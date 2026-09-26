# Découpe des planches d'équipement (gen_items.py) : case par case, détourage du vert, recadrage carré,
# puis une vraie grille de pixels (64 px, alpha net) agrandie ×2 -> assets/ui/item_<id>.png
# Aussi le dos de carte -> assets/ui/dos_carte.png
import os, json
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "ui")
ITEMS = os.path.join(HERE, "items")
N = 4
PX = 64


def key(a):
	a = a.astype(float)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	green = g - np.maximum(r, b)
	alpha = np.clip(1.0 - (green - 40) / 90.0, 0, 1)
	g2 = np.where(green > 0, np.maximum(r, b) + np.minimum(green, 0), g)
	return np.dstack([r, g2, b, alpha * 255]).astype(np.uint8)


def pixelize(c):
	import cv2
	m = (c[..., 3] > 60).astype(np.uint8)
	n, lab, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
	if n <= 1:
		return None
	big = st[1:, 4].max()
	keep = [k for k in range(1, n) if st[k, 4] >= big * 0.03]  # les poussières de vert mal détouré ne comptent pas
	m = np.isin(lab, keep)
	c = c.copy()
	c[..., 3] = np.where(m, c[..., 3], 0)
	ys, xs = np.nonzero(m)
	c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	h, w = c.shape[:2]
	s = int(max(h, w) * 1.08)
	sq = np.zeros((s, s, 4), np.uint8)
	sq[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = c
	im = Image.fromarray(sq).resize((PX, PX), Image.BOX)
	a = np.asarray(im).copy()
	a[..., 3] = np.where(a[..., 3] > 110, 255, 0)  # bord net, comme du vrai pixel art
	return Image.fromarray(a).resize((PX * 2, PX * 2), Image.NEAREST)


def segs(profile, n):
	## Les n plus larges bandes pleines, séparées par des couloirs vides ; à défaut, une grille régulière.
	full = profile > profile.max() * 0.01
	out, start = [], None
	for i, f in enumerate(list(full) + [False]):
		if f and start is None:
			start = i
		elif not f and start is not None:
			out.append((start, i))
			start = None
	out = sorted(sorted(out, key=lambda q: q[1] - q[0], reverse=True)[:n])
	if len(out) != n:
		L = len(profile)
		return [(L * k // n, L * (k + 1) // n) for k in range(n)]
	# on élargit chaque bande jusqu'au milieu des couloirs voisins
	cuts = [0] + [(out[k][1] + out[k + 1][0]) // 2 for k in range(n - 1)] + [len(profile)]
	return [(cuts[k], cuts[k + 1]) for k in range(n)]


batches = json.load(open(os.path.join(ITEMS, "batches.json")))
for k, b in enumerate(batches):
	p = os.path.join(ITEMS, "sheet_%02d.png" % k)
	if not os.path.exists(p):
		print("planche manquante", k)
		continue
	arr = key(np.asarray(Image.open(p).convert("RGB")))
	H, W = arr.shape[:2]
	# la grille peinte n'est pas régulière : on coupe dans les couloirs vides (profils d'alpha)
	xs, ys = segs(arr[..., 3].sum(axis=0), N), segs(arr[..., 3].sum(axis=1), N)
	for i, id in enumerate(b):
		r, c = divmod(i, N)
		cell = arr[ys[r][0]:ys[r][1], xs[c][0]:xs[c][1]]
		im = pixelize(cell)
		if im is None:
			print("case vide", id)
			continue
		im.save(os.path.join(OUT, "item_%s.png" % id))
	print("planche", k, "ok")
dos = os.path.join(HERE, "dos_carte.png")
if os.path.exists(dos):
	d = np.asarray(Image.open(dos).convert("RGB")).astype(int)
	white = (d.min(axis=2) > 225)
	ys, xs = np.nonzero(~white)
	d = d[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	a = np.where(d.min(axis=2) > 225, 0, 255)  # coins arrondis : le blanc devient transparent
	im = Image.fromarray(np.dstack([d, a]).astype(np.uint8))
	im.resize((392, 544), Image.LANCZOS).save(os.path.join(OUT, "dos_carte.png"))
	print("dos ok")

# dos de carte par classe (gen_items.py dos_classes) : planche 3x3 sur vert -> assets/ui/dos_<classe>.png
DOS = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur", "objet"]
TINT = {"garde": (61, 99, 224), "lame": (224, 52, 79), "oracle": (155, 80, 216), "artificier": (34, 184, 166), "moine": (108, 194, 74),
	"trappeur": (201, 162, 58), "tidiane": (208, 64, 154), "receleur": (159, 180, 194), "objet": (230, 184, 79)}
pl = os.path.join(HERE, "dos_classes.png")
if os.path.exists(pl):
	a = np.asarray(Image.open(pl).convert("RGB"))
	H, W = a.shape[:2]
	for i, k in enumerate(DOS):
		c = key(a[(i // 3) * H // 3:(i // 3 + 1) * H // 3, (i % 3) * W // 3:(i % 3 + 1) * W // 3])
		ys, xs = np.nonzero(c[..., 3] > 60)
		c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
		# l'intérieur peint en vert devient un fond sombre à la couleur de la classe, avec un halo derrière l'emblème
		h, w = c.shape[:2]
		yy, xx = np.mgrid[0:h, 0:w]
		d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h * 0.46) / (h / 2)) ** 2)
		col = np.array(TINT[k], float)
		base = (col * 0.16)[None, None, :] + (col * 0.32)[None, None, :] * np.clip(1.0 - d, 0, 1)[..., None] ** 1.6
		base += ((xx + yy) % 14 < 1)[..., None] * col * 0.05  # fines hachures
		import cv2
		# l'intérieur = les zones transparentes enfermées par le cadre (celles qui ne touchent pas le bord), un peu dilatées sous le cadre
		n, lab, st, _ = cv2.connectedComponentsWithStats((c[..., 3] < 128).astype(np.uint8), connectivity=4)
		inside = np.zeros((h, w), bool)
		for q in range(1, n):
			x0, y0, ww, hh, ar = st[q]
			if x0 > 0 and y0 > 0 and x0 + ww < w and y0 + hh < h and ar > h * w * 0.01:
				inside |= lab == q
		inside = cv2.dilate(inside.astype(np.uint8), np.ones((9, 9), np.uint8)) > 0
		# les bouts de la case voisine : seule la plus grande pièce opaque (le cadre) reste
		n2, lab2, st2, _ = cv2.connectedComponentsWithStats((c[..., 3] > 60).astype(np.uint8), connectivity=8)
		if n2 > 2:
			big = 1 + int(np.argmax(st2[1:, 4]))
			keep = np.isin(lab2, [big] + [q for q in range(1, n2) if st2[q, 4] > st2[big, 4] * 0.02 and q != big and not (st2[q, 0] <= 1 or st2[q, 1] <= 1 or st2[q, 0] + st2[q, 2] >= w - 1 or st2[q, 1] + st2[q, 3] >= h - 1)])
			c = c.copy()
			c[..., 3] = np.where(keep | inside, c[..., 3], 0)
		al = c[..., 3:4] / 255.0
		out = np.where(inside[..., None], base * (1 - al) + c[..., :3] * al, c[..., :3])
		alpha = np.where(inside, 255, c[..., 3])
		Image.fromarray(np.dstack([np.clip(out, 0, 255), alpha]).astype(np.uint8)).resize((392, 544), Image.LANCZOS).save(os.path.join(OUT, "dos_%s.png" % k))
	print("dos par classe ok")
