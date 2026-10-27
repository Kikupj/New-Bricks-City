// The street (PLAN.md §4.4, §6.7, M2c): a two-sided street at the foot of the towers in the Bricks.
//
// Template NBC_KS (tools/make_kit_maps.py): 15 columns (cross street 224, sidewalk 112, 12 lots of 176, a side
// passage 128) by 12 rows, south to north:
//
//   row 11     the Wall (8 m, free-standing concrete; towers rise beyond it)
//   row 10     the north alley, behind every north lot; a side passage down column 14 to the north sidewalk
//   rows 6-9   the north lots: shops (front two rows) with back rooms, walk-ups, alleyways, parking lots,
//              closed buildings, and the variant's landmark
//   row 5      the north sidewalk (and down column 1)
//   row 4      the road (and the cross street down column 0)
//   row 3      the south sidewalk
//   rows 1-2   the south lots: shops (front row) with back rooms, walk-ups, alleyways, parking lots
//   row 0      the canal walk, the alley behind the south lots; the canal runs right past it
//
// Shops are one storey (108, 3.5 m); above them the facades show the flats upstairs. Past the canal walk and the
// cross street the canal, past the side passages a retaining wall, and tower blocks all round (the template).
// Variants: a tower entrance (a fenced courtyard, the tower's lobby, a playground), corner stores, a chop lot
// (a fenced car lot and the garage), and under the el (the elevated rail line over the road, stalls beneath it).
class NBC_KitStreet : NBC_KitGen
{
	enum EVar { V_TOWER, V_CORNER, V_LOT, V_UNDER, V_COUNT }
	enum ERoom
	{
		S_ROAD, S_WALK, S_ALLEY, S_COURT, S_PLAY, S_LOT, S_UNDER, S_PARKING,
		S_LOBBY, S_SECURITY, S_MAIL, S_LIFTS, S_TSTAIR, S_SUPER,
		S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BOARDED, S_BACK, S_HANGOUT, S_WALKUP,
		S_GARAGE, S_OFFICE
	}
	const LOT0 = 2;
	const LOT1 = 13;
	const COL_PASS = 14;
	const ROW_CANAL = 0;       // the south alley
	const ROW_SBACK = 1;
	const ROW_SFRONT = 2;
	const ROW_SWALK = 3;
	const ROW_ROAD = 4;
	const ROW_NWALK = 5;
	const ROW_N0 = 6;          // north lots: front rows 6-7, back rows 8-9
	const ROW_N3 = 9;
	const ROW_ALLEY = 10;
	const ROW_WALL = 11;
	const WALL_TEX = "CWWALLD";      // the Wall's concrete
	const WALL_H = 256;              // and its height: 8 m, the towers beyond rise over it
	static const String FRONTS[] = { "BRICK1", "BRICK12", "BIGBRIK1", "STUCCO1", "BRICK6", "BRICK11", "ADBRICK", "STONE2" };
	static const String UPPER[] = { "CWNRESA", "CWNRESB", "CWNRESC" };

	int roadR, walkN, walkS, alleyN, alleyS;

	override void Setup()
	{
		static const int CW[] = { 224, 112, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 128 };
		static const int RW[] = { 128, 176, 176, 112, 256, 128, 176, 176, 176, 176, 128, 160 };
		for (int i = 0; i < CW.Size(); i++) colw.Push(CW[i]);
		for (int j = 0; j < RW.Size(); j++) rowh.Push(RW[j]);
		Grid(CW.Size(), RW.Size());
		doorTex = "ADDOOR3"; jambTex = "SUPPORT3"; edgeTex = "ADBRICK";
		// past the edges: the embankment and the canal, the towers beyond (the template's scenery, make_kit_maps.py)
		bandFloor = 0; bandTex = "CWPAVE"; bandCeil = 640; bandLight = 128;
		kerbTex = "CWCONCW";
	}
	override double SkyH() { return 640; }
	override double GroundFloorH() { return 112; }
	// above a shopfront, the flats upstairs (the same facade over the same storefront); the Wall stays concrete
	override String UpperFacade(String ground)
	{
		if (ground == WALL_TEX) return "CWWALLD";
		if (ground == "CWVIADUC" || ground.Length() == 0) return ground.Length() ? ground : "ADBRICK";
		return UPPER[(ground.Length() + ground.ByteAt(ground.Length() - 1)) % UPPER.Size()];
	}
	// the Wall stands free, open to the sky above it
	override double SolidTop(int i, int j) { return cellFac[j * NX + i] == WALL_TEX ? WALL_H : 0; }
	override bool EdgeOpen(int r) { return IsOut(r); }
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "tower entrance", "corner stores", "chop lot", "under the el" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 12, 12, 5, 13 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		switch (t)
		{
		case S_ROAD:       return Room(t, RF_OUT, -8, 0, 120, "CWASPH", "F_SKY1", "ADBRICK", "the street");
		case S_WALK:       return Room(t, RF_OUT | RF_CIV | RF_RUBBLE, 0, 0, 128, "CWPAVE", "F_SKY1", "ADBRICK", "the sidewalk");
		case S_ALLEY:      return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 104, "MFLR8_1", "F_SKY1", "BRICK6", "the alley");
		case S_COURT:      return Room(t, RF_OUT | RF_CIV | RF_PATROL | RF_RUBBLE, 0, 0, 120, "CWPAVE", "F_SKY1", "ADBRICK", "the courtyard");
		case S_PLAY:       return Room(t, RF_OUT | RF_CIV | RF_RUBBLE, 0, 0, 120, "CWCONCF", "F_SKY1", "ADBRICK", "the playground");
		case S_LOT:        return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 112, "FLOOR4_8", "F_SKY1", "BRICK6", "the car lot");
		case S_PARKING:    return Room(t, RF_OUT | RF_PATROL | RF_CIV, -8, 0, 120, "CWASPH", "F_SKY1", "BRICK6", "a parking lot");
		case S_UNDER:      return Room(t, RF_PATROL | RF_CIV, -8, 176, 88, "CWASPH", "CWDECKUN", "CWVIADUC", "under the el");
		case S_LOBBY:      return Room(t, RF_CIV | RF_PATROL, 0, 108, 144, "CWTILEF", "CWCEILL", "ADGREYW", "the tower entrance");
		case S_SECURITY:   return Room(t, RF_PEOPLE, 0, 96, 136, "CWCONCF", "CWCEILT", "ADGREYW", "the security booth");
		case S_MAIL:       return Room(t, RF_CIV, 0, 96, 128, "CWTILEF", "CWCEILT", "ADGREYW", "the mailroom");
		case S_LIFTS:      return Room(t, RF_CIV | RF_PATROL, 0, 96, 136, "CWTILEF", "CWCEILL", "CWELEVD", "the lift lobby");
		case S_TSTAIR:     return Room(t, RF_NOGUARD, 0, 96, 112, "CWSTAIF", "ADFLUOR", "ADGREY2", "the tower stairs");
		case S_SUPER:      return Room(t, RF_PEOPLE | RF_VALUE, 0, 88, 112, "CWCONCF", "CWCEILT", "CWWALLD", "the super's office");
		case S_BODEGA:     return Room(t, RF_CIV, 0, 108, 160, "CWTILEF", "CWCEILT", "CWWALL1", "the bodega");
		case S_LAUNDROMAT: return Room(t, RF_CIV, 0, 108, 160, "CWTILEF", "CWCEILT", "CWTILEW", "the laundromat");
		case S_CHECKS:     return Room(t, RF_CIV | RF_VALUE, 0, 108, 152, "CWCARP2", "CWCEILT", "ADGREYW", "the check cashing place");
		case S_TAKEOUT:    return Room(t, RF_CIV, 0, 108, 152, "CWTILEF", "CWCEILT", "CWWALL2", "the takeout");
		case S_BARBER:     return Room(t, RF_CIV | RF_PEOPLE, 0, 108, 152, "CWTILEF", "CWCEILT", "CWWALL1", "the barbershop");
		case S_BOARDED:    return Room(t, RF_DARK | RF_RUBBLE | RF_PATROL, 0, 108, 72, "CWCONCF", "ADFLUOR", "CWWALLD", "a boarded-up store");
		case S_BACK:       return Room(t, RF_VALUE, 0, 96, 112, "FLOOR4_8", "ADFLUOR", "CEMENT7", "a back room");
		case S_HANGOUT:    return Room(t, RF_PEOPLE | RF_PATROL | RF_RUBBLE, 0, 96, 96, "CWCONCF", "ADFLUOR", "CWWALLD", "the back room");
		case S_WALKUP:     return Room(t, RF_CIV | RF_NOGUARD, 0, 96, 104, "CWSTAIF", "ADFLUOR", "ADGREY2", "a walk-up stairway");
		case S_GARAGE:     return Room(t, RF_TECH | RF_PATROL | RF_RUBBLE, 0, 128, 112, "CWCONCF", "ADFLUOR", "SHAWN02", "the chop garage");
		case S_OFFICE:     return Room(t, RF_VALUE | RF_PEOPLE, 0, 88, 120, "CWCARP2", "CWCEILT", "CWWALLD", "the office");
		}
		return Room(t, 0, 0, 96, 128, "FLOOR4_8", "CWCEILT", "CEMENT7", "a room");
	}

	// ---------------------------------------------------------------- layout
	override void Layout()
	{
		// the public space: the road across the middle and down the west side, a sidewalk either side of it
		roadR = MakeRoom(S_ROAD);
		Rect(roadR, 0, ROW_ROAD, NX - 1, ROW_ROAD);
		Rect(roadR, 0, 0, 0, ROW_ALLEY);
		walkN = MakeRoom(S_WALK); rName[walkN] = "the north sidewalk";
		Rect(walkN, 1, ROW_NWALK, NX - 1, ROW_NWALK);
		Rect(walkN, 1, ROW_NWALK, 1, ROW_ALLEY);
		walkS = MakeRoom(S_WALK); rName[walkS] = "the south sidewalk";
		Rect(walkS, 1, ROW_SWALK, NX - 1, ROW_SWALK);
		Rect(walkS, 1, 0, 1, ROW_SWALK);
		if (variant == V_UNDER)
		{
			// the elevated line runs over the road: under it the road is covered, the cross street isn't
			int under = MakeRoom(S_UNDER);
			Rect(under, 1, ROW_ROAD, NX - 1, ROW_ROAD);
			rFacT[under] = "CWVIADUC";
			LinkAll(under, roadR, E_WIDE);
			LinkAll(under, walkN, E_WIDE);
			LinkAll(under, walkS, E_WIDE);
		}
		LinkAll(roadR, walkN, E_WIDE);
		LinkAll(roadR, walkS, E_WIDE);
		// the alleys behind both rows of lots, side passages down column 14 to the sidewalks
		alleyN = MakeRoom(S_ALLEY);
		Rect(alleyN, LOT0, ROW_ALLEY, LOT1, ROW_ALLEY);
		Rect(alleyN, COL_PASS, ROW_N0, COL_PASS, ROW_ALLEY);
		Link(1, ROW_ALLEY, LOT0, ROW_ALLEY, E_WIDE);
		Link(COL_PASS, ROW_NWALK, COL_PASS, ROW_N0, E_WIDE);
		alleyS = MakeRoom(S_ALLEY); rName[alleyS] = "the canal walk";
		Rect(alleyS, LOT0, ROW_CANAL, COL_PASS, ROW_CANAL);
		Rect(alleyS, COL_PASS, ROW_CANAL, COL_PASS, ROW_SFRONT);
		Link(1, ROW_CANAL, LOT0, ROW_CANAL, E_WIDE);
		Link(COL_PASS, ROW_SFRONT, COL_PASS, ROW_SWALK, E_WIDE);
		// the Wall closes the block to the north
		for (int i = 0; i < NX; i++) cellFac[ROW_WALL * NX + i] = WALL_TEX;

		switch (variant)
		{
		case V_TOWER:
		{
			int t0 = Rand(LOT0 + 2, LOT1 - 6);
			TowerBase(t0);
			Playground(t0 - 2, t0 - 1);
			FillLots(LOT0, t0 - 3, 25, true);
			FillLots(t0 + 5, LOT1, 25, true);
			break;
		}
		case V_CORNER:
			FillLots(LOT0, LOT1, 10, true);
			break;
		case V_LOT:
		{
			int l0 = Rand(LOT0 + 1, LOT1 - 5);
			ChopLot(l0);
			FillLots(LOT0, l0 - 1, 20, true);
			FillLots(l0 + 5, LOT1, 20, true);
			break;
		}
		case V_UNDER:
			FillLots(LOT0, LOT1, 20, true);
			break;
		}
		FillLots(LOT0, LOT1, 20, false);
		if (variant == V_CORNER) Hangout();

		// the ways in: the cross street, both alleys, the north side passage
		AddEntry(CellCenter(0, ROW_N0 + 1), 0, "the cross street", EK_FRONT, roadR);
		AddEntry(CellCenter(LOT0 + 1, ROW_ALLEY), 0, "the north alley", EK_BACK, alleyN);
		AddEntry(CellCenter(LOT0 + 1, ROW_CANAL), 0, "the canal walk", EK_SERVICE, alleyS);
		AddEntry(CellCenter(COL_PASS, ROW_N0 + 2), 270, "the side passage", EK_ANY, alleyN);
	}

	// The base of a tower over columns t0..t0+4 on the north side: a fenced courtyard, the lobby behind it.
	void TowerBase(int t0)
	{
		int court = MakeRoom(S_COURT); Rect(court, t0, ROW_N0, t0 + 4, ROW_N0 + 1);
		LinkAll(court, walkN, E_FENCE);
		Link(t0 + 2, ROW_N0, t0 + 2, ROW_NWALK, E_WIDE);              // the gate
		int b0 = ROW_N0 + 2, b1 = ROW_N3;
		int stair = MakeRoom(S_TSTAIR); Rect(stair, t0, b0, t0, b1);
		int sec = MakeRoom(S_SECURITY); Claim(sec, t0 + 1, b0);
		int lobby = MakeRoom(S_LOBBY); Claim(lobby, t0 + 2, b0);
		int mail = MakeRoom(S_MAIL); Claim(mail, t0 + 3, b0);
		int lifts = MakeRoom(S_LIFTS); Rect(lifts, t0 + 1, b1, t0 + 3, b1);
		int sup = MakeRoom(S_SUPER); Rect(sup, t0 + 4, b0, t0 + 4, b1);
		Link(t0 + 2, b0 - 1, t0 + 2, b0, E_DOOR);                      // the front doors
		Link(t0 + 1, b0 - 1, t0 + 1, b0, E_WINDOW);                    // the security booth's window onto the court
		LinkRooms(lobby, sec, E_DOOR);
		LinkRooms(lobby, mail, E_ARCH);
		Link(t0 + 2, b0, t0 + 2, b1, E_WIDE);
		LinkRooms(lifts, stair, E_DOOR);
		LinkRooms(lifts, sup, E_DOOR);
		Link(t0 + 4, b1, t0 + 4, ROW_ALLEY, E_DOOR);                   // the super's back door
		Link(t0, b1, t0, ROW_ALLEY, E_DOOR);                           // the fire door from the stairs
		for (int j = ROW_N0; j <= ROW_N3; j++) for (int i = t0; i <= t0 + 4; i++) if (At(i, j) >= 0 && !IsOut(At(i, j))) rFacT[At(i, j)] = "ADBRICK";
		AddEntry(CellCenter(t0, b0) + (0, 30), 0, "the tower stairs", EK_ROOF, stair);
	}

	// A fenced playground over columns c0..c1 beside the tower's court, a closed building behind it.
	void Playground(int c0, int c1)
	{
		if (c0 < LOT0) return;
		int pg = MakeRoom(S_PLAY); Rect(pg, c0, ROW_N0, c1, ROW_N0 + 2);
		LinkAll(pg, walkN, E_FENCE);
		Link(c0, ROW_N0, c0, ROW_NWALK, E_WIDE);
		int court = At(c1 + 1, ROW_N0);
		if (court >= 0) { LinkAll(pg, court, E_FENCE); Link(c1, ROW_N0 + 1, c1 + 1, ROW_N0 + 1, E_WIDE); }
		for (int i = c0; i <= c1; i++) cellFac[ROW_N3 * NX + i] = "BRICK12";
	}

	// A chop shop on the north side: a chain-link car lot on the street, the garage behind it, an office.
	void ChopLot(int l0)
	{
		int lot = MakeRoom(S_LOT); Rect(lot, l0, ROW_N0, l0 + 3, ROW_N0 + 1);
		LinkAll(lot, walkN, E_FENCE);
		Link(l0 + 1, ROW_N0, l0 + 1, ROW_NWALK, E_WIDE); Link(l0 + 2, ROW_N0, l0 + 2, ROW_NWALK, E_WIDE);   // the gate
		int gar = MakeRoom(S_GARAGE); Rect(gar, l0, ROW_N0 + 2, l0 + 3, ROW_N3);
		Link(l0 + 1, ROW_N0 + 1, l0 + 1, ROW_N0 + 2, E_WIDE); Link(l0 + 2, ROW_N0 + 1, l0 + 2, ROW_N0 + 2, E_WIDE);   // the roll-up door
		int off = MakeRoom(S_OFFICE); Rect(off, l0 + 4, ROW_N0 + 2, l0 + 4, ROW_N3);
		LinkRooms(off, gar, E_DOOR);
		int parts = MakeRoom(S_BACK); rName[parts] = "the parts room"; Rect(parts, l0 + 4, ROW_N0, l0 + 4, ROW_N0 + 1);
		LinkRooms(parts, off, E_DOOR);
		Link(l0, ROW_N3, l0, ROW_ALLEY, E_DOOR);
		for (int j = ROW_N0; j <= ROW_N3; j++) for (int i = l0; i <= l0 + 4; i++) if (At(i, j) >= 0) rFacT[At(i, j)] = "SHAWN02";
	}

	// Lots across columns c0..c1 on one side: shops with back rooms, walk-ups, alleyways through to the alley
	// behind, parking lots, and closed buildings.
	void FillLots(int c0, int c1, int closedPct, bool north)
	{
		int f0 = north ? ROW_N0 : ROW_SFRONT, f1 = north ? ROW_N0 + 1 : ROW_SFRONT;      // the shop rows
		int b0 = north ? ROW_N0 + 2 : ROW_SBACK, b1 = north ? ROW_N3 : ROW_SBACK;        // the back rooms
		int walkRow = north ? ROW_NWALK : ROW_SWALK, alleyRow = north ? ROW_ALLEY : ROW_CANAL;
		int walk = north ? walkN : walkS, alley = north ? alleyN : alleyS;
		int lo = min(f0, b0), hi = max(f1, b1);         // every row of the lot
		int backRow = north ? b1 : b0;                  // the lot row against the alley
		int frontRow = north ? f0 : f1;                 // the lot row against the sidewalk
		int c = c0;
		while (c <= c1)
		{
			int left = c1 - c + 1;
			int w = min(Rand(1, 3), left);
			String front = FRONTS[Rand(0, FRONTS.Size() - 1)];
			int x1 = c + w - 1;
			int roll = Rand(0, 99);
			if (roll < closedPct)
			{
				// a closed building: solid behind its facade
				for (int j = lo; j <= hi; j++) for (int i = c; i <= x1; i++) cellFac[j * NX + i] = Chance(30) ? "CWPLANK" : front;
			}
			else if (w == 1 && roll < closedPct + 12)
			{
				// an alleyway between the buildings, through to the alley behind
				int aw = MakeRoom(S_ALLEY); rName[aw] = "an alleyway";
				Rect(aw, c, lo, c, hi);
				Link(c, frontRow, c, walkRow, E_WIDE);
				Link(c, backRow, c, alleyRow, E_WIDE);
			}
			else if (w >= 2 && roll < closedPct + 26)
			{
				// a parking lot: a low fence along the sidewalk with a gap to drive in, open to the alley behind
				int pk = MakeRoom(S_PARKING);
				Rect(pk, c, lo, x1, hi);
				LinkAll(pk, walk, E_FENCE);
				int gate = c + Rand(0, w - 1);
				Link(gate, frontRow, gate, walkRow, E_WIDE);
				LinkAll(pk, alley, E_WIDE);
			}
			else if (w == 1 && roll < closedPct + 40)
			{
				// a walk-up: a stair hall up to the flats over the shops
				int wu = MakeRoom(S_WALKUP); Rect(wu, c, f0, c, f1);
				Link(c, frontRow, c, walkRow, E_DOOR);
				rFacT[wu] = front;
				for (int j = b0; j <= b1; j++) cellFac[j * NX + c] = front;
			}
			else
			{
				static const int SHOPS[] = { S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BOARDED, S_BODEGA, S_BOARDED };
				int shop = MakeRoom(SHOPS[Rand(0, SHOPS.Size() - 1)]);
				int back = MakeRoom(S_BACK);
				Rect(shop, c, f0, x1, f1);
				Rect(back, c, b0, x1, b1);
				LinkRooms(shop, back, E_DOOR);
				int door = c + w / 2;
				Link(door, frontRow, door, walkRow, IsType(shop, S_BOARDED) && Chance(50) ? E_ARCH : E_DOOR);
				if (Chance(55)) { int bx = c + Rand(0, w - 1); Link(bx, backRow, bx, alleyRow, E_DOOR); }
				rFacT[shop] = IsType(shop, S_BOARDED) ? "CWPLANK" : front;
				rFacT[back] = front;
			}
			c += w;
		}
	}

	// the crew's back room behind one of the shops
	void Hangout()
	{
		for (int tries = 0; tries < 40; tries++)
		{
			int i = Rand(LOT0, LOT1);
			int r = At(i, Chance(50) ? ROW_N0 + 2 : ROW_SBACK);
			if (r < 0 || !IsType(r, S_BACK)) continue;
			int tmp = MakeRoom(S_HANGOUT);
			rtype[r] = S_HANGOUT; rflags[r] = rflags[tmp]; rLight[r] = rLight[tmp]; rName[r] = rName[tmp];
			rFloorT[r] = rFloorT[tmp]; rWallT[r] = rWallT[tmp];
			rtype.Pop(); rflags.Pop(); rF.Pop(); rC.Pop(); rLight.Pop();
			rFloorT.Pop(); rCeilT.Pop(); rWallT.Pop(); rFacT.Pop(); rName.Pop();
			return;
		}
	}

	// ---------------------------------------------------------------- objectives, light, dressing
	override int ObjScore(int r, int k)
	{
		if (IsOut(r) || IsType(r, S_UNDER)) return 0;
		if (k == OBJ_STEAL && (IsType(r, S_HANGOUT) || IsType(r, S_OFFICE) || IsType(r, S_CHECKS) || IsType(r, S_SUPER))) return 160;
		if (k == OBJ_DESTROY && (IsType(r, S_GARAGE) || IsType(r, S_HANGOUT))) return 160;
		if (k == OBJ_TURN && (IsType(r, S_BARBER) || IsType(r, S_SUPER) || IsType(r, S_SECURITY))) return 140;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case S_BODEGA: case S_LAUNDROMAT: case S_CHECKS: case S_TAKEOUT: case S_BARBER: case S_LOBBY: case S_LIFTS: return 0;
		case S_GARAGE: case S_BACK: case S_HANGOUT: case S_TSTAIR: case S_WALKUP: case S_UNDER: return 2;
		case S_OFFICE: case S_SUPER: return 1;
		}
		return 3;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case S_ALLEY:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				// against a wall: the north side of the long alleys (the Wall, the backs of the south shops), east or
				// west in alleyways
				int side = (cj[k] == ROW_ALLEY || cj[k] == ROW_CANAL) && ci[k] != COL_PASS ? 2 : Rand(0, 1);
				if (roll < 30) PutWall("CW_FDumpster", ci[k], cj[k], side, Rand(-40, 40));
				else if (roll < 45) PutWall("CW_FPallet", ci[k], cj[k], side, Rand(-40, 40));
				else if (roll < 55) PutWall("CW_FScrap", ci[k], cj[k], side, Rand(-40, 40));
			}
			break;
		case S_WALK:
			// NBC: street furniture against the building fronts: bins, benches, planters, junk, a scaffold now and then
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				Class<Actor> what = null;
				if (roll < 16) what = "CW_FBin";
				else if (roll < 26) what = "CW_FPew";
				else if (roll < 34) what = "CW_FPlanter";
				else if (roll < 42) what = "CW_FPallet";
				else if (roll < 50) what = "CW_FCrates";
				else if (roll < 56) what = "CW_FScrap";
				else if (roll < 60) what = "CW_FScaffold";
				else if (roll < 66) what = "CW_FDumpster";
				if (!what) continue;
				int d0 = Rand(0, 3);
				for (int t = 0; t < 4; t++) if (PutWall(what, ci[k], cj[k], (d0 + t) % 4, Rand(-40, 40))) break;
			}
			break;
		case S_ROAD:
			// NBC: a wreck or two, and barriers where someone blocked the road
			for (int k = 0; k < ci.Size(); k++)
			{
				if (cj[k] != ROW_ROAD || ci[k] < LOT0) continue;
				int roll = Rand(0, 99);
				Vector2 c = CellCenter(ci[k], cj[k]);
				if (roll < 8) Car(c + (Rand(-30, 30), Rand(-20, 20)), Rand(0, 359), "ModernCarDirtyGreen");
				else if (roll < 16) Put("CW_FBarrier", c + (Rand(-40, 40), Rand(-60, 60)), Rand(0, 1) * 90 + Rand(-15, 15));
				else if (roll < 22) Put("CW_FScrap", c + (Rand(-40, 40), Rand(-60, 60)), Rand(0, 359));
			}
			break;
		case S_COURT:
			for (int k = 0; k < ci.Size(); k++)
			{
				int roll = Rand(0, 99);
				if (roll < 25) PutInCell("CW_FPew", ci[k], cj[k], 90 * Rand(0, 1));
				else if (roll < 40) PutInCell("CW_FPlanter", ci[k], cj[k]);
				else if (roll < 50) PutInCell("CW_FBin", ci[k], cj[k]);
			}
			break;
		case S_PLAY:
			PutInRoom("CW_FScaffold", r, 0);          // what's left of the climbing frame
			for (int k = 0; k < ci.Size(); k++) if (Chance(35)) PutInCell(Chance(50) ? "CW_FPew" : "CW_FScrap", ci[k], cj[k], 90 * Rand(0, 1));
			break;
		case S_LOT:
			for (int k = 0; k < ci.Size(); k++) if (Chance(75)) Car(CellCenter(ci[k], cj[k]), 90 * Rand(0, 3), Chance(50) ? "ModernCarDirtyGreen" : "");
			LineWalls("CW_FScrap", r, 160, 3);
			break;
		case S_PARKING:
			for (int k = 0; k < ci.Size(); k++) if (Chance(65)) Car(CellCenter(ci[k], cj[k]) + (0, Rand(-12, 12)), Chance(50) ? 90 : 270);
			if (ci.Size()) PoleLight(CellCenter(ci[0], cj[0]) + (-60, -60), 300);
			break;
		case S_UNDER:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (ci[k] % 3 == 0) PutInCell("CW_FBarrier", ci[k], cj[k], 0);           // the el's footings
				else if (Chance(45)) PutInCell("CW_FStall", ci[k], cj[k], 90 * Rand(0, 3));
			}
			break;
		case S_LOBBY:
			LineWalls("CW_FPlanter", r, 120, 1); LineWalls("CW_FBin", r, 120, 1);
			break;
		case S_SECURITY:
			PutInRoom("CW_FReception", r, 270); LineWalls("CW_FWallTV", r, 90, 2);
			break;
		case S_MAIL:
			LineWalls("CW_FLocker", r, 40, 6);      // the mailboxes
			break;
		case S_SUPER: case S_OFFICE:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FFileCabinet", r, 60, 3); if (Chance(50)) LineWalls("CW_FWallTV", r, 120, 1);
			break;
		case S_BODEGA:
			LineWalls("CW_FShelving", r, 80, 5); PutInRoom("CW_FCounter", r, 90); LineWalls("CW_FVending", r, 120, 1);
			break;
		case S_LAUNDROMAT:
			LineWalls("CW_FCounter", r, 70, 6); PutInRoom("CW_FPew", r, 0);
			break;
		case S_CHECKS:
			LineWalls("CW_FCounter", r, 110, 2); LineWalls("CW_FFileCabinet", r, 60, 2);
			break;
		case S_TAKEOUT:
			LineWalls("CW_FCounter", r, 110, 2);
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FStool", ci[k], cj[k]); }
			break;
		case S_BARBER:
			LineWalls("CW_FVanity", r, 80, 3); LineWalls("CW_FChair", r, 80, 3); PutInRoom("CW_FPew", r, 0);
			break;
		case S_BOARDED:
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell(Chance(50) ? "CW_FScrap" : "CW_FCrates", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		case S_BACK:
			LineWalls("CW_FShelving", r, 90, 3);
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(50) ? "CW_FCrates" : "CW_FPallet", ci[k], cj[k]);
			break;
		case S_HANGOUT:
			LineWalls("CW_FSofa", r, 140, 2); PutInRoom("CW_FRoundTable", r); LineWalls("CW_FWallTV", r, 160, 1); LineWalls("CW_FCrates", r, 120, 2);
			break;
		case S_GARAGE:
			for (int k = 0; k < ci.Size(); k++) if (cj[k] == ROW_N0 + 2 && Chance(70)) Car(CellCenter(ci[k], cj[k]), 90, Chance(40) ? "ModernCarDirtyGreen" : "");
			LineWalls("CW_FWorkbench", r, 140, 3); LineWalls("CW_FLocker", r, 160, 2); LineWalls("CW_FScrap", r, 200, 2);
			break;
		}
	}

	override void Outdoors()
	{
		// street lamps on both kerbs, parked cars along both sides of the road, lights over the alley doors,
		// floodlights on the Wall
		for (int i = LOT0; i < NX; i += 2)
		{
			PoleLight((colX[i] + colw[i] / 2, rowY[ROW_NWALK] + 16), 320);
			PoleLight((colX[i + 1 < NX ? i + 1 : i] + colw[i] / 2, rowY[ROW_SWALK] + rowh[ROW_SWALK] - 16), 320);
		}
		for (int j = 0; j < ROW_WALL; j++) if (j != ROW_ROAD) PoleLight((colX[1] + 16, rowY[j] + rowh[j] / 2), 300);
		// NBC: fill light down the middle of the road, so there are no black gaps between the lamps
		for (int i = 0; i < NX; i += 2) NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_ROAD] + rowh[ROW_ROAD] / 2, 160), 200, 180, 150, 260);
		if (variant != V_UNDER)
			for (double x = colX[LOT0] + 80; x < colX[NX - 1]; x += 240)
			{
				if (Chance(55)) Car((x + Rand(-30, 30), rowY[ROW_ROAD] + rowh[ROW_ROAD] - 56), 180);
				if (Chance(55)) Car((x + 120 + Rand(-30, 30), rowY[ROW_ROAD] + 56), 0);
			}
		for (double y = rowY[ROW_NWALK] + 60; y < rowY[NY - 1]; y += 260)
			if (Chance(50)) Car((colX[0] + colw[0] - 64, y), Chance(50) ? 90 : 270);
		for (int i = LOT0; i < NX; i += 3)
		{
			NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_ALLEY] + 16, 84), 255, 170, 90, 220);
			NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_CANAL] + rowh[ROW_CANAL] - 16, 84), 255, 170, 90, 220);
			NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_WALL] - 24, 200), 220, 230, 255, 260);   // the Wall's floodlights
		}
		if (variant == V_UNDER)
			for (int i = 1; i < NX; i += 2) NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_ROAD] + rowh[ROW_ROAD] / 2, 150), 255, 190, 120, 180);
	}
}
