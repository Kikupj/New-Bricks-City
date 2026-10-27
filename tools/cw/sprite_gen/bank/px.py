import struct, zlib, io
from PIL import Image
FONT = {
'A':"010 101 111 101 101",'B':"110 101 110 101 110",'C':"011 100 100 100 011",'D':"110 101 101 101 110",
'E':"111 100 110 100 111",'F':"111 100 110 100 100",'G':"011 100 101 101 011",'H':"101 101 111 101 101",
'I':"111 010 010 010 111",'J':"001 001 001 101 010",'K':"101 101 110 101 101",'L':"100 100 100 100 111",
'M':"101 111 111 101 101",'N':"110 101 101 101 101",'O':"010 101 101 101 010",'P':"110 101 110 100 100",
'Q':"010 101 101 111 011",'R':"110 101 110 101 101",'S':"011 100 010 001 110",'T':"111 010 010 010 010",
'U':"101 101 101 101 111",'V':"101 101 101 101 010",'W':"101 101 111 111 101",'X':"101 101 010 101 101",
'Y':"101 101 010 010 010",'Z':"111 001 010 100 111",'0':"111 101 101 101 111",'1':"010 110 010 010 111",
'2':"110 001 010 100 111",'3':"110 001 110 001 110",'4':"101 101 111 001 001",'5':"111 100 110 001 110",
'6':"011 100 111 101 111",'7':"111 001 010 010 010",'8':"111 101 111 101 111",'9':"111 101 111 001 110",
'!':"010 010 010 000 010",'-':"000 000 111 000 000",'.':"000 000 000 000 010",'$':"011 110 010 011 110",' ':"000 000 000 000 000",
}
def hexc(h):
    h=h.lstrip('#'); return (int(h[0:2],16),int(h[2:4],16),int(h[4:6],16),255)
class Img:
    def __init__(s,w,h): s.w,s.h=w,h; s.d=[[None]*w for _ in range(h)]
    def p(s,x,y,c):
        if 0<=x<s.w and 0<=y<s.h: s.d[y][x]=hexc(c) if isinstance(c,str) else c
    def g(s,x,y): return s.d[y][x] if 0<=x<s.w and 0<=y<s.h else None
    def r(s,x,y,w,h,c):
        for j in range(h):
            for i in range(w): s.p(x+i,y+j,c)
    def box(s,x,y,w,h,c):
        s.r(x,y,w,1,c); s.r(x,y+h-1,w,1,c); s.r(x,y,1,h,c); s.r(x+w-1,y,1,h,c)
    def line(s,x0,y0,x1,y1,c):
        n=max(abs(x1-x0),abs(y1-y0),1)
        for i in range(n+1): s.p(round(x0+(x1-x0)*i/n),round(y0+(y1-y0)*i/n),c)
    def disc(s,cx,cy,rx,ry,c):
        for j in range(s.h):
            for i in range(s.w):
                if ((i-cx)/max(rx,.5))**2+((j-cy)/max(ry,.5))**2<=1.0: s.p(i,j,c)
    def t(s,x,y,txt,c,sp=1):
        for ch in txt.upper():
            rows=FONT.get(ch,FONT[' ']).split()
            for j,row in enumerate(rows):
                for i,v in enumerate(row):
                    if v=='1': s.p(x+i,y+j,c)
            x+=3+sp
    @staticmethod
    def tw(txt,sp=1): return len(txt)*(3+sp)-sp
    def tc(s,cx,y,txt,c,sp=1): s.t(cx-Img.tw(txt,sp)//2,y,txt,c,sp)
    def outline(s,c='#0c0c10'):
        cc=hexc(c); new=[row[:] for row in s.d]
        for y in range(s.h):
            for x in range(s.w):
                if s.d[y][x] is None:
                    for dx,dy in((1,0),(-1,0),(0,1),(0,-1)):
                        if s.g(x+dx,y+dy) is not None: new[y][x]=cc;break
        s.d=new
    def shade(s,light=1.12,dark=.78):
        # top-left light: brighten pixels with empty above, darken with empty below
        new=[row[:] for row in s.d]
        for y in range(s.h):
            for x in range(s.w):
                c=s.d[y][x]
                if c is None: continue
                f=1
                if s.g(x,y-1) is None: f=light
                elif s.g(x,y+1) is None: f=dark
                new[y][x]=tuple(min(255,int(v*f)) for v in c[:3])+(255,)
        s.d=new
    def image(s):
        im=Image.new('RGBA',(s.w,s.h),(0,0,0,0))
        for y in range(s.h):
            for x in range(s.w):
                if s.d[y][x]: im.putpixel((x,y),s.d[y][x])
        return im
def save_png(im,path,ox,oy):
    b=io.BytesIO(); im.save(b,'PNG'); data=b.getvalue()
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    pos=8+4+4+13+4  # after IHDR
    out=data[:pos]+chunk(b'grAb',struct.pack('>ii',ox,oy))+data[pos:]
    open(path,'wb').write(out)
