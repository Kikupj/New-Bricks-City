import sys; sys.path.insert(0,'.')
import sys
from trace import *
import lib, os, json, io, struct, zlib
import px
MAT=lib.MAT
for k,v in {'teal':'#5aaaa6 #2e7c7c #205c5c #163e40 #0e2828','navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022',
 'ivbag':'#e0f4ff #b0d8f0 #80acd0 #4c7ca4 #2a4a6c','ocean':'#8ab8f4 #4682d0 #2e60a8 #1e4078 #12264c',
 'amber':'#fff2b8 #ffd468 #e2a624 #a26e12 #60400a','cool':'#ffffff #e8f4ff #c8dcf0 #90a8c0 #5a6c80'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); INKC=MAT['black'][3]
os.makedirs('out',exist_ok=True); OUTS={}
def done(code,cls,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    W,H=S.w,S.h; ox,oy=(W//2,H//2) if kind=='wall' else (W//2,H)
    b=io.BytesIO(); S.im.save(b,'PNG'); d=b.getvalue(); ch=lambda t,x:struct.pack('>I',len(x))+t+x+struct.pack('>I',zlib.crc32(t+x)&0xffffffff)
    fn=('CCG'+code.upper()) if code.islower() else 'CCF'+code
    open(f'out/{fn}A0.png','wb').write(d[:33]+ch(b'grAb',struct.pack('>ii',ox,oy))+d[33:]); OUTS[code]=(cls,kind,W,H,fn)
def wheels(S,xs,y,r=3):
    for x in xs: S.ell('black',x-r,y,x+r,y+2*r); S.dot(x,y+r,MAT['steel'][1])
def ecg(S,x,y):
    for i,dy in enumerate((0,0,0,-4,3,-1,0,0,0,0,-2,0,0,0,0,0)): S.dot(x+i,y+dy,MAT['glow'][1])
def arrow(S,x,y,c=CREAM,left=False):
    rows=("00100","00010","11111","00010","00100")
    if left: rows=("00100","01000","11111","01000","00100")
    for j,row in enumerate(rows):
        for i,v in enumerate(row):
            if v=='1': S.dot(x+i,y+j,c)
def ctext(S,cx,y,t,c,sp=1): S.text(cx-(len(t)*(3+sp)-sp)//2,y,t,c,sp)


import math
def T(code,cls,box,h,kind,enh=(1.25,1.15,1.2),ncol=16,outline=False,key=None):
    img=trace(box,h,mode='color',ncol=ncol,enh=enh,key=key); done(code,cls,as_spr(img),kind,outline=outline)
for k,v in {'slate':'#4a8080 #2c5858 #1f4444 #153030 #0e2020','olive':'#8a9a64 #66744a #4c5836 #343e24 #1e2614','cork':'#d8a468 #b8804a #94602c #6c4420 #442a12'}.items(): MAT[k]=[hx(c) for c in v.split()]
BZ=MAT['black']; SCR=hx('#0a1428'); SCR2=hx('#0f1e3c'); B0=hx('#9ad0ff'); B1=hx('#4a90e8'); B2=hx('#2860b8'); B3=hx('#1a4088'); CY=hx('#5af0ff'); GR=MAT['glow']
def mon(w,h,seed=1,inner=hx('#0a1428')):
    S=Spr(w,h,seed); S.rect('black',0,0,w,h); S.rect_px(inner,3,3,w-6,h-6); S.rect_px(BZ[3],2,2,w-4,1); S.rect_px(BZ[4],3,h-3,w-6,1); return S
def circ(S,cx,cy,r,c,ry=None):
    ry=ry or r
    for a in range(0,360,3): S.dot(cx+round(r*math.cos(math.radians(a))),cy+round(ry*math.sin(math.radians(a))),c)
def globe(S,cx,cy,r):
    circ(S,cx,cy,r,B1)
    for rx in (r*.35,r*.7): circ(S,cx,cy,round(rx),B2,ry=r)
    for k in (-.6,-.3,0,.3,.6):
        y=cy+round(r*k); hw=round(math.sqrt(max(0,r*r-(r*k)**2)))
        for x in range(cx-hw,cx+hw+1): S.dot(x,y,B2)
    S.rect_px(B1,cx,cy-r,1,2*r+1)
def bars(S,x,y,hs,c,step=3):
    for i,hh in enumerate(hs): S.rect_px(c,x+i*step,y-hh,2,hh)
def screen_globe():
    S=mon(40,36,1); globe(S,20,18,12); S.text(5,5,'GLOBAL',B1); return S
def screen_blue():
    S=mon(40,36,2)
    for x in range(5,35,6): S.rect_px(B3,x,5,1,26)
    for y in range(5,31,6): S.rect_px(B3,5,y,30,1)
    S.rect_px(B1,7,7,12,10); S.rect_px(SCR2,8,8,10,8); S.rect_px(B1,22,7,12,4); S.rect_px(B1,22,13,12,4); S.rect_px(B1,7,20,26,1)
    for i in range(5): S.rect_px(B2,8,9+i*1 if i<3 else 12,6+i,1)
    for i in range(6): S.rect_px(B0,8+i*4,23+(i%2),2,1)
    circ(S,29,25,4,B0); return S
def screen_cctv():
    S=mon(56,40,3)
    for q,(x,y) in enumerate(((5,5),(29,5),(5,21),(29,21))):
        S.rect_px(hx('#182c50'),x,y,22,14)
        for i in range(30): S.dot(x+S.rnd.randrange(22),y+S.rnd.randrange(14),hx('#2c4478'))
        S.poly('black',[(x,y+14),(x+6,y+8),(x+12,y+11),(x+18,y+6),(x+22,y+14)],edge=False) if False else None
        for i in range(x,x+22): S.dot(i,y+9+((i//5)%3),hx('#0c1834'))
        S.text(x+1,y+8,'CAM %d'%(q+1),B0)
    S.rect_px(hx('#e04030'),50,4,2,2); return S
def screen_bio():
    S=mon(44,32,4); bars(S,5,25,(6,10,8,14,11,16,9),B1); S.rect_px(B2,5,26,20,1)
    S.rect_px(B1,5,5,14,2); S.rect_px(B2,5,8,10,1)
    cx=34; S.ell('navy',cx-3,4,cx+3,10,edge=False); S.rect_px(CY,cx-2,5,4,4); S.rect_px(CY,cx-5,11,10,9); S.rect_px(CY,cx-7,12,2,8); S.rect_px(CY,cx+5,12,2,8); S.rect_px(CY,cx-4,20,3,8); S.rect_px(CY,cx+1,20,3,8)
    S.rect_px(SCR2,cx-1,13,2,3); return S
def screen_term():
    S=mon(44,30,5)
    for i,l in enumerate((16,22,12,20,18,10,14)): S.rect_px(B2 if i%3 else B1,5,6+i*3,l,1)
    S.rect_px(hx('#6a1810'),34,6,8,17); S.poly('red',[(38,9),(35,17),(41,17)],edge=False); S.rect_px(hx('#ffd0c0'),38,12,1,3); return S
def screen_dash():
    S=mon(50,34,6)
    S.rect_px(SCR2,5,5,14,10); bars(S,7,13,(3,6,4,7),GR[1]); S.rect_px(SCR2,5,17,14,12); S.rect_px(B2,6,19,12,1); S.rect_px(B2,6,22,8,1); S.rect_px(B2,6,25,10,1)
    S.rect_px(SCR2,21,5,24,24); circ(S,33,17,10,B2); circ(S,33,17,6,B2); circ(S,33,17,2,B1)
    for i in range(10): S.dot(33+i,17-i//2,B0)
    S.dot(28,12,hx('#ff5040')); S.dot(38,21,hx('#ff5040')); S.dot(31,22,hx('#ffd040')); return S
def screen_radar_g():
    S=mon(32,26,7,inner=hx('#06160c')); 
    for r in (3,6,9): circ(S,16,13,r,GR[4]);
    S.rect_px(GR[4],16,3,1,20); S.rect_px(GR[4],6,13,21,1)
    for i in range(9): S.dot(16+i,13-i,GR[1])
    S.dot(11,9,GR[0]); S.dot(21,16,GR[0]); S.dot(14,18,GR[0]); return S
for code,cls,fn in (('B','Monitor_Globe',screen_globe),('C','Monitor_Blueprint',screen_blue),('D','Monitor_Cctv',screen_cctv),('E','Monitor_Biometric',screen_bio),('F','Monitor_Terminal',screen_term),('G','Monitor_Dashboard',screen_dash)):
    done(code,cls,fn(),'wall')
done('N','Monitor_RadarSmall',screen_radar_g(),'wall')
T('A','Wall_WorldMap',(680,30,915,255),54,'wall')
# desk monitors (on stand)
def deskmon(kind):
    S=Spr(38,34,8); S.rect('black',0,0,38,24); S.rect_px(hx('#0a1428') if kind!='r' else hx('#06160c'),2,2,34,19); S.rect_px(BZ[3],1,1,36,1)
    if kind=='w':
        m=trace((705,55,890,230),19,mode='color',ncol=8,enh=(1.2,1.3,1.2)); S.im.paste(m,(19-m.width//2,2),m); S.px=S.im.load()
    elif kind=='r':
        for r in (4,7,9): circ(S,19,11,r,GR[4])
        for i in range(9): S.dot(19+i,11-i,GR[1])
        S.dot(13,8,GR[0]); S.dot(24,14,GR[0])
    else:
        bars(S,6,18,(4,7,5,10,8,12,7,9,11),B1,step=3); S.rect_px(B2,5,19,28,1); S.text(6,4,'STATUS',B0)
    S.rect('black',15,24,8,4); S.rect('black',9,28,20,4); return S
for code,cls,k in (('O','DeskMonitor_World','w'),('P','DeskMonitor_Radar','r'),('Q','DeskMonitor_Status','s')): done(code,cls,deskmon(k),'stand',outline=True)
# whiteboard
S=Spr(86,58,9); S.rect('steel',0,0,86,58); S.rect('cool',3,3,80,48,noise=.01,edge=False); S.rect_px(MAT['cool'][3],3,50,80,1); S.rect('steel',10,51,66,4)
for x,c in ((14,'red'),(20,'navy'),(26,'green')): S.rect('paper',x,52,4,2,edge=False); S.rect_px(MAT[c][1],x,52,2,2)
INKB=MAT['navy'][2]; INKR=MAT['red'][1]
for i,(l,y) in enumerate(((22,8),(30,11),(18,14))): S.rect_px(INKB,8,y,l,1)
circ(S,58,16,8,INKB); circ(S,58,16,4,INKB); S.line('navy',8,30,26,42,w=1); S.line('navy',26,42,44,32,w=1); 
for x,y in ((8,30),(26,42),(44,32)): S.ell('navy',x-2,y-2,x+2,y+2,edge=False)
for i in range(14): S.dot(50+i,44-(i*i)//30,INKR)
S.rect('yellow',66,30,9,9); S.rect_px(MAT['yellow'][3],68,33,5,1); S.rect_px(MAT['yellow'][3],68,36,4,1); S.rect('paper',10,4,14,10,edge=True); S.rect_px(MAT['paper'][3],12,7,10,1); S.rect_px(MAT['paper'][3],12,10,7,1)
S.rect('red',3,14,1,1); done('H','Whiteboard',S,'wall')
# bulletin board
S=Spr(86,58,10); S.rect('wood',0,0,86,58); S.rect('cork',3,3,80,52,noise=.10)
notes=[(6,6,16,20,'paper'),(26,5,14,12,'yellow'),(44,7,18,14,'paper'),(66,6,14,18,'cream'),(8,30,18,14,'cream'),(30,22,20,18,'paper'),(56,26,12,10,'yellow'),(56,40,20,12,'paper'),(10,47,14,6,'yellow'),(30,44,20,8,'cream')]
for x,y,w,h,m in notes:
    S.rect(m,x,y,w,h,noise=.01)
    for yy in range(y+3,y+h-1,3): S.rect_px(MAT['paper'][3],x+2,yy,max(2,w-5-(yy%4)),1)
    S.rect_px(MAT['red'][1] if x%2 else MAT['navy'][1],x+w//2,y,2,2)
S.rect_px(INKR,32,26,14,1); S.rect_px(INKR,32,30,1,6); S.dot(45,26,INKR); done('I','BulletinBoard',S,'wall')
# alert + level plates
S=Spr(26,36,11); S.rect('red',0,0,26,36); S.rect_px(MAT['red'][4],2,2,22,32); S.rect_px(MAT['red'][2],3,3,20,30); S.text(4,5,'ALERT',hx('#ffd8c8'))
S.poly('red',[(13,14),(4,31),(22,31)],edge=False); S.poly('black',[(13,18),(7,29),(19,29)],edge=False); S.rect_px(hx('#ffb0a0'),12,21,2,5); S.rect_px(hx('#ffb0a0'),12,27,2,1); done('J','Sign_Alert',S,'wall')
def big(S,x,y,t,c,k=3):
    T_=Spr(len(t)*4,5,1); T_.text(0,0,t,(255,255,255,255)); im=T_.im.resize((T_.w*k,T_.h*k),Image.NEAREST); p=im.load()
    for j in range(im.height):
        for i in range(im.width):
            if p[i,j][3]>0: S.dot(x+i,y+j,c)
def level(code,cls,t):
    S=Spr(34,42,12); S.rect('black',0,0,34,42); S.rect('steel',2,2,30,38,edge=True); S.rect_px(MAT['steel'][4],2,2,30,1)
    S.rect('black',3,3,28,36,edge=False); S.rect_px(MAT['steel'][3],3,3,28,36); S.rect_px(MAT['steel'][2],3,3,28,1)
    big(S,5,8,t,MAT['paper'][1],3); S.poly('yellow',[(17,26),(6,31),(6,35),(17,30),(28,35),(28,31)],edge=False); done(code,cls,S,'wall')
level('K','Sign_B1','B1'); level('L','Sign_B2','B2')
# ---- code cases etc.
def case(code,cls,mat,w,h,bright=False):
    S=Spr(w,h,13); S.rect(mat,0,3,w,h-3); S.rect_px(MAT[mat][3],0,h//2,w,1); S.rect_px(MAT[mat][0],1,h//2+1,w-2,1)
    S.rect('black',w//2-5,0,10,4); S.rect_px(MAT['black'][2],w//2-3,1,6,2)
    for x in (5,w-9): S.rect('steel',x,h//2-2,4,5); S.rect_px(MAT['steel'][4],x+1,h//2,2,1)
    for x,y in ((0,3),(w-4,3),(0,h-4),(w-4,h-4)): S.rect('steel',x,y,4,4)
    S.rect_px(MAT['black'][3],w//2-6,h-9,12,4) if False else None
    done(code,cls,S,'stand',outline=True)
case('R','Case_Olive','olive',32,28); case('S','Case_Teal','teal',34,26); case('T','Case_Grey','steel',40,30)
S=Spr(26,20,14); S.rect('black',0,3,26,17); S.rect('black',8,0,10,4); S.rect_px(MAT['black'][4],10,1,6,2); S.rect_px(MAT['black'][0],1,4,24,1); S.rect('yellow',4,8,4,5,edge=False); S.rect('yellow',18,8,4,5,edge=False); S.rect_px(MAT['black'][4],0,12,26,1); done('U','Toolbox_Black',S,'stand',outline=True)
S=Spr(28,50,15); S.rect('black',0,0,28,50); S.rect('ink',2,2,24,46,edge=False)
for i in range(6):
    y=4+i*7; S.rect('black',3,y,22,5,edge=True)
    for k in range(5): S.rect_px(GR[1] if (i+k)%3 else hx('#e8a020'),5+k*3,y+2,1,1)
    S.rect_px(MAT['black'][0],20,y+1,4,1)
done('0','ServerRack',S,'stand',outline=True)
# desk clutter (code)
S=Spr(9,9,16); S.rect('paper',0,1,7,8); S.rect_px(MAT['black'][2],2,4,3,3); S.rect_px(MAT['paper'][3],7,3,2,1); S.rect_px(MAT['paper'][3],8,4,1,3); S.rect_px(MAT['paper'][3],7,6,2,1); done('1','Mug',S,'stand',outline=True)
S=Spr(6,14,17); S.part('steel',lambda d:d.rounded_rectangle((0,2,5,13),1,fill=255),form='cyl'); S.rect('black',0,0,6,3); done('2','Thermos',S,'stand',outline=True)
S=Spr(26,16,18)
for i,(m,x,h) in enumerate((('navy',0,15),('navy',6,14),('red',12,15),('green',18,13))): S.rect(m,x,16-h,6,h); S.rect('paper',x+1,16-h+3,4,5,edge=False)
done('3','Binders',S,'stand',outline=True)
S=Spr(20,10,19)
for k in range(4): S.rect('paper',k%2,8-k*2-1 if False else 8-k*2,18-(k%2),2,noise=.02)
S.rect('paper',0,0,18,2); done('4','PapersStack',S,'stand',outline=True)
# ---- code-drawn signs
def board(w,h,mat='slate'):
    S=Spr(w,h,4); S.rect(mat,0,0,w,h); S.rect_px(MAT['steel'][1],1,1,w-2,1); return S
S=board(76,50); rows=('OPERATIONS','BRIEFING ROOM','SERVER ROOM','RESTROOMS')
for i,t in enumerate(rows):
    y=5+i*11; arrow(S,4,y,left=True); arrow(S,67,y); S.text(13,y,t,CREAM)
    if i<3: S.rect_px(MAT['slate'][3],3,y+8,70,1)
done('a','Directory_Command',S,'wall')
S=board(66,30); S.text(19,6,'STAIRS',CREAM); S.text(19,15,'LOWER LEVEL',MAT['steel'][0])
for i in range(4): S.rect_px(CREAM,4+i*3,10+i*3,4,1); S.rect_px(CREAM,4+i*3,10+i*3,1,3)
done('b','Sign_Stairs',S,'wall')
S=board(58,34); S.text(20,6,'ELEVATORS',CREAM); S.text(20,15,'B1 - B2',CREAM); S.rect('steel',4,6,12,20,edge=True); S.rect_px(MAT['slate'][4],9,8,2,17); arrow(S,44,23); done('c','Sign_Elevators',S,'wall')
S=Spr(66,34,5); S.rect('paper',0,0,66,34); S.rect_px(MAT['paper'][3],0,33,66,1); S.rect_px(MAT['paper'][3],65,0,1,34); S.rect_px(MAT['black'][2],1,1,64,1)
arrow(S,5,8,c=MAT['black'][3],left=True); S.text(16,7,'CENTRAL',MAT['black'][3]); S.text(16,15,'COMMAND',MAT['black'][3]); S.rect('yellow',6,26,54,3,noise=0); done('d','Sign_CentralCommand',S,'wall')
S=Spr(16,38,6); S.part('red',lambda d:d.rounded_rectangle((2,10,13,36),3,fill=255),form='cyl'); S.rect('black',5,3,6,8); S.rect('black',9,1,6,3); S.rect_px(MAT['black'][1],13,4,1,12)
S.rect('paper',4,20,7,7,noise=0); S.rect_px(MAT['black'][3],5,22,5,1); S.rect_px(MAT['black'][3],5,24,5,1); done('e','Extinguisher',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
codes=sorted(OUTS); ims=[Image.open(f'out/{OUTS[c][4]}A0.png').convert('RGBA') for c in codes]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1400),(58,58,66,255))
for im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
