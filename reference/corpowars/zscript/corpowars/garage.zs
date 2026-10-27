// =============================================================================
// Corpo Wars — parking garage (G05, level B1) + heat + extraction scenarios
//
// The garage is part of the building's hub (cluster 20): it keeps its state between visits.
//   * Garage insertion (a share of tower contracts): you start at your van; the lift up leads to the insertion
//     floor (G02). Every exit in the building then brings you back down here, and the job ends at the van.
//   * Rerouted extraction: on a normal insertion, a hot run can be rerouted here ("your exit is burned, the
//     van's in the garage"), with the chance driven by heat.
//   * Scenario roll: the first time you come down with the primary done, heat decides who is waiting:
//     QUIET (nobody new), PATROL (two guards walking the aisles), CHECKPOINT (guards posted at the lift mouth),
//     AMBUSH (a squad crouched by your van, already on edge).
// Geometry comes from genmap.build_garage (keep GARAGE_* in sync). Cars: Voxel Vehicles Pack (NerdKoopa).
// =============================================================================
class CW_GarageGen play
{
	const GW = 1792;  const GH = 1280;
	const LX0 = 768;  const LX1 = 1024;  const LY1 = 1440;

	enum EScenario { SC_NONE = -1, SC_QUIET, SC_PATROL, SC_CHECKPOINT, SC_AMBUSH }

	int rng;
	Vector2 vanPos; double vanAng;
	CW_StairDoor lift;
	int guards;

	int Rand(int a, int b) { rng = (rng * 1103515245 + 12345) & 0x7fffffff; return a + (rng >> 8) % (b - a + 1); }

	static clearscope String ScenarioName(int sc)
	{
		switch (sc)
		{
		case SC_QUIET:      return "quiet garage";
		case SC_PATROL:     return "garage patrol";
		case SC_CHECKPOINT: return "garage checkpoint";
		case SC_AMBUSH:     return "garage ambush";
		}
		return "none";
	}

	// Heat -> scenario, with some luck either way.
	static int PickScenario(int heat, bool rerouted)
	{
		int r = heat + Random(-15, 15);
		int sc = r < 20 ? SC_QUIET : r < 45 ? SC_PATROL : r < 70 ? SC_CHECKPOINT : SC_AMBUSH;
		if (rerouted && sc == SC_QUIET) sc = SC_PATROL;   // you were rerouted because someone's looking for you
		return sc;
	}

	void Generate(int seed, bool insertion, CW_Ledger l, int risk, int insertFloor)
	{
		rng = seed ^ 0x5a17;
		static const double ROWY[] = { 150, 560, 720, 1130 };
		static const double ROWA[] = { 90, 270, 90, 270 };
		static const String CARS[] = { "ModernCarRed", "ModernCarDarkRed", "ModernCarBlue", "ModernCarDarkBlue", "ModernCarGreen",
			"ModernCarOrange", "ModernCarBrown", "HatchBackRed", "HatchBackBlue", "HatchBackDarkBlue", "HatchBackBrown",
			"PickupWhite", "PickupDarkBlue", "PickupBrown", "VanWhite", "VanDarkRed", "ModernTaxi" };
		// our van: a south-row bay, away from the lift
		int vanSlot = Rand(1, 10);
		for (int row = 0; row < 4; row++)
			for (int s = 0; s < 12; s++)
			{
				double x = 176 + s * 130;
				if (row == 3 && x > LX0 - 80 && x < LX1 + 80) continue;   // keep the lift mouth clear
				bool ours = row == 0 && s == vanSlot;
				if (!ours && Rand(0, 99) >= 58) continue;
				String cls = ours ? "VanDarkBlue" : CARS[Rand(0, CARS.Size() - 1)];
				Vector2 p = (x, ROWY[row]);
				let car = Actor.Spawn(cls, (p, 0));
				if (!car) continue;
				car.angle = ROWA[row];   // voxel nose points along the actor angle: nose into the bay
				// the pack's collision is only the car's middle: block the nose and tail too
				Vector2 ax = Actor.AngleToVector(ROWA[row]);
				for (int k = -1; k <= 1; k += 2) { let b = Actor.Spawn("CW_Blocker", (p + ax * 40 * k, 0)); if (b) b.A_SetSize(20, 44); }
				if (ours) { vanPos = p; vanAng = ROWA[row]; }
			}
		// the job ends here: beside the van's side door; resupply crate at its tail
		Vector2 side = Actor.AngleToVector(vanAng + 90);
		Actor.Spawn("CW_Extraction", (vanPos + side * 56, 0));
		Actor.Spawn("CW_TransportAccess", (vanPos - Actor.AngleToVector(vanAng) * 90 + side * 30, 0));
		// light: sodium battens along the aisles, bright lift lobby
		static const double LY[] = { 300, 640, 980 };   // over the aisles and the middle rows, clear of the pillar lines
		for (int x = 128; x < GW; x += 256)
			for (int y = 0; y < 3; y++)
				CW_LightSource.Make((x, LY[y], 100), 255, 190, 120, 190);
		CW_LightSource.Make(((LX0 + LX1) / 2, 1360, 100), 230, 236, 250, 176);
		// the lift up to the insertion floor
		lift = CW_StairDoor(Actor.Spawn("CW_StairDoor", (((LX0 + LX1) / 2, LY1 - 14), 0)));
		if (lift)
		{
			lift.A_SetSize(24, 72);
			lift.elevator = true;
			lift.targetMap = "G02";
			lift.tower = 2;
			lift.label = insertFloor > 0 ? String.Format("up to floor %d", insertFloor) : "up to the office floor";
		}
		if (insertion)
		{
			// a garage at night: a few staff heading home, a guard doing rounds, sometimes one at the lift
			int civs = Rand(2, 4);
			for (int k = 0; k < civs; k++) PutCivilian();
			AislePatrol(Rand(0, 1));
			if (risk >= 2 || Rand(0, 1)) Post(((LX0 + LX1) / 2 + Rand(-60, 60), GH - 60), 270);
		}
		Console.Printf("\cfGarage generated: %d guards", guards);
	}

	void PutCivilian()
	{
		for (int tries = 0; tries < 12; tries++)
		{
			Vector2 p = (Rand(200, GW - 200), Rand(0, 1) ? Rand(300, 470) : Rand(810, 980));
			if ((p - vanPos).Length() < 300) continue;
			let c = Actor.Spawn("CW_Civilian", (p, 0));
			if (c) { c.angle = Rand(0, 3) * 90; return; }
		}
	}

	// A guard walking one aisle end to end (aisle 0: y 400, aisle 1: y 880).
	void AislePatrol(int aisle)
	{
		double y = aisle == 0 ? 440 : 850;
		Array<double> px, py;
		px.Push(160); py.Push(y); px.Push(GW - 160); py.Push(y);
		px.Push(GW - 160); py.Push(aisle == 0 ? 850 : 440); px.Push(160); py.Push(aisle == 0 ? 850 : 440);
		Array<int> tids;
		for (int k = 0; k < px.Size(); k++) tids.Push(level.FindUniqueTid());
		for (int k = 0; k < px.Size(); k++)
		{
			let pp = Actor.Spawn("CW_PatrolPoint", (px[k], py[k], 0));
			pp.ChangeTid(tids[k]);
			pp.args[0] = tids[(k + 1) % tids.Size()];
			pp.args[1] = 70;
		}
		int start = Rand(0, px.Size() - 1);
		let g = CW_Guard(Actor.Spawn("CW_Guard", (px[start], py[start], 0)));
		if (g) { g.args[0] = tids[(start + 1) % tids.Size()]; guards++; }
	}

	CW_Guard Post(Vector2 p, double ang, bool boss = false)
	{
		let g = CW_Guard(Actor.Spawn(boss ? "CW_SecuritySupervisor" : "CW_Guard", (p, 0)));
		if (g) { g.angle = ang; guards++; }
		return g;
	}

	// Who's waiting on the way out.
	void SpawnScenario(int sc)
	{
		Vector2 liftMouth = ((LX0 + LX1) / 2, GH - 80);
		switch (sc)
		{
		case SC_PATROL:
			AislePatrol(0); AislePatrol(1);
			break;
		case SC_CHECKPOINT:
			Post(liftMouth + (-90, -40), 90);
			Post(liftMouth + (90, -40), 90, true);
			AislePatrol(Rand(0, 1));
			break;
		case SC_AMBUSH:
		{
			// crouched behind the cars around the van, watching the lift, already on edge
			Vector2 toLift = liftMouth - vanPos;
			double a = VectorAngle(toLift.x, toLift.y);
			static const double OX[] = { -180, 180, -90, 110, 0 };
			static const double OY[] = { 150, 150, 260, 280, 340 };
			for (int k = 0; k < 5; k++)
			{
				let g = Post(vanPos + (OX[k], OY[k]), a + Rand(-20, 20), k == 4);
				if (g) { g.cautious = true; g.suspicion = 40; }
			}
			break;
		}
		}
	}

	// Mission start at the van.
	void Insert(PlayerPawn pm)
	{
		if (!pm) return;
		pm.TakeInventory("CW_SecurityPass", 99);
		let l = CW_Ledger.Of(pm);
		if (l) { l.passMask = 0; l.arriveTower = -1; }
		Vector2 p = vanPos + Actor.AngleToVector(vanAng + 90) * 56 + Actor.AngleToVector(vanAng) * 30;
		pm.SetOrigin((p, 0), false);
		Vector2 d = ((LX0 + LX1) / 2, GH) - p;
		pm.angle = VectorAngle(d.x, d.y);
		pm.A_Print("\cfPARKING GARAGE  -  LEVEL B1\n\cjThe lift goes up to the office floor.\n\cdYour van is the way out: every exit up there brings you back here.", 6);
	}

	// Coming down the lift.
	void Arrive(PlayerPawn pm)
	{
		if (!pm) return;
		pm.SetOrigin((((LX0 + LX1) / 2, 1370), 0), false);
		pm.angle = 270;
		pm.vel = (0, 0, 0);
	}
}
