// Allied officers (AGENTS.md squad rules): their own target-finding, no engine FRIENDLY AI.
// Each one is an officer off the roster (NBC_Officer): the class sets the build (specop, militia shotgunner,
// sniper and specop-F sprites from actors/enemies/, whose classes stay out of every enemy pool) and the
// issue weapon, the portrait sets the clothes (a plain-clothes recolor, nbc/TRNSLATE.txt); the kit can swap
// in a seized gun; rank, aim and perks shape how well they shoot.
// They follow the player, shoot visible gang members with hitscan in the gun's damage type (never "Enemy"),
// reload every magazine, use their pouches (medkits when hurt, Molotovs on a bunch of gang members), the
// Paramedic patches the player up, and they never take damage from the player, each other or fire.
// They take orders (NBC_Orders, Ghost Recon style): their fireteam's order (follow, hold, move, advance along
// waypoints and wait on go codes) and rules of engagement (recon, assault, suppress). Places are reached over
// the navigation graph (CW_NavGraph); the player is chased directly while in sight.

class NBC_Ally : Actor
{
	const SIGHT_RANGE = 1600.0;
	const FOLLOW_DIST = 144.0;
	const LOST_DIST = 1024.0;

	// who this is
	int officerId, slot, cls, aimSkill, maxHp;
	// the gun
	int gunItem, burst, pellets, dmgMin, dmgMax, magazine, reloadTics, aimTics, refireTics;
	double spread, range, dmgMul, takeMul;
	Name dmgType;
	Sound fireSound;
	// pouches (NBC_Cat items, -1 = empty or used) and the medic's timer
	Array<int> pouch;
	int healTics, healEvery, medkitHeal, bottleTics;

	Actor enemy;
	int roundsLeft, thinkCount, lostTics, burstLeft;
	// orders: the team's order as last seen, where to hold, the route being walked, who last shot at us
	int serialSeen, wpStep, stuckTics, repath, rtAt, suppressTics, lastHitTic;
	bool waitingGo, arrivedSaid;
	Vector3 holdPos, lastPos, navDest, suppressPos;
	Array<double> rtx, rty;
	Actor lastHitBy;
	NBC_SteerPoint steer;

	Default
	{
		Health 100;
		Radius 18;
		Height 56;
		Mass 100;
		Speed 22;
		PainChance 90;
		Monster;
		-COUNTKILL;
		+FLOORCLIP;
		+NOINFIGHTING;
		+DONTHARMSPECIES;
		Species "NBC_Squad";
		DamageFactor "Fire", 0;
		SeeSound "EliteN/see";
		PainSound "EliteN/pain";
		DeathSound "EliteN/die";
		Obituary "%o was shot by a fellow officer.";
		Tag "Officer";
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		SetProfile(NBC_Cat.C_PATROL, -1);
		roundsLeft = magazine;
	}

	// Kit out as a roster officer (NBC_RunManager.SetupRaid).
	void Equip(NBC_Officer o, int raidSlot)
	{
		officerId = o.id;
		slot = raidSlot;
		cls = o.cls;
		aimSkill = o.Aim();
		maxHp = o.MaxHealth();
		health = clamp(o.health, 1, maxHp);
		SetTag(o.RankedName());
		sprite = GetSpriteIndex(NBC_Cat.CLASS_SPRITE[clamp(cls, 0, NBC_Cat.C_COUNT - 1)]);
		// their own clothes, the same as in their portrait (nbc/TRNSLATE.txt, tools/art/make_portraits.py)
		A_SetTranslation(String.Format("NBC_Outfit%d", o.face * 3 % 8));
		if (cls == NBC_Cat.C_MEDIC) { SeeSound = "EliteF/see"; PainSound = "EliteF/pain"; DeathSound = "EliteF/die"; }

		SetProfile(cls, o.kitPrimary);
		spread = max(0.6, (100 - aimSkill) / 9.0);
		dmgMul = o.HasPerk(NBC_Cat.P_HOLLOW) ? 1.2 : 1.0;
		if (o.HasPerk(NBC_Cat.P_TRIGGER)) { if (pellets > 1) pellets++; else burst++; }
		if (o.HasPerk(NBC_Cat.P_SPEED)) reloadTics = reloadTics * 6 / 10;
		if (o.HasPerk(NBC_Cat.P_REFLEX)) aimTics = max(2, aimTics * 6 / 10);
		range = SIGHT_RANGE * (o.HasPerk(NBC_Cat.P_WATCH) ? 1.3 : 1.0);
		takeMul = (o.kitVest ? 0.7 : 1.0) * (o.HasPerk(NBC_Cat.P_KEVLAR) ? 0.85 : 1.0);
		medkitHeal = o.HasPerk(NBC_Cat.P_MEDIC) ? 80 : 40;
		healEvery = 35 * (o.HasPerk(NBC_Cat.P_MEDIC) ? 10 : 20);
		healTics = healEvery / 2;
		pouch.Clear();
		for (int k = 0; k < o.PouchSlots() && k < o.kitPouch.Size(); k++) pouch.Push(o.kitPouch[k]);
		roundsLeft = magazine;
	}

	// The gun: the class's issue weapon, or a seized one from the Evidence Locker.
	void SetProfile(int c, int item)
	{
		gunItem = item;
		pellets = 1; refireTics = 3; aimTics = 6;
		switch (item)
		{
		case NBC_Cat.IT_UZI:    burst = 6; dmgMin = 6;  dmgMax = 9;  magazine = 32; reloadTics = 45; dmgType = 'NBC_Light'; fireSound = "MicroUzi/Fire"; refireTics = 2; return;
		case NBC_Cat.IT_AK:     burst = 3; dmgMin = 12; dmgMax = 18; magazine = 30; reloadTics = 55; dmgType = 'NBC_Rifle'; fireSound = "Weapons/AK47FIR"; return;
		case NBC_Cat.IT_PUMP:   burst = 1; pellets = 8; dmgMin = 5; dmgMax = 8; magazine = 6; reloadTics = 70; dmgType = 'NBC_Shell'; fireSound = "weapons/Xshotgf"; refireTics = 20; return;
		case NBC_Cat.IT_COLT:   burst = 2; dmgMin = 10; dmgMax = 15; magazine = 8;  reloadTics = 35; dmgType = 'NBC_Light'; fireSound = "Weapon/COLTFIRE"; refireTics = 8; return;
		case NBC_Cat.IT_DUAL92: burst = 4; dmgMin = 7;  dmgMax = 10; magazine = 30; reloadTics = 50; dmgType = 'NBC_Light'; fireSound = "B92FIRE"; refireTics = 3; return;
		}
		gunItem = -1;
		switch (c)
		{
		case NBC_Cat.C_BREACHER: burst = 1; pellets = 7; dmgMin = 4; dmgMax = 7; magazine = 6; reloadTics = 70; dmgType = 'NBC_Shell'; fireSound = "en/shotgun"; refireTics = 20; break;
		case NBC_Cat.C_MARKSMAN: burst = 1; dmgMin = 28; dmgMax = 42; magazine = 10; reloadTics = 60; dmgType = 'NBC_Rifle'; fireSound = "en/sniper"; aimTics = 14; break;
		case NBC_Cat.C_MEDIC:    burst = 3; dmgMin = 5; dmgMax = 8; magazine = 24; reloadTics = 45; dmgType = 'NBC_Light'; fireSound = "en/silsmg"; break;
		default:                 burst = 4; dmgMin = 6; dmgMax = 10; magazine = 30; reloadTics = 45; dmgType = 'NBC_Light'; fireSound = "en/silsmg"; break;
		}
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		// the player and the squad never hurt officers
		if (source && (source.player || source is "NBC_Ally")) return 0;
		if (inflictor && inflictor.target && (inflictor.target.player || inflictor.target is "NBC_Ally")) return 0;
		if (!(flags & DMG_FORCED) && damage < TELEFRAG_DAMAGE && takeMul > 0) damage = max(1, int(damage * takeMul));
		// recon rules let an officer shoot back at whoever shot them
		if (source && source.bIsMonster && !(source is "NBC_Ally")) { lastHitBy = source; lastHitTic = level.maptime; }
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	// pouches used up on the raid come back empty (the kit stays with the officer)
	void ReturnPouches(NBC_Officer o)
	{
		for (int k = 0; k < pouch.Size() && k < o.kitPouch.Size(); k++) o.kitPouch[k] = pouch[k];
	}

	PlayerPawn Leader()
	{
		return players[consoleplayer].mo;
	}

	static bool IsGangMember(Actor mo)
	{
		return mo && mo.bIsMonster && mo.health > 0 && !(mo is "NBC_Ally") && !mo.bFriendly && mo.bShootable;
	}

	// The nearest gang member in sight. Recon rules (weapons tight): only those already in the fight, after you,
	// the squad or this officer.
	Actor FindEnemy(int roe = NBC_Orders.ROE_ASSAULT)
	{
		Actor best = null;
		double bestDist = range > 0 ? range : SIGHT_RANGE;
		let it = BlockThingsIterator.Create(self, bestDist);
		while (it.Next())
		{
			Actor mo = it.thing;
			if (!IsGangMember(mo)) continue;
			if (roe == NBC_Orders.ROE_RECON && !InTheFight(mo)) continue;
			double d = Distance3D(mo);
			if (d >= bestDist || !CheckSight(mo, SF_IGNOREVISIBILITY)) continue;
			best = mo;
			bestDist = d;
		}
		return best;
	}

	bool InTheFight(Actor mo)
	{
		if (mo == lastHitBy && level.maptime - lastHitTic < 35 * 5) return true;
		return mo.target && (mo.target.player || mo.target is "NBC_Ally") && mo.CheckSight(mo.target);
	}

	int PouchOf(int item)
	{
		for (int k = 0; k < pouch.Size(); k++) if (pouch[k] == item) return k;
		return -1;
	}

	// Called from the walk frames every 4 tics.
	void A_AllyThink()
	{
		// pouches and the medic first
		if (health * 100 < maxHp * 35)
		{
			int k = PouchOf(NBC_Cat.IT_MEDKIT);
			if (k >= 0)
			{
				pouch[k] = -1;
				health = min(maxHp, health + medkitHeal);
				A_StartSound("misc/health_pkup", CHAN_ITEM);
			}
		}
		let p = Leader();
		if (cls == NBC_Cat.C_MEDIC && p && p.health > 0)
		{
			if (healTics > 0) healTics -= 4;
			else if (p.health < 50 && Distance3D(p) < 256 && CheckSight(p))
			{
				p.GiveBody(20, 100);
				p.A_StartSound("misc/health_pkup", CHAN_ITEM);
				p.A_Print(String.Format("%s patches you up.", GetTag()), 2);
				healTics = healEvery;
			}
		}
		if (bottleTics > 0) bottleTics -= 4;

		// the team's orders (NBC_Orders); a new order resets where we hold and the path
		let rd = NBC_RunData.Find();
		int team = rd ? rd.TeamOfSlot(slot) : 0;
		int order = rd && team < rd.teamOrder.Size() ? rd.teamOrder[team] : NBC_Orders.ORD_FOLLOW;
		int roe = rd && team < rd.teamROE.Size() ? rd.teamROE[team] : NBC_Orders.ROE_ASSAULT;
		if (rd && team < rd.teamSerial.Size() && serialSeen != rd.teamSerial[team])
		{
			serialSeen = rd.teamSerial[team];
			holdPos = pos; wpStep = 0; repath = 0; rtx.Clear(); rty.Clear();
			waitingGo = false; arrivedSaid = false;
		}

		// contact, by the rules of engagement
		if (enemy && (!IsGangMember(enemy) || !CheckSight(enemy, SF_IGNOREVISIBILITY)))
		{
			if (IsGangMember(enemy)) { suppressPos = enemy.pos; suppressTics = 35 * 2; }   // last seen there
			enemy = null;
		}
		if (++thinkCount % 3 == 0 || !enemy) enemy = FindEnemy(roe);
		if (suppressTics > 0) suppressTics -= 4;
		if (enemy)
		{
			angle = AngleTo(enemy);
			if (roe != NBC_Orders.ROE_RECON && TryBottle(p)) return;
			burstLeft = burst + (roe == NBC_Orders.ROE_SUPPRESS ? 3 : 0);
			SetStateLabel("Missile");
			return;
		}
		// suppress: keep rounds going where they went to ground
		if (roe == NBC_Orders.ROE_SUPPRESS && suppressTics > 0 && roundsLeft > 0 && random(0, 99) < 60)
		{
			angle = VectorAngle(suppressPos.x - pos.x, suppressPos.y - pos.y);
			burstLeft = burst + 2;
			SetStateLabel("Missile");
			return;
		}

		if (!p) return;
		double mul = roe == NBC_Orders.ROE_RECON ? 0.6 : 1.0;     // recon: slow and quiet
		switch (order)
		{
		case NBC_Orders.ORD_HOLD:
			if (HeadFor(holdPos, mul)) Stand();
			break;
		case NBC_Orders.ORD_MOVE:
			if (HeadFor(FormationSpot((rd.teamGX[team], rd.teamGY[team], rd.teamGZ[team]), team, rd), mul))
			{
				Stand();
				if (!arrivedSaid) { arrivedSaid = true; NBC_Orders.Say(String.Format("%s: In position.", NBC_Orders.TEAM_NAME[team]), Font.CR_GREEN); }
			}
			break;
		case NBC_Orders.ORD_ADVANCE:
			Advance(rd, team, mul);
			break;
		default:
			Follow(p, mul);
			break;
		}
	}

	void Stand()
	{
		frame = 0;
		ClearRoute();
	}
	void ClearRoute() { rtx.Clear(); rty.Clear(); rtAt = 0; }

	// regroup on the player: straight at them while in sight, over the graph when not, a quiet catch-up when lost
	void Follow(Actor p, double mul)
	{
		double d = Distance2D(p);
		bool see = CheckSight(p);
		if (d > LOST_DIST && !see)
		{
			lostTics += 4;
			if (lostTics >= 105) { CatchUp(p); lostTics = 0; return; }
		}
		else lostTics = 0;

		if (d <= FOLLOW_DIST)
		{
			Stand();
			if (d < 64) { target = p; A_FaceTarget(); target = null; }
			return;
		}
		if (see)
		{
			ClearRoute();
			double sp = speed;
			speed *= mul;
			target = p;
			A_Chase(null, null, CHF_NOPLAYACTIVE);
			target = null;
			speed = sp;
			return;
		}
		HeadFor(p.pos, mul);
	}

	// walk the team's waypoints; wait at one with a go code until it's called
	void Advance(NBC_RunData rd, int team, double mul)
	{
		int n = NBC_Orders.WaypointCount(rd, team);
		if (n == 0) { if (HeadFor(holdPos, mul)) Stand(); return; }
		wpStep = clamp(wpStep, 0, n - 1);
		int wi = NBC_Orders.WaypointIndex(rd, team, wpStep);
		if (!HeadFor(FormationSpot((rd.wpX[wi], rd.wpY[wi], rd.wpZ[wi]), team, rd), mul)) return;
		int g = rd.wpGo[wi];
		if (g != NBC_Orders.GO_NONE && !rd.goCalled[g])
		{
			Stand();
			if (!waitingGo)
			{
				waitingGo = true;
				NBC_Orders.Say(String.Format("%s: At waypoint %d. Waiting on %s.", NBC_Orders.TEAM_NAME[team], wpStep + 1, NBC_Orders.GO_NAME[g]), Font.CR_GOLD);
			}
			return;
		}
		if (waitingGo) { waitingGo = false; NBC_Orders.Say(String.Format("%s: Moving out.", NBC_Orders.TEAM_NAME[team]), Font.CR_GREEN); }
		if (wpStep < n - 1) { wpStep++; repath = 0; return; }
		Stand();
		if (!arrivedSaid) { arrivedSaid = true; NBC_Orders.Say(String.Format("%s: Last waypoint. Holding.", NBC_Orders.TEAM_NAME[team]), Font.CR_GREEN); }
	}

	// a team spreads out round a point: the first member on it, the others a step to the sides and behind
	Vector3 FormationSpot(Vector3 at, int team, NBC_RunData rd)
	{
		int k = 0;
		for (int s = 0; s < slot; s++) if (rd.TeamOfSlot(s) == team) k++;
		if (k == 0) return at;
		static const double offx[] = { 0, -40, 40, 0 };
		static const double offy[] = { 0, 40, 40, -48 };
		Vector2 spot = at.xy + (offx[k & 3], offy[k & 3]);
		let ord = NBC_Orders.Get();
		let nav = ord ? ord.Nav() : null;
		if (nav && !nav.Clear(at.xy, spot)) return at;
		return (spot, level.PointInSector(spot).floorplane.ZAtPoint(spot));
	}

	// Head for a point: straight when the way is clear, else over the navigation graph. True when there.
	bool HeadFor(Vector3 dest, double mul)
	{
		if ((dest.xy - pos.xy).Length() < 40) { ClearRoute(); return true; }
		if ((pos.xy - lastPos.xy).Length() < 2) stuckTics += 4; else stuckTics = 0;
		lastPos = pos;
		let ord = NBC_Orders.Get();
		let nav = ord ? ord.Nav() : null;
		if (--repath <= 0 || stuckTics > 35 || (navDest.xy - dest.xy).Length() > 64)
		{
			// plan (again): every few seconds, when stuck, or when the goal moved
			navDest = dest;
			repath = 26;
			stuckTics = 0;
			ClearRoute();
			if (nav && nav.Count() && !nav.Clear(pos.xy, dest.xy) && nav.Route(pos.xy, dest.xy))
				for (int i = 0; i < nav.path.Size(); i++) { rtx.Push(nav.nx[nav.path[i]]); rty.Push(nav.ny[nav.path[i]]); }
		}
		Vector2 next = dest.xy;
		while (rtAt < rtx.Size())
		{
			Vector2 node = (rtx[rtAt], rty[rtAt]);
			// skip ahead to a later node once there's a clear line to it
			if ((node - pos.xy).Length() < 40 || (rtAt + 1 < rtx.Size() && nav && nav.Clear(pos.xy, (rtx[rtAt + 1], rty[rtAt + 1])))) { rtAt++; continue; }
			next = node;
			break;
		}
		SteerTo(next, mul);
		return false;
	}

	void SteerTo(Vector2 pt, double mul)
	{
		if (!steer) steer = NBC_SteerPoint(Spawn("NBC_SteerPoint", (pt, pos.z)));
		if (!steer) return;
		steer.SetOrigin((pt, level.PointInSector(pt).floorplane.ZAtPoint(pt)), false);
		double sp = speed;
		speed *= mul;
		target = steer;
		A_Chase(null, null, CHF_NOPLAYACTIVE);
		target = null;
		speed = sp;
	}

	override void OnDestroy()
	{
		if (steer) steer.Destroy();
		Super.OnDestroy();
	}

	// A Molotov at two or more of them bunched up in throwing range, well clear of the player.
	bool TryBottle(Actor p)
	{
		if (bottleTics > 0 || !enemy) return false;
		int k = PouchOf(NBC_Cat.IT_MOLOTOV);
		if (k < 0) return false;
		double d = Distance2D(enemy);
		if (d < 160 || d > 320 || (p && p.Distance2D(enemy) < 200)) return false;
		int near = 0;
		let it = BlockThingsIterator.Create(enemy, 160);
		while (it.Next()) if (it.thing != enemy && IsGangMember(it.thing) && enemy.Distance2D(it.thing) < 160) near++;
		if (near < 1) return false;
		bottleTics = 35 * 6;
		pouch[k] = -1;
		let b = Spawn("MolotovBottle", pos + (0, 0, 40), ALLOW_REPLACE);
		if (!b) return false;
		b.target = self;
		b.angle = AngleTo(enemy);
		// a lob: speed 14, gravity 0.6 (the bottle's own) -> the angle that lands it at the distance
		double th = 0.5 * asin(clamp(d * b.Gravity * level.Gravity / 800.0 / (b.Speed * b.Speed), 0, 1));
		b.Vel3DFromAngle(b.Speed, b.angle, -th);
		A_StartSound("Weapons/Molotov/Throw", CHAN_WEAPON);
		return true;
	}

	// Lost for 3 seconds: step in quietly behind the player.
	void CatchUp(Actor p)
	{
		static const double offsets[] = { 180, 150, 210, 120, 240, 90, 270 };
		Vector3 old = pos;
		for (int i = 0; i < offsets.Size(); i++)
		{
			Vector2 at = p.pos.xy + AngleToVector(p.angle + offsets[i], 80 + slot * 24);
			SetOrigin((at, p.GetZAt(at.x, at.y, 0, GZF_ABSOLUTEPOS)), false);
			if (TestMobjLocation() && CheckSight(p)) { angle = p.angle; return; }
		}
		SetOrigin(old, false);
	}

	void A_AllyAim()
	{
		if (enemy && IsGangMember(enemy)) angle = AngleTo(enemy);
		else if (suppressTics > 0) angle = VectorAngle(suppressPos.x - pos.x, suppressPos.y - pos.y);
	}

	int TeamROE()
	{
		let rd = NBC_RunData.Find();
		int team = rd ? rd.TeamOfSlot(slot) : 0;
		return rd && team < rd.teamROE.Size() ? rd.teamROE[team] : NBC_Orders.ROE_ASSAULT;
	}

	// the aim time before the first shot (Hair Trigger shortens it)
	void A_AllyAimDelay()
	{
		A_AllyAim();
		A_SetTics(aimTics);
	}

	void A_AllyShoot()
	{
		bool live = enemy && IsGangMember(enemy);
		int roe = TeamROE();
		bool suppress = roe == NBC_Orders.ROE_SUPPRESS;
		// suppressing fire goes where they were last seen
		if (!live && !(suppress && suppressTics > 0)) { SetStateLabel("See"); return; }
		if (roundsLeft <= 0) { SetStateLabel("Reload"); return; }
		double r = range > 0 ? range : SIGHT_RANGE;
		double pit;
		if (live)
		{
			angle = AngleTo(enemy);
			pit = AimLineAttack(angle, r);
		}
		else
		{
			Vector3 d = suppressPos + (0, 0, 32) - (pos + (0, 0, height * 0.75));
			angle = VectorAngle(d.x, d.y);
			pit = -VectorAngle(d.xy.Length(), d.z);
		}
		A_StartSound(fireSound, CHAN_WEAPON);
		for (int i = 0; i < pellets; i++)
		{
			double sp = (pellets > 1 ? spread + 4 : spread) * (suppress ? 1.5 : 1.0);
			int dmg = int(random(dmgMin, dmgMax) * dmgMul);
			LineAttack(angle + frandom(-sp, sp), r, pit + frandom(-sp, sp) * 0.5, dmg, dmgType, "BulletPuff");
		}
		roundsLeft--;
		// rounds snapping past make them flinch
		if (suppress && live && enemy.health > 0 && random(0, 99) < 12)
		{
			let ps = enemy.FindState("Pain");
			if (ps && !enemy.InStateSequence(enemy.CurState, ps)) enemy.SetState(ps);
		}
	}

	void A_AllyBurstNext()
	{
		if (roundsLeft <= 0) { SetStateLabel("Reload"); return; }
		if (--burstLeft > 0) SetStateLabel("Burst");
		else A_SetTics(refireTics * 3);
	}

	void A_AllyRefire()
	{
		A_SetTics(refireTics);
	}

	void A_AllyReloadWait()
	{
		A_SetTics(reloadTics);
	}

	void A_AllyReloaded()
	{
		roundsLeft = magazine;
	}

	// "####": the sprite is the officer's class (Equip); the frames are the same across the four sets
	States
	{
	Spawn:
		EW1A A 1;
	See:
		#### A 4 A_AllyThink;
		#### B 4 A_AllyThink;
		#### C 4 A_AllyThink;
		#### D 4 A_AllyThink;
		Loop;
	Missile:
		#### E 6 A_AllyAimDelay;
	Burst:
		#### E 2 A_AllyAim;
		#### G 2 Bright A_AllyShoot;
		#### E 3 A_AllyRefire;
		#### E 1 A_AllyBurstNext;
		#### E 10 A_AllyAim;
		Goto See;
	Reload:
		#### E 0 A_StartSound("en/mgCOCK", CHAN_ITEM, CHANF_DEFAULT, 0.6);
		#### E 45 A_AllyReloadWait;
		#### E 0 A_AllyReloaded;
		Goto See;
	Pain:
		#### H 3;
		#### H 3 A_Pain;
		Goto See;
	Death:
		#### I 5;
		#### J 5 A_Scream;
		#### K 5 A_NoBlocking;
		#### L 5;
		#### M -1;
		Stop;
	}
}
