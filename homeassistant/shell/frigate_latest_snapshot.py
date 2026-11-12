#!/usr/bin/env python3
"""Save Frigate's current frame for a camera straight from its HTTP API.

Fallback for camera.snapshot when the HA camera entity is unavailable (for
example when Frigate has lost MQTT and every Frigate entity in HA goes
unavailable, while Frigate itself keeps decoding the streams).

usage: frigate_latest_snapshot.py <camera> <dest> [base_url]
Prints the destination path on success; exits non-zero on failure.
"""
from __future__ import annotations

import os
import sys
import urllib.error
import urllib.request

DEFAULT_BASE = "http://10.0.10.20:5000"


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__.strip().splitlines()[-2], file=sys.stderr)
        return 2

    camera = sys.argv[1].strip()
    dest = sys.argv[2].strip()
    base = (sys.argv[3].strip() if len(sys.argv) > 3 else "") or DEFAULT_BASE
    base = base.rstrip("/")
    if not camera or not dest:
        print("camera and dest are required", file=sys.stderr)
        return 2

    url = f"{base}/api/{camera}/latest.jpg?quality=90"
    try:
        with urllib.request.urlopen(url, timeout=8) as resp:
            data = resp.read()
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        print(f"frigate latest.jpg failed for {camera}: {exc}", file=sys.stderr)
        return 1

    if len(data) < 1024 or not data.startswith(b"\xff\xd8"):
        print(f"frigate returned no JPEG for {camera} ({len(data)} bytes)", file=sys.stderr)
        return 1

    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    tmp = f"{dest}.part"
    with open(tmp, "wb") as fh:
        fh.write(data)
    os.replace(tmp, dest)
    print(dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
