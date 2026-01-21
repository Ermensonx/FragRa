#!/bin/bash
# ============================================================================
# Cloud Fragment CTF - Robust Watchdog
# ============================================================================
# Monitors site availability via HTTP and auto-recovers from failures
# ============================================================================

CTF_DIR="/root/FragRa"
INTERVAL=30
LOG="/var/log/ctf-watchdog.log"
MAX_FAILURES=3
PUBLIC_IP="72.60.148.4"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

# Check if site is responding via HTTP
check_site_health() {
    local http_code
    http_code=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "http://${PUBLIC_IP}/" 2>/dev/null)
    
    # 200, 304, 404 are OK (site is responding)
    # 502, 503, 504 or timeout (000) = problem
    case "$http_code" in
        200|304|404|403|401) return 0 ;;
        *) return 1 ;;
    esac
}

# Check container status
check_containers() {
    local down=0
    for c in CloudFragment-edge CloudFragment-proxy CloudFragment-app CloudFragment-metadata CloudFragment-secrets CloudFragment-dns; do
        if ! docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null | grep -q running; then
            log "Container DOWN: $c"
            down=$((down + 1))
        fi
    done
    return $down
}

# Restart individual container
restart_container() {
    local container="$1"
    log "Restarting: $container"
    docker restart "$container" 2>/dev/null
    sleep 5
}

# Restart app stack (proxy + app)
restart_app_stack() {
    log "Restarting app stack (proxy + app)..."
    docker restart CloudFragment-app 2>/dev/null
    sleep 5
    docker restart CloudFragment-proxy 2>/dev/null
    sleep 5
    docker restart CloudFragment-edge 2>/dev/null
    sleep 5
}

# Full restart
full_restart() {
    log "FULL RESTART - All containers"
    cd "$CTF_DIR" || return 1
    docker compose down --timeout 10 2>/dev/null
    sleep 3
    docker compose up -d 2>/dev/null
    sleep 15
}

# Main loop
main() {
    log "=========================================="
    log "Watchdog Started"
    log "Interval: ${INTERVAL}s | IP: ${PUBLIC_IP}"
    log "=========================================="
    
    local consecutive_failures=0
    local last_full_restart=0
    
    while true; do
        local current_time=$(date +%s)
        
        # Check containers first
        if ! check_containers; then
            log "Some containers are down, attempting recovery..."
            cd "$CTF_DIR" && docker compose up -d 2>/dev/null
            sleep 10
        fi
        
        # Check HTTP health
        if check_site_health; then
            if [ $consecutive_failures -gt 0 ]; then
                log "Site recovered after $consecutive_failures failures"
            fi
            consecutive_failures=0
        else
            consecutive_failures=$((consecutive_failures + 1))
            log "Site check FAILED (attempt $consecutive_failures/$MAX_FAILURES)"
            
            if [ $consecutive_failures -eq 1 ]; then
                # First failure: restart app
                restart_container CloudFragment-app
            elif [ $consecutive_failures -eq 2 ]; then
                # Second failure: restart app stack
                restart_app_stack
            elif [ $consecutive_failures -ge $MAX_FAILURES ]; then
                # Third+ failure: full restart (max once per 5 min)
                if [ $((current_time - last_full_restart)) -gt 300 ]; then
                    full_restart
                    last_full_restart=$current_time
                    consecutive_failures=0
                fi
            fi
        fi
        
        sleep "$INTERVAL"
    done
}

# Cleanup
trap 'log "Watchdog stopping..."; exit 0' SIGTERM SIGINT SIGHUP

# Run
main
