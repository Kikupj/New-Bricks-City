# Site Kits (K01–K06): procedural maps for everything that isn't an office

Status: built 2026-09-27. Playable with the bare-minimum mechanics (rooms, doors, lights, entries, extraction, objectives, guards, bystanders, crate). Site-specific mechanics get hooked in next (see "Next" at the end).

Code: `zscript/corpowars/kitgen.zs` (the base class) plus one `kit_*.zs` per kit. Props are in `kitprops.zs`, and their models come from `CorpoWars_tools/make_models.py`. Map templates are built by `CorpoWars_tools/genmap.py` (`build_kit`, `KIT_GRIDS`).

---

## 1. The kits

| Map | Kit | Grid (cells) | Variants | City sites that use it |
|---|---|---|---|---|
| K01 | Street block | 14 × 8 (176 lots, 96–208 road and walks) | club, restaurant, pawn shop, street market, mall, drug lab, chop shop, gambling den | neutral: bar, restaurant, pawn, market, mall, drug lab, chop shop, gambling · strongholds: the Anchor bar, the drug lab |
| K02 | Residential floor | 12 × 7 (128–176) | tenement, apartments, luxury apartments, hotel, hacker den, rooftops | neutral: tenement, apartments, luxury apartments, hotel, rooftops · strongholds: hacker den, basement den |
| K03 | Industrial lot | 11 × 9 (256) | warehouse, sea dock, fabrication plant, power plant, substation, industrial park, salvage yard, construction site | properties: WH, DOCK, FAB, PLT, SUB, PARK, SAL · neutral: construction site |
| K04 | Underground | 16 × 14 (128) | maintenance tunnels, underpass, transit station, parking garage, hydroponic farm, bunker | properties: FARM, BNK · neutral: tunnels, rail underpass, transit hub, parking structure |
| K05 | Civic hall | 12 × 9 (176, street row 128) | union hall, meeting hall, church hall, university, hospital, archive | neutral: union hall, university, hospital, records archive · strongholds: union hall, union office, meeting hall, church hall |
| K06 | Tech interior | 12 × 10 (176) | data centre, lab | properties: DC, LAB |

Offices, HQs, clinics, studios, training centres and R&D sites stay on the G02 office-floor generator, which handles multi-floor buildings and the garage. The mapping lives in `CW_City.SiteKit()` in `cityjobs.zs`. `MakeContract` sets `c.map`, `c.kitVariant`, `floors = 1` and `garageOk = false` for kit sites. Setting `cw_kitsites 0` sends every job back to G02.

### Layout sketches
- **K01 street**: road (row 0), sidewalk, and a row of lots (cols 2–12, rows 2–5). The target venue takes a run of lots and the neighbours are shops or solid blocks. Behind them are fenced back yards with gates, then a service alley that wraps round the east end.
- **K02 residential**: one floor. A corridor (row 3) runs between two stair cores, with flats or hotel rooms on either side, fire escapes on rows 0 and 6, and an elevator. Rooftops is the open-air variant.
- **K03 industrial**: road (row 0) outside a fence, with a main gate, a side gate and a gatehouse with a window onto the road. Inside is the yard (rows 1–8), with sheds, offices and plant placed on it. The side columns and row 1 always stay yard, so the yard is one connected space. Dock variant: a quay, the harbour and a moored ship with a hold. Plant and substation variants add fenced switchyards; the power plant has cooling-tower blocks.
- **K04 underground**: everything indoors and low. Tunnels variant: a storm-drain channel with walkways and footbridges, a lattice of service tunnels, and chambers in the gaps. Underpass: a cross of passages with a central circus, stairs at the four ends and kiosks. Transit: ticket hall, gateline, stairs, two platforms and the tracks (a 24-unit step down), plus staff rooms. Parking: a deck with pillar cells, a ramp, a booth, stairwells and a lift lobby. Farm: a spine corridor with four grow halls behind airlocks. Bunker: an entrance tunnel, a guard post, a decon lock, a corridor ring, a command centre and an escape tunnel.
- **K05 civic**: street (row 0), a side passage (col 0), the car park (row 8), and a solid building next door (col 11). The building is an outer ring of rooms (lobby on the street, back hall on the car park, stairs in the north corners), then a corridor ring, then the big spaces in the middle: a hall, a lecture theatre and library, three wards, or two stacks.
- **K06 tech**: a corridor ring, with server halls or 2×3 clean-room blocks behind airlocks in the middle, and an outer ring of rooms (lobby south, dock east, stairs in the corners).

---

## 2. How a kit works (the base class)

A kit is a subclass of `CW_KitGen`. It fills a fixed grid of cells:
1. **Setup()**: column widths, row heights, `Grid(nx, ny)`, and door, jamb and edge textures. Optionally the band round the map (`bandFloor`, `bandTex`), e.g. road or water.
2. **Layout()**: make rooms and claim cells.
   - `Room(type, flags, floor, ceiling, light, textures…, name)`, `Rect`, `Claim`.
   - Link them with `Link`, `LinkRooms` or `LinkAll`, using one of these edge kinds:
     - `E_DOOR` (door with a frame)
     - `E_ARCH`
     - `E_WIDE` (fully open)
     - `E_WINDOW` (the player climbs through; guards see through)
     - `E_FENCE` (low wall to see over)
     - `E_VENT`
   - Add entries with `AddEntry` or `WallEntry`. Kinds: `EK_FRONT`, `EK_BACK`, `EK_SERVICE`, `EK_ROOF`, `EK_ANY`. The Intel prep's entry choice picks the matching kind.
   - `Blocks(box, bag, maxW, maxH, hub, kind, hub2)` fills the free cells of a box with rooms from a bag of types (rooms are 2+ cells where they fit, and lone cells merge into a neighbour). Kits that use it override `KitRoom(t)`.
   - Unclaimed cells are solid. Set `cellFac[cell]` to give a solid block a facade.
3. The base then runs the rest of the pipeline:
   1. `PickInsertion`, then `EnsureConnected` (adds doors until every room is reachable), then a reachability check that prints `Kit: <room> is unreachable` if one isn't.
   2. `Carve` moves sector planes to room heights and opens the linked strips; `Paint` handles walls, facades, door textures and the band.
   3. `Dress(r)` per room places furniture (`Put`, `PutInCell`, `PutInRoom`, `PutWall`, `LineWalls`, `Rows`, `Car`), and `LightRoom` adds lamps (styles 0–3 via `LampStyle`).
   4. `Outdoors()` places pole lights and parked cars.
   5. Extraction points go at every entry, then the drop crate.
   6. `PlanObjectives` / `PlaceObjectives` put steal, destroy and turn in the best-scoring rooms by `ObjScore`. The default scoring is by room flags: `RF_VALUE`, `RF_TECH`, `RF_PEOPLE`. Deeper rooms are preferred and objectives are spread out.
   7. `PlaceGuards` (patrols through `RF_PATROL` rooms, posts at objectives, a supervisor; the count comes from the site's guard force), then `PlaceBystanders` (`RF_CIV` rooms).

Room flags: `RF_OUT` (outdoor, sky), `RF_CIV`, `RF_VALUE`, `RF_TECH`, `RF_PEOPLE`, `RF_PATROL`, `RF_NOGUARD`, `RF_DARK` (unlit lamps), `RF_WATER`.

Virtuals a kit can override: `Setup`, `Layout`, `Dress`, `Outdoors`, `VariantName`, `VariantCount`, `Bystanders`, `ObjScore`, `LampStyle`, `EdgeOpen` (outdoor rooms whose map edge is a railing with the view beyond), `KitRoom`.

### Template maps
`genmap.py build_kit(name, colw, rowh)` writes a UDMF map. It contains:
- every cell sector (tag 7000 + j·NX + i)
- the wall strips between cells, three per edge (v 1000+…, h 4000+…)
- corner posts (11000+…)
- a view band round the outside (12000) behind blocking lines

Everything starts closed; the kit opens it at runtime. To add a kit: add a grid to `KIT_GRIDS`, run genmap (`CW_MAPS_OUT`), add a MAPINFO entry, write `kit_<name>.zs`, register it in `CW_KitGen.Make`/`KitOfMap`, include it in `zscript.txt` and map sites to it in `SiteKit`.

---

## 3. Testing

| What | How |
|---|---|
| Load a kit directly | `+map K03 +cw_kitvariant 1 +cw_procseed 42` (variant -1 = from the seed) |
| Deploy a real city job on a kit | `netevent cw_testkit <1-6>` (sv_cheats; closes days until one turns up) |
| Plan picture, screenshots | cloud QA rig: `kit.sh`, `kitlook.sh`, `tools/qa/kitplan.py` |
| Sweep | every variant × 3 seeds on all six kits: no script errors, no unreachable rooms, every objective placed |

Verified 2026-09-27:
- every variant of every kit generates on several seeds;
- city jobs deploy onto K01–K06 and come back to the office with a debrief;
- the office props are byte-identical after regenerating the models.

---

## 4. Next (hooking the mechanics in)
- **Site mechanics per variant**:
  - grow-light cycles (farm)
  - blast doors that need a hack or blackout (bunker)
  - electrified switchyards (substation)
  - trains on the tracks (transit)
  - drug-lab chemicals that ignite
  - the dock ship as a boarding objective
- **Faction guards per site** (the DeePayback roster in building-types.md): gang muscle at strongholds, dock crew, elite security in bunkers.
- **Maglocks and access tiers** on corp kit sites (K03, K04 farm and bunker, K06), which today use ordinary locks.
- **Fixed layouts per property**: corp properties already pass a fixed seed, so the layout is stable. The insertion varies with the visit seed.
- **Multi-level kits**: tenement stacks, bunker levels, parking levels.
- **Art**: the kits reuse stock and office textures; each variant should get its own texture set.
