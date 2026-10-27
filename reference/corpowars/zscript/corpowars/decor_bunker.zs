// Bunker decoration sprites (CBN*, CBM*). Needs CWD_Wall / CWD_Stand from decor_bank.zs.
// Wall kind: origin at sprite centre, facing = wall normal. Stand kind: origin at bottom centre.

class CWD_Bkr_Sign_Radiation : CWD_Wall { States { Spawn: CBNA A -1; } }
class CWD_Bkr_Sign_Medbay : CWD_Wall { States { Spawn: CBNB A -1; } }
class CWD_Bkr_Sign_Maintenance : CWD_Wall { States { Spawn: CBNC A -1; } }
class CWD_Bkr_Sign_Surveillance : CWD_Wall { States { Spawn: CBND A -1; } }
class CWD_Bkr_Sign_ExitStairs : CWD_Wall { States { Spawn: CBNE A -1; } }
class CWD_Bkr_Directory_Bunker : CWD_Wall { States { Spawn: CBNF A -1; } }
class CWD_Bkr_Poster_Supplies : CWD_Wall { States { Spawn: CBNG A -1; } }
class CWD_Bkr_Poster_Survive : CWD_Wall { States { Spawn: CBNH A -1; } }
class CWD_Bkr_Poster_Global : CWD_Wall { States { Spawn: CBNI A -1; } }
class CWD_Bkr_Poster_Blueprint : CWD_Wall { States { Spawn: CBNJ A -1; } }
class CWD_Bkr_Monitor_AccessDenied : CWD_Wall { States { Spawn: CBNK A -1 Bright; } }
class CWD_Bkr_Monitor_RedAlert : CWD_Wall { States { Spawn: CBNL A -1 Bright; } }
class CWD_Bkr_Box_Hazard : CWD_Wall { States { Spawn: CBNM A -1; } }
class CWD_Bkr_FireAlarm : CWD_Wall { States { Spawn: CBNN A -1; } }
class CWD_Bkr_FirstAid_Green : CWD_Wall { States { Spawn: CBNO A -1; } }
class CWD_Bkr_ElectricalPanel : CWD_Wall { States { Spawn: CBNP A -1; } }
class CWD_Bkr_Intercom : CWD_Wall { States { Spawn: CBNQ A -1; } }
class CWD_Bkr_Shelf_Gear : CWD_Stand { States { Spawn: CBNR A -1; } }
class CWD_Bkr_Shelf_Supplies : CWD_Stand { States { Spawn: CBNS A -1; } }
class CWD_Bkr_Shelf_Tools : CWD_Stand { States { Spawn: CBNT A -1; } }
class CWD_Bkr_ToolWall : CWD_Stand { States { Spawn: CBNU A -1; } }
class CWD_Bkr_CoatRack_Gear : CWD_Stand { States { Spawn: CBNV A -1; } }
class CWD_Bkr_BunkBed : CWD_Stand { States { Spawn: CBNW A -1; } }
class CWD_Bkr_Cart_Radio : CWD_Stand { States { Spawn: CBNX A -1; } }
class CWD_Bkr_MapBoard : CWD_Wall { States { Spawn: CBNY A -1; } }
class CWD_Bkr_Crates_Olive : CWD_Stand { States { Spawn: CBNZ A -1; } }
class CWD_Bkr_Crates_Mixed : CWD_Stand { States { Spawn: CBN0 A -1; } }
class CWD_Bkr_Boxes_Cardboard : CWD_Stand { States { Spawn: CBN1 A -1; } }
class CWD_Bkr_ToolChest_Red : CWD_Stand { States { Spawn: CBN2 A -1; } }
class CWD_Bkr_PalletJack : CWD_Stand { States { Spawn: CBN3 A -1; } }
class CWD_Bkr_Generator : CWD_Stand { States { Spawn: CBN4 A -1; } }
class CWD_Bkr_WorkLight_Tripod : CWD_Stand { States { Spawn: CBN5 A -1 Bright; } }
class CWD_Bkr_Barrel_Blue : CWD_Stand { States { Spawn: CBN6 A -1; } }
class CWD_Bkr_Barrel_Orange : CWD_Stand { States { Spawn: CBN7 A -1; } }
class CWD_Bkr_Barrel_Green : CWD_Stand { States { Spawn: CBN8 A -1; } }
class CWD_Bkr_MopBucket : CWD_Stand { States { Spawn: CBN9 A -1; } }
class CWD_Bkr_Case_Red : CWD_Stand { States { Spawn: CBMA A -1; } }
class CWD_Bkr_Case_Hazard : CWD_Stand { States { Spawn: CBMB A -1; } }
class CWD_Bkr_Laptop : CWD_Stand { States { Spawn: CBMC A -1; } }
class CWD_Bkr_Light_Dome : CWD_Wall { States { Spawn: CBMD A -1 Bright; } }
class CWD_Bkr_Light_Tube : CWD_Wall { States { Spawn: CBME A -1 Bright; } }
class CWD_Bkr_Lamp_CagedRed : CWD_Wall { States { Spawn: CBMF A -1 Bright; } }
class CWD_Bkr_Lamp_CagedAmber : CWD_Wall { States { Spawn: CBMG A -1 Bright; } }
class CWD_Bkr_Vent_Fan : CWD_Wall { States { Spawn: CBMH A -1; } }
class CWD_Bkr_Vent_Louvre : CWD_Wall { States { Spawn: CBMI A -1; } }
class CWD_Bkr_Pipe_Elbow : CWD_Wall { States { Spawn: CBMJ A -1; } }
class CWD_Bkr_Pipe_CopperS : CWD_Wall { States { Spawn: CBMK A -1; } }
class CWD_Bkr_Pipe_Straight : CWD_Wall { States { Spawn: CBML A -1; } }
class CWD_Bkr_Valve_Red : CWD_Wall { States { Spawn: CBMM A -1; } }
class CWD_Bkr_Gauge : CWD_Wall { States { Spawn: CBMN A -1; } }
class CWD_Bkr_JunctionBox : CWD_Wall { States { Spawn: CBMO A -1; } }
class CWD_Bkr_RifleRack : CWD_Stand { States { Spawn: CBMP A -1; } }
class CWD_Bkr_DeskScreen_Cctv : CWD_Stand { States { Spawn: CBMQ A -1 Bright; } }
class CWD_Bkr_DeskScreen_Dashboard : CWD_Stand { States { Spawn: CBMR A -1 Bright; } }
class CWD_Bkr_DeskScreen_Terminal : CWD_Stand { States { Spawn: CBMS A -1 Bright; } }
class CWD_Bkr_DeskScreen_RedAlert : CWD_Stand { States { Spawn: CBMT A -1 Bright; } }
class CWD_Bkr_DeskScreen_AccessDenied : CWD_Stand { States { Spawn: CBMU A -1 Bright; } }
class CWD_Bkr_ServerUnits_Small : CWD_Stand { States { Spawn: CBMV A -1; } }
