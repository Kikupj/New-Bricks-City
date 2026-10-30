// The case summary (PLAN.md M3, M8): the case file, closed. It waits at the precinct once a case ends (the Crown
// taken, three strikes, or day 30), after the last after-action report: how it ended, the days used, the gangs
// toppled, the strikes, the raids, the officers lost, Backing, and the Merit the case earned for the department.
// Opened by NBC_RunManager.UiTick; CONTINUE marks it read.

class NBC_CaseSummary : NBC_UI
{
	enum EId { ID_CONTINUE = 1 }

	override void Init(Menu parent)
	{
		Super.Init(parent);
		focusId = ID_CONTINUE; focusArg = 0; focusSet = true;
	}

	override void Activate(int id, int arg)
	{
		EventHandler.SendNetworkEvent("nbc_summary_seen");
		Leave();
	}

	override bool Back()
	{
		EventHandler.SendNetworkEvent("nbc_summary_seen");
		return false;
	}

	override void DrawScreen()
	{
		let rd = NBC_RunData.Find();
		let dept = NBC_Department.Find();
		let rm = RM();
		Backdrop();
		if (!rd || !rm) { Button(ID_CONTINUE, 0, VW - 16 - 220, VH - 56, 220, 44, "CONTINUE", true, 20, C_AMBER); return; }

		// the title: how it ended
		String title, line;
		int tc;
		int daysUsed = clamp(rd.day - 1, 1, NBC_RunData.MAX_DAYS);
		switch (rd.caseResult)
		{
		case NBC_CASE_WON:
			title = "CASE CLOSED";
			tc = Font.CR_GOLD;
			line = rd.crownSlot > 0 ? String.Format("The Crown fell on day %d. The Landlord's hold on the Bricks is broken.", daysUsed)
				: String.Format("Every gang in the Bricks went down by day %d.", daysUsed);
			break;
		case NBC_CASE_STRUCK_OUT:
			title = "BADGE PULLED";
			tc = Font.CR_RED;
			line = String.Format("Three strikes. Internal Affairs took your badge on day %d.", daysUsed);
			break;
		default:
			title = "DEMOLITION DAY";
			tc = Font.CR_ORANGE;
			line = "Thirty days. The demolition crews rolled in, and whoever was still in the Bricks went with it.";
			break;
		}
		Text(BigFont, Font.CR_BLACK, VW / 2 + 3, 19, title, 44, 1, 0.7);
		Text(BigFont, tc, VW / 2, 16, title, 44, 1);
		Text(NewSmallFont, Font.CR_GRAY, VW / 2, 68, line, 13, 1);

		// the case file
		Panel(16, 96, 440, 428, "THE CASE FILE");
		double y = 130;
		Row(30, y, "DAYS USED", String.Format("%d  |  %d", daysUsed, NBC_RunData.MAX_DAYS)); y += 38;
		Row(30, y, "GANGS TOPPLED", String.Format("%d  |  %d", rd.ToppledCount(), rd.RegularGangs())); y += 38;
		Row(30, y, "THE CROWN", rd.crownSlot <= 0 ? "-" : (rd.CrownTaken() ? "TAKEN" : (rd.CrownOpen() ? "STANDING" : "NEVER OPENED"))); y += 38;
		Row(30, y, "STRIKES", String.Format("%d  |  %d", rd.strikes, NBC_RunData.MAX_STRIKES)); y += 38;
		Row(30, y, "RAIDS", String.Format("%d", rd.caseRaids)); y += 38;
		Text(NewSmallFont, Font.CR_GRAY, 44, y - 6, String.Format("%d taken,  %d retreats,  %d officer down", rd.caseTaken, rd.caseRetreats, rd.caseDowns), 11);
		y += 18;
		Row(30, y, "OFFICERS LOST", String.Format("%d", rd.caseLost)); y += 38;
		Row(30, y, "BACKING", String.Format("%d", rd.backing));
		Text(NewSmallFont, Font.CR_GRAY, 44, y + 32, String.Format("lowest this case: %d", rd.caseBackingLow), 11);

		// the gangs
		double x = 468, w = VW - 16 - x;
		Panel(x, 96, w, 196, "THE BRICKS");
		double gy = 128;
		for (int i = 0; i < rd.gangToppled.Size() && i < rm.gangs.Size(); i++)
		{
			let g = rm.gangs[i];
			bool down = rd.gangToppled[i];
			bool crown = rd.IsCrown(i);
			Inset(x + 14, gy, w - 28, 28, down ? C_GREEN : -1);
			Text(BigFont, down ? Font.CR_DARKGRAY : g.TextColor(), x + 26, gy + 7, g.name.MakeUpper(), 12);
			String st = down ? "TOPPLED" : (crown ? (rd.CrownOpen() ? "STANDING" : "NEVER REACHED") : "STANDING");
			Text(BigFont, down ? Font.CR_GREEN : Font.CR_RED, x + w - 26, gy + 8, st, 11, 2);
			gy += 32;
		}

		// Merit: what this case earned, and the department's bank
		Panel(x, 304, w, 220, "MERIT");
		Inset(x + 14, 336, (w - 40) / 2, 104);
		Text(BigFont, Font.CR_WHITE, x + 14 + (w - 40) / 4, 346, "THIS CASE", 13, 1);
		Text(BigFont, rd.caseMerit > 0 ? Font.CR_GOLD : Font.CR_DARKGRAY, x + 14 + (w - 40) / 4, 376, String.Format("+%d", rd.caseMerit), 34, 1);
		double bx = x + 26 + (w - 40) / 2;
		Inset(bx, 336, (w - 40) / 2, 104);
		Text(BigFont, Font.CR_WHITE, bx + (w - 40) / 4, 346, "BANKED", 13, 1);
		Text(BigFont, Font.CR_GOLD, bx + (w - 40) / 4, 376, String.Format("%d", dept ? dept.merit : 0), 34, 1);
		Wrap(NewSmallFont, Font.CR_GRAY, x + 18, 452, w - 36,
			"Merit stays with the department from case to case, and so do the officers who came home. The next case is a new Bricks.", 11, 3);

		Hints("ENTER / CLICK  continue");
		Button(ID_CONTINUE, 0, VW - 16 - 220, VH - 56, 220, 44, "CONTINUE", true, 20, C_AMBER);
	}

	void Row(double x, double y, String label, String value)
	{
		Plate(x, y, 190, 30, label, 13);
		Inset(x + 196, y, 216, 30);
		Text(BigFont, Font.CR_GOLD, x + 400, y + 7, value, 16, 2);
	}
}
