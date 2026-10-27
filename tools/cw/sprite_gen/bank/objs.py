from lib import *
import lib, os, shutil
MAT=lib.MAT
MAT['cardside']=[hx(c) for c in '#c49458 #a87a40 #8a6030 #64421e #3c2810'.split()]
MAT['tape']=[hx(c) for c in '#f0e2b0 #d4c088 #ae9662 #6a5a38 #40381e'.split()]
os.makedirs('out',exist_ok=True); OUTS={}
def done(code,cls,S,outline=True):
    if outline: S.outline()
    save(S.im,f'out/CBK{code}A0.png'); OUTS[code]=(cls,S.w,S.h)
# ---------- shared pieces ----------
def carton(S,x,y,w,h,label=True):
    S.rect('card',x,y+4,w-3,h-4)                 # front face
    S.rect('cardside',x+w-3,y+3,3,h-3)           # right face, in shadow
    S.rect('cardtop',x+1,y,w-1,5)                # lid, lit
    S.rect('tape',x+(w-3)//2-1,y,3,5,edge=False) # tape across the lid...
    S.rect('tape',x+(w-3)//2-1,y+5,3,min(5,h-6),edge=False)  # ...and down the front
    if label and w>=16 and h>=12:
        S.rect('paper',x+2,y+h-7,6,4); S.rect_px(MAT['paper'][3],x+3,y+h-5,4,1)
def papers(S,x,yb,w,n,jit=1):
    for i in range(n):
        j=S.rnd.randint(-jit,jit); S.rect('paper',x+jit+j,yb-3*(i+1),w-2*jit,3,noise=0)
    yt=yb-3*n
    for k in range(w//4): S.dot(x+jit+2+k*3,yt+1,MAT['paper'][3])     # print lines on the top sheet
def post(S,x,by,H=66):
    S.ell('steel',x+1,by-H,x+9,by-H+8,form='cyl')                     # ball top
    S.rect('steel',x+4,by-H+8,3,3,form='cyl')                          # neck
    S.rect('steel',x+3,by-H+11,5,H-20,form='cyl')                      # pole
    S.rect('steel',x+2,by-11,7,3,form='cyl')                           # collar
    S.poly('steel',[(x+1,by),(x+9,by),(x+8,by-8),(x+2,by-8)],form='cyl')   # dome base
    S.rect('steel',x,by-2,11,2)                                        # plate
# ---------- Q,R,U papers ----------
S=Spr(20,26,3); papers(S,0,26,20,7); done('Q','PapersTall',S)
S=Spr(18,16,4); papers(S,0,16,18,4); done('R','PapersShort',S)
S=Spr(20,18,5); papers(S,0,18,20,5,jit=2); done('U','PapersLoose',S)
# ---------- P archive box ----------
S=Spr(32,26,6); carton(S,0,0,32,26,label=False)
S.rect('ink',11,13,9,3,edge=False); S.rect_px(MAT['card'][2],11,16,9,1)                 # hand hole
S.rect('paper',22,15,7,6); S.rect_px(MAT['paper'][3],23,17,5,1); S.rect_px(MAT['paper'][3],23,19,4,1)
done('P','ArchiveBox',S)
# ---------- S binders ----------
S=Spr(24,28,7)
for x in (0,8,16):
    S.rect('navy',x,2,8,26,noise=0); S.rect('paper',x+2,5,4,9); S.rect_px(MAT['paper'][3],x+3,8,2,1)
    S.rect('black',x+3,18,2,2,edge=False)
for x in (7,15): S.rect_px(MAT['navy'][4],x,2,1,26)
done('S','Binders',S)
# ---------- T books ----------
S=Spr(32,26,8)
S.rect('green',0,2,8,24); S.rect('paper',2,5,4,8); S.rect_px(MAT['paper'][3],3,8,2,1)
S.rect('red',9,17,20,9); S.rect('paper',29,18,3,7,edge=False); S.rect_px(MAT['brass'][1],10,19,1,5)
S.rect('navy',11,10,18,7); S.rect('paper',29,11,2,5,edge=False); S.rect_px(MAT['brass'][1],12,11,1,4)
S.rect('green',10,5,16,5); S.rect('paper',26,6,2,3,edge=False)
done('T','Books',S)
# ---------- V phone ----------
S=Spr(18,14,9)
S.poly('black',[(1,6),(17,6),(15,13),(3,13)]); S.rect('black',0,2,18,4); S.rect_px(MAT['black'][0],2,2,14,1)
S.rect('steel',0,1,3,3); S.rect('steel',15,1,3,3)
for i in range(3):
    for j in range(3): S.dot(6+3*i,8+2*j,MAT['steel'][1])
done('V','Phone',S)
# ---------- W mug ----------
S=Spr(11,10,10)
S.rect('cream',0,1,8,9,form='cyl'); S.part('cream',lambda d:d.ellipse((6,3,10,8),outline=255,width=1),edge=False)
S.rect_px(MAT['black'][3],1,1,6,1)
done('W','Mug',S)
# ---------- X pen cup ----------
S=Spr(9,15,11)
S.rect_px(hx('#3a6ad0'),2,1,1,7); S.rect_px(hx('#d03a30'),4,0,1,8); S.rect_px(hx('#e8c020'),6,2,1,6)
S.rect('black',1,7,7,8,form='cyl'); S.rect('steel',0,6,9,2)
done('X','PenCup',S)
# ---------- Y desk lamp ----------
S=Spr(32,26,12)
S.ell('steel',9,21,23,25,form='cyl'); S.line('steel',16,22,16,12,w=2); S.line('steel',16,12,8,7,w=2)
S.poly('steel',[(0,6),(12,2),(14,7),(1,10)]); S.rect_px(MAT['yellow'][0],3,9,9,1)
done('Y','DeskLamp',S)
# ---------- 0,1 stanchions ----------
S=Spr(44,68,13); post(S,0,67); post(S,30,67); done('1','Stanchions',S)
S=Spr(78,68,14); post(S,0,67); post(S,66,67)
pts=[(6+(66*t/24),12+16*(1-(2*t/24-1)**2)) for t in range(25)]
def rope(d):
    for a,b in zip(pts,pts[1:]): d.line((a,b),fill=255,width=3)
S.part('red',rope)
done('0','StanchionRope',S)
# ---------- 2 trash bag ----------
S=Spr(34,44,15)
S.part('bag',lambda d:[d.ellipse(b,fill=255) for b in ((1,16,20,43),(12,13,33,43),(5,22,29,43))]); S.poly('bag',[(11,13),(13,4),(18,1),(22,5),(23,13)]); S.poly('bag',[(17,1),(21,0),(24,3),(20,4)])
for x,y in((5,24),(5,25),(6,27),(24,20),(25,22),(11,19),(12,19),(16,32),(16,33)): S.dot(x,y,MAT['bag'][0])
done('2','TrashBag',S)
# ---------- 3 mop bucket ----------
S=Spr(56,88,16)
S.poly('yellow',[(2,46),(34,46),(32,79),(6,79)]); S.rect('yellow',0,42,36,5)
S.poly('yellow',[(22,30),(36,30),(38,42),(24,42)]); S.rect('black',26,33,8,6,edge=False)
S.poly('black',[(17,53),(26,69),(8,69)]); S.poly('yellow',[(17,58),(22,67),(12,67)]); S.dot(17,62,MAT['black'][3]);S.dot(17,64,MAT['black'][3]);S.dot(17,66,MAT['black'][3])
S.ell('black',3,78,9,84); S.ell('black',29,78,35,84)
S.line('wood',47,3,42,66,w=2)
S.poly('cream',[(40,64),(48,64),(54,86),(34,86)])
for x in (38,41,44,47,50): S.rect_px(MAT['cream'][2],x,70,1,15)
done('3','MopBucket',S)
# ---------- 4 small cart ----------
S=Spr(40,40,17)
carton(S,10,14,18,12)
S.rect('steel',1,8,2,28); S.rect('steel',37,8,2,28); S.rect('steel',0,8,40,3); S.rect('steel',0,26,40,3)
S.ell('black',0,35,5,40); S.ell('black',35,35,40,40)
done('4','CartSmall',S)
# ---------- 5 hand cart with boxes ----------
S=Spr(48,52,18)
S.rect('black',1,16,2,28); S.rect('black',45,16,2,28); S.rect('black',1,16,46,2)
carton(S,3,28,20,14); carton(S,24,30,20,12); carton(S,8,15,18,13); carton(S,27,20,15,10,label=False)
S.rect('black',0,42,48,4); S.ell('black',2,45,9,51); S.ell('black',39,45,46,51)
S.dot(5,48,MAT['steel'][1]); S.dot(42,48,MAT['steel'][1])
done('5','CartBoxes',S)
# ---------- 6 box pile ----------
S=Spr(40,34,19)
carton(S,0,14,24,18); carton(S,22,20,18,12,label=False); carton(S,4,4,18,10,label=False)
done('6','BoxPile',S)
# ---------- O desk clutter ----------
S=Spr(84,40,20)
for i,m in enumerate(('steel','black','steel')): S.rect(m,2,25+3*i,13,3)
S.rect('cream',16,6,24,20); S.rect('ink',19,9,18,13,edge=False)
for (x,y,w) in((21,11,8),(21,13,12),(21,15,6),(21,17,10)): S.rect_px(MAT['glow'][1],x,y,w,1)
S.rect('cream',24,26,8,3); S.rect('cream',14,30,28,4)
for x in range(16,40,2): S.dot(x,31,MAT['cream'][2]); S.dot(x,32,MAT['cream'][2]) if x%4 else None
S.poly('green',[(48,17),(51,10),(58,10),(61,17)]); S.rect('brass',54,17,2,14); S.rect('brass',50,31,10,3); S.rect_px(MAT['yellow'][0],52,17,6,1)
S.ell('cream',66,25,75,34,form='cyl'); S.ell('ink',69,28,72,31,edge=False)
S.rect_px(hx('#3a6ad0'),79,17,1,6); S.rect_px(hx('#d03a30'),81,15,1,8); S.rect_px(hx('#e8c020'),83,18,1,5)
S.rect('black',78,23,6,11,form='cyl')
S.rect('wood',0,34,84,6)
done('O','DeskClutter',S)
# ---------- Z wet floor: reuse the approved test ----------
shutil.copy('../bank/wetfloor_test.png','out/_z.png'); im=Image.open('out/_z.png'); save(im,'out/CBKZA0.png'); OUTS['Z']=('WetFloor',im.width,im.height); os.remove('out/_z.png')
import json; json.dump(OUTS,open('out/manifest.json','w'))
# ---------- preview against a vending crop ----------
codes=list('OPQRSTUVWXYZ0123456'.replace('0','')) if False else ['O','P','Q','R','S','T','U','V','W','X','Y','Z','1','0','2','3','4','5','6']
ims=[Image.open(f'out/CBK{c}A0.png').convert('RGBA') for c in codes]
z=4; x=y=10; rowh=0; sheet=Image.new('RGBA',(1500,900),(58,58,66,255))
for im in ims:
    t=im.resize((im.width*z,im.height*z),Image.NEAREST)
    if x+t.width>1490: x=10; y+=rowh+14; rowh=0
    sheet.alpha_composite(t,(x,y)); x+=t.width+16; rowh=max(rowh,t.height)
sheet.crop((0,0,1500,y+rowh+10)).save('preview.png'); print(y+rowh)
