class_name UI
extends CanvasLayer
## Interface : main de cartes, héros, énergie, étiquettes au-dessus des unités, écrans de choix.

signal picked(i: int)
signal lib_closed

const INK := Color("#efe6d2")
const DIM := Color("#a79d8b")
const GOLD := Color("#e3b45c")
const CARD_BASE := Vector2(196, 272)  # proportions des cadres KIE, telles que peintes
const CARD_EXTRA := 48.0  # la bande du texte s'allonge d'autant : la carte respire
const CARD := Vector2(196, 272 + 48)  # proportions des cadres KIE
var hand_k := 0.84  # échelle de la main au repos (survol : ×1,33) ; --handk= pour essayer
const KIND_NAME := {"atk": "Attaque", "skill": "Technique", "move": "Mouvement", "power": "Pouvoir"}
const ICON := {
	"frappe": "⚔", "pavois": "🛡", "charge": "➤", "defi": "⚑", "rempart": "✠", "marteau": "⚒", "bastion": "🛡",
	"estoc": "†", "ombre": "☾", "double": "⚔", "venin": "☠", "couperet": "⚔", "ricochet": "↯",
	"braise": "✺", "seve": "✚", "colonne": "✹", "maree": "≋", "surveil": "◉", "delve": "⛏", "lotus": "✿",
}

var main: Node3D
static var big := false     # mode portable : petits textes grossis, boutons tactiles
var touch_box: HBoxContainer
var dim_alpha := 0.62   # voile des écrans de choix ; plus léger dans les lieux de repos
var battle: Battle
var root: Control
var hud: Control
var hand_layer: Control
var header: Label
var sub: Label
var challenge_lbl: Label
var speaker := ""         # qui parle dans les écrans de choix (neutre, marchand, clé d'un Ancien) : sa boîte de dialogue, sinon une ligne dorée
var team_on := false       # écrans de choix hors combat (sanctuaire, Ancien) : les portraits de l'équipe ouvrent leur fiche   # défi du porteur de carte, tant qu'il court
var energy_lbl: Label
var bpm_lbl: Label
var pile_lbl: Label
var end_btn: Button
var tip: Label
var banner_box: VBoxContainer
var banner_title: Label
var banner_sub: Label
var toast_lbl: Label
var toast_plate: PanelContainer
var tip_plate: PanelContainer
var relic_row: HBoxContainer
var hero_box: VBoxContainer
var log_box: RichTextLabel
var gold_lbl: Label
var frieze: HBoxContainer
var boss_bar: VBoxContainer
var hero_panels := {}
var tags := {}
var tag_layer: Control
var overlay: Control
var title_f: Font
var wide_f: FontVariation
var body_f: Font
var _hand_sig := ""
var _cards: Array = []
var _hover_card := -1
var sheet_plate: PanelContainer
var sheet_title: Label
var sheet_body: RichTextLabel
var item_card: Control      # l'objet porté (ou au sol) montré en carte, sous la fiche
var _item_key := ""
var menu: Control
var lib_layer: Control     # bibliothèque : sa propre couche, ouvrable par-dessus un choix ou la pause
var _eq_act := {}          # action choisie sur l'écran d'équipement
var keys_plate: PanelContainer
var show_keys := 0          # H : 0 masquée, 1 affichée (sinon : au survol du bouton « Commandes »)
var _keys_hover := false
var tactic_btn: Button
var played_box: VBoxContainer
var orb_frame: TextureRect
var voc_badge: TextureRect
var voc_dot: Panel
var _orb_key := ""
var frieze_unit: Unit        # unité survolée (ou touchée) dans la frise d'initiative
# trou de chaque cadre d'orbe : centre x, centre y, largeur (fractions, blender/kie_ui/mesures.json)
const ORB_HOLE := {"garde": [0.499, 0.529, 0.52], "lame": [0.501, 0.463, 0.672], "oracle": [0.491, 0.545, 0.519], "artificier": [0.498, 0.591, 0.558],
	"moine": [0.498, 0.52, 0.526], "trappeur": [0.498, 0.562, 0.466], "tidiane": [0.501, 0.536, 0.474], "receleur": [0.503, 0.454, 0.65], "neutre": [0.502, 0.499, 0.779]}
var _played_sig := ""
var explore_box: VBoxContainer
var explore_title: Label
var explore_sub: Label
var explore_party: Label
var explore_heroes: VBoxContainer
var explore_panels := {}


func _ready() -> void:
	title_f = Fx.title_font()
	wide_f = FontVariation.new()
	wide_f.base_font = Fx.goth("newrocker")  # titres d'écran : gothique lisible
	wide_f.spacing_glyph = 8
	wide_f.fallbacks = Fx.goth("newrocker").fallbacks
	body_f = Fx.body_font()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font = body_f
	th.default_font_size = 18 if big else 15
	th.set_constant("line_spacing", "Label", -4)
	# infobulles lisibles : plaque sombre, texte clair et plus grand
	var tst := sb(Color(0.07, 0.065, 0.07, 0.96), GOLD.darkened(0.25), 8, 1, 8)
	tst.content_margin_left = 12
	tst.content_margin_right = 12
	tst.content_margin_top = 8
	tst.content_margin_bottom = 8
	th.set_stylebox("panel", "TooltipPanel", tst)
	th.set_font_size("font_size", "TooltipLabel", 16)
	th.set_color("font_color", "TooltipLabel", INK)
	root.theme = th
	add_child(root)
	tag_layer = _full(root)
	hud = _full(root)
	_build_hud()
	hand_layer = _full(hud)
	_build_banner()
	_build_explore()
	hud.visible = false
	if big:
		_build_touch()


func _toggle_danger() -> void:
	battle.danger = not battle.danger
	main.refresh_hover()


func _build_touch() -> void:
	## Mode portable : ce que font Échap, Q/E, clic droit et D, à portée de pouce sur le bord droit.
	touch_box = HBoxContainer.new()
	touch_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	touch_box.position = Vector2(-454, -290)  # au-dessus de « Fin du tour » et des boutons Caméra / Commandes
	touch_box.add_theme_constant_override("separation", 10)
	touch_box.z_index = 50
	root.add_child(touch_box)
	for e in [["☰", "Menu", func(): toggle_menu()], ["↺", "Tourner", func(): main.yaw -= 90.0], ["↻", "Tourner", func(): main.yaw += 90.0],
			["⤵", "Le héros se tourne d'un quart", func(): battle.turn_facing(1)], ["✕", "Annuler", func(): battle.cancel()],
			["⚠", "Danger", _toggle_danger]]:
		var b := Button.new()
		b.text = e[0]
		b.tooltip_text = e[1]
		b.add_theme_font_override("font", title_f)
		b.add_theme_font_size_override("font_size", 30)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.82), GOLD.darkened(0.3), 32, 2, 6))
		b.add_theme_stylebox_override("hover", sb(Color(0.08, 0.07, 0.075, 0.82), GOLD.darkened(0.3), 32, 2, 6))
		b.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.2), GOLD, 32, 2, 4))
		b.custom_minimum_size = Vector2(64, 64)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(e[2])
		touch_box.add_child(b)


# ------------------------------------------------------------------ helpers

func _full(parent: Control) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


static func sb(bg: Color, border := Color(0, 0, 0, 0), radius := 10, bw := 0, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 3)
	return s


func _label(text: String, size: int, col: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	if big and size <= 18:
		size += 3
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font:
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Zone sombre de chaque boîte de dialogue (fractions de l'image : x0, y0, x1, y1), mesurée par blender/kie_ui/cut_boites.py
const BOITES := {"neutre": [0.06, 0.15, 0.94, 0.89], "marchand": [0.03, 0.19, 0.93, 0.86], "anatheme": [0.07, 0.14, 0.97, 0.93],
	"chineuse": [0.1, 0.17, 0.95, 0.73], "dojo": [0.04, 0.13, 0.94, 0.89], "sourcier": [0.05, 0.18, 0.96, 0.94]}


func _bar_frame(bar: Control, path: String, iy0: float, iy1: float, capl: int, capr: int) -> void:
	## Cadre peint autour d'une barre de vie : deux embouts à l'échelle, le tube étiré entre eux (le milieu de la texture est uniforme).
	var tex: Texture2D = load(path)
	var bs: Vector2 = bar.size if bar.size.x > 0 else bar.custom_minimum_size
	var tw := tex.get_width()
	var th := tex.get_height()
	var k: float = bs.y / ((iy1 - iy0) * th)
	var fr := Control.new()
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.position = Vector2(-capl * k, -iy0 * th * k)
	for part in [[0, capl, 0.0, capl * k], [capl, tw - capl - capr, capl * k, bs.x], [tw - capr, capr, capl * k + bs.x, capr * k]]:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(part[0], 0, part[1], th)
		var r := TextureRect.new()
		r.texture = at
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.position = Vector2(part[2], 0)
		r.size = Vector2(part[3], th * k)
		fr.add_child(r)
	bar.add_child(fr)


func _speech(text: String, who := "neutre") -> Control:
	## La réplique dans la boîte de celui qui parle : chaque locuteur a son cadre (neutre = information du jeu, marchand, chaque Ancien).
	var tex: Texture2D = load("res://assets/ui/boite_%s.png" % who)
	var inr: Array = BOITES.get(who, [0.06, 0.15, 0.94, 0.88])
	var asp := float(tex.get_width()) / tex.get_height()
	var tall := 140.0 if text.length() < 90 else 200.0  # une ligne : une boîte plus basse
	var h := minf(tall if not big else tall * 0.9, minf(700.0, root.size.x * 0.46) / asp)
	var w := h * asp
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(w, h)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tr)
	var pad := h * 0.07
	var l := _label(text, 18, INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(inr[0] * w + pad, inr[1] * h + pad)
	l.size = Vector2((inr[2] - inr[0]) * w - 2 * pad, (inr[3] - inr[1]) * h - 2 * pad)
	l.clip_text = false
	holder.add_child(l)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(holder)
	holder.pivot_offset = Vector2(w, h) * 0.5
	holder.scale = Vector2(0.96, 0.96)
	holder.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(holder, "modulate:a", 1.0, 0.25)
	tw.tween_property(holder, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return cc


# Lettrage des titres d'écran : l'alphabet peint dans le style du logo (Higgsfield, tools/lettres.py -> assets/ui/lettres.png).
# glyphe -> [x, y, largeur, hauteur, ligne de base] dans l'atlas
const LETTRES := {"A": [0, 0, 74, 74, 74], "B": [76, 0, 61, 74, 74], "C": [139, 0, 61, 74, 74], "D": [202, 0, 63, 74, 74], "E": [267, 0, 55, 73, 73], "F": [324, 0, 56, 74, 74], "G": [382, 0, 66, 73, 73], "H": [450, 0, 66, 73, 73], "I": [518, 0, 37, 75, 75], "J": [557, 0, 58, 74, 74], "K": [617, 0, 64, 74, 74], "L": [683, 0, 53, 74, 74], "M": [738, 0, 77, 74, 74], "N": [817, 0, 66, 74, 74], "O": [885, 0, 66, 74, 74], "P": [953, 0, 61, 75, 75], "Q": [1016, 0, 70, 79, 74], "R": [1088, 0, 64, 74, 74], "S": [1154, 0, 56, 74, 74], "T": [1212, 0, 64, 74, 74], "U": [1278, 0, 65, 73, 73], "V": [1345, 0, 67, 73, 73], "W": [1414, 0, 86, 73, 73], "X": [1502, 0, 67, 73, 73], "Y": [1571, 0, 72, 73, 73], "Z": [1645, 0, 58, 73, 73], "É": [1705, 0, 55, 92, 92], "È": [1762, 0, 56, 90, 90], "Ê": [1820, 0, 55, 90, 90], "À": [1877, 0, 70, 90, 90], "Ç": [1949, 0, 59, 88, 74], "Ô": [2010, 0, 64, 90, 90], "Û": [2076, 0, 64, 89, 89], "Î": [2142, 0, 40, 89, 89], "Ù": [2184, 0, 64, 89, 89], "Ë": [2250, 0, 54, 89, 89], "'": [2306, 0, 31, 41, 74], "-": [2339, 0, 42, 28, 51], "!": [2383, 0, 32, 79, 79], "?": [2417, 0, 54, 80, 80], "0": [2473, 0, 60, 76, 76], "1": [2535, 0, 46, 75, 75], "2": [2583, 0, 56, 76, 76], "3": [2641, 0, 58, 76, 76], "4": [2701, 0, 59, 75, 75], "5": [2762, 0, 57, 75, 75], "6": [2821, 0, 57, 75, 75], "7": [2880, 0, 55, 75, 75], "8": [2937, 0, 58, 76, 76], "9": [2997, 0, 58, 75, 75], "·": [3057, 0, 30, 33, 53], ":": [3089, 0, 29, 59, 59], ",": [3120, 0, 28, 41, 20], ".": [3150, 0, 30, 33, 33], "&": [3182, 0, 66, 74, 74], "/": [3250, 0, 52, 75, 75]}
static var _lettres_tex: Texture2D


func _title(text: String, size: int) -> Label:
	## Un titre d'écran : le Label garde la mise en page (texte transparent), le mot peint est posé par-dessus.
	var l := _label(text, size, Color(0, 0, 0, 0))
	l.set_meta("tsize", size)
	_paint_title(l)
	return l


func _paint_title(l: Label) -> void:
	for c in l.get_children():
		if c.has_meta("word"):
			c.queue_free()
	if _lettres_tex == null:
		_lettres_tex = load("res://assets/ui/lettres.png")
	var k: float = float(l.get_meta("tsize")) * 0.9 / 74.0
	var asc := 0
	var desc := 0
	var txt: String = l.text.to_upper()
	for ch in txt:
		if LETTRES.has(ch):
			asc = maxi(asc, LETTRES[ch][4])
			desc = maxi(desc, LETTRES[ch][3] - LETTRES[ch][4])
	var word := Control.new()
	word.set_meta("word", true)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 0.0
	for ch in txt:
		if not LETTRES.has(ch):
			x += 26.0 * k  # espace, ou un signe absent de l'alphabet peint
			continue
		var g: Array = LETTRES[ch]
		var at := AtlasTexture.new()
		at.atlas = _lettres_tex
		at.region = Rect2(g[0], g[1], g[2], g[3])
		var tr := TextureRect.new()
		tr.texture = at
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(x, (asc - g[4]) * k)
		tr.size = Vector2(g[2], g[3]) * k
		word.add_child(tr)
		x += (g[2] - 4) * k  # les contours se touchent, comme dans le logo
	var sz := Vector2(x, (asc + desc) * k)
	word.set_anchors_preset(Control.PRESET_CENTER)
	word.offset_left = -sz.x / 2
	word.offset_right = sz.x / 2
	word.offset_top = -sz.y / 2
	word.offset_bottom = sz.y / 2
	l.custom_minimum_size = Vector2(0, sz.y)
	l.add_child(word)


static var _bars := {}


func _bar_style(on: bool) -> StyleBoxTexture:
	## Barre de menu peinte (Higgsfield) : cuir entre deux pointes, acier au repos, or au survol. Les pointes ne s'étirent pas.
	if not _bars.has(on):
		var st := StyleBoxTexture.new()
		st.texture = load("res://assets/ui/barre_menu_on.png" if on else "res://assets/ui/barre_menu.png")
		st.texture_margin_left = 62 if on else 52
		st.texture_margin_right = 62 if on else 52
		st.content_margin_left = 44
		st.content_margin_right = 40
		st.content_margin_top = 4
		st.content_margin_bottom = 4
		_bars[on] = st
	return _bars[on]


func _bar_button(text: String, icon_name := "", w := 380.0, h := 58.0, fs := 22) -> Button:
	var b := Button.new()
	b.text = text
	if icon_name != "" and ResourceLoader.exists("res://assets/ui/%s.png" % icon_name):
		b.icon = load("res://assets/ui/%s.png" % icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(h * 0.72))
		b.add_theme_constant_override("h_separation", 12)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", title_f)
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color("#ffe3a3"))
	b.add_theme_color_override("font_focus_color", Color("#ffe3a3"))
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_stylebox_override("normal", _bar_style(false))
	for k in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(k, _bar_style(true))
	return b


func _shadowed(l: Label, outline := 6) -> Label:
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.03, 0.85))
	return l


func _panel(parent: Control, style: StyleBox) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", style)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	var head := VBoxContainer.new()
	head.position = Vector2(28, 20)
	head.add_theme_constant_override("separation", 0)
	hud.add_child(head)
	header = _shadowed(_label("", 30, INK, title_f), 8)
	sub = _shadowed(_label("", 14, GOLD), 5)
	head.add_child(header)
	head.add_child(sub)
	# le défi du porteur : en haut au centre, sous la frise d'initiative (à gauche il mordait sur les fiches)
	challenge_lbl = _shadowed(_label("", 17, Color("#ffd27a")), 5)
	challenge_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	challenge_lbl.size = Vector2(900, 26)
	challenge_lbl.position = Vector2(-450, 84)
	challenge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(challenge_lbl)

	gold_lbl = _shadowed(_label("", 20, Color("#ffd27a"), title_f), 6)
	gold_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gold_lbl.position = Vector2(-200, 70)
	gold_lbl.size = Vector2(172, 26)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(gold_lbl)

	relic_row = HBoxContainer.new()
	relic_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	relic_row.position = Vector2(-28, 24)
	relic_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	relic_row.add_theme_constant_override("separation", 6)
	hud.add_child(relic_row)

	hero_box = VBoxContainer.new()
	hero_box.position = Vector2(24, 110)
	hero_box.add_theme_constant_override("separation", 10)
	hud.add_child(hero_box)
	# journal du combat : les derniers événements, sous les fiches (L pour masquer)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = false
	log_box.scroll_active = false
	log_box.position = Vector2(26, 450)
	log_box.size = Vector2(300, 190)
	log_box.add_theme_font_size_override("normal_font_size", 12)
	log_box.add_theme_color_override("default_color", Color(0.93, 0.88, 0.8, 0.92))
	log_box.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	log_box.add_theme_constant_override("shadow_offset_x", 1)
	log_box.add_theme_constant_override("shadow_offset_y", 1)
	log_box.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_box.visible = false  # replié : bouton « Journal » ou touche L
	hud.add_child(log_box)

	# énergie
	var orb := Panel.new()
	orb.add_theme_stylebox_override("panel", _orb_style())
	orb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	orb.position = Vector2(40, -160)
	orb.size = Vector2(104, 104)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(orb)
	# cadre peint de la classe du héros actif, et médaillon de sa vocation
	orb_frame = TextureRect.new()
	orb_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb.add_child(orb_frame)
	voc_badge = TextureRect.new()
	voc_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	voc_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	voc_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voc_badge.size = Vector2(62, 62)
	voc_badge.position = Vector2(84, -34)
	orb.add_child(voc_badge)
	voc_dot = _panel(voc_badge, sb(Color.WHITE, Color(0, 0, 0, 0.5), 14, 1))
	voc_dot.size = Vector2(26, 26)
	voc_dot.position = Vector2(18, 18)
	voc_dot.show_behind_parent = true
	energy_lbl = _shadowed(_label("3", 44, Color("#2a1606"), title_f), 0)
	energy_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(energy_lbl)
	# BPM de Tidiane (et de ceux qui l'ont en vocation) : à droite de l'anneau de mana
	bpm_lbl = _shadowed(_label("", 22, Color("#f06fb0"), title_f), 6)
	bpm_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bpm_lbl.position = Vector2(152, -118)
	bpm_lbl.size = Vector2(150, 30)
	bpm_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	bpm_lbl.tooltip_text = "BPM : chaque carte jouée le monte de 1 (12 au plus). Les cartes Drop le dépensent d'un coup."
	bpm_lbl.visible = false
	hud.add_child(bpm_lbl)
	pile_lbl = _shadowed(_label("", 15, INK), 6)
	pile_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pile_lbl.position = Vector2(24, -24)
	pile_lbl.size = Vector2(160, 20)
	pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(pile_lbl)
	var pb := Button.new()
	pb.flat = true
	pb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pb.position = Vector2(24, -26)
	pb.size = Vector2(160, 24)
	pb.focus_mode = Control.FOCUS_NONE
	pb.tooltip_text = "Voir la pioche · P : tout le paquet"
	pb.pressed.connect(func(): main.view_deck("pioche"))
	hud.add_child(pb)
	# cartes jouées ce tour : la dernière arrive à droite ; clic = toute la défausse
	# pouvoirs actifs en pastilles, puis défausse et journal repliés derrière deux boutons
	played_box = VBoxContainer.new()
	played_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	played_box.offset_left = 204
	played_box.offset_top = -40
	played_box.offset_bottom = -40
	played_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	played_box.add_theme_constant_override("separation", 6)
	hud.add_child(played_box)

	end_btn = Button.new()
	end_btn.text = "Fin du tour"
	end_btn.add_theme_font_override("font", title_f)
	end_btn.add_theme_font_size_override("font_size", 22)
	end_btn.add_theme_color_override("font_color", Color("#2a1606"))
	end_btn.add_theme_color_override("font_hover_color", Color("#1a0d02"))
	end_btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.2))
	end_btn.add_theme_stylebox_override("normal", sb(GOLD, Color("#fff0c8"), 12, 2, 8))
	end_btn.add_theme_stylebox_override("hover", sb(GOLD.lightened(0.18), Color("#fff6dc"), 12, 2, 10))
	end_btn.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.15), Color("#fff0c8"), 12, 2, 4))
	end_btn.add_theme_stylebox_override("disabled", sb(Color(0.35, 0.3, 0.25, 0.8), Color(0.5, 0.45, 0.4), 12, 2, 0))
	end_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	end_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	end_btn.position = Vector2(-230, -118)
	end_btn.size = Vector2(190, 58)
	end_btn.pressed.connect(func(): battle.end_turn())
	end_btn.focus_mode = Control.FOCUS_NONE
	hud.add_child(end_btn)
	# raccourcis au-dessus de Fin du tour : caméra par défaut, musique
	var quick := HBoxContainer.new()
	quick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	quick.position = Vector2(-330, -214)
	quick.size = Vector2(290, 42)
	quick.alignment = BoxContainer.ALIGNMENT_END
	quick.add_theme_constant_override("separation", 10)
	hud.add_child(quick)
	for q in [["⟲  Caméra", "Revenir à la vue par défaut (Tab : recentrer sur le héros)", func(): main.reset_camera()], ["♪", "Couper ou remettre la musique (M)", func(): main.toggle_mute()]]:
		var qb := Button.new()
		qb.text = q[0]
		qb.tooltip_text = q[1]
		qb.focus_mode = Control.FOCUS_NONE
		qb.add_theme_font_override("font", title_f)
		qb.add_theme_font_size_override("font_size", 16)
		qb.add_theme_color_override("font_color", INK)
		qb.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.9), GOLD.darkened(0.3), 10, 1, 6))
		qb.add_theme_stylebox_override("hover", sb(Color(0.18, 0.15, 0.1, 0.95), GOLD, 10, 1, 6))
		qb.custom_minimum_size = Vector2(0, 38)
		qb.pressed.connect(q[2])
		quick.add_child(qb)
	# juste sous la caméra : l'aide des commandes (au survol) et la vue tactique (son état reste visible)
	var quick2 := HBoxContainer.new()
	quick2.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	quick2.position = Vector2(-330, -170)
	quick2.size = Vector2(290, 42)
	quick2.alignment = BoxContainer.ALIGNMENT_END
	quick2.add_theme_constant_override("separation", 10)
	hud.add_child(quick2)
	var kb := _quick_btn("?  Commandes", "Les touches (survol)", func(): show_keys = 0 if show_keys == 1 else 1)
	kb.mouse_entered.connect(func():
		_keys_hover = true
		keys_plate.visible = not big)
	kb.mouse_exited.connect(func():
		_keys_hover = false
		keys_plate.visible = show_keys == 1 and not big)
	quick2.add_child(kb)
	tactic_btn = _quick_btn("◧", "Vue tactique (T) : un affichage épuré du combat", func(): main.set_tactic(not main.tactic))
	quick2.add_child(tactic_btn)
	var hint := _shadowed(_label("Espace", 12, DIM))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-230, -54)
	hint.size = Vector2(190, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hint)

	# aide des commandes : une touche, une action, lisible d'un coup d'œil
	var keys := _plate(hud)
	keys_plate = keys
	keys.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	keys.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_left = -40
	keys.offset_top = -262
	keys.offset_right = -40
	keys.offset_bottom = -262  # au-dessus des boutons Caméra / Commandes
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 6)
	kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.add_child(kv)
	kv.add_child(_shadowed(_label("Commandes", 16, GOLD, title_f), 4))
	kv.add_child(_label("Chacun joue à son tour, par vitesse, avec son paquet et son mana.", 13, Color("#ffd98a")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kv.add_child(grid)
	for row in [["Clic · reclic", "viser une case · y aller"], ["Clic ennemi", "épingler / retirer sa fiche"], ["Course", "déjà marché ? cases orange : 3 mana"],
			["Survol", "infos de la case ou de l'objet"], ["Clic droit", "annuler, sinon se tourner · maintenu : caméra"],
			["ZQSD", "déplacer la caméra (clic droit tenu)"], ["Q / E · molette", "pivoter · zoomer"],
			["Espace · ← →", "fin du tour · se tourner"], ["D · L", "zone de danger · journal"], ["Tab · 1 à 9", "recentrer · jouer une carte"],
			["Alt", "montrer les objets interactifs"], ["P · M · T", "paquet · musique · vue tactique"], ["H · Échap", "cette aide · menu"]]:
		var k := _label(row[0], 14, Color("#ffe3a3"), title_f)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		grid.add_child(_label(row[1], 14, INK))

	# fiche d'unité, à droite
	sheet_plate = _plate(hud)
	sheet_plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	sheet_plate.offset_left = -348
	sheet_plate.offset_right = -24
	sheet_plate.offset_top = 108
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet_plate.add_child(sv)
	sheet_title = _shadowed(_label("", 21, INK, title_f), 4)
	sv.add_child(sheet_title)
	sheet_body = RichTextLabel.new()
	sheet_body.bbcode_enabled = true
	sheet_body.fit_content = true
	sheet_body.scroll_active = false
	sheet_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sheet_body.custom_minimum_size = Vector2(296, 0)
	sheet_body.add_theme_font_size_override("normal_font_size", 14)
	sheet_body.add_theme_color_override("default_color", INK)
	sheet_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sv.add_child(sheet_body)
	sheet_plate.visible = false
	item_card = Control.new()
	item_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	item_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(item_card)

	# frise de tour : qui agit, dans quel ordre, avec quelle intention
	frieze = HBoxContainer.new()
	frieze.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	frieze.position = Vector2(-300, 18)
	frieze.size = Vector2(600, 56)
	frieze.alignment = BoxContainer.ALIGNMENT_CENTER
	frieze.add_theme_constant_override("separation", 6)
	frieze.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.add_child(frieze)

	boss_bar = VBoxContainer.new()
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-300, 82)
	boss_bar.size = Vector2(600, 40)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_bar)
	var bn := _shadowed(_label("Le Gardien des ruines", 18, Color("#ffc48a"), title_f), 6)
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar.add_child(bn)
	var bb := ProgressBar.new()
	bb.show_percentage = false
	bb.custom_minimum_size = Vector2(600, 20)
	bb.add_theme_stylebox_override("background", sb(Color(0.08, 0.02, 0.02, 0.9), Color(0, 0, 0, 0), 2))
	bb.add_theme_stylebox_override("fill", sb(Color("#e0582a"), Color(0, 0, 0, 0), 2))
	boss_bar.add_child(bb)
	boss_bar.move_child(bb, 0)  # le nom sous la barre : les ailes du cadre prennent le dessus
	boss_bar.add_theme_constant_override("separation", 16)
	boss_bar.position.y = 124
	_bar_frame(bb, "res://assets/ui/barre_boss_tube.png", 0.268, 0.727, 124, 123)
	var orn := TextureRect.new()
	orn.texture = load("res://assets/ui/barre_boss_orn.png")
	orn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orn.stretch_mode = TextureRect.STRETCH_SCALE
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var osc: float = 20.0 / ((0.727 - 0.268) * 209.0)
	orn.size = Vector2(828, 188) * osc
	orn.position = Vector2(300 - orn.size.x * 0.5, -0.268 * 209.0 * osc - (188 - 56) * osc)
	bb.add_child(orn)
	boss_bar.set_meta("bar", bb)
	boss_bar.visible = false

	tip_plate = _plate(hud)
	tip_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pin_bottom(tip_plate, -256)
	tip_plate.z_index = 70  # au-dessus d'une carte survolée
	tip = _label("", 17, INK)
	tip_plate.add_child(tip)


func _build_explore() -> void:
	explore_box = VBoxContainer.new()
	explore_box.position = Vector2(28, 20)
	explore_box.add_theme_constant_override("separation", 2)
	explore_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(explore_box)
	explore_title = _shadowed(_label("", 30, INK, title_f), 8)
	explore_sub = _shadowed(_label("", 14, GOLD), 5)
	explore_party = _shadowed(_label("", 15, INK), 6)
	explore_box.add_child(explore_title)
	explore_box.add_child(explore_sub)
	explore_box.add_child(explore_party)
	explore_heroes = VBoxContainer.new()
	explore_heroes.add_theme_constant_override("separation", 8)
	explore_box.add_child(explore_heroes)
	# l'inventaire reste à portée pendant l'exploration
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for e in [["Équipement · I", "equip"], ["Paquet · P", "deck"]]:
		var b := Button.new()
		b.text = e[0]
		b.add_theme_font_override("font", title_f)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.9), Color("#8fa3b8"), 8, 1, 6))
		b.add_theme_stylebox_override("hover", sb(Color(0.16, 0.18, 0.2, 0.95), Color.WHITE, 8, 1, 6))
		b.focus_mode = Control.FOCUS_NONE
		var k: String = e[1]
		b.pressed.connect(func(): main.adv_menu(k))
		row.add_child(b)
	explore_box.add_child(row)
	var hint := _plate(explore_box)
	hint.add_child(_label("Clic : avancer · croiser un monstre lance le combat · clic droit maintenu : caméra · Échap : menu", 12, DIM))
	explore_box.visible = false


func refresh_log() -> void:
	if log_box:
		log_box.text = "\n".join(battle.log_lines.slice(maxi(0, battle.log_lines.size() - 11)))


func show_explore(on: bool, title := "", sub := "", party := "") -> void:
	explore_box.visible = on
	if on:
		explore_title.text = title
		explore_sub.text = sub
		explore_party.text = party
		explore_party.visible = party != ""
		_rebuild_heroes(explore_heroes, main.heroes, explore_panels)
		_refresh_heroes(explore_panels)


func _orb_style() -> StyleBoxFlat:
	var s := sb(Color("#e8a33c"), Color("#ffe3a3"), 52, 3, 14)
	s.shadow_color = Color(1.0, 0.55, 0.15, 0.45)
	s.shadow_offset = Vector2.ZERO
	return s


func _build_banner() -> void:
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner_box.position = Vector2(-400, 150)
	banner_box.size = Vector2(800, 100)
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.modulate.a = 0
	root.add_child(banner_box)
	banner_title = _title("", 52)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub = _shadowed(_label("", 16, GOLD), 6)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(banner_title)
	banner_box.add_child(banner_sub)
	toast_plate = _plate(root)
	toast_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pin_bottom(toast_plate, -318)
	toast_plate.modulate.a = 0
	toast_lbl = _label("", 17, Color("#ffe2bf"))
	toast_plate.add_child(toast_lbl)


func banner(title: String, subtitle := "") -> void:
	banner_title.text = title
	_paint_title(banner_title)
	banner_sub.text = subtitle
	var tw := create_tween()
	banner_box.position.y = 130
	tw.tween_property(banner_box, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(banner_box, "position:y", 150.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(banner_box, "modulate:a", 0.0, 0.4)


func _reopen_menu() -> void:
	## Un réglage changé depuis la pause : le menu se redessine, son libellé dit tout de suite le nouvel état.
	toggle_menu()
	toggle_menu()


func toast(text: String) -> void:
	toast_lbl.text = text
	toast_plate.z_index = 120  # au-dessus du menu de pause et des écrans de choix
	_fit(toast_plate)
	var tw := create_tween()
	tw.tween_property(toast_plate, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.4)
	tw.tween_property(toast_plate, "modulate:a", 0.0, 0.4)


var coach_plate: PanelContainer
var tuto_arrow: Label
var arrow_to: Callable = Callable()   # initiation : renvoie la cible de la flèche (Vector3 du monde, Control, ou null)
var coach_kick: Label
var coach_txt: RichTextLabel
var coach_next: Button
func coach(kicker: String, text: String, next := false) -> void:
	## Initiation : une consigne à la fois, qui reste jusqu'à la suivante ; « Suite » quand il n'y a qu'à lire.
	if coach_plate == null:
		coach_plate = PanelContainer.new()
		# la voix de l'initiation : la boîte de dialogue neutre (pierre claire des ruines, lierre d'automne)
		var st := StyleBoxTexture.new()
		st.texture = load("res://assets/ui/boite_neutre_s.png")  # demi-taille : un liseré de pierre fin en 9 tranches
		st.texture_margin_left = 40
		st.texture_margin_right = 40
		st.texture_margin_top = 40
		st.texture_margin_bottom = 40
		st.content_margin_left = 44
		st.content_margin_right = 44
		st.content_margin_top = 40
		st.content_margin_bottom = 38
		coach_plate.add_theme_stylebox_override("panel", st)
		coach_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coach_plate.z_index = 101  # lisible aussi par-dessus les écrans (butin, équipement)
		# en bas à gauche, au-dessus de l'orbe de mana : il ne cache ni les PV des unités ni leurs fiches
		coach_plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		coach_plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
		coach_plate.offset_left = 16
		coach_plate.offset_right = 16 + (470 if not big else 560)
		coach_plate.offset_bottom = -(200 if not big else 230)
		coach_plate.offset_top = coach_plate.offset_bottom - 10
		root.add_child(coach_plate)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coach_plate.add_child(v)
		coach_kick = _label("", 14 + (3 if big else 0), GOLD, title_f)
		v.add_child(coach_kick)
		coach_txt = _rich("", 16 + (3 if big else 0), INK)
		coach_txt.custom_minimum_size.x = 380 if not big else 470
		v.add_child(coach_txt)
		coach_next = Button.new()
		coach_next.text = "Suite ▸"
		coach_next.add_theme_font_override("font", title_f)
		coach_next.add_theme_font_size_override("font_size", 18)
		coach_next.add_theme_color_override("font_color", Color("#2a1606"))
		coach_next.add_theme_stylebox_override("normal", sb(GOLD, Color("#fff0c8"), 10, 2, 6))
		coach_next.add_theme_stylebox_override("hover", sb(GOLD.lightened(0.15), Color("#fff0c8"), 10, 2, 6))
		coach_next.size_flags_horizontal = Control.SIZE_SHRINK_END
		coach_next.pressed.connect(func(): main._tuto_ok())
		v.add_child(coach_next)
	coach_plate.visible = text != ""
	coach_next.visible = next
	if text == "":
		return
	coach_kick.text = kicker.to_upper()
	coach_txt.text = _hl(text)
	coach_plate.modulate.a = 0.0
	coach_plate.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(coach_plate, "modulate:a", 1.0, 0.3)


const HL_WORDS := ["ennemi", "ennemis", "frise", "fiche", "épingler", "déplacement", "de dos", "dos", "carte", "cartes", "mana", "énergie",
	"coffre", "fin du tour", "orientation", "vocation", "guilde", "maîtrise", "points de job", "armure", "PV", "portée", "zone orange", "clic", "cliquez"]
static var _hl_rx: RegEx


func _hl(text: String) -> String:
	## Conseil de l'initiation : les mots qui comptent en couleur (mots-clés du jeu et gestes à faire).
	if _hl_rx == null:
		var words: Array = HL_WORDS + Data.KEYWORDS.keys()
		words.sort_custom(func(a, b): return a.length() > b.length())
		_hl_rx = RegEx.create_from_string("(?i)(?<![A-Za-zÀ-ÿ])(" + "|".join(words.map(func(w): return w.replace("(", "\\(").replace(")", "\\)"))) + ")(?![A-Za-zÀ-ÿ])")
	return _hl_rx.sub(text, "[color=#ffcf6e]$1[/color]", true)


func point(to: Callable) -> void:
	## Initiation : une flèche qui rebondit au-dessus de ce qu'on attend du joueur (case, ennemi, carte, coffre).
	arrow_to = to
	if tuto_arrow == null:
		tuto_arrow = _label("▼", 58, GOLD, title_f)
		tuto_arrow.add_theme_color_override("font_outline_color", Color("#2a1606"))
		tuto_arrow.add_theme_constant_override("outline_size", 14)
		tuto_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tuto_arrow.size = Vector2(60, 70)
		tuto_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tuto_arrow.z_index = 102
		root.add_child(tuto_arrow)
	tuto_arrow.visible = false


func tuto_node(key: String) -> Control:
	## Initiation : le nœud d'un écran marqué pour la flèche (bouton, objet du sac).
	var q: Array = [overlay] if overlay else []
	while q.size() > 0:
		var n: Node = q.pop_back()
		if n.get_meta("tuto", "") == key:
			return n
		q.append_array(n.get_children())
	return null


var turn_arrow: Label


func _place_turn_arrow() -> void:
	## Le héros dont c'est le tour : un chevron doré qui rebondit au-dessus de lui, dans un halo qui bat
	## (plein tant qu'il n'a rien fait, plus discret ensuite).
	var h: Unit = battle.active if battle else null
	# plus rien dès qu'on a pris son héros en main : une carte choisie, un chemin tracé, un geste fait
	var show: bool = hud.visible and h != null and battle.player_turn and not battle.busy and overlay == null and not (tuto_arrow != null and tuto_arrow.visible) and not h.moved and battle.played == 0 and battle.card_sel < 0 and battle._move_plan == null
	var p := Vector3.ZERO
	if show:
		p = h.global_position + Vector3(0, h.head + 0.7, 0)
		show = not main.cam.is_position_behind(p)
	if turn_arrow == null:
		if not show:
			return
		turn_arrow = _label("▼", 46, Unit.ACTIVE_COL.lightened(0.2), title_f)
		turn_arrow.add_theme_color_override("font_outline_color", Color("#2a1606"))
		turn_arrow.add_theme_constant_override("outline_size", 12)
		turn_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		turn_arrow.size = Vector2(60, 60)
		turn_arrow.pivot_offset = Vector2(30, 30)
		turn_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		turn_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var halo := TextureRect.new()
		halo.texture = Fx._radial([0.0, 0.3, 1.0], [0.9, 0.45, 0.0])
		halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		halo.position = Vector2(-30, -30)
		halo.size = Vector2(120, 120)
		halo.modulate = Unit.ACTIVE_COL
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halo.show_behind_parent = true
		turn_arrow.add_child(halo)
		turn_arrow.set_meta("halo", halo)
		root.add_child(turn_arrow)
	turn_arrow.visible = show
	if show:
		var t := Time.get_ticks_msec() * 0.001
		var bob := absf(sin(t * 5.0)) * 12.0
		turn_arrow.position = main.cam.unproject_position(p) - Vector2(30, 56 + bob)
		var halo: TextureRect = turn_arrow.get_meta("halo")
		halo.modulate.a = 0.55 + 0.35 * sin(t * 4.0)


func _place_arrow() -> void:
	if tuto_arrow == null:
		return
	var t = arrow_to.call() if arrow_to.is_valid() else null
	var p = null
	var up := false  # sous la cible, pointe vers le haut : ce qui est collé au haut de l'écran (la frise)
	if t is Vector3 and not main.cam.is_position_behind(t):
		p = main.cam.unproject_position(t)
	elif t is Control and is_instance_valid(t) and t.is_visible_in_tree():
		up = t.global_position.y < 150
		p = t.global_position + Vector2(t.size.x * t.scale.x * 0.5, t.size.y * t.scale.y + 74 if up else 0)
	tuto_arrow.visible = p != null and (overlay == null or t is Control)
	if p != null:
		var bob := absf(sin(Time.get_ticks_msec() * 0.006)) * 16.0
		tuto_arrow.text = "▲" if up else "▼"
		tuto_arrow.position = p - Vector2(30, 74 - bob if up else 74 + bob)


func announce(c: Dictionary) -> void:
	toast("%s — %s" % [Data.HEROES[c.owner].name, c.name])


func reward_flash(ci: Dictionary, title: String) -> void:
	## Une récompense gagnée en plein combat (défi relevé) : la carte s'affiche en grand un instant, sans rien bloquer.
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.z_index = 90
	root.add_child(box)
	var k := 1.1
	var w := make_card(ci)
	w.scale = Vector2.ONE * k
	_passthrough(w)
	box.add_child(w)
	var t := _shadowed(_label(title.to_upper(), 26, GOLD, title_f), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size = Vector2(420, 40)
	t.position = Vector2(CARD.x * k * 0.5 - 210, -46)
	box.add_child(t)
	var ench: String = ci.get("ench", "")
	if ench != "" and Data.ENCHANTS.has(ench):
		var e := _shadowed(_label("✦ " + Data.ENCHANTS[ench].name, 18, Color("#d9a8ff"), title_f), 6)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.size = Vector2(420, 28)
		e.position = Vector2(CARD.x * k * 0.5 - 210, CARD.y * k + 8)
		box.add_child(e)
	var vp := root.size
	var end := Vector2(vp.x - CARD.x * k - 60, vp.y * 0.5 - CARD.y * k * 0.5)
	box.position = end + Vector2(CARD.x * k + 80, 0)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "position", end, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(box, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.6)
	tw.tween_property(box, "modulate:a", 0.0, 0.4)
	tw.tween_callback(box.queue_free)


func set_gold(g: int) -> void:
	gold_lbl.text = "%d or" % g


func set_challenge(t: String) -> void:
	challenge_lbl.text = t


func set_header(title: String, subtitle: String) -> void:
	header.text = title
	sub.text = subtitle


func set_sheet(u: Unit) -> void:
	sheet_plate.visible = u != null and is_instance_valid(u) and u.alive
	if not sheet_plate.visible:
		return
	var col: Color = Data.CLASS_COLOR.get(u.key, Color("#ff8a1e")) if u.side == "hero" else Color("#ff9a3c")
	sheet_title.text = u.nm + ("   · épinglé" if u == battle.inspect else "")
	sheet_title.add_theme_color_override("font_color", col.lightened(0.25))
	# idéogrammes devant PV, déplacement et armure
	var ic := func(n: String) -> String: return "[img=20x20]res://assets/ui/icon_%s.png[/img] " % n
	var txt: String = battle.sheet(u).replace("[", "[lb]")
	var rx := RegEx.create_from_string("(?m)^PV ")
	txt = rx.sub(txt, ic.call("pv"), true)
	rx = RegEx.create_from_string("(?m)^Déplacement ")
	txt = rx.sub(txt, ic.call("deplacement"), true).replace("🛡 ", ic.call("armure"))
	# sections : titres dorés et espacés, noms de capacités en gras, notes en petit
	var out: Array = []
	var named := RegEx.create_from_string("^([^:]{2,34}) : (.*)$")
	for line: String in txt.split("\n"):
		if line.begins_with("## "):
			out.append("[font_size=6] [/font_size]")
			out.append("[font_size=12][color=#e3b45c]%s[/color][/font_size]" % line.substr(3).to_upper())
		elif line.begins_with("~ "):
			out.append("[font_size=6] [/font_size]")
			out.append("[font_size=11][color=#a79d8b]%s[/color][/font_size]" % line.substr(2))
		else:
			var m := named.search(line)
			if m and not line.begins_with("[img"):
				out.append("[b][color=#ffe3a3]%s[/color][/b] : %s" % [m.get_string(1), m.get_string(2)])
			else:
				out.append(line)
	sheet_body.text = "\n".join(out)
	sheet_plate.reset_size()


func show_item(tool_id: String, below: float) -> void:
	## Un objet survolé (porté par un ennemi, ou au sol) : sa carte, telle qu'on la volerait.
	var key := "%s|%d" % [tool_id, int(below)]
	if key == _item_key:
		return
	_item_key = key
	for c in item_card.get_children():
		c.queue_free()
	if tool_id == "":
		return
	var k := 0.8 if big else 1.05  # en grand : on doit voir d'un coup d'œil ce qu'on ramasserait
	var w := make_card({"id": Data.obj_of(tool_id), "lvl": 1, "h": battle.heroes[0].key if battle.heroes.size() > 0 else "garde"})
	w.scale = Vector2.ONE * k
	w.pivot_offset = Vector2.ZERO
	w.position = Vector2(sheet_plate.offset_left - CARD.x * k - 10, sheet_plate.offset_top)  # à gauche de la fiche : rien ne la recouvre au doigt
	_passthrough(w)
	item_card.add_child(w)


func menu_open() -> bool:
	return menu != null and is_instance_valid(menu)


func toggle_menu() -> void:
	## Pause : reprendre, abandonner la run (retour au titre) ou quitter.
	if menu_open():
		menu.queue_free()
		menu = null
		return
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.z_index = 100  # au-dessus des cartes de la main
	root.add_child(menu)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(box)
	var t := _title("PAUSE", 56)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var first: Button
	var entries: Array = [["Reprendre", func(): toggle_menu(), "menu_reprendre"], ["Bibliothèque", func(): library_screen(), "menu_bibliotheque"], ["Mode portable : %s" % ("oui" if big else "non"), func(): main.set_mobile(not big), "menu_portable"], ["Vue tactique : %s" % ("oui" if main.tactic else "non"), func():
		main.set_tactic(not main.tactic)
		_reopen_menu(), "menu_tactique"], ["Vocation dès le départ : %s" % ("oui" if main.voc_start else "non"), func():
		main.set_voc_start(not main.voc_start)
		_reopen_menu(), "menu_vocation"], ["Langue : Français" if not Lang.on else "Language: English", func(): main.set_lang("fr" if Lang.on else "en"), "menu_langue"], ["Abandonner la run", func(): main.abandon(), "menu_abandonner"], ["Quitter le jeu", func(): get_tree().quit(), "menu_quitter"]]
	if hud.visible and battle.player_turn and not battle.over:
		entries.insert(1, ["Passer la salle (debug)", func():
			toggle_menu()
			battle.debug_win(), "menu_reprendre"])
	for e in entries:
		var b := _bar_button(e[0], e[2], 440.0, 54.0, 20)
		b.pressed.connect(e[1])
		var c := CenterContainer.new()
		c.add_child(b)
		box.add_child(c)
		if first == null:
			first = b
	# volume de la musique
	var vr := HBoxContainer.new()
	vr.alignment = BoxContainer.ALIGNMENT_CENTER
	vr.add_theme_constant_override("separation", 14)
	var vl := _shadowed(_label("Musique", 20, INK, title_f), 6)
	vr.add_child(vl)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 1
	sl.value = main.music_vol * 100.0
	sl.custom_minimum_size = Vector2(240, 28)
	sl.add_theme_stylebox_override("slider", sb(Color(0, 0, 0, 0.6), GOLD.darkened(0.3), 6, 1))
	sl.add_theme_stylebox_override("grabber_area", sb(GOLD.darkened(0.1), Color(0, 0, 0, 0), 6))
	sl.add_theme_stylebox_override("grabber_area_highlight", sb(GOLD, Color(0, 0, 0, 0), 6))
	var pct := _shadowed(_label("%d %%" % int(sl.value), 16, DIM), 5)
	pct.custom_minimum_size = Vector2(52, 0)
	sl.value_changed.connect(func(v: float):
		pct.text = "%d %%" % int(v)
		main.set_music_volume(v / 100.0))
	vr.add_child(sl)
	vr.add_child(pct)
	box.add_child(vr)
	var hint := _label("M : couper / remettre la musique", 13, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	first.grab_focus()


func set_tip(t: String) -> void:
	tip.text = t
	tip_plate.visible = t != ""
	_fit(tip_plate)


func _plate(parent: Control) -> PanelContainer:
	## Plaque sombre centrée : le texte ne flotte jamais seul sur la scène.
	var p := PanelContainer.new()
	var st := sb(Color(0.06, 0.055, 0.06, 0.86), Color(1, 0.85, 0.6, 0.25), 8, 1, 6)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _pin_bottom(p: Control, y: float) -> void:
	## Ancré en bas au centre, grandit vers le haut : ne sort jamais de l'écran.
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_top = y
	p.offset_bottom = y


func _fit(p: PanelContainer) -> void:
	p.reset_size()
	var w := p.get_combined_minimum_size().x
	p.offset_left = -w * 0.5
	p.offset_right = w * 0.5


func show_hud(on: bool) -> void:
	hud.visible = on
	tag_layer.visible = on
	if on:
		_rebuild_heroes()
		refresh()


# ------------------------------------------------------------------ héros et reliques

func _rebuild_heroes(box: VBoxContainer = null, list: Array = [], panels: Dictionary = {}) -> void:
	## Les fiches des héros : en combat (cliquables) ou pendant l'exploration du donjon.
	var fight := box == null
	if fight:
		box = hero_box
		list = battle.heroes
		panels = hero_panels
	for c in box.get_children():
		c.queue_free()
	panels.clear()
	for h in list:
		var col: Color = Data.CLASS_COLOR[h.key]
		var p := Panel.new()
		p.custom_minimum_size = Vector2(270, 100)
		p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		p.add_theme_stylebox_override("panel", sb(Color(0.07, 0.065, 0.07, 0.78), col.darkened(0.2), 10, 1, 6))
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		if fight:
			p.gui_input.connect(func(e):
				if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and h.alive:
					battle.pick_hero(h))
		box.add_child(p)
		var badge := _panel(p, sb(col, col.lightened(0.4), 8, 2))
		badge.position = Vector2(12, 13)
		badge.size = Vector2(52, 52)
		# le portrait ouvre la fiche : trait, vocation, les quatre pièces d'équipement
		badge.mouse_filter = Control.MOUSE_FILTER_STOP
		badge.tooltip_text = "Fiche de %s : équipement, trait, vocation" % h.nm
		badge.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				badge.accept_event()
				if fight and battle.card_sel >= 0 and h.alive:
					battle.pick_hero(h)  # une carte choisie : le portrait la joue sur ce héros
				else:
					hero_sheet(h))
		var por := TextureRect.new()
		por.texture = load("res://assets/art/portrait_%s.png" % h.key)
		por.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		por.offset_left = 3
		por.offset_top = 3
		por.offset_right = -3
		por.offset_bottom = -3
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		por.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(por)
		var nm := _label(h.nm, 19, INK, title_f)
		nm.position = Vector2(76, 6)
		p.add_child(nm)
		var tr := _label(Data.TRAITS[h.trait_id].name, 12, col.lightened(0.45))
		tr.position = Vector2(76, 30)
		var tip_txt: String = "%s : %s" % [Data.TRAITS[h.trait_id].name, Data.TRAITS[h.trait_id].text]
		for q in h.passives():
			tip_txt += "\n%s : %s" % [Data.PASSIVES[q].name, Data.PASSIVES[q].text]
		tr.tooltip_text = tip_txt
		p.tooltip_text = tip_txt
		if h.passives().size() > 0:
			tr.text += "  ·  " + ", ".join(h.passives().map(func(q): return Data.PASSIVES[q].name))
		tr.mouse_filter = Control.MOUSE_FILTER_PASS
		tr.size = Vector2(182, 18)  # les passifs débordaient du cadre : coupés, le détail au survol
		tr.clip_text = true
		tr.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		p.add_child(tr)
		var hico := TextureRect.new()
		hico.texture = icon("pv")
		hico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hico.position = Vector2(74, 47)
		hico.size = Vector2(22, 22)
		hico.modulate = Color(1.0, 0.62, 0.58)
		hico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(hico)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.position = Vector2(98, 52)
		bar.size = Vector2(158, 12)
		bar.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.55), Color(0, 0, 0, 0), 2))
		bar.add_theme_stylebox_override("fill", sb(col, Color(0, 0, 0, 0), 2))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(bar)
		_bar_frame(bar, "res://assets/ui/barre_heros.png", 0.2044, 0.8011, 78, 58)
		var hp := _shadowed(_label("", 12, INK), 4)
		hp.position = Vector2(98, 50)
		hp.size = Vector2(158, 16)
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(hp)
		var st := HBoxContainer.new()
		st.alignment = BoxContainer.ALIGNMENT_END
		st.add_theme_constant_override("separation", 6)
		st.position = Vector2(150, 6)
		st.size = Vector2(108, 24)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var arm := _chip("armure", "", Color(0.8, 0.9, 1.0), 20)
		var boot := _chip("deplacement", "", Color.WHITE, 22)
		boot.tooltip_text = "Peut encore bouger"
		st.add_child(arm)
		st.add_child(boot)
		p.add_child(st)
		# les stats d'un coup d'œil : bonus de dégâts, déplacement, saut, vitesse
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 10)
		stats.position = Vector2(76, 72)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(stats)
		panels[h] = {"panel": p, "bar": bar, "hp": hp, "st": st, "col": col, "stats": stats}


func _stats_row(row: HBoxContainer, h: Unit) -> void:
	for c in row.get_children():
		c.queue_free()
	row.add_child(_chip("attaque", "+%d" % (h.gear_dmg() + h.dmg_bonus + h.rage), Color(1.0, 0.75, 0.6), 18))
	row.add_child(_chip("deplacement", str(h.move), Color.WHITE, 18))
	var l := _shadowed(_label("saut %d · vit. %d" % [h.jump, h.speed], 13, DIM), 4)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	row.tooltip_text = "Bonus de dégâts de l'équipement, déplacement, hauteur de saut, vitesse (ordre du tour)"


func _refresh_heroes(panels: Dictionary = {}) -> void:
	if panels.is_empty():
		panels = hero_panels
	for h in panels:
		var d: Dictionary = panels[h]
		_stats_row(d.stats, h)
		d.bar.max_value = h.max_hp
		d.bar.value = h.hp
		d.hp.text = "%d / %d" % [h.hp, h.max_hp] if h.alive else "tombé"
		var arm: HBoxContainer = d.st.get_child(0)
		arm.visible = h.alive and h.block > 0
		if arm.get_child_count() < 2:
			arm.add_child(_shadowed(_label("", 17, INK, Fx.number_font()), 4))
		(arm.get_child(1) as Label).text = str(h.block)
		var boot: Control = d.st.get_child(1)
		boot.visible = h.alive
		boot.modulate = Color(1, 1, 1, 0.25) if h.moved else Color.WHITE
		var sel: bool = battle.active == h
		d.panel.add_theme_stylebox_override("panel", sb(Color(0.1, 0.09, 0.08, 0.88) if sel else Color(0.07, 0.065, 0.07, 0.78), GOLD if sel else d.col.darkened(0.2), 10, 2 if sel else 1, 6))
		d.panel.modulate = Color(1, 1, 1, 1) if h.alive else Color(0.5, 0.5, 0.5, 0.8)


func refresh_relics(relics: Array) -> void:
	for c in relic_row.get_children():
		c.queue_free()
	for r in relics:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(40, 40)
		p.add_theme_stylebox_override("panel", sb(Color(0.08, 0.07, 0.07, 0.85), GOLD.darkened(0.2), 20, 2, 4))
		p.tooltip_text = "%s\n%s" % [Data.RELICS[r].name, Data.RELICS[r].text]
		var rp := "res://assets/ui/relic_%s.png" % r
		if not ResourceLoader.exists(rp):
			var gl := _label(Data.RELICS[r].glyph, 20, GOLD, title_f)
			gl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(gl)
			relic_row.add_child(p)
			continue
		var g := TextureRect.new()
		g.texture = load(rp)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		g.offset_left = 5
		g.offset_top = 5
		g.offset_right = -5
		g.offset_bottom = -5
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(g)
		relic_row.add_child(p)


# ------------------------------------------------------------------ rafraîchissement

func refresh() -> void:
	if not hud.visible:
		return
	if hero_panels.size() != battle.heroes.size():
		_rebuild_heroes()
	_refresh_heroes()
	_refresh_frieze()
	energy_lbl.text = str(battle.energy)
	var ah: Unit = battle.active
	bpm_lbl.visible = ah != null and "tidiane" in [ah.key, ah.voc, ah.voc2]
	if bpm_lbl.visible:
		bpm_lbl.text = "♪ %d BPM" % ah.bpm
		bpm_lbl.add_theme_color_override("font_color", Color("#9a5ad0").lerp(Color("#ff8a50"), ah.bpm / 12.0))
	var ak: String = battle.active.key if battle.active else "neutre"
	var av: String = battle.active.voc if battle.active else ""
	if ak + av != _orb_key:
		_orb_key = ak + av
		var t: Texture2D = load("res://assets/ui/orb_%s.png" % ak)
		var hole: Array = ORB_HOLE[ak]
		var w: float = 104.0 / hole[2]
		orb_frame.texture = t
		orb_frame.size = Vector2(w, w * t.get_height() / t.get_width())
		orb_frame.position = Vector2(52, 52) - Vector2(hole[0], hole[1]) * orb_frame.size
		voc_badge.visible = av != ""
		if av != "":
			voc_badge.texture = load("res://assets/ui/orb_%s.png" % av)
			(voc_dot.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Data.CLASS_COLOR[av]
			voc_badge.tooltip_text = "Vocation : " + Data.HEROES[av].name
	pile_lbl.text = ("%s · pioche %d · défausse %d" % [battle.active.nm, battle.draw_pile.size(), battle.discard.size()]) if battle.active else "Tour ennemi"
	end_btn.disabled = not battle.player_turn or battle.busy
	end_btn.text = "Fin du tour" if battle.active == null else "Fin · %s" % battle.active.nm
	keys_plate.visible = (_keys_hover or show_keys == 1) and not big  # au survol de « Commandes » (ou H) ; au doigt, pas de clavier
	tactic_btn.text = "◧  Tactique" if not main.tactic else "◧  Tactique ✓"
	(tactic_btn.get_theme_stylebox("normal") as StyleBoxFlat).border_color = GOLD if main.tactic else GOLD.darkened(0.3)
	var psig := "%s|%d|%d|%s" % [JSON.stringify(battle.powers), battle.discard.size(), battle.draw_pile.size(), log_box.visible]
	if psig != _played_sig:
		_played_sig = psig
		_rebuild_played()
	var sig := JSON.stringify(battle.hand)
	if sig != _hand_sig:
		_hand_sig = sig
		_rebuild_hand()
	for i in _cards.size():
		var c := Data.card(battle.hand[i])
		var h := battle.owner_of(c)
		var ok: bool = h and h.alive and battle.cost_of(c) <= battle.energy and battle.player_turn
		_cards[i].modulate = Color.WHITE if ok else Color(0.55, 0.53, 0.5)
		var orb_l: Label = _cards[i].get_meta("cost")
		orb_l.text = "X" if c.has("xcost") else str(battle.cost_of(c))
		(_cards[i].get_meta("live") as Control).visible = ok and battle.trig_live(c)
	_sync_tags()
	main.refresh_hover()


func _rebuild_played() -> void:
	## Pouvoirs actifs en pastilles lisibles (survol ou toucher : leur texte), puis deux boutons :
	## la défausse et le journal ne s'affichent que si on les demande.
	for c in played_box.get_children():
		c.queue_free()
	for pw in battle.powers:
		var id := ""
		for k in Data.all_ids():
			if Data.def(k).get("power", "") == pw:
				id = k
				break
		if id == "":
			continue
		var who = battle.power_owner.get(pw)
		var col: Color = Data.CLASS_COLOR.get(who.key, GOLD) if who is Unit and is_instance_valid(who) else GOLD
		var pill := PanelContainer.new()
		var st := sb(Color(0.08, 0.06, 0.1, 0.9), col, 14, 2, 4)
		st.content_margin_left = 10
		st.content_margin_right = 12
		st.content_margin_top = 3
		st.content_margin_bottom = 3
		pill.add_theme_stylebox_override("panel", st)
		pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var txt := Data.card_text(Data.card({"id": id, "lvl": 1}))
		pill.tooltip_text = "%s
%s" % [Data.def(id).name, txt]
		pill.add_child(_shadowed(_label("✦ " + Data.def(id).name, 16, col.lightened(0.45), title_f), 4))
		pill.gui_input.connect(func(e):
			if e is InputEventScreenTouch and e.pressed:
				toast("%s : %s" % [Data.def(id).name, txt]))
		played_box.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	played_box.add_child(row)
	row.add_child(_small_btn("Pioche · %d" % battle.draw_pile.size(), func(): main.view_deck("pioche")))
	row.add_child(_small_btn("Défausse · %d" % battle.discard.size(), func(): main.view_deck("defausse")))
	row.add_child(_small_btn("Journal" + (" ▾" if log_box.visible else " ▸"), func():
		log_box.visible = not log_box.visible
		_played_sig = ""))


func _quick_btn(text: String, tip: String, cb: Callable) -> Button:
	var qb := Button.new()
	qb.text = text
	qb.tooltip_text = tip
	qb.focus_mode = Control.FOCUS_NONE
	qb.add_theme_font_override("font", title_f)
	qb.add_theme_font_size_override("font_size", 16)
	qb.add_theme_color_override("font_color", INK)
	qb.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.9), GOLD.darkened(0.3), 10, 1, 6))
	qb.add_theme_stylebox_override("hover", sb(Color(0.18, 0.15, 0.1, 0.95), GOLD, 10, 1, 6))
	qb.add_theme_stylebox_override("pressed", sb(Color(0.3, 0.22, 0.1, 0.95), GOLD, 10, 2, 6))
	qb.custom_minimum_size = Vector2(0, 38)
	qb.pressed.connect(cb)
	return qb


func _small_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", title_f)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", sb(Color(0.07, 0.06, 0.065, 0.85), GOLD.darkened(0.35), 8, 1, 4))
	b.add_theme_stylebox_override("hover", sb(Color(0.14, 0.11, 0.07, 0.95), GOLD, 8, 1, 6))
	b.add_theme_stylebox_override("pressed", sb(Color(0.14, 0.11, 0.07, 0.95), GOLD, 8, 2, 2))
	for k in ["normal", "hover", "pressed"]:
		var st: StyleBoxFlat = b.get_theme_stylebox(k)
		st.content_margin_left = 12
		st.content_margin_right = 12
	b.custom_minimum_size = Vector2(0, 34)
	b.pressed.connect(cb)
	return b


func _rebuild_hand() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()
	_hover_card = -1
	for i in battle.hand.size():
		var card := make_card(battle.hand[i])
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		card.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				battle.select_card(idx))
		card.mouse_entered.connect(func(): _hover_card = idx)
		card.mouse_exited.connect(func():
			if _hover_card == idx:
				_hover_card = -1)
		var vp := root.size
		card.position = Vector2(vp.x * 0.5 - CARD.x * 0.5, vp.y + 40)
		hand_layer.add_child(card)
		_cards.append(card)


const FRAME_MARGE := 0.2  # toile des cadres de classe : 20 % de débord de chaque côté (blender/kie_ui/cut_classes.py)
const TYPE_COL := {"atk": Color("#e0584a"), "skill": Color("#5a9be0"), "move": Color("#3fc0a8"), "power": Color("#b07ae0")}
const FRAME_OF := {"atk": "attaque", "skill": "technique", "move": "mouvement", "power": "pouvoir"}
# fenêtres des cadres KIE (fractions mesurées par blender/kie_ui/cut_ui.py) : illustration, texte
const F_ART := Rect2(0.14, 0.175, 0.72, 0.475)
const F_TXT := Rect2(0.14, 0.685, 0.72, 0.225)


func _frame_slices(tex: Texture2D, marge: float) -> Control:
	## Le cadre peint en trois tranches : le haut et le bas tels quels, la bande du texte (0,72 -> 0,86 de la carte)
	## étirée de CARD_EXTRA. Les ornements ne se déforment pas, la carte s'allonge.
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var W := float(tex.get_width())
	var H := float(tex.get_height())
	var S := CARD_BASE * (1.0 + 2.0 * marge)
	var cy := func(f: float) -> float: return (marge + f) / (1.0 + 2.0 * marge)
	var a: float = cy.call(0.72)
	var b: float = cy.call(0.86)
	for part in [[0.0, a, 0.0], [a, b, CARD_EXTRA], [b, 1.0, 0.0]]:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, part[0] * H, W, (part[1] - part[0]) * H)
		var tr := TextureRect.new()
		tr.texture = at
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(-CARD_BASE.x * marge, -CARD_BASE.y * marge + part[0] * S.y + (CARD_EXTRA if part[0] >= b else 0.0))
		tr.size = Vector2(S.x, (part[1] - part[0]) * S.y + part[2])
		holder.add_child(tr)
	return holder


func make_card(ci: Dictionary, see := true) -> Control:
	var c := Data.card(ci)
	if see and main and main.has_method("library_see"):
		main.library_see(c.id)
	var col: Color = Data.CLASS_COLOR[c.cls[0]]
	var col2: Color = Data.CLASS_COLOR[c.cls[1]] if c.cls.size() > 1 else col
	var obj: bool = c.has("tool")
	var rar: int = 4 if c.get("legend", false) else c.get("rar", 1)  # carte-objet de niveau 3 : légendaire
	var legend: bool = rar == 4
	# niveau 3 d'une carte-objet jamais obtenu : on sait qu'il existe, pas ce qu'il fait
	var secret: bool = obj and c.get("legend", false) and main and not main.library.has(c.id + "#3")
	if secret:
		c.name = "???"
		c.text = "Niveau 3 — Légendaire : ???"
	var card := Control.new()
	card.size = CARD
	card.custom_minimum_size = CARD
	card.pivot_offset = Vector2(CARD.x * 0.5, CARD.y)
	# fond sombre sous le cadre, liseré de rareté (lueur pour les rares et légendaires)
	var bgs := sb(Color("#1b181d") if not legend else Color("#231812"), Data.RARITY_COL[rar].darkened(0.1 if rar > 1 else 0.5), 10, 2, 18 if legend else (10 if rar == 3 else 6))
	if rar >= 3:
		bgs.shadow_color = Data.RARITY_COL[rar] * Color(1, 1, 1, 0.55)
	var bg := _panel(card, bgs)
	bg.position = CARD_BASE * Vector2(0.05, 0.05)
	bg.size = CARD_BASE * Vector2(0.9, 0.91) + Vector2(0, CARD_EXTRA)
	var art_r := Rect2(CARD_BASE * F_ART.position, CARD_BASE * F_ART.size)
	var txt_r := Rect2(CARD_BASE * F_TXT.position, CARD_BASE * F_TXT.size + Vector2(0, CARD_EXTRA))
	var art := TextureRect.new()
	var path := "res://assets/art/card_%s.png" % c.id
	art.texture = load(path) if ResourceLoader.exists(path) else (_art2(col, col2, c.kind) if c.has("guild") else _art(col, c.kind))
	if obj and not ResourceLoader.exists(path) and ResourceLoader.exists("res://assets/ui/tool_%s.png" % c.tool):
		art.texture = load("res://assets/ui/tool_%s.png" % c.tool)  # l'icône de l'objet, en attendant sa peinture
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var under := _panel(card, sb(col.darkened(0.55), Color(0, 0, 0, 0), 4))
		under.position = art_r.position
		under.size = art_r.size
		card.move_child(under, art.get_index())
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.clip_contents = true
	art.position = art_r.position
	art.size = art_r.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)
	# bas de l'illustration assombri : les chiffres s'y posent
	var shade := TextureRect.new()
	var sg := Gradient.new()
	sg.colors = PackedColorArray([Color(0.05, 0.04, 0.05, 0.0), Color(0.05, 0.04, 0.05, 0.85)])
	var sgt := GradientTexture2D.new()
	sgt.gradient = sg
	sgt.fill_from = Vector2(0, 0)
	sgt.fill_to = Vector2(0, 1)
	shade.texture = sgt
	shade.position = art_r.position + Vector2(0, art_r.size.y * 0.6)
	shade.size = Vector2(art_r.size.x, art_r.size.y * 0.4)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(shade)
	var lvc: int = c.get("lvl", 1)
	if lvc >= 2:
		var lf := _panel(card, sb(Color(0, 0, 0, 0), Color("#ffcf5a") if lvc >= 3 else Color("#d8e0e8"), 3, 2))
		lf.position = art_r.position
		lf.size = art_r.size
	# le cadre peint : celui de la classe, ou de la guilde (moitié de chaque classe), ou de l'objet.
	# Toile plus grande que la carte (cut_classes.py) : les ornements débordent.
	var fname := "c_objet" if obj else "c_%s" % c.cls[0]
	if not obj and c.cls.size() > 1:
		var gl: Array = Guildes.LIST[c.g] if c.has("g") else [c.cls[0], c.cls[1]]
		fname = "g_%s_%s" % [gl[0], gl[1]]
	var fpath := "res://assets/ui/frame_%s.png" % fname
	var marge := FRAME_MARGE
	if not ResourceLoader.exists(fpath):
		fpath = "res://assets/ui/frame_%s.png" % FRAME_OF.get(c.kind, "technique")
		marge = 0.0
	var fr := _frame_slices(load(fpath), marge)
	if obj and legend:
		fr.modulate = Color(1.0, 0.85, 0.6)
	card.add_child(fr)
	if not obj:
		# le type de la carte, sur la ligne qui sépare l'illustration du texte
		var tc: Color = TYPE_COL.get(c.kind, GOLD)
		var tname: String = {"atk": "Attaque", "skill": "Technique", "move": "Mouvement", "power": "Pouvoir"}.get(c.kind, "Technique")
		var tp := _panel(card, sb(Color(0.05, 0.04, 0.05, 0.92), tc, 7, 1))
		var tlab := _label(tname, 10, tc.lightened(0.35), title_f)
		var tw: float = title_f.get_string_size(tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16
		tp.size = Vector2(tw, 15)
		tp.position = Vector2((CARD.x - tw) * 0.5, txt_r.position.y - 9)
		tlab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tlab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tlab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tp.add_child(tlab)
	var shown: String = c.name.split(",")[0] if c.name.length() > 18 else c.name  # « Kaede, Vent sans ombre » -> « Kaede »
	var fs := 17
	while fs > 9 and title_f.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > CARD.x * 0.62:
		fs -= 1  # le nom tient toujours dans le bandeau
	var nm := _shadowed(_label(shown, fs, INK, title_f), 5)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.position = Vector2(CARD.x * 0.18, CARD_BASE.y * 0.06)
	nm.size = Vector2(CARD.x * 0.64, CARD_BASE.y * 0.1)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(nm)
	var orb := _panel(card, sb(Color("#e8a33c"), Color("#fff0c8"), 19, 2, 4))
	orb.position = Vector2(-6, -6)
	orb.size = Vector2(40, 40)
	var cl := _label("X" if c.has("xcost") else str(c.cost), 22, Color("#2a1606"), title_f)
	cl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orb.add_child(cl)
	card.set_meta("cost", cl)
	if lvc >= 2:
		# niveau : pastilles sur une pilule sombre, en haut à droite de l'illustration
		var pill := _panel(card, sb(Color(0.04, 0.03, 0.04, 0.8), Color(0, 0, 0, 0), 7))
		pill.position = Vector2(art_r.end.x - lvc * 11 - 12, art_r.position.y + 4)
		pill.size = Vector2(lvc * 11 + 8, 16)
		var pips := _label("●".repeat(lvc), 10, Color("#ffcf5a") if lvc >= 3 else Color("#e8eef4"))
		pips.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pips.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.add_child(pips)
	if c.has("voix"):
		var vd := _panel(card, sb(Data.VOIX[c.voix][1], Color(0.05, 0.04, 0.04, 0.9), 7, 2))
		vd.position = art_r.position + Vector2(5, 5)
		vd.size = Vector2(14, 14)
	var live := _panel(card, sb(Color(0, 0, 0, 0), Color(1.0, 0.82, 0.35), 13, 3, 16))
	live.position = Vector2(-3, -3)
	live.size = CARD + Vector2(6, 6)
	live.visible = false
	# derrière la carte : son ombre ne voile plus l'illustration (la carte « bonus actif » paraissait éteinte)
	(live.get_theme_stylebox("panel") as StyleBoxFlat).shadow_color = Color(1.0, 0.7, 0.25, 0.55)
	(live.get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset = Vector2.ZERO
	card.move_child(live, 0)
	card.set_meta("live", live)
	card.tooltip_text = ""
	card.set_meta("kwcard", ci)
	var gem := _shadowed(_label("✦" if legend else "◆", 19 if rar >= 3 else 15, Data.RARITY_COL[rar], title_f), 4)
	gem.position = Vector2(CARD.x * 0.83, CARD_BASE.y * 0.05)
	card.add_child(gem)
	if rar > 1:
		nm.add_theme_color_override("font_color", Data.RARITY_COL[rar].lightened(0.3))
	if obj:
		# bandeau des charges : ce qu'il reste à la carte
		var uses: int = int(ci.get("uses", Data.level(ci)))
		var band := _panel(card, sb(Color(0.05, 0.04, 0.05, 0.82), Color(0, 0, 0, 0), 6))
		band.position = art_r.position + Vector2(4, 22 if lvc >= 2 else 4)
		band.size = Vector2(art_r.size.x - 8, 17)
		var btxt: String = "Objet · Éphémère" if c.get("eph", false) else ("Objet · ✦ Inépuisable" if legend else "Objet · %s %d charge%s" % ["◆".repeat(maxi(uses, 1)), uses, "s" if uses > 1 else ""])
		var bl := _label(btxt, 11, (Data.RARITY_COL[4] if legend else col).lightened(0.35))
		bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.clip_text = true
		band.add_child(bl)
	elif c.has("guild") or c.cls[0] != c.owner:
		# bandeau : la guilde, ou la classe d'origine d'une carte de vocation
		var band := _panel(card, sb(Color(0.05, 0.04, 0.05, 0.82), Color(0, 0, 0, 0), 6))
		band.position = art_r.position + Vector2(4, 22 if lvc >= 2 else 4)
		band.size = Vector2(art_r.size.x - 8, 17)
		var bl := _label(c.guild if c.has("guild") else "Vocation · " + Data.HEROES[c.cls[0]].name, 11, col2.lightened(0.45) if c.has("guild") else col.lightened(0.4))
		bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.clip_text = true
		band.add_child(bl)
	# les chiffres dans des bulles aux coins, comme une carte à collectionner : l'effet en bas à gauche
	# (dégâts, soin, armure, empilés s'il y en a plusieurs), la portée en bas à droite
	if not secret:
		var fx: Array = []
		if c.get("dmg", 0) > 0:
			fx.append(["attaque", str(c.dmg) + ("×%d" % c.hits if c.get("hits", 1) > 1 else ""), BUBBLE_DMG])
		if c.get("heal", 0) > 0 or c.get("heal_all", 0) > 0:
			fx.append(["pv", str(c.get("heal", c.get("heal_all", 0))), BUBBLE_HEAL])
		if c.get("block", 0) > 0:
			fx.append(["armure", str(c.block), BUBBLE_ARM])
		for k in fx.size():
			var d := 48.0 if k == 0 else 38.0
			var b := _bubble(fx[k][0], fx[k][1], fx[k][2], d)
			b.position = Vector2(-14 + (48.0 - d) * 0.5, CARD.y - 38 - (0 if k == 0 else 46 + (k - 1) * 40))  # à cheval sur le coin, comme une carte à collectionner
			card.add_child(b)
		var rg: Array = c.get("range", [0, 0])
		if c.get("target", "foe") != "self" and rg[1] > 0:
			var rb := _bubble("portee", "%d-%d" % [maxi(rg[0], 1), rg[1]] if rg[0] > 1 else str(rg[1]), BUBBLE_RANGE, 48.0)
			rb.position = Vector2(CARD.x - 34, CARD.y - 38)
			card.add_child(rb)
	var txt := Data.card_brief(c)
	var tt := Lang.t(Data.trig_text(c))
	var body := VBoxContainer.new()
	body.position = txt_r.position + Vector2(6, 0)  # un peu rentré : les bulles des coins mordent sur le cadre
	body.size = txt_r.size - Vector2(12, 0)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 1)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(body)
	var long := txt.length() + tt.length()
	if txt != "":
		var r := _rich(kw_bbcode(txt), 15 if long <= 50 else (14 if long <= 80 else 13), INK)
		r.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # déjà traduit, mots-clés compris
		r.custom_minimum_size.x = txt_r.size.x + 8
		body.add_child(r)
	if tt != "":
		var r2 := _rich(kw_bbcode(tt), 13 if long <= 80 else 12, Color("#ffd98a"))
		r2.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		r2.custom_minimum_size.x = txt_r.size.x + 8
		body.add_child(r2)
	return card


func _rich(bb: String, size: int, col: Color) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(CARD.x - 20, 0)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", col)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.text = "[center]" + bb + "[/center]"
	return r


static var _kw_keys: Array = []
static var _kw_disp := {}      # mot affiché -> clé de Data.KW_ICON
static var _kw_lang := false
static var _kw_rx := {}
static func kw_bbcode(t: String) -> String:
	## Chaque mot-clé précédé de son idéogramme (game-icons.net repassées en pixel art).
	if _kw_keys.is_empty() or _kw_lang != Lang.on:
		# en anglais, on cherche les mots-clés traduits (même idéogramme)
		_kw_lang = Lang.on
		_kw_keys = Data.KW_ICON.keys()
		_kw_disp.clear()
		for k in _kw_keys:
			_kw_disp[Lang.t(k)] = k
		_kw_keys = _kw_disp.keys()
		_kw_keys.sort_custom(func(a, b): return a.length() > b.length())
		_kw_rx.clear()
	t = t.replace("[", "[lb]")
	var used: Array = []
	for k: String in _kw_keys:
		if t.contains(k):
			# mot entier seulement : « tire » ne s'allume pas au milieu de « Retire »
			if not _kw_rx.has(k):
				_kw_rx[k] = RegEx.create_from_string("(?<![A-Za-zÀ-ÿ])" + k.replace("(", "\\(").replace(")", "\\)").replace("+", "\\+") + "(?![A-Za-zÀ-ÿ])")
			var nt: String = (_kw_rx[k] as RegEx).sub(t, "§%d¤" % used.size(), true)
			if nt != t:
				t = nt
				used.append(k)
	for i in used.size():
		t = t.replace("§%d¤" % i, "[img=15x15]res://assets/ui/kw_%s.png[/img][color=#ffe3a3]%s[/color]" % [Data.KW_ICON[_kw_disp[used[i]]], used[i]])
	return t


static var _icons := {}
static func icon(n: String) -> Texture2D:
	## Idéogrammes générés (KIE) : pv, deplacement, armure, attaque, portee.
	if not _icons.has(n):
		_icons[n] = load("res://assets/ui/icon_%s.png" % n)
	return _icons[n]


const BUBBLE_DMG := Color("#b8322a")
const BUBBLE_HEAL := Color("#2f8a45")
const BUBBLE_ARM := Color("#50677e")
const BUBBLE_RANGE := Color("#8a6a2e")
func _bubble(n: String, txt: String, fill: Color, d: float) -> Panel:
	## Bulle de coin de carte : un disque coloré, l'idéogramme en filigrane, le chiffre en gros par-dessus.
	var b := Panel.new()
	var st := sb(fill, Color("#f4e6c4"), int(d * 0.5), 3, 5)
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("panel", st)
	b.size = Vector2(d, d)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = icon(n)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = Vector2(d * 0.14, d * 0.14)
	t.size = Vector2(d * 0.72, d * 0.72)
	t.modulate = Color(0, 0, 0, 0.3)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	var fs := int(d * (0.56 if txt.length() <= 2 else 0.4))
	var l := _label(txt, fs, Color.WHITE, Fx.number_font())
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	l.add_theme_constant_override("outline_size", 7)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	return b


func _chip(n: String, txt: String, tint := Color.WHITE, sz := 26) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 1)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = icon(n)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(sz, sz)
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	if txt != "":
		var l := _shadowed(_label(txt, sz - 3, INK, Fx.number_font()), 4)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
	return h


func _art2(a: Color, b: Color, kind: String) -> Texture2D:
	## Illustration par défaut d'une carte de guilde : les deux couleurs se rencontrent.
	var key := "%s%s%s" % [a.to_html(), b.to_html(), kind]
	if _arts.has(key):
		return _arts[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.55, 1.0])
	g.colors = PackedColorArray([a.lightened(0.25), a.darkened(0.35), b.darkened(0.35), b.lightened(0.25)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.0, 0.0)
	t.fill_to = Vector2(1.0, 1.0)
	t.width = 128
	t.height = 80
	_arts[key] = t
	return t


static var _arts := {}
func _art(col: Color, kind: String) -> Texture2D:
	var key := "%s%s" % [col.to_html(), kind]
	if _arts.has(key):
		return _arts[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([col.lightened(0.35), col.darkened(0.2), col.darkened(0.75)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.45)
	t.fill_to = Vector2(1.1, 1.1)
	t.width = 128
	t.height = 80
	_arts[key] = t
	return t


var kw_panel: VBoxContainer
var _kw_for: Control
var kw_force: Control         # tests : une carte « survolée » sans souris


func _kw_update() -> void:
	## Au survol d'une carte (au doigt : la carte choisie), ses mots-clés en encarts à pictogramme, à côté d'elle.
	var hov: Control = get_viewport().gui_get_hovered_control()
	var tgt: Control = null
	var n: Control = hov
	for k in 5:
		if n == null:
			break
		if n.has_meta("kwcard"):
			tgt = n
			break
		for ch in n.get_children():
			if ch is Control and ch.has_meta("kwcard"):
				tgt = ch
				break
		if tgt:
			break
		n = n.get_parent() as Control
	if tgt == null and kw_force and is_instance_valid(kw_force):
		tgt = kw_force
	if tgt == null and big and battle and battle.card_sel >= 0 and battle.card_sel < _cards.size():
		tgt = _cards[battle.card_sel]
	# une carte libérée (écran refermé) vaut null dans une comparaison : sans ce garde-fou, ses encarts restaient affichés
	if tgt != null and tgt == _kw_for and is_instance_valid(_kw_for):
		_kw_place(tgt)
		return
	if tgt == null and (kw_panel == null or not kw_panel.visible):
		_kw_for = null
		return
	_kw_for = tgt
	if kw_panel == null:
		kw_panel = VBoxContainer.new()
		kw_panel.z_index = 130
		kw_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kw_panel.add_theme_constant_override("separation", 6)
		root.add_child(kw_panel)
	for ch in kw_panel.get_children():
		ch.queue_free()
	kw_panel.visible = false
	if tgt == null:
		return
	var kc := Data.card(tgt.get_meta("kwcard"))
	var list := Data.keyword_list(kc)
	var made: String = kc.gives.id if kc.has("gives") else str(kc.get("shows", ""))  # carte créée : montrée en entier
	if list.is_empty() and made == "":
		return
	for e in list:
		var p := PanelContainer.new()
		var st := sb(Color(0.05, 0.045, 0.05, 0.95), Color(1, 1, 1, 0.08), 10, 1, 8)
		st.content_margin_left = 10
		st.content_margin_right = 12
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", st)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(hb)
		var im := TextureRect.new()
		var ip := ("res://assets/ui/%s.png" if e.icon.begins_with("guild_") or e.icon.begins_with("vocation_") else "res://assets/ui/kw_%s.png") % e.icon
		if ResourceLoader.exists(ip):
			im.texture = load(ip)
		im.custom_minimum_size = Vector2(34, 34)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		im.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(im)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(v)
		v.add_child(_label(e.title, 17, Color("#ffe3a3"), title_f))
		var t := _label(e.text, 13, INK)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(230, 0)
		v.add_child(t)
		kw_panel.add_child(p)
	if made != "":
		var mk := _label("Crée :", 15, Color("#ffe3a3"), title_f)
		kw_panel.add_child(mk)
		var k := 0.62
		var hold := Control.new()
		hold.custom_minimum_size = CARD * k
		hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mc := make_card({"id": made, "lvl": 1})
		mc.scale = Vector2.ONE * k
		mc.pivot_offset = Vector2.ZERO
		_passthrough(mc)
		hold.add_child(mc)
		kw_panel.add_child(hold)
	kw_panel.visible = true
	kw_panel.reset_size()
	_kw_place(tgt)


func _kw_place(tgt: Control) -> void:
	if not kw_panel or not kw_panel.visible:
		return
	var r := tgt.get_global_rect()
	var vs := root.size
	var w := kw_panel.get_combined_minimum_size().x
	var x := r.end.x + 10 if r.end.x + 10 + w < vs.x else r.position.x - w - 10
	var h := kw_panel.get_combined_minimum_size().y
	kw_panel.position = Vector2(clampf(x, 4, vs.x - w - 4), clampf(r.position.y, 4, vs.y - h - 4))


func _process(dt: float) -> void:
	_kw_update()
	_place_arrow()
	_place_turn_arrow()
	_fit_screen(overlay)  # un écran trop haut se réduit (téléphone, ou l'escouade en deux rangées)
	_fit_screen(sheet_layer)
	if touch_box:
		# menu toujours là ; caméra, annuler et danger seulement sur le plateau
		for i in range(1, touch_box.get_child_count()):
			touch_box.get_child(i).visible = hud.visible or explore_box.visible
	if not hud.visible:
		return
	_layout_hand(dt)
	_place_tags()


func over_hand(p: Vector2) -> bool:
	## La bande de la main (cartes au repos, levées au survol, et leurs interstices) : le plateau n'y reçoit ni survol ni clic.
	var n := _cards.size()
	if n == 0 or not hud.visible:
		return false
	var vp := root.size
	var half := (n - 1) * 0.5 * minf(146.0, 900.0 / n) * hand_k / 0.84 + CARD.x * 0.5 * hand_k * 1.33 + 12.0
	var top := vp.y - (CARD.y * hand_k * 1.33 + 80.0 if _hover_card >= 0 else CARD.y * hand_k + 28.0)
	return absf(p.x - vp.x * 0.5) < half and p.y > top


func _layout_hand(dt: float) -> void:
	var n := _cards.size()
	if n == 0:
		return
	var vp := root.size
	var spacing := minf(146.0, 900.0 / n) * hand_k / 0.84
	var k := 1.0 - exp(-dt * 14.0)
	for i in n:
		var card: Control = _cards[i]
		var off := i - (n - 1) * 0.5
		var pos := Vector2(vp.x * 0.5 + off * spacing - CARD.x * 0.5, vp.y - CARD.y - 20 + off * off * 3.0)  # les bulles des coins débordent en bas
		var rot := off * 0.03
		var sc := hand_k
		var z := i
		if i == battle.card_sel:
			pos.y -= 40
			rot = 0.0
			sc = hand_k + 0.14
			z = 50
		if i == _hover_card:
			pos.y -= 60
			rot = 0.0
			sc = hand_k * 1.33
			z = 60
		card.position = card.position.lerp(pos, k)
		card.rotation = lerpf(card.rotation, rot, k)
		card.scale = card.scale.lerp(Vector2.ONE * sc, k)
		card.z_index = z


# ------------------------------------------------------------------ frise de tour

func _refresh_frieze() -> void:
	for c in frieze.get_children():
		c.queue_free()
	var boss: Unit = null
	for f in battle.alive_foes():
		if f.data.has("titre") and boss == null:
			boss = f
	# qui joue maintenant, puis la suite du round, puis le début du suivant
	var units: Array = []
	var q := maxi(battle.qi, 0)
	for i in range(q, battle.order.size()):
		units.append(battle.order[i])
	units.append(null)
	for i in range(0, q):
		units.append(battle.order[i])
	units = units.filter(func(u): return u == null or (is_instance_valid(u) and u.alive))
	for u in units:
		if u == null:
			frieze.add_child(_label("↻", 18, GOLD, title_f))
			continue
		var col: Color = Data.CLASS_COLOR.get(u.key, Color("#c9463a"))
		var now: bool = battle.order.size() > battle.qi and battle.qi >= 0 and battle.order[battle.qi] == u
		var p := PanelContainer.new()
		var st := sb(Color(0.16, 0.12, 0.06, 0.95) if now else Color(0.07, 0.06, 0.065, 0.88), GOLD if now else col, 6, 3 if now else 1, 4)
		st.content_margin_left = 6
		st.content_margin_right = 6
		st.content_margin_top = 2
		st.content_margin_bottom = 2
		p.add_theme_stylebox_override("panel", st)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := _label("", 13, INK, title_f)
		if u.side == "hero":
			l.text = u.nm
		else:
			l.text = "%s %s" % [u.nm.split(" ")[0], battle.intent(u)]
			l.add_theme_color_override("font_color", Color("#ffc48a"))
		# survol = comme survoler l'unité sur le plateau (case, fiche, silhouette) ; clic = la caméra y va
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var uu: Unit = u
		if frieze_unit == uu:
			p.add_theme_stylebox_override("panel", sb(Color(0.2, 0.16, 0.08, 0.95), Color.WHITE, 6, 2, 8))
		p.mouse_entered.connect(func():
			if is_instance_valid(uu):
				frieze_unit = uu)
		p.mouse_exited.connect(func():
			if frieze_unit == uu:
				frieze_unit = null)
		p.gui_input.connect(func(e):
			if is_instance_valid(uu) and (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT or e is InputEventScreenTouch and e.pressed):
				frieze_unit = uu
				main.target = Vector3(uu.position.x, main.target.y, uu.position.z))
		p.add_child(l)
		frieze.add_child(p)
	_boss_bars(boss)


# ------------------------------------------------------------------ étiquettes des unités

func _sync_tags() -> void:
	var all: Array = battle.heroes + battle.foes
	for u in tags.keys():
		if not all.has(u) or not is_instance_valid(u):
			tags[u].queue_free()
			tags.erase(u)
	for u in all:
		if not tags.has(u):
			tags[u] = _make_tag(u)
		var t: Control = tags[u]
		var bar: ProgressBar = t.get_meta("bar")
		bar.max_value = u.max_hp
		bar.value = u.hp
		# poison : la part de la vie que le poison va manger, en vert au bout de la barre
		if not bar.has_meta("psn"):
			var pr_ := ColorRect.new()
			pr_.color = Color(0.45, 0.95, 0.3)
			pr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.add_child(pr_)
			bar.set_meta("psn", pr_)
		var ps: ColorRect = bar.get_meta("psn")
		var pz: int = mini(u.poison, maxi(u.hp, 0))
		ps.visible = pz > 0 and u.max_hp > 0
		if ps.visible:
			var bw: float = bar.size.x if bar.size.x > 0 else bar.custom_minimum_size.x
			var bh: float = bar.size.y if bar.size.y > 0 else 14.0
			ps.position = Vector2(bw * float(u.hp - pz) / u.max_hp, 2)
			ps.size = Vector2(bw * float(pz) / u.max_hp, bh - 4)
		var lbl: Label = t.get_meta("hp")
		lbl.text = str(u.hp) + ("  🛡%d" % u.block if u.block > 0 else "") + ("  ☠%d" % u.poison if u.poison > 0 else "") \
			+ ("  ◎" if u.mark > 0 else "") + ("  ⛓" if u.root > 0 else "")
		var pv: Label = t.get_meta("pv")
		var pr := battle.predict(u, main.hover)
		if pr.is_empty():
			pv.text = ""
		else:
			var after := maxi(0, u.hp - maxi(0, pr.dmg - u.block))
			var tag := ""
			for n in pr.notes:
				if n.begins_with("dos"):
					tag = "  DOS"
				elif n.begins_with("flanc") and tag == "":
					tag = "  FLANC"
			pv.text = "%d → %d%s" % [u.hp, after, tag]
		var it: Label = t.get_meta("intent")
		it.text = battle.intent(u) if u.side == "foe" else ""
		it.visible = it.text != ""


func _make_tag(u: Unit) -> Control:
	var t := Control.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(70, 40)
	tag_layer.add_child(t)
	var it := _label("", 19, Color("#ffc48a"), title_f)
	it.position = Vector2(5, -24)
	it.size = Vector2(60, 28)
	it.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	it.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ist := sb(Color(0.12, 0.03, 0.02, 0.85), Color(1.0, 0.45, 0.25, 0.8), 6, 1, 4)
	it.add_theme_stylebox_override("normal", ist)
	t.add_child(it)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.position = Vector2(-1, 10)
	bar.size = Vector2(72, 14)
	var hero := u.side == "hero"
	var fill_col: Color = Unit.ALLY_COL if hero else Unit.FOE_COL  # un camp, une couleur : bleu les nôtres, rouge les leurs
	bar.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.75), Color(0.85, 0.93, 1.0, 0.95) if hero else Color(0.35, 0.04, 0.02, 0.95), 4, 2))
	bar.add_theme_stylebox_override("fill", sb(fill_col, Color(0, 0, 0, 0), 4))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(bar)
	var hp := _shadowed(_label("", 12, Color.WHITE, title_f), 4)
	hp.position = Vector2(-20, 8)
	hp.size = Vector2(110, 18)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(hp)
	var pv := _shadowed(_label("", 15, Color("#ffe08a"), title_f), 6)
	pv.position = Vector2(-40, 26)
	pv.size = Vector2(150, 20)
	pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(pv)
	t.set_meta("pv", pv)
	t.set_meta("bar", bar)
	t.set_meta("hp", hp)
	t.set_meta("intent", it)
	return t


func _place_tags() -> void:
	var cam: Camera3D = main.cam
	for u in tags:
		var t: Control = tags[u]
		if not is_instance_valid(u) or not u.alive:
			t.visible = false
			continue
		var p: Vector3 = u.global_position + Vector3(0, u.head, 0)
		if cam.is_position_behind(p):
			t.visible = false
			continue
		t.visible = true
		t.position = cam.unproject_position(p) - Vector2(35, 20)
	# pile : une étiquette qui en recouvre une autre descend d'un cran ; rien sous la frise ni la barre du boss
	var top := 158.0 if boss_bar.visible else 118.0
	var vis: Array = tags.values().filter(func(t): return t.visible)
	vis.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in vis.size():
		var t: Control = vis[i]
		t.position.y = maxf(t.position.y, top)
		for j in i:
			var o: Control = vis[j]
			if absf(o.position.x - t.position.x) < 74.0 and absf(o.position.y - t.position.y) < 46.0:
				t.position.y = o.position.y + 46.0


# ------------------------------------------------------------------ écrans de choix

var last_n := 0            # nombre d'options du dernier choix (pilote de test)
var skip_ok := false  # l'écran en cours se passe (Échap, clic droit)
func choose(title: String, subtitle: String, options: Array, allow_skip := false, skip_text := "Passer", portrait := "", top_card := {}) -> int:
	_close_overlay()
	skip_ok = allow_skip
	last_n = options.size()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100  # au-dessus des cartes de la main
	root.add_child(overlay)
	var opened := Time.get_ticks_msec()
	var fresh := func() -> bool: return Time.get_ticks_msec() - opened < 300  # le clic de l'écran précédent ne valide pas celui-ci
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	if portrait != "" and ResourceLoader.exists(portrait):
		# l'Ancien en pied, à gauche, qui s'avance doucement
		var pr := TextureRect.new()
		pr.texture = load(portrait)
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pr.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		pr.offset_left = 20
		pr.offset_right = 20 + root.size.y * 0.6
		pr.offset_top = 30
		pr.offset_bottom = -30
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(pr)
		pr.modulate.a = 0.0
		pr.position.x -= 40
		var tw := create_tween().set_parallel()
		tw.tween_property(pr, "modulate:a", 1.0, 0.6)
		tw.tween_property(pr, "position:x", pr.position.x + 40, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if portrait != "":
		box.offset_left = root.size.y * 0.6
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var tl := _title(title, 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	if subtitle != "":
		box.add_child(_speech(subtitle, speaker if ResourceLoader.exists("res://assets/ui/boite_%s.png" % speaker) else "neutre"))
	else:
		var sl := _shadowed(_label(subtitle, 16, GOLD), 6)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(sl)
	if not top_card.is_empty():
		# la carte trouvée en grand, puis une flèche vers les héros à qui la donner
		var tk := 0.95 if not big else 0.8
		var tc := make_card(top_card)
		var th := Control.new()
		th.custom_minimum_size = CARD * tk
		th.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tc.scale = Vector2.ONE * tk
		tc.pivot_offset = Vector2.ZERO
		_passthrough(tc)
		th.add_child(tc)
		th.set_meta("kwcard", top_card)
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(th)
		box.add_child(cc)
		var ar := _shadowed(_label("▼  à qui la donner ?  ▼", 20, GOLD, title_f), 6)
		ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(ar)
	# cartes et objets mêlés (le marchand) : les cartes en haut, le reste en dessous
	var split: bool = options.size() > 7 and options.any(func(o): return o.has("card")) and options.any(func(o): return not o.has("card"))
	var many: bool = not split and options.size() > 7 and options[0].has("card")
	var row2: Container
	var row: Container
	if many:
		var grid := GridContainer.new()
		grid.columns = 8
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(1400, maxf(260.0, root.size.y - 360.0))  # le bouton « Fermer » reste toujours à l'écran
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var cc := CenterContainer.new()
		cc.custom_minimum_size = Vector2(1390, 0)
		cc.add_child(grid)
		sc.add_child(cc)
		var sco := CenterContainer.new()
		sco.add_child(sc)
		box.add_child(sco)
		row = grid
	elif split:
		for k in 2:
			var hb := HBoxContainer.new()
			hb.alignment = BoxContainer.ALIGNMENT_CENTER
			hb.add_theme_constant_override("separation", 12)
			box.add_child(hb)
			if k == 0:
				row = hb
			else:
				row2 = hb
	elif options.size() >= 8 and not options.any(func(o): return o.has("card") or o.has("hidden")):
		# huit choix (l'escouade) : deux rangées de quatre, pour que ça respire
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 22)
		grid.add_theme_constant_override("v_separation", 18)
		var cc := CenterContainer.new()
		cc.add_child(grid)
		box.add_child(cc)
		row = grid
	else:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		# des cartes en grand : les ornements des cadres débordent, il faut de la marge entre elles
		hb.add_theme_constant_override("separation", (70 if options.size() <= 4 else 40) if options.any(func(o): return o.has("card")) else (26 if options.size() <= 6 else 12))
		box.add_child(hb)
		row = hb
	for i in options.size():
		var o: Dictionary = options[i]
		var w: Control
		if o.has("hidden"):
			w = Control.new()
			w.custom_minimum_size = CARD * (0.8 if many else 1.2)
			card_back(w, o.hidden)
			w.tooltip_text = "%s à découvrir" % Data.RARITY_NAME[o.hidden]
		elif o.has("card"):
			w = make_card(o.card)
			var holder := Control.new()
			# en grand pour choisir : on lit la carte sans plisser les yeux (butin, draft, forge)
			var sc_k := 0.8 if many else (1.1 if split else (1.55 if options.size() <= 4 else (1.3 if options.size() <= 6 else 1.2)))
			holder.custom_minimum_size = CARD * sc_k
			holder.tooltip_text = w.tooltip_text
			w.scale = Vector2.ONE * sc_k
			w.pivot_offset = Vector2.ZERO
			holder.add_child(w)
			if o.has("tag"):
				w.position.y = 38
				holder.custom_minimum_size.y += 38
				var gold_tag: bool = o.tag == "Après" or o.tag.begins_with("✦")
				var tg := _shadowed(_label(o.tag, 22 if o.tag.length() < 16 else (16 if o.tag.length() < 24 else 13), GOLD if gold_tag else DIM, title_f), 6)
				tg.position = Vector2(0, 0)
				tg.size = Vector2(CARD.x * sc_k, 30)
				tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				holder.add_child(tg)
			_passthrough(w)
			w = holder
		else:
			w = _option(o, int(o.get("w", 164 if split else (250 if options.size() <= 4 or options.size() >= 8 else (205 if options.size() <= 6 else 186)))))
		w.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		w.focus_mode = Control.FOCUS_ALL
		w.gui_input.connect(func(e):
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or e.is_action_pressed("ui_accept"):
				w.accept_event()
				if not fresh.call():
					picked.emit(idx))
		w.mouse_entered.connect(func():
			w.modulate = Color(1.15, 1.1, 1.0)
			if o.has("card"):  # la carte survolée avance d'un cran
				w.pivot_offset = w.size * 0.5
				w.z_index = 5
				w.create_tween().tween_property(w, "scale", Vector2.ONE * 1.06, 0.12))
		w.mouse_exited.connect(func():
			w.modulate = Color.WHITE
			if o.has("card"):
				w.z_index = 0
				w.create_tween().tween_property(w, "scale", Vector2.ONE, 0.12))
		w.focus_entered.connect(func(): w.modulate = Color(1.2, 1.12, 0.95))
		w.focus_exited.connect(func(): w.modulate = Color.WHITE)
		(row2 if split and not o.has("card") else row).add_child(w)
		if i == 0 and Input.get_connected_joypads().size() > 0:
			w.grab_focus.call_deferred()
	if (team_on or options.any(func(o): return o.has("card"))) and main.heroes.size() > 0:  # voir l'équipe et ses paquets avant de choisir
		var team := HBoxContainer.new()
		team.position = Vector2(28, 24)
		team.add_theme_constant_override("separation", 8)
		overlay.add_child(team)
		var team_lbl := _shadowed(_label("Équipe", 16, GOLD), 5)
		team_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		team.add_child(team_lbl)
		for h in main.heroes:
			var tb := TextureButton.new()
			tb.texture_normal = load("res://assets/art/portrait_%s.png" % h.key)
			tb.ignore_texture_size = true
			tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			tb.custom_minimum_size = Vector2(56, 56)
			tb.tooltip_text = "Fiche et paquet de %s" % h.nm
			tb.pressed.connect(hero_sheet.bind(h))
			team.add_child(tb)
	if allow_skip:
		var sk := Button.new()
		sk.text = skip_text
		sk.add_theme_font_override("font", title_f)
		sk.add_theme_font_size_override("font_size", 20)
		sk.add_theme_color_override("font_color", INK)
		sk.add_theme_color_override("font_hover_color", Color.WHITE)
		sk.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.94), GOLD.darkened(0.2), 10, 2, 8))
		sk.add_theme_stylebox_override("hover", sb(Color(0.2, 0.16, 0.1, 0.96), GOLD, 10, 2, 8))
		sk.add_theme_stylebox_override("pressed", sb(Color(0.3, 0.22, 0.1, 0.96), GOLD, 10, 2, 8))
		sk.custom_minimum_size = Vector2(260, 50)
		sk.pressed.connect(func():
			if not fresh.call():
				picked.emit(-1))
		var c := CenterContainer.new()
		c.add_child(sk)
		box.add_child(c)
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.25)
	var i: int = await picked
	_close_overlay()
	return i


# Cartes d'étage peintes (KIE, voxel) : une île par biome. Chaque salle est posée à la main sur le décor
# (places, ponts, sentiers ; fractions de l'image) : 6 étapes de 3 voies (haut, milieu, bas) puis le gardien.
# Ordre = Data.BIOMES. Retoucher : scratchpad map/mk.py + show.py superposent les points sur l'image.
const MAPS := [
	["automne", [[Vector2(0.27, 0.46), Vector2(0.23, 0.55), Vector2(0.31, 0.61)], [Vector2(0.37, 0.41), Vector2(0.35, 0.52), Vector2(0.42, 0.59)], [Vector2(0.46, 0.36), Vector2(0.46, 0.49), Vector2(0.52, 0.57)], [Vector2(0.56, 0.32), Vector2(0.57, 0.45), Vector2(0.62, 0.53)], [Vector2(0.63, 0.28), Vector2(0.68, 0.41), Vector2(0.72, 0.49)], [Vector2(0.72, 0.24), Vector2(0.78, 0.36), Vector2(0.82, 0.44)], [Vector2(0.88, 0.31)]]],
	["mousse", [[Vector2(0.30, 0.36), Vector2(0.33, 0.44), Vector2(0.36, 0.51)], [Vector2(0.38, 0.40), Vector2(0.40, 0.47), Vector2(0.44, 0.55)], [Vector2(0.47, 0.40), Vector2(0.49, 0.46), Vector2(0.52, 0.56)], [Vector2(0.56, 0.40), Vector2(0.58, 0.47), Vector2(0.60, 0.57)], [Vector2(0.64, 0.42), Vector2(0.65, 0.51), Vector2(0.68, 0.59)], [Vector2(0.72, 0.46), Vector2(0.73, 0.54), Vector2(0.76, 0.59)], [Vector2(0.78, 0.50)]]],
	["braise", [[Vector2(0.28, 0.44), Vector2(0.30, 0.52), Vector2(0.34, 0.58)], [Vector2(0.36, 0.47), Vector2(0.40, 0.52), Vector2(0.44, 0.61)], [Vector2(0.46, 0.45), Vector2(0.50, 0.55), Vector2(0.53, 0.64)], [Vector2(0.57, 0.45), Vector2(0.59, 0.54), Vector2(0.62, 0.63)], [Vector2(0.66, 0.45), Vector2(0.68, 0.54), Vector2(0.70, 0.63)], [Vector2(0.74, 0.47), Vector2(0.76, 0.55), Vector2(0.77, 0.64)], [Vector2(0.86, 0.80)]]],
	["lilas", [[Vector2(0.30, 0.43), Vector2(0.33, 0.49), Vector2(0.37, 0.55)], [Vector2(0.39, 0.45), Vector2(0.42, 0.52), Vector2(0.44, 0.60)], [Vector2(0.48, 0.47), Vector2(0.51, 0.56), Vector2(0.52, 0.64)], [Vector2(0.57, 0.50), Vector2(0.59, 0.59), Vector2(0.61, 0.66)], [Vector2(0.66, 0.52), Vector2(0.68, 0.60), Vector2(0.70, 0.67)], [Vector2(0.74, 0.55), Vector2(0.76, 0.62), Vector2(0.77, 0.69)], [Vector2(0.82, 0.74)]]],
	["tours", [[Vector2(0.22, 0.50), Vector2(0.25, 0.57), Vector2(0.30, 0.64)], [Vector2(0.33, 0.47), Vector2(0.35, 0.56), Vector2(0.39, 0.64)], [Vector2(0.44, 0.42), Vector2(0.45, 0.52), Vector2(0.47, 0.62)], [Vector2(0.53, 0.40), Vector2(0.55, 0.50), Vector2(0.56, 0.60)], [Vector2(0.63, 0.42), Vector2(0.64, 0.52), Vector2(0.64, 0.62)], [Vector2(0.72, 0.45), Vector2(0.73, 0.54), Vector2(0.70, 0.66)], [Vector2(0.80, 0.54)]]],
	["altiplano", [[Vector2(0.20, 0.48), Vector2(0.22, 0.55), Vector2(0.26, 0.60)], [Vector2(0.32, 0.44), Vector2(0.34, 0.51), Vector2(0.38, 0.58)], [Vector2(0.44, 0.42), Vector2(0.46, 0.49), Vector2(0.50, 0.56)], [Vector2(0.56, 0.40), Vector2(0.58, 0.47), Vector2(0.62, 0.54)], [Vector2(0.68, 0.39), Vector2(0.70, 0.45), Vector2(0.72, 0.52)], [Vector2(0.78, 0.38), Vector2(0.80, 0.44), Vector2(0.82, 0.50)], [Vector2(0.89, 0.40)]]],
	["cristal", [[Vector2(0.18, 0.52), Vector2(0.20, 0.58), Vector2(0.24, 0.64)], [Vector2(0.30, 0.46), Vector2(0.32, 0.54), Vector2(0.35, 0.61)], [Vector2(0.42, 0.42), Vector2(0.44, 0.50), Vector2(0.47, 0.56)], [Vector2(0.52, 0.38), Vector2(0.55, 0.47), Vector2(0.58, 0.55)], [Vector2(0.62, 0.36), Vector2(0.66, 0.45), Vector2(0.68, 0.54)], [Vector2(0.72, 0.34), Vector2(0.76, 0.42), Vector2(0.78, 0.50)], [Vector2(0.66, 0.28)]]],
	["epilobes", [[Vector2(0.16, 0.48), Vector2(0.18, 0.56), Vector2(0.22, 0.64)], [Vector2(0.28, 0.40), Vector2(0.30, 0.51), Vector2(0.34, 0.64)], [Vector2(0.40, 0.36), Vector2(0.44, 0.46), Vector2(0.44, 0.64)], [Vector2(0.52, 0.35), Vector2(0.54, 0.45), Vector2(0.58, 0.62)], [Vector2(0.66, 0.36), Vector2(0.62, 0.47), Vector2(0.70, 0.62)], [Vector2(0.78, 0.40), Vector2(0.76, 0.52), Vector2(0.82, 0.62)], [Vector2(0.88, 0.52)]]],
	["crypte", [[Vector2(0.20, 0.38), Vector2(0.24, 0.46), Vector2(0.28, 0.54)], [Vector2(0.30, 0.34), Vector2(0.34, 0.48), Vector2(0.36, 0.56)], [Vector2(0.40, 0.42), Vector2(0.44, 0.50), Vector2(0.46, 0.60)], [Vector2(0.52, 0.43), Vector2(0.56, 0.52), Vector2(0.56, 0.62)], [Vector2(0.62, 0.43), Vector2(0.66, 0.52), Vector2(0.66, 0.62)], [Vector2(0.74, 0.44), Vector2(0.76, 0.52), Vector2(0.76, 0.60)], [Vector2(0.82, 0.40)]]],
	["emeraude", [[Vector2(0.24, 0.39), Vector2(0.23, 0.47), Vector2(0.26, 0.56)], [Vector2(0.32, 0.35), Vector2(0.32, 0.46), Vector2(0.36, 0.58)], [Vector2(0.44, 0.36), Vector2(0.44, 0.46), Vector2(0.46, 0.58)], [Vector2(0.56, 0.36), Vector2(0.56, 0.48), Vector2(0.56, 0.62)], [Vector2(0.66, 0.42), Vector2(0.67, 0.50), Vector2(0.66, 0.62)], [Vector2(0.75, 0.45), Vector2(0.78, 0.53), Vector2(0.76, 0.60)], [Vector2(0.88, 0.43)]]],
	["quartz", [[Vector2(0.24, 0.42), Vector2(0.22, 0.50), Vector2(0.26, 0.56)], [Vector2(0.34, 0.40), Vector2(0.32, 0.48), Vector2(0.36, 0.56)], [Vector2(0.44, 0.39), Vector2(0.42, 0.50), Vector2(0.46, 0.57)], [Vector2(0.54, 0.39), Vector2(0.52, 0.48), Vector2(0.56, 0.57)], [Vector2(0.62, 0.40), Vector2(0.62, 0.48), Vector2(0.66, 0.58)], [Vector2(0.70, 0.42), Vector2(0.68, 0.50), Vector2(0.76, 0.57)], [Vector2(0.79, 0.46)]]],
	["jade", [[Vector2(0.26, 0.50), Vector2(0.28, 0.57), Vector2(0.32, 0.63)], [Vector2(0.38, 0.46), Vector2(0.40, 0.53), Vector2(0.42, 0.60)], [Vector2(0.48, 0.42), Vector2(0.50, 0.51), Vector2(0.52, 0.63)], [Vector2(0.58, 0.44), Vector2(0.60, 0.52), Vector2(0.62, 0.65)], [Vector2(0.66, 0.40), Vector2(0.70, 0.51), Vector2(0.70, 0.60)], [Vector2(0.74, 0.42), Vector2(0.78, 0.50), Vector2(0.80, 0.56)], [Vector2(0.85, 0.48)]]],
]
static var _trail: Texture2D
static func trail_tex() -> Texture2D:
	## Coupe de la sente : opaque au centre, bords fondus et grenus, pour qu'elle se pose dans la peinture.
	if _trail == null:
		var im := Image.create(64, 16, false, Image.FORMAT_RGBA8)
		var r := RandomNumberGenerator.new()
		r.seed = 7
		for x in 64:
			for y in 16:
				var v := absf(y - 7.5) / 7.5
				var a := clampf(1.0 - pow(v, 2.2), 0.0, 1.0) * r.randf_range(0.6, 1.0)
				im.set_pixel(x, y, Color(1, 1, 1, a))
		_trail = ImageTexture.create_from_image(im)
	return _trail


func map_screen(title: String, subtitle: String, fmap: Array, step: int, lane: int, nexts: Array, visited: Array, equip_txt: String, bi := 0) -> int:
	## Carte de l'étage : l'île du biome vue de haut, un sentier en pointillés de salle en salle jusqu'au gardien.
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var m: Array = MAPS[bi % MAPS.size()]
	var vp: Vector2 = root.get_viewport_rect().size
	var tex: Texture2D = load("res://assets/ui/map_%s.jpg" % m[0])
	var ts := Vector2(tex.get_width(), tex.get_height())
	var k_img: float = maxf(vp.x / ts.x, vp.y / ts.y)
	var stage := Control.new()
	stage.size = ts * k_img
	stage.position = (vp - stage.size) / 2.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(stage)
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = stage.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bg)
	# voiles haut et bas : les titres et les boutons restent lisibles sur l'image
	for top in [true, false]:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(0.02, 0.02, 0.04, 0.8), Color(0.02, 0.02, 0.04, 0.0)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0) if top else Vector2(0, 1)
		gt.fill_to = Vector2(0, 1) if top else Vector2(0, 0)
		var v := TextureRect.new()
		v.texture = gt
		v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		v.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		v.custom_minimum_size = Vector2(0, 190)
		if top:
			v.offset_bottom = 190
		else:
			v.offset_top = -210
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(v)
	var head := VBoxContainer.new()
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 22
	head.add_theme_constant_override("separation", 2)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(head)
	var tl := _title(title, 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(tl)
	var sl := _shadowed(_label(subtitle, 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(sl)
	var area := Control.new()
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(area)
	# les salles posées à la main (6 étapes + gardien) : rééchantillonnées le long de chaque voie s'il y en a plus
	var cols: Array = m[1]
	var n_steps: int = fmap.size() - 1
	var hand: int = m[1].size() - 1
	if n_steps != hand and n_steps > 0:
		cols = []
		for k in n_steps:
			var t: float = float(k) * float(hand - 1) / float(maxi(n_steps - 1, 1))
			var k0 := int(floor(t))
			var k1 := mini(k0 + 1, hand - 1)
			var f := t - k0
			var col: Array = []
			for i in m[1][k0].size():
				col.append((m[1][k0][i] as Vector2).lerp(m[1][k1][mini(i, m[1][k1].size() - 1)], f))
			cols.append(col)
		cols.append(m[1][hand])
	var pos := func(k: int, i: int) -> Vector2:
		var col: Array = cols[mini(k, cols.size() - 1)]
		var p: Vector2 = col[0] if col.size() == 1 else col[clampi(i + (1 if fmap[k].size() == 1 else 0), 0, col.size() - 1)]
		return stage.position + p * stage.size
	# le sentier : une sente de terre battue qui serpente, bords fondus dans l'image ; des pas dorés sur les chemins
	# ouverts, des pas sombres sur ceux déjà suivis (plus de pointillés posés par-dessus le décor)
	for k in fmap.size() - 1:
		for i in fmap[k].size():
			for j in fmap[k][i].links:
				var a: Vector2 = pos.call(k, i)
				var b: Vector2 = pos.call(k + 1, j)
				var nrm: Vector2 = (b - a).orthogonal().normalized()
				var sd := float((k * 7 + i * 13 + j * 29) % 17)
				var pts := PackedVector2Array()
				for q in 25:
					var u := q / 24.0
					var env := sin(u * PI)  # les extrémités restent sur les salles
					var wob := sin(u * TAU * 1.3 + sd) * 7.0 + sin(u * TAU * 2.7 + sd * 2.0) * 2.5
					pts.append(a.lerp(b, u) + nrm * (wob + (10.0 if int(sd) % 2 == 0 else -10.0)) * env)
				var trod: bool = visited.has(Vector2i(k, i)) and visited.has(Vector2i(k + 1, j))
				var open: bool = k == step - 1 and i == lane and nexts.has(j)
				# bien lisible sur le décor : un bord sombre, un cœur clair ; le chemin ouvert en or, celui déjà suivi en terre
				var core := Color(1.0, 0.8, 0.32, 1.0) if open else (Color(0.5, 0.36, 0.22, 0.95) if trod else Color(0.98, 0.92, 0.76, 0.8))
				for layer in [[18.0, Color(0.06, 0.04, 0.03, 0.6)], [8.0, core]]:
					var ln := Line2D.new()
					ln.points = pts
					ln.width = layer[0] * (1.35 if open else 1.0)
					ln.texture = trail_tex()
					ln.texture_mode = Line2D.LINE_TEXTURE_STRETCH
					ln.default_color = layer[1]
					ln.joint_mode = Line2D.LINE_JOINT_ROUND
					ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
					ln.end_cap_mode = Line2D.LINE_CAP_ROUND
					area.add_child(ln)
				if trod or open:
					# des pas, en quinconce, espacés régulièrement le long de la sente
					var total := 0.0
					for q in range(1, pts.size()):
						total += pts[q].distance_to(pts[q - 1])
					var step_len := 13.0
					var d := step_len
					var q2 := 1
					var acc := 0.0
					var side := 1.0
					while d < total - step_len and q2 < pts.size():
						var seg: float = pts[q2].distance_to(pts[q2 - 1])
						if acc + seg < d:
							acc += seg
							q2 += 1
							continue
						var t: float = (d - acc) / seg
						var p: Vector2 = pts[q2 - 1].lerp(pts[q2], t)
						var dir: Vector2 = (pts[q2] - pts[q2 - 1]).normalized()
						var fp := Polygon2D.new()
						var circ := PackedVector2Array()
						for c in 8:
							var an := c / 8.0 * TAU
							circ.append(Vector2(cos(an) * 3.2, sin(an) * 2.0).rotated(dir.angle()))
						fp.polygon = circ
						fp.position = p + dir.orthogonal() * 3.0 * side
						fp.color = Color(GOLD, 0.95) if open else Color(0.1, 0.06, 0.03, 0.55)
						area.add_child(fp)
						side = -side
						d += step_len
	var info_plate := PanelContainer.new()
	var ips := sb(Color(0.05, 0.04, 0.05, 0.86), GOLD.darkened(0.4), 10, 1, 8)
	ips.content_margin_left = 18
	ips.content_margin_right = 18
	ips.content_margin_top = 8
	ips.content_margin_bottom = 8
	info_plate.add_theme_stylebox_override("panel", ips)
	info_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var info := _label("Choisissez la prochaine salle.", 17, INK)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# au survol d'une salle : son illustration au-dessus de la description
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_plate.add_child(info_box)
	var room_art := TextureRect.new()
	room_art.custom_minimum_size = Vector2(240, 160)
	room_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_art.visible = false
	var art_c := CenterContainer.new()
	art_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_c.add_child(room_art)
	info_box.add_child(art_c)
	info_box.add_child(info)
	var first: Button
	for k in fmap.size():
		for i in fmap[k].size():
			var n: Dictionary = fmap[k][i]
			var r: Dictionary = Data.ROOMS[n.type]
			var col: Color = {"elite": Color("#e0583a"), "boss": Color("#ff5a3a"), "sanctuaire": Color("#8fd0a0"), "reliquaire": Color("#d08aff"), "marchand": Color("#ffd27a"), "mystere": Color("#7fe0c8")}.get(n.type, INK)
			var open: bool = k == step and nexts.has(i)
			var done: bool = visited.has(Vector2i(k, i))
			var b := Button.new()
			b.text = r.glyph
			b.add_theme_font_override("font", title_f)
			b.add_theme_font_size_override("font_size", 28)
			var sz := 72.0 if n.type == "boss" else 56.0
			if n.get("mods", []).size() > 0:
				var mk := _shadowed(_label(Data.MODIFIERS[n.mods[0]].glyph, 26, Color("#ffb05a"), title_f), 8)
				mk.position = pos.call(k, i) + Vector2(sz * 0.3, -sz * 0.8)
				area.add_child(mk)
			b.size = Vector2(sz, sz)
			b.position = pos.call(k, i) - Vector2(sz, sz) * 0.5
			b.pivot_offset = Vector2(sz, sz) * 0.5
			b.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.96), col, int(sz / 2), 3, 10))
			b.add_theme_stylebox_override("hover", sb(col.darkened(0.55), Color.WHITE, int(sz / 2), 3, 14))
			b.add_theme_stylebox_override("focus", sb(col.darkened(0.55), Color.WHITE, int(sz / 2), 3, 14))
			b.add_theme_stylebox_override("pressed", sb(col.darkened(0.3), Color.WHITE, int(sz / 2), 3, 4))
			b.add_theme_stylebox_override("disabled", sb(col.darkened(0.62) if done else Color(0.07, 0.065, 0.075, 0.92), col.darkened(0.25 if done else 0.5), int(sz / 2), 2, 6))
			b.add_theme_color_override("font_color", col)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.add_theme_color_override("font_focus_color", Color.WHITE)
			b.add_theme_color_override("font_disabled_color", INK if done else col.darkened(0.3))
			b.disabled = not open
			var desc: String = n.desc
			var art_p := "res://assets/ui/salle_%s.png" % ("elite" if n.type == "boss" else n.type)
			var show_room := func():
				info.text = desc
				room_art.visible = ResourceLoader.exists(art_p)
				if room_art.visible:
					room_art.texture = load(art_p)
			b.mouse_entered.connect(show_room)
			b.focus_entered.connect(show_room)
			if open:
				var idx: int = i
				b.pressed.connect(func(): picked.emit(idx))
				var tw := b.create_tween().set_loops()
				tw.tween_property(b, "scale", Vector2.ONE * 1.12, 0.6).set_trans(Tween.TRANS_SINE)
				tw.tween_property(b, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
				if first == null:
					first = b
			else:
				b.mouse_filter = Control.MOUSE_FILTER_PASS
			area.add_child(b)
	if lane >= 0 and step > 0:
		# l'escouade : le portrait de tête posé sur la dernière salle
		var here := _panel(area, sb(GOLD, Color("#fff0c8"), 8, 2, 8))
		here.size = Vector2(44, 44)
		here.position = pos.call(step - 1, lane) + Vector2(-22, -80)
		if main.heroes.size() > 0:
			var hp := TextureRect.new()
			hp.texture = load("res://assets/art/portrait_%s.png" % main.heroes[0].key)
			hp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			hp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hp.offset_left = 3
			hp.offset_top = 3
			hp.offset_right = -3
			hp.offset_bottom = -3
			hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			here.add_child(hp)
		var bob := here.create_tween().set_loops()
		bob.tween_property(here, "position:y", here.position.y - 6, 0.7).set_trans(Tween.TRANS_SINE)
		bob.tween_property(here, "position:y", here.position.y, 0.7).set_trans(Tween.TRANS_SINE)
	var foot := VBoxContainer.new()
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -130
	foot.offset_bottom = -22
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN  # l'illustration de salle pousse vers le haut
	foot.add_theme_constant_override("separation", 12)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(foot)
	var ic := CenterContainer.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(info_plate)
	foot.add_child(ic)
	var eq := Button.new()
	eq.text = equip_txt
	eq.add_theme_font_override("font", title_f)
	eq.add_theme_font_size_override("font_size", 18)
	eq.add_theme_color_override("font_color", INK)
	eq.add_theme_stylebox_override("normal", sb(Color(0.08, 0.07, 0.075, 0.92), Color("#8fa3b8"), 10, 2, 6))
	eq.add_theme_stylebox_override("hover", sb(Color(0.16, 0.18, 0.2, 0.95), Color.WHITE, 10, 2, 6))
	eq.add_theme_stylebox_override("focus", sb(Color(0.16, 0.18, 0.2, 0.95), Color.WHITE, 10, 2, 6))
	eq.custom_minimum_size = Vector2(320, 46)
	eq.pressed.connect(func(): picked.emit(-2))
	var dk := eq.duplicate(0)
	dk.text = "Paquet"
	dk.pressed.connect(func(): picked.emit(-4))
	for pair in [[eq, "equipement"], [dk, "paquet"]]:
		_painted_button(pair[0], pair[1])
	var ec := HBoxContainer.new()
	ec.alignment = BoxContainer.ALIGNMENT_CENTER
	ec.add_theme_constant_override("separation", 20)
	ec.add_child(eq)
	ec.add_child(dk)
	foot.add_child(ec)
	# l'équipe, comme en combat : PV, stats ; le portrait ouvre la fiche (équipement, trait, paquet)
	var team := VBoxContainer.new()
	team.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	team.grow_vertical = Control.GROW_DIRECTION_BEGIN
	team.offset_left = 24
	team.offset_bottom = -24
	team.add_theme_constant_override("separation", 6)
	overlay.add_child(team)
	var tp := {}
	_rebuild_heroes(team, main.heroes, tp)
	_refresh_heroes(tp)
	if first and Input.get_connected_joypads().size() > 0:
		first.grab_focus.call_deferred()
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.25)
	var i: int = await picked
	_close_overlay()
	return i


func _painted_button(b: Button, k: String) -> void:
	## Bouton peint (KIE, assets/ui/bouton_<k>.png) : médaillon à gauche, plaque de cuir pour le texte à droite.
	var path := "res://assets/ui/bouton_%s.png" % k
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var h := 64.0
	var w := h * tex.get_width() / tex.get_height()
	for state in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxTexture.new()
		st.texture = tex
		st.content_margin_left = w * 0.48  # le texte sur la plaque, pas sur le médaillon
		st.content_margin_right = w * 0.1
		st.modulate_color = Color(1.25, 1.18, 1.05) if state in ["hover", "focus"] else (Color(0.85, 0.8, 0.75) if state == "pressed" else Color.WHITE)
		b.add_theme_stylebox_override(state, st)
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_color_override("font_color", Color("#f4e6c4"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 15)


func _passthrough(n: Node) -> void:
	## Les clics traversent l'illustration jusqu'au porteur de l'option.
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children():
		_passthrough(ch)


const ITEM_RAR := ["", "Commune", "Peu commune", "Rare", "Mythique"]
const PARCH_INK := Color("#2b1a0e")


func _vignette(title: String, icon: String, text: String, col: Color, tag: String, seen := true, w := 176.0, glyph := "", chips: Array = []) -> Control:
	## Vignette façon étal (reliques, équipement) : nom au-dessus, cadre de cuir, rareté dans le bandeau,
	## grande icône, gemme de rareté sur le séparateur, effet en dessous. Pas encore vue : silhouette et « ??? ».
	var h := w * 609.0 / 360.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := _shadowed(_label(title if seen else "???", 15 if w >= 160 else (13 if w >= 140 else 12), col.lightened(0.35) if seen else DIM, title_f), 5)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(w, 40)
	v.add_child(nl)
	var card := Control.new()
	card.custom_minimum_size = Vector2(w, h)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(card)
	var put := func(c: Control, x0: float, y0: float, x1: float, y1: float) -> void:
		c.position = Vector2(x0 * w, y0 * h)
		c.size = Vector2((x1 - x0) * w, (y1 - y0) * h)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(c)
	var fr := TextureRect.new()
	fr.texture = load("res://assets/ui/vignette.png")
	fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr.stretch_mode = TextureRect.STRETCH_SCALE
	put.call(fr, 0, 0, 1, 1)
	var tg := _label(tag, 12, col.lightened(0.45) if seen else DIM, title_f)
	tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tg.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	tg.add_theme_constant_override("outline_size", 5)
	put.call(tg, 0.2, 0.015, 0.8, 0.11)
	if ResourceLoader.exists(icon):
		var ic := TextureRect.new()
		ic.texture = load(icon)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not seen:
			ic.modulate = Color(0.3, 0.17, 0.07, 0.22)  # à peine une empreinte dans le cuir
		put.call(ic, 0.14, 0.15, 0.86, 0.52)
	elif glyph != "" and seen:
		# pas encore d'icône (reliques neuves) : le glyphe en grand à sa place
		var gl := _label(glyph, int(w * 0.36), col.lightened(0.2), title_f)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		put.call(gl, 0.14, 0.15, 0.86, 0.52)
	var gem := Panel.new()
	gem.add_theme_stylebox_override("panel", sb(col if seen else DIM.darkened(0.3), Color(0.12, 0.06, 0.02), 2, 2))
	gem.size = Vector2(14, 14)
	gem.pivot_offset = Vector2(7, 7)
	gem.rotation = PI / 4
	gem.position = Vector2(w * 0.5 - 7, h * 0.557 - 7)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(gem)
	var y0 := 0.6
	if seen and not chips.is_empty():
		# bonus chiffrés : idéogrammes et valeurs, sous la gemme
		var cr := HBoxContainer.new()
		cr.alignment = BoxContainer.ALIGNMENT_CENTER
		cr.add_theme_constant_override("separation", 8)
		for c in chips:
			var ch := _chip(c[0], c[1], Color.WHITE, 22 if w >= 140 else 18)
			for l in ch.find_children("*", "Label", true, false):
				l.add_theme_color_override("font_color", PARCH_INK)
				l.add_theme_constant_override("outline_size", 0)
			cr.add_child(ch)
		put.call(cr, 0.06, 0.59, 0.94, 0.68)
		y0 = 0.69
	var tx := _label(text if seen else "", 12 if w >= 140 else 10, PARCH_INK)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	put.call(tx, 0.11, y0, 0.89, 0.95)
	return v


# encarts de classe peints (KIE, tools/encarts.py) : marges 9-slice puis bord uni, en pixels de l'image réduite
const ENCARTS := {"garde": [45, 51, 45, 47, 24, 33, 21, 22], "lame": [42, 54, 42, 42, 7, 23, 7, 9], "oracle": [28, 52, 28, 32, 10, 32, 10, 12], "artificier": [33, 49, 33, 42, 11, 29, 11, 10], "moine": [43, 63, 43, 42, 17, 36, 17, 16], "trappeur": [44, 63, 44, 44, 25, 44, 24, 26], "tidiane": [26, 42, 26, 28, 7, 27, 7, 8], "receleur": [32, 46, 32, 34, 14, 28, 13, 15]}
func encart(k: String, pad := 10) -> StyleBox:
	## L'encart peint de la classe (9-slice), ou null s'il n'est pas (encore) dans assets/ui.
	var path := "res://assets/ui/encart_%s.png" % k
	if not ENCARTS.has(k) or not ResourceLoader.exists(path):
		return null
	var m: Array = ENCARTS[k]
	var st := StyleBoxTexture.new()
	st.texture = load(path)
	st.texture_margin_left = m[0]
	st.texture_margin_top = m[1]
	st.texture_margin_right = m[2]
	st.texture_margin_bottom = m[3]
	st.content_margin_left = m[4] + pad
	st.content_margin_top = m[5] + pad
	st.content_margin_right = m[6] + pad
	st.content_margin_bottom = m[7] + pad
	return st


func _option(o: Dictionary, w := 250) -> Control:
	var col: Color = o.get("color", GOLD)
	if o.has("vignette"):
		# équipement et reliques : la vignette de l'étal
		var vg := _vignette(o.title, o.get("image", ""), o.get("text", ""), col, o.vignette, true, 118.0 if w < 170 else clampf(w * 0.8, 140.0, 190.0), o.get("glyph", ""), o.get("chips", []))
		if o.get("dim", false):
			vg.modulate = Color(0.55, 0.55, 0.6)
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		pc.add_child(vg)
		return pc
	var small := w < 170  # version compacte, sous l'étal du marchand
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, o.get("h", 190 if small else 300))
	var s := sb(Color(0.08, 0.07, 0.075, 0.92), col, 14, 2, 14)
	s.content_margin_left = 12 if small else 20
	s.content_margin_right = 12 if small else 20
	s.content_margin_top = 12 if small else 26
	s.content_margin_bottom = 12 if small else 20
	p.add_theme_stylebox_override("panel", s)
	var enc := encart(o.get("encart", ""), 8)
	if enc:
		p.add_theme_stylebox_override("panel", enc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	if o.has("art") and ResourceLoader.exists(o.art):
		# grande illustration (bienfaits des Anciens)
		var ar := TextureRect.new()
		ar.texture = load(o.art)
		ar.custom_minimum_size = Vector2(w - 40, (w - 40) / 1.5)
		ar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ar.clip_contents = true
		ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ar)
	elif o.has("image") and ResourceLoader.exists(o.image):
		var im := TextureRect.new()
		im.texture = load(o.image)
		im.custom_minimum_size = Vector2(56, 56) if small else (Vector2(78, 78) if o.has("cards") else Vector2(110, 110))
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(im)
	else:
		var g := _shadowed(_label(o.get("glyph", "✦"), 34 if small else 64, col.lightened(0.2), title_f), 8)
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(g)
	if o.get("dim", false):
		v.get_child(v.get_child_count() - 1).modulate = Color(0.55, 0.55, 0.6)
	var t := _label(o.title, 15 if small else 24, INK, title_f)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if o.has("chips"):
		var cr := HBoxContainer.new()
		cr.alignment = BoxContainer.ALIGNMENT_CENTER
		cr.add_theme_constant_override("separation", 14)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for c in o.chips:
			cr.add_child(_chip(c[0], c[1], Color.WHITE, 24))
		v.add_child(cr)
	var d := _label(o.get("text", ""), 12 if small else (13 if o.has("cards") else 15), DIM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	if o.has("cards"):
		v.add_theme_constant_override("separation", 6)
		v.add_child(mini_cards(o.cards, 0.36))
	if o.has("tip"):
		p.tooltip_text = o.tip
	return p


func mini_cards(ids: Array, k := 0.34) -> HBoxContainer:
	## Trois cartes en miniature (classe ou guilde) ; au survol, la carte en grand à côté. Le clic passe au parent.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	for id in ids:
		var ci := {"id": id, "lvl": 1}
		var holder := Control.new()
		holder.custom_minimum_size = CARD * k
		holder.mouse_filter = Control.MOUSE_FILTER_PASS
		var w := make_card(ci, false)
		w.scale = Vector2.ONE * k
		w.pivot_offset = Vector2.ZERO
		_passthrough(w)
		holder.add_child(w)
		holder.mouse_entered.connect(func(): _card_peek(ci, holder))
		holder.mouse_exited.connect(func(): _card_peek({}, null))
		row.add_child(holder)
	return row


var _peek: Control
func _card_peek(ci: Dictionary, near: Control) -> void:
	## La carte survolée en taille normale, posée à côté de sa miniature (au-dessus de tout).
	if _peek and is_instance_valid(_peek):
		_peek.queue_free()
	_peek = null
	if ci.is_empty() or near == null:
		return
	var w := make_card(ci, false)
	var k := 1.2
	w.scale = Vector2.ONE * k
	w.pivot_offset = Vector2.ZERO
	_passthrough(w)
	w.z_index = 110
	var r := near.get_global_rect()
	var pos := Vector2(r.end.x + 12, r.position.y - CARD.y * k * 0.5)
	if pos.x + CARD.x * k > root.size.x:
		pos.x = r.position.x - CARD.x * k - 12
	pos.y = clampf(pos.y, 8, root.size.y - CARD.y * k - 8)
	w.position = pos
	root.add_child(w)
	_peek = w


func _fit_screen(layer: Control) -> void:
	## Portable : un téléphone 20:9 n'a que 720 de haut ; un écran trop grand se réduit pour tenir en entier.
	## ponytail: la hauteur seulement, la largeur (1600 en 20:9) n'a jamais débordé
	if not layer or not is_instance_valid(layer):
		return
	var vs := layer.size
	for c in layer.get_children():
		if c is Container and c.anchor_top == 0.0 and c.anchor_bottom == 1.0:
			var s := minf(1.0, vs.y / maxf(c.get_combined_minimum_size().y, 1.0))
			c.pivot_offset = Vector2(vs.x / 2.0, 0)
			c.scale = Vector2(s, s)


func fight_summary(title: String, rows: Array, loot: Array, can_equip: bool) -> int:
	## Fin de combat : l'expérience de chaque héros (jauge vers la maîtrise suivante), tout le butin, puis s'équiper ou repartir.
	## rows : {nm, key, pj0, pj1, lo, hi, m}. Rend 1 pour « S'équiper », 0 pour continuer.
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	overlay.add_child(box)
	var tl := _title(title, 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var hr := HBoxContainer.new()
	hr.alignment = BoxContainer.ALIGNMENT_CENTER
	hr.add_theme_constant_override("separation", 22)
	box.add_child(hr)
	for r in rows:
		var col: Color = Data.CLASS_COLOR[r.key]
		var p := PanelContainer.new()
		var st := sb(Color(0.08, 0.07, 0.075, 0.92), col, 14, 2, 10)
		st.content_margin_left = 16
		st.content_margin_right = 16
		st.content_margin_top = 14
		st.content_margin_bottom = 14
		p.add_theme_stylebox_override("panel", st)
		p.custom_minimum_size = Vector2(250, 0)
		hr.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		p.add_child(v)
		var im := TextureRect.new()
		im.texture = load("res://assets/art/portrait_%s.png" % r.key)
		im.custom_minimum_size = Vector2(90, 90)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(im)
		var nm := _label(r.nm, 22, INK, title_f)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var ml := _label(("Maîtrise %s" % Data.MASTERY_NAME[r.m]) + ("  ·  +%d XP" % (r.pj1 - r.pj0) if r.pj1 > r.pj0 else ""), 15, col.lightened(0.4))
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ml)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(210, 14)
		bar.add_theme_stylebox_override("background", sb(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.15), 6, 1))
		bar.add_theme_stylebox_override("fill", sb(col.lightened(0.15), Color(0, 0, 0, 0), 6))
		bar.min_value = r.lo
		bar.max_value = maxf(r.hi, r.lo + 1)
		bar.value = clampf(r.pj0, r.lo, r.hi)
		v.add_child(bar)
		create_tween().tween_property(bar, "value", clampf(r.pj1, r.lo, r.hi), 0.9).set_delay(0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var nx := _label("%d / %d vers la suivante" % [r.pj1, r.hi] if r.m < 4 else "Maîtrise complète", 13, DIM)
		nx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nx)
	var lp := _plate(box)
	lp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 4)
	lp.add_child(lv)
	lv.add_child(_shadowed(_label("Butin du combat", 18, GOLD, title_f), 4))
	lv.add_child(_label(" · ".join(loot) if loot.size() > 0 else "Rien de plus que la gloire.", 16, INK))
	var br := HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_theme_constant_override("separation", 16)
	box.add_child(br)
	var res := [0]
	for e in ([["S'équiper", 1]] if can_equip else []) + [["Continuer", 0]]:
		var b := Button.new()
		b.text = e[0]
		b.custom_minimum_size = Vector2(240, 54)
		b.add_theme_font_override("font", title_f)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.94), GOLD.darkened(0.2), 10, 2, 8))
		b.add_theme_stylebox_override("hover", sb(Color(0.2, 0.16, 0.1, 0.96), GOLD, 10, 2, 8))
		var k: int = e[1]
		b.set_meta("tuto", "btn%d" % k)
		b.pressed.connect(func(): picked.emit(k))
		br.add_child(b)
	last_n = 1  # pilote de test : « Continuer » (0), sinon il bouclerait sur l'équipement
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.25)
	var i: int = await picked
	_close_overlay()
	return i


func _close_overlay() -> void:
	_card_peek({}, null)
	skip_ok = false
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null


func title_screen(resume := "") -> int:
	## Façon Duelyst : logo et lieu à gauche, une liste d'entrées gothiques, une bulle au survol.
	## Rend 0 nouvelle descente, 2 reprendre, 3 initiation, -1 si le mode portable vient de changer.
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var grad := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.02, 0.02, 0.04, 0.82), Color(0.02, 0.02, 0.04, 0.35), Color(0.02, 0.02, 0.04, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.38, 0.62])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	grad.texture = gt
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(grad)
	var col := VBoxContainer.new()
	col.position = Vector2(70, 40)
	col.add_theme_constant_override("separation", 4)
	overlay.add_child(col)
	var logo := TextureRect.new()  # le logo peint (Higgsfield) : parchemin, épée et bâton croisés, une carte de chaque côté
	logo.texture = load("res://assets/ui/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.custom_minimum_size = Vector2(430, 226) if not big else Vector2(290, 152)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(logo)
	# le lieu du décor, comme « ‹ Magaari, Ember Highlands › » : on peut en changer
	var place := HBoxContainer.new()
	place.add_theme_constant_override("separation", 10)
	col.add_child(place)
	var place_l := _shadowed(_label(main.title_place(0), 17, GOLD), 5)
	for d in [-1, 1]:
		var ab := Button.new()
		ab.text = "‹" if d < 0 else "›"
		ab.flat = true
		ab.focus_mode = Control.FOCUS_NONE
		ab.add_theme_font_override("font", title_f)
		ab.add_theme_font_size_override("font_size", 24)
		ab.add_theme_color_override("font_color", GOLD.darkened(0.2))
		ab.add_theme_color_override("font_hover_color", Color.WHITE)
		ab.tooltip_text = "Changer de décor"
		var dd: int = d
		ab.pressed.connect(func(): place_l.text = main.title_place(dd))
		place.add_child(ab)
		if d < 0:
			place.add_child(place_l)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 70 if not big else 12)
	col.add_child(sp)
	var entries: Array = []
	if resume != "":
		entries.append([2, "Reprendre", "reprendre", "La partie en cours : " + resume])
	entries.append([0, "Nouvelle descente", "descente", "Choisir le mode, la difficulté, l'escouade et ses pactes, puis descendre."])
	entries.append([3, "Initiation", "initiation", "Une run éclair de trois combats : de quoi voir naître un multiclasse en un quart d'heure."])
	entries.append([1, "Bibliothèque  %d / %d" % [main.cards_known(), Data.all_ids().size()], "bibliotheque", "Toutes les cartes déjà croisées, par classe et par guilde."])
	if OS.has_feature("web") or main.args.has("portable"):
		entries.append([4, "Mode portable : %s" % ("oui" if big else "non"), "portable", "Interface agrandie, gestes tactiles (deux doigts : zoom et rotation ; toucher = viser, retoucher = valider), rendu allégé."])
	entries.append([5, "Langue : Français" if not Lang.on else "Language: English", "langue", "Français / English : les textes changent tout de suite, la partie en cours reste."])
	if not OS.has_feature("web"):
		entries.append([7, "Quitter", "quitter", "Refermer l'Écluse."])
	var bubble := PanelContainer.new()
	var bs := sb(Color(0.03, 0.03, 0.04, 0.92), Color(0, 0, 0, 0), 6, 0, 8)
	bs.content_margin_left = 14
	bs.content_margin_right = 14
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := _label("", 15, INK)
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.custom_minimum_size = Vector2(300, 0)
	bubble.add_child(bl)
	bubble.visible = false
	overlay.add_child(bubble)
	var lib_btn: Button
	var first: Button
	for e in entries:
		var b := _bar_button(e[1], "menu_" + e[2], 470.0, 60.0, 26)
		b.add_theme_font_override("font", Fx.goth("pirataone"))
		b.add_theme_font_size_override("font_size", 32)
		var k: int = e[0]
		var info: String = e[3]
		b.pressed.connect(func(): picked.emit(k))
		var show_bubble := func() -> void:
			bl.text = info
			bubble.reset_size()
			var r := b.get_global_rect()
			var tw := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
			bubble.position = Vector2(r.position.x + 64 + tw + 24, r.position.y + (r.size.y - bubble.size.y) / 2.0)
			bubble.visible = true
		b.mouse_entered.connect(show_bubble)
		b.focus_entered.connect(show_bubble)
		b.mouse_exited.connect(func(): bubble.visible = false)
		col.add_child(b)
		if k == 1:
			lib_btn = b
		if first == null:
			first = b
	var cr := _shadowed(_label("Icônes : game-icons.net (Lorc, Delapouite et al., CC BY 3.0) · idéogrammes : KIE · polices : Fette Trump (D. Steffmann), Pirata One, New Rocker (OFL)", 11, DIM), 4)
	cr.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cr.position = Vector2(90, -34)
	overlay.add_child(cr)
	# un téléphone n'a que 720 de haut : la colonne (logo et entrées) se réduit pour tenir au-dessus des crédits
	var fit := func() -> void:
		var hh: float = col.get_combined_minimum_size().y
		var room: float = root.size.y - col.position.y - 44.0
		col.scale = Vector2.ONE * minf(1.0, room / maxf(hh, 1.0))
	fit.call_deferred()
	if Input.get_connected_joypads().size() > 0:
		first.grab_focus.call_deferred()
	var k := 0
	while true:
		k = await picked
		if k == 4:
			main.set_mobile(not big)
			return -1
		if k == 5:
			main.set_lang("fr" if Lang.on else "en")
			return -1
		if k == 7:
			get_tree().quit()
			return -1
		if k != 1:
			break
		bubble.visible = false
		overlay.visible = false
		await library_screen()
		overlay.visible = true
		lib_btn.text = "  Bibliothèque  %d / %d" % [main.cards_known(), Data.all_ids().size()]
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.4)
	await tw.finished
	_close_overlay()
	return k


func game_over(victory: bool, summary: String) -> void:
	await choose("L'ÉCLUSE EST TOMBÉE" if victory else "LA DESCENTE S'ACHÈVE", summary,
		[{"title": "Nouvelle descente", "glyph": "↻", "text": "Nouveaux traits, nouvelles salles.", "color": GOLD}])


# ------------------------------------------------------------------ vocation : l'explication

func card_back(holder: Control, rar: int, cls := "") -> void:
	## Dos de carte peint : une carte pas encore découverte, seules sa classe (le dos) et sa rareté (liseré et gemme) se devinent.
	var back := _panel(holder, sb(Color("#141216"), Data.RARITY_COL[rar].darkened(0.2 if rar > 1 else 0.45), 10, 2, 6))
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dos := "res://assets/ui/dos_%s.png" % cls
	if not ResourceLoader.exists(dos):
		dos = "res://assets/ui/dos_carte.png"
	if ResourceLoader.exists(dos):
		var tr := TextureRect.new()
		tr.texture = load(dos)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 3
		tr.offset_top = 3
		tr.offset_right = -3
		tr.offset_bottom = -3
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(tr)
		var gem := _shadowed(_label("✦" if rar >= 4 else "◆", 18, Data.RARITY_COL[rar], title_f), 4)
		gem.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		gem.position.y -= 30
		back.add_child(gem)
		return
	var q := _label("?", 48, Data.RARITY_COL[rar].darkened(0.3), title_f)
	q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_child(q)


func _fill_gear(list: VBoxContainer) -> void:
	## Bibliothèque : l'équipement par emplacement. Une pièce jamais obtenue ni vue reste une silhouette.
	for slot in Data.SLOTS:
		var ids: Array = Data.ITEMS.keys().filter(func(id): return Data.ITEMS[id].slot == slot)
		ids.sort_custom(func(a, b): return Data.ITEMS[a].rarity < Data.ITEMS[b].rarity)
		var known: int = ids.filter(func(id): return main.library.has("item:" + id)).size()
		var hd := _label("%s   %d / %d" % [Data.SLOT_NAME[slot], known, ids.size()], 22, GOLD.lightened(0.2), title_f)
		hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(hd)
		var flow := HFlowContainer.new()
		flow.alignment = FlowContainer.ALIGNMENT_CENTER
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(flow)
		for id in ids:
			var it: Dictionary = Data.ITEMS[id]
			var seen: bool = main.library.has("item:" + id)
			var tile := _vignette(it.name, Data.item_icon(id), Data.item_passives(id), ITEM_COL[it.rarity], Data.item_slot(id), seen, 150.0, "", Data.item_chips(id))
			tile.mouse_filter = Control.MOUSE_FILTER_PASS
			flow.add_child(tile)


func vocation_intro(h: Unit) -> void:
	## Premier palier de maîtrise : ce qui se passe, et les sept guildes que ce héros peut former.
	_close_overlay()
	last_n = 1
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	root.add_child(overlay)
	var opened := Time.get_ticks_msec()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var col: Color = Data.CLASS_COLOR[h.key]
	var tl := _title("MAÎTRISE II", 50)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label("%s a assez combattu pour apprendre une deuxième voie" % h.nm, 20, col.lightened(0.35), title_f), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var txt := RichTextLabel.new()
	txt.bbcode_enabled = true
	txt.fit_content = true
	txt.scroll_active = false
	txt.custom_minimum_size = Vector2(920, 0)
	txt.add_theme_font_size_override("normal_font_size", 16)
	txt.add_theme_color_override("default_color", INK)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.text = ("[center][color=#e3b45c]%s choisit une vocation[/color] : une deuxième classe.\n" +
		"Chaque paire de classes forme une [color=#e3b45c]guilde[/color], avec sa règle et ses cartes à elle.\n" +
		"Ses butins proposent aussi des cartes de sa vocation et de sa guilde.\n" +
		"Et plus il combat, plus la guilde se dévoile.[/center]") % h.nm
	var tc := CenterContainer.new()
	tc.add_child(txt)
	box.add_child(tc)
	var b := Button.new()
	b.text = "Voir les vocations"
	b.add_theme_font_override("font", title_f)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color("#2a1606"))
	b.add_theme_stylebox_override("normal", sb(GOLD, Color("#fff0c8"), 12, 2, 10))
	b.add_theme_stylebox_override("hover", sb(GOLD.lightened(0.18), Color("#fff6dc"), 12, 2, 12))
	b.add_theme_stylebox_override("pressed", sb(GOLD.darkened(0.15), Color("#fff0c8"), 12, 2, 4))
	b.add_theme_stylebox_override("focus", sb(GOLD.lightened(0.18), Color.WHITE, 12, 2, 12))
	b.custom_minimum_size = Vector2(300, 54)
	b.pressed.connect(func():
		if Time.get_ticks_msec() - opened > 300:
			picked.emit(0))
	var bc := CenterContainer.new()
	bc.add_child(b)
	box.add_child(bc)
	if Input.get_connected_joypads().size() > 0:
		b.grab_focus.call_deferred()
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.35)
	await picked
	_close_overlay()


func vocation_screen(h: Unit, picks: Array) -> int:
	## D'abord le héros qui monte, puis ses trois voies. Au survol d'une voie : le modèle hybride qui tourne,
	## la guilde, sa règle et la philosophie de la classe apprise.
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	root.add_child(overlay)
	var opened := Time.get_ticks_msec()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var col: Color = Data.CLASS_COLOR[h.key]
	var tl := _title("VOCATION · %s" % h.nm.to_upper(), 46)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	# 1. le héros qui a monté
	var hp := PanelContainer.new()
	var hs := sb(Color(0.07, 0.06, 0.07, 0.95), col, 12, 3, 12)
	hs.set_content_margin_all(16)
	hp.add_theme_stylebox_override("panel", hs)
	if encart(h.key):
		hp.add_theme_stylebox_override("panel", encart(h.key))
	hp.custom_minimum_size = Vector2(250, 0)
	row.add_child(hp)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hp.add_child(hv)
	var por := TextureRect.new()
	por.texture = load("res://assets/art/portrait_%s.png" % h.key)
	por.custom_minimum_size = Vector2(170, 170)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hv.add_child(por)
	for t in [[h.nm, 26, INK, title_f], ["Maîtrise II", 18, GOLD, title_f], [Data.HEROES[h.key].title, 14, col.lightened(0.35), null],
			["A assez combattu pour apprendre une deuxième classe. Choisis sa voie.", 14, INK, null]]:
		var l := _label(t[0], t[1], t[2], t[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 218
		hv.add_child(l)
	# 2. les trois voies
	var paths := VBoxContainer.new()
	paths.add_theme_constant_override("separation", 10)
	paths.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(paths)
	# 3. l'aperçu : modèle hybride et philosophie
	var pv := PanelContainer.new()
	var ps := sb(Color(0.06, 0.05, 0.06, 0.95), GOLD.darkened(0.3), 12, 2, 12)
	ps.set_content_margin_all(14)
	pv.add_theme_stylebox_override("panel", ps)
	pv.custom_minimum_size = Vector2(420, 0)
	row.add_child(pv)
	var pvv := VBoxContainer.new()
	pvv.add_theme_constant_override("separation", 6)
	pv.add_child(pvv)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(392, 240)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pvv.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.msaa_3d = Viewport.MSAA_4X
	svc.add_child(sv)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.82, 0.9)
	env.environment.ambient_light_energy = 0.9
	sv.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 35, 0)
	sun.light_energy = 1.6
	sv.add_child(sun)
	var cam3 := Camera3D.new()
	cam3.fov = 30.0
	sv.add_child(cam3)
	var pivot := Node3D.new()
	sv.add_child(pivot)
	var spin := pivot.create_tween().set_loops()
	spin.tween_property(pivot, "rotation:y", TAU, 7.0).from(0.0)
	var info := _rich("", 15, INK)
	info.custom_minimum_size = Vector2(392, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pvv.add_child(info)
	var ex_slot := VBoxContainer.new()  # trois cartes de la guilde, en miniature (en grand au survol)
	ex_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	pvv.add_child(ex_slot)
	var show := func(k: String) -> void:
		for ch in ex_slot.get_children():
			ch.queue_free()
		var ex_lbl := _label("Cartes de la guilde", 13, GOLD, title_f)
		ex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ex_slot.add_child(ex_lbl)
		ex_slot.add_child(mini_cards(main.guild_emblems(Guildes.index(h.key, k)), 0.4))
		for ch in pivot.get_children():
			ch.queue_free()
		var path := "res://assets/u_%s__%s.glb" % [h.key, k]
		if not ResourceLoader.exists(path):
			path = "res://assets/u_%s.glb" % k
		var inst: Node3D = load(path).instantiate()
		pivot.add_child(inst)
		var box3 := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = Board.material("glow_unit" if String(mi.name).ends_with("glow") else "unit")
			var bb: AABB = mi.get_aabb()
			box3 = bb if first else box3.merge(bb)
			first = false
		var ht: float = maxf(box3.size.y, 0.5)
		inst.position = Vector3(-box3.get_center().x, -box3.position.y, -box3.get_center().z)
		cam3.position = Vector3(0, ht * 0.6, ht * 2.2)
		cam3.look_at(Vector3(0, ht * 0.5, 0))
		var g := Guildes.index(h.key, k)
		var gl: Array = Guildes.LIST[g]
		pv.add_theme_stylebox_override("panel", encart(k) if encart(k) else ps)  # l'encart de la voie survolée
		var kc: Color = Data.CLASS_COLOR[k]
		info.text = "[center][font_size=22][color=#%s]%s + %s[/color][/font_size]\n[color=#e3b45c]Guilde : %s[/color] — %s[/center]\n%s\n\n[color=#%s]%s[/color]" % [
			kc.lightened(0.3).to_html(false), Data.HEROES[h.key].name, Data.HEROES[k].name, gl[2], gl[3], Guildes.DESC[g],
			DIM.to_html(false), Data.PHILO.get(k, Data.HEROES[k].role)]
	var btns: Array = []
	for n in picks.size():
		var k: String = picks[n]
		var kc: Color = Data.CLASS_COLOR[k]
		var b := Button.new()
		b.custom_minimum_size = Vector2(330, 108)
		b.add_theme_stylebox_override("normal", sb(Color(0.07, 0.06, 0.07, 0.95), kc.darkened(0.2), 12, 2, 8))
		b.add_theme_stylebox_override("hover", sb(kc.darkened(0.55), kc.lightened(0.3), 12, 3, 14))
		b.add_theme_stylebox_override("focus", sb(kc.darkened(0.55), Color.WHITE, 12, 3, 14))
		b.add_theme_stylebox_override("pressed", sb(kc.darkened(0.4), Color.WHITE, 12, 3, 6))
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 10
		hb.add_theme_constant_override("separation", 12)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hb)
		var pt := TextureRect.new()
		pt.texture = load("res://assets/art/portrait_%s.png" % k)
		pt.custom_minimum_size = Vector2(86, 86)
		pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(pt)
		var tv := VBoxContainer.new()
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(tv)
		tv.add_child(_label(Data.HEROES[k].name, 22, kc.lightened(0.35), title_f))
		var st := _label(Data.HEROES[k].title, 13, DIM)
		st.custom_minimum_size.x = 210
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(st)
		for c in [pt, tv]:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nn := n
		b.mouse_entered.connect(func(): show.call(k))
		b.focus_entered.connect(func(): show.call(k))
		b.pressed.connect(func():
			if Time.get_ticks_msec() - opened > 1200:
				picked.emit(nn))
		b.modulate.a = 0.0
		paths.add_child(b)
		btns.append(b)
	show.call(picks[0])
	# le héros d'abord, les voies ensuite
	overlay.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.35)
	pv.modulate.a = 0.0
	tw.tween_interval(0.5)
	for b in btns:
		tw.tween_property(b, "modulate:a", 1.0, 0.18)
	tw.tween_property(pv, "modulate:a", 1.0, 0.25)
	if Input.get_connected_joypads().size() > 0:
		btns[0].grab_focus.call_deferred()
	var i: int = await picked
	_close_overlay()
	return i


# ------------------------------------------------------------------ bibliothèque

func library_screen() -> void:
	## Toutes les cartes : celles déjà croisées s'affichent, les autres restent des dos de carte.
	if lib_layer and is_instance_valid(lib_layer):
		return
	lib_layer = Control.new()
	lib_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lib_layer.z_index = 120  # au-dessus des choix et du menu de pause
	root.add_child(lib_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lib_layer.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 24
	box.offset_bottom = -24
	box.add_theme_constant_override("separation", 10)
	lib_layer.add_child(box)
	var total: int = Data.all_ids().size()
	var tl := _title("BIBLIOTHÈQUE", 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label("%d / %d cartes découvertes · clic sur une carte : ses trois niveaux" % [main.cards_known(), total], 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	box.add_child(body)
	var tabs := VBoxContainer.new()  # onglets à la verticale, à gauche
	tabs.add_theme_constant_override("separation", 10)
	body.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	sc.add_child(list)
	var fill := func(which: String) -> void:
		for ch in list.get_children():
			ch.queue_free()
		var sections: Array = []
		if which == "bestiaire":
			_fill_bestiary(list)
			return
		if which == "equipement":
			_fill_gear(list)
			return
		if which == "reliques":
			var ids: Array = Data.RELICS.keys()
			var known: int = ids.filter(func(r): return main.library.has("relic:" + r)).size()
			var hd := _label("Reliques   %d / %d" % [known, ids.size()], 22, GOLD.lightened(0.2), title_f)
			hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			list.add_child(hd)
			var flow := HFlowContainer.new()
			flow.alignment = FlowContainer.ALIGNMENT_CENTER
			flow.add_theme_constant_override("h_separation", 10)
			flow.add_theme_constant_override("v_separation", 10)
			flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_child(flow)
			for r in ids:
				flow.add_child(_vignette(Data.RELICS[r].name, "res://assets/ui/relic_%s.png" % r, Data.RELICS[r].text, GOLD, Data.RELIC_TIERS[Data.RELICS[r].tier], main.library.has("relic:" + r), 150.0, Data.RELICS[r].glyph))
			return
		if which == "classes":
			for k in Data.HEROES:
				var ids: Array = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].owner == k)
				ids.sort_custom(func(a, b): return Data.CARDS[a].rar < Data.CARDS[b].rar)
				sections.append([Data.HEROES[k].name, Data.HEROES[k].role, Data.CLASS_COLOR[k], ids])
		else:
			for g in Guildes.LIST.size():
				var gl: Array = Guildes.LIST[g]
				var ids: Array = Guildes.cards_of(g)
				ids.sort_custom(func(a, b): return Guildes.CARDS[a].rar < Guildes.CARDS[b].rar)
				sections.append(["%s  ·  %s + %s" % [gl[2], Data.HEROES[gl[0]].name, Data.HEROES[gl[1]].name], gl[3], Data.CLASS_COLOR[gl[0]], ids])
		for sec in sections:
			var known: int = sec[3].filter(func(id): return main.library.has(id)).size()
			var hd := _label("%s   %d / %d" % [sec[0], known, sec[3].size()], 22, (sec[2] as Color).lightened(0.35), title_f)
			hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			list.add_child(hd)
			var rl := _label(sec[1], 14, DIM)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			list.add_child(rl)
			var flow := HFlowContainer.new()
			flow.alignment = FlowContainer.ALIGNMENT_CENTER
			flow.add_theme_constant_override("h_separation", 10)
			flow.add_theme_constant_override("v_separation", 10)
			flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_child(flow)
			for id in sec[3]:
				var holder := Control.new()
				holder.custom_minimum_size = CARD * 0.8
				if main.library.has(id):
					var w := make_card({"id": id, "lvl": 1})
					w.scale = Vector2.ONE * 0.8
					w.pivot_offset = Vector2.ZERO
					holder.tooltip_text = ""  # les encarts de mots-clés s'affichent au survol ; clic : les trois niveaux
					_passthrough(w)
					holder.add_child(w)
					holder.mouse_filter = Control.MOUSE_FILTER_STOP
					holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					var cid: String = id
					holder.gui_input.connect(func(e):
						if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT or e is InputEventScreenTouch and e.pressed:
							_lib_focus(cid))
				else:
					var dd := Data.def(id)
					var rar: int = dd.get("rar", 1)
					card_back(holder, rar, "objet" if dd.has("tool") else str(dd.get("owner", "")))
					holder.tooltip_text = "%s à découvrir" % Data.RARITY_NAME[rar]
				flow.add_child(holder)
	for t in [["Classes", "classes"], ["Guildes", "guildes"], ["Équipement", "equipement"], ["Reliques", "reliques"], ["Bestiaire", "bestiaire"]]:
		var tb := _bar_button(t[0], "tab_" + t[1], 250.0, 52.0, 18)
		var which: String = t[1]
		tb.pressed.connect(func(): fill.call(which))
		tabs.add_child(tb)
	var close := Button.new()
	close.text = "Fermer"
	close.flat = true
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_color_override("font_color", DIM)
	close.pressed.connect(func(): lib_closed.emit())
	close.custom_minimum_size = Vector2(250, 40)
	tabs.add_child(close)
	fill.call("classes")
	await lib_closed
	lib_layer.queue_free()
	lib_layer = null


func _lib_focus(id: String) -> void:
	## Une carte en grand avec ses trois niveaux, même ceux qu'on n'a jamais forgés.
	var fl := Control.new()
	fl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lib_layer.add_child(fl)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fl.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(box)
	var d := Data.def(id)
	var tl := _title(d.name, 38)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	# le niveau 3 d'une carte-objet est un secret : absent tant qu'on ne l'a pas forgé
	var top: int = 2 if d.has("tool") and not main.library.has(id + "#3") else Data.MAX_LVL
	var sl := _shadowed(_label("%s · les niveaux de la forge" % Data.RARITY_NAME[d.get("rar", 1)], 16, Data.RARITY_COL[d.get("rar", 1)]), 5)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var k := minf(1.35, (root.size.y - 260.0) / CARD.y)
	var prev := {}
	for lv in range(1, top + 1):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var hl := _shadowed(_label("Niveau %d" % lv, 20, GOLD if lv > 1 else DIM, title_f), 5)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(hl)
		var holder := Control.new()
		holder.custom_minimum_size = CARD * k
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ci := {"id": id, "lvl": lv}
		var w := make_card(ci)
		w.scale = Vector2.ONE * k
		w.pivot_offset = Vector2.ZERO
		_passthrough(w)
		holder.add_child(w)
		col.add_child(holder)
		var diff := Data.upgrade_diff(prev, ci) if lv > 1 else ""
		var dl := _label(diff, 14, Color("#bfe8a8"))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(CARD.x * k, 0)
		col.add_child(dl)
		prev = ci
	var hint := _label("clic : retour", 14, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	fl.modulate.a = 0.0
	create_tween().tween_property(fl, "modulate:a", 1.0, 0.18)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed or e is InputEventScreenTouch and e.pressed:
			fl.queue_free())


func _fill_bestiary(list: VBoxContainer) -> void:
	## Seulement les ennemis déjà croisés : les autres n'existent pas encore pour le joueur.
	var seen: Array = Data.FOES.keys().filter(func(k): return main.bestiary.has(k))
	var hd := _label("%d ennemis rencontrés" % seen.size() if seen.size() > 0 else "Aucun ennemi croisé pour l'instant", 22, GOLD, title_f)
	hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(hd)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(flow)
	for k in seen:
		var f: Dictionary = Data.FOES[k]
		var boss: bool = f.has("titre")
		var p := PanelContainer.new()
		var st := sb(Color(0.07, 0.06, 0.065, 0.92), Color("#ffb070") if boss else Color("#c9463a").darkened(0.2), 12, 2 if boss else 1, 6)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 10
		st.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", st)
		p.custom_minimum_size = Vector2(430, 0)
		flow.add_child(p)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		p.add_child(hb)
		var por := TextureRect.new()
		var pp := "res://assets/art/foe_%s.png" % k
		if ResourceLoader.exists(pp):
			por.texture = load(pp)
		por.custom_minimum_size = Vector2(120, 120)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hb.add_child(por)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(v)
		v.add_child(_label(f.name, 20, INK, title_f))
		var rg: Array = f.get("range", [1, 1])
		var stats := "PV %d · dégâts %d · portée %s · vitesse %d · déplacement %d" % [f.hp, f.dmg, str(rg[1]) if rg[0] == rg[1] else "%d-%d" % [rg[0], rg[1]], f.speed, f.move]
		if f.get("armor", 0) > 0:
			stats += " · armure %d" % f.armor
		v.add_child(_label(stats, 13, GOLD))
		var txt: String = f.get("ligne", "")
		for q in f.get("passives", []):
			if Data.PASSIVES.has(q):
				txt += ("\n" if txt != "" else "") + "%s : %s" % [Data.PASSIVES[q].name, Data.PASSIVES[q].text]
		if Data.FOE_TIPS.has(k):
			txt += ("\n" if txt != "" else "") + Data.FOE_TIPS[k]
		var tx := _label(txt, 13, INK)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.custom_minimum_size = Vector2(270, 0)
		v.add_child(tx)


# ------------------------------------------------------------------ équipement

const ITEM_COL := [GOLD, Color("#8fa3b8"), Color("#6fb0e0"), Color("#d08aff"), Color("#ff8a3d")]


func _gear_tile(id: String, sz: int, col: Color) -> PanelContainer:
	var t := PanelContainer.new()
	t.custom_minimum_size = Vector2(sz, sz)
	t.add_theme_stylebox_override("panel", sb(Color(0.05, 0.045, 0.05, 0.95), col, 10, 2, 4))
	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if id != "":
		ic.texture = load(Data.item_icon(id))
	t.add_child(ic)
	t.pivot_offset = Vector2(sz, sz) / 2
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	t.mouse_entered.connect(func(): create_tween().tween_property(t, "scale", Vector2.ONE * 1.08, 0.1))
	t.mouse_exited.connect(func(): create_tween().tween_property(t, "scale", Vector2.ONE, 0.1))
	return t


func _clicked(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT


func equipment_screen(heroes: Array, bag: Array) -> Dictionary:
	## Héros et emplacements en haut, sac en dessous, fiche de l'objet survolé en bas.
	## Un objet du sac puis un héros : équipe. Un emplacement occupé : retire. Rend {} pour fermer.
	_close_overlay()
	last_n = 0  # le pilote de test ferme l'écran
	_eq_act = {}
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	root.add_child(overlay)
	var opened := Time.get_ticks_msec()
	var act := func(d: Dictionary) -> void:
		if Time.get_ticks_msec() - opened > 300:  # le clic de l'écran précédent ne compte pas
			_eq_act = d
			picked.emit(0)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var tl := _title("ÉQUIPEMENT", 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label(("Touchez un objet pour lire son effet, puis un héros pour l'équiper" if big else "Survolez pour lire l'effet · un objet du sac, puis un héros") + " · un emplacement occupé se vide d'un clic", 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)

	# fiche de l'objet survolé (construite plus bas, remplie au survol)
	var card := PanelContainer.new()
	var cs := sb(Color(0.08, 0.07, 0.075, 0.94), GOLD.darkened(0.4), 12, 2, 10)
	cs.content_margin_left = 22
	cs.content_margin_right = 22
	cs.content_margin_top = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)
	card.custom_minimum_size = Vector2(760, 124)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 18)
	ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(ch)
	var c_icon := TextureRect.new()
	c_icon.custom_minimum_size = Vector2(92, 92)
	c_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ch.add_child(c_icon)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ch.add_child(cv)
	var c_name := _label("", 22, INK, title_f)
	cv.add_child(c_name)
	var c_kind := _label("", 13, DIM)
	cv.add_child(c_kind)
	var c_fx := _rich("", 15, INK)
	c_fx.custom_minimum_size = Vector2(600, 0)
	cv.add_child(c_fx)
	var show := func(id: String, note := "") -> void:
		if id == "":
			c_icon.texture = null
			c_name.text = "Survolez un objet"
			c_name.add_theme_color_override("font_color", DIM)
			c_kind.text = note
			c_fx.text = ""
			return
		var it: Dictionary = Data.ITEMS[id]
		c_icon.texture = load(Data.item_icon(id))
		c_name.text = it.name
		c_name.add_theme_color_override("font_color", ITEM_COL[it.rarity].lightened(0.25))
		var lines: PackedStringArray = Data.item_text(id).split("\n")
		c_kind.text = "%s · %s%s" % [lines[0], ("Mythique" if it.rarity == 4 else Data.RARITY_NAME[it.rarity]), ("  ·  " + note) if note != "" else ""]
		var fx: Array = []
		for part in lines[1].split(" · "):
			var kv := part.split(" : ", true, 1)
			fx.append(("[color=#e3b45c]%s[/color] : %s" % [kv[0], kv[1]]) if kv.size() == 2 else "[color=#e3b45c]%s[/color]" % part)
		c_fx.text = "\n".join(fx)

	# héros et leurs deux emplacements
	var sel := [-1]  # index de l'objet du sac choisi
	var hero_panels: Array = []
	var hrow := HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", 22)
	box.add_child(hrow)
	for hi in heroes.size():
		var h: Unit = heroes[hi]
		var col: Color = Data.CLASS_COLOR[h.key]
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(300, 0)
		var ps := sb(Color(0.08, 0.07, 0.075, 0.92), col, 14, 2, 12)
		ps.content_margin_left = 16
		ps.content_margin_right = 16
		ps.content_margin_top = 14
		ps.content_margin_bottom = 14
		p.add_theme_stylebox_override("panel", ps)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)
		# la poupée : le héros en pied au centre, arme et armure à gauche, bottes et bijou à droite
		var nm := _label(h.nm, 24, col.lightened(0.35), title_f)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var tr := _label(Data.TRAITS[h.trait_id].name if Data.TRAITS.has(h.trait_id) else "", 13, col.lightened(0.5))
		tr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(tr)
		var doll := HBoxContainer.new()
		doll.alignment = BoxContainer.ALIGNMENT_CENTER
		doll.add_theme_constant_override("separation", 6)
		doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(doll)
		var cols: Array = []
		for k in 2:
			var cv2 := VBoxContainer.new()
			cv2.alignment = BoxContainer.ALIGNMENT_CENTER
			cv2.add_theme_constant_override("separation", 10)
			cv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cols.append(cv2)
		var fig := TextureRect.new()
		var fp := "res://assets/art/figure_%s.png" % h.key
		fig.texture = load(fp) if ResourceLoader.exists(fp) else load("res://assets/art/portrait_%s.png" % h.key)
		fig.custom_minimum_size = Vector2(120, 180) if big else Vector2(150, 225)
		fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		doll.add_child(cols[0])
		doll.add_child(fig)
		doll.add_child(cols[1])
		const GHOST := {"arme": "epee", "armure": "plastron", "bottes": "bottes", "bijou": "amulette"}
		for si in Data.SLOTS.size():
			var slot: String = Data.SLOTS[si]
			var id: String = h.equip.get(slot, "")
			var cap: String = Data.SLOT_NAME[slot]
			var sv := VBoxContainer.new()
			sv.add_theme_constant_override("separation", 2)
			sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var t := _gear_tile(id, 60, ITEM_COL[Data.ITEMS[id].rarity] if id != "" else DIM.darkened(0.5))
			if id == "":
				# emplacement libre : l'ombre de ce qu'il attend
				var gh := TextureRect.new()
				gh.texture = load("res://assets/ui/gear_%s.png" % GHOST[slot])
				gh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				gh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				gh.modulate = Color(1, 1, 1, 0.18)
				gh.mouse_filter = Control.MOUSE_FILTER_IGNORE
				t.add_child(gh)
			t.mouse_entered.connect(func():
				if id != "":
					show.call(id, "porté par %s · clic : retour au sac" % h.nm)
				else:
					show.call("", "%s de %s : libre" % [cap, h.nm]))
			t.gui_input.connect(func(e):
				if _clicked(e):
					t.accept_event()
					if sel[0] >= 0:
						act.call({"equip": sel[0], "hero": hi})
					elif id != "":
						act.call({"unequip": slot, "hero": hi}))
			sv.add_child(t)
			var sl2 := _label(cap if id == "" else Data.ITEMS[id].name, 12, DIM if id == "" else ITEM_COL[Data.ITEMS[id].rarity].lightened(0.3))
			sl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sl2.custom_minimum_size.x = 76
			sl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sv.add_child(sl2)
			cols[0 if si < 2 else 1].add_child(sv)
		var st := HBoxContainer.new()
		st.alignment = BoxContainer.ALIGNMENT_CENTER
		st.add_theme_constant_override("separation", 12)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		st.add_child(_chip("pv", "%d/%d" % [h.hp, h.max_hp], Color.WHITE, 20))
		st.add_child(_chip("deplacement", str(h.move), Color.WHITE, 20))
		st.add_child(_chip("attaque", "+%d" % h.gear_dmg(), Color(1.0, 0.75, 0.6), 20))
		var ex := _label("saut %d · vit. %d" % [h.jump, h.speed], 14, DIM)
		ex.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		st.add_child(ex)
		v.add_child(st)
		p.gui_input.connect(func(e):
			if _clicked(e) and sel[0] >= 0:
				act.call({"equip": sel[0], "hero": hi}))
		hero_panels.append(p)
		hrow.add_child(p)

	# le sac
	var bl := _shadowed(_label("SAC · %d objet%s" % [bag.size(), "s" if bag.size() > 1 else ""], 18, INK, title_f), 6)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(bl)
	var brow := HFlowContainer.new()
	brow.alignment = FlowContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("h_separation", 12)
	brow.add_theme_constant_override("v_separation", 12)
	brow.custom_minimum_size = Vector2(1100, 0)
	var bc := CenterContainer.new()
	bc.add_child(brow)
	box.add_child(bc)
	var bag_tiles: Array = []
	var refresh_sel := func() -> void:
		# l'objet choisi s'allume ; les héros qui ne peuvent pas le porter s'éteignent
		for i in bag_tiles.size():
			bag_tiles[i].modulate = Color(1.3, 1.2, 0.9) if i == sel[0] else (Color(0.7, 0.7, 0.75) if sel[0] >= 0 else Color.WHITE)
		for i in hero_panels.size():
			var ok: bool = true  # tout se porte par tout le monde
			hero_panels[i].modulate = Color.WHITE if ok else Color(0.4, 0.4, 0.45)
			hero_panels[i].mouse_filter = Control.MOUSE_FILTER_STOP if ok else Control.MOUSE_FILTER_IGNORE
	if bag.is_empty():
		brow.add_child(_label("Le sac est vide : coffres, élites et marchand le rempliront.", 15, DIM))
	for bi in bag.size():
		var id: String = bag[bi]
		var it: Dictionary = Data.ITEMS[id]
		var t := _gear_tile(id, 76, ITEM_COL[it.rarity])
		var fits: Array = heroes
		t.mouse_entered.connect(func():
			show.call(id, ("pour " + ", ".join(fits.map(func(u): return u.nm))) if fits.size() > 0 else "personne ici ne sait s'en servir"))
		t.gui_input.connect(func(e):
			if _clicked(e):
				t.accept_event()
				if fits.is_empty():
					return
				if fits.size() == 1 and not big:  # au doigt, le premier toucher sert à lire
					act.call({"equip": bi, "hero": heroes.find(fits[0])})  # un seul porteur possible : directement
					return
				sel[0] = -1 if sel[0] == bi else bi
				refresh_sel.call())
		t.set_meta("tuto", "bag%d" % bi)
		bag_tiles.append(t)
		brow.add_child(t)
	var cc := CenterContainer.new()
	cc.add_child(card)
	box.add_child(cc)
	show.call("")
	var done := Button.new()
	done.text = "Terminer"
	done.add_theme_font_override("font", title_f)
	done.add_theme_font_size_override("font_size", 20)
	done.add_theme_color_override("font_color", INK)
	done.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.94), GOLD.darkened(0.2), 10, 2, 8))
	done.add_theme_stylebox_override("hover", sb(Color(0.2, 0.16, 0.1, 0.96), GOLD, 10, 2, 8))
	done.custom_minimum_size = Vector2(260, 50)
	done.set_meta("tuto", "done")
	done.pressed.connect(func(): act.call({}))
	var dc := CenterContainer.new()
	dc.add_child(done)
	box.add_child(dc)
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.2)
	await picked
	_close_overlay()
	return _eq_act


# ------------------------------------------------------------------ roulette des traits

func trait_roulette(keys: Array, traits: Array) -> void:
	## Chaque héros fait défiler les traits comme un rouleau de machine à sous ; ils s'arrêtent l'un après l'autre.
	_close_overlay()
	last_n = 1
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	var tl := _title("TRAITS", 44)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tl)
	var sl := _shadowed(_label("Chacun arrive avec son caractère : un don, un défaut, parfois les deux", 16, GOLD), 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	box.add_child(row)
	const ROW_H := 56.0
	var all: Array = Data.TRAITS.keys()
	var done := [0]
	for hi in keys.size():
		var k: String = keys[hi]
		var col: Color = Data.CLASS_COLOR[k]
		var p := PanelContainer.new()
		var ps := sb(Color(0.08, 0.07, 0.075, 0.94), col, 14, 2, 12)
		ps.content_margin_left = 18
		ps.content_margin_right = 18
		ps.content_margin_top = 16
		ps.content_margin_bottom = 16
		p.add_theme_stylebox_override("panel", ps)
		p.custom_minimum_size = Vector2(300, 0)
		row.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		p.add_child(v)
		var por := TextureRect.new()
		por.texture = load("res://assets/art/portrait_%s.png" % k)
		por.custom_minimum_size = Vector2(96, 96)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(por)
		var nm := _label(Data.HEROES[k].name, 24, col.lightened(0.35), title_f)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		# la fenêtre du rouleau : une ligne visible, bordée d'or
		var win := Panel.new()
		win.custom_minimum_size = Vector2(260, ROW_H)
		win.clip_contents = true
		win.add_theme_stylebox_override("panel", sb(Color(0.03, 0.025, 0.03, 1.0), GOLD.darkened(0.2), 8, 2, 0))
		v.add_child(win)
		var strip := VBoxContainer.new()
		strip.add_theme_constant_override("separation", 0)
		win.add_child(strip)
		var n := 22 + hi * 7
		var seq: Array = []
		for j in n:
			seq.append(all[(j * 7 + hi * 3) % all.size()])
		seq.append(traits[hi])
		for t in seq:
			var l := _label(Data.TRAITS[t].name, 24, INK, Fx.goth("pirataone"))
			l.custom_minimum_size = Vector2(260, ROW_H)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			strip.add_child(l)
		var txt := _label(" ", 15, DIM)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(260, 44)
		v.add_child(txt)
		var tw := strip.create_tween()  # meurt avec l'écran si on le ferme avant l'arrêt
		tw.tween_property(strip, "position:y", -ROW_H * n, 1.4 + 0.6 * hi).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		var last: Label = strip.get_child(n)
		var t_id: String = traits[hi]
		tw.tween_callback(func():
			last.add_theme_color_override("font_color", GOLD.lightened(0.2))
			txt.text = Data.TRAITS[t_id].text
			txt.add_theme_color_override("font_color", INK)
			var pop := win.create_tween()
			win.pivot_offset = win.size / 2
			pop.tween_property(win, "scale", Vector2.ONE * 1.1, 0.08)
			pop.tween_property(win, "scale", Vector2.ONE, 0.15)
			done[0] += 1)
	var go := Button.new()
	go.text = "Continuer"
	go.add_theme_font_override("font", title_f)
	go.add_theme_font_size_override("font_size", 20)
	go.add_theme_color_override("font_color", INK)
	go.add_theme_stylebox_override("normal", sb(Color(0.1, 0.09, 0.1, 0.94), GOLD.darkened(0.2), 10, 2, 8))
	go.add_theme_stylebox_override("hover", sb(Color(0.2, 0.16, 0.1, 0.96), GOLD, 10, 2, 8))
	go.custom_minimum_size = Vector2(260, 50)
	go.pressed.connect(func():
		if done[0] >= keys.size():
			picked.emit(0))
	var gc := CenterContainer.new()
	gc.add_child(go)
	box.add_child(gc)
	await picked
	_close_overlay()


# ------------------------------------------------------------------ fiche du héros

var sheet_layer: Control
func hero_sheet(h: Unit) -> void:
	## Lecture seule, par-dessus tout : portrait, stats, trait, vocation, les quatre pièces avec leurs effets. Un clic ferme.
	if sheet_layer and is_instance_valid(sheet_layer):
		sheet_layer.queue_free()
	sheet_layer = Control.new()
	sheet_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_layer.z_index = 110
	root.add_child(sheet_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_layer.add_child(dim)
	var close := func(e):
		if e is InputEventMouseButton and e.pressed:
			sheet_layer.queue_free()
			sheet_layer = null
	dim.gui_input.connect(close)
	var col: Color = Data.CLASS_COLOR[h.key]
	var p := PanelContainer.new()
	var ps := sb(Color(0.08, 0.07, 0.075, 0.97), col, 16, 2, 16)
	ps.content_margin_left = 26
	ps.content_margin_right = 26
	ps.content_margin_top = 22
	ps.content_margin_bottom = 22
	p.add_theme_stylebox_override("panel", ps)
	p.gui_input.connect(close)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet_layer.add_child(cc)
	cc.add_child(p)
	var both := HBoxContainer.new()
	both.add_theme_constant_override("separation", 22)
	both.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(both)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	both.add_child(v)
	# son paquet, en petit, à droite : ce qu'on ajoute se juge face à ce qu'on a
	var mine: Array = main.deck.filter(func(ci): return Data.holder(ci) == h.key)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	both.add_child(dv)
	dv.add_child(_label("Paquet · %d cartes" % mine.size(), 17, col.lightened(0.35), title_f))
	var dsc := ScrollContainer.new()
	dsc.custom_minimum_size = Vector2(CARD.x * 0.42 * 4 + 24, minf(560.0, root.size.y - 180.0))
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dv.add_child(dsc)
	var dg := GridContainer.new()
	dg.columns = 4
	dg.add_theme_constant_override("h_separation", 6)
	dg.add_theme_constant_override("v_separation", 6)
	dsc.add_child(dg)
	for ci in mine:
		var hold := Control.new()
		hold.custom_minimum_size = CARD * 0.42
		var mc := make_card(ci)
		mc.scale = Vector2.ONE * 0.42
		mc.pivot_offset = Vector2.ZERO
		_passthrough(mc)
		hold.add_child(mc)
		hold.set_meta("kwcard", ci)
		dg.add_child(hold)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	v.add_child(top)
	var por := TextureRect.new()
	por.texture = load("res://assets/art/portrait_%s.png" % h.key)
	por.custom_minimum_size = Vector2(110, 110)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(por)
	var nv := VBoxContainer.new()
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(nv)
	nv.add_child(_label(h.nm, 30, col.lightened(0.35), Fx.goth("pirataone")))
	nv.add_child(_label(Data.HEROES[h.key].title, 15, DIM))
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 14)
	st.add_child(_chip("pv", "%d/%d" % [h.hp, h.max_hp], Color.WHITE, 22))
	st.add_child(_chip("deplacement", str(h.move), Color.WHITE, 22))
	st.add_child(_chip("attaque", "+%d" % h.gear_dmg(), Color(1.0, 0.75, 0.6), 22))
	st.add_child(_chip("armure", "+%d" % h.block0(), Color(0.8, 0.9, 1.0), 22))
	var sj := _label("saut %d · vitesse %d" % [h.jump, h.speed], 14, DIM)
	sj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	st.add_child(sj)
	nv.add_child(st)
	var tr := _rich("[color=#e3b45c]Trait — %s[/color] : %s" % [Data.TRAITS[h.trait_id].name, Data.TRAITS[h.trait_id].text], 15, INK)
	tr.text = tr.text.trim_prefix("[center]").trim_suffix("[/center]")
	tr.custom_minimum_size = Vector2(560, 0)
	v.add_child(tr)
	v.add_child(_label(main.voc_line(h) if h.voc != "" else "Pas encore de vocation · %d / %d points de job" % [h.pj, Data.MASTERY[2]], 14, DIM))
	for slot in Data.SLOTS:
		var id: String = h.equip.get(slot, "")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var t := _gear_tile(id, 56, ITEM_COL[Data.ITEMS[id].rarity] if id != "" else DIM.darkened(0.5))
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(t)
		var rv := VBoxContainer.new()
		rv.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(rv)
		if id == "":
			rv.add_child(_label("%s : libre" % Data.SLOT_NAME[slot], 16, DIM))
		else:
			var it: Dictionary = Data.ITEMS[id]
			rv.add_child(_label("%s — %s" % [Data.SLOT_NAME[slot], it.name], 17, ITEM_COL[it.rarity].lightened(0.25), title_f))
			var fx := _label(Data.item_text(id).split("\n")[1], 14, INK)
			fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fx.custom_minimum_size = Vector2(480, 0)
			rv.add_child(fx)
		v.add_child(row)
	var hint := _label("Clic pour fermer · l'équipement se change hors combat (carte d'étage, repos, I)", 12, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)


# ------------------------------------------------------------------ barre de boss (spec ennemis du 26/09)

func _boss_bars(boss: Unit) -> void:
	## Grelin, le Gardien : une barre à son nom. Les Amarreurs : deux barres liées, une par tête.
	boss_bar.visible = boss != null
	if boss == null:
		return
	var bn: Label = boss_bar.get_child(1)
	var bb: ProgressBar = boss_bar.get_meta("bar")
	var pair: Array = battle.foes.filter(func(o): return o.data.get("titre", "") == boss.data.titre)
	bn.text = boss.data.titre if pair.size() < 2 else " · ".join(pair.map(func(o): return "%s %d" % [o.nm.split(",")[0], maxi(0, o.hp)]))
	bb.max_value = boss.max_hp
	bb.value = boss.hp
	var b2: ProgressBar = boss_bar.get_meta("bar2") if boss_bar.has_meta("bar2") else null
	if pair.size() >= 2:
		if b2 == null:
			b2 = bb.duplicate()
			boss_bar.add_child(b2)
			boss_bar.set_meta("bar2", b2)
		b2.visible = true
		bb.max_value = pair[0].max_hp
		bb.value = maxi(0, pair[0].hp)
		b2.max_value = pair[1].max_hp
		b2.value = maxi(0, pair[1].hp)
	elif b2:
		b2.visible = false
