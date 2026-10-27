"""Inspect an Obsidian output WAD (UDMF maps): texture statistics and a top-down PNG per map.

    python tools/Obsidian/inspect_udmf.py tools/Obsidian/out/bricks.wad
Prints, per map, how much of the texturing comes from nbc/textures and which other textures
are left. Writes <wad>_<MAP>.png: solid walls in tan (magenta if not from nbc/textures), height changes in grey.
"""
import collections
import os
import re
import struct
import sys

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NBC_TEX = os.path.join(ROOT, "nbc", "textures")
KEEP = {"-", "F_SKY1"}


def lumps(path):
    data = open(path, "rb").read()
    _, n, off = struct.unpack("<4sii", data[:12])
    for i in range(n):
        pos, size, name = struct.unpack("<ii8s", data[off + 16 * i:off + 16 * i + 16])
        yield name.rstrip(b"\0").decode(), data[pos:pos + size]


def blocks(text, kind):
    for m in re.finditer(kind + r"\s*\{([^}]*)\}", text):
        fields = {}
        for k, v in re.findall(r"(\w+)\s*=\s*([^;]+);", m.group(1)):
            fields[k] = v.strip().strip('"')
        yield fields


def main(path):
    ours = {}
    for d, _, fs in os.walk(NBC_TEX):
        for f in fs:
            ours[f.split(".")[0].upper()] = os.path.join(d, f)
    colour_cache = {}

    def colour(name):
        if name not in colour_cache:
            p = ours.get(name)
            colour_cache[name] = (Image.open(p).convert("RGB").resize((1, 1)).getpixel((0, 0))
                                  if p else (220, 50, 220))
        return colour_cache[name]

    cur = None
    for name, blob in lumps(path):
        if re.match(r"^MAP\d\d$", name):
            cur = name
            continue
        if name != "TEXTMAP" or not cur:
            continue
        text = blob.decode("latin1")
        verts = [(float(v["x"]), float(v["y"])) for v in blocks(text, "vertex")]
        sides = list(blocks(text, "sidedef"))
        secs = list(blocks(text, "sector"))
        lines = list(blocks(text, "linedef"))
        things = list(blocks(text, "thing"))

        walls, flats = collections.Counter(), collections.Counter()
        for s in sides:
            for k in ("texturetop", "texturebottom", "texturemiddle"):
                if k in s:
                    walls[s[k].upper()] += 1
        for s in secs:
            for k in ("texturefloor", "textureceiling"):
                flats[s.get(k, "-").upper()] += 1

        def report(counter, label):
            total = sum(c for t, c in counter.items() if t not in KEEP)
            mine = sum(c for t, c in counter.items() if t in ours)
            other = [f"{t}:{c}" for t, c in counter.most_common() if t not in ours and t not in KEEP][:15]
            print(f"   {label} {mine}/{total} from nbc ({100 * mine // max(total, 1)}%)  other: {' '.join(other)}")

        print(f"{cur}: {len(secs)} sectors, {len(lines)} lines, {len(things)} things")
        report(walls, "walls")
        report(flats, "flats")

        # crop stray far-away vertices (skybox, limits) to the 1st-99th percentile
        xs = sorted(v[0] for v in verts)
        ys = sorted(v[1] for v in verts)
        q = lambda a, f: a[min(len(a) - 1, int(len(a) * f))]
        minx, maxx, miny, maxy = q(xs, 0.01), q(xs, 0.99), q(ys, 0.01), q(ys, 0.99)
        scale = 1000 / max(maxx - minx, maxy - miny, 1)
        img = Image.new("RGB", (int((maxx - minx) * scale) + 20, int((maxy - miny) * scale) + 20), (14, 14, 18))
        dr = ImageDraw.Draw(img)
        P = lambda v: (10 + (v[0] - minx) * scale, 10 + (maxy - v[1]) * scale)
        for l in lines:
            a, b = verts[int(l["v1"])], verts[int(l["v2"])]
            front = sides[int(l["sidefront"])]
            if "sideback" not in l:
                tex = front.get("texturemiddle", "-").upper()
                dr.line([P(a), P(b)], fill=(230, 200, 150) if tex in ours else (220, 50, 220), width=2)
            else:
                f = secs[int(front["sector"])]
                bk = secs[int(sides[int(l["sideback"])]["sector"])]
                if f.get("heightfloor") != bk.get("heightfloor"):
                    dr.line([P(a), P(b)], fill=(85, 85, 105), width=1)
        img.save(os.path.splitext(path)[0] + f"_{cur}.png")


if __name__ == "__main__":
    main(sys.argv[1])
