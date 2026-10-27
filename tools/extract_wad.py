"""Extract a Doom WAD into loose lumps, the way a PK3 folder would hold them.

Lumps between sprite markers (S_START/SS_START .. S_END/SS_END) go to <out>/sprites/,
flats to <out>/flats/, patches to <out>/patches/, everything else to <out>/ itself.
Lumps keep their Doom names and get no file extension (UZDoom reads the format from the data).

    python tools/extract_wad.py Weapons/AK47.wad build/ak47
    python tools/extract_wad.py --list some.wad
"""
import argparse
import os
import struct

MARKERS = {
    "S_START": "sprites", "SS_START": "sprites", "S_END": None, "SS_END": None,
    "F_START": "flats", "FF_START": "flats", "F_END": None, "FF_END": None,
    "P_START": "patches", "PP_START": "patches", "P_END": None, "PP_END": None,
}


def read_lumps(path):
    data = open(path, "rb").read()
    ident, count, offset = struct.unpack("<4sii", data[:12])
    if ident not in (b"IWAD", b"PWAD"):
        raise SystemExit(f"{path}: not a WAD ({ident!r})")
    for i in range(count):
        pos, size, name = struct.unpack("<ii8s", data[offset + 16 * i:offset + 16 * i + 16])
        yield name.rstrip(b"\0").decode("ascii", "replace"), data[pos:pos + size]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("wad")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--list", action="store_true", help="only list the lumps")
    args = ap.parse_args()

    section = ""
    for name, blob in read_lumps(args.wad):
        upper = name.upper()
        if upper in MARKERS:
            section = MARKERS[upper] or ""
            continue
        if args.list:
            print(f"{section or '.':8} {name:8} {len(blob):8}")
            continue
        if not args.out:
            raise SystemExit("give an output folder, or --list")
        folder = os.path.join(args.out, section)
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, name), "wb") as f:
            f.write(blob)


if __name__ == "__main__":
    main()
