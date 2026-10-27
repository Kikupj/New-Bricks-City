// Ported from Corpo Wars (reference/corpowars/zscript/corpowars/kitprops.zs) by tools/import/port_cw_props.py.
// =============================================================================
// Corpo Wars — props for the site kits (street, residential, industrial, underground, civic, tech).
// 3D models are built by CorpoWars_tools/make_models.py (modeldef.props.txt), like the office furniture.
// Footprint = depth along the facing x width across it; the blockers make them solid and count as cover.
// =============================================================================
class CW_FLampPost    : CW_Furniture { Default { Height 120; CW_Furniture.Footprint 10, 10; Tag "Street lamp"; } }
class CW_FContainer   : CW_Furniture { Default { Height 88; CW_Furniture.Footprint 200, 80; Tag "Shipping container"; } }
class CW_FContainerB  : CW_FContainer { Default { Tag "Shipping container"; } }
class CW_FCrates      : CW_Furniture { Default { Height 48; CW_Furniture.Footprint 40, 40; Tag "Crates"; } }
class CW_FPallet      : CW_Furniture { Default { Height 34; CW_Furniture.Footprint 40, 48; Tag "Pallet"; } }
class CW_FBarCounter  : CW_Furniture { Default { Height 44; CW_Furniture.Footprint 28, 128; Tag "Bar"; } }
class CW_FStool       : CW_Furniture { Default { Height 26; Tag "Stool"; } }
class CW_FBed         : CW_Furniture { Default { Height 24; CW_Furniture.Footprint 80, 44; Tag "Bed"; } }
class CW_FPew         : CW_Furniture { Default { Height 34; CW_Furniture.Footprint 24, 96; Tag "Bench"; } }
class CW_FTank        : CW_Furniture { Default { Height 96; CW_Furniture.Footprint 64, 64; Tag "Tank"; } }
class CW_FTransformer : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 48, 64; Tag "Transformer"; } }
class CW_FScaffold    : CW_Furniture { Default { Height 128; CW_Furniture.Footprint 32, 96; Tag "Scaffolding"; } }
class CW_FDumpster    : CW_Furniture { Default { Height 44; CW_Furniture.Footprint 36, 72; Tag "Dumpster"; } }
class CW_FStall       : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 48, 80; Tag "Market stall"; } }
class CW_FGrowBed     : CW_Furniture { Default { Height 40; CW_Furniture.Footprint 36, 120; Tag "Grow bed"; } }
class CW_FTurbine     : CW_Furniture { Default { Height 112; CW_Furniture.Footprint 96, 160; Tag "Turbine"; } }
class CW_FPipes       : CW_Furniture { Default { Height 64; CW_Furniture.Footprint 24, 120; Tag "Pipe rack"; } }
class CW_FGenerator   : CW_Furniture { Default { Height 56; CW_Furniture.Footprint 40, 72; Tag "Generator"; } }
class CW_FTurnstile   : CW_Furniture { Default { Height 40; CW_Furniture.Footprint 32, 12; Tag "Turnstile"; } }
class CW_FLocker      : CW_Furniture { Default { Height 72; CW_Furniture.Footprint 18, 36; Tag "Lockers"; } }
class CW_FScrap       : CW_Furniture { Default { Height 64; CW_Furniture.Footprint 64, 64; Tag "Scrap pile"; } }
class CW_FWorkbench   : CW_Furniture { Default { Height 36; CW_Furniture.Footprint 30, 80; Tag "Workbench"; } }
class CW_FAcUnit      : CW_Furniture { Default { Height 40; CW_Furniture.Footprint 40, 56; Tag "Air-con unit"; } }
class CW_FWaterTower  : CW_Furniture { Default { Height 120; CW_Furniture.Footprint 72, 72; Tag "Water tank"; } }
class CW_FBarrier     : CW_Furniture { Default { Height 32; CW_Furniture.Footprint 20, 72; Tag "Barrier"; } }
class CW_FSandbags    : CW_Furniture { Default { Height 36; CW_Furniture.Footprint 24, 72; Tag "Sandbags"; } }
