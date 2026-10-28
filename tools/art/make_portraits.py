"""Original officer portraits for the squad screens and HUD (PLAN.md §1, §2.7, M12).

    python tools/art/make_portraits.py      # writes nbc/graphics/portraits/NBCPF00.png ... NBCPF39.png, NBCPVANC.png
    python tools/art/make_portraits.py --sheet out.png    # also a contact sheet at 3x, for checking

The look follows the lore: a gutted department in a dystopian near future. Nobody has a full uniform. Officers
wear their own clothes (hoodies, field and leather jackets, flannel, patched coats) with salvaged kit
(home-made plate carriers, respirators, goggles, a cheap earpiece) and only a loose mark of the police: a
faded navy armband, a badge on a chain, a navy scarf, an old uniform shirt under a jacket. No modern patrol caps,
riot helmets or tactical uniforms.

Ten faces per class (00-09 Patrol, 10-19 Breacher, 20-29 Marksman, 30-39 Paramedic), drawn pixel by pixel at
48 x 48 from a seeded recipe; the class adds its kit (plates for breachers, a scarf and a scope eyepiece for
marksmen, a hand-painted red cross for paramedics). The menus draw them at 2x and up; the HUD at about 1x.
Deterministic: the same seed always gives the same faces.
"""
import os
import random
import sys
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "nbc", "graphics", "portraits")
N = 40
S = 48

SKIN = [(238, 200, 166), (226, 180, 140), (206, 152, 112), (182, 126, 88), (152, 98, 66), (118, 74, 48), (86, 54, 36)]
HAIR = [(22, 18, 16), (40, 30, 22), (70, 48, 30), (110, 78, 48), (168, 132, 86), (140, 138, 134), (92, 40, 24), (200, 196, 188)]
NAVY = (34, 46, 78)

# clothes: (main colour, trim colour)
CLOTHES = {
    "hoodie": [((70, 70, 74), (50, 50, 54)), ((44, 46, 44), (30, 32, 30)), ((86, 40, 40), (60, 28, 28)), ((70, 78, 56), (50, 56, 40))],
    "field": [((84, 86, 58), (60, 62, 40)), ((110, 96, 70), (80, 68, 48)), ((70, 74, 66), (50, 52, 46))],
    "leather": [((70, 44, 30), (46, 28, 18)), ((36, 32, 30), (22, 20, 18)), ((96, 60, 36), (66, 40, 24))],
    "denim": [((66, 82, 106), (46, 58, 78)), ((84, 96, 110), (60, 70, 82))],
    "flannel": [((130, 46, 40), (40, 30, 28)), ((60, 90, 62), (32, 40, 30)), ((70, 70, 110), (34, 34, 52))],
    "coat": [((120, 104, 78), (88, 74, 54)), ((82, 70, 62), (58, 48, 42)), ((58, 62, 70), (40, 42, 48))],
    "knit": [((96, 84, 68), (72, 62, 50)), ((52, 60, 72), (38, 44, 54)), ((110, 100, 92), (80, 72, 66))],
}
CUES = ["armband", "badge", "scarf", "undershirt", "stripe"]     # the loose mark of the police

# The eight outfits. Face n wears outfit (n * 3) % 8, and so does that officer's sprite in the field: the same
# shirt and trouser colours come from the NBC_Outfit0-7 translations in nbc/TRNSLATE.txt (NBC_Ally.Equip).
OUTFITS = [
    ("leather", ((112, 76, 48), (70, 46, 28))),    # 0 brown leather, jeans
    ("hoodie", ((112, 112, 116), (74, 74, 78))),   # 1 grey hoodie, dark trousers
    ("flannel", ((136, 48, 42), (44, 30, 28))),    # 2 red, jeans
    ("field", ((98, 98, 64), (68, 68, 42))),       # 3 olive field jacket, khakis
    ("knit", ((54, 64, 98), (38, 44, 70))),        # 4 navy: what's left of a uniform, dark trousers
    ("coat", ((140, 118, 84), (100, 84, 58))),     # 5 tan coat, dark jeans
    ("leather", ((44, 42, 44), (26, 24, 26))),     # 6 black, olive trousers
    ("denim", ((80, 98, 126), (56, 68, 90))),      # 7 denim jacket, black trousers
]


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


class Canvas:
    def __init__(self, rnd):
        self.img = Image.new("RGB", (S, S))
        self.px = self.img.load()
        self.rnd = rnd

    def put(self, x, y, c):
        if 0 <= x < S and 0 <= y < S:
            self.px[x, y] = c

    def get(self, x, y):
        return self.px[max(0, min(S - 1, x)), max(0, min(S - 1, y))]

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.put(x, y, c)

    def oval(self, cx, cy, rx, ry, fn):
        """fn(x, y, nx, ny) -> colour or None, for each pixel inside the ellipse"""
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                nx, ny = (x - cx) / rx, (y - cy) / ry
                if nx * nx + ny * ny <= 1.0:
                    c = fn(x, y, nx, ny)
                    if c:
                        self.put(x, y, c)


def portrait(seed, cls, recipe=None, outfit=None):
    rnd = random.Random(seed)
    r = dict(
        skin=rnd.randrange(len(SKIN)), hair=rnd.randrange(len(HAIR)), female=rnd.random() < 0.35,
        hairdo=rnd.randrange(6), wide=rnd.randint(-1, 1),
        clothes=rnd.choice(list(CLOTHES)), cue=rnd.choice(CUES),
        head=rnd.choice(["none", "none", "beanie", "hood", "bandana", "flatcap", "none"]),
        facial=rnd.choice(["none", "none", "stubble", "stubble", "mustache", "beard", "goatee"]),
        mark=rnd.choice(["none", "none", "scar", "scar", "bandage", "tattoo", "bruise"]),
        mask=rnd.choice(["none", "none", "none", "neck", "neck", "on"]),
        goggles=rnd.random() < 0.22, earpiece=rnd.random() < 0.5, light=rnd.choice(["sodium", "sodium", "cold", "red"]),
        glasses=rnd.random() < 0.12)
    if recipe:
        r.update(recipe)
    if r["female"]:
        r["facial"] = "none"
    # class kit nudges the dice
    if cls == 2:
        r["head"] = rnd.choice(["none", "beanie", "hood", "flatcap"])
    elif cls == 3:
        r["mask"] = rnd.choice(["neck", "neck", "none"])
    c = Canvas(rnd)
    px = c.px
    skin = SKIN[r["skin"]]
    hair = HAIR[r["hair"]]
    main, trim = rnd.choice(CLOTHES[r["clothes"]])
    if outfit is not None:
        r["clothes"], (main, trim) = OUTFITS[outfit]

    # ---- background: a grimy concrete wall under one street light
    lit = {"sodium": (150, 104, 54), "cold": (70, 104, 104), "red": (120, 52, 46)}[r["light"]]
    base = (30, 32, 36)
    lx = rnd.choice([6, 42])
    for y in range(S):
        for x in range(S):
            d = ((x - lx) ** 2 + (y - 10) ** 2) ** 0.5
            t = max(0.0, 1.0 - d / 46) ** 1.6
            col = mix(base, lit, t * 0.55)
            n = rnd.random()
            col = shade(col, 0.9 + n * 0.16)
            if (y % 12 == 0) or ((x + (y // 12) * 6) % 24 == 0 and y % 12 < 12):   # block joints
                col = shade(col, 0.82)
            px[x, y] = col
    # stains running down
    for _ in range(3):
        sx = rnd.randrange(2, 46)
        for y in range(rnd.randrange(0, 10), rnd.randrange(20, 46)):
            px[sx, y] = shade(px[sx, y], 0.8)

    def rim(col, x):
        """light from the lamp's side"""
        return shade(col, 1.12) if (x < 24) == (lx < 24) else shade(col, 0.82)

    # ---- body: shoulders, then the clothes
    def body_fn(x, y):
        return abs(x - 24) < 11 + (y - 36) * 1.7

    for y in range(35, S):
        for x in range(S):
            if body_fn(x, y):
                px[x, y] = rim(main, x)
    # neck
    c.rect(20, 30, 28, 38, shade(skin, 0.78))
    # what the clothes look like
    cl = r["clothes"]
    if cl == "hoodie":
        # the hood bunched round the neck, drawstrings
        for x in range(13, 36):
            for y in range(34, 38):
                if abs(x - 24) > 4 - (y - 34) and abs(x - 24) < 12:
                    px[x, y] = rim(shade(main, 0.88), x)
        px[22, 40] = px[22, 41] = px[22, 42] = (200, 196, 186)
        px[26, 40] = px[26, 41] = px[26, 42] = (200, 196, 186)
        c.rect(18, 45, 31, 48, shade(main, 0.8))     # front pocket
    elif cl in ("field", "coat", "leather", "denim"):
        # lapels / collar, a zip or buttons, a pocket flap
        for y in range(35, S):
            for x in range(S):
                if body_fn(x, y) and abs(x - 24) <= 3 + (y - 35) // 4:
                    px[x, y] = shade(trim, 0.7)       # the open front: a shirt underneath
        for y in range(34, 41):
            for d in range(0, 4):
                c.put(24 - 5 - d + (y - 34) // 2, y, rim(shade(main, 1.15), 10))
                c.put(24 + 5 + d - (y - 34) // 2, y, rim(shade(main, 1.15), 40))
        c.rect(12, 43, 18, 45, shade(main, 0.7))
        c.rect(30, 43, 36, 45, shade(main, 0.7))
        if cl == "leather":
            for y in range(38, S):
                c.put(24 - 4 - (y - 38) // 4, y, (150, 140, 120))   # zip line
        if cl == "coat":
            for y in range(36, S, 3):
                c.put(17, y, shade(trim, 0.6))
            # patches
            for _ in range(2):
                pxx, pyy = rnd.randrange(8, 38), rnd.randrange(40, 46)
                pc = rnd.choice([(90, 60, 40), (60, 70, 50), (100, 90, 70)])
                c.rect(pxx, pyy, pxx + 4, pyy + 3, pc)
    elif cl == "flannel":
        for y in range(35, S):
            for x in range(S):
                if body_fn(x, y):
                    chk = ((x // 3) + (y // 3)) % 2 == 0
                    line = x % 6 == 0 or y % 6 == 0
                    px[x, y] = rim(trim if line else (main if chk else shade(main, 0.75)), x)
        for x in range(19, 30):
            if abs(x - 24) > 1:
                px[x, 36] = shade(main, 0.6)
    elif cl == "knit":
        for y in range(35, S):
            for x in range(S):
                if body_fn(x, y) and (x + y) % 3 == 0:
                    px[x, y] = shade(px[x, y], 0.85)
        c.rect(18, 33, 30, 37, rim(shade(main, 0.9), 20))   # turtleneck

    # ---- the police mark, worn loosely
    cue = r["cue"]
    if cue == "armband":
        for y in range(41, 45):
            for x in range(4, 13):
                if body_fn(x, y):
                    px[x, y] = shade(NAVY, 0.9 + rnd.random() * 0.2)
        c.put(8, 42, (150, 140, 80))
    elif cue == "badge":
        for i, (bx, by) in enumerate([(19, 37), (20, 39), (21, 41), (28, 37), (27, 39), (26, 41)]):
            c.put(bx, by, (120, 120, 116))            # the chain
        c.rect(23, 42, 26, 45, (196, 160, 70))
        c.put(24, 43, (240, 210, 120))
    elif cue == "scarf":
        for y in range(33, 39):
            for x in range(14, 35):
                if abs(x - 24) < 9 + (y - 33) // 2:
                    px[x, y] = shade(NAVY, 0.85 + 0.25 * ((x + y) % 3 == 0))
        c.rect(25, 39, 29, 46, shade(NAVY, 0.8))       # the hanging end
    elif cue == "undershirt":
        for y in range(36, S):
            for x in range(S):
                if body_fn(x, y) and abs(x - 24) <= 2 + (y - 36) // 4:
                    px[x, y] = shade(NAVY, 1.0 if x < 24 else 0.8)
        c.put(23, 44, (190, 170, 90))                  # what's left of the shield patch
    elif cue == "stripe":
        for x in range(4, 44):
            if body_fn(x, 40) and abs(x - 24) > 5:
                px[x, 40] = (128, 120, 70)             # an old, dull reflective strip

    # ---- class kit
    if cls == 1:
        # a home-made plate carrier: scavenged plates on webbing over the clothes, duct tape, a hand-painted PD
        plate = rnd.choice([(78, 72, 60), (62, 64, 62), (88, 78, 58), (70, 66, 74)])
        for y in range(37, S):
            for x in range(S):
                if body_fn(x, y) and abs(x - 24) < 13:
                    seam = y in (42, 47) or abs(x - 24) == 6
                    px[x, y] = rim(shade(plate, 0.72 if seam else 0.95 + 0.12 * ((x * 7 + y * 3) % 5 == 0)), x)
        for y in range(33, 38):                        # shoulder straps
            for x in (14, 15, 33, 34):
                c.put(x, y, (36, 34, 30))
        for x in range(11, 38):                        # cummerbund webbing
            if body_fn(x, 45):
                c.put(x, 45, (40, 38, 34))
        tx = rnd.randrange(14, 26)
        c.rect(tx, 39, tx + 7, 41, (156, 156, 152))    # duct tape
        if rnd.random() < 0.6:
            for (dx, dy) in [(20, 43), (20, 44), (21, 43), (21, 44), (27, 43), (27, 44), (28, 43), (28, 44)]:
                c.put(dx, dy, (206, 204, 196))        # a hand-painted "PD"
    elif cls == 3:
        # a white band with a hand-painted red cross, and a satchel strap
        for y in range(40, 45):
            for x in range(35, 44):
                if body_fn(x, y):
                    px[x, y] = shade((206, 200, 186), 0.85 + rnd.random() * 0.1)
        c.rect(38, 41, 40, 44, (170, 30, 26)); c.rect(37, 42, 41, 43, (170, 30, 26))
        for i in range(14):
            c.put(12 + i, 35 + i, (60, 46, 30))
            c.put(13 + i, 35 + i, (80, 62, 40))

    # ---- head
    hw = 9 + r["wide"]

    def head_fn(x, y, nx, ny):
        f = 1.08 - max(0.0, nx if lx > 24 else -nx) * 0.0 - max(0, (nx if lx < 24 else -nx)) * 0.3 - max(0, ny - 0.5) * 0.25
        return shade(skin, f)

    c.oval(24, 21, hw, 12.5, head_fn)
    for y in range(19, 25):
        c.put(24 - hw - 1, y, shade(skin, 0.9)); c.put(24 + hw + 1, y, shade(skin, 0.72))

    # hair
    def cap(top, sides, colour=None):
        h = colour or hair
        for y in range(5, 34):
            for x in range(10, 38):
                nx, ny = (x - 24) / (hw + 1), (y - 20) / 13.5
                if nx * nx + ny * ny > 1.0:
                    continue
                if y < top or (sides and y < top + sides and abs(x - 24) >= hw - 1):
                    px[x, y] = shade(h, 1.0 - max(0, nx) * 0.3 - (0.12 if (x * 3 + y) % 4 == 0 else 0))

    hd = r["hairdo"]
    if r["female"]:
        cap(15, 12)
        if hd % 3 == 0:          # loose to the shoulders
            for y in range(13, 38):
                for x in (24 - hw - 3, 24 - hw - 2, 24 - hw - 1, 24 + hw + 1, 24 + hw + 2, 24 + hw + 3):
                    if y < 35 or abs(x - 24) > hw + 1:
                        c.put(x, y, shade(hair, (0.95 if abs(x - 24) == hw + 2 else 0.75) - (0.1 if (x + y) % 3 == 0 else 0)))
        elif hd % 3 == 1:        # tied back
            c.rect(22, 5, 27, 9, shade(hair, 0.9))
        else:                    # shaved one side
            for y in range(9, 26):
                c.put(24 + hw - 1, y, shade(skin, 0.8)); c.put(24 + hw, y, shade(skin, 0.75))
    else:
        if hd == 0: cap(14, 4)                       # short
        elif hd == 1: cap(12, 0)                     # buzz
        elif hd == 2: cap(16, 6)                     # fuller
        elif hd == 3:                                # shaved sides, a strip on top
            for y in range(7, 14):
                for x in range(21, 28):
                    c.put(x, y, shade(hair, 1.0 - (x - 21) * 0.04))
        elif hd == 4:                                # locs
            cap(15, 10)
            for x in range(24 - hw - 1, 24 + hw + 2, 2):
                for y in range(14, 28 if abs(x - 24) > hw - 2 else 15):
                    c.put(x, y, shade(hair, 0.7))
        else:                                        # bald with a shadow
            for x in range(16, 32): c.put(x, 11, shade(skin, 0.8))

    # headgear: nothing issued
    hg = r["head"]
    if hg == "beanie":
        col = rnd.choice([(40, 40, 44), (90, 34, 30), (44, 54, 40), (60, 60, 70), (100, 84, 50)])
        for y in range(4, 14):
            for x in range(13, 35):
                if abs(x - 24) < 10 + (y - 4) * 0.2:
                    px[x, y] = rim(shade(col, 1.0 if (x // 2) % 2 else 0.84), x)
        c.rect(13, 12, 35, 14, rim(shade(col, 0.75), 20))
    elif hg == "hood":
        hcol = main if cl == "hoodie" else rnd.choice(CLOTHES["hoodie"])[0]
        for y in range(3, 36):
            for x in range(8, 40):
                nx, ny = (x - 24) / (hw + 4), (y - 20) / 16
                inside = nx * nx + ny * ny <= 1.0
                face = ((x - 24) / (hw - 1)) ** 2 + ((y - 23) / 11) ** 2 <= 1.0
                if inside and not face:
                    px[x, y] = rim(shade(hcol, 0.9 - max(0, ny) * 0.2), x)
    elif hg == "bandana":
        col = rnd.choice([(120, 30, 30), (30, 40, 70), (40, 40, 40), (90, 80, 50)])
        for y in range(8, 14):
            for x in range(14, 35):
                if abs(x - 24) < 9 + (y - 8) * 0.25:
                    px[x, y] = rim(shade(col, 1.0 if (x + y) % 4 else 1.25), x)
        c.rect(34, 12, 37, 15, col)
    elif hg == "flatcap":
        col = rnd.choice([(70, 64, 56), (52, 48, 44), (90, 76, 56)])
        for y in range(6, 13):
            for x in range(13, 36):
                if abs(x - 24) < 10 + (y - 6) * 0.35:
                    px[x, y] = rim(shade(col, 1.0 if (x + y) % 3 else 0.88), x)
        c.rect(13, 13, 34, 15, shade(col, 0.7))

    # goggles pushed up on the forehead
    if r["goggles"] and hg not in ("hood",):
        for x in range(14, 35): c.put(x, 13, (40, 36, 30))
        for gx in (19, 28):
            c.oval(gx, 13, 3, 2.2, lambda x, y, nx, ny: (70, 100, 96) if nx * nx + ny * ny < 0.4 else (120, 110, 90))

    # brows, eyes, nose, mouth
    browc = shade(hair, 0.75)
    for x in (19, 20, 21): c.put(x, 18, browc)
    for x in (27, 28, 29): c.put(x, 18, browc)
    eye_y = 20
    for ex in (20, 28):
        c.put(ex - 1, eye_y, (214, 210, 200)); c.put(ex, eye_y, (34, 28, 24)); c.put(ex + 1, eye_y, (190, 186, 178))
        c.put(ex, eye_y + 1, shade(skin, 0.78))       # tired eyes
    for y in (21, 22, 23, 24): c.put(24, y, shade(skin, 0.84))
    c.put(23, 25, shade(skin, 0.68)); c.put(25, 25, shade(skin, 0.68))
    mouth = shade(skin, 0.55)
    for x in range(21, 28): c.put(x, 28, mouth)
    if rnd.random() < 0.5:
        c.put(21, 27, shade(skin, 0.75))              # a hard set to the mouth
    else:
        c.put(27, 27, shade(skin, 0.75))

    # facial hair
    fh = shade(hair, 0.9)
    if r["facial"] == "mustache":
        for x in range(20, 29): c.put(x, 27, fh)
    elif r["facial"] == "goatee":
        for x in range(20, 29): c.put(x, 27, fh)
        c.rect(22, 29, 27, 32, fh)
    elif r["facial"] == "beard":
        c.oval(24, 21, hw, 12.5, lambda x, y, nx, ny: shade(fh, 1.0 - max(0, nx) * 0.3) if y >= 25 and not (21 <= x <= 27 and y == 28) else None)
    elif r["facial"] == "stubble":
        c.oval(24, 21, hw, 12.5, lambda x, y, nx, ny: shade(c.get(x, y), 0.78) if y >= 26 and (x + y) % 2 == 0 and y != 28 else None)

    # the wear and tear
    mk = r["mark"]
    if mk == "scar":
        sx = rnd.choice([17, 29])
        for i in range(5):
            c.put(sx + (i if sx < 24 else -i) // 2, 17 + i, shade(skin, 1.25))
    elif mk == "bandage":
        if rnd.random() < 0.5:
            c.rect(22, 22, 27, 24, (220, 214, 200)); c.put(24, 22, (170, 60, 50))   # across the nose
        else:
            c.rect(14, 15, 21, 17, (220, 214, 200))                                 # over a brow
    elif mk == "tattoo":
        for y in range(31, 36):
            c.put(27 + (y % 2), y, (50, 60, 80))
    elif mk == "bruise":
        c.oval(28, 22, 2.5, 2, lambda x, y, nx, ny: mix(c.get(x, y), (90, 70, 110), 0.35))

    # a respirator: hanging at the neck, or worn over the mouth (the air in the Bricks)
    if r["mask"] == "neck":
        c.rect(19, 34, 30, 37, (44, 46, 48)); c.rect(22, 35, 27, 37, (70, 72, 74))
        c.put(19, 36, (110, 110, 100)); c.put(29, 36, (110, 110, 100))
    elif r["mask"] == "on":
        # a half-face respirator over nose and mouth, two filter cans, a strap
        c.oval(24, 28, 7, 5, lambda x, y, nx, ny: shade((58, 60, 62), 1.15 - max(0, nx if lx > 24 else -nx) * 0.35 - max(0, ny) * 0.2))
        for x in range(22, 27): c.put(x, 30, (34, 36, 38))
        for fx in (17, 31):
            c.oval(fx, 30, 2.6, 2.6, lambda x, y, nx, ny: (96, 92, 70) if nx * nx + ny * ny > 0.35 else (66, 64, 50))
        for x in list(range(12, 17)) + list(range(32, 37)): c.put(x, 24, (28, 28, 28))

    if r["glasses"]:
        for x in list(range(17, 23)) + list(range(26, 32)):
            c.put(x, 19, (24, 22, 22))
        c.put(17, 20, (24, 22, 22)); c.put(22, 20, (24, 22, 22)); c.put(26, 20, (24, 22, 22)); c.put(31, 20, (24, 22, 22))
        c.put(23, 19, (24, 22, 22)); c.put(24, 19, (24, 22, 22)); c.put(25, 19, (24, 22, 22))

    # marksman: a cheap clip-on scope eyepiece over one eye (a glowing lens)
    if cls == 2 and rnd.random() < 0.6:
        c.rect(25, 18, 32, 23, (30, 32, 34))
        c.rect(27, 19, 30, 22, (60, 190, 170)); c.put(28, 20, (180, 255, 240))
        for x in range(32, 35): c.put(x, 20, (30, 32, 34))
    # an earpiece with a status light
    if r["earpiece"] and hg != "hood":
        ex = 24 + hw + 1
        c.put(ex, 21, (30, 30, 30)); c.put(ex, 22, (30, 30, 30)); c.put(ex + 1, 21, rnd.choice([(80, 230, 90), (230, 70, 50)]))

    # a dark frame line round the card
    for i in range(S):
        px[i, 0] = px[i, S - 1] = px[0, i] = px[S - 1, i] = (10, 11, 13)
    return c.img


def main():
    os.makedirs(OUT, exist_ok=True)
    faces = []
    for i in range(N):
        img = portrait(7100 + i * 53, i // 10, outfit=(i * 3) % 8)
        img.save(os.path.join(OUT, "NBCPF%02d.png" % i))
        faces.append(img)
    # Detective Jordan Vance: the undercover look. A worn leather jacket, stubble, the badge on a chain, an earpiece.
    vance = portrait(4242, 0, dict(skin=3, hair=0, female=False, hairdo=0, wide=0, clothes="leather", cue="badge", head="none",
                                   facial="stubble", mark="scar", mask="none", goggles=False, earpiece=True, light="sodium", glasses=False))
    vance.save(os.path.join(OUT, "NBCPVANC.png"))
    print("wrote %d portraits to %s" % (N + 1, os.path.relpath(OUT, ROOT)))
    if "--sheet" in sys.argv:
        dest = sys.argv[sys.argv.index("--sheet") + 1]
        sheet = Image.new("RGB", (S * 10 * 3, S * 5 * 3), (0, 0, 0))
        for i, img in enumerate(faces + [vance]):
            sheet.paste(img.resize((S * 3, S * 3), Image.NEAREST), ((i % 10) * S * 3, (i // 10) * S * 3))
        sheet.save(dest)


if __name__ == "__main__":
    main()
