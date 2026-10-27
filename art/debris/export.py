"""Copy built debris sprites into nbc/sprites/debris/ with Doom grAb offsets.

Run after `pxl build debris.px.js`:  python art/debris/export.py
"""
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "out", "sprites")
DST = os.path.join(HERE, "..", "..", "nbc", "sprites", "debris")

# First-person frames keep the frag grenade's offsets (HGRNA0 hold, HGRNQ0 wind-up: same pixels).
VIEWMODEL = {"BRKHA0": ("BRKHA0", (-76, -36)), "BRKHB0": ("BRKHA0", (-180, -110))}
ON_FLOOR = ("BRKP", "HBRK", "CNCK", "RUBL")      # pickups and piles stand on their bottom row
CENTERED = ("BRKT", "HBKT", "CNKT", "BFRG")      # projectiles and fragments pivot on their middle


def png_size(data):
    return struct.unpack(">II", data[16:24])


def with_grab(data, x, y):
    """Insert (or replace) a grAb chunk right after IHDR."""
    body = struct.pack(">ii", x, y)
    chunk = struct.pack(">I", 8) + b"grAb" + body + struct.pack(">I", zlib.crc32(b"grAb" + body) & 0xFFFFFFFF)
    out, i = data[:33], 33                       # signature + IHDR
    out += chunk
    while i < len(data):
        n = struct.unpack(">I", data[i:i + 4])[0]
        if data[i + 4:i + 8] != b"grAb":
            out += data[i:i + 12 + n]
        i += 12 + n
    return out


def main():
    os.makedirs(DST, exist_ok=True)
    jobs = {name[:-4]: (name[:-4], None) for name in os.listdir(SRC) if name.endswith(".png") and name[:-4] not in VIEWMODEL}
    jobs.update(VIEWMODEL)
    for lump, (src, grab) in sorted(jobs.items()):
        data = open(os.path.join(SRC, src + ".png"), "rb").read()
        w, h = png_size(data)
        if grab is None:
            if lump.startswith(ON_FLOOR):
                grab = (w // 2, h - 1)
            elif lump.startswith(CENTERED):
                grab = (w // 2, h // 2)
            else:
                raise SystemExit(f"no offset rule for {lump}")
        open(os.path.join(DST, lump + ".png"), "wb").write(with_grab(data, *grab))
        print(f"{lump:8} {w:3}x{h:<3} grAb {grab}")


if __name__ == "__main__":
    main()
