# City Layer — Implementation Notes (v1, 2026-09-27)

What was built from city-layer-design.md (build order steps 1–4 and 6, plus step 5 on the G02 fallback), where it lives, how to tune it, and what's still open.

## Files
| File | What it holds |
|---|---|
| `cwcity.txt` | The roster as plain data: districts, corps (stats, goal weights), starting relations, 32 subsidiaries (security profile, service), 67 properties, 38 executives, 4 minor players (turf, service), strongholds, leaders, minor–corp relations, opening agendas. Read once when a campaign starts. |
| `zscript/corpowars/city.zs` | Data model (`CW_City` and `CWC_*` records), tables (building types, sites, goals, roles), relations and tiers, ownership, security, yields, loader. |
| `zscript/corpowars/citysim.zs` | The daily tick: economy, agendas, operations (launch, prep, deadlines, counter-operations, effects), minor players, the property market, collapse and carve-up, patronage, win/loss. `CW_Tune` holds the balance numbers. |
| `zscript/corpowars/cityjobs.zs` | Operation steps become jobs (`CW_Contract`), after-mission results (CITY IMPACT), services priced by standing, corp intel. |
| `contracts.zs` | `CW_Contract` carries the city fields; `CW_Ledger` holds `city` and the running `job`, runs missions from the board, closes days, handles the Meridian advance. |
| `terminal.zs` | OPERATIONS, INTEL, CREW, CITY, MARKET, LEDGER, NEWS. |
| `floorgen.zs` | `SetupSite`: guard force / tech level, neutral-site rules (no maglocks or passes), per-visit insertion and chosen entry. |

The city hangs off the player's `CW_Ledger` and saves with the game (checked: save and load in the office and mid-mission).

## How a day works
1. Each corp earns its properties' margin (yield with executive bonuses − running cost − security − power − subsidiary admin) minus a fixed overhead and interest. Cash below zero becomes Meridian debt.
2. About weekly, each faction reconsiders its agendas.
3. Freelancers work open odd jobs (14% a day each) and push progress. At the deadline the strike rolls: 20 + progress/2 + (client wealth × 3 − site security) × 2, clamped 5–85%. Up to two new operations launch while fewer than 6–10 run.
4. Minor players collect funds, drift back toward their starting turf, go dormant at zero turf and return after 10 days.
5. The market: over the credit limit for 3 days → foreclosure; deep debt → distress sales (properties, or whole subsidiaries); leases that can't be renewed even on credit; scandal sales; empty brands sold off. Sealed-bid auctions; no bids → receivership.
6. Collapse when a corp has no subsidiaries or its debt passes 1.3 × its credit line with no cash. The carve-up auctions its subsidiaries one a day. Then patronage offers and win/loss.
7. News. Quiet days drop hints: debt watch, agenda rumours, minor-player activity.

## Decisions made while building (flag any you want changed)
- **Another corp taking the city is a loss** for the player (the design only defined the patron win). It pushes you to pledge.
- **Meridian advance limit: $12,000.** Past that, Meridian calls the loan: default, campaign lost.
- **Counts: 17 of 32 subsidiaries** wins, as designed. See pacing below.
- **Dr. Aaron Vance** follows the roster (he). **Dr. Hana Ito** heads Corvane Grid at the Ironside plant.
- The prototype jobs are the opening operations with the design-doc clients: Helix Recovery (Bastion Arms vs Helix Labs), Black Ledger (Kestrel Trials vs Castellan Secure's dispatch office), Brain Drain (Northstar vs Helix Labs, Dr. Vance), Field Audit (Aegis vs Halvorsen Freight HQ).
- **Lease expiry** gives the seller nothing (the lease simply ended). Foreclosure proceeds pay down the debt, less 20% Meridian fees.
- **Neutral sites and strongholds** run on a single G02 floor in a fitting theme with light security and no maglocks until their generators exist. Odd jobs use new objective verbs: photograph and plant (the item stays behind), lean on / meet.
- **Guards per floor** follow the site's guard force (force 6 → 7 guards, 16 → 12; one fewer on multi-floor jobs). Tech sets hack nodes (2–4 + floor tier) and guard sight (±10%).
- **Every hit costs its target** $16k + 1/8 of the site's value (incident response, lawyers, security review). This is what lets a determined broker bring a corp down.
- **Fixed overhead per corp** is calibrated when the campaign starts, so every corp begins slightly in the black (wealth × 1.5 − 3 $k/day). This keeps edits to `cwcity.txt` balanced automatically.

## Pacing (soak tests, 90 days, `netevent cw_simdays 90`)
- **No broker:** 0–1 collapses by day 90; a handful of sales; debts build slowly.
- **A broker winning one strike a day for one client (`cw_simplayer`):** 2–3 collapses between day 54 and day 90; the leading corps reach 10–14 subsidiaries by day 90.
- So a determined player decides the war in roughly **90–120 days**, not 60. Knobs, if you want it shorter: `CW_City.WIN_SUBS` (17), `CW_Tune.INCIDENT_COST`, `INTEREST`, `CREDIT_PCT`, and the collapse threshold in `CollapseCheck`.

## Debug commands
- `netevent cw_citydump`: corps, minor players, running operations.
- `netevent cw_simdays N`: close N days with no player jobs. `cw_simverbose 1` prints every headline. `cw_simplayer 1-6` adds a broker who wins one strike a day for that corp.
- With `sv_cheats 1`: `netevent cw_openterminal`, `cw_testodd 0|1` (deploy the first odd job / strike), `cw_testfinish 1|0` (finish the running job, success / abort), `cw_testrep <faction> <delta>` (corps 0–5, minor players 10–13).

## Not built yet (next steps)
- Real neutral-site and stronghold generators (construction site first, then the street kit). Build order step 5 proper.
- More building types (step 7): every property still plays as a G02 tower floor in its type's theme.
- The player's own corp (step 8): bidding at auctions, owned subsidiaries, abstract defense. The MARKET tab is read-only for now.
- Fence (Grey Harbor), gear buy-back, the generator-room objective, executive tail/eliminate, bribes, office tier maps, news TV and map board in the office.
