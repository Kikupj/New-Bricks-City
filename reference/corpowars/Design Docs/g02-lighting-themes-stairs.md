# G02: stealth lighting, interior themes, stair towers (2026-09-26)

Shipped in `CorpoWars_tools/_build/g02_lighting_themes_stairs.zip`, then `g02_stair_core.zip` (both already extracted into the game folder).

## Lighting
- Lit rooms' sector light is about 40 lower. Wall rings are a further 24 darker.
- Fixture radii: troffer 136, pendant 112, batten 128, downlight 104. `CW_CeilingLight.LI[]` holds them.
- **Dark rooms** (`rDark`, from a seed hash, so the furniture layout is unchanged):
  - Rooms that can go dark: office/conf 45%, exec 40%, storage/janitor 60%, server 50%, IT/lab/pantry 30%, open 25%.
  - Ambient is 44 (60 with a window), tinted moonlight blue.
  - The fixtures are `unlit`, and a blackout doesn't switch them back on.
- Accent lights: done in `AccentLights()`, which runs after Dress.
  - `CW_LightSource.ups` means battery-backed: the light stays on through a blackout.
- Fixed: the EAI stealth meter now skips dormant lights.

## Themes (`themes.zs`)
- There are 31 texture slots per theme, and each theme is one string row:
  - 0 Meridian Standard
  - 1 Walnut & Brass
  - 2 Clinical White
  - 3 Night Glass
  - 4 Brick & Steel
- How a theme is picked: `CW_Contract.theme` first (Halvorsen = 4), then the `cw_theme` CVar, then the seed.
- Textures are AX* files in `textures/themes/`, imported by `import_themes.py` from the A.D. Cop pack. SS2 textures are not used.

## Stair towers
- `genmap.stair_tower` builds the towers at (2400, 0) and (2400, 800).
  - Each is a square spiral of flights round a **solid concrete core** (224 x 224, no sector). The core replaced the open well after user feedback, matching a real stair core.
  - Landings: C0 at -160, C1 at 0, C2 at 160, C3 at 320.
  - Handrails (`CW_StairRail`) are wall-mounted on both the core wall and the outer wall, on brackets.
  - Each flight has a wall light halfway up.
  - The nav graph ignores x > 2200.
- `CW_StairDoor` (a CW_Interactable) handles the fire-door teleports.
  - The vestibule door connects to C1. The other landings are locked hooks.
  - These hooks are the extension point for multi-floor missions.
- Stairwell insertion spawns the player at C0 or C2. Roof insertion spawns at C2.
- `handler.lastDoorWarp` blocks the held USE key from aborting the mission at the extraction point.
- QA: `qa/stair_test.sh`, plus the `tkstair` testkit event.

## Keycard
- `CW_SecurityPass` uses the CWPS sprites, taken from SP_FLOP.
- Frames A–E are blue/red/yellow/cyan/purple; frames F–J are the lit versions. `tier` picks the colour (currently always 0).

## Merge note
- Another session added the guard variants and `CW_SecuritySupervisor` (guard.zs, procgen.zs, mapinfo, trnslate).
- Those changes were merged into floorgen.zs, and CHANGELOG/CREDITS were merged.
- CHANGELOG.md is also edited by other sessions: edit it in place on the device rather than overwriting it.
