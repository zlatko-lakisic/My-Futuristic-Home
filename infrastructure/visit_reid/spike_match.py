#!/usr/bin/env python3
"""Tier 3 Re-ID spike — score Frigate person event pairs across cameras.

Without torchreid, uses HSV histogram cosine similarity as a pipeline stub.
"""
from __future__ import annotations

import argparse
import io
import json
import math
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


def _fetch_events(base: str, camera: str, after: float, limit: int) -> list[dict[str, Any]]:
    qs = urllib.parse.urlencode(
        {
            "cameras": camera,
            "labels": "person",
            "after": f"{after:.3f}",
            "limit": limit,
        }
    )
    url = f"{base.rstrip('/')}/api/events?{qs}"
    with urllib.request.urlopen(url, timeout=20) as resp:
        data = json.load(resp)
    return data if isinstance(data, list) else []


def _fetch_crop(base: str, event_id: str) -> bytes | None:
    url = f"{base.rstrip('/')}/api/events/{event_id}/snapshot.jpg?bbox=1"
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            return resp.read()
    except (urllib.error.URLError, TimeoutError):
        return None


def _embed_histogram(jpeg: bytes) -> list[float] | None:
    try:
        from PIL import Image
    except ImportError:
        return None
    try:
        img = Image.open(io.BytesIO(jpeg)).convert("HSV")
        img = img.resize((64, 128))
        hist = img.histogram()
        total = float(sum(hist)) or 1.0
        return [h / total for h in hist]
    except OSError:
        return None


def _cosine(a: list[float], b: list[float]) -> float:
    if len(a) != len(b) or not a:
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


def _best_matches(
    base: str, events_a: list[dict], events_b: list[dict]
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    cache: dict[str, list[float] | None] = {}

    for ev_a in events_a[:25]:
        eid_a = str(ev_a.get("id") or "")
        if not eid_a:
            continue
        if eid_a not in cache:
            crop = _fetch_crop(base, eid_a)
            cache[eid_a] = _embed_histogram(crop) if crop else None
        emb_a = cache[eid_a]
        if not emb_a:
            continue

        best_score = -1.0
        best_b: dict[str, Any] | None = None
        for ev_b in events_b[:25]:
            eid_b = str(ev_b.get("id") or "")
            if not eid_b:
                continue
            if eid_b not in cache:
                crop = _fetch_crop(base, eid_b)
                cache[eid_b] = _embed_histogram(crop) if crop else None
            emb_b = cache[eid_b]
            if not emb_b:
                continue
            score = _cosine(emb_a, emb_b)
            if score > best_score:
                best_score = score
                best_b = ev_b

        results.append(
            {
                "event_a": eid_a,
                "camera_a": ev_a.get("camera"),
                "sub_label_a": ev_a.get("sub_label"),
                "best_event_b": (best_b or {}).get("id"),
                "camera_b": (best_b or {}).get("camera"),
                "sub_label_b": (best_b or {}).get("sub_label"),
                "similarity": round(best_score, 4) if best_b else None,
            }
        )
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description="Cross-camera Re-ID spike")
    parser.add_argument("--base-url", default="http://192.168.89.37:5000")
    parser.add_argument("--camera-a", required=True)
    parser.add_argument("--camera-b", required=True)
    parser.add_argument("--after", type=float, required=True)
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args()

    try:
        events_a = _fetch_events(args.base_url, args.camera_a, args.after, args.limit)
        events_b = _fetch_events(args.base_url, args.camera_b, args.after, args.limit)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1

    matches = _best_matches(args.base_url, events_a, events_b)
    scores = [m["similarity"] for m in matches if m.get("similarity") is not None]
    avg = sum(scores) / len(scores) if scores else 0.0
    auto_link = sum(1 for s in scores if s >= 0.85)
    vlm_band = sum(1 for s in scores if 0.65 <= s < 0.85)

    report = {
        "ok": True,
        "camera_a": args.camera_a,
        "camera_b": args.camera_b,
        "events_a": len(events_a),
        "events_b": len(events_b),
        "pairs_scored": len(matches),
        "avg_similarity": round(avg, 4),
        "auto_link_count": auto_link,
        "vlm_confirm_count": vlm_band,
        "matches": matches,
        "note": "Histogram stub — replace with OSNet for production thresholds",
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
