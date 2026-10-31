// What the gang's guns are allowed to do (PLAN.md M4).
//
// The explosives cap (the biggest complaint about Hamburger Hill): at most one enemy grenade, Molotov or rocket in
// the air at a time across the block. Each throw has a 0.6-second wind-up (the shot is held at the muzzle with a cue
// on the thrower: the pin, or the launcher's click), never goes at something the thrower can't see, and the same
// enemy waits 8 seconds before the next. Everything the enemy pack throws or fires that explodes comes through
// here: its rockets (MiniRocket: the Rocketeer and BruteGL's three-rocket volley, now one at a time) and anything
// named a grenade or a Molotov; the player's and the officers' are never touched.
//
// Marksmen (the Wall Watch: gangs.txt marksman = 1): 25% more accurate past 512 units (their tracers turned a
// quarter of the way back onto you), and slow up close: a one-second reaction delay when they open fire within 256.

class NBC_EnemyFire : EventHandler
{
	const WINDUP = 21;              // 0.6 s
	const COOLDOWN = 35 * 8;
	const BUSY_MAX = 35 * 4;        // the slot frees up when the shot's gone, or after this long
	const LONG_RANGE = 512.0;
	const AIM_FIX = 0.25;

	Actor live;                     // the one explosive in the air (or held)
	int busyUntil;
	int marksmanShots;              // long-range rounds a marksman put back on target (nbc_debug_director)

	static bool IsExplosive(Actor mo)
	{
		if (mo is "MiniRocket") return true;
		String c = mo.GetClassName();
		c = c.MakeLower();
		return c.IndexOf("grenade") >= 0 || c.IndexOf("molotov") >= 0 || c.IndexOf("rocket") >= 0;
	}

	static bool IsGangShot(Actor mo)
	{
		let src = mo.target;
		return src && !src.player && !(src is "NBC_Ally") && src.bIsMonster;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let mo = e.Thing;
		if (!mo || !mo.bMissile || !IsGangShot(mo)) return;
		let src = mo.target;
		if (IsExplosive(mo))
		{
			let clock = NBC_ThrowClock(src.FindInventory("NBC_ThrowClock"));
			bool busy = live && live != mo && level.maptime < busyUntil;
			bool cooling = clock && level.maptime < clock.readyAt;
			bool blind = !src.target || !src.CheckSight(src.target);
			if (busy || cooling || blind)
			{
				if (developer) Console.Printf("nbc enemy fire: %s from %s held back (%s)", mo.GetClassName(), src.GetClassName(), busy ? "another in the air" : (cooling ? "cooling down" : "can't see"));
				mo.Destroy();
				return;
			}
			if (!clock) clock = NBC_ThrowClock(src.GiveInventoryType("NBC_ThrowClock"));
			if (clock) clock.readyAt = level.maptime + COOLDOWN;
			live = mo;
			busyUntil = level.maptime + BUSY_MAX;
			NBC_HeldShot.Hold(mo, WINDUP);
			if (developer) Console.Printf("nbc enemy fire: %s from %s, 0.6 s wind-up", mo.GetClassName(), src.GetClassName());
			src.A_StartSound(mo is "MiniRocket" ? "misc/chat" : "FragGrenade/pin", CHAN_AUTO, 0, 1.0, 0.7);
			return;
		}
		// a marksman's round at long range: a quarter of the way back onto the target
		if (src.FindInventory("NBC_Marksman") && src.target && src.Distance2D(src.target) > LONG_RANGE)
		{
			double speed = mo.vel.Length();
			if (speed <= 0) return;
			Vector3 aim = src.target.pos + (0, 0, src.target.height * 0.6) - mo.pos;
			if (aim.Length() <= 0) return;
			Vector3 dir = mo.vel / speed * (1 - AIM_FIX) + aim.Unit() * AIM_FIX;
			if (dir.Length() <= 0) return;
			mo.vel = dir.Unit() * speed;
			mo.angle = VectorAngle(mo.vel.x, mo.vel.y);
			marksmanShots++;
		}
	}

	override void WorldThingDestroyed(WorldEvent e)
	{
		if (e.Thing && e.Thing == live) { live = null; busyUntil = level.maptime + 10; }
	}
}

// when an enemy may throw again
class NBC_ThrowClock : Inventory
{
	int readyAt;
	Default { +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; Inventory.MaxAmount 1; }
}

// an explosive held at the muzzle for its wind-up: invisible and still, then let go on the line it was fired on
class NBC_HeldShot : Thinker
{
	Actor shot;
	Vector3 vel;
	int releaseAt;
	bool grabbed;

	static void Hold(Actor mo, int tics)
	{
		let h = new("NBC_HeldShot");
		h.shot = mo;
		h.releaseAt = level.maptime + tics;
		h.Grab();
	}

	void Grab()
	{
		if (!shot) return;
		// the launcher sets the velocity after the spawn; until then there's nothing to hold
		if (shot.vel.Length() <= 0) return;
		vel = shot.vel;
		shot.vel = (0, 0, 0);
		shot.bInvisible = true;
		shot.bNoGravity = true;
		grabbed = true;
	}

	override void Tick()
	{
		if (!shot) { Destroy(); return; }
		if (!grabbed) { Grab(); if (!grabbed) return; }
		if (level.maptime < releaseAt)
		{
			shot.vel = (0, 0, 0);
			return;
		}
		shot.vel = vel;
		shot.bInvisible = false;
		let def = GetDefaultByType(shot.GetClass());
		shot.bNoGravity = def.bNoGravity;
		Destroy();
	}
}

// a Wall Watch shooter: slow to react up close
class NBC_Marksman : Inventory
{
	const CLOSE = 256.0;
	const DELAY = 35;
	int delayedAt;
	Default { +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; Inventory.MaxAmount 1; }

	override void DoEffect()
	{
		Super.DoEffect();
		let o = Owner;
		if (!o || o.health <= 0 || !o.target || !o.MissileState) return;
		if (!o.InStateSequence(o.CurState, o.MissileState) || o.CurState != o.MissileState) return;
		if (o.Distance2D(o.target) > CLOSE || level.maptime < delayedAt) return;
		// the first frame of an attack at close range: a beat late
		o.tics += DELAY;
		delayedAt = level.maptime + DELAY + 35 * 3;
	}
}
