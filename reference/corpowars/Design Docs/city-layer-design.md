# City Layer — Design Overview (v7, 2026-09-27)

Status: design complete; **steps 1-4 and 6 built** (2026-09-27; see city-layer-implementation.md), step 5 runs on the G02 fallback. This is the **index and summary**. Detail lives in:
- **city-roster.md**: the 6 corps, 32 subsidiaries and 67 properties (authoritative counts)
- **contract-hierarchy.md**: agendas → operations → contracts and odd jobs; minor players as factions
- **factions-draft.md**: EarthGov, Meridian, the corps, property market, collapse and carve-up, relations
- **subsidiaries-draft.md**: the subsidiary framework and income model
- **campaign-and-city-population.md**: win/loss paths, districts, neutral owners, minor players
- **neutral-sites-and-odd-jobs.md**: procedural neutral sites and odd jobs
- **building-types.md**: every map type, plus the enemy roster from DeePaybackEnemies
- **sim-behavior-draft.md**: faction AI, executives, defense, fog of war
- **executives-and-insertion.md**: named executives and minor-player leaders, floors and entry rules
- **income-and-economy.md**: the player's money
- **city-layer-implementation.md**: what's built, file map, tuning, debug commands
- **xcom-apocalypse-reference.md**: research notes

## Purpose
The mission loop is done (buy gear → accept contract → run it → payout minus costs and fines → repeat). The city layer **generates the work** that loop consumes. Every job is a step in an operation, and every operation serves a faction's agenda.

## All decisions at a glance

**Structure**
- Turn-based days. **Every job takes one day**; you can also close the day without a job. The campaign runs about 60 days.
- You're an independent broker. Compact campaign: nothing new appears, collapsed corps are gone for good and the survivors absorb them.
- **EarthGov** (protects Meridian and territorial order, caps private armed force) → **Meridian** (the only lender; foreclosures and auctions) → **6 self-sufficient corps** → **32 subsidiaries** (8 shells) → **67 properties** across **5 districts**.
- **Neutral sites** (never owned or traded) are generated fresh for every job.
- **4 minor players** (Rustline Crew, Local 9, NullSet, Tenants' Association) act as lower-level factions with turf, strongholds, leaders, agendas and operations. They can be suppressed but never destroyed.
- Off-screen work is done by unnamed freelancers.

**Win / loss**
- Win A, **patron**: pledge to a corp once you reach Allied. You win when it controls **17 of 32 subsidiaries** or is the last corp standing. You lose if your patron collapses.
- Win B, **own corp**: buy subsidiaries and reach 17 of 32, or be the last corp standing. Losing your corp drops you back to broker. While pledged you can own 1 subsidiary; buying a second means going independent.
- Always a loss: defaulting on Meridian.

**Economy**
- Property yields minus upkeep (security, power, repairs, debt) go to the subsidiary, then up to the parent corp.
- The only outside income a corp gets is the player paying its service subsidiaries.
- The market mostly trades **single properties** (foreclosure, distress sale, lease expiry, scandal). Whole subsidiaries change hands only in distress sales, carve-ups and receivership. Monopolies are allowed.

**Work**
- **Agenda** (faction, weeks) → **operation** (subsidiary or minor player, 5–10 days, progress and deadline) → **contract** (the decisive strike at a corp property or stronghold) + **odd jobs** (prep at neutral sites: intel, access, weaken, leverage, progress).
- 6–10 operations run at once. Targets can counter-operate, so you may be offered both sides.
- Your own corp runs operations too.

**Relations and services**
- Five tiers, randomised ±10 per save; third parties react when you're identified.
- Corp services: fence (Grey Harbor), intel (Candor), blackouts (Voltaic), weapons (Bastion Arms), crew (Northstar), medical (Oriole Clinical).
- Minor-player services: black-market gear, informants, cheap intel, safehouses.

**Sites**
- Corp properties use a **fixed seed per save** and a building type (office/HQ, clinic, studio, training centre, R&D, lab, data centre, farm, bunker, warehouse, dock, fab, plant, substation, industrial park, salvage yard).
- Neutral sites use a new seed every job. Minor-player strongholds keep a fixed seed while held.
- Security = guard force (6–16, capped by EarthGov) + tech level (1–4).

**Presentation**
- Everything happens in the office. The terminal has OPERATIONS, CITY, MARKET and LEDGER tabs.
- Office objects: news TV, wall map board, phone/fax, executive pinboard, service stations.
- Debriefs add a CITY IMPACT section. The office grows through separate maps per tier.
- Fog of war hides what you have no intel on.

## Daily tick
1. Income and upkeep → treasuries.
2. Update agendas (corps and minor players).
3. Launch new operations and post their steps; deadlines resolve (success, freelancer roll, or failure).
4. Minor-player turf shifts from operation results.
5. Property market: triggers → auctions (the player's corp can bid).
6. Collapse check → carve-up; win/loss check.
7. News feed.

## Mission consequences
- SABOTAGE: damaged property (yield −50% until repaired); generator room: dark for a day.
- STEAL: target −25% for some days, client gains.
- RECRUIT / extract executive: target −10% per executive, client gains the bonus.
- Loud or identified runs: security upkeep up, relations down, third parties react.
- Records to Sable: scandal, can force a sale.
- Each job adds progress to its operation; a successful operation applies its goal effect.

## Existing contracts → templates
Helix Recovery, Black Ledger, Brain Drain (client moves to Lattice via Northstar) and Field Audit become contract templates: the final strikes of operations. The operation and target property supply objective, rules of engagement, floors and theme. Prep jobs modify the template (entries, passes, guard force and tech, willing defection).

## Build order
1. Data model: corps, subsidiaries, properties, districts, executives, relations, treasuries, debts, day counter.
2. Operations with a contract step only; the 4 templates on G02 properties.
3. Daily tick; terminal OPERATIONS and CITY tabs; close the day; debrief CITY IMPACT.
4. Property market, collapse and carve-up, patron pledge, win/loss.
5. Neutral sites + odd jobs (construction site first); street chunk kit.
6. Minor players as factions; strongholds.
7. More building types (see building-types.md); office tier maps.
8. Player-owned subsidiaries and own corp.
9. Later: drawn city map, playable defense, combat operatives, executive tail/eliminate, bribes, monopoly limits.
