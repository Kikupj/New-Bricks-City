// =============================================================================
// Corpo Wars — the city layer meets the mission loop.
//   BuildOffers: every open step of every running operation becomes a job on the terminal (CW_Contract).
//   MakeContract: a step -> objectives, pay, rules of engagement, security and prep; the map is a site kit
//   (K01-K06, SiteKit) where one fits the place, else the G02 office floor.
//   ApplyJob: after the mission, what your run did to the city (debrief CITY IMPACT).
//   Services: corp and minor-player services priced by your standing (factions-draft.md, campaign doc).
// =============================================================================

extend class CW_City
{
	Array<CW_Contract> offers;

	// ================================================================ the job board
	void BuildOffers()
	{
		offers.Clear();
		if (outcome) return;
		for (int i = 0; i < ops.Size(); i++)
		{
			let op = ops[i];
			if (op.state) continue;
			// a client who's Hostile to you doesn't call
			if (EffRep(op.client) <= -50) continue;
			for (int k = 0; k < op.steps.Size(); k++)
			{
				let st = op.steps[k];
				if (st.done) continue;
				let c = MakeContract(op, k);
				if (c) offers.Push(c);
			}
		}
		// your patron's work first, then contracts before odd jobs, soonest deadline first
		for (int a = 1; a < offers.Size(); a++)
		{
			let x = offers[a];
			int b = a - 1;
			while (b >= 0 && OfferKey(offers[b]) > OfferKey(x)) { offers[b + 1] = offers[b]; b--; }
			offers[b + 1] = x;
		}
	}
	int OfferKey(CW_Contract c)
	{
		int k = c.deadline * 10 + (c.decisive ? 0 : 5);
		if (c.refused.Length()) k += 100000;
		if (patron >= 0 && c.clientF == patron) k -= 50000;
		return k;
	}

	clearscope String ClientLabel(CWC_Op op)
	{
		if (op.launcher >= 0)
		{
			let sb = subs[op.launcher];
			if (!op.clientKnown) return sb.name .. " (?)";
			return String.Format("%s (%s)", sb.name, FactionShort(op.client));
		}
		return FactionName(op.client);
	}

	// The site kit and variant for a job's location, as kit * 16 + variant (0 = the G02 office floor).
	// Kit and variant numbers follow CW_KitGen.EKit and each kit's EVar.
	int SiteKit(CWC_Step st, CW_Contract c)
	{
		if (st.role == R_CONTRACT && st.prop >= 0)
		{
			switch (props[st.prop].type)
			{
			case PT_DC:   return 6 * 16 + 0;
			case PT_LAB:  return 6 * 16 + 1;
			case PT_FARM: return 4 * 16 + 4;
			case PT_BNK:  return 4 * 16 + 5;
			case PT_WH:   return 3 * 16 + 0;
			case PT_DOCK: return 3 * 16 + 1;
			case PT_FAB:  return 3 * 16 + 2;
			case PT_PLT:  return 3 * 16 + 3;
			case PT_SUB:  return 3 * 16 + 4;
			case PT_PARK: return 3 * 16 + 5;
			case PT_SAL:  return 3 * 16 + 6;
			}
			return 0;   // offices, HQs, clinics, studios, training centres, R&D: the office floor generator
		}
		if (st.role == R_CONTRACT && st.stronghold >= 0)
		{
			String n = holds[st.stronghold].name;
			if (n.IndexOf("drug lab") >= 0) return 1 * 16 + 5;
			if (n.IndexOf("bar") >= 0) return 1 * 16 + 0;
			if (n.IndexOf(" den") >= 0) return 2 * 16 + 4;
			if (n.IndexOf("union") >= 0) return 5 * 16 + 0;
			if (n.IndexOf("meeting hall") >= 0) return 5 * 16 + 1;
			if (n.IndexOf("church") >= 0) return 5 * 16 + 2;
			return 0;
		}
		switch (st.site)
		{
		case NS_BAR:          return 1 * 16 + 0;
		case NS_RESTAURANT:   return 1 * 16 + 1;
		case NS_PAWN:         return 1 * 16 + 2;
		case NS_MARKET:       return 1 * 16 + 3;
		case NS_MALL:         return 1 * 16 + 4;
		case NS_DRUGLAB:      return 1 * 16 + 5;
		case NS_CHOPSHOP:     return 1 * 16 + 6;
		case NS_GAMBLING:     return 1 * 16 + 7;
		case NS_TENEMENT:     return 2 * 16 + 0;
		case NS_APARTMENTS:   return 2 * 16 + 1;
		case NS_LUXURY:       return 2 * 16 + 2;
		case NS_HOTEL:        return 2 * 16 + 3;
		case NS_ROOFTOPS:     return 2 * 16 + 5;
		case NS_CONSTRUCTION: return 3 * 16 + 7;
		case NS_TUNNELS:      return 4 * 16 + 0;
		case NS_UNDERPASS:    return 4 * 16 + 1;
		case NS_TRANSIT:      return 4 * 16 + 2;
		case NS_PARKING:      return 4 * 16 + 3;
		case NS_UNIONHALL:    return 5 * 16 + 0;
		case NS_UNIVERSITY:   return 5 * 16 + 3;
		case NS_HOSPITAL:     return 5 * 16 + 4;
		case NS_ARCHIVE:      return 5 * 16 + 5;
		}
		return 0;
	}

	// How big the site is (CW_ObsSite.ETier): properties by type (and their value), neutral sites mostly small.
	int SiteTier(CWC_Step st)
	{
		if (st.role == R_CONTRACT && st.prop >= 0)
		{
			let pr = props[st.prop];
			int t;
			switch (pr.type)
			{
			case PT_SUB:  t = CW_ObsSite.TIER_S; break;
			case PT_WH: case PT_SAL: t = CW_ObsSite.TIER_M; break;
			case PT_DOCK: case PT_FAB: case PT_PLT: case PT_PARK: t = CW_ObsSite.TIER_L; break;
			default: t = CW_ObsSite.TIER_M; break;
			}
			// a small-earning site of a big type is a smaller lot
			if (t == CW_ObsSite.TIER_L && TypeYield(pr.type) >= 0 && PropYield(st.prop) < TypeYield(pr.type)) t = CW_ObsSite.TIER_M;
			return t;
		}
		if (st.role == R_CONTRACT && st.stronghold >= 0) return CW_ObsSite.TIER_M;
		return (st.seed & 3) == 0 ? CW_ObsSite.TIER_M : CW_ObsSite.TIER_S;
	}

	CW_Contract MakeContract(CWC_Op op, int k)
	{
		let st = op.steps[k];
		let c = new("CW_Contract");
		c.theme = -1;
		c.map = "G02";
		c.repeatable = true;
		c.opId = op.id; c.stepIdx = k; c.role = st.role; c.decisive = st.decisive;
		c.clientF = op.client; c.targetF = op.tFaction;
		c.clientHidden = !op.clientKnown;
		c.client = ClientLabel(op);
		c.deadline = op.deadline; c.progress = op.progress;
		c.opTitle = op.linkKnown || st.decisive ? op.title : "? (you haven't linked this job to an operation)";
		c.execIdx = st.role == R_CONTRACT ? op.tExec : -1;
		c.prop = st.prop; c.hold = st.stronghold; c.site = st.site; c.district = st.district;
		c.seed = st.seed;
		int pay = st.pay;
		int tf = op.tFaction;

		// ---- patron conflicts: work against your patron or its allies is refused (or is betrayal through a shell)
		if (patron >= 0 && op.clientKnown && op.client != patron && (tf == patron || (IsCorp(tf) && GetRel(patron, tf) >= 50)))
			c.refused = String.Format("Refused: this hurts %s, your patron%s.", corps[patron].short, tf == patron ? "" : "'s ally");
		if (patron >= 0 && op.client == patron) pay = pay * 125 / 100;
		if (Tier(EffRep(op.client)) == -1) pay = pay * 90 / 100;

		bool lev = StepDone(op, R_LEVERAGE);
		bool weak = StepDone(op, R_WEAKEN);
		c.prepIntel = StepDone(op, R_INTEL);
		c.prepAccess = StepDone(op, R_ACCESS);
		c.prepWeaken = weak;
		c.prepLeverage = lev;
		for (int i = 0; i < op.steps.Size(); i++)
		{
			int r = op.steps[i].role;
			if (r == R_INTEL) c.hasIntelStep = true;
			if (r == R_ACCESS) c.hasAccessStep = true;
			if (r == R_WEAKEN) c.hasWeakenStep = true;
			if (r == R_LEVERAGE) c.hasLeverageStep = true;
		}

		// ---- where, how guarded, how big
		bool strike = st.role == R_CONTRACT;
		if (strike && st.prop >= 0)
		{
			let pr = props[st.prop];
			int owner = PropCorp(st.prop);
			c.target = PropName(st.prop);
			c.where = String.Format("%s, %s", TypeName(pr.type), distName[pr.district]);
			c.secForce = PropForce(st.prop) - (weak ? 3 : 0);
			c.secTech = PropTech(st.prop) - (weak ? 1 : 0);
			if (owner >= 0 && day < corps[owner].alertUntil) { c.secForce += 1; c.alert = true; }
			c.floors = clamp(TypeFloors(pr.type, pr.seed), 1, 3);
			c.theme = TypeTheme(pr.type, owner >= 0 ? corps[owner].theme : 0);
			c.garageOk = HasGarage(st.prop);
			c.secKnown = c.prepIntel || IntelFresh(pr.secKnownDay);
		}
		else if (strike && st.stronghold >= 0)
		{
			let hd = holds[st.stronghold];
			let m = minors[hd.minor];
			c.target = String.Format("%s (%s stronghold)", hd.name, m.short);
			c.where = String.Format("%s stronghold, %s", m.short, distName[hd.district]);
			c.secForce = 6 + m.turf[hd.district] / 15 - (weak ? 2 : 0);
			c.secTech = 1 + (hd.seed & 1);
			c.floors = 1;
			c.theme = m.code == "NUL" ? 3 : (m.code == "L9" ? 0 : (m.code == "TEN" ? 1 : 4));
			c.neutral = true;
			c.secKnown = c.prepIntel;
		}
		else
		{
			// odd job at a neutral site: generated fresh, light security, no maglocks or passes
			c.target = String.Format("%s %s in %s", SiteArticle(st.site), SiteName(st.site), distName[st.district]);
			c.where = String.Format("%s, %s", SiteName(st.site), distName[st.district]);
			c.secForce = 5 + (st.seed % 3);
			for (int m = 0; m < minors.Size(); m++) if (!minors[m].dormant && minors[m].turf[st.district] >= 50) c.secForce++;
			c.secTech = 1 + ((st.seed >> 4) & 1);
			c.floors = 1;
			c.theme = SiteTheme(st.site);
			c.neutral = true;
			c.secKnown = true;
		}

		// ---- which map: a site kit where one fits the place, else the G02 office fallback
		int kv = SiteKit(st, c);
		if (kv > 0 && CVar.FindCVar("cw_kitsites").GetBool())
		{
			// Obsidian's map pool first (the launcher keeps it stocked), else the in-engine kit
			String pm = "";
			String pool = CW_ObsSite.PoolOfKit(kv / 16);
			if (pool.Length() && CVar.FindCVar("cw_obsidian").GetBool()) pm = CW_ObsSite.PoolMap(pool, c.seed, SiteTier(st));
			c.map = pm.Length() ? pm : CW_KitGen.MapOfKit(kv / 16);
			c.kitVariant = kv % 16;
			c.floors = 1;
			c.garageOk = false;
		}
		// After Hours site pack: a generated layout where the pack has one for this kind of place (the layout seed
		// picks the pool variant; offices stay on G02 until their pools exist: CW_SitePool.OfficeCode)
		if (kv == 0 || CVar.FindCVar("cw_kitsites").GetBool())
		{
			int ptype = (st.role == R_CONTRACT && st.prop >= 0) ? props[st.prop].type : -1;
			String sm = CW_SitePool.MapFor(kv / 16, kv % 16, ptype, c.seed);
			if (sm.Length())
			{
				c.map = sm;
				c.kitVariant = 0;
				c.floors = 1;
				c.garageOk = false;
			}
		}
		c.secForce = clamp(c.secForce, 3, 16);
		c.secTech = clamp(c.secTech, 1, 4);
		c.risk = RiskOf(c.secForce, c.secTech);
		c.cost = strike ? 150 + c.risk * 150 + (c.floors - 1) * 50 : 100;
		if (lev && strike) pay = pay * 115 / 100;

		// ---- objectives
		SetObjectives(c, op, st, pay);

		// ---- rules of engagement from the client's ethics
		if (IsCorp(op.client))
		{
			int e = corps[op.client].ethics;
			if (e >= 4) { c.protectCivilians = true; c.civFine = 1500; c.guardFine = 300; }
			else if (e == 3) { c.protectCivilians = true; c.civFine = 1200; }
			else if (e == 2) { c.protectCivilians = true; c.civFine = 800; }
			else c.civFine = 1000;
		}
		else
		{
			String mc = minors[op.client - MINOR_BASE].code;
			if (mc == "L9") { c.protectCivilians = true; c.civFine = 1000; c.guardFine = 300; }
			else if (mc == "NUL") { c.protectCivilians = true; c.civFine = 1000; }
			else if (mc == "TEN") { c.protectCivilians = true; c.civFine = 1500; c.guardFine = 500; }
			else c.civFine = 1000;
		}

		if (c.stealItem.Length() == 0) c.stealItem = "the package";
		if (c.turnName.Length() == 0) c.turnName = "the contact";
		c.title = c.objText[FirstPrimary(c)];
		c.brief = Brief(c, op, st);
		return c;
	}

	static int FirstPrimary(CW_Contract c)
	{
		for (int k = OBJ_STEAL; k <= OBJ_TURN; k++) if (c.IsPrimary(k)) return k;
		return OBJ_STEAL;
	}

	void SetObjectives(CW_Contract c, CWC_Op op, CWC_Step st, int pay)
	{
		int wSab = IsCorp(op.client) ? corps[op.client].wSab : 2;
		String exName = op.tExec >= 0 ? execs[op.tExec].name : "";
		if (st.role != R_CONTRACT)
		{
			switch (st.mode)
			{
			case 1: Obj(c, OBJ_STEAL, "Photograph " .. st.what, pay, true); c.stealItem = st.what; c.stealMode = 1; break;
			case 2: Obj(c, OBJ_STEAL, "Plant " .. st.what, pay, true); c.stealItem = st.what; c.stealMode = 2; break;
			case 3: Obj(c, OBJ_DESTROY, "Wreck " .. st.what, pay, true); break;
			case 4: Obj(c, OBJ_TURN, "Lean on " .. st.what, pay, true); c.turnName = st.what; c.turnMode = 1; break;
			default: Obj(c, OBJ_STEAL, "Steal " .. st.what, pay, true); c.stealItem = st.what; break;
			}
			return;
		}
		String item = st.what.Length() ? st.what : "the " .. StealNoun(op.tProp);
		switch (op.goal)
		{
		case G_STEAL:
			Obj(c, OBJ_STEAL, (op.agendaKind == AG_EXPOSE ? "Take " : "Steal ") .. item, pay, true);
			c.stealItem = item;
			if (wSab >= 2) Obj(c, OBJ_DESTROY, "Wreck the servers (fallback)", pay * 45 / 100, true);
			else if (wSab == 0) c.penalty[OBJ_DESTROY] = pay / 4;
			if (op.tProp >= 0 && ExecAt(op.tProp) >= 0) { int e = ExecAt(op.tProp); Obj(c, OBJ_TURN, "Turn " .. execs[e].name, pay / 4, false); c.turnName = execs[e].name; }
			break;
		case G_SABOTAGE:
			Obj(c, OBJ_DESTROY, "Destroy the site's control server", pay, true);
			Obj(c, OBJ_STEAL, "Take the " .. StealNoun(op.tProp), pay * 30 / 100, false);
			c.stealItem = "the " .. StealNoun(op.tProp);
			break;
		case G_RECRUIT:
		{
			String who = exName.Length() ? exName : "the lead engineer";
			Obj(c, OBJ_TURN, (c.prepLeverage ? "Bring out " : "Extract ") .. who, pay, true);
			c.turnName = who; c.turnMode = c.prepLeverage ? 3 : 2;
			Obj(c, OBJ_STEAL, "Steal the " .. StealNoun(op.tProp), pay * 30 / 100, false);
			c.stealItem = "the " .. StealNoun(op.tProp);
			if (wSab <= 1) c.penalty[OBJ_DESTROY] = pay / 4;
			break;
		}
		case G_STRIKE:
			Obj(c, OBJ_DESTROY, "Shut down the site's control server", pay, true);
			break;
		case G_RAID:
			Obj(c, OBJ_DESTROY, "Trash the site's control server", pay, true);
			Obj(c, OBJ_STEAL, "Grab the " .. StealNoun(op.tProp), pay / 3, false);
			c.stealItem = "the " .. StealNoun(op.tProp);
			break;
		case G_LEAK:
			Obj(c, OBJ_STEAL, "Copy the " .. StealNoun(op.tProp), pay, true);
			c.stealItem = "the " .. StealNoun(op.tProp);
			break;
		case G_PROTEST:
			Obj(c, OBJ_STEAL, "Plant the inspectors' evidence", pay, true);
			c.stealItem = "the inspectors' evidence"; c.stealMode = 2;
			break;
		case G_EXTORT:
			Obj(c, OBJ_TURN, "Lean on the site manager", pay, true);
			c.turnName = "the site manager"; c.turnMode = 1;
			break;
		case G_SUPPRESS:
		{
			let m = minors[holds[op.tStronghold].minor];
			static const String assets[] = { "the stash ledger", "the strike-fund ledger", "the crew's drives", "the association's files" };
			int ai = clamp(FindMinor(m.code), 0, 3);
			Obj(c, OBJ_STEAL, "Steal " .. assets[ai], pay, true);
			c.stealItem = assets[ai];
			if (exName.Length()) { Obj(c, OBJ_TURN, "Extract " .. exName, pay * 110 / 100, true); c.turnName = exName; c.turnMode = 2; }
			break;
		}
		}
	}
	static void Obj(CW_Contract c, int k, String text, int pay, bool primary)
	{
		c.objText[k] = text;
		c.pay[k] = max(100, pay / 100 * 100);
		if (primary) c.primaryMask |= 1 << k;
	}

	String Brief(CW_Contract c, CWC_Op op, CWC_Step st)
	{
		String s;
		if (st.role == R_CONTRACT)
		{
			s = String.Format("%s wants to %s at %s.", c.client, GoalPhrase(op), c.where);
			if (op.tProp >= 0)
			{
				int owner = PropCorp(op.tProp);
				s = s .. String.Format(" %s belongs to %s.", PropName(op.tProp), owner >= 0 ? SubOwnerLabel(props[op.tProp].sub) : "Meridian");
			}
			if (c.execIdx >= 0 && !execs[c.execIdx].gone)
				s = s .. String.Format(" %s works here%s.", execs[c.execIdx].name, c.prepIntel || execs[c.execIdx].locKnown ? "" : " (unconfirmed)");
			s = s .. " " .. EffectLine(op);
			if (c.alert) s = s .. " Their sites are on alert after a recent hot job.";
			if (c.floors > 1) s = s .. String.Format(" The job spans %d floors; primaries are never on the floor you enter.", c.floors);
		}
		else
		{
			s = String.Format("Odd job at %s. %s", c.target, op.goal == G_COUNTER ? "Defensive work: find out who hired the crew and make the strike harder." : RoleDesc(st.role));
			s = s .. (op.linkKnown ? String.Format(" Part of: %s.", op.title) : " Which operation it serves: unknown.");
			s = s .. " Small site: light security, no maglocks, plenty of bystanders.";
		}
		return s;
	}

	clearscope String EffectLine(CWC_Op op)
	{
		String owner = op.tProp >= 0 && PropCorp(op.tProp) >= 0 ? corps[PropCorp(op.tProp)].short : "the owner";
		switch (op.goal)
		{
		case G_STEAL:    return String.Format("If it lands, %s loses a quarter of the site's income for a week and the client gains it.", owner);
		case G_SABOTAGE: return "If it lands, the site is wrecked: half its income until repaired.";
		case G_RECRUIT:  return op.tExec >= 0 ? String.Format("If it lands, %s changes sides and %s loses the bonus.", execs[op.tExec].name, owner) : "If it lands, the site loses its best engineer.";
		case G_STRIKE:   return "If it lands, the site stops for five days.";
		case G_RAID:     return "If it lands, the site is damaged and the crew gets richer.";
		case G_LEAK:     return "If it lands, a scandal: the site's income drops and any shell behind it is exposed.";
		case G_PROTEST:  return "If it lands, a blockade: security costs balloon for days.";
		case G_EXTORT:   return "If it lands, the owner pays protection.";
		case G_SUPPRESS: return "If it lands, the group loses ground in the district.";
		}
		return "";
	}

	// ================================================================ after the mission
	// success = the job's primary objective was done and you got out.
	void ApplyJob(CW_Contract j, bool success, int objDone, int heat, int kills, int alarms, Array<String> outL)
	{
		let op = FindOp(j.opId);
		if (!op || j.stepIdx < 0 || j.stepIdx >= op.steps.Size())
		{
			outL.Push("The operation was already over. Nobody noticed.");
			return;
		}
		let st = op.steps[j.stepIdx];
		st.taken = false;
		int cf = j.clientF, tf = j.targetF;
		int newsMark = todayNews.Size();
		if (success && op.state == 0 && !st.done)
		{
			st.done = 1;
			op.playerSteps++;
			op.linkKnown = true;
			if (st.decisive)
			{
				jobsDone++;
				OpSucceeded(op, true, j.prepLeverage);
				outL.Push("\cdOperation complete:\c- " .. op.title);
				for (int i = newsMark; i < todayNews.Size(); i++) outL.Push(todayNews[i]);
			}
			else
			{
				oddJobsDone++;
				int gain = st.role == R_PROGRESS ? 30 : 15;
				op.progress = min(95, op.progress + gain);
				outL.Push(String.Format("Progress on the operation\t\cd+%d%%", gain));
				outL.Push("\cj" .. op.title);
				switch (st.role)
				{
				case R_INTEL:
					if (op.tProp >= 0) props[op.tProp].secKnownDay = day;
					if (op.tExec >= 0) execs[op.tExec].locKnown = true;
					outL.Push("Intel: the strike's security and target are known; you choose the entry.");
					break;
				case R_ACCESS: outL.Push("Access: you'll start the strike holding a pass."); break;
				case R_WEAKEN: outL.Push("Weaken: fewer guards and lower tech on the strike."); break;
				case R_LEVERAGE: outL.Push("Leverage: the target will co-operate; the client pays more."); break;
				}
				if (op.counterOf >= 0 && st.decisive == false && st.role == R_INTEL) { op.clientKnown = true; }
			}
			AddRep(cf, st.decisive ? 8 : 3);
			outL.Push(String.Format("Standing with %s\t\cd+%d (%s)", FactionShort(cf), st.decisive ? 8 : 3, TierName(GetRep(cf))));
			// documents from a theft: the owner's books, maybe a shell's real parent
			if ((objDone & (1 << OBJ_STEAL)) && st.decisive && op.tProp >= 0 && IsCorp(tf))
			{
				corps[tf].finKnownDay = day;
				outL.Push(String.Format("Documents: %s's books are open to you for a week.", corps[tf].short));
				if (Random[CWSim](0, 99) < 50) RevealShell(tf, outL);
			}
		}
		else if (!success)
		{
			AddRep(cf, -3);
			outL.Push(String.Format("%s is disappointed\t\cr-3", FactionShort(cf)));
			if (st.decisive)
			{
				op.progress = max(0, op.progress - 10);
				if (op.tProp >= 0) props[op.tProp].alertUntil = day + 3;
				outL.Push("The target is warier now.");
			}
		}

		// ---- were you identified? (heat carries into the corp layer)
		int idChance = heat >= 50 ? 100 : max(0, (heat - 25) * 3);
		bool identified = Random[CWSim](0, 99) < idChance;
		if (IsCorp(tf) && corps[tf].alive)
		{
			if (identified)
			{
				int d = st.decisive ? -15 : -6;
				AddRep(tf, d);
				outL.Push(String.Format("\crIdentified.\c- %s knows it was you\t\cr%d (%s)", corps[tf].short, d, TierName(GetRep(tf))));
				for (int k = 0; k < NCORP; k++)
				{
					if (k == tf || !corps[k].alive) continue;
					if (GetRel(k, tf) >= 50) AddRep(k, -4);
					else if (GetRel(k, tf) <= -50) AddRep(k, 3);
				}
				if (!op.clientKnown && Random[CWSim](0, 1)) { op.clientKnown = true; outL.Push("They traced the job back to your client, too."); }
				if (op.clientKnown && IsCorp(cf)) AddRel(tf, cf, -6);
			}
			if (heat > 50)
			{
				corps[tf].alertUntil = day + 3;
				outL.Push(String.Format("%s's sites are on alert for the next two days.", corps[tf].short));
			}
		}
		else if (IsMinor(tf) && success)
		{
			int d = st.decisive ? -10 : -4;
			AddRep(tf, d);
			outL.Push(String.Format("%s knows who hit them\t\cr%d (%s)", FactionShort(tf), d, TierName(GetRep(tf))));
		}
		if ((kills >= 3 || alarms >= 3) && st.decisive && op.tProp >= 0)
		{
			props[op.tProp].hardenUntil = day + 7;
			props[op.tProp].hardenForce = max(props[op.tProp].hardenForce, 2);
			outL.Push("A loud run: security there is being stepped up.");
		}
		// ---- betrayal: a job through a shell you hadn't uncovered, against your patron's side
		if (success && patron >= 0 && j.clientHidden && (tf == patron || (IsCorp(tf) && GetRel(patron, tf) >= 50)))
		{
			int p0 = patron;
			Betray(p0);
			outL.Push(String.Format("\crBETRAYAL:\c- the client was working against %s. The pledge is over.", corps[p0].short));
		}
	}

	void RevealShell(int corp, Array<String> outL)
	{
		Array<int> hid;
		for (int s = 0; s < subs.Size(); s++) if (subs[s].shell && !subs[s].shellKnown && (corp < 0 || subs[s].corp == corp)) hid.Push(s);
		if (!hid.Size()) return;
		int s = hid[Random[CWSim](0, hid.Size() - 1)];
		subs[s].shellKnown = true;
		for (int i = 0; i < ops.Size(); i++) if (ops[i].launcher == s) ops[i].clientKnown = true;
		outL.Push(String.Format("\cdShell uncovered:\c- %s belongs to %s.", subs[s].name, subs[s].corp >= 0 ? corps[subs[s].corp].short : "Meridian"));
	}

	// ================================================================ services (priced by standing)
	// Which corp runs a service subsidiary right now (-1 = in receivership / nobody).
	clearscope int ServiceCorp(String svc)
	{
		for (int s = 0; s < subs.Size(); s++) if (subs[s].service == svc) return subs[s].corp >= 0 && corps[subs[s].corp].alive ? subs[s].corp : -1;
		return -1;
	}
	clearscope String ServiceSub(String svc)
	{
		for (int s = 0; s < subs.Size(); s++) if (subs[s].service == svc) return subs[s].name;
		return "?";
	}
	// price multiplier in percent; 0 = unavailable
	clearscope int ServicePct(String svc)
	{
		int c = ServiceCorp(svc);
		if (c < 0) return 0;
		int t = Tier(EffRep(c));
		int pct = t == 2 ? 75 : t == 1 ? 90 : t == 0 ? 100 : t == -1 ? 125 : 0;
		if (pct && c == patron) pct = pct * 80 / 100;
		return pct;
	}
	// minor-player service open to you? (Friendly or better, and not dormant)
	clearscope bool MinorService(String code)
	{
		for (int m = 0; m < minors.Size(); m++)
			if (minors[m].code == code) return !minors[m].dormant && GetRep(MINOR_BASE + m) >= 25;
		return false;
	}
	clearscope int MinorTurf(String code, int d)
	{
		for (int m = 0; m < minors.Size(); m++) if (minors[m].code == code) return minors[m].dormant ? 0 : minors[m].turf[d];
		return 0;
	}

	// Corp financials, agendas, exact relations for a week; maybe a shell. Candor sells it; NullSet cheaper.
	clearscope int CorpIntelCost()
	{
		int pct = ServicePct("intel");
		int cost = pct ? 600 * pct / 100 : 0;
		if (MinorService("NUL")) cost = cost ? min(cost, 300) : 300;
		return cost;
	}
	void BuyCorpIntel(int c, Array<String> outL)
	{
		if (!IsCorp(c)) return;
		corps[c].finKnownDay = day;
		for (int m = 0; m < minors.Size(); m++) minors[m].turfKnownDay = max(minors[m].turfKnownDay, day - 3);
		RevealShell(c, outL);
		// who's behind the operations against this corp's sites
		for (int i = 0; i < ops.Size(); i++) if (ops[i].state == 0 && ops[i].tFaction == c && Random[CWSim](0, 1)) ops[i].clientKnown = true;
		for (int e = 0; e < execs.Size(); e++) if (execs[e].corp == c && execs[e].minor < 0) execs[e].locKnown = true;
		BuildOffers();
	}
}
