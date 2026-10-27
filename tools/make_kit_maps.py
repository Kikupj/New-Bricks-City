"""Build the blank kit template maps for the Bricks kits (PLAN.md §4.4, M2c).

    python tools/make_kit_maps.py            # writes nbc/maps/NBC_KT.wad, NBC_KS.wad, NBC_KB.wad, NBC_KR.wad

A template is a grid of cells. Nothing is open when the map loads: every cell, wall strip and corner post
starts closed (floor = ceiling = 0), and the kit generator (nbc/zscript/cw/kitgen.zs + a kit in
nbc/zscript/nbc/kit_*.zs) moves the planes at run time to carve that floor's rooms. The tags are the
contract between this file and NBC_KitGen:

    cell (i, j)                                    tag  7000 + j*NX + i
    vertical strip between (i, j) and (i+1, j)     tag  1000 + (j*(NX-1) + i)*3 + k   (k: side, 64u door, side)
    horizontal strip between (i, j) and (i, j+1)   tag  4000 + (j*NX + i)*3 + k
    corner post between (i, j) and (i+1, j+1)      tag 11000 + j*(NX-1) + i
    the view band round the grid                   tag 12000 (blocking lines on its inner edge)

Past the band, the street, tower and roof templates carry fixed scenery (SCENERY below): a gravel ground plane,
a canal with embankment walls, a high retaining wall, and tower blocks as real raised rectangles at three
distances, faced with lit-window and glass-tower textures, so the city has depth and parallax. The world's
edge is a sealed ring with a sky ceiling (the classic sky hack), so the horizon is sky, not a wall.

Strips are WALL units thick. An edge longer than 96 is cut into three: two side pieces and a DOOR-wide middle
piece, which is where doors and windows go. The grid sizes below must match each kit's Setup().

Scale (PLAN.md §4.4): a person is 56 units tall (1.8 m), so a metre is about 31 units up and, with Doom's
1.2 vertical stretch, about 37 units across. Doors are 48 wide (radius-20 actors need 40).
"""
import os
import random
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "nbc", "maps")
WALL = 16
DOOR = 48           # the doorway piece of a strip
VIEW = 384          # how far the plain view band reaches past the grid (templates without scenery)
BAND = 64           # with scenery: the kit-painted ring round the grid
REACH = 3200        # with scenery: how far the world reaches past the grid

# per template: ground height (the street is 0; seen from a tower or a roof it's 768 below), the canal, the
# retaining wall, tower heights above the ground per distance tier, and the layout seed
SCENERY = {
    "NBC_KS": dict(z=0, canal=True, wall=True, seed=11, tiers=[(380, 760), (560, 1100), (820, 1700)]),
    "NBC_KT": dict(z=-768, canal=True, wall=False, seed=37, tiers=[(420, 980), (620, 1400), (900, 2000)]),
    "NBC_KR": dict(z=-768, canal=True, wall=False, seed=23, tiers=[(360, 980), (600, 1400), (900, 2100)]),
}
# NBC: the facade art has a storey every 32 texels; at this scale a storey is 80 units (2.6 m), right for a
# 56-unit person (window facades only: plain brick keeps its scale)
FACADE_SCALE = 0.4
FACADES = ["CWNRESA", "CWNRESB", "CWNRESC", "CWNRESA", "CWNRESB", "CWNTOWA", "CWNTOWB", "CWNTOWC", "CWNTOWD", "CWNINDA"]

# name: (column widths west->east, row heights south->north). Keep in sync with the kits' Setup().
GRIDS = {
    # tower floor: stair cores at both ends (4.7 m), 12 flat bays (3.9 m); rows: south window rooms (3.9 m),
    # south inner rooms (3 m), corridor (2.2 m), north inner rooms, north window rooms
    "NBC_KT": ([176] + [144] * 12 + [176], [144, 112, 80, 112, 144]),
    # street, two-sided: cross street, sidewalk, 12 lots, side passage; rows: the canal walk, south back rooms,
    # south shops, south sidewalk, road, north sidewalk, 4 north lot rows, the north alley, the Wall
    "NBC_KS": ([224, 112] + [176] * 12 + [128], [128, 176, 176, 112, 256, 128, 176, 176, 176, 176, 128, 160]),
    # basement: a 16 x 12 grid of 128 cells
    "NBC_KB": ([128] * 16, [128] * 12),
    # roofs: 14 x 9 cells of 160
    "NBC_KR": ([160] * 14, [160] * 9),
}


def edge_cuts(length):
    """(start, end, k) pieces of a wall strip along an edge of this length."""
    if length > 96:
        a = (length - DOOR) // 2
        return [(0, a, 0), (a, a + DOOR, 1), (a + DOOR, length, 2)]
    return [(0, length, 1)]


def clockwise(loop):
    area = sum(loop[k][0] * loop[(k + 1) % len(loop)][1] - loop[(k + 1) % len(loop)][0] * loop[k][1] for k in range(len(loop)))
    return loop if area < 0 else list(reversed(loop))


def rect(x, y, w, h):
    return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]


def overlaps(a, b, pad):
    return not (a[2] + pad <= b[0] or b[2] + pad <= a[0] or a[3] + pad <= b[1] or b[3] + pad <= a[1])


LOW_FACADES = ["CWNRESA", "CWNRESB", "CWNRESC", "BRICK12", "BIGBRIK1", "CWWALLD", "CWNRESB", "STUCCO1"]


def low_row(rnd, sectors, holes, avoid, edge_tex, edge_light, z, sky, a0, a1, b0, b1, along_x):
    """A continuous row of low buildings (3-6 storeys) across [a0, a1] deep and from b0 to b1 along the row.
    Neighbouring blocks share their side walls exactly, so the row has no gaps."""
    b = b0
    while b < b1 - 64:
        w = min(rnd.randint(12, 24) * 16, b1 - b)
        if b1 - (b + w) < 128:
            w = b1 - b
        loop = clockwise(rect(b, a0, w, a1 - a0) if along_x else rect(a0, b, a1 - a0, w))
        h = rnd.randint(32, 60) * 8
        sectors.append(([loop], dict(floor=z + h, ceil=sky, ftex="FLAT5_5", ctex="F_SKY1", light=112, tag=0)))
        holes.append(loop)
        tex, light = rnd.choice(LOW_FACADES), rnd.randint(0, 32)
        for k in range(4):
            key = frozenset((loop[k], loop[(k + 1) % 4]))
            edge_tex[key] = (tex, FACADE_SCALE if tex.startswith("CWN") else 1.0)
            edge_light[key] = light
        b += w
    avoid.append((b0, a0, b1, a1) if along_x else (a0, b0, a1, b1))


def scenery(name, X, Y, hole, sectors, edge_tex, edge_light, edge_mid, things):
    """The world past the grid: band ring, canal, retaining wall, towers, ground, the sky-hack horizon."""
    cfg = SCENERY[name]
    rnd = random.Random(cfg["seed"])
    z, sky = cfg["z"], cfg["z"] + 2800
    M, R = BAND, REACH
    ring = clockwise(rect(-M, -M, X + 2 * M, Y + 2 * M))
    sectors.append(([ring, hole], dict(floor=z, ceil=sky, ftex="CWPAVE", ctex="F_SKY1", light=128, tag=12000)))
    holes, avoid = [ring], [(-M - 96, -M - 96, X + M + 96, Y + M + 96)]
    if cfg["canal"]:
        # an L of water along the south and the west: a stone quay ledge on the near side 56 down, the water 112
        # down, seawalls, a road bridge carrying the cross street (x 0-224) over the south arm, lamps on the far bank
        i0, w, q = M + 32, 352, 48
        xe, yn = X + R - 420, Y + R - 420
        bx0, bx1 = 0, 224
        wat = dict(floor=z - 112, ceil=sky, ftex="CWWATER", ctex="F_SKY1", light=120, tag=0)
        quay = dict(floor=z - 56, ceil=sky, ftex="CWCONCF", ctex="F_SKY1", light=120, tag=0)
        deck = dict(floor=z, ceil=sky, ftex="CWASPH", ctex="F_SKY1", light=128, tag=0)
        pieces = [
            (rect(-i0 - w, -i0 - w, w - q, yn + i0 + w), wat),             # the west arm and the corner
            (rect(-i0 - q, -i0 - w, bx0 + i0 + q, w - q), wat),            # the south arm west of the bridge
            (rect(bx1, -i0 - w, xe - bx1, w - q), wat),                    # and east of it
            (rect(-i0 - q, -i0 - q, q, yn + i0 + q), quay),                # the quay along the west arm and the corner
            (rect(-i0, -i0 - q, bx0 + i0, q), quay),                       # the quay along the south arm
            (rect(bx1, -i0 - q, xe - bx1, q), quay),
            (rect(bx0, -i0 - w - 32, bx1 - bx0, w + 32), deck),            # the bridge
        ]
        for loop, props in pieces:
            loop = clockwise(loop)
            sectors.append(([loop], dict(props)))
            holes.append(loop)
            for k in range(4):
                key = frozenset((loop[k], loop[(k + 1) % 4]))
                if props is deck and loop[k][0] == loop[(k + 1) % 4][0]:
                    edge_mid[key] = "CWRAIL2"          # the bridge's railings, over the water
                else:
                    edge_tex.setdefault(key, ("CWSEAWAL", 1.0))
        avoid += [(-i0 - w, -i0 - w, xe, -i0), (-i0 - w, -i0 - w, -i0, yn)]
        # the far bank: a row of low buildings along both arms, so the ground plane never shows from the street;
        # a gap where the bridge lands
        bank = -i0 - w - 32
        d = 224
        low_row(rnd, sectors, holes, avoid, edge_tex, edge_light, z, sky, bank - d, bank, bank - d, bx0 - 64, True)  # south, west of the bridge
        low_row(rnd, sectors, holes, avoid, edge_tex, edge_light, z, sky, bank - d, bank, bx1 + 64, xe, True)       # and east of it
        low_row(rnd, sectors, holes, avoid, edge_tex, edge_light, z, sky, bank - d, bank, bank + 16, yn, False)   # west, south to north
        # lamps along the far bank
        for x in range(bank + 64, xe - 64, 384):
            things.append(dict(type=26233, x=float(x), y=float(bank + 16), angle=90))
            things.append(dict(type=9800, x=float(x), y=float(bank + 24), height=96.0, arg0=255, arg1=210, arg2=150, arg3=280))
        for y in range(bank + 400, yn - 64, 384):
            things.append(dict(type=26233, x=float(bank + 16), y=float(y), angle=0))
            things.append(dict(type=9800, x=float(bank + 24), y=float(y), height=96.0, arg0=255, arg1=210, arg2=150, arg3=280))
    if cfg["wall"]:
        # a high retaining wall closing off the east side
        x0 = X + M + 32
        wall = clockwise(rect(x0, -M - 16, 48, Y + R - 300))
        sectors.append(([wall], dict(floor=z + 224, ceil=sky, ftex="CWCONCF", ctex="F_SKY1", light=104, tag=0)))
        holes.append(wall)
        for k in range(4):
            edge_tex[frozenset((wall[k], wall[(k + 1) % 4]))] = ("CWRETAIN", 1.0)
        avoid.append((x0, -M - 16, x0 + 48, Y + R - 300 + -M - 16))
    # tower blocks in three tiers of distance from the band
    bounds = (-R + 200, -R + 200, X + R - 200, Y + R - 200)
    placed = []
    tiers = [(260, 900, 192, 384), (900, 1700, 256, 512), (1700, 2700, 320, 640)]
    for t, (d0, d1, w0, w1) in enumerate(tiers):
        h0, h1 = cfg["tiers"][t]
        for _ in range(900):
            if len([1 for p in placed if p[4] == t]) >= (26, 22, 18)[t]:
                break
            side = rnd.choice((0, 0, 1, 1, 2, 3))   # 0 south, 1 north, 2 west, 3 east (long sides twice as often)
            d = rnd.randint(d0, d1)
            bw, bd = rnd.randint(w0, w1) // 16 * 16, rnd.randint(w0, w1) // 16 * 16
            if side in (0, 1):
                x = rnd.randint(-R + 300, X + R - 300 - bw) // 16 * 16
                y = (-M - d - bd) if side == 0 else (Y + M + d)
                r = (x, y, x + bw, y + bd)
            else:
                y = rnd.randint(-R + 300, Y + R - 300 - bd) // 16 * 16
                x = (-M - d - bw) if side == 2 else (X + M + d)
                r = (x, y, x + bw, y + bd)
            if r[0] < bounds[0] or r[1] < bounds[1] or r[2] > bounds[2] or r[3] > bounds[3]:
                continue
            if any(overlaps(r, a, 48) for a in avoid) or any(overlaps(r, p, 40) for p in placed):
                continue
            placed.append(r + (t,))
            h = rnd.randint(h0, h1) // 8 * 8
            loop = clockwise(rect(r[0], r[1], bw, bd))
            sectors.append(([loop], dict(floor=z + h, ceil=sky, ftex="FLAT5_5", ctex="F_SKY1", light=112, tag=0)))
            holes.append(loop)
            tex, light = rnd.choice(FACADES), rnd.randint(8, 40)
            for k in range(4):
                key = frozenset((loop[k], loop[(k + 1) % 4]))
                edge_tex[key] = (tex, FACADE_SCALE if tex.startswith("CWN") else 1.0)
                edge_light[key] = light
    ground = clockwise(rect(-R + 48, -R + 48, X + 2 * R - 96, Y + 2 * R - 96))
    sectors.append(([ground] + holes[1:] + [ring], dict(floor=z, ceil=sky, ftex="CWASPH", ctex="F_SKY1", light=120, tag=0)))
    # the horizon: a sealed ring with a sky ceiling, so the sky shows where the world ends
    sectors.append(([clockwise(rect(-R, -R, X + 2 * R, Y + 2 * R)), ground], dict(floor=z, ceil=z, ftex="CWASPH", ctex="F_SKY1", light=104, tag=0)))
    return len(placed)


def template(name, colw, rowh):
    nx, ny = len(colw), len(rowh)
    cx = [sum(colw[:i]) + WALL * i for i in range(nx)]
    cy = [sum(rowh[:j]) + WALL * j for j in range(ny)]
    sectors = []   # (loops, props)

    def cuts_inside(length):
        c = edge_cuts(length)
        return [c[0][1], c[1][1]] if len(c) == 3 else []

    for j in range(ny):
        for i in range(nx):
            x0, y0 = cx[i], cy[j]
            x1, y1 = x0 + colw[i], y0 + rowh[j]
            vs, hs = cuts_inside(rowh[j]), cuts_inside(colw[i])
            # walk the cell's outline, adding the strip cut points on every side that has a strip
            loop = [(x0, y0)]
            if i > 0:
                loop += [(x0, y0 + v) for v in vs]
            loop.append((x0, y1))
            if j < ny - 1:
                loop += [(x0 + h, y1) for h in hs]
            loop.append((x1, y1))
            if i < nx - 1:
                loop += [(x1, y0 + v) for v in reversed(vs)]
            loop.append((x1, y0))
            if j > 0:
                loop += [(x0 + h, y0) for h in reversed(hs)]
            sectors.append(([clockwise(loop)], dict(floor=0, ceil=128, tag=7000 + j * nx + i)))
    for j in range(ny):
        for i in range(nx - 1):
            x0 = cx[i] + colw[i]
            for a, b, k in edge_cuts(rowh[j]):
                sectors.append(([clockwise(rect(x0, cy[j] + a, WALL, b - a))], dict(floor=0, ceil=0, tag=1000 + (j * (nx - 1) + i) * 3 + k)))
    for j in range(ny - 1):
        for i in range(nx):
            y0 = cy[j] + rowh[j]
            for a, b, k in edge_cuts(colw[i]):
                sectors.append(([clockwise(rect(cx[i] + a, y0, b - a, WALL))], dict(floor=0, ceil=0, tag=4000 + (j * nx + i) * 3 + k)))
    for j in range(ny - 1):
        for i in range(nx - 1):
            sectors.append(([clockwise(rect(cx[i] + colw[i], cy[j] + rowh[j], WALL, WALL))], dict(floor=0, ceil=0, tag=11000 + j * (nx - 1) + i)))

    # the view band round the grid: plain, or the ring of a world of scenery
    X, Y = cx[-1] + colw[-1], cy[-1] + rowh[-1]
    xs = sorted({v for i in range(nx) for v in (cx[i], cx[i] + colw[i])})
    ys = sorted({v for j in range(ny) for v in (cy[j], cy[j] + rowh[j])})
    hole = [(x, 0) for x in xs] + [(X, y) for y in ys[1:]] + [(x, Y) for x in reversed(xs[:-1])] + [(0, y) for y in reversed(ys[1:-1])]
    edge_tex, edge_light, edge_mid, things, towers = {}, {}, {}, [], 0
    if name in SCENERY:
        towers = scenery(name, X, Y, hole, sectors, edge_tex, edge_light, edge_mid, things)
    else:
        outer = clockwise(rect(-VIEW, -VIEW, X + 2 * VIEW, Y + 2 * VIEW))
        sectors.append(([outer, hole], dict(floor=-768, ceil=1024, ftex="ADFCITY", ctex="F_SKY1", light=144, tag=12000)))
    blocking = {frozenset((hole[k], hole[(k + 1) % len(hole)])) for k in range(len(hole))}
    start = (cx[0] + colw[0] // 2, cy[0] + rowh[0] // 2)
    return sectors, blocking, start, edge_tex, edge_light, edge_mid, things, towers


def split_tees(sectors):
    """Cut every axis-aligned loop edge at any vertex lying inside it, so pieces that meet part-way along a
    side (the canal's quay, water and bridge) share whole lines. Returns {piece: the whole edge it came from}."""
    parent = {}
    pts = {p for loops, _ in sectors for loop in loops for p in loop}
    by_x, by_y = {}, {}
    for x, y in pts:
        by_x.setdefault(x, []).append(y)
        by_y.setdefault(y, []).append(x)
    for loops, _ in sectors:
        for n, loop in enumerate(loops):
            out = []
            for k in range(len(loop)):
                a, b = loop[k], loop[(k + 1) % len(loop)]
                out.append(a)
                if a[0] == b[0]:
                    mids = sorted((y for y in by_x.get(a[0], []) if min(a[1], b[1]) < y < max(a[1], b[1])), reverse=a[1] > b[1])
                    out += [(a[0], y) for y in mids]
                    chain = [a] + [(a[0], y) for y in mids] + [b]
                elif a[1] == b[1]:
                    mids = sorted((x for x in by_y.get(a[1], []) if min(a[0], b[0]) < x < max(a[0], b[0])), reverse=a[0] > b[0])
                    out += [(x, a[1]) for x in mids]
                    chain = [a] + [(x, a[1]) for x in mids] + [b]
                else:
                    continue
                for c in range(len(chain) - 1):
                    parent[frozenset((chain[c], chain[c + 1]))] = frozenset((a, b))
            loops[n] = out
    return parent


def udmf(sectors, blocking, start, edge_tex, edge_light, edge_mid, things):
    parent = split_tees(sectors)
    verts, vid = [], {}

    def v(p):
        if p not in vid:
            vid[p] = len(verts)
            verts.append(p)
        return vid[p]

    edges = {}
    for s, (loops, _) in enumerate(sectors):
        for loop in loops:
            for k in range(len(loop)):
                a, b = loop[k], loop[(k + 1) % len(loop)]
                edges.setdefault(frozenset((a, b)), []).append((a, b, s))
    lines, sides = [], []
    for key, uses in edges.items():
        a, b, s = uses[0]
        whole = parent.get(key, key)
        if len(uses) == 1:
            sides.append(dict(sector=s, texturemiddle="CWCONCW"))
            lines.append(dict(v1=v(a), v2=v(b), sidefront=len(sides) - 1, blocking=True))
        else:
            tex, sc = edge_tex.get(key, edge_tex.get(whole, ("CWCONCW", 1.0)))
            for sec in (s, uses[1][2]):
                sd = dict(sector=sec, texturetop=tex, texturebottom=tex)
                if sc != 1.0:
                    sd.update(scalex_top=sc, scaley_top=sc, scalex_bottom=sc, scaley_bottom=sc)
                if whole in edge_mid:
                    sd["texturemiddle"] = edge_mid[whole]
                sides.append(sd)
            if whole in edge_light:
                sides[-2]["light"] = edge_light[whole]
                sides[-1]["light"] = edge_light[whole]
            ln = dict(v1=v(a), v2=v(b), sidefront=len(sides) - 2, sideback=len(sides) - 1, twosided=True)
            if whole in edge_mid:
                ln["dontpegbottom"] = True
            if whole in blocking:
                ln.update(blocking=True, blockmonsters=True)
            lines.append(ln)

    def block(kind, d):
        body = []
        for k, val in d.items():
            if isinstance(val, bool):
                val = "true" if val else "false"
            elif isinstance(val, str):
                val = '"%s"' % val
            body.append("%s = %s;" % (k, val))
        return "%s\n{\n%s\n}\n" % (kind, "\n".join(body))

    out = ['namespace = "zdoom";']
    out += [block("vertex", dict(x=float(x), y=float(y))) for x, y in verts]
    out += [block("linedef", l) for l in lines]
    out += [block("sidedef", s) for s in sides]
    for _, p in sectors:
        out.append(block("sector", dict(heightfloor=p["floor"], heightceiling=p["ceil"], texturefloor=p.get("ftex", "FLAT5_4"),
                                        textureceiling=p.get("ctex", "CEIL1_1"), lightlevel=p.get("light", 128), id=p["tag"])))
    out += [block("thing", dict(t, skill1=True, skill2=True, skill3=True, skill4=True, skill5=True, single=True)) for t in things]
    out.append(block("thing", dict(type=1, x=float(start[0]), y=float(start[1]), angle=90, skill1=True, skill2=True,
                                   skill3=True, skill4=True, skill5=True, single=True, coop=True, dm=True)))
    return "\n".join(out).encode()


def write_wad(path, name, textmap):
    lumps = [(name, b""), ("TEXTMAP", textmap), ("ENDMAP", b"")]
    data, entries, off = b"", [], 12
    for n, body in lumps:
        entries.append(struct.pack("<ii8s", off, len(body), n.encode()))
        data += body
        off += len(body)
    with open(path, "wb") as f:
        f.write(b"PWAD" + struct.pack("<ii", len(lumps), 12 + len(data)) + data + b"".join(entries))


if __name__ == "__main__":
    for name, (colw, rowh) in GRIDS.items():
        sectors, blocking, start, edge_tex, edge_light, edge_mid, things, towers = template(name, colw, rowh)
        path = os.path.join(OUT, name + ".wad")
        write_wad(path, name, udmf(sectors, blocking, start, edge_tex, edge_light, edge_mid, things))
        print("%s: %d x %d cells, %d sectors, %d towers -> %s" % (name, len(colw), len(rowh), len(sectors), towers, os.path.relpath(path, ROOT)))
