// =============================================================================
// Corpo Wars — K03 industrial lot kit: warehouses, sea docks, fabrication plants, power plants,
// substations, industrial parks (rail yards, test ranges, antenna farms), salvage yards, construction sites.
//
//   rows 1-8  the fenced lot: buildings on it, the yard around them (row 1 and the side columns stay yard,
//             so the yard is always one connected space)
//   row 0     the road outside the fence: the main gate and a side gate open onto it
// Grid: 11 x 256 columns; rows 192, 8 x 256 (genmap KIT_GRIDS["K03"]).
// =============================================================================
class CW_KitIndustrial : CW_KitGen
{
	enum EVar { V_WAREHOUSE, V_DOCK, V_FAB, V_PLANT, V_SUBSTATION, V_PARK, V_SALVAGE, V_CONSTRUCTION, V_COUNT }
	enum ERoom
	{
		I_ROAD, I_YARD, I_HALL, I_OFFICE, I_COLD, I_GATEHOUSE, I_WATER, I_QUAY, I_DECK, I_CUSTOMS, I_STORE, I_QA,
		I_CONTROL, I_POWER, I_TURBINE, I_SWITCHYARD, I_HUT, I_VAULT, I_WORKSHOP, I_CRUSHER, I_TRAILER, I_SLAB, I_RANGE,
		I_BUNKROOM
	}
	const ROW_ROAD = 0;

	int roadR, yardR;
	int gateCol;

	override void Setup()
	{
		for (int i = 0; i < 11; i++) colw.Push(256);
		rowh.Push(192);
		for (int j = 1; j < 9; j++) rowh.Push(256);
		Grid(11, 9);
		doorTex = "DOOR3"; jambTex = "SUPPORT3"; edgeTex = "SHAWN02";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "warehouse", "sea dock", "fabrication plant", "power plant", "substation", "industrial park", "salvage yard", "construction site" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 5, 6, 6, 4, 1, 4, 2, 5 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override bool EdgeOpen(int r) { return IsType(r, I_ROAD) || IsType(r, I_WATER) || IsType(r, I_DECK) || IsType(r, I_QUAY); }

	int MakeRoom(int t)
	{
		switch (t)
		{
		case I_ROAD:       return Room(t, RF_OUT, -8, 0, 104, "AQF025", "F_SKY1", "SHAWN02", "the road");
		case I_YARD:       return Room(t, RF_OUT | RF_PATROL | RF_CIV, 0, 0, 104, variant == V_SALVAGE || variant == V_CONSTRUCTION ? "FLAT10" : "FLOOR4_8", "F_SKY1", "SHAWN02", "the yard");
		case I_HALL:       return Room(t, RF_PATROL | RF_CIV | RF_TECH, 0, 256, 120, "CWCONCF", "CEIL5_1", "SHAWN02", HallName());
		case I_OFFICE:     return Room(t, RF_VALUE | RF_PEOPLE | RF_CIV, 0, 112, 150, "CWCARP2", "CEIL1_1", "CWWALL2", "the site office");
		case I_COLD:       return Room(t, RF_VALUE, 0, 128, 136, "AXF06C", "CEIL5_1", "AXW44", "the cold room");
		case I_GATEHOUSE:  return Room(t, RF_PATROL | RF_PEOPLE, 0, 112, 160, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the gatehouse");
		case I_WATER:      return Room(t, RF_OUT | RF_WATER, -64, 0, 96, "FWATER1", "F_SKY1", "SUPPORT3", "the harbour");
		case I_QUAY:       return Room(t, RF_OUT | RF_PATROL, 0, 0, 104, "AQF051", "F_SKY1", "SUPPORT3", "the quay");
		case I_DECK:       return Room(t, RF_OUT | RF_PATROL | RF_VALUE, 16, 0, 96, "STEP2", "F_SKY1", "METAL", "the ship");
		case I_CUSTOMS:    return Room(t, RF_VALUE | RF_PEOPLE, 0, 112, 150, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the customs shed");
		case I_STORE:      return Room(t, RF_VALUE, 0, 160, 128, "CWCONCF", "CEIL5_1", "SHAWN02", "the stores");
		case I_QA:         return Room(t, RF_VALUE | RF_PEOPLE | RF_CIV, 0, 112, 168, "CWTILEF", "CWCEILL", "CWWALL1", "the QA lab");
		case I_CONTROL:    return Room(t, RF_TECH | RF_PEOPLE, 0, 112, 136, "CWRAISF", "CWCEILD", "AXDEFW", "the control room");
		case I_POWER:      return Room(t, RF_TECH, 0, 144, 128, "CWCONCF", "CEIL5_1", "AXW44", "the power room");
		case I_TURBINE:    return Room(t, RF_TECH | RF_PATROL, 0, 288, 128, "CWCONCF", "CEIL5_1", "SHAWN02", "the turbine hall");
		case I_SWITCHYARD: return Room(t, RF_OUT | RF_TECH | RF_PATROL, 0, 0, 112, "FLAT10", "F_SKY1", "SHAWN02", "the switchyard");
		case I_HUT:        return Room(t, RF_TECH | RF_VALUE, 0, 112, 136, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the control hut");
		case I_VAULT:      return Room(t, RF_VALUE, 0, 104, 120, "AXF06C", "CEIL1_1", "AXW44A", "the cable vault");
		case I_WORKSHOP:   return Room(t, RF_TECH | RF_CIV, 0, 160, 136, "CWCONCF", "CEIL5_1", "SHAWN02", "the workshop");
		case I_CRUSHER:    return Room(t, RF_TECH, 0, 192, 112, "FLOOR4_8", "CEIL5_1", "METAL", "the crusher shed");
		case I_TRAILER:    return Room(t, RF_VALUE | RF_PEOPLE, 0, 96, 150, "FLOOR4_1", "CEIL1_1", "AXDW07B", "the office trailer");
		case I_SLAB:       return Room(t, RF_OUT | RF_PATROL | RF_CIV, 16, 0, 112, "CWCONCF", "F_SKY1", "CEMENT7", "the slab");
		case I_RANGE:      return Room(t, RF_OUT | RF_PATROL, 0, 0, 120, "FLAT10", "F_SKY1", "CEMENT7", "the range");
		case I_BUNKROOM:   return Room(t, RF_CIV | RF_PEOPLE, 0, 112, 150, "FLOOR4_1", "CEIL1_1", "CEMENT7", "the crew room");
		}
		return Room(t, 0, 0, 160, 128, "CWCONCF", "CEIL5_1", "SHAWN02", "shed");
	}

	String HallName()
	{
		switch (variant)
		{
		case V_WAREHOUSE: return "the warehouse";
		case V_DOCK: return "the dock warehouse";
		case V_FAB: return "the fab floor";
		case V_PARK: return "a factory shed";
		}
		return "the shed";
	}

	// A building of w x h cells at (i0, j0) if the ground is free yard; returns the room or -1.
	int Building(int t, int i0, int j0, int w, int h, String face = "")
	{
		if (i0 < 1 || j0 < 2 || i0 + w - 1 > NX - 2 || j0 + h - 1 > NY - 1) return -1;
		for (int j = j0; j < j0 + h; j++) for (int i = i0; i < i0 + w; i++) if (At(i, j) != yardR) return -1;
		int r = MakeRoom(t);
		Rect(r, i0, j0, i0 + w - 1, j0 + h - 1);
		rFacT[r] = face.Length() ? face : (t == I_TRAILER || t == I_GATEHOUSE || t == I_HUT ? "CEMENT7" : "SHAWN02");
		return r;
	}
	// try a few spots
	int Place(int t, int w, int h, String face = "")
	{
		for (int tries = 0; tries < 60; tries++)
		{
			int r = Building(t, Rand(1, NX - 1 - w), Rand(2, NY - h), w, h, face);
			if (r >= 0) return r;
		}
		return -1;
	}
	// a way in from the yard: personnel doors, plus roller doors (wide) on big sheds
	void Doors(int r, int rollers = 0)
	{
		if (r < 0) return;
		LinkRooms(r, yardR, E_DOOR);
		for (int k = 0; k < rollers; k++) LinkRooms(r, yardR, E_WIDE);
	}

	override void Layout()
	{
		// the band round the map: more road, or open water behind a dock
		if (variant == V_DOCK) { bandFloor = -64; bandTex = "FWATER1"; } else { bandFloor = -8; bandTex = "AQF025"; }
		// ---- outside the fence, the lot inside it
		roadR = MakeRoom(I_ROAD);
		Rect(roadR, 0, ROW_ROAD, NX - 1, ROW_ROAD);
		yardR = MakeRoom(I_YARD);
		Rect(yardR, 0, 1, NX - 1, NY - 1);
		gateCol = Rand(2, NX - 3);
		// the gatehouse beside the main gate, a window onto the road
		int gh = MakeRoom(I_GATEHOUSE);
		int gi = gateCol + (Chance(50) ? 1 : -1);
		Claim(gh, gi, 1);
		LinkAll(roadR, yardR, E_FENCE);
		Link(gateCol, ROW_ROAD, gateCol, 1, E_WIDE);
		int side = gateCol > NX / 2 ? Rand(0, 1) : NX - 1 - Rand(0, 1);
		Link(side, ROW_ROAD, side, 1, E_WIDE);
		Link(gi, 1, gateCol, 1, E_DOOR);
		Link(gi, ROW_ROAD, gi, 1, E_WINDOW);
		AddEntry(CellCenter(gateCol, ROW_ROAD) + (0, -40), 90, "the main gate", EK_FRONT);
		AddEntry(CellCenter(side, ROW_ROAD) + (0, -40), 90, "the side gate", EK_BACK);

		switch (variant)
		{
		case V_WAREHOUSE:
		{
			int wh = Place(I_HALL, 4, 3);
			Doors(wh, 2);
			int off = Place(I_OFFICE, 2, 1, "CEMENT7"); Doors(off);
			int cold = Place(I_COLD, 1, 1, "CEMENT7"); Doors(cold);
			int st = Place(I_STORE, 2, 1); Doors(st, 1);
			if (wh >= 0 && off >= 0 && Adjacent(wh, off)) LinkRooms(wh, off, E_DOOR);
			break;
		}
		case V_DOCK:
		{
			// the harbour along the back, a quay in front of it, a ship tied up
			int water = MakeRoom(I_WATER);
			Rect(water, 0, NY - 2, NX - 1, NY - 1);
			int quay = MakeRoom(I_QUAY);
			Rect(quay, 0, NY - 3, NX - 1, NY - 3);
			LinkAll(yardR, quay, E_WIDE);
			LinkAll(quay, water, E_WIDE);
			int s0 = Rand(1, NX - 6);
			int ship = MakeRoom(I_DECK);
			Rect(ship, s0, NY - 2, s0 + 4, NY - 1);
			LinkAll(ship, water, E_FENCE);
			Link(s0 + 2, NY - 3, s0 + 2, NY - 2, E_WIDE);        // the gangway
			int hold = MakeRoom(I_STORE); rName[hold] = "the ship's hold"; rF[hold] = 16; rC[hold] = 128;
			Claim(hold, s0 + 4, NY - 1);
			LinkRooms(hold, ship, E_DOOR);
			AddEntry(CellCenter(0, NY - 3), 0, "the water side", EK_SERVICE);
			int wh = Place(I_HALL, 3, 2); Doors(wh, 2);
			int cs = Place(I_CUSTOMS, 2, 1, "CEMENT7"); Doors(cs);
			break;
		}
		case V_FAB:
		{
			int fab = Place(I_HALL, 4, 3, "CEMENT7"); Doors(fab, 1);
			int st = Place(I_STORE, 2, 1); Doors(st, 1);
			int qa = Place(I_QA, 1, 1, "CEMENT7"); Doors(qa);
			int ctl = Place(I_CONTROL, 1, 1, "CEMENT7"); Doors(ctl);
			int pw = Place(I_POWER, 1, 1, "CEMENT7"); Doors(pw);
			if (fab >= 0 && qa >= 0 && Adjacent(fab, qa)) LinkRooms(fab, qa, E_DOOR);
			if (fab >= 0 && ctl >= 0 && Adjacent(fab, ctl)) LinkRooms(fab, ctl, E_DOOR);
			break;
		}
		case V_PLANT:
		{
			int th = Place(I_TURBINE, 4, 2, "CEMENT7"); Doors(th, 1);
			int ctl = Place(I_CONTROL, 2, 1, "CEMENT7"); Doors(ctl);
			if (th >= 0 && ctl >= 0 && Adjacent(th, ctl)) LinkRooms(th, ctl, E_DOOR);
			Switchyard(3, 2);
			// cooling towers: solid concrete blocks in the yard
			for (int k = 0; k < 2; k++) Solid(2, 2, "CEMENT9");
			break;
		}
		case V_SUBSTATION:
		{
			Switchyard(5, 3);
			int hut = Place(I_HUT, 1, 1, "CEMENT7"); Doors(hut);
			int vault = Place(I_VAULT, 1, 1, "CEMENT7"); Doors(vault);
			break;
		}
		case V_PARK:
		{
			// several small compounds: sheds and offices; a tank farm; a rail spur of container wagons
			for (int k = 0; k < 3; k++) { int s = Place(I_HALL, 2, Rand(1, 2)); Doors(s, 1); }
			int off = Place(I_OFFICE, 2, 1, "CEMENT7"); Doors(off);
			int ctl = Place(I_CONTROL, 1, 1, "CEMENT7"); Doors(ctl);
			int crew = Place(I_BUNKROOM, 1, 1, "CEMENT7"); Doors(crew);
			break;
		}
		case V_SALVAGE:
		{
			int cr = Place(I_CRUSHER, 2, 1, "METAL"); Doors(cr, 1);
			int ws = Place(I_WORKSHOP, 2, 1); Doors(ws, 1);
			int tr = Place(I_TRAILER, 1, 1, "CEMENT7"); Doors(tr);
			break;
		}
		case V_CONSTRUCTION:
		{
			// the half-built block: a raised slab, open to the sky, with a site office and a container store
			int slab = MakeRoom(I_SLAB);
			int x0 = Rand(2, 4), y0 = Rand(3, 4);
			Rect(slab, x0, y0, x0 + 4, y0 + 3);
			LinkRooms(slab, yardR, E_WIDE); LinkRooms(slab, yardR, E_WIDE); LinkRooms(slab, yardR, E_WIDE);
			int tr = Place(I_TRAILER, 1, 1, "CEMENT7"); rName[tr] = "the site office"; Doors(tr);
			int st = Place(I_STORE, 1, 1, "METAL"); rName[st] = "the tool store"; Doors(st);
			int crew = Place(I_BUNKROOM, 1, 1, "CEMENT7"); rName[crew] = "the crew hut"; Doors(crew);
			break;
		}
		}
		// the last way in: a hole in the fence at the far end of the lot
		if (variant != V_DOCK)
		{
			int fi = Chance(50) ? 0 : NX - 1;
			AddEntry(CellCenter(fi, NY - 1) + (fi ? 60 : -60, 60), fi ? 225 : 315, "a gap in the back fence", EK_SERVICE);
		}
	}

	// a fenced switchyard of transformers, with its own gate
	void Switchyard(int w, int h)
	{
		for (int tries = 0; tries < 60; tries++)
		{
			int i0 = Rand(1, NX - 1 - w), j0 = Rand(2, NY - h);
			bool ok = true;
			for (int j = j0; j < j0 + h && ok; j++) for (int i = i0; i < i0 + w && ok; i++) if (At(i, j) != yardR) ok = false;
			if (!ok) continue;
			int sy = MakeRoom(I_SWITCHYARD);
			Rect(sy, i0, j0, i0 + w - 1, j0 + h - 1);
			LinkAll(sy, yardR, E_FENCE);
			LinkRooms(sy, yardR, E_WIDE);
			return;
		}
	}
	// a solid block in the yard (cooling tower base, a stack of containers too high to climb)
	void Solid(int w, int h, String face)
	{
		for (int tries = 0; tries < 60; tries++)
		{
			int i0 = Rand(1, NX - 1 - w), j0 = Rand(2, NY - h);
			bool ok = true;
			for (int j = j0; j < j0 + h && ok; j++) for (int i = i0; i < i0 + w && ok; i++) if (At(i, j) != yardR) ok = false;
			if (!ok) continue;
			for (int j = j0; j < j0 + h; j++) for (int i = i0; i < i0 + w; i++) { roomOf[j * NX + i] = -1; cellFac[j * NX + i] = face; }
			return;
		}
	}

	// the gatehouse is the fallback for a person to find, not the first choice
	override int ObjScore(int r, int k)
	{
		if (IsType(r, I_GATEHOUSE)) return k == OBJ_TURN ? 12 : 0;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r) { return (IsType(r, I_OFFICE) || IsType(r, I_QA) || IsType(r, I_TRAILER)) ? 0 : 2; }

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case I_YARD:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (cj[k] <= 1 && abs(ci[k] - gateCol) <= 1) continue;   // keep the gate clear
				int roll = Rand(0, 99);
				switch (variant)
				{
				case V_SALVAGE:
					if (roll < 55) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
					if (roll < 25) PutInCell("CW_FScrap", ci[k], cj[k], 90 * Rand(0, 3));
					break;
				case V_DOCK: case V_WAREHOUSE: case V_PARK:
					if (roll < 30) PutInCell(Chance(50) ? "CW_FContainer" : "CW_FContainerB", ci[k], cj[k], 90 * Rand(0, 1));
					else if (roll < 42) PutInCell("CW_FPallet", ci[k], cj[k]);
					else if (roll < 50) Car(CellCenter(ci[k], cj[k]), 90 * Rand(0, 3), Chance(50) ? "VanWhite" : "PickupWhite");
					if (variant == V_PARK && roll >= 50 && roll < 62) PutInCell("CW_FTank", ci[k], cj[k]);
					break;
				case V_CONSTRUCTION:
					if (roll < 25) PutInCell("CW_FPallet", ci[k], cj[k]);
					else if (roll < 35) PutInCell("CW_FCrates", ci[k], cj[k]);
					else if (roll < 42) PutInCell("CW_FContainer", ci[k], cj[k], 90 * Rand(0, 1));
					break;
				default:
					if (roll < 15) PutInCell("CW_FPallet", ci[k], cj[k]);
					else if (roll < 22) PutInCell("CW_FCrates", ci[k], cj[k]);
					else if (roll < 28) PutInCell("CW_FPipes", ci[k], cj[k], 90 * Rand(0, 1));
					break;
				}
			}
			break;
		case I_HALL:
			if (variant == V_FAB) { for (int k = 0; k < ci.Size(); k++) { Put("CW_FWorkbench", CellCenter(ci[k], cj[k]) + (0, -40), 90); Put("CW_FLabBench", CellCenter(ci[k], cj[k]) + (0, 40), 90); } }
			else { for (int k = 0; k < ci.Size(); k++) { Put("CW_FShelving", CellCenter(ci[k], cj[k]) + (-50, 0), 0); Put("CW_FShelving", CellCenter(ci[k], cj[k]) + (50, 0), 0); } }
			for (int k = 0; k < ci.Size(); k++) if (Chance(30)) PutInCell("CW_FPallet", ci[k], cj[k]);
			break;
		case I_STORE: case I_COLD: case I_VAULT:
			LineWalls("CW_FShelving", r, 90, 6);
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		case I_OFFICE: case I_CUSTOMS: case I_TRAILER:
			PutInRoom("CW_FDeskWork", r); PutInRoom("CW_FDeskWork", r); LineWalls("CW_FFileCabinet", r, 70, 3);
			break;
		case I_GATEHOUSE:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FWallTV", r, 120, 2);
			break;
		case I_QA:
			LineWalls("CW_FLabBench", r, 130, 3);
			break;
		case I_CONTROL:
			LineWalls("CW_FDeskCode", r, 90, 4); LineWalls("CW_FWallTV", r, 100, 3);
			break;
		case I_POWER: case I_HUT:
			LineWalls("CW_FGenerator", r, 120, 2); LineWalls("CW_FTransformer", r, 120, 2);
			break;
		case I_TURBINE:
			for (int k = 0; k < ci.Size(); k++) if (k % 2 == 0) PutInCell("CW_FTurbine", ci[k], cj[k], 0);
			LineWalls("CW_FPipes", r, 180, 4);
			break;
		case I_SWITCHYARD:
			for (int k = 0; k < ci.Size(); k++) { Put("CW_FTransformer", CellCenter(ci[k], cj[k]) + (-56, 0), 0); Put("CW_FTransformer", CellCenter(ci[k], cj[k]) + (56, 0), 0); }
			break;
		case I_WORKSHOP:
			LineWalls("CW_FWorkbench", r, 110, 4); PutInRoom("CW_FScrap", r);
			break;
		case I_CRUSHER:
			PutInRoom("CW_FGenerator", r); LineWalls("CW_FScrap", r, 140, 3);
			break;
		case I_SLAB:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (Chance(35)) PutInCell("CW_FScaffold", ci[k], cj[k], 90 * Rand(0, 1));
				else if (Chance(30)) PutInCell("CW_FPallet", ci[k], cj[k]);
			}
			break;
		case I_DECK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(55)) PutInCell(Chance(50) ? "CW_FContainer" : "CW_FContainerB", ci[k], cj[k], 0);
			break;
		case I_QUAY:
			for (int k = 0; k < ci.Size(); k++) if (Chance(20)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		case I_BUNKROOM:
			LineWalls("CW_FBed", r, 120, 2); PutInRoom("CW_FRoundTable", r); LineWalls("CW_FLocker", r, 80, 2);
			break;
		}
	}

	override void Outdoors()
	{
		// floodlights round the lot, sodium lamps along the road
		for (int i = 0; i < NX; i += 2) PoleLight((colX[i] + colw[i] / 2, rowY[ROW_ROAD] + 40), 240);
		for (int j = 2; j < NY; j += 2)
		{
			PoleLight((colX[0] + 40, rowY[j] + rowh[j] / 2), 260, 230, 240, 255);
			PoleLight((colX[NX - 1] + colw[NX - 1] - 40, rowY[j] + rowh[j] / 2), 260, 230, 240, 255);
		}
		if (variant == V_DOCK) for (int i = 1; i < NX; i += 3) PoleLight((colX[i] + colw[i] / 2, rowY[NY - 3] + rowh[NY - 3] - 40), 280, 230, 240, 255);
	}
}
