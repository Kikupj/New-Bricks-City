// Ported from Corpo Wars (reference/corpowars/zscript/corpowars/kit_residential.zs) for PLAN.md M2b.
// NBC: renamed to NBC_ because the mission layer is cut and the look is rebuilt for the Bricks.
// =============================================================================
// Corpo Wars — K02 residential kit: one floor of a tenement, apartment block, luxury tower or hotel;
// NullSet's hacker dens; and the rooftops above them.
// NBC: the Bricks' tower floor. Ceilings raised to the PLAN.md §4.4 scale, the den is a gang den with a stash
// room, poor floors have squats and rubble, and fire escapes and roofs carry loose debris.
//
//   row 6  rear fire escape / light well (outdoor, partly)
//   rows 4-5  flats (north)
//   row 3  corridor, a stair core at each end (columns 0 and 11), the elevator off it
//   rows 1-2  flats (south)
//   row 0  front fire escape (outdoor)
// Grid: columns 128, 10 x 176, 128; rows 96, 176, 176, 112, 176, 176, 96 (genmap KIT_GRIDS["K02"]).
// =============================================================================
class NBC_KitResidential : NBC_KitGen
{
	enum EVar { V_TENEMENT, V_APARTMENTS, V_LUXURY, V_HOTEL, V_DEN, V_ROOFTOPS, V_COUNT }
	enum ERoom
	{
		H_CORR, H_STAIR, H_ELEV, H_ESCAPE, H_LIVING, H_KITCHEN, H_BED, H_BATH, H_HOTELROOM, H_LINEN, H_UTILITY,
		H_DEN, H_SERVER, H_CONCIERGE, H_TERRACE, H_ROOF, H_HUT, H_STUDY
	}
	const ROW_SOUTH = 0;
	const ROW_CORR = 3;
	const ROW_NORTH = 6;
	const COL_W = 0;
	const COL_E = 11;

	int corrR;

	override void Setup()
	{
		static const int CW[] = { 128, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 128 };
		static const int RW[] = { 96, 176, 176, 112, 176, 176, 96 };
		for (int i = 0; i < CW.Size(); i++) colw.Push(CW[i]);
		for (int j = 0; j < RW.Size(); j++) rowh.Push(RW[j]);
		Grid(CW.Size(), RW.Size());
		doorTex = "CWDOOR1"; jambTex = "CWTRIM"; edgeTex = "BRICK1";
	}
	override int VariantCount() { return V_COUNT; }
	override bool EdgeOpen(int r) { return true; }
	override String VariantName()
	{
		static const String n[] = { "tenement", "apartment block", "luxury apartments", "hotel", "gang den", "rooftops" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 7, 6, 4, 6, 3, 1 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		bool lux = variant == V_LUXURY, poor = variant == V_TENEMENT || variant == V_DEN;
		String wall = lux ? "AXCITY17" : (poor ? "AXDU06" : "CWWALL1");
		String flo = lux ? "AXF48" : (poor ? "FLOOR4_1" : "CWCARP1");
		switch (t)
		{
		case H_CORR:      return Room(t, RF_PATROL | (poor ? RF_RUBBLE : 0), 0, 120, poor ? 112 : 150, poor ? "FLAT5_5" : (lux ? "ADFMARB" : "CWCARP2"), "CEIL1_1", poor ? "AXDU06A" : wall, "the hallway");
		case H_STAIR:     return Room(t, RF_NOGUARD, 0, 128, 120, "CWSTAIF", "CWCEILD", "ADCONC1", "the stairwell");
		case H_ELEV:      return Room(t, RF_NOGUARD, 0, 112, 160, "ADFMARB", "CWCEILL", "ADELEV2", "the elevator");
		case H_ESCAPE:    return Room(t, RF_OUT | RF_RUBBLE, 0, 0, 96, "FCGRATE1", "F_SKY1", poor ? "BRICK1" : "BRICK12", "the fire escape");
		case H_LIVING:    return Room(t, RF_CIV | RF_PEOPLE, 0, 128, 136, flo, "CEIL1_1", wall, "living room");
		case H_KITCHEN:   return Room(t, RF_CIV, 0, 120, 150, "CWTILEF", "CEIL1_1", "CWTILEW", "kitchen");
		case H_BED:       return Room(t, RF_VALUE, 0, 120, 112, flo, "CEIL1_1", wall, "bedroom");
		case H_BATH:      return Room(t, 0, 0, 112, 150, "CWTILEF", "CEIL1_1", "CWTILEW", "bathroom");
		case H_HOTELROOM: return Room(t, RF_CIV | RF_VALUE, 0, 120, 128, "CWCARP3", "CEIL1_1", "AXDW07A", "guest room");
		case H_LINEN:     return Room(t, RF_CIV, 0, 120, 136, "FLOOR4_8", "CEIL1_1", "CEMENT7", "housekeeping");
		case H_UTILITY:   return Room(t, RF_TECH | RF_RUBBLE, 0, 120, 104, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the utility room");
		case H_DEN:       return Room(t, RF_PEOPLE | RF_PATROL | RF_RUBBLE, 0, 128, 96, "FLOOR4_1", "CEIL1_1", "AXDU06", "the gang den");
		case H_SERVER:    return Room(t, RF_TECH | RF_VALUE, 0, 120, 88, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the stash room");
		case H_CONCIERGE: return Room(t, RF_PEOPLE | RF_PATROL, 0, 144, 176, "ADFMARB", "CWCEILL", "AXCITY17", "the concierge desk");
		case H_TERRACE:   return Room(t, RF_OUT | RF_CIV, 0, 0, 104, "AXF46", "F_SKY1", "AXCITY17", "the roof terrace");
		case H_ROOF:      return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 96, "FLAT5_5", "F_SKY1", "BRICK1", "a roof");
		case H_HUT:       return Room(t, RF_TECH | RF_RUBBLE, 0, 120, 112, "FLOOR4_8", "CEIL1_1", "CEMENT7", "a stair hut");
		case H_STUDY:     return Room(t, RF_VALUE | RF_PEOPLE, 0, 128, 136, "AXF48", "CEIL1_1", "AXDW07B", "the study");
		}
		return Room(t, 0, 0, 120, 128, flo, "CEIL1_1", wall, "room");
	}

	override void Layout()
	{
		if (variant == V_ROOFTOPS) { Rooftops(); return; }
		corrR = MakeRoom(H_CORR);
		Rect(corrR, 1, ROW_CORR, NX - 2, ROW_CORR);
		// stair cores at both ends of the corridor
		int sw = MakeRoom(H_STAIR), se = MakeRoom(H_STAIR);
		Rect(sw, COL_W, 2, COL_W, 4); Rect(se, COL_E, 2, COL_E, 4);
		Link(COL_W, ROW_CORR, 1, ROW_CORR, E_DOOR); Link(COL_E, ROW_CORR, COL_E - 1, ROW_CORR, E_DOOR);
		AddEntry(CellCenter(COL_W, 3), 0, "the main stairs", EK_FRONT);
		AddEntry(CellCenter(COL_E, 3), 180, "the back stairs", EK_BACK);
		// the front fire escape runs the whole south side; the rear one only part of the north side
		int fe = MakeRoom(H_ESCAPE);
		Rect(fe, 1, ROW_SOUTH, NX - 2, ROW_SOUTH);
		int re = MakeRoom(H_ESCAPE);
		int r0 = Rand(1, 4), r1 = r0 + Rand(3, 5);
		Rect(re, r0, ROW_NORTH, min(r1, NX - 2), ROW_NORTH);
		AddEntry(CellCenter(1, ROW_SOUTH) + (0, -10), 0, "the fire escape", EK_ROOF);
		// the elevator (not in tenements)
		int ec = Rand(4, 7);
		if (variant != V_TENEMENT && variant != V_DEN)
		{
			int el = MakeRoom(H_ELEV);
			Claim(el, ec, 4);
			Link(ec, 4, ec, ROW_CORR, E_DOOR);
			AddEntry(CellCenter(ec, 4), 270, "the elevator", EK_SERVICE);
		}
		// the flats on each side
		for (int side = 0; side < 2; side++)
		{
			int near = side ? 4 : 2, far = side ? 5 : 1;
			int c = 1;
			while (c <= NX - 2)
			{
				if (At(c, near) >= 0) { c++; continue; }   // the elevator
				int w;
				switch (variant)
				{
				case V_HOTEL: w = 1; break;
				case V_LUXURY: w = Rand(3, 5); break;
				case V_APARTMENTS: w = Rand(2, 3); break;
				default: w = 2; break;
				}
				// stop at the elevator
				int avail = 0;
				while (c + avail <= NX - 2 && At(c + avail, near) < 0 && avail < w) avail++;
				w = max(1, avail);
				if (variant == V_HOTEL) HotelRoom(c, near, far);
				else Flat(c, c + w - 1, near, far);
				c += w;
			}
		}
		// service rooms: the utility room somewhere on the corridor, housekeeping in hotels, the den
		Replace(H_UTILITY, 1);
		if (variant == V_HOTEL) Replace(H_LINEN, 1);
		if (variant == V_LUXURY) Replace(H_CONCIERGE, 1);
		if (variant == V_DEN) Den();
		// fire-escape windows: bedrooms on the outer rows climb out (crouch through)
		for (int i = 1; i <= NX - 2; i++)
		{
			if (Has(At(i, 1), RF_VALUE) && Chance(60)) Link(i, 1, i, ROW_SOUTH, E_WINDOW);
			if (At(i, ROW_NORTH) == re && At(i, 5) >= 0 && Chance(60)) Link(i, 5, i, ROW_NORTH, E_WINDOW);
		}
		// the fire escape reaches the stairwells (a door on each landing)
		Link(1, ROW_SOUTH, 1, 1, E_WINDOW);
		for (int i = 1; i <= NX - 2; i++) if (At(i, ROW_SOUTH) == fe && At(i, 1) >= 0 && !Has(At(i, 1), RF_VALUE) && Chance(15)) Link(i, 1, i, ROW_SOUTH, E_WINDOW);
		EnsureWindow(fe, 1);
		EnsureWindow(re, 5);
	}

	// every fire escape needs at least one way in or out
	void EnsureWindow(int esc, int row)
	{
		Array<int> ci, cj; CellsOf(esc, ci, cj);
		for (int k = 0; k < lI.Size(); k++)
		{
			int i2 = lVert[k] ? lI[k] + 1 : lI[k], j2 = lVert[k] ? lJ[k] : lJ[k] + 1;
			if (At(lI[k], lJ[k]) == esc || At(i2, j2) == esc) return;
		}
		if (ci.Size()) Link(ci[ci.Size() / 2], cj[0], ci[ci.Size() / 2], row, E_WINDOW);
	}

	// a flat: the rooms by the corridor (living room with the front door, kitchen), the rooms by the window
	void Flat(int c0, int c1, int near, int far)
	{
		int w = c1 - c0 + 1;
		int living = MakeRoom(H_LIVING);
		// NBC: on the poor floors some flats are abandoned: dark, stripped, full of rubble
		bool squat = (variant == V_TENEMENT || variant == V_DEN) && Chance(25);
		if (squat) { rflags[living] = RF_DARK | RF_RUBBLE | RF_PATROL; rName[living] = "a squat"; rFloorT[living] = "FLAT5_5"; rWallT[living] = "AXDU06A"; }
		if (w == 1)
		{
			Claim(living, c0, near);
			int bed = MakeRoom(H_BED); Claim(bed, c0, far);
			LinkRooms(living, bed, E_DOOR);
		}
		else
		{
			int lw = w >= 4 ? 2 : 1;
			Rect(living, c0, near, c0 + lw - 1, near);
			int kitch = MakeRoom(H_KITCHEN); Rect(kitch, c0 + lw, near, c1, near);
			LinkRooms(living, kitch, w >= 3 ? E_WIDE : E_ARCH);
			int bw = max(1, w - 1);
			int bed = MakeRoom(Chance(20) && variant != V_TENEMENT ? H_STUDY : H_BED); Rect(bed, c0, far, c0 + bw - 1, far);
			LinkRooms(living, bed, E_DOOR);
			int bath = MakeRoom(H_BATH); Rect(bath, c0 + bw, far, c1, far);
			if (!LinkRooms(bath, bed, E_DOOR)) LinkRooms(bath, kitch, E_DOOR);
			if (w >= 4) { int bed2 = MakeRoom(H_BED); Claim(bed2, c0 + bw - 1, far); LinkRooms(bed2, living, E_DOOR); }
		}
		Link(c0, near, c0, ROW_CORR, E_DOOR);
	}

	void HotelRoom(int c, int near, int far)
	{
		int room = MakeRoom(H_HOTELROOM);
		Claim(room, c, far);
		int bath = MakeRoom(H_BATH);
		Claim(bath, c, near);
		// the hotel room's little entry: the bathroom by the door, the bed by the window
		rName[bath] = "en-suite";
		Link(c, near, c, ROW_CORR, E_DOOR);
		Link(c, near, c, far, E_ARCH);
	}

	// turn `n` corridor-side rooms into rooms of type t (a flat's living room becomes the utility room ...)
	void Replace(int t, int n)
	{
		for (int tries = 0; tries < 40 && n > 0; tries++)
		{
			int i = Rand(1, NX - 2), j = Chance(50) ? 2 : 4;
			int r = At(i, j);
			if (r < 0 || !(IsType(r, H_KITCHEN) || IsType(r, H_BATH))) continue;
			rtype[r] = t;
			int tmp = MakeRoom(t);
			rflags[r] = rflags[tmp]; rF[r] = rF[tmp]; rC[r] = rC[tmp]; rLight[r] = rLight[tmp];
			rFloorT[r] = rFloorT[tmp]; rCeilT[r] = rCeilT[tmp]; rWallT[r] = rWallT[tmp]; rName[r] = rName[tmp];
			// its own door on the corridor
			Link(i, j, i, ROW_CORR, E_DOOR);
			n--;
		}
	}

	// NullSet's den: one flat knocked through into a workroom with a server closet
	// NBC: the gang's den, with a stash room
	void Den()
	{
		int c = Rand(2, NX - 5), side = Rand(0, 1);
		int near = side ? 4 : 2, far = side ? 5 : 1;
		int den = MakeRoom(H_DEN);
		Rect(den, c, near, c + 2, far);
		int srv = MakeRoom(H_SERVER);
		Claim(srv, c + 2, far);
		LinkRooms(den, srv, E_DOOR);
		Link(c + 1, near, c + 1, ROW_CORR, E_DOOR);
		// knocked-through walls mean the neighbours' rooms may have lost their doors: EnsureConnected fixes that
	}

	// ---------------------------------------------------------------- rooftops
	// Roofs of neighbouring buildings at slightly different heights, parapets, gaps with plank bridges,
	// stair huts (the ways in and out), water tanks and air-con plant.
	void Rooftops()
	{
		// blocks of 3-4 columns separated by one-column gaps (a few cells of the gap are plank bridges)
		int c = 0, h = 0;
		Array<int> roofs;
		while (c < NX)
		{
			int w = min(Rand(3, 4), NX - c);
			int roof = MakeRoom(H_ROOF);
			rF[roof] = h;
			rName[roof] = String.Format("a roof (%s)", roofs.Size() % 2 ? "tar" : "gravel");
			if (roofs.Size() % 2) rFloorT[roof] = "FLOOR6_2";
			Rect(roof, c, 0, c + w - 1, NY - 1);
			roofs.Push(roof);
			c += w;
			if (c < NX - 1)
			{
				// a gap (solid: the drop between buildings) with one or two plank bridges
				int bridge = MakeRoom(H_ROOF);
				rName[bridge] = "a plank bridge"; rFloorT[bridge] = "FLOOR4_1"; rF[bridge] = h;
				int by = Rand(1, NY - 2);
				Claim(bridge, c, by);
				if (Chance(50)) { int by2 = (by + 3) % NY; Claim(bridge, c, by2); }
				c++;
			}
			h = h ? 0 : 16;
		}
		// connect: roofs to bridges (open), bridges to the next roof
		for (int r = 0; r < rtype.Size(); r++)
			for (int o = r + 1; o < rtype.Size(); o++)
				if (IsType(r, H_ROOF) && IsType(o, H_ROOF)) LinkAll(r, o, E_WIDE);
		// stair huts: small indoor rooms on the roofs, the ways down (entries)
		for (int k = 0; k < roofs.Size(); k++)
		{
			if (!Chance(k == 0 || k == roofs.Size() - 1 ? 100 : 40)) continue;
			int i, j;
			if (!AnyCell(roofs[k], i, j)) continue;
			int hut = MakeRoom(H_HUT);
			rF[hut] = rF[roofs[k]];
			Claim(hut, i, j);
			LinkRooms(hut, roofs[k], E_DOOR);
			AddEntry(CellCenter(i, j), 90, k == 0 ? "a stair hut" : "the far stair hut", k == 0 ? EK_FRONT : EK_BACK);
		}
		// a roof terrace with a penthouse study on one block
		int tb = roofs[Rand(0, roofs.Size() - 1)];
		int i, j;
		if (AnyCell(tb, i, j) && At(i, j) == tb)
		{
			int study = MakeRoom(H_STUDY);
			rF[study] = rF[tb];
			Claim(study, i, j);
			if (InGrid(i, j + 1) && At(i, j + 1) == tb) Claim(study, i, j + 1);
			LinkRooms(study, tb, E_DOOR);
		}
	}

	override int ObjScore(int r, int k)
	{
		if (variant == V_DEN && k == OBJ_TURN && IsType(r, H_DEN)) return 200;
		if (variant == V_DEN && k == OBJ_STEAL && IsType(r, H_SERVER)) return 200;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case H_CORR: return variant == V_LUXURY || variant == V_HOTEL ? 3 : 2;
		case H_LIVING: case H_BED: case H_HOTELROOM: case H_STUDY: return 1;
		case H_UTILITY: case H_SERVER: case H_HUT: case H_DEN: return 2;
		}
		return 0;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case H_LIVING:
			if (Has(r, RF_DARK)) { if (Chance(60)) PutInRoom("CW_FBed", r); if (Chance(50)) PutInRoom("CW_FScrap", r); break; }   // a squat
			LineWalls("CW_FSofa", r, 120, 1); PutInRoom("CW_FCoffeeTable", r); LineWalls("CW_FWallTV", r, 200, 1);
			if (Chance(50)) PutInRoom("CW_FArmchair", r);
			break;
		case H_KITCHEN:
			LineWalls("CW_FCounter", r, 110, 2); if (Chance(50)) PutInRoom("CW_FRoundTable", r);
			break;
		case H_BED: case H_HOTELROOM:
			LineWalls("CW_FBed", r, 200, ci.Size()); LineWalls("CW_FCredenza", r, 150, 1);
			if (rtype[r] == H_HOTELROOM && Chance(50)) PutInRoom("CW_FArmchair", r);
			break;
		case H_BATH:
			LineWalls("CW_FVanity", r, 120, 1);
			break;
		case H_STUDY:
			PutInRoom("CW_FDeskExec", r); LineWalls("CW_FBookshelf", r, 70, 4); PutInRoom("CW_FArmchair", r);
			break;
		case H_UTILITY: case H_HUT:
			LineWalls("CW_FGenerator", r, 200, 1); LineWalls("CW_FPipes", r, 150, 2);
			break;
		case H_LINEN:
			LineWalls("CW_FShelving", r, 90, 3);
			break;
		case H_DEN:
			// NBC: card tables, couches and crates instead of hacker desks
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell("CW_FRoundTable", ci[k], cj[k]);
			LineWalls("CW_FSofa", r, 140, 2); LineWalls("CW_FCrates", r, 120, 2); PutInRoom("CW_FWallTV", r);
			break;
		case H_SERVER:
			LineWalls("CW_FShelving", r, 70, 3); PutInRoom("CW_FCrates", r);
			break;
		case H_CONCIERGE:
			PutInRoom("CW_FReception", r, 90); PutInRoom("CW_FPlanter", r);
			break;
		case H_ESCAPE:
			for (int k = 0; k < ci.Size(); k++) if (Chance(20)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		case H_ROOF:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 12) PutInCell("CW_FWaterTower", ci[k], cj[k]);
				else if (roll < 34) PutInCell("CW_FAcUnit", ci[k], cj[k], 90 * Rand(0, 3));
				else if (roll < 42) PutInCell("CW_FPipes", ci[k], cj[k], 90 * Rand(0, 1));
			}
			break;
		}
	}

	override void Outdoors()
	{
		// dim lights over the fire escapes and roofs
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (!IsOut(r)) continue;
			Array<int> ci, cj; CellsOf(r, ci, cj);
			for (int k = 0; k < ci.Size(); k += 3)
				NBC_LightSource.Make((CellCenter(ci[k], cj[k]), rF[r] + 96), 255, 190, 120, 150);
		}
	}
}
