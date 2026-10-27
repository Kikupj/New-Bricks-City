// =============================================================================
// Corpo Wars — interior theme sets for the procedural office floor (G02)
//
// A theme is one tenant's fit-out: a matching set of wall, floor and ceiling materials per room role,
// so every building reads as its own place. Themed textures live in textures/themes/ (AX* = A.D. Cop,
// see tools_src/import_themes.py and CREDITS.txt); theme 0 is the original Meridian look.
// Pick: the contract's theme, else cw_theme (>= 0), else from the floor seed.
// =============================================================================
class CW_Themes play
{
	enum ESlot
	{
		TS_WALL, TS_HALLW, TS_EXECW, TS_CONFW, TS_WETW, TS_SERVW, TS_TECHW, TS_TECHW2, TS_LABW, TS_LOBBYW,
		TS_METALW, TS_STAIRW, TS_FREIGHTW,
		TS_CARP, TS_CARP2, TS_EXECF, TS_TILEF, TS_SERVF, TS_GRATEF, TS_LOBBYF, TS_RECEPF, TS_RUG,
		TS_CEIL, TS_CEILD, TS_PANEL, TS_PANELF, TS_PANELC, TS_PANELR, TS_TRIM, TS_POST, TS_STEP,
		NSLOT
	}
	const COUNT = 5;

	static String Name(int t)
	{
		switch (t)
		{
		case 1: return "Walnut & Brass";
		case 2: return "Clinical White";
		case 3: return "Night Glass";
		case 4: return "Brick & Steel";
		}
		return "Meridian Standard";
	}

	// One line per theme, slots in ESlot order.
	static String Row(int t)
	{
		switch (t)
		{
		//          WALL      HALLW    EXECW    CONFW    WETW     SERVW    TECHW    TECHW2   LABW     LOBBYW   METALW   STAIRW   FREIGHTW
		//          CARP      CARP2    EXECF    TILEF    SERVF    GRATEF   LOBBYF   RECEPF   RUG
		//          CEIL      CEILD    PANEL    PANELF   PANELC   PANELR   TRIM     POST     STEP
		case 1: return
			"AXCITY08 AXHW09   AXHW07B  AXDW07A  AXCITY05 AXDW04   ADCOMP1  ADCOMP2  AXCITY18 AXHW09B  AXW44A   AXCITY09 AXW28 "
			"AXF06C   AXF06B   AXHF07C  AXF06D   AXF02    ADFGRAT  AXF06E   AXF48    AXF51B "
			"CWCEILT  CWCEILD  CWCEILL  ADFLUOR  ADCLITE  ADCLRND  CWTRIM   AXHW07D  AXF06D";
		case 2: return
			"AXW24    AXW578   AXCITY19 AXW26E   AXCITY05 AXW02    AXW69    AXW45    AXW578B  AXCITY18 AXW44    AXW01    AXW47 "
			"AXF39    AXF39C   AXF48C   AXF39B   AXF02    AXF10    AXF48B   AXF48    AXF33 "
			"CWCEILT  CWCEILD  AXDU06A  AXDU06   ADCLITE  AXF15    AXW44    AXW44A   AXF39";
		case 3: return
			"AXW67    AXW45    AXCITY17 AXW26    AXW578   AXW21    AXW69B   AXW69    AXW578B  AXCITY14 AXW72    AXW24C   AXW43B "
			"AXF46    AXF46B   AXF48D   AXF43    AXFLOR07 AXF40    AXFLOR05 AXF48D   AXF33 "
			"AXF21    AXFLOR09 AXDU13   AXDU14   AXDU13A  AXF15    AXW72    AXW72    AXF48D";
		case 4: return
			"AXW85    AXW24    AXHW07A  AXDW07B  AXDEFW   AXW28    AXW53    ADCOMP2  AXDEFW2  AXW85    AXW44    AXW24    AXW29B "
			"AXF02    AXFLOR02 AXHF07A  AXF39    AXF05    AXF10    AXDU02   AXDU10C  AXF06C "
			"AXF13    AXDU12   AXDU06   AXDU06A  AXDU06   AXF15    AXW44    AXW53B   AXF05";
		}
		return
			"CWWALL1  CWWALL2  ADTRAVW  CWWOOD1  CWTILEW  CWCONCW  ADCOMP1  ADCOMP2  ADMARBL  ADMARBD  ADMETL2  ADCONC1  ADMETL3 "
			"CWCARP1  CWCARP2  ADFWOD2  CWTILEF  CWCONCF  ADFGRAT  ADFMARG  ADFMARB  CWCARP3 "
			"CWCEILT  CWCEILD  CWCEILL  ADFLUOR  ADCLITE  ADCLRND  CWTRIM   ADMETL1  ADMARBD";
	}

	static void Load(int t, Array<String> slots)
	{
		Array<String> raw;
		Row(t).Split(raw, " ", TOK_SKIPEMPTY);
		slots.Clear();
		for (int k = 0; k < raw.Size(); k++) slots.Push(raw[k]);
		Array<String> base;
		if (slots.Size() < NSLOT) Row(0).Split(base, " ", TOK_SKIPEMPTY);
		while (slots.Size() < NSLOT) slots.Push(base[slots.Size()]);
	}

	// Polished floors pick up the lights (plane reflections, hardware renderer).
	static double Gloss(String f)
	{
		if (f == "ADFMARG" || f == "ADFMARB" || f.Left(5) == "AXF48" || f == "AXF06D" || f == "AXF06E" || f == "AXFLOR05") return 0.16;
		if (f == "CWTILEF" || f.Left(5) == "AXF39" || f == "AXF43" || f == "AXF02") return 0.10;
		if (f == "ADFWOD2" || f.Left(5) == "AXHF0" || f == "AXDU02" || f == "AXDU10C") return 0.06;
		return 0;
	}
}
