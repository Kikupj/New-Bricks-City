import sys; sys.path.insert(0,'.')
from trace import *
import lib, os, json, io, struct, zlib, math
import px
MAT=lib.MAT
for k,v in {'olive':'#8a9a64 #66744a #4c5836 #343e24 #1e2614','conc':'#d0d4d8 #a8aeb4 #848a92 #5c626a #3c4048','cork':'#d8a468 #b8804a #94602c #6c4420 #442a12','orange':'#f8a860 #e07a28 #b05a18 #7c3c0c #4a2206','blue':'#5a86d0 #2e5aa8 #204486 #16305e #0c1c3a','rust':'#d89058 #b06a38 #86481e #5c300e #381c08','navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022','amber':'#fff2b8 #ffd468 #e2a624 #a26e12 #60400a','cool':'#ffffff #e8f4ff #c8dcf0 #90a8c0 #5a6c80'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); GR=MAT['glow']; BL=MAT['black']; ST=MAT['steel']
os.makedirs('out',exist_ok=True); OUTS={}; CODES='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
def done(name,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    n=len(OUTS); fn=('CIN' if n<36 else 'CIO')+CODES[n%36]
    W,H=S.w,S.h; ox,oy=(W//2,H//2) if kind=='wall' else (W//2,H)
    b=io.BytesIO(); S.im.save(b,'PNG'); d=b.getvalue(); ch=lambda t,x:struct.pack('>I',len(x))+t+x+struct.pack('>I',zlib.crc32(t+x)&0xffffffff)
    open(f'out/{fn}A0.png','wb').write(d[:33]+ch(b'grAb',struct.pack('>ii',ox,oy))+d[33:]); OUTS[name]=(kind,W,H,fn)
def arrow(S,x,y,c=CREAM,left=False):
    rows=("00100","01000","11111","01000","00100") if left else ("00100","00010","11111","00010","00100")
    for j,row in enumerate(rows):
        for i,v in enumerate(row):
            if v=='1': S.dot(x+i,y+j,c)
def ctext(S,cx,y,t,c,sp=1): S.text(cx-(len(t)*(3+sp)-sp)//2,y,t,c,sp)
def circ(S,cx,cy,r,c):
    for a in range(0,360,3): S.dot(cx+round(r*math.cos(math.radians(a))),cy+round(r*math.sin(math.radians(a))),c)
def wheels(S,xs,y,r=2):
    for x in xs: S.ell('black',x-r,y,x+r,y+2*r); S.dot(x,y+r,ST[1])
YEL=MAT['yellow']
import random
for k,v in {'brick':'#8e7462 #6c5648 #52413a #382c28 #221a18','white':'#ffffff #eef0f2 #ced3d9 #9ba3ad #666e7a','dwood':'#7a5238 #5a3a26 #442a1a #2e1c10 #1a0e08','gray':'#8a8e96 #686c74 #50545c #383c44 #22252c','tealb':'#4a86b8 #2e6494 #204c74 #163650 #0c2036'}.items(): MAT[k]=[hx(c) for c in v.split()]
YEL=MAT['yellow']; RED=MAT['red']; WD=MAT['wood']; ORG=MAT['orange']; WH=MAT['white']; CN=MAT['cool']
def bigt(S,cx,y,t,c,k=3):
    T=Spr(len(t)*4,5,1); T.text(0,0,t,(255,255,255,255)); w=len(t)*4-1; x0=cx-(w*k)//2
    for j in range(5):
        for i in range(w):
            if T.px[i,j][3]>0: S.rect_px(c,x0+i*k,y+j*k,k,k)
def stripes(S,x,y,w,h,a=None,b=None,p=4):
    a=a or YEL[1]; b=b or BL[2]
    for j in range(h):
        for i in range(w): S.dot(x+i,y+j,a if ((i+j)//p)%2==0 else b)
# ---------- wall signs
S=Spr(32,48,1); S.rect('paper',0,0,32,48); S.rect('red',0,0,32,11); ctext(S,16,3,'DANGER',WH[0])
S.poly('yellow',[(16,14),(6,32),(26,32)],edge=False); S.poly('black',[(18,17),(11,27),(15,27),(13,31),(21,22),(17,22)],edge=False)
ctext(S,16,34,'HIGH',RED[2]); ctext(S,16,40,'VOLTAGE',RED[2]); done('Sign_HighVoltage',S,'wall')
S=Spr(34,38,2); S.rect('blue',0,0,34,38); S.rect_px(MAT['blue'][4],2,2,30,34); S.rect_px(MAT['blue'][2],3,3,28,32); ctext(S,17,6,'LEVEL',CREAM); bigt(S,17,16,'B',CREAM,4); done('Sign_LevelB',S,'wall')
for nm,t,sd in (('Stencil_B1','B1',3),('Stencil_E1','E1',4)):
    S=Spr(34,30,sd); S.rect('conc',0,0,34,30,noise=.03); bigt(S,17,7,t,MAT['conc'][3],4); done(nm,S,'wall')
S=Spr(44,12,5); S.rect('yellow',0,0,44,12,edge=False); stripes(S,0,0,44,12); S.rect_px(BL[4],0,0,44,1); S.rect_px(BL[4],0,11,44,1); done('Hazard_Panel_H',S,'wall')
S=Spr(12,52,6); stripes(S,0,0,12,52); S.rect_px(BL[4],0,0,1,52); S.rect_px(BL[4],11,0,1,52); done('Hazard_Panel_V',S,'wall')
S=Spr(34,40,7); S.rect('yellow',0,0,34,40); S.rect_px(BL[3],2,2,30,1); S.rect_px(BL[3],2,37,30,1)
ctext(S,17,5,'CAUTION',BL[3]); S.rect('black',6,13,16,8); S.rect('black',18,9,3,13); S.ell('black',7,21,12,26,edge=False); S.ell('black',18,21,23,26,edge=False); S.rect_px(BL[3],25,14,1,10); ctext(S,17,28,'TRAFFIC',BL[3]); ctext(S,17,34,'AHEAD',BL[3]); done('Sign_Forklift',S,'wall')
S=Spr(28,36,8); S.rect('blue',0,0,28,36); S.ell('white',5,4,22,21,edge=False); S.rect('yellow',8,9,12,6,edge=False); S.rect('yellow',6,14,16,2,edge=False)
ctext(S,14,25,'HARD',CREAM); ctext(S,14,31,'HAT',CREAM); done('Sign_HardHat',S,'wall')
S=Spr(32,32,9); S.rect('paper',0,0,32,32); S.rect('red',0,0,32,10); ctext(S,16,3,'STAFF',WH[0]); ctext(S,16,16,'ONLY',RED[2]); ctext(S,16,23,'AREA',RED[2]); done('Sign_StaffOnly',S,'wall')
# lights, beacons
S=Spr(44,7,10); S.rect('gray',0,0,44,7); S.rect('cool',2,1,40,5,edge=False); S.rect_px(CN[0],3,2,38,1); done('Light_Fluorescent',S,'wall',outline=False)
S=Spr(14,18,11); S.rect('black',0,0,14,18); S.rect('amber',2,2,10,14,edge=False)
for x in (4,7,10): S.rect_px(MAT['amber'][3],x,2,1,14)
for y in (6,10,14): S.rect_px(MAT['amber'][3],2,y,10,1)
done('Light_Cage',S,'wall',outline=False)
S=Spr(12,14,12); S.rect('black',1,10,10,4); S.ell('red',1,0,10,11,edge=False); S.rect_px(hx('#ffc0a0'),3,2,2,4); done('Beacon_Red',S,'wall')
# wall screens
S=Spr(46,30,13); S.rect('black',0,0,46,30); S.rect('navyd',2,2,42,26,edge=False)
S.ell('tealb',20,5,26,11,edge=False); S.rect('tealb',19,12,8,10,edge=False); S.line('tealb',18,13,12,22,w=2); S.line('tealb',28,13,34,22,w=2); S.rect('tealb',19,22,3,5,edge=False); S.rect('tealb',24,22,3,5,edge=False)
for y in range(4,27,4): S.rect_px(MAT['navy'][2],4,y,8,1); S.rect_px(MAT['navy'][2],36,y,8,1)
S.rect_px(CN[0],21,7,4,1); done('Screen_Blueprint',S,'wall')
S=Spr(50,30,14); S.rect('black',0,0,50,30)
for i in range(3):
    x=2+i*16; S.rect('navyd',x,2,14,26,edge=False)
    for j in range(5): S.rect_px(GR[1] if (i+j)%2 else GR[2],x+2,4+j*4,4+((i*3+j*5)%8),2)
done('Screen_DataBank',S,'wall')
S=Spr(14,22,15); S.rect('gray',0,0,14,22); S.rect('black',3,3,8,5,edge=False); S.rect_px(hx('#40a0ff'),4,5,6,1); S.dot(11,12,GR[1]); S.rect_px(BL[3],3,15,8,2); done('Reader_Keycard',S,'wall')
S=Spr(16,24,16); S.rect('black',0,0,16,24); S.rect('navyd',3,3,10,4,edge=False); S.rect_px(GR[1],4,4,6,1)
for j in range(3):
    for i in range(3): S.rect('gray',3+i*4,9+j*4,3,3,edge=False)
done('Panel_Keypad',S,'wall')
# shutter
S=Spr(50,54,17); S.rect('steel',0,0,50,54); S.rect('gray',0,0,4,54); S.rect('gray',46,0,4,54)
for y in range(2,44,4): S.rect_px(MAT['steel'][3],4,y,42,1); S.rect_px(MAT['steel'][0],4,y+1,42,1)
S.rect('yellow',4,44,42,8,edge=False); stripes(S,4,44,42,8); S.rect('black',22,38,6,3,edge=False); done('Rollup_Shutter',S,'wall')
S=Spr(64,10,18); S.rect('gray',0,0,64,10)
for x in range(2,62,3): S.rect_px(MAT['steel'][2],x,1,1,8)
S.rect_px(MAT['steel'][2],0,4,64,1)
for x,c in ((6,BL[3]),(14,RED[2]),(28,BL[3]),(40,MAT['yellow'][3]),(52,BL[3])): S.rect_px(c,x,3,10,2)
done('Cable_Tray',S,'wall')
S=Spr(64,18,19)
S.rect('steel',0,1,64,6); S.rect('red',0,10,64,6)
for x in (8,28,48): S.rect('gray',x,0,3,8,edge=False); S.rect('gray',x,9,3,8,edge=False)
done('Pipes_Wall',S,'wall')
# ---------- standing
def pallet(S,x,y,w):
    S.rect('dwood',x,y+4,w,2); 
    for i in range(0,w-2,max(4,w//5)): S.rect('dwood',i+x,y+1,3,4)
    S.rect('wood',x,y,w,2)
def boxes(S,r,x,y,w,h,mats=('cork','card')):
    S.rect(r.choice(mats),x,y,w,h); S.rect_px(hx('#3a2a1a'),x,y+h//3,w,1) if False else None
    S.rect_px(hx('#d8c090'),x+w//2-1,y,2,h//2)
S=Spr(38,40,20); r=random.Random(2); pallet(S,0,34,38)
for j in range(3):
    for i in range(2): boxes(S,r,1+i*18,3+j*10+0,17,10)
done('Pallet_Boxes',S,'stand')
S=Spr(38,36,21); pallet(S,0,30,38)
for j in range(2):
    for i in range(2):
        x=1+i*18; y=2+j*14; S.rect('blue',x,y,17,13)
        for k in range(3): S.rect_px(MAT['blue'][4],x+3+k*4,y+4,2,4)
        S.rect_px(MAT['blue'][0],x,y,17,1)
done('Pallet_Crates',S,'stand')
S=Spr(36,44,22); r=random.Random(5); pallet(S,0,38,36)
for j in range(3):
    for i in range(2): boxes(S,r,2+i*16,3+j*11,16,11,('card','cork'))
for j in range(0,34,2):
    for i in range(0,32,4): S.dot(2+(i+j*2)%32,3+j,CN[0])
done('Pallet_Wrapped',S,'stand')
S=Spr(38,20,23)
for k in range(3): pallet(S,0,k*7,38) if False else pallet(S,0,k*7-0,38)
done('Pallets_Stack',S,'stand')
# rack
S=Spr(64,68,24); r=random.Random(9); S.rect('black',3,2,58,62,edge=False)
for y in (22,44,64): S.rect('blue',0,y,64,3)
for j,(y0,y1) in enumerate(((3,22),(25,44),(47,64))):
    x=4
    while x<58:
        w=r.choice((9,12,14)); h=r.choice((8,11,14)); h=min(h,y1-y0-1)
        if r.random()<.82 and x+w<60:
            if j==1 and r.random()<.4: S.rect('blue',x,y1-h,w,h)
            else: boxes(S,r,x,y1-h,w,h)
        x+=w+r.choice((1,2,3))
for x in (0,30,60): S.rect('orange',x,0,4,68)
done('Rack_Stocked',S,'stand')
S=Spr(64,68,25); r=random.Random(11); S.rect('black',3,2,58,62,edge=False)
for y in (22,44,64): S.rect('blue',0,y,64,3)
for x in (4,20,44): boxes(S,r,x,50,14,14); 
boxes(S,r,10,32,12,12); boxes(S,r,38,8,16,14); S.rect('blue',6,6,14,16)
for x in (0,30,60): S.rect('orange',x,0,4,68)
done('Rack_Sparse',S,'stand')
# drums
S=Spr(44,30,26)
for x,m in ((1,'blue'),(15,'red'),(29,'yellow')):
    S.rect(m,x,4,14,26); S.ell(m,x,0,x+13,8); S.rect_px(MAT[m][4],x,10,14,1); S.rect_px(MAT[m][4],x,22,14,1); S.rect_px(MAT[m][0],x+2,10,1,12)
S.rect('black',8,12,3,3,edge=False) if False else None
done('Drums_Group',S,'stand')
S=Spr(32,46,27)
for x,m in ((1,'green'),(11,'steel'),(21,'red')):
    S.rect(m,x,10,9,36); S.ell(m,x,6,x+8,14); S.rect('black',x+3,0,3,8,edge=False); S.rect_px(MAT[m][0],x+1,14,1,28)
done('Gas_Cylinders',S,'stand')
S=Spr(14,32,28); S.rect('red',1,8,11,24); S.ell('red',1,4,12,12); S.rect('black',4,0,6,5,edge=False); S.line('black',10,2,13,10,w=1); S.rect('black',3,14,7,6,edge=False); S.rect_px(hx('#ffe080'),4,16,5,2); S.rect_px(MAT['red'][0],2,14,1,16); done('Extinguisher',S,'stand')
# robots
def humanoid(S,x,y):
    S.rect('steel',x+5,y,8,8); S.rect_px(hx('#40e0ff'),x+7,y+3,4,1)
    S.rect('gray',x+7,y+8,4,2,edge=False); S.rect('white',x+2,y+10,14,14); S.rect_px(MAT['navyd'][3],x+8,y+12,2,8)
    S.rect('steel',x-1,y+10,3,16); S.rect('steel',x+16,y+10,3,16); S.rect('gray',x-1,y+24,3,3,edge=False); S.rect('gray',x+16,y+24,3,3,edge=False)
    S.rect('gray',x+4,y+24,4,16); S.rect('gray',x+10,y+24,4,16); S.rect('steel',x+3,y+39,6,3); S.rect('steel',x+9,y+39,6,3)
S=Spr(22,46,29); humanoid(S,2,2); done('Robot_Humanoid',S,'stand')
S=Spr(36,62,30); S.rect('yellow',0,0,4,62); S.rect('yellow',32,0,4,62); S.rect('yellow',0,0,36,5); S.rect('black',0,56,36,6)
S.line('black',18,5,18,10,w=1); humanoid(S,9,10); stripes(S,0,56,36,6,p=3)
done('Robot_Gantry',S,'stand')
S=Spr(48,64,31); S.rect('black',6,52,30,12); S.rect('yellow',8,48,26,14); stripes(S,8,58,26,4)
S.line('yellow',20,50,12,26,w=8); S.line('yellow',12,26,30,10,w=7); S.line('yellow',30,10,38,20,w=5)
S.ell('black',7,22,17,32,edge=False); S.ell('black',25,5,35,15,edge=False); S.rect('black',34,18,8,8,edge=False); S.rect_px(hx('#e02020'),38,22,2,2)
done('Robot_Arm',S,'stand')
S=Spr(34,28,32); S.rect('blue',0,10,34,18); S.rect_px(MAT['blue'][4],0,14,34,1)
S.line('steel',6,12,10,0,w=3); S.line('white',16,12,18,2,w=4); S.line('steel',26,12,30,3,w=3); S.ell('gray',13,0,18,5,edge=False)
done('Robot_PartsBin',S,'stand')
# desks and bench
S=Spr(66,46,33); S.rect('dwood',0,26,66,4); S.rect('gray',2,30,16,16); S.rect('gray',48,30,16,16); S.rect_px(BL[3],4,34,12,1); S.rect_px(BL[3],4,40,12,1); S.rect_px(BL[3],50,34,12,1); S.rect_px(BL[3],50,40,12,1)
for x in (10,32):
    S.rect('black',x,6,20,14); S.rect('navyd',x+2,8,16,10,edge=False); S.rect_px(GR[1],x+4,10,10,1); S.rect_px(GR[2],x+4,13,7,1); S.rect('black',x+8,20,4,4)
S.rect('black',14,24,14,2,edge=False); S.rect('paper',44,24,8,2,edge=False)
done('Desk_Control',S,'stand')
S=Spr(20,34,34); S.rect('black',5,0,12,14); S.rect('gray',3,15,16,4); S.rect('black',10,19,2,10); S.line('black',10,29,2,33,w=2); S.line('black',12,29,20,33,w=2); S.line('black',11,29,11,33,w=2); done('Office_Chair',S,'stand')
S=Spr(56,38,35); S.rect('wood',0,14,56,4); S.rect('dwood',2,18,3,20); S.rect('dwood',51,18,3,20); S.rect('steel',6,26,44,2,edge=False)
S.rect('steel',36,10,8,5); S.rect('black',38,6,2,5); S.rect('red',8,8,10,6); S.rect_px(hx('#e0e0e0'),9,9,8,1); S.line('steel',26,10,34,12,w=1); S.rect('yellow',46,10,6,4,edge=False)
S.rect('blue',6,28,8,6,edge=False); S.rect('black',20,29,10,5,edge=False)
done('Workbench',S,'stand')
S=Spr(26,34,36); S.rect('red',0,6,26,28); S.rect('red',0,0,26,8); S.rect_px(RED[4],0,8,26,1)
for y in (12,19,26): S.rect('gray',3,y,20,5,edge=False); S.rect_px(MAT['steel'][0],9,y+2,8,1)
S.rect('black',1,32,3,2); done('Tool_Chest',S,'stand')
S=Spr(32,22,37); S.rect('blue',2,4,6,4); S.rect('blue',20,1,3,12); S.line('black',3,6,24,18,w=1)
S.rect('red',6,10,22,6,edge=False); S.rect('black',2,16,26,3); S.rect('black',2,18,4,4,edge=False); S.rect('black',26,18,4,4,edge=False); S.rect('steel',20,0,4,4,edge=False)
done('Pallet_Jack',S,'stand')
S=Spr(12,24,38); S.rect('yellow',1,3,10,21); S.ell('yellow',1,0,10,7); S.rect_px(BL[3],1,10,10,2); S.rect_px(BL[3],1,16,10,2); S.rect_px(YEL[0],2,4,1,18); done('Bollard',S,'stand')
# transformers
S=Spr(40,70,39); S.rect('steel',0,42,40,28)
for x in (3,17,31): S.rect('gray',x,44,6,22,edge=False)
S.rect('red',26,50,9,12,edge=False); S.poly('white',[(31,51),(28,57),(30,57),(29,61),(33,55),(31,55)],edge=False)
for x in (6,20,34):
    S.rect('gray',x-1,8,3,36,edge=False)
    for k in range(6): S.ell('white',x-4,6+k*6,x+4,10+k*6)
    S.ell('black',x-3,0,x+3,6)
S.rect('black',0,64,40,6,edge=False); done('Transformer_Tall',S,'stand')
S=Spr(46,44,40); S.rect('steel',0,10,46,34); S.rect('gray',3,13,40,28,edge=True)
for x in (14,28): S.rect_px(MAT['steel'][3],x,13,1,28)
S.rect('red',18,18,10,14,edge=False); S.poly('white',[(24,19),(20,26),(23,26),(21,31),(27,24),(24,24)],edge=False)
for x in (5,20,35): S.rect('white',x,0,6,10); S.rect_px(MAT['white'][3],x,3,6,1); S.rect_px(MAT['white'][3],x,6,6,1)
done('Transformer_Box',S,'stand')
S=Spr(32,52,41); S.rect('black',0,0,32,52)
for j in range(6):
    S.rect('gray',3,3+j*8,26,6,edge=False)
    for i in range(4): S.dot(6+i*3,5+j*8,GR[1] if (i+j)%3 else RED[1])
    S.rect_px(BL[3],19,5+j*8,8,1)
done('Battery_Rack',S,'stand')
S=Spr(34,54,42); S.rect('steel',0,0,34,54)
for x in (3,13,23): S.rect('gray',x,3,8,48,edge=True); S.rect('black',x+5,24,2,6,edge=False)
S.rect('yellow',13,8,8,8,edge=False); S.poly('black',[(17,9),(15,13),(16,13),(15,15),(19,11),(17,11)],edge=False); S.rect('red',3,40,8,8,edge=False)
done('Switchgear',S,'stand')
S=Spr(36,34,43); S.ell('wood',0,0,35,33); S.ell('dwood',3,3,32,30,edge=False); circ(S,17,16,10,MAT['black'][2]); circ(S,17,16,7,RED[2]); circ(S,17,16,4,MAT['black'][2]); S.ell('black',14,13,20,19,edge=False); done('Cable_Spool',S,'stand')
S=Spr(50,36,44); S.rect('green',0,8,50,26); S.poly('green',[(0,8),(50,8),(46,0),(4,0)]); 
for x in range(5,48,7): S.rect_px(MAT['green'][3],x,10,1,22)
S.rect_px(MAT['green'][0],0,8,50,1); S.rect('black',6,32,6,4); S.rect('black',38,32,6,4); done('Dumpster',S,'stand')
S=Spr(68,28,45); S.rect('yellow',0,0,68,3); S.rect('yellow',0,12,68,2)
for x in (0,32,65): S.rect('yellow',x,0,3,28)
S.rect('yellow',0,26,68,2)
for x in range(6,64,6):
    if abs(x-33)>3: S.rect_px(YEL[3],x,3,1,9)
done('Catwalk_Rail',S,'stand')
S=Spr(14,58,46); S.rect('steel',0,0,3,58); S.rect('steel',11,0,3,58)
for y in range(3,56,5): S.rect('gray',3,y,8,2,edge=False)
done('Ladder',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
