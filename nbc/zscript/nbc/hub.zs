// Checkpoint 9 (NBC_HUB): the raid board and the armory. Both are invisible Use targets standing in
// front of the Corpo Wars furniture that shows them (a whiteboard, a row of lockers).

class NBC_HubUsable : Actor
{
	Default
	{
		Radius 24;
		Height 64;
		Health 10000;
		+SOLID;
		+SHOOTABLE;
		+NODAMAGE;
		+NOBLOOD;
		+DONTTHRUST;
		+NOGRAVITY;
	}
	States { Spawn: TNT1 A -1; Stop; }
}

class NBC_RaidBoard : NBC_HubUsable
{
	Default { Tag "Raid board"; }

	override bool Used(Actor user)
	{
		if (!user || !user.player) return false;
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rm) return false;
		rm.boardRequests++;
		A_StartSound("misc/chat", CHAN_BODY);
		return true;
	}
}

// The loadout grows with the case: a shotgun after the first gang falls, an SMG after two, a rifle after three.
class NBC_ArmoryLocker : NBC_HubUsable
{
	Default { Tag "Armory"; }

	override bool Used(Actor user)
	{
		let p = PlayerPawn(user);
		if (!p || !p.player) return false;
		let rd = NBC_RunData.Find();
		int toppled = rd ? rd.ToppledCount() : 0;
		p.A_GiveInventory("NBC_Colt45", 1);
		if (toppled >= 1) p.A_GiveInventory("NBC_PumpShotgun", 1);
		if (toppled >= 2) p.A_GiveInventory("NBC_MicroUzi", 1);
		if (toppled >= 3) p.A_GiveInventory("NBC_AK47", 1);
		TopUp(p, "NBC_LightAmmo", 120);
		TopUp(p, "Shell", toppled >= 1 ? 32 : 0);
		TopUp(p, "NBC_RifleAmmo", toppled >= 3 ? 90 : 0);
		p.A_GiveInventory("MolotovCocktail", 1);
		TopUp(p, "MolotovAmmo", 2);
		if (p.health < 100) p.A_SetHealth(100);
		p.A_GiveInventory("GreenArmor", 1);
		A_StartSound("misc/w_pkup", CHAN_BODY);
		String extra = toppled >= 3 ? "Colt, shotgun, SMG and rifle" : (toppled >= 2 ? "Colt, shotgun and SMG" :
			(toppled >= 1 ? "Colt and shotgun" : "Colt (topple a gang for more)"));
		p.A_Print("Armory: patched up, vest on, " .. extra .. ", ammo topped up.");
		return true;
	}

	static void TopUp(Actor p, class<Inventory> item, int amount)
	{
		if (!item || amount <= 0) return;
		int have = p.CountInv(item);
		if (have < amount) p.A_GiveInventory(item, amount - have);
	}
}

// The raid board: open a case, pick a district (each held by a gang), or close the day.
class NBC_RaidBoardMenu : GenericMenu
{
	int sel;
	Array<int> choices;     // network choice per row: -1 new case, -2 close day, >= 0 a district
	Array<String> rows;
	Array<int> rowColors;
	Array<bool> rowEnabled;

	override void Init(Menu parent)
	{
		Super.Init(parent);
		Build();
		for (sel = 0; sel < rows.Size() && !rowEnabled[sel]; sel++) {}
		if (sel >= rows.Size()) sel = 0;
	}

	void Add(String text, int choice, int color, bool enabled)
	{
		rows.Push(text); choices.Push(choice); rowColors.Push(color); rowEnabled.Push(enabled);
	}

	void Build()
	{
		rows.Clear(); choices.Clear(); rowColors.Clear(); rowEnabled.Clear();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		let rd = NBC_RunData.Find();
		if (!rm) return;
		if (!rd || !rd.caseActive)
		{
			Add("Open a new case", -1, Font.CR_GOLD, true);
			return;
		}
		for (int d = 0; d < rm.districtMaps.Size(); d++)
		{
			int gi = d < rd.districtGang.Size() ? rd.districtGang[d] : -1;
			let g = rm.GangAt(gi);
			bool down = gi >= 0 && gi < rd.gangToppled.Size() && rd.gangToppled[gi];
			int alert = gi >= 0 && gi < rd.gangAlert.Size() ? rd.gangAlert[gi] : 0;
			String text;
			if (!g) text = String.Format("%s  (quiet)", rm.districtTitles[d]);
			else if (down) text = String.Format("%s  -  %s  TOPPLED", rm.districtTitles[d], g.name);
			else text = String.Format("%s  -  %s  (tier %d%s)", rm.districtTitles[d], g.name, g.tier,
				alert > 0 ? String.Format(", alert %d", alert) : "");
			Add(text, d, down || !g ? Font.CR_DARKGRAY : g.TextColor(), g && !down);
		}
		Add("Close the day (rest the squad)", -2, Font.CR_WHITE, true);
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		switch (mkey)
		{
		case MKEY_Up:
			for (int i = 0; i < rows.Size(); i++) { sel = (sel + rows.Size() - 1) % rows.Size(); if (rowEnabled[sel]) break; }
			MenuSound("menu/cursor");
			return true;
		case MKEY_Down:
			for (int i = 0; i < rows.Size(); i++) { sel = (sel + 1) % rows.Size(); if (rowEnabled[sel]) break; }
			MenuSound("menu/cursor");
			return true;
		case MKEY_Enter:
			if (sel < rows.Size() && rowEnabled[sel])
			{
				MenuSound("menu/choose");
				EventHandler.SendNetworkEvent("nbc_board", choices[sel]);
				Close();
			}
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override void Drawer()
	{
		int vw = 800, vh = 500;
		Screen.Dim(0, 0.75, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		String head = "CHECKPOINT 9  -  RAID BOARD";
		Screen.DrawText(BigFont, Font.CR_GOLD, (vw - BigFont.StringWidth(head)) / 2, 40, head,
			DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);

		let rd = NBC_RunData.Find();
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		String sub;
		if (rd && rd.caseActive)
			sub = String.Format("Day %d of %d     Strikes %d of %d     Gangs toppled %d of %d     Seized cash $%d",
				rd.day, NBC_RunData.MAX_DAYS, rd.strikes, NBC_RunData.MAX_STRIKES, rd.ToppledCount(), rd.gangToppled.Size(), rd.cash);
		else if (rd && rd.caseResult != NBC_CASE_RUNNING)
			sub = rd.caseResult == NBC_CASE_WON ? "Last case: CLOSED. Every gang went down." : "Last case: lost. Start over with a new Bricks.";
		else
			sub = "No open case. A new one seeds a new Bricks: gangs dealt across the districts.";
		Screen.DrawText(NewSmallFont, Font.CR_WHITE, (vw - NewSmallFont.StringWidth(sub)) / 2, 70, sub,
			DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);

		int y = 100;
		for (int i = 0; i < rows.Size(); i++)
		{
			String t = (i == sel ? "> " : "  ") .. rows[i];
			Screen.DrawText(NewSmallFont, i == sel ? Font.CR_WHITE : rowColors[i], 140, y, t,
				DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);
			y += 16;
		}

		// dossier for the selected district
		if (rm && rd && rd.caseActive && sel < choices.Size() && choices[sel] >= 0)
		{
			int d = choices[sel];
			let g = rm.GangAt(d < rd.districtGang.Size() ? rd.districtGang[d] : -1);
			if (g)
			{
				y += 12;
				String l1 = String.Format("Leader: %s.   %s", g.leaderTitle, g.trait);
				Screen.DrawText(NewSmallFont, Font.CR_GRAY, 140, y, l1,
					DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);
			}
		}
		String help = "Up / Down to choose, Enter to go, Esc to step away. Grab a loadout at the armory first.";
		Screen.DrawText(NewSmallFont, Font.CR_DARKGRAY, (vw - NewSmallFont.StringWidth(help)) / 2, vh - 40, help,
			DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_KeepRatio, true);
	}
}
