#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=11"]
# ///
"""Generate launcher icons and in-app logo assets from the brand masters.

Usage (from the repo root):
    uv run app/tool/generate_icons.py

Reads brand/binpal-icon-1024.png (square, opaque) and brand/binpal-logo.png
(transparent wordmark). Writes:

* iOS: a single-size 1024 px AppIcon (Xcode derives the rest).
* Android: adaptive icon (background colour + transparent foreground +
  monochrome layer for themed icons) and legacy square icons for Android 7.
* app/assets/brand/logo.png at 1x, 2x and 3x.
* brand/previews/icon-masks.png: the icon under common launcher masks.
"""

from __future__ import annotations

import json
import math
import statistics
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "brand"
APP = ROOT / "app"
RES = APP / "android/app/src/main/res"
IOS_ICONSET = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

# Adaptive icons are 108 dp; every launcher mask keeps at least a 66 dp circle.
ADAPTIVE_DP = 108
SAFE_DIAMETER_DP = 66
# Launchers show the inner 72 dp of the layer.
VISIBLE_DP = 72

# Logo display height in logical pixels (see AboutScreen).
LOGO_HEIGHT = 56


def background_colour(icon: Image.Image) -> tuple[int, int, int]:
    """Median colour of the icon's outer border."""
    rgb = icon.convert("RGB")
    w, h = rgb.size
    edge = [rgb.getpixel((x, y)) for x in range(0, w, 4) for y in range(0, h, 4)
            if min(x, y, w - 1 - x, h - 1 - y) < 150]
    return tuple(int(statistics.median(p[i] for p in edge)) for i in range(3))


def extract_foreground(icon: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    """Key out the flat background, keeping soft anti-aliased edges."""
    rgb = icon.convert("RGB")
    out = Image.new("RGBA", rgb.size)
    lo, hi = 18.0, 70.0  # colour distance: below = background, above = artwork
    src, dst = rgb.load(), out.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            c = src[x, y]
            d = math.dist(c, bg)
            a = min(1.0, max(0.0, (d - lo) / (hi - lo)))
            if a == 0:
                dst[x, y] = (0, 0, 0, 0)
                continue
            # Un-mix the background from edge pixels so they look right on any colour.
            f = tuple(min(255, max(0, round(bg[i] + (c[i] - bg[i]) / a))) for i in range(3))
            dst[x, y] = (*f, round(a * 255))
    return out


def place_like_ios(art: Image.Image, size: int) -> Image.Image:
    """Scale the full-icon artwork to the 72 dp a launcher shows, so the mascot
    takes the same share of the icon as on iOS, and check it stays inside the
    66 dp safe circle."""
    visible = round(size * VISIBLE_DP / ADAPTIVE_DP)
    scaled = art.resize((visible, visible), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size))
    offset = (size - visible) // 2
    canvas.alpha_composite(scaled, (offset, offset))

    alpha = canvas.getchannel("A")
    c = size / 2
    radius = max(
        math.hypot(x - c, y - c)
        for y in range(0, size, 2)
        for x in range(0, size, 2)
        if alpha.getpixel((x, y)) > 32
    )
    safe = size * SAFE_DIAMETER_DP / ADAPTIVE_DP / 2
    assert radius <= safe, f"artwork reaches {radius:.0f}px, safe circle is {safe:.0f}px"
    return canvas


def monochrome(foreground: Image.Image) -> Image.Image:
    """Line art for Android 13+ themed icons: the dark outline, face and the
    sparkle. The launcher tints whatever is opaque."""
    r, g, b, a = foreground.split()
    luminance = Image.merge("RGB", (r, g, b)).convert("L")
    strokes = luminance.point(lambda v: 255 if v < 80 else (0 if v > 110 else round((110 - v) * 255 / 30)))
    # The purple sparkle: blue well above red and green.
    sparkle = ImageChops.subtract(b, ImageChops.lighter(r, g), scale=1, offset=0).point(
        lambda v: 255 if v > 50 else (0 if v < 25 else round((v - 25) * 255 / 25)))
    mask = ImageChops.multiply(ImageChops.lighter(strokes, sparkle), a)
    return Image.merge("RGBA", (mask.point(lambda _: 255),) * 3 + (mask,))


def write_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)


def generate_ios(icon: Image.Image) -> None:
    for old in IOS_ICONSET.glob("*.png"):
        old.unlink()
    write_png(icon.convert("RGB").resize((1024, 1024), Image.LANCZOS), IOS_ICONSET / "AppIcon-1024.png")
    contents = {
        "images": [{"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }
    (IOS_ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def generate_android(icon: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    art = extract_foreground(icon, bg)
    master = place_like_ios(art, 432)
    mono = monochrome(master)
    for name, factor in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        adaptive = round(ADAPTIVE_DP * factor)
        write_png(master.resize((adaptive, adaptive), Image.LANCZOS), folder / "ic_launcher_foreground.png")
        write_png(mono.resize((adaptive, adaptive), Image.LANCZOS), folder / "ic_launcher_monochrome.png")
        legacy = round(48 * factor)
        write_png(icon.convert("RGB").resize((legacy, legacy), Image.LANCZOS), folder / "ic_launcher.png")

    hex_bg = "#%02X%02X%02X" % bg
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{hex_bg}</color>\n</resources>\n'
    )
    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n'
    )
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(adaptive_xml)
    return master


def generate_logo(logo: Image.Image) -> None:
    logo = logo.crop(logo.getchannel("A").getbbox())
    out = APP / "assets/brand"
    for scale, sub in ((1, ""), (2, "2.0x/"), (3, "3.0x/")):
        h = LOGO_HEIGHT * scale
        w = round(logo.width * h / logo.height)
        write_png(logo.resize((w, h), Image.LANCZOS), out / sub / "logo.png")


def preview(icon: Image.Image, foreground: Image.Image, bg: tuple[int, int, int]) -> None:
    """The icon under iOS and common Android launcher masks, plus the themed icon."""
    size, pad = 220, 24
    full = Image.new("RGBA", (432, 432), (*bg, 255))
    full.alpha_composite(foreground)
    # Launchers show the inner 72 of 108 dp.
    inner = full.crop((72, 72, 360, 360)).resize((size, size), Image.LANCZOS)

    def mask(kind: str) -> Image.Image:
        m = Image.new("L", (size * 4, size * 4))
        d = ImageDraw.Draw(m)
        s = size * 4
        if kind == "circle":
            d.ellipse((0, 0, s - 1, s - 1), fill=255)
        elif kind == "squircle":
            d.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.32, fill=255)
        elif kind == "rounded":
            d.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.12, fill=255)
        elif kind == "teardrop":
            d.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.5, fill=255)
            d.rectangle((s // 2, s // 2, s - 1, s - 1), fill=255)
        elif kind == "ios":
            d.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.2237, fill=255)
        return m.resize((size, size), Image.LANCZOS)

    tiles = [("ios", icon.convert("RGBA").resize((size, size), Image.LANCZOS))]
    tiles += [(k, inner) for k in ("circle", "squircle", "rounded", "teardrop")]
    themed = Image.new("RGBA", (size, size), (225, 236, 210, 255))
    mono = monochrome(foreground).crop((72, 72, 360, 360)).resize((size, size), Image.LANCZOS)
    themed.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", (size, size), (40, 70, 30)).split(), mono.getchannel("A"))))
    tiles.append(("circle", themed))

    sheet = Image.new("RGBA", (len(tiles) * (size + pad) + pad, size + 2 * pad), (255, 248, 240, 255))
    for i, (kind, tile) in enumerate(tiles):
        clipped = Image.new("RGBA", (size, size))
        clipped.paste(tile, (0, 0), mask(kind))
        shadow = mask(kind).filter(ImageFilter.GaussianBlur(4)).point(lambda v: v // 4)
        x = pad + i * (size + pad)
        sheet.paste((0, 0, 0, 255), (x + 2, pad + 4, x + 2 + size, pad + 4 + size), shadow)
        sheet.alpha_composite(clipped, (x, pad))
    write_png(sheet.convert("RGB"), BRAND / "previews/icon-masks.png")


def main() -> None:
    icon = Image.open(BRAND / "binpal-icon-1024.png")
    bg = background_colour(icon)
    generate_ios(icon)
    foreground = generate_android(icon, bg)
    generate_logo(Image.open(BRAND / "binpal-logo.png").convert("RGBA"))
    preview(icon, foreground, bg)
    print("background #%02X%02X%02X" % bg)


if __name__ == "__main__":
    main()
