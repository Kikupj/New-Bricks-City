# New Bricks City — Status

Codex: read this first, then `AGENTS.md`, then the milestone you were given in `PLAN.md`. Update this file at the end of every milestone.

**Next milestone: M1** (integration, player class, loot remap).

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

## Verified (2026-10-26)
- `python tools/check_lumps.py` → `0 new problem(s), 13 known`. The known ones are pre-existing pack quirks, each with its reason in `tools/lumps_allow.txt`:
  - 10 SNDINFO entries for sounds the enemy pack never shipped
  - 3 sprites used only on 0-tic weapon frames
- `powershell -File tools\smoke_test.ps1` → `PASS NBC_TEST`. Boot is completely clean: no warnings in 65 lines of output.
- The smoke test catches failures: a planted ZScript error gave FAIL, with the "Fatal Error" window and `zscript.zs, line 10: '@property@Bogus' is an unknown actor property`.
- Screenshot check: NBC_TEST renders (brick room, pillar, the red '60s voxel car, HUD).
- `python tools\build_pk3.py` → `dist\NewBricksCity.pk3`, 9,103 files, 41.5 MB. It boots and loads NBC_TEST with no errors.

## Needs playtest (owner)
- `powershell -File tools\run.ps1 -Extra "+give all"`. Check:
  - every weapon fires
  - the enemies are humans
  - there are no "?" sprites
  - the flashlight works
  - the Dual Berettas reload
  - a Molotov sets enemies on fire (burning-death animations)

## Owner TODO
- **Credits:** the Machete pack and Civilians2 ship no credits. Add their authors to `nbc/CREDITS.txt` (TODO lines are marked).
- **Commit:** the repo is initialized but has no commits yet.

## Known issues / notes for Codex
- The enemy pack's SNDINFO names 10 sounds it doesn't ship. Those enemies are silent for that line. Fixing it means finding or replacing the sounds; low priority.
- `+logfile` produced no file in testing. Use `-stdout` with redirected output (the smoke test does).
- In `+console commands`, use forward slashes in paths (a backslash is an escape character).
- Some vehicle class names contain `&` (e.g. `PlaneGreen&Gold`). That's valid; don't "fix" it.
- Weapon slots still clash: the fists and knife share slot 1, the machete has no slot, and the Colt, Uzi and Dual Berettas share slot 2. Enemies still drop vanilla weapons. **This is M1's job.**
