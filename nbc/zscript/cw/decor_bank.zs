// Ported from Corpo Wars (reference/corpowars/zscript/corpowars/decor_bank.zs) by tools/import/port_cw_props.py.
// Low-tech bank decoration sprites (CBK*), converted from the bank reference sheet.
// Non-solid, single-angle. Wall kind = WALLSPRITE, actor origin at the sprite centre, facing = the wall normal (like CW_FloorSign).
// Stand kind = origin at the bottom centre. Spawn with: Spawn("CWD_Bank_Sign", pos); a.angle = <facing>;
class CWD_Wall : Actor { Default { +NOGRAVITY; +NOBLOCKMAP; +WALLSPRITE; +DONTSPLASH; Radius 2; Height 8; }
	// NBC: placed as a map thing (Obsidian room prefabs) it starts on the floor; lift it to wall height.
	override void PostBeginPlay() { Super.PostBeginPlay(); if (pos.z <= floorz + 1) SetZ(floorz + 44); }
}
class CWD_Stand : Actor { Default { +NOBLOCKMAP; +DONTSPLASH; Radius 8; Height 16; } }

class CWD_Bank_Sign : CWD_Wall { Default { Tag "Trident Credit lobby sign"; } States { Spawn: CBKA A -1; Stop; } }
class CWD_Bank_PosterCredit : CWD_Wall { Default { Tag "Poster: Credit Loans Checks Cashed"; } States { Spawn: CBKB A -1; Stop; } }
class CWD_Bank_PosterTomorrow : CWD_Wall { Default { Tag "Poster: A Better Tomorrow Today"; } States { Spawn: CBKC A -1; Stop; } }
class CWD_Bank_PosterLoans : CWD_Wall { Default { Tag "Poster: Loans Not Promises"; } States { Spawn: CBKD A -1; Stop; } }
class CWD_Bank_PosterWork : CWD_Wall { Default { Tag "Poster: Hard Work Pays Off?"; } States { Spawn: CBKE A -1; Stop; } }
class CWD_Bank_PosterSkyline : CWD_Wall { Default { Tag "Tall night skyline print"; } States { Spawn: CBKF A -1; Stop; } }
class CWD_Bank_Camera : CWD_Wall { Default { Tag "Dome security camera"; } States { Spawn: CBKG A -1; Stop; } }
class CWD_Bank_Clock : CWD_Wall { Default { Tag "Wall clock"; } States { Spawn: CBKH A -1; Stop; } }
class CWD_Bank_FireAlarm : CWD_Wall { Default { Tag "Fire alarm pull station"; } States { Spawn: CBKI A -1; Stop; } }
class CWD_Bank_Certificate : CWD_Wall { Default { Tag "Framed certificate"; } States { Spawn: CBKJ A -1; Stop; } }
class CWD_Bank_Painting : CWD_Wall { Default { Tag "Framed skyline painting"; } States { Spawn: CBKK A -1; Stop; } }
class CWD_Bank_Bulletin : CWD_Wall { Default { Tag "Cork bulletin board"; } States { Spawn: CBKL A -1; Stop; } }
class CWD_Bank_NoSmoking : CWD_Wall { Default { Tag "No smoking sign"; } States { Spawn: CBKM A -1; Stop; } }
class CWD_Bank_Extinguisher : CWD_Wall { Default { Tag "Fire extinguisher (wall-mounted)"; } States { Spawn: CBKN A -1; Stop; } }
class CWD_Bank_DeskClutter : CWD_Stand { Default { Tag "Shelf with old PC, banker lamp, stamps, tape"; } States { Spawn: CBKO A -1; Stop; } }
class CWD_Bank_ArchiveBox : CWD_Stand { Default { Tag "Archive box"; } States { Spawn: CBKP A -1; Stop; } }
class CWD_Bank_PapersTall : CWD_Stand { Default { Tag "Tall paper stack"; } States { Spawn: CBKQ A -1; Stop; } }
class CWD_Bank_PapersShort : CWD_Stand { Default { Tag "Short paper stack"; } States { Spawn: CBKR A -1; Stop; } }
class CWD_Bank_Binders : CWD_Stand { Default { Tag "Three ring binders"; } States { Spawn: CBKS A -1; Stop; } }
class CWD_Bank_Books : CWD_Stand { Default { Tag "Ledgers and books"; } States { Spawn: CBKT A -1; Stop; } }
class CWD_Bank_PapersLoose : CWD_Stand { Default { Tag "Paper stack, loose"; } States { Spawn: CBKU A -1; Stop; } }
class CWD_Bank_Phone : CWD_Stand { Default { Tag "Desk phone"; } States { Spawn: CBKV A -1; Stop; } }
class CWD_Bank_Mug : CWD_Stand { Default { Tag "Coffee mug"; } States { Spawn: CBKW A -1; Stop; } }
class CWD_Bank_PenCup : CWD_Stand { Default { Tag "Pen cup"; } States { Spawn: CBKX A -1; Stop; } }
class CWD_Bank_DeskLamp : CWD_Stand { Default { Tag "Articulated desk lamp"; } States { Spawn: CBKY A -1; Stop; } }
class CWD_Bank_WetFloor : CWD_Stand { Default { Tag "Wet floor sign"; } States { Spawn: CBKZ A -1; Stop; } }
class CWD_Bank_StanchionRope : CWD_Stand { Default { Tag "Two stanchions with red velvet rope"; } States { Spawn: CBK0 A -1; Stop; } }
class CWD_Bank_Stanchions : CWD_Stand { Default { Tag "Pair of stanchions, no rope"; } States { Spawn: CBK1 A -1; Stop; } }
class CWD_Bank_TrashBag : CWD_Stand { Default { Tag "Black rubbish bag"; } States { Spawn: CBK2 A -1; Stop; } }
class CWD_Bank_MopBucket : CWD_Stand { Default { Tag "Yellow mop bucket with mop"; } States { Spawn: CBK3 A -1; Stop; } }
class CWD_Bank_CartSmall : CWD_Stand { Default { Tag "Utility cart with a box"; } States { Spawn: CBK4 A -1; Stop; } }
class CWD_Bank_CartBoxes : CWD_Stand { Default { Tag "Hand cart stacked with boxes"; } States { Spawn: CBK5 A -1; Stop; } }
class CWD_Bank_BoxPile : CWD_Stand { Default { Tag "Pile of cardboard boxes"; } States { Spawn: CBK6 A -1; Stop; } }
