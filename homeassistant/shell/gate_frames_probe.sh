#!/usr/bin/env bash
OUT=/config/www/tmp/gate_frames_probe.txt
{
  echo "time=$(date -Iseconds)"
  command -v python3 || true
  python3 -c 'import PIL; print("pillow", PIL.__version__)' 2>&1 || echo 'no pillow'
  command -v ffmpeg || true
  ls /usr/bin/ffmpeg /usr/local/bin/ffmpeg 2>&1 || true
} > "$OUT" 2>&1
