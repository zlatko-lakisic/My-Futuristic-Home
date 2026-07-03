#!/usr/bin/env python3
"""Persist AI watering run config for resume-after-restart (RUN_CONFIG env, urlencoded JSON)."""
from __future__ import annotations

import json
import os
import pathlib
import urllib.parse

OUT = pathlib.Path("/config/includes/ai_watering_active_run_snapshot.json")


def main() -> None:
    raw = os.environ.get("RUN_CONFIG", "").strip()
    if not raw:
        raise SystemExit("missing RUN_CONFIG environment variable")
    data = json.loads(urllib.parse.unquote(raw))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, indent=2), encoding="utf-8")
    zones = data.get("zones") if isinstance(data, dict) else []
    print(len(zones) if isinstance(zones, list) else 0)


if __name__ == "__main__":
    main()
