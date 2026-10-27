import sys; sys.path.insert(0,'.')
from trace import *
import lib, os, json, io, struct, zlib, math
import px
MAT=lib.MAT
for k,v in {'olive':'#8a9a64 #66744a #4c5836 #343e24 #1e2614','conc':'#d0d4d8 #a8aeb4 #848a92 #5c626a #3c4048','leaf':'#b4f070 #68cc40 #3ea22e #24701f #123e18','trough':'#c8d4f4 #98a8d4 #7488b8 #4e5e8c #2e3a5c','sack':'#ecd8aa #c8ac78 #a48854 #7a6036 #4a381c','cork':'#d8a468 #b8804a #94602c #6c4420 #442a12','orange':'#f8a860 #e07a28 #b05a18 #7c3c0c #4a2206','blue':'#5a86d0 #2e5aa8 #204486 #16305e #0c1c3a','rust':'#d89058 #b06a38 #86481e #5c300e #381c08','navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022','amber':'#fff2b8 #ffd468 #e2a624 #a26e12 #60400a','cool':'#ffffff #e8f4ff #c8dcf0 #90a8c0 #5a6c80'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); GR=MAT['glow']; BL=MAT['black']; ST=MAT['steel']
os.makedirs('out',exist_ok=True); OUTS={}; CODES='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
def done(name,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    n=len(OUTS); fn=('CHY' if n<36 else 'CHZ')+CODES[n%36]
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
def leaves(S,x0,y0,w,h,n,seed=1,mat='leaf'):
    rnd=random.Random(seed); pts=sorted((rnd.randrange(y0,y0+h),rnd.randrange(x0,x0+w),rnd.choice((3,4,4,5))) for _ in range(n))
    for cy,cx,r in pts: S.ell(mat,cx-r,cy-r+1,cx+r,cy+r-1)
def leaf_logo(S,cx,cy,h,c):
    S.poly_c=None
    for dy in range(h):
        t=dy/(h-1); wd=max(1,round(math.sin(t*math.pi)*h*0.32))
        for dx in range(-wd,wd+1): S.dot(cx+dx,cy-h//2+dy,c)
    S.rect_px(c,cx,cy+h//2,1,3)
LG=hx('#5ee050'); LG2=hx('#2e9a34'); GRN=MAT['green']
def mon(w,h,seed=1,inner=hx('#0a1428')):
    S=Spr(w,h,seed); S.rect('black',0,0,w,h); S.rect_px(inner,3,3,w-6,h-6); S.rect_px(BL[3],2,2,w-4,1); return S
def bars(S,x,y,hs,c,step=3):
    for i,hh in enumerate(hs): S.rect_px(c,x+i*step,y-hh,2,hh)
B0=hx('#9ad0ff'); B1=hx('#4a90e8'); B2=hx('#2860b8')
# ---------- wall signs
S=Spr(50,60,1); S.rect('paper',0,0,50,60,noise=.02); S.rect('black',0,0,50,60,edge=False) if False else None; S.rect_px(MAT['paper'][3],0,59,50,1); S.rect_px(BL[3],1,1,48,1)
leaf_logo(S,25,14,18,LG2); 
for i,t in enumerate(('AUTHORIZED','PERSONNEL','ONLY')): ctext(S,25,32+i*8,t,BL[3])
done('Sign_Authorized',S,'wall')
S=Spr(42,58,2); S.rect('yellow',0,0,42,58); S.rect_px(YEL[3],1,1,40,1)
S.poly('black',[(21,5),(4,32),(38,32)],edge=False); S.poly('yellow',[(21,10),(9,29),(33,29)],edge=False); leaf_logo(S,21,20,10,BL[3])
ctext(S,21,35,'PLANT',BL[3]); ctext(S,21,42,'RESEARCH',BL[3]); ctext(S,21,49,'AREA',BL[3]); done('Sign_PlantResearch',S,'wall')
S=Spr(28,46,3); S.rect('green',0,0,28,46); S.rect_px(GRN[4],2,2,24,42); S.rect_px(GRN[2],3,3,22,40)
S.ell('paper',10,6,16,12,edge=False); S.line('paper',13,13,10,22,w=3); S.line('paper',13,14,19,18,w=2); S.line('paper',9,22,15,28,w=2); S.line('paper',15,22,19,28,w=2)
S.rect_px(MAT['paper'][0],11,34,6,1); S.poly('paper',[(14,44),(8,37),(20,37)],edge=False); done('Sign_ExitArrow',S,'wall')
def zone(name,t):
    S=Spr(36,50,4); S.rect('black',0,0,36,50); S.rect('conc',2,2,32,46,edge=False); S.rect_px(MAT['conc'][4],2,2,32,46); S.rect_px(MAT['conc'][3],2,2,32,46)
    S.rect_px(hx('#20363a'),2,2,32,46); big(S,6,9,t,MAT['paper'][1],4) if False else None
    T_=Spr(len(t)*4,5,1); T_.text(0,0,t,(255,255,255,255)); im=T_.im.resize((T_.w*4,T_.h*4),Image.NEAREST); p=im.load()
    for j in range(im.height):
        for i in range(im.width):
            if p[i,j][3]>0: S.dot(6+i,9+j,MAT['paper'][1])
    for k in range(3): S.poly('orange',[(2+k*12,48),(10+k*12,32),(14+k*12,32),(6+k*12,48)],edge=False)
    S.rect('black',0,46,36,4) if False else None; done(name,S,'wall')
zone('Plate_A1','A1'); zone('Plate_B3','B3')
S=Spr(84,42,5); S.rect('conc',0,0,84,42); S.rect_px(MAT['conc'][3],0,41,84,1)
for i,t in enumerate(('GROW ROOMS','RESEARCH LAB','WATER PROCESSING','MAINTENANCE')):
    y=4+i*10; S.text(5,y,t,BL[3]); arrow(S,74,y,c=BL[3])
    if i<3: S.rect_px(MAT['conc'][2],3,y+8,78,1)
done('Directory_Hydro',S,'wall')
# ---------- wall devices
S=Spr(24,20,6); S.rect('paper',0,4,20,10); S.rect('black',18,3,4,12); S.ell('steel',17,5,22,13,edge=False); S.rect_px(BL[4],19,8,2,2); S.rect('steel',6,14,4,4); S.rect('steel',4,17,10,2); done('Camera_Cctv',S,'wall')
S=Spr(18,28,7); S.rect('black',0,0,18,28); S.rect('steel',2,2,14,24,edge=False); S.rect_px(BL[3],2,2,14,24); S.rect_px(MAT['red'][1],7,4,4,4); S.rect_px(hx('#ff9080'),8,5,1,1)
for j in range(4):
    for i in range(3): S.rect_px(ST[1],4+i*4,12+j*4,3,3)
done('Keypad_Door',S,'wall')
S=Spr(22,30,8); S.rect('conc',0,0,22,30); S.rect('steel',2,2,18,26,edge=True); S.rect('black',5,5,12,6,edge=False); S.rect_px(hx('#5ee050'),7,7,8,1); S.rect_px(hx('#2e9a34'),7,9,5,1); S.rect('steel',9,15,4,8); done('Control_Box',S,'wall')
S=Spr(20,30,9); S.rect('black',0,0,20,30); S.rect('steel',2,2,16,26,edge=False); S.rect_px(hx('#182838'),2,2,16,26); S.poly('blue',[(10,6),(5,16),(15,16)],edge=False); S.ell('blue',5,12,15,22,edge=False); S.rect_px(hx('#a0d8ff'),7,15,2,3); done('Panel_Water',S,'wall')
S=Spr(26,32,10); S.rect('conc',0,0,26,32); S.rect('steel',2,2,22,28,edge=True); S.rect('black',4,4,18,7,edge=False); S.rect_px(LG,6,6,10,1)
for j in range(2):
    for i in range(4): S.rect_px((MAT['red'][1],YEL[1],GR[1],B1)[(i+j)%4],5+i*5,15+j*5,3,3)
S.rect('black',8,26,10,3); done('Control_Panel',S,'wall')
S=Spr(14,22,11); S.rect('black',2,0,10,3); S.part('red',lambda d:d.rounded_rectangle((1,3,12,20),4,fill=255),form='cyl',edge=False); S.rect_px(hx('#ffc0b0'),4,6,2,6); S.rect('black',3,19,8,3); done('Beacon_Red',S,'wall')
S=Spr(28,28,12); S.rect('steel',9,0,4,28) if False else None; S.rect('steel',0,0,28,6) if False else None
S.ell('green',1,1,26,26); S.ell('black',5,5,22,22,edge=False); S.rect('green',13,2,3,24) if False else None
for a in range(0,360,45): S.line('green',13+round(9*math.cos(math.radians(a))),13+round(9*math.sin(math.radians(a))),13,13,w=2)
S.ell('steel',10,10,17,17); S.rect('black',22,20,6,4); done('HoseReel',S,'wall')
# ---------- screens
def leafmon(w,h,kind):
    S=mon(w,h,3,inner=hx('#06160c') if kind=='g' else hx('#0a1c2c'))
    leaf_logo(S,w//2,h//2-1,h-14,LG if kind=='g' else hx('#5af0d0')); return S
S=leafmon(38,32,'g'); S.rect('black',15,32,8,4); S.rect('black',9,36,20,4); done('DeskMonitor_Leaf',S,'stand',outline=True)
S=mon(54,38,4)
S.rect_px(hx('#0f2c58'),5,5,26,28)
for x in range(6,30,5): S.rect_px(B2,x,6,1,26)
for y in range(6,32,5): S.rect_px(B2,6,y,24,1)
S.rect_px(B1,10,10,8,6); S.rect_px(B1,20,18,8,6); S.line('blue',12,20,22,12,w=1)
S.rect_px(hx('#0a2210'),33,5,16,13); leaf_logo(S,41,11,8,LG); S.rect_px(hx('#0a2210'),33,20,16,13); bars(S,35,31,(4,7,5,9,6),LG2)
done('Monitor_Dashboard',S,'wall')
S=Spr(66,44,5); S.rect('black',0,34,66,8); S.rect_px(BL[0],0,34,66,1)
for i,(x,k) in enumerate(((2,'l'),(24,'r'),(46,'d'))):
    S.rect('black',x,2,20,26); ins={'l':hx('#0a2030'),'r':hx('#06160c'),'d':hx('#0a1428')}[k]; S.rect_px(ins,x+2,4,16,20)
    if k=='l': leaf_logo(S,x+10,14,12,hx('#5af0d0'))
    if k=='r':
        for r in (3,6,8): circ(S,x+10,14,r,GR[4])
        for j in range(7): S.dot(x+10+j,14-j//2,GR[1])
    if k=='d': bars(S,x+4,22,(4,9,6,11,7),B1)
    S.rect('black',x+8,28,4,6)
S.rect('black',0,40,4,4); S.rect('black',62,40,4,4); done('Console_Triple',S,'stand',outline=True)
S=Spr(32,22,6); S.rect('black',3,1,26,14); S.rect_px(hx('#0a2210'),5,3,22,10); leaf_logo(S,16,8,8,LG); S.poly('steel',[(0,15),(31,15),(29,21),(2,21)]); S.rect_px(BL[3],4,16,24,1)
for j in range(3):
    for i in range(9): S.dot(5+i*2+(j%2),17+j,BL[2])
done('Laptop_Leaf',S,'stand',outline=True)
# ---------- hydroponic racks
def rack(name,w,h,tiers,wh=False,seed=1):
    S=Spr(w,h,60); th=(h-12)//tiers
    for t in range(tiers):
        by=8+(t+1)*th
        S.rect('black',0,by+1,w,2)
        S.rect('trough',3,by-5,w-6,6); S.rect_px(MAT['trough'][3],3,by,w-6,1)
        leaves(S,5,by-14,w-10,9,max(5,w//7),seed+t*3)
    for x in (0,w-3): S.rect('black',x,0,3,h-2 if not wh else h-6)
    S.rect('black',0,0,w,3)
    if wh: wheels(S,(5,w-6),h-6,3)
    done(name,S,'stand')
rack('Rack_Hydro2',58,50,2,seed=1); rack('Rack_Hydro2Low',54,40,2,seed=5); rack('Rack_Hydro3',62,54,3,seed=9); rack('Rack_Hydro4Tall',34,68,4,seed=13); rack('Rack_HydroRolling',64,62,3,wh=True,seed=17)
S=Spr(44,30,61); S.rect('trough',0,10,44,20); S.rect_px(MAT['trough'][3],0,26,44,1); S.rect('steel',3,14,38,12,edge=False); S.rect_px(hx('#3a2a1a'),3,14,38,3); leaves(S,3,0,38,14,9,3); done('Planter_Trough',S,'stand')
S=Spr(40,42,62); S.rect('leaf',0,0,40,42); leaves(S,0,0,40,42,60,7); leaves(S,0,0,40,42,25,9,mat='green'); done('Hedge_Panel',S,'stand')
def basket(name,seed,w=30):
    S=Spr(w,44,63)
    for x in (w//2-8,w//2+8): S.line('steel',x,0,w//2,12,w=1) if False else None
    S.line('steel',w//2,0,w//2-8,16,w=1); S.line('steel',w//2,0,w//2+8,16,w=1); S.rect('steel',w//2-2,0,4,3)
    S.rect('trough',w//2-9,16,18,8); leaves(S,w//2-10,8,20,10,8,seed)
    for x in range(w//2-9,w//2+10,4): S.line('leaf',x,22,x+((x*5)%3-1),30+(x*3)%9,w=2)
    done(name,S,'stand')
basket('Basket_Hanging',3); basket('Basket_HangingB',8,32)
def growlight(name,plant):
    S=Spr(56,36,64); S.rect('black',26,0,4,8); S.rect('black',2,8,52,8); S.rect('cool',4,10,48,4,noise=0,edge=False); S.rect_px(MAT['cool'][0],8,11,40,1)
    if plant:
        for x in range(4,52,6): S.rect_px(hx('#a0e070'),x,17,3,2); S.rect_px(hx('#a0e070'),x+1,19,1,2)
    done(name,S,'stand')
growlight('GrowLight_Hanging',False); growlight('GrowLight_Purple',True)
# ---------- tanks / water
S=Spr(40,62,65); S.part('steel',lambda d:d.rounded_rectangle((2,8,36,52),6,fill=255),form='cyl'); S.rect('steel',6,2,28,8); S.rect('black',4,52,6,8); S.rect('black',28,52,6,8); S.rect('steel',12,0,10,3)
S.poly('blue',[(19,20),(12,32),(26,32)],edge=False); S.ell('blue',12,26,26,40,edge=False); S.rect_px(hx('#a0d8ff'),15,30,2,4); S.rect('steel',36,20,4,30); S.rect('yellow',35,26,6,3); done('Tank_Steel',S,'stand')
S=Spr(44,44,66); S.part('blue',lambda d:d.rounded_rectangle((1,6,42,40),6,fill=255),form='cyl'); S.rect('steel',4,3,36,5); S.rect_px(MAT['blue'][3],2,20,40,1); S.rect_px(MAT['blue'][3],2,30,40,1); S.rect('black',4,40,8,4); S.rect('black',32,40,8,4); done('Tank_Blue',S,'stand')
S=Spr(54,60,67); S.rect('black',0,54,54,6)
for i,x in enumerate((3,20,37)):
    S.part('blue',lambda d,x=x:d.rounded_rectangle((x,8,x+12,52),4,fill=255),form='cyl'); S.rect('steel',x-1,4,14,6); S.rect('steel',x-1,50,14,5); S.rect_px(hx('#a0d8ff'),x+3,14,2,30)
S.rect('steel',0,0,54,3); S.rect('steel',0,0,3,58); S.rect('steel',51,0,3,58); S.rect('yellow',0,26,54,3) if False else None; done('Filters_Blue',S,'stand')
S=Spr(52,52,68); S.rect('black',0,44,52,8); S.rect('steel',2,4,48,42,edge=False); S.rect_px(hx('#a8bcd0'),3,5,46,40)
for x in range(3,49,6): S.rect_px(ST[2],x,5,1,40)
for y in range(5,45,6): S.rect_px(ST[2],3,y,46,1)
S.rect('paper',10,10,32,28,noise=.02); S.poly('blue',[(26,14),(20,24),(32,24)],edge=False); S.ell('blue',20,20,32,32,edge=False); S.rect_px(hx('#a0d8ff'),23,22,2,4); done('Tote_Ibc',S,'stand')
S=Spr(64,60,69); S.part('steel',lambda d:d.rounded_rectangle((2,4,22,56),5,fill=255),form='cyl'); S.part('steel',lambda d:d.rounded_rectangle((26,12,44,56),5,fill=255),form='cyl'); S.part('blue',lambda d:d.rounded_rectangle((40,30,62,56),5,fill=255),form='cyl')
S.line('yellow',22,14,26,14,w=3); S.line('steel',44,20,58,20,w=3); S.line('steel',58,20,58,32,w=3)
for x,y in ((22,28),(45,40),(24,50)): S.rect('yellow',x,y,5,4)
S.rect_px(hx('#a0d8ff'),6,10,2,40); S.rect_px(hx('#a0d8ff'),30,18,2,30); S.rect('black',0,56,64,4); done('Plant_Filtration',S,'stand')
S=Spr(52,48,70); S.rect('black',0,42,52,6)
S.line('yellow',4,14,44,14,w=3); S.line('yellow',10,14,10,38,w=3); S.line('steel',4,26,48,26,w=3); S.line('steel',36,14,36,38,w=3); S.line('yellow',4,36,30,36,w=3)
S.rect('steel',14,18,18,14); S.rect('black',16,20,14,6,edge=False); S.rect_px(LG,18,22,8,1); S.rect('red',40,10,6,6); S.rect('red',3,32,5,5); S.rect('steel',30,30,10,10); done('Pump_Skid',S,'stand')
# ---------- sacks, crates, drums
def sacks(name,top,rows):
    S=Spr(44,46,71); S.rect('wood',0,38,44,8)
    for i in range(4): S.rect_px(BL[3],2+i*11,42,8,3)
    for r in range(rows):
        y=34-r*7
        for k in range(2 if r%2 else 3):
            x=2+k*13+(6 if r%2 else 0); S.part(top if r==rows-1 and top else 'sack',lambda d,x=x,y=y:d.rounded_rectangle((x,y,x+14,y+8),3,fill=255),noise=.05)
            S.rect_px(MAT['sack'][3],x+3,y+3,8,1) if not (r==rows-1 and top) else None
    done(name,S,'stand')
sacks('Sacks_Pallet',None,4); sacks('Sacks_PalletGreen','green',5)
S=Spr(50,46,72); S.rect('wood',0,38,50,8)
for x,y in ((1,10),(26,12)): S.rect('yellow',x,y,23,28); S.rect_px(YEL[3],x,y+7,23,1); S.rect('black',x+7,y+11,9,3); S.rect('black',x+2,y+22,19,2)
done('Crates_YellowPallet',S,'stand')
S=Spr(40,54,73); S.rect('black',2,26,36,26); S.rect('black',2,2,36,24); S.rect_px(BL[3],3,3,34,1)
for y in (2,26):
    S.line('steel',6,y+4,34,y+20,w=1) if False else None; S.rect_px(BL[0],5,y+3,30,1); S.rect('steel',6,y+8,3,10); S.rect('steel',31,y+8,3,10)
S.rect_px(BL[0],3,26,34,1); done('Cases_DarkStack',S,'stand')
S=Spr(38,34,74)
for x,m in ((0,'blue'),(19,'orange')): S.part(m,lambda d,x=x:d.rounded_rectangle((x,2,x+17,32),3,fill=255),form='cyl'); S.rect('black',x+1,0,15,3,edge=False); S.rect_px(MAT[m][3],x+1,10,16,1); S.rect_px(MAT[m][3],x+1,22,16,1)
S.rect_px(hx('#e8e4d8'),20,13,14,7); done('Drums_Pair',S,'stand')
# ---------- lab / shop
S=Spr(68,40,75); S.rect('conc',0,10,68,4); S.rect('black',2,14,64,26,edge=False); S.rect_px(hx('#20242c'),2,14,64,26)
for x in (3,35): S.rect('black',x,16,30,22,edge=True); S.rect('steel',x+11,26,8,2)
S.rect('black',10,0,16,10); S.rect_px(hx('#0a2210'),12,2,12,6); leaf_logo(S,18,5,6,LG); S.rect('steel',15,10,6,2); S.rect('black',30,8,14,3)
S.rect('blue',48,3,5,8); S.rect('paper',55,4,4,7); S.rect('leaf',60,3,6,7); done('LabBench',S,'stand')
def stool(name,m):
    S=Spr(14,20,76); S.ell(m,1,0,12,5); S.line('black',7,5,7,16,w=2); S.line('black',7,15,2,19,w=1); S.line('black',7,15,12,19,w=1); done(name,S,'stand')
stool('Stool_Brown','wood'); stool('Stool_Red','red')
S,ys=(lambda:None,None) if False else (None,None)
def shelf(w,h,n=3):
    S=Spr(w,h,20); S.rect_px(hx('#0f1116'),3,2,w-6,h-6)
    for x in (0,w-3): S.rect('black',x,0,3,h-2)
    ys=[]
    for i in range(n): y=int((h-6)*(i+1)/n); S.rect('black',0,y,w,3); S.rect_px(BL[0],0,y,w,1); ys.append(y)
    S.rect('black',0,0,w,2); wheels(S,(4,w-5),h-4,2); return S,ys
S,ys=shelf(46,56)
for i,y in enumerate(ys):
    for k,(m,bw,bh) in enumerate((('blue',5,9),('paper',5,7),('green',6,10),('yellow',5,8),('blue',5,7),('paper',6,10))):
        if (i+k)%4!=3: x=6+k*6; S.rect(m,x,y-bh,bw,bh); S.rect('black',x+1,y-bh-2,bw-2,2,edge=False) if bh>8 else None
done('Shelf_Lab',S,'stand')
S=Spr(34,44,77); S.rect('black',0,18,34,3); S.rect('black',2,21,3,20); S.rect('black',29,21,3,20); S.rect('black',0,34,34,3); wheels(S,(6,28),38,3)
S.rect('black',5,2,24,14); S.rect_px(hx('#0a2030'),7,4,20,10); leaf_logo(S,17,9,7,hx('#5af0d0')); S.rect('yellow',5,24,10,8); S.rect('paper',18,24,10,8); done('Cart_Monitor',S,'stand')
S=Spr(48,52,78) # forklift
S.rect('black',30,2,4,44); S.rect('black',36,2,3,44); S.rect('black',32,44,14,3); S.rect('black',34,40,14,2)
S.rect('yellow',4,26,28,16); S.rect('yellow',6,20,14,8); S.rect('black',6,4,2,22); S.rect('black',20,4,2,22); S.rect('black',6,4,16,2); S.rect('black',9,16,8,6,edge=False)
S.rect('black',4,40,28,3); S.ell('black',2,38,14,50); S.ell('black',22,38,34,50); S.dot(8,44,ST[1]); S.dot(28,44,ST[1]); done('Forklift',S,'stand')
S=Spr(28,44,79)
for x0,x1 in ((3,9),(25,19)): S.line('yellow',x0,2,x1 if False else x0-2 if x0<10 else x0+2,42,w=3)
S.rect('yellow',6,2,16,4)
for y in (12,20,28,36): S.rect('yellow',4-(y//14),y,20+2*(y//14),2)
done('Ladder_Yellow',S,'stand')
S=Spr(16,20,80); S.poly('orange',[(8,1),(4,17),(12,17)]); S.rect('black',1,17,14,3); S.rect_px(hx('#f0f0e8'),6,6,4,2); S.rect_px(hx('#f0f0e8'),5,11,6,2); done('Cone',S,'stand')
S=Spr(26,16,81); S.ell('green',0,4,25,15); S.ell('black',5,6,20,13,edge=False); S.ell('green',8,7,17,12); S.rect('green',18,0,7,5); done('Hose_Coil',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
