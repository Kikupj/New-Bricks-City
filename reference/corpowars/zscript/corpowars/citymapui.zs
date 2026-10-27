// =============================================================================
// Corpo Wars — the HUD city map (full-screen menu)
// Top-down plan of the five districts drawn from CW_CityMap (data only). Click / arrow-select a building, read the
// inspector, press GO THERE to visit its generated map (K01-K06 kit or G02 office floor).
//   Open:  M (keyconf), terminal CITY tab -> CITY MAP, console: netevent cw_citymap
//   Keys:  1-5 district, 0 whole city, wheel or +/- zoom, drag or WASD pan, arrows move the selection, ENTER go there,
//          M or ESC close.
// UI only: GO THERE sends the network event cw_mapgo (district, lot id); the play side does the level change.
// =============================================================================
class CW_CityMapMenu : CW_UiMenu
{
	CW_CityMap mp;
	double zoom, camX, camY, minZoom, maxZoom;
	int view;                        // 0 whole city, 1..5 district, -1 free
	CWM_Lot sel, hov;
	int mx, my;
	bool dragging, dragMoved;
	int downX, downY, lastX, lastY;
	double vx, vy, vw, vh, px, pw, topH, footH;   // viewport, side panel, bars
	double gx, gy, gw, gh;                        // GO THERE button
	double legH;
	double tabX[6], tabW[6], tabY, tabH;
	int focusSeen;
	double rx, ry, rw, rh;                        // RETURN TO OFFICE button (visits only)
	bool visiting;
	String note;
	int noteTic;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		DontDim = true;
		mp = CW_CityMap.Build();
		CheckVisit();
		s = max(1.0, Screen.GetHeight() / 540.0);
		DoLayout();
		ViewAll();
		hov = null; sel = null;
		MenuSound("menu/activate");
	}

	void CheckVisit()
	{
		let lk = CW_CityLink.Get();
		visiting = lk && lk.visit && !(level.MapName ~== "HUB01");
	}

	// same return as the debug hub key (netevent cw_dbgreturn); closes the map (and the terminal under it)
	void ReturnHome()
	{
		if (!visiting) { MenuSound("menu/invalid"); return; }
		EventHandler.SendNetworkEvent("cw_dbgreturn");
		MenuSound("menu/choose");
		Menu p = mParentMenu;
		Close();
		if (p) p.Close();
	}

	// ------------------------------------------------------------------ layout and view maths
	void DoLayout()
	{
		double sw = Screen.GetWidth(), sh = Screen.GetHeight();
		s = max(1.0, sh / 540.0);
		topH = 30 * s; footH = 22 * s;
		pw = min(sw * 0.36, 250 * s);
		px = sw - pw;
		vx = 0; vy = topH; vw = px; vh = sh - topH - footH;
		legH = 0;
		if (mp)
		{
			double h1;
			LegendFlow(false, 0, 0, vw - 28 * s, h1);
			legH = h1 + LH() + 12 * s;
			vh -= legH;
		}
	}

	double Sx(double wx) { return vx + vw * 0.5 + (wx - camX) * zoom; }
	double Sy(double wy) { return vy + vh * 0.5 - (wy - camY) * zoom; }

	void FitRect(double x0, double y0, double x1, double y1)
	{
		double w = max(1.0, x1 - x0), h = max(1.0, y1 - y0);
		zoom = min(vw / (w * 1.04), vh / (h * 1.04));
		camX = (x0 + x1) * 0.5; camY = (y0 + y1) * 0.5;
		ClampView();
	}

	// fit a world rect into the viewport with pixel margins (room for the district names and the harbour label)
	void FitRectPx(double x0, double y0, double x1, double y1, double padL, double padR, double padT, double padB)
	{
		double w = max(1.0, x1 - x0), h = max(1.0, y1 - y0);
		zoom = min((vw - padL - padR) / w, (vh - padT - padB) / h);
		padL += (vw - padL - padR - w * zoom) * 0.5;
		padT += (vh - padT - padB - h * zoom) * 0.5;
		camX = x0 + (vw * 0.5 - padL) / zoom;
		camY = y1 - (vh * 0.5 - padT) / zoom;
	}

	void ViewAll()
	{
		FitRectPx(mp.minX, mp.minY, mp.maxX, mp.maxY, 8 * s, 78 * s, 20 * s, 8 * s);
		minZoom = zoom * 0.8;
		maxZoom = 0.40;
		view = 0;
		ClampView();
	}

	void ViewDist(int i)
	{
		if (i < 0 || i > 4) return;
		let d = mp.dists[i];
		FitRect(d.ox - 500, d.oy - 500, d.ox + d.w + 500, d.oy + d.h + 500);
		view = i + 1;
	}

	void ClampView()
	{
		zoom = clamp(zoom, minZoom > 0 ? minZoom : 0.001, maxZoom > 0 ? maxZoom : 0.4);
		camX = clamp(camX, mp.minX - 4000, mp.maxX + 8000);
		camY = clamp(camY, mp.minY - 2000, mp.maxY + 2000);
	}

	void ZoomAt(double f, double pxl, double pyl)
	{
		double wx = camX + (pxl - (vx + vw * 0.5)) / zoom;
		double wy = camY - (pyl - (vy + vh * 0.5)) / zoom;
		zoom *= f;
		zoom = clamp(zoom, minZoom, maxZoom);
		camX = wx - (pxl - (vx + vw * 0.5)) / zoom;
		camY = wy + (pyl - (vy + vh * 0.5)) / zoom;
		view = -1;
		ClampView();
	}

	void Pan(double dxPx, double dyPx)
	{
		camX += dxPx / zoom; camY -= dyPx / zoom;
		view = -1;
		ClampView();
	}

	bool InView(double x, double y) { return x >= vx && x < vx + vw && y >= vy && y < vy + vh; }
	bool InBox(double x, double y, double bx, double by, double bw, double bh) { return x >= bx && x <= bx + bw && y >= by && y <= by + bh; }

	// ------------------------------------------------------------------ selection
	CWM_Lot HitTest(double x, double y)
	{
		if (!InView(x, y)) return null;
		CWM_Lot best = null;
		double bestA = 1e18;
		for (int i = 0; i < 5; i++)
		{
			let d = mp.dists[i];
			double dx0 = Sx(d.ox), dx1 = Sx(d.ox + d.w), dy0 = Sy(d.oy + d.h), dy1 = Sy(d.oy);
			if (x < dx0 || x > dx1 || y < dy0 || y > dy1) continue;
			for (int j = 0; j < d.lots.Size(); j++)
			{
				let b = d.lots[j];
				if (b.fill) continue;
				double l = Sx(d.ox + b.x0), r = Sx(d.ox + b.x1), t = Sy(d.oy + b.y1), bt = Sy(d.oy + b.y0);
				double padx = max(0.0, (4.0 - (r - l)) * 0.5), pady = max(0.0, (4.0 - (bt - t)) * 0.5);
				if (x < l - padx || x > r + padx || y < t - pady || y > bt + pady) continue;
				double a = (r - l + 2 * padx) * (bt - t + 2 * pady);
				if (b.enter) a *= 0.25;
				if (a < bestA) { bestA = a; best = b; }
			}
		}
		return best;
	}

	void EnsureVisible(CWM_Lot b)
	{
		if (!b) return;
		let d = mp.dists[b.dist];
		double w = (b.x1 - b.x0) * zoom;
		if (w < 5) ViewDist(b.dist);
		double x = Sx(b.cx), y = Sy(b.cy);
		if (x < vx + 50 * s || x > vx + vw - 50 * s || y < vy + 50 * s || y > vy + vh - 50 * s)
		{
			camX = b.cx; camY = b.cy;
			view = -1;
			ClampView();
		}
	}

	void MoveSel(double dx, double dy)
	{
		CWM_Lot best = null;
		double bc = 1e18;
		if (!sel)
		{
			double wx = camX, wy = camY;
			for (int i = 0; i < 5; i++)
				for (int j = 0; j < mp.dists[i].lots.Size(); j++)
				{
					let b = mp.dists[i].lots[j];
					if (!b.enter) continue;
					double c = (b.cx - wx) * (b.cx - wx) + (b.cy - wy) * (b.cy - wy);
					if (c < bc) { bc = c; best = b; }
				}
		}
		else
		{
			for (int i = 0; i < 5; i++)
				for (int j = 0; j < mp.dists[i].lots.Size(); j++)
				{
					let b = mp.dists[i].lots[j];
					if (!b.enter || b == sel) continue;
					double vx2 = b.cx - sel.cx, vy2 = b.cy - sel.cy;
					double fwd = vx2 * dx + vy2 * dy;
					if (fwd < 150) continue;
					double lat = abs(vx2 * dy - vy2 * dx);
					double c = fwd + lat * 2.2;
					if (c < bc) { bc = c; best = b; }
				}
		}
		if (best) { sel = best; EnsureVisible(best); MenuSound("menu/cursor"); }
		else MenuSound("menu/invalid");
	}

	void FocusOn(int code)
	{
		int d = code / 100000 - 1, id = code % 100000 - 1;
		let b = mp.FindLot(d, id);
		if (!b) return;
		sel = b;
		zoom = 0.11; camX = b.cx; camY = b.cy; view = -1;
		ClampView();
	}

	void GoThere()
	{
		let l = Ledger();
		if (!sel || !sel.enter || !l || l.missionActive) { MenuSound("menu/invalid"); if (l && l.missionActive) { note = "Finish or abort the running mission first."; noteTic = gametic; } return; }
		EventHandler.SendNetworkEvent("cw_mapgo", sel.dist + 1, sel.id);
		MenuSound("menu/choose");
		Menu p = mParentMenu;
		Close();
		if (p) p.Close();
	}

	// ------------------------------------------------------------------ input
	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
		case MKEY_Up:    MoveSel(0, 1); return true;
		case MKEY_Down:  MoveSel(0, -1); return true;
		case MKEY_Left:  MoveSel(-1, 0); return true;
		case MKEY_Right: MoveSel(1, 0); return true;
		case MKEY_Enter: GoThere(); return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool OnUIEvent(UIEvent ev)
	{
		if (ev.Type == UIEvent.Type_WheelUp) { ZoomAt(1.25, mx, my); return true; }
		if (ev.Type == UIEvent.Type_WheelDown) { ZoomAt(0.8, mx, my); return true; }
		if (ev.Type == UIEvent.Type_Char)
		{
			String k = String.Format("%c", ev.KeyChar).MakeLower();
			double st = 48 * s;
			if (k == "w") { Pan(0, -st); return true; }
			if (k == "s") { Pan(0, st); return true; }
			if (k == "a") { Pan(-st, 0); return true; }
			if (k == "d") { Pan(st, 0); return true; }
			if (k == "+" || k == "=") { ZoomAt(1.25, vx + vw * 0.5, vy + vh * 0.5); return true; }
			if (k == "-" || k == "_") { ZoomAt(0.8, vx + vw * 0.5, vy + vh * 0.5); return true; }
			if (k == "0") { ViewAll(); MenuSound("menu/change"); return true; }
			if (k == "1" || k == "2" || k == "3" || k == "4" || k == "5") { ViewDist(k.ToInt() - 1); MenuSound("menu/change"); return true; }
			if (k == "r" && visiting) { ReturnHome(); return true; }
			if (k == "m") { MenuSound("menu/backup"); Close(); return true; }
		}
		return Super.OnUIEvent(ev);
	}

	override bool MouseEvent(int type, int x, int y)
	{
		mx = x; my = y;
		if (type == MOUSE_Click)
		{
			dragging = false;
			if (InView(x, y)) { dragging = true; dragMoved = false; downX = x; downY = y; lastX = x; lastY = y; }
		}
		else if (type == MOUSE_Move)
		{
			if (dragging)
			{
				if (abs(x - downX) + abs(y - downY) > 5) dragMoved = true;
				if (dragMoved)
				{
					camX -= (x - lastX) / zoom; camY += (y - lastY) / zoom;
					view = -1;
					ClampView();
				}
				lastX = x; lastY = y;
			}
		}
		else if (type == MOUSE_Release)
		{
			bool wasDrag = dragging && dragMoved;
			bool wasPress = dragging;
			dragging = false;
			if (!wasDrag)
			{
				if (visiting && rw > 0 && InBox(x, y, rx, ry, rw, rh)) { ReturnHome(); return true; }
				if (sel && sel.enter && gw > 0 && InBox(x, y, gx, gy, gw, gh)) { GoThere(); return true; }
				if (y >= tabY && y <= tabY + tabH)
					for (int t = 0; t < 6; t++)
						if (x >= tabX[t] && x <= tabX[t] + tabW[t])
						{
							if (t == 0) ViewAll(); else ViewDist(t - 1);
							MenuSound("menu/change");
							return true;
						}
				if (wasPress && InView(x, y))
				{
					let h = HitTest(x, y);
					if (view == 0)
					{
						// whole city: a click zooms to the district under the cursor (and picks the building if it hit one)
						int hd = -1;
						for (int i = 0; i < 5; i++)
						{
							let d = mp.dists[i];
							if (x >= Sx(d.ox) && x <= Sx(d.ox + d.w) && y >= Sy(d.oy + d.h) && y <= Sy(d.oy)) hd = i;
						}
						if (hd >= 0)
						{
							ViewDist(hd);
							if (h && h.enter) sel = h;
							MenuSound("menu/change");
						}
					}
					else if (h) { sel = h; MenuSound("menu/cursor"); }
				}
			}
		}
		return true;
	}

	override void Ticker()
	{
		Super.Ticker();
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h && h.mapFocusReq != h.focusUsed) { h.focusUsed = h.mapFocusReq; FocusOn(h.mapFocus); }   // debug: netevent cw_mapfocus
	}

	// ------------------------------------------------------------------ drawing primitives
	Color Shade(Color c, double f) { return Color(clamp(int(c.r * f), 0, 255), clamp(int(c.g * f), 0, 255), clamp(int(c.b * f), 0, 255)); }
	Color Blend(Color a, Color b, double t)
	{
		return Color(clamp(int(a.r + (b.r - a.r) * t), 0, 255), clamp(int(a.g + (b.g - a.g) * t), 0, 255), clamp(int(a.b + (b.b - a.b) * t), 0, 255));
	}

	static Color MinorColor(int i)
	{
		switch (i)
		{
		case 0: return Color(176, 104, 48);
		case 1: return Color(150, 170, 60);
		case 2: return Color(50, 190, 150);
		case 3: return Color(210, 120, 160);
		}
		return Color(150, 150, 150);
	}

	void Fill(double x0, double y0, double x1, double y1, Color c, double a = 1.0)
	{
		x0 = max(x0, vx); y0 = max(y0, vy); x1 = min(x1, vx + vw); y1 = min(y1, vy + vh);
		if (x1 <= x0 || y1 <= y0) return;
		int ix = int(floor(x0)), iy = int(floor(y0));
		int iw = max(1, int(ceil(x1)) - ix), ih = max(1, int(ceil(y1)) - iy);
		Screen.Dim(c, a, ix, iy, iw, ih);
	}

	void Frame(double x0, double y0, double x1, double y1, double t, Color c, double a = 1.0)
	{
		Fill(x0, y0, x1, y0 + t, c, a);
		Fill(x0, y1 - t, x1, y1, c, a);
		Fill(x0, y0 + t, x0 + t, y1 - t, c, a);
		Fill(x1 - t, y0 + t, x1, y1 - t, c, a);
	}

	// raw box (whole screen, no viewport clip)
	void Raw(double x, double y, double w, double h, Color c, double a = 1.0)
	{
		if (w <= 0 || h <= 0) return;
		Screen.Dim(c, a, int(x), int(y), max(1, int(w)), max(1, int(h)));
	}

	void T(double x, double y, String t, int col, double sc = 1.0, double a = 1.0)
	{
		if (t.Left(1) == "$") t = "\c-" .. t;
		Screen.DrawText(NewSmallFont, col, x, y, t, DTA_ScaleX, s * sc, DTA_ScaleY, s * sc, DTA_Alpha, a);
	}
	// text with a dark drop shadow (for labels on the map)
	void TS(double x, double y, String t, int col, double sc = 1.0, double a = 1.0)
	{
		T(x + 1, y + 1, t, Font.CR_BLACK, sc, a);
		T(x, y, t, col, sc, a);
	}
	double Tw(String t, double sc = 1.0) { return NewSmallFont.StringWidth(t) * s * sc; }
	String FitW(String t, double w, double sc = 1.0)
	{
		if (Tw(t, sc) <= w) return t;
		int n = t.Length();
		while (n > 1 && Tw(t.Left(n) .. "..", sc) > w) n--;
		return t.Left(n) .. "..";
	}

	Color EdgeColour(String k)
	{
		if (k == "canal") return Color(22, 56, 96);
		if (k == "highway") return Color(64, 66, 72);
		if (k == "park") return Color(26, 70, 40);
		if (k == "cutting") return Color(70, 54, 42);
		if (k == "rail") return Color(78, 68, 48);
		return Color(10, 24, 46);
	}

	Color LotColour(CWM_Lot b)
	{
		double hf = 0.55 + 0.45 * min(b.storeys, 30) / 30.0;
		if (b.fill) return Color(36, 39, 46);
		if (b.kind == "landmark")
		{
			if (b.lm == "quad") return Color(40, 84, 52);
			if (b.lm == "garrison") return Color(120, 96, 84);
			return Shade(Color(215, 215, 225), 0.85);
		}
		if (!b.enter)
		{
			if (b.zone == CW_CityMap.Z_EMPTY) return Color(34, 56, 42);
			if (b.zone == CW_CityMap.Z_YARD) return Color(62, 58, 50);
			return Shade(Color(88, 94, 108), 0.55 + 0.45 * hf);
		}
		Color base;
		if (b.shellHid) base = Color(150, 156, 168);          // parent not uncovered: neutral grey
		else if (b.corp >= 0 && b.corp < 6) base = CW_City.FactionColor(b.corp);
		else if (b.corp == 6) base = Color(236, 236, 242);
		else if (b.kind == "stronghold") base = MinorColor(b.minor);
		else base = Color(150, 156, 168);
		if (b.kind == "neutral" && b.minor >= 0) base = Blend(base, MinorColor(b.minor), 0.22);
		return Shade(base, 0.68 + 0.32 * hf);
	}

	// ------------------------------------------------------------------ the map
	void DrawMap()
	{
		Raw(vx, vy, vw, vh, Color(9, 22, 42));
		double half = CW_CityMap.GAP * 0.5;
		// edges first (canal, highway, park ...), then the districts on top
		for (int i = 0; i < 5; i++)
		{
			let d = mp.dists[i];
			if (d.eN != "harbour") Fill(Sx(d.ox), Sy(d.oy + d.h + half), Sx(d.ox + d.w), Sy(d.oy + d.h), EdgeColour(d.eN));
			if (d.eS != "harbour") Fill(Sx(d.ox), Sy(d.oy), Sx(d.ox + d.w), Sy(d.oy - half), EdgeColour(d.eS));
			if (d.eE != "harbour") Fill(Sx(d.ox + d.w), Sy(d.oy + d.h), Sx(d.ox + d.w + half), Sy(d.oy), EdgeColour(d.eE));
			if (d.eW != "harbour") Fill(Sx(d.ox - half), Sy(d.oy + d.h), Sx(d.ox), Sy(d.oy), EdgeColour(d.eW));
		}
		for (int i = 0; i < 5; i++)
		{
			let d = mp.dists[i];
			double l = Sx(d.ox), r = Sx(d.ox + d.w), t = Sy(d.oy + d.h), b = Sy(d.oy);
			if (r < vx || l > vx + vw || b < vy || t > vy + vh) continue;
			Fill(l, t, r, b, Color(24, 26, 32));
			Color plate = Color(38, 41, 48);
			if (d.turfMinor >= 0) plate = Blend(plate, MinorColor(d.turfMinor), 0.16);
			for (int q = 0; q < 100; q++)
			{
				if (d.blkX1[q] < 0) continue;
				Fill(Sx(d.ox + d.blkX0[q]), Sy(d.oy + d.blkY1[q]), Sx(d.ox + d.blkX1[q]), Sy(d.oy + d.blkY0[q]), plate);
			}
			for (int j = 0; j < d.lots.Size(); j++)
			{
				let lot = d.lots[j];
				double x0 = Sx(d.ox + lot.x0), x1 = Sx(d.ox + lot.x1), y0 = Sy(d.oy + lot.y1), y1 = Sy(d.oy + lot.y0);
				if (x1 < vx || x0 > vx + vw || y1 < vy || y0 > vy + vh) continue;
				Color c = LotColour(lot);
				double w = x1 - x0, h = y1 - y0;
				if (lot.enter)
				{
					// keep enterable buildings readable when zoomed out: never draw one under 4 px
					if (w < 4) { double mxc = (x0 + x1) * 0.5; x0 = mxc - 2; x1 = mxc + 2; w = 4; }
					if (h < 4) { double myc = (y0 + y1) * 0.5; y0 = myc - 2; y1 = myc + 2; h = 4; }
				}
				if (!lot.fill && w > 3) { x0 += 0.5; y0 += 0.5; x1 -= 0.5; y1 -= 0.5; }
				Fill(x0, y0, x1, y1, c);
				if (lot.enter && w >= 4)
				{
					Color oc = Blend(c, Color(255, 255, 255), 0.55);
					Frame(x0, y0, x1, y1, w > 30 ? 2 : 1, oc);
				}
				else if (lot.enter) Fill(x0 - 0.5, y0 - 0.5, x1 + 0.5, y1 + 0.5, Blend(c, Color(255, 255, 255), 0.3), 0.6);
			}
		}
		// district labels
		for (int i = 0; i < 5; i++)
		{
			let d = mp.dists[i];
			double l = Sx(d.ox), r = Sx(d.ox + d.w), t = Sy(d.oy + d.h), b = Sy(d.oy);
			if (r < vx || l > vx + vw || b < vy || t > vy + vh) continue;
			String nm = d.name;
			nm.ToUpper();
			if (r - l < vw * 0.7)
			{
				double sc = 1.0;
				BrokenLines bl = NewSmallFont.BreakLines(nm, int(max(60.0, (r - l) * 1.7) / (s * sc)));
				int nl = min(bl.Count(), 3);
				double ly0 = t - 4 * s - nl * 13 * s * sc;
				for (int q = 0; q < nl; q++)
				{
					String ls = bl.StringAt(q);
					double tw = Tw(ls, sc);
					double lx0 = (l + r) * 0.5 - tw * 0.5;
					Raw(lx0 - 4 * s, ly0 + q * 13 * s * sc - 1 * s, tw + 8 * s, 13 * s * sc, Color(0, 0, 0), 0.62);
					T(lx0, ly0 + q * 13 * s * sc, ls, Font.CR_GOLD, sc);
				}
			}
			else
			{
				double lx = max(l, vx) + 10 * s, ly = max(t, vy) + 8 * s;
				Raw(lx - 4 * s, ly - 3 * s, Tw(nm, 1.3) + 8 * s, 16 * s, Color(0, 0, 0), 0.55);
				T(lx, ly, nm, Font.CR_GOLD, 1.3);
			}
		}
		// harbour label
		let isd = mp.dists[2];
		double hx = Sx(isd.ox + isd.w + 1500), hy = Sy(isd.oy + isd.h * 0.5);
		if (InView(hx, hy) && hx + Tw("HARBOUR", 1.2) < vx + vw) TS(hx, hy, "HARBOUR", Font.CR_CYAN, 1.2, 0.7);
		// selection and hover
		DrawMark(hov, Color(255, 255, 255), false);
		DrawMark(sel, Color(255, 214, 60), true);
	}

	void DrawMark(CWM_Lot b, Color c, bool strong)
	{
		if (!b) return;
		let d = mp.dists[b.dist];
		double x0 = Sx(d.ox + b.x0), x1 = Sx(d.ox + b.x1), y0 = Sy(d.oy + b.y1), y1 = Sy(d.oy + b.y0);
		double pad = max(0.0, (10.0 - (x1 - x0)) * 0.5) + (strong ? 2 : 1);
		if (strong)
		{
			double ph = 0.5 + 0.5 * sin(MSTime() * 0.32);            // pulse
			double th = max(2.0, s * 1.5);
			Frame(x0 - pad - th, y0 - pad - th, x1 + pad + th, y1 + pad + th, 1, Color(0, 0, 0), 0.9);
			Frame(x0 - pad - 5 * s * ph - th, y0 - pad - 5 * s * ph - th, x1 + pad + 5 * s * ph + th, y1 + pad + 5 * s * ph + th, max(1.0, s), Color(255, 214, 60), 0.25 + 0.5 * (1 - ph));
			Frame(x0 - pad, y0 - pad, x1 + pad, y1 + pad, th, Blend(c, Color(255, 255, 255), ph * 0.7));
			return;
		}
		Frame(x0 - pad, y0 - pad, x1 + pad, y1 + pad, 1, c);
	}

	// ------------------------------------------------------------------ chrome
	void DrawTop()
	{
		double sw = Screen.GetWidth();
		Raw(0, 0, sw, topH, Color(8, 12, 18));
		Raw(0, topH - 1, sw, 1, Color(45, 55, 70));
		T(10 * s, (topH - 10 * s) * 0.5, "CITY MAP", Font.CR_GOLD, 1.2);
		static const String names[] = { "0 CITY", "1 MERIDIAN", "2 EASTGATE", "3 IRONSIDE", "4 OLD QTR", "5 HIGHLINE" };
		double x = 10 * s + Tw("CITY MAP", 1.2) + 24 * s;
		tabY = 3 * s; tabH = topH - 8 * s;
		for (int t = 0; t < 6; t++)
		{
			double w = Tw(names[t]) + 18 * s;
			tabX[t] = x; tabW[t] = w;
			bool act = (view == t);
			bool over = InBox(mx, my, x, tabY, w, tabH);
			Raw(x, tabY, w, tabH, act ? Color(240, 170, 40) : (over ? Color(60, 72, 92) : Color(28, 36, 48)));
			if (act) Raw(x + 2, tabY + 2, w - 4, tabH - 4, Color(58, 44, 12));
			T(x + 9 * s, tabY + (tabH - 10 * s) * 0.5, names[t], act ? Font.CR_GOLD : Font.CR_WHITE);
			x += w + 5 * s;
		}
		String sd = String.Format("seed %d", mp.seed);
		T(sw - Tw(sd) - 10 * s, (topH - 8 * s) * 0.5, sd, Font.CR_DARKGRAY);
	}

	void DrawFoot()
	{
		double sw = Screen.GetWidth(), sh = Screen.GetHeight();
		Raw(0, sh - footH, sw, footH, Color(8, 12, 18));
		Raw(0, sh - footH, sw, 1, Color(45, 55, 70));
		String h = "Click select | Drag/WASD pan | Wheel/+- zoom | Arrows | ENTER go | 0-5 views | M/ESC close";
		if (visiting) h = "R return to office | " .. h;
		T(10 * s, sh - footH + (footH - 8 * s) * 0.5, FitW(h, sw - 20 * s), Font.CR_GRAY);
	}

	void DrawTip(CWM_Lot b)
	{
		if (!b) return;
		let d = mp.dists[b.dist];
		Array<String> ln;
		Array<int> col;
		ln.Push(b.name); col.Push(Font.CR_WHITE);
		String st = b.storeys > 0 ? String.Format("%d storeys", b.storeys) : "ground level";
		ln.Push(b.typeName == b.name ? st : String.Format("%s  -  %s", b.typeName, st)); col.Push(Font.CR_GRAY);
		if (b.enter)
		{
			if (b.kind == "property") ln.Push(b.shellHid ? String.Format("Owner: %s -> parent unknown", b.sub) : String.Format("Owner: %s > %s", b.sub, b.corpName));
			else ln.Push(String.Format("Owner: %s", b.owner));
			col.Push(Font.CR_YELLOW);
			ln.Push(CW_SitePool.IsSiteMap(b.map) ? String.Format("Site: %s", CW_SitePool.Describe(b.map)) : (b.kit > 0 ? String.Format("Site: %s, %s", b.map, CW_CityMap.VarName(b.kit, b.kvar)) : "Site: G02 office floor")); col.Push(Font.CR_CYAN);
			ln.Push("Click to select, then GO THERE"); col.Push(Font.CR_GREEN);
		}
		else
		{
			ln.Push("No entry"); col.Push(Font.CR_DARKGRAY);
		}
		double w = 0;
		double maxw = min(vw - 16 * s, 440 * s);
		for (int i = 0; i < ln.Size(); i++) { ln[i] = FitW(ln[i], maxw - 16 * s); w = max(w, Tw(ln[i])); }
		w += 16 * s;
		double h = ln.Size() * LH() + 10 * s;
		double tx = mx + 18 * s, ty = my + 14 * s;
		// stay inside the map area (never over the inspector, the top bar, the legend or the footer); flip left / up at the edges
		double mr = vx + vw - 6 * s, mb = vy + vh - 6 * s;
		if (tx + w > mr) tx = mx - w - 12 * s;
		if (ty + h > mb) ty = my - h - 8 * s;
		tx = clamp(tx, vx + 6 * s, max(vx + 6 * s, mr - w));
		ty = clamp(ty, vy + 6 * s, max(vy + 6 * s, mb - h));
		Raw(tx - 1, ty - 1, w + 2, h + 2, Color(240, 170, 40), 0.9);
		Raw(tx, ty, w, h, Color(8, 12, 18), 0.96);
		for (int i = 0; i < ln.Size(); i++) T(tx + 8 * s, ty + 5 * s + i * LH(), ln[i], col[i]);
	}

	void Swatch(double x, double y, Color c, bool outline = false)
	{
		Raw(x, y + 1 * s, 9 * s, 8 * s, c);
		if (outline) { Raw(x, y + 1 * s, 9 * s, 1, Color(255, 255, 255)); Raw(x, y + 8 * s, 9 * s, 1, Color(255, 255, 255)); }
	}

	void DrawPanel()
	{
		double sh = Screen.GetHeight();
		double top = topH, bottom = sh - footH;
		Raw(px, top, pw, bottom - top, Color(8, 12, 18));
		Raw(px, top, 1, bottom - top, Color(45, 55, 70));
		double x = px + 12 * s, w = pw - 24 * s;
		double y = top + 8 * s;
		gw = 0; rw = 0;
		if (visiting)
		{
			rx = x; ry = y; rw = w; rh = LH() + 14 * s;
			bool ro = InBox(mx, my, rx, ry, rw, rh);
			String rl = "RETURN TO OFFICE  [R]";
			Raw(rx, ry, rw, rh, ro ? Color(120, 230, 150) : Color(60, 190, 100));
			Raw(rx + 2, ry + 2, rw - 4, rh - 4, ro ? Color(24, 90, 46) : Color(14, 60, 30));
			T(rx + (rw - Tw(rl, 1.1)) * 0.5, ry + (rh - 8 * s * 1.1) * 0.5, rl, Font.CR_GREEN, 1.1);
			y += rh + 8 * s;
		}
		T(x, y, "INSPECTOR", Font.CR_DARKGRAY);
		y += LH();
		if (!sel)
		{
			y = Wrapped(x, y + 4 * s, w, "Click a building, or press an arrow key to pick one.\n\nOutlined buildings can be entered. GO THERE loads that building's map.", Font.CR_GRAY);
			y += 10 * s;
			T(x, y, "BUILDINGS YOU CAN VISIT", Font.CR_DARKGRAY);
			y += LH();
			for (int i = 0; i < 5; i++) y = KV(x, y, w, mp.dists[i].name, String.Format("%d", mp.dists[i].Enterable()), Font.CR_GRAY, Font.CR_WHITE);
		}
		else
		{
			let d = mp.dists[sel.dist];
			BrokenLines bl = NewSmallFont.BreakLines(sel.name, int(w / (s * 1.15)));
			int nl = min(bl.Count(), 2);
			for (int i = 0; i < nl; i++)
			{
				String ls = bl.StringAt(i);
				if (i == nl - 1 && bl.Count() > nl)
				{
					for (int q = nl; q < bl.Count(); q++) ls = ls .. " " .. bl.StringAt(q);
					ls = FitW(ls, w, 1.15);
				}
				T(x, y, ls, Font.CR_WHITE, 1.15); y += LH() * 1.15;
			}
			y += 2 * s;
			if (sel.enter) { Raw(x, y, Tw("ENTERABLE") + 12 * s, LH(), Color(30, 110, 60)); T(x + 6 * s, y + 2 * s, "ENTERABLE", Font.CR_WHITE); }
			else { Raw(x, y, Tw("NO ENTRY") + 12 * s, LH(), Color(50, 54, 62)); T(x + 6 * s, y + 2 * s, "NO ENTRY", Font.CR_GRAY); }
			y += LH() + 6 * s;
			y = KV(x, y, w, "District", d.name, Font.CR_DARKGRAY, Font.CR_WHITE);
			y = KV(x, y, w, "Type", sel.typeName, Font.CR_DARKGRAY, Font.CR_WHITE);
			if (sel.enter && sel.kind == "property")
			{
				y = KV(x, y, w, "Sub", sel.sub, Font.CR_DARKGRAY, Font.CR_YELLOW);
				if (sel.shellHid) y = KV(x, y, w, "Owner", "parent unknown", Font.CR_DARKGRAY, Font.CR_GRAY);
				y = KV(x, y, w, "Corp", sel.corpName, Font.CR_DARKGRAY, sel.shellHid ? Font.CR_GRAY : Font.CR_YELLOW);
			}
			else if (sel.enter) y = KV(x, y, w, sel.kind == "stronghold" ? "Held by" : "Owner", sel.owner, Font.CR_DARKGRAY, Font.CR_YELLOW);
			y = KV(x, y, w, "Building", sel.storeys > 0 ? String.Format("%d storeys", sel.storeys) : "low / open", Font.CR_DARKGRAY, Font.CR_WHITE);
			y = KV(x, y, w, "Block", String.Format("row %d, col %d", sel.by + 1, sel.bx + 1), Font.CR_DARKGRAY, Font.CR_WHITE);
			if (sel.enter)
			{
				y = KV(x, y, w, "Map", sel.kit > 0 ? String.Format("%s %s", sel.map, CW_CityMap.KitName(sel.kit)) : "G02 office floor", Font.CR_DARKGRAY, Font.CR_CYAN);
				y = KV(x, y, w, "Variant", CW_SitePool.IsSiteMap(sel.map) ? CW_SitePool.Describe(sel.map) : (sel.kit > 0 ? CW_CityMap.VarName(sel.kit, sel.kvar) : "ground floor"), Font.CR_DARKGRAY, Font.CR_CYAN);
				y = KV(x, y, w, "Layout seed", String.Format("%d", sel.seed), Font.CR_DARKGRAY, Font.CR_GRAY);
				y += 6 * s;
				let l = Ledger();
				bool can = l && !l.missionActive;
				String lbl = "GO THERE  [ENTER]";
				double bw = w, bh = LH() + 12 * s;
				gx = x; gy = y; gw = bw; gh = bh;
				bool over = InBox(mx, my, gx, gy, gw, gh);
				Raw(gx, gy, gw, gh, can ? (over ? Color(255, 200, 80) : Color(240, 170, 40)) : Color(52, 58, 68));
				if (can) Raw(gx + 2, gy + 2, gw - 4, gh - 4, over ? Color(90, 66, 14) : Color(58, 44, 12));
				else Raw(gx + 2, gy + 2, gw - 4, gh - 4, Color(20, 24, 30));
				if (!can) lbl = "GO THERE  (unavailable)";
				T(gx + (gw - Tw(lbl)) * 0.5, gy + 6 * s, FitW(lbl, gw - 8 * s), can ? Font.CR_GOLD : Font.CR_DARKGRAY);
				y += bh + 4 * s;
				if (!can) y = Wrapped(x, y, w, "A mission is running: finish or abort it first.", Font.CR_RED);
				else y = Wrapped(x, y, w, "Same building, same layout every visit. Return: R in the map, or HOME.", Font.CR_DARKGRAY);
			}
			else
			{
				y += 4 * s;
				y = Wrapped(x, y, w, "Nothing of interest inside. Only outlined buildings can be entered.", Font.CR_DARKGRAY);
			}
		}
		if (note.Length() && gametic - noteTic < 140) T(x, y + 4 * s, note, Font.CR_RED);
	}

	// legend: a strip along the bottom of the map
	void LegendFlow(bool draw, double x0, double y0, double avail, out double hgt)
	{
		static const String nm[] = { "", "", "", "", "", "", "Meridian receivership", "Independent", "Stronghold", "Not enterable" };
		double lx = 0, ly = 0;
		for (int i = 0; i < 10; i++)
		{
			String lab = i < 6 ? (i < mp.corpShort.Size() ? mp.corpShort[i] : "?") : nm[i];
			double iw = 13 * s + Tw(lab) + 14 * s;
			if (lx + iw > avail && lx > 0) { lx = 0; ly += LH(); }
			if (draw)
			{
				Color c;
				if (i < 6) c = CW_City.FactionColor(i);
				else if (i == 6) c = Color(236, 236, 242);
				else if (i == 7) c = Color(150, 156, 168);
				else if (i == 8) c = MinorColor(0);
				else c = Color(88, 94, 108);
				Swatch(x0 + lx, y0 + ly, c, i != 9);
				T(x0 + lx + 13 * s, y0 + ly, lab, i == 9 ? Font.CR_GRAY : Font.CR_WHITE);
			}
			lx += iw;
		}
		hgt = ly + LH();
	}

	void DrawLegend()
	{
		double avail = vw - 28 * s;
		double h1;
		LegendFlow(false, 0, 0, avail, h1);
		double by = vy + vh;
		Raw(0, by, vw, legH, Color(6, 10, 16));
		Raw(0, by, vw, 1, Color(45, 55, 70));
		double dummy;
		LegendFlow(true, 14 * s, by + 5 * s, avail, dummy);
		T(14 * s, by + 5 * s + h1 + 2 * s, FitW("Outline = enterable | brighter = taller | block tint = minor-player turf", avail), Font.CR_DARKGRAY);
	}

	override void Drawer()
	{
		DoLayout();
		ClampView();
		Screen.Dim(Color(0, 0, 0), 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		hov = (!dragging || !dragMoved) && InView(mx, my) ? HitTest(mx, my) : null;
		DrawMap();
		DrawTop();
		DrawFoot();
		DrawPanel();
		DrawLegend();
		if (hov && !(dragging && dragMoved)) DrawTip(hov);
	}
}
