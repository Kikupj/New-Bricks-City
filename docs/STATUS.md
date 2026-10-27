# New Bricks City — Status

Codex: read this first, then `AGENTS.md`, then the milestone you were given in `PLAN.md`. Update this file at the end of every milestone.

**Next milestone: M2** (The Bricks level generator and placeholder hub).

## Done

### M0 — Repo, toolchain and asset import (2026-10-26, by Claude)
- A git repo with `.gitignore`. Nothing is committed yet; the owner decides when.
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

### Side work — Obsidian city maps and Corpo Wars room sets (2026-10-27, by Claude; not a milestone)
- `tools/Obsidian/` builds city-block maps with a New Bricks City theme (`addons/NewBricksCity/`, see its README): `powershell -File tools\Obsidian\make_bricks.ps1` writes `nbc/maps/NBC_CT01-04.wad` plus `nbc/mapinfo/city_maps.txt`.
- **Corpo Wars props are now placeable map things.** `tools/import/port_cw_props.py` copied `furniture.zs`, `kitprops.zs` and four decor sets into `nbc/zscript/cw/` (one `// NBC:` change: `CWD_Wall` lifts itself to wall height when placed on the floor), the matching models into `nbc/MODELDEF.txt`, and DoomEdNums into `nbc/mapinfo/cw_props.txt`: furniture 26200–26258, decor sprites 26400–26600. **M2 should reuse these classes, not port them again.**
- `tools/Obsidian/make_cw_fabs.py` remakes Corpo Wars' room recipes (kit_*.zs `Dress()`) as Obsidian prefabs: 18 room sets (living, kitchen, bedroom, bath, office, storage, utility, laundry, workshop, garage, lockers, lab, grow, den, camp, lobby, shop, bar) with furniture along the walls, free-standing groups, random wall sprites and clutter, and loose debris (26000–26004) in squats, dens, storage and on the street. Each Bricks room theme picks from its own list of room sets.

## Verified
- **M1 baseline and final check (2026-10-27):** `python tools/check_lumps.py` → `0 new problem(s), 13 known`; `powershell -File tools/smoke_test.ps1 -Map NBC_TEST` → `PASS NBC_TEST`.
- **M1 branch:** `m1-integration`; no commit created.
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
- **The M2 slice** (New Game starts at Checkpoint 9): use the armory, then the raid board, and open a case. Raid each district: do the officers follow, shoot and keep up over stairs and lifts, do enemies turn on them, is the leader near the exit and the compass right? Is 16–24 enemies a fair fight? Check the bottom-right magazine and debris readouts in both HUD modes, the board menu's readability with the new fonts, and that Esc closes it. Save in a raid and load; start a New Game and confirm the old case is gone. Check whether the parks and split levels read as city blocks.
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
- **Commit:** the repo is initialized but has no commits yet.

## Known issues / notes for Codex
- Human M1b and M1c gameplay, pickup, HUD, save/load, weapon interruption and damage playtests remain outstanding; see the checklists above. The M9 arrest/noise hooks are intentionally stubs.
- The enemy pack's SNDINFO names 10 sounds it doesn't ship. Those enemies are silent for that line. Fixing it means finding or replacing the sounds; low priority.
- `+logfile` produced no file in testing. Use `-stdout` with redirected output (the smoke test does).
- In `+console commands`, use forward slashes in paths (a backslash is an escape character).
- Some vehicle class names contain `&` (e.g. `PlaneGreen&Gold`). That's valid; don't "fix" it.
- Weapon slots still clash: the fists and knife share slot 1, the machete has no slot, and the Colt, Uzi and Dual Berettas share slot 2. Enemies still drop vanilla weapons. **This is M1's job.**
