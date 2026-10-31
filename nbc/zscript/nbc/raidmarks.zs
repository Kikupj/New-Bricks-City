// Raid markers (PLAN.md M2e): what a map tells a raid about itself, placed in iDoom Studio (the editor reads them
// from MAPINFO) or any map editor. All invisible. NBC_RunManager.SetupRaid reads them; a map without markers falls
// back to its monster spots (any monster is a ground spot) and its exit line.
//   26023 NBC_SpotGround     a gang member stands here
//   26024 NBC_SpotPerch      a shooter up high (a roof deck, a window): tier 2 or better, rarely off guard
//   26025 NBC_SpotReinforce  where reinforcements come in from (out of the way, at the edges); never used at the start
//   26026 NBC_SpotIdle       somewhere to sleep it off: off guard more often than the gang's hour says
//   26027 NBC_LeaderSpot     the leader's place, deep in the stronghold (the escorts stand round it)
//   26028 NBC_Extraction     the extraction point: where the exit is (the leader's distance on the HUD, the crew's
//                            spread along the way)
//   26030 NBC_RoomMarker     a precinct room at Checkpoint 9 (arg0: NBC_RoomMarker.ROOM_*), for M8's reopening
//   26031 NBC_HubBay         a parking bay in Checkpoint 9's yard (arg0: 0 a car bay, 1 the helipad): the motor pool's
//                            vehicles park in them when the hub loads (NBC_RunManager.ParkMotorPool)

class NBC_RaidMarker : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +DONTSPLASH; RenderStyle "None"; }
	States { Spawn: TNT1 A -1; Stop; }
}

class NBC_GangSpot : NBC_RaidMarker
{
	enum ERole { ROLE_GROUND, ROLE_PERCH, ROLE_REINFORCE, ROLE_IDLE }
	virtual int Role() { return ROLE_GROUND; }
}

class NBC_SpotGround : NBC_GangSpot { Default { Tag "Gang spot: ground"; } }
class NBC_SpotPerch : NBC_GangSpot { Default { Tag "Gang spot: perch"; } override int Role() { return ROLE_PERCH; } }
class NBC_SpotReinforce : NBC_GangSpot { Default { Tag "Gang spot: reinforcements"; } override int Role() { return ROLE_REINFORCE; } }
class NBC_SpotIdle : NBC_GangSpot { Default { Tag "Gang spot: off guard"; } override int Role() { return ROLE_IDLE; } }
class NBC_LeaderSpot : NBC_RaidMarker { Default { Tag "The leader's place"; } }
class NBC_Extraction : NBC_RaidMarker { Default { Tag "Extraction point"; } }

class NBC_RoomMarker : NBC_RaidMarker
{
	enum ERoom
	{
		ROOM_SQUAD, ROOM_ARMORY, ROOM_CAPTAIN, ROOM_MOTOR, ROOM_RADIO, ROOM_INFIRMARY, ROOM_RANGE, ROOM_LAB, ROOM_CELLS, ROOM_ROOF,
		ROOM_COUNT
	}
	static const String ROOM_NAME[] = { "Squad Room", "Armory cage", "Captain's Office", "Motor Pool", "Radio Room", "Infirmary",
		"Range", "Crime Lab", "Holding Cells", "Roof Access" };
	Default { Tag "Precinct room"; }
	clearscope int Room() const { return clamp(args[0], 0, ROOM_COUNT - 1); }
}

class NBC_HubBay : NBC_RaidMarker
{
	Default { Tag "Motor pool bay"; }
	clearscope bool Pad() const { return args[0] == 1; }
}
