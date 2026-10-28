"""The skyline at other hours (the time of day, clock.zs): the night skyline the districts use (CITYSKY, Corpo
Wars) recoloured for the morning, the afternoon and dusk. The buildings keep their silhouettes; the sky, the
skyline and the haze below it are repainted.

    python tools/art/make_sky_variants.py     # nbc/textures/nbc/NBCSKYMR.png, NBCSKYDY.png, NBCSKYDK.png

Deterministic; no randomness.
"""
import os
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "nbc", "textures", "cw", "CITYSKY.png")
OUT = os.path.join(ROOT, "nbc", "textures", "nbc")
GROUND = 214          # the haze band under the skyline starts here
SCAN_FROM = 120       # no building reaches above this row

# zenith, horizon, glow tint, building dark, building light, window (None: unlit glass), haze top, haze bottom
VARIANTS = {
    "NBCSKYMR": dict(zenith=(64, 92, 140), horizon=(236, 188, 150), glow=(255, 214, 170),
                     dark=(52, 54, 70), light=(96, 92, 110), window=(250, 214, 150), wfrac=0.25,
                     haze=(150, 132, 132), haze2=(86, 78, 88)),
    "NBCSKYDY": dict(zenith=(58, 108, 182), horizon=(184, 206, 224), glow=(255, 255, 240),
                     dark=(86, 92, 104), light=(132, 138, 150), window=None, wfrac=0.0,
                     haze=(150, 152, 156), haze2=(104, 106, 112)),
    "NBCSKYDK": dict(zenith=(30, 26, 64), horizon=(236, 118, 58), glow=(255, 150, 80),
                     dark=(30, 26, 40), light=(58, 48, 64), window=(255, 196, 120), wfrac=0.7,
                     haze=(112, 66, 60), haze2=(52, 36, 44)),
}


def lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def building_mask(px, w, h):
    """Per column: from the first sharp drop in brightness under the sky (a roofline) down to the haze."""
    mask = [[False] * h for _ in range(w)]
    for x in range(w):
        sky = lum(px[x, SCAN_FROM])
        for y in range(SCAN_FROM + 1, GROUND):
            l = lum(px[x, y])
            if l < sky - 9:
                for yy in range(y, GROUND):
                    mask[x][yy] = True
                break
            sky = max(sky, l)
    return mask


def make(img, v):
    w, h = img.size
    px = img.load()
    mask = building_mask(px, w, h)
    # the sky's own brightness per row (its darkest pixel) and the glow on top of it, from a blurred copy (no stars)
    soft = img.filter(ImageFilter.GaussianBlur(8)).load()
    base = [min(lum(soft[x, y]) for x in range(w)) for y in range(h)]
    out = Image.new("RGB", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if y >= GROUND:
                op[x, y] = lerp(v["haze"], v["haze2"], (y - GROUND) / max(1, h - GROUND - 1))
                # the street lights in the haze stay a little
                g = (lum(soft[x, y]) - base[y]) / 80.0
                if g > 0:
                    op[x, y] = lerp(op[x, y], v["glow"], g * 0.4)
                continue
            if mask[x][y]:
                l = lum(c)
                lit = l > 70 and c[2] > c[0] + 20    # a lit window (pale blue in the night art)
                if lit and v["window"] and ((x // 3 + y // 3 * 7) % 10) < v["wfrac"] * 10:
                    op[x, y] = v["window"]
                else:
                    op[x, y] = lerp(v["dark"], v["light"], (min(l, 70) - 18) / 52.0)
                continue
            t = (y / float(GROUND)) ** 1.6
            col = lerp(v["zenith"], v["horizon"], t)
            g = (lum(soft[x, y]) - base[y]) / 60.0          # the glow over the city
            if g > 0:
                col = lerp(col, v["glow"], g * 0.5)
            op[x, y] = col
    return out


def main():
    img = Image.open(SRC).convert("RGB")
    os.makedirs(OUT, exist_ok=True)
    for name, v in VARIANTS.items():
        make(img, v).save(os.path.join(OUT, name + ".png"))
    print("wrote", ", ".join(VARIANTS), "to nbc/textures/nbc/")


if __name__ == "__main__":
    main()
