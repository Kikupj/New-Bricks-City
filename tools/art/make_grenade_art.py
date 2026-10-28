"""Smoke grenades and flashbangs (zscript/nbc/grenades.zs), from the FragGrenade pack's grenade (nbc/sprites/weapons/
fraggrenade/) with the olive body recoloured, plus an original smoke puff and the canister's hiss:

    python tools/art/make_grenade_art.py

    nbc/sprites/grenades/NSMHA0, NFBHA0         the grenade in hand (the pack's HGRNA0): smoke pale grey with a green
                                                band, the flashbang charcoal with a white band
    nbc/sprites/grenades/NSMGA0, NFBGA0         pickups and icons (the pack's GNA1A0)
    nbc/sprites/grenades/NSMTA0-F0, NFBTA0-F0   in flight, tumbling (the pack's HGN1A0-F0)
    nbc/sprites/grenades/NSMKA0-D0              smoke puffs: soft grey blobs with alpha (original)
    nbc/sounds/grenades/NBCSMKHS.wav            the canister's hiss: filtered noise (original)
Deterministic.
"""
import math
import os
import random
import struct
import wave
import zlib
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "nbc", "sprites", "weapons", "fraggrenade")
OUT = os.path.join(ROOT, "nbc", "sprites", "grenades")
OUT_SND = os.path.join(ROOT, "nbc", "sounds", "grenades")

# (body colour, band colour) by grenade: the body replaces the pack's olive, the band its orange label
LOOKS = {
    "NSM": ((176, 178, 172), (70, 150, 70)),
    "NFB": ((52, 54, 58), (232, 232, 222)),
}


def grab(path):
    data = open(path, "rb").read()
    i = data.find(b"grAb")
    return struct.unpack(">ii", data[i + 4:i + 12]) if i > 0 else None


def save_sprite(img, path, offs):
    """A PNG with a grAb chunk (the sprite's offsets), after IHDR."""
    img.save(path)
    if not offs:
        return
    data = open(path, "rb").read()
    chunk = b"grAb" + struct.pack(">ii", *offs)
    block = struct.pack(">I", 8) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)
    open(path, "wb").write(data[:33] + block + data[33:])


def is_olive(r, g, b):
    return g >= r - 4 and g > b + 6 and max(r, g, b) < 200


def is_orange(r, g, b):
    return r > g + 25 and g > b + 10


def recolour(img, body, band):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    olive = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            olive[y][x] = a > 0 and is_olive(r, g, b)
    # the label band sits between olive pixels along the canister; the hand's skin doesn't: an orange pixel with
    # olive within 18 px on two opposite sides is the band (the small pickup and flight sprites have no hand: all of it)
    def near(x, y, dx, dy):
        for k in range(1, 19):
            xx, yy = x + dx * k, y + dy * k
            if 0 <= xx < w and 0 <= yy < h and olive[yy][xx]:
                return True
        return False
    out = img.copy()
    po = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (r * 0.3 + g * 0.59 + b * 0.11) / 255.0
            if olive[y][x]:
                t = min(1.4, lum / 0.32)
                po[x, y] = tuple(min(255, int(c * t)) for c in body) + (a,)
            elif is_orange(r, g, b) and (w <= 40 or (near(x, y, 1, -1) and near(x, y, -1, 1)) or (near(x, y, 1, 0) and near(x, y, -1, 0))
                                         or (near(x, y, 0, 1) and near(x, y, 0, -1))):
                t = min(1.3, lum / 0.45)
                po[x, y] = tuple(min(255, int(c * t)) for c in band) + (a,)
    return out


def puff(seed, size=64):
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    blobs = [(rnd.uniform(18, 46), rnd.uniform(20, 44), rnd.uniform(10, 18)) for _ in range(7)]
    for y in range(size):
        for x in range(size):
            a = 0.0
            for (bx, by, br) in blobs:
                d = math.hypot(x - bx, y - by) / br
                if d < 1.6:
                    a = max(a, (1.6 - d) / 1.6)
            if a <= 0:
                continue
            n = rnd.uniform(-18, 18)
            v = int(150 + 50 * a + n)
            px[x, y] = (v, v, min(255, v + 4), int(min(1.0, a * 1.3) * 210))
    return img.filter(ImageFilter.GaussianBlur(2))


def hiss(path, seconds=3.0, rate=22050):
    rnd = random.Random(7)
    n = int(seconds * rate)
    out = []
    lo = 0.0
    for i in range(n):
        x = rnd.uniform(-1, 1)
        lo += (x - lo) * 0.35                       # takes the edge off the white noise
        hi = x - lo                                 # ... and keeps the hiss
        t = i / n
        env = min(1.0, t * 12) * (1.0 - 0.55 * t)   # a sharp pop open, then easing off
        out.append(int(max(-1, min(1, hi * 0.8 * env)) * 20000))
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(b"".join(struct.pack("<h", s) for s in out))


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(OUT_SND, exist_ok=True)
    for pre, (body, band) in LOOKS.items():
        src = os.path.join(SRC, "HGRNA0")
        save_sprite(recolour(Image.open(src), body, band), os.path.join(OUT, pre + "HA0.png"), grab(src))
        src = os.path.join(SRC, "GNA1A0")
        save_sprite(recolour(Image.open(src), body, band), os.path.join(OUT, pre + "GA0.png"), grab(src))
        for f in "ABCDEF":
            src = os.path.join(SRC, "HGN1%s0" % f)
            save_sprite(recolour(Image.open(src), body, band), os.path.join(OUT, pre + "T%s0.png" % f), grab(src))
    for i, f in enumerate("ABCD"):
        save_sprite(puff(100 + i), os.path.join(OUT, "NSMK%s0.png" % f), (32, 32))
    hiss(os.path.join(OUT_SND, "NBCSMKHS.wav"))
    print("wrote grenade sprites and the smoke hiss")


if __name__ == "__main__":
    main()
