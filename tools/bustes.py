# Bustes des héros en pixel art pour l'écran d'escouade, tirés des concepts validés (work/heros/choisis, work/oracle).
# Détourage du fond gris par remplissage depuis les bords, tête et épaules, palette réduite, contour sombre d'un pixel.
# python tools/bustes.py  ->  assets/ui/buste_<classe>.png (transparent ; Godot l'agrandit sans lissage)
from PIL import Image, ImageDraw, ImageFilter
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = {k: os.path.join(ROOT, "work", "heros", "choisis", k + ".png") for k in
       ["garde", "lame", "artificier", "moine", "trappeur", "tidiane", "receleur"]}
SRC["oracle"] = os.path.join(ROOT, "work", "oracle", "concept_final.png")
PX = 80        # côté du buste en pixels d'art : un peu plus fin que les icônes d'équipement
COLORS = 40    # palette par héros


def detoure(im):
    ## Le fond uni part par remplissage depuis les quatre coins (tolérance), le reste est le héros.
    rgb = im.convert("RGB")
    w, h = rgb.size
    mask = Image.new("L", (w, h), 255)
    work = rgb.copy()
    for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 2), (2, h // 2), (w - 3, h // 2)]:
        ImageDraw.floodfill(work, c, (255, 0, 255), thresh=38)
    px = work.load()
    mp = mask.load()
    bg = rgb.getpixel((2, 2))
    src = rgb.load()
    for y in range(h):
        for x in range(w):
            # le fond, et les poches de fond enfermées (entre l'arc et la corde) : couleur quasi identique au coin
            if px[x, y] == (255, 0, 255) or sum(abs(a - b) for a, b in zip(src[x, y], bg)) < 16:
                mp[x, y] = 0
    mask = mask.filter(ImageFilter.MinFilter(3))  # ronge la frange grise
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def buste(im):
    ## Tête et épaules : le haut de la silhouette, cadré carré.
    bb = im.getchannel("A").getbbox()
    x0, y0, x1, y1 = bb
    hh = (y1 - y0) * 0.46
    cx = (x0 + x1) / 2
    top = y0 - hh * 0.04
    return im.crop((int(cx - hh / 2), int(top), int(cx + hh / 2), int(top + hh)))


def pixel(im):
    small = im.resize((PX, PX), Image.LANCZOS)
    a = small.getchannel("A").point(lambda v: 255 if v > 110 else 0)
    q = small.convert("RGB").quantize(COLORS, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    q.putalpha(a)
    # contour sombre d'un pixel autour de la silhouette, comme les icônes d'équipement
    ring = a.filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", q.size, (0, 0, 0, 0))
    out.paste((22, 16, 18, 255), (0, 0), ring)
    out.alpha_composite(q)
    return out


# modèles de guilde (29/09) : le concept validé de chaque vocation (work/vocations/voc_<classe>__<vocation>/), sinon un rendu HD transparent
import glob
for d in sorted(glob.glob(os.path.join(ROOT, "work", "vocations", "voc_*__*"))):
    k = os.path.basename(d)[4:]
    if k.endswith("_sac"):
        continue
    d = d + "_sac" if os.path.isdir(d + "_sac") else d  # Tidiane + Receleur : la version au gros barda a été retenue
    f = sorted(x for x in glob.glob(os.path.join(d, "*.png")))
    if f:
        SRC[k] = f[0]
SRC.setdefault("garde__oracle", os.path.join(ROOT, "work", "art_hd", "refs", "trans_garde__oracle.png"))


if __name__ == "__main__":
    for k, p in SRC.items():
        im = Image.open(p)
        b = pixel(buste(im if im.mode == "RGBA" and im.getextrema()[3][0] == 0 else detoure(im)))
        b.save(os.path.join(ROOT, "assets", "ui", "buste_%s.png" % k))
        print("buste", k)
