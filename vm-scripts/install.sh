#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - FIRST BOOT INSTALLER
# Run this ONCE on a fresh Ubuntu Server 22.04 VM
# ============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'BANNER'
   _____ _                 _   ______                                     _   
  / ____| |               | | |  ____|                                   | |  
 | |    | | ___  _   _  __| | | |__ _ __ __ _  __ _ _ __ ___   ___ _ __ | |_ 
 | |    | |/ _ \| | | |/ _` | |  __| '__/ _` |/ _` | '_ ` _ \ / _ \ '_ \| __|
 | |____| | (_) | |_| | (_| | | |  | | | (_| | (_| | | | | | |  __/ | | | |_ 
  \_____|_|\___/ \__,_|\__,_| |_|  |_|  \__,_|\__, |_| |_| |_|\___|_| |_|\__|
                                               __/ |                         
                                              |___/   HTB Machine Installer
BANNER
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo ./install.sh"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}[PRE-CHECK]${NC} Verifying source files..."

# Check if we have the required files
if [[ ! -f "$PARENT_DIR/docker-compose.yml" ]]; then
    echo "ERROR: docker-compose.yml not found in $PARENT_DIR"
    echo "Make sure all CTF files are in the parent directory"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Source files found"
echo ""

echo -e "${YELLOW}[1/4]${NC} Copying CTF files to /opt/CloudFragment..."
mkdir -p /opt/CloudFragment
cp -r "$PARENT_DIR"/* /opt/CloudFragment/
rm -rf /opt/CloudFragment/vm-scripts  # Don't copy scripts again

echo -e "${YELLOW}[2/4]${NC} Creating backup..."
mkdir -p /opt/CloudFragment-backup
cp -r /opt/CloudFragment/* /opt/CloudFragment-backup/
rm -rf /opt/CloudFragment-backup/vm-scripts 2>/dev/null || true

echo -e "${YELLOW}[3/4]${NC} Copying management scripts..."
cp "$SCRIPT_DIR/setup.sh" /opt/CloudFragment/
cp "$SCRIPT_DIR/emergency-recovery.sh" /opt/CloudFragment/
chmod +x /opt/CloudFragment/*.sh

echo -e "${YELLOW}[4/4]${NC} Running main setup..."
echo ""

# Run the main setup
cd /opt/CloudFragment
./setup.sh

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Available commands:"
echo "  ctf-status  - Check system status"
echo "  ctf-reset   - Quick reset"
echo "  ctf-reset --hard - Full rebuild"
echo ""
echo "Target: http://cloudfragment.htb"
