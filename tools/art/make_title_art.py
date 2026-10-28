"""The title splash (the owner's art/new_brick_city_menu_screen.png) for the game:

    python tools/art/make_title_art.py

    nbc/graphics/NBCTITLE.png   the splash at 1280 x 960 (the title page, and the main menu's backdrop)
    nbc/graphics/NBCTITLB.png   a small, blurred, darkened copy that fills the sides on wide screens
"""
import os
from PIL import Image, ImageEnhance, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "art", "new_brick_city_menu_screen.png")
# the picture inside the sheet: the sheet has a white frame and a colour-swatch strip along the bottom
CROP = (40, 40, 3624, 2728)
OUT = os.path.join(ROOT, "nbc", "graphics")


def main():
    art = Image.open(SRC).convert("RGB").crop(CROP)
    os.makedirs(OUT, exist_ok=True)
    art.resize((1280, 960), Image.LANCZOS).save(os.path.join(OUT, "NBCTITLE.png"), optimize=True)
    side = art.resize((160, 120), Image.LANCZOS).filter(ImageFilter.GaussianBlur(6))
    side = ImageEnhance.Brightness(side).enhance(0.45)
    side.save(os.path.join(OUT, "NBCTITLB.png"), optimize=True)
    print("wrote NBCTITLE.png, NBCTITLB.png to nbc/graphics/")


if __name__ == "__main__":
    main()
