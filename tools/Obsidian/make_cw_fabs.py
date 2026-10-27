"""Build Obsidian room prefabs from Corpo Wars' room recipes (the kit_*.zs Dress() layouts).

    python tools/Obsidian/make_cw_fabs.py

Corpo Wars furnished each room type in code: sofas along a living room's walls, counters in a
kitchen, shelving in a stockroom. This script lays those same pieces out as Obsidian prefabs so the
generator furnishes a room by type:

* a WALL prefab per furniture run: a plain 16-unit wall (like Obsidian's Wall_plain) with Corpo Wars
  furniture standing in front of it, facing the room (furniture models are map things; their
  collision comes from CW_Furniture's blockers at run time)
* a DECOR prefab per free-standing group (a coffee table between two armchairs, a bar table with
  stools, a lab bench with drums)
* wall sprites (posters, radiators, breaker boxes) and floor clutter picked at random per prefab
  through Obsidian's thing substitution (placeholder numbers 26960-26999, never left in a map)

Every room set is a wall group ("nbc_living", "nbc_kitchen" ...). The New Bricks City module gives
each Bricks room theme a list of these groups, so one area of a tenement becomes a kitchen, another
a bedroom. Outdoor sets (dumpsters, rubble with loose bricks, police barricades) are ungrouped decor.

Output: tools/Obsidian/addons/NewBricksCity/games/doom/fabs/{wall,decor}/nbc_cw_*.{lua,wad}
(Obsidian reads the addon's games/doom/fabs alongside its own). Map numbers come from
nbc/mapinfo/cw_props.txt (tools/import/port_cw_props.py). Safe to re-run: rewrites only nbc_cw_*.
"""
import glob
import math
import os
import re
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
NBC = os.path.join(ROOT, "nbc")
OUT = os.path.join(HERE, "addons", "NewBricksCity", "games", "doom", "fabs")

# New Bricks City's own things (nbc/MAPINFO.txt) and Doom's burning barrel
EXTRA_IDS = {"NBC_LooseBrick": 26000, "NBC_LooseHalfBrick": 26001, "NBC_LooseConcrete": 26002,
             "NBC_LooseBottle": 26003, "NBC_RubblePile": 26004, "BurningBarrel": 70}
PLACEHOLDER_BASE = 26960      # 26960-26999: substituted by the prefab skin, never reach a map
WALL_GAP = 3                  # Corpo Wars' PutWall leaves 3 units between a piece and its wall
NO_FOOTPRINT_DEPTH = 16       # pieces without a footprint (screens, chairs) use their radius 8


def load_ids():
    ids = dict(EXTRA_IDS)
    for m in re.finditer(r"(\d+)\s*=\s*(\w+)", open(os.path.join(NBC, "mapinfo", "cw_props.txt")).read()):
        ids[m.group(2)] = int(m.group(1))
    return ids


def load_footprints():
    fp = {}
    for name in ("furniture.zs", "kitprops.zs"):
        text = open(os.path.join(NBC, "zscript", "cw", name), encoding="latin1").read()
        for m in re.finditer(r"^class (CW_F\w+)\s*:\s*(\w+)\s*\{(.*)$", text, re.M):
            f = re.search(r"Footprint\s+(\d+),\s*(\d+)", m.group(3))
            if f:
                fp[m.group(1)] = (int(f.group(1)), int(f.group(2)))
            elif m.group(2) in fp:
                fp[m.group(1)] = fp[m.group(2)]
    return fp


IDS, FOOT = load_ids(), load_footprints()


def depth_of(cls):
    return FOOT.get(cls, (NO_FOOTPRINT_DEPTH, NO_FOOTPRINT_DEPTH))[0]


def extent_of(cls):
    d, w = FOOT.get(cls, (NO_FOOTPRINT_DEPTH, NO_FOOTPRINT_DEPTH))
    return max(d, w) / 2


# ---------------------------------------------------------------- random pools (class: weight)

def pool(*names, nothing=0):
    p = {n: 10 for n in names}
    if nothing:
        p["nothing"] = nothing
    return p


POOLS = {
    "home_art": pool("CWD_Apt_Painting_Landscape", "CWD_Apt_Painting_City", "CWD_Apt_Painting_Small",
                     "CWD_Apt_Painting_Portrait", "CWD_Apt_Window_Skyline", "CWD_Bank_Painting", nothing=30),
    "home_fix": pool("CWD_Apt_Radiator", "CWD_Apt_WallAC", "CWD_Apt_FireAlarm", "CWD_Apt_Vent_Square",
                     "CWD_Apt_Electrical_Box", "CWD_Apt_Intercom_Grey", nothing=40),
    "lobby_wall": pool("CWD_Apt_Mailboxes", "CWD_Apt_Directory_Apartments", "CWD_Apt_Intercom_Brass",
                       "CWD_Apt_CCTV_Camera", "CWD_Apt_Sign_KeepClean", "CWD_Apt_Sign_Exit_Arrow",
                       "CWD_Apt_Sign_Stairs_Arrow", "CWD_Apt_Corkboard", "CWD_Bank_Clock", nothing=20),
    "office_wall": pool("CWD_Bank_Clock", "CWD_Bank_Certificate", "CWD_Bank_Bulletin", "CWD_Bank_NoSmoking",
                        "CWD_Bank_Extinguisher", "CWD_Bank_FireAlarm", "CWD_Bank_Painting", "CWD_Apt_Corkboard",
                        nothing=20),
    "posters": pool("CWD_Bank_PosterCredit", "CWD_Bank_PosterLoans", "CWD_Bank_PosterWork",
                    "CWD_Bank_PosterSkyline", "CWD_Bank_PosterTomorrow", "CWD_Apt_Corkboard", nothing=30),
    "utility_wall": pool("CWD_Apt_Breaker_Cabinet", "CWD_Apt_Electrical_Box", "CWD_Und_Switch_Box",
                         "CWD_Und_Valve_Gauge", "CWD_Und_Drip_Pipe_Gauge", "CWD_Ind_Sign_HighVoltage",
                         "CWD_Und_Panel_Open", "CWD_Apt_Vent_Grate", nothing=20),
    "shop_wall": pool("CWD_Ind_Sign_HardHat", "CWD_Ind_Sign_Forklift", "CWD_Ind_Hazard_Panel_H",
                      "CWD_Ind_Pipes_Wall", "CWD_Ind_Cable_Tray", "CWD_Ind_Light_Cage", "CWD_Ind_Sign_StaffOnly",
                      "CWD_Bank_Extinguisher", nothing=25),
    "grime": pool("CWD_Und_Moss_A", "CWD_Und_Moss_B", "CWD_Und_Moss_C", "CWD_Und_Moss_D", "CWD_Und_Moss_E",
                  "CWD_Und_Moss_F", "CWD_Apt_Brick_Vent", "CWD_Und_Grate_Rusty", "CWD_Und_Pipe_ElbowRust",
                  nothing=30),
    "lab_wall": pool("CWD_Ind_Light_Fluorescent", "CWD_Und_Sign_DangerConfined", "CWD_Und_Sign_NoEntry",
                     "CWD_Ind_Sign_StaffOnly", "CWD_Apt_Vent_Square", "CWD_Und_Lamp_CageSmall", nothing=20),
    "bath_wall": pool("CWD_Apt_Tile_Wall", "CWD_Apt_Vent_Square", "CWD_Und_Drip_Pipe_Short", nothing=40),
    # floor clutter (billboard sprites, never solid)
    "home_clutter": pool("CWD_Apt_Floor_Lamp", "CWD_Bank_Books", "CWD_Bank_ArchiveBox", "CWD_Bank_TrashBag",
                         "CWD_Und_Bottle", "CWD_Und_Can", nothing=40),
    "kitchen_clutter": pool("CWD_Apt_Kitchen_Block", "CWD_Apt_Pantry_Shelf", "CWD_Apt_Fridge_Magnets",
                            "CWD_Bank_TrashBag", nothing=20),
    "trash": pool("CWD_Und_Trash_Bag", "CWD_Bank_TrashBag", "CWD_Und_Can", "CWD_Und_Bottle",
                  "CWD_Und_Rocks_Small", "CWD_Bank_BoxPile", nothing=20),
    "boxes": pool("CWD_Bank_BoxPile", "CWD_Bank_ArchiveBox", "CWD_Bank_CartBoxes", "CWD_Ind_Pallet_Boxes",
                  "CWD_Ind_Pallet_Wrapped", "CWD_Und_Crate_Wood", "CWD_Und_Case_GreenA", "CWD_Und_Case_Blue",
                  nothing=20),
    "industrial": pool("CWD_Ind_Drums_Group", "CWD_Ind_Gas_Cylinders", "CWD_Ind_Extinguisher",
                       "CWD_Ind_Tool_Chest", "CWD_Und_Barrel_Hazard", "CWD_Und_Cone_Orange", "CWD_Ind_Cable_Spool",
                       nothing=20),
    "paperwork": pool("CWD_Bank_PapersTall", "CWD_Bank_PapersShort", "CWD_Bank_Binders", "CWD_Bank_ArchiveBox",
                      "CWD_Bank_CartSmall", nothing=30),
    "bath_clutter": pool("CWD_Bank_MopBucket", "CWD_Bank_WetFloor", "CWD_Bank_TrashBag", nothing=50),
    # throwable debris for the G quick-throw (PLAN: bricks and bottles lying about the Bricks)
    "debris": {"NBC_LooseBrick": 30, "NBC_LooseHalfBrick": 20, "NBC_LooseConcrete": 20, "NBC_LooseBottle": 15,
               "nothing": 25},
}
WALL_POOLS = {k for k in POOLS if not k.endswith(("clutter", "trash", "boxes", "industrial", "paperwork", "debris"))}


# ---------------------------------------------------------------- recipes

def W(w, pieces=(), prob=40, **slots):
    """A wall run `w` seeds long. pieces: class names (spaced evenly) or (class, x) or (class, x, dist).
    slots: pool name -> x positions, e.g. home_art=[64]. Wall pools hang on the wall, the rest stand
    on the floor in front of it."""
    return {"w": w, "pieces": list(pieces), "prob": prob, "slots": slots}


def I(things, prob=40, **slots):
    """A free-standing group around (0, 0): things are (class, x, y, angle); slots: pool -> [(x, y)]."""
    return {"things": things, "prob": prob, "slots": slots}


GROUPS = {
    # ---- homes (Corpo Wars kit_residential: H_LIVING, H_KITCHEN, H_BED, H_BATH, H_STUDY)
    "living": {
        "walls": [
            W(1, ["CW_FSofa"], 50, home_art=[64]),
            W(1, ["CW_FCredenza"], 30, home_art=[64]),
            W(1, ["CW_FWallTV"], 30, home_clutter=[24]),
            W(1, ["CW_FBookshelf", "CW_FBookshelf"], 25),
            W(1, ["CW_FArmchair"], 20, home_fix=[96]),
            W(2, ["CW_FBookshelf", "CW_FSofa", "CW_FBookshelf"], 30, home_art=[128]),
            W(2, ["CW_FSofa", "CW_FArmchair"], 30, home_art=[80], home_fix=[200]),
            W(1, [], 40, home_art=[64]),
            W(2, [], 30, home_art=[64, 192], home_fix=[128]),
        ],
        "islands": [
            I([("CW_FCoffeeTable", 0, 0, 0), ("CW_FArmchair", 0, 54, 270), ("CW_FArmchair", 0, -54, 90)], 40),
            I([("CW_FSofa", -56, 0, 0), ("CW_FCoffeeTable", 0, 0, 0), ("CW_FArmchair", 48, 40, 225)], 40,
              home_clutter=[(48, -44)]),
        ],
    },
    "kitchen": {
        "walls": [
            W(1, ["CW_FCounter"], 60, home_fix=[112]),
            W(2, ["CW_FCounter", "CW_FCounter"], 40),
            W(1, [], 30, kitchen_clutter=[40, 96]),
            W(2, ["CW_FCounter"], 30, kitchen_clutter=[200]),
            W(1, [], 20, home_fix=[64]),
        ],
        "islands": [
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FChairGuest", 0, 34, 270), ("CW_FChairGuest", 0, -34, 90)], 50),
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FChairGuest", 34, 0, 180), ("CW_FChairGuest", -34, 0, 0),
               ("CW_FChairGuest", 0, 34, 270)], 30, kitchen_clutter=[(40, -40)]),
        ],
    },
    "bedroom": {
        "walls": [
            W(1, ["CW_FBed"], 60, home_art=[64]),
            W(1, ["CW_FCredenza"], 30, home_art=[64]),
            W(2, ["CW_FBed", "CW_FCredenza"], 40, home_art=[64]),
            W(2, ["CW_FBed", "CW_FBed"], 20, home_fix=[128]),
            W(1, ["CW_FBookshelf", "CW_FBookshelf"], 15),
            W(1, [], 40, home_art=[64], home_clutter=[100]),
        ],
        "islands": [
            I([("CW_FArmchair", 0, 0, 0)], 30, home_clutter=[(28, 28)]),
        ],
    },
    "bath": {
        "walls": [
            W(1, ["CW_FVanity"], 50, bath_wall=[24]),
            W(2, ["CW_FStalls", "CW_FVanity"], 40),
            W(1, ["CW_FStalls"], 30),
            W(1, [], 50, bath_wall=[64], bath_clutter=[64]),
        ],
        "islands": [],
    },
    "office": {    # H_STUDY and the civic/street offices: the landlord's office, a gang's books
        "walls": [
            W(1, ["CW_FFileCabinet", "CW_FFileCabinet", "CW_FFileCabinet"], 40, office_wall=[64]),
            W(1, ["CW_FBookshelf", "CW_FBookshelf"], 30),
            W(1, ["CW_FCopier", ("CW_FWaterCooler", 100)], 25, office_wall=[60]),
            W(1, ["CW_FWhiteboard"], 25),
            W(2, ["CW_FFileCabinet", "CW_FFileCabinet", "CW_FCredenza", "CW_FFileCabinet"], 30, office_wall=[128]),
            W(1, [], 40, office_wall=[64], paperwork=[100]),
        ],
        "islands": [
            I([("CW_FDeskExec", 0, 0, 270), ("CW_FChairExec", 0, 36, 270), ("CW_FChairGuest", -20, -40, 90),
               ("CW_FChairGuest", 20, -40, 90)], 50),
            I([("CW_FDeskWork", 0, 0, 270), ("CW_FChair", 0, 30, 270)], 40, paperwork=[(40, 20)]),
            I([("CW_FConfTable", 0, 0, 0), ("CW_FChairGuest", -32, 34, 270), ("CW_FChairGuest", 32, 34, 270),
               ("CW_FChairGuest", -32, -34, 90), ("CW_FChairGuest", 32, -34, 90)], 30),
        ],
    },
    # ---- service floors (kit_street / kit_industrial / kit_underground)
    "storage": {
        "walls": [
            W(1, ["CW_FShelving"], 60),
            W(2, ["CW_FShelving", "CW_FShelving"], 40),
            W(1, ["CW_FCrates", "CW_FCrates"], 30, boxes=[64]),
            W(2, ["CW_FShelving", ("CW_FCrates", 168), ("CW_FPallet", 224)], 25),
            W(1, [], 30, boxes=[32, 96], debris=[64]),
        ],
        "islands": [
            I([("CW_FCrates", 0, 0, 0), ("CW_FCrates", 40, 0, 90), ("CW_FPallet", 0, 44, 0)], 40, boxes=[(-36, -28)]),
            I([("CW_FPallet", 0, 0, 0)], 40, boxes=[(0, 0), (32, 32)]),
            I([("CW_FShelving", 0, -14, 270), ("CW_FShelving", 0, 14, 90)], 30),
        ],
    },
    "utility": {   # boiler rooms, laundry, meter rooms (H_UTILITY, U_PUMP)
        "walls": [
            W(1, ["CW_FGenerator"], 40, utility_wall=[112]),
            W(1, ["CW_FPipes"], 40),
            W(2, ["CW_FGenerator", "CW_FTransformer"], 30, utility_wall=[128]),
            W(1, ["CW_FTank"], 20, utility_wall=[112]),
            W(1, [], 30, home_clutter=[], utility_wall=[40, 96]),
            W(1, [], 25, industrial=[64], utility_wall=[100]),
        ],
        "islands": [
            I([("CW_FTank", 0, 0, 0)], 30, industrial=[(44, 40)]),
            I([("CW_FGenerator", 0, 0, 0)], 30, industrial=[(-40, 40)]),
        ],
    },
    "laundry": {
        "walls": [
            W(1, [], 50, home_fix=[64], kitchen_clutter=[]),
            W(1, [("CWD_Apt_Washer", 40), ("CWD_Apt_Dryer", 88)], 60, bath_clutter=[]),
            W(2, [("CWD_Apt_Washer", 40), ("CWD_Apt_Dryer", 88), ("CWD_Apt_Washer", 168), ("CWD_Apt_Dryer", 216)], 40),
            W(1, ["CW_FShelving"], 20),
        ],
        "islands": [I([("CW_FRoundTable", 0, 0, 0)], 20, home_clutter=[(30, 20)])],
    },
    "workshop": {
        "walls": [
            W(1, ["CW_FWorkbench"], 50, shop_wall=[64]),
            W(2, ["CW_FWorkbench", "CW_FShelving"], 30),
            W(1, ["CW_FLocker", "CW_FLocker", "CW_FLocker"], 30),
            W(1, [], 30, shop_wall=[64], industrial=[64]),
        ],
        "islands": [
            I([("CW_FWorkbench", 0, -16, 90), ("CW_FWorkbench", 0, 16, 270)], 30),
            I([("CW_FScrap", 0, 0, 0)], 30, industrial=[(40, 40)]),
        ],
    },
    "garage": {    # chop shops under the towers
        "walls": [
            W(1, ["CW_FWorkbench"], 40, shop_wall=[64]),
            W(1, ["CW_FTank"], 20),
            W(2, ["CW_FWorkbench", ("CW_FShelving", 200)], 30),
            W(1, [], 40, shop_wall=[64], industrial=[32, 96]),
        ],
        "islands": [
            I([("CW_FPallet", 0, 0, 0), ("CWD_Ind_Pallet_Jack", 40, 0, 0)], 30),
            I([("CW_FScrap", 0, 0, 0)], 30, debris=[(40, -40)], industrial=[(-40, 40)]),
        ],
    },
    "lockers": {   # squad rooms, the rec centre's changing rooms
        "walls": [
            W(1, ["CW_FLocker", "CW_FLocker", "CW_FLocker"], 50),
            W(1, ["CW_FBed"], 30),
            W(2, ["CW_FBed", ("CW_FLocker", 168), ("CW_FLocker", 216)], 30),
            W(1, [], 30, office_wall=[64]),
        ],
        "islands": [
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FChairGuest", 0, 34, 270), ("CW_FChairGuest", 0, -34, 90)], 30),
            I([("CW_FPew", 0, 0, 0)], 30),
        ],
    },
    # ---- gang floors
    "lab": {       # a cook lab in a gutted flat
        "walls": [
            W(1, ["CW_FLabBench"], 50, lab_wall=[64]),
            W(2, ["CW_FLabBench", "CW_FShelving"], 30),
            W(1, ["CW_FShelving"], 25),
            W(1, [], 30, lab_wall=[64], industrial=[64]),
        ],
        "islands": [
            I([("CW_FLabBench", 0, 0, 0)], 40, industrial=[(44, 40)]),
            I([("CW_FCrates", 0, 0, 0)], 30, boxes=[(40, 0)], industrial=[(-36, 36)]),
        ],
    },
    "grow": {
        "walls": [
            W(1, ["CW_FGrowBed"], 60, lab_wall=[64]),
            W(2, ["CW_FGrowBed", "CW_FGrowBed"], 40),
            W(1, [], 25, lab_wall=[64]),
        ],
        "islands": [
            I([("CW_FGrowBed", 0, -28, 0), ("CW_FGrowBed", 0, 28, 0)], 50),
            I([("CW_FGrowBed", 0, 0, 0)], 30, boxes=[(64, 0)]),
        ],
    },
    "den": {       # gang hangout: couches, a screen, crates of who knows what
        "walls": [
            W(1, ["CW_FSofa"], 40, posters=[64]),
            W(1, ["CW_FWallTV"], 25, trash=[100]),
            W(2, ["CW_FSofa", ("CW_FCrates", 200)], 30, posters=[80]),
            W(1, ["CW_FCrates", "CW_FCrates"], 30, debris=[64]),
            W(1, ["CW_FVending"], 15, posters=[100]),
            W(1, [], 40, posters=[64], trash=[32], debris=[100]),
        ],
        "islands": [
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FChairGuest", 0, 34, 270), ("CW_FChairGuest", 34, 0, 180)], 40,
              trash=[(-30, -30)]),
            I([("BurningBarrel", 0, 0, 0)], 25, debris=[(30, 20)], trash=[(-28, 24)]),
            I([("CW_FSofa", 0, -20, 90), ("CW_FCoffeeTable", 0, 24, 0)], 30, trash=[(36, 44)]),
        ],
    },
    "camp": {      # squatters in a stripped flat
        "walls": [
            W(1, ["CW_FBed"], 40, grime=[64], trash=[110]),
            W(1, ["CW_FScrap"], 30, debris=[110]),
            W(1, ["CW_FCrates"], 25, trash=[100], debris=[20]),
            W(2, ["CW_FBed", ("CW_FScrap", 200)], 25, grime=[128]),
            W(1, [], 50, grime=[64], debris=[40], trash=[96]),
        ],
        "islands": [
            I([("NBC_RubblePile", 0, 0, 0)], 40, debris=[(30, 24), (-28, -20)], trash=[(20, -34)]),
            I([("BurningBarrel", 0, 0, 0), ("CW_FPallet", 0, 48, 0)], 30, trash=[(-30, -20)], debris=[(36, -12)]),
            I([("CW_FScrap", 0, 0, 0)], 30, debris=[(40, 40)], trash=[(-44, 30)]),
        ],
    },
    # ---- ground floors
    "lobby": {
        "walls": [
            W(1, [], 50, lobby_wall=[40, 96]),
            W(1, ["CW_FPlanter"], 30, lobby_wall=[64]),
            W(2, ["CW_FPew", ("CW_FPlanter", 200)], 25, lobby_wall=[64]),
            W(1, ["CW_FVending"], 20, lobby_wall=[100]),
        ],
        "islands": [
            I([("CW_FReception", 0, 0, 90), ("CW_FChairExec", 34, 0, 180)], 30),
            I([("CW_FPlanter", 0, -20, 0), ("CW_FPlanter", 0, 20, 0)], 30),
            I([("CWD_Bank_Stanchions", 0, 0, 0)], 20),
        ],
    },
    "shop": {      # the bodega, the pawn shop
        "walls": [
            W(1, ["CW_FShelving"], 50, posters=[]),
            W(2, ["CW_FShelving", "CW_FShelving"], 40),
            W(1, ["CW_FCounter"], 30, posters=[64]),
            W(1, ["CW_FVending"], 25, posters=[100]),
            W(1, [], 30, posters=[64], boxes=[64]),
        ],
        "islands": [
            I([("CW_FShelving", 0, -14, 270), ("CW_FShelving", 0, 14, 90)], 40),
            I([("CW_FCounter", 0, 0, 90)], 30, boxes=[(30, 50)]),
        ],
    },
    "bar": {
        "walls": [
            W(1, ["CW_FBarCounter", ("CW_FStool", 40, 50), ("CW_FStool", 88, 50)], 50, posters=[64]),
            W(1, ["CW_FSofa"], 30, posters=[64]),
            W(2, ["CW_FSofa", "CW_FSofa"], 25, posters=[128]),
            W(2, ["CW_FBarCounter", ("CW_FStool", 40, 50), ("CW_FStool", 88, 50), ("CW_FVending", 200)], 30),
            W(1, [], 30, posters=[40, 96], trash=[64]),
        ],
        "islands": [
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FStool", 0, 30, 0), ("CW_FStool", 0, -30, 0)], 50, trash=[(30, 30)]),
            I([("CW_FRoundTable", 0, 0, 0), ("CW_FChairGuest", 34, 0, 180), ("CW_FChairGuest", -34, 0, 0)], 40),
        ],
    },
}

# Ungrouped outdoor decor: lots, courtyards and sidewalks
OUTDOOR = [
    ("dumpster", I([("CW_FDumpster", 0, 0, 0)], 60, trash=[(-30, 34), (34, 30)])),
    ("pallets", I([("CW_FPallet", 0, 0, 0), ("CW_FCrates", 44, 0, 0)], 50, boxes=[(-36, 30)])),
    ("rubble", I([("NBC_RubblePile", 0, 0, 0)], 60, debris=[(34, 20), (-30, -24), (10, -36)])),
    ("barricade", I([("CW_FBarrier", 0, -20, 90), ("CW_FBarrier", 0, 20, 90), ("CWD_Und_Cone_Orange", 40, 0, 0)], 40)),
    ("sandbags", I([("CW_FSandbags", 0, 0, 90), ("CW_FSandbags", 26, 40, 180)], 25, debris=[(-30, 30)])),
    ("stall", I([("CW_FStall", 0, 0, 0)], 30, boxes=[(40, 40)])),
    ("barrel_fire", I([("BurningBarrel", 0, 0, 0), ("CW_FPallet", 44, 0, 90)], 40, trash=[(-30, 20)],
                      debris=[(-20, -34)])),
    ("ac_unit", I([("CW_FAcUnit", 0, 0, 0)], 20, trash=[(36, 30)])),
]
# Ungrouped park decor: the projects' playground and the strip of dead grass
PARK = [
    ("park_benches", I([("CW_FPew", 0, -24, 90), ("CW_FPew", 0, 24, 270)], 60, trash=[(56, 0)])),
    ("park_bench", I([("CW_FPew", 0, 0, 90), ("CW_FLampPost", 56, -16, 0)], 60, trash=[(-50, 10)])),
    ("park_picnic", I([("CW_FRoundTable", 0, 0, 0), ("CW_FStool", 0, 30, 0), ("CW_FStool", 0, -30, 0),
                       ("CW_FStool", 30, 0, 0)], 40, trash=[(-36, 30)])),
    ("park_lamp", I([("CW_FLampPost", 0, 0, 0)], 40, debris=[(24, 20)], trash=[(-20, -24)])),
    ("park_camp", I([("CW_FBed", 0, 0, 0), ("BurningBarrel", 48, 40, 0)], 25, trash=[(-30, 40)], debris=[(40, -30)])),
    ("park_rubble", I([("NBC_RubblePile", 0, 0, 0)], 30, debris=[(30, 24), (-28, -20)])),
]
# Ungrouped indoor clutter for Bricks rooms that didn't get a room set
INDOOR = [
    ("rubble_in", I([("NBC_RubblePile", 0, 0, 0)], 30, debris=[(30, 24), (-24, -28)])),
    ("bricks_in", I([], 30, debris=[(0, 0), (20, 16), (-16, 20)], trash=[(-20, -20)])),
    ("crates_in", I([("CW_FCrates", 0, 0, 0)], 25, boxes=[(36, 20)])),
]


# ---------------------------------------------------------------- WAD writing

class FabMap:
    def __init__(self):
        self.verts, self.lines, self.sides, self.sectors, self.things = [], [], [], [], []

    def vert(self, x, y):
        v = (int(x), int(y))
        if v not in self.verts:
            self.verts.append(v)
        return self.verts.index(v)

    def sector(self, floor_h, ceil_h, floor_tex, ceil_tex):
        self.sectors.append((floor_h, ceil_h, floor_tex, ceil_tex, 144, 0, 0))
        return len(self.sectors) - 1

    def side(self, sector, mid="-"):
        self.sides.append((0, 0, "-", "-", mid, sector))
        return len(self.sides) - 1

    def loop(self, pts, right, left=None, mid="-", flags=1):
        """Lines through pts (closed); the right side faces `right`, the left `left` (None: one-sided)."""
        for k in range(len(pts)):
            a, b = pts[k], pts[(k + 1) % len(pts)]
            r = self.side(right, mid if left is None else "-")
            l = -1 if left is None else self.side(left)
            self.lines.append((self.vert(*a), self.vert(*b), flags if left is None else 4, 0, 0, r, l))

    def thing(self, x, y, angle, tid):
        self.things.append((int(round(x)), int(round(y)), int(angle) % 360, tid, 7))

    def lumps(self, name):
        def pack(fmt, rows):
            return b"".join(struct.pack(fmt, *[c.encode() if isinstance(c, str) else c for c in row]) for row in rows)
        return [
            (name, b""),
            ("THINGS", pack("<hhhhh", self.things)),
            ("LINEDEFS", pack("<hhhhhhh", self.lines)),
            ("SIDEDEFS", pack("<hh8s8s8sh", self.sides)),
            ("VERTEXES", pack("<hh", self.verts)),
            ("SEGS", b""), ("SSECTORS", b""), ("NODES", b""),
            ("SECTORS", pack("<hh8s8shhh", self.sectors)),
            ("REJECT", b""), ("BLOCKMAP", b""),
        ]


def write_wad(path, lumps):
    body, directory = b"", b""
    for name, blob in lumps:
        directory += struct.pack("<ii8s", 12 + len(body), len(blob), name.encode())
        body += blob
    with open(path, "wb") as f:
        f.write(struct.pack("<4sii", b"PWAD", len(lumps), 12 + len(body)) + body + directory)


def ceil8(v):
    return int(math.ceil(v / 8.0) * 8)


class Slots:
    """Placeholder numbers for one prefab: each position gets its own, so neighbours differ."""
    def __init__(self):
        self.fields = {}

    def take(self, pool_name):
        tid = PLACEHOLDER_BASE + len(self.fields)
        assert tid < 27000, "too many random slots in one prefab"
        self.fields[tid] = POOLS[pool_name]
        return tid


def thing_id(cls):
    if cls not in IDS:
        raise SystemExit("no map number for " + cls + " (run tools/import/port_cw_props.py)")
    return IDS[cls]


def build_wall(spec):
    W_ = spec["w"] * 128
    pieces = []
    plain = [p for p in spec["pieces"] if isinstance(p, str)]
    k = 0
    for p in spec["pieces"]:
        if isinstance(p, str):
            x = W_ * (k + 0.5) / len(plain)
            k += 1
            pieces.append((p, x, None))
        else:
            pieces.append((p[0], p[1], p[2] if len(p) > 2 else None))
    # distance from the wall face to each piece's centre
    dists = [(c, x, dist if dist is not None else depth_of(c) / 2 + WALL_GAP) for c, x, dist in pieces]
    reach = max([d + depth_of(c) / 2 for c, x, d in dists] + [0])
    deep = 16 + (ceil8(reach + 4) if reach else 0)
    face = deep - 16

    m = FabMap()
    outer = m.sector(0, 128, "_NOTHING", "_NOTHING")
    m.loop([(-64, -64), (-64, deep + 64), (W_ + 64, deep + 64), (W_ + 64, -64)], outer, mid="_NOTHING")
    if face > 0:
        # a 4-unit strip of room floor at the front: gives the prefab its (0, 0) corner, changes nothing
        strip = m.sector(0, 128, "_FLOOR", "_NOTHING")
        m.loop([(0, 0), (0, 4), (W_, 4), (W_, 0)], strip, outer)
    m.loop([(0, face), (W_, face), (W_, deep), (0, deep)], outer, mid="_WALL")   # the wall itself

    slots = Slots()
    for c, x, d in dists:
        m.thing(x, face - d, 270, thing_id(c))
    for pool_name, xs in spec["slots"].items():
        for x in xs:
            y = face - 1 if pool_name in WALL_POOLS else min(face - 12, -12)
            m.thing(x, y, 270, slots.take(pool_name))
    return m, deep, slots


def build_island(spec):
    reach = 8
    m = FabMap()
    slots = Slots()
    for c, x, y, ang in spec["things"]:
        m.thing(x, y, ang, thing_id(c))
        reach = max(reach, abs(x) + extent_of(c), abs(y) + extent_of(c))
    for pool_name, pts in spec["slots"].items():
        for x, y in pts:
            m.thing(x, y, 270, slots.take(pool_name))
            reach = max(reach, abs(x) + 12, abs(y) + 12)
    size = ceil8(reach)
    outer = m.sector(0, 128, "_NOTHING", "_NOTHING")
    b = size + 64
    m.loop([(-b, -b), (-b, b), (b, b), (b, -b)], outer, mid="_NOTHING")
    centre = m.sector(0, 128, "_FLOOR", "_NOTHING")     # an 8x8 patch of room floor: the prefab's bounds
    m.loop([(-4, -4), (-4, 4), (4, 4), (4, -4)], centre, outer)
    return m, size, slots


def lua_value(v):
    if isinstance(v, dict):
        parts = []
        for k, w in v.items():
            key = "nothing" if k == "nothing" else "[%d]" % thing_id(k)
            parts.append("%s=%d" % (key, w))
        return "{ " + ", ".join(parts) + " }"
    if isinstance(v, str):
        return '"%s"' % v
    if v is True:
        return "true"
    return str(v)


def lua_def(name, fields):
    out = ["PREFABS.%s =" % name, "{"]
    for k, v in fields:
        out.append("  %s = %s," % (k, lua_value(v)))
    out.append("}\n")
    return "\n".join(out)


COMMON = [("solid_ents", True), ("nbc_only", True)]
HEADER = ("-- Generated by tools/Obsidian/make_cw_fabs.py from Corpo Wars' room recipes. Don't edit; rebuild.\n"
          "-- %s\n\n")


def emit(kind, base, entries):
    """entries: (def name, FabMap, fields)"""
    os.makedirs(os.path.join(OUT, kind), exist_ok=True)
    lumps, defs = [], []
    for i, (name, fab, fields) in enumerate(entries):
        mapname = "MAP%02d" % (i + 1)
        lumps += fab.lumps(mapname)
        defs.append(lua_def(name, [("file", "%s/%s.wad" % (kind, base)), ("map", mapname)] + fields))
    write_wad(os.path.join(OUT, kind, base + ".wad"), lumps)
    with open(os.path.join(OUT, kind, base + ".lua"), "w", encoding="ascii") as f:
        f.write(HEADER % base + "\n".join(defs))


def slot_fields(slots):
    return [("thing_%d" % tid, p) for tid, p in slots.fields.items()]


def main():
    for old in glob.glob(os.path.join(OUT, "*", "nbc_cw_*")):
        os.remove(old)
    n_walls = n_decor = 0
    for group, sets in GROUPS.items():
        walls = []
        for i, spec in enumerate(sets["walls"]):
            fab, deep, slots = build_wall(spec)
            walls.append(("Wall_nbc_cw_%s_%d" % (group, i + 1), fab,
                          [("prob", spec["prob"]), ("env", "building"), ("group", "nbc_" + group),
                           ("where", "edge"), ("seed_w", spec["w"]), ("deep", deep), ("height", 96),
                           ("bound_z1", 0), ("bound_z2", 96), ("z_fit", "top")] + COMMON + slot_fields(slots)))
        emit("wall", "nbc_cw_" + group, walls)
        n_walls += len(walls)
        islands = []
        for i, spec in enumerate(sets["islands"]):
            fab, size, slots = build_island(spec)
            islands.append(("Decor_nbc_cw_%s_%d" % (group, i + 1), fab,
                            [("prob", spec["prob"]), ("env", "building"), ("group", "nbc_" + group),
                             ("where", "point"), ("size", size), ("height", 96),
                             ("bound_z1", 0), ("bound_z2", 96), ("sink_mode", "never_liquids")]
                            + COMMON + slot_fields(slots)))
        if islands:
            emit("decor", "nbc_cw_" + group, islands)
            n_decor += len(islands)
    for env, base, sets, prob_mult in (("outdoor", "nbc_cw_street", OUTDOOR, 100), ("park", "nbc_cw_park", PARK, 150),
                                     ("building", "nbc_cw_clutter", INDOOR, 50)):
        entries = []
        for name, spec in sets:
            fab, size, slots = build_island(spec)
            entries.append(("Decor_nbc_cw_%s" % name, fab,
                            [("prob", spec["prob"] * prob_mult), ("env", env), ("where", "point"), ("size", size),
                             ("height", 96), ("bound_z1", 0), ("bound_z2", 96), ("sink_mode", "never_liquids")]
                            + COMMON + slot_fields(slots)))
        emit("decor", base, entries)
        n_decor += len(entries)
    print("room sets: %d (%s)" % (len(GROUPS), ", ".join(GROUPS)))
    print("wrote %d wall prefabs and %d decor prefabs to %s" % (n_walls, n_decor, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
