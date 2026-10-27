# Contract Hierarchy — How Every Job Ladders Up to the Corp War (v2, 2026-09-27)

Planning only. Ties together sim-behavior-draft.md (faction AI), neutral-sites-and-odd-jobs.md and city-roster.md.

## Decisions
- **Every job takes one day**, contracts and odd jobs alike. One job per day (or close the day without one).
- **Every job belongs to something bigger:** each is a step in an **operation**, which serves a faction's **agenda**.
- **6–10 operations** run citywide at once.
- **Your own corp runs operations** too, once you have one.
- **Minor players operate like the corps** at a smaller scale: agendas, operations, steps. They are the **lower-level adversaries of the corps**, so corps regularly run operations against them, and you get hired for those.

---

## The four tiers

```
AGENDA      (faction, weeks)      "Lattice: get Corvane's power tech"
  └ OPERATION (subsidiary, days)  "Helion Power: poach Corvane Research's lead engineer"
      ├ CONTRACT (corp property, fixed map)  "Extract Dr. Ito from the Corvane Research lab"
      └ ODD JOBS (neutral sites, generated)  "Photograph Dr. Ito's schedule at the Meridian Row hotel"
                                             "Steal a keycard at the Highline construction site"
```

### Tier 1: Agenda (faction level, long-term)
- Each corp holds **1–3 agendas**, drawn from personality, relations and fears. Each minor player holds **1–2**.
  - Oriole: "Break Castellan's weapons edge", "Bury the Kestrel trial data"
  - Castellan: "Cripple Oriole's R&D", "Guard the bunker programme"
  - Halvorsen: "Take over the Ironside docks", "Keep the auditors off", "Clear Rustline out of the docks"
  - Sable: "Expose a rival's shell", "Own the city's airwaves", "Find the NullSet leakers"
  - Corvane: "Protect the power patents", "Find out who's building Helion"
  - Lattice: "Get Corvane's power tech", "Out-hire everyone", "Break Local 9 at the fabs"
  - Rustline Crew: "Own the Old Quarter", "Tax the docks"
  - Local 9: "Unionise the Lattice fabs", "Win the Ironside strike"
  - NullSet: "Leak Kestrel's trials", "Expose Helion"
  - Tenants' Association: "Stop the Old Quarter clearances", "Shut down the Verdant farm"
- An agenda is a direction, not a checklist. It weights which operations are launched and against whom.
- Completing agendas gives a lasting boost; failing hurts.
- Visible only through intel (fog of war). The news hints at them.

### Tier 2: Operation (several days)
- The unit of the war. Run by a **subsidiary** (corp side) or by a **minor player**. Target: a rival subsidiary/property, a minor player's turf, or (for minor players) a corp property.
- Each has a **goal** (its sim effect), a **progress meter** (0–100%), a **deadline** (5–10 days) and **steps** (usually 1 contract + a few odd jobs).
- Success: the goal's effect happens, plus bonus pay and rep for everyone who worked on it. Deadline: freelancers try it (odds from progress so far), or it fails and the target gets warier.
- **Counter-operations:** the target can respond (find the leak, protect the executive, harden the site). You can be offered work on **both sides**.

### Tier 3: Contract (the decisive strike)
- At a **corp property** (fixed map), or at a minor player's **stronghold**. Big pay, big risk, big effect. Difficulty depends on the prep done.

### Tier 4: Odd jobs (preparation and support)
- At **neutral sites** (generated fresh each time). Small, simple, one day each. Each plays one role in its operation:
  | Role | Examples | Effect |
  |---|---|---|
  | **Intel** | photograph plans, bug a meeting, tail someone | reveals the contract's security, floor, target location; lets you choose the entry |
  | **Access** | steal a keycard, bribe a guard, copy a pass | a pass or a known unlocked route on the contract map |
  | **Weaken** | sabotage a delivery, cut a cable, pull a guard off shift | lower guard force or tech level for the strike |
  | **Leverage** | find dirt, recover a document | a softer outcome (willing defection, scandal instead of sabotage) |
  | **Progress** | plant evidence, move a package, pay off a witness | adds progress % directly |

---

## Minor players as factions

Minor players work like small corps, with their own agendas, operations and steps.

### What they have
- **Turf:** a strength score (0–100) in each district where they're active. Turf controls where their side gigs, trouble and services show up, and how many of their people appear on neutral-site jobs there. Starting values are in campaign-and-city-population.md.
- **A stronghold** in each district where their turf is strong. It's a semi-fixed map (fixed seed while they hold it): Rustline's bar and drug lab, the Local 9 union hall, NullSet's den, the Tenants' Association meeting hall. Strongholds are where decisive strikes against them happen.
- **Leaders:** 2 named figures each (see executives-and-insertion.md), who can be targeted.
- **Resources:** members and funds (abstract). Winning operations grows them; losing drains them.

### What they do to the corps
Their operations target corp properties in their turf:
- **Rustline Crew:** extortion and raids on warehouses, docks and clinics (yield ↓, repair costs), stealing shipments.
- **Local 9:** strikes and walkouts at fabs, warehouses and docks (yield ↓ for days), insider leaks to other factions.
- **NullSet:** leaks and hacks against data centres and shells (scandals, shells exposed, intel stolen).
- **Tenants' Association:** protests and blockades at Old Quarter sites (security upkeep ↑, construction delays), sabotage of clearances.

You can work **for** them against the corps (small pay, good standing, their services), or **for the corps against them**.

### What the corps do to them
Corps treat them as **lower-level adversaries** and run operations to suppress them. These are a steady source of work, especially early:
| Corp operation | Typical steps |
|---|---|
| **Break the strike** (Lattice, Halvorsen vs Local 9) | find the organisers (odd job), steal the strike fund ledger (union hall), extract or discredit a leader (contract) |
| **Clear the docks** (Halvorsen vs Rustline) | tail a courier, find the stash, raid the drug lab (stronghold) |
| **Find the leakers** (Sable, Oriole vs NullSet) | trace a data drop, bug a café, raid the hacker den |
| **Clear the block** (Verdant/Oriole vs Tenants) | steal eviction paperwork, sabotage a protest, pressure the association's leader |

### Outcomes
- Turf shifts with operation results: corps win → the minor player's turf in that district drops; they win → it rises and corp sites there suffer more trouble.
- **Suppressed, not destroyed.** A minor player at 0 turf everywhere goes **dormant**: no gigs, no trouble, no services. It slowly recovers and returns after some days (the city never fully cleans itself up). This keeps them as a steady, lower-level layer that never "wins" or "loses" the campaign.
- Your standing with them follows who you work for: busting Local 9 for Lattice costs you their informants; helping them costs you Lattice rep.

---

## Your own corp's operations
- Once you run a corp, you pick an **agenda** for it and launch **operations** from your subsidiaries against rivals (or minor players).
- You do the steps yourself (no payout, only the effect), or **hire freelancers** (pay them; odds as usual).
- Rivals launch counter-operations against you; defense is abstract for now.

---

## How it plays

### Example: corp vs corp
**Agenda:** Lattice, get Corvane's power tech. **Operation:** *Helion Power* vs *Corvane Research*, poach Dr. Hana Ito, 8 days.
1. Hotel (odd job): photograph her schedule → Intel.
2. Construction site (odd job): steal a maintenance keycard → Access.
3. Bar (odd job): learn she's unhappy with her pay → Leverage.
4. Corvane Research lab (contract): extract her → success. Corvane Research −10%, Lattice gains her bonus, Corvane may counter.

### Example: corp vs minor player
**Agenda:** Lattice, break Local 9 at the fabs. **Operation:** *Lattice Fabrication* vs *Local 9*, end the Ironside fab strike, 6 days.
1. Transit hub (odd job): tail a steward to the organisers' meeting → Intel.
2. Bar (odd job): photograph the strike-fund handoff → Leverage.
3. Union hall (stronghold contract): steal the strike-fund ledger → success. Strike ends, Local 9 turf in Ironside −20, Lattice Fabrication yield restored; your standing with Local 9 drops.

### Existing contracts as final steps
- **Helix Recovery:** Castellan (Bastion Arms) vs Helix Labs, steal the prototype. Prep: shift rosters (hotel), a Helix keycard (transit hub), pull guards (parking structure).
- **Black Ledger:** Oriole (Kestrel shell) vs Castellan, expose the books. Prep: tail the auditor (restaurant), his gambling debts (gambling den), a copied pass (dispatch office).
- **Brain Drain:** Lattice (Northstar) vs a target subsidiary, poach its head. Prep: schedule (luxury apartment), leverage (bar).
- **Field Audit:** Castellan (Aegis shell) vs Halvorsen Freight, find out what it ships. Prep: manifest (rail underpass), tracker (parking structure).

### The board
The terminal shows **operations**: client (or shell), target, goal, progress, deadline, available steps. Partly known ones show "?" until intel links them. Many operations run at once across 32 subsidiaries and 4 minor players, so there is always work.
