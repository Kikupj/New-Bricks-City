# Campaign Structure & City Population (v3, 2026-09-27)

Planning only. Counts come from **city-roster.md**; operations from **contract-hierarchy.md**.

## Decisions
- **Two win paths:**
  1. **Patron dominance:** pledge to one corp; win when your patron controls **17 of 32 subsidiaries** or is the last corp standing.
  2. **Your own corp:** buy subsidiaries and become a corp; win at **17 of 32** or as the last corp standing.
- **Losses:** defaulting on Meridian; your patron collapsing (patron path only). Death in the field fails the job, not the campaign.
- **Length:** about 60 days, one job per day.
- **Off-screen work** is done by unnamed freelancers (news only).
- **City:** 5 named districts, 67 corp properties (fixed seeds), neutral sites (generated per job), 4 minor players.

---

## Path 1: Patron
- **Free agent first:** work for anyone; build rep and money.
- **The offer:** at **Allied**, a corp offers patronage. Only one at a time; you can decline.
- **While pledged:** patron operations pay more and you see them first (phone offers); its service is discounted; its allies treat you one tier friendlier. Jobs against the patron or its allies are refused, or count as betrayal if taken through a shell you hadn't uncovered.
- **Betrayal:** the patron turns Hostile, its allies cool toward you, and you're a free agent again.
- **Win:** the patron holds 17 of 32 subsidiaries or is the last corp standing. **Loss:** the patron collapses.

## Path 2: Your own corp
- **Getting there:** buy a subsidiary at auction, out of receivership or in a distress sale (usually with a Meridian loan). The first purchase makes you a corp: you get a name, enter the relations matrix and can bid at auctions.
- **Being a corp:**
  - Your subsidiaries earn under the same income model.
  - You set security within the EarthGov cap and get your subsidiaries' services free.
  - You pick an agenda and launch operations (doing steps yourself or hiring freelancers).
  - Rivals target you (defense is abstract for now).
- **Patron vs independence:** while pledged you may own **1** subsidiary. Buying a second means going independent: the pledge ends openly, not as betrayal, and the ex-patron cools to Friendly or Neutral. An independent corp can't pledge again.
- **Win:** 17 of 32 subsidiaries, or last corp standing. Losing every subsidiary drops you back to broker (not a loss).

---

## Districts (5)

| District | Character | Corp properties | Neutral life / minor players |
|---|---|---|---|
| **Meridian Row** | financial core, glass towers | 10 (Sable HQ, Lattice HQ, Candor, Northstar, Kestrel, Tidewater, Voltaic, Castellan dispatch, Oriole clinic, Glasshouse arena) | Meridian HQ (not playable), hotels, luxury apartments, restaurants, mall; NullSet |
| **Eastgate Research Park** | campuses, labs | 10 (Oriole HQ, Helix labs, Bastion R&D, Corvane lab and substation, Lattice data centre, Candor and Northstar offices, Cold Chain warehouse) | university, apartments, cafés; NullSet, Local 9 |
| **Ironside Docks** | freight, industry | 21 (Halvorsen HQ, warehouses, docks, rail yards, salvage, plants incl. Helion, fabs, farm, industrial parks) | union hall, bars, tenements, rail underpasses; Rustline, Local 9 |
| **Old Quarter** | dense, run-down, mixed | 11 (clinics incl. Kestrel's, Verdant farm, Sable studio, Sable Outdoor, Glasshouse office, Aegis, substation, salvage yard, Lattice Edge data centre) | tenements, markets, bars, gambling dens; Rustline, Tenants' Association |
| **Highline** | security & infrastructure belt | 15 (Castellan and Corvane HQs, bunkers, training centre, fabs, Corvane R&D and substation, Biobank, studio, data centres, warehouse, rail yard) | EarthGov garrison (not playable), transit hub, construction sites; Local 9 |

---

## Neutral sites
- Never owned, traded or counted toward the win.
- **Generated fresh for every job** (see neutral-sites-and-odd-jobs.md): construction sites, rooftops, tunnels, parking structures, tenements, apartment blocks, luxury apartments, hotels, bars, markets, restaurants, malls, pawn shops, university, hospital, transit hub, union hall, drug labs, chop shops, gambling dens.
- Minor-player **strongholds** are neutral sites held by a minor player (fixed seed while held).
- Not playable: Meridian HQ, EarthGov garrison.

---

## Minor players (factions at a smaller scale)
Full rules are in **contract-hierarchy.md**. In short:
- **Turf** (0–100) per district, **strongholds**, **leaders** (2 each), **agendas** (1–2) and **operations**.
- They run operations against corp properties on their turf (raids, strikes, leaks, protests). Corps run operations against them (break the strike, clear the docks, find the leakers, clear the block). You can work for either side.
- Turf shifts with results. At zero turf everywhere a minor player goes **dormant** and recovers later; it is never destroyed.
- Relation tier with you and each corp; services open at Friendly.

| Minor player | Type | Starting turf | Service to you |
|---|---|---|---|
| **Rustline Crew** | street gang | OQ 60, IS 50 | black-market gear |
| **Local 9** | labor union | IS 60, HL 30, EG 20 | informants (patrol routes, pass locations) |
| **NullSet** | hacker collective | EG 40, MR 30 | cheap intel, shell ownership leaks |
| **Old Quarter Tenants' Association** | tenants' group | OQ 70 | safehouses (lower heat, alternate entries) |

Leaders are named in executives-and-insertion.md.

---

## Off-screen freelancers
Unfinished operation steps may be done by freelancers when the deadline hits. Odds come from progress so far, client wealth and target security. Results apply as usual and appear in the news. Freelancers are never a faction and can't be targeted.
