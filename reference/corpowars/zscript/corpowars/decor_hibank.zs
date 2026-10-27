// High-tech bank decoration sprites (CHK*): generic fixtures, no brand art. Needs CWD_Wall / CWD_Stand from decor_bank.zs.
// Wall kind: origin at sprite centre, facing = wall normal. Stand kind: origin at bottom centre.

class CWD_Sign_Tellers : CWD_Wall { States { Spawn: CHKA A -1; } }
class CWD_Sign_Executive : CWD_Wall { States { Spawn: CHKB A -1; } }
class CWD_Sign_Loans : CWD_Wall { States { Spawn: CHKC A -1; } }
class CWD_Sign_Vault : CWD_Wall { States { Spawn: CHKD A -1; } }
class CWD_Sign_Security : CWD_Wall { States { Spawn: CHKE A -1; } }
class CWD_Sign_DirectoryFloor1 : CWD_Wall { States { Spawn: CHKF A -1; } }
class CWD_Sign_DirectoryFloor2 : CWD_Wall { States { Spawn: CHKG A -1; } }
class CWD_Sign_RestroomArrow : CWD_Wall { States { Spawn: CHKH A -1; } }
class CWD_Sign_RestroomIcons : CWD_Wall { States { Spawn: CHKI A -1; } }
class CWD_Sign_AuthorizedOnly : CWD_Wall { States { Spawn: CHKJ A -1; } }
class CWD_Wall_MonitorGrid : CWD_Wall { States { Spawn: CHKK A 20 Bright; CHKK B 20 Bright; Loop; } }
class CWD_Poster_Surveillance : CWD_Wall { States { Spawn: CHKL A -1; } }
class CWD_Poster_BadgeNotice : CWD_Wall { States { Spawn: CHKM A -1; } }
class CWD_Poster_TeamEffort : CWD_Wall { States { Spawn: CHKN A -1; } }
class CWD_Poster_CleanDesks : CWD_Wall { States { Spawn: CHKO A -1; } }
class CWD_StanchionRopeBlue : CWD_Stand { States { Spawn: CHKP A -1; } }
class CWD_CoffeeMachineDrip : CWD_Stand { States { Spawn: CHKQ A -1; } }
class CWD_CoffeeMachineSingle : CWD_Stand { States { Spawn: CHKR A -1; } }
class CWD_CoinStacks : CWD_Stand { States { Spawn: CHKS A -1; } }
class CWD_CashCounter : CWD_Stand { States { Spawn: CHKT A -1; } }
class CWD_TableLamp : CWD_Stand { States { Spawn: CHKU A -1; } }
class CWD_Bench : CWD_Stand { States { Spawn: CHKV A -1; } }
class CWD_PlantDesk : CWD_Stand { States { Spawn: CHKW A -1; } }
class CWD_ShelfCart : CWD_Stand { States { Spawn: CHKX A -1; } }
class CWD_ServiceCart : CWD_Stand { States { Spawn: CHKY A -1; } }
class CWD_EquipCart : CWD_Stand { States { Spawn: CHKZ A -1; } }
