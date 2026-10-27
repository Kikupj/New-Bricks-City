// Subway/transit decoration sprites (CSW*, CSX*). Needs CWD_Wall / CWD_Stand from decor_bank.zs.
// Wall kind: origin at sprite centre, facing = wall normal. Stand kind: origin at bottom centre (hung signs: spawn at height).

class CWD_Sub_Sign_Local : CWD_Stand { States { Spawn: CSWA A -1; } }
class CWD_Sub_Board_Departures : CWD_Stand { States { Spawn: CSWB A -1 Bright; } }
class CWD_Sub_Board_DeparturesWall : CWD_Wall { States { Spawn: CSWC A -1 Bright; } }
class CWD_Sub_Sign_Exit : CWD_Stand { States { Spawn: CSWD A -1; } }
class CWD_Sub_Sign_Trains : CWD_Stand { States { Spawn: CSWE A -1; } }
class CWD_Sub_Icon_Elevator : CWD_Wall { States { Spawn: CSWF A -1; } }
class CWD_Sub_Icon_Stairs : CWD_Wall { States { Spawn: CSWG A -1; } }
class CWD_Sub_Icon_Escalator : CWD_Wall { States { Spawn: CSWH A -1; } }
class CWD_Sub_Icon_Accessible : CWD_Wall { States { Spawn: CSWI A -1; } }
class CWD_Sub_Icon_Men : CWD_Wall { States { Spawn: CSWJ A -1; } }
class CWD_Sub_Icon_Women : CWD_Wall { States { Spawn: CSWK A -1; } }
class CWD_Sub_Poster_Map : CWD_Wall { States { Spawn: CSWL A -1; } }
class CWD_Sub_Poster_SeeSay : CWD_Wall { States { Spawn: CSWM A -1; } }
class CWD_Sub_Poster_StayAlert : CWD_Wall { States { Spawn: CSWN A -1; } }
class CWD_Sub_Poster_Ride : CWD_Wall { States { Spawn: CSWO A -1; } }
class CWD_Sub_Poster_Skyline : CWD_Wall { States { Spawn: CSWP A -1; } }
class CWD_Sub_Clock_Wall : CWD_Wall { States { Spawn: CSWQ A -1; } }
class CWD_Sub_Kiosk_Map : CWD_Stand { States { Spawn: CSWR A -1; } }
class CWD_Sub_Bench_Blue4 : CWD_Stand { States { Spawn: CSWS A -1; } }
class CWD_Sub_Bench_Blue3 : CWD_Stand { States { Spawn: CSWT A -1; } }
class CWD_Sub_Bench_Steel : CWD_Stand { States { Spawn: CSWU A -1; } }
class CWD_Sub_TicketMachine : CWD_Stand { States { Spawn: CSWV A -1; } }
class CWD_Sub_NewsBox_Blue : CWD_Stand { States { Spawn: CSWW A -1; } }
class CWD_Sub_NewsBox_Red : CWD_Stand { States { Spawn: CSWX A -1; } }
class CWD_Sub_Turnstile_Closed : CWD_Stand { States { Spawn: CSWY A -1; } }
class CWD_Sub_Turnstile_Open : CWD_Stand { States { Spawn: CSWZ A -1; } }
class CWD_Sub_GateReader : CWD_Stand { States { Spawn: CSW0 A -1; } }
class CWD_Sub_Barrel_Traffic : CWD_Stand { States { Spawn: CSW1 A -1; } }
class CWD_Sub_HandTruck_Red : CWD_Stand { States { Spawn: CSW2 A -1; } }
class CWD_Sub_LuggageCart : CWD_Stand { States { Spawn: CSW3 A -1; } }
class CWD_Sub_Bin_Wheelie : CWD_Stand { States { Spawn: CSW4 A -1; } }
class CWD_Sub_Fence_Authorized : CWD_Stand { States { Spawn: CSW5 A -1; } }
class CWD_Sub_Ladder_Red : CWD_Stand { States { Spawn: CSW6 A -1; } }
class CWD_Sub_Toolbox_Red : CWD_Stand { States { Spawn: CSW7 A -1; } }
class CWD_Sub_Broom : CWD_Stand { States { Spawn: CSW8 A -1; } }
class CWD_Sub_Cabinet_Extinguisher : CWD_Wall { States { Spawn: CSW9 A -1; } }
class CWD_Sub_Payphone : CWD_Wall { States { Spawn: CSXA A -1; } }
class CWD_Sub_Cabinet_Electrical : CWD_Wall { States { Spawn: CSXB A -1; } }
class CWD_Sub_Camera_Dome : CWD_Wall { States { Spawn: CSXC A -1; } }
class CWD_Sub_Speaker_Horn : CWD_Wall { States { Spawn: CSXD A -1; } }
class CWD_Sub_Box_Electrical : CWD_Wall { States { Spawn: CSXE A -1; } }
class CWD_Sub_Light_Pendant : CWD_Stand { States { Spawn: CSXF A -1 Bright; } }
