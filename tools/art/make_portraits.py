"""Original officer portraits for the squad screens and HUD (PLAN.md §2.7, M12).

    python tools/art/make_portraits.py      # writes nbc/graphics/portraits/NBCPF00.png ... NBCPF39.png, NBCPVANC.png

Each face is drawn pixel by pixel at 48 x 48 from a seeded recipe: skin tone, face shape, hair, headgear
(none, a patrol cap, a knit cap, a riot helmet), facial hair and glasses; the uniform follows the class (navy
shirt for patrol and marksmen, a tactical vest for breachers, a paramedic's white). The menus draw them at 2x; the HUD at 1x. Damage and KIA states are tints applied
in code. Deterministic: the same seed always gives the same faces.
"""
import os
import random
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "nbc", "graphics", "portraits")
N = 40
S = 48

SKIN = [(244, 205, 170), (232, 186, 145), (214, 160, 118), (190, 132, 92), (160, 104, 70), (124, 78, 50), (92, 58, 38)]
HAIR = [(24, 20, 18), (44, 32, 24), (78, 52, 32), (120, 86, 52), (176, 140, 92), (150, 150, 150), (96, 40, 24)]
UNIFORM = {"navy": ((30, 42, 70), (46, 62, 98)), "vest": ((40, 44, 40), (64, 70, 62)), "medic": ((200, 204, 208), (232, 234, 236)),
           "jacket": ((60, 40, 28), (92, 64, 44))}


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


def face(seed, recipe=None):
    rnd = random.Random(seed)
    r = dict(
        skin=rnd.randrange(len(SKIN)), hair=rnd.randrange(len(HAIR)), female=rnd.random() < 0.3,
        hat=rnd.choice(["none", "none", "cap", "cap", "beanie", "helmet"]), facial=rnd.choice(["none", "none", "none", "mustache", "goatee", "beard", "stubble"]),
        glasses=rnd.random() < 0.18, uniform=rnd.choice(["navy", "navy", "vest", "medic"]), wide=rnd.randint(-1, 1), style=rnd.randrange(4))
    if recipe:
        r.update(recipe)
    if r["female"]:
        r["facial"] = "none"
    img = Image.new("RGB", (S, S))
    px = img.load()
    # background: a dark slate gradient with a faint vignette
    for y in range(S):
        for x in range(S):
            d = ((x - 24) ** 2 + (y - 20) ** 2) ** 0.5
            v = max(0.55, 1.0 - d / 60)
            px[x, y] = shade((44, 54, 68), v)
    skin = SKIN[r["skin"]]
    hair = HAIR[r["hair"]]
    lo, hi = UNIFORM[r["uniform"]]
    # shoulders and neck
    for y in range(36, S):
        for x in range(4, 44):
            if abs(x - 24) < 12 + (y - 36) * 1.6:
                px[x, y] = hi if x < 24 else lo
    for y in range(31, 39):
        for x in range(20, 28):
            px[x, y] = shade(skin, 0.8)
    # collar / vest details
    if r["uniform"] == "navy":
        for y in range(37, 41):
            px[22 - (y - 37), y] = (20, 28, 46); px[25 + (y - 37), y] = (20, 28, 46)
        px[16, 42] = (220, 180, 60); px[17, 42] = (240, 200, 80); px[16, 43] = (200, 160, 40)   # badge
    elif r["uniform"] == "vest":
        for y in range(39, S):
            for x in range(14, 34):
                if abs(x - 24) < 10:
                    px[x, y] = (34, 36, 34) if (x + y) % 6 else (46, 50, 46)
        for x in range(17, 31):
            px[x, 42] = (200, 200, 200) if 19 <= x <= 28 else px[x, 42]   # "POLICE" strip
    elif r["uniform"] == "medic":
        for y in range(40, 45):
            px[30, y] = (190, 30, 30)
        for x in range(28, 33):
            px[x, 42] = (190, 30, 30)
    # head: an oval, lit from the left
    hw = 9 + r["wide"]
    for y in range(9, 34):
        for x in range(10, 38):
            nx, ny = (x - 24) / hw, (y - 21) / 12.5
            if nx * nx + ny * ny <= 1.0:
                f = 1.06 - max(0, nx) * 0.28 - max(0, ny - 0.5) * 0.25
                px[x, y] = shade(skin, f)
    # ears
    for y in range(19, 25):
        px[24 - hw - 1, y] = shade(skin, 0.9); px[24 + hw + 1, y] = shade(skin, 0.7)
    # hair under the hat
    def cut(top, sides):
        for y in range(7, 34):
            for x in range(10, 38):
                nx, ny = (x - 24) / (hw + 1), (y - 20) / 13.5
                inside = nx * nx + ny * ny <= 1.0
                if inside and y < top:
                    px[x, y] = shade(hair, 1.0 - max(0, nx) * 0.3)
                elif inside and sides and y < top + sides and abs(x - 24) >= hw - 1:
                    px[x, y] = shade(hair, 0.85)
    if r["female"]:
        cut(15, 12)
        if r["style"] % 2 == 0:   # hair to the shoulders
            for y in range(14, 40):
                for x in (24 - hw - 2, 24 - hw - 1, 24 + hw + 1, 24 + hw + 2):
                    px[x, y] = shade(hair, 0.8)
        else:                      # a bun at the back
            for y in range(5, 10):
                for x in range(21, 28):
                    px[x, y] = shade(hair, 0.9)
    else:
        style = r["style"]
        if style == 0: cut(14, 4)          # short back and sides
        elif style == 1: cut(12, 0)        # buzz
        elif style == 2: cut(16, 6)        # side part, fuller
        else:                              # close crop / near bald
            for x in range(16, 32): px[x, 11] = shade(hair, 0.7)
    # headgear
    if r["hat"] == "cap":
        for y in range(6, 14):
            for x in range(13, 35):
                if abs(x - 24) < 10 + (y - 6) * 0.3:
                    px[x, y] = (24, 32, 56) if y < 12 else (16, 20, 34)
        for x in range(12, 37): px[x, 14] = (10, 12, 20); px[x, 15] = (18, 22, 34)   # brim
        px[23, 9] = (230, 190, 70); px[24, 9] = (250, 210, 90); px[23, 10] = (210, 170, 50); px[24, 10] = (230, 190, 70)
    elif r["hat"] == "beanie":
        col = rnd.choice([(40, 40, 44), (90, 30, 30), (30, 50, 40), (60, 60, 70)])
        for y in range(5, 14):
            for x in range(13, 35):
                if abs(x - 24) < 10 + (y - 5) * 0.2:
                    px[x, y] = shade(col, 1.0 if (x // 2) % 2 else 0.85)
    elif r["hat"] == "helmet":
        for y in range(4, 17):
            for x in range(11, 37):
                nx, ny = (x - 24) / 13, (y - 15) / 11
                if nx * nx + ny * ny <= 1.0:
                    px[x, y] = shade((26, 30, 38), 1.15 - max(0, nx) * 0.4)
        for x in range(11, 37): px[x, 16] = (60, 64, 72)
    # brows, eyes, nose, mouth
    browc = shade(hair, 0.8)
    for x in (19, 20, 21): px[x, 18] = browc
    for x in (27, 28, 29): px[x, 18] = browc
    for (ex, side) in ((20, 0), (28, 1)):
        px[ex - 1, 20] = (230, 230, 225); px[ex, 20] = (40, 30, 26); px[ex + 1, 20] = (230, 230, 225) if side == 0 else (200, 200, 195)
    for y in (21, 22, 23, 24): px[24, y] = shade(skin, 0.86)
    px[23, 25] = shade(skin, 0.7); px[25, 25] = shade(skin, 0.7)
    mouth = shade(skin, 0.55) if not r["female"] else (150, 70, 70)
    for x in range(21, 28): px[x, 28] = mouth
    px[21, 27] = shade(skin, 0.8)
    # facial hair
    fh = shade(hair, 0.9)
    if r["facial"] == "mustache":
        for x in range(20, 29): px[x, 27] = fh
    elif r["facial"] == "goatee":
        for x in range(20, 29): px[x, 27] = fh
        for y in range(29, 32):
            for x in range(22, 27): px[x, y] = fh
    elif r["facial"] == "beard":
        for y in range(25, 34):
            for x in range(14, 35):
                nx, ny = (x - 24) / hw, (y - 21) / 12.5
                if nx * nx + ny * ny <= 1.0 and not (21 <= x <= 27 and y == 28):
                    px[x, y] = shade(fh, 1.0 - max(0, nx) * 0.3)
    elif r["facial"] == "stubble":
        for y in range(26, 33):
            for x in range(15, 34):
                nx, ny = (x - 24) / hw, (y - 21) / 12.5
                if nx * nx + ny * ny <= 1.0 and (x + y) % 2 == 0 and y != 28:
                    px[x, y] = shade(px[x, y], 0.78)
    if r["glasses"]:
        for x in list(range(17, 23)) + list(range(26, 32)):
            px[x, 19] = (20, 20, 24)
        px[17, 20] = px[22, 20] = px[26, 20] = px[31, 20] = (20, 20, 24)
        px[23, 19] = px[24, 19] = px[25, 19] = (20, 20, 24)
    # a dark frame line round the card
    for i in range(S):
        px[i, 0] = px[i, S - 1] = px[0, i] = px[S - 1, i] = (12, 14, 18)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    # ten faces per class, in the class's uniform: 00-09 patrol, 10-19 breacher, 20-29 marksman, 30-39 paramedic
    uniforms = ["navy", "vest", "navy", "medic"]
    for i in range(N):
        face(9000 + i * 37, dict(uniform=uniforms[i // 10])).save(os.path.join(OUT, "NBCPF%02d.png" % i))
    # Detective Jordan Vance: leather jacket, stubble, no hat
    face(4242, dict(skin=3, hair=0, female=False, hat="none", facial="stubble", glasses=False, uniform="jacket", wide=0, style=0)).save(
        os.path.join(OUT, "NBCPVANC.png"))
    print("wrote %d portraits to %s" % (N + 1, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
