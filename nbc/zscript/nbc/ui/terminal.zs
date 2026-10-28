// The precinct terminal (PLAN.md M7c): one screen, four tabs.
//   BOARD     the case: the districts, who holds them, a dossier; open a case, plan a raid, close the day
//   SQUAD     the roster as people: portraits, rank, XP, stats, perks; promote, recruit, dismiss
//   ARMORY    the Evidence Locker: everything seized and issued; sell it, or requisition supplies
//   MEMORIAL  the officers lost in the line of duty
// The raid board in the hub opens it on BOARD, the lockers on ARMORY (NBC_RunManager.menuTab).

class NBC_Terminal : NBC_UI
{
	enum ETab { TAB_BOARD, TAB_SQUAD, TAB_ARMORY, TAB_MEMORIAL, TAB_COUNT }
	enum EId
	{
		ID_TAB = 1, ID_CLOSE, ID_DISTRICT, ID_PLAN, ID_NEWCASE, ID_ENDDAY,
		ID_OFFICER, ID_PROMOTE, ID_SQUAD, ID_DISMISS, ID_RECRUIT, ID_RECRUIT_CLASS, ID_PERK,
		ID_ITEM, ID_SELL, ID_BUY, ID_YES, ID_NO, ID_SCROLL
	}
	enum EPopup { POP_NONE, POP_PROMOTE, POP_RECRUIT, POP_DISMISS, POP_ENDDAY, POP_NEWCASE }

	int tab, popup;
	int selDistrict, selOfficer, selItem, memScroll;

	static const String TAB_NAME[] = { "RAID BOARD", "SQUAD ROOM", "EVIDENCE LOCKER", "MEMORIAL" };

	// officer: an officer id to open the squad room on (an officer in the HQ was talked to), 0 = none
	static void Open(int tab, int officer = 0)
	{
		Menu.SetMenu("NBC_Terminal");
		let t = NBC_Terminal(GetCurrentMenu());
		if (!t) return;
		let dept = NBC_Department.Find();
		if (dept && officer)
			for (int i = 0; i < dept.roster.Size(); i++) if (dept.roster[i].id == officer) t.selOfficer = i;
		t.SetTab(tab);
	}

	override void Init(Menu parent)
	{
		Super.Init(parent);
		selItem = NBC_Cat.IT_COLT;
	}

	void SetTab(int t)
	{
		tab = clamp(t, 0, TAB_COUNT - 1);
		popup = POP_NONE;
		focusSet = false;
		// start on the first thing worth doing
		let rd = NBC_RunData.Find();
		if (tab == TAB_BOARD && !(rd && rd.caseActive)) { focusId = ID_NEWCASE; focusArg = 0; focusSet = true; }
		else if (tab == TAB_BOARD)
		{
			// the first district you can raid
			let rm = RM();
			if (rm && !CanRaid(selDistrict))
				for (int d = 0; d < rm.districtMaps.Size(); d++) if (CanRaid(d)) { selDistrict = d; break; }
			focusId = ID_DISTRICT; focusArg = selDistrict; focusSet = true;
		}
		else if (tab == TAB_SQUAD) { focusId = ID_OFFICER; focusArg = selOfficer; focusSet = true; }
		else if (tab == TAB_ARMORY) { focusId = ID_ITEM; focusArg = selItem; focusSet = true; }
	}

	override void SwitchTab(int dir)
	{
		if (popup != POP_NONE) return;
		SetTab((tab + dir + TAB_COUNT) % TAB_COUNT);
		MenuSound("menu/change");
	}

	override bool Back()
	{
		if (popup != POP_NONE) { popup = POP_NONE; return true; }
		return false;
	}

	override void Scroll(int dir)
	{
		if (tab == TAB_MEMORIAL) memScroll = max(0, memScroll + dir);
	}

	// ------------------------------------------------------------ actions

	override void Activate(int id, int arg)
	{
		let rd = NBC_RunData.Find();
		let dept = NBC_Department.Find();
		switch (id)
		{
		case ID_TAB: SetTab(arg); return;
		case ID_CLOSE: Leave(); return;
		case ID_NO: popup = POP_NONE; return;
		case ID_DISTRICT:
			selDistrict = arg;
			Activate(ID_PLAN, 0);
			return;
		case ID_PLAN:
			if (CanRaid(selDistrict)) NBC_DeployMenu.Open(self, selDistrict);
			return;
		case ID_NEWCASE: popup = POP_NEWCASE; focusId = ID_YES; focusArg = 0; return;
		case ID_ENDDAY: popup = POP_ENDDAY; focusId = ID_NO; focusArg = 0; return;
		case ID_YES:
			if (popup == POP_NEWCASE) { EventHandler.SendNetworkEvent("nbc_board", -1); selDistrict = 0; FocusLater(ID_DISTRICT, 0); }
			else if (popup == POP_ENDDAY) EventHandler.SendNetworkEvent("nbc_board", -2);
			else if (popup == POP_DISMISS)
			{
				let o = CurOfficer();
				if (o) Send(NBC_Department.OP_DISMISS, o.id);
				selOfficer = max(0, selOfficer - 1);
			}
			popup = POP_NONE;
			return;
		case ID_OFFICER: selOfficer = arg; return;
		case ID_SQUAD:
		{
			let o = CurOfficer();
			if (o) Send(NBC_Department.OP_SQUAD_TOGGLE, o.id);
			return;
		}
		case ID_PROMOTE:
		{
			let o = CurOfficer();
			if (o && o.CanPromote()) { popup = POP_PROMOTE; focusId = ID_PERK; focusArg = 0; }
			return;
		}
		case ID_PERK:
		{
			let o = CurOfficer();
			if (o && o.CanPromote()) Send(NBC_Department.OP_PROMOTE, o.id, arg);
			popup = POP_NONE;
			return;
		}
		case ID_DISMISS:
			if (CurOfficer() && dept && dept.roster.Size() > 1) { popup = POP_DISMISS; focusId = ID_NO; focusArg = 0; }
			return;
		case ID_RECRUIT: popup = POP_RECRUIT; focusId = ID_RECRUIT_CLASS; focusArg = 0; return;
		case ID_RECRUIT_CLASS:
			if (rd && rd.caseActive && rd.cash >= NBC_Cat.CLASS_PRICE[arg] && dept && dept.roster.Size() < 16)
			{
				Send(NBC_Department.OP_RECRUIT, arg);
				selOfficer = dept.roster.Size();
				popup = POP_NONE;
			}
			return;
		case ID_ITEM: selItem = arg; return;
		case ID_SELL: Send(NBC_Department.OP_SELL, 0, selItem); return;
		case ID_BUY: Send(NBC_Department.OP_BUY, 0, selItem); return;
		}
	}

	bool CanRaid(int d)
	{
		let rd = NBC_RunData.Find();
		let rm = RM();
		return rd && rm && rd.caseActive && !rd.raidActive && d >= 0 && d < rm.districtMaps.Size()
			&& rm.DistrictGang(rd, d) && !rm.DistrictTaken(rd, d);
	}

	NBC_Officer CurOfficer()
	{
		let dept = NBC_Department.Find();
		if (!dept || !dept.roster.Size()) return null;
		selOfficer = clamp(selOfficer, 0, dept.roster.Size() - 1);
		return dept.roster[selOfficer];
	}

	// ------------------------------------------------------------ drawing

	override void DrawScreen()
	{
		Backdrop();
		registering = popup == POP_NONE;
		TopBar("CHECKPOINT 9", "PRECINCT TERMINAL  -  NEW BRICKS CITY POLICE");

		// tabs
		double tx = 16;
		for (int i = 0; i < TAB_COUNT; i++)
		{
			double w = 196;
			bool on = tab == i;
			bool f = IsFocus(ID_TAB, i) && registering;
			Fill(tx, 64, w, 34, on ? C_PANEL : 0x141C26);
			Fill(tx, 64, w, 2, on ? C_AMBER : C_PANEL_HI);
			Text(BigFont, on ? Font.CR_GOLD : (f ? Font.CR_WHITE : Font.CR_GRAY), tx + w / 2, 75, TAB_NAME[i], 12, 1);
			Region(ID_TAB, i, tx, 64, w, 34);
			if (f) FocusFrame(tx, 64, w, 34);
			tx += w + 6;
		}
		Button(ID_CLOSE, 0, VW - 16 - 100, 64, 100, 34, "CLOSE", true, 13);

		switch (tab)
		{
		case TAB_BOARD: DrawBoard(); break;
		case TAB_SQUAD: DrawSquad(); break;
		case TAB_ARMORY: DrawArmory(); break;
		case TAB_MEMORIAL: DrawMemorial(); break;
		}
		Hints("ARROWS / MOUSE  select     ENTER / CLICK  use     Q / E  switch tabs     ESC  back");

		registering = true;
		switch (popup)
		{
		case POP_PROMOTE: DrawPromote(); break;
		case POP_RECRUIT: DrawRecruit(); break;
		case POP_DISMISS:
		{
			let o = CurOfficer();
			Confirm("DISMISS", o ? String.Format("Turn in %s's badge? %s leaves the department; the kit goes back in the locker.",
				o.RankedName(), o.FullName()) : "");
			break;
		}
		case POP_ENDDAY: Confirm("CLOSE THE DAY", "No raid today. A day passes on the case clock: the squad rests and heals, the gangs cool off."); break;
		case POP_NEWCASE:
		{
			let rd = NBC_RunData.Find();
			Confirm("OPEN A NEW CASE", rd && rd.caseActive ? "Abandon this case? The Bricks reshuffles, the locker goes back to issue. Your officers stay."
				: "A new Bricks: the gangs dealt across the districts, 30 days to topple them all, three strikes and Internal Affairs takes your badge.");
			break;
		}
		}
	}

	// a yes/no box
	void Confirm(String title, String text)
	{
		Fill(0, 0, VW, VH, 0, 0.6);
		double w = 520, h = 200, x = (VW - w) / 2, y = 190;
		Panel(x, y, w, h, title);
		Wrap(NewSmallFont, Font.CR_WHITE, x + 24, y + 48, w - 48, text, 12, 5);
		Button(ID_YES, 0, x + w - 24 - 300, y + h - 56, 140, 36, "CONFIRM", true, 15, C_AMBER);
		Button(ID_NO, 0, x + w - 24 - 140, y + h - 56, 140, 36, "CANCEL", true, 15);
	}

	// ------------------------------------------------------------ BOARD

	void DrawBoard()
	{
		let rd = NBC_RunData.Find();
		let rm = RM();
		if (!rm) return;
		if (!rd || !rd.caseActive)
		{
			double w = 600, x = (VW - w) / 2;
			Panel(x, 150, w, 300, "NO OPEN CASE");
			String last = "";
			if (rd && rd.caseResult == NBC_CASE_WON) last = "Last case: CLOSED. Every gang in the Bricks went down.";
			else if (rd && rd.caseResult == NBC_CASE_STRUCK_OUT) last = "Last case: three strikes. Internal Affairs pulled the badge.";
			else if (rd && rd.caseResult == NBC_CASE_DEMOLITION) last = "Last case: out of time. The demolition crews rolled in.";
			double y = 200;
			if (last != "") { Text(NewSmallFont, Font.CR_GOLD, x + 24, y, last, 13); y += 30; }
			y += Wrap(NewSmallFont, Font.CR_WHITE, x + 24, y, w - 48,
				"The Bricks is walled off and the gangs run it block by block. A case gives you 30 days to topple every gang: "
				.. "raid a district, take down the gang's leader, get out. Three officers down and Internal Affairs ends it.", 12, 5);
			// the department you'd take into it
			let dept = NBC_Department.Find();
			if (dept && dept.roster.Size())
			{
				y = max(y + 10, 286);
				Text(NewSmallFont, Font.CR_GRAY, x + 24, y, String.Format("YOUR OFFICERS  (%d)", dept.roster.Size()), 10);
				for (int i = 0; i < dept.roster.Size() && i < 10; i++)
				{
					let o = dept.roster[i];
					Inset(x + 24 + i * 55, y + 14, 50, 50);
					Pic(o.Portrait(), x + 26 + i * 55, y + 16, 46, 46);
				}
			}
			Button(ID_NEWCASE, 0, x + w / 2 - 130, 380, 260, 44, "OPEN A NEW CASE", true, 17, C_AMBER);
			return;
		}

		// the districts
		Panel(16, 108, 452, 440, "DISTRICTS");
		int n = rm.districtMaps.Size();
		double rowH = min(48, 390.0 / max(1, n));
		if (focusId == ID_DISTRICT) selDistrict = focusArg;
		for (int d = 0; d < n; d++)
		{
			double y = 140 + d * rowH;
			let g = rm.DistrictGang(rd, d);
			bool down = rm.DistrictTaken(rd, d);
			bool f = IsFocus(ID_DISTRICT, d) && registering;
			Inset(28, y, 428, rowH - 6, selDistrict == d ? C_AMBER_DIM : -1);
			Fill(28, y, 6, rowH - 6, g ? (down ? C_GREY : C_RED) : C_PANEL);
			Text(BigFont, down ? Font.CR_DARKGRAY : (f ? Font.CR_GOLD : Font.CR_WHITE), 44, y + 5, rm.TurfTitle(d).MakeUpper(), 14);
			Text(NewSmallFont, Font.CR_GRAY, 44, y + 23, EnvName(rm.TurfEnv(d)), 10);
			if (g)
			{
				Text(NewSmallFont, down ? Font.CR_DARKGRAY : g.TextColor(), 448, y + 6, g.name, 11, 2);
				if (down) Text(BigFont, Font.CR_GREEN, 448, y + 22, "TAKEN", 11, 2);
				else
				{
					int gi = rd.districtGang[d];
					int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
					for (int a = 0; a < 3; a++) Fill(448 - 10 - a * 12, y + 25, 9, 9, a < alert ? C_RED : C_PANEL_HI);
					Text(NewSmallFont, Font.CR_DARKGRAY, 448 - 44, y + 24, "ALERT", 9, 2);
				}
			}
			Region(ID_DISTRICT, d, 28, y, 428, rowH - 6);
			if (f) FocusFrame(28, y, 428, rowH - 6);
		}

		// the dossier
		double x = 480, w = VW - 16 - x;
		Panel(x, 108, w, 440, "DOSSIER");
		int d = clamp(selDistrict, 0, max(0, n - 1));
		let g = rm.DistrictGang(rd, d);
		Text(BigFont, Font.CR_WHITE, x + 20, 140, rm.TurfTitle(d).MakeUpper(), 22);
		Text(NewSmallFont, Font.CR_GRAY, x + 20, 168, EnvName(rm.TurfEnv(d)) .. "  -  " .. EnvLine(rm.TurfEnv(d)), 11);
		if (g)
		{
			bool down = rm.DistrictTaken(rd, d);
			int gi = rd.districtGang[d];
			int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
			double y = 196;
			Inset(x + 20, y, w - 40, 150);
			Text(BigFont, g.TextColor(), x + 34, y + 10, g.name.MakeUpper(), 17);
			Text(NewSmallFont, Font.CR_GRAY, x + 34, y + 34, String.Format("Leader:  %s", g.leaderTitle), 12);
			Text(NewSmallFont, Font.CR_GRAY, x + 34, y + 52, String.Format("Threat:  tier %d     Alert: %d of 3", g.tier, alert), 12);
			Text(NewSmallFont, Font.CR_GRAY, x + 34, y + 70, String.Format("On the block:  about %d", rm.CrewEstimate(rd, d)), 12);
			Text(NewSmallFont, Font.CR_GRAY, x + 34, y + 88, String.Format("Bounty on the leader:  %s", NBC_Cat.Money(300 * g.tier)), 12);
			Wrap(NewSmallFont, Font.CR_WHITE, x + 34, y + 110, w - 68, g.trait, 11, 3);
			// what works on them (gangs.txt damage factors)
			if (g.damageTypes.Size())
			{
				Text(NewSmallFont, Font.CR_GRAY, x + 20, y + 162, "WHAT WORKS ON THEM", 10);
				double px = x + 20;
				for (int i = 0; i < g.damageTypes.Size(); i++)
				{
					double fac = g.damageFactors[i];
					String lbl = fac <= 0 ? DamageName(g.damageTypes[i]) .. ": immune" : String.Format("%s x%.1f", DamageName(g.damageTypes[i]), fac);
					double tw = TextWidth(NewSmallFont, lbl, 11) + 16;
					Fill(px, y + 176, tw, 20, fac > 1.0 ? 0x2E4A2A : (fac < 1.0 ? 0x4A2A2A : C_PLATE));
					Text(NewSmallFont, fac > 1.0 ? Font.CR_GREEN : (fac < 1.0 ? Font.CR_RED : Font.CR_WHITE), px + 8, y + 180, lbl, 11);
					px += tw + 6;
				}
			}
			if (down)
			{
				Stamp(x + w / 2, 432, "TOPPLED", C_GREEN, 26);
			}
		}
		else Text(NewSmallFont, Font.CR_DARKGRAY, x + 20, 200, "Nobody holds this block.", 12);

		let dept = NBC_Department.Find();
		int ready = 0;
		if (dept) for (int i = 0; i < dept.roster.Size(); i++) if (dept.roster[i].Available()) ready++;
		Text(NewSmallFont, Font.CR_GRAY, x + 20, 466, String.Format("Squad: %d picked, %d of %d officers fit for duty.",
			dept ? dept.squad.Size() : 0, ready, dept ? dept.roster.Size() : 0), 11);
		Button(ID_PLAN, 0, x + w - 20 - 190, 486, 190, 46, "PLAN RAID", CanRaid(d), 19, C_AMBER);
		Button(ID_ENDDAY, 0, x + 20, 486, 140, 46, "CLOSE THE DAY", !rd.raidActive, 11);
		Button(ID_NEWCASE, 0, x + 168, 486, 90, 46, "NEW CASE", true, 11);
	}

	static String DamageName(Name t)
	{
		if (t == 'NBC_Light') return "Light rounds";
		if (t == 'NBC_Shell') return "Buckshot";
		if (t == 'NBC_Rifle') return "Rifle";
		if (t == 'Fire') return "Fire";
		if (t == 'Blunt') return "Thrown";
		if (t == 'Melee') return "Blades";
		return String.Format("%s", t);
	}

	static String EnvName(String env)
	{
		if (env ~== "rooftops") return "ROOFTOPS";
		if (env ~== "underground") return "UNDERGROUND";
		if (env ~== "industrial") return "INDUSTRIAL PARK";
		if (env ~== "subway") return "SUBWAY";
		if (env ~== "parks") return "PARK";
		if (env ~== "towers") return "HOUSING TOWERS";
		return "STREETS";
	}
	static String EnvLine(String env)
	{
		if (env ~== "rooftops") return "water towers, stairheads, long sightlines";
		if (env ~== "underground") return "storm drains and boiler rooms, tight and dark";
		if (env ~== "industrial") return "yards, sheds and loading docks";
		if (env ~== "subway") return "platforms and tunnels";
		if (env ~== "parks") return "open ground, little cover";
		if (env ~== "towers") return "brick high-rises, room to room";
		return "walk-ups, stoops and alleys";
	}

	// ------------------------------------------------------------ SQUAD

	void DrawSquad()
	{
		let dept = NBC_Department.Find();
		let rd = NBC_RunData.Find();
		if (!dept) return;
		if (focusId == ID_OFFICER) selOfficer = focusArg;
		let sel = CurOfficer();

		// the roster: four across
		Panel(16, 108, 548, 440, "ROSTER");
		Text(NewSmallFont, Font.CR_GRAY, 548, 118, String.Format("%d / 16 officers", dept.roster.Size()), 11, 2);
		double cw = 122, ch = 98;
		for (int i = 0; i < dept.roster.Size(); i++)
		{
			double x = 30 + (i % 4) * (cw + 8), y = 142 + (i / 4) * (ch + 6);
			let o = dept.roster[i];
			OfficerCard(ID_OFFICER, i, x, y, cw, ch, o, selOfficer == i);
			if (dept.InSquad(o.id)) { Fill(x + cw - 22, y + ch - 30, 18, 14, C_AMBER); Text(BigFont, Font.CR_BLACK, x + cw - 13, y + ch - 29, "S", 12, 1); }
		}
		bool canHire = rd && rd.caseActive && dept.roster.Size() < 16;
		Button(ID_RECRUIT, 0, 30, 500, 200, 36, "RECRUIT", canHire, 15, C_GREEN);
		if (!(rd && rd.caseActive)) Text(NewSmallFont, Font.CR_DARKGRAY, 244, 512, "Recruiting needs an open case (cash).", 10);

		// the file on the selected officer
		double x = 576, w = VW - 16 - x;
		Panel(x, 108, w, 440, "SERVICE FILE");
		if (!sel) return;
		Inset(x + 18, 140, 112, 112);
		Pic(sel.Portrait(), x + 22, 144, 104, 104, 1.0, sel.state == NBC_Officer.ST_HOSPITAL);
		Text(BigFont, Font.CR_WHITE, x + 144, 142, sel.FullName().MakeUpper(), 18);
		Text(BigFont, Font.CR_GOLD, x + 144, 166, String.Format("%s  %s", sel.RankName().MakeUpper(), sel.ClassName().MakeUpper()), 13);
		Wrap(NewSmallFont, Font.CR_GRAY, x + 144, 186, w - 160, NBC_Cat.CLASS_ROLE[sel.cls], 10, 2);
		// XP to the next rank
		String xpl = sel.rank < NBC_Cat.MAX_RANK ? String.Format("XP %d / %d", sel.xp, sel.NextXP()) : String.Format("XP %d  (top rank)", sel.xp);
		Text(NewSmallFont, Font.CR_WHITE, x + 144, 222, xpl, 11);
		double prev = NBC_Cat.RANK_XP[sel.rank];
		double frac = sel.rank < NBC_Cat.MAX_RANK ? (sel.xp - prev) / max(1.0, sel.NextXP() - prev) : 1.0;
		Bar(x + 144, 238, w - 162, 14, frac, sel.CanPromote() ? C_GREEN : C_BLUE, 12);

		// stats
		double y = 266;
		StatRow(x + 18, y, w - 36, "HEALTH", String.Format("%d / %d", sel.health, sel.MaxHealth())); y += 24;
		StatRow(x + 18, y, w - 36, "AIM", String.Format("%d", sel.Aim())); y += 24;
		StatRow(x + 18, y, w - 36, "RAIDS  /  KILLS", String.Format("%d  /  %d", sel.raids, sel.kills)); y += 24;
		StatRow(x + 18, y, w - 36, "PRIMARY", sel.PrimaryName()); y += 24;
		String status = sel.state == NBC_Officer.ST_HOSPITAL ? String.Format("Hospital, %d day%s", sel.hospital, sel.hospital == 1 ? "" : "s")
			: (dept.InSquad(sel.id) ? "Fit, in the squad" : "Fit for duty");
		StatRow(x + 18, y, w - 36, "STATUS", status); y += 30;
		Text(NewSmallFont, Font.CR_GRAY, x + 18, y, "PERKS", 10); y += 14;
		if (!sel.perks.Size()) { Text(NewSmallFont, Font.CR_DARKGRAY, x + 18, y, "None yet: promotions bring one each.", 10); y += 14; }
		for (int i = 0; i < sel.perks.Size(); i++)
		{
			int p = sel.perks[i];
			Text(NewSmallFont, Font.CR_GOLD, x + 18, y, NBC_Cat.PERK_NAME[p], 11);
			Text(NewSmallFont, Font.CR_GRAY, x + 160, y, NBC_Cat.PERK_DESC[p], 10);
			y += 14;
		}

		Button(ID_PROMOTE, 0, x + 18, 500, 120, 36, "PROMOTE", sel.CanPromote(), 14, C_GREEN);
		Button(ID_SQUAD, 0, x + 146, 500, 120, 36, dept.InSquad(sel.id) ? "BENCH" : "TO SQUAD",
			dept.InSquad(sel.id) || (sel.Available() && dept.squad.Size() < NBC_Cat.SQUAD_SLOTS), 14, C_AMBER);
		Button(ID_DISMISS, 0, x + w - 18 - 96, 500, 96, 36, "DISMISS", dept.roster.Size() > 1, 13, C_RED);
	}

	void StatRow(double x, double y, double w, String label, String value)
	{
		Fill(x, y, w, 20, C_INSET, 0.8);
		Text(NewSmallFont, Font.CR_GRAY, x + 8, y + 4, label, 11);
		Text(NewSmallFont, Font.CR_GOLD, x + w - 8, y + 4, value, 11, 2);
	}

	void DrawPromote()
	{
		let o = CurOfficer();
		if (!o) { popup = POP_NONE; return; }
		Fill(0, 0, VW, VH, 0, 0.6);
		double w = 640, h = 280, x = (VW - w) / 2, y = 150;
		Panel(x, y, w, h, "PROMOTION");
		int nr = min(o.rank + 1, NBC_Cat.MAX_RANK);
		Text(NewSmallFont, Font.CR_WHITE, x + 24, y + 42, String.Format("%s to %s. Pick one:", o.FullName(), NBC_Cat.RANK_NAME[nr]), 13);
		for (int c = 0; c < 2; c++)
		{
			int p = NBC_Cat.PerkChoice(o.cls, nr, c);
			double bx = x + 24 + c * 302, by = y + 72;
			bool f = IsFocus(ID_PERK, c);
			Inset(bx, by, 288, 140, f ? C_AMBER : -1);
			Text(BigFont, f ? Font.CR_GOLD : Font.CR_WHITE, bx + 144, by + 16, NBC_Cat.PERK_NAME[p].MakeUpper(), 16, 1);
			Wrap(NewSmallFont, Font.CR_GRAY, bx + 16, by + 50, 256, NBC_Cat.PERK_DESC[p], 12, 4);
			if (o.HasPerk(p)) Text(NewSmallFont, Font.CR_DARKGRAY, bx + 144, by + 112, "(already has it: stacks)", 10, 1);
			Region(ID_PERK, c, bx, by, 288, 140);
			if (f) FocusFrame(bx, by, 288, 140);
		}
		Button(ID_NO, 0, x + w - 24 - 120, y + h - 50, 120, 34, "LATER", true, 13);
	}

	void DrawRecruit()
	{
		let rd = NBC_RunData.Find();
		let dept = NBC_Department.Find();
		Fill(0, 0, VW, VH, 0, 0.6);
		double w = 860, h = 330, x = (VW - w) / 2, y = 130;
		Panel(x, y, w, h, "RECRUIT");
		Text(NewSmallFont, Font.CR_GRAY, x + w - 20, y + 12, String.Format("Cash %s", NBC_Cat.Money(rd ? rd.cash : 0)), 12, 2);
		for (int c = 0; c < NBC_Cat.C_COUNT; c++)
		{
			double bx = x + 20 + c * 207, by = y + 46;
			bool afford = rd && rd.caseActive && rd.cash >= NBC_Cat.CLASS_PRICE[c] && dept && dept.roster.Size() < 16;
			bool f = IsFocus(ID_RECRUIT_CLASS, c);
			Inset(bx, by, 195, 220, f ? C_AMBER : -1);
			Pic(NBC_Cat.Face(c * 31 + 5), bx + 57, by + 10, 80, 80, afford ? 1.0 : 0.4, !afford);
			Text(BigFont, f ? Font.CR_GOLD : Font.CR_WHITE, bx + 97, by + 96, NBC_Cat.CLASS_NAME[c].MakeUpper(), 15, 1);
			Text(NewSmallFont, Font.CR_GRAY, bx + 97, by + 116, String.Format("%s  -  %d HP  -  aim %d", NBC_Cat.CLASS_ISSUE[c],
				NBC_Cat.CLASS_HP[c], NBC_Cat.CLASS_AIM[c]), 9, 1);
			Wrap(NewSmallFont, Font.CR_WHITE, bx + 12, by + 136, 171, NBC_Cat.CLASS_ROLE[c], 10, 3);
			MoneyText(afford ? Font.CR_GOLD : Font.CR_RED, bx + 97, by + 192, NBC_Cat.CLASS_PRICE[c], 17, 1);
			Region(ID_RECRUIT_CLASS, c, bx, by, 195, 220);
			if (f) FocusFrame(bx, by, 195, 220);
		}
		Button(ID_NO, 0, x + w - 20 - 120, y + h - 50, 120, 34, "CANCEL", true, 13);
	}

	// ------------------------------------------------------------ ARMORY

	void DrawArmory()
	{
		let dept = NBC_Department.Find();
		let rd = NBC_RunData.Find();
		if (!dept) return;
		if (focusId == ID_ITEM) selItem = focusArg;

		Panel(16, 108, 600, 440, "EVIDENCE LOCKER");
		Text(NewSmallFont, Font.CR_GRAY, 600, 118, "seized and issued, ready for the next raid", 10, 2);
		static const String groups[] = { "WEAPONS", "AMMUNITION", "GEAR" };
		static const int groupStart[] = { 0, 7, 10 };
		static const int groupEnd[] = { 7, 10, 13 };
		double y = 140;
		for (int g = 0; g < 3; g++)
		{
			Text(BigFont, Font.CR_GRAY, 30, y, groups[g], 12);
			y += 18;
			int col = 0;
			for (int i = groupStart[g]; i < groupEnd[g]; i++)
			{
				double tx = 30 + col * 82;
				int have = dept.locker[i];
				String count = NBC_Cat.ITEM_UNIT[i] > 1 ? String.Format("%d", have) : String.Format("x%d", have);
				Tile(ID_ITEM, i, tx, y, 76, 76, NBC_Cat.ITEM_ICON[i], NBC_Cat.ItemName(i), count, have > 0 || CheckedOut(dept, i) > 0, selItem == i);
				col++;
			}
			y += 88;
		}

		// the item
		double x = 628, w = VW - 16 - x;
		Panel(x, 108, w, 440, "ITEM");
		int it = clamp(selItem, 0, NBC_Cat.IT_COUNT - 1);
		Inset(x + 18, 140, w - 36, 120);
		Pic(NBC_Cat.ITEM_ICON[it], x + 30, 150, w - 60, 100);
		Text(BigFont, Font.CR_WHITE, x + 18, 272, NBC_Cat.ItemName(it).MakeUpper(), 18);
		double yy = 298 + Wrap(NewSmallFont, Font.CR_GRAY, x + 18, 298, w - 36, NBC_Cat.ITEM_DESC[it], 11, 3);
		yy += 6;
		bool ammo = NBC_Cat.ITEM_UNIT[it] > 1;
		StatRow(x + 18, yy, w - 36, "IN THE LOCKER", ammo ? String.Format("%d rounds", dept.locker[it]) : String.Format("%d", dept.locker[it])); yy += 24;
		StatRow(x + 18, yy, w - 36, "CHECKED OUT (KITS)", String.Format("%d", CheckedOut(dept, it))); yy += 24;
		String unit = ammo ? String.Format(" / %d", NBC_Cat.ITEM_UNIT[it]) : "";
		StatRow(x + 18, yy, w - 36, "FENCE VALUE", NBC_Cat.Money(NBC_Cat.ITEM_SELL[it]) .. unit); yy += 24;
		StatRow(x + 18, yy, w - 36, "REQUISITION", NBC_Cat.ITEM_BUY[it] > 0 ? NBC_Cat.Money(NBC_Cat.ITEM_BUY[it]) .. unit : "not issued");

		bool open = rd && rd.caseActive;
		Button(ID_SELL, 0, x + 18, 500, (w - 46) / 2, 36, ammo ? String.Format("SELL %d", NBC_Cat.ITEM_UNIT[it]) : "SELL",
			open && dept.locker[it] >= NBC_Cat.ITEM_UNIT[it], 14, C_RED);
		Button(ID_BUY, 0, x + 28 + (w - 46) / 2, 500, (w - 46) / 2, 36, ammo ? String.Format("BUY %d", NBC_Cat.ITEM_UNIT[it]) : "BUY",
			open && NBC_Cat.ITEM_BUY[it] > 0 && rd.cash >= NBC_Cat.ITEM_BUY[it], 14, C_GREEN);
	}

	// how many of an item sit in kits (yours and the officers')
	static int CheckedOut(NBC_Department dept, int it)
	{
		int n = (dept.pPrimary == it ? 1 : 0) + (dept.pSidearm == it ? 1 : 0) + (dept.pMelee == it ? 1 : 0);
		if (it == NBC_Cat.IT_VEST && dept.pVest) n++;
		for (int k = 0; k < dept.pPouch.Size(); k++) if (dept.pPouch[k] == it) n++;
		for (int i = 0; i < dept.roster.Size(); i++)
		{
			let o = dept.roster[i];
			if (o.kitPrimary == it) n++;
			if (it == NBC_Cat.IT_VEST && o.kitVest) n++;
			for (int k = 0; k < o.kitPouch.Size(); k++) if (o.kitPouch[k] == it) n++;
		}
		return n;
	}

	// ------------------------------------------------------------ MEMORIAL

	void DrawMemorial()
	{
		let dept = NBC_Department.Find();
		Panel(16, 108, VW - 32, 440, "IN THE LINE OF DUTY");
		if (!dept || !dept.fallen.Size())
		{
			Text(NewSmallFont, Font.CR_GRAY, VW / 2, 300, "No names on the wall. Keep it that way.", 14, 1);
			return;
		}
		int per = 8;
		memScroll = clamp(memScroll, 0, max(0, dept.fallen.Size() - per));
		for (int i = 0; i < per && memScroll + i < dept.fallen.Size(); i++)
		{
			let o = dept.fallen[dept.fallen.Size() - 1 - memScroll - i];
			double y = 142 + i * 48;
			Inset(30, y, VW - 60, 42);
			Pic(o.Portrait(), 36, y + 3, 36, 36, 0.8, true);
			Text(BigFont, Font.CR_WHITE, 86, y + 6, String.Format("%s %s", NBC_Cat.RANK_NAME[clamp(o.rank, 0, 3)], o.FullName()).MakeUpper(), 14);
			Text(NewSmallFont, Font.CR_GRAY, 86, y + 25, String.Format("%s, %d raid%s", o.ClassName(), o.raids, o.raids == 1 ? "" : "s"), 10);
			Text(NewSmallFont, Font.CR_GRAY, VW - 44, y + 14, String.Format("Day %d, %s", o.diedDay, o.diedWhere), 12, 2);
		}
		if (dept.fallen.Size() > per)
			Text(NewSmallFont, Font.CR_DARKGRAY, VW - 32, 530, "wheel / page up / page down to scroll", 10, 2);
	}
}
