"""ONE-TIME import (milestone M0b, run 2026-10-26) from C:\\Games\\Corpo Wars (the owner's earlier mod).

Two kinds of copy:
  * reference/corpowars/  the complete Corpo Wars *source* (ZScript, definition lumps, design docs),
                          read-only. Its systems are tangled together (see docs/corpowars-port-map.md),
                          so each milestone ports what it needs from here into nbc/zscript/cw/.
  * nbc/ + tools/cw/      assets that are safe to load now (sprites, textures, voxel cars, models,
                          sounds, template maps) and the Python map tools.
No weapons, weapon art or item icons are taken (PLAN.md §0.1).

    python tools/import/import_corpowars.py [path-to-Corpo-Wars]
"""
import os
import re
import shutil
import struct
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Games\Corpo Wars"
CW = os.path.join(SRC, "CorpoWars")
NBC = os.path.join(ROOT, "nbc")
REF = os.path.join(ROOT, "reference", "corpowars")

ROOT_DEFS = ["citydist.txt", "cvarinfo.txt", "cwcity.txt", "decorate.txt", "decorate.vehicles.txt", "gldefs.txt",
             "keyconf.txt", "mapinfo.txt", "menudef.txt", "modeldef.props.txt", "sndinfo.txt", "sndseq.txt",
             "trnslate.txt", "zscript.txt", "README.md", "CREDITS.txt", "LICENSE-UEAI.txt", "CHANGELOG.md"]
TOOL_SKIP = {"_build", "_sheets", "__pycache__", "udb_mcp", "obsidian_addon",
             "slice_pistols.py", "import_guard_sprites.py", "check_guard_variants.py"}   # weapon/guard-sprite tools: not used
KIT_MAPS = {"K01": "NBC_K1", "K02": "NBC_K2", "K04": "NBC_K4"}


def copytree(src, dst, skip=()):
    shutil.copytree(src, dst, dirs_exist_ok=True, ignore=shutil.ignore_patterns(*skip) if skip else None)


def rename_map(src, dst, new_name):
    """Copy a map WAD, renaming its header lump to the new map name."""
    data = bytearray(open(src, "rb").read())
    _, count, offset = struct.unpack("<4sii", data[:12])
    first = data[offset + 8:offset + 16].rstrip(b"\0").decode()
    assert re.fullmatch(r"K\d\d", first), f"{src}: unexpected first lump {first}"
    data[offset + 8:offset + 16] = new_name.encode().ljust(8, b"\0")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    open(dst, "wb").write(data)


def main():
    # ---- reference copy (text sources)
    shutil.rmtree(REF, ignore_errors=True)
    copytree(os.path.join(CW, "zscript"), os.path.join(REF, "zscript"))
    copytree(os.path.join(CW, "shaders"), os.path.join(REF, "shaders"))
    for name in ROOT_DEFS:
        if os.path.exists(os.path.join(CW, name)):
            shutil.copy2(os.path.join(CW, name), os.path.join(REF, name))
    copytree(os.path.join(SRC, "Design Docs"), os.path.join(REF, "Design Docs"))
    os.makedirs(os.path.join(REF, "civilians2"), exist_ok=True)
    for name in ("DECORATE.lmp", "pedciv.txt"):
        shutil.copy2(os.path.join(SRC, "Civilians2", name), os.path.join(REF, "civilians2", name))
    shutil.copy2(os.path.join(SRC, "vvpck1.0", "vvpck1.0.txt"), os.path.join(REF, "vvpck1.0.txt"))

    # ---- Python tools (runnable; genmap.py rebuilds the kit template maps)
    tools = os.path.join(ROOT, "tools", "cw")
    shutil.rmtree(tools, ignore_errors=True)
    copytree(os.path.join(SRC, "CorpoWars_tools"), tools,
             skip=tuple(TOOL_SKIP) + ("*.png", "*.pk3", "*.wad", "_m02_textmap.txt"))

    # ---- assets that are safe to load now
    for sub in ("decor", "signs", "cityskyline", "breach"):
        dst = os.path.join(NBC, "sprites", "cw", sub)
        shutil.rmtree(dst, ignore_errors=True)
        copytree(os.path.join(CW, "sprites", sub), dst)
    gadgets = os.path.join(NBC, "sprites", "cw", "gadgets")
    os.makedirs(gadgets, exist_ok=True)
    for name in ("CWC3A0.png", "CWC4A0.png"):          # flashbang, noisemaker
        shutil.copy2(os.path.join(CW, "sprites", name), os.path.join(gadgets, name))

    shutil.rmtree(os.path.join(NBC, "textures", "cw"), ignore_errors=True)
    copytree(os.path.join(CW, "textures"), os.path.join(NBC, "textures", "cw"))
    shutil.rmtree(os.path.join(NBC, "brightmaps", "city"), ignore_errors=True)
    copytree(os.path.join(CW, "brightmaps", "city"), os.path.join(NBC, "brightmaps", "city"))
    shutil.rmtree(os.path.join(NBC, "models", "props"), ignore_errors=True)
    copytree(os.path.join(CW, "models", "props"), os.path.join(NBC, "models", "props"))
    shutil.rmtree(os.path.join(NBC, "voxels"), ignore_errors=True)
    copytree(os.path.join(CW, "voxels"), os.path.join(NBC, "voxels"))
    breach = os.path.join(NBC, "sounds", "cw", "breach")
    shutil.rmtree(breach, ignore_errors=True)
    copytree(os.path.join(CW, "sounds", "breach"), breach)

    civ = os.path.join(NBC, "sprites", "civilians")
    shutil.rmtree(civ, ignore_errors=True)
    copytree(os.path.join(SRC, "Civilians2", "sprites"), civ, skip=("PGIB*",))   # gibs duplicate the enemy pack's
    for f in os.listdir(civ):                       # "PEM7A2A8 (2).PNG" is the only copy of that frame
        fixed = re.sub(r"\s*\(\d+\)", "", f)
        if fixed != f and not os.path.exists(os.path.join(civ, fixed)):
            os.rename(os.path.join(civ, f), os.path.join(civ, fixed))

    for src, dst in KIT_MAPS.items():
        rename_map(os.path.join(CW, "maps", src + ".wad"), os.path.join(NBC, "maps", dst + ".wad"), dst)

    # Voxel cars: plain DECORATE, no Corpo Wars code. Loaded now.
    shutil.copy2(os.path.join(CW, "decorate.vehicles.txt"), os.path.join(NBC, "actors", "cw", "vehicles.txt"))
    print("Corpo Wars import done")


if __name__ == "__main__":
    main()
