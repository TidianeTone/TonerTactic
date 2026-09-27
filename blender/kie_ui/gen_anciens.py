# Anciens v2 : low poly, dans le monde du jeu, loin des images d'origine. python gen_anciens.py [clé...]
import os, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(__file__))
from gen_ui import still
D = os.path.dirname(__file__)
OUT = os.path.join(D, "anciens_v2")
REF = os.path.join(D, "..", "..", "assets", "art", "card_g_revanche.png")
STYLE = ("Low-poly 3D render close to voxel art, chunky faceted blocky shapes, flat shading, simple readable silhouette, few details, "
	"exactly the same rendering style, proportions and lighting as the reference image (a stylized voxel tactics video game). "
	"Single full-body character, vertical portrait, centered, standing on a small piece of ground. Not painterly, not illustration, not realistic. "
	"No text, no letters, no frame, no border, no watermark. Use the reference ONLY for the rendering style, not its characters. ")
ANC = {
	"anatheme": "A tall hooded ancient spirit in a deep violet robe, its face a smooth faceless purple mask split by one thin glowing crack. "
		"Its huge open hands cup a floating ring of molten orange fire. A heavy golden chain hangs from its wrists and ends in a golden padlock. "
		"Violet embers drift around it. Background: dark violet void over ruined stone arches, dim.",
	"chineuse": "An ancient merchant woman standing knee-deep in a flooded sunken bazaar, turquoise water with floating market crates. "
		"She wears a teal turban and a long patchwork coat of amber and purple, and a flat bronze mask shaped like a fish fin. "
		"She holds up a bronze balance scale: one pan pours a thin stream of water, the other holds a small cracked red demon mask. "
		"Keys, shells and coins hang from her belt. Warm amber lanterns behind her.",
	"dojo": "A very old sword master kneeling on a single square stone slab in the middle of still turquoise water, eyes closed. "
		"Long white beard, dark lacquered red shoulder armor over a worn grey robe, a red demon mask pushed on the top of his head. "
		"A long glowing orange blade rests flat across his knees; two small brass weights hang from each end of the blade like a balance. "
		"Around him, concentric ripples on the water and a few floating red maple leaves. Dusk, ruined pillars far behind.",
	"sourcier": "A tall ancient water shaman with wild red hair, wearing a pale sand-colored robe with a leather belt, "
		"and a pointed teal mask with a fin crest. Pieces of dark red lacquered samurai shoulder armor on one shoulder. "
		"He raises his arms and lifts a ribbon of turquoise water that spirals into two floating rings above his head; stone blocks float around him. "
		"Shell and key charms hang on cords from his wrists. Flooded ruined courtyard, autumn leaves on the water.",
}
only = sys.argv[1:] or list(ANC)
with ThreadPoolExecutor(4) as ex:
	for k in only:
		ex.submit(still, STYLE + ANC[k], os.path.join(OUT, k + ".png"), "2:3", [REF])
