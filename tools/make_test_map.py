"""Build nbc/maps/NBC_TEST.wad: a UDMF brick room with a pillar, a player start and a few vanilla
monsters (the enemy pack's spawners replace them with human enemies). UZDoom builds the nodes on load.

    python tools/make_test_map.py
"""
import os
import struct

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "nbc", "maps", "NBC_TEST.wad")

WALL, FLOOR, CEIL = "BRICK7", "FLOOR4_8", "CEIL3_5"
OUTER = [(0, 0), (0, 1024), (1536, 1024), (1536, 0)]          # clockwise: front sides face in
PILLAR = [(640, 384), (896, 384), (896, 640), (640, 640)]     # counter-clockwise: front sides face out
THINGS = [  # (x, y, angle, type)
    (192, 512, 0, 1),        # player 1 start
    (1300, 200, 180, 3004),  # Zombieman  -> street thugs
    (1300, 512, 180, 9),     # ShotgunGuy -> suits / mobsters
    (1300, 820, 180, 3001),  # DoomImp    -> militia / street crew
    (1120, 300, 180, 65),    # ChaingunGuy -> Russians / bandits
    (1120, 740, 180, 3004),
    (448, 704, 90, 10600),   # 60sCarRed: Corpo Wars voxel car, proves the voxels and vehicles.txt load
]


def textmap():
    out = ['namespace = "zdoom";']
    verts, lines = [], []
    for loop in (OUTER, PILLAR):
        base = len(verts)
        verts += loop
        for i in range(len(loop)):
            lines.append((base + i, base + (i + 1) % len(loop)))
    for x, y, angle, kind in THINGS:
        out.append(f"thing {{ x = {x}.0; y = {y}.0; angle = {angle}; type = {kind}; "
                   "skill1 = true; skill2 = true; skill3 = true; skill4 = true; skill5 = true; "
                   "single = true; coop = true; dm = true; }")
    for x, y in verts:
        out.append(f"vertex {{ x = {x}.0; y = {y}.0; }}")
    for i, (a, b) in enumerate(lines):
        out.append(f"linedef {{ v1 = {a}; v2 = {b}; sidefront = {i}; blocking = true; }}")
        out.append(f'sidedef {{ sector = 0; texturemiddle = "{WALL}"; }}')
    out.append(f'sector {{ heightfloor = 0; heightceiling = 192; texturefloor = "{FLOOR}"; '
               f'textureceiling = "{CEIL}"; lightlevel = 192; }}')
    return ("\n".join(out) + "\n").encode("ascii")


def wad(lumps):
    body, directory, pos = b"", b"", 12
    for name, data in lumps:
        directory += struct.pack("<ii8s", pos + len(body), len(data), name.encode("ascii"))
        body += data
    return struct.pack("<4sii", b"PWAD", len(lumps), 12 + len(body)) + body + directory


if __name__ == "__main__":
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(wad([("NBC_TEST", b""), ("TEXTMAP", textmap()), ("ENDMAP", b"")]))
    print("wrote", os.path.relpath(OUT, ROOT))
