// Allied officers (AGENTS.md squad rules): their own target-finding, no engine FRIENDLY AI.
// Each one is an officer off the roster (NBC_Officer): the class sets the build (specop, militia shotgunner,
// sniper and specop-F sprites from actors/enemies/, whose classes stay out of every enemy pool) and the
// issue weapon, the portrait sets the clothes (a plain-clothes recolor, nbc/TRNSLATE.txt); the kit can swap
// in a seized gun; rank, aim and perks shape how well they shoot.
// They follow the player, shoot visible gang members with hitscan in the gun's damage type (never "Enemy"),
// reload every magazine, use their pouches (medkits when hurt, Molotovs on a bunch of gang members), the
// Paramedic patches the player up, and they never take damage from the player, each other or fire.

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

	Actor FindEnemy()
	{
		Actor best = null;
		double bestDist = range > 0 ? range : SIGHT_RANGE;
		let it = BlockThingsIterator.Create(self, bestDist);
		while (it.Next())
		{
			Actor mo = it.thing;
			if (!IsGangMember(mo)) continue;
			double d = Distance3D(mo);
			if (d >= bestDist || !CheckSight(mo, SF_IGNOREVISIBILITY)) continue;
			best = mo;
			bestDist = d;
		}
		return best;
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

		if (enemy && (!IsGangMember(enemy) || !CheckSight(enemy, SF_IGNOREVISIBILITY))) enemy = null;
		if (++thinkCount % 3 == 0 || !enemy) enemy = FindEnemy();

		if (enemy)
		{
			angle = AngleTo(enemy);
			if (TryBottle(p)) return;
			burstLeft = burst;
			SetStateLabel("Missile");
			return;
		}

		if (!p) return;
		double d = Distance2D(p);
		if (d > LOST_DIST && !CheckSight(p))
		{
			lostTics += 4;
			if (lostTics >= 105) { CatchUp(p); lostTics = 0; }
		}
		else lostTics = 0;

		if (d > FOLLOW_DIST)
		{
			target = p;
			A_Chase(null, null, CHF_NOPLAYACTIVE);
			target = null;
		}
		else
		{
			frame = 0;   // stand still
			if (d < 64) A_FaceTarget();
		}
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
	}

	// the aim time before the first shot (Hair Trigger shortens it)
	void A_AllyAimDelay()
	{
		A_AllyAim();
		A_SetTics(aimTics);
	}

	void A_AllyShoot()
	{
		if (!enemy || !IsGangMember(enemy)) { SetStateLabel("See"); return; }
		if (roundsLeft <= 0) { SetStateLabel("Reload"); return; }
		angle = AngleTo(enemy);
		double r = range > 0 ? range : SIGHT_RANGE;
		double pit = AimLineAttack(angle, r);
		A_StartSound(fireSound, CHAN_WEAPON);
		for (int i = 0; i < pellets; i++)
		{
			double sp = pellets > 1 ? spread + 4 : spread;
			int dmg = int(random(dmgMin, dmgMax) * dmgMul);
			LineAttack(angle + frandom(-sp, sp), r, pit + frandom(-sp, sp) * 0.5, dmg, dmgType, "BulletPuff");
		}
		roundsLeft--;
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
