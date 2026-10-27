// =============================================================================
// Corpo Wars — contracts and the campaign ledger
// =============================================================================

// Objective kinds (bit index in masks)
enum CW_ObjKind
{
	OBJ_STEAL   = 1,   // take the prototype
	OBJ_DESTROY = 2,   // wreck the research server
	OBJ_TURN    = 3    // convince the scientist to defect
}

class CW_Contract play
{
	String title, client, target, map, brief;
	int cost;
	int risk;          // 1 low, 2 medium, 3 high security
	bool repeatable;   // procedural jobs can be run again (new seed each time)
	int pay[4];        // payout per objective kind (0 = not part of contract)
	int primaryMask;   // any ONE of these completes the contract (highest pays)
	int penalty[4];    // fine for completing an objective kind the client did NOT order
	String objText[4]; // per-contract objective text (falls back to KindName)
	String stealItem, turnName;   // what the STEAL item / RECRUIT target is called in prompts
	int guardFine;     // per guard killed (0 = client doesn't care)
	bool protectCivilians;  // toggle: does this client fine civilian casualties?
	int civFine;            // fine per civilian killed when protectCivilians is on
	int floors;             // procedural sites: floors in the building (1 = single floor, 2-3 = multi-floor, G02 only)
	int theme;              // procedural sites: tenant's interior fit-out (CW_Themes), -1 = varies

	// ---- city layer (cityjobs.zs): every job is one step of an operation
	int opId, stepIdx, role;     // operation, step, CW_Role
	bool decisive;               // the operation's strike (a contract) vs an odd job
	int clientF, targetF;        // factions (corps 0-5, minor players 10-13)
	bool clientHidden;           // posted through a shell you hadn't uncovered
	int prop, hold, site, district;
	int seed;                    // map layout seed (fixed per property / stronghold, fresh for odd jobs)
	int secForce, secTech;       // guard force (6-16) and tech level (1-4) for this run
	bool secKnown, alert;
	bool neutral;                // neutral site / stronghold on the G02 fallback: no maglocks, no passes
	bool garageOk;               // a tower with a B1 garage
	int stealMode;               // STEAL objective verb: 0 take, 1 photograph, 2 plant
	int turnMode;                // RECRUIT objective verb: 0 convince, 1 lean on, 2 extract, 3 willing defector
	bool prepIntel, prepAccess, prepWeaken, prepLeverage;
	bool hasIntelStep, hasAccessStep, hasWeakenStep, hasLeverageStep;
	int deadline, progress, execIdx;
	int kitVariant;              // site kit variant (kitgen.zs) when map is K01-K06
	String refused, opTitle, where;

	static clearscope String KindName(int k)
	{
		switch (k)
		{
		case OBJ_STEAL:   return "Steal the Helix prototype";
		case OBJ_DESTROY: return "Destroy the research server";
		case OBJ_TURN:    return "Turn Dr. Vance";
		}
		return "?";
	}

	// ---- colour coding (shared by HUD + terminal)
	static clearscope int CorpFont(String corp)
	{
		if (corp.IndexOf("Castellan") >= 0) return Font.CR_LIGHTBLUE;
		if (corp.IndexOf("Oriole") >= 0)    return Font.CR_PURPLE;
		if (corp.IndexOf("Meridian") >= 0)  return Font.CR_GOLD;
		return Font.CR_GRAY;
	}
	static clearscope Color KindColor(int k)
	{
		switch (k)
		{
		case OBJ_STEAL:   return Color(70, 160, 255);   // blue  = theft
		case OBJ_DESTROY: return Color(230, 80, 60);    // red   = sabotage
		case OBJ_TURN:    return Color(170, 110, 240);  // violet = people
		}
		return Color(128, 128, 128);
	}
	static clearscope String KindTag(int k)
	{
		switch (k)
		{
		case OBJ_STEAL:   return "STEAL";
		case OBJ_DESTROY: return "SABOTAGE";
		case OBJ_TURN:    return "RECRUIT";
		}
		return "";
	}
	clearscope String StealVerb() { return stealMode == 1 ? "Photograph" : (stealMode == 2 ? "Plant" : "Take"); }
	clearscope String TurnPrompt()
	{
		switch (turnMode)
		{
		case 1: return "Lean on " .. turnName;
		case 2: return "Get " .. turnName .. " to come with you";
		case 3: return "Tell " .. turnName .. " it's time to go";
		}
		return "Convince " .. turnName .. " to defect";
	}
	static clearscope String RiskName(int r) { return r >= 3 ? "High" : (r == 2 ? "Medium" : "Low"); }
	static clearscope int RiskFont(int r) { return r >= 3 ? Font.CR_RED : (r == 2 ? Font.CR_ORANGE : Font.CR_GREEN); }

	clearscope String ObjName(int k) { return (k >= 0 && k < 4 && objText[k].Length()) ? objText[k] : KindName(k); }

	clearscope bool IsPrimary(int k) { return (primaryMask & (1 << k)) != 0; }
}

// Carried by the player across maps (inventory persists), saved with the game.
class CW_Ledger : Inventory
{
	const MERIDIAN_LIMIT = 12000;    // the most Meridian will advance you before it calls the loan (campaign loss)

	int budget;
	int selected;                    // index into city.offers on the terminal
	int activeContract;              // legacy (pre-city saves); the running job is `job`
	bool missionActive;
	int objDone;
	int kills, takedowns, alarms;
	int doorsForced;                 // maglocks broken this mission
	Array<String> approachNotes;     // "objective room<TAB>how you got in" (G02), for the debrief
	int completedMask;               // legacy
	bool debriefNew;
	int fineTotal, failedMask;
	int opCost, loadoutSpent, startBudget, civKills;
	int missionSeed;             // procedural sites rebuild from this (a property's fixed layout seed)
	int visitSeed;               // this visit's insertion / garage roll (varies every time)
	int entryPref;               // with Intel prep: 0 any, 1 garage, 2 street lobby, 3 stairwell, 4 elevator, 5 roof
	int freeIntelMask;           // intel provided by prep work or informants this run (not charged)
	int heatAdj;                 // safehouse routes etc.
	int debt;                    // Meridian advances still owed (repaid from half of each payout)
	CW_City city;                // the city layer (city.zs), created with the campaign
	CW_Contract job;             // the job being run (built from an operation step)
	// heat + garage (garage.zs)
	int bodiesFound, firstAlarmTime;
	bool garageRun;              // inserted in the parking garage: the job ends at the van
	bool rerouted;               // a hot run rerouted to the garage for extraction
	bool scenarioRolled, exitRolled;
	int scenario;                // CW_GarageGen.EScenario, -1 = none
	int heatAtExit;

	// 0..100: how much attention this run has drawn. Crew work takes the edge off.
	clearscope int Heat()
	{
		int h = alarms * 12 + kills * 6 + civKills * 12 + doorsForced * 8 + bodiesFound * 5;
		if (firstAlarmTime > 0) h += min(20, (level.totaltime - firstAlarmTime) / (35 * 30) * 3);   // +3 per half minute on alert
		if (alarms == 0) h -= 10;
		if (HasCrew(CW_Services.CREW_HACKER)) h -= 6;    // Nyx scrubs camera logs
		if (HasCrew(CW_Services.CREW_CLEANER)) h -= 8;   // Marrow: fewer bodies, fewer questions
		if (HasCrew(CW_Services.CREW_VOX)) h -= 6;       // Vox pulls the response the wrong way
		h += heatAdj;
		return clamp(h, 0, 100);
	}
	int passMask;                // security pass tiers held this mission (bit = floor index in the building)
	int arriveTower;             // multi-floor: stair tower the player is arriving through (-1 = none)
	Array<String> fineLines;
	int intelMask, crewMask;    // loadout for the next / current mission
	int hackerUses, voxUses;
	int gearOwned, noisemakers, flashbangs;   // legacy (pre-grid saves), migrated by InvInit
	Array<String> debrief;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		budget = 2000;
		activeContract = -1;
	}

	static clearscope CW_Ledger Of(Actor pm)
	{
		return pm ? CW_Ledger(pm.FindInventory("CW_Ledger")) : null;
	}

	// the job being run, or the one selected on the terminal
	clearscope int OfferCount() { return city ? city.offers.Size() : 0; }
	clearscope CW_Contract Offer(int i) { return (city && i >= 0 && i < city.offers.Size()) ? city.offers[i] : null; }
	clearscope bool IsCompleted(int i) { return false; }

	void FixSelection()
	{
		int n = OfferCount();
		selected = n ? clamp(selected, 0, n - 1) : -1;
	}
	void SelectNext() { FixSelection(); }

	// ---- the new campaign / old saves: the city is created the first time you're in the office
	void EnsureCity()
	{
		if (city) return;
		city = CW_City.Create();
		city.StartCampaign();
		selected = 0;
	}

	clearscope bool HasIntel(int i) { return ((intelMask | freeIntelMask) & (1 << i)) != 0; }
	clearscope bool HasCrew(int i) { return (crewMask & (1 << i)) != 0; }
	clearscope int CrewCount()
	{
		int n = 0;
		for (int i = 0; i < CW_Services.CREW_COUNT; i++) if (HasCrew(i)) n++;
		return n;
	}
	// ---- corp services: Candor sells intel, Northstar hires crew, Bastion Arms and Oriole Clinical stock the quartermaster
	clearscope int IntelPrice(int i)
	{
		int pct = city ? city.ServicePct("intel") : 100;
		int base = CW_Services.IntelCost(i);
		if (!pct) return city && city.MinorService("NUL") ? base * 70 / 100 : 0;   // NullSet steps in when Candor won't
		return base * pct / 100;
	}
	clearscope int CrewPrice(int i)
	{
		int pct = city ? city.ServicePct("crew") : 100;
		return CW_Services.CrewCost(i) * pct / 100;
	}
	clearscope int ShopPrice(int t)
	{
		int base = CW_Items.Price(t);
		if (!city || base <= 0) return base;
		String svc = CW_Items.Cat(t) == CW_Items.CAT_MEDICAL ? "medical" : "weapons";
		int pct = city.ServicePct(svc);
		if (city.MinorService("RUS")) pct = pct ? min(pct, 85) : 95;   // Rustline's black market
		return pct ? max(1, base * pct / 100) : 0;
	}
	clearscope int LoadoutCost()
	{
		int t = 0;
		for (int i = 0; i < CW_Services.INTEL_COUNT; i++) if ((intelMask & (1 << i)) && !(freeIntelMask & (1 << i))) t += IntelPrice(i);
		for (int i = 0; i < CW_Services.CREW_COUNT; i++) if (HasCrew(i)) t += CrewPrice(i);
		return t;
	}
	void ToggleIntel(int i)
	{
		if (missionActive || i < 0 || i >= CW_Services.INTEL_COUNT) return;
		if (!(intelMask & (1 << i)) && IntelPrice(i) <= 0) return;   // Candor won't sell to you
		intelMask ^= (1 << i);
	}
	void ToggleCrew(int i)
	{
		if (missionActive || i < 0 || i >= CW_Services.CREW_COUNT) return;
		if (!HasCrew(i) && CrewCount() >= CW_Services.MAX_CREW) return;
		if (!HasCrew(i) && CrewPrice(i) <= 0) return;                  // Northstar won't send anyone
		crewMask ^= (1 << i);
	}

	// Why the selected job can't be run right now ("" = it can).
	clearscope String DeployBlock(CW_Contract c)
	{
		if (!c) return "NO JOB SELECTED";
		if (city && city.outcome) return "CAMPAIGN OVER";
		if (c.refused.Length()) return "REFUSED";
		if (MissingKits().Length()) return "LOAD CREW KITS";
		if (budget < c.cost + LoadoutCost()) return "INSUFFICIENT BUDGET";
		return "";
	}

	void BeginMission()
	{
		FixSelection();
		let c = Offer(selected);
		if (!c) return;
		if (c.refused.Length()) { Console.MidPrint(NewSmallFont, "\cg" .. c.refused); return; }
		if (city && city.outcome) return;
		String missing = MissingKits();
		if (missing.Length())
		{
			Console.MidPrint(NewSmallFont, "\cgCrew kit not in the transport:\c- " .. missing .. "\nLoad it at the Quartermaster.");
			return;
		}
		int total = c.cost + LoadoutCost();
		if (budget < total)
		{
			Console.MidPrint(NewSmallFont, "Not enough budget to fund this operation.");
			return;
		}
		job = c;
		let op = city.FindOp(c.opId);
		if (op && c.stepIdx >= 0 && c.stepIdx < op.steps.Size()) op.steps[c.stepIdx].taken = true;
		startBudget = budget;
		missionSeed = c.seed ? c.seed : Random(1, 0x7ffffff);
		visitSeed = Random(1, 0x7ffffff);
		passMask = 0;
		arriveTower = -1;
		ApplyAccessPrep(Owner);
		bodiesFound = firstAlarmTime = 0;
		rerouted = scenarioRolled = exitRolled = false;
		scenario = -1;
		heatAtExit = 0;
		// a share of tower jobs start in the building's parking garage (or you choose it, with Intel prep)
		int pref = c.prepIntel ? entryPref : 0;
		garageRun = c.garageOk && (pref == 1 || (pref == 0 && CW_Building.Mix(visitSeed, 29) % 100 < 40));
		// prep and informants: free intel for this run
		freeIntelMask = 0;
		if (c.prepIntel) freeIntelMask |= (1 << CW_Services.INTEL_SURVEY) | (1 << CW_Services.INTEL_PATROLS);
		if (city && city.MinorService("L9") && city.MinorTurf("L9", c.district) >= 30) freeIntelMask |= 1 << CW_Services.INTEL_PATROLS;
		heatAdj = 0;
		if (city && city.MinorService("TEN") && (city.distCode[c.district] == "OQ" || city.distCode[c.district] == "IS")) heatAdj -= 8;
		if (c.alert) heatAdj += 10;
		opCost = c.cost;
		loadoutSpent = LoadoutCost();
		civKills = 0;
		budget -= total;
		hackerUses = HasCrew(CW_Services.CREW_HACKER) ? 1 : 0;
		voxUses = HasCrew(CW_Services.CREW_VOX) ? 3 : 0;
		activeContract = 0;
		missionActive = true;
		objDone = 0;
		failedMask = 0;
		fineTotal = 0;
		fineLines.Clear();
		kills = takedowns = alarms = 0;
		doorsForced = 0;
		approachNotes.Clear();
		debriefNew = false;
		String dest = garageRun ? "G05" : c.map;
		// a site-pack building opens on the map of the entry this visit uses (a roof entry starts on the roof map)
		if (!garageRun && CW_SitePool.IsSiteMap(c.map)) dest = CW_SitePool.LaunchMap(c.map, visitSeed, c.prepIntel ? entryPref : 0);
		if (!garageRun && CW_SitePool.IsSiteMap(dest) && !LevelInfo.MapExists(dest)) dest = "G02";   // the pack is not loaded
		level.ChangeLevel(dest, 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}

	// Access prep (a keycard / copied pass from an odd job): you start holding the pass for the floor that
	// holds the primary objective. Neutral sites have no maglocks.
	void ApplyAccessPrep(Actor pm)
	{
		if (!job || !job.prepAccess || job.neutral) return;
		int floors = CW_Building.Floors(self);
		int k = OBJ_STEAL;
		for (int i = OBJ_STEAL; i <= OBJ_TURN; i++) if (job.IsPrimary(i)) { k = i; break; }
		passMask |= 1 << CW_Building.ObjFloor(missionSeed, floors, job, k);
		if (pm && !pm.FindInventory("CW_SecurityPass")) pm.GiveInventory("CW_SecurityPass", 1);
	}

	// Safety net: Meridian never lets the desk go dark. If the budget can't cover the cheapest job, it advances
	// enough to run it plus a modest loadout; the advance is repaid from half of later payouts. Past the limit,
	// Meridian calls the loan: your office is taken and the campaign is lost.
	// Returns the amount advanced (0 = none needed).
	int EnsureSolvent()
	{
		int cheapest = 1 << 30;
		for (int i = 0; i < OfferCount(); i++) { let c = Offer(i); if (c && !c.refused.Length()) cheapest = min(cheapest, c.cost); }
		if (cheapest == (1 << 30)) cheapest = 300;
		if (budget >= cheapest) return 0;
		int adv = cheapest + 800 - budget;
		if (debt + adv > MERIDIAN_LIMIT)
		{
			if (city) city.Lose("You defaulted on Meridian. The office, the desk and the phone are theirs now.");
			return 0;
		}
		budget += adv;
		debt += adv;
		return adv;
	}

	void AddFine(String reason, int amount)
	{
		if (!missionActive || amount <= 0) return;
		fineTotal += amount;
		fineLines.Push(String.Format("%s\t\cr-%s", reason, CW_Handler.Money(amount)));
		Console.MidPrint(NewSmallFont, String.Format("\crCONTRACT VIOLATION\n\c-%s  \cr-%s", reason, CW_Handler.Money(amount)));
		S_StartSound("misc/keytry", CHAN_AUTO, CHANF_UI);
	}

	void FailObjective(int k, String why)
	{
		if (!missionActive || (objDone & (1 << k))) return;
		failedMask |= (1 << k);
		let c = job;
		Console.Printf("\crObjective failed: %s (%s)", c ? c.ObjName(k) : CW_Contract.KindName(k), why);
	}

	void CompleteObjective(int k)
	{
		objDone |= (1 << k);
		let c = job;
		if (c && missionActive && c.pay[k] <= 0 && c.penalty[k] > 0)
		{
			AddFine("Unauthorized " .. CW_Contract.KindTag(k).MakeLower(), c.penalty[k]);
			return;
		}
		String msg = c ? c.ObjName(k) : CW_Contract.KindName(k);
		if (c && missionActive && c.pay[k] > 0)
			msg = String.Format("%s\n\cd%s%s", msg, CW_Handler.Money(c.pay[k]), c.IsPrimary(k) ? "" : " bonus");
		else
			msg = msg .. "\n\cr(not part of the contract)";
		Console.MidPrint(NewSmallFont, msg);
	}

	clearscope bool PrimaryDone()
	{
		let c = job;
		return c && (objDone & c.primaryMask) != 0;
	}

	// Debrief rows: "#TITLE" = section header, "a\tb" = label / right-aligned value,
	// "@" = start the right-hand column, anything else = plain line.
	void FinishMission(bool success)
	{
		let c = job;
		heatAtExit = Heat();
		debrief.Clear();
		int payout = 0;
		Array<String> impact, overnight;
		if (c)
		{
			debrief.Push(String.Format("DEBRIEF: %s%s", c.title, city ? String.Format("   (day %d)", city.day) : ""));
			debrief.Push(success ? "\cdJob complete." : "\crMission aborted. Operation costs are lost.");

			// ---- earnings
			debrief.Push("#EARNINGS");
			if (success)
			{
				int best = 0, bestK = 0;
				for (int k = 1; k <= 3; k++)
					if ((objDone & (1 << k)) && c.pay[k] > 0 && c.IsPrimary(k) && c.pay[k] > best) { best = c.pay[k]; bestK = k; }
				if (bestK) debrief.Push(String.Format("%s\t\cd+%s", c.ObjName(bestK), CW_Handler.Money(best)));
				payout = best;
				for (int k = 1; k <= 3; k++)
				{
					if (!(objDone & (1 << k)) || c.pay[k] <= 0 || c.IsPrimary(k)) continue;
					payout += c.pay[k];
					debrief.Push(String.Format("%s (bonus)\t\cd+%s", c.ObjName(k), CW_Handler.Money(c.pay[k])));
				}
				double mult = 1.0;
				if (alarms == 0) { mult += 0.25; debrief.Push("Ghost: never spotted\t\cd+25%"); }
				else
				{
					double pen = min(0.5, alarms * 0.1);
					mult -= pen;
					debrief.Push(String.Format("Spotted %d time(s)\t\cr-%d%%", alarms, int(pen * 100 + 0.5)));
				}
				if (kills == 0) { mult += 0.15; debrief.Push("No guard casualties\t\cd+15%"); }
				payout = int(payout * mult);
			}
			else debrief.Push("No payout for an aborted job\t\cr$0");
			debrief.Push(String.Format("\cfPayout\t\cf%s", CW_Handler.Money(payout)));

			// ---- rules of engagement
			debrief.Push("#RULES OF ENGAGEMENT");
			if (fineLines.Size() == 0) debrief.Push("\cdNo violations. The client is satisfied.");
			for (int i = 0; i < fineLines.Size(); i++) debrief.Push(fineLines[i]);
			if (fineTotal) debrief.Push(String.Format("\crFines\t\cr-%s", CW_Handler.Money(fineTotal)));

			// ---- the city: what this run did, then the day closes (one job per day)
			if (city)
			{
				city.ApplyJob(c, success && PrimaryDone(), objDone, heatAtExit, kills, alarms, impact);
				debrief.Push("#CITY IMPACT");
				for (int i = 0; i < impact.Size(); i++) debrief.Push(impact[i]);
				city.AdvanceDay();
				for (int i = 0; i < city.todayNews.Size() && i < 4; i++) overnight.Push(city.todayNews[i]);
				if (city.todayNews.Size() > 4) overnight.Push(String.Format("\cu(%d more on the NEWS tab)", city.todayNews.Size() - 4));
			}

			// ---- right column
			debrief.Push("@");
			debrief.Push("#FIELD REPORT");
			for (int i = 0; i < approachNotes.Size(); i++) debrief.Push("Way in: " .. approachNotes[i]);
			debrief.Push(String.Format("Alarms raised\t%s%d", alarms ? "\cr" : "\cd", alarms));
			if (doorsForced) debrief.Push(String.Format("Doors breached\t\cr%d", doorsForced));
			debrief.Push(String.Format("Guards killed\t%s%d", kills ? "\cr" : "\cd", kills));
			debrief.Push(String.Format("Takedowns\t%d", takedowns));
			debrief.Push(String.Format("Heat at exit\t%s%d", heatAtExit >= 45 ? "\cr" : "\cd", heatAtExit));
			if (scenario >= 0) debrief.Push(String.Format("Extraction\t%s", CW_GarageGen.ScenarioName(scenario)));
			else if (garageRun) debrief.Push("Extraction\tgarage");
			debrief.Push(String.Format("Civilian casualties\t%s%d", civKills ? "\cr" : "\cd", civKills));
			for (int k = 1; k <= 3; k++)
				if (failedMask & (1 << k)) debrief.Push(String.Format("\cr%s\t\crFAILED", c.ObjName(k)));

			// ---- account
			int bonus = CollectBonus(null);
			int repay = min(debt, (payout + bonus) / 2);
			debt -= repay;
			budget += payout + bonus - fineTotal - repay;
			int net = payout + bonus - fineTotal - opCost - loadoutSpent;
			debrief.Push("#ACCOUNT");
			debrief.Push(String.Format("Budget before\t%s", CW_Handler.Money(startBudget)));
			debrief.Push(String.Format("Operation cost\t\cr-%s", CW_Handler.Money(opCost)));
			if (loadoutSpent) debrief.Push(String.Format("Intel & crew\t\cr-%s", CW_Handler.Money(loadoutSpent)));
			debrief.Push(String.Format("Payout\t\cd+%s", CW_Handler.Money(payout)));
			if (bonus) debrief.Push(String.Format("Operation bonuses\t\cd+%s", CW_Handler.Money(bonus)));
			if (fineTotal) debrief.Push(String.Format("Fines\t\cr-%s", CW_Handler.Money(fineTotal)));
			debrief.Push(String.Format("Net\t%s%s", net >= 0 ? "\cd+" : "\cr", CW_Handler.Money(net)));
			if (repay) debrief.Push(String.Format("Meridian advance repaid\t\cr-%s", CW_Handler.Money(repay)));
			int adv = EnsureSolvent();
			if (adv) debrief.Push(String.Format("\ckMeridian advance\t\ck+%s", CW_Handler.Money(adv)));
			debrief.Push(String.Format("\cfBudget now\t\cf%s", CW_Handler.Money(budget)));
			if (debt) debrief.Push(String.Format("Owed to Meridian\t\cr%s", CW_Handler.Money(debt)));
			if (overnight.Size())
			{
				debrief.Push(String.Format("#OVERNIGHT: DAY %d", city.day));
				for (int i = 0; i < overnight.Size(); i++) debrief.Push(overnight[i]);
			}
		}
		intelMask = crewMask = freeIntelMask = 0;
		hackerUses = voxUses = 0;
		heatAdj = 0;
		missionActive = false;
		activeContract = -1;
		job = null;
		debriefNew = true;
		FixSelection();
		level.ChangeLevel("HUB01", 0, CHANGELEVEL_NOINTERMISSION | CHANGELEVEL_RESETHEALTH);
	}

	// operation-success bonuses the city owes you (freelancers finished work you started)
	int CollectBonus(Array<String> lines)
	{
		if (!city) return 0;
		int b = city.pendingBonus;
		city.pendingBonus = 0;
		if (lines) for (int i = 0; i < city.pendingLines.Size(); i++) lines.Push(city.pendingLines[i]);
		city.pendingLines.Clear();
		return b;
	}

	// Close the day without taking a job: the city moves on.
	void CloseDay()
	{
		if (missionActive || !city || city.outcome) return;
		city.AdvanceDay();
		debrief.Clear();
		debrief.Push(String.Format("DAY %d", city.day));
		debrief.Push("\cjYou kept your head down. The city didn't.");
		debrief.Push("#OVERNIGHT");
		for (int i = 0; i < city.todayNews.Size(); i++) debrief.Push(city.todayNews[i]);
		debrief.Push("@");
		debrief.Push("#ACCOUNT");
		Array<String> bl;
		int bonus = CollectBonus(bl);
		for (int i = 0; i < bl.Size(); i++) debrief.Push(bl[i]);
		if (bonus)
		{
			int repay = min(debt, bonus / 2);
			debt -= repay;
			budget += bonus - repay;
			if (repay) debrief.Push(String.Format("Meridian advance repaid\t\cr-%s", CW_Handler.Money(repay)));
		}
		int adv = EnsureSolvent();
		if (adv) debrief.Push(String.Format("\ckMeridian advance\t\ck+%s", CW_Handler.Money(adv)));
		debrief.Push(String.Format("\cfBudget\t\cf%s", CW_Handler.Money(budget)));
		if (debt) debrief.Push(String.Format("Owed to Meridian\t\cr%s", CW_Handler.Money(debt)));
		if (city.outcome) debrief.Push(String.Format("%s\t%s", city.outcome == 1 ? "\cdCAMPAIGN WON" : "\crCAMPAIGN LOST", ""));
		debriefNew = true;
		FixSelection();
	}
}
