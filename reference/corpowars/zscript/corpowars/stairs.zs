// =============================================================================
// Corpo Wars — stair towers (G02). The floor plate's stairwell cells are vestibules; their fire door leads
// to an off-plate stair tower (genmap.stair_tower): a square spiral round an open well with a landing one
// storey below this floor, this floor's landing, and two above. Every landing has a fire door.
//
// Door teleports: CW_StairDoor is the use-spot in front of a fire door. An open door fades you through to
// its partner spot; a locked one says why. The landings for other floors are hooks for multi-floor
// missions: give a door a partner (another floor's map spot, a roof, a basement) and it just works.
// =============================================================================
class CW_StairDoor : CW_Interactable
{
	Default
	{
		Radius 10; Height 72;
		+NOGRAVITY; +NOTAUTOAIMED;
		RenderStyle "None";
		Tag "Fire door";
	}
	String label;        // what the door is: "Floor 14", "Roof access"
	String lockText;     // empty = open
	Vector3 dest;        // where it puts you (open doors)
	String targetMap;    // multi-floor: another floor of the building (changes level)
	int tower;
	double destAng;

	bool elevator;       // an elevator call button (multi-floor buildings) rather than a fire door
	override String GetPrompt(Actor user)
	{
		if (lockText.Length()) return label .. " - locked";
		return (elevator ? "Elevator: " : "Fire door: ") .. label;
	}
	override void Interact(Actor user)
	{
		if (lockText.Length())
		{
			user.A_StartSound("*usefail", CHAN_VOICE);
			if (user.player == players[consoleplayer]) Console.MidPrint(NewSmallFont, lockText);
			return;
		}
		A_StartSound("doors/dr1_open", CHAN_AUTO, 0, 0.8);
		if (targetMap.Length())
		{
			let l = CW_Ledger.Of(user);
			if (l) l.arriveTower = tower;
			level.ChangeLevel(targetMap, 0, CHANGELEVEL_NOINTERMISSION);
			return;
		}
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h) h.lastDoorWarp = level.maptime;
		user.SetOrigin(dest, false);
		user.angle = destAng;
		user.vel = (0, 0, 0);
		user.A_SetBlend("Black", 1.0, 18);
		user.A_StartSound("doors/dr1_clos", CHAN_AUTO, 0, 0.6);
	}
	States { Spawn: TNT1 A -1; Stop; }
}

// Floor-number plate on the stair landings (wall sprite). Sprites CWN0/CWN1, frame = label index:
// 0 "B1", 1..40 floor numbers, 41 "R" (roof), 42 "M" (plant room).
class CW_FloorSign : Actor
{
	Default { +NOGRAVITY; +NOBLOCKMAP; +WALLSPRITE; +DONTSPLASH; Radius 2; Height 12; Tag "Floor sign"; }
	int idx;
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		idx = clamp(idx, 0, 42);
		sprite = GetSpriteIndex(idx < 26 ? 'CWN0' : 'CWN1');
		frame = idx % 26;
	}
	override void Tick() { Super.Tick(); sprite = GetSpriteIndex(idx < 26 ? 'CWN0' : 'CWN1'); frame = idx % 26; }
	States { Spawn: CWN0 A -1 Bright; CWN1 A -1; Stop; }
}

// Handrail model along one flight of a stair tower (make_models.build_stair_rail).
class CW_StairRail : Actor
{
	Default { +NOGRAVITY; +NOBLOCKMAP; +DONTSPLASH; Radius 2; Height 8; }
	States { Spawn: CWMD A -1; Stop; }
}
