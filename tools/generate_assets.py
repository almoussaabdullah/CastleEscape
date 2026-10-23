#!/usr/bin/env python3
"""Generates the original raster assets used by Castle Escape.

All artwork here is procedural and original (no third-party assets):
  * tileable stone / wood / dark-stone textures used by SpriteKit tiled walls
  * soft radial glow sprite (torches, windows, moon halo)
  * spark particle used by SKEmitterNode
  * 1024x1024 App Icon (night castle silhouette)

Run from the repository root:  python3 tools/generate_assets.py
"""
import json
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS = os.path.join(ROOT, "CastleEscape", "Resources", "Assets.xcassets")


def ensure(path):
    os.makedirs(path, exist_ok=True)


def write_json(path, obj):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2)


def imageset(name, image, single_scale=True):
    folder = os.path.join(ASSETS, f"{name}.imageset")
    ensure(folder)
    filename = f"{name}.png"
    image.save(os.path.join(folder, filename), "PNG")
    entry = {"filename": filename, "idiom": "universal"}
    contents = {
        "images": [entry],
        "info": {"author": "xcode", "version": 1},
    }
    if not single_scale:
        entry["scale"] = "1x"
    write_json(os.path.join(folder, "Contents.json"), contents)
    print("wrote", folder)


# ---------------------------------------------------------------- textures

def stone_tile(size=512, base=(96, 104, 122), seed=7, mortar=(46, 50, 64)):
    rnd = random.Random(seed)
    img = Image.new("RGB", (size, size), mortar)
    draw = ImageDraw.Draw(img)
    rows = 8
    row_h = size // rows
    for r in range(rows):
        offset = (row_h * 1) if r % 2 else 0
        x = -offset
        while x < size:
            w = rnd.randint(int(row_h * 1.4), int(row_h * 2.6))
            jitter = rnd.randint(-10, 10)
            col = tuple(max(0, min(255, c + jitter + rnd.randint(-6, 6))) for c in base)
            x0, y0 = x + 3, r * row_h + 3
            x1, y1 = x + w - 3, (r + 1) * row_h - 3
            draw.rounded_rectangle([x0, y0, x1, y1], radius=6, fill=col)
            # highlight edge (top-left) and shadow (bottom-right) for depth
            hl = tuple(min(255, c + 22) for c in col)
            sh = tuple(max(0, c - 26) for c in col)
            draw.line([x0 + 2, y0 + 2, x1 - 2, y0 + 2], fill=hl, width=3)
            draw.line([x0 + 2, y0 + 2, x0 + 2, y1 - 2], fill=hl, width=3)
            draw.line([x0 + 2, y1 - 2, x1 - 2, y1 - 2], fill=sh, width=3)
            draw.line([x1 - 2, y0 + 2, x1 - 2, y1 - 2], fill=sh, width=3)
            # speckles
            for _ in range(rnd.randint(6, 14)):
                px = rnd.randint(x0 + 4, max(x0 + 5, x1 - 4))
                py = rnd.randint(y0 + 4, max(y0 + 5, y1 - 4))
                c = tuple(max(0, min(255, v + rnd.randint(-18, 18))) for v in col)
                draw.ellipse([px, py, px + 3, py + 3], fill=c)
            x += w
    # make horizontally tileable by wrapping the right edge
    wrapped = Image.new("RGB", (size, size))
    wrapped.paste(img, (0, 0))
    return wrapped.filter(ImageFilter.GaussianBlur(0.6))


def wood_tile(size=512, seed=3):
    rnd = random.Random(seed)
    img = Image.new("RGB", (size, size), (120, 78, 44))
    draw = ImageDraw.Draw(img)
    planks = 6
    ph = size // planks
    for p in range(planks):
        shade = rnd.randint(-14, 14)
        col = (120 + shade, 78 + shade // 2, 44 + shade // 3)
        draw.rectangle([0, p * ph, size, (p + 1) * ph - 4], fill=col)
        for _ in range(26):
            y = rnd.randint(p * ph + 4, (p + 1) * ph - 8)
            x0 = rnd.randint(0, size)
            x1 = x0 + rnd.randint(40, 220)
            c = tuple(max(0, v - rnd.randint(8, 26)) for v in col)
            draw.line([x0, y, x1, y + rnd.randint(-2, 2)], fill=c, width=rnd.randint(1, 3))
        draw.rectangle([0, (p + 1) * ph - 4, size, (p + 1) * ph], fill=(70, 42, 22))
    return img


def glow_sprite(size=256, color=(255, 190, 110)):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c + 0.5, y - c + 0.5) / c
            a = max(0.0, 1.0 - d)
            a = a * a * (3 - 2 * a)  # smoothstep
            px[x, y] = (color[0], color[1], color[2], int(255 * a))
    return img


def spark_sprite(size=64):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c + 0.5, y - c + 0.5) / c
            a = max(0.0, 1.0 - d * 1.15)
            a = a ** 1.6
            px[x, y] = (255, 255, 255, int(255 * a))
    return img


def cloud_sprite(size=512, seed=11):
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size // 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for _ in range(28):
        r = rnd.randint(size // 10, size // 5)
        x = rnd.randint(r, size - r)
        y = rnd.randint(size // 4 - r // 2 + 20, size // 2 - r // 3)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 255))
    img = img.filter(ImageFilter.GaussianBlur(14))
    # fade edges
    alpha = img.split()[3]
    alpha = alpha.point(lambda a: int(min(255, a * 1.4)))
    img.putalpha(alpha)
    return img


# ---------------------------------------------------------------- app icon

def app_icon(size=1024):
    img = Image.new("RGB", (size, size), (14, 18, 46))
    draw = ImageDraw.Draw(img)
    # night-sky gradient
    for y in range(size):
        t = y / size
        r = int(12 + 30 * t)
        g = int(16 + 20 * t)
        b = int(52 + 70 * t)
        draw.line([0, y, size, y], fill=(r, g, b))
    rnd = random.Random(42)
    for _ in range(140):
        x, y = rnd.randint(0, size), rnd.randint(0, int(size * 0.55))
        s = rnd.randint(1, 4)
        draw.ellipse([x, y, x + s, y + s], fill=(255, 255, 240))
    # moon with halo
    halo = glow_sprite(600, (255, 240, 200))
    img.paste(Image.new("RGB", halo.size, (255, 240, 200)), (size - 560, -120), halo.split()[3].point(lambda a: a // 3))
    draw.ellipse([size - 380, 60, size - 180, 260], fill=(252, 244, 214))
    # mountains
    draw.polygon([(0, 760), (180, 540), (330, 680), (470, 500), (620, 660), (800, 480), (1024, 700), (1024, 1024), (0, 1024)], fill=(38, 44, 80))
    draw.polygon([(0, 860), (160, 700), (300, 790), (520, 640), (700, 780), (900, 660), (1024, 800), (1024, 1024), (0, 1024)], fill=(28, 32, 62))
    # castle silhouette
    stone = (66, 72, 96)
    dark = (44, 48, 70)
    cx = 512
    # keep
    draw.rectangle([cx - 150, 300, cx + 150, 900], fill=stone)
    # battlements
    for i in range(-150, 150, 50):
        draw.rectangle([cx + i + 6, 270, cx + i + 34, 300], fill=stone)
    # side towers
    for tx in (cx - 260, cx + 260):
        draw.rectangle([tx - 70, 420, tx + 70, 900], fill=dark)
        draw.polygon([(tx - 90, 420), (tx + 90, 420), (tx, 280)], fill=(120, 40, 50))
        draw.rectangle([tx - 4, 240, tx + 4, 300], fill=(120, 120, 140))
        draw.polygon([(tx + 4, 240), (tx + 60, 258), (tx + 4, 276)], fill=(230, 60, 70))
    # central turret
    draw.rectangle([cx - 60, 150, cx + 60, 300], fill=dark)
    draw.polygon([(cx - 80, 150), (cx + 80, 150), (cx, 40)], fill=(120, 40, 50))
    # windows: 10 floors, top one glowing
    for i in range(10):
        y = 330 + i * 56
        for wx in (cx - 90, cx, cx + 90):
            lit = (i == 0 and wx == cx - 90) or rnd.random() < 0.25
            col = (255, 196, 90) if lit else (24, 26, 44)
            draw.rounded_rectangle([wx - 14, y, wx + 14, y + 36], radius=10, fill=col)
            if i == 0 and wx == cx - 90:
                g = glow_sprite(220, (255, 190, 90))
                img.paste(Image.new("RGB", g.size, (255, 190, 90)), (wx - 110, y - 90), g.split()[3].point(lambda a: int(a * 0.8)))
    # gate
    draw.rounded_rectangle([cx - 60, 760, cx + 60, 900], radius=55, fill=(20, 20, 34))
    for gx in range(cx - 50, cx + 60, 22):
        draw.line([gx, 790, gx, 900], fill=(90, 94, 120), width=6)
    # bridge
    draw.rectangle([0, 870, cx - 150, 905], fill=(74, 80, 106))
    for ax in range(40, cx - 150, 120):
        draw.pieslice([ax, 880, ax + 90, 990], 180, 360, fill=(74, 80, 106))
    # ground
    draw.rectangle([0, 900, size, size], fill=(30, 34, 58))
    # fog band
    fog = Image.new("RGBA", (size, 260), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    for i in range(0, size, 90):
        fd.ellipse([i - 80, 60, i + 180, 220], fill=(200, 210, 240, 90))
    fog = fog.filter(ImageFilter.GaussianBlur(40))
    img.paste(fog, (0, 780), fog)
    return img


def main():
    ensure(ASSETS)
    write_json(os.path.join(ASSETS, "Contents.json"), {"info": {"author": "xcode", "version": 1}})

    # App icon
    icon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    ensure(icon_dir)
    app_icon().save(os.path.join(icon_dir, "AppIcon.png"), "PNG")
    write_json(os.path.join(icon_dir, "Contents.json"), {
        "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    })

    # Accent color
    accent_dir = os.path.join(ASSETS, "AccentColor.colorset")
    ensure(accent_dir)
    write_json(os.path.join(accent_dir, "Contents.json"), {
        "colors": [{"color": {"color-space": "srgb", "components": {"alpha": "1.000", "blue": "0.350", "green": "0.720", "red": "1.000"}}, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    })

    imageset("stone_tile", stone_tile())
    imageset("stone_tile_dark", stone_tile(base=(62, 66, 86), seed=19, mortar=(28, 30, 42)))
    imageset("wood_tile", wood_tile())
    imageset("glow_soft", glow_sprite())
    imageset("spark", spark_sprite())
    imageset("cloud_puff", cloud_sprite())
    print("done")


if __name__ == "__main__":
    main()
