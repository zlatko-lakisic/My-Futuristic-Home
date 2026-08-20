#!/usr/bin/env python3
"""Query Frigate person events across cameras since an epoch (visit correlation).

Prints JSON: {ok, events: [{id, camera, zone, label, sub_label, start_time}, ...], faces: [...]}

Usage:
  frigate_visit_events.py <since_epoch> [cameras_csv] [base_url]

cameras_csv: comma-separated Frigate camera names; default all visit graph cameras.
"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


GRAPH_PATH = Path(__file__).resolve().parent.parent / "includes" / "property_zone_graph.json"
DEFAULT_BASE = "http://192.168.89.37:5000"


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


def _graph_cameras() -> list[str]:
    try:
        with GRAPH_PATH.open(encoding="utf-8") as fh:
            graph = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return []
    seen: set[str] = set()
    out: list[str] = []
    for z in (graph.get("zones") or {}).values():
        for cam in z.get("cameras") or []:
            c = str(cam).strip()
            if c and c not in seen:
                seen.add(c)
                out.append(c)
    return out


def _fetch_events(base: str, cameras: list[str], after: float) -> list[dict[str, Any]]:
    qs = urllib.parse.urlencode(
        {
            "cameras": ",".join(cameras),
            "labels": "person",
            "after": f"{after:.3f}",
            "limit": 200,
        }
    )
    url = f"{base.rstrip('/')}/api/events?{qs}"
    with urllib.request.urlopen(url, timeout=15) as resp:
        data = json.load(resp)
    return data if isinstance(data, list) else []


def main() -> int:
    if len(sys.argv) < 2:
        print(
            json.dumps(
                {
                    "ok": False,
                    "error": "usage: frigate_visit_events.py <since_epoch> [cameras_csv] [base_url]",
                }
            )
        )
        return 2

    since = float(sys.argv[1])
    after = max(0.0, since - 20.0)
    cameras = _graph_cameras()
    if len(sys.argv) > 2 and sys.argv[2].strip():
        cameras = [c.strip() for c in sys.argv[2].split(",") if c.strip()]
    base = (
        sys.argv[3].strip() if len(sys.argv) > 3 and sys.argv[3].strip() else DEFAULT_BASE
    )

    try:
        raw_events = _fetch_events(base, cameras, after)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1

    slim: list[dict[str, Any]] = []
    faces: list[str] = []
    face_seen: set[str] = set()

    for ev in raw_events:
        cam = str(ev.get("camera") or "")
        zones = ev.get("zones") or []
        name = _normalize_name(ev.get("sub_label"))
        entry = {
            "id": ev.get("id"),
            "camera": cam,
            "zones": zones,
            "label": ev.get("label"),
            "sub_label": name,
            "start_time": ev.get("start_time"),
        }
        slim.append(entry)
        if name:
            key = name.casefold()
            if key not in face_seen:
                face_seen.add(key)
                faces.append(name)

    print(
        json.dumps(
            {
                "ok": True,
                "event_count": len(slim),
                "events": slim,
                "faces": faces,
                "cameras": cameras,
                "after": after,
            },
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
