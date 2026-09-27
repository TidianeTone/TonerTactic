# Détoure les boîtes de dialogue et les cadres de barres de vie (fond vert) -> assets/ui/boite_*.png, barre_*.png + boites.json (zone de texte / tube, en fractions)
import os, json
import numpy as np
from PIL import Image
import cv2


def label(m):
    n, lab = cv2.connectedComponents(m.astype(np.uint8), connectivity=4)
    return lab, n - 1


def sums(m, lab, n):
    return np.bincount(lab.ravel(), weights=m.ravel().astype(float), minlength=n + 1)[1:]


K3 = np.ones((3, 3), np.uint8)
D = os.path.dirname(__file__)
UI = os.path.join(D, "..", "..", "assets", "ui")
out = {}
for f in sorted(os.listdir(os.path.join(D, "boites"))):
    if not f.endswith(".png"):
        continue
    k = f[:-4]
    a = np.asarray(Image.open(os.path.join(D, "boites", f)).convert("RGB")).astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    green = (g > 140) & (g - np.maximum(r, b) > 60)
    green = cv2.dilate(green.astype(np.uint8), K3, iterations=1).astype(bool)
    solid = ~green
    lab, n = label(solid)
    sizes = sums(solid, lab, n)
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > sizes.max() * 0.002])
    ys, xs = np.nonzero(keep)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgba = np.dstack([a, np.where(keep, 255, 0)]).astype(np.uint8)[y0:y1, x0:x1]
    # le vert qui bave sur les bords : ramené vers le gris
    e = rgba[..., :3].astype(np.int32)
    spill = e[..., 1] > np.maximum(e[..., 0], e[..., 2])
    e[..., 1] = np.where(spill, np.maximum(e[..., 0], e[..., 2]), e[..., 1])
    rgba[..., :3] = e.astype(np.uint8)
    h, w = rgba.shape[:2]
    if k == "vignette":  # cadre de vignette : zones mesurées à l'œil (bandeau 1,5-11 %, séparateur à 55,7 %)
        yy, xx = np.array([0, h - 1]), np.array([0, w - 1])
        name = k
    elif k.startswith("barre"):
        hole = ~keep[y0:y1, x0:x1]
        hl, hn = label(hole)
        border = set(np.unique(np.concatenate([hl[0], hl[-1], hl[:, 0], hl[:, -1]])))
        hs = sums(hole, hl, hn)
        cand = [(hs[i - 1], i) for i in range(1, hn + 1) if i not in border]
        i = max(cand)[1]
        yy, xx = np.nonzero(hl == i)
        name = k
    else:
        lum = rgba[..., :3].mean(axis=2)
        dark = (lum < 55) & (rgba[..., 3] > 0)
        dark = cv2.morphologyEx(dark.astype(np.uint8), cv2.MORPH_OPEN, K3, iterations=3).astype(bool)
        dl, dn = label(dark)
        i = dl[h // 2, w // 2] or (np.argmax(sums(dark, dl, dn)) + 1)
        yy, xx = np.nonzero(dl == i)
        name = "boite_" + k
    out[name] = {"inner": [round(xx.min() / w, 4), round(yy.min() / h, 4), round((xx.max() + 1) / w, 4), round((yy.max() + 1) / h, 4)], "size": [w, h]}
    s = min(1.0, (360 if k == "vignette" else 900) / w)
    Image.fromarray(rgba).resize((int(w * s), int(h * s)), Image.LANCZOS).save(os.path.join(UI, name + ".png"))
    print(name, out[name])
json.dump(out, open(os.path.join(D, "boites", "boites.json"), "w"), indent=1)  # zones recopiées dans UI.BOITES

# barre du boss : le tube (milieu uniforme, étirable) et l'ornement (ailes et crâne, taille fixe) séparés
im = np.asarray(Image.open(os.path.join(UI, "barre_boss.png")).convert("RGBA")).copy()
h, w = im.shape[:2]
x0, y0, x1, y1 = out["barre_boss"]["inner"]
bt = int((1 - y1) * h)
top = int(y0 * h) - bt
tube = im[top:].copy()
l, r = int((x0 + 0.02) * w), int((x1 - 0.02) * w)
tube[:, l:r] = np.repeat(tube[:, int((x0 + 0.03) * w):int((x0 + 0.03) * w) + 1], r - l, axis=1)
Image.fromarray(tube).save(os.path.join(UI, "barre_boss_tube.png"))
ys, xs = np.nonzero(im[:top, :, 3] > 10)
orn = im[:top + bt].copy()
orn[top:, :w // 2 - int(0.1 * w), 3] = 0
orn[top:, w // 2 + int(0.1 * w):, 3] = 0
Image.fromarray(orn[:, xs.min():xs.max() + 1]).save(os.path.join(UI, "barre_boss_orn.png"))
os.remove(os.path.join(UI, "barre_boss.png"))
print("tube", tube.shape[1], tube.shape[0], "tube inner y", round((int(y0 * h) - top) / tube.shape[0], 3), round((int(y1 * h) - top) / tube.shape[0], 3), "caps", round(x0 * w), round((1 - x1) * w))
