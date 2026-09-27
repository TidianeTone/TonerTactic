class_name Board
extends Node3D
## Génère une salle de ruines et la dessine avec les modules voxel de Blender (MultiMesh).
## Quatre topologies : écluse (plateformes et ponts), terrasses (pente en gradins coupée d'un
## canal), cour (cour creuse ceinte de chemins de ronde), îlots (archipel de piliers).
## Seules les faces de mur exposées sont posées : l'intérieur des colonnes n'existe pas.

const RING := 7        # couronne de décor autour
const LH := 0.5        # hauteur d'un niveau
const SLAB := 0.125    # épaisseur de la dalle de sol
const WATER_Y := 0.34
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const ARCHETYPES := ["ecluse", "terrasses", "cour", "ilots"]

var dim := 16        # plateau jouable dim x dim
var archetype := "ecluse"
var h := {}          # Vector2i -> niveau (0 = eau)
var kind := {}       # "water" | "land" | "bridge" | "tower" | "monument"
var along_x := {}    # pont : vrai s'il court le long de X
var blocked := {}    # Vector2i -> "tree" (décor) | "oak" (planté)
var live_trees := false  # en combat, les arbres du plateau sont des objets à PV (dessinés par Battle)
var props := {}      # Vector2i -> "coffre" | "brasero" | "pilier" | "baril"
var pillars := {}    # colonnade de la couronne
var paths := {}      # cases réservées aux liaisons
var rects: Array[Rect2i] = []
var links: Array = []      # donjon : paires de salles reliées
var start := Vector2i.ZERO
var portal := Vector2i(-99, -99)
var rng := RandomNumberGenerator.new()
var biome: Dictionary
var monument_at := Vector2i(-99, -99)
var monument_face := Vector2i.ZERO

var _hl: MultiMeshInstance3D
var _water: MeshInstance3D
static var _meshes := {}
static var hd := false  ## voxel fin (assets/hd, généré par DELVE_HD=3) : PC en qualité ultra
static var _mats := {}


func center() -> Vector3:
	return Vector3((dim - 1) * 0.5, 1.2, (dim - 1) * 0.5)


# ------------------------------------------------------------------ génération

func generate(seed: int, b: Dictionary, size := 16, arch := "", with_props := true) -> void:
	live_trees = with_props
	for attempt in 20:
		_generate(seed + attempt * 7919, b, size, arch)
		if _connected():
			if with_props:
				_place_props()
			return
	push_warning("salle non connexe, seed %d" % seed)


func _generate(seed: int, b: Dictionary, size: int, arch: String) -> void:
	rng.seed = seed
	biome = b
	dim = size
	archetype = arch if arch != "" else ARCHETYPES[rng.randi_range(0, ARCHETYPES.size() - 1)]
	for d in [h, kind, along_x, blocked, paths, pillars, props]:
		d.clear()
	rects.clear()
	links.clear()
	portal = Vector2i(-99, -99)
	for x in range(-RING, dim + RING):
		for z in range(-RING, dim + RING):
			h[Vector2i(x, z)] = 0
			kind[Vector2i(x, z)] = "water"
	match archetype:
		"terrasses":
			_gen_terrasses()
		"cour":
			_gen_cour()
		"ilots":
			_gen_islands(3, 5, dim * dim / 20)
		"donjon":
			_gen_dungeon()
		"damier":
			_gen_damier()
		_:
			_gen_islands(4, 7, dim * dim / 40)  # plateformes larges : de la place pour manœuvrer
	_ring(seed)
	_towers_and_trees()


func _gen_islands(lo: int, hi: int, want: int) -> void:
	## Plateformes reliées par un arbre couvrant de ponts, plus une boucle.
	var tries := 0
	while rects.size() < want and tries < 800:
		tries += 1
		var r := Rect2i(rng.randi_range(0, dim - lo), rng.randi_range(0, dim - lo), rng.randi_range(lo, hi), rng.randi_range(lo, hi))
		if r.end.x > dim or r.end.y > dim:
			continue
		if rects.any(func(o): return o.grow(1).intersects(r)):
			continue
		rects.append(r)
	for r in rects:
		var base := rng.randi_range(2, 3) if archetype == "ecluse" else rng.randi_range(2, 5)
		_fill(r, base, "land")
		if r.size.x >= 4 and r.size.y >= 4 and rng.randf() < 0.7:
			var d := Rect2i(r.position + Vector2i(1, 1), Vector2i(rng.randi_range(2, r.size.x - 2), rng.randi_range(2, r.size.y - 2)))
			_fill(d, base + rng.randi_range(1, 2), "land")
	var inside := [0]
	var todo := range(1, rects.size())
	while todo.size() > 0:
		var best := Vector3i(-1, -1, 1 << 30)
		for a in inside:
			for bi in todo:
				var dd := _manhattan(rects[a].get_center(), rects[bi].get_center())
				if dd < best.z:
					best = Vector3i(a, bi, dd)
		_carve(rects[best.x].get_center(), rects[best.y].get_center())
		inside.append(best.y)
		todo.erase(best.y)
	if rects.size() > 3:
		_carve(rects[0].get_center(), rects[rects.size() - 1].get_center())
	start = rects[0].get_center()


func _gen_dungeon() -> void:
	## Mode aventure : une grille de salles (une par case de 9), reliées par un arbre de ponts et quelques boucles.
	var n := dim / 9
	var slot := {}
	for gx in n:
		for gz in n:
			if gx + gz > 0 and rng.randf() > 0.82:
				continue
			var w := rng.randi_range(5, 7)
			var d := rng.randi_range(5, 7)
			var r := Rect2i(gx * 9 + rng.randi_range(0, 8 - w), gz * 9 + rng.randi_range(0, 8 - d), w, d)
			slot[Vector2i(gx, gz)] = rects.size()
			rects.append(r)
	for r in rects:
		var base := rng.randi_range(2, 4)
		_fill(r, base, "land")
		if rng.randf() < 0.5:
			var cx := r.position.x + (1 if rng.randf() < 0.5 else r.size.x - 3)
			var cz := r.position.y + (1 if rng.randf() < 0.5 else r.size.y - 3)
			_fill(Rect2i(cx, cz, 2, 2), base + 1, "land")
	var keys: Array = slot.keys()
	var inside: Array = [Vector2i.ZERO]
	var todo: Array = keys.filter(func(k): return k != Vector2i.ZERO)
	while todo.size() > 0:
		var best := [null, null, 1 << 30]
		for a in inside:
			for b in todo:
				var dd: int = absi(a.x - b.x) + absi(a.y - b.y)
				if dd < best[2]:
					best = [a, b, dd]
		_carve(rects[slot[best[0]]].get_center(), rects[slot[best[1]]].get_center())
		links.append([slot[best[0]], slot[best[1]]])
		inside.append(best[1])
		todo.erase(best[1])
	for a in keys:
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var b: Vector2i = a + d
			if slot.has(b) and rng.randf() < 0.25 and not links.any(func(l): return (l[0] == slot[a] and l[1] == slot[b]) or (l[0] == slot[b] and l[1] == slot[a])):
				_carve(rects[slot[a]].get_center(), rects[slot[b]].get_center())
				links.append([slot[a], slot[b]])
	start = rects[slot[Vector2i.ZERO]].get_center()


func _gen_damier() -> void:
	## Mode tactique : un damier plat aux coins coupés, des murets bas posés en symétrie par le centre.
	## Ni relief ni pente : tout se joue sur le placement, les lignes de vue et les murets.
	var m := (dim - 1) * 0.5
	for x in dim:
		for z in dim:
			if absf(x - m) + absf(z - m) <= dim * 0.8:
				kind[Vector2i(x, z)] = "land"
				h[Vector2i(x, z)] = 2
	var want := 2 + dim / 5
	var tries := 0
	while want > 0 and tries < 300:
		tries += 1
		var d := Vector2i(1, 0) if rng.randf() < 0.5 else Vector2i(0, 1)
		var p := Vector2i(rng.randi_range(1, dim - 2), rng.randi_range(2, dim / 2 - 1))
		var col := rng.randf() < 0.4  # colonne isolée, ou muret de 2 à 4
		var cells: Array[Vector2i] = []
		for k in (1 if col else rng.randi_range(2, 4)):
			cells.append(p + d * k)
		for c in cells.duplicate():
			cells.append(Vector2i(dim - 1 - c.x, dim - 1 - c.y))
		# murets espacés : jamais collés à un autre ni au bord du damier
		if cells.any(func(c): return not _in(c) or kind[c] != "land" or DIRS.any(func(dd): return not _in(c + dd) or kind[c + dd] != "land" and not cells.has(c + dd))):
			continue
		for c in cells:
			kind[c] = "tower"
			h[c] = 6 if col else 4
		if _connected():
			want -= 1
		else:
			for c in cells:
				kind[c] = "land"
				h[c] = 2
	start = Vector2i(dim / 2, dim - 2)


func _gen_terrasses() -> void:
	## Pente en quatre gradins, coupée d'un canal franchi par deux ponts.
	var ax := rng.randf() < 0.5
	for x in dim:
		for z in dim:
			var t := x if ax else z
			var band := int(float(t) / dim * 4.0)
			var c := Vector2i(x, z)
			kind[c] = "land"
			h[c] = 2 + band + (1 if rng.randf() < 0.1 else 0)
	var ct := rng.randi_range(dim / 3, dim / 2)
	var crossings := [rng.randi_range(1, dim / 2 - 1), rng.randi_range(dim / 2 + 1, dim - 2)]
	for s in dim:
		var c := Vector2i(ct, s) if ax else Vector2i(s, ct)
		if s in crossings:
			kind[c] = "bridge"
			h[c] = 3
			along_x[c] = ax
			paths[c] = true
		else:
			kind[c] = "water"
			h[c] = 0
	for x in dim:
		for z in dim:
			var c := Vector2i(x, z)
			if kind[c] == "land" and not paths.has(c) and rng.randf() < 0.05:
				kind[c] = "water"
				h[c] = 0
	start = Vector2i(1, dim / 2) if ax else Vector2i(dim / 2, 1)


func _gen_cour() -> void:
	## Cour creuse, chemins de ronde surélevés, escaliers, fontaine centrale, tours d'angle.
	for x in dim:
		for z in dim:
			var c := Vector2i(x, z)
			var edge := mini(mini(x, z), mini(dim - 1 - x, dim - 1 - z))
			kind[c] = "land"
			h[c] = 5 if edge < 2 else 2
	for side in 4:
		var s := rng.randi_range(3, dim - 4)
		for k in 2:
			var c: Vector2i = [Vector2i(k, s), Vector2i(dim - 1 - k, s), Vector2i(s, k), Vector2i(s, dim - 1 - k)][side]
			h[c] = 4 - k
			paths[c] = true
			var c2: Vector2i = [Vector2i(k, s + 1), Vector2i(dim - 1 - k, s + 1), Vector2i(s + 1, k), Vector2i(s + 1, dim - 1 - k)][side]
			h[c2] = 4 - k
			paths[c2] = true
	var fw := rng.randi_range(2, 4)
	var f0 := dim / 2 - fw / 2
	_fill(Rect2i(f0, f0, fw, fw), 0, "water")
	for c in [Vector2i(0, 0), Vector2i(dim - 1, 0), Vector2i(0, dim - 1), Vector2i(dim - 1, dim - 1)]:
		kind[c] = "tower"
		h[c] = rng.randi_range(9, 12)
	start = Vector2i(dim / 2, dim - 4)


func _towers_and_trees() -> void:
	var lands: Array[Vector2i] = []
	for c: Vector2i in h:
		if _in(c) and kind[c] == "land" and not paths.has(c):
			lands.append(c)
	lands.sort()
	_shuffle(lands)
	var towers := 0
	for c in lands:
		if towers >= 1 + dim / 8 or archetype in ["cour", "damier"]:
			break
		if _edge_count(c) >= 1 and rng.randf() < 0.3:
			var old: int = h[c]
			kind[c] = "tower"
			h[c] = old + rng.randi_range(5, 8)
			if _connected():
				towers += 1
			else:
				kind[c] = "land"
				h[c] = old
	var trees := 0
	for c in lands:
		if kind[c] != "land" or archetype == "damier" or trees >= 2 + dim / 6:
			continue
		if (_edge_count(c) > 0 or archetype == "cour") and rng.randf() < 0.08:
			blocked[c] = "tree"
			if not _connected():
				blocked.erase(c)
			else:
				trees += 1


func _place_props() -> void:
	## Coffres loin du départ, braseros et piliers fragiles près des ennemis.
	var cells := walkable_cells()
	cells.sort()
	_shuffle(cells)
	var near := bfs_dist([_nearest_walkable(start)], 2, false)
	if archetype == "damier":
		_damier_props()
		return
	var want := {"coffre": 2 + int(dim >= 16), "brasero": dim / 4, "pilier": dim / 5}
	for c in cells:
		if paths.has(c) or near.get(c, 99) < 4:
			continue
		for k in want:
			if want[k] <= 0:
				continue
			if k == "coffre" and near.get(c, 0) < dim / 2:
				continue
			props[c] = k
			if _connected():
				want[k] -= 1
			else:
				props.erase(c)
			break
	# un seul objet spécial par arène, et pas à chaque combat : râtelier (au bout de l'arène, il faut aller le chercher),
	# vasque ou cloche (à mi-chemin : les ennemis s'en servent aussi, c'est une course)
	var roll := rng.randf()
	var sp: String = "ratelier" if roll < 0.15 else ("vasque" if roll < 0.27 else ("cloche" if roll < 0.37 else ""))
	if dim >= 12 and sp != "":
		var land: Array = cells.filter(func(c): return near.has(c) and not paths.has(c) and not props.has(c) and not blocked.has(c) and kind.get(c, "") == "land")
		var top: int = 0
		for c in land:
			top = maxi(top, near[c])
		var goal: int = top if sp == "ratelier" else top / 2
		land.sort_custom(func(a, b): return absi(near[a] - goal) < absi(near[b] - goal))
		for c in land.slice(0, 6):
			props[c] = sp
			if _connected():
				break
			props.erase(c)


func _damier_props() -> void:
	## Parvis : une paire (symétrique) d'arbres, de braseros, de barils et de piliers, un coffre au centre.
	var m := func(c: Vector2i) -> Vector2i: return Vector2i(dim - 1 - c.x, dim - 1 - c.y)
	var free := func(c: Vector2i) -> bool: return _in(c) and kind[c] == "land" and not blocked.has(c) and not props.has(c) and c.y >= 2 and c.y <= dim - 3
	for k in ["tree", "brasero", "baril", "pilier"]:
		for tries in 60:
			var c := Vector2i(rng.randi_range(1, dim - 2), rng.randi_range(2, dim / 2 - 1))
			var mc: Vector2i = m.call(c)
			if not free.call(c) or not free.call(mc) or c == mc:
				continue
			for x in [c, mc]:
				if k == "tree":
					blocked[x] = "tree"
				else:
					props[x] = k
			if _connected():
				break
			for x in [c, mc]:
				blocked.erase(x)
				props.erase(x)
	var mid := Vector2i(dim / 2, dim / 2)
	for r in 3:
		var done := false
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var c := mid + Vector2i(dx, dz)
				if not done and free.call(c):
					props[c] = "coffre"
					if _connected():
						done = true
					else:
						props.erase(c)
		if done:
			break


func place_portal() -> void:
	## Sortie à atteindre : la case praticable la plus éloignée du départ.
	var near := bfs_dist([_nearest_walkable(start)], 2, false)
	var best := portal
	var bd := -1
	for c in near:
		if near[c] > bd and not props.has(c):
			bd = near[c]
			best = c
	portal = best


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _fill(r: Rect2i, height: int, k: String) -> void:
	for x in range(r.position.x, r.end.x):
		for z in range(r.position.y, r.end.y):
			h[Vector2i(x, z)] = height
			kind[Vector2i(x, z)] = k


func _carve(a: Vector2i, b: Vector2i) -> void:
	var p := a
	var xfirst := rng.randf() < 0.5
	while p != b:
		var step: Vector2i
		if (xfirst and p.x != b.x) or p.y == b.y:
			step = Vector2i(signi(b.x - p.x), 0)
		else:
			step = Vector2i(0, signi(b.y - p.y))
		p += step
		# ponts de deux cases de large : on s'y croise, on s'y contourne
		for q in [p, p + Vector2i(step.y, step.x)]:
			if not _in(q) or (q != p and archetype == "donjon"):
				continue
			paths[q] = true
			if kind[q] == "water":
				kind[q] = "bridge"
				h[q] = 3
				along_x[q] = step.x != 0


func _out(c: Vector2i) -> int:
	return maxi(maxi(-c.x, c.x - (dim - 1)), maxi(-c.y, c.y - (dim - 1)))


func _ring(seed: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.1
	for c: Vector2i in h:
		if _in(c):
			continue
		var out := _out(c)
		var v := noise.get_noise_2d(c.x, c.y) + out * 0.05
		if out == 1:
			v -= 0.25  # un fossé d'eau autour de l'arène
		if v > 0.14:
			kind[c] = "land"
			h[c] = 2 + int(v * 4.0) + out / 2
			if v > 0.36 and out >= 3 and rng.randf() < 0.3:
				kind[c] = "tower"
				h[c] += rng.randi_range(5, 10)
			elif out >= 2 and rng.randf() < 0.14:
				blocked[c] = "tree"
	# un monument au fond de la scène (la caméra part du coin +x +z), face à l'arène
	var side: Vector2i = [Vector2i(-1, 0), Vector2i(0, -1)][rng.randi_range(0, 1)]
	var mid := Vector2i(dim / 2, dim / 2)
	monument_at = mid
	if side.x != 0:
		monument_at.x = -4
	else:
		monument_at.y = -4
	monument_face = -side
	var across := Vector2i(absi(side.y), absi(side.x))
	for k in range(-3, 4):
		for dd in range(-2, 2):
			var c := monument_at + across * k + side * dd
			if h.has(c):
				kind[c] = "water"
				h[c] = 0
				blocked.erase(c)
	for k in range(-1, 2):
		kind[monument_at + across * k] = "monument"
	# une colonnade avec architraves sur un côté perpendiculaire
	var side2 := Vector2i(side.y, side.x) * (1 if rng.randf() < 0.5 else -1)
	var line := mid
	if side2.x != 0:
		line.x = dim if side2.x > 0 else -1
	else:
		line.y = dim if side2.y > 0 else -1
	var across2 := Vector2i(absi(side2.y), absi(side2.x))
	for k in range(-6, 6):
		var c := line + across2 * k
		if not h.has(c) or kind[c] == "monument":
			continue
		kind[c] = "land"
		h[c] = 1
		blocked.erase(c)
		if (k + 12) % 2 == 0:
			pillars[c] = rng.randf() < 0.25


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _in(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < dim and c.y < dim


func _edge_count(c: Vector2i) -> int:
	var k := 0
	for d in DIRS:
		if kind.get(c + d, "water") == "water":
			k += 1
	return k


func _connected() -> bool:
	var cells := walkable_cells()
	if cells.is_empty():
		return false
	var seen := {cells[0]: true}
	var q: Array[Vector2i] = [cells[0]]
	while q.size() > 0:
		var c: Vector2i = q.pop_back()
		for d in DIRS:
			var nb := c + d
			if walkable(nb) and not seen.has(nb) and absi(h[nb] - h[c]) <= 2:
				seen[nb] = true
				q.append(nb)
	return seen.size() == cells.size()


# ------------------------------------------------------------------ requêtes

func walkable(c: Vector2i) -> bool:
	return _in(c) and (kind[c] == "land" or kind[c] == "bridge") and not blocked.has(c) and not props.has(c)


func walkable_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in dim:
		for z in dim:
			if walkable(Vector2i(x, z)):
				out.append(Vector2i(x, z))
	return out


func top_y(c: Vector2i) -> float:
	return h.get(c, 0) * LH + SLAB


func world(c: Vector2i) -> Vector3:
	return Vector3(c.x, top_y(c), c.y)


func _nearest_walkable(c: Vector2i) -> Vector2i:
	var best := c
	var bd := 1 << 30
	for w in walkable_cells():
		var dd := _manhattan(w, c)
		if dd < bd:
			bd = dd
			best = w
	return best


func spawn_cells(side: String, count: int, avoid: Array = []) -> Array[Vector2i]:
	## Héros près du départ, espacés de deux cases ; ennemis au plus loin, à distance des héros.
	## Les contraintes se relâchent seulement si la carte ne permet pas mieux.
	var cells := walkable_cells()
	var dist := bfs_dist([_nearest_walkable(start)], 2, false)
	if side == "foe":
		# ni au contact ni à l'autre bout du labyrinthe : on se croise au deuxième tour
		cells.shuffle()
		cells.sort_custom(func(a, b): return absi(dist.get(a, 99) - (6 + dim / 6)) < absi(dist.get(b, 99) - (6 + dim / 6)))
	else:
		cells.sort_custom(func(a, b): return dist.get(a, 999) < dist.get(b, 999))
	for keep: int in [6, 4, 0]:
		for gap: int in [3, 2, 1]:
			var out: Array[Vector2i] = []
			for c in cells:
				if out.all(func(o): return _manhattan(o, c) >= gap) and avoid.all(func(a): return _manhattan(a, c) >= maxi(keep, 1)):
					out.append(c)
					if out.size() == count:
						return out
	var rest: Array[Vector2i] = []
	rest.assign(cells.filter(func(c): return not avoid.has(c)).slice(0, count))
	return rest


func bfs_dist(sources: Array, jump: int, fly: bool, through_trees := false) -> Dictionary:
	var dist := {}
	var q: Array = []
	for s in sources:
		dist[s] = 0
		q.append(s)
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for d in DIRS:
			var nb: Vector2i = c + d
			if dist.has(nb) or not (walkable(nb) or through_trees and _in(nb) and blocked.has(nb) and not props.has(nb)):
				continue
			if not fly and absi(h[nb] - h[c]) > jump:
				continue
			dist[nb] = dist[c] + 1
			q.append(nb)
	return dist


func pick(ray_from: Vector3, ray_dir: Vector3) -> Variant:
	## Case jouable dont la dalle est touchée en premier par le rayon.
	var best = null
	var best_t := INF
	if absf(ray_dir.y) < 0.0001:
		return null
	for x in dim:
		for z in dim:
			var c := Vector2i(x, z)
			var y := top_y(c) if kind[c] != "water" else WATER_Y
			var t := (y - ray_from.y) / ray_dir.y
			if t <= 0 or t >= best_t:
				continue
			var p := ray_from + ray_dir * t
			if absf(p.x - x) <= 0.5 and absf(p.z - z) <= 0.5:
				best_t = t
				best = c
	return best


# ------------------------------------------------------------------ rendu

func _wall_key(r: RandomNumberGenerator, k: String, lv: int, hh: int) -> String:
	## Surtout de la pierre de taille ; la brique reste minoritaire.
	var ash := r.randf() < (0.15 if biome.get("stone", "") == "brique" else 0.7)
	if lv == hh - 1:
		if k == "tower" and r.randf() < 0.5:
			return "wall_broken_%d" % r.randi_range(0, 1)
		return "ashlar_cornice_%d" % r.randi_range(0, 2) if ash else "wall_cornice_0"
	if lv == 0:
		return "ashlar_base_%d" % r.randi_range(0, 2) if ash else "wall_base_0"
	return "ashlar_plain_%d" % r.randi_range(0, 4) if ash else "wall_plain_%d" % r.randi_range(0, 1)


func build_visuals() -> void:
	for ch in get_children():
		ch.queue_free()
	var T := {}
	var fol: String = biome.foliage
	var r := RandomNumberGenerator.new()
	r.seed = rng.seed ^ 0x5eed
	var lights := 0
	for c: Vector2i in h:
		var k: String = kind[c]
		var hh: int = h[c]
		var pos := Vector3(c.x, 0, c.y)
		if k == "water" or k == "monument":
			if k == "monument":
				continue
			var roll := r.randf()
			if roll < 0.1:
				_add(T, "lily_%d" % r.randi_range(0, 1), pos + Vector3(0, WATER_Y + 0.005, 0), r.randi_range(0, 3))
			elif roll < 0.2 and fol == "autumn":
				_add(T, "float_autumn", pos + Vector3(0, WATER_Y + 0.004, 0), r.randi_range(0, 3))
			for d in DIRS:
				var nb := c + d
				if kind.get(nb, "") == "land" and h[nb] == 2 and not blocked.has(nb) and r.randf() < 0.12:
					_add_dir(T, "stairs", pos, -d)
					break
				if kind.get(nb, "") in ["land", "tower"] and r.randf() < 0.05:
					_add(T, "rubble", pos + Vector3(d.x * 0.3, WATER_Y - 0.12, d.y * 0.3), r.randi_range(0, 3))
			continue
		if k == "bridge":
			_add(T, "arch_%d" % r.randi_range(0, 1), pos, 1 if along_x[c] else 0)
			for d in DIRS:
				if kind.get(c + d, "water") == "water":
					_add_dir(T, "rail", pos + Vector3(0, top_y(c), 0), d)
		else:
			var arcaded := {}
			for lv in hh:
				for d in DIRS:
					var nb := c + d
					var nh: int = h.get(nb, 0) if kind.get(nb, "water") != "monument" else 0
					if nh > lv or (lv == 1 and arcaded.has(d)):
						continue
					if lv == 0 and hh >= 3 and nh == 0 and r.randf() < 0.45:
						arcaded[d] = true
						_add_dir(T, "wall_arcade_%d" % r.randi_range(0, 1), pos, d)
						continue
					var key := _wall_key(r, k, lv, hh)
					if lv > 0 and lv < hh - 1:
						var roll := r.randf()
						if roll < float(biome.glow_windows) * 0.35 and lights < 10 and lv >= 2:
							key = "wall_windowglow_0"
							if r.randf() < 0.5:
								_light(pos + Vector3(d.x * 0.75, lv * LH + 0.25, d.y * 0.75), Color(1.0, 0.62, 0.3), 1.4, 2.8)
								lights += 1
						elif roll < 0.08:
							key = "wall_window_0"
						elif roll < 0.14:
							key = "wall_pilaster_0"
					_add_dir(T, key, pos + Vector3(0, lv * LH, 0), d)
		var top := pos + Vector3(0, hh * LH, 0)
		var grass: bool = biome.get("top", "dalle") == "herbe" and k == "land" and not _in(c)
		_add(T, ("top_grass_%d" if grass else "top_%d") % r.randi_range(0, 2), top, r.randi_range(0, 3))
		if k == "tower":
			if biome.get("crown", "crown") == "basin":
				_add(T, "basin", top + Vector3(0, SLAB, 0), r.randi_range(0, 3))
			else:
				_add(T, "crown_%d" % r.randi_range(0, 1), top + Vector3(0, SLAB, 0), r.randi_range(0, 3))
		for d in DIRS:
			if kind.get(c + d, "water") == "water" and r.randf() < (0.3 if k != "bridge" else 0.2):
				_add_dir(T, "ivy_%s_%d" % [fol, r.randi_range(0, 1)], top, d)
		if k == "tower":
			continue
		var surf := top + Vector3(0, SLAB, 0)
		if pillars.has(c):
			_add(T, "pillar_1" if pillars[c] else "pillar_0", surf, r.randi_range(0, 3))
			# architrave vers la colonne suivante si les deux sont intactes
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var nb := c + d * 2
				if not pillars[c] and pillars.has(nb) and not pillars[nb] and kind.get(c + d, "") == "land":
					_add_free(T, "lintel", surf + Vector3(d.x, 3.06, d.y), 0.0 if d.x != 0 else PI * 0.5, 1.0)
			continue
		match blocked.get(c, ""):
			"tree":
				if live_trees and _in(c):
					continue  # arbre destructible : c'est le combat qui le pose
				var ess: String = biome.get("tree", "autumn")
				if ess == "":
					_add(T, "tufts", surf, r.randi_range(0, 3))
				elif ess == "pine":
					_add_free(T, "pine_%d" % r.randi_range(0, 1), surf, r.randf() * TAU, 0.7 if _in(c) else r.randf_range(0.9, 1.3))
				else:
					var tk := "tree_%s_small" % ess if _in(c) else "tree_%s_%d" % [ess, r.randi_range(0, 2)]
					_add_free(T, tk, surf, r.randf() * TAU, r.randf_range(0.9, 1.1))
				if r.randf() < 0.5 and not _in(c):
					_add_free(T, "bush_%s_%d" % [fol, r.randi_range(0, 1)], surf + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)), r.randf() * TAU, 0.9)
			"lantern":
				_add(T, "lantern", surf, 0)
				if lights < 14:
					_light(surf + Vector3(0, 0.8, 0), Color(1.0, 0.66, 0.34), 2.0, 4.0)
					lights += 1
			_:
				var ring_decor: Array = biome.get("ring", [])
				if not _in(c) and ring_decor.size() > 0 and r.randf() < 0.14:
					var rk: String = ring_decor[r.randi_range(0, ring_decor.size() - 1)]
					_add_free(T, rk, surf, r.randf() * TAU, r.randf_range(1.0, 1.3) if rk == "statue" else r.randf_range(0.9, 1.4))
					continue
				if not _in(c) and r.randf() < 0.25:
					_add_free(T, "bush_%s_%d" % [fol, r.randi_range(0, 1)], surf, r.randf() * TAU, r.randf_range(0.7, 1.1))
				var flora: String = biome.get("flora", "")
				# rien de plus haut qu'une cheville sur une case jouable
				if flora != "" and not _in(c) and r.randf() < (0.35 if grass else 0.15):
					_add(T, flora, surf, r.randi_range(0, 3))
				elif not grass and r.randf() < (0.25 if fol == "autumn" else 0.15):
					_add(T, "litter_" + fol, surf, r.randi_range(0, 3))
				if r.randf() < 0.05:
					_add(T, "flowers", surf, r.randi_range(0, 3))
				elif r.randf() < 0.04:
					_add(T, "rubble", surf, r.randi_range(0, 3))
	if kind.get(monument_at, "") == "monument":
		var mp := Vector3(monument_at.x, 0, monument_at.y)
		_add_dir(T, biome.get("monument", "monument"), mp, monument_face)
		var across := Vector2i(absi(monument_face.y), absi(monument_face.x))
		for k in [-1, 0, 1]:
			if r.randf() < 0.7:
				var off := Vector3(across.x * k, 0, across.y * k)
				_add_dir(T, "ivy_%s_%d" % [fol, r.randi_range(0, 1)], mp + off + Vector3(0, 5.4 - absf(k) * 1.2, 0), monument_face)
	for key in T:
		_instance(key, T[key])
	_build_seabed()
	_build_water()
	_hl = MultiMeshInstance3D.new()
	_hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hl)


func _xf(pos: Vector3, angle: float, s := 1.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, angle).scaled(Vector3.ONE * s), pos)


func _add(T: Dictionary, key: String, pos: Vector3, quarter: int) -> void:
	_add_free(T, key, pos, quarter * PI * 0.5, 1.0)


func _add_dir(T: Dictionary, key: String, pos: Vector3, d: Vector2i) -> void:
	# les modules exposent leur face détaillée vers +Z
	_add_free(T, key, pos, atan2(float(d.x), float(d.y)), 1.0)


func _add_free(T: Dictionary, key: String, pos: Vector3, angle: float, s: float) -> void:
	if not T.has(key):
		T[key] = []
	T[key].append(_xf(pos, angle, s))


func _light(pos: Vector3, col: Color, energy: float, rng_: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	l.shadow_enabled = false
	add_child(l)


func _stone(key: String) -> String:
	## Même module, dans la matière du biome (brique, lilas...) s'il en existe une version.
	var st: String = biome.get("stone", "pierre")
	if st == "pierre":
		return key
	var k := "%s/%s" % [st, key]
	return k if ResourceLoader.exists("res://assets/%s.glb" % k) else key


func _instance(key: String, xfs: Array) -> void:
	var md := mesh_of(_stone(key))
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = md[part]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = material_for(key, part == "glow")
		if part == "glow" or key.begins_with("lily") or key.begins_with("litter") or key.begins_with("flowers") or key.begins_with("float"):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


static func material_for(key: String, glow: bool) -> Material:
	if glow:
		return material("glow")
	if key.begins_with("tree") or key.begins_with("bush") or key.begins_with("ivy") or key.begins_with("pine") or key.begins_with("fireweed"):
		return material("foliage")
	if key.begins_with("lily") or key.begins_with("litter") or key.begins_with("flowers") or key.begins_with("float") or key.begins_with("tufts") or key.begins_with("top_grass"):
		return material("flat")
	return material("stone")


static func mesh_of(key: String) -> Dictionary:
	var ck := ("hd/" + key) if hd else key
	if _meshes.has(ck):
		return _meshes[ck]
	var md := {"mesh": null, "glow": null}
	var path := ""
	for k in ([key, key.get_file()] if key.contains("/") else [key]):
		for dir in (["hd/", ""] if hd else [""]):
			if path == "" and ResourceLoader.exists("res://assets/%s%s.glb" % [dir, k]):
				path = "res://assets/%s%s.glb" % [dir, k]
	var ps: PackedScene = load(path)
	var inst := ps.instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).ends_with("_glow"):
			md.glow = mi.mesh
		else:
			md.mesh = mi.mesh
	inst.free()
	_meshes[ck] = md
	return md


static func material(kind_: String) -> Material:
	if _mats.has(kind_):
		if kind_ == "foliage":
			(_mats[kind_] as ShaderMaterial).set_shader_parameter("sway", 0.0 if Fx.lite else 1.0)
		return _mats[kind_]
	var m := ShaderMaterial.new()
	if kind_ == "glow" or kind_ == "glow_unit":
		m.shader = load("res://shaders/glow.gdshader")
		if kind_ == "glow_unit":
			m.set_shader_parameter("energy", 4.5)
			m.set_shader_parameter("pulse", 0.4)
			m.set_shader_parameter("cut", 0.0)
	else:
		m.shader = load("res://shaders/voxel.gdshader")
		if kind_ == "foliage":
			m.set_shader_parameter("sway", 0.0 if Fx.lite else 1.0)  # pas de vent en mode portable
			m.set_shader_parameter("backlight", 0.55)
		elif kind_ == "flat":
			m.set_shader_parameter("backlight", 0.2)
		elif kind_ == "unit" or kind_ == "prop":
			m.set_shader_parameter("cut", 0.0)
		if kind_ == "stone":
			m.set_shader_parameter("moss", 1.0)
	_mats[kind_] = m
	return m


func _build_seabed() -> void:
	## Un seul fond de sable jusqu'à l'horizon : pas de bord de dalle visible sous l'eau.
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	var bed := MeshInstance3D.new()
	bed.mesh = pm
	bed.position = Vector3(dim * 0.5 - 0.5, -0.6, dim * 0.5 - 0.5)
	var m := StandardMaterial3D.new()
	var nz := FastNoiseLite.new()
	nz.frequency = 0.08
	var t := NoiseTexture2D.new()
	t.noise = nz
	t.seamless = true
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#9c9278"), Color("#cfc4a2")])
	t.color_ramp = g
	m.albedo_texture = t
	m.uv1_scale = Vector3(60, 60, 1)
	m.roughness = 1.0
	bed.material_override = m
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bed)


func _build_water() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)  # lac jusqu'à l'horizon
	_water = MeshInstance3D.new()
	_water.mesh = pm
	_water.position = Vector3(dim * 0.5 - 0.5, WATER_Y, dim * 0.5 - 0.5)
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/water.gdshader")
	m.set_shader_parameter("normal_a", _normal_tex(3))
	m.set_shader_parameter("normal_b", _normal_tex(11))
	# l'eau reste de la famille turquoise quel que soit le ciel
	m.set_shader_parameter("shallow", (biome.water_shallow as Color).lerp(Color(0.2, 0.8, 0.74), 0.6))
	m.set_shader_parameter("deep", (biome.water_deep as Color).lerp(Color(0.02, 0.32, 0.36), 0.6))
	m.set_shader_parameter("sky", (biome.sky_hor as Color).lerp(Color(0.62, 0.88, 0.86), 0.5))
	_water.material_override = m
	add_child(_water)


static func _normal_tex(seed: int) -> NoiseTexture2D:
	var key := "n%d" % seed
	if _mats.has(key):
		return _mats[key]
	var nz := FastNoiseLite.new()
	nz.seed = seed
	nz.frequency = 0.02
	nz.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = 6.0
	t.noise = nz
	_mats[key] = t
	return t


# ------------------------------------------------------------------ surbrillance

func highlight(cells: Dictionary) -> void:
	## cells : Vector2i -> Color ; alpha < 0.5 = contour seul, sinon case pleine
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(0.96, 0.96)
	q.orientation = PlaneMesh.FACE_Y
	mm.mesh = q
	mm.instance_count = cells.size()
	var i := 0
	for c in cells:
		var y := top_y(c) + 0.02 if kind[c] != "water" else WATER_Y + 0.02
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x, y, c.y)))
		mm.set_instance_color(i, cells[c])
		i += 1
	_hl.multimesh = mm
	if _hl.material_override == null:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/tile.gdshader")
		_hl.material_override = m
