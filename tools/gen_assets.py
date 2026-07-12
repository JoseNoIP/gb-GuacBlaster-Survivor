#!/usr/bin/env python3
"""Generate placeholder pixel-art sprites and SFX WAVs for GuacBlaster Survivor.
Run from project root:  python3 tools/gen_assets.py
Requires only Python 3 stdlib — no PIL, no external packages.
"""
import array
import math
import os
import random
import struct
import wave
import zlib

# ---------------------------------------------------------------------------
# PNG helpers
# ---------------------------------------------------------------------------

def _chunk(tag: bytes, data: bytes) -> bytes:
    c = tag + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)


def save_png(path: str, w: int, h: int, pixels: list) -> None:
    """pixels: flat list of (r,g,b,a) tuples, row-major."""
    raw = bytearray()
    for row in range(h):
        raw.append(0)  # filter=None
        for col in range(w):
            raw.extend(pixels[row * w + col])
    content = (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + _chunk(b"IEND", b"")
    )
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(content)
    print(f"  + {path}")


# ---------------------------------------------------------------------------
# Drawing primitives
# ---------------------------------------------------------------------------

T = (0, 0, 0, 0)  # transparent
BLK = (12, 12, 12, 255)  # outline black
WHT = (255, 255, 255, 255)
PUP = (15, 15, 15, 255)  # pupil


def _grid(w, h, fill=T):
    return [[list(fill)] * w for _ in range(h)]


def _flat(g):
    return [tuple(c) for row in g for c in row]


def _set(g, x, y, c):
    if 0 <= x < len(g[0]) and 0 <= y < len(g):
        g[y][x] = list(c)


def _circle(g, cx, cy, r, c):
    for y in range(max(0, int(cy - r) - 1), min(len(g), int(cy + r) + 2)):
        for x in range(max(0, int(cx - r) - 1), min(len(g[0]), int(cx + r) + 2)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                _set(g, x, y, c)


def _outline_circle(g, cx, cy, r, oc):
    r2 = (r + 1.4) ** 2
    for y in range(max(0, int(cy - r) - 2), min(len(g), int(cy + r) + 3)):
        for x in range(max(0, int(cx - r) - 2), min(len(g[0]), int(cx + r) + 3)):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if r * r < d2 <= r2 and tuple(g[y][x]) == T:
                _set(g, x, y, oc)


def _rect(g, x1, y1, x2, y2, c):
    for y in range(max(0, y1), min(len(g), y2 + 1)):
        for x in range(max(0, x1), min(len(g[0]), x2 + 1)):
            _set(g, x, y, c)


def _hline(g, y, x1, x2, c):
    for x in range(x1, x2 + 1):
        _set(g, x, y, c)


def _vline(g, x, y1, y2, c):
    for y in range(y1, y2 + 1):
        _set(g, x, y, c)


def _poly(g, pts, c):
    """Fill a polygon using scanline."""
    if not pts:
        return
    min_y = max(0, min(p[1] for p in pts))
    max_y = min(len(g) - 1, max(p[1] for p in pts))
    for y in range(min_y, max_y + 1):
        xs = []
        n = len(pts)
        for i in range(n):
            x1, y1 = pts[i]
            x2, y2 = pts[(i + 1) % n]
            if y1 == y2:
                continue
            if min(y1, y2) <= y < max(y1, y2):
                t = (y - y1) / (y2 - y1)
                xs.append(x1 + t * (x2 - x1))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(int(xs[i]) + 1, int(xs[i + 1]) + 1):
                _set(g, x, y, c)


def _eyes(g, cx, cy, r=2, gap=4):
    for ex in [cx - gap, cx + gap]:
        _circle(g, ex, cy, r, WHT)
        _set(g, ex, cy, PUP)


def _shine(g, x, y):
    _set(g, x, y, WHT)


# ---------------------------------------------------------------------------
# Character sprites
# ---------------------------------------------------------------------------

def make_player(size=32):
    """Green guacamole ship — triangle with rounded top and cockpit."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    MAIN = (68, 200, 40, 255)
    HI = (120, 235, 80, 255)
    SH = (35, 120, 18, 255)
    COCKPIT = (40, 160, 220, 255)

    # Body triangle (pointing up)
    body = [
        (cx, 4),
        (cx + 12, size - 4),
        (cx - 12, size - 4),
    ]
    _poly(g, body, MAIN)

    # Wings
    lwing = [(cx - 12, size - 4), (cx - 4, size - 12), (cx - 16, size - 10)]
    rwing = [(cx + 12, size - 4), (cx + 4, size - 12), (cx + 16, size - 10)]
    _poly(g, lwing, SH)
    _poly(g, rwing, SH)

    # Cockpit circle
    _circle(g, cx, cy - 2, 5, COCKPIT)

    # Highlight stripe
    _vline(g, cx, 6, cy - 8, HI)

    # Outline the whole thing
    _outline_circle(g, cx, size - 6, 10, BLK)
    for y in range(size):
        for x in range(size):
            if tuple(g[y][x]) != T and (
                x == 0 or y == 0 or x == size - 1 or y == size - 1
                or tuple(g[y][x - 1]) == T or tuple(g[y][x + 1]) == T
                or tuple(g[y - 1][x]) == T or tuple(g[y + 1][x]) == T
            ):
                pass  # skip border outline, handled per shape

    # Engine glow at bottom
    for dx in range(-3, 4):
        _set(g, cx + dx, size - 4, (255, 160, 40, 200))
    for dx in range(-2, 3):
        _set(g, cx + dx, size - 3, (255, 200, 80, 150))

    return _flat(g)


def make_enemy_basic(size=28):
    """Small red angry bubble."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    R = size // 2 - 2
    MAIN = (230, 50, 50, 255)
    HI = (255, 110, 110, 255)
    SH = (140, 15, 15, 255)

    _circle(g, cx, cy, R, MAIN)
    # Highlight top-left
    _circle(g, cx - 3, cy - 3, R // 3, HI)
    # Shadow bottom-right
    _circle(g, cx + 2, cy + 2, R // 4, SH)
    # Angry eyes
    for ex, ey in [(cx - 4, cy - 2), (cx + 4, cy - 2)]:
        _circle(g, ex, ey, 2, BLK)
        _circle(g, ex - 1, ey - 1, 1, (255, 50, 50, 255))
    # Frown
    for dx in range(-3, 4):
        _set(g, cx + dx, cy + 5, BLK)
    _set(g, cx - 3, cy + 4, BLK)
    _set(g, cx + 3, cy + 4, BLK)
    _outline_circle(g, cx, cy, R, BLK)

    return _flat(g)


def make_enemy_tank(size=42):
    """Large dark-red armored brute."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    R = size // 2 - 2
    MAIN = (170, 18, 18, 255)
    HI = (210, 60, 60, 255)
    SH = (90, 5, 5, 255)
    ARMOR = (120, 10, 10, 255)

    _circle(g, cx, cy, R, MAIN)
    # Armor plates
    for i in range(3):
        angle = math.pi / 4 + i * math.pi / 3
        ax = int(cx + (R - 5) * math.cos(angle))
        ay = int(cy + (R - 5) * math.sin(angle))
        _circle(g, ax, ay, 4, ARMOR)
    # Highlight
    _circle(g, cx - 5, cy - 5, R // 4, HI)
    # Mean eyes (horizontal slits)
    for ex in [cx - 5, cx + 5]:
        _hline(g, cy - 3, ex - 2, ex + 2, BLK)
        _hline(g, cy - 2, ex - 1, ex + 1, (180, 30, 30, 255))
    # Outline
    _outline_circle(g, cx, cy, R, BLK)

    return _flat(g)


def make_enemy_zigzag(size=26):
    """Orange spiky wasp-like enemy."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    MAIN = (240, 155, 25, 255)
    HI = (255, 200, 90, 255)
    WING = (240, 210, 120, 180)
    SH = (170, 90, 5, 255)

    # Wings (translucent)
    lwing = [(cx - 4, cy), (cx - 12, cy - 6), (cx - 10, cy + 6)]
    rwing = [(cx + 4, cy), (cx + 12, cy - 6), (cx + 10, cy + 6)]
    _poly(g, lwing, WING)
    _poly(g, rwing, WING)

    # Diamond body
    body = [(cx, cy - 9), (cx + 7, cy), (cx, cy + 9), (cx - 7, cy)]
    _poly(g, body, MAIN)
    # Highlight
    _poly(g, [(cx, cy - 7), (cx + 3, cy - 2), (cx - 3, cy - 2)], HI)
    # Eye
    _circle(g, cx, cy - 1, 2, BLK)
    _set(g, cx, cy - 1, (255, 80, 20, 255))

    return _flat(g)


def make_enemy_boss(size=72):
    """Large purple demon face."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    R = size // 2 - 3
    MAIN = (120, 30, 195, 255)
    HI = (180, 80, 255, 255)
    SH = (55, 8, 100, 255)
    HORN = (80, 15, 140, 255)
    EYE_GLOW = (255, 50, 50, 255)
    MOUTH = (40, 5, 80, 255)

    # Main head
    _circle(g, cx, cy + 4, R, MAIN)
    # Highlight top-left
    _circle(g, cx - 10, cy - 6, R // 4, HI)
    # Shadow bottom
    _circle(g, cx + 5, cy + 12, R // 3, SH)

    # Horns
    horn_l = [(cx - 16, cy - R + 8), (cx - 22, cy - R - 8), (cx - 10, cy - R + 2)]
    horn_r = [(cx + 16, cy - R + 8), (cx + 22, cy - R - 8), (cx + 10, cy - R + 2)]
    _poly(g, horn_l, HORN)
    _poly(g, horn_r, HORN)

    # Glowing red eyes
    for ex in [cx - 12, cx + 12]:
        _circle(g, ex, cy - 4, 7, BLK)
        _circle(g, ex, cy - 4, 5, EYE_GLOW)
        _circle(g, ex, cy - 4, 2, (255, 200, 50, 255))

    # Mouth — wide frown with teeth
    for dx in range(-12, 13):
        _set(g, cx + dx, cy + 14, BLK)
        _set(g, cx + dx, cy + 15, MOUTH)
    for dx in range(-10, 11):
        _set(g, cx + dx, cy + 16, MOUTH)
    # Teeth
    for tx in [cx - 8, cx - 3, cx + 3, cx + 8]:
        _vline(g, tx, cy + 15, cy + 18, WHT)

    _outline_circle(g, cx, cy + 4, R, BLK)

    return _flat(g)


def make_projectile(size=14):
    """Small yellow-green guac drop."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    MAIN = (170, 235, 35, 255)
    HI = (220, 255, 100, 255)
    CORE = (255, 255, 180, 255)

    # Teardrop shape — circle + pointed top
    _circle(g, cx, cy + 2, size // 2 - 2, MAIN)
    # Pointed top
    tip = [(cx, 0), (cx - 3, 5), (cx + 3, 5)]
    _poly(g, tip, MAIN)
    # Core glow
    _circle(g, cx, cy + 2, 2, CORE)
    # Highlight
    _set(g, cx - 1, cy - 1, HI)

    return _flat(g)


def make_gem(size=18):
    """Cyan XP diamond."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    MAIN = (30, 200, 230, 255)
    HI = (130, 240, 255, 255)
    SH = (10, 120, 160, 255)
    EDGE = (5, 80, 120, 255)

    diamond = [(cx, 1), (cx + 7, cy), (cx, size - 2), (cx - 7, cy)]
    _poly(g, diamond, MAIN)
    # Upper facet
    top_facet = [(cx, 1), (cx + 7, cy), (cx, cy)]
    _poly(g, top_facet, HI)
    # Lower facet
    bot_facet = [(cx, cy), (cx + 7, cy), (cx, size - 2)]
    _poly(g, bot_facet, SH)
    # Left facet
    left_facet = [(cx, 1), (cx, cy), (cx - 7, cy)]
    _poly(g, left_facet, (60, 210, 240, 255))
    # Shine
    _set(g, cx + 1, cy - 3, WHT)

    return _flat(g)


def make_heart(size=26):
    """Classic red heart."""
    g = _grid(size, size)
    cx, cy = size // 2, size // 2
    MAIN = (235, 40, 40, 255)
    HI = (255, 120, 120, 255)

    # Two circles for the top bumps
    _circle(g, cx - 5, cy - 2, 7, MAIN)
    _circle(g, cx + 5, cy - 2, 7, MAIN)
    # Bottom triangle
    tip = [(cx - 12, cy + 2), (cx + 12, cy + 2), (cx, cy + 13)]
    _poly(g, tip, MAIN)
    # Highlight
    _circle(g, cx - 6, cy - 4, 2, HI)
    _set(g, cx - 6, cy - 5, WHT)

    return _flat(g)


# ---------------------------------------------------------------------------
# Power-up icons  (32×32)
# ---------------------------------------------------------------------------

_ICON_COLORS = {
    "triple_shot":    (50, 140, 255, 255),
    "super_guac":     (50, 210, 80, 255),
    "rapid_fire":     (255, 130, 30, 255),
    "mole_grenade":   (200, 80, 50, 255),
    "jalapeno_laser": (255, 230, 40, 255),
    "spicy_bounce":   (200, 60, 220, 255),
    "nacho_wall":     (230, 195, 40, 255),
    "salsa_magnet":   (40, 220, 220, 255),
    "guac_storm":     (100, 235, 60, 255),
}


def _rounded_rect(g, x1, y1, x2, y2, r, c):
    _rect(g, x1 + r, y1, x2 - r, y2, c)
    _rect(g, x1, y1 + r, x2, y2 - r, c)
    _circle(g, x1 + r, y1 + r, r, c)
    _circle(g, x2 - r, y1 + r, r, c)
    _circle(g, x1 + r, y2 - r, r, c)
    _circle(g, x2 - r, y2 - r, r, c)


def _icon_base(name, size=32):
    g = _grid(size, size)
    bg = _ICON_COLORS[name]
    dark_bg = (max(0, bg[0] - 50), max(0, bg[1] - 50), max(0, bg[2] - 50), 255)
    _rounded_rect(g, 1, 1, size - 2, size - 2, 4, bg)
    _rounded_rect(g, 1, 1, size - 2, size - 2, 4, dark_bg)  # outline trick
    _rounded_rect(g, 2, 2, size - 3, size - 3, 3, bg)
    return g


def _make_ts_icon(size=32):
    """Triple shot — three upward arrows."""
    g = _icon_base("triple_shot", size)
    for ox in [-8, 0, 8]:
        cx = size // 2 + ox
        _vline(g, cx, 8, 22, WHT)
        _set(g, cx, 7, WHT)
        _set(g, cx - 1, 10, WHT)
        _set(g, cx + 1, 10, WHT)
    return _flat(g)


def _make_sg_icon(size=32):
    """Super guac — star burst."""
    g = _icon_base("super_guac", size)
    cx, cy = size // 2, size // 2
    for angle_deg in range(0, 360, 45):
        a = math.radians(angle_deg)
        for r in range(2, 11):
            _set(g, int(cx + r * math.cos(a)), int(cy + r * math.sin(a)), WHT)
    _circle(g, cx, cy, 3, WHT)
    return _flat(g)


def _make_rf_icon(size=32):
    """Rapid fire — lightning bolt."""
    g = _icon_base("rapid_fire", size)
    bolt = [(18, 6), (12, 16), (17, 16), (14, 26), (20, 14), (15, 14)]
    _poly(g, bolt, WHT)
    return _flat(g)


def _make_mg_icon(size=32):
    """Mole grenade — explosion."""
    g = _icon_base("mole_grenade", size)
    cx, cy = size // 2, size // 2
    _circle(g, cx, cy, 6, WHT)
    for angle_deg in range(0, 360, 40):
        a = math.radians(angle_deg)
        for r in range(7, 12):
            _set(g, int(cx + r * math.cos(a)), int(cy + r * math.sin(a)), WHT)
    return _flat(g)


def _make_jl_icon(size=32):
    """Jalapeno laser — vertical beam."""
    g = _icon_base("jalapeno_laser", size)
    cx = size // 2
    _rect(g, cx - 2, 4, cx + 2, size - 5, WHT)
    _circle(g, cx, 7, 4, WHT)
    return _flat(g)


def _make_sb_icon(size=32):
    """Spicy bounce — bouncing arrow."""
    g = _icon_base("spicy_bounce", size)
    # Diagonal arrow going down-right then reflecting up-right
    pts1 = [(8, 8), (20, 20), (8, 20)]  # first segment
    pts2 = [(20, 20), (24, 8), (28, 20)]  # reflected
    _poly(g, pts1, WHT)
    _poly(g, pts2, WHT)
    _hline(g, 22, 6, 26, WHT)
    return _flat(g)


def _make_nw_icon(size=32):
    """Nacho wall — shield."""
    g = _icon_base("nacho_wall", size)
    shield = [(size // 2, 6), (size - 7, 10), (size - 7, 20), (size // 2, 26), (7, 20), (7, 10)]
    _poly(g, shield, WHT)
    # Cross on shield
    _vline(g, size // 2, 10, 22, _ICON_COLORS["nacho_wall"])
    _hline(g, 16, 10, size - 11, _ICON_COLORS["nacho_wall"])
    return _flat(g)


def _make_sm_icon(size=32):
    """Salsa magnet — horseshoe magnet."""
    g = _icon_base("salsa_magnet", size)
    cx, cy = size // 2, size // 2
    # Outer arch
    for angle_deg in range(10, 171):
        a = math.radians(angle_deg)
        for r in [9, 10, 11]:
            _set(g, int(cx + r * math.cos(a)), int(cy - r * math.sin(a) + 2), WHT)
    # Two prongs
    _rect(g, cx - 11, cy - 2, cx - 8, cy + 8, WHT)
    _rect(g, cx + 8, cy - 2, cx + 11, cy + 8, WHT)
    # Red tip left, blue tip right
    _rect(g, cx - 11, cy + 6, cx - 8, cy + 10, (255, 80, 80, 255))
    _rect(g, cx + 8, cy + 6, cx + 11, cy + 10, (80, 80, 255, 255))
    return _flat(g)


def _make_gs_icon(size=32):
    """Guac storm — multiple upward streams."""
    g = _icon_base("guac_storm", size)
    for ox in [-10, -5, 0, 5, 10]:
        cx = size // 2 + ox
        _vline(g, cx, 6, 24, WHT)
        _set(g, cx - 1, 9, WHT)
        _set(g, cx + 1, 9, WHT)
        _set(g, cx, 6, WHT)
    return _flat(g)


_ICON_MAKERS = {
    "triple_shot":    _make_ts_icon,
    "super_guac":     _make_sg_icon,
    "rapid_fire":     _make_rf_icon,
    "mole_grenade":   _make_mg_icon,
    "jalapeno_laser": _make_jl_icon,
    "spicy_bounce":   _make_sb_icon,
    "nacho_wall":     _make_nw_icon,
    "salsa_magnet":   _make_sm_icon,
    "guac_storm":     _make_gs_icon,
}

# ---------------------------------------------------------------------------
# WAV helpers
# ---------------------------------------------------------------------------

RATE = 44100


def _env(samples, attack=0.005, release=0.08):
    n = len(samples)
    atk = max(1, int(attack * RATE))
    rel = max(1, int(release * RATE))
    return [
        s * min(1.0, i / atk) * min(1.0, (n - i) / rel)
        for i, s in enumerate(samples)
    ]


def _sine(freq, dur, amp=0.45):
    n = int(dur * RATE)
    return [amp * math.sin(2 * math.pi * freq * i / RATE) for i in range(n)]


def _sweep(f0, f1, dur, amp=0.45):
    n = int(dur * RATE)
    return [amp * math.sin(2 * math.pi * (f0 + (f1 - f0) * i / n) * i / RATE) for i in range(n)]


def _noise(dur, amp=0.25):
    n = int(dur * RATE)
    return [amp * (random.random() * 2 - 1) for _ in range(n)]


def _mix(*tracks):
    n = max(len(t) for t in tracks)
    result = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            result[i] += s
    # Normalize
    peak = max(abs(s) for s in result) or 1.0
    return [s / peak * 0.9 for s in result]


def _concat(*tracks):
    result = []
    for t in tracks:
        result.extend(t)
    return result


def save_wav(path, samples):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    data = array.array("h", [max(-32767, min(32767, int(s * 32767))) for s in samples])
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    print(f"  + {path}")


# ---------------------------------------------------------------------------
# Sound designs
# ---------------------------------------------------------------------------

def sfx_shoot():
    s = _sweep(900, 600, 0.06, 0.4)
    return _env(s, 0.002, 0.04)


def sfx_enemy_die():
    s = _mix(_sweep(440, 150, 0.15, 0.35), _noise(0.1, 0.15))
    return _env(s, 0.002, 0.06)


def sfx_player_hit():
    s = _mix(_sweep(180, 60, 0.25, 0.4), _noise(0.12, 0.3))
    return _env(s, 0.003, 0.12)


def sfx_gem_collect():
    s = _sine(1320, 0.07, 0.5)
    return _env(s, 0.001, 0.04)


def sfx_levelup():
    notes = [(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.25)]
    return _env(_concat(*[_sine(f, d, 0.5) for f, d in notes]), 0.002, 0.15)


def sfx_boss_die():
    s = _mix(
        _sweep(120, 30, 0.9, 0.5),
        _noise(0.5, 0.4),
        _sweep(800, 50, 0.9, 0.3),
    )
    return _env(s, 0.01, 0.4)


def sfx_music_loop():
    """Simple 4-bar pentatonic melody ~4 seconds."""
    bpm = 130
    beat = 60 / bpm
    h = beat / 2
    q = beat / 4

    # Melody: C4 D4 E4 G4 A4 C5
    melody = [
        (523, h), (659, h), (784, q), (659, q),
        (523, h), (440, h), (392, beat),
        (392, h), (523, h), (659, q), (523, q),
        (440, h), (392, h), (523, beat),
    ]
    track = _concat(*[_sine(f, d, 0.35) for f, d in melody])

    # Bass: simple root notes
    bass_notes = [
        (131, beat), (165, beat), (196, beat), (131, beat),
        (131, beat), (110, beat), (98, beat * 2),
        (98, beat), (131, beat), (165, beat), (131, beat),
        (110, beat), (98, beat), (131, beat * 2),
    ]
    bass = _concat(*[_sine(f, d, 0.25) for f, d in bass_notes])

    combined = _mix(track, bass)
    return _env(combined, 0.02, 0.1)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("\n=== Generating sprites ===")
    sprites = {
        "assets/sprites/player.png":       (32, 32, make_player(32)),
        "assets/sprites/enemy_basic.png":  (28, 28, make_enemy_basic(28)),
        "assets/sprites/enemy_tank.png":   (42, 42, make_enemy_tank(42)),
        "assets/sprites/enemy_zigzag.png": (26, 26, make_enemy_zigzag(26)),
        "assets/sprites/enemy_boss.png":   (72, 72, make_enemy_boss(72)),
        "assets/sprites/projectile.png":   (14, 14, make_projectile(14)),
        "assets/sprites/gem.png":          (18, 18, make_gem(18)),
        "assets/sprites/heart.png":        (26, 26, make_heart(26)),
    }
    for path, (w, h, pixels) in sprites.items():
        save_png(path, w, h, pixels)

    print("\n=== Generating power-up icons ===")
    for name, maker in _ICON_MAKERS.items():
        save_png(f"assets/sprites/powerup_icons/{name}.png", 32, 32, maker(32))

    print("\n=== Generating audio ===")
    sfx = {
        "assets/audio/shoot.wav":       sfx_shoot(),
        "assets/audio/enemy_die.wav":   sfx_enemy_die(),
        "assets/audio/player_hit.wav":  sfx_player_hit(),
        "assets/audio/gem_collect.wav": sfx_gem_collect(),
        "assets/audio/levelup.wav":     sfx_levelup(),
        "assets/audio/boss_die.wav":    sfx_boss_die(),
        "assets/audio/music_loop.wav":  sfx_music_loop(),
    }
    for path, samples in sfx.items():
        save_wav(path, samples)

    print("\nDone. Run 'godot --headless --quit' to import new assets.")


if __name__ == "__main__":
    main()
