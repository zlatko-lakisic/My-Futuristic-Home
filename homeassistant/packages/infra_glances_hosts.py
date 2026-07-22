#!/usr/local/bin/python3
"""Pull host metrics from Glances API v4 for infrastructure dashboard cards."""
from __future__ import annotations

import json
import sys
import urllib.request
from typing import Any

HOSTS = {
    "garden_speaker": "http://192.168.89.27:61208",
    "jetson": "http://172.16.90.20:61208",
    "nvr": "http://10.0.10.16:61208",
}
TIMEOUT = 20


def _get(base: str, path: str) -> Any:
    url = base.rstrip("/") + path
    req = urllib.request.Request(url, headers={"User-Agent": "HomeAssistant-infra-glances"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.loads(resp.read().decode("utf-8", errors="replace"))


def _num(value: Any, default: float | None = None) -> float | None:
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _pick_nic(network: Any) -> tuple[str | None, dict]:
    items: list[tuple[str, dict]] = []
    if isinstance(network, dict):
        for name, node in network.items():
            if isinstance(node, dict):
                items.append((str(name), node))
    elif isinstance(network, list):
        for node in network:
            if isinstance(node, dict):
                name = str(node.get("interface_name") or node.get("name") or "")
                if name:
                    items.append((name, node))

    best_name = None
    best: dict = {}
    best_score = -1.0
    for name, node in items:
        lname = name.lower()
        if lname.startswith(("lo", "veth", "br-", "docker", "virbr", "wg", "tun", "tap")):
            continue
        rx = (
            _num(node.get("bytes_recv_rate_per_sec"))
            or _num(node.get("rx_rate_per_sec"))
            or _num(node.get("rx_rate"))
            or _num(node.get("rx"))
            or 0.0
        )
        tx = (
            _num(node.get("bytes_sent_rate_per_sec"))
            or _num(node.get("tx_rate_per_sec"))
            or _num(node.get("tx_rate"))
            or _num(node.get("tx"))
            or 0.0
        )
        score = float(rx) + float(tx)
        preferred = lname.startswith(("en", "eth", "wlan"))
        best_preferred = bool(best_name and str(best_name).lower().startswith(("en", "eth", "wlan")))
        if score > best_score or (score == best_score and preferred and not best_preferred):
            best_score = score
            best_name = name
            best = node
    return best_name, best


def _root_disk(fs: Any) -> dict:
    if not isinstance(fs, list):
        return {}
    for item in fs:
        if isinstance(item, dict) and item.get("mnt_point") == "/":
            return item
    return fs[0] if fs and isinstance(fs[0], dict) else {}


def _gpu_usage(gpu: Any) -> float | None:
    if not isinstance(gpu, list) or not gpu:
        return None
    first = gpu[0]
    if not isinstance(first, dict):
        return None
    for key in ("proc", "gpu_proc", "memory_percent", "mem"):
        val = _num(first.get(key))
        if val is not None:
            return val
    return None


def host_metrics(base: str) -> dict[str, Any]:
    out: dict[str, Any] = {
        "ok": False,
        "cpu_usage": None,
        "memory_usage": None,
        "memory_use_mib": None,
        "disk_usage": None,
        "uptime": None,
        "nic": None,
        "rx": None,
        "tx": None,
        "gpu_usage": None,
        "cpu_count": None,
        "error": None,
    }
    try:
        data = _get(base, "/api/4/all")
    except Exception as err:  # noqa: BLE001 - surface to HA attribute
        out["error"] = str(err)[:200]
        return out

    cpu = data.get("cpu") if isinstance(data, dict) else None
    mem = data.get("mem") if isinstance(data, dict) else None
    fs = data.get("fs") if isinstance(data, dict) else None
    network = data.get("network") if isinstance(data, dict) else None
    uptime = data.get("uptime") if isinstance(data, dict) else None
    core = data.get("core") if isinstance(data, dict) else None
    gpu = data.get("gpu") if isinstance(data, dict) else None

    out["cpu_usage"] = _num((cpu or {}).get("total") if isinstance(cpu, dict) else None)
    if isinstance(mem, dict):
        out["memory_usage"] = _num(mem.get("percent"))
        used = _num(mem.get("used"))
        if used is not None:
            out["memory_use_mib"] = round(used / (1024 * 1024), 2)
    disk = _root_disk(fs)
    out["disk_usage"] = _num(disk.get("percent"))
    out["uptime"] = uptime if isinstance(uptime, str) else None
    if isinstance(core, dict):
        count = _num(core.get("log") or core.get("phys"))
        out["cpu_count"] = int(count) if count is not None else None
    elif isinstance(core, int):
        out["cpu_count"] = core

    nic_name, nic = _pick_nic(network)
    out["nic"] = nic_name
    if nic:
        out["rx"] = (
            _num(nic.get("bytes_recv_rate_per_sec"))
            or _num(nic.get("rx_rate_per_sec"))
            or _num(nic.get("rx_rate"))
        )
        out["tx"] = (
            _num(nic.get("bytes_sent_rate_per_sec"))
            or _num(nic.get("tx_rate_per_sec"))
            or _num(nic.get("tx_rate"))
        )

    out["gpu_usage"] = _gpu_usage(gpu)
    out["ok"] = out["cpu_usage"] is not None
    return out


def main() -> None:
    result = {name: host_metrics(base) for name, base in HOSTS.items()}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
    sys.stdout.flush()
