# Détoure les encarts de classe et les boutons (encarts/brut/*.png, fond vert, magenta pour le moine) -> encarts/*.png,
# mesure les marges 9-slice de chaque encart -> encarts/encarts.json, et monte les planches de revue.
# python cut_encarts.py [planche.png]
# python cut_encarts.py voc [planche.png]   -> seulement encart_voc_* et bandeau_* (28/09), fusionnés dans encarts.json sans toucher aux encarts validés
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import cv2

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "encarts")
BRUT = os.path.join(D, "brut")
CLASSES = ["garde", "lame", "oracle", "artificier", "moine", "trappeur", "tidiane", "receleur"]
MAGENTA = {"moine"}
# marges relevées à l'œil (encarts/planche_guides) là où la mesure rate : volutes sombres sur fond sombre (lame),
# perles fines sous les disques de jade (moine). À refaire si le brut change.
MANUEL = {"lame": (130, 170, 130, 130), "moine": (134, 197, 134, 132),
	"tidiane": (90, 170, 90, 95), "guilde_artificier_tidiane": (102, 154, 102, 130), "guilde_oracle_tidiane": (78, 110, 78, 130),  # v5 du 29/09 (le peintre), ramené à 633 px de large : les coups de pinceau trompent la mesure
	"encart_voc_moine": (85, 142, 85, 100)}  # voc : la mesure prend la bande de bas de la moulure pour un ornement


def key(a, magenta):
	## alpha par distance à la couleur de fond (comme cut_ui.key), dévert/démagenta sur un liseré de 3 px autour du détourage seulement
	## magenta : True (fond magenta), False (vert), "bleu" (fond bleu, paire Moine + Tidiane)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	k = b - np.maximum(r, g) if magenta == "bleu" else (np.minimum(r, b) - g if magenta else g - np.maximum(r, b))
	alpha = np.clip(1.0 - (k - 40) / 90.0, 0, 1)
	solid = alpha > 0.12
	n, lab, st, _ = cv2.connectedComponentsWithStats(solid.astype(np.uint8), connectivity=8)
	big = st[1:, cv2.CC_STAT_AREA].max()
	alpha = alpha * np.isin(lab, [i for i in range(1, n) if st[i, cv2.CC_STAT_AREA] > big * 0.002])  # poussières du fond
	edge = cv2.dilate((alpha < 1).astype(np.uint8), np.ones((7, 7), np.uint8)).astype(bool) & (k > 0)
	a = a.copy()
	if magenta == "bleu":
		a[..., 2] = np.where(edge, np.maximum(r, g), b)
	elif magenta:
		a[..., 0] = np.where(edge, r - k, r)
		a[..., 2] = np.where(edge, b - k, b)
	else:
		a[..., 1] = np.where(edge, np.maximum(r, b), g)
	rgba = np.dstack([a, alpha * 255]).clip(0, 255).astype(np.uint8)
	ys, xs = np.nonzero(rgba[..., 3] > 8)
	return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def plain(v, ref):
	## écart d'un pixel (ou d'un profil) au modèle « bord lisse » : rgb prémultiplié + alpha
	return np.abs(v - ref).max(axis=-1)


def measure(rgba, key_=None, thr=38):
	## Marges 9-slice : épaisseur du bord lisse au milieu de chaque côté, puis extension des ornements de coin
	## (tout pixel qui ne ressemble ni à la coupe du bord de son côté ni à l'intérieur).
	h, w = rgba.shape[:2]
	p = rgba.astype(float)
	p[..., :3] *= p[..., 3:] / 255
	mid = lambda lo, hi, n: slice(int(lo * n), int(hi * n))
	# coupes des bords, prises loin des coins et du cimier
	cl = np.median(p[mid(.4, .6, h), :w // 4], axis=0)
	cr = np.median(p[mid(.4, .6, h), w - w // 4:], axis=0)
	ct = np.median(np.concatenate([p[:h // 4, mid(.22, .36, w)], p[:h // 4, mid(.64, .78, w)]], axis=1), axis=1)
	cb = np.median(p[h - h // 4:, mid(.3, .7, w)], axis=1)

	def thick(prof):  # du dedans vers le dehors : premier pixel qui n'est plus l'intérieur local
		ref = prof[-max(4, len(prof) // 5)]
		dev = plain(prof, ref) > thr
		i = len(prof) - 1
		while i > 0 and not dev[i]:
			i -= 1
		return i + 1
	bl, br, bt, bb = thick(cl), thick(cr[::-1]), thick(ct), thick(cb[::-1])

	# ornement = tout pixel qui ne ressemble ni à la coupe du bord de son côté, ni à l'intérieur (étiré depuis le bloc central :
	# vignettage, lueur), nettoyé de ses traits fins (la lumière qui varie le long d'un bord n'est pas un ornement)
	x0, y0, x1, y1 = bl, bt, w - br, h - bb
	mx, my = int((x1 - x0) * .2), int((y1 - y0) * .2)
	blk = cv2.resize(p[y0 + my:y1 - my, x0 + mx:x1 - mx], (6, 8), interpolation=cv2.INTER_AREA)
	field = np.broadcast_to(np.median(blk.reshape(-1, 4), axis=0), p.shape).copy()
	field[y0:y1, x0:x1] = cv2.resize(blk, (x1 - x0, y1 - y0), interpolation=cv2.INTER_LINEAR)
	dev = plain(p, field)
	q, r = w // 4, h // 4
	dev[:, :q] = np.minimum(dev[:, :q], plain(p[:, :q], cl[None]))
	dev[:, w - q:] = np.minimum(dev[:, w - q:], plain(p[:, w - q:], cr[None]))
	dev[:r] = np.minimum(dev[:r], plain(p[:r], ct[:, None]))
	dev[h - r:] = np.minimum(dev[h - r:], plain(p[h - r:], cb[:, None]))
	orn = cv2.morphologyEx((dev > thr).astype(np.uint8), cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
	n, lab, st, _ = cv2.connectedComponentsWithStats(orn, connectivity=8)
	# un bord peint à la main penche d'un ou deux pixels : ses traits longs et fins ne sont pas des ornements
	bw, bh = st[:, cv2.CC_STAT_WIDTH], st[:, cv2.CC_STAT_HEIGHT]
	lab[np.isin(lab, np.nonzero((np.minimum(bw, bh) <= 12) & (np.maximum(bw, bh) > 5 * np.minimum(bw, bh)))[0])] = 0
	orn = (lab > 0).astype(np.uint8)
	# ornement de coin = composantes qui touchent le carré où les deux bandes de bord se croisent (+5 %)
	ex, ey = int(.05 * w), int(.05 * h)
	zones = {"tl": (0, 0, bl + ex, bt + ey), "tr": (w - br - ex, 0, w, bt + ey),
		"bl": (0, h - bb - ey, bl + ex, h), "br": (w - br - ex, h - bb - ey, w, h)}
	box = {}
	for z, (zx0, zy0, zx1, zy1) in zones.items():
		ids = set(np.unique(lab[zy0:zy1, zx0:zx1])) - {0}
		ids = [i for i in ids if st[i, cv2.CC_STAT_AREA] >= 40]
		if not ids:
			box[z] = (zx0, zy0, zx1, zy1)
			continue
		m = np.isin(lab, ids)
		m[:, int(w * .4):int(w * .6)] = False  # un coin ne déborde pas sur le milieu (cimier, fleuron)
		m[int(h * .4):int(h * .6)] = False
		ys, xs = np.nonzero(m)
		box[z] = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
	L = max(bl, box["tl"][2], box["bl"][2])
	R = max(br, w - box["tr"][0], w - box["br"][0])
	T = max(bt, box["tl"][3], box["tr"][3])
	B = max(bb, h - box["bl"][1], h - box["br"][1])
	# cimier : composantes du haut entre les deux coins
	cm = orn[:r, L:w - R]
	crest = None
	ys, xs = np.nonzero(cm)
	if len(xs):
		n2, lab2, st2, _ = cv2.connectedComponentsWithStats(cm, connectivity=8)
		lo, hi = int(w * .45) - L, int(w * .55) - L  # le cimier passe par le milieu
		ids = [i for i in range(1, n2) if st2[i, cv2.CC_STAT_AREA] >= 80
			and st2[i, cv2.CC_STAT_LEFT] < hi and st2[i, cv2.CC_STAT_LEFT] + st2[i, cv2.CC_STAT_WIDTH] > lo]
		if ids:
			ys, xs = np.nonzero(np.isin(lab2, ids))
			crest = [L + xs.min(), 0, L + xs.max() + 1, ys.max() + 1]
			T = max(T, crest[3])
	L = R = max(L, R)  # les coins sont peints en miroir : le plus grand des deux côtés vaut pour les deux
	pad = 8
	L, T, R, B = [int(min(v + pad, s * .45)) for v, s in zip((L, T, R, B), (w, h, w, h))]
	L, T, R, B = MANUEL.get(key_, (L, T, R, B))
	f = lambda v, s: round(v / s, 4)
	return {"size": [w, h], "marges": [L, T, R, B], "bord": [bl, bt, br, bb],
		"interieur": [f(bl, w), f(bt, h), f(w - br, w), f(h - bb, h)],
		"sur": [f(L, w), f(T, h), f(w - R, w), f(h - B, h)],
		"cimier": [f(crest[0], w), f(crest[1], h), f(crest[2], w), f(crest[3], h)] if crest else None}


def font(sz):
	for f in ("C:/Windows/Fonts/georgiab.ttf", "C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arial.ttf"):
		if os.path.exists(f):
			return ImageFont.truetype(f, sz)
	return ImageFont.load_default()


def sheet(items, out, guides=None):
	## planche sombre étiquetée : 8 encarts en 2 × 4, les deux boutons dessous
	cw, ch, pad, lab = 300, 400, 36, 34
	W = 4 * cw + 5 * pad
	H = 2 * (ch + lab) + 3 * pad + 170 + lab + pad
	S = Image.new("RGB", (W, H), (14, 11, 18))
	d = ImageDraw.Draw(S)
	fo = font(22)
	for i, (name, im) in enumerate(items):
		if i < 8:
			bx, by, bw, bh = pad + (i % 4) * (cw + pad), pad + (i // 4) * (ch + lab + pad), cw, ch
		else:
			bw, bh = (W - 3 * pad) // 2, 170
			bx, by = pad + (i - 8) * (bw + pad), pad + 2 * (ch + lab + pad)
		s = min(bw / im.width, bh / im.height)
		t = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
		ox, oy = bx + (bw - t.width) // 2, by + (bh - t.height) // 2
		S.paste(t, (ox, oy), t)
		if guides and "marges" in guides.get(name, {}):
			L, T, R, B = [v * s for v in guides[name]["marges"]]
			col = (255, 190, 90)
			for x in (ox + L, ox + t.width - R):
				d.line([(x, oy), (x, oy + t.height)], fill=col, width=1)
			for y in (oy + T, oy + t.height - B):
				d.line([(ox, y), (ox + t.width, y)], fill=col, width=1)
			x0, y0, x1, y1 = guides[name]["interieur"]
			d.rectangle([ox + x0 * t.width, oy + y0 * t.height, ox + x1 * t.width, oy + y1 * t.height], outline=(230, 110, 170))
		tw = d.textlength(name, font=fo)
		d.text((bx + (bw - tw) / 2, by + bh + 6), name, fill=(236, 214, 190), font=fo)
	S.save(out)


def planche_voc(meta, out, guides=False):
	## deux classes par ligne ; par classe : l'encart validé, l'encart_voc (même hauteur), le bandeau (300 px de large)
	ch, bw, pad, lab, fo, fs = 320, 300, 26, 26, font(24), font(17)
	W, bh = 2 * (pad + 230 + 150 + bw + 3 * pad), ch + 2 * lab + pad
	S = Image.new("RGB", (W, pad + 4 * bh), (14, 11, 18))
	d = ImageDraw.Draw(S)
	for i, c in enumerate(CLASSES):
		x, y = pad + (i % 2) * (W // 2), pad + (i // 2) * bh
		d.text((x, y), c, fill=(255, 214, 150), font=fo)
		y += lab + 4
		for n, tag in (("encart_%s" % c, "validé"), ("encart_voc_%s" % c, "voc"), ("bandeau_%s" % c, "bandeau")):
			im = Image.open(os.path.join(D, n + ".png"))
			s = bw / im.width if tag == "bandeau" else ch / im.height
			t = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
			oy = y + (ch - t.height) // 2
			S.paste(t, (x, oy), t)
			if guides and "marges" in meta.get(n, {}):
				L, T, R, B = [v * s for v in meta[n]["marges"]]
				for gx in (x + L, x + t.width - R):
					d.line([(gx, oy), (gx, oy + t.height)], fill=(255, 190, 90))
				for gy in (oy + T, oy + t.height - B):
					d.line([(x, gy), (x + t.width, gy)], fill=(255, 190, 90))
				x0, y0, x1, y1 = meta[n]["interieur"]
				d.rectangle([x + x0 * t.width, oy + y0 * t.height, x + x1 * t.width, oy + y1 * t.height], outline=(230, 110, 170))
			tw = d.textlength(tag, font=fs)
			d.text((x + (t.width - tw) / 2, oy + t.height + 4), tag, fill=(236, 214, 190), font=fs)
			x += t.width + pad
	S.save(out)


if __name__ == "__main__" and sys.argv[1:2] == ["voc"]:
	meta = json.load(open(os.path.join(D, "encarts.json")))
	for c in CLASSES:
		for name in ("encart_voc_%s" % c, "bandeau_%s" % c):
			a = np.asarray(Image.open(os.path.join(BRUT, name + ".png")).convert("RGB")).astype(float)
			rgba = key(a, c in MAGENTA)
			Image.fromarray(rgba).save(os.path.join(D, name + ".png"))
			meta[name] = measure(rgba, name)
			print(name, json.dumps(meta[name]))
	json.dump(meta, open(os.path.join(D, "encarts.json"), "w"), indent=1)
	out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(D, "planche_voc.png")
	planche_voc(meta, out)
	planche_voc(meta, out.replace(".png", "_guides.png"), True)
	print(out)
elif __name__ == "__main__" and sys.argv[1:2] == ["neutres"]:
	# panneaux neutres (28/09) : neutre_annonce, neutre_panneau, neutre_risque, neutre_gain -> encarts.json
	meta = json.load(open(os.path.join(D, "encarts.json")))
	for f in sorted(os.listdir(BRUT)):
		name = f[:-4]
		if not name.startswith("neutre_"):
			continue
		rgba = key(np.asarray(Image.open(os.path.join(BRUT, f)).convert("RGB")).astype(float), False)
		Image.fromarray(rgba).save(os.path.join(D, f))
		meta[name] = measure(rgba, name)
		if name in ("neutre_risque", "neutre_gain"):
			# fermoirs à mi-hauteur : marges verticales au ras du bord, la plaque est réduite à la hauteur de son contenu
			b, mg = meta[name]["bord"], meta[name]["marges"]
			meta[name]["marges"] = [mg[0], b[1] + 14, mg[2], b[3] + 14]
		print(name, json.dumps(meta[name]))
	json.dump(meta, open(os.path.join(D, "encarts.json"), "w"), indent=1)
elif __name__ == "__main__" and sys.argv[1:2] == ["guildes"]:
	# guilde_<a>_<b> (un encart par guilde), bouton_action, encart_option : fusionnés dans encarts.json
	meta = json.load(open(os.path.join(D, "encarts.json")))
	items = []
	for f in sorted(os.listdir(BRUT)):
		name = f[:-4]
		if not (name.startswith("guilde_") or name in ("bouton_action", "encart_option")):
			continue
		pair = name[7:].split("_") if name.startswith("guilde_") else []
		chroma = "bleu" if pair == ["moine", "tidiane"] else ("moine" in pair)
		rgba = key(np.asarray(Image.open(os.path.join(BRUT, f)).convert("RGB")).astype(float), chroma)
		im = Image.fromarray(rgba)
		im.save(os.path.join(D, f))
		items.append((name, im))
		if name == "bouton_action":
			# bouton étirable : les pointes aux deux bouts, le milieu uni ; marges = pointes + un peu
			h, w = rgba.shape[:2]
			meta[name] = {"size": [w, h], "marges": [int(h * 0.62), int(h * 0.3), int(h * 0.62), int(h * 0.3)], "bord": [int(h * 0.5), int(h * 0.2), int(h * 0.5), int(h * 0.2)]}
		else:
			meta[name] = measure(rgba, name)
		print(name, json.dumps(meta[name]))
	json.dump(meta, open(os.path.join(D, "encarts.json"), "w"), indent=1)
elif __name__ == "__main__":
	meta, items = {}, []
	for k in CLASSES + ["equipement", "paquet"]:
		enc = k in CLASSES
		name = ("encart_%s" if enc else "bouton_%s") % k
		a = np.asarray(Image.open(os.path.join(BRUT, name + ".png")).convert("RGB")).astype(float)
		rgba = key(a, k in MAGENTA)
		im = Image.fromarray(rgba)
		im.save(os.path.join(D, name + ".png"))
		items.append((name, im))
		meta[name] = measure(rgba, k) if enc else {"size": [rgba.shape[1], rgba.shape[0]]}
		print(name, json.dumps(meta[name]))
	json.dump(meta, open(os.path.join(D, "encarts.json"), "w"), indent=1)
	out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, "planche.png")
	sheet(items, out)
	sheet(items, out.replace(".png", "_guides.png"), meta)
	print(out)
