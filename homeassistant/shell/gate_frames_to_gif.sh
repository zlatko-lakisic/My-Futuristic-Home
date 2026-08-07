#!/usr/bin/env bash
set -euo pipefail
LOG=/config/www/tmp/gate_frames_to_gif.log
exec > >(tee -a "$LOG") 2>&1
echo "---- $(date -Iseconds) args: $* ----"

SLUG="${1:?slug required}"
STAMP="${2:?timestamp required}"
COUNT="${3:-8}"
DURATION_MS="${4:-450}"

if command -v python3 >/dev/null 2>&1; then
  if python3 /config/shell/gate_frames_to_gif.py "$SLUG" "$STAMP" "$COUNT" "$DURATION_MS"; then
    exit 0
  fi
  echo "python stitcher failed, trying ffmpeg"
fi

DIR="/config/www/tmp"
PREFIX="${DIR}/${SLUG}_${STAMP}"
OUT_GIF="${PREFIX}.gif"
OUT_LATEST_GIF="${DIR}/${SLUG}_latest.gif"

FFMPEG="$(command -v ffmpeg || true)"
if [[ -z "$FFMPEG" ]]; then
  for candidate in /usr/bin/ffmpeg /usr/local/bin/ffmpeg; do
    [[ -x "$candidate" ]] && FFMPEG="$candidate" && break
  done
fi
if [[ -z "$FFMPEG" ]]; then
  echo "neither Pillow nor ffmpeg available" >&2
  exit 127
fi

LIST="$(mktemp)"
trap 'rm -f "$LIST"' EXIT
found=0
for i in $(seq 1 "$COUNT"); do
  f="${PREFIX}_${i}.jpg"
  if [[ -f "$f" ]]; then
    printf "file '%s'\n" "${f//\'/\'\\\'\'}" >> "$LIST"
    found=$((found + 1))
  fi
done
if [[ "$found" -lt 1 ]]; then
  echo "no frames found for ${PREFIX}_*.jpg" >&2
  exit 1
fi

# duration_ms per still → fps for concat stills (min ~0.2fps, max 10fps)
FPS="$(python3 - <<PY
ms = max(100, min(int("${DURATION_MS}"), 5000))
print(f"{1000.0 / ms:.4f}")
PY
)"

"$FFMPEG" -hide_banner -loglevel error -y \
  -f concat -safe 0 -i "$LIST" \
  -vf "fps=${FPS},scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 \
  "$OUT_GIF"
cp -f "$OUT_GIF" "$OUT_LATEST_GIF"
echo "gif=$OUT_GIF frames=$found duration_ms=$DURATION_MS fps=$FPS"
