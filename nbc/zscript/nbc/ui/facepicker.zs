// Your face (owner request, 2026-10-28): pick any of the officer portraits as Det. Vance's. Faces an officer on
// the roster already has are taken. Opened from the squad room (YOUR FACE) and the deploy screen's card. The
// choice is kept between games (nbc_avatar).

class NBC_FacePicker : NBC_UI
{
	enum EId { ID_FACE = 1, ID_PAGE, ID_DEFAULT, ID_CLOSE }
	const COLS = 12;
	const ROWS = 4;
	const TILE = 62;

	int page;

	static void Open(Menu parent)
	{
		let m = new("NBC_FacePicker");
		m.Init(parent);
		m.ActivateMenu();
	}

	override void Init(Menu parent)
	{
		Super.Init(parent);
		let dept = NBC_Department.Find();
		int cur = dept ? dept.playerFace : NBC_Cat.VANCE_FACE;
		page = cur / (COLS * ROWS);
		focusId = ID_FACE; focusArg = cur; focusSet = true;
	}

	int Pages() { return (NBC_Cat.FACES + COLS * ROWS - 1) / (COLS * ROWS); }

	override void Scroll(int dir) { page = clamp(page + dir, 0, Pages() - 1); }
	override void SwitchTab(int dir) { page = (page + dir + Pages()) % Pages(); MenuSound("menu/change"); }

	bool Taken(NBC_Department dept, int f)
	{
		for (int i = 0; i < dept.roster.Size(); i++) if (dept.roster[i].face == f) return true;
		return false;
	}

	override void Activate(int id, int arg)
	{
		let dept = NBC_Department.Find();
		switch (id)
		{
		case ID_FACE:
			if (dept && !Taken(dept, arg)) { Send(NBC_Department.OP_AVATAR, 0, arg); Leave(); }
			else MenuSound("menu/invalid");
			return;
		case ID_PAGE: page = clamp(page + arg, 0, Pages() - 1); return;
		case ID_DEFAULT: Send(NBC_Department.OP_AVATAR, 0, NBC_Cat.VANCE_FACE); Leave(); return;
		case ID_CLOSE: Leave(); return;
		}
	}

	override void DrawScreen()
	{
		let dept = NBC_Department.Find();
		if (!dept) return;
		Fill(0, 0, VW, VH, 0, 0.7);
		double w = COLS * (TILE + 6) + 34, h = ROWS * (TILE + 6) + 130;
		double x = (VW - w) / 2, y = (VH - h) / 2;
		Panel(x, y, w, h, "YOUR FACE");
		Text(NewSmallFont, Font.CR_GRAY, x + w - 20, y + 12, String.Format("page %d of %d", page + 1, Pages()), 11, 2);
		int per = COLS * ROWS;
		for (int k = 0; k < per; k++)
		{
			int f = page * per + k;
			if (f >= NBC_Cat.FACES) break;
			double tx = x + 20 + (k % COLS) * (TILE + 6), ty = y + 40 + (k / COLS) * (TILE + 6);
			bool taken = Taken(dept, f);
			bool cur = f == dept.playerFace;
			bool fo = IsFocus(ID_FACE, f);
			Inset(tx, ty, TILE, TILE, cur ? C_AMBER : -1);
			Pic(NBC_Cat.Face(f), tx + 2, ty + 2, TILE - 4, TILE - 4, taken ? 0.3 : 1.0, taken);
			if (taken) Text(NewSmallFont, Font.CR_DARKGRAY, tx + TILE / 2, ty + TILE - 14, "officer", 8, 1);
			Region(ID_FACE, f, tx, ty, TILE, TILE);
			if (fo) FocusFrame(tx, ty, TILE, TILE);
		}
		double by = y + h - 52;
		Button(ID_PAGE, -1, x + 20, by, 110, 34, "< PREV", page > 0, 13);
		Button(ID_PAGE, 1, x + 138, by, 110, 34, "NEXT >", page < Pages() - 1, 13);
		Button(ID_DEFAULT, 0, x + w / 2 - 90, by, 180, 34, "VANCE'S OWN", true, 13);
		Button(ID_CLOSE, 0, x + w - 20 - 120, by, 120, 34, "CLOSE", true, 13);
		Text(NewSmallFont, Font.CR_GRAY, x + 20, y + h - 14, "Q / E or the wheel: pages", 9);
	}
}
