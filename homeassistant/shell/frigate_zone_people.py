#!/usr/bin/env python3
"""List Frigate-recognized people for a camera since an epoch timestamp.

Prints a comma-separated list of unique sub_label names on stdout.
"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.parse
import urllib.request


def _normalize_name(label: object) -> str | None:
    if label is None:
        return None
    if isinstance(label, (list, tuple)):
        label = label[0] if label else None
    if label is None:
        return None
    name = str(label).strip()
    if not name or name.lower() in {"none", "null", "unknown", "n/a"}:
        return None
    return name


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: frigate_zone_people.py <camera> <since_epoch> [zone] [base_url]",
            file=sys.stderr,
        )
        return 2

    camera = sys.argv[1].strip()
    since = float(sys.argv[2])
    zone = ""
    if len(sys.argv) > 3 and sys.argv[3].strip().lower() not in {"", "-", "none", "null"}:
        zone = sys.argv[3].strip()
    base = (
        sys.argv[4].strip()
        if len(sys.argv) > 4 and sys.argv[4].strip()
        else "http://192.168.89.37:5000"
    ).rstrip("/")

    # Small lookback so we include the occupancy edge that started the automation.
    after = max(0.0, since - 20.0)
    qs = urllib.parse.urlencode(
        {
            "cameras": camera,
            "labels": "person",
            "after": f"{after:.3f}",
            "limit": 100,
        }
    )
    url = f"{base}/api/events?{qs}"

    try:
        with urllib.request.urlopen(url, timeout=12) as resp:
            events = json.load(resp)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"frigate query failed: {exc}", file=sys.stderr)
        return 1

    if not isinstance(events, list):
        print("frigate returned non-list", file=sys.stderr)
        return 1

    names: list[str] = []
    seen: set[str] = set()
    for ev in events:
        if zone:
            zones = ev.get("zones") or []
            if zone not in zones:
                continue
        name = _normalize_name(ev.get("sub_label"))
        if not name:
            continue
        key = name.casefold()
        if key in seen:
            continue
        seen.add(key)
        names.append(name)

    print(",".join(names))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
