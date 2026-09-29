class_name Fx
## Effets ponctuels : chiffres de dégâts, gerbes d'étincelles, projectiles, ambiance.

# Polices embarquées (libres) : le navigateur n'a pas les polices du système.
static var font: Font
static var _num_font: Font
static var _body_font: Font


static func _face(path: String, wght: int) -> FontVariation:
	var base: FontFile = load(path)
	if base.fallbacks.is_empty():
		var fb: Array[Font] = []
		for f in ["dejavu_mono", "noto_math", "noto_emoji"]:
			fb.append(load("res://fonts/%s.woff2" % f))
		base.fallbacks = fb
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	fv.fallbacks = base.fallbacks  # sinon une variation de variation perd les symboles
	return fv


static func title_font() -> Font:
	if font == null:
		font = _face("res://fonts/fraunces.woff2", 700)
	return font


static var _goth := {}
static func goth(n: String) -> Font:
	## Polices gothiques des titres : fette_trump (logo), pirataone (menu), newrocker (titres d'écran).
	if not _goth.has(n):
		var f: FontFile = load("res://fonts/%s.ttf" % n)
		if f.fallbacks.is_empty():
			var fb: Array[Font] = []
			for x in ["dejavu_mono", "noto_math", "noto_emoji"]:
				fb.append(load("res://fonts/%s.woff2" % x))
			f.fallbacks = fb
		_goth[n] = f
	return _goth[n]


static func number_font() -> Font:
	if _num_font == null:
		_num_font = _face("res://fonts/lato_bold.woff2", 700)
	return _num_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = _face("res://fonts/lato.woff2", 400)
	return _body_font


static func number(parent: Node, pos: Vector3, text: String, col: Color, big := false) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = number_font()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 88 if big else 64
	l.pixel_size = 0.0055
	l.outline_size = 20
	l.modulate = col
	l.outline_modulate = Color(0.08, 0.04, 0.02, 0.95)
	l.render_priority = 10
	l.outline_render_priority = 9
	l.position = pos + Vector3(randf_range(-0.2, 0.2), 2.3, 0)
	parent.add_child(l)
	l.scale = Vector3.ONE * 1.6
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y + 0.45, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)


static func _glow_mat(col: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col.r * energy, col.g * energy, col.b * energy)
	m.vertex_color_use_as_albedo = true
	return m


static var _soft: GradientTexture2D
static var _ring: GradientTexture2D


static func _radial(offs: Array, alphas: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	var pc := PackedColorArray()
	for a in alphas:
		pc.append(Color(1, 1, 1, a))
	g.colors = pc
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


static func soft_mat(col: Color, energy := 2.0, additive := true, billboard := BaseMaterial3D.BILLBOARD_PARTICLES) -> StandardMaterial3D:
	## Halo doux : lueurs, fumées, traînées. Remplace les cubes nus.
	if _soft == null:
		_soft = _radial([0.0, 0.25, 1.0], [1.0, 0.55, 0.0])
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = billboard
	m.albedo_texture = _soft
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(col.r * energy, col.g * energy, col.b * energy, 1.0) if additive else col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	return g


static var lite := false  # mode portable : ni particules, ni lumières éphémères (ça ramait sur tablette)
static var particles := true  # réglage Graphismes > Particules


static func glow_puff(parent: Node, pos: Vector3, col: Color, n := 8, size := 0.55, life := 0.45, speed := 0.8) -> void:
	if lite or not particles:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = maxi(2, n)
	p.lifetime = life
	var q := QuadMesh.new()
	q.size = Vector2.ONE * size
	p.mesh = q
	p.material_override = soft_mat(col, 1.6)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.3
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, 0.6, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 1.3))
	p.scale_amount_curve = curve
	p.color_ramp = _fade_ramp()
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func flash(parent: Node, pos: Vector3, col: Color, energy := 3.0, rng := 3.5) -> void:
	## Éclair de lumière bref : l'explosion éclaire les pierres autour.
	if lite or not particles:
		return
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	l.position = pos + Vector3(0, 0.6, 0)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)


static func ring(parent: Node, pos: Vector3, col: Color, radius := 1.6) -> void:
	if lite or not particles:
		return
	## Onde de choc au sol.
	if _ring == null:
		_ring = _radial([0.0, 0.62, 0.78, 0.9, 1.0], [0.0, 0.0, 1.0, 0.0, 0.0])
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := soft_mat(col, 2.2, true, BaseMaterial3D.BILLBOARD_DISABLED)
	m.albedo_texture = _ring
	m.vertex_color_use_as_albedo = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, 0.08, 0)
	mi.scale = Vector3.ONE * 0.3
	parent.add_child(mi)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * radius * 2.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.4)
	tw.chain().tween_callback(mi.queue_free)


static func smoke_cloud(parent: Node, pos: Vector3) -> Node3D:
	## Fumée qui roule sur la case tant qu'elle dure.
	var p := CPUParticles3D.new()
	p.amount = 14 if not lite else 4  # la fumée reste : c'est une règle de jeu
	p.lifetime = 2.2
	p.preprocess = 2.2
	var q := QuadMesh.new()
	q.size = Vector2.ONE * 0.9
	p.mesh = q
	p.material_override = soft_mat(Color(0.8, 0.8, 0.82, 0.5), 1.0, false)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.35, 0.15, 0.35)
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.gravity = Vector3(0, 0.05, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(1, 1.3))
	p.scale_amount_curve = curve
	p.color_ramp = _fade_ramp()
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.position = pos
	parent.add_child(p)
	return p


static func burst(parent: Node, pos: Vector3, col: Color, amount := 26, speed := 3.2, up := 0.0) -> void:
	if lite or not particles:
		return
	# un halo doux derrière les éclats ; les grosses gerbes éclairent et font une onde au sol
	glow_puff(parent, pos, col, amount / 6, 0.45 + amount * 0.004, 0.4 + amount * 0.002, speed * 0.3)
	if amount >= 60:
		flash(parent, pos, col.lightened(0.2), 3.5, 4.5)
		ring(parent, pos - Vector3(0, 0.55, 0), col.lightened(0.3), 1.8)
	elif amount >= 30:
		flash(parent, pos, col, 1.6, 2.5)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(4, amount * 2 / 3)
	p.lifetime = 0.7
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.06
	p.mesh = bm
	p.material_override = _glow_mat(col)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6.0 + up, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func bolt(parent: Node, from: Vector3, to: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new()
	var s := QuadMesh.new()
	s.size = Vector2.ONE * 0.55
	m.mesh = s
	m.material_override = soft_mat(col.lightened(0.3), 2.4, true, BaseMaterial3D.BILLBOARD_ENABLED)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.06
	cs.height = 0.12
	core.mesh = cs
	core.material_override = _glow_mat(Color(1, 1, 1).lerp(col, 0.3), 4.0)
	m.add_child(core)
	parent.add_child(m)
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.0
	light.omni_range = 2.5
	m.add_child(light)
	var trail := CPUParticles3D.new()
	trail.emitting = not lite
	trail.amount = 48
	trail.lifetime = 0.3
	trail.local_coords = false
	var bm := QuadMesh.new()
	bm.size = Vector2.ONE * 0.26
	trail.mesh = bm
	trail.material_override = soft_mat(col, 1.4)
	trail.color_ramp = _fade_ramp()
	trail.gravity = Vector3(0, 0.5, 0)
	trail.initial_velocity_max = 0.3
	trail.spread = 180
	m.add_child(trail)
	var a := from + Vector3(0, 0.9, 0)
	var b := to + Vector3(0, 0.7, 0)
	var arc := 0.6 + a.distance_to(b) * 0.12
	var tw := m.create_tween()
	tw.tween_method(func(k: float): m.position = a.lerp(b, k) + Vector3(0, sin(k * PI) * arc, 0), 0.0, 1.0, 0.1 + a.distance_to(b) * 0.05)
	await tw.finished
	burst(parent, b, col, 18, 2.5)
	m.queue_free()


static func ambient(parent: Node, biome: Dictionary, center: Vector3) -> void:
	if lite or not particles:
		return
	if biome.leaves:
		var p := GPUParticles3D.new()
		p.amount = 70
		p.lifetime = 18.0
		p.preprocess = 18.0
		p.visibility_aabb = AABB(Vector3(-20, -12, -20), Vector3(40, 24, 40))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(13, 0.5, 13)
		pm.direction = Vector3(0.3, -1, 0.2)
		pm.spread = 25.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.5
		pm.gravity = Vector3(0.18, -0.28, 0.08)
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 1.4
		pm.turbulence_influence_min = 0.15
		pm.turbulence_influence_max = 0.35
		pm.angle_min = 0
		pm.angle_max = 360
		pm.angular_velocity_min = -160
		pm.angular_velocity_max = 160
		pm.scale_min = 0.6
		pm.scale_max = 1.3
		var g := Gradient.new()
		var cols: Array = biome.leaves
		var offs := PackedFloat32Array()
		var pc := PackedColorArray()
		for i in cols.size():
			offs.append(float(i) / maxi(1, cols.size() - 1))
			pc.append(Color(cols[i]))
		g.offsets = offs
		g.colors = pc
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_initial_ramp = gt
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.026)
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.backlight_enabled = true
		m.backlight = Color(0.5, 0.25, 0.08)
		q.material = m
		p.draw_pass_1 = q
		p.position = center + Vector3(0, 9, 0)
		parent.add_child(p)
	if biome.get("embers", false):
		var e := GPUParticles3D.new()
		e.amount = 140
		e.lifetime = 6.0
		e.preprocess = 6.0
		e.visibility_aabb = AABB(Vector3(-16, -2, -16), Vector3(32, 14, 32))
		var em := ParticleProcessMaterial.new()
		em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		em.emission_box_extents = Vector3(11, 0.2, 11)
		em.gravity = Vector3(0.1, 0.35, 0.05)
		em.initial_velocity_min = 0.1
		em.initial_velocity_max = 0.4
		em.turbulence_enabled = true
		em.turbulence_noise_strength = 1.0
		em.scale_min = 0.5
		em.scale_max = 1.2
		var sc2 := Curve.new()
		sc2.add_point(Vector2(0, 1))
		sc2.add_point(Vector2(1, 0))
		var sct2 := CurveTexture.new()
		sct2.curve = sc2
		em.scale_curve = sct2
		e.process_material = em
		var eq := QuadMesh.new()
		eq.size = Vector2(0.05, 0.05)
		var emat := _glow_mat(Color(1.0, 0.45, 0.15), 4.0)
		emat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		eq.material = emat
		e.draw_pass_1 = eq
		e.position = center + Vector3(0, 0.4, 0)
		parent.add_child(e)
	# poussière et lucioles dans la lumière
	var f := GPUParticles3D.new()
	f.amount = 70 if biome.leaves else 110
	f.lifetime = 9.0
	f.preprocess = 9.0
	f.visibility_aabb = AABB(Vector3(-16, -4, -16), Vector3(32, 10, 32))
	var fm := ParticleProcessMaterial.new()
	fm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fm.emission_box_extents = Vector3(10, 1.5, 10)
	fm.gravity = Vector3(0, 0.02, 0)
	fm.initial_velocity_max = 0.1
	fm.turbulence_enabled = true
	fm.turbulence_noise_strength = 0.6
	fm.turbulence_noise_speed_random = 0.4
	fm.scale_min = 0.4
	fm.scale_max = 1.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0))
	sc.add_point(Vector2(0.2, 1))
	sc.add_point(Vector2(0.8, 1))
	sc.add_point(Vector2(1, 0))
	var sct := CurveTexture.new()
	sct.curve = sc
	fm.scale_curve = sct
	f.process_material = fm
	var fq := QuadMesh.new()
	fq.size = Vector2(0.035, 0.035)
	var col := Color(1.0, 0.72, 0.38) if not biome.leaves else Color(1.0, 0.9, 0.7)
	var fmat := _glow_mat(col, 3.0 if not biome.leaves else 1.2)
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fq.material = fmat
	f.draw_pass_1 = fq
	f.position = center + Vector3(0, 2.4, 0)
	parent.add_child(f)
