FROM openresty/openresty:alpine

# Install required Lua modules
RUN luarocks install lua-resty-http 2>/dev/null || true

# Copy WAF configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY waf.lua /usr/local/openresty/lualib/waf.lua

# Health check endpoint
COPY health.html /usr/local/openresty/nginx/html/health.html

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
