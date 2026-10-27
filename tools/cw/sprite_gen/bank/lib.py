"""Layered pixel toolkit matched to the Corpo Wars prop style:
flat fills, 1px light top/left edge, 1px darker bottom/right edge, near-black navy recesses,
sparse scuff pixels, hard edges, 1px dark outline on standing sprites."""
from PIL import Image, ImageDraw
import random, struct, zlib, io
def hx(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))+(255,)
MAT={ # hi, base, mid, dark, deep
 'card':   '#eec088 #d4a468 #b08448 #82582c #4e341a',
 'cardtop':'#f6d4a0 #e6bc84 #c8a066 #9a7440 #60401e',
 'paper':  '#ffffff #ecece4 #cacac2 #94948c #5c5c56',
 'navy':   '#6a88c8 #3a5a9a #28406e #1a2c50 #101c34',
 'green':  '#78b080 #468a52 #326a3e #22482c #142c1c',
 'red':    '#f06050 #c4302a #92201c #64140f #3a0c0a',
 'steel':  '#d4d8e0 #9ca2ac #6c727c #484e58 #2a2e36',
 'black':  '#646874 #30323c #20222a #13171d #0a0c10',
 'yellow': '#f6e05a #e8b820 #c99a12 #94690a #5e4206',
 'wood':   '#c89258 #9c6834 #76481f #50301a #30200e',
 'cream':  '#faf2de #dcd2b8 #b8ac8c #887e62 #58543e',
 'bag':    '#6a6e7c #383a46 #262830 #1a1c22 #0e1014',
 'ink':    '#13171d #13171d #0c0e12 #0c0e12 #0c0e12',
 'glow':   '#a8ffc0 #58e888 #38b060 #206838 #103820',
 'brass':  '#f0d060 #c8a030 #a07820 #705010 #402c08',
}
MAT={k:[hx(c) for c in v.split()] for k,v in MAT.items()}
OUT=hx('#1c1c20')
class Spr:
    def __init__(s,w,h,seed=1): s.w,s.h=w,h; s.im=Image.new('RGBA',(w,h),(0,0,0,0)); s.px=s.im.load(); s.rnd=random.Random(seed)
    def part(s,mat,draw,form=None,noise=.04,edge=True):
        m=Image.new('L',(s.w,s.h),0); draw(ImageDraw.Draw(m)); mp=m.load(); R=MAT[mat]; hi,ba,mi,dk,dp=R
        xs=[x for y in range(s.h) for x in range(s.w) if mp[x,y]]
        if not xs: return
        x0,x1=min(xs),max(xs)
        def on(x,y): return 0<=x<s.w and 0<=y<s.h and mp[x,y]>0
        for y in range(s.h):
            for x in range(s.w):
                if not mp[x,y]: continue
                c=ba
                if form=='cyl':                               # vertical roll: light left, dark right
                    f=(x-x0)/max(1,x1-x0)
                    c=hi if f<.16 else ba if f<.55 else mi if f<.85 else dk
                    if not on(x,y-1) and f<.7: c=hi
                elif edge:
                    if not on(x,y-1) or not on(x-1,y): c=hi
                    elif not on(x,y+1) or not on(x+1,y): c=mi
                if c is ba and noise and s.rnd.random()<noise: c=mi
                s.px[x,y]=c
    def rect(s,mat,x,y,w,h,**k): s.part(mat,lambda d:d.rectangle((x,y,x+w-1,y+h-1),fill=255),**k)
    def poly(s,mat,pts,**k): s.part(mat,lambda d:d.polygon(pts,fill=255),**k)
    def ell(s,mat,x0,y0,x1,y1,**k): s.part(mat,lambda d:d.ellipse((x0,y0,x1,y1),fill=255),**k)
    def line(s,mat,x0,y0,x1,y1,w=1,**k): s.part(mat,lambda d:d.line((x0,y0,x1,y1),fill=255,width=w),edge=False,**k)
    def dot(s,x,y,c):
        if 0<=x<s.w and 0<=y<s.h: s.px[x,y]=hx(c) if isinstance(c,str) else c
    def mat_px(s,mat,i,x,y): s.dot(x,y,MAT[mat][i])
    def rect_px(s,c,x,y,w,h):
        for j in range(h):
            for i in range(w): s.dot(x+i,y+j,c)
    def text(s,x,y,t,c,sp=1):
        from px import FONT
        for ch in t.upper():
            for j,row in enumerate(FONT.get(ch,FONT[' ']).split()):
                for i,v in enumerate(row):
                    if v=='1': s.dot(x+i,y+j,c)
            x+=3+sp
    def outline(s):
        a=s.im.copy(); ap=a.load(); big=Image.new('RGBA',(s.w+2,s.h+2),(0,0,0,0)); bp=big.load()
        for y in range(s.h):
            for x in range(s.w): bp[x+1,y+1]=ap[x,y]
        for y in range(s.h+2):
            for x in range(s.w+2):
                if bp[x,y][3]==0 and any(0<=x+dx<s.w+2 and 0<=y+dy<s.h+2 and (bp[x+dx,y+dy][3]>0 and bp[x+dx,y+dy]!=OUT) for dx,dy in((1,0),(-1,0),(0,1),(0,-1))): bp[x,y]=OUT
        s.im=big; s.w,s.h=big.size; s.px=s.im.load()
def save(im,path):
    W,H=im.size; b=io.BytesIO(); im.save(b,'PNG'); d=b.getvalue()
    def ch(t,x): return struct.pack('>I',len(x))+t+x+struct.pack('>I',zlib.crc32(t+x)&0xffffffff)
    p=8+25; open(path,'wb').write(d[:p]+ch(b'grAb',struct.pack('>ii',W//2,H))+d[p:])
