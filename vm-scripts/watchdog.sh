#!/bin/bash
# ============================================================================
# Cloud Fragment CTF - Container Watchdog
# ============================================================================
# Monitors containers every 15 seconds and auto-recovers individual containers
#
# Install as systemd service:
#   sudo cp watchdog.sh /opt/CloudFragment/
#   sudo chmod +x /opt/CloudFragment/watchdog.sh
#   sudo systemctl enable CloudFragment-watchdog
#   sudo systemctl start CloudFragment-watchdog
# ============================================================================

# Configuration
CTF_DIR="${CTF_DIR:-/opt/CloudFragment}"
INTERVAL=15
LOG_FILE="/var/log/ctf-watchdog.log"

# Expected containers with their compose service names
declare -A CONTAINERS=(
    ["CloudFragment-edge"]="edge-waf"
    ["CloudFragment-proxy"]="nginx-proxy"
    ["CloudFragment-app"]="nextjs-app"
    ["CloudFragment-metadata"]="internal-api"
    ["CloudFragment-secrets"]="secrets-vault"
    ["CloudFragment-dns"]="internal-dns"
)

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null
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

# Check if a container is running
is_container_running() {
    local container="$1"
    local status
    status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    [[ "$status" == "running" ]]
}

# Restart individual container via docker compose
restart_container() {
    local container="$1"
    local service="${CONTAINERS[$container]}"
    
    if [[ -z "$service" ]]; then
        log_error "Unknown container: $container"
        return 1
    fi
    
    log_warn "Restarting container: $container (service: $service)"
    
    cd "$CTF_DIR" || return 1
    
    # Try to start just this service
    if docker compose up -d "$service" 2>/dev/null; then
        log_ok "Container $container restarted successfully"
        return 0
    else
        log_error "Failed to restart $container"
        return 1
    fi
}

# Force recreate a container
force_recreate_container() {
    local container="$1"
    local service="${CONTAINERS[$container]}"
    
    if [[ -z "$service" ]]; then
        return 1
    fi
    
    log_warn "Force recreating container: $container"
    
    cd "$CTF_DIR" || return 1
    
    # Remove the stuck container
    docker rm -f "$container" 2>/dev/null || true
    
    # Recreate via compose
    if docker compose up -d --force-recreate "$service" 2>/dev/null; then
        log_ok "Container $container recreated successfully"
        return 0
    else
        log_error "Failed to recreate $container"
        return 1
    fi
}

# Check WAF is responding
check_waf_health() {
    local http_code
    http_code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
    [[ "$http_code" == "200" ]]
}

# Main monitoring loop
monitor_loop() {
    log "=========================================="
    log "Watchdog started (interval: ${INTERVAL}s)"
    log "Monitoring containers: ${!CONTAINERS[*]}"
    log "=========================================="
    
    local consecutive_failures=0
    local last_full_restart=0
    
    while true; do
        local issues=0
        local current_time
        current_time=$(date +%s)
        
        # Check each container
        for container in "${!CONTAINERS[@]}"; do
            if ! is_container_running "$container"; then
                log_warn "Container DOWN: $container"
                issues=$((issues + 1))
                
                # Try to restart
                if ! restart_container "$container"; then
                    # If restart fails, try force recreate
                    force_recreate_container "$container"
                fi
                
                # Wait a bit for container to start
                sleep 2
            fi
        done
        
        # Check WAF health even if container appears running
        if ! check_waf_health; then
            log_warn "WAF health check failed"
            
            # WAF might be unresponsive, restart it
            if is_container_running "CloudFragment-edge"; then
                log_warn "WAF container running but not responding, restarting..."
                docker restart CloudFragment-edge 2>/dev/null || true
                sleep 3
            fi
        fi
        
        # Track consecutive failures
        if [[ $issues -gt 0 ]]; then
            consecutive_failures=$((consecutive_failures + 1))
            
            # If too many failures, do a full restart (max once per 5 minutes)
            if [[ $consecutive_failures -ge 5 ]] && [[ $((current_time - last_full_restart)) -gt 300 ]]; then
                log_error "Too many consecutive failures ($consecutive_failures), performing full restart..."
                cd "$CTF_DIR" || continue
                docker compose down --timeout 10 2>/dev/null || true
                sleep 2
                docker compose up -d 2>/dev/null || true
                last_full_restart=$current_time
                consecutive_failures=0
                sleep 10
            fi
        else
            consecutive_failures=0
        fi
        
        # Wait for next check
        sleep "$INTERVAL"
    done
}

# Cleanup on exit
cleanup() {
    log "Watchdog stopping..."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# Run
monitor_loop
