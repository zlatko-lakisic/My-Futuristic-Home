#!/usr/bin/env python3
"""Append still file paths to the active visit buffer for Tier-2 multi-cam VLM.

Usage:
  visit_append_stills.py <visit_id> <camera> <zone_key> <stamp> <count> [start_index]

Prints JSON with updated buffer length.
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path
from typing import Any


STATE_PATH = Path("/config/www/tmp/property_visit_state.json")
MAX_BUFFER_STILLS = 16
MAX_PER_STEP = 4


def _load_state() -> dict[str, Any]:
    if not STATE_PATH.exists():
        return {}
    try:
        with STATE_PATH.open(encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}


def _save_state(state: dict[str, Any]) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with STATE_PATH.open("w", encoding="utf-8") as fh:
        json.dump(state, fh, separators=(",", ":"))


def main() -> int:
    if len(sys.argv) < 6:
        print(json.dumps({"ok": False, "error": "usage: visit_append_stills.py <visit_id> <camera> <zone_slug> <stamp> <count> [start_index]"}))
        return 2

    visit_id = sys.argv[1].strip()
    camera = sys.argv[2].strip()
    zone_slug = sys.argv[3].strip()
    stamp = sys.argv[4].strip()
    count = max(1, int(sys.argv[5]))
    start_index = int(sys.argv[6]) if len(sys.argv) > 6 else 1

    state = _load_state()
    if str(state.get("visit_id") or "") != visit_id:
        print(json.dumps({"ok": False, "error": "visit_id mismatch"}))
        return 1

    buffer: list[dict[str, str]] = list(state.get("still_buffer") or [])
    take = min(count, MAX_PER_STEP)
    added: list[str] = []
    for i in range(take):
        idx = start_index + i
        path = f"/config/www/tmp/{zone_slug}_{stamp}_{idx}.jpg"
        entry = {
            "path": path,
            "camera": camera,
            "zone_slug": zone_slug,
            "index": str(idx),
        }
        if path not in {b.get("path") for b in buffer}:
            buffer.append(entry)
            added.append(path)

    if len(buffer) > MAX_BUFFER_STILLS:
        buffer = buffer[-MAX_BUFFER_STILLS:]

    state["still_buffer"] = buffer
    state["updated_epoch"] = time.time()
    _save_state(state)

    print(
        json.dumps(
            {
                "ok": True,
                "added": len(added),
                "buffer_len": len(buffer),
                "paths": added,
            },
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
