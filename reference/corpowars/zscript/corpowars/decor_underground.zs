// Underground / sewer decoration sprites (CUG*, CUH*). Needs CWD_Wall / CWD_Stand from decor_bank.zs.
// Wall kind: origin at sprite centre, facing = wall normal (moss drapes: place at ceiling edge). Stand kind: origin at bottom centre (hung lamps: spawn at height).

class CWD_Und_Plate_B1 : CWD_Wall { States { Spawn: CUGA A -1; } }
class CWD_Und_Sign_SewerAccess : CWD_Wall { States { Spawn: CUGB A -1; } }
class CWD_Und_Sign_CautionWet : CWD_Wall { States { Spawn: CUGC A -1; } }
class CWD_Und_Sign_DangerConfined : CWD_Wall { States { Spawn: CUGD A -1; } }
class CWD_Und_Sign_HighPressure : CWD_Wall { States { Spawn: CUGE A -1; } }
class CWD_Und_Sign_NoEntry : CWD_Wall { States { Spawn: CUGF A -1; } }
class CWD_Und_Sign_KeepWaterClean : CWD_Wall { States { Spawn: CUGG A -1; } }
class CWD_Und_Sign_FloodControl : CWD_Wall { States { Spawn: CUGH A -1; } }
class CWD_Und_Sign_MaintenanceOnly : CWD_Wall { States { Spawn: CUGI A -1; } }
class CWD_Und_Sign_ExitGreen : CWD_Wall { States { Spawn: CUGJ A -1; } }
class CWD_Und_Sign_PumpStationB : CWD_Wall { States { Spawn: CUGK A -1; } }
class CWD_Und_Sign_MainTunnel : CWD_Wall { States { Spawn: CUGL A -1; } }
class CWD_Und_Grate_Round : CWD_Wall { States { Spawn: CUGM A -1; } }
class CWD_Und_Outfall_Pipe : CWD_Wall { States { Spawn: CUGN A -1; } }
class CWD_Und_Tunnel_Arch : CWD_Wall { States { Spawn: CUGO A -1; } }
class CWD_Und_Drip_Pipe_Straight : CWD_Wall { States { Spawn: CUGP A -1; } }
class CWD_Und_Drip_Pipe_Elbow : CWD_Wall { States { Spawn: CUGQ A -1; } }
class CWD_Und_Drip_Pipe_Gauge : CWD_Wall { States { Spawn: CUGR A -1; } }
class CWD_Und_Drip_Pipe_Short : CWD_Wall { States { Spawn: CUGS A -1; } }
class CWD_Und_Valve_Body : CWD_Wall { States { Spawn: CUGT A -1; } }
class CWD_Und_Valve_Vertical : CWD_Wall { States { Spawn: CUGU A -1; } }
class CWD_Und_Valve_Gauge : CWD_Wall { States { Spawn: CUGV A -1; } }
class CWD_Und_Valve_Post : CWD_Stand { States { Spawn: CUGW A -1; } }
class CWD_Und_Lamp_CageAmber : CWD_Stand { States { Spawn: CUGX A -1 Bright; } }
class CWD_Und_Lamp_CageRed : CWD_Stand { States { Spawn: CUGY A -1 Bright; } }
class CWD_Und_Lamp_CageSmall : CWD_Wall { States { Spawn: CUGZ A -1 Bright; } }
class CWD_Und_Lamp_CageSmallRed : CWD_Wall { States { Spawn: CUG0 A -1 Bright; } }
class CWD_Und_Lamp_Industrial : CWD_Stand { States { Spawn: CUG1 A -1 Bright; } }
class CWD_Und_Lamp_Bollard : CWD_Wall { States { Spawn: CUG2 A -1 Bright; } }
class CWD_Und_Barrel_Hazard : CWD_Stand { States { Spawn: CUG3 A -1; } }
class CWD_Und_Cone_Orange : CWD_Stand { States { Spawn: CUG4 A -1; } }
class CWD_Und_Railing_Yellow : CWD_Stand { States { Spawn: CUG5 A -1; } }
class CWD_Und_Fence_DangerKeepOut : CWD_Stand { States { Spawn: CUG6 A -1; } }
class CWD_Und_Switch_Box : CWD_Wall { States { Spawn: CUG7 A -1; } }
class CWD_Und_Box_Small : CWD_Wall { States { Spawn: CUG8 A -1; } }
class CWD_Und_Panel_Open : CWD_Wall { States { Spawn: CUG9 A -1; } }
class CWD_Und_Pump_Motor : CWD_Stand { States { Spawn: CUHA A -1; } }
class CWD_Und_Crate_Wood : CWD_Stand { States { Spawn: CUHB A -1; } }
class CWD_Und_Case_GreenA : CWD_Stand { States { Spawn: CUHC A -1; } }
class CWD_Und_Case_GreenB : CWD_Stand { States { Spawn: CUHD A -1; } }
class CWD_Und_Case_Blue : CWD_Stand { States { Spawn: CUHE A -1; } }
class CWD_Und_Pallet_Wood : CWD_Stand { States { Spawn: CUHF A -1; } }
class CWD_Und_Ladder_Wood : CWD_Stand { States { Spawn: CUHG A -1; } }
class CWD_Und_Vent_GrateSq : CWD_Wall { States { Spawn: CUHH A -1; } }
class CWD_Und_Grate_Rusty : CWD_Wall { States { Spawn: CUHI A -1; } }
class CWD_Und_Moss_A : CWD_Wall { States { Spawn: CUHJ A -1; } }
class CWD_Und_Moss_B : CWD_Wall { States { Spawn: CUHK A -1; } }
class CWD_Und_Moss_C : CWD_Wall { States { Spawn: CUHL A -1; } }
class CWD_Und_Moss_D : CWD_Wall { States { Spawn: CUHM A -1; } }
class CWD_Und_Moss_E : CWD_Wall { States { Spawn: CUHN A -1; } }
class CWD_Und_Moss_F : CWD_Wall { States { Spawn: CUHO A -1; } }
class CWD_Und_Drip_A : CWD_Stand { States { Spawn: CUHP A -1; } }
class CWD_Und_Drip_B : CWD_Stand { States { Spawn: CUHQ A -1; } }
class CWD_Und_Drip_C : CWD_Stand { States { Spawn: CUHR A -1; } }
class CWD_Und_Splash_Small : CWD_Stand { States { Spawn: CUHS A -1; } }
class CWD_Und_Splash_Large : CWD_Stand { States { Spawn: CUHT A -1; } }
class CWD_Und_Can : CWD_Stand { States { Spawn: CUHU A -1; } }
class CWD_Und_Bottle : CWD_Stand { States { Spawn: CUHV A -1; } }
class CWD_Und_Rocks_Small : CWD_Stand { States { Spawn: CUHW A -1; } }
class CWD_Und_Rock_Big : CWD_Stand { States { Spawn: CUHX A -1; } }
class CWD_Und_Trash_Bag : CWD_Stand { States { Spawn: CUHY A -1; } }
class CWD_Und_Pipe_ElbowIron : CWD_Wall { States { Spawn: CUHZ A -1; } }
class CWD_Und_Pipe_ElbowRust : CWD_Wall { States { Spawn: CUH0 A -1; } }
class CWD_Und_Pipe_ElbowVerd : CWD_Wall { States { Spawn: CUH1 A -1; } }
class CWD_Und_Pipe_TeeIron : CWD_Wall { States { Spawn: CUH2 A -1; } }
class CWD_Und_Pipe_ElbowBig : CWD_Wall { States { Spawn: CUH3 A -1; } }
class CWD_Und_Pipe_DoubleLong : CWD_Wall { States { Spawn: CUH4 A -1; } }
class CWD_Und_Pipe_LongIron : CWD_Wall { States { Spawn: CUH5 A -1; } }
class CWD_Und_Pipe_Stack : CWD_Wall { States { Spawn: CUH6 A -1; } }
