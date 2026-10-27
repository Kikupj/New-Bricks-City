// =============================================================================
// Corpo Wars — debug hub (Play_CorpoWars_DebugHub.bat sets cw_debughub 1 + sv_cheats 1)
// The terminal's OPERATIONS tab becomes a kit tester: every site kit and variant, the office floor,
// the garage and the handmade maps, reachable from HUB01.
//   WALK IN  = load the map with no job (cw_kitvariant / cw_floors pick the layout); Return-to-hub key comes back
//   WITH JOB = take a job off the board, move it onto that kit/variant at no cost, deploy it for real
// =============================================================================
class CW_DebugKits
{

	static clearscope int Count() { return 48; }
	static clearscope String MapOf(int i)
	{
		static const String maps[] = {
			"K01","K01","K01","K01","K01","K01","K01","K01","K01",
			"K02","K02","K02","K02","K02","K02","K02",
			"K03","K03","K03","K03","K03","K03","K03","K03","K03",
			"K04","K04","K04","K04","K04","K04","K04",
			"K05","K05","K05","K05","K05","K05","K05",
			"K06","K06","K06",
			"G02","G02","G05","CWTEST","M01","M02"
		};
		return maps[clamp(i, 0, 47)];
	}
	static clearscope int Variant(int i)
	{
		static const int vars[] = {
			-1,0,1,2,3,4,5,6,7,
			-1,0,1,2,3,4,5,
			-1,0,1,2,3,4,5,6,7,
			-1,0,1,2,3,4,5,
			-1,0,1,2,3,4,5,
			-1,0,1,
			-1,-1,-1,-1,-1,-1
		};
		return vars[clamp(i, 0, 47)];
	}
	static clearscope String Name(int i)
	{
		static const String names[] = {
			"random","club","restaurant","pawn shop","street market","mall","drug lab","chop shop","gambling den",
			"random","tenement","apartment block","luxury apartments","hotel","hacker den","rooftops",
			"random","warehouse","sea dock","fabrication plant","power plant","substation","industrial park","salvage yard","construction site",
			"random","maintenance tunnels","underpass","transit station","parking garage","hydroponic farm","bunker",
			"random","union hall","meeting hall","church hall","university","hospital","archive",
			"random","data centre","lab",
			"single floor","3-floor tower","B1 garage","stealth test","Oriole Helix Lab","Castellan R&D Annex"
		};
		return names[clamp(i, 0, 47)];
	}
	static clearscope int Floors(int i) { return i == 43 ? 3 : 1; }
	static clearscope bool JobOk(int i) { String m = MapOf(i); return CW_KitGen.KitOfMap(m) > 0 || m == "G02"; }
	static clearscope int VariantCount(String m)
	{
		static const int n[] = { 8, 6, 8, 6, 6, 2 };
		int k = CW_KitGen.KitOfMap(m);
		return k > 0 ? n[k - 1] : 1;
	}
	static clearscope String Group(String m)
	{
		if (m == "K01") return "K01  STREET BLOCK";
		if (m == "K02") return "K02  RESIDENTIAL";
		if (m == "K03") return "K03  INDUSTRIAL";
		if (m == "K04") return "K04  UNDERGROUND";
		if (m == "K05") return "K05  CIVIC HALL";
		if (m == "K06") return "K06  TECH INTERIOR";
		if (m == "G02") return "G02  OFFICE FLOOR";
		return "OTHER MAPS";
	}
	static clearscope bool On() { let cv = CVar.FindCVar("cw_debughub"); return cv && cv.GetBool(); }

	// ---- play side (network events from the terminal / the return key)
	static play void Go(CW_Ledger l, int i, bool withJob)
	{
		if (!On() || !l || l.missionActive || i < 0 || i >= Count()) return;
		String m = MapOf(i);
		int v = Variant(i);
		if (withJob && JobOk(i))
		{
			if (!l.city) { Console.MidPrint(NewSmallFont, "\cgNo city yet: walk out of the office and back in."); return; }
			for (int j = 0; j < l.OfferCount(); j++)
			{
				let o = l.Offer(j);
				if (o.refused.Length()) continue;
				o.map = m;
				o.kitVariant = v >= 0 ? v : Random(0, VariantCount(m) - 1);
				o.floors = Floors(i);
				o.garageOk = false;
				o.cost = 0;
				Console.Printf("CW_DEBUGHUB job on %s v%d: %s", m, o.kitVariant, o.target);
				l.selected = j;
				l.BeginMission();
				return;
			}
			Console.MidPrint(NewSmallFont, "\cgNo job on the board to borrow. Close the day and try again.");
			return;
		}
		// walk in: no job, the test CVars pick the layout
		CVar.FindCVar("cw_kitvariant").SetInt(v);
		CVar.FindCVar("cw_floors").SetInt(Floors(i));
		l.job = null;   // CW_Building.Floors reads a lingering job before cw_floors
		Console.Printf("CW_DEBUGHUB walk-in %s (%s)", m, Name(i));
		level.ChangeLevel(m, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}

	static play void GoHome(CW_Ledger l)
	{
		let vk = CW_CityLink.Get();
		if ((!On() && !(vk && vk.visit)) || !l) return;      // debug hub, or a visit from the city map
		if (level.MapName ~== "HUB01") return;
		if (l.missionActive && l.job) { l.FinishMission(false); return; }   // counts as an abort; FinishMission goes home
		level.ChangeLevel("HUB01", 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}
}
