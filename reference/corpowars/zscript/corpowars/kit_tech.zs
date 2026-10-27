// =============================================================================
// Corpo Wars — K06 tech interior kit: data centres and labs (building-types.md, group 2)
// Plan: a ring of rooms along the outer walls, a corridor ring inside it, and the big spaces in the middle
// (server halls, or clean-room blocks behind airlocks). Stair cores in the corners.
// Grid 12 x 10 cells of 176 (genmap KIT_GRIDS["K06"]).
// =============================================================================
class CW_KitTech : CW_KitGen
{
	enum EVar { V_DC, V_LAB, V_COUNT }
	enum ERoom
	{
		T_CORR, T_LOBBY, T_SECURITY, T_NOC, T_HALL, T_COOLING, T_POWER, T_DOCK, T_VAULT, T_STAFF, T_BATH,
		T_STORE, T_STAIR, T_LAB, T_AIRLOCK, T_COLD, T_DECON, T_OFFICE, T_CHANGE, T_PLANT
	}

	override void Setup()
	{
		for (int i = 0; i < 12; i++) colw.Push(176);
		for (int j = 0; j < 10; j++) rowh.Push(176);
		Grid(12, 10);
		doorTex = "CWDOORS"; jambTex = "CWTRIM"; edgeTex = "CWCONCW";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName() { return variant == V_LAB ? "lab" : "data centre"; }
	override int Bystanders() { return variant == V_LAB ? 5 : 3; }

	int MakeRoom(int t)
	{
		bool lab = variant == V_LAB;
		String wall = lab ? "CWWALL1" : "CWWALL2", floor = lab ? "CWTILEF" : "CWRAISF", ceil = "CWCEILT";
		switch (t)
		{
		case T_CORR:     return Room(t, RF_PATROL, 0, 104, 160, lab ? "CWTILEF" : "ADFCAR2", ceil, wall, "corridor");
		case T_LOBBY:    return Room(t, RF_CIV, 0, 128, 176, "ADFMARB", "CWCEILL", "AXCITY17", "lobby");
		case T_SECURITY: return Room(t, RF_PEOPLE | RF_PATROL, 0, 104, 150, "ADFCAR2", ceil, wall, "security office");
		case T_NOC:      return Room(t, RF_PEOPLE | RF_TECH | RF_CIV, 0, 112, 120, "ADFCAR2", "CWCEILD", "AXDEFW", "network operations centre");
		case T_HALL:     return Room(t, RF_TECH | RF_PATROL | RF_VALUE, 0, 128, 112, "CWRAISF", "CWCEILD", "CWSRVWL", "server hall");
		case T_COOLING:  return Room(t, RF_TECH, 0, 128, 128, "CWCONCF", "CWCEILD", "CWCONCW", "cooling plant");
		case T_POWER:    return Room(t, RF_TECH, 0, 120, 128, "CWCONCF", "CWCEILD", "AXW44", "power room");
		case T_DOCK:     return Room(t, RF_PATROL, 0, 128, 150, "CWCONCF", "CWCEILD", "CWCONCW", "loading dock");
		case T_VAULT:    return Room(t, RF_VALUE, 0, 104, 120, "AXF06C", "CWCEILD", "AXW44A", lab ? "specimen vault" : "cage vault");
		case T_STAFF:    return Room(t, RF_CIV, 0, 104, 168, "CWTILEF", ceil, "CWWALL1", "staff room");
		case T_BATH:     return Room(t, 0, 0, 96, 160, "CWTILEF", ceil, "CWTILEW", "restrooms");
		case T_STORE:    return Room(t, 0, 0, 104, 128, "CWCONCF", "CWCEILD", "CWCONCW", "stores");
		case T_STAIR:    return Room(t, RF_NOGUARD, 0, 128, 136, "CWSTAIF", "CWCEILD", "ADCONC1", "fire stairs");
		case T_LAB:      return Room(t, RF_PEOPLE | RF_VALUE | RF_CIV, 0, 112, 176, "CWTILEF", "CWCEILL", "CWTILEW", "clean room");
		case T_AIRLOCK:  return Room(t, RF_NOGUARD, 0, 96, 168, "AXF06C", "CWCEILL", "AXW44", "airlock");
		case T_COLD:     return Room(t, RF_VALUE | RF_TECH, 0, 104, 136, "AXF06C", "CWCEILD", "AXW44A", "cold storage");
		case T_DECON:    return Room(t, 0, 0, 96, 168, "CWTILEF", "CWCEILL", "CWTILEW", "decon");
		case T_OFFICE:   return Room(t, RF_PEOPLE | RF_CIV, 0, 104, 160, "CWCARP2", ceil, "CWWALL1", "offices");
		case T_CHANGE:   return Room(t, RF_CIV, 0, 96, 160, "CWTILEF", ceil, "CWTILEW", "changing room");
		case T_PLANT:    return Room(t, RF_TECH, 0, 120, 128, "CWCONCF", "CWCEILD", "CWCONCW", "plant room");
		}
		return Room(t, 0, 0, 104, 128, floor, ceil, wall, "room");
	}

	override void Layout()
	{
		bool lab = variant == V_LAB;
		// corridor ring
		int corr = MakeRoom(T_CORR);
		for (int j = 0; j < NY; j++) for (int i = 0; i < NX; i++) if (Depth(i, j) == 1) Claim(corr, i, j);
		// the middle: server halls or clean-room blocks
		if (!lab)
		{
			int cuts = Rand(1, 2);
			int x0 = 2;
			for (int h = 0; h <= cuts; h++)
			{
				int x1 = h == cuts ? NX - 3 : x0 + (NX - 4) / (cuts + 1) - 1;
				int hall = MakeRoom(T_HALL);
				Rect(hall, x0, 2, x1, NY - 3);
				LinkRooms(hall, corr, E_DOOR, CellCenter(x0, 2));
				LinkRooms(hall, corr, E_DOOR, CellCenter(x1, NY - 3));
				x0 = x1 + 1;
			}
		}
		else
		{
			// 2 x 3 blocks; the cell touching the corridor is the block's airlock
			static const int kinds[] = { T_LAB, T_LAB, T_COLD, T_LAB, T_DECON, T_LAB, T_OFFICE, T_LAB };
			int n = 0;
			for (int bx = 2; bx + 1 <= NX - 3; bx += 2)
				for (int by = 0; by < 2; by++)
				{
					int y0 = by ? NY - 5 : 2, y1 = y0 + 2;
					int t = kinds[(n + Rand(0, 7)) % 8];
					n++;
					int room = MakeRoom(t);
					Rect(room, bx, y0, bx + 1, y1);
					if (t == T_LAB || t == T_COLD)
					{
						int ai = bx + Rand(0, 1), aj = by ? y1 : y0;
						int lock = MakeRoom(T_AIRLOCK);
						Claim(lock, ai, aj);
						Link(ai, aj, ai, by ? aj + 1 : aj - 1, E_DOOR);
						Link(ai, aj, ai, by ? aj - 1 : aj + 1, E_DOOR);
					}
					else LinkRooms(room, corr, E_DOOR);
				}
		}
		// the outer ring: runs of 1-3 cells from a room programme
		Array<int> ci, cj;
		Ring(0, ci, cj);
		Array<int> bag;
		if (!lab) { static const int dcBag[] = { T_NOC, T_COOLING, T_POWER, T_VAULT, T_SECURITY, T_STAFF, T_BATH, T_STORE, T_COOLING, T_POWER, T_OFFICE, T_STORE, T_PLANT, T_STAFF }; for (int k = 0; k < dcBag.Size(); k++) bag.Push(dcBag[k]); }
		else { static const int labBag[] = { T_OFFICE, T_VAULT, T_SECURITY, T_CHANGE, T_STAFF, T_BATH, T_STORE, T_PLANT, T_OFFICE, T_COLD, T_OFFICE, T_STORE, T_STAFF, T_POWER }; for (int k = 0; k < labBag.Size(); k++) bag.Push(labBag[k]); }
		int lobbyAt = (NX - 1) / 2 - 1;            // south wall, middle
		int dockAt = NX + (NY - 2) / 2;            // east wall, middle (index along the ring)
		int k = 0, b = Rand(0, bag.Size() - 1);
		bool lobbyDone = false, dockDone = false;
		while (k < ci.Size())
		{
			int i = ci[k], j = cj[k];
			bool corner = (i == 0 || i == NX - 1) && (j == 0 || j == NY - 1);
			if (corner) { Claim(MakeRoom(T_STAIR), i, j); k++; continue; }
			int len = Rand(1, 3), t;
			if (!lobbyDone && k + 3 > lobbyAt) { t = T_LOBBY; len = 3; lobbyDone = true; }
			else if (!dockDone && k + len > dockAt) { t = T_DOCK; len = 2; dockDone = true; }
			else { t = bag[b % bag.Size()]; b++; }
			int room = MakeRoom(t);
			for (int n = 0; n < len && k < ci.Size(); n++)
			{
				int ii = ci[k], jj = cj[k];
				if ((ii == 0 || ii == NX - 1) && (jj == 0 || jj == NY - 1)) break;
				Claim(room, ii, jj);
				k++;
			}
			LinkRooms(room, corr, t == T_DOCK || t == T_LOBBY ? E_WIDE : E_DOOR);
		}
		// entries: front doors, the loading dock, a fire stair to the street, the roof hatch
		for (int e = 0; e < ci.Size(); e++)
		{
			int r = At(ci[e], cj[e]);
			if (IsType(r, T_LOBBY) && OuterSide(ci[e], cj[e]) == 3 && !FoundEntry(EK_FRONT)) WallEntry(ci[e], cj[e], 3, "the front doors", EK_FRONT);
			if (IsType(r, T_DOCK) && !FoundEntry(EK_SERVICE)) WallEntry(ci[e], cj[e], OuterSide(ci[e], cj[e]), "the loading dock", EK_SERVICE);
		}
		int s1 = At(0, NY - 1), s2 = At(NX - 1, NY - 1);
		LinkRooms(s1, At(1, NY - 1), E_DOOR); LinkRooms(s2, At(NX - 2, NY - 1), E_DOOR);
		LinkRooms(At(0, 0), At(1, 0), E_DOOR); LinkRooms(At(NX - 1, 0), At(NX - 2, 0), E_DOOR);
		AddEntry(CellCenter(0, NY - 1), 315, "the fire stairs", EK_BACK);
		AddEntry(CellCenter(NX - 1, NY - 1), 225, "the roof hatch", EK_ROOF);
	}

	bool FoundEntry(int kind) { for (int e = 0; e < enKind.Size(); e++) if (enKind[e] == kind) return true; return false; }

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case T_HALL: case T_COOLING: case T_POWER: case T_DOCK: case T_STORE: case T_PLANT: return 2;
		case T_LOBBY: case T_STAFF: return 3;
		}
		return 0;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case T_HALL:
			for (int k = 0; k < ci.Size(); k++)
			{
				Vector2 c = CellCenter(ci[k], cj[k]);
				for (int x = -1; x <= 1; x++) Put("CW_FServerRack", c + (x * 26, 0), 90);
			}
			break;
		case T_NOC:
			for (int k = 0; k < ci.Size(); k++)
			{
				Vector2 c = CellCenter(ci[k], cj[k]);
				Put("CW_FDeskCode", c + (-30, 0), 90); Put("CW_FDeskCode", c + (30, 0), 90);
				for (int d = 0; d < 4; d++) PutWall("CW_FWallTV", ci[k], cj[k], d);
			}
			break;
		case T_COOLING:
			for (int k = 0; k < ci.Size(); k++) { PutInCell("CW_FTank", ci[k], cj[k]); PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3)); }
			break;
		case T_POWER: case T_PLANT:
			for (int k = 0; k < ci.Size(); k++) { PutInCell(Chance(50) ? "CW_FGenerator" : "CW_FTransformer", ci[k], cj[k], 90 * Rand(0, 3)); PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3)); }
			break;
		case T_DOCK:
			for (int k = 0; k < ci.Size(); k++) { PutInCell(Chance(50) ? "CW_FCrates" : "CW_FPallet", ci[k], cj[k]); PutWall("CW_FShelving", ci[k], cj[k], Rand(0, 3)); }
			break;
		case T_VAULT:
			LineWalls("CW_FServerRack", r, 60, 6);
			LineWalls("CW_FFileCabinet", r, 48, 4);
			break;
		case T_SECURITY:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FLocker", r, 60, 2); LineWalls("CW_FWallTV", r, 96, 3);
			break;
		case T_LOBBY:
			PutInRoom("CW_FReception", r, 90); PutInRoom("CW_FSofa", r); PutInRoom("CW_FPlanter", r); PutInRoom("CW_FPlanter", r);
			break;
		case T_STAFF:
			PutInRoom("CW_FRoundTable", r); PutInRoom("CW_FRoundTable", r); LineWalls("CW_FVending", r, 80, 2); LineWalls("CW_FCounter", r, 120, 1);
			break;
		case T_BATH:
			LineWalls("CW_FStalls", r, 90, 2); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case T_STORE:
			LineWalls("CW_FShelving", r, 80, 6);
			break;
		case T_LAB:
			for (int k = 0; k < ci.Size(); k++) Put("CW_FLabBench", CellCenter(ci[k], cj[k]), 90 * Rand(0, 1));
			LineWalls("CW_FShelving", r, 120, 2);
			break;
		case T_COLD:
			LineWalls("CW_FTank", r, 90, 4); LineWalls("CW_FShelving", r, 90, 3);
			break;
		case T_DECON: case T_CHANGE:
			LineWalls("CW_FLocker", r, 60, 4); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case T_OFFICE:
			for (int k = 0; k < ci.Size(); k++) { PutInCell("CW_FDeskWork", ci[k], cj[k], 90 * Rand(0, 3)); PutWall("CW_FFileCabinet", ci[k], cj[k], Rand(0, 3)); }
			break;
		}
	}
}
