# G02 QA harness (headless)

Used to verify the G02 generator without playing: runs UZDoom under Wine + Xvfb (Linux), loads
`CorpoWars` plus the `testkit` folder (a debug event handler, NOT part of the mod), dumps every sector,
line and solid thing, and takes screenshots from scripted camera positions.

- `run.sh <seed> <role> <shots.txt> <outdir>`: shots are lines `x y angle pitch [z]`. `OPEN=1` opens all doors
  first; `PRE="x"` presses extra bound keys first (`x` = spawn every furniture model on the street, `c` = print a
  synthetic furniture-cover test every second).
- `heightmap.py dump out.png`: top-down floor-height map with room labels and furniture.
- `check.py dump`: steps > 24, gaps < 56, and solid things in doorways.
- `reach.py dump [png]`: flood fill from the insertion point; lists any room cell you can't reach. `RAD=20` checks
  guard-sized clearance (guards are radius 20, the player 16).
- `mktour.py dump shots.txt [types]`: a corner camera per room type.
- `cover.py dump [png]`: crouch-high cover within reach along every patrol loop; longest exposed stretch
  (env `R` reach 96 default, use 64; `MAXGAP` flag 256; `COLUMNS=0` ignores the 16u columns). Overlay PNG.
- `reach.py` also: `LOCKED=1` keeps maglocked doors shut, `GAP=32` lets you crawl vents/ducts; prints whether each
  objective room is reachable. The three-ways-in check is `LOCKED=1 GAP=32` (all 3 reachable) vs `LOCKED=1`
  (the server room only via its duct).
- `test_lock.sh <outdir> [seed] [role]`: in-engine maglock test (tap without a pass stays shut, 3 s hold forces
  it, a pass opens it) and prints how the player entered the objective room.

The testkit's console events (`netevent tkdump`, `tknext`, `tkdoors`, `tkshow`, `tkwhere`) also work in a
normal Windows session if you load `-file CorpoWars CorpoWars_tools/qa/testkit`.

## Guard palette check (Windows)

`python CorpoWars_tools/check_guard_variants.py` verifies sprite integrity, palette compatibility,
skin/clothing recoloring and animation coverage, and writes `_build/security_cast_preview.png`.

For an in-engine spawn check, run from the game directory:

```
uzdoom.exe -iwad freedoom2.wad -file CorpoWars CorpoWars_tools/qa/palette -stdout +map HUB01
```

The separate `palette` event handler spawns 64 regular guards and 16 supervisors, checks
their role, sight range, skin palette, and appearance across eight animation states, then removes them.
`CW_PALETTE_CHECK` counts all four skin tones; `CW_CAST_CHECK` counts male/female/supervisor looks.
Both `invalid` and `stateErrors` must be zero. It is not loaded by the normal launcher.
Each regular guard has a 50% male/female chance; each skin tone has a 25% chance. Counts vary.
Use `+cw_procseed 257 +cw_floorrole 1 +map G02` instead of `+map HUB01` to also check
procedural placement: `CW_FLOOR_CHECK` must report one supervisor. G01 supports the same check.
