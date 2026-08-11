#!/usr/local/bin/python3
"""Import HAOS CONFIG USB (authorized_keys -> host SSH on port 22222).

Runs inside Home Assistant Core so SUPERVISOR_TOKEN can call Supervisor.
Prints one JSON line for a command_line sensor; full dump goes to www/tmp.
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

TOKEN = os.environ.get("SUPERVISOR_TOKEN", "")
BASE = "http://supervisor"
DUMP = "/config/www/tmp/ha_os_config_sync.json"


def call(method: str, path: str, payload: dict | None = None) -> dict:
    body = None if payload is None else json.dumps(payload).encode()
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "X-Supervisor-Token": TOKEN,
        "Content-Type": "application/json",
    }
    req = urllib.request.Request(
        BASE + path,
        data=body if body is not None else b"",
        method=method,
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            parsed = json.loads(raw) if raw else None
            return {"ok": True, "status": resp.status, "body": parsed}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw)
        except Exception:
            parsed = raw
        return {"ok": False, "status": exc.code, "body": parsed}
    except Exception as exc:
        return {"ok": False, "status": 0, "body": str(exc)}


def usb_candidates(hardware: dict) -> list[dict]:
    data = (hardware.get("body") or {}).get("data") or {}
    devices = data.get("devices") or []
    found: list[dict] = []
    for dev in devices:
        name = str(dev.get("name") or "")
        subsystem = str(dev.get("subsystem") or "")
        by_id = str(dev.get("by_id") or "")
        attrs = dev.get("attributes") or {}
        blob = json.dumps(dev).lower()
        if not any(
            key in blob
            for key in (
                "usb",
                "config",
                "sd[b-z]",
                "mmcblk1",
                "authorized_keys",
            )
        ) and subsystem not in {"block", "usb", "scsi", "usb-storage"}:
            continue
        label = (
            attrs.get("ID_FS_LABEL")
            or attrs.get("ID_FS_LABEL_ENC")
            or attrs.get("DEVNAME")
            or ""
        )
        if subsystem in {"block", "usb", "scsi", "usb-storage"} or "usb" in blob or "config" in blob:
            found.append(
                {
                    "name": name,
                    "subsystem": subsystem,
                    "by_id": by_id,
                    "devnode": attrs.get("DEVNAME") or dev.get("dev_path"),
                    "label": label,
                    "id_bus": attrs.get("ID_BUS"),
                    "id_fs_type": attrs.get("ID_FS_TYPE"),
                    "id_model": attrs.get("ID_MODEL"),
                }
            )
    return found[:40]


def main() -> None:
    os.makedirs("/config/www/tmp", exist_ok=True)
    result = {
        "has_token": bool(TOKEN),
        "os_info": call("GET", "/os/info"),
        "host_info": call("GET", "/host/info"),
        "hardware": call("GET", "/hardware/info"),
        "import": call("POST", "/os/config/sync"),
    }
    result["usb_candidates"] = usb_candidates(result["hardware"])
    # Drop bulky udev dump from the on-disk copy's hardware list? keep it.
    with open(DUMP, "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2, default=str)

    imp = result["import"]
    os_body = ((result["os_info"].get("body") or {}).get("data") or {})
    summary = (
        f"import_ok={imp.get('ok')} status={imp.get('status')} "
        f"usb={len(result['usb_candidates'])} board={os_body.get('board')}"
    )
    print(
        json.dumps(
            {
                "summary": summary[:240],
                "ok": bool(imp.get("ok")),
                "import_status": imp.get("status"),
                "import_result": imp.get("body"),
                "usb_candidates": result["usb_candidates"],
                "board": os_body.get("board"),
                "dump": DUMP,
            }
        )
    )


if __name__ == "__main__":
    main()
