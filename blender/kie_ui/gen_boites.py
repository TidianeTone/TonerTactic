# Boîtes de dialogue par locuteur + cadres de barres de vie. python gen_boites.py [clé...] -> boites/<clé>.png (fond vert, découpé par cut_boites.py)
import os, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(__file__))
from gen_ui import still
D = os.path.dirname(__file__)
OUT = os.path.join(D, "boites")
BOX = ("A single wide horizontal dialogue box frame for a fantasy video game user interface, seen perfectly flat and front-on, centered, "
	"filling about 90 percent of the image width. The inside of the box is one flat, plain, very dark charcoal panel with no texture and no pattern, "
	"so text can be written on it. The frame is thin on the long sides and carries its decoration at the corners and on a small name tab at the top-left. "
	"Hand-painted stylized game art with clean dark outlines, slightly tilted and imperfect like a hand-made object. "
	"The whole background around the box is pure flat chroma green #00FF00. No text, no letters, no characters, no scenery. ")
BAR = ("A single long horizontal health bar frame for a fantasy video game user interface, seen perfectly flat and front-on, centered, "
	"filling about 90 percent of the image width and about 12 percent of its height. The inside of the tube is EMPTY and filled with pure flat chroma green #00FF00, "
	"exactly the same green as the background. Hand-painted stylized pixel-art-like game art with clean dark outlines. "
	"The whole background is pure flat chroma green #00FF00. No text, no letters. ")
K = {
	"neutre": BOX + "Frame: worn dark bronze and weathered grey stone, simple and sober, two small rivets at each corner.",
	"marchand": BOX + "Frame: polished warm wood and brass, with a small brass balance scale on the name tab, a few gold coins and a tiny lantern hanging from one corner.",
	"anatheme": BOX + "Frame: dark violet lacquered metal with golden chain links running along the top edge, a small golden padlock hanging from the name tab, faint orange embers at the corners.",
	"chineuse": BOX + "Frame: turquoise-patinated copper and amber, small keys, shells and coins hanging from the bottom edge, a fish-fin shaped ornament on the name tab.",
	"dojo": BOX + "Frame: red lacquered wood and black iron like samurai armor plates, a sword blade lying along the top edge, two small red maple leaves at a corner.",
	"sourcier": BOX + "Frame: pale sandstone with turquoise water flowing along its edges and small splashes at the corners, a thin water ring above the name tab.",
	"barre_boss": BAR + "Frame: thick golden bronze tube with rounded end caps, and in the top middle a menacing horned skull with spread dark bat wings sitting on the bar.",
	"barre_heros": BAR + "Frame: thin simple bronze tube with small rounded end caps and one tiny gem at the left end, sober.",
}
only = sys.argv[1:] or list(K)
with ThreadPoolExecutor(4) as ex:
	for k in only:
		ex.submit(still, K[k], os.path.join(OUT, k + ".png"), "16:9", (), ["--quality", "basic"])
