"""Rasterise the AquaTrack icon (design B) to every size Android and Play need.

No SVG library available and none may be installed, so the handful of shapes in
app_icon.svg are re-drawn here with Pillow. The two non-trivial primitives —
SVG elliptical arcs and cubic beziers — are flattened with the W3C endpoint→
centre parameterisation rather than eyeballed, so the output matches the source
geometry exactly.

Everything is drawn at SS× the target and downsampled with LANCZOS, which is
what gives clean edges without a real vector rasteriser.
"""

import math
import os
import sys

from PIL import Image, ImageDraw

SS = 4  # supersample factor
BASE = 1024.0

OUT = sys.argv[1]

# ---------------------------------------------------------------- geometry


def arc_points(x0, y0, rx, ry, phi, large_arc, sweep, x1, y1, steps=180):
    """SVG elliptical arc → polyline. W3C F.6.5 endpoint→centre conversion."""
    if x0 == x1 and y0 == y1:
        return [(x0, y0)]
    phi = math.radians(phi)
    cos_p, sin_p = math.cos(phi), math.sin(phi)

    dx2, dy2 = (x0 - x1) / 2.0, (y0 - y1) / 2.0
    x1p = cos_p * dx2 + sin_p * dy2
    y1p = -sin_p * dx2 + cos_p * dy2

    rx, ry = abs(rx), abs(ry)
    lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
    if lam > 1:
        s = math.sqrt(lam)
        rx, ry = rx * s, ry * s

    num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
    den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    co = math.sqrt(max(0.0, num / den))
    if large_arc == sweep:
        co = -co
    cxp = co * rx * y1p / ry
    cyp = -co * ry * x1p / rx

    cx = cos_p * cxp - sin_p * cyp + (x0 + x1) / 2.0
    cy = sin_p * cxp + cos_p * cyp + (y0 + y1) / 2.0

    def angle(ux, uy, vx, vy):
        dot = ux * vx + uy * vy
        n = math.hypot(ux, uy) * math.hypot(vx, vy)
        a = math.acos(max(-1.0, min(1.0, dot / n)))
        return -a if (ux * vy - uy * vx) < 0 else a

    theta0 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dtheta = angle(
        (x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry
    )
    if not sweep and dtheta > 0:
        dtheta -= 2 * math.pi
    elif sweep and dtheta < 0:
        dtheta += 2 * math.pi

    pts = []
    for i in range(steps + 1):
        t = theta0 + dtheta * i / steps
        px = cos_p * rx * math.cos(t) - sin_p * ry * math.sin(t) + cx
        py = sin_p * rx * math.cos(t) + cos_p * ry * math.sin(t) + cy
        pts.append((px, py))
    return pts


def cubic_points(p0, p1, p2, p3, steps=90):
    out = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]
        out.append((x, y))
    return out


# ---------------------------------------------------------------- drawing


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size):
    """linearGradient x1=0 y1=0 x2=0.5 y2=1 over the bounding box."""
    stops = [(0.0, (0x22, 0xD3, 0xEE)), (0.5, (0x0E, 0xA5, 0xE9)), (1.0, (0x1E, 0x3A, 0x8A))]
    img = Image.new("RGB", (size, size))
    px = img.load()
    # Gradient vector in pixel space, then project each pixel onto it.
    vx, vy = 0.5 * size, 1.0 * size
    vlen2 = vx * vx + vy * vy
    for y in range(size):
        for x in range(size):
            t = (x * vx + y * vy) / vlen2
            t = 0.0 if t < 0 else (1.0 if t > 1 else t)
            for i in range(len(stops) - 1):
                a, b = stops[i], stops[i + 1]
                if a[0] <= t <= b[0]:
                    px[x, y] = lerp(a[1], b[1], (t - a[0]) / (b[0] - a[0]))
                    break
    return img


def scaled(pts, s):
    return [(x * s, y * s) for x, y in pts]


def stroke(draw, pts, width, colour, s):
    """Stroke a polyline by stamping discs along it.

    PIL's `line(..., joint="curve")` shreds a thick stroke into visible radial
    seams once the polyline is dense — each segment is its own quad and the
    overlaps show. Stamping a disc per sample has no seams and gives the round
    caps the source SVG asks for, for free.
    """
    r = width * s / 2.0
    step = max(1.0, r / 8.0)  # dense enough that consecutive discs overlap

    prev = None
    for x, y in scaled(pts, s):
        if prev is not None:
            dist = math.hypot(x - prev[0], y - prev[1])
            n = int(dist / step)
            for i in range(1, n):
                t = i / n
                ix = prev[0] + (x - prev[0]) * t
                iy = prev[1] + (y - prev[1]) * t
                draw.ellipse([ix - r, iy - r, ix + r, iy + r], fill=colour)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=colour)
        prev = (x, y)


def disc(draw, cx, cy, r, s, fill, outline=None, ow=0):
    box = [(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s]
    draw.ellipse(box, fill=fill, outline=outline, width=int(round(ow * s)))


def render(size):
    s = size * SS / BASE
    px = size * SS

    img = gradient(px).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")

    # Ground shadow — an ellipse mostly below the canvas.
    d.ellipse(
        [(512 - 520) * s, (1010 - 290) * s, (512 + 520) * s, (1010 + 290) * s],
        fill=(0x0C, 0x2A, 0x6B, int(255 * 0.3)),
    )

    # The two arms. Butt caps are fine: the fists below are wider than the
    # stroke and cover every endpoint.
    right = arc_points(377, 802, 320, 320, 0, 0, 0, 832, 512) + arc_points(
        832, 512, 320, 320, 0, 0, 0, 377, 222
    )
    left = arc_points(647, 802, 320, 320, 0, 0, 1, 192, 512) + arc_points(
        192, 512, 320, 320, 0, 0, 1, 647, 222
    )
    stroke(d, right, 98, (0x7D, 0xD3, 0xFC, 255), s)
    stroke(d, left, 98, (0xFF, 0xFF, 0xFF, 255), s)

    # Fists
    disc(d, 377, 222, 58, s, (0x7D, 0xD3, 0xFC, 255))
    disc(d, 377, 802, 58, s, (0x7D, 0xD3, 0xFC, 255))
    disc(d, 647, 222, 58, s, (0xFF, 0xFF, 0xFF, 255))
    disc(d, 647, 802, 58, s, (0xFF, 0xFF, 0xFF, 255))

    # The drop: point at the top, bezier shoulders, semicircular bottom.
    drop = cubic_points((512, 336), (512, 336), (646, 480), (646, 574))
    drop += arc_points(646, 574, 134, 134, 0, 1, 1, 378, 574)
    drop += cubic_points((378, 574), (378, 480), (512, 336), (512, 336))
    d.polygon(scaled(drop, s), fill=(0xFF, 0xFF, 0xFF, 255))

    # Highlight inside the drop.
    hi = arc_points(448, 566, 64, 64, 0, 0, 0, 512, 630)
    stroke(d, hi, 24, (0x38, 0xBD, 0xF8, 255), s)

    return img.resize((size, size), Image.LANCZOS)


def render_foreground(size):
    """Adaptive-icon foreground: art only, inset into the safe inner 66%.

    Launchers mask adaptive icons to arbitrary shapes and may parallax the
    layers, so anything outside the middle 66% can be clipped. The gradient
    plate is dropped here — it becomes the separate background layer.
    """
    art = render(size).convert("RGBA")
    art.putalpha(render_plate_mask(size))

    inner = int(size * 0.66)
    shrunk = art.resize((inner, inner), Image.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(shrunk, ((size - inner) // 2, (size - inner) // 2), shrunk)
    return canvas


def render_plate_mask(size):
    """Alpha mask covering only the foreground art (no background, no shadow)."""
    s = size * SS / BASE
    px = size * SS
    m = Image.new("L", (px, px), 0)
    d = ImageDraw.Draw(m)

    right = arc_points(377, 802, 320, 320, 0, 0, 0, 832, 512) + arc_points(
        832, 512, 320, 320, 0, 0, 0, 377, 222
    )
    left = arc_points(647, 802, 320, 320, 0, 0, 1, 192, 512) + arc_points(
        192, 512, 320, 320, 0, 0, 1, 647, 222
    )
    stroke(d, right, 98, 255, s)
    stroke(d, left, 98, 255, s)
    for cx, cy in ((377, 222), (377, 802), (647, 222), (647, 802)):
        d.ellipse([(cx - 58) * s, (cy - 58) * s, (cx + 58) * s, (cy + 58) * s], fill=255)
    drop = cubic_points((512, 336), (512, 336), (646, 480), (646, 574))
    drop += arc_points(646, 574, 134, 134, 0, 1, 1, 378, 574)
    drop += cubic_points((378, 574), (378, 480), (512, 336), (512, 336))
    d.polygon(scaled(drop, s), fill=255)

    return m.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- outputs

MIPMAPS = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

res = os.path.join(OUT, "android/app/src/main/res")
for dens, size in MIPMAPS.items():
    p = os.path.join(res, f"mipmap-{dens}", "ic_launcher.png")
    render(size).convert("RGB").save(p, "PNG", optimize=True)
    print(f"  {size:>4}px  {p}")

for dens, size in FOREGROUND.items():
    p = os.path.join(res, f"mipmap-{dens}", "ic_launcher_foreground.png")
    render_foreground(size).save(p, "PNG", optimize=True)
    print(f"  {size:>4}px  {p}")

# Adaptive background layer. Rasterised rather than a <gradient> drawable:
# android:angle only accepts multiples of 45 degrees and the source gradient
# runs at ~63, so an XML version would not match the legacy icon.
for dens, size in FOREGROUND.items():
    p = os.path.join(res, f"mipmap-{dens}", "ic_launcher_background.png")
    gradient(size).save(p, "PNG", optimize=True)
    print(f"  {size:>4}px  {p}")

play = os.path.join(OUT, "assets/branding/play_store_icon_512.png")
render(512).convert("RGB").save(play, "PNG", optimize=True)
print(f"   512px  {play}")

src = os.path.join(OUT, "assets/branding/app_icon_1024.png")
render(1024).convert("RGB").save(src, "PNG", optimize=True)
print(f"  1024px  {src}")
