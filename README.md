# New Bricks City

A roguelite squad FPS mod for **UZDoom** (a GZDoom fork). The police are losing a megacity of twenty
million to its gangs. You are an undercover detective running what's left of a gutted department: you pick
your officers, fit them out from a cage of seized guns, and lead raids into **the Bricks**, a walled-off
district of brick housing towers. Each raid topples a gang or costs you officers. Thirty days later the
demolition crews roll in either way.

> **Status:** in development. The core loop is playable: a case, raids on generated districts, a squad of
> individual officers with ranks and perks, an evidence locker, Ghost Recon-style squad orders and a polished
> set of precinct screens. Much of it still needs a human playtest. `docs/STATUS.md` has the live state.

---

## Contents

- [The pitch](#the-pitch)
- [How a case plays](#how-a-case-plays)
- [Getting started](#getting-started)
- [Controls](#controls)
- [The squad](#the-squad)
- [Squad orders](#squad-orders)
- [The motor pool](#the-motor-pool)
- [Time of day](#time-of-day)
- [The precinct screens](#the-precinct-screens)
- [The gangs](#the-gangs)
- [The districts](#the-districts)
- [Weapons and gear](#weapons-and-gear)
- [Repository layout](#repository-layout)
- [How the code fits together](#how-the-code-fits-together)
- [Building levels with Obsidian](#building-levels-with-obsidian)
- [Testing and tools](#testing-and-tools)
- [Contributing](#contributing)
- [Credits and licensing](#credits-and-licensing)

---

## The pitch

Budgets were cut year after year, precincts closed, and whole districts were handed to the gangs. The worst
of it is the Bricks. Fifteen years ago the city poured a concrete wall around its poorest district and pulled
everything out. The towers inside now belong to a kingpin called the Landlord, and City Hall has signed a
demolition order: in thirty days the Bricks gets leveled, along with everyone still living there.

All that's left of the department on this side of the city is **Checkpoint 9**, a half-shut police post
built into the Wall. You're **Detective Jordan Vance**, an undercover narcotics cop who grew up two blocks
from the wall. No backup is coming. You run raids with whatever you can scrape together: seized guns, a
handful of officers in their own clothes, and whatever the last raid brought back.

It's a dystopian near future. The officers are ragtag and plain-clothed, with only a loose mark of the
police (a faded armband, a badge on a chain). Nobody gets a modern uniform.

*Setting inspiration:* Brick Mansions. *Tone:* Dirty Harry, Bad Boys II, Den of Thieves. *Mechanics and
screen layouts:* Hamburger Hill (the indie roguelite) and Ghost Recon (2001). Every name, character, line of
dialogue, image and sound in the mod is original.

## How a case plays

1. **New Game** (pick how hard the Bricks hit back: Rookie, Patrol, Detective or Internal Affairs) starts you at
   Checkpoint 9, the precinct. Captain Harrow, Rook the pilot and your officers
   who are fit for duty are there; talk to them with Use. Use the **raid board** (or the captain) to open a
   case. A seed deals the four gangs across eight districts.
2. **Plan a raid.** Pick a district on the raid board. Its dossier shows the gang, its leader, its tier,
   how alert it is, how many are on the block, what works on them and how they keep the clock (how many are
   out and how many are off guard at each hour). The day's event, if there is one, is flagged on its district.
3. **Deploy.** Choose up to four officers, split them into fireteams ALPHA and BRAVO, and fit everyone out
   (you included) from the Evidence Locker. Press **READY** to lock in the plan.
4. **Roll out.** Walk to Rook, the pilot, and talk to them. Choose **when** (morning, afternoon, dusk or
   night; the day's event fixes the hour in its district), the insertion and the motorcade:
   **STREET** (land vehicles, the raid starts on the street) or **ROOFTOP** (a helicopter: the raid starts on the
   district's roofs, but it can be shot down, and a crash landing turns into a survival ambush round the wreck).
   The vehicles' seats have to carry everyone. **ROLL OUT** / **WHEELS UP** starts the raid.
5. **The raid.** You land in the district with your squad behind you. The game clears the map's own
   monsters and fills it with the holding gang. The leader waits near the exit with escorts, and
   reinforcements come once most of the crew is down. Command the squad, take down the leader and leave
   by the exit to **topple** the gang. Leaving with the leader alive is a **retreat**, and the gang goes
   on alert. A lethal hit means **OFFICER DOWN**: you're pulled out with a strike against you.
6. **The after-action report.** You get a grade, kills, time and health lost. Officers earn XP, go to
   the hospital, or go onto the memorial wall. Everything you carried goes back into the locker, and on a
   taken block the evidence team bags what the gang dropped. You also get the cash and the bounty.
7. **Between raids:** promote officers (each promotion picks one of two perks), recruit new ones, sell
   seized guns and requisition supplies, or **close the day** to let the squad heal.
8. **The case ends** when every gang is down (case closed), after three strikes (Internal Affairs takes
   your badge), or on day 30 (demolition). Officers who survive carry over to your next game.

## Getting started

### What you need

- **UZDoom 5.0.3.** The repo carries `UZDoom-5.0.3.zip`; unzip it into the repo root so `uzdoom.exe`
  sits next to `Launch.bat`. The engine files are gitignored.
- **Freedoom 2** as the IWAD: put `freedoom2.wad` (Freedoom 0.13.0, https://freedoom.github.io/) in
  `freedoom-0.13.0/`. That folder is gitignored too.
- **Python 3** for the tools (`check_lumps.py`, `build_pk3.py`, the map scripts). Pillow is only needed
  for `tools/art/`.

### Play (Windows)

```powershell
Launch.bat                                                      # menu: pick a map, cheats, skill, tests, build
powershell -File tools\run.ps1 -Map NBC_HUB                    # Checkpoint 9, where New Game starts
powershell -File tools\run.ps1 -Extra "+give all"              # the test room (the default map) with every weapon
.\uzdoom.exe -iwad freedoom-0.13.0\freedoom2.wad -file nbc       # the same by hand (the mod loads as a folder)
.\uzdoom.exe -iwad freedoom-0.13.0\freedoom2.wad -file nbc +map NBC_CT05   # straight into a district
```

### Play (Linux)

Build UZDoom 5.0.3 from source (see the notes in `docs/STATUS.md`), then:

```bash
/path/to/uzdoom -iwad freedoom-0.13.0/freedoom2.wad -file nbc
```

### Release build

```powershell
python tools\build_pk3.py      # -> dist\NewBricksCity.pk3
.\uzdoom.exe -iwad freedoom-0.13.0\freedoom2.wad -file dist\NewBricksCity.pk3
```

## Controls

Every key below is rebindable under **Options → Customize Controls → New Bricks City**.

| Key | Action |
|---|---|
| WASD, mouse | move, look (UZDoom defaults) |
| Mouse 1 | fire |
| R | reload (every firearm has a magazine and draws from a shared reserve) |
| E | use (the raid board, the lockers, the squad-room sofa, doors) |
| 1-6 | weapon slots: 1 melee, 2 pistols, 3 shotgun, 4 SMG, 5 rifle, 6 Molotov |
| F | flashlight |
| F1 | how to play: the keys as bound, and the job |
| G | quick-throw debris: tap for a lob, hold to wind up a harder throw |
| H | cycle the debris type (brick, half brick, concrete, bottle) |
| Enter | use the selected inventory item (a medkit) |
| **Q** | squad: talk to ALL / ALPHA / BRAVO |
| **Z** | squad: regroup on me |
| **C** | squad: hold position |
| **V** | squad: move to where you're aiming |
| **N** | squad: advance along the plotted waypoints |
| **B** | squad: rules of engagement (Recon → Assault → Suppress) |
| **J / K / L** | squad: call go code X-Ray / Yankee / Zulu |
| **M** | squad: the command map |

**In the menus:** the mouse hovers and clicks, the wheel scrolls and right-click backs out. On the keyboard
or a pad, the arrows move to the nearest control in that direction, Enter uses it, Esc backs out, and
Q / E (or Tab) switch tabs.

## The squad

Every officer is a person, Hamburger Hill / XCOM style:

- **A name, a face and their own clothes.** There are 144 pixel portraits (no two alike on the roster), and
  each officer's sprite wears one of eight plain-clothes outfits, the same on raids and at the HQ.
- **They never block you** (or each other) and, when one gets stuck or left behind while following you, they
  step in behind you.
- **A class:**

  | Class | Issue weapon | Role |
  |---|---|---|
  | Patrol | service SMG (bursts) | all-rounder, sticks close |
  | Breacher | service shotgun | front of the stack, home-made plate carrier, the most health |
  | Marksman | service rifle (single heavy shots) | long sightlines, best aim |
  | Paramedic | light SMG | patches you up when you drop under half health |

- **Rank and XP.** Officer → Corporal → Sergeant → Lieutenant, at 60 / 160 / 320 XP. Officers earn 10 XP
  per kill, 20 for coming back and 15 when the leader goes down. Rank adds health, aim and pouch slots.
- **Perks.** Each promotion offers two perks for the class: Steady Hands, Tough as Nails, Kevlar Faith,
  Hollow Points, Trigger Discipline, Speed Loader, Hair Trigger, Field Dressing, Packrat or Long Watch.
- **A kit.** Each officer has a primary (the class's issue weapon or a seized gun the class can use),
  pouches (medkits and Molotovs) and an optional Kevlar vest. Officers use their medkits when hurt and lob
  Molotovs at bunched-up gang members (never near you).
- **Wounds and death.** An officer below 70% health spends a day in the hospital, and one below 40%
  spends two. An officer who goes down might be pulled out alive (CRITICAL, four days). The odds are
  better on a block you took and better for higher ranks. Otherwise they're **killed in the line of
  duty**: their kit is lost and their name goes on the memorial wall.
- **Your own face:** pick any portrait for Det. Vance (YOUR FACE in the squad room, FACE on the deploy screen).
- **The roster** holds up to 16 officers, recruited for cash between raids. Officers who survive carry
  over to your next game (`nbc_roster` and `nbc_memorial` CVars).

Officers never hurt you or each other, fire doesn't touch them, and they find their own targets (the
engine's FRIENDLY monster AI isn't used).

## Squad orders

The command system follows **Ghost Recon (2001)**:

- **Fireteams.** The squad splits into **ALPHA** and **BRAVO**, set on the deploy screen. Your keys talk
  to the team you select with Q.
- **Orders.**
  - **Regroup**: follow you.
  - **Hold**: stay where they are.
  - **Move**: go to the spot you're aiming at. A ring of light marks it.
  - **Advance**: walk the team's waypoint path.
- **Rules of engagement.**
  - **Recon**: weapons tight. They only return fire, throw no Molotovs, and move slowly and quietly.
  - **Assault**: engage at will.
  - **Suppress**: longer, wider bursts, sustained fire on where a target was last seen, and targets
    flinch under it.
- **The command map** (M) runs in real time. It's a top-down view of the district with the walls, the
  exit, your officers, what the squad has spotted, and each team's path. Click to plot waypoints, drag
  to pan, scroll to zoom. The panel sets each team's order and rules of engagement.
- **Go codes.** Put **X-Ray**, **Yankee** or **Zulu** on a waypoint, and a team advancing on its path
  stops there and waits ("BRAVO: At waypoint 2. Waiting on X-RAY.") until you call the code (J / K / L or
  the map). That lets you stage a two-team entry.
- **The HUD:**
  - squad portraits with an A or B badge, and a line per team with its order and rules of engagement
  - Ghost Recon's **threat indicator**, a ring at the bottom of the screen with a mark for every gang
    member the squad can see (red: it's after one of you)
  - a squad radio log

Officers route through the districts over a navigation graph (ported from Corpo Wars). It is built
automatically on every map.

## Checkpoint 9

The precinct is a place with people in it:

- **Captain Harrow** stands by the raid board with a cigar. Talk to him for the state of the case (the day,
  the gangs left, strikes, who's in the hospital, who's due a promotion). Talk again for the raid board.
- **Rook, the pilot,** waits by the door out to the pad. Once a raid is planned (READY on the deploy screen),
  talking to Rook brings up the **wheels-up check**: the district, the gang, everyone going in. WHEELS UP
  starts the raid.
- **Your officers** who are fit for duty stand around the precinct in their own clothes, at the desks, in the
  squad corner, by the lockers. Talk to one for a line about how they're doing. Talk again to open the squad
  room on their service file. Officers in the hospital aren't there.
- **The raid board, the lockers and the squad-room sofa** open the precinct terminal.

## The motor pool

Raids roll out as a motorcade. Buy, repair and sell vehicles at the terminal's **MOTOR POOL** tab; a case starts
with a panel van and an unmarked sedan.

| Vehicle | Seats (you included) | Price | On a raid |
|---|---|---|---|
| Unmarked sedan | 2 | $350 | you alone or with one officer, and it rides alone; low profile: fewer of them on the block |
| Panel van | 5 | $800 | room for you and a full squad |
| Armored truck | 5 | $2,200 | officers take less damage; never wears down |
| Helicopter | 5 | $4,000 | rooftop insertion, fewer of them up there; can be shot down |

- **Street insertions** park the motorcade out on the street nearest your start on the district map.
- **Rooftop insertions** fly you onto the district's own rooftop map (`NBC_RF01-08`). The shoot-down risk (shown
  before you go) grows with the gang's tier and alert and the helicopter's damage.
- **Shot down:** you come down in the street, hurt, next to the burning wreck, and the gang sends four waves at
  the crash site. Hold out until the way to the exit is clear and walk out. The helicopter is gone.
- Vehicles wear down on raids, go to the shop under 30% condition and are written off at 0.

## Time of day

Like Hamburger Hill's missions, every raid goes in at an hour: **MORNING** (07:00), **AFTERNOON** (14:00),
**DUSK** (19:30) or **NIGHT** (02:00). Pick it on Rook's roll-out screen; each hour shows what it does to the
gang you're hitting.

- **The gang keeps its own clock** (`strength` and `offguard` in `gangs.txt`): how many of them are out, and how
  many of those are off guard (asleep, high, half-watching). An off-guard member stands frozen and notices
  nothing until they're shot, someone fires nearby (they're up a few seconds later) or you walk right up to them.

  | Gang | Their hours |
  |---|---|
  | The Stoop Kings | out in force from dusk; sleeping it off until noon |
  | The Rust Saints | the night shift: full force after dark, thin and groggy in the morning |
  | The Iron Pit | they train at dawn and fight at night; dusk finds them worn out |
  | The Collectors | business hours: all in by day, a skeleton crew at night |

- **The block:** the sky (a morning, afternoon and dusk skyline, `tools/art/make_sky_variants.py`), the light
  (brighter by day, dark at night; the flashlight matters) and a tint.
- **The squad:** officers see less far and shoot wider at dusk and at night.

**The day's event.** Most mornings from day 2, something is going down somewhere (the case RNG). Raid that
district today and you go in at its hour, in its situation:

| Event | Hour | What it means |
|---|---|---|
| Gang war | dusk or night | a rival crew hit them: 30% fewer, and the rest are hurt |
| Crowded streets | afternoon or dusk | the crowd covers you (30% more off guard), but the first shot wakes the whole block; fire in a crowd is a strike |
| The deal | any | the leader's out with two more guards; double the bounty |
| Blackout | night | the power's out: darker still, 20% more off guard |
| Officer pinned down | morning or afternoon | everyone's awake and waiting. Urgent: leave it and it's a strike; get the unit out and City Hall pays $400 |

The radio calls it in when you're back at Checkpoint 9, the captain brings it up, the HUD shows it, and the raid
board flags its district.

## The precinct screens

All the screens share one look (slate-blue panels, amber selection, stencil titles), and their layouts
follow Hamburger Hill's:

- **The title and main menu:** the New Bricks City splash, with NEW GAME, LOAD, OPTIONS, HOW TO PLAY, CREDITS and
  QUIT along the bottom (RESUME and SAVE in a game). The engine's own option, load and save screens and its
  yes / no boxes wear the same colours.
- **The HUD:** one bar along the bottom: your face, health and vest; your pouches and the debris; the weapon,
  its magazine and the reserve.
- **Music:** the title, Checkpoint 9 (a different track each day) and every raid have their own; a raid's track
  follows the hour it goes in at.

- **The precinct terminal** opens at the raid board, the lockers or the squad-room sofa:
  - **Raid board:** the districts and their gangs, a dossier, plan a raid, close the day, start a new case.
  - **Squad room:** the roster as portrait cards, a service file with an XP bar, stats and perks, plus
    promote, recruit, bench and dismiss.
  - **Evidence locker:** every weapon, round and piece of gear you hold, with what's checked out to kits,
    sell for cash or requisition supplies.
  - **Motor pool:** the garage (condition, seats, ready or in the shop), repair, sell, and the dealer.
  - **Memorial:** the officers lost in the line of duty.
- **Deploy:** the roster, the squad (you plus four, AUTO, ALPHA/BRAVO badges) and the kit of whoever is
  selected. Each slot opens a picker showing what's left in the locker. The bottom bar shows the locker
  totals, BACK and READY.
- **Roll out** (talk to the pilot): the district, WHEN (the four hours with what each does to the gang), STREET
  or ROOFTOP insertion with the shoot-down risk, the
  motorcade (pick vehicles, seats needed), everyone going in, and ROLL OUT / WHEELS UP, CHANGE PLAN, NOT YET.
- **After-action report:** the outcome title, a stats table and letter grade, each officer's portrait
  with kills and KIA / CRITICAL / WOUNDED / PROMOTION stamps, the loot tiles, the cash, and CONTINUE.

## The gangs

Gangs are data: `nbc/gangs.txt` holds their rosters, traits, damage profiles, leaders and escorts.

| Gang | Tier | Trait |
|---|---|---|
| The Stoop Kings | 1 | Swarm: more of them on every stoop, but they drop fast |
| The Rust Saints | 1 | Pyros: fire and explosives, and fire won't touch them |
| The Iron Pit | 2 | Roiders: they shrug off stagger; fire hurts them half again |
| The Collectors | 2 | Vests: pistol and SMG rounds do less; bring shells or rifles |

Every attack has a damage type (`NBC_Light`, `NBC_Shell`, `NBC_Rifle`, `Melee`, `Fire`, `Blunt`), so the
right gun for the gang matters. The enemies themselves are the DeeDeeOZ **DeePayback** pack: thugs,
punks, goons and militia.

## The districts

Levels are generated outside the game by **Obsidian** with the mod's own **New Bricks City** theme, and
ship as `nbc/maps/NBC_CT01-08.wad`. `nbc/districts.txt` is the pool the raid board reads.

| Map | District | Environment |
|---|---|---|
| NBC_CT01 | Pike Water Towers | rooftops |
| NBC_CT02 | Fulton Junction | subway |
| NBC_CT03 | Mercer Block | streets |
| NBC_CT04 | Wexford Commons | park |
| NBC_CT05 | Sutter Storm Drains | underground (basements, sewers) |
| NBC_CT06 | Cypress Houses | housing towers |
| NBC_CT07 | Carver Row | streets |
| NBC_CT08 | Arden Docks | industrial park |

Each district also has a rooftop map for helicopter insertions, `NBC_RF01-08` ("<district> Rooftops"), paired in
`nbc/rooftops.txt`.

Other maps:

- **NBC_HUB**, Checkpoint 9, the precinct, built by `tools/make_hub_map.py`.
- **NBC_TEST**, a test room.
- **NBC_KT / KS / KB / KR**, the in-game "kit" generators (tower, street, basement, roof), kept as test
  maps only.

## Weapons and gear

The weapon roster is only the packs in `Weapons/`, ported to ZScript with magazines and reloads:

| Slot | Weapons | Ammo |
|---|---|---|
| 1 | Fists of Fury, Combat Knife, Machete | — |
| 2 | Colt .45, Dual Berettas (Dual 92s) | light rounds |
| 3 | Pump-action shotgun | shells |
| 4 | Micro-Uzi, MP5K-SD (suppressed; altfire cycles auto / burst / semi) | light rounds |
| 5 | AK-47, M16 (3-round bursts) | rifle rounds |
| 6 | Molotov cocktail | bottles (max 5) |

Also in the game:

- **Thrown debris** (G): bricks, half bricks, concrete chunks and bottles, picked up from rubble piles.
  Built on the FragGrenade pack's throwing code, with no explosion. Your gun drops out of view while the hand
  throws, and comes back up after.
- **Medkits** (40 health; officers carry them too).
- **Kevlar vests.**
- **The flashlight** (F): the Flashlight pack's beam and sounds on a key of its own rather than a weapon slot, so
  your gun stays in hand. At dusk and night the HUD reminds you it's there. The beam gives you away: shine it on a
  gang member who's off guard and they wake up. It needs dynamic lights (OpenGL or Vulkan).

## Repository layout

```
nbc/                    the mod, loaded as a folder (-file nbc); build_pk3.py zips it for release
  ZSCRIPT.zs            includes every script below (version "4.10")
  MAPINFO.txt, KEYCONF, CVARINFO.txt, SNDINFO.txt, GLDEFS.txt, TRNSLATE.txt, ...   root definition lumps
  gangs.txt             the gangs (data)
  districts.txt         the district pool for the raid board (written by the Obsidian exporter)
  zscript/nbc/          New Bricks City code (one system per file, NBC_ names)
  zscript/nbc/ui/       the precinct screens
  zscript/nbc/weapons/  the reloadable firearms
  zscript/cw/           code ported from Corpo Wars (furniture, kits, the nav graph; CW_ names)
  actors/               imported DECORATE (enemies, weapons, props)
  sprites/ sounds/ textures/ graphics/ models/ voxels/ brightmaps/
  maps/                 NBC_HUB, NBC_TEST, NBC_CT01-08 (Obsidian), the kit test maps
  CREDITS.txt           every asset's credit (never remove a line)
tools/                  launcher, smoke tests, lump checks, PK3 build, map builders, Obsidian pipeline
  Obsidian/             make_bricks.ps1/.sh, export_maps.py, addons/NewBricksCity/ (the Obsidian theme)
  art/import_npc_art.py the officer portraits and the HQ characters, from the owner's art in art/
  art/make_vehicle_art.py the motor pool's land vehicles
  import/               one-time import scripts (kept as a record; never re-run)
art/                    source art: the debris sprites' pxl file, the portrait sheets, the captain, pilot and helicopter
docs/STATUS.md          what's done, verified and waiting on a playtest
docs/hamburger-hill-analysis.md, docs/corpowars-port-map.md    design references
reference/              read-only source: Corpo Wars and the weapon packs' extra files (never loaded)
DeePaybackEnemies/, Weapons/   the original downloads (read-only)
PLAN.md                 the full design and the milestones
AGENTS.md               the rules for anyone (or any AI agent) working on the code
```

## How the code fits together

| System | File | What it does |
|---|---|---|
| `NBC_RunData` | `rundata.zs` | Case and raid state (a STAT_STATIC thinker): day, strikes, cash, gangs, districts, the raid, the squad's orders. All case randomness comes from its seeded RNG, so a seed reproduces a case. |
| `NBC_Department` | `dept.zs` | The roster (`NBC_Officer`), the memorial, the Evidence Locker, everyone's kit, the after-action report. Menus change it only through `nbc_dept.<op>` netevents. |
| `NBC_RunManager` | `runmanager.zs` | The loop: deploy → raid setup (gang spawns, leader, exit, your kit, the squad) → resolve (loot, XP, wounds, grade, report). Opens the menus from the UI side. |
| `NBC_Ally` | `ally.zs` | An officer in the field: class sprite and outfit, weapon profile, aim and perks, pouches, orders and rules of engagement, routing. |
| `NBC_Orders` | `orders.zs` | Squad commands (`nbc_cmd.<op>`), fireteams, waypoints and go codes, the radio log, contacts for the threat ring, the nav graph's owner. |
| `CW_NavGraph` | `cw/nav.zs` | The navigation graph built from the map's geometry; Dijkstra routes. |
| `NBC_UI` and screens | `ui/*.zs` | The screen framework, the terminal, deploy, results and the command map. |
| `NBC_StatusBar` | `hud.zs` | The magazine and debris readouts, the raid readout, the squad strip, the threat ring, the radio log. |
| `NBC_Motor`, `NBC_Vehicle` | `garage.zs` | The vehicle catalog, the garage's vehicles, seats, wear, the shoot-down risk, the crash site's fire. |
| `NBC_Clock`, `NBC_OffGuard` | `clock.zs` | The time of day (sky, light, the squad's sight), the day's events, gang members off guard. |
| `NBC_HQNpc` and kin | `hq.zs` | The captain, the pilot and the officers at Checkpoint 9: talk lines, the pilot's wheels-up step. |
| `NBC_Player` | `player.zs` | The player class: weapon slots, flashlight, quick throw, the OFFICER DOWN intercept. |
| `NBC_Gangs` | `gangs.zs` | Reads `gangs.txt` and `districts.txt`; gang damage profiles. |

Scope rule: game state changes only in **play** scope. The HUD and menus are **ui** scope; they read
state and send changes as network events.

## Building levels with Obsidian

The districts come from a source build of Obsidian (github.com/obsidian-level-maker/Obsidian) and the
mod's theme addon in `tools/Obsidian/addons/NewBricksCity/`. The theme swaps Doom's prefabs and textures
for New Bricks City ones across seven environments (streets, towers, rooftops, industrial, parks,
underground, subway), with per-building facades.

```powershell
powershell -File tools\Obsidian\make_bricks.ps1                                   # Windows, the GUI build's obsidian.exe
tools/Obsidian/make_bricks.sh --length episode --seed 2026 --limit 8             # Linux, a console source build
tools/Obsidian/make_bricks.sh --theme nbc_rooftops --length single --no-export   # try one environment
tools/Obsidian/make_bricks.sh --name roofs --length episode --seed 3131 --theme nbc_rooftops --no-export
python3 tools/Obsidian/export_maps.py tools/Obsidian/out/roofs.wad --prefix NBC_RF --pair-with NBC_CT --limit 8   # the rooftop set
```

`export_maps.py` splits a build into `nbc/maps/NBC_CTxx.wad` and writes `nbc/mapinfo/city_maps.txt` and
`nbc/districts.txt`. The game doesn't use Obsidian's monster layer: their spots are refilled with the raiding
gang at raid time. See `tools/Obsidian/addons/NewBricksCity/README.md` for the theme itself.

## Testing and tools

```powershell
python tools\check_lumps.py                                    # static checks: duplicate lumps, sounds, classes, DoomEdNums, sprites
powershell -File tools\smoke_test.ps1 -Map NBC_TEST,NBC_HUB    # boots UZDoom per map and fails on any script error
tools/smoke_test.sh NBC_TEST NBC_HUB NBC_CT05                  # the same on Linux (headless, xvfb)
python tools\list_textures.py BRICK                           # find texture names
python tools\build_pk3.py                                      # release build
```

Debug netevents, from the console:

| Command | Effect |
|---|---|
| `netevent nbc_debug_case` | print the case, the roster, the locker, the teams' orders and every officer |
| `netevent nbc_terminal <0-4>` | open the precinct terminal on a tab |
| `netevent nbc_debug_clear <n>` | on a raid: down the leader and n of the crew (0 = all) |
| `netevent nbc_debug_cash <n>` | add seized cash |
| `netevent nbc_deploy <district> <force>` | start a raid now (force 1: never shot down, 2: shot down) |
| `netevent nbc_debug_event <kind> <district> <hour>` | set today's event (0 none, 1 gang war, 2 crowd, 3 deal, 4 blackout, 5 pinned; hour 0-3) |
| `netevent nbc_debug_motorcade` | on a street raid: stand back from the parked motorcade |
| `nbc_seed <n>` | every new case uses this seed |
| `nbc_navdebug 1` | show the squad navigation graph's nodes |
| `nbc_kittest <kit> <variant> <seed>` | generate a kit test floor |

## Contributing

Read **`AGENTS.md`** first (the project's rules), then **`docs/STATUS.md`** (what's done and what's
next), then the milestone in **`PLAN.md`**. In short:

- New code is ZScript in `nbc/zscript/nbc/`, one system per file, with every class, CVar, sound and lump
  prefixed `NBC_` / `nbc_`.
- Gangs and districts are data files, not code.
- Map things use DoomEdNums from 26000.
- Never edit `reference/`, `DeePaybackEnemies/` or `Weapons/`, and never re-run `tools/import/`.
- Before calling anything done: `check_lumps.py` must report 0 new problems and the smoke test must pass
  on every map you touched. List anything that needs a human to play under "Needs playtest" in
  `docs/STATUS.md`.

## Credits and licensing

New Bricks City is a **free** fan mod. It must never be sold or bundled with anything paid: some recycled
textures carry no formal licence.

- **Enemies:** DeePayback Enemies by DeeDeeOZ, and the many sprite and sound authors listed in its credits.
- **Weapons:** the AK47, Colt45, CombatKnife, DualBerettas, FistsOfFury, Flashlight, Machete, MicroUzi,
  MP5kSD, Molotov, PumpActionShotgun, Vanilla M16 and FragGrenade packs, each with its authors' credits.
- **Corpo Wars** (the project owner's earlier mod): props, furniture, textures, the kit generator and the
  navigation graph, plus the packs it credits. Universal Enhanced AI is MIT
  (`reference/corpowars/LICENSE-UEAI.txt`).
- **Font:** "Miniplicity" by Jimmy, after the Ultimate Simplicity bigfont by Agent Spork.
- **Levels:** generated with Obsidian (GPL).
- **IWAD:** Freedoom (BSD), not shipped.
- **Engine:** UZDoom.
- **Original to this project:** the code, the officer portraits, the captain, pilot and helicopter art (by
  the project owner), the debris art, the hub and test maps, and the Obsidian theme.

The full, line-by-line list is in **`nbc/CREDITS.txt`**. Every asset added to the mod gets a line there,
and no line is ever removed.
