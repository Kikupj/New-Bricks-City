# G02 crashes to desktop: guard sprites + floor reflections (2026-09-26)

## Symptoms
- The game crashed to desktop at random while playing G02, and also once when the supervisor guard came on screen.
- Some guards flickered into furniture 3D models.

## Main cause: unregistered guard sprites (fixed)
- The guard variants added by another agent set the sprite in code: `sprite = GetSpriteIndex('CWMA')`.
- The engine only registers sprite names that appear in some state.
  - The only one that did was CWGA, the supervisor's standing frame.
  - CWMA and CWFA (the regular male and female guards) and CWMB, CWFB and CWGB (knocked out) were never registered.
- For those names `GetSpriteIndex` returned -1, so the guards rendered from an invalid sprite index. The renderer then read whatever memory was there, which showed up as furniture models and as crashes.
- Fixed in `guard.zs`:
  - An unused `SpriteRegistry` state now lists every guard sprite and frame.
  - `SetLook(down)` only ever assigns a valid index.
- Verified in the engine: all three looks, the death sprites and the knocked-out sprites render correctly.
- Rule for the future: any sprite set from ZScript must also appear in a state somewhere.

## Contributing cause: too many reflective floors (fixed)
- The lighting pass turned on plane reflections for every polished floor. With the Brick & Steel theme that meant 240 of the 1173 sectors reflected, and each one is a mirror portal for the renderer.
- Reflections now appear only in the lobbies, reception and elevator halls (about 12 sectors per floor).
- The `cw_floorreflect 0` CVar turns them off completely.

## Verification
- Soak test in the engine with guards active, stair doors used, on both Vulkan and OpenGL: no crash, and no growth in actor count.

## Debug launcher
- `Play_CorpoWars_Debug.bat` logs everything the engine prints to `cw_debug_log.txt`.
