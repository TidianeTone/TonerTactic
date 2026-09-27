# Équipement en pixel art (26/09) : une icône par pièce, dans le style des références de Tidiane (refs_items/),
# planches 4×4 sur vert #00FF00, puis découpe, détourage et vraie grille de pixels (cut_items.py).
# Aussi le dos de carte (cartes inconnues de la bibliothèque).
# python gen_items.py [dos]
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ui import still, GREEN, HERE

REFS = [os.path.join(HERE, "refs_items", f) for f in ("9.png", "13.png", "14.png", "17.png")]
OUT = os.path.join(HERE, "items")

ITEMS = {
	"epee_ecluse": "a sturdy knight's longsword with a blue enamel crossguard shaped like a canal lock gate",
	"masse_os": "a heavy iron flanged mace wrapped with bone plates",
	"hallebarde": "a halberd whose axe blade is shaped like a heron's head and beak",
	"dague_ombre": "a slim black dagger with a crimson grip and a small arch-shaped guard",
	"kriss": "a pair of twin wavy kris daggers crossed, red and black handles",
	"lame_soif": "a curved dagger dripping green poison, blood-red gem on the pommel",
	"baton_braise": "a gnarled wooden staff topped with a glowing orange ember in a claw",
	"sceptre_maree": "a silver scepter with a swirling blue water orb and wave-shaped crest",
	"baton_lotus": "a slender staff topped with a pink lotus flower in bloom",
	"cle_meca": "a huge brass lock-keeper's wrench key with gears",
	"canon_main": "a stubby flared blunderbuss hand cannon with brass bands and a teal fuse",
	"marteau_forge": "a shipwright's forge hammer with a riveted copper head",
	"bandes_jade": "rolled hand wraps of rope with jade beads",
	"chapelet": "a prayer bead chain with a wave-shaped jade pendant",
	"gantelets_ressac": "a pair of bronze knuckle gauntlets shaped like ship prows",
	"arc_frene": "a simple ash wood longbow with a green string",
	"arc_os": "a bow carved from pale catfish bone with fish-scale grip",
	"arbalete_silure": "a heavy crossbow loaded with a barbed harpoon and rope",
	"pinceau": "a master painter's paintbrush dripping magenta paint, golden ferrule",
	"palette": "a painter's palette with blue, red and black paint blobs and a small knife",
	"stylet": "a digital drawing stylus pen glowing cyan, elegant",
	"pied_biche": "a rusty iron crowbar",
	"crochets": "a ring of lockpicks and small keys",
	"gants_velours": "a pair of dark purple velvet thief gloves with silver studs",
	"anneau_bouclier": "a breastplate made from a riveted sluice gate plate, blue iron",
	"oeil_vigilant": "a leather back plate with a painted watchful eye",
	"bracelet_fleches": "woven reed bracers with arrow-deflecting slats",
	"coeur_pierre": "a rusty chainmail shirt",
	"cuirasse_compagnie": "a dented steel cuirass with a faded company emblem",
	"cotte_vase": "a mud-caked padded armor dripping with silt",
	"cire_passeur": "a yellow oilskin boatman's raincoat",
	"carapace_ecrevisse": "an armor made of red crayfish shell plates",
	"mantelet_feuilles": "a short cloak made of orange autumn leaves",
	"brigandine_noyee": "a heavy waterlogged brigandine with barnacles and seaweed",
	"heaume_noye": "a drowned knight's great helm covered in barnacles, water dripping",
	"bottes_heron": "tall slender grey boots with heron feather tufts",
	"sandales_saut": "springy green sandals with toad-skin soles",
	"ecaille_eau": "light cork-soled boots that float",
	"echasses_roseau": "a pair of reed stilts tied with twine",
	"sabots_halage": "wooden towpath clogs with iron studs",
	"guetres_eclusier": "sturdy leather gaiters with brass buckles",
	"bottes_vase": "heavy mud boots with lead soles, dark brown",
	"bottes_fuyard": "worn quick running boots with wing-like flaps",
	"pas_passeur": "ghostly ferryman's boots glowing teal, walking on water ripples",
	"amulette_regen": "an amulet of living green moss around a stone",
	"plume_elan": "a pearl pendant with a swirl of breath inside",
	"gantelet": "a heavy weighted signet ring of iron and gold",
	"miroir": "a round copper hand mirror",
	"bourse": "a shipwrecker's coin purse spilling gold coins",
	"dent_silure": "a big catfish tooth on a leather cord",
	"medaille_rouillee": "a rusty military insignia medal on a ribbon",
	"bague_charognard": "a ring shaped like a vulture skull",
	"lanterne_brume": "a small hanging lantern filled with swirling mist",
	"croc_brochet": "a pike fang pendant dripping green venom",
	"signet_algue": "a seaweed-green signet ring with a wax seal",
	"masse_digue": "a legendary giant mace shaped like a stone dike tower, blue enamel, gold trim, glowing",
	"derniere_arche": "a legendary black dagger with a crescent arch guard and crimson glowing edge",
	"sceptre_vive": "a legendary scepter crowned with a roaring living flame, violet and gold",
	"canon_mere": "a legendary ornate brass cannon with a valve wheel and glowing teal barrel",
	"poings_crue": "legendary gauntlets made of crashing flood waves and jade",
	"arc_chevrier": "a legendary bow with curled goat horn limbs and gold inlay",
	"geste_parfait": "a legendary painter's brush trailing rainbow paint, masked porcelain handle",
	"passe_partout": "a legendary ornate skeleton key glowing silver, with tiny gears",
	"cuirasse_gardien": "a legendary massive stone and gold cuirass of an ancient guardian, glowing runes",
	"voile_dame": "a legendary flowing teal veil robe dripping luminous water drops",
	"manteau_cendre": "a legendary cloak of smoldering ash with glowing embers at the hem",
	"bottes_chevrier": "legendary goatherd boots with small curled horns and fur",
	"grandes_eaux": "legendary boots made of swirling water with golden anchors",
	"coeur_ecluse": "a legendary glowing blue heart-shaped gem set in a lock gear",
	"oeil_paupiere": "a legendary lidless eye amulet staring, violet iris, gold frame",
	"sceau_compagnie": "a legendary golden seal medallion of the drowned company, red ribbon",
}


def planches():
	os.makedirs(OUT, exist_ok=True)
	ids = list(ITEMS)
	batches = [ids[i:i + 16] for i in range(0, len(ids), 16)]
	json.dump(batches, open(os.path.join(OUT, "batches.json"), "w"), indent=0)
	for k, b in enumerate(batches):
		parts = ["Cell %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, ITEMS[x]) for i, x in enumerate(b)]
		for i in range(len(b), 16):
			parts.append("Cell %d: empty." % (i + 1))
		still("A 4x4 grid of sixteen separate video game item icons in crisp pixel art, exactly the style of the reference images: "
			"chunky readable pixels, a dark 1-pixel outline, rich hand-placed shading with 4 to 6 tones per material, warm highlights, "
			"each item centered in its own cell, drawn at a slight three-quarter angle, same scale, lots of empty space between cells, "
			"no text, no numbers, no frame, no shadow on the ground. " + " ".join(parts) + " " + GREEN.replace("frames", "items").replace("inside of each frame", "space around each item"),
			os.path.join(OUT, "sheet_%02d.png" % k), "1:1", REFS)


def dos():
	still("The back of a trading card for a dark fantasy tactics card game about a drowned lock city: portrait card, ornate dark iron and brass "
		"frame with teal enamel, a central emblem of a stylized canal lock gate crossed by a key and a sword over a deep blue-black background "
		"with subtle wave patterns and faint gold filigree, symmetrical, mysterious, hand-painted game UI asset, front view, fills the whole image, "
		"no text, no letters.", os.path.join(HERE, "dos_carte.png"), "3:4", [os.path.join(HERE, "cadres_classes.png")])


DOS = [  # un dos par classe (ordre de cadres_classes.png), la matière et l'emblème de son cadre
	("garde", "royal-blue enamelled iron and steel, emblem: a tower shield under a small helmet crest, battlement border"),
	("lame", "blackened steel and crimson lacquer, emblem: two crossed curved daggers under a crescent moon, smoke wisps"),
	("oracle", "dark bronze and violet enamel, emblem: an open eye inside a ring of ember flames"),
	("artificier", "riveted copper and brass, teal gauges, emblem: a powder keg with a lit fuse inside a cogwheel"),
	("moine", "carved light wood and jade, green silk, emblem: a jade gem circled by prayer beads over wave crests"),
	("trappeur", "knotted rope, bone and ochre leather, emblem: a stag skull with antlers over crossed arrows"),
	("tidiane", "gilded wood splattered with magenta, blue, red and black paint, emblem: a cracked porcelain mask over crossed paintbrushes"),
	("receleur", "tarnished silver and slate enamel, emblem: a padlock hung with keys and coins"),
	("objet", "warm polished brass and leather, emblem: a buckled satchel with a coin"),
]


def dos_classes():
	parts = ["Panel %d (row %d, column %d): %s." % (i + 1, i // 3 + 1, i % 3 + 1, d) for i, (k, d) in enumerate(DOS)]
	still("A single image divided into a 3x3 grid of nine trading card BACKS for a fantasy tactics card game, each card portrait, centered "
		"in its cell, all the same size and the same layout as the card back of the first reference: an ornate frame around a deep dark "
		"background with subtle patterns, one large central emblem, symmetrical, hand-painted game UI, front view. Each back uses the material "
		"and colours of the matching class frame in the second reference. No text, no letters. " + " ".join(parts) + " " + GREEN,
		os.path.join(HERE, "dos_classes.png"), "3:4", [os.path.join(HERE, "dos_carte.png"), os.path.join(HERE, "cadres_classes.png")])


RELICS = {  # les 31 reliques (27/09) : même pixel art que l'équipement, à la place des pictogrammes
	"ambre": "a warm amber stone with a tiny river insect trapped inside, glowing",
	"feuille": "a single bright red autumn maple leaf with a sharp dagger-like stem",
	"lotus_pale": "a pale white-pink lotus flower floating on a lily pad",
	"crochet": "a big iron canal-lock hook with a chain link",
	"cendre": "a small heap of glowing live embers and grey ash in a clay dish",
	"tuile": "a broken terracotta roof tile, cracked in two",
	"cloche": "a small green-bronze bell covered in barnacles, dripping water",
	"grimoire": "a swollen damp leather spellbook with wet pages and a teal clasp",
	"sablier": "a green glass water clock (clepsydra) with dripping water",
	"ecaille": "a large iridescent golden carp scale",
	"heron": "a white heron feather aigrette with a silver clasp",
	"oeil": "a brass spyglass with a fogged lens",
	"sacoche": "a buckled brown leather satchel",
	"alambic": "a small copper pocket alchemy still with a bubbling green flask",
	"livret": "a small apprentice notebook bound with string, a pencil tucked in",
	"blason": "a heraldic shield quartered in blue, red, gold and green",
	"touriste": "a peddler's travel notebook covered in stamps and pinned tickets",
	"sceau": "a hexagonal guild wax seal stamp with a red wax disc",
	"medaille": "a medal made of two interlocking rings, one blue one magenta",
	"noblesse": "a sealed letter of nobility with a gold ribbon and red wax",
	"plume": "an elegant quill pen borrowed, with a different-colored feather tip",
	"masque": "a white porcelain half-mask with a thin crack, magenta ribbon",
	"tambour": "a small hand drum with the number 174 painted on it, drumsticks",
	"galet": "a smooth round polished river pebble, grey with a white band",
	"pierre": "a whetstone with a small blade being sharpened, sparks",
	"braise_eternelle": "a clay jug of stagnant green murky water with flies",
	"hamecon": "a big rusty fishing hook on a frayed line",
	"collier": "a spiked leather dog collar with wolf teeth charms",
	"sifflet": "a carved bone whistle on a cord",
	"bourse": "a ferryman's obol coin on a black ribbon, silver",
	"journal_route": "a worn travel journal with a map sticking out and a compass",
}
RELICS2 = {  # les 57 reliques du concile (27/09), planches à part pour ne pas décaler les premières
	"baril_contrebande": "small smuggler's powder keg with a torn customs tag",
	"coin_carrier": "iron wedge driven into a cracked stone block",
	"etoupe": "coil of tarred oakum, black and glossy, smouldering orange tip",
	"clou_halage": "big forged iron nail with a frayed hemp rope knotted around it",
	"collet_crin": "coiled horsehair snare loop with a small wooden stake",
	"piquet_frene": "sharpened ash-wood stake with iron teeth bound by cord",
	"amadou": "chunk of dry tinder fungus with a glowing ember on it",
	"battant": "heavy bronze bell clapper on a short leather strap",
	"gobelet": "dented pewter goblet brimming with clear glowing water",
	"passe_partout": "ring of old iron skeleton keys, one worn shiny",
	"denier_fossoyeur": "tarnished bronze coin with a small shovel stamped on it",
	"sebile_cuivre": "small hammered copper begging bowl with a few coins inside",
	"semelles_jonc": "pair of woven reed sandal soles with mud stains",
	"ecorce_saule": "curled strip of willow bark tied with twine",
	"givre_etrave": "frosted ship prow fragment with icicles",
	"chaine_amarre": "short length of massive rusted mooring chain dripping water",
	"craie_arpenteur": "stub of white surveyor's chalk in a brass holder beside a chalk cross",
	"plaque_vanne": "small square riveted iron sluice-gate plate dented in the center",
	"onguent": "small clay pot of amber resin salve with a wooden spatula",
	"lentille": "thick hand-blown glass lens in a copper ring, slightly warped",
	"diapason": "steel tuning fork resting on a folded cloth, faint vibration lines",
	"doublure": "coat lining turned inside out showing many hidden stitched pockets",
	"vessie": "dried toad bladder pouch leaking a green droplet",
	"poudre_fine": "small leather pouch spilling black gunpowder",
	"pique": "wooden pike with a tattered war banner",
	"hachoir": "wide butcher's cleaver with a notched blade",
	"soufflet": "small leather forge bellows with brass nozzle and scorch marks",
	"goupille": "oversized steel cotter pin on a leather cord",
	"encrier": "squat glass inkwell with violet glowing ink and a quill",
	"grelot": "small brass bell tied to a braided leather leash",
	"etendard": "faded tattered banner on a broken pole, waterlogged cloth",
	"remous": "small whirlpool swirl in a stone basin",
	"tenaille": "blacksmith pincer tongs clamped shut",
	"corde_noeuds": "knotted hemp prayer rope with four large knots",
	"cle_jumeaux": "old iron key with two identical bows, faint violet glow",
	"clou_quai": "large rusted dock spike nail",
	"souffle": "cracked bronze cannon mouth puffing smoke",
	"quille": "heavy dented lead skittle pin",
	"marelle": "stub of white chalk beside a hopscotch square drawn on stone",
	"echo_caverne": "spiral seashell carved from dark stone with ripple lines",
	"braise_veille": "small iron lantern holding one glowing ember",
	"relais_poste": "brass post horn hanging from a wooden signpost",
	"couteau_palette": "painter's palette knife smeared with glowing red, blue and gold paint",
	"ecusson": "corroded bronze shield-shaped badge with barnacles and a faint central glow",
	"corne_aube": "curved horn bugle with a dawn-colored brass band",
	"couronne_plomb": "crude heavy lead crown with dull grey spikes",
	"chaine_forcat": "rusted iron shackle with a short broken chain",
	"cle_ecluse": "enormous ornate iron key with a lock-gate shaped bow, green algae",
	"machoire_ogre": "huge jawbone with jagged teeth and a leather strap",
	"ecrin": "small velvet-lined jewelry box whose interior is a dark bottomless void",
	"coeur_fournaise": "glowing molten heart inside an iron cage",
	"jeton_comptoir": "square brass trade token stamped with a balance scale",
	"ciseaux_epure": "pair of slender tailor's scissors with blackened blades",
	"nasse": "wicker fish trap basket dripping water",
	"lampe_brume": "small hooded ship lantern with frosted green glass, mist curling from its vents",
	"registre_prevot": "leather-bound ledger with a wax seal and a list of crossed-out names",
	"colonne_volee": "cracked stone pillar segment strapped on a wooden sled",
}


def reliques(src=RELICS, sub="reliques"):
	out = os.path.join(HERE, sub)
	os.makedirs(out, exist_ok=True)
	ids = list(src)
	batches = [ids[i:i + 16] for i in range(0, len(ids), 16)]
	json.dump(batches, open(os.path.join(out, "batches.json"), "w"), indent=0)
	for k, b in enumerate(batches):
		parts = ["Cell %d (row %d, column %d): %s." % (i + 1, i // 4 + 1, i % 4 + 1, src[x]) for i, x in enumerate(b)]
		for i in range(len(b), 16):
			parts.append("Cell %d: empty." % (i + 1))
		still("A 4x4 grid of sixteen separate video game relic icons in crisp pixel art, exactly the style of the reference images: "
			"chunky readable pixels, a dark 1-pixel outline, rich hand-placed shading with 4 to 6 tones per material, warm highlights, "
			"each object centered in its own cell, drawn at a slight three-quarter angle, same scale, lots of empty space between cells, "
			"no text, no numbers, no frame, no shadow on the ground. " + " ".join(parts) + " " + GREEN.replace("frames", "items").replace("inside of each frame", "space around each item"),
			os.path.join(out, "sheet_%02d.png" % k), "1:1", REFS)


if __name__ == "__main__":
	{"dos": dos, "dos_classes": dos_classes, "reliques": reliques, "reliques2": lambda: reliques(RELICS2, "reliques2")}.get(sys.argv[1] if sys.argv[1:] else "", planches)()
