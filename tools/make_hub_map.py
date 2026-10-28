"""Build nbc/maps/NBC_HUB.wad: Checkpoint 9, the precinct post built into the Wall (PLAN M2).

    python tools/make_hub_map.py

One UDMF room furnished with the ported Corpo Wars props (nbc/mapinfo/cw_props.txt):
* the raid board (a whiteboard; NBC_RaidBoard 26010 is the Use target) on the north wall
* the armory (a row of lockers and a gun bench; NBC_ArmoryLocker 26011) on the west wall
* desks and file cabinets in the middle, a squad corner with a sofa on the east side (NBC_SquadRoom 26012)
UZDoom builds the nodes on load.
"""
import os
import re
import struct

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "nbc", "maps", "NBC_HUB.wad")

W, H, CEIL = 1152, 768, 160
WALL, FLOOR, CEILING = "ADGREYW", "AXF39", "CWCEILT"


def prop_ids():
    ids = {}
    text = open(os.path.join(ROOT, "nbc", "mapinfo", "cw_props.txt")).read()
    for m in re.finditer(r"(\d+)\s*=\s*(\w+)", text):
        ids[m.group(2)] = int(m.group(1))
    ids.update({"Player1": 1, "NBC_RaidBoard": 26010, "NBC_ArmoryLocker": 26011, "NBC_SquadRoom": 26012})
    return ids


def things():
    t = [("Player1", 576, 140, 90)]
    # the raid board: a whiteboard on the north wall, notices either side
    t += [("CW_FWhiteboard", 576, 757, 270), ("NBC_RaidBoard", 576, 736, 270),
          ("CWD_Bank_Bulletin", 460, 767, 270), ("CWD_Apt_Corkboard", 692, 767, 270),
          ("CW_FWallTV", 330, 757, 270), ("CWD_Bank_Clock", 820, 767, 270)]
    # the armory: lockers and a gun bench on the west wall
    t += [("CW_FLocker", 12, y, 0) for y in (300, 336, 372, 408, 444)]
    t += [("NBC_ArmoryLocker", 44, 372, 0), ("CW_FWorkbench", 18, 540, 0), ("CW_FCrates", 32, 620, 0),
          ("CWD_Bank_Extinguisher", 1, 220, 0), ("CWD_Bank_NoSmoking", 1, 480, 0)]
    # the bullpen: four desks with chairs
    for x in (400, 752):
        for y in (380, 520):
            t += [("CW_FDeskWork", x, y, 270), ("CW_FChair", x, y + 30, 270)]
    # file cabinets and a cooler on the south wall
    t += [("CW_FFileCabinet", x, 16, 90) for x in (820, 846, 872, 898)]
    t += [("CW_FWaterCooler", 960, 12, 90), ("CW_FVending", 1100, 19, 90), ("CWD_Bank_Certificate", 300, 1, 90),
          ("CW_FPlanter", 160, 16, 90)]
    # the squad corner: sofa against the east wall, table, armchairs
    t += [("CW_FSofa", 1131, 384, 180), ("CW_FCoffeeTable", 1070, 384, 0),
          ("CW_FArmchair", 1040, 300, 45), ("CW_FArmchair", 1040, 468, 315), ("CWD_Apt_Painting_City", 1151, 384, 180),
          ("NBC_SquadRoom", 1104, 384, 180)]   # Use the sofa: the squad room (roster, promotions, recruits)
    return t


def textmap():
    ids = prop_ids()
    out = ['namespace = "zdoom";']
    verts = [(0, 0), (0, H), (W, H), (W, 0)]          # clockwise: front sides face in
    for name, x, y, angle in things():
        out.append(f"thing {{ x = {x}.0; y = {y}.0; angle = {angle}; type = {ids[name]}; "
                   "skill1 = true; skill2 = true; skill3 = true; skill4 = true; skill5 = true; "
                   "single = true; coop = true; dm = true; }")
    for x, y in verts:
        out.append(f"vertex {{ x = {x}.0; y = {y}.0; }}")
    for i in range(4):
        out.append(f"linedef {{ v1 = {i}; v2 = {(i + 1) % 4}; sidefront = {i}; blocking = true; }}")
        out.append(f'sidedef {{ sector = 0; texturemiddle = "{WALL}"; }}')
    out.append(f'sector {{ heightfloor = 0; heightceiling = {CEIL}; texturefloor = "{FLOOR}"; '
               f'textureceiling = "{CEILING}"; lightlevel = 200; }}')
    return ("\n".join(out) + "\n").encode("ascii")


def wad(lumps):
    body, directory = b"", b""
    for name, data in lumps:
        directory += struct.pack("<ii8s", 12 + len(body), len(data), name.encode("ascii"))
        body += data
    return struct.pack("<4sii", b"PWAD", len(lumps), 12 + len(body)) + body + directory


def main():
    with open(OUT, "wb") as f:
        f.write(wad([("NBC_HUB", b""), ("TEXTMAP", textmap()), ("ENDMAP", b"")]))
    print("wrote", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
