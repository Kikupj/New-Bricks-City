// The basement (PLAN.md §4.4, §6.7, M2c): under the towers of the Bricks.
//
// Template NBC_KB (tools/make_kit_maps.py): a 16 x 12 grid of 128 cells (3.5 m). Ceilings are low (80-88,
// 2.5-2.8 m) except where the space is a hall: the boiler room, the fight hall, the garage ramp.
//
// Variants:
//   service basement   a cross of corridors, the boiler room, the laundry, storage cages, the trash room
//   cook lab           the same basement with one wing turned into the crew's lab
//   fight pit          the Iron Pit's hall: a sunken ring, bleachers, a bar, the bookie's office, the gym
//   parking garage     a pillared deck under the tower, the ramp up to the street, stairs, the booth, cages
//   smugglers' tunnel  an old service tunnel under the Wall, chambers cut off it, the breach at the far end
class NBC_KitBasement : NBC_KitGen
{
	enum EVar { V_SERVICE, V_LAB, V_PIT, V_GARAGE, V_TUNNEL, V_COUNT }
	enum ERoom
	{
		B_CORR, B_STAIR, B_LIFT, B_BOILER, B_LAUNDRY, B_CAGES, B_STORE, B_TRASH, B_ELECTRIC, B_WORKSHOP, B_JUNK,
		B_COOK, B_PACKING, B_CUTTING, B_STASH, B_GUARD,
		B_HALL, B_RING, B_BAR, B_BOOKIE, B_GYM, B_LOCKERS, B_TOILETS, B_CHAMP,
		B_DECK, B_RAMP, B_BOOTH,
		B_TUNNEL, B_CACHE, B_BUNKS, B_PUMP, B_BREACH
	}

	override void Setup()
	{
		for (int i = 0; i < 16; i++) colw.Push(128);
		for (int j = 0; j < 12; j++) rowh.Push(128);
		Grid(16, 12);
		doorTex = "ADDOORS"; jambTex = "SUPPORT3"; edgeTex = "CWCONCW";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "service basement", "cook lab", "fight pit", "parking garage", "smugglers' tunnel" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 3, 1, 4, 3, 1 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int KitRoom(int t) { return MakeRoom(t); }

	int MakeRoom(int t)
	{
		switch (t)
		{
		case B_CORR:     return Room(t, RF_PATROL, 0, 80, 104, "CWCONCF", "ADFLUOR", "CWWALLD", "the corridor");
		case B_STAIR:    return Room(t, RF_NOGUARD, 0, 96, 112, "CWSTAIF", "ADFLUOR", "ADGREY2", "the stairs");
		case B_LIFT:     return Room(t, RF_NOGUARD, 0, 88, 120, "CWCONCF", "ADFLUOR", "CWELEVD", "the freight lift");
		case B_BOILER:   return Room(t, RF_TECH | RF_PATROL, 0, 112, 96, "FLOOR4_8", "ADFLUOR", "SUPPORT3", "the boiler room");
		case B_LAUNDRY:  return Room(t, RF_CIV, 0, 80, 136, "CWTILEF", "CWCEILT", "CWTILEW", "the laundry");
		case B_CAGES:    return Room(t, RF_VALUE | RF_RUBBLE, 0, 80, 88, "CWCONCF", "ADFLUOR", "MIDBARS3", "the storage cages");
		case B_STORE:    return Room(t, RF_RUBBLE, 0, 80, 96, "CWCONCF", "ADFLUOR", "CEMENT7", "a storeroom");
		case B_TRASH:    return Room(t, RF_RUBBLE, 0, 80, 80, "CWCONCF", "ADFLUOR", "CWWALLD", "the trash room");
		case B_ELECTRIC: return Room(t, RF_TECH, 0, 80, 96, "CWCONCF", "ADFLUOR", "SUPPORT3", "the electrical room");
		case B_WORKSHOP: return Room(t, RF_TECH | RF_CIV, 0, 80, 120, "CWCONCF", "ADFLUOR", "CEMENT7", "the super's workshop");
		case B_JUNK:     return Room(t, RF_DARK | RF_RUBBLE, 0, 80, 64, "CWCONCF", "ADFLUOR", "CWWALLD", "a junk room");
		case B_COOK:     return Room(t, RF_TECH | RF_PATROL | RF_RUBBLE, 0, 88, 120, "CWTILEF", "ADFLUOR", "CWWALLD", "the cook room");
		case B_PACKING:  return Room(t, RF_PATROL, 0, 80, 120, "CWCONCF", "ADFLUOR", "CWWALLD", "the packing room");
		case B_CUTTING:  return Room(t, RF_PATROL, 0, 80, 112, "CWTILEF", "ADFLUOR", "CWTILEW", "the cutting room");
		case B_STASH:    return Room(t, RF_VALUE | RF_PATROL, 0, 80, 88, "CWCONCF", "ADFLUOR", "CEMENT7", "the stash");
		case B_GUARD:    return Room(t, RF_PEOPLE | RF_PATROL, 0, 80, 104, "CWCONCF", "ADFLUOR", "CWWALLD", "the guard room");
		case B_HALL:     return Room(t, RF_PATROL | RF_CIV | RF_PEOPLE, 0, 128, 112, "CWCONCF", "ADFLUOR", "CWWALLD", "the fight hall");
		case B_RING:     return Room(t, RF_PATROL, -16, 128, 152, "CWCARP2", "ADFLUOR", "CWWALLD", "the ring");
		case B_BAR:      return Room(t, RF_CIV | RF_PATROL, 0, 88, 120, "FLOOR4_8", "ADFLUOR", "CWWALLD", "the bar");
		case B_BOOKIE:   return Room(t, RF_VALUE | RF_PEOPLE, 0, 80, 120, "CWCARP1", "CWCEILT", "CWWALLD", "the bookie's office");
		case B_GYM:      return Room(t, RF_PATROL, 0, 88, 128, "CWCONCF", "ADFLUOR", "CWWALLD", "the gym");
		case B_LOCKERS:  return Room(t, RF_PATROL, 0, 80, 120, "CWTILEF", "ADFLUOR", "CWTILEW", "the locker room");
		case B_TOILETS:  return Room(t, 0, 0, 80, 120, "CWTILEF", "ADFLUOR", "CWTILEW", "the toilets");
		case B_CHAMP:    return Room(t, RF_PEOPLE | RF_VALUE, 0, 80, 112, "CWCARP1", "CWCEILT", "CWWALL1", "the champion's room");
		case B_DECK:     return Room(t, RF_PATROL | RF_CIV, 0, 80, 96, "CWCONCF", "ADFLUOR", "CWCONCW", "the parking deck");
		case B_RAMP:     return Room(t, RF_PATROL, 0, 112, 104, "CWCONCF", "ADFLUOR", "CWCONCW", "the ramp");
		case B_BOOTH:    return Room(t, RF_PEOPLE, 0, 80, 136, "CWCONCF", "CWCEILT", "ADGREYW", "the attendant's booth");
		case B_TUNNEL:   return Room(t, RF_PATROL | RF_RUBBLE, 0, 88, 72, "FLOOR0_3", "ADFLUOR", "BRICK11", "the old service tunnel");
		case B_CACHE:    return Room(t, RF_VALUE | RF_RUBBLE, 0, 80, 72, "FLOOR4_8", "ADFLUOR", "BRICK11", "a smugglers' cache");
		case B_BUNKS:    return Room(t, RF_PEOPLE | RF_RUBBLE, 0, 80, 80, "FLOOR0_3", "ADFLUOR", "BRICK10", "the bunk room");
		case B_PUMP:     return Room(t, RF_TECH, 0, 96, 88, "FLOOR4_8", "ADFLUOR", "SUPPORT3", "the pump room");
		case B_BREACH:   return Room(t, RF_DARK | RF_RUBBLE | RF_PATROL, 0, 88, 56, "FLOOR0_3", "ADFLUOR", "BRICK10", "the breach under the Wall");
		}
		return Room(t, 0, 0, 80, 96, "CWCONCF", "ADFLUOR", "CEMENT7", "a room");
	}

	void Bag(Array<int> bag, int a, int b = -1, int c = -1, int d = -1, int e = -1, int f = -1)
	{
		bag.Clear(); bag.Push(a);
		if (b >= 0) bag.Push(b); if (c >= 0) bag.Push(c); if (d >= 0) bag.Push(d); if (e >= 0) bag.Push(e); if (f >= 0) bag.Push(f);
	}

	// solid ground: n blocks of 2 x 2 cells left unexcavated
	void Rock(int n, String tex)
	{
		for (int k = 0; k < n; k++)
		{
			int x = Rand(1, NX - 3), y = Rand(1, NY - 3);
			for (int dy = 0; dy < 2; dy++) for (int dx = 0; dx < 2; dx++) if (FreeCell(x + dx, y + dy)) cellFac[(y + dy) * NX + x + dx] = tex;
		}
	}

	// a stair cell at the map's edge opening onto a neighbour, with an entry on it
	int Stairs(int i, int j, int toI, int toJ, String name, int kind)
	{
		int s = MakeRoom(B_STAIR); rName[s] = name;
		Claim(s, i, j);
		Link(i, j, toI, toJ, E_DOOR);
		Vector2 c = CellCenter(i, j), to = CellCenter(toI, toJ);
		AddEntry(c, VectorAngle(to.x - c.x, to.y - c.y), name, kind, s);
		return s;
	}

	// ---------------------------------------------------------------- layout
	override void Layout()
	{
		switch (variant)
		{
		case V_SERVICE: case V_LAB: Service(variant == V_LAB); break;
		case V_PIT: Pit(); break;
		case V_GARAGE: Garage(); break;
		case V_TUNNEL: Tunnel(); break;
		}
	}

	// A cross of corridors (row 5 west-east, column 7 south-north), the big rooms in the quarters.
	void Service(bool lab)
	{
		int corr = MakeRoom(B_CORR);
		Rect(corr, 1, 5, NX - 2, 5);
		Rect(corr, 7, 1, 7, NY - 2);
		Stairs(0, 5, 1, 5, "the stairs down from the lobby", EK_FRONT);
		Stairs(NX - 1, 5, NX - 2, 5, "the back stairs", EK_BACK);
		int lift = MakeRoom(B_LIFT); Claim(lift, 7, NY - 1); Link(7, NY - 1, 7, NY - 2, E_DOOR);
		AddEntry(CellCenter(7, NY - 1), 270, "the freight lift", EK_SERVICE, lift);
		// the boiler room in the north-east quarter, two cells high
		int boiler = MakeRoom(B_BOILER); Rect(boiler, 8, 6, 13, 9);
		LinkRooms(boiler, corr, E_DOOR, CellCenter(10, 5));
		AddEntry(CellCenter(13, 9), 225, "the drain hatch", EK_ROOF, boiler);
		if (lab)
		{
			// the crew's wing in the north-west: cook room, cutting, packing, the stash, a guard room on the corridor
			int cook = MakeRoom(B_COOK); Rect(cook, 2, 6, 5, 8);
			int cut = MakeRoom(B_CUTTING); Rect(cut, 2, 9, 3, 9);
			int pack = MakeRoom(B_PACKING); Rect(pack, 4, 9, 6, 9);
			int stash = MakeRoom(B_STASH); Claim(stash, 6, 8);
			int guard = MakeRoom(B_GUARD); Claim(guard, 6, 6); Claim(guard, 6, 7);
			LinkRooms(guard, corr, E_DOOR); LinkRooms(guard, cook, E_ARCH); LinkRooms(cook, cut, E_DOOR);
			LinkRooms(cut, pack, E_ARCH); LinkRooms(pack, stash, E_DOOR); LinkRooms(cook, stash, E_DOOR);
		}
		else
		{
			int laundry = MakeRoom(B_LAUNDRY); Rect(laundry, 2, 6, 5, 8);
			LinkRooms(laundry, corr, E_DOOR, CellCenter(4, 5));
		}
		// storage cages along the south-east
		int cages = MakeRoom(B_CAGES); Rect(cages, 8, 1, 13, 3);
		LinkRooms(cages, corr, E_DOOR, CellCenter(7, 2));
		Rock(3, "CWCONCW");
		Array<int> bag;
		if (lab) Bag(bag, B_STORE, B_JUNK, B_GUARD, B_STORE, B_ELECTRIC);
		else Bag(bag, B_STORE, B_TRASH, B_ELECTRIC, B_WORKSHOP, B_JUNK, B_STORE);
		Blocks(0, 0, NX - 1, NY - 1, bag, 3, 2, corr);
	}

	// The fight hall in the middle with the sunken ring, a corridor ring round it, rooms off the corridor.
	void Pit()
	{
		int hall = MakeRoom(B_HALL); Rect(hall, 4, 3, 11, 8);
		int ring = MakeRoom(B_RING); Rect(ring, 7, 5, 8, 6);
		LinkAll(ring, hall, E_WIDE);
		int corr = MakeRoom(B_CORR);
		Rect(corr, 3, 2, 12, 2); Rect(corr, 3, 9, 12, 9); Rect(corr, 3, 2, 3, 9); Rect(corr, 12, 2, 12, 9);
		LinkRooms(hall, corr, E_WIDE, CellCenter(7, 2)); LinkRooms(hall, corr, E_WIDE, CellCenter(8, 2));
		LinkRooms(hall, corr, E_DOOR, CellCenter(3, 6)); LinkRooms(hall, corr, E_DOOR, CellCenter(12, 5));
		LinkRooms(hall, corr, E_DOOR, CellCenter(9, 9));
		int bar = MakeRoom(B_BAR); Rect(bar, 4, 1, 7, 1); LinkRooms(bar, corr, E_WIDE, CellCenter(5, 2));
		int bookie = MakeRoom(B_BOOKIE); Rect(bookie, 9, 1, 10, 1); LinkRooms(bookie, corr, E_DOOR);
		int champ = MakeRoom(B_CHAMP); Rect(champ, 13, 8, 14, 9); LinkRooms(champ, corr, E_DOOR);
		Rect(corr, 1, 5, 2, 5); Rect(corr, 13, 3, 14, 3); Claim(corr, 5, 10);   // stubs out to the stairs
		Stairs(0, 5, 1, 5, "the club stairs", EK_FRONT);
		Stairs(NX - 1, 3, NX - 2, 3, "the back stairs", EK_BACK);
		Stairs(5, NY - 1, 5, NY - 2, "the service stairs", EK_SERVICE);
		Rock(2, "CWCONCW");
		Array<int> bag;
		Bag(bag, B_GYM, B_LOCKERS, B_TOILETS, B_STORE, B_GYM, B_STASH);
		Blocks(0, 0, NX - 1, NY - 1, bag, 3, 2, corr);
	}

	// A parking deck under the tower: pillars every four cells, the ramp up to the street, stairs, the booth.
	void Garage()
	{
		int deck = MakeRoom(B_DECK); Rect(deck, 1, 1, NX - 2, NY - 2);
		// pillars on a regular grid, clear of the drive lane in from the ramp (columns 6-8)
		static const int PX[] = { 2, 5, 10, 13 };
		for (int j = 3; j <= NY - 3; j += 4)
			for (int k = 0; k < PX.Size(); k++) { roomOf[j * NX + PX[k]] = -1; cellFac[j * NX + PX[k]] = "CWCONCW"; }
		int ramp = MakeRoom(B_RAMP); Rect(ramp, 6, 0, 8, 0); LinkAll(ramp, deck, E_WIDE);
		AddEntry(CellCenter(7, 0), 90, "the ramp from the street", EK_FRONT, ramp);
		int booth = MakeRoom(B_BOOTH); Claim(booth, 9, 0); Link(9, 0, 8, 0, E_WINDOW); Link(9, 0, 9, 1, E_DOOR);
		Stairs(0, NY - 2, 1, NY - 2, "the stairwell", EK_BACK);
		Stairs(NX - 1, 1, NX - 2, 1, "the stairs from the lobby", EK_ROOF);
		int lift = MakeRoom(B_LIFT); rName[lift] = "the lift lobby"; Rect(lift, 7, NY - 1, 8, NY - 1); LinkAll(lift, deck, E_WIDE);
		AddEntry(CellCenter(7, NY - 1) + (64, 0), 270, "the lift", EK_SERVICE, lift);
		Array<int> bag;
		Bag(bag, B_CAGES, B_ELECTRIC, B_STORE, B_CAGES, B_TRASH);
		Blocks(0, 0, NX - 1, NY - 1, bag, 3, 1, deck);
	}

	// An old service tunnel under the Wall from west to east, chambers cut off it, rock everywhere else.
	void Tunnel()
	{
		int tun = MakeRoom(B_TUNNEL);
		int y = Rand(4, 7);
		for (int i = 0; i < NX; i++)
		{
			Claim(tun, i, y);
			if (i > 0 && i < NX - 1 && Chance(30)) { int ny = clamp(y + (Chance(50) ? 1 : -1), 2, NY - 3); Claim(tun, i, ny); y = ny; Claim(tun, i, y); }
		}
		AddEntry(CellCenter(0, FirstRow(tun, 0)), 0, "the basement door", EK_FRONT, tun);
		int breach = MakeRoom(B_BREACH);
		int by = FirstRow(tun, NX - 1);
		Claim(breach, NX - 1, by);
		if (InGrid(NX - 1, by + 1) && At(NX - 1, by + 1) < 0) Claim(breach, NX - 1, by + 1);
		LinkRooms(breach, tun, E_ARCH);
		AddEntry(CellCenter(NX - 1, by), 180, "the breach under the Wall", EK_BACK, breach);
		int pump = MakeRoom(B_PUMP); Rect(pump, 6, 0, 8, 1); LinkRooms(pump, tun, E_DOOR);
		if (!Adjacent(pump, tun)) { int sh = MakeRoom(B_TUNNEL); rName[sh] = "a side passage"; for (int j = 2; j < NY && At(7, j) != tun; j++) Claim(sh, 7, j); LinkRooms(sh, pump, E_DOOR); LinkRooms(sh, tun, E_ARCH); }
		AddEntry(CellCenter(7, 0), 90, "the drain shaft", EK_ROOF, pump);
		Rock(6, "BRICK10");
		Array<int> bag;
		Bag(bag, B_CACHE, B_BUNKS, B_CACHE, B_GUARD, B_STORE);
		Blocks(0, 0, NX - 1, NY - 1, bag, 2, 2, tun);
		// what Blocks left is rock
		for (int k = 0; k < roomOf.Size(); k++) if (roomOf[k] < 0 && !cellFac[k].Length()) cellFac[k] = "BRICK10";
	}

	// the lowest row of column i in room r (or 0)
	int FirstRow(int r, int i)
	{
		for (int j = 0; j < NY; j++) if (At(i, j) == r) return j;
		return 0;
	}

	// ---------------------------------------------------------------- objectives, light, dressing
	override int ObjScore(int r, int k)
	{
		if (IsType(r, B_STAIR) || IsType(r, B_CORR) || IsType(r, B_DECK) || IsType(r, B_TUNNEL)) return 0;
		if (k == OBJ_STEAL && (IsType(r, B_STASH) || IsType(r, B_CACHE) || IsType(r, B_BOOKIE))) return 180;
		if (k == OBJ_DESTROY && (IsType(r, B_COOK) || IsType(r, B_BOILER) || IsType(r, B_ELECTRIC))) return 160;
		if (k == OBJ_TURN && (IsType(r, B_CHAMP) || IsType(r, B_GUARD) || IsType(r, B_BOOKIE))) return 150;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case B_LAUNDRY: case B_BOOKIE: case B_CHAMP: case B_BOOTH: return 0;
		case B_RING: case B_BAR: return 3;
		}
		return 2;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case B_CORR: case B_TUNNEL:
			for (int k = 0; k < ci.Size(); k++) if (Chance(14)) PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3));
			break;
		case B_BOILER: case B_PUMP:
			for (int k = 0; k < ci.Size(); k++) { if (Chance(40)) PutInCell(Chance(50) ? "CW_FTank" : "CW_FGenerator", ci[k], cj[k], 90 * Rand(0, 3)); PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3)); }
			break;
		case B_LAUNDRY:
			LineWalls("CW_FCounter", r, 64, 10); PutInRoom("CW_FRoundTable", r); PutInRoom("CW_FBin", r);
			break;
		case B_CAGES: case B_STORE: case B_CACHE:
			LineWalls("CW_FShelving", r, 72, 5);
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(60) ? "CW_FCrates" : "CW_FPallet", ci[k], cj[k]);
			break;
		case B_TRASH:
			LineWalls("CW_FDumpster", r, 140, 2); PutInRoom("CW_FScrap", r);
			break;
		case B_ELECTRIC:
			LineWalls("CW_FTransformer", r, 100, 2); LineWalls("CW_FPipes", r, 120, 2);
			break;
		case B_WORKSHOP:
			LineWalls("CW_FWorkbench", r, 110, 3); LineWalls("CW_FShelving", r, 90, 2);
			break;
		case B_JUNK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(50) ? "CW_FScrap" : "CW_FCrates", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		case B_COOK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) PutInCell("CW_FLabBench", ci[k], cj[k], 90 * Rand(0, 1));
			LineWalls("CW_FTank", r, 110, 3); LineWalls("CW_FCrates", r, 140, 2);
			break;
		case B_PACKING: case B_CUTTING:
			for (int k = 0; k < ci.Size(); k++) PutInCell("CW_FWorkbench", ci[k], cj[k], 90);
			LineWalls("CW_FCrates", r, 120, 2);
			break;
		case B_STASH:
			LineWalls("CW_FShelving", r, 64, 4); PutInRoom("CW_FCrates", r);
			break;
		case B_GUARD:
			PutInRoom("CW_FRoundTable", r); LineWalls("CW_FWallTV", r, 120, 1); if (Chance(60)) PutInRoom("CW_FSandbags", r, 90 * Rand(0, 3));
			break;
		case B_HALL:
			// bleachers facing the ring, a few crates and barrels round the walls
			for (int k = 0; k < ci.Size(); k++)
			{
				if (At(ci[k] + 1, cj[k]) != r || At(ci[k] - 1, cj[k]) != r) continue;
				if (cj[k] == 3 || cj[k] == 8) PutInCell("CW_FPew", ci[k], cj[k], cj[k] == 3 ? 90 : 270);
			}
			LineWalls("CW_FCrates", r, 220, 3);
			break;
		case B_BAR:
			LineWalls("CW_FBarCounter", r, 140, 2);
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FStool", ci[k], cj[k]); }
			break;
		case B_BOOKIE:
			PutInRoom("CW_FDeskExec", r); LineWalls("CW_FFileCabinet", r, 60, 3); LineWalls("CW_FWallTV", r, 90, 2);
			break;
		case B_GYM:
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell("CW_FPew", ci[k], cj[k], 90 * Rand(0, 1));
			LineWalls("CW_FLocker", r, 120, 2);
			break;
		case B_LOCKERS:
			LineWalls("CW_FLocker", r, 44, 8); PutInRoom("CW_FPew", r, 0);
			break;
		case B_TOILETS:
			LineWalls("CW_FStalls", r, 90, 2); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case B_CHAMP:
			LineWalls("CW_FSofa", r, 140, 1); LineWalls("CW_FWallTV", r, 160, 1); PutInRoom("CW_FBed", r);
			break;
		case B_DECK:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (ci[k] >= 6 && ci[k] <= 8) continue;     // the drive lane from the ramp
				if (Chance(50)) Car(CellCenter(ci[k], cj[k]), Chance(50) ? 90 : 270);
			}
			break;
		case B_BOOTH:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FWallTV", r, 90, 1);
			break;
		case B_BUNKS:
			LineWalls("CW_FBed", r, 70, 4); PutInRoom("CW_FCrates", r);
			break;
		case B_BREACH:
			for (int k = 0; k < ci.Size(); k++) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
			break;
		}
	}
}
