// Plan the raid (PLAN.md M6, M7c): the Hamburger Hill deploy layout, three columns.
//   ROSTER  every officer; click one to put them in the squad or take them out
//   SQUAD   you, and up to four officers; AUTO picks a squad; click a card to fit out that person
//   KIT     the selected person's kit out of the Evidence Locker: guns, pouches, vest (a picker for each slot)
// Along the bottom: BACK, what's left in the locker, and ASSAULT, which sends the raid in.

class NBC_DeployMenu : NBC_UI
{
	enum EId
	{
		ID_BACK = 1, ID_ASSAULT, ID_ROSTER, ID_MEMBER, ID_YOU, ID_AUTO, ID_AUTOKIT, ID_SLOT, ID_BENCH,
		ID_PICK, ID_UNEQUIP, ID_PICK_CLOSE, ID_TEAM
	}
	// kit slots
	enum ESlot { S_PRIMARY, S_SIDEARM, S_MELEE, S_VEST, S_POUCH }    // S_POUCH + n for pouch n

	int district;
	int kitWho;             // 0 = you, else an officer id
	int picking;            // -1, or the slot the picker is open for
	int rosterScroll;

	static void Open(Menu parent, int d)
	{
		let m = new("NBC_DeployMenu");
		m.Init(parent);
		m.district = d;
		m.ActivateMenu();
	}

	override void Init(Menu parent)
	{
		Super.Init(parent);
		picking = -1;
		focusId = ID_ASSAULT; focusArg = 0; focusSet = true;
	}

	override bool Back()
	{
		if (picking >= 0) { picking = -1; focusId = ID_SLOT; focusArg = 0; return true; }
		return false;
	}

	override void Scroll(int dir)
	{
		let dept = NBC_Department.Find();
		if (dept) rosterScroll = clamp(rosterScroll + dir, 0, max(0, dept.roster.Size() - ROWS));
	}
	const ROWS = 8;

	// ------------------------------------------------------------ actions

	override void Activate(int id, int arg)
	{
		let dept = NBC_Department.Find();
		if (!dept) return;
		switch (id)
		{
		case ID_BACK: Leave(); return;
		case ID_ASSAULT:
			// the plan's set; the pilot starts the raid (NBC_Pilot, NBC_WheelsUp)
			EventHandler.SendNetworkEvent("nbc_ready", district);
			LeaveAll();
			return;
		case ID_ROSTER:
		{
			if (arg < 0 || arg >= dept.roster.Size()) return;
			let o = dept.roster[arg];
			bool was = dept.InSquad(o.id);
			if (!was && (!o.Available() || dept.squad.Size() >= NBC_Cat.SQUAD_SLOTS)) { MenuSound("menu/invalid"); return; }
			Send(NBC_Department.OP_SQUAD_TOGGLE, o.id);
			if (!was) kitWho = o.id; else if (kitWho == o.id) kitWho = 0;
			return;
		}
		case ID_MEMBER: if (arg >= 0 && arg < dept.squad.Size()) kitWho = dept.squad[arg]; return;
		case ID_TEAM: if (arg >= 0 && arg < dept.squad.Size()) Send(NBC_Department.OP_TEAM, dept.squad[arg]); return;
		case ID_YOU: kitWho = 0; return;
		case ID_AUTO: Send(NBC_Department.OP_SQUAD_AUTO); return;
		case ID_AUTOKIT: Send(NBC_Department.OP_AUTO_KIT); return;
		case ID_BENCH:
			if (kitWho != 0) { Send(NBC_Department.OP_SQUAD_TOGGLE, kitWho); kitWho = 0; }
			return;
		case ID_SLOT:
			if (arg == S_VEST)
			{
				Send(NBC_Department.OP_VEST, kitWho, HasVest(dept) ? 0 : 1);
				return;
			}
			picking = arg;
			focusId = ID_PICK; focusArg = -2; focusSet = true;
			return;
		case ID_UNEQUIP: Equip(-1); return;
		case ID_PICK: Equip(arg); return;
		case ID_PICK_CLOSE: picking = -1; return;
		}
	}

	// put item (-1: empty / the issue weapon) in the slot the picker is open for
	void Equip(int item)
	{
		int s = picking;
		picking = -1;
		focusId = ID_SLOT; focusArg = s;
		if (s == S_PRIMARY) Send(NBC_Department.OP_PRIMARY, kitWho, item);
		else if (s == S_SIDEARM) Send(NBC_Department.OP_SIDEARM, 0, item);
		else if (s == S_MELEE) Send(NBC_Department.OP_MELEE, 0, item);
		else if (s >= S_POUCH) Send(NBC_Department.OP_POUCH, kitWho, s - S_POUCH, item);
	}

	NBC_Officer KitOfficer(NBC_Department dept)
	{
		if (kitWho == 0) return null;
		let o = dept.OfficerById(kitWho);
		if (!o || !dept.InSquad(o.id)) { kitWho = 0; return null; }
		return o;
	}
	bool HasVest(NBC_Department dept)
	{
		let o = KitOfficer(dept);
		return o ? o.kitVest : dept.pVest;
	}

	// ------------------------------------------------------------ drawing

	override void DrawScreen()
	{
		let dept = NBC_Department.Find();
		let rd = NBC_RunData.Find();
		let rm = RM();
		if (!dept || !rd || !rm) return;
		Backdrop();
		registering = picking < 0;
		let g = rm.DistrictGang(rd, district);
		TopBar(rm.TurfTitle(district).MakeUpper(), String.Format("%s  -  held by %s  -  leader %s  -  about %d on the block",
			NBC_Terminal.EnvName(rm.TurfEnv(district)), g ? g.name : "nobody", g ? g.leaderTitle : "-", rm.CrewEstimate(rd, district)));

		DrawRoster(dept);
		DrawSquad(dept);
		DrawKit(dept);
		Text(NewSmallFont, Font.CR_GRAY, 18, 524, "ARROWS / MOUSE  select     ENTER / CLICK  use     WHEEL  scroll the roster     ESC  back", 11);

		// the bottom bar: back, the locker, assault
		Fill(0, 544, VW, 56, C_PANEL_LO, 0.85);
		Fill(0, 544, VW, 2, C_AMBER_DIM);
		Button(ID_BACK, 0, 16, 552, 150, 40, "BACK", true, 18);
		static const int shown[] = { NBC_Cat.IT_LIGHT, NBC_Cat.IT_SHELL, NBC_Cat.IT_RIFLE, NBC_Cat.IT_MOLOTOV, NBC_Cat.IT_MEDKIT, NBC_Cat.IT_VEST };
		double x = 190;
		Text(NewSmallFont, Font.CR_DARKGRAY, x, 556, "IN THE LOCKER", 9);
		for (int i = 0; i < shown.Size(); i++)
		{
			int it = shown[i];
			Pic(NBC_Cat.ITEM_ICON[it], x, 566, 26, 22);
			Text(BigFont, dept.locker[it] > 0 ? Font.CR_GOLD : Font.CR_DARKGRAY, x + 30, 570, String.Format("%d", dept.locker[it]), 14);
			x += 92;
		}
		bool canGo = !rd.raidActive && rd.caseActive && g && !rm.DistrictTaken(rd, district);
		Button(ID_ASSAULT, 0, VW - 16 - 190, 552, 190, 40, "READY", canGo, 20, C_AMBER);

		registering = true;
		if (picking >= 0) DrawPicker(dept);
	}

	void DrawRoster(NBC_Department dept)
	{
		Panel(16, 66, 262, 452, "ROSTER");
		rosterScroll = clamp(rosterScroll, 0, max(0, dept.roster.Size() - ROWS));
		for (int r = 0; r < ROWS; r++)
		{
			int i = rosterScroll + r;
			if (i >= dept.roster.Size()) break;
			let o = dept.roster[i];
			double y = 96 + r * 52;
			bool inSq = dept.InSquad(o.id);
			bool f = IsFocus(ID_ROSTER, i) && registering;
			Inset(28, y, 238, 46, inSq ? C_AMBER : -1);
			Pic(o.Portrait(), 32, y + 3, 40, 40, o.Available() ? 1.0 : 0.5, !o.Available());
			Text(NewSmallFont, f ? Font.CR_GOLD : (o.Available() ? Font.CR_WHITE : Font.CR_DARKGRAY), 80, y + 5, o.RankedName(), 12);
			Text(NewSmallFont, Font.CR_GRAY, 80, y + 21, o.Available() ? o.ClassName() : String.Format("%s - hospital %dd", o.ClassName(), o.hospital), 10);
			double frac = o.health / double(max(1, o.MaxHealth()));
			Fill(80, y + 36, 120, 4, C_PANEL_LO);
			Fill(80, y + 36, 120 * clamp(frac, 0, 1), 4, frac > 0.6 ? C_GREEN : (frac > 0.3 ? C_AMBER : C_RED));
			if (inSq) Text(BigFont, Font.CR_GOLD, 258, y + 14, "IN", 13, 2);
			else if (o.CanPromote()) Text(NewSmallFont, Font.CR_GREEN, 258, y + 16, "PROMOTE", 9, 2);
			Region(ID_ROSTER, i, 28, y, 238, 46);
			if (f) FocusFrame(28, y, 238, 46);
		}
		if (dept.roster.Size() > ROWS)
			Text(NewSmallFont, Font.CR_DARKGRAY, 147, 96 + ROWS * 52, String.Format("%d-%d of %d", rosterScroll + 1,
				min(dept.roster.Size(), rosterScroll + ROWS), dept.roster.Size()), 10, 1);
	}

	void DrawSquad(NBC_Department dept)
	{
		double x = 290, w = 336;
		Panel(x, 66, w, 452, "SQUAD");
		Button(ID_AUTO, 0, x + w - 14 - 80, 72, 80, 24, "AUTO", true, 12);

		// you
		bool fy = IsFocus(ID_YOU, 0) && registering;
		Inset(x + 14, 104, w - 28, 76, kitWho == 0 ? C_AMBER : -1);
		Pic("NBCPVANC", x + 20, 110, 64, 64);
		Text(BigFont, fy ? Font.CR_GOLD : Font.CR_WHITE, x + 94, 114, "DET. VANCE", 16);
		Text(NewSmallFont, Font.CR_GRAY, x + 94, 136, "You. Undercover, leading the raid.", 10);
		Text(NewSmallFont, Font.CR_GOLD, x + 94, 154, KitLine(dept.pPrimary, dept.pSidearm), 10);
		Region(ID_YOU, 0, x + 14, 104, w - 28, 76);
		if (fy) FocusFrame(x + 14, 104, w - 28, 76);

		// four slots
		for (int s = 0; s < NBC_Cat.SQUAD_SLOTS; s++)
		{
			double cx = x + 14 + (s % 2) * 158, cy = 190 + (s / 2) * 146;
			NBC_Officer o = s < dept.squad.Size() ? dept.OfficerById(dept.squad[s]) : null;
			if (!o)
			{
				Inset(cx, cy, 150, 138);
				Text(NewSmallFont, Font.CR_DARKGRAY, cx + 75, cy + 56, "EMPTY", 12, 1);
				Text(NewSmallFont, Font.CR_DARKGRAY, cx + 75, cy + 74, "pick from the roster", 9, 1);
				continue;
			}
			OfficerCard(ID_MEMBER, s, cx, cy, 150, 120, o, kitWho == o.id);
			// the fireteam (Ghost Recon's ALPHA / BRAVO): click to switch
			bool alpha = o.team == NBC_Orders.TEAM_ALPHA;
			Button(ID_TEAM, s, cx + 150 - 58, cy + 4, 54, 18, alpha ? "ALPHA" : "BRAVO", true, 9, NBC_Orders.TEAM_COLOR[alpha ? 0 : 1]);
			Text(NewSmallFont, Font.CR_GRAY, cx + 75, cy + 124, String.Format("%s  -  %s", o.ClassName(), o.PrimaryName()), 9, 1);
		}
		Text(NewSmallFont, Font.CR_GRAY, x + 14, 520 - 30, String.Format("%d of %d in the squad", dept.squad.Size(), NBC_Cat.SQUAD_SLOTS), 10);
		Button(ID_AUTOKIT, 0, x + w - 14 - 120, 482, 120, 28, "AUTO KIT", dept.squad.Size() > 0, 12);
	}

	static String KitLine(int primary, int sidearm)
	{
		String s = primary >= 0 ? NBC_Cat.ItemName(primary) : "";
		if (sidearm >= 0) s = s == "" ? NBC_Cat.ItemName(sidearm) : s .. " + " .. NBC_Cat.ItemName(sidearm);
		return s == "" ? "Unarmed" : s;
	}

	void DrawKit(NBC_Department dept)
	{
		double x = 638, w = VW - 16 - x;
		Panel(x, 66, w, 452, "KIT");
		let o = KitOfficer(dept);
		Inset(x + 14, 104, 72, 72);
		Pic(o ? o.Portrait() : "NBCPVANC", x + 18, 108, 64, 64);
		Text(BigFont, Font.CR_WHITE, x + 96, 108, o ? o.RankedName().MakeUpper() : "DET. VANCE", 15);
		Text(NewSmallFont, Font.CR_GOLD, x + 96, 128, o ? String.Format("%s  -  %d HP  -  aim %d", o.ClassName(), o.MaxHealth(), o.Aim()) : "Detective", 10);
		if (o)
		{
			String perks = "";
			for (int i = 0; i < o.perks.Size(); i++) perks = perks .. (i ? ", " : "") .. NBC_Cat.PERK_NAME[o.perks[i]];
			Wrap(NewSmallFont, Font.CR_GRAY, x + 96, 144, w - 110, perks == "" ? "No perks yet." : perks, 9, 2);
		}
		else Text(NewSmallFont, Font.CR_GRAY, x + 96, 144, "Ammo comes out of the locker for your guns.", 9);

		double y = 190;
		if (o)
		{
			SlotRow(S_PRIMARY, x + 14, y, w - 28, "PRIMARY", o.kitPrimary >= 0 ? NBC_Cat.ITEM_ICON[o.kitPrimary] : NBC_Terminal.ClassIcon(o.cls),
				o.PrimaryName(), o.kitPrimary < 0);
			y += 46;
			for (int k = 0; k < o.PouchSlots(); k++)
			{
				int it = k < o.kitPouch.Size() ? o.kitPouch[k] : -1;
				SlotRow(S_POUCH + k, x + 14, y, w - 28, String.Format("POUCH %d", k + 1), it >= 0 ? NBC_Cat.ITEM_ICON[it] : "", NBC_Cat.ItemName(it), it < 0);
				y += 46;
			}
			if (o.PouchSlots() < 4) { Text(NewSmallFont, Font.CR_DARKGRAY, x + 14, y, "More pouches come with rank.", 9); y += 16; }
			SlotRow(S_VEST, x + 14, y, w - 28, "VEST", o.kitVest ? NBC_Cat.ITEM_ICON[NBC_Cat.IT_VEST] : "", o.kitVest ? "Kevlar vest" : "None", !o.kitVest);
			Button(ID_BENCH, 0, x + 14, 474, 120, 34, "BENCH", true, 13, C_RED);
		}
		else
		{
			SlotRow(S_PRIMARY, x + 14, y, w - 28, "PRIMARY", dept.pPrimary >= 0 ? NBC_Cat.ITEM_ICON[dept.pPrimary] : "", NBC_Cat.ItemName(dept.pPrimary), dept.pPrimary < 0);
			y += 40;
			SlotRow(S_SIDEARM, x + 14, y, w - 28, "SIDEARM", dept.pSidearm >= 0 ? NBC_Cat.ITEM_ICON[dept.pSidearm] : "", NBC_Cat.ItemName(dept.pSidearm), dept.pSidearm < 0);
			y += 40;
			SlotRow(S_MELEE, x + 14, y, w - 28, "MELEE", dept.pMelee >= 0 ? NBC_Cat.ITEM_ICON[dept.pMelee] : "", dept.pMelee >= 0 ? NBC_Cat.ItemName(dept.pMelee) : "Fists", dept.pMelee < 0);
			y += 40;
			for (int k = 0; k < dept.pPouch.Size(); k++)
			{
				int it = dept.pPouch[k];
				SlotRow(S_POUCH + k, x + 14, y, w - 28, String.Format("POUCH %d", k + 1), it >= 0 ? NBC_Cat.ITEM_ICON[it] : "", NBC_Cat.ItemName(it), it < 0);
				y += 40;
			}
			SlotRow(S_VEST, x + 14, y, w - 28, "VEST", dept.pVest ? NBC_Cat.ITEM_ICON[NBC_Cat.IT_VEST] : "", dept.pVest ? "Kevlar vest" : "None", !dept.pVest);
		}
	}

	// one kit slot: a label plate, the item's icon and name; click for the picker
	void SlotRow(int slot, double x, double y, double w, String label, String icon, String name, bool empty)
	{
		bool f = IsFocus(ID_SLOT, slot) && registering;
		Fill(x, y, 76, 38, C_PLATE);
		Frame(x, y, 76, 38, C_PANEL_HI);
		Text(BigFont, Font.CR_WHITE, x + 38, y + 13, label, 11, 1);
		Inset(x + 80, y, w - 80, 38);
		if (icon != "") Pic(icon, x + 86, y + 3, 48, 32, empty ? 0.5 : 1.0);
		Text(NewSmallFont, empty ? Font.CR_DARKGRAY : (f ? Font.CR_GOLD : Font.CR_WHITE), x + 142, y + 12, name, 12);
		Region(ID_SLOT, slot, x, y, w, 38);
		if (f) FocusFrame(x, y, w, 38);
	}

	// ------------------------------------------------------------ the picker

	void DrawPicker(NBC_Department dept)
	{
		let o = KitOfficer(dept);
		Array<int> opts;
		String title = "";
		int current = -1;
		switch (picking)
		{
		case S_PRIMARY:
			title = "PRIMARY";
			if (o)
			{
				opts.Push(-1);      // the issue weapon
				for (int i = 0; i < NBC_Cat.IT_COUNT; i++) if (NBC_Cat.ClassTakes(o.cls, i)) opts.Push(i);
				current = o.kitPrimary;
			}
			else
			{
				for (int i = 0; i < NBC_Cat.IT_COUNT; i++)
					if ((NBC_Cat.Kind(i) == NBC_Cat.K_PRIMARY || NBC_Cat.Kind(i) == NBC_Cat.K_SIDEARM) && i != dept.pSidearm) opts.Push(i);
				current = dept.pPrimary;
			}
			break;
		case S_SIDEARM:
			title = "SIDEARM";
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++) if (NBC_Cat.Kind(i) == NBC_Cat.K_SIDEARM && i != dept.pPrimary) opts.Push(i);
			current = dept.pSidearm;
			break;
		case S_MELEE:
			title = "MELEE";
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++) if (NBC_Cat.Kind(i) == NBC_Cat.K_MELEE) opts.Push(i);
			current = dept.pMelee;
			break;
		default:
		{
			int k = picking - S_POUCH;
			title = String.Format("POUCH %d", k + 1);
			for (int i = 0; i < NBC_Cat.IT_COUNT; i++) if (NBC_Cat.Kind(i) == NBC_Cat.K_POUCH) opts.Push(i);
			current = o ? (k < o.kitPouch.Size() ? o.kitPouch[k] : -1) : (k < dept.pPouch.Size() ? dept.pPouch[k] : -1);
			break;
		}
		}

		Fill(0, 0, VW, VH, 0, 0.65);
		double tw = 120, th = 96;
		int cols = min(5, max(3, opts.Size()));
		double w = 40 + cols * (tw + 10) - 10, h = 130 + ((opts.Size() + cols - 1) / cols) * (th + 10);
		double x = (VW - w) / 2, y = (VH - h) / 2;
		Panel(x, y, w, h, title .. "  -  " .. (o ? o.RankedName().MakeUpper() : "DET. VANCE"));
		for (int n = 0; n < opts.Size(); n++)
		{
			int it = opts[n];
			double bx = x + 20 + (n % cols) * (tw + 10), by = y + 44 + (n / cols) * (th + 10);
			if (it < 0)
			{
				Tile(ID_PICK, -1, bx, by, tw, th, NBC_Terminal.ClassIcon(o ? o.cls : 0), o ? NBC_Cat.CLASS_ISSUE[o.cls] : "Issue", "ISSUE", true, current < 0);
				continue;
			}
			int have = dept.locker[it] + (it == current ? 1 : 0);
			Tile(ID_PICK, it, bx, by, tw, th, NBC_Cat.ITEM_ICON[it], NBC_Cat.ItemName(it), String.Format("x%d", dept.locker[it]),
				have > 0, it == current);
		}
		Button(ID_UNEQUIP, 0, x + 20, y + h - 52, 160, 36, "UNEQUIP", current >= 0, 15, C_RED);
		Button(ID_PICK_CLOSE, 0, x + w - 40, y + 8, 28, 24, "X", true, 13);
		Text(NewSmallFont, Font.CR_GRAY, x + w - 20, y + h - 40, "the count is what's left in the locker", 10, 2);
	}
}
