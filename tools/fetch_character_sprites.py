#!/usr/bin/env python3
"""Download unique character sprites from Pollinations.ai.

Run from project root:
    /tmp/gb_venv/bin/python3 tools/fetch_character_sprites.py

After download, regenerate Godot imports:
    godot --headless -e --quit

Requires Pillow: /tmp/gb_venv/bin/pip install Pillow
"""
import io
import os
import sys
import time
import urllib.request
import urllib.parse

try:
    from PIL import Image
except ImportError:
    print("ERROR: Run with /tmp/gb_venv/bin/python3 (pip install Pillow)")
    sys.exit(1)


def fetch_image(prompt: str, width: int, height: int, seed: int,
                retries: int = 3) -> Image.Image | None:
    enc = urllib.parse.quote(prompt)
    url = (f"https://image.pollinations.ai/prompt/{enc}"
           f"?width={width}&height={height}&nologo=true&model=flux&seed={seed}")
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "GuacBlaster/1.0"})
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
            if data[:2] in (b'\xff\xd8', b'\x89PN'):
                img = Image.open(io.BytesIO(data))
                return img.convert("RGBA")
            else:
                msg = data[:80].decode("utf-8", errors="replace")
                print(f"  [attempt {attempt+1}] Bad response: {msg[:60]}")
                time.sleep(5)
        except Exception as e:
            print(f"  [attempt {attempt+1}] Error: {e}")
            time.sleep(5)
    return None


def chroma_key(img: Image.Image, bg_color=(255, 255, 255), tolerance=40) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = ((r-bg_color[0])**2 + (g-bg_color[1])**2 + (b-bg_color[2])**2)**0.5
            if dist < tolerance:
                px[x, y] = (r, g, b, 0)
    return img


def save_img(img: Image.Image, path: str, size: tuple[int, int]) -> None:
    img = img.resize(size, Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  ✓ {path} ({img.width}×{img.height})")


CHARACTER_SPECS = [
    {
        "id": "guac",
        "path": "assets/sprites/characters/player_guac.png",
        "prompt": (
            "pixel art green avocado spaceship top-down view, "
            "triangular body bright green guacamole color, "
            "round blue cockpit window center, orange thruster below, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2001,
    },
    {
        "id": "habanero",
        "path": "assets/sprites/characters/player_habanero.png",
        "prompt": (
            "pixel art orange habanero pepper rocket spaceship top-down view, "
            "pepper-shaped body vivid orange, fiery red flame exhaust trail, "
            "small red cockpit window, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2002,
    },
    {
        "id": "serrano",
        "path": "assets/sprites/characters/player_serrano.png",
        "prompt": (
            "pixel art yellow-green serrano chili torpedo spaceship top-down view, "
            "long narrow pointed body yellow-green, swept-back fins, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2003,
    },
    {
        "id": "doble_guac",
        "path": "assets/sprites/characters/player_doble_guac.png",
        "prompt": (
            "pixel art cyan blue twin-cannon spaceship top-down view, "
            "wide body with two parallel gun barrels on left and right sides, "
            "sleek futuristic cyan color, small center cockpit, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2004,
    },
    {
        "id": "veloz",
        "path": "assets/sprites/characters/player_veloz.png",
        "prompt": (
            "pixel art yellow lightning bolt fast fighter spaceship top-down view, "
            "thin needle arrowhead body bright yellow, swept-back delta wings, "
            "tiny cockpit, speed lines markings, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2005,
    },
    {
        "id": "tornado",
        "path": "assets/sprites/characters/player_tornado.png",
        "prompt": (
            "pixel art purple tornado fan spaceship top-down view, "
            "round body deep purple violet, three spread cannon barrels fan arrangement, "
            "swirl vortex marking on hull, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2006,
    },
    {
        "id": "aplastador",
        "path": "assets/sprites/characters/player_aplastador.png",
        "prompt": (
            "pixel art dark brown heavy armored tank spaceship top-down view, "
            "thick wide rectangular body, heavy armor plating bolts, "
            "single massive center cannon barrel, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2007,
    },
    {
        "id": "gran_abanico",
        "path": "assets/sprites/characters/player_gran_abanico.png",
        "prompt": (
            "pixel art pink magenta wide fan fighter spaceship top-down view, "
            "butterfly wing shape with five spread cannon barrels, "
            "hot pink color, ornate wide fins, "
            "2D game sprite isolated white background, clean pixel style"
        ),
        "seed": 2008,
    },
]


def main():
    print("\n=== Character Sprite Download (sequential, Pollinations Flux) ===\n")
    for spec in CHARACTER_SPECS:
        path = spec["path"]
        print(f"[{spec['id']}] {path}")
        img = fetch_image(spec["prompt"], 512, 512, spec["seed"])
        if img:
            img = chroma_key(img)
            save_img(img, path, size=(64, 64))
        else:
            print(f"  ✗ FAILED — {path} not created")
        time.sleep(3)

    print("\nDone! Now regenerate Godot imports:")
    print("  godot --headless -e --quit")


if __name__ == "__main__":
    main()
