class_name Unit
extends Node3D
## Un héros ou un ennemi : stats, modèle voxel, animations procédurales.

var key: String
var side: String          # "hero" | "foe"
var nm: String
var data: Dictionary
var hp := 10
var max_hp := 10
var block := 0
var move := 3
var jump := 2
var fly := false
var cell := Vector2i.ZERO
var facing := Vector2i(0, 1)
var poison := 0
var taunt := false
var moved := false
var trait_id := ""
var equip := {"arme": "", "armure": "", "bottes": "", "bijou": ""}
var base_move := 3
var base_jump := 2
var base_hp := 10
var struck := false       # a déjà frappé ce tour (Deux mains)
var affix := ""
var mark := 0              # tours restants : +50 % de dégâts reçus
var root := 0              # tours restants : ne bouge plus
var combo := 0             # coups portés ce tour (Moine)
var ambush := false        # prochain coup compté de dos (Embuscade)
var dmg_bonus := 0
var extra_armor := 0
var extra_passives: Array = []
var turns := 0
var card_id := ""           # porteur de carte : la carte qu'il garde
var card_cond := ""         # fuite | vite | eau | piege | marque : comment la gagner
var flee_n := 0             # fuyard : tours passés à fuir
var speed := 5              # initiative : les plus rapides jouent d'abord
var tool := ""             # objet porté (ennemis) : utilisé parfois, volable, lâché en tombant
var alive := true
var companion := false
var walked := false          # a marché ce tour (Ancré)
var teles := 0               # téléportations et bonds ce tour (Bondi)
var trap_seen := 0           # pièges déclenchés vus à la fin de son dernier tour (Déclic)
var blastproof := false      # les explosions lui donnent de l'armure au lieu de le blesser
var bpm := 0                 # BPM : monte à chaque carte jouée, les cartes Drop le dépensent       # bête apprivoisée : joue seule, du côté des héros
# vocation (classe secondaire à la FFT) : points de job, paliers de maîtrise
var voc := ""
var voc2 := ""               # Blason écartelé : une deuxième vocation
var pj := 0
var legend_seen := {}        # guilde -> légendaire déjà proposée
# états de combat des cartes de guilde, remis à zéro à chaque combat
var aegis := false         # Égide : le prochain coup ne fait rien
var bait := false          # Appât : qui le frappe s'expose
var exposed := false       # le prochain coup reçu compte de dos
var parry := false
var dodge_next := false    # Iframe
var boomguard := 0         # Pavois piégé
var bph := 0               # armure par coup ce tour
var keep_block := false
var inner := 0             # Braise intérieure
var tele := false          # s'est téléporté ce tour
var hits := 0              # coups portés ce tour, toutes classes
var triple := false        # Just frame
var lvl_next := false      # Geste technique
var fuse := 0              # Burn-out
var stick := 0             # charge collée (ennemi)
var bounty := false        # Avis de recherche (ennemi)
var struck_hero := false   # a frappé un héros depuis... (Whiff punish)
var pushed := false        # repoussé ce tour
var rage := 0             # Berserk : bonus aux coups gagné en perdant des PV
var q40 := false           # Règle des 40 % déjà servie


var voc_node: Node3D


func wear_voc(k: String) -> void:
	## L'insigne de la vocation, porté dans le dos : la classe apprise se voit sur le modèle.
	if voc_node:
		voc_node.queue_free()
		voc_node = null
	if side == "hero" and model:
		# le héros de guilde (gen_guildes.py) : un modèle à part entière, l'insigne ferait doublon
		var hy := "res://assets/u_%s__%s.glb" % [key, k]
		var guilde := k != "" and ResourceLoader.exists(hy)
		_load_body(hy if guilde else "res://assets/u_%s.glb" % key)
		if guilde:
			return
	if k == "" or not ResourceLoader.exists("res://assets/voc_%s.glb" % k):
		return
	voc_node = load("res://assets/voc_%s.glb" % k).instantiate()
	var vc: Color = Data.CLASS_COLOR[k]
	for mi in voc_node.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = Board.material("glow_unit" if String(mi.name).ends_with("glow") else "unit")
		mi.set_instance_shader_parameter("rim", Vector3(vc.r, vc.g, vc.b) * 0.9)  # liseré à la couleur de la classe apprise
	voc_node.scale = Vector3.ONE * 1.4  # dépasse des épaules : lisible de face comme de dos
	voc_node.position = Vector3(0, -0.12, 0.05)
	model.add_child(voc_node)


var _body: Node3D
var anim: AnimationPlayer  # modèle HD animé ; null pour les modèles voxel rigides


var _hand: Node3D  # os de la main droite du modèle HD : le bâton suit sa position, pas sa rotation
var _staff_k := 1.0


func _grip(inst: Node3D, old_path: String) -> void:
	## Le modèle HD vient les mains vides : on prend l'arme du modèle voxel d'origine et on la met dans la main droite.
	if not ResourceLoader.exists(old_path):
		return
	var sks := inst.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	var sk: Skeleton3D = sks[0]
	var bi := -1
	for n in ["mixamorig:RightHand", "mixamorig_RightHand"]:
		if bi < 0:
			bi = sk.find_bone(n)
	var old: Node3D = load(old_path).instantiate()
	var w: Node3D = old.find_child(key + "_weapon", true, false)
	if bi < 0 or w == null:
		old.free()
		return
	w.get_parent().remove_child(w)
	old.free()
	weapon = w
	var ba := BoneAttachment3D.new()
	ba.bone_name = sk.get_bone_name(bi)
	sk.add_child(ba)
	inst.add_child(w)
	_hand = ba
	_staff_k = 0.55


func _follow_hand() -> void:
	## Bâton droit, un peu penché vers l'avant, tenu à la hauteur de la main.
	if _hand == null or weapon == null:
		return
	var h := _hand.global_position
	var side := h - model.global_position
	side.y = 0.0
	weapon.global_position = h + side.normalized() * 0.12 * bs  # écarté du corps : visible de face
	weapon.global_basis = model.global_basis.orthonormalized() * Basis.from_euler(Vector3(-0.18, 0, -0.1)) * Basis.from_scale(Vector3.ONE * _staff_k * bs)


func play(n: String, speed := 1.0) -> bool:
	## Joue une animation du modèle HD puis revient au repos ; false si le modèle n'en a pas.
	if anim == null or not anim.has_animation(n):
		return false
	anim.play(n, 0.12, speed)
	if n != "walk" and n != "death":
		anim.queue("idle")
	return true


func ring_color(c: Color) -> void:
	ring.material_override.set_shader_parameter("col", c)


func _load_body(path: String) -> void:
	## Modèle voxel du corps ; la vocation le remplace par sa version hybride.
	if _body:
		_body.queue_free()
		for mi in _meshes:
			mi.material_overlay = null
	_meshes.clear()
	_xmats.clear()
	_hand = null
	# PC ultra : modèle voxel fin riggé et animé (blender/voxeliser_rig.py), s'il existe
	var hdp := "res://assets/hd/" + path.get_file()
	if Board.hd and ResourceLoader.exists(hdp):
		path = hdp
	var inst: Node3D = load(path).instantiate()
	_body = inst
	model.add_child(inst)
	anim = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		for n in ["idle", "walk"]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		anim.play("idle")
		if inst.find_child(key + "_weapon", true, false) == null:
			_grip(inst, "res://assets/" + path.get_file())
	weapon = inst.find_child(key + "_weapon", true, false)
	if weapon == null and data.has("model"):
		weapon = inst.find_child(str(data.model) + "_weapon", true, false)
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).ends_with("glow"):
			mi.material_override = Board.material("glow_unit")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			mi.material_override = Board.material("unit")
			var col: Color = Data.CLASS_COLOR.get(key, Color(1.0, 0.3, 0.15))
			_xmats.append(_xray(col if side == "hero" else Color(1.0, 0.35, 0.2)))
			# liseré de contour : sur le voxel fin animé, il s'allume sur chaque petite face de biais et fait du bruit
			var rk := 0.0 if anim else 1.0
			mi.set_instance_shader_parameter("rim", (Vector3(0.55, 0.75, 1.0) * 0.3 if side == "hero" else Vector3(col.r, col.g, col.b) * 0.2) * rk)
			_meshes.append(mi)
			if String(mi.name).ends_with("_body"):
				head = (1.75 if anim else mi.get_aabb().end.y) * bs + 0.35


func reset_fight() -> void:
	for k in ["aegis", "bait", "exposed", "parry", "dodge_next", "keep_block", "tele", "triple", "lvl_next", "bounty", "struck_hero", "pushed", "q40", "walked"]:
		set(k, false)
	for k in ["boomguard", "bph", "inner", "hits", "fuse", "stick", "teles", "bpm", "rage"]:
		set(k, 0)

var model: Node3D
var weapon: Node3D
var ring: MeshInstance3D
var _meshes: Array = []
var _xmats: Array = []
var _phase := randf() * TAU
var _yaw := 0.0
var _busy := false
var bs := 1.35      # échelle du modèle
var head := 2.0     # hauteur de l'étiquette au-dessus des pieds


func setup(k: String, s: String) -> void:
	key = k
	side = s
	data = Data.HEROES[k] if s == "hero" else Data.FOES[k]
	nm = data.name
	max_hp = data.hp
	hp = max_hp
	move = data.move
	jump = data.jump
	speed = data.get("speed", 5)
	fly = data.get("fly", false)
	base_move = move
	base_jump = jump
	base_hp = max_hp
	model = Node3D.new()
	add_child(model)
	bs = {"gardien": 0.85, "husk": 1.2, "guetteur": 1.15, "carapace": 1.1, "rodeur": 0.85, "wisp": 0.9,
		"frondeur": 1.1, "tenant": 1.05, "pisteuse": 0.95, "eclusier_fou": 1.05, "fouisseur": 1.1}.get(k, 1.0)
	model.scale = Vector3.ONE * bs
	# nouveaux ennemis : un modèle proche en attendant le leur (data.model)
	var body := "res://assets/u_%s.glb" % k
	if not ResourceLoader.exists(body) and data.has("model"):
		body = "res://assets/u_%s.glb" % data.model
	_load_body(body)
	if k == "fanal":
		var fl := OmniLight3D.new()  # la lanterne : s'éteint avec lui (l'unité morte est cachée)
		fl.light_color = Color(1.0, 0.7, 0.36)
		fl.light_energy = 2.2
		fl.omni_range = 3.5
		fl.position.y = 1.6
		add_child(fl)
	if k == "wisp":
		var wl := OmniLight3D.new()
		wl.light_color = Color(1.0, 0.55, 0.2)
		wl.light_energy = 1.6
		wl.omni_range = 1.8
		wl.position.y = 0.6
		add_child(wl)
	# anneau au sol : or pour les héros, braise pour les ennemis
	ring = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0) * {"gardien": 2.0, "grelin": 1.5, "hale": 1.5, "brasse": 1.5, "chevrier": 1.5, "dame": 1.5, "brule_haie": 1.5}.get(k, 1.0)
	q.orientation = PlaneMesh.FACE_Y
	ring.mesh = q
	var m := ShaderMaterial.new()
	m.shader = _ring_shader()
	m.set_shader_parameter("col", Color(1.0, 0.8, 0.4) if s == "hero" else Color(1.0, 0.35, 0.2))
	ring.material_override = m
	ring.position.y = 0.015
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


static var _xs: Shader
static func _xray(col: Color) -> ShaderMaterial:
	## Silhouette visible seulement là où le décor cache l'unité.
	if _xs == null:
		_xs = Shader.new()
		_xs.code = """shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 col : source_color;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
void fragment(){
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	discard;  // WebGL : pas de profondeur lisible, pas de silhouette
#endif
	// seulement si un obstacle se tient nettement devant (pas l'unité elle-même)
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	if (v.z - VERTEX.z < 0.7) {
		discard;
	}
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = col.rgb * 1.4;
	ALPHA = 0.12 + f * 0.75;
}"""
	var m := ShaderMaterial.new()
	m.shader = _xs
	m.set_shader_parameter("col", col)
	m.render_priority = 5
	return m


static var _rs: Shader
static func _ring_shader() -> Shader:
	if _rs == null:
		_rs = Shader.new()
		_rs.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 col : source_color;
uniform float sel = 0.0;
void fragment(){
	float d = length(UV - 0.5) * 2.0;
	float r = smoothstep(0.62, 0.8, d) * (1.0 - smoothstep(0.84, 0.98, d));
	float fill = (1.0 - smoothstep(0.0, 0.8, d)) * 0.25;
	ALBEDO = col.rgb * (r * (0.9 + sel * 1.6) + fill * (0.4 + sel));
}"""
	return _rs


func passives() -> Array:
	var out: Array = data.get("passives", []).duplicate() + extra_passives
	for slot in equip:
		var id: String = equip[slot]
		for pk in ["passive", "passive2"]:
			if id != "" and Data.ITEMS[id].get(pk, "") != "":
				out.append(Data.ITEMS[id][pk])
	return out


func has_p(p: String) -> bool:
	return passives().has(p)


func gear_dmg() -> int:
	var d := 0
	for slot in equip:
		if equip[slot] != "":
			d += int(Data.ITEMS[equip[slot]].get("dmg", 0))
	return d


func apply_gear() -> void:
	## Recalcule les stats dérivées de l'équipement ; les PV suivent le nouveau maximum.
	fix_equip()
	move = base_move + int(has_p("deplacement"))
	if side == "hero":
		speed = int(data.get("speed", 5)) + (3 if trait_id == "vif" else 0)
	jump = base_jump + 2 * int(has_p("saut"))
	for slot in equip:
		if equip[slot] != "":
			move += int(Data.ITEMS[equip[slot]].get("move", 0))
			jump += int(Data.ITEMS[equip[slot]].get("jump", 0))
	var old := max_hp
	max_hp = base_hp
	for slot in equip:
		if equip[slot] != "":
			max_hp += int(Data.ITEMS[equip[slot]].get("hp", 0))
	hp = clampi(hp + max_hp - old, 1, max_hp)


func fix_equip() -> void:
	## Sauvegardes d'avant le 26/09 : l'ancien « talisman » rejoint son nouvel emplacement.
	if equip.has("talisman"):
		var t: String = equip.talisman
		equip.erase("talisman")
		if t != "" and Data.ITEMS.has(t):
			equip[Data.ITEMS[t].slot] = t
	for s in Data.SLOTS:
		if not equip.has(s):
			equip[s] = ""
	for s in equip:
		if equip[s] != "" and not Data.ITEMS.has(equip[s]):
			equip[s] = ""


func block0() -> int:
	var b := 0
	for slot in equip:
		if equip[slot] != "":
			b += int(Data.ITEMS[equip[slot]].get("block0", 0))
	return b


func atk() -> int:
	## Dégâts d'un ennemi, adoucis aux premiers étages.
	return maxi(1, int(round((data.get("dmg", 0) + dmg_bonus) * Battle.foe_mult)) + Battle.foe_bonus)


func make_champion(a: String) -> void:
	## Ennemi rare : plus de PV, un affixe, anneau doré et gabarit un peu plus grand.
	affix = a
	nm = "%s %s" % [nm, Data.AFFIXES[a].name]
	max_hp = int(max_hp * 1.4)
	hp = max_hp
	match a:
		"blinde":
			extra_armor = 5
		"enrage":
			dmg_bonus = 3
		"veloce":
			move += 2
			jump += 1
			speed += 2
		"epineux":
			extra_passives.append("contre")
	bs *= 1.12
	model.scale = Vector3.ONE * bs
	head *= 1.12
	(ring.material_override as ShaderMaterial).set_shader_parameter("col", Color(1.0, 0.8, 0.25))


func set_xray(on: bool) -> void:
	## Silhouette à travers le décor, seulement pour l'unité active ou ciblée.
	for i in _meshes.size():
		_meshes[i].material_overlay = _xmats[i] if on else null


func dodge() -> void:
	var tw := create_tween()
	var p := model.position
	tw.tween_property(model, "position", p + Vector3(0.25, 0.1, 0), 0.08)
	tw.tween_property(model, "position", p, 0.15)


func set_selected(on: bool) -> void:
	(ring.material_override as ShaderMaterial).set_shader_parameter("sel", 1.0 if on else 0.0)


func place(c: Vector2i, board: Board) -> void:
	cell = c
	position = board.world(c)


func face(d: Vector2i) -> void:
	if d == Vector2i.ZERO:
		return
	if absi(d.x) > absi(d.y):
		facing = Vector2i(signi(d.x), 0)
	else:
		facing = Vector2i(0, signi(d.y))


func _process(dt: float) -> void:
	if not alive:
		return
	_follow_hand()
	var target := atan2(float(facing.x), float(facing.y))
	_yaw = lerp_angle(_yaw, target, 1.0 - exp(-dt * 12.0))
	model.rotation.y = _yaw
	var t := Time.get_ticks_msec() / 1000.0
	if not _busy and anim == null:
		model.scale.y = bs * (1.0 + sin(t * 2.4 + _phase) * 0.018)
		if fly:
			model.position.y = 0.35 + sin(t * 2.0 + _phase) * 0.12
			model.rotation.z = sin(t * 1.3 + _phase) * 0.08
		else:
			model.position.y = 0.0
			model.scale = Vector3(bs, bs * (1.0 + sin(t * 2.4 + _phase) * 0.018), bs)
		if weapon:
			weapon.rotation.x = sin(t * 1.7 + _phase) * 0.05


# ------------------------------------------------------------------ animations

func walk(path: Array, board: Board) -> void:
	_busy = true
	play("walk", 2.0)
	for c in path:
		var a := position
		var b := board.world(c)
		face(c - cell)
		cell = c
		var tw := create_tween()
		var arc := (0.0 if anim else 0.18) + absf(b.y - a.y) * 0.6
		tw.tween_method(func(k: float): position = a.lerp(b, k) + Vector3(0, sin(k * PI) * arc, 0), 0.0, 1.0, 0.17)
		await tw.finished
	play("idle")
	_busy = false


func teleport(c: Vector2i, board: Board) -> void:
	_busy = true
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(0.05, 1.6, 0.05) * bs, 0.12)
	await tw.finished
	place(c, board)
	tw = create_tween()
	tw.tween_property(model, "scale", Vector3.ONE * bs, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_busy = false


func lunge(toward: Vector3) -> void:
	_busy = true
	var base := position
	var dir := (toward - base)
	dir.y = 0
	dir = dir.normalized() * 0.38
	var tw := create_tween()
	tw.tween_property(self, "position", base - dir * 0.3, 0.1).set_trans(Tween.TRANS_SINE)
	if weapon:
		tw.parallel().tween_property(weapon, "rotation:x", 1.1, 0.1)
	tw.tween_property(self, "position", base + dir, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if weapon:
		tw.parallel().tween_property(weapon, "rotation:x", -1.9, 0.08)
	await tw.finished
	var back := create_tween()
	back.tween_property(self, "position", base, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if weapon:
		back.parallel().tween_property(weapon, "rotation:x", 0.0, 0.3)
	back.finished.connect(func(): _busy = false)


func cast() -> void:
	_busy = true
	if play("cast", 1.8):
		await get_tree().create_timer(0.5).timeout
		_busy = false
		return
	var tw := create_tween()
	tw.tween_property(model, "position:y", 0.25, 0.14).set_trans(Tween.TRANS_SINE)
	if weapon:
		tw.parallel().tween_property(weapon, "rotation:x", -0.9, 0.14)
	tw.tween_property(model, "position:y", 0.0, 0.2)
	if weapon:
		tw.parallel().tween_property(weapon, "rotation:x", 0.0, 0.2)
	await get_tree().create_timer(0.14).timeout
	tw.finished.connect(func(): _busy = false)


func hurt() -> void:
	play("hit", 1.6)
	var tw := create_tween()
	tw.tween_method(_set_flash, 0.65, 0.0, 0.2)
	var s := create_tween()
	var p := model.position
	for i in 4:
		s.tween_property(model, "position", p + Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06)), 0.03)
	s.tween_property(model, "position", p, 0.04)


func _set_flash(v: float) -> void:
	for mi in _meshes:
		mi.set_instance_shader_parameter("flash", v)


func die() -> void:
	alive = false
	_busy = true
	ring.visible = false
	if play("death", 2.0):
		await get_tree().create_timer(2.2).timeout
		visible = false
		return
	var tw := create_tween()
	tw.tween_property(model, "rotation:x", -1.4 if not fly else 0.0, 0.35).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(model, "position:y", -0.1, 0.35)
	tw.tween_property(model, "scale", Vector3(1.2, 0.02, 1.2) * bs, 0.25)
	await tw.finished
	visible = false


func revive() -> void:
	alive = true
	visible = true
	ring.visible = true
	_busy = false
	model.rotation = Vector3.ZERO
	model.scale = Vector3.ONE * bs
	model.position = Vector3.ZERO
	play("idle")
