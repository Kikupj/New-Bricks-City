# Night-city art for map C01 (procedural, deterministic):
#   textures/  lit-window facades (CWN*), boundary textures (fence, railing, sea wall, viaduct, deck ...), rail flats
#   brightmaps/city/  fullbright masks for the lit windows (registered in gldefs.txt)
#   sprites/cityskyline/CSKYA0..F0.png  skyline billboards (layer 2)
#   textures/CITYSKY.png  panoramic skyline sky (layer 3)
# Run:  python make_city_assets.py            (writes into ../CorpoWars)
import os, struct, zlib, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.environ.get("CW_ROOT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars")
TEX = os.path.join(ROOT, "textures"); BM = os.path.join(ROOT, "brightmaps", "city"); SPR = os.path.join(ROOT, "sprites", "cityskyline")
for d in (TEX, BM, SPR): os.makedirs(d, exist_ok=True)
R = random.Random(20260929); NR = np.random.default_rng(20260929)
SKY_HORIZON_ROW = int(os.environ.get("CW_SKY_HORIZON", "0"))        # debug: draw a marker row (see sky())

def save_rgb(im, name, bm=None):
    im.convert("RGB").save(os.path.join(TEX, name + ".png"))
    if bm is not None: bm.convert("L").save(os.path.join(BM, name + ".png"))

def grain(a, amt):
    return np.clip(a + NR.normal(0, amt, a.shape[:2] + (1,)), 0, 255)

def blot(w, h, cell=16, amt=10):
    """smooth low-frequency luminance variation, tileable-ish enough for walls"""
    sm = NR.normal(0, 1, (h // cell + 2, w // cell + 2))
    im = Image.fromarray(((sm - sm.min()) / (np.ptp(sm) + 1e-6) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return (np.asarray(im, float) / 255 - 0.5)[:, :, None] * amt * 2

WARM = [(255, 214, 140), (255, 196, 110), (255, 226, 170), (250, 180, 90)]
COOL = [(190, 222, 255), (170, 210, 250), (220, 240, 255)]
TEAL = [(140, 240, 220), (120, 220, 235)]

def lit_col(kind):
    r = R.random()
    if kind == 'tower': return R.choice(COOL if r < 0.5 else (WARM if r < 0.85 else TEAL))
    return R.choice(WARM if r < 0.85 else COOL)

# ------------------------------------------------------------------ facades, round 3 (2x scale): ONE STOREY = 128 units
# upper tiles are 256 x 128 (one storey tall, 4-5 bays), ground rows are 256 x 128 too (shopfront / lobby / service).
# Windows are 40-56 wide x 64-80 tall. Styles: G glass (Meridian) E campus (Eastgate) D docks (Ironside) Q old quarter H highline.
STY = {
 # base colours per kind (A tower, B office, C res, D ind, E civic, F fill), dark glass, lit palette weights, lit prob scale
 'G': dict(base=dict(A=(20, 28, 42), B=(58, 62, 70), C=(84, 70, 60), D=(40, 44, 52), E=(108, 106, 100), F=(22, 26, 36)), glass=(30, 46, 70), lit=1.0, trim=(14, 18, 26)),
 'E': dict(base=dict(A=(92, 98, 108), B=(104, 108, 112), C=(112, 94, 78), D=(96, 100, 104), E=(110, 62, 52), F=(84, 88, 94)), glass=(34, 60, 72), lit=0.8, trim=(60, 66, 72)),
 'D': dict(base=dict(A=(38, 48, 58), B=(72, 74, 76), C=(92, 54, 46), D=(66, 72, 66), E=(96, 86, 70), F=(50, 54, 52)), glass=(26, 38, 46), lit=0.7, trim=(30, 30, 30)),
 'Q': dict(base=dict(A=(96, 60, 50), B=(88, 66, 56), C=(104, 60, 46), D=(74, 48, 42), E=(122, 100, 76), F=(80, 52, 44)), glass=(28, 30, 40), lit=1.0, trim=(44, 30, 26)),
 'H': dict(base=dict(A=(50, 56, 64), B=(74, 76, 80), C=(84, 84, 82), D=(64, 66, 70), E=(88, 90, 94), F=(60, 62, 66)), glass=(24, 32, 40), lit=0.75, trim=(36, 38, 42)),
}
LITP = {'A': 0.42, 'B': 0.36, 'C': 0.40, 'D': 0.22, 'E': 0.6, 'F': 0.3}

def brick(d, W, H, mortar, size=(16, 8)):
    for y in range(0, H, size[1]):
        d.line((0, y, W, y), fill=mortar)
        for x in range(((y // size[1]) % 2) * (size[0] // 2), W, size[0]): d.line((x, y, x, y + size[1] - 1), fill=mortar)

def _storey(style, kind, variant=0):
    S = STY[style]; W, H = 256, 128
    base = np.array(S['base'][kind], float)
    a = np.ones((H, W, 3)) * base + blot(W, H, 24, 5)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    bmi = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bmi)
    trim = S['trim']
    litp = LITP[kind] * S['lit']
    def pane(x0, y0, x1, y1, lit=None, dark=None):
        dark = dark or tuple(int(v + R.randint(-4, 8)) for v in S['glass'])
        if lit is None: lit = R.random() < litp
        if lit:
            c = lit_col('tower' if style == 'G' and kind == 'A' else 'x'); k = R.uniform(0.7, 1.0)
            c = tuple(int(v * k) for v in c)
            d.rectangle((x0, y0, x1, y1), fill=c); bd.rectangle((x0, y0, x1, y1), fill=int(255 * k))
            d.rectangle((x0, y0, x1, y0 + 5), fill=tuple(int(v * 0.72) for v in c))         # blind / ceiling shadow
            if R.random() < 0.5: d.rectangle((x0 + (x1 - x0) // 3, y0 + 8, x0 + (x1 - x0) // 3 + 3, y1 - 6), fill=tuple(int(v * 0.6) for v in c))
        else:
            d.rectangle((x0, y0, x1, y1), fill=dark)
            d.line((x0, y0, x1, y0 + 6), fill=tuple(min(255, v + 12) for v in dark))       # sky reflection
            d.line((x0 + 1, y0, x1, y0 + 8), fill=tuple(min(255, v + 8) for v in dark))
    if kind == 'A':                                     # curtain wall: 4 bays x 64, glazing 52 x 80
        d.rectangle((0, 0, W, H), fill=trim)
        for b in range(4):
            x = b * 64
            for i in range(2):
                pane(x + 6 + i * 0, 24, x + 58, 104) if i == 0 else None
        d.rectangle((0, 0, W, 3), fill=tuple(min(255, v + 30) for v in trim))
        d.rectangle((0, 108, W, 128), fill=tuple(int(v * 0.8) for v in trim))
        for x in range(0, W, 64): d.rectangle((x + 58, 24, x + 63, 104), fill=tuple(min(255, v + 18) for v in trim))
    elif kind == 'B':                                   # office: 5 bays, pane 40 x 72, lintel + sill
        bw = W / 5.0
        for b in range(5):
            x = int(b * bw + (bw - 40) / 2)
            d.rectangle((x - 4, 22, x + 44, 26), fill=tuple(min(255, v + 26) for v in base.astype(int)))
            pane(x, 28, x + 40, 100)
            d.line((x + 20, 28, x + 20, 100), fill=trim)
            d.rectangle((x - 4, 100, x + 44, 104), fill=tuple(min(255, v + 34) for v in base.astype(int)))
        d.rectangle((0, 0, W, 5), fill=tuple(int(v * 0.7) for v in base.astype(int)))
    elif kind == 'C':                                   # residential: brick, 4 bays, pane 40 x 68 + sill, some balconies
        brick(d, W, H, tuple(int(v * 0.68) for v in base.astype(int)))
        for b in range(4):
            x = b * 64 + 12
            d.rectangle((x - 3, 27, x + 43, 99), fill=trim)
            pane(x, 30, x + 40, 97)
            d.line((x + 20, 30, x + 20, 97), fill=trim); d.line((x, 62, x + 40, 62), fill=trim)
            d.rectangle((x - 5, 99, x + 45, 104), fill=tuple(min(255, v + 40) for v in base.astype(int)))
            if (b + variant) % 3 == 1:
                d.rectangle((x - 6, 108, x + 46, 110), fill=(30, 30, 34))
                for rx in range(x - 6, x + 47, 6): d.line((rx, 110, rx, 124), fill=(30, 30, 34))
    elif kind == 'D':                                   # industrial cladding: corrugation, high strip windows 56 x 64
        for x in range(0, W, 4):
            k = (x // 4 % 2) * 10
            d.line((x, 0, x, H), fill=tuple(int(v + k - 5) for v in base.astype(int)))
        d.rectangle((0, 108, W, 128), fill=tuple(int(v * 0.8) for v in base.astype(int)))
        for b in range(3):
            x = int(b * 85.3 + 14)
            d.rectangle((x - 3, 30, x + 59, 98), fill=trim)
            pane(x, 33, x + 56, 96)
            for gx in range(x, x + 57, 8): d.line((gx, 33, gx, 96), fill=trim)
    elif kind == 'E':                                   # civic: pilasters, tall arched windows 40 x 80
        d.rectangle((0, 0, W, 8), fill=tuple(min(255, v + 22) for v in base.astype(int)))
        d.rectangle((0, 8, W, 10), fill=tuple(int(v * 0.6) for v in base.astype(int)))
        for b in range(4):
            x = b * 64
            d.rectangle((x, 10, x + 10, H), fill=tuple(min(255, v + 16) for v in base.astype(int)))
            d.rectangle((x + 11, 10, x + 11, H), fill=tuple(int(v * 0.6) for v in base.astype(int)))
            wx = x + 16
            pane(wx, 34, wx + 40, 104)
            d.pieslice((wx, 14, wx + 40, 54), 180, 360, fill=tuple(int(v * 0.5) for v in base.astype(int)))
            lit = R.random() < litp
            c = lit_col('x') if lit else S['glass']
            d.pieslice((wx + 2, 16, wx + 38, 52), 180, 360, fill=tuple(int(v * R.uniform(0.7, 1)) for v in c) if lit else S['glass'])
            if lit: bd.pieslice((wx + 2, 16, wx + 38, 52), 180, 360, fill=230)
            d.rectangle((wx - 3, 104, wx + 43, 108), fill=tuple(min(255, v + 30) for v in base.astype(int)))
    else:                                               # F: low-lit generic ribbon of 44 x 72 panes
        for b in range(4):
            x = b * 64 + 10
            d.rectangle((x - 2, 26, x + 46, 100), fill=trim)
            pane(x, 28, x + 44, 99)
        d.rectangle((0, 108, W, 128), fill=tuple(int(v * 0.85) for v in base.astype(int)))
    a = np.asarray(im, float)
    a = grain(a, 2.5)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), bmi

def upper(style, kind, variant=0):
    """4 storeys tall (256 x 512): every storey has its own lit pattern so the wall does not repeat visibly"""
    ims = []; bms = []
    for r in range(4):
        im, bm = _storey(style, kind, variant + r)
        ims.append(im); bms.append(bm)
    big = Image.new("RGB", (256, 512)); bigm = Image.new("L", (256, 512))
    for r in range(4): big.paste(ims[r], (0, r * 128)); bigm.paste(bms[r], (0, r * 128))
    # guarantee some lit panes on every storey pair: if a storey has none, light one bay
    return big, bigm

def ground(style, kind):
    """ground-floor row: A retail shopfronts, B lobby, C service / loading. y=0 is the top of the ground floor, y=128 the sidewalk."""
    S = STY[style]; W, H = 256, 128
    base = np.array(S['base']['B' if kind != 'C' else 'D'], float) * 0.92
    a = np.ones((H, W, 3)) * base + blot(W, H, 20, 5)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    bmi = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bmi)
    trim = S['trim']
    if style in ('Q', 'D') and kind != 'C': brick(d, W, H, tuple(int(v * 0.66) for v in base.astype(int)))
    d.rectangle((0, 112, W, H), fill=tuple(int(v * 0.55) for v in base.astype(int)))            # kick plate
    d.line((0, 112, W, 112), fill=tuple(min(255, int(v * 1.3)) for v in base.astype(int)))
    if kind == 'A':
        for b in range(2):
            x = b * 128
            col = R.choice(WARM + COOL[:1]); k = R.uniform(0.75, 1.0); col = tuple(int(v * k) for v in col)
            d.rectangle((x + 8, 34, x + 120, 111), fill=trim)
            d.rectangle((x + 12, 38, x + 116, 110), fill=col); bd.rectangle((x + 12, 38, x + 116, 110), fill=int(200 * k))
            d.line((x + 64, 38, x + 64, 110), fill=trim, width=2)
            for sy in (64, 90):                                                                  # shelves / displays
                d.rectangle((x + 16, sy, x + 60, sy + 3), fill=tuple(int(v * 0.5) for v in col))
            d.rectangle((x + 76, 60, x + 108, 110), fill=tuple(int(v * 0.72) for v in col))       # door
            aw = [(200, 60, 50), (50, 120, 90), (60, 90, 170), (210, 160, 50)][(b + R.randint(0, 3)) % 4]
            for sx in range(x + 6, x + 122, 12): d.rectangle((sx, 22, sx + 5, 33), fill=aw); d.rectangle((sx + 6, 22, sx + 11, 33), fill=tuple(int(v * 0.5) for v in aw))
            d.rectangle((x + 8, 6, x + 120, 20), fill=(16, 18, 22)); d.rectangle((x + 14, 9, x + 114, 17), fill=(255, 220, 140)); bd.rectangle((x + 14, 9, x + 114, 17), fill=255)
    elif kind == 'B':
        d.rectangle((0, 0, W, 14), fill=tuple(int(v * 0.6) for v in base.astype(int)))
        d.rectangle((70, 18, 186, 111), fill=trim)
        for pxl in range(74, 182, 36):
            k = R.uniform(0.8, 1.0)
            d.rectangle((pxl, 22, pxl + 32, 110), fill=(int(236 * k), int(214 * k), int(160 * k))); bd.rectangle((pxl, 22, pxl + 32, 110), fill=int(230 * k))
            d.line((pxl + 16, 22, pxl + 16, 110), fill=trim)
        d.rectangle((70, 60, 186, 63), fill=(120, 126, 136))
        for cx in (16, 44, 212, 240):                                                             # columns
            d.rectangle((cx - 8, 14, cx + 8, 111), fill=tuple(min(255, int(v * 1.25)) for v in base.astype(int)))
        for wx in (8, 200):
            pxl = wx
            d.rectangle((pxl, 40, pxl + 40, 104), fill=S['glass']); d.line((pxl, 40, pxl + 40, 60), fill=tuple(min(255, v + 12) for v in S['glass']))
        d.rectangle((92, 3, 164, 11), fill=(14, 16, 20)); d.rectangle((96, 5, 160, 9), fill=(200, 255, 240)); bd.rectangle((96, 5, 160, 9), fill=255)
    else:
        for b in range(2):
            x = b * 128
            d.rectangle((x + 10, 26, x + 106, 111), fill=(46, 48, 54))
            for sy in range(28, 111, 6): d.line((x + 10, sy, x + 106, sy), fill=(64, 66, 74))
            d.rectangle((x + 10, 22, x + 106, 26), fill=(20, 20, 22))
            for k in range(x + 10, x + 100, 14): d.polygon([(k, 106), (k + 7, 106), (k + 12, 111), (k + 5, 111)], fill=(230, 190, 30))
            d.rectangle((x + 112, 44, x + 124, 111), fill=(30, 32, 38))
        d.rectangle((108, 3, 116, 10), fill=(255, 190, 90)); bd.rectangle((108, 3, 116, 10), fill=255)
        d.rectangle((236, 3, 244, 10), fill=(255, 190, 90)); bd.rectangle((236, 3, 244, 10), fill=255)
    d.rectangle((0, 0, W, 2), fill=tuple(int(v * 0.4) for v in base.astype(int)))
    a = grain(np.asarray(im, float), 2.5)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), bmi

def door_wall():                       # the recess back wall: 128 x 128 (floor 8 -> 136), glazed door, lit lintel
    W, H = 128, 128
    a = np.ones((H, W, 3)) * np.array((30, 33, 42), float) + blot(W, H, 32, 5)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    bm = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bm)
    d.rectangle((14, 26, W - 15, H - 1), fill=(150, 156, 168))
    d.rectangle((20, 32, W - 21, H - 1), fill=(236, 196, 124)); bd.rectangle((20, 32, W - 21, H - 1), fill=255)
    for y in range(32, H, 3):
        k = 1.0 - (y - 32) / 300.0
        d.line((20, y, W - 21, y), fill=(int(236 * k), int(196 * k), int(124 * k)))
    d.rectangle((W // 2 - 1, 32, W // 2 + 1, H - 1), fill=(150, 156, 168))
    d.rectangle((W // 2 - 9, 74, W // 2 - 6, 100), fill=(60, 64, 72)); d.rectangle((W // 2 + 6, 74, W // 2 + 9, 100), fill=(60, 64, 72))
    d.rectangle((12, 14, W - 13, 19), fill=(200, 255, 240)); bd.rectangle((12, 14, W - 13, 19), fill=255)      # lit lintel
    d.rectangle((0, H - 3, W, H), fill=(70, 72, 80))
    return im, bm

def door_side():
    a = np.ones((128, 64, 3)) * np.array((40, 42, 52), float) + blot(64, 128, 16, 4)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    d.rectangle((0, 12, 63, 16), fill=(200, 255, 240)); bm = Image.new("L", (64, 128), 0); ImageDraw.Draw(bm).rectangle((0, 12, 63, 16), fill=200)
    d.line((0, 0, 0, 127), fill=(20, 22, 26))
    return im, bm

# ------------------------------------------------------------------ round 3 extras: water, ships, cranes, gateway portals
def tileable_noise(n, cell):
    f = NR.normal(0, 1, (n, n)); F = np.fft.fft2(f)
    fx = np.fft.fftfreq(n)[:, None]; fy = np.fft.fftfreq(n)[None, :]
    g = np.exp(-(fx ** 2 + fy ** 2) * (2 * np.pi * cell) ** 2 / 2)
    r = np.real(np.fft.ifft2(F * g)); return (r - r.mean()) / (r.std() + 1e-9)

def tex_water():                      # night harbour water: dark, desaturated, tileable 256 x 256, faint ripples + lamp glints
    n = 256
    a = np.ones((n, n, 3)) * np.array((22, 34, 42), float)
    r1 = tileable_noise(n, 10); r2 = tileable_noise(n, 3)
    a += (r1[:, :, None] * 5.0 + r2[:, :, None] * 2.2) * np.array((0.7, 1.0, 1.15))
    yy, xx = np.mgrid[0:n, 0:n]
    swell = np.sin(2 * np.pi * (xx * 3 + yy * 5) / n) * 0.5 + np.sin(2 * np.pi * (xx * 1 - yy * 2) / n) * 0.5
    a += swell[:, :, None] * 2.0
    hl = (r2 > 1.7) & (r1 > 0.1)
    a[hl] += np.array((46, 56, 62))
    return to_im(grain(a, 1.4))

def tex_asph():                       # road asphalt 128 x 128
    a = noisy(128, 128, (40, 42, 46), 5, 12)
    for i in range(900):
        x, y = NR.integers(0, 128, 2); a[y, x] = a[y, x] * NR.uniform(0.7, 1.35)
    im = to_im(a); d = ImageDraw.Draw(im)
    for i in range(3):
        x = R.randrange(0, 128); y = R.randrange(0, 128)
        for k in range(R.randrange(10, 30)):
            x += R.randrange(-2, 3); y += R.randrange(0, 3); d.point((x % 128, y % 128), fill=(22, 22, 26))
    return im

def tex_pave():                       # sidewalk slabs 128 x 128
    a = noisy(128, 128, (84, 84, 82), 6, 16)
    im = to_im(a); d = ImageDraw.Draw(im)
    for k in (0, 64): d.line((k, 0, k, 128), fill=(48, 48, 50), width=2); d.line((0, k, 128, k), fill=(48, 48, 50), width=2)
    return im

def tex_hull():                       # ship hull: 256 x 256, lower texture on a 232-tall face (bulwark at the top, waterline at the bottom)
    W, H = 256, 256
    a = noisy(W, H, (70, 30, 28), 5, 24)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bm)
    d.rectangle((0, 0, W, 34), fill=(52, 54, 60)); d.rectangle((0, 34, W, 38), fill=(200, 200, 200))
    for x in range(0, W, 16): d.line((x, 4, x, 34), fill=(36, 38, 42))
    for y in range(64, 190, 14):
        for x in range(10, W, 44): d.rectangle((x, y, x + 5, y + 5), fill=(24, 20, 20))
    for x in range(20, W, 88): d.rectangle((x, 90, x + 9, 99), fill=(255, 210, 120)); bd.rectangle((x, 90, x + 9, 99), fill=255)
    d.rectangle((0, 190, W, 212), fill=(28, 20, 22)); d.rectangle((0, 212, W, H), fill=(14, 18, 16))
    for x in range(0, W, 3): d.point((x, 200 + (x % 7)), fill=(90, 40, 30))
    return im, bm

def tex_cont():                       # cabin / container stack: 128 x 256
    W, H = 128, 256
    a = noisy(W, H, (150, 152, 150), 4, 16)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bm)
    for r in range(0, H, 64):
        col = [(170, 60, 40), (50, 90, 150), (200, 160, 40), (60, 120, 80)][(r // 64 + 1) % 4]
        d.rectangle((0, r + 2, W, r + 62), fill=col)
        for x in range(4, W, 8): d.line((x, r + 4, x, r + 60), fill=tuple(int(v * 0.7) for v in col))
        d.line((0, r, W, r), fill=(20, 20, 20), width=2)
    for x in range(8, W - 8, 24):
        d.rectangle((x, 16, x + 14, 26), fill=(255, 226, 150)); bd.rectangle((x, 16, x + 14, 26), fill=255)
    return im, bm

def tex_crane():                      # lattice steel tower: 64 x 256, yellow
    W, H = 64, 256
    im = Image.new("RGB", (W, H), (58, 62, 70)); d = ImageDraw.Draw(im); bm = Image.new("L", (W, H), 0); bd = ImageDraw.Draw(bm)
    for y in range(0, H, 32):
        d.line((4, y, 60, y + 32), fill=(214, 170, 30), width=3); d.line((60, y, 4, y + 32), fill=(214, 170, 30), width=3)
        d.line((4, y, 60, y), fill=(190, 150, 26), width=3)
    d.rectangle((0, 0, 5, H), fill=(214, 170, 30)); d.rectangle((58, 0, 64, H), fill=(214, 170, 30))
    for y in (16, 144): d.ellipse((28, y, 36, y + 8), fill=(255, 60, 40)); bd.ellipse((28, y, 36, y + 8), fill=255)
    return im, bm

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
def font(sz):
    from PIL import ImageFont
    try: return ImageFont.truetype(FONT_B, sz)
    except Exception: return ImageFont.load_default()

def portal(gt, target):
    """gateway back-wall graphics, 384 wide; heights match the carved geometry (tunnel 512, ramp 520, metro 128, bridge 504)"""
    import citydist as CD
    name = CD.PROFILES[target]['name'].upper()
    short = name.split()[0] if len(name) > 18 else name
    W = 384
    Hh = {'T': 512, 'R': 520, 'M': 128, 'B': 504}[gt]
    a = noisy(W, Hh, (54, 56, 62), 6, 24)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (W, Hh), 0); bd = ImageDraw.Draw(bm)
    if gt == 'T':
        d.rectangle((0, 0, W, Hh), fill=(58, 60, 66))
        for y in range(0, Hh, 64): d.line((0, y, W, y), fill=(40, 42, 48), width=2)
        d.rectangle((24, 120, W - 24, Hh), fill=(6, 6, 10)); d.pieslice((24, 40, W - 24, 400), 180, 360, fill=(6, 6, 10))
        d.arc((16, 32, W - 16, 408), 180, 360, fill=(180, 170, 120), width=8)
        for i in range(9):                                             # lamp strip along the arch
            ang = 3.14159 * (i + 1) / 10
            import math
            cx = W / 2 - math.cos(ang) * 150; cy = 220 - math.sin(ang) * 160
            d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(255, 210, 120)); bd.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=255)
        d.rectangle((70, 236, W - 70, Hh), fill=(14, 14, 20))
        d.line((W // 2, 420, W // 2, Hh), fill=(230, 220, 120), width=4)
        d.rectangle((60, 6, W - 60, 40), fill=(16, 60, 44)); d.text((W // 2, 23), "ROAD TUNNEL  " + short, font=font(20), fill=(240, 250, 240), anchor="mm")
        bd.text((W // 2, 23), "ROAD TUNNEL  " + short, font=font(20), fill=255, anchor="mm")
        for k in range(0, W, 32): d.polygon([(k, Hh - 20), (k + 16, Hh - 20), (k + 30, Hh), (k + 14, Hh)], fill=(230, 190, 30))
    elif gt == 'R':
        d.rectangle((0, 0, W, Hh), fill=(48, 52, 58))
        d.rectangle((24, 24, W - 24, 240), fill=(14, 92, 52)); d.rectangle((30, 30, W - 30, 234), outline=(240, 240, 240), width=4)
        d.text((W // 2, 92), "HIGHWAY", font=font(30), fill=(245, 245, 245), anchor="mm"); bd.text((W // 2, 92), "HIGHWAY", font=font(30), fill=180, anchor="mm")
        d.text((W // 2, 140), short, font=font(26 if len(short) < 12 else 20), fill=(245, 245, 245), anchor="mm"); bd.text((W // 2, 140), short, font=font(26 if len(short) < 12 else 20), fill=180, anchor="mm")
        d.polygon([(W // 2 - 50, 200), (W // 2 + 50, 200), (W // 2, 170)], fill=(245, 245, 245))
        d.rectangle((0, 280, W, 330), fill=(20, 20, 22))
        for k in range(-40, W + 40, 44): d.polygon([(k, 330), (k + 22, 330), (k + 52, 280), (k + 30, 280)], fill=(235, 190, 30))
        d.rectangle((0, 330, W, Hh), fill=(40, 42, 46)); d.rectangle((W // 2 - 4, 350, W // 2 + 4, Hh), fill=(220, 220, 120))
        for x in (40, W - 60): d.rectangle((x, 250, x + 20, 262), fill=(255, 190, 90)); bd.rectangle((x, 250, x + 20, 262), fill=255)
    elif gt == 'M':
        d.rectangle((0, 0, W, Hh), fill=(46, 50, 60))
        for x in range(0, W, 24): d.line((x, 0, x, Hh), fill=(64, 68, 78))
        d.rectangle((60, 30, W - 60, Hh), fill=(8, 8, 12)); d.rectangle((56, 26, W - 56, 34), fill=(180, 180, 190))
        d.ellipse((160, 2, 224, 66), fill=(210, 40, 40)) if False else None
        d.rectangle((20, 6, 100, 24), fill=(210, 40, 40)); d.text((60, 15), "METRO", font=font(16), fill=(255, 255, 255), anchor="mm")
        bd.rectangle((20, 6, 100, 24), fill=255)
        d.text((W - 90, 15), short, font=font(13), fill=(240, 240, 200), anchor="mm"); bd.text((W - 90, 15), short, font=font(13), fill=255, anchor="mm")
        for x in range(80, W - 70, 40): d.rectangle((x, 60, x + 24, 64), fill=(255, 230, 170)); bd.rectangle((x, 60, x + 24, 64), fill=255)
    else:
        d.rectangle((0, 0, W, Hh), fill=(44, 52, 66))
        d.rectangle((40, 0, 78, Hh), fill=(120, 130, 146)); d.rectangle((W - 78, 0, W - 40, Hh), fill=(120, 130, 146))
        for k in range(8):
            y = 60 + k * 44
            d.line((78, y, W - 78, y + 40), fill=(200, 210, 220), width=2) if k % 2 == 0 else d.line((W - 78, y, 78, y + 40), fill=(200, 210, 220), width=2)
        d.rectangle((90, 40, W - 90, 90), fill=(14, 20, 34)); d.text((W // 2, 65), "BRIDGE  " + short, font=font(16), fill=(250, 240, 200), anchor="mm")
        bd.text((W // 2, 65), "BRIDGE  " + short, font=font(16), fill=255, anchor="mm")
        for y in range(140, Hh, 90): d.ellipse((50, y, 66, y + 16), fill=(255, 200, 100)); bd.ellipse((50, y, 66, y + 16), fill=255); d.ellipse((W - 66, y, W - 50, y + 16), fill=(255, 200, 100)); bd.ellipse((W - 66, y, W - 50, y + 16), fill=255)
        d.rectangle((90, Hh - 60, W - 90, Hh), fill=(20, 22, 28))
    return to_im(grain(np.asarray(im, float), 2)), bm

# ------------------------------------------------------------------ boundary textures
def noisy(w, h, col, var=5, cell=16):
    a = np.ones((h, w, 3)) * np.array(col, float) + blot(w, h, cell, var)
    return grain(a, 2.5)

def to_im(a): return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

def tex_fence():                      # chain link, 128 x 64, RGBA
    W, H = 128, 64
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for k in range(-H, W + H, 6):
        d.line((k, 4, k + H, H), fill=(120, 130, 140, 170)); d.line((k + H, 4, k, H), fill=(120, 130, 140, 170))
    d.rectangle((0, 0, W, 3), fill=(80, 86, 94, 255))
    for x in (0, 64): d.rectangle((x, 0, x + 3, H), fill=(70, 76, 84, 255))
    return im

def tex_rail():                       # railing 128 x 56
    W, H = 128, 56
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, W, 4), fill=(58, 64, 74, 255)); d.rectangle((0, 26, W, 28), fill=(48, 52, 60, 255))
    for x in range(0, W, 8): d.rectangle((x, 4, x + 1, H), fill=(40, 44, 52, 235))
    for x in (0, 64): d.rectangle((x, 0, x + 5, H), fill=(70, 76, 86, 255))
    return im

def tex_barr():                       # road-closed barricade 128 x 48
    W, H = 128, 48
    a = noisy(W, H, (60, 62, 68), 4)
    im = to_im(a); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, W, 26), fill=(20, 20, 22))
    for k in range(-30, W + 30, 20): d.polygon([(k, 26), (k + 10, 26), (k + 26, 0), (k + 16, 0)], fill=(235, 190, 30))
    d.rectangle((0, 27, W, 29), fill=(200, 40, 30))
    return im

def tex_jersey():                     # 64 x 64
    a = noisy(64, 64, (88, 90, 94), 6)
    im = to_im(a); d = ImageDraw.Draw(im)
    d.rectangle((0, 40, 63, 44), fill=(170, 150, 40)); d.line((0, 0, 0, 63), fill=(52, 54, 58)); d.line((63, 0, 63, 63), fill=(52, 54, 58))
    d.rectangle((0, 56, 63, 63), fill=(64, 66, 70))
    return im

def tex_seawall():                    # 128 x 128
    a = noisy(128, 128, (70, 72, 78), 7)
    im = to_im(a); d = ImageDraw.Draw(im)
    for y in range(0, 128, 32):
        d.line((0, y, 128, y), fill=(34, 36, 42), width=2)
        for x in range(((y // 32) % 2) * 32, 128, 64): d.line((x, y, x, y + 31), fill=(34, 36, 42), width=2)
    a = np.asarray(im, float)
    wet = np.linspace(0.0, 1.0, 128)[:, None, None] ** 2          # darker toward the bottom (waterline)
    a = a * (1 - 0.45 * wet) + np.array([0, 4, 8]) * wet
    return to_im(grain(a, 2))

def tex_retain():                     # 128 x 128 retaining wall
    a = noisy(128, 128, (92, 96, 104), 7, 24)
    im = to_im(a); d = ImageDraw.Draw(im)
    for x in range(0, 128, 64): d.line((x, 0, x, 128), fill=(30, 32, 36), width=2)
    for x in (10, 44, 90): d.rectangle((x, 0, x + 2, 128), fill=(44, 46, 50))     # drainage streaks
    d.rectangle((0, 0, 128, 3), fill=(80, 82, 86))
    return im

def tex_deck():                       # deck underside / edge beam 128 x 128 (+ brightmap: sodium lamps under the deck)
    a = noisy(128, 128, (84, 88, 98), 5, 24)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (128, 128), 0); bd = ImageDraw.Draw(bm)
    for y in (0, 40, 80, 120): d.rectangle((0, y, 128, y + 5), fill=(50, 54, 60)); d.line((0, y + 6, 128, y + 6), fill=(120, 124, 132))
    for x in range(0, 128, 32): d.line((x, 6, x + 16, 40), fill=(56, 60, 66), width=2); d.line((x + 16, 40, x + 32, 6), fill=(56, 60, 66), width=2)
    for x in (16, 80):
        d.rectangle((x, 46, x + 22, 52), fill=(255, 190, 90)); bd.rectangle((x, 46, x + 22, 52), fill=255)
    return im, bm

def tex_pillar():                     # 64 x 128
    a = noisy(64, 128, (66, 68, 72), 6, 24)
    im = to_im(a); d = ImageDraw.Draw(im)
    for x in (16, 48): d.line((x, 0, x, 128), fill=(46, 48, 52), width=2)
    for k in range(0, 64, 16): d.polygon([(k, 128), (k + 8, 128), (k + 20, 108), (k + 12, 108)], fill=(200, 170, 40))
    d.rectangle((0, 100, 64, 107), fill=(30, 30, 30))
    return im

def tex_viaduct():                    # brick + arches 128 x 128 (+ brightmap: lamp in every arch)
    a = noisy(128, 128, (104, 68, 60), 7)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (128, 128), 0); bd = ImageDraw.Draw(bm)
    for y in range(0, 128, 8):
        d.line((0, y, 128, y), fill=(36, 26, 24))
        for x in range((y // 8 % 2) * 8, 128, 16): d.line((x, y, x, y + 7), fill=(36, 26, 24))
    d.rectangle((20, 50, 108, 128), fill=(10, 10, 14)); d.pieslice((20, 26, 108, 74), 180, 360, fill=(10, 10, 14))
    d.arc((16, 22, 112, 78), 180, 360, fill=(120, 96, 84), width=3)
    d.rectangle((0, 0, 128, 5), fill=(120, 120, 128))
    d.rectangle((58, 40, 70, 46), fill=(255, 200, 110)); bd.rectangle((58, 40, 70, 46), fill=255)
    for x in (24, 96):
        d.rectangle((x, 100, x + 8, 104), fill=(255, 180, 90)); bd.rectangle((x, 100, x + 8, 104), fill=255)
    return im, bm

def tex_train():                      # passenger car side 128 x 96 (+ brightmap: lit windows)
    a = noisy(128, 96, (58, 66, 84), 4)
    im = to_im(a); d = ImageDraw.Draw(im); bm = Image.new("L", (128, 96), 0); bd = ImageDraw.Draw(bm)
    d.rectangle((0, 0, 128, 14), fill=(120, 124, 134)); d.rectangle((0, 78, 128, 96), fill=(34, 36, 44))
    d.rectangle((0, 70, 128, 76), fill=(210, 60, 50))
    for x in range(4, 128, 32):
        d.rectangle((x, 24, x + 24, 56), fill=(255, 236, 190)); bd.rectangle((x, 24, x + 24, 56), fill=255)
        d.line((x + 12, 24, x + 12, 56), fill=(80, 84, 96))
    d.line((0, 15, 128, 15), fill=(30, 32, 40))
    return im, bm

def tex_plank():                      # pier planks (flat, 64 x 64)
    a = noisy(64, 64, (86, 64, 44), 9, 6)
    im = to_im(a); d = ImageDraw.Draw(im)
    for y in range(0, 64, 8): d.line((0, y, 64, y), fill=(34, 24, 16), width=1)
    for y in range(0, 64, 16):
        for x in (R.randrange(8, 56),): d.line((x, y, x, y + 7), fill=(34, 24, 16))
    return im

def tex_edge():
    return to_im(np.ones((64, 64, 3)) * np.array((8, 12, 22), float))

def flat_rail(horizontal):            # 64 x 64 ballast + rails + sleepers
    a = noisy(64, 64, (74, 70, 66), 12, 4)
    for i in range(400):
        x, y = NR.integers(0, 64, 2); a[y, x] = a[y, x] * NR.uniform(0.6, 1.3)
    im = to_im(a); d = ImageDraw.Draw(im)
    for x in range(2, 64, 10): d.rectangle((x, 8, x + 4, 56), fill=(58, 42, 30))
    d.rectangle((0, 14, 64, 16), fill=(150, 154, 162)); d.rectangle((0, 46, 64, 48), fill=(150, 154, 162))
    d.line((0, 17, 64, 17), fill=(60, 60, 64)); d.line((0, 49, 64, 49), fill=(60, 60, 64))
    return im if horizontal else im.transpose(Image.TRANSPOSE)

# ------------------------------------------------------------------ skyline sprites + sky (layers 2 and 3)
HAZE = (54, 70, 108)

def towers(W, H, count, hmin, hmax, seed, detail=1.0, ss=2, U=1):
    """Cluster of lit towers on a transparent background. Returns an RGBA image (W x H)."""
    r = random.Random(seed)
    w2, h2 = W * ss, H * ss
    im = Image.new("RGBA", (w2, h2), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = r.randint(8 * U, 30 * U) * ss
    lay = []
    while x < w2:
        bw = r.randint(int(28 * detail * U), int(110 * detail * U)) * ss
        bh = int(r.uniform(hmin, hmax) * (0.5 + 0.5 * r.random() ** 0.6)) * ss
        gap = r.choice([0, 0, 4, 10, 24]) * ss * U
        lay.append((x, bw, bh)); x += bw + gap
    lay.sort(key=lambda t: -t[2])
    order = lay
    for (x, bw, bh) in order:
        y0 = h2 - bh
        shade = r.uniform(0.75, 1.15)
        body = tuple(int(c * shade) for c in (22, 28, 44))
        d.rectangle((x, y0, x + bw, h2), fill=body + (255,))
        # setback crown
        if r.random() < 0.6:
            cw = bw * r.uniform(0.4, 0.7); ch = int(bh * r.uniform(0.06, 0.16))
            cx = x + (bw - cw) / 2
            d.rectangle((cx, y0 - ch, cx + cw, y0), fill=body + (255,))
            y0c = y0 - ch
            if r.random() < 0.5:
                d.rectangle((cx + cw / 2 - 2 * ss * U, y0c - r.randint(20, 60) * ss * U, cx + cw / 2 + 2 * ss * U, y0c), fill=body + (255,))
                ay = y0c - 50 * ss
        # windows
        cell = int(r.choice([6, 7, 8]) * ss * U * 0.75); litp = r.uniform(0.18, 0.5)
        col = r.choice([WARM, COOL, WARM])
        for wy in range(y0 + 4 * ss * U, h2 - 4 * ss * U, cell):
            rowbias = r.random()
            for wx in range(x + 3 * ss * U, x + bw - 4 * ss * U, cell):
                if r.random() < litp * (0.4 + rowbias):
                    c = r.choice(col); k = r.uniform(0.7, 1.0)
                    d.rectangle((wx, wy, wx + cell // 2 - 1, wy + cell // 2), fill=tuple(int(v * k) for v in c) + (255,))
        # warning light
        if r.random() < 0.5:
            tx = x + bw // 2; d.ellipse((tx - 1 * ss * U, y0 - 3 * ss * U, tx + 1 * ss * U, y0 - 1 * ss * U), fill=(255, 60, 40, 255))
    # atmospheric haze: fade toward the haze colour near the bottom and slightly overall
    arr = np.asarray(im, float)
    ys = np.linspace(0, 1, h2)[:, None]
    hz = np.clip((ys - (0.35)) / 0.65, 0, 1) ** 1.3 * 0.75 + 0.12
    for c in range(3):
        arr[:, :, c] = arr[:, :, c] * (1 - hz) + HAZE[c] * hz * (arr[:, :, 3] > 0)
    out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").resize((W, H), Image.LANCZOS)
    return out

def save_sprite(im, name):
    p = os.path.join(SPR, name + ".png"); im.save(p)
    d = open(p, "rb").read()
    body = b"grAb" + struct.pack(">ii", im.size[0] // 2, im.size[1] - 2)
    chunk = struct.pack(">I", 8) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)
    open(p, "wb").write(d[:33] + chunk + d[33:])

SKY_HR = 212        # texture row that lands on the horizon at pitch 0 in UZDoom (measured with the CW_SKY_HORIZON debug grid)

def sky():
    W, H = 1024, 256
    HR = SKY_HR
    a = np.zeros((H, W, 3), float)
    top, mid, hor = np.array((5, 8, 20), float), np.array((14, 22, 48), float), np.array((62, 64, 96), float)
    for y in range(H):
        t = min(1.0, y / float(HR))
        if t < 0.55: c = top + (mid - top) * (t / 0.55)
        else: c = mid + (hor - mid) * ((t - 0.55) / 0.45) ** 1.6
        if y > HR: c = hor * 0.55                                     # below the horizon: haze over the far ground
        a[y, :, :] = c
    xs = np.arange(W)[None, :]
    for cx in NR.integers(0, W, 7):                                   # light-pollution glow patches near the horizon (wrap around: no seam)
        dxw = np.minimum(np.abs(xs - cx), W - np.abs(xs - cx))
        g = np.exp(-(dxw ** 2) / (2 * 60.0 ** 2))
        prof = np.exp(-((HR - np.arange(H)) ** 2) / (2 * 34.0 ** 2))[:, None]
        a += (g * prof)[:, :, None] * np.array((34, 26, 18))
    for i in range(140):                                              # stars, only in the upper half
        x, y = NR.integers(0, W), NR.integers(0, int(HR * 0.5)); a[y, x] += NR.uniform(30, 120)
    im = to_im(a).convert("RGBA")
    SH = 44                                                           # far skyline: low silhouettes standing ON the horizon
    sk = towers(W, SH, 40, 8, 40, seed=99, detail=0.45, ss=3, U=1)
    im.alpha_composite(sk, (0, HR - SH + 1))
    d = ImageDraw.Draw(im)
    if SKY_HORIZON_ROW:
        for y in range(0, H, 16): d.line((0, y, W, y), fill=(255, 0, 0, 255)); d.text((4, y + 2), str(y), fill=(255, 255, 0, 255))
    return to_im(np.asarray(im.convert("RGB"), float))

def write_gldefs():
    g = os.path.join(ROOT, "gldefs.txt")
    if not os.path.exists(g): return
    t = open(g).read()
    b, e = "// CITY-BRIGHTMAPS-BEGIN", "// CITY-BRIGHTMAPS-END"
    if b in t: t = t[:t.index(b)].rstrip("\n") + "\n" + (t[t.index(e) + len(e):].lstrip("\n") if e in t else "")
    else:
        i = t.find("\n// City district C01: lit windows")
        if i >= 0: t = t[:i].rstrip("\n") + "\n"
    names = sorted(os.path.splitext(n)[0] for n in os.listdir(BM))
    blk = b + "\n// City district C01: lit windows / door glass / lamps are fullbright (generated by make_city_assets.py)\n" + \
          "".join('BrightMap Texture %s { Map "brightmaps/city/%s.png" }\n' % (n, n) for n in names) + e + "\n"
    open(g, "w").write(t.rstrip("\n") + "\n\n" + blk)

def main():
    import citydist as CD
    # round-3 facades: upper storeys CWU<style><A-F>, ground rows CWG<style><A-C>
    for st in STY:
        for k in "ABCDEF":
            im, bm = upper(st, k, ord(k) % 3); save_rgb(im, "CWU" + st + k, bm)
        for k in "ABC":
            im, bm = ground(st, k); save_rgb(im, "CWG" + st + k, bm)
    im, bm = door_wall(); save_rgb(im, "CWDOORWL", bm)
    im, bm = door_side(); save_rgb(im, "CWDOORSD", bm)
    for name, fn in (("CWJERSY", tex_jersey), ("CWSEAWAL", tex_seawall), ("CWRETAIN", tex_retain), ("CWDECKUN", tex_deck),
                     ("CWPILLAR", tex_pillar), ("CWVIADUC", tex_viaduct), ("CWEDGE", tex_edge), ("CWBARR", tex_barr), ("CWTRAIN", tex_train),
                     ("CWHULL", tex_hull), ("CWCONT", tex_cont), ("CWCRANE", tex_crane)):
        r = fn()
        if isinstance(r, tuple): save_rgb(r[0], name, r[1])
        else: save_rgb(r, name)
    save_rgb(tex_water(), "CWWATER"); save_rgb(tex_asph(), "CWASPH"); save_rgb(tex_pave(), "CWPAVE")
    for (dn, side, pos, gt, tgt) in CD.GATES:
        nm = "CWP%s%d" % (CD.GATE_CODE[gt], tgt)
        if os.path.exists(os.path.join(TEX, nm + ".png")) and nm in _done: continue
        im, bm = portal(CD.GATE_CODE[gt], tgt); save_rgb(im, nm, bm); _done.add(nm)
    save_rgb(tex_plank(), "CWPLANK")
    write_gldefs()
    for name, im in (("CWFENCE", tex_fence()), ("CWRAIL2", tex_rail())):
        im.save(os.path.join(TEX, name + ".png"))
    save_rgb(flat_rail(True), "CWRAILA"); save_rgb(flat_rail(False), "CWRAILB")
    sky().save(os.path.join(TEX, "CITYSKY.png"))
    for i, n in enumerate("ABCDEF"):
        hmax = [300, 360, 260, 340, 220, 380][i] * 2
        save_sprite(towers(2048, 768, 0, 180, hmax, seed=700 + i, detail=1.0, U=2), "CSKY%s0" % n)
    print("city assets written")

_done = set()
CITY_DOOR_W = 88
if __name__ == "__main__":
    main()
