// The roof (PLAN.md §4.4, §6.7, M2c): the top of a tower in the Bricks, and the roofs around it.
//
// Template NBC_KR (tools/make_kit_maps.py): 14 x 9 cells of 160 (4.3 m). The roof is open sky over a 768-unit
// drop to the street; its edges block. Huts and the machine room are small indoor rooms (ceiling 88-96).
//
// Variants:
//   tower roof         one big roof: two stair huts, the lift machine room, water tanks, AC plant
//   rooftop crossing   this roof, a gap down to the street, plank bridges across it, the next tower's roof
//   roof camp          the roof taken over: plank shacks, mattresses, a sandbagged lookout over the street
class NBC_KitRoof : NBC_KitGen
{
	enum EVar { V_TOWER, V_CROSSING, V_CAMP, V_COUNT }
	enum ERoom { R_ROOF, R_NEXT, R_DROP, R_BRIDGE, R_HUT, R_MACHINE, R_SHACK, R_LOOKOUT, R_TANKS }
	const GAP = 9;                // the crossing's gap column

	int roof, next;           // the two roof rooms (next = -1 without a crossing)

	override void Setup()
	{
		for (int i = 0; i < 14; i++) colw.Push(160);
		for (int j = 0; j < 9; j++) rowh.Push(160);
		Grid(14, 9);
		doorTex = "CWDOORF"; jambTex = "SUPPORT3"; edgeTex = "ADBRICK";
	}
	override bool EdgeOpen(int r) { return IsOut(r); }
	override String EdgeRail(int r) { return "CWRAIL2"; }
	override double FenceH(int a, int b) { return 36; }     // rails at the gap's edge: 1.1 m, and they block
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "tower roof", "rooftop crossing", "roof camp" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 1, 1, 4 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		switch (t)
		{
		case R_ROOF:    return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 120, "FLAT5_5", "F_SKY1", "ADBRICK", "the roof");
		case R_NEXT:    return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 16, 0, 112, "FLOOR6_2", "F_SKY1", "BRICK12", "the next roof");
		case R_DROP:    return Room(t, RF_OUT | RF_WATER | RF_NOGUARD, -768, 0, 88, "CWASPH", "F_SKY1", "ADBRICK", "the drop");
		case R_BRIDGE:  return Room(t, RF_OUT | RF_NOGUARD, 8, 0, 96, "FLOOR4_1", "F_SKY1", "CWPLANK", "a plank bridge");
		case R_HUT:     return Room(t, RF_NOGUARD, 0, 88, 112, "CWSTAIF", "ADFLUOR", "ADBRICK", "the stair hut");
		case R_MACHINE: return Room(t, RF_TECH | RF_PATROL, 0, 96, 96, "CWCONCF", "ADFLUOR", "SUPPORT3", "the lift machine room");
		case R_SHACK:   return Room(t, RF_PEOPLE | RF_CIV | RF_RUBBLE, 0, 80, 72, "FLOOR4_1", "ADFLUOR", "CWPLANK", "a shack");
		case R_LOOKOUT: return Room(t, RF_OUT | RF_PEOPLE | RF_PATROL | RF_RUBBLE, 0, 0, 120, "FLAT5_5", "F_SKY1", "ADBRICK", "the lookout");
		case R_TANKS:   return Room(t, RF_OUT | RF_TECH, 0, 0, 120, "FLAT5_5", "F_SKY1", "ADBRICK", "the water tanks");
		}
		return Room(t, RF_OUT, 0, 0, 96, "FLAT5_5", "F_SKY1", "ADBRICK", "the roof");
	}

	// ---------------------------------------------------------------- layout
	override void Layout()
	{
		next = -1;
		roof = MakeRoom(R_ROOF);
		int east = variant == V_CROSSING ? GAP - 1 : NX - 1;
		Rect(roof, 0, 0, east, NY - 1);
		// the stair hut this floor's stairs come up into, the lift machine room, the tank stand: each on open roof
		int i, j;
		if (FreeSpot(1, 2, 1, NY - 3, 1, 2, i, j)) Hut(i, j, "the stair hut", EK_FRONT);
		if (FreeSpot(4, east - 2, 4, NY - 2, 2, 1, i, j)) Machine(i, j);
		if (FreeSpot(4, east - 2, 1, 2, 2, 1, i, j)) Tanks(i, j);
		if (variant == V_CROSSING) Crossing();
		else if (FreeSpot(east - 2, east - 1, 2, NY - 3, 1, 2, i, j)) Hut(i, j, "the far stair hut", EK_BACK);
		if (variant == V_CAMP) Camp(east);
		// the fire escape comes up over the parapet in a corner
		AddEntry(CellCenter(0, NY - 1) + (-40, 40), 315, "the fire escape", EK_ROOF, roof);
	}

	// A w x h block of open roof (and open roof all round it) with its corner in [i0, i1] x [j0, j1].
	bool FreeSpot(int i0, int i1, int j0, int j1, int w, int h, out int fi, out int fj)
	{
		for (int tries = 0; tries < 30; tries++)
		{
			int i = Rand(i0, max(i0, i1)), j = Rand(j0, max(j0, j1));
			bool ok = true;
			for (int y = j - 1; y <= j + h && ok; y++)
				for (int x = i - 1; x <= i + w && ok; x++)
				{
					bool inside = x >= i && x < i + w && y >= j && y < j + h;
					int r = At(x, y);
					if (inside && r != roof && r != next) ok = false;
					if (!inside && r >= 0 && r != roof && r != next) ok = false;
				}
			if (ok) { fi = i; fj = j; return true; }
		}
		return false;
	}

	// a stair hut over cells (i, j) and (i, j + 1), its door facing east
	void Hut(int i, int j, String name, int kind)
	{
		int hut = MakeRoom(R_HUT); rName[hut] = name;
		int base = At(i, j);
		Claim(hut, i, j); Claim(hut, i, j + 1);
		rF[hut] = base >= 0 ? rF[base] : 0;
		if (!LinkRooms(hut, base >= 0 ? base : roof, E_DOOR, CellCenter(i + 1, j))) LinkRooms(hut, roof, E_DOOR);
		AddEntry(CellCenter(i, j), 0, name, kind, hut);
	}

	void Machine(int i, int j)
	{
		int m = MakeRoom(R_MACHINE);
		Claim(m, i, j); Claim(m, i + 1, j);
		LinkRooms(m, roof, E_DOOR, CellCenter(i, j - 1));
		AddEntry(CellCenter(i + 1, j), 180, "the lift shaft hatch", EK_SERVICE, m);
	}

	// a raised tank stand: walk round it, not through it
	void Tanks(int i, int j)
	{
		int t = MakeRoom(R_TANKS);
		Claim(t, i, j); Claim(t, i + 1, j);
		LinkAll(t, roof, E_WIDE);
	}

	// the gap down to the street, one or two plank bridges, and the neighbouring tower's roof
	void Crossing()
	{
		int drop = MakeRoom(R_DROP); Rect(drop, GAP, 0, GAP, NY - 1);
		next = MakeRoom(R_NEXT); Rect(next, GAP + 1, 0, NX - 1, NY - 1);
		int b0 = Rand(1, NY - 2);
		Bridge(b0);
		if (Chance(60)) { int b1 = (b0 + Rand(3, 5)) % NY; if (abs(b1 - b0) > 1) Bridge(b1); }
		LinkAll(drop, roof, E_FENCE);
		LinkAll(drop, next, E_FENCE);
		int i, j;
		if (FreeSpot(NX - 2, NX - 2, 1, NY - 3, 1, 2, i, j)) Hut(i, j, "the next tower's stairs", EK_BACK);
	}

	void Bridge(int j)
	{
		int br = MakeRoom(R_BRIDGE);
		Claim(br, GAP, j);
		Link(GAP, j, GAP - 1, j, E_WIDE);
		Link(GAP, j, GAP + 1, j, E_WIDE);
	}

	// the camp: shacks of planks along the north edge, a sandbagged lookout over the street at the south edge
	void Camp(int east)
	{
		int n = 0;
		for (int i = 3; i <= east - 2 && n < 4; i += Rand(2, 3))
		{
			if (At(i, NY - 1) != roof) continue;
			int s = MakeRoom(R_SHACK);
			Claim(s, i, NY - 1);
			LinkRooms(s, roof, Chance(50) ? E_DOOR : E_ARCH);
			n++;
		}
		int li, lj;
		if (!FreeSpot(3, east - 3, 0, 0, 2, 1, li, lj)) return;
		int lo = MakeRoom(R_LOOKOUT);
		Rect(lo, li, 0, li + 1, 0);
		LinkAll(lo, roof, E_WIDE);
	}

	// ---------------------------------------------------------------- objectives, light, dressing
	override int ObjScore(int r, int k)
	{
		if (Has(r, RF_WATER) || IsType(r, R_BRIDGE) || IsType(r, R_HUT)) return 0;
		if (k == OBJ_STEAL && IsType(r, R_SHACK)) return 140;
		if (k == OBJ_DESTROY && (IsType(r, R_MACHINE) || IsType(r, R_TANKS))) return 150;
		if (k == OBJ_TURN && (IsType(r, R_LOOKOUT) || IsType(r, R_SHACK))) return 140;
		// outdoor roofs are fine for objectives here (most of the map is roof)
		if (k == OBJ_STEAL) return Has(r, RF_VALUE) ? 60 : 10;
		return 10;
	}

	override int LampStyle(int r) { return 2; }

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case R_ROOF: case R_NEXT:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 14) PutInCell("CW_FAcUnit", ci[k], cj[k], 90 * Rand(0, 3));
				else if (roll < 22) PutInCell("CW_FPipes", ci[k], cj[k], 90 * Rand(0, 1));
				else if (roll < 27) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
				else if (roll < 30 && variant == V_CAMP) PutInCell("CW_FBed", ci[k], cj[k], 90 * Rand(0, 3));
			}
			break;
		case R_TANKS:
			for (int k = 0; k < ci.Size(); k++) PutInCell("CW_FWaterTower", ci[k], cj[k]);
			break;
		case R_MACHINE:
			LineWalls("CW_FGenerator", r, 140, 2); LineWalls("CW_FTransformer", r, 140, 1); LineWalls("CW_FPipes", r, 160, 2);
			break;
		case R_SHACK:
			PutInRoom("CW_FBed", r); if (Chance(60)) PutInRoom("CW_FCrates", r); if (Chance(40)) PutInRoom("CW_FScrap", r);
			break;
		case R_LOOKOUT:
			for (int k = 0; k < ci.Size(); k++) PutWall("CW_FSandbags", ci[k], cj[k], 3, Rand(-20, 20));
			PutInRoom("CW_FArmchair", r, 270); PutInRoom("CW_FCrates", r);
			break;
		}
	}

	override void Outdoors()
	{
		// work lamps over the hut and machine-room doors
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (IsOut(r) || !CellCount(r)) continue;
			Vector2 c = RoomCenter(r);
			NBC_LightSource.Make((c, rF[r] + 104), 255, 200, 140, 200);
		}
	}
}
