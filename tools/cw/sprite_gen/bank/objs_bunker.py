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
    n=len(OUTS); fn=('CBN' if n<36 else 'CBM')+CODES[n%36]
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
# ================= WALL SIGNS =================
S=Spr(46,66,1); S.rect('yellow',0,0,46,66); S.rect_px(YEL[3],1,1,44,1); S.rect_px(YEL[3],1,64,44,1)
S.part('black',lambda d:[d.pieslice((7,3,39,35),a,a+60,fill=255) for a in (60,180,300)],edge=False)
S.ell('yellow',15,11,31,27,edge=False); S.ell('black',18,14,28,24,edge=False); S.ell('yellow',20,16,26,22,edge=False); S.ell('black',21,17,25,21,edge=False)
ctext(S,23,42,'RADIATION',BL[3]); ctext(S,23,50,'CONTROLLED',BL[3]); ctext(S,23,58,'AREA',BL[3]); done('Sign_Radiation',S,'wall')
S=Spr(32,46,2); S.rect('paper',0,0,32,46); S.rect('red',0,32,32,14); S.rect('red',11,4,10,26); S.rect('red',5,10,22,10); ctext(S,16,37,'MEDBAY',MAT['paper'][0]); done('Sign_Medbay',S,'wall')
S=Spr(42,50,3); S.rect('yellow',0,0,42,50); S.rect('black',3,3,36,10); ctext(S,21,5,'NOTICE',YEL[1]); S.line('black',10,18,32,38,w=5); S.line('black',32,18,10,38,w=5); S.rect('yellow',18,26,6,6,edge=False)
ctext(S,21,42,'CREW ONLY',BL[3]); done('Sign_Maintenance',S,'wall')
S=Spr(34,46,4); S.rect('paper',0,0,34,46); S.rect_px(MAT['paper'][3],0,45,34,1); S.rect('black',8,6,16,9); S.rect('black',4,8,5,5); S.rect('steel',24,9,5,3); S.ell('steel',12,8,18,14,edge=False); S.rect_px(BL[4],14,10,2,2); S.line('black',28,4,32,8,w=2)
ctext(S,17,22,'CCTV',BL[3]); S.rect_px(MAT['red'][1],4,29,26,1); ctext(S,17,33,'IN USE',MAT['red'][2]); done('Sign_Surveillance',S,'wall')
S=Spr(26,42,5); S.rect('green',0,0,26,42); S.rect_px(MAT['green'][4],2,2,22,38); S.rect_px(MAT['green'][2],3,3,20,36)
S.ell('paper',13,6,18,11,edge=False); S.line('paper',15,12,12,20,w=3); S.line('paper',15,13,20,17,w=2); S.line('paper',12,20,18,26,w=2)
for i in range(4): S.rect_px(MAT['paper'][0],4+i*4,34-i*4+0,5,1); S.rect_px(MAT['paper'][0],4+i*4,34-i*4,1,4)
done('Sign_ExitStairs',S,'wall')
S=Spr(84,52,6); S.rect('conc',0,0,84,52); S.rect_px(MAT['conc'][3],0,51,84,1)
for i,t in enumerate(('GENERATORS','LIVING QUARTERS','MEDBAY','FOOD CACHE','MAINTENANCE')):
    y=4+i*10; S.text(5,y,t,BL[3]); arrow(S,74,y,c=BL[3])
    if i<4: S.rect_px(MAT['conc'][2],3,y+8,78,1)
done('Directory_Bunker',S,'wall')
# posters
S=Spr(42,52,7); S.rect('paper',0,0,42,52,noise=.02); S.rect_px(MAT['paper'][3],0,51,42,1)
for i,t in enumerate(('FOOD','WATER','SUPPLIES','SECURITY','TOGETHER')): ctext(S,21,4+i*8,t,BL[3])
S.poly('red',[(21,45),(17,51),(25,51)],edge=False) if False else None; S.poly('black',[(34,44),(31,50),(37,50)],edge=False); S.dot(34,47,YEL[1]); done('Poster_Supplies',S,'wall')
S=Spr(36,52,8); S.rect('navyd',0,0,36,52); S.poly('paper',[(2,26),(14,6),(20,14),(26,8),(34,26)],edge=False); S.poly('navy',[(14,6),(9,15),(14,13),(17,17),(20,14)],edge=False)
for x in range(2,34,4): S.poly('black',[(x,32),(x+2,20+(x%3)*2),(x+4,32)],edge=False)
S.rect('black',0,30,36,4,edge=False)
for i,t in enumerate(('SURVIVE','PREPARE','ENDURE')): ctext(S,18,36+i*5,t,CREAM,sp=1)
done('Poster_Survive',S,'wall')
m=trace((990,38,1108,150),24,mode='color',ncol=8,enh=(1.2,1.2,1.2))
S=Spr(42,50,9); S.rect('cool',0,0,42,50,noise=.02); S.im.paste(m,(21-m.width//2,4),m); S.px=S.im.load(); ctext(S,21,36,'GLOBAL',MAT['navyd'][2]); ctext(S,21,43,'SITUATION',MAT['navyd'][2]); done('Poster_Global',S,'wall')
S=Spr(36,50,10); S.rect('navyd',0,0,36,50); S.rect_px(MAT['navy'][1],1,1,34,1)
for x in range(4,32,5): S.rect_px(MAT['navy'][2],x,4,1,34)
for y in range(4,38,5): S.rect_px(MAT['navy'][2],4,y,27,1)
S.rect_px(MAT['navy'][0],8,8,10,8); S.rect_px(MAT['navyd'][3],9,9,8,6); S.rect_px(MAT['navy'][0],20,8,10,20); S.rect_px(MAT['navy'][0],8,22,8,10)
ctext(S,18,42,'BUNKER',MAT['navy'][0]); done('Poster_Blueprint',S,'wall')
# wall boxes / small monitors
S=Spr(34,20,11); S.rect('black',0,0,34,20); S.rect_px(hx('#2a0808'),2,2,30,16); ctext(S,17,4,'ACCESS',hx('#ff4030')); ctext(S,17,11,'DENIED',hx('#ff4030')); done('Monitor_AccessDenied',S,'wall')
S=Spr(28,22,12); S.rect('black',0,0,28,22); S.rect_px(hx('#2a0808'),2,2,24,18); S.poly('red',[(14,4),(6,18),(22,18)],edge=False); S.rect_px(hx('#ffd0c0'),13,9,2,5); S.rect_px(hx('#ffd0c0'),13,15,2,1); done('Monitor_RedAlert',S,'wall')
S=Spr(22,28,13); S.rect('conc',0,0,22,28); S.rect('steel',2,2,18,24,edge=True); S.poly('yellow',[(11,7),(4,21),(18,21)],edge=False); S.poly('black',[(11,11),(7,19),(15,19)],edge=False); S.rect_px(YEL[1],10,13,2,4); S.dot(10,18,YEL[1]); S.dot(11,18,YEL[1]); done('Box_Hazard',S,'wall')
S=Spr(22,30,14); S.rect('red',0,0,22,30); S.rect_px(MAT['red'][4],2,2,18,26); S.text(3,5,'FIRE',MAT['paper'][0]); S.rect('paper',4,13,14,13,edge=False); S.rect('black',9,15,4,10); S.rect('black',5,15,12,3); done('FireAlarm',S,'wall')
S=Spr(32,32,15); S.rect('green',0,0,32,32); S.rect_px(MAT['green'][4],2,2,28,28); S.rect_px(MAT['green'][2],3,3,26,26); S.rect('paper',13,7,6,18,edge=False); S.rect('paper',7,13,18,6,edge=False); S.rect('steel',12,30,8,2); done('FirstAid_Green',S,'wall')
S=Spr(22,32,16); S.rect('conc',0,0,22,32); S.rect('conc',2,2,18,28,edge=True); S.rect('black',5,5,12,7,edge=False); S.rect_px(GR[1],7,7,8,1); S.rect_px(GR[2],7,9,5,1); S.rect('steel',9,16,4,8); S.dot(11,26,MAT['red'][1]); done('ElectricalPanel',S,'wall')
S=Spr(20,30,17); S.rect('steel',0,0,20,30); S.rect('black',3,3,14,8,edge=False)
for j in range(3):
    for i in range(3): S.dot(5+i*4,15+j*4,ST[0])
S.rect_px(MAT['red'][1],3,26,3,2); done('Intercom',S,'wall')
# ================= STANDING =================
def shelf(w,h,n=3):
    S=Spr(w,h,20); S.rect_px(hx('#0f1116'),3,2,w-6,h-6)
    for x in (0,w-3): S.rect('black',x,0,3,h-2)
    ys=[]
    for i in range(n): y=int((h-6)*(i+1)/n); S.rect('black',0,y,w,3); S.rect_px(BL[0],0,y,w,1); ys.append(y)
    S.rect('black',0,0,w,2); wheels(S,(4,w-5),h-4,2); return S,ys
def crate(S,x,y,w,h,m='olive'):
    S.rect(m,x,y,w,h); S.rect_px(MAT[m][3],x,y+3,w,1); S.rect_px(MAT[m][4],x+w//2-3,y+h-4,6,2); S.rect('black',x+1,y+h//2,w-2,1) if False else None
def jerry(S,x,y,m='olive'):
    S.rect(m,x,y+2,10,12); S.rect('black',x+1,y,4,3); S.rect_px(MAT[m][3],x+2,y+6,6,1); S.rect_px(MAT[m][4],x+7,y+3,2,3)
def bundle(S,x,y,w,h,m):
    S.ell(m,x,y,x+w,y+h)
S,ys=shelf(46,58)  # gear shelf: bags, helmets, vests
for x in (6,16,26): S.ell('olive',x,ys[0]-9,x+9,ys[0]-1)
for x in (6,18,30): S.ell('rust',x,ys[1]-9,x+11,ys[1]-1); S.rect_px(MAT['rust'][4],x+1,ys[1]-3,9,1)
for x in (6,25): S.rect('olive',x,ys[2]-11,16,10); S.rect_px(MAT['olive'][4],x+2,ys[2]-6,12,1); S.rect_px(MAT['olive'][0],x+2,ys[2]-10,12,1)
done('Shelf_Gear',S,'stand')
S,ys=shelf(46,58)  # ammo/fuel shelf
crate(S,6,ys[0]-9,16,9); crate(S,24,ys[0]-8,14,8,'card'); jerry(S,6,ys[1]-14); jerry(S,18,ys[1]-14); crate(S,30,ys[1]-10,12,10)
crate(S,6,ys[2]-12,14,12); jerry(S,22,ys[2]-14); jerry(S,32,ys[2]-14); done('Shelf_Supplies',S,'stand')
S,ys=shelf(46,58)  # toolbox shelf
S.rect('red',6,ys[0]-9,16,9); S.rect('card',26,ys[0]-8,12,8); S.rect('red',6,ys[1]-10,18,10); S.rect('red',8,ys[2]-10,20,10); S.rect('steel',30,ys[2]-7,10,7)
for (x,y,w) in ((6,ys[0]-9,16),(6,ys[1]-10,18),(8,ys[2]-10,20)): S.rect_px(MAT['red'][4],x,y+4,w,1); S.rect('black',x+w//2-3,y-2,6,2)
S.rect('yellow',30,ys[1]-8,9,8); S.rect_px(YEL[3],30,ys[1]-4,9,1); done('Shelf_Tools',S,'stand')
S=Spr(48,58,21); S.rect('conc',2,2,44,46); S.rect('black',0,0,48,3); S.rect('black',0,46,48,4); S.rect('black',0,0,3,50); S.rect('black',45,0,3,50)
for x in range(6,44,4):
    for y in range(6,44,4): S.dot(x,y,MAT['conc'][4])
for x,c in ((8,'red'),(14,'orange'),(20,'steel'),(26,'red'),(32,'yellow')): S.rect(c,x,8,3,4); S.rect('wood',x,12,3,12) if c!='steel' else S.rect('steel',x,12,3,14)
S.rect('steel',8,30,10,3); S.rect('red',22,30,8,6); S.rect('steel',34,30,6,10); wheels(S,(5,43),50,3); done('ToolWall',S,'stand')
S=Spr(52,62,22); S.rect_px(hx('#0f1116'),3,4,46,50)
S.rect('black',0,0,4,58); S.rect('black',48,0,4,58); S.rect('black',0,0,52,4); S.rect('steel',3,6,46,2)
def garment(x,w,m,h,hood=False):
    S.rect('steel',x+w//2-1,3,2,4)
    S.poly(m,[(x+2,8),(x+w-2,8),(x+w,12),(x+w,8+h),(x,8+h),(x,12)])
    S.rect(m,x-1,12,3,h-6); S.rect(m,x+w-2,12,3,h-6)
    S.rect_px(MAT[m][4],x+w//2,10,1,h-2); S.rect_px(MAT[m][3],x+2,8+h-4,w-4,1)
    if hood: S.ell(m,x+2,7,x+w-2,14)
    S.rect('black',x+2,8,w-4,2,edge=False) if False else None
garment(5,13,'black',36,True); garment(17,13,'olive',38); garment(29,13,'navy',34,True); garment(40,9,'card',30)
S.rect('black',6,52,3,1)
for x in (8,15): S.rect('wood',x,44,5,8); S.rect('black',x,50,7,3); S.rect_px(MAT['wood'][0],x,44,1,6)
S.ell('olive',28,46,46,58); S.rect_px(MAT['olive'][4],30,52,14,1); S.rect('black',33,44,7,2)
S.rect('black',0,58,52,4); S.rect_px(BL[0],0,58,52,1); wheels(S,(6,45),58,2)
done('CoatRack_Gear',S,'stand')
S=Spr(64,54,23) # bunk bed
S.rect('black',0,2,4,50); S.rect('black',60,2,4,50); S.rect('black',0,2,64,3); S.rect('black',0,26,64,3); S.rect('black',2,48,60,3)
S.rect('olive',5,12,54,12); S.rect('olive',5,36,54,12); S.rect('olive',5,8,14,6); S.rect('olive',5,32,14,6)
for y in (12,36): S.rect_px(MAT['olive'][3],5,y+8,54,1); S.rect_px(MAT['olive'][0],6,y,52,1)
S.rect_px(BL[0],3,4,1,44); done('BunkBed',S,'stand')
S=Spr(44,50,24) # radio cart
S.rect('black',0,22,44,3); S.rect('black',2,25,3,20); S.rect('black',39,25,3,20); S.rect('black',0,40,44,3); wheels(S,(6,38),44,3)
S.rect('steel',3,6,20,16); S.rect_px(hx('#0a1428'),5,8,10,5); S.rect_px(GR[1],6,10,7,1); S.rect('steel',26,10,13,12); S.rect('black',28,12,9,3); S.rect('black',30,2,3,8)
S.ell('blue',4,28,10,40); S.ell('blue',13,30,19,40,edge=False) if False else None; S.rect('steel',26,28,12,12); S.rect_px(BL[4],28,30,8,2); done('Cart_Radio',S,'stand')
# wall: corkboard map
S=Spr(74,50,25); S.rect('wood',0,0,74,50); S.rect('cork',3,3,68,44,noise=.10); m=trace((1590,375,1750,505),36,mode='color',ncol=12,enh=(1.15,1.2,1.2)) if False else None
S.rect('cream',14,7,46,34,noise=.03)
for i in range(6): S.line('cream',20+i*7,8,18+i*8,40,w=1) if False else None
for x,y in ((20,14),(32,22),(44,16),(52,30),(28,32)): S.dot(x,y,MAT['red'][1]); S.dot(x+1,y,MAT['red'][1])
for a,b in (((20,14),(32,22)),((32,22),(44,16)),((44,16),(52,30)),((32,22),(28,32))): S.line('red',a[0],a[1],b[0],b[1],w=1)
for x,y in ((16,10),(30,8),(48,10),(38,26),(22,26)):
    S.rect_px(MAT['blue'][2],x-1,y,10,1) if False else None
for x,y,w,h,m in ((5,6,8,10,'paper'),(5,20,8,9,'yellow'),(62,8,8,10,'paper'),(62,22,8,10,'yellow'),(6,34,10,9,'paper'),(58,36,10,8,'cream')):
    S.rect(m,x,y,w,h,noise=.01); S.rect_px(MAT['paper'][3],x+1,y+3,w-3,1); S.rect_px(MAT['paper'][3],x+1,y+6,w-4,1); S.rect_px(MAT['red'][1],x+w//2,y,2,2)
for x in range(16,58,6): S.rect_px(MAT['blue'][2],x,9,3,1); S.rect_px(MAT['blue'][2],x+1,36,3,1)
done('MapBoard',S,'wall')
def crates(name,layout,w,h):
    S=Spr(w,h,26)
    for x,y,cw,ch,m in layout: crate(S,x,y,cw,ch,m)
    done(name,S,'stand')
crates('Crates_Olive',[(0,20,22,16,'olive'),(22,20,20,16,'olive'),(4,4,22,16,'olive')],44,36)
crates('Crates_Mixed',[(0,18,26,18,'olive'),(26,22,20,14,'steel'),(6,4,18,14,'card')],46,36)
crates('Boxes_Cardboard',[(0,16,24,20,'card'),(24,22,18,14,'card'),(6,2,18,14,'cardtop')],44,36)
S=Spr(30,42,27); S.rect('red',0,6,30,36); S.rect('black',0,0,30,7); S.rect_px(BL[0],0,0,30,1)
for i in range(4): y=9+i*8; S.rect('red',2,y,26,7); S.rect_px(MAT['red'][4],2,y+6,26,1); S.rect('steel',10,y+2,10,2)
wheels(S,(5,25),40,2); done('ToolChest_Red',S,'stand')
S=Spr(44,38,28) # pallet jack
S.rect('yellow',6,26,36,5); S.rect('yellow',6,32,36,3); S.rect_px(BL[3],8,30,32,1); S.line('black',8,26,4,4,w=3); S.rect('black',0,0,10,4); S.rect('black',3,2,3,16)
wheels(S,(10,36),33,2); done('PalletJack',S,'stand')
S=Spr(44,38,29) # generator
S.rect('black',0,4,44,32); S.rect('red',3,7,38,22); S.rect_px(MAT['red'][4],3,20,38,1); S.rect('black',6,10,10,8,edge=False); S.circ=None; circ(S,30,15,5,ST[1]); S.rect_px(ST[0],30,11,1,4); S.rect('steel',8,22,4,4); S.rect('steel',15,22,4,4)
S.rect('black',8,0,28,5); wheels(S,(8,36),33,3); done('Generator',S,'stand')
def worklight(name):
    S=Spr(28,56,30); S.rect('black',4,2,20,12); S.rect('amber',6,4,7,8,noise=0); S.rect('amber',15,4,7,8,noise=0); S.rect_px(MAT['amber'][0],7,5,4,2); S.rect_px(MAT['amber'][0],16,5,4,2); S.rect('yellow',13,14,2,24)
    S.line('yellow',14,36,3,54,w=2); S.line('yellow',14,36,25,54,w=2); S.line('yellow',14,36,14,54,w=1); done(name,S,'stand')
worklight('WorkLight_Tripod')
def barrel(name,m,band=None):
    S=Spr(20,28,31); S.part(m,lambda d:d.rounded_rectangle((0,1,19,27),3,fill=255),form='cyl'); S.rect('black',1,0,18,3,edge=False); S.rect_px(MAT[m][3],1,9,18,1); S.rect_px(MAT[m][3],1,19,18,1)
    if band: S.rect_px(hx(band),1,11,18,6)
    S.rect_px(MAT[m][4],5,22,6,3) if False else None; done(name,S,'stand')
barrel('Barrel_Blue','blue'); barrel('Barrel_Orange','orange','#e8e4d8'); barrel('Barrel_Green','olive')
S=Spr(30,34,32); S.rect('blue',1,10,16,22); S.rect('yellow',13,14,15,18); S.rect('black',0,30,30,3); S.rect('steel',7,2,3,10); S.line('steel',20,2,18,14,w=2); S.rect_px(YEL[3],13,22,15,1); wheels(S,(5,25),31,2) if False else None; done('MopBucket',S,'stand')
S=Spr(28,22,33); S.rect('red',0,3,28,19); S.rect('black',9,0,10,4); S.rect_px(MAT['red'][4],0,11,28,1); S.rect('steel',3,9,4,5); S.rect('steel',21,9,4,5); S.rect('paper',10,14,8,6,edge=False); S.rect('red',13,15,2,4,edge=False); S.rect('red',11,17,6,2,edge=False); done('Case_Red',S,'stand')
S=Spr(42,26,34); S.rect('black',0,3,42,23); S.rect_px(BL[0],1,4,40,1); S.rect('steel',3,10,5,5); S.rect('steel',34,10,5,5); S.poly('yellow',[(21,8),(14,21),(28,21)],edge=False); S.poly('black',[(21,12),(17,19),(25,19)],edge=False); S.rect_px(YEL[1],20,14,2,3); S.rect('black',15,0,12,4); done('Case_Hazard',S,'stand')
S=Spr(32,22,35); S.rect('black',3,1,26,14); S.rect_px(hx('#0a1c40'),5,3,22,10); S.rect_px(hx('#5ab0ff'),7,5,10,1); S.rect_px(hx('#2e6ad0'),7,7,14,1); S.rect_px(hx('#5ab0ff'),7,9,6,1); S.rect_px(hx('#e04030'),23,4,2,2)
S.poly('steel',[(0,15),(31,15),(29,21),(2,21)]); S.rect_px(BL[3],4,16,24,1)
for j in range(3):
    for i in range(9): S.dot(5+i*2+(j%2),17+j,BL[2])
S.rect_px(ST[3],13,20,6,1); done('Laptop',S,'stand')
# lights / vents / pipes (wall)
S=Spr(30,12,36); S.part('steel',lambda d:d.rounded_rectangle((0,3,29,11),4,fill=255)); S.rect('amber',3,4,24,6,noise=0,edge=False); S.rect_px(MAT['amber'][0],7,6,16,2); done('Light_Dome',S,'wall')
S=Spr(44,10,37); S.rect('black',0,0,44,10); S.rect('cool',2,2,40,6,noise=0,edge=False); S.rect_px(MAT['cool'][0],5,4,34,2); done('Light_Tube',S,'wall')
def caged(name,m):
    S=Spr(14,24,38); S.rect('black',2,0,10,4); S.part(m,lambda d:d.rounded_rectangle((1,4,12,22),5,fill=255),form='cyl',edge=False); S.rect_px(MAT[m][0],4,7,2,7)
    for y in (8,13,18): S.rect_px(BL[2],1,y,12,1)
    S.rect_px(BL[2],6,4,1,18); S.rect('black',3,22,8,2); done(name,S,'wall')
caged('Lamp_CagedRed','red'); caged('Lamp_CagedAmber','amber')
S=Spr(24,24,39); S.rect('steel',0,0,24,24); S.rect_px(BL[3],3,3,18,18); circ(S,12,12,8,ST[2]); S.rect_px(hx('#0a0c10'),4,4,16,16)
S.part('steel',lambda d:[d.pieslice((5,5,19,19),a,a+40,fill=255) for a in (0,90,180,270)],edge=False); S.rect('black',10,10,4,4); done('Vent_Fan',S,'wall')
S=Spr(30,20,40); S.rect('steel',0,0,30,20)
for y in range(3,18,3): S.rect_px(BL[3],3,y,24,2); S.rect_px(ST[0],3,y+2,24,1)
done('Vent_Louvre',S,'wall')
def pipe(name,pts,m,w=6):
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]; W=max(xs)+w+2; H=max(ys)+w+2; S=Spr(W,H,41)
    for a,b in zip(pts,pts[1:]): S.part(m,lambda d:d.line((a[0]+w//2,a[1]+w//2,b[0]+w//2,b[1]+w//2),fill=255,width=w),form=None)
    for p in pts[1:-1]: S.rect(m,p[0]-1,p[1]-1,w+2,w+2)
    for p in (pts[0],pts[-1]): S.rect_px(MAT[m][2],p[0]-(1 if p[0]==pts[0][0] else 0),p[1],1,w)
    done(name,S,'wall')
pipe('Pipe_Elbow',[(0,4),(16,4),(16,28)],'steel'); pipe('Pipe_CopperS',[(0,4),(14,4),(14,20),(30,20)],'rust'); pipe('Pipe_Straight',[(0,4),(36,4)],'steel')
S=Spr(24,30,42); S.rect('steel',9,0,6,30); S.rect('steel',0,12,24,6); S.rect('red',3,6,18,3); S.rect('red',10,3,4,12); S.rect_px(MAT['red'][4],3,8,18,1); done('Valve_Red',S,'wall')
S=Spr(26,34,43); S.rect('steel',10,20,6,14); S.ell('steel',1,1,24,24); S.ell('paper',4,4,21,21,edge=False); circ(S,12,12,7,BL[3])
for a in range(-40,220,45): S.dot(12+round(7*math.cos(math.radians(a))),12+round(7*math.sin(math.radians(a))),BL[3])
S.line('red',12,12,17,17,w=1); S.dot(12,12,BL[3]); done('Gauge',S,'wall')
S=Spr(22,30,44); S.rect('conc',0,0,22,30); S.rect('steel',2,2,18,26,edge=True); S.poly('yellow',[(11,8),(5,20),(17,20)],edge=False); S.poly('black',[(11,12),(8,19),(14,19)],edge=False); S.rect_px(YEL[1],10,14,2,3); S.rect('black',9,22,4,4); done('JunctionBox',S,'wall')

# ---- rifle rack, desk screens, servers
S=Spr(46,62,50); S.rect_px(hx('#181b22'),3,3,40,50); S.rect('black',0,0,46,4); S.rect('black',0,0,3,56); S.rect('black',43,0,3,56)
for x in range(6,42,4):
    for y in (8,32): S.dot(x,y,MAT['conc'][4])
S.rect('steel',3,24,40,3); S.rect('steel',3,44,40,3)
for x in (7,17,27,37):
    S.rect('black',x,5,2,26); S.rect('black',x-1,14,4,3,edge=False); S.rect('wood',x-1,26,4,12); S.rect_px(MAT['wood'][0],x-1,26,1,12)
    S.rect('black',x-1,36,5,10); S.rect('black',x+1,44,3,8); S.poly('wood',[(x-1,44),(x+3,44),(x+4,56),(x,56)],edge=True)
    S.rect_px(BL[0],x,6,1,20)
S.rect('black',0,54,46,4); S.rect_px(BL[0],0,54,46,1); wheels(S,(6,39),56,2); done('RifleRack',S,'stand')
def dscr(name,fn,w=40,h=34):
    S=Spr(w,h+10,51); S.rect('black',0,0,w,h-6); S.rect_px(hx('#0a1428'),2,2,w-4,h-10); S.rect_px(BL[3],1,1,w-2,1); fn(S,w,h)
    S.rect('black',w//2-4,h-6,8,4); S.rect('black',w//2-10,h-2,20,4); done(name,S,'stand')
def f_cctv(S,w,h):
    for q,(x,y) in enumerate(((4,4),(w//2+1,4),(4,h//2-3),(w//2+1,h//2-3))):
        S.rect_px(hx('#182c50'),x,y,w//2-5,h//2-9)
        for i in range(14): S.dot(x+S.rnd.randrange(w//2-5),y+S.rnd.randrange(h//2-9),hx('#2c4478'))
        S.text(x+1,y+1,'C%d'%(q+1),hx('#9ad0ff'))
def f_dash(S,w,h):
    for i,hh in enumerate((3,6,4,8,5)): S.rect_px(hx('#4a90e8'),5+i*3,h-11-hh,2,hh)
    S.rect_px(hx('#2860b8'),5,h-10,14,1)
    for r in (9,5): circ(S,w-14,h//2-3,r,hx('#2860b8'))
    for i in range(8): S.dot(w-14+i,h//2-3-i//2,hx('#9ad0ff'))
    S.dot(w-17,h//2-6,hx('#ff5040')); S.dot(w-10,h//2,hx('#ffd040'))
def f_term(S,w,h):
    for i,l in enumerate((18,24,14,22,16,10)): S.rect_px(hx('#5af0ff') if i%3==0 else hx('#2e8ac8'),5,5+i*3,l,1)
    S.text(5,h-14,'> _',hx('#5af0ff'))
def f_alert(S,w,h):
    S.rect_px(hx('#2a0808'),2,2,w-4,h-10); S.poly('red',[(w//2,5),(w//2-9,h-13),(w//2+9,h-13)],edge=False); S.rect_px(hx('#ffd0c0'),w//2-1,11,2,8); S.rect_px(hx('#ffd0c0'),w//2-1,h-17,2,2)
def f_denied(S,w,h):
    S.rect_px(hx('#2a0808'),2,2,w-4,h-10); ctext(S,w//2,8,'ACCESS',hx('#ff4030')); ctext(S,w//2,15,'DENIED',hx('#ff4030'))
dscr('DeskScreen_Cctv',f_cctv); dscr('DeskScreen_Dashboard',f_dash); dscr('DeskScreen_Terminal',f_term); dscr('DeskScreen_RedAlert',f_alert); dscr('DeskScreen_AccessDenied',f_denied)
S=Spr(34,32,52)
for x in (0,18):
    S.rect('black',x,2,16,30)
    for i in range(4):
        y=5+i*7; S.rect('black',x+2,y,12,5,edge=True); S.dot(x+4,y+2,GR[1] if i%2 else hx('#e8a020')); S.rect_px(BL[0],x+8,y+2,4,1)
done('ServerUnits_Small',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
