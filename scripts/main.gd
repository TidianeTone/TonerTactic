extends Node3D
## Monde (lumière, caméra), boucle de run, entrées, mode capture pour le critique.

const ROOMS_PER_FLOOR := 8
const CENTER := Vector3(7.5, 1.2, 7.5)

var ui: UI
var battle: Battle
var board: Board
var units_root: Node3D
var ambient_root: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var cam_attr: CameraAttributesPractical

var yaw := 45.0
var pitch := 38.0
var dist := 24.0
var target := CENTER
var _yaw := 45.0
var _pitch := 38.0
var _dist := 24.0
var _target := CENTER
var _focus = null
var _shake := 0.0
var _punch := 1.0
var hover = null
var _fu_last: Unit          # unité de la frise survolée à l'image précédente
var quality := 1
var orbit := false
var pad := false            # la manette a la main : le curseur ne suit plus la souris
var _pad_rep := 0.0
var _rmb_drag := 0.0

var heroes: Array = []
var deck: Array = []
var relics: Array = []
var floor_i := 1
var step := 0
var run_seed := 0
var fights := 0
var gold := 0
var bag: Array = []
var run_start := 0
var next_arch := ""
var next_obj := "kill"
var floor_biomes: Array = []
var party: Array = ["garde", "lame", "oracle"]
var leader: Unit            # pion du mode aventure
var mode := "descente"      # "descente" (carte d'étage) | "aventure" (exploration)
var voc_start := true      # réglage : le premier Ancien propose toujours la Vocation (une run différente dès le départ)
var tactic := false         # vue tactique (réglage) : arènes plates en damier, pour la lisibilité seulement
var elites_seen: Array = []  # "étage:élite" déjà affrontées
var fight_loot: Array = []   # ce que le combat en cours a rapporté (écran de fin de combat)
var aboard: Board           # le donjon du mode aventure, gardé à part de l'arène
var adv_root: Node3D
var rooms: Array = []       # salles du donjon : {rect, type, cell, ids, arch, mods, done, seen, node, fog}
var exploring := false
var _adv_busy := false
var _adv_hover = null
var _fog_mat: StandardMaterial3D
var followers: Array = []
var trail: Array = []       # dernières cases du chef, que les compagnons reprennent
signal floor_done(result: String)
static var difficulty := 1   # index dans Data.DIFFICULTY ; retenu d'une run à l'autre
var pacts: Array = []
var next_mods: Array = []
var pending_mods: Array = []  # imposés par un événement au prochain combat
var fmap: Array = []        # carte de l'étage : étapes -> nœuds {type, arch, obj, links, desc}
var lane := -1
var visited: Array = []
var args := {}
static var _globals_ready := false
var rng := RandomNumberGenerator.new()
var _music: Array = []      # deux lecteurs pour le fondu enchaîné
var _music_kind := ""
var _mute := false
var mobile := false        # mode portable : interface agrandie, gestes tactiles, rendu allégé (user://reglages.cfg)
var _touches := {}         # doigts posés : index -> position
var _tap_drag := 0.0       # chemin parcouru par le doigt depuis qu'il s'est posé
var music_vol := 0.6        # 0 à 1, réglé dans le menu Échap et gardé dans user://reglages.cfg
var library := {}           # cartes découvertes, gardées dans user://bibliotheque.cfg
var bestiary := {}          # ennemis rencontrés (bestiaire), même fichier
var _lib_dirty := false
var pending_cards: Array = []  # cartes gagnées en combat (porteurs, coffres), offertes après
var tuto := false  # run d'initiation : points de job ×3, ni sauvegarde ni carte d'étage
var voc_intro_done := false  # l'explication de la vocation déjà montrée pendant cette run
var seen_mech := {}  # mécaniques ennemies déjà vues pendant la run : leur texte ne s'affiche en grand qu'une fois


func _exit_tree() -> void:
	Lang.teardown()


func _ready() -> void:
	if not _globals_ready:  # déjà déclarés si la scène est rechargée après un abandon
		_globals_ready = true
		RenderingServer.global_shader_parameter_add("cut_dir", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(0.7, 0.7))
		RenderingServer.global_shader_parameter_add("cut_center", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(7.5, 7.5))
		RenderingServer.global_shader_parameter_add("cut_half", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 8.0)
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Lang.setup(_read_lang() == "en")
	Engine.time_scale = 1.0  # global au moteur : un ralenti (hitstop) coupé par un rechargement de scène figerait la suivante
	if args.has("party"):
		party = Array(args.party.split(","))
	if args.has("difficulty"):
		difficulty = clampi(int(args.difficulty) - 1, 0, 4)
	_load_library()
	mobile = _read_mobile()
	UI.big = mobile
	if mobile:
		# base plus petite : tout grossit d'un quart sur un téléphone en paysage (20:9 -> 1600 x 720)
		get_window().content_scale_size = Vector2i(1440, 720)
		quality = 0
	Fx.lite = mobile  # tablette et téléphone : ni particules, ni vent, ni bloom, ombres légères
	if mobile:
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
	_setup_world()
	board = Board.new()
	add_child(board)
	units_root = Node3D.new()
	add_child(units_root)
	ambient_root = Node3D.new()
	add_child(ambient_root)
	battle = Battle.new()
	battle.main = self
	battle.board = board
	battle.units_root = units_root
	add_child(battle)
	ui = UI.new()
	ui.main = self
	if args.has("handk"):
		ui.hand_k = float(args.handk)
	ui.battle = battle
	add_child(ui)
	battle.changed.connect(ui.refresh)
	if args.has("quality"):
		quality = int(args.quality)
	_apply_quality()
	if args.has("autoplay"):
		_autoplay.call_deferred()
	elif args.has("uitest"):
		_uitest.call_deferred()
	elif args.has("advtest"):
		_advtest.call_deferred()
	elif args.has("cardtest"):
		_cardtest.call_deferred()
	elif args.has("voctest"):
		_voctest.call_deferred()
	elif args.has("looktest"):
		_looktest.call_deferred()
	elif args.has("hdtest"):
		_hdtest.call_deferred()
	elif args.has("haventest"):
		_haventest.call_deferred()
	elif args.has("eventtest"):
		_eventtest.call_deferred()
	elif args.has("savetest"):
		_savetest.call_deferred()
	elif args.has("maptest"):
		_maptest.call_deferred()
	elif args.has("tutotest"):
		_tutotest.call_deferred()
	elif args.has("tuto2run"):
		_tuto2run.call_deferred()
	elif args.has("uxtest"):
		_uxtest.call_deferred()
	elif args.has("cardsheet"):
		_cardsheet.call_deferred()
	elif args.has("capture"):
		_capture.call_deferred()
	else:
		_title.call_deferred()


# ------------------------------------------------------------------ monde

func _setup_world() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://reglages.cfg") == OK:
		music_vol = float(cf.get_value("son", "musique", music_vol))
		tactic = bool(cf.get_value("ecran", "tactique", false))
		voc_start = bool(cf.get_value("partie", "vocation", true))
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		add_child(mp)
		_music.append(mp)
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = not mobile
	env.glow_intensity = 0.8
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_radius = 0.8
	env.ssao_intensity = 2.4
	env.ssao_power = 1.6
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 26.0
	env.fog_depth_end = 80.0
	env.fog_height = 0.7
	env.fog_height_density = 0.35
	env.fog_sun_scatter = 0.3
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_amount = 0.05
	we.camera_attributes = cam_attr
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_blur = 1.3
	sun.shadow_bias = 0.04
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.shadow_enabled = false
	moon.light_specular = 0.3
	add_child(moon)
	cam = Camera3D.new()
	cam.fov = 30
	cam.far = 250
	add_child(cam)
	cam.current = true


func apply_biome(b: Dictionary) -> void:
	var sm: ProceduralSkyMaterial = env.sky.sky_material
	sm.sky_top_color = b.sky_top
	sm.sky_horizon_color = b.sky_hor
	sm.ground_horizon_color = b.sky_hor
	sm.ground_bottom_color = b.water_deep
	env.ambient_light_energy = b.ambient
	env.fog_light_color = b.fog
	env.fog_density = 0.45 if quality >= 2 else 0.85
	env.volumetric_fog_albedo = b.fog
	sun.light_color = b.sun
	sun.light_energy = b.sun_energy
	sun.rotation_degrees = Vector3(-b.sun_elev, b.sun_az, 0)
	moon.visible = b.has("moon")
	if b.has("moon"):
		moon.light_color = b.moon
		moon.light_energy = 0.7
		moon.rotation_degrees = Vector3(-40, b.sun_az + 180.0, 0)


func _apply_quality() -> void:
	## 0 portable, 1 normal, 2 ultra
	Board.hd = quality >= 2 and not OS.has_feature("web") and args.get("hd", "1") != "0"
	env.ssao_enabled = quality >= 1
	env.ssil_enabled = quality >= 2
	env.sdfgi_enabled = quality >= 2
	env.volumetric_fog_enabled = quality >= 2
	# ultra : air limpide et rayons de soleil plutôt que voile laiteux, creux plus sombres, lumière qui tranche
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_anisotropy = 0.7
	env.volumetric_fog_length = 48.0
	env.ssao_intensity = 3.2 if quality >= 2 else 2.4
	env.ssil_intensity = 1.4
	env.sdfgi_energy = 1.2
	env.adjustment_contrast = 1.14 if quality >= 2 else 1.05
	env.adjustment_saturation = 1.16 if quality >= 2 else 1.1
	env.fog_density = 0.45 if quality >= 2 else 0.85
	cam_attr.dof_blur_far_enabled = quality >= 1
	cam_attr.dof_blur_near_enabled = quality >= 1
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if quality == 0 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality == 0 else Viewport.MSAA_2X
	get_viewport().scaling_3d_scale = (0.6 if mobile else 0.8) if quality == 0 else 1.0


func focus(p) -> void:
	_focus = p


func shake(a: float) -> void:
	_shake = maxf(_shake, a)


func hitstop(t: float) -> void:
	if Engine.time_scale > 1.0:  # auto-jeu accéléré : pas de ralenti (il remettait la vitesse à 1)
		return
	Engine.time_scale = 0.06
	await get_tree().create_timer(t, true, false, true).timeout
	Engine.time_scale = 1.0


func punch(p: Vector3) -> void:
	## Recadre brièvement sur l'échange de coups.
	_focus = p
	_punch = 0.82
	await get_tree().create_timer(0.9).timeout
	_punch = 1.0
	if not battle.player_turn:
		return
	_focus = null


# ------------------------------------------------------------------ caméra et entrées

func _process(dt: float) -> void:
	if orbit:
		yaw += dt * 3.0
	var k := 1.0 - exp(-dt * 7.0)
	_yaw = lerpf(_yaw, yaw, k)
	_pitch = lerpf(_pitch, pitch, k)
	_dist = lerpf(_dist, dist * _punch, k)
	var goal: Vector3 = target if _focus == null else target.lerp(_focus, 0.35 if _punch == 1.0 else 0.6)
	_target = _target.lerp(goal, 1.0 - exp(-dt * 3.0))
	_place_cam()
	if _shake > 0.0:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.12
		_shake = maxf(0.0, _shake - dt * 2.2)
	_free_cam(dt)
	_pad_process(dt)
	_feed_units()
	if exploring:
		_adv_process(dt)
	# frise d'initiative : survoler (ou toucher) une unité revient à la survoler sur le plateau
	var fu: Unit = ui.frieze_unit if ui else null
	if fu and not (is_instance_valid(fu) and fu.alive and (mobile or ui.frieze.get_global_rect().has_point(get_viewport().get_mouse_position()))):
		fu = null  # la frise se reconstruit sans prévenir de la sortie de la souris
		ui.frieze_unit = null
	if fu != _fu_last:
		if _fu_last and is_instance_valid(_fu_last):
			_fu_last.set_xray(false)
		if fu:
			fu.set_xray(true)
		_fu_last = fu
		ui._refresh_frieze()
		if fu and mobile:  # au doigt : la case reste désignée, la surbrillance de la frise s'en va
			hover = fu.cell
			refresh_hover()
			ui.frieze_unit = null
	if ui and ui.hud.visible and not args.has("capture") and not pad and not mobile and not ui.menu_open():
		var mp := get_viewport().get_mouse_position()
		var h = fu.cell if fu else (null if ui.over_hand(mp) else _pick(cam.project_ray_origin(mp), cam.project_ray_normal(mp)))
		if h != hover:
			hover = h
			refresh_hover()


func _pick(from: Vector3, dir: Vector3) -> Variant:
	## La case visée : la dalle touchée, ou le volume d'un objet ou d'une unité posé devant
	## (survoler le coffre lui-même, pas la dalle derrière lui).
	var best = board.pick(from, dir)
	var bt := INF
	if best != null:
		bt = from.distance_to(board.world(best))
	var solids: Array = battle.prop_nodes.keys() + battle.loot.keys() + battle.oaks.keys()
	for u in battle.heroes + battle.foes:
		if u.alive:
			solids.append(u.cell)
	for c in solids:
		var base := board.world(c)
		var hit = AABB(base + Vector3(-0.42, 0.0, -0.42), Vector3(0.84, 1.5, 0.84)).intersects_ray(from, dir)
		if hit != null and from.distance_to(hit) < bt:
			bt = from.distance_to(hit)
			best = c
	return best


func _place_cam() -> void:
	var yr := deg_to_rad(_yaw)
	var pr := deg_to_rad(_pitch)
	cam.position = _target + Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr)) * _dist
	cam.look_at(_target)
	# le plateau se cadre dans la zone libre : au-dessus de la main, à droite des portraits
	cam.v_offset = -0.06 * _dist if ui.hud.visible else 0.0
	cam.h_offset = -0.09 * _dist if ui.hud.visible else 0.0
	var cd := Vector2(sin(yr), cos(yr))
	RenderingServer.global_shader_parameter_set("cut_dir", cd)
	cam_attr.dof_blur_far_distance = _dist + 8.0
	cam_attr.dof_blur_far_transition = 12.0
	cam_attr.dof_blur_near_distance = maxf(1.0, _dist - 9.0)
	cam_attr.dof_blur_near_transition = 5.0


func _snap_cam() -> void:
	_yaw = yaw
	_pitch = pitch
	_dist = dist
	_target = target
	_place_cam()


func refresh_hover() -> void:
	battle.refresh_highlight(hover)
	ui.set_tip(battle.preview(hover))
	var look: Unit = battle.inspect if battle.inspect and battle.inspect.alive else null
	if look == null and hover != null:
		look = battle.unit_at(hover)
	ui.set_sheet(look)
	var carried := ""
	if look and look.side == "foe" and look.tool != "":
		carried = look.tool
	elif hover != null and battle.loot.has(hover):
		carried = battle.loot[hover][0]
	ui.show_item(carried, (ui.sheet_plate.position.y + ui.sheet_plate.size.y) if ui.sheet_plate.visible else 100.0)
	ui._sync_tags()


func _feed_units() -> void:
	## Donne au décor la position des unités, pour qu'il s'efface devant elles.
	var arr := PackedVector4Array()
	var list: Array = (battle.heroes + battle.foes) if ui.hud.visible else []
	for u in list:
		if is_instance_valid(u) and u.alive and arr.size() < 16:
			var p: Vector3 = u.global_position + Vector3(0, 0.75, 0)
			arr.append(Vector4(p.x, p.y, p.z, 1.0))
	if leader and is_instance_valid(leader) and leader.visible and arr.size() < 16:
		var lp := leader.global_position + Vector3(0, 0.75, 0)
		arr.append(Vector4(lp.x, lp.y, lp.z, 1.0))
	while arr.size() < 16:
		arr.append(Vector4.ZERO)
	for k in ["stone", "foliage"]:
		var m: ShaderMaterial = Board.material(k)
		m.set_shader_parameter("units", arr)
		m.set_shader_parameter("unit_n", mini(16, list.size() + (1 if leader and is_instance_valid(leader) and leader.visible else 0)))


func abandon() -> void:
	## Retour à l'écran titre : la scène repart de zéro, la sauvegarde avec.
	_clear_save()
	get_tree().reload_current_scene()


func _free_cam(dt: float) -> void:
	## Clic droit maintenu : ZQSD (ou WASD) déplace la caméra.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or ui.menu_open():
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1
	if v != Vector2.ZERO:
		_pan(v.normalized() * dt * 900.0)


func _pan(rel: Vector2) -> void:
	var yr := deg_to_rad(_yaw)
	var right := Vector3(cos(yr), 0, -sin(yr))
	var fwd := Vector3(sin(yr), 0, cos(yr))
	target += (right * rel.x + fwd * rel.y) * _dist * 0.0016
	var bd: Board = aboard if exploring else board  # le donjon est bien plus grand que l'arène
	target = target.clamp(Vector3(-3, 0, -3), Vector3(bd.dim + 2, 4, bd.dim + 2))


var _pad_rest := {}
func _axis(a: JoyAxis) -> float:
	## Valeur d'un axe par rapport à son repos : dans le navigateur, les gâchettes au repos
	## ne valent pas toujours 0, ce qui faisait zoomer et tourner la caméra toute seule.
	var v := Input.get_joy_axis(0, a)
	if not _pad_rest.has(a):
		_pad_rest[a] = v
	return v - float(_pad_rest[a])


func _pad_process(dt: float) -> void:
	## Manette Xbox : stick gauche / croix = curseur de case, stick droit = caméra, gâchettes = zoom.
	if Input.get_connected_joypads().is_empty() or ui.menu_open() or not ui.hud.visible or ui.overlay != null:
		return
	var r := Vector2(_axis(JOY_AXIS_RIGHT_X), _axis(JOY_AXIS_RIGHT_Y))
	if r.length() > 0.2:
		yaw -= r.x * dt * 140.0
		pitch = clampf(pitch + r.y * dt * 70.0, 12.0, 82.0)
	var z := _axis(JOY_AXIS_TRIGGER_RIGHT) - _axis(JOY_AXIS_TRIGGER_LEFT)
	if absf(z) > 0.2:
		dist = clampf(dist - z * dt * 30.0, 7.0, 60.0)
	var v := Vector2(_axis(JOY_AXIS_LEFT_X), _axis(JOY_AXIS_LEFT_Y))
	if v.length() < 0.5:
		v = Vector2.ZERO
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		v.x = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		v.x = 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		v.y = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		v.y = 1
	_pad_rep -= dt
	if v == Vector2.ZERO:
		_pad_rep = 0.0
		return
	if _pad_rep > 0.0:
		return
	_pad_rep = 0.17
	pad = true
	# axes de la grille tournés avec la caméra (droite = +x, haut = -z vu de 45°)
	var yr := deg_to_rad(_yaw - 45.0)
	var w := Vector2(cos(yr), -sin(yr)) * v.x - Vector2(sin(yr), cos(yr)) * -v.y
	var st := Vector2i(int(signf(w.x)), 0) if absf(w.x) >= absf(w.y) else Vector2i(0, int(signf(w.y)))
	var cur: Vector2i = hover if hover != null else (battle.selected.cell if battle.selected else heroes[0].cell)
	var nx := Vector2i(clampi(cur.x + st.x, 0, board.dim - 1), clampi(cur.y + st.y, 0, board.dim - 1))
	hover = nx
	var wp := board.world(nx)
	target = target.lerp(Vector3(wp.x, target.y, wp.z), 0.35)
	refresh_hover()


func _pad_button(b: int) -> void:
	match b:
		JOY_BUTTON_A:
			if hover != null:
				battle.click(hover)
		JOY_BUTTON_B:
			battle.cancel()
		JOY_BUTTON_X:
			battle.end_turn()
		JOY_BUTTON_Y:
			if hover != null:
				battle.toggle_inspect(battle.unit_at(hover))
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			var n := battle.hand.size()
			if n > 0:
				var s := 1 if b == JOY_BUTTON_RIGHT_SHOULDER else -1
				var i := posmod((battle.card_sel if battle.card_sel >= 0 else (-1 if s > 0 else 0)) + s, n)
				battle.select_card(i)
		JOY_BUTTON_BACK:
			if battle.active:
				battle.select(battle.active)


func _unhandled_input(e: InputEvent) -> void:
	var esc: bool = (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE) \
		or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START)
	if esc:
		if ui.sheet_layer and is_instance_valid(ui.sheet_layer):
			ui.sheet_layer.queue_free()
			ui.sheet_layer = null
		elif ui.lib_layer and is_instance_valid(ui.lib_layer):
			ui.lib_closed.emit()
		elif ui.overlay != null and ui.skip_ok and not ui.menu_open():
			ui.picked.emit(-1)  # Échap ferme l'écran (paquet, défausse, choix qu'on peut passer) au lieu d'ouvrir la pause
		elif ui.menu_open() or not (battle.card_sel >= 0 or battle.inspect):
			ui.toggle_menu()
		else:
			battle.cancel()
		return
	if ui.menu_open() or ui.overlay != null or ui.lib_layer != null:
		return
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch(e)
		return
	if mobile and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		# le toucher agit au lever du doigt : un glissé tourne la caméra sans rien valider
		if not e.pressed and _tap_drag < 14.0:
			_tap(e.position)
		return
	if mobile and e is InputEventMouseMotion:
		return
	if e is InputEventKey and e.keycode == KEY_ALT and not e.echo:
		refresh_hover()  # Alt montre les objets interactifs
		return
	if e is InputEventJoypadButton and e.pressed:
		pad = true
		if ui.hud.visible and ui.overlay == null:
			_pad_button(e.button_index)
		return
	if e is InputEventMouseMotion and e.relative.length() > 2.0:
		pad = false
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		_pan(-e.relative)
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		# caméra libre : orbite autour du point visé
		_rmb_drag += e.relative.length()
		yaw -= e.relative.x * 0.3
		pitch = clampf(pitch + e.relative.y * 0.2, 12.0, 82.0)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		if e.pressed:
			_rmb_drag = 0.0
		elif _rmb_drag < 6.0:
			# un clic droit bref annule ; sans rien à annuler, il tourne le héros actif vers la case visée
			if battle.card_sel >= 0 or battle.inspect or battle._move_plan != null or hover == null or not battle.face_cell(hover):
				battle.cancel()
	elif e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				dist = clampf(dist - 1.8, 7.0, 60.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				dist = clampf(dist + 1.8, 7.0, 60.0)
			MOUSE_BUTTON_LEFT:
				if exploring and ui.overlay == null:
					if _adv_hover != null:
						_adv_click(_adv_hover)
				elif ui.hud.visible and ui.over_hand(e.position):
					pass  # un clic à côté d'une carte ne traverse jamais la main jusqu'au plateau
				elif ui.hud.visible and not pad:
					var c = _pick(cam.project_ray_origin(e.position), cam.project_ray_normal(e.position))
					if c != hover:
						hover = c
						refresh_hover()
					if hover != null:
						battle.click(hover)
				elif hover != null and ui.hud.visible:
					battle.click(hover)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_Q:
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					yaw -= 90.0
			KEY_E:
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					yaw += 90.0
			KEY_SPACE, KEY_ENTER:
				battle.end_turn()
			KEY_LEFT, KEY_RIGHT:
				battle.turn_facing(1 if e.keycode == KEY_RIGHT else -1)
			KEY_P:
				if exploring:
					adv_menu("deck")
				else:
					view_deck()
			KEY_I:
				adv_menu("equip")
			KEY_L:
				ui.log_box.visible = not ui.log_box.visible
			KEY_D:
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and ui.hud.visible:
					battle.danger = not battle.danger
					ui.toast("Zone de danger : tout ce que les ennemis peuvent frapper ce tour" if battle.danger else "Zone de danger masquée")
					refresh_hover()
			KEY_H:
				ui.show_keys = 0 if ui.keys_plate.visible else 1
				ui.refresh()
			KEY_M:
				toggle_mute()
			KEY_T:
				if ui.hud.visible:
					set_tactic(not tactic)
			KEY_TAB:
				if battle.active:
					battle.select(battle.active)
					follow(battle.active.position, minf(dist, 18.0))
			KEY_G:
				quality = (quality + 1) % 3
				_apply_quality()
				ui.toast("Qualité : " + ["portable", "normale", "ultra"][quality])
			_:
				if e.keycode >= KEY_1 and e.keycode <= KEY_9:
					battle.select_card(e.keycode - KEY_1)


# ------------------------------------------------------------------ run

func _title() -> void:
	play_music("titre")
	orbit = true
	title_bi = randi() % Data.BIOMES.size()
	_build_room(randi(), title_bi, 16, Board.ARCHETYPES[randi() % Board.ARCHETYPES.size()])
	dist = 34.0
	pitch = 30.0
	_snap_cam()
	var k := 1  # « Lancer une descente » depuis la fin de l'initiation : droit aux écrans de départ
	if not go_run:
		k = await ui.title_screen(_save_info())
	go_run = false
	orbit = false
	if k == 2 and _load_run():
		return
	if k < 0:
		return  # le mode portable vient de changer : la scène repart
	if k == 3:
		_tutorial()
		return
	new_run()


var title_bi := 0
func title_place(d: int) -> String:
	## Écran titre : le décor voxel derrière le menu, et son nom ; ‹ › en change.
	if d != 0:
		title_bi = posmod(title_bi + d, Data.BIOMES.size())
		_build_room(randi(), title_bi, 16, Board.ARCHETYPES[randi() % Board.ARCHETYPES.size()])
	return Data.BIOMES[title_bi].name


var rolled_traits: Array = []  # tirés par la roulette avant la création de l'escouade
func _roll_traits() -> Array:
	var traits := Data.TRAITS.keys()
	for i in range(traits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = traits[i]
		traits[i] = traits[j]
		traits[j] = t
	return traits


func _make_party(keys: Array = party) -> void:
	for u in heroes:
		u.queue_free()
	heroes.clear()
	var traits: Array = rolled_traits if rolled_traits.size() >= keys.size() else _roll_traits()
	rolled_traits = []
	var i := 0
	for k in keys:
		var u := Unit.new()
		u.setup(k, "hero")
		u.trait_id = traits[i]
		i += 1
		_trait_mod(u, 1)
		u.base_hp = int(round(u.base_hp * Data.DIFFICULTY[difficulty].hp * (0.85 if pacts.has("sang") else 1.0)))
		u.max_hp = u.base_hp
		u.hp = u.max_hp
		if args.has("gear"):  # --gear=id,id : essais, chaque héros prend les pièces qui lui vont
			for gid in args.gear.split(","):
				if Data.ITEMS.has(gid) and Data.item_fits(gid, k) and u.equip[Data.ITEMS[gid].slot] == "":
					u.equip[Data.ITEMS[gid].slot] = gid
		u.apply_gear()
		units_root.add_child(u)
		heroes.append(u)


func _trait_mod(u: Unit, sgn: int) -> void:
	## Ce que le trait change aux stats de base ; sgn = -1 pour le retirer (relance du Journal de route).
	var m: Array = {"vertige": [6, 0, -1], "leger": [0, 1, 0], "colosse": [8, -1, 0], "insomniaque": [-4, 0, 0],
		"fragile": [-6, 0, 0], "grimpeur": [0, 0, 2], "lourdaud": [0, -1, 0]}.get(u.trait_id, [0, 0, 0])
	u.base_hp += sgn * m[0]
	u.base_move += sgn * m[1]
	u.base_jump += sgn * m[2]


var journal_floor := 0
func _journal_reroll() -> void:
	## Journal de route : à la première salle « ? » de l'étage, un héros peut relancer son trait.
	if journal_floor == floor_i:
		return
	journal_floor = floor_i
	var h := await _pick_hero("JOURNAL DE ROUTE", "Un héros de votre choix relance son trait")
	if h == null:
		return
	var pool: Array = Data.TRAITS.keys().filter(func(t): return t != h.trait_id)
	var t: String = pool[rng.randi_range(0, pool.size() - 1)]
	await ui.trait_roulette([h.key], [t])
	_trait_mod(h, -1)
	h.trait_id = t
	_trait_mod(h, 1)
	h.apply_gear()


func new_run() -> void:
	exploring = false
	if aboard:
		aboard.visible = false
		adv_root.visible = false
	run_seed = int(args.seed) if args.has("seed") else randi()
	rng.seed = run_seed
	mode = await _pick_mode()
	difficulty = await _pick_difficulty()
	party = await _draft()
	rolled_traits = _roll_traits()
	await ui.trait_roulette(party, rolled_traits)
	pacts = await _pick_pacts()
	tuto = false
	_start_run()
	if mode == "aventure":
		_adventure()
	else:
		_loop()


func _start_run() -> void:
	floor_i = 1
	journal_floor = 0
	step = 0
	fmap = []
	_no_save = false
	fights = 0
	purges = 0
	rare_off = -0.05
	obj_chance = 0.4
	myst_fight = 0.1
	companion = ""
	seen_events = []
	seen_mech = {}
	pending_mods = []
	gold = 40
	floor_biomes = range(Data.BIOMES.size())
	for i in range(floor_biomes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = floor_biomes[i]
		floor_biomes[i] = floor_biomes[j]
		floor_biomes[j] = t
	bag = []
	relics = []
	deck = []
	elites_seen = []
	run_start = Time.get_ticks_msec()
	deck = Data.starter(party)
	voc_intro_done = false
	for ci in deck:
		library_see(ci.id)
	gain_obj("o_fiole", party[0])  # la Fiole de départ, au premier héros de l'escouade
	if party.has("receleur"):
		gain_obj("o_picots", "receleur")
	ui.refresh_relics(relics)
	ui.set_gold(gold)
	_make_party()


# Initiation : des chapitres scénarisés. Chacun : escouade, arène 10×10 à plat (eau, objets, runes posés à la main),
# ennemis [id, case, regard, PV], puis les étapes. Une étape : le geste attendu (do), où (at), la carte, la main donnée
# au début du tour (hand), et la consigne. do : move (une case), play (une carte sur une case), prop (le coffre),
# ok (lire, puis « Suite »), orient (« Fin »), face (aucun ennemi dans le dos, puis valider), end (fin du tour libre).
# Les ennemis ne jouent pas : le plateau reste celui que décrit la consigne.
const TUTO := [
	{"name": "Le pas et le coup", "art": "res://assets/ui/tuto_1.png", "glyph": "⚔", "text": "La Lame contre deux Moussus : avancer, frapper, prendre de dos, se tourner.",
		"party": ["lame"], "heroes": [Vector2i(4, 8)],
		"foes": [["husk", Vector2i(4, 4), Vector2i(0, 1)], ["husk", Vector2i(7, 3), Vector2i(0, -1)]],
		"steps": [
			{"do": "move", "at": Vector2i(4, 5), "hand": ["estoc", "double", "fente"], "say": "Au tour de la Lame. Les cases éclairées : jusqu'où elle va. Cliquez la case marquée, puis recliquez."},
			{"do": "play", "card": "estoc", "at": Vector2i(4, 4), "say": "Une carte : l'Estoc, en bas, puis cliquez le Moussu. Chaque carte coûte du mana : 3 par tour."},
			{"do": "face", "say": "La flèche dorée : où regarde la Lame. Ils frappent de dos : clic droit sur une case vers eux (ou ← →)."},
			{"do": "end", "say": "Fini pour ce tour : « Fin · Lame », en bas à droite. Sans consigne, elle se tourne vers l'ennemi proche."},
			{"do": "move", "at": Vector2i(7, 4), "hand": ["double", "estoc", "fente"], "say": "Ce Moussu vous tourne le dos. Passez derrière lui : la case marquée."},
			{"do": "play", "card": "double", "at": Vector2i(7, 3), "say": "Double lame, dans son dos : ×1,5 sur chaque coup."},
			{"do": "face", "say": "Aucun Moussu dans son dos : clic droit sur une case vers eux."},
			{"do": "end", "say": "Fin du tour : « Fin · Lame »."}]},
	{"name": "Le terrain", "glyph": "✹", "text": "Un brasero, l'eau, une rune de force et un coffre : le décor frappe aussi.",
		"party": ["lame"], "heroes": [Vector2i(4, 8)],
		"water": [Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6)],
		"props": {Vector2i(2, 4): "brasero", Vector2i(4, 4): "coffre"}, "tiles": {Vector2i(4, 5): "force"},
		"foes": [["husk", Vector2i(6, 5), Vector2i(-1, 0)], ["husk", Vector2i(2, 3), Vector2i(0, 1)]],
		"steps": [
			{"do": "move", "at": Vector2i(4, 5), "hand": ["c_aiguille", "c_lam2_kunai_leste", "estoc"], "say": "Une rune de force ✦ : +3 aux attaques lancées depuis sa case. Allez dessus."},
			{"do": "play", "card": "c_aiguille", "at": Vector2i(2, 4), "say": "Un brasero ✹ explose quand on le frappe : 7 dégâts autour. Visez-le avec l'Aiguille."},
			{"do": "play", "card": "c_lam2_kunai_leste", "at": Vector2i(6, 5), "say": "Le Kunaï lesté repousse d'une case. Poussez ce Moussu à l'eau : la noyade fait 8."},
			{"do": "prop", "at": Vector2i(4, 4), "say": "Un coffre ◆ au contact : cliquez-le. L'ouvrir ne coûte rien."},
			{"do": "end", "say": "Fin du tour : « Fin · Lame »."}]},
	{"name": "L'escouade", "art": "res://assets/ui/tuto_2.png", "glyph": "◆", "text": "Garde, Lame, Oracle : l'ordre du round, un paquet chacun, la provocation, le soin.",
		"party": ["garde", "lame", "oracle"], "heroes": [Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8)], "hurt": {"garde": 14},
		"foes": [["husk", Vector2i(4, 4), Vector2i(0, 1)], ["husk", Vector2i(6, 4), Vector2i(0, 1)]],
		"steps": [
			{"do": "ok", "at": "frieze", "hand": ["estoc", "double", "fente"], "say": "La frise, en haut : l'ordre du round, du plus rapide au plus lent. La Lame ouvre."},
			{"do": "ok", "at": "orb", "say": "Chaque héros a son paquet, sa main, et 3 de mana à son tour."},
			{"do": "move", "at": Vector2i(4, 5), "say": "Avancez la Lame au contact du Moussu."},
			{"do": "play", "card": "estoc", "at": Vector2i(4, 4), "say": "Estoc, sur lui."},
			{"do": "end", "say": "Fin du tour : la main passe au suivant de la frise."},
			{"do": "play", "card": "seve", "at": Vector2i(3, 8), "hand": ["seve", "braise", "c_ondee"], "say": "L'Oracle soigne de loin : Sève, puis cliquez le Garde blessé."},
			{"do": "play", "card": "braise", "at": Vector2i(6, 4), "say": "Et frappe de loin : Braise sur le Moussu, jusqu'à 5 cases."},
			{"do": "end", "say": "Fin du tour de l'Oracle."},
			{"do": "play", "card": "defi", "at": Vector2i(3, 8), "hand": ["defi", "pavois", "frappe"], "say": "Au Garde. Défi : +4 armure et Provocation, les ennemis le visent lui."},
			{"do": "ok", "at": "garde", "say": "L'armure absorbe les coups avant les PV. Le Garde encaisse, les autres frappent."},
			{"do": "end", "say": "Fin du tour, et du chapitre."}]},
	{"name": "Butin et équipement", "glyph": "⚒", "text": "Une carte au butin, une pièce d'équipement à porter, une relique.",
		"party": ["garde", "lame", "oracle"], "heroes": [Vector2i(3, 8), Vector2i(4, 5), Vector2i(5, 8)],
		"foes": [["husk", Vector2i(4, 4), Vector2i(0, 1), 4]],
		"steps": [
			{"do": "play", "card": "estoc", "at": Vector2i(4, 4), "hand": ["estoc", "double", "fente"], "say": "Un dernier Moussu, à bout de souffle : achevez-le à l'Estoc."}]},
	{"name": "La vocation", "art": "res://assets/ui/tuto_3.png", "glyph": "⚭", "text": "Les points de job, une deuxième classe, et sa guilde au butin.",
		"party": ["garde", "lame", "oracle"]},
	{"name": "Version rapide", "glyph": "»", "text": "Un combat, puis l'essentiel en un écran.",
		"party": ["lame"], "heroes": [Vector2i(4, 8)],
		"water": [Vector2i(8, 4), Vector2i(9, 4), Vector2i(8, 5), Vector2i(9, 5), Vector2i(8, 6), Vector2i(9, 6)],
		"foes": [["husk", Vector2i(5, 4), Vector2i(0, -1)], ["husk", Vector2i(7, 5), Vector2i(-1, 0)]],
		"steps": [
			{"do": "move", "at": Vector2i(5, 5), "hand": ["double", "c_lam2_kunai_leste", "estoc"], "say": "Cliquez la case marquée (le chemin s'affiche), recliquez : la Lame y va, dans son dos."},
			{"do": "play", "card": "double", "at": Vector2i(5, 4), "say": "Une carte en bas, puis la cible. De dos, c'est ×1,5 : Double lame !"},
			{"do": "play", "card": "c_lam2_kunai_leste", "at": Vector2i(7, 5), "say": "Le Kunaï lesté repousse : poussez l'autre Moussu à l'eau. Noyade : 8."},
			{"do": "face", "say": "Eux aussi frappent de dos : clic droit sur une case vers eux (ou ← →)."},
			{"do": "end", "say": "Fin du tour : « Fin · Lame », en bas à droite."}]},
]
const TUTO_TRAITS := {"garde": "costaud", "lame": "gaucher", "oracle": "lynx"}
const TUTO_ITEM := "epee_ecluse"
const TUTO_RELIC := "ecaille"
var tuto_k := 0              # chapitre en cours (index dans TUTO ; 5 : la version rapide)
var tuto_steps: Array = []
var tuto_i := 0
var bot_pick = 0             # --tutotest : la réponse du pilote au prochain écran (index, ou geste d'équipement)
static var go_run := false   # « Lancer une descente » : la scène repart sur une descente
var next_size := 0  # taille d'arène imposée (initiation) ; 0 = tirée au sort


func _tutorial() -> void:
	## Entrée « Initiation » du titre : la première fois, une question ; ensuite, le menu des chapitres.
	var done := _tuto_done()
	var i := -1
	if done.is_empty():
		i = await ui.choose("INITIATION", "Tu connais les roguelikes, les tacticals ou les TCG ?", [
			{"title": "Oui, fais-moi la version rapide", "art": "res://assets/ui/tuto_1.png", "w": 320, "glyph": "»", "text": TUTO[5].text, "color": UI.GOLD},
			{"title": "Non, fais voir", "art": "res://assets/ui/tuto_2.png", "w": 320, "glyph": "◆", "text": "Cinq chapitres courts, une notion à la fois.", "color": Color("#8fd0a0")}], true, "← Retour")
		i = [5, 0][i] if i >= 0 else -1
	else:
		var opts: Array = []
		for k in TUTO.size():
			var o := {"title": ("✓ " if done.has(k) else "") + (TUTO[k].name if k == 5 else "%d · %s" % [k + 1, TUTO[k].name]),
				"glyph": TUTO[k].glyph, "text": TUTO[k].text, "color": UI.GOLD if k == 5 else Color("#8fd0a0")}
			if TUTO[k].has("art"):
				o["art"] = TUTO[k].art
			opts.append(o)
		i = await ui.choose("INITIATION", "Rejouer un chapitre", opts, true, "← Retour")
	if i < 0:
		get_tree().reload_current_scene()
	elif i == 5:
		await _tuto_play(5)
		await _tuto_end()
	else:
		await _tuto_from(i)


func _tuto_done() -> Array:
	## Chapitres déjà faits (user://initiation.cfg) : l'entrée du titre ouvre alors le menu des chapitres.
	var cf := ConfigFile.new()
	if cf.load("user://initiation.cfg") != OK or not cf.has_section("chapitres"):
		return []
	return Array(cf.get_section_keys("chapitres")).map(func(k): return int(k))


func _tuto_mark(k: int) -> void:
	if _testing():
		return
	var cf := ConfigFile.new()
	cf.load("user://initiation.cfg")
	cf.set_value("chapitres", str(k), true)
	cf.save("user://initiation.cfg")


func _tuto_from(n: int) -> void:
	## La version complète, du chapitre n au dernier ; un petit écran entre deux chapitres.
	for k in range(n, 5):
		await _tuto_play(k)
		if k == 4:
			break
		var j := await ui.choose("CHAPITRE %d TERMINÉ" % (k + 1), TUTO[k].name, [
			{"title": "Chapitre suivant", "glyph": "▸", "text": "%d · %s" % [k + 2, TUTO[k + 1].name], "color": UI.GOLD},
			{"title": "Retour au titre", "glyph": "⌂", "text": "L'Initiation garde vos chapitres : ils se rejouent depuis son menu.", "color": Color("#8f86a8")}])
		if j != 0:
			_tuto_leave(false)
			return
	await _tuto_end()


func _tuto_end() -> void:
	if args.has("tuto2run"):
		bot_pick = 1
		args.erase("tutotest")
	var i := await ui.choose("INITIATION TERMINÉE", "Le reste, la descente vous l'apprendra", [
		{"title": "Retour au titre", "glyph": "⌂", "text": "Les chapitres se rejouent depuis l'Initiation.", "color": Color("#8f86a8")},
		{"title": "Lancer une descente", "glyph": "⚔", "text": "Mode, difficulté, escouade : la vraie descente commence.", "color": UI.GOLD}])
	_tuto_leave(i == 1)


func _tuto_leave(run: bool) -> void:
	tuto = false
	if args.has("tutotest"):
		return
	go_run = run
	get_tree().reload_current_scene()


func _tuto_title() -> String:
	return TUTO[5].name if tuto_k == 5 else "Chapitre %d · %s" % [tuto_k + 1, TUTO[tuto_k].name]


func _tuto_play(k: int) -> void:
	## Un chapitre : escouade et paquet neufs, graine fixe, son combat scénarisé puis ses écrans.
	var ch: Dictionary = TUTO[k]
	tuto = true
	tuto_k = k
	mode = "descente"
	difficulty = 0
	pacts = []
	run_seed = 4200 + k
	rng.seed = run_seed
	party = ch.party.duplicate()
	rolled_traits = party.map(func(p): return TUTO_TRAITS[p])
	_start_run()
	if not battle.coach.is_connected(_coach):
		battle.coach.connect(_coach)
	tuto_steps = ch.get("steps", [])
	tuto_i = 0
	if ch.has("foes"):
		next_arch = "damier"
		next_obj = "kill"
		next_mods = []
		next_size = 10
		await _fight("combat", ch.foes.map(func(f): return f[0]))
		next_size = 0
		ui.coach("", "")
		ui.point(Callable())
	else:
		_build_room(run_seed, 0, 10, "damier")
		ui.set_header("Initiation", _tuto_title())
	match k:
		3:
			await _tuto_gear()
		4:
			await _tuto_voc()
		5:
			await _tuto_recap()
	_tuto_mark(k)


func _tuto_arena() -> void:
	## L'arène du chapitre : un parvis 10×10 à plat, l'eau et les objets posés à la main (le hasard n'y met rien).
	var ch: Dictionary = TUTO[tuto_k]
	board.props.clear()
	board.blocked.clear()
	for x in board.dim:
		for z in board.dim:
			var c := Vector2i(x, z)
			var wet: bool = ch.get("water", []).has(c)
			board.kind[c] = "water" if wet else "land"
			board.h[c] = 0 if wet else 2
	board.props.merge(ch.get("props", {}))
	board.build_visuals()
	ui.set_header("Initiation", _tuto_title())


func _tuto_setup() -> void:
	## Appelé par battle.start avant le premier round : chaque unité à sa case, les runes du chapitre, la première consigne.
	var ch: Dictionary = TUTO[tuto_k]
	for i in heroes.size():
		heroes[i].place(ch.heroes[i], board)
		heroes[i].facing = Vector2i(0, -1)
		heroes[i].hp -= int(ch.get("hurt", {}).get(heroes[i].key, 0))
	for i in battle.foes.size():
		var d: Array = ch.foes[i]
		battle.foes[i].place(d[1], board)
		battle.foes[i].facing = d[2]
		if d.size() > 3:
			battle.foes[i].hp = d[3]
	for c in ch.get("tiles", {}):
		battle.tiles[c] = ch.tiles[c]
		battle._make_tile(c, ch.tiles[c])
	_tuto_show()


func _tuto_show() -> void:
	var s: Dictionary = tuto_steps[tuto_i]
	ui.coach("%s · %d/%d" % [_tuto_title(), tuto_i + 1, tuto_steps.size()], s.say, s.do == "ok")
	ui.point(_tuto_arrow(s))


func _tuto_near() -> Unit:
	var h: Unit = battle.active
	var best: Unit = null
	for f in battle.alive_foes():
		if h and (best == null or Battle.dist(f.cell, h.cell) < Battle.dist(best.cell, h.cell)):
			best = f
	return best


func _tuto_arrow(s: Dictionary) -> Callable:
	## Ce que montre la flèche : la case, la carte puis sa cible, le bouton de fin, ou ce que la consigne explique.
	var over := func(c: Vector2i):
		var u := battle.unit_at(c)
		return u.position + Vector3(0, u.head + 0.9, 0) if u else board.world(c) + Vector3(0, 1.0, 0)
	match s.do:
		"move":
			return func(): return board.world(s.at) + Vector3(0, 0.3, 0)
		"prop":
			return over.bind(s.at)
		"play":
			return func():
				if battle.card_sel < 0:
					var i: int = battle.hand.map(func(ci): return ci.id).find(s.card)
					return ui._cards[i] if i >= 0 and i < ui._cards.size() else null
				return over.call(s.at)
		"face":
			return func():
				var f := _tuto_near()
				return over.call(battle.active.cell + battle._dir(battle.active.cell, f.cell)) if f and battle.active else null
		"ok":
			return func():
				if s.at == "frieze":
					return ui.frieze
				if s.at == "orb":
					return ui.energy_lbl
				var h: Array = heroes.filter(func(u): return u.key == s.at)
				return h[0].position + Vector3(0, h[0].head + 0.9, 0) if h.size() > 0 else null
	return func(): return ui.end_btn


func _tuto_face_ok() -> bool:
	## Aucun ennemi dans le dos du héros actif (même règle que calc).
	var h: Unit = battle.active
	return battle.alive_foes().all(func(f): return h.facing.x * signi(f.cell.x - h.cell.x) + h.facing.y * signi(f.cell.y - h.cell.y) >= 0)


func tuto_gate(kind: String, arg = null) -> String:
	## L'étape en cours n'accepte que son geste ; le reste est refusé d'un mot. "" : permis.
	if not tuto or tuto_i >= tuto_steps.size():
		return ""
	var s: Dictionary = tuto_steps[tuto_i]
	var ok: bool
	match kind:
		"card":
			ok = s.do == "play" and arg == s.card
		"target":
			ok = s.do == "play" and arg == s.at
		"end":
			ok = s.do == "end"
		_:
			ok = s.do == kind and arg == s.at
	if ok:
		return ""
	match s.do:
		"play":
			return "Suivez la flèche : %s." % Data.def(s.card).name
		"ok":
			return "Lisez, puis « Suite »."
		"face":
			return "Clic droit sur une case vers les ennemis : le héros se tourne."
		"end":
			return "Terminez le tour : « Fin », en bas à droite."
	return "Pas là : suivez la flèche."


func tuto_hand(h: Unit) -> Array:
	## La main donnée au début du tour : celle de l'étape en cours ([] : la pioche normale).
	var ids: Array = tuto_steps[tuto_i].get("hand", []) if tuto and tuto_i < tuto_steps.size() else []
	return ids.map(func(id): return {"id": id, "lvl": 1, "h": h.key})


func _coach(evt: String, _info) -> void:
	## Ce que fait le joueur : le geste attendu fait passer à l'étape suivante.
	if tuto and tuto_i < tuto_steps.size() and evt == {"move": "moved", "play": "done", "prop": "coffre", "face": "faced", "end": "ended"}.get(tuto_steps[tuto_i].do, "") and (evt != "faced" or _tuto_face_ok()):
		_tuto_next()


func _tuto_ok() -> void:
	## Bouton « Suite » de la boîte du coach.
	if tuto_i < tuto_steps.size() and tuto_steps[tuto_i].do == "ok":
		_tuto_next()


func _tuto_next() -> void:
	tuto_i += 1
	if tuto_i < tuto_steps.size():
		_tuto_show()
		return
	ui.coach("", "")
	ui.point(Callable())
	if not battle.over:  # la dernière consigne suivie : le chapitre est gagné
		battle.over = true
		battle.player_turn = false
		battle._finish(true)


func _tuto_gear() -> void:
	## Chapitre 4, après le combat : une carte au butin, une pièce d'équipement à porter, une relique.
	var ids := ["defi", "venin", "c_tison"]
	var i := await ui.choose("BUTIN", "Après chaque combat : une carte parmi trois pour le paquet, ou aucune", ids.map(func(id): return {"card": {"id": id, "lvl": 1}, "tag": "Pour " + Data.HEROES[Data.def(id).owner].name}), true)
	if i >= 0:
		deck.append({"id": ids[i], "lvl": 1})
		fight_loot.append(Data.def(ids[i]).name)
	await ui.choose("ÉQUIPEMENT", "Une pièce d'équipement : elle rejoint le sac", [_item_opt(TUTO_ITEM).merged({"w": 300})], true, "Au sac")
	bag.append(TUTO_ITEM)
	fight_loot.append(Data.ITEMS[TUTO_ITEM].name)
	var rows: Array = heroes.map(func(h): return {"nm": h.nm, "key": h.key, "pj0": h.pj, "pj1": h.pj, "m": 1, "lo": 0, "hi": Data.MASTERY[2]})
	var say := func(t: String, at: String) -> void:
		ui.coach(_tuto_title(), t)
		ui.point(func(): return ui.tuto_node(at))
	while bag.has(TUTO_ITEM):
		say.call("On s'équipe hors combat : cliquez « S'équiper ».", "btn1")
		bot_pick = 1
		if await ui.fight_summary("VICTOIRE", rows, fight_loot, true) != 1:
			ui.toast("D'abord « S'équiper » : l'épée attend au sac.")
			continue
		say.call("L'épée ne va qu'au Garde : cliquez-la dans le sac.", "bag0")
		bot_pick = {"equip": 0, "hero": 0}
		_equip_act(await ui.equipment_screen(heroes, bag))
	say.call("La fiche du Garde a changé : l'épée, et l'attaque +1. Cliquez « Terminer ».", "done")
	bot_pick = {}
	while _equip_act(await ui.equipment_screen(heroes, bag)):
		pass
	ui.coach("", "")
	ui.point(Callable())
	await ui.choose("RELIQUE", "Un pouvoir gardé toute la descente, pour toute l'escouade", [_relic_opt(TUTO_RELIC).merged({"w": 300})], true, "La prendre")
	await _add_relic(TUTO_RELIC)


func _tuto_voc() -> void:
	## Chapitre 5 : les points de job, la vocation, puis une carte de guilde au butin.
	var h: Unit = heroes[1]  # la Lame
	await ui.choose("POINTS DE JOB", "Chaque combat en rapporte : 1, et 2 contre une élite", [
		{"title": "La maîtrise", "art": "res://assets/ui/tuto_3.png", "w": 320, "glyph": "⚭", "color": Color("#d08aff"),
		"text": "Au palier II, le héros choisit une vocation : une deuxième classe. L'initiation triple les points : la Lame y est."}], true, "Compris")
	await _gain_pj(h, 1)
	if h.voc == "":
		return
	var g := Guildes.index(h.key, h.voc)
	var opts: Array = [{"card": {"id": Guildes.cards_of(g, [1])[0], "lvl": 1, "h": h.key}, "tag": "⚭ " + Guildes.LIST[g][2]},
		{"card": {"id": "venin", "lvl": 1}, "tag": "Pour Lame"}, {"card": {"id": "c_tison", "lvl": 1}, "tag": "Pour Oracle"}]
	var i := await ui.choose("BUTIN", "Sa guilde entre au butin : la carte ⚭ mêle ses deux classes", opts, true)
	if i >= 0:
		deck.append(opts[i].card)
	await _tuto_mastery()


func _tuto_recap() -> void:
	## Version rapide : le reste de l'initiation en un écran.
	await ui.choose("L'ESSENTIEL", "Le reste se découvre en descendant", [
		{"title": "Le butin", "art": "res://assets/ui/tuto_2.png", "w": 300, "glyph": "◆", "color": UI.GOLD,
		"text": "Après chaque combat, une carte parmi trois. Coffres et élites donnent objets et reliques."},
		_item_opt(TUTO_ITEM).merged({"title": "L'équipement", "w": 300, "text": "Hors combat, « S'équiper » : un objet du sac, puis un héros. Sa fiche montre ce qui change."}, true),
		{"title": "La vocation", "art": "res://assets/ui/tuto_3.png", "w": 300, "glyph": "⚭", "color": Color("#d08aff"),
		"text": "1 point de job par combat, 2 par élite. Au palier II : une deuxième classe, et sa guilde au butin."}], true, "Compris")


func _tuto_mastery() -> void:
	## Chapitre 5 : la vocation expliquée sur le héros qui vient de la prendre, avec trois cartes de sa guilde
	## (commune, rare, légendaire) pour montrer ce que la maîtrise fait monter.
	var hs: Array = heroes.filter(func(h): return h.voc != "")
	if hs.is_empty():
		return
	var h: Unit = hs[0]
	var g := Guildes.index(h.key, h.voc)
	var opts: Array = []
	for r in [[1, "Commune"], [3, "Rare"], [4, "✦ Légendaire"]]:
		var ids := Guildes.cards_of(g, [r[0]])
		if ids.size() > 0:
			opts.append({"card": {"id": ids[0], "lvl": 1, "h": h.key}, "tag": r[1]})
	await ui.choose("LA MAÎTRISE", "Vocation de %s : %s. Sa guilde, %s + %s, s'appelle « %s ». Plus il combat, meilleures sont ses cartes de guilde." % [
		h.nm, Data.HEROES[h.voc].name, Data.HEROES[h.key].name, Data.HEROES[h.voc].name, Guildes.LIST[g][2]], opts, true, "Compris")


func _pick_difficulty() -> int:
	var opts: Array = []
	var cols := [Color("#8fd0a0"), UI.GOLD, Color("#e0a050"), Color("#e0583a"), Color("#b0305a")]
	for i in Data.DIFFICULTY.size():
		var d: Dictionary = Data.DIFFICULTY[i]
		opts.append({"title": "%d · %s" % [i + 1, d.name], "glyph": "%d/5" % (i + 1), "art": "res://assets/ui/diff_%d.png" % (i + 1), "text": d.text + ("\nVotre dernier choix." if i == difficulty else ""), "color": cols[i]})
	return await ui.choose("DIFFICULTÉ", "De 1 (Oklm) à 5 (Anathème)", opts)


func _pick_pacts() -> Array:
	## Malus choisis contre du butin : chaque pacte ajoute 25 % d'or et des cartes plus rares.
	var on: Array = []
	while true:
		var opts: Array = []
		for k in Data.PACTS:
			var act: bool = on.has(k)
			opts.append({"title": ("✓ " if act else "") + Data.PACTS[k].name, "image": "res://assets/ui/pact_%s.png" % k, "dim": not act, "text": Data.PACTS[k].text,
				"color": Color("#e0583a") if act else Color("#8f86a8")})
		var i := await ui.choose("PACTES", "Chaque pacte : +25 %% d'or et plus de cartes rares. %d actif(s)." % on.size(), opts, true,
			"Descendre avec %d pacte(s)" % on.size() if on.size() > 0 else "Aucun pacte")
		if i < 0:
			return on
		var k: String = Data.PACTS.keys()[i]
		if on.has(k):
			on.erase(k)
		else:
			on.append(k)
	return on


func _draft() -> Array:
	## Trois héros parmi huit, en deux rangées de quatre ; un héros choisi reste à sa place (coché), un clic le retire.
	var out: Array = []
	while out.size() < 3:
		var keys: Array = Data.HEROES.keys()
		var opts: Array = []
		for k in keys:
			var d: Dictionary = Data.HEROES[k]
			var took: bool = out.has(k)
			opts.append({"title": ("✓ " if took else "") + d.name, "image": "res://assets/art/portrait_%s.png" % k, "color": Data.CLASS_COLOR[k],
				"chips": [["pv", str(d.hp)], ["deplacement", str(d.move)]], "text": d.title, "tip": d.role, "dim": took, "cards": emblem_cards(k), "encart": k})
		var chosen: String = ", ".join(out.map(func(k): return Data.HEROES[k].name))
		var i := await ui.choose("L'ESCOUADE", "Choisissez trois héros (%d / 3)%s" % [out.size(), ("  ·  " + chosen) if chosen != "" else ""], opts, true, "Compléter au hasard")
		if i < 0:
			while out.size() < 3:
				var left: Array = keys.filter(func(k): return not out.has(k))
				out.append(left[rng.randi_range(0, left.size() - 1)])
		elif out.has(keys[i]):
			out.erase(keys[i])
		else:
			out.append(keys[i])
	return out


func emblem_cards(cls: String) -> Array:
	## Trois cartes qui disent la classe : une par route (Data.ARCHETYPES), communes ou peu communes seulement.
	var out: Array = []
	for route in Data.ARCHETYPES.get(cls, []):
		for id in Data.CARDS:
			var d: Dictionary = Data.CARDS[id]
			if d.get("owner", "") == cls and d.get("arch", "") == route[0] and int(d.get("rar", 1)) <= 2 and not out.has(id):
				out.append(id)
				break
	for id in Data.STARTER.get(cls, []):
		if out.size() >= 3:
			break
		if not out.has(id):
			out.append(id)
	return out.slice(0, 3)


func guild_emblems(g: int) -> Array:
	## Trois cartes de la guilde (communes et peu communes : rien de ce que débloquent les paliers).
	var ids: Array = Guildes.cards_of(g, [1, 2])
	return ids.slice(0, 3)


func _biome() -> int:
	return floor_biomes[floor_i - 1] if floor_biomes.size() >= floor_i else floor_i - 1


func _minutes() -> int:
	return int((Time.get_ticks_msec() - run_start) / 60000.0)


func _loop() -> void:
	while true:
		var type: String = await _door()
		if type in ["combat", "elite", "boss"]:
			var won: bool = await _fight(type)
			if not won:
				_clear_save()
				await ui.game_over(false, "Étage %d, %d combats remportés, %d min, difficulté %d/5." % [floor_i, fights, _minutes(), difficulty + 1])
				new_run.call_deferred()
				return
			await _post_fight(type)
			if type == "boss":
				_clear_save()
				await ui.game_over(true, "Le Gardien est tombé : %d combats, %d min, difficulté %d/5." % [fights, _minutes(), difficulty + 1])
				new_run.call_deferred()
				return
		elif type == "sanctuaire":
			await _sanctuary()
		elif type == "marchand":
			await _merchant()
		elif type == "mystere":
			await _mystery({"node": null, "arch": next_arch})
		else:
			await _relic_pick("Reliquaire", "Une relique parmi trois")
		step += 1
		if step >= (fmap.size() if fmap.size() > 0 else ROOMS_PER_FLOOR):  # une vieille sauvegarde garde sa carte à 7 salles
			floor_i += 1
			step = 0
			obj_chance = 0.4
			fmap = []


func _flush_cards() -> void:
	## Les cartes gagnées en route : on la prend ou on la laisse (un paquet trop gros se dilue).
	while pending_cards.size() > 0:
		var parts: PackedStringArray = str(pending_cards.pop_front()).split("|")  # « id|enchantement » : un défi relevé
		var id: String = parts[0]
		var ci := {"id": id, "lvl": 1}
		if parts.size() > 1:
			ci["ench"] = parts[1]
		var i := await ui.choose("CARTE TROUVÉE", ("Défi relevé : la carte arrive enchantée. " if ci.has("ench") else "Un porteur, un vol ou un coffre : ") + "ajoutez-la au paquet (%d cartes) ou laissez-la" % deck.size(),
			[{"card": ci, "tag": Data.HEROES[Data.CARDS[id].owner].name if Data.CARDS.has(id) else ""}], true, "La laisser")
		if i >= 0:
			deck.append(ci)


func _post_fight(type: String) -> void:
	fights += 1
	for h in heroes:
		if not h.alive:
			h.revive()
			h.hp = maxi(1, int(h.max_hp * Data.DIFFICULTY[difficulty].revive[clampi(floor_i, 1, 3) - 1]))
		else:
			h.hp = mini(h.max_hp, h.hp + int(h.max_hp * Data.DIFFICULTY[difficulty].heal[clampi(floor_i, 1, 3) - 1]))
		if relics.has("lotus_pale"):
			h.hp = mini(h.max_hp, h.hp + 4)
	var pj0 := {}
	for h in heroes:
		pj0[h] = h.pj
	if type != "boss":
		for h in heroes:
			await _gain_pj(h, 2 if type == "elite" else 1)
		await _rewards(type)
	await _flush_cards()
	for k in battle.pending_relics:
		await _relic_pick("DÉCOUPE", "Le trophée d'une grande chasse")
	battle.pending_relics = 0
	await _summary(pj0)


func _summary(pj0: Dictionary) -> void:
	## Fin de combat : jauge d'expérience, tout le butin, et s'équiper avant de repartir (on ne s'équipe pas en combat).
	var rows: Array = []
	for h in heroes:
		var m := mastery(h)
		rows.append({"nm": h.nm, "key": h.key, "pj0": pj0.get(h, h.pj), "pj1": h.pj, "m": m,
			"lo": Data.MASTERY[m] if m >= 2 else 0, "hi": Data.MASTERY[mini(m + 1, 4)]})
	while true:
		var i := await ui.fight_summary("VICTOIRE", rows, fight_loot, bag.size() > 0)
		if i != 1:
			break
		await _equipment()
	fight_loot = []


func _door() -> String:
	## Carte de l'étage, tirée à la première salle : on voit où mène chaque chemin.
	if step == 0 and fmap.is_empty():
		await _ancient()
		_gen_map()
	_save_run()
	var nexts: Array = range(fmap[step].size()) if lane < 0 else fmap[step - 1][lane].links
	while true:
		var i := await ui.map_screen("ÉTAGE %d" % floor_i, "%s · salle %d / %d · %d or · difficulté %d/5" % [Data.BIOMES[_biome()].name, step + 1, ROOMS_PER_FLOOR, gold, difficulty + 1],
			fmap, step, lane, nexts, visited, "Équipement · %d" % bag.size(), _biome())
		if i == -2:
			await _equipment()
			continue
		if i == -4:
			await view_deck()
			continue
		lane = i
		visited.append(Vector2i(step, i))
		var n: Dictionary = fmap[step][i]
		next_arch = n.arch
		next_obj = n.obj
		next_mods = n.get("mods", [])
		return n.type
	return "combat"


func _gen_map() -> void:
	## Trois voies, reliées aux voisines ; marchand au milieu de l'étage, sanctuaire et second marchand avant le gardien.
	fmap = []
	visited = []
	lane = -1
	var pool := ["combat", "combat", "combat", "elite", "sanctuaire", "reliquaire", "mystere", "mystere"]
	for k in ROOMS_PER_FLOOR:
		var row: Array = []
		var last := k == ROOMS_PER_FLOOR - 1
		for i in (1 if last else 3):
			var t: String = pool[rng.randi_range(0, pool.size() - 1)]
			if last:
				t = "boss" if floor_i == 3 else "elite"
			elif k == 0:
				t = "combat"
			elif k == 3 and i == 1:
				t = "marchand"
			elif k == ROOMS_PER_FLOOR - 2 and i == 1:
				t = "sanctuaire"
			elif k == ROOMS_PER_FLOOR - 2 and i == 2:
				t = "marchand"  # un dernier passage avant le gardien
			var arch: String = Board.ARCHETYPES[rng.randi_range(0, 3)]
			while i > 0 and arch == row[i - 1].arch:
				arch = Board.ARCHETYPES[rng.randi_range(0, 3)]
			var obj := "portal" if t == "combat" and rng.randf() < 0.3 else "kill"
			var mods: Array = []
			if t == "elite" or (t == "combat" and k > 0 and rng.randf() < 0.3):
				mods.append(Data.MODIFIERS.keys()[rng.randi_range(0, Data.MODIFIERS.size() - 1)])
			row.append({"type": t, "arch": arch, "obj": obj, "links": [], "mods": mods})
		fmap.append(row)
	for k in ROOMS_PER_FLOOR - 1:
		for i in fmap[k].size():
			for j in fmap[k + 1].size():
				if fmap[k + 1].size() == 1 or absi(i - j) <= 1:
					fmap[k][i].links.append(j)
	for row in fmap:
		for n in row:
			var r: Dictionary = Data.ROOMS[n.type]
			n["desc"] = "%s — %s" % [r.name, r.text]
			if n.type in ["combat", "elite", "boss"]:
				n["desc"] += "\nTerrain : %s.%s" % [ARCH_NAMES[n.arch], "  Objectif : atteindre le portail." if n.obj == "portal" else ""]
			for m in n.mods:
				n["desc"] += "\n%s %s : %s  Butin +50 %%, cartes plus rares." % [Data.MODIFIERS[m].glyph, Data.MODIFIERS[m].name, Data.MODIFIERS[m].text]

const ARCH_NAMES := {"ecluse": "écluse et ponts", "terrasses": "terrasses en gradins", "cour": "cour fortifiée", "ilots": "îlots et pont-levis"}


func _build_room(seed: int, bi: int, size := 14, arch := "", with_props := false) -> void:
	var b: Dictionary = Data.BIOMES[bi]
	board.visible = true
	units_root.visible = true
	exploring = false
	env.fog_depth_begin = 26.0
	env.fog_depth_end = 80.0
	ui.show_explore(false)
	if aboard:
		aboard.visible = false
		adv_root.visible = false
	board.generate(seed, b, size, arch, with_props)
	board.build_visuals()
	apply_biome(b)
	var c3 := board.center()
	RenderingServer.global_shader_parameter_set("cut_center", Vector2(c3.x, c3.z))
	RenderingServer.global_shader_parameter_set("cut_half", board.dim * 0.5)
	for c in ambient_root.get_children():
		c.queue_free()
	Fx.ambient(ambient_root, b, Vector3(c3.x, 0, c3.z))
	for f in battle.foes:
		f.queue_free()
	battle.foes.clear()
	for n in battle.prop_nodes.values():
		n.queue_free()
	battle.prop_nodes.clear()
	if heroes.size() > 0:
		var hc := board.spawn_cells("hero", heroes.size())
		for i in heroes.size():
			heroes[i].place(hc[i], board)
			heroes[i].face(Vector2i(board.dim / 2, board.dim / 2) - hc[i])
	ui.set_header(b.name, ("Étage %d · donjon" % floor_i) if mode == "aventure" else ("Étage %d · salle %d / %d" % [floor_i, step + 1, ROOMS_PER_FLOOR]))
	target = c3
	dist = 14.0 + board.dim * 1.05


func toggle_mute() -> void:
	_mute = not _mute
	(_music[1] as AudioStreamPlayer).volume_db = _music_vol()
	ui.toast("Musique coupée" if _mute else "Musique")


func follow(p: Vector3, d: float) -> void:
	## Suivi de caméra : le centre de l'orbite va sur l'unité qui joue, et on s'en approche.
	if args.has("capture") or args.has("speed"):
		return  # les captures cadrent elles-mêmes ; l'auto-jeu accéléré n'a pas d'yeux
	target = Vector3(p.x, clampf(p.y, 0.0, 4.0), p.z)
	_focus = null
	dist = d


func reset_camera() -> void:
	## Vue par défaut du combat : l'angle de départ, tout le plateau, centrée sur l'escouade.
	yaw = 45.0
	pitch = 40.0
	dist = 14.0 + board.dim * 1.05
	target = _units_center()


func _fight(type: String, ids_override: Array = []) -> bool:
	var ids: Array
	fight_loot = []
	var arch := next_arch
	if arch == "":
		arch = Board.ARCHETYPES[rng.randi_range(0, Board.ARCHETYPES.size() - 1)]
	# concile : combats plus courts ; les cours et terrasses se resserrent, écluses et îlots gardent de la place
	var size := next_size if next_size > 0 else (16 if arch in ["cour", "terrasses"] else 18)
	match type:
		"elite":
			ids = Data.elite_pick(floor_i, rng, difficulty)
			for retry in 6:  # la même élite ne revient pas deux fois dans l'étage (Grelin croisé deux fois : lassant)
				if not elites_seen.has("%d:%s" % [floor_i, ids[0]]):
					break
				ids = Data.elite_pick(floor_i, rng, difficulty)
			elites_seen.append("%d:%s" % [floor_i, ids[0]])
			size = 18
			arch = Data.ELITE_ARCH.get(ids[0], arch)
		"boss":
			ids = Data.BOSS
			size = 20
		_:
			var pool: Array = Data.ENCOUNTERS[floor_i]
			# acte 1 : la première salle est une leçon isolée, la deuxième reste dans les leçons simples
			var hi: int = pool.size() - 1
			if floor_i == 1 and mode == "descente" and step <= 1:
				hi = mini(hi, 2 if step == 0 else 4)
			ids = pool[rng.randi_range(0, hi)]
	if ids_override.size() > 0:
		ids = ids_override
	# difficulté : un ennemi de plus (tiré dans le pool d'extras de l'étage) ou de moins
	ids = ids.duplicate()
	var extra: int = Data.DIFFICULTY[difficulty].extra[floor_i - 1] + (1 if pacts.has("horde") else 0)
	if extra > 0 and type != "boss":
		var ex: Array = Data.EXTRAS[clampi(floor_i, 1, 3)]
		for k in extra:
			if type == "combat" and ids.size() >= 5:
				break  # au plus 5 unités par combat normal
			ids.append(ex[rng.randi_range(0, ex.size() - 1)])
	elif extra < 0 and type == "combat" and ids.size() > 3:
		ids.resize(ids.size() + extra)
	_build_room(run_seed + floor_i * 1009 + step * 37 + fights * 131, _biome(), size, arch, true)
	if tuto:
		_tuto_arena()
	ids = compose(ids, type)
	pitch = 40.0
	battle.objective = next_obj if type == "combat" else "kill"
	battle.elite_fight = type in ["elite", "boss"]
	battle.champions = maxi(0, (floor_i - 1) + (1 if type == "elite" else 0) + Data.DIFFICULTY[difficulty].champ)
	battle.rng.seed = run_seed + floor_i * 13 + step
	Battle.foe_mult = Data.DIFFICULTY[difficulty].foe[floor_i - 1]
	Battle.foe_hp = Data.FOE_HP[clampi(floor_i, 1, 3) - 1]
	var mods: Array = next_mods.duplicate() if type != "boss" else []
	for m in pending_mods:
		if not mods.has(m):
			mods.append(m)
	pending_mods.clear()
	for pk in [["acier", "blindes"], ["rage", "enrages"], ["brume", "brume"]]:
		if pacts.has(pk[0]) and not mods.has(pk[1]):
			mods.append(pk[1])
	battle.mods = mods
	Battle.foe_bonus = 2 if mods.has("enrages") else 0
	battle.hand_size = 3 if pacts.has("main") else 4
	battle.tool_rate = 0.0 if tuto else 0.3 + 0.1 * (floor_i - 1)
	if pacts.has("champion"):
		battle.champions += 1
	if mods.size() > 0:
		ui.set_header(Data.BIOMES[_biome()].name, "Étage %d · salle %d / %d  ·  %s" % [floor_i, step + 1, ROOMS_PER_FLOOR,
			" · ".join(mods.map(func(m): return Data.MODIFIERS[m].glyph + " " + Data.MODIFIERS[m].name))])
	ui.show_hud(true)
	play_music("boss" if type == "boss" else ("elite" if type == "elite" else "combat"))
	battle.start(heroes, ids, deck, relics)
	target = _units_center()
	ui.show_hud(true)
	_apply_tactic()
	var won: bool = await battle.ended
	play_music("calme")
	ui.show_hud(false)
	_apply_tactic()  # le décor revient hors combat
	board.highlight({})
	return won


func compose(ids: Array, type: String) -> Array:
	## Règles de composition, une fois la salle construite : le terrain décide de qui peut y être.
	## Frondeur sans relief → Guetteur ; Anguille sans eau → Moussu (2 au plus) ;
	## une seule couche absorbante, une seule règle de terrain, une Vanne (deux en élite 4+), 5 unités en combat normal.
	var high := board.walkable_cells().any(func(c): return board.h[c] >= 2)
	var wet := board.h.keys().any(func(c): return board.kind[c] == "water")
	var out: Array = []
	var layer := ""
	var terrain := ""
	var eels := 0
	var vannes := 0
	for id in ids:
		var k: String = id
		if k == "frondeur" and not high:
			k = "guetteur"
		if k == "anguille":
			eels += 1
			if not wet or eels > 2:
				k = "husk"
		if k in Data.LAYERS:
			if layer != "" and layer != k:
				k = "husk"
			else:
				layer = k
		if k in Data.TERRAIN_RULES:
			if terrain != "" and terrain != k:
				k = "husk"
			else:
				terrain = k
		if k == "vanne":
			vannes += 1
			if vannes > (2 if type == "elite" and difficulty >= 3 else 1):
				k = "husk"
		out.append(k)
	if type == "combat" and out.size() > 5:
		out.resize(5)
	return out


func _roll_item(min_rarity := 1) -> String:
	## Rareté pondérée par l'étage : les objets rares arrivent plus tard.
	## Rang 4 (mythique) : acte 2 (≈ 8 %), acte 3 (≈ 20 %) ; l'acte 1 reste modeste.
	var roll := rng.randf() + 0.04 * pacts.size() + (floor_i - 1) * 0.15  # chaque pacte : objets un peu meilleurs
	var rar := 3 if roll > 0.92 else (2 if roll > 0.55 else 1)
	rar = maxi(rar, min_rarity)
	if floor_i >= 2 and rng.randf() < (0.05 if floor_i == 2 else 0.12) + (0.1 if min_rarity >= 3 else 0.0):
		rar = 4
	var ids: Array = []
	while ids.is_empty() and rar > 0:
		ids = Data.ITEMS.keys().filter(func(id): return Data.ITEMS[id].rarity == rar and (Data.ITEMS[id].owner == "any" or _job_here(Data.ITEMS[id].owner)))  # les pièces de métier : seulement si la classe est là
		rar -= 1
	for id in ids.duplicate():
		if Data.ITEMS[id].owner != "any":
			ids.append_array([id, id])  # une pièce de métier de l'équipe sort trois fois plus souvent
	return ids[rng.randi_range(0, ids.size() - 1)]


func _job_here(k: String) -> bool:
	## Une classe présente dans l'équipe, en classe ou en vocation.
	return party.has(k) or heroes.any(func(h): return h.voc == k or h.voc2 == k)


func rack_weapon(h: Unit) -> void:
	## Râtelier d'armes : une arme pour ce héros, plutôt bonne (peu commune ou mieux), équipée si sa main est libre.
	var r := rng.randf()
	var rar := 3 if r > 0.7 else 2
	var ids: Array = []
	while ids.is_empty() and rar > 0:
		ids = Data.ITEMS.keys().filter(func(id): return Data.ITEMS[id].slot == "arme" and Data.ITEMS[id].rarity == rar and Data.item_fits(id, h.key, h.voc, h.voc2))
		rar -= 1
	if ids.size() > 0:
		_gain_item(ids[rng.randi_range(0, ids.size() - 1)], h)


func _gain_item(id: String, h: Unit = null) -> void:
	## Au sac, ou équipé d'office si l'emplacement du héros qui l'a trouvé est libre.
	var it: Dictionary = Data.ITEMS[id]
	library_see("item:" + id)
	var who: Array = [h] if h else heroes
	for u in who:
		if u.equip[it.slot] == "" and Data.item_fits(id, u.key, u.voc, u.voc2):
			u.equip[it.slot] = id
			u.apply_gear()
			fight_loot.append("%s (équipé)" % it.name)
			ui.toast("%s : %s, équipé." % [u.nm, it.name])
			return
	bag.append(id)
	fight_loot.append(it.name)
	ui.toast("%s rejoint le sac." % it.name)


func open_chest(h: Unit) -> void:
	if tuto:  # l'initiation : un coffre sans surprise
		gold += 30
		ui.set_gold(gold)
		await ui.choose("COFFRE", "Ouvert par %s · coffres et élites remplissent la bourse et le sac" % h.nm, [{"title": "+30 or", "glyph": "◆", "text": "La bourse de l'escouade", "color": UI.GOLD, "w": 210}], true, "Continuer")
		return
	# on tire tout, puis une petite fenêtre dit clairement ce que contenait le coffre
	var g := 0
	var gains: Array = []
	var card := ""
	if rng.randf() < 0.15:
		card = _card_roll(2)
	if h.has_p("chasseur"):
		g += 25
	var obj := ""
	if rng.randf() < 0.35:
		obj = _obj_roll(3)
	if rng.randf() < (0.4 if floor_i == 1 else 0.6):  # acte 1 : moins de pièces, le sac se remplit trop vite
		var it := _roll_item()
		_gain_item(it, h)
		gains.append(_item_opt(it).merged({"text": Data.item_passives(it) + ("\n" if Data.item_passives(it) != "" else "") + "Au sac : s'équiper après le combat.", "w": 250}, true))
		fight_loot.append(Data.ITEMS[it].name)
	else:
		g += rng.randi_range(20, 35)  # 2 à 3 coffres par combat
	if g > 0:
		gold += g
		ui.set_gold(gold)
		Fx.number(self, h.position + Vector3(0, 0.6, 0), "+%d or" % g, Color(1.0, 0.85, 0.4))
		gains.append({"title": "+%d or" % g, "glyph": "◆", "text": "La bourse de l'escouade", "color": UI.GOLD, "w": 210})
		fight_loot.append("+%d or" % g)
	# 1. ce que le coffre donne d'office : tout est reçu, rien à choisir
	var more := (" · puis une carte à attribuer") if obj != "" or card != "" else ""
	await ui.choose("COFFRE", "Ouvert par %s · vous recevez tout%s" % [h.nm, more], gains, true, "Continuer")
	# 2. une carte-objet : à quel héros la donner (ou la revendre)
	if obj != "":
		await _gain_obj_ui(obj, 2 if rng.randf() < 0.1 else 1, "COFFRE")
	if card == "":
		return
	# 3. une carte de classe : la garder, ou la revendre tout de suite (un petit paquet ne doit rien coûter)
	var val: int = Data.sell_value({"id": card})
	var who: String = Data.holder({"id": card})
	var opts: Array = [{"title": "La garder", "image": "res://assets/art/portrait_%s.png" % who, "color": Data.CLASS_COLOR[who], "text": "Rejoint le paquet de %s." % Data.HEROES[who].name, "w": 240, "h": 210}]
	var i := await ui.choose("COFFRE", "Tu as trouvé %s !" % Data.def(card).name, opts, true, "Revendre : +%d or" % val, "", {"id": card, "lvl": 1})
	if i == 0:
		deck.append({"id": card, "lvl": 1})
		library_see(card)
		ui.toast("%s rejoint le paquet." % Data.def(card).name)
	elif i < 0:
		gold += val
		ui.set_gold(gold)
		Fx.number(self, h.position + Vector3(0, 0.6, 0), "+%d or" % val, Color(1.0, 0.85, 0.4))


func _rewards(type: String) -> void:
	var g := int((rng.randi_range(18, 28) + (20 if type == "elite" else 0)) * (1.0 + 0.25 * pacts.size()) * (1.15 if heroes.any(func(h): return h.trait_id == "radin") else 1.0) * (1.5 if next_mods.size() > 0 else 1.0) * (1.25 if relics.has("bourse") else 1.0))
	gold += g
	fight_loot.append("+%d or" % g)
	ui.set_gold(gold)
	var opts: Array = []
	var n := 4 if relics.has("oeil") else 3
	var tries := 0
	while opts.size() < n:
		var id := _card_roll(2 if (type == "elite" or next_mods.size() > 0) and opts.is_empty() else 1, "elite" if (type == "elite" or next_mods.size() > 0) else "combat")
		if opts.any(func(o): return o.card.id == id):
			continue
		# des archétypes différents à chaque butin : on sent vite qu'une classe a plusieurs routes
		var ar: String = Data.def(id).get("arch", "")
		tries += 1
		if tries < 24 and ar != "" and opts.any(func(o): return Data.def(o.card.id).get("arch", "") == ar and Data.def(o.card.id).get("owner", "") == Data.def(id).get("owner", "")):
			continue
		var up: bool = (type == "elite" and opts.is_empty()) or rng.randf() < [0.0, 0.25, 0.5][clampi(floor_i, 1, 3) - 1]  # cartes déjà forgées : acte 2 et 3
		opts.append({"card": {"id": id, "lvl": 2 if up else 1}})
	for o in opts:
		var ar: String = Data.def(o.card.id).get("arch", "")
		o["tag"] = "Pour " + Data.HEROES[Data.holder(o.card)].name + (" · route " + ar if ar != "" else "")  # qui la reçoit, et la route de sa classe
	var extra := _bonus_opts()
	opts.append_array(extra)
	var oid := ""
	var obj_roll := rng.randf() < obj_chance
	if type != "elite":
		obj_chance = clampf(obj_chance + (-0.1 if obj_roll else 0.1), 0.1, 0.9)  # ±10 % : pas de longues séries
	if type == "elite" or obj_roll:
		# une carte-objet en option de plus (niveau 2 en élite) ; passée, elle ne rapporte rien
		oid = _obj_roll(3 if type == "elite" else 2)
		opts.append({"card": {"id": oid, "lvl": 2 if type == "elite" else 1, "h": party[0]}, "tag": "Objet · au héros de ton choix"})
	var sub := "+%d or · ajoutez une carte au paquet (%d cartes)" % [g, deck.size()]
	var i := await ui.choose("BUTIN", sub, opts, true)
	if i >= 0 and oid != "" and i == opts.size() - 1:
		var hh := await _pick_hero("OBJET", "Qui prend %s ?" % Data.def(oid).name)
		gain_obj(oid, hh.key, int(opts[i].card.lvl))
	elif i >= 0:
		deck.append(opts[i].card)
		fight_loot.append(Data.def(opts[i].card.id).name)
		if Data.def(opts[i].card.id).get("rar", 1) == 4:
			ui.banner("Légendaire !", "%s rejoint le paquet de %s" % [Data.def(opts[i].card.id).name, Data.HEROES[Data.holder(opts[i].card)].name])
		await _replace_starter(opts[i].card)
	if type == "elite":
		# une élite : chaque autre héros a aussi sa carte (les paquets grandissent vers ~14 cartes en fin de run)
		var got: String = Data.holder(opts[i].card) if i >= 0 and opts[i].has("card") and i < opts.size() - (1 if oid != "" else 0) else ""
		for h in heroes:
			if h.key != got:
				await _hero_offer(h.key)
	if i < 0 and relics.has("sebile_cuivre"):
		gold += 20  # Sébile de cuivre : passer le butin de cartes
		fight_loot.append("+20 or")
		ui.set_gold(gold)
	if type == "elite":
		_gain_item(_roll_item(2))
		if mode == "descente" and step == fmap.size() - 1 and floor_i < 3:
			# le gardien de l'étage : la seule source normale de reliques de gardien
			await _relic_pick("RELIQUE DE GARDIEN", "Le gardien de l'étage laisse un pouvoir, et son prix", false, "boss")
		else:
			var defi: bool = pending_cards.any(func(p): return "|" in str(p))  # un défi relevé : le choix parmi trois
			await _relic_pick("RELIQUE D'ÉLITE", "Défi relevé : une relique parmi trois" if defi else "Les gardiens tombés laissent un trésor", false, "elite", 3 if defi else 1)


# ------------------------------------------------------------------ vocation et guildes (multiclasse)

func _hero_offer(k: String) -> void:
	## Butin d'élite : trois cartes de la classe d'un héros, pour lui.
	var opts: Array = []
	var tries := 0
	while opts.size() < 3 and tries < 40:
		tries += 1
		var id := _card_roll(1, "elite", k)
		if opts.any(func(o): return o.card.id == id):
			continue
		var ar: String = Data.def(id).get("arch", "")
		opts.append({"card": {"id": id, "lvl": 1}, "tag": "Pour %s" % Data.HEROES[k].name + (" · route " + ar if ar != "" else "")})
	var i := await ui.choose("BUTIN D'ÉLITE", "Une carte pour %s (paquet : %d cartes)" % [Data.HEROES[k].name, deck.filter(func(c): return Data.holder(c) == k).size()], opts, true)
	if i >= 0:
		deck.append(opts[i].card)
		fight_loot.append(Data.def(opts[i].card.id).name)
		await _replace_starter(opts[i].card)


func _replace_starter(ci: Dictionary) -> void:
	## La nouvelle carte peut prendre la place d'une carte de départ du même héros (gratuit) : le paquet change de visage
	## sans se diluer. Rien à remplacer : rien ne s'affiche.
	var k := Data.holder(ci)
	var idx: Array = range(deck.size()).filter(func(q): return deck[q].get("st", false) and Data.holder(deck[q]) == k)
	if idx.is_empty() or tuto:
		return
	var j := await ui.choose("REMPLACER ?", "%s rejoint le paquet de %s. Retirer une de ses cartes de départ ?" % [Data.def(ci.id).name, Data.HEROES[k].name],
		idx.map(func(q): return {"card": deck[q], "tag": "Retirer"}), true, "Garder les deux")
	if j >= 0:
		ui.toast("%s quitte le paquet." % Data.def(deck[idx[j]].id).name)
		deck.remove_at(idx[j])


func mastery(h: Unit) -> int:
	## Palier de maîtrise : I au départ, II à la vocation, III les rares de guilde, IV la légendaire.
	var m := 1
	for k in range(2, Data.MASTERY.size()):
		if h.pj >= Data.MASTERY[k]:
			m = k
	return m


func _gain_pj(h: Unit, n: int) -> void:
	var before := mastery(h)
	h.pj += n * (3 if tuto else 1)
	for lvl in range(before + 1, mastery(h) + 1):
		await _mastery_up(h, lvl)


func _mastery_up(h: Unit, lvl: int) -> void:
	if lvl == 2:
		if h.voc == "":
			await _choose_vocation(h)
		return
	if h.voc == "":
		return
	var g := Guildes.index(h.key, h.voc)
	var gl: Array = Guildes.LIST[g]
	var rars: Array = [3] if lvl == 3 else [4]
	var ids: Array = Guildes.cards_of(g, rars)
	ui.banner("Maîtrise %s" % Data.MASTERY_NAME[lvl], h.nm)  # rien d'annoncé : au joueur de découvrir


func _choose_vocation(h: Unit, second := false) -> void:
	## La cérémonie : pourquoi c'est grand, les 7 guildes possibles, puis trois vocations au choix.
	if not voc_intro_done:
		voc_intro_done = true
		await ui.vocation_intro(h)
	var others: Array = Data.HEROES.keys().filter(func(k): return k != h.key and k != h.voc and k != h.voc2)
	for i in range(others.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = others[i]
		others[i] = others[j]
		others[j] = t
	var picks: Array = others.slice(0, 3)
	var i: int = await ui.vocation_screen(h, picks) if not _testing() or args.has("voctest") or tuto else 0
	var k: String = picks[maxi(i, 0)]
	if second:
		h.voc2 = k
	else:
		h.voc = k
		h.wear_voc(k)
	var g := Guildes.index(h.key, k)
	var gl: Array = Guildes.LIST[g]
	ui.banner("Vocation : %s" % Data.HEROES[k].name, h.nm)
	if not second:
		# cadeau de vocation : une carte au choix, tout de suite dans le paquet (un vrai palier de puissance) :
		# la commune de la guilde, sa peu commune, et une carte de la classe apprise
		var ids: Array = []
		for rr in [1, 2]:
			var pool: Array = Guildes.cards_of(g, [rr])
			if pool.size() > 0:
				ids.append(pool[rng.randi_range(0, pool.size() - 1)])
		var own: Array = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].owner == k and Data.CARDS[id].rar == 1 and not Data.STARTER[k].has(id))
		if own.size() > 0:
			ids.append(own[rng.randi_range(0, own.size() - 1)])
		var opts: Array = ids.slice(0, 3).map(func(id): return {"card": {"id": id, "lvl": 1, "h": h.key}})
		if opts.size() > 0:
			var j := await ui.choose("CADEAU DE VOCATION", "%s rejoint %s : une de ces cartes entre dans son paquet." % [h.nm, gl[2]], opts, true, "Aucune")
			if j >= 0:
				deck.append(opts[j].card)
				library_see(opts[j].card.id)


# Maîtrise : elle rend les cartes multiclasses plus fréquentes et meilleures, sans rien verrouiller.
# Chance qu'un butin propose la case bonus, puis poids des raretés (commune, peu commune, rare, légendaire).
const VOC_CHANCE := {2: 0.55, 3: 0.8, 4: 1.0}
const VOC_RAR := {2: [70.0, 25.0, 4.5, 0.5], 3: [45.0, 35.0, 17.0, 3.0], 4: [25.0, 35.0, 30.0, 10.0]}


func _voc_pool(h: Unit, rar := 0) -> Array:
	## Cartes multiclasses de ce héros (classe de vocation et guilde), d'une rareté donnée (0 : 1 à 3).
	var out: Array = []
	for v in [h.voc, h.voc2]:
		if v == "":
			continue
		var g := Guildes.index(h.key, v)
		var rars: Array = [rar] if rar > 0 else [1, 2, 3]
		for id in Guildes.cards_of(g, rars):
			if Data.def(id).get("rar", 1) == 4 and (h.legend_seen.has(g) or deck.any(func(ci): return ci.id == id)):
				continue  # une légendaire de guilde ne sort qu'une fois par run
			out.append(id)
			out.append(id)  # la guilde pèse double face aux cartes de classe
		for id in Data.CARDS:
			if Data.CARDS[id].owner == v and not Data.STARTER[v].has(id) and rars.has(Data.CARDS[id].rar):
				out.append(id)
	return out


func _voc_pick(h: Unit) -> String:
	## Une carte multiclasse tirée selon la maîtrise : même au premier palier, la légendaire peut tomber.
	var w: Array = VOC_RAR[clampi(mastery(h), 2, 4)]
	if relics.has("sceau"):
		w = [w[0] * 0.6, w[1], w[2] * 1.6, w[3] * 1.5]
	var r: float = rng.randf() * (w[0] + w[1] + w[2] + w[3])
	var rar := 1
	while rar < 4 and r >= w[rar - 1]:
		r -= w[rar - 1]
		rar += 1
	for k in range(rar, 0, -1):  # rien à cette rareté : on redescend d'un cran
		var pool := _voc_pool(h, k)
		if pool.size() > 0:
			var id: String = pool[rng.randi_range(0, pool.size() - 1)]
			if Data.def(id).get("rar", 1) == 4:
				h.legend_seen[Guildes.CARDS[id].g] = true
			return id
	return ""


func _bonus_opts() -> Array:
	## La case bonus : une carte de vocation ou de guilde, en plus des trois cartes de classe.
	## Sa fréquence et sa rareté montent avec la maîtrise du héros.
	var out: Array = []
	var hs: Array = heroes.filter(func(u): return u.voc != "")
	if hs.size() > 0:
		var h: Unit = hs[fights % hs.size()]
		var n := 3 if relics.has("noblesse") else 1
		# maîtrise IV : la légendaire de sa guilde est assurée, une fois par run
		for v in [h.voc, h.voc2]:
			if v == "" or mastery(h) < 4:
				continue
			var g := Guildes.index(h.key, v)
			var leg: String = Guildes.cards_of(g, [4])[0]
			if not h.legend_seen.has(g) and not deck.any(func(ci): return ci.id == leg):
				h.legend_seen[g] = true
				out.append({"card": {"id": leg, "lvl": 1, "h": h.key}, "tag": "✦ Légendaire · %s" % h.nm})
				n -= 1
				break
		if out.is_empty() and rng.randf() >= VOC_CHANCE[clampi(mastery(h), 2, 4)] and not relics.has("noblesse"):
			n = 0
		var guard := 0
		while n > 0 and guard < 20:
			guard += 1
			var id := _voc_pick(h)
			if id == "" or out.any(func(o): return o.card.id == id):
				continue
			var kind := "Légendaire" if Data.def(id).get("rar", 1) == 4 else ("Guilde" if Guildes.CARDS.has(id) else "Vocation")
			out.append({"card": {"id": id, "lvl": 1, "h": h.key}, "tag": "✦ %s · %s" % [kind, h.nm]})
			n -= 1
	if relics.has("touriste"):
		var absent: Array = Data.HEROES.keys().filter(func(k): return not party.has(k))
		var ids: Array = Data.CARDS.keys().filter(func(id): return absent.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id))
		if ids.size() > 0:
			var h: Unit = heroes[rng.randi_range(0, heroes.size() - 1)]
			out.append({"card": {"id": ids[rng.randi_range(0, ids.size() - 1)], "lvl": 1, "h": h.key}, "tag": "✦ Touriste · %s" % h.nm})
	return out


func _pick_hero(title: String, sub: String, filter := Callable()) -> Unit:
	var hs: Array = heroes.filter(filter) if filter.is_valid() else heroes.duplicate()
	if hs.is_empty():
		return null
	var opts: Array = hs.map(func(h): return {"title": h.nm, "image": "res://assets/art/portrait_%s.png" % h.key, "color": Data.CLASS_COLOR[h.key],
		"text": ("Vocation : %s%s" % [Data.HEROES[h.voc].name, (" et " + Data.HEROES[h.voc2].name) if h.voc2 != "" else ""]) if h.voc != "" else "Pas encore de vocation\n%d / %d points de job" % [h.pj, Data.MASTERY[2]]})
	return hs[maxi(0, await ui.choose(title, sub, opts))]


func voc_line(h: Unit) -> String:
	## Une ligne pour la fiche du héros.
	var m := mastery(h)
	var nxt := "" if m >= 4 else " · %d / %d points vers la maîtrise %s" % [h.pj, Data.MASTERY[m + 1], Data.MASTERY_NAME[m + 1]]
	if h.voc == "":
		return "Maîtrise I%s" % nxt
	var g: Array = Guildes.LIST[Guildes.index(h.key, h.voc)]
	return "Vocation : %s (%s) · maîtrise %s%s" % [Data.HEROES[h.voc].name, g[2], Data.MASTERY_NAME[m], nxt]


# ------------------------------------------------------------------ bibliothèque : cartes découvertes

func _load_library() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://bibliotheque.cfg") == OK and cf.has_section("cartes"):
		for id in cf.get_section_keys("cartes"):
			library[id] = true
	if cf.has_section("bestiaire"):
		for id in cf.get_section_keys("bestiaire"):
			bestiary[id] = true


func bestiary_see(id: String) -> void:
	if bestiary.has(id) or not Data.FOES.has(id):
		return
	bestiary[id] = true
	if not _lib_dirty:
		_lib_dirty = true
		_save_library.call_deferred()


func cards_known() -> int:
	## Cartes découvertes (sans les niveaux 3 secrets ni l'équipement, rangés dans la même bibliothèque).
	return library.keys().filter(func(k): return not ("#" in k or k.begins_with("item:"))).size()


func library_see(id: String) -> void:
	if library.has(id):
		return
	library[id] = true
	if not _lib_dirty:
		_lib_dirty = true
		_save_library.call_deferred()


# ------------------------------------------------------------------ sauvegarde de la run

var save_path := "user://partie.sav"
const HERO_KEEP := ["trait_id", "hp", "base_hp", "base_move", "base_jump", "equip", "pj", "voc", "voc2", "legend_seen"]
var _no_save := false       # la run est finie : plus rien à reprendre


func _save_run() -> void:
	## Point de reprise entre deux salles : tout l'état de la run, pas le combat en cours.
	if _testing() or _no_save:
		return
	var d := {"v": 1, "mode": mode, "difficulty": difficulty, "pacts": pacts, "party": party, "floor_i": floor_i, "step": step,
		"fights": fights, "gold": gold, "floor_biomes": floor_biomes, "bag": bag, "relics": relics, "deck": deck, "elites_seen": elites_seen,
		"voc_intro_done": voc_intro_done, "run_seed": run_seed, "rng": rng.state, "minutes": _minutes(),
		"fmap": fmap, "lane": lane, "visited": visited, "heroes": [], "purges": purges, "rare_off": rare_off, "obj_chance": obj_chance, "myst_fight": myst_fight, "companion": companion, "seen_events": seen_events, "pending_mods": pending_mods}
	for h in heroes:
		var hd := {}
		for k in HERO_KEEP:
			hd[k] = h.get(k)
		d.heroes.append(hd)
	if mode == "aventure" and leader:
		d["leader"] = leader.cell
		d["rooms"] = rooms.map(func(r):
			var c: Dictionary = r.duplicate()
			c.erase("node")
			c.erase("fog")
			return c)
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(d))


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var d = str_to_var(FileAccess.get_file_as_string(save_path))
	return d if d is Dictionary and d.get("v", 0) == 1 else {}


func _save_info() -> String:
	var d := _read_save()
	if d.is_empty():
		return ""
	var noms: String = ", ".join(d.party.map(func(k): return Data.HEROES[k].name))
	return "Étage %d · %s · %s" % [d.floor_i, "Aventure" if d.mode == "aventure" else "Descente", noms]


func _clear_save() -> void:
	_no_save = true
	if not _testing() and FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _load_run() -> bool:
	var d := _read_save()
	if d.is_empty():
		return false
	_no_save = false
	difficulty = int(d.difficulty)  # variable statique : set() ne l'atteint pas
	for k in ["mode", "pacts", "party", "floor_i", "step", "fights", "gold", "floor_biomes", "bag", "relics", "deck",
			"voc_intro_done", "run_seed", "fmap", "lane", "visited"]:
		set(k, d[k])
	for tid in d.get("besace", []):  # vieille sauvegarde : la besace devient des cartes-objets
		if Data.TOOLS.has(tid):
			gain_obj(Data.obj_of(tid), party[0])
	bag = bag.map(func(id): return _item_now(str(id))).filter(func(id): return id != "")
	purges = int(d.get("purges", 0))
	rare_off = float(d.get("rare_off", -0.05))
	obj_chance = float(d.get("obj_chance", 0.4))
	myst_fight = float(d.get("myst_fight", 0.1))
	elites_seen = d.get("elites_seen", [])
	companion = str(d.get("companion", ""))
	seen_events = d.get("seen_events", [])
	pending_mods = d.get("pending_mods", [])
	run_start = Time.get_ticks_msec() - int(d.minutes) * 60000
	_make_party()
	for i in heroes.size():
		for k in HERO_KEEP:
			heroes[i].set(k, d.heroes[i][k])
		var eq: Dictionary = heroes[i].equip
		for sl in eq:
			eq[sl] = _item_now(str(eq[sl]))
		heroes[i].apply_gear()
		heroes[i].hp = int(d.heroes[i].hp)
		heroes[i].wear_voc(heroes[i].voc)
	rng.seed = run_seed
	rng.state = d.rng
	for ci in deck:
		library_see(ci.id)
	ui.refresh_relics(relics)
	ui.set_gold(gold)
	ui.banner("Reprise", "Étage %d" % floor_i)
	if mode == "aventure":
		_adventure(d)
	else:
		_loop()
	return true


func _item_now(id: String) -> String:
	## Vieille sauvegarde : une pièce retirée par le concile de l'équipement devient celle qui la remplace (ou rien).
	id = {"stylet": "poincon_voilier"}.get(id, id)
	return id if id == "" or Data.ITEMS.has(id) else ""


func _testing() -> bool:
	## Les essais n'écrivent ni dans la bibliothèque ni dans la sauvegarde du joueur.
	return ["autoplay", "uitest", "advtest", "capture", "cardtest", "voctest", "looktest", "hdtest", "haventest", "eventtest", "tutotest", "maptest", "tuto2run", "uxtest", "cardsheet"].any(func(k): return args.has(k))


func _save_library() -> void:
	_lib_dirty = false
	if _testing():
		return
	var cf := ConfigFile.new()
	for id in library:
		cf.set_value("cartes", id, true)
	for id in bestiary:
		cf.set_value("bestiaire", id, true)
	cf.save("user://bibliotheque.cfg")


func _card_roll(min_rar := 1, loot := "", only := "") -> String:
	## Hors butin : commune 60 %, peu commune 30 %, rare 10 %. Butin de combat (loot = "combat" / "elite", Slay the Spire) :
	## rare 3 % (élite 10 %), peu commune 37 % (40 %), décalés par la malchance : +1 % par commune tirée, retour à −5 % à la rare.
	var roll := rng.randf()
	var rar := 3 if roll < 0.1 else (2 if roll < 0.4 else 1)
	if loot != "":
		var r3 := (0.10 if loot == "elite" else 0.03) + rare_off + 0.02 * pacts.size()  # chaque pacte : +2 % de rares
		rar = 3 if roll < r3 else (2 if roll < (0.50 if loot == "elite" else 0.40) + rare_off else 1)
		if rar == 3:
			rare_off = -0.05
		elif rar == 1:
			rare_off = minf(rare_off + 0.01, 0.4)
	rar = maxi(rar, min_rar)
	var ids: Array = Data.CARDS.keys().filter(func(id): return (Data.CARDS[id].owner == only if only != "" else party.has(Data.CARDS[id].owner)) and Data.CARDS[id].get("rar", 1) == rar)
	return ids[rng.randi_range(0, ids.size() - 1)]


func _item_opt(id: String, price := 0) -> Dictionary:
	var it: Dictionary = Data.ITEMS[id]
	library_see("item:" + id)
	var title: String = it.name + ("  ·  %d or" % price if price > 0 else "")
	return {"title": title, "image": Data.item_icon(id), "text": Data.item_passives(id), "chips": Data.item_chips(id),
		"color": UI.ITEM_COL[it.rarity], "vignette": Data.item_slot(id)}


func _equipment() -> void:
	## Écran dédié : survol = effet de l'objet ; un objet du sac puis un héros pour équiper, un emplacement pour retirer.
	while _equip_act(await ui.equipment_screen(heroes, bag)):
		pass


func _equip_act(a: Dictionary) -> bool:
	## Un geste de l'écran d'équipement ; faux quand on le ferme.
	if a.has("equip"):
		var id: String = bag[a.equip]
		var u: Unit = heroes[a.hero]
		var slot: String = Data.ITEMS[id].slot
		bag.remove_at(a.equip)
		if u.equip[slot] != "":
			bag.append(u.equip[slot])
		u.equip[slot] = id
		u.apply_gear()
	elif a.has("unequip"):
		var u: Unit = heroes[a.hero]
		bag.append(u.equip[a.unequip])
		u.equip[a.unequip] = ""
		u.apply_gear()
	else:
		return false
	return true


# ------------------------------------------------------------------ lieux de repos

var haven_root: Node3D
const MERCHANT_LINES := ["« Tout se revend, même un souvenir. »", "« Assieds-toi, l'eau ne monte pas avant ce soir. »",
	"« Cette jarre ? Elle a vu trois déluges. »", "« Je fais crédit aux morts, jamais aux vivants. »",
	"« Les Hauts-Fonds donnent, les Hauts-Fonds reprennent. »"]
const FIRE_LINES := ["Le feu crépite. Quelqu'un fredonne un vieux break.", "L'eau de la fontaine couvre le bruit du monde.",
	"On refait les bandages, on raconte la dernière salle.", "Un moment sans initiative ni orientation."]


func _haven(kind: String) -> void:
	## Un lieu calme posé sur l'arène : étal et marchand, ou fontaine, kiosque et feu de camp.
	_build_room(run_seed + floor_i * (311 if kind == "marchand" else 577) + step, _biome(), 12, "cour")
	if haven_root:
		haven_root.queue_free()
	haven_root = Node3D.new()
	units_root.add_child(haven_root)
	var a := _haven_anchor()
	var p := board.world(a)
	var fire := a  # ce que l'escouade regarde : l'étal ou le feu
	if kind == "mystere":
		_haven_light(p + Vector3(0, 1.4, 0), Color(0.75, 0.8, 1.0), 1.4, 5.0)
	elif kind == "marchand":
		_haven_piece("haven_etal", p + Vector3(0.5, 0, 0), 0.0)
		_haven_piece("haven_jarres", board.world(a + Vector2i(-1, 0)), 0.0)
		_haven_piece("haven_jarres", board.world(a + Vector2i(-1, -1)), PI * 0.5)
		_haven_npc("marchand", board.world(a + Vector2i(2, 0)) + Vector3(-0.05, 0, 0.2), -0.5)  # au coin de l'étal, pas sous l'auvent
		_haven_light(p + Vector3(0.5, 1.6, 0.2), Color(1.0, 0.7, 0.4), 2.2, 5.0)
		_haven_piece("haven_tapis", board.world(a + Vector2i(0, 2)), 0.0)
		_haven_piece("haven_tapis", board.world(a + Vector2i(1, 2)), 0.0)
	else:
		_haven_piece("haven_fontaine", p + Vector3(0.5, 0, 0.5), 0.0)
		# le feu : une case dégagée à 2-3 pas de la fontaine, avec de la place autour pour s'asseoir
		var fs := -INF
		for c in board.walkable_cells():
			var dd := Battle.dist(c, a)
			if dd < 2 or dd > 4 or c in [a + Vector2i(1, 0), a + Vector2i(0, 1), a + Vector2i(1, 1)]:
				continue
			var sc := 0.0
			for d in Battle.RING8:
				if board.walkable(c + d) and absi(board.h[c + d] - board.h[c]) <= 1:
					sc += 1.0
			sc += 0.3 * (c.y - a.y) - absi(board.h[c] - board.h[a])
			if sc > fs:
				fs = sc
				fire = c
		_haven_piece("haven_feu", board.world(fire), 0.0)
		var fl := _haven_light(board.world(fire) + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.25), 3.0, 6.0)
		var tw := fl.create_tween().set_loops()
		tw.tween_property(fl, "light_energy", 2.2, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(fl, "light_energy", 3.2, 0.5).set_trans(Tween.TRANS_SINE)
		var wet := _haven_water(a)
		if wet.x > -50:
			_haven_piece("haven_kiosque", Vector3(wet.x, Board.WATER_Y - 0.1, wet.y), 0.0)
	# l'escouade se pose autour : les cases libres les plus proches du point de rendez-vous
	var meet: Vector2 = Vector2(a) + Vector2(0.0, 1.8) if kind == "marchand" else Vector2(fire) + Vector2(0.3, 0.6)
	var taken: Array = [a, a + Vector2i(1, 0), a + Vector2i(0, 1), a + Vector2i(1, 1), fire] if kind == "sanctuaire" else [a, a + Vector2i(1, 0), a + Vector2i(-1, 0), a + Vector2i(2, 0)]
	if kind == "mystere":
		taken = []
	var cands: Array = board.walkable_cells().filter(func(c): return not taken.has(c) and absi(board.h[c] - board.h[a]) <= 1)
	cands.sort_custom(func(x, y): return Vector2(x).distance_to(meet) < Vector2(y).distance_to(meet))
	if kind == "sanctuaire":  # en cercle autour du feu : à gauche, à droite, derrière
		var ring: Array = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(0, 1)].map(func(d): return fire + d).filter(func(c): return cands.has(c))
		cands = ring + cands.filter(func(c): return not ring.has(c))
	for i in heroes.size():
		var c: Vector2i = cands[i] if i < cands.size() else a
		heroes[i].place(c, board)
		heroes[i].face(fire - c)
	target = (p + Vector3(0.5, 0.6, 0.8)) if kind == "marchand" else (p + Vector3(0.5, 0, 0.5) + board.world(fire)) * 0.5 + Vector3(0, 0.5, 0)
	dist = 13.0
	pitch = 48.0
	orbit = true
	ui.dim_alpha = 0.22
	if kind == "marchand":
		ui.banner("Le Marchand", MERCHANT_LINES[rng.randi_range(0, MERCHANT_LINES.size() - 1)])
	elif kind == "sanctuaire":
		ui.banner("Halte", FIRE_LINES[rng.randi_range(0, FIRE_LINES.size() - 1)])
	else:
		ui.banner("Inconnu", "Quelque chose attend dans la salle")
	await get_tree().create_timer(1.6).timeout


func _haven_end() -> void:
	orbit = false
	ui.dim_alpha = 0.62
	if haven_root:
		haven_root.queue_free()
		haven_root = null
	if mode == "aventure":
		_show_dungeon()


func _haven_anchor() -> Vector2i:
	## La case la plus plate et la plus centrale : de la place pour l'étal ou la fontaine et l'escouade.
	var best := Vector2i(board.dim / 2, board.dim / 2)
	var bs := -INF
	var mid := Vector2(board.dim / 2.0, board.dim / 2.0)
	for c in board.walkable_cells():
		var s := 0.0
		for dx in range(-2, 4):
			for dz in range(-1, 4):
				var n: Vector2i = c + Vector2i(dx, dz)
				if board.walkable(n) and board.h[n] == board.h[c]:
					s += 1.0
				elif dz == -1 and dx in [0, 1]:
					s -= 20.0  # derrière l'étal, la place du marchand
		s -= Vector2(c).distance_to(mid) * 0.6
		if s > bs:
			bs = s
			best = c
	return best


func _haven_water(a: Vector2i) -> Vector2i:
	## Une eau libre à 4-7 cases pour le kiosque (-99 si l'arène n'en a pas).
	for r in range(5, 9):
		for c in board.kind.keys():
			if board.kind[c] == "water" and Battle.dist(c, a) == r:
				var ok := true
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if board.kind.get(c + d, "water") != "water":
						ok = false
				if ok:
					return c
	return Vector2i(-99, -99)


func _haven_piece(key: String, pos: Vector3, rot: float) -> void:
	var md := Board.mesh_of(key)
	var node := Node3D.new()
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material("glow" if part == "glow" else "prop")
		node.add_child(mi)
	node.position = pos
	node.rotation.y = rot
	haven_root.add_child(node)


func _haven_light(pos: Vector3, col: Color, energy: float, rng_: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	l.position = pos
	haven_root.add_child(l)
	return l


func _haven_npc(key: String, pos: Vector3, rot: float) -> void:
	var inst: Node3D = load("res://assets/u_%s.glb" % key).instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = Board.material("glow_unit" if String(mi.name).ends_with("glow") else "unit")
	var node := Node3D.new()
	node.add_child(inst)
	node.position = pos
	node.rotation.y = rot
	haven_root.add_child(node)
	var tw := inst.create_tween().set_loops()  # il se balance, tranquille
	tw.tween_property(inst, "rotation:z", 0.05, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(inst, "rotation:z", -0.05, 1.4).set_trans(Tween.TRANS_SINE)


func _merchant() -> void:
	await _haven("marchand")
	ui.speaker = "marchand"
	await _merchant_shop()
	ui.speaker = ""
	_haven_end()


var purges := 0  # épurations payées pendant la run : le prix monte (Slay the Spire)
# compteurs invisibles (Slay the Spire) : malchance des rares, chance d'objet ±10 %, embuscade des salles « ? »
var rare_off := -0.05
var obj_chance := 0.4
var myst_fight := 0.1


func _purge_price() -> int:
	return 50 if relics.has("ciseaux_epure") else 75 + 25 * purges


func _price(x: int) -> int:
	## Jeton du Comptoir : tout 20 % moins cher chez le marchand, services compris.
	return int(round(x * 0.8)) if relics.has("jeton_comptoir") else x


func _merchant_shop() -> void:
	var stock: Array = []
	while stock.size() < 4 + (1 if relics.has("bourse") else 0):  # quatre emplacements : quatre pièces à l'étal
		var id := _roll_item()
		if not stock.has(id):
			stock.append(id)
	var shelf := _shelf_stock()
	var tstock: Array = [_obj_roll(2), _obj_roll(3)]
	# trois reliques : deux tirées comme un coffre, une du palier marchand
	var rstock: Array = []
	for k in ["coffre", "coffre", "marchand"]:
		var r := _relic_draw(k, rstock.map(func(o): return o.id))
		if r != "":
			rstock.append({"id": r, "price": rng.randi_range(24, 30) * 5 if k == "marchand" else {"commune": 75, "peu_commune": 110, "rare": 160}[Data.RELICS[r].tier]})
	var done := {}
	while true:
		for o in shelf:
			if not o.has("p0"):
				o["p0"] = o.price
			o.price = _price(o.p0)  # le Jeton peut s'acheter en cours de route
		var opts: Array = _shelf_opts(shelf)
		var nc := opts.size()
		for id in stock:
			opts.append(_item_opt(id, _price(Data.PRICE[Data.ITEMS[id].rarity])))
		for id in tstock:
			opts.append({"title": "%s  ·  %d or" % [Data.def(id).name, _price(_obj_price(id))], "image": "res://assets/ui/tool_%s.png" % Data.def(id).tool, "text": "Carte-objet — " + Data.card_text(Data.card({"id": id, "lvl": 1, "h": party[0]})), "color": Data.CLASS_COLOR.objet})
		# services : un passage chacun par marchand ; déjà fait = coché, avec ce qui a été fait
		opts.append({"title": "Reliques", "glyph": "◆", "text": "À l'étal : " + ", ".join(rstock.map(func(o): return Data.RELICS[o.id].name)) if rstock.size() > 0 else "L'étal des reliques est vide."})
		var grey := Color("#8a8478")
		opts.append({"title": "Soins  ·  fait ✓", "glyph": "✓", "text": "Le groupe a déjà été soigné ici.", "color": grey} if done.has("heal") else
			{"title": "Soins  ·  %d or" % _price(35), "glyph": "✚", "text": "Chaque héros récupère 50 % de ses PV max."})
		opts.append({"title": "Épurer  ·  fait ✓", "glyph": "✓", "text": "Déjà épuré ici : %s retirée du paquet." % done.purge, "color": grey} if done.has("purge") else
			{"title": "Épurer  ·  %d or" % _price(_purge_price()), "glyph": "✂", "text": "Retirer une carte du paquet. Le prix monte à chaque épuration de la run." if not relics.has("ciseaux_epure") else "Retirer une carte du paquet. Ciseaux d'épure : toujours 50 or."})
		opts.append({"title": "Forge  ·  fait ✓", "glyph": "✓", "text": "Déjà forgé ici : %s." % done.forge, "color": grey} if done.has("forge") else
			{"title": "Forge  ·  %d or" % _price(35), "glyph": "⚒", "text": "Une carte du paquet gagne un niveau."})
		var i := await ui.choose("MARCHAND", "Vous avez %d or · une carte achetée rejoint le paquet de son héros" % gold, opts, true, "Partir")
		if i < 0:
			return
		if i < nc:
			if gold < shelf[i].price:
				ui.toast("Pas assez d'or.")
				continue
			gold -= shelf[i].price
			deck.append(shelf[i].card)
			shelf.remove_at(i)
			ui.set_gold(gold)
			continue
		i -= nc
		if i < stock.size():
			var id: String = stock[i]
			var price: int = _price(Data.PRICE[Data.ITEMS[id].rarity])
			if gold < price:
				ui.toast("Pas assez d'or.")
				continue
			gold -= price
			stock.remove_at(i)
			_gain_item(id)
		elif i < stock.size() + tstock.size():
			var tid: String = tstock[i - stock.size()]
			if gold < _price(_obj_price(tid)):
				ui.toast("Pas assez d'or.")
				continue
			var hh := await _pick_hero("OBJET", "Qui prend %s ?" % Data.def(tid).name)
			gold -= _price(_obj_price(tid))
			tstock.remove_at(i - stock.size())
			gain_obj(tid, hh.key)
		elif i == stock.size() + tstock.size():
			# l'étal des reliques : deux tirées comme un coffre, une du palier marchand
			if rstock.is_empty():
				continue
			var j := await ui.choose("RELIQUES", "Vous avez %d or" % gold, rstock.map(func(o): return _relic_opt(o.id, "%s  ·  %d or" % [Data.RELICS[o.id].name, _price(o.price)])), true, "← Retour")
			if j < 0:
				continue
			var ro: Dictionary = rstock[j]
			if gold < _price(ro.price):
				ui.toast("Pas assez d'or.")
				continue
			gold -= _price(ro.price)
			rstock.remove_at(j)
			ui.set_gold(gold)
			await _add_relic(ro.id)
		else:
			var k: String = ["heal", "purge", "forge"][i - stock.size() - tstock.size() - 1]  # paquet et équipe : portraits (fiche + paquet), P, carte d'étage
			if k == "deck":
				await view_deck()
				continue
			if k == "team":
				await _equipment()
				continue
			if done.has(k):
				ui.toast("Déjà fait chez ce marchand.")
				continue
			var price: int = _price({"heal": 35, "purge": _purge_price(), "forge": 35}[k])
			if gold < price:
				ui.toast("Pas assez d'or.")
				continue
			if k == "heal":
				for h in heroes:
					h.hp = mini(h.max_hp, h.hp + h.max_hp / 2)
				done.heal = true
			elif k == "forge":
				var before: Array = deck.map(func(c): return Data.level(c))
				if not await _forge("FORGE", "Quelle carte forger ? (+1 niveau · objet précieux vers le niveau 3 : 70 or)", gold):
					continue
				for q in deck.size():
					if q < before.size() and Data.level(deck[q]) != before[q]:
						done.forge = "%s au niveau %d" % [Data.def(deck[q].id).name, Data.level(deck[q])]
						if Data.def(deck[q].id).get("forge2", false) and Data.level(deck[q]) == 3:
							gold -= _price(35)  # Fiole, Élixir, Sablier, Bombe : la légende se paie double
			else:
				var copts: Array = deck.map(func(c): return {"card": c})
				var j := await ui.choose("ÉPURER", "Quelle carte retirer ?", copts, true)
				if j < 0:
					continue
				done.purge = Data.def(deck[j].id).name
				deck.remove_at(j)
				purges += 1
			gold -= price
		ui.set_gold(gold)


func _shelf_stock() -> Array:
	## L'étal à la Slay the Spire : deux communes, deux peu communes, une rare, une carte de guilde si quelqu'un a sa vocation.
	var out: Array = []
	var rs := [1, 1, 2, 2, 3]
	for si in rs.size():
		var r0: int = rs[si]
		var who: String = party[si % party.size()]  # chaque héros a au moins une carte à l'étal
		var taken: Array = out.map(func(o): return o.card.id)
		var ids: Array = []
		var rar: int = r0
		while ids.is_empty() and rar <= 3:  # les communes sont souvent toutes au paquet de départ : on monte d'un cran
			ids = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].owner == who and Data.CARDS[id].get("rar", 1) == rar and not Data.STARTER[Data.CARDS[id].owner].has(id) and not taken.has(id))
			if ids.is_empty():
				rar += 1
		if ids.size() > 0:
			out.append({"card": {"id": ids[rng.randi_range(0, ids.size() - 1)], "lvl": 1}, "price": [0, 50, 75, 150][rar] + rng.randi_range(-2, 2) * 5})
	var hs: Array = heroes.filter(func(u): return u.voc != "")
	if hs.size() > 0:
		var h: Unit = hs[rng.randi_range(0, hs.size() - 1)]
		var id := _voc_pick(h)
		if id != "":
			out.append({"card": {"id": id, "lvl": 1, "h": h.key}, "price": [0, 75, 100, 175, 260][Data.def(id).get("rar", 1)], "voc": "guilde" if Guildes.CARDS.has(id) else "vocation"})
	if out.size() > 0:
		var sale: Dictionary = out[rng.randi_range(0, out.size() - 1)]
		sale.price /= 2
		sale["sale"] = true
	return out


func _shelf_opts(shelf: Array) -> Array:
	return shelf.map(func(o):
		var who: String = Data.HEROES[Data.holder(o.card)].name
		return {"card": o.card, "tag": ("✦ %d or · soldée · %s" if o.has("sale") else ("✦ %d or · " + o.voc + " · %s" if o.has("voc") else "%d or · %s")) % [o.price, who]})


func _shelf(shelf: Array) -> void:
	while shelf.size() > 0:
		var opts: Array = _shelf_opts(shelf)
		var i := await ui.choose("ÉTAL DE CARTES", "Vous avez %d or · une carte achetée rejoint le paquet de son héros" % gold, opts, true, "Voir les objets et services")
		if i < 0:
			return
		if gold < shelf[i].price:
			ui.toast("Pas assez d'or.")
			continue
		gold -= shelf[i].price
		ui.set_gold(gold)
		deck.append(shelf[i].card)
		shelf.remove_at(i)


# ------------------------------------------------------------------ reliques : paliers, tirages, pertinence

const DROP_TIERS := ["commune", "peu_commune", "rare"]
const RELIC_EXCL := {"cle_ecluse": ["cloche", "remous", "nasse"]}  # exclusions mutuelles


func _relic_useful(r: String) -> bool:
	## Filtre de pertinence : une relique n'est proposée que si la run peut s'en servir (champ "need").
	var need: String = Data.RELICS[r].get("need", "")
	if need == "":
		return true
	var cards := func(p: Callable) -> bool: return deck.any(func(ci): return p.call(Data.card(ci)))
	var hero := func(p: Callable) -> bool: return heroes.any(p)
	match need:
		"glace", "vase":  # un étage restant de ce biome, ou une carte qui pose ce sol
			return floor_biomes.slice(floor_i - 1, 3).any(func(b): return Data.ground_of(b) == need) or cards.call(func(c): return c.get("ground", "") == need or c.get("ground_behind", "") == need)
		"poison":
			return cards.call(func(c): return int(c.get("poison", 0)) > 0 or c.get("trig", {}).has("poison")) or hero.call(func(h): return h.has_p("venin"))
		"tidiane":
			return hero.call(func(h): return h.key == "tidiane" or h.voc == "tidiane" or h.voc2 == "tidiane")
		"compagnon":
			return companion != ""
		"sans_compagnon":
			return companion == ""
		"piege":
			return cards.call(func(c): return c.get("place", "") in Battle.TRAP_KINDS or c.get("trap_behind", false) or c.has("traps_around") or c.get("tool", "") == "picots")
		"exec":
			return cards.call(func(c): return c.get("exec", false)) or hero.call(func(h): return h.has_p("execution"))
		"objet":
			return cards.call(func(c): return c.has("tool"))
		"vol":
			return cards.call(func(c): return c.get("steal", false) or c.get("place", "") == "collet")
		"soin":
			return cards.call(func(c): return (c.get("target", "") == "ally" and int(c.get("heal", 0)) > 0) or c.has("heal_all") or c.get("heal_adj", false))
		"distance":
			return cards.call(func(c): return c.kind == "atk" and c.has("range") and int(c.range[1]) >= 3)
		"provocation":
			return cards.call(func(c): return c.get("taunt", false))
		"attire":
			return cards.call(func(c): return int(c.get("pull", 0)) > 0)
		"multi":
			return cards.call(func(c): return int(c.get("hits", 1)) >= 2)
		"enchant":
			return deck.any(func(ci): return ci.has("ench"))
		"sans_vocation":
			return hero.call(func(h): return h.voc == "")
	return true


func _relic_ok(r: String, skip: Array = []) -> bool:
	## Jamais deux fois la même relique dans une run, ni deux reliques qui s'excluent, ni une relique inutile.
	if relics.has(r) or skip.has(r):
		return false
	for a in RELIC_EXCL:
		if (r == a and RELIC_EXCL[a].any(func(x): return relics.has(x))) or (relics.has(a) and RELIC_EXCL[a].has(r)):
			return false
	return _relic_useful(r)


func _relic_draw(kind: String, skip: Array = []) -> String:
	## Une relique selon sa source. coffre : 50/33/17 (40/38/22 au 3e étage) ; elite : 45/35/20 ; ancien : peu commune
	## ou rare ; event : comme un coffre, sans rare au 1er étage ; boss, marchand : leur palier. Repli sur le palier
	## inférieur s'il est vide. "" si rien ne convient.
	var tiers: Array = [kind]
	if not kind in ["boss", "marchand", "evenement"]:
		var odds: Array = {"elite": [45, 35, 20], "ancien": [0, 50, 50]}.get(kind, [40, 38, 22] if floor_i >= 3 else [50, 33, 17])
		if kind == "event" and floor_i == 1:
			odds = [60, 40, 0]
		var x := rng.randi_range(0, 99)
		var t := 0 if x < odds[0] else (1 if x < odds[0] + odds[1] else 2)
		tiers = [t, t - 1, t - 2, t + 1, t + 2].filter(func(k): return k >= 0 and k <= 2 and (k < 2 or odds[2] > 0)).map(func(k): return DROP_TIERS[k])
		if kind == "event" and rng.randf() < 0.3:
			tiers.push_front("evenement")  # ponytail: pas encore d'événement écrit pour eux ; à retirer quand chacun aura le sien
	for t in tiers:
		var pool: Array = Data.RELICS.keys().filter(func(r): return Data.RELICS[r].tier == t and _relic_ok(r, skip))
		if pool.size() > 0:
			return pool[rng.randi_range(0, pool.size() - 1)]
	return ""


func _relic_opt(r: String, title := "") -> Dictionary:
	library_see("relic:" + r)
	var d: Dictionary = Data.RELICS[r]
	return {"title": title if title != "" else d.name, "image": "res://assets/ui/relic_%s.png" % r, "glyph": d.glyph, "text": d.text, "vignette": Data.RELIC_TIERS[d.tier]}


func _relic_pick(title: String, subtitle: String, back := false, kind := "coffre", n := 3) -> bool:
	## Une relique parmi n. Gardien (kind "boss") hors bienfait : on peut la refuser contre 50 or.
	var ids: Array = []
	for k in n:
		var r := _relic_draw(kind, ids)
		if r != "":
			ids.append(r)
	if ids.is_empty():
		return true
	var refuse := kind == "boss" and not back
	var i := await ui.choose(title.to_upper(), subtitle, ids.map(func(r): return _relic_opt(r)), back or refuse, "Refuser : +50 or" if refuse else "← Retour")
	if i < 0:
		if refuse:
			gold += 50
			ui.set_gold(gold)
			return true
		return false
	await _add_relic(ids[i])
	return true


func _event_relic() -> void:
	## Une salle « ? » qui offre une relique : tirée comme un coffre, sans rare au 1er étage.
	var r := _relic_draw("event")
	if r != "":
		await _add_relic(r)


func _add_relic(r: String) -> void:
	relics.append(r)
	library_see("relic:" + r)
	if r in ["heron", "chaine_forcat"]:
		for h in heroes:
			h.base_move = maxi(1, h.base_move + (1 if r == "heron" else -1))  # Chaîne du forçat : -1 déplacement
			h.apply_gear()
	ui.refresh_relics(relics)
	if r == "livret":
		var h := await _pick_hero("LIVRET D'APPRENTI", "Qui prend sa vocation tout de suite ?", func(u): return u.voc == "")
		if h:
			var before := mastery(h)
			h.pj = maxi(h.pj, Data.MASTERY[2])
			for lvl in range(before + 1, mastery(h) + 1):
				await _mastery_up(h, lvl)
	elif r == "blason":
		var h := await _pick_hero("BLASON ÉCARTELÉ", "Qui prend une deuxième vocation ?", func(u): return u.voc2 == "")
		if h:
			if h.voc == "":
				h.pj = maxi(h.pj, Data.MASTERY[2])
				await _choose_vocation(h)
			else:
				await _choose_vocation(h, true)


func _sanctuary() -> void:
	await _haven("sanctuaire")
	await _sanctuary_menu()
	_haven_end()


func _sanctuary_menu() -> void:
	ui.team_on = true
	await _sanctuary_loop()
	ui.team_on = false


func _sanctuary_loop() -> void:
	## Un choix ; Braise de veille : deux choix différents. Couronne de plomb : plus de repos.
	var all := {"rest": {"title": "Se reposer", "glyph": "✚", "text": "Chaque héros récupère 35 % de ses PV max."},
		"forge": {"title": "Forger", "glyph": "⚒", "text": "Une carte du paquet gagne un niveau (5 au maximum)."}}
	var keys: Array = all.keys().filter(func(k): return k != "rest" or not relics.has("couronne_plomb"))
	var left := 2 if relics.has("braise_veille") else 1
	while left > 0 and keys.size() > 0:
		var again := left == 1 and relics.has("braise_veille")
		var i := await ui.choose("SANCTUAIRE", "Une eau calme sous les arches" + ("  ·  encore un choix" if again else ""), keys.map(func(k): return all[k]), again, "Partir")
		if i < 0:
			return
		var k: String = keys[i]
		if k == "rest":
			for h in heroes:
				h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.35))
			ui.toast("Le groupe reprend son souffle.")
		elif (k == "forge" and not await _forge("FORGE", "Quelle carte forger ? (+1 niveau)")):
			continue
		keys.erase(k)
		left -= 1


func _forge(title: String, subtitle: String, budget := -1) -> bool:
	## budget : l'or disponible à une forge payante ; -1 = forge gratuite (événement, bienfait).
	var idx: Array = []
	for k in deck.size():
		if Data.level(deck[k]) < Data.MAX_LVL:  # la forge passe outre le plafond des cartes-objets
			if Data.def(deck[k].id).get("forge2", false) and Data.level(deck[k]) == 2 and budget < 70:
				continue
			idx.append(k)
	if idx.is_empty():
		ui.toast("Tout le paquet est déjà au niveau 3.")
		return false
	var j := await ui.choose(title, subtitle, idx.map(func(k): return {"card": deck[k]}), true, "← Retour")
	if j < 0:
		return false
	if not await _confirm_upgrade(deck[idx[j]], _next_lvl(deck[idx[j]])):
		return await _forge(title, subtitle, budget)
	_level_up(idx[j])
	ui.toast("%s passe au niveau %d." % [Data.def(deck[idx[j]].id).name, deck[idx[j]].lvl])
	return true


func _next_lvl(ci: Dictionary) -> Dictionary:
	## La carte au niveau suivant, avec tout ce qu'elle porte (enchantement, propriétaire, charges) : l'aperçu dit vrai.
	var nc: Dictionary = ci.duplicate()
	nc["lvl"] = mini(Data.level(ci) + 1, Data.MAX_LVL)
	nc.erase("up")
	return nc


func _confirm_upgrade(before: Dictionary, after: Dictionary) -> bool:
	## Les trois niveaux côte à côte (on ne monte pas au 2 sans voir le 3) ; le niveau visé se clique pour valider.
	var gain := Data.upgrade_diff(before, after)
	var now := Data.level(before)
	var to := Data.level(after)
	var opts: Array = []
	for lv in range(1, Data.MAX_LVL + 1):
		var ci: Dictionary = before.duplicate()
		ci["lvl"] = lv
		ci.erase("up")
		ci.erase("bump")
		var tag := "Niveau %d" % lv
		if lv == now:
			tag += " · actuel"
		elif lv == to:
			tag = "✦ Niveau %d · valider" % lv
		elif lv > to:
			tag += " · ensuite"
		opts.append({"card": ci, "tag": tag})
	var i := await ui.choose("AMÉLIORER ?", "Niveau %d → %d : %s · cliquez le niveau %d pour valider" % [now, to, gain, to],
		opts, true, "Choisir une autre carte")
	if i == to - 1:
		ui.banner("%s · niveau %d" % [Data.def(after.id).name, to], gain)
		return true
	return false


func _level_up(k: int) -> void:
	var nc: Dictionary = deck[k].duplicate()
	nc["lvl"] = mini(Data.level(deck[k]) + 1, Data.MAX_LVL)
	nc.erase("up")
	if Data.def(nc.id).has("tool"):
		if nc.lvl == 2:
			nc["uses"] = maxi(int(nc.get("uses", 1)), 2)
		elif nc.lvl >= 3:
			nc.erase("uses")
			library_see(nc.id + "#3")
			var c := Data.card(nc)
			ui.banner("Légendaire : %s" % c.name, Data.card_text(c))
			shake(0.5)
	deck[k] = nc


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(dir: String, name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("capture ", name)


func _capture() -> void:
	var dir: String = args.capture
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = int(args.get("seed", "7"))
	rng.seed = run_seed
	floor_i = int(args.get("floor", "1"))
	var bi := int(args.get("biome", str(floor_i - 1)))
	floor_biomes = [bi, bi, bi]
	battle.champions = floor_i - 1
	deck = Data.starter(party)
	_make_party()
	heroes[0].equip.arme = "epee_ecluse"
	heroes[1].equip.bottes = "bottes_heron"
	if args.has("voc"):
		for h in heroes:
			h.voc = args.voc if args.voc != h.key else "lame"
			h.wear_voc(h.voc)
	var ids: Array = Data.BOSS if args.has("boss") else (Array(args.foes.split(",")) if args.has("foes") else Data.ENCOUNTERS[floor_i][0])
	var size := 22 if args.has("boss") else int(args.get("size", "18"))
	_build_room(run_seed, _biome(), size, "cour" if args.has("boss") else args.get("arch", ""), true)
	ui.show_hud(true)
	battle.start(heroes, ids, deck, relics)
	target = _units_center()
	battle.hand = Data.starter(party).slice(0, 5)
	if args.has("hand"):  # --hand=id1,id2 : une main choisie pour la capture
		battle.hand = Array(args.hand.split(",")).map(func(id): return {"id": id, "lvl": 1, "h": heroes[0].key})
	battle.changed.emit()
	await _frames(150)
	if args.has("screens"):  # --screens : fin de combat et coffre, pour vérifier la mise en page
		fight_loot = ["+24 or", "Dossière du guetteur", "Élixir de braise", "Estoc"]
		bag = ["oeil_vigilant"]
		heroes[0].pj = 5
		var f := func(): await _summary({heroes[0]: 3, heroes[1]: 0, heroes[2]: 1})
		f.call()
		await _frames(60)
		_shot(dir, "fin_combat")
		ui.picked.emit(0)
		await _frames(10)
		var g := func(): await _gain_obj_ui("o_elixir", 1, "COFFRE")
		g.call()
		await _frames(40)
		_shot(dir, "coffre_objet")
		get_tree().quit()
		return
	if args.has("kwhover"):  # --kwhover : la souris sur la 2e carte de la main, pour voir les encarts de mots-clés
		for q in ui._cards.size():
			ui.kw_force = ui._cards[q]
			await _frames(40)
			_shot(dir, "kw_%d" % q)
		get_tree().quit()
		return
	if args.has("focus"):  # --focus=o_fiole,o_bombe : la bibliothèque, chaque carte en grand avec ses trois niveaux
		ui.library_screen()
		await _frames(10)
		for fid in args.focus.split(","):
			ui._lib_focus(fid)
			await _frames(30)
			_shot(dir, "focus_" + fid)
			ui.lib_layer.get_child(-1).queue_free()
		get_tree().quit()
		return
	var hero: Unit = heroes[0]
	var foe: Unit = battle.foes[0]
	var c3 := _units_center()
	var far := 14.0 + board.dim * 1.05
	var views := [
		{"n": "01_jeu", "yaw": 45.0, "pitch": 40.0, "dist": far, "ui": true},
		{"n": "07_dessus", "yaw": 45.0, "pitch": 72.0, "dist": far * 1.2, "ui": false},
		{"n": "02_visee", "yaw": 45.0, "pitch": 40.0, "dist": far * 0.8, "ui": true, "card": 2},
		{"n": "03_large", "yaw": 135.0, "pitch": 44.0, "dist": far * 1.4, "ui": false},
		{"n": "04_rasant", "yaw": 225.0, "pitch": 18.0, "dist": far * 0.7, "ui": false},
		{"n": "05_heros", "yaw": 45.0, "pitch": 30.0, "dist": 7.0, "ui": false, "at": hero},
		{"n": "06_ennemi", "yaw": 45.0, "pitch": 30.0, "dist": 7.0, "ui": false, "at": foe},
	]
	for v in views:
		yaw = v.yaw
		pitch = v.pitch
		dist = v.dist
		target = c3 if not v.has("at") else v.at.position + Vector3(0, 0.7, 0)
		_snap_cam()
		ui.root.visible = v.ui
		if v.has("card"):
			# un ennemi à portée de Braise pour montrer une vraie visée
			var ora: Unit = heroes[2]
			for c in board.walkable_cells():
				if Battle.dist(c, ora.cell) == 3 and battle.unit_at(c) == null:
					foe.place(c, board)
					break
			target = ora.position
			_snap_cam()
			battle.select_card(v.card)
			hover = foe.cell
			refresh_hover()
		else:
			battle.card_sel = -1
			hover = null
			refresh_hover()
		await _frames(30)
		_shot(dir, v.n)
	# plan d'action : un ennemi collé au Garde, frappe en cours, caméra de jeu
	ui.root.visible = true
	var spot := hero.cell
	for d in Board.DIRS:
		if board.walkable(hero.cell + d) and battle.unit_at(hero.cell + d) == null:
			spot = hero.cell + d
			break
	foe.place(spot, board)
	foe.face(hero.cell - spot)
	yaw = 45.0
	pitch = 36.0
	dist = 13.0
	target = hero.position + Vector3(0, 0.6, 0)
	_snap_cam()
	battle.card_sel = -1
	battle.changed.emit()
	await _frames(10)
	if args.has("hover"):  # --hover=i : survol de la i-e carte de la main (encarts, carte créée)
		if args.has("hand"):  # le début du tour a remplacé la main : on la remet, au héros actif
			battle.hand = Array(args.hand.split(",")).map(func(id): return {"id": id, "lvl": 1, "h": battle.active.key})
			battle.changed.emit()
			await _frames(10)
		var cs: Array = ui.root.find_children("*", "Control", true, false).filter(func(n): return n.has_meta("kwcard") and n.is_visible_in_tree())
		cs.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		var mv := InputEventMouseMotion.new()
		mv.position = cs[int(args.hover)].get_global_rect().get_center()
		mv.global_position = mv.position
		pad = true
		get_viewport().push_input(mv)
		await _frames(25)
		_shot(dir, "09_survol")
	battle.play_card(0, foe.cell)
	await get_tree().create_timer(0.32).timeout
	_shot(dir, "08_action")
	await get_tree().create_timer(1.2).timeout
	get_tree().quit()


# ------------------------------------------------------------------ auto-jeu (test de fumée)

func _autoplay() -> void:
	## Joue plusieurs combats au hasard (toutes topologies, objets, champions, portail) pour
	## débusquer les erreurs d'exécution. Imprime un bilan puis quitte.
	Engine.time_scale = float(args.get("speed", "8"))  # --speed=400 : simulation d'équilibrage, sans attendre les animations
	_auto_overlays()
	var fights_n := int(args.get("autoplay", "6"))
	run_seed = int(args.get("seed", "3"))
	rng.seed = run_seed
	deck = Data.starter(party)
	# toutes les cartes de l'escouade : chaque mécanique passe au moins une fois
	if not args.has("starter"):  # --starter : seulement les paquets de départ (équilibrage)
		for id in Data.CARDS:
			if party.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id):
				deck.append({"id": id, "lvl": 2})
		for id in Guildes.CARDS:
			var pr := Guildes.pair(Guildes.CARDS[id].g)
			var who: String = pr[0] if party.has(pr[0]) else (pr[1] if party.has(pr[1]) else "")
			if who != "":
				deck.append({"id": id, "lvl": 2, "h": who})
	# cartes-objets : toutes (réparties) en test complet, la seule Fiole de départ avec --starter
	var oids: Array = Data.CARDS.keys().filter(func(x): return Data.CARDS[x].has("tool"))
	if args.has("starter") and not args.has("objs"):  # --objs : toutes les cartes-objets même avec --starter
		oids = ["o_fiole"]
	for q in oids.size():
		var olv := int(args.get("objlvl", "2" if not args.has("starter") else "1"))  # --objlvl=3 : les légendaires
		deck.append({"id": oids[q], "lvl": olv, "h": party[q % party.size()], "uses": 2 if olv < 3 else 0})
		if olv >= 3:
			library_see(oids[q] + "#3")
	_make_party()
	companion = str(args.get("companion", ""))  # --companion=crabe : une bête apprivoisée dans chaque combat
	relics = []
	for r in str(args.get("relics", "")).split(",", false):  # --relics=tuile,souffle : des reliques dès le départ
		if Data.RELICS.has(r):
			await _add_relic(r)
		else:
			print("relique inconnue : ", r)
	if party == ["garde", "lame", "oracle"]:
		heroes[0].equip = {"arme": "masse_os", "armure": "anneau_bouclier", "bottes": "bottes_vase", "bijou": "bague_charognard"}
		heroes[1].equip = {"arme": "kriss", "armure": "mantelet_feuilles", "bottes": "ecaille_eau", "bijou": "croc_brochet"}
		heroes[2].equip = {"arme": "sceptre_maree", "armure": "cire_passeur", "bottes": "bottes_fuyard", "bijou": "miroir"}
	var won := 0
	for n in fights_n:
		floor_i = int(args.get("floor", str(1 + n % 3)))  # --floor=2 : un acte seul (budget de rounds)
		floor_biomes = [n % Data.BIOMES.size(), (n + 1) % Data.BIOMES.size(), (n + 2) % Data.BIOMES.size()]
		for h in heroes:
			h.revive()
			h.hp = h.max_hp
		battle.objective = "portal" if n % 3 == 2 and not args.has("floor") else "kill"
		battle.champions = floor_i - 1
		battle.tool_rate = 1.0
		Battle.foe_mult = Data.DIFFICULTY[difficulty].foe[floor_i - 1]
		Battle.foe_hp = Data.FOE_HP[floor_i - 1]
		var sarch: String = "damier" if args.has("tactic") else Board.ARCHETYPES[n % 4]
		var ssize: int = 16 if Board.ARCHETYPES[n % 4] in ["cour", "terrasses"] else 18
		if args.has("oldsize"):  # --oldsize : les tailles d'avant le concile (référence)
			ssize = [14, 16, 18][n % 3]
		var ids: Array = Data.BOSS if n == fights_n - 1 and not args.has("floor") else Data.ENCOUNTERS[floor_i][n % Data.ENCOUNTERS[floor_i].size()]
		if args.has("elite"):  # --elite : les élites de l'acte, à tour de rôle
			ids = Data.ELITES[floor_i][n % Data.ELITES[floor_i].size()]
		if args.has("boss"):
			ids = Data.BOSS
		if args.has("foes"):
			ids = Array(args.foes.split(","))
		sarch = Data.ELITE_ARCH.get(ids[0], sarch) if not args.has("tactic") else sarch
		_build_room(run_seed + n * 101, _biome(), ssize, sarch, true)
		if not args.has("foes"):
			ids = compose(ids, "elite" if args.has("elite") else ("boss" if ids == Data.BOSS else "combat"))
		ui.show_hud(true)
		battle.start(heroes, ids, deck, relics)
		var turns := 0
		while not battle.over and battle.turn < 14:
			await _auto_turn()
			if battle.over:
				break
			turns = battle.turn
			await battle.end_turn()
		if battle.over and not battle.alive_heroes().is_empty():
			won += 1
		print("  sim ", JSON.stringify(battle.sim), " · or ", gold)
		print("combat %d (%s %d, %s, %s) : %d tours, héros vivants %d, ennemis vivants %d, PV héros %d · %s" % [n, board.archetype, board.dim, Data.BIOMES[_biome()].name, battle.objective, turns, battle.alive_heroes().size(), battle.alive_foes().size(), battle.alive_heroes().reduce(func(a, h): return a + h.hp, 0), ",".join(ids)])
		await get_tree().create_timer(0.5).timeout
	# boutique et équipement sans interface : juste les chemins de code
	bag = ["gantelet", "bottes_heron"]
	_gain_item("coeur_pierre", heroes[0])
	await open_chest(heroes[1])
	for k in ["coffre", "elite", "ancien", "event", "boss", "marchand"]:  # tirages de reliques et filtre de pertinence
		print("  relique ", k, " : ", _relic_draw(k))
	print("AUTOPLAY OK, %d/%d combats gagnés" % [won, fights_n])
	get_tree().quit()


func _eventtest() -> void:
	## Chaque nouvel événement, première option (sauf les combats) : capture puis on enchaîne les choix.
	var dir: String = args.eventtest
	DirAccess.make_dir_recursive_absolute(dir)
	party = ["garde", "oracle", "moine"]
	deck = Data.starter(party)
	_make_party()
	gold = 300
	gain_obj("o_fiole", party[0])
	ui.speaker = "neutre"
	for ev in EVENTS_NEW:
		await _haven("mystere")
		var done := [false]
		var f := func():
			await _event_new(ev, {"arch": "cour"})
			done[0] = true
		f.call()
		await _frames(30)
		_shot(dir, "ev_" + ev)
		var n := 0
		while not done[0] and n < 8:
			ui.picked.emit({"duel": 1, "mimique": -1}.get(ev, 0))
			n += 1
			await _frames(20)
		print("événement ", ev, " : ", "fini" if done[0] else "BLOQUÉ", " · or ", gold, " · compagnon ", companion, " · paquet ", deck.size())
		_haven_end()
	get_tree().quit()


func _haventest() -> void:
	## Captures des lieux de repos : l'étal du marchand, la fontaine et le feu de camp.
	var dir: String = args.haventest
	DirAccess.make_dir_recursive_absolute(dir)
	party = ["garde", "oracle", "moine"]
	deck = Data.starter(party)
	_make_party()
	for k in ["marchand", "sanctuaire"]:
		for b in [0, 11, 3]:
			floor_biomes = [b]
			floor_i = 1
			await _haven(k)
			_snap_cam()
			await _frames(40)
			_shot(dir, "%s_%d" % [k, b])
			if b == 0:
				for h in heroes:
					h.visible = false
				dist = 5.0
				_snap_cam()
				await _frames(20)
				_shot(dir, "%s_%d_nu" % [k, b])
				for h in heroes:
					h.visible = true
			_haven_end()
	get_tree().quit()


func _looktest() -> void:
	## Captures des héros hybrides : chaque classe avec quelques vocations, de près.
	var dir: String = args.looktest
	DirAccess.make_dir_recursive_absolute(dir)
	var ks: Array = Data.HEROES.keys()
	for k in ks.size():
		party = [ks[k], ks[k], ks[k]]
		deck = Data.starter(party)
		_make_party()
		_build_room(4242, 0, 12, "cour")
		for i in heroes.size():
			heroes[i].wear_voc(ks[(k + 1 + i * 3) % ks.size()])
		target = _units_center()
		dist = 7.0
		_snap_cam()
		await _frames(30)
		_shot(dir, "hybride_%s" % ks[k])
	get_tree().quit()


func _hdtest() -> void:
	## Captures d'un héros HD animé (assets/hd) de près : repos, sort, coup reçu, marche. --party=oracle,garde,lame
	var dir: String = args.hdtest
	DirAccess.make_dir_recursive_absolute(dir)
	deck = Data.starter(party)
	_make_party()
	_build_room(4242, 0, 12, "cour")
	var u: Unit = heroes[0]
	target = u.position + Vector3(0, 0.9, 0)
	dist = float(args.get("dist", "6"))
	pitch = float(args.get("pitch", str(pitch)))
	_snap_cam()
	await _frames(40)
	_shot(dir, "1_repos")
	for a in [["cast", 1.8, 22, "2_sort"], ["hit", 1.6, 12, "3_coup"], ["walk", 2.0, 14, "4_marche"]]:
		u.play(a[0], a[1])
		await _frames(a[2])
		_shot(dir, a[3])
	yaw += 150.0
	u.play("idle")
	_snap_cam()
	await _frames(20)
	_shot(dir, "5_dos")
	get_tree().quit()


func _voctest() -> void:
	## Captures des écrans de la vocation : explication, choix, guilde, butin bonus, bibliothèque.
	var dir: String = args.voctest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = 3
	rng.seed = run_seed
	deck = Data.starter(party)
	_make_party()
	_build_room(4242, 0, 16, "ecluse")
	_snap_cam()
	await _frames(30)
	var h: Unit = heroes[0]
	var f1 := func(): await ui.vocation_intro(h)
	f1.call()
	await _frames(40)
	_shot(dir, "1_explication")
	ui.picked.emit(0)
	await _frames(10)
	voc_intro_done = true
	var f2 := func(): await _choose_vocation(h)
	f2.call()
	await get_tree().create_timer(2.5).timeout  # l'écran apparaît en ~1,6 s (fondus en chaîne)
	_shot(dir, "2_choix")
	ui.picked.emit(0)
	await _frames(40)
	_shot(dir, "3_guilde")
	ui.picked.emit(-1)
	await _frames(10)
	h.pj = Data.MASTERY[3]
	fights = 0
	var f3 := func(): await _rewards("combat")
	f3.call()
	await _frames(40)
	_shot(dir, "4_butin")
	ui.picked.emit(-1)
	await _frames(10)
	for id in Guildes.CARDS.keys().slice(0, 40):
		library_see(id)
	var f4 := func(): await ui.library_screen()
	f4.call()
	await _frames(40)
	_shot(dir, "5_bibliotheque")
	for b in ui.lib_layer.find_children("*", "Button", true, false):
		if b.text == "Guildes":
			b.pressed.emit()
	await _frames(40)
	_shot(dir, "6_bibliotheque_guildes")
	for id in Data.ITEMS.keys().slice(0, 30):
		library.erase("item:" + id)  # la capture montre des pièces vues et des silhouettes, sans rien écrire
	for id in Data.ITEMS.keys().slice(0, 20):
		library["item:" + id] = true
	for b in ui.lib_layer.find_children("*", "Button", true, false):
		if b.text == "Équipement":
			b.pressed.emit()
	await _frames(40)
	_shot(dir, "6b_bibliotheque_equipement")
	ui.lib_closed.emit()
	await _frames(10)
	gold = 240
	var f5 := func(): await _shelf(_shelf_stock())
	f5.call()
	await _frames(40)
	_shot(dir, "7_etal")
	ui.picked.emit(-1)
	await _frames(10)
	var f5b := func(): await _merchant()
	f5b.call()
	await _frames(60)
	_shot(dir, "7b_marchand")
	ui.picked.emit(-1)
	await _frames(10)
	floor_i = 1
	step = 0
	lane = -1
	_gen_map()
	var f6 := func(): await ui.map_screen("ÉTAGE 1", "test", fmap, step, lane, [0, 1, 2], visited, "Équipement")
	f6.call()
	await _frames(40)
	_shot(dir, "8_carte")
	ui.picked.emit(0)
	await _frames(10)
	var f7 := func(): await ui.title_screen("Étage 2 · Descente · Garde, Lame, Oracle")
	f7.call()
	await _frames(40)
	_shot(dir, "9_titre")
	ui.picked.emit(0)
	await _frames(40)
	ui.show_hud(true)
	battle.start(heroes, Data.ENCOUNTERS[1][0], deck, relics)
	while not battle.player_turn:
		await get_tree().process_frame
	battle.orienting = true
	battle._orient_from = battle.active.facing
	pad = true  # la souris ne reprend pas la main
	hover = battle.active.cell + Vector2i(1, 0)
	refresh_hover()
	focus(battle.active.position)
	dist = 13.0
	ui.refresh()
	await _frames(40)
	_shot(dir, "10_orientation")
	get_tree().quit()


func _maptest() -> void:
	## Les douze cartes d'étage peintes, avec un parcours à moitié fait : -- --maptest=DIR
	var dir: String = args.maptest
	DirAccess.make_dir_recursive_absolute(dir)
	party = ["garde", "lame", "oracle"]
	_make_party()
	floor_i = 1
	step = 0
	rng.seed = 7
	_gen_map()
	visited = [Vector2i(0, 1), Vector2i(1, fmap[0][1].links[0])]
	lane = fmap[0][1].links[0]
	step = 2
	for bi in Data.BIOMES.size():
		var f := func(): await ui.map_screen("ÉTAGE 1", Data.BIOMES[bi].name, fmap, step, lane, fmap[1][lane].links, visited, "Équipement", bi)
		f.call()
		await _frames(30)
		_shot(dir, "carte_%02d" % bi)
		if bi == 0:
			# l'annonce de salle au survol : une capture par type de salle (et une salle à modificateur)
			var seen := {}
			for b: Button in ui.find_children("*", "Button", true, false):
				var key := b.text + ("+" if b.get_parent().get_children().any(func(o): return o is Label and o.position.distance_to(b.position) < 60) else "")
				if b.text.length() == 1 and not seen.has(key):
					seen[key] = true
					b.mouse_entered.emit()
					await _frames(6)
					_shot(dir, "annonce_%02d" % seen.size())
		ui.picked.emit(0)
		await _frames(5)
	get_tree().quit()


func _tutotest() -> void:
	## -- --tutotest=DIR : les cinq chapitres puis la version rapide, joués par le pilote ; une capture par étape et par écran.
	DirAccess.make_dir_recursive_absolute(args.tutotest)
	Engine.time_scale = 4.0
	_tuto_bot()
	await _tuto_from(0)
	await _tuto_play(5)
	await _tuto_end()
	print("initiation : ", heroes.map(func(h): return "%s pj %d voc %s" % [h.nm, h.pj, h.voc]), " · paquet ", deck.size(), " · reliques ", relics)
	get_tree().quit()


func _cardsheet() -> void:
	## -- --cardsheet=FICHIER.png [--cards=id,id] [--k=1.0] : une planche de cartes telles que dessinées en jeu.
	party = ["garde", "lame", "oracle"]
	_make_party()
	_build_room(3, 0, 12, "damier", false)
	var ids: Array = Array(args.get("cards", "estoc,fente,g_benir,c_interposition,charge,braise,seve,defi,pavois,g_onction").split(","))
	var k := float(args.get("k", "1.0"))
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.root.add_child(layer)
	var bgc := ColorRect.new()
	bgc.color = Color(0.1, 0.09, 0.1)
	bgc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bgc)
	var per := int(floor((ui.root.size.x - 40) / (UI.CARD.x * k + 30)))
	for i in ids.size():
		var w := ui.make_card({"id": ids[i], "lvl": 1, "h": "garde"})
		w.scale = Vector2.ONE * k
		w.pivot_offset = Vector2.ZERO
		w.position = Vector2(40 + (i % per) * (UI.CARD.x * k + 30), 50 + (i / per) * (UI.CARD.y * k + 50))
		layer.add_child(w)
	await _frames(30)
	get_viewport().get_texture().get_image().save_png(args.cardsheet)
	get_tree().quit()


func _uxtest() -> void:
	## -- --uxtest=DIR : les gestes du combat un par un (ciblage par portrait, échange, ruée, déplacement en deux clics,
	## butin au sol, défi relevé) ; chaque geste imprime OK ou ÉCHEC, une capture par étape.
	var dir: String = args.uxtest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = 7
	rng.seed = run_seed
	floor_i = 1
	floor_biomes = [0, 0, 0]
	if not args.has("party"):
		party = ["garde", "lame", "oracle"]
	deck = Data.starter(party)
	_make_party()
	_build_room(run_seed, 0, 12, "damier", false)
	ui.show_hud(true)
	battle.start(heroes, ["husk", "husk"], deck, relics)
	while not battle.player_turn:
		await get_tree().process_frame
	await _frames(60)
	_shot(dir, "01_debut")
	var ok := func(what: String, cond: bool): print(("OK     " if cond else "ÉCHEC  ") + what)
	var h: Unit = battle.active
	var give := func(ids: Array):
		while battle.busy:
			await get_tree().process_frame
		battle.hand = ids.map(func(id): return {"id": id, "lvl": 1, "h": h.key})
		battle.energy = 9
		battle.card_sel = -1
		battle.changed.emit()
	# 1. une carte de soin sur soi, par le portrait (le héros caché derrière la main)
	h.hp = h.max_hp - 8
	give.call(["g_benir"])
	await _frames(20)
	battle.select_card(0)
	await _frames(20)
	_shot(dir, "02_benir_choisie")
	battle.pick_hero(h)
	for q in 12:
		await _frames(30)
		if not battle.busy:
			break
	ok.call("Bénir sur soi par le portrait (PV %d/%d, armure %d)" % [h.hp, h.max_hp, h.block], h.hp > h.max_hp - 8 and h.block > 0)
	# 2. échange de place avec un allié
	var mate: Unit = battle.alive_heroes().filter(func(u): return u != h)[0]
	mate.place(h.cell + Vector2i(2, 0) if board.walkable(h.cell + Vector2i(2, 0)) and battle.unit_at(h.cell + Vector2i(2, 0)) == null else h.cell + Vector2i(0, 2), board)
	var a0 := h.cell
	var b0 := mate.cell
	for q in 40:
		if not battle.busy:
			break
		await _frames(15)
	give.call(["c_interposition"])
	await _frames(20)
	battle.select_card(0)
	await _frames(10)
	var tg: Array = battle.card_targets(Data.card(battle.hand[0]), h) if battle.card_sel >= 0 else []
	ok.call("Interposition : l'allié est une cible (%s dans %s)" % [b0, tg], tg.has(b0) or battle.card_sel < 0)
	if battle.card_sel >= 0:
		battle.click(b0)
	await _frames(20)
	for q in 60:
		if not battle.busy:
			break
		await _frames(10)
	ok.call("Interposition : places échangées (%s <-> %s)" % [h.cell, mate.cell], h.cell == b0 and mate.cell == a0)
	# 3. ruée hors de la ligne droite
	if battle.alive_foes().is_empty():
		print("ÉCHEC  plus d'ennemis vivants avant la ruée")
		get_tree().quit()
		return
	var foe: Unit = battle.alive_foes()[0]
	var spot := foe.cell + Vector2i(-2, 1)
	for c in [foe.cell + Vector2i(-2, 1), foe.cell + Vector2i(2, 1), foe.cell + Vector2i(1, 2), foe.cell + Vector2i(-1, -2), foe.cell + Vector2i(1, -2)]:
		if board._in(c) and board.walkable(c) and battle.unit_at(c) == null:
			spot = c
			break
	h.place(spot, board)
	h.moved = false
	give.call(["fente"])
	await _frames(20)
	battle.select_card(0)
	await _frames(20)
	await main_hover_shot(dir, "03_fente_visee", foe.cell)
	var hp0 := foe.hp
	var diag: bool = h.cell.x != foe.cell.x and h.cell.y != foe.cell.y
	ok.call("Fente : ennemi en diagonale ciblable (%s -> %s)" % [h.cell, foe.cell], diag and battle.card_targets(Data.card(battle.hand[0]), h).has(foe.cell))
	battle.click(foe.cell)
	await _frames(90)
	ok.call("Fente : a couru et frappé (PV %d -> %d, au contact : %s)" % [hp0, foe.hp, Battle.dist(h.cell, foe.cell) == 1], foe.hp < hp0 or not foe.alive)
	for q in 40:
		if not battle.busy:
			break
		await _frames(15)
	# 4. déplacement en deux clics
	h.moved = false
	give.call([])
	battle.select(h)
	var R := battle.reach(h)
	var goal: Vector2i = h.cell
	for c in R.cells:
		if Battle.dist(c, h.cell) >= 2:
			goal = c
			break
	target = h.position
	dist = 13.0
	var from := h.cell
	battle.click(goal)
	await _frames(30)
	await main_hover_shot(dir, "04_chemin_prevu", goal)
	print("plan : marque ", battle._plan_mark != null and battle._plan_mark.visible, " busy ", battle.busy, " sel ", battle.selected == h, " h ", h.cell, " but ", goal)
	ok.call("Déplacement : le 1er clic ne fait que viser", h.cell == from and battle._move_plan == goal)
	battle.click(goal)
	await _frames(90)
	ok.call("Déplacement : le 2e clic y va", h.cell == goal)
	# 5. course : cases orange
	battle.energy = 3
	await _frames(20)
	_shot(dir, "05_course")
	# 6. butin au sol, survolé
	var f2: Unit = battle.alive_foes()[-1] if battle.alive_foes().size() > 0 else null
	if f2:
		var keep: Vector2i = f2.cell
		f2.cell = h.cell + Vector2i(1, 1) if board.walkable(h.cell + Vector2i(1, 1)) and battle.unit_at(h.cell + Vector2i(1, 1)) == null else h.cell + Vector2i(-1, 1)
		f2.tool = "fiole"
		battle._drop(f2)
		f2.tool = ""
		var lc: Vector2i = f2.cell
		f2.cell = keep
		ok.call("Butin posé au sol en %s" % lc, battle.loot.has(lc))
		await _frames(30)
		await main_hover_shot(dir, "06_butin", lc)
	# 7. défi relevé
	ui.reward_flash({"id": "estoc", "lvl": 1, "h": h.key, "ench": "vampire"}, "Défi relevé")
	await _frames(40)
	_shot(dir, "07_defi")
	# 8. main survolée
	if battle.hand.size() == 0:
		give.call(["estoc", "fente", "c_interposition", "g_benir"])
	await _frames(30)
	ui._hover_card = 1
	await _frames(30)
	_shot(dir, "08_main_survol")
	tactic = true
	_apply_tactic()
	ui._hover_card = -1
	await _frames(30)
	_shot(dir, "09_tactique")
	tactic = false
	_apply_tactic()
	get_tree().quit()


func main_hover_shot(dir: String, name: String, c) -> void:
	hover = c
	refresh_hover()
	await _frames(20)
	_shot(dir, name)


func _tuto2run() -> void:
	## -- --tuto2run=DIR : version rapide, « Lancer une descente », puis les écrans de départ et le premier combat (captures).
	args["tutotest"] = args.tuto2run
	if go_run:
		_title()
		var n := 0
		for i in 60:
			await _frames(30)
			n += 1
			_shot(args.tuto2run, "apres_%02d" % n)
			if ui.overlay != null:
				ui.picked.emit(-1 if ui.last_n in [Data.PACTS.size(), Data.HEROES.size()] else (int(args.get("premier", "0")) if n < 3 else 0))
			if exploring and ui.overlay == null and not _adv_busy:
				var goal: Vector2i = leader.cell
				for d in Board.DIRS:
					if aboard.walkable(leader.cell + d * 2) and not _adv_path(leader.cell + d * 2).is_empty():
						goal = leader.cell + d * 2
				print("tuto2run : exploration, chef en ", leader.cell, " -> ", goal, " · busy ", _adv_busy)
				_adv_click(goal)
			if battle.active != null and battle.player_turn:
				print("tuto2run : combat en cours, héros actif ", battle.active.nm, " · Engine.time_scale ", Engine.time_scale)
				break
		get_tree().quit()
		return
	_tuto_bot()
	await _tuto_from(0)


func _tuto_bot() -> void:
	## Pilote de --tutotest : il fait le geste attendu (par les mêmes portes que le joueur) et capture avant chaque geste.
	var dir: String = args.tutotest
	var n := 0
	while is_inside_tree():
		await _frames(24)
		if ui.overlay != null:
			n += 1
			_shot(dir, "%03d_ecran" % n)
			var p = bot_pick
			bot_pick = 0  # avant l'emit : l'écran suivant peut poser sa propre réponse tout de suite
			if p is Dictionary:
				ui._eq_act = p
			ui.picked.emit(0 if p is Dictionary else p)
			continue
		if not tuto or tuto_i >= tuto_steps.size() or not battle.player_turn or battle.busy or battle.over or not ui.hud.visible:
			continue
		var s: Dictionary = tuto_steps[tuto_i]
		var tag := "%s_%02d" % ["rapide" if tuto_k == 5 else "ch%d" % (tuto_k + 1), tuto_i + 1]
		n += 1
		_shot(dir, "%03d_%s_%s" % [n, tag, s.do])
		if tuto_gate("move", Vector2i(-1, -1)) == "":
			print("ERREUR initiation : un geste hors consigne passe (", tag, ")")
		match s.do:
			"move", "prop":
				battle.click(s.at)
			"play":
				var i: int = battle.hand.map(func(ci): return ci.id).find(s.card)
				if i < 0:
					print("ERREUR initiation : ", s.card, " absente de la main (", tag, ")")
					continue
				battle.select_card(i)
				if battle.card_sel >= 0:
					await _frames(24)
					n += 1
					_shot(dir, "%03d_%s_cible" % [n, tag])
					battle.click(s.at)
			"face":
				var f := _tuto_near()
				battle.face_cell(f.cell)
			"ok":
				_tuto_ok()
			_:
				battle.end_turn()


func _savetest() -> void:
	## Sauvegarde puis reprise, en Descente et en Aventure, dans un fichier à part.
	save_path = "user://essai_partie.sav"
	var fail := func(m): print("ÉCHEC : ", m)
	run_seed = 7
	rng.seed = run_seed
	floor_biomes = [0, 1, 2]
	deck = Data.starter(party)
	_make_party()
	heroes[1].pj = 5
	heroes[1].voc = "oracle"
	heroes[0].equip.arme = "masse_os"
	gold = 123
	mode = "descente"
	_gen_map()
	_save_run()
	var d := _read_save()
	if d.is_empty() or d.fmap.size() != ROOMS_PER_FLOOR or d.gold != 123 or d.heroes[1].voc != "oracle":
		fail.call("descente")
	mode = "aventure"
	_gen_dungeon()
	rooms[1].done = true
	rooms[2].seen = true
	var types: Array = rooms.map(func(r): return r.type)
	if types.count("marchand") < 2:
		fail.call("second marchand : %s" % [types])
	_save_run()
	gold = 0
	heroes[1].voc = ""
	_load_run()
	await _frames(5)
	if gold != 123 or heroes[1].voc != "oracle" or heroes[1].pj != 5 or heroes[0].equip.arme != "masse_os":
		fail.call("héros ou or")
	if rooms.map(func(r): return r.type) != types or not rooms[1].done or not rooms[2].seen:
		fail.call("donjon")
	_clear_save()
	print("SAUVEGARDE OK" if not FileAccess.file_exists(save_path) else "ÉCHEC : fichier resté")
	get_tree().quit()


func _cardtest() -> void:
	## Banc d'essai : chaque carte de guilde est jouée en vrai combat, à un niveau qui tourne (1 à 3).
	Engine.time_scale = 10.0
	_auto_overlays()
	run_seed = int(args.get("seed", "5"))
	rng.seed = run_seed
	deck = Data.starter(party)
	_make_party()
	var ids: Array = Array(args.ids.split(",")) if args.has("ids") else Guildes.CARDS.keys()
	var n := 0
	var ok := 0
	var fresh := true
	while n < ids.size():
		if fresh or battle.over or battle.alive_foes().size() < 2 or battle.alive_heroes().size() < 2:
			fresh = false
			if battle.heroes.size() > 0 and not battle.over:
				# on clôt le combat en cours comme le jeu le ferait, avant d'en bâtir un autre
				for f in battle.alive_foes():
					battle.kill(f)
			if battle.heroes.size() > 0:
				await get_tree().create_timer(1.6).timeout  # _finish rend la main après 1,1 s
			for h in heroes:
				h.revive()
				h.hp = h.max_hp
			battle.tool_rate = 1.0
			_build_room(run_seed + n * 7, n % Data.BIOMES.size(), 14, Board.ARCHETYPES[n % 4], true)
			printerr("salle reconstruite, mémoire %d Mo" % (OS.get_static_memory_usage() / 1048576))
			ui.show_hud(true)
			battle.start(heroes, Data.ENCOUNTERS[2][n % Data.ENCOUNTERS[2].size()], deck, relics)
		while not battle.player_turn and not battle.over:
			await get_tree().process_frame
		if battle.over or battle.active == null:
			fresh = true
			continue
		var h: Unit = battle.active
		var id: String = ids[n]
		n += 1
		battle.hand.append({"id": id, "lvl": 1 + n % 3, "h": h.key})
		battle.energy = 10
		var i := battle.hand.size() - 1
		var c := Data.card(battle.hand[i])
		var tg := battle.card_targets(c, h)
		if tg.is_empty():
			# rapproche le héros d'une case d'où la carte a une cible
			var from := h.cell
			for cell in board.walkable_cells():
				if battle.unit_at(cell) != null:
					continue
				h.cell = cell
				if battle.card_targets(c, h).size() > 0:
					break
				h.cell = from
			if h.cell != from:
				var to := h.cell
				h.cell = from
				h.place(to, board)
			tg = battle.card_targets(c, h)
		if tg.is_empty():
			print("pas de cible : ", id)
			battle.hand.pop_back()
			continue
		printerr("joue ", id, " (niv ", c.lvl, ", ", h.key, ")")
		await battle.play_card(i, tg[0])
		ok += 1
		if battle.player_turn and not battle.over and battle.played >= 3:
			await battle.end_turn()
	print("CARDTEST OK, %d / %d cartes jouées" % [ok, ids.size()])
	get_tree().quit()


func _auto_overlays() -> void:
	## Partie automatique : les écrans ouverts en plein combat (Découvre, Braquage...) prennent une option.
	while is_inside_tree():
		await get_tree().process_frame
		if ui.overlay != null:
			await _frames(6)
			if ui.overlay != null:
				ui.picked.emit(maxi(0, ui.last_n - 1))


func _auto_turn() -> void:
	## Un tour naïf du héros actif : il s'approche, se sert d'un objet, joue ce qui a une cible.
	while not battle.player_turn and not battle.over:
		await get_tree().process_frame
	var hh: Unit = battle.active
	if hh == null or battle.over:
		return
	for h in [hh]:
		var R := battle.reach(h)
		var foes_ := battle.alive_foes()
		if foes_.is_empty():
			return
		var goal: Vector2i = battle.board.portal if battle.objective == "portal" else foes_[0].cell
		var best: Vector2i = h.cell
		for c in R.cells:
			if Battle.dist(c, goal) < Battle.dist(best, goal):
				best = c
		if best != h.cell:
			await battle.click(best)
		for pc in board.props.keys():
			if board.props.get(pc, "") == "coffre" and Battle.dist(pc, h.cell) == 1 and not h.moved:
				await battle.interact(h, pc)
	var guard := 0
	while guard < 12 and not battle.over and battle.player_turn:
		guard += 1
		var played := false
		for i in battle.hand.size():
			var c := Data.card(battle.hand[i])
			var h := battle.owner_of(c)
			if h == null or not h.alive or battle.cost_of(c) > battle.energy:
				continue
			var tg := battle.card_targets(c, h)
			if tg.is_empty():
				continue
			await battle.play_card(i, tg[0])
			played = true
			break
		if not played:
			break


func _units_center() -> Vector3:
	## Milieu de l'emprise des unités : c'est là que se joue le combat, pas au centre de la carte.
	var box := AABB(heroes[0].position, Vector3.ZERO)
	for u in battle.heroes + battle.foes:
		box = box.expand(u.position)
	return box.get_center()


func _uitest() -> void:
	## Vérifie l'interface avec de vrais clics : carte de butin, fiche d'ennemi, menu.
	var dir: String = args.uitest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = 7
	rng.seed = run_seed
	deck = Data.starter(party)
	_make_party()
	_build_room(run_seed, 0, 16, "", true)
	ui.show_hud(true)
	for oid in ["o_fiole", "o_bombe", "o_arbre"]:
		gain_obj(oid, party[0])
	battle.tool_rate = 1.0
	fights = 9  # des ennemis équipés à coup sûr ou presque
	heroes[0].equip = {"arme": "epee_ecluse", "armure": "brigandine_noyee", "bottes": "bottes_vase", "bijou": "croc_brochet"}
	heroes[0].apply_gear()
	heroes[1].voc = "oracle"
	args["porteur"] = "marque"
	battle.start(heroes, Data.ENCOUNTERS[1][0], deck, relics)
	args.erase("porteur")
	target = _units_center()
	_snap_cam()
	await _frames(90)
	var foe: Unit = battle.foes[0]
	pad = true  # la souris réelle ne doit pas écraser le survol simulé
	battle.click(foe.cell)
	hover = foe.cell
	refresh_hover()
	await _frames(20)
	_shot(dir, "fiche")
	print("fiche visible : ", ui.sheet_plate.visible, " · zone : ", battle.reach(foe).cells.size())
	ui.toggle_menu()
	await _frames(20)
	_shot(dir, "menu")
	ui.toggle_menu()
	ui.hero_sheet(heroes[0])
	await _frames(20)
	_shot(dir, "fiche_heros")
	var carrier: Array = battle.foes.filter(func(f): return f.card_id != "")
	if carrier.size() > 0:
		hover = carrier[0].cell
		refresh_hover()
		await _frames(10)
		_shot(dir, "porteur")
	ui.sheet_layer.queue_free()
	ui.sheet_layer = null
	print("ennemis équipés : ", battle.foes.map(func(f): return "%s %s" % [f.nm, f.equip.values().filter(func(x): return x != "")]))
	while not battle.player_turn:
		await get_tree().process_frame
	print("main du héros actif (%s) : %s" % [battle.active.nm, battle.hand.all(func(ci): return Data.card(ci).owner == battle.active.key)])
	ui.show_hud(false)
	var got := [-2]
	var chooser := func(): got[0] = await _rewards_probe()
	chooser.call()
	await _frames(30)
	_shot(dir, "butin")
	var holder: Control = ui.overlay.find_children("*", "Control", true, false).filter(func(c): return is_equal_approx(c.custom_minimum_size.x, UI.CARD.x * 1.55))[1]
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = holder.get_global_rect().get_center()
	ev.global_position = ev.position
	get_viewport().push_input(ev)
	await _frames(10)
	print("carte de butin cliquée : ", got[0])
	# écrans de run : escouade, carte d'étage, butin rare
	var probe := func(): await _draft()
	probe.call()
	await _frames(30)
	_shot(dir, "escouade")
	ui.picked.emit(-1)
	await _frames(10)
	var ro := func(): await ui.trait_roulette(party, _roll_traits())
	ro.call()
	await _frames(40)
	_shot(dir, "roulette_tourne")
	await _frames(200)
	_shot(dir, "roulette")
	ui.picked.emit(0)
	await _frames(10)
	var pk := func(): await _pick_pacts()
	pk.call()
	await _frames(30)
	ui.picked.emit(1)  # un pacte coché : l'icône allumée
	await _frames(30)
	_shot(dir, "pactes")
	ui.picked.emit(-1)
	await _frames(10)
	for sc in [["mode", func(): await _pick_mode()], ["difficulte", func(): await _pick_difficulty()]]:
		sc[1].call()
		await _frames(30)
		_shot(dir, sc[0])
		ui.picked.emit(0)
		await _frames(10)
	bag = ["kriss", "bottes_heron", "miroir", "coeur_pierre", "sceptre_maree"]
	heroes[0].equip.arme = "epee_ecluse"
	heroes[0].apply_gear()
	var eq := func(): await _equipment()
	eq.call()
	await _frames(30)
	var tiles: Array = ui.overlay.find_children("*", "PanelContainer", true, false).filter(func(c): return c.custom_minimum_size == Vector2(76, 76))
	pad = true
	var mv := InputEventMouseMotion.new()
	mv.position = tiles[1].get_global_rect().get_center()
	mv.global_position = mv.position
	get_viewport().push_input(mv)
	await _frames(20)
	_shot(dir, "equipement")
	ui.picked.emit(0)
	await _frames(10)
	# étal du marchand et bibliothèque (vignettes d'équipement et de reliques)
	gold = 400
	ui.speaker = "marchand"
	var shop := func(): await _merchant_shop()
	shop.call()
	await _frames(40)
	_shot(dir, "marchand")
	ui.picked.emit(-1)
	await _frames(20)
	ui.speaker = ""
	for r in Data.RELICS.keys().slice(0, 5):
		library_see("relic:" + r)
	var lib := func(): await ui.library_screen()
	lib.call()
	await _frames(20)
	for b in ui.lib_layer.find_children("*", "Button", true, false):
		if b.text == "Reliques":
			b.pressed.emit()
	await _frames(20)
	_shot(dir, "bibli_reliques")
	ui.lib_closed.emit()
	await _frames(10)
	floor_i = 1
	step = 0
	_gen_map()
	visited = [Vector2i(0, 1)]
	lane = 1
	step = 1
	var mp := func(): await ui.map_screen("ÉTAGE 1", "test", fmap, step, lane, fmap[0][1].links, visited, "Équipement · 0 objet(s) au sac")
	mp.call()
	await _frames(30)
	_shot(dir, "carte")
	ui.picked.emit(0)
	await _frames(10)
	var rw := func(): await ui.choose("BUTIN", "test", [{"card": {"id": "tourelle", "lvl": 1}}, {"card": {"id": "voie", "lvl": 3}}, {"card": {"id": "harpon", "lvl": 3}}], true)
	rw.call()
	await _frames(30)
	_shot(dir, "butin2")
	ui.picked.emit(-1)
	await _frames(10)
	pending_cards = ["c_signal_meute"]
	var fc := func(): await _flush_cards()
	fc.call()
	await _frames(30)
	_shot(dir, "carte_trouvee")
	ui.picked.emit(-1)
	await _frames(10)
	var ap := func(): await _confirm_upgrade({"id": "charge", "lvl": 2}, {"id": "charge", "lvl": 3})
	ap.call()
	await _frames(30)
	_shot(dir, "apercu")
	ui.picked.emit(-1)
	await _frames(10)
	# survol d'un objet du décor : l'infobulle de la case
	ui.show_hud(true)
	if board.props.size() > 0:
		var pc: Vector2i = board.props.keys()[0]
		target = board.world(pc)
		_snap_cam()
		await _frames(5)
		var sp := cam.unproject_position(board.world(pc) + Vector3(0, 0.6, 0))
		pad = true  # la souris réelle ne doit pas écraser le survol simulé
		hover = _pick(cam.project_ray_origin(sp), cam.project_ray_normal(sp))
		refresh_hover()
		await _frames(10)
		print("survol objet : ", hover == pc, " · ", ui.tip.text, " · plaque ", ui.tip_plate.get_global_rect())
		ui.toast("Test : message éphémère")
		await _frames(8)
		print("toast : ", ui.toast_plate.get_global_rect())
		_shot(dir, "survol")
	get_tree().quit()


func _rewards_probe() -> int:
	var opts: Array = []
	for id in ["frappe", "braise", "estoc"]:
		opts.append({"card": {"id": id, "lvl": 1}})
	return await ui.choose("BUTIN", "test", opts, true)


# ------------------------------------------------------------------ mode aventure

func _pick_mode() -> String:
	var i := await ui.choose("MODE", "Deux façons de descendre", [
		{"title": "Descente", "glyph": "⇣", "art": "res://assets/ui/mode_descente.png", "w": 380, "text": "Carte d'étage à trois voies : on choisit ses salles, combat après combat.", "color": UI.GOLD},
		{"title": "Aventure", "glyph": "✥", "art": "res://assets/ui/mode_aventure.png", "w": 380, "text": "On mène l'escouade dans le donjon, salle par salle, dans le brouillard. Croiser un monstre lance le combat.", "color": Color("#8fd0a0")},
	])
	return ["descente", "aventure"][i]


func _adventure(saved := {}) -> void:
	## Trois étages de donjon ; un gardien d'élite garde l'escalier, le Gardien de l'Écluse attend au dernier.
	while true:
		_gen_dungeon(saved)
		_show_dungeon()
		if saved.is_empty():
			await _ancient()
		saved = {}
		_save_run()
		_explore_hud()
		var r: String = await floor_done
		if r == "lost":
			_clear_save()
			await ui.game_over(false, "Étage %d, %d combats remportés, %d min, difficulté %d/5." % [floor_i, fights, _minutes(), difficulty + 1])
			new_run.call_deferred()
			return
		if r == "won":
			_clear_save()
			await ui.game_over(true, "Le Gardien est tombé : %d combats, %d min, difficulté %d/5." % [fights, _minutes(), difficulty + 1])
			new_run.call_deferred()
			return
		floor_i += 1
		obj_chance = 0.4
		ui.banner("Étage %d" % floor_i, Data.BIOMES[_biome()].name)


func _gen_dungeon(saved := {}) -> void:
	var b: Dictionary = Data.BIOMES[_biome()]
	if aboard == null:
		aboard = Board.new()
		add_child(aboard)
		adv_root = Node3D.new()
		add_child(adv_root)
	for ch in adv_root.get_children():
		ch.queue_free()
	aboard.generate(run_seed + floor_i * 4447, b, 36 if floor_i == 1 else 45, "donjon", false)
	aboard.build_visuals()
	# distances dans le graphe des salles : le gardien au plus loin du départ
	var start_i := _room_index(aboard.rects, aboard.start)
	var gd := {start_i: 0}
	var q: Array = [start_i]
	while q.size() > 0:
		var a: int = q.pop_front()
		for l in aboard.links:
			for pair in [[l[0], l[1]], [l[1], l[0]]]:
				if pair[0] == a and not gd.has(pair[1]):
					gd[pair[1]] = gd[a] + 1
					q.append(pair[1])
	var far := start_i
	for k in gd:
		if gd[k] > gd[far]:
			far = k
	var others: Array = range(aboard.rects.size()).filter(func(k): return k != start_i and k != far)
	for i in range(others.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = others[i]
		others[i] = others[j]
		others[j] = t
	# peu de monstres, beaucoup de salles « ? » et de caches ; les essentiels d'abord si le donjon est petit
	var deck_types: Array = ["elite"]
	if floor_i > 1:
		deck_types.append("elite")
	for k in 2 + floor_i:
		deck_types.append("combat")
	deck_types += ["marchand", "sanctuaire", "reliquaire", "coffre"]
	var fill := ["mystere", "mystere", "reserve", "mystere", "coffre", "mystere", "reserve", "vide"]
	var fi := 0
	while deck_types.size() < others.size():
		deck_types.append(fill[fi % fill.size()])
		fi += 1
	# un second marchand dans une salle voisine du gardien : le dernier passage avant le combat
	for l in aboard.links:
		var nb: int = l[1] if l[0] == far else (l[0] if l[1] == far else -1)
		var j := others.find(nb)
		if j < 0 or j >= others.size():
			continue
		var f := range(others.size()).filter(func(x): return x != j and deck_types[x] in ["mystere", "reserve", "vide", "coffre"])
		if f.size() > 0:
			deck_types[f[0]] = deck_types[j]
			deck_types[j] = "marchand"
		break
	rooms = []
	for k in aboard.rects.size():
		var t: String = "depart"
		if k == far:
			t = "boss" if floor_i == 3 else "gardien"
		elif k != start_i:
			t = deck_types[others.find(k)]
		var ids: Array = []
		match t:
			"combat":
				var pool: Array = Data.ENCOUNTERS[floor_i]
				ids = pool[rng.randi_range(0, pool.size() - 1)]
			"elite", "gardien":
				ids = Data.elite_pick(floor_i, rng, difficulty)
			"boss":
				ids = Data.BOSS
		var mods: Array = []
		if t in ["elite", "gardien"] or (t == "combat" and rng.randf() < 0.3):
			mods.append(Data.MODIFIERS.keys()[rng.randi_range(0, Data.MODIFIERS.size() - 1)])
		var r := {"rect": aboard.rects[k], "type": t, "cell": aboard._nearest_walkable(aboard.rects[k].get_center()), "ids": ids,
			"arch": Board.ARCHETYPES[rng.randi_range(0, 3)], "mods": mods, "done": t in ["depart", "vide"], "seen": false, "node": null, "fog": null}
		if saved.has("rooms"):
			r = saved.rooms[k].duplicate()  # reprise : le donjon tel qu'on l'a laissé
			r["node"] = null
			r["fog"] = null
		rooms.append(r)
		if not r.done:
			r.node = _room_node(r)
		if not r.seen:
			r.fog = _fog(r.rect)
	leader = Unit.new()
	leader.setup(party[0], "hero")
	adv_root.add_child(leader)
	if heroes.size() > 0:
		leader.wear_voc(heroes[0].voc)
	leader.place(aboard._nearest_walkable(aboard.start), aboard)
	followers.clear()
	for k in range(1, party.size()):
		var f := Unit.new()
		f.setup(party[k], "hero")
		adv_root.add_child(f)
		if heroes.size() > k:
			f.wear_voc(heroes[k].voc)
		f.place(leader.cell, aboard)
		f.visible = false
		followers.append(f)
	trail.clear()
	if saved.has("leader"):
		leader.place(saved.leader, aboard)
		for f in followers:
			f.place(leader.cell, aboard)
		for k in rooms.size():
			if rooms[k].seen:
				_reveal(k, true)
	else:
		_reveal(start_i, true)


func _room_index(rects: Array, c: Vector2i) -> int:
	for k in rects.size():
		if (rects[k] as Rect2i).has_point(c):
			return k
	return 0


func _room_at(c: Vector2i) -> int:
	for k in rooms.size():
		if (rooms[k].rect as Rect2i).has_point(c):
			return k
	return -1


func _room_node(r: Dictionary) -> Node3D:
	## Ce qui attend dans la salle : un monstre, un coffre, un marchand...
	var t: String = r.type
	if t in ["depart", "vide"]:
		return null
	var n := Node3D.new()
	adv_root.add_child(n)
	n.position = aboard.world(r.cell)
	var glyph: Array = {"combat": ["⚔", Color(1.0, 0.6, 0.3)], "elite": ["☠", Color(1.0, 0.4, 0.3)], "gardien": ["☠", Color(1.0, 0.35, 0.25)],
		"boss": ["♜", Color(1.0, 0.3, 0.2)], "coffre": ["◆", Color(1.0, 0.85, 0.35)], "marchand": ["⚖", Color(1.0, 0.85, 0.5)],
		"sanctuaire": ["✚", Color(0.6, 1.0, 0.65)], "reliquaire": ["◆", Color(0.85, 0.6, 1.0)], "escalier": ["⇩", Color(0.55, 0.9, 1.0)],
		"mystere": ["?", Color(0.75, 0.85, 1.0)], "reserve": ["❖", Color(0.5, 1.0, 0.8)]}.get(t, ["?", Color.WHITE])
	if t in ["combat", "elite", "gardien", "boss"]:
		var u := Unit.new()
		u.setup(r.ids[0], "foe")
		n.add_child(u)
		u.face(Vector2i(0, 1))
		if t != "combat":
			u.scale = Vector3.ONE * 1.2
	else:
		var key: String = {"coffre": "prop_coffre", "marchand": "lantern", "sanctuaire": "crystal_0", "reliquaire": "crystal_1", "escalier": "portal",
			"mystere": "statue", "reserve": "prop_sac"}.get(t, "")
		if key != "":
			var md := Board.mesh_of(key)
			for part in ["mesh", "glow"]:
				if md[part] == null:
					continue
				var mi := MeshInstance3D.new()
				mi.mesh = md[part]
				mi.material_override = Board.material("glow" if part == "glow" else "prop")
				if t == "mystere":
					mi.scale = Vector3.ONE * 0.55
				n.add_child(mi)
	var l3 := Label3D.new()
	l3.text = glyph[0]
	l3.font = Fx.title_font()
	l3.font_size = 90
	l3.pixel_size = 0.006
	l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l3.no_depth_test = true
	l3.modulate = glyph[1]
	l3.outline_size = 18
	l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
	l3.position.y = 2.1
	n.add_child(l3)
	n.visible = not (t in ["combat", "elite"])
	if t in ["coffre", "marchand", "sanctuaire", "reliquaire", "escalier", "gardien", "boss", "mystere", "reserve"]:
		var beam := OmniLight3D.new()
		beam.light_color = glyph[1]
		beam.light_energy = 2.0
		beam.omni_range = 3.5
		beam.position.y = 1.2
		n.add_child(beam)
	return n


func _fog(rc: Rect2i) -> MeshInstance3D:
	## Nappe de nuée plate, bleutée, posée juste au-dessus du sol de la salle ; les tours la percent en silhouette.
	var mi := MeshInstance3D.new()
	var top0 := 0
	for x in range(rc.position.x, rc.end.x):
		for z in range(rc.position.y, rc.end.y):
			top0 = maxi(top0, aboard.h.get(Vector2i(x, z), 0))
	var pm := BoxMesh.new()  # un bloc de brume : on ne voit plus dessous en tournant la caméra
	var hh := top0 * Board.LH + 3.0
	pm.size = Vector3(rc.size.x + 1.6, hh + 2.0, rc.size.y + 1.6)
	mi.mesh = pm
	if _fog_mat == null:
		_fog_mat = StandardMaterial3D.new()
		_fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fog_mat.proximity_fade_enabled = true
		_fog_mat.proximity_fade_distance = 0.8
		var nz := FastNoiseLite.new()
		nz.frequency = 0.05
		var t := NoiseTexture2D.new()
		t.noise = nz
		t.seamless = true
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(0.2, 0.26, 0.34), Color(0.55, 0.64, 0.72)])
		t.color_ramp = g
		_fog_mat.albedo_texture = t
		_fog_mat.uv1_scale = Vector3(2, 2, 1)
	var m: StandardMaterial3D = _fog_mat.duplicate()
	m.albedo_color = Color(1, 1, 1, 0.96)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var top := 0
	for x in range(rc.position.x, rc.end.x):
		for z in range(rc.position.y, rc.end.y):
			if aboard.kind.get(Vector2i(x, z), "") != "tower":
				top = maxi(top, aboard.h.get(Vector2i(x, z), 0))
	mi.position = Vector3(rc.position.x + rc.size.x * 0.5 - 0.5, (hh + 2.0) * 0.5 - 1.5, rc.position.y + rc.size.y * 0.5 - 0.5)
	adv_root.add_child(mi)
	return mi


func _reveal(k: int, instant := false) -> void:
	## La salle où l'on entre se dévoile ; ses voisines s'entrevoient à travers une brume plus légère.
	var near: Array = [k]
	for l in aboard.links:
		if l[0] == k:
			near.append(l[1])
		elif l[1] == k:
			near.append(l[0])
	for i in near:
		var r: Dictionary = rooms[i]
		var full: bool = i == k
		if r.node:
			r.node.visible = true
		if r.fog == null:
			continue
		var m: StandardMaterial3D = r.fog.material_override
		var a := 0.0 if full else minf(m.albedo_color.a, 0.5)
		if instant:
			m.albedo_color.a = a
		else:
			r.fog.create_tween().tween_property(m, "albedo_color:a", a, 0.6)
		if full:
			r.seen = true
			var f: MeshInstance3D = r.fog
			r.fog = null
			f.create_tween().tween_interval(0.7).finished.connect(f.queue_free)


func _show_dungeon() -> void:
	var b: Dictionary = Data.BIOMES[_biome()]
	exploring = true
	board.visible = false
	units_root.visible = false
	aboard.visible = true
	adv_root.visible = true
	apply_biome(b)
	RenderingServer.global_shader_parameter_set("cut_half", 999.0)
	env.fog_depth_begin = 55.0
	env.fog_depth_end = 170.0
	for c in ambient_root.get_children():
		c.queue_free()
	Fx.ambient(ambient_root, b, leader.position)
	ui.show_hud(false)
	_explore_hud()
	target = leader.position + Vector3(0, 0.6, 0)
	dist = 18.0
	pitch = 50.0


func _explore_hud() -> void:
	ui.show_explore(true, Data.BIOMES[_biome()].name, "Étage %d · donjon · %d or · difficulté %d/5" % [floor_i, gold, difficulty + 1], "")


func adv_menu(k: String) -> void:
	## Inventaire ouvert depuis le donjon : équipement, paquet.
	if not exploring or _adv_busy or ui.overlay != null:
		return
	_adv_busy = true
	aboard.highlight({})
	match k:
		"equip":
			await _equipment()
		"deck":
			await view_deck()
	_adv_busy = false
	_explore_hud()


func _adv_process(dt: float) -> void:
	target = target.lerp(leader.position + Vector3(0, 0.6, 0), 1.0 - exp(-dt * 3.0))
	if ui.menu_open() or ui.overlay != null or _adv_busy or mobile:
		return
	var mp := get_viewport().get_mouse_position()
	var hc = aboard.pick(cam.project_ray_origin(mp), cam.project_ray_normal(mp))
	if hc != _adv_hover:
		_adv_hover = hc
		aboard.highlight({hc: Color(1, 1, 1, 0.7)} if hc != null and aboard.walkable(hc) else {})


func _adv_path(goal: Vector2i) -> Array:
	var prev := {leader.cell: leader.cell}
	var q: Array = [leader.cell]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if c == goal:
			break
		for d in Board.DIRS:
			var nb: Vector2i = c + d
			if prev.has(nb) or not aboard.walkable(nb) or absi(aboard.h[nb] - aboard.h[c]) > 2:
				continue
			prev[nb] = c
			q.append(nb)
	if not prev.has(goal) or goal == leader.cell:
		return []
	var p: Array = []
	var c := goal
	while c != leader.cell:
		p.push_front(c)
		c = prev[c]
	return p


func _adv_click(goal: Vector2i) -> void:
	if _adv_busy:
		return
	var path := _adv_path(goal)
	if path.is_empty():
		return
	_adv_busy = true
	aboard.highlight({})
	for c in path:
		trail.push_front(leader.cell)
		trail.resize(mini(trail.size(), 4))
		for k in followers.size():
			var f: Unit = followers[k]
			if trail.size() > k and is_instance_valid(f):
				f.visible = true
				f.walk([trail[k]], aboard)
		await leader.walk([c], aboard)
		var k := _room_at(c)
		if k >= 0 and not rooms[k].seen:
			_reveal(k)
		var ev := _adv_trigger(c)
		if ev >= 0:
			await _adv_event(ev)
			break
	_adv_busy = false
	_adv_hover = null
	if exploring:
		_save_run()


func _adv_trigger(c: Vector2i) -> int:
	for k in rooms.size():
		var r: Dictionary = rooms[k]
		if r.done:
			continue
		if r.type in ["combat", "elite", "gardien", "boss"]:
			if Battle.dist(c, r.cell) <= 1:
				return k
		elif c == r.cell:
			return k
	return -1


func _adv_event(k: int) -> void:
	var r: Dictionary = rooms[k]
	match r.type:
		"combat", "elite", "gardien", "boss":
			var ft: String = {"combat": "combat", "elite": "elite", "gardien": "elite", "boss": "boss"}[r.type]
			ui.banner(Data.ROOMS[ft].name if ft != "combat" else "Embuscade", " · ".join(r.mods.map(func(m): return Data.MODIFIERS[m].name)))
			await get_tree().create_timer(0.6).timeout
			next_arch = r.arch
			next_obj = "kill"
			next_mods = r.mods
			var won: bool = await _fight(ft, r.ids)
			if not won:
				floor_done.emit("lost")
				return
			await _post_fight(ft)
			if ft == "boss":
				floor_done.emit("won")
				return
			if r.node:
				r.node.queue_free()
				r.node = null
			r.done = true
			if r.type == "gardien":
				r.type = "escalier"
				r.done = false
				r.node = _room_node(r)
				r.node.visible = true
				ui.toast("L'escalier vers l'étage suivant est libre.")
			_show_dungeon()
		"coffre":
			r.done = true
			if r.node:
				r.node.queue_free()
			await open_chest(heroes[0])
			await _flush_cards()
			_explore_hud()
		"marchand":
			r.done = true  # un seul passage : l'étal ne se regarnit pas
			if r.node:
				r.node.queue_free()
				r.node = null
			await _merchant()
			_explore_hud()
		"sanctuaire":
			r.done = true
			await _sanctuary()
			_explore_hud()
		"reliquaire":
			r.done = true
			if r.node:
				r.node.queue_free()
			await _relic_pick("Reliquaire", "Une relique parmi trois")
			_explore_hud()
		"escalier":
			floor_done.emit("next")
		"mystere":
			await _mystery(r)
		"reserve":
			r.done = true
			if r.node:
				r.node.queue_free()
				r.node = null
			for n in rng.randi_range(1, 2):
				await _gain_obj_ui(_obj_roll(2), 1)
			_explore_hud()


func _advtest() -> void:
	## Mode aventure sans les mains : captures du donjon, marche vers un monstre, combat joué, retour.
	var dir: String = args.advtest
	DirAccess.make_dir_recursive_absolute(dir)
	run_seed = int(args.get("seed", "3"))
	rng.seed = run_seed
	mode = "aventure"
	floor_i = 1
	var bi := int(args.get("biome", "0"))
	floor_biomes = [bi, bi, bi]
	deck = Data.starter(party)
	_make_party()
	_gen_dungeon()
	_show_dungeon()
	_snap_cam()
	await _frames(90)
	_shot(dir, "01_depart")
	var keep := [target, dist, pitch]
	target = Vector3(aboard.dim * 0.5, 0, aboard.dim * 0.5)
	dist = aboard.dim * 1.5
	pitch = 62.0
	_snap_cam()
	await _frames(40)
	_shot(dir, "02_donjon")
	target = keep[0]
	dist = keep[1]
	pitch = keep[2]
	_snap_cam()
	# le monstre le plus proche
	var goal = null
	var best := 1 << 30
	for r in rooms:
		if r.type == "combat" and not r.done:
			for d in Board.DIRS:
				var c: Vector2i = r.cell + d
				if aboard.walkable(c):
					var pl := _adv_path(c).size()
					if pl > 0 and pl < best:
						best = pl
						goal = c
	print("monstre à ", best, " cases")
	_test_driver()
	Engine.time_scale = 3.0
	await _adv_click(goal)
	Engine.time_scale = 1.0
	await _frames(60)
	_shot(dir, "03_retour")
	print("retour au donjon : ", exploring, " · combats ", fights)
	# chemins d'événements : Ancien, bienfaits, salles « ? », paquet
	gain_obj("o_fiole", party[0])
	Engine.time_scale = 3.0
	var shot_an := func(): await _frames(30); _shot(dir, "04_ancien")
	shot_an.call()
	await _ancient()
	for bk in Data.BOONS:
		await _boon(bk)
	for n in 10:
		await _mystery({"done": false, "node": null, "arch": "cour"})
	await view_deck()
	Engine.time_scale = 1.0
	print("événements OK · paquet %d · or %d" % [deck.size(), gold])
	get_tree().quit()


func _test_driver() -> void:
	## Joue à la place du joueur pendant les tests : combats et écrans de choix.
	while is_inside_tree():
		await get_tree().process_frame
		if ui.overlay != null:
			await _frames(15)
			if ui.overlay != null:
				ui.picked.emit(maxi(0, ui.last_n - 1))  # la dernière option : « Après » pour les aperçus
			continue
		if ui.hud.visible and battle.player_turn and not battle.busy and not battle.over:
			if battle.turn > 25:
				# le bot peut tourner en rond : on abrège le combat plutôt que de boucler
				print("bot : combat abrégé au tour %d" % battle.turn)
				for f in battle.alive_foes():
					battle.kill(f)
				continue
			await _auto_turn()
			if not battle.over:
				await battle.end_turn()


# ------------------------------------------------------------------ cartes-objets, paquet, Anciens, salles « ? »

func _obj_roll(max_rar := 2) -> String:
	## Une carte-objet au hasard : commune 70 %, peu commune 25 %, rare 5 % (plafonnée par max_rar).
	var roll := rng.randf()
	var rar := mini(3 if roll < 0.05 else (2 if roll < 0.3 else 1), max_rar)
	var ids: Array = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].has("tool") and Data.CARDS[id].rar == rar)
	return ids[rng.randi_range(0, ids.size() - 1)]


func _obj_price(id: String) -> int:
	return {1: 25, 2: 40, 3: 60}[Data.def(id).rar]


func gain_obj(id: String, hkey: String, lvl := 1) -> Dictionary:
	## Une carte-objet rejoint le paquet d'un héros. Doublon absorbé : +1 charge (3 au plus) ; niv 3 -> or.
	if relics.has("sacoche"):
		lvl = maxi(lvl, 2)
	for ci in deck:
		if ci.id == id and ci.get("h", "") == hkey:
			if Data.level(ci) >= 3:
				gold += 60
				ui.set_gold(gold)
				ui.toast("%s : déjà légendaire, revendu +60 or." % Data.def(id).name)
				return {}
			# un doublon ne fait plus monter de niveau (le niveau 3 se mérite à la forge) : +1 charge, 3 au plus
			ci["uses"] = mini(3, int(ci.get("uses", 1)) + 1)
			ui.toast("%s : doublon absorbé, %d charges." % [Data.def(id).name, ci.uses])
			return ci
	var ci := {"id": id, "lvl": lvl, "h": hkey, "uses": mini(lvl, 2)}
	fight_loot.append(Data.def(id).name)
	if lvl >= 3:
		ci.erase("uses")
		library_see(id + "#3")
	deck.append(ci)
	library_see(id)
	return ci


func _gain_obj_ui(id: String, lvl := 1, title := "OBJET", sub := "") -> void:
	## Une carte-objet trouvée : à quel héros la donner, ou la revendre tout de suite.
	var opts: Array = []
	for h in heroes:
		var has := deck.filter(func(ci): return ci.id == id and ci.get("h", "") == h.key)
		var note := "Paquet : %d cartes" % deck.filter(func(ci): return Data.holder(ci) == h.key).size()
		if has.size() > 0:
			note = "L'a déjà : doublon → +1 charge" if Data.level(has[0]) < 3 else "L'a déjà en légendaire : +60 or"
		opts.append({"title": h.nm, "image": "res://assets/art/portrait_%s.png" % h.key, "color": Data.CLASS_COLOR[h.key], "text": note, "w": 220, "h": 210})
	var val := Data.sell_value({"id": id, "lvl": lvl})
	var i := await ui.choose(title, (sub + " · " if sub != "" else "") + "Tu as trouvé %s !" % Data.def(id).name, opts, true, "Revendre : +%d or" % val, "", {"id": id, "lvl": lvl, "h": heroes[0].key, "uses": mini(lvl, 2)})
	if i >= 0:
		gain_obj(id, heroes[i].key, lvl)
	else:
		gold += val
		ui.set_gold(gold)


func view_deck(which := "deck") -> void:
	## P : tout le paquet ; en combat, clic sur le compteur : la pioche (ordre caché).
	if ui.overlay != null or ui.menu_open():
		return
	var cards: Array = deck.duplicate()
	var title := "PAQUET"
	var sub := "%d cartes · survol : détails" % cards.size()
	if which == "pioche" and ui.hud.visible:
		cards = battle.draw_pile.duplicate()
		title = "PIOCHE"
		sub = "%d cartes, ordre caché · défausse %d · épuisées %d" % [cards.size(), battle.discard.size(), battle.exhausted.size()]
	if which == "defausse" and ui.hud.visible:
		# la plus récente d'abord, dans l'ordre où elles ont été jouées ; les épuisées à la suite
		var opts: Array = []
		var d: Array = battle.discard.duplicate()
		d.reverse()
		for c in d:
			opts.append({"card": c, "tag": "Joué ce tour" if battle.played_turn.any(func(p): return p.id == c.id) else "Défausse"})
		for c in battle.exhausted:
			opts.append({"card": c, "tag": "Épuisée"})
		await ui.choose("DÉFAUSSE", "%d en défausse · %d épuisée(s) · elles reviennent quand la pioche est vide" % [battle.discard.size(), battle.exhausted.size()], opts, true, "Fermer")
		return
	var key := func(c: Dictionary) -> String: return "%s|%s|%d" % [Data.holder(c), c.id, 9 - Data.level(c)]
	cards.sort_custom(func(a, b): return key.call(a) < key.call(b))
	await ui.choose(title, sub, cards.map(func(c): return {"card": c}), true, "Fermer")


func _ancient() -> void:
	## Au seuil de chaque étage, un Ancien (esprit Slay the Spire 2) offre un bienfait parmi trois.
	var keys: Array = Data.ANCIENTS.keys()
	var an: Dictionary = Data.ANCIENTS[keys[posmod(run_seed + floor_i, keys.size())]]
	var pool: Array = an.boons.duplicate()
	if floor_i == 1:
		pool.erase("soin")  # au départ, l'escouade est pleine : un soin serait un choix mort
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var picks: Array = pool.slice(0, 3)
	if voc_start and floor_i == 1 and not tuto and not picks.has("vocation"):
		picks[0] = "vocation"  # réglage « Vocation dès le départ »
	if floor_i >= 2 and not tuto and rng.randf() < 1.0 / 3.0 and _relic_draw("boss") != "":
		picks[2] = "relique_boss"  # étages 2 et 3 : parfois une relique de gardien de plus, à la place d'un bienfait
	var opts: Array = picks.map(func(b): return {"title": Data.BOONS[b].name, "glyph": Data.BOONS[b].glyph, "art": "res://assets/ui/boon_%s.png" % b, "text": Data.BOONS[b].text, "color": an.col})
	ui.team_on = true
	ui.speaker = keys[posmod(run_seed + floor_i, keys.size())]
	while true:
		var i := await ui.choose("%s  %s" % [an.glyph, an.name.to_upper()], "%s · « %s »" % [an.title, an.line], opts, false, "", "res://assets/art/ancien_%s.png" % keys[posmod(run_seed + floor_i, keys.size())])
		if await _boon(picks[i], true):
			break
	ui.team_on = false
	ui.speaker = ""
	ui.refresh_relics(relics)
	ui.set_gold(gold)


func _boon(k: String, back := false) -> bool:
	## back : le sous-écran propose « ← Retour » et rend false si on revient au choix du bienfait.
	match k:
		"relique":
			var r := _relic_draw("ancien")
			if r != "":
				await _add_relic(r)
		"relique_boss":
			if not await _relic_pick("RELIQUE DE GARDIEN", "Un pouvoir, et son prix", back, "boss"):
				return false
		"relique_sang":
			if not await _relic_pick("RELIQUE DE SANG", "Chaque héros perd 5 PV max", back):
				return false
			for h in heroes:
				h.base_hp = maxi(10, h.base_hp - 5)
				h.apply_gear()
		"rare":
			var opts: Array = []
			var guard := 0
			while opts.size() < 3 and guard < 60:
				guard += 1
				var id := _card_roll(3)
				if not opts.any(func(o): return o.card.id == id):
					opts.append({"card": {"id": id, "lvl": 1}})
			var j := await ui.choose("SAVOIR INTERDIT", "Une carte rare pour le paquet", opts, true, "← Retour" if back else "Passer")
			if j < 0 and back:
				return false
			if j >= 0:
				deck.append(opts[j].card)
		"epure":
			for n in 2:
				var j := await ui.choose("OUBLI", "Retirer une carte (%d / 2)" % (n + 1), deck.map(func(c): return {"card": c}), true, "← Retour" if back and n == 0 else "Garder le reste")
				if j < 0 and back and n == 0:
					return false
				if j < 0:
					break
				deck.remove_at(j)
		"or":
			gold += 100
		"pvmax":
			for h in heroes:
				h.base_hp += 6
				h.apply_gear()
		"soin":
			for h in heroes:
				h.hp = h.max_hp
		"forge2":
			var idx: Array = range(deck.size()).filter(func(q): return Data.level(deck[q]) < Data.lvl_cap(deck[q]))
			var names: Array = []
			for n in mini(2, idx.size()):
				var q: int = idx.pop_at(rng.randi_range(0, idx.size() - 1))
				_level_up(q)
				names.append(Data.def(deck[q].id).name)
			ui.toast("Plus fortes : " + ", ".join(names))
		"racines":
			var hopts: Array = heroes.map(func(h): return {"title": h.nm, "image": "res://assets/art/portrait_%s.png" % h.key, "text": "Ses cartes de départ gagnent un niveau.", "color": Data.CLASS_COLOR[h.key]})
			var j := await ui.choose("RACINES", "Quel héros ?", hopts, back, "← Retour")
			if j < 0:
				return false
			for q in deck.size():
				if deck[q].get("st", false) and Data.holder(deck[q]) == heroes[j].key and Data.level(deck[q]) < Data.lvl_cap(deck[q]):
					_level_up(q)
		"besace":
			for n in 3:
				await _gain_obj_ui(_obj_roll(2), 1, "TROIS BABIOLES")
		"place":
			var idx: Array = range(deck.size()).filter(func(q): return Data.def(deck[q].id).has("tool") and Data.level(deck[q]) < Data.lvl_cap(deck[q]))
			if idx.size() > 0:
				var j := await ui.choose("POCHES COUSUES", "Quelle carte-objet gagne un niveau ?", idx.map(func(q): return {"card": deck[q]}), true)
				if j >= 0:
					_level_up(idx[j])
			var rare: Array = Data.CARDS.keys().filter(func(x): return Data.CARDS[x].has("tool") and Data.CARDS[x].rar == 3)
			await _gain_obj_ui(rare[rng.randi_range(0, rare.size() - 1)], 1, "POCHES COUSUES")
		"arme":
			_gain_item(_roll_item(3))
		"reflet":
			var src: Array = deck.filter(func(c): return Data.def(c.id).get("rar", 1) < 4 and not Data.def(c.id).has("tool"))  # une légendaire reste unique
			var j := await ui.choose("REFLET", "Quelle carte copier ? (pas les légendaires)", src.map(func(c): return {"card": c}), true)
			if j >= 0:
				var cp := {"id": src[j].id, "lvl": Data.level(src[j])}
				if src[j].has("h"):
					cp["h"] = src[j].h
				deck.append(cp)
		"vocation":
			var h := await _pick_hero("VOCATION", "Qui prend ou change sa vocation ?")
			if h:
				h.pj = maxi(h.pj, Data.MASTERY[2])
				await _choose_vocation(h)
		"memoire":
			for h in heroes:
				await _gain_pj(h, 3)
	return true


# ------------------------------------------------------------------ événements (salles « ? »)
# Inspirés de Slay the Spire (un choix, un prix) et de Hades (des figures qui reviennent, qui parlent).

var seen_events: Array = []   # événements déjà vus pendant la run : on ne les revoit pas
var companion := ""           # bête apprivoisée qui suit l'escouade (Data.COMPANIONS)
const EVENTS_NEW := ["passeur", "duel", "miroir", "des", "bibliothecaire", "maitre", "bete", "epave", "glyphes", "rave", "grixis", "mimique", "graveur", "sangsue"]


func _event_fight(r: Dictionary, type: String, mods: Array, ids: Array = []) -> bool:
	## Un combat surgi d'un événement ; faux si l'escouade tombe (la run s'arrête).
	if haven_root:
		haven_root.queue_free()
		haven_root = null
	orbit = false
	ui.dim_alpha = 0.62
	await get_tree().create_timer(0.6).timeout
	next_arch = r.get("arch", "cour")
	next_obj = "kill"
	next_mods = mods
	var won: bool = await _fight(type, ids)
	if not won:
		if mode == "aventure":
			floor_done.emit("lost")
		else:
			_clear_save()
			await ui.game_over(false, "Étage %d, tombés sur un événement, %d min." % [floor_i, _minutes()])
			new_run.call_deferred()
		return false
	await _post_fight(type)
	if mode == "aventure":
		_show_dungeon()
	return true


func _event_figure(key: String) -> void:
	## La figure de l'événement, posée devant l'escouade (la bête blessée, le bretteur masqué).
	if haven_root == null or heroes.is_empty():
		return
	var c: Vector2i = heroes[0].cell
	for d in [Vector2i(0, 2), Vector2i(2, 0), Vector2i(0, -2), Vector2i(-2, 0), Vector2i(1, 1)]:
		if board.walkable(c + d) and not heroes.any(func(h): return h.cell == c + d):
			c = c + d
			break
	_haven_npc(key, board.world(c), PI)
	target = (board.world(c) + heroes[0].position) * 0.5 + Vector3(0, 0.6, 0)


func _deck_pick(title: String, sub: String, filter := Callable()) -> int:
	## Une carte du paquet au choix ; renvoie son indice dans le paquet, -1 si on renonce.
	var idx: Array = range(deck.size()).filter(func(q): return not filter.is_valid() or filter.call(deck[q]))
	if idx.is_empty():
		ui.toast("Aucune carte ne convient.")
		return -1
	var j := await ui.choose(title, sub, idx.map(func(q): return {"card": deck[q]}), true)
	return idx[j] if j >= 0 else -1


func _event_new(ev: String, r: Dictionary) -> bool:
	## Renvoie faux si la run s'arrête pendant l'événement.
	var green := Color("#8fd0a0")
	var red := Color("#e0583a")
	var blue := Color("#6fb0e0")
	match ev:
		"graveur":
			# enchantement : le graveur choisit le mot-clé, vous choisissez la carte (ou l'inverse, pour de l'or)
			var i := await ui.choose("LE GRAVEUR DE RUNES", "Un vieil homme grave des runes sur des pierres de gué. « Ta carte a une voix. Je peux lui en donner une deuxième. » Vous avez %d or." % gold, [
				{"title": "Graver au hasard", "glyph": "✦", "text": "Une carte au choix reçoit un enchantement tiré au sort, cohérent avec elle.", "color": blue},
				{"title": "Choisir la rune  ·  75 or", "glyph": "✎", "text": "Trois enchantements proposés pour la carte choisie.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0 or (i == 1 and gold >= 75):
				var q := await _deck_pick("LE GRAVEUR DE RUNES", "Quelle carte graver ?", func(ci): return Data.ench_roll(ci, rng) != "")
				if q >= 0:
					var en := Data.ench_roll(deck[q], rng)
					if i == 1:
						gold -= 75
						ui.set_gold(gold)
						var ok: Array = Data.ENCHANTS.keys().filter(func(e): return Data.ench_ok(deck[q], e))
						ok.shuffle()
						ok = ok.slice(0, 3)
						var j := await ui.choose("LE GRAVEUR DE RUNES", "Quelle rune ?", ok.map(func(e):
							var cp: Dictionary = deck[q].duplicate()
							cp["ench"] = e
							return {"card": cp}))
						en = ok[maxi(j, 0)]
					deck[q]["ench"] = en
					ui.toast("%s ✦ %s" % [Data.def(deck[q].id).name, Data.ENCHANTS[en].name])
			elif i == 1:
				ui.toast("« La pierre se paie. »")
		"sangsue":
			var i := await ui.choose("LA SANGSUE D'OR", "Dans une vasque, une sangsue dorée, grosse comme un poing, attend qu'on lui tende une arme.", [
				{"title": "Lui tendre une attaque", "glyph": "♥", "text": "Une attaque gagne Vol de vie (soigne la moitié des dégâts infligés). Son porteur perd 6 PV max.", "color": red},
			], true, "Garder son sang")
			if i == 0:
				var q := await _deck_pick("LA SANGSUE D'OR", "Quelle attaque ?", func(ci): return Data.ench_ok(ci, "vampire"))
				if q >= 0:
					deck[q]["ench"] = "vampire"
					for h in heroes:
						if h.key == Data.holder(deck[q]):
							h.base_hp = maxi(10, h.base_hp - 6)
							h.apply_gear()
		"passeur":
			var rel := _relic_draw("event")
			if rel == "":
				return true
			var i := await ui.choose("LE PASSEUR", "Une barque sans rame, une lanterne, une main tendue. « L'obole d'abord. » Vous avez %d or." % gold, [
				{"title": "%s  ·  90 or" % Data.RELICS[rel].name, "image": "res://assets/ui/relic_%s.png" % rel, "text": Data.RELICS[rel].text},
				{"title": "Lui confier un souvenir", "glyph": "✂", "text": "Retirer une carte du paquet. Il ne rend jamais la monnaie.", "color": blue},
			], true, "Rester sur la rive")
			if i == 0:
				if gold < 90:
					ui.toast("« Reviens plus riche. »")
				else:
					gold -= 90
					await _add_relic(rel)
			elif i == 1:
				var q := await _deck_pick("LE PASSEUR", "Quelle carte laisser au fond de la barque ?")
				if q >= 0:
					deck.remove_at(q)
		"duel":
			var big: Unit = heroes.reduce(func(a, b): return a if a.hp >= b.hp else b)
			_event_figure("bretteur")
			var i := await ui.choose("DUEL D'HONNEUR", "Un bretteur masqué plante sa lame dans la dalle : « Ton meilleur contre ma garde. » Les siens attendent, enragés.", [
				{"title": "Relever le défi", "glyph": "⚔", "text": "Combat d'élite, ennemis Enragés (+2 dégâts). Victoire : une relique au choix et une carte rare.", "color": red},
				{"title": "Saluer et passer", "glyph": "✓", "text": "%s gagne 2 points de job : on apprend aussi en regardant." % big.nm, "color": green},
			])
			if i == 0:
				if not await _event_fight(r, "elite", ["enrages"]):
					return false
				await _relic_pick("TROPHÉE DU DUEL", "La garde du bretteur, en souvenir", false, "event")
				await _boon("rare")
			else:
				await _gain_pj(big, 2)
		"miroir":
			var i := await ui.choose("MIROIR NOYÉ", "Sous l'eau, un grand miroir renvoie l'escouade avec un temps de retard.", [
				{"title": "Y plonger la main", "glyph": "⧉", "text": "Copier une carte du paquet (la copie n'est pas une carte de départ). Chaque héros perd 4 PV.", "color": blue},
			], true, "Ne pas se regarder")
			if i == 0:
				var q := await _deck_pick("MIROIR NOYÉ", "Quelle carte copier ?")
				if q >= 0:
					var cp: Dictionary = deck[q].duplicate()
					cp.erase("st")
					deck.append(cp)
					for h in heroes:
						h.hp = maxi(1, h.hp - 4)
		"des":
			var i := await ui.choose("TOUT OU RIEN", "Un joueur aux doigts bandés secoue deux dés d'os. « Zawa... zawa... » Vous avez %d or." % gold, [
				{"title": "Miser 50 or", "glyph": "⚄", "text": "Une chance sur deux de repartir avec 125 or.", "color": UI.GOLD},
				{"title": "Miser une carte", "glyph": "⚒", "text": "Une carte au choix : une chance sur deux qu'elle gagne deux niveaux, sinon elle est perdue.", "color": red},
			], true, "Garder ses billes")
			if i == 0:
				if gold < 50:
					ui.toast("« Pas de mise, pas de frisson. »")
				else:
					gold -= 50
					if rng.randf() < 0.5:
						gold += 125
						ui.banner("Gagné", "+125 or")
					else:
						ui.banner("Perdu", "Les dés roulent dans l'eau")
			elif i == 1:
				var q := await _deck_pick("TOUT OU RIEN", "Quelle carte jouer aux dés ?", func(ci): return Data.level(ci) < Data.lvl_cap(ci))
				if q >= 0:
					if rng.randf() < 0.5:
						deck[q]["lvl"] = mini(Data.lvl_cap(deck[q]), Data.level(deck[q]) + 2)
						ui.banner("Double six", "%s passe au niveau %d" % [Data.def(deck[q].id).name, deck[q].lvl])
					else:
						ui.banner("Perdu", "%s file avec le courant" % Data.def(deck[q].id).name)
						deck.remove_at(q)
		"bibliothecaire":
			var i := await ui.choose("LA BIBLIOTHÉCAIRE AVEUGLE", "« Donne-moi une page, je t'en rendrai une meilleure. Je ne dis pas laquelle. »", [
				{"title": "Échanger une page", "glyph": "✎", "text": "Une carte du paquet devient une carte du même héros, d'une rareté au-dessus (au hasard).", "color": blue},
			], true, "Garder ses pages")
			if i == 0:
				var q := await _deck_pick("ÉCHANGE", "Quelle carte transmuter ?")
				if q >= 0:
					var who := Data.holder(deck[q])
					var rar := mini(3, int(Data.def(deck[q].id).get("rar", 1)) + 1)
					var pool: Array = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].owner == who and int(Data.CARDS[id].get("rar", 1)) == rar)
					if pool.is_empty():
						pool = Data.CARDS.keys().filter(func(id): return Data.CARDS[id].owner == who)
					var nid: String = pool[rng.randi_range(0, pool.size() - 1)]
					var old: String = Data.def(deck[q].id).name
					deck[q] = {"id": nid, "lvl": 1} if Data.CARDS[nid].owner == who else {"id": nid, "lvl": 1, "h": who}
					library_see(nid)
					ui.banner("%s → %s" % [old, Data.def(nid).name], Data.card_text(Data.card(deck[q])))
		"maitre":
			var i := await ui.choose("MAÎTRE D'ARMES ERRANT", "Un vieux soldat de la Compagnie, sec comme un sarment, propose une leçon.", [
				{"title": "Suivre la leçon", "glyph": "⚔", "text": "Un héros au choix gagne 4 points de job (vers sa vocation et ses guildes).", "color": green},
				{"title": "Lui demander son arme", "glyph": "⚒", "text": "Un équipement rare. Il se vexe : chaque héros perd 3 PV max.", "color": red},
			], true, "Passer son chemin")
			if i == 0:
				var h := await _pick_hero("LA LEÇON", "Qui apprend ?")
				if h:
					await _gain_pj(h, 4)
			elif i == 1:
				_gain_item(_roll_item(3))
				for h in heroes:
					h.base_hp = maxi(10, h.base_hp - 3)
					h.apply_gear()
		"bete":
			var sp: Array = Data.COMPANIONS.keys()
			var k: String = sp[rng.randi_range(0, sp.size() - 1)]
			var cd: Dictionary = Data.COMPANIONS[k]
			var fi: Array = deck.filter(func(ci): return ci.id == "o_fiole" and Data.level(ci) < 3)
			var has_fiole := fi.size() > 0
			_event_figure(k)
			var i := await ui.choose("BÊTE BLESSÉE", "%s gît, une patte prise dans un filet de la Compagnie. Elle ne grogne plus : elle attend." % Data.FOES[k].name, [
				{"title": "La soigner  ·  %s" % ("une Fiole de sève" if has_fiole else "30 or"), "image": "res://assets/ui/comp_%s.png" % k, "text": "Elle vous suit : %s %s" % [cd.name + ".", cd.text], "color": green},
			], true, "La laisser")
			if i == 0:
				if has_fiole:
					fi[0]["uses"] = int(fi[0].get("uses", Data.level(fi[0]))) - 1
					if int(fi[0].uses) <= 0:
						deck.erase(fi[0])
				elif gold >= 30:
					gold -= 30
				else:
					ui.toast("Ni fiole ni or : elle se traîne dans l'eau.")
					return true
				companion = k
				ui.banner("Nouveau compagnon", cd.name)
		"epave":
			var i := await ui.choose("ÉPAVE DE LA COMPAGNIE", "Une barge à demi coulée, des coffres encore scellés. Des casques affleurent sous l'eau.", [
				{"title": "Piller", "glyph": "❖", "text": "Un équipement et 40 or. Le prochain combat reçoit des Renforts.", "color": UI.GOLD},
			], true, "Ne pas réveiller les noyés")
			if i == 0:
				_gain_item(_roll_item(2))
				gold += 40
				pending_mods.append("renforts")
		"glyphes":
			var i := await ui.choose("CERCLE DE GLYPHES", "Deux glyphes jumeaux pulsent au sol. Ce que l'un prend, l'autre le rend.", [
				{"title": "Sacrifier une carte", "glyph": "✺", "text": "Retirer une carte : une autre, au choix, gagne deux niveaux.", "color": blue},
			], true, "Contourner")
			if i == 0:
				var q := await _deck_pick("SACRIFICE", "Quelle carte offrir au premier glyphe ?")
				if q >= 0:
					deck.remove_at(q)
					var u := await _deck_pick("OFFRANDE", "Quelle carte reçoit deux niveaux ?", func(ci): return Data.level(ci) < Data.lvl_cap(ci))
					if u >= 0:
						deck[u]["lvl"] = mini(Data.lvl_cap(deck[u]), Data.level(deck[u]) + 2)
		"rave":
			var i := await ui.choose("RAVE ENGLOUTIE", "Sous une voûte, une enceinte de pierre bat à 174 BPM. Des lucioles tiennent le rythme.", [
				{"title": "Danser jusqu'à l'aube", "glyph": "♫", "text": "Chaque héros récupère 25 % de ses PV max.", "color": green},
				{"title": "Chercher le DJ", "glyph": "●", "text": "Il vous file 35 or et un Carnet de croquis pour la route.", "color": UI.GOLD},
			], true, "Garder le tempo")
			if i == 0:
				for h in heroes:
					h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.25))
			elif i == 1:
				gold += 35
				await _gain_obj_ui("o_carnet", 1)
		"grixis":
			var i := await ui.choose("AUTEL DE GRIXIS", "Trois vasques : l'une d'encre bleue, l'une de braise, l'une de nuit.", [
				{"title": "Bleu : l'Analyse", "glyph": "◆", "text": "Deux cartes au hasard gagnent un niveau.", "color": Color("#4aa3d8")},
				{"title": "Rouge : l'Émotion", "glyph": "✹", "text": "Une carte rare au choix, mais chaque héros perd 5 PV.", "color": Color("#e0483f")},
				{"title": "Noir : l'Ambition", "glyph": "♦", "text": "Une relique au choix parmi trois ; le héros aux plus hauts PV max en perd 8.", "color": Color("#9b6dd6")},
			], true, "Ne rien boire")
			if i == 0:
				await _boon("forge2")
			elif i == 1:
				for h in heroes:
					h.hp = maxi(1, h.hp - 5)
				await _boon("rare")
			elif i == 2:
				var big: Unit = heroes.reduce(func(a, b): return a if a.max_hp >= b.max_hp else b)
				big.base_hp = maxi(10, big.base_hp - 8)
				big.apply_gear()
				await _relic_pick("AMBITION", "Ce qu'on prend, on le garde", false, "event")
		"mimique":
			var i := await ui.choose("UN COFFRE, SEUL", "Un coffre cerclé d'or au milieu de la salle. Trop beau. Beaucoup trop beau.", [
				{"title": "L'ouvrir", "glyph": "◆", "text": "Une chance sur deux : une relique et 50 or. Sinon, il a des dents (combat d'élite).", "color": UI.GOLD},
				{"title": "Le frapper d'abord", "glyph": "⚔", "text": "Une chance sur deux : 30 or, le couvercle cabossé. Sinon il se réveille avant de mordre : simple combat, et sa relique.", "color": red},
			], true, "Ne pas y toucher")
			if i == 0:
				if rng.randf() < 0.5:
					gold += 50
					await _event_relic()
				else:
					ui.banner("Mimique !", "Le coffre ouvre un œil")
					if not await _event_fight(r, "elite", ["enrages"]):
						return false
					await _event_relic()
			elif i == 1:
				if rng.randf() < 0.5:
					gold += 30
				else:
					ui.banner("Mimique !", "Il hurle avant d'avoir mordu")
					if not await _event_fight(r, "combat", []):
						return false
					await _event_relic()
	return true


func _mystery(r: Dictionary) -> void:
	## Salle « ? » : un événement tiré au sort, parfois une embuscade.
	r.done = true
	if r.get("node"):
		r.node.queue_free()
		r.node = null
	if mode != "aventure":
		await _haven("mystere")
	if relics.has("journal_route"):
		for h in heroes:
			h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.1))
		await _journal_reroll()
	# embuscade : 10 %, +10 % à chaque « ? » paisible (au plus 50 %), retour à 10 % après une embuscade
	if not tuto and rng.randf() < myst_fight and not relics.has("lampe_brume"):
		myst_fight = 0.1
		ui.banner("Embuscade !", "La salle n'était pas vide")
		if await _event_fight(r, "combat", []) and mode != "aventure":
			_haven_end()
		return
	myst_fight = minf(myst_fight + 0.1, 0.5)
	var evs: Array = ["fontaine", "cadavre", "enclume", "puits", "cage", "autel", "atelier", "bibliotheque"] + EVENTS_NEW
	evs = evs.filter(func(e): return not seen_events.has(e) and (e != "bete" or (companion == "" and rng.randf() < 0.4)))
	if evs.is_empty():
		seen_events.clear()
		evs = ["fontaine", "enclume", "puits", "atelier"]
	var ev: String = evs[rng.randi_range(0, evs.size() - 1)]
	seen_events.append(ev)
	if EVENTS_NEW.has(ev):
		ui.speaker = "neutre"
		var alive := await _event_new(ev, r)
		ui.speaker = ""
		ui.set_gold(gold)
		if alive and mode != "aventure":
			_haven_end()
		elif alive:
			_explore_hud()
		return
	var green := Color("#8fd0a0")
	match ev:
		"fontaine":
			var i := await ui.choose("FONTAINE TROUBLE", "Une eau verte suinte d'un mascaron.", [
				{"title": "Boire", "glyph": "✚", "text": "Chaque héros récupère 30 % de ses PV max.", "color": green},
				{"title": "Remplir une fiole", "glyph": "♥", "text": "Une carte Fiole de sève (un doublon ajoute une charge).", "color": green},
			], true, "Passer son chemin")
			if i == 0:
				for h in heroes:
					h.hp = mini(h.max_hp, h.hp + int(h.max_hp * 0.3))
			elif i == 1:
				await _gain_obj_ui("o_fiole", 1)
		"cadavre":
			var i := await ui.choose("AVENTURIER TOMBÉ", "Son sac est encore plein. Quelque chose rôde peut-être.", [
				{"title": "Fouiller", "glyph": "❖", "text": "Deux cartes-objets et 30 or. Une chance sur trois d'être surpris.", "color": UI.GOLD},
			], true, "Le laisser en paix")
			if i == 0:
				await _gain_obj_ui(_obj_roll(2), 1)
				await _gain_obj_ui(_obj_roll(2), 1)
				gold += 30
				if rng.randf() < 0.33:
					ui.banner("Embuscade", "Le sac était un appât")
					await get_tree().create_timer(0.6).timeout
					next_arch = r.arch
					next_obj = "kill"
					next_mods = []
					if not await _event_fight(r, "combat", []):
						return
		"enclume":
			var i := await ui.choose("ENCLUME ABANDONNÉE", "Le feu couve encore sous les cendres.", [
				{"title": "Forger", "glyph": "⚒", "text": "Une carte du paquet gagne un niveau.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				await _forge("FORGE", "Quelle carte forger ? (+1 niveau)")
		"puits":
			var i := await ui.choose("PUITS AUX SOUHAITS", "Des pièces brillent au fond. Vous avez %d or." % gold, [
				{"title": "Jeter 30 or", "glyph": "●", "text": "Une chance sur deux qu'une relique remonte.", "color": UI.GOLD},
			], true, "Garder son or")
			if i == 0:
				if gold < 30:
					ui.toast("Pas assez d'or.")
				else:
					gold -= 30
					if rng.randf() < 0.5:
						await _event_relic()
					else:
						ui.toast("Rien ne remonte.")
		"cage":
			var i := await ui.choose("CAGE ROUILLÉE", "Un contrebandier y croupit, sa marchandise à ses pieds.", [
				{"title": "Le libérer", "glyph": "⌂","text": "Il vous laisse un équipement pour la peine.", "color": green},
				{"title": "Le rançonner", "glyph": "●", "text": "+60 or, mais il crie : chaque héros perd 4 PV.", "color": Color("#e0583a")},
			], true, "Passer son chemin")
			if i == 0:
				_gain_item(_roll_item(2))
			elif i == 1:
				gold += 60
				for h in heroes:
					h.hp = maxi(1, h.hp - 4)
		"autel":
			var big: Unit = heroes.reduce(func(a, b): return a if a.max_hp >= b.max_hp else b)
			var i := await ui.choose("AUTEL DE SANG", "La pierre a soif.", [
				{"title": "Offrir du sang", "glyph": "♦", "text": "%s perd 6 PV max ; une carte rare au choix." % big.nm, "color": Color("#e0583a")},
			], true, "Passer son chemin")
			if i == 0:
				big.base_hp -= 6
				big.apply_gear()
				await _boon("rare")
		"atelier":
			var i := await ui.choose("ATELIER EN RUINE", "Établis renversés, outils rouillés, poudre humide.", [
				{"title": "Récupérer", "glyph": "❖", "text": "Deux cartes-objets.", "color": Color("#7fe0c8")},
				{"title": "Démonter", "glyph": "●", "text": "+45 or.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				await _gain_obj_ui(_obj_roll(2), 1)
				await _gain_obj_ui(_obj_roll(3), 1)
			elif i == 1:
				gold += 45
		"bibliotheque":
			var i := await ui.choose("BIBLIOTHÈQUE NOYÉE", "Des pages gonflées d'eau, quelques-unes lisibles.", [
				{"title": "Lire", "glyph": "✎", "text": "Une carte au choix parmi trois, niveau 2.", "color": Color("#6fb0e0")},
				{"title": "Brûler une page", "glyph": "✂", "text": "Retirer une carte du paquet.", "color": UI.GOLD},
			], true, "Passer son chemin")
			if i == 0:
				var opts: Array = []
				while opts.size() < 3:
					var id := _card_roll(1)
					if not opts.any(func(o): return o.card.id == id):
						opts.append({"card": {"id": id, "lvl": 2}})
				var j := await ui.choose("BIBLIOTHÈQUE", "Une carte pour le paquet", opts, true)
				if j >= 0:
					deck.append(opts[j].card)
			elif i == 1:
				var j := await ui.choose("BRÛLER", "Quelle carte retirer ?", deck.map(func(c): return {"card": c}), true)
				if j >= 0:
					deck.remove_at(j)
	ui.set_gold(gold)
	if mode != "aventure":
		_haven_end()
	else:
		_explore_hud()


# ------------------------------------------------------------------ musique

func _music_vol() -> float:
	return -80.0 if _mute or music_vol < 0.01 else linear_to_db(music_vol) - 5.0


func set_music_volume(v: float) -> void:
	music_vol = clampf(v, 0.0, 1.0)
	_mute = false
	if _music.size() > 1:
		(_music[1] as AudioStreamPlayer).volume_db = _music_vol()
	var cf := ConfigFile.new()
	cf.load("user://reglages.cfg")
	cf.set_value("son", "musique", music_vol)
	cf.save("user://reglages.cfg")


func set_voc_start(on: bool) -> void:
	voc_start = on
	var cf := ConfigFile.new()
	cf.load("user://reglages.cfg")
	cf.set_value("partie", "vocation", on)
	cf.save("user://reglages.cfg")
	ui.toast("Vocation dès le départ %s : le premier Ancien la proposera %s." % (["activée", "toujours"] if on else ["désactivée", "au hasard"]))


func set_tactic(on: bool) -> void:
	## Vue tactique (réglage, ou T en combat) : un affichage épuré du même combat, appliqué tout de suite.
	tactic = on
	var cf := ConfigFile.new()
	cf.load("user://reglages.cfg")
	cf.set_value("ecran", "tactique", on)
	cf.save("user://reglages.cfg")
	_apply_tactic()
	ui.toast("Vue tactique %s." % ("activée · T pour revenir" if on else "désactivée"))


func _apply_tactic() -> void:
	## Seulement en combat : le titre et le donjon gardent leur décor.
	var on: bool = tactic and ui.hud.visible and not exploring
	board.set_tactic(on)
	ambient_root.visible = not on
	if on:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.07, 0.065, 0.08)
		env.fog_enabled = false
	else:
		env.background_mode = Environment.BG_SKY
		env.fog_enabled = true


func _read_lang() -> String:
	## Langue : --lang=en pour forcer ; sinon le réglage ; au premier lancement, celle du système.
	if args.has("lang"):
		return args.lang
	var cf := ConfigFile.new()
	if cf.load("user://reglages.cfg") == OK and cf.has_section_key("ecran", "langue"):
		return str(cf.get_value("ecran", "langue"))
	return "fr" if OS.get_locale_language() == "fr" else "en"


func set_lang(code: String) -> void:
	## Change la langue et relance la scène (tous les textes se refont) ; la partie sauvegardée reste.
	var cf := ConfigFile.new()
	cf.load("user://reglages.cfg")
	cf.set_value("ecran", "langue", code)
	cf.save("user://reglages.cfg")
	args.erase("lang")
	Lang.setup(code == "en")
	get_tree().reload_current_scene()


func _read_mobile() -> bool:
	## Par défaut : actif sur un navigateur de téléphone ; --portable=1 / 0 pour forcer.
	if args.has("portable"):
		return args.portable != "0"
	var cf := ConfigFile.new()
	if cf.load("user://reglages.cfg") == OK and cf.has_section_key("ecran", "portable"):
		return bool(cf.get_value("ecran", "portable"))
	# une tablette dans un navigateur ne se déclare pas toujours « mobile » (iPad = Safari de bureau) : l'écran tactile suffit
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())


func set_mobile(on: bool) -> void:
	## Change le mode et relance la scène (l'interface se reconstruit) ; la partie sauvegardée reste.
	var cf := ConfigFile.new()
	cf.load("user://reglages.cfg")
	cf.set_value("ecran", "portable", on)
	cf.save("user://reglages.cfg")
	if on and OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	args.erase("portable")
	get_tree().reload_current_scene()


func _touch(e: InputEvent) -> void:
	## Deux doigts : écarter = zoom, glisser = tourner autour du plateau. Un doigt qui glisse : tourner aussi.
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_tap_drag = 0.0
		else:
			_touches.erase(e.index)
		if _touches.size() > 1:
			_tap_drag = 99.0  # un geste à deux doigts n'est jamais un toucher
	elif e is InputEventScreenDrag and _touches.has(e.index):
		if _touches.size() >= 2:
			var ids: Array = _touches.keys().slice(0, 2)
			var a: Vector2 = _touches[ids[0]]
			var b: Vector2 = _touches[ids[1]]
			var before := a.distance_to(b)
			var mid0 := (a + b) / 2.0
			_touches[e.index] = e.position
			a = _touches[ids[0]]
			b = _touches[ids[1]]
			if before > 10.0:
				dist = clampf(dist * before / maxf(10.0, a.distance_to(b)), 7.0, 60.0)
			var dm := (a + b) / 2.0 - mid0
			yaw -= dm.x * 0.25
			pitch = clampf(pitch + dm.y * 0.15, 12.0, 82.0)
		else:
			_touches[e.index] = e.position
			_tap_drag += e.relative.length()
			if _tap_drag > 14.0:
				yaw -= e.relative.x * 0.3
				pitch = clampf(pitch + e.relative.y * 0.2, 12.0, 82.0)


func _tap(pos: Vector2) -> void:
	## Au doigt, pas de survol : un premier toucher vise (aperçu, fiche), le même toucher une deuxième fois valide.
	if exploring and ui.overlay == null:
		var hc = aboard.pick(cam.project_ray_origin(pos), cam.project_ray_normal(pos))
		if hc != null and hc == _adv_hover:
			_adv_click(hc)
		else:
			_adv_hover = hc
			aboard.highlight({hc: Color(1, 1, 1, 0.7)} if hc != null and aboard.walkable(hc) else {})
		return
	if not ui.hud.visible:
		return
	var c = _pick(cam.project_ray_origin(pos), cam.project_ray_normal(pos))
	if c != null and c == hover:
		battle.click(c)
	else:
		hover = c
		refresh_hover()


const PLAYLIST := {"titre": ["reveur"], "calme": ["chill_bnb", "pulse_alice", "far_away", "reveur"],
	"combat": ["bebey", "combo_devils", "dark_is_the_sun"], "elite": ["proceed_caution", "combo_devils"], "boss": ["wretched"]}
var _track_i := {}


func play_music(kind: String) -> void:
	## titre, calme (cartes, exploration), combat, élite, boss : chaque ambiance tourne sur ses morceaux. Fondu enchaîné.
	if kind == _music_kind or _music.is_empty():
		return
	_music_kind = kind
	var pool: Array = PLAYLIST.get(kind, PLAYLIST.calme).filter(func(n): return ResourceLoader.exists("res://assets/music/%s.mp3" % n))
	if pool.is_empty():
		return
	_track_i[kind] = int(_track_i.get(kind, randi())) + 1
	var path := "res://assets/music/%s.mp3" % pool[int(_track_i[kind]) % pool.size()]
	var st: AudioStreamMP3 = load(path)
	st.loop = true
	var old: AudioStreamPlayer = _music[1]
	if old.stream == st and old.playing:
		return
	_music.reverse()
	var nw: AudioStreamPlayer = _music[1]
	nw.stream = st
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(nw, "volume_db", _music_vol(), 1.5)
	tw.tween_property(old, "volume_db", -80.0, 1.5)
	tw.chain().tween_callback(func():
		if _music[0] == old:
			old.stop())
