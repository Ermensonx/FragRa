#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - EMERGENCY RECOVERY
# Use this when everything is broken beyond repair
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CTF_DIR="/opt/CloudFragment"
BACKUP_DIR="/opt/CloudFragment-backup"

echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║         EMERGENCY RECOVERY - NUCLEAR OPTION           ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}This will:${NC}"
echo "  • Stop ALL Docker containers"
echo "  • Remove ALL Docker images, volumes, networks"
echo "  • Restore from backup"
echo "  • Rebuild everything from scratch"
echo ""
read -p "Are you sure? (type 'NUKE' to confirm): " confirm

if [[ "$confirm" != "NUKE" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/8]${NC} Stopping all services..."
systemctl stop CloudFragment-watchdog 2>/dev/null || true
systemctl stop CloudFragment 2>/dev/null || true

echo -e "${YELLOW}[2/8]${NC} Killing all containers..."
docker kill $(docker ps -q) 2>/dev/null || true

echo -e "${YELLOW}[3/8]${NC} Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo -e "${YELLOW}[4/8]${NC} Removing all images..."
docker rmi -f $(docker images -q) 2>/dev/null || true

echo -e "${YELLOW}[5/8]${NC} Pruning Docker system..."
docker system prune -af --volumes 2>/dev/null || true
docker network prune -f 2>/dev/null || true

echo -e "${YELLOW}[6/8]${NC} Restoring from backup..."
if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A $BACKUP_DIR)" ]]; then
    rm -rf "$CTF_DIR"/*
    cp -r "$BACKUP_DIR"/* "$CTF_DIR"/
    echo "  Restored from $BACKUP_DIR"
else
    echo -e "${RED}  No backup found! Keeping current files.${NC}"
fi

echo -e "${YELLOW}[7/8]${NC} Rebuilding images (this may take a while)..."
cd "$CTF_DIR"
docker compose build --no-cache

echo -e "${YELLOW}[8/8]${NC} Starting services..."
docker compose up -d
systemctl start CloudFragment-watchdog

# Wait and verify
sleep 10

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              RECOVERY COMPLETE!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Show status
docker compose ps

echo ""
echo -e "Run ${CYAN}ctf-status${NC} to verify everything"
