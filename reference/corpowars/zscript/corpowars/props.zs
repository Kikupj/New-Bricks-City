// Generated from Assets/hq-object-sprite-sheet.png — HQ props (solid, single-angle sprites)
class CW_Prop : Actor
{
	Default
	{
		+SOLID;
		+NOBLOOD;
		+DONTTHRUST;
	}
}

class CW_DeskCommand : CW_Prop
{
	Default { Radius 34; Height 56; Tag "Command desk"; }
	States { Spawn: CWD1 A -1; Stop; }
}

class CW_DeskRound : CW_Prop
{
	Default { Radius 28; Height 48; Tag "Workstation"; }
	States { Spawn: CWD2 A -1; Stop; }
}

class CW_DeskTarget : CW_Prop
{
	Default { Radius 30; Height 48; Tag "Analyst desk"; }
	States { Spawn: CWD3 A -1; Stop; }
}

class CW_ServerRack : CW_Prop
{
	Default { Radius 16; Height 76; Tag "Server rack"; }
	States { Spawn: CWSR A -1; Stop; }
}

class CW_Chair : CW_Prop
{
	Default { Radius 12; Height 40; Tag "Chair"; }
	States { Spawn: CWCH A -1; Stop; }
}

class CW_FileCabinet : CW_Prop
{
	Default { Radius 14; Height 42; Tag "File cabinet"; }
	States { Spawn: CWFC A -1; Stop; }
}

class CW_Dresser : CW_Prop
{
	Default { Radius 26; Height 34; Tag "Low cabinet"; }
	States { Spawn: CWDR A -1; Stop; }
}

class CW_RadioConsole : CW_Prop
{
	Default { Radius 18; Height 41; Tag "Radio console"; }
	States { Spawn: CWRC A -1; Stop; }
}

class CW_CrateBig : CW_Prop
{
	Default { Radius 26; Height 35; Tag "Equipment crate"; }
	States { Spawn: CWC1 A -1; Stop; }
}

class CW_CrateStack : CW_Prop
{
	Default { Radius 24; Height 47; Tag "Crate stack"; }
	States { Spawn: CWC2 A -1; Stop; }
}

class CW_CaseBlack : CW_Prop
{
	Default { Radius 24; Height 30; Tag "Hard case"; }
	States { Spawn: CWC3 A -1; Stop; }
}

class CW_Shelf : CW_Prop
{
	Default { Radius 26; Height 61; Tag "Supply shelf"; }
	States { Spawn: CWSH A -1; Stop; }
}

class CW_Workbench : CW_Prop
{
	Default { Radius 42; Height 42; Tag "Workbench"; }
	States { Spawn: CWWB A -1; Stop; }
}

class CW_CaseSmall : CW_Prop
{
	Default { Radius 16; Height 27; Tag "Small case"; }
	States { Spawn: CWC4 A -1; Stop; }
}

class CW_MapTable : CW_Prop
{
	Default { Radius 24; Height 42; Tag "Map table"; }
	States { Spawn: CWMT A -1; Stop; }
}

// Hangs from the ceiling and casts a real dynamic light (counts toward player visibility).
// Rendered as a 3D fixture (modeldef.props.txt): style 0 recessed troffer, 1 drum pendant, 2 industrial
// batten, 3 round downlight. The generator sets the style; hand-placed lights default to troffers.
class CW_CeilingLight : Actor
{
	Default
	{
		+SPAWNCEILING;
		+NOGRAVITY;
		+NOBLOCKMAP;
		Radius 8;
		Height 19;
		Tag "Ceiling light";
	}
	Actor lamp;
	int style;
	int tintR, tintG, tintB;   // an accent colour set by the generator (underground mood lighting); 0,0,0 = the style's own
	bool unlit;   // after-hours: fixture is off for the whole mission (the dark rooms); blackouts don't bring it back
	// warm office white, warm pendant, cool industrial, halogen downlight
	static const int LR[] = { 255, 255, 214, 255 };
	static const int LG[] = { 240, 214, 232, 230 };
	static const int LB[] = { 214, 160, 255, 196 };
	// light radius per style: tight pools with real shadow between them (the stealth meter reads these)
	static const int LI[] = { 136, 112, 128, 104 };

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		style = clamp(style, 0, 3);
		frame = style;
		if (unlit) { SetStateLabel("Off"); return; }
		lamp = Spawn("CW_LightSource", pos - (0, 0, 12));
		if (lamp)
		{
			bool tinted = tintR || tintG || tintB;
			lamp.args[DynamicLight.LIGHT_RED] = tinted ? tintR : LR[style];
			lamp.args[DynamicLight.LIGHT_GREEN] = tinted ? tintG : LG[style];
			lamp.args[DynamicLight.LIGHT_BLUE] = tinted ? tintB : LB[style];
			lamp.args[DynamicLight.LIGHT_INTENSITY] = LI[style];
		}
	}
	override void Tick()
	{
		Super.Tick();
		if (frame != style) frame = style;   // keep the fixture model across the On/Off states (blackout)
	}
	States
	{
	Spawn:
		CWLT A -1 Bright;
		Stop;
	Off:
		CWLT A -1;
		Stop;
	}
}

// ---- office dressing (sprites drawn by CorpoWars_tools/make_textures.py)
class CW_Plant : CW_Prop
{
	Default { Radius 12; Height 56; Tag "Potted plant"; }
	States { Spawn: CWPL A -1; Stop; }
}

class CW_Vending : CW_Prop
{
	Default { Radius 18; Height 70; Tag "Vending machine"; }
	States { Spawn: CWVN A -1; Stop; }
}

class CW_Copier : CW_Prop
{
	Default { Radius 20; Height 42; Tag "Copier"; }
	States { Spawn: CWCP A -1; Stop; }
}

class CW_Sofa : CW_Prop
{
	Default { Radius 28; Height 30; Tag "Sofa"; }
	States { Spawn: CWSF A -1; Stop; }
}

class CW_WaterCooler : CW_Prop
{
	Default { Radius 10; Height 50; Tag "Water cooler"; }
	States { Spawn: CWWC A -1; Stop; }
}

class CW_JanitorCart : CW_Prop
{
	Default { Radius 18; Height 42; Tag "Janitor cart"; }
	States { Spawn: CWJC A -1; Stop; }
}

class CW_Bin : Actor
{
	Default { Radius 8; Height 20; +NOBLOCKMAP; Tag "Waste bin"; }
	States { Spawn: CWBN A -1; Stop; }
}

// Illuminated exit sign hung from the ceiling over stairwell doors.
class CW_ExitSign : Actor
{
	Default { +SPAWNCEILING; +NOGRAVITY; +NOBLOCKMAP; Radius 6; Height 10; Tag "Exit sign"; }
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		CW_LightSource.Make(pos + (0, 0, 2), 60, 220, 90, 40, true);   // battery-backed green spill
	}
	States { Spawn: CWEX A -1 Bright; Stop; }
}

// Wall sconce (3D model, see make_models.py): a warm up/down wash on the wall at head height. Placed on
// solid walls by the generator's lighting pass; the pool it throws is small, so the wall between two
// sconces stays in shadow. +x faces out of the wall.
class CW_WallSconce : Actor
{
	Default { +NOGRAVITY; +NOBLOCKMAP; +DONTSPLASH; Radius 4; Height 16; Tag "Wall light"; }
	Actor lamp;
	bool emergency;   // stairwells: red battery lamp
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		Vector2 ofs = AngleToVector(angle) * 8;
		if (emergency) lamp = CW_LightSource.Make(pos + (ofs, 8), 255, 60, 44, 88, true);
		else lamp = CW_LightSource.Make(pos + (ofs, 8), 255, 196, 132, 80);
		if (emergency) frame = 1;
	}
	override void Tick()
	{
		Super.Tick();
		if (emergency && frame < 1) frame = 1;
	}
	States
	{
	Spawn: CWSC A -1 Bright; Stop;
	Off:   CWSC C -1; Stop;
	}
}
