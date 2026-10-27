"""Static checks on nbc/ that catch most "it loads but shows ?" and "wrong sound" problems.

Checks:
  1. duplicate lump names inside a namespace (sprites, sounds, textures, voxels, ...)
  2. sprite or sound files whose names are too long to be lumps
  3. SNDINFO entries that point at sound lumps that don't exist (in nbc/, the IWAD or uzdoom.pk3)
  4. actor classes defined twice (DECORATE + ZScript, case-insensitive)
  5. DoomEdNums used twice (DECORATE headers + MAPINFO DoomEdNums)
  6. sprite names used in DECORATE/ZScript states that exist nowhere

Known, accepted problems live in tools/lumps_allow.txt (one "check: key" per line, # comments).
They're printed as "known" and don't fail the run. Exit code 1 on any new problem.

    python tools/check_lumps.py            # check
    python tools/check_lumps.py --verbose  # also list the known problems
"""
import argparse
import collections
import os
import re
import struct
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NBC = os.path.join(ROOT, "nbc")
IWAD = os.path.join(ROOT, "freedoom-0.13.0", "freedoom2.wad")
ENGINE_PK3 = os.path.join(ROOT, "uzdoom.pk3")
ALLOW = os.path.join(ROOT, "tools", "lumps_allow.txt")
NAMESPACES = ("sprites", "sounds", "textures", "flats", "patches", "graphics", "voxels", "music")
SKIP_SPRITES = {"TNT1", "####", "----"}


def short(name):
    return os.path.basename(name).split(".")[0].upper()


def nbc_files():
    for d, dirs, fs in os.walk(NBC):
        for f in fs:
            full = os.path.join(d, f)
            yield os.path.relpath(full, NBC).replace(os.sep, "/"), full


def wad_lumps(path):
    """(namespace, name) pairs from a WAD, namespace from S_/F_/P_ markers."""
    if not os.path.exists(path):
        return []
    data = open(path, "rb").read()
    _, count, offset = struct.unpack("<4sii", data[:12])
    ns, out = "", []
    for i in range(count):
        name = data[offset + 16 * i + 8:offset + 16 * i + 16].rstrip(b"\0").decode("ascii", "replace").upper()
        if name in ("S_START", "SS_START"):
            ns = "sprites"
        elif name in ("F_START", "FF_START"):
            ns = "flats"
        elif name in ("P_START", "PP_START"):
            ns = "patches"
        elif name.endswith("_END"):
            ns = ""
        else:
            out.append((ns, name))
    return out


def engine_lumps():
    out = []
    if os.path.exists(ENGINE_PK3):
        with zipfile.ZipFile(ENGINE_PK3) as z:
            for n in z.namelist():
                if not n.endswith("/"):
                    top = n.split("/")[0].lower() if "/" in n else ""
                    out.append((top, short(n)))
    return out


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    allow = set()
    if os.path.exists(ALLOW):
        for line in open(ALLOW, encoding="utf-8"):
            line = line.split("#", 1)[0].strip()
            if line:
                allow.add(line.lower())

    problems = collections.defaultdict(list)   # check -> [(key, message)]

    # ---- 1/2: namespaces in nbc/
    by_ns = collections.defaultdict(lambda: collections.defaultdict(list))
    defs = collections.defaultdict(list)       # DECORATE / ZSCRIPT / SNDINFO / MAPINFO texts
    for rel, full in nbc_files():
        parts = rel.split("/")
        top = parts[0].lower()
        if len(parts) > 1 and top in NAMESPACES:
            name = short(rel)
            if top in ("sprites", "sounds") and len(name) > 8:
                problems["longname"].append((rel.lower(), f"{rel}: name longer than 8 characters, not usable as a lump"))
            by_ns[top][name].append(rel)
        if len(parts) == 1 or top in ("actors", "zscript"):
            kind = short(rel)
            if top == "actors" or kind == "DECORATE":
                defs["DECORATE"].append(full)
            elif top == "zscript" or kind == "ZSCRIPT":
                defs["ZSCRIPT"].append(full)
            elif kind in ("SNDINFO", "MAPINFO", "TEXTURES"):
                defs[kind].append(full)
    for ns, names in by_ns.items():
        for name, paths in names.items():
            if len(paths) > 1:
                problems["dup"].append((f"{ns}/{name}".lower(), f"{ns}/{name} defined {len(paths)} times: " + ", ".join(paths)))
    # a voxel named like a sprite frame silently replaces that sprite in the game
    for name in set(by_ns.get("voxels", {})) & set(by_ns.get("sprites", {})):
        problems["dup"].append((f"voxel/{name}".lower(), f"voxel {name} would replace sprite frame {name}: "
                                + ", ".join(by_ns["voxels"][name] + by_ns["sprites"][name])))

    # ---- 3: SNDINFO targets
    available = {name for names in by_ns.values() for name in names}
    available |= {n for _, n in wad_lumps(IWAD)} | {n for _, n in engine_lumps()}
    for path in defs["SNDINFO"]:
        for lineno, line in enumerate(open(path, encoding="latin1"), 1):
            line = strip_comments(line).strip()
            if not line or line.startswith("$") or line.startswith("{") or line.startswith("}"):
                if line.lower().startswith("$playersound"):
                    toks = line.split()
                    if len(toks) >= 5:
                        target = toks[4]
                    else:
                        continue
                else:
                    continue
            else:
                toks = line.split()
                if len(toks) < 2:
                    continue
                target = toks[1]
            target = target.strip('"')
            if "/" in target:
                ok = os.path.exists(os.path.join(NBC, target))
            else:
                ok = target.upper() in available
            if not ok:
                rel = os.path.relpath(path, NBC)
                problems["sndinfo"].append((f"sndinfo:{target}".lower(), f"{rel}:{lineno}: sound lump '{target}' not found"))

    # ---- 4/5/6: classes, DoomEdNums, sprites
    classes = collections.defaultdict(list)
    ednums = collections.defaultdict(list)
    used_sprites = collections.defaultdict(set)
    sprite_names = {n[:4] for n in by_ns.get("sprites", {})} | {n[:4] for n in by_ns.get("voxels", {})}
    sprite_names |= {n[:4] for ns, n in wad_lumps(IWAD) if ns == "sprites"}
    sprite_names |= {n[:4] for ns, n in engine_lumps() if ns == "sprites"}
    for path in defs["TEXTURES"]:
        sprite_names |= {m.upper()[:4] for m in re.findall(r'^\s*Sprite\s+"?(\w+)', open(path, encoding="latin1").read(), re.M | re.I)}

    state_line = re.compile(r'^\s*"?([A-Za-z0-9_#\-]{4})"?\s+"?[A-Za-z\[\]\\#\^]+"?\s+-?\d', re.M)
    for kind in ("DECORATE", "ZSCRIPT"):
        for path in defs[kind]:
            text = strip_comments(open(path, encoding="latin1").read())
            rel = os.path.relpath(path, NBC).replace(os.sep, "/")
            if kind == "DECORATE":
                for m in re.finditer(r"^\s*actor\s+([^\s:{]+)([^{\n]*)", text, re.M | re.I):
                    classes[m.group(1).lower()].append(rel)
                    num = re.search(r"\b(\d+)\s*$", m.group(2).strip())
                    if num:
                        ednums[int(num.group(1))].append(f"{m.group(1)} ({rel})")
            else:
                for m in re.finditer(r"^\s*class\s+(\w+)", text, re.M | re.I):
                    classes[m.group(1).lower()].append(rel)
            for m in state_line.finditer(text):
                spr = m.group(1).upper()
                if spr not in SKIP_SPRITES and not spr.lower() in ("goto", "stop", "loop", "wait", "fail"):
                    used_sprites[spr].add(rel)
    for path in defs["MAPINFO"]:
        text = strip_comments(open(path, encoding="latin1").read())
        for block in re.findall(r"DoomEdNums\s*\{(.*?)\}", text, re.S | re.I):
            for num, cls in re.findall(r"(\d+)\s*=\s*\"?(\w+)", block):
                ednums[int(num)].append(f"{cls} (MAPINFO)")
    for name, where in classes.items():
        if len(where) > 1:
            problems["class"].append((f"class:{name}", f"class {name} defined {len(where)} times: " + ", ".join(where)))
    for num, where in ednums.items():
        if len(where) > 1:
            problems["ednum"].append((f"ednum:{num}", f"DoomEdNum {num} used by: " + ", ".join(where)))
    for spr, where in sorted(used_sprites.items()):
        if spr not in sprite_names:
            problems["sprite"].append((f"sprite:{spr}".lower(), f"sprite {spr} used in {', '.join(sorted(where))} but no {spr}* lump exists"))

    # ---- report
    new = known = 0
    for check in ("dup", "longname", "sndinfo", "class", "ednum", "sprite"):
        for key, msg in sorted(problems.get(check, [])):
            if key in allow or f"{check}:{key}" in allow:
                known += 1
                if args.verbose:
                    print(f"  known  [{check}] {msg}")
            else:
                new += 1
                print(f"  NEW    [{check}] {msg}")
    print(f"check_lumps: {new} new problem(s), {known} known (tools/lumps_allow.txt)")
    sys.exit(1 if new else 0)


if __name__ == "__main__":
    main()
