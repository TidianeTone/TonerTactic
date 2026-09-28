extends SceneTree
## Vérif logique sans rendu : godot --headless --path . --script res://tests/check.gd

func _init() -> void:
	var fails := 0
	# chaque script doit compiler (une erreur de typage bloque le jeu entier)
	for path in ["res://scripts/main.gd", "res://scripts/battle.gd", "res://scripts/ui.gd", "res://scripts/unit.gd", "res://scripts/fx.gd"]:
		var sc: GDScript = load(path)
		if sc == null or not sc.can_instantiate():
			print("ne compile pas : ", path)
			fails += 1
	for k in Data.STARTER:
		assert(Data.HEROES.has(k), k)
		for id in Data.STARTER[k]:
			assert(Data.CARDS.has(id), id)
	for id in Data.all_ids():
		for lv in [1, 2, 3]:
			var c := Data.card({"id": id, "lvl": lv})
			if Data.card_text(c).contains("{"):
				print("texte non résolu : ", id, " niveau ", lv)
				fails += 1
			if not Data.HEROES.has(c.owner) and not c.has("tool"):
				print("propriétaire inconnu : ", id)
				fails += 1
			if c.has("trig") and not Data.TRIGGERS.has(c.trig.on):
				print("déclencheur inconnu : ", id)
				fails += 1
		if Data.upgrade_diff({"id": id, "lvl": 1}, {"id": id, "lvl": 2}) == "" or Data.upgrade_diff({"id": id, "lvl": 2}, {"id": id, "lvl": 3}) == "":
			print("palier vide : ", id)
			fails += 1
		if id.contains("2_") and not ResourceLoader.exists("res://assets/art/card_%s.png" % id):
			print("illustration manquante : ", id)
			fails += 1
	# jetons : jamais tirés comme cartes normales, texte résolu ; toute carte créée (gives) existe
	for id in Data.TOKENS:
		if Data.all_ids().has(id) or Data.card({"id": id}).owner == "":
			print("jeton mal rangé : ", id)
			fails += 1
	for id in Data.all_ids() + Data.TOKENS.keys():
		for lv in [1, 2, 3]:
			var c := Data.card({"id": id, "lvl": lv})
			if Data.card_text(c).contains("{"):
				print("texte non résolu : ", id, " niveau ", lv)
				fails += 1
			if c.has("gives") and not (Data.CARDS.has(c.gives.id) or Data.TOKENS.has(c.gives.id) or Guildes.CARDS.has(c.gives.id)):
				print("carte créée inconnue : ", id, " -> ", c.gives.id)
				fails += 1
			if c.has("place") and not (c.place in ["piege", "mine", "epieu", "ombre", "collet"] or Data.PROPS.has(c.place)):
				print("pose inconnue : ", id, " ", c.place)
				fails += 1
	# multiclasse : 28 guildes de 14 cartes
	for g in Guildes.LIST.size():
		var n := [0, 0, 0, 0, 0]
		for id in Guildes.cards_of(g):
			n[Guildes.CARDS[id].rar] += 1
		if n != [0, 4, 5, 7, 1]:  # 6 d'origine + 5 du 25/09 + 3 du 27/09 + 3 du 27/09 bis (une de chaque rareté)
			print("guilde incomplète : ", Guildes.LIST[g][2], " ", n)
			fails += 1
	if Guildes.index("lame", "garde") != 0 or Guildes.index("receleur", "tidiane") != 27:
		print("index de guilde faux")
		fails += 1
	var b := Board.new()
	var racks := 0
	var specials := 0
	for s in 200:
		for bi in 3:
			b.generate(s * 31 + bi, Data.BIOMES[bi], [12, 14, 16, 18][s % 4], Board.ARCHETYPES[s % 4])
			if not b._connected():
				print("non connexe seed ", s)
				fails += 1
			var hs := b.spawn_cells("hero", 3)
			var fs := b.spawn_cells("foe", 5, hs)
			if hs.size() < 3 or fs.size() < 5:
				print("spawns manquants seed ", s)
				fails += 1
			for c in hs:
				if fs.has(c):
					print("spawn partagé seed ", s)
					fails += 1
			var nr := b.props.values().count("ratelier")
			racks += nr
			var nsp: int = nr + b.props.values().count("vasque") + b.props.values().count("cloche")
			specials += nsp
			if nsp > 1:
				print("plusieurs objets spéciaux seed ", s)
				fails += 1
	if racks < 30 or racks > 160 or specials < 120 or specials > 330:  # ~15 % et ~37 % des 600 arènes (12+)
		print("râteliers : ", racks, ", objets spéciaux : ", specials, " sur 600 arènes")
		fails += 1
	# mode tactique : le damier est toujours connexe et symétrique par le centre
	for s2 in 300:
		b.generate(s2 * 17, Data.BIOMES[s2 % 3], 12 + 2 * (s2 % 2), "damier")
		if not b._connected():
			print("damier non connexe ", s2)
			fails += 1
		for x in b.dim:
			for z in b.dim:
				var c1 := Vector2i(x, z)
				if b.kind[c1] != b.kind[Vector2i(b.dim - 1 - x, b.dim - 1 - z)] and not b.blocked.has(c1):
					print("damier asymétrique ", s2)
					fails += 1
	b.free()
	# enchantements : chaque carte enchantable garde un texte résolu ; jamais sur une carte-objet
	var n_en := 0
	for id in Data.all_ids():
		for en in Data.ENCHANTS:
			if Data.ench_ok({"id": id, "lvl": 1}, en):
				n_en += 1
				var c := Data.card({"id": id, "lvl": 3, "ench": en})
				if Data.card_text(c).contains("{") or c.has("tool"):
					print("enchantement : ", id, " ", en)
					fails += 1
	if n_en < 200:
		print("trop peu de cartes enchantables : ", n_en)
		fails += 1
	# reliques : un palier valide, un glyphe ; le filtre de pertinence tourne sur une run neuve
	for r in Data.RELICS:
		if not Data.RELIC_TIERS.has(Data.RELICS[r].get("tier", "")) or Data.RELICS[r].get("glyph", "") == "":
			print("relique sans palier ou glyphe : ", r)
			fails += 1
	var m: Node = load("res://scripts/main.gd").new()
	m.floor_biomes = [5, 0, 2]
	m.deck = Data.starter(["garde", "lame", "oracle"])
	for r in Data.RELICS:
		m._relic_useful(r)
	if not m._relic_useful("givre_etrave") or m._relic_useful("diapason") or m._relic_useful("collier") or not m._relic_useful("sifflet"):
		print("filtre de pertinence faux")
		fails += 1
	m.relics = ["cle_ecluse"]
	if m._relic_ok("remous") or m._relic_ok("cle_ecluse"):
		print("exclusions de reliques fausses")
		fails += 1
	# initiation : chaque étape jouable telle qu'écrite (carte en main, case dans l'arène, un ennemi par place)
	for ch in m.TUTO:
		var hand: Array = []
		for st in ch.get("steps", []):
			hand = st.get("hand", hand)
			if not st.do in ["move", "play", "prop", "ok", "face", "end"] or (st.do == "play" and not (Data.CARDS.has(st.card) and hand.has(st.card))) \
				or (st.get("at") is Vector2i and (st.at.x < 0 or st.at.y < 0 or st.at.x > 9 or st.at.y > 9)) or st.say.length() > 110:
				print("initiation : étape fausse ", ch.name, " ", st)
				fails += 1
		if ch.has("foes") and ch.heroes.size() != ch.party.size():
			print("initiation : héros sans case ", ch.name)
			fails += 1
	m.free()
	# anglais : correspondance exacte, recollage de phrases voisines, chemins d'image intacts
	var L := Lang.new()
	L.load_dict("res://assets/i18n/en.json")
	for pair in [["Fin du tour", "End turn"], ["[img=15x15]res://assets/ui/kw_dos.png[/img]", "[img=15x15]res://assets/ui/kw_dos.png[/img]"]]:
		var got := String(L._get_message(pair[0], ""))
		if got != pair[1]:
			print("traduction : ", pair[0], " -> ", got)
			fails += 1
	var mix := String(L._get_message("Survolez pour lire l'effet · un objet du sac, puis un héros · clic", ""))
	if not mix.begins_with("Hover to read the effect · an item from the bag, then a hero"):
		print("recollage : ", mix)
		fails += 1
	# équipement (concile du 28/09) : propriétaire, passifs, icône ; une pièce de métier seulement pour sa classe
	for id in Data.ITEMS:
		var it: Dictionary = Data.ITEMS[id]
		if not (it.owner == "any" or Data.HEROES.has(it.owner)) or not Data.SLOTS.has(it.slot) or not ResourceLoader.exists(Data.item_icon(id)):
			print("pièce fausse : ", id)
			fails += 1
		for k in ["passive", "passive2"]:
			if it.get(k, "") != "" and not Data.PASSIVES.has(it[k]):
				print("passif inconnu : ", id, " ", it[k])
				fails += 1
		if it.owner != "any" and (Data.item_fits(id, "garde" if it.owner != "garde" else "lame") or not Data.item_fits(id, it.owner)):
			print("verrou de métier faux : ", id)
			fails += 1
	# départ multiclasse : pour chaque paire, 7 cartes, 4 de départ (graine gardée), 2 de la guilde, 1 de la classe apprise
	var mr := RandomNumberGenerator.new()
	for k in Data.HEROES:
		for v in Data.HEROES:
			if k == v:
				continue
			var md: Array = Data.multi_starter(k, v, mr)
			var st: Array = md.filter(func(ci): return ci.get("st", false))
			var gc: Array = md.filter(func(ci): return Guildes.CARDS.has(ci.id) and Guildes.CARDS[ci.id].g == Guildes.index(k, v))
			var vc: Array = md.filter(func(ci): return Data.CARDS.has(ci.id) and Data.CARDS[ci.id].owner == v)
			var seeds: Array = Data.STARTER[k].filter(func(id): return id.begins_with("c_"))
			if md.size() != 7 or st.size() != 4 or gc.size() != 2 or vc.size() != 1 or md.any(func(ci): return not ci.get("st", false) and ci.get("h", "") != k) 					or seeds.any(func(id): return not st.any(func(ci): return ci.id == id)):
				print("paquet multiclasse faux : ", k, "+", v, " ", md.map(func(ci): return ci.id))
				fails += 1
	print("OK" if fails == 0 else "ÉCHECS : %d" % fails)
	quit(1 if fails else 0)
