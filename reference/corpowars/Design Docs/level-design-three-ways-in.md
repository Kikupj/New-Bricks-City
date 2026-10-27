# Corpo Wars — Level design rule: three ways in (G02)

Living design doc: https://claude.ai/code/artifact/b7683801-f95f-4a54-bf21-3330f4d68e30

Derived from Deus Ex: every objective room gets a FRONT, a SIDE and an INFORMATION route.

- Objective rooms (chosen in `CW_FloorGen.PlanObjectives`, before carving): STEAL = weighted pick among exec suite, private office, conference room, storage, IT room or lab in the far part of the floor (`PickStealRoom`); DESTROY = server room; TURN = lab, else a private office (spread away from the other objectives with `RoomSpread`).
- FRONT: maglocked doors (`CW_Door.secured`, no line special). Ways through (updated 2026-09-26, playtest round 5):
  - Security pass (per floor tier) or Nyx blackout: tap USE.
  - Tailgate a guard walking through (guards carry passes).
  - **Hack**: tap USE to open the `CW_HackMenu` timing minigame (non-pausing). Nodes = 3 + floor tier, +1 on high-security contracts. Three misses trip the lock: an 800u noise and a 20 s lockout.
  - **Maglock bypass** gadget: hold USE for 3 s. Silent, single use.
  - **Breaching charge** gadget ([K]): 3 s fuse. The door is blown open for good, the noise carries 1600u, and the blast does area damage. Counted as "Doors breached".
  - The old hold-USE force (noisy) was removed.
- SIDE: server = crawl duct from janitor closet; others = unlocked door via a neighbouring staff room (`AddSideEntry`).
- INFO: `CW_SecurityPass` (security.zs) placed in IT/lobby/office 400u+ from insertion; one patrol guard `hasPass` drops it when downed. Site survey radar marks loose pass (kind 30).
- Keypads `CW_Keypad` (3D, frames A red / B green / C dark) on both faces of maglocked doors.
- Stationary key posts may stand beside maglocked doors. Standing guards don't hold doors open; only guards walking up do.
- Cover budget `CoverPass`: crouch cover (>=28u) or unlocked doorway within 64u (doors 88u) of patrol loops, max 192u exposed; adds `CW_FCredenza` or freestanding `CW_FPlanter`.
- Debrief: "Way in" line per objective room (`CW_Ledger.approachNotes`: pass / blackout / tailgated / hacked / bypass device / blown open) + "Doors breached".
- QA: `CorpoWars_tools/qa/`: cover.py, reach.py (RAD=20, LOCKED=1, GAP=32; plate 1888u after the roomier-core change), check.py, test_lock.sh (predates the hack rework; the force step no longer applies).

Open: suspicion from blown doors, cover indicator on visibility meter, cameras, ceiling crawlspace, patrol timing offsets, apply rule to G01.
