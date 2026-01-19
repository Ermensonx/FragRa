#!/bin/bash
# ============================================================================
# Cloud Fragment CTF - Environment Integrity Monitor
# ============================================================================
# Cron script for periodic health checks and auto-recovery
# Runs every 5 minutes via systemd timer or cron
#
# Install: sudo cp integrity-monitor.sh /opt/CloudFragment/
#          sudo chmod +x /opt/CloudFragment/integrity-monitor.sh
#
# Cron entry (every 5 min):
#   */5 * * * * /opt/CloudFragment/integrity-monitor.sh >> /var/log/ctf-monitor.log 2>&1
# ============================================================================

set -euo pipefail

# Configuration
CTF_DIR="/opt/CloudFragment"
LOG_FILE="/var/log/ctf-monitor.log"
COMPOSE_FILE="${CTF_DIR}/docker-compose.yml"
BACKUP_DIR="${CTF_DIR}/backup"

# Expected values
EXPECTED_CONTAINERS=6
USER_FLAG="d8ea1ee67784b6d36f9a901dfc6fbf70"
ROOT_FLAG="7ad0e1af0e577f564b1834bf5c8649a2"
USER_FLAG_PATH="/home/node/user.txt"
ROOT_FLAG_PATH="/root/root.txt"

# Colors (for interactive use)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_ok() {
    log "✓ $1"
}

log_warn() {
    log "⚠ $1"
}

log_error() {
    log "✗ $1"
}

# ============================================================================
# CHECKS
# ============================================================================

check_docker_running() {
    if ! systemctl is-active --quiet docker; then
        log_error "Docker service not running"
        log "Attempting to start Docker..."
        systemctl start docker
        sleep 5
        if systemctl is-active --quiet docker; then
            log_ok "Docker started successfully"
            return 0
        else
            log_error "Failed to start Docker"
            return 1
        fi
    fi
    return 0
}

check_containers() {
    local running
    running=$(docker ps --filter "name=CloudFragment" --format "{{.Names}}" 2>/dev/null | wc -l)
    
    if [[ "$running" -lt "$EXPECTED_CONTAINERS" ]]; then
        log_warn "Only $running/$EXPECTED_CONTAINERS containers running"
        return 1
    fi
    
    log_ok "All $EXPECTED_CONTAINERS containers running"
    return 0
}

check_container_health() {
    local unhealthy=0
    
    # Check each container
    for container in $(docker ps --filter "name=CloudFragment" --format "{{.Names}}" 2>/dev/null); do
        local status
        status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        
        if [[ "$status" != "running" ]]; then
            log_warn "Container $container status: $status"
            unhealthy=$((unhealthy + 1))
        fi
        
        # Check restart count
        local restarts
        restarts=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null)
        if [[ "$restarts" -gt 5 ]]; then
            log_warn "Container $container has restarted $restarts times"
        fi
    done
    
    return $unhealthy
}

check_waf_responding() {
    # Check if WAF is responding on port 80
    local http_code
    http_code=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
    if [[ "$http_code" == "200" ]]; then
        log_ok "WAF responding on port 80 (HTTP $http_code)"
        return 0
    else
        log_warn "WAF not responding on port 80 (HTTP $http_code)"
        return 1
    fi
}

check_internal_services() {
    local issues=0
    
    # Check if internal-api is reachable from nextjs container
    if docker exec CloudFragment-app sh -c "wget -q -O- http://internal-api:8080/ >/dev/null 2>&1" 2>/dev/null; then
        log_ok "internal-api reachable"
    else
        log_warn "internal-api not reachable from nextjs"
        issues=$((issues + 1))
    fi
    
    # Check if secrets-vault is reachable
    if docker exec CloudFragment-app sh -c "wget -q --no-check-certificate -O- https://secrets-vault:443/ >/dev/null 2>&1" 2>/dev/null; then
        log_ok "secrets-vault reachable"
    else
        log_warn "secrets-vault not reachable from nextjs"
        issues=$((issues + 1))
    fi
    
    return $issues
}

check_flags() {
    local issues=0
    
    # Check user flag
    if [[ -f "$USER_FLAG_PATH" ]]; then
        local user_content
        user_content=$(cat "$USER_FLAG_PATH" 2>/dev/null | tr -d '[:space:]')
        if [[ "$user_content" == "$USER_FLAG" ]]; then
            log_ok "User flag intact"
        else
            log_error "User flag corrupted or modified"
            issues=$((issues + 1))
        fi
    else
        log_error "User flag missing at $USER_FLAG_PATH"
        issues=$((issues + 1))
    fi
    
    # Check root flag
    if [[ -f "$ROOT_FLAG_PATH" ]]; then
        local root_content
        root_content=$(cat "$ROOT_FLAG_PATH" 2>/dev/null | tr -d '[:space:]')
        if [[ "$root_content" == "$ROOT_FLAG" ]]; then
            log_ok "Root flag intact"
        else
            log_error "Root flag corrupted or modified"
            issues=$((issues + 1))
        fi
    else
        log_error "Root flag missing at $ROOT_FLAG_PATH"
        issues=$((issues + 1))
    fi
    
    return $issues
}

check_disk_space() {
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    
    if [[ "$usage" -gt 90 ]]; then
        log_error "Disk usage critical: ${usage}%"
        return 1
    elif [[ "$usage" -gt 80 ]]; then
        log_warn "Disk usage high: ${usage}%"
        return 0
    else
        log_ok "Disk usage OK: ${usage}%"
        return 0
    fi
}

check_memory() {
    local mem_free
    mem_free=$(free -m | awk 'NR==2 {printf "%.0f", $7/$2*100}')
    
    if [[ "$mem_free" -lt 10 ]]; then
        log_warn "Memory low: only ${mem_free}% available"
        return 1
    else
        log_ok "Memory OK: ${mem_free}% available"
        return 0
    fi
}

# ============================================================================
# RECOVERY ACTIONS
# ============================================================================

restart_containers() {
    log "Restarting CTF containers..."
    cd "$CTF_DIR"
    docker compose down --timeout 10 2>/dev/null || true
    sleep 2
    docker compose up -d
    sleep 10
    log_ok "Containers restarted"
}

restore_flags() {
    log "Restoring flags..."
    
    # User flag
    if [[ ! -f "$USER_FLAG_PATH" ]] || [[ "$(cat "$USER_FLAG_PATH" 2>/dev/null | tr -d '[:space:]')" != "$USER_FLAG" ]]; then
        echo "$USER_FLAG" > "$USER_FLAG_PATH"
        chown root:node "$USER_FLAG_PATH"
        chmod 640 "$USER_FLAG_PATH"
        chattr +i "$USER_FLAG_PATH" 2>/dev/null || true
        log_ok "User flag restored"
    fi
    
    # Root flag
    if [[ ! -f "$ROOT_FLAG_PATH" ]] || [[ "$(cat "$ROOT_FLAG_PATH" 2>/dev/null | tr -d '[:space:]')" != "$ROOT_FLAG" ]]; then
        echo "$ROOT_FLAG" > "$ROOT_FLAG_PATH"
        chown root:root "$ROOT_FLAG_PATH"
        chmod 640 "$ROOT_FLAG_PATH"
        chattr +i "$ROOT_FLAG_PATH" 2>/dev/null || true
        log_ok "Root flag restored"
    fi
}

cleanup_docker() {
    log "Cleaning up Docker resources..."
    docker system prune -f --volumes 2>/dev/null || true
    log_ok "Docker cleanup complete"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log "========== CTF Integrity Check Started =========="
    
    local issues=0
    local critical=0
    
    # Check Docker
    if ! check_docker_running; then
        critical=$((critical + 1))
    fi
    
    # Check containers
    if ! check_containers; then
        issues=$((issues + 1))
        # Try to restart
        restart_containers
        sleep 5
        check_containers || critical=$((critical + 1))
    fi
    
    # Check container health
    check_container_health || issues=$((issues + 1))
    
    # Check WAF
    check_waf_responding || issues=$((issues + 1))
    
    # Check internal services
    check_internal_services || issues=$((issues + 1))
    
    # Check flags
    if ! check_flags; then
        issues=$((issues + 1))
        restore_flags
    fi
    
    # Check resources
    check_disk_space || issues=$((issues + 1))
    check_memory || issues=$((issues + 1))
    
    # Cleanup if disk is getting full
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$disk_usage" -gt 80 ]]; then
        cleanup_docker
    fi
    
    # Summary
    log "=========================================="
    if [[ "$critical" -gt 0 ]]; then
        log_error "CRITICAL: $critical critical issues found"
        exit 2
    elif [[ "$issues" -gt 0 ]]; then
        log_warn "WARNING: $issues issues found (auto-recovered)"
        exit 1
    else
        log_ok "All checks passed"
        exit 0
    fi
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
