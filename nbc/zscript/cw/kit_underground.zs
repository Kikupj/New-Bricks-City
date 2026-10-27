// Ported from Corpo Wars (reference/corpowars/zscript/corpowars/kit_underground.zs) for PLAN.md M2b.
// NBC: renamed to NBC_ because the mission layer is cut and the look is rebuilt for the Bricks.
// =============================================================================
// Corpo Wars — K04 underground kit: maintenance tunnels and sewers, pedestrian underpasses, transit stations,
// parking garages, hydroponic farms, bunkers.
// Everything is indoors and low; the ways in are stairs from the street, manholes, service tunnels.
// Grid 16 x 14 cells of 128 (genmap KIT_GRIDS["K04"]).
// NBC: the basements, garages, tunnels and subway under the towers. Tunnels, camps and caches carry rubble.
// =============================================================================
class NBC_KitUnderground : NBC_KitGen
{
	enum EVar { V_TUNNELS, V_UNDERPASS, V_TRANSIT, V_PARKING, V_FARM, V_BUNKER, V_COUNT }
	enum ERoom
	{
		U_TUNNEL, U_CHANNEL, U_WALK, U_BRIDGE, U_CHAMBER, U_PUMP, U_CAMP, U_CACHE, U_HIDEOUT, U_CONTROL, U_STORE, U_STAIRS,
		U_PASSAGE, U_CIRCUS, U_KIOSK, U_TOILET, U_MAINT, U_CONCOURSE, U_PAID, U_TICKET, U_PLATFORM, U_TRACK, U_STAFF, U_CASH,
		U_RELAY, U_DECK, U_RAMP, U_BOOTH, U_CAGE, U_LIFT, U_PLANT, U_SECURITY, U_GROW, U_NUTRIENT, U_SEEDS, U_PACKING,
		U_DOCK, U_OFFICE, U_LOCKER, U_AIRLOCK, U_POST, U_COMMAND, U_ARMOURY, U_VAULT, U_COMMS, U_BUNKS, U_MESS,
		U_GENERATOR, U_ESCAPE, U_CORR, U_MEDBAY, U_WATER
	}

	override void Setup()
	{
		for (int i = 0; i < 16; i++) colw.Push(128);
		for (int j = 0; j < 14; j++) rowh.Push(128);
		Grid(16, 14);
		doorTex = "DOOR3"; jambTex = "SUPPORT3"; edgeTex = "CWCONCW";
	}
	override int VariantCount() { return V_COUNT; }
	override String VariantName()
	{
		static const String n[] = { "maintenance tunnels", "underpass", "transit station", "parking garage", "hydroponic farm", "bunker" };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int Bystanders()
	{
		static const int n[] = { 3, 6, 8, 3, 5, 2 };
		return n[clamp(variant, 0, V_COUNT - 1)];
	}
	override int KitRoom(int t) { return MakeRoom(t); }

	int MakeRoom(int t)
	{
		bool bunker = variant == V_BUNKER;
		String cw = bunker ? "GRAY4" : "CWCONCW";
		switch (t)
		{
		case U_TUNNEL:    return Room(t, RF_PATROL | RF_RUBBLE, 0, 112, 96, "FLOOR4_8", "CEIL5_1", variant == V_TUNNELS ? "BRICK11" : cw, bunker ? "the entrance tunnel" : "the service tunnels");
		case U_CHANNEL:   return Room(t, RF_WATER, -24, 136, 80, "NUKAGE1", "CEIL5_1", "BRICK11", "the storm drain");
		case U_WALK:      return Room(t, RF_PATROL, 0, 112, 96, "FLOOR0_3", "CEIL5_1", "BRICK11", "the drain walkway");
		case U_BRIDGE:    return Room(t, RF_PATROL, 0, 112, 96, "FLOOR0_3", "CEIL5_1", "BRICK11", "the footbridge");
		case U_CHAMBER:   return Room(t, RF_PATROL | RF_RUBBLE, 0, 176, 104, "FLOOR4_8", "CEIL5_1", "BRICK10", "a junction chamber");
		case U_PUMP:      return Room(t, RF_TECH, 0, 144, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", "the pump room");
		case U_CAMP:      return Room(t, RF_CIV | RF_PEOPLE | RF_DARK | RF_RUBBLE, 0, 112, 88, "FLOOR0_3", "CEIL5_1", "BRICK10", "a squatters' camp");
		case U_CACHE:     return Room(t, RF_VALUE | RF_DARK | RF_RUBBLE, 0, 104, 80, "FLOOR4_8", "CEIL5_1", "BRICK11", "a smugglers' cache");
		case U_HIDEOUT:   return Room(t, RF_PEOPLE | RF_VALUE, 0, 112, 120, "FLOOR0_3", "CEIL5_1", "BROWN96", variant == V_UNDERPASS ? "a shuttered shop" : "the hideout");
		case U_CONTROL:   return Room(t, RF_TECH | RF_PEOPLE, 0, 112, 136, "CWRAISF", "CWCEILD", "AXDEFW", "the control room");
		case U_STORE:     return Room(t, 0, 0, 112, 112, "FLOOR4_8", "CEIL5_1", cw, "a storeroom");
		case U_STAIRS:    return Room(t, RF_NOGUARD, 0, 192, 144, "CWSTAIF", "CEIL5_1", "CWCONCW", "the stairs");
		case U_PASSAGE:   return Room(t, RF_PATROL | RF_CIV, 0, 128, 150, "CWTILEF", "CWCEILL", "CWTILEW", "the passage");
		case U_CIRCUS:    return Room(t, RF_PATROL | RF_CIV, 0, 160, 150, "CWTILEF", "CWCEILL", "CWTILEW", "the circus");
		case U_KIOSK:     return Room(t, RF_CIV | RF_PEOPLE, 0, 104, 176, "FLOOR4_1", "CEIL1_1", "CWWALL1", "a kiosk");
		case U_TOILET:    return Room(t, 0, 0, 104, 136, "CWTILEF", "CEIL1_1", "CWTILEW", "the toilets");
		case U_MAINT:     return Room(t, RF_TECH, 0, 112, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", "a maintenance room");
		case U_CONCOURSE: return Room(t, RF_PATROL | RF_CIV, 0, 176, 160, "CWTILEF", "CWCEILL", "CWTILEW", "the ticket hall");
		case U_PAID:      return Room(t, RF_PATROL | RF_CIV, 0, 160, 160, "CWTILEF", "CWCEILL", "CWTILEW", "the gateline");
		case U_TICKET:    return Room(t, RF_PEOPLE | RF_VALUE, 0, 112, 168, "FLOOR4_1", "CEIL1_1", "CWWALL1", "the ticket office");
		case U_PLATFORM:  return Room(t, RF_PATROL | RF_CIV, 0, 176, 150, "CWTILEF", "CWCEILL", "CWTILEW", "the platform");
		case U_TRACK:     return Room(t, RF_NOGUARD | RF_DARK, -24, 200, 72, "FLOOR0_3", "CEIL5_1", "BRICK10", "the tracks");
		case U_STAFF:     return Room(t, RF_CIV, 0, 112, 160, "FLOOR4_1", "CEIL1_1", "CWWALL1", "the staff room");
		case U_CASH:      return Room(t, RF_VALUE, 0, 104, 136, "AXF06C", "CEIL1_1", "AXW44A", "the cash office");
		case U_RELAY:     return Room(t, RF_TECH, 0, 112, 112, "CWRAISF", "CWCEILD", "CWSRVWL", "the signal relay room");
		case U_DECK:      return Room(t, RF_PATROL | RF_CIV, 0, 128, 112, "CWCONCF", "CEIL5_1", "CWCONCW", "the parking deck");
		case U_RAMP:      return Room(t, RF_PATROL, 0, 160, 128, "CWCONCF", "CEIL5_1", "CWCONCW", "the vehicle ramp");
		case U_BOOTH:     return Room(t, RF_PEOPLE, 0, 104, 160, "FLOOR4_1", "CEIL1_1", "CWWALL1", "the attendant's booth");
		case U_CAGE:      return Room(t, RF_VALUE, 0, 112, 104, "CWCONCF", "CEIL5_1", "MIDBARS3", "the storage cages");
		case U_LIFT:      return Room(t, RF_CIV, 0, 112, 150, "CWTILEF", "CEIL1_1", "CWWALL1", "the lift lobby");
		case U_PLANT:     return Room(t, RF_TECH, 0, 128, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", "the plant room");
		case U_SECURITY:  return Room(t, RF_PEOPLE | RF_PATROL, 0, 104, 150, "ADFCAR2", "CEIL1_1", "CWWALL2", "the security office");
		case U_GROW:      return Room(t, RF_PATROL | RF_CIV | RF_VALUE, 0, 160, 176, "CWTILEF", "CWCEILL", "CWTILEW", "a grow hall");
		case U_NUTRIENT:  return Room(t, RF_TECH, 0, 128, 136, "AXF06C", "CWCEILD", "AXW44", "the nutrient plant");
		case U_SEEDS:     return Room(t, RF_VALUE, 0, 104, 128, "AXF06C", "CWCEILD", "AXW44A", "the seed vault");
		case U_PACKING:   return Room(t, RF_CIV | RF_PATROL, 0, 128, 160, "CWCONCF", "CEIL5_1", "CWCONCW", "the packing floor");
		case U_DOCK:      return Room(t, RF_PATROL, 0, 160, 136, "CWCONCF", "CEIL5_1", "CWCONCW", "the loading bay");
		case U_OFFICE:    return Room(t, RF_PEOPLE | RF_CIV | RF_VALUE, 0, 104, 160, "CWCARP2", "CEIL1_1", "CWWALL1", "the office");
		case U_LOCKER:    return Room(t, RF_CIV, 0, 104, 150, "CWTILEF", "CEIL1_1", "CWTILEW", "the locker room");
		case U_AIRLOCK:   return Room(t, RF_NOGUARD, 0, 104, 168, "AXF06C", "CWCEILL", "AXW44", "the airlock");
		case U_POST:      return Room(t, RF_PEOPLE | RF_PATROL, 0, 104, 150, "FLOOR4_8", "CEIL1_1", "GRAY4", "the guard post");
		case U_COMMAND:   return Room(t, RF_TECH | RF_PEOPLE | RF_VALUE, 0, 144, 128, "CWRAISF", "CWCEILD", "AXDEFW", "the command centre");
		case U_ARMOURY:   return Room(t, RF_VALUE, 0, 104, 128, "AXF06C", "CEIL5_1", "AXW44A", "the armoury");
		case U_VAULT:     return Room(t, RF_VALUE, 0, 104, 120, "AXF06C", "CWCEILD", "AXW44A", "the vault");
		case U_COMMS:     return Room(t, RF_TECH, 0, 112, 120, "CWRAISF", "CWCEILD", "CWSRVWL", "the comms room");
		case U_BUNKS:     return Room(t, RF_CIV | RF_PEOPLE, 0, 104, 120, "FLOOR4_1", "CEIL1_1", "GRAY4", "the bunk room");
		case U_MESS:      return Room(t, RF_CIV, 0, 112, 150, "FLOOR4_1", "CEIL1_1", "GRAY4", "the mess");
		case U_GENERATOR: return Room(t, RF_TECH, 0, 144, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", "the generator hall");
		case U_ESCAPE:    return Room(t, RF_NOGUARD | RF_DARK | RF_RUBBLE, 0, 104, 72, "FLOOR4_8", "CEIL5_1", "GRAY4", "the escape tunnel");
		case U_CORR:      return Room(t, RF_PATROL, 0, 112, 136, bunker ? "FLOOR4_8" : "CWTILEF", "CEIL5_1", bunker ? "GRAY4" : "CWTILEW", "the corridor");
		case U_MEDBAY:    return Room(t, RF_PEOPLE | RF_CIV, 0, 112, 176, "CWTILEF", "CWCEILL", "CWTILEW", "the med bay");
		case U_WATER:     return Room(t, RF_TECH, 0, 144, 112, "FLOOR4_8", "CEIL5_1", "SUPPORT3", "the water plant");
		}
		return Room(t, 0, 0, 112, 112, "FLOOR4_8", "CEIL5_1", cw, "a room");
	}

	// bags of room types for Blocks
	void Bag(Array<int> bag, int a, int b = -1, int c = -1, int d = -1, int e = -1, int f = -1, int g = -1, int h = -1)
	{
		bag.Clear();
		bag.Push(a);
		if (b >= 0) bag.Push(b); if (c >= 0) bag.Push(c); if (d >= 0) bag.Push(d);
		if (e >= 0) bag.Push(e); if (f >= 0) bag.Push(f); if (g >= 0) bag.Push(g); if (h >= 0) bag.Push(h);
	}
	int FirstOfType(int t) { for (int r = 0; r < rtype.Size(); r++) if (rtype[r] == t && CellCount(r)) return r; return -1; }
	// an entry in the middle of a room's first cell, facing into the map
	void RoomEntry(int r, String name, int kind)
	{
		if (r < 0) return;
		Array<int> ci, cj; CellsOf(r, ci, cj);
		if (!ci.Size()) return;
		int k = Rand(0, ci.Size() - 1);
		Vector2 c = CellCenter(ci[k], cj[k]);
		Vector2 m = MapCenter();
		AddEntry(c, VectorAngle(m.x - c.x, m.y - c.y), name, kind, r);
	}
	// stairs in one cell, opening onto a neighbour; an entry on the stairs
	int Stairs(int i, int j, int toI, int toJ, String name, int kind)
	{
		int s = MakeRoom(U_STAIRS);
		Claim(s, i, j);
		Link(i, j, toI, toJ, E_WIDE);
		Vector2 c = CellCenter(i, j);
		Vector2 to = CellCenter(toI, toJ);
		AddEntry(c, VectorAngle(to.x - c.x, to.y - c.y), name, kind, s);
		return s;
	}

	override void Layout()
	{
		Array<int> bag;
		switch (variant)
		{
		// ------------------------------------------------------------------ tunnels and a storm drain
		case V_TUNNELS:
		{
			int jc = Rand(6, 7);
			int chan = MakeRoom(U_CHANNEL); Rect(chan, 0, jc, NX - 1, jc);
			int ws = MakeRoom(U_WALK); Rect(ws, 0, jc - 1, NX - 1, jc - 1);
			int wn = MakeRoom(U_WALK); Rect(wn, 0, jc + 1, NX - 1, jc + 1);
			LinkAll(ws, chan, E_WIDE); LinkAll(wn, chan, E_WIDE);
			// the service tunnels: a lattice off the walkways
			int tun = MakeRoom(U_TUNNEL);
			Array<int> cols;
			for (int x = Rand(1, 3); x <= NX - 2; x += Rand(3, 5)) cols.Push(x);
			for (int k = 0; k < cols.Size(); k++)
				for (int j = 1; j < NY - 1; j++) if (abs(j - jc) > 1) Claim(tun, cols[k], j);
			for (int i = cols[0]; i <= cols[cols.Size() - 1]; i++) { Claim(tun, i, 1); Claim(tun, i, NY - 2); }
			LinkAll(tun, ws, E_ARCH); LinkAll(tun, wn, E_ARCH);
			// footbridges over the drain
			for (int n = 0; n < 2; n++)
			{
				int bx = cols[Rand(0, cols.Size() - 1)];
				if (At(bx, jc) != chan) continue;
				int br = MakeRoom(U_BRIDGE); Claim(br, bx, jc);
				Link(bx, jc, bx, jc - 1, E_WIDE); Link(bx, jc, bx, jc + 1, E_WIDE);
				Link(bx, jc, bx - 1, jc, E_FENCE); Link(bx, jc, bx + 1, jc, E_FENCE);
			}
			// ways in: street stairs at either end of the lattice, a manhole, the drain outfall
			Stairs(cols[0], 0, cols[0], 1, "the stairs from the street", EK_FRONT);
			int lx = cols[cols.Size() - 1];
			Stairs(lx, NY - 1, lx, NY - 2, "the back stairs", EK_BACK);
			RoomEntry(tun, "a manhole", EK_ROOF);
			AddEntry(CellCenter(0, jc - 1), 0, "the drain outfall", EK_SERVICE, ws);
			// dead rock, then chambers in the gaps
			for (int n = 0; n < 5; n++) { int x = Rand(0, NX - 2), y = Rand(0, NY - 2); for (int dy = 0; dy < 2; dy++) for (int dx = 0; dx < 2; dx++) if (FreeCell(x + dx, y + dy)) cellFac[(y + dy) * NX + x + dx] = "BRICK10"; }
			Bag(bag, U_CHAMBER, U_CAMP, U_PUMP, U_CACHE, U_HIDEOUT, U_STORE, U_CONTROL, U_CAMP);
			Blocks(0, 0, NX - 1, NY - 1, bag, 3, 2, tun, E_DOOR, ws);
			break;
		}
		// ------------------------------------------------------------------ a pedestrian underpass under a junction
		case V_UNDERPASS:
		{
			int ph = MakeRoom(U_PASSAGE); Rect(ph, 0, 6, NX - 1, 7); rName[ph] = "the east-west passage";
			int pv = MakeRoom(U_PASSAGE); Rect(pv, 7, 0, 8, NY - 1); rName[pv] = "the north-south passage";
			int ci = MakeRoom(U_CIRCUS); Rect(ci, 6, 5, 9, 8);
			LinkAll(ph, ci, E_WIDE); LinkAll(pv, ci, E_WIDE);
			// stairs up at the four ends
			int s1 = MakeRoom(U_STAIRS); Rect(s1, 7, 0, 8, 0);
			int s2 = MakeRoom(U_STAIRS); Rect(s2, 7, NY - 1, 8, NY - 1);
			int s3 = MakeRoom(U_STAIRS); Rect(s3, 0, 6, 0, 7);
			int s4 = MakeRoom(U_STAIRS); Rect(s4, NX - 1, 6, NX - 1, 7);
			LinkAll(s1, pv, E_WIDE); LinkAll(s2, pv, E_WIDE); LinkAll(s3, ph, E_WIDE); LinkAll(s4, ph, E_WIDE);
			AddEntry(CellCenter(7, 0) + (40, 0), 90, "the south stairs", EK_FRONT, s1);
			AddEntry(CellCenter(7, NY - 1) + (40, 0), 270, "the north stairs", EK_BACK, s2);
			AddEntry(CellCenter(0, 6) + (0, 40), 0, "the west stairs", EK_ANY, s3);
			AddEntry(CellCenter(NX - 1, 6) + (0, 40), 180, "the east stairs", EK_ANY, s4);
			// shops and back rooms in the four quadrants, a band three deep round the passages
			Bag(bag, U_KIOSK, U_KIOSK, U_TOILET, U_HIDEOUT, U_MAINT, U_KIOSK, U_CAMP, U_STORE);
			Blocks(4, 3, 6, 5, bag, 2, 2, ph, E_DOOR, pv);
			Blocks(9, 3, 11, 5, bag, 2, 2, ph, E_DOOR, pv);
			Blocks(4, 8, 6, 10, bag, 2, 2, ph, E_DOOR, pv);
			Blocks(9, 8, 11, 10, bag, 2, 2, ph, E_DOOR, pv);
			Blocks(1, 4, 3, 5, bag, 2, 2, ph);
			Blocks(1, 8, 3, 9, bag, 2, 2, ph);
			Blocks(12, 4, 14, 5, bag, 2, 2, ph);
			Blocks(12, 8, 14, 9, bag, 2, 2, ph);
			Blocks(5, 1, 6, 2, bag, 2, 2, pv);
			Blocks(9, 1, 10, 2, bag, 2, 2, pv);
			Blocks(5, 11, 6, 12, bag, 2, 2, pv);
			Blocks(9, 11, 10, 12, bag, 2, 2, pv);
			// a service hatch in a maintenance room
			int mr = FirstOfType(U_MAINT);
			if (mr >= 0) RoomEntry(mr, "the service hatch", EK_SERVICE);
			break;
		}
		// ------------------------------------------------------------------ a transit station
		case V_TRANSIT:
		{
			int conc = MakeRoom(U_CONCOURSE); Rect(conc, 3, 1, 12, 3);
			int paid = MakeRoom(U_PAID); Rect(paid, 5, 4, 10, 5);
			LinkAll(conc, paid, E_FENCE);
			LinkRooms(conc, paid, E_WIDE, CellCenter(6, 4)); LinkRooms(conc, paid, E_WIDE, CellCenter(9, 4));
			int pas = MakeRoom(U_PASSAGE); Rect(pas, 7, 6, 8, 7); rName[pas] = "the stairs to the platforms";
			LinkAll(paid, pas, E_WIDE);
			int p1 = MakeRoom(U_PLATFORM); Rect(p1, 1, 8, NX - 2, 9); rName[p1] = "the westbound platform";
			LinkAll(pas, p1, E_WIDE);
			int trk = MakeRoom(U_TRACK); Rect(trk, 0, 10, NX - 1, 11);
			int p2 = MakeRoom(U_PLATFORM); Rect(p2, 1, 12, NX - 2, 12); rName[p2] = "the eastbound platform";
			LinkAll(p1, trk, E_WIDE); LinkAll(p2, trk, E_WIDE);
			Stairs(4, 0, 4, 1, "the station entrance", EK_FRONT);
			Stairs(11, 0, 11, 1, "the side entrance", EK_BACK);
			AddEntry(CellCenter(0, 10) + (0, 40), 0, "the track tunnel", EK_SERVICE, trk);
			// staff rooms round the concourse, a staff corridor behind the far platform
			Bag(bag, U_TICKET, U_STAFF, U_CASH, U_CONTROL, U_TOILET, U_LOCKER, U_STORE, U_KIOSK);
			Blocks(0, 1, NX - 1, 7, bag, 3, 2, conc, E_DOOR, paid);
			Bag(bag, U_RELAY, U_STORE, U_MAINT, U_STAFF);
			Blocks(1, 13, NX - 2, 13, bag, 3, 1, p2);
			int mr = FirstOfType(U_MAINT);
			if (mr >= 0) RoomEntry(mr, "an emergency shaft", EK_ROOF);
			break;
		}
		// ------------------------------------------------------------------ a parking garage level
		case V_PARKING:
		{
			int deck = MakeRoom(U_DECK); Rect(deck, 1, 1, NX - 2, NY - 2);
			for (int j = 4; j <= NY - 4; j += 4) for (int i = 4; i <= NX - 4; i += 4) { roomOf[j * NX + i] = -1; cellFac[j * NX + i] = "CWCONCW"; }
			int ramp = MakeRoom(U_RAMP); Rect(ramp, 6, 0, 8, 0);
			LinkAll(ramp, deck, E_WIDE);
			AddEntry(CellCenter(7, 0), 90, "the vehicle ramp", EK_FRONT, ramp);
			int booth = MakeRoom(U_BOOTH); Claim(booth, 9, 0);
			Link(9, 0, 8, 0, E_WINDOW); Link(9, 0, 9, 1, E_DOOR);
			Stairs(0, NY - 2, 1, NY - 2, "the stairwell", EK_BACK);
			Stairs(NX - 1, NY - 2, NX - 2, NY - 2, "the stairs from the level above", EK_ROOF);
			int lift = MakeRoom(U_LIFT); Rect(lift, 7, NY - 1, 8, NY - 1); LinkRooms(lift, deck, E_WIDE);
			Bag(bag, U_CAGE, U_PLANT, U_STORE, U_SECURITY, U_CAGE, U_OFFICE, U_MAINT);
			Blocks(0, 0, NX - 1, NY - 1, bag, 3, 2, deck);
			int mr = FirstOfType(U_MAINT);
			if (mr >= 0) RoomEntry(mr, "the service door", EK_SERVICE);
			break;
		}
		// ------------------------------------------------------------------ a hydroponic farm
		case V_FARM:
		{
			int corr = MakeRoom(U_CORR);
			Rect(corr, 1, 6, NX - 2, 7);
			Rect(corr, 7, 1, 8, NY - 2);
			// grow halls in the four quarters, each behind an airlock
			for (int q = 0; q < 4; q++)
			{
				if (q == 3 && Chance(40)) continue;
				int x0 = q % 2 ? 9 : 1, y0 = q < 2 ? 1 : 8;
				int w = 6, h = 5;
				int g = MakeRoom(U_GROW);
				int gx0 = x0 + (q % 2 ? 0 : 6 - w), gy0 = y0 + (q < 2 ? 5 - h : 0);
				Rect(g, gx0, gy0, gx0 + w - 1, gy0 + h - 1);
				// shrink: leave the column by the spine for rooms
				for (int j = gy0; j < gy0 + h; j++) { int ex = q % 2 ? gx0 : gx0 + w - 1; roomOf[j * NX + ex] = -1; }
				int ax = q % 2 ? gx0 + 1 : gx0 + w - 2, ay = q < 2 ? gy0 + h - 1 : gy0;
				int lock = MakeRoom(U_AIRLOCK); Claim(lock, ax, ay);
				Link(ax, ay, ax, q < 2 ? ay + 1 : ay - 1, E_DOOR);
				Link(ax, ay, ax, q < 2 ? ay - 1 : ay + 1, E_DOOR);
			}
			int dock = MakeRoom(U_DOCK); Rect(dock, NX - 1, 5, NX - 1, 8); LinkAll(dock, corr, E_WIDE);
			AddEntry(CellCenter(NX - 1, 6) + (0, 40), 180, "the loading bay", EK_SERVICE, dock);
			Stairs(0, 6, 1, 6, "the stairs from the street", EK_FRONT);
			Stairs(7, 0, 7, 1, "the fire stairs", EK_BACK);
			Stairs(8, NY - 1, 8, NY - 2, "the vent shaft ladder", EK_ROOF);
			Bag(bag, U_NUTRIENT, U_OFFICE, U_SEEDS, U_PACKING, U_LOCKER, U_CONTROL, U_PUMP, U_STAFF);
			Blocks(0, 0, NX - 1, NY - 1, bag, 2, 3, corr);
			break;
		}
		// ------------------------------------------------------------------ a bunker
		case V_BUNKER:
		{
			// the entrance tunnel, the blast door, the decon lock, then a corridor ring
			int tun = MakeRoom(U_TUNNEL); Rect(tun, 7, 0, 7, 2);
			AddEntry(CellCenter(7, 0), 90, "the entrance tunnel", EK_FRONT, tun);
			int post = MakeRoom(U_POST); Claim(post, 8, 2); Link(8, 2, 7, 2, E_WINDOW);
			int lock = MakeRoom(U_AIRLOCK); rName[lock] = "the decon lock"; Claim(lock, 7, 3);
			Link(7, 2, 7, 3, E_DOOR);
			int corr = MakeRoom(U_CORR);
			Rect(corr, 2, 4, NX - 3, 4); Rect(corr, 2, NY - 4, NX - 3, NY - 4);
			Rect(corr, 2, 4, 2, NY - 4); Rect(corr, NX - 3, 4, NX - 3, NY - 4);
			Link(7, 3, 7, 4, E_DOOR);
			Link(8, 2, 8, 3, E_DOOR);  // the post's back door, via a cell of the lock row
			int pc = MakeRoom(U_CORR); Claim(pc, 8, 3); Link(8, 3, 8, 4, E_DOOR);
			// the command centre in the middle, flanked
			int cmd = MakeRoom(U_COMMAND); Rect(cmd, 6, 6, 9, 7);
			LinkRooms(cmd, corr, E_DOOR, CellCenter(7, 5));
			Bag(bag, U_COMMS, U_ARMOURY, U_VAULT, U_STORE);
			Blocks(3, 5, NX - 4, NY - 5, bag, 3, 2, corr);
			LinkRooms(cmd, At(5, 6), E_DOOR);
			// the outer rooms
			Bag(bag, U_BUNKS, U_MESS, U_GENERATOR, U_WATER, U_MEDBAY, U_STORE, U_BUNKS, U_ARMOURY);
			Blocks(0, 0, NX - 1, NY - 1, bag, 3, 3, corr);
			// the escape tunnel out of the far corner, an air shaft
			int esc = MakeRoom(U_ESCAPE);
			int ex = Chance(50) ? 0 : NX - 1;
			roomOf[(NY - 1) * NX + ex] = esc;
			AddEntry(CellCenter(ex, NY - 1), ex ? 180 : 0, "the escape tunnel", EK_BACK, esc);
			if (!LinkRooms(esc, At(ex, NY - 2), E_DOOR)) LinkRooms(esc, At(ex ? ex - 1 : 1, NY - 1), E_DOOR);
			int gen = FirstOfType(U_GENERATOR);
			if (gen >= 0) RoomEntry(gen, "the air shaft", EK_ROOF);
			break;
		}
		}
	}

	override int ObjScore(int r, int k)
	{
		if (variant == V_BUNKER && k == OBJ_DESTROY && IsType(r, U_COMMAND)) return 150;
		if (IsType(r, U_POST) || IsType(r, U_BOOTH)) return k == OBJ_TURN ? 12 : 0;
		return Super.ObjScore(r, k);
	}

	override int LampStyle(int r)
	{
		switch (rtype[r])
		{
		case U_OFFICE: case U_TICKET: case U_KIOSK: case U_STAFF: case U_MEDBAY: case U_LIFT: return 0;
		case U_CONCOURSE: case U_PAID: case U_PLATFORM: case U_PASSAGE: case U_CIRCUS: case U_GROW: return 3;
		case U_CONTROL: case U_COMMAND: case U_COMMS: case U_RELAY: return 1;
		}
		return 2;
	}

	override void Dress(int r)
	{
		Array<int> ci, cj; CellsOf(r, ci, cj);
		switch (rtype[r])
		{
		case U_TUNNEL: case U_WALK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(12)) PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3));
			break;
		case U_CHAMBER: case U_PUMP: case U_WATER:
			for (int k = 0; k < ci.Size(); k++) { if (Chance(50)) PutInCell("CW_FTank", ci[k], cj[k]); PutWall("CW_FPipes", ci[k], cj[k], Rand(0, 3)); }
			break;
		case U_CAMP:
			LineWalls("CW_FBed", r, 90, 3); PutInRoom("CW_FScrap", r); PutInRoom("CW_FCrates", r);
			break;
		case U_CACHE: case U_STORE: case U_CAGE:
			LineWalls("CW_FShelving", r, 70, 4);
			for (int k = 0; k < ci.Size(); k++) if (Chance(60)) PutInCell("CW_FCrates", ci[k], cj[k]);
			break;
		case U_HIDEOUT:
			PutInRoom("CW_FRoundTable", r); LineWalls("CW_FSofa", r, 120, 1); LineWalls("CW_FCrates", r, 80, 2);
			break;
		case U_CONTROL: case U_RELAY: case U_COMMS:
			LineWalls("CW_FDeskCode", r, 80, 3); LineWalls(rtype[r] == U_CONTROL ? "CW_FWallTV" : "CW_FServerRack", r, 64, 4);
			break;
		case U_KIOSK:
			LineWalls("CW_FCounter", r, 120, 1); LineWalls("CW_FShelving", r, 90, 2);
			break;
		case U_TICKET: case U_OFFICE:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FFileCabinet", r, 70, 2);
			break;
		case U_CASH: case U_VAULT: case U_SEEDS:
			LineWalls("CW_FFileCabinet", r, 48, 4); PutInRoom("CW_FCrates", r);
			break;
		case U_TOILET:
			LineWalls("CW_FStalls", r, 90, 2); LineWalls("CW_FVanity", r, 90, 1);
			break;
		case U_STAFF: case U_MESS:
			PutInRoom("CW_FRoundTable", r); LineWalls("CW_FVending", r, 90, 1); LineWalls("CW_FCounter", r, 120, 1);
			break;
		case U_LOCKER:
			LineWalls("CW_FLocker", r, 50, 5);
			break;
		case U_PAID:
			for (int k = 0; k < ci.Size(); k++) if (cj[k] == 4 && ci[k] % 2) Put("CW_FTurnstile", CellCenter(ci[k], cj[k]) + (0, -30), 90);
			break;
		case U_PLATFORM: case U_CIRCUS: case U_CONCOURSE:
			for (int k = 0; k < ci.Size(); k++) if (Chance(18)) PutInCell("CW_FPew", ci[k], cj[k], 0);
			break;
		case U_DECK:
			for (int k = 0; k < ci.Size(); k++)
			{
				if (ci[k] >= 6 && ci[k] <= 9) continue;                   // the drive lane in from the ramp
				if (Chance(55)) Car(CellCenter(ci[k], cj[k]), Chance(50) ? 90 : 270);
			}
			break;
		case U_BOOTH: case U_SECURITY: case U_POST:
			PutInRoom("CW_FDeskWork", r); LineWalls("CW_FWallTV", r, 90, 2);
			break;
		case U_PLANT: case U_GENERATOR: case U_MAINT:
			for (int k = 0; k < ci.Size(); k++) PutInCell(Chance(50) ? "CW_FGenerator" : "CW_FTransformer", ci[k], cj[k], 90 * Rand(0, 3));
			LineWalls("CW_FPipes", r, 140, 2);
			break;
		case U_GROW:
			for (int k = 0; k < ci.Size(); k++) Put("CW_FGrowBed", CellCenter(ci[k], cj[k]), 90);
			break;
		case U_NUTRIENT:
			LineWalls("CW_FTank", r, 90, 4); PutInRoom("CW_FPipes", r);
			break;
		case U_PACKING: case U_DOCK:
			for (int k = 0; k < ci.Size(); k++) if (Chance(50)) PutInCell(Chance(50) ? "CW_FPallet" : "CW_FCrates", ci[k], cj[k]);
			if (rtype[r] == U_PACKING) LineWalls("CW_FWorkbench", r, 100, 3);
			break;
		case U_COMMAND:
			for (int k = 0; k < ci.Size(); k++) Put("CW_FDeskCode", CellCenter(ci[k], cj[k]), 90);
			LineWalls("CW_FWallTV", r, 80, 6);
			break;
		case U_ARMOURY:
			LineWalls("CW_FLocker", r, 50, 5); PutInRoom("CW_FCrates", r);
			break;
		case U_BUNKS:
			LineWalls("CW_FBed", r, 70, 6); LineWalls("CW_FLocker", r, 80, 2);
			break;
		case U_MEDBAY:
			LineWalls("CW_FBed", r, 90, 3); LineWalls("CW_FLabBench", r, 120, 1);
			break;
		}
	}
}
