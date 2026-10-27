import sys; sys.path.insert(0,'.')
from trace import *
import lib, os, json, io, struct, zlib, math
import px
MAT=lib.MAT
for k,v in {'olive':'#8a9a64 #66744a #4c5836 #343e24 #1e2614','conc':'#d0d4d8 #a8aeb4 #848a92 #5c626a #3c4048','cork':'#d8a468 #b8804a #94602c #6c4420 #442a12','subblue':'#5a7ac8 #34509c #263c7c #1a2a58 #101a38','orange':'#f8a860 #e07a28 #b05a18 #7c3c0c #4a2206','blue':'#5a86d0 #2e5aa8 #204486 #16305e #0c1c3a','rust':'#d89058 #b06a38 #86481e #5c300e #381c08','navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022','amber':'#fff2b8 #ffd468 #e2a624 #a26e12 #60400a','cool':'#ffffff #e8f4ff #c8dcf0 #90a8c0 #5a6c80'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); GR=MAT['glow']; BL=MAT['black']; ST=MAT['steel']
os.makedirs('out',exist_ok=True); OUTS={}; CODES='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
def done(name,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    n=len(OUTS); fn=('CSW' if n<36 else 'CSX')+CODES[n%36]
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
SB=MAT['subblue']; AMB=hx('#ffb020'); AMB2=hx('#c07810')
def hang(S,x):
    S.rect('black',x,0,2,5,edge=False)
def bigt(S,x,y,t,c,k=2,sp=1):
    T_=Spr(len(t)*(3+sp),5,1); T_.text(0,0,t,(255,255,255,255),sp); im=T_.im.resize((T_.w*k,T_.h*k),Image.NEAREST); p=im.load()
    for j in range(im.height):
        for i in range(im.width):
            if p[i,j][3]>0: S.dot(x+i,y+j,c)
# ---- hanging signs
S=Spr(58,36,1); hang(S,8); hang(S,48); S.rect('black',0,5,58,31); S.rect_px(hx('#10141c'),2,7,54,27)
S.rect('paper',4,9,17,20,edge=False); S.rect_px(BL[3],5,10,15,18); bigt(S,8,13,'2',MAT['paper'][0],3,1)
S.text(24,11,'LOCAL',MAT['paper'][1]); S.text(24,18,'TO CITY',MAT['paper'][1])
for i,c in enumerate((AMB,hx('#4a90e8'),hx('#5c6070'))): S.rect_px(c,25+i*5,26,3,3)
done('Sign_Local',S,'stand')
def board(name,w,h,rows,hung=True,kind='stand'):
    S=Spr(w,h,2)
    if hung: hang(S,8); hang(S,w-10)
    y0=5 if hung else 0; S.rect('black',0,y0,w,h-y0); S.rect_px(hx('#0e0e12'),2,y0+2,w-4,h-y0-4)
    ctext(S,w//2,y0+4,'NEXT TRAINS',AMB)
    for i,(n,nm,t) in enumerate(rows):
        y=y0+12+i*7; S.rect('yellow',4,y-1,6,7,edge=False); S.text(6,y,n,BL[4]); S.text(13,y,nm,AMB); S.text(w-4-len(t)*4+1,y,t,AMB)
    done(name,S,kind)
R=(('1','DOWNTOWN','2 MIN'),('2','MIDTOWN','7 MIN'),('2','AIRPORT','12 MIN'),('3','HARBOR','18 MIN'))
board('Board_Departures',80,44,R); board('Board_DeparturesWall',72,42,R,hung=False,kind='wall')
S=Spr(66,28,3); hang(S,8); hang(S,56); S.rect('subblue',0,5,66,23); S.rect_px(SB[4],2,7,62,19)
S.poly('paper',[(8,17),(13,11),(13,14),(20,14),(20,20),(13,20),(13,23)],edge=False) if False else None
arrow(S,5,13,c=MAT['paper'][0]); arrow(S,5,13,c=MAT['paper'][0],left=True) if False else None
S.rect('red',24,8,38,16,edge=True); bigt(S,28,11,'EXIT',MAT['paper'][0],2,1); S.rect_px(MAT['paper'][0],14,10,1,12); S.poly('paper',[(14,9),(10,14),(18,14)],edge=False)
done('Sign_Exit',S,'stand')
S=Spr(52,30,4); hang(S,8); hang(S,42); S.rect('black',0,5,52,25); S.rect_px(hx('#10161e'),2,7,48,21)
arrow(S,5,13,c=MAT['paper'][0],left=True); S.text(14,10,'TRAINS',MAT['paper'][0])
for i,(c,n) in enumerate(((hx('#e04030'),'1'),(hx('#f0a020'),'2'),(hx('#3a90e8'),'3'))): S.ell('paper',15+i*9,17,23+i*9,25,edge=False) if False else None; S.rect_px(c,15+i*9,18,7,7); S.text(16+i*9,19,n,hx('#ffffff'))
done('Sign_Trains',S,'stand')
# ---- icon plates
def plate(name,fn,c='black'):
    S=Spr(20,22,5); S.rect(c,0,0,20,22); S.rect_px(MAT[c][0] if c!='black' else BL[0],1,1,18,1); fn(S); done(name,S,'wall')
W_=MAT['paper'][0]
def person(S,cx,y,sk=False):
    S.rect_px(W_,cx-1,y,3,3); S.rect_px(W_,cx-2,y+4,5,6) if not sk else S.poly('paper',[(cx,y+4),(cx-4,y+11),(cx+4,y+11)],edge=False)
    if not sk: S.rect_px(W_,cx-2,y+10,2,5); S.rect_px(W_,cx+1,y+10,2,5)
    else: S.rect_px(W_,cx-2,y+11,2,4); S.rect_px(W_,cx+1,y+11,2,4)
def i_elev(S):
    for x in (5,11): S.poly('paper',[(x+2,3),(x-1,7),(x+5,7)],edge=False)
    S.rect_px(W_,3,9,14,10); S.rect_px(BL[2],4,10,5,8); S.rect_px(BL[2],11,10,5,8)
def i_stairs(S):
    for i in range(5): S.rect_px(W_,3+i*3,15-i*3,4,2); S.rect_px(W_,3+i*3,15-i*3,1,5-(i*0))
def i_esc(S):
    for i in range(5): S.rect_px(W_,3+i*3,16-i*3,3,1)
    S.line('paper',3,18,16,7,w=1); S.rect_px(W_,9,4,2,2)
def i_acc(S):
    S.rect_px(W_,8,3,3,3); S.rect_px(W_,9,7,2,6); S.rect_px(W_,9,10,6,2); S.rect_px(W_,14,12,2,5); circ(S,9,15,4,W_)
def i_men(S): person(S,10,3)
def i_wom(S): person(S,10,3,True)
plate('Icon_Elevator',i_elev); plate('Icon_Stairs',i_stairs); plate('Icon_Escalator',i_esc); plate('Icon_Accessible',i_acc,'subblue'); plate('Icon_Men',i_men); plate('Icon_Women',i_wom)
# ---- posters
def poster(name,w,h,bg,fn,kind='wall'):
    S=Spr(w,h,6); S.rect(bg,0,0,w,h,noise=.02); S.rect_px(MAT[bg][3],0,h-1,w,1); S.rect_px(MAT[bg][3],w-1,0,1,h); S.rect_px(BL[3],1,1,w-2,1) if False else None; fn(S,w,h); done(name,S,'wall')
LC=(hx('#e04030'),hx('#3a90e8'),hx('#3ab060'),hx('#f0a020'),hx('#f0d030'))
def maplines(S,x,y,w,h,seed=1):
    r=random.Random(seed)
    for k,c in enumerate(LC):
        px_=x+2+r.randrange(4); py=y+2+k*(h//6); pts=[(px_,py)]
        for _ in range(4): pts.append((pts[-1][0]+r.randrange(w//6,w//3),pts[-1][1]+r.randrange(-h//5,h//5)))
        for a,b in zip(pts,pts[1:]): S.line('paper',a[0],a[1],b[0],b[1],w=1) if False else None
        for a,b in zip(pts,pts[1:]):
            for t in range(0,11):
                xx=a[0]+(b[0]-a[0])*t//10; yy=a[1]+(b[1]-a[1])*t//10
                if x<=xx<x+w and y<=yy<y+h: S.dot(xx,yy,c); S.dot(xx,yy+1,c)
        for p in pts:
            if x<=p[0]<x+w and y<=p[1]<y+h: S.rect_px(hx('#ffffff'),p[0]-1,p[1],3,3); S.dot(p[0],p[1]+1,BL[3])
def p_map(S,w,h): S.rect_px(BL[3],2,3,w-4,7); ctext(S,w//2,5,'METRO MAP',MAT['paper'][0]); maplines(S,3,13,w-6,h-16,4)
poster('Poster_Map',42,50,'cream',p_map)
def p_see(S,w,h):
    S.ell('paper',6,8,w-7,26,edge=False); S.ell('subblue',w//2-7,10,w//2+7,24,edge=False); S.ell('black',w//2-3,14,w//2+3,20,edge=False); S.dot(w//2-2,15,MAT['paper'][0])
    S.rect_px(BL[3],4,9,w-8,1) if False else None; S.rect_px(SB[4],0,h-13,w,13)
    ctext(S,w//2,27,'SEE',BL[3]); ctext(S,w//2,33,'SOMETHING',BL[3]); ctext(S,w//2,h-11,'SAY',MAT['paper'][0]); ctext(S,w//2,h-6,'SOMETHING',MAT['paper'][0])
poster('Poster_SeeSay',44,52,'cream',p_see)
def p_alert(S,w,h):
    ctext(S,w//2,5,'STAY',MAT['red'][2]); ctext(S,w//2,12,'ALERT',MAT['red'][2])
    S.rect('black',8,20,16,9); S.ell('steel',12,22,18,28,edge=False); S.rect_px(BL[4],14,24,2,2); S.rect('steel',22,22,6,4); S.rect('black',6,28,4,7); S.rect('black',4,34,10,2)
poster('Poster_StayAlert',36,46,'cream',p_alert)
def p_ride(S,w,h):
    ctext(S,w//2,5,'RIDE SAFER',MAT['paper'][0]); ctext(S,w//2,12,'TOGETHER',MAT['paper'][0])
    S.rect('paper',8,20,w-16,22,edge=True); S.rect_px(SB[3],10,24,w-20,9)
    for x in (12,21,30): S.rect_px(hx('#a8c8e8'),x,25,7,7)
    S.rect_px(hx('#f0a020'),8,36,w-16,2); S.rect_px(AMB,11,39,3,2); S.rect_px(AMB,w-14,39,3,2); S.rect_px(hx('#181820'),6,h-4,w-12,2)
poster('Poster_Ride',40,50,'red',p_ride)
def p_sky(S,w,h):
    rr=random.Random(3)
    for x in range(2,w-4,7):
        bh=rr.randrange(14,30); S.rect_px(SB[4],x,h-10-bh,6,bh)
        for yy in range(h-8-bh,h-12,4):
            if rr.random()>.35: S.dot(x+1,yy,AMB); S.dot(x+4,yy,AMB)
    S.rect_px(BL[3],0,h-10,w,10); ctext(S,w//2,5,'OUR CITY',MAT['paper'][1]); ctext(S,w//2,12,'MOVES',MAT['paper'][1])
poster('Poster_Skyline',38,50,'subblue',p_sky)
# ---- clock
S=Spr(32,32,7); S.part('black',lambda d:d.ellipse((0,0,31,31),fill=255),form=None); S.ell('paper',3,3,28,28,edge=False)
for a in range(0,360,30): S.rect_px(BL[3],16+round(11*math.cos(math.radians(a)))-0,16+round(11*math.sin(math.radians(a))),2 if a%90==0 else 1,2 if a%90==0 else 1)
S.line('black',16,16,16,7,w=1); S.line('black',16,16,23,20,w=1); S.dot(16,16,MAT['red'][1]); done('Clock_Wall',S,'wall')
# ---- kiosk map
S=Spr(64,52,8); S.rect('black',0,0,64,46); S.rect('cream',3,3,58,40,noise=.02); maplines(S,4,6,56,34,9); S.rect_px(BL[3],4,4,56,1)
S.rect('black',6,46,4,6); S.rect('black',54,46,4,6); S.rect('black',2,50,10,2); S.rect('black',52,50,10,2); done('Kiosk_Map',S,'stand')
# ---- benches
def bench_blue(name,n):
    w=n*15+6; S=Spr(w,30,9); S.rect('black',0,22,w,3); S.rect('black',2,25,3,5); S.rect('black',w-5,25,3,5)
    for i in range(n): x=3+i*15; S.rect('subblue',x,2,13,12); S.rect('subblue',x,14,13,9); S.rect_px(SB[0],x+1,2,11,1); S.rect_px(SB[3],x,13,13,1)
    S.rect('black',0,10,3,14); S.rect('black',w-3,10,3,14); done(name,S,'stand')
bench_blue('Bench_Blue4',4); bench_blue('Bench_Blue3',3)
S=Spr(60,30,10)
for y in (4,10): S.rect('conc',3,y,54,4)
for y in (17,22): S.rect('conc',3,y,54,4)
for x in (4,52): S.rect('black',x,2,3,28); S.rect('black',x,12,3,4)
S.rect('black',0,14,60,3); done('Bench_Steel',S,'stand')
# ---- machines
S=Spr(44,58,11); S.rect('steel',0,0,44,58); S.rect('black',3,3,38,8); ctext(S,22,5,'TICKETS',hx('#e0e4ec'))
S.rect('black',5,14,34,20,edge=False); S.rect_px(hx('#0a2a3a'),7,16,30,16); S.rect_px(hx('#3a90e8'),9,18,14,6); S.rect_px(hx('#5af0ff'),9,26,20,1); S.rect_px(hx('#3ab060'),26,18,8,6)
S.rect('black',5,38,12,8); S.rect_px(AMB,7,41,8,2); S.rect('black',22,38,17,4); S.rect('steel',22,45,17,6,edge=True); S.rect_px(BL[4],24,47,13,2); S.rect('subblue',5,48,14,8) if False else None; S.rect('black',0,54,44,4); done('TicketMachine',S,'stand')
def newsbox(name,m,t):
    S=Spr(22,32,12); S.rect(m,0,3,22,29); S.rect('black',1,0,20,4); S.rect_px(MAT[m][4],0,10,22,1); ctext(S,11,5,t,MAT['paper'][0]) if False else None; S.rect('paper',3,13,16,10,edge=False); S.rect_px(BL[3],4,15,14,1); S.rect_px(BL[3],4,18,10,1); S.rect_px(BL[3],4,21,12,1); S.rect('black',5,26,12,3); S.rect_px(MAT[m][0],2,4,18,1); done(name,S,'stand')
newsbox('NewsBox_Blue','subblue','NEWS'); newsbox('NewsBox_Red','red','NEWS')
def turnstile(name,ok):
    S=Spr(30,38,13); S.rect('steel',0,0,14,38); S.rect_px(BL[3],2,3,10,10); S.rect_px(hx('#3ab060') if ok else hx('#e04030'),4,5,6,6); S.rect_px(hx('#a0ffb0') if ok else hx('#ff9080'),5,6,2,2)
    S.rect('black',2,17,10,3); S.rect('black',2,26,10,4)
    S.line('steel',14,24,28,24,w=2); S.rect('black',26,22,4,5); done(name,S,'stand')
turnstile('Turnstile_Closed',False); turnstile('Turnstile_Open',True)
S=Spr(16,38,14); S.rect('steel',0,0,16,38); S.rect('black',2,3,12,12); S.poly('green',[(8,5),(4,10),(12,10)],edge=False); S.rect_px(GR[1],7,10,2,4); S.rect('black',3,20,10,10); S.rect_px(hx('#a0c0d0'),5,22,6,2); done('GateReader',S,'stand')
# ---- street-ish
S=Spr(22,30,15); S.part('orange',lambda d:d.polygon([(4,0),(17,0),(21,29),(0,29)],fill=255),form='cyl')
for y in (6,16): S.rect_px(hx('#ecece4'),(y//8),y,22-y//4,4)
S.rect('black',0,27,22,3); done('Barrel_Traffic',S,'stand')
S=Spr(28,42,16); S.rect('red',5,0,3,34); S.rect('red',5,2,8,3); S.rect('steel',2,30,20,3); wheels(S,(9,),33,4)
S.line('red',7,4,7,32,w=2); S.rect('red',5,20,3,3); S.rect('steel',6,30,16,3); done('HandTruck_Red',S,'stand')
S=Spr(44,38,17); S.rect('yellow',0,26,44,4); S.rect_px(YEL[3],0,29,44,1); S.rect('yellow',0,2,3,26); S.rect('yellow',0,2,10,3); S.rect('black',2,22,40,2) if False else None; wheels(S,(6,38),30,3); done('LuggageCart',S,'stand')
S=Spr(26,34,18); S.part('conc',lambda d:d.rounded_rectangle((1,4,24,30),3,fill=255),form='cyl'); S.rect('black',0,0,26,6); S.rect_px(BL[0],0,0,26,1); wheels(S,(5,20),29,2) if False else None; S.rect('black',2,30,5,4); S.rect('black',19,30,5,4); done('Bin_Wheelie',S,'stand')
# fence
S=Spr(64,42,19); S.rect('black',0,0,4,42); S.rect('black',60,0,4,42); S.rect('black',0,0,64,3); S.rect('black',0,39,64,3)
for x in range(6,60,3): S.rect_px(hx('#a8b0b8') if x%6 else hx('#788088'),x,4,1,35)
for y in range(5,38,3): S.rect_px(hx('#8a9098'),4,y,56,1)
S.rect('paper',8,10,20,14,edge=False); S.rect_px(MAT['red'][1],8,10,20,1); S.rect_px(MAT['red'][1],8,23,20,1)
ctext(S,18,13,'STAFF',MAT['red'][2]); ctext(S,18,19,'ONLY',MAT['red'][2])
S.ell('paper',36,10,52,26,edge=False); S.ell('red',37,11,51,25,edge=False); S.rect('paper',40,17,8,3,edge=False); done('Fence_Authorized',S,'stand')
S=Spr(30,46,20)
for x0,x1 in ((3,7),(27,23)): S.line('red',x0,2,x1-2 if x0<10 else x1+2,44,w=3) if False else None
S.line('red',4,44,10,2,w=3); S.line('red',22,44,16,2,w=3); S.rect('red',9,2,8,4)
for y in (12,20,28,36): S.rect('red',6-(y//14)+1,y,14+2*(y//14),2)
done('Ladder_Red',S,'stand')
S=Spr(28,16,21); S.rect('red',0,4,26,12); S.rect_px(MAT['red'][4],0,9,26,1); S.rect('steel',9,0,10,4,edge=True) if False else None; S.rect('black',9,1,10,4); S.rect('steel',3,7,3,4); S.rect('steel',20,7,3,4); done('Toolbox_Red',S,'stand')
S=Spr(10,44,22); S.rect('wood',4,0,2,30); S.poly('rust',[(0,44),(3,30),(7,30),(10,44)]); S.rect_px(MAT['rust'][4],1,40,8,1); done('Broom',S,'stand')
# ---- wall devices
S=Spr(26,34,23); S.rect('red',0,0,26,34); S.rect_px(MAT['red'][4],2,2,22,30); S.rect_px(hx('#a8c0d0'),3,3,20,28); S.rect_px(hx('#78909c'),3,3,20,1)
S.part('red',lambda d:d.rounded_rectangle((9,9,17,29),3,fill=255),form='cyl'); S.rect('black',10,6,6,4); S.rect('paper',10,17,6,6,edge=False); done('Cabinet_Extinguisher',S,'wall')
S=Spr(20,32,24); S.rect('conc',0,0,20,32); S.rect('steel',2,2,16,28,edge=True); S.rect('black',5,5,10,5,edge=False); S.rect('black',6,12,8,10); S.rect_px(ST[0],7,14,6,4); S.rect('black',4,24,12,3); done('Payphone',S,'wall')
S=Spr(34,38,25); S.rect('conc',0,0,34,38); S.rect('steel',2,2,30,34,edge=True); S.rect_px(BL[3],17,2,1,34); S.poly('yellow',[(9,8),(4,18),(14,18)],edge=False); S.poly('black',[(9,11),(6,17),(12,17)],edge=False); S.rect_px(YEL[1],8,13,2,3); S.rect('black',22,14,6,8); done('Cabinet_Electrical',S,'wall')
S=Spr(22,20,26); S.ell('paper',2,1,20,15,edge=False); S.part('black',lambda d:d.pieslice((2,1,20,15),0,180,fill=255),edge=False); S.ell('black',7,5,15,12,edge=False); S.rect_px(hx('#5a7ac8'),10,8,2,2); S.rect('steel',9,14,4,5); done('Camera_Dome',S,'wall')
S=Spr(24,22,27); S.rect('black',0,6,10,10); S.poly('steel',[(8,3),(22,0),(22,21),(8,17)]); S.rect_px(BL[3],10,6,10,10); S.rect_px(BL[2],14,4,1,14); done('Speaker_Horn',S,'wall')
S=Spr(20,22,28); S.rect('conc',0,0,20,22); S.rect('steel',2,2,16,18,edge=True); S.poly('yellow',[(12,5),(6,12),(10,12),(8,18),(15,10),(11,10)],edge=False); done('Box_Electrical',S,'wall')
S=Spr(28,26,29); S.rect('black',12,0,4,7); S.part('black',lambda d:d.pieslice((0,2,27,30),180,360,fill=255),edge=True) if False else None
S.poly('black',[(4,8),(24,8),(27,18),(1,18)]); S.rect('amber',5,17,18,5,noise=0,edge=False); S.rect_px(MAT['amber'][0],8,18,12,2); done('Light_Pendant',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
