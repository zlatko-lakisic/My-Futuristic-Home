#!/usr/local/bin/python3
"""Health + GPU probe for the Jetson Agentic-Orchestration (AO) engine.

The Jetson AO exposes a public /health endpoint over plain TLS (self-signed, no client
cert required — presenting one actually resets the connection). /health returns engine
status plus hardware.gpu telemetry (compute % and VRAM via tegrastats), which is the
real source for the Jetson GPU gauges and the online/offline monitor.

Prints one JSON line: {ok, state, version, service, gpu_name, gpu_percent,
gpu_vram_percent, gpu_vram_used_gb, gpu_vram_total_gb, http, error}.
"""
from __future__ import annotations

import json
import ssl
import urllib.request

BASE = "https://172.16.90.20:8765"
PATHS = ("/health", "/")
TIMEOUT = 8


def _ctx():
    # Self-signed server cert; /health does not use mTLS (a client cert is rejected).
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def main():
    out = {
        "ok": False,
        "state": "offline",
        "version": None,
        "service": None,
        "gpu_name": None,
        "gpu_percent": None,
        "gpu_vram_percent": None,
        "gpu_vram_used_gb": None,
        "gpu_vram_total_gb": None,
        "http": None,
        "error": None,
    }
    ctx = _ctx()
    last_err = None
    for path in PATHS:
        try:
            req = urllib.request.Request(BASE + path, headers={"User-Agent": "HomeAssistant-Jetson-AO"})
            with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
                out["http"] = r.status
                raw = r.read().decode("utf-8", errors="replace")
            body = json.loads(raw) if raw.strip().startswith("{") else {}
            if isinstance(body, dict):
                out["version"] = body.get("version")
                out["service"] = body.get("service")
                ok = body.get("ok")
                out["ok"] = bool(ok) if ok is not None else (200 <= (out["http"] or 0) < 300)
                gpu = ((body.get("hardware") or {}).get("gpu")) or {}
                if isinstance(gpu, dict):
                    out["gpu_name"] = gpu.get("name")
                    out["gpu_percent"] = _num(gpu.get("percent"))
                    total = _num(gpu.get("vramTotalGb"))
                    used = _num(gpu.get("vramUsedGb"))
                    out["gpu_vram_used_gb"] = used
                    out["gpu_vram_total_gb"] = total
                    if total and used is not None:
                        out["gpu_vram_percent"] = round(used / total * 100.0, 1)
            else:
                out["ok"] = 200 <= (out["http"] or 0) < 300
            out["state"] = "online" if out["ok"] else "degraded"
            print(json.dumps(out))
            return
        except Exception as e:
            last_err = (path + ":" + str(e))[:160]
            continue
    out["error"] = last_err
    print(json.dumps(out))


if __name__ == "__main__":
    main()
