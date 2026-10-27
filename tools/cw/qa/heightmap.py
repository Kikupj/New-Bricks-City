# Render floor-height map from a TK dump in uzdoom stdout. usage: heightmap.py stdout.txt out.png [scale]
import sys, re, numpy as np
from PIL import Image, ImageDraw, ImageFont
txt = open(sys.argv[1], encoding='latin1').read().splitlines()
S = {}; Ls = []; Th = []; Ce = []
for l in txt:
    p = l.split()
    if not p: continue
    if p[0] == 'SEC': S[int(p[1])] = (float(p[2]), float(p[3]), p[4], p[5], int(p[6]))
    elif p[0] == 'LIN': Ls.append((float(p[1]), float(p[2]), float(p[3]), float(p[4]), int(p[5]), int(p[6]), p[7] if len(p)>7 else '-'))
    elif p[0] == 'CEL': Ce.append((int(p[1]), int(p[2]), int(p[3]), int(p[4]), float(p[5]), float(p[6])))
    elif p[0] == 'THG': Th.append((p[1], float(p[2]), float(p[3]), float(p[4]), float(p[5])))
sc = float(sys.argv[3]) if len(sys.argv) > 3 else 0.5
x0, y0, x1, y1 = -40, -40, 1752, 1752
W, H = int((x1 - x0) * sc), int((y1 - y0) * sc)
fl = np.full((H, W), np.nan); cl = np.full((H, W), np.nan)
edges = {}
for (ax, ay, bx, by, f, b, m) in Ls:
    for s in (f, b):
        if s >= 0: edges.setdefault(s, []).append((ax, ay, bx, by))
for s, E in edges.items():
    if s not in S: continue
    E = np.array(E)
    for row in range(H):
        y = y1 - (row + 0.5) / sc
        ay, by = E[:, 1], E[:, 3]
        m = ((ay <= y) & (by > y)) | ((by <= y) & (ay > y))
        if not m.any(): continue
        e = E[m]
        xs = np.sort(e[:, 0] + (y - e[:, 1]) * (e[:, 2] - e[:, 0]) / (e[:, 3] - e[:, 1]))
        for k in range(0, len(xs) - 1, 2):
            c0 = int(np.ceil((xs[k] - x0) * sc - 0.5)); c1 = int(np.floor((xs[k + 1] - x0) * sc - 0.5))
            c0 = max(c0, 0); c1 = min(c1, W - 1)
            if c1 >= c0: fl[row, c0:c1 + 1] = S[s][0]; cl[row, c0:c1 + 1] = S[s][1]
img = np.zeros((H, W, 3), np.uint8)
def col(h):
    # -24..40 mapped to palette; 0 = mid grey
    t = np.clip((h + 24) / 64, 0, 1)
    return np.stack([80 + 175 * t, 80 + 60 * (1 - abs(t - 0.375) * 2), 200 - 170 * t], -1)
ok = ~np.isnan(fl)
img[ok] = col(fl[ok]).astype(np.uint8)
closed = ok & (cl - fl < 57)
img[closed] = (20, 20, 20)
lowc = ok & (cl - fl >= 57) & (cl - fl < 72)
img[lowc] = (img[lowc] * 0.6).astype(np.uint8)
im = Image.fromarray(img); d = ImageDraw.Draw(im)
P = lambda x, y: ((x - x0) * sc, (y1 - y) * sc)
for (ax, ay, bx, by, f, b, m) in Ls:
    if b < 0: d.line([P(ax, ay), P(bx, by)], fill=(255, 255, 255), width=1)
    elif f in S and b in S and abs(S[f][0] - S[b][0]) > 0.5: d.line([P(ax, ay), P(bx, by)], fill=(255, 230, 0), width=1)
for (c, x, y, z, r) in Th:
    cx, cy = P(x, y); rr = max(2, r * sc)
    if c.startswith('CW_F'):
        d.text((cx - 6, cy - 4), c[4:8], fill=(120, 255, 120)); continue
    colr = (255, 60, 60) if 'Guard' in c else (0, 255, 255) if 'Light' in c else (255, 0, 255) if 'Door' in c else (255, 170, 60) if 'Blocker' in c else (200, 200, 200)
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=colr)
# labels: floor height per sector (only for small-ish sectors with nonzero floors)
NAMES = "HALL OPEN OFF EXEC CONF PANTRY STOR SERV LAB IT JAN DUCT BATH STAIR ELEV FRGT CLOB RECP".split()
for (i, j, r, t, cx, cy) in Ce:
    px, py = P(cx, cy); d.text((px - 14, py - 5), f"{NAMES[t]}{r}", fill=(255, 255, 255))
im.save(sys.argv[2]); print('saved', W, H)
