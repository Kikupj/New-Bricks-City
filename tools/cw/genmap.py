# Generates Corpo Wars UDMF maps into CorpoWars/maps/. Run from anywhere.
import struct, os
OUT = os.environ.get("CW_MAPS_OUT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars", "maps")
def box_ccw(x,y,w,h): return [(x,y),(x+w,y),(x+w,y+h),(x,y+h)]

def build(name, sectors, things, specials={}, wall="STARG3", floor="FLOOR4_8", ceil="CEIL3_5", edge_tex={}, line_props={}):
    verts=[]; vid={}
    def V(p):
        if p not in vid: vid[p]=len(verts); verts.append(p)
        return vid[p]
    edges={}
    for si,(loops,_) in enumerate(sectors):
        for loop in loops:
            tex = wall
            if isinstance(loop, tuple): loop, tex = loop
            for i in range(len(loop)):
                a,b=loop[i],loop[(i+1)%len(loop)]
                edges.setdefault(frozenset((a,b)),[]).append((a,b,si,tex))
    lines=[]; sides=[]
    for lst in edges.values():
        a,b,s,tex=lst[0]
        if len(lst)==1:
            sides.append(dict(sector=s, texturemiddle=edge_tex.get(frozenset((a,b)), tex)))
            ln=dict(v1=V(a),v2=V(b),sidefront=len(sides)-1,blocking="true")
            sp=specials.get((a,b)) or specials.get((b,a))
            if sp:
                sides[-1]['texturemiddle']="SW1STRTN"
                ln.update(special=sp[0],arg0=sp[1][0],arg1=sp[1][1],arg2=sp[1][2],playeruse="true",repeatspecial="true")
            lines.append(ln)
        else:
            sides.append(dict(sector=s, texturetop=tex, texturebottom=tex)); f=len(sides)-1
            sides.append(dict(sector=lst[1][2], texturetop=tex, texturebottom=tex)); bk=len(sides)-1
            ln=dict(v1=V(a),v2=V(b),sidefront=f,sideback=bk,twosided="true")
            lp=line_props.get(frozenset((a,b)))
            if lp:
                fields, mid, tb = lp[:3]
                sf = lp[3] if len(lp) > 3 else {}
                ln.update(fields)
                for si in (f, bk):
                    sides[si]['texturemiddle']=mid
                    if tb: sides[si]['texturetop']=tb; sides[si]['texturebottom']=tb
                    sides[si].update(sf)
            lines.append(ln)
    def blk(n,d):
        return n+"\n{\n"+"".join(f"{k} = {v if not isinstance(v,str) or v in ('true','false') else chr(34)+v+chr(34)};\n" for k,v in d.items())+"}\n"
    out=['namespace = "zdoom";']
    for x,y in verts: out.append(blk("vertex",dict(x=float(x),y=float(y))))
    for l in lines: out.append(blk("linedef",l))
    for s in sides: out.append(blk("sidedef",s))
    for _,p in sectors:
        out.append(blk("sector",dict(heightfloor=p.get('floorh',0),heightceiling=p.get('ceil',128),texturefloor=p.get('floor',floor),
            textureceiling=p.get('ctex',ceil),lightlevel=p['light'],id=p.get('tag',0))))
    for t in things:
        d=dict(angle=0); d.update(t)
        d.update(skill1="true",skill2="true",skill3="true",skill4="true",skill5="true",single="true",coop="true",dm="true")
        out.append(blk("thing",d))
    tm="\n".join(out).encode()
    lumps=[(name,b""),("TEXTMAP",tm),("ENDMAP",b"")]
    data=b"";dirs=b"";off=12
    for n,c in lumps:
        dirs+=struct.pack("<ii8s",off,len(c),n.encode()); data+=c; off+=len(c)
    open(os.path.join(OUT,name+".wad"),"wb").write(b"PWAD"+struct.pack("<ii",len(lumps),off)+data+dirs)
    print(name, len(verts),"verts",len(lines),"lines")

# ---------------------------------------------------------------- Oriole lab layout (shared by CWTEST + M01)
LAB = [
 ([[(0,0),(0,448),(0,512),(0,576),(0,640),(0,1024),(224,1024),(224,576),(224,448),(224,192),(224,64),(224,0)]], dict(light=40)),
 ([[(256,256),(256,448),(256,576),(256,1024),(1280,1024),(1280,640),(1280,384),(1280,256)],
   box_ccw(544,544,64,64), box_ccw(864,736,96,64), box_ccw(864,448,64,96), box_ccw(1088,640,64,64)], dict(light=176, tag=1)),
 ([[(256,0),(256,64),(256,192),(256,256),(1280,256),(1280,0)]], dict(light=48)),
 ([[(1280,384),(1280,640),(1536,640),(1536,384)]], dict(light=144)),
 ([[(224,448),(224,576),(256,576),(256,448)]], dict(light=40)),
 ([[(224,64),(224,192),(256,192),(256,64)]], dict(light=40)),
]
LAB_SWITCHES = { ((0,448),(0,512)): (113,[1,32,35]), ((0,576),(0,640)): (113,[1,176,35]) }  # Light_Fade
LAB_GUARDS = [
 dict(type=20002,x=400,y=400,id=1,arg0=2,arg1=35),
 dict(type=20002,x=1200,y=400,id=2,arg0=3,arg1=35),
 dict(type=20002,x=1200,y=900,id=3,arg0=4,arg1=70),
 dict(type=20002,x=400,y=900,id=4,arg0=1,arg1=35),
 dict(type=20001,x=400,y=900,angle=0,arg0=1),
 dict(type=20002,x=420,y=128,id=5,arg0=6,arg1=105),
 dict(type=20002,x=1180,y=128,id=6,arg0=5,arg1=105),
 dict(type=20001,x=1180,y=128,angle=180,arg0=5),
 dict(type=20001,x=1470,y=560,angle=180),
 dict(type=85,x=768,y=992), dict(type=85,x=1250,y=992),
]
START = dict(type=1,x=112,y=960,angle=270)

build("CWTEST", LAB, [START, dict(type=5,x=1480,y=440)] + LAB_GUARDS, LAB_SWITCHES)

build("M01", LAB, [START] + LAB_GUARDS + [
 dict(type=20023,x=112,y=990),            # extraction (insertion point)
 dict(type=20025,x=40,y=850),            # transport access (field resupply)
 dict(type=20020,x=1480,y=440),           # Helix prototype (office)
 dict(type=20021,x=1240,y=300),           # research server (hall, by office door)
 dict(type=20022,x=1240,y=40,angle=180),  # Dr. Vance (east end of shadow strip)
 # Oriole staff (civilian witnesses)
 dict(type=20024,x=1330,y=540,angle=0),  # lab tech at the analyst desk
 dict(type=20024,x=1120,y=960,angle=180),  # tech by the radio console
 # set dressing
 dict(type=20102,x=1400,y=600), dict(type=20105,x=1512,y=606), dict(type=20103,x=1512,y=410),
 dict(type=20115,x=1408,y=512),
 dict(type=20103,x=1250,y=340), dict(type=20107,x=1250,y=990),
 dict(type=20109,x=700,y=300), dict(type=20108,x=1000,y=975), dict(type=20110,x=800,y=40),
 dict(type=20111,x=300,y=990), dict(type=20106,x=560,y=990),
], LAB_SWITCHES)

# ---------------------------------------------------------------- Meridian hub office
# North wall centre = world briefing screen, west wall centre = gear locker panel.
HUB_EDGES = {
 frozenset(((256,512),(512,512))): "CWMAPSCR",
 frozenset(((0,128),(0,384))): "CWGEARWL",
}
build("HUB01", [
 ([[(0,0),(0,128),(0,384),(0,512),(256,512),(512,512),(768,512),(768,0)]], dict(light=144, floor="FLAT5_4")),
], [
 dict(type=1,x=384,y=64,angle=90),
 dict(type=20010,x=384,y=462,angle=270),   # acquisitions terminal (command desk)
 dict(type=20101,x=200,y=470), dict(type=20105,x=96,y=486), dict(type=20105,x=60,y=486),
 dict(type=20107,x=576,y=478),
 dict(type=20103,x=744,y=470), dict(type=20103,x=744,y=420), dict(type=20103,x=744,y=370),
 dict(type=20111,x=730,y=180),
 dict(type=20012,x=60,y=256),              # quartermaster gear locker (workbench) under the gear wall
 dict(type=20109,x=80,y=60), dict(type=20108,x=170,y=40), dict(type=20110,x=40,y=440),
 dict(type=20114,x=384,y=256),             # map table
 dict(type=20104,x=330,y=256), dict(type=20104,x=438,y=256),
 dict(type=20115,x=384,y=400), dict(type=20115,x=192,y=256), dict(type=20115,x=576,y=256),
], wall="STARGR1", ceil="CEIL1_1", edge_tex=HUB_EDGES)


# =============================================================================
# Room-and-door layout API + prefab room library
# Rooms are axis-aligned rectangles separated by 16-unit walls; doors are small
# sectors bridging the gap. This is the building block for hand-made levels now
# and for a seeded prefab assembler later (X-COM style: premade chunks, sockets).
# =============================================================================
class Layout:
    WALL = 16
    def __init__(self, name, wall="STARG3", floor="FLOOR4_8", ceil="CEIL3_5"):
        self.name, self.wall, self.floor, self.ceil = name, wall, floor, ceil
        self.rooms = {}          # key -> dict(rect, light, ceil, floor, holes, splits, tex)
        self.doors = []          # (rect, ceil, light)
        self.things = []
        self.next_tid = 100

    def room(self, key, x0, y0, x1, y1, light=160, ceil=128, floor=None, wall=None, holes=()):
        self.rooms[key] = dict(r=(x0, y0, x1, y1), light=light, ceil=ceil, floor=floor or self.floor,
                               wall=wall or self.wall, holes=list(holes),
                               split=dict(L=set(), R=set(), T=set(), B=set()))
        return self

    def door(self, a, b, at, width=64, ceil=104):
        A, B = self.rooms[a]["r"], self.rooms[b]["r"]
        if A[3] < B[1] or B[3] < A[1]:            # stacked vertically
            lo, hi = (a, b) if A[3] < B[1] else (b, a)
            y0, y1 = self.rooms[lo]["r"][3], self.rooms[hi]["r"][1]
            self.rooms[lo]["split"]["T"] |= {at, at + width}
            self.rooms[hi]["split"]["B"] |= {at, at + width}
            rect = (at, y0, at + width, y1)
        else:                                      # side by side
            lf, rt = (a, b) if A[2] < B[0] else (b, a)
            x0, x1 = self.rooms[lf]["r"][2], self.rooms[rt]["r"][0]
            self.rooms[lf]["split"]["R"] |= {at, at + width}
            self.rooms[rt]["split"]["L"] |= {at, at + width}
            rect = (x0, at, x1, at + width)
        light = min(self.rooms[a]["light"], self.rooms[b]["light"])
        self.doors.append((rect, min(ceil, self.rooms[a]["ceil"], self.rooms[b]["ceil"]), light))
        return self

    def tid(self):
        self.next_tid += 1
        return self.next_tid

    def add(self, **t):
        self.things.append(t)

    def patrol(self, pts, wait=35, start_angle=0):
        """Closed patrol loop through pts; spawns one guard at the first point."""
        tids = [self.tid() for _ in pts]
        for i, (x, y) in enumerate(pts):
            self.add(type=20002, x=x, y=y, id=tids[i], arg0=tids[(i + 1) % len(pts)], arg1=wait)
        self.add(type=20001, x=pts[0][0], y=pts[0][1], angle=start_angle, arg0=tids[1 % len(tids)] if len(pts) > 1 else 0)

    def post(self, x, y, angle):
        self.add(type=20001, x=x, y=y, angle=angle)

    # Solid footprint radius per thing type (props, NPCs, objectives). Non-solid things are ignored.
    RADIUS = {20100: 34, 20101: 28, 20102: 30, 20103: 16, 20104: 12, 20105: 14, 20106: 26, 20107: 18,
              20108: 26, 20109: 24, 20110: 24, 20111: 26, 20112: 42, 20113: 16, 20114: 24,
              20020: 16, 20021: 16, 20022: 16, 20024: 16, 20025: 26, 20010: 34, 20012: 42}
    DOOR_CLEAR = 80      # keep this far into each room clear in front of a doorway
    DOOR_SIDE = 24       # extra clearance either side of the door opening

    def door_zones(self):
        zones = []
        for (x0, y0, x1, y1), _, _ in self.doors:
            if y1 - y0 <= self.WALL:   # horizontal wall (rooms above/below)
                zones.append((x0 - self.DOOR_SIDE, y0 - self.DOOR_CLEAR, x1 + self.DOOR_SIDE, y1 + self.DOOR_CLEAR))
            else:                       # vertical wall (rooms left/right)
                zones.append((x0 - self.DOOR_CLEAR, y0 - self.DOOR_SIDE, x1 + self.DOOR_CLEAR, y1 + self.DOOR_SIDE))
        return zones

    def room_of(self, x, y):
        for k, R in self.rooms.items():
            x0, y0, x1, y1 = R["r"]
            if x0 <= x <= x1 and y0 <= y <= y1: return k
        return None

    def validate(self):
        """Keep doorways clear and props inside their rooms. Blocking props are slid along the wall
        away from the door; if no clear spot exists they are dropped. Reports every change."""
        zones = self.door_zones()
        def hits_zone(x, y, r):
            return any(zx0 - r < x < zx1 + r and zy0 - r < y < zy1 + r for zx0, zy0, zx1, zy1 in zones)
        def inside(x, y, r):
            k = self.room_of(x, y)
            if not k: return False
            x0, y0, x1, y1 = self.rooms[k]["r"]
            return x0 + r <= x <= x1 - r and y0 + r <= y <= y1 - r
        placed = []
        def overlaps(x, y, r):
            return any((x - px) ** 2 + (y - py) ** 2 < (r + pr) ** 2 for px, py, pr in placed)
        keep = []
        for t in self.things:
            r = self.RADIUS.get(t["type"])
            if r is None:
                keep.append(t); continue
            x, y = t["x"], t["y"]
            if not hits_zone(x, y, r) and inside(x, y, r) and not overlaps(x, y, r):
                placed.append((x, y, r)); keep.append(t); continue
            moved = False
            for step in range(16, 400, 16):
                for dx, dy in ((step, 0), (-step, 0), (0, step), (0, -step)):
                    nx, ny = x + dx, y + dy
                    if not hits_zone(nx, ny, r) and inside(nx, ny, r) and not overlaps(nx, ny, r) and self.room_of(nx, ny) == self.room_of(x, y):
                        print(f"  {self.name}: moved thing {t['type']} ({x},{y}) -> ({nx},{ny}) to clear a doorway/wall")
                        t["x"], t["y"] = nx, ny; placed.append((nx, ny, r)); keep.append(t); moved = True
                        break
                if moved: break
            if not moved: print(f"  {self.name}: dropped thing {t['type']} at ({x},{y}) - no clear spot")
        self.things = keep

    def build(self, extra_specials=None):
        self.validate()
        sectors = []
        for key, R in self.rooms.items():
            x0, y0, x1, y1 = R["r"]; sp = R["split"]
            left  = [(x0, y) for y in sorted(sp["L"])]
            top   = [(x, y1) for x in sorted(sp["T"])]
            right = [(x1, y) for y in sorted(sp["R"], reverse=True)]
            bot   = [(x, y0) for x in sorted(sp["B"], reverse=True)]
            loop = [(x0, y0)] + left + [(x0, y1)] + top + [(x1, y1)] + right + [(x1, y0)] + bot
            loops = [(loop, R["wall"])] + [(box_ccw(*h[:4]), h[4] if len(h) > 4 else R["wall"]) for h in R["holes"]]
            sectors.append((loops, dict(light=R["light"], ceil=R["ceil"], floor=R["floor"])))
        for (x0, y0, x1, y1), c, light in self.doors:
            sectors.append(([[(x0, y0), (x0, y1), (x1, y1), (x1, y0)]], dict(light=light, ceil=c)))
        build(self.name, sectors, self.things, extra_specials or {}, wall=self.wall, floor=self.floor, ceil=self.ceil)

# ---------------------------------------------------------------- prefab rooms
# Each dresses a room rectangle: props, lights, civilians, guard posts/patrols.
def pf_loading_dock(L, r, start=True):
    x0, y0, x1, y1 = r
    if start:
        L.add(type=1, x=x0 + 96, y=y0 + 112, angle=90)
        L.add(type=20023, x=x0 + 96, y=y0 + 64)                 # extraction
        L.add(type=20025, x=x1 - 64, y=y0 + 48)                 # transport crate
    L.add(type=20109, x=x1 - 80, y=y1 - 64); L.add(type=20108, x=x1 - 176, y=y1 - 56)
    L.add(type=20110, x=x0 + 64, y=y1 - 48)

def pf_storage(L, r):
    x0, y0, x1, y1 = r; cx = (x0 + x1) // 2
    L.add(type=20109, x=cx, y=(y0 + y1) // 2); L.add(type=20111, x=x1 - 40, y=(y0 + y1) // 2)
    L.add(type=20108, x=x0 + 60, y=y1 - 50); L.add(type=20110, x=cx + 120, y=y0 + 40)
    L.patrol([(x0 + 72, y0 + 80), (x1 - 72, y0 + 80), (x1 - 72, y1 - 72), (x0 + 72, y1 - 72)], wait=70)

def pf_server_room(L, r, objective=True):
    x0, y0, x1, y1 = r
    for x in range(x0 + 72, x1 - 40, 72):
        L.add(type=20103, x=x, y=y1 - 40)
        L.add(type=20103, x=x, y=y0 + 40)
    if objective: L.add(type=20021, x=(x0 + x1) // 2, y=(y0 + y1) // 2)
    L.post(x1 - 48, (y0 + y1) // 2, 180)

def pf_corridor(L, r, lights=2):
    x0, y0, x1, y1 = r; cy = (y0 + y1) // 2
    for i in range(lights):
        L.add(type=20115, x=x0 + (x1 - x0) * (2 * i + 1) // (2 * lights), y=cy)
    L.patrol([(x0 + 64, cy), (x1 - 64, cy)], wait=70)

def pf_lobby(L, r):
    x0, y0, x1, y1 = r; cx = (x0 + x1) // 2
    L.add(type=20102, x=cx, y=y1 - 80)                          # reception desk
    L.add(type=20024, x=cx, y=y1 - 130, angle=270)              # receptionist
    L.add(type=20105, x=x0 + 40, y=y1 - 40); L.add(type=20105, x=x0 + 76, y=y1 - 40)
    L.add(type=20115, x=cx, y=(y0 + y1) // 2)
    L.post(x1 - 80, y0 + 90, 180)

def pf_open_office(L, r, civilians=2):
    x0, y0, x1, y1 = r
    rows = [y0 + 96, y1 - 96]
    xs = list(range(x0 + 112, x1 - 80, 160))
    for y in rows:
        for x in xs: L.add(type=20101 if (x // 160) % 2 else 20102, x=x, y=y)
    aisle = (y0 + y1) // 2
    for i, x in enumerate(xs[:civilians]):
        L.add(type=20024, x=x + 40, y=rows[i % 2] + (46 if i % 2 == 0 else -46), angle=90 if i % 2 == 0 else 270)
    L.add(type=20115, x=x0 + (x1 - x0) // 3, y=aisle); L.add(type=20115, x=x0 + 2 * (x1 - x0) // 3, y=aisle)
    L.patrol([(x0 + 72, aisle), (x1 - 72, aisle)], wait=50)

def pf_exec_office(L, r, objective=True):
    x0, y0, x1, y1 = r
    L.add(type=20102, x=x1 - 96, y=y1 - 96); L.add(type=20104, x=x1 - 96, y=y1 - 150)
    L.add(type=20105, x=x1 - 40, y=y0 + 40); L.add(type=20105, x=x1 - 76, y=y0 + 40)
    L.add(type=20107, x=x0 + 48, y=y1 - 40)
    if objective: L.add(type=20020, x=x1 - 60, y=y1 - 40)
    L.add(type=20115, x=(x0 + x1) // 2, y=(y0 + y1) // 2)
    L.post(x1 - 64, (y0 + y1) // 2, 180)

def pf_lab(L, r, scientist=True):
    x0, y0, x1, y1 = r
    L.add(type=20112, x=(x0 + x1) // 2, y=y1 - 48); L.add(type=20114, x=(x0 + x1) // 2, y=(y0 + y1) // 2)
    L.add(type=20111, x=x1 - 40, y=y1 - 60)
    if scientist: L.add(type=20022, x=x1 - 100, y=(y0 + y1) // 2, angle=180)
    L.add(type=20024, x=x0 + 120, y=(y0 + y1) // 2 + 60, angle=0)
    L.add(type=20115, x=(x0 + x1) // 2, y=(y0 + y1) // 2 - 60)
    L.patrol([(x0 + 72, y0 + 72), (x1 - 72, y0 + 72)], wait=60)

# ---------------------------------------------------------------- M02: Castellan R&D Annex
M = Layout("M02", wall="STARGR1", floor="FLAT5_4", ceil="CEIL1_1")
M.room("dock",    0,    0,  512,  384, light=96,  ceil=160, floor="FLOOR4_8", wall="STARG3")
M.room("storage", 528,  0,  1024, 384, light=40,  ceil=128, floor="FLOOR4_8", wall="STARG3")
M.room("server",  1040, 0,  1536, 384, light=56,  ceil=112)
M.room("hall",    0,    400,1536, 528, light=144, ceil=112)
M.room("lobby",   0,    544,512,  960, light=176, ceil=160)
M.room("office",  528,  544,1216, 960, light=160, ceil=128)
M.room("exec",    1232, 544,1536, 960, light=112, ceil=128)
M.room("lab",     528,  976,1216, 1280,light=136, ceil=144)
M.door("dock", "hall", 192).door("storage", "hall", 704).door("server", "hall", 1216)
M.door("dock", "storage", 160)
M.door("hall", "lobby", 256).door("hall", "office", 832)
M.door("lobby", "office", 736).door("office", "exec", 848).door("office", "lab", 640)
R = {k: v["r"] for k, v in M.rooms.items()}
pf_loading_dock(M, R["dock"])
pf_storage(M, R["storage"])
pf_server_room(M, R["server"])
pf_corridor(M, R["hall"], lights=3)
pf_lobby(M, R["lobby"])
pf_open_office(M, R["office"])
pf_exec_office(M, R["exec"])
pf_lab(M, R["lab"])
M.build()


# =============================================================================
# G01: blank modular grid for runtime procedural generation (see procgen.zs)
# Columns/rows have individual sizes so the grid can hold narrow corridors and
# 64-unit service lanes (crawl ducts). 16-unit wall strips between cells.
# A strip edge longer than 96 is three sectors (side / 64 door / side); shorter
# edges are a single sector (k = 1). All strips start CLOSED (ceiling = floor).
#   vertical strip between cell (i,j) and (i+1,j), segment k: tag 1000 + (j*(NX-1)+i)*3 + k
#   horizontal strip between (i,j) and (i,j+1),   segment k: tag 4000 + (j*NX+i)*3 + k
#   cell (i,j) itself (ceiling changes, e.g. ducts):              tag 7000 + j*NX + i
# Keep COLW / ROWH in sync with CW_ProcGen.
# =============================================================================
GRID_COLW = [240, 240, 240, 240, 112, 240, 240, 240, 240, 240]   # col 4 = branch corridor
GRID_ROWH = [240, 240, 64, 240, 112, 240, 240, 64, 240]          # rows 2,7 = service lanes, row 4 = spine

def edge_cuts(L):
    if L > 96:
        d0 = (L - 64) // 2
        return [(0, d0, 0), (d0, d0 + 64, 1), (d0 + 64, L, 2)]
    return [(0, L, 1)]

def build_grid(name, colw=GRID_COLW, rowh=GRID_ROWH, W=16, channel=None):
    NX, NY = len(colw), len(rowh)
    cx = [sum(colw[:i]) + W * i for i in range(NX)]
    cy = [sum(rowh[:j]) + W * j for j in range(NY)]
    sectors = []
    for j in range(NY):
        for i in range(NX):
            x0, y0 = cx[i], cy[j]; x1, y1 = x0 + colw[i], y0 + rowh[j]
            vcut = [c for c in edge_cuts(rowh[j]) if c[2] != 2][1:] if len(edge_cuts(rowh[j])) == 3 else []
            hcut = [c for c in edge_cuts(colw[i]) if c[2] != 2][1:] if len(edge_cuts(colw[i])) == 3 else []
            vs = [edge_cuts(rowh[j])[0][1], edge_cuts(rowh[j])[1][1]] if len(edge_cuts(rowh[j])) == 3 else []
            hs = [edge_cuts(colw[i])[0][1], edge_cuts(colw[i])[1][1]] if len(edge_cuts(colw[i])) == 3 else []
            left  = [(x0, y0 + v) for v in vs] if i > 0 else []
            top   = [(x0 + h, y1) for h in hs] if j < NY - 1 else []
            right = [(x1, y0 + v) for v in reversed(vs)] if i < NX - 1 else []
            bot   = [(x0 + h, y0) for h in reversed(hs)] if j > 0 else []
            ch = channel(i, j) if channel else None
            if ch == 'h' and vs:      # three bands along x: outer / 64u channel / outer
                ya, yb = y0 + vs[0], y0 + vs[1]
                sectors.append(([[(x0, y0), (x0, ya), (x1, ya), (x1, y0)] + bot], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
                sectors.append(([[(x0, ya), (x0, yb), (x1, yb), (x1, ya)]], dict(light=128, ceil=128, floor="FLAT5_4", tag=8000 + j * NX + i)))
                sectors.append(([[(x0, yb), (x0, y1)] + top + [(x1, y1), (x1, yb)]], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
                continue
            if ch == 'v' and hs:      # three bands along y
                xa, xb = x0 + hs[0], x0 + hs[1]
                sectors.append(([[(x0, y0)] + left + [(x0, y1), (xa, y1), (xa, y0)]], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
                sectors.append(([[(xa, y0), (xa, y1), (xb, y1), (xb, y0)]], dict(light=128, ceil=128, floor="FLAT5_4", tag=8000 + j * NX + i)))
                sectors.append(([[(xb, y0), (xb, y1), (x1, y1)] + right + [(x1, y0)]], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
                continue
            loop = [(x0, y0)] + left + [(x0, y1)] + top + [(x1, y1)] + right + [(x1, y0)] + bot
            sectors.append(([loop], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
    for j in range(NY):
        for i in range(NX - 1):          # vertical strips
            x0 = cx[i] + colw[i]; x1 = x0 + W; y0 = cy[j]
            for a, b, k in edge_cuts(rowh[j]):
                sectors.append(([[(x0, y0 + a), (x0, y0 + b), (x1, y0 + b), (x1, y0 + a)]],
                                dict(light=128, ceil=0, tag=1000 + (j * (NX - 1) + i) * 3 + k)))
    for j in range(NY - 1):
        for i in range(NX):              # horizontal strips
            y0 = cy[j] + rowh[j]; y1 = y0 + W; x0 = cx[i]
            for a, b, k in edge_cuts(colw[i]):
                sectors.append(([[(x0 + a, y0), (x0 + a, y1), (x0 + b, y1), (x0 + b, y0)]],
                                dict(light=128, ceil=0, tag=4000 + (j * NX + i) * 3 + k)))
    things = [dict(type=1, x=cx[0] + colw[0] // 2, y=cy[0] + rowh[0] // 2 + 40, angle=90)]
    build(name, sectors, things, {}, wall="STARGR1", floor="FLAT5_4", ceil="CEIL1_1")

build_grid("G01")

# G02: centre-core office floor (see floorgen.zs). Ring by ring from the facade:
# perimeter offices 176, open-plan aisle 144, interior band 176, corridor loop 128, core 3 x 160.
G02_SIZES = [176, 144, 176, 128, 160, 160, 160, 128, 176, 144, 176]
def g02_channel(i, j):
    # interior-band cells (ring 2, not ring corners) carry a 64u crawl channel along the band,
    # lined up with the door segments: a duct cell closes its outer bands and keeps only the channel.
    n = len(G02_SIZES)
    d = min(i, j, n - 1 - i, n - 1 - j)
    if d != 2: return None
    if j in (2, n - 3) and 3 <= i <= n - 4: return 'h'
    if i in (2, n - 3) and 3 <= j <= n - 4: return 'v'
    return None

def ccw_area(poly):
    return sum(poly[k][0] * poly[(k + 1) % len(poly)][1] - poly[(k + 1) % len(poly)][0] * poly[k][1] for k in range(len(poly))) / 2

def cw(poly):   # sector loops in this file run clockwise (negative area)
    return poly if ccw_area(poly) < 0 else list(reversed(poly))

def build_floor(name, sizes, W=16, PANEL=20, TREAD=16, WIN_END=16, RECESS=24, VIEW=320):
    """G02 office floor: the modular grid (see build_grid) plus
       - every non-channel cell split into an outer ring (tag 7000+, crown/soffit), a 16u tread ring (tag 9000+)
         and a centre panel (tag 10000+) so the generator can shape two-step ceilings (coffers, ducts, light coves)
         and two-step floors (sunken pits)
       - window bays on the facade: a recess (sill 32, header 104) behind real glass, looking out over a
         sky-lit band with the street far below."""
    NX = NY = len(sizes)
    cx = [sum(sizes[:i]) + W * i for i in range(NX)]
    X = cx[-1] + sizes[-1]
    sectors = []; lprops = {}
    glass_pts = {0: [], 1: [], 2: [], 3: []}   # per side: coordinate along the side of each glass endpoint
    room = dict(light=128, ceil=100, floor="CWCARP1", ctex="CWCEILT")
    for j in range(NY):
        for i in range(NX):
            x0, y0 = cx[i], cx[j]; x1, y1 = x0 + sizes[i], y0 + sizes[j]
            ec = lambda L: [edge_cuts(L)[0][1], edge_cuts(L)[1][1]] if len(edge_cuts(L)) == 3 else []
            vs, hs = ec(sizes[j]), ec(sizes[i])
            left  = [(x0, y0 + v) for v in vs] if i > 0 else [(x0, y0 + WIN_END), (x0, y1 - WIN_END)]
            top   = [(x0 + h, y1) for h in hs] if j < NY - 1 else [(x0 + WIN_END, y1), (x1 - WIN_END, y1)]
            right = [(x1, y0 + v) for v in reversed(vs)] if i < NX - 1 else [(x1, y1 - WIN_END), (x1, y0 + WIN_END)]
            bot   = [(x0 + h, y0) for h in reversed(hs)] if j > 0 else [(x1 - WIN_END, y0), (x0 + WIN_END, y0)]
            tag = 7000 + j * NX + i
            ch = g02_channel(i, j)
            if ch == 'h':
                ya, yb = y0 + vs[0], y0 + vs[1]
                sectors.append(([[(x0, y0), (x0, ya), (x1, ya), (x1, y0)] + bot], dict(room, tag=tag)))
                sectors.append(([[(x0, ya), (x0, yb), (x1, yb), (x1, ya)]], dict(room, tag=8000 + j * NX + i)))
                sectors.append(([[(x0, yb), (x0, y1)] + top + [(x1, y1), (x1, yb)]], dict(room, tag=tag)))
            elif ch == 'v':
                xa, xb = x0 + hs[0], x0 + hs[1]
                sectors.append(([[(x0, y0)] + left + [(x0, y1), (xa, y1), (xa, y0)]], dict(room, tag=tag)))
                sectors.append(([[(xa, y0), (xa, y1), (xb, y1), (xb, y0)]], dict(room, tag=8000 + j * NX + i)))
                sectors.append(([[(xb, y0), (xb, y1), (x1, y1)] + right + [(x1, y0)]], dict(room, tag=tag)))
            else:
                loop = [(x0, y0)] + left + [(x0, y1)] + top + [(x1, y1)] + right + [(x1, y0)] + bot
                P, Q = PANEL, PANEL + TREAD
                sectors.append(([loop, box_ccw(x0 + P, y0 + P, sizes[i] - 2 * P, sizes[j] - 2 * P)], dict(room, tag=tag)))
                sectors.append(([cw(box_ccw(x0 + P, y0 + P, sizes[i] - 2 * P, sizes[j] - 2 * P)),
                                 box_ccw(x0 + Q, y0 + Q, sizes[i] - 2 * Q, sizes[j] - 2 * Q)], dict(room, tag=9000 + j * NX + i)))
                sectors.append(([cw(box_ccw(x0 + Q, y0 + Q, sizes[i] - 2 * Q, sizes[j] - 2 * Q))], dict(room, tag=10000 + j * NX + i)))
            # window bays on outer edges: recess sector, glass line toward the view band
            bays = []
            if j == 0:      bays.append((0, (x0 + WIN_END, y0), (x1 - WIN_END, y0), (0, -1)))
            if i == NX - 1: bays.append((1, (x1, y0 + WIN_END), (x1, y1 - WIN_END), (1, 0)))
            if j == NY - 1: bays.append((2, (x0 + WIN_END, y1), (x1 - WIN_END, y1), (0, 1)))
            if i == 0:      bays.append((3, (x0, y0 + WIN_END), (x0, y1 - WIN_END), (-1, 0)))
            for side, A, B, n in bays:
                A2 = (A[0] + n[0] * RECESS, A[1] + n[1] * RECESS); B2 = (B[0] + n[0] * RECESS, B[1] + n[1] * RECESS)
                sectors.append(([cw([A, B, B2, A2])], dict(light=150, floorh=28, ceil=88, floor="CWWALLH", ctex="CWWALLH")))
                lprops[frozenset((A2, B2))] = (dict(blocking="true", blockprojectiles="true", blockhitscan="true",
                                                   renderstyle="translucent", alpha=0.22), "CWGLASS", "ADGLASSB")
                along = 0 if side in (0, 2) else 1
                glass_pts[side] += [A2[along], B2[along]]
    # view band around the building (street far below, sky above), and a zero-height sky ring beyond it
    R, V = RECESS, VIEW
    lo, hi = -R, X + R
    hole = [(x, lo) for x in [lo] + sorted(glass_pts[0]) + [hi]]
    hole += [(hi, y) for y in sorted(glass_pts[1]) + [hi]]
    hole += [(x, hi) for x in sorted(glass_pts[2], reverse=True) + [lo]]
    hole += [(lo, y) for y in sorted(glass_pts[3], reverse=True)]
    dedup = []
    for p in hole:
        if not dedup or dedup[-1] != p: dedup.append(p)
    if dedup[0] == dedup[-1]: dedup.pop()
    outer = cw(box_ccw(lo - V, lo - V, hi - lo + 2 * V, hi - lo + 2 * V))
    sectors.append((([outer, (dedup, "ADGLASSB")]), dict(light=144, floorh=-1024, ceil=1536, floor="ADFCITY", ctex="F_SKY1")))
    sky = cw(box_ccw(lo - V - 16, lo - V - 16, hi - lo + 2 * V + 32, hi - lo + 2 * V + 32))
    sectors.append(([sky, box_ccw(lo - V, lo - V, hi - lo + 2 * V, hi - lo + 2 * V)], dict(light=144, floorh=-1024, ceil=-1024, floor="F_SKY1", ctex="F_SKY1")))
    # wall strips between cells, all closed (see build_grid)
    for j in range(NY):
        for i in range(NX - 1):
            x0 = cx[i] + sizes[i]; x1 = x0 + W; y0 = cx[j]
            for a, b, k in edge_cuts(sizes[j]):
                sectors.append(([[(x0, y0 + a), (x0, y0 + b), (x1, y0 + b), (x1, y0 + a)]], dict(light=128, ceil=0, tag=1000 + (j * (NX - 1) + i) * 3 + k)))
    for j in range(NY - 1):
        for i in range(NX):
            y0 = cx[j] + sizes[j]; y1 = y0 + W; x0 = cx[i]
            for a, b, k in edge_cuts(sizes[i]):
                sectors.append(([[(x0 + a, y0), (x0 + a, y1), (x0 + b, y1), (x0 + b, y0)]], dict(light=128, ceil=0, tag=4000 + (j * NX + i) * 3 + k)))
    etex = {}
    for ox, oy in STAIR_TOWERS: stair_tower(sectors, lprops, etex, ox, oy)
    things = [dict(type=1, x=cx[0] + sizes[0] // 2, y=cx[0] + sizes[0] // 2, angle=90)]
    build(name, sectors, things, {}, wall="CWWALLH", floor="CWCARP1", ceil="CWCEILT", line_props=lprops, edge_tex=etex)

# Stair towers (off the floor plate, reached through the fire door in each stairwell vestibule; see
# CW_StairDoor). A square spiral round a solid core: corner landings one storey apart (160) joined by
# 16-step flights on three sides, so nothing overlaps and no 3D floors are needed. Landing heights:
# C0 -160 (floor below), C1 0 (this floor), C2 +160, C3 +320. Each landing's outer wall is its fire door.
# Keep STAIR_TOWERS / the landing layout in sync with floorgen.zs (TOWER_X/TOWER_Y, TowerLanding).
STAIR_TOWERS = [(2400, 0), (2400, 800)]
def stair_tower(sectors, lprops, etex, ox, oy, L=64, K=224, N=16, RISE=10, HEAD=128):
    S = K + 2 * L; d = K // N
    base = dict(light=96, floor="CWSTAIF", ctex="CWCEILD")
    wall = "ADCONC1"
    H = [-160, 0, 160, 320]
    def sec(poly, fh, **kw):
        p = dict(base, floorh=fh, ceil=fh + HEAD); p.update(kw)
        sectors.append(([(cw(poly), wall)], p))
    corners = [(ox, oy), (ox + L + K, oy), (ox + L + K, oy + L + K), (ox, oy + L + K)]
    # landings: add the neighbouring flight's step vertices where they share an edge (none do: flights
    # meet landings edge to edge), plus the door wall
    for k, (x, y) in enumerate(corners):
        sec(box_ccw(x, y, L, L), H[k])
    doors = [((ox, oy), (ox, oy + L)), ((ox + S, oy), (ox + S, oy + L)),
             ((ox + S, oy + L + K), (ox + S, oy + S)), ((ox, oy + L + K), (ox, oy + S))]
    for a, b in doors: etex[frozenset((a, b))] = "CWDOORF"
    # flight A (south lane, climbing east) C0 -> C1
    for k in range(N):
        x0 = ox + L + k * d
        sec(box_ccw(x0, oy, d, L), H[0] + RISE * (k + 1))
    # flight B (east lane, climbing north) C1 -> C2
    for k in range(N):
        y0 = oy + L + k * d
        sec(box_ccw(ox + L + K, y0, L, d), H[1] + RISE * (k + 1))
    # flight C (north lane, climbing west) C2 -> C3
    for k in range(N):
        x1 = ox + L + K - k * d
        sec(box_ccw(x1 - d, oy + L + K, d, L), H[2] + RISE * (k + 1))
    # the core (K x K) is solid: no sector, so every flight's inner side is a wall, as in a real stair core


build_floor("G02", G02_SIZES)


# ---------------------------------------------------------------- G05: underground parking garage (level B1)
# Shared by garage insertions and extraction scenarios. Geometry only: the deck, pillars and the lift lobby;
# cars, lights, people and the doors up to the building are placed by CW_GarageGen (garage.zs).
# Keep GARAGE_* in sync with garage.zs.
def build_garage(name):
    W, H = 1792, 1280                     # deck
    LX0, LX1, LY1 = 768, 1024, 1440       # lift lobby on the north wall
    deck = [(0, 0), (0, H), (LX0, H), (LX1, H), (W, H), (W, 0)]
    pillars = [box_ccw(x - 16, y - 16, 32, 32) for x in range(256, W, 256) for y in (384, 896)]
    lobby = [(LX0, H), (LX0, LY1), (LX0 + 96, LY1), (LX1 - 96, LY1), (LX1, LY1), (LX1, H)]
    build(name, [
        ([deck] + pillars, dict(light=112, floor="CWCONCF", ctex="ADCONC1", ceil=112)),
        ([lobby], dict(light=168, floor="ADFMARB", ctex="ADCONC1", ceil=112)),
    ], [dict(type=1, x=896, y=1360, angle=270)], wall="CWCONCW", edge_tex={
        frozenset(((LX0 + 96, LY1), (LX1 - 96, LY1))): "CWDOORE",
    })

build_garage("G05")


# ---------------------------------------------------------------- kit templates (K01-K06, see kitgen.zs)
# A blank modular grid like G01, for the site kits: street block, residential floor, industrial lot,
# underground, civic hall, tech interior. The kit generator carves it at runtime.
#   cell (i,j)                                   tag 7000 + j*NX + i
#   vertical strip between (i,j) and (i+1,j)     tag 1000 + (j*(NX-1)+i)*3 + k    (k = side / 64 door / side)
#   horizontal strip between (i,j) and (i,j+1)   tag 4000 + (j*NX+i)*3 + k
#   corner post between (i,j) .. (i+1,j+1)       tag 11000 + j*(NX-1) + i         (opened when all four cells share a room)
# Strips and posts start CLOSED (ceiling = floor = 0). Keep KIT_GRIDS in sync with CW_KitGen.Sizes().
KIT_GRIDS = {
    "K01": ([208, 96] + [176] * 11 + [96], [208, 96, 176, 176, 176, 176, 112, 128]),       # street block
    "K02": ([128] + [176] * 10 + [128], [96, 176, 176, 112, 176, 176, 96]),                # residential floor
    "K03": ([256] * 11, [192] + [256] * 8),                                                  # industrial lot
    "K04": ([128] * 16, [128] * 14),                                                         # underground
    "K05": ([176] * 12, [128] + [176] * 8),                                                  # civic hall
    "K06": ([176] * 12, [176] * 10),                                                         # tech interior
}

def build_kit(name, colw, rowh, W=16):
    NX, NY = len(colw), len(rowh)
    cx = [sum(colw[:i]) + W * i for i in range(NX)]
    cy = [sum(rowh[:j]) + W * j for j in range(NY)]
    sectors = []
    for j in range(NY):
        for i in range(NX):
            x0, y0 = cx[i], cy[j]; x1, y1 = x0 + colw[i], y0 + rowh[j]
            ec = lambda L: [edge_cuts(L)[0][1], edge_cuts(L)[1][1]] if len(edge_cuts(L)) == 3 else []
            vs, hs = ec(rowh[j]), ec(colw[i])
            left  = [(x0, y0 + v) for v in vs] if i > 0 else []
            top   = [(x0 + h, y1) for h in hs] if j < NY - 1 else []
            right = [(x1, y0 + v) for v in reversed(vs)] if i < NX - 1 else []
            bot   = [(x0 + h, y0) for h in reversed(hs)] if j > 0 else []
            loop = [(x0, y0)] + left + [(x0, y1)] + top + [(x1, y1)] + right + [(x1, y0)] + bot
            sectors.append(([cw(loop)], dict(light=128, ceil=128, floor="FLAT5_4", tag=7000 + j * NX + i)))
    for j in range(NY):
        for i in range(NX - 1):
            x0 = cx[i] + colw[i]; x1 = x0 + W; y0 = cy[j]
            for a, b, k in edge_cuts(rowh[j]):
                sectors.append(([cw([(x0, y0 + a), (x0, y0 + b), (x1, y0 + b), (x1, y0 + a)])], dict(light=128, ceil=0, tag=1000 + (j * (NX - 1) + i) * 3 + k)))
    for j in range(NY - 1):
        for i in range(NX):
            y0 = cy[j] + rowh[j]; y1 = y0 + W; x0 = cx[i]
            for a, b, k in edge_cuts(colw[i]):
                sectors.append(([cw([(x0 + a, y0), (x0 + a, y1), (x0 + b, y1), (x0 + b, y0)])], dict(light=128, ceil=0, tag=4000 + (j * NX + i) * 3 + k)))
    for j in range(NY - 1):
        for i in range(NX - 1):
            x0 = cx[i] + colw[i]; y0 = cy[j] + rowh[j]
            sectors.append(([cw(box_ccw(x0, y0, W, W))], dict(light=128, ceil=0, tag=11000 + j * (NX - 1) + i)))
    # view band all round (tag 12000): far below and open to the sky. The boundary lines are two-sided but
    # blocking; the generator paints them as walls (mid texture) where the edge room is indoors, and leaves
    # them open where it's a roof, a yard or a fire escape, so you see the city instead of a box.
    X, Y = cx[-1] + colw[-1], cy[-1] + rowh[-1]
    VIEW = 384
    xs = sorted(set([v for i in range(NX) for v in (cx[i], cx[i] + colw[i])]))
    ys = sorted(set([v for j in range(NY) for v in (cy[j], cy[j] + rowh[j])]))
    hole = [(x, 0) for x in xs] + [(X, y) for y in ys[1:]] + [(x, Y) for x in reversed(xs[:-1])] + [(0, y) for y in reversed(ys[1:-1])]
    outer = cw(box_ccw(-VIEW, -VIEW, X + 2 * VIEW, Y + 2 * VIEW))
    sectors.append(([outer, hole], dict(light=144, floorh=-768, ceil=1024, floor="ADFCITY", ctex="F_SKY1", tag=12000)))
    lprops = {}
    for k in range(len(hole)):
        a, b = hole[k], hole[(k + 1) % len(hole)]
        lprops[frozenset((a, b))] = (dict(blocking="true", blockmonsters="true"), "-", None)
    things = [dict(type=1, x=cx[0] + colw[0] // 2, y=cy[0] + rowh[0] // 2, angle=90)]
    build(name, sectors, things, {}, wall="CWCONCW", floor="FLAT5_4", ceil="CEIL1_1", line_props=lprops)

for _k, (_c, _r) in KIT_GRIDS.items(): build_kit(_k, _c, _r)


# ---------------------------------------------------------------- C01: city district prototype (see citygen.zs)
# 8x8 blocks: the outer ring (block index 0 and 7) is FILLER (non-enterable, one sector per block), the inner
# 6x6 blocks are the playable district (2x2 lots each). Streets are 320 (side streets) / 384 (avenues and the
# perimeter road), sidewalks CITY_SW wide, both counted inside the street width. Every lot has a small door notch
# (CITY_NOTCH_W x CITY_NOTCH_D) cut into its street face; the runtime generator keeps it open (with a door
# texture, sign and light) only for enterable buildings and fills it in for all others.
# Around the grid sit the boundary bands (all LOW - nothing taller than a ~64 fence anywhere you can walk):
#   east  = quay + sea wall railing + water (pier stub, far-shore islands)
#   north = shoulder, jersey curb, fenced embankment, elevated highway deck on pillars, on-ramp stubs ending in barriers
#   south = shoulder, jersey curb, fenced gravel bank, elevated rail viaduct
#   west  = shoulder, jersey curb, chain-link fence, railway cutting (trench), retaining wall
# beyond each barrier the ground continues with FILLER blocks (raised sectors, sparser outward) up to a "skirt"
# (low sky-ceilinged ring) at the world edge, so there is never a tall wall and never a void.
# Sector tags: lots CITY_TAG0+lot (lot = ly*16+lx), notches CITY_NTAG0+lot, ring-filler blocks CITY_FTAG0+by*8+bx.
# Keep the constants in sync with CW_CityGen (citygen.zs).
import random
from collections import defaultdict
from bisect import bisect_left, bisect_right

# City districts C01..C05 (round 3, 2x scale): all built by citydist.py from one profile-driven builder.
import citydist
citydist.main(OUT, os.environ.get("CW_CITYDATA") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars", "citydist.txt"))
