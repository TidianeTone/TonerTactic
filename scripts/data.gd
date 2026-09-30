class_name Data
## Toutes les données de jeu : héros, ennemis, cartes, reliques, traits, biomes.

const CLASS_COLOR := {
	"garde": Color("#3d63e0"),
	"lame": Color("#e0344f"),
	"oracle": Color("#9b50d8"),
	"artificier": Color("#22b8a6"),
	"moine": Color("#6cc24a"),
	"trappeur": Color("#c9a23a"),
	"tidiane": Color("#d0409a"),
	"receleur": Color("#9fb4c2"),
	"objet": Color("#c9a86a"),
	"neutre": Color("#7fa6a0"),  # cartes neutres : sans classe, vert-de-gris
}
const CLASS_GLYPH := {"garde": "🛡", "lame": "🗡", "oracle": "✺"}

const HEROES := {
	"garde": {"name": "Garde", "title": "Rempart de l'Écluse", "hp": 48, "speed": 4, "move": 3, "jump": 2, "role": "Encaisse : armure, charges, provocation."},
	"lame": {"name": "Lame", "title": "Ombre des Arches", "hp": 36, "speed": 8, "move": 4, "jump": 4, "role": "Coups de dos, poison, téléportation."},
	"oracle": {"name": "Oracle", "title": "Voix de la Braise", "hp": 34, "speed": 5, "move": 3, "jump": 2, "role": "Braise à distance, soins, pioche."},
	"artificier": {"name": "Artificier", "title": "Poudre des Écluses", "hp": 38, "speed": 5, "move": 3, "jump": 2, "role": "Barils explosifs, grenades, tourelles."},
	"moine": {"name": "Moine", "title": "Paume du Ressac", "hp": 38, "speed": 7, "move": 4, "jump": 3, "role": "Enchaîne au contact, bondit, tourbillonne."},
	"trappeur": {"name": "Trappeur", "title": "Chasseur des Hauts-Fonds", "hp": 34, "speed": 7, "move": 4, "jump": 3, "role": "Pièges, marques, filets, harpons."},
	"tidiane": {"name": "Tidiane", "title": "L'Élan calculé", "hp": 36, "speed": 6, "move": 4, "jump": 3, "role": "Artisan des trois voix : Analyse, Émotion, Ambition. Paie en PV pour frapper fort."},
	"receleur": {"name": "Receleur", "title": "Main leste des Hauts-Quais", "hp": 36, "speed": 8, "move": 4, "jump": 3, "role": "Vole les objets des ennemis, les fabrique et les recharge. Ses objets ne lui bouchent pas la main."},
}

# La philosophie de chaque classe, telle qu'on la lit à l'écran de vocation : comment elle pense, comment elle joue.
const PHILO := {
	"garde": "Tenir. Le Garde prend les coups pour que les autres n'aient pas à les prendre : armure, provocation, charges qui renversent. Il gagne les combats longs.",
	"lame": "Frapper là où ça ne se voit pas. La Lame tourne autour, passe dans le dos, empoisonne et disparaît. Fragile de face, mortelle de dos.",
	"oracle": "Tout à distance. L'Oracle brûle les ennemis de loin et soigne ses alliés sans jamais s'approcher : il tient l'arrière, et tant qu'on ne l'atteint pas, personne ne tombe.",
	"artificier": "Tout peut sauter. L'Artificier pose des barils, lance des grenades et fait du terrain une arme ; il joue le placement avant les dégâts.",
	"moine": "Le geste enchaîné. Le Moine frappe au contact, bondit, tourbillonne : chaque coup du tour nourrit le suivant.",
	"trappeur": "La proie vient à lui. Le Trappeur pose ses pièges, marque, entrave et harponne : il décide où le combat aura lieu.",
	"tidiane": "Le peintre masqué : chaotique, ingénieux, jamais deux fois le même tableau. Tidiane mêle Analyse, Émotion et Ambition, paie en PV pour frapper fort et vit au rythme de son BPM.",
	"receleur": "Tout se prend, tout se revend. Le Receleur vole les objets des ennemis, les fabrique, les recharge et les lance : sa main ne se vide jamais.",
}

const FOES := {
	"husk": {"name": "Moussu", "hp": 14, "speed": 4, "move": 3, "jump": 2, "dmg": 6, "range": [1, 1], "ai": "melee"},
	"guetteur": {"name": "Guetteur", "hp": 11, "speed": 6, "move": 3, "jump": 2, "dmg": 5, "range": [2, 5], "ai": "ranged"},
	"sentinelle": {"name": "Sentinelle", "hp": 28, "speed": 3, "move": 2, "jump": 2, "dmg": 10, "range": [1, 1], "ai": "melee", "armor": 4, "passives": ["contre", "ancre"], "zoc": true},
	"wisp": {"name": "Feu follet", "hp": 6, "speed": 9, "move": 5, "jump": 9, "dmg": 9, "range": [1, 1], "ai": "bomb", "fly": true},
	"gardien": {"name": "Le Gardien des ruines", "hp": 85, "speed": 4, "move": 3, "jump": 2, "dmg": 13, "range": [1, 1], "ai": "boss", "passives": ["contre", "ancre"],
		"no_champion": true, "paliers": [0.66, 0.33], "root_immune": true, "titre": "Le Gardien des ruines", "ligne": "Il tient l'Écluse depuis que la ville a sombré."},
	"chaman": {"name": "Chaman de braise", "arme": "magie", "hp": 12, "speed": 5, "move": 3, "jump": 2, "dmg": 3, "range": [2, 4], "ai": "healer", "heal": 6},
	"carapace": {"name": "Carapace", "hp": 20, "speed": 2, "move": 2, "jump": 1, "dmg": 7, "range": [1, 1], "ai": "melee", "armor": 8, "heavy": true, "ancre_armure": true},
	"rodeur": {"name": "Rôdeur", "hp": 13, "speed": 8, "move": 5, "jump": 4, "dmg": 7, "range": [1, 1], "ai": "assassin", "passives": ["reflexe"]},
	# la Compagnie noyée : une armée engloutie par l'Écluse
	"lancier": {"name": "Lancier noyé", "hp": 18, "speed": 5, "move": 3, "jump": 2, "dmg": 7, "range": [1, 2], "ai": "melee", "arme": "perforant", "passives": ["contre"]},
	"cavalier": {"name": "Cavalier des berges", "hp": 20, "speed": 7, "move": 6, "jump": 1, "dmg": 8, "range": [1, 1], "ai": "reflux", "arme": "tranchant"},
	"vouivre": {"name": "Vouivre", "hp": 22, "speed": 6, "move": 6, "jump": 9, "dmg": 9, "range": [1, 1], "ai": "melee", "arme": "contondant", "fly": true},
	"mage": {"name": "Mage de la Marée", "hp": 12, "speed": 5, "move": 3, "jump": 2, "dmg": 7, "range": [1, 3], "ai": "ranged", "arme": "magie"},
	"bretteur": {"name": "Bretteur", "hp": 15, "speed": 8, "move": 4, "jump": 3, "dmg": 6, "range": [1, 1], "ai": "assassin", "arme": "tranchant", "botte": true, "passives": ["reflexe"]},
	"danseuse": {"name": "Danseuse des brumes", "hp": 12, "speed": 6, "move": 4, "jump": 3, "dmg": 3, "range": [1, 1], "ai": "dancer", "arme": "tranchant"},
	"capitaine": {"name": "Capitaine noyé", "hp": 40, "speed": 4, "move": 3, "jump": 2, "dmg": 10, "range": [1, 1], "ai": "commander", "arme": "contondant", "armor": 3, "aura": "ordre"},
	"baliste": {"name": "Baliste", "hp": 18, "speed": 3, "move": 0, "jump": 0, "dmg": 10, "range": [2, 8], "ai": "ranged", "arme": "perforant", "heavy": true},
	# bêtes des Hauts-Fonds
	"crabe": {"name": "Crabe des écluses", "hp": 24, "speed": 3, "move": 3, "jump": 1, "dmg": 7, "range": [1, 1], "ai": "melee", "armor": 4, "heavy": true, "shove": 1, "ancre_armure": true},
	"crapaud": {"name": "Crapaud-gouffre", "hp": 18, "speed": 4, "move": 2, "jump": 3, "dmg": 6, "range": [2, 4], "ai": "puller"},
	"harpie": {"name": "Harpie des brumes", "hp": 13, "speed": 9, "move": 6, "jump": 9, "dmg": 6, "range": [1, 1], "ai": "reflux", "fly": true},
	# structure : ne bouge pas, n'attaque pas, appelle une créature au début du round. À abattre vite.
	"obelisque": {"name": "Obélisque d'appel", "hp": 30, "speed": 2, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "spawner", "passives": ["ancre"], "structure": true},
	# --- spec ennemis du 26/09 · « model » : modèle voxel de repli tant que u_<id>.glb n'existe pas
	# acte 1 : lire
	"frondeur": {"name": "Frondeur des toits", "model": "guetteur", "hp": 10, "speed": 6, "move": 3, "jump": 3, "dmg": 5, "range": [2, 4], "ai": "ranged", "perche": true},
	"pavoiseur": {"name": "Pavoiseur noyé", "model": "sentinelle", "hp": 18, "speed": 4, "move": 3, "jump": 2, "dmg": 6, "range": [1, 1], "ai": "melee", "passives": ["pavois_face"]},
	"anguille": {"name": "Anguille des vannes", "model": "vouivre", "hp": 10, "speed": 7, "move": 4, "jump": 1, "dmg": 6, "range": [1, 1], "ai": "anguille", "passives": ["eau", "flotte"], "water_only": true},
	"fanal": {"name": "Fanal de la Compagnie", "model": "obelisque", "hp": 22, "speed": 2, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "totem", "passives": ["ancre"], "structure": true, "aura": "fanal", "near_foes": true, "on_death": "fanal"},
	"treuil": {"name": "Treuil de vanne", "model": "obelisque", "hp": 12, "speed": 1, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "totem", "passives": ["ancre"], "structure": true, "on_death": "treuil"},
	"grelin": {"name": "Maître Grelin, l'Éclusier", "model": "capitaine", "hp": 55, "speed": 5, "move": 3, "jump": 2, "dmg": 9, "range": [1, 2], "ai": "eclusier", "passives": ["pavois_face", "ancre"],
		"no_champion": true, "paliers": [0.5], "titre": "Maître Grelin, l'Éclusier", "ligne": "Il ouvre les vannes sur tout ce qui se tient devant lui."},
	# acte 2 : prioriser
	"tenant": {"name": "Tenant de la Compagnie", "model": "sentinelle", "hp": 24, "speed": 4, "move": 3, "jump": 2, "dmg": 5, "range": [1, 1], "ai": "guard", "armor": 3, "guard": 1},
	"pisteuse": {"name": "Pisteuse des vases", "model": "guetteur", "hp": 13, "speed": 7, "move": 4, "jump": 3, "dmg": 6, "range": [2, 4], "ai": "ranged", "guet": 5},
	"penitente": {"name": "Pénitente de l'Écluse", "model": "mage", "hp": 14, "speed": 5, "move": 3, "jump": 2, "dmg": 4, "range": [1, 3], "ai": "cleanser", "arme": "magie"},
	"bitte": {"name": "Bitte d'amarrage", "model": "obelisque", "hp": 26, "speed": 2, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "tether", "passives": ["ancre"], "structure": true, "on_death": "bitte"},
	"hale": {"name": "Hale, l'Amarreur au bouclier", "model": "capitaine", "hp": 55, "speed": 3, "move": 3, "jump": 2, "dmg": 9, "range": [1, 1], "ai": "guard", "armor": 5, "passives": ["ancre", "contre"],
		"no_champion": true, "bond": "brasse", "guard": 1, "guard_only": "brasse", "root_immune": true, "titre": "Les Amarreurs", "ligne": "Hale couvre, Brasse accroche. Tuer l'un enrage l'autre."},
	"brasse": {"name": "Brasse, l'Amarreuse à la gaffe", "model": "lancier", "hp": 40, "speed": 7, "move": 4, "jump": 3, "dmg": 8, "range": [1, 2], "ai": "puller", "armor": 1, "no_champion": true, "bond": "hale", "botte": true},
	# acte 3 : le terrain se retourne
	"vanne": {"name": "Vanne rouillée", "model": "obelisque", "hp": 26, "speed": 10, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "flood", "armor": 2, "passives": ["ancre"], "structure": true, "flood_cap": 8, "on_death": "vanne"},
	"pilori": {"name": "Pilori noyé", "model": "obelisque", "hp": 20, "speed": 9, "move": 0, "jump": 0, "dmg": 0, "range": [0, 6], "ai": "pilori", "armor": 3, "passives": ["ancre"], "structure": true, "on_death": "pilori"},
	"eclusier_fou": {"name": "Éclusier fou", "model": "husk", "hp": 14, "speed": 6, "move": 4, "jump": 2, "dmg": 5, "range": [1, 1], "ai": "sapper"},
	"noye_ancien": {"name": "Noyé ancien", "model": "lancier", "hp": 30, "speed": 3, "move": 3, "jump": 2, "dmg": 8, "range": [1, 1], "ai": "melee", "armor": 3, "passives": ["eau", "flotte"], "ancre_si_eau": true},
	"porte_etendard": {"name": "Porte-étendard noyé", "model": "lancier", "hp": 22, "speed": 4, "move": 3, "jump": 2, "dmg": 6, "range": [1, 1], "ai": "melee", "armor": 2, "aura": "etendard"},
	"fouisseur": {"name": "Fouisseur des fondations", "model": "crabe", "hp": 16, "speed": 7, "move": 4, "jump": 3, "dmg": 7, "range": [1, 1], "ai": "burrow"},
	# --- les crues (26/09) : trois boss de terrain, dans l'esprit de Grelin (une mécanique à casser ou à contourner)
	"chevrier": {"name": "Le Chevrier des ponts", "hp": 50, "speed": 6, "move": 4, "jump": 4, "dmg": 8, "range": [1, 1], "ai": "chevrier", "arme": "tranchant",
		"no_champion": true, "paliers": [0.5], "titre": "Le Chevrier des ponts", "ligne": "Il coupe les ponts derrière vous. Ses chèvres font le reste."},
	"chevre": {"name": "Chèvre des ponts", "hp": 9, "speed": 8, "move": 4, "jump": 5, "dmg": 3, "range": [1, 1], "ai": "melee", "shove": 1},
	"dame": {"name": "La Dame des Vannes", "hp": 60, "speed": 5, "move": 3, "jump": 2, "dmg": 7, "range": [2, 4], "ai": "dame", "arme": "magie",
		"no_champion": true, "paliers": [0.5], "titre": "La Dame des Vannes", "ligne": "La crue monte d'un cran à chaque tour. Qu'elle s'y noie."},
	"vanne_dame": {"name": "Vanne de la Dame", "model": "vanne", "hp": 18, "speed": 1, "move": 0, "jump": 0, "dmg": 0, "range": [0, 0], "ai": "totem", "armor": 2, "passives": ["ancre"], "structure": true, "on_death": "vanne_dame"},
	"brule_haie": {"name": "Brûle-Haie", "hp": 60, "speed": 6, "move": 4, "jump": 3, "dmg": 7, "range": [1, 3], "ai": "brule", "arme": "magie",
		"no_champion": true, "paliers": [0.5], "titre": "Brûle-Haie", "ligne": "Il met le feu aux haies. Coupez-les avant la flamme."},
}
# PV des ennemis par étage (chaque héros joue son propre tour) ; plancher d'équipement ennemi par étage
const FOE_HP := [2.15, 2.55, 2.95]  # 29/09 : +35 % (on fondait les ennemis plus vite que prévu)
const TERRAIN := [1.35, 1.6, 1.85]  # concile du 29/09 : Choc, noyade, piège, baril, pilier suivent les PV ennemis
const FOE_GEAR_FLOOR := [0.0, 0.35, 0.45]

# Compagnons : des bêtes des Hauts-Fonds apprivoisées au détour d'un événement (rare). Elles jouent seules,
# à leur vitesse, se relèvent à chaque combat. Une seule à la fois.
const COMPANIONS := {
	"crabe": {"name": "Pince, crabe apprivoisé", "hp": 34, "push": 1, "taunt": true, "text": "Encaisse et attire les coups (Provocation), repousse d'une case à chaque pince."},
	"harpie": {"name": "Zéphyr, harpie apprivoisée", "hp": 20, "mark": 2, "text": "Vole au-dessus de tout, fond sur l'ennemi le plus faible et le Marque 2 tours."},
	"crapaud": {"name": "Gloup, crapaud-gouffre", "hp": 28, "pull": 3, "text": "Sa langue attire un ennemi jusqu'à lui depuis 4 cases : parfait pour les pièges et la Tenaille."},
	"chaman": {"name": "Braisille, chaman repenti", "hp": 22, "heal": 7, "text": "Soigne 7 le héros le plus blessé (sous 70 % de ses PV), sinon lance de la braise."},
}

# Ce que chaque ennemi demande au joueur (affiché au survol).
const FOE_TIPS := {
	"husk": "Mort, il vous colle aux pieds : −1 déplacement. Le tuer de loin ou le noyer.",
	"guetteur": "Un tour sur deux, il marque une cible pour les autres. Aller le chercher.",
	"sentinelle": "Ancrée, armure et riposte. Quitter son contact coûte un coup.",
	"wisp": "Explose au contact, ses voisins compris. Le tuer de loin, ou l'attirer dans leur groupe.",
	"gardien": "Trois phases : ne pas rester sur la ligne rouge, casser les vannes, finir vite.",
	"chaman": "Soigne un quart de vie et blinde. Cible prioritaire.",
	"carapace": "Lourde : une poussée dans l'eau la coule. Aux étages 2-3, ancrée tant qu'elle a de l'armure : percer, puis noyer.",
	"rodeur": "Rapide, fond sur le héros isolé. Rester groupé.",
	"lancier": "Côte à côte, ils se blindent et ripostent double. Les séparer.",
	"cavalier": "Frappe puis reflue au loin. Le coincer contre l'eau.",
	"vouivre": "Vole, et un tour sur deux emporte un héros vers l'eau. Rester loin des berges.",
	"mage": "Sa magie ignore l'armure. Fragile : aller le chercher.",
	"bretteur": "Frappe ×1,5 un héros déjà blessé ce round. Espacer les cibles.",
	"danseuse": "Fait rejouer un allié qui a déjà agi. À abattre en premier.",
	"capitaine": "Charge dès qu'on le touche. Ses soldats proches frappent +2 et courent.",
	"baliste": "Immobile, tire de 2 à 8 cases. Se coller à elle.",
	"crabe": "Ancré tant qu'il a de l'armure. La percer, puis le noyer.",
	"crapaud": "Sa langue attire un héros jusqu'à lui depuis 4 cases, puis mord.",
	"harpie": "En meute : +2 par sœur sur la même cible. Briser la meute.",
	"obelisque": "Appelle une créature au début du round. L'abattre étourdit ce qu'il a appelé.",
	"frondeur": "Perché, il tire +3. Monter plus haut que lui, ou le faire descendre.",
	"pavoiseur": "Son pavois divise par deux les coups de face. Le contourner.",
	"anguille": "Mord et tire depuis l'eau ceux qui restent sur la berge. Tirée à terre, elle est Échouée : ×1,5.",
	"fanal": "Pas de dos dans sa lumière. Éteint, il laisse exposés tous ceux qu'il éclairait.",
	"treuil": "Donne +3 d'armure par tour à Grelin. Le casser l'expose.",
	"grelin": "Casser ses treuils, le prendre de dos, sortir de la ligne rouge.",
	"tenant": "Intercepte le premier coup du round sur son voisin. Le gaspiller ou l'écarter.",
	"pisteuse": "Tire sur qui se téléporte à 5 cases d'elle. La tuer, l'enfumer, ou marcher.",
	"penitente": "Purifie un allié par tour et vous renvoie sa Marque. La tuer avant de marquer.",
	"bitte": "Encaisse 40 % des coups portés à ses deux amarrés. La briser les étourdit.",
	"hale": "Couvre Brasse d'un coup par round. Tuer l'un enrage l'autre.",
	"brasse": "Sa gaffe attire, sa Botte frappe ×1,5 qui est déjà blessé. Sans ancre : l'éloigner de Hale.",
	"vanne": "Inonde 2 cases près de vous chaque round. La casser, ou quitter la berge.",
	"pilori": "Enchaîne votre provocateur un tour sur deux. Le briser le libère.",
	"eclusier_fou": "Pose un baril près de votre groupe un tour sur deux ; il saute au round suivant. S'écarter, ou le faire sauter plus tôt.",
	"noye_ancien": "Dans l'eau : ancré et +3. Tiré à terre : Asséché, sans armure. Pas de noyade possible.",
	"porte_etendard": "À 2 cases de lui, rien ne se pousse. L'abattre d'abord.",
	"fouisseur": "La case qu'il frappe s'effondre au round suivant. Ne pas y rester.",
	"chevrier": "Coupe le pont le plus proche de vous à chaque tour. Abattre un arbre au bord de l'eau jette un tronc en travers.",
	"chevre": "Frappe peu, mais repousse d'une case : gare aux berges.",
	"dame": "La crue avance d'un rang par tour. Casser ses vannes l'arrête ; poussée dans l'eau, elle s'y noie (lourdement).",
	"vanne_dame": "Nourrit la crue de la Dame. Toutes cassées : l'eau cesse de monter.",
	"brule_haie": "Fait couver l'arbre le plus proche de vous : il flambe au round suivant et gagne ses voisins. Abattre la haie avant la flamme.",
}

# kind : atk | skill | move. target : foe (défaut pour atk) | self | ally | tile | line
const CARDS := {
	"frappe": {"name": "Frappe", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "trig": {"on": "grace", "draw": 1}, "text": "Inflige {dmg}."},
	"pavois": {"name": "Pavois", "owner": "garde", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 6, "text": "Gagne {block} d'armure."},
	"charge": {"name": "Charge", "owner": "garde", "rar": 1, "cost": 2, "kind": "atk", "target": "line", "range": [1, 3], "dmg": 8, "push": 1, "crash": 2, "trig": {"on": "enchaine", "block": 4}, "text": "Fonce sur un ennemi. Inflige {dmg}. Repousse {push}. Choc : +{crash}."},
	"defi": {"name": "Défi", "owner": "garde", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "block": 4, "taunt": true, "text": "+{block} armure. Provocation."},
	"rempart": {"name": "Rempart", "owner": "garde", "rar": 2, "cost": 2, "kind": "skill", "target": "self", "block": 6, "adj": true, "text": "+{block} armure au Garde et aux alliés voisins."},
	"marteau": {"name": "Marteau d'écluse", "owner": "garde", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 11, "push": 2, "trig": {"on": "grace", "block": 6}, "text": "Inflige {dmg} et repousse de {push}."},
	"bastion": {"name": "Bastion", "owner": "garde", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "block": 3, "draw": 1, "text": "Gagne {block} d'armure. Pioche 1."},
	"estoc": {"name": "Estoc", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "backstab": 2.0, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}. De dos : ×2."},
	"ombre": {"name": "Pas de l'ombre", "owner": "lame", "rar": 1, "cost": 0, "kind": "move", "target": "tile", "range": [1, 3], "text": "Téléportation, relief ignoré."},
	"double": {"name": "Double lame", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 3, "hits": 2, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg} deux fois."},
	"venin": {"name": "Venin", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 2, "poison": 4, "trig": {"on": "enchaine", "poison": 2}, "text": "Inflige {dmg} et {poison} de poison."},
	"couperet": {"name": "Couperet", "owner": "lame", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 9, "execute": true, "trig": {"on": "mur", "dmg": 6}, "text": "Inflige {dmg}. Doublé si la cible est sous la moitié de ses PV."},
	"ricochet": {"name": "Ricochet", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 5, "bounce": true, "trig": {"on": "grace", "refund": true}, "text": "Dague : {dmg}, rebondit sur un voisin."},
	"braise": {"name": "Braise", "owner": "oracle", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 6, "trig": {"on": "precision", "dmg": 3}, "text": "Inflige {dmg} à distance."},
	"seve": {"name": "Sève", "owner": "oracle", "rar": 1, "cost": 1, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 7, "trig": {"on": "mur", "heal": 4}, "text": "Soigne {heal} un allié."},
	"colonne": {"name": "Colonne de cendre", "owner": "oracle", "rar": 2, "cost": 2, "kind": "atk", "target": "tile", "range": [2, 5], "dmg": 7, "aoe": true, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} en croix autour d'une case."},
	"maree": {"name": "Marée", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 3, "push": 3, "text": "Inflige {dmg}. Repousse {push}."},
	"surveil": {"name": "Miroir d'eau", "owner": "oracle", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "draw": 2, "exhaust": true, "text": "Pioche {draw}. Épuise."},
	"delve": {"name": "Feu de tout bois", "owner": "oracle", "rar": 3, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 0, "delve": true, "exhaust": true, "text": "2 dégâts par carte en défausse, puis la défausse est exilée. Épuise."},
	"bouclier": {"name": "Pavois volant", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 3], "dmg": 5, "push": 1, "block": 3, "trig": {"on": "mur", "block": 5}, "text": "Lance le pavois : {dmg}, repousse 1, +{block} armure."},
	"crochet": {"name": "Coup de gaffe", "owner": "garde", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 3], "dmg": 4, "pull": 2, "text": "Inflige {dmg} et attire l'ennemi de 2 cases."},
	"forteresse": {"name": "Forteresse", "owner": "garde", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "forteresse", "text": "L'armure des héros ne s'efface plus en début de tour."},
	"fente": {"name": "Fente", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "target": "line", "range": [1, 4], "dmg": 7, "trig": {"on": "grace", "refund": true}, "text": "Fonce sur un ennemi et frappe : {dmg}."},
	"embuscade": {"name": "Embuscade", "owner": "lame", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "ambush": true, "draw": 1, "text": "Le prochain coup de la Lame compte comme de dos. Pioche 1."},
	"coupures": {"name": "Mille coupures", "owner": "lame", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "coupures", "text": "Chaque carte jouée inflige 1 à un ennemi au hasard."},
	"arc": {"name": "Arc de braise", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 3, "chain": 3, "trig": {"on": "precision", "dmg": 2}, "text": "Inflige {dmg}. Saute ensuite sur 2 ennemis proches."},
	"echo": {"name": "Écho", "owner": "oracle", "rar": 3, "cost": 1, "kind": "skill", "target": "self", "echo": true, "exhaust": true, "text": "La prochaine carte jouée ce tour agit deux fois. Épuise."},
	"cendres": {"name": "Pluie de cendres", "owner": "oracle", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "cendres", "val": 1, "text": "Chaque tour de l'Oracle, 5 dégâts à l'ennemi le plus proche."},
	"grenade": {"name": "Grenade", "owner": "artificier", "rar": 1, "cost": 1, "kind": "atk", "target": "tile", "range": [2, 4], "dmg": 5, "aoe": true, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} en croix autour d'une case."},
	"baril": {"name": "Baril de poudre", "owner": "artificier", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "baril", "draw": 1, "text": "Pose un baril : frappé, il explose sur 3×3, héros compris. Pioche {draw}."},
	"etincelle": {"name": "Étincelle", "owner": "artificier", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 5], "dmg": 0, "detonate": true, "text": "Fait sauter un baril ou un brasero."},
	"rivet": {"name": "Rivet", "owner": "artificier", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "block": 4, "trig": {"on": "mur", "block": 6}, "text": "Inflige {dmg}. +{block} armure."},
	"tourelle": {"name": "Tourelle", "owner": "artificier", "rar": 2, "cost": 2, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "tdmg": 5, "turns": 3, "text": "Pose une tourelle : {tdmg} au plus proche à chaque round, {turns} rounds."},
	"surcharge": {"name": "Surcharge", "owner": "artificier", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "energy": 1, "draw": 1, "exhaust": true, "text": "+1 énergie, pioche 1. Épuise."},
	"mortier": {"name": "Mortier", "owner": "artificier", "rar": 3, "cost": 2, "kind": "atk", "target": "tile", "range": [3, 6], "dmg": 9, "aoe": true, "trig": {"on": "premier", "dmg": 4}, "text": "Obus en croix : {dmg}."},
	"atelier": {"name": "Atelier", "owner": "artificier", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "atelier", "text": "Chaque tour, un baril apparaît près d'un ennemi."},
	"paume": {"name": "Paume", "owner": "moine", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 3, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg}. Nourrit l'enchaînement."},
	"poing": {"name": "Poing-marteau", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "combo": 3, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}, +{combo} par coup déjà porté ce tour."},
	"tourbillon": {"name": "Tourbillon", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "target": "self", "dmg": 5, "around": true, "text": "Frappe chaque ennemi voisin : {dmg}."},
	"bond": {"name": "Bond de grue", "owner": "moine", "rar": 1, "cost": 0, "kind": "move", "target": "tile", "range": [1, 2], "blink": true, "text": "Bondit, relief ignoré."},
	"souffle": {"name": "Souffle calme", "owner": "moine", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "heal": 5, "draw": 1, "text": "Se soigne de {heal}. Pioche 1."},
	"ressac": {"name": "Paume du ressac", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "push": 2, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} et repousse de 2."},
	"cent": {"name": "Cent poings", "owner": "moine", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 2, "hits": 5, "trig": {"on": "mur", "dmg": 1}, "text": "Inflige {dmg} cinq fois."},
	"voie": {"name": "Compte de trois", "owner": "moine", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "voie", "text": "Chaque 3e coup du Moine dans un tour : +1 énergie, pioche 1."},
	"fleche": {"name": "Flèche lestée", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 6, "trig": {"on": "precision", "dmg": 4}, "text": "Inflige {dmg} à distance."},
	"piege": {"name": "Piège à mâchoires", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "piege", "tdmg": 8, "text": "Pose un piège ({tdmg})."},
	"marque": {"name": "Marque du chasseur", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 3, "mark": 2, "trig": {"on": "premier", "draw": 1}, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tours."},
	"filet": {"name": "Filet lesté", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 2, "root": 2, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours."},
	"pluie": {"name": "Pluie de flèches", "owner": "trappeur", "rar": 2, "cost": 2, "kind": "atk", "target": "tile", "range": [2, 5], "dmg": 5, "aoe": true, "text": "Inflige {dmg} en croix autour d'une case."},
	"harpon": {"name": "Harpon", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 4, "pull": 3, "trig": {"on": "grace", "draw": 1}, "text": "Inflige {dmg} et tire l'ennemi de 3 cases vers soi."},
	"perforant": {"name": "Tir perforant", "owner": "trappeur", "rar": 3, "cost": 2, "kind": "atk", "range": [2, 6], "dmg": 12, "pierce": true, "trig": {"on": "surplomb", "dmg": 5}, "text": "Inflige {dmg}, ignore l'armure."},
	"instinct": {"name": "Mâchoires affûtées", "owner": "trappeur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "instinct", "text": "Les pièges infligent +6 et l'ennemi pris devient Marqué."},
	"esquisse": {"name": "Esquisse", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 5, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg}."},
	"recul": {"name": "Recul analytique", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 5, "trig": {"on": "premier", "draw": 1}, "text": "+{block} armure."},
	"journal": {"name": "Journal intime", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "draw": 2, "text": "Pioche {draw}."},
	"pacte": {"name": "Signé au sang", "owner": "tidiane", "voix": "N", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 8, "selfdmg": 2, "trig": {"on": "grixis", "heal": 4}, "text": "Inflige {dmg}, perd {selfdmg} PV."},
	"arbo": {"name": "Pensée arborescente", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "draw": 1, "text": "Pioche {draw}."},
	"wavedash": {"name": "Wavedash", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "block": 4, "text": "Inflige {dmg}, +{block} armure."},
	"punchline": {"name": "Punchline", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 8, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}."},
	"truecombo": {"name": "True combo", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 3, "hits": 3, "text": "Inflige {dmg} trois fois."},
	"monster": {"name": "Canette de trop", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "energy": 1, "selfdmg": 2, "text": "+{energy} énergie, perd {selfdmg} PV."},
	"nuit": {"name": "Nuit blanche", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "draw": 3, "selfdmg": 4, "exhaust": true, "text": "Pioche {draw}, perd {selfdmg} PV. Épuise."},
	"transmutation": {"name": "Transmutation", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 7, "leech": 3, "text": "Inflige {dmg}, soigne 3."},
	"dette": {"name": "La Dette", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 7, "selfdmg": 3, "text": "Inflige {dmg}, perd {selfdmg} PV."},
	"dsm": {"name": "Regard clinique", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 0, "mark": 2, "draw": 1, "text": "L'ennemi est Marqué {mark} tours. Pioche 1."},
	"contreanalyse": {"name": "Arrêt sur image", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 0, "root": 1, "block": 5, "text": "Entravé 1 tour, +{block} armure."},
	"troisvoix": {"name": "Crescendo", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 4, "flow": 2, "text": "Inflige {dmg}, +2 par carte déjà jouée ce tour."},
	"break174": {"name": "Break 174", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 12, "text": "Inflige {dmg}."},
	"purerage": {"name": "Pure rage", "owner": "tidiane", "voix": "R", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 6, "hits": 2, "gives": {"id": "troisvoix", "to": "allies", "free": true}, "text": "Inflige {dmg} deux fois. Chaque allié reçoit un Crescendo gratuit et Éphémère."},
	"potentiel": {"name": "Potentiel brut", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 3, "kind": "atk", "range": [1, 1], "dmg": 16, "trig": {"on": "grixis", "dmg": 8}, "text": "Inflige {dmg}."},
	"revelation": {"name": "La Révélation", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 1, "kind": "skill", "target": "self", "heal": 8, "draw": 2, "exhaust": true, "text": "Soigne {heal}, pioche 2. Épuise."},
	"hyperfocus": {"name": "Hyperfocus", "owner": "tidiane", "voix": "R", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "hyperfocus", "text": "Les attaques de Tidiane infligent +3."},
	"dnb": {"name": "Drum & Bass", "owner": "tidiane", "voix": "B", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "dnb", "text": "Pioche 1 carte de plus à chaque tour."},
	"obsession": {"name": "Obsession", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 3, "kind": "power", "target": "self", "power": "obsession", "text": "+1 énergie à chaque tour."},
	"larcin": {"name": "Larcin", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "steal": true, "trig": {"on": "grace", "draw": 1}, "text": "Vole l'objet de la cible, puis inflige {dmg}."},
	"cle": {"name": "Clé anglaise", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "trig": {"on": "mur", "dmg": 3}, "text": "Inflige {dmg}."},
	"bricolage": {"name": "Bricolage", "owner": "receleur", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "craft": 1, "block": 4, "text": "Fabrique 1. +{block} armure."},
	"camelote": {"name": "Jet de camelote", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 3, "junk": 2, "trig": {"on": "precision", "dmg": 3}, "text": "Inflige {dmg}, +{junk} par Stock."},
	"crochetage": {"name": "Crochetage", "owner": "receleur", "rar": 2, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 0, "steal": true, "draw": 1, "text": "Vole l'objet d'un ennemi. Pioche {draw}."},
	"recyclage": {"name": "Recyclage", "owner": "receleur", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "consume": true, "c_energy": 1, "text": "Démonte 1 : +{c_energy} énergie."},
	"contrefacon": {"name": "Contrefaçon", "owner": "receleur", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "copy_item": true, "exhaust": true, "text": "Copie un objet de ta main (niveau 1, Éphémère). Épuise."},
	"coupdesac": {"name": "Coup de sac", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 7, "push": 1, "throw": true, "trig": {"on": "grace", "energy": 1}, "text": "Lance un objet, puis inflige {dmg} et repousse 1."},
	"etal": {"name": "Étal volant", "owner": "receleur", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "craft": 2, "exhaust": true, "text": "Fabrique 2. Épuise."},
	"lecasse": {"name": "Le Casse", "owner": "receleur", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 11, "steal": true, "craft_else": true, "text": "Vole l'objet de la cible (sinon Fabrique 1), puis inflige {dmg}."},
	"marchenoir": {"name": "Marché noir", "owner": "receleur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "marchenoir", "text": "Chaque objet consommé inflige 4 à l'ennemi le plus proche."},
	"poches": {"name": "Poches sans fond", "owner": "receleur", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "poches", "text": "Au début de chaque tour du Receleur, Fabrique 1."},
	"lotus": {"name": "Lotus", "owner": "oracle", "rar": 3, "cost": 2, "kind": "skill", "target": "self", "heal_all": 6, "block": 3, "all": true, "text": "Soigne {heal_all} tous les héros. Armure à chaque héros : +{block} armure."},
	# ---- 80 cartes de classe (25/09) : 3 archétypes par classe, conçues par designers puis panel Timmy, Johnny, Spike, Vorthos, Melvin
	"c_ancrage": {"name": "Ancrage", "owner": "garde", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 4, "trig": {"on": "immobile", "block": 4, "keep": true}, "text": "+{block} armure.", "up": [{"block": 2}, {"trig": {"on": "immobile", "block": 6, "keep": true, "draw": 1}}], "arch": "L'Enclume"},
	"c_ouvrir": {"name": "Ouvrir la garde", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "expose": true, "text": "Inflige {dmg}. La cible est Exposée.", "up": [{"dmg": 3}, {"reach": 2, "text": "Pavois lancé : {dmg}. La cible est Exposée."}], "arch": "Le Défi"},
	"c_represailles": {"name": "Représailles", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "trig": {"on": "attaque", "dmg": 4, "block": 3}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}, {"trig": {"on": "attaque", "dmg": 4, "block": 3, "mark": 2}}], "arch": "Le Défi"},
	"c_epaule": {"name": "Coup d'épaule", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "push": 1, "crash": 3, "text": "Inflige {dmg}, repousse {push}. Choc : +{crash} aux deux.", "up": [{"dmg": 2, "crash": 2}, {"push": 1}], "arch": "Brise-lames"},
	"c_ecailles": {"name": "Tenir la position", "owner": "garde", "rar": 2, "cost": 1, "kind": "power", "target": "self", "power": "ecailles", "val": 3, "text": "Fin de tour sans avoir marché : le héros gagne {val} armure, qui reste.", "up": [{"val": 1}, {"cost": -1}], "arch": "L'Enclume"},
	"c_interposition": {"name": "Interposition", "owner": "garde", "rar": 2, "cost": 1, "kind": "skill", "target": "ally", "range": [1, 3], "swap": true, "block": 5, "text": "Échange de place avec un allié, qui gagne {block} armure.", "up": [{"block": 3}, {"ambush": true, "text": "Échange de place avec un allié, qui gagne {block} armure. Le prochain coup du Garde compte comme de dos."}], "arch": "Le Défi"},
	"c_remous": {"name": "Sur les talons", "owner": "garde", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "trig": {"on": "chasse", "dmg": 6, "draw": 1}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}, {"push": 1, "text": "Inflige {dmg} et repousse {push}."}], "arch": "Brise-lames"},
	"c_lacher": {"name": "Lâcher d'écluse", "owner": "garde", "rar": 2, "cost": 2, "kind": "atk", "target": "self", "dmg": 5, "around": true, "push": 1, "crash": 3, "text": "Frappe chaque ennemi voisin : {dmg}. Repousse 1. Choc : +{crash}.", "up": [{"dmg": 2}, {"block": 6, "text": "Frappe chaque ennemi voisin : {dmg}. Repousse 1. Choc : +{crash}. +{block} armure."}], "arch": "Brise-lames"},
	"c_contrepoids": {"name": "Contrepoids", "owner": "garde", "rar": 3, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 3, "per_block": 1.0, "spend_block": 0.5, "text": "Inflige {dmg} + l'armure du héros (12 au plus), puis il en perd la moitié.", "up": [{"dmg": 2}, {"push": 1, "text": "Inflige {dmg} + l'armure du héros (12 au plus), puis il en perd la moitié. Repousse {push}."}], "arch": "L'Enclume"},
	"c_vindicte": {"name": "Vindicte", "owner": "garde", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "vindicte", "val": 3, "text": "Tout ennemi qui frappe le héros au contact subit {val} et devient Exposé.", "up": [{"val": 2}, {"cost": -1}], "arch": "Le Défi"},
	"c_gar2_verglas": {"name": "Verglas", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "target": "tile", "range": [1, 3], "aoe": true, "dmg": 3, "ground": "glace", "text": "Inflige {dmg} en croix ; ces cases deviennent Glace.", "up": [{"dmg": 2}, {"reach": 1}], "arch": "Brise-lames"},
	"c_gar2_carcan": {"name": "Mise au carcan", "owner": "garde", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "root": 1, "expose": true, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tour et Exposé.", "up": [{"dmg": 3}, {"root": 1, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours et Exposé."}], "arch": "Le Défi"},
	"c_gar2_enlisement": {"name": "Pieds dans la vase", "owner": "garde", "rar": 3, "cost": 1, "kind": "skill", "target": "self", "block": 8, "ground": "vase", "trig": {"on": "immobile", "block": 4, "keep": true}, "text": "+{block} armure. Les 4 cases voisines du héros deviennent Vase.", "up": [{"block": 3}, {"trig": {"on": "immobile", "block": 6, "keep": true, "draw": 1}}], "arch": "L'Enclume"},
	"c_gar3_mot_ordre": {"name": "Mot d'ordre", "owner": "garde", "rar": 3, "cost": 2, "kind": "skill", "target": "self", "range": [0, 0], "taunt": true, "block": 6, "gives": {"id": "pavois", "to": "allies", "free": true, "n": 1}, "text": "Provocation, +{block} armure. Chaque allié reçoit un Pavois gratuit et Éphémère.", "up": [{"block": 3}, {"cost": -1}], "arch": "Le Défi"},
	"c_feinte": {"name": "Feinte", "owner": "lame", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 2], "dmg": 0, "expose": true, "text": "La cible est Exposée.", "up": [{"draw": 1, "text": "La cible est Exposée. Pioche {draw}."}, {"reach": 2}], "arch": "Le Revers"},
	"c_aiguille": {"name": "Aiguille", "owner": "lame", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 2, "poison": 2, "trig": {"on": "empoisonne", "poison": 1}, "text": "Inflige {dmg} et {poison} de poison.", "up": [{"poison": 1}, {"trig": {"on": "empoisonne", "poison": 1, "draw": 1}}], "arch": "Sève noire"},
	"c_coupe_jarret": {"name": "Coupe-jarret", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "root": 1, "trig": {"on": "empoisonne", "dmg": 4}, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tour.", "up": [{"dmg": 2}, {"root": 1, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours."}], "arch": "Sève noire"},
	"c_kunai": {"name": "Kunaï", "owner": "lame", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 2, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg}.", "up": [{"bounce": true, "text": "Inflige {dmg}, rebondit sur un voisin."}, {"trig": {"on": "enchaine", "dmg": 2, "draw": 1}}], "arch": "Pluie de kunaïs"},
	"c_aller_retour": {"name": "Aller-retour", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 5, "behind": true, "ret": true, "text": "Surgit dans le dos d'un ennemi, frappe, puis revient. Inflige {dmg}.", "up": [{"dmg": 2}, {"draw": 1, "text": "Surgit dans le dos d'un ennemi, frappe, puis revient. Inflige {dmg}. Pioche {draw}."}], "arch": "Le Revers"},
	"c_mue": {"name": "Mue", "owner": "lame", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "iframe": true, "ambush": true, "text": "Esquive le prochain coup. Le prochain coup du héros compte de dos.", "up": [{"draw": 1, "text": "Esquive le prochain coup. Le prochain coup du héros compte de dos. Pioche {draw}."}, {"cost": -1}], "arch": "Le Revers"},
	"c_maceration": {"name": "Macération", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 0, "poison": 2, "poison_x2": true, "exhaust": true, "text": "Ajoute {poison} poison. Déjà empoisonné : son poison double. Épuise.", "up": [{"poison": 1}, {"reach": 2, "draw": 1, "text": "Ajoute {poison} poison. Déjà empoisonné : son poison double. Pioche {draw}. Épuise."}], "arch": "Sève noire"},
	"c_ceinture": {"name": "Ceinture de kunaïs", "owner": "lame", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "add_card": "c_kunai", "add_n": 2, "text": "Ajoute {add_n} Kunaïs Éphémères à la main.", "up": [{"add_n": 1}, {"draw": 1, "text": "Ajoute {add_n} Kunaïs Éphémères à la main. Pioche {draw}."}], "arch": "Pluie de kunaïs"},
	"c_seve_noire": {"name": "Sève noire", "owner": "lame", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "seve_noire", "val": 2, "text": "Quand un ennemi empoisonné meurt, son poison (+{val}) passe à l'ennemi le plus proche.", "up": [{"val": 2}, {"cost": -1}], "arch": "Sève noire"},
	"c_sillage": {"name": "Sillage", "owner": "lame", "rar": 3, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 3, "per_tele": 4, "text": "Inflige {dmg}, +{per_tele} par téléportation du héros ce tour.", "up": [{"per_tele": 1}, {"expose": true, "text": "Inflige {dmg}, +{per_tele} par téléportation du héros ce tour. La cible est Exposée."}], "arch": "Pluie de kunaïs"},
	"c_lam2_kunai_leste": {"name": "Kunaï lesté", "owner": "lame", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 2, "push": 1, "trig": {"on": "bondi", "dmg": 2}, "text": "Inflige {dmg}, repousse {push}.", "up": [{"dmg": 1}, {"push": 1}], "arch": "Pluie de kunaïs"},
	"c_lam2_fiel_tourbieres": {"name": "Fiel des tourbières", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 2, "poison": 3, "trig": {"on": "proie", "poison": 3}, "text": "Inflige {dmg} et {poison} de poison.", "up": [{"poison": 1}, {"root": 1, "text": "Inflige {dmg} et {poison} de poison. L'ennemi est Entravé {root} tour."}], "arch": "Sève noire"},
	"c_lam2_renvoi": {"name": "Poussée dans le dos", "owner": "lame", "rar": 3, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "backstab": 2.0, "push": 2, "crash": 4, "text": "Inflige {dmg}, repousse {push}. De dos : ×2. Choc : +{crash}.", "up": [{"dmg": 2}, {"trap_behind": true, "tdmg": 6, "text": "Inflige {dmg}, pose un piège ({tdmg}) derrière la cible puis la repousse {push}. De dos : ×2. Choc : +{crash}."}], "arch": "Le Revers"},
	"c_pas_braise": {"name": "Pas de braise", "owner": "oracle", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "rune": "lave", "block": 4, "text": "Une case libre devient une Faille de braise. +{block} armure.", "up": [{"block": 3}, {"lure": 1, "text": "Une case libre devient une Faille de braise ; les ennemis à 4 cases avancent de {lure} vers elle. +{block} armure."}], "arch": "Semeur de failles"},
	"c_tison": {"name": "Tison", "owner": "oracle", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 5, "trig": {"on": "sol", "dmg": 5}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}, {"trig": {"on": "sol", "dmg": 5, "draw": 1}}], "arch": "Semeur de failles"},
	"c_palimpseste": {"name": "Palimpseste", "owner": "oracle", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "recall": 1, "block": 4, "text": "Reprend au hasard {recall} carte de la défausse (−1 coût ce tour). +{block} armure.", "up": [{"block": 3}, {"recall": 1, "text": "Reprend au hasard {recall} cartes de la défausse (−1 coût ce tour). +{block} armure."}], "arch": "Palimpseste"},
	"c_ondee": {"name": "Ondée", "owner": "oracle", "rar": 1, "cost": 1, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 6, "spill": true, "text": "Soigne {heal} un allié ; le surplus déborde.", "up": [{"heal": 3}, {"block": 4, "text": "Soigne {heal} un allié ; le surplus déborde. Armure pour l'allié : +{block} armure."}], "arch": "Marée montante"},
	"c_eruption": {"name": "Éruption", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "target": "tile", "range": [2, 4], "dmg": 4, "aoe": true, "trig": {"on": "sol", "dmg": 4}, "text": "Inflige {dmg} en croix autour d'une case.", "up": [{"dmg": 2}, {"trig": {"on": "sol", "dmg": 4, "energy": 1}}], "arch": "Semeur de failles"},
	"c_scelle": {"name": "Scellé dans la braise", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 5, "root": 1, "trig": {"on": "sol", "dmg": 5}, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tour.", "up": [{"root": 1, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours."}, {"expose": true, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours et Exposé."}], "arch": "Semeur de failles"},
	"c_reminiscence": {"name": "Réminiscence", "owner": "oracle", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "flashback": true, "text": "Flashback. Sans carte Épuisée : pioche 1.", "up": [{"retain": true, "text": "Conservé. Flashback. Sans carte Épuisée : pioche 1."}, {"recall": 1, "text": "Conservé. Flashback. Sans carte Épuisée : pioche 1. Reprend au hasard {recall} carte de la défausse (−1 coût ce tour)."}], "arch": "Palimpseste"},
	"c_reflux": {"name": "Reflux", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 4, "push": 2, "heal_adj": true, "spill": true, "text": "Inflige {dmg}, repousse {push}. Un allié blessé à 2 cases regagne autant ; le surplus déborde.", "up": [{"dmg": 2}, {"push": 1}], "arch": "Marée montante"},
	"c_phenix": {"name": "Phénix de papier", "owner": "oracle", "rar": 3, "cost": 2, "kind": "skill", "target": "self", "flashback": true, "echo": true, "exhaust": true, "text": "Flashback. La prochaine carte jouée agit deux fois. Épuise.", "up": [{"cost": -1}, {"retain": true, "text": "Conservé. Flashback. La prochaine carte jouée agit deux fois. Épuise."}], "arch": "Palimpseste"},
	"c_maree_haute": {"name": "Marée haute", "owner": "oracle", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "maree_haute", "val": 2, "text": "Tout soin en trop reçu par un héros déborde, avec +{val} dégâts.", "up": [{"val": 1}, {"val2": 1, "text": "Tout soin en trop reçu par un héros déborde, avec +{val} dégâts, et repousse de 1 l'ennemi touché."}], "arch": "Marée montante"},
	"c_ora2_augure": {"name": "Mauvais augure", "owner": "oracle", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 3, "omen": 5, "trig": {"on": "sol", "dmg": 3}, "text": "Inflige {dmg}. Présage sous la cible : {omen} dégâts.", "up": [{"omen": 3}, {"root": 1, "text": "Inflige {dmg}. Présage sous la cible : {omen} dégâts. Elle est Entravée {root} tour."}], "arch": "Semeur de failles"},
	"c_ora2_presage_crue": {"name": "Présage de crue", "owner": "oracle", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "mark_near": 1, "heal_ally": 5, "text": "L'ennemi le plus proche est Marqué {mark_near} tour. L'allié le plus blessé regagne {heal_ally} PV.", "up": [{"heal_ally": 3}, {"ground": "vase", "text": "L'ennemi le plus proche est Marqué {mark_near} tour. L'allié le plus blessé regagne {heal_ally} PV. Les 4 cases autour du héros deviennent Vase."}], "arch": "Marée montante"},
	"c_ora2_archives": {"name": "Archives en cendres", "owner": "oracle", "rar": 3, "cost": 2, "kind": "atk", "target": "tile", "range": [2, 4], "dmg": 5, "aoe": true, "per_exhaust": 2, "exhaust": true, "text": "Inflige {dmg} en croix, +{per_exhaust} par carte Épuisée par l'Oracle ce combat. Épuise.", "up": [{"per_exhaust": 1}, {"exhaust": false, "text": "Inflige {dmg} en croix, +{per_exhaust} par carte Épuisée par l'Oracle ce combat."}], "arch": "Palimpseste"},
	"c_ora3_lanterne": {"name": "Lanterne partagée", "owner": "oracle", "rar": 2, "cost": 2, "kind": "skill", "target": "self", "block": 3, "gives": {"id": "braise", "to": "allies", "free": true, "n": 1}, "text": "+{block} armure. Chaque allié reçoit une Braise gratuite et Éphémère.", "up": [{"block": 2}, {"adj": true, "text": "+{block} armure, aussi aux alliés au contact. Chaque allié reçoit une Braise gratuite et Éphémère."}], "arch": "Semeur de failles"},
	"c_trainee": {"name": "Traînée de poudre", "owner": "artificier", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "baril", "lure": 1, "text": "Pose un baril. Les ennemis à 4 cases avancent de {lure} vers le baril.", "up": [{"lure": 1}, {"draw": 1, "text": "Pose un baril. Les ennemis à 4 cases avancent de {lure} vers le baril. Pioche {draw}."}], "arch": "Poudrière"},
	"c_poudre_recup": {"name": "Fond de baril", "owner": "artificier", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "draw": 1, "trig": {"on": "poudre", "energy": 1}, "text": "Pioche {draw}.", "up": [{"trig": {"on": "poudre", "energy": 1, "draw": 1}}, {"retain": true, "text": "Conservé. Pioche {draw}."}], "arch": "Chaudière"},
	"c_tourelle_fortune": {"name": "Tourelle de fortune", "owner": "artificier", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "tdmg": 1, "tgrow": 2, "turns": 3, "text": "Tourelle, {turns} rounds : {tdmg} au plus proche, +{tgrow} à chaque tir.", "up": [{"turns": 1}, {"tfar": true, "text": "Tourelle, {turns} rounds : {tdmg} à l'ennemi Marqué, sinon au plus éloigné ; +{tgrow} à chaque tir."}], "arch": "Chantier de siège"},
	"c_rafale_rivets": {"name": "Rafale de rivets", "owner": "artificier", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 5, "hits": 0, "xcost": {"hits": 1}, "text": "Coût X. Inflige {dmg}. Frappe X fois.", "up": [{"dmg": 1}, {"pierce": true, "text": "Coût X. Ignore l'armure. Inflige {dmg}. Frappe X fois."}], "arch": "Chaudière"},
	"c_brulot": {"name": "Brûlot", "owner": "artificier", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 4, "per_boom": 3, "text": "Inflige {dmg}, +{per_boom} par baril sauté ce tour.", "up": [{"per_boom": 2}, {"chain": 2, "text": "Inflige {dmg}, +{per_boom} par baril sauté ce tour, puis saute sur un ennemi proche."}], "arch": "Poudrière"},
	"c_demolition": {"name": "Charge de démolition", "owner": "artificier", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 4, "stick": 7, "text": "Inflige {dmg}. Charge collée : {stick} autour de la cible en fin de tour.", "up": [{"stick": 3}, {"push": 1, "text": "Inflige {dmg}, repousse {push}. Charge collée : {stick} autour de la cible en fin de tour."}], "arch": "Poudrière"},
	"c_ressort": {"name": "Tourelle à ressort", "owner": "artificier", "rar": 2, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "tdmg": 2, "tpush": 1, "turns": 3, "text": "Tourelle, {turns} rounds : {tdmg} et repousse {tpush} l'ennemi le plus proche.", "up": [{"turns": 1}, {"lure": 1, "text": "Tourelle, {turns} rounds : {tdmg} et repousse {tpush} l'ennemi le plus proche. Les ennemis à 4 cases avancent de {lure} vers elle."}], "arch": "Chantier de siège"},
	"c_decharge": {"name": "Décharge", "owner": "artificier", "rar": 2, "cost": 0, "kind": "atk", "range": [1, 4], "dmg": 4, "chain": 1, "xcost": {"chain": 1}, "text": "Coût X. Inflige {dmg}. Saute ensuite sur X ennemis proches.", "up": [{"dmg": 1}, {"volt": true, "text": "Coût X. Inflige {dmg}. Saute ensuite sur X ennemis proches. Tous les barils et braseros à 3 cases de la cible sautent."}], "arch": "Chaudière"},
	"c_bombarde": {"name": "Bombarde de siège", "owner": "artificier", "rar": 3, "cost": 2, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "tdmg": 3, "tgrow": 2, "turns": 4, "trange": 6, "text": "Pose une bombarde : {turns} rounds, {tdmg} à l'ennemi le plus proche (6 cases), +{tgrow} par tir.", "up": [{"tgrow": 1}, {"tpierce": true, "text": "Pose une bombarde : {turns} rounds, {tdmg} à l'ennemi le plus proche (6 cases), armure ignorée, +{tgrow} par tir."}], "arch": "Chantier de siège"},
	"c_salve": {"name": "Salve de mortiers", "owner": "artificier", "rar": 3, "cost": 0, "kind": "atk", "target": "tile", "range": [3, 6], "dmg": 3, "aoe": true, "xcost": {"dmg": 4}, "text": "Coût X. Obus en croix : {dmg}, +4 par énergie.", "up": [{"dmg": 2}, {"ground": "glace", "text": "Coût X. Obus en croix : {dmg}, +4 par énergie. Ces cases deviennent Glace."}], "arch": "Chaudière"},
	"c_art2_baril_blinde": {"name": "Baril blindé", "owner": "artificier", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "baril", "block": 5, "text": "Pose un baril. +{block} armure.", "up": [{"block": 3}, {"draw": 1, "text": "Pose un baril. +{block} armure. Pioche {draw}."}], "arch": "Poudrière"},
	"c_art2_tourelle_givre": {"name": "Tourelle givrante", "owner": "artificier", "rar": 2, "cost": 2, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "tdmg": 3, "tpush": 1, "turns": 3, "ground": "glace", "aoe": true, "text": "Tourelle, {turns} rounds : {tdmg} et repousse {tpush} l'ennemi le plus proche. Glace sur les 4 cases autour.", "up": [{"tdmg": 1}, {"reach": 2, "text": "Tourelle, {turns} rounds : {tdmg} et repousse {tpush} l'ennemi le plus proche. Glace sur les 4 cases autour. Se pose jusqu'à {rmax} cases."}], "arch": "Chantier de siège"},
	"c_art2_piston": {"name": "Piston de chaudière", "owner": "artificier", "rar": 3, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 5, "push": 0, "crash": 4, "xcost": {"dmg": 3, "push": 1}, "text": "Coût X. Inflige {dmg}. Par énergie : +3 dégâts, repousse 1. Choc : +{crash}.", "up": [{"crash": 3}, {"dash": true, "reach": 2, "text": "Coût X. Bondit au contact d'un ennemi à {rmax} cases ou moins. Inflige {dmg}. Par énergie : +3 dégâts, repousse 1. Choc : +{crash}."}], "arch": "Chaudière"},
	"c_art3_meches": {"name": "Mèches partagées", "owner": "artificier", "rar": 2, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "baril", "gives": {"id": "etincelle", "to": "allies"}, "text": "Pose un baril. Chaque allié reçoit une Étincelle.", "up": [{"draw": 1, "text": "Pose un baril. Chaque allié reçoit une Étincelle. Pioche {draw}."}, {"lure": 1, "text": "Pose un baril ; les ennemis à 4 cases avancent de {lure} vers lui. Chaque allié reçoit une Étincelle. Pioche {draw}."}], "arch": "Poudrière"},
	"c_gifle_maree": {"name": "Gifle de marée", "owner": "moine", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 1, "hits": 2, "combo": 1, "text": "Inflige {dmg} deux fois, +{combo} par coup déjà porté ce tour.", "up": [{"dmg": 1}, {"push": 1, "text": "Inflige {dmg} deux fois, +{combo} par coup déjà porté ce tour, puis repousse de {push}."}], "arch": "Ressac"},
	"c_pas_chasse": {"name": "Pas de chasse", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 3], "dash": true, "dmg": 6, "trig": {"on": "enchaine", "dmg": 2}, "text": "Bondit au contact d'un ennemi. Inflige {dmg}.", "up": [{"reach": 1}, {"push": 1, "text": "Bondit au contact d'un ennemi. Inflige {dmg} et le repousse de {push}."}], "arch": "Pas de grue"},
	"c_vol_heron": {"name": "Vol du héron", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "vault": true, "dmg": 4, "trig": {"on": "bondi", "dmg": 3}, "text": "Saute par-dessus la cible et frappe {dmg}.", "up": [{"dmg": 2}, {"ret": true, "text": "Saute par-dessus la cible, frappe {dmg}, puis revient."}], "arch": "Pas de grue"},
	"c_paume_ouverte": {"name": "Paume ouverte", "owner": "moine", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 5, "parry": true, "text": "+{block} armure. Renvoie le prochain coup reçu au contact.", "up": [{"block": 3}, {"taunt": true, "text": "+{block} armure. Renvoie le prochain coup reçu au contact. Provocation."}], "arch": "Contre-courant"},
	"c_vague_fond": {"name": "Vague de fond", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "target": "self", "dmg": 3, "around": true, "combo": 2, "text": "Frappe chaque ennemi voisin : {dmg}, +{combo} par coup déjà porté ce tour.", "up": [{"dmg": 2}, {"push": 1, "crash": 2, "text": "Frappe chaque ennemi voisin : {dmg}, +{combo} par coup déjà porté ce tour. Les repousse de {push}. Choc : +{crash}."}], "arch": "Ressac"},
	"c_garde_tigre": {"name": "Garde du tigre", "owner": "moine", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "bph": 3, "draw": 1, "text": "Ce tour, +{bph} armure par coup porté. Pioche {draw}.", "up": [{"bph": 1}, {"ambush": true, "text": "Ce tour, +{bph} armure par coup porté. Pioche {draw}. Ton prochain coup compte de dos."}], "arch": "Ressac"},
	"c_pique_cormoran": {"name": "Piqué du cormoran", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "push": 1, "trig": {"on": "bondi", "dmg": 5}, "text": "Inflige {dmg} et repousse {push}.", "up": [{"dmg": 2}, {"crash": 3, "text": "Inflige {dmg} et repousse {push}. Choc : +{crash}."}], "arch": "Pas de grue"},
	"c_contre_ressac": {"name": "Contre du ressac", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "leech": 3, "trig": {"on": "attaque", "dmg": 5}, "text": "Inflige {dmg}. Se soigne de {leech}.", "up": [{"leech": 2}, {"root": 1, "text": "Inflige {dmg}. Se soigne de {leech}. L'ennemi est Entravé {root} tour."}], "arch": "Contre-courant"},
	"c_danse_grue": {"name": "Danse de la grue", "owner": "moine", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "danse_grue", "val": 3, "text": "Chaque bond ou téléportation du héros lui donne {val} armure.", "up": [{"val": 2}, {"val2": 1, "text": "Chaque bond ou téléportation du héros lui donne {val} armure. 2e du tour : +1 énergie."}], "arch": "Pas de grue"},
	"c_second_souffle": {"name": "Second souffle", "owner": "moine", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 3, "hits": 3, "per_missing": 1, "leech": 5, "text": "Inflige {dmg} trois fois, +{per_missing} par 5 PV manquants. Se soigne de {leech}.", "up": [{"leech": 3}, {"retain": true, "trig": {"on": "mur", "energy": 1}, "text": "Conservé. Inflige {dmg} trois fois, +{per_missing} par 5 PV manquants. Se soigne de {leech}."}], "arch": "Contre-courant"},
	"c_moi2_serres": {"name": "Serres de l'aigrette", "owner": "moine", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "per_tele": 3, "text": "Inflige {dmg}, +{per_tele} par bond ou téléportation du héros ce tour.", "up": [{"dmg": 1}, {"reach": 1, "dash": true, "text": "Bondit au contact d'un ennemi jusqu'à 2 cases. Inflige {dmg}, +{per_tele} par bond ou téléportation du héros ce tour, ce bond compris."}], "arch": "Pas de grue"},
	"c_moi2_reflux": {"name": "Reflux", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "recoil": 1, "trig": {"on": "blesse", "dmg": 5}, "text": "Inflige {dmg} et recule d'1 case.", "up": [{"dmg": 2}, {"leech": 3, "text": "Inflige {dmg}. Se soigne de {leech} et recule d'1 case."}], "arch": "Contre-courant"},
	"c_moi2_equinoxe": {"name": "Marée d'équinoxe", "owner": "moine", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 3, "hits": 3, "bounce": true, "trig": {"on": "enchaine", "energy": 1}, "text": "Inflige {dmg} trois fois. Rebondit ensuite sur un voisin de la cible.", "up": [{"dmg": 1}, {"bounce": false, "chain": 3, "text": "Inflige {dmg} trois fois. Rebondit ensuite sur 2 ennemis proches."}], "arch": "Ressac"},
	"c_moi3_kata": {"name": "Kata", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "gives": {"id": "paume", "to": "self", "free": false, "n": 2}, "text": "Inflige {dmg}. Reçois 2 Paumes Éphémères.", "up": [{"dmg": 2}, {"expose": true, "text": "Inflige {dmg}. La cible est Exposée. Reçois 2 Paumes Éphémères."}], "arch": "Ressac"},
	"c_tir_rabat": {"name": "Tir de rabat", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 4, "trap_behind": true, "tdmg": 5, "text": "Inflige {dmg}. Pose un piège ({tdmg}) derrière la cible.", "up": [{"tdmg": 2}, {"push": 1, "text": "Inflige {dmg}. Pose un piège ({tdmg}) derrière la cible, puis l'y repousse."}], "arch": "Collets et rabattage"},
	"c_coup_crosse": {"name": "Coup de crosse", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "push": 2, "recoil": 1, "trig": {"on": "proie", "draw": 1}, "text": "Inflige {dmg}, repousse {push} et recule d'1 case.", "up": [{"dmg": 2}, {"crash": 3, "text": "Inflige {dmg}, repousse {push} et recule d'1 case. Choc : +{crash}."}], "arch": "Collets et rabattage"},
	"c_tir_affut": {"name": "Tir d'affût", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [3, 6], "dmg": 5, "trig": {"on": "immobile", "dmg": 3}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}, {"mark": 1, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour."}], "arch": "Affût"},
	"c_trace_sang": {"name": "Trace de sang", "owner": "trappeur", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 5], "dmg": 2, "mark": 1, "trig": {"on": "proie", "mark": 2}, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour.", "up": [{"dmg": 1}, {"root": 1, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour et Entravé {root} tour."}], "arch": "Curée"},
	"c_appeau": {"name": "Appeau", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "skill", "target": "tile", "range": [2, 4], "place": "piege", "tdmg": 6, "lure": 2, "text": "Pose un piège ({tdmg}). Les ennemis à 4 cases avancent de {lure} vers le piège.", "up": [{"lure": 1}, {"ambush": true, "text": "Pose un piège ({tdmg}). Les ennemis à 4 cases avancent de {lure} vers le piège. Ton prochain coup compte de dos."}], "arch": "Collets et rabattage"},
	"c_nasse": {"name": "Nasse", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "collet", "tdmg": 4, "draw": 1, "text": "Pose un collet ({tdmg}) : l'ennemi pris est Entravé et volé. Pioche {draw}.", "up": [{"tdmg": 4}, {"lure": 2, "text": "Pose un collet ({tdmg}). Les ennemis à 4 cases avancent de {lure} vers le collet. Pioche {draw}."}], "arch": "Collets et rabattage"},
	"c_nid_guet": {"name": "Nid de guet", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "block": 4, "draw": 1, "trig": {"on": "immobile", "energy": 1}, "text": "+{block} armure. Pioche {draw}.", "up": [{"block": 3}, {"retain": true, "text": "Conservé. +{block} armure. Pioche {draw}."}], "arch": "Affût"},
	"c_signal_meute": {"name": "Signal de meute", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 0, "mark": 2, "shadow_ally": true, "text": "L'ennemi est Marqué {mark} tours. L'allié le plus proche bondit derrière l'ennemi et frappera de dos.", "up": [{"mark": 1}, {"draw": 1, "text": "L'ennemi est Marqué {mark} tours. L'allié le plus proche bondit derrière l'ennemi et frappera de dos. Pioche {draw}."}], "arch": "Curée"},
	"c_carreau_silure": {"name": "Carreau transperçant", "owner": "trappeur", "rar": 3, "cost": 2, "kind": "atk", "range": [3, 7], "dmg": 8, "pierce": true, "chain": 2, "trig": {"on": "immobile", "energy": 1}, "text": "Inflige {dmg}, ignore l'armure, puis traverse vers un ennemi proche.", "up": [{"dmg": 3}, {"chain": 1, "text": "Inflige {dmg}, ignore l'armure, puis traverse vers 2 ennemis proches."}], "arch": "Affût"},
	"c_curee": {"name": "Curée", "owner": "trappeur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "curee", "val": 6, "text": "Quand un ennemi Entravé meurt, un piège ({val}) apparaît sur sa case. Pioche 1.", "up": [{"val": 3}, {"val2": 1, "text": "Quand un ennemi Entravé ou Marqué meurt, un piège ({val}) apparaît sur sa case. Pioche 1."}], "arch": "Curée"},
	"c_tra2_gaule": {"name": "Gaule de rabatteur", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 4, "push": 1, "trig": {"on": "declic", "draw": 1}, "text": "Inflige {dmg}, repousse {push}.", "up": [{"dmg": 2}, {"ground_behind": "glace", "text": "Inflige {dmg}. La case derrière la cible devient Glace, puis la cible y est repoussée de {push} et glisse."}], "arch": "Collets et rabattage"},
	"c_tra2_fondriere": {"name": "Fondrière", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "target": "tile", "range": [2, 4], "dmg": 3, "aoe": true, "ground": "vase", "trig": {"on": "proie", "dmg": 3}, "text": "Inflige {dmg} en croix ; ces cases deviennent Vase.", "up": [{"dmg": 2}, {"reach": 2}], "arch": "Curée"},
	"c_tra2_debusque": {"name": "Carreau assommeur", "owner": "trappeur", "rar": 3, "cost": 2, "kind": "atk", "range": [3, 6], "dmg": 7, "push": 2, "crash": 3, "trig": {"on": "immobile", "dmg": 4}, "text": "Inflige {dmg}, repousse {push}. Choc : +{crash}.", "up": [{"dmg": 3}, {"delay": 2, "text": "Inflige {dmg}, repousse {push}. Choc : +{crash}. L'ennemi recule de {delay} places dans l'initiative."}], "arch": "Affût"},
	"c_tra3_cor": {"name": "Cor de chasse", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 3, "mark": 1, "gives": {"id": "c_trace_sang", "to": "allies"}, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour(s). Chaque allié reçoit une Trace de sang.", "up": [{"dmg": 2}, {"mark": 1}], "arch": "Curée"},
	"c_contretemps": {"name": "Contretemps", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "bpm": 2, "trig": {"on": "premier", "draw": 1}, "text": "BPM +{bpm}.", "up": [{"bpm": 1}, {"retain": true, "text": "Conservé. BPM +{bpm}."}], "arch": "174 BPM"},
	"c_saignee": {"name": "Saignée", "owner": "tidiane", "voix": "N", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "selfdmg": 3, "per_missing": 2, "text": "Perd {selfdmg} PV. Inflige {dmg}. +{per_missing} dégâts par 5 PV manquants.", "up": [{"per_missing": 1}, {"reach": 1}], "arch": "Pacte de sang"},
	"c_ligne_claire": {"name": "Ligne claire", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 5, "trig": {"on": "grixis", "draw": 2}, "text": "Inflige {dmg}.", "up": [{"dmg": 3}, {"mark": 1, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour."}], "arch": "Trinité"},
	"c_coup_de_sang": {"name": "Coup de sang", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "trig": {"on": "blesse", "dmg": 4}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}, {"reach": 2, "dash": true, "text": "Fonce au contact d'un ennemi jusqu'à {rmax} cases, puis inflige {dmg}."}], "arch": "Pacte de sang"},
	"c_drop": {"name": "Le Drop", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 6, "drop": 2, "text": "Inflige {dmg}. Drop ×{drop}.", "up": [{"dmg": 3}, {"target": "self", "around": true, "text": "Frappe chaque ennemi voisin : {dmg}. Drop ×{drop}."}], "arch": "174 BPM"},
	"c_boucle": {"name": "Boucle de 8 mesures", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "recall": 1, "bpm": 1, "text": "Reprend au hasard {recall} carte de la défausse (−1 coût). BPM +{bpm}.", "up": [{"bpm": 1}, {"lvl_next": true, "text": "Reprend au hasard {recall} carte de la défausse (−1 coût). BPM +{bpm}. La prochaine carte jouée ce tour gagne un niveau pour le combat."}], "arch": "174 BPM"},
	"c_rancoeur": {"name": "Rancœur", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 4, "per_missing": 2, "leech": 4, "text": "Inflige {dmg}, +{per_missing} par 5 PV manquants. Se soigne de {leech}.", "up": [{"leech": 2}, {"trig": {"on": "grace", "energy": 1}}], "arch": "Pacte de sang"},
	"c_trinite": {"name": "Bis", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "echo": true, "exhaust": true, "trig": {"on": "grixis", "energy": 1}, "text": "La prochaine carte jouée agit deux fois. Épuise.", "up": [{"retain": true, "text": "Conservé. La prochaine carte jouée agit deux fois. Épuise."}, {"draw": 1, "text": "Conservé. La prochaine carte jouée agit deux fois. Pioche {draw}. Épuise."}], "arch": "Trinité"},
	"c_metronome": {"name": "Métronome", "owner": "tidiane", "voix": "B", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "metronome", "val": 2, "text": "BPM +{val} au début de chaque tour du héros.", "up": [{"val": 1}, {"cost": -1}], "arch": "174 BPM"},
	"c_catharsis": {"name": "Catharsis", "owner": "tidiane", "voix": "R", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 6, "per_missing": 4, "trig": {"on": "grace", "heal": 8}, "text": "Inflige {dmg}, +{per_missing} par 5 PV manquants.", "up": [{"dmg": 3}, {"trig": {"on": "grace", "heal": 8, "refund": true}}], "arch": "Pacte de sang"},
	"c_tid2_double_croche": {"name": "Double croche", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 3, "hits": 2, "bpm": 1, "text": "Inflige {dmg} deux fois. BPM +{bpm}.", "up": [{"dmg": 1}, {"bpm": 1}], "arch": "174 BPM"},
	"c_tid2_cicatrices": {"name": "Peau de cicatrices", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "block": 4, "per_missing_block": 2, "text": "+{block} armure, +{per_missing_block} par 5 PV manquants.", "up": [{"per_missing_block": 1}, {"adj": true, "text": "+{block} armure, +{per_missing_block} par 5 PV manquants. Les alliés au contact en reçoivent autant."}], "arch": "Pacte de sang"},
	"c_tid2_triptyque": {"name": "Triptyque", "owner": "tidiane", "voix": "B", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 3], "dmg": 9, "expose": true, "trig": {"on": "grixis", "energy": 2}, "text": "Inflige {dmg}. La cible est Exposée.", "up": [{"dmg": 3}, {"mark": 2, "text": "Inflige {dmg}. L'ennemi est Exposé et Marqué {mark} tours."}], "arch": "Trinité"},
	"c_tid3_carnet": {"name": "Carnet de croquis", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "bpm": 1, "gives": {"id": "esquisse", "to": "self", "n": 1}, "text": "BPM +{bpm}. Ajoute une Esquisse Éphémère à la main.", "up": [{"bpm": 1}, {"gives": {"id": "esquisse", "to": "allies", "n": 1}, "text": "BPM +{bpm}. Chaque allié reçoit une Esquisse Éphémère."}], "arch": "174 BPM"},
	"c_brocante": {"name": "Établi portatif", "owner": "receleur", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "recharge": 1, "iblock": 2, "text": "Recharge 1. +{iblock} armure par Stock.", "up": [{"iblock": 1}, {"recharge": 1, "text": "Recharge {recharge}. +{iblock} armure par Stock."}], "arch": "L'Établi"},
	"c_revente": {"name": "Revente à la sauvette", "owner": "receleur", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "consume": true, "sell": 10, "draw": 1, "exhaust": true, "text": "Démonte 1 : +{sell} or. Pioche {draw}. Épuise.", "up": [{"sell": 5}, {"draw": 1}], "arch": "Casse et Revente"},
	"c_tire_laine": {"name": "Tire-laine", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 6, "trig": {"on": "butin", "heal": 4}, "text": "Inflige {dmg}.", "up": [{"dmg": 3}, {"steal": true, "text": "Vole l'objet de la cible, puis inflige {dmg}."}], "arch": "Vide-poches"},
	"c_casse_tout": {"name": "Casse-tout", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "per_used": 4, "text": "Inflige {dmg}, +{per_used} par objet consommé ce tour.", "up": [{"per_used": 1}, {"pierce": true, "text": "Ignore l'armure. Inflige {dmg}, +{per_used} par objet consommé ce tour."}], "arch": "Casse et Revente"},
	"c_bonneteau": {"name": "Bonneteau", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 0, "steal": true, "pull": 2, "text": "Vole l'objet d'un ennemi et l'attire de {pull}.", "up": [{"dmg": 5, "text": "Vole l'objet d'un ennemi et l'attire de {pull}. Inflige {dmg}."}, {"expose": true, "text": "Vole l'objet d'un ennemi et l'attire de {pull}. Inflige {dmg}. La cible est Exposée."}], "arch": "Vide-poches"},
	"c_feu_de_joie": {"name": "Feu de joie", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "target": "self", "around": true, "dmg": 3, "per_used": 3, "text": "Frappe chaque ennemi voisin : {dmg}, +{per_used} par objet consommé ce tour.", "up": [{"per_used": 1}, {"push": 1, "text": "Frappe chaque ennemi voisin : {dmg}, +{per_used} par objet consommé ce tour. Repousse chacun de {push}."}], "arch": "Casse et Revente"},
	"c_inventaire": {"name": "Déballage", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "throw": true, "dmg": 4, "junk": 2, "text": "Lance un objet sur la cible, puis inflige {dmg}, +{junk} par Stock.", "up": [{"dmg": 2}, {"mark": 1, "text": "Lance un objet sur la cible, puis inflige {dmg}, +{junk} par Stock. L'ennemi est Marqué {mark} tour."}], "arch": "L'Établi"},
	"c_marchandage": {"name": "Marchandage", "owner": "receleur", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "copy_item": true, "consume": true, "sell": 10, "exhaust": true, "text": "Copie un objet de ta main (Éphémère), puis Démonte l'original : +{sell} or. Épuise.", "up": [{"sell": 5}, {"draw": 1, "text": "Copie un objet de ta main (Éphémère), puis Démonte l'original : +{sell} or. Pioche {draw}. Épuise."}], "arch": "L'Établi"},
	"c_fourgue": {"name": "Le Fourgue", "owner": "receleur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "fourgue", "val": 2, "text": "Chaque vol soigne {val} à chaque héros (1 fois par tour) et Recharge 1 la carte volée.", "up": [{"val": 1}, {"val2": 1, "text": "Chaque vol soigne {val} à chaque héros (1 fois par tour) et Recharge 1 la carte volée. La cible volée est Exposée."}], "arch": "Vide-poches"},
	"c_benne": {"name": "Benne à ferraille", "owner": "receleur", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 6, "need_item": true, "per_used": 4, "text": "Démonte 1 (sinon 0 dégât), puis inflige {dmg}, +{per_used} par objet consommé ce tour.", "up": [{"per_used": 1}, {"exec": true, "text": "Démonte 1 (sinon 0 dégât), puis inflige {dmg}, +{per_used} par objet consommé ce tour. Exécution."}], "arch": "Casse et Revente"},
	"c_rec2_croc": {"name": "Croc-en-jambe", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 3, "steal": true, "push": 1, "text": "Vole l'objet de la cible. Inflige {dmg}. Repousse {push}.", "up": [{"dmg": 3}, {"crash": 3, "text": "Vole l'objet de la cible. Inflige {dmg}. Repousse {push}. Choc : +{crash}."}], "arch": "Vide-poches"},
	"c_rec2_pieces": {"name": "Pièces détachées", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 4, "hits": 2, "need_item": true, "text": "Démonte 1 (sinon 0 dégât), puis inflige {dmg} deux fois.", "up": [{"dmg": 1}, {"bounce": true, "text": "Démonte 1 (sinon 0 dégât), puis inflige {dmg} deux fois, puis rebondit sur un voisin de la cible : {dmg}."}], "arch": "Casse et Revente"},
	"c_rec2_crochet": {"name": "Crochet de brocanteur", "owner": "receleur", "rar": 3, "cost": 1, "kind": "atk", "range": [2, 4], "throw": true, "dmg": 5, "pull": 2, "recharge": 1, "text": "Lance un objet sur la cible, puis inflige {dmg} et l'attire de {pull}. Recharge {recharge}.", "up": [{"dmg": 3}, {"root": 1, "text": "Lance un objet sur la cible, puis inflige {dmg}, l'attire de {pull} et l'Entrave {root} tour. Recharge {recharge}."}], "arch": "L'Établi"},
	# ---- Objets (owner « objet » ; c.has("tool") est le seul test fiable en jeu, Data.card écrase owner)
	"o_fiole": {"name": "Fiole de sève", "owner": "objet", "tool": "fiole", "rar": 2, "cost": 0, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 10, "forge2": true,
		"text": "Soigne {heal} un allié.",
		"up": [{"heal": 2, "cleanse": "poison", "text": "Soigne {heal} un allié. Retire le poison de l'allié."},
			{"heal": 4, "cleanse": "all", "overheal": true, "exhaust": true, "legend": true, "name": "Sève vive", "text": "Soigne {heal} un allié. Retire poison et entraves de l'allié ; le surplus devient armure."}]},
	"o_fumigene": {"name": "Fumigène", "owner": "objet", "tool": "fumigene", "rar": 1, "cost": 0, "kind": "skill", "target": "tile", "range": [0, 3], "smoke": 2,
		"text": "Fumée {smoke} tours en croix : pas de tir à distance, coups au contact de dos.",
		"up": [{"smoke": 1, "block": 4, "text": "Fumée {smoke} tours en croix : pas de tir à distance, coups au contact de dos. Armure au lanceur : +{block} armure."},
			{"block": -4, "area": "diamond", "smoke_block": 6, "exhaust": true, "legend": true, "name": "Rideau de fumée", "text": "Fumée {smoke} tours sur 2 cases de rayon. Chaque héros dans la fumée gagne {smoke_block} armure."}]},
	"o_picots": {"name": "Picots", "owner": "objet", "tool": "picots", "rar": 1, "cost": 0, "kind": "skill", "target": "free", "range": [1, 3], "picots": 5,
		"text": "Picots en croix : l'ennemi qui y marche s'arrête et subit {picots}.",
		"up": [{"picots": 2, "range": [1, 4], "text": "Picots en croix : l'ennemi qui y marche s'arrête et subit {picots}."},
			{"picots": 1, "area": "ring", "trap_root": 1, "exhaust": true, "legend": true, "name": "Ronces d'acier", "text": "Picots sur 9 cases : {picots} dégâts, et l'ennemi pris reste Entravé 1 tour."}]},
	"o_grappin": {"name": "Grappin", "owner": "objet", "tool": "grappin", "rar": 1, "cost": 0, "kind": "skill", "target": "free", "range": [2, 5],
		"text": "Se hisse sur une case libre, relief ignoré, et ramasse ce qui s'y trouve.",
		"up": [{"range": [1, 6], "draw": 1, "text": "Se hisse sur une case libre, relief ignoré. Pioche {draw}."},
			{"range": [1, 7], "land_dmg": 6, "exhaust": true, "legend": true, "name": "Grappin d'abordage", "text": "Se hisse sur une case libre, relief ignoré. À l'arrivée : {land_dmg} à chaque ennemi voisin. Pioche {draw}."}]},
	"o_arbre": {"name": "Gland de chêne", "owner": "objet", "tool": "gland", "rar": 2, "cost": 0, "kind": "skill", "target": "free", "range": [1, 3], "oaks_n": 1, "oak_hp": 10, "oak_aura": 3,
		"text": "Plante un chêne ({oak_hp} PV) qui barre la case. Héros voisins : +{oak_aura} armure par tour. Il brûle au feu.",
		"up": [{"oak_hp": 4, "range": [1, 4], "text": "Plante un chêne ({oak_hp} PV). Héros voisins : +{oak_aura} armure par tour."},
			{"oaks_n": 1, "oak_hp": 4, "oak_arm": 2, "oak_aura": 2, "fireproof": true, "exhaust": true, "legend": true, "name": "Chênes jumeaux",
				"text": "Plante 2 chênes ({oak_hp} PV, 2 armure). Héros voisins : +{oak_aura} armure par tour. Insensibles au feu."}]},
	"o_bombe": {"name": "Bombe à mèche", "owner": "objet", "tool": "bombe", "rar": 1, "cost": 0, "kind": "skill", "target": "tile", "range": [2, 4], "bomb": 8, "forge2": true,
		"text": "{bomb} dégâts en croix. Fait sauter barils et braseros, embrase les arbres.",
		"up": [{"bomb": 2, "range": [2, 5], "text": "{bomb} dégâts en croix."},
			{"bomb": 2, "area": "ring", "push": 1, "exhaust": true, "legend": true, "name": "Soleil de poudre", "text": "{bomb} dégâts sur 9 cases, repousse de 1 depuis le centre. Fait tout sauter."}]},
	"o_baril": {"name": "Baril", "owner": "objet", "tool": "tonnelet", "rar": 1, "cost": 0, "kind": "skill", "target": "free", "range": [1, 2], "barils": 1,
		"text": "Pose un baril de poudre : frappé, il explose (7 autour).",
		"up": [{"barils": 1, "range": [1, 3], "text": "Pose 2 barils en ligne, dans l'axe du lancer."},
			{"barils": 1, "draw": 1, "exhaust": true, "legend": true, "name": "Poudrière", "text": "Pose 3 barils en ligne, dans l'axe du lancer. Pioche {draw}."}]},
	"o_brasero": {"name": "Brasero", "owner": "objet", "tool": "brasero", "rar": 1, "cost": 0, "kind": "skill", "target": "free", "range": [1, 2], "aura": 3,
		"text": "Brasero : {aura} à chaque ennemi voisin en fin de manche. Frappé, il explose (7 autour).",
		"up": [{"aura": 1, "range": [1, 3], "text": "Brasero : {aura} à chaque ennemi voisin en fin de manche."},
			{"aura": 2, "exhaust": true, "legend": true, "name": "Brasier", "text": "Brasero : {aura} à chaque ennemi voisin en fin de manche. Frappé, il explose."}]},
	"o_filet": {"name": "Filet lesté", "owner": "objet", "tool": "filet", "rar": 1, "cost": 0, "kind": "skill", "target": "foe", "range": [1, 4], "root": 2,
		"text": "L'ennemi est Entravé {root} tours.",
		"up": [{"expose": true, "range": [1, 5], "text": "L'ennemi est Entravé {root} tours et Exposé."},
			{"splash": true, "exhaust": true, "legend": true, "name": "Coup de filet", "text": "La cible et chaque ennemi à son contact : Entravé {root} tours et Exposé."}]},
	"o_sels": {"name": "Sels de réveil", "owner": "objet", "tool": "sels", "rar": 1, "cost": 0, "kind": "skill", "target": "ally", "range": [0, 3], "cleanse": "all", "block": 6,
		"text": "Un allié : poison et entraves retirés, +{block} armure.",
		"up": [{"block": 2, "draw": 1, "text": "Un allié : poison et entraves retirés, +{block} armure. Pioche {draw}."},
			{"draw": -1, "all": true, "energy": 1, "exhaust": true, "legend": true, "name": "Réveil général", "text": "Toute l'escouade : poison et entraves retirés, +{block} armure. +{energy} énergie."}]},
	"o_elixir": {"name": "Élixir de braise", "owner": "objet", "tool": "elixir", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "energy": 2, "forge2": true,
		"text": "+{energy} énergie.",
		"up": [{"draw": 1, "text": "+{energy} énergie. Pioche {draw}."},
			{"energy": 1, "draw": 1, "exhaust": true, "legend": true, "name": "Braise vive", "text": "+{energy} énergie. Pioche {draw}."}]},
	"o_carnet": {"name": "Carnet de route", "owner": "objet", "tool": "carnet", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "draw": 3,
		"text": "Pioche {draw} cartes.",
		"up": [{"draw": 1},
			{"cut_drawn": 1, "exhaust": true, "legend": true, "name": "Carnet annoté", "text": "Pioche {draw} cartes ; elles coûtent 1 de moins ce tour."}]},
	"o_ballot": {"name": "Contrat d'embauche", "owner": "objet", "tool": "ballot", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "heist": 1, "heist_plain": true,
		"text": "Embauche.",
		"up": [{"heist_plain": false, "text": "Embauche : la carte gardée coûte 1 de moins."},
			{"heist": 1, "heist_free": true, "exhaust": true, "legend": true, "name": "Plein emploi", "text": "Embauche deux fois ; les cartes gardées coûtent 0 ce tour."}]},
	# Cartes neutres (28/09) : sans classe, n'importe quel héros les joue (ci.h) ; modestes, comme les cartes incolores.
	# Bienfait « Bric-à-brac » au seuil du premier étage. L'Embauche de base (prix plein) est ici ; les Cambrioleurs font mieux.
	"q_coup_oeil": {"name": "Coup d'œil", "owner": "neutre", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "range": [0, 0], "heist": 1, "heist_plain": true, "exhaust": true,
		"text": "Embauche. Épuise.", "up": [{"draw": 1, "text": "Embauche. Pioche {draw}. Épuise."}, {"exhaust": false, "text": "Embauche. Pioche {draw}."}]},
	"q_filiere": {"name": "Petite annonce", "owner": "neutre", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "range": [0, 0], "heist": 1, "heist_plain": true, "draw": 1, "text": "Embauche. Pioche {draw}.", "up": [{"draw": 1}, {"heist_plain": false, "text": "Embauche : la carte gardée coûte 1 de moins. Pioche {draw}."}]},
	"q_arrivage": {"name": "Bras en renfort", "owner": "neutre", "rar": 2, "cost": 2, "kind": "skill", "target": "self", "range": [0, 0], "heist": 2, "heist_plain": true, "exhaust": true,
		"text": "Embauche deux fois. Épuise.", "up": [{"cost": -1}, {"exhaust": false, "text": "Embauche deux fois."}]},
	"q_bandage": {"name": "Bandage", "owner": "neutre", "rar": 1, "cost": 0, "kind": "skill", "target": "ally", "range": [0, 2], "heal": 5, "exhaust": true,
		"text": "Soigne {heal} un allié. Épuise.", "up": [{"heal": 3}, {"exhaust": false, "text": "Soigne {heal} un allié."}]},
	"q_planche": {"name": "Planche", "owner": "neutre", "rar": 1, "cost": 1, "kind": "skill", "target": "ally", "range": [0, 2], "block": 6,
		"text": "+{block} armure à un allié.", "up": [{"block": 3}, {"draw": 1, "text": "+{block} armure à un allié. Pioche {draw}."}]},
	"q_caillou": {"name": "Caillou", "owner": "neutre", "rar": 1, "cost": 0, "kind": "atk", "range": [2, 4], "dmg": 3, "text": "Inflige {dmg}.", "up": [{"dmg": 1}, {"expose": true, "text": "Inflige {dmg}. La cible est Exposée."}]},
	"q_gaffe": {"name": "Coup de perche", "owner": "neutre", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 5, "push": 1,
		"text": "Inflige {dmg}. Repousse {push}.", "up": [{"dmg": 2}, {"push": 1}]},
	"q_rame": {"name": "Coup de rame", "owner": "neutre", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 7,
		"text": "Inflige {dmg}.", "up": [{"dmg": 3}, {"expose": true, "text": "Inflige {dmg}. La cible est Exposée."}]},
	"q_souffle": {"name": "Second souffle", "owner": "neutre", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "range": [0, 0], "energy": 2, "exhaust": true, "text": "+{energy} énergie. Épuise.", "up": [{"draw": 1, "text": "+{energy} énergie. Pioche {draw}. Épuise."}, {"retain": true, "text": "Conservé. +{energy} énergie. Pioche {draw}. Épuise."}]},
	"q_lanterne": {"name": "Lanterne sourde", "owner": "neutre", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "range": [0, 0], "draw": 2, "text": "Pioche {draw}.", "up": [{"draw": 1}, {"mark_near": 1, "text": "Pioche {draw}. L'ennemi le plus proche est Marqué {mark_near} tour."}]},
	"o_de": {"name": "Dé pipé", "owner": "objet", "tool": "de", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "reroll": 1,
		"text": "Défausse la main et repioche autant de cartes, plus {reroll}.",
		"up": [{"reroll": 1},
			{"energy": 1, "exhaust": true, "legend": true, "name": "Dés plombés", "text": "Défausse la main et repioche autant de cartes, plus {reroll}. +{energy} énergie."}]},
	"o_sablier": {"name": "Sablier fêlé", "owner": "objet", "tool": "sablier", "rar": 3, "cost": 0, "kind": "skill", "target": "self", "root_all": 1, "forge2": true,
		"text": "Chaque ennemi est Entravé {root_all} tour.",
		"up": [{"block": 4, "all": true, "text": "Chaque ennemi est Entravé {root_all} tour. Armure à chaque héros : +{block} armure."},
			{"block": -4, "expose_all": true, "draw": 1, "exhaust": true, "legend": true, "name": "Sablier brisé", "text": "Chaque ennemi est Entravé {root_all} tour et Exposé. Pioche {draw}."}]},
}

# Trois routes par classe (25/09) : les cartes portent « arch », le butin en propose de différentes.
const ARCHETYPES := {
	"garde": [["L'Enclume", "empiler l'armure sans marcher, puis la dépenser"], ["Le Défi", "attirer les coups, punir, exposer pour les autres"], ["Brise-lames", "repousser contre les murs : le Choc"]],
	"lame": [["Le Revers", "feintes, allers-retours, coups de dos"], ["Sève noire", "un poison qui passe d'ennemi en ennemi"], ["Pluie de kunaïs", "tempo à 0, kunaïs et téléportations"]],
	"oracle": [["Semeur de failles", "créer des cases spéciales, punir qui s'y tient"], ["Palimpseste", "la défausse et le Flashback"], ["Marée montante", "le soin en trop frappe l'ennemi"]],
	"artificier": [["Poudrière", "barils en chaîne"], ["Chantier de siège", "tourelles qui grandissent"], ["Chaudière", "coût X : tout mettre dans un coup"]],
	"moine": [["Ressac", "l'enchaînement de coups"], ["Pas de grue", "bonds et téléportations"], ["Contre-courant", "punir et se battre ensanglanté"]],
	"trappeur": [["Collets et rabattage", "pousser la proie dans les pièges"], ["Affût", "tirer sans bouger d'un pas"], ["Curée", "marquer, entraver, pièges en chaîne"]],
	"tidiane": [["174 BPM", "monter le rythme, lâcher le Drop"], ["Pacte de sang", "les PV manquants frappent"], ["Trinité", "Analyse, Émotion, Ambition"]],
	"receleur": [["L'Établi", "fabriquer, recharger, faire durer ses objets"], ["Casse et Revente", "démonter ses objets pour frapper"], ["Vide-poches", "voler, et le Butin"]],
}

# Decks de départ (revus le 25/09) : les bases plus une graine de chaque route de ARCHETYPES.
const STARTER := {
	"garde": ["frappe", "c_ouvrir", "pavois", "pavois", "charge", "bouclier"],
	"lame": ["estoc", "estoc", "double", "c_aiguille", "ombre", "fente"],
	"oracle": ["braise", "braise", "c_pas_braise", "seve", "c_ondee", "surveil"],
	"artificier": ["grenade", "baril", "baril", "etincelle", "rivet", "c_rafale_rivets"],
	"moine": ["paume", "c_paume_ouverte", "poing", "poing", "tourbillon", "bond"],
	"trappeur": ["fleche", "fleche", "fleche", "piege", "piege", "marque"],
	"tidiane": ["esquisse", "c_ligne_claire", "recul", "wavedash", "journal", "pacte"],  # Contretemps (BPM) sortait sans payoff
	"receleur": ["larcin", "cle", "c_casse_tout", "bricolage", "camelote", "camelote"],
}
const VOIX := {"B": ["Analyse", Color("#4aa3d8")], "R": ["Émotion", Color("#e0483f")], "N": ["Ambition", Color("#9b6dd6")]}
# Difficulté 1 à 5. Le niveau 2 est l'équilibrage courant, le 4 celui d'origine.
# foe : dégâts ennemis par étage · hp : PV des héros · heal / revive : fraction des PV max après un combat
# extra : ennemis en plus (ou en moins) par étage · champ : champions en plus.
const DIFFICULTY := [
	{"name": "Oklm", "text": "Pour découvrir : ennemis mous, soins généreux.", "foe": [0.7, 0.9, 1.0], "hp": 1.15, "heal": [0.3, 0.25, 0.25], "revive": [0.6, 0.55, 0.5], "extra": [0, -1, -1], "champ": -1},
	{"name": "Aventurier", "text": "L'équilibre conseillé pour une première descente.", "foe": [0.8, 1.0, 1.1], "hp": 1.0, "heal": [0.2, 0.15, 0.15], "revive": [0.5, 0.45, 0.4], "extra": [0, 0, 0], "champ": 0},
	{"name": "Vétéran", "text": "Moins de soins, les ennemis frappent plein pot dès l'étage 2.", "foe": [0.9, 1.1, 1.15], "hp": 0.92, "heal": [0.1, 0.08, 0.08], "revive": [0.35, 0.3, 0.25], "extra": [0, 0, 0], "champ": 0},
	{"name": "Éclusier", "text": "L'équilibrage d'origine : aucun soin entre les salles.", "foe": [1.0, 1.1, 1.1], "hp": 0.82, "heal": [0.0, 0.0, 0.0], "revive": [0.25, 0.2, 0.15], "extra": [1, 0, 0], "champ": 0},
	{"name": "Anathème", "text": "Un ennemi de plus partout, un champion de plus, aucune pitié.", "foe": [1.15, 1.35, 1.4], "hp": 0.8, "heal": [0.0, 0.0, 0.0], "revive": [0.15, 0.12, 0.1], "extra": [1, 1, 1], "champ": 1},
]
# Déclencheurs : un bonus quand la condition tient (esprit Hearthstone / Runeterra, sans la complexité de Magic).
const TRIGGERS := {
	"grace": {"name": "Coup de grâce", "text": "si la carte tue"},
	"mur": {"name": "Dos au mur", "text": "si le héros est sous 30 % de ses PV"},
	"enchaine": {"name": "Enchaîné", "text": "si une autre carte a déjà été jouée ce tour"},
	"surplomb": {"name": "Surplomb", "text": "si le héros est plus haut que la cible"},
	"precision": {"name": "Précision", "text": "si la cible est à la portée maximale exacte"},
	"premier": {"name": "Premier jet", "text": "si c'est la première carte du tour"},
	"grixis": {"name": "Trinité", "text": "si Tidiane a joué ce tour l'Analyse, l'Émotion et l'Ambition (bleu, rouge, noir)"},
	"tenaille": {"name": "Tenaille", "text": "si la cible est prise entre ce héros et un allié, sur des cases opposées"},
	"proie": {"name": "Proie", "text": "si la cible est marquée ou entravée"},
	"poudre": {"name": "Poudre", "text": "si un baril a sauté ce tour"},
	"blesse": {"name": "Blessure", "text": "si un héros a perdu des PV ce tour"},
	"attaque": {"name": "Punition", "text": "si la cible a frappé un héros à son dernier tour"},
	"chasse": {"name": "Chasse", "text": "si la cible a été repoussée ce tour"},
	"immobile": {"name": "Ancré", "text": "si le héros n'a pas marché ce tour (il ne pourra plus bouger)"},
	"empoisonne": {"name": "Plaie", "text": "si la cible est empoisonnée"},
	"sol": {"name": "Terrain", "text": "si la cible se tient sur une case spéciale (rune, faille, ronces...)"},
	"bondi": {"name": "Bondi", "text": "si le héros s'est déjà téléporté ou a bondi ce tour"},
	"butin": {"name": "Butin", "text": "si un objet a été volé ce tour"},
	"dos": {"name": "Revers", "text": "si le coup part dans le dos de la cible"},
	"regain": {"name": "Regain", "text": "si un héros a regagné des PV ce tour"},
	"declic": {"name": "Déclic", "text": "si un piège s'est déclenché depuis la fin de ton dernier tour"},
}
# Mots-clés expliqués en infobulle sur les cartes.
const KEYWORDS := {
	"Épuise": "La carte quitte le combat une fois jouée.",
	"Pouvoir": "Effet permanent jusqu'à la fin du combat.",
	"Marqué": "Subit +50 % de dégâts, terrain compris (Choc, piège, baril, noyade).",
	"Entravé": "Ne peut plus se déplacer.",
	"enchaînement": "Le Moine compte ses coups du tour ; certaines cartes s'en nourrissent.",
	"repousse": "Pousse la cible ; contre un mur ou une unité : Choc. Dans l'eau : noyade. Un piège traversé l'arrête et se déclenche.",
	"attire": "Tire la cible vers le héros.",
	"De dos": "Frapper une unité de dos : dégâts ×1,5 (ou plus selon la carte). Après la carte, elle se retourne vers vous. Un héros collé à un allié, ou au premier round, ne se fait pas prendre de dos.",
	"baril": "Explose quand on le frappe : 7 dégâts autour, plus aux étages profonds et +50 % sur un ennemi Marqué. Un brasero compte comme un baril.",
	"brasero": "Compte comme un baril : un coup le fait exploser, 7 dégâts autour (plus aux étages profonds).",
	"piège": "L'ennemi qui y marche s'arrête, subit 8 et reste entravé. Plus aux étages profonds, +50 % s'il était Marqué.",
	"Niveau": "La forge fait monter une carte d'un niveau (3 au maximum). Chaque niveau change la carte.",
	"perd": "Coût en PV : ne peut pas tuer le héros (il reste à 1).",
	"Vole": "Prend l'objet que porte l'ennemi : sa carte arrive dans ta main.",
	"Fabrique": "Crée des objets Éphémères dans ta main.",
	"Démonte": "Retire un objet de ta main sans jouer son effet : elle perd 1 charge.",
	"Recharge": "+1 charge à un objet de ta main (3 au plus, une fois par combat et par carte ; jamais une Fiole).",
	"Lance": "Joue un objet de ta main sur la cible de la carte.",
	"Stock": "Objets de l'escouade encore en jeu (pioche, main, défausse), Éphémères exclues. 4 au plus.",
	"Charges": "Objet, gratuit. Joué, il perd 1 charge et quitte le combat ; à 0, il quitte le paquet.",
	"Conservé": "Reste en main à la fin du tour au lieu d'aller en défausse.",
	"Éphémère": "Épuisée si elle est encore en main à la fin du tour.",
	"Égide": "Le prochain coup reçu ne fait aucun dégât.",
	"Exécution": "Après le coup, une cible restée à 20 % de ses PV ou moins est achevée. Élites : 10 %. Gardiens : seulement dans leur dernière phase.",
	"Découvre": "Choisis une carte parmi trois ; elle arrive en main et coûte 0 ce tour.",
	"Embauche": "Regarde 3 cartes d'une classe absente de l'escouade et embauches-en une : elle arrive en main pour ce combat, dans le cadre de sa classe.",
	"Surcharge": "Coût optionnel : au moment de jouer la carte, si l'énergie suffit, tu peux payer la Surcharge ; elle touche alors chaque ennemi.",
	"Provocation": "Les ennemis visent ce héros en priorité.",
	"Exposé": "Le prochain coup qu'il reçoit d'un héros compte de dos.",
	"Choc": "3 dégâts (plus selon la carte) quand la cible repoussée heurte un mur, un relief ou une unité. Plus aux étages profonds, +50 % sur un ennemi Marqué.",
	"BPM": "Chaque carte jouée monte le BPM du héros de 1 (12 au plus). Les cartes Drop le dépensent d'un coup.",
	"Drop": "Ajoute le BPM du héros (multiplié) à la carte, puis le remet à zéro.",
	"Flashback": "Rejoue en Éphémère la dernière carte épuisée par ce héros ce combat (elle coûte 1 de moins).",
	"déborde": "Le soin en trop frappe l'ennemi le plus proche (×1,5 s'il est Marqué).",
	"Débordement": "Le soin en trop frappe l'ennemi le plus proche (×1,5 s'il est Marqué).",
	"X": "Coût X : dépense toute l'énergie restante (1 au moins) ; chaque point renforce la carte.",
	"Ouï-dire": "+N par carte piochée ce tour hors début de tour.",
	"Présage": "Marque une case : au début de ton prochain tour, l'ennemi qui s'y tient encaisse, armure ignorée.",
	"Conservé chargé": "Chaque tour passé en main, la carte gagne des dégâts (3 fois au plus).",
	"Exposée": "Le prochain coup qu'elle reçoit d'un héros compte de dos.",
	"Vol de vie": "Soigne le héros de la moitié des dégâts qu'il inflige avec cette carte.",
	"Glace": "Poussé sur la glace, on glisse jusqu'au prochain obstacle (et on s'y cogne).",
	"Vase": "Y entrer coûte 2 de déplacement. Poussé dedans, on s'enlise : entravé 1 tour.",
	"Tourelle": "Machine posée sur la case : elle tire seule au début de chaque round, pendant le nombre de rounds indiqué, puis disparaît.",
	"Bombarde": "Tourelle lourde, posée sur la case : elle tire seule au début de chaque round, pendant le nombre de rounds indiqué, puis disparaît.",
	"Baliste": "Tourelle posée sur la case : elle tire seule au début de chaque round, pendant le nombre de rounds indiqué, puis disparaît.",
	"Bélier": "Machine posée sur la case : elle frappe seule au début de chaque round, pendant le nombre de rounds indiqué, puis disparaît.",
	"Rage": "Chaque point de Rage ajoute +1 aux dégâts des coups du héros, jusqu'à la fin du combat.",
}
# Outils : effets des objets (o_*) et des objets portés par les ennemis.
# target : self | ally | foe | free (case libre) | tile. foe_ai : ce que fait un ennemi qui le porte.
const TOOLS := {
	"fiole": {"name": "Fiole de sève", "glyph": "♥", "rar": 1, "target": "ally", "range": [0, 3], "text": "Soigne 10 un allié.", "foe_ai": "la boit sous la moitié de ses PV"},
	"fumigene": {"name": "Fumigène", "glyph": "☁", "rar": 1, "target": "tile", "range": [0, 3], "text": "Fumée 2 tours sur la case et autour : on n'y vise plus à distance, et tout coup au contact y compte de dos.", "foe_ai": "s'en couvre quand il faiblit"},
	"picots": {"name": "Picots", "glyph": "✶", "rar": 1, "target": "free", "range": [1, 3], "text": "Sème des picots sur la case et autour : l'ennemi qui y marche s'arrête et subit 5."},
	"grappin": {"name": "Grappin", "glyph": "↗", "rar": 1, "target": "free", "range": [2, 5], "text": "Le héros se hisse sur une case libre, relief ignoré."},
	"gland": {"name": "Gland de chêne", "glyph": "♣", "rar": 2, "target": "free", "range": [1, 3], "text": "Plante un chêne : il barre la case, les héros voisins gagnent 3 armure par tour. Une explosion l'embrase (6 autour)."},
	"bombe": {"name": "Bombe à mèche", "glyph": "✹", "rar": 1, "target": "tile", "range": [2, 4], "text": "8 dégâts en croix. Fait sauter barils, chênes et bombes portées.", "foe_ai": "la lance sur un groupe de héros"},
	"tonnelet": {"name": "Tonnelet de poudre", "glyph": "▣", "rar": 1, "target": "free", "range": [1, 2], "text": "Pose un baril de poudre."},
	"filet": {"name": "Filet lesté", "glyph": "⊞", "rar": 1, "target": "foe", "range": [1, 4], "text": "Entrave 2 tours.", "foe_ai": "le jette sur un héros proche"},
	"sels": {"name": "Sels de réveil", "glyph": "✧", "rar": 1, "target": "ally", "range": [0, 3], "text": "Retire poison et entraves, +6 armure.", "foe_ai": "s'en sert s'il est blessé ou entravé"},
	"elixir": {"name": "Élixir de braise", "glyph": "☄", "rar": 2, "target": "self", "text": "+2 énergie."},
	"carnet": {"name": "Carnet de croquis", "glyph": "✎", "rar": 2, "target": "self", "text": "Pioche 3 cartes."},
	"de": {"name": "Dé pipé", "glyph": "⚄", "rar": 2, "target": "self", "text": "Défausse la main et repioche autant de cartes."},
	"brasero": {"name": "Brasero", "glyph": "♨", "rar": 1, "target": "free", "range": [1, 2], "text": "Pose un brasero."},
	"ballot": {"name": "Contrat d'embauche", "glyph": "⧈", "rar": 2, "target": "self", "text": "Embauche.", "foe_ai": "loin des héros, fait venir un complice"},
	"sablier": {"name": "Sablier fêlé", "glyph": "⧗", "rar": 3, "target": "self", "text": "Tous les ennemis sont entravés 1 tour."},
}
const FOE_TOOLS := ["fiole", "fiole", "bombe", "bombe", "fumigene", "filet", "sels", "ballot"]
# Cases spéciales, à la Dofus Arena : des runes au sol qui profitent à qui s'y tient, héros comme ennemis.
const TILES := {
	"force": {"name": "Rune de force", "glyph": "✦", "col": Color("#ff5a3a"), "text": "+3 dégâts aux attaques lancées depuis cette case."},
	"source": {"name": "Source", "glyph": "✚", "col": Color("#6ee07a"), "text": "Soigne 4 au début du tour de qui s'y tient."},
	"garde": {"name": "Rune de garde", "glyph": "🛡", "col": Color("#5aa8ff"), "text": "+5 armure au début du tour de qui s'y tient."},
	"elan": {"name": "Rune d'élan", "glyph": "↯", "col": Color("#ffd23a"), "text": "Un héros qui y commence son tour rapporte +1 énergie."},
	"portail": {"name": "Portail jumeau", "glyph": "◎", "col": Color("#c77dff"), "text": "Finir son déplacement dessus mène au portail jumeau, s'il est libre."},
	"ronces": {"name": "Ronces", "glyph": "✳", "col": Color("#c98a4a"), "text": "4 dégâts à qui s'y arrête ou y est poussé."},
	# terrains : se couvrir, se retrancher, éviter la braise
	"fourre": {"name": "Fourré", "glyph": "♣", "col": Color("#4fb86a"), "text": "Qui s'y tient reçoit 30 % de dégâts en moins."},
	"fort": {"name": "Fort en ruine", "glyph": "♜", "col": Color("#c9b27a"), "text": "Au début du tour de qui s'y tient : soigne 3 et +3 armure."},
	"lave": {"name": "Faille de braise", "glyph": "♨", "col": Color("#ff6a1a"), "text": "5 dégâts à qui s'y arrête, y est poussé ou y commence son tour."},
	"autel": {"name": "Autel des vœux", "glyph": "✧", "col": Color("#9fd8ff"), "text": "Un héros qui y commence son tour pioche 1 carte de plus."},
	"glyphe": {"name": "Glyphe instable", "glyph": "✺", "col": Color("#e05aff"), "text": "Explose en croix (6 dégâts) quand son compte à rebours tombe à 0, puis se recharge."},
}
# Matières du sol, une par biome au plus (battle._place_ground) : elles changent ce que fait une poussée.
const GROUND := {
	"glace": {"name": "Glace", "col": Color(0.62, 0.9, 1.0, 0.85), "text": "Poussé sur la glace, on glisse jusqu'au prochain obstacle (et on s'y cogne)."},
	"vase": {"name": "Vase", "col": Color(0.36, 0.25, 0.14, 0.97), "text": "Y entrer coûte 2 de déplacement. Poussé dedans, on s'enlise : entravé 1 tour."},
}
# Anciens (esprit Slay the Spire 2) : au seuil de chaque étage, un bienfait parmi trois.
const ANCIENTS := {
	"anatheme": {"name": "L'Anathème", "title": "Ancien de l'ambition", "glyph": "♆", "col": Color("#9b6dd6"),
		"line": "Tout pouvoir se paie. Je fais crédit.", "boons": ["relique_sang", "rare", "epure", "or", "relique"]},
	"sourcier": {"name": "Le Sourcier premier", "title": "Ancien des eaux", "glyph": "≋", "col": Color("#4ad0c0"),
		"line": "Bois, et souviens-toi de ce que tu étais.", "boons": ["soin", "pvmax", "memoire", "racines", "besace"]},
	"chineuse": {"name": "La Chineuse", "title": "Ancienne des marchés engloutis", "glyph": "⚖", "col": Color("#e3b45c"),
		"line": "Tout se revend. Même toi.", "boons": ["besace", "place", "arme", "or", "reflet"]},
	"dojo": {"name": "Le Vieux du Dojo", "title": "Ancien des frames", "glyph": "⚔", "col": Color("#e0483f"),
		"line": "Une frame de trop et tu es mort. Recommence.", "boons": ["forge2", "racines", "rare", "vocation", "reflet"]},
}
const BOONS := {
	"relique": {"name": "Relique ancienne", "glyph": "◆", "text": "Une relique au hasard."},
	"neutre": {"name": "Bric-à-brac", "glyph": "⧈", "text": "Une carte neutre pour chaque héros, au choix parmi trois : sans classe, n'importe qui la joue."},
	"relique_sang": {"name": "Relique de sang", "glyph": "♦", "text": "Une relique au choix parmi trois ; chaque héros perd 5 PV max."},
	"relique_boss": {"name": "Relique de gardien", "glyph": "♜", "text": "Une relique de gardien au choix parmi trois : un pouvoir, et son prix."},
	"rare": {"name": "Savoir interdit", "glyph": "✦", "text": "Une carte rare au choix parmi trois."},
	"epure": {"name": "Oubli", "glyph": "✂", "text": "Retirer jusqu'à deux cartes du paquet."},
	"or": {"name": "Tribut", "glyph": "●", "text": "+100 or."},
	"pvmax": {"name": "Sève ancienne", "glyph": "♥", "text": "Chaque héros gagne 6 PV max."},
	"soin": {"name": "Eau lustrale", "glyph": "✚", "text": "Tous les héros retrouvent leurs PV."},
	"forge2": {"name": "Main de maître", "glyph": "⚒", "text": "Deux cartes du paquet, au hasard, gagnent un niveau."},
	"racines": {"name": "Racines", "glyph": "♣", "text": "Les cartes de départ d'un héros au choix gagnent un niveau."},
	"besace": {"name": "Trois babioles", "glyph": "☁", "text": "Trois objets, chacune à un héros de ton choix ou revendue."},
	"place": {"name": "Poches cousues", "glyph": "▣", "text": "Un objet de ton paquet gagne un niveau, puis un objet rare."},
	"arme": {"name": "Arme d'antan", "glyph": "⚔", "text": "Un équipement rare."},
	"reflet": {"name": "Reflet", "glyph": "⧉", "text": "Copie une carte du paquet (la copie n'est pas une carte de départ)."},
	"vocation": {"name": "Vocation", "glyph": "⚔", "text": "Un héros au choix prend ou change sa vocation."},
	"memoire": {"name": "Mémoire du fleuve", "glyph": "≋", "text": "Chaque héros gagne 3 points de job."},
}
# Idéogramme de chaque mot-clé (assets/ui/kw_*.png) ; les déclencheurs ont le leur.
const KW_ICON := {"Épuise": "epuise", "Pouvoir": "pouvoir", "Marqué": "marque", "Entravé": "entrave", "enchaînement": "enchainement",
	"repousse": "repousse", "attire": "attire", "tire": "attire", "De dos": "dos", "de dos": "dos", "baril": "baril", "brasero": "baril", "piège": "piege",
	"perd": "perd", "Vole": "vole", "Démonte": "bricole", "Stock": "besace", "Charges": "fabrique", "Fabrique": "fabrique", "poison": "poison",
	"Pioche": "pioche", "pioche": "pioche", "énergie": "energie",
	"Coup de grâce": "grace", "Dos au mur": "mur", "Enchaîné": "enchaine", "Surplomb": "surplomb", "Précision": "precision",
	"Premier jet": "premier", "Trinité": "grixis",
	"Recharge": "recharge", "Lance": "lance", "Conservé": "conserve", "Éphémère": "ephemere", "Égide": "egide", "Exécution": "execution", "Découvre": "decouvre", "Embauche": "braquage", "Surcharge": "surcharge", "Provocation": "provocation", "Exposé": "expose", "Exposée": "expose", "Choc": "choc", "BPM": "bpm", "Drop": "drop", "Flashback": "flashback", "Débordement": "debordement", "déborde": "debordement", "X": "x", "Ouï-dire": "oui_dire", "Présage": "presage", "Conservé chargé": "conserve_charge", "Vol de vie": "vol_de_vie", "Glace": "glace", "Vase": "vase", "Rage": "rage", "Tourelle": "tourelle", "Bombarde": "tourelle", "Baliste": "tourelle", "Bélier": "tourelle", "Niveau": "niveau"}
# Modificateurs de combat : affichés sur les salles marquées (plus de risque, plus de butin).
const MODIFIERS := {
	"brume": {"name": "Brume", "glyph": "≈", "text": "Portée des attaques à distance -1, pour tout le monde."},
	"enrages": {"name": "Enragés", "glyph": "✶", "text": "Les ennemis infligent +2 dégâts."},
	"blindes": {"name": "Carapaces", "glyph": "🛡", "text": "Les ennemis gagnent 4 armure à chaque tour."},
	"renforts": {"name": "Renforts", "glyph": "☖", "text": "Deux Moussus surgissent au tour 3."},
	"poudriere": {"name": "Poudrière", "glyph": "✹", "text": "Quatre barils de poudre en plus sur le terrain."},
	"glissant": {"name": "Sol glissant", "glyph": "↠", "text": "Toutes les poussées portent une case plus loin."},
	"hate": {"name": "Hâte", "glyph": "»", "text": "Les ennemis se déplacent d'une case de plus."},
}
# Pactes : des malus choisis en début de run ; chacun augmente l'or (+25 %) et la chance de cartes rares.
const PACTS := {
	"sang": {"name": "Pacte de sang", "text": "PV max des héros -15 %."},
	"horde": {"name": "Horde", "text": "Un ennemi de plus dans chaque combat."},
	"acier": {"name": "Acier", "text": "Les ennemis gagnent 4 armure à chaque tour."},
	"rage": {"name": "Rage", "text": "Les ennemis infligent +2 dégâts."},
	"main": {"name": "Main courte", "text": "On pioche une carte de moins à chaque tour."},
	"brume": {"name": "Brume éternelle", "text": "Portée des attaques à distance -1 dans tous les combats."},
	"champion": {"name": "Champions", "text": "Un champion de plus dans chaque combat."},
}
# Porteurs de carte : un ennemi par combat, parfois, garde une carte. On la gagne en remplissant la condition,
# ou en la volant. Le fuyard, lui, s'échappe au bout de 3 tours.
const CARD_CONDS := {
	"fuite": {"name": "Fuyard", "text": "Il fuit et s'échappe au bout de 3 tours avec sa carte. Abattez-le avant."},
	"vite": {"name": "Défi : éclair", "text": "Abattez-le avant la fin du round 2 pour gagner sa carte."},
	"eau": {"name": "Défi : noyade", "text": "Faites-le tomber à l'eau pour l'achever et gagner sa carte."},
	"piege": {"name": "Défi : collet", "text": "Achevez-le avec un piège pour gagner sa carte."},
	"marque": {"name": "Défi : curée", "text": "Achevez-le pendant qu'il est Marqué pour gagner sa carte."},
}
# objets : l'outil porté par un ennemi -> sa carte ; barème de revente
const OBJ_OF := {"gland": "o_arbre", "tonnelet": "o_baril"}
const SELL_OBJ := {1: 15, 2: 25, 3: 40}
const SELL_CARD := {1: 25, 2: 40, 3: 60, 4: 100}


static func obj_of(tool: String) -> String:
	return OBJ_OF.get(tool, "o_" + tool)


static func sell_value(ci: Dictionary) -> int:
	var d := def(ci.id)
	if d.has("tool"):
		return 60 if level(ci) >= 3 else int(SELL_OBJ[d.rar] * (1.5 if level(ci) == 2 else 1.0))
	return SELL_CARD[d.get("rar", 1)]


const RARITY_COL := {1: Color("#a9aeb8"), 2: Color("#5b9dff"), 3: Color("#b36bff"), 4: Color("#ff8a3d")}  # gris, bleu, violet, orange : les gemmes
const RARITY_NAME := {1: "Commune", 2: "Peu commune", 3: "Rare", 4: "Légendaire"}


static func multi_starter(k: String, v: String, r: RandomNumberGenerator) -> Array:
	## Départ multiclasse : le paquet de départ allégé de 2 cartes (doublons d'abord, jamais la graine c_*),
	## une commune et une peu commune de la guilde, et la graine de la classe apprise. 7 cartes.
	var own: Array = STARTER[k].duplicate()
	for n in 2:
		var drop := -1
		for q in range(own.size() - 1, -1, -1):
			if own.count(own[q]) > 1:
				drop = q
				break
		if drop < 0:
			for q in range(own.size() - 1, -1, -1):
				if not own[q].begins_with("c_"):
					drop = q
					break
		own.remove_at(drop)
	var out: Array = own.map(func(id): return {"id": id, "lvl": 1, "st": true})
	var g := Guildes.index(k, v)
	for rr in [1, 2]:
		var pool: Array = Guildes.cards_of(g, [rr])
		if pool.size() > 0:
			out.append({"id": pool[r.randi_range(0, pool.size() - 1)], "lvl": 1, "h": k})
	var seed: Array = STARTER[v].filter(func(id): return id.begins_with("c_"))
	if seed.is_empty():
		seed = CARDS.keys().filter(func(id): return CARDS[id].owner == v and CARDS[id].rar == 1 and not STARTER[v].has(id))
	out.append({"id": seed[r.randi_range(0, seed.size() - 1)], "lvl": 1, "h": k})
	return out


static func starter(party: Array) -> Array:
	var out: Array = []
	for k in party:
		for id in STARTER[k]:
			out.append({"id": id, "lvl": 1, "st": true})  # carte de départ : pas de fusion
	return out

# Reliques. tier : commune | peu_commune | rare | boss (gardien de fin d'étage) | marchand | evenement (main._relic_draw).
# need : ce dont la run a besoin pour qu'on la propose (main._relic_useful) ; sans need, toujours utile.
const RELICS := {
	"double_fond": {"name": "Lettre de recommandation", "glyph": "⧈", "tier": "peu_commune", "text": "Au premier tour de chaque combat, le premier héros à jouer fait une Embauche."},
	"ambre": {"name": "Ambre du Gué", "glyph": "◆", "tier": "commune", "text": "+1 énergie au premier tour de chaque héros, à chaque combat."},
	"feuille": {"name": "Feuille Rouge", "glyph": "❦", "tier": "commune", "text": "Les attaques de dos infligent +3."},
	"lotus_pale": {"name": "Lotus Pâle", "glyph": "✿", "tier": "commune", "text": "Soigne 4 chaque héros après un combat."},
	"crochet": {"name": "Crochet d'Écluse", "glyph": "⚓", "tier": "commune", "text": "Les ennemis repoussés vont 1 case plus loin."},
	"cendre": {"name": "Cendre Vive", "glyph": "✹", "tier": "peu_commune", "text": "Un ennemi tué explose : 4 dégâts autour de lui."},
	"tuile": {"name": "Tuile Brisée", "glyph": "▲", "tier": "peu_commune", "text": "Le premier Choc de chaque combat sonne l'ennemi : il perd son prochain tour."},
	"cloche": {"name": "Cloche Noyée", "glyph": "♒", "tier": "commune", "text": "Un ennemi qui se noie subit 6 de plus."},
	"grimoire": {"name": "Grimoire Humide", "glyph": "▤", "tier": "commune", "text": "Chaque héros pioche 1 carte de plus à ses deux premiers tours de chaque combat."},
	"sablier": {"name": "Clepsydre verte", "glyph": "⧗", "tier": "peu_commune", "text": "La première carte au coût imprimé de 1 du tour de chaque héros coûte 0."},
	"ecaille": {"name": "Écaille de Carpe", "glyph": "◈", "tier": "commune", "text": "Chaque héros commence le combat avec 6 d'armure."},
	"heron": {"name": "Aigrette du héron", "glyph": "⇶", "tier": "peu_commune", "text": "+1 déplacement pour tous les héros."},
	"oeil": {"name": "Longue-vue embuée", "glyph": "◉", "tier": "peu_commune", "text": "Choix de 4 cartes au lieu de 3."},
	"sacoche": {"name": "Sacoche de cuir", "glyph": "▣", "tier": "peu_commune", "text": "Tout objet obtenu arrive au niveau 2 (2 charges)."},
	"alambic": {"name": "Alambic de poche", "glyph": "☄", "tier": "commune", "text": "Au début de chaque combat, Fabrique 1 dans la main du premier héros à jouer."},
	"livret": {"name": "Livret d'apprenti", "glyph": "◇", "tier": "peu_commune", "need": "sans_vocation", "text": "Un héros au choix prend sa vocation tout de suite."},
	"blason": {"name": "Blason écartelé", "glyph": "⚜", "tier": "rare", "text": "Un héros gagne une deuxième vocation, et donc une deuxième guilde."},
	"touriste": {"name": "Carnet du colporteur", "glyph": "⚐", "tier": "commune", "text": "Chaque butin propose en plus une carte d'une classe absente de l'escouade."},
	"sceau": {"name": "Sceau de guilde", "glyph": "⬡", "tier": "peu_commune", "text": "Les rares de guilde s'ouvrent dès la maîtrise II."},
	"medaille": {"name": "Médaille du duo", "glyph": "⚭", "tier": "rare", "text": "Les cartes de guilde coûtent 1 de moins quand les deux classes de la guilde sont dans l'escouade."},
	"noblesse": {"name": "Lettre de noblesse", "glyph": "✉", "tier": "peu_commune", "text": "Le butin propose trois cartes de vocation ou de guilde au lieu d'une."},
	"plume": {"name": "Plume d'emprunt", "glyph": "✒", "tier": "peu_commune", "text": "La première carte hors classe jouée à chaque tour pioche 1."},
	"masque": {"name": "Masque de porcelaine", "glyph": "◐", "tier": "peu_commune", "text": "La première carte hors classe de chaque tour coûte 1 de moins."},
	"tambour": {"name": "Tambour 174", "glyph": "♫", "tier": "rare", "text": "Toutes les 4 cartes jouées dans un combat, +1 énergie."},
	"galet": {"name": "Galet poli", "glyph": "●", "tier": "commune", "text": "La 3e carte jouée par un héros dans son tour lui donne 4 armure."},
	"pierre": {"name": "Pierre à aiguiser", "glyph": "◇", "tier": "commune", "need": "multi", "text": "Les attaques à plusieurs coups infligent +1 par coup."},
	"braise_eternelle": {"name": "Eau croupie", "glyph": "☠", "tier": "peu_commune", "need": "poison", "text": "Le poison des ennemis ne décroît plus."},
	"hamecon": {"name": "Hameçon rouillé", "glyph": "⌐", "tier": "commune", "need": "attire", "text": "Attirer tire une case plus loin et Marque la cible 1 tour."},
	"collier": {"name": "Collier de la meute", "glyph": "∞", "tier": "peu_commune", "need": "compagnon", "text": "Le compagnon a 50 % de PV en plus et frappe +3."},
	"sifflet": {"name": "Sifflet d'os", "glyph": "♪", "tier": "rare", "need": "sans_compagnon", "text": "Sans compagnon, une bête des Hauts-Fonds répond à l'appel à chaque combat."},
	"bourse": {"name": "Obole du Passeur", "glyph": "◎", "tier": "marchand", "text": "L'or des combats +25 %, et la boutique propose toujours une pièce d'équipement de plus."},
	"journal_route": {"name": "Journal de route", "glyph": "✎", "tier": "evenement", "text": "Chaque salle « ? » soigne 10 % des PV max de chaque héros ; la première de chaque étage permet de relancer le trait d'un héros."},
	# communes
	"baril_contrebande": {"name": "Baril de contrebande", "glyph": "✹", "tier": "commune", "text": "Au début de chaque combat, un baril de poudre apparaît près d'un ennemi."},
	"coin_carrier": {"name": "Coin de carrier", "glyph": "⚠", "tier": "commune", "text": "Un pilier fendu s'effondre sur 4 cases au lieu de 2."},
	"etoupe": {"name": "Étoupe goudronnée", "glyph": "♨", "tier": "commune", "text": "Barils et braseros infligent 4 dégâts de plus en explosant."},
	"clou_halage": {"name": "Clou de halage", "glyph": "⚒", "tier": "commune", "text": "Le Choc inflige +3 dégâts."},
	"collet_crin": {"name": "Collet de crin", "glyph": "◎", "tier": "commune", "need": "piege", "text": "Un ennemi pris dans un piège est aussi Marqué 2 tours."},
	"piquet_frene": {"name": "Piquet de frêne", "glyph": "✳", "tier": "commune", "need": "piege", "text": "Vos pièges infligent 4 dégâts de plus."},
	"amadou": {"name": "Amadou", "glyph": "♨", "tier": "commune", "text": "Un arbre qui s'embrase inflige 3 de plus et laisse une Braise sur sa case."},
	"battant": {"name": "Battant de cloche", "glyph": "♫", "tier": "commune", "text": "Sonner une cloche d'alarme ne coûte plus le déplacement et Marque les ennemis qu'elle étourdit."},
	"gobelet": {"name": "Gobelet d'étain", "glyph": "♥", "tier": "commune", "text": "Les vasques soignent vos héros de 50 % de plus."},
	"passe_partout": {"name": "Passe-partout", "glyph": "◆", "tier": "commune", "text": "Ouvrir un coffre au sol rapporte aussi 10 or."},
	"denier_fossoyeur": {"name": "Denier du fossoyeur", "glyph": "●", "tier": "commune", "text": "Gagnez 4 or quand un ennemi meurt d'un Choc, d'une noyade ou d'une explosion."},
	"sebile_cuivre": {"name": "Sébile de cuivre", "glyph": "◎", "tier": "commune", "text": "Passer le butin de cartes d'un combat rapporte 20 or."},
	"semelles_jonc": {"name": "Semelles de jonc", "glyph": "≋", "tier": "commune", "need": "vase", "text": "Vos héros traversent la vase sans surcoût et ne s'y enlisent jamais."},
	"ecorce_saule": {"name": "Écorce de saule", "glyph": "♣", "tier": "commune", "text": "Chaque ennemi qu'un héros repousse lui donne 2 armure."},
	"givre_etrave": {"name": "Givre d'étrave", "glyph": "✧", "tier": "commune", "need": "glace", "text": "Un ennemi qui glisse sur la glace est Exposé."},
	"chaine_amarre": {"name": "Chaîne d'amarre", "glyph": "⛓", "tier": "commune", "text": "Les ennemis Entravés subissent +3 dégâts à chaque coup de vos héros."},
	"craie_arpenteur": {"name": "Craie d'arpenteur", "glyph": "✎", "tier": "commune", "text": "Au début de chaque combat, l'ennemi aux PV les plus hauts est Marqué 2 tours."},
	"plaque_vanne": {"name": "Plaque de vanne", "glyph": "▣", "tier": "commune", "text": "Chaque héros commence chaque combat avec Égide."},
	"onguent": {"name": "Onguent de résine", "glyph": "✚", "tier": "commune", "need": "soin", "text": "Quand un héros soigne un allié, cet allié gagne aussi 3 armure."},
	"lentille": {"name": "Lentille de souffleur", "glyph": "◉", "tier": "commune", "need": "distance", "text": "Les attaques qui touchent à 3 cases ou plus infligent +2."},
	"diapason": {"name": "Diapason", "glyph": "♪", "tier": "commune", "need": "tidiane", "text": "Au début de chaque combat, BPM +2."},
	"doublure": {"name": "Doublure de manteau", "glyph": "▤", "tier": "commune", "need": "vol", "text": "Un objet volé arrive avec 1 charge de plus (3 au plus)."},
	"vessie": {"name": "Vessie de crapaud", "glyph": "☠", "tier": "commune", "need": "poison", "text": "Le poison que vous appliquez est augmenté de 1."},
	# peu communes
	"poudre_fine": {"name": "Poudre fine", "glyph": "✺", "tier": "peu_commune", "text": "Barils et braseros explosent sur 2 cases autour au lieu d'1."},
	"pique": {"name": "Tête sur la pique", "glyph": "⚔", "tier": "peu_commune", "need": "exec", "text": "Quand un ennemi est exécuté, les ennemis à 3 cases sont Marqués 2 tours."},
	"hachoir": {"name": "Hachoir d'équarrisseur", "glyph": "✂", "tier": "peu_commune", "need": "exec", "text": "Exécution achève sous 30 % des PV au lieu de 20 % (élites 15 %)."},
	"soufflet": {"name": "Soufflet de forge", "glyph": "☁", "tier": "peu_commune", "need": "objet", "text": "Une fois par tour, une explosion Recharge une autre objet de la main du héros qui joue."},
	"goupille": {"name": "Goupille de rechange", "glyph": "⌐", "tier": "peu_commune", "need": "objet", "text": "Quand un objet joué perd sa dernière charge, son héros gagne 1 énergie."},
	"encrier": {"name": "Encrier de relieur", "glyph": "✒", "tier": "peu_commune", "need": "enchant", "text": "Jusqu'à 2 cartes enchantées de chaque héros sont dans sa main de départ."},
	"grelot": {"name": "Grelot de dressage", "glyph": "♪", "tier": "peu_commune", "need": "compagnon", "text": "Un ennemi touché par votre compagnon est Exposé."},
	"etendard": {"name": "Étendard délavé", "glyph": "⚐", "tier": "peu_commune", "need": "provocation", "text": "Un héros qui Provoque gagne 3 armure chaque fois qu'un ennemi le frappe."},
	"remous": {"name": "Remous", "glyph": "≋", "tier": "peu_commune", "text": "Quand un ennemi se noie, les ennemis voisins sont repoussés d'une case loin de lui."},
	"tenaille": {"name": "Tenaille", "glyph": "⚒", "tier": "peu_commune", "text": "Un ennemi pris entre deux héros, de part et d'autre, est Marqué 1 tour."},
	"corde_noeuds": {"name": "Corde à nœuds", "glyph": "∞", "tier": "peu_commune", "text": "Le 4e coup qu'un héros porte dans son tour lui fait piocher 1 carte."},
	"cle_jumeaux": {"name": "Clé des jumeaux", "glyph": "◈", "tier": "peu_commune", "text": "Un ennemi qui passe par un portail est Entravé 1 tour."},
	"clou_quai": {"name": "Clou de quai", "glyph": "⚓", "tier": "peu_commune", "text": "Un ennemi repoussé contre un mur ou un obstacle est Entravé 1 tour."},
	# rares
	"souffle": {"name": "Souffle du canonnier", "glyph": "☄", "tier": "rare", "text": "Les explosions repoussent d'une case les unités qui les bordent (pas en diagonale)."},
	"quille": {"name": "Quille de plomb", "glyph": "●", "tier": "rare", "text": "Quand vos héros repoussent un ennemi contre un autre ennemi, celui-ci est repoussé d'une case."},
	"marelle": {"name": "Craie de marelle", "glyph": "✦", "tier": "rare", "text": "Un héros qui commence son tour sur une rune de force, de source ou de garde en fait aussi profiter l'allié le plus proche."},
	"echo_caverne": {"name": "Écho de caverne", "glyph": "◎", "tier": "rare", "text": "La première attaque jouée dans chaque combat est jouée deux fois."},
	"braise_veille": {"name": "Braise de veille", "glyph": "♨", "tier": "rare", "text": "Au sanctuaire, faites deux choix différents au lieu d'un."},
	"relais_poste": {"name": "Relais de poste", "glyph": "⇶", "tier": "rare", "text": "1 énergie non dépensée par un héros passe au héros suivant."},
	"couteau_palette": {"name": "Couteau à palette", "glyph": "✦", "tier": "rare", "text": "Au début de chaque combat, une rune de force, de garde ou d'élan, au hasard, apparaît sous chaque héros."},
	"ecusson": {"name": "Écusson de la Compagnie", "glyph": "⚜", "tier": "rare", "text": "Une fois par combat, le premier héros qui tomberait à 0 PV reste à 1 PV et gagne Égide."},
	"corne_aube": {"name": "Corne de l'aube", "glyph": "♫", "tier": "rare", "text": "Au premier round de chaque combat, tous vos héros jouent avant les ennemis."},
	# gardien : un pouvoir, et son prix
	"couronne_plomb": {"name": "Couronne de plomb", "glyph": "♜", "tier": "boss", "text": "+1 énergie à chaque tour de chaque héros. Prix : au sanctuaire, on ne peut plus se reposer."},
	"chaine_forcat": {"name": "Chaîne du forçat", "glyph": "⛓", "tier": "boss", "text": "Chaque héros pioche 1 carte de plus à chaque tour. Prix : vos héros ont -1 déplacement."},
	"cle_ecluse": {"name": "Clé de la Grande Écluse", "glyph": "♆", "tier": "boss", "text": "+1 énergie à chaque tour de chaque héros. Prix : les ennemis ne se noient plus."},
	"machoire_ogre": {"name": "Mâchoire de l'ogre", "glyph": "☠", "tier": "boss", "text": "Chaque ennemi tué donne 2 Rage à son tueur. Prix : vos héros ne gagnent plus d'armure ni d'Égide."},
	"ecrin": {"name": "Écrin sans fond", "glyph": "▣", "tier": "boss", "need": "objet", "text": "Les objets joués vont à la défausse au lieu de quitter le combat. Prix : au premier tour de chaque combat, chaque héros a 1 énergie de moins."},
	"coeur_fournaise": {"name": "Cœur de fournaise", "glyph": "♥", "tier": "boss", "text": "Les explosions infligent le double. Prix : à vos héros aussi, et chaque combat commence avec un baril au contact de l'un d'eux."},
	# marchand
	"jeton_comptoir": {"name": "Jeton du Comptoir", "glyph": "⚖", "tier": "marchand", "text": "Tout est 20 % moins cher chez le marchand, services compris."},
	"ciseaux_epure": {"name": "Ciseaux d'épure", "glyph": "✂", "tier": "marchand", "text": "Épurer chez le marchand coûte toujours 50 or."},
	"nasse": {"name": "Nasse d'osier", "glyph": "≋", "tier": "marchand", "text": "Chaque ennemi tué par la noyade rapporte 15 or."},
	# événement (pas encore d'événement écrit pour eux : ils sortent des reliques des salles « ? »)
	"lampe_brume": {"name": "Lampe de brume", "glyph": "☽", "tier": "evenement", "text": "Les salles « ? » ne tendent plus d'embuscade."},
	"registre_prevot": {"name": "Registre du prévôt", "glyph": "✉", "tier": "evenement", "text": "Un porteur de carte apparaît dès qu'un ennemi peut l'être, et réussir son défi rapporte 20 or."},
	"colonne_volee": {"name": "Colonne volée", "glyph": "⚠", "tier": "evenement", "text": "Au début de chaque combat, un pilier fendu se dresse près du centre du terrain."},
}
const RELIC_TIERS := {"commune": "Commune", "peu_commune": "Peu commune", "rare": "Rare", "boss": "Gardien", "marchand": "Marchand", "evenement": "Événement"}


static func ground_of(biome: int) -> String:
	## Matière du sol d'un biome (battle._place_ground) : glace, vase ou rien.
	return "glace" if biome in [5, 6, 10] else ("vase" if biome in [0, 1, 4, 9] else "")


# Maîtrise : points de job (1 par combat, 2 par élite) ; seuils des paliers II, III, IV.
const MASTERY := [0, 0, 3, 7, 11]
const MASTERY_NAME := {1: "I", 2: "II", 3: "III", 4: "IV"}

const TRAITS := {
	"gaucher": {"name": "Gaucher", "text": "+2 aux attaques de dos."},
	"vertige": {"name": "Vertige", "text": "Saut -1, PV max +6."},
	"leger": {"name": "Pieds légers", "text": "Déplacement +1."},
	"rancune": {"name": "Rancunier", "text": "+3 dégâts sous la moitié des PV."},
	"colosse": {"name": "Colosse", "text": "PV max +8, déplacement -1."},
	"nageur": {"name": "Nageur", "text": "Insensible à la noyade."},
	"myope": {"name": "Myope", "text": "Portée à distance -1, dégâts +2."},
	"beni": {"name": "Béni", "text": "Soins reçus +50 %."},
	"matinal": {"name": "Matinal", "text": "+1 énergie à son premier tour de chaque combat."},
	"insomniaque": {"name": "Insomniaque", "text": "Pioche 1 carte de plus, PV max -4."},
	"costaud": {"name": "Costaud", "text": "Commence chaque combat avec 6 d'armure."},
	"bagarreur": {"name": "Bagarreur", "text": "+2 aux attaques au contact."},
	"lynx": {"name": "Œil de lynx", "text": "Portée des attaques à distance +1."},
	"fragile": {"name": "Fragile", "text": "+3 à toutes ses attaques, PV max -6."},
	"grimpeur": {"name": "Grimpeur", "text": "Saut +2."},
	"lourdaud": {"name": "Lourdaud", "text": "Déplacement -1, +4 armure au début de son tour."},
	"chanceux": {"name": "Chanceux", "text": "20 % d'esquiver une attaque."},
	"sang_chaud": {"name": "Sang chaud", "text": "+1 énergie à son tour sous la moitié de ses PV."},
	"radin": {"name": "Radin", "text": "L'or gagné en combat +15 %."},
	"vif": {"name": "Vif", "text": "Vitesse +3 : joue plus tôt dans le round."},
}

# Acte 1 : lire (une leçon par ennemi). Acte 2 : prioriser. Acte 3 : le terrain se retourne.
# Salle 1 de l'acte 1 tirée dans [0..2], salle 2 dans [0..4], ensuite tout le pool (main.gd _fight).
const ENCOUNTERS := {
	1: [["husk", "husk", "frondeur"], ["pavoiseur", "husk", "guetteur"], ["carapace", "husk", "anguille"], ["husk", "guetteur", "wisp"],
		["fanal", "pavoiseur", "guetteur"], ["rodeur", "husk", "chaman"], ["obelisque", "husk", "frondeur"], ["anguille", "crabe", "husk"],
		["frondeur", "frondeur", "pavoiseur", "husk"], ["fanal", "carapace", "guetteur", "wisp"]],
	2: [["tenant", "mage", "guetteur", "husk"], ["fanal", "rodeur", "bretteur", "guetteur"], ["bitte", "sentinelle", "crabe", "chaman"],
		["pisteuse", "cavalier", "lancier", "lancier"], ["penitente", "vouivre", "bretteur", "husk"], ["obelisque", "tenant", "baliste", "lancier"],
		["fanal", "baliste", "pisteuse", "carapace"], ["harpie", "harpie", "harpie", "penitente"], ["bitte", "capitaine", "lancier", "mage"],
		["crapaud", "tenant", "mage", "wisp"], ["cavalier", "lancier", "mage", "danseuse"]],
	3: [["vanne", "noye_ancien", "noye_ancien", "guetteur"], ["fanal", "lancier", "lancier", "bretteur"], ["pilori", "sentinelle", "mage", "rodeur"],
		["eclusier_fou", "eclusier_fou", "lancier", "wisp"], ["porte_etendard", "carapace", "crabe", "mage"], ["fouisseur", "fouisseur", "baliste", "guetteur"],
		["vanne", "crapaud", "noye_ancien", "vouivre"], ["obelisque", "fanal", "cavalier", "mage"], ["pilori", "porte_etendard", "bretteur", "wisp"],
		["fouisseur", "bretteur", "vouivre", "chaman"]],
}
# ennemis en plus selon la difficulté, tirés dans ce pool (règles de composition respectées)
const EXTRAS := {1: ["husk", "guetteur", "pavoiseur"], 2: ["lancier", "bretteur", "guetteur", "husk"], 3: ["lancier", "noye_ancien", "bretteur", "guetteur"]}
# élites par acte : la première est tirée une fois sur deux aux actes 1-2 (Grelin, les Amarreurs), 1/3 chacune à l'acte 3
const ELITES := {
	1: [["grelin", "treuil", "treuil", "husk", "guetteur"], ["fanal", "sentinelle", "pavoiseur", "frondeur", "chaman"], ["capitaine", "pavoiseur", "pavoiseur", "frondeur", "anguille"],
		["chevrier", "chevre", "chevre", "guetteur"]],
	2: [["hale", "brasse", "pisteuse", "husk"], ["capitaine", "tenant", "mage", "lancier", "danseuse"], ["bitte", "sentinelle", "bretteur", "penitente", "guetteur"],
		["dame", "vanne_dame", "vanne_dame", "lancier", "mage"]],
	3: [["capitaine", "porte_etendard", "noye_ancien", "lancier", "mage"], ["vanne", "noye_ancien", "crapaud", "danseuse", "guetteur"], ["fanal", "pilori", "baliste", "bretteur", "danseuse"],
		["brule_haie", "lancier", "chaman", "frondeur"]],
}
# arène imposée par certaines élites : des ponts pour le Chevrier
const ELITE_ARCH := {"chevrier": "ilots", "dame": "ecluse", "brule_haie": "cour"}
const BOSS := ["gardien", "chaman", "husk", "husk", "fanal"]
# couches défensives absorbantes et règles de terrain : une seule de chaque par combat
const LAYERS := ["bitte", "tenant", "porte_etendard"]
const TERRAIN_RULES := ["vanne", "fouisseur", "eclusier_fou"]


static func elite_pick(fl: int, r: RandomNumberGenerator, diff: int) -> Array:
	## Tirage pondéré de l'élite d'un acte ; difficulté 4+ : un renfort.
	var L: Array = ELITES.get(fl, ELITES[3])
	var x := r.randf()
	# actes 1-2 : le boss de terrain (Grelin ou le Chevrier, les Amarreurs ou la Dame) une fois sur deux, en alternance
	var i: int = (([0, 3][r.randi_range(0, 1)]) if x < 0.5 else (1 if x < 0.75 else 2)) if fl < 3 else mini(3, int(x * 4.0))
	var ids: Array = L[i].duplicate()
	if diff >= 3 and fl == 2 and i == 0:
		ids.append("lancier")
	if diff >= 3 and fl == 3 and i == 1:
		ids.append("vanne")
	return ids

const ROOMS := {
	"combat": {"name": "Combat", "glyph": "⚔", "text": "Une escouade des ruines. Récompense : une carte."},
	"elite": {"name": "Élite", "glyph": "☠", "text": "Des gardiens plus coriaces. Récompense : carte et relique."},
	"sanctuaire": {"name": "Sanctuaire", "glyph": "✚", "text": "Soigner le groupe ou affûter une carte."},
	"reliquaire": {"name": "Reliquaire", "glyph": "◆", "text": "Une relique parmi trois."},
	"marchand": {"name": "Marchand", "glyph": "⚖", "text": "Équipement, cartes et soins contre de l'or."},
	"mystere": {"name": "Inconnu", "glyph": "?", "text": "Une rencontre, un marché douteux, une bête, un piège. On ne sait qu'en entrant."},
	"boss": {"name": "Le Gardien", "glyph": "♜", "text": "Le colosse qui tient l'Écluse."},
}

# Passifs d'équipement, d'après les capacités de réaction et de soutien de FFTA.
const PASSIVES := {
	"contre": {"name": "Contre", "text": "Riposte 4 quand frappé au contact."},
	"casseur": {"name": "Casse-os", "text": "Riposte 8 au contact sous la moitié des PV."},
	"reflexe": {"name": "Réflexe", "text": "25 % d'esquiver un coup au contact."},
	"parade": {"name": "Parade des flèches", "text": "50 % d'esquiver un tir."},
	"retour": {"name": "Retour de feu", "text": "Renvoie la moitié des dégâts de tir."},
	"bouclier": {"name": "Porte-bouclier", "text": "+3 armure au début de chaque tour."},
	"regen": {"name": "Auto-régén", "text": "Soigne 2 au début de chaque tour."},
	"arme_plus": {"name": "Arme+", "text": "+2 aux attaques au contact."},
	"concentration": {"name": "Concentration", "text": "+1 portée aux attaques à distance."},
	"deux_mains": {"name": "Deux mains", "text": "Première attaque du tour : +50 %."},
	"elan": {"name": "Dernier élan", "text": "Sous 25 % PV : +2 énergie, une fois par combat."},
	"absorbe": {"name": "Absorbe", "text": "Tuer un ennemi rend 1 énergie."},
	"eau": {"name": "Marche sur l'eau", "text": "Peut marcher sur l'eau."},
	"deplacement": {"name": "Déplacement +1", "text": "+1 case de déplacement."},
	"saut": {"name": "Saut +2", "text": "Franchit 2 niveaux de plus."},
	"vigilance": {"name": "Vigilance", "text": "Jamais pris de dos."},
	"economie": {"name": "Demi-coût", "text": "La 1re carte à 2+ du tour coûte 1 de moins."},
	"chasseur": {"name": "Chasseur de trésors", "text": "Les coffres donnent aussi 25 or."},
	"ancre": {"name": "Ancre", "text": "Ne peut être ni repoussé ni attiré : il encaisse le Choc comme un mur."},
	"flotte": {"name": "Insubmersible", "text": "Insensible à la noyade."},
	"venin": {"name": "Venin", "text": "Chaque coup au contact qui touche inflige aussi 1 poison."},
	"charogne": {"name": "Charogne", "text": "Tuer un ennemi donne 4 armure."},
	"meche": {"name": "Mèche courte", "text": "Pendant son tour, les explosions infligent +2 (Burn-out et bombes collées compris)."},
	"prelude": {"name": "Prélude", "text": "Pioche 1 carte de plus à son premier tour de chaque combat."},
	"affut": {"name": "Embusqué", "text": "+2 aux attaques à distance si le porteur n'a pas bougé ce tour."},
	"main_leste": {"name": "Main leste", "text": "Tuer un ennemi équipé récupère sa pièce à coup sûr, et la carte de son objet, dans la main du tueur."},
	"execution": {"name": "Exécution", "text": "Ses coups achèvent une cible restée à 20 % de ses PV ou moins (élites 10 %, gardiens en dernière phase)."},
	"pavois_face": {"name": "Pavois", "text": "Les coups de face (hors magie) sont divisés par deux."},
	"brisant": {"name": "Brisant", "text": "Frappé au contact alors qu'il a de l'armure : repousse l'attaquant d'1 case."},
	"digue": {"name": "Digue", "text": "Garde la moitié de son armure d'un tour à l'autre (8 au plus)."},
	"ombre_portee": {"name": "Ombre portée", "text": "Après une téléportation ou un bond, sa prochaine attaque du tour frappe de dos."},
	"decrue": {"name": "Décrue", "text": "Chaque carte qu'il Épuise le soigne de 2 ; le soin en trop déborde sur l'ennemi le plus proche."},
	"trop_plein": {"name": "Trop-plein", "text": "Tout soin qu'il reçoit déborde : le surplus frappe l'ennemi le plus proche."},
	"bordee": {"name": "Bordée", "text": "Ses tourelles tirent +2."},
	"envol": {"name": "Envol", "text": "Chaque bond ou téléportation compte comme un coup d'enchaînement."},
	"contre_vague": {"name": "Contre-vague", "text": "Frappé au contact : +1 enchaînement au début de son prochain tour (2 au plus)."},
	"detente": {"name": "Détente", "text": "Quand un piège se déclenche, la proie est Marquée et il gagne 1 énergie (une fois par round)."},
	"trait_sang": {"name": "Trait de sang", "text": "Chaque carte payée en PV : +2 BPM."},
	"nuancier": {"name": "Nuancier", "text": "La première fois du tour qu'il a joué les trois voix : +1 énergie et +2 BPM."},
	"prestesse": {"name": "Prestesse", "text": "Le premier objet qu'il joue, démonte ou lance chaque tour : pioche 1."},
}

# 4 emplacements : arme, armure, bottes, bijou. dmg / hp / move / jump : bonus plats, block0 : armure au début de chaque combat.
# foe : un ennemi peut la porter (à partir du 3e combat). owner "any" : tout le monde ; sinon pièce de métier, réservée à sa classe
# et liée à ses mécaniques (concile du 28/09 : G:\Mes APP\TonerTactic_concertation\equipement\result.json).
const ITEMS := {
	# pièces communes à tous
	"epee_ecluse": {"name": "Épée de l'Écluse", "slot": "arme", "owner": "any", "dmg": 1, "passive": "contre", "rarity": 1},
	"arc_frene": {"name": "Arc de frêne", "slot": "arme", "owner": "any", "dmg": 1, "passive": "concentration", "rarity": 1},
	"baton_braise": {"name": "Bâton de feu follet", "slot": "arme", "owner": "any", "dmg": 1, "hp": 3, "passive": "", "rarity": 1},
	"perche_batelier": {"name": "Perche de batelier", "slot": "arme", "owner": "any", "dmg": 1, "jump": 1, "passive": "", "rarity": 1},
	"pied_biche": {"name": "Pied-de-biche", "slot": "arme", "owner": "any", "dmg": 1, "passive": "chasseur", "rarity": 1},
	"poincon_voilier": {"name": "Poinçon de voilier", "slot": "arme", "owner": "any", "dmg": 1, "passive": "reflexe", "rarity": 1},
	"kriss": {"name": "Kriss jumeau", "slot": "arme", "owner": "any", "dmg": 2, "passive": "deux_mains", "rarity": 2},
	"chapelet": {"name": "Chapelet du noyé", "slot": "arme", "owner": "any", "dmg": 2, "passive": "elan", "rarity": 2},
	"foene_anguillier": {"name": "Foëne d'anguillier", "slot": "arme", "owner": "any", "dmg": 2, "passive": "absorbe", "rarity": 2},
	"merlin_fendeur": {"name": "Merlin de fendeur", "slot": "arme", "owner": "any", "dmg": 1, "passive": "arme_plus", "rarity": 2},
	"canon_main": {"name": "Tromblon des quais", "slot": "arme", "owner": "any", "dmg": 3, "move": -1, "passive": "", "rarity": 3},
	"serpe_vendange": {"name": "Serpe de vendange", "slot": "arme", "owner": "any", "dmg": 2, "passive": "execution", "rarity": 3},
	"sabre_equinoxe": {"name": "Sabre d'équinoxe", "slot": "arme", "owner": "any", "dmg": 3, "passive": "deux_mains", "passive2": "execution", "rarity": 4},
	"arc_basses_eaux": {"name": "Arc des basses eaux", "slot": "arme", "owner": "any", "dmg": 3, "passive": "concentration", "passive2": "absorbe", "rarity": 4},
	"faux_regain": {"name": "Faux de regain", "slot": "arme", "owner": "any", "dmg": 3, "passive": "casseur", "passive2": "charogne", "rarity": 4},
	"coeur_pierre": {"name": "Cotte rouillée", "slot": "armure", "owner": "any", "hp": 6, "passive": "", "rarity": 1, "foe": true},
	"cuirasse_compagnie": {"name": "Cuirasse de la Compagnie", "slot": "armure", "owner": "any", "block0": 5, "passive": "", "rarity": 1, "foe": true},
	"cotte_vase": {"name": "Cotte de limon", "slot": "armure", "owner": "any", "hp": 4, "block0": 3, "passive": "", "rarity": 1, "foe": true},
	"cire_passeur": {"name": "Ciré du batelier", "slot": "armure", "owner": "any", "hp": 3, "passive": "flotte", "rarity": 1, "foe": true},
	"gambison_filet": {"name": "Gambison de filet", "slot": "armure", "owner": "any", "hp": 3, "block0": 2, "passive": "", "rarity": 1, "foe": true},
	"oeil_vigilant": {"name": "Dossière du guetteur", "slot": "armure", "owner": "any", "passive": "vigilance", "rarity": 2, "foe": true},
	"bracelet_fleches": {"name": "Brassards de roseau", "slot": "armure", "owner": "any", "passive": "parade", "rarity": 2, "foe": true},
	"carapace_ecrevisse": {"name": "Carapace d'écrevisse", "slot": "armure", "owner": "any", "block0": 4, "passive": "contre", "rarity": 2, "foe": true},
	"mantelet_feuilles": {"name": "Mantelet de feuilles mortes", "slot": "armure", "owner": "any", "hp": 3, "passive": "reflexe", "rarity": 2, "foe": true},
	"brigandine_noyee": {"name": "Brigandine noyée", "slot": "armure", "owner": "any", "move": -1, "block0": 8, "passive": "", "rarity": 2, "foe": true},
	"heaume_noye": {"name": "Heaume noyé", "slot": "armure", "owner": "any", "hp": 10, "move": -1, "passive": "", "rarity": 2, "foe": true},
	"jaque_cloutee": {"name": "Jaque cloutée", "slot": "armure", "owner": "any", "block0": 3, "passive": "casseur", "rarity": 2, "foe": true},
	"pourpoint_haleur": {"name": "Pourpoint de haleur", "slot": "armure", "owner": "any", "hp": 5, "passive": "charogne", "rarity": 2},
	"pelisse_loutre": {"name": "Pelisse de loutre", "slot": "armure", "owner": "any", "hp": 4, "passive": "elan", "rarity": 2},
	"anneau_bouclier": {"name": "Plastron de vanne", "slot": "armure", "owner": "any", "passive": "bouclier", "rarity": 3, "foe": true},
	"ecailles_carpe": {"name": "Écailles de carpe", "slot": "armure", "owner": "any", "hp": 4, "block0": 3, "passive": "parade", "rarity": 3, "foe": true},
	"pavois_chene": {"name": "Pavois de chêne", "slot": "armure", "owner": "any", "block0": 3, "passive": "pavois_face", "rarity": 3, "foe": true},
	"cuirasse_gardien": {"name": "Cuirasse du Gardien", "slot": "armure", "owner": "any", "hp": 8, "block0": 6, "passive": "contre", "passive2": "ancre", "rarity": 4},
	"voile_dame": {"name": "Voile de la Dame", "slot": "armure", "owner": "any", "hp": 6, "passive": "flotte", "passive2": "regen", "rarity": 4},
	"manteau_cendre": {"name": "Manteau de cendre", "slot": "armure", "owner": "any", "block0": 4, "passive": "retour", "passive2": "reflexe", "rarity": 4},
	"haubert_bief": {"name": "Haubert du bief mort", "slot": "armure", "owner": "any", "hp": 6, "passive": "pavois_face", "passive2": "vigilance", "rarity": 4},
	"bottes_heron": {"name": "Bottes de héron", "slot": "bottes", "owner": "any", "passive": "deplacement", "rarity": 1, "foe": true},
	"sandales_saut": {"name": "Semelles de crapaud", "slot": "bottes", "owner": "any", "passive": "saut", "rarity": 1, "foe": true},
	"echasses_roseau": {"name": "Échasses de roseau", "slot": "bottes", "owner": "any", "move": -1, "jump": 3, "passive": "", "rarity": 1, "foe": true},
	"sabots_halage": {"name": "Sabots de halage", "slot": "bottes", "owner": "any", "jump": 1, "block0": 2, "passive": "", "rarity": 1, "foe": true},
	"guetres_eclusier": {"name": "Guêtres de quai", "slot": "bottes", "owner": "any", "hp": 4, "passive": "", "rarity": 1, "foe": true},
	"chaussons_loutre": {"name": "Chaussons de loutre", "slot": "bottes", "owner": "any", "passive": "flotte", "rarity": 1, "foe": true},
	"ecaille_eau": {"name": "Bottes de liège", "slot": "bottes", "owner": "any", "passive": "eau", "rarity": 2, "foe": true},
	"bottes_vase": {"name": "Bottes de vase", "slot": "bottes", "owner": "any", "block0": 2, "passive": "ancre", "rarity": 2, "foe": true},
	"bottes_fuyard": {"name": "Bottes du fuyard", "slot": "bottes", "owner": "any", "move": 1, "jump": 1, "passive": "", "rarity": 2, "foe": true},
	"houseaux_maraude": {"name": "Houseaux de maraude", "slot": "bottes", "owner": "any", "passive": "reflexe", "rarity": 2, "foe": true},
	"semelles_cloutees": {"name": "Semelles cloutées", "slot": "bottes", "owner": "any", "block0": 2, "passive": "vigilance", "rarity": 2, "foe": true},
	"pas_passeur": {"name": "Pas du Passeur", "slot": "bottes", "owner": "any", "move": 1, "jump": 1, "passive": "eau", "rarity": 3, "foe": true},
	"bottes_greve": {"name": "Bottes de grève", "slot": "bottes", "owner": "any", "move": 2, "passive": "", "rarity": 3, "foe": true},
	"bottes_chevrier": {"name": "Bottes du chevrier", "slot": "bottes", "owner": "any", "move": 1, "jump": 2, "passive": "vigilance", "passive2": "saut", "rarity": 4},
	"grandes_eaux": {"name": "Bottes des grandes eaux", "slot": "bottes", "owner": "any", "move": 1, "passive": "eau", "passive2": "ancre", "rarity": 4},
	"bottes_vent": {"name": "Bottes du vent d'ouest", "slot": "bottes", "owner": "any", "move": 1, "passive": "reflexe", "passive2": "parade", "rarity": 4},
	"dent_silure": {"name": "Dent de silure", "slot": "bijou", "owner": "any", "dmg": 1, "passive": "", "rarity": 1, "foe": true},
	"medaille_rouillee": {"name": "Insigne rouillé", "slot": "bijou", "owner": "any", "hp": 4, "block0": 2, "passive": "", "rarity": 1, "foe": true},
	"bourse": {"name": "Bourse du naufrageur", "slot": "bijou", "owner": "any", "passive": "chasseur", "rarity": 1},
	"broche_rousse": {"name": "Broche de feuille rousse", "slot": "bijou", "owner": "any", "block0": 3, "passive": "", "rarity": 1, "foe": true},
	"bracelet_jonc": {"name": "Bracelet de jonc", "slot": "bijou", "owner": "any", "hp": 5, "passive": "", "rarity": 1, "foe": true},
	"amulette_regen": {"name": "Amulette de mousse", "slot": "bijou", "owner": "any", "passive": "regen", "rarity": 2, "foe": true},
	"plume_elan": {"name": "Perle de souffle", "slot": "bijou", "owner": "any", "passive": "elan", "rarity": 2},
	"miroir": {"name": "Miroir de cuivre", "slot": "bijou", "owner": "any", "passive": "retour", "rarity": 2, "foe": true},
	"bague_charognard": {"name": "Bague du charognard", "slot": "bijou", "owner": "any", "passive": "charogne", "rarity": 2, "foe": true},
	"lanterne_brume": {"name": "Lanterne de brume", "slot": "bijou", "owner": "any", "passive": "concentration", "rarity": 2},
	"croc_brochet": {"name": "Croc de brochet", "slot": "bijou", "owner": "any", "passive": "venin", "rarity": 2, "foe": true},
	"signet_algue": {"name": "Signet d'algue", "slot": "bijou", "owner": "any", "passive": "prelude", "rarity": 2},
	"corne_brume": {"name": "Corne de brume", "slot": "bijou", "owner": "any", "passive": "deux_mains", "rarity": 2, "foe": true},
	"bague_gue": {"name": "Bague du gué", "slot": "bijou", "owner": "any", "passive": "eau", "rarity": 2, "foe": true},
	"gantelet": {"name": "Chevalière lestée", "slot": "bijou", "owner": "any", "passive": "arme_plus", "rarity": 3, "foe": true},
	"sceau_bourreau": {"name": "Sceau du bourreau", "slot": "bijou", "owner": "any", "passive": "execution", "rarity": 3},
	"talisman_etain": {"name": "Talisman d'étain", "slot": "bijou", "owner": "any", "passive": "economie", "rarity": 3},
	"coeur_chene": {"name": "Cœur de chêne", "slot": "bijou", "owner": "any", "passive": "bouclier", "rarity": 3, "foe": true},
	"coeur_ecluse": {"name": "Cœur de l'Écluse", "slot": "bijou", "owner": "any", "hp": 8, "passive": "elan", "passive2": "absorbe", "rarity": 4},
	"oeil_paupiere": {"name": "Œil sans paupière", "slot": "bijou", "owner": "any", "passive": "vigilance", "passive2": "execution", "rarity": 4},
	"sceau_compagnie": {"name": "Sceau de la Compagnie", "slot": "bijou", "owner": "any", "dmg": 2, "passive": "charogne", "passive2": "absorbe", "rarity": 4},
	"medaillon_vannes": {"name": "Médaillon des vannes", "slot": "bijou", "owner": "any", "passive": "prelude", "passive2": "economie", "rarity": 4},
	# pièces de métier : artificier (passif lié à ses mécaniques)
	"cle_meca": {"name": "Clé d'éclusier", "slot": "arme", "owner": "artificier", "dmg": 1, "passive": "meche", "rarity": 2},
	"marteau_forge": {"name": "Marteau de radoub", "slot": "arme", "owner": "artificier", "dmg": 2, "passive": "bordee", "rarity": 3},
	"canon_mere": {"name": "Canon de la vanne-mère", "slot": "arme", "owner": "artificier", "dmg": 3, "passive": "meche", "passive2": "bordee", "rarity": 4},
	# pièces de métier : garde (passif lié à ses mécaniques)
	"masse_os": {"name": "Masse brise-lames", "slot": "arme", "owner": "garde", "dmg": 2, "passive": "brisant", "rarity": 2},
	"hallebarde": {"name": "Hallebarde du rempart", "slot": "arme", "owner": "garde", "dmg": 2, "passive": "digue", "rarity": 3},
	"masse_digue": {"name": "Masse de la digue", "slot": "arme", "owner": "garde", "dmg": 3, "passive": "digue", "passive2": "brisant", "rarity": 4},
	# pièces de métier : lame (passif lié à ses mécaniques)
	"dague_ombre": {"name": "Dague d'ombre", "slot": "arme", "owner": "lame", "dmg": 1, "passive": "ombre_portee", "rarity": 2},
	"lame_soif": {"name": "Lame de soif", "slot": "arme", "owner": "lame", "dmg": 2, "passive": "venin", "rarity": 3},
	"derniere_arche": {"name": "Dague de la dernière arche", "slot": "arme", "owner": "lame", "dmg": 3, "passive": "ombre_portee", "passive2": "venin", "rarity": 4},
	# pièces de métier : moine (passif lié à ses mécaniques)
	"bandes_jade": {"name": "Bandes de grue", "slot": "arme", "owner": "moine", "dmg": 1, "passive": "envol", "rarity": 2},
	"gantelets_ressac": {"name": "Poings d'étrave", "slot": "arme", "owner": "moine", "dmg": 2, "passive": "contre_vague", "rarity": 3},
	"poings_crue": {"name": "Poings de la crue", "slot": "arme", "owner": "moine", "dmg": 3, "passive": "envol", "passive2": "contre_vague", "rarity": 4},
	# pièces de métier : oracle (passif lié à ses mécaniques)
	"baton_lotus": {"name": "Bâton de décrue", "slot": "arme", "owner": "oracle", "dmg": 1, "hp": 4, "passive": "decrue", "rarity": 2},
	"sceptre_maree": {"name": "Sceptre du déversoir", "slot": "arme", "owner": "oracle", "dmg": 2, "passive": "trop_plein", "rarity": 3},
	"sceptre_vive": {"name": "Sceptre de l'augure", "slot": "arme", "owner": "oracle", "dmg": 3, "passive": "decrue", "passive2": "trop_plein", "rarity": 4},
	# pièces de métier : receleur (passif lié à ses mécaniques)
	"crochets": {"name": "Trousseau de crochets", "slot": "arme", "owner": "receleur", "dmg": 1, "passive": "prestesse", "rarity": 2},
	"gants_velours": {"name": "Gants de velours", "slot": "arme", "owner": "receleur", "dmg": 2, "passive": "main_leste", "rarity": 3},
	"passe_partout": {"name": "Passe-partout", "slot": "arme", "owner": "receleur", "dmg": 3, "passive": "prestesse", "passive2": "main_leste", "rarity": 4},
	# pièces de métier : tidiane (passif lié à ses mécaniques)
	"pinceau": {"name": "Pinceau de sang", "slot": "arme", "owner": "tidiane", "dmg": 1, "passive": "trait_sang", "rarity": 2},
	"palette": {"name": "Palette à trois godets", "slot": "arme", "owner": "tidiane", "dmg": 2, "passive": "nuancier", "rarity": 3},
	"geste_parfait": {"name": "Le Geste parfait", "slot": "arme", "owner": "tidiane", "dmg": 3, "passive": "trait_sang", "passive2": "nuancier", "rarity": 4},
	# pièces de métier : trappeur (passif lié à ses mécaniques)
	"arc_os": {"name": "Arc du rabatteur", "slot": "arme", "owner": "trappeur", "dmg": 1, "passive": "detente", "rarity": 2},
	"arbalete_silure": {"name": "Arbalète à harpon", "slot": "arme", "owner": "trappeur", "dmg": 2, "passive": "affut", "rarity": 3},
	"arc_chevrier": {"name": "Arc du chevrier", "slot": "arme", "owner": "trappeur", "dmg": 3, "passive": "affut", "passive2": "detente", "rarity": 4},
}
const ITEM_ICON := {"epee_ecluse": "epee", "arc_frene": "arc", "baton_braise": "baton", "perche_batelier": "baton", "pied_biche": "piedbiche", "poincon_voilier": "dague", "kriss": "dagues", "chapelet": "bandes", "foene_anguillier": "hallebarde", "merlin_fendeur": "marteau", "canon_main": "canon", "serpe_vendange": "dague", "sabre_equinoxe": "epee", "arc_basses_eaux": "arc", "faux_regain": "hallebarde", "coeur_pierre": "cotte", "cuirasse_compagnie": "cuirasse_compagnie", "cotte_vase": "cotte_vase", "cire_passeur": "cire_passeur", "gambison_filet": "cotte", "oeil_vigilant": "dossiere", "bracelet_fleches": "brassards", "carapace_ecrevisse": "carapace_ecrevisse", "mantelet_feuilles": "mantelet_feuilles", "brigandine_noyee": "brigandine_noyee", "heaume_noye": "heaume_noye", "jaque_cloutee": "cotte", "pourpoint_haleur": "cotte_vase", "pelisse_loutre": "mantelet_feuilles", "anneau_bouclier": "plastron", "ecailles_carpe": "carapace_ecrevisse", "pavois_chene": "plastron", "cuirasse_gardien": "cuirasse_compagnie", "voile_dame": "cire_passeur", "manteau_cendre": "mantelet_feuilles", "haubert_bief": "brigandine_noyee", "bottes_heron": "bottes", "sandales_saut": "crapaud", "echasses_roseau": "echasses_roseau", "sabots_halage": "sabots_halage", "guetres_eclusier": "guetres_eclusier", "chaussons_loutre": "ecaille", "ecaille_eau": "liege", "bottes_vase": "bottes_vase", "bottes_fuyard": "bottes_fuyard", "houseaux_maraude": "bottes", "semelles_cloutees": "sandales", "pas_passeur": "pas_passeur", "bottes_greve": "bottes_fuyard", "bottes_chevrier": "bottes_fuyard", "grandes_eaux": "liege", "bottes_vent": "bottes_fuyard", "dent_silure": "dent_silure", "medaille_rouillee": "medaille_rouillee", "bourse": "bourse", "broche_rousse": "plume", "bracelet_jonc": "bracelet", "amulette_regen": "amulette", "plume_elan": "perle", "miroir": "miroir", "bague_charognard": "bague_charognard", "lanterne_brume": "lanterne_brume", "croc_brochet": "croc_brochet", "signet_algue": "signet_algue", "corne_brume": "amulette", "bague_gue": "anneau", "gantelet": "chevaliere", "sceau_bourreau": "chevaliere", "talisman_etain": "oeil", "coeur_chene": "coeur", "coeur_ecluse": "amulette", "oeil_paupiere": "dossiere", "sceau_compagnie": "medaille_rouillee", "medaillon_vannes": "amulette", "masse_os": "masse", "hallebarde": "hallebarde", "masse_digue": "masse", "dague_ombre": "dague", "lame_soif": "dague", "derniere_arche": "dague", "baton_lotus": "baton", "sceptre_maree": "sceptre", "sceptre_vive": "sceptre", "cle_meca": "cle", "marteau_forge": "marteau", "canon_mere": "canon", "bandes_jade": "bandes", "gantelets_ressac": "gantelet", "poings_crue": "gantelet", "arc_os": "arc", "arbalete_silure": "arbalete", "arc_chevrier": "arc", "pinceau": "pinceau", "palette": "palette", "geste_parfait": "pinceau", "crochets": "crochets", "gants_velours": "gants", "passe_partout": "crochets"}
const SLOTS := ["arme", "armure", "bottes", "bijou"]
const SLOT_NAME := {"arme": "Arme", "armure": "Armure", "bottes": "Bottes", "bijou": "Bijou"}
const PRICE := {1: 45, 2: 75, 3: 110, 4: 170}

const PROPS := {
	"coffre": {"name": "Coffre", "text": "Frappez-le avec une attaque, ou ouvrez-le au contact sans perdre votre déplacement."},
	"brasero": {"name": "Brasero", "text": "Compte comme un baril : un coup le fait exploser, 7 dégâts autour."},
	"pilier": {"name": "Pilier fendu", "text": "Frappé ou poussé, il s'effondre sur les 2 cases suivantes : 9 dégâts."},
	"baril": {"name": "Baril de poudre", "text": "Un coup le fait exploser : 7 dégâts autour."},
	"bombe_retard": {"name": "Bombe à retardement", "text": "Explose dans %d round(s) : %d dégâts en croix, aux ennemis seulement. Les coups ne la déclenchent pas."},
	"tourelle": {"name": "Tourelle", "text": "Tire 4 sur l'ennemi le plus proche à chaque fin de tour."},
	"vasque": {"name": "Vasque", "text": "Au contact, soigne 40 % des PV max de qui y boit, héros ou ennemi (cela coûte son déplacement au héros). Une seule gorgée : un ennemi blessé viendra la boire."},
	"cloche": {"name": "Cloche d'alarme", "text": "Un héros au contact la brise (cela coûte son déplacement) : les ennemis à 4 cases perdent leur prochain tour. Un ennemi libre qui l'atteint sonne l'alarme : 2 renforts."},
	"ratelier": {"name": "Râtelier d'armes", "text": "Au contact, un héros y prend une arme (cela lui coûte son déplacement). Une seule fois."},
}


static func item_icon(id: String) -> String:
	## L'icône peinte de la pièce (KIE, pixel art : blender/kie_ui/gen_items.py), sinon l'idéogramme de son type.
	var p := "res://assets/ui/item_%s.png" % id
	if ResourceLoader.exists(p):
		return p
	# pièce sans peinture à elle : celle d'une pièce de la même famille (une dague prend l'icône d'une dague)
	var k: String = ITEM_ICON.get(id, "anneau")
	for other in ITEM_ICON:
		if ITEM_ICON[other] == k and ResourceLoader.exists("res://assets/ui/item_%s.png" % other):
			return "res://assets/ui/item_%s.png" % other
	return "res://assets/ui/gear_%s.png" % k


static func item_fits(id: String, key: String, voc := "", voc2 := "") -> bool:
	## Une pièce de métier va à sa classe, ou à qui l'a apprise en vocation ; le reste va à tout le monde.
	return ITEMS[id].owner == "any" or ITEMS[id].owner in [key, voc, voc2]


static func item_chips(id: String) -> Array:
	## Les bonus chiffrés d'une pièce, en idéogrammes (vignettes) : [icône, valeur].
	var it: Dictionary = ITEMS[id]
	var out: Array = []
	for k in [["dmg", "attaque"], ["hp", "pv"], ["move", "deplacement"], ["jump", "saut"], ["block0", "armure"]]:
		if int(it.get(k[0], 0)) != 0:
			out.append([k[1], "%+d" % int(it[k[0]])])
	return out


static func item_slot(id: String) -> String:
	var it: Dictionary = ITEMS[id]
	return SLOT_NAME[it.slot] + ("" if it.owner == "any" else " · " + HEROES[it.owner].name)


static func item_passives(id: String) -> String:
	## Seulement les effets en mots (les chiffres passent en idéogrammes) ; « » si aucun.
	var it: Dictionary = ITEMS[id]
	var parts: Array = []
	for pk in ["passive", "passive2"]:
		if it.get(pk, "") != "":
			parts.append("%s : %s" % [PASSIVES[it[pk]].name, PASSIVES[it[pk]].text])
	if int(it.get("block0", 0)) > 0:
		parts.append("Armure au début de chaque combat.")
	return "\n".join(parts)


static func item_text(id: String) -> String:
	var it: Dictionary = ITEMS[id]
	var parts: Array = []
	if it.get("dmg", 0) > 0:
		parts.append("+%d dégâts" % it.dmg)
	if it.get("hp", 0) > 0:
		parts.append("+%d PV max" % it.hp)
	for pk in ["passive", "passive2"]:
		if it.get(pk, "") != "":
			parts.append("%s : %s" % [PASSIVES[it[pk]].name, PASSIVES[it[pk]].text])
	if it.get("move", 0) != 0:
		parts.append("%+d déplacement" % it.move)
	if it.get("jump", 0) != 0:
		parts.append("%+d saut" % it.jump)
	if it.get("block0", 0) > 0:
		parts.append("+%d armure au début du combat" % it.block0)
	var who: String = SLOT_NAME[it.slot] + ("" if it.owner == "any" else " de " + HEROES[it.owner].name)
	return who + "\n" + " · ".join(parts)


# Lumière, ciel et végétation de chaque étage.
# stone : matière des murs · top : dalle | herbe · tree : essence de la couronne · flora : décor des
# sols · ring : objets dressés dans la couronne · crown : sommet des tours · monument : pièce maîtresse.
const BIOMES := [
	{"name": "L'Écluse d'Automne", "stone": "pierre", "top": "dalle", "tree": "autumn", "foliage": "autumn", "flora": "", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.84, 0.64), "sun_energy": 3.1, "sun_elev": 27.0, "sun_az": -38.0,
		"sky_top": Color(0.36, 0.56, 0.76), "sky_hor": Color(0.93, 0.83, 0.68), "ambient": 0.42, "fog": Color(0.86, 0.8, 0.7),
		"water_shallow": Color(0.2, 0.8, 0.74), "water_deep": Color(0.02, 0.32, 0.36), "glow_windows": 0.1, "leaves": ["#b4501c", "#d98434", "#8c3616", "#e39a3e"]},
	{"name": "Les Arches Moussues", "stone": "pierre", "top": "dalle", "tree": "green", "foliage": "green", "flora": "tufts", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.66, 0.42), "sun_energy": 2.4, "sun_elev": 24.0, "sun_az": 150.0,
		"sky_top": Color(0.2, 0.28, 0.46), "sky_hor": Color(0.7, 0.55, 0.5), "ambient": 1.0, "fog": Color(0.4, 0.46, 0.56),
		"water_shallow": Color(0.22, 0.68, 0.66), "water_deep": Color(0.05, 0.26, 0.32), "glow_windows": 0.5, "leaves": [], "moon": Color(0.5, 0.66, 1.0)},
	{"name": "Le Bassin de Braise", "stone": "terre", "top": "dalle", "tree": "autumn", "foliage": "autumn", "flora": "", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.68, 0.5), "sun_energy": 3.0, "sun_elev": 22.0, "sun_az": 70.0,
		"sky_top": Color(0.32, 0.32, 0.46), "sky_hor": Color(1.0, 0.64, 0.46), "ambient": 0.75, "fog": Color(0.66, 0.5, 0.44),
		"water_shallow": Color(0.26, 0.72, 0.74), "water_deep": Color(0.06, 0.3, 0.38), "glow_windows": 0.3, "leaves": ["#b4501c", "#d98434", "#8c3616"], "embers": true, "moon": Color(0.45, 0.5, 0.9)},
	{"name": "Le Sanctuaire Lilas", "stone": "lilas", "top": "dalle", "tree": "green", "foliage": "green", "flora": "tufts", "ring": ["statue"], "crown": "crown", "monument": "statue_giant",
		"sun": Color(1.0, 0.95, 0.82), "sun_energy": 2.6, "sun_elev": 42.0, "sun_az": 20.0,
		"sky_top": Color(0.55, 0.78, 0.86), "sky_hor": Color(0.88, 0.82, 0.96), "ambient": 0.6, "fog": Color(0.82, 0.78, 0.92),
		"water_shallow": Color(0.35, 0.86, 0.8), "water_deep": Color(0.08, 0.32, 0.44), "glow_windows": 0.0, "leaves": ["#e8d46a", "#f2e28a"]},
	{"name": "Les Tours-Bassins", "stone": "brique", "top": "dalle", "tree": "green", "foliage": "green", "flora": "", "ring": [], "crown": "basin", "monument": "monument",
		"sun": Color(1.0, 0.94, 0.84), "sun_energy": 2.8, "sun_elev": 38.0, "sun_az": -60.0,
		"sky_top": Color(0.72, 0.8, 0.78), "sky_hor": Color(0.96, 0.93, 0.86), "ambient": 0.55, "fog": Color(0.88, 0.9, 0.86),
		"water_shallow": Color(0.3, 0.72, 0.74), "water_deep": Color(0.05, 0.28, 0.32), "glow_windows": 0.2, "leaves": ["#6a8f3a", "#7da44a"]},
	{"name": "L'Altiplano", "stone": "terre", "top": "herbe", "tree": "", "foliage": "green", "flora": "tufts", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.9, 0.72), "sun_energy": 3.0, "sun_elev": 30.0, "sun_az": 110.0,
		"sky_top": Color(0.74, 0.86, 0.68), "sky_hor": Color(1.0, 0.9, 0.76), "ambient": 0.5, "fog": Color(0.7, 0.62, 0.72),
		"water_shallow": Color(0.45, 0.72, 0.9), "water_deep": Color(0.12, 0.3, 0.5), "glow_windows": 0.05, "leaves": []},
	{"name": "La Cité de Cristal", "stone": "blanc", "top": "dalle", "tree": "green", "foliage": "green", "flora": "", "ring": ["crystal_0", "crystal_1"], "crown": "crown", "monument": "crystal_giant",
		"sun": Color(1.0, 0.9, 0.74), "sun_energy": 2.9, "sun_elev": 34.0, "sun_az": -20.0,
		"sky_top": Color(0.5, 0.72, 0.95), "sky_hor": Color(0.96, 0.92, 0.84), "ambient": 0.55, "fog": Color(0.86, 0.9, 0.96),
		"water_shallow": Color(0.28, 0.82, 0.82), "water_deep": Color(0.04, 0.3, 0.42), "glow_windows": 0.1, "leaves": []},
	{"name": "La Prairie d'Épilobes", "stone": "blanc", "top": "herbe", "tree": "pine", "foliage": "pink", "flora": "fireweed", "ring": ["column_fallen"], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.82, 0.72), "sun_energy": 2.6, "sun_elev": 24.0, "sun_az": -80.0,
		"sky_top": Color(0.92, 0.7, 0.68), "sky_hor": Color(1.0, 0.88, 0.8), "ambient": 0.55, "fog": Color(0.96, 0.82, 0.78),
		"water_shallow": Color(0.3, 0.7, 0.72), "water_deep": Color(0.08, 0.28, 0.36), "glow_windows": 0.05, "leaves": ["#e0418c", "#f06aa8", "#f59ac4"]},
	# d'après les images envoyées le 25/09 : crypte aux cierges, bosquet émeraude, grotte au croissant, temple de jade
	{"name": "La Crypte aux Cierges", "stone": "crypte", "top": "dalle", "tree": "", "foliage": "teal", "flora": "", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(0.78, 0.7, 1.0), "sun_energy": 2.0, "sun_elev": 40.0, "sun_az": 35.0,
		"sky_top": Color(0.16, 0.14, 0.28), "sky_hor": Color(0.5, 0.34, 0.44), "ambient": 1.05, "fog": Color(0.34, 0.27, 0.4),
		"water_shallow": Color(0.2, 0.6, 0.58), "water_deep": Color(0.04, 0.18, 0.24), "glow_windows": 0.9, "leaves": [], "embers": true, "moon": Color(0.55, 0.62, 1.0)},
	{"name": "Le Bosquet Émeraude", "stone": "pierre", "top": "herbe", "tree": "teal", "foliage": "teal", "flora": "tufts", "ring": ["statue"], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.96, 0.84), "sun_energy": 2.8, "sun_elev": 46.0, "sun_az": -30.0,
		"sky_top": Color(0.42, 0.68, 0.62), "sky_hor": Color(0.86, 0.95, 0.8), "ambient": 0.62, "fog": Color(0.5, 0.68, 0.6),
		"water_shallow": Color(0.3, 0.78, 0.62), "water_deep": Color(0.05, 0.3, 0.28), "glow_windows": 0.3, "leaves": ["#4fb8a8", "#8fd06a"]},
	{"name": "La Grotte au Croissant", "stone": "quartz", "top": "dalle", "tree": "", "foliage": "pink", "flora": "", "ring": ["crystal_0", "crystal_1"], "crown": "crown", "monument": "crystal_giant",
		"sun": Color(1.0, 0.86, 0.82), "sun_energy": 2.6, "sun_elev": 58.0, "sun_az": 10.0,
		"sky_top": Color(0.24, 0.16, 0.24), "sky_hor": Color(0.62, 0.46, 0.52), "ambient": 0.85, "fog": Color(0.54, 0.4, 0.48),
		"water_shallow": Color(0.52, 0.48, 0.74), "water_deep": Color(0.14, 0.1, 0.24), "glow_windows": 0.4, "leaves": ["#f4dcec", "#ffffff"]},
	{"name": "Le Temple de Jade", "stone": "jade", "top": "dalle", "tree": "green", "foliage": "green", "flora": "tufts", "ring": ["statue"], "crown": "crown", "monument": "statue_giant",
		"sun": Color(0.96, 1.0, 0.86), "sun_energy": 2.5, "sun_elev": 40.0, "sun_az": 120.0,
		"sky_top": Color(0.36, 0.52, 0.46), "sky_hor": Color(0.68, 0.8, 0.7), "ambient": 0.6, "fog": Color(0.4, 0.54, 0.46),
		"water_shallow": Color(0.26, 0.72, 0.62), "water_deep": Color(0.04, 0.26, 0.24), "glow_windows": 0.2, "leaves": ["#7da44a", "#a8d070"]},
]

# Champions : un affixe tiré au sort, comme les ennemis rares du Monde des objets.
const AFFIXES := {
	"blinde": {"name": "blindé", "text": "+5 armure par tour."},
	"enrage": {"name": "enragé", "text": "+3 dégâts."},
	"veloce": {"name": "véloce", "text": "+2 déplacement, +1 saut."},
	"epineux": {"name": "épineux", "text": "Riposte au contact."},
	"vampire": {"name": "vampire", "text": "Se soigne de la moitié des dégâts infligés."},
}


# Améliorations : [niveau 2, niveau 3]. Un nombre s'ajoute (cost, selfdmg peuvent baisser),
# « reach » allonge la portée, le reste remplace (text, trig, exhaust...). Chaque niveau change la carte.
const UPGRADES := {
	"frappe": [{"dmg": 3}, {"push": 1, "text": "Inflige {dmg} et repousse 1."}],
	"pavois": [{"block": 3}, {"draw": 1, "text": "Gagne {block} d'armure. Pioche 1."}],
	"charge": [{"dmg": 2}, {"push": 1, "reach": 1}],
	"defi": [{"block": 4}, {"bait": true, "text": "+{block} armure. Provocation. Qui frappe le héros devient Exposé."}],
	"rempart": [{"block": 3}, {"taunt": true, "text": "+{block} armure au Garde et aux alliés voisins. Provocation."}],
	"marteau": [{"dmg": 2}, {"root": 1, "text": "Inflige {dmg} et repousse de {push}. La cible reste Entravée 1 tour."}],
	"bastion": [{"block": 2}, {"adj": true, "text": "+{block} armure au Garde et aux alliés voisins. Pioche {draw}."}],
	"bouclier": [{"dmg": 2, "block": 2}, {"reach": 1, "bounce": true, "text": "Lance le pavois : {dmg}, repousse 1, rebondit sur un voisin. +{block} armure."}],
	"crochet": [{"dmg": 2, "reach": 1}, {"expose": true, "text": "Inflige {dmg} et attire l'ennemi de 2 cases. Il est Exposé."}],
	"forteresse": [{"cost": -1}, {"block": 6, "text": "L'armure des héros ne s'efface plus. Armure à chaque héros : +{block} armure."}],
	"estoc": [{"dmg": 2}, {"pierce": true, "text": "Inflige {dmg}, armure ignorée. De dos : ×2."}],
	"ombre": [{"reach": 1}, {"block": 3, "near_ally": true, "text": "Téléportation, relief ignoré. +{block} armure au héros et aux alliés au contact."}],
	"double": [{"dmg": 1}, {"bounce": true, "text": "Inflige {dmg} deux fois, puis rebondit sur un ennemi voisin de la cible."}],
	"venin": [{"poison": 2}, {"mark": 1, "text": "Inflige {dmg} et {poison} de poison. La cible est Marquée."}],
	"couperet": [{"dmg": 2}, {"exec": true, "text": "Inflige {dmg}. Doublé si la cible est sous la moitié de ses PV. Exécution."}],
	"ricochet": [{"dmg": 2}, {"chain": 3, "bounce": false, "text": "Dague : {dmg}, puis saute sur 2 ennemis proches."}],
	"fente": [{"dmg": 2}, {"reach": 1, "push": 1, "text": "Fonce sur un ennemi et frappe : {dmg}. Repousse {push}."}],
	"embuscade": [{"cost": -1}, {"iframe": true, "text": "Le prochain coup de la Lame compte comme de dos. Pioche {draw}. Elle esquive le prochain coup reçu."}],
	"coupures": [{"cost": -1}, {"val": 1, "text": "Chaque carte jouée inflige 2 à un ennemi au hasard."}],
	"braise": [{"dmg": 2}, {"push": 1, "text": "Inflige {dmg} à distance, repousse {push}."}],
	"seve": [{"heal": 4}, {"swap": true, "text": "Soigne {heal} un allié et échange de place avec lui."}],
	"colonne": [{"dmg": 3}, {"ground": "vase", "text": "Inflige {dmg} en croix autour d'une case ; ces cases deviennent Vase."}],
	"maree": [{"dmg": 2}, {"root": 1, "text": "Inflige {dmg}. Repousse {push}, puis l'ennemi est Entravé {root} tour."}],
	"surveil": [{"draw": 1}, {"exhaust": false, "text": "Pioche {draw}."}],
	"delve": [{"retain": true, "text": "Conservé. 2 dégâts par carte en défausse, puis la défausse est exilée. Épuise."}, {"draw": 2, "text": "Conservé. 2 dégâts par carte en défausse, puis la défausse est exilée. Pioche {draw}. Épuise."}],
	"arc": [{"dmg": 1}, {"det_near": true, "text": "Inflige {dmg}. Saute ensuite sur 2 ennemis proches. Un baril ou un brasero voisin de la première cible saute."}],
	"echo": [{"cost": -1}, {"retain": true, "text": "Conservé. La prochaine carte jouée ce tour agit deux fois. Épuise."}],
	"cendres": [{"val": 1, "text": "Chaque tour de l'Oracle, 6 dégâts à l'ennemi le plus proche."}, {"val2": 1, "text": "Chaque tour de l'Oracle, 6 dégâts aux deux ennemis les plus proches."}],
	"lotus": [{"heal_all": 2}, {"rune": "source", "text": "Soigne {heal_all} tous les héros. Armure à chaque héros : +{block} armure. La case du héros devient une Source."}],
	"grenade": [{"dmg": 2}, {"aoe_baril": true, "text": "Inflige {dmg} en croix autour d'une case. Si la case visée est libre, y laisse un baril."}],
	"baril": [{"draw": 1}, {"reach": 2}],
	"etincelle": [{"reach": 2}, {"draw": 1, "text": "Fait sauter un baril ou un brasero. Pioche 1."}],
	"rivet": [{"dmg": 2}, {"push": 1, "text": "Inflige {dmg}, repousse {push}. +{block} armure."}],
	"tourelle": [{"tdmg": 1}, {"tmark": true, "text": "Pose une tourelle : {tdmg} au plus proche à chaque round, qui devient Marqué 2 tours ; {turns} rounds."}],
	"surcharge": [{"draw": 1, "text": "+1 énergie, pioche {draw}. Épuise."}, {"retain": true, "text": "Conservé. +1 énergie, pioche {draw}. Épuise."}],
	"mortier": [{"dmg": 3}, {"trig": {"on": "premier", "dmg": 4, "mark": 2}}],
	"atelier": [{"cost": -1}, {"val": 1, "text": "Chaque tour de l'Artificier, deux barils apparaissent près des ennemis."}],
	"paume": [{"dmg": 1}, {"push": 1, "text": "Inflige {dmg} et repousse de {push}. Nourrit l'enchaînement."}],
	"poing": [{"dmg": 2}, {"pierce": true, "text": "Inflige {dmg}, +{combo} par coup déjà porté ce tour. Ignore l'armure."}],
	"tourbillon": [{"dmg": 2}, {"push": 1, "text": "Frappe chaque ennemi voisin : {dmg}. Les repousse de {push}."}],
	"bond": [{"reach": 1}, {"dmg": 3, "text": "Bondit, relief ignoré. À l'arrivée, frappe chaque ennemi voisin : {dmg}."}],
	"souffle": [{"heal": 3}, {"trig": {"on": "immobile", "energy": 1}}],
	"ressac": [{"dmg": 2}, {"reach": 1, "text": "Inflige {dmg} jusqu'à 2 cases et repousse de 2."}],
	"cent": [{"dmg": 1}, {"push": 2, "text": "Inflige {dmg} cinq fois, puis repousse de {push}."}],
	"voie": [{"cost": -1}, {"val": 1, "text": "Chaque 2e coup du Moine dans un tour : +1 énergie, pioche 1."}],
	"fleche": [{"dmg": 3}, {"reach": 1, "pierce": true, "text": "Inflige {dmg} à distance, ignore l'armure."}],
	"piege": [{"tdmg": 4}, {"twin": true, "text": "Pose deux pièges ({tdmg}) : sur la case et une voisine."}],
	"marque": [{"dmg": 2, "mark": 1, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tours."}, {"expose": true, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tours et Exposé."}],
	"filet": [{"root": 1, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tours."}, {"reach": 2, "pull": 2, "text": "Inflige {dmg} et tire l'ennemi de {pull} cases vers soi. Il est Entravé {root} tours."}],
	"pluie": [{"dmg": 2}, {"root": 1, "text": "Inflige {dmg} en croix autour d'une case. Les ennemis touchés sont Entravés {root} tour."}],
	"harpon": [{"dmg": 3}, {"mark": 2, "text": "Inflige {dmg} et tire l'ennemi de 3 cases vers soi. L'ennemi est Marqué {mark} tours."}],
	"perforant": [{"dmg": 3}, {"root": 1, "text": "Inflige {dmg}, ignore l'armure. L'ennemi est Entravé {root} tour."}],
	"instinct": [{"cost": -1}, {"val2": 1, "text": "Les pièges infligent +6, entravent 2 tours et l'ennemi pris devient Marqué."}],
	"esquisse": [{"dmg": 3}, {"reach": 1, "draw": 1, "text": "Inflige {dmg}. Pioche 1."}],
	"recul": [{"block": 2}, {"target": "tile", "range": [1, 2], "blink": true, "text": "Bondit jusqu'à {rmax} cases. +{block} armure."}],
	"journal": [{"draw": 1}, {"cost": -1}],
	"pacte": [{"dmg": 3}, {"mark": 1, "text": "Inflige {dmg}, perd {selfdmg} PV. L'ennemi est Marqué {mark} tour."}],
	"arbo": [{"bpm": 1, "text": "Pioche {draw}. BPM +{bpm}."}, {"voix2": "N", "text": "Pioche {draw}. BPM +{bpm}. Compte aussi comme Ambition."}],
	"wavedash": [{"dmg": 2, "block": 2}, {"vault": true, "text": "Saute par-dessus la cible, frappe {dmg}, +{block} armure."}],
	"punchline": [{"dmg": 2}, {"push": 2, "text": "Inflige {dmg} et repousse {push}."}],
	"truecombo": [{"dmg": 1}, {"root": 1, "text": "Inflige {dmg} trois fois. L'ennemi est Entravé {root} tour."}],
	"monster": [{"bpm": 2, "text": "+{energy} énergie, BPM +{bpm}, perd {selfdmg} PV."}, {"retain": true, "text": "Conservé. +{energy} énergie, BPM +{bpm}, perd {selfdmg} PV."}],
	"nuit": [{"selfdmg": -1}, {"bpm": 3, "text": "Pioche {draw}, perd {selfdmg} PV, BPM +{bpm}. Épuise."}],
	"transmutation": [{"dmg": 2, "leech": 1, "text": "Inflige {dmg}. Se soigne de {leech}."}, {"leech": -4, "lifesteal": true, "text": "Inflige {dmg}. Vol de vie."}],
	"dette": [{"dmg": 2}, {"omen": 4, "text": "Inflige {dmg}, perd {selfdmg} PV. Présage sous la cible : {omen} dégâts."}],
	"dsm": [{"mark": 1}, {"expose": true, "text": "L'ennemi est Exposé et Marqué {mark} tours. Pioche 1."}],
	"contreanalyse": [{"block": 3}, {"delay": 2, "text": "L'ennemi est Entravé {root} tour et recule de {delay} places dans l'initiative. +{block} armure."}],
	"troisvoix": [{"flow": 1, "text": "Inflige {dmg}, +{flow} par carte déjà jouée ce tour."}, {"bounce": true, "text": "Inflige {dmg}, +{flow} par carte déjà jouée ce tour, rebondit sur un voisin."}],
	"break174": [{"dmg": 3}, {"drop": 1, "text": "Inflige {dmg}. Drop ×{drop}."}],
	"purerage": [{"dmg": 2}, {"taunt": true, "block": 6, "text": "Inflige {dmg} deux fois, +{block} armure. Provocation. Chaque allié reçoit un Crescendo gratuit et Éphémère."}],
	"potentiel": [{"dmg": 4}, {"push": 2, "text": "Inflige {dmg} et repousse {push}."}],
	"revelation": [{"heal": 2}, {"mark_all": 1, "text": "Soigne {heal}, pioche 2. Chaque ennemi est Marqué {mark_all} tour. Épuise."}],
	"hyperfocus": [{"val": 2, "text": "Les attaques de Tidiane infligent +5."}, {"cost": -1}],
	"dnb": [{"cost": -1}, {"val": 1, "text": "Tidiane pioche 2 cartes de plus à chaque tour."}],
	"obsession": [{"cost": -1}, {"cost": -1}],
	"larcin": [{"dmg": 3}, {"reach": 2, "text": "Vole l'objet de la cible, puis inflige {dmg}."}],
	"cle": [{"dmg": 3}, {"push": 1, "text": "Inflige {dmg} et repousse 1."}],
	"bricolage": [{"block": 3}, {"adj": true, "text": "Fabrique 1. +{block} armure, autant à chaque allié au contact."}],
	"camelote": [{"dmg": 2}, {"push": 1, "text": "Inflige {dmg}, +{junk} par Stock. Repousse {push}."}],
	"crochetage": [{"draw": 1}, {"reach": 2}],
	"recyclage": [{"c_energy": 1}, {"draw": 1, "text": "Démonte 1 : +{c_energy} énergie, pioche {draw}."}],
	"contrefacon": [{"cost": -1}, {"draw": 1, "text": "Copie un objet de ta main (niveau 1, Éphémère). Pioche {draw}. Épuise."}],
	"coupdesac": [{"dmg": 3}, {"push": 1, "text": "Lance un objet, puis inflige {dmg} et repousse 2."}],
	"etal": [{"craft": 1, "text": "Fabrique 3. Épuise."}, {"craft_min": 2, "text": "Fabrique 3, peu communes ou mieux. Épuise."}],
	"lecasse": [{"dmg": 3}, {"behind": true, "reach": 2, "text": "Surgit dans le dos d'un ennemi, vole son objet (sinon Fabrique 1), puis inflige {dmg}."}],
	"marchenoir": [{"val": 2, "text": "Chaque objet consommé inflige 6 à l'ennemi le plus proche."}, {"val2": 1, "text": "Chaque objet consommé inflige 6 à l'ennemi le plus proche, puis le Marque 1 tour."}],
	"poches": [{"cost": -1}, {"val": 1, "text": "Au début de chaque tour du Receleur, Fabrique 2."}],
}
const MAX_LVL := 3


## Une carte en main = {"id", "lvl"} (niveau 1 à 3). Renvoie la définition au niveau voulu.
static func level(ci: Dictionary) -> int:
	return clampi(int(ci.get("lvl", 1 + int(ci.get("up", 0)))) + int(ci.get("bump", 0)), 1, MAX_LVL)


static func lvl_cap(ci: Dictionary) -> int:
	## Niveau atteignable par un raccourci (Œuvre, Geste, dés, glyphes, bienfaits) : un objet s'y arrête
	## au niveau 2. Seule la forge ouvre son niveau 3 (secret).
	return 2 if def(ci.id).has("tool") else MAX_LVL


# Cartes créées en combat seulement : jamais au butin, ni en bibliothèque.
const TOKENS := {
	"murmure": {"name": "Murmure", "g": 7, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 4, "pierce": true, "text": "Inflige {dmg}, armure ignorée.", "up": [{"dmg": 2}]},
	"t_bou_sentence": {"name": "Sentence", "g": 0, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "exec": true, "text": "Inflige {dmg}. Exécution.", "up": [{"dmg": 2}]},
	"t_sab_colis": {"name": "Colis piégé", "g": 8, "rar": 1, "cost": 0, "kind": "skill", "target": "tile", "range": [1, 2], "place": "bombe_retard", "tdmg": 6, "delay": 1, "text": "Bombe : {tdmg} en croix au prochain round, ennemis seulement.", "up": [{"tdmg": 3}]},
	"t_enl_note": {"name": "Note en marge", "g": 16, "voix": "N", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "range": [0, 0], "draw": 1, "text": "Pioche {draw}.", "up": [{"draw": 1}]},
	"t_acr_balle": {"name": "Balle de jongle", "g": 24, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 2, "combo": 1, "text": "Inflige {dmg}, +{combo} par coup déjà porté ce tour.", "up": [{"dmg": 1}]},
	"t_tem_cierge": {"name": "Cierge", "g": 1, "rar": 1, "cost": 0, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 3, "overheal": true, "text": "Soigne {heal} un allié ; le surplus devient armure doublée.", "up": [{"heal": 2}]},
	"t_nin_brume": {"name": "Pas de brume", "g": 9, "rar": 1, "cost": 0, "kind": "move", "target": "tile", "range": [1, 2], "blink": true, "hitcount": true, "text": "Téléportation. Compte comme un coup.", "up": [{"reach": 1}]},
	"t_apo_dragee": {"name": "Dragée", "g": 17, "rar": 1, "cost": 0, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 3, "draw": 1, "text": "Soigne {heal} un allié. Pioche 1.", "up": [{"heal": 2}]},
	"t_cdm_balise": {"name": "Balise", "g": 25, "rar": 1, "voix": "B", "cost": 0, "kind": "atk", "range": [1, 5], "dmg": 0, "mark": 2, "text": "L'ennemi est Marqué {mark} tours.", "up": [{"mark": 1}]},
	"t_sap_gabion": {"name": "Gabion", "g": 2, "rar": 1, "cost": 0, "kind": "skill", "target": "self", "block": 5, "text": "+{block} armure.", "up": [{"block": 2}]},
	"t_cdp_prime": {"name": "Prime", "g": 10, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 5], "dmg": 2, "trig": {"on": "proie", "dmg": 2}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}]},
	"t_dem_petard": {"name": "Pétard", "g": 18, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 3, "trig": {"on": "poudre", "dmg": 3}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}]},
	"t_bra_collet": {"name": "Collet de poche", "g": 26, "rar": 1, "cost": 0, "kind": "skill", "target": "tile", "range": [1, 2], "place": "piege", "tdmg": 4, "text": "Pose un piège ({tdmg}).", "up": [{"tdmg": 3}]},
	"t_gdc_eclat": {"name": "Éclat de bouclier", "g": 3, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "per_block": 0.5, "text": "Inflige {dmg}. Ajoute la moitié de l'armure du héros aux dégâts.", "up": [{"dmg": 2}]},
	"t_swd_entaille": {"name": "Contre-entaille", "g": 11, "voix": "R", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "trig": {"on": "attaque", "dmg": 2}, "text": "Inflige {dmg}.", "up": [{"dmg": 2}]},
	"t_art_fusee": {"name": "Fusée éclairante", "g": 19, "rar": 1, "cost": 0, "kind": "atk", "range": [2, 6], "dmg": 2, "mark": 1, "text": "Inflige {dmg}. L'ennemi est Marqué {mark} tour.", "up": [{"dmg": 2}]},
	"t_cam_rossignol": {"name": "Rossignol", "g": 27, "voix": "N", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 2], "dmg": 2, "steal": true, "text": "Vole l'objet d'un ennemi, puis inflige {dmg}.", "up": [{"dmg": 2}]},
	"t_gch_piquet": {"name": "Piquet", "g": 4, "rar": 1, "cost": 0, "kind": "skill", "target": "tile", "range": [1, 2], "place": "piege", "tdmg": 5, "text": "Pose un petit piège ({tdmg}).", "up": [{"tdmg": 3}]},
	"t_det_tuyau": {"name": "Tuyau", "g": 12, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 4], "dmg": 0, "expose": true, "text": "L'ennemi est Exposé.", "up": [{"draw": 1, "text": "L'ennemi est Exposé. Pioche 1."}]},
	"t_ing_clou": {"name": "Clou", "g": 20, "voix": "R", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 2], "dmg": 3, "bpm": 1, "text": "Inflige {dmg}. BPM +{bpm}.", "up": [{"dmg": 2}]},
	"t_ing_gabarit": {"name": "Gabarit", "g": 20, "voix": "B", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "range": [0, 0], "lvl_next": true, "text": "La prochaine carte jouée ce tour gagne un niveau pour le combat.", "up": [{"draw": 1, "text": "La prochaine carte jouée ce tour gagne un niveau pour le combat. Pioche 1."}]},
	"t_ber_entaille": {"name": "Entaille", "g": 5, "voix": "R", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "per_missing": 1, "text": "Inflige {dmg}, +{per_missing} par 5 PV manquants.", "up": [{"dmg": 2}]},
	"t_can_obus": {"name": "Obus fusant", "g": 13, "rar": 1, "cost": 0, "kind": "atk", "range": [2, 5], "dmg": 3, "overload": 2, "text": "Inflige {dmg} à distance. Surcharge 2.", "up": [{"dmg": 2}]},
	"t_fer_mitraille": {"name": "Mitraille", "g": 21, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 3, "det_near": true, "text": "Inflige {dmg}. Fait sauter un baril voisin de la cible.", "up": [{"dmg": 2}]},
	"t_dou_amende": {"name": "Amende", "g": 6, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 3, "expose": true, "text": "Inflige {dmg}. La cible est Exposée.", "up": [{"dmg": 2}]},
	"t_dou_tampon": {"name": "Tampon", "g": 6, "rar": 1, "cost": 0, "kind": "skill", "target": "self", "range": [0, 0], "iblock": 2, "text": "+{iblock} armure par Stock.", "up": [{"iblock": 1}]},
	"t_gou_disciple": {"name": "Geste du disciple", "g": 14, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 3, "heal_adj": true, "text": "Inflige {dmg}. L'allié le plus blessé à 2 cases regagne autant de PV.", "up": [{"dmg": 2}]},
	"t_lut_cle": {"name": "Clé de bras", "g": 22, "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 3, "root": 1, "text": "Inflige {dmg}. L'ennemi est Entravé {root} tour(s).", "up": [{"dmg": 2}]},
	"t_mag_lettre": {"name": "Lettre scellée", "g": 7, "rar": 1, "cost": 0, "kind": "skill", "target": "self", "draw": 1, "text": "Pioche {draw}.", "up": [{"draw": 1}]},
	"t_tir_trait": {"name": "Trait désigné", "g": 15, "rar": 1, "cost": 0, "kind": "atk", "range": [2, 6], "dmg": 3, "trig": {"on": "proie", "dmg": 2}, "text": "Inflige {dmg} à distance.", "up": [{"dmg": 2}]},
	"t_sma_jab": {"name": "Jab", "g": 23, "voix": "R", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 2, "bpm": 1, "text": "Inflige {dmg}. BPM +{bpm}.", "up": [{"dmg": 1}]},
}


static func def(id: String) -> Dictionary:
	## Définition d'une carte, de classe ou de guilde.
	return CARDS[id] if CARDS.has(id) else (TOKENS[id] if TOKENS.has(id) else Guildes.CARDS[id])


static func all_ids() -> Array:
	return CARDS.keys() + Guildes.CARDS.keys()


static func classes_of(id: String) -> Array:
	## Classes d'une carte : une seule, ou les deux de sa guilde.
	var d := def(id)
	return Guildes.pair(d.g) if d.has("g") else [d.owner]


static func holder(ci: Dictionary) -> String:
	## Héros qui a la carte dans son paquet (une carte hors classe porte « h »).
	return ci.get("h", classes_of(ci.id)[0])


static func card(ci: Dictionary) -> Dictionary:
	var c: Dictionary = def(ci.id).duplicate(true)
	c["id"] = ci.id
	c["cls"] = classes_of(ci.id)
	c["owner"] = holder(ci)
	if c.has("g"):
		c["guild"] = Guildes.LIST[c.g][2]
	var lv := level(ci)
	c["lvl"] = lv
	c["st"] = ci.get("st", false)
	for k in ["free", "cut", "eph", "ench", "cb"]:
		if ci.has(k):
			c[k] = ci[k]
	var ups: Array = UPGRADES.get(ci.id, c.get("up", []))
	for i in mini(lv - 1, ups.size()):
		var d: Dictionary = ups[i]
		for key in d:
			var v = d[key]
			if key == "reach":
				c.range = [c.range[0], c.range[1] + v]
			elif (v is int or v is float) and not (v is bool):
				c[key] = maxi(0, c.get(key, 0) + v) if v is int else c.get(key, 0.0) + v
			else:
				c[key] = v
	if ci.has("ench") and ENCHANTS.has(ci.ench):
		# enchantement (événement, défi) : un mot-clé greffé sur la carte, par-dessus ses niveaux
		var en: Dictionary = ENCHANTS[ci.ench]
		for key in en.add:
			var v = en.add[key]
			c[key] = maxi(0, int(c.get(key, 0)) + v) if key == "cost" else v
		if en.has("text"):
			c.text = c.text + " " + en.text
		c.name = c.name + " ✦"
	return c


# Enchantements : greffés sur une carte par un événement ou un défi. « need » dit sur quelles cartes
# ils ont un sens (une attaque peut recevoir Coup de grâce, jamais un baril).
const ENCHANTS := {
	"vampire": {"name": "Vampirique", "text": "Vol de vie.", "desc": "Soigne le héros de la moitié des dégâts infligés.", "add": {"lifesteal": true}, "need": "dmg"},
	"perce": {"name": "Perçante", "text": "Ignore l'armure.", "desc": "Les dégâts ignorent l'armure de la cible.", "add": {"pierce": true}, "need": "dmg"},
	"conserve": {"name": "Tenace", "text": "Conservé.", "desc": "Ne part pas à la défausse en fin de tour : elle reste en main.", "add": {"retain": true}, "need": "any"},
	"allegee": {"name": "Allégée", "desc": "Coûte 1 de moins.", "add": {"cost": -1}, "need": "cost2"},
	"grace": {"name": "Curée", "desc": "+1 énergie si la carte tue.", "add": {"trig": {"on": "grace", "energy": 1}}, "need": "atk"},
	"mur": {"name": "Désespoir", "desc": "+5 dégâts si le héros est sous 30 % de ses PV.", "add": {"trig": {"on": "mur", "dmg": 5}}, "need": "atk"},
	"proie": {"name": "Traqueur", "desc": "+4 dégâts si la cible est marquée ou entravée.", "add": {"trig": {"on": "proie", "dmg": 4}}, "need": "atk"},
	"revers": {"name": "Ombre", "desc": "Pioche 1 si le coup part dans le dos de la cible.", "add": {"trig": {"on": "dos", "draw": 1}}, "need": "melee"},
	"premier": {"name": "Ouverture", "desc": "Pioche 1 si c'est la première carte jouée du tour.", "add": {"trig": {"on": "premier", "draw": 1}}, "need": "any"},
	"execution": {"name": "Exécutrice", "text": "Exécution.", "desc": "Exécution : après le coup, une cible restée à 20 % de ses PV ou moins est achevée (élites 10 %, gardiens en dernière phase).", "add": {"exec": true}, "need": "atk"},
	"enchaine": {"name": "Rythme", "desc": "+4 armure si une autre carte a déjà été jouée ce tour.", "add": {"trig": {"on": "enchaine", "block": 4}}, "need": "any"},
}


static func ench_ok(ci: Dictionary, en: String) -> bool:
	## L'enchantement a-t-il un sens sur cette carte (à tous ses niveaux) ?
	var d := def(ci.id)
	if d.has("tool") or TOKENS.has(ci.id) or ci.has("ench") or d.get("kind", "") == "power":
		return false
	var ups: Array = UPGRADES.get(ci.id, d.get("up", []))
	var trig_any: bool = d.has("trig") or ups.any(func(u): return u.has("trig"))
	var add: Dictionary = ENCHANTS[en].add
	if add.has("trig") and trig_any:
		return false
	var c := card(ci)
	if add.has("pierce") and c.get("pierce", false) or add.has("retain") and c.get("retain", false):
		return false
	if add.has("exec") and (d.get("exec", false) or ups.any(func(u): return u.has("exec")) or c.get("target", "foe") != "foe" or c.get("around", false)):
		return false  # Exécution : attaques sur une seule cible
	match ENCHANTS[en].need:
		"dmg":
			return int(c.get("dmg", 0)) > 0
		"atk":
			return c.kind == "atk" and int(c.get("dmg", 0)) > 0
		"melee":
			return c.kind == "atk" and int(c.get("dmg", 0)) > 0 and int(c.get("range", [1, 1])[1]) <= 1
		"cost2":
			return int(c.get("cost", 0)) >= 2 and not c.has("xcost")
	return true


static func ench_roll(ci: Dictionary, r: RandomNumberGenerator) -> String:
	## Un enchantement cohérent au hasard pour cette carte, "" s'il n'y en a aucun.
	var ok: Array = ENCHANTS.keys().filter(func(e): return ench_ok(ci, e))
	return "" if ok.is_empty() else ok[r.randi_range(0, ok.size() - 1)]


const DIFF_NAME := {"cost": "Coût", "dmg": "Dégâts", "block": "Armure", "heal": "Soin", "heal_all": "Soin de groupe", "draw": "Pioche",
	"push": "Repousse", "energy": "Énergie", "hits": "Coups", "poison": "Poison", "mark": "Marque", "root": "Entrave", "turns": "Tours",
	"tdmg": "Dégâts posés", "combo": "Enchaînement", "flow": "Par carte jouée", "leech": "Vol de vie", "selfdmg": "Coût en PV",
	"val": "Puissance", "val2": "Cibles", "craft": "Objets fabriqués", "recharge": "Recharge", "bomb": "Explosion", "picots": "Picots", "oak_hp": "PV du chêne", "aura": "Brûlure", "reroll": "Repioche", "smoke": "Fumée", "root_all": "Entrave", "chain": "Rebonds", "backstab": "De dos ×",
	"boom": "Explosion", "mark_all": "Marque", "mark_near": "Marque", "recall": "Cartes reprises", "delay": "Recul d'initiative",
	"stick": "Charge", "rpoison": "Poison", "inner": "Braise", "bph": "Armure par coup", "c_block": "Armure", "c_energy": "Énergie", "lure": "Attirance",
	"craft_n": "Objets", "crash": "Choc", "per_missing": "Par 5 PV manquants", "per_used": "Par objet consommé", "per_tele": "Par téléportation", "drop": "Drop", "bpm": "BPM", "sell": "Or", "junk": "Par Stock", "iblock": "Armure par Stock", "tgrow": "Croissance", "add_n": "Cartes créées", "per_drawn": "Ouï-dire", "per_marked": "Par Marqué", "per_eph": "Par Éphémère jouée", "per_exhaust": "Par carte épuisée", "omen": "Présage", "hone": "Affûtage", "consume_root": "Par entrave", "charge_up": "Charge", "per_missing_block": "Armure par 5 PV manquants", "pay_gold": "Or", "tpush": "Recul", "heal_ally": "Soin", "per_boom": "Par baril", "fuse": "Explosion", "overload": "Surcharge", "item_poison": "Poison des objets", "idraw": "Pioche max"}
const DIFF_FLAG := {"exhaust": ["Ne s'épuise plus", "S'épuise"], "pierce": ["Ignore l'armure", ""], "bounce": ["Rebondit", "Ne rebondit plus"], "twin": ["Deux pièges", ""], "exec": ["Exécution", ""]}


static func upgrade_diff(before: Dictionary, after: Dictionary) -> String:
	## Ce que gagne la carte d'un niveau à l'autre, en clair : « Coût −1 · Repousse +1 ».
	var a := card(before)
	var b := card(after)
	var out: Array = []
	if a.has("range") and b.range[1] != a.range[1]:
		out.append("Portée %+d" % (b.range[1] - a.range[1]))
	for k in DIFF_NAME:
		var va: float = float(a.get(k, 0))
		var vb: float = float(b.get(k, 0))
		if va != vb:
			var d := vb - va
			out.append(("%s %s%s" % [DIFF_NAME[k], "+" if d > 0 else "−", str(absf(d)) if k == "backstab" else str(int(absf(d)))]))
	for k in DIFF_FLAG:
		if bool(a.get(k, false)) != bool(b.get(k, false)):
			var t: String = DIFF_FLAG[k][0 if (k == "exhaust") != bool(b.get(k, false)) else 1]
			if t != "":
				out.append(t)
	if a.get("trig", {}) != b.get("trig", {}) and b.has("trig"):
		out.append("Déclencheur : " + trig_text(b).trim_suffix("."))
	if out.is_empty():
		for k in b:
			if k != "lvl" and str(a.get(k)) != str(b.get(k)):
				out.append("Nouvel effet")
				break
	return " · ".join(out)


static func trig_text(c: Dictionary) -> String:
	if not c.has("trig"):
		return ""
	var t: Dictionary = c.trig
	var fx: Array = []
	if t.has("dmg"):
		fx.append("+%d dégâts" % t.dmg)
	if t.has("block"):
		fx.append("+%d armure" % t.block)
	if t.has("heal"):
		fx.append("soigne %d" % t.heal)
	if t.has("draw"):
		fx.append("pioche %d" % t.draw)
	if t.has("energy"):
		fx.append("+%d énergie" % t.energy)
	if t.has("poison"):
		fx.append("+%d poison" % t.poison)
	if t.has("mark"):
		fx.append("Marqué %d tours" % t.mark)
	if t.has("boom"):
		fx.append("explosion de %d autour de la cible" % t.boom)
	if t.get("keep", false):
		fx.append("l'armure reste au prochain tour")
	if t.get("refund", false):
		fx.append("revient en main")
	if t.has("craft"):
		fx.append("fabrique %d objet%s" % [t.craft, "s" if int(t.craft) > 1 else ""])
	return "%s : %s." % [TRIGGERS[t.on].name, ", ".join(fx)]


static func fill(t: String, c: Dictionary) -> String:
	## Remplace {clé} par la valeur de la carte, {rmax} par sa portée maximale.
	if c.has("range"):
		t = t.replace("{rmax}", str(c.range[1]))
	for k in c:
		if (c[k] is int or c[k] is float) and not (c[k] is bool) and t.contains("{%s}" % k):
			t = t.replace("{%s}" % k, str(int(c[k])))
	return t


static func card_text(c: Dictionary) -> String:
	var t: String = fill(c.text, c)
	var tt := trig_text(c)
	return t + ("\n" + tt if tt != "" else "")


static var _strip: Array = []
static func brief_src(c: Dictionary) -> String:
	## Le texte français raccourci (avant traduction) : ce qu'il faut traduire tel quel (tools/i18n).
	if _strip.is_empty():
		for pat in ["(, puis )?[Ii]nflige \\{dmg\\}( (deux|trois|cinq) fois)?( à distance)?", "\\{dmg\\}( et|,)? ?",
				"(Gagne )?\\+?\\{block\\}( d'armure| armure)", "(Se soigne de|Soigne) \\{heal(_all)?\\}( un allié)?"]:
			var rx := RegEx.new()
			rx.compile(pat)
			_strip.append(rx)
	var t: String = c.text
	for rx: RegEx in _strip:
		t = rx.sub(t, "", true)
	for pair in [[" ,", ","], [" .", "."], [",.", "."], [", .", "."], ["..", "."], [": ,", ":"], ["  ", " "], [" :.", "."], [":.", "."], [" : .", "."], [" ;.", "."]]:
		t = t.replace(pair[0], pair[1])
	t = t.strip_edges()
	while t.begins_with(",") or t.begins_with(".") or t.begins_with(";") or t.begins_with("et ") or t.begins_with("+ "):
		t = t.substr(1 if not t.begins_with("et ") else 3).strip_edges()
	if t.begins_with("au Garde et aux alliés voisins"):
		t = "Aussi aux alliés voisins."
	t = t.replace("{poison} de poison", "+{poison} poison")
	return t


static func card_brief(c: Dictionary) -> String:
	## Texte de la carte sans ce que disent déjà les bulles des coins, traduit puis rempli.
	var t := fill(Lang.t(brief_src(c)), c)
	# majuscule en tête de chaque phrase
	var parts := t.split(". ")
	for i in parts.size():
		if parts[i].length() > 0:
			parts[i] = parts[i][0].to_upper() + parts[i].substr(1)
	t = ". ".join(parts)
	return "" if t == "." else t


static func keyword_tip(c: Dictionary) -> String:
	## Définitions des mots-clés présents sur la carte.
	var txt: String = card_text(c) + " " + KIND_WORD.get(c.kind, "")
	var out: Array = [card_text(c)]
	if c.has("trig"):
		out.append("%s : bonus %s." % [TRIGGERS[c.trig.on].name, TRIGGERS[c.trig.on].text])
	for kw in KEYWORDS:
		if txt.to_lower().contains(kw.to_lower()):
			out.append("%s : %s" % [kw, KEYWORDS[kw]])
	if c.has("tool"):
		out.insert(1, "Charges : " + KEYWORDS["Charges"])
		if c.get("legend", false):  # le niveau 3 est un secret : on n'en parle qu'une fois obtenu
			out.append("Légendaire : inépuisable, une fois par combat.")
		return "\n".join(out)
	if c.has("guild"):
		var gl: Array = Guildes.LIST[c.g]
		out.append("%s (%s + %s) : %s" % [gl[2], HEROES[gl[0]].name, HEROES[gl[1]].name, gl[3]])
	elif c.get("cb", false) and HEROES.has(c.cls[0]):
		out.append("Carte de %s, embauchée par %s pour ce combat." % [HEROES[c.cls[0]].name, HEROES[c.owner].name])
	elif c.cls[0] != c.owner and HEROES.has(c.cls[0]):
		out.append("Carte de %s, jouée par %s grâce à sa vocation." % [HEROES[c.cls[0]].name, HEROES[c.owner].name])
	out.append("%s · niveau %d / %d : %s" % [RARITY_NAME[int(c.get("rar", 1))], c.lvl, MAX_LVL, KEYWORDS["Niveau"]])
	return "\n".join(out)

const KIND_WORD := {"power": "Pouvoir"}


static var _kwx := {}
static func keywords_in(txt: String) -> Array:
	## Les mots-clés d'un texte libre (carte, relique, équipement) en encarts {icon, title, text}.
	var out: Array = []
	for kw in KEYWORDS:
		if kw in ["Niveau", "Charges"]:
			continue
		if not _kwx.has(kw):
			_kwx[kw] = RegEx.create_from_string("(?i)(?<![A-Za-zÀ-ÿ])" + kw + "(?![A-Za-zÀ-ÿ])")
		if (_kwx[kw] as RegEx).search(txt):
			out.append({"icon": KW_ICON.get(kw, KW_ICON.get(kw.to_lower(), "niveau")), "title": kw[0].to_upper() + kw.substr(1), "text": KEYWORDS[kw]})
	return out


static func keyword_list(c: Dictionary) -> Array:
	## Les encarts du survol (façon cartes à collectionner) : un pictogramme, un titre, une phrase. {icon, title, text}
	var out: Array = []
	var ic := func(k: String) -> String:
		for v in [k, k.to_lower(), k.capitalize()]:
			if KW_ICON.has(v):
				return KW_ICON[v]
		return "niveau"
	if c.has("tool"):
		out.append({"icon": "fabrique", "title": "Objet", "text": "Gratuit, et il reste en main d'un tour à l'autre. Joué, il perd une charge ; à zéro, il quitte le paquet."})
		if c.get("legend", false):
			out.append({"icon": "niveau", "title": "Légendaire", "text": "Inépuisable : une fois par combat, effet nettement plus fort."})
	out.append_array(keywords_in(card_text(c) + " " + KIND_WORD.get(c.kind, "")))
	if c.has("trig"):
		var tr: Dictionary = TRIGGERS[c.trig.on]
		out.append({"icon": ic.call(tr.name), "title": tr.name, "text": "Bonus " + tr.text + "."})
	if c.has("ench") and ENCHANTS.has(c.ench):
		out.append({"icon": "niveau", "title": "✦ Enchantée : " + ENCHANTS[c.ench].name, "text": ENCHANTS[c.ench].desc + " Enchantement gagné en défi ou en événement : il reste à tous les niveaux de la carte."})
	if c.has("guild"):
		var gl: Array = Guildes.LIST[c.g]
		out.append({"icon": "guild_%d" % c.g, "title": gl[2], "text": "%s + %s : %s" % [HEROES[gl[0]].name, HEROES[gl[1]].name, gl[3]]})
	elif not c.has("tool") and not c.get("cb", false) and c.cls[0] != c.owner and HEROES.has(c.owner) and HEROES.has(c.cls[0]):
		out.append({"icon": "vocation_" + c.cls[0], "title": "Vocation", "text": "Jouable par %s, qui a la vocation %s." % [HEROES[c.owner].name, HEROES[c.cls[0]].name]})
	return out
