# AGENTS.md — New Bricks City

This is a roguelite FPS mod for **UZDoom** (a GZDoom fork). You play an undercover cop leading a squad of allied officers on raids into a walled-off district of brick housing towers. The full design and the milestones are in `PLAN.md`. **Read `docs/STATUS.md` first**: it says what's done, what's verified and what's next. Do only the milestone you're asked for, then update `docs/STATUS.md`.

## Project facts
- Engine: `uzdoom.exe` in the repo root. IWAD: `freedoom-0.13.0/freedoom2.wad`.
- Mod source: `nbc/`, loaded as a folder with `-file nbc`. The release is built by `tools/build_pk3.py`.
- `SLADE.exe` (in the root) is the owner's lump and archive editor. It's not part of the mod, and none of its files go into git or `nbc/`.
- **`reference/`** is read-only source to port from, and it's never loaded by the game:
  - `reference/corpowars/` holds the owner's earlier mod Corpo Wars: its full ZScript, definition lumps, `Design Docs/` and credits.
  - `reference/weapons/<pack>/` holds the weapon packs' INFO, OLDCODE and KEYCONF files and FragGrenade's code.

  Port by copying into `nbc/` and adapting. Never edit `reference/`. **`docs/corpowars-port-map.md`** lists each Corpo Wars system's files and every outside class it uses; read it before porting. The original `C:\Games\Corpo Wars\` exists as a fallback, also read-only.
- `DeePaybackEnemies/` and `Weapons/` are the original downloads. They're **read-only**: copy from them, never edit them.
- `tools/import/` holds the one-time M0/M0b import scripts, kept as a record. **Never re-run them**: they regenerate the root lumps and would wipe later work.
- Layout in `nbc/`:
  - new art goes in `sprites/<topic>/` and `sounds/<topic>/`
  - imported DECORATE goes in `actors/<source>/`
  - new ZScript goes in `zscript/nbc/`, and ported Corpo Wars code in `zscript/cw/`
  - root definition lumps are `MAPINFO.txt`, `SNDINFO.txt`, `GLDEFS.txt` and the like; add to them, don't create rival copies.
- Single-player only.

## Code rules
- Write all new code in **ZScript**, under `nbc/zscript/nbc/`, one system per file, included from `nbc/ZSCRIPT.zs`.
- Prefix every new class, CVar, sound, lump and netevent with `NBC_` / `nbc_`. **Code ported from Corpo Wars** lives in `nbc/zscript/cw/` and may keep its `CW_` names, which keeps it easy to compare with the original. Rename a class to `NBC_` once you change what it does. Never wire in Corpo Wars' mission layer (contracts, the corp sim, CW guards or bystanders, security passes) unless PLAN.md asks for it.
- Gangs are **data**. Rosters, traits, damage factors, kit variants and leaders live in `nbc/gangs.txt`, and the Bricks layout lives in `nbc/bricksmap.txt`. Don't hard-code gang specifics in ZScript; add a field to the data file instead.
- Every attack has a damage type (`NBC_Light`, `NBC_Shell`, `NBC_Rifle`, `Melee`, `Fire`, `Blunt`). Gang profiles depend on them.
- **The weapon roster is only the packs in `Weapons/`.** Never import weapons, weapon sprites, weapon sounds or item icons from anywhere else: not DeePayback Weapons 1.5E, and not Corpo Wars' guns. Guns without reload frames use the in-engine dip reload. New weapons arrive only when the owner adds a pack to `Weapons/`.
- Imported DECORATE stays DECORATE. Patch it minimally and leave a `// NBC:` comment on each change. **Exception: firearms.** They're ported to ZScript subclasses of `NBC_ReloadWeapon` (M1b). Keep the originals as unused reference files.
- Every firearm reloads: a per-weapon magazine plus a shared reserve. Melee weapons, throwables and the flashlight don't.
- Thrown debris (the G quick-throw) is built from the FragGrenade pack's code, with no explosion. The FragGrenade itself is not a playable weapon.
- `nbc/sprites/debris/` holds **finished** art. Its source is `art/debris/debris.px.js` (pxl), and `art/debris/export.py` sets the offsets. Don't redraw it, overwrite it or make placeholders for it.
- Never merge an asset pack's KEYCONF (Machete ships one). The slots are set by `NBC_Player`.
- Respect scope: game state changes only in **play** scope. The HUD and menus are **ui** scope; they read state and send changes through `EventHandler.SendNetworkEvent`.
- Case and raid state (the day, strikes, gang states and the current raid) lives in `NBC_RunData` (a STAT_STATIC thinker). Permanent progress lives in archived `server` CVars (CVARINFO). Don't use ACS unless a map truly needs it.
- Draw all case and raid randomness from the seeded RNG in `NBC_RunData`, never from bare `random()`, so seeds reproduce.
- Map things the mod defines use DoomEdNums starting at **26000**, registered in MAPINFO. 25013 is taken by the imported Molotov.
- Never remove entries from `nbc/CREDITS.txt`. Add credits for any new asset.
- Keep names, characters, dialogue and audio original. *Brick Mansions* is setting inspiration only.

## Allied officer (squad) rules
- Allies are `NBC_Ally` subclasses with their own target-finding. Don't rely on the engine's built-in FRIENDLY AI: the pack's enemies have `+NOTARGET`, `+NOINFIGHTING` and `DamageFactor "Enemy", 0`.
- Ally projectiles must **never** use `DamageType "Enemy"`, because enemies are immune to it. Use `AllyTracer` or an NBC tracer.
- Allies never take damage from the player or from other allies, and they have `DamageFactor "Fire", 0` (Molotov fire).
- The ally base classes (specopM*, specopF*, MiltiaShotgun*, Sniper, Sniper2) must never appear in enemy spawn pools.
- During a raid, squad state lives in `NBC_RunData`. The permanent roster lives in the `nbc_roster` CVar.

## Verify before you say you're done
1. `python tools/check_lumps.py` reports **0 new problems**. It checks duplicate lumps, SNDINFO targets, duplicate classes and DoomEdNums, missing sprites, and voxels that would replace sprites. Only add a line to `tools/lumps_allow.txt` for a problem that already exists in third-party assets, and give the reason. Never use it for your own mistakes.
2. `powershell -File tools/smoke_test.ps1 -Map NBC_TEST,<every map you touched>` prints PASS for each map.
   - It boots UZDoom with `-stdout` into `build\smoke_<map>.txt`, using its own config, and kills it after a few seconds.
   - It fails on a "Fatal Error" window, on a missing `Init complete.` or map line, or on any line that looks like an error. Script errors look like `<file>, line N: <message>`.
   - A UZDoom window opens for a few seconds per map; that's expected.
3. List what you could **not** verify (anything that needs a human to play) in `docs/STATUS.md` under "Needs playtest".

Engine notes:
- In `+console commands` on the command line, use forward slashes in paths (a backslash is an escape character).
- `+logfile` produced no file in testing; use `-stdout` with redirected output.
- The engine is UZDoom 5.0.3; `ZSCRIPT.zs` declares `version "4.10"`.

## Commands
```powershell
powershell -File tools\run.ps1 -Extra "+give all"            # play (NBC_TEST until the hub exists)
powershell -File tools\smoke_test.ps1 -Map NBC_TEST           # smoke test
python tools\check_lumps.py                                   # static checks
python tools\list_textures.py BRICK                           # find texture names
python tools\build_pk3.py                                     # release build → dist\NewBricksCity.pk3
```
