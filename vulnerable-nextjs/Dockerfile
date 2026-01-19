# ==============================================================================
# VULNERABLE NEXT.JS APPLICATION - Cloud Fragment CTF
# MID-HARDENED: Clean system, minimal users, no exploitation tools
# ==============================================================================

FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache build-base python3

COPY package.json ./
RUN npm install --legacy-peer-deps

COPY . .
RUN npm run build

# Build the TTY-locked token reader
COPY read_token.c .
RUN gcc -o /usr/local/bin/read_token read_token.c && \
    rm read_token.c

# ============================================================================
# RUNNER STAGE
# ============================================================================
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy essential files
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /usr/local/bin/read_token /usr/local/bin/read_token

# Hardening: Remove almost everything from the shell
# We keep only 'node', 'sh', and 'read_token'
# Players must upload their own tools (busybox, ncat) to /tmp
RUN set -ex && \
    # Ensure token is root-only
    mkdir -p /run/secrets/kubernetes.io/serviceaccount && \
    echo "k8s-sa-token-cloud-fragment-ops-console-815791b1ee293f661fad31de6db24c2d" > /run/secrets/kubernetes.io/serviceaccount/token && \
    chmod 400 /run/secrets/kubernetes.io/serviceaccount/token && \
    # Setuid for our special binary
    chmod 4755 /usr/local/bin/read_token && \
    # Cleanup: Remove NETWORK tools but KEEP local utilities needed for exploit
    # We remove: nc, netcat, wget, curl, telnet
    # We keep: sh, node, read_token, base64, cat, ls, id, whoami, etc.
    rm -f /usr/bin/nc /usr/bin/ncat /usr/bin/netcat /usr/bin/wget /usr/bin/curl /usr/bin/telnet 2>/dev/null || true && \
    rm -f /bin/nc /bin/ncat /bin/netcat /bin/wget /bin/curl /bin/telnet 2>/dev/null || true && \
    # Ensure sh is busybox
    ln -sf /bin/busybox /bin/sh && \
    \
    # Remove shadow file (no passwords)
    rm -f /etc/shadow 2>/dev/null || true && \
    \
    # Remove scripting languages
    rm -f /usr/bin/python* /usr/bin/perl* /usr/bin/ruby* /usr/bin/php* 2>/dev/null || true && \
    \
    # Remove compilers
    rm -f /usr/bin/gcc /usr/bin/cc /usr/bin/make 2>/dev/null || true && \
    \
    # Remove package manager completely
    rm -rf /sbin/apk /etc/apk /lib/apk /var/cache/apk 2>/dev/null || true && \
    \
    # Remove editors
    # Remove editors
    rm -f /usr/bin/vi /usr/bin/vim /usr/bin/nano 2>/dev/null || true && \
    \
    # ==========================================
    # EXTREME HARDENING: NODE & UTILS CASTRATION
    # ==========================================
    \
    # 1. Remove core utilities to force tools upload
    # This prevents 'cat /home/node/user.txt' even if WAF is bypassed
    rm -f /bin/cat /usr/bin/cat \
    /bin/head /usr/bin/head \
    /bin/tail /usr/bin/tail \
    /bin/more /usr/bin/more \
    /bin/less /usr/bin/less \
    /usr/bin/xxd /usr/bin/od && \
    \
    # 2. Castrate Node.js (Block -e, --eval, etc)
    # Move real binary
    mv /usr/local/bin/node /usr/local/bin/node_real && \
    # Create wrapper script
    echo '#!/bin/sh' > /usr/local/bin/node && \
    echo 'for arg in "$@"; do' >> /usr/local/bin/node && \
    echo '  case "$arg" in' >> /usr/local/bin/node && \
    echo '    -e|--eval|-p|--print|-i|--interactive|-r|--require)' >> /usr/local/bin/node && \
    echo '      echo "Error: Node.js is restricted on this system."' >> /usr/local/bin/node && \
    echo '      exit 1 ;;' >> /usr/local/bin/node && \
    echo '  esac' >> /usr/local/bin/node && \
    echo 'done' >> /usr/local/bin/node && \
    echo 'exec /usr/local/bin/node_real "$@"' >> /usr/local/bin/node && \
    chmod +x /usr/local/bin/node && \
    \
    # Clean logs and temp
    rm -rf /var/log/* /tmp/* 2>/dev/null || true

USER node

EXPOSE 3000

# Use real node for server startup so it doesn't break
CMD ["node_real", "server.js"]
