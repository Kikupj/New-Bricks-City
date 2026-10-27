# New Bricks City theme for Obsidian (Doom 2)

City blocks for New Bricks City: streets with sidewalks and parked voxel cars, brick tenements
with rows of windows, courtyards, plaster flats, concrete stairwells, a night city skyline.

## Build
```powershell
powershell -File tools\Obsidian\make_bricks.ps1                         # 4 maps -> nbc\maps\NBC_CT01-04.wad
powershell -File tools\Obsidian\make_bricks.ps1 -Name test -Length single -Seed 42
powershell -File tools\Obsidian\make_bricks.ps1 -NoExport               # keep the build in out\ only
```
The script starts from Obsidian's `CONFIG.txt`, sets `theme = nbc_bricks`, enables this addon,
switches off modules that bring their own textures (Armaetus epic textures, sky generator,
compression) and raises the lighting. The build lands in `tools\Obsidian\out\bricks.wad`, then
`export_maps.py` splits it into the mod:
- `nbc\maps\NBC_CT01.wad`, `NBC_CT02.wad` ... one map each; a new build replaces the previous set
- `nbc\mapinfo\city_maps.txt`: titles, city sky, next-map chain (included from `nbc\MAPINFO.txt`)
- `nbc\textures\obsidian\O_INVIST`: Obsidian's invisible-barrier texture, if a map uses it

In the GUI just pick the **New Bricks City** theme; its module switches itself on.

## Play
```powershell
.\uzdoom.exe -iwad freedoom-0.13.0\freedoom2.wad -file nbc +map NBC_CT01
```

## What the addon does (`modules/new_bricks_city.lua`)
- **Theme `nbc_bricks`**: a copy of Obsidian's Urban theme with Bricks facades, fences, asphalt
  streets with a paving-slab kerb, trash fires and lamps, a street-crew monster mix, and a style
  list for city blocks (no caves, liquids, teleporters, cages, parks or scenic vistas; low
  steepness). Its room themes (Tenement, Flat, Derelict, Concrete, Lobby, halls, yards) copy
  Urban's and swap the textures.
- **Streets Mode** is forced on for every Bricks level.
- **No Doom or hell content**:
  - every texture is mapped onto the New Bricks City / Corpo Wars set (`nbc/textures/cw/`);
    office metal and grey panels are steered toward brick, plaster and grime
  - about 1,100 hellish, gothic, gore and techbase prefabs are switched off per level (decorative
    kinds by a wide word list, structural kinds only for overtly hellish names); if a required
    slot would be left with nothing, that kind's prefabs come back for that slot rather than
    failing the level
  - hell decorations and Freedoom's leafy trees become lamps, trash fires or nothing
- **Voxel cars**: Obsidian's car prefabs (sedans, hatchbacks, minitrucks, minibuses, and their
  wrecks) become one parked voxel car each, at the same spot and angle, from the mod's Voxel
  Vehicles Pack: sedans, wagons, vans, pickups, SUVs, taxis, now and then a parked police car,
  limo or ambulance; wrecks use the dirty colours. Road-works prefabs become voxel bulldozers,
  tractors, semis and forklifts; the APC is dropped.
- **Furnished rooms (Corpo Wars room sets)**: each building area gets a room set from its room
  theme's `wall_groups` list. Tenements and flats become living rooms, kitchens, bedrooms and
  bathrooms; derelict floors become squats, gang dens, cook labs and grow rooms; concrete floors
  become boiler rooms, laundries, storerooms, workshops and garages; ground floors become lobbies,
  offices, bodegas and bars. A set's wall prefabs stand Corpo Wars furniture along the walls,
  facing the room. Its decor prefabs are free-standing groups: a coffee table between armchairs,
  a bar table with stools, a grow bed pair. Posters, radiators, breaker boxes and floor clutter
  are picked at random per prefab. Squats, dens, storerooms and streets get loose bricks,
  half-bricks, concrete and bottles for the quick-throw, and rubble piles. Outdoors there are
  dumpsters, pallets, police barricades, sandbags, market stalls and barrel fires. These prefabs
  only appear on Bricks levels.
- **Sky and titles**: every map gets `CITYSKY` (the night skyline) and a Bricks street name
  ("Mercer Street", "Wexford Row" ...).
- Prefabs see Bricks levels as Urban (as Obsidian does for Deimos and Thy Flesh), so street props
  and urban decor stay available.

## Room sets (`games/doom/fabs/{wall,decor}/nbc_cw_*`)
Generated, don't edit them by hand. Change the recipes in `tools\Obsidian\make_cw_fabs.py`
(`GROUPS`, `OUTDOOR`, `INDOOR`, and the random `POOLS`), then:
```powershell
python tools\Obsidian\make_cw_fabs.py
powershell -File tools\Obsidian\make_bricks.ps1
```
The props are map things from `nbc/mapinfo/cw_props.txt` (furniture 26200+, decor sprites 26400+),
which `tools\import\port_cw_props.py` writes. Prefab things 26960-26999 are placeholders that Obsidian
swaps for a random poster, sign or bit of clutter; none reach a map. To give a room theme different
sets, edit its `wall_groups` in the module. `wall_group_prob` (85) is how often an area gets one.

## Check a build
`python tools\Obsidian\inspect_udmf.py tools\Obsidian\out\bricks.wad` prints how much texturing
comes from `nbc/textures` per map and writes a top-down PNG per map next to the WAD.
`powershell -File tools\smoke_test.ps1 -Map NBC_CT01` checks a map boots cleanly.

## Known limits
- The layout is Obsidian's grammar: streets are long outdoor rooms between buildings, not a strict
  city grid.
- Voxel cars are solid only in their middle (a voxel-pack limitation), so you can clip their ends.
- `car_angle_offset` in the module turns every car, if a car is ever found across a road.
- Furniture is made of model things, not map geometry. Obsidian keeps its monster and item spots
  32 units clear of each piece. The furniture's collision comes from Corpo Wars' blockers in-game.
- Room sets fill 1- and 2-seed wall runs. Longer runs, corners and stairs get Obsidian's plain walls.
