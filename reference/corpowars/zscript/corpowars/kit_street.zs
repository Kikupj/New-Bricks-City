// =============================================================================
// Corpo Wars — K01 street kit: a city block (bars and clubs, restaurants, pawn shops, markets, malls,
// drug labs, chop shops, gambling dens; Rustline's bar and drug lab strongholds)
//
//   row 7  alleyR ------------------------------------------------------------+
//   row 6  back yards (one per lot, fenced, a gate to the alleyR)             | east gap
//   rows 2-5  buildings: 3-5 lots across columns 2..12, the target venue in the middle
//   row 1  sidewalk                                                          |
//   row 0  street (parked cars)  ... and a cross street down column 0, sidewalk down column 1
// Grid: columns 208, 96, 11 x 176, 96; rows 208, 96, 4 x 176, 112, 128 (genmap KIT_GRIDS["K01"]).
// =============================================================================
class CW_KitStreet : CW_KitGen
{
	enum EVar { V_CLUB, V_RESTAURANT, V_PAWN, V_MARKET, V_MALL, V_DRUGLAB, V_CHOPSHOP, V_GAMBLING, V_COUNT }
	enum ERoom
	{
		S_ROAD, S_WALK, S_YARD, S_ALLEY, S_SHOP, S_BACK, S_FOYER, S_FLOOR, S_BAR, S_VIP, S_OFFICE, S_STORE, S_BATH,
		S_KITCHEN, S_COLD, S_HALL, S_WORKSHOP, S_GARAGE, S_LAB, S_GAMING, S_CAGE, S_STALLS, S_CONCOURSE, S_UNIT,
		S_SERVICE, S_DINING
	}
	const LOT0 = 2;
	const LOT1 = 12;
	const ROW_FRONT = 2;
	const ROW_BACK = 5;
	const ROW_YARD = 6;
	const ROW_ALLEY = 7;
	const COL_GAP = 13;

	int roadR, walkR, alleyR;
	int vc0, vc1;              // the venue's columns
	static const String FACADES[] = { "BRICK11", "BRICK12", "BRICK1", "BIGBRIK1", "STUCCO1", "STONE2", "BRICK6", "CEMENT7", "AXW84", "AXW85" };

	override void Setup()
	{
		static const int CW[] = { 208, 96, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 96 };
		static const int RW[] = { 208, 96, 176, 176, 176, 176, 112, 128 };
		for (int i = 0; i < CW.Size(); i++) colw.Push(CW[i]);
		for (int j = 0; j < RW.Size(); j++) rowh.Push(RW[j]);
		Grid(CW.Size(), RW.Size());
		doorTex = "DOOR3"; jambTex = "SUPPORT3"; edgeTex = "BRICK7";
		// beyond the street: the far pavement at kerb height, then the buildings across the road, three storeys
		// with lit and dark windows, and the night sky above their roofline (the band is open, you just can't cross)
		bandFloor = 0; bandTex = "AQF050"; bandCeil = 512; bandLight = 144;
		bandWalls.Push("BRWINDOW");
		kerbTex = "CWCONCW";
	}
	// four- and five-storey blocks: a shop-level ground floor, windowed storeys above, sky over the roofline
	override double SkyH() { return 640; }
	override double GroundFloorH() { return 128; }
	override String UpperFacade(String ground) { return "BRWINDOW"; }
	// every outdoor edge (street, pavement, alley) looks across to the next block instead of hitting a wall
	override bool EdgeOpen(int r) { return IsOut(r); }
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "club", "restaurant", "pawn shop", "street market", "mall", "drug lab", "chop shop", "gambling den" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 9, 7, 3, 9, 9, 1, 2, 6 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}

	int MakeRoom(int t)
	{
		switch (t)
		{
		case S_ROAD:      return Room(t, RF_OUT, -8, 0, 80, "AQF025", "F_SKY1", "BRICK7", "the street");
		case S_WALK:      return Room(t, RF_OUT | RF_CIV, 0, 0, 88, "AQF050", "F_SKY1", "BRICK7", "sidewalk");
		case S_YARD:      return Room(t, RF_OUT, 0, 0, 96, "FLOOR4_8", "F_SKY1", "BRICK6", "back yard");
		case S_ALLEY:     return Room(t, RF_OUT | RF_PATROL, 0, 0, 64, "MFLR8_1", "F_SKY1", "BRICK6", "the alley");
		case S_SHOP:      return Room(t, RF_CIV, 0, 112, 152, "AQF050", "CEIL1_1", "AXW01", "shop");
		case S_BACK:      return Room(t, 0, 0, 104, 120, "FLOOR4_8", "CEIL1_1", "CEMENT7", "back room");
		case S_FOYER:     return Room(t, RF_PATROL, 0, 112, 136, "AXF48", "CWCEILD", "AXDW07A", "foyer");
		case S_FLOOR:     return Room(t, RF_CIV | RF_PATROL, 0, 144, 104, "AXF46", "CWCEILD", "AXW84", variant == V_CLUB ? "the dance floor" : "the floor");
		case S_BAR:       return Room(t, RF_CIV, 0, 120, 120, "AXF48", "CWCEILD", "AXDW07A", "the bar");
		case S_VIP:       return Room(t, RF_PEOPLE | RF_CIV, 0, 112, 112, "CWCARP3", "CWCEILD", "AXDW07B", "VIP lounge");
		case S_OFFICE:    return Room(t, RF_VALUE | RF_PEOPLE, 0, 104, 136, "CWCARP2", "CEIL1_1", "AXDW07A", "the back office");
		case S_STORE:     return Room(t, 0, 0, 104, 112, "FLOOR4_8", "CEIL1_1", "CEMENT7", "storeroom");
		case S_BATH:      return Room(t, 0, 0, 96, 144, "CWTILEF", "CEIL1_1", "CWTILEW", "restrooms");
		case S_KITCHEN:   return Room(t, RF_CIV | RF_TECH, 0, 112, 168, "CWTILEF", "CEIL1_1", "CWTILEW", "the kitchen");
		case S_COLD:      return Room(t, RF_TECH, 0, 96, 136, "AXF06C", "CEIL1_1", "AXW44", "walk-in cold room");
		case S_HALL:      return Room(t, RF_PATROL, 0, 104, 120, "FLOOR4_8", "CEIL1_1", "CEMENT7", "back hall");
		case S_WORKSHOP:  return Room(t, RF_TECH, 0, 112, 136, "CWCONCF", "CEIL1_1", "CEMENT7", "workshop");
		case S_GARAGE:    return Room(t, RF_TECH | RF_PATROL, 0, 144, 136, "CWCONCF", "CEIL1_1", "SHAWN02", "the garage");
		case S_LAB:       return Room(t, RF_VALUE | RF_TECH | RF_PATROL, 0, 112, 112, "FLOOR4_8", "CEIL1_1", "CEMENT7", "the cook room");
		case S_GAMING:    return Room(t, RF_CIV | RF_PATROL, 0, 128, 104, "CWCARP3", "CWCEILD", "AXDW07B", "the card room");
		case S_CAGE:      return Room(t, RF_VALUE | RF_TECH, 0, 104, 136, "AXF06C", "CEIL1_1", "AXW44A", "the cashier's cage");
		case S_STALLS:    return Room(t, RF_OUT | RF_CIV | RF_PATROL, 0, 0, 120, "AQF046", "F_SKY1", "BRICK11", "the market");
		case S_CONCOURSE: return Room(t, RF_CIV | RF_PATROL, 0, 160, 176, "ADFMARB", "CWCEILL", "AXCITY17", "the concourse");
		case S_UNIT:      return Room(t, RF_CIV, 0, 128, 168, "CWTILEF", "CWCEILT", "CWWALL1", "shop unit");
		case S_SERVICE:   return Room(t, RF_PATROL, 0, 112, 120, "CWCONCF", "CWCEILD", "CWCONCW", "service corridor");
		case S_DINING:    return Room(t, RF_CIV, 0, 120, 144, "AXF48", "CWCEILD", "AXDW07A", "the dining room");
		}
		return Room(t, 0, 0, 112, 128, "FLOOR4_8", "CEIL1_1", "CEMENT7", "room");
	}

	override void Layout()
	{
		// ---- the public space
		roadR = MakeRoom(S_ROAD);
		Rect(roadR, 0, 0, NX - 1, 0);
		Rect(roadR, 0, 0, 0, NY - 1);
		walkR = MakeRoom(S_WALK);
		Rect(walkR, 1, 1, NX - 1, 1);
		Rect(walkR, 1, 1, 1, NY - 1);
		alleyR = MakeRoom(S_ALLEY);
		Rect(alleyR, LOT0, ROW_ALLEY, COL_GAP, ROW_ALLEY);
		Rect(alleyR, COL_GAP, ROW_FRONT, COL_GAP, ROW_ALLEY);
		LinkAll(roadR, walkR, E_WIDE);
		Link(COL_GAP, 1, COL_GAP, ROW_FRONT, E_WIDE);             // the east gap opens onto the sidewalk
		Link(1, ROW_ALLEY, LOT0, ROW_ALLEY, E_WIDE);           // and the alleyR onto the west sidewalk

		// ---- the venue, then the neighbours either side
		int w = VenueWidth();
		if (variant == V_MALL) { vc0 = LOT0; vc1 = LOT1; }
		else
		{
			vc0 = LOT0 + 2 + Rand(0, max(0, (LOT1 - LOT0 + 1) - w - 4));
			vc1 = vc0 + w - 1;
		}
		BuildVenue();
		FillNeighbours(LOT0, vc0 - 1);
		FillNeighbours(vc1 + 1, LOT1);
		// yards behind every lot, fenced from each other; the venue's yard has a gate to the alleyR
		BuildYards();

		// ---- entries: where the van can drop you
		AddEntry(CellCenter(0, 0) + (-40, 0), 0, "the street", EK_FRONT);
		AddEntry(CellCenter(COL_GAP, ROW_ALLEY) + (0, 20), 270, "the alley", EK_BACK);
		AddEntry(CellCenter(0, NY - 1) + (-40, 30), 270, "the cross street", EK_SERVICE);
	}

	int VenueWidth()
	{
		switch (variant)
		{
		case V_CLUB: return 4;
		case V_RESTAURANT: return Rand(3, 4);
		case V_PAWN: return Rand(2, 3);
		case V_MARKET: return Rand(4, 5);
		case V_DRUGLAB: return 3;
		case V_CHOPSHOP: return Rand(3, 4);
		case V_GAMBLING: return Rand(3, 4);
		}
		return 3;
	}

	// ---- the target venue: columns vc0..vc1, rows ROW_FRONT..ROW_BACK
	void BuildVenue()
	{
		int w = vc1 - vc0 + 1;
		int face = Rand(0, FACADES.Size() - 1);
		int front = -1, mid = -1, hall = -1;
		Array<int> backs;
		switch (variant)
		{
		case V_CLUB:
		{
			front = MakeRoom(S_FOYER); Claim(front, vc0, ROW_FRONT);
			int bar = MakeRoom(S_BAR); Rect(bar, vc0 + 1, ROW_FRONT, vc1, ROW_FRONT);
			mid = MakeRoom(S_FLOOR); Rect(mid, vc0, ROW_FRONT + 1, vc1, ROW_FRONT + 2);
			LinkRooms(front, mid, E_DOOR); LinkRooms(bar, mid, E_WIDE); LinkRooms(front, bar, E_ARCH);
			backs.Push(S_VIP); backs.Push(S_OFFICE); backs.Push(S_BATH);
			break;
		}
		case V_RESTAURANT:
		{
			front = MakeRoom(S_DINING); Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT + 1);
			mid = MakeRoom(S_KITCHEN); Rect(mid, vc0, ROW_FRONT + 2, vc1 - 1, ROW_FRONT + 2);
			int cold = MakeRoom(S_COLD); Claim(cold, vc1, ROW_FRONT + 2);
			LinkRooms(front, mid, E_DOOR); LinkRooms(mid, cold, E_DOOR);
			backs.Push(S_OFFICE); backs.Push(S_STORE); backs.Push(S_BATH);
			break;
		}
		case V_PAWN:
		{
			front = MakeRoom(S_SHOP); rName[front] = "the pawn counter"; Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT);
			mid = MakeRoom(S_STORE); Rect(mid, vc0, ROW_FRONT + 1, vc1, ROW_FRONT + 2);
			int shop = MakeRoom(S_WORKSHOP); Claim(shop, vc1, ROW_FRONT + 2); rName[shop] = "repair bench";
			LinkRooms(front, mid, E_DOOR); LinkRooms(mid, shop, E_ARCH);
			backs.Push(S_OFFICE); backs.Push(S_CAGE);
			break;
		}
		case V_MARKET:
		{
			// an open-air market square in front, the market building behind it
			front = MakeRoom(S_STALLS); Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT + 1);
			LinkAll(front, walkR, E_WIDE);
			mid = MakeRoom(S_STORE); rName[mid] = "market hall"; rflags[mid] |= RF_CIV; Rect(mid, vc0, ROW_FRONT + 2, vc1, ROW_FRONT + 2);
			LinkRooms(front, mid, E_WIDE); LinkRooms(front, mid, E_DOOR);
			backs.Push(S_OFFICE); backs.Push(S_COLD); backs.Push(S_STORE);
			break;
		}
		case V_MALL:
		{
			// entrance hall, a concourse through the block, shop units either side, service corridor behind
			int e0 = (LOT0 + LOT1) / 2 - 1;
			front = MakeRoom(S_FOYER); rName[front] = "the mall entrance"; rflags[front] |= RF_CIV; Rect(front, e0, ROW_FRONT, e0 + 2, ROW_FRONT);
			mid = MakeRoom(S_CONCOURSE); Rect(mid, LOT0, ROW_FRONT + 1, LOT1, ROW_FRONT + 2);
			LinkAll(front, mid, E_WIDE);
			for (int c = LOT0; c <= LOT1; c++)
			{
				if (c >= e0 && c <= e0 + 2) continue;
				int u = MakeRoom(S_UNIT);
				int uw = (c + 1 <= LOT1 && !(c + 1 >= e0 && c + 1 <= e0 + 2) && Chance(50)) ? 2 : 1;
				Rect(u, c, ROW_FRONT, c + uw - 1, ROW_FRONT);
				LinkRooms(u, mid, uw > 1 ? E_WIDE : E_ARCH);
				c += uw - 1;
			}
			hall = MakeRoom(S_SERVICE); Rect(hall, LOT0, ROW_BACK, LOT0 + 1, ROW_BACK);
			int k = LOT0 + 2;
			static const int mallBack[] = { S_UNIT, S_OFFICE, S_UNIT, S_UNIT, S_STORE, S_UNIT, S_CAGE, S_UNIT };
			int n = Rand(0, 7);
			while (k <= LOT1)
			{
				int t = mallBack[n % 8]; n++;
				int u = MakeRoom(t);
				int uw = min(Rand(1, 2), LOT1 - k + 1);
				Rect(u, k, ROW_BACK, k + uw - 1, ROW_BACK);
				LinkRooms(u, mid, t == S_UNIT ? E_WIDE : E_DOOR);
				if (t != S_UNIT) LinkRooms(u, hall, E_DOOR);
				k += uw;
			}
			LinkRooms(hall, mid, E_DOOR);
			for (int c = LOT0; c <= LOT1; c++) if (At(c, ROW_FRONT) >= 0) rFacT[At(c, ROW_FRONT)] = "AXCITY19";
			rFacT[front] = "AXCITY19"; rFacT[mid] = "AXCITY19";
			Link(e0 + 1, ROW_FRONT, e0 + 1, ROW_FRONT - 1, E_WIDE);
			Link(e0, ROW_FRONT, e0, ROW_FRONT - 1, E_DOOR);
			Link(e0 + 2, ROW_FRONT, e0 + 2, ROW_FRONT - 1, E_DOOR);
			Link(LOT0, ROW_BACK, LOT0, ROW_YARD, E_DOOR);
			return;
		}
		case V_DRUGLAB:
		{
			front = MakeRoom(S_SHOP); rName[front] = "a boarded-up shop"; rflags[front] = RF_DARK; Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT);
			mid = MakeRoom(S_LAB); Rect(mid, vc0, ROW_FRONT + 1, vc1, ROW_FRONT + 2);
			LinkRooms(front, mid, E_DOOR);
			backs.Push(S_STORE); backs.Push(S_OFFICE);
			break;
		}
		case V_CHOPSHOP:
		{
			front = MakeRoom(S_GARAGE); Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT + 2);
			mid = front;
			backs.Push(S_STORE); backs.Push(S_OFFICE); backs.Push(S_WORKSHOP);
			break;
		}
		case V_GAMBLING:
		{
			front = MakeRoom(S_BAR); rName[front] = "the front bar"; Rect(front, vc0, ROW_FRONT, vc1, ROW_FRONT);
			mid = MakeRoom(S_GAMING); Rect(mid, vc0, ROW_FRONT + 1, vc1, ROW_FRONT + 2);
			LinkRooms(front, mid, E_DOOR);
			backs.Push(S_CAGE); backs.Push(S_OFFICE); backs.Push(S_BATH);
			break;
		}
		}
		// the back row: a back hall with the rear door, and the rooms that matter
		hall = MakeRoom(S_HALL);
		int hc = Chance(50) ? vc0 : vc1;
		Claim(hall, hc, ROW_BACK);
		int c = vc0, n = 0;
		while (c <= vc1)
		{
			if (c == hc) { c++; continue; }
			int t = backs.Size() ? backs[n % backs.Size()] : S_STORE;
			n++;
			int r = MakeRoom(t);
			int uw = (n == 1 && c + 1 <= vc1 && c + 1 != hc && w >= 4) ? 2 : 1;
			Rect(r, c, ROW_BACK, c + uw - 1, ROW_BACK);
			if (!LinkRooms(r, hall, E_DOOR)) LinkRooms(r, mid, E_DOOR);
			c += uw;
		}
		LinkRooms(hall, mid, E_DOOR);
		// front door(s) onto the sidewalk; the rear door onto the yard
		int fc = (vc0 + vc1) / 2;
		if (At(fc, ROW_FRONT) == front || variant == V_CHOPSHOP)
		{
			if (variant == V_CHOPSHOP) { Link(fc, ROW_FRONT, fc, ROW_FRONT - 1, E_WIDE); Link(fc + 1, ROW_FRONT, fc + 1, ROW_FRONT - 1, E_WIDE); }
			else if (variant != V_MARKET) Link(fc, ROW_FRONT, fc, ROW_FRONT - 1, E_DOOR);
		}
		else if (variant != V_MARKET) LinkRooms(front, walkR, E_DOOR);
		Link(hc, ROW_BACK, hc, ROW_YARD, E_DOOR);
		for (int j = ROW_FRONT; j <= ROW_BACK; j++) for (int i = vc0; i <= vc1; i++) if (At(i, j) >= 0) rFacT[At(i, j)] = FACADES[face];
	}

	// neighbours: small shops (front room + back room) and closed-up lots (solid)
	void FillNeighbours(int c0, int c1)
	{
		int c = c0;
		while (c <= c1)
		{
			int w = min(Rand(2, 3), c1 - c + 1);
			if (c1 - (c + w - 1) == 1) w++;           // no one-column leftovers
			w = min(w, c1 - c + 1);
			int x1 = c + w - 1;
			String face = FACADES[Rand(0, FACADES.Size() - 1)];
			if (Chance(72))
			{
				int shop = MakeRoom(S_SHOP), back = MakeRoom(S_BACK);
				Rect(shop, c, ROW_FRONT, x1, ROW_FRONT + 1);
				Rect(back, c, ROW_FRONT + 2, x1, ROW_BACK);
				rFacT[shop] = face; rFacT[back] = face;
				LinkRooms(shop, back, E_DOOR);
				Link(c + w / 2, ROW_FRONT, c + w / 2, ROW_FRONT - 1, E_DOOR);
			}
			else
			{
				// closed: the block is solid behind a facade; mark the facade on the street side
				for (int j = ROW_FRONT; j <= ROW_BACK; j++) for (int i = c; i <= x1; i++) cellFac[j * NX + i] = face;
			}
			c += w;
		}
	}

	void BuildYards()
	{
		Array<int> yards;
		int prev = -1, prevLot = -99;
		for (int c = LOT0; c <= LOT1; c++)
		{
			int lot = LotOf(c);
			if (lot != prevLot)
			{
				prev = MakeRoom(S_YARD);
				yards.Push(prev);
				prevLot = lot;
			}
			Claim(prev, c, ROW_YARD);
		}
		for (int y = 0; y < yards.Size(); y++)
		{
			int yd = yards[y];
			if (y > 0) LinkAll(yards[y - 1], yd, E_FENCE);
			LinkAll(yd, alleyR, E_FENCE);
			// a gate to the alleyR in most yards, always behind the venue
			Array<int> ci, cj; CellsOf(yd, ci, cj);
			bool venue = ci.Size() && ci[0] >= vc0 && ci[0] <= vc1;
			if (venue || Chance(55)) { int gx = ci[Rand(0, ci.Size() - 1)]; Link(gx, ROW_YARD, gx, ROW_ALLEY, E_WIDE); }
			// neighbours' back doors
			for (int k = 0; k < ci.Size(); k++)
			{
				int b = At(ci[k], ROW_BACK);
				if (b >= 0 && !venue && IsType(b, S_BACK) && Chance(35)) { Link(ci[k], ROW_BACK, ci[k], ROW_YARD, E_DOOR); break; }
			}
		}
		// the first yard backs onto the west sidewalk: a fence
		LinkAll(yards[0], walkR, E_FENCE);
		LinkAll(yards[yards.Size() - 1], alleyR, E_FENCE);
	}

	// which lot a column belongs to (the room in its front row, or the venue)
	int LotOf(int c)
	{
		if (c >= vc0 && c <= vc1) return 1000;
		int r = At(c, ROW_FRONT);
		if (r >= 0) return r;
		// a closed lot has no cells: group columns by the facade run they fall in
		return 2000 + c / 3;
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case S_FLOOR: case S_BAR: case S_VIP: case S_GAMING: case S_DINING: return 1;
		case S_GARAGE: case S_WORKSHOP: case S_STORE: case S_BACK: case S_LAB: case S_SERVICE: case S_HALL: return 2;
		case S_CONCOURSE: case S_FOYER: return 3;
		}
		return 0;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case S_YARD:
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) PutWall(Chance(50) ? "CW_FDumpster" : "CW_FCrates", ci[k], cj[k], 2, Rand(-40, 40));
			break;
		case S_ALLEY:
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutWall(Chance(60) ? "CW_FDumpster" : "CW_FPallet", ci[k], cj[k], Chance(50) ? 2 : 3, Rand(-40, 40));
			break;
		case S_SHOP: case S_UNIT:
			LineWalls("CW_FShelving", r, 90, 4);
			PutInRoom("CW_FCounter", r, 90);
			break;
		case S_BACK: case S_STORE: case S_SERVICE:
			LineWalls("CW_FShelving", r, 90, 4);
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(50) ? "CW_FCrates" : "CW_FPallet", ci[k], cj[k]);
			break;
		case S_FOYER:
			PutInRoom("CW_FPlanter", r); PutInRoom("CW_FReception", r, 90);
			break;
		case S_FLOOR:
			LineWalls("CW_FBarCounter", r, 150, 2);
			LineWalls("CW_FSofa", r, 120, 3);
			for (int k = 0; k < ci.Size(); k++) if (Chance(40)) PutInCell("CW_FRoundTable", ci[k], cj[k]);
			break;
		case S_BAR:
			LineWalls("CW_FBarCounter", r, 150, 1);
			for (int k = 0; k < ci.Size(); k++) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FStool", ci[k], cj[k]); }
			break;
		case S_VIP:
			LineWalls("CW_FSofa", r, 110, 3); PutInRoom("CW_FCoffeeTable", r);
			break;
		case S_OFFICE:
			PutInRoom("CW_FDeskExec", r); LineWalls("CW_FFileCabinet", r, 60, 3); PutInRoom("CW_FChairExec", r);
			break;
		case S_BATH:
			LineWalls("CW_FStalls", r, 90, 2); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case S_KITCHEN:
			LineWalls("CW_FCounter", r, 110, 5);
			for (int k = 0; k < ci.Size(); k++) Put("CW_FCounter", CellCenter(ci[k], cj[k]), 90);
			break;
		case S_COLD:
			LineWalls("CW_FShelving", r, 80, 4);
			break;
		case S_WORKSHOP:
			LineWalls("CW_FWorkbench", r, 100, 3); LineWalls("CW_FShelving", r, 100, 2);
			break;
		case S_GARAGE:
			for (int k = 0; k < ci.Size(); k++) if (cj[k] > ROW_FRONT && Chance(70)) Car(CellCenter(ci[k], cj[k]), 90);
			LineWalls("CW_FWorkbench", r, 140, 3); LineWalls("CW_FLocker", r, 200, 2);
			break;
		case S_LAB:
			for (int k = 0; k < ci.Size(); k++) Put("CW_FLabBench", CellCenter(ci[k], cj[k]), 90 * Rand(0, 1));
			LineWalls("CW_FTank", r, 120, 3); LineWalls("CW_FCrates", r, 120, 3);
			break;
		case S_GAMING:
			for (int k = 0; k < ci.Size(); k++) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FChairGuest", ci[k], cj[k]); }
			LineWalls("CW_FBarCounter", r, 200, 1); LineWalls("CW_FSofa", r, 200, 2);
			break;
		case S_CAGE:
			LineWalls("CW_FCounter", r, 110, 2); LineWalls("CW_FFileCabinet", r, 60, 3);
			break;
		case S_STALLS:
			for (int k = 0; k < ci.Size(); k++) if (Chance(80)) Put("CW_FStall", CellCenter(ci[k], cj[k]) + (Rand(-20, 20), Rand(-10, 10)), 90 * Rand(0, 3));
			break;
		case S_CONCOURSE:
			for (int k = 0; k < ci.Size(); k++) if (Chance(45)) PutInCell(Chance(50) ? "CW_FPlanter" : "CW_FPew", ci[k], cj[k], 90 * Rand(0, 1));
			break;
		case S_DINING:
			for (int k = 0; k < ci.Size(); k++) { PutInCell("CW_FRoundTable", ci[k], cj[k]); PutInCell("CW_FChairGuest", ci[k], cj[k]); }
			break;
		}
	}

	override void Outdoors()
	{
		// street lamps on the kerb, parked cars along the street, lights over the alleyR doors
		for (int i = 2; i < NX; i += 2) PoleLight((colX[i] + colw[i] / 2, rowY[1] + 18), 220);
		for (int j = 3; j < NY; j += 2) PoleLight((colX[1] + 18, rowY[j] + rowh[j] / 2), 220);
		for (double x = colX[2] + 80; x < colX[NX - 1]; x += 240)
			if (Chance(60)) Car((x + Rand(-30, 30), rowY[0] + rowh[0] - 72), Chance(50) ? 0 : 180);
		for (double y = rowY[2] + 60; y < rowY[NY - 1]; y += 260)
			if (Chance(50)) Car((colX[0] + colw[0] - 72, y), Chance(50) ? 90 : 270);
		for (int i = LOT0; i <= COL_GAP; i += 3)
			CW_LightSource.Make((colX[i] + colw[i] / 2, rowY[ROW_ALLEY] + rowh[ROW_ALLEY] - 8, 104), 255, 170, 90, 150);
		// the venue's sign and door light
		CW_LightSource.Make((CellCenter((vc0 + vc1) / 2, 1) + (0, 30), 110), variant == V_CLUB ? 255 : 255, variant == V_CLUB ? 60 : 200, variant == V_CLUB ? 200 : 120, 170);
	}
}
