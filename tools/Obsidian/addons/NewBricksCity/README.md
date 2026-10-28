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

## Environments
Every environment is its own Obsidian level theme with its own room themes, styles, hallways, fences, facades,
prefab boosts and level titles (`NBC_BRICKS.envs`):

| theme | what it builds |
|---|---|
| `nbc_streets` | city blocks in Streets Mode: tenements, flats, shops, yards |
| `nbc_towers` | inside the housing towers: flats along wide corridors, lobbies, few outdoors; concrete-slab facades |
| `nbc_rooftops` | open tar-and-gravel roofs, stair huts, parapet fences, water towers, AC units and vents |
| `nbc_industrial` | warehouses in corrugated sheet, factories, big yards, forklifts, crates, corrugated fences |
| `nbc_parks` | parks with lawns, park railings, benches, a basketball court, fountains, picnic tables, dead trees |
| `nbc_underground` | basements and boiler rooms, sewers and storm drains, sewer halls, no outdoors, low light |
| `nbc_subway` | white-tiled stations, track tunnels (rails on the floor), subway and metro halls, waiting benches |

`nbc_bricks` (the default) deals them across the levels like a deck: eight levels get every environment, streets
twice, before any repeats. `--theme nbc_rooftops` (`-Theme` in PowerShell) builds just one. Every map gets
Obsidian's 3D city skybox (`zdoom_skybox = themed`), so the skyline stands round the edges.

**Facades per building.** Obsidian gives each zone two facades, so a whole level had two or three building faces.
Now every building facing the outside picks its own from the environment's set (`facade_sets`): 30 lit-window
facades in red and brown brick, tan stone with arched windows, grey stone, concrete slabs and dark modern
blocks, plus corrugated sheet and block for the industrial park.

**The district pool.** `export_maps.py` writes each map's environment as the third column of
`nbc/districts.txt` (`NBC_CT01 "Pike Water Towers" rooftops`). `--limit 8` exports the first eight maps of a
longer build: `make_bricks.sh --length episode --limit 8`.

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
- **City pieces only** (2026-10-28): Urban's groups are replaced by city lists: fences (plain, gappy,
  corrugated steel, highway bars, planters), metal fence posts, plain/lit/wood/textured beams, vent and access
  halls (no mineshafts), and windows (barred, tall, square, grates, open, bay, metal and construction frames,
  no gothic, caged, octagon or arched ones). Per kind, prefabs whose names read as tech, gothic, castle, mine or
  gore are switched off (`fab_kind_words`): tech lights, gallows, the crack of doom, tentacle pillars, blob lamps,
  the confession booth, the portable-nuke exit, teleporters. If a slot has no clean prefab, one blocked prefab is
  let back in for that slot only, and the log says which (`New Bricks City: fallback ...`).
- **No teleporters, no rock parks**: the build turns off Obsidian's emergency teleporters, and natural (rock-walled)
  parks are off in the theme's style list.
- **Night lighting**: the sky light over the streets is 160-192 (144 on a dark level); rooms keep Obsidian's
  levels times 1.1, so lit interiors stand out from the streets. (1.3 used to push nearly everything to 255.)
- **Debris and lamps**: floor decor is the quick-throw's loose bricks, half-bricks, concrete and bottles
  (26000-26003) with the odd bloodstain; outdoor lights are the mod's lamp posts (26233).
- **Prefab texture fixes** (`fab_fields`): roll-up shutters get a corrugated shutter instead of a step riser, and
  fake street doors get weathered wooden and steel doors.
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
The build log lists every prefab each level used (`NBC prefab <kind>:<name> x<count>`) and every Doom texture
that no remap rule caught (`NBC default <name> -> <texture>`): grep them to spot anything out of place.

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
