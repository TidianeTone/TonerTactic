# Encarts de classe (écran de choix du héros, écran de vocation) + boutons Équipement / Paquet de la carte du monde.
# PRÉ-PROD : tout reste dans encarts/ (hors git), rien ne va dans assets/ tant que Tidiane n'a pas validé.
# Un visuel par image (qualité basic, 7,5 crédits) : sur une planche, le modèle recopie une classe sur les autres.
# Fond chroma vert #00FF00, sauf le moine (jade) sur magenta #FF00FF. Découpe : cut_encarts.py
# python gen_encarts.py [clé...]   (clés : garde lame ... receleur, equipement, paquet ; un fichier déjà là n'est pas refait)
import os, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ui import still

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "encarts", "brut")
MAGENTA = {"moine"}  # classes dont la couleur mangerait le vert du fond

ENCART = ("A single blank vertical panel frame for a fantasy video game hero selection screen, seen perfectly flat and front-on, centered, "
	"portrait, filling about 86 percent of the image height. The frame is a THIN border, about 3 percent of the panel width, and along the middle "
	"of each of the four sides it is a plain straight simple moulding with no ornament at all, no studs, no rivets, no repeated plates, so the panel can be stretched. All the decoration "
	"is concentrated in the four small corner pieces and in one small crest sitting on the top edge at the center. Nothing sticks out beyond the "
	"border: no paint splashes, no flames, no drips, no hanging objects, no ribbons outside the frame. The inside of the panel is one flat, plain, "
	"very dark near-black surface with a faint %s tint, no texture, no pattern, no picture, no divider, so text can be written on it. "
	"Hand-painted stylized game art with clean dark outlines, sober and elegant, much more discreet than a trading card frame. "
	"The whole background around the panel is pure flat chroma %s. No text, no letters, no characters. Materials and motifs: %s")

CLASSES = {
	"garde": ("blue", "royal-blue enamelled iron with grey stone; corner pieces are small stone tower battlements with round shield bosses; "
		"the crest is a small heater shield with a knight's helmet."),
	"lame": ("crimson", "blackened steel with thin crimson lacquer lines; corner pieces are small crescent moons with a curl of shadow; "
		"the crest is two small crossed curved daggers."),
	"oracle": ("violet", "dark bronze with violet enamel; each corner piece is a clearly visible sculpted bronze bracket holding a small "
		"orange-gold ember flame that stays inside the bracket; the crest is a bold open eye with a violet iris, wreathed in small orange "
		"ember flames, about 14 percent of the panel width."),
	"artificier": ("teal", "riveted bronze and copper with teal-patina enamel, corner pieces are small cogs and tiny "
		"gunpowder barrels; the crest is a small powder keg with a short fuse."),
	"moine": ("green", "carved light wood inlaid with polished green jade; corner pieces are small jade discs wrapped with a few prayer beads; "
		"the crest is an open palm carved in jade."),
	"trappeur": ("ochre", "a slim ochre leather strip over a thin wooden rod, smooth and plain along the sides with no seams "
		"and no lashings in the middle; corner pieces are small knots of rope with two crossed arrowheads; the crest is a small pair of antlers."),
	"tidiane": ("magenta", "white porcelain and gilded brass with thin magenta lacquer lines; corner pieces are small brass flourishes each "
		"with a single neat magenta brush-stroke painted INSIDE the corner piece; the crest is a small white porcelain duelist mask with a fine "
		"crack, a paintbrush and a thin rapier crossed behind it."),
	"receleur": ("slate grey", "tarnished silver with slate-grey enamel; corner pieces are small keyholes with a lockpick and a coin; "
		"the crest is a small padlock."),
}

BOUTON = ("A single compact badge-shaped game UI button for a fantasy video game map screen, seen perfectly flat and front-on, centered, "
	"about twice as wide as it is tall, filling about 80 percent of the image width, same family as a painted leather menu bar: dark brown "
	"stitched leather face with a sturdy worn metal rim and pointed metal end caps. On the left third, a small raised round medallion with %s. "
	"The right two thirds are a plain flat dark leather plate with a stitched edge and NOTHING written on it, left empty for a label. "
	"Hand-painted stylized game art with clean dark outlines, warm amber and brass highlights. "
	"The whole background around the button is pure flat chroma green #00FF00. No text, no letters, no numbers.")
BOUTONS = {
	"equipement": "a tiny knight helmet over a short sword, framed by a leather strap with a brass buckle",
	"paquet": "a small fan of three overlapping playing cards with painted backs",
}


def job(k):
	if k in CLASSES:
		tint, look = CLASSES[k]
		key = "magenta #FF00FF" if k in MAGENTA else "green #00FF00"
		return ENCART % (tint, key, look), os.path.join(D, "encart_%s.png" % k), "3:4"
	return BOUTON % BOUTONS[k], os.path.join(D, "bouton_%s.png" % k), "3:2"


if __name__ == "__main__":
	os.makedirs(D, exist_ok=True)
	only = sys.argv[1:] or list(CLASSES) + list(BOUTONS)
	with ThreadPoolExecutor(4) as ex:
		for k in only:
			p, out, ar = job(k)
			ex.submit(still, p, out, ar, (), ["--quality", "basic"])
