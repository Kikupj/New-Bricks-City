"""List the wall textures and flats available to maps: the IWAD (Freedoom 2), nbc/textures/,
nbc/flats/ and TEXTURES definitions in nbc/. Use it before writing a texture name into a map or kit.

    python tools/list_textures.py               # everything, one "NAME  source" per line
    python tools/list_textures.py BRICK         # names containing BRICK
    python tools/list_textures.py --check NAME  # exit 1 if NAME doesn't exist
"""
import argparse
import os
import re
import struct
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NBC = os.path.join(ROOT, "nbc")
IWAD = os.path.join(ROOT, "freedoom-0.13.0", "freedoom2.wad")


def iwad_names(path):
    data = open(path, "rb").read()
    _, count, offset = struct.unpack("<4sii", data[:12])
    lumps, in_flats = {}, False
    names = {}
    for i in range(count):
        pos, size, raw = struct.unpack("<ii8s", data[offset + 16 * i:offset + 16 * i + 16])
        name = raw.rstrip(b"\0").decode("ascii", "replace").upper()
        if name in ("F_START", "FF_START"):
            in_flats = True
        elif name in ("F_END", "FF_END"):
            in_flats = False
        elif in_flats and size:
            names[name] = "iwad flat"
        lumps[name] = (pos, size)
    for tex in ("TEXTURE1", "TEXTURE2"):
        if tex in lumps:
            pos, size = lumps[tex]
            blob = data[pos:pos + size]
            n = struct.unpack("<i", blob[:4])[0]
            for k in range(n):
                off = struct.unpack("<i", blob[4 + 4 * k:8 + 4 * k])[0]
                names[blob[off:off + 8].rstrip(b"\0").decode("ascii", "replace").upper()] = "iwad wall"
    return names


def nbc_names():
    names = {}
    for sub, label in (("textures", "nbc texture"), ("flats", "nbc flat")):
        for d, _, fs in os.walk(os.path.join(NBC, sub)):
            for f in fs:
                names[f.split(".")[0].upper()] = f"{label} ({os.path.relpath(os.path.join(d, f), NBC)})"
    for f in os.listdir(NBC):
        if f.upper().startswith("TEXTURES") and os.path.isfile(os.path.join(NBC, f)):
            text = open(os.path.join(NBC, f), encoding="latin1").read()
            for kind, name in re.findall(r'^\s*(Texture|WallTexture|Flat)\s+"?([\w\-]+)', text, re.M | re.I):
                names[name.upper()] = f"nbc {kind.lower()} ({f})"
    return names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pattern", nargs="?", default="")
    ap.add_argument("--check")
    args = ap.parse_args()
    names = iwad_names(IWAD)
    names.update(nbc_names())
    if args.check:
        found = args.check.upper() in names
        print(f"{args.check}: {names.get(args.check.upper(), 'NOT FOUND')}")
        sys.exit(0 if found else 1)
    for name in sorted(names):
        if args.pattern.upper() in name:
            print(f"{name:10} {names[name]}")


if __name__ == "__main__":
    main()
