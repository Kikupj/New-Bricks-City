# New Bricks City — Status

Codex: read this first, then `AGENTS.md`, then the milestone you were given in `PLAN.md`. Update this file at the end of every milestone.

**Current milestone: M2d** (back to Obsidian: finish the New Bricks City theme, PLAN.md §4.4). Obsidian builds in the cloud now; next are putting raids back on the Obsidian districts and swapping the Doom prefabs and textures still left. The kits (M2b/M2c) are kept as test maps only. **Then: M3** (the case and raid loop).

## Done

### M2d — Back to Obsidian — 🔧 IN PROGRESS (2026-10-28, by Claude)
- **Owner decision:** Obsidian is the level base again; finish the `nbc_bricks` theme rather than the kits.
- **Obsidian in the cloud:** a console-only source build of Obsidian 20 from github.com/obsidian-level-maker/Obsidian (`/home/user/obsidian-src`, build steps at the top of `tools/Obsidian/make_bricks.sh`). `tools/Obsidian/make_bricks.sh` is the Linux twin of `make_bricks.ps1` (same overrides; starts from `tools/Obsidian/CONFIG.txt` if present, else Obsidian's defaults). The addon loads unchanged on Obsidian 20: a single level builds in about 4 s, all wall textures and 99% of flats from `nbc/textures`.
- **Viewing builds:** load the build WAD after `nbc` and `+map MAP01`. Under xvfb, **use the GL renderer** (`+vid_rendermode 4`): the software renderer crashed (signal 11) a few seconds into an Obsidian map.
- **Seen in a first build (seed 42 and an unseeded one):** streets with brick facades and lit windows, voxel cars, Corpo Wars room sets. Doom leftovers still visible: marble-and-wood wall panels with torch sconces, a red Doom-style door, techbase computer columns, grey techbase halls.
- **Theme pass (2026-10-28):** audited 24 levels (which prefabs each level used, which textures every map uses, screenshots) and fixed what read as Doom:
  - textures: ADSCONC (a marble wall with a lit torch sconce) was the fallback for every stair, step, stone and default wall, which made the torch-lined marble halls; ADMETL3 (a sci-fi blue light panel) stood in for every support and silver texture; AXW84 is square flagstones, not brick, yet faced whole streets; Obsidian's dark window glass (MODWALL3/4) came out as blank white plaster. All remapped to concrete, step risers, steel, trusses, dark glass, corrugated shutters, crates and full-height doors; key-door trims keep their red, blue and yellow.
  - prefabs: city-only fence, post, beam, hall and window groups; per-kind name blocks (tech, gothic, castle, mine, gore); teleporters and rock parks off; the "allow blocked prefabs" fallback now covers one slot, not the rest of the level.
  - light: the 1.3 multiplier put nearly every sector at 255 (no shading). Now night streets at 160-192 and rooms at Obsidian's levels times 1.1.
  - decor: loose bricks, bottles and concrete instead of blood pools; the mod's lamp posts outside; corrugated roll-up shutters and weathered street doors.
  - a fresh district set was exported (seed 2026): NBC_CT01 "Pike Projects", NBC_CT02 "Fulton Plaza", NBC_CT03 "Mercer Courts", NBC_CT04 "Wexford Street". `check_lumps` 0 new problems; the smoke test passes on NBC_CT01-04, NBC_TEST and NBC_HUB.
- **Environments and facades (2026-10-28):** the theme is now seven Obsidian level themes: streets, towers, rooftops, industrial park, parks, underground (basements and sewers) and subway, each with its own room themes, styles, hallway groups, fences, facades, prefab boosts and titles. `nbc_bricks` deals them across a build. Buildings each pick a facade from their environment's set (30 lit-window facades plus sheet and block) instead of two per zone. Obsidian's 3D city skybox is on. Two Obsidian quirks handled: the 2-seed hallway groups (deuce, metro, subway, sewers) must be `wide_halls`, and a hallway group short of a dead-end piece is capped with a metro, access or vent one. 35 single-environment builds (5 seeds each) built without errors.
  - New district set (seed 2026, `--length episode --limit 8`): NBC_CT01 "Pike Water Towers" (rooftops), NBC_CT02 "Fulton Storm Drains" (underground), NBC_CT03 "Mercer Terminal" (industrial), NBC_CT04 "Wexford Junction" (subway), NBC_CT05 "Sutter Walk-ups" (streets), NBC_CT06 "Cypress Playground" (parks), NBC_CT07 "Carver Towers" (towers), NBC_CT08 "Arden Street" (streets). `nbc/districts.txt` carries each map's environment as a third column for the raid work (the game reads the first two).
- **Last kit work (committed before the switch, `3819f07`):** sliding panel doors, a street-plan generator on an even grid, roomier towers, low roof huts, animated canal water, and `nbc_kitsweep N` (regenerate a test floor N times, one summary line each).


### M0 — Repo, toolchain and asset import (2026-10-26, by Claude)
- A git repo with `.gitignore`. (Since committed: M0/M0b, M1–M1c and M2 each have a commit.)
- `nbc/` is loadable with `-file nbc` and holds:

  | From | Where in `nbc/` |
  |---|---|
  | DeePayback Enemies (`DeePaybackEnemies/`) | `actors/enemies/`, `sprites/enemies/`, `sounds/enemies/`, plus SNDINFO entries |
  | 10 weapon packs, active (`Weapons/*.zip`): AK47, Colt45, CombatKnife, DualBerettas, FistsOfFury, Flashlight, Machete, MicroUzi, Molotov, PumpActionShotgun | DECORATE in `actors/weapons/<pack>/`; Flashlight and MicroUzi ZScript in `zscript/imported/`; sprites and sounds in `sprites/` and `sounds/weapons/<pack>/`; brightmaps in `brightmaps/` and `graphics/brightmaps/` |
  | FragGrenade | only its sprites and sounds are loaded (for the M1c debris throw); its code is in `reference/weapons/fraggrenade/` |
  | Debris art (made earlier with pxl) | `sprites/debris/` |

- Root lumps:
  - `DECORATE` (#includes)
  - `ZSCRIPT.zs` (`version "4.10"`)
  - `SNDINFO.txt` and `GLDEFS.txt` (merged, one section per source)
  - `TEXTURES.molotov.txt`
  - `GAMEINFO.txt` (title "NEW BRICKS CITY")
  - `MAPINFO.txt` (NBC_TEST)
  - `CREDITS.txt` (every source)
- Not loaded: each pack's INFO, OLDCODE and OLDGLDEFS files, the Machete's KEYCONF (it would fight our slots) and the Molotov's `altsprites/` are in `reference/weapons/<pack>/`.
- The import cleaned up two things:
  - 9 duplicate enemy voice files (TPAIN1–9, byte-identical copies in two folders): kept one copy.
  - The Civilians2 file `PEM7A2A8 (2).PNG`: renamed to `PEM7A2A8.PNG`. It's the only copy of that frame.
- **The test map** `NBC_TEST` (`tools/make_test_map.py`) is a brick room with a pillar. It has a player start, 5 vanilla monsters (the enemy pack turns them into humans) and a parked voxel car.
- **Tools:**
  - `check_lumps.py` (+ `lumps_allow.txt`)
  - `smoke_test.ps1`
  - `run.ps1`
  - `list_textures.py`
  - `extract_wad.py`
  - `build_pk3.py`
  - `make_test_map.py`
  - the one-time import scripts in `tools/import/` (don't re-run them)

### M0b — Corpo Wars import (2026-10-26, by Claude)
- `reference/corpowars/`: Corpo Wars' full source, read-only and never loaded. It has the ZScript tree, every definition lump, `Design Docs/`, CREDITS, README, CHANGELOG, LICENSE-UEAI, the Civilians2 DECORATE and the vehicle-pack readme.
- `docs/corpowars-port-map.md`: per system, its files and the outside classes it uses. **The code is tangled**: the kits alone use 13 outside classes, including the contract, ledger, guard and objective classes. Each milestone ports one system.
- Loaded in `nbc/`, unused until wired:
  - `textures/cw/` (438 textures)
  - `sprites/cw/` (decor, signs, cityskyline, breach, gadgets)
  - `models/props/` (71 OBJ files)
  - `brightmaps/city/`
  - `sounds/cw/breach/` (with `cw/breach/*` in SNDINFO)
  - `sprites/civilians/` (Civilians2, minus its PGIB gibs, which duplicate the enemy pack's)
- **Active:** voxel cars (`voxels/`, `actors/cw/vehicles.txt`, DoomEdNums 10600–10803). One is placed in NBC_TEST.
- Kit templates `maps/NBC_K1.wad`, `NBC_K2.wad` and `NBC_K4.wad` (from K01, K02 and K04, with the header lump renamed). Not wired yet: loading one before M2 shows Corpo Wars thing numbers as unknown.
- `tools/cw/`: Corpo Wars' Python tools (genmap.py, citydist.py, texlib.py, make_models.py, qa/ …).
- **Not taken, on purpose:** no weapons, weapon sprites, weapon sounds or item icons (the roster is `Weapons/` only); no Corpo Wars guard sprites (the enemy pack has them).

### M1 — Integration, player class and loot remap — ✅ DONE (2026-10-27)
- Added `NBC_Player` as the only player class, with the M1 weapon slots and starting FistsOfFury, Colt45 and 24 light-ammo rounds.
- Added a direct F-key flashlight toggle and the default R reload binding; the flashlight is no longer loaded as a weapon. Did not merge the Machete pack's KEYCONF.
- Added shared `NBC_LightAmmo` and `NBC_RifleAmmo` reserve pickups using existing Doom pickup sprites. Colt45, Dual92, MicroUzi, PumpActionShotgun and AK47 use the M1 reserve scheme; the Uzi-specific reserve classes were retired. Molotovs remain capped at 5.
- Added `NBC_Loot.CheckReplacement` mappings for vanilla weapon and ammo pickups/drops, including nested `Thuggundropper` drops. Removed Molotov editor number 25013.
- Added the requested ~8% Molotov drop chance to the tier-1 enemy archetypes used by the existing human choice spawners. The katana-wielding Ninja2 drops a Machete.
- Removed the specop, MiltiaShotgun and sniper ally base classes from the enemy choice lists. `eWOLFSpawner` retains only terrorist choices.
- **Scope note:** no M1b reload framework, M1c debris throw or M2 maps were added. The weapon pack's existing Dual92 magazine/reload behavior remains until M1b ports it.

### M1b — Reloading for every firearm — ✅ DONE (2026-10-27)
- Added the shared `NBC_ReloadWeapon` base and separate persistent magazines: Colt45 8, Dual92 30, PumpActionShotgun 6, MicroUzi 32, AK47 30. Each uses its M1 shared reserve type.
- Ported the five active firearms to `NBC_Colt45`, `NBC_Dual92`, `NBC_PumpShotgun`, `NBC_MicroUzi` and `NBC_AK47` ZScript subclasses. Their original DECORATE files remain in the tree but are no longer loaded; the imported MicroUzi ZScript is also no longer included.
- Added R/manual and empty-magazine auto-reload flows, dry-click behavior, full-magazine rejection, reload speed and magazine-size player multipliers, cancellation on weapon switch, and late reserve transfer. The shotgun commits one shell at a time and yields to fire input.
- Used the Dual92's pack reload frames/sounds and the shotgun's unused XSTR frames/XMDB sounds. Colt/Uzi/AK use the in-engine dip; the AK uses the enemy pack's e30COCK rack sound.
- Added magazine/reserve HUD text, low-ammo colors, an empty-magazine `RELOAD` prompt and the `nbc_debug_weapon` console alias. Added `NBC_Light`, `NBC_Shell`, and `NBC_Rifle` firearm puff damage types and standardized existing fists/knife/machete puffs to `Melee`. Molotov remains `Fire`; debris damage is deferred to M1c because that attack does not exist yet.
- Starting light reserve remains 24 rounds: the Colt's 6-round pickup reserve grant is accounted for by starting with 18 reserve rounds. Weapon pickups grant a full magazine plus a small shared-reserve bonus.
- **Scope note:** no M1c debris, ally reload behavior, or later milestone systems were added.
- **Next milestone:** M1c — quick-throw bricks and debris.

### M1c — Quick-throw bricks and debris — ✅ DONE (2026-10-27)
- Added the persistent `NBC_DebrisSatchel` with separate brick, half-brick, concrete and bottle counts, a player-read carry cap of 3, and H cycling across carried types. Added loose pickups and a finite Use-operated rubble pile; the pile yields 3–6 pieces, about half half-bricks, changes appearance as it empties and remains as a nonblocking spent pile.
- Added G press/release netevents and the hidden `NBC_QuickThrow` capability marker. A separate overlay uses the finished brick hand, Molotov bottle hand and HGT2 follow-through frames; charge steps 10→30 speed over 12 steps. It suppresses fire/reload, lowers the active weapon, redirects an active M1b reload to Ready before its commit point, and restores the weapon after the throw or safely cancels on weapon switching.
- Added four non-explosive `Blunt` projectiles: brick (18 damage, one bounce, 30% reusable), half-brick (12, two bounces), concrete (26, no bounce, enemy knockback and two non-pickup half-brick fragments), and bottle (8, light long arc and 768-unit noise hook). All use `+FORCEPAIN` and reject friendly/player damage. The arrest-stagger and `NBC_DebrisNoise` hooks are stubs for M9.
- Added the debris HUD readout, prefixed sound aliases, map thing registrations 26000–26004, and focused pickups/rubble fixtures in NBC_TEST. No finished art or read-only source assets were edited.
- **Scope note:** debris-only named random stream is used for reuse and rubble supply until the later run-state RNG exists. M2 and later systems were not started.
- **Next milestone:** M2 — The Bricks level generator and placeholder hub.

### M2 — Obsidian districts, the hub and the vertical slice — ✅ SLICE PLAYABLE (2026-10-27, by Claude)
- **Course change:** levels come from Obsidian (PLAN.md M2 rewritten). `tools/Obsidian/make_bricks.ps1` builds the pool; `export_maps.py` writes `nbc/maps/NBC_CT01…04`, `nbc/mapinfo/city_maps.txt` (every district exits to NBC_HUB) and `nbc/districts.txt` (the pool the raid board reads).
- **Obsidian:** the GUI's saved `steepness/outdoors/hallways = none` overrode the theme (earlier builds were flat). The build now hands those back to the theme: steepness some/heaps (split levels, stairs, lifts), taller rooms, more porches, **parks** (grass and dirt ground, benches, picnic tables, lamp posts, a dumped mattress, rubble), no traps, and a light monster layer (`float_mons 0.6`).
- **Enemy count is the game's:** `NBC_RunManager` removes Obsidian's monsters at map start and refills those spots with the raiding gang: 22/18/16 base by tier × gang budget × (1 + 0.15 × alert), nobody within 768 of the start, plus one reinforcement wave of up to 6 out of sight once 60% are down. Seen: 16–24 crew per district.
- **New code** (`nbc/zscript/nbc/`): `gangs.zs` (reads `nbc/gangs.txt`, resolves the pack's choice spawners with the case RNG, `NBC_GangProfile` damage factors, `NBC_LeaderToken`), `rundata.zs` (`NBC_RunData`: seed and xorshift RNG, day, strikes, cash, gangs, districts, squad, the results card), `ally.zs` (`NBC_Ally`: own targeting, hitscan `NBC_Light` bursts, 24-round reloads, follow, catch-up teleport, immune to player, squad and fire), `runmanager.zs` (raid setup, leader nearest the exit with escorts, officers spawning, enemies switching to officers, Officer Down, results, `nbc_board` and `nbc_debug_case` netevents), `hub.zs` (raid board, armory, the board menu). `NBC_Player.DamageMobj`: officers never hurt you; a lethal hit on a raid is OFFICER DOWN.
- **Data:** `nbc/gangs.txt` (Stoop Kings, Rust Saints, Iron Pit, Collectors), `nbc/CVARINFO.txt` (`nbc_seed`). **Maps:** `NBC_HUB` (Checkpoint 9, `tools/make_hub_map.py`) is the New Game start map. Things 26010 raid board, 26011 armory.
- **HUD:** the raid readout is top left (district, gang, the leader's distance and compass direction, crew left, squad health, day, strikes, cash). The magazine and debris readouts moved from the top centre to the bottom right. The big font is Miniplicity (`nbc/BIGFONT.lmp`, credited); the mod's own small text uses UZDoom's NewSmallFont.
- **Loop verified by a scripted run:** new case → raid → retreat (alert +1, day 2); new case → kill the leader → exit (TOPPLED, bounty) → next raid → lethal hit (OFFICER DOWN, strike 1, half the cash lost, back at the hub, day 3). The same seed gives the same assignments.

### M2c — The Bricks kit layouts, from scratch — ✅ BUILT, NEEDS PLAYTEST (2026-10-27, by Claude)
- **Owner's call:** the Corpo Wars layouts weren't up to standard and covered settings the Bricks doesn't need. The ported layouts (`kit_street/residential/underground.zs`) and template maps (`NBC_K1/K2/K4`) are deleted. Only M2b's carving engine stays.
- **Four new kits**, written for New Bricks City (`nbc/zscript/nbc/kit_tower.zs`, `kit_street.zs`, `kit_basement.zs`, `kit_roof.zs`) on new template grids built by `tools/make_kit_maps.py` (`NBC_KT`, `NBC_KS`, `NBC_KB`, `NBC_KR`). 17 variants in all, listed in PLAN.md §6.7.
- **Real scale, measured from the actors:** people are 56 units (sprites 54–60 px), so 1 m ≈ 31 units up and ≈ 37 across. Ceilings 80 (2.5 m), doors 68 x 48, corridors 80, rails 36 and blocking. The door art is squeezed onto the opening; the Corpo Wars door-frame models are no longer placed. The earlier "orange outline" was the old door texture (CWDOOR1's own frame), not a model fault.
- **Engine changes (`kitgen.zs`):** kit registry for the four kits; `EdgeWall` (flats' outer walls are windows onto the night city, `CWWINDO`, or boarded with `CWPLANK`); `BandWall` (towers with lit windows across the road); `FenceH` and blocking rails over drops; posts where fences meet are fence posts (no more thin brick columns standing out of a courtyard wall); outdoor spaces that touch without a link get a fence; two spawn spots per cell where there's room.
- **The street is two-sided** (owner's call): buildings meet the sidewalk on both sides of the road and all of them are part of the level: shops with back rooms, walk-ups, closed buildings, plus **alleyways** cutting between buildings to the alley behind, and **parking lots** (a low fence along the sidewalk with a drive-in gap, open to the alley). The south lots back onto the canal walk, with the canal right beyond it. 135–170 spawn spots per street.
- **Gangs** now hold these kits (`gangs.txt` `mansion`): Stoop Kings gang floor, gallery floor, corner stores, roof camp; Rust Saints chop lot, parking garage, burned-out floor, cook lab; Iron Pit fight pit, service basement; Collectors penthouse, tower entrance.
- **The world past the edges (owner's feedback on the street maps):** the painted tower walls at the map borders are gone. `tools/make_kit_maps.py` now builds scenery into the street, tower and roof templates: a canal (water 112 below the ground, concrete embankments) along the road and the cross street, a high retaining wall closing off the east, a continuous row of low buildings (4–10 m, brick, lit flats, warehouse walls) along the canal's far bank so the ground plane never shows from the street, a gravel/asphalt ground plane, and 66 tower blocks as real raised rectangles at three distances (lit-window and glass-tower facades, varied heights and light), so the city has parallax. The world ends in a sealed ring with a sky ceiling (sky hack), so the horizon is sky. The Wall in the street is now a free-standing 8 m concrete wall (`SolidTop` in the engine), not a slab to the sky. Seen from the roof and the tower's gallery, the same blocks stand 768 below: some tops below you, some far above.
- **Test tools:** `netevent nbc_goto <x> <y> <angle>` puts the player anywhere (for screenshots and checks); `nbc_kittest <kit 1-4> <variant> <seed>`.

### M2b — Our own level architecture: the Bricks kits — ✅ BOOTS, NEEDS PLAYTEST (2026-10-27, by Claude)
- **Ported** Corpo Wars' site-kit generator and three kits into `nbc/zscript/cw/` as `NBC_KitGen`, `NBC_KitStreet` (K1), `NBC_KitResidential` (K2) and `NBC_KitUnderground` (K4). Renamed to `NBC_` because the mission layer is cut: no CW guards, patrol points, bystanders, drop crate, ledger, passes or contract objectives. `procgen.zs`, `stairs.zs` and `themes.zs` turned out not to be needed by these kits and weren't ported. The already-ported furniture, kitprops and decor classes are reused.
- **What the kit gives the raid instead:** spawn spots (one per reachable cell, outdoor cells marked as perches for M4), `NBC_ResidentSpot` markers in civilian rooms (empty until M9), `NBC_ObjectiveMarker`s in the planned objective rooms, rubble piles (against walls, so corridors stay passable) and loose debris in rooms flagged `RF_RUBBLE`, and an exit: the entry farthest from the insertion, with `NBC_KitExit` (Use to leave) under a lit exit sign.
- **Rebuilt for the Bricks:** doors 96 high; tower-floor ceilings raised to 112–144 (PLAN.md §4.4 scale); the "hacker den" is a gang den with a stash room; 1 in 4 flats on poor floors is a dark squat full of rubble; fire escapes, roofs, yards, alleys, tunnels and camps carry debris; parked cars are the Bricks' (dirty colours, a dead squad car). Street interiors keep their heights (the street facade line is 128).
- **New code** (`nbc/zscript/nbc/kits.zs`): `NBC_KitRunner` (generates on load, never on a loaded save; inserts the player on the first tic; `nbc_kittest`, `nbc_debug_kit`), `NBC_KitDoor` (Use opens; officers waiting at a door open it; shuts after 4 s when clear), `NBC_CeilingLight` (+ pendant, strip, downlight), `NBC_LightSource`, `NBC_KitExit`, `NBC_ExitSign`, the two markers.
- **The slice runs on kits now.** `nbc/districts.txt` lists 4 turfs (no maps). Each gang's kit floors are a new `mansion` field in `nbc/gangs.txt` (Stoop Kings: tenement, gang den, rooftops; Rust Saints: chop shop, parking garage; Iron Pit: parking garage, tunnels; Collectors: luxury apartments, gambling den). The board picks one with the case RNG and a layout seed (`NBC_RunData.raidMap/raidVariant/raidKitSeed`). The RunManager fills the kit's spawn spots and puts the leader nearest the kit's exit. A raid is still one floor; M3 adds approach → staging flat → floors.
- **Registered:** maps `NBC_K1/K2/K4` in MAPINFO (city sky, next = hub), `NBC_KitRunner` in `AddEventHandlers` (before the RunManager), CVars `nbc_kitseed` / `nbc_kitvariant`, `SNDSEQ.txt` (`NBCDoorSilent`), MODELDEF entries for the four light fixtures and the exit sign (existing `models/props/*.obj`), KEYCONF aliases `nbc_kittest` and `nbc_debug_kit`.
- **Obsidian is frozen:** NBC_CT01–04 are out of the raid pool but still load (`+map NBC_CT01`), with their own monsters and no raid.
- **Owner feedback round 2 (2026-10-27):**
  - Street doors (outdoor to indoor) are open archways now, so no door art slides up the building face. Indoor doors open to the lower ceiling; their art is pinned to the ceiling and squeezed onto the shut opening, and on the taller side the gap over an open door shows the room's wall (`NBC_KitDoor` transoms).
  - Outdoor exits put the exit sign on a barricade behind the exit instead of floating in the air; indoors it hangs just under the ceiling.
  - Open outdoor edges show what stops you: chain-link (`CWFENCE`) on the street and tower, a rail (`CWRAIL2`) on the roof (`EdgeRail` hook). The Wall now closes the north end of the cross street too.
  - The canal is rebuilt: a quay ledge, seawalls (`CWSEAWAL`), a road bridge with railings carrying the cross street over it, lamp posts and lights on the far bank. The east retaining wall uses `CWRETAIN`. `make_kit_maps.py` now splits T-junctions and writes things.
  - The far-bank buildings are 3-6 storeys, and window facades are scaled to 0.4 (a storey is 80 units next to a 56-unit person), the towers too.
  - Street clutter: bins, benches, planters, pallets, crates, scrap, dumpsters and scaffolds along the sidewalks; wrecks, barriers and scrap on the road; loose debris on the sidewalks.
  - Lighting: outdoor light levels raised (road 120, sidewalk 128, alley 104, lots 112-120), lamp radius 320, lamps the length of the cross street, fill lights down the road.
- **Not done yet (later milestones):** time of day and weather (M7c), elevated highway set pieces, perch spawns for snipers (M4), residents (M9), objectives on the markers (M4/M9).

### Side work — Obsidian city maps and Corpo Wars room sets (2026-10-27, by Claude; not a milestone)
- `tools/Obsidian/` builds city-block maps with a New Bricks City theme (`addons/NewBricksCity/`, see its README): `powershell -File tools\Obsidian\make_bricks.ps1` writes `nbc/maps/NBC_CT01-04.wad` plus `nbc/mapinfo/city_maps.txt`.
- **Corpo Wars props are now placeable map things.** `tools/import/port_cw_props.py` copied `furniture.zs`, `kitprops.zs` and four decor sets into `nbc/zscript/cw/` (one `// NBC:` change: `CWD_Wall` lifts itself to wall height when placed on the floor), the matching models into `nbc/MODELDEF.txt`, and DoomEdNums into `nbc/mapinfo/cw_props.txt`: furniture 26200–26258, decor sprites 26400–26600. **M2 should reuse these classes, not port them again.**
- `tools/Obsidian/make_cw_fabs.py` remakes Corpo Wars' room recipes (kit_*.zs `Dress()`) as Obsidian prefabs: 18 room sets (living, kitchen, bedroom, bath, office, storage, utility, laundry, workshop, garage, lockers, lab, grow, den, camp, lobby, shop, bar) with furniture along the walls, free-standing groups, random wall sprites and clutter, and loose debris (26000–26004) in squats, dens, storage and on the street. Each Bricks room theme picks from its own list of room sets.

## Verified
- **M2c on Windows (owner, 2026-10-27):** `powershell -File tools\smoke_test.ps1 -Map NBC_TEST,NBC_HUB,NBC_KT,NBC_KS,NBC_KB,NBC_KR` → PASS on all six, two runs.
- **M2c checks (2026-10-27, cloud session, UZDoom 5.0.3 built from source on Linux):**
  - `python tools/check_lumps.py` → `0 new problem(s), 13 known`.
  - `tools/smoke_test.sh NBC_TEST NBC_HUB NBC_KT NBC_KS NBC_KB NBC_KR` → PASS on all six.
  - Every variant of every kit generated with `+developer 1`: no script errors, no unreachable rooms, objectives placed. Spawn spots per floor: tower 18–49, street 84–96, basement 155–168, roof 98–105.
  - Screenshots (software renderer) of the tower corridor, lift lobby, gang floor and gallery; the street's sidewalk, storefronts, courtyard and under the el; the fight hall and garage; the rooftop crossing. A summoned gang member checks the scale: doors just over head height, ceilings a hand above that.
  - A full raid from the hub (`nbc_seed 1234`): new case, raid turf 0 → the Stoop Kings on a gallery floor, 29 crew + the leader + 2 officers, exit found.
- **M2b checks (2026-10-27, cloud session, UZDoom 5.0.3 built from source on Linux):**
  - `python tools/check_lumps.py` → `0 new problem(s), 13 known` (Freedoom 0.13.0's `freedoom2.wad` from the Ubuntu archive).
  - `tools/smoke_test.sh NBC_TEST NBC_HUB NBC_K1 NBC_K2 NBC_K4` → PASS on all five (software renderer under xvfb; no script errors, no warnings).
  - With `+developer 1` each kit generates a full floor and reports no unreachable rooms, e.g. K1 chop shop: 15 rooms, 7 doors, 88 spawn spots, 3 rubble piles, 11 loose pieces, in by the street, out by the alley; K2 apartment block: 35 rooms, 27 doors, 49 spawn spots; K4 underpass: 31 rooms, 24 doors, 109 spawn spots.
  - A screenshot of the K2 tenement (seed 42) shows the stairwell and the shut corridor door as expected. The Corpo Wars **door-frame models render as bright orange outlines** there; their textures (CWFMETL, CWFWDSD) are grey metal and brown wood, so check them on a real GPU (see Needs playtest). The same furniture models were already in the M2 maps.
- **M1 baseline and final check (2026-10-27):** `python tools/check_lumps.py` → `0 new problem(s), 13 known`; `powershell -File tools/smoke_test.ps1 -Map NBC_TEST` → `PASS NBC_TEST`.
- **M1 branch:** `m1-integration`; since committed with M1b and M1c as one commit.
- `python tools/check_lumps.py` → `0 new problem(s), 13 known`. The known ones are pre-existing pack quirks, each with its reason in `tools/lumps_allow.txt`:
  - 10 SNDINFO entries for sounds the enemy pack never shipped
  - 3 sprites used only on 0-tic weapon frames
- `powershell -File tools\smoke_test.ps1` → `PASS NBC_TEST`. Boot is completely clean: no warnings in 65 lines of output.
- **M1b checks (2026-10-27):** `git diff --check` passed; `python tools/check_lumps.py` → `0 new problem(s), 13 known`; `powershell -File tools/smoke_test.ps1 -Map NBC_TEST` → `PASS NBC_TEST` (66 log lines).
- **M1b release build:** `python tools/build_pk3.py` produced `dist\NewBricksCity.pk3` (9,109 files, 41.5 MB); the PK3 itself was not separately booted after M1b.
- **M1c checks (2026-10-27):** `git diff --check` passed; `python tools/check_lumps.py` → `0 new problem(s), 13 known`; `powershell -File tools/smoke_test.ps1 -Map NBC_TEST` → `PASS NBC_TEST` (66 log lines).
- **M1c release build:** `python tools/build_pk3.py` produced `dist\NewBricksCity.pk3` (9,110 files, 41.5 MB). The smoke test loads the source folder; the release PK3 was not separately booted.
- The smoke test catches failures: a planted ZScript error gave FAIL, with the "Fatal Error" window and `zscript.zs, line 10: '@property@Bogus' is an unknown actor property`.
- Screenshot check: NBC_TEST renders (brick room, pillar, the red '60s voxel car, HUD).
- `python tools\build_pk3.py` → `dist\NewBricksCity.pk3`, 9,103 files, 41.5 MB. It boots and loads NBC_TEST with no errors.

## Needs playtest (owner)
- **M2d environments** (`+map NBC_CT01` ... `NBC_CT08`, one per environment, see "Done"): does each read as what it is (rooftops, sewers, an industrial park, a subway station, a street, a park, a housing tower)? Do the buildings vary enough? Does the 3D city skybox look right round the edges?
- **M2d Obsidian districts** (`+map NBC_CT01` ... `NBC_CT08`): do they read as the Bricks at night (brick blocks, alleys, courtyards, lit windows, street lamps)? Anything still Doom-looking (tech panels, gothic pieces, odd prefabs)? Is the lighting right on a real GPU (streets darker than the rooms, nothing pitch black)? Locked doors still show their key colour?
- **M2c kits:**
  - In the console: `nbc_kittest 1 0 3` (tower, occupied), `nbc_kittest 1 1 10` (gallery), `nbc_kittest 1 2 17` (gang floor), `nbc_kittest 1 3 24` (burned-out), `nbc_kittest 1 4 31` (penthouse); `nbc_kittest 2 <0-3> 5` (street); `nbc_kittest 3 <0-4> 7` (basement); `nbc_kittest 4 <0-2> 9` (roof). Do they read as a housing tower, a city street, a basement, a roof, at the right size next to you and the gang?
  - The flats' windows (CWWINDO) look like windows onto the city, not a painted wall; the boarded ones read as boarded.
  - Round 2 fixes: no door art on building faces or above open doors; exit signs sit on a barricade outdoors; fences visible at every open street edge; the canal, bridge and quay look right; the far-bank buildings and tower windows look the right size next to you; enough street clutter, nothing blocking a sidewalk; no dark gaps between street lamps.
  - Doors: Use opens them, they shut after a few seconds, never on you; walk an officer up to a closed door and it opens. The squeezed door art looks like a door.
  - The gallery rail and the rooftop gap's rails stop you; the plank bridges carry you across.
  - Fences and gates: no thin columns, no gaps in the courtyard, playground or car-lot fences.
  - The scenery past the edges on a real GPU: the canal and its embankment, the retaining wall, the tower blocks' lit windows, parallax as you move, the horizon fading into sky with no wall at the world's edge; the Wall stops at 8 m with towers above it.
  - Lighting on a real GPU: the software renderer here washes lit ceilings white and the roofs dark.
  - Start a case and raid each gang: the right kit floors, the crew count (29 on a Stoop Kings gallery floor; the Swarm budget is no longer capped by spawn spots, so tune in M4), the leader near the exit, the officers keeping up through doors and corridors. Save mid-raid and load.
- Obsidian city maps (`+map NBC_CT01` … `NBC_CT04`): walk the furnished rooms. Check that furniture collision (CW_Blocker) matches the models, no monster or item starts inside furniture, wall sprites hang at a sensible height, and the street debris can be picked up and thrown. Doors and walk paths should stay clear.
- `powershell -File tools\run.ps1 -Extra "+give all"`. Check:
  - every weapon fires
  - the enemies are humans
  - there are no "?" sprites
  - the flashlight works
  - the Dual Berettas reload
  - a Molotov sets enemies on fire (burning-death animations)
- M1 integration checklist, using the same launch command above:
  - kill 20 mixed enemies, pick up every drop, and confirm no vanilla weapon or ammo pickup appears; confirm clip drops feed light ammo, shells feed `Shell`, and former rocket/cell ammo feeds rifle ammo
  - switch through slots 1–5 and confirm the listed melee and firearms, then verify Molotovs are in slot 6 and never exceed 5
  - press F repeatedly while holding different weapons; the flashlight should toggle without selecting a weapon, and R should remain the reload key
  - use `summon WolfensteinSS` ten times; only terrorist variants should spawn, never specop-looking allies
  - check the katana Ninja2 Machete drop and the approximate 8% Molotov chance on tier-1 enemies
- M1b reload checklist, using `powershell -File tools\run.ps1 -Extra "+give all"`:
  - fire empty each firearm and verify automatic reload with reserve or a dry click without reserve; manually press R with a partial and full magazine
  - switch weapons during each reload before and after the commit point; check that only a completed/committed transfer changes reserve and that no rounds are duplicated or lost
  - interrupt the shotgun between inserted shells; check the loaded shell remains and fire resumes immediately
  - confirm pickup ammo feeds reserve only, weapon pickups give a full magazine plus reserve, the HUD and `nbc_debug_weapon` agree, and magazine counts survive save/load and map changes
- M1c debris checklist, using `powershell -File tools\run.ps1 -Extra "+give all"`:
  - Use the NBC_TEST rubble pile and collect the loose types; verify H cycles only carried types, HUD count/type updates, capacity never exceeds 3, and the pile visibly changes and becomes spent.
  - Tap G and hold G to full charge from each supported weapon; verify tap speed 10, full charge speed 30, higher aim extends range, the hand/release frames render, and G with no selected debris does nothing.
  - Throw while reloading before and after the M1b commit point, while firing, and while switching weapons. Confirm no post-cancel reserve transfer, duplicated ammo or stuck/lowered weapon.
  - Hit enemies with each debris type; verify damage, pain/stagger, concrete knockback, one/two/no bounces as specified, and the brick's reusable pickup chance. Confirm bottles break and produce their loud-noise hook.
  - Hit an ally on purpose and confirm no damage; save/load and change maps with debris carried, then verify counts and selected type persist.

## Owner TODO
- **Credits:** the Machete pack and Civilians2 ship no credits. Add their authors to `nbc/CREDITS.txt` (TODO lines are marked).

## Known issues / notes for Codex
- **Testing in a cloud (Linux) session:** install `freedoom` from the Ubuntu archive and copy `/usr/share/games/doom/freedoom2.wad` to `freedoom-0.13.0/` (gitignored); clone UZDoom's `5.0.3` tag from github.com/UZDoom/uzdoom to `/home/user/uzdoom/uzdoom`, build it with CMake + Ninja (deps: cmake, ninja-build, build-essential, libsdl2-dev, libgl1-mesa-dev, libvpx-dev, libbz2-dev, libgtk-3-dev; about 30 minutes on 4 cores), then run `tools/smoke_test.sh <maps>`. It uses the software renderer under xvfb, about 90 s per map. Don't commit engine binaries or source zips (too large for the repo).
- Human M1b and M1c gameplay, pickup, HUD, save/load, weapon interruption and damage playtests remain outstanding; see the checklists above. The M9 arrest/noise hooks are intentionally stubs.
- The enemy pack's SNDINFO names 10 sounds it doesn't ship. Those enemies are silent for that line. Fixing it means finding or replacing the sounds; low priority.
- `+logfile` produced no file in testing. Use `-stdout` with redirected output (the smoke test does).
- In `+console commands`, use forward slashes in paths (a backslash is an escape character).
- Some vehicle class names contain `&` (e.g. `PlaneGreen&Gold`). That's valid; don't "fix" it.
- `check_lumps.py` needs `freedoom-0.13.0/freedoom2.wad` and `uzdoom.exe`'s `uzdoom.pk3`, which aren't in git. In a checkout without them (such as a cloud session) it reports IWAD sprites (`AMMO`, `CLIP`, `SBOX`, `ROCK`, `BROK`, `BAL1`) and the `dsbarexp` sound as new problems. Those are false alarms; run it on the owner's machine for the real count.
