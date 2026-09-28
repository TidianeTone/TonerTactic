extends SceneTree
## Textes de cartes raccourcis (Data.brief_src), tous niveaux : ils ne sont pas des littéraux du code,
## extract.py ne les voit pas. godot --headless --script res://tools/i18n/briefs.gd -> tools/i18n/briefs.json


func _init() -> void:
	var out := {}
	for id in Data.all_ids():
		for lv in [1, 2, 3]:
			var d := Data.def(id)
			var who: String = d.get("owner", Guildes.pair(d.g)[0] if d.has("g") else "garde")
			var t := Data.brief_src(Data.card({"id": id, "lvl": lv, "h": who}))
			if t != "" and t != ".":
				out[t] = true
	var f := FileAccess.open("res://tools/i18n/briefs.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out.keys(), "\t"))
	print(out.size(), " textes raccourcis")
	quit()
