# Building Types & Mission Sites (v4, 2026-09-27)

Planning only. Every map type in the game. Which properties use which type is in **city-roster.md**. Neutral-site rules are in **neutral-sites-and-odd-jobs.md**. G02 (office floor) and G05 (garage) cover the office-plate types (group 1). Everything else now runs on six **site kits**, K01–K06; see **site-kits.md** for the kits, their variants and how to add one.

Corp properties use a **fixed seed per save**. Neutral sites use a **fresh seed per job**. Security for corp sites = subsidiary guard force + tech level; "security style" says how it's used.

---

## A. Corp property types (67 properties)

### Group 1: Office-plate variants (cheap: reuse G02's plate and core)
| Type | Count | Rooms | Security style | Signature objectives |
|---|---|---|---|---|
| **HQ** | 6 | as office, plus executive floor | tighter on the exec floor | steal from exec suite, recruit/extract CEO |
| **Office tower** (G02, built) | 12 | open plan, offices, exec suites, conference, server room, lobby | standard | steal, wipe servers, recruit/extract head |
| **Clinic** | 4 | reception, exam rooms, wards, locked pharmacy, records, trial lab | light guards, many civilians | steal trial data, plant evidence, extract a doctor |
| **Studio** | 3 | sound stages/arena, control room, edit suites, archive | light, crowded | steal/wipe footage, hijack a broadcast |
| **Training centre** | 1 | firing range, gym, lockers, armory, classrooms | many alert guards, high tech | steal doctrine, sabotage armory |
| **R&D site** | 2 | test labs, prototype workshop, vault | high tech, maglocks everywhere | steal prototype, sabotage test rig |

### Group 2: Purpose-built interiors (medium)
| Type | Count | Layout | Security style | Signature objectives |
|---|---|---|---|---|
| **Lab** | 4 | clean rooms behind airlocks, specimen vault, cold storage, decon | access tiers per zone | steal specimen, sabotage cold storage, extract a scientist |
| **Data centre** | 5 | server halls, cooling plant, power room, NOC, cage vault | few guards, high tech, drones later | wipe/steal data, sabotage cooling/power |
| **Underground farm** | 2 | tiered grow halls under grow lights, nutrient tanks, seed vault, climate control, packing floor | low guards, many workers, lots of plant cover; grow-light cycles change visibility | steal the strain vault, sabotage climate control, extract an agronomist |
| **Bunker** | 2 | blast doors, checkpoint, concrete corridors, armory vault, test range, command room, vents | toughest sites: elite guards, blast doors (hack or blackout only) | steal a prototype, sabotage the range, steal records |

### Group 3: Industrial lots (new outdoor generator + prefab chunks)
| Type | Count | Layout | Security style | Signature objectives |
|---|---|---|---|---|
| **Storage warehouse** | 6 | rack aisles, forklifts, mezzanine office, loading bays, cold room, fenced yard | low guards, yard patrols, workers | steal manifests or a shipment, find a stash |
| **Sea dock** | 2 | quay and cranes, container stacks, a berthed cargo ship, customs shed | patrols, foreign crew, deep cover in the stacks | intercept a shipment, board the ship, sabotage a crane |
| **Fabrication facility** | 5 | fab floor, robotic lines, materials store, QA lab, control and power rooms | automated, many maglocks, drones later | steal designs, sabotage the line |
| **Power plant** | 4 | turbine hall, control room, switchyard, cooling towers, catwalks | medium–high, blackout-resistant | steal plant designs, sabotage a turbine |
| **Substation** | 3 | fenced switchyard, control hut, cable vault | few guards, electrified hazards | quick sabotage, plant a monitor |
| **Industrial park** | 4 | several compounds on one lot: sheds, pipe racks, tank farm, rail spur | mixed per compound | rail-yard and range jobs, grab-and-go, meets |
| **Salvage yard** | 2 | scrap maze, crusher, workshop, office trailer | loose, gang-adjacent | recover an item, plant evidence |

Special wing: **hidden drug lab** behind a false wall (inside the Kestrel clinic; possible in farms and warehouses).

Prefab chunks for group 3: warehouse, rack aisle, container stack, quay edge, ship section, fab hall, turbine hall, tank farm, gatehouse, scrap maze. Reuse the garage's concrete, pillars and voxel vehicles.

---

## B. Neutral site types (generated per job)
Small maps, one area, one day per job. Tech level 1–2, no maglocks or passes, many civilians.

| Site | Typical districts | Layout |
|---|---|---|
| **Construction site** | MR, HL | scaffolding, half-built floors, cranes, site office |
| Alley block | OQ, IS | street and back alleys, fire escapes, shops |
| Tenement | OQ, IS | 3–5 floors of flats, stairwell, roof, boiler room |
| Apartment block / luxury apartment | MR, EG | lobby, concierge, apartments, penthouse (executive homes) |
| Hotel | MR | lobby, bar, restaurant, rooms, service corridors, roof |
| Bar / club | IS, OQ | bar floor, VIP room, back office, cellar |
| Street market / mall | OQ / MR | stalls or shopfronts, crowd, back rooms |
| Restaurant / pawn shop / car wash | any | small commercial sets |
| University / hospital / library | EG / any | lecture halls or wards, archives, offices |
| Transit hub | HL | concourse, platforms, service tunnels |
| Union hall | IS, HL | meeting hall, offices, records room |
| Hacker den | EG, MR | converted flat or basement, server closet, roof escape |
| Rooftops | any | connected roofs, water towers, skylights |
| Sewer / tunnels / rail underpass | HL, IS | maintenance tunnels, platform, service rooms |
| Parking structure | any | levels, ramps, cars, booth |
| Drug lab / chop shop / gambling den | OQ, IS | illicit sets; drug-lab chemicals ignite under gunfire |

Minor-player **strongholds** use these types (bar, drug lab, union hall, hacker den, meeting hall) with a fixed seed while held.

Built from a **street chunk kit** (street, alley, shopfront, tenement stack, courtyard, rooftop set, tunnel segment) plus bigger sets (construction site, hotel, transit hub).

---

## C. Enemy roster from DeePaybackEnemies
Source: `C:\Games\Corpo Wars\DeePaybackEnemies` (actors, sprites, sounds). Take sprites and sounds only, recolour via `trnslate.txt`, run on our own guard AI and balance, and credit in CREDITS.txt.

| Faction / site | Look (DeePayback actors) | Notes |
|---|---|---|
| Rustline Crew | StreetThugM/F, Banger, robberM, killerM, GangBike; Roider muscle | pistols/SMGs; bikers at night in Ironside |
| Local 9 | street civilians (eSTREETM/F) as stewards; Roider / Enforcer heavies | mostly unarmed; hostile only when you're against them |
| NullSet | Hoody / Punk lookouts; Edrone drones (later) | flee and raise alarms |
| Tenants' Assoc. | street civilians, Tramp, Scum | civilians, protest crowds, never armed |
| Private muscle | MobUzi/Pistol/Revolver, HitmanTommy/Shotgun, YardieUzi, YakuzaUzi | hired guns at illicit sites and meets |
| Sea dock crew | RussianM/F, Bandit | ship crew, dock guards |
| Elite security (Bastion, Castellan) | Elite1/EliteF1, EliteShotgun, BadassElite, PMCBig, Sniper | bunker, training centre, high-tech floors |
| Automated security (Lattice) | Edrone | tech-level-4 sites |
| Response teams / EarthGov | PMCdude, Enforcer, Jetpacker (rare) | extraction ambushes, seized property |

Voices from the matching `sounds/enemies` sets. Avoid the demon/boss-flavoured sounds.

---

## Maps plan: site kits (built 2026-09-27)
Six kit generators replace the per-site generators planned above. The kits were sized from a count of 1,419 simulated jobs by map theme: street 24%, office 16%, underground/transit 16%, industrial 15%, residential 12.5%, civic 10%, tech 5.5%, mall 2%.

| Kit | Covers |
|---|---|
| G02 office floor (existing) | HQ, office, clinic, studio, training centre, R&D site |
| K01 street block | bar/club, restaurant, pawn shop, street market, mall, drug lab, chop shop, gambling den; strongholds: bar, drug lab |
| K02 residential floor | tenement, apartments, luxury apartments, hotel, rooftops; strongholds: hacker den, basement den |
| K03 industrial lot | warehouse, sea dock, fab, power plant, substation, industrial park, salvage yard, construction site |
| K04 underground | tunnels/sewer, rail underpass, transit hub, parking structure, underground farm, bunker |
| K05 civic hall | union hall, meeting hall, church hall, university, hospital, archive; strongholds: union hall, union office, meeting hall, church hall |
| K06 tech interior | data centre, lab |

Still to do, in order:
1. Site mechanics per variant: farm grow-light cycles, bunker blast doors, electrified switchyards, trains, igniting drug-lab chemicals, boarding the ship.
2. Faction guard rosters (section C) per site.
3. Maglocks and access tiers on corp kit sites.
4. Multi-level kits (tenement stacks, bunker and parking levels), and the hidden drug-lab wing.
5. Per-variant texture sets; clinic, studio and training centre dressing on G02.

## Open
- Map size and time targets for neutral sites.
- Which other corps hide drug-lab wings.
