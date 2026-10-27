import sys; sys.path.insert(0,'.')
from trace import *
import lib, os, json, io, struct, zlib, math
import px
MAT=lib.MAT
for k,v in {'olive':'#8a9a64 #66744a #4c5836 #343e24 #1e2614','conc':'#d0d4d8 #a8aeb4 #848a92 #5c626a #3c4048','cork':'#d8a468 #b8804a #94602c #6c4420 #442a12','iron':'#7a8088 #4e545c #383d44 #262a30 #16181c','rusty':'#b0784a #85532e #613a1e #42260f #28160a','verd':'#6aa088 #487a66 #345c4c #223e34 #142620','sew':'#a0ffe0 #40c8a0 #28987c #186858 #0c3c34','brick':'#9a8a70 #756650 #564a38 #3a3126 #241e16','moss':'#7ab050 #4a8a34 #326a26 #204a1c #102c10','pump':'#4a9a90 #2e7068 #1f544e #143a36 #0a2422','orange':'#f8a860 #e07a28 #b05a18 #7c3c0c #4a2206','blue':'#5a86d0 #2e5aa8 #204486 #16305e #0c1c3a','rust':'#d89058 #b06a38 #86481e #5c300e #381c08','navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022','amber':'#fff2b8 #ffd468 #e2a624 #a26e12 #60400a','cool':'#ffffff #e8f4ff #c8dcf0 #90a8c0 #5a6c80'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); GR=MAT['glow']; BL=MAT['black']; ST=MAT['steel']
os.makedirs('out',exist_ok=True); OUTS={}; CODES='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
def done(name,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    n=len(OUTS); fn=('CUG' if n<36 else 'CUH')+CODES[n%36]
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
IR=MAT['iron']; RU=MAT['rusty']; VE=MAT['verd']; SW=MAT['sew']; MO=MAT['moss']; PA=MAT['paper']
W_=PA[0]
def bigt(S,x,y,t,c,k=2,sp=1):
    T_=Spr(len(t)*(3+sp),5,1); T_.text(0,0,t,(255,255,255,255),sp); im=T_.im.resize((T_.w*k,T_.h*k),Image.NEAREST); p=im.load()
    for j in range(im.height):
        for i in range(im.width):
            if p[i,j][3]>0: S.dot(x+i,y+j,c)
def plate(name,w,h,m,fn,kind='wall',seed=1):
    S=Spr(w,h,seed); S.rect(m,0,0,w,h,noise=.05); S.rect_px(MAT[m][4],0,h-1,w,1); S.rect_px(MAT[m][4],w-1,0,1,h); fn(S,w,h); done(name,S,kind)
def hp(S,x,y,w,h,m='iron'):
    S.rect(m,x,y,w,h,edge=True); S.rect_px(MAT[m][0],x,y+1,w,1); S.rect_px(MAT[m][4],x,y+h-2,w,1) if h>3 else None
def vp(S,x,y,w,h,m='iron'):
    S.rect(m,x,y,w,h,edge=True); S.rect_px(MAT[m][0],x+1,y,1,h); S.rect_px(MAT[m][4],x+w-2,y,1,h) if w>3 else None
def clamp(S,x,y,w,h,vert=False): S.rect('black',x,y,w,h,edge=True)
RED=MAT['red']
def wheel(S,cx,cy,r):
    for a in range(0,360,3): S.dot(cx+round(r*math.cos(math.radians(a))),cy+round(r*math.sin(math.radians(a))),RED[1]); S.dot(cx+round((r-1)*math.cos(math.radians(a))),cy+round((r-1)*math.sin(math.radians(a))),RED[2])
    for a in range(0,360,45): S.line('red',cx,cy,cx+round(r*math.cos(math.radians(a))),cy+round(r*math.sin(math.radians(a))),w=1)
    S.rect('red',cx-1,cy-1,3,3)
# ---- signs
def f_b1(S,w,h): bigt(S,5,12,'B1',BL[3],4); 
plate('Plate_B1',40,40,'conc',f_b1)
def f_sewer(S,w,h): bigt(S,6,7,'SEWER',MAT['paper'][1],2); bigt(S,6,18,'ACCESS',MAT['paper'][1],2) if False else None; ctext(S,w//2,20,'ACCESS',MAT['paper'][1]); arrow(S,w//2-3,28,c=MAT['paper'][1],left=True)
plate('Sign_SewerAccess',48,38,'black',f_sewer)
def f_wet(S,w,h):
    ctext(S,w//2,4,'CAUTION',BL[3]); S.rect_px(BL[3],2,3,w-4,1) if False else None
    S.rect_px(BL[3],w//2-1,14,3,3); S.line('black',w//2,17,w//2-4,26,w=3); S.line('black',w//2,18,w//2+6,22,w=2); S.line('black',w//2-4,26,w//2-8,32,w=2); S.line('black',w//2-4,26,w//2+2,33,w=2); ctext(S,w//2,h-8,'WET FLOOR',BL[3])
plate('Sign_CautionWet',40,52,'yellow',f_wet)
def f_conf(S,w,h):
    ctext(S,w//2,4,'DANGER',BL[3])
    for k in range(3):
        a=math.radians(90+k*120+180); cx=w//2+round(8*math.cos(a)); cy=22+round(8*math.sin(a)); circ(S,cx,cy,5,BL[3]); circ(S,cx,cy,4,BL[3])
    circ(S,w//2,22,2,BL[3]); ctext(S,w//2,h-14,'CONFINED',BL[3]); ctext(S,w//2,h-8,'SPACE',BL[3])
plate('Sign_DangerConfined',40,54,'yellow',f_conf)
def f_hp(S,w,h):
    ctext(S,w//2,4,'HIGH',PA[0]); ctext(S,w//2,11,'PRESSURE',PA[0]); wheel(S,w//2,30,7); S.rect_px(PA[0],w//2-1,20,3,3) if False else None; S.rect_px(hx('#ffd0d0'),w//2,37,1,6); S.rect_px(hx('#ffd0d0'),w//2-5,40,11,1)
plate('Sign_HighPressure',38,50,'red',f_hp)
def f_no(S,w,h):
    S.ell('red',5,5,w-6,w-6,edge=False); S.rect_px(PA[0],10,w//2-2,w-20,5); ctext(S,w//2,w+3,'NO',RED[2]); ctext(S,w//2,w+10,'ENTRY',RED[2])
plate('Sign_NoEntry',34,52,'paper',f_no)
def f_wc(S,w,h):
    S.poly('green',[(w//2,5),(w//2-7,16),(w//2+7,16)],edge=False); S.ell('green',w//2-7,11,w//2+7,25,edge=False); S.rect_px(hx('#d0ffd8'),w//2-3,14,2,4)
    ctext(S,w//2,28,'KEEP',GRN[3] if False else BL[3]); ctext(S,w//2,35,'WATER',BL[3]); ctext(S,w//2,42,'CLEAN',BL[3])
GRN=MAT['green']; plate('Sign_KeepWaterClean',34,52,'paper',f_wc)
def f_fl(S,w,h):
    for k,y in enumerate((6,13,20)):
        for x in range(4,w-4): S.dot(x,y+round(2*math.sin((x+k*3)/2.2)),hx('#e0f0ff')); S.dot(x,y+1+round(2*math.sin((x+k*3)/2.2)),hx('#a8d0f0'))
    ctext(S,w//2,32,'FLOOD',PA[0]); ctext(S,w//2,39,'CONTROL',PA[0])
plate('Sign_FloodControl',36,50,'navy',f_fl)
def f_mt(S,w,h):
    S.rect_px(MAT['red'][2],2,2,w-4,10); ctext(S,w//2,5,'MAINTENANCE',hx('#ffe0d8')) if False else None
    S.rect('red',3,3,w-6,9,edge=False); ctext(S,w//2,5,'MAINTENANCE',PA[0]); ctext(S,w//2,16,'AUTHORIZED',BL[3]); ctext(S,w//2,23,'PERSONNEL ONLY',BL[3]); S.poly('red',[(w//2,30),(w//2-4,37),(w//2+4,37)],edge=False)
plate('Sign_MaintenanceOnly',62,42,'cream',f_mt)
def f_ex(S,w,h):
    S.rect_px(hx('#0a2a14'),2,2,w-4,h-4); S.rect_px(PA[0],10,6,3,3); S.line('paper',11,10,10,16,w=2); S.line('paper',11,11,16,14,w=1); S.line('paper',10,16,6,20,w=1); S.line('paper',10,16,14,20,w=1)
    bigt(S,20,5,'EXIT',PA[0],2); arrow(S,w-11,8,c=PA[0])
plate('Sign_ExitGreen',66,26,'green',f_ex)
def f_pump(S,w,h): ctext(S,w//2,6,'PUMP',BL[3]); ctext(S,w//2,14,'STATION',BL[3]); bigt(S,w//2-6,26,'B',BL[3],3,0)
plate('Sign_PumpStationB',36,52,'rusty',f_pump)
def f_mt2(S,w,h): bigt(S,6,6,'MAIN',MAT['paper'][1],2); bigt(S,6,17,'TUNNEL',MAT['paper'][1],2) if False else None; ctext(S,w//2-4,20,'TUNNEL',MAT['paper'][1]); arrow(S,w-14,8,c=MAT['paper'][1])
plate('Sign_MainTunnel',56,34,'black',f_mt2)
# ---- openings / fixtures
S=Spr(36,36,2); S.part('iron',lambda d:d.ellipse((0,0,35,35),fill=255),form=None); S.ell('conc',1,1,34,34,edge=True) if False else None; S.ell('black',4,4,31,31,edge=False); circ(S,18,18,17,IR[0])
for x in range(9,28,4): S.rect_px(IR[2],x,6,2,24)
S.rect_px(IR[0],10,6,1,24) if False else None; done('Grate_Round',S,'wall')
S=Spr(38,58,3); S.part('iron',lambda d:d.ellipse((0,0,37,37),fill=255),form=None); S.ell('black',4,4,33,33,edge=False)
rr=random.Random(2)
for x in range(6,32,2): 
    h=rr.randrange(20,54); S.rect_px(SW[1] if x%4 else SW[0],x,20,2,h-18); S.rect_px(SW[3],x+1,22,1,h-24)
S.rect_px(SW[3],5,20,28,3); done('Outfall_Pipe',S,'wall')
S=Spr(46,42,4); S.poly('brick',[(0,42),(0,20),(6,9),(16,3),(29,3),(39,9),(46,20),(46,42)])
S.poly('black',[(8,42),(8,22),(13,14),(20,9),(26,9),(33,14),(38,22),(38,42)],edge=False)
for y in range(6,42,5):
    for x in range(0,46,7): S.rect_px(MAT['brick'][3],x+((y//5)%2)*3,y,1,4); 
    S.rect_px(MAT['brick'][3],0,y,46,1)
S.rect('black',8,20,30,22,edge=False)
for x in range(9,37,3): rr=random.Random(x); S.rect_px(MO[2],x,rr.randrange(10,16),2,rr.randrange(6,20))
S.rect_px(SW[2],8,38,30,4); done('Tunnel_Arch',S,'wall')
def dripwall(name,w,h,kind):
    S=Spr(w,h,5)
    if kind=='s': hp(S,0,0,w,8); clamp(S,4,0,3,8); clamp(S,w-8,0,3,8)
    if kind=='e': hp(S,0,0,w-8,8); vp(S,w-16,0,8,14); clamp(S,3,0,3,8); S.ell('steel',w-14,-1,w-8,7) if False else None
    if kind=='g': hp(S,0,0,w-10,8); vp(S,w-18,0,8,14); S.ell('paper',w-14,15,w-4,25,edge=False); circ(S,w-9,20,3,BL[3]) 
    if kind=='t': vp(S,w//2-4,0,8,14)
    x=(w//2-1) if kind!='e' else w-14
    for y in range(12 if kind in 'et' else 8,h-8): S.rect_px(SW[1],x,y,2,1); S.rect_px(SW[0],x,y,1,1) if y%3 else None
    S.ell('sew',x-8,h-7,x+9,h-1,edge=False); S.rect_px(SW[0],x-3,h-5,6,1); done(name,S,'wall')
dripwall('Drip_Pipe_Straight',36,44,'s'); dripwall('Drip_Pipe_Elbow',36,44,'e'); dripwall('Drip_Pipe_Gauge',40,46,'g'); dripwall('Drip_Pipe_Short',20,46,'t')
def valve(name,w,h,kind):
    S=Spr(w,h,6)
    if kind=='body':
        S.part('iron',lambda d:d.rounded_rectangle((18,4,w-3,h-3),5,fill=255)); hp(S,0,h//2-4,20,8); wheel(S,13,h//2-1,11); S.rect('black',w-12,h//2-3,4,6)
    if kind=='v':
        vp(S,w//2-4,0,8,h); wheel(S,w//2,h//2,9); clamp(S,w//2-5,6,10,3); clamp(S,w//2-5,h-10,10,3)
    if kind=='g':
        vp(S,4,0,8,h); wheel(S,8,h//2+8,8); vp(S,w-9,10,4,h-10,'steel'); S.ell('steel',w-14,2,w-2,14); S.ell('paper',w-12,4,w-4,12,edge=False); S.line('red',w-8,8,w-6,5,w=1)
        S.rect_px(BL[3],w-9,7,1,2)
    done(name,S,'wall')
valve('Valve_Body',46,46,'body'); valve('Valve_Vertical',26,52,'v'); valve('Valve_Gauge',32,62,'g')
S=Spr(28,42,7); vp(S,11,14,6,26); S.rect('black',6,38,16,4); wheel(S,14,10,9); S.rect('black',11,18,6,4) if False else None; done('Valve_Post',S,'stand')
# lamps
def cage(name,m,w,h,hang=True,wall=False):
    S=Spr(w,h,8); top=6 if hang else 0
    if hang: S.rect_px(BL[2],w//2,0,1,4); S.rect('black',w//2-3,3,6,4)
    S.part(m,lambda d:d.rounded_rectangle((2,top+2,w-3,h-6),w//2-2,fill=255),form='cyl',edge=False); S.rect_px(MAT[m][0],w//2-1,top+5,2,(h-top)//2-2)
    for y in range(top+4,h-7,4): S.rect_px(BL[2],2,y,w-4,1)
    S.rect_px(BL[2],w//2,top+2,1,h-top-8); S.rect('black',3,h-6,w-6,5); S.rect_px(BL[3],w//2-1,h-1,2,1); done(name,S,'stand' if hang else 'wall')
cage('Lamp_CageAmber','amber',18,34); cage('Lamp_CageRed','red',18,34); cage('Lamp_CageSmall','amber',16,26,hang=False); cage('Lamp_CageSmallRed','red',14,24,hang=False)
S=Spr(34,30,9); S.rect_px(BL[2],16,0,1,6); S.rect('black',14,5,5,4); S.poly('iron',[(4,22),(13,8),(20,8),(29,22)]); S.rect_px(IR[0],14,9,3,11); S.rect('amber',5,22,24,4,noise=0,edge=False); S.rect_px(MAT['amber'][0],9,23,16,2); done('Lamp_Industrial',S,'stand')
S=Spr(14,32,10); S.rect('iron',3,0,8,32); S.rect('black',1,10,12,10) if False else None; S.rect('amber',3,4,8,10,noise=0,edge=False); S.rect_px(MAT['amber'][0],5,5,2,7); S.rect('black',3,14,8,2); done('Lamp_Bollard',S,'wall')
# ---- standing set
S=Spr(24,36,11); S.part('orange',lambda d:d.rounded_rectangle((1,3,22,35),4,fill=255),form='cyl')
for y in (10,20): S.rect_px(hx('#c8ccd0'),1,y,22,5); S.rect_px(hx('#8a9098'),1,y+4,22,1)
S.rect('black',2,0,20,4,edge=False); S.rect('black',1,32,22,4); done('Barrel_Hazard',S,'stand')
S=Spr(18,24,12); S.poly('orange',[(9,1),(4,20),(14,20)]); S.rect_px(hx('#f0f0e8'),7,7,4,3); S.rect_px(hx('#f0f0e8'),5,13,8,3); S.rect('black',1,20,16,4); done('Cone_Orange',S,'stand')
S=Spr(60,34,13); 
for x in (2,54): S.rect('yellow',x,4,4,30); S.rect('yellow',x-1,2,6,3)
S.rect('yellow',2,8,56,4); S.rect('yellow',2,18,56,4)
S.rect_px(hx('#8a6408'),2,12,56,1); S.rect_px(hx('#8a6408'),2,22,56,1); done('Railing_Yellow',S,'stand')
S=Spr(66,40,14); S.rect('black',0,0,4,40); S.rect('black',62,0,4,40); S.rect('black',0,0,66,3); S.rect('black',0,37,66,3)
for x in range(6,62,3): S.rect_px(hx('#a8b0b8') if x%6 else hx('#788088'),x,4,1,33)
for y in range(5,36,3): S.rect_px(hx('#8a9098'),4,y,58,1)
S.rect('paper',16,10,34,20,edge=False); S.rect_px(MAT['red'][1],16,10,34,1); S.rect_px(MAT['red'][1],16,29,34,1); S.rect('red',18,12,30,7,edge=False); ctext(S,33,13,'DANGER',PA[0]); ctext(S,33,21,'KEEP OUT',BL[3]); done('Fence_DangerKeepOut',S,'stand')
S=Spr(14,30,15); S.rect('black',0,0,14,30); S.rect('iron',2,2,10,26,edge=False); S.rect_px(IR[3],2,2,10,26); S.rect_px(hx('#3ab060'),4,6,5,5); S.rect_px(hx('#a0ffb0'),5,7,2,2); S.rect_px(hx('#e04030'),4,16,5,5); S.rect_px(hx('#ff9080'),5,17,2,2); done('Switch_Box',S,'wall')
S=Spr(16,26,16); S.rect('black',0,0,16,26); S.rect_px(BL[3],2,2,12,22); S.rect_px(hx('#a8c0d0'),5,6,6,2); done('Box_Small',S,'wall')
S=Spr(26,42,17); S.rect('conc',0,0,26,42); S.rect('steel',2,2,22,38,edge=True); S.rect('black',4,4,18,34,edge=False)
for i,c in enumerate((RED[1],hx('#f0d030'),hx('#3ab060'),hx('#3a90e8'),RED[1],hx('#f0d030'))):
    S.rect_px(c,5,8+i*5,16,1); S.rect_px(BL[0],5+(i*3)%12,7+i*5,3,3)
S.rect_px(GR[1],6,5,3,1); done('Panel_Open',S,'wall')
S=Spr(66,42,18); S.rect('iron',0,32,66,10) if False else None; S.rect('black',2,34,62,8,edge=True)
S.part('pump',lambda d:d.rounded_rectangle((14,6,54,32),8,fill=255),form='cyl'); S.rect('pump',4,14,12,14); S.rect('black',54,16,10,6); S.rect('pump',26,0,14,8); S.rect_px(MAT['pump'][3],16,14,38,1); S.rect_px(MAT['pump'][3],16,24,38,1)
S.rect('iron',0,20,6,14); S.ell('iron',0,28,12,40) if False else None; S.rect_px(hx('#e8a020'),44,12,3,3); done('Pump_Motor',S,'stand')
def crate(name,w,h,m,x_=False):
    S=Spr(w,h,19); S.rect(m,0,0,w,h)
    for y in (h//3,2*h//3): S.rect_px(MAT[m][4],0,y,w,1)
    S.rect('wood',0,0,4,h) if False else None; S.rect_px(MAT[m][3],3,0,1,h); S.rect_px(MAT[m][3],w-4,0,1,h); S.line('wood',4,4,w-5,h-5,w=2); S.line('wood',w-5,4,4,h-5,w=2) if x_ else None
    done(name,S,'stand')
crate('Crate_Wood',42,32,'wood',True)
def case(name,w,h,m):
    S=Spr(w,h,20); S.rect(m,0,3,w,h-3); S.rect_px(MAT[m][4],0,h//2,w,1); S.rect('black',w//2-5,0,10,4); S.rect('steel',5,h//2-2,4,5); S.rect('steel',w-9,h//2-2,4,5)
    for x,y in ((0,3),(w-4,3),(0,h-4),(w-4,h-4)): S.rect('black',x,y,4,4,edge=False)
    done(name,S,'stand')
case('Case_GreenA',34,28,'olive'); case('Case_GreenB',36,26,'olive'); case('Case_Blue',48,30,'navy')
S=Spr(46,22,21); S.rect('wood',0,0,46,4); S.rect('wood',0,9,46,4); S.rect('wood',0,18,46,4)
for x in (2,20,38): S.rect('woodd' if False else 'wood',x,4,6,5); S.rect('wood',x,13,6,5)
S.rect_px(MAT['wood'][4],0,4,46,1); S.rect_px(MAT['wood'][4],0,13,46,1); done('Pallet_Wood',S,'stand')
S=Spr(26,68,22); vp(S,1,0,3,68,'wood'); vp(S,22,0,3,68,'wood')
for y in range(6,64,10): S.rect('wood',3,y,20,3)
done('Ladder_Wood',S,'stand')
S=Spr(42,42,23); S.rect('iron',0,0,42,42); S.rect('black',4,4,34,34,edge=False)
for x in range(8,36,5): S.rect_px(IR[2],x,4,2,34)
for y in range(8,36,5): S.rect_px(IR[2],4,y,34,2)
S.rect_px(IR[0],1,1,40,1); done('Vent_GrateSq',S,'wall')
S=Spr(46,22,24); S.rect('rusty',0,0,46,22); S.rect('black',3,3,40,16,edge=False)
for x in range(6,42,4): S.rect_px(RU[2],x,3,2,16)
done('Grate_Rusty',S,'wall')
# ---- moss drapes
def moss(name,w,hmax,seed):
    S=Spr(w,hmax+6,25); rr=random.Random(seed)
    S.rect('moss',0,0,w,6)
    x=1
    while x<w-1:
        cw=rr.choice((2,3,3,4)); ln=rr.randrange(hmax//3,hmax); S.rect('moss',x,4,cw,ln+2,edge=False); S.rect_px(MO[3],x+cw-1,6,1,ln); S.rect_px(MO[0],x,6,1,ln//2)
        x+=cw+rr.randrange(0,3)
    done(name,S,'wall')
moss('Moss_A',22,30,1); moss('Moss_B',34,34,2); moss('Moss_C',26,36,3); moss('Moss_D',40,32,4); moss('Moss_E',24,22,5); moss('Moss_F',50,28,6)
# ---- water fx
def dripfx(name,h,seed):
    S=Spr(14,h,26); rr=random.Random(seed); cx=7
    for y in range(0,h-6): S.rect_px(SW[1],cx,y,2,1); 
    S.rect_px(SW[0],cx,0,1,h-6)
    S.ell('sew',0,h-6,13,h-1,edge=False); S.rect_px(SW[0],4,h-4,5,1); done(name,S,'stand')
dripfx('Drip_A',34,1); dripfx('Drip_B',26,2); dripfx('Drip_C',20,3)
def splash(name,w,h,seed):
    S=Spr(w,h,27); rr=random.Random(seed)
    S.ell('sew',0,h-8,w-1,h-1,edge=False)
    for i in range(w//2):
        a=rr.uniform(-2.6,-.5); r=rr.randrange(3,h-6); x=w//2+round(r*math.cos(a)*1.4); y=h-6+round(r*math.sin(a))
        S.dot(x,y,SW[0]); S.dot(x,y+1,SW[1])
    done(name,S,'stand')
splash('Splash_Small',26,20,1); splash('Splash_Large',44,28,2)
# ---- debris
S=Spr(10,12,28); S.rect('steel',0,0,10,12); S.rect_px(ST[4],0,3,10,1); S.rect_px(ST[4],0,8,10,1); done('Can',S,'stand')
S=Spr(20,9,29); S.part('green',lambda d:d.rounded_rectangle((0,2,13,8),3,fill=255),edge=True); S.rect('green',12,4,7,3); S.rect_px(hx('#e8e0c0'),4,4,5,3); done('Bottle',S,'stand')
S=Spr(26,12,30)
for x,y,w,h in ((0,5,9,6),(8,2,10,9),(17,6,8,5)): S.ell('conc',x,y,x+w,y+h)
done('Rocks_Small',S,'stand')
S=Spr(30,20,31); S.poly('conc',[(0,18),(3,8),(10,2),(20,4),(28,10),(29,19)]); S.rect_px(MAT['conc'][3],8,10,10,1); done('Rock_Big',S,'stand')
S=Spr(28,32,32); S.part('bag',lambda d:d.polygon([(3,31),(1,20),(6,10),(11,4),(15,0),(17,4),(23,10),(27,20),(25,31)],fill=255),form='cyl'); S.rect_px(MAT['bag'][0],9,10,2,8); S.rect('bag',11,0,6,6); done('Trash_Bag',S,'stand')
# ---- pipes
def elbow(name,m,kind,w=34,h=34):
    S=Spr(w,h,33); t=10
    if kind in ('e','g','b'):
        hp(S,0,h-t-6,w-6,t,m); vp(S,w-t-4,0,t,h-6,m) ; S.rect(m,w-t-6,h-t-8,t+4,t+4)
        clamp(S,5,h-t-7,3,t+2); clamp(S,w-t-5,5,t+2,3)
    if kind=='t':
        hp(S,0,h//2-5,w,t,m); vp(S,w//2-5,0,t,h//2,m); S.rect(m,w//2-7,h//2-7,t+4,t+4); clamp(S,4,h//2-6,3,t+2); clamp(S,w-8,h//2-6,3,t+2)
    if kind=='b': S.rect('black',w-t-4,4,t+2,3) if False else None
    done(name,S,'wall')
elbow('Pipe_ElbowIron','iron','e'); elbow('Pipe_ElbowRust','rusty','e'); elbow('Pipe_ElbowVerd','verd','g'); elbow('Pipe_TeeIron','iron','t',40,34); elbow('Pipe_ElbowBig','iron','b',40,40)
S=Spr(88,28,34); hp(S,0,2,88,11); hp(S,0,15,88,11)
for x in (12,38,64): clamp(S,x,0,4,28)
done('Pipe_DoubleLong',S,'wall')
S=Spr(84,16,35); hp(S,0,2,84,12,'iron'); 
for x in (8,40,74): clamp(S,x,0,4,16)
done('Pipe_LongIron',S,'wall')
S=Spr(56,70,36)
for x in (4,20,36): vp(S,x,0,10,56); clamp(S,x-1,10,12,3); clamp(S,x-1,40,12,3)
hp(S,0,50,56,10); clamp(S,8,49,3,12); clamp(S,44,49,3,12); wheel(S,49,20,7) if False else None; wheel(S,26,30,9); 
done('Pipe_Stack',S,'wall')
json.dump(OUTS,open('out/manifest.json','w'))
ims=[(n,Image.open(f'out/{v[3]}A0.png').convert('RGBA')) for n,v in OUTS.items()]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1600),(58,58,66,255))
for n,im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
