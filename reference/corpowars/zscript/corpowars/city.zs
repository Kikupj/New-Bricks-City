// =============================================================================
// Corpo Wars — the city layer: data model (design: Design Docs/city-layer-design.md)
// EarthGov -> Meridian -> 6 corps -> 32 subsidiaries -> 67 properties in 5 districts, plus 4 minor players.
// The roster is read from cwcity.txt when a campaign starts; everything after that lives in CW_City,
// which hangs off the player's CW_Ledger and is saved with the game.
// Money inside the sim is in $1000s (k). The player's own budget stays in dollars.
// Factions: corps are 0..5, minor players are MINOR_BASE + 0..3.
// =============================================================================

enum CW_PropType
{
	PT_OFF, PT_HQ, PT_CLN, PT_STU, PT_TRN, PT_RND, PT_LAB, PT_DC, PT_FARM, PT_BNK,
	PT_WH, PT_DOCK, PT_FAB, PT_PLT, PT_SUB, PT_PARK, PT_SAL, PT_COUNT
}

// Operation goals (what a successful operation does to its target)
enum CW_Goal
{
	G_STEAL, G_SABOTAGE, G_RECRUIT,      // corp vs corp (and minor players' thefts)
	G_STRIKE, G_RAID, G_LEAK, G_PROTEST, G_EXTORT,   // minor players vs corp properties
	G_SUPPRESS,                          // corp vs a minor player's stronghold
	G_COUNTER,                           // defensive: find the leak, harden the site
	G_COUNT
}

// Step roles (contract-hierarchy.md)
enum CW_Role { R_CONTRACT, R_INTEL, R_ACCESS, R_WEAKEN, R_LEVERAGE, R_PROGRESS, R_COUNT }

// Agenda kinds
enum CW_AgendaKind { AG_HURT, AG_TECH, AG_SUPPRESS, AG_PROTECT, AG_HIRE, AG_EXPOSE, AG_TURF, AG_COUNT }

// Neutral site kinds (neutral-sites-and-odd-jobs.md). Until they have generators they run on a G02 floor.
enum CW_Site
{
	NS_CONSTRUCTION, NS_ROOFTOPS, NS_TUNNELS, NS_PARKING, NS_UNDERPASS, NS_TENEMENT, NS_APARTMENTS, NS_LUXURY,
	NS_HOTEL, NS_BAR, NS_MARKET, NS_RESTAURANT, NS_MALL, NS_PAWN, NS_UNIVERSITY, NS_HOSPITAL, NS_TRANSIT,
	NS_UNIONHALL, NS_ARCHIVE, NS_DRUGLAB, NS_CHOPSHOP, NS_GAMBLING, NS_COUNT
}

class CWC_Corp play
{
	String code, name, short, motto, special;
	int wealth, security, tech, aggression, ethics, theme;
	int wSteal, wSab, wRec;
	int treasury, debt;          // $k
	int overhead;                // fixed daily costs ($k), set when the campaign starts
	bool alive;
	int diedDay;
	int finKnownDay;             // fog of war: day the player last bought / found intel on this corp
	int alertUntil;              // hot run against them: their sites stay alert until this day
	int overDays;                // consecutive days over the Meridian credit limit
	int lastAgendaDay;
}

class CWC_Sub play
{
	String code, name, niche, service;
	int corp;                    // owner (-1 = Meridian receivership)
	int origCorp;
	bool shell, shellKnown;
	int force, tech;             // default security profile
	int head;                    // exec index, -1 = vacant (an unnamed deputy runs it)
	int boostUntil, boostPct;    // stolen tech / poached talent paying off
}

class CWC_Prop play
{
	int sub, type, district;
	String label;
	int seed;                    // fixed map seed for this save
	int damagedUntil, stolenUntil, scandalUntil, strikeUntil, troubleUntil, darkUntil;
	int alertUntil;              // guards on edge (hot run, operation leaked)
	int hardenUntil, hardenForce;// counter-operation / post-hit security upgrade
	int refitUntil;              // just changed hands: security is soft
	int secKnownDay;             // fog: exact security known (site survey, intel odd job)
	int leaseEnd;                // non-HQ: the lease comes up for renewal
	bool seized;                 // Meridian seized it: EarthGov guards it until the auction
}

class CWC_Exec play
{
	String name, role;
	int corp;                    // employer corp (CEOs: the corp they run)
	int sub;                     // subsidiary they head (-1 for a CEO)
	int minor;                   // minor-player leaders: the group (-1 for corp executives)
	int prop;                    // where they work (property index), -1 = a stronghold / unknown
	int district;
	bool ceo, gone;              // out = extracted, dead or otherwise gone
	bool locKnown;
	int bonus;                   // % income bonus they bring
	int movedDay;
}

class CWC_Minor play
{
	String code, name, short, kind, service, special;
	int turf[5];
	int startTurf[5];
	int aggression, wSteal, wSab, wRec;
	int funds;                   // $k
	int dormantUntil;            // 0 = active
	int leaderOutUntil;
	int turfKnownDay;
	bool dormant;
}

class CWC_Stronghold play
{
	int minor, district, seed;
	String name;
}

class CWC_Agenda play
{
	int owner, kind, target, focusSub, district;
	String text;
	int since;
}

class CWC_Step play
{
	int role;
	bool decisive;               // the step the operation's success hangs on
	int prop;                    // contract at a corp property (-1 = neutral site / stronghold)
	int stronghold;              // contract at a minor player's stronghold (-1 = none)
	int site, district, seed;    // neutral site (odd jobs)
	int mode;                    // objective verb: 0 take, 1 photograph, 2 plant, 3 destroy, 4 meet / lean on, 5 extract
	String what;                 // "Dr. Hana Ito's schedule", "a maintenance keycard" ...
	int pay;                     // $
	int done;                    // 0 open, 1 you, 2 freelancers
	bool taken;                  // you're on it right now
}

class CWC_Op play
{
	int id, client, launcher;    // client faction, launching subsidiary (-1 = minor player / none)
	int goal;
	int tFaction, tProp, tStronghold, tExec, tDistrict;
	int counterOf;               // op id this one answers (-1)
	int progress, startDay, deadline;
	int state;                   // 0 running, 1 succeeded, 2 failed, 3 withdrawn
	bool clientKnown, linkKnown;
	int playerSteps;
	int agendaKind;
	String title;
	Array<CWC_Step> steps;
}

class CWC_Listing play
{
	bool wholeSub;               // a whole subsidiary (distress sale, carve-up, receivership) or one property
	int idx;                     // property or subsidiary index
	int seller;                  // corp, or -1 = Meridian (foreclosure / receivership)
	int reason;                  // 0 foreclosure, 1 distress sale, 2 lease expiry, 3 scandal sale, 4 carve-up, 5 receivership
	int day;                     // auction day
	int minPrice;                // $k
}

class CW_City play
{
	const NDIST = 5;
	const NCORP = 6;
	const NMINOR = 4;
	const MINOR_BASE = 10;
	const WIN_SUBS = 17;
	const INTEL_DAYS = 7;        // intel goes stale after this many days
	const MAX_NEWS = 120;

	int day;
	int nextOpId;
	Array<String> distCode, distName;
	Array<int> distTall;
	Array<CWC_Corp> corps;
	Array<CWC_Sub> subs;
	Array<CWC_Prop> props;
	Array<CWC_Exec> execs;
	Array<CWC_Minor> minors;
	Array<CWC_Stronghold> holds;
	Array<CWC_Agenda> agendas;
	Array<CWC_Op> ops;
	Array<CWC_Listing> listings;
	Array<int> rel;              // corp x corp (NCORP * NCORP)
	Array<int> mrel;             // minor x corp (NMINOR * NCORP)
	Array<int> rep;              // the player's standing with each corp
	Array<int> mrep;             // ... and with each minor player
	Array<String> news;          // newest last: "<day>\t<text>"
	Array<String> todayNews;     // headlines from the last day tick (debrief)
	Array<String> marketLog;     // "<day>\t<text>" auction results
	int patron;                  // corp the player pledged to (-1 = free agent)
	int offer;                   // corp currently offering patronage (-1 = none)
	int declinedUntil;
	bool betrayed[6];
	int outcome;                 // 0 running, 1 won, 2 lost
	String outcomeText;
	int jobsDone, oddJobsDone;

	// ================================================================ static tables
	static clearscope String TypeCode(int t)
	{
		static const String c[] = { "OFF", "HQ", "CLN", "STU", "TRN", "RND", "LAB", "DC", "FARM", "BNK", "WH", "DOCK", "FAB", "PLT", "SUB", "PARK", "SAL" };
		return (t >= 0 && t < PT_COUNT) ? c[t] : "?";
	}
	static clearscope String TypeName(int t)
	{
		static const String n[] = { "office", "HQ", "clinic", "studio", "training centre", "R&D site", "lab", "data centre", "underground farm", "bunker",
			"warehouse", "sea dock", "fabrication facility", "power plant", "substation", "industrial park", "salvage yard" };
		return (t >= 0 && t < PT_COUNT) ? n[t] : "site";
	}
	static int TypeFromCode(String s)
	{
		for (int t = 0; t < PT_COUNT; t++) if (TypeCode(t) ~== s) return t;
		return PT_OFF;
	}
	// daily yield ($k) by building type (subsidiaries-draft.md: labs/R&D/DC/fabs/plants high ... HQ low)
	static clearscope int TypeYield(int t)
	{
		static const int y[] = { 4, 4, 5, 5, 5, 9, 8, 8, 5, 6, 4, 6, 7, 8, 4, 5, 3 };
		return (t >= 0 && t < PT_COUNT) ? y[t] : 3;
	}
	// power draw ($k/day)
	static clearscope double TypePower(int t)
	{
		switch (t)
		{
		case PT_DC: return 2.4;
		case PT_FAB: return 1.4;
		case PT_LAB: case PT_RND: return 1.0;
		case PT_PLT: return 0.0;
		case PT_FARM: return 0.9;
		}
		return 0.4;
	}
	// floors a contract spans on the G02 fallback (executives-and-insertion.md)
	static int TypeFloors(int t, int seed)
	{
		switch (t)
		{
		case PT_HQ: return 3;
		case PT_OFF: return 2 + (seed & 1);
		case PT_LAB: case PT_DC: case PT_RND: case PT_TRN: return 2;
		case PT_CLN: case PT_STU: case PT_FAB: case PT_BNK: case PT_FARM: return 1 + ((seed >> 3) & 1);
		}
		return 1;
	}
	// interior fit-out on the G02 fallback: offices wear the owner's theme, the rest their type's look
	static clearscope int TypeTheme(int t, int corpTheme)
	{
		switch (t)
		{
		case PT_LAB: case PT_CLN: case PT_RND: return 2;           // Clinical White
		case PT_DC: case PT_TRN: case PT_BNK: return 3;            // Night Glass
		case PT_STU: return 1;                                     // Walnut & Brass
		case PT_WH: case PT_DOCK: case PT_FAB: case PT_PLT: case PT_SUB: case PT_PARK: case PT_SAL: case PT_FARM: return 4;   // Brick & Steel
		}
		return corpTheme;
	}
	// towers with a B1 garage (HQs, offices, labs, data centres, R&D in tall districts)
	clearscope bool HasGarage(int p)
	{
		let pr = props[p];
		bool towerType = pr.type == PT_HQ || pr.type == PT_OFF || pr.type == PT_LAB || pr.type == PT_DC || pr.type == PT_RND;
		return towerType && distTall[pr.district] != 0;
	}

	static clearscope String SiteName(int s)
	{
		static const String n[] = { "construction site", "rooftops", "maintenance tunnels", "parking structure", "rail underpass", "tenement",
			"apartment block", "luxury apartments", "hotel", "club", "street market", "restaurant", "mall", "pawn shop", "university",
			"hospital", "transit hub", "union hall", "records archive", "drug lab", "chop shop", "gambling den" };
		return (s >= 0 && s < NS_COUNT) ? n[s] : "site";
	}
	static clearscope String SiteArticle(int s)
	{
		switch (s) { case NS_ROOFTOPS: case NS_TUNNELS: case NS_LUXURY: return "the"; case NS_UNIVERSITY: case NS_UNIONHALL: return "the"; }
		return "a";
	}
	// G02 fallback theme per neutral site
	static clearscope int SiteTheme(int s)
	{
		switch (s)
		{
		case NS_HOTEL: case NS_LUXURY: case NS_RESTAURANT: case NS_GAMBLING: return 1;
		case NS_HOSPITAL: case NS_UNIVERSITY: return 2;
		case NS_MALL: case NS_TRANSIT: case NS_APARTMENTS: return 3;
		case NS_CONSTRUCTION: case NS_TUNNELS: case NS_PARKING: case NS_UNDERPASS: case NS_TENEMENT: case NS_BAR: case NS_MARKET:
		case NS_PAWN: case NS_DRUGLAB: case NS_CHOPSHOP: case NS_ROOFTOPS: return 4;
		}
		return 0;
	}

	static clearscope String GoalName(int g)
	{
		static const String n[] = { "steal", "sabotage", "recruit", "strike", "raid", "leak", "protest", "extort", "suppress", "counter" };
		return (g >= 0 && g < G_COUNT) ? n[g] : "?";
	}
	static clearscope String RoleName(int r)
	{
		static const String n[] = { "CONTRACT", "INTEL", "ACCESS", "WEAKEN", "LEVERAGE", "PROGRESS" };
		return (r >= 0 && r < R_COUNT) ? n[r] : "?";
	}
	static clearscope Color RoleColor(int r)
	{
		switch (r)
		{
		case R_CONTRACT: return Color(240, 170, 40);
		case R_INTEL:    return Color(60, 200, 220);
		case R_ACCESS:   return Color(90, 150, 255);
		case R_WEAKEN:   return Color(230, 90, 60);
		case R_LEVERAGE: return Color(170, 110, 240);
		case R_PROGRESS: return Color(90, 200, 110);
		}
		return Color(128, 128, 128);
	}
	static clearscope String RoleDesc(int r)
	{
		switch (r)
		{
		case R_INTEL:    return "Reveals the strike's security and target, and lets you choose your entry.";
		case R_ACCESS:   return "You start the strike holding a security pass.";
		case R_WEAKEN:   return "Fewer guards and lower tech on the strike.";
		case R_LEVERAGE: return "Softer outcome: the target co-operates and the client pays more.";
		case R_PROGRESS: return "Moves the operation straight toward success.";
		}
		return "The decisive strike. Big pay, big risk, big effect.";
	}

	// ================================================================ factions
	static clearscope bool IsMinor(int f) { return f >= MINOR_BASE && f < MINOR_BASE + NMINOR; }
	static clearscope bool IsCorp(int f) { return f >= 0 && f < NCORP; }

	clearscope String FactionName(int f)
	{
		if (IsCorp(f) && f < corps.Size()) return corps[f].name;
		if (IsMinor(f) && f - MINOR_BASE < minors.Size()) return minors[f - MINOR_BASE].name;
		if (f == -1) return "Meridian Capital";
		return "?";
	}
	clearscope String FactionShort(int f)
	{
		if (IsCorp(f) && f < corps.Size()) return corps[f].short;
		if (IsMinor(f) && f - MINOR_BASE < minors.Size()) return minors[f - MINOR_BASE].short;
		if (f == -1) return "Meridian";
		return "?";
	}
	static clearscope int FactionFont(int f)
	{
		switch (f)
		{
		case 0: return Font.CR_PURPLE;     // Oriole
		case 1: return Font.CR_LIGHTBLUE;  // Castellan
		case 2: return Font.CR_ORANGE;     // Halvorsen
		case 3: return Font.CR_RED;        // Sable
		case 4: return Font.CR_YELLOW;     // Corvane
		case 5: return Font.CR_CYAN;       // Lattice
		case MINOR_BASE + 0: return Font.CR_BRICK;
		case MINOR_BASE + 1: return Font.CR_GREEN;
		case MINOR_BASE + 2: return Font.CR_DARKGREEN;
		case MINOR_BASE + 3: return Font.CR_TAN;
		case -1: return Font.CR_GOLD;
		}
		return Font.CR_GRAY;
	}
	static clearscope Color FactionColor(int f)
	{
		switch (f)
		{
		case 0: return Color(170, 110, 240);
		case 1: return Color(110, 170, 255);
		case 2: return Color(240, 140, 50);
		case 3: return Color(220, 70, 70);
		case 4: return Color(240, 210, 60);
		case 5: return Color(60, 210, 220);
		}
		return Color(110, 120, 130);
	}

	// ---- relations (-100..100). Corp-corp symmetric; minor-corp symmetric.
	clearscope int GetRel(int a, int b)
	{
		if (a == b) return 100;
		if (IsCorp(a) && IsCorp(b)) return rel[a * NCORP + b];
		if (IsMinor(a) && IsCorp(b)) return mrel[(a - MINOR_BASE) * NCORP + b];
		if (IsCorp(a) && IsMinor(b)) return mrel[(b - MINOR_BASE) * NCORP + a];
		return -60;   // minor players don't get along with each other either
	}
	void AddRel(int a, int b, int d)
	{
		if (a == b || !d) return;
		if (IsCorp(a) && IsCorp(b))
		{
			int v = clamp(rel[a * NCORP + b] + d, -100, 100);
			rel[a * NCORP + b] = v; rel[b * NCORP + a] = v;
		}
		else if (IsMinor(a) && IsCorp(b)) mrel[(a - MINOR_BASE) * NCORP + b] = clamp(mrel[(a - MINOR_BASE) * NCORP + b] + d, -100, 100);
		else if (IsCorp(a) && IsMinor(b)) mrel[(b - MINOR_BASE) * NCORP + a] = clamp(mrel[(b - MINOR_BASE) * NCORP + a] + d, -100, 100);
	}
	// the player's standing
	clearscope int GetRep(int f)
	{
		if (IsCorp(f)) return rep[f];
		if (IsMinor(f)) return mrep[f - MINOR_BASE];
		return 0;
	}
	void AddRep(int f, int d)
	{
		if (IsCorp(f)) rep[f] = clamp(rep[f] + d, -100, 100);
		else if (IsMinor(f)) mrep[f - MINOR_BASE] = clamp(mrep[f - MINOR_BASE] + d, -100, 100);
	}
	// Tiers (X-COM Apocalypse): Allied 75+ / Friendly 25+ / Neutral / Unfriendly -25 / Hostile -50
	static clearscope int Tier(int v) { return v >= 75 ? 2 : v >= 25 ? 1 : v > -25 ? 0 : v > -50 ? -1 : -2; }
	static clearscope String TierName(int v)
	{
		switch (Tier(v)) { case 2: return "Allied"; case 1: return "Friendly"; case 0: return "Neutral"; case -1: return "Unfriendly"; }
		return "Hostile";
	}
	static clearscope int TierFont(int v)
	{
		switch (Tier(v)) { case 2: return Font.CR_GREEN; case 1: return Font.CR_DARKGREEN; case 0: return Font.CR_GRAY; case -1: return Font.CR_ORANGE; }
		return Font.CR_RED;
	}
	// how the player is treated by f: the patron's allies treat you one tier friendlier
	clearscope int EffRep(int f)
	{
		int v = GetRep(f);
		if (patron >= 0 && IsCorp(f) && f != patron && GetRel(patron, f) >= 50) v = min(100, v + 25);
		return v;
	}

	// ================================================================ ownership and counts
	clearscope int PropCorp(int p)
	{
		if (p < 0 || p >= props.Size()) return -1;
		int s = props[p].sub;
		return s >= 0 ? subs[s].corp : -1;
	}
	clearscope int SubCount(int c)
	{
		int n = 0;
		for (int i = 0; i < subs.Size(); i++) if (subs[i].corp == c) n++;
		return n;
	}
	clearscope int PropCount(int c)
	{
		int n = 0;
		for (int i = 0; i < props.Size(); i++) if (PropCorp(i) == c) n++;
		return n;
	}
	clearscope int SubProps(int s)
	{
		int n = 0;
		for (int i = 0; i < props.Size(); i++) if (props[i].sub == s) n++;
		return n;
	}
	clearscope int AliveCorps()
	{
		int n = 0;
		for (int i = 0; i < corps.Size(); i++) if (corps[i].alive) n++;
		return n;
	}

	// "Helix Labs lab (EG)"
	clearscope String PropName(int p)
	{
		if (p < 0 || p >= props.Size()) return "?";
		let pr = props[p];
		String kind = pr.label.Length() ? pr.label : TypeName(pr.type);
		String owner = pr.sub >= 0 ? subs[pr.sub].name : "Meridian";
		return String.Format("%s %s (%s)", owner, kind, distCode[pr.district]);
	}
	// what the player may see of a subsidiary's name (shells hide their parent, not their name)
	clearscope String SubOwnerLabel(int s)
	{
		if (s < 0) return "Meridian receivership";
		let sb = subs[s];
		if (sb.corp < 0) return "Meridian receivership";
		if (sb.shell && !sb.shellKnown) return "? (shell)";
		return corps[sb.corp].short;
	}
	clearscope bool IntelFresh(int dayKnown) { return dayKnown > -99 && day - dayKnown <= INTEL_DAYS; }

	// ---- security at a property: guard force (EarthGov-capped at 16) and tech level (1-4)
	clearscope int PropForce(int p)
	{
		let pr = props[p];
		int f = pr.sub >= 0 ? subs[pr.sub].force : 8;
		if (pr.type == PT_BNK || pr.type == PT_TRN) f += 2;
		if (pr.type == PT_HQ) f += 1;
		if (day < pr.hardenUntil) f += pr.hardenForce;
		if (day < pr.alertUntil) f += 2;
		if (day < pr.refitUntil) f -= 3;
		if (pr.seized) f = 14;
		return clamp(f, 4, 16);
	}
	clearscope int PropTech(int p)
	{
		let pr = props[p];
		int t = pr.sub >= 0 ? subs[pr.sub].tech : 2;
		if (day < pr.refitUntil) t--;
		if (day < pr.darkUntil) t--;
		return clamp(t, 1, 4);
	}
	static clearscope int RiskOf(int force, int tech)
	{
		int sc = force + tech * 2;
		return sc >= 19 ? 3 : sc >= 13 ? 2 : 1;
	}
	static clearscope String RoughSecurity(int force, int tech)
	{
		int r = RiskOf(force, tech);
		return r >= 3 ? "tight" : r == 2 ? "moderate" : "light";
	}

	// daily yield of a property after events ($k, can be fractional internally)
	clearscope double PropYield(int p)
	{
		let pr = props[p];
		if (pr.sub < 0 || pr.seized) return 0;
		double y = TypeYield(pr.type);
		double m = 1.0;
		if (day < pr.damagedUntil) m -= 0.5;
		if (day < pr.darkUntil) m -= 0.5;
		if (day < pr.stolenUntil) m -= 0.25;
		if (day < pr.scandalUntil) m -= 0.2;
		if (day < pr.strikeUntil) m -= 0.4;
		let sb = subs[pr.sub];
		if (sb.head < 0) m -= 0.1;
		else m += execs[sb.head].bonus / 100.0;
		if (day < sb.boostUntil) m += sb.boostPct / 100.0;
		m += 0.03 * (sb.tech - 2);
		return y * max(0.0, m);
	}
	clearscope int PropValue(int p) { return TypeYield(props[p].type) * CW_Tune.PROP_VALUE; }
	clearscope int SubValue(int s)
	{
		int v = 0;
		for (int i = 0; i < props.Size(); i++) if (props[i].sub == s) v += PropValue(i);
		return max(v, 40);   // an empty brand still has some worth
	}
	clearscope int CorpValue(int c)
	{
		int v = 0;
		for (int i = 0; i < props.Size(); i++) if (PropCorp(i) == c) v += PropValue(i);
		return v;
	}
	clearscope int CreditLimit(int c) { return CorpValue(c) * CW_Tune.CREDIT_PCT / 100; }

	// ================================================================ news
	void AddNews(String t)
	{
		news.Push(String.Format("%d\t%s", day, t));
		todayNews.Push(t);
		while (news.Size() > MAX_NEWS) news.Delete(0);
	}

	// ================================================================ loading the roster
	int FindCorp(String code) { for (int i = 0; i < corps.Size(); i++) if (corps[i].code ~== code) return i; return -1; }
	int FindSub(String code) { for (int i = 0; i < subs.Size(); i++) if (subs[i].code ~== code) return i; return -1; }
	int FindMinor(String code) { for (int i = 0; i < minors.Size(); i++) if (minors[i].code ~== code) return i; return -1; }
	int FindDist(String code) { for (int i = 0; i < distCode.Size(); i++) if (distCode[i] ~== code) return i; return 0; }
	// a faction code: corp code, minor code, or "-"
	int FindFaction(String code)
	{
		int c = FindCorp(code);
		if (c >= 0) return c;
		int m = FindMinor(code);
		return m >= 0 ? MINOR_BASE + m : -99;
	}

	static CW_City Create()
	{
		let c = new("CW_City");
		c.day = 1;
		c.nextOpId = 1;
		c.patron = -1;
		c.offer = -1;
		if (!c.Load()) Console.Printf("\crCorpo Wars: cwcity.txt missing or empty; the city is empty.");
		c.Randomise();
		return c;
	}

	bool Load()
	{
		int lump = Wads.CheckNumForFullName("cwcity.txt");
		if (lump < 0) return false;
		String txt = Wads.ReadLump(lump);
		Array<String> lines;
		txt.Split(lines, "\n");
		for (int i = 0; i < NCORP * NCORP; i++) rel.Push(0);
		for (int i = 0; i < NMINOR * NCORP; i++) mrel.Push(0);
		for (int i = 0; i < lines.Size(); i++)
		{
			String ln = lines[i];
			ln.Replace("\r", "");
			ln.StripRight();
			if (ln.Length() == 0 || ln.Left(1) == "#") continue;
			Array<String> f;
			ln.Split(f, "|", TOK_KEEPEMPTY);
			if (f.Size() < 2) continue;
			String k = f[0];
			if (k == "DISTRICT" && f.Size() >= 4)
			{
				distCode.Push(f[1]); distName.Push(f[2]); distTall.Push(f[3].ToInt());
			}
			else if (k == "CORP" && f.Size() >= 15)
			{
				let o = new("CWC_Corp");
				o.code = f[1]; o.name = f[2]; o.short = f[3];
				o.wealth = f[4].ToInt(); o.security = f[5].ToInt(); o.tech = f[6].ToInt();
				o.aggression = f[7].ToInt(); o.ethics = f[8].ToInt(); o.theme = f[9].ToInt();
				o.wSteal = f[10].ToInt(); o.wSab = f[11].ToInt(); o.wRec = f[12].ToInt();
				o.special = f[13]; o.motto = f[14];
				o.alive = true;
				o.finKnownDay = -99;
				o.treasury = 30 + o.wealth * 18;
				corps.Push(o);
			}
			else if (k == "RELROW" && f.Size() >= 2 + NCORP)
			{
				int a = FindCorp(f[1]);
				if (a >= 0) for (int b = 0; b < NCORP; b++) rel[a * NCORP + b] = f[2 + b].ToInt();
			}
			else if (k == "SUB" && f.Size() >= 9)
			{
				let o = new("CWC_Sub");
				o.code = f[1]; o.corp = FindCorp(f[2]); o.origCorp = o.corp; o.name = f[3]; o.niche = f[4];
				o.shell = f[5] ~== "shell";
				o.service = f[6] == "-" ? "" : f[6];
				o.force = clamp(f[7].ToInt(), 4, 16); o.tech = clamp(f[8].ToInt(), 1, 4);
				o.head = -1;
				subs.Push(o);
			}
			else if (k == "PROP" && f.Size() >= 4)
			{
				let o = new("CWC_Prop");
				o.sub = FindSub(f[1]); o.type = TypeFromCode(f[2]); o.district = FindDist(f[3]);
				o.label = f.Size() >= 5 ? f[4] : "";
				o.secKnownDay = -99;
				props.Push(o);
			}
			else if (k == "EXEC" && f.Size() >= 5)
			{
				let o = new("CWC_Exec");
				o.name = f[2];
				o.minor = -1;
				int cc = FindCorp(f[1]);
				if (cc >= 0) { o.ceo = true; o.corp = cc; o.sub = -1; o.role = "CEO"; o.bonus = 5; }
				else
				{
					o.sub = FindSub(f[1]);
					o.corp = o.sub >= 0 ? subs[o.sub].corp : -1;
					o.role = o.sub >= 0 ? "head of " .. subs[o.sub].name : "executive";
					o.bonus = 10;
				}
				int t = TypeFromCode(f[3]), d = FindDist(f[4]);
				o.district = d;
				o.prop = -1;
				for (int p = 0; p < props.Size(); p++)
				{
					if (props[p].type != t || props[p].district != d) continue;
					int owner = props[p].sub >= 0 ? subs[props[p].sub].corp : -1;
					if ((o.sub >= 0 && props[p].sub == o.sub) || (o.sub < 0 && owner == o.corp)) { o.prop = p; break; }
				}
				int ei = execs.Size();
				execs.Push(o);
				if (o.sub >= 0) subs[o.sub].head = ei;
			}
			else if (k == "MINOR" && f.Size() >= 16)
			{
				let o = new("CWC_Minor");
				o.code = f[1]; o.name = f[2]; o.short = f[3]; o.kind = f[4]; o.service = f[5];
				for (int d = 0; d < NDIST; d++) { o.turf[d] = f[6 + d].ToInt(); o.startTurf[d] = o.turf[d]; }
				o.aggression = f[11].ToInt(); o.wSteal = f[12].ToInt(); o.wSab = f[13].ToInt(); o.wRec = f[14].ToInt();
				o.special = f[15];
				o.funds = 60;
				o.turfKnownDay = -99;
				minors.Push(o);
			}
			else if (k == "STRONGHOLD" && f.Size() >= 4)
			{
				let o = new("CWC_Stronghold");
				o.minor = FindMinor(f[1]); o.name = f[2]; o.district = FindDist(f[3]);
				holds.Push(o);
			}
			else if (k == "LEADER" && f.Size() >= 5)
			{
				let o = new("CWC_Exec");
				o.minor = FindMinor(f[1]); o.name = f[2]; o.role = f[3]; o.district = FindDist(f[4]);
				o.corp = -1; o.sub = -1; o.prop = -1; o.bonus = 0;
				execs.Push(o);
			}
			else if (k == "MREL" && f.Size() >= 2 + NCORP)
			{
				int m = FindMinor(f[1]);
				if (m >= 0) for (int b = 0; b < NCORP; b++) mrel[m * NCORP + b] = f[2 + b].ToInt();
			}
			else if (k == "AGENDA" && f.Size() >= 6)
			{
				let o = new("CWC_Agenda");
				o.owner = FindFaction(f[1]);
				o.kind = AgendaFromCode(f[2]);
				o.target = -1; o.district = -1;
				if (o.kind == AG_TURF) o.district = FindDist(f[3]);
				else if (f[3] != "-") o.target = FindFaction(f[3]);
				o.focusSub = f[4] == "-" ? -1 : FindSub(f[4]);
				o.text = f[5];
				if (o.owner != -99) agendas.Push(o);
			}
		}
		for (int i = 0; i < NCORP; i++) rep.Push(0);
		for (int i = 0; i < NMINOR; i++) mrep.Push(0);
		return corps.Size() > 0;
	}

	static int AgendaFromCode(String s)
	{
		static const String n[] = { "HURT", "TECH", "SUPPRESS", "PROTECT", "HIRE", "EXPOSE", "TURF" };
		for (int i = 0; i < AG_COUNT; i++) if (n[i] ~== s) return i;
		return AG_HURT;
	}

	// per-save variety: relations +-10, fixed map seeds, lease dates
	void Randomise()
	{
		for (int a = 0; a < NCORP; a++)
			for (int b = a + 1; b < NCORP; b++)
			{
				int v = clamp(rel[a * NCORP + b] + Random[CWCity](-10, 10), -100, 100);
				rel[a * NCORP + b] = v; rel[b * NCORP + a] = v;
			}
		for (int i = 0; i < mrel.Size(); i++) mrel[i] = clamp(mrel[i] + Random[CWCity](-10, 10), -100, 100);
		for (int p = 0; p < props.Size(); p++)
		{
			props[p].seed = Random[CWCity](1, 0x7ffffff);
			props[p].leaseEnd = props[p].type == PT_HQ ? 0 : Random[CWCity](18, 140);
		}
		for (int h = 0; h < holds.Size(); h++) holds[h].seed = Random[CWCity](1, 0x7ffffff);
		for (int c = 0; c < corps.Size(); c++) corps[c].treasury += Random[CWCity](-8, 8);
	}

	// ---- console dump (cw_citydump)
	void Dump()
	{
		Console.Printf("\cfCITY day %d  corps %d  subs %d  props %d  execs %d  minors %d  ops %d  listings %d", day, corps.Size(), subs.Size(), props.Size(), execs.Size(), minors.Size(), ops.Size(), listings.Size());
		for (int c = 0; c < corps.Size(); c++)
		{
			let o = corps[c];
			Console.Printf("  %s%s: %s  subs %d props %d  cash %dk debt %dk/%dk  rep %d", o.alive ? "" : "\cr[GONE] ", o.name, o.code, SubCount(c), PropCount(c), o.treasury, o.debt, CreditLimit(c), rep[c]);
		}
		for (int m = 0; m < minors.Size(); m++)
		{
			let o = minors[m];
			Console.Printf("  %s: turf MR %d EG %d IS %d OQ %d HL %d  funds %dk%s", o.name, o.turf[0], o.turf[1], o.turf[2], o.turf[3], o.turf[4], o.funds, o.dormant ? " DORMANT" : "");
		}
		for (int i = 0; i < ops.Size(); i++)
		{
			let op = ops[i];
			if (op.state) continue;
			Console.Printf("  op #%d %s  %d%%  due day %d  steps %d", op.id, op.title, op.progress, op.deadline, op.steps.Size());
		}
	}
}
