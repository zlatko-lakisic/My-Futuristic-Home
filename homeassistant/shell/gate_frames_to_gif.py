#!/usr/bin/env python3
"""Stitch gate/zone snapshot JPEGs into an animated GIF (+ latest copy).

Keeps the same wall-clock GIF length as N×duration_ms, but inserts blended
intermediate frames so notification previews play at higher FPS.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow not installed", file=sys.stderr)
    sys.exit(127)


def _interp_frames(
    rgb_frames: list[Image.Image], factor: int
) -> list[Image.Image]:
    """Insert (factor-1) blends between each consecutive pair."""
    if len(rgb_frames) < 2 or factor < 2:
        return list(rgb_frames)
    out: list[Image.Image] = []
    for i in range(len(rgb_frames) - 1):
        a = rgb_frames[i]
        b = rgb_frames[i + 1]
        out.append(a)
        for step in range(1, factor):
            alpha = step / float(factor)
            out.append(Image.blend(a, b, alpha))
    out.append(rgb_frames[-1])
    return out


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: gate_frames_to_gif.py <slug> <stamp> [count] [duration_ms] [interp_factor]",
            file=sys.stderr,
        )
        return 2
    slug, stamp = sys.argv[1], sys.argv[2]
    count = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    duration_ms = int(sys.argv[4]) if len(sys.argv) > 4 else 450
    duration_ms = max(100, min(duration_ms, 5000))
    # Higher = smoother GIF; total play time stays ~ count * duration_ms.
    interp_factor = int(sys.argv[5]) if len(sys.argv) > 5 else 4
    interp_factor = max(1, min(interp_factor, 8))

    base = Path("/config/www/tmp")
    rgb_frames: list[Image.Image] = []
    for i in range(1, count + 1):
        path = base / f"{slug}_{stamp}_{i}.jpg"
        if not path.exists():
            continue
        im = Image.open(path).convert("RGB")
        width = 480
        height = max(1, int(width * im.size[1] / im.size[0]))
        rgb_frames.append(im.resize((width, height), Image.Resampling.LANCZOS))
    if not rgb_frames:
        print(f"no frames for {slug}_{stamp}", file=sys.stderr)
        return 1

    source_count = len(rgb_frames)
    total_ms = source_count * duration_ms
    blended = _interp_frames(rgb_frames, interp_factor)
    frames = [
        im.quantize(colors=64, method=Image.Quantize.MEDIANCUT) for im in blended
    ]
    out_duration = max(20, int(round(total_ms / len(frames))))

    out = base / f"{slug}_{stamp}.gif"
    latest = base / f"{slug}_latest.gif"
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=out_duration,
        loop=0,
        optimize=True,
        disposal=2,
    )
    shutil.copyfile(out, latest)
    fps = 1000.0 / out_duration if out_duration else 0.0
    print(
        f"gif={out} source_frames={source_count} gif_frames={len(frames)} "
        f"interp={interp_factor} duration_ms={out_duration} "
        f"total_ms≈{total_ms} fps≈{fps:.2f} bytes={out.stat().st_size}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
