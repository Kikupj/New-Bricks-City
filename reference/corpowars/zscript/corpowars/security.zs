// =============================================================================
// Corpo Wars — floor security: the security pass (information route into objective rooms)
// =============================================================================
class CW_SecurityPass : Inventory
{
	Default
	{
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "Security pass. It opens the maglocked doors on this floor.";
		Inventory.PickupSound "misc/k_pkup";
		Tag "Security pass";
		Radius 10;
		Height 12;
		Inventory.Icon "CWPSA0";
		+INVENTORY.UNDROPPABLE;
	}
	// Access tier = floppy colour (frames A-E: blue, red, yellow, cyan, purple; F-J the same, lit, for the
	// pickup blink). Every floor currently issues tier 0; the other colours are there for access levels.
	int tier;

	// A pass counts on the floor whose tier it is (multi-floor buildings; single floors are all tier 0).
	static clearscope bool Has(Actor pm)
	{
		let l = pm ? CW_Ledger(pm.FindInventory("CW_Ledger")) : null;
		if (!l) return false;
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		int t = (h && h.floorGen) ? h.floorGen.mapIdx : 0;
		return (l.passMask & (1 << t)) != 0;
	}
	override bool TryPickup(in out Actor toucher)
	{
		let l = CW_Ledger.Of(toucher);
		if (l) l.passMask |= 1 << clamp(tier, 0, 4);
		return Super.TryPickup(toucher);
	}
	override String PickupMessage()
	{
		let h = CW_Handler(EventHandler.Find("CW_Handler"));
		if (h && h.floorGen && h.floorGen.floors > 1)
			return String.Format("Security pass (%s). It opens the maglocks on floor %d.", CW_Building.TierColour(tier), h.floorGen.floorNum);
		return Super.PickupMessage();
	}
	override void Tick()
	{
		Super.Tick();
		if (!Owner) { frame = clamp(tier, 0, 4) + ((level.maptime / 12) % 2 ? 5 : 0); bBRIGHT = frame >= 5; }
	}
	States
	{
	Spawn:
		CWPS A -1;
		Stop;
	}
}

// Keypad panel beside a maglocked door (both faces). Frame A red = locked, B green = open, C dark = no power / broken.
class CW_Keypad : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +DONTSPLASH; Radius 4; Height 50; Tag "Maglock keypad"; }
	States { Spawn: CWKP A -1 Bright; Stop; }
}
