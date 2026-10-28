// The pilot's wheels-up check (owner request, 2026-10-28): the last step before a raid. READY on the deploy
// screen plans the raid; talking to the pilot brings this up: where you're going, who's going, what you're
// carrying. WHEELS UP starts the raid, CHANGE PLAN goes back to the deploy screen, NOT YET walks away.

class NBC_WheelsUp : NBC_UI
{
	enum EId { ID_GO = 1, ID_PLAN, ID_NOTYET }

	override void Init(Menu parent)
	{
		Super.Init(parent);
		focusId = ID_GO; focusArg = 0; focusSet = true;
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
		double x = 150, y = 70, w = VW - 300, h = 460;
		Panel(x, y, w, h, "WHEELS UP?");

		// the bird, and where it's going
		Inset(x + 20, y + 40, 300, 160);
		Pic("NBCHELI", x + 30, y + 50, 280, 140);
		Text(BigFont, Font.CR_WHITE, x + 340, y + 44, rm.TurfTitle(d).MakeUpper(), 22);
		Text(NewSmallFont, Font.CR_GRAY, x + 342, y + 72, NBC_Terminal.EnvName(rm.TurfEnv(d)), 11);
		if (g)
		{
			Text(BigFont, g.TextColor(), x + 342, y + 94, g.name.MakeUpper(), 15);
			Text(NewSmallFont, Font.CR_GRAY, x + 342, y + 116, String.Format("Leader: %s", g.leaderTitle), 11);
			Text(NewSmallFont, Font.CR_GRAY, x + 342, y + 132, String.Format("About %d on the block", rm.CrewEstimate(rd, d)), 11);
			Wrap(NewSmallFont, Font.CR_WHITE, x + 342, y + 152, w - 362, g.trait, 10, 3);
		}

		// who's going
		Text(NewSmallFont, Font.CR_GRAY, x + 20, y + 214, "GOING IN", 10);
		double cx = x + 20;
		Inset(cx, y + 228, 96, 120, C_AMBER_DIM);
		Pic("NBCPVANC", cx + 8, y + 234, 80, 80);
		Text(NewSmallFont, Font.CR_WHITE, cx + 48, y + 318, "Det. Vance", 10, 1);
		Text(NewSmallFont, Font.CR_GOLD, cx + 48, y + 332, NBC_DeployMenu.KitLine(dept.pPrimary, dept.pSidearm), 8, 1);
		cx += 104;
		for (int s = 0; s < dept.squad.Size(); s++)
		{
			let o = dept.OfficerById(dept.squad[s]);
			if (!o) continue;
			Inset(cx, y + 228, 96, 120, NBC_Orders.TEAM_COLOR[o.team == NBC_Orders.TEAM_ALPHA ? 0 : 1]);
			Pic(o.Portrait(), cx + 8, y + 234, 80, 80);
			Text(NewSmallFont, Font.CR_WHITE, cx + 48, y + 318, o.RankedName(), 10, 1);
			Text(NewSmallFont, Font.CR_GRAY, cx + 48, y + 332, String.Format("%s  -  %s", o.ClassName(), o.team == NBC_Orders.TEAM_ALPHA ? "ALPHA" : "BRAVO"), 8, 1);
			cx += 104;
		}
		if (!dept.squad.Size())
			Text(NewSmallFont, Font.CR_RED, x + 140, y + 280, "No officers with you. You're going in alone.", 12);

		Text(NewSmallFont, Font.CR_GRAY, x + 20, y + 362, String.Format("Day %d of %d.  A raid takes the day.", rd.day, NBC_RunData.MAX_DAYS), 11);
		bool canGo = rm.IsHub() && !rd.raidActive && rd.caseActive && g && !rm.DistrictTaken(rd, d);
		Button(ID_NOTYET, 0, x + 20, y + h - 62, 140, 44, "NOT YET", true, 15);
		Button(ID_PLAN, 0, x + 170, y + h - 62, 180, 44, "CHANGE PLAN", true, 15);
		Button(ID_GO, 0, x + w - 20 - 240, y + h - 62, 240, 44, "WHEELS UP", canGo, 21, C_AMBER);
	}
}
