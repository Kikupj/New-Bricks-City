"""Pixel side views of the motor pool's land vehicles, in the style of the owner's helicopter (art/helicopter.png):
dark, worn, 128 x 64, transparent background.

    python tools/art/make_vehicle_art.py     # nbc/graphics/NBCVSEDN.png, NBCVVAN.png, NBCVTRUK.png

Drawn in code, deterministic (a fixed seed for the grime). Original art for New Bricks City.
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "nbc", "graphics")
W, H = 128, 64
OUTLINE = (18, 18, 20, 255)


def grime(img, body, seed, amount=0.16):
    """Speckle the body colour, darker towards the bottom."""
    rnd = random.Random(seed)
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0 or (r, g, b) != body:
                continue
            f = 1.0 - amount * rnd.random() - 0.25 * (y / H)
            px[x, y] = (int(r * f), int(g * f), int(b * f), 255)


def outline(img):
    """A one-pixel dark edge round everything opaque."""
    px = img.load()
    edge = []
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < W and 0 <= y + dy < H and px[x + dx, y + dy][3] and px[x + dx, y + dy] != OUTLINE:
                        edge.append((x, y))
                        break
    for x, y in edge:
        px[x, y] = OUTLINE


def wheel(d, cx, cy, r=8):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(28, 28, 30, 255))
    d.ellipse((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), fill=(84, 86, 90, 255))
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=(40, 40, 44, 255))


def sedan():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (44, 54, 78)          # unmarked dark blue
    d.polygon([(8, 44), (10, 34), (30, 31), (44, 20), (82, 19), (98, 31), (118, 33), (121, 44), (116, 48), (12, 48)], fill=body + (255,))
    d.polygon([(47, 22), (62, 22), (62, 31), (37, 31)], fill=(96, 120, 132, 255))       # windows
    d.polygon([(65, 22), (80, 22), (93, 31), (65, 31)], fill=(96, 120, 132, 255))
    d.line([(10, 38), (120, 38)], fill=(34, 42, 60, 255))
    d.rectangle((116, 35, 120, 37), fill=(220, 200, 140, 255))                            # headlight
    d.rectangle((8, 36, 11, 38), fill=(150, 30, 30, 255))                                 # tail light
    d.rectangle((56, 32, 60, 33), fill=(30, 34, 46, 255))                                 # door handle
    grime(img, body, 11)
    wheel(d, 30, 48)
    wheel(d, 98, 48)
    outline(img)
    return img


def van():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (70, 72, 74)          # a grey panel van
    d.polygon([(6, 50), (6, 14), (88, 12), (102, 26), (120, 32), (122, 50)], fill=body + (255,))
    d.polygon([(90, 15), (100, 27), (90, 28)], fill=(96, 120, 132, 255))                  # windscreen
    d.rectangle((72, 17, 86, 27), fill=(96, 120, 132, 255))                              # cab window
    d.line([(68, 14), (68, 50)], fill=(48, 50, 52, 255))                                 # sliding door
    d.line([(10, 30), (64, 30)], fill=(58, 60, 62, 255))
    d.rectangle((118, 36, 121, 38), fill=(220, 200, 140, 255))
    d.rectangle((6, 34, 9, 38), fill=(150, 30, 30, 255))
    d.rectangle((20, 34, 54, 36), fill=(110, 92, 60, 255))                               # a faded stripe
    grime(img, body, 23)
    wheel(d, 26, 50, 9)
    wheel(d, 100, 50, 9)
    outline(img)
    return img


def truck():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (64, 66, 58)          # armored, olive-grey
    d.polygon([(4, 50), (4, 12), (84, 10), (90, 16), (110, 18), (122, 30), (124, 50)], fill=body + (255,))
    d.rectangle((96, 21, 108, 28), fill=(70, 90, 96, 255))                               # slit windscreen
    for x in range(14, 80, 16):                                                           # armour plates
        d.line([(x, 14), (x, 48)], fill=(48, 50, 44, 255))
    for y in (22, 36):
        for x in range(10, 82, 8):
            d.point((x, y), fill=(100, 102, 92, 255))                                    # rivets
    d.rectangle((24, 22, 34, 26), fill=(30, 32, 30, 255))                                 # gun ports
    d.rectangle((56, 22, 66, 26), fill=(30, 32, 30, 255))
    d.rectangle((118, 34, 122, 36), fill=(220, 200, 140, 255))
    d.rectangle((86, 40, 120, 46), fill=(40, 42, 38, 255))                                # bumper / ram
    grime(img, body, 37, 0.2)
    wheel(d, 22, 50, 10)
    wheel(d, 50, 50, 10)
    wheel(d, 104, 50, 10)
    outline(img)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("NBCVSEDN", sedan), ("NBCVVAN", van), ("NBCVTRUK", truck)):
        fn().save(os.path.join(OUT, name + ".png"))
    print("wrote NBCVSEDN, NBCVVAN, NBCVTRUK to nbc/graphics/")


if __name__ == "__main__":
    main()
