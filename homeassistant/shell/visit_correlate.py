#!/usr/bin/env python3
"""Correlate a zone/camera event into an active property visit.

Reads/writes visit state JSON and prints a single JSON object on stdout for HA
shell_command response_variable parsing.

Usage:
  visit_correlate.py <zone_key> <frigate_camera> <epoch> [faces_csv] [gate_open]

faces_csv: comma-separated Frigate face sub_labels (may be empty).
gate_open: yes|no — gate sensor fired for this step.
"""
from __future__ import annotations

import json
import sys
import time
import uuid
import os
from pathlib import Path
from typing import Any


GRAPH_PATH = Path(__file__).resolve().parent.parent / "includes" / "property_zone_graph.json"
STATE_PATH = Path(
    os.environ.get("VISIT_STATE_PATH", "/config/www/tmp/property_visit_state.json")
)


def _load_graph() -> dict[str, Any]:
    with GRAPH_PATH.open(encoding="utf-8") as fh:
        return json.load(fh)


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


def _normalize_faces(raw: str) -> list[str]:
    names: list[str] = []
    seen: set[str] = set()
    for part in raw.split(","):
        name = part.strip()
        if not name or name.lower() in {"none", "null", "unknown", "n/a"}:
            continue
        key = name.casefold()
        if key in seen:
            continue
        seen.add(key)
        names.append(name)
    return names


def _path_label(graph: dict[str, Any], path: list[str]) -> str:
    zones = graph.get("zones") or {}
    labels = []
    for key in path:
        z = zones.get(key) or {}
        labels.append(str(z.get("label") or key))
    return " → ".join(labels)


def _adjacent_ok(
    graph: dict[str, Any], prev: str, nxt: str, elapsed: float
) -> bool:
    zones = graph.get("zones") or {}
    prev_z = zones.get(prev) or {}
    adj = (prev_z.get("adjacent") or {}).get(nxt)
    if not adj:
        return False
    min_s = float(adj.get("min_s", 0))
    max_s = float(adj.get("max_s", 9999))
    return min_s <= elapsed <= max_s


def _face_overlap(a: list[str], b: list[str]) -> bool:
    if not a or not b:
        return False
    ba = {x.casefold() for x in a}
    return any(x.casefold() in ba for x in b)


def _new_visit_id() -> str:
    return f"v-{int(time.time())}-{uuid.uuid4().hex[:6]}"


def _priority_for_step(
    graph: dict[str, Any],
    zone_key: str,
    linked: bool,
    is_first: bool,
) -> str:
    if is_first:
        return "realtime"
    zones = graph.get("zones") or {}
    z = zones.get(zone_key) or {}
    if not linked:
        return str(z.get("link_priority") or "realtime")
    return "normal"


def main() -> int:
    if len(sys.argv) < 4:
        print(
            json.dumps(
                {
                    "ok": False,
                    "error": "usage: visit_correlate.py <zone_key> <camera> <epoch> [faces_csv] [gate_open]",
                }
            )
        )
        return 2

    zone_key = sys.argv[1].strip()
    camera = sys.argv[2].strip()
    epoch = float(sys.argv[3])
    faces = _normalize_faces(sys.argv[4] if len(sys.argv) > 4 else "")
    gate_open = (sys.argv[5].strip().lower() if len(sys.argv) > 5 else "no") == "yes"

    graph = _load_graph()
    zones = graph.get("zones") or {}
    if zone_key not in zones:
        print(json.dumps({"ok": False, "error": f"unknown zone_key: {zone_key}"}))
        return 1

    now = time.time()
    timeout = float(graph.get("visit_timeout_seconds") or 300)
    state = _load_state()

    active_id = str(state.get("visit_id") or "")
    active_path = list(state.get("path") or [])
    active_faces = list(state.get("faces") or [])
    active_cameras = list(state.get("cameras") or [])
    active_started = float(state.get("started_epoch") or 0)
    active_last_epoch = float(state.get("last_wall_epoch") or state.get("last_epoch") or 0)
    active_last_event_epoch = float(state.get("last_event_epoch") or state.get("last_epoch") or 0)
    still_buffer = list(state.get("still_buffer") or [])

    expired = (
        not active_id
        or (now - active_last_epoch) > timeout
        or active_started <= 0
    )

    linked = False
    link_reason = "new"

    if expired:
        visit_id = _new_visit_id()
        path = [zone_key]
        visit_faces = list(faces)
        cameras = [camera] if camera else []
        started_epoch = epoch
        link_reason = "new_visit"
    else:
        visit_id = active_id
        path = list(active_path)
        visit_faces = list(active_faces)
        cameras = list(active_cameras)
        started_epoch = active_started
        elapsed = epoch - active_last_event_epoch if active_last_event_epoch else 0

        if not path or path[-1] == zone_key:
            linked = True
            link_reason = "same_zone"
        elif _face_overlap(faces, visit_faces):
            linked = True
            link_reason = "face_match"
            for f in faces:
                if f.casefold() not in {x.casefold() for x in visit_faces}:
                    visit_faces.append(f)
        elif len(path) >= 1 and _adjacent_ok(graph, path[-1], zone_key, elapsed):
            linked = True
            link_reason = "adjacency_time"
            if gate_open:
                link_reason = "gate_adjacency"
        else:
            visit_id = _new_visit_id()
            path = [zone_key]
            visit_faces = list(faces)
            cameras = [camera] if camera else []
            started_epoch = epoch
            link_reason = "branch_split"

        if linked and (not path or path[-1] != zone_key):
            path.append(zone_key)

    if camera and camera not in cameras:
        cameras.append(camera)
    for f in faces:
        if f.casefold() not in {x.casefold() for x in visit_faces}:
            visit_faces.append(f)

    is_first = len(path) <= 1 and link_reason in {"new_visit", "new"}
    priority = _priority_for_step(graph, zone_key, linked and not is_first, is_first)

    path_label = _path_label(graph, path)
    visit_context = (
        f"Property visit {visit_id}. Path so far: {path_label}. "
        f"Faces: {', '.join(visit_faces) if visit_faces else 'none'}. "
        f"Current zone: {zones[zone_key].get('label', zone_key)}. "
        f"Link: {link_reason}."
    )

    new_state = {
        "visit_id": visit_id,
        "path": path,
        "faces": visit_faces,
        "cameras": cameras,
        "started_epoch": started_epoch,
        "started_wall_epoch": state.get("started_wall_epoch") or (now if expired else state.get("started_wall_epoch")) or now,
        "last_event_epoch": epoch,
        "last_wall_epoch": now,
        "last_epoch": epoch,
        "last_zone": zone_key,
        "last_camera": camera,
        "still_buffer": still_buffer,
        "updated_epoch": now,
    }
    if expired or link_reason in {"new_visit", "branch_split"}:
        new_state["started_wall_epoch"] = now
    _save_state(new_state)

    out = {
        "ok": True,
        "visit_id": visit_id,
        "path": path,
        "path_label": path_label,
        "faces": visit_faces,
        "cameras": cameras,
        "linked": linked or link_reason == "same_zone",
        "link_reason": link_reason,
        "priority": priority,
        "visit_context": visit_context,
        "zone_key": zone_key,
        "zone_label": zones[zone_key].get("label", zone_key),
    }
    print(json.dumps(out, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
