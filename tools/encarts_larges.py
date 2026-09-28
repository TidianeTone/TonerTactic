"""Encarts de vocation et de guilde élargis (panneau d'aperçu de la vocation, écran des paquets multiclasses).

python tools/encarts_larges.py -> assets/ui/encart_vocl_<classe>.png, guildel_<a>_<b>.png, écrits dans ENCARTS (scripts/ui.gd)
9e et 10e valeurs : ce qui dépasse au-dessus et au-dessous de la ligne du cadre (ui.encart le fait déborder : les cadres s'alignent sur leurs lignes).
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
	if not (k.startswith("encart_voc_") or k.startswith("guilde_")):
		continue
	dst = k.replace("encart_voc_", "encart_vocl_") if k.startswith("encart_voc_") else k.replace("guilde_", "guildel_")
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
	Image.fromarray(np.concatenate(cols, axis=1).astype(np.uint8)).save(os.path.join(UI, dst + ".png"))
	wide = np.concatenate(cols, axis=1)
	band = range(int(W * 0.24), int(W * 0.38))  # entre le coin et le cimier : le bord y est uni ; médiane contre les ornements
	haut = int(np.median([np.argmax(wide[:, x, 3] > 128) for x in band]))
	bas = int(np.median([np.argmax(wide[::-1, x, 3] > 128) for x in band]))
	out[dst] = list(m[:8]) + [haut, bas]
	print(k, w, "->", W, "colonnes", xl, xr)
for k in [k for k in enc if k.startswith("encart_vocl_") or k.startswith("guildel_")]:
	del enc[k]
enc.update(out)
line = "const ENCARTS := {" + ", ".join('"%s": %s' % (k, v) for k, v in enc.items()) + "}"
src = re.sub(r"const ENCARTS := \{.*\}", lambda _: line, src, count=1)
open(os.path.join(ROOT, "scripts", "ui.gd"), "w", encoding="utf-8", newline=chr(10)).write(src)
print(len(out), "encarts élargis écrits dans ENCARTS")
