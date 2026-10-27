"""ONE-TIME import (milestone M0, run 2026-10-26): DeePaybackEnemies/ and Weapons/*.zip -> nbc/.

Kept as a record of exactly where every imported file came from. Re-running it rebuilds the
imported folders AND regenerates the root DECORATE, ZSCRIPT.zs, SNDINFO.txt, GLDEFS.txt and
CREDITS.txt, wiping any hand edits made to those since. Don't re-run it after M1 has started.

    python tools/import/import_packs.py
"""
import io
import os
import re
import shutil
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NBC = os.path.join(ROOT, "nbc")
REF = os.path.join(ROOT, "reference", "weapons")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from extract_wad import read_lumps  # noqa: E402

# pack name -> how it's used. "reference" packs keep sprites and sounds but their code isn't loaded.
WEAPON_PACKS = {
    "AK47": "active", "Colt45": "active", "CombatKnife": "active", "DualBerettas": "active",
    "FistsOfFury": "active", "Flashlight": "active", "Machete": "active", "MicroUzi": "active",
    "Molotov": "active", "PumpActionShotgun": "active",
    "FragGrenade": "reference",   # code retired; sprites/sounds feed the M1c debris throw
}
DEF_NAMES = {"DECORATE", "ZSCRIPT", "SNDINFO", "GLDEFS", "TEXTURES", "KEYCONF"}
DOC_NAMES = {"CREDITS", "INFO", "OLDCODE", "OLDGLDEFS", "UPDATES"}

decorate, zscript, sndinfo, gldefs, credits = [], [], [], [], []


def lump_name(path):
    return os.path.basename(path).split(".")[0].upper()


def write(path, blob):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(blob)


def text(blob):
    return blob.decode("latin1").replace("\r\n", "\n")


def section(title, body):
    return f"// ===== {title} =====\n{body.rstrip()}\n"


def reset(*parts):
    path = os.path.join(NBC, *parts)
    shutil.rmtree(path, ignore_errors=True)
    os.makedirs(path, exist_ok=True)


def import_enemies():
    src = os.path.join(ROOT, "DeePaybackEnemies")
    for sub, dst in (("sprites", ("sprites", "enemies")), ("sounds", ("sounds", "enemies"))):
        shutil.copytree(os.path.join(src, sub), os.path.join(NBC, *dst), dirs_exist_ok=True)
    for name in os.listdir(os.path.join(src, "actors")):
        shutil.copy2(os.path.join(src, "actors", name), os.path.join(NBC, "actors", "enemies", name))
    dec = open(os.path.join(src, "DECORATE.lmp"), encoding="latin1").read()
    dec = re.sub(r'#include\s+"actors/', '#include "actors/enemies/', dec, flags=re.I)
    write(os.path.join(NBC, "actors", "enemies", "decorate.txt"), dec.encode("latin1"))
    decorate.append('#include "actors/enemies/decorate.txt"   // DeePayback Enemies (DeeDeeOZ)')
    sndinfo.append(section("DeePayback Enemies", open(os.path.join(src, "SNDINFO.lmp"), encoding="latin1").read()))
    credits.append(section("DeePayback Enemies by DeeDeeOZ (credits.txt, unchanged)",
                           open(os.path.join(src, "credits.txt"), encoding="latin1").read()))
    # The pack ships some voice files twice in different folders (byte-identical). Two lumps with one
    # name is ambiguous for SNDINFO, so keep the first copy only.
    seen = {}
    for d, _, fs in sorted(os.walk(os.path.join(NBC, "sounds", "enemies"))):
        for f in sorted(fs):
            p = os.path.join(d, f)
            name = lump_name(f)
            if name in seen and open(seen[name], "rb").read() == open(p, "rb").read():
                os.remove(p)
            else:
                seen.setdefault(name, p)


def entries_of(pack_path):
    """Yield (relative path, data) for a pk3 or (pseudo-path, data) for a wad."""
    if pack_path.lower().endswith(".pk3"):
        with zipfile.ZipFile(pack_path) as z:
            for info in z.infolist():
                if not info.is_dir():
                    yield info.filename, z.read(info)
        return
    section_dir = ""
    for name, blob in read_lumps(pack_path):
        upper = name.upper()
        if upper in ("S_START", "SS_START"):
            section_dir = "sprites/"
            continue
        if upper in ("S_END", "SS_END"):
            section_dir = ""
            continue
        if not section_dir and upper not in DEF_NAMES | DOC_NAMES:
            yield "sounds/" + name, blob  # loose lumps in these WADs are all sounds
        else:
            yield section_dir + name, blob


def import_weapon(pack, use):
    zpath = os.path.join(ROOT, "Weapons", pack + ".zip")
    with zipfile.ZipFile(zpath) as z:
        inner = z.namelist()[0]
        tmp = os.path.join(ROOT, "build", "import", inner)
        write(tmp, z.read(inner))
    key = pack.lower()
    files = dict(entries_of(tmp))
    actor_dir = os.path.join(NBC, "actors", "weapons", key)
    ref_dir = os.path.join(REF, key)
    defs = {}
    for rel, blob in files.items():
        parts = rel.split("/")
        top = parts[0].lower()
        if len(parts) > 2 and top in ("sprites", "sounds") and parts[1].lower() == key:
            parts = [parts[0]] + parts[2:]          # sprites/colt45/X -> sprites/weapons/colt45/X, not .../colt45/colt45/X
        if len(parts) == 1:
            defs.setdefault(lump_name(rel), []).append((rel, blob))
        elif top == "sprites":
            write(os.path.join(NBC, "sprites", "weapons", key, *parts[1:]), blob)
        elif top == "sounds":
            write(os.path.join(NBC, "sounds", "weapons", key, *parts[1:]), blob)
        elif top in ("brightmaps", "graphics"):
            write(os.path.join(NBC, *[p.lower() if i < len(parts) - 1 else p for i, p in enumerate(parts)]), blob)
        elif top == "actors":
            write(os.path.join(actor_dir, *parts[1:]), blob)
        else:
            write(os.path.join(ref_dir, *parts), blob)

    for name, items in defs.items():
        for rel, blob in items:
            if name in DOC_NAMES:
                write(os.path.join(ref_dir, rel), blob)
                if name == "CREDITS":
                    credits.append(section(f"{pack} (weapon pack, Weapons/{pack}.zip)", text(blob)))
            elif name == "KEYCONF" or use == "reference" and name in ("DECORATE", "GLDEFS"):
                write(os.path.join(ref_dir, rel), blob)
            elif name == "DECORATE":
                body = re.sub(r"#include\s+\"?([^\"\n]+)\"?",
                              lambda m: f'#include "actors/weapons/{key}/' + m.group(1).split("/", 1)[-1].strip() + '"',
                              text(blob), flags=re.I)
                write(os.path.join(actor_dir, "decorate.txt"), body.encode("latin1"))
                decorate.append(f'#include "actors/weapons/{key}/decorate.txt"')
            elif name == "ZSCRIPT":
                write(os.path.join(NBC, "zscript", "imported", key + ".zs"), blob)
                zscript.append(f'#include "zscript/imported/{key}.zs"')
            elif name == "SNDINFO":
                sndinfo.append(section(f"{pack} (Weapons/{pack}.zip)", text(blob)))
            elif name == "GLDEFS":
                gldefs.append(section(f"{pack} (Weapons/{pack}.zip)", text(blob)))
            elif name == "TEXTURES":
                write(os.path.join(NBC, f"TEXTURES.{key}.txt"), blob)


def main():
    for parts in (("actors", "enemies"), ("actors", "weapons"), ("sprites", "enemies"), ("sprites", "weapons"),
                  ("sounds", "enemies"), ("sounds", "weapons"), ("zscript", "imported"), ("brightmaps",),
                  ("graphics", "brightmaps")):
        reset(*parts)
    shutil.rmtree(REF, ignore_errors=True)
    for name in os.listdir(NBC):
        if name.upper().startswith("TEXTURES."):
            os.remove(os.path.join(NBC, name))

    import_enemies()
    for pack, use in WEAPON_PACKS.items():
        import_weapon(pack, use)

    header = "// Generated by tools/import/import_packs.py (M0). Edit by hand from M1 on.\n"
    write(os.path.join(NBC, "DECORATE"), (header + "\n".join(decorate) +
          '\n#include "actors/cw/decorate.txt"   // Corpo Wars imports (M0b)\n').encode("latin1"))
    write(os.path.join(NBC, "ZSCRIPT.zs"), ('version "4.10"\n' + header + "\n// Imported weapon code\n" +
          "\n".join(zscript) + "\n\n// New Bricks City code goes in zscript/nbc/ and is included below\n").encode("latin1"))
    write(os.path.join(NBC, "SNDINFO.txt"), (header + "\n".join(sndinfo)).encode("latin1"))
    write(os.path.join(NBC, "GLDEFS.txt"), (header + "\n".join(gldefs)).encode("latin1"))
    write(os.path.join(ROOT, "build", "import", "credits_packs.txt"), "\n".join(credits).encode("latin1"))
    print("imported enemies +", len(WEAPON_PACKS), "weapon packs")


if __name__ == "__main__":
    main()
