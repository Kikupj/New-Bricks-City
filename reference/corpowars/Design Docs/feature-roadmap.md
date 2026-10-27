# Corpo Wars — Feature Roadmap (updated 2026-09-27, city layer built)

Sources: CorpoWars_dev/CHANGELOG.md, README.md and the design docs in this folder.

## DONE

### Core loop
Buy and equip gear → accept contract → complete it → payout minus costs and penalties → repeat.

### Stealth core
- Visibility meter; guard states UNAWARE → SUSPICIOUS → ALERT (UEAI search)
- Vision cones, noise, silent takedowns, body discovery; furniture blocks sight; nav-graph pathing
- Guards: PMC looks, 4 skin tones, Security Supervisor, DeePayback voices, stationary posts

### Management layer
- Office hub (HUB01), Acquisitions Terminal, briefs and debriefs
- Payouts, bonuses, penalties, rules-of-engagement fines; 4 contracts on generated towers
- Intel purchases; operatives Nyx, Marrow, Vox; board advance
- Quartermaster: grid inventory, shop, crew kits, field resupply crate

### Gear
Service pistol, SMG, pump shotgun, tranq rifle, taser, fists; universal suppressor; flashlight, noisemaker, flashbang, medkit, body armor; maglock bypass, breaching charge

### Level generation (G02 office tower)
Seeded floors, floor roles, random insertion; multi-floor jobs, stair towers, elevators; three ways in, passes, hacking; cover budget; 3D furniture; 5 themes; stealth lighting; civilians; extraction at any exit

### Heat & extraction
Heat 0–100; garage G05: garage insertion, rerouted extraction, scenarios quiet/patrol/checkpoint/ambush

### Tooling / QA
genmap, render_map, model/texture generators; reach/cover/name checks; lock test; debug launcher

### City & corp layer (built 2026-09-27; notes: city-layer-implementation.md)
- Data model from `cwcity.txt`: 6 corps, 32 subsidiaries, 67 properties, 5 districts, 38 executives, 4 minor players with turf, strongholds and leaders; saved with the game
- Turn-based days (one job per day, CLOSE DAY); daily tick: economy, agendas, operations, minor players, market, collapse, patronage, win/loss, news
- Faction AI: agendas -> scored, weighted operations; counter-operations; freelancers; minor players raid/strike/leak/protest/extort, corps suppress them
- Every job is an operation step: contracts at properties/strongholds, INTEL/ACCESS/WEAKEN/LEVERAGE/PROGRESS odd jobs at neutral sites (G02 fallback); prep changes the strike
- Property security (force/tech) sets guards, hacks and sight on G02; fixed layouts per property, varying entry
- Property market (foreclosure, distress, lease, scandal, auctions, receivership), carve-ups, patron pledge and betrayal, win/loss, Meridian default
- Services priced by standing (corp and minor player); fog of war and corp intel; terminal OPERATIONS/INTEL/CREW/CITY/MARKET/LEDGER/NEWS; CITY IMPACT debrief

---

## City & corp layer: design (steps 1-4 and 6 built; 5 on the G02 fallback; 7-8 open)
Index: **city-layer-design.md**. Key docs: city-roster, contract-hierarchy, factions-draft, subsidiaries-draft, campaign-and-city-population, neutral-sites-and-odd-jobs, building-types, sim-behavior-draft, executives-and-insertion, income-and-economy.

- EarthGov → Meridian → 6 corps → 32 subsidiaries → 67 properties in 5 districts; neutral sites generated per job
- Agendas → operations → contracts (corp properties/strongholds) + odd jobs (neutral sites); 6–10 operations at once; one job per day
- 4 minor players as small factions (turf, strongholds, leaders, operations); corps operate against them
- Property market, collapse and carve-up; relation tiers; corp and minor-player services; 38 executives + 8 leaders; fog of war
- Wins: patron or own corp at 17 of 32 subsidiaries (or last standing); loss: Meridian default or patron collapse; ~60 days
- Presentation: terminal tabs, news TV, map board, phone, pinboard; office tier maps

### Build order
1. **Data model**: corps, subsidiaries, properties, districts, executives, relations, treasuries, debts, day counter (saved in the ledger; `cw_citydump` debug command)
2. **Operations** with a contract step; the 4 existing jobs become templates on G02 properties
3. **Daily tick**; terminal OPERATIONS/CITY tabs; close the day; debrief CITY IMPACT
4. **Property market**, collapse and carve-up, patron pledge, win/loss
5. **Neutral sites + odd jobs** (construction site first; street kit)
6. **Minor players** as factions; strongholds
7. **More building types** (see building-types.md); office tier maps
8. **Player-owned subsidiaries / own corp**

### Before coding (done)
- CorpoWars_dev is a git repo; old saves start a fresh city; save/load with nested city data tested

### Next on the city layer
- Real neutral-site generators (construction site first, street kit), stronghold maps, more building types (step 5 proper, step 7)
- Player-owned subsidiaries / own corp, auction bidding, abstract defense (step 8)
- Pacing: soak tests put a determined broker's war at ~90-120 days (design target ~60); see city-layer-implementation.md

---

## PLANNED (other)

### Near term
- Player income: fence via Grey Harbor, gear buy-back
- Extraction: ground-floor lobby checkpoint, rooftop reroute at very high heat, clean-escape bonus
- Heat tuning
- New objectives: generator room sabotage; named executive recruit/extract; photograph/plant/meet templates for odd jobs

### Staged assets (Assets/, DeePaybackEnemies/)
- PDA.pk3 → intel/document pickups; Checkpoints_v667.pk3 → checkpoint saves
- Weapons: M16, Machinegun, bolt rifle, ASMD, railgun prototype, UAC sniper, Flares, Fists of Fury
- Higher-tier pass colours; ss2_tex.wad + Aquilarius textures
- DeePaybackEnemies rosters for minor players, private muscle, dock crew, elites, drones

### Longer term
- Drawn city map; playable defense + combat operatives; office raids
- Executive tail/eliminate; bribes; monopoly and subsidiary limits

### Deferred
- Obstacle-avoidance "whiskers" for guard steering
