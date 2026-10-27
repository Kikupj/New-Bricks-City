# Factions — First Six Corps (v7, 2026-09-26)

Planning only. Companion to city-layer-design.md (index), city-roster.md, subsidiaries-draft.md, campaign-and-city-population.md and sim-behavior-draft.md.

- **v2:** Meridian Capital is no longer a faction. It is the neutral **lender**. Its faction slot goes to **Lattice Dynamics**.
- **v3:** buildings change hands through the **property market** (Meridian credit + auctions), not one corp.
- **v4:** **EarthGov** added above Meridian. **Compact campaign:** a corp that goes under is gone for the rest of the save; no new corps enter.
- **v5:** EarthGov's power narrowed to **protecting Meridian and territorial order**. When a corp falls, the **surviving corps absorb its assets**.
- **v6:** **Corps are self-sufficient.** No corp supplies another; each runs its own security and power. EarthGov **caps private armed force** per corp.
- **v7:** win conditions settled (see campaign-and-city-population.md); the player's own corp takes part in the market; power sabotage targets a building's generator room.

Stats are 1–5. **Ethics** drives rules of engagement. **Aggression** is how often they launch hostile operations. **Security** is the baseline guard force/tech level at their properties. Theme is the default interior fit-out (existing CW_Themes).

---

## The power structure

```
            EarthGov  (protects Meridian + territorial order; licenses private force)
               │ charters & backs
            Meridian  (the only licensed lender; runs the property market)
               │ credit, foreclosure, auctions
   Oriole · Castellan · Halvorsen · Sable · Corvane · Lattice   (self-sufficient, free to operate)
               │ hire
            You (independent broker → optionally your own corp)
```

## EarthGov — the backstop (not a faction)
*"Order is the first public good."*
- A UN-like body with strong military power, bigger than any corp's. Not a client, not a target, not in the relations matrix.
- **Hands-off on corp business.**
- **It steps in only for:**
  1. **Meridian's authority.** Debts are law. EarthGov enforces foreclosures, protects Meridian's offices, and guards seized properties awaiting auction.
  2. **Territorial order.** Property changes hands only through the market.
  3. **Licensed force.** Each corp's charter caps its armed staff (this includes the player's corp). That's why guard force tops out and no corp can build an army.
- The corp war is therefore fought with deniable brokers.

### When EarthGov gets involved (player-facing)
- **Seized property:** EarthGov-guarded properties awaiting auction; rare, high-pay jobs face EarthGov troops.
- **Your own debt:** default on Meridian → Meridian takes your office (campaign loss).
- **Breaking territorial order** (later): attacking Meridian or EarthGov sites draws a response team.

---

## Meridian Capital — the lender (not a faction)
*"Every asset has a price. Every debt has a date."*
- Chartered and backed by EarthGov; never a client or target.
- Lends to the corps (secured against their properties) and to you: the board advance, and later loans to buy subsidiaries.
- Runs foreclosures and auctions.
- While you're in debt, Meridian takes half of each payout.
- Powerful only because EarthGov stands behind it.

---

## 1. Oriole Biosciences — biotech / pharma
*"Better living, patented."*
- **Role:** the rich R&D target. Labs full of prototypes and scientists (Dr. Vance, Helix lab).
- Wealth 4 · Security 3 · Tech 5 · Aggression 2 · Ethics 4 (protects civilians, fines guard kills lightly)
- **Wants:** to protect its IP, poach rival researchers, quietly bury bad trial data.
- **Fear:** leaks and whistleblowers — posts "retrieve the defector" jobs.
- **Theme:** Clinical White. **Rival:** Castellan.
- **Service to you:** medical supplies (Oriole Clinical).

## 2. Castellan Systems — defense & security tech
*"Peace through superior hardware."*
- **Role:** the hardest targets. Best-trained security in the city, for its own sites only. Its edge is **quality, not numbers**.
- Wealth 4 · Security 5 · Tech 4 · Aggression 4 · Ethics 1
- **Wants:** weapons IP, sabotage of competing products, recruiting engineers. Most likely to launch SABOTAGE.
- **Fear:** its own security failing — upgrades fastest after a hit.
- **Theme:** Night Glass.
- **Service to you:** weapons and armor (Bastion Arms).

## 3. Halvorsen Logistics — shipping, warehousing, freight
*"It gets there. Don't ask how."*
- **Role:** the grey-market neutral; your fence.
- Wealth 3 · Security 2 · Tech 2 · Aggression 3 · Ethics 2
- **Wants:** rivals' manifests, routes and contracts; to stay on good terms with everyone.
- **Fear:** audits (Field Audit fits here).
- **Theme:** Brick & Steel.
- **Hook:** good relations with everyone by default; easy early jobs, low pay.
- **Service to you:** fencing (Grey Harbor Salvage).

## 4. Sable Media Group — news, advertising, data brokerage
*"We don't report the news. We schedule it."*
- **Role:** the information corp. Turns your missions into news; scandals hit a corp's income and relations.
- Wealth 3 · Security 2 · Tech 3 · Aggression 2 · Ethics 3
- **Wants:** evidence and financial records (STEAL), insiders and executives (RECRUIT). Rarely sabotage.
- **Fear:** being the story.
- **Theme:** Walnut & Brass.
- **Service to you:** intel (Candor Analytics). Bad rep = news about *you*.

## 5. Corvane Energy — power technology
*"Keeping the lights on."*
- **Role:** in lore, the **best power technology in the city**. Powers only its own sites; everyone envies its tech.
- Wealth 5 · Security 4 · Tech 3 (5 in power) · Aggression 1 · Ethics 2
- **In play:** cheapest power upkeep; shorter blackouts at its sites; its plants and substations earn the most; its engineers and designs are prime STEAL/RECRUIT targets.
- **Wants:** rarely hires, pays best. Protects its power patents.
- **Theme:** Brick & Steel variant (new "Plant" theme later).
- **Service to you:** grid expertise (Voltaic Holdings): longer/cheaper blackouts elsewhere, or a free blackout.

## 6. Lattice Dynamics — AI, compute, data centres
*"The future is already optimising you."*
- **Role:** the fast-growing upstart; hoovers up talent and data.
- Wealth 4 · Security 4 (automated: more maglocks, fewer guards) · Tech 5 · Aggression 4 · Ethics 2
- **Wants:** training data, engineers and executives, sabotage of competing compute, **Corvane's power tech**.
- **Fear:** power. Its data centres are the most power-hungry sites and its own plants are inefficient (Helion Power is its secret fix).
- **Theme:** Night Glass variant or a new "Server Hall" theme.
- **Hook:** hacks harder, blackouts hit its sites harder. Later: cameras.
- **Service to you:** crew (Northstar Talent).

---

## Property market — why property changes hands

Properties are **collateral**. Each corp has income, upkeep (security, power, repairs) and a **Meridian credit line** secured against its property. The market is the only legal way territory moves.

### Triggers (checked each day)
1. **Foreclosure (main route):** over the debt limit → grace period → Meridian seizes the weakest property (EarthGov guards it) → **auction**.
2. **Distress sale:** below the cash floor → lists a property (or a whole subsidiary).
3. **Lease expiry:** non-HQ properties; renew at market rate or auction.
4. **Scandal sale (rare):** a Sable story wrecks a property's value.

### The auction
- Bidders: every corp with cash above its floor, **including the player's corp**. Bid = value × want (sector fit, adjacency, hurting a rival) × aggression, capped by cash.
- Corps don't bid against an Allied corp.
- Winner takes the property (or subsidiary); security and power cost switch to the new owner after a refit window.

### How missions feed it
| Player action | Effect |
|---|---|
| SABOTAGE | property damaged (yield −50% until repaired) + repair cost |
| Sabotage a property's **generator room** | that property dark for a day, yield −50% (Corvane recovers faster) |
| STEAL tech/data | owner −25% for some days, client + |
| RECRUIT / extract executive | owner −10% per executive, client gains the bonus |
| Loud / identified run | owner security upkeep ↑; relations ↓; third parties react |
| Records handed to Sable | can trigger a scandal sale |

---

## When a corp goes under (compact campaign)

A corp **collapses** when it has no subsidiaries left, or its Meridian debt exceeds what its properties can cover. It is gone for the rest of the save. If it was your patron, you lose the campaign.

**The carve-up:**
1. **Subsidiaries → liquidation auction** as units (fire-sale), with properties, staff, IP, income and executives.
2. **Relations reshuffle.**
3. **Contracts & rep:** operations withdrawn; owed payouts lost; **its service to you disappears**.
4. **Around a collapse:** desperate operations, "finish them" operations, "grab the IP before the auction" jobs.

---

## Starting relations (−100 … +100, randomised ±10 per save)

|           | Oriole | Castellan | Halvorsen | Sable | Corvane | Lattice |
|-----------|---:|---:|---:|---:|---:|---:|
| Oriole    | — | −50 | +10 | −20 | 0 | −10 |
| Castellan | −50 | — | +10 | −30 | +20 | −20 |
| Halvorsen | +10 | +10 | — | +10 | 0 | +10 |
| Sable     | −20 | −30 | +10 | — | −10 | +10 |
| Corvane   | 0 | +20 | 0 | −10 | — | −30 |
| Lattice   | −10 | −20 | +10 | +10 | −30 | — |

Tiers: Allied +75 · Friendly +25 · Neutral −24..+24 · Unfriendly −25 · Hostile −50. Player starting rep: Neutral (0) with every corp.

Built-in tensions: **Oriole vs Castellan** (main war) · **Corvane vs Lattice** (power tech) · **Castellan + Corvane** (establishment bloc) · **Sable + Lattice** (data buddies) · **Halvorsen** (neutral).

## Operation flavor per corp (for the generator)
| Corp | Likely goals | Typical RoE | Pay |
|---|---|---|---|
| Oriole | STEAL tech, retrieve defector | civilians protected | high |
| Castellan | SABOTAGE, STEAL weapons IP | no fines | medium–high |
| Halvorsen | STEAL manifests, audits, clear Rustline | loose | low–medium |
| Sable | STEAL evidence/records, RECRUIT sources, find leakers | civilians protected | medium |
| Corvane | rare; recover power patents, SABOTAGE copycats | no fines | very high |
| Lattice | STEAL data, STEAL Corvane power tech, RECRUIT engineers/execs, break strikes | civilians fined (PR) | high |

Objective weights per faction are in sim-behavior-draft.md.

## Open questions
- EarthGov force cap value (drives max guard force).
