extends SceneTree
## Exporte toutes les données du jeu en JSON pour le guide officiel (cartes aux 3 niveaux, objets, ennemis...).
func _col(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		var v = d[k]
		o[k] = v.to_html(false) if v is Color else v
	return o

func _init() -> void:
	var cards := []
	for id in Data.all_ids():
		var d: Dictionary = Data.def(id)
		var h: String = Data.classes_of(id)[0]
		var lv := []
		for L in [1, 2, 3]:
			var c := Data.card({"id": id, "lvl": L, "h": h})
			lv.append({"text": Data.card_text(c), "cost": c.cost, "name": c.name})
		cards.append({"id": id, "name": d.name, "cls": Data.classes_of(id), "rar": d.get("rar", 1), "kind": d.kind,
			"range": d.get("range", []), "target": d.get("target", "foe"), "lv": lv, "starter": Data.STARTER.get(h, []).has(id), "arch": d.get("arch", "")})
	var items := {}
	for id in Data.ITEMS:
		items[id] = {"name": Data.ITEMS[id].name, "slot": Data.ITEMS[id].slot, "owner": Data.ITEMS[id].owner, "rarity": Data.ITEMS[id].rarity,
			"text": Data.item_text(id), "icon": Data.ITEM_ICON.get(id, "anneau")}
	var foes := {}
	for id in Data.FOES:
		foes[id] = Data.FOES[id].duplicate()
		foes[id]["tip"] = Data.FOE_TIPS.get(id, "")
	var heroes := {}
	for k in Data.HEROES:
		heroes[k] = Data.HEROES[k].duplicate()
		heroes[k]["color"] = Data.CLASS_COLOR[k].to_html(false)
		heroes[k]["starter"] = Data.STARTER[k]
	var tiles := {}
	for k in Data.TILES:
		tiles[k] = _col(Data.TILES[k])
	var ancients := {}
	for k in Data.ANCIENTS:
		ancients[k] = _col(Data.ANCIENTS[k])
	var guilds := []
	for i in Guildes.LIST.size():
		guilds.append(Guildes.LIST[i] + [Guildes.DESC[i]])  # [a, b, nom, règle, inspiration, paragraphe]
	var out := {"cards": cards, "items": items, "foes": foes, "heroes": heroes, "tiles": tiles, "tools": Data.TOOLS, "relics": Data.RELICS,
		"passives": Data.PASSIVES, "traits": Data.TRAITS, "triggers": Data.TRIGGERS, "keywords": Data.KEYWORDS, "pacts": Data.PACTS,
		"modifiers": Data.MODIFIERS, "affixes": Data.AFFIXES, "ancients": ancients, "boons": Data.BOONS, "guilds": guilds,
		"difficulty": Data.DIFFICULTY, "mastery": Data.MASTERY, "biomes": Data.BIOMES.map(func(b): return b.name),
		"archetypes": Data.ARCHETYPES, "companions": Data.COMPANIONS,
		"new_guild_cards": Guildes.CARDS.keys().filter(func(id): return Guildes.CARDS[id].has("arch")),
		"encounters": Data.ENCOUNTERS, "elites": Data.ELITES, "boss": Data.BOSS, "price": Data.PRICE}
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	quit()
