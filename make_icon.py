import os, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 1024
L = [(72,48),(55,0),(38,60),(18,95),(30,120),(22,150),(55,150),(72,185),(88,195)]

def head(sc, ox, oy):
    pts = [(100,55)] + L + [(100,198)] + [(200-x, y) for x, y in reversed(L)]
    return [(ox + x*sc, oy + y*sc) for x, y in pts]

def eye(sc, ox, oy, mirror):
    e = [(56,98),(86,108),(62,111)]
    if mirror:
        e = [(200-x, y) for x, y in e]
    return [(ox + x*sc, oy + y*sc) for x, y in e]

img = Image.new("RGB", (S, S), (10, 0, 0))
d = ImageDraw.Draw(img)
random.seed(7)
d.rectangle([0, 0, S, 70], fill=(120, 0, 0))
for i in range(9):
    x = 40 + i * 115 + random.randint(-20, 20)
    w = random.randint(26, 44)
    ln = random.randint(120, 300)
    d.rounded_rectangle([x, 0, x + w, ln], radius=w // 2, fill=(139, 0, 0))

sc = 3.7
ox, oy = (S - 200 * sc) / 2, (S - 200 * sc) / 2 + 60
d.polygon(head(sc, ox, oy), fill=(28, 28, 28), outline=(213, 0, 0), width=14)

glow = Image.new("RGB", (S, S), (0, 0, 0))
g = ImageDraw.Draw(glow)
for m in (False, True):
    g.polygon(eye(sc, ox, oy, m), fill=(255, 40, 40))
glow = glow.filter(ImageFilter.GaussianBlur(14))
img = ImageChops.add(img, glow)
d = ImageDraw.Draw(img)
for m in (False, True):
    d.polygon(eye(sc, ox, oy, m), fill=(255, 60, 60))

os.makedirs("assets", exist_ok=True)
img.save("assets/icon.png")
