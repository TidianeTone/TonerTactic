"""Encarts de classe et boutons (KIE, blender/kie_ui/encarts) réduits pour l'interface -> assets/ui/.

python tools/encarts.py [--dry]   -> écrit le dictionnaire ENCARTS dans scripts/ui.gd (--dry : l'imprime seulement)
Marges 9-slice et bord uni mis à l'échelle (encarts.json, mesuré par cut_encarts.py).
"""
import json, os, sys
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "blender", "kie_ui", "encarts")
OUT = os.path.join(ROOT, "assets", "ui")
d = json.load(open(os.path.join(SRC, "encarts.json")))
out = {}
for k, v in d.items():
	fam = next((f for f in ("encart_voc", "bandeau", "guilde", "encart") if k.startswith(f + "_")), "bouton")
	s = {"encart": 0.32, "encart_voc": 250.0 / v["size"][0], "guilde": 250.0 / v["size"][0], "bandeau": 108.0 / v["size"][1]}.get(fam, 64.0 / v["size"][1])  # colonne de vocation : à la largeur de la colonne du héros (le cimier ne s'étire pas)  # encarts ~210 px de large, bandeaux 108 px de haut, boutons 64
	im = Image.open(os.path.join(SRC, k + ".png")).convert("RGBA")
	w, h = round(im.width * s), round(im.height * s)
	if "--dry" not in sys.argv:
		im.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, k + ".png"))
	if "marges" in v:
		out[k] = [round(x * s) for x in v["marges"]] + [round(x * s) for x in v["bord"]]
line = "const ENCARTS := " + json.dumps(out)
if "--dry" in sys.argv:
	print(line)
else:
	# écrit dans scripts/ui.gd ; tools/encarts_larges.py y ajoute ensuite les encarts élargis (vocl, guildel)
	import re
	ug = os.path.join(ROOT, "scripts", "ui.gd")
	src = open(ug, encoding="utf-8").read()
	src = re.sub(r"const ENCARTS := [{].*[}]", lambda _: line, src, count=1)
	open(ug, "w", encoding="utf-8", newline=chr(10)).write(src)
	print(len(out), "encarts écrits dans ENCARTS")
