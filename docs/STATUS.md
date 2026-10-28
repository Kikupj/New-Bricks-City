# New Bricks City — Status

Codex: read this first, then `AGENTS.md`, then the milestone you were given in `PLAN.md`. Update this file at the end of every milestone.

**Current milestone: M3 + M6 + M7c screens** (plus Ghost Recon squad orders) (the case loop on the Obsidian districts, the squad as people, the Evidence Locker, the precinct screens). Raids run on the eight Obsidian districts again; the precinct terminal, the deploy screen and the after-action report are in. Next: playtest the loop (see "Needs playtest"), then the rest of M3 (case-end screens, Merit) and M7b (the city map and the daily gang tick). The kits (M2b/M2c) are test maps only.

## Done

### M7c (part) — The motor pool, insertions, the crash landing; your own face — 🔧 BUILT, NEEDS PLAYTEST (2026-10-28, by Claude)
- **Owner request:** let the player change their portrait; a motorcade where you buy and manage vehicles; a helicopter can start a raid on a rooftop (with a risk of being shot down, which starts a crash-landing survival ambush); land vehicles insert on the street.
- **Your face:** YOUR FACE in the squad room, or FACE on your deploy card, opens a picker of all 144 portraits (faces an officer has are taken; VANCE'S OWN goes back). Kept between games in `nbc_avatar`; new officers never get your face.
- **The motor pool** (`garage.zs`, the terminal's new MOTOR POOL tab): buy, repair and sell vehicles; up to 8. They belong to the case like the locker; a case starts with a panel van and an unmarked sedan.

  | Vehicle | Seats (you included) | Price | On a raid |
  |---|---|---|---|
  | Unmarked sedan | 2 | $350 | a motorcade of sedans only: 15% fewer of them on the block |
  | Panel van | 4 | $800 | room for the stack |
  | Armored truck | 5 | $2,200 | officers take 15% less damage; never wears down |
  | Helicopter | 5 | $4,000 | rooftop insertion: 20% fewer of them; can be shot down |

  Land vehicles lose 4-14% condition a raid (8 more if you didn't take the block), a helicopter 2-8%; under 30% a vehicle is in the shop until repaired ((100 - condition) × price / 250); at 0 it's a write-off. Selling pays half its value times its condition.
- **Rolling out** (Rook's screen, `ui/wheelsup.zs`, now the motorcade): INSERTION STREET or ROOFTOP (needs a helicopter that's not in the shop), the garage as cards to pick (AUTO picks enough seats), SEATS x / y NEEDED (everyone going in has to fit; ROLL OUT / WHEELS UP is off until they do), the shoot-down risk for a rooftop insertion (6% + 4% × gang tier + 6% × alert + a quarter of the helicopter's damage, 5-60%), the squad.
- **Street insertion:** the raid runs on the district map; the vehicles that rolled out park behind your start (the voxel vehicle pack: a dark-blue modern car, a van, the armored truck).
- **Rooftop insertion:** the raid runs on the district's rooftop map, `NBC_RF01-08` ("<district> Rooftops"; Obsidian's rooftops environment, built with `make_bricks.sh --name roofs --length episode --seed 3131 --theme nbc_rooftops` and exported with the new `export_maps.py --prefix NBC_RF --pair-with NBC_CT`, which writes `nbc/rooftops.txt` and `nbc/mapinfo/nbc_rf_maps.txt`).
- **Shot down** (the case RNG, at roll-out): the raid runs on the street map from a crash site out in the open (away from the exit and the leader, the case RNG picks it); the burning wreck (the voxel helicopter, burnt) lies by you; you lose 15-35 health (never below 30), each officer 15-40% of theirs. Four ambush waves (3 + 2 × tier + alert each, out of sight 700-2,400 units off, coming for you) every 25 s from 10 s in; 30 s after the last, "the way to the exit is clear". The leader is still there to topple. Walk out alive and it's SHOT DOWN - SURVIVED (no strike, the gang's alert goes up); the helicopter is gone either way. The HUD shows the wave.
- **The report** lists what happened to the motorcade (rounds taken, the shop, write-offs, the helicopter lost).
- **Art:** `tools/art/make_vehicle_art.py` draws the sedan, van and truck side views (`NBCVSEDN`, `NBCVVAN`, `NBCVTRUK`) to match the owner's helicopter.
- Testing: `netevent nbc_debug_cash <n>`; `netevent nbc_deploy <district> <force>` (1: never shot down, 2: shot down).
- **Verified (scripted runs under Xvfb, software renderer):** the motor pool tab (the starting van and sedan; a helicopter bought, $6,000 to $2,000); the roll-out screen with ROOFTOP picked (risk 14%, seats 5 / 5); the face picker and a face change. A forced shoot-down: the crash HUD line, wave 1 then 2 of 4, health 67% then 59%, crew 18 then 24 then 29. A rooftop raid on NBC_RF05 (23 crew), the report and day 2. A street raid on NBC_CT05 (31 crew): the retreat report shows the van's and sedan's wear notes. The parked vehicles weren't in view in the street screenshot, so `ParkMotorcade` now tries a ring of spots round the start (behind first, level floor, in sight) and the developer line counts what parked. `check_lumps` 0 new problems.

### M8 (part) — People at Checkpoint 9; the pilot starts the raid — 🔧 BUILT, NEEDS PLAYTEST (2026-10-28, by Claude)
- **Owner request:** use the new squad portraits and the pilot and police-captain billboards in the HQ, have NPCs spawn there, and make the pilot the confirmation step that starts a raid.
- **Portraits:** the owner's six "Pixel Mercenary Portrait Grid" sheets (`art/`) are cut into 144 officer portraits, `graphics/portraits/NBCPF000-143` (96×96), by `tools/art/import_npc_art.py`. Face 10 is Det. Vance (`NBCPVANC`) and never rolled for an officer; new officers get a face nobody on the roster has. The generated faces and `tools/art/make_portraits.py` are retired. Outfits on the street still follow the face (`NBC_Outfit` = face × 3 mod 8).
- **The captain** (`NBC_Captain`, thing 26013, `NCAP` A-G from `art/PMC-boss*.png`): stands by the raid board, takes a pull on his cigar now and then. Talk (Use): a line about the case (the day, gangs left, strikes, who's in the hospital, who's due a promotion, the squad, the cash). Use again while he's talking: the raid board.
- **The pilot** (`NBC_Pilot`, thing 26014, `NPLT` A from `art/Pilot.png`), by the south-west door out to the pad. With nothing planned: a line, and Use again opens the raid board. **With a raid planned, the pilot is how it starts:** READY (the deploy screen's button, formerly ASSAULT) sets the plan and a gold "RAID READY ... Talk to Rook" line shows at the top of the HQ; talking to the pilot opens the **wheels-up check** (`ui/wheelsup.zs`, the helicopter art `NBCHELI`): the district, the gang, its leader and trait, everyone going in (portraits, fireteams, your kit). WHEELS UP starts the raid; CHANGE PLAN goes back to the deploy screen; NOT YET walks away. The plan is dropped when a day passes or a case starts.
- **Officers at the HQ** (`NBC_HQOfficer`): each time you're back at Checkpoint 9 the officers fit for duty stand at the `NBC_HQSpot` things (thing 26015; ten in the hub: the desks, the squad corner, the lockers, the bullpen), in their class's sprite and their own clothes; officers in the hospital aren't there. They turn to look at you. Talk: their rank, class and a line (due a promotion, still hurt, first week, on the next raid's list, their kill count, their job). Use again: the squad room, on their service file.
- **Talking** shows a subtitle box along the bottom: the speaker, their portrait (officers), the line and what Use does next.

### M6 (part) — Squad orders, Ghost Recon style — 🔧 BUILT, NEEDS PLAYTEST (2026-10-28, by Claude)
- **Owner request:** "Add the Ghost Recon 1 squad command system so the player can control what their squad does on the map."
- **Fireteams:** the squad splits into ALPHA and BRAVO. The deploy screen sets each officer's team (the badge on the squad card; AUTO and new picks put the first two in Alpha, the rest in Bravo).
- **Keys** (KEYCONF, rebindable under Controls → New Bricks City):

  | Key | Command |
  |---|---|
  | Q | talk to ALL / ALPHA / BRAVO (the ">" on the HUD marks who's listening) |
  | Z | regroup on me (FOLLOW) |
  | C | HOLD where they are |
  | V | MOVE to the spot you're aiming at (a ring of light marks it) |
  | N | ADVANCE along the team's waypoints |
  | B | rules of engagement: RECON → ASSAULT → SUPPRESS |
  | J / K / L | call go code X-RAY / YANKEE / ZULU |
  | M | the command map |

- **Rules of engagement:** RECON is weapons tight (they only shoot gang members already in the fight, after you, the squad or them), no Molotovs, 60% speed. ASSAULT is engage at will (the old behaviour). SUPPRESS adds three rounds to every burst, spreads them wider, keeps firing for two seconds where a target was last seen, and rounds snapping past make targets flinch (a 12% pain chance per round).
- **The command map** (`ui/commandmap.zs`, `NBC_CommandMap`): a top-down view in real time (the raid goes on while you plan, as in Ghost Recon) with the walls, ledges, the exit, your officers by team, what the squad has spotted, and each team's waypoint path. Click to add a waypoint for the team you're plotting (Q/E switches team), drag to pan, the wheel zooms, right-click a waypoint to delete it. The panel sets who your keys talk to, the team's order and ROE, clears the path, puts a go code on the selected waypoint and calls go codes. Keyboard: select the map and the arrows pan, Enter drops a waypoint at the crosshair, Esc goes back to the panel.
- **Go codes:** a team on ADVANCE stops at a waypoint carrying a go code ("BRAVO: At waypoint 2. Waiting on X-RAY.") until you call it (J / K / L or the map), then moves on ("BRAVO: Moving out.").
- **Pathing:** the officers route over Corpo Wars' navigation graph (`zscript/cw/nav.zs`, ported; a binary-heap Dijkstra replaces the linear scan; built once per raid: 1,874 nodes in 152 ms on Sutter Walk-ups). Straight when the way is clear, node to node when not, re-planning when stuck. FOLLOW still chases you directly while you're in sight and uses the graph when you're not (the catch-up teleport stays as the last resort). A team at a point fans out round it.
- **HUD:** an A/B badge on each squad portrait; a line per team (order, ROE, waypoints) with ">" on the ones listening; Ghost Recon's threat indicator, a ring at the bottom centre with a mark for every gang member the squad can see, in its direction from where you're looking (red: it's after one of you; bigger: closer); the squad's radio log bottom left.
- **State:** orders, ROE, waypoints and go codes live in `NBC_RunData` (raid state, reset each raid); `NBC_Orders` (`orders.zs`) takes the `nbc_cmd.<op>` netevents, owns the graph, the log and the contacts. `nbc_debug_case` prints each team's orders and every officer's position. `nbc_navdebug 1` shows the graph's nodes.

### M3 / M6 / M7c (part) — The case loop on the Obsidian districts, the department, the precinct screens — 🔧 BUILT, NEEDS PLAYTEST (2026-10-28, by Claude)
- **Owner request:** raids back on the Obsidian districts with the loop connected; an inventory where recovered weapons and resources go after missions for you and the squad; squad mates as individuals (Hamburger Hill), managed and upgraded like XCOM soldiers (police squad management, the original Rainbow Six); polished menus with clear controls, in the style of the Hamburger Hill video in `docs/`.
- **The loop:** the precinct terminal (raid board) → open a case → pick a district → the deploy screen (squad and kits) → ASSAULT → the district's Obsidian map (`districts.txt`; the env column is read now) → take the exit → back at Checkpoint 9 → the after-action report. `PickMansion` and the kit floors are out of the raid path (kit maps still work as raid maps if one is ever listed).
- **The department** (`nbc/zscript/nbc/dept.zs`, `NBC_Department`, STAT_STATIC):
  - **Officers** (`NBC_Officer`): name, class (Patrol, Breacher, Marksman, Paramedic), rank (Officer → Corporal → Sergeant → Lieutenant at 60 / 160 / 320 XP), XP, raids, kills, health, aim, a toughness roll, a portrait, perks (two to choose from per class per promotion: Steady Hands, Tough as Nails, Kevlar Faith, Hollow Points, Trigger Discipline, Speed Loader, Hair Trigger, Field Dressing, Packrat, Long Watch), hospital days, and a kit (primary, pouches by rank, vest). The roster starts with four (two Patrol, a Breacher, a Paramedic); recruits cost cash (150-250), up to 16.
  - **XP:** 10 per kill, 20 for coming back, 15 when the leader goes down. **Wounds:** below 70% health 1 day in the hospital, below 40% 2 days. **Down on a raid:** pulled out alive at 50% + 10% per rank on a taken block (30% on a retreat, 15% if you went down too): CRITICAL, 4 days; otherwise KIA, the kit is lost and the name goes on the memorial.
  - **The Evidence Locker:** one count per catalog item (7 weapons, 3 ammo types, Molotovs, medkits, vests). A case starts it at issue (2 Colts, a pump, an Uzi, ammo, 3 Molotovs, 3 medkits, a vest). Kits are checked out of it. After a raid everything you carry goes back in (your kit weapons stay checked out to you, used pouches empty), and on a taken block the evidence team bags what the gang dropped (`bDropped` items only, not what Obsidian placed). Sell for cash, requisition ammo and supplies.
  - **Permanent progress:** the roster and the memorial go to the `nbc_roster` / `nbc_memorial` CVars (written from the UI when they change), so the survivors carry into the next game. A new case resets the locker, not the officers. Note: an explicit `archive` keyword on a CVARINFO string hung UZDoom 5.0.3 at startup here; server CVars archive by default, so the keyword is left off.
- **Allies are the officers** (`ally.zs`): the class picks the sprite set (specop, militia shotgunner, sniper, specop-F via `####` states) and the issue weapon (SMG bursts, an 7-pellet shotgun, single 28-42 rifle shots, a light SMG); a seized gun from the kit swaps in its own profile, sound and damage type (`NBC_Light` / `NBC_Shell` / `NBC_Rifle`, never "Enemy"). Aim sets the spread; perks change damage, burst, reload, reaction, sight range and damage taken; a vest takes 30% off. They use their medkits below 35%, lob a Molotov at two or more gang members bunched 160-320 units away (well clear of you), and the Paramedic patches you up (+20) under 50% every 20 s (10 s with Field Dressing). Kills are credited per officer (`WorldThingDamaged` on the killing blow).
- **Your kit:** primary, sidearm, melee, four pouches (a Molotov or a medkit each, `NBC_Medkit` is new: Use from the inventory bar) and a vest, all from the locker. Ammo for your guns is drawn at the start (up to 200 light, 50 shells, 150 rifle), magazines load from it. At the precinct you carry fists and debris only.
- **Screens** (`nbc/zscript/nbc/ui/`, a 960×600 canvas scaled to the screen; slate-blue panels, amber selection, Miniplicity stencil titles):
  - `nbcui.zs` (`NBC_UI`): panels, insets, plates, buttons, tiles, portrait cards, stamps, bars. Input: mouse hover selects, click uses, wheel scrolls, right click backs out; arrows move to the nearest control in that direction, Enter uses, Esc backs out, Q / E / Tab switch tabs. Screens don't pause the game (their changes are netevents and have to run).
  - **Precinct terminal** (`terminal.zs`): RAID BOARD (districts with environment, gang, alert pips; the dossier: leader, tier, alert, crew estimate, bounty, trait; PLAN RAID, CLOSE THE DAY, NEW CASE with confirmations), SQUAD ROOM (the roster as portrait cards, the service file with XP bar, stats, perks, PROMOTE with a two-perk choice, TO SQUAD / BENCH, DISMISS, RECRUIT by class), EVIDENCE LOCKER (weapons, ammo and gear tiles with counts, item detail, checked-out count, SELL / BUY), MEMORIAL.
  - **Deploy** (`deploy.zs`): ROSTER | SQUAD (you plus four, AUTO) | KIT (the selected person's slots; each opens a picker with what's left in the locker, UNEQUIP), AUTO KIT, the locker totals, BACK / ASSAULT.
  - **After-action report** (`results.zs`): the title (TAKEN / RETREAT / OFFICER DOWN), kills, your kills, leader, health lost, time, a letter grade, each officer's portrait with kills and KIA / CRITICAL / WOUNDED / PROMOTION stamps, the loot tiles, seized cash, bounty, balance, the day line; CONTINUE (or SQUAD ROOM when someone can be promoted).
  - **Raid HUD:** the squad strip (portrait, health bar, name) under the raid readout.
- **Hub:** the raid board opens the terminal on RAID BOARD, the lockers on EVIDENCE LOCKER, and a new use spot on the squad corner's sofa (`NBC_SquadRoom`, 26012) on SQUAD ROOM. `netevent nbc_terminal <0-3>` opens it from the console. The old give-everything armory is gone.
- **Officer portraits:** 40 original 48×48 pixel faces (ten per class) and Det. Vance, made by `tools/art/make_portraits.py` into `nbc/graphics/portraits/` (credited).
- **The look of the squad (owner feedback, 2026-10-28):** the first portraits wore modern police uniforms (navy shirts, patrol caps, riot helmets). Redrawn for the lore, a gutted department in a dystopian near future: plain clothes (hoodies, field and leather jackets, flannel, patched coats, knits) with salvaged kit (home-made plate carriers with duct tape and a painted "PD" on breachers, half-face respirators, goggles, a cheap earpiece with a status light, a clip-on scope eyepiece on marksmen, a hand-painted red-cross armband on paramedics) and only a loose mark of the police: a faded navy armband, a badge on a chain, a navy scarf, an old uniform shirt under a jacket, a dull reflective strip. Scars, bandages and bruises; a grimy wall under a street light behind each. No issued headgear: beanies, hoods, bandanas, flat caps.
- **In the field, the same clothes:** the ally sprites (the pack's soldiers, green tops and blue trousers) get one of eight plain-clothes recolors (`nbc/TRNSLATE.txt`, `NBC_Outfit0-7`) instead of the old police-blue remap. Face *f* wears outfit *(f × 3) mod 8* in both the portrait and the sprite, so the card and the officer on the street match.
- **Checks:** `check_lumps` 0 new problems; `tools/smoke_test.sh NBC_TEST NBC_HUB NBC_CT01 … NBC_CT08` → PASS on all ten. The scripted loop runs are under "Verified".

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
- **HQ people and the pilot step (2026-10-28, cloud session, scripted):** `check_lumps` 0 new problems; smoke test on NBC_TEST, NBC_HUB, NBC_CT01-08 → PASS on all ten. At Checkpoint 9: four officers standing at their spots in their outfits, the captain by the raid board, the pilot by the south-west door. Talking to the captain shows his line in the subtitle box; to an officer, their portrait and line, and Use again opened the squad room on that officer's service file. `nbc_ready 4` (READY) put up the RAID READY line; the pilot opened the wheels-up check (helicopter, Sutter Walk-ups, the Stoop Kings, Vance plus four officers with their fireteams); WHEELS UP started the raid (31 crew + leader, 4 officers). Scripts: Use has to be held for a tic or two (`xdotool keydown`/`keyup`), a bare tap can fall between tics.
- **Squad orders (2026-10-28, cloud session, scripted):** `check_lumps` 0 new problems; `tools/smoke_test.sh` on NBC_TEST, NBC_HUB and NBC_CT01-08 → PASS on all ten. On NBC_CT05 with four officers: the graph built (1,874 nodes, 150-210 ms); V moved both teams to the aimed spot ("ALPHA: In position." on the radio log); B cycled the ROE; on the command map two waypoints were plotted for Alpha, X-RAY put on the second, ADVANCE ordered. Alpha walked to waypoint 1 and held (step 0 → 1 only after the call), J called X-RAY and they moved on toward waypoint 2 while Bravo kept following; the map showed X-RAY as called and the officers on the path. Screenshots of the HUD (team lines, A/B badges, radio log), the command map and the deploy screen's team badges.
- **The case loop and screens (2026-10-28, cloud session, UZDoom 5.0.3 on Linux, scripted with xdotool, software renderer):**
  - `python tools/check_lumps.py` → `0 new problem(s), 13 known`. `tools/smoke_test.sh` on NBC_TEST, NBC_HUB and NBC_CT01-08 → PASS on all ten.
  - Screenshots of every terminal tab (no case, a case open, a gang toppled), the confirmations, the promotion and recruit popups, the deploy screen, the kit picker and the after-action report (taken and retreat).
  - Full loop: new case → AUTO KIT → deploy into NBC_CT05 (Sutter Walk-ups: 31 crew + the leader, 4 officers, exit found; your kit issued, magazines loaded, the squad strip on the HUD) → `netevent nbc_debug_clear 0` (kills shared out: you 7, the officers 6-7 each) → back at the hub → the report (Sutter Walk-ups TAKEN, grade A, four PROMOTION stamps, Colt x3 + light rounds + a Molotov to the locker, +$320 seized, +$300 bounty) → CONTINUE → the squad room → PROMOTE (Steady Hands) → Corporal → the deploy screen → a primary picked from the locker (the count drops). A retreat raid on NBC_CT02 gives RETREAT, grade F, alert up, nothing recovered.
  - Fixed on the way: a division by zero when the mouse moved before a screen's first frame; a leading `$` in drawn text being read as a string-table lookup; the stencil font's missing `$`.
  - Testing helpers: `netevent nbc_terminal <0-3>` opens the terminal, `netevent nbc_debug_clear <n>` downs the leader and n of the crew (0 = all) on a raid, `netevent nbc_debug_case` prints the case, roster and locker. Scripted runs: bind keys to these (an `-exec` file) rather than typing in the console; after a level change the console's open/closed state goes out of step with the script.
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
- **The motor pool and insertions:** buy a helicopter (`netevent nbc_debug_cash 5000` helps), raid from the roofs (do the NBC_RF maps play as rooftops: start, crew, leader, exit?), get shot down (`netevent nbc_deploy <d> 2`): is the crash site sensible (out in the open, not inside a wall), is the ambush survivable and tense, is the wreck's fire visible on a real GPU? Do the parked vehicles sit sensibly behind the start on each district? Tune prices, wear and the shoot-down odds. Pick your face; does it stay after quitting?
- **The HQ people:** do the captain and pilot billboards stand at the right size and height on a real GPU (scale 0.68 / 0.7, feet on the floor), and in good spots? Do officers stand clear of the furniture? Talk to each (Use, then Use again). Plan a raid (READY), talk to the pilot, WHEELS UP. Is the portrait set right for every officer (no repeats on a full roster)?
- **Squad orders** (a raid with the squad): Q / Z / C / V / N / B / J-K-L / M as listed under "Done". Do they go where you send them through doors, stairs and lifts on every environment (the graph doesn't know about lifts or doors that need opening)? Does RECON keep them quiet until a fight starts, does SUPPRESS pin the gang? Is the command map readable and quick enough to use in real time, and should it pause instead? Do the threat ring and the radio log help?
- **The squad's look:** do the portraits and the recolored sprites read as a ragtag plain-clothes department in a near-future Bricks, not a modern police or military unit? The sprites' builds still come from the pack (the specop's full-face mask and goggles, the sniper's one-colour coverall); say if any of them should be swapped or recolored further.
- **The case loop and the precinct screens** (New Game starts at Checkpoint 9; Use the raid board):
  - The terminal, deploy screen and report on a real screen: is everything readable at your resolution, do the panels and the amber selection read clearly? Mouse: hover selects, click uses, wheel scrolls, right click backs out. Keyboard / pad: arrows go to the nearest control that way, Enter uses, Esc backs out, Q / E (or Tab) switch tabs.
  - Open a case, plan a raid, change the squad and kits on the deploy screen (pickers, UNEQUIP, AUTO, AUTO KIT), ASSAULT. On the map: your guns and ammo match the kit, magazines are loaded, pouches give Molotovs and medkits (Use the medkit from the inventory bar), the vest gives armor; the officers look like their class, carry their guns (shotgun spread, rifle single shots, the Uzi and AK sounds), use medkits, lob Molotovs (never at you), the Paramedic patches you up.
  - Take the block (down the leader, reach the exit), retreat (exit with the leader alive) and go down once: the report's numbers, grade, stamps (WOUNDED / CRITICAL / KIA / PROMOTION), the loot that went to the locker, the cash. Check the locker afterwards: ammo you came back with is there, used pouches are empty, a gun you picked up is in the locker.
  - Promote an officer (two perks to choose from), recruit one, dismiss one; hospital days count down when you close the day or raid; the memorial lists the dead. Quit and start a new game: the surviving roster is still there (`nbc_roster`).
  - Balance to tune: officer damage and accuracy, the XP curve (60 / 160 / 320), hospital days, recruit prices, sell and requisition prices, the starting locker, how much the gangs drop.
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
