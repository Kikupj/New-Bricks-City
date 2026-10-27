"""Trace helper: turn a region of a reference sheet into a flat, ramp-shaded pixel sprite."""
from PIL import Image
import numpy as np
from scipy import ndimage as ndi
from lib import *
import lib
SRC=Image.open('/root/.claude/uploads/7cc15ac1-6888-56ad-93a5-bb824dfd99e2/d0f866aa-image.png').convert('RGBA')
lib.MAT['stone']=[hx(c) for c in '#f0ece4 #d0ccc4 #a8a49c #7c7872 #4c4a46'.split()]
lib.MAT['bronze']=[hx(c) for c in '#e8a868 #c08040 #90582a #603a1a #3a2210'.split()]
lib.MAT['woodf']=[hx(c) for c in '#d89a48 #b0742c #855018 #5c340e #3a2008'.split()]
lib.MAT['woodd']=[hx(c) for c in '#8a5c34 #603c1e #452a12 #2e1a0a #1a0e06'.split()]
def majority(idx,mask,n,it=1):
    for _ in range(it):
        cnt=np.stack([ndi.uniform_filter(((idx==k)&mask).astype(float),3) for k in range(n)],0)
        idx=np.where(mask,cnt.argmax(0),idx)
    return idx
def get_mask(a,key):
    r,g,b=[a[...,i].astype(float) for i in range(3)]
    if key=='navy': m=(b-(r+g)/2<18)&(a[...,3]>40)
    else: m=a[...,3]>40
    m=ndi.binary_closing(m,iterations=1)
    lab,n=ndi.label(m)
    if n>1:
        sz=ndi.sum(m,lab,range(1,n+1)); m=np.isin(lab,[i+1 for i,s in enumerate(sz) if s>=max(20,0.02*max(sz))])
    return m
def trace(box,th,ramp='stone',key=None,levels=5,ncol=12,mode='ramp',pct=(8,30,58,84),inset=0,enh=None):
    c=SRC.crop(box); a=np.array(c)
    m=get_mask(a,key); ys,xs=np.where(m); y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    a=a[y0:y1,x0:x1]; m=m[y0:y1,x0:x1]; h,w=m.shape; s=th/h; nw,nh=max(2,round(w*s)),th
    mk=np.array(Image.fromarray((m*255).astype('uint8')).resize((nw,nh),Image.BOX))>127
    rgb=a[...,:3].astype(float)*m[...,None]; 
    def rs(ch): return np.array(Image.fromarray(ch.astype('uint8')).resize((nw,nh),Image.BOX)).astype(float)
    wgt=np.maximum(np.array(Image.fromarray((m*255).astype('uint8')).resize((nw,nh),Image.BOX)).astype(float)/255,.02)
    small=np.stack([rs(rgb[...,i])/wgt for i in range(3)],-1).clip(0,255)
    out=Image.new('RGBA',(nw,nh),(0,0,0,0)); op=out.load()
    if mode=='ramp':
        lum=small.mean(-1); ed=np.percentile(lum[mk],pct); idx=np.digitize(lum,ed)   # 0 = darkest
        idx=(len(ed)-idx).clip(0,4)                                                    # 0 = hi ... 4 = deep
        idx=majority(idx,mk,5,1); R=lib.MAT[ramp]
        for y in range(nh):
            for x in range(nw):
                if mk[y,x]: op[x,y]=R[idx[y,x]]
    else:
        src_=Image.fromarray(small.astype('uint8'),'RGB')
        if enh:
            from PIL import ImageEnhance
            src_=ImageEnhance.Brightness(src_).enhance(enh[1]); src_=ImageEnhance.Contrast(src_).enhance(enh[0]); src_=ImageEnhance.Color(src_).enhance(enh[2])
        q=src_.quantize(ncol,method=Image.MEDIANCUT,dither=Image.NONE)
        pal=np.array(q.getpalette()[:ncol*3]).reshape(-1,3); idx=majority(np.array(q),mk,ncol,1)
        for y in range(nh):
            for x in range(nw):
                if mk[y,x]: op[x,y]=tuple(int(v) for v in pal[idx[y,x]])+(255,)
    return out
def as_spr(img):
    S=Spr(*img.size); S.im=img; S.px=img.load(); return S
