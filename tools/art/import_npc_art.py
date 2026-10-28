"""Bring the owner's character art from art/ into the mod (2026-10-28).

    python tools/art/import_npc_art.py

* Officer portraits: the six "Pixel Mercenary Portrait Grid N.png" sheets (6 x 4 heads, 256-px cells) are cut
  into 144 portraits, nbc/graphics/portraits/NBCPF000.png ... NBCPF143.png, 96 x 96, numbered sheet by sheet,
  row by row. One face is Det. Vance (NBCPVANC.png) and is kept out of the officers' pool
  (NBC_Cat.VANCE_FACE).
* The captain: PMC-boss.png (standing) and PMC-boss-1..6.png (the cigar) become the billboard sprite NCAP
  frames A-G; the pilot, Pilot.png, becomes NPLT A. One rotation (frame 0: the same from every side), offsets
  set so the feet stand on the floor.
* The helicopter, helicopter.png, becomes graphics/NBCHELI.png (the pilot's wheels-up screen).
Re-run after the art changes; it overwrites only these files.
"""
import os
import struct
import zlib
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(ROOT, "art")
PORTRAITS = os.path.join(ROOT, "nbc", "graphics", "portraits")
SPRITES = os.path.join(ROOT, "nbc", "sprites", "npcs")
GRAPHICS = os.path.join(ROOT, "nbc", "graphics")
SIZE = 96
VANCE_FACE = 10        # sheet 1, row 2, column 5: keep in step with NBC_Cat.VANCE_FACE


def save_with_grab(img, path, ox, oy):
    """Write a PNG with a grAb chunk (the sprite's offsets)."""
    img.save(path)
    data = open(path, "rb").read()
    chunk = b"grAb" + struct.pack(">ii", ox, oy)
    grab = struct.pack(">I", 8) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)
    # right after IHDR (8-byte signature + 25-byte IHDR chunk)
    open(path, "wb").write(data[:33] + grab + data[33:])


def portraits():
    os.makedirs(PORTRAITS, exist_ok=True)
    # the old generated set (two-digit names) goes
    for f in os.listdir(PORTRAITS):
        if len(f) == len("NBCPF00.png") and f.startswith("NBCPF"):
            os.remove(os.path.join(PORTRAITS, f))
    n = 0
    for sheet in range(1, 7):
        im = Image.open(os.path.join(ART, "Pixel Mercenary Portrait Grid %d.png" % sheet)).convert("RGB")
        cw, ch = im.width // 6, im.height // 4
        for row in range(4):
            for col in range(6):
                cell = im.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
                # a little margin trimmed so the head fills the card
                m = cw // 16
                cell = cell.crop((m, m, cw - m, ch - m)).resize((SIZE, SIZE), Image.LANCZOS)
                cell.save(os.path.join(PORTRAITS, "NBCPF%03d.png" % n))
                if n == VANCE_FACE:
                    cell.save(os.path.join(PORTRAITS, "NBCPVANC.png"))
                n += 1
    return n


def billboard(src, path):
    im = Image.open(os.path.join(ART, src)).convert("RGBA")
    bbox = im.getbbox()
    # centred, the lowest opaque row on the floor
    save_with_grab(im, path, im.width // 2, bbox[3] - 1 if bbox else im.height)


def npcs():
    os.makedirs(SPRITES, exist_ok=True)
    billboard("PMC-boss.png", os.path.join(SPRITES, "NCAPA0.png"))
    for i in range(1, 7):
        billboard("PMC-boss-%d.png" % i, os.path.join(SPRITES, "NCAP%s0.png" % "ABCDEFG"[i]))
    billboard("Pilot.png", os.path.join(SPRITES, "NPLTA0.png"))
    Image.open(os.path.join(ART, "helicopter.png")).convert("RGBA").save(os.path.join(GRAPHICS, "NBCHELI.png"))


def main():
    n = portraits()
    npcs()
    print("portraits: %d (+ NBCPVANC); sprites NCAP A-G, NPLT A; graphics NBCHELI" % n)


if __name__ == "__main__":
    main()
