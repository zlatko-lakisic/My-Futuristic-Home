#!/usr/bin/env python3
"""Remove HA IP bans that fall inside private/LAN CIDRs.

Home Assistant has no native ip_ban allowlist (core has declined whitelist PRs).
This script is the local-network safety net: never leave LAN/proxy hops banned
in /config/ip_bans.yaml.

Exit 0 always. Prints one line:
  OK unchanged
  CHANGED removed=<csv>
"""
from __future__ import annotations

import ipaddress
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    # HAOS image has PyYAML; fall back to a tiny parser for simple ban maps.
    yaml = None

BANS_PATH = Path("/config/ip_bans.yaml")
NEVER_BAN = [
    ipaddress.ip_network("192.168.88.0/24"),
    ipaddress.ip_network("192.168.89.0/24"),
    ipaddress.ip_network("192.168.90.0/24"),
    ipaddress.ip_network("172.16.90.0/24"),
    ipaddress.ip_network("172.16.91.0/24"),
    ipaddress.ip_network("10.0.10.0/24"),
    ipaddress.ip_network("127.0.0.0/8"),
]


def _in_never_ban(ip_str: str) -> bool:
    try:
        addr = ipaddress.ip_address(ip_str.strip())
    except ValueError:
        return False
    return any(addr in net for net in NEVER_BAN)


def _load(path: Path) -> dict:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return {}
    if yaml is not None:
        data = yaml.safe_load(text) or {}
        if not isinstance(data, dict):
            return {}
        return data
    # Minimal fallback: top-level keys are IPs
    out: dict = {}
    cur = None
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith(" ") or line.startswith("\t"):
            if cur is not None and "banned_at" in line:
                _, _, val = line.partition(":")
                out.setdefault(cur, {})["banned_at"] = val.strip().strip("'\"")
            continue
        key = line.split(":", 1)[0].strip()
        cur = key
        out[cur] = {}
    return out


def _dump(data: dict) -> str:
    if not data:
        return ""
    if yaml is not None:
        return yaml.safe_dump(data, default_flow_style=False, sort_keys=False)
    lines: list[str] = []
    for ip, info in data.items():
        lines.append(f"{ip}:")
        if isinstance(info, dict) and info.get("banned_at"):
            lines.append(f"  banned_at: '{info['banned_at']}'")
        else:
            lines.append("  banned_at: null")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    data = _load(BANS_PATH)
    removed = [ip for ip in list(data) if _in_never_ban(str(ip))]
    if not removed:
        print("OK unchanged")
        return 0
    for ip in removed:
        data.pop(ip, None)
    BANS_PATH.write_text(_dump(data), encoding="utf-8")
    print("CHANGED removed=" + ",".join(removed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
