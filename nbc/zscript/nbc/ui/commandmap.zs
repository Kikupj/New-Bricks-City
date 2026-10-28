// The command map (Ghost Recon's planning map, PLAN.md M6; NBC_Orders): a top-down view of the district with
// your officers, what the squad has spotted, the exit, and each fireteam's waypoint path. It runs in real time,
// as Ghost Recon's did: the raid doesn't stop while you plan.
//   left panel   who your keys talk to (ALL / ALPHA / BRAVO); the team you're editing, its members, its order
//                (FOLLOW / HOLD / ADVANCE) and rules of engagement (RECON / ASSAULT / SUPPRESS); the selected
//                waypoint's go code; the three go codes to call
//   the map      click: add a waypoint for the team you're editing (or pick one); drag: pan; wheel: zoom;
//                right click on a waypoint: delete it. Keyboard: with the map selected the arrows pan,
//                Enter drops a waypoint at the crosshair, Esc goes back to the panel.

class NBC_CommandMap : NBC_UI
{
	enum EId
	{
		ID_CLOSE = 1, ID_SELECT, ID_EDIT, ID_ORDER, ID_ROE, ID_CLEAR, ID_WPGO, ID_WPDEL, ID_CALL, ID_MAP, ID_CENTER
	}
	const MX = 274;
	const MY = 66;
	const MW = 670;
	const MH = 470;

	int editTeam;
	int selWp;               // index into the waypoint list (NBC_RunData.wpX...), -1 none
	double camX, camY, zoom; // the map: centre in world units, world units per canvas pixel
	bool camSet;
	// dragging the map
	bool lDown, dragging;
	int downX, downY;
	double downCamX, downCamY;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		selWp = -1;
		zoom = 4.0;
		let rd = NBC_RunData.Find();
		editTeam = rd && rd.cmdTeam == NBC_Orders.CT_BRAVO ? 1 : 0;
		focusId = ID_MAP; focusArg = 0; focusSet = true;
	}

	bool OnRaid()
	{
		let rm = RM();
		let rd = NBC_RunData.Find();
		return rm && rd && rm.IsRaidMap(rd) && rd.teamOrder.Size() == NBC_Orders.TEAMS;
	}

	static void Cmd(int op, int a = 0, int b = 0, int c = 0)
	{
		EventHandler.SendNetworkEvent(String.Format("nbc_cmd.%d", op), a, b, c);
	}

	// ------------------------------------------------------------ map coordinates

	double MapToCanvasX(double wx) { return MX + MW / 2 + (wx - camX) / zoom; }
	double MapToCanvasY(double wy) { return MY + MH / 2 - (wy - camY) / zoom; }
	double CanvasToMapX(double vx) { return camX + (vx - MX - MW / 2) * zoom; }
	double CanvasToMapY(double vy) { return camY - (vy - MY - MH / 2) * zoom; }
	bool InMap(double vx, double vy) { return vx >= MX && vx < MX + MW && vy >= MY && vy < MY + MH; }

	// the waypoint under a canvas point (any team's), -1 none
	int WaypointAt(double vx, double vy)
	{
		let rd = NBC_RunData.Find();
		if (!rd) return -1;
		for (int i = rd.wpX.Size() - 1; i >= 0; i--)
			if (abs(MapToCanvasX(rd.wpX[i]) - vx) < 9 && abs(MapToCanvasY(rd.wpY[i]) - vy) < 9) return i;
		return -1;
	}

	void PlaceAt(double vx, double vy)
	{
		int w = WaypointAt(vx, vy);
		if (w >= 0) { selWp = w; let rd = NBC_RunData.Find(); if (rd) editTeam = rd.wpTeam[w]; return; }
		let rd = NBC_RunData.Find();
		if (!rd || NBC_Orders.WaypointCount(rd, editTeam) >= NBC_Orders.MAX_WAYPOINTS) { MenuSound("menu/invalid"); return; }
		Cmd(NBC_Orders.CMD_WP_ADD, editTeam, int(CanvasToMapX(vx)), int(CanvasToMapY(vy)));
		selWp = rd.wpX.Size();      // the new one, once the netevent has run
		MenuSound("menu/choose");
	}

	// ------------------------------------------------------------ input

	override bool OnUIEvent(UIEvent ev)
	{
		Layout();
		double vx = VX(ev.MouseX), vy = VY(ev.MouseY);
		switch (ev.Type)
		{
		case UIEvent.Type_LButtonDown:
			if (InMap(vx, vy) && OnRaid())
			{
				lDown = true; dragging = false;
				downX = ev.MouseX; downY = ev.MouseY; downCamX = camX; downCamY = camY;
				focusId = ID_MAP; focusArg = 0; focusSet = true;
				return true;
			}
			break;
		case UIEvent.Type_MouseMove:
			if (lDown)
			{
				if (abs(ev.MouseX - downX) + abs(ev.MouseY - downY) > 5) dragging = true;
				if (dragging)
				{
					camX = downCamX - (ev.MouseX - downX) / sc * zoom;
					camY = downCamY + (ev.MouseY - downY) / sc * zoom;
				}
				return true;
			}
			break;
		case UIEvent.Type_LButtonUp:
			if (lDown)
			{
				lDown = false;
				if (!dragging) PlaceAt(vx, vy);
				dragging = false;
				return true;
			}
			break;
		case UIEvent.Type_RButtonDown:
			if (InMap(vx, vy) && OnRaid())
			{
				int w = WaypointAt(vx, vy);
				if (w >= 0) { Cmd(NBC_Orders.CMD_WP_DEL, w); selWp = -1; MenuSound("menu/backup"); return true; }
			}
			break;
		case UIEvent.Type_WheelUp:
		case UIEvent.Type_WheelDown:
			if (InMap(vx, vy))
			{
				// zoom about the pointer
				double wx = CanvasToMapX(vx), wy = CanvasToMapY(vy);
				zoom = clamp(zoom * (ev.Type == UIEvent.Type_WheelUp ? 0.8 : 1.25), 0.8, 24);
				camX = wx - (vx - MX - MW / 2) * zoom;
				camY = wy + (vy - MY - MH / 2) * zoom;
				return true;
			}
			break;
		}
		return Super.OnUIEvent(ev);
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		// the map selected: the arrows pan it, Enter drops a waypoint at the crosshair
		if (focusId == ID_MAP && OnRaid())
		{
			double step = 48 * zoom;
			switch (mkey)
			{
			case MKEY_Up: camY += step; return true;
			case MKEY_Down: camY -= step; return true;
			case MKEY_Left: camX -= step; return true;
			case MKEY_Right: camX += step; return true;
			case MKEY_PageUp: zoom = max(0.8, zoom * 0.8); return true;
			case MKEY_PageDown: zoom = min(24, zoom * 1.25); return true;
			case MKEY_Enter: PlaceAt(MX + MW / 2, MY + MH / 2); return true;
			}
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool Back()
	{
		// from the map back to the panel first
		if (focusId == ID_MAP) { focusId = ID_ORDER; focusArg = 0; return true; }
		return false;
	}

	override void SwitchTab(int dir)
	{
		editTeam = 1 - editTeam;
		selWp = -1;
		MenuSound("menu/change");
	}

	override void Activate(int id, int arg)
	{
		let rd = NBC_RunData.Find();
		switch (id)
		{
		case ID_CLOSE: Leave(); return;
		case ID_SELECT: Cmd(NBC_Orders.CMD_SELECT, arg); if (arg > 0) editTeam = arg - 1; return;
		case ID_EDIT: editTeam = arg; selWp = -1; return;
		case ID_ORDER:
			if (arg == NBC_Orders.ORD_FOLLOW) Cmd(NBC_Orders.CMD_FOLLOW, editTeam);
			else if (arg == NBC_Orders.ORD_HOLD) Cmd(NBC_Orders.CMD_HOLD, editTeam);
			else if (arg == NBC_Orders.ORD_ADVANCE) Cmd(NBC_Orders.CMD_ADVANCE, editTeam);
			return;
		case ID_ROE: Cmd(NBC_Orders.CMD_ROE, editTeam, arg); return;
		case ID_CLEAR: Cmd(NBC_Orders.CMD_WP_CLEAR, editTeam); selWp = -1; return;
		case ID_WPGO:
			if (rd && selWp >= 0 && selWp < rd.wpGo.Size()) Cmd(NBC_Orders.CMD_WP_GO, selWp, (rd.wpGo[selWp] + 1) % NBC_Orders.GO_COUNT);
			return;
		case ID_WPDEL:
			if (rd && selWp >= 0 && selWp < rd.wpGo.Size()) { Cmd(NBC_Orders.CMD_WP_DEL, selWp); selWp = -1; }
			return;
		case ID_CALL: Cmd(NBC_Orders.CMD_GO, -1, arg); return;
		case ID_CENTER: camSet = false; return;
		case ID_MAP: PlaceAt(MX + MW / 2, MY + MH / 2); return;
		}
	}

	// ------------------------------------------------------------ drawing

	override void DrawScreen()
	{
		let rd = NBC_RunData.Find();
		let rm = RM();
		Backdrop();
		String sub = rm && rd ? String.Format("%s  -  real time: the raid goes on while you plan", rm.TurfTitle(rd.raidDistrict)) : "";
		TopBar("COMMAND MAP", sub);
		if (!OnRaid())
		{
			Panel(VW / 2 - 260, 220, 520, 140, "NO SQUAD HERE");
			Text(NewSmallFont, Font.CR_WHITE, VW / 2, 270, "The command map works on a raid, with your squad on the ground.", 12, 1);
			Button(ID_CLOSE, 0, VW / 2 - 70, 306, 140, 36, "CLOSE", true, 15);
			return;
		}
		let p = players[consoleplayer].mo;
		if (!camSet && p) { camSet = true; camX = p.pos.x; camY = p.pos.y; }
		if (selWp >= rd.wpX.Size()) selWp = -1;

		DrawPanel(rd, rm);
		DrawMap(rd, rm);
		Text(NewSmallFont, Font.CR_GRAY, 18, VH - 22,
			"MAP: click  add waypoint     drag  pan     wheel  zoom     right click  delete     Q / E  switch team     ESC  back / close", 10);
	}

	void DrawPanel(NBC_RunData rd, NBC_RunManager rm)
	{
		Panel(16, 66, 246, 470, "");
		// who the keys talk to
		Text(NewSmallFont, Font.CR_GRAY, 28, 74, "YOUR KEYS TALK TO", 10);
		static const String sel[] = { "ALL", "ALPHA", "BRAVO" };
		for (int i = 0; i < 3; i++)
		{
			bool on = rd.cmdTeam == i;
			Button(ID_SELECT, i, 28 + i * 76, 88, 70, 26, sel[i], true, 11, on ? C_AMBER : -1);
			if (on) Frame(28 + i * 76, 88, 70, 26, C_AMBER, 1);
		}

		// the team being edited: tabs, members
		for (int t = 0; t < NBC_Orders.TEAMS; t++)
		{
			bool on = editTeam == t;
			double tx = 28 + t * 114;
			Fill(tx, 124, 108, 26, on ? 0x2E3E52 : 0x18212C);
			Fill(tx, 124, 108, 3, NBC_Orders.TEAM_COLOR[t]);
			Text(BigFont, on ? Font.CR_WHITE : Font.CR_GRAY, tx + 54, 132, NBC_Orders.TEAM_NAME[t], 13, 1);
			Region(ID_EDIT, t, tx, 124, 108, 26);
			if (IsFocus(ID_EDIT, t)) FocusFrame(tx, 124, 108, 26);
		}
		Inset(28, 150, 222, 96);
		let dept = NBC_Department.Find();
		int row = 0;
		for (int s = 0; s < rm.squad.Size(); s++)
		{
			let a = NBC_Ally(rm.squad[s]);
			if (!a || rd.TeamOfSlot(a.slot) != editTeam) continue;
			let o = dept ? dept.OfficerById(a.officerId) : null;
			double y = 156 + row * 22;
			if (o) Pic(o.Portrait(), 34, y, 18, 18, a.health > 0 ? 1.0 : 0.4, a.health <= 0);
			Text(NewSmallFont, a.health > 0 ? Font.CR_WHITE : Font.CR_DARKGRAY, 58, y + 3, a.health > 0 ? a.GetTag() : a.GetTag() .. "  DOWN", 10);
			double frac = clamp(a.health / double(max(1, a.maxHp)), 0, 1);
			Fill(196, y + 7, 46, 4, C_PANEL_LO);
			Fill(196, y + 7, 46 * frac, 4, frac > 0.6 ? C_GREEN : (frac > 0.3 ? C_AMBER : C_RED));
			row++;
		}
		if (!row) Text(NewSmallFont, Font.CR_DARKGRAY, 139, 190, "nobody on this team", 10, 1);

		// orders
		int order = rd.teamOrder[editTeam];
		Text(NewSmallFont, Font.CR_GRAY, 28, 254, "ORDER", 10);
		static const int orders[] = { NBC_Orders.ORD_FOLLOW, NBC_Orders.ORD_HOLD, NBC_Orders.ORD_ADVANCE };
		for (int i = 0; i < 3; i++)
		{
			int o = orders[i];
			bool on = order == o || (o == NBC_Orders.ORD_HOLD && order == NBC_Orders.ORD_MOVE);
			Button(ID_ORDER, o, 28 + i * 76, 268, 70, 28, NBC_Orders.ORDER_NAME[o], true, 10, on ? NBC_Orders.TEAM_COLOR[editTeam] : -1);
			if (on) Frame(28 + i * 76, 268, 70, 28, NBC_Orders.TEAM_COLOR[editTeam], 1);
		}
		if (order == NBC_Orders.ORD_MOVE) Text(NewSmallFont, Font.CR_GRAY, 28, 300, "Moving to your marker (V in the field).", 9);

		// rules of engagement
		int roe = rd.teamROE[editTeam];
		Text(NewSmallFont, Font.CR_GRAY, 28, 314, "RULES OF ENGAGEMENT", 10);
		for (int i = 0; i < NBC_Orders.ROE_COUNT; i++)
		{
			bool on = roe == i;
			Button(ID_ROE, i, 28 + i * 76, 328, 70, 28, NBC_Orders.ROE_NAME[i], true, 8.5, on ? C_AMBER : -1);
			if (on) Frame(28 + i * 76, 328, 70, 28, C_AMBER, 1);
		}
		static const String roeHelp[] = { "Weapons tight: return fire only. Slow, quiet.", "Weapons free: engage at will.", "Long bursts, fire on last-seen spots." };
		Text(NewSmallFont, Font.CR_GRAY, 28, 360, roeHelp[roe], 9);

		// the path
		int n = NBC_Orders.WaypointCount(rd, editTeam);
		Text(NewSmallFont, Font.CR_GRAY, 28, 380, String.Format("PATH  %d / %d waypoints", n, NBC_Orders.MAX_WAYPOINTS), 10);
		Button(ID_CLEAR, 0, 28, 394, 108, 26, "CLEAR PATH", n > 0, 10, C_RED);
		bool hasSel = selWp >= 0 && selWp < rd.wpX.Size();
		Button(ID_WPDEL, 0, 142, 394, 108, 26, "DELETE WP", hasSel, 10);
		String goLbl = hasSel ? String.Format("GO CODE: %s", rd.wpGo[selWp] ? NBC_Orders.GO_NAME[rd.wpGo[selWp]] : "NONE") : "GO CODE: -";
		Button(ID_WPGO, 0, 28, 424, 222, 26, goLbl, hasSel, 11, hasSel && rd.wpGo[selWp] ? C_AMBER : -1);

		// calling the go codes
		Text(NewSmallFont, Font.CR_GRAY, 28, 458, "CALL A GO CODE", 10);
		for (int g = NBC_Orders.GO_XRAY; g <= NBC_Orders.GO_ZULU; g++)
		{
			bool called = rd.goCalled[g];
			Button(ID_CALL, g, 28 + (g - 1) * 76, 472, 70, 28, NBC_Orders.GO_NAME[g], !called, 10, C_AMBER);
			if (called) Text(NewSmallFont, Font.CR_GREEN, 63 + (g - 1) * 76, 503, "called", 9, 1);
		}
		Button(ID_CENTER, 0, 150, 506, 100, 24, "ON ME", true, 10);
		Button(ID_CLOSE, 0, 28, 506, 100, 24, "CLOSE", true, 10);
	}

	void DrawMap(NBC_RunData rd, NBC_RunManager rm)
	{
		Inset(MX, MY, MW, MH);
		int cx0 = PX(MX + 1), cy0 = PY(MY + 1), cx1 = PX(MX + MW - 1), cy1 = PY(MY + MH - 1);
		Screen.SetClipRect(cx0, cy0, cx1 - cx0, cy1 - cy0);
		// faint grid every 512 units
		double gx0 = floor(CanvasToMapX(MX) / 512) * 512, gy0 = floor(CanvasToMapY(MY + MH) / 512) * 512;
		for (double gx = gx0; MapToCanvasX(gx) < MX + MW; gx += 512) MapLine(gx, CanvasToMapY(MY), gx, CanvasToMapY(MY + MH), 0x182230);
		for (double gy = gy0; MapToCanvasY(gy) > MY; gy += 512) MapLine(CanvasToMapX(MX), gy, CanvasToMapX(MX + MW), gy, 0x182230);

		// the walls
		double wx0 = CanvasToMapX(MX), wx1 = CanvasToMapX(MX + MW), wy1 = CanvasToMapY(MY), wy0 = CanvasToMapY(MY + MH);
		for (int i = 0; i < level.Lines.Size(); i++)
		{
			Line ln = level.Lines[i];
			Vector2 a = ln.v1.p, b = ln.v2.p;
			if (max(a.x, b.x) < wx0 || min(a.x, b.x) > wx1 || max(a.y, b.y) < wy0 || min(a.y, b.y) > wy1) continue;
			int col;
			if (!ln.backsector) col = 0x8FA6BE;
			else
			{
				double df = abs(ln.frontsector.floorplane.ZAtPoint(a) - ln.backsector.floorplane.ZAtPoint(a));
				if (df > 24) col = 0x51647A;
				else if (zoom < 3) col = 0x26323F;
				else continue;
			}
			MapLine(a.x, a.y, b.x, b.y, col);
		}

		// the exit
		if (rm.exitFound)
		{
			double ex = MapToCanvasX(rm.exitPos.x), ey = MapToCanvasY(rm.exitPos.y);
			Frame(ex - 6, ey - 6, 12, 12, C_GREEN, 2);
			Text(NewSmallFont, Font.CR_GREEN, ex + 9, ey - 5, "EXIT", 10);
		}

		// what the squad has spotted
		let ord = NBC_Orders.Get();
		if (ord)
			for (int i = 0; i < ord.contacts.Size(); i++)
			{
				Actor m = ord.contacts[i];
				if (!m) continue;
				double ex = MapToCanvasX(m.pos.x), ey = MapToCanvasY(m.pos.y);
				Fill(ex - 3, ey - 1, 7, 2, C_RED); Fill(ex - 1, ey - 3, 2, 7, C_RED);
			}

		// each team's path: from its lead officer through the waypoints
		for (int t = 0; t < NBC_Orders.TEAMS; t++)
		{
			int col = NBC_Orders.TEAM_COLOR[t];
			double lx = 0, ly = 0;
			bool have = false;
			for (int s = 0; s < rm.squad.Size() && !have; s++)
			{
				let a = rm.squad[s] ? NBC_Ally(rm.squad[s]) : null;
				if (a && a.health > 0 && rd.TeamOfSlot(a.slot) == t) { lx = a.pos.x; ly = a.pos.y; have = true; }
			}
			int n = NBC_Orders.WaypointCount(rd, t);
			for (int k = 0; k < n; k++)
			{
				int wi = NBC_Orders.WaypointIndex(rd, t, k);
				double wx = rd.wpX[wi], wy = rd.wpY[wi];
				if (have) MapLine(lx, ly, wx, wy, col, t == editTeam ? 255 : 120);
				lx = wx; ly = wy; have = true;
				double px = MapToCanvasX(wx), py = MapToCanvasY(wy);
				bool on = wi == selWp;
				Fill(px - 7, py - 7, 14, 14, on ? C_AMBER : col, t == editTeam ? 1.0 : 0.5);
				Fill(px - 5, py - 5, 10, 10, C_INSET);
				Text(NewSmallFont, Font.CR_WHITE, px, py - 5, String.Format("%d", k + 1), 9, 1);
				if (rd.wpGo[wi])
				{
					String code = NBC_Orders.GO_NAME[rd.wpGo[wi]];
					Text(NewSmallFont, rd.goCalled[rd.wpGo[wi]] ? Font.CR_GREEN : Font.CR_GOLD, px + 10, py - 5, code, 9);
				}
			}
			// a MOVE goal
			if (rd.teamOrder[t] == NBC_Orders.ORD_MOVE)
			{
				double gx = MapToCanvasX(rd.teamGX[t]), gy = MapToCanvasY(rd.teamGY[t]);
				Frame(gx - 5, gy - 5, 10, 10, col, 2);
			}
		}

		// the officers and you
		for (int s = 0; s < rm.squad.Size(); s++)
		{
			let a = NBC_Ally(rm.squad[s]);
			if (!a) continue;
			int col = a.health > 0 ? NBC_Orders.TEAM_COLOR[rd.TeamOfSlot(a.slot)] : C_GREY;
			double ax = MapToCanvasX(a.pos.x), ay = MapToCanvasY(a.pos.y);
			Fill(ax - 4, ay - 4, 8, 8, 0);
			Fill(ax - 3, ay - 3, 6, 6, col);
			Text(NewSmallFont, Font.CR_WHITE, ax + 6, ay - 4, String.Format("%d", a.slot + 1), 8);
		}
		let p = players[consoleplayer].mo;
		if (p)
		{
			double ppx = MapToCanvasX(p.pos.x), ppy = MapToCanvasY(p.pos.y);
			Vector2 f = Actor.AngleToVector(p.angle, 9), r = Actor.AngleToVector(p.angle + 140, 7), l = Actor.AngleToVector(p.angle - 140, 7);
			Screen.DrawThickLine(PX(ppx + f.x), PY(ppy - f.y), PX(ppx + r.x), PY(ppy - r.y), 2 * sc, RGB(0xFFFFFF));
			Screen.DrawThickLine(PX(ppx + f.x), PY(ppy - f.y), PX(ppx + l.x), PY(ppy - l.y), 2 * sc, RGB(0xFFFFFF));
			Screen.DrawThickLine(PX(ppx + r.x), PY(ppy - r.y), PX(ppx + l.x), PY(ppy - l.y), 2 * sc, RGB(0xFFFFFF));
		}

		// the crosshair (keyboard placing)
		bool mapFocus = focusId == ID_MAP;
		Fill(MX + MW / 2 - 8, MY + MH / 2, 16, 1, mapFocus ? C_AMBER : C_GREY, mapFocus ? 0.9 : 0.4);
		Fill(MX + MW / 2, MY + MH / 2 - 8, 1, 16, mapFocus ? C_AMBER : C_GREY, mapFocus ? 0.9 : 0.4);
		Screen.ClearClipRect();

		// the map is a control too (keyboard: select it to pan and drop waypoints)
		Region(ID_MAP, 0, MX, MY, MW, MH);
		if (mapFocus) Frame(MX - 2, MY - 2, MW + 4, MH + 4, C_AMBER, 2, 0.8);
		Text(NewSmallFont, NBC_Orders.TEAM_COLOR[editTeam] == NBC_Orders.TEAM_COLOR[0] ? Font.CR_CYAN : Font.CR_GOLD, MX + 10, MY + 8,
			String.Format("Plotting for %s", NBC_Orders.TEAM_NAME[editTeam]), 11);
		Text(NewSmallFont, Font.CR_DARKGRAY, MX + MW - 10, MY + MH - 18, String.Format("1 square = 512 units   zoom %.1f", zoom), 9, 2);
	}

	void MapLine(double ax, double ay, double bx, double by, int col, int alpha = 255)
	{
		Screen.DrawLine(PX(MapToCanvasX(ax)), PY(MapToCanvasY(ay)), PX(MapToCanvasX(bx)), PY(MapToCanvasY(by)), RGB(col), alpha);
	}
}
