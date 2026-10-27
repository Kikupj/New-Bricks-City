// =============================================================================
// Corpo Wars — multi-floor buildings (G02 / G03 / G04 in one hub cluster).
// A contract with floors > 1 spans that many consecutive floors of the tower. You always insert on map 0
// (G02) and extract there; the other floors are reached through the stair towers (the landing fire doors
// for mission floors are open and change level). Everything is derived from the mission seed, so every
// floor agrees on the building: floor numbers, which floor holds which objective.
// Security passes are per floor: a pass found on floor index m is tier m (floppy colour m) and opens only
// that floor's maglocks.
// =============================================================================
class CW_Building play
{
	const MAX_FLOORS = 3;

	static clearscope String MapName(int m) { return m == 1 ? "G03" : (m == 2 ? "G04" : "G02"); }
	static clearscope int MapIndex(String name)
	{
		if (name ~== "G02") return 0;
		if (name ~== "G03") return 1;
		if (name ~== "G04") return 2;
		return -1;
	}
	static clearscope bool IsFloorMap(String name) { return MapIndex(name) >= 0; }

	// Floors in the running mission's building (or the cw_floors test CVar with no mission).
	static int Floors(CW_Ledger l)
	{
		if (l && l.job)
		{
			let c = l.job;
			if (c && c.map ~== "G02") return clamp(c.floors, 1, MAX_FLOORS);
			return 1;
		}
		let vk = CW_CityLink.Get();
		if (vk && vk.visit) return 1;                                  // a walk-in from the city map: a single floor
		return clamp(CVar.FindCVar("cw_floors").GetInt(), 1, MAX_FLOORS);
	}

	static clearscope int Mix(int seed, int salt)
	{
		int h = seed ^ (salt * 374761393 + 668265263);
		h = (h ^ (h >> 13)) * 1274126177;
		return (h ^ (h >> 16)) & 0x7fffffff;
	}

	// Floor number of map m. The floors are consecutive; the insertion floor (map 0) sits at a random slot.
	static clearscope int FloorNum(int seed, int floors, int m)
	{
		if (floors <= 1) return 0;
		int bottom = 5 + Mix(seed, 3) % 18;
		int s0 = Mix(seed, 7) % floors;
		if (m == 0) return bottom + s0;
		int slot = m - 1;
		if (slot >= s0) slot++;
		return bottom + slot;
	}

	// Which map index holds objective kind k. Primaries are never on the insertion floor.
	static clearscope int ObjFloor(int seed, int floors, CW_Contract c, int k)
	{
		if (floors <= 1) return 0;
		if (c && c.IsPrimary(k)) return 1 + Mix(seed, 11 * k) % (floors - 1);
		return Mix(seed, 13 * k) % floors;
	}

	static clearscope String TierColour(int t)
	{
		static const String names[] = { "blue", "red", "yellow", "cyan", "purple" };
		return names[clamp(t, 0, 4)];
	}
}
