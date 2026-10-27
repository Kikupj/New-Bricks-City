// Allied officers (AGENTS.md squad rules): their own target-finding, no engine FRIENDLY AI.
// They follow the player, shoot visible gang members with hitscan NBC_Light rounds (never "Enemy"),
// reload every magazine, catch up when lost, and never take damage from the player, each other or fire.
// Uses the specop sprites (EW1A) from actors/enemies/wolfsA.txt; the specop classes themselves stay
// out of every enemy pool.

class NBC_Ally : Actor
{
	const MAGAZINE = 24;
	const SIGHT_RANGE = 1600.0;
	const FOLLOW_DIST = 144.0;
	const LOST_DIST = 1024.0;

	Actor enemy;
	int slot;
	int roundsLeft;
	int thinkCount;
	int lostTics;
	int burstLeft;

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
		Translation "192:204=196:200", "205:207=200:202", "118:121=196:198", "122:127=200:203";
		SeeSound "EliteN/see";
		PainSound "EliteN/pain";
		DeathSound "EliteN/die";
		Obituary "%o was shot by a fellow officer.";
		Tag "Officer";
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		roundsLeft = MAGAZINE;
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		// the player and the squad never hurt officers
		if (source && (source.player || source is "NBC_Ally")) return 0;
		if (inflictor && inflictor.target && (inflictor.target.player || inflictor.target is "NBC_Ally")) return 0;
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
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
		double bestDist = SIGHT_RANGE;
		let it = BlockThingsIterator.Create(self, SIGHT_RANGE);
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

	// Called from the walk frames every 4 tics.
	void A_AllyThink()
	{
		if (enemy && (!IsGangMember(enemy) || !CheckSight(enemy, SF_IGNOREVISIBILITY))) enemy = null;
		if (++thinkCount % 3 == 0 || !enemy) enemy = FindEnemy();

		if (enemy && Distance3D(enemy) < SIGHT_RANGE)
		{
			angle = AngleTo(enemy);
			burstLeft = 3;
			SetStateLabel("Missile");
			return;
		}

		let p = Leader();
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

	void A_AllyShoot()
	{
		if (!enemy || !IsGangMember(enemy)) { SetStateLabel("See"); return; }
		if (roundsLeft <= 0) { SetStateLabel("Reload"); return; }
		angle = AngleTo(enemy);
		double pit = AimLineAttack(angle, SIGHT_RANGE);
		A_StartSound("en/silsmg", CHAN_WEAPON);
		LineAttack(angle + frandom(-3.5, 3.5), SIGHT_RANGE, pit + frandom(-2, 2), random(7, 11), 'NBC_Light', "BulletPuff");
		roundsLeft--;
	}

	void A_AllyBurstNext()
	{
		if (roundsLeft <= 0) { SetStateLabel("Reload"); return; }
		if (--burstLeft > 0) SetStateLabel("Burst");
	}

	void A_AllyReloaded()
	{
		roundsLeft = MAGAZINE;
	}

	States
	{
	Spawn:
	See:
		EW1A A 4 A_AllyThink;
		EW1A B 4 A_AllyThink;
		EW1A C 4 A_AllyThink;
		EW1A D 4 A_AllyThink;
		Loop;
	Missile:
		EW1A E 6 A_AllyAim;
	Burst:
		EW1A F 2 A_AllyAim;
		EW1A G 2 Bright A_AllyShoot;
		EW1A F 2;
		EW1A G 2 Bright A_AllyShoot;
		EW1A F 3 A_AllyBurstNext;
		EW1A E 10 A_AllyAim;
		Goto See;
	Reload:
		EW1A E 0 A_StartSound("en/mgCOCK", CHAN_ITEM, CHANF_DEFAULT, 0.6);
		EW1A E 45;
		EW1A E 0 A_AllyReloaded;
		Goto See;
	Pain:
		EW1A H 3;
		EW1A H 3 A_Pain;
		Goto See;
	Death:
		EW1A I 5;
		EW1A J 5 A_Scream;
		EW1A K 5 A_NoBlocking;
		EW1A L 5;
		EW1A M -1;
		Stop;
	}
}
