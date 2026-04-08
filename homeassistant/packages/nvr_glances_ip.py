#!/usr/local/bin/python3
"""Fetch Glances /api/4/ip; emit flat JSON for three NICs (command_line json_attributes)."""
import json
import sys
import urllib.request

BASE = "http://10.0.10.16:61208"
PATHS = ("/api/4/ip", "/api/3/ip")
TIMEOUT = 25
IFACES = ("enp3s0", "enp4s0", "br-9229c4b7924f")


def _extract_ipv4(node) -> str:
    if node is None:
        return "—"
    if isinstance(node, str) and "." in node:
        return node.split("/")[0].strip()
    if not isinstance(node, dict):
        return "—"
    for key in ("ipv4", "IPv4", "address", "ip_address"):
        v = node.get(key)
        if isinstance(v, str) and "." in v:
            return v.split("/")[0].strip()
    addrs = node.get("addresses")
    if isinstance(addrs, list):
        for a in addrs:
            if isinstance(a, str) and "." in a:
                return a.split("/")[0].strip()
            if isinstance(a, dict):
                for key in ("addr", "address", "ip"):
                    x = a.get(key)
                    if isinstance(x, str) and "." in x:
                        return x.split("/")[0].strip()
    return "—"


def _lookup(data: object, iface: str) -> str:
    if not isinstance(data, dict):
        return "—"
    for name in (iface, iface.replace("-", "_")):
        if name in data:
            return _extract_ipv4(data[name])
    return "—"


def main() -> None:
    out = {"enp3s0": "—", "enp4s0": "—", "br_9229c4b7924f": "—"}
    err = None
    raw = None
    for path in PATHS:
        url = BASE.rstrip("/") + path
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "HomeAssistant-NVR-ip"})
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                raw = r.read().decode("utf-8", errors="replace")
            data = json.loads(raw)
            break
        except Exception as e:
            err = str(e)
            data = None
    else:
        data = None

    if isinstance(data, dict):
        out["enp3s0"] = _lookup(data, "enp3s0")
        out["enp4s0"] = _lookup(data, "enp4s0")
        out["br_9229c4b7924f"] = _lookup(data, "br-9229c4b7924f")
    if err and all(v == "—" for v in out.values()):
        out["_error"] = err

    print(json.dumps(out))


if __name__ == "__main__":
    main()
    sys.stdout.flush()
