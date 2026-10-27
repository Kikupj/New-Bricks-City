// The street (PLAN.md §4.4, §6.7, M2c): a block at the foot of the towers in the Bricks.
//
// Template NBC_KS (tools/make_kit_maps.py): 15 columns (cross street 224, sidewalk 112, 12 lots of 176, a side
// passage 128) by 8 rows (road 256, sidewalk 128, four lot rows of 176, alley 128, the Wall 160).
//
//   row 7  the Wall (solid, floodlit concrete)
//   row 6  the alley, behind every lot; the side passage runs down column 14 to the sidewalk
//   rows 2-5  the lots: shops with back rooms, walk-ups, closed buildings, and the variant's landmark
//   row 1  the sidewalk (and down column 1)
//   row 0  the road (and the cross street down column 0)
//
// Shops are one storey (108, 3.5 m); above them the facades show the flats upstairs. Variants: a tower entrance
// (a fenced courtyard, the tower's lobby, a playground), corner stores, a chop lot (a fenced car lot and the
// garage), and under the el (the elevated rail line over the road, market stalls beneath it).
class NBC_KitStreet : NBC_KitGen
{
	enum EVar { V_TOWER, V_CORNER, V_LOT, V_UNDER, V_COUNT }
	enum ERoom
	{
		S_ROAD, S_WALK, S_ALLEY, S_COURT, S_PLAY, S_LOT, S_UNDER,
		S_LOBBY, S_SECURITY, S_MAIL, S_LIFTS, S_TSTAIR, S_SUPER,
		S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BOARDED, S_BACK, S_HANGOUT, S_WALKUP,
		S_GARAGE, S_OFFICE
	}
	const LOT0 = 2;
	const LOT1 = 13;
	const COL_PASS = 14;
	const ROW_ALLEY = 6;
	const ROW_WALL = 7;
	const WALL_TEX = "ADSCONC";      // the Wall's floodlit concrete
	static const String FRONTS[] = { "BRICK1", "BRICK12", "BIGBRIK1", "STUCCO1", "BRICK6", "BRICK11", "ADBRICK", "STONE2" };
	static const String UPPER[] = { "CWNRESA", "CWNRESB", "CWNRESC" };

	int roadR, walkR, alleyR;

	override void Setup()
	{
		static const int CW[] = { 224, 112, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 128 };
		static const int RW[] = { 256, 128, 176, 176, 176, 176, 128, 160 };
		for (int i = 0; i < CW.Size(); i++) colw.Push(CW[i]);
		for (int j = 0; j < RW.Size(); j++) rowh.Push(RW[j]);
		Grid(CW.Size(), RW.Size());
		doorTex = "ADDOOR3"; jambTex = "SUPPORT3"; edgeTex = "ADBRICK";
		// across the street: the pavement at kerb height, then the towers opposite, the night sky above them
		bandFloor = 0; bandTex = "CWPAVE"; bandCeil = 640; bandLight = 136;
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
	// beyond the road and the cross street: towers with lit windows
	override String BandWall(Vector2 at) { return UPPER[Rand(0, UPPER.Size() - 1)]; }
	override bool EdgeOpen(int r) { return IsOut(r); }
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "tower entrance", "corner stores", "chop lot", "under the el" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 9, 9, 3, 10 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		switch (t)
		{
		case S_ROAD:       return Room(t, RF_OUT, -8, 0, 96, "CWASPH", "F_SKY1", "ADBRICK", "the street");
		case S_WALK:       return Room(t, RF_OUT | RF_CIV, 0, 0, 104, "CWPAVE", "F_SKY1", "ADBRICK", "the sidewalk");
		case S_ALLEY:      return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 72, "MFLR8_1", "F_SKY1", "BRICK6", "the alley");
		case S_COURT:      return Room(t, RF_OUT | RF_CIV | RF_PATROL | RF_RUBBLE, 0, 0, 104, "CWPAVE", "F_SKY1", "ADBRICK", "the courtyard");
		case S_PLAY:       return Room(t, RF_OUT | RF_CIV | RF_RUBBLE, 0, 0, 96, "CWCONCF", "F_SKY1", "ADBRICK", "the playground");
		case S_LOT:        return Room(t, RF_OUT | RF_PATROL | RF_RUBBLE, 0, 0, 88, "FLOOR4_8", "F_SKY1", "BRICK6", "the car lot");
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
		// the public space: the road along the south and down the west side, the sidewalk inside it
		roadR = MakeRoom(S_ROAD);
		Rect(roadR, 0, 0, NX - 1, 0);
		Rect(roadR, 0, 0, 0, NY - 1);
		walkR = MakeRoom(S_WALK);
		Rect(walkR, 1, 1, NX - 1, 1);
		Rect(walkR, 1, 1, 1, NY - 1);
		if (variant == V_UNDER)
		{
			// the elevated line runs over the road: under it the road is covered, the cross street isn't
			int under = MakeRoom(S_UNDER);
			Rect(under, 1, 0, NX - 1, 0);
			rFacT[under] = "CWVIADUC";
			LinkAll(under, roadR, E_WIDE);
			LinkAll(under, walkR, E_WIDE);
		}
		LinkAll(roadR, walkR, E_WIDE);
		// the alley behind the lots and the side passage down to the sidewalk
		alleyR = MakeRoom(S_ALLEY);
		Rect(alleyR, LOT0, ROW_ALLEY, LOT1, ROW_ALLEY);
		Rect(alleyR, COL_PASS, 2, COL_PASS, ROW_ALLEY);
		Link(1, ROW_ALLEY, LOT0, ROW_ALLEY, E_WIDE);
		Link(COL_PASS, 1, COL_PASS, 2, E_WIDE);
		// the Wall closes the block to the north
		for (int i = LOT0; i < NX; i++) cellFac[ROW_WALL * NX + i] = WALL_TEX;

		switch (variant)
		{
		case V_TOWER:
		{
			int t0 = Rand(LOT0 + 2, LOT1 - 6);
			TowerBase(t0);
			Playground(t0 - 2, t0 - 1);
			FillLots(LOT0, t0 - 3, 30);
			FillLots(t0 + 5, LOT1, 30);
			break;
		}
		case V_CORNER:
			FillLots(LOT0, LOT1, 10);
			Hangout();
			break;
		case V_LOT:
		{
			int l0 = Rand(LOT0 + 1, LOT1 - 5);
			ChopLot(l0);
			FillLots(LOT0, l0 - 1, 25);
			FillLots(l0 + 5, LOT1, 25);
			break;
		}
		case V_UNDER:
			FillLots(LOT0, LOT1, 20);
			break;
		}

		// the ways in: the cross street, the alley, the side passage
		AddEntry(CellCenter(0, 1), 0, "the cross street", EK_FRONT, roadR);
		AddEntry(CellCenter(LOT0 + 1, ROW_ALLEY), 0, "the alley", EK_BACK, alleyR);
		AddEntry(CellCenter(COL_PASS, 3), 270, "the side passage", EK_SERVICE, alleyR);
	}

	// The base of a tower over columns t0..t0+4: a fenced courtyard on the street, the lobby behind it.
	void TowerBase(int t0)
	{
		int court = MakeRoom(S_COURT); Rect(court, t0, 2, t0 + 4, 3);
		LinkAll(court, walkR, E_FENCE);
		Link(t0 + 2, 2, t0 + 2, 1, E_WIDE);                // the gate
		int stair = MakeRoom(S_TSTAIR); Rect(stair, t0, 4, t0, 5);
		int sec = MakeRoom(S_SECURITY); Claim(sec, t0 + 1, 4);
		int lobby = MakeRoom(S_LOBBY); Claim(lobby, t0 + 2, 4);
		int mail = MakeRoom(S_MAIL); Claim(mail, t0 + 3, 4);
		int lifts = MakeRoom(S_LIFTS); Rect(lifts, t0 + 1, 5, t0 + 3, 5);
		int sup = MakeRoom(S_SUPER); Rect(sup, t0 + 4, 4, t0 + 4, 5);
		Link(t0 + 2, 3, t0 + 2, 4, E_DOOR);                // the front doors
		Link(t0 + 1, 3, t0 + 1, 4, E_WINDOW);              // the security booth's window onto the court
		LinkRooms(lobby, sec, E_DOOR);
		LinkRooms(lobby, mail, E_ARCH);
		Link(t0 + 2, 4, t0 + 2, 5, E_WIDE);
		LinkRooms(lifts, stair, E_DOOR);
		LinkRooms(lifts, sup, E_DOOR);
		Link(t0 + 4, 5, t0 + 4, ROW_ALLEY, E_DOOR);        // the super's back door
		Link(t0, 5, t0, ROW_ALLEY, E_DOOR);                // the fire door from the stairs
		for (int j = 2; j <= 5; j++) for (int i = t0; i <= t0 + 4; i++) if (At(i, j) >= 0 && !IsOut(At(i, j))) rFacT[At(i, j)] = "ADBRICK";
		AddEntry(CellCenter(t0, 4) + (0, 30), 0, "the tower stairs", EK_ROOF, stair);
	}

	// A fenced playground over columns c0..c1 beside the tower's court.
	void Playground(int c0, int c1)
	{
		if (c0 < LOT0) return;
		int pg = MakeRoom(S_PLAY); Rect(pg, c0, 2, c1, 4);
		LinkAll(pg, walkR, E_FENCE);
		Link(c0, 2, c0, 1, E_WIDE);
		int court = At(c1 + 1, 2);
		if (court >= 0) { LinkAll(pg, court, E_FENCE); Link(c1, 3, c1 + 1, 3, E_WIDE); }
		// a closed building behind it
		for (int i = c0; i <= c1; i++) cellFac[5 * NX + i] = "BRICK12";
	}

	// A chop shop: a chain-link car lot on the street over columns l0..l0+3, the garage behind it, an office.
	void ChopLot(int l0)
	{
		int lot = MakeRoom(S_LOT); Rect(lot, l0, 2, l0 + 3, 3);
		LinkAll(lot, walkR, E_FENCE);
		Link(l0 + 1, 2, l0 + 1, 1, E_WIDE); Link(l0 + 2, 2, l0 + 2, 1, E_WIDE);   // the gate
		int gar = MakeRoom(S_GARAGE); Rect(gar, l0, 4, l0 + 3, 5);
		Link(l0 + 1, 3, l0 + 1, 4, E_WIDE); Link(l0 + 2, 3, l0 + 2, 4, E_WIDE);   // the roll-up door
		int off = MakeRoom(S_OFFICE); Rect(off, l0 + 4, 4, l0 + 4, 5);
		LinkRooms(off, gar, E_DOOR);
		int yard = MakeRoom(S_BACK); rName[yard] = "the parts room"; Rect(yard, l0 + 4, 2, l0 + 4, 3);
		LinkRooms(yard, off, E_DOOR);
		Link(l0, 5, l0, ROW_ALLEY, E_DOOR);
		for (int j = 2; j <= 5; j++) for (int i = l0; i <= l0 + 4; i++) if (At(i, j) >= 0) rFacT[At(i, j)] = "SHAWN02";
	}

	// Lots across columns c0..c1: shops with back rooms, walk-up stairways, and closed buildings.
	void FillLots(int c0, int c1, int closedPct)
	{
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
				for (int j = 2; j <= 5; j++) for (int i = c; i <= x1; i++) cellFac[j * NX + i] = Chance(30) ? "CWPLANK" : front;
			}
			else if (w == 1 && roll < closedPct + 15)
			{
				// a walk-up: a stair hall up to the flats over the shops
				int wu = MakeRoom(S_WALKUP); Rect(wu, c, 2, c, 3);
				Link(c, 2, c, 1, E_DOOR);
				rFacT[wu] = front;
				for (int j = 4; j <= 5; j++) cellFac[j * NX + c] = front;
			}
			else
			{
				static const int SHOPS[] = { S_BODEGA, S_LAUNDROMAT, S_CHECKS, S_TAKEOUT, S_BARBER, S_BOARDED, S_BODEGA, S_BOARDED };
				int shop = MakeRoom(SHOPS[Rand(0, SHOPS.Size() - 1)]);
				int back = MakeRoom(S_BACK);
				Rect(shop, c, 2, x1, 3);
				Rect(back, c, 4, x1, 5);
				LinkRooms(shop, back, E_DOOR);
				int door = c + w / 2;
				Link(door, 2, door, 1, IsType(shop, S_BOARDED) && Chance(50) ? E_ARCH : E_DOOR);
				if (Chance(55)) { int bx = c + Rand(0, w - 1); Link(bx, 5, bx, ROW_ALLEY, E_DOOR); }
				rFacT[shop] = IsType(shop, S_BOARDED) ? "CWPLANK" : front;
				rFacT[back] = front;
			}
			c += w;
		}
	}

	// the crew's back room behind one of the shops
	void Hangout()
	{
		for (int tries = 0; tries < 30; tries++)
		{
			int i = Rand(LOT0, LOT1);
			int r = At(i, 4);
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
				int side = cj[k] == ROW_ALLEY ? 2 : 0;
				if (roll < 30) PutWall("CW_FDumpster", ci[k], cj[k], side, Rand(-40, 40));
				else if (roll < 45) PutWall("CW_FPallet", ci[k], cj[k], side, Rand(-40, 40));
				else if (roll < 55) PutWall("CW_FScrap", ci[k], cj[k], side, Rand(-40, 40));
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
			for (int k = 0; k < ci.Size(); k++) if (cj[k] == 4 && Chance(70)) Car(CellCenter(ci[k], cj[k]), 90, Chance(40) ? "ModernCarDirtyGreen" : "");
			LineWalls("CW_FWorkbench", r, 140, 3); LineWalls("CW_FLocker", r, 160, 2); LineWalls("CW_FScrap", r, 200, 2);
			break;
		}
	}

	override void Outdoors()
	{
		// street lamps on the kerb, parked cars along the road, lights over the alley doors, floodlights on the Wall
		for (int i = LOT0; i < NX; i += 2) PoleLight((colX[i] + colw[i] / 2, rowY[1] + 16), 220);
		for (int j = 3; j < NY; j += 2) PoleLight((colX[1] + 16, rowY[j] + rowh[j] / 2), 220);
		if (variant != V_UNDER)
			for (double x = colX[LOT0] + 80; x < colX[NX - 1]; x += 240)
				if (Chance(60)) Car((x + Rand(-30, 30), rowY[0] + rowh[0] - 64), Chance(50) ? 0 : 180);
		for (double y = rowY[2] + 60; y < rowY[NY - 1]; y += 260)
			if (Chance(50)) Car((colX[0] + colw[0] - 64, y), Chance(50) ? 90 : 270);
		for (int i = LOT0; i < NX; i += 3)
		{
			NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_ALLEY] + 16, 84), 255, 170, 90, 140);
			NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_WALL] - 24, 200), 220, 230, 255, 260);   // the Wall's floodlights
		}
		if (variant == V_UNDER)
			for (int i = 1; i < NX; i += 2) NBC_LightSource.Make((colX[i] + colw[i] / 2, rowY[0] + rowh[0] / 2, 150), 255, 190, 120, 180);
	}
}
