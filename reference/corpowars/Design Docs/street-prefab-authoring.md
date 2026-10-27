# Corpo Wars — Street Map Prefab Authoring Guide

Version 1 · 2026-09-28 · for anyone (human or agent) building street-map prefabs in Ultimate Doom Builder (UDB)

---

## 1. What we're building

Street missions take place on one fixed city map, `street_grid.wad`. It has a crossroads, sidewalks and tall background buildings, and it never changes, so every mission keeps the feel of being somewhere inside a big city. The map has **four lots**, marked with the `FLAT5` floor texture. **A mission always uses exactly one lot.** The other three get a closed background shell.

This is a **toolbox, not a sandbox**. Nothing is fully free-form: variety comes from choosing between hand-built pieces that were made to fit known spaces.

Variety comes in three layers:

| Layer | When | What varies | Who makes it |
|---|---|---|---|
| **Shell** | Build time (assembler script) | Which prefab fills the lot: e.g. the south-west lot is a *Park* or a *Construction site* | Hand-built in UDB, one set per lot |
| **Sub-slots** | Build time (assembler script) | What fills each marked area inside the shell: e.g. the park's slots get a fountain, playground, basketball court… | Hand-built in UDB, one set per slot size |
| **Dressing** | Mission load (game script) | Props, lights, guards, bystanders, objectives, extraction; which switchable gates and fences are open | Placed at runtime on marker things you put in the pieces |

A finished mission map is:

**street grid** + **one mission shell** in the mission's lot (its sub-slots filled with pieces) + **a background shell** in each of the other three lots.

The assembler (a Python script, written separately) writes these finished maps. The game picks one by the job's seed and runs the mission on it.

---

## 2. Files

| File | Holds | How pieces are drawn |
|---|---|---|
| `Assets/maps/street_grid.wad` | The street map (map `MAP01`). **Don't edit it for prefab work.** | — |
| `Assets/maps/cw_lots.wad` | **Shells.** One map per shell, many maps in one WAD. | At the lot's **real world coordinates** (section 3) |
| `Assets/maps/cw_pieces.wad` | **Sub-slot pieces.** One map per piece. | At the **origin**, in a fixed orientation (section 6) |

- Format: **UDMF**, namespace `zdoom`, the same as `street_grid.wad`. UDB's "UDMF (GZDoom)" config works.
- Resources: `freedoom2.wad` plus the `CorpoWars` mod folder, for its textures and props.
- Map names: 8 characters max, uppercase letters, digits and `_`. See the naming rules in sections 4 and 6.

**Tip for shells:** open `street_grid.wad`, copy the whole map into a new map in `cw_lots.wad`, delete everything outside the lot, then build inside the lot area. The street edges stay in place for reference, and the shell lands at the right coordinates. Delete any leftover street sectors before saving: a shell map may only contain geometry inside its lot's bounds.

---

## 3. The lots

Coordinates are Doom map units. +x is east and +y is north. Floor heights are relative to the road (0); the sidewalk is 8.

| Lot | Bounds (x1..x2, y1..y2) | Size | Street side(s) | Neighbours on the other sides |
|---|---|---|---|---|
| **NW** | x −4096..−3328, y 4224..5376 | 768 × 1152 | **East** (sidewalk, floor 8) | N: low strip (floor 0) · W: building (432) · S: building (328) |
| **NE** | x −2304..−1152, y 3584..5376, **plus annex** x −1152..−576, y 4480..5376 | 1152 × 1792 + 576 × 896 (an L shape) | **West** and **south** (sidewalk, 8) | N: building (304) · E: building (544) below the annex. The annex touches only buildings (304 / 536 / 544): it's a back yard, no street frontage. |
| **SW** | x −5632..−3328, y 768..2560 | 2304 × 1792 | **North** and **east** (sidewalk, 8) | S: buildings (200, 296) · W: the map edge |
| **SE** | x −2240..−448, y 1152..2496 | 1792 × 1344 | **South** only, to a strip at floor 8 that leads to the service lane | N, W, E: a **128-high wall** (sectors in the street grid, outside the lot) with the roads beyond |

All four lots have a floor of 8 (sidewalk height) and a sky ceiling (`F_SKY1`) at 600, like the rest of the street.

**Open question, SE lot.** The wall around it belongs to the street grid, so a shell can't cut a gate into it. If SE shells need gates onto the north or west roads, move that wall into the lot, as part of each shell, in `street_grid.wad` first. Decide this before building SE shells.

### Edge rules (every shell)

- **Match heights at the boundary.** Along a street side, the shell's floor meets the sidewalk at 8. Where a shell needs a step or kerb, put it inside the lot.
- **Don't build past the bounds.** The assembler cuts each shell at its lot's rectangle, so anything outside is lost.
- **Street sides are the fronts.** Entrances, shopfronts and gates go on the street side(s) listed above. Other sides back onto buildings: close them, or use them for back doors into a yard or alley inside the lot.
- **Outdoor areas** use the sky ceiling at 600. Indoor rooms use their own ceilings. Keep roofs and walls at or below 600.

---

## 4. Shells

A shell fills one whole lot. It holds:

- the fixed structure: perimeter (fence, railing, hoarding, building walls), entrances, main paths, anything that should always be there;
- **sub-slots**: empty areas the assembler fills with pieces (section 5);
- **marker things**: entries, objective spots, guard posts and so on (section 7);
- optional **switchable sectors**: gates or fence gaps the game opens or closes per mission (section 8).

**Naming:** `<LOT>_<TYPE>` for a mission shell and `<LOT>_BG<n>` for a background shell.
Examples: `SW_PARK`, `SW_BUILD`, `NW_BAR`, `NW_PAWN`, `NE_TENEM`, `SE_CARPK`, `SW_BG1`.

**Background shells:** each lot needs at least one. These are what the lot shows when the mission is somewhere else: a boarded-up shopfront, a fenced vacant lot, a solid building, a closed yard. They're scenery only. They should read as closed from the street and need no markers.

**Starter list** (suggestions, not a rule):

| Lot | Mission shells | Background shells |
|---|---|---|
| NW (narrow, one street front) | bar / club, pawn shop, gambling den, drug lab behind a shopfront | boarded-up shop, narrow building |
| NE (big corner lot + back annex) | tenement or hotel with a back yard in the annex, restaurant, chop shop with the yard | shuttered corner block |
| SW (biggest, corner) | park, construction site, street market, parking lot | fenced vacant lot |
| SE (walled, south access) | parking lot / car park, chop-shop yard, depot | locked yard |

---

## 5. Sub-slots

A sub-slot is an area inside a shell that the assembler fills with a piece.

**Sizes.** Use only these, so pieces can be reused:

| Code | Size (units) |
|---|---|
| `S256` | 256 × 256 |
| `S512` | 512 × 512 |
| `R5X2` | 512 × 256 |
| `S768` | 768 × 768 |
| `R10X5` | 1024 × 512 |

(Ask before adding a size. Every size needs its own set of pieces.)

**How to mark one in a shell:**

1. Leave the area as **one plain square or rectangular sector**, exactly the slot size, axis-aligned, with its corners on the 64-unit grid. Floor at the shell's ground height at that spot, floor texture `FLAT5_1`, and the shell's ceiling (sky outdoors).
2. Put **one slot thing (31050)** at its exact centre:
   - **arg0** = size code: 1 `S256`, 2 `S512`, 3 `R5X2`, 4 `S768`, 5 `R10X5`
   - **arg1** = slot group (see below): 1 park, 2 construction, 3 market, 4 shop interior, 5 yard / back-of-house, 6 car park…
   - **angle** = which way the slot's **front** faces (towards the path or entrance that reaches it): 0 east, 90 north, 180 west, 270 south
   - **arg2** = 1 if the piece may also be mirrored (default 0)
3. The slot's edges must be **open to the surrounding space** (two-sided lines, nothing blocking) along at least its front edge, so the piece placed there can be reached.

The assembler deletes the slot sector and puts the chosen piece's sectors in its place, joined to the shell's lines at the slot's edges.

**Slot groups** keep pieces in context: a fountain only lands in a park slot, a stack of rebar only in a construction slot.

---

## 6. Pieces (sub-slot fillers)

- **One map per piece** in `cw_pieces.wad`, named `<size>_<NAME>`, for example `S512FTN` (fountain), `S512PLAY` (playground), `S512BBAL` (basketball court), `S768PIT` (excavation pit), `R10X5STK` (materials stacks). Keep to 8 characters.
- **Draw at the origin:** the footprint runs from **(0,0)** to **(width, height)**. The **front edge is the south edge** (y = 0), facing −y. The assembler rotates the piece so that edge faces the slot's front.
- **Stay inside the footprint** and keep the outer boundary a plain rectangle on the 64 grid. Everything inside is up to you: raised beds, pits, low walls, a kiosk, a gazebo with a roof.
- **Floor height:** 0 at the footprint's edge. The assembler lifts the piece to the slot's floor height. Heights inside are relative to that.
- **Ceilings:** anything open to the sky uses `F_SKY1` at **592** (relative to the edge floor; it lands at 600). Roofed parts, like a kiosk or a toilet block, use their own ceiling.
- **Header comment:** the piece's slot group goes in arg1 of a **piece info thing (31051)** anywhere inside the footprint. arg0 = weight (how often it's picked, 1–10, default 5).
- Pieces carry their own markers (section 7).

---

## 7. Marker things

These are editor things with the numbers below. Put them in shells and pieces. The game reads them when the mission loads and removes them. **UDMF keeps things' args**, so use args as listed.

| Thing | Meaning | Angle | Args |
|---|---|---|---|
| **31012** | Entry: front (main way in from the street) | facing into the lot | — |
| **31013** | Entry: back (rear or yard door, alley side) | facing in | — |
| **31014** | Entry: service (side gate, delivery door) | facing in | — |
| **31015** | Entry: covert (over a fence, through a skylight or roof hatch) | facing in | — |
| **31020** | Objective spot: where something to steal, destroy or hand in can go | — | arg0 = value (1 low … 3 high: safe, office, server) |
| **31021** | Guard post: a guard stands here | facing | arg0 = 1 if only when security is high |
| **31022** | Patrol point: guards walk between these (and posts) | — | arg0 = route id (points with the same id form a loop) |
| **31023** | Bystander spot: a civilian may idle here | facing | — |
| **31024** | Extraction point (optional; otherwise one goes at each entry) | — | — |
| **31030** | Prop spot: the game may place a prop here | facing (a wall prop faces away from the wall) | arg0 = category: 1 street (bin, hydrant, bench), 2 alley (dumpster, pallets, trash), 3 construction (materials, machinery), 4 park (bench, lamp, planter), 5 cover (crates, barrier), 6 vehicle (a parked car) · arg1 = chance % (default 60) |
| **31040** | Light: a lamp the game switches on | — | arg0 = style (0 street sodium, 1 cool white, 2 door light, 3 neon) · arg1 = colour for neon (0 red, 1 blue, 2 pink, 3 green, 4 amber) |
| **31050** | Sub-slot (shells only, section 5) | front | as in section 5 |
| **31051** | Piece info (pieces only, section 6) | — | arg0 weight, arg1 slot group |
| **31060** | Switchable group (section 8) | — | arg0 group id, arg1 kind, arg2 chance open % |

Guidelines:

- **Every mission shell needs at least a front entry (31012)**, plus one other entry of a different kind. Missions are planned around **three ways in**.
- **Objective spots (31020):** at least 3 per mission shell, spread out, some deep inside. Pieces can add more.
- **Guard posts and patrol points:** enough to cover the main routes: about 4–8 posts per shell, and 1–2 patrol loops.
- **Prop spots:** use plenty. They're cheap, and the game leaves some empty for variety.
- Don't place monsters, items, keys, player starts, teleports or exits. The game adds everything that moves.

---

## 8. Switchable sectors (gates, fence gaps, locked doors)

Some routes should change per mission: a side gate open or chained, a gap in a hoarding, a loading door up or down.

1. **Build the opening in its OPEN state:** a sector across the gap, floor at ground and ceiling at the opening's height.
2. Give it a **sector tag from 1 to 99**. Tags are local to the shell or piece; the assembler renumbers them.
3. Put **one switchable-group thing (31060)** inside it:
   - **arg0** = the same tag
   - **arg1** = kind: 1 gate (closed = solid, impassable), 2 fence gap (closed = fence panel you can see through but not cross), 3 lockable door (closed = locked door you can pick or hack), 4 vent / crawl gap (closed = grille)
   - **arg2** = chance it's open, 0–100 (default 50)
4. Texture its sides as they should look when **closed** (fence, shutter, gate). The game closes it by moving the sector's floor or ceiling.

**Ordinary doors:** build them as normal Doom doors (closed sector, line special `Door_Raise` (12), tag 0) and the game converts them. Don't use other line specials.

---

## 9. Style

- **Scale:** the player is 56 tall and 32 wide. Storeys are **128**. Doors are 64 wide × 112 tall. Corridors are at least 96 wide. Avoid ceilings above 192 indoors unless it's a hall.
- **Street feel:** set pieces back from the kerb, add low walls, steps and railings, and aim for a shopfront at ground level with a facade above. The references are a dark city night: pools of street light, neon, alleys lined with dumpsters.
- **Textures:** use the Freedoom set plus `CorpoWars` textures. Keep to the street's palette (brick, concrete, grey panel, dark glass).
- **Lighting:** sector light levels outdoors 64–96, a bit higher indoors. The game adds lamp light at the light markers (31040).
- **Performance:** keep a shell under about 400 sectors, and a piece under about 60.
- **Everything reachable:** the player must be able to walk (jump height 32, crouch height 32) from every entry to every objective spot, with ordinary doors open and switchable groups in either state.

---

## 10. What the assembler does (for reference)

1. Load `street_grid.wad` (MAP01).
2. For the chosen mission lot: load its shell from `cw_lots.wad`. For each 31050 slot: pick a piece from `cw_pieces.wad` with the same size and slot group (weighted by 31051 arg0), rotate or mirror it to the slot's front, lift it to the slot's floor, and swap it in for the slot sector.
3. For the other three lots: load a background shell (`<LOT>_BG*`).
4. Clip each shell to its lot bounds and stitch its boundary lines to the street grid's lot edges. The lot's FLAT5 sector is replaced.
5. Renumber tags and write a finished map (`CWS01`, `CWS02`…) into a pool WAD the game loads.
6. **Check:** heights match at every boundary, no geometry outside the bounds, every entry reaches every objective, required markers present. A map that fails is rebuilt or the piece is skipped.

The game then reads the markers on load, converts doors, rolls the switchable groups, places props, lights, objectives, guards and bystanders, and inserts the player at the chosen entry.

---

## 11. Checklist before handing in a shell or piece

- [ ] UDMF, correct map name, in the right WAD
- [ ] Shell: drawn at the lot's real coordinates, nothing outside the bounds; piece: drawn at the origin, front edge on the south
- [ ] Heights match the sidewalk (8) on street sides; sky at 600 outdoors (pieces: 592)
- [ ] Sub-slots are plain rectangles of an allowed size, on the 64 grid, `FLAT5_1`, with a 31050 at the centre
- [ ] At least a front entry and one other entry; at least 3 objective spots (shells)
- [ ] Guard posts, patrol points, bystander and prop spots placed
- [ ] Switchable sectors built open, tagged 1–99, each with a 31060
- [ ] No monsters, items, keys, starts, exits or line specials other than `Door_Raise`
- [ ] Walked it in UDB's 3D mode: every entry reaches every objective
