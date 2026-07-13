#!/usr/bin/env python3
"""Re-download biomes 0 and 1 (overwritten by gen_assets.py during main download)."""
import io, os, time, urllib.request, urllib.parse
from PIL import Image

TARGETS = {
    "assets/sprites/backgrounds/bg_0_0.png": (
        "dark tropical jungle night game background portrait, "
        "dense dark green foliage palm trees, glowing fireflies, crescent moon, "
        "atmospheric moody, dark green tones, mobile game art", 7
    ),
    "assets/sprites/backgrounds/bg_0_1.png": (
        "dark tropical jungle night game background portrait, "
        "dense dark green foliage palm trees, glowing fireflies, crescent moon, "
        "atmospheric moody, dark green tones, mobile game art", 44
    ),
    "assets/sprites/backgrounds/bg_0_2.png": (
        "dark tropical jungle night game background portrait, "
        "dense dark green foliage palm trees, glowing fireflies, crescent moon, "
        "atmospheric moody, dark green tones, mobile game art", 81
    ),
    "assets/sprites/backgrounds/bg_1_0.png": (
        "twilight indigo purple night sky cityscape game background portrait, "
        "mystical stars nebula glowing, urban silhouette, deep purple tones, "
        "atmospheric moody mobile game art", 107
    ),
    "assets/sprites/backgrounds/bg_1_1.png": (
        "twilight indigo purple night sky cityscape game background portrait, "
        "mystical stars nebula glowing, urban silhouette, deep purple tones, "
        "atmospheric moody mobile game art", 144
    ),
    "assets/sprites/backgrounds/bg_1_2.png": (
        "twilight indigo purple night sky cityscape game background portrait, "
        "mystical stars nebula glowing, urban silhouette, deep purple tones, "
        "atmospheric moody mobile game art", 181
    ),
}

def fetch(prompt, w, h, seed, retries=3):
    enc = urllib.parse.quote(prompt)
    url = f"https://image.pollinations.ai/prompt/{enc}?width={w}&height={h}&nologo=true&model=flux&seed={seed}"
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "GuacBlaster/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if data[:2] in (b'\xff\xd8', b'\x89PN'):
                return Image.open(io.BytesIO(data)).convert("RGBA")
            print(f"  bad response: {data[:60]}")
        except Exception as e:
            print(f"  attempt {attempt+1} error: {e}")
        time.sleep(5)
    return None

for path, (prompt, seed) in TARGETS.items():
    print(f"\n{path} (seed={seed})")
    img = fetch(prompt, 390, 844, seed)
    if img:
        img.save(path, "PNG")
        print(f"  ✓ saved ({os.path.getsize(path)//1024}KB)")
    else:
        print(f"  ✗ failed — keeping existing")
    time.sleep(3)

print("\nDone.")
