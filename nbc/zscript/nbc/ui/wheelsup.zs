// Roll out (owner requests, 2026-10-28): the last step before a raid, at the pilot. READY on the deploy screen
// plans the raid; talking to Rook brings this up:
//   INSERTION   STREET (the land vehicles; the raid starts on the street) or ROOFTOP (a helicopter; the raid starts
//               on the district's rooftop map, with the shoot-down risk shown: shot down means a crash landing)
//   MOTORCADE   the garage: pick the vehicles that go (AUTO picks enough seats); the seats have to carry everyone
//   GOING IN    you and the squad
// ROLL OUT / WHEELS UP starts the raid, CHANGE PLAN goes back to the deploy screen, NOT YET walks away.

class NBC_WheelsUp : NBC_UI
{
	enum EId { ID_GO = 1, ID_PLAN, ID_NOTYET, ID_INSERT, ID_ROLL, ID_AUTO }

	override void Init(Menu parent)
	{
		Super.Init(parent);
		focusId = ID_GO; focusArg = 0; focusSet = true;
		// nothing picked that fits? pick for them
		let dept = NBC_Department.Find();
		if (dept && dept.Seats(dept.insertion) < dept.SeatsNeeded()) Send(NBC_Department.OP_AUTO_MOTORCADE);
	}

	override void Activate(int id, int arg)
	{
		let rd = NBC_RunData.Find();
		if (!rd) return;
		switch (id)
		{
		case ID_GO:
			EventHandler.SendNetworkEvent("nbc_deploy", rd.readyDistrict);
			LeaveAll();
			return;
		case ID_PLAN:
		{
			int d = rd.readyDistrict;
			Close();
			NBC_DeployMenu.Open(null, d);
			return;
		}
		case ID_NOTYET: Leave(); return;
		case ID_INSERT: Send(NBC_Department.OP_INSERTION, 0, arg); return;
		case ID_ROLL: Send(NBC_Department.OP_ROLL, arg); return;
		case ID_AUTO: Send(NBC_Department.OP_AUTO_MOTORCADE); return;
		}
	}

	override void DrawScreen()
	{
		let rd = NBC_RunData.Find();
		let rm = RM();
		let dept = NBC_Department.Find();
		Fill(0, 0, VW, VH, 0, 0.55);
		if (!rd || !rm || !dept || rd.readyDistrict < 0)
		{
			Panel(VW / 2 - 220, 240, 440, 120, "NOTHING PLANNED");
			Button(ID_NOTYET, 0, VW / 2 - 70, 300, 140, 36, "CLOSE", true, 14);
			return;
		}
		int d = rd.readyDistrict;
		let g = rm.DistrictGang(rd, d);
		bool roof = dept.insertion == NBC_Motor.INS_ROOFTOP;
		double x = 50, y = 30, w = VW - 100, h = 540;
		Panel(x, y, w, h, roof ? "WHEELS UP?" : "ROLL OUT?");

		// where to
		Inset(x + 16, y + 36, 420, 128);
		Text(BigFont, Font.CR_WHITE, x + 28, y + 44, rm.TurfTitle(d).MakeUpper(), 20);
		Text(NewSmallFont, Font.CR_GRAY, x + 30, y + 68, NBC_Terminal.EnvName(rm.TurfEnv(d)), 10);
		if (g)
		{
			Text(BigFont, g.TextColor(), x + 30, y + 84, g.name.MakeUpper(), 13);
			Text(NewSmallFont, Font.CR_GRAY, x + 30, y + 102, String.Format("Leader: %s.  About %d on the block.", g.leaderTitle, rm.CrewEstimate(rd, d)), 10);
			Wrap(NewSmallFont, Font.CR_WHITE, x + 30, y + 120, 396, g.trait, 10, 2);
		}

		// how: the insertion
		double ix = x + 452, iw = w - 468;
		Text(NewSmallFont, Font.CR_GRAY, ix, y + 36, "INSERTION", 10);
		bool heli = dept.HasHeli();
		Button(ID_INSERT, NBC_Motor.INS_STREET, ix, y + 50, iw / 2 - 4, 40, "STREET", true, 15, !roof ? C_AMBER : -1);
		if (!roof) Frame(ix, y + 50, iw / 2 - 4, 40, C_AMBER, 2);
		Button(ID_INSERT, NBC_Motor.INS_ROOFTOP, ix + iw / 2 + 4, y + 50, iw / 2 - 4, 40, "ROOFTOP", heli, 15, roof ? C_AMBER : -1);
		if (roof) Frame(ix + iw / 2 + 4, y + 50, iw / 2 - 4, 40, C_AMBER, 2);
		String how;
		int risk = 0;
		if (roof)
		{
			let hv = dept.RollingHeli();
			int gi = rd.districtGang[d];
			int alert = gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
			risk = hv && g ? NBC_Motor.ShootDownRisk(g.tier, alert, hv.cond) : 0;
			how = String.Format("Rook flies you onto the roofs of %s: 20%% fewer of them up there. Shot down, it's a crash landing in the street and they come for the wreck.", rm.TurfTitle(d));
		}
		else how = heli ? "The motorcade drives you in; the raid starts on the street." : "The motorcade drives you in; the raid starts on the street. (Buy a helicopter at the motor pool for rooftop insertions.)";
		Wrap(NewSmallFont, Font.CR_WHITE, ix, y + 98, iw, how, 10, 2);
		if (roof)
		{
			Text(NewSmallFont, Font.CR_GRAY, ix, y + 146, "SHOOT-DOWN RISK", 10);
			Text(BigFont, risk >= 30 ? Font.CR_RED : (risk >= 15 ? Font.CR_GOLD : Font.CR_GREEN), ix + iw, y + 142, String.Format("%d%%", risk), 15, 2);
		}

		// the motorcade
		double my = y + 176;
		int seats = dept.Seats(dept.insertion), need = dept.SeatsNeeded();
		Text(NewSmallFont, Font.CR_GRAY, x + 16, my, "MOTORCADE", 10);
		Text(NewSmallFont, seats >= need ? Font.CR_GREEN : Font.CR_RED, x + 120, my, String.Format("SEATS %d / %d NEEDED", seats, need), 10);
		Button(ID_AUTO, 0, x + w - 16 - 70, my - 4, 70, 20, "AUTO", true, 10);
		for (int i = 0; i < dept.garage.Size(); i++)
		{
			let v = dept.garage[i];
			double cx = x + 16 + i * 106, cy = my + 18;
			bool fits = dept.Fits(v, dept.insertion);
			bool on = v.rolling && fits;
			bool f = IsFocus(ID_ROLL, v.id);
			Inset(cx, cy, 100, 104, on ? C_AMBER : -1);
			Pic(NBC_Motor.TYPE_ART[v.type], cx + 6, cy + 6, 88, 44, fits ? 1.0 : 0.3, !fits);
			Text(NewSmallFont, on ? Font.CR_GOLD : (fits ? Font.CR_WHITE : Font.CR_DARKGRAY), cx + 50, cy + 54, NBC_Motor.TYPE_SHORT[v.type], 10, 1);
			Text(NewSmallFont, Font.CR_GRAY, cx + 50, cy + 68, String.Format("%d seats", v.Seats()), 9, 1);
			Text(NewSmallFont, v.Ready() ? Font.CR_GRAY : Font.CR_RED, cx + 50, cy + 80, v.Ready() ? String.Format("%d%%", v.cond) : "IN THE SHOP", 9, 1);
			if (on) Text(BigFont, Font.CR_GOLD, cx + 94, cy + 4, "IN", 10, 2);
			Region(ID_ROLL, v.id, cx, cy, 100, 104);
			if (f) FocusFrame(cx, cy, 100, 104);
		}

		// who's going
		double gy = my + 136;
		Text(NewSmallFont, Font.CR_GRAY, x + 16, gy, "GOING IN", 10);
		double cx = x + 16;
		Inset(cx, gy + 14, 90, 112, C_AMBER_DIM);
		Pic(dept.PlayerPortrait(), cx + 7, gy + 20, 76, 76);
		Text(NewSmallFont, Font.CR_WHITE, cx + 45, gy + 98, "Det. Vance", 9, 1);
		Text(NewSmallFont, Font.CR_GOLD, cx + 45, gy + 110, NBC_DeployMenu.KitLine(dept.pPrimary, dept.pSidearm), 7, 1);
		cx += 98;
		for (int s = 0; s < dept.squad.Size(); s++)
		{
			let o = dept.OfficerById(dept.squad[s]);
			if (!o) continue;
			Inset(cx, gy + 14, 90, 112, NBC_Orders.TEAM_COLOR[o.team == NBC_Orders.TEAM_ALPHA ? 0 : 1]);
			Pic(o.Portrait(), cx + 7, gy + 20, 76, 76);
			Text(NewSmallFont, Font.CR_WHITE, cx + 45, gy + 98, o.RankedName(), 9, 1);
			Text(NewSmallFont, Font.CR_GRAY, cx + 45, gy + 110, String.Format("%s - %s", o.ClassName(), o.team == NBC_Orders.TEAM_ALPHA ? "A" : "B"), 7, 1);
			cx += 98;
		}
		if (!dept.squad.Size()) Text(NewSmallFont, Font.CR_RED, x + 120, gy + 60, "No officers with you. You're going in alone.", 12);

		// go?
		bool canGo = rm.IsHub() && !rd.raidActive && rd.caseActive && g && !rm.DistrictTaken(rd, d) && seats >= need;
		String why = seats < need ? String.Format("Not enough seats: %d going in, %d in the motorcade. Pick another vehicle or bench someone.", need, seats)
			: String.Format("Day %d of %d. A raid takes the day.", rd.day, NBC_RunData.MAX_DAYS);
		Text(NewSmallFont, seats < need ? Font.CR_RED : Font.CR_GRAY, x + 16, y + h - 82, why, 11);
		Button(ID_NOTYET, 0, x + 16, y + h - 60, 140, 44, "NOT YET", true, 15);
		Button(ID_PLAN, 0, x + 166, y + h - 60, 180, 44, "CHANGE PLAN", true, 15);
		Button(ID_GO, 0, x + w - 16 - 240, y + h - 60, 240, 44, roof ? "WHEELS UP" : "ROLL OUT", canGo, 21, C_AMBER);
	}
}
