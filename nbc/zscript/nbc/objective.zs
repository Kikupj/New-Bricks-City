// Raid objectives (PLAN.md M4, §6.6) and the gang breaking (NBC_Morale, §4.3).
//
// NBC_Objective is the base: a raid has one (M9 adds the others: evidence runs, rescues, arrests...). The first is
// the Sweep: clear the threat budget. The block is SECURE once the leader is down and three in four of everyone the
// gang put in are down (one in two for a gang that breaks easily: gangs.txt morale = 0.5); any waves still to come
// are called off. Leaving by the exit takes the block only once it's secure; before that it's a retreat.
//
// When the block's secure the ones still standing give up: they kneel where they are for 20 seconds (NBC_Captive:
// their pain frame, held), and Use cuffs them. The rest then run for the map's edge and are gone.

class NBC_Objective play
{
	bool done;
	virtual void Begin(NBC_RunManager rm, NBC_RunData rd, NBC_GangDef g) {}
	virtual void Tick(NBC_RunManager rm, NBC_RunData rd, NBC_GangDef g) {}
	virtual clearscope String Status(NBC_RunManager rm, NBC_RunData rd) const { return ""; }
}

class NBC_Sweep : NBC_Objective
{
	const BREAK_AT = 0.75;
	double breakAt;

	override void Begin(NBC_RunManager rm, NBC_RunData rd, NBC_GangDef g)
	{
		breakAt = g && g.moraleBreak > 0 ? g.moraleBreak : BREAK_AT;
	}

	override void Tick(NBC_RunManager rm, NBC_RunData rd, NBC_GangDef g)
	{
		if (done || !rm.director) return;
		let d = rm.director;
		int total = max(1, d.sentTotal);
		int down = total - d.Alive();
		if (!rd.leaderDown || down < total * breakAt) return;
		done = true;
		d.CallOff();
		rm.Secure(rd);
	}

	override clearscope String Status(NBC_RunManager rm, NBC_RunData rd) const
	{
		if (done) return "BLOCK SECURE: head for the exit";
		if (!rm.director) return "";
		let d = rm.director;
		int total = max(1, d.sentTotal);
		int down = total - d.Alive();
		int need = int(ceil(total * breakAt));
		return String.Format("SWEEP: %d of %d down (%d to break them)%s", down, total, max(0, need - down),
			d.Spent() ? "" : String.Format(", wave %d of %d", d.wave, d.waves));
	}
}

// A gang member who's given up. Kneels (the pain frame, held) for KNEEL seconds; Use cuffs them. Uncuffed, they run
// for the map's edge along the nav graph and are gone once you've lost sight of them (or after RUN seconds).
// Shoot one and they die the way they would have (their own class's death).
class NBC_Captive : Actor
{
	const KNEEL = 20;
	const RUN = 20;
	class<Actor> was;
	State see;
	int phase, until, animAt;
	bool cuffed;
	Vector2 edge;

	Default
	{
		Radius 16; Height 40; Health 40; Mass 400;
		+SOLID; +SHOOTABLE; +NOBLOOD; +DONTTHRUST; +NOTARGET; +NOBLOCKMONST;
		Tag "Surrendered";
	}

	// swap a gang member for their surrender: same look, same place
	static NBC_Captive Take(Actor m, Vector2 edge)
	{
		if (!m || m.health <= 0) return null;
		let c = NBC_Captive(Actor.Spawn("NBC_Captive", m.pos, NO_REPLACE));
		if (!c) return null;
		c.was = m.GetClass();
		c.angle = m.angle;
		c.Translation = m.Translation;
		c.Scale = m.Scale;
		c.A_SetSize(m.radius, m.height * 0.75);
		c.health = max(1, m.health);
		c.SetTag(m.GetTag(""));
		State pain = m.FindState("Pain");
		if (!pain) pain = m.SpawnState;
		c.sprite = pain.sprite;
		c.frame = pain.Frame;
		c.see = m.SeeState;
		c.edge = edge;
		c.until = level.maptime + 35 * KNEEL;
		m.Destroy();
		return c;
	}

	override bool Used(Actor user)
	{
		if (!user || !user.player || cuffed || health <= 0 || phase != 0) return false;
		cuffed = true;
		A_StartSound("misc/chat", CHAN_BODY);
		let rd = NBC_RunData.Find();
		if (rd) rd.raidArrests++;
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (rm) rm.Announce(String.Format("Cuffed: %s.", NBC_Elite.NameOf(self)), 35 * 2);
		if (developer) Console.Printf("nbc objective: cuffed %s (%d arrests)", NBC_Elite.NameOf(self), rd ? rd.raidArrests : 0);
		return true;
	}

	override void Tick()
	{
		Super.Tick();
		if (health <= 0 || bDestroyed) return;
		if (phase == 0)
		{
			if (cuffed || level.maptime < until) return;
			// time's up: run for it
			phase = 1;
			until = level.maptime + 35 * RUN;
			bSolid = false;
			let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
			if (rm && !rm.runnersCalled) { rm.runnersCalled = true; NBC_Orders.Say("They're running!", Font.CR_ORANGE); if (developer) Console.Printf("nbc objective: they're running"); }
			RoutePlan();
			return;
		}
		// running: the See frames (no actions), along the route
		if (see && level.maptime >= animAt)
		{
			see = see.NextState ? see.NextState : SeeState;
			if (see) { sprite = see.sprite; frame = see.Frame; animAt = level.maptime + max(3, see.Tics); }
		}
		MoveOn();
		let p = players[consoleplayer].mo;
		if (level.maptime >= until || (p && (pos.xy - p.pos.xy).Length() > 768 && !CheckSight(p)))
		{
			let rd = NBC_RunData.Find();
			if (rd) rd.raidFled++;
			if (developer) Console.Printf("nbc objective: one got away (%d fled)", rd ? rd.raidFled : 0);
			Destroy();
		}
	}

	Array<double> px, py;
	int at;

	void RoutePlan()
	{
		px.Clear(); py.Clear(); at = 0;
		let o = NBC_Orders.Get();
		let graph = o ? o.Nav() : null;
		if (graph && graph.Route(pos.xy, edge))
			for (int i = 0; i < graph.path.Size(); i++) { int n = graph.path[i]; px.Push(graph.nx[n]); py.Push(graph.ny[n]); }
		px.Push(edge.x); py.Push(edge.y);
	}

	void MoveOn()
	{
		while (at < px.Size() && (pos.xy - (px[at], py[at])).Length() < 48) at++;
		if (at >= px.Size()) return;
		Vector2 d = (px[at], py[at]) - pos.xy;
		angle = VectorAngle(d.x, d.y);
		Vector2 step = d.Unit() * min(10.0, d.Length());
		if (!TryMove(pos.xy + step, 0)) { at++; }
	}

	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath)
	{
		// they die as themselves: their own class, killed where they knelt (it counts, and drops what they carried)
		class<Actor> cls = was;
		Vector3 at = pos;
		double ang = angle;
		int tr = Translation;
		Super.Die(source, inflictor, dmgflags, MeansOfDeath);
		if (cls)
		{
			let body = Actor.Spawn(cls, at, NO_REPLACE);
			if (body)
			{
				body.angle = ang;
				body.Translation = tr;
				body.DamageMobj(inflictor, source, body.health + 100, MeansOfDeath, DMG_FORCED);
			}
		}
		Destroy();
	}

	States { Spawn: TNT1 A -1; Stop; }
}
