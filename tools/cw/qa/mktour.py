# Build a camera tour from a TK dump: one inside-corner shot per room type (and a few extra).
# usage: mktour.py stdout.txt out.txt [types...]
import sys, math, collections
L = open(sys.argv[1], encoding='latin1').read().splitlines()
NAMES = "HALL OPEN OFF EXEC CONF PANTRY STOR SERV LAB IT JAN DUCT BATH STAIR ELEV FRGT CLOB RECP".split()
SZ = [176, 144, 176, 128, 160, 160, 160, 128, 176, 144, 176]
cells = collections.defaultdict(list)
for l in L:
    p = l.split()
    if p and p[0] == 'CEL':
        i, j, r, t, x, y = int(p[1]), int(p[2]), int(p[3]), int(p[4]), float(p[5]), float(p[6])
        cells[r].append((i, j, t, x, y))
want = sys.argv[3:] or ["OFF", "EXEC", "CONF", "PANTRY", "STOR", "SERV", "LAB", "IT", "JAN", "BATH", "STAIR", "ELEV", "FRGT", "CLOB", "RECP", "OPEN", "HALL"]
out = []; seen = collections.Counter()
for r, cs in sorted(cells.items()):
    t = NAMES[cs[0][2]]
    if t not in want or seen[t] >= (3 if t == "OPEN" else 1): continue
    seen[t] += 1
    cx = sum(c[3] for c in cs) / len(cs); cy = sum(c[4] for c in cs) / len(cs)
    i, j, _, x, y = cs[0] if t != "OPEN" else cs[len(cs) // (seen[t] + 1)]
    # stand in the corner of the first cell farthest from the room centroid, look at the far corner
    best = None
    for sx in (-1, 1):
        for sy in (-1, 1):
            px, py = x + sx * (SZ[i] / 2 - 18), y + sy * (SZ[j] / 2 - 18)
            d = math.hypot(px - cx, py - cy)
            if best is None or d > best[0]: best = (d, px, py, sx, sy)
    _, px, py, sx, sy = best
    tx, ty = (cx, cy) if len(cs) > 1 else (x - sx * 40, y - sy * 40)
    ang = math.degrees(math.atan2(ty - py, tx - px)) % 360
    out.append("%d %d %d 12 %d" % (px, py, ang, -1))
    print(t, r, "->", out[-1], file=sys.stderr)
open(sys.argv[2], "w").write("\n".join(out) + "\n")
