// Checkpoint 9 (NBC_HUB): the raid board, the Evidence Locker and the squad room. All three are invisible Use
// targets standing in front of the Corpo Wars furniture that shows them (a whiteboard, a row of lockers, a sofa).

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

// Use one and the precinct terminal opens on its tab (the UI opens menus: NBC_RunManager.UiTick).
class NBC_TerminalUsable : NBC_HubUsable
{
	int tab;

	override bool Used(Actor user)
	{
		if (!user || !user.player) return false;
		let rm = NBC_RunManager(EventHandler.Find("NBC_RunManager"));
		if (!rm) return false;
		rm.menuTab = tab;
		rm.menuRequests++;
		A_StartSound("misc/chat", CHAN_BODY);
		return true;
	}
}

// the raid board: the case, the districts, planning a raid
class NBC_RaidBoard : NBC_TerminalUsable
{
	Default { Tag "Raid board"; }
	override void BeginPlay() { Super.BeginPlay(); tab = NBC_Terminal.TAB_BOARD; }
}

// the lockers: the Evidence Locker (seized weapons and supplies, everyone's kit comes out of it)
class NBC_ArmoryLocker : NBC_TerminalUsable
{
	Default { Tag "Evidence Locker"; }
	override void BeginPlay() { Super.BeginPlay(); tab = NBC_Terminal.TAB_ARMORY; }
}

// the squad room: the roster, promotions, recruits (placed in the hub's squad corner)
class NBC_SquadRoom : NBC_TerminalUsable
{
	Default { Tag "Squad room"; }
	override void BeginPlay() { Super.BeginPlay(); tab = NBC_Terminal.TAB_SQUAD; }
}
