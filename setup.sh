#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - SETUP COMPLETO UNIFICADO
# Instalação, Configuração de Rede, Deploy e Manutenção
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
MACHINE_NAME="cloudfragment"
DOMAIN="${MACHINE_NAME}.htb"
USER_FLAG="d8ea1ee67784b6d36f9a901dfc6fbf70"
ROOT_FLAG="7ad0e1af0e577f564b1834bf5c8649a2"
CTF_USER="node"

# Detect script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../docker-compose.yml" ]]; then
    CTF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
    CTF_DIR="$SCRIPT_DIR"
else
    CTF_DIR="/opt/CloudFragment"
fi

BACKUP_DIR="/opt/CloudFragment-backup"
LOG_FILE="/var/log/CloudFragment-setup.log"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${BLUE}[i]${NC} $1"; }
banner() { echo -e "${CYAN}$1${NC}"; }

# ============================================================================
# BANNER
# ============================================================================
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
   _____ _                 _   ______                                     _   
  / ____| |               | | |  ____|                                   | |  
 | |    | | ___  _   _  __| | | |__ _ __ __ _  __ _ _ __ ___   ___ _ __ | |_ 
 | |    | |/ _ \| | | |/ _` | |  __| '__/ _` |/ _` | '_ ` _ \ / _ \ '_ \| __|
 | |____| | (_) | |_| | (_| | | |  | | | (_| | (_| | | | | | |  __/ | | | |_ 
  \_____|_|\___/ \__,_|\__,_| |_|  |_|  \__,_|\__, |_| |_| |_|\___|_| |_|\__|
                                               __/ |                         
                                              |___/  Setup Completo Unificado
BANNER
    echo -e "${NC}"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================
preflight() {
    if [[ $EUID -ne 0 ]]; then
        error "Execute como root: sudo $0"
    fi

    log "Verificações iniciais OK"
}

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================
configure_system() {
    log "Configurando sistema..."

    # Hostname
    hostnamectl set-hostname "$MACHINE_NAME" 2>/dev/null || true

    # Locale
    localectl set-locale LANG=en_US.UTF-8 2>/dev/null || true

    # Timezone
    timedatectl set-timezone America/Sao_Paulo 2>/dev/null || true

    log "Sistema configurado: hostname=$MACHINE_NAME"
}

# ============================================================================
# CONFIGURE /etc/hosts (DNS LOCAL)
# ============================================================================
configure_hosts() {
    log "Configurando DNS local (/etc/hosts)..."

    # Backup original
    if [[ ! -f /etc/hosts.backup ]]; then
        cp /etc/hosts /etc/hosts.backup
    fi

    # Remove old entries first
    sed -i "/$DOMAIN/d" /etc/hosts 2>/dev/null || true

    # Add domain entries
    echo "127.0.0.1   $DOMAIN $MACHINE_NAME" >> /etc/hosts
    log "Adicionado: 127.0.0.1 → $DOMAIN"

    log "DNS local configurado"
}

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================
install_dependencies() {
    log "Instalando dependências..."

    # Update package lists
    apt-get update -qq

    # Install essential packages
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        jq \
        net-tools \
        ufw 2>/dev/null || true

    log "Pacotes básicos instalados"
}

# ============================================================================
# DOCKER INSTALLATION
# ============================================================================
install_docker() {
    if command -v docker &>/dev/null; then
        log "Docker já está instalado"
        # Ensure Docker is running
        systemctl start docker 2>/dev/null || true
        return
    fi

    log "Instalando Docker..."

    # Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
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

    log "Docker instalado e rodando"
}

# ============================================================================
# USER SETUP
# ============================================================================
setup_users() {
    log "Configurando usuários..."

    # Passwords (HTB compliant - no @ { } ' ")
    ROOT_PASS="Cl0udFr4gm3nt_R00t!"
    NODE_PASS="N0d3_Us3r_Acc3ss!"

    # Create CTF user if doesn't exist
    if ! id "$CTF_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$CTF_USER" 2>/dev/null || true
        log "Usuário criado: $CTF_USER"
    fi

    # Set passwords
    echo "root:$ROOT_PASS" | chpasswd 2>/dev/null || true
    echo "$CTF_USER:$NODE_PASS" | chpasswd 2>/dev/null || true
    log "Senhas configuradas"

    # Disable history for all users
    for user_home in /root /home/$CTF_USER; do
        if [[ -d "$user_home" ]]; then
            for hist_file in .bash_history .mysql_history .viminfo .python_history .lesshst; do
                rm -f "${user_home}/${hist_file}" 2>/dev/null || true
                ln -sf /dev/null "${user_home}/${hist_file}" 2>/dev/null || true
                chown root:root "${user_home}/${hist_file}" 2>/dev/null || true
            done
        fi
    done

    log "Usuários configurados"
}

# ============================================================================
# FLAGS SETUP
# ============================================================================
setup_flags() {
    log "Configurando flags..."

    # User flag
    mkdir -p /home/$CTF_USER
    echo "$USER_FLAG" > /home/$CTF_USER/user.txt
    chown root:$CTF_USER /home/$CTF_USER/user.txt 2>/dev/null || true
    chmod 640 /home/$CTF_USER/user.txt

    # Root flag
    echo "$ROOT_FLAG" > /root/root.txt
    chmod 640 /root/root.txt

    log "Flags instaladas"
}

# ============================================================================
# FIREWALL SETUP
# ============================================================================
setup_firewall() {
    log "Configurando firewall..."

    # Reset and configure
    ufw --force reset >/dev/null 2>&1 || true
    ufw default deny incoming >/dev/null 2>&1 || true
    ufw default allow outgoing >/dev/null 2>&1 || true

    # Allow ports
    ufw allow 22/tcp >/dev/null 2>&1 || true   # SSH
    ufw allow 80/tcp >/dev/null 2>&1 || true   # HTTP

    # Enable
    ufw --force enable >/dev/null 2>&1 || true

    log "Firewall configurado (SSH, HTTP)"
}

# ============================================================================
# DEPLOY CTF
# ============================================================================
deploy_ctf() {
    log "Fazendo deploy do CTF..."

    # Copy to /opt if not already there
    if [[ "$CTF_DIR" != "/opt/CloudFragment" ]] && [[ -f "$CTF_DIR/docker-compose.yml" ]]; then
        mkdir -p /opt/CloudFragment
        cp -r "$CTF_DIR"/* /opt/CloudFragment/ 2>/dev/null || true
        rm -rf /opt/CloudFragment/vm-scripts 2>/dev/null || true
        CTF_DIR="/opt/CloudFragment"
    fi

    # Create backup
    mkdir -p "$BACKUP_DIR"
    cp -r "$CTF_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

    cd "$CTF_DIR"

    # Stop existing containers
    docker compose down 2>/dev/null || true

    # Build images
    log "Construindo imagens (pode demorar alguns minutos)..."
    docker compose build --quiet 2>/dev/null || docker compose build

    # Start containers
    log "Iniciando containers..."
    docker compose up -d

    log "CTF deployed em $CTF_DIR"
}

# ============================================================================
# SYSTEMD SERVICE (AUTO-START ON BOOT)
# ============================================================================
install_systemd_service() {
    log "Configurando auto-start no boot..."

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
WorkingDirectory=/opt/CloudFragment
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
    cat > /etc/systemd/system/CloudFragment-watchdog.service << 'EOF'
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

    # Create watchdog script
    cat > /opt/CloudFragment/watchdog.sh << 'WATCHDOG'
#!/bin/bash
EXPECTED_CONTAINERS=("CloudFragment-edge" "CloudFragment-proxy" "CloudFragment-app" "CloudFragment-metadata" "CloudFragment-secrets")
FAIL_COUNT=0

while true; do
    UNHEALTHY=0
    for container in "${EXPECTED_CONTAINERS[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            UNHEALTHY=$((UNHEALTHY + 1))
        fi
    done
    
    if [[ $UNHEALTHY -gt 0 ]]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ $FAIL_COUNT -ge 3 ]]; then
            cd /opt/CloudFragment && docker compose up -d
            FAIL_COUNT=0
        fi
    else
        FAIL_COUNT=0
    fi
    sleep 60
done
WATCHDOG
    chmod +x /opt/CloudFragment/watchdog.sh

    # Enable services
    systemctl daemon-reload
    systemctl enable CloudFragment.service
    systemctl enable CloudFragment-watchdog.service

    log "Auto-start configurado (systemd)"
}

# ============================================================================
# CREATE HELPER SCRIPTS
# ============================================================================
create_helper_scripts() {
    log "Criando scripts auxiliares..."

    # Reset script
    cat > "$CTF_DIR/reset.sh" << 'RESET'
#!/bin/bash
set -e
cd /opt/CloudFragment
echo "Resetando CTF..."
docker compose down -v 2>/dev/null || true
docker compose up -d
echo "Reset completo!"
docker compose ps
RESET
    chmod +x "$CTF_DIR/reset.sh"

    # Status script
    cat > "$CTF_DIR/status.sh" << 'STATUS'
#!/bin/bash
cd /opt/CloudFragment
echo "=== Status Cloud Fragment ==="
echo ""
docker compose ps
echo ""
echo "Health: $(curl -s http://localhost/health 2>/dev/null || echo 'OFFLINE')"
STATUS
    chmod +x "$CTF_DIR/status.sh"

    # Symlinks
    ln -sf "$CTF_DIR/reset.sh" /usr/local/bin/ctf-reset 2>/dev/null || true
    ln -sf "$CTF_DIR/status.sh" /usr/local/bin/ctf-status 2>/dev/null || true

    log "Scripts: ctf-reset, ctf-status"
}

# ============================================================================
# VERIFY SETUP
# ============================================================================
verify_setup() {
    log "Verificando instalação..."

    echo ""
    info "=== Containers ==="
    docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || true

    echo ""
    info "=== Testes ==="

    # Test WAF health
    sleep 3
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "  HTTP localhost:    ${GREEN}OK (200)${NC}"
    else
        echo -e "  HTTP localhost:    ${YELLOW}HTTP $HTTP_CODE${NC}"
    fi

    # Test domain
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "  HTTP $DOMAIN: ${GREEN}OK (200)${NC}"
    else
        echo -e "  HTTP $DOMAIN: ${YELLOW}HTTP $HTTP_CODE${NC}"
    fi
}

# ============================================================================
# SHOW FINAL INSTRUCTIONS
# ============================================================================
show_final() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    INSTALAÇÃO COMPLETA! ✓                         ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  🌐 Acesse no navegador:                                          ║
║     → http://cloudfragment.htb                                    ║
║     → http://localhost                                            ║
║                                                                   ║
║  📁 Arquivos:                                                     ║
║     → CTF: /opt/CloudFragment                                    ║
║     → Logs: /var/log/CloudFragment-setup.log                     ║
║                                                                   ║
║  🛠️  Comandos:                                                     ║
║     → ctf-status    - Ver status                                  ║
║     → ctf-reset     - Resetar containers                          ║
║                                                                   ║
║  🔓 Exploit:                                                       ║
║     → python3 react2shell.py -u http://cloudfragment.htb          ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"
}

# ============================================================================
# QUICK RESET
# ============================================================================
quick_reset() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    QUICK RESET                                     ║
╚═══════════════════════════════════════════════════════════════════╝
"
    cd "$CTF_DIR"
    docker compose down -v 2>/dev/null || true
    docker compose up -d
    log "Reset completo!"
    docker compose ps
}

# ============================================================================
# HARD RESET
# ============================================================================
hard_reset() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    HARD RESET (REBUILD)                           ║
╚═══════════════════════════════════════════════════════════════════╝
"
    cd "$CTF_DIR"

    log "Parando containers..."
    docker compose down -v 2>/dev/null || true

    log "Limpando Docker..."
    docker system prune -af --volumes 2>/dev/null || true

    log "Reconstruindo imagens..."
    docker compose build --no-cache

    log "Iniciando..."
    docker compose up -d

    log "Hard reset completo!"
    docker compose ps
}

# ============================================================================
# EMERGENCY RECOVERY
# ============================================================================
emergency_recovery() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║              EMERGENCY RECOVERY - NUCLEAR OPTION                  ║
╚═══════════════════════════════════════════════════════════════════╝
"
    warn "Isso vai destruir tudo e reconstruir do zero!"
    read -p "Digite 'NUKE' para confirmar: " confirm

    if [[ "$confirm" != "NUKE" ]]; then
        echo "Abortado."
        exit 0
    fi

    log "Parando tudo..."
    systemctl stop CloudFragment-watchdog 2>/dev/null || true
    systemctl stop CloudFragment 2>/dev/null || true

    log "Matando containers..."
    docker kill $(docker ps -q) 2>/dev/null || true
    docker rm -f $(docker ps -aq) 2>/dev/null || true

    log "Removendo imagens..."
    docker rmi -f $(docker images -q) 2>/dev/null || true

    log "Limpando Docker..."
    docker system prune -af --volumes 2>/dev/null || true

    log "Restaurando backup..."
    if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
        rm -rf "$CTF_DIR"/*
        cp -r "$BACKUP_DIR"/* "$CTF_DIR"/
    fi

    log "Reconstruindo..."
    cd "$CTF_DIR"
    docker compose build --no-cache
    docker compose up -d

    log "Recovery completo!"
}

# ============================================================================
# STATUS
# ============================================================================
show_status() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    CLOUD FRAGMENT - STATUS                        ║
╚═══════════════════════════════════════════════════════════════════╝
"
    echo -e "${YELLOW}[Sistema]${NC}"
    echo "  Hostname: $(hostname)"
    echo "  Uptime:   $(uptime -p 2>/dev/null || echo 'N/A')"
    echo ""

    echo -e "${YELLOW}[Docker]${NC}"
    if systemctl is-active --quiet docker 2>/dev/null; then
        echo -e "  Status: ${GREEN}Rodando${NC}"
    else
        echo -e "  Status: ${RED}Parado${NC}"
    fi
    echo ""

    echo -e "${YELLOW}[Containers]${NC}"
    cd "$CTF_DIR" 2>/dev/null || cd /opt/CloudFragment
    docker compose ps 2>/dev/null || echo "  Erro ao listar"
    echo ""

    echo -e "${YELLOW}[Conectividade]${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "  WAF: ${GREEN}OK${NC}"
    else
        echo -e "  WAF: ${RED}OFFLINE${NC}"
    fi
}

# ============================================================================
# UNINSTALL
# ============================================================================
uninstall() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    DESINSTALAÇÃO                                  ║
╚═══════════════════════════════════════════════════════════════════╝
"
    warn "Removendo configuração..."

    # Stop containers
    cd "$CTF_DIR" 2>/dev/null || cd /opt/CloudFragment 2>/dev/null || true
    docker compose down -v 2>/dev/null || true

    # Restore /etc/hosts
    if [[ -f /etc/hosts.backup ]]; then
        cp /etc/hosts.backup /etc/hosts
        log "hosts restaurado"
    else
        sed -i "/$DOMAIN/d" /etc/hosts 2>/dev/null || true
    fi

    # Remove symlinks
    rm -f /usr/local/bin/ctf-reset 2>/dev/null || true
    rm -f /usr/local/bin/ctf-status 2>/dev/null || true

    log "Desinstalação completa"
}

# ============================================================================
# HELP
# ============================================================================
show_help() {
    echo "Cloud Fragment - Setup Completo Unificado"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos:"
    echo "  (sem comando)    Instalação completa"
    echo "  --status         Ver status do sistema"
    echo "  --reset          Reset rápido (reinicia containers)"
    echo "  --hard-reset     Reset completo (reconstrói imagens)"
    echo "  --emergency      Recovery nuclear (destrói tudo)"
    echo "  --uninstall      Remove configuração"
    echo "  --help           Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  sudo $0              # Instalação completa"
    echo "  sudo $0 --reset      # Resetar containers"
    echo "  sudo $0 --status     # Ver status"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    # Handle arguments
    case "${1:-}" in
        --status|-s)
            preflight
            show_status
            exit 0
            ;;
        --reset|-r)
            preflight
            quick_reset
            exit 0
            ;;
        --hard-reset|-H)
            preflight
            hard_reset
            exit 0
            ;;
        --emergency|-e)
            preflight
            emergency_recovery
            exit 0
            ;;
        --uninstall|-u)
            preflight
            uninstall
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac

    # Full installation
    show_banner
    preflight

    info "[1/10] Configurando sistema..."
    configure_system

    info "[2/10] Configurando DNS local..."
    configure_hosts

    info "[3/10] Instalando dependências..."
    install_dependencies

    info "[4/10] Instalando Docker..."
    install_docker

    info "[5/10] Configurando usuários..."
    setup_users

    info "[6/10] Configurando flags..."
    setup_flags

    info "[7/10] Configurando firewall..."
    setup_firewall

    info "[8/10] Deploy do CTF..."
    deploy_ctf

    info "[9/10] Criando scripts auxiliares..."
    create_helper_scripts

    info "[10/10] Configurando auto-start..."
    install_systemd_service

    # Start services
    systemctl start CloudFragment.service 2>/dev/null || true
    systemctl start CloudFragment-watchdog.service 2>/dev/null || true

    verify_setup
    show_final
}

main "$@"
