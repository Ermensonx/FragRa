-- ============================================================================
-- EdgeShield WAF - Cloud Fragment CTF
-- Blocks shell patterns EXCEPT for /tmp binaries (intended path)
-- ============================================================================

local _M = {}

-- Generate CF-like Ray ID
local function generate_ray_id()
    local chars = "0123456789abcdef"
    local ray = ""
    for i = 1, 16 do
        local idx = math.random(1, #chars)
        ray = ray .. chars:sub(idx, idx)
    end
    local locations = {"IAD", "SFO", "LHR", "FRA", "NRT", "SYD", "GRU"}
    return ray .. "-" .. locations[math.random(1, #locations)]
end

-- Check if request has Server Action headers
local function is_server_action()
    local next_action = ngx.req.get_headers()["Next-Action"]
    return next_action ~= nil
end

-- Helper to get request body properly (from memory or file)
local function get_request_body()
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        local file = ngx.req.get_body_file()
        if file then
            local f = io.open(file, "r")
            if f then
                body = f:read("*all")
                f:close()
            end
        end
    end
    return body or ""
end

-- Check if command uses /tmp binary or targets /tmp (allowed path)
local function uses_tmp_binary()
    local body = get_request_body()
    if not body then return false end
    
    -- Simple check: if /tmp/ appears anywhere, allow it
    -- This is the intended solve path - players upload binaries to /tmp and use them
    if body:find("/tmp/") then return true end
    
    return false
end

-- Check for SHELL patterns - BLOCKED unless using /tmp binary
local function check_shell_patterns()
    local body = get_request_body()
    if not body then return false, nil end
    
    local body_lower = body:lower()
    
    -- Reverse shell patterns
    local shell_patterns = {
        -- Bash reverse shells (not from /tmp)
        "/dev/tcp/",
        "/dev/udp/",
        "bash -i",
        "sh -i",
        -- Built-in network tools for shells
        "nc -e",
        "nc -c",
        "netcat -e",
        "netcat -c",
        "socat",
        -- Python/Perl reverse shells
        "pty.spawn",
        "os.dup2",
        "perl -e.*socket",
        "ruby -rsocket",
        "php -r.*fsockopen",
        -- Node.js reverse shells
        "net.connect",
        "net.createConnection",
        "net.Socket",
        -- Block direct Node execution
        "node -e",
        "node --eval",
        "node -pe",
        "node --print",
        "node -r",
        "node --require",
        -- Mkfifo based
        "mkfifo",
        "mknod",
        -- Common reverse shell indicators
        "0>&1",
        "1>&0",
        ">&/dev",
        "/bin/sh -i",
        "/bin/bash -i",
        -- Blocked commands (force interactive shell)
        "cat ",
        "tail ",
        "head ",
        "more ",
        "less ",
        -- Block sensitive paths
        "/run/secrets",
        "kubernetes.io",
    }
    
    for _, pattern in ipairs(shell_patterns) do
        if body:find(pattern, 1, true) or body_lower:find(pattern:lower(), 1, true) then
            return true, pattern
        end
    end
    
    return false, nil
end

-- Main WAF check function
function _M.check_request()
    local result = {
        blocked = false,
        status = 200,
        ray_id = generate_ray_id(),
        reason = nil
    }
    
    local uri = ngx.var.uri
    local method = ngx.req.get_method()
    local is_sa = is_server_action()
    
    -- Only inspect POST requests with Server Action headers
    if method ~= "POST" or not is_sa then
        return result
    end
    
    -- Rule 1: Block root path "/" completely
    if uri == "/" then
        result.blocked = true
        result.status = 403
        result.reason = "Blocked on root path - use alternative endpoints"
        return result
    end
    
    -- Rule 2: If using /tmp binary, ALLOW EVERYTHING
    -- This is the intended solve path - upload binary and use it
    if uses_tmp_binary() then
        return result  -- Allow through, no restrictions
    end
    
    -- Anti-Cheese: Limit request body size for Server Actions
    -- Forces use of chunked uploads for large binaries (like ncat/busybox)
    local content_length = tonumber(ngx.var.http_content_length) or 0
    if content_length > 65536 then
        result.blocked = true
        result.status = 403
        result.reason = "Payload too large. Use chunked transfer for files > 64KB."
        return result
    end

    -- Rule 3: Block shell patterns (simple)
    local has_shell, shell_pattern = check_shell_patterns()
    if has_shell then
        result.blocked = true
        result.status = 403
        result.reason = "Shell execution blocked. Upload your binary to /tmp/ and run it directly."
        return result
    end
    
    -- Random 503 challenge (0.5% chance)
    if math.random(1, 200) == 1 then
        result.blocked = true
        result.status = 503
        result.reason = "Challenge required"
        return result
    end
    
    return result
end

return _M
