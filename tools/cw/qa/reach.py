# Player-reachability flood fill over a TK dump (16u player radius, 24u steps, 56u headroom, solid things, glass).
# usage: reach.py stdout.txt [png]
import sys, numpy as np, collections
L = open(sys.argv[1], encoding='latin1').read().splitlines()
S = {}; Ls = []; Th = []; Ce = []
for l in L:
    p = l.split()
    if not p: continue
    if p[0] == 'SEC': S[int(p[1])] = (float(p[2]), float(p[3]))
    elif p[0] == 'LIN': Ls.append((float(p[1]), float(p[2]), float(p[3]), float(p[4]), int(p[5]), int(p[6]), p[7] if len(p) > 7 else '-'))
    elif p[0] == 'THG': Th.append((p[1], float(p[2]), float(p[3]), float(p[5])))
    elif p[0] == 'CEL': Ce.append((int(p[1]), int(p[2]), int(p[3]), int(p[4]), float(p[5]), float(p[6])))
import os
RAD = float(os.environ.get("RAD", 16))
GAP = float(os.environ.get("GAP", 56))          # 32 = crouching (vents / ducts)
LOCKED = os.environ.get("LOCKED") == "1"       # maglocked doors stay shut (no pass, no forcing)
G = 8; X0, Y0, N = -8, -8, 1904 // 8   # plate 1888u (G02 SZ after the roomier-core change) + margin
# sector id per grid point via point-in-polygon by scanline (reuse edges)
sec = -np.ones((N, N), int)
edges = collections.defaultdict(list)
for ax, ay, bx, by, f, b, m in Ls:
    for s in (f, b):
        if s >= 0: edges[s].append((ax, ay, bx, by))
for s, E in edges.items():
    E = np.array(E)
    if S[s][0] < -500: continue
    for row in range(N):
        y = Y0 + row * G + 0.5
        m = ((E[:, 1] <= y) & (E[:, 3] > y)) | ((E[:, 3] <= y) & (E[:, 1] > y))
        if not m.any(): continue
        e = E[m]; xs = np.sort(e[:, 0] + (y - e[:, 1]) * (e[:, 2] - e[:, 0]) / (e[:, 3] - e[:, 1]))
        for k in range(0, len(xs) - 1, 2):
            c0 = int(np.ceil((xs[k] - X0) / G)); c1 = int(np.floor((xs[k + 1] - X0) / G))
            if c1 >= c0: sec[row, max(c0, 0):min(c1, N - 1) + 1] = s
# doors are closed in the dump: treat each doorway strip as open (unless LOCKED and it's a maglocked door)
SD = set()
OBJ = {}
for l in L:
    p = l.split()
    if p and p[0] == 'SDOOR': SD.add((round(float(p[1])), round(float(p[2]))))
    if p and p[0] == 'OBJROOM': OBJ[int(p[1])] = int(p[2])
for c, x, y, r in Th:
    if c == 'CW_Door' and not (LOCKED and (round(x), round(y)) in SD):
        s0 = sec[int(round((y - Y0) / G)), int(round((x - X0) / G))]
        if s0 >= 0: S[s0] = (S[s0][0], S[s0][0] + 80)
ok = np.zeros((N, N), bool)
for r in range(N):
    for c in range(N):
        s = sec[r, c]
        if s >= 0 and S[s][1] - S[s][0] >= GAP: ok[r, c] = True
# walls: any grid point within 16 of a blocking line is not ok; blocking = one-sided, glass, step>24, gap<56
def blocking(f, b, m):
    if b < 0 or f < 0: return True
    if m == 'CWGLASS': return True
    F, B = S[f], S[b]
    return abs(F[0] - B[0]) > 24 or min(F[1], B[1]) - max(F[0], B[0]) < GAP
ys, xs = np.mgrid[0:N, 0:N]; PX = X0 + xs * G; PY = Y0 + ys * G
for ax, ay, bx, by, f, b, m in Ls:
    if not blocking(f, b, m): continue
    x0, x1 = min(ax, bx) - 16, max(ax, bx) + 16; y0, y1 = min(ay, by) - 16, max(ay, by) + 16
    c0, c1 = max(int((x0 - X0) / G), 0), min(int((x1 - X0) / G) + 1, N - 1)
    r0, r1 = max(int((y0 - Y0) / G), 0), min(int((y1 - Y0) / G) + 1, N - 1)
    px = PX[r0:r1 + 1, c0:c1 + 1]; py = PY[r0:r1 + 1, c0:c1 + 1]
    dx, dy = bx - ax, by - ay; ll = dx * dx + dy * dy or 1
    t = np.clip(((px - ax) * dx + (py - ay) * dy) / ll, 0, 1)
    d = np.hypot(px - (ax + t * dx), py - (ay + t * dy))
    ok[r0:r1 + 1, c0:c1 + 1] &= d >= RAD - 1
for c, x, y, r in Th:
    if c in ('CW_Door', 'CW_CeilingLight', 'CW_Guard', 'CW_SecuritySupervisor', 'CW_Civilian', 'CW_Scientist', 'DoomPlayer') or c.startswith('CW_F'): continue
    ok &= (np.abs(PX - x) >= r + RAD - 1) | (np.abs(PY - y) >= r + RAD - 1)
# flood from the player insertion (first PlayerPawn-ish: use TKPOS? use the transport crate's cell centre)
start = None
for c, x, y, r in Th:
    if c == 'CW_TransportAccess' and start is None: start = (x, y)
for l in L:   # prefer the player's own spot (the crate can wall off a corner pocket of its cell)
    p = l.split()
    if len(p) > 3 and p[0] == 'THG' and p[1] == 'DoomPlayer' and float(p[2]) < 1904: start = (float(p[2]), float(p[3]))
cands = [(int(round((start[1] - Y0) / G)) + dy, int(round((start[0] - X0) / G)) + dx) for dx in range(-8, 9) for dy in range(-8, 9)]
cands = [p for p in cands if 0 <= p[0] < N and 0 <= p[1] < N and ok[p]]
cands.sort(key=lambda p: -abs(p[0] - (start[1] - Y0) / G) - abs(p[1] - (start[0] - X0) / G))
seen = np.zeros((N, N), bool); q = collections.deque([cands[-1]]); seen[cands[-1]] = True
while q:
    r, c = q.popleft()
    for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        rr, cc = r + dr, c + dc
        if 0 <= rr < N and 0 <= cc < N and ok[rr, cc] and not seen[rr, cc]: seen[rr, cc] = True; q.append((rr, cc))
NAMES = "HALL OPEN OFF EXEC CONF PANTRY STOR SERV LAB IT JAN DUCT BATH STAIR ELEV FRGT CLOB RECP".split()
rooms = collections.defaultdict(list)
for i, j, r, t, x, y in Ce: rooms[r].append((t, x, y))
bad = 0
for r, cs in rooms.items():
    t = NAMES[cs[0][0]]
    if t == 'DUCT': continue
    reach = 0; tot = 0
    for _, x, y in cs:
        rr, cc = int((y - Y0) / G), int((x - X0) / G)
        win = seen[rr - 8:rr + 9, cc - 8:cc + 9]; tot += 1; reach += win.any()
    if reach < tot: print('UNREACHABLE', t, r, reach, '/', tot); bad += 1
print('rooms', len(rooms), 'unreachable', bad)
if OBJ:
    names = {1: 'STEAL', 2: 'DESTROY', 3: 'TURN'}
    for k, r in sorted(OBJ.items()):
        if r < 0 or r not in rooms: continue
        hit = any(seen[int((y - Y0) / G) - 6:int((y - Y0) / G) + 7, int((x - X0) / G) - 6:int((x - X0) / G) + 7].any() for _, x, y in rooms[r])
        print('OBJECTIVE', names[k], NAMES[rooms[r][0][0]], 'reachable' if hit else 'NOT reachable')
if len(sys.argv) > 2:
    from PIL import Image
    img = np.zeros((N, N, 3), np.uint8); img[ok] = (70, 70, 80); img[seen] = (60, 200, 90)
    Image.fromarray(img[::-1]).resize((N * 3, N * 3), Image.NEAREST).save(sys.argv[2])
