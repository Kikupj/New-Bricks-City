# Generates the Corpo Wars 3D furniture kit (original art, built in code):
#   CorpoWars/textures/props/CWF*.png   material textures (pixel art, 1-2 texels per map unit)
#   CorpoWars/models/props/*.obj        low-poly box-built furniture (Doom map units)
#   CorpoWars/modeldef.props.txt        MODELDEF: one model per CW_F* actor (sprite CWMD, frame per model)
# Re-run any time: output is deterministic.
#
# Conventions (checked in-engine):
#   model space is Doom space: +x = the piece's FRONT (the side a person uses / sits at), +y = its left, +z = up,
#   origin = centre of the footprint on the floor. The actor's angle points the front.
#   OBJ is written y-up: obj(x, y, z) = doom(x, z, -y).
import os, random, math
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import texlib as T

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars")
TEXD = os.path.join(ROOT, "textures", "props")
MODD = os.path.join(ROOT, "models", "props")
os.makedirs(TEXD, exist_ok=True); os.makedirs(MODD, exist_ok=True)
FONTB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
if not os.path.exists(FONTB):
    import glob; FONTB = glob.glob("/usr/share/fonts/truetype/**/*.ttf", recursive=True)[0]
R = random.Random(2026)

# =============================================================================================== textures
TEX = {}   # name -> (w, h, texels per map unit)

def noise(im, amt, box=None, mono=True):
    px = im.load(); w, h = im.size
    x0, y0, x1, y1 = box or (0, 0, w, h)
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = px[x, y]
            if mono:
                d = R.randint(-amt, amt); px[x, y] = tuple(max(0, min(255, c + d)) for c in p[:3])
            else:
                px[x, y] = tuple(max(0, min(255, c + R.randint(-amt, amt))) for c in p[:3])
    return im

def shade(c, k): return tuple(max(0, min(255, int(v * k))) for v in c)

# Detail finish per material (applied on save): (fbm variation, variation cell, grain, grime, edge AO)
# brings the flat-drawn prop art up to the stock textures' level of surface detail.
FINISH = {
    "CWFDRAW": (0.04, 8, 0.02, 0.10, 0.10), "CWFFILE": (0.04, 12, 0.02, 0.14, 0.10),
    "CWFRACK": (0.05, 12, 0.03, 0.0, 0.0), "CWFRKSD": (0.06, 8, 0.02, 0.10, 0.0),
    "CWFBOOK": (0.06, 8, 0.04, 0.10, 0.18), "CWFVEND": (0.04, 16, 0.02, 0.10, 0.08),
    "CWFCOPY": (0.03, 16, 0.02, 0.12, 0.08), "CWFCPTP": (0.03, 16, 0.02, 0.06, 0.0),
    "CWFCABN": (0.03, 16, 0.02, 0.12, 0.0), "CWFSINK": (0.04, 8, 0.03, 0.0, 0.0),
    "CWFWBRD": (0.02, 32, 0.01, 0.06, 0.0), "CWFSTAL": (0.04, 16, 0.02, 0.14, 0.0),
    "CWFPORC": (0.02, 8, 0.02, 0.05, 0.0), "CWFRCPF": (0.04, 16, 0.02, 0.0, 0.0),
    "CWFSTEP": (0.08, 8, 0.05, 0.25, 0.0), "CWFRACO": (0.06, 8, 0.04, 0.20, 0.0),
    "CWFPOT": (0.06, 8, 0.04, 0.10, 0.0), "CWFMIRR": (0.03, 16, 0.01, 0.0, 0.0),
    "CWFKEYB": (0.03, 8, 0.03, 0.0, 0.0), "CWFJUG": (0.03, 8, 0.02, 0.0, 0.0),
    "CWFBOX": (0.08, 8, 0.04, 0.15, 0.10),
}

def save(im, name, density=1.0):
    if name in FINISH:
        v, cell, g, dirt, ao = FINISH[name]
        a = T.from_image(im.convert("RGB"))
        cell = min(cell, a.shape[0], a.shape[1])
        if v: a = T.vary(a, v, cell, 3)
        if g: a = T.grain(a, g)
        if dirt: a = T.grime(a, dirt, max(4, cell // 2))
        if ao: a = T.ao_edges(a, 3, ao)
        im = T.to_image(a)
    if name.startswith("CWFSCR") or name == "CWFTVSC":
        # screens: scanlines, a soft vignette and a faint glass sheen
        a = T.from_image(im.convert("RGB"))
        a[1::2] *= 0.9
        h, w = a.shape[:2]; yy, xx = np.mgrid[0:h, 0:w]
        a *= (1 - 0.25 * (((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2) / 2)[..., None]
        a += 18 * np.clip(1 - (xx + yy * 1.5) / (w * 0.7), 0, 1)[..., None]
        im = T.to_image(a)
    im.convert("RGB").save(os.path.join(TEXD, name + ".png"))
    TEX[name] = (im.size[0], im.size[1], density)

def bevel(d, box, light, dark):
    x0, y0, x1, y1 = box
    d.line([x0, y0, x1, y0], fill=light); d.line([x0, y0, x0, y1], fill=light)
    d.line([x0, y1, x1, y1], fill=dark); d.line([x1, y0, x1, y1], fill=dark)

def font(sz): return ImageFont.truetype(FONTB, sz)

def make_textures():
    T.seed(3001)
    # --- wood (desk tops / exec furniture): walnut, warped grain along u, varnish sheen
    a = T.wood(64, 64, (104, 64, 38), ring=0.18, cell=32)
    a *= (1 + 0.06 * np.exp(-((np.mgrid[0:64, 0:64][1] - np.mgrid[0:64, 0:64][0] * 0.4 - 20) % 64 - 32) ** 2 / 60))[..., None]
    save(T.to_image(a), "CWFWOOD")
    a = T.wood(32, 32, (72, 44, 26), ring=0.12, cell=16)
    a[0] *= 1.45; a[1] *= 1.15; a = T.ao_edges(a, 3, 0.2, "b")
    save(T.to_image(a), "CWFWDSD")      # wood edge / carcass (lit top arris)
    # --- laminate (open-plan desks): pale grey with fleck, and the dark ABS edge band
    a = T.vary(T.solid(64, 64, (198, 198, 192)), 0.03, 32); a = T.grain(a, 0.025)
    a = T.speckle(a, 0.02, (170, 170, 166), 0.5); a = T.scratches(a, 6, 10, (214, 214, 210), 0.25)
    save(T.to_image(a), "CWFLAMT")
    a = T.vary(T.solid(32, 32, (92, 94, 98)), 0.04, 16); a = T.grain(a, 0.03)
    a[0] *= 1.5; a[1] *= 1.2; a[31] *= 0.7
    save(T.to_image(a), "CWFLAMS")
    # --- metal (powder-coated grey steel), black plastic, chrome
    a = T.brushed(32, 32, (126, 130, 136), 0.08); a = T.vary(a, 0.04, 16); a = T.grime(a, 0.1, 8)
    save(T.to_image(a), "CWFMETL")
    a = T.vary(T.solid(32, 32, (34, 35, 38)), 0.08, 16); a = T.grain(a, 0.06)
    a = T.scratches(a, 5, 6, (70, 72, 76), 0.4)
    save(T.to_image(a), "CWFBLAK")
    a = np.zeros((32, 16, 3))
    for x in range(16): a[:, x] = np.array((210, 214, 220)) * (0.5 + 0.5 * abs(math.sin(x * 0.4 + 0.6)))
    a = T.brushed(16, 32, (1, 1, 1), 0.08, horizontal=False) * a
    save(T.to_image(a), "CWFCHRM")
    # --- fabrics: twill weave, fbm pilling, darker seams; leather with creases and a sheen
    for name, base in (("CWFFABR", (58, 60, 66)), ("CWFFABB", (54, 72, 104)), ("CWFFABG", (92, 98, 90))):
        a = T.weave(32, 32, base, 0.12); a = T.vary(a, 0.07, 16); a = T.grain(a, 0.05)
        save(T.to_image(a), name)
    a = T.vary(T.solid(32, 32, (86, 48, 30)), 0.05, 16, 3); a = T.grain(a, 0.04)
    crease = T.fbm(32, 32, 4, 2); a = T.tint(a, np.exp(-((crease - 0.5) * 60) ** 2), (66, 36, 22), 0.3)
    a *= (1 + 0.12 * np.exp(-((np.mgrid[0:32, 0:32][0] - 10) ** 2) / 20))[..., None]
    save(T.to_image(a), "CWFLEAT")
    # --- monitor screens (fit, 2 texels/unit): 48 x 28
    def screen(name, kind):
        im = Image.new("RGB", (48, 28), (8, 12, 18)); d = ImageDraw.Draw(im)
        if kind == 0:     # spreadsheet
            d.rectangle([1, 1, 46, 26], fill=(222, 226, 230)); d.rectangle([1, 1, 46, 3], fill=(40, 110, 70))
            for y in range(6, 26, 3): d.line([2, y, 45, y], fill=(170, 176, 182))
            for x in (10, 20, 30, 38): d.line([x, 5, x, 25], fill=(170, 176, 182))
            for y in range(7, 25, 3):
                for x in (3, 12, 22, 32, 40): d.line([x, y, x + R.randint(3, 6), y], fill=(60, 64, 70))
        elif kind == 1:   # security / dashboard, green
            d.rectangle([1, 1, 46, 26], fill=(6, 22, 14))
            pts = [(2 + i * 3, 20 - int(8 * abs(math.sin(i * 0.7)) + R.randint(0, 3))) for i in range(15)]
            d.line(pts, fill=(90, 230, 120)); d.rectangle([30, 3, 45, 12], outline=(60, 160, 90))
            for y in (5, 7, 9): d.line([32, y, 32 + R.randint(5, 11), y], fill=(90, 230, 120))
            d.rectangle([3, 3, 26, 5], fill=(40, 120, 70))
        elif kind == 2:   # code editor
            d.rectangle([1, 1, 46, 26], fill=(28, 30, 40)); d.rectangle([1, 1, 8, 26], fill=(22, 24, 32))
            cols = [(200, 120, 220), (120, 200, 240), (230, 200, 110), (180, 184, 196)]
            for y in range(3, 26, 2):
                x = 10 + R.randint(0, 3) * 2; d.line([x, y, x + R.randint(6, 26), y], fill=R.choice(cols))
        else:             # corporate login / wallpaper
            for y in range(28): d.line([0, y, 47, y], fill=(20 + y * 2, 40 + y * 3, 90 + y * 3))
            d.ellipse([19, 6, 29, 16], outline=(230, 236, 244)); d.rectangle([14, 19, 34, 21], fill=(230, 236, 244))
        d.rectangle([0, 0, 47, 27], outline=(16, 16, 18))
        save(im, name, 2.0)
    for k in range(4): screen("CWFSCR%d" % (k + 1), k)
    # --- keyboard (fit)
    im = Image.new("RGB", (36, 12), (40, 42, 46)); d = ImageDraw.Draw(im)
    for r in range(4):
        for c in range(16):
            x = 1 + c * 2 + (r % 2); y = 1 + r * 3
            if x < 34: d.rectangle([x, y, x, y + 1], fill=(92, 96, 102))
    save(im, "CWFKEYB", 2.0)
    # --- pedestal drawers (fit): 3 drawers, 32 x 56
    im = Image.new("RGB", (32, 56), (104, 106, 110)); d = ImageDraw.Draw(im)
    for y0, y1 in ((2, 14), (16, 28), (30, 53)):
        d.rectangle([2, y0, 29, y1], fill=(122, 124, 128)); bevel(d, (2, y0, 29, y1), (150, 152, 156), (70, 72, 76))
        d.rectangle([11, y0 + 3, 20, y0 + 4], fill=(40, 40, 44))
    noise(im, 2); save(im, "CWFDRAW", 2.0)
    # --- file cabinet (fit): 4 drawers with label holders, 36 x 104
    im = Image.new("RGB", (36, 104), (92, 96, 102)); d = ImageDraw.Draw(im)
    for k in range(4):
        y0 = 3 + k * 25; y1 = y0 + 22
        d.rectangle([2, y0, 33, y1], fill=(112, 116, 122)); bevel(d, (2, y0, 33, y1), (150, 154, 160), (60, 62, 68))
        d.rectangle([13, y0 + 4, 22, y0 + 8], fill=(214, 210, 190)); d.rectangle([12, y0 + 11, 23, y0 + 13], fill=(56, 58, 62))
    noise(im, 2); save(im, "CWFFILE", 2.0)
    # --- server rack front (fit): 48 x 160 — units, blinking LEDs, a patch panel
    im = Image.new("RGB", (48, 160), (22, 23, 26)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 47, 159], outline=(60, 62, 68)); d.rectangle([2, 2, 45, 157], outline=(44, 46, 50))
    y = 6
    while y < 150:
        hgt = R.choice((6, 6, 10, 14))
        if y + hgt > 152: break
        d.rectangle([5, y, 42, y + hgt - 1], fill=(48, 50, 56)); bevel(d, (5, y, 42, y + hgt - 1), (84, 86, 92), (30, 30, 34))
        for k in range(R.randint(1, 4)):
            lx = 8 + k * 3; d.point((lx, y + 2), fill=R.choice(((80, 255, 120), (80, 255, 120), (255, 180, 40), (80, 180, 255))))
        if hgt >= 10:
            for bx in range(20, 40, 5): d.rectangle([bx, y + 2, bx + 3, y + hgt - 3], fill=(36, 38, 42))
        y += hgt + 1
    save(im, "CWFRACK", 2.0)
    im = Image.new("RGB", (32, 32), (40, 42, 46)); d = ImageDraw.Draw(im)
    for yy in range(2, 32, 4):
        for xx in range(2, 32, 4): d.point((xx, yy), fill=(18, 18, 20))
    save(im, "CWFRKSD")
    # --- binders / books on a shelf (tile, u along the shelf)
    im = Image.new("RGB", (64, 24), (30, 26, 22)); d = ImageDraw.Draw(im)
    x = 0; cols = [(160, 40, 40), (40, 70, 140), (220, 210, 190), (40, 110, 70), (30, 30, 34), (190, 150, 60), (120, 124, 130)]
    while x < 64:
        w = R.randint(2, 5); h = R.randint(16, 23); c = R.choice(cols)
        d.rectangle([x, 24 - h, x + w - 1, 23], fill=c); d.line([x, 24 - h, x, 23], fill=shade(c, 1.25))
        if w >= 4: d.rectangle([x + 1, 24 - h + 3, x + w - 2, 24 - h + 5], fill=(230, 226, 210))
        x += w
    save(im, "CWFBOOK")
    # --- vending machine front (fit): 72 x 144
    im = Image.new("RGB", (72, 144), (150, 30, 34)); d = ImageDraw.Draw(im)
    d.rectangle([4, 6, 50, 112], fill=(20, 24, 30))
    snack = [(230, 60, 50), (240, 200, 60), (60, 120, 220), (80, 190, 90), (240, 140, 40), (200, 200, 210)]
    for r in range(6):
        for c in range(5):
            x0 = 7 + c * 9; y0 = 10 + r * 17; col = R.choice(snack)
            d.rectangle([x0, y0, x0 + 6, y0 + 10], fill=col); d.line([x0, y0, x0 + 6, y0], fill=shade(col, 1.3))
        d.line([5, 22 + r * 17, 49, 22 + r * 17], fill=(120, 124, 130))
    d.line([6, 8, 20, 100], fill=(70, 80, 96))       # glass glint
    d.rectangle([54, 10, 67, 22], fill=(20, 40, 30)); d.text((56, 12), "1.25", fill=(90, 240, 120), font=font(6))
    for r in range(4):
        for c in range(3): d.rectangle([55 + c * 4, 28 + r * 5, 57 + c * 4, 30 + r * 5], fill=(210, 210, 214))
    d.rectangle([56, 52, 66, 56], fill=(20, 20, 22)); d.rectangle([8, 118, 46, 134], fill=(28, 28, 32))
    d.text((10, 136), "SNAX", fill=(250, 230, 200), font=font(7))
    noise(im, 3, (52, 0, 72, 144)); save(im, "CWFVEND", 2.0)
    # --- copier: body (fit front) + top panel
    im = Image.new("RGB", (56, 72), (212, 212, 206)); d = ImageDraw.Draw(im)
    d.rectangle([2, 4, 53, 12], fill=(196, 196, 190)); d.rectangle([4, 20, 51, 38], fill=(200, 200, 194))
    bevel(d, (4, 20, 51, 38), (230, 230, 226), (150, 150, 146)); d.rectangle([20, 26, 35, 28], fill=(90, 90, 94))
    d.rectangle([4, 42, 51, 60], fill=(200, 200, 194)); bevel(d, (4, 42, 51, 60), (230, 230, 226), (150, 150, 146))
    d.rectangle([20, 48, 35, 50], fill=(90, 90, 94)); d.rectangle([0, 66, 55, 71], fill=(70, 72, 76))
    noise(im, 2); save(im, "CWFCOPY", 2.0)
    im = Image.new("RGB", (48, 56), (206, 206, 200)); d = ImageDraw.Draw(im)
    d.rectangle([4, 4, 43, 30], fill=(50, 54, 60)); d.rectangle([6, 6, 41, 28], fill=(70, 76, 84))
    d.rectangle([4, 36, 24, 50], fill=(40, 60, 90)); d.rectangle([6, 38, 22, 44], fill=(110, 200, 240))
    for r in range(3):
        for c in range(4): d.rectangle([28 + c * 4, 37 + r * 4, 30 + c * 4, 39 + r * 4], fill=(120, 122, 126))
    d.rectangle([44, 46, 46, 48], fill=(80, 240, 90)); save(im, "CWFCPTP", 2.0)
    # --- water cooler jug + white appliance body
    im = Image.new("RGB", (20, 32), (90, 150, 210)); d = ImageDraw.Draw(im)
    for y in range(32): d.line([0, y, 19, y], fill=(80 + (y % 6), 140 + y, 206))
    d.line([4, 2, 4, 29], fill=(190, 230, 250)); d.line([0, 10, 19, 10], fill=(70, 120, 180)); d.line([0, 22, 19, 22], fill=(70, 120, 180))
    save(im, "CWFJUG", 1.0)
    a = T.vary(T.solid(32, 32, (226, 226, 222)), 0.03, 16); a = T.grain(a, 0.02); a = T.grime(a, 0.06, 8)
    save(T.to_image(a), "CWFWHIT")
    # --- kitchen: cabinet doors (tile 48 wide = two doors), stone countertop, sink top (fit)
    im = Image.new("RGB", (48, 36), (236, 234, 228)); d = ImageDraw.Draw(im)
    for x0 in (1, 25):
        d.rectangle([x0, 1, x0 + 21, 34], fill=(226, 224, 218)); bevel(d, (x0, 1, x0 + 21, 34), (250, 250, 246), (170, 168, 162))
    d.rectangle([20, 4, 21, 12], fill=(120, 124, 130)); d.rectangle([27, 4, 28, 12], fill=(120, 124, 130))
    save(im, "CWFCABN")
    a = T.vary(T.solid(64, 64, (62, 64, 68)), 0.10, 16, 4); a = T.grain(a, 0.12)
    a = T.speckle(a, 0.05, (170, 172, 176), 0.8); a = T.speckle(a, 0.05, (24, 24, 26), 0.8); a = T.speckle(a, 0.02, (130, 96, 80), 0.6)
    save(T.to_image(a), "CWFGRAN")
    im = Image.new("RGB", (48, 24), (64, 66, 70)); noise(im, 10, mono=False); d = ImageDraw.Draw(im)
    d.rounded_rectangle([10, 4, 38, 20], 3, fill=(170, 176, 184)); d.rounded_rectangle([12, 6, 36, 18], 3, fill=(120, 126, 134))
    d.ellipse([23, 11, 26, 14], fill=(50, 52, 56)); d.rectangle([22, 1, 26, 3], fill=(200, 204, 210))
    save(im, "CWFSINK", 1.0)
    # --- whiteboard (fit 128 x 64), wall TV (fit 128 x 72)
    im = Image.new("RGB", (128, 64), (236, 238, 240)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 127, 63], outline=(150, 154, 160)); d.rectangle([1, 1, 126, 62], outline=(190, 194, 200))
    d.rectangle([8, 6, 60, 10], fill=(40, 60, 170))
    for y in (16, 22, 28): d.line([10, y, 10 + R.randint(20, 44), y], fill=(40, 60, 170))
    d.rectangle([72, 14, 88, 26], outline=(200, 40, 40)); d.rectangle([100, 30, 116, 42], outline=(200, 40, 40))
    d.line([88, 20, 100, 36], fill=(200, 40, 40)); d.line([12, 44, 30, 36, 46, 48, 62, 38], fill=(30, 140, 70))
    d.rectangle([90, 58, 120, 61], fill=(120, 124, 130)); save(im, "CWFWBRD", 2.0)
    im = Image.new("RGB", (128, 72), (10, 12, 16)); d = ImageDraw.Draw(im)
    for y in range(4, 68): d.line([4, y, 123, y], fill=(14, 24 + y // 3, 48 + y // 2))
    d.rectangle([4, 56, 123, 67], fill=(10, 14, 24))
    d.text((8, 57), "MRDN +2.4  ORLX -1.1  CSTL +0.6", fill=(120, 230, 150), font=font(7))
    pts = [(8 + i * 6, 40 - int(14 * math.sin(i * 0.35)) - R.randint(0, 5)) for i in range(19)]
    d.line(pts, fill=(250, 210, 90), width=1); d.text((8, 6), "MERIDIAN HOLDINGS", fill=(230, 236, 244), font=font(9))
    save(im, "CWFTVSC", 2.0)
    # --- bathroom partitions (beige laminate), porcelain
    im = Image.new("RGB", (32, 32), (188, 176, 150)); noise(im, 2); save(im, "CWFSTAL")
    im = Image.new("RGB", (16, 16), (240, 240, 238)); noise(im, 2); save(im, "CWFPORC")
    # --- lab: black epoxy top; white lab cabinets use CWFCABN
    a = T.vary(T.solid(32, 32, (26, 28, 30)), 0.12, 16); a = T.speckle(a, 0.01, (80, 82, 86), 0.6)
    a = T.scratches(a, 4, 8, (70, 72, 76), 0.3); save(T.to_image(a), "CWFEPOX")
    # --- reception front: stone slab with a brass reveal strip and the corporate mark (fit 96 x 44)
    im = Image.new("RGB", (192, 88), (58, 58, 64)); noise(im, 10, mono=False); d = ImageDraw.Draw(im)
    for k in range(24):
        x = R.randint(0, 191); y = R.randint(0, 87); d.line([x, y, x + R.randint(-20, 20), y + R.randint(4, 20)], fill=(84, 84, 92))
    d.rectangle([0, 10, 191, 13], fill=(186, 150, 80)); d.rectangle([0, 80, 191, 87], fill=(24, 24, 28))
    d.ellipse([84, 30, 108, 54], outline=(200, 170, 100), width=2); d.polygon([(90, 36), (102, 36), (96, 48)], outline=(200, 170, 100))
    save(im, "CWFRCPF", 2.0)
    # --- stairs: concrete tread with a yellow nosing (fit per step face), handrail
    im = Image.new("RGB", (32, 32), (128, 128, 124)); noise(im, 8); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 31, 2], fill=(214, 170, 40)); save(im, "CWFSTEP")
    # --- storage: orange pallet-rack uprights, cardboard boxes (tile)
    im = Image.new("RGB", (16, 16), (214, 110, 30)); noise(im, 5)
    d = ImageDraw.Draw(im)
    for y in range(0, 16, 4): d.rectangle([6, y + 1, 9, y + 2], fill=(60, 34, 12))
    save(im, "CWFRACO")
    im = Image.new("RGB", (32, 24), (176, 132, 82)); noise(im, 5); d = ImageDraw.Draw(im)
    d.line([0, 0, 31, 0], fill=(140, 100, 60)); d.line([16, 0, 16, 23], fill=(150, 110, 66)); d.rectangle([3, 12, 12, 18], fill=(230, 226, 214))
    d.line([0, 23, 31, 23], fill=(120, 88, 52)); save(im, "CWFBOX")
    # --- planter: dark ceramic
    im = Image.new("RGB", (32, 32), (46, 48, 52)); noise(im, 4); d = ImageDraw.Draw(im)
    d.line([0, 0, 31, 0], fill=(90, 92, 98)); save(im, "CWFPOT")
    # --- toilet paper / towel dispenser & mirror
    im = Image.new("RGB", (64, 32), (150, 170, 186)); d = ImageDraw.Draw(im)
    for k in range(6): d.line([4 + k * 11, 30, 14 + k * 11, 2], fill=(196, 214, 226))
    d.rectangle([0, 0, 63, 31], outline=(200, 204, 210)); save(im, "CWFMIRR", 2.0)

def light_textures():
    T.seed(3100)
    # troffer lens: prismatic diffuser, brightest in the middle, aluminium rim
    a = T.solid(24, 48, (240, 244, 248)); yy, xx = np.mgrid[0:48, 0:24]
    a *= (1 + 0.05 * (((xx + yy) % 3 == 0) * 2 - 1))[..., None]
    a *= (1.02 - 0.12 * np.hypot((xx - 12) / 12, (yy - 24) / 24))[..., None]
    a[:, :2] = (170, 174, 180); a[:, -2:] = (170, 174, 180); a[:2] = (170, 174, 180); a[-2:] = (170, 174, 180)
    a[4:44, 11:13] *= 0.9                                            # tube shadow line through the lens
    save(T.to_image(a), "CWFLENS", 1.0)
    # fluorescent tube: hot core, cooler ends
    a = T.solid(8, 64, (250, 252, 255)); a[:4] = (200, 200, 205); a[-4:] = (200, 200, 205)
    a[:, 0] *= 0.85; a[:, -1] *= 0.85; save(T.to_image(a), "CWFTUBE", 1.0)
    # warm diffuser disc for pendants / downlights
    a = T.solid(32, 32, (255, 236, 196)); yy, xx = np.mgrid[0:32, 0:32]
    a *= (1.05 - 0.25 * np.hypot(xx - 16, yy - 16) / 16)[..., None]; save(T.to_image(a), "CWFDIFF", 1.0)
    # pendant drum shade: dark bronze with a lit inner rim line
    a = T.brushed(32, 16, (62, 52, 44), 0.1); a[-2:] = (200, 170, 120); a[:1] *= 0.6
    save(T.to_image(a), "CWFSHAD", 1.0)
    # exit sign face (fit): white "EXIT" on green, running man
    im = Image.new("RGB", (48, 20), (18, 140, 64)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 47, 19], outline=(12, 90, 40)); d.text((4, 3), "EXIT", font=font(12), fill=(240, 255, 240))
    d.polygon([(40, 6), (44, 10), (40, 14)], fill=(240, 255, 240))
    a = T.from_image(im); a *= (1.1 - 0.2 * np.abs(np.mgrid[0:20, 0:48][0] - 10) / 10)[..., None]
    save(T.to_image(a), "CWFEXIT", 2.0)

# =============================================================================================== meshes
class Mesh:
    def __init__(self, name):
        self.name = name; self.v = []; self.vt = []; self.f = {}   # material -> [((vi,ti),...)]

    def _uv(self, mat, u, v):
        w, h, dens = TEX[mat]
        return (u * dens / w, v * dens / h)

    def quad(self, mat, pts, uvs):
        """pts: 4 doom-space points, counter-clockwise seen from outside; uvs: 4 (u, v) pairs, already normalised."""
        idx = []
        for p, t in zip(pts, uvs):
            self.v.append(p); self.vt.append(t); idx.append((len(self.v), len(self.vt)))
        self.f.setdefault(mat, []).append(idx)

    def box(self, x0, x1, y0, y1, z0, z1, mat, **faces):
        """Axis-aligned box. mat is the default material; faces override per side: front(+x) back(-x) left(+y)
        right(-y) top bottom. A value is a material name, (material, 'fit') to stretch the whole texture over the
        face, or None to skip the face. Bottom faces are skipped by default (furniture stands on floors)."""
        spec = dict(front=mat, back=mat, left=mat, right=mat, top=mat, bottom=None)
        spec.update(faces)
        def go(side, pts, u_axis, v_axis):
            s = spec[side]
            if s is None: return
            m, fit = (s if isinstance(s, tuple) else (s, None))
            fit = fit == 'fit'
            us = [u_axis(p) for p in pts]; vs = [v_axis(p) for p in pts]
            if fit:
                u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
                uvs = [((u - u0) / (u1 - u0 or 1), (v - v0) / (v1 - v0 or 1)) for u, v in zip(us, vs)]
            else:
                uvs = [self._uv(m, u, v) for u, v in zip(us, vs)]
            self.quad(m, pts, uvs)
        go('front', [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)], lambda p: p[1], lambda p: p[2])
        go('back', [(x0, y1, z0), (x0, y0, z0), (x0, y0, z1), (x0, y1, z1)], lambda p: -p[1], lambda p: p[2])
        go('left', [(x1, y1, z0), (x0, y1, z0), (x0, y1, z1), (x1, y1, z1)], lambda p: -p[0], lambda p: p[2])
        go('right', [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], lambda p: p[0], lambda p: p[2])
        go('top', [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], lambda p: p[1], lambda p: p[0])
        go('bottom', [(x0, y1, z0), (x1, y1, z0), (x1, y0, z0), (x0, y0, z0)], lambda p: p[1], lambda p: p[0])
        return self

    def cyl(self, cx, cy, r, z0, z1, mat, n=8, top=True):
        """n-gon prism (plant pots, bins, jugs)."""
        pts = [(cx + r * math.cos(2 * math.pi * k / n), cy + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
        w, h, dens = TEX[mat]
        per = 2 * math.pi * r
        for k in range(n):
            a, b = pts[k], pts[(k + 1) % n]
            u0, u1 = k / n * per, (k + 1) / n * per
            self.quad(mat, [(a[0], a[1], z0), (b[0], b[1], z0), (b[0], b[1], z1), (a[0], a[1], z1)],
                      [self._uv(mat, u0, z0), self._uv(mat, u1, z0), self._uv(mat, u1, z1), self._uv(mat, u0, z1)])
        if top:
            for k in range(n):   # fan as degenerate quads
                a, b = pts[k], pts[(k + 1) % n]
                self.quad(mat, [(cx, cy, z1), (a[0], a[1], z1), (b[0], b[1], z1), (cx, cy, z1)],
                          [self._uv(mat, cx, cy), self._uv(mat, a[0], a[1]), self._uv(mat, b[0], b[1]), self._uv(mat, cx, cy)])
        return self

    def write(self):
        out = ["# Corpo Wars furniture: %s (generated by make_models.py)" % self.name]
        for x, y, z in self.v: out.append("v %.3f %.3f %.3f" % (x, z, -y))
        for u, v in self.vt: out.append("vt %.4f %.4f" % (u, v))
        for m, fs in self.f.items():
            out.append("usemtl " + m)
            for f in fs: out.append("f " + " ".join("%d/%d" % t for t in f))
        open(os.path.join(MODD, self.name + ".obj"), "w").write("\n".join(out) + "\n")


MODELS = []   # (actor class, obj name, frame letter)

BUILDERS = []
def model(cls):
    def deco(fn):
        BUILDERS.append((cls, fn)); return fn
    return deco

def build_models():
    for cls, fn in BUILDERS:
        m = Mesh(fn.__name__); fn(m); m.write(); MODELS.append((cls, fn.__name__))

# ---------------------------------------------------------------- workstation (open plan): 30 deep x 60 wide
def monitor(m, x, y, z, scr, w=24, h=15, ang=0.0):
    # stand + neck + panel; screen faces +x
    m.box(x - 5, x + 2, y - 6, y + 6, z, z + 1, "CWFBLAK")
    m.box(x - 4, x - 2, y - 1.5, y + 1.5, z + 1, z + 7, "CWFBLAK")
    m.box(x - 2, x, y - w / 2, y + w / 2, z + 5, z + 5 + h, "CWFBLAK", front=(scr, 'fit'), bottom="CWFBLAK")

@model("CW_FDeskWork")
def desk_work(m):
    T = 28
    m.box(-15, 15, -30, 30, T, T + 2, "CWFLAMS", top="CWFLAMT", bottom="CWFLAMS")
    m.box(-12, 13, -29, -13, 0, T, "CWFLAMS", front=("CWFDRAW", 'fit'))           # drawer pedestal (right)
    m.box(-13, 13, 27, 29, 0, T, "CWFLAMS")                                         # side panel (left)
    m.box(-14, -12, -13, 27, 9, T, "CWFLAMS")                                       # modesty panel
    m.box(-9, 9, 18, 25, 0, 19, "CWFBLAK")                                          # tower PC
    monitor(m, -7, -6, T + 2, "CWFSCR1")
    monitor(m, -7, 16, T + 2, "CWFSCR2", w=20, h=13)
    m.box(2, 8, -12, 6, T + 2, T + 3, "CWFBLAK", top=("CWFKEYB", 'fit'))
    m.box(4, 7, 10, 12, T + 2, T + 3, "CWFBLAK")
    m.box(-6, 6, -28, -20, T + 2, T + 3, "CWFWHIT")                                  # paper stack
    m.box(8, 11, -26, -23, T + 2, T + 6, "CWFFABB")                                  # mug

@model("CW_FDeskCode")
def desk_code(m):
    T = 28
    m.box(-15, 15, -30, 30, T, T + 2, "CWFLAMS", top="CWFLAMT", bottom="CWFLAMS")
    m.box(-12, 13, 13, 29, 0, T, "CWFLAMS", front=("CWFDRAW", 'fit'))
    m.box(-13, 13, -29, -27, 0, T, "CWFLAMS")
    m.box(-14, -12, -27, 13, 9, T, "CWFLAMS")
    monitor(m, -7, 0, T + 2, "CWFSCR3", w=28, h=16)
    m.box(2, 8, -9, 9, T + 2, T + 3, "CWFBLAK", top=("CWFKEYB", 'fit'))
    m.box(-4, 8, 16, 26, T + 2, T + 3, "CWFBLAK", top="CWFMETL")                     # laptop base
    m.box(-4, -3, 16, 26, T + 3, T + 11, "CWFMETL", front=("CWFSCR4", 'fit'))

# ---------------------------------------------------------------- executive desk: 36 deep x 84 wide, wood, pedestals both sides
@model("CW_FDeskExec")
def desk_exec(m):
    T = 29
    m.box(-18, 18, -42, 42, T, T + 3, "CWFWDSD", top="CWFWOOD", bottom="CWFWDSD")
    m.box(-16, 15, -40, -20, 0, T, "CWFWDSD", front=("CWFDRAW", 'fit'))
    m.box(-16, 15, 20, 40, 0, T, "CWFWDSD", front=("CWFDRAW", 'fit'))
    m.box(-17, -15, -20, 20, 6, T, "CWFWDSD")
    monitor(m, -9, 6, T + 3, "CWFSCR4", w=28, h=17)
    m.box(2, 8, -6, 14, T + 3, T + 4, "CWFBLAK", top=("CWFKEYB", 'fit'))
    # desk lamp
    m.box(-12, -6, -34, -28, T + 3, T + 4, "CWFCHRM"); m.box(-10, -8, -32, -30, T + 4, T + 18, "CWFCHRM")
    m.box(-10, 0, -34, -28, T + 16, T + 19, "CWFFABG")
    m.box(-6, 4, 22, 34, T + 3, T + 4, "CWFWHIT")                                    # folder
    m.box(6, 10, -24, -20, T + 3, T + 5, "CWFCHRM")                                  # pen tray

# ---------------------------------------------------------------- chairs
@model("CW_FChair")
def chair_office(m):
    m.box(-9, 9, -1.5, 1.5, 1, 3, "CWFBLAK"); m.box(-1.5, 1.5, -9, 9, 1, 3, "CWFBLAK")   # star base
    m.box(-1.5, 1.5, -1.5, 1.5, 3, 15, "CWFCHRM")
    m.box(-8, 8, -8, 8, 15, 19, "CWFFABR")
    m.box(-10, -7, -7, 7, 19, 38, "CWFFABR")
    m.box(-4, 4, -9, -8, 19, 25, "CWFBLAK"); m.box(-4, 4, 8, 9, 19, 25, "CWFBLAK")       # arm rests
    m.box(-4, 4, -9, -7, 25, 26, "CWFBLAK"); m.box(-4, 4, 7, 9, 25, 26, "CWFBLAK")

@model("CW_FChairExec")
def chair_exec(m):
    m.box(-10, 10, -1.5, 1.5, 1, 3, "CWFBLAK"); m.box(-1.5, 1.5, -10, 10, 1, 3, "CWFBLAK")
    m.box(-1.5, 1.5, -1.5, 1.5, 3, 15, "CWFCHRM")
    m.box(-9, 9, -9, 9, 15, 20, "CWFLEAT")
    m.box(-12, -8, -8, 8, 20, 46, "CWFLEAT")
    m.box(-6, 6, -10, -9, 20, 27, "CWFLEAT"); m.box(-6, 6, 9, 10, 20, 27, "CWFLEAT")

@model("CW_FChairGuest")
def chair_guest(m):
    for x in (-7, 6):
        for y in (-7, 6): m.box(x, x + 1.5, y, y + 1.5, 0, 16, "CWFCHRM")
    m.box(-8, 8, -8, 8, 16, 19, "CWFFABB")
    m.box(-9, -7, -8, 8, 19, 34, "CWFFABB")

# ---------------------------------------------------------------- lounge
@model("CW_FSofa")
def sofa(m):
    m.box(-18, 18, -42, 42, 0, 4, "CWFBLAK")
    m.box(-18, -8, -42, 42, 4, 32, "CWFFABR")                      # back
    m.box(-8, 18, -42, -36, 4, 22, "CWFFABR"); m.box(-8, 18, 36, 42, 4, 22, "CWFFABR")   # arms
    m.box(-8, 17, -36, -0.5, 4, 16, "CWFFABR"); m.box(-8, 17, 0.5, 36, 4, 16, "CWFFABR")  # seat cushions
    m.box(-9, -5, -34, -2, 16, 28, "CWFFABG"); m.box(-9, -5, 2, 34, 16, 28, "CWFFABG")    # back cushions

@model("CW_FArmchair")
def armchair(m):
    m.box(-16, 16, -16, 16, 0, 4, "CWFBLAK")
    m.box(-16, -7, -16, 16, 4, 30, "CWFLEAT")
    m.box(-7, 16, -16, -11, 4, 21, "CWFLEAT"); m.box(-7, 16, 11, 16, 4, 21, "CWFLEAT")
    m.box(-7, 15, -11, 11, 4, 15, "CWFLEAT")

@model("CW_FCoffeeTable")
def coffee_table(m):
    m.box(-14, 14, -24, 24, 13, 15, "CWFWDSD", top="CWFWOOD", bottom="CWFWDSD")
    m.box(-12, 12, -22, 22, 0, 2, "CWFBLAK")
    for x in (-11, 10):
        for y in (-21, 20): m.box(x, x + 1.5, y, y + 1.5, 2, 13, "CWFCHRM")
    m.box(-6, 4, -14, -2, 15, 16, "CWFWHIT")                        # magazines
    m.box(0, 8, 8, 16, 15, 17, "CWFBLAK")

# ---------------------------------------------------------------- meeting
@model("CW_FConfTable")
def conf_table(m):
    # 88 long (x) x 40 wide (y); two pedestal bases; front = one short end
    m.box(-44, 44, -20, 20, 28, 31, "CWFWDSD", top="CWFWOOD", bottom="CWFWDSD")
    for x in (-24, 24): m.box(x - 6, x + 6, -10, 10, 0, 28, "CWFBLAK", top=None); m.box(x - 10, x + 10, -14, 14, 0, 2, "CWFBLAK")
    m.box(-4, 4, -4, 4, 31, 32, "CWFBLAK")                          # conference phone
    m.box(-30, -22, -10, 2, 31, 32, "CWFWHIT"); m.box(18, 26, 4, 14, 31, 32, "CWFWHIT")

@model("CW_FRoundTable")
def round_table(m):
    m.cyl(0, 0, 16, 26, 28, "CWFLAMT", n=12)
    m.box(-2, 2, -2, 2, 2, 26, "CWFCHRM"); m.cyl(0, 0, 9, 0, 2, "CWFBLAK", n=8)

@model("CW_FWhiteboard")
def whiteboard(m):
    m.box(-1, 1, -30, 30, 28, 60, "CWFMETL", front=("CWFWBRD", 'fit'))
    m.box(-1, 3, -20, 10, 26, 28, "CWFMETL")

@model("CW_FWallTV")
def wall_tv(m):
    m.box(-1.5, 1.5, -28, 28, 34, 66, "CWFBLAK", front=("CWFTVSC", 'fit'), bottom="CWFBLAK")

# ---------------------------------------------------------------- reception counter: 34 deep x 112 wide; staff side = front (+x)
@model("CW_FReception")
def reception(m):
    m.box(-17, -12, -56, 56, 0, 44, "CWFBLAK", back=("CWFRCPF", 'fit'), top="CWFWOOD")         # visitor-facing screen wall
    m.box(-20, -8, -58, 58, 44, 46, "CWFWDSD", top="CWFWOOD", bottom="CWFWDSD")                  # transaction ledge
    m.box(-12, 17, -56, 56, 27, 29, "CWFLAMS", top="CWFLAMT", bottom="CWFLAMS")                 # work surface
    m.box(-12, 16, -56, -52, 0, 27, "CWFLAMS"); m.box(-12, 16, 52, 56, 0, 27, "CWFLAMS")
    m.box(-12, 14, -30, -12, 0, 27, "CWFLAMS", front=("CWFDRAW", 'fit'))
    monitor(m, -8, 20, 29, "CWFSCR1"); monitor(m, -8, -24, 29, "CWFSCR2", w=20, h=13)
    m.box(1, 7, 12, 30, 29, 30, "CWFBLAK", top=("CWFKEYB", 'fit'))

# ---------------------------------------------------------------- storage / tech
@model("CW_FFileCabinet")
def file_cabinet(m):
    m.box(-13, 13, -9, 9, 0, 52, "CWFMETL", front=("CWFFILE", 'fit'))

@model("CW_FBookshelf")
def bookshelf(m):
    D, W, H = 14, 36, 72
    m.box(-7, 7, -18, -16, 0, H, "CWFWDSD"); m.box(-7, 7, 16, 18, 0, H, "CWFWDSD")
    m.box(-7, -6, -16, 16, 0, H, "CWFWDSD")
    for z in (0, 18, 36, 54): m.box(-7, 7, -16, 16, z, z + 2, "CWFWDSD", top="CWFWOOD")
    m.box(-7, 7, -18, 18, H - 2, H, "CWFWDSD", top="CWFWOOD")
    for z in (2, 20, 38, 56):
        m.box(-6, 5, -16, 16, z, z + 13 + (z % 3), "CWFBOOK", front="CWFBOOK", top="CWFWHIT")

@model("CW_FServerRack")
def server_rack(m):
    m.box(-20, 20, -12, 12, 0, 80, "CWFRKSD", front=("CWFRACK", 'fit'), back=("CWFRACK", 'fit'), top="CWFBLAK")
    m.box(20, 21, -12, 12, 0, 2, "CWFBLAK")

@model("CW_FShelving")
def shelving(m):
    # industrial pallet racking, 20 deep x 64 wide x 72 tall, boxes on three levels
    for x in (-10, 9):
        for y in (-32, 31): m.box(x, x + 1.5, y, y + 1.5, 0, 72, "CWFRACO")
    for z in (4, 28, 52):
        m.box(-10, 10.5, -32, 32.5, z, z + 2, "CWFRACO", top="CWFMETL")
        x = -30
        while x < 26:
            w = R.choice((12, 16, 20)); h = R.choice((10, 14, 18))
            if x + w > 30: break
            m.box(-8, 8, x, x + w - 1, z + 2, z + 2 + h, "CWFBOX")
            x += w + 1

@model("CW_FVending")
def vending(m):
    m.box(-16, 14, -18, 18, 0, 72, "CWFBLAK", front=("CWFVEND", 'fit'), left="CWFRKSD", right="CWFRKSD")
    m.box(14, 16, -17, 17, 2, 70, "CWFBLAK", front=("CWFVEND", 'fit'), left=None, right=None, top=None)

@model("CW_FCopier")
def copier(m):
    m.box(-12, 12, -14, 14, 0, 34, "CWFWHIT", front=("CWFCOPY", 'fit'))
    m.box(-12, 12, -14, 14, 34, 38, "CWFWHIT", top=("CWFCPTP", 'fit'))
    m.box(-6, 6, 14, 22, 26, 28, "CWFWHIT")        # output tray
    m.box(-4, 4, 15, 21, 28, 29, "CWFWHIT")

@model("CW_FWaterCooler")
def water_cooler(m):
    m.box(-6, 6, -6, 6, 0, 30, "CWFWHIT")
    m.box(6, 7, -2, 2, 18, 22, "CWFBLAK")
    m.cyl(0, 0, 5, 30, 46, "CWFJUG", n=8)

@model("CW_FCounter")
def kitchen_counter(m):
    # 24 deep x 96 wide kitchen run: base cabinets, stone top, sink, microwave + coffee machine
    m.box(-12, 10, -48, 48, 0, 34, "CWFCABN", left="CWFWHIT", right="CWFWHIT", back="CWFWHIT")
    m.box(10, 11, -48, 48, 0, 3, "CWFBLAK")
    m.box(-12, 12, -48, 48, 34, 36, "CWFGRAN", top="CWFGRAN")
    m.box(-12, 12, -12, 12, 36, 36.3, "CWFGRAN", top=("CWFSINK", 'fit'), front=None, back=None, left=None, right=None)
    m.box(-11, -5, -2, 2, 36, 46, "CWFCHRM"); m.box(-7, 0, -1, 1, 44, 46, "CWFCHRM")   # tap
    m.box(-11, 5, 22, 40, 36, 46, "CWFMETL", front="CWFBLAK")                            # microwave
    m.box(-11, 3, -40, -28, 36, 50, "CWFBLAK"); m.box(0, 3, -37, -31, 38, 40, "CWFCHRM")   # coffee machine

@model("CW_FLabBench")
def lab_bench(m):
    # 30 deep x 96 wide: white cabinets, black epoxy top, fume shelf + kit
    m.box(-15, 13, -48, 48, 0, 32, "CWFCABN", left="CWFWHIT", right="CWFWHIT", back="CWFWHIT")
    m.box(-15, 15, -48, 48, 32, 34, "CWFEPOX")
    m.box(-15, -12, -48, 48, 34, 58, "CWFWHIT"); m.box(-12, -2, -48, 48, 56, 58, "CWFWHIT")
    m.box(-11, 1, -40, -24, 34, 44, "CWFMETL", front=("CWFSCR2", 'fit'))            # analyser
    m.cyl(-6, 4, 3, 34, 44, "CWFJUG", n=6); m.cyl(-4, 14, 2.5, 34, 40, "CWFJUG", n=6)
    m.box(-8, 6, 24, 40, 34, 36, "CWFWHIT")                                            # sample tray
    monitor(m, -8, 26, 58, "CWFSCR3", w=18, h=11)

@model("CW_FBin")
def bin(m):
    m.cyl(0, 0, 6, 0, 15, "CWFBLAK", n=8, top=False)
    m.cyl(0, 0, 5.5, 0, 12, "CWFWHIT", n=8)

@model("CW_FPlanter")
def planter(m):
    # waist-high trough planter for lobbies (crouch cover); the leafy plant sprite stays a billboard on top
    m.box(-12, 12, -40, 40, 0, 28, "CWFPOT", top="CWFFABG")
    m.box(-13, 13, -41, 41, 28, 30, "CWFMETL", top=None)

@model("CW_FCredenza")
def credenza(m):
    # low corridor / aisle cabinet: sliding doors, laminate top, a few things on it (crouch cover)
    m.box(-9, 9, -30, 30, 0, 2, "CWFBLAK")
    m.box(-9, 8, -30, 30, 2, 29, "CWFCABN", left="CWFLAMS", right="CWFLAMS", back="CWFLAMS")
    m.box(-10, 10, -31, 31, 29, 31, "CWFLAMS", top="CWFLAMT", bottom="CWFLAMS")
    m.box(-5, 5, -24, -10, 31, 33, "CWFWHIT")                     # binders lying flat
    m.cyl(2, 18, 4, 31, 36, "CWFPOT", n=8)                          # small pot

@model("CW_FStalls")
def stalls(m):
    # two toilet stalls, 48 deep x 76 wide, open fronts facing +x
    for y in (-38, 0, 36):
        m.box(-24, 22, y, y + 2, 4, 60, "CWFSTAL")
    m.box(-24, -22, -38, 38, 4, 60, "CWFSTAL")
    for y in (-18, 18):
        m.box(20, 22, y - 16, y + 4, 4, 60, "CWFSTAL")                               # doors (half open look)
        m.box(-22, -12, y - 6, y + 6, 0, 22, "CWFPORC"); m.box(-22, -16, y - 6, y + 6, 22, 30, "CWFPORC")
    m.box(-24, 22, -38, 38, 60, 62, "CWFCHRM", bottom="CWFCHRM")

@model("CW_FVanity")
def vanity(m):
    # washroom sink counter 20 deep x 64 wide with mirror above
    m.box(-10, 10, -32, 32, 26, 30, "CWFGRAN")
    m.box(-10, -8, -30, 30, 0, 26, "CWFGRAN")
    for y in (-15, 15):
        m.box(-4, 6, y - 8, y + 8, 30, 30.3, "CWFPORC", top=("CWFSINK", 'fit'))
        m.box(-9, -5, y - 1, y + 1, 30, 36, "CWFCHRM")
    m.box(-10, -9, -30, 30, 36, 66, "CWFCHRM", front=("CWFMIRR", 'fit'))

@model("CW_FStairFlight")
def stair_flight(m):
    # a flight of stairs climbing along +x to the next floor, 36 wide; blocks (not walkable), with a rail
    steps = 10
    for k in range(steps):
        x0 = -45 + k * 9
        m.box(x0, 45, -18, 18, 0, 8 * (k + 1), "CWFBLAK", back=("CWFSTEP", 'fit'), top="CWFSTEP",
              left="CWFRKSD", right="CWFRKSD", front="CWFRKSD" if k == steps - 1 else None)
    for k in range(0, steps, 3):
        x = -44 + k * 9; m.box(x, x + 1.5, 17, 18.5, 8 * (k + 1), 8 * (k + 1) + 30, "CWFMETL")
    # rail: a run of short segments approximating the slope
    for k in range(steps):
        x = -45 + k * 9; z = 8 * (k + 1) + 30
        m.box(x, x + 9, 16.5, 19, z, z + 2, "CWFCHRM")

@model("CW_FElevRail")
def elev_rail(m):
    m.box(-1, 3, -40, 40, 30, 33, "CWFCHRM")
    for y in (-38, 38): m.box(-1, 1, y - 1, y + 1, 30, 33, "CWFCHRM")

# ---------------------------------------------------------------- door casings (3D frame around every doorway)
# Centred in the 16u doorway strip, facing along the door's normal; the 64u opening is left clear.
def casing(m, mat):
    for y in (-36, 32): m.box(-9.5, 9.5, y, y + 4, 0, 84, mat, bottom=None)
    m.box(-9.5, 9.5, -36, 36, 80, 84, mat, bottom=mat)
    m.box(-10, 10, -37, 37, 84, 85, mat, bottom=mat)                      # head cap
    for y in (-36, 32): m.box(-10, 10, y, y + 4, 0, 4, "CWFBLAK", bottom=None)   # plinth blocks

@model("CW_FDoorFrame")
def door_frame(m): casing(m, "CWFMETL")

@model("CW_FDoorFrameW")
def door_frame_wood(m): casing(m, "CWFWDSD")

@model("CW_FPartition")
def partition(m):
    # cubicle screen 3 thick x 64 wide x 48 tall, fabric with an aluminium cap
    m.box(-1.5, 1.5, -32, 32, 0, 46, "CWFFABB", top=None)
    m.box(-2, 2, -33, 33, 46, 48, "CWFCHRM")
    m.box(-2, 2, -33, -31, 0, 46, "CWFCHRM"); m.box(-2, 2, 31, 33, 0, 46, "CWFCHRM")


# ---------------------------------------------------------------- maglock keypads beside secured doors
# CW_Keypad: frame A = locked (red LED), B = open (green), C = dead (blackout / forced)
KEYPADS = [("A", "keypad_locked", (230, 40, 30)), ("B", "keypad_open", (60, 230, 90)), ("C", "keypad_dead", None)]

def keypad_textures():
    for frame, name, led in KEYPADS:
        im = Image.new("RGB", (12, 20), (46, 48, 54)); d = ImageDraw.Draw(im)
        d.rectangle([0, 0, 11, 19], outline=(90, 92, 98))
        d.rectangle([2, 2, 9, 5], fill=(18, 20, 24))
        if led: d.rectangle([3, 3, 8, 4], fill=led)
        for r in range(3):
            for c in range(3): d.rectangle([2 + c * 3, 8 + r * 3, 3 + c * 3, 9 + r * 3], fill=(150, 152, 158) if led else (70, 72, 76))
        d.rectangle([3, 17, 8, 18], fill=(20, 20, 22))                       # card slot
        save(im, "CWFKP" + frame, 2.0)

# wall sconce: frame A warm (lit), B red emergency, C off
SCONCES = [("A", "sconce_warm", (255, 214, 160)), ("B", "sconce_emerg", (255, 70, 50)), ("C", "sconce_off", (120, 116, 110))]

def sconce_textures():
    for frame, name, col in SCONCES:
        a = T.solid(16, 24, col); yy, xx = np.mgrid[0:24, 0:16]
        # frosted glass: brightest at the open top and bottom edges where the light escapes
        a *= (0.82 + 0.3 * (np.abs(yy - 11.5) / 11.5) ** 2)[..., None]
        a *= (1 + 0.04 * ((xx + yy) % 2))[..., None]
        save(T.to_image(a), "CWFSC" + frame, 1.0)

def build_sconces():
    for frame, name, col in SCONCES:
        m = Mesh(name)
        m.box(0, 0.8, -2.5, 2.5, 0, 16, "CWFCHRM", bottom="CWFCHRM")                  # wall plate
        m.box(0.8, 2.5, -0.8, 0.8, 7, 9, "CWFCHRM", bottom="CWFCHRM")                 # arm
        g = ("CWFSC" + frame, 'fit')
        m.box(2.5, 8.5, -3.5, 3.5, 2, 14, "CWFCHRM", front=g, left=g, right=g, back=g, top=g, bottom=g)  # glass shade
        m.write()

# stair-tower handrails: one flight = 16 steps of 14 x 10 (see genmap.stair_tower), a 64u lane between the
# solid core wall (model y = 0) and the outer wall (y = -64). The actor stands on the core wall at the flight's
# first step, facing up the flight; the lane is on its right (-y). Wall-mounted tube rails on both walls,
# 34 above the nosings, on small brackets (like a real concrete stair core).
def build_stair_rail():
    m = Mesh("stair_rail")
    N, D, R, H, L = 16, 14, 10, 34, 64
    def bar(x0, z0, x1, z1, y0, y1, t, mat):
        pts = lambda y, dz: [(x0, y, z0 + dz), (x1, y, z1 + dz)]
        Ln = math.hypot(x1 - x0, z1 - z0)
        uv = [(0, 0), (Ln / 16, 0), (Ln / 16, 1), (0, 1)]
        a0, a1 = pts(y0, 0); b0, b1 = pts(y1, 0); c0, c1 = pts(y0, t); d0, d1 = pts(y1, t)
        m.quad(mat, [c0, c1, d1, d0], uv); m.quad(mat, [a1, a0, b0, b1], uv)
        m.quad(mat, [a0, a1, c1, c0], uv); m.quad(mat, [b1, b0, d0, d1], uv)
    zr = lambda x: R + H + x * (N - 1) * R / (N * D)       # rail height above the flight start
    for wall_y, sgn in ((0, -1), (-L, 1)):                 # core wall rail, outer wall rail (both stand off into the lane)
        y0, y1 = wall_y + sgn * 2.2, wall_y + sgn * 4.0
        bar(-6, zr(0) - 6 * (N - 1) * R / (N * D), N * D + 6, zr(N * D) + 6 * (N - 1) * R / (N * D),
            min(y0, y1), max(y0, y1), 1.8, "CWFCHRM")
        for k in (1, 7, 13):                               # brackets
            x = k * D + D / 2
            ya, yb = sorted((wall_y, wall_y + sgn * 3.1))
            m.box(x - 0.5, x + 0.5, ya, yb, zr(x) - 3, zr(x), "CWFMETL", bottom="CWFMETL")
            pa, pb = sorted((wall_y, wall_y + sgn * 0.6))
            m.box(x - 1.5, x + 1.5, pa, pb, zr(x) - 4.5, zr(x) - 1.5, "CWFMETL")   # wall plate
    m.write()

def build_keypads():
    for frame, name, led in KEYPADS:
        m = Mesh(name)
        m.box(-0.8, 0.8, -3, 3, 40, 50, "CWFBLAK", front=("CWFKP" + frame, 'fit'), bottom="CWFBLAK")
        m.write()

# ---------------------------------------------------------------- 3D light fixtures (replace the old ceiling-light sprite)
# CW_CeilingLight is Height 19 and hangs from the ceiling, so each fixture's top sits at z = 19.
LIGHTS = []   # (frame letter, obj name)

def light(frame):
    def deco(fn):
        LIGHTS.append((frame, fn)); return fn
    return deco

@light("A")
def light_troffer(m):
    # recessed 2 x 4 troffer: shallow pan, prismatic lens facing down
    m.box(-12, 12, -24, 24, 16.5, 19, "CWFWHIT", bottom=("CWFLENS", 'fit'), top=None)
    m.box(-13, 13, -25, 25, 18.5, 19, "CWFWHIT", bottom="CWFWHIT", top=None)

@light("B")
def light_pendant(m):
    # drum pendant on a rod: bronze shade, warm diffuser underneath
    m.box(-0.6, 0.6, -0.6, 0.6, 7, 19, "CWFCHRM", top=None)
    m.cyl(0, 0, 3, 18, 19, "CWFCHRM", n=8)
    m.cyl(0, 0, 11, 1, 8, "CWFSHAD", n=12, top=True)
    m.cyl(0, 0, 10.5, 0.9, 1.0, "CWFDIFF", n=12, top=True)

@light("C")
def light_strip(m):
    # industrial batten: steel channel with an exposed tube, hung on two short rods
    for y in (-22, 22): m.box(-0.5, 0.5, y - 0.5, y + 0.5, 15, 19, "CWFMETL", top=None)
    m.box(-3, 3, -28, 28, 13, 15, "CWFMETL")
    m.box(-1.2, 1.2, -26, 26, 11.5, 13, "CWFTUBE", front=("CWFTUBE", 'fit'), back=("CWFTUBE", 'fit'),
          bottom=("CWFTUBE", 'fit'), left="CWFMETL", right="CWFMETL")

@light("D")
def light_downlight(m):
    # round recessed downlight with a trim ring
    m.cyl(0, 0, 7, 18, 19, "CWFWHIT", n=12, top=False)
    m.cyl(0, 0, 5.5, 17.9, 18.0, "CWFDIFF", n=12, top=True)

def exit_sign(m):
    # double-sided ceiling-hung exit box; CW_ExitSign is Height 10, rods reach the ceiling
    m.box(-1.5, 1.5, -12, 12, 0, 9, "CWFWHIT", front=("CWFEXIT", 'fit'), back=("CWFEXIT", 'fit'), bottom="CWFWHIT")
    for y in (-8, 8): m.box(-0.5, 0.5, y - 0.5, y + 0.5, 9, 10, "CWFCHRM", top=None)

def build_lights():
    for frame, fn in LIGHTS:
        m = Mesh(fn.__name__); fn(m); m.write()
    m = Mesh("exit_sign"); exit_sign(m); m.write()

def write_modeldef():
    out = ["// Generated by CorpoWars_tools/make_models.py - furniture models (sprite CWMD is a 1x1 placeholder).", ""]
    for k, (cls, name) in enumerate(MODELS):
        out += ["Model %s" % cls, "{", '\tPath "models/props"', '\tModel 0 "%s.obj"' % name, "\tScale 1.0 1.0 1.0",
                "\tDONTCULLBACKFACES", "\tFrameIndex CWMD A 0 0", "}", ""]
    # ceiling fixtures: one actor, a model per frame (style chosen by the generator)
    # (one Model block per frame: slots in a shared block would all draw on every frame)
    for frame, fn in LIGHTS:
        out += ["Model CW_CeilingLight", "{", '\tPath "models/props"', '\tModel 0 "%s.obj"' % fn.__name__,
                "\tDONTCULLBACKFACES", "\tFrameIndex CWLT %s 0 0" % frame, "}", ""]
    for frame, name, led in KEYPADS:
        out += ["Model CW_Keypad", "{", '\tPath "models/props"', '\tModel 0 "%s.obj"' % name, "\tDONTCULLBACKFACES",
                "\tFrameIndex CWKP %s 0 0" % frame, "}", ""]
    for frame, name, col in SCONCES:
        out += ["Model CW_WallSconce", "{", '\tPath "models/props"', '\tModel 0 "%s.obj"' % name, "\tDONTCULLBACKFACES",
                "\tFrameIndex CWSC %s 0 0" % frame, "}", ""]
    out += ["Model CW_StairRail", "{", '\tPath "models/props"', '\tModel 0 "stair_rail.obj"', "\tDONTCULLBACKFACES",
            "\tFrameIndex CWMD A 0 0", "}", ""]
    out += ["Model CW_ExitSign", "{", '\tPath "models/props"', '\tModel 0 "exit_sign.obj"', "\tDONTCULLBACKFACES",
            "\tFrameIndex CWEX A 0 0", "}", ""]
    open(os.path.join(ROOT, "modeldef.props.txt"), "w").write("\n".join(out))
    # placeholder sprite
    spr = os.path.join(ROOT, "sprites", "CWMDA0.png")
    Image.new("RGBA", (1, 1), (0, 0, 0, 0)).save(spr)


# =============================================================================================== site-kit props
# Street / industrial / underground / civic props for the site kits (kitprops.zs). Own RNG streams so the
# office furniture above comes out byte-identical.
RK = random.Random(4040)

def kit_textures():
    T.seed(4100)
    # corrugated container steel: vertical ribs, weathering, rust streaks from the top
    for name, base in (("CWKCONT", (150, 52, 40)), ("CWKCONB", (38, 72, 120)), ("CWKCONG", (54, 96, 70))):
        a = T.solid(64, 64, base)
        for x in range(64):
            k = 1.0 + 0.16 * math.sin(x / 64 * 2 * math.pi * 8)
            a[:, x] *= k
        a = T.vary(a, 0.06, 16); a = T.grime(a, 0.18, 8)
        streak = T.fbm(64, 64, 8, 2)
        a = T.tint(a, (streak > 0.62) * np.linspace(1, 0, 64)[:, None] * 0.8, (110, 60, 30), 0.5)
        save(T.to_image(a), name)
    # wooden crate / pallet planks (u along the planks)
    a = T.wood(64, 32, (150, 112, 70), ring=0.1, cell=16)
    for y in (0, 10, 21): a[y] *= 0.55
    a = T.grime(a, 0.12, 8); save(T.to_image(a), "CWKCRAT")
    # poured concrete
    a = T.vary(T.solid(64, 64, (150, 148, 142)), 0.06, 16); a = T.grain(a, 0.05)
    a = T.speckle(a, 0.03, (110, 108, 104), 0.6); a = T.grime(a, 0.18, 16)
    save(T.to_image(a), "CWKCONC")
    # hazard stripes, painted yellow steel
    im = Image.new("RGB", (32, 32), (220, 180, 30)); d = ImageDraw.Draw(im)
    for k in range(-2, 4): d.polygon([(k * 16, 0), (k * 16 + 8, 0), (k * 16 + 40, 32), (k * 16 + 32, 32)], fill=(24, 24, 26))
    a = T.grime(T.from_image(im), 0.2, 8); save(T.to_image(a), "CWKHAZD")
    a = T.brushed(32, 32, (206, 170, 40), 0.06); a = T.grime(a, 0.2, 8)
    a = T.scratches(a, 6, 8, (120, 110, 90), 0.4); save(T.to_image(a), "CWKYELL")
    # dark green utility paint (dumpsters, transformers, generators)
    a = T.brushed(32, 32, (52, 78, 58), 0.06); a = T.vary(a, 0.05, 16); a = T.grime(a, 0.22, 8)
    a = T.scratches(a, 5, 6, (120, 122, 118), 0.35); save(T.to_image(a), "CWKGREN")
    # rust
    a = T.vary(T.solid(32, 32, (120, 66, 38)), 0.12, 8, 4); a = T.grain(a, 0.08)
    a = T.speckle(a, 0.08, (70, 40, 26), 0.8); a = T.speckle(a, 0.03, (150, 110, 70), 0.6)
    save(T.to_image(a), "CWKRUST")
    # burlap sandbags
    a = T.weave(32, 32, (150, 128, 90), 0.14); a = T.vary(a, 0.08, 8); a = T.grime(a, 0.2, 8)
    save(T.to_image(a), "CWKSACK")
    # mattress ticking
    a = T.solid(32, 32, (206, 208, 214))
    for x in range(0, 32, 4): a[:, x] = (120, 140, 180)
    a = T.vary(a, 0.04, 16); a = T.grain(a, 0.03); save(T.to_image(a), "CWKMATT")
    # grow bed canopy: dense leaves on soil
    a = T.solid(32, 32, (46, 110, 40)); leaf = T.fbm(32, 32, 4, 3)
    a = T.tint(a, leaf > 0.55, (90, 170, 60), 0.8); a = T.tint(a, leaf < 0.3, (40, 30, 22), 0.9)
    save(T.to_image(a), "CWKLEAF")
    # stall awning: red and white stripes
    im = Image.new("RGB", (32, 16), (230, 230, 226)); d = ImageDraw.Draw(im)
    for x in range(0, 32, 8): d.rectangle([x, 0, x + 3, 15], fill=(190, 40, 40))
    a = T.vary(T.from_image(im), 0.05, 8); save(T.to_image(a), "CWKAWNG")
    # locker bank front (fit): two doors, vents, handles
    im = Image.new("RGB", (36, 72), (78, 96, 118)); d = ImageDraw.Draw(im)
    for x0 in (1, 19):
        d.rectangle([x0, 1, x0 + 15, 70], fill=(92, 112, 136)); bevel(d, (x0, 1, x0 + 15, 70), (130, 150, 170), (50, 62, 78))
        for y in range(5, 17, 3): d.line([x0 + 3, y, x0 + 12, y], fill=(40, 48, 60))
        d.rectangle([x0 + 11, 34, x0 + 12, 40], fill=(180, 184, 190))
    save(im, "CWKLOCK", 1.0)
    # generator front (fit): panel with gauges, louvres
    im = Image.new("RGB", (72, 56), (60, 86, 64)); d = ImageDraw.Draw(im)
    d.rectangle([4, 6, 28, 30], fill=(30, 32, 34))
    for k, x in enumerate((8, 18)): d.ellipse([x, 10, x + 7, 17], fill=(230, 230, 220)); d.line([x + 3, 13, x + 5 + k, 11], fill=(200, 30, 30))
    d.rectangle([7, 22, 25, 26], fill=(40, 160, 70))
    for y in range(8, 50, 4): d.line([34, y, 68, y], fill=(34, 50, 38))
    save(im, "CWKGENF", 1.0)
    # air-con front (fit): fan grille
    im = Image.new("RGB", (56, 40), (196, 198, 196)); d = ImageDraw.Draw(im)
    d.ellipse([4, 4, 36, 36], fill=(60, 62, 64))
    for r in range(4, 16, 3): d.ellipse([20 - r, 20 - r, 20 + r, 20 + r], outline=(150, 152, 150))
    for y in range(6, 36, 3): d.line([40, y, 52, y], fill=(150, 152, 150))
    save(im, "CWKACFR", 1.0)
    # transformer fins (fit)
    im = Image.new("RGB", (64, 64), (60, 80, 64)); d = ImageDraw.Draw(im)
    for x in range(2, 64, 5): d.rectangle([x, 4, x + 2, 60], fill=(80, 104, 84))
    d.rectangle([22, 24, 42, 36], fill=(220, 200, 40)); d.polygon([(32, 26), (28, 31), (32, 31), (30, 35), (36, 29), (32, 29)], fill=(20, 20, 20))
    save(im, "CWKTRFN", 1.0)


def hcyl(m, cx, cz, r, y0, y1, mat, n=8):
    """n-gon prism lying along y (pipes, turbine casings, tanks on their side)."""
    pts = [(cx + r * math.cos(2 * math.pi * k / n), cz + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    per = 2 * math.pi * r
    for k in range(n):
        a, b = pts[k], pts[(k + 1) % n]
        u0, u1 = k / n * per, (k + 1) / n * per
        m.quad(mat, [(a[0], y1, a[1]), (b[0], y1, b[1]), (b[0], y0, b[1]), (a[0], y0, a[1])],
               [m._uv(mat, y1, u0), m._uv(mat, y1, u1), m._uv(mat, y0, u1), m._uv(mat, y0, u0)])
    for y, flip in ((y0, False), (y1, True)):
        for k in range(n):
            a, b = pts[k], pts[(k + 1) % n]
            q = [(cx, y, cz), (a[0], y, a[1]), (b[0], y, b[1]), (cx, y, cz)]
            if flip: q = q[::-1]
            m.quad(mat, q, [m._uv(mat, 0, 0)] * 4)

@model("CW_FLampPost")
def lamp_post(m):
    m.box(-5, 5, -5, 5, 0, 6, "CWFBLAK")
    m.cyl(0, 0, 2.5, 6, 116, "CWFMETL", n=6)
    m.box(-2, 26, -2, 2, 112, 115, "CWFMETL")
    m.box(14, 34, -6, 6, 108, 113, "CWFBLAK", bottom=("CWFDIFF", 'fit'))

def container(m, mat):
    m.box(-100, 100, -40, 40, 0, 88, mat, top="CWFMETL")
    for x in (-100, 97):                                   # corner posts
        for y in (-40, 37): m.box(x, x + 3, y, y + 3, 0, 88.5, "CWFBLAK")
    for y in (-20, 20): m.box(100, 101.5, y - 1, y + 1, 4, 84, "CWFMETL")   # door bars

@model("CW_FContainer")
def container_red(m): container(m, "CWKCONT")

@model("CW_FContainerB")
def container_blue(m): container(m, "CWKCONB")

@model("CW_FCrates")
def crates(m):
    m.box(-20, 16, -20, 16, 0, 24, "CWKCRAT")
    m.box(-8, 20, 2, 20, 0, 20, "CWKCRAT")
    m.box(-16, 8, -14, 10, 24, 46, "CWKCRAT")

@model("CW_FPallet")
def pallet(m):
    for y in (-24, -2, 20): m.box(-20, 20, y, y + 4, 0, 4, "CWKCRAT")
    m.box(-20, 20, -24, 24, 4, 6, "CWKCRAT")
    m.box(-18, 18, -22, 22, 6, 32, "CWFBOX", top="CWFBOX")
    m.box(-18.5, 18.5, -22.5, 22.5, 12, 14, "CWFWHIT")    # strapping

@model("CW_FBarCounter")
def bar_counter(m):
    m.box(-14, 12, -64, 64, 0, 40, "CWFWDSD", front="CWFWOOD")
    m.box(-16, 14, -65, 65, 40, 44, "CWFWDSD", top="CWFWOOD", bottom="CWFWDSD")
    m.box(13, 15, -62, 62, 4, 6, "CWFCHRM")                # foot rail
    for y in range(-56, 60, 16): m.box(-12, -8, y, y + 3, 44, 54, "CWFCHRM")   # taps

@model("CW_FStool")
def stool(m):
    m.cyl(0, 0, 6, 0, 1, "CWFBLAK", n=8)
    m.cyl(0, 0, 1.5, 1, 22, "CWFCHRM", n=6)
    m.cyl(0, 0, 8, 22, 26, "CWFLEAT", n=10)

@model("CW_FBed")
def bed(m):
    m.box(-40, 40, -22, 22, 0, 12, "CWFMETL", top=None)
    m.box(-39, 39, -21, 21, 12, 20, "CWKMATT")
    m.box(-36, 14, -21.5, 21.5, 20, 22, "CWFFABB")          # blanket
    m.box(-38, -26, -14, 14, 20, 24, "CWFWHIT")               # pillow
    m.box(-42, -40, -22, 22, 0, 30, "CWFMETL")                # head rail

@model("CW_FPew")
def pew(m):
    m.box(-10, 10, -48, 48, 14, 17, "CWFWDSD", top="CWFWOOD")
    m.box(-12, -9, -48, 48, 17, 34, "CWFWDSD", front="CWFWOOD")
    for y in (-48, 45): m.box(-12, 10, y, y + 3, 0, 30, "CWFWDSD")

@model("CW_FTank")
def tank(m):
    for x, y in ((-20, -20), (17, -20), (-20, 17), (17, 17)): m.box(x, x + 3, y, y + 3, 0, 10, "CWFMETL")
    m.cyl(0, 0, 30, 8, 88, "CWFMETL", n=12)
    m.cyl(0, 0, 20, 88, 94, "CWFMETL", n=10)
    m.box(28, 32, -4, 4, 20, 26, "CWKYELL")                  # valve

@model("CW_FTransformer")
def transformer(m):
    m.box(-20, 20, -28, 28, 0, 56, "CWKGREN", front=("CWKTRFN", 'fit'), back=("CWKTRFN", 'fit'))
    for y in (-30, 28): m.box(-16, 16, y, y + 2, 6, 50, "CWKGREN")
    for y in (-16, 0, 16):
        m.cyl(0, y, 3.5, 56, 70, "CWFWHIT", n=6)
        m.cyl(0, y, 5, 62, 64, "CWFWHIT", n=6)

@model("CW_FScaffold")
def scaffold(m):
    for x in (-16, 14):
        for y in (-48, -1, 46): m.box(x, x + 2, y, y + 2, 0, 128, "CWFMETL")
    for z in (60, 124):
        m.box(-16, 16, -48, 48, z, z + 3, "CWKCRAT")
        m.box(-17, 17, -48, 48, z + 18, z + 20 if z < 100 else z + 3, "CWKYELL", top="CWKYELL")
    for y in (-48, 46): m.box(-16, 16, y, y + 2, 30, 32, "CWFMETL")

@model("CW_FDumpster")
def dumpster(m):
    m.box(-18, 16, -36, 36, 4, 40, "CWKGREN")
    m.box(-19, 17, -37, 37, 40, 44, "CWFBLAK")
    for x, y in ((-16, -34), (12, -34), (-16, 32), (12, 32)): m.box(x, x + 3, y, y + 3, 0, 4, "CWFBLAK")
    m.box(16, 18, -30, 30, 30, 33, "CWFMETL")

@model("CW_FStall")
def stall(m):
    m.box(-22, 22, -40, 40, 26, 30, "CWKCRAT")
    m.box(-20, 20, -38, 38, 0, 26, "CWFFABG", top=None)
    for x in (-24, 22):
        for y in (-40, 38): m.box(x, x + 2, y, y + 2, 0, 68, "CWFMETL")
    m.box(-26, 28, -42, 42, 68, 72, "CWKAWNG", front="CWKAWNG", top="CWKAWNG", bottom="CWKAWNG")
    for k in range(6):
        y = -34 + k * 12; m.box(-10 + (k % 2) * 8, 2 + (k % 2) * 8, y, y + 9, 30, 36 + (k % 3) * 2, RK.choice(("CWFBOX", "CWKLEAF", "CWKCONT")))

@model("CW_FGrowBed")
def grow_bed(m):
    m.box(-18, 18, -60, 60, 0, 22, "CWFWHIT", top=None)
    m.box(-16, 16, -58, 58, 16, 30, "CWKLEAF", front="CWKLEAF", back="CWKLEAF")
    for y in (-58, 56): m.box(-2, 2, y, y + 2, 22, 40, "CWFMETL")
    m.box(-4, 4, -58, 58, 38, 40, "CWFBLAK", bottom=("CWFDIFF", 'fit'))

@model("CW_FTurbine")
def turbine(m):
    m.box(-48, 48, -80, 80, 0, 24, "CWKCONC")
    hcyl(m, 0, 60, 38, -76, 50, "CWKGREN", n=10)
    hcyl(m, 0, 60, 26, 50, 78, "CWFMETL", n=10)
    m.box(-8, 8, -40, -20, 96, 112, "CWFMETL")               # steam inlet
    m.box(-46, -44, -78, 78, 24, 60, "CWKYELL")               # guard rail
    m.box(44, 46, -78, 78, 24, 60, "CWKYELL")

@model("CW_FPipes")
def pipes(m):
    for y in (-56, 0, 54): m.box(-12, 12, y, y + 2, 0, 60, "CWKYELL")
    for x, z, r, mat in ((-6, 22, 5, "CWKGREN"), (6, 22, 4, "CWFMETL"), (-4, 50, 6, "CWFMETL"), (7, 50, 3.5, "CWKRUST")):
        hcyl(m, x, z, r, -60, 60, mat, n=6)

@model("CW_FGenerator")
def generator(m):
    m.box(-20, 20, -36, 36, 0, 4, "CWFBLAK")
    m.box(-18, 18, -34, 34, 4, 50, "CWKGREN", front=("CWKGENF", 'fit'))
    m.cyl(-8, 24, 3, 50, 60, "CWFBLAK", n=6)                 # exhaust

@model("CW_FTurnstile")
def turnstile(m):
    m.box(-16, 16, -6, 6, 0, 36, "CWFCHRM", top="CWFBLAK")
    for k in range(3):
        a = k * 2 * math.pi / 3
        dx, dz = math.cos(a) * 18, math.sin(a) * 4
        m.box(-1 + dx / 2, 1 + dx / 2, 6, 24, 30 + dz, 32 + dz, "CWFCHRM")

@model("CW_FLocker")
def locker(m):
    m.box(-9, 9, -18, 18, 0, 72, "CWFMETL", front=("CWKLOCK", 'fit'))

@model("CW_FScrap")
def scrap(m):
    for k in range(9):
        w, d, h = RK.uniform(14, 34), RK.uniform(14, 34), RK.uniform(8, 24)
        x, y = RK.uniform(-30 + w / 2, 30 - w / 2), RK.uniform(-30 + d / 2, 30 - d / 2)
        z = 0 if k < 5 else RK.uniform(10, 36)
        m.box(x - w / 2, x + w / 2, y - d / 2, y + d / 2, z, min(62, z + h), RK.choice(("CWKRUST", "CWKRUST", "CWFMETL", "CWKCONB")))
    hcyl(m, 4, 14, 12, -26, 18, "CWFBLAK", n=10)             # a tyre

@model("CW_FWorkbench")
def workbench(m):
    for x in (-13, 11):
        for y in (-38, 36): m.box(x, x + 2, y, y + 2, 0, 33, "CWFMETL")
    m.box(-15, 15, -40, 40, 33, 36, "CWFWDSD", top="CWFWOOD")
    m.box(-13, 13, -38, 38, 8, 10, "CWFMETL")
    m.box(-13, 13, -36, -10, 10, 20, "CWFBOX")
    m.box(6, 14, 26, 36, 36, 44, "CWKGREN")                 # vice
    m.box(-15, -13, -40, 40, 36, 70, "CWFRKSD")               # pegboard

@model("CW_FAcUnit")
def ac_unit(m):
    m.box(-20, 20, -28, 28, 0, 3, "CWFBLAK")
    m.box(-18, 18, -26, 26, 3, 40, "CWFWHIT", front=("CWKACFR", 'fit'), top="CWFMETL")

@model("CW_FWaterTower")
def water_tower(m):
    for x, y in ((-30, -30), (27, -30), (-30, 27), (27, 27)): m.box(x, x + 3, y, y + 3, 0, 62, "CWKRUST")
    m.box(-30, 30, -30, 30, 58, 62, "CWKCRAT")
    m.cyl(0, 0, 34, 62, 110, "CWKCRAT", n=12)
    m.cyl(0, 0, 22, 110, 118, "CWKRUST", n=12)

@model("CW_FBarrier")
def barrier(m):
    m.box(-10, 10, -36, 36, 0, 8, "CWKCONC")
    m.box(-6, 6, -36, 36, 8, 26, "CWKCONC")
    m.box(-4, 4, -36, 36, 26, 32, "CWKCONC", top="CWKCONC")
    m.box(-6.5, 6.5, -20, 20, 14, 18, "CWKHAZD", front="CWKHAZD", back="CWKHAZD", top=None)

@model("CW_FSandbags")
def sandbags(m):
    for row in range(4):
        z = row * 9; off = 8 if row % 2 else 0
        w = 24 - row * 3
        y = -36 + off
        while y + 16 <= 36:
            m.box(-w / 2, w / 2, y, y + 16, z, z + 9, "CWKSACK")
            y += 17


if __name__ == "__main__":
    make_textures()
    light_textures()
    keypad_textures()
    sconce_textures()
    kit_textures()
    build_models()
    build_lights()
    build_keypads()
    build_sconces()
    build_stair_rail()
    write_modeldef()
    print(len(TEX), "textures,", len(MODELS), "models")
