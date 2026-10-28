"""Colour-coded keys, key doors and switches in the New Bricks City look (owner playtest: switches and key doors
were hard to pick out). Built from the theme's own textures so they sit in the maps, sized like what they replace
(zscript/nbc/mapmarks.zs swaps them in when a map loads):

    python tools/art/make_key_art.py

    nbc/textures/nbc/NBCDRRED.png, NBCDRBLU.png, NBCDRYEL.png   key doors: the steel door (ADDOORS), a painted band,
                                                                 coloured edges and a lit card reader (64 x 128)
    nbc/textures/nbc/NBCSW1A.png / NBCSW1B.png                   a breaker box in a hazard frame: lever up and a red
                                                                 lamp; lever down and a green lamp (ANIMDEFS swaps them)
    nbc/textures/nbc/NBCSWEX1.png / NBCSWEX2.png                 the exit switch: the breaker box under a lit EXIT sign
    nbc/sprites/keys/RKEYA0..YKEYB0.png                          keycards: a laminated ID card on a coloured lanyard
                                                                 (two frames, the second lit)
Deterministic.
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEX = os.path.join(ROOT, "nbc", "textures")
OUT_T = os.path.join(TEX, "nbc")
OUT_S = os.path.join(ROOT, "nbc", "sprites", "keys")

COLORS = {"RED": (210, 40, 34), "BLU": (40, 96, 220), "YEL": (236, 196, 40)}
KEYS = {"R": (210, 40, 34), "B": (40, 96, 220), "Y": (236, 196, 40)}


def load(name):
    for sub in ("cw", os.path.join("cw", "themes"), "nbc"):
        p = os.path.join(TEX, sub, name + ".png")
        if os.path.exists(p):
            return Image.open(p).convert("RGB")
    raise SystemExit("missing texture " + name)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def hazard(d, box, c1=(236, 196, 40), c2=(24, 24, 24), w=6):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=c2)
    for k in range(-(y1 - y0), x1 - x0 + (y1 - y0), w * 2):
        d.polygon([(x0 + k, y1), (x0 + k + w, y1), (x0 + k + w + (y1 - y0), y0), (x0 + k + (y1 - y0), y0)], fill=c1)


def key_door(color):
    img = load("ADDOORS")
    px = img.load()
    w, h = img.size
    # a wash of the key's colour over the steel
    for y in range(h):
        for x in range(w):
            px[x, y] = mix(px[x, y], color, 0.22)
    d = ImageDraw.Draw(img)
    # the painted band across the door, with dark rims
    d.rectangle((0, 78, w - 1, 96), fill=color)
    d.line((0, 77, w - 1, 77), fill=(20, 20, 22))
    d.line((0, 97, w - 1, 97), fill=(20, 20, 22))
    d.rectangle((4, 82, w - 5, 92), outline=mix(color, (255, 255, 255), 0.35))
    # coloured edges, both sides
    d.rectangle((0, 0, 2, h - 1), fill=color)
    d.rectangle((w - 3, 0, w - 1, h - 1), fill=color)
    # the card reader: a dark box with a lit slot in the key's colour
    d.rectangle((50, 58, 59, 72), fill=(26, 28, 32), outline=(10, 10, 12))
    d.rectangle((52, 61, 57, 64), fill=mix(color, (255, 255, 255), 0.5))
    d.rectangle((53, 67, 56, 69), fill=(12, 12, 14))
    return img


def breaker(on, exit_sign=False):
    img = load("AXW38")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            px[x, y] = mix(px[x, y], (30, 32, 36), 0.55)
    d = ImageDraw.Draw(img)
    top = 38
    if exit_sign:
        d.rectangle((6, 10, w - 7, 30), fill=(14, 16, 14), outline=(60, 64, 60))
        # EXIT in a blocky lit green
        g = (90, 255, 120) if on else (60, 220, 90)
        x = 11
        for ch in "EXIT":
            for (a, b, c, e) in GLYPHS[ch]:
                d.rectangle((x + a, 14 + b, x + c, 14 + e), fill=g)
            x += 11
    # the hazard frame and the box
    hazard(d, (4, top, w - 5, top + 66))
    d.rectangle((10, top + 6, w - 11, top + 60), fill=(52, 56, 62), outline=(16, 16, 18))
    d.rectangle((12, top + 8, w - 13, top + 10), fill=(78, 84, 92))
    # the middle of the box is a lit plate, red when off and green when on: the switch prefabs show only a window
    # of the texture round where Doom's switch graphics sit, so the whole middle has to read as "switch"
    lamp = (60, 220, 90) if on else (225, 50, 40)
    rim = mix(lamp, (0, 0, 0), 0.45)
    d.rectangle((18, top + 8, 45, top + 58), fill=lamp, outline=rim)
    d.rectangle((20, top + 10, 43, top + 12), fill=mix(lamp, (255, 255, 255), 0.45))
    # the lever: a slot down the plate, the handle up when off, down when on
    d.rectangle((29, top + 14, 34, top + 54), fill=rim)
    ly = top + 38 if on else top + 18
    d.rectangle((22, ly, 41, ly + 8), fill=(230, 230, 226), outline=(30, 30, 30))
    d.rectangle((24, ly + 2, 39, ly + 3), fill=(255, 255, 255))
    return img


# 3x5-ish block glyphs for EXIT: rectangles (x0, y0, x1, y1) in a 9 x 11 cell
GLYPHS = {
    "E": [(0, 0, 1, 10), (0, 0, 7, 1), (0, 5, 6, 6), (0, 9, 7, 10)],
    "X": [(0, 0, 1, 3), (6, 0, 7, 3), (2, 3, 5, 7), (0, 7, 1, 10), (6, 7, 7, 10)],
    "I": [(3, 0, 4, 10), (1, 0, 6, 1), (1, 9, 6, 10)],
    "T": [(0, 0, 7, 1), (3, 0, 4, 10)],
}


def keycard(color, lit):
    img = Image.new("RGBA", (18, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # the lanyard loop
    d.line((5, 0, 9, 6), fill=color + (255,), width=2)
    d.line((13, 0, 9, 6), fill=color + (255,), width=2)
    d.rectangle((7, 5, 11, 8), fill=(150, 150, 150, 255))
    # the card: laminated white with a coloured band, a photo square and a chip
    card = (232, 232, 228) if lit else (200, 200, 196)
    d.rectangle((2, 8, 16, 21), fill=card + (255,), outline=(30, 30, 30, 255))
    d.rectangle((3, 9, 15, 12), fill=(mix(color, (255, 255, 255), 0.3) if lit else color) + (255,))
    d.rectangle((4, 14, 7, 18), fill=(90, 80, 70, 255))
    d.rectangle((10, 15, 14, 16), fill=(60, 60, 60, 255))
    d.rectangle((10, 18, 13, 19), fill=(60, 60, 60, 255))
    return img


def save_sprite(img, path, xoff, yoff):
    """A PNG with a grAb chunk (the sprite's offsets)."""
    import struct
    import zlib
    img.save(path)
    data = open(path, "rb").read()
    chunk = b"grAb" + struct.pack(">ii", xoff, yoff)
    grab = struct.pack(">I", 8) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)
    # after IHDR (8 signature + 25 IHDR)
    open(path, "wb").write(data[:33] + grab + data[33:])


def main():
    os.makedirs(OUT_T, exist_ok=True)
    os.makedirs(OUT_S, exist_ok=True)
    for name, c in COLORS.items():
        key_door(c).save(os.path.join(OUT_T, "NBCDR%s.png" % name))
    breaker(False).save(os.path.join(OUT_T, "NBCSW1A.png"))
    breaker(True).save(os.path.join(OUT_T, "NBCSW1B.png"))
    breaker(False, True).save(os.path.join(OUT_T, "NBCSWEX1.png"))
    breaker(True, True).save(os.path.join(OUT_T, "NBCSWEX2.png"))
    for k, c in KEYS.items():
        for frame, lit in (("A", False), ("B", True)):
            save_sprite(keycard(c, lit), os.path.join(OUT_S, "%sKEY%s0.png" % (k, frame)), 9, 22)
    print("wrote key doors, switches and keycards")


if __name__ == "__main__":
    main()
