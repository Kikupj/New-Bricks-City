// Reload-aware magazine readout layered over the stock Doom HUD.
class NBC_StatusBar : DoomStatusBar
{
	HUDFont nbcAmmoFont;

	override void Init()
	{
		Super.Init();
		Font fnt = "HUDFONT_DOOM";
		nbcAmmoFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft, 1, 1);
	}

	void DrawNBCWeaponAmmo()
	{
		if (!CPlayer || !CPlayer.ReadyWeapon || !nbcAmmoFont) return;
		NBC_ReloadWeapon weapon = NBC_ReloadWeapon(CPlayer.ReadyWeapon);
		if (!weapon) return;

		Inventory magazineItem = weapon.Ammo1;
		Inventory reserveItem = weapon.Ammo2;
		int magazine = magazineItem ? magazineItem.Amount : 0;
		int capacity = magazineItem ? magazineItem.MaxAmount : 0;
		int reserve = reserveItem ? reserveItem.Amount : 0;
		int color = magazine == 0 || magazine * 4 <= capacity ? Font.CR_RED :
			(magazine * 2 <= capacity ? Font.CR_YELLOW : Font.CR_UNTRANSLATED);
		String ammoText = FormatNumber(magazine, 0) .. " / " .. FormatNumber(reserve, 0);
		DrawString(nbcAmmoFont, ammoText, (310, 12), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, color);
		if (magazine == 0)
			DrawString(nbcAmmoFont, "RELOAD", (310, 25), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_RED);
	}

	void DrawNBCDebris()
	{
		if (!CPlayer || !CPlayer.mo || !nbcAmmoFont) return;
		NBC_Player pawn = NBC_Player(CPlayer.mo);
		if (!pawn) return;
		int selected = pawn.NBC_GetSelectedDebris();
		String icon = "BRKPA0";
		String label = "BRICK";
		switch (selected)
		{
		case NBC_DEBRIS_HALF_BRICK: icon = "HBRKA0"; label = "HALF"; break;
		case NBC_DEBRIS_CONCRETE: icon = "CNCKA0"; label = "CONCRETE"; break;
		case NBC_DEBRIS_BOTTLE: icon = "MOLPA0"; label = "BOTTLE"; break;
		}
		DrawImage(icon, (274, 34));
		String count = FormatNumber(pawn.NBC_GetDebrisCount(selected), 0) .. " / " .. FormatNumber(pawn.NBC_GetDebrisCarryLimit(), 0);
		DrawString(nbcAmmoFont, label .. " " .. count, (310, 36), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_UNTRANSLATED);
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (state == HUD_StatusBar)
		{
			BeginStatusBar();
			DrawNBCWeaponAmmo();
			DrawNBCDebris();
		}
		else if (state == HUD_Fullscreen)
		{
			BeginHUD();
			DrawNBCWeaponAmmo();
			DrawNBCDebris();
		}
	}
}
