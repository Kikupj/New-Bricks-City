# Extraction scenarios: heat + parking garage

Status: **first slice built 2026-09-27** (garage.zs, G05). This is the foundation for the corporation and city simulation layers: heat and outcomes are the signals those layers will consume.

## Decisions
- **Stairwells stay empty.** Moving between floors never triggers a scenario. Scenarios happen only on extraction.
- **Failing is possible.** If the player can't reach the vehicle (killed), the mission fails.
- **Operatives lower heat.** Nyx -6, Marrow -8, Vox -6.
- **Planned later: combat operatives** who come on the mission and fight, useful in ambushes.
- **The garage is also an insertion point**, and when you insert there, every exit leads back down and the job ends at the van.

## Built (v1)
- **Heat** `CW_Ledger.Heat()` 0-100: alarms x12, guards killed x6, civilians killed x12, doors breached x8, bodies found x5, +3 per 30 s since the first alarm, -10 if no alarms, minus crew. Shown on the mission HUD; "Heat at exit" in the debrief.
- **G05 parking garage** (genmap `build_garage`): 1792x1280 deck, 12 pillars, lift lobby on the north wall. `CW_GarageGen` places cars (Voxel Vehicles Pack; blockers at nose and tail), sodium lights, the van (extraction + transport crate) in a south bay, and the lift up to G02.
- **Garage insertion**: about 40% of tower jobs (`Mix(seed,29) % 100 < 40`). Start at the van with 2-4 civilians, an aisle patrol, and a lift post on medium/high security or a coin flip. The G02 passenger elevator gets a "garage (B1)" button.
- **Reroute**: on a normal insertion, the first time you reach an exit with the primary done: chance = heat - 25 (0-60%). If it hits, you go to the garage.
- **Scenario roll** (first arrival in the garage with the primary done): heat +/-15 → quiet (<20) / patrol (<45) / checkpoint (<70) / ambush. A reroute is never quiet.
  - Patrol: 2 aisle patrols.
  - Checkpoint: 2 posts at the lift mouth (one is the supervisor) + 1 patrol.
  - Ambush: 5 posted guards around the van, cautious, suspicion 40, facing the lift.
- Debrief shows "Extraction: <scenario>".

## Next (not built)
- Lobby checkpoint that actually checks passes (show a pass or disguise to walk through).
- Rooftop extraction when heat is very high (ground floor sealed).
- Bonus for a clean escape; client ROE fines already apply to ambush fights.
- Civilian witnesses raising heat; heat carrying over into the corp layer (target corp security rating, retaliation).
- Stair route between the garage and the building (the tower's B1 landing already exists).
