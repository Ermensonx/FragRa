#!/bin/bash
# ============================================================================
# CLOUD FRAGMENT - PRE-EXPORT CHECKLIST
# Run this before exporting the VM for HTB submission
# ============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

pass() { echo -e "${GREEN}[✓]${NC} $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}[✗]${NC} $1"; FAILED=$((FAILED + 1)); }
warn() { echo -e "${YELLOW}[!]${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       HTB PRE-EXPORT VERIFICATION CHECKLIST           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# GENERAL REQUIREMENTS
# ============================================================================
echo -e "${YELLOW}=== General Requirements ===${NC}"

# Hostname
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == "cloudfragment" ]]; then
    pass "Hostname: $HOSTNAME"
else
    fail "Hostname should be 'cloudfragment', got: $HOSTNAME"
fi

# Locale
LOCALE=$(locale | grep LANG= | cut -d= -f2)
if [[ "$LOCALE" == "en_US.UTF-8" ]] || [[ "$LOCALE" == *"en_US"* ]]; then
    pass "Locale: $LOCALE"
else
    warn "Locale should be en_US.UTF-8, got: $LOCALE"
fi

# Domain in hosts
if grep -q "cloudfragment.htb" /etc/hosts; then
    pass "Domain in /etc/hosts: cloudfragment.htb"
else
    fail "Missing cloudfragment.htb in /etc/hosts"
fi

echo ""

# ============================================================================
# FLAGS
# ============================================================================
echo -e "${YELLOW}=== Flag Verification ===${NC}"

# User flag
if [[ -f /home/node/user.txt ]]; then
    USER_FLAG=$(cat /home/node/user.txt)
    if [[ ${#USER_FLAG} -eq 32 ]] && [[ "$USER_FLAG" =~ ^[a-f0-9]+$ ]]; then
        pass "User flag: valid MD5 format"
    else
        fail "User flag not in MD5 format (32 hex chars)"
    fi
    
    # Check permissions
    PERMS=$(stat -c "%a" /home/node/user.txt)
    OWNER=$(stat -c "%U:%G" /home/node/user.txt)
    if [[ "$PERMS" == "640" ]]; then
        pass "User flag permissions: $PERMS"
    else
        warn "User flag permissions should be 640, got: $PERMS"
    fi
    if [[ "$OWNER" == "root:node" ]]; then
        pass "User flag ownership: $OWNER"
    else
        warn "User flag ownership should be root:node, got: $OWNER"
    fi
else
    fail "User flag missing: /home/node/user.txt"
fi

# Root flag
if [[ -f /root/root.txt ]]; then
    ROOT_FLAG=$(cat /root/root.txt)
    if [[ ${#ROOT_FLAG} -eq 32 ]] && [[ "$ROOT_FLAG" =~ ^[a-f0-9]+$ ]]; then
        pass "Root flag: valid MD5 format"
    else
        fail "Root flag not in MD5 format (32 hex chars)"
    fi
    
    PERMS=$(stat -c "%a" /root/root.txt)
    if [[ "$PERMS" == "640" ]]; then
        pass "Root flag permissions: $PERMS"
    else
        warn "Root flag permissions should be 640, got: $PERMS"
    fi
else
    fail "Root flag missing: /root/root.txt"
fi

echo ""

# ============================================================================
# HISTORY FILES
# ============================================================================
echo -e "${YELLOW}=== History Redirection ===${NC}"

for hist_file in /root/.bash_history /home/node/.bash_history; do
    if [[ -L "$hist_file" ]] && [[ "$(readlink -f $hist_file)" == "/dev/null" ]]; then
        pass "$(basename $hist_file) -> /dev/null"
    elif [[ ! -f "$hist_file" ]] || [[ ! -s "$hist_file" ]]; then
        warn "$hist_file exists but not symlinked to /dev/null"
    else
        fail "$hist_file contains data (should be empty or -> /dev/null)"
    fi
done

echo ""

# ============================================================================
# DISK SIZE
# ============================================================================
echo -e "${YELLOW}=== Disk Usage ===${NC}"

DISK_USED=$(df -BG / | awk 'NR==2 {gsub("G",""); print $3}')
if [[ "$DISK_USED" -le 10 ]]; then
    pass "Disk usage: ${DISK_USED}GB (limit: 10GB)"
else
    fail "Disk usage: ${DISK_USED}GB exceeds 10GB limit"
fi

echo ""

# ============================================================================
# DOCKER & SERVICES
# ============================================================================
echo -e "${YELLOW}=== Services ===${NC}"

if systemctl is-active --quiet docker; then
    pass "Docker: running"
else
    fail "Docker: not running"
fi

if systemctl is-enabled --quiet docker; then
    pass "Docker: enabled at boot"
else
    warn "Docker not enabled at boot"
fi

if systemctl is-enabled --quiet CloudFragment 2>/dev/null; then
    pass "CloudFragment.service: enabled"
else
    warn "CloudFragment.service not enabled"
fi

# Check containers
CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
if [[ "$CONTAINER_COUNT" -ge 5 ]]; then
    pass "Containers running: $CONTAINER_COUNT"
else
    warn "Only $CONTAINER_COUNT containers running (expected 5+)"
fi

echo ""

# ============================================================================
# NETWORK
# ============================================================================
echo -e "${YELLOW}=== Network ===${NC}"

# Check port 80
if ss -tlnp | grep -q ":80 "; then
    pass "Port 80: listening"
else
    fail "Port 80: not listening"
fi

# Check port 443
if ss -tlnp | grep -q ":443 "; then
    pass "Port 443: listening"
else
    warn "Port 443: not listening"
fi

# Health check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
    pass "WAF health endpoint: HTTP $HTTP_CODE"
else
    warn "WAF health endpoint: HTTP $HTTP_CODE (expected 200)"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, ${YELLOW}$WARNINGS warnings${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ VM is ready for HTB submission!${NC}"
    exit 0
else
    echo -e "${RED}✗ Please fix the failed checks before submitting.${NC}"
    exit 1
fi
