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
    n=len(OUTS); fn=('CAP' if n<36 else 'CAQ')+CODES[n%36]
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
for k,v in {'brick':'#8e7462 #6c5648 #52413a #382c28 #221a18','tile':'#c0d0c0 #98ac9c #748a7c #566a60 #38463f','white':'#ffffff #eef0f2 #ced3d9 #9ba3ad #666e7a','dwood':'#7a5238 #5a3a26 #442a1a #2e1c10 #1a0e08','gdoor':'#4a7a58 #34603f #264a30 #1a3422 #0e2014','gray':'#8a8e96 #686c74 #50545c #383c44 #22252c','ndoor':'#3a4258 #2a3044 #1e2434 #141824 #0a0c14','bdoor':'#5a3a24 #46291a #351d12 #24130a #140a05'}.items(): MAT[k]=[hx(c) for c in v.split()]
BR=MAT['brass']; WD=MAT['wood']; CR=MAT['cream']
def door(name,mat,label,slot=False,lc=None):
    S=Spr(24,46,hash(name)%50); S.rect(mat,0,0,24,46); S.rect_px(MAT[mat][4],0,0,24,1); S.rect_px(MAT[mat][4],0,0,1,46); S.rect_px(MAT[mat][4],23,0,1,46)
    for x in (5,11,17): S.rect_px(MAT[mat][3],x,2,1,42)
    S.rect_px(MAT[mat][2],3,3,18,1)
    if label: ctext(S,12,8,label,lc or BR[1])
    S.rect('brass',18,26,3,4); S.dot(19,27,BR[0])
    if slot: S.rect_px(BR[2],8,31,8,2); S.rect_px(BR[0],8,30,8,1)
    S.dot(12,20,BR[1]); 
    done(name,S,'wall')
door('Door_3A','black','3A'); door('Door_3B','ndoor','3B'); door('Door_4C','bdoor','4C'); door('Door_2B','gray','2B',lc=MAT['steel'][0]); door('Door_1A','gdoor','',slot=True)
S=Spr(84,52,2); S.rect('conc',0,0,84,52); S.rect_px(MAT['conc'][3],0,51,84,1); S.rect_px(MAT['conc'][2],0,0,84,1)
for i,t in enumerate(('APARTMENTS','LAUNDRY','ROOFTOP','MAINTENANCE','FIRE ESCAPE')):
    S.rect('navyd',0,0,0,0) if False else None
S=Spr(84,52,2); S.rect('black',0,0,84,52); S.rect_px(MAT['steel'][2],0,0,84,1)
for i,t in enumerate(('APARTMENTS','LAUNDRY','ROOFTOP','MAINTENANCE','FIRE ESCAPE')):
    y=4+i*10; arrow(S,4,y,c=CREAM,left=True); S.text(14,y,t,CREAM)
done('Directory_Apartments',S,'wall')
S=Spr(46,16,3); S.rect('paper',0,0,46,16); S.rect_px(MAT['red'][2],0,0,46,1); S.rect_px(MAT['red'][2],0,15,46,1); arrow(S,3,5,c=MAT['red'][2],left=True); S.rect('red',10,3,34,10); ctext(S,27,5,'EXIT',MAT['paper'][0]); done('Sign_Exit_Arrow',S,'wall')
S=Spr(46,16,4); S.rect('green',0,0,46,16); S.rect_px(MAT['green'][4],1,1,44,14); S.rect_px(MAT['green'][2],2,2,42,12); arrow(S,4,5,c=CREAM,left=True); ctext(S,27,5,'STAIRS',CREAM); done('Sign_Stairs_Arrow',S,'wall')
S=Spr(28,42,5); S.rect('red',0,0,28,42); S.rect_px(MAT['red'][4],2,2,24,38); S.rect_px(MAT['red'][2],3,3,22,36)
ctext(S,14,6,'FIRE',CREAM); ctext(S,14,13,'ESCAPE',CREAM)
S.ell('paper',12,20,17,25,edge=False); S.line('paper',14,26,12,33,w=3); S.line('paper',14,27,19,30,w=2); S.line('paper',12,33,17,38,w=2); done('Sign_FireEscape',S,'wall')
S=Spr(34,42,6); S.rect('green',0,0,34,42); S.rect_px(MAT['green'][4],2,2,30,38); S.rect_px(MAT['green'][2],3,3,28,36)
S.rect_px(CREAM,16,7,2,10); S.poly('paper',[(17,4),(12,10),(22,10)],edge=False); ctext(S,17,22,'ROOFTOP',CREAM); ctext(S,17,29,'ACCESS',CREAM); done('Sign_Rooftop',S,'wall')
S=Spr(38,44,7); S.rect('conc',0,0,38,44); S.rect_px(MAT['conc'][3],0,43,38,1)
S.rect('navyd',15,4,8,3,edge=False); S.rect('navyd',13,8,12,13,edge=False); S.rect_px(MAT['navy'][2],16,11,1,8); S.rect_px(MAT['navy'][2],19,11,1,8); S.rect_px(MAT['navy'][2],22,11,1,8)
ctext(S,19,25,'KEEP',BL[3]); ctext(S,19,31,'HALLWAYS',BL[3]); ctext(S,19,37,'CLEAN',BL[3]); done('Sign_KeepClean',S,'wall')
S=Spr(30,26,8); S.rect('cream',0,4,20,10); S.rect('steel',2,5,16,2,edge=False); S.rect('black',18,6,8,7,edge=False); S.ell('black',20,7,25,12,edge=False); S.rect('red',22,9,1,1,edge=False)
S.rect('steel',20,13,4,10); S.rect('black',15,21,10,4); S.rect('steel',3,11,3,3,edge=False)
done('CCTV_Camera',S,'wall',outline=True)
# mailboxes
S=Spr(90,36,9); S.rect('black',0,0,90,36)
for c in range(4):
    for r in range(5):
        x=2+c*22; y=2+r*7; S.rect('steel',x,y,20,6,edge=True); S.rect_px(BL[2],x+3,y+2,4,1); S.rect_px(BL[4],x+15,y+2,2,2)
S.rect_px(MAT['steel'][0],68,30,14,1)
done('Mailboxes',S,'wall')
# corkboard
S=Spr(64,36,10); S.rect('wood',0,0,64,36); S.rect('cork',3,3,58,30)
for x,y,w,h,c in ((6,6,8,11,'paper'),(17,5,8,12,'paper'),(28,7,7,12,'paper'),(9,20,8,10,'paper'),(22,22,6,7,'paper'),(40,6,18,24,'cool')):
    S.rect(c,x,y,w,h,edge=False)
    for i in range(0,h-3,3): S.rect_px(BL[3],x+1,y+2+i,w-3,1)
    S.dot(x+w//2,y+1,MAT['red'][1])
for x,y in ((44,12),(50,18),(46,24),(54,10)): S.rect_px(MAT['blue'][1],x,y,4,1)
S.line('red',42,28,56,12,w=1) 
done('Corkboard',S,'wall')
# intercoms
S=Spr(16,28,11); S.rect('brass',0,0,16,28); S.rect('black',3,3,10,8,edge=False)
for i in range(4): S.rect_px(BR[4],4,4+i*2,8,1)
for j in range(3):
    for i in range(3): S.rect('black',3+i*4,15+j*4,3,3,edge=False)
done('Intercom_Brass',S,'wall')
S=Spr(16,28,12); S.rect('steel',0,0,16,28); S.rect('black',3,3,10,9,edge=False); S.rect_px(GR[2],4,5,8,1); S.rect_px(GR[3],4,8,5,1)
for j in range(3):
    for i in range(3): S.rect('black',3+i*4,15+j*4,3,3,edge=False); S.dot(4+i*4,16+j*4,MAT['steel'][1])
done('Intercom_Grey',S,'wall')
S=Spr(16,28,13); S.rect('red',0,0,16,28); ctext(S,8,3,'FIRE',CREAM); S.rect('paper',4,10,8,8,edge=False); S.rect_px(MAT['red'][2],6,12,4,4); S.rect('black',4,20,5,4,edge=False); S.rect('steel',10,21,3,4,edge=False); done('FireAlarm',S,'wall')
# radiator
S=Spr(40,30,14); S.rect('black',1,0,38,4); S.rect('black',1,26,38,4)
for x in range(2,38,5): S.rect('steel',x,3,4,24); S.rect_px(MAT['steel'][0],x,4,1,22)
S.rect('steel',0,0,3,30); S.rect('steel',37,0,3,30)
done('Radiator',S,'wall')
# wall AC
S=Spr(40,26,15); S.rect('cream',0,0,40,26); S.rect('black',3,3,20,20,edge=False)
for y in range(4,22,2): S.rect_px(MAT['steel'][2],4,y,18,1)
S.ell('black',5,5,20,20,edge=False)
for y in range(4,22,2): S.rect_px(MAT['cream'][3],27,4+y-4,10,1)
S.rect_px(GR[2],25,21,2,2); done('WallAC',S,'wall')
# paintings
def frame(name,w,h,paint,seed,fm='wood'):
    S=Spr(w,h,seed); S.rect(fm,0,0,w,h); paint(S,w,h); done(name,S,'wall')
def p_land(S,w,h):
    S.rect('blue',2,2,w-4,h-4,edge=False); S.rect('cool',2,2,w-4,8,edge=False)
    for x in range(3,w-3,5): S.poly('green',[(x,h-6),(x+3,h-14-(x%3)*3),(x+6,h-6)],edge=False)
    S.rect('green',2,h-8,w-4,6,edge=False)
def p_city(S,w,h):
    S.rect('navyd',3,3,w-6,h-6,edge=False); S.rect('orange',3,h-18,w-6,5,edge=False); S.rect('red',3,h-14,w-6,3,edge=False)
    for i,x in enumerate(range(5,w-5,7)):
        hh=10+(i*7)%13; S.rect('black',x,h-4-hh,6,hh,edge=False)
        for y in range(h-2-hh,h-6,3): S.dot(x+2,y,YEL[1])
def p_small(S,w,h):
    S.rect('cool',2,2,w-4,h-4,edge=False); S.rect('green',2,h-8,w-4,6,edge=False); S.rect('blue',2,h-12,w-4,4,edge=False)
def p_portrait(S,w,h):
    S.rect('cream',2,2,w-4,h-4,edge=False); S.ell('rust',w//2-4,6,w//2+4,16,edge=False); S.rect('red',w//2-6,16,12,h-18,edge=False)
frame('Painting_Landscape',50,36,p_land,20); frame('Painting_City',34,44,p_city,21,'black'); frame('Painting_Small',26,20,p_small,22); frame('Painting_Portrait',22,26,p_portrait,23)
# skyline window
S=Spr(52,40,24); S.rect('black',0,0,52,40); S.rect('navyd',3,3,46,34,edge=False); S.rect('orange',3,26,46,4,edge=False)
for i,x in enumerate(range(4,48,6)):
    hh=8+(i*5)%14; S.rect('black',x,34-hh,5,hh,edge=False)
    for y in range(36-hh,33,3): S.dot(x+2,y,YEL[1])
S.rect('steel',3,3,46,4); 
for y in (3,5): S.rect_px(MAT['steel'][2],3,y+1,46,1)
S.rect_px(BL[1],25,3,1,34); S.rect_px(BL[1],3,20,46,1)
done('Window_Skyline',S,'wall')
# brick sections
def brick(S,w,h):
    S.rect('brick',0,0,w,h)
    for y in range(0,h,4):
        S.rect_px(MAT['brick'][3],0,y,w,1)
        for x in range((y//4%2)*4,w,8): S.rect_px(MAT['brick'][3],x,y,1,4)
S=Spr(64,56,25); brick(S,64,56); done('Brick_Plain',S,'wall')
def bwin(name,lit,seed):
    S=Spr(64,56,seed); brick(S,64,56); S.rect('black',18,6,28,36); S.rect('navyd' if not lit else 'orange',20,8,24,32,edge=False)
    if lit:
        S.rect('amber',22,10,20,28,edge=False); S.rect_px(MAT['orange'][3],24,12,16,1)
    else:
        for x in (20+8,20+16): pass
    S.rect_px(BL[1],31,8,2,32); S.rect_px(BL[1],20,22,24,2); S.rect('black',16,42,32,3)
    if not lit: S.rect('white',22,32,20,8,edge=True); [S.rect_px(MAT['white'][3],23+i*2,34,1,5) for i in range(9)]
    done(name,S,'wall')
bwin('Brick_WindowDark',False,26); bwin('Brick_WindowLit',True,27)
S=Spr(64,56,28); brick(S,64,56); S.rect('black',20,10,24,32); 
for y in range(12,40,3): S.rect_px(MAT['steel'][2],22,y,20,1)
done('Brick_Vent',S,'wall')
# breaker / electrical cabinets
S=Spr(34,44,29); S.rect('steel',0,0,34,44); S.rect('steel',3,3,28,38,edge=True); S.rect('yellow',13,10,8,10,edge=False); S.dot(17,13,BL[3]); S.rect_px(BL[3],16,15,2,3); S.rect('black',22,20,5,8,edge=False); S.rect_px(MAT['red'][1],24,22,1,3)
done('Breaker_Cabinet',S,'wall')
S=Spr(26,32,30); S.rect('steel',0,0,26,32); S.rect('steel',2,2,22,28,edge=True); S.rect('yellow',9,8,8,8,edge=False); S.poly('black',[(14,9),(11,13),(13,13),(12,15),(16,11),(14,11)],edge=False); S.rect('black',18,20,4,6,edge=False); done('Electrical_Box',S,'wall')
S=Spr(26,24,31); S.rect('wood',0,0,26,24); S.rect('black',3,3,20,18,edge=False)
for y in range(5,20,3): S.rect_px(MAT['steel'][2],4,y,18,1)
done('Vent_Grate',S,'wall')
S=Spr(30,30,32); S.rect('steel',0,0,30,30); S.rect('black',3,3,24,24,edge=False)
for y in range(5,26,3): S.rect_px(MAT['steel'][1],4,y,22,1)
for x,y in ((1,1),(27,1),(1,27),(27,27)): S.dot(x,y,BL[3])
done('Vent_Square',S,'wall')
# tile bathroom wall + shower curtain
S=Spr(48,56,33); S.rect('tile',0,0,48,56)
for y in range(0,56,7): S.rect_px(MAT['tile'][3],0,y,48,1)
for x in range(0,48,7): S.rect_px(MAT['tile'][3],x,0,1,56)
done('Tile_Wall',S,'wall')
S=Spr(34,54,34); S.rect('steel',0,0,34,3); S.rect('white',1,3,32,50,edge=False)
for x in range(3,33,4): S.rect_px(MAT['white'][2],x,4,1,49); S.rect_px(MAT['white'][0],x+1,4,1,49)
for x in range(2,32,5): S.ell('steel',x,0,x+2,6,edge=False)
S.rect_px(MAT['white'][3],1,52,32,1); done('Shower_Curtain',S,'stand')
# ---- standing
S=Spr(44,26,35); S.rect('wood',0,6,44,4); S.rect('dwood',2,10,3,16); S.rect('dwood',39,10,3,16); S.rect('dwood',4,19,36,2,edge=False)
S.rect('paper',5,15,12,3,edge=False); S.rect('cool',20,16,10,2,edge=False)
S.rect('blue',8,0,6,6); S.rect('cream',9,1,4,1) ; S.rect('green',30,1,8,5,edge=False); S.rect('green',32,0,4,2,edge=False)
done('Coffee_Table',S,'stand')
S=Spr(20,58,36); S.rect('brass',2,54,16,4); S.rect('brass',9,14,2,40); S.poly('amber',[(4,2),(16,2),(19,14),(1,14)]); S.rect_px(MAT['amber'][3],1,13,18,1); S.rect_px(MAT['amber'][0],6,3,3,10); done('Floor_Lamp',S,'stand')
S=Spr(46,42,37); S.rect('black',4,0,38,26); S.rect('gray',7,3,32,20,edge=False)
import random
r=random.Random(3)
for y in range(3,23):
    for x in range(7,39): 
        v=r.random(); S.dot(x,y,MAT['white'][0] if v>.7 else (MAT['steel'][3] if v<.3 else MAT['steel'][1]))
S.rect('black',14,26,18,2,edge=False); S.rect('dwood',0,28,46,14); S.rect('dwood',2,30,42,3,edge=False); S.rect('black',5,34,17,6,edge=False); S.rect('dwood',24,34,17,6,edge=False); S.dot(32,37,BR[1]); S.rect_px(MAT['dwood'][0],0,28,46,1)
done('TV_Stand',S,'stand')
# dining set
S=Spr(64,52,38)
S.rect('wood',12,20,42,5); S.rect('dwood',14,25,3,22); S.rect('dwood',50,25,3,22); S.rect_px(WD[0],12,20,42,1)
S.rect('dwood',2,6,3,44); S.rect('dwood',2,26,16,3); S.rect('dwood',3,29,3,20); S.rect('dwood',14,29,3,20); S.rect('dwood',2,6,10,3)
S.rect('dwood',58,14,3,36); S.rect('dwood',48,28,13,3); S.rect('dwood',47,31,3,18); S.rect('dwood',58,31,3,18)
S.rect('white',30,13,7,7); S.rect_px(MAT['white'][3],33,15,3,1); S.rect('red',22,10,8,10); S.rect('yellow',24,12,4,4,edge=False)
done('Dining_Set',S,'stand')
# fridge
S=Spr(28,52,39); S.rect('white',0,0,28,52); S.rect_px(MAT['white'][3],1,17,26,2); S.rect('steel',3,6,2,8,edge=False); S.rect('steel',3,22,2,14,edge=False)
S.rect('yellow',12,7,5,5,edge=False); S.rect('yellow',19,12,4,4,edge=False); S.rect('paper',11,26,6,7,edge=False); S.rect('red',18,28,4,4,edge=False); S.rect('black',2,50,24,2,edge=False)
done('Fridge_Magnets',S,'stand')
# kitchen block
S=Spr(88,54,40); S.rect('wood',2,0,66,14); 
for x in (2,24,46): S.rect_px(WD[4],x+20,1,1,12)
S.rect('steel',26,14,26,3,edge=False)
S.rect('tile',2,17,86,14,edge=False)
for x in range(2,88,6): S.rect_px(MAT['tile'][3],x,17,1,14)
S.rect('wood',0,31,32,23); S.rect('steel',36,31,20,23); S.rect('black',40,38,12,8,edge=False); S.rect('wood',60,31,28,23)
for x in (2,26,62,82): pass
S.rect_px(WD[4],15,33,1,20); S.rect_px(WD[4],73,33,1,20)
S.rect('dwood',0,31,32,3,edge=False); S.rect('dwood',60,31,28,3,edge=False)
S.rect('white',66,18,18,13); S.rect('black',68,20,10,9,edge=False); S.rect_px(GR[2],80,20,2,1)
S.ell('blue',5,24,9,31,edge=False); S.ell('red',11,25,14,31,edge=False); S.rect('white',40,27,4,4,edge=False)
S.rect('black',40,28,0,0,edge=False) if False else None
done('Kitchen_Block',S,'stand')
# bathroom fixtures
S=Spr(30,34,41); S.rect('white',0,6,26,7); S.rect('white',8,13,10,8); S.rect('white',6,20,14,14); S.rect('steel',4,0,3,6,edge=False); S.rect_px(MAT['steel'][0],3,0,5,1)
done('Sink_Pedestal',S,'stand')
S=Spr(28,38,42); S.rect('white',4,0,20,16); S.rect('white',2,15,24,5); S.rect('white',6,20,16,14); S.rect('white',3,34,22,4); S.rect_px(MAT['white'][3],6,14,16,1); S.rect('steel',11,2,5,2,edge=False)
done('Toilet',S,'stand')
# washers
def washer(name,seed,basket):
    S=Spr(34,44,seed); S.rect('white',0,10,34,34); S.rect('steel',3,12,28,4,edge=False); S.rect('black',3,20,0,0,edge=False) if False else None
    S.ell('steel',6,19,28,41,edge=False); S.ell('black',9,22,25,38,edge=False); S.ell('cool',11,24,23,36,edge=False)
    S.rect_px(MAT['cool'][3],13,27,8,1); S.dot(28,14,MAT['red'][1]); S.dot(25,14,GR[1])
    if basket:
        S.rect('steel',5,0,22,10,edge=True)
        for x in range(7,26,3): S.rect_px(MAT['steel'][3],x,2,1,7)
    else:
        S.rect('red',5,3,6,7); S.rect('blue',14,3,6,7); S.rect('cream',6,3,4,1,edge=False); S.rect('black',6,5,0,0,edge=False) if False else None
    done(name,S,'stand')
washer('Washer',43,False); washer('Dryer',44,True)
# pantry shelf
S=Spr(36,50,45); S.rect('black',0,0,36,50); S.rect('black',3,3,30,44,edge=False)
for i,y in enumerate((3,14,25,36)): S.rect('steel',0,y+10,36,2,edge=False)
for x,y,c in ((5,4,'red'),(10,6,'yellow'),(15,5,'green'),(20,7,'orange'),(26,5,'blue'),(5,15,'green'),(11,17,'red'),(24,16,'cream'),(29,18,'yellow')):
    S.rect(c,x,y,4,9 if y<10 else 8,edge=False)
S.rect('paper',5,26,7,8,edge=False); S.rect('paper',14,27,7,7,edge=False); S.rect('green',24,26,4,9,edge=False); S.rect('blue',29,28,3,7,edge=False)
S.rect('cork',4,38,14,9,edge=False); S.rect('cream',22,39,8,8,edge=False)
done('Pantry_Shelf',S,'stand')
# stairs with rail
S=Spr(50,56,46)
for i in range(6): S.rect('conc',12+i*6,24+i*5,38-i*6,5+ (i==5)*0) if False else None
for i in range(6): S.rect('gray',6+i*6,26+i*5-0,44-i*6,5,edge=True)
S.rect('black',2,4,3,52); S.line('black',3,4,3,54,w=3)
S.poly('black',[(4,54),(4,44),(12,42),(12,50)],edge=False) if False else None
S.line('black',5,26,42,2,w=2)
for x in range(8,40,6): S.rect_px(BL[2],x,29-int((x-8)*.75)+ (0),1,20)
S.rect('black',1,2,4,54); S.rect('black',0,52,8,4)
done('Stairs_Rail',S,'stand')
# fire escape platform
S=Spr(80,56,47); S.rect('black',0,8,80,3)
for x in range(2,78,6): S.rect_px(BL[2],x,11,2,0+0)
S.rect('black',0,0,80,2)
for x in range(2,79,4): S.rect('black',x,0,1,9,edge=False)
S.rect('black',0,8,80,4); S.rect('steel',0,12,80,2,edge=False)
S.line('black',10,14,4,54,w=3); S.line('black',70,14,76,54,w=3); S.line('black',20,14,40,34,w=2); S.line('black',60,14,40,34,w=2)
done('FireEscape_Platform',S,'stand')
# chain link
S=Spr(52,44,48); 
S.rect('steel',0,0,3,44); S.rect('steel',49,0,3,44); S.rect('steel',0,0,52,3)
for y in range(4,42): 
    for x in range(3,49):
        if (x+y)%4==0 or (x-y)%4==0: S.dot(x,y,MAT['steel'][1 if (x+y)%8 else 2])
done('Chainlink_Fence',S,'stand')
# street lamp, pipes
S=Spr(16,66,49); S.rect('black',6,16,4,48); S.rect('black',3,62,10,4); S.rect('black',3,10,10,6); S.rect('amber',4,2,8,10,edge=False); S.rect('black',2,0,12,3); S.rect_px(MAT['amber'][0],5,4,2,6); done('Street_Lamp',S,'stand')
def pipe_v(name,w,seed):
    S=Spr(w,64,seed); S.rect('steel',0,0,w,64); S.rect_px(MAT['steel'][0],1,0,1,64); S.rect('steel',-1,10,w+2,3) if False else None
    S.rect('black',0,10,w,3,edge=False); S.rect('black',0,46,w,3,edge=False); done(name,S,'stand')
pipe_v('Pipe_Thin',10,50); pipe_v('Pipe_Thick',14,51)
S=Spr(40,44,52); S.rect('steel',14,0,10,34); S.rect('steel',14,26,26,10); S.rect('black',12,0,14,3,edge=False); S.rect('black',34,24,4,14,edge=False)
S.ell('red',3,26,13,36,edge=False); S.ell('black',6,29,10,33,edge=False); S.rect('steel',10,29,6,4,edge=False); done('Pipe_Valve',S,'stand')
S=Spr(52,54,53); S.rect('steel',0,0,14,54); S.rect('steel',0,0,52,14); S.rect('black',12,0,3,14,edge=False); S.rect('black',38,0,3,14,edge=False); S.rect('black',0,44,14,3,edge=False); S.rect_px(MAT['steel'][0],1,0,1,54); done('Pipe_Elbow',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
