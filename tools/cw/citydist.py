# =============================================================================
# Corpo Wars - the five city districts (maps C01..C05), ROUND 3 (2x scale).
# ONE parameterised builder (build_district) driven by a profile dict per district. Called from genmap.py
# (genmap regenerates all maps; run with CW_MAPS_OUT=<temp dir> and copy back only C0*.wad).
#
# SCALE (32 units/m, player 56 = 1.75 m; the player, cars and NPCs are NOT scaled, the city is):
#   storey 128, sidewalk 112, side streets 512-640 (incl. sidewalks), avenues 704-832, perimeter 768-896,
#   lots 384-640, building frame (podium) 32 deep, ground floor = 128 (floor 8 -> 136), upper storeys 128 each.
#
# BUILDING = 3 sectors: FRAME (podium, floor 136, tag TAGF+id, has the door notch bitten out of its street face),
#            INNER (rises at runtime to 136 + 128*k, tag TAGI+id), NOTCH (door recess, tag TAGN+id).
#   The frame's outer face is exactly one storey (ground-floor texture), the inner face is k storeys (upper texture).
#   citygen.zs picks zone / height / kit per building from the campaign seed; this file only fixes the geometry.
#
# Around the grid: edge bands (water/harbour, canal, highway, rail viaduct, rail cutting, park) built in a local
# (u along the edge, v outward) frame, then GATEWAYS (tunnel mouth, bridge, highway ramp, metro stair) are carved
# through the edge bands. Everything walkable is low; beyond the barriers are filler blocks, then billboards, then sky.
# Output: <OUT>/C0n.wad and CorpoWars/citydist.txt (the building / gateway / profile table read by citygen.zs).
# =============================================================================
import os, struct, random
from collections import defaultdict
from bisect import bisect_left, bisect_right

STOREY, SWH, SW = 128, 8, 112
GND = SWH + STOREY                 # 136: top of the frame / ground floor
FR, ND, NW = 32, 24, 128           # frame depth, notch depth, notch width
CEIL = 9216                        # sky ceiling (taller than any building)
TAGF, TAGI, TAGN = 10000, 20000, 30000
EXT = 5600                         # how far the world extends beyond the district grid
SK = 256

# ------------------------------------------------------------------ district profiles
def streets(nb, per, side, av, av_at):
    return [per if k in (0, nb) else (av if k in av_at else side) for k in range(nb + 1)]

STYLE_NAMES = {'G': 'glass', 'E': 'campus', 'D': 'docks', 'Q': 'oldquarter', 'H': 'highline'}

PROFILES = {
 1: dict(code='MR', name='Meridian Row', style='G', rseed=101,
         nbx=8, nby=8, lw=512, lh=512, bl=2, bh=2,
         sx=streets(8, 896, 640, 832, (3, 5)), sy=streets(8, 896, 640, 832, (3, 5)),
         ring=dict(N=1, S=1, W=1, E=1), p_pair=0.22, p_vert=0.08, p_block=0.06,
         zw=dict(T=34, O=26, R=10, I=2, C=8, E=8), core=40,
         ht=dict(T=(8, 24), O=(5, 11), R=(3, 6), I=(2, 3), C=(3, 5), F=(4, 10)),
         edges=dict(N='highway', E='canal', S='park', W='cutting'),
         landmark=dict(bx=4, by=4, kind='hq', name='Meridian Tower', k=44),
         neutral=['hotel', 'luxury', 'mall', 'restaurant', 'bar', 'parking', 'apartments', 'pawn']),
 2: dict(code='EG', name='Eastgate Research Park', style='E', rseed=202,
         nbx=8, nby=8, lw=576, lh=576, bl=2, bh=2,
         sx=streets(8, 896, 704, 896, (4,)), sy=streets(8, 896, 704, 896, (4,)),
         ring=dict(N=1, S=1, W=1, E=1), p_pair=0.3, p_vert=0.1, p_block=0.1,
         zw=dict(T=6, O=34, R=10, I=2, C=16, E=32), core=12,
         ht=dict(T=(6, 12), O=(3, 6), R=(2, 4), I=(1, 3), C=(2, 4), F=(2, 6)),
         edges=dict(N='park', E='canal', S='highway', W='park'),
         landmark=dict(bx=4, by=4, kind='quad', name='University Quad', k=3),
         neutral=['university', 'apartments', 'parking', 'restaurant', 'archive', 'bar']),
 3: dict(code='IS', name='Ironside Docks', style='D', rseed=303,
         nbx=8, nby=8, lw=512, lh=512, bl=3, bh=2,
         sx=streets(8, 896, 640, 832, (3, 6)), sy=streets(8, 896, 640, 832, (4,)),
         ring=dict(N=1, S=1, W=1, E=0), p_pair=0.35, p_vert=0.05, p_block=0.28,
         zw=dict(T=2, O=8, R=18, I=52, C=6, E=8), core=0,
         ht=dict(T=(4, 8), O=(3, 5), R=(3, 6), I=(2, 4), C=(3, 4), F=(2, 6)),
         edges=dict(N='canal', E='harbour', S='rail', W='canal'),
         landmark=dict(bx=3, by=4, kind='stack', name='Grain Silos', k=9),
         neutral=['bar', 'tenement', 'unionhall', 'pawn', 'chopshop', 'construction', 'restaurant']),
 4: dict(code='OQ', name='Old Quarter', style='Q', rseed=404,
         nbx=9, nby=9, lw=384, lh=384, bl=3, bh=2,
         sx=streets(9, 768, 512, 704, (4, 5)), sy=streets(9, 768, 512, 704, (4,)),
         ring=dict(N=1, S=1, W=0, E=1), p_pair=0.12, p_vert=0.05, p_block=0.03,
         zw=dict(T=1, O=6, R=54, I=10, C=12, E=6), core=0,
         ht=dict(T=(4, 6), O=(3, 5), R=(3, 6), I=(2, 4), C=(3, 5), F=(3, 6)),
         edges=dict(N='park', E='cutting', S='rail', W='canal'),
         landmark=dict(bx=4, by=4, kind='clock', name='Clock Tower', k=10),
         neutral=['tenement', 'market', 'bar', 'pawn', 'gambling', 'druglab', 'hospital', 'restaurant', 'chopshop']),
 5: dict(code='HL', name='Highline', style='H', rseed=505,
         nbx=8, nby=8, lw=640, lh=640, bl=2, bh=2,
         sx=streets(8, 960, 704, 960, (3, 5)), sy=streets(8, 960, 704, 960, (3, 5)),
         ring=dict(N=1, S=1, W=1, E=1), p_pair=0.35, p_vert=0.1, p_block=0.2,
         zw=dict(T=6, O=14, R=6, I=44, C=14, E=16), core=0,
         ht=dict(T=(5, 10), O=(3, 6), R=(2, 4), I=(2, 4), C=(2, 4), F=(2, 6)),
         edges=dict(N='highway', E='cutting', S='canal', W='park'),
         landmark=dict(bx=4, by=3, kind='garrison', name='EarthGov Garrison', k=2),
         neutral=['construction', 'transit', 'parking', 'archive', 'underpass', 'unionhall']),
}
# gateways: (district, side, position 0..1 along the edge, type, target district). Every link has a partner.
GATES = [
    (1, 'N', 0.30, 'ramp', 2), (2, 'S', 0.30, 'ramp', 1),
    (1, 'E', 0.62, 'bridge', 3), (3, 'W', 0.62, 'bridge', 1),
    (1, 'S', 0.45, 'metro', 4), (4, 'N', 0.45, 'metro', 1),
    (1, 'W', 0.38, 'tunnel', 5), (5, 'E', 0.38, 'tunnel', 1),
    (2, 'E', 0.55, 'bridge', 3), (3, 'N', 0.55, 'bridge', 2),
    (3, 'S', 0.40, 'tunnel', 4), (4, 'E', 0.40, 'tunnel', 3),
    (4, 'W', 0.55, 'bridge', 5), (5, 'S', 0.55, 'bridge', 4),
]
GATE_CODE = dict(tunnel='T', ramp='R', metro='M', bridge='B')

REACH = {'road', 'ring', 'lot', 'notch', 'quay', 'pier', 'shoulder', 'groad', 'gstair', 'gate'}

def _area(p):
    return sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p))) / 2

def _rect(x0, y0, x1, y1): return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

class CityMap:
    def __init__(self): self.secs = []; self.things = []
    def add(self, role, outer, holes=(), **kw):
        d = dict(role=role, outer=outer, holes=list(holes), light=kw.pop('light', 96), floorh=kw.pop('floorh', 0),
                 ceil=kw.pop('ceil', CEIL), floor=kw.pop('floor', 'FLAT1'), ctex=kw.pop('ctex', 'F_SKY1'),
                 tag=kw.pop('tag', 0), fac=kw.pop('fac', 'CWCONCW'))
        d.update(kw); self.secs.append(d); return d
    def rect(self, role, x0, y0, x1, y1, holes=(), **kw):
        assert x1 > x0 and y1 > y0, (role, x0, y0, x1, y1)
        return self.add(role, _rect(x0, y0, x1, y1), holes, **kw)

def _rules(ra, rb):
    pair = frozenset((ra, rb))
    R = {
        frozenset(('quay', 'water')): 'CWRAIL2', frozenset(('pier', 'water')): 'CWRAIL2', frozenset(('groad', 'water')): 'CWRAIL2',
        frozenset(('curb', 'embank')): 'CWFENCE', frozenset(('curb', 'trench')): 'CWFENCE', frozenset(('curb', 'sembank')): 'CWFENCE',
        frozenset(('curb', 'lawn')): 'CWFENCE', frozenset(('shoulder', 'lawn')): 'CWFENCE',
        frozenset(('deck', 'far')): 'CWRAIL2', frozenset(('viaduct', 'sembank')): 'CWFENCE', frozenset(('viaduct', 'far')): 'CWRAIL2',
        frozenset(('groad', 'embank')): 'CWFENCE', frozenset(('groad', 'sembank')): 'CWFENCE', frozenset(('groad', 'lawn')): 'CWFENCE',
        frozenset(('ramp', 'embank')): 'CWBARR', frozenset(('ramp', 'curb')): 'CWBARR', frozenset(('ramp', 'water')): 'CWBARR',
    }
    mid = R.get(pair)
    block = bool(mid) or ((ra in REACH) != (rb in REACH))
    return block, mid

def emit_city(name, cm, things, out_dir):
    loops = []; total = 0.0
    for si, s in enumerate(cm.secs):
        o = s['outer']
        if _area(o) > 0: o = o[::-1]
        loops.append([si, o]); a = -_area(o)
        for h in s['holes']:
            if _area(h) < 0: h = h[::-1]
            loops.append([si, h]); a -= _area(h)
        total += a; s['_area'] = a
    vx, vy = defaultdict(set), defaultdict(set)
    for _, pts in loops:
        for x, y in pts: vx[x].add(y); vy[y].add(x)
    sx = {k: sorted(v) for k, v in vx.items()}; sy = {k: sorted(v) for k, v in vy.items()}
    for L in loops:
        pts = L[1]; new = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            new.append(a)
            if a[0] == b[0]:
                lst = sx[a[0]]; lo, hi = sorted((a[1], b[1]))
                mids = lst[bisect_right(lst, lo):bisect_left(lst, hi)]
                if a[1] > b[1]: mids = mids[::-1]
                new += [(a[0], y) for y in mids]
            elif a[1] == b[1]:
                lst = sy[a[1]]; lo, hi = sorted((a[0], b[0]))
                mids = lst[bisect_right(lst, lo):bisect_left(lst, hi)]
                if a[0] > b[0]: mids = mids[::-1]
                new += [(x, a[1]) for x in mids]
            else: raise ValueError("diagonal edge %s %s in %s" % (a, b, cm.secs[L[0]]['role']))
        L[1] = new
    edges = defaultdict(list)
    for si, pts in loops:
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            edges[frozenset((a, b))].append((a, b, si))
    bad = [(k, v) for k, v in edges.items() if len(v) > 2 or (len(v) == 2 and v[0][0] == v[1][0])]
    if bad:
        for k, v in bad[:8]: print("BAD EDGE", sorted(k), [(a, b, cm.secs[s]['role']) for a, b, s in v])
        raise SystemExit("city edge error (overlapping sectors?) in " + name)
    print("%s: sector area sum %.0f vs world %.0f" % (name, total, cm.world_area))
    assert abs(total - cm.world_area) < 1, "sectors do not tile the world (%s: %.0f vs %.0f)" % (name, total, cm.world_area)
    verts, vid = [], {}
    def V(p):
        if p not in vid: vid[p] = len(verts); verts.append(p)
        return vid[p]
    sides, lines = [], []
    for lst in edges.values():
        a, b, s = lst[0]; SA = cm.secs[s]
        if len(lst) == 1:
            sides.append(dict(sector=s, texturemiddle=SA['fac']))
            lines.append(dict(v1=V(a), v2=V(b), sidefront=len(sides) - 1, blocking="true")); continue
        s2 = lst[1][2]; SB = cm.secs[s2]
        block, mid = _rules(SA['role'], SB['role'])
        hi = SA if SA['floorh'] >= SB['floorh'] else SB
        ta = hi['fac']
        ln = dict(v1=V(a), v2=V(b), twosided="true")
        d1 = dict(sector=s, texturetop=ta, texturebottom=ta); d2 = dict(sector=s2, texturetop=ta, texturebottom=ta)
        if mid:
            d1['texturemiddle'] = mid; d2['texturemiddle'] = mid; ln['dontpegbottom'] = "true"
        if block: ln['blocking'] = "true"
        sides.append(d1); ln['sidefront'] = len(sides) - 1
        sides.append(d2); ln['sideback'] = len(sides) - 1
        lines.append(ln)
    def blk(n, d):
        return n + "\n{\n" + "".join("%s = %s;\n" % (k, v if not isinstance(v, str) or v in ('true', 'false') else '"%s"' % v) for k, v in d.items()) + "}\n"
    out = ['namespace = "zdoom";']
    for x, y in verts: out.append(blk("vertex", dict(x=float(x), y=float(y))))
    for l in lines: out.append(blk("linedef", l))
    for s in sides: out.append(blk("sidedef", s))
    for s in cm.secs:
        out.append(blk("sector", dict(heightfloor=s['floorh'], heightceiling=s['ceil'], texturefloor=s['floor'], textureceiling=s['ctex'],
                                      lightlevel=s['light'], id=s['tag'])))
    for t in things:
        d = dict(angle=0); d.update(t)
        d.update(skill1="true", skill2="true", skill3="true", skill4="true", skill5="true", single="true", coop="true", dm="true")
        out.append(blk("thing", d))
    tm = "\n".join(out).encode()
    lumps = [(name, b""), ("TEXTMAP", tm), ("ENDMAP", b"")]
    data = b""; dirs = b""; off = 12
    for n, c in lumps:
        dirs += struct.pack("<ii8s", off, len(c), n.encode()); data += c; off += len(c)
    open(os.path.join(out_dir, name + ".wad"), "wb").write(b"PWAD" + struct.pack("<ii", len(lumps), off) + data + dirs)
    print(name, len(cm.secs), "sectors", len(lines), "lines", len(verts), "verts")

# ------------------------------------------------------------------ edge frame helper
class Frame:
    """local (u along the edge, v outward) -> world, for side N/S/E/W of a grid of size Sx x Sy."""
    def __init__(self, side, Sx, Sy): self.side, self.Sx, self.Sy = side, Sx, Sy
    def pt(self, u, v):
        s = self.side
        if s == 'N': return (u, self.Sy + v)
        if s == 'S': return (u, -v)
        if s == 'E': return (self.Sx + v, u)
        return (-v, u)
    def box(self, u0, v0, u1, v1):
        a, b = self.pt(u0, v0), self.pt(u1, v1)
        return (min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
    def inward(self):      # angle (deg) that points into the city from the edge
        return dict(N=270, S=90, E=180, W=0)[self.side]
    def span(self, X0, X1, Y0, Y1):
        return (X0, X1) if self.side in 'NS' else (0, self.Sy)
    def length(self): return self.Sx if self.side in 'NS' else self.Sy

def carve(cm, c, first='x'):
    """remove the box c from every edge-band sector (rects, possibly with holes)"""
    cx0, cy0, cx1, cy1 = c
    keep_roles = ('skirt', 'road', 'ring', 'lot', 'notch', 'fill_grid')
    new = []
    for s in cm.secs:
        if s['role'] in keep_roles or s.get('grid'): new.append(s); continue
        xs = [p[0] for p in s['outer']]; ys = [p[1] for p in s['outer']]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        if len(s['outer']) != 4 or cx0 >= x1 or cx1 <= x0 or cy0 >= y1 or cy1 <= y0: new.append(s); continue
        ix0, iy0, ix1, iy1 = max(cx0, x0), max(cy0, y0), min(cx1, x1), min(cy1, y1)
        def hole_ok(pieces):
            for h in s['holes']:
                hx = [q[0] for q in h]; hy = [q[1] for q in h]
                inside = [p for p in pieces if min(hx) >= p[0] and max(hx) <= p[2] and min(hy) >= p[1] and max(hy) <= p[3]]
                over = [p for p in pieces if not (max(hx) <= p[0] or min(hx) >= p[2] or max(hy) <= p[1] or min(hy) >= p[3])]
                if len(over) > 0 and len(inside) != 1: return False
                if len(over) > 1: return False
            return True
        px = []
        if ix0 > x0: px.append((x0, y0, ix0, y1))
        if ix1 < x1: px.append((ix1, y0, x1, y1))
        if iy0 > y0: px.append((ix0, y0, ix1, iy0))
        if iy1 < y1: px.append((ix0, iy1, ix1, y1))
        py = []
        if iy0 > y0: py.append((x0, y0, x1, iy0))
        if iy1 < y1: py.append((x0, iy1, x1, y1))
        if ix0 > x0: py.append((x0, iy0, ix0, iy1))
        if ix1 < x1: py.append((ix1, iy0, x1, iy1))
        pieces = px if first == 'x' else py
        for p in pieces:
            hs = []
            for h in s['holes']:
                hx = [q[0] for q in h]; hy = [q[1] for q in h]
                if min(hx) >= p[0] and max(hx) <= p[2] and min(hy) >= p[1] and max(hy) <= p[3]: hs.append(h)
                elif not (max(hx) <= p[0] or min(hx) >= p[2] or max(hy) <= p[1] or min(hy) >= p[3]):
                    raise SystemExit("gate carve %s hits a hole in %s %s" % (c, s["role"], (x0, y0, x1, y1)))
            d = dict(s); d['outer'] = _rect(*p); d['holes'] = hs; new.append(d)
    cm.secs = new

# ------------------------------------------------------------------ the district builder
def build_district(n, P, out_dir, table):
    rng = random.Random(P['rseed'])
    nbx, nby = P['nbx'], P['nby']
    BW, BH = P['bl'] * P['lw'], P['bh'] * P['lh']
    def axis(st, bs):
        stp, blp, pos = [], [], 0
        for k in range(len(st)):
            stp.append(pos); pos += st[k]
            if k < len(st) - 1: blp.append(pos); pos += bs
        return stp, blp, pos
    STX, BLX, Sx = axis(P['sx'], BW)
    STY, BLY, Sy = axis(P['sy'], BH)
    ring = P['ring']
    X0, X1, Y0, Y1 = -EXT, Sx + EXT, -EXT, Sy + EXT
    cm = CityMap(); cm.world_area = (X1 - X0 + 2 * SK) * (Y1 - Y0 + 2 * SK)
    FIL = 'CWU%s' % P['style']
    filtex = [FIL + c for c in 'FFDB']
    cm.add('skirt', _rect(X0 - SK, Y0 - SK, X1 + SK, Y1 + SK), [_rect(X0, Y0, X1, Y1)], floorh=-64, ceil=0, light=40, floor='CWWATER', fac='CWEDGE')
    # ---- grid: roads, sidewalk rings, buildings
    holes = []
    for by in range(nby):
        for bx in range(nbx):
            holes.append(_rect(BLX[bx] - SW, BLY[by] - SW, BLX[bx] + BW + SW, BLY[by] + BH + SW))
    cm.add('road', _rect(0, 0, Sx, Sy), holes, floor='CWASPH', light=150, fac='CWCONCW', grid=1)
    bl_rec = []
    def is_fill(bx, by):
        return (bx == 0 and ring['W']) or (bx == nbx - 1 and ring['E']) or (by == 0 and ring['S']) or (by == nby - 1 and ring['N'])
    lm = P['landmark']
    UP, GR = 'CWU' + P['style'], 'CWG' + P['style']
    bid = 0
    for by in range(nby):
        for bx in range(nbx):
            x0, y0 = BLX[bx], BLY[by]
            cm.add('ring', _rect(x0 - SW, y0 - SW, x0 + BW + SW, y0 + BH + SW), [_rect(x0, y0, x0 + BW, y0 + BH)], floorh=SWH, floor='CWPAVE', light=160, fac='CWCONCW', grid=1)
            fill = is_fill(bx, by)
            is_lm = (bx, by) == (lm['bx'], lm['by'])
            occ = [[0] * P['bl'] for _ in range(P['bh'])]
            rects = []
            if fill or is_lm or rng.random() < P['p_block']:
                rects.append((0, 0, P['bl'], P['bh']))
            else:
                for j in range(P['bh']):
                    for i in range(P['bl']):
                        if occ[j][i]: continue
                        w = 1; h = 1
                        if P['bh'] == 2 and j == 0 and rng.random() < P['p_vert']: h = 2
                        elif i + 1 < P['bl'] and not occ[j][i + 1] and rng.random() < P['p_pair']:
                            w = 2
                            if i + 2 < P['bl'] and not occ[j][i + 2] and rng.random() < 0.3: w = 3
                        for jj in range(h):
                            for ii in range(w): occ[j + jj][i + ii] = 1
                        rects.append((i, j, w, h))
            for (i, j, w, h) in rects:
                rx0, ry0 = x0 + i * P['lw'], y0 + j * P['lh']
                rx1, ry1 = rx0 + w * P['lw'], ry0 + h * P['lh']
                nl = w * h
                cls = 'F' if fill else ('S' if nl == 1 else ('M' if nl == 2 else 'L'))
                face = 'S' if ry0 == y0 else 'N'
                cx = ((rx0 + rx1) // 2) // 16 * 16
                wf = 0
                if not fill:
                    if bx == 0 or (bx == 1 and ring['W']): wf |= 8
                    if bx == nbx - 1 or (bx == nbx - 2 and ring['E']): wf |= 2
                    if by == 0 or (by == 1 and ring['S']): wf |= 4
                    if by == nby - 1 or (by == nby - 2 and ring['N']): wf |= 1
                b = dict(id=bid, x0=rx0, y0=ry0, x1=rx1, y1=ry1, face=face, cls=cls, nl=nl, bx=bx, by=by, fill=int(fill), wf=wf, cx=cx, lm=(lm['kind'] if is_lm else ''))
                bl_rec.append(b)
                hw = NW // 2
                if fill:
                    poly = _rect(rx0, ry0, rx1, ry1); notch = None
                elif face == 'S':
                    poly = [(rx0, ry0), (cx - hw, ry0), (cx - hw, ry0 + ND), (cx + hw, ry0 + ND), (cx + hw, ry0), (rx1, ry0), (rx1, ry1), (rx0, ry1)]
                    notch = _rect(cx - hw, ry0, cx + hw, ry0 + ND)
                else:
                    poly = [(rx0, ry0), (rx1, ry0), (rx1, ry1), (cx + hw, ry1), (cx + hw, ry1 - ND), (cx - hw, ry1 - ND), (cx - hw, ry1), (rx0, ry1)]
                    notch = _rect(cx - hw, ry1 - ND, cx + hw, ry1)
                inner = _rect(rx0 + FR, ry0 + FR, rx1 - FR, ry1 - FR)
                cm.add('lot', poly, [inner], floorh=GND, floor='CWCONCF', light=100, tag=TAGF + bid, fac=GR + 'A', grid=1)
                cm.add('lot', inner, floorh=GND, floor='CWCONCF', light=70, tag=TAGI + bid, fac=UP + 'A', grid=1)
                if notch: cm.add('notch', notch, floorh=GND, floor='FLAT1', light=170, tag=TAGN + bid, fac=GR + 'A', grid=1)
                bid += 1
    # ---- edges (local frame: u along the edge, v outward)
    filtex = [UP + c for c in 'FFDB']
    gate_info = []
    for (dn, side, pos, gtype, tgt) in [g for g in GATES if g[0] == n]:
        f = Frame(side, Sx, Sy)
        gate_info.append(dict(side=side, uc=int(f.length() * pos) // 64 * 64, type=gtype, target=tgt, f=f))
    def gate_keep(f):
        ks = []
        for g in gate_info:
            if g['f'].side != f.side: continue
            ks.append(f.box(g['uc'] - 800, -60, g['uc'] + 800, 2700))
            for u in (g['uc'] - 192, g['uc'] + 192, g['uc'] - 448, g['uc'] + 448, g['uc'] - 320, g['uc'] + 320):
                ks.append(f.box(u - 2, -60, u + 2, EXT + 100))
        return ks
    def hit(a, k): return a[0] < k[2] and a[2] > k[0] and a[1] < k[3] and a[3] > k[1]
    def filler(f, u0, v0, u1, v1, dens, hk=(2, 12), cell=960, keep=()):
        out = []; cu = u0
        while cu + cell <= u1:
            cv = v0
            while cv + cell <= v1:
                if rng.random() < dens(cu + cell / 2, cv + cell / 2):
                    w = rng.choice([448, 576, 704, 832]); hh = rng.choice([448, 576, 704, 832])
                    a = cu + 64 + rng.randrange(0, max(1, int(cell - 128 - w)) // 64 + 1) * 64
                    b = cv + 64 + rng.randrange(0, max(1, int(cell - 128 - hh)) // 64 + 1) * 64
                    bx_ = f.box(a, b, a + w, b + hh)
                    if not any(hit(bx_, k) for k in keep): out.append((bx_, GND + STOREY * rng.randint(*hk)))
                cv += cell
            cu += cell
        return out
    def far_ground(f, u0, v0, u1, v1, fl, fac):
        cm.add('far', _rect(*f.box(u0, v0, u1, v1)), [_rect(*r) for r, h in fl], floor='FLOOR0_6', light=115, fac=fac)
        for r, h in fl: cm.rect('ffill', *r, floorh=h, floor='CWCONCF', light=90, fac=rng.choice(filtex))
    def edge_water(f, kind):
        Ln = f.length(); harbour = kind == 'harbour'
        QW, PL = 192, 1500
        WD = 3800 if harbour else 1500 + 192
        keep = gate_keep(f)
        cm.rect('quay', *f.box(0, 0, Ln, QW), floorh=SWH, floor='CWPAVE', light=134, fac='CWSEAWAL')
        piers = []
        isl = []      # (box, floor, fac, children)
        if harbour:
            for pu in (int(Ln * 0.28) // 64 * 64, int(Ln * 0.70) // 64 * 64): piers.append((pu - 96, pu + 96))
            for (a, b) in piers:
                cm.rect('pier', *f.box(a, QW, b, QW + PL), floorh=SWH, floor='CWPLANK', light=126, fac='CWSEAWAL')
                for vv in range(QW + 200, QW + PL - 100, 256):
                    for uu in (a - 96, b + 64): isl.append((f.box(uu, vv, uu + 32, vv + 32), 72, 'CWPILLAR', []))
            for (a, b), sd in zip(piers, (1, -1)):
                uu = b + 160 if sd > 0 else a - 160 - 320
                isl.append((f.box(uu, QW + 260, uu + 320, QW + 260 + 1200), 168, 'CWHULL', [(f.box(uu + 80, QW + 700, uu + 240, QW + 1040), 380, 'CWCONT')]))
            su = int(Ln * 0.46) // 64 * 64
            isl.append((f.box(su, 1900, su + 400, 3400), 200, 'CWHULL', [(f.box(su + 100, 2100, su + 300, 2500), 420, 'CWCONT')]))
            isl.append((f.box(int(Ln * 0.12), 3100, int(Ln * 0.62), 3196), 56, 'CWSEAWAL', []))
            isl = [i for i in isl if not any(hit(i[0], k) for k in keep)]
        us = [0]
        for (a, b) in piers: us += [a, b]
        us.append(Ln)
        segs = [(us[k], QW, us[k + 1], QW + PL) for k in range(0, len(us), 2) if us[k + 1] > us[k]] if harbour else []
        segs.append((0, QW + PL, Ln, WD) if harbour else (0, QW, Ln, WD))
        for sg in segs:
            bx_ = f.box(*sg); hs = [_rect(*i[0]) for i in isl if i[0][0] >= bx_[0] and i[0][2] <= bx_[2] and i[0][1] >= bx_[1] and i[0][3] <= bx_[3]]
            cm.add('water', _rect(*bx_), hs, floorh=-64, floor='CWWATER', light=170, fac='CWSEAWAL')
        for ib, fh, fac, kids in isl:
            cm.add('obst', _rect(*ib), [_rect(*k[0]) for k in kids], floorh=fh, floor='CWCONCF', light=90, fac=fac)
            for kb, kh, kf in kids: cm.rect('obst', *kb, floorh=kh, floor='CWCONCF', light=90, fac=kf)
        if harbour:       # far shore: quay strip with crane towers, then land with low warehouses (nothing stands in the water)
            FQ = 320
            cr = []
            for cu in range(int(Ln * 0.10) // 64 * 64, int(Ln * 0.92), 2688):
                for du in (0, 512): cr.append(f.box(cu + du, WD + 64, cu + du + 128, WD + 192))
            cm.add('far', _rect(*f.box(0, WD, Ln, WD + FQ)), [_rect(*r) for r in cr], floorh=SWH, floor='CWCONCF', light=110, fac='CWSEAWAL')
            for r in cr: cm.rect('ffill', *r, floorh=SWH + 1152, floor='CWCONCF', light=230, fac='CWCRANE')
            fl = filler(f, 0, WD + FQ, Ln, EXT - 200, lambda u, v: 0.78 if v < WD + FQ + 2200 else 0.5, hk=(1, 4))
            far_ground(f, 0, WD + FQ, Ln, EXT, fl, 'CWDECKUN')
        else:
            fl = filler(f, 0, WD, Ln, EXT - 200, lambda u, v: max(0.0, 0.85 - (v - WD) / 4800.0), hk=(2, 9), keep=keep)
            far_ground(f, 0, WD, Ln, EXT, fl, 'CWDECKUN')
        if f.side in 'NS':      # corner regions of a full-width band
            for (ua, ub) in ((X0, 0), (Ln, X1)):
                cm.add('far', _rect(*f.box(ua, 0, ub, EXT)), [], floor='FLOOR0_6', light=115, fac='CWDECKUN')
    def edge_flank(f, kind):
        Ln = f.length()
        lo, hi = (X0, X1) if f.side in 'NS' else (0, Ln)
        keep = gate_keep(f)
        cm.rect('shoulder', *f.box(0, 0, Ln, 96), floor='CWASPH', light=134, fac='CWCONCW')
        if lo < 0:
            cm.rect('curb', *f.box(lo, 0, 0, 160), floorh=32, light=130, fac='CWJERSY')
            cm.rect('curb', *f.box(Ln, 0, hi, 160), floorh=32, light=130, fac='CWJERSY')
        cm.rect('curb', *f.box(0, 96, Ln, 160), floorh=32, light=130, fac='CWJERSY')
        if kind == 'highway':
            cm.rect('embank', *f.box(lo, 160, hi, 640), floorh=32, floor='GRASS1', light=150, fac='CWRETAIN')
            x = lo
            for p in range(lo + 400, hi - 400, 768):
                cm.rect('embank', *f.box(x, 640, p, 704), floorh=32, floor='GRASS1', light=150, fac='CWRETAIN')
                cm.rect('pillar', *f.box(p, 640, p + 96, 704), floorh=384, floor='FLAT1', light=100, fac='CWPILLAR')
                x = p + 96
            cm.rect('embank', *f.box(x, 640, hi, 704), floorh=32, floor='GRASS1', light=150, fac='CWRETAIN')
            cm.rect('deck', *f.box(lo, 704, hi, 1184), floorh=384, floor='CWASPH', light=120, fac='CWDECKUN')
            near = 1184; ffac = 'CWDECKUN'
        elif kind == 'rail':
            cm.rect('sembank', *f.box(lo, 160, hi, 640), floorh=32, floor='GRASS1', light=150, fac='CWRETAIN')
            cars = []; tu = lo + 512
            while tu + 640 < hi - 512 and len(cars) < 16:
                r = f.box(tu, 740, tu + 640, 900)
                if not any(hit(r, k) for k in keep): cars.append(r)
                tu += 704
            for r in cars: cm.add('train', _rect(*r), floorh=256 + 112, floor='CWRAILA', light=140, fac='CWTRAIN')
            cm.add('viaduct', _rect(*f.box(lo, 640, hi, 1000)), [_rect(*r) for r in cars], floorh=256, floor='CWRAILA', light=100, fac='CWVIADUC')
            near = 1000; ffac = 'CWVIADUC'
        elif kind == 'cutting':
            cm.rect('trench', *f.box(lo, 160, hi, 640), floorh=-112, floor='CWRAILB', light=140, fac='CWRETAIN')
            near = 640; ffac = 'CWRETAIN'
        else:
            cm.rect('lawn', *f.box(lo, 160, hi, 900), floorh=SWH, floor='GRASS1', light=150, fac='CWRETAIN')
            near = 900; ffac = 'CWRETAIN'
        fl = filler(f, lo + 400, near + 900, hi - 400, EXT - 300, lambda u, v: max(0.0, 0.92 - (v - near - 900) / 4500.0), hk=(2, 8), keep=keep)
        far_ground(f, lo, near, hi, EXT, fl, ffac)
    for side in 'NSEW':
        f = Frame(side, Sx, Sy); kind = P['edges'][side]
        if kind in ('harbour', 'canal'): edge_water(f, kind)
        else: edge_flank(f, kind)
    # ---- gateways (carved through the edge bands)
    def portal_mass(f, a, b, A, B, v0, v1, fh, code):
        cm.rect('gmass', *f.box(a, v0, b, v1), floorh=fh, floor='CWCONCF', light=90, fac=code)
        if A < a: cm.rect('gmass', *f.box(A, v0, a, v1), floorh=fh, floor='CWCONCF', light=60, fac='CWRETAIN')
        if B > b: cm.rect('gmass', *f.box(b, v0, B, v1), floorh=fh, floor='CWCONCF', light=60, fac='CWRETAIN')
    for g in gate_info:
        f, uc, gt = g['f'], g['uc'], g['type']
        a, b = uc - 192, uc + 192
        FW = 256
        A, B = (a - 128, b + 128) if gt == 'bridge' else (a - FW, b + FW)
        Ltot = {'tunnel': 832, 'ramp': 1152, 'metro': 896, 'bridge': 1500 + 192 + 380 + 260}[gt]
        end0 = Ltot - 96
        code = 'CWP%s%d' % (GATE_CODE[gt], g['target'])
        fst = 'x' if g['side'] in 'NS' else 'y'
        if gt == 'bridge':
            carve(cm, f.box(a, 0, b, end0), fst); carve(cm, f.box(A, end0, B, Ltot + 96), fst)
        else:
            carve(cm, f.box(A, 0, B, Ltot + 96), fst)
        if gt == 'tunnel':
            cm.rect('groad', *f.box(a, 0, b, end0 - 176), floor='CWASPH', light=155, fac='CWCONCW')
            trig = f.box(a, end0 - 176, b, end0)
            cm.rect('gate', *trig, floor='CWASPH', light=150, fac='CWCONCW')
            portal_mass(f, a, b, A, B, end0, Ltot + 96, 512, code)
            for (p, q) in ((A, a), (b, B)): cm.rect('gmass', *f.box(p, 0, q, end0), floorh=512, floor='CWCONCF', light=60, fac='CWRETAIN')
        elif gt == 'ramp':
            nseg = 10; seg = (end0 - 176 - 128) // nseg
            cm.rect('groad', *f.box(a, 0, b, 128), floor='CWASPH', light=155, fac='CWJERSY')
            for i in range(nseg):
                cm.rect('gstair', *f.box(a, 128 + i * seg, b, 128 + (i + 1) * seg), floorh=12 * (i + 1), floor='CWASPH', light=155, fac='CWJERSY')
            trig = f.box(a, 128 + nseg * seg, b, end0)
            cm.rect('gate', *trig, floorh=12 * nseg, floor='CWASPH', light=150, fac='CWJERSY')
            portal_mass(f, a, b, A, B, end0, Ltot + 96, 640, code)
            for (p, q) in ((A, a), (b, B)): cm.rect('gmass', *f.box(p, 0, q, end0), floorh=192, floor='GRASS1', light=155, fac='CWRETAIN')
        elif gt == 'metro':
            cm.rect('groad', *f.box(a, 0, b, 96), floor='CWASPH', light=155, fac='CWCONCW')
            for i in range(8):
                cm.rect('gstair', *f.box(a, 96 + i * 64, b, 96 + (i + 1) * 64), floorh=-16 * (i + 1), floor='FLAT1', light=155 - 4 * i, fac='CWCONCW')
            trig = f.box(a, 96 + 8 * 64, b, end0)
            cm.rect('gate', *trig, floorh=-128, floor='FLAT1', light=150, fac='CWCONCW')
            portal_mass(f, a, b, A, B, end0, Ltot + 96, 0, code)
            for (p, q) in ((A, a), (b, B)): cm.rect('gmass', *f.box(p, 0, q, end0), floorh=SWH, floor='CWCONCF', light=100, fac='CWCONCW')
        else:
            cm.rect('groad', *f.box(a, 0, b, end0 - 176), floorh=SWH, floor='CWASPH', light=155, fac='CWSEAWAL')
            trig = f.box(a, end0 - 176, b, end0)
            cm.rect('gate', *trig, floorh=SWH, floor='CWASPH', light=150, fac='CWSEAWAL')
            portal_mass(f, a, b, A, B, end0, Ltot + 96, 512, code)
        ctr = f.pt(uc, -320)
        table['gate'].append(dict(dist=n, side=g['side'], type=gt, target=g['target'], tx0=trig[0], ty0=trig[1], tx1=trig[2], ty1=trig[3],
                                  ax=ctr[0], ay=ctr[1], aang=f.inward()))
    sxp = STX[2] + P['sx'][2] // 2; syp = STY[2] + P['sy'][2] // 2
    things = [dict(type=1, x=sxp, y=syp, angle=0)]
    table['dist'].append(dict(n=n, code=P['code'], name=P['name'], style=P['style'], w=Sx, h=Sy, sx=sxp, sy=syp,
                              zw=P['zw'], core=P['core'], ht=P['ht'], neutral=P['neutral'], lm=lm, edges=P['edges']))
    table['bldg'] += [dict(b, dist=n) for b in bl_rec]
    emit_city("C%02d" % n, cm, things, out_dir)
    if os.environ.get("CW_CITY_PREVIEW"): preview(cm, os.path.join(os.environ["CW_CITY_PREVIEW"], "C%02d.png" % n), (X0 - SK, Y0 - SK, X1 + SK, Y1 + SK))
    return cm

def preview(cm, path, box, scale=0.045):
    from PIL import Image, ImageDraw
    x0, y0, x1, y1 = box
    W, H = int((x1 - x0) * scale), int((y1 - y0) * scale)
    im = Image.new("RGB", (W, H), (0, 0, 0)); d = ImageDraw.Draw(im)
    col = dict(skirt=(20, 20, 40), road=(70, 70, 76), ring=(120, 120, 110), lot=(150, 90, 70), notch=(255, 255, 0), quay=(160, 160, 130),
               pier=(160, 120, 80), water=(30, 60, 120), shoulder=(90, 90, 96), curb=(200, 200, 200), trench=(90, 60, 40), far=(50, 70, 50),
               embank=(60, 100, 60), deck=(200, 120, 40), pillar=(255, 60, 60), viaduct=(150, 80, 200), sembank=(70, 110, 70), lawn=(80, 150, 80),
               ffill=(110, 70, 90), obst=(200, 60, 60), groad=(255, 255, 255), gstair=(255, 200, 0), gate=(0, 255, 0), gmass=(255, 0, 255), train=(200, 200, 60))
    T = lambda p: [((x - x0) * scale, H - (y - y0) * scale) for x, y in p]
    order = ['skirt', 'far', 'water', 'road', 'ring']
    for s in sorted(cm.secs, key=lambda s: (order.index(s['role']) if s['role'] in order else 9)):
        d.polygon(T(s['outer']), fill=col.get(s['role'], (255, 0, 255)))
        for h in s['holes']: d.polygon(T(h), fill=(0, 0, 0)) if False else None
    for s in cm.secs:
        if s['role'] not in order: d.polygon(T(s['outer']), fill=col.get(s['role'], (255, 0, 255)))
    im.save(path)

def write_table(table, path):
    L = ["# generated by CorpoWars_tools/citydist.py - do not edit. Read by citygen.zs (lump citydist.txt)."]
    for d in table['dist']:
        L.append("DIST|%d|%s|%s|%s|%d|%d|%d|%d" % (d['n'], d['code'], d['name'], d['style'], d['w'], d['h'], d['sx'], d['sy']))
        e = d['edges']
        L.append("EDGES|%d|%s|%s|%s|%s" % (d['n'], e['N'], e['E'], e['S'], e['W']))
        L.append("ZW|%d|%s|%d" % (d['n'], "|".join("%d" % d['zw'][k] for k in 'TORICE'), d['core']))
        for z in 'TORICF': L.append("HT|%d|%s|%d|%d" % (d['n'], z, d['ht'][z][0], d['ht'][z][1]))
        L.append("NEUTRAL|%d|%s" % (d['n'], ",".join(d['neutral'])))
        L.append("LM|%d|%s|%s|%d" % (d['n'], d['lm']['kind'], d['lm']['name'], d['lm']['k']))
    for b in table['bldg']:
        L.append("B|%d|%d|%d|%d|%d|%d|%s|%s|%d|%d|%d|%d|%d|%d|%s" % (b['dist'], b['id'], b['x0'], b['y0'], b['x1'], b['y1'], b['face'], b['cls'],
                 b['nl'], b['bx'], b['by'], b['fill'], b['wf'], b['cx'], b['lm'] or '-'))
    for g in table['gate']:
        L.append("GATE|%d|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d" % (g['dist'], g['side'], g['type'], g['target'], g['tx0'], g['ty0'], g['tx1'], g['ty1'], g['ax'], g['ay'], g['aang']))
    open(path, "w").write("\n".join(L) + "\n")

def main(out_dir, table_path):
    table = dict(dist=[], bldg=[], gate=[])
    for n in sorted(PROFILES):
        build_district(n, PROFILES[n], out_dir, table)
    write_table(table, table_path)
    for n in sorted(PROFILES):
        c = sum(1 for b in table['bldg'] if b['dist'] == n)
        print("district", n, PROFILES[n]['name'], "buildings", c)
