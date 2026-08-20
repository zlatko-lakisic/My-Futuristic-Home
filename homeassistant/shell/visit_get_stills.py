#!/usr/bin/env python3
"""Print still buffer from property visit state as JSON for HA finalize script."""
from __future__ import annotations

import json
import sys
from pathlib import Path


STATE_PATH = Path("/config/www/tmp/property_visit_state.json")


def main() -> int:
    if not STATE_PATH.exists():
        print(json.dumps({"ok": True, "buffer": [], "paths": []}))
        return 0
    try:
        with STATE_PATH.open(encoding="utf-8") as fh:
            state = json.load(fh)
    except (json.JSONDecodeError, OSError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1
    buffer = state.get("still_buffer") or []
    paths = [str(b.get("path")) for b in buffer if b.get("path")]
    print(json.dumps({"ok": True, "buffer": buffer, "paths": paths, "visit_id": state.get("visit_id")}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
