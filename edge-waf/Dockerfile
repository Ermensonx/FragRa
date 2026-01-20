FROM openresty/openresty:alpine

# Install required dependencies for GeoIP
RUN apk add --no-cache curl libmaxminddb libmaxminddb-dev

# Install required Lua modules
RUN luarocks install lua-resty-http 2>/dev/null || true

# Create GeoIP directory and download Brazil IP ranges
RUN mkdir -p /etc/nginx/geoip

# Download GeoLite2 Country database (free version)
# Note: In production, use your own MaxMind license key
# For CTF, we use a simple Brazil CIDR list approach instead
COPY brazil_cidrs.txt /etc/nginx/geoip/brazil_cidrs.txt

# Copy WAF configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY waf.lua /usr/local/openresty/lualib/waf.lua
COPY geocheck.lua /usr/local/openresty/lualib/geocheck.lua

# Health check endpoint
COPY health.html /usr/local/openresty/nginx/html/health.html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
