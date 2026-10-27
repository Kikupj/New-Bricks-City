// =============================================================================
// Corpo Wars — the mission on a site-pack map (sitepool.zs says which map; this runs the job on it)
//
// The generators leave their mission markers in the manifest, not in the map; build_mod_pack.py copies them
// into CWSITES, and this reads them when a pack map loads:
//     31012-31015  entries (front, back, service, covert)    -> insertion + extraction
//     31020        objective spot                              -> the contract's objectives
//     31021        guard post                                  -> a guard standing watch
//     31022        patrol point                                -> patrol loops (chained by distance)
//     31023        bystander                                   -> civilians
//     31024        extraction                                  -> CW_Extraction
// A building is one or more maps (street block: ground floor, roof, upper floor / basement; hotel: its floors).
// Everything that has to agree across the floors (which entry the visit uses, where the objectives are) is a pure
// function of the building's record and the visit seed, so each floor works it out on its own when it loads.
// Walk-in visits (HUD city map, no contract) get guards and bystanders but no objectives.
// =============================================================================

class CW_SiteMission play
{
	CW_SiteBld bld;
	String mapName;
	int floorIdx;
	bool missionOn, siteSet, neutralSite;
	int siteForce, siteTech, visitSeed, entryPref;
	int rng, guards, civs;
	CW_ObsProbe probe;

	int insertIdx;
	bool hasInsert;                 // this floor holds the insertion
	Vector2 insertPos;
	double insertAng, insertZ;
	String insertName, siteName;
	Array<double> exX, exY;         // extraction points on this floor
	Array<double> stX, stY;         // stairs / lifts to the other floors
	int objMk[4];                   // per objective kind: index of the objective marker (whole building)
	int objPlaced;
	const SAFE_R = 480;

	int Rand(int lo, int hi)
	{
		rng = rng * 1103515245 + 12345;
		int r = (rng >>> 16) & 0x7fff;
		return hi <= lo ? lo : lo + r % (hi - lo + 1);
	}

	// ---------------------------------------------------------------- setup
	bool Init(CW_Ledger l, CW_Contract c)
	{
		mapName = level.MapName;
		bld = CW_SitePool.Load(CW_SitePool.BldOf(mapName));
		if (!bld) { Console.Printf("\cgSites: no CWSITES record for %s", mapName); return false; }
		floorIdx = bld.FloorOf(mapName);
		missionOn = c && l && l.missionActive;
		if (missionOn)
		{
			siteSet = true; siteForce = c.secForce; siteTech = c.secTech; neutralSite = c.neutral;
			visitSeed = l.visitSeed; entryPref = c.prepIntel ? l.entryPref : 0;
			siteName = c.target;
		}
		else { visitSeed = 0; entryPref = 2; siteName = bld.title; }
		insertIdx = CW_SitePool.PickEntry(bld, visitSeed, entryPref);
		rng = bld.seed * 31 + (floorIdx + 1) * 7919;
		for (int k = 0; k < 4; k++) objMk[k] = -1;
		return true;
	}

	// ---------------------------------------------------------------- placing things
	// the floor at p: the marker's own height where it gives one (3D-floor buildings stack levels over one sector)
	double GroundZ(Vector2 p, double zhint, bool useHint)
	{
		Sector s = level.PointInSector(p);
		if (!s) return 0;
		double base = s.floorplane.ZAtPoint(p);
		if (!useHint) return base;
		double f; Sector s2; F3DFloor ff;
		[f, s2, ff] = s.NextLowestFloorAt(p.x, p.y, zhint + 4);
		return max(f, base);
	}
	double MarkerZ(int i)
	{
		bool derived = bld.kNote[i].Length() && bld.kNote[i].ByteAt(0) == 126;    // '~': made by the pack builder, z is a guess
		return GroundZ((bld.kX[i], bld.kY[i]), bld.kZ[i], !derived);
	}

	bool Fit(Vector2 p, double z, double r, double h)
	{
		Sector s = level.PointInSector(p);
		if (!s) return false;
		double c; Sector s2; F3DFloor ff;
		[c, s2, ff] = s.NextHighestCeilingAt(p.x, p.y, z, z + h);
		if (c < z + h) return false;
		if (!probe) probe = CW_ObsProbe(Actor.Spawn("CW_ObsProbe", (p, z)));
		if (!probe) return false;
		probe.A_SetSize(r, h);
		probe.SetOrigin((p, z), false);
		return probe.CheckPosition(p);
	}

	Actor Put(Class<Actor> cls, Vector2 p, double z, double ang, bool check = true)
	{
		let def = GetDefaultByType(cls);
		if (check && !Fit(p, z, def.radius + 2, def.height)) return null;
		let a = Actor.Spawn(cls, (p, z));
		if (a) a.angle = ang;
		return a;
	}

	// at p, else on a widening ring around it (the markers are room-level; furniture may sit on them)
	Actor PutNear(Class<Actor> cls, Vector2 p, double z, bool useHint, double ang)
	{
		Actor a = Put(cls, p, z, ang);
		if (a) return a;
		for (int ring = 1; ring <= 5; ring++)
			for (int d = 0; d < 8; d++)
			{
				Vector2 q = p + Actor.AngleToVector(d * 45 + ring * 13) * (ring * 28);
				double qz = GroundZ(q, z, useHint);
				if (abs(qz - z) > 24 && useHint) continue;
				a = Put(cls, q, qz, ang);
				if (a) return a;
			}
		return null;
	}

	bool Safe(Vector2 p) { return !hasInsert || (p - insertPos).Length() >= SAFE_R; }

	// ---------------------------------------------------------------- the map
	// Door_Raise doors work as they are; let guards use them too. The level exit panels become scenery: missions
	// end at the extraction points (and the stairs between floors, Teleport_NewMap, stay).
	void Prep()
	{
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line ln = level.lines[i];
			switch (ln.special)
			{
			case 243: case 244: ln.special = 0; break;                   // Exit_Normal / Exit_Secret
			case 13:                                                     // Door_LockedRaise (tech maglock / key doors): unlocked, no keys in the pack yet
				ln.special = 12; ln.args[3] = 0;
				ln.flags |= Line.ML_MONSTERSCANACTIVATE;
				break;
			case 12: case 11: ln.flags |= Line.ML_MONSTERSCANACTIVATE; break;   // doors
			}
		}
	}

	// ---------------------------------------------------------------- entries, extraction
	void PlaceEntries()
	{
		hasInsert = false;
		if (insertIdx >= 0 && bld.eMap[insertIdx] == mapName) hasInsert = true;
		else
		{
			// a map opened on its own (debug, a saved game from an older pack): the first way in that is on this floor
			for (int i = 0; i < bld.eMap.Size() && !hasInsert; i++) if (bld.eMap[i] == mapName && bld.IsOutside(i)) { insertIdx = i; hasInsert = true; }
			for (int i = 0; i < bld.eMap.Size() && !hasInsert; i++) if (bld.eMap[i] == mapName) { insertIdx = i; hasInsert = true; }
		}
		if (hasInsert)
		{
			insertPos = (bld.eX[insertIdx], bld.eY[insertIdx]);
			insertZ = GroundZ(insertPos, bld.eZ[insertIdx], true);
			insertAng = bld.eAng[insertIdx];
			insertName = CW_SitePool.EntryTitle(bld, insertIdx);
		}
		for (int i = 0; i < bld.eMap.Size(); i++)
		{
			if (bld.eMap[i] != mapName) continue;
			Vector2 p = (bld.eX[i], bld.eY[i]);
			if (!bld.IsOutside(i)) { stX.Push(p.x); stY.Push(p.y); continue; }
			AddExtraction(p, GroundZ(p, bld.eZ[i], true));
		}
		for (int i = 0; i < bld.kMap.Size(); i++)
			if (bld.kMap[i] == mapName && bld.kType[i] == 31024) AddExtraction((bld.kX[i], bld.kY[i]), MarkerZ(i));
	}

	// Lines the player works with USE: doors, lifts, the stairs to another floor.
	static bool IsUseLine(Line ln)
	{
		switch (ln.special)
		{
		case 10: case 11: case 12: case 13: case 14:      // doors
		case 62: case 64: case 65:                         // lifts
		case 70: case 71: case 74:                         // teleports / the stairs to another map
		case 80: case 226:                                 // scripted panels
			return true;
		}
		return false;
	}

	// An extraction point sits where the building's entry is, and most entries are a door: 60 units from it in the
	// street layouts, inside the point's 72-unit zone. USE on that door then also counted as "leave the map".
	// So the point backs away from every door / lift line around it until its zone is clear of them (or the open
	// ground runs out). The insertion spot itself does not move.
	const EX_CLEAR = 128.0;     // CW_Extraction zone (72) + a body and a bit
	Vector2 ClearOfDoors(Vector2 p, double z)
	{
		for (int pass = 0; pass < 4; pass++)
		{
			double best = EX_CLEAR; Vector2 away = (0, 0);
			for (int i = 0; i < level.lines.Size(); i++)
			{
				Line ln = level.lines[i];
				if (!IsUseLine(ln)) continue;
				Vector2 a = ln.v1.p, d = ln.delta;
				double dd = d dot d;
				double t = dd > 0 ? clamp(((p - a) dot d) / dd, 0, 1) : 0;
				Vector2 c = a + d * t;
				double dist = (p - c).Length();
				if (dist >= best) continue;
				best = dist;
				if (dist > 1) away = (p - c) / dist;
				else { away = (d.y, -d.x); if (away.Length() > 0) away /= away.Length(); }
			}
			if (best >= EX_CLEAR || away.Length() < 0.5) break;
			// step away in small moves while the ground stays open, level and inside the map
			double want = EX_CLEAR - best + 4, went = 0;
			Vector2 q = p;
			while (went < want)
			{
				Vector2 n = q + away * 8;
				if (!level.IsPointInLevel((n, z + 24))) break;
				double nz = GroundZ(n, z, true);
				if (abs(nz - z) > 16) break;
				// geometry only: the player, the crate and bystanders stand around entries
				bool was = probe && probe.bThruActors;
				if (!probe) Fit(n, nz, 14, 48);
				if (probe) probe.bThruActors = true;
				bool ok = Fit(n, nz, 14, 48);
				if (probe) probe.bThruActors = was;
				if (!ok) break;
				q = n; went += 8;
			}
			if (went < 8) break;
			p = q;
		}
		return p;
	}

	void AddExtraction(Vector2 p, double z)
	{
		p = ClearOfDoors(p, z);
		z = GroundZ(p, z, true);
		for (int k = 0; k < exX.Size(); k++) if ((p - (exX[k], exY[k])).Length() < 96) return;
		exX.Push(p.x); exY.Push(p.y);
		Actor.Spawn("CW_Extraction", (p, z));
	}

	// the transport crate next to where the player comes in
	void PlaceCrate()
	{
		if (!hasInsert) return;
		let def = GetDefaultByType("CW_TransportAccess");
		for (int k = 0; k < 16; k++)
		{
			Vector2 p = insertPos + Actor.AngleToVector(insertAng + 90 + k * 30) * (56 + (k / 4) * 24);
			double z = GroundZ(p, insertZ, true);
			if (abs(z - insertZ) > 24) continue;
			if (Fit(p, z, def.radius + 4, def.height)) { Actor.Spawn("CW_TransportAccess", (p, z)); return; }
		}
	}

	// ---------------------------------------------------------------- objectives
	// Plan: for each kind, a marker of the whole building, far from the insertion and from the other objectives.
	// A pure function of (building, visit seed): every floor of the visit gets the same answer.
	void PlanObjectives()
	{
		Array<int> ob, ex;
		String mainMap = bld.mMap.Size() ? bld.mMap[0] : mapName;
		for (int i = 0; i < bld.kMap.Size(); i++)
		{
			if (bld.kType[i] == 31020) ob.Push(i);
			else if ((bld.kType[i] == 31022 || bld.kType[i] == 31021 || bld.kType[i] == 31023) && bld.kMap[i] == mainMap) ex.Push(i);
		}
		// a building with fewer than three objective spots lends its patrol / post spots
		Array<int> pool;
		for (int i = 0; i < ob.Size(); i++) pool.Push(ob[i]);
		if (ob.Size() < 3) for (int i = 0; i < ex.Size(); i++) pool.Push(ex[i]);
		if (!pool.Size()) return;
		int er = Hash2(bld.seed, visitSeed);
		Vector2 ep = insertIdx >= 0 ? (bld.eX[insertIdx], bld.eY[insertIdx]) : (0, 0);
		String em = insertIdx >= 0 ? bld.eMap[insertIdx] : "";
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int best = -1; double bs = -1e9;
			for (int c = 0; c < pool.Size(); c++)
			{
				int i = pool[c];
				double s = 0;
				er = er * 1103515245 + 12345;
				s += ((er >>> 16) & 0x7fff) % 60;
				if (bld.kType[i] == 31020) s += 100;
				for (int q = OBJ_STEAL; q < k; q++)
				{
					int j = objMk[q];
					if (j < 0) continue;
					if (j == i) s -= 1000;
					else if (bld.kMap[j] == bld.kMap[i] && ((bld.kX[i], bld.kY[i]) - (bld.kX[j], bld.kY[j])).Length() < 200) s -= 120;
				}
				if (bld.kMap[i] == em) s += min(((bld.kX[i], bld.kY[i]) - ep).Length(), 3000) / 40.0;
				else s += 40;
				if (s > bs) { bs = s; best = i; }
			}
			objMk[k] = best;
		}
	}
	int Hash2(int a, int b) { return abs(CW_Building.Mix(a, b & 0xffffff)); }

	void PlaceObjectives(CW_Ledger l)
	{
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int i = objMk[k];
			if (i < 0 || bld.kMap[i] != mapName) continue;
			if (l && (l.objDone & (1 << k))) continue;            // done on another floor visit: it stays done
			String cn = k == OBJ_STEAL ? "CW_Prototype" : (k == OBJ_DESTROY ? "CW_Server" : "CW_Scientist");
			Class<Actor> cls = cn;
			bool derived = bld.kNote[i].Length() && bld.kNote[i].ByteAt(0) == 126;
			Actor a = PutNear(cls, (bld.kX[i], bld.kY[i]), MarkerZ(i), !derived, Rand(0, 7) * 45);
			if (a) { objPlaced++; Console.Printf("\cfObjective %d at %s (%s)", k, bld.kNote[i].Length() ? bld.kNote[i] : "a marked spot", mapName); }
			else Console.Printf("\cgSites: objective %d has no room to stand at %d,%d on %s", k, bld.kX[i], bld.kY[i], mapName);
		}
	}

	// ---------------------------------------------------------------- people
	int SiteTarget()
	{
		int f = siteSet ? siteForce : 8;
		return clamp(4 + f * 55 / 100, 4, 12);
	}

	void Patrol(Array<double> px, Array<double> py, Array<double> pz, int wait)
	{
		if (px.Size() < 2) return;
		Array<int> tids;
		for (int k = 0; k < px.Size(); k++) tids.Push(level.FindUniqueTid());
		for (int k = 0; k < px.Size(); k++)
		{
			let pp = Actor.Spawn("CW_PatrolPoint", ((px[k], py[k]), pz[k]));
			if (!pp) continue;
			pp.ChangeTid(tids[k]);
			pp.args[0] = tids[(k + 1) % px.Size()];
			pp.args[1] = k == 0 || k == px.Size() / 2 ? wait * 2 : wait;
		}
		let g = CW_Guard(PutNear("CW_Guard", (px[0], py[0]), pz[0], true, 0));
		if (g) { g.args[0] = tids[1]; guards++; }
	}

	void Shuffle(Array<int> a)
	{
		for (int i = a.Size() - 1; i > 0; i--) { int j = Rand(0, i); int t = a[i]; a[i] = a[j]; a[j] = t; }
	}

	void PlaceGuards()
	{
		Array<int> gp, pp;
		for (int i = 0; i < bld.kMap.Size(); i++)
		{
			if (bld.kMap[i] != mapName) continue;
			if (bld.kType[i] == 31021) gp.Push(i);
			else if (bld.kType[i] == 31022) pp.Push(i);
		}
		int wt = gp.Size() + pp.Size();
		int totalW = bld.CountAll(31021) + bld.CountAll(31022);
		if (!wt || !totalW) return;
		int target = SiteTarget();
		int mine = clamp((target * wt + totalW - 1) / totalW, 1, wt);
		int patrolsWanted = max(1, mine * 55 / 100);
		// routes: chains of up to 4 patrol points, each point to its nearest unused neighbour
		Array<int> used;
		Shuffle(pp);
		for (int s = 0; s < pp.Size() && guards < patrolsWanted; s++)
		{
			int a = pp[s];
			if (used.Find(a) != used.Size()) continue;
			Array<double> px, py, pz;
			used.Push(a);
			int cur = a;
			px.Push(bld.kX[a]); py.Push(bld.kY[a]); pz.Push(MarkerZ(a));
			for (int len = 0; len < 3; len++)
			{
				int nb = -1; double bd = 1e9;
				for (int o = 0; o < pp.Size(); o++)
				{
					int b = pp[o];
					if (used.Find(b) != used.Size()) continue;
					double d = ((bld.kX[b], bld.kY[b]) - (bld.kX[cur], bld.kY[cur])).Length();
					if (d < bd && d < 1800) { bd = d; nb = b; }
				}
				if (nb < 0) break;
				used.Push(nb); cur = nb;
				px.Push(bld.kX[nb]); py.Push(bld.kY[nb]); pz.Push(MarkerZ(nb));
			}
			if (px.Size() < 2 || !Safe((px[0], py[0]))) continue;
			Patrol(px, py, pz, 35 + Rand(0, 2) * 35);
		}
		// posts: the guard markers, then spare patrol points
		Array<int> posts;
		Shuffle(gp);
		for (int i = 0; i < gp.Size(); i++) posts.Push(gp[i]);
		for (int i = 0; i < pp.Size(); i++) if (used.Find(pp[i]) == used.Size()) posts.Push(pp[i]);
		for (int n = 0; n < posts.Size() && guards < mine; n++)
		{
			int i = posts[n];
			Vector2 p = (bld.kX[i], bld.kY[i]);
			if (!Safe(p)) continue;
			if (PutNear("CW_Guard", p, MarkerZ(i), true, Rand(0, 7) * 45)) guards++;
		}
		// one of them runs the shift (once per building: on the floor with most guard spots)
		if (floorIdx == SupervisorFloor())
		{
			Array<CW_Guard> gs;
			let it = ThinkerIterator.Create("CW_Guard");
			CW_Guard g;
			while (g = CW_Guard(it.Next())) gs.Push(g);
			if (gs.Size())
			{
				let o = gs[Rand(0, gs.Size() - 1)];
				let sv = CW_Guard(Actor.Spawn("CW_SecuritySupervisor", o.pos));
				if (sv) { sv.angle = o.angle; sv.args[0] = o.args[0]; o.Destroy(); }
			}
		}
		double sight = !siteSet ? 1.0 : (siteTech >= 4 ? 1.12 : (siteTech <= 1 ? 0.9 : 1.0));
		let it2 = ThinkerIterator.Create("CW_Guard");
		CW_Guard g2;
		while (g2 = CW_Guard(it2.Next())) g2.sightRange *= sight;
	}
	int SupervisorFloor()
	{
		int best = 0, bn = -1;
		for (int f = 0; f < bld.mMap.Size(); f++)
		{
			int n = bld.CountOn(bld.mMap[f], 31021) + bld.CountOn(bld.mMap[f], 31022);
			if (n > bn) { bn = n; best = f; }
		}
		return best;
	}

	void PlaceBystanders()
	{
		Array<int> bs;
		for (int i = 0; i < bld.kMap.Size(); i++) if (bld.kMap[i] == mapName && bld.kType[i] == 31023) bs.Push(i);
		int all = bld.CountAll(31023);
		if (!bs.Size() || !all) return;
		int want = neutralSite || !siteSet ? 5 : 3;
		int mine = clamp((want * bs.Size() + all - 1) / all, 1, bs.Size());
		Shuffle(bs);
		for (int n = 0; n < bs.Size() && civs < mine; n++)
		{
			int i = bs[n];
			Vector2 p = (bld.kX[i], bld.kY[i]);
			if (hasInsert && (p - insertPos).Length() < 200) continue;
			if (PutNear("CW_Civilian", p, MarkerZ(i), true, Rand(0, 7) * 45)) civs++;
		}
	}

	// ---------------------------------------------------------------- the pipeline
	void Generate(CW_Ledger l, bool fresh)
	{
		Prep();
		PlaceEntries();
		if (!fresh) hasInsert = false;      // arrived by the stairs: nobody is inserted here, the way in is behind you
		if (fresh) PlaceCrate();
		if (missionOn) { PlanObjectives(); PlaceObjectives(l); }
		PlaceGuards();
		PlaceBystanders();
		if (probe) { probe.Destroy(); probe = null; }
		Console.Printf("Site %s (%s #%d, %s): seed %d, floor %d of %d, %d guards, %d bystanders, %d objectives, %d extraction points%s",
			mapName, bld.code, bld.variant, siteName, bld.seed, floorIdx + 1, bld.mMap.Size(), guards, civs, objPlaced, exX.Size(), fresh ? "; in by " .. insertName : "");
		Console.Printf("SITEQA %s fresh %d mission %d guards %d civs %d obj %d ex %d stairs %d", mapName, fresh, missionOn, guards, civs, objPlaced, exX.Size(), stX.Size());
	}

	// the player fits where it stands and can take a step in most directions
	static bool CanMove(PlayerPawn pm)
	{
		if (!pm.CheckPosition(pm.pos.xy)) return false;
		if (pm.ceilingz - pm.floorz < pm.height) return false;
		int open = 0;
		for (int d = 0; d < 8; d++) if (pm.CheckMove(pm.pos.xy + Actor.AngleToVector(d * 45) * 24)) open++;
		return open >= 3;
	}

	void Insert(PlayerPawn pm, bool fresh)
	{
		if (!pm || !fresh || insertIdx < 0) return;
		pm.TakeInventory("CW_SecurityPass", 99);
		let l = CW_Ledger.Of(pm);
		if (l) { l.passMask = 0; l.arriveTower = -1; }
		pm.SetOrigin((insertPos, insertZ), false);
		pm.angle = insertAng;
		if (!CanMove(pm))
		{
			bool ok = false;
			for (int e = 0; e < bld.eMap.Size() && !ok; e++)
			{
				if (bld.eMap[e] != mapName || !bld.IsOutside(e)) continue;
				Vector2 q = (bld.eX[e], bld.eY[e]);
				pm.SetOrigin((q, GroundZ(q, bld.eZ[e], true)), false);
				if (CanMove(pm)) { ok = true; insertName = CW_SitePool.EntryTitle(bld, e); pm.angle = bld.eAng[e]; }
			}
			for (int ring = 1; ring <= 8 && !ok; ring++)
				for (int d = 0; d < 8 && !ok; d++)
				{
					Vector2 q = insertPos + Actor.AngleToVector(d * 45) * (ring * 24);
					pm.SetOrigin((q, GroundZ(q, insertZ, true)), false);
					if (CanMove(pm)) ok = true;
				}
			Console.Printf("SITEQA insert %s", ok ? "fixed at spawn" : "STUCK");
			if (!ok) pm.SetOrigin((insertPos, insertZ), false);
		}
		String site = siteName.Length() ? siteName : bld.title;
		pm.A_Print(String.Format("\cg%s\n\cj%s\n\cjInsertion: %s\n\cdExtraction: any way out you came in by", site.MakeUpper(), CW_SitePool.PoolTitle(bld.code), insertName), 6);
	}

	// ---------------------------------------------------------------- debug (netevent cw_sitego <pool> <variant> <job>)
	// Walk into pool <pool> (1-based, see cw_sitelist) variant <variant> as a visit, or with job=1 borrow the first job on the
	// board and run it on that map.
	static void GoSite(CW_Ledger l, int poolIdx, int variant, bool withJob)
	{
		if (!l || l.missionActive) { Console.Printf("CW_SITEGO: finish the running mission first"); return; }
		String code = CW_SitePool.CodeAt(poolIdx - 1);
		if (!code.Length()) { Console.Printf("CW_SITEGO: no pool %d (cw_sitelist)", poolIdx); return; }
		int n = CW_SitePool.PoolCount(code);
		String m = String.Format("S%s%02dA", code, clamp(variant, 1, max(n, 1)));
		if (!LevelInfo.MapExists(m)) { Console.Printf("CW_SITEGO: %s is not in the loaded pack", m); return; }
		let lk = CW_CityLink.Get();
		if (withJob)
		{
			if (!l.city) { Console.Printf("CW_SITEGO: no city yet"); return; }
			for (int j = 0; j < l.OfferCount(); j++)
			{
				let o = l.Offer(j);
				if (o.refused.Length()) continue;
				o.map = m; o.kitVariant = 0; o.floors = 1; o.garageOk = false; o.cost = 0;
				Console.Printf("CW_SITEGO job on %s: %s", m, o.target);
				l.selected = j;
				l.BeginMission();
				return;
			}
			Console.Printf("CW_SITEGO: no job on the board");
			return;
		}
		if (lk) { lk.visit = true; lk.visitName = CW_SitePool.Describe(m); lk.visitDist = 0; lk.visitLot = 0; lk.kitSeed = 0; lk.g02Seed = 0; lk.siteBld = ""; lk.siteTok = 0; }
		l.job = null;
		Console.Printf("CW_SITEGO walk-in %s", m);
		level.ChangeLevel(CW_SitePool.LaunchMap(m, 0, 2), 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}
}
