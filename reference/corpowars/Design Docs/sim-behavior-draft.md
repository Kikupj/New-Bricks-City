# Sim Behavior — Faction AI, Executives, Defense, Information (v2, 2026-09-27)

Planning only. Companion to contract-hierarchy.md, city-roster.md and campaign-and-city-population.md.

## Decisions
- **Faction AI in two layers:** **agendas** (long-term) weight which **operations** get launched; target and objective choice within an operation uses **weighted rolls**. The same system drives corps, minor players and (once you have one) your own corp's rivals.
- **Executives:** named + role only. **38** corp executives (6 CEOs + 32 subsidiary heads) plus **8** minor-player leaders.
- **Your corp's defense:** abstract now, playable later.
- **Information:** fog of war.

---

## Faction AI

### Layer 1: Agendas (weekly-ish)
- Corps hold 1–3, minor players 1–2 (examples in contract-hierarchy.md).
- Picked from personality (sector, aggression, fears) and relations; re-evaluated every few days or when something big happens (a collapse, a stolen patent, a strike).
- An agenda names a **direction**: a rival or minor player to hurt, a thing to gain (tech, turf, a property type), or a thing to protect.

### Layer 2: Operations (daily)
Each day, while fewer than 6–10 operations run citywide, factions may launch one:

1. **Pick the launcher:** a subsidiary whose niche fits an agenda (Helion Power for Lattice's power agenda, Castellan Secure for "guard the bunker"), or a minor player.
2. **Score targets** (properties, subsidiaries, executives, or a minor player's stronghold/turf):
   `score = agenda fit + hostility + weakness + value + opportunity`, all × aggression
   - **Agenda fit:** does hitting this advance the agenda?
   - **Hostility:** relation tier with the target's owner.
   - **Weakness:** low guard force/tech, near foreclosure, fresh refit, dormant turf.
   - **Value:** the property's yield, a wanted tech, an executive's bonus.
   - **Opportunity:** recent blackouts, strikes, scandals, collapses.
3. **Weighted random pick** from the top scores.
4. **Pick the goal** by personality:

| Faction | STEAL | SABOTAGE | RECRUIT / EXTRACT | Other |
|---|---|---|---|---|
| Oriole | high | low | medium | bury evidence |
| Castellan | medium | high | medium | |
| Halvorsen | high | low | low | clear turf (vs Rustline) |
| Sable | high | none | medium | expose (scandal) |
| Corvane | medium | medium | low | protect patents |
| Lattice | high | medium | high | break strikes |
| Rustline Crew | high (shipments) | medium (raids) | low | extort |
| Local 9 | low | medium (strikes) | medium (organisers) | leak |
| NullSet | high (data) | low | low | leak, expose shells |
| Tenants' Assoc. | low | medium (protests) | low | block clearances |

Modifiers: a target near foreclosure favours sabotage ("finish them"); an executive present favours recruit/extract; a pledged player's patron's enemies get priority.

5. **Build the operation:** goal, deadline (5–10 days), the contract step (property or stronghold, rules of engagement from the launcher's ethics, pay from its wealth) and 1–4 odd-job steps (roles: intel, access, weaken, leverage, progress) placed at fitting neutral sites. Shells hide the client.
6. **Counter-operations:** a target that learns of an operation (through its own intel, a leak or an identified run) may launch a defensive one.

### Resolving
- Steps done by you add progress and apply their modifiers.
- At the deadline: success if the decisive step is done; otherwise **freelancers** roll (odds from progress, client wealth vs target security), else failure (target security up).
- Results feed agendas, relations, yields, turf and the property market.

### Against the player's corp
Rivals score your subsidiaries and properties the same way. A large, weakly guarded player corp gets targeted often.

---

## Executives and leaders
- **38 corp executives:** 1 CEO per corp (+income across the corp) and 1 head per subsidiary (+income to that subsidiary). **8 minor-player leaders** (2 per group; boost the group's operations and turf gain).
- Each has a name, role, bonus and location (a property, HQ or stronghold). Roster: executives-and-insertion.md.
- **Losing one** (recruited or extracted): the bonus is lost and the subsidiary's yield drops 10% until an unnamed, weaker replacement is promoted (~10 days). The client gains the bonus. Losing a minor-player leader cuts that group's turf gain until replaced.
- The floor where an executive works has tighter security. Executives may also appear at neutral sites (homes, hotels, restaurants) through operation steps.
- Jobs: recruit, extract. Later: tail, eliminate.

---

## Defending your own corp

### Now (abstract)
When an operation's decisive step hits your property off-screen: attacker strength (launcher wealth, job type, progress) vs your security (guard force × tech level). Success applies normal effects to you; failure reads "Intruders repelled at …". Your levers: security spend per property, intel to learn who's behind it, and counter-operations.

### Later (playable)
Some attacks become defense missions (hold a floor, catch the intruder, protect an executive), arriving with combat operatives.

---

## Information: fog of war

**Always visible:** the news feed; public subsidiaries and their properties (map board); auction results; your finances, rep and relation tiers with you; operations offered to you (with "?" for unknown fields).

**Hidden until you gather intel:**
| Hidden | Revealed by |
|---|---|
| Treasuries and debt | Candor, NullSet, stolen financial records |
| Corp-to-corp relations (exact) | intel; news hints |
| Agendas | intel, leaks, patterns in the news |
| Shell ownership | Candor, NullSet, documents on missions |
| Executive locations | intel odd jobs, Local 9 informants, documents |
| Property security (force/tech) beyond a rough rating | site survey, intel odd jobs |
| Which operation an odd job belongs to | intel; completing linked steps |
| Who is behind an operation against you | intel, documents, interrogating a recruited executive |
| Minor-player turf (exact) | their services, informants |

Intel goes stale after some days (greyed out on the terminal).
