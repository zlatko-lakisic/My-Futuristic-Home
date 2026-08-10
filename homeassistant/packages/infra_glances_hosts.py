#!/usr/local/bin/python3
"""Pull host metrics from Glances API v4 for infrastructure dashboard cards.

Do not use /api/4/all: on some hosts (notably Jetson) the fs plugin hangs on
Docker/overlay mounts, which stalls /api/4/all long enough for Home Assistant's
command_line timeout to kill this script and wipe sensor attributes.
"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

HOSTS = {
    "garden_speaker": "http://192.168.89.27:61208",
    "gateway": "http://192.168.89.6:61208",
    "jetson": "http://172.16.90.20:61208",
    "nvr": "http://10.0.10.16:61208",
}

# Keep wall clock well under HA command_line timeout (raised to 25s in YAML).
TIMEOUT_FAST = 4.0
TIMEOUT_FS = 2.0

SKIP_NIC_PREFIXES = (
    "lo",
    "veth",
    "br-",
    "docker",
    "virbr",
    "wg",
    "tun",
    "tap",
    "cni",
    "flannel",
    "cali",
    "nodelocaldns",
    "kube-",
)


def _get(base: str, path: str, timeout: float) -> Any:
    url = base.rstrip("/") + path
    req = urllib.request.Request(url, headers={"User-Agent": "HomeAssistant-infra-glances"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
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
        if lname.startswith(SKIP_NIC_PREFIXES):
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
        preferred = lname.startswith(("en", "eth", "wlan", "wl"))
        best_preferred = bool(
            best_name and str(best_name).lower().startswith(("en", "eth", "wlan", "wl"))
        )
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


def _fetch_map(base: str) -> tuple[dict[str, Any], str | None]:
    """Fetch light plugins in parallel. fs is best-effort with a short timeout."""
    paths = {
        "cpu": ("/api/4/cpu", TIMEOUT_FAST),
        "mem": ("/api/4/mem", TIMEOUT_FAST),
        "network": ("/api/4/network", TIMEOUT_FAST),
        "uptime": ("/api/4/uptime", TIMEOUT_FAST),
        "core": ("/api/4/core", TIMEOUT_FAST),
        "gpu": ("/api/4/gpu", TIMEOUT_FAST),
        "fs": ("/api/4/fs", TIMEOUT_FS),
    }
    data: dict[str, Any] = {}
    errors: list[str] = []

    def one(key: str, path: str, timeout: float) -> tuple[str, Any, str | None]:
        try:
            return key, _get(base, path, timeout), None
        except Exception as err:  # noqa: BLE001 - surface to HA attribute
            return key, None, f"{key}:{err}"[:120]

    with ThreadPoolExecutor(max_workers=len(paths)) as pool:
        futs = [
            pool.submit(one, key, path, timeout)
            for key, (path, timeout) in paths.items()
        ]
        for fut in as_completed(futs):
            key, value, err = fut.result()
            data[key] = value
            if err:
                errors.append(err)

    # Host is usable if cpu answered; fs failures must not fail the whole host.
    summary = "; ".join(errors[:3]) if errors else None
    return data, summary


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
        data, partial_err = _fetch_map(base)
    except Exception as err:  # noqa: BLE001
        out["error"] = str(err)[:200]
        return out

    cpu = data.get("cpu")
    mem = data.get("mem")
    fs = data.get("fs")
    network = data.get("network")
    uptime = data.get("uptime")
    core = data.get("core")
    gpu = data.get("gpu")

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
    if partial_err and not out["ok"]:
        out["error"] = partial_err
    elif partial_err and out["disk_usage"] is None:
        # Keep ok=true for cpu/mem; note fs/other soft failures.
        out["error"] = partial_err
    return out


def main() -> None:
    result: dict[str, Any] = {}
    with ThreadPoolExecutor(max_workers=len(HOSTS)) as pool:
        futs = {pool.submit(host_metrics, base): name for name, base in HOSTS.items()}
        for fut in as_completed(futs):
            result[futs[fut]] = fut.result()
    # Stable key order for easier debugging in HA states.
    ordered = {name: result.get(name, {"ok": False, "error": "missing"}) for name in HOSTS}
    print(json.dumps(ordered))


if __name__ == "__main__":
    main()
    sys.stdout.flush()
