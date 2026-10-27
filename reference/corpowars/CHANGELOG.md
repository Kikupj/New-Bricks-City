# Corpo Wars — Changelog

Format: newest first. Versions are prototype milestones (0.x). Entries dated 2026-09-25 / 2026-09-26
are retroactive, reconstructed from the development log.

## [Unreleased]
### Office pools switched on (2026-10-01)
- Six more pools (OFC office, HQT headquarters, CLC clinic, STD studio, TRN training site, RND R&D office; 6 layouts each, built
  by `gen_site_pool.py` from `generate_office.py`): each building is a floor + its roof (training: floor + parking garage).
  OFF / HQ / CLN / STU / TRN / RND properties now open them instead of G02 (`CW_SitePool.OfficeCode`; "" sends a type back to G02).
  An office's emergency stairs count as a street-level way in; a roof hatch is a covert entry; the training site is entered
  from the garage street exit. Debug: `cw_testkit 7 [1-6]` deploys the first job on an office pool (type = PT_OFF..PT_RND + 1).
### After Hours site pack in the game loop (2026-10-01)
- `CorpoWars_sites.wad` + `CorpoWars_sitemaps.pk3` (built by `Assets/maps/AfterHours/build_mod_pack.py`, 38 pools x 6 generated
  layouts) replace the old K01-K06 kits wherever a pool exists: city-map GO THERE and contracts open `S<CODE><NN>A` maps
  (SBAR03A, SHOT02A ...). The building's layout seed picks the pool variant, so a building is always the same layout.
  Power plant, parking, rooftops and the office-like types stay on K03 / K04 / K02 / G02. `cw_newsites 0` = old routing.
- New `sitepool.zs` (routing, CWSITES parser) and `sitemission.zs` (guards, patrols, bystanders, objectives, extraction,
  insertion, multi-floor persistence). Nav graph: bucketed link search so big maps build in under a second.
- Debug: `netevent cw_sitelist`, `cw_sitego <pool> <variant> <job 0/1>`, `cw_sitestairs <n>`; `cw_testkit N` matches pack maps.

### Debug hub (kit tester)
- `Play_CorpoWars_DebugHub.bat` (launcher `-DebugHub`): HUB01 with `sv_cheats 1` and `cw_debughub 1`. The terminal's
  OPERATIONS tab becomes **KIT TEST**: every site kit and variant (K01-K06, "random" = from the seed), the G02 office
  floor (single / 3-floor tower), the G05 garage, CWTEST, M01 and M02.
- **WALK IN** (ENTER) loads the map with no job (`cw_kitvariant` / `cw_floors` set for you). **WITH A JOB** (J) borrows
  the first job on the board, moves it onto that kit and variant at no cost and deploys it (objectives, extraction,
  debrief; the target text still names the job's original site). **T** flips to the real job board and back.
- New key "Debug hub: return to hub" (default HOME, `netevent cw_dbgreturn`): back to HUB01 from anywhere; during a
  job it aborts the job. Only active with `cw_debughub`. Code: `zscript/corpowars/debughub.zs`.

### Underground mood lighting
- `cw_undermood` (-1 picked per site, 0 plain, 1 soft gold, 2 green, 3 crimson, 4 cool blue, 5 mixed): about half the
  lit rooms and two-thirds of the corridors on an underground map get an accent colour, a gentle sector tint plus
  lamps in that colour (at least two rooms per map). Left at -1, most sites get a mood (15% stay plain). The OBSQA line
  reports it. Visibility is unchanged (the stealth meter reads light level, not colour).

### Underground sites on the Obsidian pool (block-out)
- **New pool: underground (K04)** — maps `CWU01..` / `CWV01..`, built by the launcher like the industrial pool
  (`CorpoWars Underground.txt` preset, `cw_underground` theme in `corpowars_sites.lua`). All indoors: no outdoors,
  parks, caves or fences; more and bigger halls, more hallways, up to 3 crawl ducts.
- Uses the industrial role numbers; the game names them per site and variant (platform, parking deck, grow hall,
  command centre, ticket hall, airlock, guard post, armoury...). Six variants as K04: maintenance tunnels, underpass,
  transit station, parking garage, hydroponic farm, bunker. Entries: street stairs / manhole / station entrance /
  vehicle ramp / entrance tunnel, service shaft / escape tunnel, maintenance hatch, storm drain (the far indoor way in
  that replaces "over the fence").
- Hall props by variant (pipes, vending machines, barriers, grow beds, sandbags). Stock textures only.
- Farm and bunker properties, and neutral K04 sites, now deploy onto the pool (`netevent cw_testkit 4`).
- Verified headless: 11-map pool builds in ~1 min; 10/11 maps load with 3 objectives and no unreachable rooms.
  Known: a small map can still come out with unreachable rooms (seen once: CWU08).

### Playtest round 2: stealth on the industrial sites, knockouts, lean, climbing
- **Darker sites**: Obsidian maps are night-shifted — ambient light capped (rooms 80, corridors 72, yards 88-104),
  about a quarter of the rooms have the lights off (48-56), about half of Obsidian's light fittings work and rooms
  get one or two lamps, so there are pools of light with shadow between. Obsidian's glow / flicker / strobe
  sector effects are stopped (they kept pushing lights back to 255).
- **Cover in open spaces**: yards, halls, loading bays and stores get crates, pallet racking, pallets, dumpsters, scrap
  and containers off the patrol middle, spaced apart and a player's width from walls (`cover N` in the OBSQA line).
- **Extraction points** go against a wall near each entry (a corner or alcove when there is one) instead of the
  middle of a room or yard.
- **Fists knock out**: a punch on an unaware or staggered guard knocks him out; a punch that would kill knocks out
  instead; otherwise he's dazed for a moment. Civilians go down in one punch. No kills, no casualty fines. Punching
  the recruit target can't kill him. Punches are quiet: a 96-unit scuffle instead of a 1,400-unit gunshot alert
  (they were counted as gunfire), and the taser no longer counts as gunfire either.
- **Tactical lean** (hold Q / E; Options > Customize Controls > Corpo Wars): the camera tilts and slides out to peek,
  the body stays behind cover. Traced against walls. Guards can spot a peeking head (at 40% of normal visibility).
  `cw_leanangle` (12), `cw_leandist` (22). Shots still leave from the body.
- **Ledge climbing** (hold Jump facing a ledge or a prop 25-60 high): climbs map ledges, 3D floors and furniture —
  crates, pallets, dumpsters, desks — so a prop the generator left in a doorway can be climbed over. Arrives crouched;
  weapon lowers while climbing. `cw_climb 0` turns it off. The player is now `CW_Player` (a DoomPlayer).

- **Grounded movement** (from Build Movement v2): extra ground friction every tic with more push to match, so you
  stop almost dead when you let go, and a slower top speed than vanilla — running ~12 u/tic (was 16.7), walking ~6.
  Landing flinch after a real fall; death roll + red flash. Works on props, off while climbing, keeps the lean's roll.
  Footstep noise retuned to the new speeds (run > 9 = 360-unit radius, walk > 4.5 = 160, crouch-walk silent).
  Options > Corpo Wars Movement: `cw_buildmove`, `cw_movespeed` (1.6; 1.9 = the original mod), `cw_landflinch`,
  `cw_deathroll`, plus the lean and climb settings.

### (earlier, unreleased)
### Fixed: Obsidian industrial sites (playtest round 1)
- **Spawns**: every entry is tested with a player-sized probe (fits, room to move, not in a duct or doorway)
  and moved or dropped; the player is checked again on arrival. Start pads and exit closets are no longer built
  (the "behind bars" spawn), and the player start sits at a real entry.
- **Reachability**: the game works out the walkable area (steps, headroom, doors, lifts, 3D floors) and keeps
  objectives, guards and bystanders inside it. Obsidian's switch-opened doors are now Corpo Wars doors.
- **Map size follows the site**: pools hold small (01-04), medium (05-08) and large (09-11) maps; substations
  get small ones, docks, plants and fabs large ones, warehouses and salvage yards medium; neutral sites mostly
  small. Maps are now about 1,500-5,000 units across instead of ~7,000; rooms are smaller.
- **Crawl ducts**: up to two narrow service halls per map become ducts the player crouches through (guards can't).
- **Windows**: passable for the player (not guards); only the scenery edge keeps its invisible wall.
- **Corridors**: no Obsidian decoration in hallways; our furniture keeps a player's width of passage.
- Removed: cross / gothic / religious prefabs, barred and cage windows, water textures (the "water ceiling"),
  crushers, trap and ambush prefabs.

### Changed: industrial sites are now built by Obsidian
How it works and how to tune it: Design Docs/obsidian-maps.md.
- **Obsidian builds the maps, the game runs the mission.** A Corpo Wars addon for Obsidian
  (`CorpoWars_tools/obsidian_addon/CorpoWars`) gives it our industrial theme and textures, switches off monsters,
  pickups, keys, switches, traps, secrets and teleporters, swaps every texture a prefab hard-codes for one of ours,
  and leaves markers for the rooms, entries and good spots. A quality gate rebuilds maps with too few rooms, buildings,
  yards or ways in.
- **Map pools and the launcher.** `Play_CorpoWars.bat` now runs `CorpoWars_Launcher.ps1`: it builds a missing pool
  before the game starts, loads every pool with the game, and builds a fresh pool in the background for next time.
  Pools alternate between two map-name sets (CWI / CWJ) and the previous one stays loaded, so saves and job offers
  keep their maps. `-Rebuild` / `-NoBuild` options; the debug bat still writes cw_debug_log.txt.
- **Industrial jobs use the pool**: warehouses, sea docks, fab plants, power plants, substations, industrial parks,
  salvage yards and construction sites. A property keeps its map while a pool lasts. With no pool (or `cw_obsidian 0`)
  they fall back to the K03 kit.
- **In the game** (`obssite.zs`): Obsidian's doors become Corpo Wars doors (guards open them, hack / bypass / breach
  work), exits are defused, rooms get lights, furniture by role, objectives, patrols and posts, bystanders,
  extraction at every entry and the drop crate; room names follow the job's variant.
- 110 more A.D. Cop textures (industrial walls, machinery, containers, crates, grates, hazard panels, light panels).
- Navigation: the furniture grid is sized to the map (Obsidian maps are ~7,000 units across).
- Debug: `netevent cw_guarddump`; `cw_testkit 3` finds pool jobs; `cw_simverbose 1` prints pool map positions.

### Added: site kits — six procedural map generators for everything that isn't an office
Design and how-to: Design Docs/site-kits.md. Code: `kitgen.zs` (base) and `kit_*.zs`; templates K01-K06 from
`CorpoWars_tools/genmap.py` (`build_kit`).
- **K01 street block** (club, restaurant, pawn shop, street market, mall, drug lab, chop shop, gambling den): a road,
  sidewalks, a row of shopfronts with the target venue among them, back yards and a service alley.
- **K02 residential floor** (tenement, apartments, luxury apartments, hotel, hacker den, rooftops): a corridor between
  stair cores, flats either side, fire escapes; rooftops is the open-air variant.
- **K03 industrial lot** (warehouse, sea dock, fabrication plant, power plant, substation, industrial park, salvage
  yard, construction site): a fenced yard off the road with a gatehouse, sheds and plant on it; the dock has a quay,
  the harbour and a ship with a hold.
- **K04 underground** (maintenance tunnels with a storm drain, pedestrian underpass, transit station, parking garage,
  hydroponic farm, bunker): stairs from the street, manholes, service tunnels; the station has platforms and tracks.
- **K05 civic hall** (union hall, meeting hall, church hall, university, hospital, archive): lobby on the street, a ring
  of rooms and a corridor round the big spaces (hall, lecture theatre and library, wards, stacks), a car park behind.
- **K06 tech interior** (data centre, lab): corridor ring, server halls or clean rooms behind airlocks.
- **Bare-minimum mechanics on every kit**: carved rooms with doors, windows, fences and vents; lights; 2-5 named
  entries (front / back / service / roof, honours the Intel entry choice) with extraction at each; objectives
  placed by room tags (valuables / tech / people); patrols, posts and a supervisor scaled by the site's guard force;
  bystanders; the drop crate. Every room is checked reachable from the insertion point.
- **The city uses them**: data centres and labs -> K06; farms and bunkers -> K04; warehouses, docks, fabs, plants,
  substations, parks and salvage yards -> K03; neutral sites and strongholds by kind (bars, restaurants, markets,
  malls, pawn shops, drug labs, chop shops, gambling dens -> K01; tenements, apartments, hotels, rooftops, dens -> K02;
  construction sites -> K03; tunnels, underpasses, transit, parking -> K04; union / meeting / church halls,
  universities, hospitals, archives -> K05). Offices, HQs, clinics, studios, training centres and R&D sites stay on
  the G02 office floor. `cw_kitsites 0` puts every job back on G02.
- **26 new 3D props** (containers, crates, pallets, bar counter, stools, beds, pews, tanks, transformers, scaffolding,
  dumpsters, market stalls, grow beds, turbines, pipe racks, generators, turnstiles, lockers, scrap, workbenches,
  air-con units, water tanks, jersey barriers, sandbags, street lamps) and 17 textures, from `make_models.py`.
- Debug: `cw_kitvariant`, `cw_procseed` (load K01-K06 directly), `netevent cw_testkit <1-6>` (deploy the next city
  job on that kit).

### Added: the city layer (corps, minor players, the city) and the contract loop running on it
Design: Design Docs/city-layer-design.md and companions; implementation notes: Design Docs/city-layer-implementation.md.
- **The city** (`city.zs`, roster in `cwcity.txt`): 6 corps, 32 subsidiaries (8 shells), 67 properties in 5 districts,
  38 executives, 4 minor players with turf, 8 strongholds and 8 leaders. Relations are randomised +-10 per save and
  every property gets a fixed map seed. Money inside the sim is in $k. `cwcity.txt` is plain data: edit names, stats,
  starting relations and agendas there.
- **Turn-based days** (`citysim.zs`): every job takes a day; CLOSE DAY [C] on the terminal skips one. The daily tick runs
  income and upkeep, agendas, operations (freelancer prep, deadlines, launches), minor-player turf and dormancy, the
  property market, collapse and carve-up, patronage and win / loss, then the news.
- **Faction AI**: agendas (from the design doc) weight which operations get launched; targets are scored
  (agenda fit + hostility + weakness + value + opportunity) and picked by weighted roll; goals follow each faction's
  personality table. Minor players run strikes, raids, leaks, protests and shakedowns on their turf; corps run
  operations to suppress them (stronghold raids). Targets sometimes catch wind and launch counter-operations.
- **Operations -> jobs** (`cityjobs.zs`): every open step of a running operation is a job on the terminal: the
  decisive CONTRACT at a corp property or stronghold, and INTEL / ACCESS / WEAKEN / LEVERAGE / PROGRESS odd jobs at
  neutral sites. The four prototype jobs are the opening operations on day 1 (Helix Recovery, Black Ledger,
  Brain Drain, Field Audit), now with the clients from the design docs.
- **Prep matters**: Intel = free site survey + patrol schedule and you choose the entry [E]; Access = you start with
  the pass for the primary's floor; Weaken = -3 guard force, -1 tech; Leverage = +15% pay and softer outcomes.
- **Property security drives the map**: guard force 6-16 and tech level 1-4 per property set the guards on the G02
  floor (posts added or stood down), hack difficulty and guard sight. Properties keep their layout between visits;
  the insertion point changes. Towers in tall districts can still start in the garage.
- **Neutral sites and strongholds on the G02 fallback**: light security, no maglocks, no passes; site name on arrival.
  New objective verbs: photograph and plant (the item stays), lean on / meet (the recruit target).
- **Consequences**: steal, sabotage, recruit (executives change sides, with vacancies and acting replacements),
  strikes, raids, leaks and shell exposure, scandals, protests, extortion, turf shifts. Every hit costs the target.
  Heat carries over: identified runs cost standing (third parties react), hot runs put the target's sites on alert.
- **Property market**: foreclosure (EarthGov-guarded seized property), distress sales (properties and whole
  subsidiaries), lease expiry, scandal sales, sealed-bid auctions, Meridian receivership, empty brands sold off.
  Collapse and carve-up: a fallen corp's subsidiaries are auctioned one a day.
- **Patronage and the end**: Allied (75) corps offer patronage (LEDGER: pledge / decline). Win when your patron holds
  17 of 32 subsidiaries or stands alone; lose if it collapses, if another corp takes the city, or if you default on
  Meridian (advances past $12,000). Jobs against your patron are refused; taking one through an unknown shell is
  betrayal.
- **Services priced by standing**: Candor (intel), Northstar (crew), Bastion Arms and Oriole Clinical (quartermaster),
  Voltaic (+10 s blackouts at Friendly). Minor-player services at Friendly: Rustline black market, Local 9
  informants, NullSet cheap intel, Tenants' safehouses (-8 heat).
- **Fog of war**: treasuries, debts, agendas and exact relations need intel (CITY tab: BUY INTEL, or documents from a
  theft); shells hide their parent until uncovered; odd jobs hide their operation until you work it; minor-player
  turf is rough unless they're friends. Intel goes stale after a week. Quiet days on the wire drop hints.
- **Terminal**: OPERATIONS | INTEL | CREW | CITY | MARKET | LEDGER | NEWS. Debriefs gain CITY IMPACT and OVERNIGHT.
  The office HUD shows the day, the board and any patronage offer.
- Debug (console): `netevent cw_citydump`, `netevent cw_simdays N` (+ `cw_simverbose 1`, `cw_simplayer 1-6`), and with
  sv_cheats `cw_testodd 0|1`, `cw_testfinish 1|0`, `cw_testrep <faction> <delta>`, `cw_openterminal`.

### Changed
- You're an independent broker: the office is "The Broker's Office", the terminal is the broker's terminal, and the
  safety net is a Meridian advance (with a limit).
- Saves from before the city layer start a fresh city the first time you're in the office (budget and gear kept).

### (earlier, unreleased)
### Added: heat, parking garage, extraction scenarios (foundation for the corp / city layers)
- **Heat** (`CW_Ledger.Heat()`, 0-100): alarms x12, guards killed x6, civilians killed x12, doors breached x8,
  bodies found x5, +3 per half minute since the first alarm; -10 for a run with no alarms; crew on the job take
  the edge off (Nyx -6, Marrow -8, Vox -6). Shown on the mission panel; "Heat at exit" in the debrief.
- **Parking garage (G05, level B1)**, part of the building's hub: concrete deck with pillars, a lift lobby, rows of
  parked cars (Voxel Vehicles Pack, with blockers so the whole car is solid) and your van.
- **Garage insertion** (~40% of tower jobs): you start at the van (crate at its tail) with a few staff heading
  home and a guard on rounds (plus one at the lift on medium/high security). The lift goes up to the insertion
  floor; the passenger elevator there has a "garage (B1)" button. Every exit in the building brings you back
  down, and the job ends at the van.
- **Rerouted extraction**: on a normal insertion, reaching an exit with the primary done rolls once: chance =
  heat - 25 (max 60%). If it hits, "your exit's burned" and the van is waiting in the garage instead.
- **Extraction scenarios**: the first trip down with the primary done rolls on heat (+/-15 luck): quiet (< 20),
  patrol (two guards on the aisles), checkpoint (two posted at the lift mouth incl. the supervisor, plus a patrol),
  ambush (five guards crouched around your van, on edge). A reroute is never quiet. Debrief: "Extraction: ...".
  Dying on the way to the van fails the job as usual.
- genmap: `build_garage("G05")`.

### Fixed / changed (playtest round 6)
- **Guards no longer fight each other**: one species (`CWSecurity`), `+NOINFIGHTING`, `+DONTHARMSPECIES`.
- **Guard sounds from DeePayback Enemies**: PMC male / female voices for the guards, the USA male voice for the
  supervisor (see / pain / death), Glock gunshot for their pistols; no more zombie growls.
- **Hacked or bypassed maglocks stay released**: the keypad stays green and the door opens with USE like any
  other door for the rest of the mission (it still swings shut on its own).

### Changed (playtest round 5): getting through a maglock
- **Forcing the lock (hold USE, noisy) is gone.** Without a pass or a blackout, a maglocked door now offers:
  - **Hack** (tap USE): a timing minigame at the keypad (`CW_HackMenu`, the game keeps running). Stop the sweeping
    marker in the lit window; each hit clears a node and the next window is narrower and faster. Nodes = 3 + the
    building floor tier (+1 on high-security contracts). Three misses trip the lock: a loud tone heard 800u away
    and a 20 s keypad lockout. Getting spotted mid-hack drops you out.
  - **Maglock bypass** (new gadget, $350, single use): hold USE for 3 s, silent.
  - **Breaching charge** (new gadget, $400, [K]): 3 s fuse, then the door is blown open for good (keypads dead).
    Heard 1600u away and it hurts anyone within ~144u, you included. Debrief: "Doors breached".
- Debrief "way in" notes: hacked / bypass device / blown open.
- A standing guard posted beside a maglocked door no longer holds it open (only guards walking up open doors).
- Breaching charge art and sounds from Spring Mine by Mor'ladim (see CREDITS.txt).

### Fixed / added (playtest round 4)
- **Doors fit their frames**: the painted door (lower-pegged upper texture, -8 offset) now sits exactly inside the
  3D frame when shut and slides up into the lintel when opened; no more door texture above the header.
- **Elevators between floors**: on multi-floor contracts the passenger and freight cars get a call button per
  other contract floor on the back wall ("Elevator: floor 17 (exits)"). You arrive in the same car on that floor,
  facing out.

### Changed (playtest round 3)
- **Contract list**: the hand-built prototype jobs (M01 / M02) are gone. Four jobs remain, all on generated towers:
  Field Audit, Helix Recovery, Brain Drain, Black Ledger. Old saves: repeatable jobs are never marked completed.
- **Board advance** (safety net): if the budget can't cover the cheapest contract, the Meridian board advances
  enough for it plus $800 of kit. Half of every later payout goes to repaying it until it's clear. Shown in the
  debrief and the office HUD ("Owed to the board"). Also applied when an existing save loads the office.
- **Steal objective placement**: the item can be in an executive suite, private office, conference room, storage,
  IT room or lab (weighted, in the far part of the floor); outside suites it sits in a free spot of the room, watched
  by a posted guard half the time.
- **Security supervisor** is a random guard on the floor, not always the one in the steal room.
- **Roomier interior**: interior band 144 -> 176, corridor 112 -> 128, core cells 128 -> 160 (genmap G02_SIZES and
  floorgen SZ; G02-G04 regenerated). No single-cell huddle rooms: conference rooms are 2-3 cells.
- QA: reach.py covers the larger plate and ignores the player's own spot.

### Added
- **Stationary posts**: 1-2 extra guards per floor stand post at key spots (beside maglocked objective doors
  watching the approach, the elevator hall, corridor corners), placed in the emptiest part of the floor after
  patrols are balanced. Posted guards (these and the existing objective-room / lobby posts) slowly sweep a
  70-degree arc and face the nearest doorway instead of a fixed direction.

### Changed (playtest round 2)
- **Extraction is any exit** on the insertion floor: every elevator, stairwell, the street lobby and the roof stair.
- **Extraction marker**: once a primary is done, a top-centre marker points to the nearest exit with its distance;
  on a building's other floors it points to the nearest stairwell and names the exit floor.
- Aborting now takes **holding USE for 1.5 s** at an exit (with a progress prompt), so a stray tap can't end a mission.

### Fixed (playtest round 1)
- **Terminal text overlap**: wider window; the contract brief and the debrief shrink their text until everything fits
  above the footer; long names are cut with "..." instead of running under prices, and long debrief labels wrap.
- **Guards bunched on one side**: patrol rings start on opposite sides of the floor, the server/recruit rooms are
  picked far from the insertion point *and* from each other, and any empty quadrant gets a patrol between its
  corridor and open-plan corners (console: "Guards by quadrant").
- **Mission HUD**: the objective panel is smaller (72% text) with only objectives and status; kit and crew moved
  to a small panel on the right above the status bar.
- **Door sounds**: generated doors no longer play the looping ceiling-move grind (silent `CWDoorSilent` sequence);
  open/close is quieter, shorter-range and pitch-varied.
- **Stairs between floors**: a landing door marked "Floor N" puts you on floor N's plate, in its stair vestibule,
  instead of in another copy of the stair tower.
- `cw_floors` is no longer saved to the ini; multi-floor test runs without a seed use a fixed building.

### Added
- **Multi-floor buildings (G02 / G03 / G04).** A contract's `floors` (1-3) sets how many consecutive floors of the tower
  the job spans. You insert and extract on G02; the other floors are separate maps in one hub cluster (cluster 20), so a
  floor keeps its state (bodies, open doors, alert guards) when you come back. The stair-tower fire doors for
  landings that are mission floors are open ("Floor 17 (on the contract)") and change level; you arrive on that
  floor's landing in the same tower, facing its fire door. Everything is derived from the mission seed (`CW_Building`):
  floor numbers, insertion floor slot, and which floor holds each objective (primaries are never on the insertion floor).
  Multi-floor jobs are always typical office floors and share one interior theme.
- **Per-floor security passes.** A pass found (or taken off a guard) on floor index m is tier m, shown as that
  floppy colour, and only opens that floor's maglocks. The mission panel lists the passes you hold and marks each
  objective with its floor (`[FL 17]`).
- **Tower Floor contracts**: G02 versions of the corporate jobs with their clients' rules of engagement:
  Helix Recovery (Castellan, Clinical White, 2 floors, no civilian fines), Brain Drain (Meridian Board,
  Walnut & Brass, 2 floors, recruit only, guard/civilian fines, sabotage penalized), Black Ledger (Oriole,
  Night Glass, 3 floors, civilians protected). All repeatable. The terminal contract list scrolls.
- `cw_floors` test CVar (2-3 = multi-floor building with no mission running).
### Changed
- Only the objective server room gets the destroyable server; other server rooms are racks only.

- **Stealth lighting pass (G02).** Rooms sit darker (sector light about 40 lower) and the fixtures throw tight
  pools (troffer 136, pendant 112, batten 128, downlight 104 radius) with real shadow between them; the wall ring
  of each cell is 24 darker still.
  - **After-hours rooms**: a seed-stable share of offices (45%), conference rooms (45%), executive suites (40%),
    storage/janitor (60%), server rooms (50%), IT/lab/pantry (30%) and open-plan (25%) have their lights off:
    moonlight-blue ambient (44, 60 by a window), fixtures dark (`CW_CeilingLight.unlit`), blackouts don't
    switch them back on. Circulation (corridors, core, reception, elevators) is always lit.
  - **Accent lights**: monitor glow at 70% of desks in dark rooms (and it shows you if you stand in it), blue
    LEDs on server racks, vending-machine fronts, warm **wall sconces** (new 3D `CW_WallSconce`) along corridor
    cells and in suites/lobbies, red battery emergency lamps in stairwells, green spill under exit signs.
  - Per-room **colour tints** (warm suites and pantry, cool server/IT, clinical lab/bath, sodium service rooms,
    red stairwells) and **reflective floors** on marble, tile, polished concrete and wood.
  - Nyx's blackout cuts every mains light (`CW_LightSource`) and sconce; battery-backed ones (`ups`: monitors,
    exit signs, emergency lamps) stay on.
- **Interior theme sets** (`themes.zs`, `CW_Themes`): five tenant fit-outs, each a matched set of 31 wall /
  floor / ceiling materials by room role - Meridian Standard (original), Walnut & Brass, Clinical White,
  Night Glass, Brick & Steel. 80 A.D. Cop textures imported to `textures/themes/` (`tools_src/import_themes.py`).
  Chosen by the contract (`CW_Contract.theme`; Halvorsen Logistics = Brick & Steel), else `cw_theme`, else the seed.
- **Stair towers** (G02): each stairwell cell is now a vestibule with a fire door to an off-plate tower (genmap
  `stair_tower`): a square spiral of flights round a solid concrete core, landings one floor below, this floor, and two above
  (16-step flights, wall-mounted 3D handrails `CW_StairRail` on both walls, floor-number plates `CW_FloorSign`, batten + emergency light
  per landing). **Door teleports** (`CW_StairDoor`): USE a fire door to fade through to its partner; the other
  floors' doors are locked hooks (another tenant's floor / roof alarmed / plant room) ready for multi-floor
  missions. Stairwell insertions now start in the tower, a floor below or above; roof insertion on the top
  landing. Floors are numbered (ground 1, typical 4-25, top 30-38). Guards' nav graph ignores the towers.
- **Security pass is a floppy disk** (`CWPS`, from the SP_FLOP set): five colours as frames for future access
  tiers (tier 0 = blue on every floor for now), blinking on the floor, HUD icon.
- Regular guards randomly use DeePayback's male/female militia characters, recolored with
  charcoal-black shirts/caps and dark navy trousers. Both have four skin tones.
- The bald suited character is now `CW_SecuritySupervisor` (20004): sight range 1280u vs
  a regular guard's 1024u (1600u vs 1280u once cautious). Other combat stats stay the same.
  G01/G02 make the first successfully placed guard a supervisor; manual maps can place 20004.
- All three looks keep their appearance through idle/walk/fire/pain, death, non-lethal collapse,
  and resurrection. Original PNGs/offsets are preserved in CWGA/CWGB, CWMA/CWMB, CWFA/CWFB.
  `CorpoWars_tools/import_guard_sprites.py --check` checks asset integrity and frame coverage.
- **Three ways into every objective room (G02)**, following the Deus Ex rule (design doc: "Level Design: Three
  Ways In"). Objective rooms are chosen before carving: executive suite farthest from insertion (STEAL),
  server room (SABOTAGE), lab or else the farthest private office (RECRUIT - the target now always exists).
  - FRONT: every ordinary door into an objective room is **maglocked** (`CW_Door.secured`): open it with a
    **security pass**, during **Nyx's blackout**, by **tailgating** a guard (guards carry passes), or **force** it
    (hold USE 3 s: prying noise every second heard 520u away; the door jams open; counted in the debrief).
  - SIDE: the server room keeps its crawl duct; the suite and the recruit's room get an unlocked door through a
    neighbouring staff room (office / storage / janitor / IT / pantry preferred, the aisle itself last).
  - INFORMATION: `CW_SecurityPass` lies in an IT room / lobby / office 400u+ from insertion; one patrolling guard
    carries another and drops it when downed (lethal or not). Site survey intel marks the loose pass on radar.
  - Keypads (`CW_Keypad`, 3D) on both faces of every maglocked door: red locked, green open, dark = no power / broken.
  - HUD prompts at the lock; "Security pass" row on the mission panel; passes are cleared on insertion.
- **Cover budget** (`CoverPass`): along the aisle ring and corridor loop, crouch-high cover (>= 28u) or an unlocked
  doorway is never more than 192u of walking away; the generator adds a low credenza against a side wall or a
  freestanding planter where the gap runs out. New `CW_FCredenza`; planters are now waist-high (30u) cover.
- Debrief FIELD REPORT: "Way in" line per objective room (air duct / side door (room) / front door with pass /
  maglock down / tailgated / forced) and "Maglocks forced".
- QA: `cover.py` (cover along patrol loops), `reach.py` `LOCKED=1` / `GAP=32` / per-objective reachability,
  `test_lock.sh` (in-engine maglock test).
### Fixed
- Guards flickering into furniture models / crash to desktop: the regular-guard (CWMA/CWFA) and knocked-out
  (CWMB/CWFB/CWGB) sprites were never named in any state, so the engine didn't register them and
  `GetSpriteIndex` returned -1; guards rendered from an invalid sprite index. `CW_Guard` now lists every sprite in
  an unused `SpriteRegistry` state, and `SetLook()` never assigns an invalid index.
- Random crash to desktop in G02: plane reflections were on every polished floor (240+ mirror-portal sectors with
  Brick & Steel's polished concrete). Now only lobbies, reception and elevator halls reflect; `cw_floorreflect 0`
  turns them off.
- Stealth meter counted switched-off (dormant) dynamic lights: blackouts didn't actually hide you.
- Door "a player opened it" detection misfired while a door was closing (now keyed on the door rising).

### Removed
- The stair-flight furniture model in stairwell cells (the stairs are in the tower now).

### Staged (in `Assets/`, not yet integrated)
- `PDA.pk3` (9 files: PDA sprite + brightmap) and `Checkpoints_v667.pk3` (21 files, incl. `SP_SAVED` sound) -
  candidates for an intel/PDA pickup and checkpoint saves.
- `SP_FLOP_*` source PNGs (blue/cyan/purple/red/yellow) behind the `CWPS` security-pass frames.
- New level-design references in `Assets/references/` (two concept images 15:13/15:15, `B146_2.jpg`).

### (previous unreleased work)
### Added
- **3D light fixtures**: `CW_CeilingLight` now renders as a model instead of the old billboard, in four styles
  the G02 generator picks per room: recessed 2x4 troffers (offices / open plan), drum pendants (executive,
  conference, reception, pantry), industrial battens (storage, janitor, server, IT, freight, stairwells) and
  round downlights (corridors, elevator lobby, washrooms, elevators). Light colour follows the fixture; the
  blackout still switches them off. Hand-placed lights elsewhere become troffers. The ceiling exit sign is a
  double-sided 3D box.
- **Furniture is cover**: a guard can't see you when every line from his eyes to the top of your head passes
  through solid furniture below its top surface - crouch behind desks and counters, stand behind racks.
- **Guards path around furniture**: the nav graph drops nodes inside furniture and refuses links that clip it
  (blockers bucketed on a 128u grid, negligible build cost).
- **3D door casings** on every doorway (wood for offices / suites / meeting rooms, brushed steel elsewhere);
  doorways get an aluminium threshold and a plain header soffit.
- `CorpoWars_tools/texlib.py`: shared numpy texture toolkit (tileable fbm, wood grain, weave, brushed metal,
  bevels, grooves, baked light / AO, grime, scratches, glow).
### Changed
- **Texture detail pass**: every generated wall, flat and prop texture rebuilt with material variation,
  baked top light and floor AO, bevelled seams and trims, scuffs and grime, to sit with the stock and A.D. Cop
  sets: plaster with vinyl skirting, walnut boarding with a chair rail, honed stone, painted CMU, glazed tile,
  fissured acoustic ceiling tiles with prismatic lenses, quarter-turn carpet tiles, veined dark marble, sealed
  concrete, raised floor, brushed-steel elevator doors, painted fire doors, galvanised duct, crown trim; props
  get walnut grain, laminate fleck, powder-coat, twill fabric, leather, granite, and scanlines on screens.
- Same-room openings take the room's floor and ceiling (no more carpet seams through wood and marble rooms);
  wide openings between rooms take the corridor finish.
- Layout for flow (verified walkable at guard size, radius 20, across 12 seeds): interior-band open bays keep
  their middle clear (desks / lounge against the side walls), lobby pit seats are armchairs across a coffee
  table, conference tables are 88u with tighter chairs and no decor in multi-bay boardrooms, one executive
  bookcase slid away from the bay joint, lounges skip the armchair in walk-through bays, no corner plants in
  lobby bays. Guard posts try a ring of spots when the cell centre is furnished.
### Fixed
- Furniture collision blockers are laid the moment a piece is placed (they used to appear a tic later, so
  placement tests couldn't see earlier furniture and pieces could overlap or land on guard posts).
- Light fixture models: one MODELDEF block per style (slots in a shared block all drew at once).

### (previous unreleased work)
### Added
- **G02 refinement pass — 3D furniture**: 30 low-poly furniture models built in code by
  `CorpoWars_tools/make_models.py` (OBJ + 40 original material textures in `textures/props/`, `modeldef.props.txt`):
  workstations with monitors/keyboards/tower PCs, executive desk + chairs, office/guest chairs, sofa, armchair,
  coffee table, conference table, round table, reception counter, file cabinets, bookshelves, server racks,
  pallet racking, vending machine, copier, water cooler, kitchen run with sink, lab bench, bins, planters,
  toilet stalls, washbasin vanity, a stair flight for stairwells, elevator handrail, cubicle screens,
  wall-mounted whiteboards and TV screens. G02 is now dressed with these instead of billboard sprites
  (plants, crates, cart and objectives stay sprites).
- `CW_Furniture` (furniture.zs): model actors that lay invisible `CW_Blocker`s over their rectangular footprint so
  long desks and counters collide like rectangles. Chairs and bins are decorative (no collision).
- Room layouts per type: open-plan workstation rows along solid walls + back-to-back cubicle pods in open bays,
  private offices (desk by the window, shelving, meeting nook or lounge), executive suites (desk facing down the
  suite, guest chairs, bookshelves, lounge + wall screen, area rug), conference rooms (tables down the room's run,
  leather chairs, whiteboard + screen), pantry, storage, server rows, IT, labs, washrooms, reception counter,
  stairwells with a real flight of stairs, elevator rails. Placement keeps doorways, vents, the insertion point
  and bay-to-bay walkways clear, and never puts furniture across an opening or anything tall against glass.
- **Interior glazing**: private offices and conference rooms have glass fronts (sill 32, head 84) toward the
  aisle / corridor; executive suites get sidelights beside the door. Glass blocks movement, bullets and use, not sight.
- Brushed-metal cladding on open-plan columns and door jambs; wall rings sit 16 light darker than room centres.
- G02 cells now have a 16u tread ring between the outer ring and the centre panel (tags 10000+): two-step
  coffered ceilings and a two-step (-8/-16) sunken seating pit in the street lobby.
### Changed
- G02 floors are flat everywhere except the lobby pit: server/IT/freight (+8), executive (+16) and stairwell
  landing (+16) raises removed.
### Fixed
- G02 planes are set instantly at generation instead of with movers; a floor raised in the same tic as a closed
  strip's ceiling was clamped (doorway steps at the wrong height).
- Transport crate spawns in the insertion-cell corner farthest from any doorway, after dressing.

### (earlier unreleased work)
### Added
- **G02 geometry pass**:
  - *Windows with depth*: the facade is now window bays (sill 32u, header 104u, 24u deep) behind translucent,
    bullet-proof glass, split by solid mullions, looking out over a night skyline (sky + street far below).
  - *Shaped ceilings*: every cell is pre-split into a ring and a centre panel. Rooms get crown/soffit trim,
    coffered and double-height centres (lobby 160u, reception 192u, exec 168u), recessed light panels,
    and lowered ductwork in server, IT, storage, janitor and freight spaces.
  - *Floor steps*: raised executive suites (+16, two steps via an 8u doorway), raised server/IT floors and
    freight elevator (+8), stairwell landings, and a sunken seating pit in the ground-floor lobby.
  - *Functional doors*: every room door is a real door (wood office doors, glass-panel service doors,
    red fire doors to stairwells, steel elevator doors). USE opens them from either side, guards open them
    as they approach, and they close by themselves once the doorway is clear. They start open for a moment
    so the nav graph links through them.
  - *Room size variety*: offices 1-3 cells wide, occasional open lounge alcoves on the facade,
    conference rooms from 1-cell huddle rooms to 3-cell boardrooms, 2-3-cell labs.
- A.D Cop texture set imported (doors, marble, travertine, metal panels, computer walls, light panels,
  wood/marble floors, night skyline) - credited in CREDITS.txt. Generated: glass, duct metal, crown trim.
- **Office art pass (G02)**: new original texture set drawn in code by `CorpoWars_tools/make_textures.py`:
  plaster walls with baseboards, wood panelling, dark accent stone, tiled washrooms, server-rack walls,
  concrete service walls, floor-to-ceiling night-city windows on the facade, drop-ceiling tiles with light
  panels, carpets, polished stone lobby floor, raised server floor, elevator doors, fire doors, wayfinding
  signs (ELEVATORS / STAIRS / RESTROOMS / SERVICE / EXIT), corporate logo walls and slogan posters.
- Each room type now has its own wall/floor/ceiling/light style; door headers get a plain header texture,
  wall posts are themed, the elevator lobby is lined with elevator doors, and corridor walls next to the
  core carry wayfinding signs.
- New props (original sprites): potted plant, vending machine, copier, sofa, water cooler, janitor cart,
  waste bin, ceiling exit sign (DoomEdNums 20116-20123). Rooms are dressed with them: plants in corners and
  corridor bends, copiers/coolers along the open plan, sofas in reception and exec offices, vending + cooler
  in the pantry, a cart in the janitor closet, exit signs over stairwell doors.
- **Office floor generator (G02)**: `floorgen.zs` + 11x11 grid map **G02** laid out like a real centre-core
  office floor plate. From the facade inward: perimeter private offices with four corner executive offices,
  an open-plan aisle ring, an interior band (conference rooms, pantry, lab, storage, IT, server room),
  a racetrack corridor loop, and a rotated 3x3 service core (elevator lobby, passenger + freight elevator,
  two diagonally-remote stairwells, two restrooms). Deus Ex-style route: janitor closet -> crawl duct -> server room.
- **Floor roles + random entry points**: each G02 floor is a ground floor (street lobby with reception),
  typical floor or top floor (roof access stair). The mission inserts at a random entry point for that role
  (elevator, freight elevator, stairwell A/B, street lobby, roof stair) and extracts at the farthest other one.
  No guards spawn near the insertion point. `cw_floorrole` cvar forces a role (-1 random, 0/1/2).
- **Runtime procedural sites (proof of concept)**: `procgen.zs` + blank modular grid map **G01**
  (10x8 cells of 240u, 16u wall strips split side/door/side, all closed by default, tagged).
  At mission start a seeded generator lays out a corridor spine, an insertion dock and BSP-split rooms,
  assigns room types (office, storage, server room, lab, executive suite, lobby), guarantees every room is
  reachable (+ ~25% extra doors for alternate routes; exec suites single-entry), opens walls/doorways,
  themes each room (wall/floor/ceiling textures, light level) and dresses it with prefab routines
  (props, civilians, guard posts, patrol loops, objectives, extraction, transport crate), keeping doorways
  clear. Nav graph is rebuilt after the walls finish opening.
- Contract **"Field Audit (procedural)"** on G01 — repeatable; every deploy gets a new seed (stored in the
  ledger so saves rebuild the same site).
- **Deus Ex-style service ducts** in procedural sites: the generator splits a 2-cell room next to the
  executive suite (or server room / lab) into a **washroom** + a **crawlspace duct** (ceiling 40u, dark, metal).
  32u-high vents join duct <-> washroom and duct <-> target room: crouch to crawl through; guards (56u) can't
  follow and the nav graph ignores ducts. HUD hint "Air duct - crouch to enter" near a vent.
- New room types: washroom (tiles, bright) and duct. G01 cells are now tagged (7000 + j*NX + i) so the
  generator can change cell ceilings.
- **Grid v2 / office-floor planner** (after first playtest): G01 now has per-column/row sizes — a 112u
  corridor spine (row 4), a 112u branch-corridor column (col 4), and two 64u service lanes (rows 2 and 7).
  Layout is a double-loaded corridor: rooms are 1–3-column slices running from the corridor to the outer wall,
  40% split into front + back suites; branch corridor north (70%); extra adjoining doors cut to 8% and only
  between side-by-side rooms in the same band.
- Service ducts now run along the 64u lane under a run of 3–4 columns (75% of sites): executive suite above
  the run, washroom below one end, vents into both. Server rooms lit (104 + ceiling light). Props only go in
  full-size cells (corridors and lanes stay clear).
- `cw_procseed` CVar: seed used when loading G01 directly (0 = random).
### Added
- **Navigation graph + pathfinding** (`nav.zs`): built automatically on level load from map geometry
  (doorways/openings, sector centres, grids inside big rooms, a line of nodes down corridors) plus optional
  hand-placed nodes (20003). Links use guard-width clearance traces; guards walk straight when clear and route
  with Dijkstra otherwise. Debug: `cw_navdebug 1` shows nodes (health-bonus markers) and prints graph size.
- **Room/door Layout API + prefab room library** in `genmap.py` (loading dock, storage, server room, corridor,
  lobby, open office, executive office, lab) — the basis for an X-COM-style prefab map assembler.
- `render_map.py`: top-down PNG preview of generated maps.
- **M02 "Castellan Systems: R&D Annex"**: 8 rooms, 9 doors, 8 guards, 4 civilians + recruit target.
- **Contract "Black Ledger"** (Oriole vs Castellan, High security, $700): steal the ledger $9,000 or wipe the
  servers $4,000; recruit the night auditor $2,500 bonus; civilians protected ($1,500 each).
- Per-contract objective names and prompts (`objName`, `stealItem`, `turnName`).
### Fixed
- Props blocking doorways in M02: the Layout tool now validates every map — keeps an 80-unit clear zone in
  front of each doorway, keeps props inside their room and off each other, slides offenders along the wall
  (or drops them) and reports each change.
- Weapon cycling / slot selection: explicit weapon slots in KEYCONF (1 fist/taser, 2 service pistol,
  3 tranq/shotgun, 4 SMG); the service pistol had no slot of its own.
- `objName`/`nav` field-method name clashes; added `CorpoWars_tools/check_names.py` to catch these.
### Changed
- G02 rescaled to Doom proportions (it felt like a giant's office): doorways 80u (was 112) with door art
  resized to match, rooms 96-104u (was 116-128), tall spaces 136-176u (was 160-192), window header 88u,
  sill 28u. Wall signs/posters moved down so they sit inside the lower walls.
- "Field Audit (procedural)" now deploys to the G02 office floor (G01 stays loadable with `map G01`).
- Two-sided lines now get upper/lower wall textures (needed for rooms with different ceiling heights).
### Removed
- **Suppressed pistol** archived (superseded by the universal Suppressor on the service pistol).
  Code moved to `zscript/archive/CW_SuppressedPistol.zs` (not loaded); no longer sold.
### Changed
- Existing saves: an owned suppressed pistol converts into a Suppressor in the locker, or is refunded
  ($1,200) if you already own a Suppressor. Item id kept reserved so saves stay compatible.
- Deploy weapon priority is now service pistol > tranq > fists.

### Changed
- "Field Audit (procedural)" now deploys to the G02 office floor (G01 stays loadable with `map G01`).

### Fixed
- G02: crawl ducts are now a narrow 64u channel (the rest of the duct cell is sealed) instead of a full-width room.
- G02: desks/civilians no longer spawn mid-aisle in the open-plan ring; they sit against the interior-band wall.
- G01 generator was missing its `Adjacent`/`AddDoor` helpers (would not compile).

## [0.10.0] — 2026-09-26 — Taser & flashlight
### Added
- **Taser** (weapon, slot 1, 2x1, $700): hold fire point-blank; each zap staggers a guard, ~1 s of contact
  (4 zaps) knocks them out non-lethally; civilians drop on the first zap. 100-charge battery (~25 zaps),
  ~180u noise. Sprites/sounds/light/brightmaps from "Tazer" (DeVloek).
- **Flashlight** (gadget, 1x1, $150): L toggles a spotlight beam while holding any weapon. While on,
  your visibility can't drop below 85%. Auto-off if removed from the kit. Sounds/icon from "Flashlight" pack.
- Keybind L (flashlight).
### Fixed
- Restored `CW_Items.CrewKit()` (accidentally removed with the MP5 icon-swap code).

## [0.9.0] — 2026-09-26 — Universal suppressor & attachments
### Added
- Universal **Suppressor** attachment ($900, 1x1). V fits/removes it on the weapon in hand using the
  reload-dip animation. One suppressor = one weapon; fitting it elsewhere moves it.
- Compatible weapons: service pistol (11 dmg, ~220u) and SMG (7 dmg, ~260u, custom `silence_shot.ogg`).
  Suppressed shots have no muzzle flash/light.
- `CW_Suppressible` mixin + `ToggleSuppressor` / `FireSilenced` states pattern for future weapons.
- HUD: "[V] Weapon SUPPRESSED" / "[V] Fit suppressor".
### Changed
- The former "SMG suppressor" item became the universal Suppressor (saves carry over).
### Removed
- Per-weapon icon swapping (silenced MP5 icon).

## [0.8.0] — 2026-09-26 — Weapon graphics overhaul & loud guns
### Added
- **Pump shotgun** (slot 3, 4x1, $1400): 6-shell tube, shell-by-shell reload interruptible by fire,
  8x6 pellets, ~1400u noise.
- **Submachine gun** (slot 4, 3x2, $1800): 30-round mag, full auto, 8 dmg, ~1400u noise.
- **Shell box (8)** ammo item ($80).
- Service pistol reloading: 12-round magazine (R).
### Changed
- Weapon art/sound packs: service pistol = Glock 19, suppressed pistol = Silenced Pistol,
  shotgun = Duke Shotgun, SMG = MP5, tranq rifle = UAC Sniper Rifle (4x scope). Pickup sprites used as icons.
- Stock Doom pistol is swapped for the service pistol on map load.
- Credits for all packs in CREDITS.txt.

## [0.7.1] — 2026-09-26 — Service pistol in the inventory
### Added
- **Service pistol** inventory item (2x1, $300), seeded into the personal kit for new and existing saves.
- Custom pixel-art pistol / suppressed pistol sheets; `CorpoWars_tools/slice_pistols.py` slicer.
### Changed
- Ammo on deploy now comes only from packed items (pistols start with one loaded magazine).
- Deploy weapon priority: suppressed pistol > service pistol > tranq > fists.

## [0.7.0] — 2026-09-26 — Grid inventory (Locker / Transport / Personal)
### Added
- Quartermaster LOADOUT tab: drag items between LOCKER (unlimited list), TRANSPORT (6x4) and
  PERSONAL KIT (6x3); R / right-click rotates; mouse wheel scrolls; SHOP tab buys into the locker.
- Only the personal kit is issued on deploy; ammo/dart packs load when carried; gadgets/medkit consumed from the kit.
- Crew kits (Nyx rig 2x2, Marrow kit 2x1, Vox kit 2x1) must ride in the transport; deploy is blocked otherwise.
- Field resupply: transport crate (20025) at the insertion point opens TRANSPORT <-> PERSONAL mid-mission.
- Field medkit (J, +40 health).
- Legacy gear migrated into items automatically.
### Fixed
- `invInit` field/method name clash (ZScript is case-insensitive).
- Transport crate USE no longer aborts the mission; crate moved out of the extraction zone.

## [0.6.1] — 2026-09-26 — DeePayback weapon assets
### Changed
- Suppressed pistol and tranq rifle rebuilt with DeePayback sprites/sounds; pistol magazine + reload;
  tranq became a bolt-action rifle with alt-fire scope. R bound to reload.

## [0.6.0] — 2026-09-26 — Quartermaster (gear locker)
### Added
- Quartermaster at the office workbench: suppressed pistol ($1200), tranquilizer ($1500), body armor ($600),
  noisemaker ($150, G), flashbang ($250, H: 5 s stun on guards with LOS).
- Tranq darts: target drops after 2 s, non-lethal. Guard stun state.

## [0.5.0] — 2026-09-26 — Rules of engagement
### Added
- Contract fines: unauthorized objectives, per guard killed, per civilian killed; civilian protection is a
  per-contract toggle (`protectCivilians`).
- **Civilians** (20024): witnesses who scream and alert guards, flee, can be knocked out from behind.
- Guards find civilian bodies. Killing Dr. Vance fails the recruit objective.
- Sectioned debrief: EARNINGS / RULES OF ENGAGEMENT | FIELD REPORT / ACCOUNT.
### Fixed
- Hitscan kills weren't credited to the player (puff had no owner); NPCs now record player damage.

## [0.4.0] — 2026-09-26 — Intel & operatives
### Added
- Terminal tabs CONTRACTS | INTEL | OPERATIVES.
- Intel: Site survey (automap + objectives on radar), Patrol schedule (guards on radar). Heading-up radar HUD.
- Operatives (max 2): Nyx (B blackout 20 s), Marrow (bodies removed), Vox (N noise lure x3).
- Ceiling lights spawn real dynamic lights (affect stealth, cut by blackout).
- Terminal colour coding: corp colours, security rating, objective type chips, projected budget.
### Fixed
- Terminal text overflowing the panel / covering the deploy button.

## [0.3.0] — 2026-09-26 — HUD, terminal menu & HQ art
### Added
- Full-screen Acquisitions Terminal menu (contract list, brief, payouts, deploy, debrief).
- HQ prop sprites (16 props, 20100–20115), briefing-monitor and gear-panel wall textures, command-desk terminal.
### Changed
- HUD moved to NewSmallFont with auto-sized panels; compact office card.

## [0.2.0] — 2026-09-25 — Contract loop
### Added
- HUB01 (Meridian office), M01 (Oriole Helix lab), persistent ledger (budget, contracts).
- Objectives: steal prototype, destroy server, turn Dr. Vance; extraction/abort.
- Payout: best primary + bonuses, ghost +25%, alarms -10% each, no-kill +15%. Interaction prompts.

## [0.1.1] — 2026-09-25 — Guard tuning
### Changed
- Test map walls/doorways, darker corridor, spawn grace, reduced long-range detection.
- Guard steering around obstacles; skip unreachable patrol points; lamps moved off routes.

## [0.1.0] — 2026-09-25 — Stealth prototype
### Added
- Fork of Universal Enhanced AI 1.1.1 (MIT).
- CW_Guard: unaware → suspicious → alert; vision cone, light/crouch/speed visibility, patrols (20001/20002).
- Noise system (gunfire, footsteps), takedowns from behind, body discovery, sneak-attack bonus.
- Visibility HUD meter, CWTEST test map.
