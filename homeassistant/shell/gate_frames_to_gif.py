#!/usr/bin/env python3
"""Stitch gate snapshot JPEGs into an animated GIF (+ latest copy)."""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow not installed", file=sys.stderr)
    sys.exit(127)


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: gate_frames_to_gif.py <slug> <stamp> [count] [duration_ms]", file=sys.stderr)
        return 2
    slug, stamp = sys.argv[1], sys.argv[2]
    count = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    duration_ms = int(sys.argv[4]) if len(sys.argv) > 4 else 450
    duration_ms = max(100, min(duration_ms, 5000))
    base = Path("/config/www/tmp")
    frames: list[Image.Image] = []
    for i in range(1, count + 1):
        path = base / f"{slug}_{stamp}_{i}.jpg"
        if not path.exists():
            continue
        im = Image.open(path).convert("RGB")
        width = 480
        height = max(1, int(width * im.size[1] / im.size[0]))
        im = im.resize((width, height), Image.Resampling.LANCZOS)
        frames.append(im.quantize(colors=64, method=Image.Quantize.MEDIANCUT))
    if not frames:
        print(f"no frames for {slug}_{stamp}", file=sys.stderr)
        return 1
    out = base / f"{slug}_{stamp}.gif"
    latest = base / f"{slug}_latest.gif"
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=duration_ms,
        loop=0,
        optimize=True,
        disposal=2,
    )
    shutil.copyfile(out, latest)
    print(
        f"gif={out} frames={len(frames)} duration_ms={duration_ms} "
        f"bytes={out.stat().st_size}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
