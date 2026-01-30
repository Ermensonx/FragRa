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

-- Unicode normalization to prevent bypass attacks
-- Converts fullwidth, homoglyphs and other Unicode tricks to ASCII
local function normalize_unicode(str)
    if not str then return "" end
    
    -- Fullwidth ASCII variants (U+FF01 to U+FF5E) -> ASCII (0x21 to 0x7E)
    -- These are commonly used to bypass WAF: ｃａｔ instead of cat
    local result = str:gsub("[\239\188\129-\239\189\158]", function(char)
        local b1, b2, b3 = char:byte(1, 3)
        if b1 == 239 and b2 == 188 then
            -- First range: FF01-FF3F -> 21-5F (!-_)
            return string.char(b3 - 128 + 0x21)
        elseif b1 == 239 and b2 == 189 then
            -- Second range: FF40-FF5E -> 60-7E (`-~)
            return string.char(b3 - 128 + 0x60)
        end
        return char
    end)
    
    -- Common homoglyph replacements (Cyrillic, Greek that look like Latin)
    local homoglyphs = {
        -- Cyrillic lookalikes
        ["\208\176"] = "a", -- а -> a
        ["\208\181"] = "e", -- е -> e
        ["\208\190"] = "o", -- о -> o
        ["\209\128"] = "p", -- р -> p
        ["\209\129"] = "c", -- с -> c
        ["\209\133"] = "x", -- х -> x
        ["\209\131"] = "y", -- у -> y
        ["\208\179"] = "r", -- г -> r (close enough)
        ["\208\186"] = "k", -- к -> k
        ["\208\188"] = "m", -- м -> m
        ["\208\189"] = "n", -- н -> n
        ["\209\130"] = "t", -- т -> t
        -- Greek lookalikes
        ["\206\177"] = "a", -- α -> a
        ["\206\181"] = "e", -- ε -> e
        ["\206\191"] = "o", -- ο -> o
        -- Zero-width characters (remove them)
        ["\226\128\139"] = "", -- zero-width space
        ["\226\128\140"] = "", -- zero-width non-joiner
        ["\226\128\141"] = "", -- zero-width joiner
        ["\239\187\191"] = "", -- BOM
        ["\194\173"] = "",     -- soft hyphen
    }
    
    for unicode, ascii in pairs(homoglyphs) do
        result = result:gsub(unicode, ascii)
    end
    
    -- Remove other invisible/control characters
    result = result:gsub("[\0-\8\11\12\14-\31]", "")
    
    return result
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
    
    -- CRITICAL: Normalize Unicode to prevent bypass attacks
    -- This converts fullwidth chars (ｃａｔ), Cyrillic lookalikes, etc to ASCII
    local normalized_body = normalize_unicode(body)
    local body_lower = normalized_body:lower()
    
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
        -- Check both normalized body (to catch Unicode bypass) and lowercase
        if normalized_body:find(pattern, 1, true) or body_lower:find(pattern:lower(), 1, true) then
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
