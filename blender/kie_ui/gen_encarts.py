# Encarts de classe (écran de choix du héros, écran de vocation) + boutons Équipement / Paquet de la carte du monde.
# PRÉ-PROD : tout reste dans encarts/ (hors git), rien ne va dans assets/ tant que Tidiane n'a pas validé.
# Un visuel par image (qualité basic, 7,5 crédits) : sur une planche, le modèle recopie une classe sur les autres.
# Fond chroma vert #00FF00, sauf le moine (jade) sur magenta #FF00FF. Découpe : cut_encarts.py
# guilde_<a>_<b> (28/09) : un encart par guilde, les deux encarts voc_ de ses classes en référence ; action : bouton générique ;
# option : panneau des choix (marchand, menus).
# python gen_encarts.py [clé...]   (clés : garde lame ... receleur, equipement, paquet, voc_<classe>, bandeau_<classe> ;
# un fichier déjà là n'est pas refait)
# voc_ / bandeau_ (28/09) : colonne haute ~1:2,3 (écran de vocation) et rectangle large ~3:1 (bouton de voie), peints en image-to-image
# avec l'encart validé de la classe en référence, pour rester de la même famille.
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


# ce que les encarts validés montrent vraiment (le prompt d'origine a dérivé), et les deux retouches demandées : lame moins sombre, oracle plus violet
LOOK = {
	"garde": "royal-blue enamelled iron border with grey stone; corner pieces are small grey stone tower battlements with round steel shield bosses; "
		"crest: a small blue heater shield with a knight's helmet.",
	# 2e essai du voc (le 1er restait aussi sombre que l'encart validé) : acier poli gris moyen, bande cramoisie franche
	"lame": "polished mid-grey gunmetal steel border, clearly LIGHTER than the reference, with a bright crimson enamel band running along the whole "
		"border and bright steel highlights, so the frame stays readable on a black screen; corner pieces are small polished steel crescent moons; "
		"crest: two small crossed curved steel daggers with crimson hilts, bright enough to read on black.",
	"oracle": "violet enamel border with thin dark bronze edges, the violet dominant everywhere (much more violet than bronze); corner pieces are small "
		"bronze-and-violet brackets each holding a small orange ember flame inside; crest: a bold open eye with a violet iris wreathed in small orange ember flames.",
	"artificier": "riveted bronze and copper border with teal-patina enamel; corner pieces are small bronze cogs with tiny gunpowder barrels; "
		"crest: a small powder keg with a short lit fuse.",
	"moine": "carved light sage-toned wood border inlaid with polished green jade; corner pieces are round green jade discs with a few prayer beads; "
		"crest: a small green jade lotus flower.",
	"trappeur": "smooth orange-ochre leather strip over a thin wooden rod; corner pieces are small rope knots with two crossed arrows; "
		"crest: a small pair of antlers.",
	"tidiane": "a very thin gilded gold moulding with fine magenta lacquer lines; corner pieces are small gold flourishes each set with a small magenta gem; "
		"crest: a small white porcelain duelist mask with a paintbrush and a thin rapier crossed behind it.",
	"receleur": "tarnished silver border with slate-grey enamel; corner pieces are small silver rivet plates with a crossed lockpick and key; "
		"crest: a small silver padlock.",
}

VOC = ("Using the reference image as the style guide, paint a NEW panel of the same family: the same materials, colors, corner pieces and crest "
	"as the reference, same hand-painted stylized game art with clean dark outlines. The new panel is a single blank TALL NARROW vertical column frame, "
	"seen perfectly flat and front-on, centered, about 2.4 times taller than it is wide, filling about 92 percent of the image height, with wide areas "
	"of the flat chroma background on its left and right. The border is thin, and the corner pieces and the crest stay SMALL, the same size relative "
	"to the border as in the reference, not stretched. Along the long left and right sides and along the top and bottom edges between the corners "
	"the border is a plain straight simple moulding with no ornament, no studs, no rivets, no repeated plates, so the panel can be stretched vertically. "
	"All the decoration is in the four corner pieces and in one small crest on the top edge at the center; nothing at the middle of the sides, "
	"nothing on the bottom edge. Nothing sticks out beyond the border: no splashes, no flames, no drips, no ribbons outside the frame. "
	"The inside is one flat, plain, very dark near-black surface with a faint %s tint, no texture, no pattern, no picture, no divider. "
	"The whole background around the panel is pure flat chroma %s. No text, no letters, no characters. %s")

BANDEAU = ("Using the reference image as the style guide, paint a NEW game UI element of the same family: the same materials, colors and corner "
	"motifs as the reference, same hand-painted stylized game art with clean dark outlines. The new element is a single blank WIDE HORIZONTAL "
	"rectangular plate used as a clickable button, seen perfectly flat and front-on, centered, exactly three times as wide as it is tall (its height is one "
	"third of its width), filling about 88 percent of the image width and about half of the image height. A slim border. The class motif appears ONLY at the two short ends: a small matching ornament at the left end and "
	"the same ornament mirrored at the right end, kept small and inside the plate's height, the four corners identical and mirrored left-right and "
	"top-bottom. The long top and bottom edges are a completely plain straight simple moulding: no ornament, no crest, no studs, no rivets, no plates, "
	"no bosses, no repeated blocks, so the plate can be stretched horizontally. Nothing sticks out beyond the border. "
	"The inside is one flat, plain, dark near-black surface with a faint %s tint, no texture, no pattern, no picture, no divider, left empty for "
	"a portrait and a label. The whole background around the plate is pure flat chroma %s. No text, no letters, no numbers. %s")


GUILDE = ("The two reference images are two panels from the same game UI, one per class. Paint ONE NEW panel of the same family that "
	"fuses both, as if the two classes had formed a guild together: the border weaves the materials and colors of the first reference with "
	"those of the second (for example one colour on the outer edge, the other on the inner edge, joined cleanly); the two top corner pieces are "
	"the corner pieces of the first reference, the two bottom corner pieces are those of the second, all kept small; one small crest on the "
	"top edge at the center merges the two crests of the references into a single emblem, the same size as one reference crest. "
	"Same hand-painted stylized game art with clean dark outlines. The panel is a single blank TALL NARROW vertical column frame, seen perfectly "
	"flat and front-on, centered, about 2.4 times taller than it is wide, filling about 92 percent of the image height, with wide areas of the "
	"flat chroma background on its left and right. Along the long left and right sides and along the top and bottom edges between the corners "
	"the border is a plain straight simple moulding with no ornament, no studs, no rivets, no repeated plates, so the panel can be stretched. "
	"Nothing at the middle of the sides, nothing on the bottom edge. Nothing sticks out beyond the border: no splashes, no flames, no drips, "
	"no ribbons outside the frame. The inside is one flat, plain, very dark near-black surface, no texture, no pattern, no picture, no divider. "
	"The whole background around the panel is pure flat chroma %s. No text, no letters, no characters.")

ACTION = ("Using the reference image as the style guide, paint a NEW game UI button of the same family: the same dark brown stitched leather "
	"face, the same sturdy worn metal rim and pointed metal end caps, the same hand-painted stylized game art with clean dark outlines and warm "
	"amber and brass highlights. The new button is a single blank WIDE HORIZONTAL plate, about four and a half times as wide as it is tall, "
	"centered, filling about 90 percent of the image width, with NO medallion and no icon: the whole face is one plain flat dark leather "
	"plate with a stitched edge, left empty for a label. The long top and bottom edges of the rim are plain straight metal with no rivets and "
	"no ornament, so the button can be stretched horizontally; all the decoration is in the two pointed metal end caps, mirrored left and right. "
	"Nothing sticks out beyond the button. The whole background around the button is pure flat chroma green #00FF00. No text, no letters, no numbers.")

OPTION = ("Using the reference image as the style guide, paint a NEW game UI panel of the same family: the same dark brown stitched leather, "
	"the same worn metal rim with brass highlights, the same hand-painted stylized game art with clean dark outlines. The new panel is a single "
	"blank vertical card-like panel for a merchant's or a menu's choices, seen perfectly flat and front-on, centered, portrait, about 1.3 times "
	"taller than it is wide, filling about 86 percent of the image height. A slim metal rim; four small matching brass corner protectors with a "
	"rivet; along the middle of each side the rim is plain straight metal with no ornament, no studs, no rivets, so the panel can be stretched. "
	"No crest. The inside is one flat, plain dark leather surface with a faint stitched line just inside the rim, no texture, no pattern, "
	"no picture, no divider, dark enough for light text. Nothing sticks out beyond the rim. The whole background around the panel is pure flat "
	"chroma green #00FF00. No text, no letters, no numbers.")
CHROMA = {"moine": "magenta #FF00FF"}  # le jade mangerait le vert du fond
PAIRE_BLEUE = {("moine", "tidiane")}   # jade et laque magenta : ni vert ni magenta


def job(k):
	fam, _, c = k.partition("_")
	if fam in ("voc", "bandeau") and c in CLASSES:
		key = "magenta #FF00FF" if c in MAGENTA else "green #00FF00"
		tpl, ar, name = (VOC, "9:16", "encart_voc_%s.png") if fam == "voc" else (BANDEAU, "16:9", "bandeau_%s.png")
		return (tpl % (CLASSES[c][0], key, "Materials and motifs: " + LOOK[c]), os.path.join(D, name % c), ar,
			[os.path.join(D, "encart_%s.png" % c)])
	if fam == "guilde":
		x, _, y = c.partition("_")
		key = "blue #0000FF" if (x, y) in PAIRE_BLEUE else ("magenta #FF00FF" if "moine" in (x, y) else "green #00FF00")
		return (GUILDE % key, os.path.join(D, "guilde_%s.png" % c), "9:16",
			[os.path.join(D, "encart_voc_%s.png" % x), os.path.join(D, "encart_voc_%s.png" % y)])
	if k == "action":
		return ACTION, os.path.join(D, "bouton_action.png"), "21:9", [os.path.join(D, "bouton_equipement.png")]
	if k == "option":
		return OPTION, os.path.join(D, "encart_option.png"), "3:4", [os.path.join(D, "bouton_equipement.png")]
	if k in CLASSES:
		tint, look = CLASSES[k]
		key = "magenta #FF00FF" if k in MAGENTA else "green #00FF00"
		return ENCART % (tint, key, look), os.path.join(D, "encart_%s.png" % k), "3:4", []
	return BOUTON % BOUTONS[k], os.path.join(D, "bouton_%s.png" % k), "3:2", []


if __name__ == "__main__":
	os.makedirs(D, exist_ok=True)
	only = sys.argv[1:] or list(CLASSES) + list(BOUTONS)
	with ThreadPoolExecutor(4) as ex:
		for k in only:
			p, out, ar, refs = job(k)
			ex.submit(still, p, out, ar, refs, ["--quality", "basic"])
