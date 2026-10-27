# Top-down preview of a generated UDMF map: python render_map.py ../CorpoWars/maps/M02.wad out.png
import re, sys
from PIL import Image, ImageDraw
d = open(sys.argv[1], "rb").read().decode("latin1"); tm = d[d.index("namespace"):]
blocks = lambda k: re.findall(k + r"\n\{\n(.*?)\}", tm, re.S)
kv = lambda b: dict((m[0], m[1].strip('"')) for m in re.findall(r"(\w+) = (.*?);", b))
V = [(float(kv(b)["x"]), float(kv(b)["y"])) for b in blocks("vertex")]
L = [kv(b) for b in blocks("linedef")]; T = [kv(b) for b in blocks("thing")]
xs = [v[0] for v in V]; ys = [v[1] for v in V]; pad = 40; S = 0.6
W = int((max(xs) - min(xs)) * S) + 2 * pad; H = int((max(ys) - min(ys)) * S) + 2 * pad
P = lambda x, y: (pad + (x - min(xs)) * S, H - pad - (y - min(ys)) * S)
im = Image.new("RGB", (W, H), (20, 22, 28)); dr = ImageDraw.Draw(im)
for l in L:
    a, b = V[int(l["v1"])], V[int(l["v2"])]
    dr.line([P(*a), P(*b)], fill=(90, 110, 130) if "sideback" in l else (230, 230, 230), width=1 if "sideback" in l else 2)
col = {"1": (0, 255, 0), "20001": (255, 60, 60), "20002": (255, 150, 150), "20024": (255, 255, 0), "20022": (200, 120, 255),
       "20020": (80, 160, 255), "20021": (80, 160, 255), "20023": (0, 200, 120), "20025": (0, 200, 200), "20115": (255, 255, 200)}
for t in T:
    x, y = P(float(t["x"]), float(t["y"])); c = col.get(t["type"], (140, 140, 140)); r = 6 if t["type"] in col else 4
    dr.ellipse([x - r, y - r, x + r, y + r], outline=c, width=2)
im.save(sys.argv[2]); print("saved", W, H)
