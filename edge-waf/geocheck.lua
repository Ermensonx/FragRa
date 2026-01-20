-- ============================================================================
-- GeoCheck Module - Brazil IP Verification
-- Blocks all IPs not from Brazil
-- ============================================================================

local _M = {}

-- Parse CIDR notation to IP range
local function parse_cidr(cidr)
    local ip, prefix = cidr:match("^([%d%.]+)/(%d+)$")
    if not ip or not prefix then
        return nil
    end
    
    prefix = tonumber(prefix)
    if prefix < 0 or prefix > 32 then
        return nil
    end
    
    -- Convert IP to number
    local octets = {}
    for octet in ip:gmatch("%d+") do
        table.insert(octets, tonumber(octet))
    end
    
    if #octets ~= 4 then
        return nil
    end
    
    local ip_num = (octets[1] * 16777216) + (octets[2] * 65536) + (octets[3] * 256) + octets[4]
    local mask = 0xFFFFFFFF - (2^(32 - prefix) - 1)
    local network = bit.band(ip_num, mask)
    local broadcast = bit.bor(network, bit.bnot(mask))
    
    return network, broadcast
end

-- Convert IP string to number
local function ip_to_number(ip)
    local octets = {}
    for octet in ip:gmatch("%d+") do
        table.insert(octets, tonumber(octet))
    end
    
    if #octets ~= 4 then
        return nil
    end
    
    return (octets[1] * 16777216) + (octets[2] * 65536) + (octets[3] * 256) + octets[4]
end

-- Load CIDR list from file
local brazil_cidrs = nil

local function load_brazil_cidrs()
    if brazil_cidrs then
        return brazil_cidrs
    end
    
    brazil_cidrs = {}
    local file = io.open("/etc/nginx/geoip/brazil_cidrs.txt", "r")
    if not file then
        ngx.log(ngx.ERR, "GeoCheck: Could not load Brazil CIDR file")
        return brazil_cidrs
    end
    
    for line in file:lines() do
        -- Skip comments and empty lines
        line = line:gsub("^%s*(.-)%s*$", "%1")  -- trim
        if line ~= "" and not line:match("^#") then
            local network, broadcast = parse_cidr(line)
            if network and broadcast then
                table.insert(brazil_cidrs, {network = network, broadcast = broadcast})
            end
        end
    end
    
    file:close()
    ngx.log(ngx.INFO, "GeoCheck: Loaded " .. #brazil_cidrs .. " Brazil CIDR ranges")
    return brazil_cidrs
end

-- Check if IP is from Brazil
function _M.is_brazil(ip)
    -- Handle nil or empty IP
    if not ip or ip == "" then
        return false
    end
    
    -- Always allow localhost and private IPs
    if ip:match("^127%.") or ip:match("^10%.") or ip:match("^192%.168%.") or ip:match("^172%.1[6-9]%.") or ip:match("^172%.2%d%.") or ip:match("^172%.3[0-1]%.") then
        return true
    end
    
    local ip_num = ip_to_number(ip)
    if not ip_num then
        return false
    end
    
    local cidrs = load_brazil_cidrs()
    
    for _, cidr in ipairs(cidrs) do
        if ip_num >= cidr.network and ip_num <= cidr.broadcast then
            return true
        end
    end
    
    return false
end

-- Get country info for logging
function _M.get_country(ip)
    if _M.is_brazil(ip) then
        return "BR"
    else
        return "BLOCKED"
    end
end

return _M
