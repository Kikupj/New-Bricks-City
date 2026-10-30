// The after-action report (PLAN.md M7c): the Hamburger Hill results layout. A big title (the block taken,
// a retreat, or officer down), the numbers and a letter grade, the officers who went in (kills, and stamps:
// KIA, CRITICAL, WOUNDED, PROMOTION), what the raid brought back to the Evidence Locker, the money, Backing and
// Merit (M3).
// Opened by NBC_RunManager.UiTick when you're back at the precinct; CONTINUE marks it read.

class NBC_ResultsMenu : NBC_UI
{
	enum EId { ID_CONTINUE = 1, ID_SQUADROOM }

	override void Init(Menu parent)
	{
		Super.Init(parent);
		focusId = ID_CONTINUE; focusArg = 0; focusSet = true;
	}

	override void Activate(int id, int arg)
	{
		Send(NBC_Department.OP_REPORT_SEEN);
		if (id == ID_SQUADROOM)
		{
			Close();
			NBC_Terminal.Open(NBC_Terminal.TAB_SQUAD);
			return;
		}
		Leave();
	}

	override bool Back()
	{
		Send(NBC_Department.OP_REPORT_SEEN);
		return false;
	}

	override void DrawScreen()
	{
		let dept = NBC_Department.Find();
		let rep = dept ? dept.report : null;
		Backdrop();
		if (!rep) { Button(ID_CONTINUE, 0, VW - 16 - 220, VH - 52, 220, 40, "CONTINUE", true, 20); return; }

		// the title
		String title = rep.outcome == NBC_Report.OUT_TAKEN ? String.Format("%s TAKEN", rep.place.MakeUpper())
			: (rep.outcome == NBC_Report.OUT_DOWN ? "OFFICER DOWN" : (rep.outcome == NBC_Report.OUT_CRASH ? "SHOT DOWN" :
			String.Format("RETREAT FROM %s", rep.place.MakeUpper())));
		double tsize = 40;
		while (tsize > 22 && TextWidth(BigFont, title, tsize) > VW - 40) tsize -= 2;
		Text(BigFont, Font.CR_BLACK, VW / 2 + 3, 15, title, tsize, 1, 0.7);
		Text(BigFont, rep.outcome == NBC_Report.OUT_DOWN ? Font.CR_RED : Font.CR_WHITE, VW / 2, 12, title, tsize, 1);
		String when = NBC_Clock.WindowLine(rep.window);
		if (rep.eventKind > NBC_Clock.EV_NONE && rep.eventKind < NBC_Clock.EV_COUNT) when = when .. ", " .. NBC_Clock.EV_NAME[rep.eventKind];
		Text(NewSmallFont, Font.CR_GRAY, VW / 2, 12 + tsize + 4, rep.title .. (rep.gang != "" ? "  -  " .. rep.gang : "") .. "  -  " .. when, 12, 1);

		// the numbers and the grade
		Panel(16, 80, 420, 196);
		double y = 90;
		Row(30, y, "KILLS", String.Format("%d  |  %d", rep.kills, rep.crewTotal)); y += 28;
		Row(30, y, "YOUR KILLS", String.Format("%d", rep.playerKills)); y += 28;
		Row(30, y, "LEADER", rep.leaderDown ? "DOWN" : "AT LARGE"); y += 28;
		Row(30, y, "ACCURACY", rep.shots > 0 ? String.Format("%d%%", 100 * rep.hits / rep.shots) : "-"); y += 28;
		Row(30, y, "HEALTH LOST", String.Format("%d", rep.healthLost)); y += 28;
		Row(30, y, "TIME", String.Format("%d:%02d", rep.timeSecs / 60, rep.timeSecs % 60));
		if (rep.parSecs > 0)
			Text(NewSmallFont, rep.timeSecs <= rep.parSecs ? Font.CR_GREEN : Font.CR_DARKGRAY, 176, y + 28,
				String.Format("par %d:%02d", rep.parSecs / 60, rep.parSecs % 60), 9);
		Inset(310, 94, 112, 168);
		Text(BigFont, Font.CR_WHITE, 366, 104, "GRADE", 14, 1);
		int gc = rep.grade == "S" || rep.grade == "A" ? Font.CR_GOLD : (rep.grade == "D" ? Font.CR_RED : Font.CR_WHITE);
		// the grade on a raised stone tile (Hamburger Hill's)
		Fill(334, 136, 72, 92, 0, 0.5);
		Fill(330, 132, 72, 92, 0x56606C);
		Fill(330, 132, 72, 3, 0x8A96A4); Fill(330, 132, 3, 92, 0x8A96A4);
		Fill(330, 221, 72, 3, 0x2A323C); Fill(399, 132, 3, 92, 0x2A323C);
		Text(NewSmallFont, Font.CR_BLACK, 369, 151, rep.grade, 62, 1, 0.55);
		Text(NewSmallFont, gc, 366, 148, rep.grade, 62, 1);
		Text(NewSmallFont, Font.CR_DARKGRAY, 366, 236, String.Format("%d / 100", rep.score), 10, 1);

		// the officers
		Panel(448, 80, VW - 16 - 448, 196);
		int n = rep.offId.Size();
		if (!n) Text(NewSmallFont, Font.CR_DARKGRAY, 448 + (VW - 16 - 448) / 2, 170, "You went in alone.", 13, 1);
		for (int i = 0; i < n; i++)
		{
			double cx = 464 + i * 118, cy = 94;
			Inset(cx, cy, 108, 168);
			int st = rep.offState[i];
			Pic(NBC_Cat.Face(rep.offFace[i]), cx + 10, cy + 6, 88, 88, 1.0, st == NBC_Report.OS_KIA);
			Text(NewSmallFont, Font.CR_WHITE, cx + 54, cy + 100, rep.offName[i], 11, 1);
			Text(NewSmallFont, rep.offKills[i] > 0 ? Font.CR_GOLD : Font.CR_DARKGRAY, cx + 54, cy + 116,
				rep.offKills[i] > 0 ? String.Format("+%d KILL%s", rep.offKills[i], rep.offKills[i] == 1 ? "" : "S") : "no kills", 10, 1);
			int days = i < rep.offDays.Size() ? rep.offDays[i] : 0;
			String note = st == NBC_Report.OS_KIA ? "Killed in action" : (st != NBC_Report.OS_FIT && days > 0 ?
				String.Format("Hospital, %d day%s", days, days == 1 ? "" : "s") : "Fit");
			Text(NewSmallFont, st == NBC_Report.OS_FIT ? Font.CR_GRAY : Font.CR_RED, cx + 54, cy + 132, note, 9, 1);
			if (st == NBC_Report.OS_KIA) Stamp(cx + 54, cy + 48, "KIA", C_RED, 20);
			else if (st == NBC_Report.OS_CRITICAL) Stamp(cx + 54, cy + 48, "CRITICAL", C_RED, 13);
			else if (st == NBC_Report.OS_WOUNDED) Stamp(cx + 54, cy + 48, "WOUNDED", C_AMBER, 13);
			if (rep.offPromote[i]) Stamp(cx + 54, cy + 152, "PROMOTION", C_GREEN, 11);
		}

		// the loot
		Panel(16, 288, 420, 236, "TO THE LOCKER");
		if (!rep.lootItem.Size())
			Text(NewSmallFont, Font.CR_DARKGRAY, 226, 400, rep.outcome == NBC_Report.OUT_TAKEN ? "Nothing worth bagging." : "Nothing recovered.", 12, 1);
		for (int i = 0; i < rep.lootItem.Size() && i < 8; i++)
		{
			int it = rep.lootItem[i];
			double lx = 30 + (i % 4) * 100, ly = 320 + (i / 4) * 100;
			Inset(lx, ly, 92, 92);
			Pic(NBC_Cat.ITEM_ICON[it], lx + 8, ly + 8, 76, 52);
			Text(BigFont, Font.CR_GOLD, lx + 86, ly + 5, String.Format("x%d", rep.lootCount[i]), 13, 2);
			Text(NewSmallFont, Font.CR_WHITE, lx + 46, ly + 70, NBC_Cat.ItemName(it), 10, 1);
		}

		// the money, Backing, Merit and the day
		Panel(448, 288, VW - 16 - 448, 236);
		double mx = 462, mw = VW - 16 - 448 - 28;
		Plate(mx, 300, 150, 30, "SEIZED");
		Inset(mx + 158, 300, mw - 158, 30);
		MoneyText(Font.CR_GOLD, mx + mw - 10, 305, max(0, rep.cashRaid), 18, 2, true);
		Plate(mx, 336, 150, 30, "BOUNTY");
		Inset(mx + 158, 336, mw - 158, 30);
		if (rep.bounty > 0) MoneyText(Font.CR_GOLD, mx + mw - 10, 341, rep.bounty, 18, 2, true);
		else Text(NewSmallFont, Font.CR_DARKGRAY, mx + mw - 10, 341, "-", 18, 2);
		// three boxes: the balance, Backing (and its change), Merit earned (and the bank)
		double bw = (mw - 12) / 3;
		Inset(mx, 374, bw, 58);
		Text(BigFont, Font.CR_WHITE, mx + bw / 2, 380, "BALANCE", 11, 1);
		MoneyText(Font.CR_GOLD, mx + bw / 2, 398, rep.balance, 20, 1);
		double bx = mx + bw + 6;
		Inset(bx, 374, bw, 58);
		Text(BigFont, Font.CR_WHITE, bx + bw / 2, 380, "BACKING", 11, 1);
		int dBack = rep.backingNow - rep.backingWas;
		double valW = Text(BigFont, BackingColor(rep.backingNow), bx + bw / 2, 398, String.Format("%d", rep.backingNow), 20, 1);
		if (dBack != 0) Text(NewSmallFont, dBack > 0 ? Font.CR_GREEN : Font.CR_RED, bx + bw / 2 + valW / 2 + 6, 404,
			String.Format("%s%d", dBack > 0 ? "+" : "", dBack), 11);
		double cx = bx + bw + 6;
		Inset(cx, 374, bw, 58);
		Text(BigFont, Font.CR_WHITE, cx + bw / 2, 380, "MERIT", 11, 1);
		Text(BigFont, rep.merit > 0 ? Font.CR_GOLD : Font.CR_DARKGRAY, cx + bw / 2, 398, String.Format("+%d", rep.merit), 20, 1);
		Text(NewSmallFont, Font.CR_DARKGRAY, cx + bw / 2, 420, String.Format("banked %d", rep.meritBank), 8, 1);
		// what moved Backing
		String why = "";
		for (int i = 0; i < rep.backingLog.Size(); i++) why = why .. (i ? ",  " : "") .. rep.backingLog[i];
		double ny = 436;
		if (why != "") ny += Wrap(NewSmallFont, Font.CR_GRAY, mx, ny, mw, "Backing: " .. why, 9, 2);
		ny += 2;
		ny += Wrap(NewSmallFont, Font.CR_WHITE, mx, ny, mw, rep.dayLine, 11, 2);
		// the motorcade
		for (int i = 0; i < rep.notes.Size() && ny < 520; i++)
			ny += Wrap(NewSmallFont, Font.CR_ORANGE, mx, ny, mw, rep.notes[i], 10, 2);

		bool promo = false;
		for (int i = 0; i < rep.offPromote.Size(); i++) if (rep.offPromote[i]) promo = true;
		if (promo) Button(ID_SQUADROOM, 0, VW - 16 - 220 - 240, VH - 56, 230, 44, "SQUAD ROOM", true, 18, C_GREEN);
		Button(ID_CONTINUE, 0, VW - 16 - 220, VH - 56, 220, 44, "CONTINUE", true, 20, C_AMBER);
	}

	void Row(double x, double y, String label, String value)
	{
		Plate(x, y, 140, 25, label, 11);
		Inset(x + 146, y, 120, 25);
		Text(BigFont, Font.CR_GOLD, x + 258, y + 5, value, 14, 2);
	}

	// Backing's colour: high green, low red (PLAN.md §2.5's thresholds)
	static int BackingColor(int b)
	{
		return b >= NBC_RunData.BACKING_HIGH ? Font.CR_GREEN : (b <= NBC_RunData.BACKING_LOW ? Font.CR_RED : Font.CR_WHITE);
	}
}
