"""Cadres de carte (assets/ui/frame_*.png, issus de blender/kie_ui/cut_classes.py) : retouches de bord.

python tools/cadres_bords.py   (à relancer après cut_classes.py)
1. Fuites : sur la planche 3×3, un cadre voisin dépassait dans la case (bouts de pinceau sous l'Artificier,
   éclaboussures à gauche du Receleur). On ne garde que ce qui touche le cadre (à 30 px près).
2. Coupes : la peinture de Tidiane touchait le bord de sa case, tranchée net. Les côtés listés dans COUPES
   s'estompent sur quelques dizaines de pixels, en frange irrégulière (brosse sèche), au lieu d'une ligne droite.
"""
import glob, os
import numpy as np
import cv2
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, "assets", "ui")
COUPES = {"c_tidiane": "RT", "g_artificier_tidiane": "R", "g_tidiane_receleur": "T", "g_oracle_tidiane": "R"}
D = {"L": 24, "R": 24, "T": 40, "B": 40}  # largeur de la frange : sur les côtés, le bord doré du cadre est à ~25 px de la coupe


def fuites(a):
	m = (a[..., 3] > 40).astype(np.uint8)
	n, lab = cv2.connectedComponents(cv2.dilate(m, np.ones((5, 5), np.uint8)), connectivity=8)
	if n <= 2:
		return a
	big = 1 + int(np.argmax(np.bincount(lab.ravel())[1:]))
	near = cv2.dilate((lab == big).astype(np.uint8), np.ones((61, 61), np.uint8))
	keep = np.zeros(n, bool)
	for k in range(1, n):
		keep[k] = near[lab == k].any()
	a[..., 3] = np.where(keep[lab] | (lab == 0), a[..., 3], 0)
	return a


def frange(a, cote, rng):
	al = a[..., 3].astype(float)
	ys, xs = np.where(al > 40)
	H, W = al.shape
	if cote in "LR":
		edge = xs.max() if cote == "R" else xs.min()
		jitter = np.convolve(rng.uniform(0, 1, H + 40), np.ones(9) / 9, "same")[20:20 + H] * D[cote] * 0.6  # frange irrégulière
		x = np.arange(W)[None, :]
		dist = (edge - x if cote == "R" else x - edge) - jitter[:, None]
	else:
		edge = ys.max() if cote == "B" else ys.min()
		jitter = np.convolve(rng.uniform(0, 1, W + 40), np.ones(9) / 9, "same")[20:20 + W] * D[cote] * 0.6
		y = np.arange(H)[:, None]
		dist = (edge - y if cote == "B" else y - edge) - jitter[None, :]
	t = np.clip(dist / D[cote], 0, 1)
	a[..., 3] = (al * t * t * (3 - 2 * t)).astype(np.uint8)
	return a


rng = np.random.default_rng(7)
for f in sorted(glob.glob(os.path.join(UI, "frame_[cg]_*.png"))):
	k = os.path.basename(f)[6:-4]
	a = np.array(Image.open(f).convert("RGBA"))
	before = int((a[..., 3] > 40).sum())
	a = fuites(a)
	for c in COUPES.get(k, ""):
		a = frange(a, c, rng)
	after = int((a[..., 3] > 40).sum())
	if after != before:
		Image.fromarray(a).save(f)
		print(k, before - after, "px retirés", COUPES.get(k, ""))
