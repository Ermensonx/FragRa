#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - HTB VM SETUP SCRIPT
# Resilient, Self-Healing, Quick Reset
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MACHINE_NAME="cloudfragment"
DOMAIN="${MACHINE_NAME}.htb"
CTF_DIR="/opt/CloudFragment"
BACKUP_DIR="/opt/CloudFragment-backup"
USER_FLAG="d8ea1ee67784b6d36f9a901dfc6fbf70"
ROOT_FLAG="7ad0e1af0e577f564b1834bf5c8649a2"
CTF_USER="node"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
banner() { echo -e "${CYAN}$1${NC}"; }

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================
preflight() {
    banner "
╔═══════════════════════════════════════════════════════════════╗
║           CLOUD FRAGMENT - HTB VM SETUP                       ║
║           Resilient • Self-Healing • Quick Reset              ║
╚═══════════════════════════════════════════════════════════════╝
"
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
    
    log "Pre-flight checks passed"
}

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================
configure_system() {
    log "Configuring system..."
    
    # Hostname
    hostnamectl set-hostname "$MACHINE_NAME"
    
    # /etc/hosts
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "127.0.0.1   $MACHINE_NAME $DOMAIN" >> /etc/hosts
    fi
    
    # Locale
    localectl set-locale LANG=en_US.UTF-8 2>/dev/null || true
    localectl set-keymap us 2>/dev/null || true
    
    # Timezone
    timedatectl set-timezone UTC
    
    log "System configured: hostname=$MACHINE_NAME, domain=$DOMAIN"
}

# ============================================================================
# USER SETUP
# ============================================================================
setup_users() {
    log "Setting up users..."
    
    # Create CTF user if doesn't exist
    if ! id "$CTF_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$CTF_USER"
        log "Created user: $CTF_USER"
    fi
    
    # Disable history for all users
    for user_home in /root /home/$CTF_USER; do
        for hist_file in .bash_history .mysql_history .viminfo .python_history .lesshst; do
            rm -f "${user_home}/${hist_file}" 2>/dev/null || true
            ln -sf /dev/null "${user_home}/${hist_file}"
            chown root:root "${user_home}/${hist_file}" 2>/dev/null || true
        done
    done
    
    # Add to /etc/profile to ensure history is never saved
    if ! grep -q "HISTSIZE=0" /etc/profile; then
        cat >> /etc/profile << 'EOF'

# HTB: Disable command history
export HISTSIZE=0
export HISTFILESIZE=0
unset HISTFILE
EOF
    fi
    
    log "Users configured with history disabled"
}

# ============================================================================
# FLAGS SETUP
# ============================================================================
setup_flags() {
    log "Setting up flags..."
    
    # User flag
    echo "$USER_FLAG" > /home/$CTF_USER/user.txt
    chown root:$CTF_USER /home/$CTF_USER/user.txt
    chmod 640 /home/$CTF_USER/user.txt
    
    # Root flag
    echo "$ROOT_FLAG" > /root/root.txt
    chown root:root /root/root.txt
    chmod 640 /root/root.txt
    
    # Protect flags with immutable attribute
    chattr +i /home/$CTF_USER/user.txt 2>/dev/null || true
    chattr +i /root/root.txt 2>/dev/null || true
    
    log "Flags installed and protected"
}

# ============================================================================
# DOCKER INSTALLATION
# ============================================================================
install_docker() {
    if command -v docker &>/dev/null; then
        log "Docker already installed"
        return
    fi
    
    log "Installing Docker..."
    
    apt-get update -qq
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Docker repo
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    log "Docker installed and running"
}

# ============================================================================
# CTF DEPLOYMENT
# ============================================================================
deploy_ctf() {
    log "Deploying CTF environment..."
    
    # Ensure directory exists
    mkdir -p "$CTF_DIR"
    
    # If we have the source files, copy them
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/../docker-compose.yml" ]]; then
        cp -r "${SCRIPT_DIR}/../"* "$CTF_DIR/" 2>/dev/null || true
        rm -rf "${CTF_DIR}/vm-scripts" 2>/dev/null || true
    fi
    
    # Create backup for quick reset
    mkdir -p "$BACKUP_DIR"
    cp -r "$CTF_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    
    # Build and start
    cd "$CTF_DIR"
    docker compose build --quiet
    docker compose up -d
    
    log "CTF deployed successfully"
}

# ============================================================================
# SYSTEMD SERVICES
# ============================================================================
install_services() {
    log "Installing systemd services..."
    
    # Main CTF service
    cat > /etc/systemd/system/CloudFragment.service << EOF
[Unit]
Description=Cloud Fragment CTF Challenge
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$CTF_DIR
ExecStartPre=/usr/bin/docker compose pull --ignore-pull-failures
ExecStart=/usr/bin/docker compose up -d --remove-orphans
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Watchdog service - monitors and auto-heals
    cat > /etc/systemd/system/CloudFragment-watchdog.service << EOF
[Unit]
Description=Cloud Fragment Watchdog (Auto-Healing)
After=CloudFragment.service
Requires=CloudFragment.service

[Service]
Type=simple
ExecStart=/opt/CloudFragment/watchdog.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

    # Timer for periodic health checks
    cat > /etc/systemd/system/CloudFragment-health.timer << EOF
[Unit]
Description=Cloud Fragment Health Check Timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

    cat > /etc/systemd/system/CloudFragment-health.service << EOF
[Unit]
Description=Cloud Fragment Health Check

[Service]
Type=oneshot
ExecStart=/opt/CloudFragment/health-check.sh
EOF

    # Enable all services
    systemctl daemon-reload
    systemctl enable CloudFragment.service
    systemctl enable CloudFragment-watchdog.service
    systemctl enable CloudFragment-health.timer
    
    log "Systemd services installed"
}

# ============================================================================
# WATCHDOG SCRIPT
# ============================================================================
create_watchdog() {
    log "Creating watchdog script..."
    
    cat > "$CTF_DIR/watchdog.sh" << 'WATCHDOG'
#!/bin/bash
# Cloud Fragment Watchdog - Auto-healing daemon

CTF_DIR="/opt/CloudFragment"
LOG_FILE="/var/log/CloudFragment-watchdog.log"
EXPECTED_CONTAINERS=("CloudFragment-edge" "CloudFragment-proxy" "CloudFragment-app" "CloudFragment-metadata" "CloudFragment-secrets")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_container() {
    local name=$1
    if ! docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        return 1
    fi
    return 0
}

heal() {
    log "HEALING: Restarting CTF environment..."
    cd "$CTF_DIR"
    docker compose down 2>/dev/null || true
    docker compose up -d
    log "HEALING: Complete"
}

# Main loop
log "Watchdog started"
FAIL_COUNT=0
MAX_FAILS=3

while true; do
    UNHEALTHY=0
    
    for container in "${EXPECTED_CONTAINERS[@]}"; do
        if ! check_container "$container"; then
            log "WARNING: Container $container is DOWN"
            UNHEALTHY=$((UNHEALTHY + 1))
        fi
    done
    
    if [[ $UNHEALTHY -gt 0 ]]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        log "Unhealthy count: $UNHEALTHY, Fail streak: $FAIL_COUNT"
        
        if [[ $FAIL_COUNT -ge $MAX_FAILS ]]; then
            heal
            FAIL_COUNT=0
        fi
    else
        FAIL_COUNT=0
    fi
    
    sleep 60
done
WATCHDOG

    chmod +x "$CTF_DIR/watchdog.sh"
    log "Watchdog script created"
}

# ============================================================================
# HEALTH CHECK SCRIPT
# ============================================================================
create_health_check() {
    log "Creating health check script..."
    
    cat > "$CTF_DIR/health-check.sh" << 'HEALTHCHECK'
#!/bin/bash
# Cloud Fragment Health Check

CTF_DIR="/opt/CloudFragment"
BACKUP_DIR="/opt/CloudFragment-backup"

# Check Docker
if ! systemctl is-active --quiet docker; then
    echo "[CRITICAL] Docker is not running!"
    systemctl start docker
fi

# Check containers
cd "$CTF_DIR"
RUNNING=$(docker compose ps --format json 2>/dev/null | jq -s 'length' 2>/dev/null || echo "0")

if [[ "$RUNNING" -lt 5 ]]; then
    echo "[WARNING] Only $RUNNING containers running, expected 5+"
    docker compose up -d
fi

# Check web accessibility
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://72.60.148.4:80/health 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" != "200" ]]; then
    echo "[WARNING] WAF health check failed (HTTP $HTTP_CODE)"
fi

# Check flags exist
if [[ ! -f /home/node/user.txt ]] || [[ ! -f /root/root.txt ]]; then
    echo "[CRITICAL] Flags missing! Restoring..."
    echo "d8ea1ee67784b6d36f9a901dfc6fbf70" > /home/node/user.txt
    chown root:node /home/node/user.txt
    chmod 640 /home/node/user.txt
    
    echo "7ad0e1af0e577f564b1834bf5c8649a2" > /root/root.txt
    chown root:root /root/root.txt
    chmod 640 /root/root.txt
fi

echo "[OK] Health check complete"
HEALTHCHECK

    chmod +x "$CTF_DIR/health-check.sh"
    log "Health check script created"
}

# ============================================================================
# RESET SCRIPT
# ============================================================================
create_reset_script() {
    log "Creating reset script..."
    
    cat > "$CTF_DIR/reset.sh" << 'RESET'
#!/bin/bash
# Cloud Fragment - QUICK RESET
# Destroys and rebuilds everything in <60 seconds

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CTF_DIR="/opt/CloudFragment"
BACKUP_DIR="/opt/CloudFragment-backup"

echo -e "${YELLOW}╔═══════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     CLOUD FRAGMENT - QUICK RESET      ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════╝${NC}"

# Parse args
HARD_RESET=false
if [[ "${1:-}" == "--hard" ]]; then
    HARD_RESET=true
fi

cd "$CTF_DIR"

echo -e "${YELLOW}[1/5]${NC} Stopping containers..."
docker compose down -v --remove-orphans 2>/dev/null || true

if $HARD_RESET; then
    echo -e "${YELLOW}[2/5]${NC} Hard reset: Pruning Docker..."
    docker system prune -af --volumes 2>/dev/null || true
    
    echo -e "${YELLOW}[3/5]${NC} Restoring from backup..."
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$CTF_DIR"/*
        cp -r "$BACKUP_DIR"/* "$CTF_DIR"/
    fi
    
    echo -e "${YELLOW}[4/5]${NC} Rebuilding images..."
    docker compose build --no-cache
else
    echo -e "${YELLOW}[2/5]${NC} Soft reset: Keeping images..."
    echo -e "${YELLOW}[3/5]${NC} Skipping backup restore..."
    echo -e "${YELLOW}[4/5]${NC} Skipping rebuild..."
fi

echo -e "${YELLOW}[5/5]${NC} Starting containers..."
docker compose up -d

# Verify
sleep 5
RUNNING=$(docker compose ps --format json | jq -s 'length' 2>/dev/null || echo "?")
echo ""
echo -e "${GREEN}✓ Reset complete!${NC}"
echo -e "  Containers running: ${RUNNING}"
echo -e "  Access: http://cloudfragment.htb"
echo ""

# Restore flags
echo "d8ea1ee67784b6d36f9a901dfc6fbf70" > /home/node/user.txt
chown root:node /home/node/user.txt 2>/dev/null || true
chmod 640 /home/node/user.txt

echo "7ad0e1af0e577f564b1834bf5c8649a2" > /root/root.txt  
chmod 640 /root/root.txt
RESET

    chmod +x "$CTF_DIR/reset.sh"
    
    # Symlink for easy access
    ln -sf "$CTF_DIR/reset.sh" /usr/local/bin/ctf-reset
    
    log "Reset script created (use: ctf-reset or ctf-reset --hard)"
}

# ============================================================================
# STATUS SCRIPT
# ============================================================================
create_status_script() {
    log "Creating status script..."
    
    cat > "$CTF_DIR/status.sh" << 'STATUS'
#!/bin/bash
# Cloud Fragment - Status Dashboard

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

CTF_DIR="/opt/CloudFragment"

echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           CLOUD FRAGMENT - STATUS                     ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# System Info
echo -e "${YELLOW}[System]${NC}"
echo "  Hostname: $(hostname)"
echo "  Uptime:   $(uptime -p)"
echo "  Disk:     $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo ""

# Docker Status
echo -e "${YELLOW}[Docker]${NC}"
if systemctl is-active --quiet docker; then
    echo -e "  Status: ${GREEN}Running${NC}"
else
    echo -e "  Status: ${RED}Stopped${NC}"
fi
echo ""

# Container Status
echo -e "${YELLOW}[Containers]${NC}"
cd "$CTF_DIR"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Unable to get container status"
echo ""

# Network Check
echo -e "${YELLOW}[Network]${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://72.60.148.4:80/health 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
    echo -e "  WAF Health: ${GREEN}OK (HTTP 200)${NC}"
else
    echo -e "  WAF Health: ${RED}FAIL (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Flags
echo -e "${YELLOW}[Flags]${NC}"
if [[ -f /home/node/user.txt ]]; then
    echo -e "  User Flag: ${GREEN}Present${NC}"
else
    echo -e "  User Flag: ${RED}Missing${NC}"
fi
if [[ -f /root/root.txt ]]; then
    echo -e "  Root Flag: ${GREEN}Present${NC}"
else
    echo -e "  Root Flag: ${RED}Missing${NC}"
fi
echo ""

# Services
echo -e "${YELLOW}[Systemd Services]${NC}"
for svc in CloudFragment CloudFragment-watchdog; do
    if systemctl is-active --quiet $svc; then
        echo -e "  $svc: ${GREEN}Active${NC}"
    else
        echo -e "  $svc: ${RED}Inactive${NC}"
    fi
done
echo ""
STATUS

    chmod +x "$CTF_DIR/status.sh"
    ln -sf "$CTF_DIR/status.sh" /usr/local/bin/ctf-status
    
    log "Status script created (use: ctf-status)"
}

# ============================================================================
# FIREWALL SETUP
# ============================================================================
setup_firewall() {
    log "Configuring firewall..."
    
    # Install ufw if not present
    apt-get install -y -qq ufw
    
    # Reset and configure
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (for HTB)
    ufw allow 22/tcp
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable
    ufw --force enable
    
    log "Firewall configured (SSH, HTTP, HTTPS allowed)"
}

# ============================================================================
# CLEANUP
# ============================================================================
cleanup_system() {
    log "Cleaning up system..."
    
    # Remove unnecessary packages
    apt-get autoremove -y -qq
    apt-get clean
    
    # Clear logs
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
    find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    
    # Clear temp
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    # Clear apt cache
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    
    log "System cleaned"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    preflight
    
    info "Step 1/10: System configuration"
    configure_system
    
    info "Step 2/10: User setup"
    setup_users
    
    info "Step 3/10: Docker installation"
    install_docker
    
    info "Step 4/10: CTF deployment"
    deploy_ctf
    
    info "Step 5/10: Flags setup"
    setup_flags
    
    info "Step 6/10: Watchdog creation"
    create_watchdog
    
    info "Step 7/10: Health check creation"
    create_health_check
    
    info "Step 8/10: Reset script creation"
    create_reset_script
    
    info "Step 9/10: Status script creation"
    create_status_script
    
    info "Step 10/10: Systemd services"
    install_services
    
    # Optional: Firewall
    if [[ "${1:-}" == "--with-firewall" ]]; then
        setup_firewall
    fi
    
    # Cleanup
    cleanup_system
    
    # Start services
    systemctl start CloudFragment.service
    systemctl start CloudFragment-watchdog.service
    systemctl start CloudFragment-health.timer
    
    banner "
╔═══════════════════════════════════════════════════════════════╗
║                    SETUP COMPLETE! ✓                          ║
╠═══════════════════════════════════════════════════════════════╣
║  Commands available:                                          ║
║    ctf-status  - Show system status                           ║
║    ctf-reset   - Quick reset (soft)                           ║
║    ctf-reset --hard  - Full rebuild                           ║
║                                                               ║
║  Access: http://cloudfragment.htb                             ║
║  Services: Auto-healing enabled                               ║
╚═══════════════════════════════════════════════════════════════╝
"
}

main "$@"
