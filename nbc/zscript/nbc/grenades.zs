// Smoke grenades and flashbangs, for you and the squad (owner request). Pouch items off the Evidence Locker
// (NBC_Cat.IT_SMOKE / IT_FLASH). You throw them with their own keys (Y a flashbang, U smoke; hold to throw further)
// or from the inventory bar, through the quick throw's hand (player.zs); officers lob theirs (ally.zs, TryGrenade).
// The art is the FragGrenade pack's grenade recoloured (tools/art/make_grenade_art.py), which also draws the smoke.
//
// Smoke: the gang's own sight (the engine's) sees through actors, so the cloud breaks it by hand: a gang member
// whose line to its target runs through a cloud loses the target, one standing in it is blind, and while you stand
// in one nobody picks you up (CF_NOTARGET). Officers can't see through it either (NBC_Ally.ClearShot).
// Flashbang: gang members who see the bang in range stand dazed in their pain frame for a few seconds; you get a
// white-out if you're looking at one of your own close up (an officer's only dims your view a little).

class NBC_GrenadeItem : Inventory
{
	virtual class<Actor> Projectile() { return null; }

	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 5;
		Inventory.InterHubAmount 5;
		Inventory.PickupSound "misc/i_pkup";
		+INVENTORY.INVBAR;
		Scale 0.8;
	}

	// from the inventory bar: a quick throw, no wind-up (the grenade comes off when it's actually thrown)
	override bool Use(bool pickup)
	{
		let pawn = NBC_Player(Owner);
		if (pawn && !pickup) pawn.NBC_BeginGrenadeThrow(GetClass(), false);
		return false;
	}
}

class NBC_SmokeGrenade : NBC_GrenadeItem
{
	override class<Actor> Projectile() { return "NBC_SmokeGrenadeThrown"; }
	Default
	{
		Inventory.Icon "NSMGA0";
		Inventory.PickupMessage "Picked up a smoke grenade.";
		Tag "Smoke Grenade";
	}
	States { Spawn: NSMG A -1; Stop; }
}

class NBC_Flashbang : NBC_GrenadeItem
{
	override class<Actor> Projectile() { return "NBC_FlashbangThrown"; }
	Default
	{
		Inventory.Icon "NFBGA0";
		Inventory.PickupMessage "Picked up a flashbang.";
		Tag "Flashbang";
	}
	States { Spawn: NFBG A -1; Stop; }
}

// ------------------------------------------------------------ in flight

// Bounces about like the pack's grenade and goes off when its fuse runs out, wherever it came to rest.
class NBC_GrenadeThrown : Actor
{
	int fuse;

	virtual void Detonate() {}

	Default
	{
		Radius 6;
		Height 4;
		Speed 14;
		Mass 9;
		Damage 0;
		Gravity 0.7;
		BounceType "Doom";
		BounceFactor 0.45;
		WallBounceFactor 0.4;
		BounceCount 5;
		BounceSound "FragGrenade/Bounce";
		WallBounceSound "FragGrenade/Bounce";
		ReactionTime 52;            // the fuse, in tics
		Projectile;
		-NOGRAVITY;
		+CANBOUNCEWATER;
		+NOBLOOD;
		+THRUSPECIES;
		+MTHRUSPECIES;
		Species "NBC_Squad";
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		fuse = ReactionTime;
	}

	// a grenade doesn't hurt whoever it lands on, and a thrown one never stops on an officer
	override int SpecialMissileHit(Actor victim)
	{
		if (victim == target || victim is "NBC_Ally" || victim.player) return 1;
		return -1;
	}

	override void Tick()
	{
		Super.Tick();
		if (isFrozen() || bDestroyed) return;
		if (--fuse == 0)
		{
			Detonate();
			Destroy();
		}
	}
}

class NBC_SmokeGrenadeThrown : NBC_GrenadeThrown
{
	Default { ReactionTime 45; }

	override void Detonate()
	{
		let c = Spawn("NBC_SmokeCloud", (pos.xy, floorz), ALLOW_REPLACE);
		if (c) c.target = target;
	}

	States
	{
	Spawn:
		NSMT ABCDEF 3;
		Loop;
	Death:
		NSMT A -1;
		Stop;
	}
}

class NBC_FlashbangThrown : NBC_GrenadeThrown
{
	const RANGE = 420.0;
	const PLAYER_RANGE = 380.0;

	Default { ReactionTime 52; }

	override void Detonate()
	{
		A_StartSound("FragGrenade/Explode", CHAN_BODY, CHANF_DEFAULT, 1.0, 0.6, 1.5);
		A_AlertMonsters(1200);
		Spawn("NBC_FlashLight", pos + (0, 0, 8));
		for (int i = 0; i < 24; i++)
			A_SpawnParticle("White", SPF_FULLBRIGHT, random[nbcnade](8, 16), random[nbcnade](3, 6), random[nbcnade](0, 359),
				0, 0, 8, frandom[nbcnade](-4, 4), frandom[nbcnade](-4, 4), frandom[nbcnade](1, 5), 0, 0, -0.2, 1.0, -1, -0.3);
		NBC_Grenades.Bang(self, RANGE);

		// your own flashbang close up, if you're looking at it: a white-out; an officer's only dims your view
		let p = players[consoleplayer].mo;
		if (p && p.health > 0 && p.Distance3D(self) < PLAYER_RANGE && p.CheckSight(self, SF_IGNOREVISIBILITY))
		{
			double facing = abs(Actor.DeltaAngle(p.angle, p.AngleTo(self)));
			double strength = (1.0 - p.Distance3D(self) / PLAYER_RANGE) * (facing < 60 ? 1.0 : facing < 110 ? 0.5 : 0.2);
			if (target is "NBC_Ally") strength = min(strength, 0.35);
			if (strength > 0.05) p.A_SetBlend("White", min(0.95, 0.4 + strength), int(35 * (1 + 4 * strength)));
		}
	}

	States
	{
	Spawn:
		NFBT ABCDEF 3;
		Loop;
	Death:
		NFBT A -1;
		Stop;
	}
}

// the bang's light, for a moment (the software renderer draws none: the particles and the white-out carry it)
class NBC_FlashLight : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; RenderStyle "None"; }

	override void Tick()
	{
		Super.Tick();
		int age = GetAge();
		if (age > 7) { Destroy(); return; }
		A_AttachLight('flash', DynamicLight.PointLight, 0xFFFFF0, 420 - age * 55, 0);
	}
}

// ------------------------------------------------------------ the smoke

class NBC_SmokeCloud : Actor
{
	const LIFE = 35 * 20;
	const FULL = 168.0;         // the cloud's radius once it's out
	const HIGH = 112.0;
	double rad;

	Default
	{
		+NOINTERACTION;
		+NOBLOCKMAP;
		RenderStyle "None";
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		rad = 24;
		A_StartSound("nbc_smoke_hiss", CHAN_BODY, CHANF_DEFAULT, 0.6, 1.4);
	}

	// how thick it is now: it billows out over two seconds and thins away over the last four
	double Thickness()
	{
		int age = GetAge();
		if (age > LIFE - 35 * 4) return clamp((LIFE - age) / (35.0 * 4), 0, 1);
		return 1;
	}

	override void Tick()
	{
		Super.Tick();
		if (isFrozen()) return;
		int age = GetAge();
		if (age >= LIFE) { Destroy(); return; }
		rad = min(FULL, rad + 3);
		// the puffs: a steady churn while it's thick, fewer as it thins
		if (age % 3 == 0 && frandom[nbcnade](0, 1) < Thickness() + 0.15)
		{
			double a = frandom[nbcnade](0, 360), r = frandom[nbcnade](0, rad * 0.9);
			Vector2 at = pos.xy + AngleToVector(a, r);
			let s = Spawn("NBC_SmokePuff", (at, pos.z + frandom[nbcnade](0, HIGH * 0.6)));
			if (s)
			{
				s.vel = (frandom[nbcnade](-0.3, 0.3), frandom[nbcnade](-0.3, 0.3), frandom[nbcnade](0.05, 0.3));
				s.Alpha = 0.55 + 0.3 * Thickness();
			}
		}
	}

	// does the line from a to b run through this cloud (thick enough to hide in)?
	bool Cuts(Vector3 a, Vector3 b)
	{
		if (Thickness() < 0.35) return false;
		double r = rad * 0.85;
		Vector2 d = b.xy - a.xy;
		double len2 = d dot d;
		double t = len2 > 0 ? clamp(((pos.xy - a.xy) dot d) / len2, 0, 1) : 0;
		Vector3 c = a + (b - a) * t;
		if ((c.xy - pos.xy).Length() > r) return false;
		return c.z > pos.z - 16 && c.z < pos.z + HIGH;
	}

	bool Holds(Vector3 at)
	{
		return Thickness() >= 0.35 && (at.xy - pos.xy).Length() < rad * 0.8 && at.z > pos.z - 16 && at.z < pos.z + HIGH;
	}
}

class NBC_SmokePuff : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOBLOCKMAP;
		+FORCEXYBILLBOARD;
		RenderStyle "Translucent";
		Alpha 0.7;
		Scale 1.6;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		frame = random[nbcnade](0, 3);
		Scale *= frandom[nbcnade](0.8, 1.3);
	}

	override void Tick()
	{
		Super.Tick();
		if (isFrozen()) return;
		Scale *= 1.004;
		int age = GetAge();
		if (age > 35 * 3) Alpha -= 0.012;
		if (Alpha <= 0 || age > 35 * 6) Destroy();
	}

	States { Spawn: NSMK A -1; Stop; }
}

// ------------------------------------------------------------ the bang's daze

// Holds a dazed gang member in their pain frame: their state doesn't advance, so they don't move or shoot.
class NBC_FlashStun : Thinker
{
	Actor victim;
	int left;

	static void Daze(Actor mo, int tics)
	{
		let it = ThinkerIterator.Create("NBC_FlashStun", STAT_USER);
		NBC_FlashStun s;
		while ((s = NBC_FlashStun(it.Next()))) if (s.victim == mo) { s.left = max(s.left, tics); return; }
		s = new("NBC_FlashStun");
		s.ChangeStatNum(STAT_USER);
		s.victim = mo;
		s.left = tics;
		// out of whatever ducking or dodging they were at (tactical.zs), and nothing more till it wears off
		let tac = NBC_TacticalAI(mo.FindInventory("NBC_TacticalAI"));
		if (tac) { tac.EnterNormalState(); tac.dazedUntil = level.maptime + tics; }
		State pain = mo.FindState("Pain");
		if (pain) mo.SetState(pain);
	}

	override void Tick()
	{
		if (!victim || victim.health <= 0 || --left <= 0) { Destroy(); return; }
		if (victim.tics >= 0 && victim.tics < 2) victim.tics = 2;
		victim.vel.xy *= 0.6;
		if (left % 10 == 0)
			victim.A_SpawnParticle("White", SPF_FULLBRIGHT, 12, 3, 0, frandom[nbcnade](-10, 10), frandom[nbcnade](-10, 10),
				victim.height + 4, 0, 0, 0.6, 0, 0, 0, 0.9, -1, 0);
	}
}

// ------------------------------------------------------------ the rules

class NBC_Grenades : EventHandler
{
	// the bang: gang members in range who can see it are dazed, longer the closer and the more they faced it
	static void Bang(Actor at, double range)
	{
		let it = BlockThingsIterator.Create(at, range);
		while (it.Next())
		{
			Actor mo = it.thing;
			if (!NBC_Ally.IsGangMember(mo)) continue;
			double d = mo.Distance3D(at);
			if (d > range || !mo.CheckSight(at, SF_IGNOREVISIBILITY)) continue;
			double facing = abs(Actor.DeltaAngle(mo.angle, mo.AngleTo(at)));
			double secs = 2.0 + 3.5 * (1.0 - d / range);
			if (facing > 100) secs *= 0.55;
			let off = NBC_OffGuard(mo.FindInventory("NBC_OffGuard"));
			if (off) off.WakeIn(int(35 * secs));        // caught napping: they wake to the ringing, later
			else NBC_FlashStun.Daze(mo, int(35 * secs));
		}
	}

	// any cloud between a and b?
	static bool SmokeBetween(Vector3 a, Vector3 b)
	{
		let it = ThinkerIterator.Create("NBC_SmokeCloud");
		NBC_SmokeCloud c;
		while ((c = NBC_SmokeCloud(it.Next()))) if (c.Cuts(a, b)) return true;
		return false;
	}

	static bool InSmoke(Vector3 at)
	{
		let it = ThinkerIterator.Create("NBC_SmokeCloud");
		NBC_SmokeCloud c;
		while ((c = NBC_SmokeCloud(it.Next()))) if (c.Holds(at)) return true;
		return false;
	}

	bool hidingYou;

	override void WorldTick()
	{
		if (level.maptime % 4) return;
		let p = players[consoleplayer].mo;
		bool clouds = ThinkerIterator.Create("NBC_SmokeCloud").Next() != null;
		// you in the smoke: nobody picks you up (those already on you lose you below)
		bool hide = clouds && p && InSmoke(p.pos + (0, 0, p.height * 0.5));
		if (p && p.player && hide != hidingYou)
		{
			if (hide) p.player.cheats |= CF_NOTARGET;
			else p.player.cheats &= ~CF_NOTARGET;
			hidingYou = hide;
		}
		if (!clouds) return;
		// gang members on a target through the smoke, or standing in it, lose them
		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		while ((mo = Actor(it.Next())))
		{
			if (!mo.target || !NBC_Ally.IsGangMember(mo)) continue;
			Actor t = mo.target;
			if (!t.player && !(t is "NBC_Ally")) continue;
			Vector3 eye = mo.pos + (0, 0, mo.height * 0.8);
			if (!InSmoke(eye) && !SmokeBetween(eye, t.pos + (0, 0, t.height * 0.6))) continue;
			bool shooting = mo.MissileState && mo.InStateSequence(mo.CurState, mo.MissileState);
			mo.A_ClearTarget();
			if (shooting || mo.InStateSequence(mo.CurState, mo.SeeState)) mo.SetState(mo.SpawnState);
		}
	}

	// the keys: netevent nbc_grenade_start <1 flashbang | 2 smoke>, then nbc_grenade_release
	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player]) return;
		let pawn = NBC_Player(players[e.Player].mo);
		if (!pawn) return;
		if (e.Name == "nbc_grenade_start")
		{
			class<Inventory> cls = e.Args[0] == 2 ? "NBC_SmokeGrenade" : "NBC_Flashbang";
			if (pawn.CountInv(cls) > 0) pawn.NBC_BeginGrenadeThrow(cls, true);
			else pawn.A_Print(e.Args[0] == 2 ? "No smoke grenades." : "No flashbangs.", 1);
		}
		else if (e.Name == "nbc_grenade_release") pawn.NBC_ReleaseQuickThrow();
	}
}
