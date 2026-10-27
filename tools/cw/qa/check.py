# Walkability lint from a TK dump. usage: check.py stdout.txt
import sys
L = open(sys.argv[1], encoding='latin1').read().splitlines()
S = {}; Ls = []
dump = [l for l in L if l.startswith(('SEC', 'LIN'))]
for l in dump:
    p = l.split()
    if p[0] == 'SEC': S[int(p[1])] = (float(p[2]), float(p[3]), p[4])
    else: Ls.append((float(p[1]), float(p[2]), float(p[3]), float(p[4]), int(p[5]), int(p[6])))
bad = {}
for ax, ay, bx, by, f, b in Ls:
    if f < 0 or b < 0: continue
    F, B = S[f], S[b]
    if F[0] < -500 or B[0] < -500: continue
    if F[1] - F[0] < 56 or B[1] - B[0] < 56: continue   # one side is a wall/duct/closed
    step = abs(F[0] - B[0]); gap = min(F[1], B[1]) - max(F[0], B[0])
    key = (min(f, b), max(f, b))
    if step > 24 or gap < 56:
        bad[key] = (round((ax + bx) / 2), round((ay + by) / 2), F, B, step, gap)
for k, v in bad.items(): print('BLOCK', v)
print(len(bad), 'blocking edges')
# furniture vs doorways: any solid blocker within 36u of a door strip centre
Th = []
for l in L:
    p = l.split()
    if p and p[0] == 'THG': Th.append((p[1], float(p[2]), float(p[3]), float(p[5])))
doors = [(x, y) for c, x, y, r in Th if c == 'CW_Door']
bl = [(c, x, y, r) for c, x, y, r in Th if c not in ('CW_Door', 'CW_CeilingLight') and not c.startswith('CW_F')]
nb = 0
for dx, dy in doors:
    for c, x, y, r in bl:
        if c in ('CW_Guard',): continue
        if ((x - dx) ** 2 + (y - dy) ** 2) ** 0.5 < r + 30:
            print('DOORBLOCK', c, round(x), round(y), 'door', round(dx), round(dy)); nb += 1
print(len(doors), 'doors,', nb, 'blocked')
