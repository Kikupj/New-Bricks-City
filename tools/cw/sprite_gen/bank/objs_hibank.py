from lib import *
import lib, os, json, shutil
import px; px.FONT['/']='001 001 010 100 100'
MAT=lib.MAT
MAT['cardside']=[hx(c) for c in '#c49458 #a87a40 #8a6030 #64421e #3c2810'.split()]
MAT['tape']=[hx(c) for c in '#f0e2b0 #d4c088 #ae9662 #6a5a38 #40381e'.split()]
MAT['navyd']=[hx(c) for c in '#3c5a94 #1e3160 #15234a #0e1832 #0a1022'.split()]
MAT['screen']=[hx(c) for c in '#7ab8ff #3a78d0 #2a58a0 #1c3c70 #10244a'.split()]
CREAM=hx('#e6e0cc'); BRASS=MAT['brass'][1]; INKC=MAT['black'][3]
os.makedirs('out',exist_ok=True); OUTS={}
def done(code,cls,S,kind,outline=None,frame='A',frames=1,tics=0):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    W,H=S.w,S.h; ox,oy=(W//2,H//2) if kind=='wall' else (W//2,H)
    b=__import__('io').BytesIO(); S.im.save(b,'PNG'); import struct,zlib
    d=b.getvalue(); ch=lambda t,x:struct.pack('>I',len(x))+t+x+struct.pack('>I',zlib.crc32(t+x)&0xffffffff)
    open(f'out/CHK{code}{frame}0.png','wb').write(d[:33]+ch(b'grAb',struct.pack('>ii',ox,oy))+d[33:])
    OUTS[code]=(cls,kind,W,H,frames,tics)
def arrow(S,x,y,c=CREAM):
    for j,row in enumerate(("00100","00010","11111","00010","00100")):
        for i,v in enumerate(row):
            if v=='1': S.dot(x+i,y+j,c)
def frame(S,w,h,fill='navyd',edge='steel'):
    S.rect(edge,0,0,w,h,noise=0); S.rect(fill,1,1,w-2,h-2,noise=.015)
def tw(t,sp=1): return len(t)*(3+sp)-sp
def ctext(S,cx,y,t,c,sp=1): S.text(cx-tw(t,sp)//2,y,t,c,sp)
# ---- direction signs ----
for code,word in (('A','TELLERS'),('B','EXECUTIVE'),('C','LOANS'),('D','VAULT'),('E','SECURITY')):
    w=tw(word)+16; S=Spr(w,15); frame(S,w,15); S.text(4,5,word,CREAM); arrow(S,w-9,5); done(code,'Sign_'+word.title(),S,'wall')
# ---- directories ----
def directory(code,cls,title,rows):
    h=13+7*len(rows)+2; w=68; S=Spr(w,h); S.rect('black',0,0,w,h); S.rect('black',1,1,w-2,h-2)
    S.rect_px(BRASS,0,0,w,1); S.rect_px(BRASS,0,h-1,w,1); S.rect_px(BRASS,0,0,1,h); S.rect_px(BRASS,w-1,0,1,h)
    S.text(4,4,title,BRASS); S.rect_px(MAT['brass'][3],3,10,w-6,1)
    for i,r in enumerate(rows):
        y=13+7*i; S.text(4,y,r,CREAM); arrow(S,w-9,y,MAT['cream'][2])
    done(code,cls,S,'wall')
directory('F','Sign_DirectoryFloor1','FLOOR 1',['LOBBY','TELLERS','EXECUTIVE','MEETING','RESTROOMS'])
directory('G','Sign_DirectoryFloor2','FLOOR 2',['LOANS','VAULT','SECURITY','IT / SERVERS','STAFF'])
# ---- restroom arrow ----
S=Spr(45,24); frame(S,45,24); ctext(S,22,5,'RESTROOMS',CREAM)
for x in range(12,32): S.dot(x,16,CREAM); S.dot(x,17,CREAM)
for k in range(4): S.dot(32+k,16-3+k+0,CREAM) if False else None
for j in range(7): S.rect_px(CREAM,32+j//1 if j<4 else 32+(6-j),13+j,1,1)
done('H','Sign_RestroomArrow',S,'wall')
# ---- restroom icons ----
S=Spr(38,20); frame(S,38,20)
def person(x,fem):
    S.rect_px(CREAM,x+1,3,3,3); 
    if fem: S.poly('paper',[(x+2,7),(x+5,14),(x-1,14)],edge=False); S.rect_px(CREAM,x+1,14,1,3); S.rect_px(CREAM,x+3,14,1,3)
    else: S.rect_px(CREAM,x,7,5,6); S.rect_px(CREAM,x,13,2,4); S.rect_px(CREAM,x+3,13,2,4)
person(9,False); person(25,True); S.rect_px(MAT['steel'][2],19,3,1,14)
done('I','Sign_RestroomIcons',S,'wall')
# ---- authorized personnel ----
S=Spr(52,36); S.rect('yellow',0,0,52,36)
for y in list(range(0,6))+list(range(30,36)):
    for x in range(52): S.dot(x,y,MAT['black'][3] if (x+y)%8<4 else MAT['yellow'][1])
S.rect_px(INKC,0,0,52,1); S.rect_px(INKC,0,35,52,1); S.rect_px(INKC,0,0,1,36); S.rect_px(INKC,51,0,1,36)
ctext(S,26,10,'AUTHORIZED',INKC); ctext(S,26,17,'PERSONNEL',INKC); ctext(S,26,24,'ONLY',INKC)
done('J','Sign_AuthorizedOnly',S,'wall')
# ---- security monitor wall (2 frames: figures move) ----
for f,frm in enumerate('AB'):
    S=Spr(58,42); S.rect('black',0,0,58,42)
    for n,(sx,sy) in enumerate(((2,2),(30,2),(2,22),(30,22))):
        S.rect('screen',sx,sy,26,18,edge=False)
        S.rect_px(MAT['screen'][3],sx,sy+11,26,7)                    # floor
        S.rect_px(MAT['screen'][4],sx+3+n*3,sy+3,5,8)               # doorway
        S.rect_px(MAT['screen'][0],sx+16,sy+4,7,1); S.rect_px(MAT['screen'][2],sx+16,sy+6,7,1)
        px_=sx+8+((n*5+f*6)%14); S.rect_px(CREAM,px_,sy+8,2,2); S.rect_px(CREAM,px_,sy+10,2,4)   # a guard walking
        S.text(sx+2,sy+2,f'C{n+1}',MAT['screen'][0],0)
    done('K','Wall_MonitorGrid',S,'wall',frame=frm,frames=2,tics=20)
# ---- posters ----
S=Spr(56,74); S.rect('cream',0,0,56,74,noise=0); S.rect('paper',2,2,52,70,edge=False,noise=.015)
S.rect('black',26,6,4,4); S.poly('steel',[(19,12),(37,12),(40,20),(16,20)]); S.ell('black',22,14,34,24); S.dot(25,17,MAT['steel'][0]); S.dot(26,17,MAT['steel'][0])
ctext(S,28,32,'THIS AREA',INKC); ctext(S,28,40,'IS UNDER',INKC); ctext(S,28,52,'SURVEILLANCE',MAT['red'][1]); S.rect_px(MAT['red'][1],4,60,48,1); S.rect_px(MAT['red'][1],4,62,48,1)
done('L','Poster_Surveillance',S,'wall')
S=Spr(48,68); frame(S,48,68); ctext(S,24,6,'NOTICE',CREAM); S.rect_px(CREAM,6,13,36,1)
for y,t in ((22,'BADGE'),(29,'REQUIRED'),(42,'BEYOND'),(49,'THIS'),(56,'POINT')): ctext(S,24,y,t,CREAM)
done('M','Poster_BadgeNotice',S,'wall')
S=Spr(46,64); S.rect('steel',0,0,46,64,noise=0); S.rect('paper',2,2,42,60,edge=False,noise=.015)
for y,t in ((12,'SECURITY'),(20,'IS A TEAM'),(28,'EFFORT')): ctext(S,23,y,t,INKC)
for x in (12,23,34): S.rect_px(INKC,x,42,4,4); S.rect_px(INKC,x-1,47,6,8)
done('N','Poster_TeamEffort',S,'wall')
S=Spr(46,66); frame(S,46,66)
for y,t in ((10,'CLEAN'),(18,'DESKS'),(30,'SECURE'),(38,'FUTURES')): ctext(S,23,y,t,CREAM)
S.rect('brass',17,54,12,9); S.part('brass',lambda d:d.arc((18,46,28,60),180,360,fill=255,width=2),edge=False)
S.rect_px(INKC,22,57,2,3)
done('O','Poster_CleanDesks',S,'wall')
# ---- standing ----
def post(S,x,by,H=66):
    S.ell('steel',x+1,by-H,x+9,by-H+8,form='cyl'); S.rect('steel',x+4,by-H+8,3,3,form='cyl'); S.rect('steel',x+3,by-H+11,5,H-20,form='cyl')
    S.rect('steel',x+2,by-11,7,3,form='cyl'); S.poly('steel',[(x+1,by),(x+9,by),(x+8,by-8),(x+2,by-8)],form='cyl'); S.rect('steel',x,by-2,11,2)
S=Spr(78,68); post(S,0,67); post(S,66,67)
pts=[(6+(66*t/24),12+16*(1-(2*t/24-1)**2)) for t in range(25)]
S.part('navy',lambda d:[d.line((a,b),fill=255,width=3) for a,b in zip(pts,pts[1:])]); done('P','StanchionRopeBlue',S,'stand')
S=Spr(16,24,3); S.rect('black',0,0,16,4); S.rect('black',2,4,12,19); S.rect('ink',5,12,6,8,edge=False); S.rect_px(hx('#6a4220'),5,16,6,4)
S.rect_px(MAT['red'][1],11,7,2,1); S.rect('steel',1,22,14,2); done('Q','CoffeeMachineDrip',S,'stand')
S=Spr(14,20,4); S.rect('black',1,0,12,3); S.rect('black',0,2,14,18); S.rect('ink',4,9,6,7,edge=False); S.rect('steel',3,16,8,2); S.rect_px(MAT['glow'][1],10,5,2,1); done('R','CoffeeMachineSingle',S,'stand')
S=Spr(22,14,5)
for k,(x,n) in enumerate(((0,5),(8,3),(15,4))):
    for i in range(n): S.rect('brass' if (i+k)%2 else 'steel',x,14-2*(i+1),6,2,edge=True,noise=0)
done('S','CoinStacks',S,'stand')
S=Spr(26,14,6); S.rect('steel',0,5,26,9); S.poly('black',[(3,0),(17,0),(19,6),(1,6)]); S.rect('ink',6,2,8,2,edge=False)
S.rect('ink',18,7,6,4,edge=False); S.rect_px(MAT['glow'][1],19,8,4,2); S.rect_px(MAT['steel'][3],2,11,14,1); done('T','CashCounter',S,'stand')
S=Spr(22,36,7); S.poly('cream',[(5,12),(8,3),(14,3),(17,12)]); S.rect_px(MAT['yellow'][0],7,12,8,1)
S.rect('brass',10,12,2,7); S.rect('brass',8,18,6,2)
S.rect('wood',1,22,20,3); S.rect('wood',3,25,2,11); S.rect('wood',17,25,2,11); S.rect('wood',3,31,16,2); done('U','TableLamp',S,'stand')
S=Spr(58,24,8); S.rect('black',0,4,58,10); S.rect('black',0,4,58,3)
for x in (14,29,44): S.rect_px(MAT['black'][4],x,7,1,7)
S.rect('wood',3,14,3,10); S.rect('wood',52,14,3,10); done('V','Bench',S,'stand')
S=Spr(14,20,9)
for (x0,y0,x1,y1) in ((7,11,2,2),(7,11,4,0),(7,11,7,0),(7,11,10,0),(7,11,12,3)): S.line('green',x0,y0,x1,y1,w=2)
S.rect('steel',3,11,8,8); S.rect_px(MAT['steel'][0],4,11,6,1); done('W','PlantDesk',S,'stand')
S=Spr(46,46,10); 
S.rect('steel',1,6,2,34); S.rect('steel',43,6,2,34)
for y in (6,20,34): S.rect('steel',0,y,46,2)
carton(S,6,10,14,10,label=False) if False else None
S.im=S.im  # boxes drawn below via local carton
def carton(S,x,y,w,h):
    S.rect('card',x,y+3,w-3,h-3); S.rect('cardside',x+w-3,y+2,3,h-2); S.rect('cardtop',x+1,y,w-1,4); S.rect('tape',x+(w-3)//2-1,y,3,4,edge=False)
carton(S,6,11,14,9); carton(S,26,25,15,9); carton(S,8,-0+27-9+9-9,12,7) if False else None
S.ell('black',0,40,6,45); S.ell('black',40,40,46,45); done('X','ShelfCart',S,'stand')
S=Spr(36,40,11)
S.rect('black',1,12,2,18); S.rect('black',33,12,2,18); S.rect('black',0,12,36,3); S.rect('black',0,28,36,3); S.rect('black',1,2,2,11); S.rect('black',1,2,8,2)
S.rect('paper',5,7,12,5); S.rect_px(MAT['paper'][2],5,9,12,1); S.rect('steel',24,3,5,9); S.rect('red',25,1,4,3)
S.ell('black',0,34,6,39); S.ell('black',30,34,36,39); done('Y','ServiceCart',S,'stand')
S=Spr(52,42,12)
S.rect('black',1,10,2,22); S.rect('black',1,10,9,2); S.rect('black',0,30,52,3)
S.rect('steel',6,16,22,14); S.rect_px(MAT['steel'][3],6,22,22,1); S.rect('ink',10,21,3,2,edge=False); S.rect('ink',21,21,3,2,edge=False)
S.rect('steel',30,21,15,9); S.rect_px(MAT['steel'][3],30,25,15,1); S.rect('ink',36,24,3,2,edge=False)
S.ell('black',1,33,8,40); S.ell('black',43,33,50,40); done('Z','EquipCart',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
# contact sheet
from PIL import Image
codes=sorted(OUTS); ims=[]
for c in codes:
    for fr in 'AB':
        p=f'out/CHK{c}{fr}0.png'
        if os.path.exists(p): ims.append(Image.open(p).convert('RGBA'))
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1200),(58,58,66,255))
for im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+12; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
