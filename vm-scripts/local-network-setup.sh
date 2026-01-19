#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - LOCAL NETWORK SETUP (NAT Mode)
# Configura a máquina local para rodar o CTF e acessar via navegador
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
CTF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
banner() { echo -e "${CYAN}$1${NC}"; }

# ============================================================================
# BANNER
# ============================================================================
show_banner() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║         CLOUD FRAGMENT - LOCAL NETWORK SETUP (NAT Mode)          ║
║         Instalação completa para acesso local                     ║
╚═══════════════════════════════════════════════════════════════════╝
"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================
preflight() {
    if [[ $EUID -ne 0 ]]; then
        error "Execute como root: sudo $0"
    fi

    if [[ ! -f "$CTF_DIR/docker-compose.yml" ]]; then
        error "docker-compose.yml não encontrado em $CTF_DIR"
    fi

    log "Verificações iniciais OK"
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
        net-tools

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
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

        log "Docker instalado com sucesso"
    else
        log "Docker já está instalado"
    fi

    # Ensure Docker is running
    if ! systemctl is-active --quiet docker; then
        systemctl start docker
    fi

    log "Dependências instaladas"
}

# ============================================================================
# CONFIGURE /etc/hosts
# ============================================================================
configure_hosts() {
    log "Configurando /etc/hosts..."

    # Backup original
    if [[ ! -f /etc/hosts.backup ]]; then
        cp /etc/hosts /etc/hosts.backup
    fi

    # Add domain entries if not present
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "127.0.0.1   $DOMAIN $MACHINE_NAME" >> /etc/hosts
        log "Adicionado: 127.0.0.1   $DOMAIN"
    else
        log "Entrada $DOMAIN já existe em /etc/hosts"
    fi

    log "/etc/hosts configurado"
}

# ============================================================================
# DEPLOY CONTAINERS
# ============================================================================
deploy_containers() {
    log "Fazendo deploy dos containers..."

    cd "$CTF_DIR"

    # Stop existing containers
    docker compose down 2>/dev/null || true

    # Build images
    log "Construindo imagens Docker (pode demorar alguns minutos)..."
    docker compose build --quiet

    # Start containers
    log "Iniciando containers..."
    docker compose up -d

    # Wait for containers to be healthy
    log "Aguardando containers ficarem prontos..."
    sleep 10

    # Verify containers are running
    RUNNING=$(docker compose ps --format json 2>/dev/null | jq -s 'length' 2>/dev/null || echo "0")
    
    if [[ "$RUNNING" -ge 5 ]]; then
        log "Todos os containers estão rodando ($RUNNING containers)"
    else
        warn "Apenas $RUNNING containers estão rodando (esperado: 5+)"
    fi
}

# ============================================================================
# VERIFY SETUP
# ============================================================================
verify_setup() {
    log "Verificando configuração..."

    echo ""
    info "=== Status dos Containers ==="
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Erro ao listar containers"

    echo ""
    info "=== Teste de Conectividade ==="

    # Test WAF health
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "  WAF Health: ${GREEN}OK (HTTP 200)${NC}"
    else
        echo -e "  WAF Health: ${RED}FALHA (HTTP $HTTP_CODE)${NC}"
    fi

    # Test domain resolution
    if ping -c 1 "$DOMAIN" &>/dev/null; then
        echo -e "  DNS ($DOMAIN): ${GREEN}OK${NC}"
    else
        echo -e "  DNS ($DOMAIN): ${YELLOW}Não resolvido (verifique /etc/hosts)${NC}"
    fi

    # Test via domain
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "  Acesso via domínio: ${GREEN}OK${NC}"
    else
        echo -e "  Acesso via domínio: ${YELLOW}HTTP $HTTP_CODE${NC}"
    fi
}

# ============================================================================
# SHOW FINAL INSTRUCTIONS
# ============================================================================
show_instructions() {
    banner "
╔═══════════════════════════════════════════════════════════════════╗
║                    INSTALAÇÃO COMPLETA! ✓                         ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Acesse no navegador:                                             ║
║    → http://cloudfragment.htb                                     ║
║    → http://localhost                                             ║
║                                                                   ║
║  Comandos úteis:                                                  ║
║    docker compose ps        - Ver status dos containers           ║
║    docker compose logs -f   - Ver logs em tempo real              ║
║    docker compose restart   - Reiniciar todos containers          ║
║    docker compose down      - Parar todos containers              ║
║                                                                   ║
║  Para testar o exploit:                                           ║
║    python3 react2shell.py -u http://cloudfragment.htb             ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"
}

# ============================================================================
# UNINSTALL (optional)
# ============================================================================
uninstall() {
    warn "Removendo configuração..."

    cd "$CTF_DIR"
    docker compose down -v 2>/dev/null || true

    # Restore /etc/hosts
    if [[ -f /etc/hosts.backup ]]; then
        cp /etc/hosts.backup /etc/hosts
        log "hosts restaurado"
    else
        # Remove our entries manually
        sed -i "/$DOMAIN/d" /etc/hosts
    fi

    log "Desinstalação completa"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    show_banner

    # Handle arguments
    case "${1:-}" in
        --uninstall|-u)
            preflight
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "Uso: $0 [OPÇÃO]"
            echo ""
            echo "Opções:"
            echo "  (sem opção)     Instalação completa"
            echo "  --uninstall     Remove configuração"
            echo "  --help          Mostra esta ajuda"
            exit 0
            ;;
    esac

    # Run installation
    preflight

    info "[1/4] Instalando dependências..."
    install_dependencies

    info "[2/4] Configurando DNS local..."
    configure_hosts

    info "[3/4] Deploy dos containers..."
    deploy_containers

    info "[4/4] Verificando..."
    verify_setup

    show_instructions
}

main "$@"
