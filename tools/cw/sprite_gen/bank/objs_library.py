import sys; sys.path.insert(0,'.')
from trace import *
import lib, os, json, math, struct, zlib, io
import px
MAT=lib.MAT
for k,v in {'parch':'#f4e4b0 #dcc088 #b89658 #866a34 #524020','contA':'#c8a060 #a88040 #84602a #5e4218 #3a280e',
            'ocean':'#8ab8f4 #4682d0 #2e60a8 #1e4078 #12264c','gold':'#f6dc70 #dcb040 #b08420 #7a5810 #483206',
            'navyd':'#3c5a94 #1e3160 #15234a #0e1832 #0a1022'}.items(): MAT[k]=[hx(c) for c in v.split()]
CREAM=hx('#e6e0cc'); INKC=MAT['black'][3]
os.makedirs('out',exist_ok=True); OUTS={}
def done(code,cls,S,kind,outline=None):
    if outline is None: outline=(kind=='stand')
    if outline: S.outline()
    W,H=S.w,S.h; ox,oy=(W//2,H//2) if kind=='wall' else (W//2,H)
    b=io.BytesIO(); S.im.save(b,'PNG'); d=b.getvalue(); ch=lambda t,x:struct.pack('>I',len(x))+t+x+struct.pack('>I',zlib.crc32(t+x)&0xffffffff)
    open(f'out/CLB{code}A0.png','wb').write(d[:33]+ch(b'grAb',struct.pack('>ii',ox,oy))+d[33:]); OUTS[code]=(cls,kind,W,H)
def recolor(img,y_from,src,dst):
    S,D=MAT[src],MAT[dst]; p=img.load()
    for y in range(y_from,img.height):
        for x in range(img.width):
            if p[x,y][3] and p[x,y] in S: p[x,y]=D[S.index(p[x,y])]
def with_plinth(fig,pw):
    fw,fh=fig.size; W=max(pw,fw); y0=fh-2; S=Spr(W,y0+22)
    ox=(W-fw)//2; S.rect('stone',(W-pw)//2+3,y0,pw-6,4); S.rect('stone',(W-pw)//2+5,y0+4,pw-10,12); S.rect('stone',(W-pw)//2+1,y0+16,pw-2,6)
    S.rect_px(MAT['stone'][3],(W-pw)//2+9,y0+8,pw-18,1)
    S.im.paste(fig,(ox,0),fig); S.px=S.im.load(); return S
# ================= traced: statues, busts =================
done('A','Statue_Pedestal',as_spr(trace((455,30,538,292),108,key='navy')),'stand')
done('B','Statue_Robed',with_plinth(trace((596,38,676,183),70,key='navy'),47),'stand')
done('C','Statue_Hero',with_plinth(trace((736,38,820,214),76,key='navy'),44),'stand')
for code,cls,box,th,ramp in (('D','Bust_Marble',(482,462,560,600),46,'stone'),('E','Bust_Bronze',(586,470,656,600),44,'bronze'),('F','Bust_MarbleB',(700,462,758,600),46,'stone')):
    im=trace(box,th,ramp=ramp); recolor(im,int(th*0.74),ramp,'black'); done(code,cls,as_spr(im),'stand')
# ================= traced: paintings (code frames, traced interior) =================
def framed(interior,frame,pad=4,ring='brass'):
    iw,ih=interior.size; W,H=iw+2*pad,ih+2*pad; S=Spr(W,H); S.rect(frame,0,0,W,H,noise=0)
    c=MAT[ring][2]
    for x in range(1,W-1): S.dot(x,pad-1,c); S.dot(x,H-pad,c)
    for y in range(pad-1,H-pad+1): S.dot(pad-1,y,c); S.dot(W-pad,y,c)
    S.im.paste(interior,(pad,pad)); S.px=S.im.load(); return S
dome=trace((1424,334,1580,436),42,mode='color',ncol=18,enh=(1.45,1.1,1.25)); done('G','Painting_Dome',framed(dome,'woodf'),'wall')
port=trace((1628,322,1736,434),40,mode='color',ncol=16,enh=(1.5,1.9,1.1)); done('H','Painting_Portrait',framed(port,'woodd'),'wall')
# ================= traced: display case, lectern =================
done('I','DisplayCase',as_spr(trace((1546,466,1662,596),46,mode='color',ncol=20,enh=(1.2,0.95,1.15))),'stand')
done('J','Lectern',as_spr(trace((1372,505,1538,602),36,mode='color',ncol=18,enh=(1.3,1.25,1.1))),'stand')
# ================= drawn: globes, armillary =================
def sphere(S,cx,cy,r,ocean,land,blobs):
    lm=Image.new('L',(S.w,S.h),0); d=ImageDraw.Draw(lm)
    for b in blobs: d.polygon([(cx+px_*r,cy+py_*r) for px_,py_ in b],fill=255)
    lp=lm.load()
    for y in range(S.h):
        for x in range(S.w):
            nx=(x+.5-cx)/r; ny=(y+.5-cy)/r
            if nx*nx+ny*ny>1: continue
            nz=math.sqrt(1-nx*nx-ny*ny); dd=-.45*nx-.55*ny+.70*nz
            i=0 if dd>.80 else 1 if dd>.48 else 2 if dd>.18 else 3 if dd>-.15 else 4
            S.px[x,y]=MAT[land if lp[x,y] else ocean][i]
AM=[[(-.6,-.5),(-.2,-.62),(-.1,-.2),(-.3,.1),(-.34,.62),(-.5,.2),(-.72,-.1)],[(.15,-.62),(.72,-.45),(.78,-.05),(.46,.05),(.36,.58),(.15,.36),(.05,-.1)]]
def globe(code,cls,ocean,land,stand):
    S=Spr(36,46); cx,cy,r=18,17,13
    S.part('brass',lambda d:d.ellipse((cx-r-3,cy-r-3,cx+r+3,cy+r+3),outline=255,width=1),edge=False)     # meridian ring
    sphere(S,cx,cy,r,ocean,land,AM)
    S.rect('brass',cx-1,cy+r+3,2,5); S.ell(stand,cx-9,40,cx+9,45,form='cyl'); S.rect('brass',cx-2,cy+r+7,4,4)
    S.part('brass',lambda d:d.line((cx,cy-r-5,cx,cy-r-2),fill=255),edge=False)
    done(code,cls,S,'stand')
globe('K','Globe_Antique','parch','contA','brass'); globe('L','Globe_Blue','ocean','gold','black')
S=Spr(40,46)
S.part('brass',lambda d:[d.ellipse(b,outline=255,width=2) for b in ((5,3,35,33),(12,3,28,33),(3,14,37,22))])
S.ell('brass',16,13,24,21,form='cyl'); S.rect('brass',19,32,2,8); S.ell('brass',9,39,31,45,form='cyl'); done('M','Armillary',S,'stand')
# ================= drawn: banker lamps =================
S=Spr(26,36)
S.poly('green',[(3,11),(7,4),(19,4),(23,11)]); S.rect_px(MAT['yellow'][0],5,11,16,1); S.rect('brass',12,11,2,17); S.ell('brass',5,27,21,33,form='cyl'); done('N','BankerLamp_A',S,'stand')
S=Spr(28,36)
S.part('green',lambda d:d.pieslice((2,2,26,26),180,360,fill=255)); S.rect_px(MAT['yellow'][0],3,14,22,1); S.rect('brass',13,14,2,14); S.ell('brass',7,27,21,33,form='cyl'); done('O','BankerLamp_B',S,'stand')
# ================= drawn: library signs =================
def bigch(S,x,y,ch,sc,c):
    for j,row in enumerate(px.FONT[ch].split()):
        for i,v in enumerate(row):
            if v=='1': S.rect_px(c,x+i*sc,y+j*sc,sc,sc)
def ctext(S,cx,y,t,c,sp=1): S.text(cx-(len(t)*(3+sp)-sp)//2,y,t,c,sp)
def arrow(S,x,y,c=CREAM):
    for j,row in enumerate(("00100","00010","11111","00010","00100")):
        for i,v in enumerate(row):
            if v=='1': S.dot(x+i,y+j,c)
def card(w,h): S=Spr(w,h); S.rect('black',0,0,w,h,noise=0); S.rect('cream',1,1,w-2,h-2,noise=.015); return S
for code,cls,ch,left in (('P','Sign_StacksB','B',True),('Q','Sign_StacksC','C',False)):
    S=card(34,46); ctext(S,17,4,'STACKS',INKC); bigch(S,12,13,ch,3,INKC)
    for x in range(8,26): S.dot(x,36,INKC); S.dot(x,37,INKC)
    for k in range(4):
        if left: S.dot(8+k,36-3+k+ (0),INKC) if False else None
    for j in range(7):
        d=abs(j-3); S.rect_px(INKC,(8+d) if left else (25-d),33+j,1,1)
    done(code,cls,S,'wall')
S=card(36,46); ctext(S,18,4,'SILENCE',INKC); ctext(S,18,11,'PLEASE',INKC)
S.ell('black',11,16,23,29); S.ell('black',5,31,29,52); S.rect_px(CREAM,17,21,2,7); S.rect_px(CREAM,16,20,4,1); done('R','Sign_Silence',S,'wall')
S=card(38,48); RED=MAT['red'][1]
S.ell('red',7,4,31,28); S.ell('cream',10,7,28,25,edge=False); S.rect('black',15,13,8,9); S.rect('black',14,11,10,2)
S.part('red',lambda d:d.line((10,25,28,7),fill=255,width=2),edge=False)
ctext(S,19,33,'NO FOOD',RED); ctext(S,19,41,'OR DRINK',RED); done('S','Sign_NoFoodDrink',S,'wall')
S=Spr(46,46); S.rect('red',0,0,46,46,noise=0); S.rect('black',2,13,42,31,noise=.015); ctext(S,23,4,'RESTRICTED',CREAM)
ctext(S,23,17,'AREA',CREAM); S.poly('cream',[(23,26),(35,42),(11,42)],edge=False); S.poly('black',[(23,30),(31,40),(15,40)],edge=False)
S.rect_px(CREAM,23,33,1,4); S.dot(23,38,CREAM); done('T','Sign_Restricted',S,'wall')
rows=['LIBRARY','READING ROOM','ARCHIVES','RESEARCH','COMPUTER LAB','MEETING ROOM','RESTROOMS']
h=4+8*len(rows); w=68; S=Spr(w,h); S.rect('steel',0,0,w,h,noise=0); S.rect('navyd',1,1,w-2,h-2,noise=.015)
for i,r in enumerate(rows):
    y=4+8*i; S.text(4,y,r,CREAM); arrow(S,w-9,y,MAT['cream'][2])
    if i: S.rect_px(MAT['navyd'][3],2,y-2,w-4,1)
done('U','Directory_Library',S,'wall')
# ================= drawn: coat rack, rolling ladder =================
S=Spr(24,72); S.rect('wood',10,6,3,58,form='cyl'); S.ell('wood',8,0,14,7,form='cyl')
for (a,b,c,d) in ((11,12,3,7),(11,12,19,7),(11,20,4,15),(11,20,18,15)): S.line('wood',a,b,c,d,w=2)
for (a,b,c,d) in ((11,62,2,70),(11,62,20,70),(11,62,11,71)): S.line('wood',a,b,c,d,w=2)
done('V','CoatRack',S,'stand')
S=Spr(28,60); S.poly('wood',[(5,0),(8,0),(4,59),(0,59)]); S.poly('wood',[(20,0),(23,0),(27,59),(23,59)])
for y in range(6,56,8):
    t=y/59; xl=int(6.5-4*t)+1; xr=int(21.5+4*t)-1; S.rect('wood',xl,y,xr-xl+1,2)
S.rect('brass',3,0,22,2); done('W','RollingLadder',S,'stand')
json.dump(OUTS,open('out/manifest.json','w'))
codes=sorted(OUTS); ims=[Image.open(f'out/CLB{c}A0.png').convert('RGBA') for c in codes]
z=3; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,1400),(58,58,66,255))
for im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+14; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(len(ims),y+rowh)
