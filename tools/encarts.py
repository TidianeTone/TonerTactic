"""Encarts de classe et boutons (KIE, blender/kie_ui/encarts) réduits pour l'interface -> assets/ui/.

python tools/encarts.py [--dry]   -> imprime le dictionnaire ENCARTS à recopier dans scripts/ui.gd
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
	s = {"encart": 0.32, "encart_voc": 0.36, "bandeau": 108.0 / v["size"][1]}.get(k.rsplit("_", 1)[0], 64.0 / v["size"][1])  # encarts ~210 px de large, bandeaux 108 px de haut, boutons 64
	im = Image.open(os.path.join(SRC, k + ".png")).convert("RGBA")
	w, h = round(im.width * s), round(im.height * s)
	if "--dry" not in sys.argv:
		im.resize((w, h), Image.LANCZOS).save(os.path.join(OUT, k + ".png"))
	if "marges" in v:
		out[k] = [round(x * s) for x in v["marges"]] + [round(x * s) for x in v["bord"]]
print("const ENCARTS := " + json.dumps(out).replace(": ", ": "))
