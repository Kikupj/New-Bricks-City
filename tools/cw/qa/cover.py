# Cover budget along patrol routes (Deus Ex rule: never a long stretch in the open next to a watched path).
# usage: cover.py stdout.txt [png]   env: R (cover reach, default 96), MAXGAP (flag longer exposed stretches, 256)
# Cover = solid furniture/props at least crouch height (28u), unlocked doorways (duck into a room),
# and the 16u structural columns. A route sample is "covered" if cover is within R of it.
import sys, os, math, collections
import numpy as np
L = open(sys.argv[1], encoding='latin1').read().splitlines()
R = float(os.environ.get('R', 96)); MAXGAP = float(os.environ.get('MAXGAP', 256))
cover = []; pp = {}; secured = set(); lines = []
for l in L:
    p = l.split()
    if not p: continue
    if p[0] == 'THG' and len(p) >= 7:
        c, x, y, r, h = p[1], float(p[2]), float(p[3]), float(p[5]), float(p[6])
        if c == 'CW_Door': cover.append((x, y, 24, 'door'))   # doorways reach a bit further: duck through
        elif (c == 'CW_Blocker' or c.startswith('CW_C') or c in ('CW_Plant', 'CW_JanitorCart', 'CW_TransportAccess')) and h >= 28:
            cover.append((x, y, r, 'prop'))
    elif p[0] == 'SDOOR': secured.add((round(float(p[1])), round(float(p[2]))))
    elif p[0] == 'PP': pp[int(p[1])] = (int(p[2]), float(p[3]), float(p[4]))
    elif p[0] == 'LIN' and int(p[6]) < 0:
        lines.append(tuple(map(float, p[1:5])))
cover = [c for c in cover if not (c[3] == 'door' and (round(c[0]), round(c[1])) in secured)]
# structural columns: one-sided 16u edges inside the building (not the facade)
edges = collections.Counter()
for ax, ay, bx, by in lines:
    if abs(math.hypot(bx - ax, by - ay) - 16) < 0.5 and 0 < min(ax, bx) and max(ax, bx) < 1712 and 0 < min(ay, by) and max(ay, by) < 1712:
        edges[(round((ax + bx) / 2 / 8), round((ay + by) / 2 / 8))] += 1
cols = set()
for ax, ay, bx, by in lines:
    if abs(math.hypot(bx - ax, by - ay) - 16) < 0.5:
        mx, my = (ax + bx) / 2, (ay + by) / 2
        # a column centre is 8u off the edge midpoint; keep squares surrounded by 4 such edges
        for dx, dy in ((8, 0), (-8, 0), (0, 8), (0, -8)):
            cx, cy = mx + dx, my + dy
            n = sum(1 for ex, ey in ((cx + 8, cy), (cx - 8, cy), (cx, cy + 8), (cx, cy - 8)) if (round(ex / 8), round(ey / 8)) in edges)
            if n == 4: cols.add((round(cx), round(cy)))
if os.environ.get('COLUMNS', '1') == '1': cover += [(x, y, 8, 'column') for x, y in cols]
C = np.array([(c[0], c[1], c[2]) for c in cover]) if cover else np.zeros((0, 3))
# routes: follow next pointers into loops
routes = []; seen = set()
for tid in pp:
    if tid in seen: continue
    loop = []; t = tid
    while t in pp and t not in seen:
        seen.add(t); loop.append(t); t = pp[t][0]
    if len(loop) > 1: routes.append([(pp[t][1], pp[t][2]) for t in loop])
report = []; segs = []
worst_all = 0
for ri, pts in enumerate(routes):
    samples = []
    for k in range(len(pts)):
        a, b = np.array(pts[k]), np.array(pts[(k + 1) % len(pts)])
        n = max(1, int(np.linalg.norm(b - a) / 16))
        for s in range(n): samples.append(a + (b - a) * s / n)
    S = np.array(samples)
    d = np.sqrt(((S[:, None, :2] - C[None, :, :2]) ** 2).sum(-1)) - C[None, :, 2] if len(C) else np.full((len(S), 1), 1e9)
    near = d.min(1) <= R
    # longest exposed stretch (wraps around the loop)
    run = worst = 0
    for v in list(near) + list(near):
        run = 0 if v else run + 16; worst = max(worst, min(run, 16 * len(S)))
    worst_all = max(worst_all, worst)
    report.append((ri, len(pts), 16 * len(S), near.mean(), worst))
    segs.append((S, near))
for ri, npts, length, frac, worst in report:
    flag = '  <-- exposed stretch' if worst > MAXGAP else ''
    print(f"route {ri}: {npts} points, {length:.0f}u, {frac * 100:.0f}% within {R:.0f}u of cover, longest exposed {worst:.0f}u{flag}")
print(f"cover objects {len(cover)} (props {sum(c[3] == 'prop' for c in cover)}, doors {sum(c[3] == 'door' for c in cover)}, columns {len(cols)}); worst exposed stretch {worst_all:.0f}u")
if len(sys.argv) > 2:
    from PIL import Image, ImageDraw
    sc = 0.5; W = int(1800 * sc)
    im = Image.new('RGB', (W, W), (24, 26, 30)); dr = ImageDraw.Draw(im)
    P = lambda x, y: ((x + 40) * sc, (1760 - y) * sc)
    for ax, ay, bx, by in lines: dr.line([P(ax, ay), P(bx, by)], fill=(90, 90, 100))
    for x, y, r, kind in cover:
        col = {'prop': (200, 160, 60), 'door': (80, 160, 255), 'column': (160, 160, 170)}[kind]
        dr.rectangle([P(x - r, y + r), P(x + r, y - r)], outline=col)
    for S, near in segs:
        for (x, y), v in zip(S, near): dr.point(P(x, y), fill=(60, 220, 90) if v else (255, 60, 50)); dr.ellipse([P(x - 4, y + 4), P(x + 4, y - 4)], outline=(60, 220, 90) if v else (255, 60, 50))
    im.save(sys.argv[2])
