# Les 6 cartes des Berserkers refaites (27/09 : la guilde devient la rage, plus il prend plus il frappe). Une image par carte.
import os, sys
from concurrent.futures import ThreadPoolExecutor
from PIL import Image
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "kie_ui"))
from gen_ui import still
D = os.path.dirname(__file__)
OUT = os.path.join(D, "berserk")
ART = os.path.join(D, "..", "..", "assets", "art")
REF = os.path.join(ART, "card_g_revanche.png")
STYLE = ("Low-poly 3D render close to voxel art, chunky faceted blocky shapes, flat shading, simple readable silhouettes, few details, "
	"exactly the same rendering style and lighting as the reference image, a stylized voxel tactics video game, three-quarter view, "
	"flooded ruined stone city background. Single game card illustration, no text, no letters, no frame. Use the reference only for the style. ")
KNIGHT = "a blue-armored knight with a tower shield wearing a white porcelain half-mask"
DUEL = "a duelist in a magenta coat with a brush-blade wearing a blue-plumed helmet"
FOE = "a cracked basalt golem with glowing ember cracks"
S = {
	"g_douche": f"{KNIGHT}, his armor dented and bleeding red light from cracks, roaring and smashing his shield into {FOE}; the wounder he is, the bigger the red aura around him.",
	"g_discipline": f"{DUEL} dragging his own blade across his forearm, red drops falling, grinning, and three glowing cards flying up into his other hand.",
	"g_callus": f"{KNIGHT} standing wide open, arms spread, covered in old scars that glow as armor plates, taunting three drowned armored spearmen who strike his chest.",
	"g_cle_donjon": f"{DUEL} just hit by an arrow in the shoulder, answering instantly with a furious slash that splits {FOE}, blood and embers mixing.",
	"g_parry": f"{KNIGHT} on one knee, almost dead, eyes glowing red, striking twice in a frenzy of two afterimage blows at a giant river crab.",
	"g_quarante": f"{DUEL} and {KNIGHT} back to back, wounded, in a towering red berserk aura with flame-like hair, the ground cracking under them, a horde of golems hesitating.",
}
only = sys.argv[1:] or list(S)
with ThreadPoolExecutor(3) as ex:
	for k in only:
		ex.submit(still, STYLE + S[k], os.path.join(OUT, k + ".png"), "3:2", [REF], ["--quality", "basic"])
for k in only:  # au format des cartes (504 x 336)
	p = os.path.join(OUT, k + ".png")
	if os.path.exists(p):
		im = Image.open(p).convert("RGB")
		w, h = im.size
		t = int(w * 2 / 3)
		im = im.crop((0, (h - t) // 2, w, (h - t) // 2 + t)) if t < h else im
		im.resize((504, 336), Image.LANCZOS).save(os.path.join(ART, "card_%s.png" % k))
		print("carte", k)
