#!/usr/bin/env bash
# Download 15 AI backgrounds from Pollinations.ai (sequential, 1 at a time)
set -e

DEST="assets/sprites/backgrounds"
TMP="/tmp/gb_bg_tmp.jpg"

declare -A PROMPTS
PROMPTS[0]="dark jungle night tropical dense foliage dark green palm trees glowing fireflies atmospheric mobile game background portrait vertical dark moody"
PROMPTS[1]="twilight indigo purple night sky mystical stars nebula atmospheric mobile game background portrait vertical fantasy moody deep"
PROMPTS[2]="volcanic lava rivers glowing embers fire dark red orange molten rock atmospheric mobile game background portrait vertical inferno"
PROMPTS[3]="deep ocean abyss underwater dark blue bioluminescent jellyfish creatures atmospheric mobile game background portrait vertical"
PROMPTS[4]="blood moon red night desert dark crimson sand dunes dramatic atmospheric mobile game background portrait vertical gothic"

SEEDS=(7 44 81 107 144 181 207 244 281 307 344 381 407 444 481)
IDX=0

for BIOME in 0 1 2 3 4; do
  PROMPT_ENC=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PROMPTS[$BIOME]}'))")
  for VARIANT in 0 1 2; do
    SEED=${SEEDS[$IDX]}
    OUT="${DEST}/bg_${BIOME}_${VARIANT}.png"
    URL="https://image.pollinations.ai/prompt/${PROMPT_ENC}?width=390&height=844&nologo=true&model=flux&seed=${SEED}"
    echo "[$(date +%H:%M:%S)] Downloading bg_${BIOME}_${VARIANT}.png (seed=${SEED})..."
    curl -s -o "$TMP" --max-time 120 "$URL"
    # Validate it's an image (not JSON error)
    if python3 -c "
import sys
with open('$TMP','rb') as f:
    hdr = f.read(4)
sys.exit(0 if hdr[:2] in (b'\xff\xd8', b'\x89PNG') else 1)
" 2>/dev/null; then
      sips -s format png "$TMP" --out "$OUT" > /dev/null 2>&1
      echo "  ✓ Saved ${OUT}"
    else
      echo "  ✗ Invalid response — keeping procedural bg_${BIOME}_${VARIANT}"
    fi
    IDX=$((IDX + 1))
    sleep 2
  done
done

echo "Done. $(date)"
