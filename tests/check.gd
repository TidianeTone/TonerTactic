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
	# multiclasse : 28 guildes de 11 cartes
	for g in Guildes.LIST.size():
		var n := [0, 0, 0, 0, 0]
		for id in Guildes.cards_of(g):
			n[Guildes.CARDS[id].rar] += 1
		if n != [0, 2, 3, 5, 1]:  # 6 d'origine + 5 du 25/09 (1 commune, 2 peu communes, 2 rares)
			print("guilde incomplète : ", Guildes.LIST[g][2], " ", n)
			fails += 1
	if Guildes.index("lame", "garde") != 0 or Guildes.index("receleur", "tidiane") != 27:
		print("index de guilde faux")
		fails += 1
	var b := Board.new()
	var racks := 0
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
			if nr > 1:
				print("plusieurs râteliers seed ", s)
				fails += 1
	if racks < 30 or racks > 180:  # ~17 % des 600 arènes
		print("râteliers : ", racks, " sur 600 arènes")
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
	print("OK" if fails == 0 else "ÉCHECS : %d" % fails)
	quit(1 if fails else 0)
