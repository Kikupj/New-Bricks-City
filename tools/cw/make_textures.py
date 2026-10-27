# Generates the Corpo Wars office texture + prop sprite set (original art, drawn in code).
# Writes into CorpoWars/textures (walls + flats, usable as either) and CorpoWars/sprites.
# Re-run any time: output is deterministic.
import os, random, struct, zlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars")
TEX = os.path.join(ROOT, "textures"); SPR = os.path.join(ROOT, "sprites")
FONTB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
for f in (FONTB, FONT):
    if not os.path.exists(f):
        import glob; c = glob.glob("/usr/share/fonts/truetype/**/*.ttf", recursive=True); FONTB = FONT = c[0]; break
R = random.Random(1987)

def noise(im, amt, box=None):
    px = im.load(); w, h = im.size
    x0, y0, x1, y1 = box or (0, 0, w, h)
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = px[x, y]; d = R.randint(-amt, amt)
            px[x, y] = tuple(max(0, min(255, c + d)) for c in p[:3]) + p[3:]
    return im

def save_tex(im, name):
    im.convert("RGB").save(os.path.join(TEX, name + ".png")); print("tex", name, im.size)

def save_sprite(im, name):
    p = os.path.join(SPR, name + ".png"); im.save(p)
    d = open(p, "rb").read()                       # add grAb (centre-bottom offset) after IHDR
    body = b"grAb" + struct.pack(">ii", im.size[0] // 2, im.size[1] - 2)
    chunk = struct.pack(">I", 8) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)
    open(p, "wb").write(d[:33] + chunk + d[33:]); print("spr", name, im.size)

def font(sz, bold=True): return ImageFont.truetype(FONTB if bold else FONT, sz)

# ---------------------------------------------------------------- walls (128 x 128, baseboard at the bottom)
# Detail pass: material variation (fbm), baked top-light / floor AO, bevelled seams and trims, scuffs and grime,
# so the custom set sits next to the stock and A.D. Cop textures instead of reading as flat colour.
import texlib as T
T.seed(1987)

def baseboard(img, board, top=118):
    """Vinyl skirting: rows top..127 with a lit top edge, a shadow line on the wall above, and scuffs."""
    h = img.shape[0]
    b = T.vary(T.solid(img.shape[1], h - top, board), 0.06, 8)
    b = T.vgrad(b, 1.12, 0.85)
    b[0] *= 1.45; b[1] *= 1.15
    img[top:] = b
    img[top - 1] *= 0.72; img[top - 2] *= 0.88
    return img

def plaster_arr(base=(182, 180, 172), board=(44, 44, 48), seams=(), rs_seed=None):
    if rs_seed is not None: T.seed(rs_seed)
    img = T.solid(128, 128, base)
    img = T.vary(img, 0.035, 48, 4)                     # broad trowel mottling
    img = T.vary(img, 0.02, 8, 2)                       # fine texture
    img = T.grain(img, 0.018)
    # faint vertical roller marks
    streak = T.fbm(128, 1, 6, 3)[0]
    img *= (1 + (streak - 0.5) * 0.03)[None, :, None]
    img = T.vgrad(img, 1.04, 0.95, 0, 118)              # light from the ceiling fixtures
    img = T.grime(img, 0.10, 12)
    for x in seams: T.groove_v(img, x, 0.8, 1.08, 0, 118)
    img[0] *= 0.82; img[1] *= 0.93                      # ceiling contact shadow
    return baseboard(img, board)

def plaster(base=(182, 180, 172), board=(44, 44, 48)):
    return T.to_image(plaster_arr(base, board))

def wall_plain():
    save_tex(T.to_image(plaster_arr(rs_seed=11)), "CWWALL1")
    save_tex(T.to_image(plaster_arr(seams=(0, 64), rs_seed=12)), "CWWALL2")
    T.seed(13)
    img = T.vary(T.solid(128, 128, (182, 180, 172)), 0.035, 48, 4); img = T.grain(img, 0.018)
    img = T.grime(img, 0.06, 12, False)
    save_tex(T.to_image(img), "CWWALLH")               # header over doors

def wall_wood():
    # walnut boarding: 32u boards, each its own grain and tint, V-grooves, a chair rail and a dark skirting
    T.seed(21)
    img = np.zeros((128, 128, 3))
    for k in range(4):
        b = T.wood(32, 128, (96 + k * 3 % 7, 60, 36), ring=0.14, cell=32, along_x=False)
        b *= 0.94 + 0.12 * T.rng().random()
        img[:, k * 32:(k + 1) * 32] = b
    img = T.vgrad(img, 1.06, 0.92, 0, 118)
    for x in (0, 32, 64, 96): T.groove_v(img, x, 0.55, 1.2, 0, 118)
    T.rect(img, 0, 16, 127, 20, (122, 84, 54)); img[16] *= 1.3; img[20] *= 0.7; img[21] *= 0.8   # chair rail
    img = baseboard(img, (32, 22, 16))
    img = T.grime(img, 0.08, 12)
    save_tex(T.to_image(img), "CWWOOD1")

def wall_dark():
    # dark honed stone, 64 x 64 slabs with fine veins and bevelled joints
    T.seed(31)
    img = T.solid(128, 128, (60, 62, 68))
    img = T.vary(img, 0.08, 32, 5)
    vein = T.fbm(128, 128, 48, 5)
    v = np.exp(-((vein - 0.5) * 90) ** 2)
    img = T.tint(img, v, (104, 106, 114), 0.55)
    for x0 in (0, 64):
        for y0 in (0, 64):
            T.rect_mul(img, x0, y0, x0 + 63, y0 + 63, 0.93 + 0.14 * T.rng().random())
            T.bevel(img, x0, y0, x0 + 63, min(y0 + 63, 117), 1.25, 0.6)
    img = T.vgrad(img, 1.08, 0.9, 0, 118)
    save_tex(T.to_image(baseboard(img, (24, 24, 28))), "CWWALLD")   # dark accent / lobby stone
    # service block wall: painted CMU, running bond, pitted face, recessed mortar
    T.seed(32)
    img = T.solid(128, 128, (118, 118, 120))
    img = T.vary(img, 0.05, 16, 4); img = T.grain(img, 0.05)
    pits = T.white(128, 128) < 0.03; img[pits] *= 0.7
    for i, y in enumerate(range(0, 128, 32)):
        for x in range(0 if i % 2 else 32, 128 + 64, 64):
            T.rect_mul(img, max(x - 64, 0), y, min(x - 1, 127), y + 31, 0.95 + 0.08 * T.rng().random())
        T.groove_h(img, y, 0.62, 1.12)
        for x in range(0 if i % 2 else 32, 128, 64): T.groove_v(img, x, 0.62, 1.12, y, y + 32)
    img = T.grime(img, 0.18, 12)
    img = T.vgrad(img, 1.03, 0.92)
    save_tex(T.to_image(img), "CWCONCW")

def wall_tile():
    # glazed 16u tiles: per-tile tint, grout AO, a glaze glint per tile, dark tile band at the bottom
    T.seed(41)
    img = T.solid(128, 128, (218, 220, 214))
    r = T.rng()
    for ty in range(0, 128, 16):
        for tx in range(0, 128, 16):
            dark = ty >= 112
            col = (62, 74, 84) if dark else (218, 220, 214)
            t = T.solid(16, 16, col) * (0.95 + 0.08 * r.random())
            t = T.vary(t, 0.03, 8, 2)
            t = T.bevel(t, 0, 0, 15, 15, 1.08, 0.85)
            t[2:4, 2:6] *= 1.08
            img[ty:ty + 16, tx:tx + 16] = t
            img[ty, tx:tx + 16] *= 0.72; img[ty:ty + 16, tx] *= 0.72    # grout
    img = T.grime(img, 0.08, 16)
    img = T.vgrad(img, 1.04, 0.93)
    save_tex(T.to_image(img), "CWTILEW")

def wall_server():
    T.seed(51)
    img = T.solid(128, 128, (34, 36, 42)); img = T.vary(img, 0.08, 16)
    r = T.rng(); leds = np.zeros((128, 128))
    for x in range(4, 128, 32):
        T.rect(img, x, 8, x + 24, 116, (20, 21, 25)); T.bevel(img, x, 8, x + 24, 116, 1.9, 0.6)
        for y in range(12, 112, 5):
            T.rect(img, x + 2, y, x + 22, y + 3, (44, 46, 54)); T.bevel(img, x + 2, y, x + 22, y + 3, 1.4, 0.7)
            for k in range(r.integers(0, 4)):
                lx = x + 4 + k * 3; img[y + 1, lx] = [(60, 170, 255), (80, 230, 120), (255, 170, 40)][r.integers(0, 3)]
                leds[y + 1, lx] = 1
            if r.random() < 0.5: T.rect(img, x + 13, y + 1, x + 20, y + 2, (26, 26, 30))
    img = T.glow(img, leds, (40, 90, 60), 1.5, 0.8)
    T.rect(img, 0, 120, 127, 127, (18, 18, 22)); img[120] *= 1.6
    save_tex(T.to_image(img), "CWSRVWL")

def window():
    # night city through floor-to-ceiling glass: mullions, sill, distant towers with lit windows
    T.seed(61)
    img = np.zeros((128, 128, 3))
    for y in range(128): img[y] = (14 + y // 10, 16 + y // 9, 34 + y // 5)
    r = T.rng(); lit = np.zeros((128, 128))
    for _ in range(11):
        w = int(r.integers(10, 26)); x = int(r.integers(-8, 120)); top = int(r.integers(20, 80))
        x0, x1 = max(x, 0), min(x + w, 127)
        img[top:118, x0:x1] = (22, 24, 36); img[top:118, x0:x1] *= np.linspace(1.2, 0.8, x1 - x0)[None, :, None] if x1 > x0 else 1
        for yy in range(top + 4, 116, 6):
            for xx in range(x + 2, x + w - 2, 4):
                if 0 <= xx < 128 and r.random() < 0.35:
                    img[yy, xx] = [(230, 200, 120), (200, 210, 230), (240, 180, 90)][r.integers(0, 3)]; lit[yy, xx] = 1
    img = T.glow(img, lit, (90, 70, 40), 1.2, 0.5)
    T.rect(img, 0, 0, 127, 5, (40, 42, 48)); T.rect(img, 0, 112, 127, 127, (40, 42, 48))
    T.bevel(img, 0, 112, 127, 127, 1.5, 0.6); T.bevel(img, 0, 0, 127, 5, 1.3, 0.6)
    for x in (0, 64): T.rect(img, x, 0, x + 1, 127, (52, 54, 60)); img[:, x] *= 1.4
    img[6] = img[6] * 0.5 + np.array((90, 110, 140)) * 0.5
    img = T.draw_on(img, lambda d, im: [d.line([x, 10, x + 20, 30], fill=(60, 72, 100)) for x in (8, 72)])
    save_tex(T.to_image(img), "CWWINDO")

def logo_mark(d, cx, cy, s, col):
    # original abstract corporate mark: split chevron in a ring
    d.ellipse([cx - s, cy - s, cx + s, cy + s], outline=col, width=max(1, s // 6))
    d.polygon([(cx - s * .55, cy - s * .35), (cx, cy + s * .5), (cx + s * .55, cy - s * .35), (cx, cy + s * .05)], fill=col)

def framed(im, box, fill, frame=(24, 24, 28)):
    """A mounted panel with a drop shadow and bevelled frame, drawn on a PIL image."""
    a = T.from_image(im); x0, y0, x1, y1 = box
    T.rect_mul(a, x0 + 2, y0 + 2, x1 + 2, y1 + 2, 0.7)          # shadow on the wall
    T.rect(a, x0, y0, x1, y1, frame); T.bevel(a, x0, y0, x1, y1, 1.8, 0.6)
    T.rect(a, x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)
    a = T.vgrad(a, 1.0, 1.0)
    return T.to_image(a)

def decor():
    # 64-wide panels for the closed door segments of a wall: logo, slogans, signage
    slogans = [("PEOPLE", "DATA", "POTENTIAL"), ("DISCIPLINE", "CREATES", "FREEDOM"),
               ("SECURITY", "STABILITY", "TOMORROW"), ("SERVICE", "KEEPS US", "RUNNING")]
    im = plaster().crop((0, 0, 64, 128)); d = ImageDraw.Draw(im)
    logo_mark(d, 32, 72, 18, (40, 42, 48)); save_tex(im, "CWLOGO1")
    im = T.to_image(plaster_arr((60, 62, 68), (24, 24, 28))).crop((0, 0, 64, 128)); d = ImageDraw.Draw(im)
    logo_mark(d, 32, 72, 18, (200, 196, 180)); logo_mark(d, 32, 71, 18, (230, 226, 210)); save_tex(im, "CWLOGO2")
    for i, s in enumerate(slogans):
        im = framed(plaster().crop((0, 0, 64, 128)), (8, 40, 56, 110), (40, 42, 50)); d = ImageDraw.Draw(im)
        for k, line in enumerate(s):
            f = font(7); w = d.textlength(line, font=f)
            d.text((32 - w / 2, 50 + k * 12), line, font=f, fill=(210, 210, 206))
        logo_mark(d, 32, 99, 6, (160, 160, 160))
        a = T.from_image(im); a[41:109, 9:55] = T.vgrad(a[41:109, 9:55].copy(), 1.15, 0.85); save_tex(T.to_image(a), "CWPOST%d" % (i + 1))
    for name, text, arrow in (("CWSGELEV", "ELEVATORS", True), ("CWSGSTAI", "STAIRS", True),
                              ("CWSGREST", "RESTROOMS", True), ("CWSGEXIT", "EXIT", False), ("CWSGSERV", "SERVICE", True)):
        green = name == "CWSGEXIT"
        im = framed(plaster().crop((0, 0, 64, 128)), (4, 44, 60, 62), (20, 120, 50) if green else (30, 32, 38), (70, 72, 78)); d = ImageDraw.Draw(im)
        f = font(7 if len(text) > 7 else 9); w = d.textlength(text, font=f)
        d.text((32 - w / 2 - (4 if arrow else 0), 48), text, font=f, fill=(235, 235, 230))
        if arrow: d.polygon([(52, 49), (57, 53), (52, 57)], fill=(235, 235, 230))
        save_tex(im, name)

def elevator_door():
    T.seed(71)
    img = T.brushed(64, 128, (150, 154, 160), 0.10, horizontal=False)
    frame = T.brushed(64, 128, (72, 74, 80), 0.08)
    img[:12] = frame[:12]; img[:, :6] = frame[:, :6]; img[:, 58:] = frame[:, 58:]
    T.bevel(img, 6, 12, 57, 127, 1.35, 0.6); T.bevel(img, 0, 0, 63, 127, 1.2, 0.7)
    img[12:, 31] *= 0.45; img[12:, 32] *= 1.3                      # leaf meeting line
    img = T.vgrad(img, 1.1, 0.9, 12, 128)
    T.rect(img, 26, 3, 38, 8, (16, 16, 18))
    img = T.draw_on(img, lambda d, im: d.text((28, 1), "12", font=font(6), fill=(255, 150, 40)))
    img = T.grime(img, 0.12, 10)
    save_tex(T.to_image(img), "CWELEVD")
    # stairwell fire door: painted steel, raised panels, vision panel, push bar, scuffed kick zone
    T.seed(72)
    img = T.vary(T.solid(64, 128, (140, 34, 32)), 0.06, 16)
    T.rect(img, 6, 10, 57, 127, (122, 38, 34)); T.bevel(img, 6, 10, 57, 127, 1.35, 0.55)
    T.rect(img, 20, 24, 44, 44, (40, 60, 72)); T.inset(img, 20, 24, 44, 44, 1.5, 0.5)
    img = T.draw_on(img, lambda d, im: d.line([23, 40, 36, 27], fill=(90, 120, 140)))
    T.rect(img, 12, 62, 54, 67, (190, 190, 192)); T.bevel(img, 12, 62, 54, 67, 1.2, 0.6)
    T.rect_mul(img, 8, 104, 55, 124, 0.85); img = T.grime(img, 0.2, 8)
    save_tex(T.to_image(img), "CWFIRED")

# ---------------------------------------------------------------- flats
def ceiling():
    # 2 x 2 fissured acoustic tiles on a T-bar grid
    T.seed(81)
    img = T.solid(128, 128, (176, 176, 170))
    img = T.vary(img, 0.03, 32)
    fiss = T.fbm(128, 128, 8, 3)
    worm = np.exp(-((fiss - 0.5) * 55) ** 2) * (T.white(128, 128) < 0.7)
    img = T.tint(img, worm, (136, 136, 132), 0.7)
    img = T.speckle(img, 0.06, (150, 150, 146), 0.6)
    for x0 in (0, 64):
        for y0 in (0, 64):
            T.rect_mul(img, x0, y0, x0 + 63, y0 + 63, 0.96 + 0.06 * T.rng().random())
            T.inset(img, x0 + 2, y0 + 2, x0 + 61, y0 + 61, 1.08, 0.86)
    for v in (0, 1, 63, 64, 127):
        img[:, v] = (206, 206, 202); img[v, :] = (206, 206, 202)
    img[:, 1] *= 0.8; img[1, :] *= 0.8; img[:, 64] *= 0.8; img[64, :] *= 0.8
    save_tex(T.to_image(img), "CWCEILT")
    # a prismatic troffer lens in one of the four bays
    lens = T.solid(58, 58, (236, 240, 244))
    yy, xx = np.mgrid[0:58, 0:58]
    lens *= (1 + 0.05 * (((xx // 2 + yy // 2) % 2) * 2 - 1))[..., None]
    lens *= (1.0 - 0.12 * (np.hypot(xx - 29, yy - 29) / 41))[..., None]
    img[67:125, 67:125] = lens; T.bevel(img, 66, 66, 125, 125, 0.75, 0.75)
    save_tex(T.to_image(img), "CWCEILL")                           # tiles with a light panel every 2x2
    # dark open ceiling: painted deck with ribs (lobby / service)
    T.seed(82)
    img = T.vary(T.solid(64, 64, (46, 48, 54)), 0.08, 16)
    for x in range(0, 64, 16): T.rect(img, x, 0, x + 5, 63, (38, 40, 46)); T.bevel(img, x, 0, x + 5, 63, 1.3, 0.7)
    img = T.grime(img, 0.15, 8, False)
    save_tex(T.to_image(img), "CWCEILD")

def carpet(base, seedv, pattern):
    # 32u carpet tiles laid quarter-turn: directional loop pile, per-tile tint, flecks, soft traffic wear
    T.seed(seedv)
    img = np.zeros((64, 64, 3)); yy, xx = np.mgrid[0:32, 0:32]
    for ty in (0, 32):
        for tx in (0, 32):
            rot = ((ty // 32) + (tx // 32)) % 2
            lines = ((yy if rot else xx) % 3 == 0) * 1.0
            t = T.solid(32, 32, base) * (1 - 0.07 * lines)[..., None]
            t = T.grain(t, 0.08); t = T.vary(t, 0.05, 8, 2)
            t *= 0.96 + 0.06 * T.rng().random()
            img[ty:ty + 32, tx:tx + 32] = t
    img = T.speckle(img, 0.03, T.np.clip(np.array(base) * 1.6, 0, 255), 0.5)
    img = T.speckle(img, 0.03, np.array(base) * 0.5, 0.5)
    if pattern:
        img = T.tint(img, ((np.mgrid[0:64, 0:64][0] + np.mgrid[0:64, 0:64][1]) % 16 == 0) * 1.0, np.array(base) * 1.25, 0.4)
    img = T.vary(img, 0.05, 32, 3)
    for v in (0, 32): img[v, :] *= 0.88; img[:, v] *= 0.88
    return img

def floors():
    save_tex(T.to_image(carpet((64, 66, 72), 91, False)), "CWCARP1")
    save_tex(T.to_image(carpet((54, 60, 80), 92, True)), "CWCARP2")
    save_tex(T.to_image(carpet((82, 64, 58), 93, True)), "CWCARP3")
    # polished dark stone: veins, slab joints, soft reflections of the ceiling lights
    T.seed(94)
    img = T.vary(T.solid(128, 128, (56, 56, 62)), 0.08, 32, 5)
    vein = T.fbm(128, 128, 48, 5)
    img = T.tint(img, np.exp(-((vein - 0.5) * 80) ** 2), (130, 130, 140), 0.6)
    vein2 = T.fbm(128, 128, 24, 4)
    img = T.tint(img, np.exp(-((vein2 - 0.5) * 120) ** 2), (96, 96, 104), 0.4)
    img = T.speckle(img, 0.01, (140, 140, 150), 0.5)
    yy, xx = np.mgrid[0:128, 0:128]
    img *= (1 + 0.10 * np.exp(-((xx - yy) % 64 - 32) ** 2 / 90))[..., None]
    for v in (0, 64): img[v, :] *= 0.7; img[:, v] *= 0.7; img[(v + 1) % 128, :] *= 1.15; img[:, (v + 1) % 128] *= 1.15
    save_tex(T.to_image(img), "CWMARBF")
    # ceramic floor tile
    T.seed(95)
    img = T.solid(64, 64, (206, 208, 204))
    for ty in range(0, 64, 16):
        for tx in range(0, 64, 16):
            t = T.vary(T.solid(16, 16, (206, 208, 204)), 0.04, 8, 2) * (0.95 + 0.07 * T.rng().random())
            img[ty:ty + 16, tx:tx + 16] = T.bevel(t, 0, 0, 15, 15, 1.05, 0.88)
            img[ty, tx:tx + 16] *= 0.7; img[ty:ty + 16, tx] *= 0.7
    img = T.grime(img, 0.1, 16, False)
    save_tex(T.to_image(img), "CWTILEF")
    # sealed concrete: fbm clouding, aggregate, a hairline crack, saw-cut joint
    T.seed(96)
    img = T.vary(T.solid(64, 64, (100, 100, 102)), 0.10, 32, 5); img = T.grain(img, 0.06)
    img = T.speckle(img, 0.04, (70, 70, 72), 0.5); img = T.speckle(img, 0.02, (140, 140, 142), 0.5)
    img = T.draw_on(img, lambda d, im: d.line([5, 60, 18, 42, 22, 30, 36, 22], fill=(74, 74, 76)))
    img[0, :] *= 0.75; img[:, 0] *= 0.75
    save_tex(T.to_image(img), "CWCONCF")
    # raised access floor panel: perforated, bevelled edges
    T.seed(97)
    img = T.vary(T.solid(64, 64, (74, 76, 82)), 0.05, 16)
    for y in range(6, 60, 6):
        for x in range(6, 60, 6):
            T.rect(img, x, y, x + 2, y + 2, (22, 22, 26)); img[y + 2, x:x + 3] *= 2.2
    T.bevel(img, 0, 0, 63, 63, 1.35, 0.55, 2)
    img = T.grime(img, 0.1, 8, False)
    save_tex(T.to_image(img), "CWRAISF")
    # stair landing: concrete with a safety nosing strip
    T.seed(98)
    img = T.vary(T.solid(64, 64, (150, 150, 146)), 0.08, 16); img = T.grain(img, 0.05)
    T.rect(img, 0, 30, 63, 33, (200, 160, 40)); T.bevel(img, 0, 30, 63, 33, 1.2, 0.6)
    T.bevel(img, 0, 0, 63, 63, 1.1, 0.7)
    img = T.grime(img, 0.15, 8, False)
    save_tex(T.to_image(img), "CWSTAIF")

# ---------------------------------------------------------------- prop sprites (front view, ~Doom scale)
def shade(d, box, col, edge=18):
    d.rectangle(box, fill=col); x0, y0, x1, y1 = box
    d.line([x0, y0, x1, y0], fill=tuple(min(255, c + edge) for c in col))
    d.line([x1, y0, x1, y1], fill=tuple(max(0, c - edge) for c in col))

def spr_plant():
    im = Image.new("RGBA", (40, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [10, 44, 29, 63], (58, 58, 62))
    for _ in range(26):
        a = R.uniform(-1.3, 1.3); L = R.randint(14, 30); x0, y0 = 20, 44
        import math; x1, y1 = x0 + math.sin(a) * L, y0 - math.cos(a) * L
        g = R.choice([(46, 110, 48), (60, 140, 56), (36, 90, 40), (80, 160, 70)])
        d.line([x0, y0, x1, y1], fill=g, width=2); d.ellipse([x1 - 3, y1 - 2, x1 + 3, y1 + 2], fill=g)
    save_sprite(im, "CWPLA0")

def spr_vending():
    im = Image.new("RGBA", (36, 72), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [0, 0, 35, 71], (40, 42, 50)); d.rectangle([3, 4, 24, 56], fill=(18, 22, 30))
    for y in range(8, 54, 9):
        for x in range(5, 23, 5): d.rectangle([x, y, x + 3, y + 5], fill=R.choice([(200, 60, 40), (220, 180, 40), (60, 120, 200), (230, 230, 230)]))
    d.rectangle([27, 10, 32, 30], fill=(20, 20, 24)); d.rectangle([28, 12, 31, 14], fill=(60, 200, 90))
    d.rectangle([4, 60, 24, 66], fill=(14, 14, 16)); save_sprite(im, "CWVNA0")

def spr_copier():
    im = Image.new("RGBA", (44, 44), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [2, 10, 41, 43], (70, 72, 78)); shade(d, [4, 2, 39, 10], (90, 92, 98))
    for y in (18, 26, 34): d.line([6, y, 37, y], fill=(40, 42, 46))
    d.rectangle([30, 4, 37, 8], fill=(40, 140, 220)); save_sprite(im, "CWCPA0")

def spr_sofa():
    im = Image.new("RGBA", (64, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [4, 2, 59, 20], (52, 50, 54)); shade(d, [0, 12, 63, 29], (62, 60, 64))
    shade(d, [0, 8, 8, 29], (44, 42, 46)); shade(d, [55, 8, 63, 29], (44, 42, 46))
    d.line([31, 14, 31, 27], fill=(40, 38, 42)); save_sprite(im, "CWSFA0")

def spr_cooler():
    im = Image.new("RGBA", (20, 52), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([3, 0, 16, 18], fill=(120, 170, 220)); d.rectangle([5, 14, 14, 18], fill=(100, 150, 200))
    shade(d, [2, 18, 17, 51], (210, 210, 206)); d.rectangle([7, 26, 12, 29], fill=(60, 80, 200)); save_sprite(im, "CWWCA0")

def spr_cart():
    im = Image.new("RGBA", (40, 44), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [2, 20, 37, 36], (40, 40, 44)); shade(d, [18, 12, 34, 34], (210, 180, 40))
    d.line([10, 0, 12, 20], fill=(200, 110, 40), width=2)
    for x in (6, 32): d.ellipse([x - 3, 36, x + 3, 42], fill=(20, 20, 20))
    d.polygon([(26, 16), (30, 24), (22, 24)], fill=(20, 20, 20)); save_sprite(im, "CWJCA0")

def spr_bin():
    im = Image.new("RGBA", (16, 22), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    shade(d, [2, 2, 13, 21], (60, 62, 66)); d.rectangle([1, 1, 14, 3], fill=(80, 82, 86)); save_sprite(im, "CWBNA0")

def spr_exit():
    im = Image.new("RGBA", (24, 10), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 23, 9], fill=(20, 150, 60)); d.text((3, 0), "EXIT", font=font(8), fill=(240, 255, 240)); save_sprite(im, "CWEXA0")

def extras():
    im = Image.new("RGB", (64, 128), (120, 150, 175)); d = ImageDraw.Draw(im)      # window glass (drawn translucent)
    for x in (6, 30): d.line([x, 10, x + 26, 50], fill=(200, 220, 235), width=2)
    d.line([40, 70, 58, 100], fill=(170, 195, 215)); save_tex(im, "CWGLASS")
    # galvanised duct: spangle, seams with rivets, grime
    T.seed(101)
    img = T.brushed(64, 64, (150, 154, 158), 0.06)
    span = T.fbm(64, 64, 6, 2); img *= (1 + (span - 0.5) * 0.16)[..., None]
    for y in (0, 32):
        img[y] *= 0.65; img[(y + 1) % 64] *= 1.25; img[(y + 2) % 64] *= 1.1
        for x in range(4, 64, 8): img[y + 5, x] *= 0.55; img[y + 4, x] *= 1.3
    img = T.grime(img, 0.12, 8, False)
    save_tex(T.to_image(img), "CWDUCT")
    # crown molding / soffit trim: a shaded ogee profile
    T.seed(102)
    img = T.vary(T.solid(64, 64, (228, 226, 218)), 0.02, 16)
    prof = [1.12, 1.18, 0.92, 0.78, 1.05, 1.15, 1.0, 0.8, 1.1, 1.0, 0.96, 0.9]
    for y, f in enumerate(prof): img[y * 2:(y + 1) * 2] *= f
    img[40:42] *= 0.85; img[56:58] *= 0.85; img[63] *= 0.75
    save_tex(T.to_image(img), "CWTRIM")
    # door threshold plate: ribbed aluminium
    T.seed(103)
    img = T.brushed(64, 64, (150, 152, 156), 0.08)
    for y in range(2, 64, 4): img[y] *= 1.25; img[y + 1] *= 0.8
    img = T.grime(img, 0.15, 8, False)
    save_tex(T.to_image(img), "CWTHRES")

def doors():
    # Doom-scale doors: 64 x 128 textures with the door in the bottom 80 rows (doorways are 80u tall) and a
    # plaster header above; the upper texture is bottom-aligned, so the door rises into the ceiling when it opens.
    srcs = {"CWDOOR1": "ADDOOR1", "CWDOOR2": "ADDOOR2", "CWDOORS": "ADDOORS", "CWDOORT": "ADDOORT"}
    for name, src in list(srcs.items()) + [("CWDOORF", None), ("CWDOORE", None)]:
        base = plaster().crop((0, 0, 64, 128))
        if src:
            door = Image.open(os.path.join(TEX, src + ".png")).convert("RGB").resize((64, 80), Image.NEAREST)
        else:
            door = Image.open(os.path.join(TEX, ("CWFIRED" if name == "CWDOORF" else "CWELEVD") + ".png")).convert("RGB").resize((64, 80), Image.NEAREST)
        base.paste(door, (0, 48))
        d = ImageDraw.Draw(base); d.rectangle([0, 44, 63, 47], fill=(70, 70, 74))   # frame head
        save_tex(base, name)

for fn in (extras, wall_plain, wall_wood, wall_dark, wall_tile, wall_server, window, decor, elevator_door, ceiling, floors,
           spr_plant, spr_vending, spr_copier, spr_sofa, spr_cooler, spr_cart, spr_bin, spr_exit, doors):
    fn()
