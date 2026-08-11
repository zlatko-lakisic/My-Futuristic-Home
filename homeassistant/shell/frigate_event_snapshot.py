#!/usr/bin/env python3
"""Download the best recent Frigate event snapshot for a camera/label/zone.

Writes JPEG bytes to dest. Prints event_id on stdout on success.
"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.parse
import urllib.request


def main() -> int:
    if len(sys.argv) < 4:
        print(
            "usage: frigate_event_snapshot.py <camera> <since_epoch> <dest> "
            "[label] [zone] [base_url]",
            file=sys.stderr,
        )
        return 2

    camera = sys.argv[1].strip()
    since = float(sys.argv[2])
    dest = sys.argv[3].strip()
    label = ""
    if len(sys.argv) > 4 and sys.argv[4].strip().lower() not in {
        "",
        "-",
        "none",
        "null",
    }:
        label = sys.argv[4].strip()
    zone = ""
    if len(sys.argv) > 5 and sys.argv[5].strip().lower() not in {
        "",
        "-",
        "none",
        "null",
    }:
        zone = sys.argv[5].strip()
    base = (
        sys.argv[6].strip()
        if len(sys.argv) > 6 and sys.argv[6].strip()
        else "http://192.168.89.37:5000"
    ).rstrip("/")

    after = max(0.0, since - 20.0)
    params: dict[str, str] = {
        "cameras": camera,
        "after": f"{after:.3f}",
        "limit": "30",
        "include_thumbnails": "0",
    }
    if label:
        params["labels"] = label
    url = f"{base}/api/events?{urllib.parse.urlencode(params)}"

    try:
        with urllib.request.urlopen(url, timeout=8) as resp:
            events = json.load(resp)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"frigate query failed: {exc}", file=sys.stderr)
        return 1

    if not isinstance(events, list) or not events:
        print("no frigate events", file=sys.stderr)
        return 1

    scored: list[tuple[float, dict]] = []
    for ev in events:
        if zone:
            zones = ev.get("zones") or []
            if zone not in zones:
                continue
        start = float(ev.get("start_time") or 0.0)
        score = float(ev.get("top_score") or ev.get("score") or 0.0)
        # Prefer events that started near occupancy, then higher score.
        recency = max(0.0, 30.0 - abs(start - since))
        scored.append((recency + score, ev))

    if not scored:
        print("no matching frigate events", file=sys.stderr)
        return 1

    scored.sort(key=lambda item: item[0], reverse=True)
    event_id = str(scored[0][1].get("id") or "").strip()
    if not event_id:
        print("event missing id", file=sys.stderr)
        return 1

    snap_url = (
        f"{base}/api/events/{urllib.parse.quote(event_id)}/snapshot.jpg"
        f"?bbox=0&timestamp=0&crop=0&quality=95"
    )
    try:
        with urllib.request.urlopen(snap_url, timeout=8) as resp:
            data = resp.read()
    except (urllib.error.URLError, TimeoutError) as exc:
        print(f"snapshot download failed: {exc}", file=sys.stderr)
        return 1

    if not data or data[:2] != b"\xff\xd8":
        print("snapshot was not a jpeg", file=sys.stderr)
        return 1

    try:
        with open(dest, "wb") as fh:
            fh.write(data)
    except OSError as exc:
        print(f"write failed: {exc}", file=sys.stderr)
        return 1

    print(event_id)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
