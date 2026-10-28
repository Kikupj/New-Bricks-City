------------------------------------------------------------------------
--  ADDON: New Bricks City theme for DOOM 2
------------------------------------------------------------------------
--
--  A level theme for the walled-off district in New Bricks City: city
--  blocks of brick tenements with streets and sidewalks between them,
--  courtyards, plaster flats, concrete stairwells and basements.
--
--  Built on Obsidian's Urban theme (so the street grammar, cars and
--  barriers keep working), then stripped of everything Doom and hell:
--    * every texture is mapped onto the New Bricks City / Corpo Wars set
--      (nbc/textures/cw/), only the sky keeps its required name
--    * hellish, gothic, gore and techbase prefabs are switched off
--    * hell decorations (skulls, impaled and hanging bodies, candles,
--      coloured torches, Doom corpses) become lamps, barrels or nothing
--    * no lava, blood, nukage or slime; no teleporters, cages or caves
--  Streets Mode is forced on for every level.
--
--  Play the output WITH the mod, which holds the textures:
--    uzdoom -iwad freedoom2.wad -file nbc <output>.wad
--
--  Settings: theme = nbc_bricks, and enable this module (@new_bricks_city = 1).
--
------------------------------------------------------------------------

NBC_BRICKS = {}


-- Upper-case tables are merged into the game by Obsidian.
-- Wall textures get a floor partner and flats a wall partner.
NBC_BRICKS.MATERIALS =
{
  -- brick
  ADBRICK  = { t="ADBRICK",  f="CWCONCF" },
  AXW84    = { t="AXW84",    f="CWCONCF" },
  AXW85    = { t="AXW85",    f="CWCONCF" },

  -- tower facades with windows (256 x 512)
  CWUQB    = { t="CWUQB",    f="CWPAVE" },
  CWUQC    = { t="CWUQC",    f="CWPAVE" },
  CWUQF    = { t="CWUQF",    f="CWPAVE" },
  CWUEE    = { t="CWUEE",    f="CWPAVE" },
  CWUDC    = { t="CWUDC",    f="CWPAVE" },

  -- plaster and paint
  CWWALL1  = { t="CWWALL1",  f="CWCARP1" },
  CWWALL2  = { t="CWWALL2",  f="CWCARP1" },
  AXCITY08 = { t="AXCITY08", f="AXDU02" },
  AXCITY09 = { t="AXCITY09", f="AXDU02" },
  ADGREYW  = { t="ADGREYW",  f="CWTILEF" },
  ADGREY2  = { t="ADGREY2",  f="CWTILEF" },
  CWTILEW  = { t="CWTILEW",  f="CWTILEF" },
  CWWOOD1  = { t="CWWOOD1",  f="ADFWOOD" },
  AXHW09   = { t="AXHW09",   f="CWCARP1" },
  AXDW06A  = { t="AXDW06A",  f="ADFWOOD" },

  -- grime and concrete
  CWWALLD  = { t="CWWALLD",  f="CWCONCF" },
  AXW24    = { t="AXW24",    f="AXF02" },
  AXW27    = { t="AXW27",    f="AXF02" },
  AXW89    = { t="AXW89",    f="AXF02" },
  AXSTEP23 = { t="AXSTEP23", f="CWSTAIF" },
  AXW12    = { t="AXW12",    f="AXF05" },
  AXW14    = { t="AXW14",    f="AXF05" },
  AXW23    = { t="AXW23",    f="AXF05" },
  AXW25    = { t="AXW25",    f="AXF05" },
  AXW43A   = { t="AXW43A",   f="AXF02" },
  AXW43B   = { t="AXW43B",   f="AXF02" },
  AXW43C   = { t="AXW43C",   f="AXF02" },
  ADCONC1  = { t="ADCONC1",  f="AXF02" },
  CWCONCW  = { t="CWCONCW",  f="CWCONCF" },
  CWRETAIN = { t="CWRETAIN", f="CWCONCF" },
  CWSEAWAL = { t="CWSEAWAL", f="CWCONCF" },

  -- lobby
  ADMARBG  = { t="ADMARBG",  f="ADFMARG" },
  ADMARBL  = { t="ADMARBL",  f="ADFMARB" },

  -- metal, doors, signs, switches, railings
  ADMETL1  = { t="ADMETL1",  f="AXF16" },
  ADMETL2  = { t="ADMETL2",  f="AXF16" },
  ADDOOR1  = { t="ADDOOR1",  f="AXF16" },
  ADDOOR2  = { t="ADDOOR2",  f="AXF16" },
  CWDOOR1  = { t="CWDOOR1",  f="AXF16" },
  CWDOOR2  = { t="CWDOOR2",  f="AXF16" },
  CWDOORS  = { t="CWDOORS",  f="AXF16" },
  CWDOORF  = { t="CWDOORF",  f="AXF16" },
  CWFIRED  = { t="CWFIRED",  f="AXF16" },
  ADEXIT   = { t="ADEXIT",   f="AXF16" },
  ADCOMP1  = { t="ADCOMP1",  f="AXF16" },
  CWFENCE  = { t="CWFENCE",  f="CWPAVE" },
  CWDOORWL = { t="CWDOORWL", f="AXF16" },
  ADDOOR2  = { t="ADDOOR2",  f="AXF16" },
  ADDOOR3  = { t="ADDOOR3",  f="AXF16" },
  ADDOOR1  = { t="ADDOOR1",  f="AXF16" },
  ADDOORS  = { t="ADDOORS",  f="AXF16" },
  ADDOORT  = { t="ADDOORT",  f="AXF16" },
  AXB21B   = { t="AXB21B",   f="AXF16" },
  AXB27    = { t="AXB27",    f="AXF16" },
  AXW56    = { t="AXW56",    f="AXF16" },

  -- steel, corrugated sheet, an electrical box (the switches)
  AXW01    = { t="AXW01",    f="AXF16" },
  AXW44    = { t="AXW44",    f="AXF16" },
  AXW72    = { t="AXW72",    f="AXF16" },
  AXW30    = { t="AXW30",    f="AXF16" },
  AXW86    = { t="AXW86",    f="CWCONCF" },
  AXW87    = { t="AXW87",    f="CWCONCF" },
  AXW38    = { t="AXW38",    f="CWCONCF" },
  AXW28    = { t="AXW28",    f="CWCONCF" },
  ADGLASSB = { t="ADGLASSB", f="AXF16" },

  -- crates: wooden, labelled, a blue steel one
  AXB03    = { t="AXB03",    f="ADFWOOD" },
  AXB04    = { t="AXB04",    f="ADFWOOD" },
  AXB09    = { t="AXB09",    f="ADFWOOD" },
  AXB10    = { t="AXB10",    f="ADFWOOD" },
  AXB12    = { t="AXB12",    f="ADFWOOD" },
  AXB14    = { t="AXB14",    f="AXF16" },

  -- floors
  CWCARP1  = { f="CWCARP1",  t="CWWALL1" },
  CWCARP2  = { f="CWCARP2",  t="CWWALL2" },
  CWCARP3  = { f="CWCARP3",  t="CWWALL1" },
  ADFWOOD  = { f="ADFWOOD",  t="AXDW06A" },
  ADFWOD2  = { f="ADFWOD2",  t="AXDW06A" },
  AXHF07A  = { f="AXHF07A",  t="AXDW06A" },
  AXHW07A  = { f="AXHW07A",  t="AXDW06A" },
  AXDU02   = { f="AXDU02",   t="AXCITY08" },
  CWTILEF  = { f="CWTILEF",  t="CWTILEW" },
  AXF39    = { f="AXF39",    t="ADCONC1" },
  AXF39B   = { f="AXF39B",   t="ADCONC1" },
  AXF01    = { f="AXF01",    t="ADCONC1" },
  AXF02    = { f="AXF02",    t="ADCONC1" },
  AXF03    = { f="AXF03",    t="ADCONC1" },
  AXF05    = { f="AXF05",    t="AXW23" },
  AXF06B   = { f="AXF06B",   t="AXW23" },
  CWCONCF  = { f="CWCONCF",  t="CWCONCW" },
  ADFDARK  = { f="ADFDARK",  t="ADGREY2" },
  ADFMARB  = { f="ADFMARB",  t="ADMARBL" },
  ADFMARG  = { f="ADFMARG",  t="ADMARBG" },
  CWSTAIF  = { f="CWSTAIF",  t="AXSTEP23" },
  CWWATER  = { f="CWWATER",  t="CWSEAWAL" },
  -- Freedoom's animated water
  FWATER1  = { f="FWATER1",  t="CWSEAWAL" },

  -- the 30 lit-window facades (256 x 512): brick, stone, concrete and modern blocks
  CWUDA = { t="CWUDA", f="CWPAVE" }, CWUDB = { t="CWUDB", f="CWPAVE" }, CWUDD = { t="CWUDD", f="CWPAVE" },
  CWUDE = { t="CWUDE", f="CWPAVE" }, CWUDF = { t="CWUDF", f="CWPAVE" }, CWUEA = { t="CWUEA", f="CWPAVE" },
  CWUEB = { t="CWUEB", f="CWPAVE" }, CWUEC = { t="CWUEC", f="CWPAVE" }, CWUED = { t="CWUED", f="CWPAVE" },
  CWUEF = { t="CWUEF", f="CWPAVE" }, CWUGA = { t="CWUGA", f="CWPAVE" }, CWUGB = { t="CWUGB", f="CWPAVE" },
  CWUGC = { t="CWUGC", f="CWPAVE" }, CWUGD = { t="CWUGD", f="CWPAVE" }, CWUGE = { t="CWUGE", f="CWPAVE" },
  CWUGF = { t="CWUGF", f="CWPAVE" }, CWUHA = { t="CWUHA", f="CWPAVE" }, CWUHB = { t="CWUHB", f="CWPAVE" },
  CWUHC = { t="CWUHC", f="CWPAVE" }, CWUHD = { t="CWUHD", f="CWPAVE" }, CWUHE = { t="CWUHE", f="CWPAVE" },
  CWUHF = { t="CWUHF", f="CWPAVE" }, CWUQA = { t="CWUQA", f="CWPAVE" }, CWUQD = { t="CWUQD", f="CWPAVE" },
  CWUQE = { t="CWUQE", f="CWPAVE" },

  -- subway: tile, track, a train
  CWTRAIN  = { t="CWTRAIN",  f="CWCONCF" },
  CWRAILA  = { f="CWRAILA",  t="CWRETAIN" },
  CWRAILB  = { f="CWRAILB",  t="CWRETAIN" },
  AXF27    = { f="AXF27",    t="CWTILEW" },
  -- industrial: grating, plate, a green shutter
  AXF40    = { f="AXF40",    t="AXW01" },
  AXF44    = { f="AXF44",    t="AXW44" },
  AXW29    = { t="AXW29",    f="CWCONCF" },

  -- streets (128 x 128): asphalt road, paving-slab sidewalk
  CWASPH   = { f="CWASPH",   t="CWRETAIN" },
  CWPAVE   = { f="CWPAVE",   t="CWRETAIN" },

  -- park ground (Freedoom's grass, kept: the remap would turn it to dirt)
  GRASS1   = { f="GRASS1",   t="CWRETAIN" },
  GRASS2   = { f="GRASS2",   t="CWRETAIN" },

  -- ceilings
  AXDU03   = { f="AXDU03",   t="CWWALL1" },
  CWCEILD  = { f="CWCEILD",  t="CWWALLD" },
  CWCEILT  = { f="CWCEILT",  t="ADCONC1" },
  ADCTILE  = { f="ADCTILE",  t="ADGREYW" },
  ADCLITE  = { f="ADCLITE",  t="ADGREYW" },
  AXF16    = { f="AXF16",    t="ADCONC1" },
}


-- Streets: asphalt sunk a kerb's height below a paving-slab sidewalk.
NBC_BRICKS.SINKS =
{
  nbc_street =
  {
    mat = "CWASPH",
    dz = -8,

    trim_mat = "CWPAVE",
    trim_dz = 0,
  },
}


------------------------------------------------------------------------
--  Theme content (lower-case: kept out of Obsidian's table merge)
------------------------------------------------------------------------

-- Room themes. Each copies the matching Urban room theme (so every field
-- Obsidian expects is there) and replaces its textures.
NBC_BRICKS.rooms =
{
  -- bare brick inside and out: the default Bricks interior
  Tenement = { base = "urban_Brick", env = "building", prob = 100,
    walls    = { ADBRICK=60, AXW85=50, CWWALLD=15 },
    floors   = { AXHF07A=40, AXHW07A=30, ADFWOOD=30, CWCARP3=20, AXF39=20 },
    ceilings = { AXDU03=50, CWCEILD=40 },
    wall_groups = { nbc_living=30, nbc_bedroom=25, nbc_kitchen=25, nbc_bath=10, nbc_den=15, nbc_camp=10,
                    nbc_storage=10, nbc_laundry=5 } },

  -- the flats: paint, plaster, carpet
  Flat = { base = "urban_Brick", env = "building", prob = 80,
    walls    = { CWWALL1=40, CWWALL2=40, AXCITY08=30, AXCITY09=30, AXHW09=25, CWWOOD1=10 },
    floors   = { CWCARP1=40, CWCARP2=30, CWCARP3=30, AXDU02=30, ADFWOD2=20, CWTILEF=10 },
    ceilings = { AXDU03=70, CWCEILD=10 },
    wall_groups = { nbc_living=30, nbc_bedroom=30, nbc_kitchen=25, nbc_bath=15, nbc_office=5 } },

  -- abandoned floors: water-stained concrete, scorched paint
  Derelict = { base = "urban_Cement", env = "building", prob = 60,
    walls    = { AXW23=40, AXW25=40, AXW12=8, AXW14=8, CWWALLD=30, ADCONC1=20 },
    floors   = { CWCONCF=50, AXF05=40, AXF06B=20, AXF01=20 },
    ceilings = { CWCEILD=60, AXF16=20 },
    wall_groups = { nbc_camp=40, nbc_den=20, nbc_lab=20, nbc_grow=15, nbc_storage=15 } },

  -- stairwells, laundry rooms, basements
  Concrete = { base = "urban_Cement", env = "building", prob = 50,
    walls    = { ADCONC1=40, AXW24=30, CWCONCW=30, AXW89=25, AXW27=20 },
    floors   = { AXF02=40, AXF03=30, CWCONCF=30, AXF39B=20 },
    ceilings = { CWCEILT=40, CWCEILD=30 },
    wall_groups = { nbc_utility=30, nbc_storage=25, nbc_workshop=20, nbc_garage=20, nbc_laundry=15,
                    nbc_lockers=10 } },

  -- ground floors: the old lobby, the landlord's office, the bodega, the bar
  Lobby = { base = "urban_Brick", env = "building", prob = 25,
    walls    = { ADMARBL=30, AXCITY08=40, ADBRICK=30 },
    floors   = { ADFMARB=40, AXF39=40 },
    ceilings = { AXDU03=50 },
    wall_groups = { nbc_lobby=35, nbc_office=25, nbc_shop=25, nbc_bar=25 } },

  -- corridors between the flats
  deuce_Hallway = { base = "urban_deuce_Hallway", env = "hallway", group = "deuce", prob = 50,
    walls    = { CWWALLD=40, ADBRICK=30, AXW23=30, AXCITY09=30, AXW25=20 },
    floors   = { AXF39=40, CWCONCF=40, AXF05=20 },
    ceilings = { CWCEILD=50, AXDU03=30 } },

  -- service tunnels and basement runs
  metro_Hallway = { base = "urban_metro_Hallway", env = "hallway", group = "metro", prob = 50,
    walls    = { ADCONC1=40, CWCONCW=40, AXW27=30, AXW23=20 },
    floors   = { AXF02=40, CWCONCF=40, AXF05=20 },
    ceilings = { CWCEILT=50, CWCEILD=30 } },

  -- rubble and broken foundations (only if caves get switched on)
  Cave_rubble = { base = "urban_Cave_generic", env = "cave", prob = 50,
    walls    = { ADCONC1=50, AXW23=40, CWRETAIN=30 },
    floors   = { CWCONCF=50, AXF06B=40, AXF05=30 } },

  -- roofs: a stair hut or the lift machine room on top of a tower
  StairHut = { base = "urban_Cement", env = "building", prob = 50,
    walls    = { CWCONCW=40, ADBRICK=30, AXW24=30, CWWALLD=20 },
    floors   = { CWCONCF=50, AXF02=30 },
    ceilings = { CWCEILD=50, AXF16=20 },
    wall_groups = { nbc_utility=40, nbc_storage=30, nbc_camp=20 } },

  -- tar and gravel roofs
  Roof_top = { base = "urban_Outdoors_generic", env = "outdoor", prob = 100,
    floors   = { CWASPH=40, AXF01=30, CWCONCF=30, AXF02=20 },
    naturals = { AXF01=40, CWCONCF=30, AXF06B=20 } },

  -- basements: old brick and poured concrete, low light
  Basement = { base = "urban_Cement", env = "building", prob = 100,
    walls    = { CWCONCW=40, ADBRICK=30, AXW24=30, CWWALLD=20, AXW43C=10 },
    floors   = { CWCONCF=50, AXF05=30, AXF02=20 },
    ceilings = { CWCEILD=50, AXF16=20 },
    light_adjusts = { -32, -16, -16, 0 },
    wall_groups = { nbc_utility=30, nbc_storage=25, nbc_den=20, nbc_lab=15, nbc_grow=15, nbc_camp=15 } },

  -- sewers and storm drains
  Sewer = { base = "urban_Cement", env = "building", prob = 50,
    walls    = { CWSEAWAL=40, CWRETAIN=30, CWWALLD=30, AXW14=15, AXW12=15 },
    floors   = { AXF05=40, CWCONCF=40 },
    ceilings = { CWCEILD=60 },
    light_adjusts = { -32, -32, -16 },
    wall_groups = { nbc_camp=40, nbc_utility=30 } },

  sewers_Hallway = { base = "urban_metro_Hallway", env = "hallway", group = "sewers", prob = 50,
    walls    = { CWSEAWAL=40, CWRETAIN=30, CWWALLD=30 },
    floors   = { AXF05=50, CWCONCF=30 },
    ceilings = { CWCEILD=50 } },

  pipeline_Hallway = { base = "urban_metro_Hallway", env = "hallway", group = "pipeline", prob = 50,
    walls    = { AXW14=30, AXW43C=30, CWCONCW=30 },
    floors   = { AXF40=40, CWCONCF=40 },
    ceilings = { CWCEILD=50 } },

  -- subway: tiled stations, the track tunnels
  Station = { base = "urban_Brick", env = "building", prob = 100,
    walls    = { CWTILEW=60, ADGREYW=25, CWWALL2=15, CWCONCW=15 },
    floors   = { CWTILEF=40, AXF27=30, CWCONCF=20 },
    ceilings = { ADCTILE=40, CWCEILT=40 },
    wall_groups = { nbc_lobby=30, nbc_shop=20, nbc_camp=15, nbc_utility=15 } },

  Tunnel = { base = "urban_Cement", env = "building", prob = 60,
    walls    = { CWWALLD=40, CWCONCW=30, CWRETAIN=30, CWTRAIN=6 },
    floors   = { CWRAILA=40, CWRAILB=20, CWCONCF=30 },
    ceilings = { CWCEILD=60 },
    light_adjusts = { -32, -16, 0 },
    wall_groups = { nbc_utility=30, nbc_camp=30 } },

  subway_Hallway = { base = "urban_metro_Hallway", env = "hallway", group = "subway", prob = 50,
    walls    = { CWTILEW=50, ADGREYW=30, CWWALLD=20 },
    floors   = { CWTILEF=40, CWCONCF=40 },
    ceilings = { ADCTILE=40, CWCEILT=40 } },

  -- industrial park: warehouses, workshops, yards
  Warehouse = { base = "urban_Cement", env = "building", prob = 100,
    walls    = { AXW86=40, AXW87=30, CWCONCW=30, AXW28=15, AXW29=10 },
    floors   = { CWCONCF=50, AXF02=30, AXF44=10 },
    ceilings = { AXF16=40, CWCEILD=40 },
    wall_groups = { nbc_storage=40, nbc_garage=30, nbc_workshop=30 } },

  Factory = { base = "urban_Cement", env = "building", prob = 60,
    walls    = { ADCONC1=40, AXW24=30, AXW89=30, AXW01=20, AXW43C=15 },
    floors   = { AXF02=40, AXF40=20, CWCONCF=30 },
    ceilings = { CWCEILD=50, AXF16=30 },
    wall_groups = { nbc_workshop=40, nbc_utility=30, nbc_lab=10, nbc_lockers=15 } },

  Yard_industrial = { base = "urban_Outdoors_generic", env = "outdoor", prob = 100,
    floors   = { CWASPH=40, CWCONCF=30, AXF05=20, AXF01=20 },
    naturals = { AXF06B=40, AXF05=30, CWCONCF=20 } },

  -- parks: paths, lawns, the court
  Park = { base = "urban_Outdoors_generic", env = "outdoor", prob = 100,
    floors   = { CWPAVE=40, AXF01=20, CWCONCF=20, CWASPH=10 },
    naturals = { GRASS1=50, GRASS2=40, AXF06B=20 } },

  -- courtyards, lots and sidewalks between the towers
  Outdoors_yard = { base = "urban_Outdoors_generic", env = "outdoor", prob = 60,
    floors   = { CWPAVE=50, CWASPH=30, AXF01=20, CWCONCF=20 },
    -- park ground: worn grass, dirt and broken concrete
    naturals = { GRASS1=15, GRASS2=10, AXF06B=40, CWCONCF=30, AXF01=20 } },
}


-- The level theme: Urban's fields, with these replaced.
NBC_BRICKS.theme_overrides =
{
  liquids = { water = 100 },

  -- building exteriors: brick towers with rows of windows
  facades =
  {
    CWUQB = 40, CWUQC = 40, CWUQF = 30, CWUEE = 30, CWUDC = 20,
    ADBRICK = 30, AXW85 = 30,
  },

  -- low walls round courtyards and lots
  -- (scenic_fences stays Urban's: those names are rail definitions with heights,
  -- and their textures come out as the CWFENCE chain-link through the remap)
  fences = { CWRETAIN = 60, CWCONCW = 40, ADCONC1 = 30, AXW85 = 20, ADBRICK = 20 },

  street_sinks = { nbc_street = 1 },

  -- trash fires and the mod's street lamps outside
  outdoor_torches = { burning_barrel = 50, nbc_lamppost = 50 },
  cave_torches = { burning_barrel = 50, lamp = 20 },
  -- loose debris on the floor (the quick-throw's bricks and bottles), the odd bloodstain
  passable_decor = { nbc_brick = 20, nbc_halfbrick = 15, nbc_concrete = 15, nbc_bottle = 15, pool_blood_2 = 4 },
  -- Freedoom draws Doom's trees as leafy green trees: none in the Bricks
  park_decor = { burning_barrel = 30, nbc_lamppost = 30, nbc_rubble = 20 },
  trees = { burning_barrel = 30, nbc_lamppost = 30 },
  cliff_trees = { burning_barrel = 30, nbc_lamppost = 30 },

  -- hell and Doom decorations: lamps, trash fires, or an invisible marker
  entity_remap =
  {
    candle = "dummy", candelabra = "lamp", tech_column = "lamp",
    mercury_lamp = "lamp", mercury_small = "lamp",
    blue_torch = "burning_barrel", blue_torch_sm = "lamp", green_torch = "burning_barrel",
    green_torch_sm = "lamp", red_torch = "burning_barrel", red_torch_sm = "lamp",
    green_pillar = "burning_barrel", green_column = "burning_barrel", green_column_hrt = "burning_barrel",
    red_pillar = "burning_barrel", red_column = "burning_barrel", red_column_skl = "burning_barrel",
    evil_eye = "burning_barrel", skull_rock = "burning_barrel", skull_pole = "burnt_tree",
    skull_kebab = "burnt_tree", skull_cairn = "burning_barrel",
    impaled_human = "dummy", impaled_twitch = "dummy",
    gutted_victim1 = "dummy", gutted_victim2 = "dummy", gutted_torso1 = "dummy", gutted_torso2 = "dummy",
    gutted_torso3 = "dummy", gutted_torso4 = "dummy",
    hang_arm_pair = "dummy", hang_leg_gone = "dummy", hang_torso = "dummy", hang_leg = "dummy",
    hang_twitching = "dummy", pool_brains = "pool_blood_1", gibbed_player = "pool_blood_2",
    gibs = "dummy", dead_player = "dummy", dead_demon = "dummy", dead_caco = "dummy", dead_skull = "dummy",
    keen = "dummy", burnt_tree = "dummy", brown_stub = "dummy", big_tree = "dummy",
  },

  -- Doom's monsters become the enemy pack's humans in New Bricks City.
  -- Favour street crews over the heavies.
  monster_prefs =
  {
    zombie = 2.5, shooter = 2.0, imp = 2.0, gunner = 1.8, ss_nazi = 1.2,
    demon = 1.0, spectre = 0.8, revenant = 0.8, knight = 0.8,
    caco = 0.4, baron = 0.4, pain = 0.3, mancubus = 0.3, arach = 0.3,
    vile = 0.15, skull = 0.1, Cyberdemon = 0.1, Spiderdemon = 0.1,
  },

  -- city blocks: streets and courtyards outside, tenements inside
  style_list =
  {
    caves = { none = 100 },
    outdoors = { few = 10, some = 60, heaps = 60 },
    big_outdoor_rooms = { few = 30, some = 60, heaps = 30 },
    liquids = { none = 100 },
    hallways = { few = 40, some = 50, heaps = 20 },
    windows = { some = 40, heaps = 90 },
    doors = { some = 50, heaps = 50 },
    teleporters = { none = 100 },
    cages = { none = 100 },
    steepness = { some = 40, heaps = 60 },   -- split-level floors, stairs and lifts everywhere
    symmetry = { none = 40, few = 40, some = 20 },
    keys = { none = 20, few = 60, some = 20 },
    barrels = { few = 70, some = 30 },   -- Doom's exploding drums: a few, not a dump
    scenics = { none = 100 },   -- vistas are built like caves: cliffs, not city
    parks = { few = 60, some = 35, heaps = 5 },
    park_detail = { some = 50, heaps = 50 },
    fences = { few = 30, some = 70 },
    porches = { some = 30, heaps = 70 },
    pictures = { none = 70, few = 30 },
    natural_parks = { none = 100 },   -- rock-walled nature parks: not in the Bricks
  },

  -- the city-skyline skybox only
  skyboxes = { Skybox_garrett_city = 50 },

  streets_friendly = true,

  -- Urban's groups, cut down to what a city block has (no gothic, tech-lit, castle or mine pieces)
  narrow_halls = { vent = 50, access = 25 },
  beam_groups = { beam_lights = 25, beam_lights_white = 40, beam_wood = 30, beam_textured = 50 },
  fence_groups = { PLAIN = 50, gappy = 50, fence_corrugated_steel = 60, fence_highway_bars = 25, fence_planters = 40 },
  fence_posts = { Post_metal = 50 },
  window_groups =
  {
    barred = 30, barred_2 = 20, tall = 95, square = 20, grate = 40, supertall = 30,
    gtd_window_full_open = 70, gtd_window_full_open_tall = 65, gtd_window_bay = 30, gtd_window_low = 25,
    gtd_window_metal_frames = 70, gtd_window_construction_frames = 65, gtd_window_slump_tall = 65,
    gtd_window_absurdly_open = 20,
  },
  -- wall sets for rooms that don't get a Bricks room set (halls, lobbies of other themes)
  wall_groups =
  {
    torches9 = 6,   -- a burning barrel
    gtd_wall_urban_storage = 50, gtd_full_storage = 50, gtd_door_storage = 30, gtd_toilet_gallery = 15,
    gtd_drywall = 50, gtd_library = 15, gtd_DMV_set = 30, gtd_craneo_bank_set = 20, cran_bunkbeds = 30,
    gtd_generic_beamed_inset = 25, gtd_generic_beamed_brown_inset = 25,
    gtd_wall_high_gap_set = 25, gtd_wall_high_gap_alt_set = 25,
    gtd_generic_half_floor = 16, gtd_generic_half_floor_no_trim = 16,
    gtd_woodframe = 15, gtd_woodframe_alt = 15, gtd_wall_urban_cement_frame = 25,
    gtd_generic_ceilwall = 30, gtd_generic_ceilwall_2 = 30, gtd_generic_ceilwall_3 = 30,
    gtd_ind_modwall_1 = 20, gtd_ind_modwall_2 = 20, gtd_ind_modwall_3 = 20,
    gtd_greywall_1 = 25, gtd_greytall_trim = 25,
    gtd_wall_lamp_stubby = 7, gtd_wall_lamp_thin = 7, gtd_wall_lamp_thicc = 7,
    gtd_wall_lit_h_window_tall_gray = 25, gtd_wall_lit_h_window_tall_brown = 50,
  },

  -- most building areas get one of their room theme's room sets (make_cw_fabs.py)
  wall_group_prob = 85,
}

-- (Urban's wall_groups are replaced by a city list above; nothing to drop.)
NBC_BRICKS.drop_wall_groups = {}


------------------------------------------------------------------------
--  Environments
------------------------------------------------------------------------
--
-- Each environment is its own level theme, nbc_<env>: the shared overrides above, then the environment's
-- own (styles, halls, fences, facades...), its own room themes (picked from NBC_BRICKS.rooms by weight), a
-- prefab boost list, and its level titles. The theme "nbc_bricks" deals environments across the levels
-- (env_mix); "nbc_rooftops" and the rest build one environment.

-- building faces by kind of block (each building picks one; see Junction_calc_wall_tex below)
NBC_BRICKS.facade_sets =
{
  -- tenements and walk-ups: red and brown brick, stone with arched windows, the odd painted or grey one
  residential =
  {
    CWUDC = 30, CWUEE = 30, CWUQC = 30, CWUEC = 25, CWUGC = 25, CWUQB = 25, CWUQD = 20, CWUQF = 20,
    CWUDE = 20, CWUQE = 20, CWUEB = 15, CWUGE = 15, CWUHE = 15, CWUDB = 12, CWUED = 12, CWUEF = 10,
    CWUHC = 10, CWUHD = 10, CWUDD = 8, CWUGB = 8, CWUGD = 8, CWUHF = 8, ADBRICK = 15, AXCITY08 = 6,
  },
  -- the housing towers: concrete slabs and dark modern blocks, some brick
  towers =
  {
    CWUDB = 25, CWUED = 25, CWUEF = 25, CWUHC = 25, CWUHD = 25, CWUDA = 20, CWUDF = 20, CWUGA = 15,
    CWUGF = 15, CWUHA = 15, CWUHB = 15, CWUEA = 15, CWUDC = 10, CWUQC = 10, CWUGC = 10,
  },
  -- warehouses and works: corrugated sheet, block, concrete, old brick factories
  industrial =
  {
    AXW86 = 40, AXW87 = 30, CWCONCW = 30, ADCONC1 = 25, CWRETAIN = 20, AXW24 = 15, ADBRICK = 20,
    CWUHC = 12, CWUHD = 12, CWUDC = 12, AXW29 = 8,
  },
  -- what stands on a roof: stair huts, machine rooms, the next tower up
  rooftops =
  {
    CWCONCW = 30, ADBRICK = 30, ADCONC1 = 20, AXW24 = 20, AXW86 = 10,
    CWUDC = 10, CWUQB = 10, CWUHC = 10, CWUED = 10,
  },
  underground = { CWCONCW = 40, ADCONC1 = 30, CWSEAWAL = 30, CWRETAIN = 30, ADBRICK = 20 },
  subway = { CWTILEW = 40, CWCONCW = 30, CWRETAIN = 30, ADBRICK = 20 },
}

NBC_BRICKS.envs =
{
  streets =
  {
    label = "Streets", streets = true, facades = "residential",
    rooms = { Tenement = 100, Flat = 70, Derelict = 50, Concrete = 40, Lobby = 30, Outdoors_yard = 60,
              Cave_rubble = 50, deuce_Hallway = 50, metro_Hallway = 50 },
    titles = { "Street", "Avenue", "Row", "Block", "Alley", "Plaza", "Walk-ups" },
  },

  towers =
  {
    label = "Towers", facades = "towers",
    rooms = { Flat = 100, Tenement = 70, Derelict = 40, Lobby = 30, Concrete = 20, Outdoors_yard = 50,
              Cave_rubble = 50, deuce_Hallway = 60, metro_Hallway = 20 },
    overrides =
    {
      -- narrow halls are 1 seed wide (vent, access), wide ones 2 (deuce, metro, subway, sewers, pipeline)
      narrow_halls = { access = 40, vent = 30 },
      wide_halls = { deuce = 60, metro = 20 },
      style_list =
      {
        outdoors = { few = 70, some = 30 }, big_outdoor_rooms = { none = 60, few = 40 },
        hallways = { some = 50, heaps = 50 }, big_rooms = { none = 40, few = 60 },
        windows = { some = 30, heaps = 70 }, parks = { none = 80, few = 20 },
      },
    },
    titles = { "Towers", "Houses", "Projects", "Courts", "Heights", "Stacks" },
  },

  rooftops =
  {
    label = "Rooftops", facades = "rooftops",
    rooms = { Roof_top = 100, StairHut = 60, Concrete = 40, Tenement = 30, Cave_rubble = 50,
              metro_Hallway = 50, deuce_Hallway = 30 },
    overrides =
    {
      narrow_halls = { access = 50, vent = 50 },
      fence_groups = { PLAIN = 60, gappy = 40, fence_corrugated_steel = 30, fence_highway_bars = 30 },
      style_list =
      {
        outdoors = { heaps = 100 }, big_outdoor_rooms = { some = 50, heaps = 50 },
        hallways = { none = 40, few = 60 }, parks = { none = 100 }, porches = { heaps = 100 },
        fences = { some = 40, heaps = 60 }, windows = { few = 40, some = 60 },
        steepness = { some = 50, heaps = 50 }, big_rooms = { none = 70, few = 30 },
      },
    },
    fab_boost = { Decor_water_tower = 8, Decor_nbc_cw_ac_unit = 6, Decor_air_vent = 6, Pic_HVAC_unit_outdoor = 6 },
    titles = { "Rooftops", "Roofs", "Skyline", "Tar Beach", "Water Towers" },
  },

  industrial =
  {
    label = "Industrial Park", facades = "industrial",
    rooms = { Warehouse = 100, Factory = 60, Concrete = 40, Lobby = 10, Yard_industrial = 100, Cave_rubble = 50,
              metro_Hallway = 50, pipeline_Hallway = 40 },
    overrides =
    {
      narrow_halls = { access = 50, vent = 50 },
      wide_halls = { metro = 50, deuce = 30 },
      fence_groups = { fence_corrugated_steel = 80, fence_highway_bars = 50, gappy = 30, PLAIN = 20 },
      style_list =
      {
        outdoors = { some = 50, heaps = 50 }, big_outdoor_rooms = { some = 40, heaps = 60 },
        big_rooms = { some = 50, heaps = 50 }, hallways = { few = 70, some = 30 },
        parks = { none = 100 }, fences = { some = 40, heaps = 60 }, windows = { few = 50, some = 50 },
      },
    },
    fab_boost = { Decor_forklift = 4, Decor_road_clutter = 3, Crate_ = 3, Decor_nbc_cw_pallets = 3,
                  Pic_industrial_storage = 6, Decor_bunchy_pipe = 3 },
    fab_allow = { "Decor_forklift" },
    titles = { "Yards", "Works", "Industrial Park", "Depot", "Terminal", "Docks" },
  },

  parks =
  {
    label = "Parks", streets = true, facades = "residential",
    rooms = { Park = 100, Outdoors_yard = 40, Tenement = 50, Lobby = 30, Concrete = 20, Cave_rubble = 50,
              deuce_Hallway = 50, metro_Hallway = 30 },
    overrides =
    {
      fence_groups = { fence_park_bars = 60, fence_park_bars_round = 30, PLAIN = 30, fence_planters = 40, gappy = 20 },
      -- a run-down park keeps its trees (dead ones and stumps)
      trees = { burnt_tree = 30, brown_stub = 20, nbc_lamppost = 30 },
      park_decor = { nbc_lamppost = 40, burnt_tree = 20, brown_stub = 15, burning_barrel = 10 },
      style_list =
      {
        outdoors = { heaps = 100 }, big_outdoor_rooms = { some = 30, heaps = 70 },
        parks = { some = 40, heaps = 60 }, park_detail = { heaps = 100 }, hallways = { none = 50, few = 50 },
      },
    },
    entity_remap_drop = { "burnt_tree", "brown_stub" },
    fab_boost = { Decor_bench_n_trashcan = 6, Decor_basketball_hoop = 8, Decor_water_fountain = 6,
                  Decor_cafeteria_picnic_table = 6, Decor_round_planter = 3, Decor_urban_lightpost = 3 },
    titles = { "Park", "Playground", "Gardens", "Commons", "Green", "Square" },
  },

  underground =
  {
    label = "Underground", facades = "underground",
    rooms = { Basement = 100, Sewer = 50, Concrete = 50, Derelict = 30, Outdoors_yard = 20, Cave_rubble = 50,
              sewers_Hallway = 60, pipeline_Hallway = 40, metro_Hallway = 30 },
    overrides =
    {
      narrow_halls = { access = 50, vent = 50 },
      wide_halls = { sewers = 70, metro = 30 },
      liquids = { water = 100 },
      style_list =
      {
        outdoors = { none = 100 }, hallways = { some = 50, heaps = 50 }, liquids = { few = 60, some = 40 },
        windows = { none = 70, few = 30 }, big_rooms = { none = 30, few = 70 }, parks = { none = 100 },
        steepness = { few = 30, some = 70 },
      },
      wall_groups_add = { gtd_wall_sewer = 30, gtd_sewer_set_2 = 30, gtd_sewer_set_3 = 30 },
    },
    fab_boost = { Decor_gtd_sewer_3 = 5, Decor_open_pipe_sewer_group = 5, Decor_bunchy_pipe = 4,
                  Pic_industrial_sewer = 6 },
    titles = { "Basements", "Sewers", "Cellars", "Boiler Rooms", "Storm Drains" },
  },

  subway =
  {
    label = "Subway", facades = "subway",
    rooms = { Station = 100, Tunnel = 70, Concrete = 40, Basement = 20, Outdoors_yard = 30, Cave_rubble = 50,
              subway_Hallway = 60, metro_Hallway = 50 },
    overrides =
    {
      narrow_halls = { access = 50, vent = 50 },
      wide_halls = { subway = 60, metro = 40 },
      style_list =
      {
        outdoors = { none = 60, few = 40 }, hallways = { some = 40, heaps = 60 }, big_rooms = { few = 50, some = 50 },
        windows = { none = 60, few = 40 }, parks = { none = 100 }, liquids = { none = 100 },
      },
    },
    fab_boost = { Decor_gtd_DMV_double_bench = 6, Decor_gtd_DMV_multi_bench = 6,
                  Pic_industrial_cafeteria_vending_machines = 8, Decor_bench_n_trashcan = 3 },
    titles = { "Station", "Line", "Platforms", "Tunnels", "Junction" },
  },
}

-- how "nbc_bricks" deals environments across the levels: like a deck, so a set of eight levels has every
-- environment (streets twice) before any repeats; the deck is reshuffled when it runs out
NBC_BRICKS.env_deck = { "streets", "streets", "towers", "rooftops", "industrial", "parks", "underground", "subway" }

function NBC_BRICKS.is_nbc(name)
  return type(name) == "string" and string.sub(name, 1, 4) == "nbc_"
end

function NBC_BRICKS.env_of(theme_name)
  if not NBC_BRICKS.is_nbc(theme_name) then return nil end
  local key = string.sub(theme_name, 5)
  if key == "bricks" then key = "streets" end
  return NBC_BRICKS.envs[key], key
end


------------------------------------------------------------------------
--  Prefab filter: nothing Doom or hell flavoured on a Bricks level
------------------------------------------------------------------------

-- A prefab is switched off if its name (lower-cased) contains any of these.
-- ("dem_" is the prefab author Demios, not demons, so it isn't listed.)
NBC_BRICKS.fab_block_words =
{
  "hell", "skull", "gore", "blood", "demon", "satan", "penta", "cross", "gothic", "goth_",
  "candle", "altar", "church", "chapel", "corpse", "impale", "hanging", "flesh", "evil",
  "marbface", "lava", "nukage", "slime", "torture", "uac", "comput", "terminal", "teleport",
  "crystal", "obelisk", "monument", "grave", "casket", "coffin", "tomb", "crypt", "sacrif",
  "ritual", "writh", "gargoyle", "lion", "viney", "wolf", "nazi", "keen", "box_of_people",
  "shrine", "_eye", "baphomet", "sigil", "rune", "brain", "icon", "doom1", "tech",
  "cage", "penta", "bloodtubes", "rotten", "sky_penta", "spooky", "ruins", "sacrifice",
}

-- Structural prefabs (doors, exits, fences, halls, stairs...) are only
-- dropped for these overtly hellish words; the full list above applies to
-- decorative kinds. A prefab's kind is the folder it lives in.
NBC_BRICKS.fab_hell_words =
{
  "hell", "skull", "gore", "blood", "demon", "satan", "penta", "cross", "gothic", "goth_",
  "corpse", "impale", "flesh", "evil", "lava", "nukage", "slime", "torture", "marbface",
  "gargoyle", "crypt", "tomb", "altar", "candle", "wolf", "nazi",
}

-- Per kind: prefabs that read as sci-fi, gothic, castle, mine or gore in a city block, by name. These
-- apply to every kind listed, structural or not (the fallback in Fab_pick covers a slot left empty).
NBC_BRICKS.fab_kind_words =
{
  light      = { "tech", "sticks", "_red", "_blue", "quad_tight" },
  beam       = { "quakeish", "tech", "gothic" },
  fence      = { "tech", "gothic", "jurassic", "crenel", "silver" },
  post       = { "tech", "gothic" },
  pillar     = { "gothic", "tech" },
  window     = { "gothic", "cage", "octagon", "plut", "lite_cross", "arched", "quakeish", "hexagon", "arrowslit",
                 "bunker", "weabdows", "pencil" },
  hall       = { "mineshaft", "tech", "tek", "comp" },
  arch       = { "tech" },
  door       = { "tech" },
  terminator = { "mineshaft" },
  stairs     = { "techy", "teleporter", "fancy" },
  joiner     = { "tech", "quakeish", "cageish", "alternating_lights", "bombed" },
  exit       = { "nuke", "tech", "tp_closet" },
  start      = { "tech", "fireblu" },
  item       = { "confession", "oh_he_ded", "drown", "gameshow", "wallmachines", "tech", "cage", "pedestal" },
  decor      = { "crackofdoom", "gallows", "tentacle", "blob_lamp", "grimmoire", "infestation", "mogwaltz" },
  picture    = { "future", "big_faces" },
  wall       = { "infestation", "natural" },
  switch     = { "tech" },
  teleporter = { "" },        -- no teleporters in the Bricks
}

-- Texture fixes inside particular prefabs (tex_ fields override the prefab's own random picks):
--   * Urban's roll-up shutters draw their slats with a random Doom STEP texture, which the remap turns into a
--     concrete step riser (a grey block with a brown band): give them a corrugated shutter
--   * the fake street doors pick Doom's grey DOOR1/DOOR3: weathered wooden and steel doors instead
NBC_BRICKS.door_mix = { ADDOOR3 = 50, ADDOOR1 = 25, ADDOORS = 25 }
NBC_BRICKS.fab_fields =
{
  Wall_modern_shutter            = { tex_STEP4 = "AXW28" },
  Wall_modern_shutter_braceless  = { tex_STEP4 = "AXW28" },
  Item_closet_urban_fake_shutter = { tex_STEP4 = "AXW28" },
  Wall_fake_door                 = { tex_DOOR3 = NBC_BRICKS.door_mix },
  Wall_fake_door_braceless       = { tex_DOOR3 = NBC_BRICKS.door_mix },
  Item_closet_urban_fake_door    = { tex_DOOR3 = NBC_BRICKS.door_mix },
}

NBC_BRICKS.decor_kinds =
{
  decor = true, cage = true, picture = true, trap = true, wall = true,
  teleporter = true, misc = true, skybox = true,
}

local function has_word(name, words)
  local low = string.lower(name)
  for _, w in ipairs(words) do
    if string.find(low, w, 1, true) then return true end
  end
  return false
end

local function fab_is_blocked(name, def)
  if def.nbc_only then return false end   -- our own room sets
  local words = NBC_BRICKS.decor_kinds[def.kind or ""] and NBC_BRICKS.fab_block_words
                or NBC_BRICKS.fab_hell_words
  local kw = NBC_BRICKS.fab_kind_words[def.kind or ""]
  if kw and has_word(name, kw) then return true end
  return has_word(name, words) or (def.file and has_word(def.file, words))
end


------------------------------------------------------------------------
--  Texture remap: everything onto the Bricks set
------------------------------------------------------------------------

-- Explicit picks first, then name rules, then a default.
NBC_BRICKS.wall_swap =
{
  METAL = "AXW01", METAL1 = "AXW44", METAL2 = "AXW44", METAL3 = "AXW43C", METAL4 = "AXW43C",
  SUPPORT2 = "AXW30", SUPPORT3 = "AXW30", DOORTRAK = "ADMETL1", DOORSTOP = "ADMETL1",
  CRATE1 = "AXB10", CRATE2 = "AXB03", CRATE3 = "AXB14", CRATINY = "AXB09", CRATWIDE = "AXB04",
  CRATELIT = "AXB12", CRATLITE = "AXB12",
  STARTAN1 = "CWWALL1", STARTAN2 = "CWWALL1", STARTAN3 = "CWWALL2", STARG1 = "CWWALL2", STARG2 = "CWWALL2",
  STARG3 = "CWWALL2", STARGR1 = "CWWALL1", STARGR2 = "CWWALL1", STARBR2 = "AXCITY08",
  -- Obsidian's facade and storefront prefabs use these as window glass and shop screens
  BRWINDOW = "ADGLASSB", PANBOOK = "CWWOOD1",
  MODWALL3 = "ADGLASSB", MODWALL4 = "ADGLASSB", COMPBLUE = "ADGLASSB", COMPBLU2 = "ADGLASSB",
  SHAWN1 = "AXW28", SHAWN2 = "AXW28", SHAWN3 = "AXW28", SILVER1 = "AXW72", BROWN96 = "AXW87",
  BLAKWAL1 = "CWWALLD", BLAKWAL2 = "CWWALLD", ICKWALL1 = "AXW23", ICKWALL3 = "AXW23",
  BROWN1 = "AXW85", BROWN96 = "AXW85", BROWNGRN = "AXW85", BROWNHUG = "AXW85", REDWALL = "AXW85",
  BIGBRIK1 = "ADBRICK", BIGBRIK2 = "AXW85", BIGBRIK3 = "AXW84",
  MARBGRAY = "AXCITY08", MARBLE1 = "ADMARBL", MARBLE2 = "ADMARBL", MARBLE3 = "ADMARBL",
  -- full-height door art (the CWDOOR* set has plaster over the door, which turns short doors into white boxes)
  DOOR1 = "ADDOORT", DOOR3 = "ADDOORS", BIGDOOR1 = "CWDOORWL", BIGDOOR2 = "CWDOORWL",
  BIGDOOR3 = "CWDOORWL", BIGDOOR4 = "CWDOORWL", BIGDOOR5 = "ADDOOR2", BIGDOOR6 = "ADDOOR3",
  BIGDOOR7 = "ADDOOR3", SPCDOOR1 = "ADDOORS", SPCDOOR2 = "ADDOORS", SPCDOOR3 = "ADDOORS", EXITDOOR = "CWFIRED",
  EXITSIGN = "ADEXIT", EXITSTON = "ADEXIT",
  -- key-door trims keep their colour: red and blue painted sheet, yellow hazard stripes
  DOORRED = "AXB21B", DOORBLU = "AXB27", DOORYEL = "AXW56",
  DOORRED2 = "AXB21B", DOORBLU2 = "AXB27", DOORYEL2 = "AXW56",
}

-- {lua pattern, replacement}, tried in order on the upper-case name
NBC_BRICKS.wall_rules =
{
  { "^SW[12]", "AXW38" },
  { "CRAT", "AXB03" },
  { "^MID", "CWFENCE" }, { "BRNSMAL", "CWFENCE" }, { "BRNBIG", "CWFENCE" },
  { "EXIT", "ADEXIT" },
  { "DOOR", "ADDOOR3" },
  { "BRIK", "AXW85" }, { "BRICK", "ADBRICK" },
  { "WOOD", "CWWOOD1" }, { "CRAT", "CWWOOD1" }, { "PLANK", "CWWOOD1" },
  { "STEP", "AXSTEP23" }, { "STAIR", "AXSTEP23" },
  -- hell, gore, gothic, natural rock: grimy concrete
  { "SKULL", "AXW23" }, { "SKIN", "AXW25" }, { "SK", "AXW23" }, { "FIRE", "AXW23" },
  { "BLOD", "AXW23" }, { "BLOOD", "AXW23" }, { "LAVA", "AXW23" }, { "GST", "AXW14" },
  { "MARBFAC", "ADMARBL" }, { "MARB", "AXCITY08" }, { "SP_", "AXW23" }, { "ZZ", "AXW23" },
  { "ZIMMER", "AXW23" }, { "SLOP", "AXW23" }, { "CRACK", "AXW23" }, { "FLESH", "AXW23" },
  { "HELL", "AXW23" }, { "NUKE", "AXW43C" }, { "ROCK", "CWCONCW" }, { "ASH", "AXW23" },
  { "ICK", "AXW23" }, { "VINE", "AXW25" }, { "SATYR", "AXW14" }, { "LION", "AXW14" },
  { "GARG", "AXW14" }, { "FACE", "AXW14" }, { "WOLF", "ADGREY2" }, { "ZELDOOR", "ADDOOR3" },
  -- techbase: industrial panels and metal
  { "COMP", "AXW89" }, { "TEK", "AXW89" }, { "SPACE", "AXW43C" }, { "SHAWN", "AXW28" },
  { "PANCASE", "AXW89" }, { "PANEL", "AXDW06A" }, { "^PAN", "AXDW06A" },
  { "FALL", "CWWALLD" }, { "NUKAGE", "AXW43C" }, { "SLAD", "AXW23" }, { "POIS", "AXW23" }, { "DBRAIN", "AXW23" }, { "LITE", "CWWALLD" }, { "PIPE", "AXW43C" },
  { "SILVER", "AXW72" }, { "METAL", "AXW01" }, { "SUPPORT", "AXW30" }, { "PLAT", "AXW01" },
  -- plain walls
  { "CEMENT", "ADCONC1" }, { "CONC", "ADCONC1" }, { "BSTONE", "CWCONCW" }, { "STONE", "CWCONCW" },
  { "GRAY", "CWWALLD" }, { "GREY", "CWWALLD" }, { "STAR", "CWWALL1" }, { "STUCCO", "AXCITY08" },
  { "MODWALL", "CWWALL2" }, { "BROWN", "AXW85" }, { "TAN", "AXCITY09" }, { "BRONZE", "AXW87" },
  { "BLAK", "CWWALLD" }, { "CEIL", "CWWALLD" },
}
NBC_BRICKS.wall_default = "ADCONC1"

NBC_BRICKS.flat_swap =
{
  FLOOR7_1 = "CWCONCF", CEIL5_1 = "CWCEILD", CEIL5_2 = "CWCEILD",
  FLAT1 = "AXF03", FLAT4 = "AXF01", FLAT19 = "AXF02", FLAT20 = "CWCONCF", FLAT23 = "AXF02",
  FLOOR0_1 = "AXHF07A", FLOOR0_2 = "AXHF07A", FLOOR0_3 = "AXHW07A", FLOOR4_8 = "AXF39",
}

NBC_BRICKS.flat_rules =
{
  { "WATER", "FWATER1" },
  { "NUKAGE", "CWCONCF" }, { "SLIME", "CWCONCF" }, { "LAVA", "CWCONCF" }, { "BLOOD", "CWCONCF" },
  { "TLITE", "ADCLITE" }, { "LITE", "ADCLITE" }, { "CEIL1_2", "ADCLITE" }, { "CEIL1_3", "ADCLITE" },
  { "CEIL", "CWCEILD" },
  { "STEP", "CWSTAIF" },
  { "GRASS", "AXF06B" }, { "DIRT", "AXF06B" }, { "RROCK", "CWCONCF" }, { "ROCK", "CWCONCF" },
  { "SAND", "AXF06B" }, { "MFLR", "AXF05" }, { "ASH", "AXF05" },
  { "WOOD", "ADFWOOD" }, { "CRATOP", "ADFWOOD" },
  { "GATE", "CWCONCF" }, { "TELE", "CWCONCF" },
  { "FLAT5", "AXF39" }, { "FLOOR5", "AXF39B" }, { "FLOOR", "AXF02" }, { "FLAT", "AXF02" },
}
NBC_BRICKS.flat_default = "CWCONCF"

local function remap(name, swap, rules, default)
  if not name or name == "" or name == "-" then return name end
  if string.sub(name, 1, 1) == "_" then return name end          -- Obsidian placeholders
  local up = string.upper(name)
  if up == "F_SKY1" or string.match(up, "^SKY") then return name end
  if up == "O_INVIST" then return name end                         -- Obsidian's invisible barrier (export_maps.py ships it)
  if NBC_BRICKS.MATERIALS[up] then return name end               -- already ours
  if swap[up] then return swap[up] end
  for _, r in ipairs(rules) do
    if string.find(up, r[1]) then return r[2] end
  end
  NBC_BRICKS.misses = NBC_BRICKS.misses or {}
  NBC_BRICKS.misses[up] = default
  return default
end

function NBC_BRICKS.remap_wall(name)
  return remap(name, NBC_BRICKS.wall_swap, NBC_BRICKS.wall_rules, NBC_BRICKS.wall_default)
end

function NBC_BRICKS.remap_flat(name)
  return remap(name, NBC_BRICKS.flat_swap, NBC_BRICKS.flat_rules, NBC_BRICKS.flat_default)
end


------------------------------------------------------------------------
--  Hooks
------------------------------------------------------------------------

NBC_BRICKS.entities =
{
  nbc_brick     = { id = 26000, r = 8,  h = 8,   pass = true },
  nbc_halfbrick = { id = 26001, r = 8,  h = 8,   pass = true },
  nbc_concrete  = { id = 26002, r = 8,  h = 8,   pass = true },
  nbc_bottle    = { id = 26003, r = 6,  h = 12,  pass = true },
  nbc_rubble    = { id = 26004, r = 24, h = 16,  pass = true },
  nbc_lamppost  = { id = 26233, r = 12, h = 128, light = 255 },
}

function NBC_BRICKS.setup(self)
  local urban = GAME.THEMES["urban"]
  if not urban then return end

  -- New Bricks City things the theme places (nbc/MAPINFO.txt, nbc/mapinfo/cw_props.txt)
  for name, ent in pairs(NBC_BRICKS.entities) do
    if not GAME.ENTITIES[name] then GAME.ENTITIES[name] = table.copy(ent) end
  end

  -- the shared base: a deep copy of Urban with our overrides
  local base = table.deep_copy(urban)
  for k, v in pairs(NBC_BRICKS.theme_overrides) do
    base[k] = table.deep_copy(v)
  end
  base.prefab_remap = nil   -- Urban's remaps point at Doom textures; the remap below does the job
  base.post_mat = "AXW85"   -- corner posts otherwise default to METAL

  -- one level theme per environment; nbc_bricks is the streets theme (levels left on it get dealt one)
  for key, E in pairs(NBC_BRICKS.envs) do
    local T = table.deep_copy(base)
    for k, v in pairs(E.overrides or {}) do
      if k == "style_list" then
        for sk, sv in pairs(v) do T.style_list[sk] = table.deep_copy(sv) end
      elseif k == "wall_groups_add" then
        for wk, wv in pairs(v) do T.wall_groups[wk] = wv end
      else
        T[k] = table.deep_copy(v)
      end
    end
    for _, name in ipairs(E.entity_remap_drop or {}) do T.entity_remap[name] = nil end
    T.facades = table.deep_copy(NBC_BRICKS.facade_sets[E.facades or "residential"])
    T.nbc_env = key
    GAME.THEMES["nbc_" .. key] = T
    if key == "streets" then GAME.THEMES["nbc_bricks"] = table.deep_copy(T) end
  end

  -- Obsidian reads the error/default fill (METAL, FLAT5_1) before begin_level,
  -- so set it here when this build is a Bricks build.
  if NBC_BRICKS.is_nbc(OB_CONFIG.theme) then
    GAME.MATERIALS["_ERROR"] = { t = "AXW85", f = "CWCONCF" }
    GAME.MATERIALS["_DEFAULT"] = { t = "ADCONC1", f = "AXF02" }
  end

  -- room themes: copy the Urban base, replace the textures; each environment gets its own list
  local function add_room(theme_name, name, prob)
    local def = NBC_BRICKS.rooms[name]
    if not def then error("New Bricks City: no room theme " .. name) end
    local basedef = GAME.ROOM_THEMES[def.base]
    local R = basedef and table.deep_copy(basedef) or {}
    for k, v in pairs(def) do
      if k ~= "base" then R[k] = table.deep_copy(v) end
    end
    R.prob = prob
    GAME.ROOM_THEMES[theme_name .. "_" .. name] = R
  end
  for key, E in pairs(NBC_BRICKS.envs) do
    for name, prob in pairs(E.rooms) do
      add_room("nbc_" .. key, name, prob)
      if key == "streets" then add_room("nbc_bricks", name, prob) end
    end
  end
end


-- Obsidian picks prefabs by exact theme name. Bricks levels count as Urban
-- there, so the street grammar's props and the urban prefabs stay available
-- (Obsidian does the same for its Deimos and Thy Flesh themes).
if ob_match_level_theme and not NBC_BRICKS.orig_match then
  NBC_BRICKS.orig_match = ob_match_level_theme

  ob_match_level_theme = function(LEVEL, T, override)
    if not override and LEVEL and NBC_BRICKS.is_nbc(LEVEL.theme_name) then
      -- the environment's own picks are allowed whatever theme they were made for
      local E = NBC_BRICKS.env_of(LEVEL.theme_name)
      if E and E.fab_allow and T and T.name then
        for _, pat in ipairs(E.fab_allow) do
          if string.find(T.name, pat, 1, true) then return true end
        end
      end
      override = "urban"
    end
    return NBC_BRICKS.orig_match(LEVEL, T, override)
  end
end


-- Materials made on the fly (for names not in GAME.MATERIALS) bypass the
-- table swap, so the lookups are wrapped too.
local function wrap_lookup(fname)
  local orig = _G[fname]
  if not orig or NBC_BRICKS["orig_" .. fname] then return end
  NBC_BRICKS["orig_" .. fname] = orig

  _G[fname] = function(LEVEL, name, ...)
    local mat = orig(LEVEL, name, ...)
    if NBC_BRICKS.active and mat then
      local t = mat.t and NBC_BRICKS.remap_wall(mat.t)
      local f = mat.f and NBC_BRICKS.remap_flat(mat.f)
      if t ~= mat.t or f ~= mat.f then
        local new = table.copy(mat)
        new.t, new.f = t, f
        return new
      end
    end
    return mat
  end
end
wrap_lookup("Mat_lookup_tex")
wrap_lookup("Mat_lookup_flat")


function NBC_BRICKS.get_levels_after_themes(self)
  -- "nbc_bricks" levels each get an environment (not the same one twice running); Streets Mode for the
  -- environments that have streets
  local last, deck = nil, {}
  for _, LEV in ipairs(GAME.levels) do
    if NBC_BRICKS.is_nbc(LEV.theme_name) and not LEV.prebuilt then
      if LEV.theme_name == "nbc_bricks" then
        if #deck == 0 then
          deck = table.copy(NBC_BRICKS.env_deck)
          rand.shuffle(deck)
          if deck[1] == last and #deck > 1 then deck[1], deck[#deck] = deck[#deck], deck[1] end
        end
        local key = table.remove(deck, 1)
        LEV.theme_name = "nbc_" .. key
        LEV.theme = GAME.THEMES[LEV.theme_name]
        gui.printf("New Bricks City: %s is %s\n", LEV.name, NBC_BRICKS.envs[key].label)
      end
      local E, key = NBC_BRICKS.env_of(LEV.theme_name)
      last = key
      LEV.nbc_env = key
      LEV.has_streets = (E and E.streets) or nil
      LEV.is_nature = false
    end
  end
end


function NBC_BRICKS.begin_level(self, LEVEL)
  -- the Corpo Wars room sets place New Bricks City things: Bricks levels only
  local bricks = LEVEL and NBC_BRICKS.is_nbc(LEVEL.theme_name)
  for _, def in pairs(PREFABS) do
    if def.nbc_only then
      if def.nbc_prob == nil then def.nbc_prob = def.use_prob or 0 end
      def.use_prob = bricks and def.nbc_prob or 0
    end
  end
  if not bricks then return end
  NBC_BRICKS.active = true

  -- 1. every material onto the Bricks set (kept to restore at end_level)
  NBC_BRICKS.saved_mats = {}
  for name, mat in pairs(GAME.MATERIALS) do
    local t = mat.t and NBC_BRICKS.remap_wall(mat.t)
    local f = mat.f and NBC_BRICKS.remap_flat(mat.f)
    if t ~= mat.t or f ~= mat.f then
      NBC_BRICKS.saved_mats[name] = mat
      local new = table.copy(mat)
      new.t, new.f = t, f
      GAME.MATERIALS[name] = new
    end
  end

  -- 2. switch off Doom and hell prefabs (Fab_pick below puts a kind back
  --    if a required slot would otherwise have nothing to choose from)
  NBC_BRICKS.saved_fab_probs = {}
  NBC_BRICKS.blocked_by_kind = {}
  local count = 0
  for name, def in pairs(PREFABS) do
    if def.use_prob and def.use_prob > 0 and fab_is_blocked(name, def) then
      NBC_BRICKS.saved_fab_probs[name] = def.use_prob
      local k = def.kind or "?"
      NBC_BRICKS.blocked_by_kind[k] = NBC_BRICKS.blocked_by_kind[k] or {}
      table.insert(NBC_BRICKS.blocked_by_kind[k], name)
      def.use_prob = 0
      count = count + 1
    end
  end
  gui.printf("New Bricks City: %d Doom/hell prefabs switched off\n", count)

  -- 3. this environment's prefabs come up more often (name substrings, multipliers; put back at end_level)
  NBC_BRICKS.saved_boosts = {}
  local E = NBC_BRICKS.env_of(LEVEL.theme_name)
  for pat, mult in pairs((E and E.fab_boost) or {}) do
    for name, def in pairs(PREFABS) do
      if def.use_prob and def.use_prob > 0 and string.find(name, pat, 1, true) then
        if NBC_BRICKS.saved_boosts[name] == nil then NBC_BRICKS.saved_boosts[name] = def.use_prob end
        def.use_prob = def.use_prob * mult
      end
    end
  end

  -- 4. per-prefab texture fixes (tex_ fields; put back at end_level)
  NBC_BRICKS.saved_fab_fields = {}
  for name, fields in pairs(NBC_BRICKS.fab_fields) do
    local def = PREFABS[name]
    if def then
      NBC_BRICKS.saved_fab_fields[name] = {}
      for k, v in pairs(fields) do
        NBC_BRICKS.saved_fab_fields[name][k] = def[k] or false
        def[k] = v
      end
    end
  end
  NBC_BRICKS.cars = 0
end


-- Never fail a level over the filter: if a required prefab slot finds
-- nothing, restore that kind's blocked prefabs and ask again.
if Fab_pick and not NBC_BRICKS.orig_fab_pick then
  NBC_BRICKS.orig_fab_pick = Fab_pick

  Fab_pick = function(LEVEL, reqs, allow_none)
    if not NBC_BRICKS.active or allow_none then
      return NBC_BRICKS.orig_fab_pick(LEVEL, reqs, allow_none)
    end

    local res = NBC_BRICKS.orig_fab_pick(LEVEL, reqs, true)
    if res ~= nil then return res end

    -- a hallway group short of dead-end pieces (subway, sewers): cap it with a metro, access or vent one
    if reqs and reqs.kind == "terminator" and reqs.group then
      local group = reqs.group
      for _, g in ipairs({ "metro", "access", "vent" }) do
        reqs.group = g
        res = NBC_BRICKS.orig_fab_pick(LEVEL, reqs, true)
        if res then
          gui.printf("New Bricks City: %s hallway capped with a %s terminator\n", group, g)
          return res
        end
      end
      reqs.group = group
    end

    -- this one slot only: let the blocked prefabs of its kind back in, pick, block them again
    local list = reqs and NBC_BRICKS.blocked_by_kind and NBC_BRICKS.blocked_by_kind[reqs.kind]
    if list then
      gui.printf("New Bricks City: no clean '%s' prefab fits here, allowing a blocked one\n", tostring(reqs.kind))
      for _, name in ipairs(list) do
        if PREFABS[name] and NBC_BRICKS.saved_fab_probs[name] then
          PREFABS[name].use_prob = NBC_BRICKS.saved_fab_probs[name]
        end
      end
    end
    res = NBC_BRICKS.orig_fab_pick(LEVEL, reqs, allow_none)
    if list then
      for _, name in ipairs(list) do
        if PREFABS[name] then PREFABS[name].use_prob = 0 end
      end
      if res and res.name then gui.printf("New Bricks City: fallback %s:%s\n", tostring(reqs.kind), res.name) end
    end
    return res
  end
end


-- Room sets: Obsidian hands every building room the same mix of wall groups
-- from all its themes (quest.lua). A Bricks room uses its own room theme's
-- list instead, so a Flat's areas become living rooms, kitchens and
-- bedrooms, and a Derelict floor becomes squats, cook labs and grow rooms.
if Layout_decorate_rooms and not NBC_BRICKS.orig_decorate_rooms then
  NBC_BRICKS.orig_decorate_rooms = Layout_decorate_rooms

  Layout_decorate_rooms = function(LEVEL, pass, ...)
    if NBC_BRICKS.active and pass == 1 then
      local sets = 0
      for _, R in pairs(LEVEL.rooms or {}) do
        if R.theme and R.theme.wall_groups and R:get_env() == "building" then
          R.forced_wall_groups = R.theme.wall_groups
          sets = sets + 1
        end
      end
      gui.printf("New Bricks City: %d rooms use the Corpo Wars room sets\n", sets)
    end
    return NBC_BRICKS.orig_decorate_rooms(LEVEL, pass, ...)
  end
end


-- Night in the Bricks: the streets under the sky are dimmer than the lit rooms inside. Obsidian picks the
-- sky light (176-240, times the lighting multiplier) before any module hook, so it's set here instead.
NBC_BRICKS.sky_light = { 160, 176, 176, 192 }
NBC_BRICKS.sky_light_dark = 144

if Level_choose_darkness and not NBC_BRICKS.orig_choose_darkness then
  NBC_BRICKS.orig_choose_darkness = Level_choose_darkness

  Level_choose_darkness = function(LEVEL, ...)
    local res = NBC_BRICKS.orig_choose_darkness(LEVEL, ...)
    if LEVEL and NBC_BRICKS.is_nbc(LEVEL.theme_name) then
      LEVEL.sky_light = LEVEL.is_dark and NBC_BRICKS.sky_light_dark or rand.pick(NBC_BRICKS.sky_light)
      LEVEL.sky_shadow = 24
    end
    return res
  end
end


-- One facade per building. Obsidian gives each zone two facades (and a level has one to three zones), so a
-- whole level shares two or three building faces. On a Bricks level every building (room) facing the outside
-- picks its own from the environment's facade set, so a street is a row of different buildings.
if Junction_calc_wall_tex and not NBC_BRICKS.orig_wall_tex then
  NBC_BRICKS.orig_wall_tex = Junction_calc_wall_tex

  Junction_calc_wall_tex = function(A1, A2)
    local mat = NBC_BRICKS.orig_wall_tex(A1, A2)
    if not NBC_BRICKS.active or type(A1) ~= "table" or type(A2) ~= "table" then return mat end
    if not A1.is_outdoor or not A1.zone or not A2.is_indoor or not A2:is_indoor() then return mat end
    if mat ~= A1.zone.facade_mat and mat ~= A1.zone.other_facade and mat ~= A2.facade_crap then return mat end
    local R = A2.room
    if not R or R.is_outdoor or not THEME or not THEME.facades then return mat end
    if not R.nbc_facade then R.nbc_facade = rand.key_by_probs(THEME.facades) end
    return R.nbc_facade
  end
end


------------------------------------------------------------------------
--  Voxel cars instead of prefab cars
------------------------------------------------------------------------

-- New Bricks City's parked cars (Voxel Vehicles Pack, nbc/actors/cw/vehicles.txt).
NBC_BRICKS.car_ids =
{
  -- sedans, wagons, modern cars, hatchbacks, vans, pickups, SUVs, taxis
  street = {
    10600,10601,10602,10603,10604,10605,10606,10625,10626,10627,
    10616,10617,10618,10619,10620,10621,10622,10623,10624,
    10631,10632,10633,10634,10635,10636,10637,10638,10639,10640,
    10641,10642,10643,10644,10646,10647,10648,10649,
    10650,10651,10652,10653,10654,10655,10656,10657,10658,10659,
    10661,10662,10663,10664,10665,10666,10667,10668,10669,10670,
    10753,10754,10755,10756,10757,10758,10759,10760,10761, 10613,10628,
  },
  -- parked cop cars, limos, an ambulance, sports cars
  rare = { 10614, 10629, 10749, 10750, 10751, 10728, 10739, 10741, 10745 },
  -- dirty and brown ones stand in for the wrecks
  dirty = { 10606, 10621, 10627, 10636, 10646, 10655, 10659, 10666, 10670, 10758, 10761 },
  dozer = { 10695, 10703, 10705, 10707 },
  tractor = { 10716, 10719, 10721, 10723 },
  truck = { 10730, 10732, 10734, 10737 },
  forklift = { 10694, 10696, 10697, 10698, 10701 },
}

-- prefab name pattern -> pool (false = drop the prefab)
NBC_BRICKS.car_fabs =
{
  { "sedan", "street" }, { "hatchback", "street" }, { "minitruck", "street" }, { "minibus", "street" },
  { "dozer", "dozer" }, { "tractor", "tractor" }, { "dump_truck", "truck" }, { "forklift", "forklift" },
  { "Decor_apc", false },
}

-- Added to the prefab's spot rotation to get the car's angle.
NBC_BRICKS.car_angle_offset = 0

local function car_pool(name)
  for _, r in ipairs(NBC_BRICKS.car_fabs) do
    if string.find(name, r[1], 1, true) then
      if not r[2] then return false end
      if r[2] == "street" then
        if string.find(name, "broken", 1, true) then return "dirty" end
        if rand.odds(10) then return "rare" end
      end
      return r[2]
    end
  end
  return nil
end

-- A car prefab on a Bricks level becomes one voxel-car thing at the same
-- spot and rotation; everything else is built as usual.
if Fabricate and not NBC_BRICKS.orig_fabricate then
  NBC_BRICKS.orig_fabricate = Fabricate

  Fabricate = function(LEVEL, room, def, T, skins)
    if NBC_BRICKS.active and def and def.name then
      -- tally for the log (end_level): which prefabs this level used, by kind
      local key = (def.kind or "?") .. ":" .. def.name
      NBC_BRICKS.used = NBC_BRICKS.used or {}
      NBC_BRICKS.used[key] = (NBC_BRICKS.used[key] or 0) + 1
    end
    if NBC_BRICKS.active and def and def.name and T and T.add_x then
      local pool = car_pool(def.name)
      if pool == false then return end
      if pool then
        local angle = ((T.rotate or 0) + NBC_BRICKS.car_angle_offset) % 360
        raw_add_entity({ id = rand.pick(NBC_BRICKS.car_ids[pool]), x = T.add_x, y = T.add_y,
                         z = T.add_z or 0, angle = angle })
        NBC_BRICKS.cars = (NBC_BRICKS.cars or 0) + 1
        return
      end
    end
    return NBC_BRICKS.orig_fabricate(LEVEL, room, def, T, skins)
  end
end


------------------------------------------------------------------------
--  Level titles: Bricks street and block names
------------------------------------------------------------------------

NBC_BRICKS.title_a = { "Fulton", "Marlow", "Kessler", "Halsey", "Cypress", "Union", "Delancey", "Mercer",
  "Garnet", "Bishop", "Lowell", "Carver", "Rankin", "Juniper", "Wexford", "Calloway", "Dumont", "Pike",
  "Arden", "Holloway", "Lenox", "Sutter", "Orchard", "Vance" }
NBC_BRICKS.title_b = { "Courts", "Towers", "Houses", "Block", "Avenue", "Street", "Projects", "Yards",
  "Terrace", "Walk-ups", "Row", "Plaza", "Gardens", "Heights", "Stacks", "Alley" }

function NBC_BRICKS.title_for(i, env)
  local seed = math.floor(tonumber(OB_CONFIG.seed) or 0)
  local list = (NBC_BRICKS.envs[env or ""] or {}).titles or NBC_BRICKS.title_b
  local a = NBC_BRICKS.title_a[(i * 7 + seed) % #NBC_BRICKS.title_a + 1]
  local b = list[(i * 5 + math.floor(seed / 7)) % #list + 1]
  return a .. " " .. b
end

-- A night-time city skyline (CITYSKY, 1024 x 256, in nbc/textures/cw/)
-- instead of Doom's skies. Map entries only, so the mod's own MAPINFO
-- (gameinfo, hub maps) is left alone when both are loaded.
NBC_BRICKS.sky = "CITYSKY"

function NBC_BRICKS.all_done(self)
  local levels = {}
  for _, L in ipairs(GAME.levels) do
    if NBC_BRICKS.is_nbc(L.theme_name) then table.insert(levels, L) end
  end
  if #levels == 0 then return end

  local lines = { "// Written by the New Bricks City Obsidian addon\n\n" }
  for i, L in ipairs(levels) do
    local title = NBC_BRICKS.title_for(i, L.nbc_env)
    -- the environment, for export_maps.py (district pool) and the game
    table.insert(lines, string.format("// nbc_env %s %s\n", L.name, L.nbc_env or "streets"))
    table.insert(lines, string.format("map %s \"%s\"\n{\n", L.name, title))
    table.insert(lines, string.format("  sky1 = \"%s\", 0\n", NBC_BRICKS.sky))
    if levels[i + 1] then
      table.insert(lines, string.format("  next = \"%s\"\n", levels[i + 1].name))
    end
    table.insert(lines, "}\n\n")
  end
  gui.wad_add_text_lump("ZMAPINFO", lines)
end


function NBC_BRICKS.end_level(self, LEVEL)
  if NBC_BRICKS.active then
    gui.printf("New Bricks City: %d voxel cars parked\n", NBC_BRICKS.cars or 0)
    -- every prefab the level used, for checking builds (inspect the log)
    local keys = {}
    for k, _ in pairs(NBC_BRICKS.used or {}) do table.insert(keys, k) end
    table.sort(keys)
    for _, k in ipairs(keys) do gui.printf("NBC prefab %s x%d\n", k, NBC_BRICKS.used[k]) end
    -- texture names no rule caught (they got the default)
    for k, v in pairs(NBC_BRICKS.misses or {}) do gui.printf("NBC default %s -> %s\n", k, v) end
  end
  NBC_BRICKS.used = nil
  NBC_BRICKS.active = false

  if NBC_BRICKS.saved_mats then
    for name, mat in pairs(NBC_BRICKS.saved_mats) do
      GAME.MATERIALS[name] = mat
    end
    NBC_BRICKS.saved_mats = nil
  end

  for name, prob in pairs(NBC_BRICKS.saved_boosts or {}) do
    if PREFABS[name] then PREFABS[name].use_prob = prob end
  end
  NBC_BRICKS.saved_boosts = nil

  if NBC_BRICKS.saved_fab_probs then
    for name, prob in pairs(NBC_BRICKS.saved_fab_probs) do
      if PREFABS[name] then PREFABS[name].use_prob = prob end
    end
    NBC_BRICKS.saved_fab_probs = nil
  end
  NBC_BRICKS.blocked_by_kind = nil

  for name, fields in pairs(NBC_BRICKS.saved_fab_fields or {}) do
    for k, v in pairs(fields) do
      if PREFABS[name] then PREFABS[name][k] = v or nil end
    end
  end
  NBC_BRICKS.saved_fab_fields = nil
end


OB_THEMES["nbc_bricks"] =
{
  label = _("New Bricks City"),
  game = "doom2",
  priority = 29,
  name_class = "URBAN",
  mixed_prob = 0,
}

-- one environment for every level
do
  local order = { "streets", "towers", "rooftops", "industrial", "parks", "underground", "subway" }
  for i, key in ipairs(order) do
    OB_THEMES["nbc_" .. key] =
    {
      label = _("New Bricks City: " .. NBC_BRICKS.envs[key].label),
      game = "doom2",
      priority = 28.9 - i * 0.01,
      name_class = "URBAN",
      mixed_prob = 0,
    }
  end
end


-- Picking the theme in the GUI is enough: if "New Bricks City" is the theme,
-- this module joins the build even when its checkbox is off (otherwise the
-- theme doesn't exist and Obsidian stops with "Unknown theme : nbc_bricks").
if ob_sort_modules and not NBC_BRICKS.orig_sort_modules then
  NBC_BRICKS.orig_sort_modules = ob_sort_modules

  ob_sort_modules = function(...)
    local mod = OB_MODULES["new_bricks_city"]
    if mod and OB_CONFIG and NBC_BRICKS.is_nbc(OB_CONFIG.theme) then
      mod.enabled = true
      mod.shown = true
    end
    return NBC_BRICKS.orig_sort_modules(...)
  end
end


OB_MODULES["new_bricks_city"] =
{
  name = "new_bricks_city",
  label = _("New Bricks City Theme"),
  game = "doom2",
  where = "misc",

  tables =
  {
    NBC_BRICKS
  },

  hooks =
  {
    setup = NBC_BRICKS.setup,
    get_levels_after_themes = NBC_BRICKS.get_levels_after_themes,
    begin_level = NBC_BRICKS.begin_level,
    end_level = NBC_BRICKS.end_level,
    all_done = NBC_BRICKS.all_done,
  },
}
