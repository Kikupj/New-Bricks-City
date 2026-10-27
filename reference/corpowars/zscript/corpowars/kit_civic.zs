// =============================================================================
// Corpo Wars — K05 civic hall kit: union halls, meeting halls, church halls, universities, hospitals, archives.
//
//   row 0        the street                          col 0   a side passage from the street to the car park
//   rows 1-7     the building, cols 1-10:            col 11  the next building (solid)
//                an outer ring of rooms (lobby on the street, back hall on the car park, stairs in two corners),
//                a corridor ring inside it, the big spaces in the middle (a hall, wards, stacks, a lecture theatre)
//   row 8        the car park behind
// Grid: 12 x 176 columns; rows 128, 8 x 176 (genmap KIT_GRIDS["K05"]).
// =============================================================================
class CW_KitCivic : CW_KitGen
{
	enum EVar { V_UNION, V_MEETING, V_CHURCH, V_UNIVERSITY, V_HOSPITAL, V_ARCHIVE, V_COUNT }
	enum ERoom
	{
		C_STREET, C_ALLEY, C_CARPARK, C_CORR, C_LOBBY, C_HALL, C_STAIR, C_OFFICE, C_RECORDS, C_BAR, C_COMMITTEE, C_FUND,
		C_PRINT, C_KITCHEN, C_BATH, C_STORE, C_MEETING, C_CLOAK, C_GAMES, C_VESTRY, C_CLASS, C_CHAPEL, C_LAB, C_SERVER,
		C_SEMINAR, C_COMMON, C_DEAN, C_LECTURE, C_LIBRARY, C_WARD, C_PHARMACY, C_THEATRE, C_MORGUE, C_STAFF, C_SUPPLY,
		C_SECURITY, C_STACKS, C_READING, C_VAULT, C_DIGI, C_PLANT, C_BACKHALL
	}
	const COL_ALLEY = 0;
	const COL_NEXT = 11;
	const ROW_STREET = 0;
	const ROW_CARPARK = 8;

	int streetR, alleyR, parkR, corrR, lobbyR;

	override void Setup()
	{
		for (int i = 0; i < 12; i++) colw.Push(176);
		rowh.Push(128);
		for (int j = 1; j < 9; j++) rowh.Push(176);
		Grid(12, 9);
		doorTex = "DOOR3"; jambTex = "CWTRIM"; edgeTex = "BRICK6";
		bandFloor = -8; bandTex = "AQF025";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "union hall", "meeting hall", "church hall", "university", "hospital", "archive" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 7, 6, 5, 8, 9, 3 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override bool EdgeOpen(int r) { return IsType(r, C_STREET) || IsType(r, C_CARPARK); }
	override int KitRoom(int t) { return MakeRoom(t); }

	int MakeRoom(int t)
	{
		bool hosp = variant == V_HOSPITAL, uni = variant == V_UNIVERSITY, church = variant == V_CHURCH;
		String wall = hosp ? "CWTILEW" : church ? "STUCCO1" : uni ? "CWWALL1" : "CWWALL2";
		String floor = hosp ? "CWTILEF" : church ? "FLOOR4_1" : "CWCARP2";
		switch (t)
		{
		case C_STREET:    return Room(t, RF_OUT | RF_CIV, 0, 0, 120, "AQF050", "F_SKY1", "BRICK6", "the street");
		case C_ALLEY:     return Room(t, RF_OUT | RF_PATROL, 0, 0, 88, "MFLR8_1", "F_SKY1", "BRICK6", "the side passage");
		case C_CARPARK:   return Room(t, RF_OUT | RF_PATROL, 0, 0, 104, "AQF025", "F_SKY1", "BRICK6", "the car park");
		case C_CORR:      return Room(t, RF_PATROL, 0, 120, 150, hosp ? "CWTILEF" : "FLOOR4_1", "CEIL1_1", wall, "the corridor");
		case C_LOBBY:     return Room(t, RF_CIV | RF_PATROL, 0, 160, 176, church ? "FLOOR4_1" : "ADFMARB", "CWCEILL", wall, hosp ? "reception" : "the lobby");
		case C_HALL:      return Room(t, RF_CIV | RF_PATROL | RF_PEOPLE, 0, church ? 256 : 192, 168, church ? "FLOOR4_1" : "ADFWOD2", "CEIL1_1", church ? "STUCCO1" : wall, HallName());
		case C_STAIR:     return Room(t, RF_NOGUARD, 0, 160, 136, "CWSTAIF", "CWCEILD", "ADCONC1", "the stairwell");
		case C_OFFICE:    return Room(t, RF_PEOPLE | RF_CIV | RF_VALUE, 0, 112, 160, "CWCARP2", "CEIL1_1", wall, variant == V_UNION ? "the organiser's office" : "an office");
		case C_RECORDS:   return Room(t, RF_VALUE | RF_TECH, 0, 112, 136, "FLOOR4_1", "CEIL1_1", wall, "the records room");
		case C_BAR:       return Room(t, RF_CIV | RF_PEOPLE, 0, 120, 144, "ADFWOD2", "CEIL1_1", "WOOD1", "the members' bar");
		case C_COMMITTEE: return Room(t, RF_PEOPLE | RF_CIV, 0, 120, 160, "CWCARP2", "CEIL1_1", wall, "the committee room");
		case C_FUND:      return Room(t, RF_VALUE, 0, 104, 136, "FLOOR4_1", "CEIL1_1", "AXW44A", "the strike fund office");
		case C_PRINT:     return Room(t, RF_TECH | RF_CIV, 0, 112, 150, "FLOOR4_8", "CEIL1_1", wall, "the print room");
		case C_KITCHEN:   return Room(t, RF_CIV, 0, 112, 160, "CWTILEF", "CEIL1_1", "CWTILEW", "the kitchen");
		case C_BATH:      return Room(t, 0, 0, 104, 150, "CWTILEF", "CEIL1_1", "CWTILEW", "the toilets");
		case C_STORE:     return Room(t, 0, 0, 112, 120, "FLOOR4_8", "CEIL1_1", wall, "a storeroom");
		case C_MEETING:   return Room(t, RF_PEOPLE | RF_CIV, 0, 120, 160, floor, "CEIL1_1", wall, "a meeting room");
		case C_CLOAK:     return Room(t, RF_CIV, 0, 112, 150, floor, "CEIL1_1", wall, "the cloakroom");
		case C_GAMES:     return Room(t, RF_CIV, 0, 120, 160, "ADFWOD2", "CEIL1_1", wall, "the games room");
		case C_VESTRY:    return Room(t, RF_VALUE | RF_PEOPLE, 0, 120, 144, "FLOOR4_1", "CEIL1_1", "WOOD1", "the vestry");
		case C_CLASS:     return Room(t, RF_CIV, 0, 120, 160, "FLOOR4_1", "CEIL1_1", "STUCCO1", "the classroom");
		case C_CHAPEL:    return Room(t, RF_CIV | RF_PEOPLE, 0, 160, 136, "FLOOR4_1", "CEIL1_1", "STUCCO1", "the side chapel");
		case C_LAB:       return Room(t, RF_TECH | RF_VALUE | RF_PEOPLE, 0, 120, 176, "CWTILEF", "CWCEILL", "CWTILEW", hosp ? "the pathology lab" : "a research lab");
		case C_SERVER:    return Room(t, RF_TECH | RF_VALUE, 0, 112, 120, "CWRAISF", "CWCEILD", "CWSRVWL", "the server room");
		case C_SEMINAR:   return Room(t, RF_CIV, 0, 120, 160, "CWCARP2", "CEIL1_1", wall, "a seminar room");
		case C_COMMON:    return Room(t, RF_CIV, 0, 120, 160, "CWCARP2", "CEIL1_1", wall, "the common room");
		case C_DEAN:      return Room(t, RF_PEOPLE | RF_VALUE, 0, 120, 150, "CWCARP3", "CEIL1_1", "WOOD1", "the dean's office");
		case C_LECTURE:   return Room(t, RF_CIV | RF_PEOPLE | RF_PATROL, 0, 224, 160, "CWCARP2", "CEIL1_1", wall, "the lecture theatre");
		case C_LIBRARY:   return Room(t, RF_CIV | RF_PATROL | RF_VALUE, 0, 192, 150, "CWCARP3", "CEIL1_1", "WOOD1", "the library");
		case C_WARD:      return Room(t, RF_CIV | RF_PEOPLE | RF_PATROL, 0, 128, 168, "CWTILEF", "CWCEILL", "CWTILEW", "a ward");
		case C_PHARMACY:  return Room(t, RF_VALUE, 0, 112, 168, "CWTILEF", "CWCEILL", "CWTILEW", "the pharmacy");
		case C_THEATRE:   return Room(t, RF_PEOPLE | RF_TECH, 0, 128, 200, "CWTILEF", "CWCEILL", "CWTILEW", "the operating theatre");
		case C_MORGUE:    return Room(t, RF_DARK, 0, 112, 104, "AXF06C", "CWCEILD", "AXW44", "the morgue");
		case C_STAFF:     return Room(t, RF_CIV, 0, 112, 160, "CWTILEF", "CEIL1_1", wall, "the staff room");
		case C_SUPPLY:    return Room(t, 0, 0, 112, 136, "CWTILEF", "CEIL1_1", wall, "the supply room");
		case C_SECURITY:  return Room(t, RF_PEOPLE | RF_PATROL, 0, 112, 150, "ADFCAR2", "CEIL1_1", wall, "the security office");
		case C_STACKS:    return Room(t, RF_VALUE | RF_PATROL, 0, 192, 128, "FLOOR4_8", "CEIL5_1", "CWCONCW", "the stacks");
		case C_READING:   return Room(t, RF_CIV | RF_PEOPLE, 0, 160, 160, "CWCARP3", "CEIL1_1", "WOOD1", "the reading room");
		case C_VAULT:     return Room(t, RF_VALUE, 0, 112, 120, "AXF06C", "CWCEILD", "AXW44A", "the vault");
		case C_DIGI:      return Room(t, RF_TECH | RF_PEOPLE, 0, 112, 150, "CWRAISF", "CWCEILD", "AXDEFW", "the scanning room");
		case C_PLANT:     return Room(t, RF_TECH, 0, 128, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", variant == V_MEETING || variant == V_CHURCH ? "the boiler room" : "the plant room");
		case C_BACKHALL:  return Room(t, RF_PATROL, 0, 120, 136, "FLOOR4_8", "CEIL1_1", wall, hosp ? "the ambulance bay" : "the back hall");
		}
		return Room(t, 0, 0, 112, 136, floor, "CEIL1_1", wall, "a room");
	}

	String HallName()
	{
		switch (variant)
		{
		case V_UNION: return "the main hall";
		case V_MEETING: return "the community hall";
		case V_CHURCH: return "the church hall";
		}
		return "the hall";
	}

	void Bag(Array<int> bag, int a, int b, int c, int d, int e, int f, int g, int h, int k = -1, int l = -1)
	{
		bag.Clear();
		bag.Push(a); bag.Push(b); bag.Push(c); bag.Push(d); bag.Push(e); bag.Push(f); bag.Push(g); bag.Push(h);
		if (k >= 0) bag.Push(k);
		if (l >= 0) bag.Push(l);
	}

	override void Layout()
	{
		// ---- outside: the street, the side passage, the car park, the building next door
		streetR = MakeRoom(C_STREET); Rect(streetR, 0, ROW_STREET, NX - 1, ROW_STREET);
		alleyR = MakeRoom(C_ALLEY); Rect(alleyR, COL_ALLEY, 1, COL_ALLEY, ROW_CARPARK - 1);
		parkR = MakeRoom(C_CARPARK); Rect(parkR, 0, ROW_CARPARK, NX - 1, ROW_CARPARK);
		LinkRooms(alleyR, streetR, E_WIDE); LinkRooms(alleyR, parkR, E_WIDE);
		for (int j = 1; j < ROW_CARPARK; j++) cellFac[j * NX + COL_NEXT] = "BRICK7";

		// ---- the corridor ring (grid depth 2) and the middle (depth 3+)
		corrR = MakeRoom(C_CORR);
		for (int j = 1; j < NY - 1; j++) for (int i = 1; i < NX - 1; i++) if (Depth(i, j) == 2) Claim(corrR, i, j);
		BuildMiddle();

		// ---- the outer ring (depth 1): lobby on the street, back hall on the car park, stairs in the north corners
		Array<int> bag;
		switch (variant)
		{
		case V_UNION:      Bag(bag, C_OFFICE, C_RECORDS, C_BAR, C_COMMITTEE, C_FUND, C_PRINT, C_KITCHEN, C_BATH, C_STORE, C_COMMITTEE); break;
		case V_MEETING:    Bag(bag, C_KITCHEN, C_MEETING, C_OFFICE, C_PLANT, C_BATH, C_CLOAK, C_MEETING, C_GAMES, C_STORE); break;
		case V_CHURCH:     Bag(bag, C_VESTRY, C_OFFICE, C_KITCHEN, C_CLASS, C_PLANT, C_BATH, C_CHAPEL, C_MEETING, C_STORE); break;
		case V_UNIVERSITY: Bag(bag, C_LAB, C_OFFICE, C_SERVER, C_SEMINAR, C_COMMON, C_DEAN, C_BATH, C_STORE, C_LAB, C_SEMINAR); break;
		case V_HOSPITAL:   Bag(bag, C_PHARMACY, C_THEATRE, C_RECORDS, C_OFFICE, C_MORGUE, C_LAB, C_STAFF, C_SUPPLY, C_SECURITY, C_BATH); break;
		case V_ARCHIVE:    Bag(bag, C_READING, C_VAULT, C_DIGI, C_OFFICE, C_PLANT, C_SECURITY, C_BATH, C_STORE); break;
		}
		int x0 = 1, x1 = NX - 2, y0 = 1, y1 = ROW_CARPARK - 1;
		// fixed rooms first
		lobbyR = MakeRoom(C_LOBBY); Rect(lobbyR, 4, y0, 6, y0);
		int back = MakeRoom(C_BACKHALL); Rect(back, 5, y1, 6, y1);
		int s1 = MakeRoom(C_STAIR); Claim(s1, x0, y1);
		int s2 = MakeRoom(C_STAIR); Claim(s2, x1, y1);
		int b = Rand(0, bag.Size() - 1);
		for (int pass = 0; pass < 2; pass++)
			for (int j = y0; j <= y1; j++)
				for (int i = x0; i <= x1; i++)
				{
					if (i != x0 && i != x1 && j != y0 && j != y1) continue;
					if (At(i, j) >= 0) continue;
					// a run of up to 3 free ring cells, along the row on the long walls, down the column on the sides
					int r = MakeRoom(bag[b % bag.Size()]); b++;
					Claim(r, i, j);
					int len = Rand(1, 3);
					bool horiz = j == y0 || j == y1;
					for (int n = 1; n < len; n++)
					{
						int ii = horiz ? i + n : i, jj = horiz ? j : j + n;
						if (ii > x1 || jj > y1 || At(ii, jj) >= 0) break;
						if (!horiz && ii != x0 && ii != x1) break;
						Claim(r, ii, jj);
					}
				}
		// the stairs open into the ring room beside them
		LinkRooms(s1, At(x0 + 1, y1), E_DOOR); LinkRooms(s2, At(x1 - 1, y1), E_DOOR);
		// every ring room opens onto the corridor
		for (int r = 0; r < rtype.Size(); r++)
		{
			if (r == streetR || r == alleyR || r == parkR || r == corrR || !CellCount(r) || IsType(r, C_STAIR)) continue;
			if (Adjacent(r, corrR) && LinkKindBetween(r, corrR) < 0) LinkRooms(r, corrR, IsType(r, C_LOBBY) || IsType(r, C_HALL) ? E_WIDE : E_DOOR);
		}
		// the outside: front doors, windows on the street and the side passage, the back doors, a side door
		Link(5, y0, 5, ROW_STREET, E_DOOR);
		Link(4, y0, 4, ROW_STREET, E_WINDOW); Link(6, y0, 6, ROW_STREET, E_WINDOW);
		LinkRooms(back, parkR, variant == V_HOSPITAL ? E_WIDE : E_DOOR);
		for (int i = x0; i <= x1; i++) { int r = At(i, y0); if (r != lobbyR && Chance(45)) Link(i, y0, i, ROW_STREET, E_WINDOW); }   // (the lobby has its own)
		for (int j = y0; j <= y1; j++) { int r = At(x0, j); if (!IsType(r, C_STAIR) && Chance(40)) Link(x0, j, COL_ALLEY, j, E_WINDOW); }
		for (int i = x0; i <= x1; i++) { int r = At(i, y1); if (r != back && !IsType(r, C_STAIR) && Chance(30)) Link(i, y1, i, ROW_CARPARK, E_WINDOW); }
		int sj = Rand(3, 5);
		Link(x0, sj, COL_ALLEY, sj, E_DOOR);
		AddEntry(CellCenter(5, ROW_STREET), 90, "the front doors", EK_FRONT, streetR);
		AddEntry(CellCenter(6, ROW_CARPARK) + (0, 30), 270, "the car park", EK_BACK, parkR);
		AddEntry(CellCenter(COL_ALLEY, sj) + (-30, 0), 0, "the side passage", EK_SERVICE, alleyR);
		AddEntry(CellCenter(x1, y1), 225, "the roof stairs", EK_ROOF, s2);
	}

	// the big spaces in the middle: cols 3..8, rows 3..5
	void BuildMiddle()
	{
		int x0 = 3, x1 = NX - 4, y0 = 3, y1 = NY - 4;
		switch (variant)
		{
		case V_UNIVERSITY:
		{
			int lec = MakeRoom(C_LECTURE); Rect(lec, x0, y0, x0 + 2, y1);
			int lib = MakeRoom(C_LIBRARY); Rect(lib, x0 + 3, y0, x1, y1);
			LinkRooms(lec, corrR, E_DOOR, CellCenter(x0, y0)); LinkRooms(lec, corrR, E_DOOR, CellCenter(x0, y1));
			LinkRooms(lib, corrR, E_WIDE, CellCenter(x1, y0)); LinkRooms(lib, corrR, E_DOOR, CellCenter(x1, y1));
			break;
		}
		case V_HOSPITAL:
		{
			for (int w = 0; w < 3; w++)
			{
				int wd = MakeRoom(C_WARD); Rect(wd, x0 + w * 2, y0, x0 + w * 2 + 1, y1);
				LinkRooms(wd, corrR, E_DOOR, CellCenter(x0 + w * 2, y0)); LinkRooms(wd, corrR, E_DOOR, CellCenter(x0 + w * 2 + 1, y1));
			}
			break;
		}
		case V_ARCHIVE:
		{
			for (int s = 0; s < 2; s++)
			{
				int st = MakeRoom(C_STACKS); Rect(st, x0 + s * 3, y0, x0 + s * 3 + 2, y1);
				LinkRooms(st, corrR, E_DOOR, CellCenter(x0 + s * 3 + 1, y0)); LinkRooms(st, corrR, E_DOOR, CellCenter(x0 + s * 3 + 1, y1));
			}
			break;
		}
		default:
		{
			int hall = MakeRoom(C_HALL); Rect(hall, x0, y0, x1, y1);
			LinkRooms(hall, corrR, E_WIDE, CellCenter(4, y0)); LinkRooms(hall, corrR, E_WIDE, CellCenter(7, y0));
			LinkRooms(hall, corrR, E_DOOR, CellCenter(x0, 4)); LinkRooms(hall, corrR, E_DOOR, CellCenter(x1, 4));
			break;
		}
		}
	}

	override int ObjScore(int r, int k)
	{
		if (variant == V_UNION && k == OBJ_STEAL && IsType(r, C_FUND)) return 120;
		if (variant == V_ARCHIVE && k == OBJ_STEAL && IsType(r, C_VAULT)) return 120;
		if (variant == V_HOSPITAL && k == OBJ_STEAL && IsType(r, C_PHARMACY)) return 110;
		if (IsType(r, C_STAIR) || IsType(r, C_BACKHALL)) return 0;
		if (IsType(r, C_HALL) || IsType(r, C_WARD) || IsType(r, C_LECTURE)) return k == OBJ_TURN ? 30 : 0;   // too public
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case C_LOBBY: case C_HALL: case C_BAR: case C_CHAPEL: case C_READING: case C_LIBRARY: return 3;
		case C_STORE: case C_PLANT: case C_STACKS: case C_MORGUE: case C_STAIR: case C_BACKHALL: return 2;
		case C_SERVER: case C_DIGI: return 1;
		}
		return 0;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case C_HALL:
			if (variant == V_MEETING) { for (int k = 0; k < ci.Size(); k++) if (cj[k] != 3 && Chance(60)) PutInCell("CW_FRoundTable", ci[k], cj[k]); }
			else Rows("CW_FPew", r, 56, true, 270, 40);
			break;
		case C_LECTURE:
			Rows("CW_FPew", r, 52, true, 0, 30);
			break;
		case C_LIBRARY: case C_STACKS:
			for (int k = 0; k < ci.Size(); k++) { Put("CW_FBookshelf", CellCenter(ci[k], cj[k]) + (-44, 0), 0); Put("CW_FBookshelf", CellCenter(ci[k], cj[k]) + (44, 0), 0); }
			break;
		case C_WARD:
			LineWalls("CW_FBed", r, 72, 8);
			break;
		case C_LOBBY:
			PutInRoom("CW_FReception", r, 90); PutInRoom("CW_FSofa", r); PutInRoom("CW_FPlanter", r);
			break;
		case C_OFFICE: case C_DEAN: case C_FUND:
			PutInRoom(rtype[r] == C_DEAN ? "CW_FDeskExec" : "CW_FDeskWork", r); LineWalls("CW_FFileCabinet", r, 60, 3); LineWalls("CW_FBookshelf", r, 90, 1);
			break;
		case C_RECORDS: case C_VAULT:
			LineWalls("CW_FFileCabinet", r, 40, 8);
			break;
		case C_BAR:
			LineWalls("CW_FBarCounter", r, 200, 1); PutInRoom("CW_FRoundTable", r); PutInRoom("CW_FStool", r); PutInRoom("CW_FStool", r);
			break;
		case C_COMMITTEE: case C_MEETING: case C_SEMINAR:
			PutInRoom("CW_FConfTable", r); LineWalls("CW_FWhiteboard", r, 200, 1);
			break;
		case C_PRINT:
			LineWalls("CW_FCopier", r, 70, 3); PutInRoom("CW_FWorkbench", r);
			break;
		case C_KITCHEN: case C_STAFF: case C_COMMON:
			LineWalls("CW_FCounter", r, 120, 2); PutInRoom("CW_FRoundTable", r); LineWalls("CW_FVending", r, 120, 1);
			break;
		case C_BATH:
			LineWalls("CW_FStalls", r, 90, 2); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case C_STORE: case C_SUPPLY: case C_CLOAK:
			LineWalls("CW_FShelving", r, 70, 4);
			break;
		case C_GAMES:
			PutInRoom("CW_FRoundTable", r); PutInRoom("CW_FSofa", r);
			break;
		case C_VESTRY: case C_CHAPEL:
			Rows("CW_FPew", r, 60, true, 270, 4); LineWalls("CW_FCredenza", r, 120, 1);
			break;
		case C_CLASS:
			Rows("CW_FDeskWork", r, 70, true, 270, 6); LineWalls("CW_FWhiteboard", r, 200, 1);
			break;
		case C_LAB: case C_PHARMACY:
			LineWalls("CW_FLabBench", r, 110, 3); LineWalls("CW_FShelving", r, 90, 2);
			break;
		case C_SERVER:
			LineWalls("CW_FServerRack", r, 30, 8);
			break;
		case C_THEATRE:
			PutInRoom("CW_FBed", r); LineWalls("CW_FLabBench", r, 120, 2); LineWalls("CW_FWallTV", r, 120, 1);
			break;
		case C_MORGUE:
			LineWalls("CW_FLocker", r, 44, 6); PutInRoom("CW_FBed", r);
			break;
		case C_SECURITY:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FWallTV", r, 90, 3); LineWalls("CW_FLocker", r, 60, 2);
			break;
		case C_READING:
			for (int k = 0; k < ci.Size(); k++) PutInCell("CW_FConfTable", ci[k], cj[k], 90);
			LineWalls("CW_FBookshelf", r, 70, 4);
			break;
		case C_DIGI:
			LineWalls("CW_FDeskCode", r, 80, 3); LineWalls("CW_FServerRack", r, 60, 2);
			break;
		case C_PLANT:
			for (int k = 0; k < ci.Size(); k++) PutInCell(Chance(50) ? "CW_FGenerator" : "CW_FAcUnit", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		case C_BACKHALL:
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		}
	}

	override void Outdoors()
	{
		for (int i = 1; i < NX; i += 3) PoleLight((colX[i] + colw[i] / 2, rowY[ROW_STREET] + 24), 240);
		for (int i = 2; i < NX; i += 4) PoleLight((colX[i] + colw[i] / 2, rowY[ROW_CARPARK] + rowh[ROW_CARPARK] - 24), 220, 230, 240, 255);
		for (int i = 1; i < NX - 1; i++) if (i < 4 || i > 7) { if (Chance(55)) Car(CellCenter(i, ROW_CARPARK) + (0, 20), Chance(50) ? 90 : 270); }
		for (int i = 0; i < NX; i++) if ((i < 3 || i > 7) && Chance(30)) Car((colX[i] + colw[i] / 2, rowY[ROW_STREET] + rowh[ROW_STREET] - 40), Chance(50) ? 0 : 180);
	}
}
