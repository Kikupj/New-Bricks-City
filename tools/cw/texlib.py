# Corpo Wars procedural texture toolkit (numpy). Shared by make_textures.py and make_models.py.
# Goal: textures with the same kind of detail as the stock / A.D. Cop sets - material variation (fbm), baked
# light and ambient occlusion, bevelled edges, grime and wear - instead of flat colour + white noise.
# Everything is tileable (noise wraps) and deterministic (fixed seeds).
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

_rng = np.random.default_rng(1987)

def seed(s):
    global _rng
    _rng = np.random.default_rng(s)

def rng(): return _rng

# ------------------------------------------------------------------ noise
def value_noise(w, h, cell, rs=None):
    """Tileable smooth value noise in [0,1]; cell = feature size in pixels (w, h should be multiples)."""
    r = rs or _rng
    gx, gy = max(1, round(w / cell)), max(1, round(h / cell))
    g = r.random((gy, gx))
    ys = np.arange(h) * gy / h; xs = np.arange(w) * gx / w
    y0 = np.floor(ys).astype(int); x0 = np.floor(xs).astype(int)
    fy = ys - y0; fx = xs - x0
    fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
    y1 = (y0 + 1) % gy; x1 = (x0 + 1) % gx; y0 %= gy; x0 %= gx
    a = g[np.ix_(y0, x0)]; b = g[np.ix_(y0, x1)]; c = g[np.ix_(y1, x0)]; d = g[np.ix_(y1, x1)]
    top = a + (b - a) * fx[None, :]; bot = c + (d - c) * fx[None, :]
    return top + (bot - top) * fy[:, None]

def fbm(w, h, cell=32, octaves=4, gain=0.5, rs=None):
    out = np.zeros((h, w)); amp = 1.0; tot = 0.0; c = cell
    for _ in range(octaves):
        out += amp * value_noise(w, h, max(c, 1), rs); tot += amp; amp *= gain; c /= 2
    return out / tot

def white(w, h, rs=None): return (rs or _rng).random((h, w))

def stretch(n, lo=0.0, hi=1.0):
    a, b = n.min(), n.max()
    return lo + (n - a) / (b - a + 1e-9) * (hi - lo)

# ------------------------------------------------------------------ images as float arrays (h, w, 3) 0..255
def solid(w, h, col): return np.ones((h, w, 3)) * np.array(col, float)

def tint(img, mask, col, amt=1.0):
    """Blend towards col by mask*amt (mask 2D 0..1)."""
    m = (np.clip(mask, 0, 1) * amt)[..., None]
    return img * (1 - m) + np.array(col, float) * m

def mul(img, f):
    return img * (f[..., None] if np.ndim(f) == 2 else f)

def vary(img, amount, cell=24, octaves=4, rs=None):
    """Material variation: multiply brightness by 1 +- amount of fbm."""
    n = fbm(img.shape[1], img.shape[0], cell, octaves, rs=rs)
    return img * (1 + (n - 0.5) * 2 * amount)[..., None]

def grain(img, amount, rs=None):
    n = white(img.shape[1], img.shape[0], rs)
    return img * (1 + (n - 0.5) * 2 * amount)[..., None]

def rect(img, x0, y0, x1, y1, col):
    img[y0:y1 + 1, x0:x1 + 1] = col; return img

def rect_mul(img, x0, y0, x1, y1, f):
    img[y0:y1 + 1, x0:x1 + 1] *= f; return img

def bevel(img, x0, y0, x1, y1, hi=1.25, lo=0.65, w=1):
    """Raised panel edge: light top/left, dark bottom/right (light from top-left, as the stock sets)."""
    for k in range(w):
        img[y0 + k, x0 + k:x1 + 1 - k] *= hi; img[y0 + k:y1 + 1 - k, x0 + k] *= hi
        img[y1 - k, x0 + k:x1 + 1 - k] *= lo; img[y0 + k:y1 + 1 - k, x1 - k] *= lo
    return img

def inset(img, x0, y0, x1, y1, hi=1.2, lo=0.7, w=1):
    """Recessed edge (groove / inset panel): dark top/left, light bottom/right."""
    return bevel(img, x0, y0, x1, y1, lo, hi, w)

def groove_v(img, x, lo=0.62, hi=1.18, y0=0, y1=None):
    y1 = img.shape[0] if y1 is None else y1
    img[y0:y1, x % img.shape[1]] *= lo; img[y0:y1, (x + 1) % img.shape[1]] *= hi; return img

def groove_h(img, y, lo=0.62, hi=1.18, x0=0, x1=None):
    x1 = img.shape[1] if x1 is None else x1
    img[y % img.shape[0], x0:x1] *= lo; img[(y + 1) % img.shape[0], x0:x1] *= hi; return img

def vgrad(img, top, bottom, y0=0, y1=None):
    """Vertical brightness ramp (baked light / AO)."""
    y1 = img.shape[0] if y1 is None else y1
    ramp = np.linspace(top, bottom, y1 - y0)
    img[y0:y1] *= ramp[:, None, None]; return img

def hgrad(img, left, right, x0=0, x1=None):
    x1 = img.shape[1] if x1 is None else x1
    ramp = np.linspace(left, right, x1 - x0)
    img[:, x0:x1] *= ramp[None, :, None]; return img

def ao_edges(img, width=6, strength=0.25, sides="tblr"):
    """Darken towards the chosen borders (contact shadow)."""
    h, w = img.shape[:2]
    f = np.ones((h, w))
    if 't' in sides: f *= 1 - strength * np.clip(1 - np.arange(h) / width, 0, 1)[:, None]
    if 'b' in sides: f *= 1 - strength * np.clip(1 - np.arange(h)[::-1] / width, 0, 1)[:, None]
    if 'l' in sides: f *= 1 - strength * np.clip(1 - np.arange(w) / width, 0, 1)[None, :]
    if 'r' in sides: f *= 1 - strength * np.clip(1 - np.arange(w)[::-1] / width, 0, 1)[None, :]
    return img * f[..., None]

def grime(img, amount=0.25, cell=16, bottom_bias=True, rs=None):
    """Patchy dirt, heavier towards the bottom (scuffs near floors)."""
    h, w = img.shape[:2]
    n = fbm(w, h, cell, 4, rs=rs)
    m = np.clip((n - 0.55) * 3, 0, 1)
    if bottom_bias: m *= np.linspace(0.3, 1.0, h)[:, None]
    return img * (1 - amount * m)[..., None]

def speckle(img, density, col, amt=1.0, rs=None):
    m = white(img.shape[1], img.shape[0], rs) < density
    img[m] = img[m] * (1 - amt) + np.array(col, float) * amt; return img

def scratches(img, n, length, col, alpha=0.35, angle=None, rs=None):
    r = rs or _rng
    h, w = img.shape[:2]
    for _ in range(n):
        x, y = r.random() * w, r.random() * h
        a = angle if angle is not None else r.random() * math.pi
        L = length * (0.5 + r.random())
        for t in np.linspace(0, L, int(L * 1.5) + 1):
            xx, yy = int(x + math.cos(a) * t) % w, int(y + math.sin(a) * t) % h
            img[yy, xx] = img[yy, xx] * (1 - alpha) + np.array(col, float) * alpha
    return img

def brushed(w, h, base, amount=0.12, horizontal=True, rs=None):
    """Brushed metal: long anisotropic streaks."""
    r = rs or _rng
    if horizontal:
        row = fbm(1, h, 2, 3, rs=r)[:, 0] if h > 1 else np.zeros(1)
        streak = (r.random(h)[:, None] * 0.6 + row[:, None] * 0.4) * np.ones((1, w))
        streak += fbm(w, h, 32, 2, rs=r) * 0.3
    else:
        streak = (r.random(w)[None, :] * 0.6) * np.ones((h, 1)) + fbm(w, h, 32, 2, rs=r) * 0.3
    img = solid(w, h, base)
    return img * (1 + (stretch(streak) - 0.5) * 2 * amount)[..., None]

def wood(w, h, base=(104, 64, 38), ring=0.16, cell=48, along_x=True, rs=None, knots=0):
    """Warped growth-ring grain along u (or v). base = mid colour."""
    r = rs or _rng
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    warp = fbm(w, h, cell, 3, rs=r) * 10
    if along_x:
        v = yy + warp * 1.5 + np.sin(xx / w * 2 * math.pi) * 2
    else:
        v = xx + warp * 1.5 + np.sin(yy / h * 2 * math.pi) * 2
    rings = np.sin(v * 0.9) * 0.5 + np.sin(v * 0.37 + 1.3) * 0.5
    fine = fbm(w, h, 4, 2, rs=r)
    f = 1 + rings * ring + (fine - 0.5) * 0.12
    img = solid(w, h, base) * f[..., None]
    # warmer darks in the late wood
    img[..., 2] *= 1 - 0.1 * np.clip(rings, 0, 1)
    return img

def weave(w, h, base, amt=0.08):
    yy, xx = np.mgrid[0:h, 0:w]
    f = 1 + amt * (((xx + yy) % 4 < 2) * 2 - 1) * 0.5 + amt * ((xx % 2) - 0.5) * 0.5
    return solid(w, h, base) * f[..., None]

def to_image(img):
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")

def from_image(im):
    return np.asarray(im.convert("RGB")).astype(float)

def draw_on(img, fn):
    """Run a PIL ImageDraw callback on an array image; returns the new array."""
    im = to_image(img); d = ImageDraw.Draw(im); fn(d, im); return from_image(im)

def blur(img, radius):
    return from_image(to_image(img).filter(ImageFilter.GaussianBlur(radius)))

def glow(img, mask, col, radius=2, amt=0.6):
    """Add a soft bloom of col around mask (lit panels, LEDs)."""
    m = Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius))
    g = np.asarray(m).astype(float) / 255 * amt
    return img + np.array(col, float) * g[..., None]
