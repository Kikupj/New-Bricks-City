# Corpo Wars: copy the A.D. Cop textures used by the interior theme sets into textures/themes/ under
# 8-character names ("AX" + source name without underscores). Source pack: Assets/Textures/ad cop textures.
import os, shutil, sys
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Assets", "Textures", "ad cop textures", "Textures")
DST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars", "textures", "themes")
USED = """CITY_05 CITY_08 CITY_09 CITY_14 CITY_17 CITY_18 CITY_19 DEF_W DEF_W2 DW_04 DW_07A DW_07B HW07A HW07B HW07D
HW09 HW09B W01 W02 W21 W24 W24C W26 W26E W28 W29B W43B W44 W44A W45 W47 W53 W53B W578 W578B W67 W69 W69B W72 W84 W85
F02 F05 F06B F06C F06D F06E F10 F13 F15 F21 F27 F33 F39 F39B F39C F40 F43 F46 F46B F48 F48B F48C F48D FLOR_02 FLOR_05
FLOR_07 FLOR_09 DU_02 DU_06 DU_06A DU_10C DU_12 DU_13 DU_13A DU_14 HF07A HF07C F51B HT01
W23 W27 W89 W43A W43C W43D W44B W44C W64 W65 W29 W29C W60 W61 W52 W31 W32 W35 W36 W37 W38 W11 W12 W13 W14
DW_08 DW_09 DW_11 DW_13 DW_14 DW_15 DW_16 W86 W86A W87 W18 W20 W25 DW_06A DW_06B W56 W41 DW_10 W30 W48 W88
B13 B14 B17B B18 B19B B20 B21B B22 B25 B26 B27 B28 B29 B03 B04 B09 B10 B11 B12 XX_02 XX_03 XX_04 XX_05 W10 W22 W39 W40
D01 D02 D08 D11 STEP_02 STEP_03 STEP_04 STEP_05 STEP_22 STEP_23
F01 F03 F14 F15 F16 DU_03 DU_03A F22 F31 F12 F21 F44 F41 DU_09 DU_16 DU_17 FT_32 FT_33 F49 F49B F50 FLOR_03
DU_11 F24 F25 DU_14A F17 F18 WAT_01""".split()
USED = list(dict.fromkeys(USED))   # (later sets repeat a few earlier names)
# industrial / site-kit sets for the Obsidian map generator (Design Docs/obsidian-maps.md)

def short(n): return ("AX" + n.replace("_", ""))[:8]

def main():
    os.makedirs(DST, exist_ok=True)
    seen = {}
    for n in USED:
        s = short(n)
        assert s not in seen, (n, seen.get(s))
        seen[s] = n
        for sub in ("Walls", "Flats"):
            p = os.path.join(SRC, sub, n + ".png")
            if os.path.exists(p):
                shutil.copy(p, os.path.join(DST, s + ".png")); break
        else:
            raise SystemExit("missing " + n)
    print(len(seen), "theme textures ->", DST)
    for s, n in sorted(seen.items()): print(" ", s, "=", n)

if __name__ == "__main__": main()
