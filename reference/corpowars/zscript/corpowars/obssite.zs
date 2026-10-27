// =============================================================================
// Corpo Wars — sites built by Obsidian (the map pools: industrial CWI/CWJ, underground CWU/CWV; see Design Docs/obsidian-maps.md)
//
// Obsidian builds the architecture and leaves marker things behind (CorpoWars addon, corpowars.lua):
//   30200 + role   one per room, at its middle          angle = room id * 128 + depth (0 start .. 100 exit)
//   30110..30113   free floor spots of a room            angle = room id (plain / goal / start / exit spot)
//   30120 + kind   entry points (2 front 3 back 4 service 5 roof), angle = facing
//   30130          a light fitting
// CW_ObsSite reads them when the map loads and runs the mission on top: doors become Corpo Wars doors,
// the exits are defused, rooms get lamps and furniture, objectives, guards, bystanders, extraction and the
// drop crate go in, and the player is put at the chosen entry.
// =============================================================================

class CW_ObsMarker : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; +NOGRAVITY; +DONTSPLASH; RenderStyle "None"; Radius 4; Height 4; }
	States { Spawn: TNT1 A -1; Stop; }
}
class CW_ObsRoom : CW_ObsMarker { int role; property Role: role; }
class CW_ObsSpot : CW_ObsMarker { int spotKind; property SpotKind: spotKind; }
class CW_ObsEntry : CW_ObsMarker { int entryKind; property EntryKind: entryKind; }
class CW_ObsLamp : CW_ObsMarker {}
class CW_ObsWindow : CW_ObsMarker {}   // a window prefab: the player may climb through
class CW_ObsDuct : CW_ObsMarker {}     // a point inside a crawl duct (angle = hallway room id)

// Stands in for the player when checking where the player fits (CheckPosition).
class CW_ObsProbe : Actor
{
	Default { Radius 17; Height 56; +SOLID; +NOBLOCKMAP; +NOGRAVITY; +DONTSPLASH; +NOTELEPORT; RenderStyle "None"; }
	States { Spawn: TNT1 A -1; Stop; }
}

class CW_ObsSpot0 : CW_ObsSpot { Default { CW_ObsSpot.SpotKind 0; } }   // plain
class CW_ObsSpot1 : CW_ObsSpot { Default { CW_ObsSpot.SpotKind 1; } }   // goal (a key / switch went here)
class CW_ObsSpot2 : CW_ObsSpot { Default { CW_ObsSpot.SpotKind 2; } }   // start
class CW_ObsSpot3 : CW_ObsSpot { Default { CW_ObsSpot.SpotKind 3; } }   // exit
class CW_ObsEntry2 : CW_ObsEntry { Default { CW_ObsEntry.EntryKind 2; } }
class CW_ObsEntry3 : CW_ObsEntry { Default { CW_ObsEntry.EntryKind 3; } }
class CW_ObsEntry4 : CW_ObsEntry { Default { CW_ObsEntry.EntryKind 4; } }
class CW_ObsEntry5 : CW_ObsEntry { Default { CW_ObsEntry.EntryKind 5; } }
class CW_ObsRoom00 : CW_ObsRoom { Default { CW_ObsRoom.Role 0; } }
class CW_ObsRoom01 : CW_ObsRoom { Default { CW_ObsRoom.Role 1; } }
class CW_ObsRoom02 : CW_ObsRoom { Default { CW_ObsRoom.Role 2; } }
class CW_ObsRoom03 : CW_ObsRoom { Default { CW_ObsRoom.Role 3; } }
class CW_ObsRoom04 : CW_ObsRoom { Default { CW_ObsRoom.Role 4; } }
class CW_ObsRoom05 : CW_ObsRoom { Default { CW_ObsRoom.Role 5; } }
class CW_ObsRoom06 : CW_ObsRoom { Default { CW_ObsRoom.Role 6; } }
class CW_ObsRoom07 : CW_ObsRoom { Default { CW_ObsRoom.Role 7; } }
class CW_ObsRoom08 : CW_ObsRoom { Default { CW_ObsRoom.Role 8; } }
class CW_ObsRoom09 : CW_ObsRoom { Default { CW_ObsRoom.Role 9; } }
class CW_ObsRoom10 : CW_ObsRoom { Default { CW_ObsRoom.Role 10; } }
class CW_ObsRoom11 : CW_ObsRoom { Default { CW_ObsRoom.Role 11; } }
class CW_ObsRoom12 : CW_ObsRoom { Default { CW_ObsRoom.Role 12; } }
class CW_ObsRoom13 : CW_ObsRoom { Default { CW_ObsRoom.Role 13; } }
class CW_ObsRoom14 : CW_ObsRoom { Default { CW_ObsRoom.Role 14; } }
class CW_ObsRoom15 : CW_ObsRoom { Default { CW_ObsRoom.Role 15; } }
class CW_ObsRoom16 : CW_ObsRoom { Default { CW_ObsRoom.Role 16; } }
class CW_ObsRoom17 : CW_ObsRoom { Default { CW_ObsRoom.Role 17; } }
class CW_ObsRoom18 : CW_ObsRoom { Default { CW_ObsRoom.Role 18; } }
class CW_ObsRoom19 : CW_ObsRoom { Default { CW_ObsRoom.Role 19; } }

// A door Obsidian built (a Doom door sector) run by the Corpo Wars door logic: it opens and closes through the
// manual door specials on its own faces, so it needs no sector tag.
class CW_ObsDoor : CW_Door
{
	Line doorLine;      // a face whose back sector is the door
	const DOOR_OPEN = 11;     // Door_Open(tag, speed)
	const DOOR_CLOSE = 10;    // Door_Close(tag, speed)
	const OBS_SPEED = 24;

	override void SetUsable(bool usable)
	{
		Sector ds = level.PointInSector(pos.xy);
		for (int l = 0; l < ds.lines.Size(); l++)
		{
			Line ln = ds.lines[l];
			if (!ln.sidedef[1] || ln.backsector != ds) continue;
			if (!usable) { ln.special = 0; continue; }
			ln.special = DOOR_OPEN;
			ln.args[0] = 0; ln.args[1] = OBS_SPEED; ln.args[2] = 0; ln.args[3] = 0; ln.args[4] = 0;
			ln.activation = SPAC_Use | SPAC_MUse;
			ln.flags |= Line.ML_REPEAT_SPECIAL | Line.ML_MONSTERSCANACTIVATE;
		}
	}

	int doorSecTag;     // tagged doors (Obsidian's switch-opened ones) are driven by tag

	override void SetDoor(bool open)
	{
		if (doorSecTag) level.ExecuteSpecial(open ? DOOR_OPEN : DOOR_CLOSE, null, null, 0, doorSecTag, OBS_SPEED);
		else if (doorLine) level.ExecuteSpecial(open ? DOOR_OPEN : DOOR_CLOSE, null, doorLine, 0, 0, OBS_SPEED);
		if (primed) DoorSound(open);
		primed = true;
		isOpen = open;
		idle = 0;
		if (!open) openedBy = OB_NONE;
	}
}

class CW_ObsSite play
{
	// ---- the mission's site
	int siteForce, siteTech, visitSeed, entryPref;
	bool siteSet, neutralSite;
	String pool;              // "CWI", ...
	int variant;
	int rng, seed0, guards, civs;

	// ---- what the markers said
	Array<int> rId, rRole, rDepth, rFlags;       // rooms
	Array<double> rX, rY;
	Array<String> rName;
	Array<int> sRoom, sKind;                     // spots
	Array<double> sX, sY;
	Array<double> enX, enY, enA;                 // entries
	Array<int> enKind, enRoom;
	Array<String> enName;
	Array<CW_Door> doors;

	// sector state: planned ceilings (ducts, doors), ducts, lifts, walkable regions
	Array<double> ceilPlan;
	Array<int> secDuct, secFlex, secDoor, regP, regG;
	int mainReg;                // -1 until the regions are known (set in Generate)
	int ductRooms, windowsOpened, entriesDropped, entriesMoved;
	double putMargin;
	CW_ObsProbe probe;
	Array<int> rDark;           // rooms left in the dark (lights off after hours)
	// underground mood lighting (cw_undermood): accent rooms get a coloured tint and coloured lamps
	int mood;                   // 0 off, 1 gold, 2 green, 3 crimson, 4 cool blue, 5 mixed
	Array<int> rTint;           // per room: accent colour 0-3, or -1
	static const String MOOD_NAMES[] = { "plain", "soft gold", "green", "crimson", "cool blue", "mixed" };
	static const int TINT_SEC[] = { 0xFFE2AA, 0xBEFFC8, 0xFFB0AA, 0xAFCDFF };   // sector tint: gentle, so the room still reads
	static const int TINT_LR[] = { 255, 110, 255, 110 };                       // lamp colour: the accent itself
	static const int TINT_LG[] = { 196, 255, 64, 170 };
	static const int TINT_LB[] = { 110, 150, 64, 255 };
	Array<double> exX, exY;     // extraction points (against a wall near each entry)
	int coverPlaced;
	const DUCT_H = 44;          // crawl-duct headroom (the player crouches to 28)
	const CROUCH_H = 32;        // what the player needs to get through at all
	const WALK_H = 56;          // what a guard needs

	int insertIdx;
	Vector2 insertPos;
	double insertAng;
	String insertName, siteName;
	int objRoom[4];

	enum ERoomFlag { RF_OUT = 1, RF_CIV = 2, RF_VALUE = 4, RF_TECH = 8, RF_PEOPLE = 16, RF_PATROL = 32, RF_NOGUARD = 64, RF_DARK = 128, RF_UNREACH = 256 }
	enum EEntryKind { EK_ANY, EK_GARAGE, EK_FRONT, EK_BACK, EK_SERVICE, EK_ROOF }
	const SAFE_R = 480;

	// ================================================================ the pool
	static clearscope bool IsPoolMap(String m)
	{
		if (m.Length() != 5 || m.Left(2) != "CW") return false;
		int c = m.ByteAt(2);
		if (c < 65 || c > 90) return false;
		return m.ByteAt(3) >= 48 && m.ByteAt(3) <= 57 && m.ByteAt(4) >= 48 && m.ByteAt(4) <= 57;
	}
	// maps of a pool that are actually present (the launcher builds them with Obsidian)
	static int PoolSize(String prefix)
	{
		int n = 0;
		for (int k = 1; k <= 32; k++) if (LevelInfo.MapExists(String.Format("%s%02d", prefix, k))) n = k; else break;
		return n;
	}
	// Size tiers: a pool's maps 1-4 are small, 5-8 medium, 9-11 large (corpowars.lua CORPOWARS.tier_of).
	enum ETier { TIER_S, TIER_M, TIER_L, TIER_ANY }
	static int TierFirst(int tier) { static const int f[] = { 1, 5, 9, 1 }; return f[clamp(tier, 0, 3)]; }
	static int TierLast(int tier) { static const int l[] = { 4, 8, 32, 32 }; return l[clamp(tier, 0, 3)]; }
	// a site's map: a corp property keeps its map while the pool lasts (seed), a neutral site gets any of its size
	static String PoolMap(String prefix, int seed, int tier = TIER_ANY)
	{
		int n = PoolSize(prefix);
		if (n <= 0) return "";
		int a = TierFirst(tier), b = min(TierLast(tier), n);
		if (a > b) { a = 1; b = n; }          // a short pool: any map
		return String.Format("%s%02d", prefix, a + abs(seed) % (b - a + 1));
	}

	// Which pool stands in for which in-engine kit (CW_KitGen.EKit). Each site type has two map-name sets
	// (industrial: CWI.. and CWJ..): the launcher builds the next pool under the other set and keeps the last
	// one loaded, so saves and job offers that point at the old maps still work. cw_pool_<site> names the
	// current set; without it, whichever set is present.
	static String PoolOfKit(int kit)
	{
		String a, b, cv;
		switch (kit)
		{
		case 3: a = "CWI"; b = "CWJ"; cv = "cw_pool_industrial"; break;
		case 4: a = "CWU"; b = "CWV"; cv = "cw_pool_underground"; break;
		default: return "";
		}
		let v = CVar.FindCVar(cv);
		String cur = v ? v.GetString() : "";
		if ((cur ~== a || cur ~== b) && PoolSize(cur) > 0) return cur;
		if (PoolSize(a) > 0) return a;
		if (PoolSize(b) > 0) return b;
		return a;
	}

	void SetupSite(int force, int tech, bool neutral, int visit, int pref)
	{
		siteSet = true;
		siteForce = force; siteTech = tech; neutralSite = neutral; visitSeed = visit; entryPref = pref;
	}

	// ================================================================ RNG
	int Rand(int lo, int hi)
	{
		rng = rng * 1103515245 + 12345;
		int r = (rng >>> 16) & 0x7fff;
		return hi <= lo ? lo : lo + r % (hi - lo + 1);
	}
	bool Chance(int pct) { return Rand(0, 99) < pct; }

	// ================================================================ site tables
	// industrial roles (corpowars_sites.lua CORPOWARS.IR)
	enum EIndRole { IR_ROOM, IR_YARD, IR_CORRIDOR, IR_HALL, IR_WORKSHOP, IR_PLANT, IR_CONTROL, IR_OFFICE, IR_STORE, IR_LOADING, IR_CREW }

	int RoleFlags(int role)
	{
		switch (role)
		{
		case IR_YARD:     return RF_OUT | RF_PATROL | RF_CIV;
		case IR_CORRIDOR: return RF_PATROL;
		case IR_HALL:     return RF_PATROL | RF_CIV | RF_VALUE | RF_TECH;
		case IR_WORKSHOP: return RF_CIV | RF_TECH;
		case IR_PLANT:    return RF_TECH;
		case IR_CONTROL:  return RF_TECH | RF_PEOPLE;
		case IR_OFFICE:   return RF_VALUE | RF_PEOPLE | RF_CIV;
		case IR_STORE:    return RF_VALUE;
		case IR_LOADING:  return RF_PATROL | RF_CIV;
		case IR_CREW:     return RF_CIV | RF_PEOPLE;
		}
		return RF_PATROL | RF_CIV;
	}

	// which site type this pool map is (the pool prefix; the role numbers are shared, the names differ)
	static clearscope bool UnderPool(String m) { String p = m.Left(3); return p ~== "CWU" || p ~== "CWV"; }
	bool Under() { return UnderPool(level.MapName); }

	static const String IND_VARIANTS[] = { "warehouse", "sea dock", "fabrication plant", "power plant", "substation", "industrial park", "salvage yard", "construction site" };
	static const String UND_VARIANTS[] = { "maintenance tunnels", "underpass", "transit station", "parking garage", "hydroponic farm", "bunker" };
	static const String UND_HALLPROP[] = { "CW_FPipes", "CW_FVending", "CW_FVending", "CW_FBarrier", "CW_FGrowBed", "CW_FSandbags" };
	String VariantName() { return Under() ? UND_VARIANTS[clamp(variant, 0, 5)] : IND_VARIANTS[clamp(variant, 0, 7)]; }
	int VariantCount() { return Under() ? 6 : 8; }

	// underground (K04 variants): same roles, underground names
	String UnderRoleName(int role, int n)
	{
		switch (role)
		{
		case IR_YARD: case IR_HALL:
			switch (variant)
			{
			case 0: return "the pump chamber";
			case 1: return "the circus";
			case 2: return "the platform";
			case 3: return "the parking deck";
			case 4: return "the grow hall";
			case 5: return "the command centre";
			}
			return "a chamber";
		case IR_CORRIDOR: return variant == 2 ? "a staff passage" : "a service tunnel";
		case IR_WORKSHOP: return variant == 0 ? "a storm drain" : "a maintenance room";
		case IR_PLANT:    return variant == 4 ? "the nutrient plant" : "the plant room";
		case IR_CONTROL:  return variant == 2 ? "the signal room" : "the control room";
		case IR_OFFICE:   return variant == 3 ? "the attendant's booth" : (variant == 5 ? "the guard post" : "the staff office");
		case IR_STORE:    return variant == 5 ? "the armoury" : "a storeroom";
		case IR_LOADING:  return variant == 2 ? "the ticket hall" : (variant == 4 ? "the airlock" : "the concourse");
		case IR_CREW:     return variant == 5 ? "the bunk room" : "the mess room";
		}
		return "a room";
	}

	String RoleName(int role, int n)
	{
		if (Under()) return UnderRoleName(role, n);
		switch (role)
		{
		case IR_YARD:     return "the yard";
		case IR_CORRIDOR: return "a service corridor";
		case IR_HALL:
			switch (variant)
			{
			case 0: return "the warehouse floor";
			case 1: return "the dock warehouse";
			case 2: return "the fab floor";
			case 3: return "the turbine hall";
			case 4: return "the switch house";
			case 7: return "the half-built block";
			}
			return "a factory shed";
		case IR_WORKSHOP: return variant == 6 ? "the breaker's shed" : "a workshop";
		case IR_PLANT:    return variant == 3 ? "the boiler house" : "the plant room";
		case IR_CONTROL:  return "the control room";
		case IR_OFFICE:   return variant == 1 ? "the customs office" : "the site office";
		case IR_STORE:    return "a storeroom";
		case IR_LOADING:  return "the loading bay";
		case IR_CREW:     return "the crew room";
		}
		return "a building";
	}

	int Bystanders()
	{
		static const int n[] = { 5, 6, 6, 4, 1, 4, 2, 5 };
		static const int u[] = { 1, 6, 7, 3, 3, 1 };
		if (Under()) return u[clamp(variant, 0, 5)];
		return n[clamp(variant, 0, 7)];
	}

	String EntryName(int kind)
	{
		if (Under())
		{
			switch (kind)
			{
			case EK_FRONT:
				switch (variant)
				{
				case 0: return "a street manhole";
				case 2: return "the station entrance";
				case 3: return "the vehicle ramp";
				case 5: return "the entrance tunnel";
				}
				return "the street stairs";
			case EK_BACK:    return variant == 5 ? "the escape tunnel" : "the service shaft";
			case EK_SERVICE: return "a maintenance hatch";
			case EK_ROOF:    return "a storm drain";
			}
			return "the tunnels";
		}
		switch (kind)
		{
		case EK_FRONT:   return "the main gate";
		case EK_BACK:    return variant == 1 ? "the water side" : "the loading dock";
		case EK_SERVICE: return "a service door";
		case EK_ROOF:    return "over the back fence";
		}
		return "the site";
	}

	// ================================================================ reading the markers
	int RoomIndex(int id) { for (int k = 0; k < rId.Size(); k++) if (rId[k] == id) return k; return -1; }
	bool Has(int r, int f) { return r >= 0 && (rFlags[r] & f) != 0; }

	void ReadMarkers()
	{
		let it = ThinkerIterator.Create("CW_ObsMarker");
		CW_ObsMarker m;
		Array<CW_ObsSpot> spots;
		while (m = CW_ObsMarker(it.Next()))
		{
			let rm = CW_ObsRoom(m);
			if (rm)
			{
				int code = rm.SpawnAngle;
				rId.Push(code / 128); rDepth.Push(code % 128); rRole.Push(rm.role);
				rFlags.Push(RoleFlags(rm.role));
				rX.Push(rm.pos.x); rY.Push(rm.pos.y);
				rName.Push("");
				continue;
			}
			let sp = CW_ObsSpot(m);
			if (sp) { spots.Push(sp); continue; }
			let en = CW_ObsEntry(m);
			if (en)
			{
				enX.Push(en.pos.x); enY.Push(en.pos.y); enA.Push(en.SpawnAngle); enKind.Push(en.entryKind);
				enRoom.Push(-1); enName.Push(EntryName(en.entryKind));
				continue;
			}
		}
		// the room marker is also a spot of its room
		for (int r = 0; r < rId.Size(); r++) { sX.Push(rX[r]); sY.Push(rY[r]); sRoom.Push(r); sKind.Push(0); }
		for (int k = 0; k < spots.Size(); k++)
		{
			int r = RoomIndex(spots[k].SpawnAngle);
			if (r < 0) continue;
			sX.Push(spots[k].pos.x); sY.Push(spots[k].pos.y); sRoom.Push(r); sKind.Push(spots[k].spotKind);
		}
		for (int e = 0; e < enX.Size(); e++) enRoom[e] = NearestRoom((enX[e], enY[e]));
		// names: the first (biggest) room of a role gets the definite article
		Array<int> seenRole;
		for (int r = 0; r < rId.Size(); r++)
		{
			int n = 0;
			for (int q = 0; q < seenRole.Size(); q++) if (seenRole[q] == rRole[r]) n++;
			rName[r] = Ordinal(RoleName(rRole[r], n), n);
			seenRole.Push(rRole[r]);
		}
	}

	// "the warehouse floor" -> "the second warehouse floor" for the second room of a kind
	static String Ordinal(String name, int n)
	{
		static const String ords[] = { "", "second ", "third ", "fourth ", "fifth ", "sixth " };
		if (n <= 0 || name.Left(4) != "the ") return name;
		if (n > 5) return name .. " (" .. (n + 1) .. ")";
		return "the " .. ords[n] .. name.Mid(4);
	}

	int NearestRoom(Vector2 p)
	{
		int best = -1; double bd = 1e9;
		for (int k = 0; k < sX.Size(); k++)
		{
			double d = (p - (sX[k], sY[k])).Length();
			if (d < bd) { bd = d; best = sRoom[k]; }
		}
		return best;
	}

	// ================================================================ doors, exits, light
	static bool IsManualDoor(Line ln)
	{
		switch (ln.special)
		{
		case 10: case 11: case 12: case 13: case 14: case 202:   // Door_Close/Open/Raise/LockedRaise/Animated, Generic_Door
			return ln.args[0] == 0 && ln.backsector != null;
		}
		return false;
	}

	// A closed sector between two open ones: a door (the manual kind, or a tagged one a switch used to open).
	bool IsClosedDoor(Sector ds)
	{
		if (ds.ceilingplane.ZAtPoint(ds.centerspot) - ds.floorplane.ZAtPoint(ds.centerspot) > 4) return false;
		int open = 0;
		for (int l = 0; l < ds.lines.Size(); l++)
		{
			Line dl = ds.lines[l];
			Sector o = dl.frontsector == ds ? dl.backsector : dl.frontsector;
			if (!o) continue;
			if (o.ceilingplane.ZAtPoint(o.centerspot) - o.floorplane.ZAtPoint(o.centerspot) >= 56) open++;
		}
		return open >= 2 && ds.lines.Size() <= 16;
	}

	void ConvertDoors()
	{
		Array<Sector> done;
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line ln = level.lines[i];
			bool manual = IsManualDoor(ln);
			if (!manual && !(ln.backsector && ln.backsector.GetTag(0) > 0 && IsClosedDoor(ln.backsector))) continue;
			Sector ds = ln.backsector;
			bool seen = false;
			for (int k = 0; k < done.Size(); k++) if (done[k] == ds) { seen = true; break; }
			if (seen) continue;
			done.Push(ds);
			// open height: the lowest neighbouring ceiling, less 4 (as Doom does)
			double minC = 1e9;
			for (int l = 0; l < ds.lines.Size(); l++)
			{
				Line dl = ds.lines[l];
				Sector o = dl.frontsector == ds ? dl.backsector : dl.frontsector;
				if (o && o != ds) minC = min(minC, o.ceilingplane.ZAtPoint(o.centerspot));
				if (dl.special) { dl.special = 0; }
			}
			if (minC > 1e8) continue;
			double f = ds.floorplane.ZAtPoint(ds.centerspot);
			double openZ = max(f + 64, minC - 4);
			double c = ds.ceilingplane.ZAtPoint(ds.centerspot);
			if (openZ != c) ds.MoveCeiling(abs(openZ - c) + 1, ds.ceilingplane.PointToDist(ds.centerspot, openZ), -1, openZ > c ? 1 : -1, false);
			if (ceilPlan.Size()) { ceilPlan[ds.Index()] = openZ; secDoor[ds.Index()] = 1; }
			let dr = CW_ObsDoor(Actor.Spawn("CW_ObsDoor", (ds.centerspot, f)));
			if (!dr) continue;
			dr.doorLine = ln;
			if (!manual) dr.doorSecTag = ds.GetTag(0);
			dr.shutZ = f; dr.openZ = openZ; dr.doorIdx = doors.Size();
			doors.Push(dr);
		}
	}

	// the level exit becomes scenery: missions end at the extraction points
	void DefuseExits()
	{
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line ln = level.lines[i];
			switch (ln.special)
			{
			case 243: case 244: case 74: case 75: case 70: case 71:   // Exit_Normal/Secret, Teleport_NewMap/EndGame, Teleport(_NoFog)
				ln.special = 0;
				break;
			}
		}
	}

	// Obsidian's scenery border has sky for a floor; give it ground instead. And no hurting floors.
	void FixSkyFloors()
	{
		for (int i = 0; i < level.sectors.Size(); i++) { level.sectors[i].damageamount = 0; level.sectors[i].leakydamage = 0; }
		TextureID ground = TexMan.CheckForTexture("AXDU03", TexMan.Type_Any);
		if (!ground.IsValid()) return;
		for (int i = 0; i < level.sectors.Size(); i++)
			if (level.sectors[i].GetTexture(Sector.floor) == skyflatnum) level.sectors[i].SetTexture(Sector.floor, ground);
		// no liquid on ceilings (or anywhere): old prefabs used water and slime flats as light panels
		TextureID ceil = TexMan.CheckForTexture("CWCEILD", TexMan.Type_Any);
		TextureID grate = TexMan.CheckForTexture("AXF41", TexMan.Type_Any);
		for (int i = 0; i < level.sectors.Size(); i++)
		{
			Sector sec = level.sectors[i];
			if (IsLiquid(sec.GetTexture(Sector.ceiling)) && ceil.IsValid()) sec.SetTexture(Sector.ceiling, ceil);
			if (IsLiquid(sec.GetTexture(Sector.floor)) && grate.IsValid()) sec.SetTexture(Sector.floor, grate);
		}
	}
	static bool IsLiquid(TextureID t)
	{
		String n = TexMan.GetName(t).MakeUpper();
		return n.Left(6) == "FWATER" || n.Left(6) == "NUKAGE" || n.Left(5) == "SLIME" || n.Left(4) == "LAVA" || n.Left(5) == "BLOOD";
	}

	// ================================================================ geometry the game changes / checks
	void PrepSectors()
	{
		int n = level.sectors.Size();
		ceilPlan.Clear(); secDuct.Clear(); secFlex.Clear(); secDoor.Clear();
		for (int i = 0; i < n; i++) { ceilPlan.Push(-1e9); secDuct.Push(0); secFlex.Push(0); secDoor.Push(0); }
		// lifts and other moving floors: any tagged sector a line special points at connects to its neighbours
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line ln = level.lines[i];
			if (!ln.special || ln.args[0] <= 0) continue;
			let it = level.CreateSectorTagIterator(ln.args[0]);
			int k;
			while ((k = it.Next()) >= 0) secFlex[k] = 1;
		}
	}
	double CeilZ(Sector s, Vector2 p)
	{
		double c = ceilPlan.Size() ? ceilPlan[s.Index()] : -1e9;
		return c > -1e8 ? c : s.ceilingplane.ZAtPoint(p);
	}

	// Crawl ducts: the narrow service halls Obsidian marked get a ceiling the player must crouch under
	// (guards can't follow), a grate ceiling and little light.
	void BuildDucts()
	{
		Array<int> secs, ids, secRoom;
		let it = ThinkerIterator.Create("CW_ObsDuct");
		Actor m;
		while (m = Actor(it.Next()))
		{
			Sector s = level.PointInSector(m.pos.xy);
			if (!s || secDoor[s.Index()] || s.GetTexture(Sector.ceiling) == skyflatnum) continue;
			// only the open floor of the hall (not the solid bits of its prefab: raised blocks, pillars)
			if (s.ceilingplane.ZAtPoint(m.pos.xy) - s.floorplane.ZAtPoint(m.pos.xy) < 56) continue;
			// a duct is narrow: a wide sector here is a room next to the hall, not the hall
			double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
			for (int l = 0; l < s.lines.Size(); l++) { Vector2 v = s.lines[l].v1.p; x0 = min(x0, v.x); y0 = min(y0, v.y); x1 = max(x1, v.x); y1 = max(y1, v.y); }
			if (min(x1 - x0, y1 - y0) > 160) continue;
			if (secs.Find(s.Index()) == secs.Size()) { secs.Push(s.Index()); secRoom.Push(m.SpawnAngle); }
			if (ids.Find(m.SpawnAngle) == ids.Size()) ids.Push(m.SpawnAngle);
		}
		// the rest of the vent: neighbouring narrow, low sectors at the same floor level (vent prefabs are ~64 high)
		for (int h0 = 0; h0 < secs.Size() && secs.Size() < 400; h0++)
		{
			Sector a = level.sectors[secs[h0]];
			double fa = a.floorplane.ZAtPoint(a.centerspot);
			for (int l = 0; l < a.lines.Size(); l++)
			{
				Line ln = a.lines[l];
				Sector b = ln.frontsector == a ? ln.backsector : ln.frontsector;
				if (!b || secs.Find(b.Index()) != secs.Size() || secDoor[b.Index()] || b.GetTexture(Sector.ceiling) == skyflatnum) continue;
				double fb = b.floorplane.ZAtPoint(b.centerspot), cb = b.ceilingplane.ZAtPoint(b.centerspot);
				if (abs(fb - fa) > 16 || cb - fb < 56 || cb - fb > 96) continue;
				double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
				for (int q = 0; q < b.lines.Size(); q++) { Vector2 v = b.lines[q].v1.p; x0 = min(x0, v.x); y0 = min(y0, v.y); x1 = max(x1, v.x); y1 = max(y1, v.y); }
				if (min(x1 - x0, y1 - y0) > 160) continue;
				secs.Push(b.Index()); secRoom.Push(secRoom[h0]);
			}
		}
		// and only at the hall's own floor level (the most common floor height among its sectors)
		Array<int> keep;
		for (int k = 0; k < secs.Size(); k++)
		{
			double fk = level.sectors[secs[k]].floorplane.ZAtPoint(level.sectors[secs[k]].centerspot);
			int same = 0, total = 0;
			for (int q = 0; q < secs.Size(); q++)
			{
				if (secRoom[q] != secRoom[k]) continue;
				total++;
				if (abs(level.sectors[secs[q]].floorplane.ZAtPoint(level.sectors[secs[q]].centerspot) - fk) <= 16) same++;
			}
			keep.Push(same * 3 >= total ? 1 : 0);
		}
		TextureID wallTex = TexMan.CheckForTexture("AXW43B", TexMan.Type_Any);
		TextureID ductTex = TexMan.CheckForTexture("AXDU09", TexMan.Type_Any);
		for (int k = 0; k < secs.Size(); k++)
		{
			if (!keep[k]) continue;
			Sector sec = level.sectors[secs[k]];
			double f = sec.floorplane.ZAtPoint(sec.centerspot);
			double c = sec.ceilingplane.ZAtPoint(sec.centerspot);
			double nc = f + DUCT_H;
			if (c <= nc) continue;
			sec.MoveCeiling(c - nc + 1, sec.ceilingplane.PointToDist(sec.centerspot, nc), -1, -1, false);
			ceilPlan[secs[k]] = nc;
			secDuct[secs[k]] = 1;
			if (ductTex.IsValid()) sec.SetTexture(Sector.ceiling, ductTex);
			sec.SetLightLevel(min(sec.lightlevel, 72));
		}
		// the walls above the duct seen from outside it
		for (int k = 0; k < secs.Size(); k++)
		{
			Sector sec = level.sectors[secs[k]];
			if (!secDuct[secs[k]]) continue;
			for (int l = 0; l < sec.lines.Size(); l++)
			{
				Line ln = sec.lines[l];
				if (!ln.sidedef[1]) continue;
				Sector o = ln.frontsector == sec ? ln.backsector : ln.frontsector;
				if (!o || secDuct[o.Index()]) continue;
				Side sd = ln.frontsector == o ? ln.sidedef[0] : ln.sidedef[1];
				if (sd && sd.GetTexture(Side.top).IsNull() && wallTex.IsValid()) sd.SetTexture(Side.top, wallTex);
			}
		}
		ductRooms = ids.Size();
		if (CVar.FindCVar("cw_simverbose").GetInt() >= 2)
			for (int k = 0; k < secs.Size(); k++)
			{
				Sector sec = level.sectors[secs[k]];
				double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
				for (int l = 0; l < sec.lines.Size(); l++) { Vector2 v = sec.lines[l].v1.p; x0 = min(x0, v.x); y0 = min(y0, v.y); x1 = max(x1, v.x); y1 = max(y1, v.y); }
				Console.Printf("OBSDBG duct sector %d room %d keep %d lowered %d: %dx%d at %d %d, floor %d", secs[k], secRoom[k], keep[k], secDuct[secs[k]], int(x1 - x0), int(y1 - y0), int(x0), int(y0), int(sec.floorplane.ZAtPoint(sec.centerspot)));
			}
	}

	// Windows: Obsidian makes window openings impassable; let the player climb through (guards still can't).
	void OpenWindows()
	{
		int bad = Line.ML_BLOCKING | Line.ML_BLOCK_PLAYERS | Line.ML_BLOCKEVERYTHING;
		let it = ThinkerIterator.Create("CW_ObsWindow");
		Actor m;
		while (m = Actor(it.Next()))
		{
			let li = BlockLinesIterator.CreateFromPos(m.pos, 128, 160);
			while (li.Next())
			{
				Line ln = li.CurLine;
				if (!ln.sidedef[1] || !(ln.flags & bad) || SegDist(m.pos.xy, ln.v1.p, ln.delta) > 144) continue;
				if (!ln.sidedef[0].GetTexture(Side.mid).IsNull() || !ln.sidedef[1].GetTexture(Side.mid).IsNull()) continue;
				// (a barrier with sky on one side is the edge of the map: leave it)
				if (ln.frontsector.GetTexture(Sector.ceiling) == skyflatnum || ln.backsector.GetTexture(Sector.ceiling) == skyflatnum) continue;
				ln.flags = (ln.flags & ~bad) | Line.ML_BLOCKMONSTERS;
				windowsOpened++;
			}
		}
		// the same for any other invisible barrier between two indoor spaces (window ports in wall prefabs)
		for (int i = 0; i < level.lines.Size(); i++)
		{
			Line ln = level.lines[i];
			if (!ln.sidedef[1] || !(ln.flags & bad)) continue;
			if (!ln.sidedef[0].GetTexture(Side.mid).IsNull() || !ln.sidedef[1].GetTexture(Side.mid).IsNull()) continue;
			Sector a = ln.frontsector, b = ln.backsector;
			if (a.GetTexture(Sector.ceiling) == skyflatnum || b.GetTexture(Sector.ceiling) == skyflatnum) continue;
			Vector2 mid = ln.v1.p + ln.delta / 2;
			double fa = a.floorplane.ZAtPoint(mid), fb = b.floorplane.ZAtPoint(mid);
			if (abs(fa - fb) > 48) continue;
			if (min(a.ceilingplane.ZAtPoint(mid), b.ceilingplane.ZAtPoint(mid)) - max(fa, fb) < 40) continue;
			ln.flags = (ln.flags & ~bad) | Line.ML_BLOCKMONSTERS;
			windowsOpened++;
		}
	}

	// Can someone needing headroom h (a guard: blocked by monster-blocking lines too) cross this line?
	bool Passable(Line ln, Sector a, Sector b, double h, bool guard)
	{
		double maxStep = guard ? 24 : 32;      // the player can jump a little
		if (!b || !ln.sidedef[1]) return false;
		int bad = Line.ML_BLOCKING | Line.ML_BLOCK_PLAYERS | Line.ML_BLOCKEVERYTHING;
		if (guard) bad = Line.ML_BLOCKING | Line.ML_BLOCKMONSTERS | Line.ML_BLOCKEVERYTHING;
		if (ln.flags & bad) return false;
		Vector2 mid = ln.v1.p + ln.delta / 2;
		double fa = a.floorplane.ZAtPoint(mid), fb = b.floorplane.ZAtPoint(mid);
		if (abs(fa - fb) > maxStep && !secFlex[a.Index()] && !secFlex[b.Index()]) return false;
		double lowC = min(CeilZ(a, mid), CeilZ(b, mid));
		if (secFlex[a.Index()] || secFlex[b.Index()]) return lowC - min(fa, fb) >= h;
		return lowC - max(fa, fb) >= h;
	}

	// connected walkable regions of sectors
	void Regions(Array<int> reg, double h, bool guard)
	{
		int n = level.sectors.Size();
		reg.Clear();
		for (int i = 0; i < n; i++) reg.Push(-1);
		int id = 0;
		Array<int> q;
		for (int i = 0; i < n; i++)
		{
			if (reg[i] >= 0) continue;
			reg[i] = id;
			q.Clear(); q.Push(i);
			for (int h0 = 0; h0 < q.Size(); h0++)
			{
				Sector a = level.sectors[q[h0]];
				for (int l = 0; l < a.lines.Size(); l++)
				{
					Line ln = a.lines[l];
					Sector b = ln.frontsector == a ? ln.backsector : ln.frontsector;
					if (!b || b == a || reg[b.Index()] >= 0) continue;
					if (!Passable(ln, a, b, h, guard)) continue;
					reg[b.Index()] = id;
					q.Push(b.Index());
				}
			}
			id++;
		}
	}
	int RegionAt(Array<int> reg, Vector2 p) { Sector s = level.PointInSector(p); return s ? reg[s.Index()] : -1; }

	// The player's walkable area is the region holding most of the rooms; rooms outside it are left alone.
	void FindMainRegion()
	{
		Regions(regP, CROUCH_H, false);
		Regions(regG, WALK_H, true);
		Array<int> cnt;
		for (int i = 0; i < level.sectors.Size(); i++) cnt.Push(0);
		for (int r = 0; r < rId.Size(); r++) { int g = RegionAt(regP, (rX[r], rY[r])); if (g >= 0) cnt[g]++; }
		int best = 0;
		for (int i = 0; i < cnt.Size(); i++) if (cnt[i] > cnt[best]) best = i;
		mainReg = best;
		for (int r = 0; r < rId.Size(); r++) if (RegionAt(regP, (rX[r], rY[r])) != mainReg) rFlags[r] |= RF_UNREACH | RF_NOGUARD;
		if (CVar.FindCVar("cw_simverbose").GetInt() >= 2)
		{
			// QA: why the main area's edge is closed (flags / step / headroom), per room region
			int nFlag = 0, nStep = 0, nHead = 0, nDoor = 0, nFlex = 0;
			for (int i = 0; i < level.lines.Size(); i++)
			{
				Line ln = level.lines[i];
				if (!ln.sidedef[1]) continue;
				int ra = regP[ln.frontsector.Index()], rb = regP[ln.backsector.Index()];
				if ((ra == mainReg) == (rb == mainReg)) continue;
				Sector o = ra == mainReg ? ln.backsector : ln.frontsector;
				bool roomSide = false;
				for (int r = 0; r < rId.Size(); r++) if (Has(r, RF_UNREACH) && RegionAt(regP, (rX[r], rY[r])) == regP[o.Index()]) roomSide = true;
				Vector2 mid = ln.v1.p + ln.delta / 2;
				double fa = ln.frontsector.floorplane.ZAtPoint(mid), fb = ln.backsector.floorplane.ZAtPoint(mid);
				double c = min(CeilZ(ln.frontsector, mid), CeilZ(ln.backsector, mid));
				if (ln.flags & (Line.ML_BLOCKING | Line.ML_BLOCK_PLAYERS | Line.ML_BLOCKEVERYTHING)) { nFlag++; if (nFlag <= 4) Console.Printf("OBSDBG block %d at %d %d mid %s/%s sky %d/%d", i, int(mid.x), int(mid.y), TexMan.GetName(ln.sidedef[0].GetTexture(Side.mid)), TexMan.GetName(ln.sidedef[1].GetTexture(Side.mid)), ln.frontsector.GetTexture(Sector.ceiling) == skyflatnum, ln.backsector.GetTexture(Sector.ceiling) == skyflatnum); }
				else if (abs(fa - fb) > 24) { nStep++; if (nStep <= 6) Console.Printf("OBSDBG step %d at %d %d: %d -> %d  special %d tag %d/%d", i, int(mid.x), int(mid.y), int(fa), int(fb), ln.special, ln.frontsector.GetTag(0), ln.backsector.GetTag(0)); }
				else if (c - max(fa, fb) < CROUCH_H) { nHead++; if (nHead <= 6) Console.Printf("OBSDBG head %d at %d %d: floor %d/%d ceil %d  tags %d/%d door %d/%d", i, int(mid.x), int(mid.y), int(fa), int(fb), int(c), ln.frontsector.GetTag(0), ln.backsector.GetTag(0), secDoor[ln.frontsector.Index()], secDoor[ln.backsector.Index()]); }
			}
			Console.Printf("OBSDBG edge of main area toward cut-off rooms: blocking %d, steps %d, headroom %d", nFlag, nStep, nHead);
		}
	}

	// Does the player fit here (standing, not in a duct, in the walkable area, clear of walls and solid things)?
	bool FitsPlayer(Vector2 p)
	{
		Sector s = level.PointInSector(p);
		if (!s || secDuct[s.Index()] || secDoor[s.Index()]) return false;
		if (mainReg >= 0 && regP[s.Index()] != mainReg) return false;
		double f = s.floorplane.ZAtPoint(p);
		if (CeilZ(s, p) - f < 60) return false;
		if (!probe) probe = CW_ObsProbe(Actor.Spawn("CW_ObsProbe", (p, f)));
		if (!probe) return true;
		probe.SetOrigin((p, f), false);
		FCheckPosition tm;
		tm.thing = probe; tm.pos = (p, f);
		if (!probe.CheckPosition(p, false, tm)) return false;
		if (tm.ceilingz - tm.floorz < 56 || abs(tm.floorz - f) > 24) return false;
		// room to move: at least half the directions around are open
		int open = 0;
		for (int d = 0; d < 8; d++)
		{
			Vector2 q = p + Actor.AngleToVector(d * 45) * 32;
			Sector sq = level.PointInSector(q);
			if (!sq || sq.floorplane.ZAtPoint(q) - f > 24 || CeilZ(sq, q) - sq.floorplane.ZAtPoint(q) < 56) continue;
			if (probe.CheckPosition(q)) open++;
		}
		return open >= 4;
	}

	// Move each entry to a spot where the player fits (drop it if there's none nearby); make sure there is one.
	void FixEntries()
	{
		for (int e = enX.Size() - 1; e >= 0; e--)
		{
			Vector2 p = (enX[e], enY[e]);
			if (FitsPlayer(p)) continue;
			bool found = false;
			for (int ring = 1; ring <= 6 && !found; ring++)
				for (int d = 0; d < 8 && !found; d++)
				{
					Vector2 q = p + Actor.AngleToVector(d * 45 + ring * 13) * (ring * 24);
					if (FitsPlayer(q)) { enX[e] = q.x; enY[e] = q.y; found = true; }
				}
			int r = enRoom[e];
			for (int k = 0; k < sX.Size() && !found; k++)
			{
				if (sRoom[k] != r) continue;
				Vector2 q = (sX[k], sY[k]);
				if (FitsPlayer(q)) { enX[e] = q.x; enY[e] = q.y; found = true; }
			}
			if (found) { entriesMoved++; continue; }
			entriesDropped++;
			enX.Delete(e); enY.Delete(e); enA.Delete(e); enKind.Delete(e); enRoom.Delete(e); enName.Delete(e);
		}
		if (enX.Size()) return;
		// nothing usable: the most central fitting spot of the biggest reachable rooms
		for (int k = 0; k < sX.Size(); k++)
		{
			Vector2 q = (sX[k], sY[k]);
			if (Has(sRoom[k], RF_UNREACH) || !FitsPlayer(q)) continue;
			enX.Push(q.x); enY.Push(q.y); enA.Push(Rand(0, 7) * 45); enKind.Push(EK_FRONT); enRoom.Push(sRoom[k]); enName.Push(EntryName(EK_FRONT));
			return;
		}
	}

	bool SkyAbove(Vector2 p) { return level.PointInSector(p).GetTexture(Sector.ceiling) == skyflatnum; }

	void Lights()
	{
		// the fittings Obsidian placed
		let it = ThinkerIterator.Create("CW_ObsLamp");
		Actor m;
		while (m = Actor(it.Next()))
		{
			Sector ms = level.PointInSector(m.pos.xy);
			if (!ms || secDuct[ms.Index()]) continue;
			int r = NearestRoom(m.pos.xy);
			bool dark = r >= 0 && rDark[r];
			if (dark || Chance(Under() ? 85 : 55)) Lamp(m.pos.xy, dark ? 2 : -1, dark);   // about half the fittings work (most, underground)
		}
		// indoor rooms get a light or two: pools of light with shadow between them (dark rooms: fittings, off)
		for (int r = 0; r < rId.Size(); r++)
		{
			if (Has(r, RF_OUT)) { if (Chance(45) && RoomPoint(r, 24)) PoleLight(rp); continue; }
			bool dark = rDark[r];
			int n = 0;
			int most = Under() ? 3 : 2;
			for (int k = 0; k < sX.Size() && n < most; k++)
				if (sRoom[k] == r && (n == 0 || Chance(Under() ? 70 : 40))) { Lamp((sX[k], sY[k]), dark ? 2 : -1, dark); n++; }
		}
	}

	// ================================================================ stealth: darkness and cover
	// Obsidian lights its maps evenly and brightly, which leaves nowhere to hide (the stealth meter reads the
	// sector light as a floor under the lamps). Night-shift the whole site: dim ambient everywhere so the
	// lamps make pools, and a share of the rooms with the lights off.
	int DarkCount() { int n = 0; for (int r = 0; r < rDark.Size(); r++) if (rDark[r]) n++; return n; }
	void Darken()
	{
		rDark.Clear();
		int home = enRoom.Size() ? enRoom[insertIdx] : -1;
		for (int r = 0; r < rId.Size(); r++)
		{
			bool dark = !Has(r, RF_OUT) && r != home && rRole[r] != IR_CORRIDOR && rRole[r] != IR_CONTROL && Chance(Under() ? 12 : 28);
			rDark.Push(dark);
		}
		// underground mood: which lit rooms get an accent colour
		rTint.Clear();
		mood = 0;
		if (Under())
		{
			mood = CVar.FindCVar("cw_undermood").GetInt();
			if (mood < 0 || mood > 5) mood = Chance(15) ? 0 : Rand(1, 5);
			for (int r = 0; r < rId.Size(); r++)
			{
				int t = -1;
				if (mood && !rDark[r] && !Has(r, RF_OUT) && Chance(rRole[r] == IR_CORRIDOR ? 65 : 55)) t = mood == 5 ? Rand(0, 3) : mood - 1;
				rTint.Push(t);
			}
			// at least two accented rooms, so the mood reads on a small map
			int have = 0;
			for (int r = 0; r < rTint.Size(); r++) if (rTint[r] >= 0) have++;
			for (int n = 0; mood && have < 2 && n < 40; n++)
			{
				int r = Rand(0, rId.Size() - 1);
				if (rTint[r] >= 0 || rDark[r] || Has(r, RF_OUT)) continue;
				rTint[r] = mood == 5 ? Rand(0, 3) : mood - 1;
				have++;
			}
		}
		// Obsidian's light prefabs run glow / flicker / strobe effects that would drive the level straight
		// back up to 255 under the fittings: stop them (our lamps do the lighting)
		let lt = ThinkerIterator.Create("Lighting");
		Thinker th;
		Array<Thinker> fx;
		while (th = lt.Next()) fx.Push(th);
		for (int k = 0; k < fx.Size(); k++) if (fx[k]) fx[k].Destroy();
		for (int i = 0; i < level.sectors.Size(); i++)
		{
			Sector sec = level.sectors[i];
			if (secDuct[i]) continue;                        // ducts are already dim
			int r = NearestRoom(sec.centerspot);
			int cap;
			if (sec.GetTexture(Sector.ceiling) == skyflatnum) cap = 88 + Rand(0, 2) * 8;   // yards at night
			else if (r >= 0 && rDark[r]) cap = 48 + Rand(0, 1) * 8;                       // lights off
			else if (Under()) cap = (r >= 0 && rRole[r] == IR_CORRIDOR) ? 104 : 120;   // underground: lit 24/7, no moon
			else if (r >= 0 && rRole[r] == IR_CORRIDOR) cap = 72;
			else cap = 80;
			if (sec.lightlevel > cap) sec.SetLightLevel(cap);
			if (r >= 0 && r < rTint.Size() && rTint[r] >= 0) sec.SetColor(Color(TINT_SEC[rTint[r]]));
		}
	}

	// Cover in the big open spaces: crates, pallets, scrap and containers that break sightlines
	// (CW_Cover.Behind hides a crouched player behind anything 48+ high). Keeps off the room middle
	// (patrol routes), the entries and doors, with a player's width of passage all round.
	void PlaceCover()
	{
		coverPlaced = 0;
		putMargin = 40;
		Array<double> cx, cy;
		for (int r = 0; r < rId.Size(); r++)
		{
			int want = 0;
			bool isOut = Has(r, RF_OUT);
			switch (rRole[r])
			{
			case IR_YARD:     want = 6; break;
			case IR_HALL:     want = 5; break;
			case IR_LOADING:  want = 4; break;
			case IR_STORE:    want = 3; break;
			case IR_WORKSHOP: case IR_PLANT: want = 2; break;
			default:          want = isOut ? 4 : 0; break;
			}
			if (!want) continue;
			Vector2 c = (rX[r], rY[r]);
			int placed = 0;
			int a0 = Rand(0, 359);
			for (int ring = 2; ring <= 12 && placed < want; ring++)
			{
				double rad = ring * 56;
				int steps = 6 + ring * 2;
				for (int k = 0; k < steps && placed < want; k++)
				{
					Vector2 p = c + Actor.AngleToVector(a0 + k * 360.0 / steps + ring * 17) * rad;
					if (NearestRoom(p) != r) continue;
					if ((p - insertPos).Length() < 192) continue;
					bool near = false;
					for (int q = 0; q < cx.Size() && !near; q++) if ((p - (cx[q], cy[q])).Length() < 176) near = true;
					for (int q = 0; q < exX.Size() && !near; q++) if ((p - (exX[q], exY[q])).Length() < 128) near = true;
					if (near) continue;
					String cn;
					int pick = Rand(0, 99);
					if (isOut) cn = pick < 30 ? "CW_FContainer" : (pick < 60 ? "CW_FCrates" : (pick < 80 ? "CW_FDumpster" : "CW_FScrap"));
					else if (rRole[r] == IR_HALL || rRole[r] == IR_STORE) cn = pick < 45 ? "CW_FCrates" : (pick < 75 ? "CW_FShelving" : "CW_FPallet");
					else if (rRole[r] == IR_LOADING) cn = pick < 60 ? "CW_FCrates" : "CW_FPallet";
					else cn = pick < 50 ? "CW_FCrates" : "CW_FScrap";
					// something big that doesn't fit: try a stack of crates there instead
					if (!Put((Class<Actor>)(cn), p, 90 * Rand(0, 3)) && (cn == "CW_FCrates" || !Put("CW_FCrates", p, 90 * Rand(0, 3)))) continue;
					cx.Push(p.x); cy.Push(p.y);
					placed++; coverPlaced++;
				}
			}
		}
		putMargin = 0;
	}

	// ================================================================ extraction
	// Walls within arm's reach of p (8 directions): 0 = open floor, 2 = along a wall, 3+ = a corner / alcove.
	int WallsAround(Vector2 p)
	{
		if (!probe) probe = CW_ObsProbe(Actor.Spawn("CW_ObsProbe", (p, FloorAt(p))));
		if (!probe) return 0;
		probe.SetOrigin((p, FloorAt(p)), false);
		int n = 0;
		for (int d = 0; d < 8; d++)
		{
			FLineTraceData t;
			if (probe.LineTrace(d * 45, 64, 0, TRF_THRUACTORS | TRF_THRUHITSCAN, 32, 0, 0, t) && t.HitType == TRACE_HitWall && t.Distance <= 56) n++;
		}
		return n;
	}

	// Each entry's extraction goes against a wall near it (a corner or alcove if there is one), not in the
	// open middle of a room or yard where you'd walk into it by accident.
	void PlaceExtractions()
	{
		exX.Clear(); exY.Clear();
		for (int e = 0; e < enX.Size(); e++)
		{
			Vector2 p0 = (enX[e], enY[e]);
			Vector2 best = p0;
			double bs = WallsAround(p0) * 10.0;
			if (bs < 20)
			{
				for (int ring = 1; ring <= 12; ring++)
				{
					double rad = ring * 24;
					for (int d = 0; d < 16; d++)
					{
						Vector2 q = p0 + Actor.AngleToVector(d * 22.5 + ring * 7) * rad;
						if (!FitsPlayerNear(q)) continue;
						int w = WallsAround(q);
						if (w < 2) continue;
						double sc = min(w, 4) * 10.0 - rad / 24.0;
						if (NearestRoom(q) == enRoom[e]) sc += 6;
						bool clash = false;
						for (int k = 0; k < exX.Size(); k++) if ((q - (exX[k], exY[k])).Length() < 96) clash = true;
						if (clash) continue;
						if (sc > bs) { bs = sc; best = q; }
					}
				}
			}
			exX.Push(best.x); exY.Push(best.y);
			Actor.Spawn("CW_Extraction", (best, FloorAt(best)));
		}
	}
	// like FitsPlayer, but a spot against a wall only needs a few open directions
	bool FitsPlayerNear(Vector2 p)
	{
		Sector s = level.PointInSector(p);
		if (!s || secDuct[s.Index()] || secDoor[s.Index()]) return false;
		if (mainReg >= 0 && regP[s.Index()] != mainReg) return false;
		double f = s.floorplane.ZAtPoint(p);
		if (CeilZ(s, p) - f < 60) return false;
		if (!probe) probe = CW_ObsProbe(Actor.Spawn("CW_ObsProbe", (p, f)));
		if (!probe) return false;
		probe.SetOrigin((p, f), false);
		FCheckPosition tm;
		tm.thing = probe; tm.pos = (p, f);
		if (!probe.CheckPosition(p, false, tm)) return false;
		return tm.ceilingz - tm.floorz >= 56 && abs(tm.floorz - f) <= 24;
	}

	void Lamp(Vector2 p, int style = -1, bool unlit = false)
	{
		if (SkyAbove(p)) { PoleLight(p); return; }
		int r = NearestRoom(p);
		if (style < 0) style = (r >= 0 && (rRole[r] == IR_OFFICE || rRole[r] == IR_CREW)) ? 0 : 2;
		let l = CW_CeilingLight(Actor.Spawn("CW_CeilingLight", (p, CeilAt(p) - 19)));
		if (l) { l.style = style; l.frame = style; l.unlit = unlit; }
		if (l && r >= 0 && r < rTint.Size() && rTint[r] >= 0)
		{
			int t = rTint[r];
			l.tintR = TINT_LR[t]; l.tintG = TINT_LG[t]; l.tintB = TINT_LB[t];
		}
	}
	void PoleLight(Vector2 p)
	{
		if (!Put("CW_FLampPost", p, 0)) return;
		CW_LightSource.Make((p, FloorAt(p) + 112), 230, 240, 255, 240);
	}

	// ================================================================ placing things
	double FloorAt(Vector2 p) { return level.PointInSector(p).floorplane.ZAtPoint(p); }
	double CeilAt(Vector2 p) { return level.PointInSector(p).ceilingplane.ZAtPoint(p); }

	static double SegDist(Vector2 p, Vector2 a, Vector2 d)
	{
		double len2 = d dot d;
		double t = len2 > 0 ? clamp(((p - a) dot d) / len2, 0, 1) : 0;
		return (a + d * t - p).Length();
	}

	// Free floor for something of radius r at p: flat, headroom, clear of walls, ledges, doors, entries and solids.
	bool Clear(Vector2 p, double r)
	{
		Sector s = level.PointInSector(p);
		if (!s) return false;
		if (secDuct.Size() && (secDuct[s.Index()] || secDoor[s.Index()])) return false;
		if (mainReg >= 0 && regP[s.Index()] != mainReg) return false;
		r += putMargin;
		double f = s.floorplane.ZAtPoint(p);
		if (s.ceilingplane.ZAtPoint(p) - f < 64) return false;
		let li = BlockLinesIterator.CreateFromPos((p, f), 64, r + 16);
		while (li.Next())
		{
			Line ln = li.CurLine;
			if (SegDist(p, ln.v1.p, ln.delta) > r + 4) continue;
			if (!ln.sidedef[1] || (ln.flags & (Line.ML_BLOCKING | Line.ML_BLOCKEVERYTHING | Line.ML_BLOCK_PLAYERS))) return false;
			Sector a = ln.frontsector, b = ln.backsector;
			double fa = a.floorplane.ZAtPoint(p), fb = b.floorplane.ZAtPoint(p);
			if (abs(fa - fb) > 2) return false;
			if (min(a.ceilingplane.ZAtPoint(p), b.ceilingplane.ZAtPoint(p)) - max(fa, fb) < 64) return false;
		}
		for (int k = 0; k < doors.Size(); k++) if (doors[k] && (doors[k].pos.xy - p).Length() < 72 + r) return false;
		for (int e = 0; e < enX.Size(); e++) if ((p - (enX[e], enY[e])).Length() < 64 + r) return false;
		for (int e = 0; e < exX.Size(); e++) if ((p - (exX[e], exY[e])).Length() < 64 + r) return false;
		let it = BlockThingsIterator.CreateFromPos(p.x, p.y, f, 64, r + 48, false);
		while (it.Next()) if (it.thing.bSOLID && it.thing != probe && (it.thing.pos.xy - p).Length() < it.thing.radius + r + 4) return false;
		return true;
	}

	Actor Put(Class<Actor> cls, Vector2 p, double ang = 0, bool check = true)
	{
		let def = GetDefaultByType(cls);
		double r = def.radius;
		if (cls is "CW_Furniture") r = max(r, CW_Furniture.HalfSize((class<CW_Furniture>)(cls)));
		if (check && !Clear(p, r)) return null;
		let a = Actor.Spawn(cls, (p, def.bSPAWNCEILING ? CeilAt(p) - def.height : FloorAt(p)));
		if (!a) return null;
		a.angle = ang;
		let fu = CW_Furniture(a);
		if (fu) fu.MakeBlockers();
		return a;
	}

	// Something that belongs against a wall (vending machine, pipe run, barrier): from spot p, find the
	// nearest wall within reach and stand it there with its back to the wall, facing into the room.
	Actor PutAgainstWall(Class<Actor> cls, Vector2 p, int r)
	{
		if (!probe) probe = CW_ObsProbe(Actor.Spawn("CW_ObsProbe", (p, FloorAt(p))));
		if (!probe) return null;
		probe.SetOrigin((p, FloorAt(p)), false);
		let def = GetDefaultByType(cls);
		double depth = def.radius;
		let fd = CW_Furniture(def);
		if (fd && fd.fDepth > 0) depth = fd.fDepth / 2;
		double bestD = 1e9, bestA = 0;
		for (int d = 0; d < 8; d++)
		{
			FLineTraceData t;
			if (probe.LineTrace(d * 45, 192, 0, TRF_THRUACTORS | TRF_THRUHITSCAN, 32, 0, 0, t) && t.HitType == TRACE_HitWall && t.Distance < bestD)
			{ bestD = t.Distance; bestA = d * 45; }
		}
		if (bestD > 192) return null;
		Vector2 n = Actor.AngleToVector(bestA);
		Vector2 q = p + n * max(0, bestD - depth - 3);
		if (NearestRoom(q) != r) return null;
		return Put(cls, q, bestA + 180);
	}

	// a free point in a room: its spots, nudged about
	Vector2 rp;
	bool RoomPoint(int r, double rad = 20)
	{
		Array<int> ks;
		for (int k = 0; k < sX.Size(); k++) if (sRoom[k] == r) ks.Push(k);
		if (!ks.Size()) return false;
		int s = Rand(0, ks.Size() - 1);
		for (int n = 0; n < ks.Size() * 3; n++)
		{
			int k = ks[(s + n) % ks.Size()];
			Vector2 p = (sX[k], sY[k]) + (n < ks.Size() ? (0, 0) : (Rand(-40, 40), Rand(-40, 40)));
			if (Clear(p, rad)) { rp = p; return true; }
		}
		return false;
	}
	bool Safe(Vector2 p) { return (p - insertPos).Length() >= SAFE_R; }

	double FaceFrom(Vector2 p, int r)
	{
		// toward the nearest door within reach, else toward the middle of the room
		double bd = 600;
		Vector2 best = p;
		if (r >= 0) best = (rX[r], rY[r]);
		for (int k = 0; k < doors.Size(); k++)
		{
			if (!doors[k]) continue;
			double d = (doors[k].pos.xy - p).Length();
			if (d < bd) { bd = d; best = doors[k].pos.xy; }
		}
		Vector2 v = best - p;
		return v.Length() > 1 ? VectorAngle(v.x, v.y) : Rand(0, 7) * 45;
	}

	// ================================================================ dressing
	void Dress()
	{
		putMargin = 40;          // furniture leaves a player's width of passage all round (no blocked corridors)
		DressSpots();
		putMargin = 0;
	}
	void DressSpots()
	{
		for (int k = 0; k < sX.Size(); k++)
		{
			if (sKind[k] >= 2) continue;                        // start / exit spots stay clear
			int r = sRoom[k];
			Vector2 p = (sX[k], sY[k]);
			if ((p - (rX[r], rY[r])).Length() < 8) continue;    // the middle stays open for patrols
			if ((p - insertPos).Length() < 160) continue;
			double a = 90 * Rand(0, 3);
			switch (rRole[r])
			{
			case IR_YARD:
				if (Chance(25)) Put(Chance(50) ? "CW_FContainer" : "CW_FContainerB", p, 90 * Rand(0, 1));
				else if (Chance(20)) Put("CW_FPallet", p, a);
				else if (Chance(12)) Put("CW_FDumpster", p, a);
				break;
			case IR_HALL:
				if (Under())
				{
					// vending machines, pipes, barriers and sandbags stand against a wall; grow beds stand free
					if (Chance(40)) { if (variant == 4) Put(UND_HALLPROP[4], p, 90 * Rand(0, 1)); else PutAgainstWall(UND_HALLPROP[clamp(variant, 0, 5)], p, r); }
					else if (Chance(25)) Put("CW_FCrates", p, a);
				}
				else if (Chance(40)) Put(variant == 2 ? "CW_FWorkbench" : "CW_FShelving", p, 90 * Rand(0, 1));
				else if (Chance(30)) Put(Chance(50) ? "CW_FPallet" : "CW_FCrates", p, a);
				break;
			case IR_WORKSHOP:
				if (Chance(45)) Put("CW_FWorkbench", p, a); else if (Chance(25)) Put("CW_FScrap", p, a);
				break;
			case IR_PLANT:
				if (Under() && Chance(20)) PutAgainstWall("CW_FPipes", p, r);
				else if (Chance(35)) Put(Under() ? "CW_FGenerator" : (variant == 3 ? "CW_FTurbine" : "CW_FGenerator"), p, a);
				else if (Chance(30)) Put("CW_FTank", p, a);
				else if (Chance(25)) Put("CW_FTransformer", p, a);
				break;
			case IR_CONTROL:
				if (Chance(55)) Put("CW_FDeskCode", p, a);
				break;
			case IR_OFFICE:
				if (Chance(50)) Put("CW_FDeskWork", p, a); else if (Chance(30)) Put("CW_FFileCabinet", p, a);
				break;
			case IR_STORE:
				if (Chance(50)) Put("CW_FShelving", p, a); else if (Chance(40)) Put("CW_FCrates", p, a);
				break;
			case IR_LOADING:
				if (Chance(40)) Put("CW_FPallet", p, a); else if (Chance(25)) Put("CW_FCrates", p, a);
				break;
			case IR_CREW:
				if (Chance(40)) Put("CW_FLocker", p, a); else if (Chance(30)) Put("CW_FRoundTable", p, a);
				break;
			}
		}
	}

	// ================================================================ entries
	void PickInsertion()
	{
		int n = enX.Size();
		if (!n)
		{
			// no entries at all: the player start
			let pm = players[consoleplayer].mo;
			Vector2 p = pm ? pm.pos.xy : (rX.Size() ? (rX[0], rY[0]) : (0, 0));
			enX.Push(p.x); enY.Push(p.y); enA.Push(pm ? pm.angle : 0); enKind.Push(EK_FRONT); enRoom.Push(NearestRoom(p)); enName.Push(EntryName(EK_FRONT));
			n = 1;
		}
		insertIdx = Rand(0, n - 1);
		if (visitSeed) insertIdx = CW_Building.Mix(visitSeed, 31) % n;
		if (entryPref >= 2) for (int e = 0; e < n; e++) if (enKind[e] == entryPref) { insertIdx = e; break; }
		insertPos = (enX[insertIdx], enY[insertIdx]);
		insertAng = enA[insertIdx];
		insertName = enName[insertIdx];
	}

	void PlaceCrate()
	{
		for (int k = 0; k < 16; k++)
		{
			Vector2 p = insertPos + Actor.AngleToVector(insertAng + 90 + k * 30) * (56 + (k / 4) * 24);
			let def = GetDefaultByType("CW_TransportAccess");
			Sector s = level.PointInSector(p);
			if (abs(s.floorplane.ZAtPoint(p) - FloorAt(insertPos)) > 24) continue;
			bool ok = true;
			let li = BlockLinesIterator.CreateFromPos((p, FloorAt(p)), 64, def.radius + 8);
			while (li.Next()) if (SegDist(p, li.CurLine.v1.p, li.CurLine.delta) < def.radius + 4 && (!li.CurLine.sidedef[1] || (li.CurLine.flags & Line.ML_BLOCKING))) ok = false;
			let it = BlockThingsIterator.CreateFromPos(p.x, p.y, 0, 64, def.radius + 48, false);
			while (it.Next()) if (it.thing.bSOLID && (it.thing.pos.xy - p).Length() < it.thing.radius + def.radius + 4) ok = false;
			if (!ok) continue;
			Actor.Spawn("CW_TransportAccess", (p, FloorAt(p)));
			return;
		}
	}

	// ================================================================ objectives
	int ObjScore(int r, int k)
	{
		int f = rFlags[r];
		if (f & (RF_OUT | RF_UNREACH)) return 0;
		if (rRole[r] == IR_CORRIDOR) return 1;
		if (k == OBJ_STEAL) return (f & RF_VALUE) ? 60 : 5;
		if (k == OBJ_DESTROY) return (f & RF_TECH) ? 60 : 3;
		return (f & RF_PEOPLE) ? 60 : 4;
	}

	void PlanObjectives()
	{
		int home = enRoom.Size() ? enRoom[insertIdx] : -1;
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int best = -1, bs = -1;
			for (int r = 0; r < rId.Size(); r++)
			{
				int s = ObjScore(r, k);
				if (s <= 0) continue;
				s += rDepth[r] / 2 + Rand(0, 20);
				for (int q = OBJ_STEAL; q < k; q++) if (objRoom[q] == r) s -= 150;
				if (r == home) s -= 100;
				// distance from the insertion point counts too (the depth runs from Obsidian's start, not ours)
				Vector2 pr = (rX[r], rY[r]);
				s += int(min((pr - insertPos).Length(), 3000) / 100);
				if (s > bs) { bs = s; best = r; }
			}
			objRoom[k] = best;
		}
	}

	void PlaceObjectives()
	{
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++)
		{
			int r = objRoom[k];
			if (r < 0) continue;
			Actor a = null;
			String cn = k == OBJ_STEAL ? "CW_Prototype" : (k == OBJ_DESTROY ? "CW_Server" : "CW_Scientist");
			Class<Actor> cls = cn;
			// goal spots first (Obsidian put its keys and switches in the far corners of rooms)
			for (int s = 0; s < sX.Size() && !a; s++)
				if (sRoom[s] == r && sKind[s] == 1) a = Put(cls, (sX[s], sY[s]), FaceFrom((sX[s], sY[s]), r));
			for (int n = 0; n < 12 && !a; n++)
				if (RoomPoint(r, 24)) a = Put(cls, rp, FaceFrom(rp, r));
			if (!a) Console.Printf("\cgObs: objective %d has no room to stand in (%s)", k, rName[r]);
		}
	}

	// ================================================================ people
	int SiteTarget()
	{
		int f = siteSet ? siteForce : 8;
		return clamp(4 + f * 55 / 100, 4, 12);
	}

	void Patrol(Array<double> px, Array<double> py, int wait)
	{
		if (px.Size() < 2) return;
		Array<int> tids;
		for (int k = 0; k < px.Size(); k++) tids.Push(level.FindUniqueTid());
		for (int k = 0; k < px.Size(); k++)
		{
			let pp = Actor.Spawn("CW_PatrolPoint", ((px[k], py[k]), FloorAt((px[k], py[k]))));
			if (!pp) continue;
			pp.ChangeTid(tids[k]);
			pp.args[0] = tids[(k + 1) % px.Size()];
			pp.args[1] = k == 0 || k == px.Size() / 2 ? wait * 2 : wait;
		}
		let g = CW_Guard(Put("CW_Guard", (px[0], py[0]), 0, false));
		if (g) { g.args[0] = tids[1]; guards++; }
	}

	void PlaceGuards()
	{
		Array<int> pool;
		for (int r = 0; r < rId.Size(); r++) if (!Has(r, RF_NOGUARD)) pool.Push(r);
		if (!pool.Size()) return;
		int target = SiteTarget();
		int patrols = max(2, target * 55 / 100);
		for (int tries = 0; tries < patrols * 4 && guards < patrols; tries++)
		{
			// a loop through 3-5 rooms near each other, away from the insertion point
			int r = pool[Rand(0, pool.Size() - 1)];
			if (!RoomPoint(r) || !Safe(rp)) continue;
			Array<double> px, py;
			px.Push(rp.x); py.Push(rp.y);
			Array<int> seen; seen.Push(r);
			int cur = r, len = Rand(2, 4);
			for (int s = 0; s < len; s++)
			{
				int nb = -1; double bd = 1e9;
				for (int o = 0; o < rId.Size(); o++)
				{
					if (seen.Find(o) != seen.Size() || Has(o, RF_NOGUARD)) continue;
					Vector2 po = (rX[o], rY[o]);
					Vector2 pc = (rX[cur], rY[cur]);
					double d = (po - pc).Length() + Rand(0, 300);
					if (d < bd && d < 1800) { bd = d; nb = o; }
				}
				if (nb < 0) break;
				seen.Push(nb); cur = nb;
				Vector2 p0 = (px[0], py[0]);
				if (RoomPoint(nb) && RegionAt(regG, rp) == RegionAt(regG, p0)) { px.Push(rp.x); py.Push(rp.y); }
			}
			if (px.Size() >= 2) Patrol(px, py, 35 + Rand(0, 2) * 35);
		}
		// posts: by the objectives, at the other entries, then anywhere
		Array<int> postRooms;
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] >= 0) postRooms.Push(objRoom[k]);
		for (int e = 0; e < enX.Size(); e++) if (e != insertIdx && enRoom[e] >= 0) postRooms.Push(enRoom[e]);
		for (int n = 0; n < 16; n++) postRooms.Push(pool[Rand(0, pool.Size() - 1)]);
		for (int n = 0; n < postRooms.Size() && guards < target; n++)
		{
			int r = postRooms[n];
			if (!RoomPoint(r) || !Safe(rp)) continue;
			if (Put("CW_Guard", rp, FaceFrom(rp, r))) guards++;
		}
		// one of them runs the shift
		Array<CW_Guard> gs;
		let it = ThinkerIterator.Create("CW_Guard");
		CW_Guard g;
		while (g = CW_Guard(it.Next())) gs.Push(g);
		if (gs.Size())
		{
			let o = gs[Rand(0, gs.Size() - 1)];
			let sv = CW_Guard(Actor.Spawn("CW_SecuritySupervisor", o.pos));
			if (sv) { sv.angle = o.angle; sv.args[0] = o.args[0]; o.Destroy(); }
		}
		double sight = !siteSet ? 1.0 : (siteTech >= 4 ? 1.12 : (siteTech <= 1 ? 0.9 : 1.0));
		it = ThinkerIterator.Create("CW_Guard");
		while (g = CW_Guard(it.Next())) g.sightRange *= sight;
	}

	void PlaceBystanders()
	{
		int want = Bystanders();
		Array<int> pool;
		for (int r = 0; r < rId.Size(); r++) if (Has(r, RF_CIV) && !Has(r, RF_UNREACH)) pool.Push(r);
		if (!pool.Size()) for (int r = 0; r < rId.Size(); r++) if (!Has(r, RF_OUT | RF_UNREACH) && rRole[r] != IR_CORRIDOR) pool.Push(r);
		if (!pool.Size()) return;
		for (int n = 0; n < want * 4 && civs < want; n++)
		{
			int r = pool[Rand(0, pool.Size() - 1)];
			if (!RoomPoint(r) || (rp - insertPos).Length() < 200) continue;
			if (Put("CW_Civilian", rp, Rand(0, 7) * 45)) civs++;
		}
	}

	// ================================================================ the pipeline
	void Generate(int seed, int vari)
	{
		rng = seed; seed0 = seed;
		variant = vari;
		mainReg = -1;
		pool = level.MapName.Left(3);
		for (int k = 0; k < 4; k++) objRoom[k] = -1;
		ReadMarkers();
		PrepSectors();
		ConvertDoors();
		DefuseExits();
		FixSkyFloors();
		BuildDucts();
		OpenWindows();
		FindMainRegion();
		FixEntries();
		PickInsertion();
		Darken();
		Lights();
		PlaceExtractions();
		PlaceCrate();
		PlanObjectives();
		PlaceObjectives();
		Dress();
		PlaceCover();
		PlaceGuards();
		PlaceBystanders();
		String ens = "";
		for (int e = 0; e < enX.Size(); e++) ens = ens .. (e ? ", " : "") .. enName[e];
		Console.Printf("Obs %s (%s): seed %d, %d rooms, %d spots, %d doors, %d guards, %d bystanders, entries: %s; in by %s",
			level.MapName, VariantName(), seed, rId.Size(), sX.Size(), doors.Size(), guards, civs, ens, insertName);
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] >= 0) Console.Printf("\cfObjective %d in %s", k, rName[objRoom[k]]);
		int unreach = 0;
		for (int r = 0; r < rId.Size(); r++) if (Has(r, RF_UNREACH)) unreach++;
		int objs = 0;
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (objRoom[k] >= 0) objs++;
		int tinted = 0;
		for (int r = 0; r < rTint.Size(); r++) if (rTint[r] >= 0) tinted++;
		Console.Printf("OBSQA %s seed %d: entries %d (moved %d, dropped %d), rooms %d (unreachable %d), objectives %d, ducts %d, windows opened %d, dark rooms %d, cover %d, mood %s (%d rooms)",
			level.MapName, seed, enX.Size(), entriesMoved, entriesDropped, rId.Size(), unreach, objs, ductRooms, windowsOpened, DarkCount(), coverPlaced, MOOD_NAMES[mood], tinted);
		if (probe) { probe.Destroy(); probe = null; }
		if (CVar.FindCVar("cw_simverbose").GetInt() >= 1)
		{
			// QA: where things are (tools/qa/obslook.sh warps to these)
			Console.Printf("OBSPOS insert %d %d %d", int(insertPos.x), int(insertPos.y), int(insertAng));
			for (int r = 0; r < rId.Size(); r++) Console.Printf("OBSPOS room%02d %d %d %d", r, int(rX[r]), int(rY[r]), Rand(0, 7) * 45);
			let di = ThinkerIterator.Create("CW_ObsDuct");
			Actor dm;
			int dn = 0;
			while ((dm = Actor(di.Next())) && dn < 3) { Sector ds = level.PointInSector(dm.pos.xy); if (ds && secDuct[ds.Index()]) { Console.Printf("OBSPOS duct%d %d %d %d", dn, int(dm.pos.x), int(dm.pos.y), 0); dn++; } }
		}
	}

	// the player fits where it stands and can take a step in most directions
	static bool CanMove(PlayerPawn pm)
	{
		if (!pm.CheckPosition(pm.pos.xy)) return false;
		if (pm.ceilingz - pm.floorz < pm.height) return false;
		int open = 0;
		for (int d = 0; d < 8; d++) if (pm.CheckMove(pm.pos.xy + Actor.AngleToVector(d * 45) * 24)) open++;
		return open >= 3;
	}

	void Insert(PlayerPawn pm)
	{
		if (!pm) return;
		pm.TakeInventory("CW_SecurityPass", 99);
		let l = CW_Ledger.Of(pm);
		if (l) { l.passMask = 0; l.arriveTower = -1; }
		pm.SetOrigin((insertPos, FloorAt(insertPos)), false);
		pm.angle = insertAng;
		// last check with the player itself: stuck? try the other entries, then around this one
		if (!CanMove(pm))
		{
			bool ok = false;
			for (int e = 0; e < enX.Size() && !ok; e++)
			{
				pm.SetOrigin(((enX[e], enY[e]), FloorAt((enX[e], enY[e]))), false);
				if (CanMove(pm)) { ok = true; insertName = enName[e]; pm.angle = enA[e]; }
			}
			for (int ring = 1; ring <= 8 && !ok; ring++)
				for (int d = 0; d < 8 && !ok; d++)
				{
					Vector2 q = insertPos + Actor.AngleToVector(d * 45) * (ring * 24);
					pm.SetOrigin((q, FloorAt(q)), false);
					if (CanMove(pm)) ok = true;
				}
			Console.Printf("OBSQA insert %s", ok ? "fixed at spawn" : "STUCK");
			if (!ok) pm.SetOrigin((insertPos, FloorAt(insertPos)), false);
		}
		String site = siteName.Length() ? siteName : ((l && l.job) ? l.job.target : VariantName());
		pm.A_Print(String.Format("\cg%s\n\cj%s\n\cjInsertion: %s\n\cdExtraction: any way out you came in by", site.MakeUpper(), VariantName(), insertName), 6);
	}
}
