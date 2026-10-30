# New Bricks City — Build Plan

A roguelite FPS mod for UZDoom (a GZDoom fork, so it runs ZScript). The police are losing a megacity to its gangs, and you're an undercover cop leading what's left of a gutted department on raids into a walled-off district of brick housing towers, with allied officers following you in. It's guerrilla police work: seized guns, unmarked vans, paid informants, and a department you rebuild one room at a time. The setting draws on the walled-off projects of *Brick Mansions*; the tone draws on cop thrillers like *Dirty Harry*, *Bad Boys II* and *Den of Thieves*. The campaign layer (deploy screen, squad kits, counter-raids, permanent losses) borrows mechanics from the indie FPS *Hamburger Hill* (`docs/hamburger-hill-analysis.md`). The plan is built to be handed to GPT Codex one milestone at a time.

- **Engine:** `uzdoom.exe` (in this folder)
- **Base game (IWAD):** `freedoom-0.13.0/freedoom2.wad`. It's free, so the mod can be shared without needing commercial Doom.
- **Language:** ZScript for all new code. Imported asset packs keep their DECORATE.
- **Single-player only.**

---

## 0. What's already in the folder

| Asset | Format | Notes |
|---|---|---|
| `DeePaybackEnemies/` | Unpacked folder, DECORATE | About 5,600 sprite frames and roughly 900 sounds. It replaces all 18 vanilla monsters with `RandomSpawner`s that pick from human enemies: thugs, punks, crooks, hoodies, suits and mobsters, militia, mercs and PMCs, ninjas, a jetpack guy, a drone, and the bosses `BruteGL` and `BruteMiniGUN`. It has a handcuff sound (`HCUFF.ogg`) and already defines an `AllyTracer` projectile. |
| `Weapons/AK47.zip` | WAD, DECORATE | `AK47`, slot 4, uses `Clip` |
| `Weapons/Colt45.zip` | PK3, DECORATE | `Colt45`, slot 2, uses `Clip`, editor number 5757 |
| `Weapons/CombatKnife.zip` | PK3, DECORATE | `CombatKnife`, slot 1 |
| `Weapons/FistsOfFury.zip` | WAD, DECORATE | `FistsOfFury`, slot 1 |
| `Weapons/Flashlight.zip` | PK3, ZScript | `FlashlightCentered` / `FlashlightAngled`. Needs dynamic lights on. |
| `Weapons/MicroUzi.zip` | PK3, ZScript | `MicroUzi`, slot 2, uses its own `UziAmmo` |
| `Weapons/PumpActionShotgun.zip` | PK3, DECORATE | `PumpActionShotgun`, slot 3, uses `Shell`. Its `Sprites/unused/` and `Sounds/unused/` folders hold 13 `XSTR` frames plus shell-load, open and close sounds (`XMDBLOAD`, `XMDBOPN`, `XMDBCLS`), very likely a reload animation. |
| `Weapons/DualBerettas.zip` | PK3, DECORATE | `Dual92`, slot 2. **Reloads**: a 30-round magazine (`Dual92Loaded`) refilled from a `Clip` reserve, using `WRF_ALLOWRELOAD`. Alternates left and right guns. |
| `Weapons/Machete.zip` | WAD, DECORATE | `Machete`, a melee weapon with 4 random swings. **No slot set in its code.** It ships a `KEYCONF` that adds itself to slot 1 (`addslotdefault 1 Machete`). **Don't merge that KEYCONF**; our player class sets the slots. |
| `Weapons/FragGrenade.zip` | PK3, DECORATE | `FragGrenade`, slot 9, editor numbers 11907–11909, uses `FragGrenadeAmmo`. Primary fire **winds up the throw**: hold it for up to 12 speed steps, and the throw speed goes 8 → 30. Alt-fire throws instantly at full speed. The thrown grenade bounces off walls and floors (`BounceType "Doom"`, with tunable bounce factors). The hand sprites are `HGRN` (holding the grenade, pin-pull frames B–P) and `HGT2` (the throw). **It gets repurposed as the base for the brick and debris throw (§2.3).** It won't be in the game as a frag grenade. |
| `Weapons/Molotov.zip` | PK3, DECORATE | `MolotovCocktail`, slot 9, editor number **25013**, uses `MolotovAmmo`. You hold fire to wind up a throw (with a power bar); hold too long and it goes off in your hand. Its fire uses `DamageType Fire` and `XF_HURTSOURCE`, so it can burn you. It ships its own `TEXTURES` and `GLDEFS`. |

**Integration problems found** (fixed in M0/M1):
1. **Slot collisions.** The fists and knife both use slot 1, and the Machete has no slot. The Colt, Uzi and Dual Berettas all use slot 2.
2. **Enemies drop vanilla weapons.** They drop `Shotgun`, `Chaingun`, `PlasmaRifle`, `Pistol` and `Thuggundropper`. These have to be remapped to our weapons.
3. **Ammo is split four ways** (`Clip`, `Shell`, `UziAmmo`, none). It needs a simple, deliberate scheme.
4. **Three packs are WADs** (AK47, FistsOfFury, Machete). Their lumps need extracting into folders so everything lives in one PK3 source tree. The Molotov's `TEXTURES` and `GLDEFS` need merging with ours.
4a. **Editor-number conflict.** The Molotov uses map editor number 25013, so **the mod's own map objects use 26000 and up**.
4b. **Every firearm needs reloading (§2.2).** Only the Dual Berettas reload today. Reload art per weapon:

| Weapon | Reload art |
|---|---|
| Dual92 | Full animation (`R92L`, `R92R`, `D92R`) plus sounds `B92REL1–3` |
| Shotgun | Likely the unused `XSTR` frames plus load sounds; Codex must check |
| Colt45, MicroUzi, AK47 | No reload frames or sounds. They use the in-engine "dip" reload: the weapon drops out of view, you hear the magazine sounds, and it comes back up. |

KEYCONF binds `+reload` to R by default.
4c. **Molotov fire hits everyone.** It hurts the player (`XF_HURTSOURCE`), and the fire is spawned in a chain where it isn't certain the player still gets credit as the attacker. So allies get `DamageFactor "Fire", 0` instead of relying on a "was it the player?" check. Enemy flamethrowers use the `"Enemy"` damage type, so they still burn allies. The Molotov sets enemies alight, which triggers the pack's existing `Death.Fire` burning animations.
5. **Puff sprites overlap.** The enemy pack overrides the vanilla `PUFF*` puff sprites. That's intended; keep it.
6. **The enemy pack's `gameinfo.txt`** sets the startup title "DeeDee says: takem down". Replace it with ours.
7. There are no sprite-name duplicates inside the enemy pack (checked).

**Sprites for allied cops (no new art needed to start).** The pack has tactical-looking humans with full animation sets. They'll become police allies, recolored with a police translation:

| Pack actor | Sprites | Becomes |
|---|---|---|
| `specopM` (and its 7 color variants) | `EW1A`/`EW1B`, SMG | Patrol Officer (male) |
| `specopF` (and its 5 color variants) | `EW2A`/`EW2B`, SMG | Patrol Officer / Paramedic (female) |
| `MiltiaShotgun` (and its variants) | military shotgun | Breacher |
| `Sniper`, `Sniper2` | military sniper | Marksman |

These classes get **removed from the enemy spawn pools**, so the player never confuses an ally with an enemy. That leaves `eWOLFSpawner` with only its terrorist variants, which is fine.

**AI facts that matter for allies (verified in the pack's code):**
- Every enemy has `+NOTARGET` and `+NOINFIGHTING`, which tells the engine monsters shouldn't fight each other.
- Every enemy has `DamageFactor "Enemy", 0`, so they're immune to anything with that damage type.
- All enemy projectiles use `DamageType "Enemy"`.

So the built-in "friendly monster" behavior won't work properly. Allies need **custom target-finding**, their projectiles must not use the `"Enemy"` damage type (the pack's `AllyTracer` doesn't), and a script has to point enemies at allies. M5 covers all of this.

**What's missing** (planned for below): maps, HUD, player sprite or mugshot, pickups art (cash, perks), music, urban textures, voice callouts for cops, a heavy/explosive player weapon, and title graphics.

**Credits and licensing.** The enemy pack and the weapon packs (these look like Realm667 releases, judging by their INFO files) are community assets. Each one ships a CREDITS file that must be carried into the final `CREDITS.txt`. Freedoom is BSD-licensed.

### 0.1 Recycled from Corpo Wars (the owner's earlier mod)

`C:\Games\Corpo Wars\` holds a working UZDoom mod (stealth contracts in a corporate city) plus the packs it was built from. **M0b (done) brought what we need into this repo**, so Codex never has to leave the project folder:
- **`reference/corpowars/`**: the complete Corpo Wars *source*, read-only. It has the ZScript tree, every definition lump (MODELDEF, GLDEFS, SNDINFO, CVARINFO, KEYCONF, MENUDEF, TRNSLATE, MAPINFO), `Design Docs/` (read `site-kits.md` before M2), CREDITS, README, CHANGELOG and LICENSE-UEAI.
- **`docs/corpowars-port-map.md`**: for each system below, its files and **every outside class it uses**, which a port has to bring along, replace or cut.
- **`nbc/`**: the assets, already loaded: textures, decor, sign, skyline and gadget sprites, the breaching charge, prop models, the voxel cars (active), the Civilians2 sprites, and the K01, K02 and K04 kit template maps (as NBC_K1, NBC_K2 and NBC_K4).
- **`tools/cw/`**: Corpo Wars' Python tools (genmap.py rebuilds the kit templates; qa/ has map checks).

If something is missing, the original `C:\Games\Corpo Wars\CorpoWars\` (newer than `CorpoWars_dev\`) is still there to copy from. Never edit it.

**The systems are tangled.** The level kits, for example, use Corpo Wars' event handler, ledger, city, contract, guard and objective classes. Porting everything as-is would pull in 48 of its files, including the city sim. So each milestone ports **one system** and cuts or replaces its mission-layer ties, using the port map. Only the navigation graph is nearly standalone.

| Take | From | Replaces / feeds | Milestone |
|---|---|---|---|
| **Runtime level generator ("site kits")**: `kitgen.zs` (base), `kit_residential.zs` (tenement, apartments, luxury, hotel, den, **rooftops**: a corridor between two stair cores, flats, fire escapes), `kit_street.zs` (street block: **drug lab, chop shop, pawn shop, gambling den, street market**), `kit_underground.zs` (**parking garage**, tunnels, underpass), plus `procgen.zs`, `kitprops.zs`, `furniture.zs`, `props.zs`, `decor_apartment.zs`, `decor_underground.zs`, `stairs.zs`, `themes.zs`; template maps K01, K02 and K04, and `CorpoWars_tools/genmap.py` (`build_kit`) to rebuild them | CorpoWars | **Replaces `gen_blocks.py` entirely.** Every block is freshly carved from the case seed: a fixed grid of sectors whose floor and ceiling heights are moved when the map loads, so rooms appear while the game runs. Rooms, doors, windows, fire escapes, lights, furniture, entries and objective rooms are all placed for us. | M2 |
| **Navigation graph** `nav.zs`: built automatically on any map, Dijkstra pathing | CorpoWars | Ally following, catching up and "move there" orders; enemy pathing in generated maps | M4, M5 |
| **Guard awareness**: `guard.zs` (unaware → suspicious → alert, vision cones, patrols, finding bodies), the **visibility meter** (light, crouch, speed), the **noise system** (gunfire, running, walking radii), silent takedown from behind, plus Universal Enhanced AI 1.1.1 (MIT) | CorpoWars + UEAI | **Undercover openers** and debris noise lures (M9). A takedown becomes *takedown and cuff*, an arrest. | M9 |
| **Civilians**: `CW_Civilian` (sees you → screams → alerts → flees; knock-out from behind) plus the `Civilians2` pedestrian sprites (male, female and doctor sets) | CorpoWars + Civilians2 | Bricks residents in flats and on streets, the escort informant, and **civilian-casualty Merit fines** (a cop's rules of engagement, modeled on Corpo Wars' contracts) | M9 |
| **Reload code pattern** (code only): `gear.zs` has a magazine + reserve pattern, an interruptible shell-tube reload loop, and in-engine dip reloads (the weapon sprite is offset down and back up, with sounds). It also has `CW_Thrown`, with the noisemaker and **flashbang** gadgets. | CorpoWars (none of its weapons or weapon art) | The template for `NBC_ReloadWeapon`; the flashbang as a shop gadget | M1b, M7 |
| **Movement**: `player.zs` ledge climbing (Dodopod, "use or modify, attribute me"), `lean.zs` tactical lean, grounded movement | CorpoWars | The M11 **mantle** (don't write it from scratch); lean as an optional extra | M11 |
| **Menu framework**: `CW_UiMenu` / `terminal.zs` (tabbed terminal UI with mouse and keyboard), plus `gear.zs`'s locker menu | CorpoWars | Squad Room, deploy screen, Informant shop, Captain's Office, Armory locker, results screen | M3–M8 |
| **Props and dressing**: 71 OBJ models plus `modeldef.props.txt` (dumpsters, AC units, crates, beds, armchairs, bar counter, barriers, generators…); 460 decor sprites; signs; **voxel parked cars** (NerdKoopa); city skyline sprites (`CSKY`); breaching charge | CorpoWars + vvpck1.0 | Furnishing kits, burned-out cars on D1 streets, the skyline outside tower windows | M2, M12 |
| **Textures**: 438, including the AD* set (brick, concrete, doors, blinds), the AX* interior themes and Corpo Wars' own CW* textures | CorpoWars | The urban texture set (the kits already reference them) | M2 |

**Also take, slimmed down:** the **city map** (`citymap.zs` data + `citymapui.zs`, the full-screen top-down map with an inspector) and the *shape* of the daily tick in `citysim.zs`. This becomes the Bricks map with gang turfs and dossiers (§2.4, M7b).

**Don't take any weapons.** That means nothing from DeePayback Weapons 1.5E, and none of Corpo Wars' own guns (Glock, MP5, Duke shotgun, tranq, taser) or their sprites, sounds or item icons. **The weapon roster is only the packs in `Weapons/`.** Reloads for guns without reload frames use the in-engine dip.

**Don't take:** the corp economy itself (corps, subsidiaries, property market, Meridian, contracts), the terminal job board, grid inventory, the office-floor generator `floorgen.zs` (maybe later for the Crown's floors), or the CW guard sprites (they're DeePayback militia, which we already have). The Obsidian pipeline was tried for M2 and is now frozen (§4.4).

**Licensing.**
- **Fine to reuse:** Corpo Wars' own code (yours), and UEAI (MIT; keep `LICENSE-UEAI.txt`).
- **Attribution required:** ledge climbing (Dodopod) and lean.
- **Credit lines to copy over:** Corpo Wars' `CREDITS.txt` lists every source. Copy across the lines for everything you import.
- **Not formally licensed:** the A.D. Cop textures come from a 1996 commercial game. That's common in Doom modding and fine for a **free** mod, but never sell New Bricks City or bundle it with anything paid.

**How far to take the films and games.** It's fine to draw on the setting: a walled-off district of brick housing towers, police checkpoints at the wall, a kingpin running the towers, rooftop parkour, a cop working with locals, and a corrupt plan to raze the place. From the cop thrillers, take only the **tone**: a department that's outgunned and underfunded, cops who bend the rules to get results, crews that fight like soldiers, big loud raids. From *Hamburger Hill*, take only **mechanics and screen layouts**. Keep all names, characters, dialogue, logos, footage, art and audio original. Film stills and screenshots are fine as **your own private mood board** for mapping, but never ship them in the mod.

---

## 1. The pitch

> **New Bricks City.** Twenty million people, and the police are losing them. Budgets were cut year after year, precincts closed, and whole districts were handed to the gangs. The crews have rifles, armor and lawyers. The department has paperwork.
>
> The worst of it is **the Bricks**. Fifteen years ago the city poured a concrete wall around its poorest district and pulled everything out: the schools, the hospital, and finally the police. The brick housing towers inside now belong to **the Landlord**, a kingpin who runs the district's drugs, guns and rent from the top of the tallest tower, **the Crown**.
>
> City Hall has signed a demolition order. In thirty days the Bricks gets leveled, along with everyone still living there. Rumor says someone downtown is paying the Landlord to empty the towers first.
>
> All that's left of the department on this side of the city is **Checkpoint 9**: a half-shut police post built into the Wall. The switchboard is dead, the cells are flooded, and the armory is a cage of guns taken off dead gangsters. No backup is coming. You're **Detective Jordan Vance**, an undercover narcotics cop who grew up two blocks from the wall, and you run raids with whatever you can scrape together: seized guns, an unmarked van, paid informants, and the few officers who still show up. It's guerrilla police work, and it works. Every raid that pays off brings back cash, guns and recruits, and Checkpoint 9 comes back to life one room at a time.
>
> If you go down, the squad drags you back to the checkpoint. The case file stays open. Go again. But the officers who bleed out in the Bricks don't come back.

(These names are placeholders. Change them freely.)

**What the lore means for play:**
- **You start with almost nothing.** The first cases run on a cage of seized guns, two officers and a dead precinct. The meta progression (§2.6) is the department being rebuilt, and you can see it in the hub.
- **Guerrilla methods are the toolset.** Unmarked vans, rooftop entries, informants, stakeouts and seized weapons, not SWAT trucks and air support.
- **Every officer matters.** There aren't many, and losses are permanent (§2.1).
- **Backing is fragile** (§2.5). City Hall and the street are watching. Clean raids earn trust; dead officers and dead residents burn it.

---

## 2. Core loop

```
CHECKPOINT 9 (hub — a half-shut police post built into the Wall; it rebuilds as you unlock rooms, §2.6)
  ├─ Captain's Office: spend Merit to reopen precinct rooms (permanent unlocks)
  ├─ Squad Room: roster, recruiting, ranks, the memorial wall for the fallen
  ├─ Armory cage + Evidence Locker: your loadout and the weapons seized this case
  └─ THE CITY MAP (wall terminal): the Bricks, its turfs, the gangs, your case file,
     today's side jobs, districts under attack, Backing

CASE = one roguelite run: a freshly seeded Bricks, 30 days to demolition, 3 strikes
  Each day, pick ONE:
    RAID a gang's mansion (takes the day)
      DEPLOY SCREEN: time of day, how you go in, which officers, their kits (§2.7)
      Approach block (the street outside, on their turf)
      → STAGING FLAT across the street: pick 1 of 3 perks ("Intel"),
        buy from the Informant, patch up officers, pick your entry into the mansion
      → 2 mansion floors (each floor is one block; the stair core is the exit up)
      → the LEADER'S FLOOR: arrest or kill the gang leader → gang TOPPLED,
        its turf becomes a RECLAIMED BLOCK (pays turf income every day)
    DEFEND a reclaimed block that a gang is counter-raiding: HOLD THE BLOCK (§2.4)
    TAKE A SIDE JOB (takes the day): a short block with its reward posted up front
    STAKE OUT a gang's turf (takes the day): a short undercover recon block (M9)
    CLOSE THE DAY: rest; officers in the hospital recover a day
  Any time, free: buy tips from informants with Cash; read the gang dossiers
  Every day ends with the GANG TICK: gangs react, fortify, counter-raid, retaliate (§2.4),
  and reclaimed blocks pay their turf income

  Topple 3 gangs → the CROWN opens: the Landlord's tower (final raid)

GO DOWN in a raid → "OFFICER DOWN" → extracted, raid failed, 1 STRIKE,
                    what you carried that raid is lost, the gang is on alert
BACKING HITS ZERO → 1 STRIKE (§2.5)
CASE ENDS → win (the Landlord taken), 3 strikes (Internal Affairs pulls you), or day 30 (demolition)
          → Merit banked → next case is a NEW seeded city; the precinct and the
            surviving roster carry over
WIN       → big Merit payout → unlocks "Demolition Day" hard mode
```

Within a block, nothing changes. Enemies spawn in waves from a threat budget, your squad follows you in, you complete the objective (Sweep, Lab Bust, Evidence Run, Informant Extraction, Rooftop Pursuit or Warrant), the extraction point unlocks, and you exit.

**Two currencies:**
- **Seized Cash.** Dropped by enemies and kept through the case. You lose half when you go down, and all of it when the case ends. Spent with the Informant and on tips.
- **Merit** (commendation points). Earned for blocks cleared, arrests, elites, gangs toppled and officers brought home alive. It's banked after every raid and kept forever. Spent in the Captain's Office to reopen precinct rooms, and in the Squad Room to recruit.

**What carries through a case:** Intel perks, Seized Cash, Backing, reclaimed blocks, and **seized weapons** (every weapon you pick up in a raid goes into the case's evidence locker; you draw from it at the Armory, and your officers carry it in their kits). All of these are lost when the case ends. The roster (minus the fallen), ranks and reopened rooms are permanent.

**What makes you a cop, not just a gunman:**
- **The squad.** Up to 3 allied officers follow you on raids (see §2.1).
- **Arrests.** A badly wounded enemy can be cuffed instead of killed (use on them, with the handcuff sound). That earns Merit and a bigger drop.
- **Surrender.** Once the leader of a block is down (or the objective is done) and about 75% of the crew is out, the rest **break**: they drop their guns and kneel for 20 seconds. Cuff as many as you can for Merit; the rest run for the map edges. "BLOCK SECURE: head for the exit" appears, so there's no slow cleanup of the last few stragglers.
- **Undercover openers** (M9). Some blocks start with your cover intact: enemies aren't hostile yet, and you can line up your squad and make silent takedowns. Firing, being seen holding a gun, or a squadmate getting spotted blows your cover, and the whole block goes loud.
- **Scouting before you hit a door.** Every gang fights differently, and you only learn how by working the case: informants, stakeouts and interrogating the people you arrest (§2.4).
- **Curfew Heat.** Each block has a soft timer. When it runs out, the gangs call in reinforcements. Clearing quickly earns bonus Cash.

### 2.1 The squad (allied cops)

**Roster (permanent).**
- Officers are recruited in the Squad Room with Merit, by class, each with a price. An **AUTO** button fills the roster's gaps with the cheapest useful mix.
- Each officer has a generated name, a class, and a rank that improves over raids: Officer → Corporal → Sergeant. **Rank adds kit slots** (§2.7), so veterans carry more.
- The roster header counts officers by class, so gaps are easy to see.
- Squad size starts at 1 slot and unlocks up to 3.
- **Losses are permanent.** An officer who bleeds out on a raid is **killed in the line of duty**: removed from the roster for good, with their name, rank and raids added to the **memorial wall** in the Squad Room. Keeping your Sergeants alive is half the game.

**In a raid:**
- **Following.** Officers follow you in formation, fight on their own, and travel with you from map to map. Their health carries between blocks.
- **Orders** on five keys:
  - **Regroup / Follow**
  - **Hold Position**: officers take the nearest spot near you that's out of the enemy's sightline, not the exact point
  - **Move There** (to the spot you're aiming at, again preferring cover)
  - **Hold Fire**: they don't shoot unless shot at (for undercover openers, M9)
  - **Weapons Free**: back to normal
- **A squad log** on the HUD shows orders and callouts ("Holding!", "Reloading!", "Officer down!", "We've been spotted!", "They're running!").
- **No friendly fire.** Your shots and explosions never hurt them, and theirs never hurt you.
- **Officer Down.** At 0 HP an officer drops and bleeds out over 20 seconds. You or a Paramedic can revive them (stand next to them and press Use for 2 seconds), and they come back at 40% HP. A downed officer you carry out (they're near the exit when you leave) survives. **If no one gets to them in time, they die**, permanently (see Roster above).
- **Catch-up.** If an officer falls more than 1,024 units behind and you can't see them for 3 seconds, they quietly teleport to a free spot behind you. This also covers rooftop jumps they can't make.

**After a raid:**
- Officers who survived gain XP.
- Officers who went down at any point (revived or carried out) spend **2 days in the hospital** (CLOSE DAY counts), so you'll bring someone else. The Infirmary (§2.6) cuts that to 1 day.
- Officers who bled out are gone. Each one costs Backing (§2.5).
- Bringing your whole squad home earns bonus Merit and Backing.
- **Taking over an officer when you go down** (as *Hamburger Hill* does) is **not** in the standard game: you play one detective. It may come back as a Demolition Day rule (M10).

**Classes** (see §6.5 for stats): Patrol Officer (SMG, all-rounder), Breacher (shotgun, tanky, kicks open doors ahead of you), Marksman (rifle, holds overwatch from range), Paramedic (light SMG, heals you and revives faster).

The **Radio for Backup** consumable calls a temporary Patrol Officer into the current block only.

### 2.2 Reloading (every firearm)

- **Two counts.** Every firearm has a **magazine** (a per-weapon item, like `NBC_Mag_Colt`) and draws from a shared **reserve** (`NBC_LightAmmo`, `Shell`, `NBC_RifleAmmo`). The HUD shows `magazine / reserve`.
- **Pickups.** Ammo pickups and enemy drops only add to the reserve. A weapon pickup arrives with a full magazine plus a bit of reserve.
- **Reloading.**
  - **R** reloads. Firing with an empty magazine reloads automatically if you have reserve; otherwise you hear a dry click.
  - You can't reload a full magazine.
  - Reloading from completely empty takes longer, because you also rack the slide or bolt.
- **Interrupting.** Switching weapons cancels a reload. The ammo moves over at a **commit point** about 70% of the way through, so cancelling early costs nothing.
- **Shotgun.** It loads shell by shell, and pressing fire stops the reload so you can shoot right away.
- **Magazines are remembered** per weapon when you switch weapons, and they carry over between maps.
- **No reloading** for melee weapons, throwables or the flashlight.
- **Allies reload too.** Each one pauses about 1.5 seconds after a set number of shots and calls "Reloading!" That gives enemies a window and makes squad timing matter.
- **Tuning** is through perks (Speed Loader, Extended Mags) and a Board unlock (Range Qualification), listed in §6.3 and §6.4. The magazine sizes and reload times for each weapon are in §6.1.

### 2.3 Throwing bricks and debris (built from the frag grenade)

The Bricks is a ruin, so the ruin is your ammo. Bricks, chunks of concrete and bottles lie around every block. You can pick them up and throw them **with a quick-throw key (G) from any weapon**, without switching away from your gun.

- **Picking up.** You get debris by walking over loose pieces, or by pressing Use on a **rubble pile**, which gives 3–6 pieces before it's used up. You can carry **3 pieces** to start; perks and unlocks raise that. The HUD shows the count and the type you'll throw next.
- **Throwing.** Tap G for a quick lob, or **hold G to wind up** and release for a harder, flatter throw. This is the frag grenade's 12-step wind-up, reused. The current gun dips out of view during the throw and comes back afterwards. Aiming higher throws further, just like the frag.
- **On hit.** Debris doesn't explode. It does solid damage on a direct hit and **forces enemies into their pain animation** (staggering them for a moment), which breaks up rushes. A brick that hits a wounded enemy (under 35% HP) **guarantees an arrest stagger**, so bricks are the cop's non-lethal opener.
- **After it lands.** Bricks have about a 30% chance to land whole and can be picked up again. Everything else breaks into fragments.
- **Undercover use (M9).** A thrown piece that lands unseen makes a **noise** at the spot it lands. Unaware enemies nearby walk over to look, instead of being alerted to you. Use it to split up guards for silent takedowns. Throwing unseen doesn't blow your cover.
- **Allies.** Your debris never hurts the squad.
- **What happens to the frag grenade.** It's retired as a grenade. Its code (the wind-up, the bounce physics, the throw sounds) becomes the debris base, and its explosion sprites (`EXP3`) get reused for Volatile elites and cook-station explosions. A flashbang (M12) can be built later on the same throw code.

The debris types are in §6.8.

### 2.4 The city map and the gangs

The wall terminal at Checkpoint 9 opens a **top-down map of the Bricks**, built from Corpo Wars' city map (§0.1):
- The district inside the Wall is split into **turfs**, each held by a gang, with the **Crown** tower in the middle.
- Each turf shows its gang's **mansion** (their stronghold building), plus a few side sites: stash houses, a lab, a lookout roof.
- You select a site and read its **dossier** in the inspector panel, then press **RAID** or **STAKE OUT**. You can also open the case file: days left, strikes, toppled gangs, and the evidence on the Landlord.
- **Every turf shows its estimated crew size** on the map: a range (±40%) with no intel, exact from intel level 1. You can judge a raid before you commit.
- **The top bar** shows the day, Cash with **tomorrow's turf income** next to it, Backing, strikes, and the weather.
- **Under-attack cards** list the reclaimed blocks a gang is counter-raiding today.
- **Side jobs** (0–2 a day) sit on the map as their own markers. Selecting one opens a **briefing card**: a picture, two lines of orders from the Captain, the reward, and **Accept** or **Decline**. Types: Foot Patrol (walk a route to a far checkpoint; easy; Cash and officer XP), Evidence Run, Informant Pickup (an escort), Warrant (arrest a named lieutenant). Accepting takes the day.

**Each case seeds a new Bricks.**
- **4 of the 6 gangs** appear on the map, in random turfs.
- Every gang has **fixed identity traits** plus **1–2 random traits for this case** (§6.9), so even a gang you know well needs scouting again.

**Gangs differ in ways you prepare for.** These live in `nbc/gangs.txt`, a data file in the style of Corpo Wars' `cwcity.txt`, so you can tune gangs without touching code.

| What a gang changes | How you prepare |
|---|---|
| **Roster**: which enemy types and tiers show up, and how many | Squad classes (Breacher vs rushers, Marksman vs snipers) |
| **Damage**: bullets, fire, explosives or melee | Gear: Kevlar vest, fire-retardant jacket, more medkits |
| **Resistances and weaknesses**: e.g. vests that shrug off pistol rounds, fire immunity, ignoring stagger, weak to fire | Weapons: shotgun, Molotovs, bricks |
| **Signature tactic**: lookouts, alarms, ambushes, snipers, booby traps, swarming | Entry choice, flashbangs, undercover approach |
| **Mansion**: which kit variants their floors use, and how many entries | Entry choice (front, back, service, roof) |
| **Morale and alertness**: whether they break and run, and how fast cover blows | When to go loud |

**Intel: three levels per gang**, shown as `???` on the dossier until earned.

| Level | Reveals | Also gives |
|---|---|---|
| 1 | Roster and strength (enemy types, numbers, tier) | — |
| 2 | Signature tactic, resistances and weaknesses, and **this case's random traits** | — |
| 3 | The mansion's floor plan | Its entries become choosable; objective rooms and the leader's room are on the automap; guard posts show on the radar (Corpo Wars' "site survey" and "patrol schedule") |

**Sources of intel:**
- **Informants.** Buy a tip with Cash for +1 level on one gang. The price rises with that gang's alert.
- **Stakeouts** (M9). Spend a day on a recon block in their turf, undercover. Mark 3 targets (a lookout, a stash, a face) without blowing cover for +1 level. If your cover is blown, you take no strike, but the gang goes on alert.
- **Interrogations.** Every gang member you **arrest** in a raid has a 25% chance to reveal that gang's next unknown trait. Warrant targets always do.
- **Evidence ledgers** (the Evidence Run objective) give +1 level on a random *other* gang.

**The gang tick (end of every day).** This is a much smaller version of Corpo Wars' daily sim (`citysim.zs`):
1. **Alert decays** by 1 (from 0 to 3), unless you hit that gang today.
2. **Fortifying.** A gang you raided or got spotted by goes **+1 alert**: bigger budget, more elites, cover blows faster, and higher informant prices.
3. **Reclaimed blocks and counter-raids.** A toppled gang's turf becomes a **reclaimed block**: the department holds it, and it pays **turf income** every day (§6.10). A gang at alert 2 or higher that borders a reclaimed block may **counter-raid** it. The next day it shows as UNDER ATTACK. If you defend it that day (the **Hold the Block** objective, §6.6), you keep it and gain Backing. If you don't, or you lose, the attacker absorbs the turf: its roster starts showing up there, it gets stronger, and you lose the income and Backing. At most one counter-raid at a time, two after day 20. Sometimes two gangs hit the same block at once: a two-front defense.
4. **Retaliation.** A gang at alert 3 may hit back: an officer is hospitalized, an informant goes quiet for 2 days, or your next approach block is an ambush.
5. **The Crown grows.** Every 5 days the Crown gains a defense. Each gang you topple **removes** a matching one: no more lookouts after the Stoop Kings fall, no alarm after the Collectors, no rooftop snipers after the Wall Watch.
6. **Turf income** from every reclaimed block is paid, and new side jobs are rolled.
7. **News.** One line of street news per day hints at what moved.

### 2.5 Backing

How much City Hall, the brass and the street still back the department, from 0 to 100. Shown on the city map and the results screen. It starts each case at 60.
- **It falls** when officers die, when residents die by your hand or the squad's, when you retreat from a raid, when you go down, and when a reclaimed block is lost.
- **It rises** with clean raids (no officers lost, no residents hurt), arrests, toppled gangs and defended blocks.
- **High Backing (75+)** makes informant tips 20% cheaper and adds a side job each day.
- **Low Backing (25 or less)** adds a day to hospital stays and takes Radio for Backup out of the shop.
- **At 0** you take a **strike** (Internal Affairs opens a file) and Backing resets to 40. Strikes stay the only way to lose a case.

The numbers are in §6.10.

### 2.6 Rebuilding the precinct (the meta)

Checkpoint 9 starts as a ruin: most of it is boarded up, dark and flooded. The only rooms working are the Squad Room, the Armory cage and the wall terminal. **Merit reopens rooms**, in the Captain's Office, and each room is a group of permanent unlocks (§6.4). A reopened room is visibly back in the hub: lights on, furniture in, someone at the desk.

| Room | What it gives |
|---|---|
| **Squad Room** (open) | The roster, recruiting, the memorial wall |
| **Armory cage** (open) | Your loadout; the Evidence Locker of seized weapons |
| **Captain's Office** | Squad slots 2 and 3, Long Case, Case Files |
| **Motor Pool** | The **unmarked van** way in (§2.7); Radio for Backup in the shop |
| **Radio Room** | Cheaper informant tips; a third side job each day; Backing shown as a trend |
| **Infirmary** | Hospital stays 2 → 1 day; Precinct Doc (+max health); Trauma training |
| **Range** | Range Qualification (faster reloads); Field Training (recruits start as Corporals) |
| **Crime Lab** | Case Detective (intel 1 on every gang); interrogations more likely |
| **Holding Cells** | Arrests are worth more Merit; interrogations reveal more |
| **Roof Access** | The **rooftop** way in (§2.7); the second dash (M11) |

### 2.7 The deploy screen (before every raid)

Raids, defenses and side jobs start on one screen, laid out like *Hamburger Hill*'s: **roster on the left, squad slots in the middle, the selected officer's kit on the right**, and a strip along the bottom that totals the squad's Molotovs, medkits, debris and flashbangs.

- **When:** Day, Dusk or Night.
  - **Day:** the crew is awake and posted; more residents on the streets (more civilian risk).
  - **Dusk:** in between.
  - **Night:** genuinely dark (the flashlight matters); a third of the crew is asleep or off post, so undercover openers are likelier; ambush gangs (the Quiet) are stronger. The enemy count doesn't change.
  - **Weather** is rolled each day from the case seed and shown here: clear, rain or fog. Fog shortens enemy sight (M9); rain is cosmetic.
- **How you go in** (where the approach block starts):
  - **On foot** from the checkpoint (always)
  - **Unmarked van** (Motor Pool): start deeper in the block with your cover intact
  - **Over the roofs** (Roof Access): start on a perch above the street
  - **Through the tunnels** (intel level 2 on a gang whose turf has tunnels): start in a basement
- **Squad:** drag officers into the slots, or press **AUTO** (best available mix, healthiest first). Officers in the hospital are greyed out with their days left.
- **Kits** (one panel per officer):
  - **Primary:** the class's issue weapon, or a matching **seized weapon** from the Evidence Locker (Patrol: Uzi, AK; Breacher: shotgun; Marksman: AK; Paramedic: Uzi, Colt). A seized weapon changes the officer's damage type and fire pattern. Only weapons from `Weapons/` exist.
  - **Pouches** for consumables: Molotov, medkit, debris, flashbang. Officer 1 pouch, Corporal 2, Sergeant 3.
  - **Vest** (if one is in the locker): armor for that officer.
  - Kits come out of the Evidence Locker and go back after the raid. Whatever a fallen officer carried is lost.
- **ASSAULT** (or **DEFEND**) starts the raid.

The **staging flat** stays: it's where you pick a perk, shop and choose your entry into the mansion itself (§4.3 NBC_SafeApartment).

---

## 3. Feature scope

**MVP, to build first (M0–M8):**
1. The case and raid loop: 30 days, 3 strikes, Officer Down extraction, raids of approach + staging flat + 2 floors + leader, and a graded results screen
2. Seeded, freshly generated blocks from **our own level kits** (the Corpo Wars site kits, ported and rebuilt for the Bricks; §4.4), generated from the case seed
2b. **The city map**: turfs, 4 of 6 gangs per case, dossiers with intel levels, crew estimates, informant tips, interrogations, and the daily gang tick (§2.4)
2c. **The deploy screen and the turf war**: time of day, how you go in, squad kits from the Evidence Locker, reclaimed blocks with turf income, counter-raids and Hold the Block, Backing (§2.4, §2.5, §2.7)
3. A spawn director that spends a threat budget, enemy tiers by depth, waves, and surrender
4. Elite enemies (random modifiers)
5. **The allied cop squad**: following, fighting, orders, downing and reviving, carrying over between maps, classes, a roster with ranks, a hospital, and permanent deaths
6. Seized Cash and the Informant shop
7. A choice of 1 of 3 perks between blocks, including squad perks
8. Permanent meta progression: **rebuilding the precinct** room by room with Merit (§2.6)
9. A custom HUD (player stats, magazine and reserve, debris count, squad status strip and log, gang and floor, day and strikes, objective)
10. **Reloading for every firearm** (§2.2)
11. **Quick-throw bricks and debris** from the level (§2.3)

**After the MVP (M9–M12):** raid objectives, side jobs, undercover openers and arrests (M9); Curfew Heat, boss blocks and a win state (M10); a parkour movement kit (M11); and content and polish (M12).

---

## 4. Technical architecture

### 4.1 Repo layout

The engine stays in the root. Git ignores the engine files, and the mod source lives in `nbc/`, which UZDoom can load directly as a folder.

This is the layout as built by M0 and M0b. Folders marked *(planned)* appear in later milestones.

```
New Bricks City/
├─ uzdoom.exe, *.pk3, *.dll …        (engine — gitignored)
├─ freedoom-0.13.0/                   (IWAD — gitignored)
├─ DeePaybackEnemies/, Weapons/       (original downloads — read-only)
├─ AGENTS.md                          (standing rules for Codex)
├─ PLAN.md                            (this file)
├─ docs/STATUS.md                     (current state; Codex updates it after each milestone)
├─ docs/corpowars-port-map.md         (what each Corpo Wars system needs when ported)
├─ docs/hamburger-hill-analysis.md    (what the campaign layer borrows from Hamburger Hill)
├─ reference/                         (READ-ONLY source to port from, never loaded)
│  ├─ corpowars/                      (Corpo Wars' full ZScript, definition lumps, Design Docs, credits)
│  └─ weapons/<pack>/                 (each weapon pack's INFO, OLDCODE, KEYCONF; FragGrenade's code)
├─ art/debris/                        (pxl source for the debris sprites; export.py installs them)
├─ nbc/                               (THE MOD — loaded with -file nbc)
│  ├─ GAMEINFO.txt, MAPINFO.txt, DECORATE, ZSCRIPT.zs, SNDINFO.txt, GLDEFS.txt, TEXTURES.molotov.txt, CREDITS.txt
│  ├─ actors/enemies/, actors/weapons/<pack>/, actors/cw/   (imported DECORATE)
│  ├─ zscript/imported/               (pack ZScript: flashlight, microuzi)
│  ├─ zscript/nbc/                    (all new code, one system per file; squad/, city/, ui/, weapons/ …)
│  ├─ zscript/cw/                     (Corpo Wars systems as they're ported) (planned)
│  ├─ sprites/enemies/, sprites/weapons/<pack>/, sprites/debris/, sprites/cw/, sprites/civilians/
│  ├─ sounds/enemies/, sounds/weapons/<pack>/, sounds/cw/
│  ├─ textures/cw/, brightmaps/, graphics/brightmaps/, models/props/, voxels/
│  └─ maps/                           (NBC_TEST, NBC_K1/K2/K4 kit templates; NBC_HUB, NBC_SAFE … later)
├─ tools/
│  ├─ check_lumps.py + lumps_allow.txt   (static checks; the allow-list holds accepted pre-existing issues)
│  ├─ smoke_test.ps1       (boot, load map(s), fail on any error; uses -stdout)
│  ├─ run.ps1              (play)
│  ├─ list_textures.py     (texture names from the IWAD + nbc/)
│  ├─ make_test_map.py     (rebuilds NBC_TEST)
│  ├─ extract_wad.py       (WAD → loose lumps)
│  ├─ build_pk3.py         (zip nbc/ → dist/NewBricksCity.pk3)
│  ├─ cw/                  (Corpo Wars' Python tools: genmap.py rebuilds kit templates, qa/)
│  └─ import/              (one-time M0/M0b import scripts, kept as a record; don't re-run)
├─ build/                  (smoke-test output, scratch — gitignored)
└─ dist/                   (built pk3 — gitignored)
```

### 4.2 Launch commands

```powershell
# play (opens NBC_TEST until the hub exists)
powershell -File tools\run.ps1 -Extra "+give all"
# smoke test: boots, loads each map, kills the engine, fails on any error line
powershell -File tools\smoke_test.ps1 -Map NBC_TEST
```

How the smoke test works:
- It runs `uzdoom.exe ... -stdout -config build/smoke.ini` with the output redirected to `build\smoke_<map>.txt`. (`+logfile` produced no file in testing.) Its own config means your UZDoom settings are never touched.
- A map passes when three things are true: the engine is still running (a fatal error shows a "Fatal Error" window), the output has `Init complete.` and `<MAP> - <title>`, and no line matches an error pattern.
- Script errors look like `<file>, line N: <message>`.
- Inside `+commands`, use forward slashes: UZDoom's console treats a backslash as an escape character.

### 4.3 Systems (all ZScript, all prefixed `NBC_`)

| System | Where | How it works |
|---|---|---|
| **NBC_RunData** | `run_data.zs` | A `Thinker` set to `STAT_STATIC`, so it survives map changes and is stored in savegames. It holds the **case**: the seed and RNG step, the day, strikes, Cash, perks, the evidence locker of seized weapons, and the **gang states** (for each gang: turf, alert, intel level, revealed traits, toppled). It also holds **Backing**, the **reclaimed blocks** and any counter-raids, today's **side jobs** and **weather**, and the **current raid**: the gang, the floor index, Heat, the time of day, the way in, the chosen entry, and the **squad snapshot** (for each officer: roster ID, health, downed, carried-out or killed state, and their kit). There's a single instance, found with `NBC_RunData.Get()`. |
| **NBC_RunManager** | `run_manager.zs` | An `EventHandler`. It starts cases (seeding the city and the gangs), runs the day (raid, stakeout or close), and sequences a raid: approach → staging flat → floors → leader. It sets the kit, variant, seed and objective for each block and calls `Level.ChangeLevel(map, 0, CHANGELEVEL_NOINTERMISSION)`. On Officer Down it records a strike and on a raid's end it banks Merit; both return to the hub with `ChangeLevel("NBC_HUB", 0, CHANGELEVEL_RESETINVENTORY \| CHANGELEVEL_RESETHEALTH \| CHANGELEVEL_NOINTERMISSION)`. |
| **NBC_Gangs** | `gangs.zs` + `nbc/gangs.txt` | Gang definitions read from the data file (§6.9): roster per tier, damage-factor profile, signature-tactic flags, morale, mansion kit variants, leader, Crown defense, and the random-trait pool. It applies the profile to every enemy the Director spawns, and runs the **daily gang tick** (§2.4). |
| **NBC_CityMap** | `city/citymap.zs`, `city/citymapui.zs` | Ported from Corpo Wars' city map (data plus a full-screen ZScript menu). It draws the Bricks from `nbc/bricksmap.txt` (the Wall, 6 turfs, the Crown, Checkpoint 9, mansions and side sites), colors turfs by gang, and shows the inspector dossier with intel-gated fields (`???`), the case file and the news line. **RAID**, **STAKE OUT**, **BUY TIP** and **CLOSE DAY** send netevents that are checked in play scope. |
| **NBC_Meta** | `meta.zs` + `CVARINFO` | Permanent progress, stored in archived `server` CVars: `nbc_merit`, `nbc_unlocks` (a bitfield, grouped by precinct room, §6.4), `nbc_best_toppled` (most gangs toppled in one case), `nbc_cases`, `nbc_wins`, `nbc_roster` and `nbc_memorial`. The roster is a string holding each officer's ID, name, class, XP and hospital days. The memorial holds the fallen (name, rank, raids, the case and day they died). Changing either goes through a parser and writer in `meta.zs`. |
| **NBC_Precinct** | `precinct.zs` | Runs on NBC_HUB. On `WorldLoaded` it reads `nbc_unlocks` and brings each reopened room to life: unbars its door, raises its lights, spawns its furniture and its NPC from map things tagged by room (`NBC_RoomMarker`, DoomEdNum 26000+, arg0 = room ID). Closed rooms stay boarded and dark. |
| **NBC_Deploy** | `deploy.zs`, `ui/deploy_menu.zs` | The deploy screen (§2.7): time of day, way in, squad slots with AUTO, and per-officer kits drawn from the Evidence Locker. The menu reads RunData and the roster, and sends one `nbc_deploy` netevent that play scope validates before the raid starts. |
| **NBC_Morale** | `morale.zs` | Tracks the crew still standing in a block. When the leader or objective is done and about 75% of the crew is out, the rest surrender (kneel, unarmed, cuffable for 20 seconds), then flee to the map edge and despawn. Prints "BLOCK SECURE". |
| **NBC_Player** | `player.zs` | A custom `PlayerPawn` and the only player class. It defines weapon slots with `Player.WeaponSlot`, the start inventory, and the Officer Down intercept: an override of `DamageMobj` stops death during a raid and hands off to the RunManager. In the hub, damage is ignored. |
| **NBC_SpawnSpot** | `spawn_spot.zs` | An invisible map thing (DoomEdNum 26000+). Its args set the role: 0 is ground, 1 is a sniper perch or balcony, 2 is reinforcements only, 3 is an undercover idle spot. |
| **NBC_Director** | `director.zs` | A per-level `EventHandler`. It computes the threat budget from depth, Heat and objective, then spawns waves from the tier tables at spots the player can't see. It tracks living enemies and tells the objective when they're cleared. |
| **NBC_EnemyTiers** | `enemy_tiers.zs` | Tier costs (§6.2). The **raid's gang** decides which of the pack's choice classes fill each tier (§6.9); the ally classes are always excluded. |
| **NBC_Elites** | `elites.zs` | Hooks `WorldThingSpawned` and rolls modifiers based on depth. |
| **NBC_Loot** | `loot.zs` | Uses `CheckReplacement` to swap vanilla items for ours, and hooks `WorldThingDied` for Cash and drops. |
| **NBC_Objectives** | `objectives/*.zs` | One class per raid objective (§6.6). The objective owns the exit's lock state and the HUD objective text. |
| **NBC_Exit** | `exit.zs` | The extraction point (a squad car or an open stairwell door). It stays locked until the objective completes, then touching it calls `RunManager.AdvanceBlock()`. Downed allies nearby get carried out; officers who are already out stay out. |
| **NBC_Ally** (base) | `squad/ally.zs` | A ZScript actor class with one subclass per officer class, each inheriting the sprites and states of the pack actor listed in §0. It has `+FRIENDLY`, removes `+NOTARGET` and `+NOINFIGHTING`, and fires `AllyTracer` (or our own NBC tracers, never with the `"Enemy"` damage type). It runs its own state machine (follow, combat, hold, move-to, downed, reviving), uses **custom target-finding** (the nearest visible hostile within 1,536 units, preferring enemies that are attacking the player), avoids standing in the player's line of fire, and catches up by teleporting. Its `DamageMobj` override ignores damage from the player and other allies. It has `DamageFactor "Fire", 0`, so it's immune to the player's Molotov fire. At 0 HP sends the officer to the downed state instead of dying. Its `Used()` override handles reviving. |
| **NBC_SquadManager** | `squad/squad_manager.zs` | An `EventHandler`. On `WorldLoaded` it spawns the officers in RunData's squad snapshot near the player start, in formation. Before the level changes it writes their health and state back. It handles order netevents (`nbc_order 0–4`: follow, hold, move, hold fire, weapons free) and the squad log, retargets enemies onto allies (each second, an enemy targeting the player has a 35% chance to switch to a closer ally it can see), and gives XP after the raid. |
| **NBC_Roster** | `squad/roster.zs` | Recruiting by class (with AUTO), ranks (stat bonuses and kit slots), hospital rotation, deaths in the line of duty (to `nbc_memorial`), and name generation (first-name and last-name lists in LANGUAGE). |
| **NBC_ReloadWeapon** | `weapons/reload_weapon.zs` | A ZScript `Weapon` base class that all firearms inherit from. Settings per weapon: magazine class and size, reserve class, reload style (whole magazine or shell by shell), reload time, extra time when empty, the commit point, the sounds (magazine out, magazine in, rack), and either the weapon's own reload frames or the generic dip. It handles auto-reload, the dry click, cancelling and the perk modifiers. Each imported firearm gets **ported to a ZScript subclass** (`NBC_Colt45`, `NBC_Dual92`, `NBC_PumpShotgun`, `NBC_MicroUzi`, `NBC_AK47`) that keeps its original sprites, sounds, damage and fire timing. |
| **NBC_QuickThrow** | `weapons/quick_throw.zs` | A hidden inventory item on the player. `KEYCONF` defines `+nbc_throw` / `-nbc_throw` aliases → netevents. Pressing G starts a throw on an overlay layer (the finished `BRKH` hold frames, then the frag's `HGT2` throw frames), lowers the current weapon's sprite and blocks it from firing; holding builds the wind-up; releasing throws the next debris type. **Fallback** if overlays misbehave: a slot-0 "Debris" weapon built straight from the frag grenade code. |
| **NBC_Debris** | `weapons/debris.zs` | The carried debris items (counts and limit), the thrown projectiles (bounce settings adapted from `D3Grenade1`, no explosion, `+FORCEPAIN`), the impact results (a reusable brick, fragments, or a noise event for M9), the loose pickups, and `NBC_RubblePile` (map thing 26000+; Use gives pieces until it runs out). |
| **NBC_Arrest** | `arrest.zs` | Below 20% HP, an enemy has a chance to stagger for 3 seconds. Using it during the stagger cuffs it: the HCUFF sound plays, it's removed with no corpse, and it gives Merit and a drop. |
| **NBC_SafeApartment** | `safe_apartment.zs` | Runs on the **staging flat** (map NBC_SAFE), once per raid between the approach and the mansion: 3 Intel perk pedestals, the Informant NPC who opens the shop, a first-aid station where you pay to heal officers, and an **entry board**. With intel level 3 the entry board lets you pick front, back, service or roof; otherwise the entry is random. |
| **NBC_Results** | `ui/results_menu.zs` | The after-action screen at the end of every raid, defense and side job: the title ("<Turf> Taken", "<Block> Held", "Raid Failed"), kills out of total, arrests, accuracy, health lost, time and a **letter grade** (§6.11); every officer's portrait with kills and a DOWN, KILLED or promotion stamp; seized weapons with counts; Cash, turf income, Merit and the Backing change. |
| **UI** | `ui/hud.zs`, `ui/shop_menu.zs`, `ui/board_menu.zs`, `ui/squad_menu.zs` | A `BaseStatusBar` HUD (player stats, the squad strip with name, class, rank, health, order and bleed-out timer, the squad log, the objective, Heat, and the day and strikes) plus ZScript menus built on Corpo Wars' `CW_UiMenu` framework. The UI only reads game state. Changes go through `SendNetworkEvent` and are checked in play scope. |

**Scope rules Codex must follow.** Game state changes happen in play scope. The HUD and menus are ui scope and only *read* state; they send changes as network events. Don't use ACS unless a map truly needs it.

### 4.4 Levels: "the Bricks"

**Decision (owner, 2026-10-28): levels come from Obsidian again.** Obsidian has proven level architecture, and its Urban theme with the right settings makes good maps. Obsidian is the base: we finish the New Bricks City theme (`tools/Obsidian/addons/NewBricksCity/`) so every Doom prefab and texture it uses is swapped for New Bricks City prefabs and textures, and modify Obsidian's output as far as we can. Maps are generated outside the game into the district pool; that's fine. The in-game kits (below, M2b/M2c) are kept as loadable test maps (`nbc_kittest`) but no longer extended. The milestone is **M2d**.

*Superseded (2026-10-28): the two decisions below.*

**Decision (owner, 2026-10-27): levels go back to our own architecture.** The goal is levels that look as true to the setting as possible, and Obsidian can't get there:
- **Obsidian builds Doom levels.** It joins abstract rooms with lifts, odd-shaped halls and arenas. A city theme can re-skin that, but it can't produce an apartment block's logic: stacked identical floors, a corridor with flats on both sides, two stair cores, an elevator, fire escapes, real room sizes.
- **Its maps are built outside the game** into a fixed pool, so the case seed can't shape them, and every rebuild is a manual step.
- **Our own kits do what Obsidian can't.** Corpo Wars' site kits carve real building plans from the case seed inside the game, and they're the owner's own tested code. They're boxier, so the look comes from scale, facades, props and lighting (below).

**Obsidian is frozen.** NBC_CT01–04 stay in the game as the M2 slice's districts until M2b replaces them, then they're dropped from the district pool. `tools/Obsidian/` stays in the repo as a record; don't extend it. Its Corpo Wars furniture classes (`nbc/zscript/cw/`) are reused by the kits' `Dress()`.

**Scale (every kit and hand-built map uses it).** Measured from the actors: the player, the officers and every gang member are 56 units tall (their sprites draw 54–60 pixels tall), so a person is 56 units = 1.8 m. That makes a metre about **31 units up**; with Doom's 1.2 vertical stretch it's about **37 units across**. Real sizes, bent only where actors need room to move:
- flat, corridor and service ceilings 80 (2.5 m); lobbies 88–100; penthouse flats 96 (3 m); shops and halls 108–128
- doors 68 high (2.1 m) and 48 wide (1.3 m; a real 1 m door is 37, too narrow for radius-20 actors)
- corridors 80 wide (2.2 m, so two officers can pass); rooms 112–144 deep (3–4 m); stair cores 176 wide
- rails over a drop 36 high (1.1 m) and blocking; fences 64 (2 m)
- streets: a 256 roadway (6.9 m), 112–128 sidewalks
- window sills 24, window openings 40 high

Doom engines can't create new geometry at runtime, but they can **move** it. Corpo Wars' site kits (§0.1) use that: each kit map is a fixed grid of closed-off sectors, and when the map loads the kit code picks a layout from the seed and raises or lowers floors and ceilings to carve out rooms, doors, windows and fire escapes. It then furnishes and lights them, and marks entries and objective rooms. So **every block in every case is a new layout**, with no map files to author per block. On top of that come randomized objectives, spawns, loot and elite modifiers.

**The look:**
- Brick tower blocks 15 to 20 storeys high, with rows of identical windows
- Gutted lobbies, apartment corridors with doors on both sides, and stairwells with graffiti
- Laundry rooms, boarded windows and burned-out cars
- Chain-link fences, dumpsters, courtyards with dead playgrounds
- Clotheslines, rooftops connected by planks and short jumps
- Basement drug labs
- The concrete Wall itself, with floodlights and checkpoint booths
- **The megacity beyond the Wall:** the skyline in every window and over every street (the Corpo Wars `CSKY` sprites and sky), an elevated highway across one edge of some street blocks, neon and shop signs (Corpo Wars sign sprites), subway entrances (the K4 transit variant), police barricades and dead squad cars

Use the Corpo Wars textures (brick, concrete, the AD and AX sets) that the kits already reference, plus Freedoom's bricks. Add graffiti and boarded-window textures in M12. The look matters a lot here: keep a mood board of real housing projects and city blocks (private, never shipped) and compare screenshots against it at every level milestone.

**Climbing the towers, a floor per block.** Doom maps are 2.5D, so floors can't sit on top of each other. Instead of faking a whole tower in one map, **each block in the Stacks and the Crown is one floor**, and the far stair core is the exit to the next floor up. Climbing the tower *is* the raid's progress. Windows look out on the Corpo Wars city-skyline sprites so the height reads. The rooftop variant is the top of a tower.

**Three sources of maps:**
1. **Generated blocks: Corpo Wars site kits, ported and rebuilt for the Bricks (M2b).** These are `NBC_K1` (street, from K01), `NBC_K2` (residential floor and rooftops, from K02) and `NBC_K4` (basement, garage and tunnels, from K04). Each is a template map from `genmap.py` plus a kit class. The variant and layout come from the case seed. The kit's own pipeline places the rooms, doors, furniture, lights and entries. **The NBC layer adds:**
   - spawn spots: from patrol and people rooms; windows and balconies become perches
   - the squad start and the extraction point: at the kit's entries
   - objective markers: from the kit's objective-room picker
   - rubble piles
   - residents: in civilian rooms
   - defense spots for Hold the Block: a fortifiable building on the street kit, with the enemy's approach from the map edges

   Kit layouts already keep doors and corridors walkable for Doom monsters. Check that they fit the squad too, and widen them to the scale above if not.
2. **Hand-built hero maps (you build these in Ultimate Doom Builder).** These are Checkpoint 9 (with every precinct room built in, boarded up until it's reopened, §2.6), the Safe Apartment and the three boss arenas. Use UDMF format with the "GZDoom: Doom 2 (UDMF)" config, and drop the NBC things into place.
3. **Pools.** `map_pools.zs` lists, per gang, which kit and variant their approach block, mansion floors and leader floor can be, with weights and the objectives each variant supports (§6.7, §6.9).

**Turfs and mansions.** The Bricks map has **6 turfs** around the Crown. Each case puts 4 gangs on them; two gangs hold a second turf each and are stronger for it.
- **Approach block:** the street on that gang's turf (`NBC_K1`; along the Wall it shows checkpoint ruins, burned cars and corner stores).
- **Mansion floors:** the gang's stronghold, a brick tower, a garage or a converted building, using the kit variants listed for that gang in §6.9.
- **Leader's floor:** a normal kit floor, with the leader in its deepest objective room and the gang's best units around them. Only the **Crown's penthouse and roof** are hand-built (the final fight: BruteMiniGUN, then the Landlord escapes across the roof as a Rooftop Pursuit).

Which tiers and turfs feel hardest comes from the gang (§6.9), not from a fixed district order.

---

## 5. Milestones and Codex prompts

**How to work with Codex:**
- **M0 through M2 are done. Start Codex at M2b.** Read `docs/STATUS.md` first.
- Use **Codex CLI or the IDE extension running locally on Windows**, not Codex Cloud. It has to run `uzdoom.exe` for smoke tests.
- Give it **one milestone per task**. Each prompt below can be pasted as-is. Codex reads `AGENTS.md` automatically.
- After each milestone, **you** play through the checklist (Codex can't play), commit, and paste any bugs back as a follow-up, with the exact console output.
- If a milestone feels too big, tell Codex: "do only the first half of M_, stop, and update STATUS.md."

---

### M0 — Repo, toolchain and asset import — ✅ DONE (2026-10-26, by Claude)
**What exists** (details in `docs/STATUS.md`):
- A git repo with `.gitignore`.
- `nbc/` holding the enemy pack and all 11 weapon packs:
  - DECORATE under `nbc/actors/`, ZScript under `nbc/zscript/imported/`
  - sprites and sounds under `nbc/{sprites,sounds}/{enemies,weapons/<pack>}/`
  - one merged `SNDINFO.txt` and `GLDEFS.txt`, and `CREDITS.txt`
- **Kept as reference only:** the FragGrenade code (its sprites and sounds stay active for M1c), each pack's INFO, OLDCODE and OLDGLDEFS files, and the Machete's key-config file. They're in `reference/weapons/<pack>/`.
- `GAMEINFO.txt` (title "NEW BRICKS CITY") and `MAPINFO.txt`.
- The test map `NBC_TEST`: a brick room with a pillar, 5 vanilla monsters (replaced by human enemies) and a parked voxel car. Rebuild it with `tools/make_test_map.py`.
- **Tools:**
  - `check_lumps.py`: duplicate lumps, SNDINFO targets, duplicate classes and DoomEdNums, missing sprites, voxels that would replace sprites. Accepted pre-existing issues are in `lumps_allow.txt`.
  - `list_textures.py`, `extract_wad.py`, `build_pk3.py`, `run.ps1`
  - `smoke_test.ps1`, verified to pass the clean build and to fail on a planted script error
- `tools/import/` holds the one-time import scripts, kept as a record. **Don't re-run them** after M1 starts; they regenerate the root lumps.

**You check** (needs a human): run `powershell -File tools\run.ps1 -Extra "+give all"`.
- Fire every weapon.
- The enemies should be humans.
- There should be no "?" sprites.
- The flashlight should work, the Dual Berettas should reload, and a Molotov should set enemies on fire.

---

### M0b — Import from Corpo Wars — ✅ DONE (2026-10-26, by Claude)
**What changed from the original plan:** the Corpo Wars code turned out to be tangled (§0.1), so it was **not** copied into `nbc/zscript/cw/` half-wired. Instead:
- The complete source is in `reference/corpowars/`.
- `docs/corpowars-port-map.md` lists each system's files and outside dependencies.
- Each later milestone ports its system into `nbc/zscript/cw/`.

**Already in `nbc/` and loaded:**
- Assets:
  - 438 Corpo Wars textures in `textures/cw/`
  - decor, sign, skyline, breach and gadget sprites in `sprites/cw/`
  - 71 OBJ prop models in `models/props/` (MODELDEF waits for M2)
  - city brightmaps in `brightmaps/city/` (GLDEFS waits)
  - breach sounds, with `cw/breach/*` in SNDINFO
- Civilians2 sprites in `sprites/civilians/` (its DECORATE replaces ZombieMan, so it's reference only).
- **Voxel cars** (`voxels/` + `actors/cw/vehicles.txt`): active, with one parked in NBC_TEST and confirmed rendering in game.
- Kit template maps `maps/NBC_K1`, `NBC_K2` and `NBC_K4`. These still use Corpo Wars thing numbers until M2.

The Python tools are in `tools/cw/`. Credits are merged into `nbc/CREDITS.txt`. **No weapons or weapon art were taken.**

**Owner TODO:** the Machete pack and Civilians2 ship no credits. Add their authors to `nbc/CREDITS.txt`.

---

### M1 — Integration, player class and loot remap — ✅ DONE (2026-10-27)
**Prompt:**
> Do PLAN.md milestone M1. Create `NBC_Player` (§4.3) and make it the only player class. Set weapon slots: 1 = FistsOfFury, CombatKnife, Machete; 2 = Colt45, Dual92; 3 = PumpActionShotgun; 4 = MicroUzi; 5 = AK47; 6 = MolotovCocktail (throwables). Leave slot 7 for future heavy weapons. Make the flashlight a toggle on its own key (KEYCONF alias → netevent or an inventory toggle) instead of a weapon. Bind `+reload` to R by default. Don't merge Machete's KEYCONF. Leave the FragGrenade out of the game for now (it becomes the debris throw in M1c). Use three **reserve** ammo types: `NBC_LightAmmo` (Colt, Uzi, Dual92), `Shell` (shotgun), `NBC_RifleAmmo` (AK). Magazines come in M1b. MolotovAmmo stays as it is, with a maximum of 5. Patch the imported weapons to use them, with pickups reusing the existing sprites. Remove the Molotov's 25013 editor number if nothing uses it. Gang enemies (tier 1 in D1–D2) have an 8% chance to drop a Molotov, and machete-style melee enemies (if any) drop the Machete. Write `NBC_Loot.CheckReplacement` to remap the vanilla weapons and ammo enemies drop (including Thuggundropper's drops) to ours, and remove vanilla weapons from the game. Remove the ally base classes listed in PLAN.md §0 (specopM*, specopF*, MiltiaShotgun*, Sniper, Sniper2) from every enemy RandomSpawner and choice list, and check that every spawner still has at least one entry. Start inventory: Fists, Colt45, 24 light ammo. Smoke test must pass.

**Done when:** no vanilla Doom weapon can appear, every enemy drop is one of our items, slots don't conflict, and no ally-looking enemy can spawn.

**You check:** kill 20 enemies of mixed types, pick up the drops, and switch through slots 1–5. `summon WolfensteinSS` ten times should give only terrorists.

---

### M1b — Reloading for every firearm — ✅ DONE (2026-10-27)
**Prompt:**
> Do PLAN.md milestone M1b (§2.2, §4.3 NBC_ReloadWeapon, §6.1). Write the `NBC_ReloadWeapon` ZScript base class, starting from Corpo Wars' working pattern in `reference/corpowars/zscript/corpowars/gear.zs` (read it; don't port its weapons: CW_ServicePistol's magazine + reserve, CW_Shotgun's interruptible shell loop). Port Colt45, Dual92, PumpActionShotgun, MicroUzi and AK47 (the packs in `Weapons/`, and only those) to ZScript subclasses (NBC_Colt45 and so on) that keep their sprites, sounds, damage, spread and fire timing. **Give every attack a damage type** through its puff or projectile: `NBC_Light` (Colt, Dual92, Uzi), `NBC_Shell`, `NBC_Rifle`, `Melee` (fists, knife, machete), `Fire` (Molotov), `Blunt` (debris). The gang profiles in §6.9 key off these. Replace the originals everywhere: player slots, loot remap and pickups. Leave the original DECORATE files in place but unused, as reference. Each weapon gets its own magazine Ammo class sized from §6.1, and draws from its reserve type. Reload styles: Dual92 uses its own R92L/R92R/D92R frames and B92REL sounds. The shotgun goes shell by shell; check the unused XSTR frames and XMDBLOAD/XMDBOPN/XMDBCLS sounds and use them if they fit, otherwise use the dip. The Colt, Uzi and AK use the in-engine dip reload (smoothly offset the weapon sprite down about 60 px and back up, as Corpo Wars' gear.zs does), with placeholder sounds: B92REL1–3 for the Colt and Uzi, and the enemy pack's e30COCK for the AK's rack. Don't import weapon art from anywhere else. Rules: R reloads; firing empty auto-reloads (or dry-clicks with no reserve); a full magazine can't be reloaded; reloading from empty adds rack time; switching weapons cancels; the ammo moves at a 70% commit point; pressing fire stops a shotgun reload. Read reload speed and magazine size multipliers from the player (for perks later). HUD: `magazine / reserve`, a low-magazine color, and a "RELOAD" prompt when empty. Add `nbc_debug_weapon` (prints the magazine, the reserve and the reload state).

**Done when:** every firearm reloads, nothing duplicates or loses ammo, and you can't double-reload.

**You check:** empty each gun and confirm auto-reload. Switch weapons halfway through a reload, then switch back. Interrupt a shotgun reload by firing. Pick up ammo with a full magazine. Save and load in the middle of a magazine.

---

### M1c — Quick-throw bricks and debris — ✅ DONE (2026-10-27)
**Prompt:**
> Do PLAN.md milestone M1c (§2.3, §4.3 NBC_QuickThrow and NBC_Debris, §6.8). Base it on the FragGrenade pack's code (`reference/weapons/fraggrenade/DECORATE`; its sprites and sounds are already loaded from `nbc/sprites/weapons/fraggrenade/` and `nbc/sounds/weapons/fraggrenade/`): reuse its wind-up idea (GrenSpeed, 12 steps) and its D3Grenade1 bounce settings, but strip the explosion and the pin pull. Implement the quick-throw key G (`+nbc_throw`/`-nbc_throw` KEYCONF aliases → netevents) on an overlay PSprite layer that works from any weapon. Lower the current weapon's sprite and block it from firing during the throw, and restore it afterwards (including in the middle of a reload, which should cancel safely). Tap = a light lob at speed 10; hold = wind up to speed 30; aiming higher throws further. Debris types, damage and behavior come from §6.8. Thrown debris uses +FORCEPAIN; a hit on an enemy under 35% HP triggers the arrest stagger hook (a stub until M9); it never damages allies. Impact: bricks have a 30% chance to drop as a reusable `NBC_LooseBrick`; other pieces break (spawn fragments). Every impact sends a `NBC_DebrisNoise(pos)` event (a stub; M9 uses it). Add `NBC_RubblePile` (a map thing; Use gives 3–6 pieces, its look changes as it runs out, then it's spent) and loose pickups for each type, with a carry limit of 3 (read from the player for perks). Art is **already made**; don't draw any. Use the finished lumps in `nbc/sprites/debris/` (listed in §6.8, with their grAb offsets already set). The hand holding a brick is BRKH A (the hold pose, at the frag's HGRNA offset) and BRKH B (the wound-up pose, at the HGRNQ offset). The release and follow-through reuse the frag's own HGT2 frames as they are (they show an empty hand). Note that HGT2E0 doesn't exist in the pack, so use A B C D F G H I J. The bottle reuses the Molotov pack's unlit bottle and glass-debris sprites (MOLT/MOGT/MDEB; verify which frames fit). Placeholder sounds: frag throw for throwing, a punch or thud for impact, Molotov glass for bottles. HUD: a debris icon, the count and the next type; a scroll key (`nbc_debris_next`, default H) cycles the type. If the overlay approach turns out unreliable, use the slot-0 weapon fallback from §4.3 and write down why in STATUS.md.

**Done when:** you can grab bricks off a rubble pile and throw them in the middle of a firefight without switching weapons, and enemies stagger when hit.

**You check:** throw while reloading, while switching weapons and while firing. Wind up a full throw across a courtyard. Bounce a brick off a wall. Pick a whole brick back up. Hit an ally on purpose and confirm no damage. Run out of debris and confirm G does nothing harmful.

---

### M2 — Obsidian districts, the hub and the vertical slice — ✅ SLICE PLAYABLE (2026-10-27, by Claude; needs playtest)
**Changed course (owner, 2026-10-27):** levels come from **Obsidian**, not from ported Corpo Wars kits.
Obsidian can't run inside UZDoom, so districts are built ahead of time into a **pool**:
- `tools/Obsidian/make_bricks.ps1` builds the New Bricks City theme (`tools/Obsidian/addons/NewBricksCity/`): city blocks, steep multi-level buildings with stairs, lifts and balconies, parks, Corpo Wars room sets, voxel cars and debris. `export_maps.py` writes `nbc/maps/NBC_CT01…` and `nbc/districts.txt` (the pool the game reads).
- Obsidian places only a light monster layer. The game removes it on load and uses those spots for its own gang spawns, so **the game, not Obsidian, sets the enemy count**.
- **NBC_HUB** (Checkpoint 9) is a hand-made precinct: the raid board, the armory crate, the exit to the street.

**The vertical slice loop:**
1. The raid board (Use) starts a case if none is running: seeded, day 1, 0 strikes, 4 gangs from `nbc/gangs.txt` each holding one district from the pool.
2. Pick a district → raid. The game replaces Obsidian's monsters with that gang's roster (a budget from the gang tier and alert), puts the **gang leader** (an elite) near the map's exit, and spawns **2 officers** (`NBC_Ally`) with the player.
3. Take down the leader, then exit → gang **toppled**. Exit early → retreat (day lost, gang on alert). Lethal damage → **OFFICER DOWN** → strike, back to the hub.
4. Back at the hub: a results card, the day advances. Topple all 4 → case closed. 3 strikes or day 30 → case over.

The full city map, staging flat, intel and gang tick stay in M7b and later.

*Superseded in part (owner, 2026-10-27): levels go back to our own kits (§4.4, M2b). The hub, raid board, gangs, RunData, squad, leader and Officer Down code all stay; only the Obsidian districts are replaced.*

**Done when:** you can start a case at the hub, raid every district, topple a gang, go down and take a strike, and close or lose the case.

---

### M2b — Our own level architecture: the Bricks kits — ✅ BOOTS, NEEDS PLAYTEST (2026-10-27, by Claude; see STATUS.md)
**Prompt:**
> Do PLAN.md milestone M2b (§4.4, §6.7, the "Runtime level generator" row of §0.1). Read `reference/corpowars/Design Docs/site-kits.md` and the "Site kits" section of `docs/corpowars-port-map.md` first. Port the kit base (`kitgen.zs`) and three kits into `nbc/zscript/cw/`: `kit_street.zs` (K01), `kit_residential.zs` (K02) and `kit_underground.zs` (K04), plus `procgen.zs`, `stairs.zs` and `themes.zs`. **Reuse** the furniture, kitprops and decor classes already ported in `nbc/zscript/cw/`; don't port them again. Cut every tie to Corpo Wars' mission layer listed in the port map (contracts, ledger, city, CW guards, bystanders, the drop crate): replace guard placement with NBC_SpawnSpot output, bystanders with resident spots (empty until M9), and extraction with NBC_Exit. Rename a class to `NBC_` once you change what it does.
>
> **Rebuild the kits for the Bricks, true to the setting:** apply the scale in §4.4 (widen corridors and doors where the squad needs it), the textures and dressing in §6.7, the city skyline outside every window and over every street, and lighting per room. K02 tenement is the default tower floor: a corridor between two stair cores, flats on both sides with real rooms (living room, kitchen, bedroom, bathroom), an elevator lobby, fire escapes. K02 rooftops is the top of a tower. K01 becomes the street block at the foot of the towers. K04 is basements, garages, tunnels and the subway (transit variant).
>
> **The NBC layer:** spawn spots from patrol and people rooms (perches from windows and fire escapes), the squad start and NBC_Exit at the kit's entries, rubble piles in derelict and outdoor rooms, resident spots in civilian rooms, objective markers from the kit's planner, and a defense spot on K01 (for M7c). The kit variant and layout come from the case RNG in `NBC_RunData`, never bare `random()`.
>
> **Switch the M2 slice onto the kits:** replace `nbc/districts.txt` with `map_pools.zs`, which lists per gang the kit and variant for their approach block and mansion floors (§6.9). For now a raid is **one block**: the gang's first mansion floor, with the leader placed in its deepest objective room (M3 adds the full approach → staging flat → floors sequence). Drop NBC_CT01–04 from the district pool, but leave the maps loadable. Remove placed monsters from kit maps as the slice already does.
>
> **Debug:** `nbc_kittest <kit> <variant> <seed>` loads a kit directly; `nbc_debug_kit` prints the rooms, entries, spawn spots and objective rooms. Run every variant × 3 seeds and fix any `Kit: <room> is unreachable` message.

**Done when:** every raid in the slice runs on a seeded kit floor that reads as a real building, and the same seed gives the same floor.

**You check:**
- `nbc_kittest` every K02 and K01 variant with 3 seeds. Walk them: do they look like a housing tower and a city street? Compare screenshots with your mood board.
- Can two officers follow you through every corridor, door and stairwell without blocking you?
- Raid every gang in a case and confirm their floors use the right kit variants.
- Look out of the windows: skyline, rows of windows on the facades opposite.


---

### M2c — The Bricks kit layouts, from scratch — ✅ BUILT, NEEDS PLAYTEST (2026-10-27, by Claude)
**Decision (owner, 2026-10-27):** the Corpo Wars kit layouts aren't up to standard and cover settings the Bricks doesn't need, so every layout is written new for New Bricks City. Only M2b's carving engine (`nbc/zscript/cw/kitgen.zs`) stays. The kits are `nbc/zscript/nbc/kit_*.zs` on new template grids (`tools/make_kit_maps.py`), at the measured scale in §4.4:
- **Tower floor** (`NBC_KT`): stair cores at both ends, a corridor, flats on both sides (studios to four-bay flats: bathroom, hall and kitchen by the corridor, bedrooms either side of the living room at the windows), the lift lobby with the trash chute and laundry. Variants: occupied, gallery (an open-air deck along one face), gang floor (knocked-through flats, barricades, stash/cook/counting/lookout flats), burned-out, penthouse.
- **Street** (`NBC_KS`): the foot of the towers: the tower entrance, a courtyard, a bodega and corner stores, a chain-link lot, the alley, the Wall.
- **Basement** (`NBC_KB`): boiler and laundry, storage cages, a cook lab, the fight pit, the garage, a tunnel under the Wall.
- **Roof** (`NBC_KR`): parapets, the stair hut and lift machine room, water tanks, plank bridges to the next tower.

---

### M2d — Back to Obsidian: finish the New Bricks City theme — 🔧 IN PROGRESS (2026-10-28)
**Decision (owner, 2026-10-28):** Obsidian is the level base (§4.4). Steps:
1. **Build Obsidian in the cloud** so maps can be generated and checked here. ✅ A console-only source build of Obsidian 20 (github.com/obsidian-level-maker/Obsidian) runs `tools/Obsidian/make_bricks.sh`, the Linux twin of `make_bricks.ps1`; a level builds in about 4 seconds.
2. **Raids run on Obsidian districts again:** restore the M2 district pool (`nbc/districts.txt` lists NBC_CT maps; the RunManager replaces Obsidian's monsters with the gang). The kits leave the raid pool but stay loadable.
3. **Finish the theme:** find every Doom prefab and texture still reaching the maps (screenshots and `inspect_udmf.py`) and swap it for a New Bricks City one: wall and floor textures, doors, wall decor and light fixtures, techbase and hell props, liquids, skies.
4. **Settings:** start from the Urban settings the owner found good, then tune for city blocks.
5. **Environments** (owner, 2026-10-28): the theme supports streets, housing towers, rooftops, an industrial park, parks, underground (basements and sewers) and the subway as separate Obsidian level themes, dealt across a build; buildings vary their facades. ✅ First pass built; see STATUS.

### M3 — The case and raid loop (the heart of the roguelite) — ✅ BUILT, NEEDS PLAYTEST (2026-10-30, by Claude)
*Done (2026-10-30): Backing (§2.5, §6.10, `NBC_RunData.AddBacking`), Merit banked after every raid at M8's rates (`nbc_merit`; spending stays M8), the §6.11 grade (accuracy, par time), the Crown placeholder (the `crown = 1` gang in gangs.txt on a borrowed tower map; topple 3 and it opens, take it to win), the case summary, and the debug netevents `nbc_day`, `nbc_skipblock`, `nbc_debug_backing`, `nbc_debug_topple` (the seed is the `nbc_seed` CVar). Owner decisions: going down still costs half of the raid's take, not all your Cash. Superseded by the Obsidian decision (§4.4): the five-block raid (approach, staging flat, floors, leader's floor) is one district map per raid; the staging flat's Intel and Informant come with M7.*
*Note (2026-10-27): M2's vertical slice already delivers the core of this (RunData, the RunManager, gangs.txt, Officer Down, the case ending), and M2b moves it onto the kits. What remains: the full multi-block raid on the kits (approach → staging flat → 2 floors → leader's floor), Cash, the results screen, Backing's strike, debug commands and save/load checks. Reuse the slice's code rather than rewriting it.*

**Prompt:**
> Do PLAN.md milestone M3 (§2, §4.3 NBC_RunData, NBC_RunManager and NBC_Gangs). Implement `NBC_RunData` (a STAT_STATIC thinker holding the case and the current raid), `NBC_RunManager`, `map_pools.zs`, the Officer Down intercept in `NBC_Player.DamageMobj`, and a first `nbc/gangs.txt` with the names, mansions and kit variants from §6.9 (rosters and traits come in M4 and M7b).
>
> **Starting a case:** at NBC_HUB, a temporary **list menu** (the real city map comes in M7b) starts a case. It seeds from the system time, puts 4 of the 6 gangs on turfs, and sets day 1, 0 strikes and the start loadout. The menu then lists the gang mansions, with RAID and CLOSE DAY options.
>
> **A raid** takes the day:
> 1. The approach block (NBC_K1, the gang's variant)
> 2. NBC_SAFE (the staging flat)
> 3. Floor 1 and floor 2 (the gang's mansion kit)
> 4. The leader's floor
>
> Each block's kit, variant, seed and objective are drawn from the case RNG. For now the exit is always unlocked (objectives come in M4 and M9). Clearing the leader's floor topples the gang. Back at the hub, the day advances.
>
> **Officer Down:** a lethal hit → a 2-second "OFFICER DOWN" sequence (red fade, a heartbeat-style sound, centered text) → +1 strike, half the Cash lost, back to the hub with inventory and health reset, and the day advances.
>
> **The case ends** at 3 strikes or after day 30; once 3 gangs are toppled, the Crown raid appears (a placeholder until M10). Draw all randomness from the case's seeded RNG stream (the seed plus a step counter).
>
> **Debug commands (netevents):** `nbc_debug_case`, `nbc_skipblock`, `nbc_seed <n>`, `nbc_day <n>`.
>
> **Minimal HUD:** day and strikes, the gang and floor name, health, armor, ammo, Cash.
>
> **Backing (§2.5, §6.10):** store it in RunData (start 60), apply the changes this milestone can already see (retreat, going down, gang toppled), and turn 0 Backing into a strike that resets it to 40. Later milestones add their own changes through one `NBC_RunData.AddBacking(n, reason)` call.
>
> **Results screen** (`NBC_Results`, §4.3, §6.11): replace the M2 results card. It opens after every raid: title, kills out of total, accuracy, health lost, time, the letter grade, each officer with kills and a DOWN or promotion stamp (placeholder boxes until portraits exist), seized weapons with counts, Cash, Merit (0 until M8) and the Backing change. CONTINUE returns to the hub.

**Done when:** you can start a case, raid a gang through all five blocks, topple them, go down on another raid and take a strike, and the same seed gives the same city and the same floors.

**You check:** raid two gangs, then go down on purpose. Confirm the strike, the lost Cash and the day advancing. Save in the middle of a raid, load the save and check `nbc_debug_case`. Use `nbc_day 30` to end a case. Start a new game from the title screen and confirm no case is active.

---

### M4 — Spawn director, enemy tiers, elites and the "Sweep" objective
**Prompt:**
> Do PLAN.md milestone M4 using §6.2 and §6.9. Implement `NBC_EnemyTiers`, `NBC_Director`, `NBC_Elites`, the `NBC_Objective` base class and its first objective, `Sweep` (clear the threat budget). Fill `nbc/gangs.txt` with every gang's roster per tier (the choice classes in §6.9), damage-factor profile and identity flags. Apply the profile to each spawned enemy with a hidden `NBC_GangProfile` inventory item whose `ModifyDamage` (passive) scales incoming damage by type. Implement these identity mechanics now:
> - swarm (budget and health)
> - fire immunity
> - vests
> - stagger resistance
> - the Iron Pit's fire weakness
> - the long-range accuracy and close-range delay
> - the Collectors' alarm wave
> - morale: runners head for the nearest exit and can be arrested later
> - explosive barrels and sandbags dressed into the mansion floors
>
> Leave lookouts, ambush and "cover blows faster" for M9. Use the budget formula in §6.2. Enemy pathing uses Corpo Wars' `nav.zs` graph (port it from `reference/corpowars/`; per the port map it only needs `CW_Blocker`), which builds automatically on any map. Spawn in 2–4 waves; the next wave starts when 70% of the current wave is dead or after 30 seconds. Spawn at spots the player can't see and that are at least 384 units away; perches (role 1) get tier 1–2 shooters. Use a short spawn-in effect. The objective unlocks NBC_Exit and announces "BLOCK SECURE". Elites: the chance comes from the gang's tier (§6.2). Modifiers (pick 1; tier-3 gangs and the Crown can roll 2): Armored (2× health, takes 0.5× damage from bullets), Wired (1.4× speed), Volatile (explodes on death), Shot Caller (calls 3 low-tier enemies at 50% health), Landlord's Own (3× Cash plus a guaranteed Intel shard). Show elites with a translation, and show their name when you aim at them. Remove placed vanilla monsters from generated maps. Add a `nbc_debug_director` command that prints the remaining budget, the current wave and the living enemies.
>
> **Surrender (`NBC_Morale`, §4.3):** once the objective (or the leader) is done and about 75% of the block's crew is down, the rest drop their guns and kneel for 20 seconds (use an idle or pain frame held still; no new art), cuffable with Use. Uncuffed ones then run to the map edge and despawn. Print "BLOCK SECURE: head for the exit" and post "They're running!" to the squad log. Gangs with the morale weakness break at 50%.
>
> **Cap enemy explosives** (the biggest complaint about *Hamburger Hill*): at most **one** enemy may throw a grenade or Molotov, or fire a rocket, at a time across the block; each throw has a 0.6-second wind-up with a sound cue, never targets something it can't see, and the same enemy waits at least 8 seconds before the next. Check every grenade, Molotov and rocket user in the enemy pack and route them through this limit.

**Done when:** blocks feel like real fights that get harder with depth, and the exit only opens after a clear.

**You check:** a tier-1 gang is fair with the Colt and fists; the Quiet and the Crown are dangerous; each gang you raid plays noticeably differently. Enemies never spawn on top of you, and nothing soft-locks.

---

### M5 — Squad I: one officer that works
**Prompt:**
> Do PLAN.md milestone M5: §2.1 and the NBC_Ally and NBC_SquadManager rows of §4.3. Do not rely on the built-in FRIENDLY behavior. The pack's enemies have +NOTARGET, +NOINFIGHTING and DamageFactor "Enemy" 0, and their projectiles use DamageType "Enemy" (see actors/bullets.txt); confirm this in the code first. Build the `NBC_Ally` base class and one subclass, `NBC_PatrolOfficer`, using specopM sprites and a navy police translation, with an SMG firing AllyTracer (or an NBC tracer without the Enemy damage type). Implement: formation following (keep 96–192 units away, slot offsets behind and beside the player); custom target-finding (the nearest visible hostile within 1,536 units, preferring enemies that are targeting the player; hold fire if the player is in the line of fire, checked with LineTrace, and sidestep); **pathing on Corpo Wars' `nav.zs` graph** (auto-built on every map, including kit floors) when the player isn't in a straight line; catch-up teleporting only as a last resort (more than 1,024 units away and unseen for 3 seconds → a free spot behind the player); no friendly fire either way (including splash damage and Molotov fire: give allies DamageFactor "Fire" 0, since the fire may not credit the player as the attacker); a downed state at 0 HP with a 20-second bleed-out; revive with Use (an Actor.Used override) after staying within 64 units for 2 seconds, back at 40% HP; a downed officer within 192 units of the exit when you leave is carried out alive; and **killed** if the bleed-out finishes (a death sound, a body that stays, "Officer down — [name] is gone" in the squad log; the roster removal comes in M6). In NBC_SquadManager: spawn the squad from the RunData snapshot at NBC_SquadStart (or near the player start) on WorldLoaded, save its health and state before the exit, and retarget enemies onto allies (each second, an enemy targeting the player has a 35% chance to switch to a closer visible ally). Add a floating chevron marker or name over each ally, and a HUD squad strip showing name, health, state and bleed-out timer. For M5, every raid starts with one Patrol Officer. Add debug commands: `nbc_squad_add <class>`, `nbc_squad_down <i>`, `nbc_debug_squad`.

**Done when:** a single officer is clearly useful, survives between maps and is never a burden: no blocking doorways, no shooting you, no getting lost.

**You check:**
- Do a full raid on a tier-1 gang with the officer.
- Run through doors and up stairwell teleports, and confirm the officer keeps up.
- Shoot the officer on purpose and confirm no damage.
- Let the officer go down, revive them, then let them bleed out.
- Check that enemies sometimes shoot at the officer.

---

### M6 — Squad II: classes, orders, roster and ranks
**Prompt:**
> Do PLAN.md milestone M6 using §6.5. Every class (including the Patrol Officer from M5) gets the reload pauses in §6.5, with a callout, and officers stagger their reloads so they don't all reload at once. Add the classes NBC_Breacher (MiltiaShotgun sprites), NBC_Marksman (Sniper sprites) and NBC_Paramedic (specopF sprites), each with its own police translation and the behavior in §6.5. The Breacher opens closed doors ahead of the squad when ordered to move through them. The Marksman prefers holding a spot with a long sightline. The Paramedic heals the player when they're under 50% HP (once per 20 seconds) and revives in 1 second. Orders: KEYCONF aliases `nbc_order_follow`, `nbc_order_hold`, `nbc_order_move`, `nbc_order_holdfire` and `nbc_order_free` → `netevent nbc_order N`, with default binds Z/X/C/V/B. "Hold" and "Move" pick the nearest free spot (within 128 units of the target) that enemies in the block can't see, falling back to the exact point; "Move" puts a goal marker where the player is aiming (LineTrace) and shows it briefly. "Hold Fire" stops them shooting unless they're shot at; "Weapons Free" undoes it. Each order plays an acknowledgment sound (placeholder) and goes into the **squad log** (a few lines, bottom left, fading). Build `NBC_Roster` on the `nbc_roster` CVar: recruiting by class with prices and an AUTO button, generated names, XP and ranks (Officer/Corporal/Sergeant: +15% HP, +10% accuracy, faster reactions and one more kit slot per rank), hospital (an officer who went down spends 2 days there), **deaths in the line of duty** (an officer who bled out is removed from the roster and written to `nbc_memorial`), and a 1-slot squad limit for now (slots come from unlocks in M8). Build the Squad Room menu in NBC_HUB in the deploy-screen layout (§2.7): roster on the left with a count per class, squad slots in the middle, the officer's details on the right (rank, XP, raids, hospital days), plus RECRUIT and AUTO. Add the memorial wall: a map thing in the Squad Room that lists the fallen when used. Start every new save with 2 free Patrol Officers on the roster.

**Done when:** you choose who comes along, they act differently, and losing one stings.

**You check:** order "hold" at a corridor, run ahead and confirm they stay, and that they stand somewhere sensible, not in the open. Order "move" across a courtyard, and have the Breacher open a door. Order "hold fire" and confirm they don't shoot until shot at. Let an officer go down and get revived: hospital for 2 days. Let one bleed out: gone from the roster, name on the memorial wall.

---

### M7 — Economy, the Informant and Intel perks
**Prompt:**
> Do PLAN.md milestone M7 using §6.3. Seized Cash pickups (small, medium and large bills): each enemy has a 40% chance to drop Cash, scaled by tier, and elites always drop it. Kills by allies also drop Cash. Speed bonus: +25% if the block is cleared in under 90 seconds. Implement `NBC_SafeApartment`: 3 Intel pedestals with perks from the unlocked pool weighted by rarity (no duplicates unless a perk stacks; picking one removes the others), the Informant NPC (use it to open NBC_ShopMenu), and a first-aid station that heals all officers for a Cash price. Shop stock: Light ammo, Shells, Rifle ammo, a Medkit (25), a **Kevlar vest** (armor; `NBC_Light`/`NBC_Rifle` −30%), a **fire-retardant jacket** (`Fire` −60%), **flashbangs** (Corpo Wars' CW_ThrownFlashbang gadget: a 5-second stun on enemies in sight; thrown with its own key, not a weapon slot), one random weapon the player doesn't own, Radio for Backup (a temporary Patrol Officer for the next block only), and "Reroll Intel". Prices rise with the gang's tier. Purchases are validated in play scope through a netevent. Intel shards from elites: 3 shards give an extra perk pick. HUD: Cash, perk abbreviations and shards. Add `nbc_giveperk <name>`.

**You check:** buy each item once, try buying with no Cash, reroll, call in backup, and check that every perk (especially the squad perks) does what it says.

---

### M7b — The city map, gang dossiers and the daily gang tick
**Prompt:**
> Do PLAN.md milestone M7b (§2.4, §4.3 NBC_Gangs and NBC_CityMap, §6.9). Read Corpo Wars' `citymap.zs`, `citymapui.zs` and `citysim.zs` (in `reference/corpowars/zscript/corpowars/`), the "City map" section of `docs/corpowars-port-map.md`, and `reference/corpowars/Design Docs/city-layer-design.md`, then port the map screen. Keep the full-screen top-down plan, zoom and pan, keyboard and mouse selection, and the inspector panel; drop the corps, the market and the contracts.
>
> **The map data.** Write `nbc/bricksmap.txt`: the Wall as the outer ring with Checkpoint 9's gate, 6 turfs around the central Crown, and in each turf a mansion plus 1–2 side sites (stash house, lab, lookout roof). The case seed places 4 gangs from `gangs.txt` (two of them get a second turf) and rolls each gang's 1–2 random traits.
>
> **The inspector dossier** shows these fields, gated by intel level (`???` until earned):
> - **Level 1:** roster and strength
> - **Level 2:** signature tactic, weakness and the random traits
> - **Level 3:** the floor plan
>
> It also shows the gang's alert (0–3), whether it's toppled, and the **estimated crew size** on the turf itself (a ±40% range drawn once per day from the case RNG with no intel, exact from level 1). A top bar shows the day, Cash, Backing, strikes and the weather. A case-file tab shows days left, strikes, toppled gangs, the Crown's current defenses and a news line.
>
> **Actions:**
> - **RAID** starts the M3 raid on that gang.
> - **BUY TIP** costs Cash for +1 intel level; the price is 150 × (level + 1) × (1 + alert), doubled for the Quiet.
> - **CLOSE DAY**.
> - **STAKE OUT** is shown but disabled until M9.
>
> **Intel level 3 effects:** at raid start, mark the objective rooms and the leader's room on the automap; show guard posts on the radar (port Corpo Wars' survey and schedule effects); and enable the entry board in the staging flat.
>
> **Interrogation:** each arrest has a 25% chance to reveal that gang's next unknown trait, and Warrant targets always do (the hook is ready; arrests arrive in M9). Evidence ledgers give +1 level on a random other gang.
>
> **The daily gang tick** follows rules 1, 2, 4, 5 and 7 in §2.4: decay, fortifying, retaliation, the Crown growing, news. Rules 3 and 6 (reclaimed blocks, counter-raids, turf income and side jobs) come in M7c and M9; for now a toppled gang's turf simply stays empty. Keep the tick's numbers in one tuning class.
>
> Replace M3's temporary list menu with this map, opened from the wall terminal in NBC_HUB and with the M key. Add `nbc_intel <gang> <level>` and `nbc_simdays <n>` (a soak test that runs the tick n times and prints the result).

**Done when:** each new case shows a different Bricks, dossiers fill in as you buy tips, gangs react day to day, and toppling gangs strips the Crown's defenses.

**You check:** start 3 cases and compare the maps. Buy tips up to level 3 on one gang and confirm the automap marks, the entry choice in the raid, and the crew estimate turning exact. Raid one gang twice and watch its alert climb. Run `nbc_simdays 30` and read the log for anything silly.

---

### M7c — The deploy screen and the turf war
**Prompt:**
> Do PLAN.md milestone M7c (§2.4 rule 3 and 6, §2.5, §2.7, §6.6 Hold the Block, §6.10). Read `docs/hamburger-hill-analysis.md` for the screens this borrows.
>
> **Deploy screen** (`NBC_Deploy`, §4.3): every raid, defense and side job now opens it from the city map. Build it on the `CW_UiMenu` framework in the §2.7 layout: roster left, squad slots middle, kit right, a totals strip at the bottom, BACK and ASSAULT (DEFEND for a defense). Time of day (Day/Dusk/Night) sets the kit's outdoor light, the share of lamps that are on, and (Night) a third of the first wave spawning idle; store it in RunData. Weather is rolled per day from the case RNG: rain and fog are cosmetic for now (fog density; rain particles outdoors). Ways in: On foot always; Unmarked van needs the Motor Pool unlock (M8; for now enable it with `nbc_unlock`), Over the roofs needs Roof Access, Through the tunnels needs intel level 2 and a turf with tunnels. Each way in picks the matching kit entry for the approach block's player start. AUTO fills the slots with the healthiest officers in a class mix. Hospital officers are greyed out with their days left.
>
> **Kits:** each officer has a Primary (their class's issue weapon, or a matching seized weapon from the Evidence Locker, per §2.7), pouches by rank (1/2/3) holding Molotovs, medkits, debris or flashbangs, and an optional vest. A seized primary switches the officer's attack to that weapon's damage type and fire pattern (Uzi bursts `NBC_Light`, AK `NBC_Rifle`, shotgun `NBC_Shell`). Officers **use** their pouches: a Molotov at a group of 3+ enemies at least 256 units from the player (an officer's fire never hurts the player: filter it in `NBC_Player.DamageMobj`; allies are already fire-immune), a medkit on themselves under 30% HP. Kits come out of the locker at deploy and return after the raid; a fallen officer's kit is lost.
>
> **Reclaimed blocks and counter-raids:** a toppled gang's turf becomes a reclaimed block (shown in police blue on the city map) that pays turf income in the gang tick (§6.10). Add the counter-raid rule (§2.4 rule 3): the next day the block shows UNDER ATTACK with a card under the map's END DAY button. DEFEND runs **Hold the Block** (§6.6) on that turf's street kit; ignoring it or failing loses the block to the attacker. Two attackers at once is a two-front defense: two waves from opposite edges.
>
> **Backing** (§6.10): wire in every change (officer killed or hospitalized, resident killed, retreat, going down, arrests, clean raid, gang toppled, block defended or lost) and the high and low effects.
>
> **Debug:** `nbc_counterraid <gang>` forces a counter-raid tomorrow; `nbc_backing <n>`; `nbc_unlock <room>` (until M8).

**Done when:** before every raid you choose when, how and with whom you go in, your officers carry the guns you seized, and the gangs push back on the turf you've taken.

**You check:**
- Raid at Day and at Night on the same gang: is night darker, with more of the crew idle?
- Try every way in and confirm where you start.
- Give an officer a seized AK and watch them use it; give one a Molotov pouch and watch them throw it (never at you or the squad).
- Topple a gang, then `nbc_counterraid` a neighbor: defend the block once and lose it once. Check the income and Backing both ways.
- Let an officer die with a seized weapon in their kit and confirm it's gone from the locker.

---

### M8 — Meta progression: rebuilding the precinct
**Prompt:**
> Do PLAN.md milestone M8 using §2.6 and §6.4. Add CVARINFO entries for the meta CVars in §4.3. Merit: +2 per block, +15 per gang toppled, +1 per elite, +3 per arrest (once M9 adds arrests), +5 per officer brought home alive from a raid, +4 per block defended, +50 for taking the Crown. It's banked **after every raid**, whether it succeeded or failed. Add Merit and intel learned to the M3 results screen, and add a case summary when the case ends (days used, gangs toppled, strikes, blocks held, officers lost, total Merit).
>
> **Rebuilding the precinct.** Rebuild NBC_HUB (`tools/make_hub_map.py`) with every room in §2.6 built in, each behind a boarded door and dark, with `NBC_RoomMarker` things (arg0 = room ID) marking its door, lights, furniture spots and NPC spot. `NBC_Precinct` (§4.3) opens the rooms whose unlocks are bought: it removes the boards, raises the light, and spawns the room's Corpo Wars furniture and an officer NPC at the desk (a recolored specopM/F standing idle; no new art). The Captain's Office menu (NBC_BoardMenu; it lives in the Captain's Office, which is open from the start as a desk in the corridor until the room itself is reopened) lists the rooms and their unlocks with costs and state; buying sets bits in `nbc_unlocks`. Unlocks feed the start loadout, max health, the Intel pool, the shop, the ways in, hospital time and squad slots. Recruiting new officers (Squad Room) costs Merit. Armory locker: choose the starting sidearm and melee from what's unlocked. Options menu: "Reset New Bricks City progress" (Merit, unlocks, roster and memorial) with a confirmation. Replace M7c's `nbc_unlock` debug path with the real unlocks.

**Done when:** progress survives quitting UZDoom completely, unlocks plus squad choices change the next case, and you can see the precinct coming back to life.

> **The MVP is complete here.** Play 3 full cases before going further, and write down what's boring or frustrating, especially about the squad and how much scouting actually changes your plan.

---

### M9 — Objectives, undercover (ported stealth), stakeouts, residents and arrests
**Prompt:**
> Do PLAN.md milestone M9 using §6.6 and §2.4.
>
> **Objectives.** Add the objective classes Lab Bust, Evidence Run, Informant Extraction (an escort NPC built on the NBC_Ally follow code, using a Civilians2 sprite; it can't fight; if it dies, the objective fails and the reward is lost, but the exit still unlocks after a sweep), Rooftop Pursuit, Warrant and Foot Patrol. The RunManager picks from the objectives the kit variant supports (§6.7), never the same one twice in a row in a raid. **Escorts must behave** (*Hamburger Hill*'s rescue missions failed here): the informant always follows you, crouches in cover when you stop or a fight starts (the nearest spot out of enemy sight within 128 units), never stands in the open, and catches up by teleporting like an officer.
>
> **Side jobs** (§2.4): roll 0–2 per day in the gang tick (3 with the Radio Room, +1 at high Backing) from Foot Patrol, Evidence Run, Informant Pickup and Warrant, each on a gang's turf with its reward drawn up front. They show on the city map; selecting one opens a briefing card (a placeholder picture box, two lines of orders, the reward, ACCEPT and DECLINE). Accepting goes through the deploy screen and takes the day. A side job is one block.
>
> **Undercover: port Corpo Wars' stealth, don't write a new one.** Port from `reference/corpowars/zscript/` (the "Guard awareness" and "Civilians" sections of `docs/corpowars-port-map.md` list what they depend on) `guard.zs` (the unaware/suspicious/alert states, vision cones, the light, crouch and speed visibility meter, the noise radii, finding bodies) with UEAI. Make it drive the enemy pack's DECORATE enemies through a controller item given at spawn, with the HUD visibility meter. Undercover openers: 30% of blocks, plus "Night shift" (always) and the Quiet (never). The first wave spawns idle at their posts.
>
> **When cover blows:** the player is "carrying" with any weapon other than fists raised. Cover blows on gunfire noise heard, an alert guard, a body found, or an ally seen within 256 units. The Collectors and "Paid off" make cover blow 50% faster. **Lookouts** (Stoop Kings, the trait) blow cover if they see the squad at all. Ambush (the Quiet) spawns waves behind the player, and the flashlight reveals them.
>
> **Debris noise:** route `NBC_DebrisNoise` into the ported noise system (bricks 512 units, bottles 768). A thrown piece draws suspicious guards to look, and never blows cover by itself.
>
> **Takedowns become arrests:** Use behind an unaware or suspicious enemy is a silent takedown, as in Corpo Wars, which **cuffs** them (the HCUFF sound): +3 Merit and an interrogation roll.
>
> **`NBC_Arrest` in a fight:** below 20% HP an enemy has a 40% chance to stagger for 3 seconds (bricks under 35% always stagger), with a cuffs icon; Use within 64 units cuffs them. Warrant targets must be arrested for the full reward.
>
> **Fists for arrests:** a fist hit on an enemy under 35% HP always staggers it (like a brick), so you can cuff without firing a shot.
>
> **Residents:** port `CW_Civilian` with Civilians2 sprites into RF_CIV rooms. They flee gunfire, scream and alert nearby enemies if they see you shoot, and can be knocked out from behind. More are out on the streets by Day than at Night. **A resident killed by the player or the squad costs −5 Merit and Backing (§6.10) and shows on the results screen** (rules of engagement). Hostages (the trait) are residents tied up on the mansion floors: free them with Use for +4 Merit.
>
> **Stakeouts:** enable STAKE OUT on the city map. It's one approach-style block on that gang's turf, undercover, with 3 marked targets (a lookout, a stash, a face). Look at each one from cover for 2 seconds (a camera-style HUD frame) and then leave. Mark all 3 for +1 intel level. If cover is blown, there's no strike, but the gang goes +1 alert.

**You check:**
- Each objective can be completed and failed.
- Sneak through an opener, use a brick to pull a guard away, then cuff him from behind.
- Get spotted and watch the block go loud.
- Shoot near a resident and watch them run and scream.
- Do a stakeout to +1 intel, then blow one.

---

---

### M10 — Curfew Heat, gang leaders, the Crown and winning a case
**Prompt:**
> Do PLAN.md milestone M10.
>
> **Curfew Heat:** each block has a timer of 120s + 20s × floorIndex, paused while cover is intact. At zero, Heat goes up one level (max 3); each level adds a reinforcement wave (reinforcement spots preferred), +10% enemy health and +15% Cash. Heat resets each block, and the HUD shows the timer and the level.
>
> **Gang leaders** (§6.9): on each leader's floor, the leader holds the deepest objective room with the gang's best units, plus a health bar and a short intro line. Arresting the leader (stagger or a takedown) instead of killing them gives double Merit and a free intel level on the Crown.
>
> **The Crown:** two K2 luxury floors, then the hand-built `NBC_CROWN` penthouse and roof (build a placeholder; the owner will rebuild it in UDB). BruteMiniGUN has a phase change at 50% (PMC adds, flickering lights), then the Landlord escapes across the roof as a final Rooftop Pursuit. Apply the Crown's active defenses from the gang tick, minus those stripped by toppled gangs.
>
> **Winning:** a win screen → the case summary → unlock "Demolition Day" mode in the Captain's Office (+25% budget, elites ×2, 20 days instead of 30, Backing starts at 40). Optional Demolition Day rule, off by default: when you go down, you take over the nearest living officer instead (*Hamburger Hill*'s rule); the raid fails only when the whole squad is down. Allies must handle every leader floor and the Crown: no getting stuck.

---

### M11 — Parkour movement kit
**Prompt:**
> Do PLAN.md milestone M11. Add these to NBC_Player with BT_USER1–3 (bound in KEYCONF): **Dash** (a short burst, 1.2-second cooldown, once in the air), **Slide** (while sprinting, crouch for a low-hitbox slide with momentum and a 0.8-second duration), **Mantle** (**port Corpo Wars' ledge climbing** from `reference/corpowars/zscript/corpowars/player.zs`: Dodopod's code with the CW fixes, credited; climbs onto ledges and props), and **Wall-jump** (up to 2 before landing). Optionally port Corpo Wars' **tactical lean** (`lean.zs`) on Q/E for peeking corners. Add tilt or bob feedback and sounds. Give the K2 rooftops variant and the K1 street more mantle ledges, wider gaps and fire-escape routes. Allies don't parkour: they take the long way (stairs or a route marker) or catch up by teleporting. Make sure the squad never gets permanently left behind. Board unlocks: a second dash charge and "Slide-shot" (+30% damage while sliding).

---

### M12 — Content and polish
Split this across several Codex tasks:
- **Urban textures:** add graffiti, boarded windows and chain-link on top of the Corpo Wars set (CC-licensed and credited), and use them in the kits' Bricks restyle.
- **New weapons: only packs the owner adds to `Weapons/`.** Codex never sources weapons itself. Each new pack gets ported onto `NBC_ReloadWeapon` (with the dip reload if it has no reload frames) and assigned to the gangs it fits as a drop.
- **More gangs** as data in `gangs.txt` (e.g. a crew built on GangBike riders, or one on the Russian set) for more variety between cases.
- **Sounds:** brick, glass and thud sounds should be CC0 and credited. (The debris art is already finished, see §6.8.)
- **Squad voice callouts:** record your own lines or use licensed TTS ("Moving!", "Holding!", "Officer down!", "Clear!").
- **Weapon mods:** pickups roll Standard/Tuned/Custom.
- **Daily seed:** a case of the day (same city for everyone that day) on the city map terminal.
- **Title, HUD art, perk icons, gang emblems for the city map, police mugshot HUD face, music per gang turf** (CC-licensed, credited).
- **One bottom-bar HUD:** the squad log on the left; a portrait per officer that bloodies as their health drops (greys out when down), with a class icon and a rank chevron; your own face; the time of day, weather and a compass; pouch counts; magazine and reserve; the weapon. The portraits are new original art (a few faces × damage states); the results screen and deploy screen reuse them.
- **Briefing card pictures** for side jobs and the deploy screen (original art).
- **Balance logging:** a `nbc_log_balance` CVar that writes per-block time, damage taken, ally downs and kills to the log.
- **Release:** `tools/build_pk3.py` → `dist/NewBricksCity.pk3`, plus a README with the launch line, credits and the Freedoom 2 requirement.

---

## 6. Content tables (starting values; tune later)

### 6.1 Weapons

| Slot | Weapon | Reserve | Magazine | Reload (empty) | Reload art | Role | Availability |
|---|---|---|---|---|---|---|---|
| 1 | FistsOfFury | — | — | — | — | Silent takedowns; always staggers wounded enemies for arrests; doesn't count as "carrying" while undercover | Starting gear |
| 1 | CombatKnife | — | — | — | — | Silent, higher damage | Board unlock |
| 1 | Machete | — | — | — | — | Heavy melee, random swings, slower | Seized: dropped by tier-1 gangs, and the shop |
| 2 | NBC_Colt45 | Light | 8 | 1.2s (1.5s) | In-engine dip | Service sidearm | Starting gear |
| 2 | NBC_Dual92 (Dual Berettas) | Light | 30 | 1.8s (2.2s) | Its own frames and sounds | Fast dual pistols; the best sidearm | Shop; Board unlock as a starting weapon |
| 3 | NBC_PumpShotgun | Shell | 6 (tube) | 0.5s per shell (+0.4s pump when empty) | XSTR if usable, else the in-engine dip | Room entries; ignores the Collectors' vests | Drops and shop |
| 4 | NBC_MicroUzi | Light | 32 | 1.6s (2.0s) | In-engine dip | Seized from gangs | Drops and shop; Board unlock as a starting weapon |
| 5 | NBC_AK47 | Rifle | 30 | 2.0s (2.5s) | In-engine dip (e30COCK rack) | Seized rifle | Dropped by tier-2+ gangs; shop |
| 6 | MolotovCocktail | Molotov (max 5) | — | — | — | Thrown fire for crowds, labs and stairwells; burns you too | Gang drops (8%), the shop, and Lab Bust blocks |
| G key | Debris (quick throw) | Carried pieces (max 3) | — | — | Finished: BRKH A/B + the frag's HGT2 frames | Stagger, open arrests, distractions | Found in every level (§6.8) |
| — | Flashlight | — | — | — | — | Toggle key; needed in basements and stairwells | Always |

The weapon roster is only the packs in `Weapons/`. The in-engine dip reload is the intended look for guns without reload frames, not a placeholder.

### 6.2 Enemy tiers and the threat budget

| Tier | Cost | Role |
|---|---|---|
| 1 | 1 | Rank and file |
| 2 | 3 | Crew: better guns, more health |
| 3 | 6 | Heavies |
| 4 | 10 | Elite units |
| Leader | — | One per gang, on the leader's floor |

Which enemies fill each tier comes from the raid's gang (§6.9). The Director spawns the pack's **choice classes** (e.g. `eHOODYchoice`), not the vanilla-replacing spawners, so each gang gets only its own people with all their color variants.

**Threat budget** per block: `12 + 6 × floorIndex + 8 × (gangTier − 1) + 4 × gangsToppled + 6 × alert`. The approach block is floor 0, and the leader's floor adds +10.

**Tier unlocks:**
- Tier 3 appears from floor 1.
- Tier 4 appears on the leader's floor, or when the gang is at alert 2 or higher.

**Elite chance:** 5% for tier-1 gangs, 10% for tier-2 gangs, 15% for tier-3 gangs, 20% in the Crown.

### 6.3 Intel perks (the 1-of-3 picks)

| Perk | Effect | Rarity | Stacks |
|---|---|---|---|
| Hollow Points | +15% bullet damage | Common | ×3 |
| Steady Hands | −30% spread | Common | no |
| Deep Pockets | +50% max ammo | Common | ×2 |
| Asset Forfeiture | +25% Cash from drops | Common | ×2 |
| Kevlar Liner | −10% damage taken | Common | ×3 |
| **Tight Unit** | Allies +20% damage | Common | ×2 |
| **Issued Vests** | Allies +40% max HP | Uncommon | no |
| **Trauma Kit** | Revives take half the time and restore 70% HP | Uncommon | no |
| Second Wind | Heal 15 when a block clears | Uncommon | ×2 |
| Hair Trigger | Double fire rate for 4 seconds after a kill | Uncommon | no |
| Badge & Cuffs | Arrest chance 40% → 70%; arrests heal 10 | Uncommon | no |
| Adrenaline | +20% move speed under 30% HP | Uncommon | no |
| Firestarter | +2 max Molotovs; Molotov fire lasts 50% longer; your own fire does half damage to you | Uncommon | no |
| Akimbo Training | Dual92 reloads 40% faster, and magazine size goes 30 → 40 | Uncommon | no |
| Speed Loader | All reloads 25% faster | Common | ×2 |
| Extended Mags | +30% magazine size for every firearm | Uncommon | no |
| Brick Arm | Thrown debris does +50% damage and always staggers | Common | no |
| Rubble Rat | +2 debris carry limit; rubble piles give 2 extra pieces | Common | ×2 |
| **Backup En Route** | Once per raid, a free Radio for Backup | Rare | no |
| **Blue Wall** | When an ally goes down, you and the other allies get +30% damage for 8 seconds | Rare | no |
| Off the Books | Survive one lethal hit per case with 25 HP (no strike) | Rare | no |
| Deep Cover | Undercover openers 2× more likely; cover takes 50% longer to blow | Rare | no |

### 6.4 Precinct rooms and their unlocks (meta, §2.6)

Reopening a room costs its listed price and gives its first unlock; the room's other unlocks are bought separately once it's open.

| Room | Unlock | Cost (Merit) | Effect |
|---|---|---|---|
| Squad Room (open) | **Recruit Officer** | 15 each (by class: Patrol 15, Breacher 20, Marksman 25, Paramedic 25) | Add an officer to the roster |
| Squad Room | **Breacher / Marksman / Paramedic Clearance** | 30 / 40 / 50 | That class can be recruited |
| Armory cage (open) | Spare Mags | 15 | +24 starting light ammo |
| Armory cage | Blade | 30 | CombatKnife can be chosen as starting melee |
| Armory cage | Seized Uzi | 40 | MicroUzi can be chosen as starting sidearm |
| Armory cage | Dual Service Pistols | 45 | Dual92 can be chosen as starting sidearm |
| Armory cage | Vest Issue | 35 | Start with 25 armor; one vest in the locker for an officer each case |
| Armory cage | Evidence Locker: Molotovs | 25 | Start each raid with 2 Molotovs |
| Armory cage | Street Smarts | 20 | Start every block carrying 2 bricks |
| **Captain's Office** (reopen 30) | **Squad Slot 2** | 40 | Bring 2 officers |
| Captain's Office | **Squad Slot 3** | 100 | Bring 3 officers |
| Captain's Office | Long Case | 60 | Cases last 35 days instead of 30 |
| Captain's Office | Case Files I–III | 25 each | Adds Rare perks to the pool |
| Captain's Office | Lucky Break | 60 | The first Intel pick offers 4 choices |
| Captain's Office | Demolition Day (M10) | Win once | Hard mode toggle |
| **Motor Pool** (reopen 45) | **Unmarked Van** | (with the room) | The van way in (§2.7) |
| Motor Pool | Radio for Backup | 25 | The shop stocks Radio for Backup |
| **Radio Room** (reopen 35) | Street Contacts | (with the room) | Informant tips cost 30% less |
| Radio Room | Dispatch | 30 | One extra side job each day |
| Radio Room | Informant Network | 30 | The shop stocks one extra item |
| **Infirmary** (reopen 40) | **Ward Beds** | (with the room) | Hospital stays 2 → 1 day |
| Infirmary | Precinct Doc | 20 | +10 starting max health (buy 3 times) |
| Infirmary | Trauma Training | 40 | Officers revive each other (2 seconds, within 64 units) |
| **Range** (reopen 30) | Range Qualification | (with the room) | All reloads 10% faster, permanently |
| Range | **Field Training** | 35 | New recruits start as Corporals |
| **Crime Lab** (reopen 50) | Case Detective | (with the room) | Start every case with intel level 1 on every gang |
| Crime Lab | Ballistics | 30 | Interrogation chance 25% → 40% |
| **Holding Cells** (reopen 35) | Booking Desk | (with the room) | Arrests give +2 Merit |
| **Roof Access** (reopen 40) | **Rooftop Entry** | (with the room) | The over-the-roofs way in (§2.7) |
| Roof Access | Second Dash (M11) | 50 | +1 dash charge |

### 6.5 Squad classes

| Class | Sprites (pack actor) | Weapon | HP | Behavior | Unlock |
|---|---|---|---|---|---|
| Patrol Officer | specopM / specopF, navy translation | SMG, 5-round bursts, medium spread | 80 | All-rounder; follows closely | Starting roster |
| Breacher | MiltiaShotgun, navy translation | Shotgun, short range | 130 | Leads into rooms when you order a move; opens doors; draws enemy fire | Board |
| Marksman | Sniper, dark-grey translation | Rifle, single shots, high damage, slow | 60 | Likes long sightlines; holds position on its own and won't push into close fights | Board |
| Paramedic | specopF, white or red-cross translation | Light SMG, weak | 70 | Heals the player under 50% HP (once per 20 seconds), revives in 1 second, stays behind the player | Board |

Reload pauses (about 1.5 seconds, with a "Reloading!" callout): Patrol every 30 rounds, Breacher every 6 shells, Marksman every 5 shots, Paramedic every 25 rounds. Officers in the same squad try not to reload at the same moment.

Ranks: Officer → Corporal (3 raids survived) → Sergeant (8). Each rank gives +15% HP, +10% accuracy, a shorter reaction delay and **one more pouch slot** (1 / 2 / 3).

Kit primaries by class (§2.7): Patrol takes the issue SMG, a seized Uzi or a seized AK; Breacher the issue or a seized shotgun; Marksman the issue rifle or a seized AK (single shots); Paramedic the issue light SMG, a seized Uzi or a Colt. The class's own sprites stay as they are.

Officers who bleed out are **killed** and leave the roster for good (§2.1).

### 6.6 Raid objectives

| Objective | Goal | Exit unlocks when | Bonus |
|---|---|---|---|
| Sweep | Clear the threat budget | The budget is spent and every enemy is dead | Speed bonus |
| Lab Bust | Destroy 3–5 cook stations (destructible actors at objective markers); they explode when shot, and a Molotov destroys one instantly. Every Lab Bust block places 2 Molotov pickups. | All stations are destroyed | +Cash |
| Evidence Run | Grab 3 ledgers (pickups at markers); waves keep coming | All ledgers are collected | +Merit, +1 Intel shard |
| Informant Extraction | Find a local informant and escort them to the exit (they follow you, can't fight, and can be revived once) | The informant reaches the exit (if they die, after a sweep) | +Merit, free Intel pick |
| Rooftop Pursuit | A runner flees across the roofs to an escape point; catch them (arrest) or stop them before they get there | The runner is caught or dead | A Warrant-style reward if arrested |
| Warrant | A named elite lieutenant is in the block; arrest them | The lieutenant is arrested or killed | ×2 Merit if arrested |
| **Hold the Block** (M7c) | Defend a reclaimed block against a counter-raid: fortify a building on the street kit, the gang attacks in 3–4 waves from the map edges (two edges in a two-front defense) | The last wave breaks (surrender applies) | Keep the block; +Backing, +Merit. Lose it if you retreat or go down |
| **Foot Patrol** (side job, M9) | Walk a marked route through the turf to a far checkpoint; light resistance, residents on the street | You reach the checkpoint | Cash and officer XP; low risk |

### 6.7 The Bricks kits (written for New Bricks City, M2c)

Each kit is a template grid (`tools/make_kit_maps.py`) plus a layout class in `nbc/zscript/nbc/kit_*.zs`, carved by the engine in `nbc/zscript/cw/kitgen.zs`. All at the measured scale in §4.4.

| Kit (map) | Grid | Variants | Becomes | Objectives it suits |
|---|---|---|---|---|
| **Tower floor** (`NBC_KT`) | 14 x 5: stair cores, 12 flat bays, two rows of rooms either side of the corridor | occupied floor, gallery floor, gang floor, burned-out floor, penthouse floor | Mansion floors. Flats (studio to four bays), the lift lobby, the trash chute and laundry. The gang floor has stash, cook, counting, trap and lookout flats, knocked-through walls, barricades. The penthouse is the Collectors' and the Crown's. | All; Lab Bust in the cook flat, Evidence in the stash and counting room |
| **Street** (`NBC_KS`) | 15 x 12: a two-sided street (the canal walk, south lots, sidewalk, road, sidewalk, north lots, the north alley, the Wall) | tower entrance, corner stores, chop lot, under the el | Approach blocks, Hold the Block defenses, Foot Patrols. Shops on both sides with back rooms and flats above, walk-ups, alleyways cutting through to the alleys behind, fenced parking lots, closed buildings; on the north side the tower's courtyard and lobby, a playground, the chain-link car lot and garage; the elevated line over the road. | Sweep, Evidence, Warrant, Pursuit, Hold the Block, Foot Patrol |
| **Basement** (`NBC_KB`) | 16 x 12 cells of 128 | service basement, cook lab, fight pit, parking garage, smugglers' tunnel | The Iron Pit's fight hall, the Rust Saints' garage, the Wall Watch's tunnel, labs under any tower. | Sweep, Lab, Evidence, Extraction |
| **Roof** (`NBC_KR`) | 14 x 9 cells of 160 | tower roof, rooftop crossing, roof camp | The top of a tower: stair huts, the lift machine room, water tanks, the gap to the next tower on plank bridges, a squatters' and lookout camp. | Sweep, Rooftop Pursuit, Warrant |

In every kit:
- **Spawn spots** come from every reachable cell (up to two per cell); outdoor cells are marked as perches for M4.
- **Rubble piles** (against walls) and loose debris go in rooms flagged `RF_RUBBLE`: squats, burned flats, alleys, yards, roofs, tunnels.
- **Residents** stand at `NBC_ResidentSpot` markers in civilian rooms (M9).
- **The way in and the exit** are two of the kit's entries (stairs, lift, alley, ramp, fire escape...); the exit is the one farthest from the way in, under a lit exit sign.
- **Objectives** go in the rooms each kit scores highest for seizing, wrecking or reaching someone (`NBC_ObjectiveMarker`).
- **Fences and rails:** where outdoor spaces meet without a doorway or gap, there's a fence; rails over a drop block.
- **Past the map's edges** (street, tower and roof templates): a canal with embankments along the road side, a high retaining wall, a ground plane, and tower blocks as real geometry at three distances for parallax; the horizon is a sky-hack ring, never a wall. Never paint a city onto a flat wall at a map border.

---

### 6.8 Debris (quick-throw)

| Type | Damage | Throw | On impact | Found | Art |
|---|---|---|---|---|---|
| Brick | 18 | Normal range, 1 low bounce | 30% chance to stay whole and be reusable; staggers; arrest stagger under 35% HP | Everywhere; rubble piles | New: a brick (hand and world sprites) |
| Half-brick | 12 | Longer and faster, 2 bounces | Breaks; staggers | Rubble piles (half of what they give) | New |
| Concrete chunk | 26 | Short range, heavy arc, no bounce | Breaks into 2 half-bricks you can't pick up; knocks enemies back | Streets and broken buildings | New |
| Glass bottle | 8 | Long and light | Always shatters; **loud** (768-unit noise in M9) | Alleys, courtyards, labs | Reuse the Molotov pack's unlit bottle and glass-debris sprites |

All debris is non-explosive, has `+FORCEPAIN`, never damages allies, and uses the frag's bounce code. You throw the type that's selected; H cycles the types you're carrying.

**Finished sprite lumps** (in `nbc/sprites/debris/`). They were drawn in pxl from `art/debris/debris.px.js` and exported with `python art/debris/export.py`, which sets the grAb offsets. Every color is an exact Doom PLAYPAL color.

| Lump(s) | What it is | Size | Offset |
|---|---|---|---|
| `BRKHA0`, `BRKHB0` | The first-person hand holding a brick: the frag grenade's hand frame with the grenade recolored into a brick with mortar crust (A hold, B wind-up) | 167×133 | (−76, −36) and (−180, −110), the frag's own |
| `HGT2` A–D, F–J | The throw and follow-through, an empty hand reused from the FragGrenade pack (there's no E frame) | — | the pack's |
| `BRKPA0` | A loose brick on the floor (pickup) | 15×8 | bottom center |
| `HBRKA0` | A half-brick, broken end on the right (pickup) | 10×8 | bottom center |
| `CNCKA0` | A concrete chunk with a rusted rebar stub (pickup) | 13×11 | bottom center |
| `RUBL` A/B/C | A rubble pile: full, half and nearly spent (it changes as it's used) | 40×20, 32×14, 22×8 | bottom center |
| `BRKT` A–D, `HBKT` A–D, `CNKT` A–D | Thrown brick, half-brick and chunk tumbling in flight (A flat, B 45°, C on end, D 135°: loop A–D for the spin) | up to 17×17 | centered |
| `BFRG` A–D | Shards for impact particles (pick a frame at random) | 2–3 px | centered |

The pickups are about twice real scale, like Doom's own items. If they look too big in game, set `Scale` around 0.6 on the actors rather than redrawing them. To change the art, edit `debris.px.js`, rebuild with `pxl build`, then run `export.py` again.

### 6.9 The gangs (`nbc/gangs.txt`; 4 of the first 6 appear in each case)

Rosters use the enemy pack's choice classes (from `Espawners.txt`). Damage types come from M1b: `NBC_Light` (pistols, SMGs), `NBC_Shell`, `NBC_Rifle`, `Fire`, `Melee`, `Blunt` (debris).

| Gang | Tier | Roster (tier 1 / 2 / 3 / 4) | Identity traits | Weakness | Mansion (kit) | Leader | Crown defense removed when toppled |
|---|---|---|---|---|---|---|---|
| **The Stoop Kings**: street crew holding the walk-ups | 1 | GOON, GOONGIRL, HOODY, CROOK, SCUMMAN, SCUMF / STREETM, STREETF, ROBMAN, BANGER / KILLER / — | **Swarm**: budget +30%, health −20%. **Lookouts** on stoops and roofs blow cover if they see the squad. Throw Molotovs. | **Morale**: when half a wave is down, the rest may run, and runners can be arrested | Tenement (K2) | A Stoop King: a KILLER elite with 2 modifiers and a TEC-9 escort | Lookouts on the Crown's roofs |
| **The Rust Saints**: biker punks and pyros in the chop shops | 1 | PUNKM, PUNKF, REDNECK, ROBBERF / GangBike riders / PYRO / FATSO (Rocketeer) | **Fire and explosives**: Molotovs, flamethrowers, Volatile elites twice as common, **explosive barrels** dressed into their floors. **Fire immune.** | Their barrels and splash hurt them too; Breachers and Marksmen keep you out of the fire | Chop shop (K1) → garage (K4) | **BruteGL** | Fire traps on the Crown's stairs |
| **The Iron Pit**: roiders running a basement fight club | 2 | TOUGH / BUFF, MUSCLE, ROID / CHUBB (Chunky SSG), DOORMAN (Enforcer) / — | **Melee rushers**: health +40%, ignore stagger (pain chance −60%, so bricks stagger only half the time), few guns. | **Fire** (×1.5: Molotovs; they fight bare-chested) and flashbangs; slow on stairs, so Marksmen and range win | Garage and tunnels (K4) | The Champion: a ROID elite with Armored + Wired | The Crown's door guards (fewer tier-3 units) |
| **The Collectors**: the Landlord's rent men, in suits | 2 | SUITMAN, SUITGIRL, MOBS / MOOKSHOT, MOOKSHOT2, YAKUZA, PIMP / SUITAK, HitmanTommy, HitmanShotgun / — | **Vests**: `NBC_Light` ×0.6. **Alarms**: when alerted, an immediate reinforcement wave. **A cop on the payroll**: cover blows 50% faster. Evidence-rich: Evidence Runs give double Merit. | **Shells and rifles ignore the vests**; destroying the alarm panel (an objective marker) stops the reinforcements | Luxury apartments (K2); approach via the gambling den (K1) | The Head Collector: a SUITMAN revolver elite with Shot Caller | The Crown's alarm |
| **The Wall Watch**: militia smugglers who own the tunnels under the Wall | 2 | MILSMG, MILFEM / RUSSIAN, RUSSFEM, BANDIT, TERROR / RUSGUN, RUSSBIG / BigElite (LMG) | **Long range**: rifle accuracy +25%, **snipers** on every perch, **sandbag** cover dressed into rooms. | **Bad up close**: a 1-second reaction delay within 256 units; back and service entries flank them | Tunnels (K4) → rooftops (K2) | The Quartermaster: a BigElite (LMG) elite | The Crown's rooftop snipers |
| **The Quiet**: an imported crew of ninjas and cyborgs | 3 | — / Ninja1–4, KILLER / TERROR / KappaBorgM, KappaBorgF | **Ambush**: spawn *behind* you, mostly invisible (ninjas), **intel costs double**, no undercover openers. | **The flashlight** reveals them and makes them flinch; flashbangs | Hotel (K2) | A KappaBorg elite with 2 modifiers | The Crown's ambush teams |
| **The Crown** (final, always present): the Landlord's private military | 3+ | — / PMC, PMCBIG / Elite1, EliteF1, EliteShotgun / BadassElite, BadassElite2, BigElite, BadassPara, Rocketeer | **Everything**, plus one extra defense every 5 days. Each toppled gang strips one (the last column). | Whatever you've toppled | Luxury floors (K2) → hand-built penthouse and roof | **BruteMiniGUN**, then the Landlord flees across the roof (Rooftop Pursuit) | — |

**Random traits** (each gang rolls 1–2 per case; they show at intel level 2):

| Trait | Effect |
|---|---|
| Fresh shipment | Tier-1 units carry tier-2 weapons |
| Fortified | Sandbags and barricades; one entry fewer |
| Paid off | Cover blows 50% faster (stacks with the Collectors' own) |
| Lookouts | Spotters on perches |
| Hostages | 2–4 residents held on the mansion floors: +Merit per rescue, a fine per death |
| Booby-trapped | Tripwire charges on some doors (the Corpo Wars breaching-charge sprites), visible with the flashlight |
| Night shift | Half the crew is asleep: undercover openers are certain |
| Short-handed | Budget −25% |
| Big payday | Cash drops +50% |
| Inside man | Intel level 3 for free |
| Bad blood | A neighboring gang's crew is in the building too, fighting them |

The data file holds each gang's name, colors, roster, damage factors, flags, kit variants, leader and Crown link, so new gangs can be added as data.

### 6.10 Backing and turf income

Backing runs from 0 to 100 and starts each case at 60 (40 in Demolition Day).

| Event | Backing |
|---|---|
| Officer killed in the line of duty | −10 |
| Officer hospitalized | −2 |
| Resident killed by you or the squad | −5 |
| Retreat from a raid | −5 |
| You go down (Officer Down) | −10 (plus the strike) |
| Reclaimed block lost | −10 |
| Clean raid: no officers down, no residents hurt | +5 |
| Arrest | +1 (at most +5 per raid) |
| Gang toppled | +15 |
| Block defended | +5 |
| Side job completed | +2 |

- **75 or more:** informant tips −20%, one extra side job a day.
- **25 or less:** hospital stays +1 day; no Radio for Backup in the shop.
- **0:** a strike, then Backing resets to 40.

**Turf income:** each reclaimed block pays 100 × the toppled gang's tier in Cash every day, shown as tomorrow's income on the city map. A block under attack pays nothing that day.

### 6.11 The results grade

Points out of 100, then S (90+), A (75+), B (60+), C (40+), D (below 40):
- crew taken down (killed or arrested) out of the total: 30
- accuracy: 15 (60% or better gets full points)
- health lost: 15 (none lost gets full points)
- time against the block's par time (90 seconds per floor): 10
- officers: 20, minus 10 per officer killed and 5 per officer down
- residents: 10, minus 5 per resident killed

The grade adds Merit from M8 (S +6, A +4, B +2).

---

## 7. Risks and how to handle them

| Risk | Mitigation |
|---|---|
| **Ally AI is clumsy** (blocks doors, gets lost, shoots walls) | M5 ships *one* officer until it's solid. Corridors and doors are sized for the squad, catch-up teleporting covers navigation failures, and there are debug commands. Expect 2–3 rounds of Codex fixes from your playtest notes. |
| **Enemies ignore allies** because of the pack's `+NOTARGET` / `+NOINFIGHTING` flags | The SquadManager retargets enemies onto allies. Allies use their own target-finding, not built-in friendly AI. Allies must never fire `"Enemy"`-damage projectiles, since enemies are immune to them. |
| **Allies make the game too easy** | Enemies get retargeted onto allies, officers bleed out, the hospital rotation, and squad size gated behind Merit. If allies still feel strong, tune their accuracy and the budget scaling. |
| **The quick-throw overlay fights with the weapon** (firing during a throw, glitches when switching, a reload cancelled at the wrong moment) | The fire block and weapon lowering are in M1c's spec, and the checklist tests throwing while reloading and switching. If it can't be made solid, use the slot-0 Debris weapon fallback built straight from the frag code. |
| **Ported weapons feel different from the originals** | M1b keeps the original sprites, sounds, damage, spread and fire timing. Compare old and new side by side (the original DECORATE is kept as reference). |
| **Porting Corpo Wars systems drags in its baggage** (city sim, contracts, CW guards) | This risk is real: the kits, stealth, menus and city map all reference Corpo Wars' handler, ledger, city and contract classes. `docs/corpowars-port-map.md` lists every outside class per system. M2, M4/M5, M7b, M9 and M11 each port **one** system and cut or replace those ties, and every port must pass `check_lumps.py` and the smoke test before the next one starts. Expect M2 (the kits) to be the biggest port. |
| **The city map makes cases too long or too fiddly** | One action per day keeps it quick. Tune days, tip prices and the gang tick from `nbc_simdays` soak tests and the 3-case MVP playtest. If scouting doesn't change your plan, the gang traits aren't different enough: push the numbers in `gangs.txt`. |
| **Licensing of recycled art** | The A.D. Cop textures are rips. Keep the mod free, keep every credit line, and replace anything a creator objects to. |
| **Molotovs burn your squad, or burn you more than is fun** | Allies have fire immunity (`DamageFactor "Fire", 0`), with damage from enemy flamers kept separate through the `"Enemy"` damage type. Playtest the Molotov's self-damage; if it's too punishing, scale fire damage to the player down in `NBC_Player.DamageMobj`. |
| **Allies look like enemies** | Their sprite classes are removed from enemy pools, and they get a distinct police translation, a chevron marker, and the HUD strip. |
| **Kit floors feel samey** | Corpo Wars' kits already have several variants each, and every layout is new per seed. The Bricks restyle, gang dressing (sandbags, barrels, hostages) and objectives add more. If it still feels flat, add a variant to a kit (site-kits.md explains how). |
| **Codex writes ZScript that compiles but doesn't work in play** | Every milestone has debug commands, plus your manual checklist. Paste the exact console output back to Codex. |
| **Run state lost or duplicated across saves** | RunData is a STAT_STATIC thinker (saved with the game). Meta progress and the roster live in CVars (not saved with the game), so loading an old save can't roll back Merit. Tested in M3. |
| **Asset credits get lost** | M0 merges the CREDITS files. Never delete `nbc/CREDITS.txt` entries. |
| **Scope creep** | Don't start M9 until 3 full MVP cases feel good. |
| **Enemy grenades and rockets wipe the squad** (*Hamburger Hill*'s worst problem) | M4's cap: one enemy explosive at a time, a telegraphed wind-up, no blind throws, a cooldown per thrower. Tune it in the M4 playtest before anything else. |
| **Permanent deaths feel unfair** | Bleed-out is 20 seconds, revives work, a downed officer near the exit is carried out, the Infirmary's Trauma Training lets officers revive each other, and the memorial wall makes losses mean something. If it's still harsh, lengthen the bleed-out before softening the rule. |
| **Escorts and allies stand in the open** (another *Hamburger Hill* complaint) | Hold, Move and escorts pick cover spots out of enemy sight (M6, M9). The playtests check for it. |
| **The kits look boxy, not like a real city** | The scale rules and the "look" list in §4.4, the skyline, facades with rows of windows, props from the room sets, and lighting per room. Compare screenshots with the mood board at M2b and M12. If a space still reads wrong, it becomes a new kit variant or a hand-built set piece, not a return to Obsidian. |
| **The campaign layer gets too long between raids** | One action per day, AUTO on every squad screen, and the deploy screen remembers the last squad and kits. |
