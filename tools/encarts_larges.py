"""Encarts de vocation élargis pour le panneau d'aperçu (droite de l'écran de vocation).

python tools/encarts_larges.py -> assets/ui/encart_vocl_<classe>.png + dictionnaire à ajouter à ENCARTS (scripts/ui.gd)
L'encart peint fait 250 de large ; étiré à ~440 en 9-slice, son cimier s'aplatit. On l'élargit plutôt en recopiant
une colonne unie de chaque côté du cimier (aucun rééchantillonnage), marges inchangées.
"""
import os, re
import numpy as np
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, "assets", "ui")
src = open(os.path.join(ROOT, "scripts", "ui.gd"), encoding="utf-8").read()
enc = eval(re.search(r"const ENCARTS := (\{.*\})", src).group(1))
out = {}
for k, m in enc.items():
	if not k.startswith("encart_voc_"):
		continue
	a = np.asarray(Image.open(os.path.join(UI, k + ".png")).convert("RGBA")).astype(np.int32)
	h, w = a.shape[:2]
	W = max(420, 412 + m[4] + m[6])  # largeur réelle du panneau : 392 de contenu + marges + 2 × 10
	diff = np.abs(a[:, 1:] - a[:, :-1]).sum(axis=(0, 2))  # écart d'une colonne à la suivante : faible = bord uni
	lo, hi = m[0] + 2, w - m[2] - 3
	mid = w // 2
	xl = lo + int(np.argmin(diff[lo:mid - 30]))
	xr = mid + 30 + int(np.argmin(diff[mid + 30:hi]))
	n = W - w
	nl = n // 2
	cols = [a[:, :xl]] + [a[:, xl:xl + 1]] * nl + [a[:, xl:xr]] + [a[:, xr:xr + 1]] * (n - nl) + [a[:, xr:]]
	Image.fromarray(np.concatenate(cols, axis=1).astype(np.uint8)).save(os.path.join(UI, k.replace("encart_voc_", "encart_vocl_") + ".png"))
	out[k.replace("encart_voc_", "encart_vocl_")] = m
	print(k, w, "->", W, "colonnes", xl, xr)
print(", ".join('"%s": %s' % (k, v) for k, v in out.items()))
