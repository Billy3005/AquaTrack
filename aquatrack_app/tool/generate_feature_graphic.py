"""Render the Google Play feature graphic (1024x500).

Play shows this at the top of the store listing and in promotional surfaces,
where it can be cropped and can have the app icon overlaid on top. So the
composition keeps every glyph inside a generous safe area rather than filling
the canvas edge to edge.

Run from aquatrack_app/:
    python tool/generate_feature_graphic.py

Output: assets/branding/play_feature_graphic_1024x500.png (RGB, no alpha —
Play flattens anything transparent onto an unpredictable background).
"""

from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
SS = 2  # supersample factor; everything is drawn at 2x then downsampled
RIGHT_MARGIN = 76  # keep every glyph clear of a crop

# Anchored to lib/core/constants/app_colors.dart so the store page and the app
# do not drift apart.
GLOW = (54, 196, 250)  # bright cyan behind the mark
MID = (16, 92, 176)  # mid blue body
EDGE = (8, 32, 78)  # deep navy at the far corners
CYAN = (0, 180, 216)  # #00B4D8 accent
CYAN_SOFT = (86, 205, 245)
WHITE = (255, 255, 255)
MUTED = (198, 220, 236)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON = os.path.join(ROOT, "assets", "branding", "app_icon_1024.png")
# Deliberately NOT play_feature_graphic_1024x500.png. That name holds the
# artwork actually uploaded to Play, which is hand-made; if this script owned
# the name, one stray run would silently destroy it.
OUT = os.path.join(ROOT, "assets", "branding", "play_feature_graphic_generated.png")

TITLE = "Wafubi"
TAGLINE = "Chụp ảnh ly nước → AI đếm ml"
SUB = "Uống đủ nước mỗi ngày, không phải nhớ"

# Mark placement, in final (un-supersampled) pixels.
MARK_PX = 268
MARK_X = 116
MARK_Y = (H - MARK_PX) // 2
GLOW_CX = MARK_X + MARK_PX // 2
GLOW_CY = MARK_Y + MARK_PX // 2


def _font(bold: bool, size: int) -> ImageFont.FreeTypeFont:
    """Segoe UI Variable when present, else Arial. Both cover Vietnamese.

    The variation name must match the font's own table exactly — Segoe UI
    Variable calls its faces "Bold Display", not "Display Bold". Getting it
    wrong used to raise into a bare `except: pass`, which silently shipped the
    default (light) instance and made every heading look unstyled. So a failed
    lookup now falls through to a genuinely bold static face instead.
    """
    seg = "C:/Windows/Fonts/SegUIVar.ttf"
    if os.path.exists(seg):
        f = ImageFont.truetype(seg, size)
        try:
            f.set_variation_by_name("Bold Display" if bold else "Regular Display")
            return f
        except OSError:
            pass  # not a variable build here — use a static face below

    for path in (
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibrib.ttf" if bold else "C:/Windows/Fonts/calibri.ttf",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _background(w: int, h: int, scale: int) -> Image.Image:
    """Radial cyan bloom behind the mark, falling off to deep navy at the edges.

    Vectorised because a per-pixel Python loop over 2M supersampled pixels is
    slow enough to discourage re-running this, and a graphic you avoid
    regenerating is one that goes stale.
    """
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = GLOW_CX * scale, GLOW_CY * scale

    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    t = np.clip(d / (w * 0.66), 0.0, 1.0) ** 1.25  # 0 at the mark, 1 far away

    # GLOW -> MID over the first half, MID -> EDGE over the second.
    near = np.clip(t / 0.5, 0, 1)[..., None]
    far = np.clip((t - 0.5) / 0.5, 0, 1)[..., None]
    g, m, e = (np.array(c, np.float32) for c in (GLOW, MID, EDGE))
    rgb = g + (m - g) * near
    rgb = rgb + (e - rgb) * far

    return Image.fromarray(rgb.clip(0, 255).astype(np.uint8), "RGB")


def _waves(w: int, h: int, scale: int) -> Image.Image:
    """Translucent water ribbons sweeping across the lower-left."""
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i, (amp, base, alpha, thick) in enumerate(
        ((30, 0.70, 64, 10), (38, 0.80, 52, 9), (26, 0.90, 40, 8), (20, 0.97, 30, 7))
    ):
        pts = []
        for x in range(0, w + 8, 8):
            phase = (x / w) * math.pi * 1.7 + i * 0.9
            y = base * h + math.sin(phase) * amp * scale
            pts.append((x, y))
        # Fade each ribbon out towards the right so the copy stays clean.
        for j in range(len(pts) - 1):
            fade = max(0.0, 1.0 - (pts[j][0] / w) / 0.72)
            a = int(alpha * fade)
            if a <= 0:
                continue
            d.line(
                [pts[j], pts[j + 1]],
                fill=CYAN_SOFT + (a,),
                width=thick * scale,
                joint="curve",
            )
    return layer.filter(ImageFilter.GaussianBlur(1.8 * scale))


def _bubbles(w: int, h: int, scale: int) -> Image.Image:
    """Scattered droplets. Kept off the text block so nothing fights the copy."""
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # (x, y, radius) in final pixels — all left of the wordmark or low-right.
    for x, y, r in (
        (72, 166, 19),
        (58, 250, 12),
        (190, 86, 10),
        (372, 408, 17),
        (326, 66, 8),
        (648, 456, 11),
        (452, 462, 7),
    ):
        cx, cy, rr = x * scale, y * scale, r * scale
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=(190, 232, 255, 74))
        d.ellipse(
            (cx - rr, cy - rr, cx + rr, cy + rr),
            outline=(232, 248, 255, 168),
            width=max(1, int(1.8 * scale)),
        )
        # Specular highlight, upper-left of each bubble.
        hr = max(1, int(rr * 0.32))
        hx, hy = cx - rr * 0.34, cy - rr * 0.36
        d.ellipse((hx - hr, hy - hr, hx + hr, hy + hr), fill=(255, 255, 255, 205))
    return layer


def _rounded(im: Image.Image, radius_ratio: float = 0.235) -> Image.Image:
    """Squircle-ish mask so the mark reads as an app icon, not a raw square."""
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, im.size[0] - 1, im.size[1] - 1),
        radius=int(im.size[0] * radius_ratio),
        fill=255,
    )
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im.convert("RGBA"), (0, 0), mask)
    return out


def main() -> int:
    if not os.path.exists(ICON):
        print(f"missing {ICON} — run tool/generate_icons.py first", file=sys.stderr)
        return 1

    w, h, s = W * SS, H * SS, SS
    canvas = _background(w, h, s).convert("RGBA")
    canvas = Image.alpha_composite(canvas, _waves(w, h, s))
    canvas = Image.alpha_composite(canvas, _bubbles(w, h, s))

    mark_px = MARK_PX * s
    mx, my = MARK_X * s, MARK_Y * s
    radius = int(mark_px * 0.235)

    # Halo + drop shadow, so the mark sits in the light rather than on top of it.
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    pad = int(30 * s)
    hd.rounded_rectangle(
        (mx - pad, my - pad, mx + mark_px + pad, my + mark_px + pad),
        radius=radius + pad,
        fill=(120, 220, 255, 58),
    )
    hd.rounded_rectangle(
        (mx + 4 * s, my + 11 * s, mx + mark_px + 4 * s, my + mark_px + 11 * s),
        radius=radius,
        fill=(4, 18, 44, 120),
    )
    canvas = Image.alpha_composite(canvas, halo.filter(ImageFilter.GaussianBlur(11 * s)))

    mark = _rounded(Image.open(ICON).convert("RGB").resize((mark_px, mark_px), Image.LANCZOS))
    canvas.paste(mark, (mx, my), mark)

    # Glassy rim, matching the lit edge in the reference.
    ImageDraw.Draw(canvas).rounded_rectangle(
        (mx, my, mx + mark_px - 1, my + mark_px - 1),
        radius=radius,
        outline=(190, 235, 255, 92),
        width=max(1, int(1.6 * s)),
    )

    d = ImageDraw.Draw(canvas)
    tx = (MARK_X + MARK_PX + 70) * s
    avail = (W - (MARK_X + MARK_PX + 70) - RIGHT_MARGIN) * s

    def fit(text: str, bold: bool, start: int, floor: int) -> ImageFont.FreeTypeFont:
        for size in range(start * s, floor * s - 1, -s):
            f = _font(bold, size)
            if d.textbbox((0, 0), text, font=f)[2] <= avail:
                return f
        return _font(bold, floor * s)

    f_title = fit(TITLE, True, 92, 54)
    f_tag = fit(TAGLINE, True, 34, 22)
    f_sub = fit(SUB, False, 26, 17)

    gap_tag, gap_sub, gap_rule = 20 * s, 14 * s, 24 * s
    rule_h = 5 * s
    h_title = d.textbbox((0, 0), TITLE, font=f_title)[3]
    h_tag = d.textbbox((0, 0), TAGLINE, font=f_tag)[3]
    h_sub = d.textbbox((0, 0), SUB, font=f_sub)[3]
    total = h_title + gap_tag + h_tag + gap_sub + h_sub + gap_rule + rule_h
    y = (h - total) // 2

    d.text((tx, y), TITLE, font=f_title, fill=WHITE)
    y += h_title + gap_tag
    d.text((tx, y), TAGLINE, font=f_tag, fill=CYAN_SOFT)
    y += h_tag + gap_sub
    d.text((tx, y), SUB, font=f_sub, fill=MUTED)
    y += h_sub + gap_rule

    # Two-segment accent rule, as in the reference.
    d.rounded_rectangle((tx, y, tx + 120 * s, y + rule_h), radius=rule_h // 2, fill=CYAN)
    d.rounded_rectangle(
        (tx + 136 * s, y, tx + 158 * s, y + rule_h), radius=rule_h // 2, fill=(0, 140, 190)
    )

    out = canvas.convert("RGB").resize((W, H), Image.LANCZOS)
    out.save(OUT, "PNG", optimize=True)

    widest = max(
        d.textbbox((0, 0), t, font=f)[2]
        for t, f in ((TITLE, f_title), (TAGLINE, f_tag), (SUB, f_sub))
    )
    print(f"  right margin: {(avail - widest) // s + RIGHT_MARGIN}px (budget {RIGHT_MARGIN}px)")
    print(f"wrote {OUT}  ({os.path.getsize(OUT) / 1024:.1f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
