# Subsidiaries — Framework (v5, 2026-09-27)

Planning only. The full list of subsidiaries and properties is in **city-roster.md**. This doc defines what a subsidiary is and how it works.

## Decisions
- **32 subsidiaries** (5–6 per corp, 8 shells) owning **67 properties** (1–3 each).
- **No growth:** no new subsidiaries appear during a save.
- **Corps are self-sufficient:** no corp supplies another. The only outside money a corp receives is what the player pays its service subsidiaries.
- **Win counts subsidiaries** (17 of 32). Properties decide income.
- **Monopolies allowed.** An optional per-corp subsidiary limit (~10–12) could be added later.

## What a subsidiary is
A business unit of a corp that owns a set of properties fitting its niche.

| Field | Meaning |
|---|---|
| Name, parent, niche | what it is and what it does (e.g. Verdant Grow, Oriole, pharma crops) |
| Visibility | **public** (parent known) or **shell** (parent hidden until uncovered) |
| Head | one named executive; their bonus boosts the subsidiary's income |
| Properties | 1–3 sites; each has a building type, district, fixed seed, yield and security |
| Security profile | default guard force + tech level; individual properties can be tighter or looser |
| Service (some) | what it offers the player (fence, intel, blackouts, weapons, crew, medical) |
| Treasury link | net income goes up to the parent; losses are covered by the parent |

## What a subsidiary does
- **Earns** the sum of its properties' yields minus upkeep. Missions hit individual properties.
- **Runs operations** against rival subsidiaries or minor players, serving its corp's agenda (see contract-hierarchy.md).
- **Hires the player**, sometimes through a shell.
- **Is a target**: contracts name the property and subsidiary ("Verdant Grow — Old Quarter farm").
- **Serves the player** if it's a service subsidiary, priced by relation tier.

## Income model (abstract, self-sufficient)
**Gross (per day)**
- Property yield by type: labs, R&D, data centres, fabs and plants are high; clinics, studios, warehouses, docks and farms are medium; offices, salvage yards and training centres are low to medium; an HQ is low.
- Player-service income (fees and cuts).

**Modifiers**
| Event | Effect |
|---|---|
| Damaged (sabotage) | −50% until repaired |
| Power cut (generator room) | dark and −50% for a day (Corvane recovers faster) |
| IP stolen | −25% for some days; the client gets a matching boost |
| Head recruited away | −10% until replaced (~10 days) |
| Scandal | −20% for some days |
| Minor-player trouble (strike, raid, protest, leak) | yield down or upkeep up for some days |
| Tech level | small bonus per level |

**Upkeep:** security (guard force × tech level), power (own generation; Corvane cheapest, Lattice data centres dearest), repairs, Meridian debt.

**Net** goes to the parent. A subsidiary losing money drains its parent toward distress sales and foreclosure.

Not simulated: supply between corps, supply chains, markets, employees, shares.

## How subsidiaries and properties change hands
- **Single properties** move most of the time: foreclosure, distress sale, lease expiry, scandal sale → auction. The buyer places the property in one of its subsidiaries that fits.
- **Whole subsidiaries** move in distress sales (parent sells a unit), collapse carve-ups (auctioned as units), and Meridian receivership (unsold units).
- A subsidiary with no properties left still exists as a brand or holding and still counts toward the win until it's sold or its corp collapses.
- After a change of owner, security and power cost switch to the new owner's level after a refit window (a soft period for jobs).

## If a subsidiary limit is added later
1. Buyers under the limit keep the unit as a separate subsidiary.
2. Buyers at the limit fold it into a related subsidiary (name retired; counts once).
3. Unsold units go to Meridian receivership (EarthGov-guarded, re-auctioned every few days, first thing the player could buy).
4. Receivership too long (~30 days) → liquidation: properties sold one by one.

## Player-owned subsidiaries
- Bought at auction, out of receivership or in a distress sale, usually with a Meridian loan.
- They earn with the same model; you set their security; you get their service or perk free.
- The first purchase makes you a corp (see campaign-and-city-population.md).
