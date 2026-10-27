// =============================================================================
// Corpo Wars — the broker's terminal (full-screen menu)
// UI only: every change is sent to play code as a network event.
// Tabs: OPERATIONS (the job board) | INTEL | CREW | CITY | MARKET | LEDGER | NEWS
// =============================================================================
// Shared drawing helpers for Corpo Wars full-screen menus.
class CW_UiMenu : GenericMenu
{
	double btnX, btnY, btnW, btnH;
	CW_Ledger Ledger() { return CW_Ledger.Of(players[consoleplayer].mo); }
	CW_Handler Hnd() { return CW_Handler(EventHandler.Find("CW_Handler")); }

	// ------------------------------------------------------------------ drawing helpers
	double s;
	bool dry;   // measuring pass: lay out, draw nothing (used to shrink text until a section fits)
	void Txt(double x, double y, String t, int col)
	{
		if (dry) return;
		if (t.Left(1) == "$") t = "\c-" .. t;   // a leading $ would be read as a string-table lookup
		Screen.DrawText(NewSmallFont, col, x, y, t, DTA_ScaleX, s, DTA_ScaleY, s);
	}
	// t cut down with "..." so it fits in w
	String Fit(String t, double w)
	{
		if (TW(t) <= w) return t;
		int n = t.CodePointCount();
		while (n > 1 && TW(t.Left(n) .. "...") > w) n--;   // (byte-wise; the terminal text is ASCII)
		return t.Left(n) .. "...";
	}
	double TW(String t) { return NewSmallFont.StringWidth(t) * s; }
	double LH() { return NewSmallFont.GetHeight() * s * 1.35; }
	void Box(double x, double y, double w, double h, Color c, double a = 1.0) { if (!dry) Screen.Dim(c, a, int(x), int(y), int(w), int(h)); }

	// Draws wrapped text inside width w; returns the y below it.
	double Wrapped(double x, double y, double w, String t, int col)
	{
		Array<String> paras;
		t.Split(paras, "\n");
		for (int p = 0; p < paras.Size(); p++)
		{
			BrokenLines bl = NewSmallFont.BreakLines(paras[p], int(w / s));
			for (int i = 0; i < bl.Count(); i++) { Txt(x, y, bl.StringAt(i), col); y += LH(); }
		}
		return y;
	}

	// Label on the left, value right-aligned: never overflows the column.
	double KV(double x, double y, double w, String k, String v, int kc, int vc)
	{
		v = Fit(v, w * 0.72);
		Txt(x, y, Fit(k, max(w - TW(v) - 12 * s, w * 0.25)), kc);
		Txt(x + w - TW(v), y, v, vc);
		return y + LH();
	}
}

class CW_TerminalMenu : CW_UiMenu
{
	enum ETab { TAB_OPS, TAB_INTEL, TAB_CREW, TAB_CITY, TAB_MARKET, TAB_LEDGER, TAB_NEWS, TAB_COUNT }
	enum EAct { ACT_NONE, ACT_DEPLOY, ACT_CLOSEDAY, ACT_CONTINUE, ACT_INTELBUY, ACT_PLEDGE, ACT_DECLINE, ACT_ENTRY, ACT_KITWALK, ACT_KITJOB, ACT_KITBOARD, ACT_OPENMAP }

	int sel;
	bool dbg, dbgBoard;         // debug hub: OPERATIONS is the kit tester (dbgBoard = show the real board instead)
	int kSel, kTop;
	bool KitMode() { return dbg && !dbgBoard; }
	bool showDebrief, waitDebrief, confirmClose;
	int hoverRow;
	int tab;
	int cur[TAB_COUNT];         // cursor per list tab
	int scroll[TAB_COUNT];
	double tabX[TAB_COUNT], tabW[TAB_COUNT], tabY, tabH;
	double itemY0, itemH;
	double clipBottom;
	// layout from last draw, for mouse hit-testing
	double listX, listY, listW, rowH;
	int listTop, listTab;
	Array<double> bX, bY, bW, bH;
	Array<int> bAct;
	Color amber, panel, line;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		let l = Ledger();
		sel = (l && l.selected >= 0) ? l.selected : 0;
		showDebrief = l && l.debriefNew;
		hoverRow = -1;
		dbg = CW_DebugKits.On();
		DontDim = true;
		MenuSound("menu/activate");
	}

	CW_City City() { let l = Ledger(); return l ? l.city : null; }
	int Count() { let l = Ledger(); return l ? l.OfferCount() : 0; }
	CW_Contract SelJob() { let l = Ledger(); return l ? l.Offer(sel) : null; }

	void Select(int i)
	{
		if (i < 0 || i >= Count() || i == sel) return;
		sel = i;
		MenuSound("menu/cursor");
		EventHandler.SendNetworkEvent("cw_select", sel);
	}

	// ------------------------------------------------------------------ actions
	void DoAct(int a)
	{
		let l = Ledger();
		let city = City();
		if (!l) return;
		if (a != ACT_CLOSEDAY) confirmClose = false;
		switch (a)
		{
		case ACT_KITWALK:
		case ACT_KITJOB:
			if (a == ACT_KITJOB && !CW_DebugKits.JobOk(kSel)) { MenuSound("menu/invalid"); return; }
			MenuSound("menu/choose");
			EventHandler.SendNetworkEvent("cw_dbgkit", kSel, a == ACT_KITJOB);
			Close();
			break;
		case ACT_OPENMAP:
		{
			MenuSound("menu/choose");
			let m = new("CW_CityMapMenu");
			m.Init(self);
			m.ActivateMenu();
			break;
		}
		case ACT_KITBOARD:
			dbgBoard = !dbgBoard;
			MenuSound("menu/change");
			break;
		case ACT_CONTINUE:
			showDebrief = false;
			EventHandler.SendNetworkEvent("cw_dismiss");
			MenuSound("menu/choose");
			break;
		case ACT_DEPLOY:
		{
			let c = SelJob();
			if (!c || l.DeployBlock(c).Length()) { MenuSound("menu/invalid"); return; }
			MenuSound("menu/choose");
			EventHandler.SendNetworkEvent("cw_deploy", sel);
			Close();
			break;
		}
		case ACT_CLOSEDAY:
			if (!city || city.outcome) { MenuSound("menu/invalid"); return; }
			if (!confirmClose) { confirmClose = true; MenuSound("menu/change"); return; }
			confirmClose = false;
			EventHandler.SendNetworkEvent("cw_closeday");
			waitDebrief = true;
			MenuSound("menu/choose");
			break;
		case ACT_INTELBUY:
		{
			int c = cur[TAB_CITY];
			if (!city || !CW_City.IsCorp(c) || c >= city.corps.Size() || !city.corps[c].alive) { MenuSound("menu/invalid"); return; }
			int cost = city.CorpIntelCost();
			if (cost <= 0 || l.budget < cost) { MenuSound("menu/invalid"); return; }
			EventHandler.SendNetworkEvent("cw_cityintel", c);
			MenuSound("menu/choose");
			break;
		}
		case ACT_PLEDGE:
		case ACT_DECLINE:
			if (!city || city.offer < 0) { MenuSound("menu/invalid"); return; }
			EventHandler.SendNetworkEvent("cw_pledge", a == ACT_PLEDGE ? 1 : 0);
			MenuSound("menu/choose");
			break;
		case ACT_ENTRY:
		{
			let c = SelJob();
			if (!c || !c.prepIntel) { MenuSound("menu/invalid"); return; }
			int e = (l.entryPref + 1) % 6;
			if (e == 1 && !c.garageOk) e = 2;
			EventHandler.SendNetworkEvent("cw_entry", e);
			MenuSound("menu/change");
			break;
		}
		}
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if (mkey != MKEY_Enter) confirmClose = false;
		switch (mkey)
		{
		case MKEY_Up:
			if (showDebrief) return true;
			if (tab == TAB_OPS && KitMode()) kSel = max(0, kSel - 1);
			else if (tab == TAB_OPS) Select(sel - 1);
			else if (tab == TAB_MARKET || tab == TAB_NEWS || tab == TAB_LEDGER) scroll[tab] = max(0, scroll[tab] - 1);
			else { cur[tab] = max(0, cur[tab] - 1); if (tab == TAB_CITY && cur[tab] == CW_City.NCORP) cur[tab]--; }
			MenuSound("menu/cursor");
			return true;
		case MKEY_Down:
			if (showDebrief) return true;
			if (tab == TAB_OPS && KitMode()) kSel = min(CW_DebugKits.Count() - 1, kSel + 1);
			else if (tab == TAB_OPS) Select(sel + 1);
			else if (tab == TAB_MARKET || tab == TAB_NEWS || tab == TAB_LEDGER) scroll[tab]++;
			else { cur[tab] = min(ItemCount() - 1, cur[tab] + 1); if (tab == TAB_CITY && cur[tab] == CW_City.NCORP) cur[tab]++; }
			MenuSound("menu/cursor");
			return true;
		case MKEY_Left:  if (!showDebrief) { tab = (tab + TAB_COUNT - 1) % TAB_COUNT; MenuSound("menu/change"); } return true;
		case MKEY_Right: if (!showDebrief) { tab = (tab + 1) % TAB_COUNT; MenuSound("menu/change"); } return true;
		case MKEY_Enter:
			if (showDebrief) DoAct(ACT_CONTINUE);
			else if (tab == TAB_INTEL || tab == TAB_CREW) Toggle(cur[tab]);
			else if (tab == TAB_OPS) DoAct(KitMode() ? ACT_KITWALK : ACT_DEPLOY);
			else if (tab == TAB_CITY) DoAct(ACT_INTELBUY);
			else if (tab == TAB_LEDGER) DoAct(ACT_PLEDGE);
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	// letter keys: C close the day, E entry, I intel, P pledge, D decline
	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_Char && !showDebrief)
		{
			String k = String.Format("%c", ev.KeyChar).MakeLower();
			if (k == "c") { DoAct(ACT_CLOSEDAY); return true; }
			if (k == "t" && tab == TAB_OPS && dbg) { DoAct(ACT_KITBOARD); return true; }
			if (k == "j" && tab == TAB_OPS && KitMode()) { DoAct(ACT_KITJOB); return true; }
			if (k == "e" && tab == TAB_OPS && !KitMode()) { DoAct(ACT_ENTRY); return true; }
			if (k == "i" && tab == TAB_CITY) { DoAct(ACT_INTELBUY); return true; }
			if (k == "m" && tab == TAB_CITY) { DoAct(ACT_OPENMAP); return true; }
			if (k == "p" && tab == TAB_LEDGER) { DoAct(ACT_PLEDGE); return true; }
			if (k == "d" && tab == TAB_LEDGER) { DoAct(ACT_DECLINE); return true; }
		}
		return Super.OnUIEvent(ev);
	}

	int ItemCount()
	{
		if (tab == TAB_INTEL) return CW_Services.INTEL_COUNT;
		if (tab == TAB_CREW) return CW_Services.CREW_COUNT;
		if (tab == TAB_CITY) return CW_City.NCORP + 1 + CW_City.NMINOR;
		return Count();
	}

	void Toggle(int i)
	{
		let l = Ledger();
		if (!l) return;
		if (tab == TAB_INTEL)
		{
			if (!l.HasIntel(i) && l.IntelPrice(i) <= 0) { MenuSound("menu/invalid"); return; }
			EventHandler.SendNetworkEvent("cw_intel", i);
		}
		else if (tab == TAB_CREW)
		{
			if (!l.HasCrew(i) && (l.CrewCount() >= CW_Services.MAX_CREW || l.CrewPrice(i) <= 0)) { MenuSound("menu/invalid"); return; }
			EventHandler.SendNetworkEvent("cw_crew", i);
		}
		MenuSound("menu/choose");
	}

	override bool MouseEvent(int type, int x, int y)
	{
		hoverRow = -1;
		if (type == MOUSE_Release)
			for (int i = 0; i < bAct.Size(); i++)
				if (x >= bX[i] && x <= bX[i] + bW[i] && y >= bY[i] && y <= bY[i] + bH[i]) { DoAct(bAct[i]); return true; }
		if (showDebrief) return true;
		if (y >= tabY && y <= tabY + tabH)
		{
			for (int t = 0; t < TAB_COUNT; t++)
				if (x >= tabX[t] && x <= tabX[t] + tabW[t] && type == MOUSE_Release) { tab = t; confirmClose = false; MenuSound("menu/change"); }
			return true;
		}
		if ((tab == TAB_INTEL || tab == TAB_CREW) && itemH > 0 && y >= itemY0)
		{
			int r = int((y - itemY0) / itemH);
			if (r >= 0 && r < ItemCount())
			{
				cur[tab] = r;
				if (type == MOUSE_Release) Toggle(r);
				return true;
			}
		}
		if ((tab == TAB_OPS || tab == TAB_CITY) && listTab == tab && x >= listX && x <= listX + listW && y >= listY && rowH > 0)
		{
			int r = int((y - listY) / rowH) + listTop;
			if (tab == TAB_OPS && KitMode())
			{
				if (r >= 0 && r < CW_DebugKits.Count()) { hoverRow = r; if (type == MOUSE_Release && r != kSel) { kSel = r; MenuSound("menu/cursor"); } }
			}
			else if (tab == TAB_OPS && r >= 0 && r < Count())
			{
				hoverRow = r;
				if (type == MOUSE_Release) Select(r);
			}
			if (tab == TAB_CITY && r >= 0 && r < ItemCount() && r != CW_City.NCORP)
			{
				hoverRow = r;
				if (type == MOUSE_Release) { cur[tab] = r; MenuSound("menu/cursor"); }
			}
		}
		return true;
	}

	override void Ticker()
	{
		Super.Ticker();
		let l = Ledger();
		if (waitDebrief && l && l.debriefNew) { waitDebrief = false; showDebrief = true; }
		if (l && sel >= Count()) sel = max(0, Count() - 1);
	}

	// A button with its right edge at xr; returns its left edge.
	double Button(double xr, double y, String label, bool active, int act, bool primary = true)
	{
		double w = TW(label) + 32 * s, h = LH() + 10 * s;
		double x = xr - w;
		Box(x, y, w, h, active ? (primary ? amber : Color(60, 72, 92)) : line);
		Txt(x + 16 * s, y + 5 * s + 1, label, active ? (primary ? Font.CR_BLACK : Font.CR_WHITE) : Font.CR_DARKGRAY);
		bX.Push(x); bY.Push(y); bW.Push(w); bH.Push(h); bAct.Push(active ? act : ACT_NONE);
		return x - 8 * s;
	}

	override void Drawer()
	{
		Super.Drawer();
		bX.Clear(); bY.Clear(); bW.Clear(); bH.Clear(); bAct.Clear();
		double sw = Screen.GetWidth(), sh = Screen.GetHeight();
		s = max(1.0, sh / 540.0);
		amber = Color(240, 170, 40);
		panel = Color(8, 12, 18);
		line = Color(45, 55, 70);

		Box(0, 0, sw, sh, Color(0, 0, 0), 0.65);
		double ww = min(sw * 0.96, 1180 * s), wh = sh * 0.95;
		double wx = (sw - ww) / 2, wy = (sh - wh) / 2;
		double pad = 14 * s;
		Box(wx, wy, ww, wh, panel, 0.96);
		TextureID art = TexMan.CheckForTexture("CWBRIEF", TexMan.Type_Any);
		if (art.IsValid()) Screen.DrawTexture(art, false, wx, wy, DTA_DestWidthF, ww, DTA_DestHeightF, wh, DTA_Alpha, 0.10);
		Box(wx, wy, ww, 3 * s, amber);

		let l = Ledger();
		let city = City();
		// ---- header
		double hy = wy + pad;
		String head = "BROKER'S DESK  //  TERMINAL";
		if (city) head = String.Format("BROKER'S DESK  //  DAY %d%s", city.day, city.patron >= 0 ? "  //  PLEDGED TO " .. city.corps[city.patron].short.MakeUpper() : "");
		Txt(wx + pad, hy, head, Font.CR_GOLD);
		if (l)
		{
			String bud = "Budget  " .. CW_Handler.Money(l.budget);
			double bx = wx + ww - pad - TW(bud);
			Txt(bx, hy, bud, l.budget >= 0 ? Font.CR_GREEN : Font.CR_RED);
			if (l.debt) { String dt = "Owed to Meridian  " .. CW_Handler.Money(l.debt) .. "    "; Txt(bx - TW(dt), hy, dt, Font.CR_ORANGE); }
		}
		hy += LH() + 6 * s;
		Box(wx + pad, hy, ww - pad * 2, max(1.0, s), line);
		double top = hy + 10 * s;
		if (!showDebrief)
		{
			static const String tabNames[] = { "OPERATIONS", "INTEL", "CREW", "CITY", "MARKET", "LEDGER", "NEWS" };
			double tx = wx + pad;
			tabY = top; tabH = LH() + 8 * s;
			for (int t = 0; t < TAB_COUNT; t++)
			{
				String nm = tabNames[t];
				if (t == TAB_OPS && KitMode()) nm = String.Format("KIT TEST (%d)", CW_DebugKits.Count());
				else if (t == TAB_OPS && l) nm = nm .. String.Format(" (%d)", Count());
				if (t == TAB_INTEL && l && l.intelMask) nm = nm .. String.Format(" (%d)", CountBits(l.intelMask));
				if (t == TAB_CREW && l && l.crewMask) nm = nm .. String.Format(" (%d/%d)", l.CrewCount(), CW_Services.MAX_CREW);
				if (t == TAB_LEDGER && city && city.offer >= 0) nm = nm .. " (!)";
				tabX[t] = tx; tabW[t] = TW(nm) + 20 * s;
				Box(tx, tabY, tabW[t], tabH, t == tab ? Color(30, 38, 52) : Color(14, 18, 26));
				if (t == tab) Box(tx, tabY + tabH - 2 * s, tabW[t], 2 * s, amber);
				Txt(tx + 10 * s, tabY + 4 * s + 1, nm, t == tab ? Font.CR_GOLD : (t == TAB_LEDGER && city && city.offer >= 0 ? Font.CR_ORANGE : Font.CR_DARKGRAY));
				tx += tabW[t] + 4 * s;
			}
			String hint = "LEFT/RIGHT  tabs    C  close the day    ESC  close";
			if (tx + TW(hint) + 20 * s < wx + ww - pad) Txt(wx + ww - pad - TW(hint), tabY + 4 * s + 1, hint, Font.CR_DARKGRAY);
			top = tabY + tabH + 10 * s;
		}

		// ---- footer
		double btnHh = LH() + 10 * s;
		double by = wy + wh - pad - btnHh;
		Box(wx + pad, by - 8 * s, ww - pad * 2, max(1.0, s), line);
		double bottom = by - 16 * s;
		clipBottom = bottom;
		if (!l) return;
		DrawFooter(l, city, wx + pad, wx + ww - pad, by);
		if (!city) { Txt(wx + pad, top, "The city is not set up yet. Walk out of the office and back in.", Font.CR_RED); return; }

		// ---- debrief (after a job or a closed day)
		if (showDebrief)
		{
			double s0 = s;
			dry = true;
			while (DrawDebrief(l, wx + pad, top, ww - pad * 2, 1e9) > bottom && s > s0 * 0.55) s *= 0.93;
			dry = false;
			DrawDebrief(l, wx + pad, top, ww - pad * 2, bottom);
			s = s0;
			return;
		}
		switch (tab)
		{
		case TAB_OPS:    if (KitMode()) DrawKits(wx + pad, top, ww - pad * 2, bottom); else DrawOps(l, city, wx + pad, top, ww - pad * 2, bottom); break;
		case TAB_INTEL:
		case TAB_CREW:   DrawServices(l, city, wx + pad, top, ww - pad * 2, bottom); break;
		case TAB_CITY:   DrawCity(l, city, wx + pad, top, ww - pad * 2, bottom); break;
		case TAB_MARKET: DrawMarket(city, wx + pad, top, ww - pad * 2, bottom); break;
		case TAB_LEDGER:
		{
			double s0 = s;
			dry = true;
			while (DrawLedger(l, city, wx + pad, top, ww - pad * 2, 1e9) > bottom && s > s0 * 0.6) s *= 0.93;
			dry = false;
			DrawLedger(l, city, wx + pad, top, ww - pad * 2, bottom);
			s = s0;
			break;
		}
		case TAB_NEWS:   DrawNews(city, wx + pad, top, ww - pad * 2, bottom); break;
		}
	}

	void DrawFooter(CW_Ledger l, CW_City city, double xl, double xr, double by)
	{
		double fy = by + 5 * s + 1;
		if (showDebrief)
		{
			Button(xr, by, "CONTINUE", true, ACT_CONTINUE);
			Txt(xl, fy, "ENTER  continue      ESC  close", Font.CR_DARKGRAY);
			return;
		}
		bool over = city && city.outcome;
		String cd = confirmClose ? "CLOSE THE DAY? (C again)" : "CLOSE DAY  [C]";
		switch (tab)
		{
		case TAB_OPS:
		if (KitMode())
		{
			double x = Button(xr, by, "WALK IN  [ENTER]", true, ACT_KITWALK);
			x = Button(x, by, "WITH A JOB  [J]", CW_DebugKits.JobOk(kSel), ACT_KITJOB, false);
			x = Button(x, by, "JOB BOARD  [T]", true, ACT_KITBOARD, false);
			Txt(xl, fy, "Return to hub: HOME (rebind in Controls)", Font.CR_DARKGRAY);
			break;
		}
		else
		{
			if (dbg) { xr = Button(xr, by, "KIT TEST  [T]", true, ACT_KITBOARD, false); }
			let c = SelJob();
			String blk = l.DeployBlock(c);
			double x = Button(xr, by, blk.Length() ? blk : "DEPLOY", blk.Length() == 0, ACT_DEPLOY);
			x = Button(x, by, cd, !over, ACT_CLOSEDAY, false);
			if (c)
			{
				int oc = c.cost, lo = l.LoadoutCost();
				double fx = xl;
				Txt(fx, fy, "Op cost", Font.CR_DARKGRAY); fx += TW("Op cost ") + 4 * s;
				String t1 = "-" .. CW_Handler.Money(oc);
				Txt(fx, fy, t1, Font.CR_RED); fx += TW(t1) + 16 * s;
				if (lo)
				{
					Txt(fx, fy, "Intel & crew", Font.CR_DARKGRAY); fx += TW("Intel & crew ") + 4 * s;
					String t2 = "-" .. CW_Handler.Money(lo);
					Txt(fx, fy, t2, Font.CR_RED); fx += TW(t2) + 16 * s;
				}
				int after = l.budget - oc - lo;
				if (fx + TW("After deploy $00000") < x)
				{
					Txt(fx, fy, "After deploy", Font.CR_DARKGRAY); fx += TW("After deploy ") + 4 * s;
					Txt(fx, fy, CW_Handler.Money(after), after >= 0 ? Font.CR_GREEN : Font.CR_RED);
				}
			}
			break;
		}
		case TAB_INTEL:
		case TAB_CREW:
		{
			double x = Button(xr, by, cd, !over, ACT_CLOSEDAY, false);
			String tot = CW_Handler.Money(l.LoadoutCost());
			Txt(xl, fy, "Loadout for the next job  ", Font.CR_DARKGRAY);
			Txt(xl + TW("Loadout for the next job  "), fy, tot, l.LoadoutCost() ? Font.CR_RED : Font.CR_DARKGRAY);
			break;
		}
		case TAB_CITY:
		{
			int c = cur[TAB_CITY];
			int cost = city ? city.CorpIntelCost() : 0;
			bool can = city && CW_City.IsCorp(c) && c < city.corps.Size() && city.corps[c].alive && cost > 0 && l.budget >= cost;
			String lbl = cost > 0 ? String.Format("BUY INTEL  %s  [I]", CW_Handler.Money(cost)) : "NO INTEL FOR SALE";
			double x = Button(xr, by, lbl, can, ACT_INTELBUY);
			x = Button(x, by, cd, !over, ACT_CLOSEDAY, false);
			Button(x, by, "CITY MAP  [M]", true, ACT_OPENMAP, false);
			String src = !city ? "" : city.MinorService("NUL") ? "Intel: Candor Analytics or NullSet (Friendly)" : String.Format("Intel from %s", city.ServiceSub("intel"));
			Txt(xl, fy, src, Font.CR_DARKGRAY);
			break;
		}
		case TAB_LEDGER:
		{
			double x = xr;
			if (city && city.offer >= 0)
			{
				x = Button(x, by, "PLEDGE  [P]", true, ACT_PLEDGE);
				x = Button(x, by, "DECLINE  [D]", true, ACT_DECLINE, false);
			}
			Button(x, by, cd, !over, ACT_CLOSEDAY, false);
			Txt(xl, fy, "UP/DOWN  scroll", Font.CR_DARKGRAY);
			break;
		}
		default:
			Button(xr, by, cd, !over, ACT_CLOSEDAY, false);
			Txt(xl, fy, "UP/DOWN  scroll", Font.CR_DARKGRAY);
			break;
		}
	}

	static int CountBits(int m) { int n = 0; while (m) { n += m & 1; m >>= 1; } return n; }

	// ================================================================ OPERATIONS
	// debug hub: every kit / variant, one row each
	void DrawKits(double x, double top, double w, double bottom)
	{
		double lw = (w - 14 * s) * 0.42;
		listTab = TAB_OPS;
		listX = x; listY = top + LH(); listW = lw; rowH = LH() + 4 * s;
		int n = CW_DebugKits.Count();
		Txt(listX, top, "DEBUG HUB  //  SITE KITS", Font.CR_GOLD);
		int visRows = max(1, int((bottom - listY) / rowH));
		if (kSel < kTop) kTop = kSel;
		if (kSel >= kTop + visRows) kTop = kSel - visRows + 1;
		kTop = clamp(kTop, 0, max(0, n - visRows));
		listTop = kTop;
		if (n > visRows) { String more = String.Format("%d-%d of %d", kTop + 1, min(n, kTop + visRows), n); Txt(listX + lw - TW(more), top, more, Font.CR_DARKGRAY); }
		double gw = lw * 0.48;
		for (int i = kTop; i < n && i < kTop + visRows; i++)
		{
			double ry = listY + (i - kTop) * rowH;
			if (i == kSel) Box(listX, ry, lw, rowH - 2 * s, Color(30, 38, 52));
			else if (i == hoverRow) Box(listX, ry, lw, rowH - 2 * s, Color(18, 24, 34));
			if (i == kSel) Box(listX, ry, 3 * s, rowH - 2 * s, amber);
			String m = CW_DebugKits.MapOf(i);
			if (i == kTop || CW_DebugKits.Group(CW_DebugKits.MapOf(i - 1)) != CW_DebugKits.Group(m))
				Txt(listX + 8 * s, ry + 2 * s, Fit(CW_DebugKits.Group(m), gw - 12 * s), Font.CR_GOLD);
			String nm = CW_DebugKits.Name(i);
			if (CW_DebugKits.Group(m) == "OTHER MAPS") nm = m .. "  " .. nm;
			Txt(listX + gw, ry + 2 * s, Fit(nm, lw - gw - 8 * s), i == kSel ? Font.CR_WHITE : Font.CR_GRAY);
		}
		// details
		double dx = x + lw + 14 * s, dw = w - lw - 14 * s;
		double y = top;
		String m = CW_DebugKits.MapOf(kSel);
		int v = CW_DebugKits.Variant(kSel);
		Txt(dx, y, CW_DebugKits.Group(m), Font.CR_GOLD); y += LH() + 4 * s;
		y = KV(dx, y, dw, "Map", m, Font.CR_DARKGRAY, Font.CR_WHITE);
		y = KV(dx, y, dw, "Layout", CW_DebugKits.Name(kSel), Font.CR_DARKGRAY, Font.CR_WHITE);
		if (CW_KitGen.KitOfMap(m)) y = KV(dx, y, dw, "cw_kitvariant", v < 0 ? "-1 (from the seed)" : String.Format("%d", v), Font.CR_DARKGRAY, Font.CR_WHITE);
		if (m == "G02") y = KV(dx, y, dw, "cw_floors", String.Format("%d", CW_DebugKits.Floors(kSel)), Font.CR_DARKGRAY, Font.CR_WHITE);
		y = KV(dx, y, dw, "With a job", CW_DebugKits.JobOk(kSel) ? "yes" : "walk-in only", Font.CR_DARKGRAY, CW_DebugKits.JobOk(kSel) ? Font.CR_GREEN : Font.CR_DARKGRAY);
		y += LH();
		y = Wrapped(dx, y, dw, "\cdWALK IN\c-  loads the map with no job: guards, props and layout from the kit, a fresh seed every time (set cw_procseed to pin one). Press HOME to come back here.", Font.CR_GRAY);
		y += 6 * s;
		y = Wrapped(dx, y, dw, "\cdWITH A JOB\c-  borrows the first job on the board, moves it onto this kit and variant at no cost, and deploys it for real: objectives, extraction and a debrief. HOME aborts it.", Font.CR_GRAY);
		y += 6 * s;
		Wrapped(dx, y, dw, "\cdT\c-  switches to the real job board and back.", Font.CR_GRAY);
	}

	void DrawOps(CW_Ledger l, CW_City city, double x, double top, double w, double bottom)
	{
		double lw = (w - 14 * s) * 0.38;
		listTab = TAB_OPS;
		listX = x; listY = top + LH(); listW = lw; rowH = LH() * 2 + 6 * s;
		int n = Count();
		Txt(listX, top, String.Format("THE BOARD  %d operations", city.ActiveOps()), Font.CR_DARKGRAY);
		if (city.outcome)
		{
			Wrapped(x, listY + 6 * s, w, (city.outcome == 1 ? "\cdCAMPAIGN WON.\c- " : "\crCAMPAIGN LOST.\c- ") .. city.outcomeText, Font.CR_WHITE);
			return;
		}
		if (!n)
		{
			Wrapped(x, listY + 6 * s, lw, "Nothing on the board today. Close the day and see what the city brings.", Font.CR_GRAY);
			return;
		}
		int visRows = max(1, int((bottom - listY) / rowH));
		if (sel < listTop) listTop = sel;
		if (sel >= listTop + visRows) listTop = sel - visRows + 1;
		listTop = clamp(listTop, 0, max(0, n - visRows));
		if (n > visRows) { String more = String.Format("%d-%d of %d", listTop + 1, min(n, listTop + visRows), n); Txt(listX + lw - TW(more), top, more, Font.CR_DARKGRAY); }
		for (int i = listTop; i < n; i++)
		{
			let c = l.Offer(i);
			double ry = listY + (i - listTop) * rowH;
			if (ry + rowH > bottom) break;
			bool off = c.refused.Length() > 0;
			if (i == sel) Box(listX, ry, lw, rowH - 4 * s, Color(30, 38, 52));
			else if (i == hoverRow) Box(listX, ry, lw, rowH - 4 * s, Color(20, 26, 36));
			Box(listX, ry, 3 * s, rowH - 4 * s, i == sel ? amber : CW_City.RoleColor(c.role));
			String rk = CW_Contract.RiskName(c.risk);
			Txt(listX + 10 * s, ry + 3 * s, Fit(c.title, lw - 30 * s - TW(rk)), off ? Font.CR_DARKGRAY : (i == sel ? Font.CR_WHITE : Font.CR_GRAY));
			Txt(listX + lw - 8 * s - TW(rk), ry + 3 * s, rk, off ? Font.CR_DARKGRAY : CW_Contract.RiskFont(c.risk));
			String role = CW_City.RoleName(c.role);
			double y2 = ry + 3 * s + LH();
			Txt(listX + 10 * s, y2, role, off ? Font.CR_DARKGRAY : (c.decisive ? Font.CR_GOLD : Font.CR_CYAN));
			int left = c.deadline - city.day;
			String dl = off ? "refused" : String.Format("%dd", max(0, left));
			double cx = listX + 18 * s + TW("LEVERAGE");
			Txt(cx, y2, Fit(city.FactionShort(c.clientF) .. (c.clientHidden ? " (?)" : ""), listX + lw - cx - TW(dl) - 16 * s), off ? Font.CR_DARKGRAY : CW_City.FactionFont(c.clientHidden ? -99 : c.clientF));
			Txt(listX + lw - 8 * s - TW(dl), y2, dl, off ? Font.CR_DARKGRAY : (left <= 1 ? Font.CR_RED : Font.CR_DARKGRAY));
		}
		double rx = listX + lw + 14 * s;
		Box(rx - 7 * s, top, max(1.0, s), bottom - top, line);
		let c = SelJob();
		if (!c) return;
		double rw = x + w - rx;
		double s0 = s;
		dry = true; clipBottom = 1e9;
		while (DrawJob(l, city, c, rx, top, rw) > bottom && s > s0 * 0.6) s *= 0.93;
		dry = false; clipBottom = bottom;
		DrawJob(l, city, c, rx, top, rw);
		s = s0;
	}

	double Chip(double x, double y, String t, Color c)
	{
		double cw = TW(t) + 10 * s;
		Box(x, y - 1, cw, LH() - 3 * s, c, 0.85);
		Txt(x + 5 * s, y + 1, t, Font.CR_WHITE);
		return x + cw + 8 * s;
	}

	double DrawJob(CW_Ledger l, CW_City city, CW_Contract c, double rx, double top, double rw)
	{
		double y = top;
		Txt(rx, y, Fit(c.title, rw), Font.CR_WHITE); y += LH() * 1.2;
		double cx = Chip(rx, y, CW_City.RoleName(c.role), CW_City.RoleColor(c.role));
		Txt(cx, y, Fit("for " .. c.client, rx + rw - cx), CW_City.FactionFont(c.clientHidden ? -99 : c.clientF));
		y += LH() + 2 * s;
		y = KV(rx, y, rw, "Operation", c.opTitle, Font.CR_DARKGRAY, Font.CR_GRAY);
		int left = max(0, c.deadline - city.day);
		y = KV(rx, y, rw, "Progress", String.Format("%d%%   %d day%s left", c.progress, left, left == 1 ? "" : "s"), Font.CR_DARKGRAY, left <= 1 ? Font.CR_RED : Font.CR_GRAY);
		y = KV(rx, y, rw, "Target", c.target, Font.CR_DARKGRAY, CW_City.FactionFont(c.targetF));
		String sec = c.secKnown ? String.Format("force %d, tech %d  (%s)", c.secForce, c.secTech, CW_Contract.RiskName(c.risk)) : String.Format("looks %s (no intel)", CW_City.RoughSecurity(c.secForce, c.secTech));
		y = KV(rx, y, rw, "Security", sec, Font.CR_DARKGRAY, CW_Contract.RiskFont(c.risk));
		if (c.floors > 1) y = KV(rx, y, rw, "Floors", String.Format("%d", c.floors), Font.CR_DARKGRAY, Font.CR_GRAY);
		y += 4 * s;
		y = Wrapped(rx, y, rw, c.brief, Font.CR_TAN);
		if (c.refused.Length()) { y += 2 * s; y = Wrapped(rx, y, rw, c.refused, Font.CR_RED); }
		y += 6 * s;
		Txt(rx, y, "OBJECTIVES", Font.CR_DARKGRAY);
		String rule = "any one primary completes the job";
		Txt(rx + rw - TW(rule), y, rule, Font.CR_DARKGRAY);
		y += LH();
		for (int k = 1; k <= 3; k++)
		{
			if (c.pay[k] <= 0) continue;
			bool p = c.IsPrimary(k);
			String tag = CW_Contract.KindTag(k);
			double cw = TW("SABOTAGE") + 10 * s;
			Box(rx, y - 1, cw, LH() - 3 * s, CW_Contract.KindColor(k), 0.85);
			Txt(rx + (cw - TW(tag)) / 2, y + 1, tag, Font.CR_WHITE);
			String role = p ? "PRIMARY" : "BONUS";
			Txt(rx + cw + 8 * s, y, role, p ? Font.CR_GOLD : Font.CR_DARKGRAY);
			double nx = rx + cw + 16 * s + TW("PRIMARY");
			String pay = CW_Handler.Money(c.pay[k]);
			Txt(nx, y, Fit(c.ObjName(k), rx + rw - TW(pay) - 12 * s - nx), p ? Font.CR_WHITE : Font.CR_GRAY);
			Txt(rx + rw - TW(pay), y, pay, Font.CR_GREEN);
			y += LH() + 2 * s;
		}
		// ---- prep: the operation's odd jobs and what they've done for this strike
		if (c.decisive && (c.hasIntelStep || c.hasAccessStep || c.hasWeakenStep || c.hasLeverageStep))
		{
			y += 6 * s;
			Txt(rx, y, "PREP (odd jobs on this operation)", Font.CR_DARKGRAY); y += LH();
			double px = rx;
			if (c.hasIntelStep) px = PrepChip(px, y, "INTEL", c.prepIntel, R_INTEL);
			if (c.hasAccessStep) px = PrepChip(px, y, "ACCESS", c.prepAccess, R_ACCESS);
			if (c.hasWeakenStep) px = PrepChip(px, y, "WEAKEN", c.prepWeaken, R_WEAKEN);
			if (c.hasLeverageStep) px = PrepChip(px, y, "LEVERAGE", c.prepLeverage, R_LEVERAGE);
			y += LH() + 2 * s;
		}
		if (c.decisive)
		{
			static const String entries[] = { "random", "garage (B1)", "street lobby", "stairwell", "elevator", "roof" };
			String en = c.prepIntel ? String.Format("%s   [E] change", entries[clamp(l.entryPref, 0, 5)]) : (c.garageOk ? "random (garage possible)" : "random");
			y = KV(rx, y, rw, "Entry", en, Font.CR_DARKGRAY, c.prepIntel ? Font.CR_CYAN : Font.CR_GRAY);
		}
		// ---- rules of engagement
		y += 6 * s;
		if (y + LH() * 2 > clipBottom) return y;
		Txt(rx, y, "RULES OF ENGAGEMENT", Font.CR_DARKGRAY); y += LH();
		for (int k = 1; k <= 3; k++)
		{
			if (c.penalty[k] <= 0) continue;
			y = Fine(rx, y, rw, "Unauthorized " .. CW_Contract.KindTag(k).MakeLower(), c.penalty[k]);
		}
		if (c.guardFine) y = Fine(rx, y, rw, "Each guard killed", c.guardFine);
		if (c.protectCivilians) y = Fine(rx, y, rw, "Each civilian killed", c.civFine);
		else if (y + LH() <= clipBottom)
		{
			Box(rx, y + LH() * 0.35, 6 * s, 6 * s, Color(90, 100, 110));
			Txt(rx + 14 * s, y, "Civilian casualties", Font.CR_DARKGRAY);
			Txt(rx + rw - TW("not penalized"), y, "not penalized", Font.CR_DARKGRAY);
			y += LH();
		}
		return y;
	}

	double PrepChip(double x, double y, String t, bool done, int role)
	{
		String lbl = t .. (done ? "  done" : "  open");
		double cw = TW(lbl) + 12 * s;
		Box(x, y - 1, cw, LH() - 3 * s, done ? CW_City.RoleColor(role) : Color(40, 46, 56), done ? 0.85 : 1.0);
		Txt(x + 6 * s, y + 1, lbl, done ? Font.CR_WHITE : Font.CR_DARKGRAY);
		return x + cw + 6 * s;
	}

	double Fine(double x, double y, double w, String what, int amt)
	{
		if (y + LH() > clipBottom) return y;
		Box(x, y + LH() * 0.35, 6 * s, 6 * s, Color(230, 70, 60));
		String v = "-" .. CW_Handler.Money(amt);
		Txt(x + 14 * s, y, Fit(what, w - 14 * s - TW(v) - 12 * s), Font.CR_GRAY);
		Txt(x + w - TW(v), y, v, Font.CR_RED);
		return y + LH();
	}

	// ================================================================ INTEL / CREW
	void DrawServices(CW_Ledger l, CW_City city, double x, double top, double w, double bottom)
	{
		bool intel = tab == TAB_INTEL;
		int n = intel ? CW_Services.INTEL_COUNT : CW_Services.CREW_COUNT;
		double y = top;
		String svc = intel ? "intel" : "crew";
		int pct = city.ServicePct(svc);
		int owner = city.ServiceCorp(svc);
		String who = String.Format("%s (%s)", city.ServiceSub(svc), owner >= 0 ? city.corps[owner].short : "receivership");
		String note;
		if (pct) note = String.Format("Supplied by %s. You're %s with them: %d%% of list price.", who, CW_City.TierName(city.EffRep(owner)), pct);
		else if (intel && city.MinorService("NUL")) note = String.Format("%s won't deal with you. NullSet sells it instead.", who);
		else note = String.Format("%s won't deal with you right now.", who);
		Txt(x, y, intel ? "Bought per job. Consumed when you deploy." : String.Format("Hire up to %d specialists for the next job.", CW_Services.MAX_CREW), Font.CR_DARKGRAY);
		y += LH();
		Txt(x, y, Fit(note, w), pct ? Font.CR_GRAY : Font.CR_ORANGE);
		y += LH();
		let c = SelJob();
		if (intel && c && c.prepIntel) { Txt(x, y, "The selected job's Intel prep covers both packages for free.", Font.CR_CYAN); y += LH(); }
		else if (intel && c && city.MinorService("L9") && city.MinorTurf("L9", c.district) >= 30) { Txt(x, y, "Local 9 informants give you the patrol schedule on this job for free.", Font.CR_GREEN); y += LH(); }
		y += 6 * s;
		itemY0 = y;
		itemH = LH() * 2 + 14 * s;
		for (int i = 0; i < n; i++)
		{
			double ry = y + i * itemH;
			if (ry + itemH > bottom) break;
			bool on = intel ? l.HasIntel(i) : l.HasCrew(i);
			int price = intel ? l.IntelPrice(i) : l.CrewPrice(i);
			bool full = (!intel && !on && l.CrewCount() >= CW_Services.MAX_CREW) || price <= 0;
			bool hot = i == cur[tab];
			Box(x, ry, w, itemH - 6 * s, hot ? Color(30, 38, 52) : Color(14, 18, 26));
			Color accent = intel ? Color(60, 220, 200) : CW_Services.CrewColor(i);
			Box(x, ry, 3 * s, itemH - 6 * s, on ? accent : line);
			double cb = LH() - 4 * s;
			Box(x + 12 * s, ry + 6 * s, cb, cb, line);
			if (on) Box(x + 12 * s + 3 * s, ry + 9 * s, cb - 6 * s, cb - 6 * s, amber);
			double tx = x + 22 * s + cb;
			String name = intel ? CW_Services.IntelName(i) : CW_Services.CrewName(i);
			Txt(tx, ry + 5 * s, name, full ? Font.CR_DARKGRAY : (on ? Font.CR_WHITE : Font.CR_GRAY));
			if (!intel)
			{
				String role = CW_Services.CrewRole(i);
				double rx2 = tx + TW(name) + 10 * s;
				Box(rx2, ry + 5 * s, TW(role) + 10 * s, LH() - 4 * s, accent, 0.25);
				Txt(rx2 + 5 * s, ry + 6 * s, role, Font.CR_WHITE);
			}
			String cost = price > 0 ? CW_Handler.Money(price) : "unavailable";
			Txt(x + w - 12 * s - TW(cost), ry + 5 * s, cost, on ? Font.CR_RED : Font.CR_DARKGRAY);
			Txt(tx, ry + 5 * s + LH(), Fit(intel ? CW_Services.IntelDesc(i) : CW_Services.CrewDesc(i), w - (tx - x) - 140 * s), full ? Font.CR_DARKGRAY : Font.CR_TAN);
			if (!intel)
			{
				bool loaded = l.CountIn(1, CW_Items.CrewKit(i)) > 0;
				String ks = loaded ? "kit in transport" : "KIT NOT LOADED";
				Txt(x + w - 12 * s - TW(ks), ry + 5 * s + LH(), ks, loaded ? Font.CR_DARKGREEN : (on ? Font.CR_RED : Font.CR_DARKGRAY));
			}
		}
		if (!intel && city.ServicePct("blackout") && CW_City.Tier(city.EffRep(city.ServiceCorp("blackout"))) >= 1)
		{
			double sy = y + n * itemH + 4 * s;
			if (sy + LH() < bottom) Txt(x, sy, "Voltaic Holdings grid contacts: Nyx's blackout lasts 10 seconds longer.", Font.CR_YELLOW);
		}
	}

	// ================================================================ CITY
	void DrawCity(CW_Ledger l, CW_City city, double x, double top, double w, double bottom)
	{
		double lw = (w - 14 * s) * 0.30;
		listTab = TAB_CITY;
		listX = x; listY = top + LH(); listW = lw; rowH = LH() * 2 + 4 * s;
		listTop = 0;
		Txt(x, top, "FACTIONS", Font.CR_DARKGRAY);
		int n = ItemCount();
		double ry = listY;
		for (int i = 0; i < n; i++, ry += rowH)
		{
			if (ry + rowH > bottom) break;
			if (i == CW_City.NCORP)
			{
				Txt(listX + 4 * s, ry + rowH * 0.3, "MINOR PLAYERS", Font.CR_DARKGRAY);
				continue;
			}
			int f = i < CW_City.NCORP ? i : CW_City.MINOR_BASE + i - CW_City.NCORP - 1;
			if (i == cur[TAB_CITY]) Box(listX, ry, lw, rowH - 4 * s, Color(30, 38, 52));
			else if (i == hoverRow) Box(listX, ry, lw, rowH - 4 * s, Color(20, 26, 36));
			Box(listX, ry, 3 * s, rowH - 4 * s, CW_City.FactionColor(f));
			bool dead = CW_City.IsCorp(f) && !city.corps[f].alive;
			bool dorm = CW_City.IsMinor(f) && city.minors[f - CW_City.MINOR_BASE].dormant;
			Txt(listX + 10 * s, ry + 3 * s, Fit(city.FactionName(f), lw - 16 * s), dead || dorm ? Font.CR_DARKGRAY : CW_City.FactionFont(f));
			String sub;
			if (CW_City.IsCorp(f)) sub = dead ? String.Format("collapsed day %d", city.corps[f].diedDay) : String.Format("%d subs, %d sites", city.SubCount(f), city.PropCount(f));
			else sub = dorm ? "dormant" : city.minors[f - CW_City.MINOR_BASE].kind;
			Txt(listX + 10 * s, ry + 3 * s + LH() * 0.95, sub, Font.CR_DARKGRAY);
			String t = CW_City.TierName(city.EffRep(f));
			Txt(listX + lw - 8 * s - TW(t), ry + 3 * s + LH() * 0.95, t, CW_City.TierFont(city.EffRep(f)));
		}
		double rx = listX + lw + 14 * s;
		Box(rx - 7 * s, top, max(1.0, s), bottom - top, line);
		double rw = x + w - rx;
		int i = cur[TAB_CITY];
		double s0 = s;
		dry = true;
		while (DrawFaction(city, i, rx, top, rw, 1e9) > bottom && s > s0 * 0.55) s *= 0.93;
		dry = false;
		DrawFaction(city, i, rx, top, rw, bottom);
		s = s0;
	}

	double DrawFaction(CW_City city, int i, double x, double y, double w, double bottom)
	{
		if (i < CW_City.NCORP) return DrawCorp(city, i, x, y, w, bottom);
		return DrawMinor(city, i - CW_City.NCORP - 1, x, y, w, bottom);
	}

	double DrawCorp(CW_City city, int c, double x, double y, double w, double bottom)
	{
		let o = city.corps[c];
		bool known = city.IntelFresh(o.finKnownDay);
		Txt(x, y, o.name, CW_City.FactionFont(c));
		String tag = o.alive ? "\"" .. o.motto .. "\"" : String.Format("COLLAPSED on day %d", o.diedDay);
		Txt(x + w - TW(tag), y, Fit(tag, w * 0.55), o.alive ? Font.CR_DARKGRAY : Font.CR_RED);
		y += LH() * 1.2;
		double cw = (w - 20 * s) / 2, x2 = x + cw + 20 * s, yl = y, yr = y;
		yl = KV(x, yl, cw, "Your standing", String.Format("%s (%d)", CW_City.TierName(city.EffRep(c)), city.GetRep(c)), Font.CR_DARKGRAY, CW_City.TierFont(city.EffRep(c)));
		yl = KV(x, yl, cw, "Wealth / security / tech", String.Format("%d / %d / %d", o.wealth, o.security, o.tech), Font.CR_DARKGRAY, Font.CR_GRAY);
		yl = KV(x, yl, cw, "Aggression / ethics", String.Format("%d / %d", o.aggression, o.ethics), Font.CR_DARKGRAY, Font.CR_GRAY);
		yl = KV(x, yl, cw, "Subsidiaries / sites", String.Format("%d / %d", city.SubCount(c), city.PropCount(c)), Font.CR_DARKGRAY, Font.CR_WHITE);
		yr = KV(x2, yr, cw, "Treasury", known ? String.Format("%dk", o.treasury) : "?", Font.CR_DARKGRAY, known ? Font.CR_GREEN : Font.CR_DARKGRAY);
		yr = KV(x2, yr, cw, "Meridian debt", known ? String.Format("%dk of %dk", o.debt, city.CreditLimit(c)) : "?", Font.CR_DARKGRAY, known ? (o.debt > city.CreditLimit(c) * 7 / 10 ? Font.CR_RED : Font.CR_GRAY) : Font.CR_DARKGRAY);
		int ceo = city.CeoOf(c);
		yr = KV(x2, yr, cw, "CEO", ceo >= 0 ? city.execs[ceo].name : "vacant", Font.CR_DARKGRAY, Font.CR_GRAY);
		yr = KV(x2, yr, cw, "Intel", known ? String.Format("fresh (day %d)", o.finKnownDay) : (o.finKnownDay > -99 ? "stale" : "none"), Font.CR_DARKGRAY, known ? Font.CR_CYAN : Font.CR_DARKGRAY);
		y = max(yl, yr) + 6 * s;
		// ---- agendas (fog of war)
		Txt(x, y, "AGENDAS", Font.CR_DARKGRAY); y += LH();
		if (!known) { Txt(x, y, "Unknown. Buy intel, or read the news for hints.", Font.CR_DARKGRAY); y += LH(); }
		else for (int a = 0; a < city.agendas.Size(); a++) if (city.agendas[a].owner == c) { Txt(x, y, Fit("- " .. city.agendas[a].text, w), Font.CR_TAN); y += LH(); }
		y += 4 * s;
		// ---- relations with the other corps: tiers always, exact values with intel
		Txt(x, y, known ? "RELATIONS (exact)" : "RELATIONS (as the street sees it)", Font.CR_DARKGRAY); y += LH();
		double rx = x;
		for (int k = 0; k < CW_City.NCORP; k++)
		{
			if (k == c) continue;
			int v = city.GetRel(c, k);
			String t = String.Format("%s %s", city.corps[k].short, known ? String.Format("%d", v) : CW_City.TierName(v));
			if (!city.corps[k].alive) t = city.corps[k].short .. " (gone)";
			double tw = TW(t) + 18 * s;
			if (rx + tw > x + w) { rx = x; y += LH(); }
			Txt(rx, y, t, city.corps[k].alive ? CW_City.TierFont(v) : Font.CR_DARKGRAY);
			rx += tw;
		}
		y += LH() + 4 * s;
		// ---- subsidiaries and their sites
		Txt(x, y, "SUBSIDIARIES", Font.CR_DARKGRAY); y += LH();
		for (int sb = 0; sb < city.subs.Size(); sb++)
		{
			let b = city.subs[sb];
			if (b.corp != c) continue;
			if (b.shell && !b.shellKnown && c != city.patron) continue;   // you don't know it's theirs
			if (y + LH() > bottom) break;
			String head = b.head >= 0 ? city.execs[b.head].name : "vacant";
			String svc = b.service.Length() ? "  [" .. b.service .. "]" : "";
			Txt(x, y, Fit(String.Format("%s%s%s", b.name, b.shell ? " (shell)" : "", svc), w * 0.55), b.shell ? Font.CR_ORANGE : Font.CR_WHITE);
			String right = String.Format("%d sites   head: %s", city.SubProps(sb), head);
			Txt(x + w - TW(Fit(right, w * 0.43)), y, Fit(right, w * 0.43), Font.CR_DARKGRAY);
			y += LH();
			String sites = "";
			for (int p = 0; p < city.props.Size(); p++)
			{
				if (city.props[p].sub != sb) continue;
				let pr = city.props[p];
				String st = String.Format("%s %s", CW_City.TypeCode(pr.type), city.distCode[pr.district]);
				if (city.day < pr.damagedUntil) st = st .. " damaged";
				else if (city.day < pr.strikeUntil) st = st .. " strike";
				else if (city.day < pr.scandalUntil) st = st .. " scandal";
				sites = sites .. (sites.Length() ? ",  " : "") .. st;
			}
			if (sites.Length() && y + LH() <= bottom) { Txt(x + 12 * s, y, Fit(sites, w - 12 * s), Font.CR_DARKGRAY); y += LH(); }
		}
		int hidden = 0;
		for (int sb = 0; sb < city.subs.Size(); sb++) if (city.subs[sb].corp == c && city.subs[sb].shell && !city.subs[sb].shellKnown && c != city.patron) hidden++;
		if (hidden && y + LH() <= bottom) { Txt(x, y, String.Format("+ %d subsidiar%s the street doesn't know about", hidden, hidden == 1 ? "y" : "ies"), Font.CR_DARKGRAY); y += LH(); }
		return y;
	}

	double DrawMinor(CW_City city, int m, double x, double y, double w, double bottom)
	{
		let o = city.minors[m];
		int f = CW_City.MINOR_BASE + m;
		bool known = city.IntelFresh(o.turfKnownDay) || city.GetRep(f) >= 25;
		Txt(x, y, o.name, CW_City.FactionFont(f));
		String tag = o.dormant ? String.Format("DORMANT until day %d", o.dormantUntil) : o.kind;
		Txt(x + w - TW(tag), y, tag, o.dormant ? Font.CR_DARKGRAY : Font.CR_GRAY);
		y += LH() * 1.2;
		y = KV(x, y, w, "Your standing", String.Format("%s (%d)", CW_City.TierName(city.GetRep(f)), city.GetRep(f)), Font.CR_DARKGRAY, CW_City.TierFont(city.GetRep(f)));
		static const String svcs[] = { "blackmarket", "informants", "cheapintel", "safehouse" };
		static const String svcDesc[] = { "Black-market gear: quartermaster prices capped at 85%, and it sells even when Bastion Arms won't.",
			"Informants: free patrol schedules on jobs where Local 9 is strong (30+ turf).",
			"Cheap intel: corp intel for $300, and site intel when Candor won't sell.",
			"Safehouses: -8 heat on jobs in the Old Quarter and Ironside." };
		int si = 0;
		for (int k = 0; k < 4; k++) if (svcs[k] == o.service) si = k;
		bool open = city.MinorService(o.code);
		y = Wrapped(x, y, w, (open ? "\cdService open:\c- " : "\cuService at Friendly:\c- ") .. svcDesc[si], open ? Font.CR_GRAY : Font.CR_DARKGRAY);
		y += 6 * s;
		Txt(x, y, known ? "TURF BY DISTRICT (exact)" : "TURF BY DISTRICT (rough)", Font.CR_DARKGRAY); y += LH();
		double bw = w * 0.45;
		for (int d = 0; d < CW_City.NDIST; d++)
		{
			int t = o.turf[d];
			Txt(x, y, city.distName[d], Font.CR_GRAY);
			double bx = x + w * 0.42;
			Box(bx, y + 3 * s, bw, LH() - 7 * s, Color(30, 36, 46));
			int shown = known ? t : (t >= 60 ? 80 : t >= 30 ? 45 : t > 0 ? 15 : 0);
			if (shown) Box(bx, y + 3 * s, bw * shown / 100, LH() - 7 * s, Color(170, 120, 60));
			String v = known ? String.Format("%d", t) : (t >= 60 ? "strong" : t >= 30 ? "present" : t > 0 ? "weak" : "none");
			Txt(bx + bw + 8 * s, y, v, Font.CR_GRAY);
			y += LH();
		}
		y += 4 * s;
		Txt(x, y, "LEADERS AND STRONGHOLDS", Font.CR_DARKGRAY); y += LH();
		for (int e = 0; e < city.execs.Size(); e++)
		{
			let x2 = city.execs[e];
			if (x2.minor != m) continue;
			String st = x2.gone ? "out of the picture" : String.Format("%s, %s", x2.role, city.distName[x2.district]);
			y = KV(x, y, w, x2.name, st, Font.CR_WHITE, x2.gone ? Font.CR_DARKGRAY : Font.CR_GRAY);
		}
		for (int h = 0; h < city.holds.Size(); h++)
		{
			if (city.holds[h].minor != m) continue;
			bool act = city.HoldActive(h);
			y = KV(x, y, w, city.holds[h].name, String.Format("%s  %s", city.distCode[city.holds[h].district], act ? "held" : "abandoned"), Font.CR_GRAY, act ? Font.CR_GREEN : Font.CR_DARKGRAY);
		}
		y += 4 * s;
		Txt(x, y, "AGENDAS", Font.CR_DARKGRAY); y += LH();
		if (!known) { Txt(x, y, "Unknown. They talk to friends.", Font.CR_DARKGRAY); y += LH(); }
		else for (int a = 0; a < city.agendas.Size(); a++) if (city.agendas[a].owner == f) { Txt(x, y, Fit("- " .. city.agendas[a].text, w), Font.CR_TAN); y += LH(); }
		return y;
	}

	// ================================================================ MARKET
	void DrawMarket(CW_City city, double x, double top, double w, double bottom)
	{
		double y = top;
		Txt(x, y, "UPCOMING AUCTIONS   (Meridian runs the market; EarthGov guards seized property)", Font.CR_DARKGRAY); y += LH() + 2 * s;
		if (!city.listings.Size()) { Txt(x, y, "Nothing listed. Watch for corps sliding toward their credit limit.", Font.CR_DARKGRAY); y += LH(); }
		for (int i = 0; i < city.listings.Size(); i++)
		{
			let li = city.listings[i];
			if (y + LH() > bottom) break;
			String what = li.wholeSub ? city.subs[li.idx].name .. " (whole subsidiary)" : city.PropName(li.idx);
			String seller = li.seller >= 0 ? city.corps[li.seller].short : "Meridian";
			String right = String.Format("%s  /  day %d  /  reserve %dk", CW_City.ReasonName(li.reason), li.day, li.minPrice);
			Txt(x, y, Fit(String.Format("%s   from %s", what, seller), w - TW(right) - 16 * s), li.wholeSub ? Font.CR_GOLD : Font.CR_WHITE);
			Txt(x + w - TW(right), y, right, li.reason == 0 || li.reason == 4 ? Font.CR_ORANGE : Font.CR_GRAY);
			y += LH();
		}
		y += 8 * s;
		Box(x, y, w, max(1.0, s), line); y += 6 * s;
		Txt(x, y, "RESULTS", Font.CR_DARKGRAY); y += LH() + 2 * s;
		int n = city.marketLog.Size();
		if (!n) { Txt(x, y, "No sales yet.", Font.CR_DARKGRAY); return; }
		int vis = max(1, int((bottom - y) / LH()));
		scroll[TAB_MARKET] = clamp(scroll[TAB_MARKET], 0, max(0, n - vis));
		for (int i = n - 1 - scroll[TAB_MARKET]; i >= 0; i--)
		{
			if (y + LH() > bottom) break;
			Array<String> f;
			city.marketLog[i].Split(f, "\t");
			if (f.Size() < 2) continue;
			Txt(x, y, "Day " .. f[0], Font.CR_DARKGRAY);
			Txt(x + TW("Day 000  "), y, Fit(f[1], w - TW("Day 000  ")), Font.CR_GRAY);
			y += LH();
		}
	}

	// ================================================================ LEDGER
	double DrawLedger(CW_Ledger l, CW_City city, double x, double top, double w, double bottom)
	{
		double cw = (w - 30 * s) / 2, x2 = x + cw + 30 * s;
		Box(x + cw + 15 * s, top, max(1.0, s), bottom - top, line);
		double y = top;
		// ---- left: you
		if (city.outcome)
		{
			y = Wrapped(x, y, cw, (city.outcome == 1 ? "\cdCAMPAIGN WON\c-\n" : "\crCAMPAIGN LOST\c-\n") .. city.outcomeText, Font.CR_WHITE);
			y += 6 * s;
		}
		Txt(x, y, "THE CAMPAIGN", Font.CR_DARKGRAY); y += LH();
		y = KV(x, y, cw, "Day", String.Format("%d  (about 60 to decide the war)", city.day), Font.CR_GRAY, Font.CR_WHITE);
		y = KV(x, y, cw, "Jobs done", String.Format("%d contracts, %d odd jobs", city.jobsDone, city.oddJobsDone), Font.CR_GRAY, Font.CR_WHITE);
		y = KV(x, y, cw, "Budget", CW_Handler.Money(l.budget), Font.CR_GRAY, Font.CR_GREEN);
		y = KV(x, y, cw, "Owed to Meridian", String.Format("%s of %s", CW_Handler.Money(l.debt), CW_Handler.Money(CW_Ledger.MERIDIAN_LIMIT)), Font.CR_GRAY, l.debt > CW_Ledger.MERIDIAN_LIMIT * 3 / 4 ? Font.CR_RED : Font.CR_GRAY);
		y += 6 * s;
		Txt(x, y, "PATRONAGE", Font.CR_DARKGRAY); y += LH();
		if (city.patron >= 0)
			y = Wrapped(x, y, cw, String.Format("Pledged to %s. Its jobs pay 25%% more and its service is discounted; its allies treat you one tier friendlier. Win when it holds %d of %d subsidiaries or stands alone. Lose if it collapses.", city.corps[city.patron].name, CW_City.WIN_SUBS, city.subs.Size()), Font.CR_GRAY);
		else if (city.offer >= 0)
			y = Wrapped(x, y, cw, String.Format("\cd%s offers patronage.\c- Pledge [P] to back them in the war, or decline [D]. While pledged, jobs against them or their allies are refused.", city.corps[city.offer].name), Font.CR_WHITE);
		else
			y = Wrapped(x, y, cw, "Free agent. Reach Allied (75) with a corp and it will offer patronage. Win by putting your patron on top.", Font.CR_GRAY);
		y += 6 * s;
		Txt(x, y, "YOUR STANDING", Font.CR_DARKGRAY); y += LH();
		for (int i = 0; i < CW_City.NCORP + CW_City.NMINOR; i++)
		{
			int f = i < CW_City.NCORP ? i : CW_City.MINOR_BASE + i - CW_City.NCORP;
			int v = city.EffRep(f);
			Txt(x, y, city.FactionShort(f), CW_City.FactionFont(f));
			double bx = x + cw * 0.34, bw = cw * 0.40;
			Box(bx, y + 3 * s, bw, LH() - 7 * s, Color(30, 36, 46));
			Box(bx + bw / 2, y + 3 * s, max(1.0, s), LH() - 7 * s, line);
			double half = bw / 2 * abs(v) / 100.0;
			if (v >= 0) Box(bx + bw / 2, y + 3 * s, half, LH() - 7 * s, Color(70, 180, 90));
			else Box(bx + bw / 2 - half, y + 3 * s, half, LH() - 7 * s, Color(200, 70, 60));
			String t = String.Format("%s %d", CW_City.TierName(v), v);
			Txt(x + cw - TW(t), y, t, CW_City.TierFont(v));
			y += LH();
		}
		// ---- right: the war
		double yLeft = y;
		y = top;
		Txt(x2, y, String.Format("THE WAR: SUBSIDIARIES HELD (%d of %d wins)", CW_City.WIN_SUBS, city.subs.Size()), Font.CR_DARKGRAY); y += LH() + 2 * s;
		double bx = x2 + cw * 0.30, bw = cw * 0.55;
		for (int c = 0; c < CW_City.NCORP; c++)
		{
			let o = city.corps[c];
			int n = city.SubCount(c);
			Txt(x2, y, o.short .. (c == city.patron ? " *" : ""), o.alive ? CW_City.FactionFont(c) : Font.CR_DARKGRAY);
			Box(bx, y + 3 * s, bw, LH() - 7 * s, Color(30, 36, 46));
			if (n) Box(bx, y + 3 * s, bw * n / city.subs.Size(), LH() - 7 * s, CW_City.FactionColor(c));
			Box(bx + bw * CW_City.WIN_SUBS / city.subs.Size(), y + 1 * s, max(1.0, s * 2), LH() - 3 * s, amber);
			String v = o.alive ? String.Format("%d", n) : "gone";
			Txt(x2 + cw - TW(v), y, v, o.alive ? Font.CR_WHITE : Font.CR_DARKGRAY);
			y += LH() + 2 * s;
		}
		int rec = 0;
		for (int sb = 0; sb < city.subs.Size(); sb++) if (city.subs[sb].corp < 0) rec++;
		if (rec) { Txt(x2, y, String.Format("Meridian receivership: %d", rec), Font.CR_GOLD); y += LH(); }
		y += 8 * s;
		Txt(x2, y, "SERVICES AT YOUR STANDING", Font.CR_DARKGRAY); y += LH();
		static const String svc[] = { "intel", "crew", "weapons", "medical", "blackout", "fence" };
		static const String what[] = { "Intel (terminal)", "Crew (terminal)", "Weapons & gear", "Medical", "Grid contacts", "Fence (coming)" };
		for (int k = 0; k < 6; k++)
		{
			if (y + LH() > bottom) break;
			int pct = city.ServicePct(svc[k]);
			int owner = city.ServiceCorp(svc[k]);
			String v = pct ? String.Format("%s  %d%%", owner >= 0 ? city.corps[owner].short : "?", pct) : "closed to you";
			y = KV(x2, y, cw, String.Format("%s  (%s)", what[k], city.ServiceSub(svc[k])), v, Font.CR_GRAY, pct ? (pct < 100 ? Font.CR_GREEN : Font.CR_WHITE) : Font.CR_RED);
		}
		return max(y, yLeft);
	}

	// ================================================================ NEWS
	void DrawNews(CW_City city, double x, double top, double w, double bottom)
	{
		double y = top;
		Txt(x, y, "THE WIRE   newest first", Font.CR_DARKGRAY); y += LH() + 2 * s;
		int n = city.news.Size();
		int vis = max(1, int((bottom - y) / LH()));
		scroll[TAB_NEWS] = clamp(scroll[TAB_NEWS], 0, max(0, n - 1));
		int lastDay = -1;
		for (int i = n - 1 - scroll[TAB_NEWS]; i >= 0; i--)
		{
			Array<String> f;
			city.news[i].Split(f, "\t");
			if (f.Size() < 2) continue;
			int d = f[0].ToInt();
			if (d != lastDay)
			{
				if (y + LH() * 2 > bottom) break;
				y += 3 * s;
				Txt(x, y, "DAY " .. f[0], Font.CR_GOLD);
				y += LH();
				lastDay = d;
			}
			if (y + LH() > bottom) break;
			bool big = f[1].IndexOf("COLLAPSE") >= 0 || f[1].IndexOf("CAMPAIGN") >= 0 || f[1].IndexOf("FORECLOSURE") >= 0 || f[1].IndexOf("BETRAYAL") >= 0;
			y = Wrapped(x + 12 * s, y, w - 12 * s, f[1], big ? Font.CR_ORANGE : Font.CR_GRAY);
		}
	}

	// ================================================================ debrief
	// Returns the lowest y used (for the fit-to-height pass).
	double DrawDebrief(CW_Ledger l, double x, double top, double w, double bottom)
	{
		double colW = (w - 30 * s) / 2;
		double cx = x, y = top, maxY = top;
		for (int i = 0; i < l.debrief.Size(); i++)
		{
			String r = l.debrief[i];
			if (i == 0) { Txt(cx, y, r, Font.CR_GOLD); y += LH(); continue; }
			if (i == 1) { Txt(cx, y, r, Font.CR_WHITE); y += LH() + 6 * s; top = y; continue; }
			if (r == "@")
			{
				if (bottom < 1e8) Box(x + colW + 15 * s, top, max(1.0, s), bottom - top, line);
				cx = x + colW + 30 * s;
				maxY = max(maxY, y);
				y = top;
				continue;
			}
			if (y + LH() > bottom) continue;
			if (r.Left(1) == "#")
			{
				y += 4 * s;
				Txt(cx, y, r.Mid(1), Font.CR_DARKGRAY);
				Box(cx, y + LH() - 3 * s, colW, max(1.0, s), line);
				y += LH() + 2 * s;
				continue;
			}
			int tb = r.IndexOf("\t");
			if (tb >= 0)
			{
				// label left, value right; a label too long for the gap wraps onto more lines
				String a = r.Left(tb), b = r.Mid(tb + 1);
				Txt(cx + colW - TW(b), y, b, Font.CR_WHITE);
				y = Wrapped(cx, y, colW - TW(b) - 14 * s, a, Font.CR_GRAY);
				continue;
			}
			y = Wrapped(cx, y, colW, r, Font.CR_WHITE);
		}
		return max(maxY, y);
	}
}
