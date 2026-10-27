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

Strips are WALL units thick. An edge longer than 96 is cut into three: two side pieces and a DOOR-wide middle
piece, which is where doors and windows go. The grid sizes below must match each kit's Setup().

Scale (PLAN.md §4.4): a person is 56 units tall (1.8 m), so a metre is about 31 units up and, with Doom's
1.2 vertical stretch, about 37 units across. Doors are 48 wide (radius-20 actors need 40).
"""
import os
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "nbc", "maps")
WALL = 16
DOOR = 48           # the doorway piece of a strip
VIEW = 384          # how far the view band reaches past the grid

# name: (column widths west->east, row heights south->north). Keep in sync with the kits' Setup().
GRIDS = {
    # tower floor: stair cores at both ends (4.7 m), 12 flat bays (3.9 m); rows: south window rooms (3.9 m),
    # south inner rooms (3 m), corridor (2.2 m), north inner rooms, north window rooms
    "NBC_KT": ([176] + [144] * 12 + [176], [144, 112, 80, 112, 144]),
    # street: cross street, sidewalk, 12 lots, side passage; rows: road, sidewalk, 4 lot rows, alley, the Wall
    "NBC_KS": ([224, 112] + [176] * 12 + [128], [256, 128, 176, 176, 176, 176, 128, 160]),
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


def template(colw, rowh):
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

    # the view band: an outer box with the grid's outline as a hole
    X, Y = cx[-1] + colw[-1], cy[-1] + rowh[-1]
    xs = sorted({v for i in range(nx) for v in (cx[i], cx[i] + colw[i])})
    ys = sorted({v for j in range(ny) for v in (cy[j], cy[j] + rowh[j])})
    hole = [(x, 0) for x in xs] + [(X, y) for y in ys[1:]] + [(x, Y) for x in reversed(xs[:-1])] + [(0, y) for y in reversed(ys[1:-1])]
    outer = clockwise(rect(-VIEW, -VIEW, X + 2 * VIEW, Y + 2 * VIEW))
    sectors.append(([outer, hole], dict(floor=-768, ceil=1024, ftex="ADFCITY", ctex="F_SKY1", light=144, tag=12000)))
    blocking = {frozenset((hole[k], hole[(k + 1) % len(hole)])) for k in range(len(hole))}
    start = (cx[0] + colw[0] // 2, cy[0] + rowh[0] // 2)
    return sectors, blocking, start


def udmf(sectors, blocking, start):
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
        if len(uses) == 1:
            sides.append(dict(sector=s, texturemiddle="CWCONCW"))
            lines.append(dict(v1=v(a), v2=v(b), sidefront=len(sides) - 1, blocking=True))
        else:
            sides.append(dict(sector=s, texturetop="CWCONCW", texturebottom="CWCONCW"))
            sides.append(dict(sector=uses[1][2], texturetop="CWCONCW", texturebottom="CWCONCW"))
            ln = dict(v1=v(a), v2=v(b), sidefront=len(sides) - 2, sideback=len(sides) - 1, twosided=True)
            if key in blocking:
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
        sectors, blocking, start = template(colw, rowh)
        path = os.path.join(OUT, name + ".wad")
        write_wad(path, name, udmf(sectors, blocking, start))
        print("%s: %d x %d cells, %d sectors -> %s" % (name, len(colw), len(rowh), len(sectors), os.path.relpath(path, ROOT)))
