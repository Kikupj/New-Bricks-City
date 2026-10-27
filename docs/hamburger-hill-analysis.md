# Hamburger Hill: what to take for New Bricks City

Source: the review video (854×480 copy) and transcript in `docs/` (an 11-minute review of **Hamburger Hill**, a free early-access Vietnam War FPS on itch.io with an old-school Doom look). Frames were checked at 8-second steps plus close-ups of the menus.

We take **mechanics and screen layouts only**. Names, art, text and audio stay original (AGENTS.md). Nothing here is built yet; the owner picks which items go into `PLAN.md`.

## What the game does

### The campaign layer
- **A territory map, played in turns** (the reviewer calls it "Risk, but Vietnam"). You choose which region to attack next. Taking a region ends a battle; then you press **End Turn** and two enemy factions move.
- **Enemies counter-attack your regions.** Their turn usually means a **defense battle** on ground you already hold, sometimes on two fronts at once.
- **Each region you hold pays income** every turn.
- **Bonus missions** sit beside the main attacks: Recon or Patrol missions are easy cash and XP, Rescue missions (bring a downed helicopter crew home) are brutal, and there are convoy ambushes. Each one shows its cash reward on the map.
- **A Support meter** in the top bar falls when you lose men (−3 after the battle shown). Running out of men *and* money is game over.
- **The top bar** shows the turn, money, date, Support, the weather forecast and End Turn.

### Before a battle (the deploy screen)
- **When:** morning, day, dusk or night. **Weather** is shown (clear, overcast, rain, fog).
- **How you arrive:** on foot, beach landing, airborne (a parachute drop you steer), helicopter or boat.
- **Army → Squad:** drag men from your army list into squad slots, or press **AUTO**.
- **Kit per man:** a load weight (Light, Medium, Heavy), Primary, Secondary, Pouch 1, Pouch 2, Kit 1, Kit 2. A pouch opens a picker (frag, smoke, molotov). Rank decides how many slots a man can fill.
- **A totals strip** along the bottom counts the squad's grenades, medkits and other gear.
- **Recruit:** buy men by class (rifleman, machine gunner, medic, radio, engineer, flamethrower), each with a price, with − and + buttons and an AUTO button.

### In a battle
- Two or three hits kill you, so fights are short and tense.
- **When you die, you take over another squad member** and keep playing. The battle is lost only when the whole squad is gone.
- **Squad orders** appear in a message log: on me, hold here, move out, hold your fire, offensive, defensive. Alerts like "you've been spotted" and "incoming arty" show in the same log.
- **The enemy breaks:** once most are dead, the rest surrender and scatter, and the battle ends.
- Civilians run through the crossfire.
- Night maps are genuinely dark; rain and fog cut visibility.
- **The HUD is one bottom bar:** a message log on the left; squad portraits with health, wound and class icons; the current soldier's face; weather, a clock and a compass; grenade counts; magazine and reserve; two weapon slots.

### After a battle (the results screen)
- A title ("<Region> Taken" or "Held"), then kills out of total, headshots, accuracy, health lost, time, and a **letter grade**.
- Every squad member's portrait with their kills, a **KIA** stamp on the dead, and a promotion chevron for the ones who ranked up.
- **Loot:** enemy weapons recovered, with counts. They can go into your squad's kits or be sold.
- Region income, the Support change, and the new balance.

### The meta
- **Soldiers who die are gone for good.** Survivors gain XP and get promoted; a promotion lets them carry more gear. Protecting your veterans is the real game.

### What the reviewer criticized (lessons for us)
- Enemy grenades and RPGs are overpowered and spammed; one grenade wiped a whole squad.
- Allies and enemies leave cover and wander in the open.
- Rescue missions are unfair: the rescued men won't follow or take cover.
- Difficulty swings: some fights are trivial, others unfair. It gets repetitive after about an hour.

### Details from a closer pass of the menus
- **Every region on the map shows a number**: the size of the force holding it (2 and 4 on the quiet ground, 27–46 on the strongholds). Faction borders are colored, and the front line is hatched. You can judge how hard an attack will be before you commit.
- **The top bar shows income per turn** (`+$25M`) next to the money, and the date moves forward a month each turn.
- **The army header counts men by class** (12 total, then riflemen, machine gunners, medics, engineers, flamers), so gaps are easy to see.
- **Two cards under End Turn** show the regions that are threatened right now.
- **A mission briefing card** opens before a bonus mission: a picture, two lines of orders, the reward, then **Accept** or **Decline**.
- **The squad portraits show damage on the faces**, Doom-style (bloodied, then grey when down), with a class icon in one corner and a rank chevron in the other. The portrait of the man you're controlling is bigger.
- **A commanding officer's portrait** sits in the map's corner and gives out the missions.
- **The battle doesn't end by itself**: once the area is secure, "press Enter to leave" appears, so you can loot and gather the wounded first.
- **The message log** carries both squad orders and enemy news, such as an alert that the enemy faction is running.

## How it maps onto New Bricks City

| Hamburger Hill | New Bricks City today (PLAN.md) | Verdict |
|---|---|---|
| Territory map, pick your next attack | Raid board + city map, one gang district per raid (M2, M7b) | **Already ours.** |
| Enemy factions take turns and counter-attack | Daily gang tick: gangs gain alert and react (M7b) | **Adapt:** a gang can **counter-raid** a district you've taken. You defend it or lose it. |
| Defense battles | None | **New mission type:** "Hold the Block". Fortify a building, the gang comes in waves. Cheap to build: the M2 reinforcement wave code, plus a hold timer. |
| Region income each turn | Seized Cash from drops (M7) | **Adapt:** each toppled district pays a small daily "tip line" income. |
| Bonus missions with posted rewards | M9 objectives (Evidence Run, Informant Extraction…) | **Adapt:** show 1–2 optional side jobs on the raid board each day, with their Cash/Merit up front. A side job takes the day. |
| Support meter | 3 strikes (Internal Affairs) | **Adapt (optional):** a **Department Backing** meter. Lost officers, dead residents and retreats lower it; at zero you get a strike. Strikes stay the lose condition. |
| Time of day and weather | Not planned | **Adapt:** pick **dusk or night** on the raid board. Night is darker (flashlight matters) and more of the crew is asleep or off post, but the enemy count is the same. Weather is cosmetic at first (rain, fog density). |
| Insertion method | Entry choice at Intel level 3 (M7b) | **Adapt:** make it a deploy-screen choice: **front door, back alley, rooftop (from the next tower), unmarked van** (starts deeper, cover intact). The more stealthy options unlock with intel. |
| Army → Squad with AUTO | Squad Room menu (M6) | **Adapt:** use this layout for the Squad Room: roster on the left, squad slots in the middle, an AUTO button. |
| Kit per soldier (primary, secondary, pouches), slots by rank | Allies use a fixed class weapon (M6) | **Adapt:** officers carry **seized weapons** from the evidence locker (only guns from `Weapons/`), plus 1–2 pouch slots (Molotov, debris, medkit). Rank adds a pouch slot. Ties seized loot to the squad. |
| Recruit by class with prices | Recruit with Merit (M6) | **Already ours.** Keep the class picker with prices and an AUTO fill. |
| Take over a squad member when you die | Officer Down = strike, back to the hub (M2) | **Not a fit** as standard: you're one detective with a story. Could be a Captain's Board unlock or the "Demolition Day" hard mode. |
| Squad orders | Follow / Hold / Move (M6) | **Add two:** **Hold Fire** (for undercover openers, M9) and **Weapons Free**. |
| Spotted / message log | Undercover cover (M9) | **Adapt:** a small squad log on the HUD ("Spotted", "Reloading", "Officer down"). |
| Enemies surrender and flee | Arrests of wounded enemies (M9) | **Adapt:** a **morale break**. Once about 75% of a crew is down and the leader is gone, the rest drop their guns: arrest them for Merit, or let them run. Also ends long, dull cleanups. |
| Civilians in the crossfire | Residents (M9) | **Already ours.** Tie resident deaths to Department Backing. |
| Results screen with grade | Results card (M2) | **Expand:** kills/total, accuracy, health lost, time, a grade, each officer's portrait with kills and a DOWN or promotion stamp, seized weapons with counts, Cash and Merit, and the Backing change. |
| Sell loot | Seized weapons go to the evidence locker | **Adapt:** let surplus seized weapons be **turned in for Cash** at the armory. |
| Permadeath soldiers | Hospital 2 days (M6) | **Owner's call.** Options: keep the hospital; or make a downed officer who bleeds out **dead for good**, which makes ranks matter much more. A middle path: bleed-out = 2 days in hospital, but bleed-out *on a raid you then retreat from* = killed. |
| Bottom-bar HUD with squad portraits | Raid readout top left, ammo bottom right (M2) | **Adapt (later, M12):** one bottom bar. Original portraits are needed; none exist yet. |
| Force size shown on each region | Gang tier and alert on the dossier (M7b) | **Adapt:** print each district's estimated crew size on the raid board. It's exact with intel, a range without. |
| Income per turn in the top bar | Cash on the HUD (M2) | **Adapt:** show tomorrow's turf income next to Cash on the board. |
| Mission briefing card with Accept/Decline | Raid board menu (M2) | **Adapt:** side jobs open a briefing card (two lines, reward, Accept/Decline). Written by us; the captain at Checkpoint 9 can give them. |
| Damage shown on squad faces, with class and rank icons | Squad health readout (M2) | **Adapt (M6/M12):** the squad strip gets a face per officer that bloodies as health drops, with a class icon and rank chevron. Needs original face art. |
| "Press Enter to leave" once secure | Exit line ends the raid (M2) | **Already ours** in effect: you walk to the exit when ready. Add a "Block secure: head for the exit" message once the leader and most of the crew are down. |

## Things to avoid (from the criticism)
- **Cap enemy explosives:** at most one grenade or Molotov thrower active at a time, with a visible wind-up and a sound cue. The DeePayback pack's grenade users need a check in M4.
- **Escorts must follow:** any escort NPC (Informant Extraction) uses the `NBC_Ally` follow code, takes cover when you stop, and is never left standing in the open.
- **Allies stick to cover** when holding: M6's Hold order should pick a nearby spot out of the enemy's sightline, not stand on the exact point.
- **Keep variety up:** rotate objectives and gangs so raids don't repeat after an hour.

## Decisions (2026-10-27)
Written into `PLAN.md`:
- **Permanent deaths: yes.** An officer who bleeds out is killed for good (memorial wall); one who goes down and is revived or carried out spends 2 days in hospital.
- **Backing: yes**, as one 0–100 meter; zero costs a strike (§2.5, §6.10).
- **Taking over an officer when you go down: no** in the standard game; an optional Demolition Day rule (M10).
- **New milestone M7c** (deploy screen and turf war); the rest is folded into M3, M4, M5, M6, M7b, M8, M9, M10 and M12.

## Suggested order (as first proposed)
1. **Fold into existing milestones** (no new milestone needed): results screen (M3), the Squad Room layout with AUTO (M6), Hold Fire / Weapons Free orders (M6), morale break (M4 or M9), the explosives cap (M4), side jobs on the board (M7b/M9).
2. **New milestone "M7c: Deploy screen and turf war":** time of day, insertion choice, officer kits from the evidence locker, counter-raids and Hold the Block, daily turf income, Department Backing.
3. **Owner decisions first:** permadeath or hospital; whether to have Department Backing; whether taking over an officer on death exists at all.
