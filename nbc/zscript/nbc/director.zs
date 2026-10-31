// The spawn director (PLAN.md M4, §6.2): a raid's threat budget, spent in waves.
//
// The budget is §6.2's, for a whole district in one map (the old five-block raid's four floors and the leader's):
//   (12 + 8 x (gang tier - 1) + 4 x gangs toppled + 6 x alert) x 3 + 10
// times the gang's budget (Swarm), the hour's and the day's event's strength and the insertion. Gang members cost
// their tier: 1, 3, 6, 10 (tier 4: elite units, from the gang's roster4 once it's at alert 2, or in the Crown).
//
// Wave 1 is the crew NBC_RunManager.SetupRaid stands round the map at the start (some of them off guard). The rest
// of the budget, at least 30% of it, comes in 1-3 more waves (2-4 in all) once the block is awake (a gang member
// has seen you or the squad, or been hit): the next wave when 70% of the current one is down, or 30 seconds after
// it went in. Waves come in at spots you can't see, at least 384 away from you (the map's reinforcement spots
// first), with a puff of dust, and make their way to you along the nav graph (CW_NavGraph, cw/nav.zs) until they
// see you. A gang with an alarm (the Collectors) sends a wave the moment it wakes.

class NBC_Member : Inventory
{
	int tier, wave;
	Default { +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; Inventory.MaxAmount 1; }
	static NBC_Member Of(Actor a) { return a ? NBC_Member(a.FindInventory("NBC_Member")) : null; }
}

class NBC_Director play
{
	const WAVE_AT = 0.7;            // the next wave once this share of the current one is down
	const WAVE_SECS = 30;           // ... or this long after it went in
	const MIN_DIST = 384.0;         // a wave spawns at least this far from you
	const MIN_DIST_SQUAD = 256.0;   // and from your officers
	const MAX_WAVE = 14;            // gang members in one wave at most
	static const int TIER_COST[] = { 1, 3, 6, 10 };

	NBC_RunManager rm;
	int budget, spent;              // the block's threat budget, and what the crew and the waves cost so far
	int waves, wave;                // waves in all (the placed crew is wave 1), and the last one sent
	Array<int> waveBudget;          // each later wave's share (index 0: wave 2)
	Array<Actor> current;           // the last wave's members
	int nextAt;                     // the next wave goes in at this map time (once the block is awake)
	bool engaged, alarmSent, calledOff;
	int sentTotal;                  // gang members spawned in all (the crew, the leader and escorts, the waves)

	static NBC_Director Create(NBC_RunManager rm)
	{
		let d = new("NBC_Director");
		d.rm = rm;
		d.nextAt = -1;
		return d;
	}

	static int Cost(int tier) { return NBC_Director.TIER_COST[clamp(tier, 1, 4) - 1]; }

	// §6.2 for a district: the four floors' budgets and the leader's floor
	static int BlockBudget(NBC_GangDef g, NBC_RunData rd, int alert, double mul)
	{
		int base = 12 + 8 * (clamp(g.tier, 1, 3) - 1) + 4 * rd.ToppledCount() + 6 * alert;
		return max(12, int((base * 2 + 6) * mul));
	}

	// A tier for one gang member: mostly rank and file, more heavies at alert; tier 4 from the gang's roster4 once
	// it's at alert 2 or in the Crown
	static int PickTier(NBC_GangDef g, NBC_RunData rd, int alert)
	{
		int r = rd.Rand(0, 99);
		if (g.roster4.Size() && (alert >= 2 || g.crown) && r < 5) return 4;
		r = rd.Rand(0, 99);
		return r < 60 - alert * 5 ? 1 : (r < 90 ? 2 : 3);
	}

	// After the crew's placed: what it cost, and the waves the rest of the budget makes
	void Begin(NBC_GangDef g, NBC_RunData rd, int theBudget, int crewCost, int crewCount, out Array<Actor> crew)
	{
		budget = theBudget;
		spent = crewCost;
		sentTotal = crewCount;
		wave = 1;
		current.Clear();
		for (int i = 0; i < crew.Size(); i++) if (crew[i]) current.Push(crew[i]);
		int rest = clamp(budget - spent, budget / 5, budget * 2 / 5);
		int later = clamp(rest / 12, 1, 2);
		waves = 1 + later;
		waveBudget.Clear();
		for (int i = 0; i < later; i++) waveBudget.Push(rest / later + (i < rest % later ? 1 : 0));
	}

	clearscope bool AllSent() const { return calledOff || wave >= waves; }
	void CallOff() { calledOff = true; }

	// the block's awake: the waves start their clock (an alarm brings the next one now)
	void Engage(NBC_GangDef g, NBC_RunData rd)
	{
		if (engaged) return;
		engaged = true;
		nextAt = level.maptime + 35 * WAVE_SECS;
		if (g && g.alarm && !alarmSent && !AllSent())
		{
			alarmSent = true;
			rm.Announce("ALARM! The whole building knows you're here. More of them on the way.", 35 * 4);
			NBC_Orders.Say("They hit the alarm! More coming.", Font.CR_ORANGE);
			SendWave(g, rd);
		}
	}

	// once a second from NBC_RunManager.RaidTick
	void Tick(NBC_GangDef g, NBC_RunData rd, Actor p)
	{
		if (!g || !p) return;
		if (!engaged)
		{
			// anyone awake who can see you or an officer
			for (int i = 0; i < rm.crew.Size(); i++)
			{
				Actor m = rm.crew[i];
				if (!m || m.health <= 0 || !m.target || m.FindInventory("NBC_OffGuard")) continue;
				if ((m.target.player || m.target is "NBC_Ally") && m.CheckSight(m.target)) { Engage(g, rd); break; }
			}
			if (!engaged) return;
		}
		if (AllSent()) return;
		int alive = 0;
		for (int i = 0; i < current.Size(); i++) if (current[i] && current[i].health > 0) alive++;
		bool thinned = current.Size() == 0 || (current.Size() - alive) >= current.Size() * WAVE_AT;
		if (thinned || level.maptime >= nextAt) SendWave(g, rd);
	}

	// Spend the next wave's budget out of your sight
	void SendWave(NBC_GangDef g, NBC_RunData rd)
	{
		if (AllSent()) return;
		let p = players[consoleplayer].mo;
		if (!p) return;
		int share = waveBudget.Size() > wave - 1 ? waveBudget[wave - 1] : 0;
		wave++;
		nextAt = level.maptime + 35 * WAVE_SECS;
		current.Clear();
		int alert = rd.gangAlert.Size() > rd.raidGang ? rd.gangAlert[rd.raidGang] : 0;
		// the spots: hidden from you and the squad, far enough off; the reinforcement spots come first in the list
		Array<NBC_Spot> spots;
		for (int i = 0; i < rm.spareSpots.Size(); i++)
		{
			let s = rm.spareSpots[i];
			if ((s.pos.xy - p.pos.xy).Length() < MIN_DIST) continue;
			bool nearSquad = false;
			for (int k = 0; k < rm.squad.Size() && !nearSquad; k++)
				if (rm.squad[k] && rm.squad[k].health > 0 && (s.pos.xy - rm.squad[k].pos.xy).Length() < MIN_DIST_SQUAD) nearSquad = true;
			if (!nearSquad) spots.Push(s);
		}
		int left = share, sent = 0, tries = 0;
		while (left > 0 && sent < MAX_WAVE && tries < 60 && spots.Size())
		{
			tries++;
			int tier = PickTier(g, rd, alert);
			while (tier > 1 && Cost(tier) > left) tier--;
			int k = rd.Rand(0, min(spots.Size(), 12) - 1);       // mostly the first (reinforcement) spots
			let s = spots[k];
			let a = rm.SpawnMember(rm.PickRoster(g, rd, tier), s.pos, g, rd, rm.WaveHealth(g, rd), tier, wave);
			if (!a) { spots.Delete(k); continue; }
			if (a.CheckSight(p) || OfficerSees(a)) { a.Destroy(); spots.Delete(k); continue; }
			spots.Delete(k);
			left -= Cost(tier);
			spent += Cost(tier);
			sent++;
			sentTotal++;
			current.Push(a);
			rm.crew.Push(a);
			Actor.Spawn("NBC_SpawnPuff", a.pos, NO_REPLACE);
			NBC_Route.Toward(a, p.pos.xy);
		}
		if (sent)
		{
			rm.Announce(String.Format("Radio: wave %d of %d, %d more of them coming in.", wave, waves, sent), 35 * 4);
			NBC_Orders.Say(String.Format("Contact: %d more coming in.", sent), Font.CR_ORANGE);
		}
		if (developer) Console.Printf("nbc director: wave %d of %d, %d sent for %d of %d budget (spent %d of %d)", wave, waves, sent, share - left, share, spent, budget);
	}

	bool OfficerSees(Actor a)
	{
		for (int k = 0; k < rm.squad.Size(); k++)
			if (rm.squad[k] && rm.squad[k].health > 0 && rm.squad[k].CheckSight(a)) return true;
		return false;
	}

	// a Shot Caller elite calls in a few of the rank and file, out of sight near them
	int CallIn(NBC_GangDef g, NBC_RunData rd, Vector3 near, int count)
	{
		let p = players[consoleplayer].mo;
		if (!p || !g) return 0;
		Array<NBC_Spot> spots;
		for (int i = 0; i < rm.allSpots.Size(); i++)
		{
			let s = rm.allSpots[i];
			if ((s.pos.xy - p.pos.xy).Length() >= MIN_DIST && (s.pos.xy - near.xy).Length() < 1536) spots.Push(s);
		}
		int sent = 0;
		for (int t = 0; t < 30 && sent < count && spots.Size(); t++)
		{
			int k = rd.Rand(0, spots.Size() - 1);
			let a = rm.SpawnMember(rm.PickRoster(g, rd, 1), spots[k].pos, g, rd, rm.WaveHealth(g, rd), 1, wave);
			spots.Delete(k);
			if (!a) continue;
			if (a.CheckSight(p)) { a.Destroy(); continue; }
			sent++;
			sentTotal++;
			rm.crew.Push(a);
			Actor.Spawn("NBC_SpawnPuff", a.pos, NO_REPLACE);
			NBC_Route.Toward(a, p.pos.xy);
		}
		return sent;
	}

	// for the HUD and nbc_debug_director
	clearscope int Alive() const
	{
		int n = 0;
		for (int i = 0; i < rm.crew.Size(); i++) if (rm.crew[i] && rm.crew[i].health > 0) n++;
		if (rm.leader && rm.leader.health > 0) n++;
		return n;
	}

	void Debug()
	{
		int alive = Alive();
		Console.Printf("nbc director: budget %d, spent %d (%d left), wave %d of %d%s, block %s; %d spawned, %d standing",
			budget, spent, max(0, budget - spent), wave, waves, calledOff ? " (called off)" : "", engaged ? "awake" : "quiet", sentTotal, alive);
		for (int i = 0; i < rm.crew.Size(); i++)
		{
			Actor m = rm.crew[i];
			if (!m || m.health <= 0) continue;
			let mb = NBC_Member.Of(m);
			let el = NBC_Elite(m.FindInventory("NBC_Elite"));
			Console.Printf("  %s tier %d wave %d hp %d at (%d, %d)%s%s%s", m.GetClassName(), mb ? mb.tier : 0, mb ? mb.wave : 0, m.health,
				int(m.pos.x), int(m.pos.y), m.FindInventory("NBC_OffGuard") ? " off guard" : "", el ? " ELITE " .. el.Title() : "",
				m.target && m.target.player ? " on you" : "");
		}
	}
}

// A wave member's (or a runner's) way through the district: nav graph nodes to a point, walked as the monster's
// goal (A_Chase walks to a goal it doesn't attack). A wave member drops the route the moment it sees you or an
// officer, and goes back to the fight.
class NBC_Route : Inventory
{
	Array<double> px, py;
	int at;
	Actor point;
	Vector2 dest;
	bool flee;              // a runner (NBC_Captive): never fights, despawns at the end
	int replanAt;

	Default { +INVENTORY.UNDROPPABLE; +INVENTORY.UNTOSSABLE; Inventory.MaxAmount 1; }

	static NBC_Route Toward(Actor a, Vector2 to, bool flee = false)
	{
		if (!a) return null;
		let r = NBC_Route(a.FindInventory("NBC_Route"));
		if (!r) r = NBC_Route(a.GiveInventoryType("NBC_Route"));
		if (!r) return null;
		r.flee = flee;
		r.Plan(to);
		return r;
	}

	void Plan(Vector2 to)
	{
		dest = to;
		px.Clear(); py.Clear();
		at = 0;
		replanAt = level.maptime + 35 * 4;
		let o = NBC_Orders.Get();
		let graph = o ? o.Nav() : null;
		if (Owner && graph && graph.Route(Owner.pos.xy, to))
			for (int i = 0; i < graph.path.Size(); i++) { int n = graph.path[i]; px.Push(graph.nx[n]); py.Push(graph.ny[n]); }
		px.Push(to.x); py.Push(to.y);
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if (!Owner || Owner.health <= 0) { Finish(); return; }
		if (level.maptime % 4) return;
		// a wave member: back to the fight once it sees someone
		if (!flee && Owner.target && Owner.target != point && (Owner.target.player || Owner.target is "NBC_Ally") && Owner.CheckSight(Owner.target))
		{
			Finish();
			return;
		}
		if (!flee && level.maptime >= replanAt)
		{
			let p = players[consoleplayer].mo;
			if (p && (p.pos.xy - dest).Length() > 256) Plan(p.pos.xy);
			else replanAt = level.maptime + 35 * 4;
		}
		while (at < px.Size() && (Owner.pos.xy - (px[at], py[at])).Length() < 112) at++;
		if (at >= px.Size())
		{
			if (!flee) { Finish(); return; }
			at = px.Size() - 1;
		}
		Vector2 next = (px[at], py[at]);
		if (!point) point = Actor.Spawn("NBC_RoutePoint", (next, Owner.pos.z), NO_REPLACE);
		if (!point) { Finish(); return; }
		point.SetOrigin((next, Owner.floorz), false);
		Owner.goal = point;
		if (!Owner.target || Owner.target == point || !Owner.target.bShootable || flee)
		{
			Owner.target = point;
			if (Owner.InStateSequence(Owner.CurState, Owner.SpawnState)) Owner.SetState(Owner.SeeState);
		}
	}

	void Finish()
	{
		if (Owner)
		{
			if (Owner.goal == point) Owner.goal = null;
			if (Owner.target == point)
			{
				Owner.target = null;
				let p = players[consoleplayer].mo;
				if (!flee && p) Owner.target = p;
			}
		}
		if (point) point.Destroy();
		Destroy();
	}
}

class NBC_RoutePoint : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "None"; Radius 8; Height 16; }
	States { Spawn: TNT1 A -1; Stop; }
}

// a wave comes in: a puff of dust where they step out
class NBC_SpawnPuff : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "None"; }
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		for (int i = 0; i < 14; i++)
			A_SpawnParticle(0x8A8070, 0, random[nbcfx](24, 40), random[nbcfx](10, 18), 0,
				frandom[nbcfx](-14, 14), frandom[nbcfx](-14, 14), frandom[nbcfx](4, 40), frandom[nbcfx](-1, 1), frandom[nbcfx](-1, 1), frandom[nbcfx](0.2, 1.2),
				0, 0, -0.02, 0.6, -1, -0.2);
	}
	States { Spawn: TNT1 A 2; Stop; }
}
