#!/bin/bash
# ============================================================================
# Cloud Fragment CTF - Complete System Watchdog
# ============================================================================
# Monitors ALL containers, processes, resources and network every 15 seconds
# with auto-recovery capabilities
#
# Install as systemd service:
#   sudo cp watchdog.sh /opt/CloudFragment/
#   sudo chmod +x /opt/CloudFragment/watchdog.sh
#   sudo systemctl enable ctf-watchdog
#   sudo systemctl start ctf-watchdog
# ============================================================================

# Configuration
CTF_DIR="${CTF_DIR:-/opt/CloudFragment}"
INTERVAL=15
LOG_FILE="/var/log/ctf-watchdog.log"
MAX_LOG_SIZE=10485760  # 10MB

# Resource thresholds
CPU_THRESHOLD=90
MEMORY_THRESHOLD=90
DISK_THRESHOLD=90

# Expected containers with their compose service names
declare -A CONTAINERS=(
    ["CloudFragment-edge"]="edge-waf"
    ["CloudFragment-proxy"]="nginx-proxy"
    ["CloudFragment-app"]="nextjs-app"
    ["CloudFragment-metadata"]="internal-api"
    ["CloudFragment-secrets"]="secrets-vault"
    ["CloudFragment-dns"]="internal-dns"
)

# Critical processes to check inside containers (use partial match)
# These are checked with 'pgrep -f' for flexible matching
declare -A CONTAINER_PROCESSES=(
    ["CloudFragment-edge"]="nginx: master"
    ["CloudFragment-proxy"]="nginx: master"
    ["CloudFragment-app"]="node server.js"
    ["CloudFragment-metadata"]="python"
    ["CloudFragment-secrets"]="secrets-vault"
    ["CloudFragment-dns"]="coredns"
)

# ============================================================================
# LOGGING
# ============================================================================
rotate_log() {
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
}

log() {
    rotate_log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null
}

log_ok() { log "✓ $1"; }
log_warn() { log "⚠ $1"; }
log_error() { log "✗ $1"; }
log_info() { log "ℹ $1"; }

# ============================================================================
# CONTAINER CHECKS
# ============================================================================
is_container_running() {
    local container="$1"
    local status
    status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    [[ "$status" == "running" ]]
}

is_container_healthy() {
    local container="$1"
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
    [[ "$health" == "healthy" || "$health" == "" ]]  # "" means no healthcheck defined
}

check_process_in_container() {
    local container="$1"
    local process="${CONTAINER_PROCESSES[$container]}"
    
    if [[ -z "$process" ]]; then
        return 0  # No process defined, skip check
    fi
    
    # Use ps aux and grep for flexible matching (pgrep -f doesn't work well in alpine)
    docker exec "$container" sh -c "ps aux 2>/dev/null | grep -v grep | grep -q '$process'" 2>/dev/null
}

get_container_cpu() {
    local container="$1"
    docker stats --no-stream --format "{{.CPUPerc}}" "$container" 2>/dev/null | tr -d '%'
}

get_container_memory() {
    local container="$1"
    docker stats --no-stream --format "{{.MemPerc}}" "$container" 2>/dev/null | tr -d '%'
}

restart_container() {
    local container="$1"
    local service="${CONTAINERS[$container]}"
    
    if [[ -z "$service" ]]; then
        log_error "Unknown container: $container"
        return 1
    fi
    
    log_warn "Restarting container: $container (service: $service)"
    
    cd "$CTF_DIR" || return 1
    
    if docker compose up -d "$service" 2>/dev/null; then
        log_ok "Container $container restarted successfully"
        return 0
    else
        log_error "Failed to restart $container"
        return 1
    fi
}

force_recreate_container() {
    local container="$1"
    local service="${CONTAINERS[$container]}"
    
    if [[ -z "$service" ]]; then
        return 1
    fi
    
    log_warn "Force recreating container: $container"
    
    cd "$CTF_DIR" || return 1
    
    docker rm -f "$container" 2>/dev/null || true
    
    if docker compose up -d --force-recreate "$service" 2>/dev/null; then
        log_ok "Container $container recreated successfully"
        return 0
    else
        log_error "Failed to recreate $container"
        return 1
    fi
}

# ============================================================================
# SERVICE HEALTH CHECKS
# ============================================================================
check_waf_health() {
    local http_code
    http_code=$(docker exec CloudFragment-edge curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
    [[ "$http_code" == "200" ]]
}

check_proxy_health() {
    local http_code
    http_code=$(docker exec CloudFragment-proxy curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "000")
    [[ "$http_code" == "200" ]]
}

check_app_health() {
    # Check if Node.js is responding (via internal network)
    docker exec CloudFragment-edge curl -s --max-time 5 -o /dev/null -w "%{http_code}" http://nginx-proxy:8080/ 2>/dev/null | grep -qE "^(200|304)$"
}

check_metadata_health() {
    docker exec CloudFragment-app wget -q --spider --timeout=3 http://internal-api:8080/ 2>/dev/null
}

check_secrets_health() {
    docker exec CloudFragment-app wget -q --spider --timeout=3 --no-check-certificate https://secrets-vault:443/ 2>/dev/null
}

check_dns_health() {
    docker exec CloudFragment-dns nslookup localhost 127.0.0.1 >/dev/null 2>&1
}

# ============================================================================
# SYSTEM RESOURCE CHECKS
# ============================================================================
check_system_cpu() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1 2>/dev/null || echo "0")
    [[ "${cpu_usage:-0}" -lt "$CPU_THRESHOLD" ]]
}

check_system_memory() {
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}' 2>/dev/null || echo "0")
    [[ "${mem_usage:-0}" -lt "$MEMORY_THRESHOLD" ]]
}

check_system_disk() {
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%' 2>/dev/null || echo "0")
    [[ "${disk_usage:-0}" -lt "$DISK_THRESHOLD" ]]
}

# ============================================================================
# NETWORK CHECKS
# ============================================================================
check_docker_networks() {
    local networks=("fragra_edge_net" "fragra_dmz_net" "fragra_app_net" "fragra_internal_net")
    local missing=0
    
    for net in "${networks[@]}"; do
        if ! docker network inspect "$net" >/dev/null 2>&1; then
            log_warn "Docker network missing: $net"
            missing=$((missing + 1))
        fi
    done
    
    return $missing
}

check_port_listening() {
    # Check if port 80 is open on the public IP
    nc -z -w2 72.60.148.4 80 2>/dev/null
}

# ============================================================================
# RECOVERY ACTIONS
# ============================================================================
full_system_restart() {
    log_error "Performing FULL SYSTEM RESTART..."
    
    cd "$CTF_DIR" || return 1
    
    # Stop all
    docker compose down --timeout 15 2>/dev/null || true
    
    # Clean up orphans
    docker rm -f $(docker ps -aq --filter "name=CloudFragment") 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    
    # Restart
    sleep 3
    docker compose up -d 2>/dev/null
    
    log_info "Full restart completed, waiting 30s for services..."
    sleep 30
}

cleanup_resources() {
    log_info "Cleaning up Docker resources..."
    docker system prune -f --volumes 2>/dev/null || true
}

# ============================================================================
# MAIN MONITORING LOOP
# ============================================================================
monitor_loop() {
    log "=========================================================="
    log "CTF Watchdog Started - Complete System Monitoring"
    log "Interval: ${INTERVAL}s | Containers: ${#CONTAINERS[@]}"
    log "CPU Threshold: ${CPU_THRESHOLD}% | Memory: ${MEMORY_THRESHOLD}%"
    log "=========================================================="
    
    local consecutive_failures=0
    local last_full_restart=0
    local check_count=0
    
    while true; do
        local issues=0
        local current_time
        current_time=$(date +%s)
        check_count=$((check_count + 1))
        
        # ===== CONTAINER STATUS CHECKS =====
        for container in "${!CONTAINERS[@]}"; do
            # Check if running
            if ! is_container_running "$container"; then
                log_warn "Container DOWN: $container"
                issues=$((issues + 1))
                
                if ! restart_container "$container"; then
                    force_recreate_container "$container"
                fi
                sleep 2
                continue
            fi
            
            # Check process inside container
            if ! check_process_in_container "$container"; then
                log_warn "Process not running in: $container"
                issues=$((issues + 1))
                docker restart "$container" 2>/dev/null || true
                sleep 2
            fi
        done
        
        # ===== SERVICE HEALTH CHECKS =====
        if ! check_waf_health; then
            log_warn "WAF health check failed"
            issues=$((issues + 1))
            if is_container_running "CloudFragment-edge"; then
                docker restart CloudFragment-edge 2>/dev/null || true
                sleep 3
            fi
        fi
        
        if ! check_proxy_health; then
            log_warn "Proxy health check failed"
            if is_container_running "CloudFragment-proxy"; then
                docker restart CloudFragment-proxy 2>/dev/null || true
                sleep 2
            fi
        fi
        
        # ===== SYSTEM RESOURCE CHECKS (every 4 checks = ~1 minute) =====
        if [[ $((check_count % 4)) -eq 0 ]]; then
            if ! check_system_cpu; then
                log_warn "HIGH CPU USAGE detected (>${CPU_THRESHOLD}%)"
            fi
            
            if ! check_system_memory; then
                log_warn "HIGH MEMORY USAGE detected (>${MEMORY_THRESHOLD}%)"
                # Try to free some memory
                docker system prune -f 2>/dev/null || true
            fi
            
            if ! check_system_disk; then
                log_error "HIGH DISK USAGE detected (>${DISK_THRESHOLD}%)"
                cleanup_resources
            fi
        fi
        
        # ===== NETWORK CHECKS (every 8 checks = ~2 minutes) =====
        if [[ $((check_count % 8)) -eq 0 ]]; then
            if ! check_docker_networks; then
                log_warn "Docker networks missing, attempting recreation..."
                cd "$CTF_DIR" && docker compose up -d 2>/dev/null
            fi
            
            if ! check_port_listening; then
                log_warn "Port 80 not responding on public IP"
                issues=$((issues + 1))
            fi
        fi
        
        # ===== FAILURE TRACKING =====
        if [[ $issues -gt 0 ]]; then
            consecutive_failures=$((consecutive_failures + 1))
            
            # Full restart after 5 consecutive failures (max once per 5 minutes)
            if [[ $consecutive_failures -ge 5 ]] && [[ $((current_time - last_full_restart)) -gt 300 ]]; then
                full_system_restart
                last_full_restart=$current_time
                consecutive_failures=0
            fi
        else
            if [[ $consecutive_failures -gt 0 ]]; then
                log_ok "All systems recovered"
            fi
            consecutive_failures=0
        fi
        
        # ===== STATUS LOG (every 20 checks = ~5 minutes) =====
        if [[ $((check_count % 20)) -eq 0 ]]; then
            local running_count
            running_count=$(docker ps --filter "name=CloudFragment" --format "{{.Names}}" | wc -l)
            log_info "STATUS: ${running_count}/${#CONTAINERS[@]} containers running | Check #${check_count}"
        fi
        
        sleep "$INTERVAL"
    done
}

# ============================================================================
# STARTUP
# ============================================================================
cleanup() {
    log "Watchdog stopping..."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# Create log file if not exists
touch "$LOG_FILE" 2>/dev/null || true

# Run main loop
monitor_loop
