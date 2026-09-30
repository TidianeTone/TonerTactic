class_name Battle
extends Node
## Un combat : pioche, main, énergie, cartes, déplacement libre, objets du décor,
## passifs d'équipement (à la FFTA), IA ennemie.

signal ended(victory: bool)
signal changed
signal coach(evt: String, info)  # initiation : ce que fait le joueur, pour que main.gd commente

const EMBER := Color(1.0, 0.55, 0.22)
const DMG_COL := Color(1.0, 0.93, 0.7)

var main: Node3D
var log_lines: Array = []   # journal du combat, affiché à gauche
var danger := false         # zone de danger : tout ce que les ennemis menacent
var _extra_move := {}       # héros qui ont déjà payé leur course (3 mana) ce tour
var glyph_t := {}           # glyphe instable -> tours avant l'explosion
var glyph_lbl := {}
var bombs := {}              # bombe à retardement : case -> {n: rounds avant l'explosion, dmg, lbl}
var orienting := false      # fin du tour à la FFT : le héros choisit où il regarde
var _faced := false        # le joueur a tourné le héros actif depuis sa dernière action (sinon : vers l'ennemi le plus proche en fin de tour)
var _move_plan = null       # déplacement en deux clics : la case visée au premier clic
var _orient_from := Vector2i.ZERO
var _orient_mark: Label3D    # flèche dorée sur la case regardée, visible à travers le décor
var board: Board
var units_root: Node3D
var heroes: Array = []
var foes: Array = []
var allies: Array = []      # compagnons : des bêtes apprivoisées qui jouent seules, du côté des héros
var deck: Array = []
var relics: Array = []
var draw_pile: Array = []
var discard: Array = []
var played_turn: Array = []
var _turns_of := {}  # tours joués par chaque héros ce combat (Grimoire humide : les deux premiers)  # cartes jouées par le héros actif ce tour (affichées près de l'orbe)
var exhausted: Array = []
var hand: Array = []
var energy := 3
var bonus_energy := 0
var turn := 0
var busy := false
var player_turn := false
var over := false
var first_free := false
var selected: Unit
var card_sel := -1
var prop_nodes := {}      # Vector2i -> Node3D
var _eco_used := {}       # héros -> vrai si Demi-coût déjà servi ce tour
var _elan_used := {}
var champions := 0          # nombre d'ennemis rares (réglé par la run)
var objective := "kill"     # "kill" | "portal"
var rng := RandomNumberGenerator.new()
var _portal_node: Node3D
var inspect: Unit           # unité dont la fiche est épinglée
var powers: Array = []      # pouvoirs actifs jusqu'à la fin du combat
var traps := {}             # case -> nœud du piège
var turrets := {}           # case -> {turns, dmg}
var trap_dmg := {}          # case -> dégâts du piège
var echo := false           # la prochaine carte agit deux fois
var played := 0             # cartes jouées ce tour
var voices: Array = []      # voix (bleu, rouge, noir) jouées ce tour par Tidiane
var _killed := false        # la carte en cours a tué
var _struck: Unit = null    # unité frappée par la carte en cours (déclencheurs : elle a pu être repoussée)
static var foe_mult := 1.0  # dégâts ennemis selon l'étage
static var foe_bonus := 0   # dégâts ennemis en plus (Enragés, Rage)
var mods: Array = []        # modificateurs de la salle et des pactes
var hand_size := 4            # cartes piochées par tour de héros
static var foe_hp := 1.8      # PV des ennemis : chaque héros joue son propre tour
var active: Unit              # héros dont c'est le tour (null pendant un ennemi)
var order: Array = []         # ordre du round, par vitesse
var qi := -1                  # position dans l'ordre
var piles := {}               # héros -> {draw, discard, exhausted} : chacun son paquet
var _first_turn := {}         # héros -> a déjà joué (Ambre du Gué)
var power_val := {}           # pouvoir -> force, selon le niveau de la carte
var bonus := {}               # héros -> énergie en plus à son prochain tour
var sim := {}               # compteurs de simulation (auto-jeu) : objets joués, arbres, explosions, percées
var spent: Array = []       # objets sans charge : quittent le paquet en fin de combat
var won_objs: Array = []    # objets volés ou ramassés ce combat (revendables au butin)
var brasero_aura := {}      # case -> brûlure du brasero posé par une carte, en fin de manche
var oriel_turn := false     # Dame Oriel : premier objet du tour déjà doublée
var fourgue_turn := false   # Le Fourgue : soin sur vol, une fois par tour
var _alambic := false       # Alambic : Fabrique 1 au premier tour d'un héros
var _double_fond := false   # Lettre de recommandation : une Embauche au premier tour du combat
var tool_rate := 0.3        # part des ennemis qui portent un objet
var smoke := {}             # case -> tours de fumée restants
var smoke_nodes := {}
var trap_kind := {}         # case -> "piege" | "picots"
var picot_root := {}        # case -> tours d'entrave des picots (Ronces d'acier)
var tiles := {}             # case -> rune au sol (Data.TILES)
var ground_nodes := {}      # case -> plaque de sol
var _ground_mat := {}
var ground := {}            # case -> matière du sol (Data.GROUND) : glace, vase, par biome
var twins := {}             # portail -> portail jumeau
var tile_nodes: Array = []
var oaks := {}              # case -> arbre (décor ou planté) : nœud 3D
var tree_hp := {}           # case -> PV de l'arbre ; tout arbre se coupe
var oak_arm := {}           # case -> écorce du chêne (retirée de chaque coup)
var oak_aura := {}          # case -> armure donnée aux héros voisins à leur tour (0 pour un arbre du décor)
var oak_fp := {}            # case -> le feu ne le consume pas (8 dégâts à la place)
var oak_max := {}           # case -> PV de départ (barre de vie)
var smolder := {}           # case -> l'arbre couve : il flambe au round suivant (nœud de la flamme)
var loot := {}              # case -> [objet, nœud] lâché par un ennemi
var _blast := false         # les dégâts en cours viennent d'une explosion
var _lifesteal := false     # la carte en cours porte « Vol de vie » (enchantement)
# multiclasse : cartes de guilde
var power_owner := {}       # pouvoir -> héros qui l'a joué
var booms := 0              # barils sautés ce tour (Poudre, 174 BPM)
var hurt_turn := false      # un héros a perdu des PV ce tour (Blessure)
var stolen_turn := 0        # objets volés ce tour (Filière)
var played_ids := {}        # héros -> cartes jouées ce combat (Grand Journal)
var played_lvl := {}        # héros -> {carte: plus haut niveau joué} (Grand Journal niveau 3)
var item_poison := 0        # Lame enduite
var fiole2 := false         # Alchimie
var trophy := false         # Trophée
var double_trap := false    # Rabatteur : le piège frappe deux fois
var pending_relics := 0     # Découpe : reliques à choisir après le combat
var elite_fight := false
var suien_hits := 0
var plume_used := false
var masque_used := false
var _pre := false           # déclencheur évalué avant la résolution de la carte en cours
var _resolving := false
var crash_bonus := 0        # Choc : dégâts de collision en plus pour la poussée en cours
var used_turn := 0          # objets utilisés ou détruits ce tour (Casse et Revente)
var sold_gold := 0          # or de revente de ce combat (30 au plus)
var last_exhausted := {}    # héros -> dernière carte épuisée jouée (Flashback)
var curee_turn := 0
var drawn_turn := 0         # cartes piochées ce tour hors début de tour (Ouï-dire)
var nyxa_turn := 0          # Murmures soufflés ce tour (Nyxa)
var heal_turn := false      # un héros a regagné des PV ce tour (Regain)
var omens := {}             # case -> {dmg, owner, node} : Présage
var exhaust_n := {}         # héros -> cartes épuisées ce combat
var item_echo: Unit         # le prochain objet doublable de ce héros agit deux fois
var traps_fired := 0        # pièges déclenchés ce combat (Déclic)
const DOUBLABLE := ["fiole", "carnet", "elixir", "sels", "sablier", "filet", "bombe", "fumigene"]
var tambour := 0            # cartes jouées ce combat (Tambour 174)
var _overload := false
var _start_draw := false
var _enclume_q: Array = []
var foe_omens: Array = []     # attaques différées des ennemis : {kind, cells, owner, cell, dir, dmg, nodes}
var _dot := false             # dégâts de poison en cours : ni interception ni amarre
var _last_ranged := false     # le coup qui tue venait de loin (Moussu lesté)
var _pulling := false         # attraction par un héros (tire le Noyé ancien hors de l'eau)
# reliques : drapeaux par combat ou par tour
var _terrain := false         # dégâts de terrain (Choc, noyade, piège, baril, pilier) : indexés sur l'étage
var _terrain_mark := -1       # -1 : lire la Marque de la cible ; 0/1 : figée à l'entrée du piège
var _choc := false            # les dégâts en cours viennent d'un Choc (Denier du fossoyeur)
var _tuile := false           # Tuile Brisée : premier Choc du combat déjà servi
var _ecusson := false         # Écusson : déjà servi ce combat
var _echo_cav := false        # Écho de caverne : première attaque du combat déjà doublée
var _soufflet := false        # Soufflet de forge : une fois par tour
var _souffle := false         # Souffle du canonnier : pas de poussée en chaîne
var _remous := false          # Remous : une noyade causée par Remous n'en relance pas
var _hits_turn := 0           # coups portés par le héros actif ce tour (Corde à nœuds)
const SPRINT_COL := Color(1.0, 0.6, 0.12, 0.6)  # cases de course : un deuxième déplacement pour 3 mana
const OMEN_COL := Color(1.0, 0.42, 0.18, 0.85)  # un seul télégraphe rouge-ambre pour tout ce qui arrive au prochain round
const IDLE_AI := ["dancer", "spawner", "totem", "tether", "flood", "pilori"]
const TRAP_KINDS := ["piege", "mine", "epieu", "ombre", "collet"]
const BOOM := ["brasero", "baril"]
const USABLE := ["coffre", "ratelier", "vasque", "cloche"]  # au contact : un héros (et, pour vasque et cloche, un ennemi) s'en sert
const RING8: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


func log_add(t: String) -> void:
	log_lines.append(t)
	if log_lines.size() > 60:
		log_lines.pop_front()
	main.ui.refresh_log()


func has(relic: String) -> bool:
	return relics.has(relic)


func _gold(n: int, at: Vector3) -> void:
	## L'or d'une relique, gagné en plein combat.
	main.gold += n
	main.ui.set_gold(main.gold)
	Fx.number(main, at + Vector3(0, 1.3, 0), "+%d or" % n, GOLD_FX)


func _bpm_hero(h: Unit) -> bool:
	## Tidiane, de classe ou de vocation : le seul dont le BPM compte (et s'affiche).
	return h.key == "tidiane" or h.voc == "tidiane" or h.voc2 == "tidiane"


func start(hs: Array, foe_ids: Array, deck_ref: Array, relics_ref: Array) -> void:
	heroes = hs
	deck = deck_ref
	relics = relics_ref
	main.ui.set_challenge("")
	for f in foes + _gone:
		if is_instance_valid(f):
			f.queue_free()
	foes.clear()
	_gone.clear()
	over = false
	turn = 0
	card_sel = -1
	selected = null
	inspect = null
	powers.clear()
	for n in traps.values():
		n.queue_free()
	traps.clear()
	trap_kind.clear()
	for d in [smoke_nodes, oaks]:
		for n in d.values():
			n.queue_free()
		d.clear()
	for n in smolder.values():
		if is_instance_valid(n):
			n.queue_free()
	for dd in [tree_hp, oak_arm, oak_aura, oak_fp, oak_max, smolder]:
		dd.clear()
	smoke.clear()
	for e in loot.values():
		e[1].queue_free()
	loot.clear()
	spent.clear()
	won_objs.clear()
	brasero_aura.clear()
	sim.clear()
	turrets.clear()
	bombs.clear()
	echo = false
	bonus_energy = 0
	_elan_used.clear()
	tambour = 0
	sold_gold = 0
	last_exhausted.clear()
	exhaust_n.clear()
	traps_fired = 0
	item_echo = null
	for o in omens.values():
		if o.node:
			o.node.queue_free()
	omens.clear()
	for om in foe_omens:
		for n in om.nodes:
			if is_instance_valid(n):
				n.queue_free()
	foe_omens.clear()
	for h1 in heroes:
		for mk in ["chained", "englue", "root_round", "hit_round", "meute", "zoc_hit"]:
			if h1.has_meta(mk):
				h1.remove_meta(mk)
	for h0 in heroes:
		h0.trap_seen = 0
		h0.blastproof = false
	var center := Vector2i(board.dim / 2, board.dim / 2)
	var hc := board.spawn_cells("hero", heroes.size())
	for i in heroes.size():
		var h: Unit = heroes[i]
		h.apply_gear()
		h.place(hc[i], board)
		h.face(center - h.cell)
		h.block = 6 if has("ecaille") and not has("machoire_ogre") else 0
		h.poison = 0
		h.taunt = false
		h.reset_fight()
		h.aegis = has("plaque_vanne") and not has("machoire_ogre")
		if has("diapason") and _bpm_hero(h):
			h.bpm = 2
		h.set_selected(false)
	_tuile = false
	_ecusson = false
	_echo_cav = false
	for a in allies:
		a.queue_free()
	allies.clear()
	var pet: String = main.companion
	if pet == "" and has("sifflet"):
		pet = Data.COMPANIONS.keys()[rng.randi_range(0, Data.COMPANIONS.size() - 1)]  # Sifflet d'os : une bête répond pour ce combat
	if pet != "":
		var ac := board.spawn_cells("hero", heroes.size() + 1)
		var a := Unit.new()
		a.setup(pet, "foe")
		a.side = "hero"
		a.companion = true
		a.nm = Data.COMPANIONS[pet].name
		a.max_hp = int(Data.COMPANIONS[pet].hp * (1.5 if has("collier") else 1.0))
		a.hp = a.max_hp
		units_root.add_child(a)
		a.ring_color(Color(0.55, 1.0, 0.7))
		a.place(ac[ac.size() - 1], board)
		a.face(center - a.cell)
		allies.append(a)
		hc.append(a.cell)
	var fc := board.spawn_cells("foe", foe_ids.size(), hc)
	for i in foe_ids.size():
		var u := spawn_foe(foe_ids[i], fc[i])
		u.face(center - u.cell)
	for f in foes:
		_place_special(f)
	_boss_terrain()
	var pool: Array = foes.filter(func(f): return not f.data.get("no_champion", false) and not f.data.get("structure", false))
	for i in mini(champions, pool.size()):
		var f: Unit = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(f)
		f.make_champion(Data.AFFIXES.keys()[rng.randi_range(0, Data.AFFIXES.size() - 1)])
	var carriers: Array = foes.filter(func(f): return not f.data.get("no_champion", false) and not f.data.get("structure", false))
	if carriers.size() > 0 and (rng.randf() < (1.0 if has("registre_prevot") else 0.3) or main.args.has("porteur")) and not main.tuto:
		var cf: Unit = carriers[rng.randi_range(0, carriers.size() - 1)]
		cf.card_id = main._card_roll(2)
		cf.card_cond = Data.CARD_CONDS.keys()[rng.randi_range(0, Data.CARD_CONDS.size() - 1)]
		if Data.CARD_CONDS.has(str(main.args.get("porteur", ""))):
			cf.card_cond = main.args.porteur  # test : -- --porteur=fuite
		_card_mark(cf)
	# plancher d'équipement par étage : l'acte 2 et l'acte 3 ne commencent pas nus
	var gear_rate: float = maxf(clampf(0.08 * (main.fights - 1), 0.0, 0.45) if main.fights >= 2 else 0.0, Data.FOE_GEAR_FLOOR[clampi(main.floor_i, 1, 3) - 1])
	if main.tuto:
		gear_rate = 0.0
	for f in foes:
		if not f.data.get("no_champion", false) and not f.data.get("structure", false) and rng.randf() < gear_rate:
			_equip_foe(f)
	for f in foes:
		if not f.data.get("no_champion", false) and not f.data.get("structure", false) and (f.affix != "" or rng.randf() < tool_rate):
			f.tool = Data.FOE_TOOLS[rng.randi_range(0, Data.FOE_TOOLS.size() - 1)]
	spawn_props()
	_place_tiles()
	_place_ground()
	_alambic = has("alambic")
	_double_fond = false
	if mods.has("hate"):
		for f in foes:
			f.move += 1
	if mods.has("poudriere"):
		var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c))
		free.shuffle()
		for i in mini(4, free.size()):
			board.props[free[i]] = "baril"
			_make_prop(free[i])
	if has("baril_contrebande"):
		_keg_near(foes)
	if has("coeur_fournaise"):
		_keg_near(heroes)
	if has("couteau_palette"):
		for h in heroes:
			if not tiles.has(h.cell):
				tiles[h.cell] = ["force", "garde", "elan"][rng.randi_range(0, 2)]
				_make_tile(h.cell, tiles[h.cell])
	if has("craie_arpenteur") and foes.size() > 0:
		var big: Unit = foes.reduce(func(a, b): return b if b.max_hp > a.max_hp else a)  # à égalité, le premier
		big.mark = maxi(big.mark, 2)
	piles.clear()
	log_lines.clear()
	for ci in deck:
		for k in ["bump", "free", "cut", "rch"]:
			ci.erase(k)
	for ci in deck:
		var cls: Array = Data.classes_of(ci.id)
		if ci.has("h") and cls.size() == 1 and cls[0] != ci.h:
			var ok: Array = heroes.filter(func(u): return u.key == cls[0] or u.voc == cls[0] or u.voc2 == cls[0])
			if ok.size() > 1:
				ci["h"] = ok[rng.randi_range(0, ok.size() - 1)].key  # tirée au sort à chaque combat
	for h in heroes:
		var d: Array = deck.filter(func(ci): return Data.holder(ci) == h.key)
		d.shuffle()
		if has("encrier"):
			# Encrier de relieur : jusqu'à 2 cartes enchantées remontent en haut de la pioche (on pioche par la fin)
			var en: Array = d.filter(func(ci): return ci.has("ench"))
			en.shuffle()
			for ci in en.slice(0, 2):
				d.erase(ci)
				d.append(ci)
		piles[h] ={"draw": d, "discard": [], "exhausted": [], "keep": []}
	power_owner.clear()
	played_ids.clear()
	played_lvl.clear()
	item_poison = 0
	fiole2 = false
	trophy = false
	pending_relics = 0
	suien_hits = 0
	oriel_turn = false
	_enclume_q.clear()
	draw_pile = []
	discard = []
	exhausted = []
	hand = []
	power_val.clear()
	bonus.clear()
	_first_turn.clear()
	_turns_of.clear()
	trap_dmg.clear()
	active = null
	order = []
	qi = -1
	if main.tuto:
		main._tuto_setup()
	_next_round()


func spawn_foe(id: String, c: Vector2i) -> Unit:
	var u := Unit.new()
	u.setup(id, "foe")
	u.max_hp = int(round(u.max_hp * foe_hp))
	u.hp = u.max_hp
	if main.floor_i >= 3 and id in ["mage", "wisp"]:
		u.set_meta("maree" if id == "mage" else "couvant", true)  # versions de l'acte 3
	units_root.add_child(u)
	u.place(c, board)
	foes.append(u)
	main.bestiary_see(id)
	return u


func _place_special(f: Unit) -> void:
	## Placement selon le rôle : structures à l'écart, Fanal au cœur des siens, treuils derrière Grelin,
	## Frondeur perché, Anguille dans l'eau.
	if f.data.get("near_foes", false):
		var others: Array = foes.filter(func(o): return o != f and not o.data.get("structure", false))
		if others.size() > 0:
			var bc := Vector2.ZERO
			for o in others:
				bc += Vector2(o.cell)
			bc /= others.size()
			_relocate(f, func(c): return -Vector2(c).distance_to(bc) + (0.5 if board.h[c] >= 1 else 0.0) - (99.0 if _hero_dist(c) < 4 else 0.0))
			return
	if f.key == "treuil":
		var g: Array = foes.filter(func(o): return o.key == "grelin")
		if g.size() > 0:
			var gc: Vector2i = g[0].cell
			_relocate(f, func(c): return (-99.0 if dist(c, gc) < 5 or dist(c, gc) > 7 else 0.0) + _hero_dist(c) * 0.5 - absi(dist(c, gc) - 6))
			return
	if f.data.get("structure", false):
		_isolate(f)
	elif f.data.get("perche", false):
		var from := f.cell
		_relocate(f, func(c): return (-99.0 if board.h[c] < 2 or _hero_dist(c) < 5 else 0.0) - dist(c, from) * 0.3 + board.h[c])
	elif f.data.get("water_only", false):
		var from2 := f.cell
		_relocate(f, func(c): return -dist(c, from2) - (99.0 if _hero_dist(c) < 4 else 0.0), true)


func _boss_terrain() -> void:
	## Le terrain que réclament les boss de crue : des arbres au bord de l'eau (Chevrier), des haies (Brûle-Haie).
	var keys: Array = foes.map(func(o): return o.key)
	if keys.has("chevrier"):
		var banks: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c) and _hero_dist(c) >= 2 \
				and Board.DIRS.any(func(d): return board.kind.get(c + d, "") == "water" and board._in(c + d)))
		banks.shuffle()
		var n := 0
		for c in banks:
			if n >= 6 or oaks.keys().any(func(o): return dist(o, c) < 3):
				continue
			_plant(c, 10, 0, 0, false, false)
			n += 1
	if keys.has("brule_haie"):
		var hc := Vector2.ZERO
		var fc := Vector2.ZERO
		for h in heroes:
			hc += Vector2(h.cell)
		for o in foes:
			fc += Vector2(o.cell)
		hc /= maxi(1, heroes.size())
		fc /= maxi(1, foes.size())
		var ax := Vector2i(signi(int(fc.x - hc.x)), 0) if absf(fc.x - hc.x) >= absf(fc.y - hc.y) else Vector2i(0, signi(int(fc.y - hc.y)))
		var side := Vector2i(ax.y, ax.x)
		var n := 0
		for k in [4, 7]:  # deux haies en travers, entre l'escouade et lui : le feu court le long d'une ligne
			var mid: Vector2i = Vector2i(roundi(hc.x), roundi(hc.y)) + ax * k
			for j in range(-6, 7):
				var c: Vector2i = mid + side * j
				if n < 16 and board.walkable(c) and unit_at(c) == null and not board.props.has(c) and not oaks.has(c):
					_plant(c, 10, 0, 0, false, false)
					n += 1


func _relocate(f: Unit, score: Callable, water := false) -> void:
	## Déplace f sur la case libre de meilleur score (score < -50 : exclue).
	var best := f.cell
	var bs := -INF
	for c: Vector2i in board.h:
		var ok: bool = board.kind[c] == "water" if water else board.walkable(c)
		if not ok or (unit_at(c) != null and unit_at(c) != f):
			continue
		var s: float = score.call(c)
		if s > -50.0 and s > bs:
			bs = s
			best = c
	f.place(best, board)


func _isolate(f: Unit) -> void:
	## Une structure se place loin des autres ennemis, à 6-11 cases des héros : il faut aller la chercher.
	var best := f.cell
	var bs := -INF
	var ok := _walk_reach(1)  # accessible à pied même pour un héros qui ne saute que d'un niveau
	for c in board.walkable_cells():
		if unit_at(c) != null or board.props.has(c) or not ok.has(c):
			continue
		var dh := _hero_dist(c)
		if dh < 6 or dh > 11:
			continue
		var df := 99
		for o in foes:
			if o != f:
				df = mini(df, dist(o.cell, c))
		var s := df * 2.0 - absi(dh - 8)
		if s > bs:
			bs = s
			best = c
	if bs == -INF:
		for c in ok:  # arène étroite : la case accessible la plus lointaine
			if unit_at(c) == null and not board.props.has(c) and (bs == -INF or _hero_dist(c) > bs):
				bs = _hero_dist(c)
				best = c
	f.place(best, board)


func _walk_reach(jump: int) -> Dictionary:
	## Cases atteignables à pied depuis les héros avec ce saut (sans eau, unités ignorées).
	var seen := {}
	var q: Array = alive_heroes().map(func(h): return h.cell)
	for c in q:
		seen[c] = true
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for d in Board.DIRS:
			var n: Vector2i = c + d
			if not seen.has(n) and board.walkable(n) and absi(board.h[n] - board.h[c]) <= jump:
				seen[n] = true
				q.append(n)
	return seen


func alive_heroes() -> Array:
	return heroes.filter(func(u): return u.alive) + allies.filter(func(u): return u.alive)


func alive_foes() -> Array:
	return foes.filter(func(u): return u.alive)


func unit_at(c: Vector2i) -> Unit:
	for u in heroes + allies:
		if u.alive and u.cell == c:
			return u
	for u in foes:
		if u.alive and u.cell == c:
			return u
	return null


func owner_of(c: Dictionary) -> Unit:
	for h in heroes:
		if h.key == c.owner:
			return h
	return null


static func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# ------------------------------------------------------------------ objets du décor

func spawn_props() -> void:
	for n in prop_nodes.values():
		n.queue_free()
	prop_nodes.clear()
	# test : --prop=vasque (cloche, ratelier) le pose au plus près du centre ; Colonne volée : un pilier
	var extra: Array = [main.args.prop] if main.args.has("prop") and not board.props.values().has(main.args.prop) else []
	if has("colonne_volee"):
		extra.append("pilier")
	for k in extra:
		var mid := Vector2i(board.dim / 2, board.dim / 2)
		var land: Array = board.walkable_cells().filter(func(c): return not board.props.has(c) and board.kind.get(c, "") == "land" and unit_at(c) == null)
		land.sort_custom(func(a, b): return dist(a, mid) < dist(b, mid))
		if land.size() > 0:
			board.props[land[0]] = k
	for c in board.props:
		_make_prop(c)
	# les arbres du plateau deviennent destructibles (10 PV)
	for c in board.blocked.keys():
		if board.blocked[c] == "tree" and board._in(c) and not oaks.has(c):
			_plant(c, 10, 0, 0, false, false)
	if _portal_node:
		_portal_node.queue_free()
		_portal_node = null
	if objective == "portal":
		board.place_portal()
		_portal_node = Node3D.new()
		var md := Board.mesh_of("portal")
		for part in ["mesh", "glow"]:
			var mi := MeshInstance3D.new()
			mi.mesh = md[part]
			mi.material_override = Board.material("glow" if part == "glow" else "prop")
			_portal_node.add_child(mi)
		var l := OmniLight3D.new()
		l.light_color = Color(0.55, 0.9, 1.0)
		l.light_energy = 2.5
		l.omni_range = 4.0
		l.position.y = 0.8
		_portal_node.add_child(l)
		_portal_node.position = board.world(board.portal) - Vector3(0, Board.SLAB, 0)
		units_root.add_child(_portal_node)


func _check_portal(h: Unit) -> void:
	if objective == "portal" and h.alive and h.cell == board.portal and not over:
		over = true
		player_turn = false
		main.ui.banner("Sortie atteinte", "Le groupe franchit le portail")
		_finish(true)


func _make_prop(c: Vector2i) -> void:
	var node := Node3D.new()
	var md := Board.mesh_of("prop_" + ("baril" if board.props[c] == "bombe_retard" else board.props[c]))
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material("glow" if part == "glow" else "prop")
		node.add_child(mi)
	node.position = board.world(c)
	node.rotation.y = randi_range(0, 3) * PI * 0.5
	var mk: Array = {"coffre": ["◆", Color(1.0, 0.85, 0.35)],
		"brasero": ["✹", Color(1.0, 0.55, 0.2)], "baril": ["✹", Color(1.0, 0.55, 0.2)], "pilier": ["⚠", Color(0.95, 0.9, 0.8)],
		"ratelier": ["⚔", Color(0.85, 0.9, 1.0)], "vasque": ["♥", Color(0.45, 0.95, 0.85)], "cloche": ["♫", Color(1.0, 0.8, 0.4)]}.get(board.props[c], [])
	if mk.size() > 0:
		var l3 := Label3D.new()
		l3.text = mk[0]
		l3.font = Fx.title_font()
		l3.font_size = 72
		l3.pixel_size = 0.0042
		l3.visible = false
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.no_depth_test = true
		l3.modulate = mk[1]
		l3.outline_size = 16
		l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
		l3.position.y = 1.45
		node.add_child(l3)
		node.set_meta("mark", l3)
		var tw := l3.create_tween().set_loops()
		tw.tween_property(l3, "position:y", 1.65, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(l3, "position:y", 1.45, 0.9).set_trans(Tween.TRANS_SINE)
	if board.props[c] == "bombe_retard":
		node.scale = Vector3.ONE * 0.6  # un petit baril cerclé de rouge, son compte à rebours au-dessus
		var cd := Label3D.new()
		cd.text = "2"
		cd.font = Fx.title_font()
		cd.font_size = 110
		cd.pixel_size = 0.009
		cd.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cd.no_depth_test = true
		cd.render_priority = 10
		cd.modulate = Color(1.0, 0.3, 0.2)
		cd.outline_size = 18
		cd.outline_modulate = Color(0.05, 0.02, 0.02, 0.9)
		cd.position.y = 1.9
		node.add_child(cd)
		node.set_meta("count", cd)
		var bl := OmniLight3D.new()
		bl.light_color = Color(1.0, 0.25, 0.15)
		bl.light_energy = 1.2
		bl.omni_range = 1.6
		bl.position.y = 0.8
		node.add_child(bl)
	if board.props[c] == "brasero":
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.25)
		l.light_energy = 1.6
		l.omni_range = 3.0
		l.position.y = 0.7
		node.add_child(l)
	units_root.add_child(node)
	prop_nodes[c] = node


func _remove_prop(c: Vector2i) -> void:
	board.props.erase(c)
	var node: Node3D = prop_nodes.get(c)
	prop_nodes.erase(c)
	if node:
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(1.2, 0.05, 1.2), 0.25)
		tw.tween_callback(node.queue_free)


func _keg_near(us: Array) -> void:
	## Un baril sur une case libre au contact d'une unité tirée au sort (Baril de contrebande, Cœur de fournaise).
	var pool: Array = us.filter(func(u): return u.alive and not u.data.get("structure", false))
	pool.shuffle()
	for u in pool:
		for d in Board.DIRS:
			var c: Vector2i = u.cell + d
			if board.walkable(c) and unit_at(c) == null and not board.props.has(c) and not traps.has(c):
				board.props[c] = "baril"
				_make_prop(c)
				return


func _drink(u: Unit, c: Vector2i) -> void:
	## Vasque : le premier qui y boit, héros ou ennemi, reprend 40 % de ses PV max. Elle se vide.
	_remove_prop(c)
	Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), Color(0.45, 0.95, 0.85), 40, 3.0, 5.0)
	heal(u, ceili(u.max_hp * 0.4 * (1.5 if u.side == "hero" and has("gobelet") else 1.0)))
	log_add("%s boit à la vasque" % u.nm)


func _foe_prop(f: Unit, R: Dictionary) -> bool:
	## Vasque et cloche servent aussi aux ennemis : un blessé va boire ; un ennemi libre (aucun héros à 2 cases) va sonner l'alarme.
	if f.data.get("structure", false) or f.data.ai in IDLE_AI:
		return false
	for pc in board.props.keys():
		var k: String = board.props[pc]
		if not ((k == "vasque" and f.hp * 5 < f.max_hp * 3) or (k == "cloche" and not alive_heroes().any(func(h): return dist(h.cell, f.cell) <= 2))):
			continue
		var best = null
		for cell in R.cells:
			if dist(cell, pc) == 1 and absi(board.h[cell] - board.h[pc]) <= 2 and (cell == f.cell or unit_at(cell) == null) and (best == null or R.dist[cell] < R.dist[best]):
				best = cell
		if best == null:
			continue
		if best != f.cell:
			await _foe_walk(f, path_to(R.prev, best))
		if not f.alive or over or not board.props.has(pc):
			return true
		f.face(pc - f.cell)
		await f.cast()
		if k == "vasque":
			_drink(f, pc)
		else:
			_remove_prop(pc)
			main.shake(0.4)
			Fx.number(main, board.world(pc) + Vector3(0, 1.6, 0), "Alarme !", EMBER, true)
			var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c) and not alive_heroes().any(func(h): return dist(h.cell, c) <= 1))
			free.sort_custom(func(a, b): return dist(a, pc) < dist(b, pc))
			var pool: Array = Data.EXTRAS[clampi(main.floor_i, 1, 3)]
			for i in mini(2, free.size()):
				var u := spawn_foe(pool[randi() % pool.size()], free[i])
				u.face(pc - u.cell)
				Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
			await wait(0.5)
		return true
	return false


func _open_chest(h: Unit, c: Vector2i) -> void:
	_remove_prop(c)
	Fx.burst(main, board.world(c) + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.4), 50, 3.0, 6.0)
	if has("passe_partout"):
		_gold(10, board.world(c))
	await main.open_chest(h)
	coach.emit("coffre", h)


func interact(h: Unit, c: Vector2i) -> void:
	var k: String = board.props[c]
	busy = true
	h.face(c - h.cell)
	await h.cast()
	match k:
		"coffre":
			await _open_chest(h, c)
			busy = false
			changed.emit()
			return  # ouvrir un coffre au contact est gratuit : le déplacement reste
		"ratelier":
			_remove_prop(c)
			Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), Color(0.85, 0.9, 1.0), 40, 3.0, 5.0)
			main.rack_weapon(h)
		"vasque":
			_drink(h, c)
		"cloche":
			_remove_prop(c)
			main.shake(0.4)
			Fx.burst(main, board.world(c) + Vector3(0, 1.0, 0), Color(1.0, 0.8, 0.4), 60, 5.0, 5.0)
			Fx.number(main, board.world(c) + Vector3(0, 1.6, 0), "La cloche se brise !", Color(1.0, 0.8, 0.4), true)
			for f in alive_foes():
				if dist(f.cell, c) <= 4 and not f.data.get("structure", false):
					f.set_meta("sonne", true)
					if has("battant"):
						f.mark = maxi(f.mark, 1)  # un Sonné ne décompte pas sa Marque : elle tient jusqu'à son vrai tour
					Fx.number(main, f.position + Vector3(0, 1.0, 0), "Sonné", Color(1.0, 0.8, 0.4))
			if has("battant"):
				busy = false
				changed.emit()
				return  # Battant de cloche : sonner ne coûte plus le déplacement
	h.moved = true
	h.walked = true
	busy = false
	changed.emit()
	_after_action()


func trigger_prop(c: Vector2i, d: Vector2i) -> void:
	## Brasero : explosion. Pilier : effondrement dans la direction d.
	var k: String = board.props.get(c, "")
	brasero_aura.erase(c)
	if k in BOOM:
		booms += 1
		_sim("explosion")
		if powers.has("fonderie") and board.kind.get(c, "") != "water" and board.kind.get(c, "") != "tower":
			_fonderie_q.append(c)
		if powers.has("pip"):
			_craft(1)
		_remove_prop(c)
		var p := board.world(c)
		Fx.burst(main, p + Vector3(0, 0.6, 0), EMBER, 90, 6.0)
		Fx.number(main, p, "Boum", EMBER, true)
		main.shake(0.6)
		var r := 2 if has("poudre_fine") else 1
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var t := c + Vector2i(dx, dz)
				var u := unit_at(t)
				if u:
					_blast = true
					_terrain = true
					damage(u, _boom_dmg(7 + (4 if has("etoupe") else 0)))
					_terrain = false
					_blast = false
				if oaks.has(t):
					_hit_tree(t, 0, true)
				if board.props.get(t, "") in BOOM:
					await wait(0.12)
					await trigger_prop(t, d)
		await _after_boom(c)
	elif k == "pilier":
		_remove_prop(c)
		main.shake(0.5)
		for i: int in range(1, 5 if has("coin_carrier") else 3):
			var t := c + d * i
			Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Color(0.75, 0.72, 0.66), 40, 3.0)
			var u := unit_at(t)
			if u:
				_terrain = true
				damage(u, 9)
				_terrain = false
			if board.props.get(t, "") in BOOM + ["pilier"]:
				await trigger_prop(t, d)
		Fx.number(main, board.world(c), "Effondrement", Color(1, 0.85, 0.6))
	changed.emit()
	while _fonderie_q.size() > 0:
		var fc: Vector2i = _fonderie_q.pop_front()
		if not board.props.has(fc):
			_lava(fc)


func _lava(c: Vector2i) -> void:
	## Une faille de braise remplace la rune de la case (Fonderie, Amadou).
	if tiles.has(c):
		for n in tile_nodes:
			if is_instance_valid(n) and n.position.distance_to(board.world(c) + Vector3(0, 0.03, 0)) < 0.2:
				n.queue_free()
	tiles[c] = "lave"
	_make_tile(c, "lave")


func _boom_dmg(n: int) -> int:
	## Cœur de fournaise : les explosions infligent le double, à tous.
	return n * (2 if has("coeur_fournaise") else 1)


func _after_boom(c: Vector2i) -> void:
	## Reliques d'explosion : Soufflet de forge (Recharge un objet), Souffle du canonnier (repousse en croix).
	if has("soufflet") and player_turn and active and not _soufflet:
		for ci in hand:
			if Data.def(ci.id).has("tool") and _recharge_ci(ci, 1, false):
				_soufflet = true
				Fx.number(main, active.position + Vector3(0, 1.2, 0), "Soufflet : %s (%d)" % [Data.card(ci).name, int(ci.uses)], GOLD_FX)
				break
	if has("souffle") and not _souffle:
		_souffle = true
		for d in Board.DIRS:
			var o := unit_at(c + d)
			if o and o.alive:
				await push(o, d, 1)
		_souffle = false


# ------------------------------------------------------------------ tours

func _next_round() -> void:
	## Nouveau round : tout le monde joue une fois, du plus rapide au plus lent (FFT).
	turn += 1
	log_add("— Round %d —" % turn)
	if turn > 1:
		_smoke_tick()
		_brasero_tick()
		await _turrets_fire()
		if over:
			return
	if turn == 3 and mods.has("renforts"):
		_reinforce()
	if turn > 1:
		await _glyphs()
		await _bombs()
		await _resolve_omens()
		if over:
			return
	await _round_start()
	if over:
		return
	order = alive_heroes() + alive_foes()
	order.sort_custom(func(a, b): return _init_key(a) > _init_key(b))
	for u in order.duplicate():
		if u.has_meta("delay"):
			var n: int = u.get_meta("delay")
			u.remove_meta("delay")
			var i := order.find(u)
			order.remove_at(i)
			order.insert(mini(i + n, order.size()), u)
	qi = -1
	var chief: Array = alive_foes().filter(func(f): return f.data.has("titre"))
	if turn == 1 and chief.size() > 0:
		# carte-titre : le nom et une ligne, caméra sur lui
		main.focus(chief[0].position)
		main.ui.banner(chief[0].data.titre, chief[0].data.get("ligne", ""))
		await wait(1.6)
		main.focus(null)
	else:
		main.ui.banner("Round %d" % turn, "Du plus rapide au plus lent")
		await wait(0.5)
	# un porteur de carte : on l'annonce d'entrée, caméra sur lui (le défi se découvre, il ne se rate pas)
	var bearer: Array = alive_foes().filter(func(f): return f.card_id != "") if turn == 1 else []
	if bearer.size() > 0:
		var b: Unit = bearer[0]
		main.focus(b.position)
		main.ui.banner("🃏 %s" % Data.CARD_CONDS[b.card_cond].name, "%s garde une carte : %s. %s%s" % [b.nm, Data.def(b.card_id).name, Data.CARD_CONDS[b.card_cond].text, "" if b.card_cond == "fuite" else " Relevé, le défi l'enchante."])
		await wait(2.2)
		main.focus(null)
	_challenge_hud()
	await _advance()


# ------------------------------------------------------------------ ennemis : règles communes (spec du 26/09)

func _first(key: String, pos: Vector3, text: String, col: Color, expl := "") -> void:
	## La première fois qu'une mécanique se déclenche dans la run : le texte en grand, et son explication.
	var seen: Dictionary = main.seen_mech
	if seen.has(key):
		Fx.number(main, pos + Vector3(0, 0.6, 0), text, col)
		return
	seen[key] = true
	if main._testing():
		print("  mécanique : ", key)
	Fx.number(main, pos + Vector3(0, 0.9, 0), text, col, true)
	main.ui.toast(text + (" — " + expl if expl != "" else ""))
	log_add("%s %s" % [text, expl])


func _meta(u: Object, k: String) -> Variant:
	return u.get_meta(k) if u.has_meta(k) else null


func _in_aura(u: Unit, key: String, r: int) -> bool:
	## u est-il dans l'aura « key » d'un ennemi vivant (Fanal, Porte-étendard, Capitaine) ?
	for o in foes:
		if o.alive and o.data.get("aura", "") == key and dist(o.cell, u.cell) <= r:
			return true
	return false


func _foe_omen(kind: String, cells: Array, owner: Unit, extra := {}) -> Dictionary:
	## Télégraphe commun : cases rouge-ambre et compte à rebours ; résolu au prochain round ou au tour de l'auteur.
	var om := {"kind": kind, "cells": cells, "owner": owner, "nodes": []}
	om.merge(extra)
	for c: Vector2i in cells:
		if not board._in(c):
			continue
		var l3 := Label3D.new()
		l3.text = {"suinte": "≋", "fissure": "⚒", "baril": "✹", "chasse": "≋", "digue": "⚠", "coupe": "✂"}.get(kind, "!") + " 1"
		l3.font = Fx.title_font()
		l3.font_size = 64
		l3.pixel_size = 0.0045
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.no_depth_test = true
		l3.modulate = Color(1.0, 0.55, 0.25)
		l3.outline_size = 14
		l3.outline_modulate = Color(0.1, 0.03, 0.02, 0.9)
		l3.position = (board.world(c) if board.kind[c] != "water" else Vector3(c.x, Board.WATER_Y, c.y)) + Vector3(0, 0.35, 0)
		units_root.add_child(l3)
		om.nodes.append(l3)
	foe_omens.append(om)
	changed.emit()
	return om


func _drop_omen(om: Dictionary) -> void:
	for n in om.nodes:
		if is_instance_valid(n):
			n.queue_free()
	foe_omens.erase(om)
	changed.emit()


func omen_cells() -> Dictionary:
	var out := {}
	for om in foe_omens:
		for c in om.cells:
			if board._in(c):
				out[c] = true
	return out


func _resolve_omens() -> void:
	## Début de round : l'eau monte, le sol cède, les barils sautent. Un seul passage de mutation du plateau.
	var muts: Array = []
	for om in foe_omens.duplicate():
		match om.kind:
			"suinte", "coupe":
				for c in om.cells:
					muts.append({"cell": c, "kind": "water"})
				_drop_omen(om)
			"fissure":
				for c in om.cells:
					muts.append({"cell": c, "dh": -1})
				_drop_omen(om)
			"baril":
				_drop_omen(om)
				if board.props.get(om.cell, "") == "baril":
					_remove_prop(om.cell)
					_explode(om.cell, 10, true)
					await wait(0.3)
	if muts.size() > 0:
		await _mutate_cells(muts)


func _mutate_cells(list: Array) -> void:
	## Un seul helper de mutation (Vanne, Fouisseur) : applique, reconstruit le plateau une fois, résout les unités.
	var hit: Array = []
	for m in list:
		var c: Vector2i = m.cell
		if not board._in(c) or board.kind[c] in ["water", "tower", "monument"]:
			continue
		if m.has("dh"):
			board.h[c] = maxi(0, board.h[c] + int(m.dh))
			var wet := Board.DIRS.any(func(d): return board.kind.get(c + d, "") == "water")
			if board.h[c] == 0 and wet:
				board.kind[c] = "water"
		if m.get("kind", "") == "water":
			board.kind[c] = "water"
			board.h[c] = 0
		if board.kind[c] == "water" and board.props.has(c):
			_remove_prop(c)
		hit.append(c)
	if hit.is_empty():
		return
	board.build_visuals()
	main.shake(0.3)
	for c in hit:
		Fx.burst(main, board.world(c) + Vector3(0, 0.3, 0), Color(0.75, 0.95, 1.0) if board.kind[c] == "water" else Color(0.75, 0.7, 0.6), 30, 3.0)
		var u := unit_at(c)
		if u == null:
			continue
		if board.kind[c] == "water":
			await _fall_water(u)
		else:
			u.place(c, board)
			Fx.number(main, u.position, "Chute", Color(1, 0.8, 0.5))
			damage(u, 4)
	changed.emit()


func _fall_water(u: Unit) -> void:
	## Une unité se retrouve dans l'eau : noyade (8), coulée si elle est lourde, sauf si elle nage ou vole.
	if not u.alive or u.has_p("eau") or u.fly:
		return
	Fx.burst(main, Vector3(u.cell.x, Board.WATER_Y + 0.1, u.cell.y), Color(0.75, 0.95, 1.0), 40, 3.0, 2.0)
	main.shake(0.2)
	var wc := u.cell
	var lock: bool = u.side == "foe" and has("cle_ecluse")  # Clé de la Grande Écluse : l'eau ne tue ni ne blesse les ennemis
	if u.data.get("heavy", false) and not u.has_p("ancre") and not lock:
		Fx.number(main, u.position, "Coulé", Color(0.6, 0.85, 1.0), true)
		_cause = "eau"
		kill(u)
		_cause = ""
		await _drowned(u, wc)
		return
	if u.trait_id != "nageur" and not u.has_p("flotte") and not lock:
		Fx.number(main, u.position, "Noyade", Color(0.6, 0.85, 1.0))
		_cause = "eau"
		if u.key == "dame":
			Fx.number(main, u.position + Vector3(0, 1.2, 0), "Noyée dans sa crue !", Color(0.6, 0.85, 1.0), true)
		_terrain = true
		damage(u, 8 + (6 if has("cloche") and u.side == "foe" else 0) + (int(u.max_hp * 0.2) if u.key == "dame" else 0))
		_terrain = false
		_cause = ""
		await _drowned(u, wc)
	if u.alive:
		var free := _nearest_free(u.cell)
		u.cell = free
		await u.teleport(free, board)


func _drowned(u: Unit, wc: Vector2i) -> void:
	## Un ennemi se noie : Nasse d'osier (or s'il en meurt), Remous (ses voisins sont repoussés loin de lui).
	if u.side != "foe":
		return
	if has("nasse") and not u.alive:
		_gold(15, u.position)
	if has("remous") and not _remous:
		_remous = true
		for d in RING8:
			var o := unit_at(wc + d)
			if o and o != u and o.side == "foe" and o.alive:
				await push(o, _dir(wc, o.cell), 1)
		_remous = false


func _round_start() -> void:
	## Début de round : amarres, Appels de l'Obélisque et du Gardien.
	_smolder_tick()
	for b in alive_foes().filter(func(o): return o.data.ai == "tether"):
		for o in foes:
			if _meta(o, "amarre") == b:
				o.remove_meta("amarre")
		var cand: Array = alive_foes().filter(func(o): return not o.data.get("structure", false) and not o.data.get("no_champion", false) and not o.has_meta("amarre"))
		cand.sort_custom(func(a, c): return a.max_hp > c.max_hp)
		for o in cand.slice(0, 2):
			o.set_meta("amarre", b)
			Fx.bolt(main, b.position + Vector3(0, 0.8, 0), o.position + Vector3(0, 0.8, 0), Color(0.36, 0.42, 0.8))
	for f in alive_foes():
		if f.data.ai == "spawner":
			var fl := clampi(main.floor_i, 1, 3)
			if fl == 1 and turn % 2 == 0:
				continue
			var cap: int = [6, 8, 7][fl - 1]
			var pool: Array = [["husk"], ["husk", "wisp", "harpie"], ["husk", "wisp", "eclusier_fou"]][fl - 1]
			if alive_foes().size() < cap:
				await _summon(f, pool[(turn - 1) % pool.size()])
		elif f.key == "gardien" and f.get_meta("phase", 0) < 2 and turn % 3 == 0 and alive_foes().size() < 8:
			await f.cast()
			var ph: int = f.get_meta("phase", 0)
			_first("appel", f.position + Vector3(0, 0.6, 0), "Appel !", EMBER, "le Gardien appelle des renforts tous les 3 rounds.")
			var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null)
			free.sort_custom(func(a, c): return dist(a, f.cell) < dist(c, f.cell))
			for i in mini(2 if ph == 0 else 1, free.size()):
				var u := spawn_foe("husk" if ph == 0 else "eclusier_fou", free[i])
				u.face(f.cell - u.cell)
				Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
			await wait(0.5)


func _phase(u: Unit, p: int) -> void:
	## Palier verrouillé franchi : bandeau, et le boss change.
	if not u.alive or over:
		return
	main.shake(0.8)
	u.data = u.data.duplicate(true)
	match u.key:
		"chevrier":
			main.ui.banner("La corne sonne !", "Deux chèvres de plus ; il coupe deux ponts par tour")
			for i in 2:
				await _summon(u, "chevre")
		"dame":
			main.ui.banner("Les vannes hurlent", "La crue monte de deux rangs par tour")
		"brule_haie":
			main.ui.banner("Tout brûle", "Il fait couver deux arbres par tour")
		"grelin":
			main.ui.banner("Les vannes cèdent !", "Grelin perd son pavois ; la Chasse d'eau revient tous les 2 tours")
			u.data.passives = u.data.passives.filter(func(q): return q != "pavois_face")
		"gardien":
			if p == 1:
				main.ui.banner("Les vannes s'ouvrent", "Deux vannes rouillées ; l'Appel fait venir un Éclusier fou")
				var banks: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and _hero_dist(c) >= 4 					and Board.DIRS.any(func(d): return board.kind.get(c + d, "") == "water"))
				banks.sort_custom(func(a, c): return dist(a, u.cell) < dist(c, u.cell))
				for i in mini(2, banks.size()):
					var bc: Vector2i = banks[mini(i * 4, banks.size() - 1)]
					if unit_at(bc) != null:
						bc = banks[i]
					var v := spawn_foe("vanne", bc)
					Fx.burst(main, v.position + Vector3(0, 0.6, 0), Color(0.6, 0.9, 1.0), 40, 3.0, 5.0)
			else:
				main.ui.banner("Le Gardien se lève", "Plus de riposte ; il avance et abat la digue sur une ligne")
				u.data.passives = u.data.passives.filter(func(q): return q != "contre")
				u.move = 4
	Fx.number(main, u.position + Vector3(0, 1.4, 0), "Phase %d" % (p + 1), EMBER, true)
	changed.emit()


func _init_key(u: Unit) -> float:
	## Vitesse ; à égalité, les héros d'abord.
	return u.speed * 10.0 + (5.0 if u.side == "hero" else 0.0) + (u.get_instance_id() % 7) * 0.1 \
		+ (1000.0 if u.side == "hero" and turn == 1 and has("corne_aube") else 0.0)  # Corne de l'aube : les héros d'abord au premier round


func _advance() -> void:
	## Au suivant : un héros attend le joueur, un ennemi joue seul.
	while not over:
		qi += 1
		if qi >= order.size():
			await _next_round()
			return
		var u: Unit = order[qi]
		if not is_instance_valid(u) or not u.alive:
			continue
		if main.args.has("trace"):
			print("  tour de ", u.nm, " (", u.side, ")")
		if u.companion:
			await _ally_turn(u)
			continue
		if u.side == "hero":
			_hero_turn(u)
			if player_turn:
				changed.emit()
				return
			continue
		if main.tuto:
			continue  # initiation : les ennemis attendent, le plateau reste celui de la consigne
		await _foe_turn(u)


func _ally_turn(a: Unit) -> void:
	## Un compagnon joue seul : il va au contact (ou à portée) de l'ennemi le plus proche et frappe.
	## Le Chaman apprivoisé soigne d'abord un héros blessé.
	active = null
	a.struck = false
	if a.poison > 0:
		damage(a, a.poison, null, false)
		a.poison -= 1
		if not a.alive:
			return
	main.focus(a.position)
	var cd: Dictionary = Data.COMPANIONS[a.key]
	var rg: Array = a.data.get("range", [1, 1])
	var rooted := a.root > 0
	if rooted:
		a.root -= 1
	var R := reach(a) if not rooted else {"prev": {a.cell: a.cell}, "cells": {a.cell: true}, "dist": {a.cell: 0}}
	if cd.get("heal", 0) > 0:
		var w: Unit = null
		for h in heroes:
			if h.alive and h.hp * 10 < h.max_hp * 7 and (w == null or h.hp * w.max_hp < w.hp * h.max_hp):
				w = h
		if w:
			var go := a.cell
			for cell in R.cells:
				if dist(cell, w.cell) <= 3 and (go == a.cell and dist(a.cell, w.cell) > 3 or R.dist.get(cell, 99) < R.dist.get(go, 99)):
					go = cell
			if go != a.cell:
				await a.walk(path_to(R.prev, go), board)
			if dist(a.cell, w.cell) <= 3:
				a.face(w.cell - a.cell)
				await a.cast()
				await Fx.bolt(main, a.position, w.position, Color(0.6, 1.0, 0.6))
				heal(w, int(cd.heal))
				await wait(0.3)
				main.focus(null)
				return
	var target: Unit = null
	var go := a.cell
	var best := INF
	for f in alive_foes():
		for cell in R.cells:
			var dd := dist(cell, f.cell)
			if dd < rg[0] or dd > rg[1] or (rg[1] == 1 and absi(board.h[cell] - board.h[f.cell]) > 3):
				continue
			var s: float = R.dist.get(cell, 0) + f.hp * 0.05 - (4.0 if f.data.get("structure", false) else 0.0)
			if s < best:
				best = s
				go = cell
				target = f
	if target == null:
		# personne à portée : il se rapproche
		var near: Unit = null
		for f in alive_foes():
			if near == null or dist(f.cell, a.cell) < dist(near.cell, a.cell):
				near = f
		if near:
			var mv := a.cell
			for cell in R.cells:
				if dist(cell, near.cell) < dist(mv, near.cell):
					mv = cell
			if mv != a.cell:
				await a.walk(path_to(R.prev, mv), board)
				await _landed(a)
		main.focus(null)
		return
	if go != a.cell:
		await a.walk(path_to(R.prev, go), board)
		await _landed(a)
	if not a.alive or not target.alive or over:
		return
	a.face(target.cell - a.cell)
	if rg[1] > 1:
		await a.cast()
		await Fx.bolt(main, a.position, target.position, Color(0.6, 1.0, 0.7))
	else:
		await a.lunge(target.position)
	damage(target, calc(a, target, int(a.data.dmg)).dmg, a, true, rg[1] > 1)
	if target.alive and int(cd.get("push", 0)) > 0:
		await push(target, _dir(a.cell, target.cell), int(cd.push))
	if target.alive and int(cd.get("pull", 0)) > 0 and dist(a.cell, target.cell) > 1:
		_pulling = true
		await push(target, _dir(target.cell, a.cell), mini(int(cd.pull), dist(a.cell, target.cell) - 1))
		_pulling = false
	if target.alive and int(cd.get("mark", 0)) > 0:
		target.mark = maxi(target.mark, int(cd.mark))
	if cd.get("taunt", false):
		a.taunt = true
	await wait(0.25)
	main.focus(null)


var _fonderie_q: Array = []


func _omen(cell: Vector2i, dmg: int, h: Unit) -> void:
	## Présage : au début du prochain tour du héros, l'ennemi qui s'y tient encaisse, armure ignorée.
	if omens.has(cell) and omens[cell].node:
		omens[cell].node.queue_free()
	var l3 := Label3D.new()
	l3.text = "☽ %d" % dmg
	l3.font = Fx.title_font()
	l3.font_size = 80
	l3.pixel_size = 0.005
	l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l3.modulate = Color(0.8, 0.6, 1.0)
	l3.outline_size = 16
	l3.outline_modulate = Color(0.08, 0.03, 0.12, 0.9)
	l3.position = board.world(cell) + Vector3(0, 0.25, 0)
	units_root.add_child(l3)
	omens[cell] = {"dmg": dmg, "owner": h, "node": l3}
	Fx.number(main, board.world(cell) + Vector3(0, 0.8, 0), "Présage", Color(0.8, 0.6, 1.0))


func _teleported(u: Unit) -> void:
	## Toute téléportation ou tout bond d'un héros (pas la marche, ni la charge, ni les poussées).
	u.tele = true
	u.teles += 1
	if u == active and u.side == "hero":
		if u.has_p("ombre_portee"):
			u.ambush = true  # Ombre portée : la prochaine attaque du tour frappe de dos
		if u.has_p("envol"):
			_count_hit(u)  # Envol : le bond compte comme un coup d'enchaînement
	if u.side == "hero" and not u.companion:
		for pst in alive_foes():
			if int(pst.data.get("guet", 0)) > 0 and dist(pst.cell, u.cell) <= int(pst.data.guet) and pst.get_meta("guet_round", -1) != turn and can_hit(pst, pst.cell, u):
				pst.set_meta("guet_round", turn)
				pst.face(u.cell - pst.cell)
				Fx.bolt(main, pst.position + Vector3(0, 0.8, 0), u.position + Vector3(0, 0.8, 0), EMBER)
				_first("evente", u.position, "Éventé !", Color(1.0, 0.6, 0.4), "la Pisteuse tire sur qui se téléporte à 5 cases d'elle, et l'expose.")
				damage(u, calc(pst, u, pst.atk()).dmg, pst, true, true)
				if u.alive:
					u.exposed = true
				break
	if u.side == "hero" and powers.has("cyclone") and power_owner.get("cyclone") == u:
		for d in RING8:
			var o := unit_at(u.cell + d)
			if o and o.side == "foe":
				Fx.burst(main, o.position + Vector3(0, 0.7, 0), Color(0.75, 0.95, 0.85), 16, 2.5)
				damage(o, maxi(1, int(power_val.get("cyclone", 3))))
	if u.side == "hero" and powers.has("danse_grue") and power_owner.get("danse_grue") == u:
		gain_block(u, maxi(1, int(power_val.get("danse_grue", 3))))
		if int(power_val.get("danse_grue2", 0)) > 0 and u.teles == 2 and u == active:
			energy += 1
			Fx.number(main, u.position + Vector3(0, 1.3, 0), "Danse · +1 énergie", GOLD_FX)


func _gain_energy(h: Unit, n: int) -> void:
	## L'énergie gagnée hors de son tour attend le prochain.
	if h == active and player_turn:
		energy += n
	else:
		bonus[h] = bonus.get(h, 0) + n


func _hero_turn(h: Unit) -> void:
	active = h
	_eco_used.clear()
	var korin: bool = powers.has("korin") and power_owner.get("korin") == h
	if _first_turn.has(h) and not powers.has("forteresse") and not h.keep_block and not korin:
		h.block = mini(8, h.block / 2) if h.has_p("digue") else 0  # Digue : la moitié reste (8 au plus)
	h.keep_block = false
	for k in ["bait", "parry", "dodge_next", "tele", "triple", "lvl_next"]:
		h.set(k, false)
	h.bph = 0
	h.bpm = h.bpm / 2  # concile du 29/09 : le BPM retombe de moitié, plus de réserve à 12 pour un Drop à 80
	h.inner = 0
	h.hits = 0
	h.set_meta("hazan_fait", false)  # Trois Coups, Troisième Main : un déclenchement par tour
	h.set_meta("linfei_fait", false)
	h.walked = false
	h.teles = 0
	h.blastproof = false
	used_turn = 0
	curee_turn = 0
	drawn_turn = 0
	nyxa_turn = 0
	heal_turn = false
	item_echo = null
	h.fuse = 0
	booms = 0
	hurt_turn = false
	stolen_turn = 0
	oriel_turn = false
	fourgue_turn = false
	plume_used = false
	masque_used = false
	_soufflet = false
	_hits_turn = 0
	for f in foes:
		f.pushed = false
	h.combo = 0
	if h.has_meta("vague"):  # Contre-vague : les coups encaissés au contact lancent l'enchaînement
		h.combo = int(h.get_meta("vague"))
		h.remove_meta("vague")
	h.ambush = false
	h.moved = false
	h.taunt = false
	h.struck = false
	if h.poison > 0:
		Fx.number(main, h.position, "☠ %d" % h.poison, Color(0.6, 0.9, 0.3))
		damage(h, h.poison, null, false)
		h.poison -= 1
		if not h.alive:
			active = null
			return
	if h.has_p("bouclier"):
		gain_block(h, 3)
	if h.has_p("regen") and h.hp < h.max_hp:
		heal(h, 2)
	if h.has_meta("zoc_hit"):
		h.remove_meta("zoc_hit")
	if h.has_meta("englue"):
		Fx.number(main, h.position + Vector3(0, 0.5, 0), "Englué : −1 déplacement", Color(0.6, 0.8, 0.5))
	if h.root > 0:
		h.moved = true
		h.walked = true
		h.root -= 1
		Fx.number(main, h.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
	var aura := 0
	for o in oaks:
		if dist(o, h.cell) == 1:
			aura = maxi(aura, int(oak_aura.get(o, 0)))  # le meilleur voisin, sans cumul
	if aura > 0:
		gain_block(h, aura)
	echo = false
	played = 0
	voices.clear()
	energy = 3 + (1 if not _first_turn.has(h) and has("ambre") else 0) + int(bonus.get(h, 0)) \
		+ (1 if h.key == "tidiane" and powers.has("obsession") else 0) \
		+ (1 if not _first_turn.has(h) and h.trait_id == "matinal" else 0) + (1 if h.trait_id == "sang_chaud" and h.hp * 2 < h.max_hp else 0) \
		+ (1 if has("couronne_plomb") else 0) + (1 if has("cle_ecluse") else 0) - (1 if not _first_turn.has(h) and has("ecrin") else 0)
	if not _first_turn.has(h) and h.trait_id == "costaud":
		gain_block(h, 6)
	if not _first_turn.has(h) and h.block0() > 0:
		gain_block(h, h.block0())
	if h.trait_id == "lourdaud":
		gain_block(h, 4)
	bonus.erase(h)
	_tile_turn(h)
	_power_ticks(h)
	for oc in omens.keys():
		var om: Dictionary = omens[oc]
		if om.owner != h:
			continue
		omens.erase(oc)
		if om.node:
			om.node.queue_free()
		var of := unit_at(oc)
		if of and of.side == "foe":
			of.block = 0
			Fx.burst(main, of.position + Vector3(0, 1.0, 0), Color(0.75, 0.5, 1.0), 40, 3.0)
			Fx.number(main, of.position + Vector3(0, 1.2, 0), "Présage", Color(0.8, 0.6, 1.0), true)
			damage(of, int(om.dmg))
	var pl: Dictionary = piles[h]
	draw_pile = pl.draw
	discard = pl.discard
	exhausted = pl.exhausted
	hand = pl.keep
	pl.keep = []
	played_turn = []
	_turns_of[h] = int(_turns_of.get(h, 0)) + 1
	for ci in hand:
		var cu := int(Data.card(ci).get("charge_up", 0))
		if cu > 0:
			ci["chg"] = mini(int(ci.get("chg", 0)) + cu, 3 * cu)
	_start_draw = true
	draw(hand_size + (1 if has("grimoire") and int(_turns_of.get(h, 0)) <= 2 else 0) + (1 if h.trait_id == "insomniaque" else 0)
		+ (1 if h.has_p("prelude") and not _first_turn.has(h) else 0) + ((1 + int(power_val.get("dnb", 0))) if h.key == "tidiane" and powers.has("dnb") else 0)
		+ (1 if tiles.get(h.cell, "") == "autel" else 0) + (1 if has("chaine_forcat") else 0))
	if h.key == "receleur":
		# Double fond : ses objets ne lui bouchent pas la main
		while hand.filter(func(ci): return not Data.def(ci.id).has("tool")).size() < hand_size and hand.size() < 6 and not (draw_pile.is_empty() and discard.is_empty()):
			draw(1)
	var th: Array = main.tuto_hand(h)
	if th.size() > 0:
		hand = th  # initiation : la main de l'étape, pas celle de la pioche
	_extra_move.erase(h)
	_start_draw = false
	if _alambic:
		_alambic = false
		_craft(1, h)
	if powers.has("metronome") and power_owner.get("metronome") == h:
		h.bpm = mini(12, h.bpm + maxi(1, int(power_val.get("metronome", 1))))
		Fx.number(main, h.position + Vector3(0, 1.3, 0), "♪ %d" % h.bpm, Color(0.95, 0.5, 0.8))
	first_free = has("sablier")
	_first_turn[h] = true
	card_sel = -1
	_faced = false
	_move_plan = null
	player_turn = true
	busy = false
	select(h)
	main.follow(h.position, 17.0)  # zoom sur le héros qui joue
	main.ui.banner(h.nm, "À toi · %d mana" % energy)
	if powers.has("journal") and power_owner.get("journal") == h and played_ids.get(h, []).size() > 0:
		_journal.call_deferred(h)
	if has("double_fond") and not _double_fond:
		_double_fond = true
		_double_fond_go.call_deferred(h)


func _double_fond_go(h: Unit) -> void:
	busy = true
	Fx.number(main, h.position + Vector3(0, 1.4, 0), "Recommandation", GOLD_FX)
	await _embauche(h, 1)
	busy = false
	changed.emit()


func _journal(h: Unit) -> void:
	## Le Grand Journal : Découvre une carte déjà jouée ce combat.
	busy = true
	var ids: Array = []
	for id in played_ids.get(h, []):
		if not ids.has(id):
			ids.append(id)
	# niveau 3 : la page revient au niveau où elle a été jouée
	var lvls: Dictionary = played_lvl.get(h, {}) if int(power_val.get("journal", 0)) >= 1 else {}
	await _discover(h, ids, "LE GRAND JOURNAL", "Une page déjà écrite ce combat ; elle coûte 0", true, false, false, lvls)
	busy = false
	changed.emit()


func draw(n: int) -> void:
	## Le héros actif pioche dans son propre paquet.
	var got := 0
	while got < n and hand.size() < 10:
		if draw_pile.is_empty():
			draw_pile.append_array(discard)
			discard.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
		got += 1
	if got > 0 and not _start_draw:
		drawn_turn += got
	if got > 0 and powers.has("ignar") and not _start_draw:
		for f in alive_foes():
			damage(f, got * int(power_val.get("ignar", 1)), null, true, true)


func end_turn() -> void:
	if not player_turn or busy or over:
		return
	_lifesteal = false
	var nope: String = main.tuto_gate("end")
	if nope != "":
		main.ui.toast(nope)
		return
	# plus d'étape d'orientation : sans consigne du joueur depuis sa dernière action, il se tourne vers l'ennemi le plus proche
	if active and active.alive and not _faced:
		face_nearest(active)
	orienting = false
	_move_plan = null
	player_turn = false
	card_sel = -1
	coach.emit("ended", active)
	var keep: Array = []
	for ci in hand:
		var c := Data.card(ci)
		ci.erase("free")
		ci.erase("cut")
		if not c.get("retain", false):
			ci.erase("chg")
		if c.get("retain", false) or (c.has("tool") and not c.get("eph", false)):
			keep.append(ci)  # un objet reste en main d'un tour à l'autre, comme dans une besace
		elif c.get("eph", false):
			pass  # copie éphémère : elle s'efface
		elif c.get("ethereal", false):
			exhausted.append(ci)
		else:
			discard.append(ci)
	if active and piles.has(active):
		piles[active].keep = keep
	hand.clear()
	if active:
		active.mark = maxi(0, active.mark - 1)
		if active.has_meta("englue"):
			active.remove_meta("englue")
		_chain_check(active)
	if active:
		active.trap_seen = traps_fired
	if active and active.alive and powers.has("ecailles") and power_owner.get("ecailles") == active and not active.walked:
		gain_block(active, maxi(1, int(power_val.get("ecailles", 4))))
		active.keep_block = true
	if active and active.alive and active.fuse > 0:
		Fx.number(main, active.position + Vector3(0, 1.0, 0), "Burn-out", EMBER, true)
		_explode(active.cell, active.fuse + (2 if active.has_p("meche") else 0))  # player_turn est déjà faux : Mèche courte comptée à la main
		active.fuse = 0
	for f in foes:
		if f.alive and f.stick > 0:
			var sd: int = f.stick
			f.stick = 0
			_explode(f.cell, sd + (2 if active and active.has_p("meche") else 0))
	if has("relais_poste") and energy > 0 and active:
		# Relais de poste : 1 énergie non dépensée passe au héros suivant de l'ordre du round (bouclé)
		for k in range(1, order.size() + 1):
			var nx = order[(qi + k) % order.size()]
			if is_instance_valid(nx) and nx.alive and nx.side == "hero" and not nx.companion:
				bonus[nx] = bonus.get(nx, 0) + 1
				break
	active = null
	board.highlight({})
	main.focus(null)
	changed.emit()
	await _advance()


func _after_action() -> void:
	## Le héros actif est tombé pendant son propre tour : on passe au suivant.
	if player_turn and not over and active and not active.alive:
		busy = false
		end_turn()


func pick_hero(h: Unit) -> void:
	## Clic sur un héros : le héros actif se sélectionne, les autres montrent leur fiche.
	## Une carte choisie : son portrait vaut sa case (le perso caché derrière la main reste ciblable).
	if card_sel >= 0 and card_sel < hand.size() and card_targets(Data.card(hand[card_sel]), owner_of(Data.card(hand[card_sel]))).has(h.cell):
		click(h.cell)
		return
	if h == active:
		select(h)
	else:
		toggle_inspect(h)


func _foe_turn(f: Unit) -> void:
	f.block = 0
	f.struck = false
	f.struck_hero = false
	if f.data.get("root_immune", false):
		f.root = 0
	if f.mark > 0 and powers.has("vesk"):
		f.poison += int(power_val.get("vesk", 3))
	if f.poison > 0:
		Fx.number(main, f.position, "☠ %d" % f.poison, Color(0.6, 0.9, 0.3))
		_dot = true
		damage(f, f.poison, null, false)
		_dot = false
		if not has("braise_eternelle"):
			f.poison -= 1
		await wait(0.3)
		if not f.alive:
			return
	if f.has_meta("sonne"):
		f.remove_meta("sonne")
		Fx.number(main, f.position + Vector3(0, 1.0, 0), "Sonné : passe son tour", Color(1.0, 0.8, 0.4))
		await wait(0.4)
		return
	f.walked = false
	var arm: int = int(f.data.get("armor", 0)) + f.extra_armor + (4 if mods.has("blindes") else 0)
	if not _first_turn.has(f):
		_first_turn[f] = true
		arm += f.block0()
	if f.has_p("bouclier"):
		arm += 3
	if f.key == "carapace" and main.floor_i == 1 and not main.tuto:
		arm -= 2  # acte 1 : 6 par tour, et la leçon de l'eau
	if f.key == "grelin":
		arm += 3 * alive_foes().filter(func(o): return o.key == "treuil").size()
	if f.key == "lancier":
		# mur de piques : côte à côte, ils se blindent et ripostent double
		var wall := alive_foes().any(func(o): return o != f and o.key == "lancier" and dist(o.cell, f.cell) == 1)
		f.set_meta("piques", wall)
		if wall:
			arm += 3
			_first("piques", f.position, "Mur de piques", Color(0.9, 0.8, 0.6), "deux Lanciers côte à côte : +3 armure, riposte 8.")
	if f.has_meta("asseche"):
		f.remove_meta("asseche")
		arm = 0
		Fx.number(main, f.position + Vector3(0, 0.6, 0), "Asséché : sans armure", Color(0.9, 0.8, 0.6))
	if arm > 0:
		gain_block(f, arm)
	if f.has_p("regen") and f.hp < f.max_hp:
		heal(f, 2)
	_tile_turn(f)
	if f.data.get("structure", false):
		main.focus(f.position)
	else:
		main.follow(f.position, 21.0)  # la caméra suit l'ennemi qui joue, le temps d'arriver
		await wait(0.3)
	changed.emit()
	# déplacement en plus : l'ordre du Capitaine (+1 à 2 cases), la charge du Capitaine (+2)
	var mv_bonus := 0
	if f.key != "capitaine" and _in_aura(f, "ordre", 2):
		mv_bonus += 1
	if f.data.ai == "commander" and (f.has_meta("hit") or alive_foes().filter(func(o): return o != f and not o.data.get("structure", false)).size() < 2):
		mv_bonus += 2
	f.move += mv_bonus
	await foe_act(f)
	f.move -= mv_bonus
	if f.has_meta("hit"):
		f.remove_meta("hit")
	if f.has_meta("echouee"):
		var ec: int = f.get_meta("echouee") - 1
		if ec <= 0:
			f.remove_meta("echouee")
		else:
			f.set_meta("echouee", ec)
	while _enclume_q.size() > 0 and not over:
		var e: Array = _enclume_q.pop_front()
		await _enclume(e[0], e[1])
	f.mark = maxi(0, f.mark - 1)
	if f.alive:
		# fin de tour : il se tourne vers le héros le plus proche, comme un joueur prudent
		var hs := alive_heroes()
		hs.sort_custom(func(a, b): return dist(a.cell, f.cell) < dist(b.cell, f.cell))
		if hs.size() > 0:
			f.face(hs[0].cell - f.cell)
	await wait(0.2)
	main.focus(null)


# ------------------------------------------------------------------ sélection et clics

func select(u: Unit) -> void:
	if selected:
		selected.set_selected(false)
	selected = u
	for h in heroes:
		h.set_xray(h == u)
	if u:
		u.set_selected(true)
	changed.emit()


func select_card(i: int) -> void:
	if not player_turn or busy or orienting or i >= hand.size():
		return
	if card_sel == i:
		card_sel = -1
		changed.emit()
		return
	var c := Data.card(hand[i])
	var h := owner_of(c)
	var nope: String = main.tuto_gate("card", c.id)
	if nope != "":
		main.ui.toast(nope)
		return
	if h == null or not h.alive:
		main.ui.toast("%s est tombé : cette carte est morte." % Data.HEROES[c.owner].name)
		return
	if cost_of(c) > energy:
		main.ui.toast("Pas assez d'énergie.")
		return
	select(h)
	card_sel = i
	_move_plan = null
	var tg := card_targets(c, h)
	# seule « self » part toute seule : une carte d'allié attend son clic (elle se jouait sur la case du lanceur,
	# et un échange de place avec un seul allié à portée échangeait le héros avec lui-même)
	if c.get("target", "foe") == "self":
		play_card(i, h.cell)
		return
	if tg.is_empty():
		main.ui.toast("Aucune cible à portée.")
	var tl := target_list()
	if tl.size() > 0:  # la cible la plus proche est déjà visée : un toucher de plus la joue
		main.hover = tl[0]
		main.refresh_hover()
	changed.emit()


func cost_of(c: Dictionary) -> int:
	if (first_free and int(Data.def(c.id).get("cost", 0)) == 1) or c.get("free", false):
		return 0
	var h := owner_of(c)
	if h and h.triple and c.kind == "atk":
		return 0
	var cost: int = int(c.cost) - int(c.get("cut", 0))
	if c.has("guild") and has("medaille") and c.cls.all(func(k): return heroes.any(func(u): return u.key == k)):
		cost -= 1
	if h and cost >= 2 and h.has_p("economie") and not _eco_used.has(h):
		cost -= 1
	if h and has("masque") and not c.cls.has(h.key) and not masque_used:
		cost -= 1  # Masque de porcelaine : la première carte hors classe du tour
	return maxi(0, cost)


func click(c: Vector2i) -> void:
	if not player_turn or busy or over:
		return
	if orienting:
		if c != active.cell:
			active.face(c - active.cell)
		end_turn()
		return
	if card_sel >= 0:
		var card := Data.card(hand[card_sel])
		var h := owner_of(card)
		if card_targets(card, h).has(c):
			var nope: String = main.tuto_gate("target", c)
			if nope != "":
				main.ui.toast(nope)
				return
			play_card(card_sel, c)
		else:
			card_sel = -1
			changed.emit()
		return
	var u := unit_at(c)
	if u and u.side == "hero":
		pick_hero(u)
		return
	if u and u.side == "foe":
		toggle_inspect(u)  # la fiche reste affichée jusqu'au prochain clic
		return
	var pk: String = board.props.get(c, "")
	if pk in USABLE and selected:
		var nope: String = main.tuto_gate("prop", c)
		if nope != "":
			main.ui.toast(nope)
			return
		var near := dist(selected.cell, c) == 1 and absi(board.h[selected.cell] - board.h[c]) <= 2
		if near and (pk == "coffre" or not selected.moved):
			interact(selected, c)
		elif not selected.moved:
			# le héros y va tout seul : la case libre la plus proche au contact, puis il ouvre
			var R := reach(selected)
			var best = null
			for cell in R.cells:
				if dist(cell, c) == 1 and absi(board.h[cell] - board.h[c]) <= 2 and (best == null or R.dist[cell] < R.dist[best]):
					best = cell
			if best == null:
				main.ui.toast("Trop loin : frappez le coffre avec une attaque, ou approchez-vous." if pk == "coffre" else "Trop loin : approchez-vous.")
				return
			busy = true
			var mover := selected
			await mover.walk(path_to(R.prev, best), board)
			mover.moved = true
			mover.walked = true
			await _landed(mover)
			busy = false
			if mover.alive:
				interact(mover, c)
		else:
			main.ui.toast("Frappez le coffre avec une attaque pour l'ouvrir." if pk == "coffre" else "%s a déjà utilisé son déplacement." % selected.nm)
		return
	var sprint := can_sprint(selected)
	if selected and (not selected.moved or sprint):
		var R := reach(selected)
		if R.cells.has(c) and c != selected.cell:
			var nope: String = main.tuto_gate("move", c)
			if nope != "":
				main.ui.toast(nope)
				return
			# deux clics : le premier trace le chemin (et le prix d'une course), le second y va.
			# Au doigt, le premier toucher vise déjà ; les pilotes de test vont droit au but.
			if _move_plan != c and not main.mobile and (not main._testing() or main.args.has("uxtest")):
				_move_plan = c
				main.refresh_hover()
				return
			_move_plan = null
			busy = true
			changed.emit()
			var mover := selected  # la sélection peut changer pendant la marche
			if sprint:
				energy -= 3
				_extra_move[mover] = true
				Fx.number(main, mover.position + Vector3(0, 1.1, 0), "Course · 3 mana", GOLD_FX)
			var path := path_to(R.prev, c)
			var start := mover.cell
			await mover.walk(path, board)
			mover.moved = true
			mover.walked = true
			_faced = false
			face_nearest(mover)
			_zoc(mover, start)
			for pc in path:
				if loot.has(pc):
					_pick_loot(mover, pc)
			await _landed(mover)
			_check_portal(mover)
			busy = false
			changed.emit()
			coach.emit("moved", mover)
			if can_sprint(mover) and not main.tuto and not main.seen_mech.has("course"):
				_first("course", mover.position + Vector3(0, 0.8, 0), "Course", GOLD_FX, "un héros qui a déjà marché peut repartir une fois par tour, pour 3 mana : cliquez une case éclairée.")
			_after_action()
			return


func _zoc(h: Unit, from: Vector2i) -> void:
	if h.has_meta("zoc_hit") or not h.alive:
		return
	for s in alive_foes():
		if s.data.get("zoc", false) and dist(s.cell, from) == 1 and dist(s.cell, h.cell) > 1:
			h.set_meta("zoc_hit", true)
			s.face(h.cell - s.cell)
			_first("zoc", s.position, "Coup d'opportunité", Color(1.0, 0.7, 0.4), "quitter le contact d'une Sentinelle coûte un coup.")
			damage(h, maxi(1, roundi(s.atk() * 0.5)), s)
			return


func _chain_check(h: Unit) -> void:
	## La chaîne du Pilori tombe si le pilori est mort ou si le héros finit son tour à plus de 6 cases.
	if not h.has_meta("chained"):
		return
	var p = h.get_meta("chained")
	if not is_instance_valid(p) or not p.alive or dist(p.cell, h.cell) > 6:
		h.remove_meta("chained")
		Fx.number(main, h.position + Vector3(0, 0.8, 0), "Chaîne brisée", Color(0.8, 0.9, 1.0))


func can_sprint(u: Unit) -> bool:
	## Course : un héros qui a déjà bougé peut repartir une fois pour 3 mana.
	return u != null and u == active and u.moved and energy >= 3 and not _extra_move.has(u) and u.root <= 0


func toggle_inspect(u: Unit) -> void:
	inspect = null if u == null or u == inspect else u
	main.refresh_hover()


func turn_facing(s: int) -> void:
	## Flèches gauche/droite : un quart de tour, à tout moment du tour, gratuit.
	if player_turn and not busy and active and active.alive:
		active.facing = Vector2i(-active.facing.y * s, active.facing.x * s)
		_faced = true
		coach.emit("faced", active)  # l'Initiation attend ce geste : sans lui, le bouton ⤵ de la tablette la bloquait
		main.refresh_hover()


func face_cell(c: Vector2i) -> bool:
	## Clic droit sur une case : le héros actif se tourne vers elle, gratuit, à tout moment de son tour.
	if not player_turn or busy or active == null or not active.alive or c == active.cell:
		return false
	active.face(_dir(active.cell, c))
	_faced = true
	coach.emit("faced", active)
	main.refresh_hover()
	return true


func face_nearest(u: Unit) -> void:
	## Orientation automatique : vers l'ennemi le plus proche (le dos exposé compte : coups de dos, pièges, Tenaille).
	var best: Unit = null
	for f in alive_foes():
		if best == null or dist(u.cell, f.cell) < dist(u.cell, best.cell):
			best = f
	if best:
		u.face(_dir(u.cell, best.cell))


func cancel() -> void:
	if _move_plan != null:
		_move_plan = null
		main.refresh_hover()
		return
	if orienting:
		orienting = false
		active.facing = _orient_from
		main.refresh_hover()
		changed.emit()
		return
	if inspect:
		inspect = null
		main.refresh_hover()
		return
	if card_sel >= 0:
		card_sel = -1
	changed.emit()


# ------------------------------------------------------------------ déplacement

func _can_stand(u: Unit, c: Vector2i) -> bool:
	return board.walkable(c) or (board._in(c) and board.kind[c] == "water" and u.has_p("eau"))


func reach(u: Unit) -> Dictionary:
	## prev : case -> case précédente ; cells : cases où l'unité peut s'arrêter.
	var mv: int = u.move - (1 if u.has_meta("englue") else 0)
	var prev := {u.cell: u.cell}
	var d := {u.cell: 0}
	var q: Array = [u.cell]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		if d[c] >= mv:
			continue
		for dir in Board.DIRS:
			var n: Vector2i = c + dir
			if d.has(n) or not board._in(n):
				continue
			var ok: bool = _can_stand(u, n) or (u.fly and board.kind[n] == "water")
			if not ok:
				continue
			if not u.fly and absi(board.h[n] - board.h[c]) > u.jump:
				continue
			var o := unit_at(n)
			if o and o.side != u.side:
				continue
			var step := 2 if ground.get(n, "") == "vase" and not u.fly and not (u.side == "hero" and has("semelles_jonc")) else 1
			if d[c] + step > mv:
				continue
			d[n] = d[c] + step
			prev[n] = c
			q.append(n)
	var cells := {}
	for c in prev:
		if c == u.cell or (_can_stand(u, c) and unit_at(c) == null):
			cells[c] = true
	return {"prev": prev, "cells": cells, "dist": d}


func path_to(prev: Dictionary, c: Vector2i) -> Array:
	var p: Array = []
	while prev[c] != c:
		p.push_front(c)
		c = prev[c]
	return p


# ------------------------------------------------------------------ cartes

func card_range(c: Dictionary, h: Unit) -> Vector2i:
	var r: Array = c.get("range", [0, 0])
	var hi: int = r[1]
	if hi > 1 and h.trait_id == "myope":
		hi -= 1
	if hi > 1 and h.trait_id == "lynx":
		hi += 1
	if hi > 2 and mods.has("brume") and not powers.has("aelis"):
		hi -= 1
	if hi > 1 and h.has_p("concentration"):
		hi += 1
	if hi > 1 and powers.has("aelis") and int(power_val.get("aelis", 0)) >= 1:
		hi += 1  # Œil perce-brume niveau 3
	return Vector2i(r[0], hi)


func target_list() -> Array:
	## Le menu des cibles de la carte choisie : les unités de la plus proche à la plus lointaine, puis arbres et objets.
	## Les cartes de case (placer, se téléporter) n'en ont pas : leurs cibles sont des cases vides.
	if card_sel < 0 or card_sel >= hand.size():
		return []
	var c := Data.card(hand[card_sel])
	var h := owner_of(c)
	if h == null or c.get("target", "foe") in ["self", "tile"]:
		return []
	var out: Array = card_targets(c, h).filter(func(t): return unit_at(t) != null or board.props.has(t) or oaks.has(t))
	var rank := func(t: Vector2i) -> int:
		return (0 if unit_at(t) != null else (1 if oaks.has(t) else 2)) * 1000 + dist(h.cell, t)
	out.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	return out


func target_label(t: Vector2i) -> String:
	var u := unit_at(t)
	var d := dist(active.cell, t) if active else 0
	if u:
		return "%s · %d PV" % [u.nm, u.hp] + ("" if d == 0 else " · %d case%s" % [d, "s" if d > 1 else ""])
	var nm: String = "Arbre" if oaks.has(t) else {"brasero": "Brasero", "baril": "Baril", "bombe_retard": "Bombe", "pilier": "Pilier",
		"coffre": "Coffre"}.get(board.props.get(t, ""), str(board.props.get(t, "")).capitalize())
	return "%s · %d case%s" % [nm, d, "s" if d > 1 else ""]


func card_targets(c: Dictionary, h: Unit) -> Array:
	if c.has("tool"):
		return tool_targets(c.tool, h, c.get("range", Data.TOOLS[c.tool].get("range", [0, 0])))
	var out: Array = []
	var r := card_range(c, h)
	match c.get("target", "foe"):
		"self":
			out.append(h.cell)
		"ally":
			for a in alive_heroes():
				var dd := dist(h.cell, a.cell)
				if dd >= r.x and dd <= r.y:
					out.append(a.cell)
		"tile":
			for x in board.dim:
				for z in board.dim:
					var t := Vector2i(x, z)
					var dd := dist(h.cell, t)
					if dd < r.x or dd > r.y:
						continue
					if c.id == "ombre" or c.get("blink", false):
						if board.walkable(t) and unit_at(t) == null and (not c.get("near_ally", false) or alive_heroes().any(func(a): return a != h and dist(a.cell, t) == 1)):
							out.append(t)
					elif c.has("place"):
						if board.walkable(t) and unit_at(t) == null and not traps.has(t):
							out.append(t)
					elif board.kind[t] != "tower":
						out.append(t)
		"line":
			# ruée : jusqu'à r.y cases par le plus court chemin (plus seulement en ligne droite), puis le coup au contact
			var R := _dash_reach(h, r.y)
			for cell in R:
				if cell != h.cell:
					out.append(cell)
			var hits: Array = alive_foes().map(func(f): return f.cell) + oaks.keys()
			for pc in board.props:
				if board.props[pc] in BOOM + ["pilier"]:
					hits.append(pc)
			for t in hits:
				if not out.has(t) and _dash_path(h, t, r.y, R) != null:
					out.append(t)
		_:
			var cells: Array = [] if c.get("detonate", false) else alive_foes().map(func(f): return f.cell)
			for pc in board.props:
				if board.props[pc] in (BOOM if c.get("detonate", false) else BOOM + ["pilier", "coffre"]):
					cells.append(pc)
			if not c.get("detonate", false) and c.get("kind", "") == "atk":
				cells.append_array(oaks.keys())  # tout arbre se coupe
			for t in cells:
				var dd := dist(h.cell, t)
				if dd < r.x or dd > r.y:
					continue
				if r.y == 1 and absi(board.h[h.cell] - board.h[t]) > 3:
					continue
				if dd > 1 and smoke.has(t) and not powers.has("aelis"):
					continue  # fumée : on n'y vise pas de loin
				out.append(t)
	return out


func range_cells(c: Dictionary, h: Unit) -> Array:
	var out: Array = []
	var r := card_range(c, h)
	if c.get("target", "foe") == "self":
		return out
	for x in board.dim:
		for z in board.dim:
			var t := Vector2i(x, z)
			var dd := dist(h.cell, t)
			if dd >= maxi(r.x, 1) and dd <= r.y and board.kind[t] != "tower":
				out.append(t)
	return out


func play_card(i: int, t: Vector2i) -> void:
	var ci: Dictionary = hand[i]
	var c := Data.card(ci)
	var h := owner_of(c)
	if h.lvl_next and not c.get("lvl_next", false) and Data.level(ci) < Data.lvl_cap(ci):
		# Geste technique : la carte monte d'un niveau jusqu'à la fin du combat
		h.lvl_next = false
		ci["bump"] = int(ci.get("bump", 0)) + 1
		c = Data.card(ci)
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Geste technique : niveau %d" % c.lvl, GOLD_FX)
	var cost := cost_of(c)
	if energy < cost or (c.has("xcost") and energy - cost < 1):
		return
	_faced = false
	_move_plan = null
	_lifesteal = c.get("lifesteal", false)
	if int(c.get("pay_gold", 0)) > main.gold:
		main.ui.toast("Pas assez d'or.")
		return
	if int(c.get("pay_gold", 0)) > 0:
		main.gold -= int(c.pay_gold)
		main.ui.set_gold(main.gold)
		Fx.number(main, h.position + Vector3(0, 1.3, 0), "−%d or" % int(c.pay_gold), GOLD_FX)
	if ci.has("chg"):
		c["_chg"] = int(ci.chg)
	if cost < int(c.cost) and not first_free and h.has_p("economie"):
		_eco_used[h] = true
	energy -= cost
	if int(Data.def(c.id).get("cost", 0)) == 1:
		first_free = false  # Clepsydre verte : consommée par la première carte à 1
	if h.triple and c.kind == "atk":
		cost = 0
	if c.has("xcost"):
		# coût X : toute l'énergie restante, chaque point renforce la carte
		var x := energy
		energy = 0
		for f in c.xcost:
			c[f] = int(c.get(f, 0)) + int(c.xcost[f]) * x
		Fx.number(main, h.position + Vector3(0, 1.2, 0), "X = %d" % x, GOLD_FX, true)
	if c.get("drop_hits", false):
		c["hits"] = 1 + h.bpm / 2
		c["drop"] = 0  # remet le BPM à zéro comme un Drop
	if c.has("drop"):
		# Drop : le BPM monté par les cartes précédentes part d'un coup
		var dv: int = int(c.drop) * h.bpm
		if c.kind == "atk":
			c["_dropv"] = dv
		elif c.has("block"):
			c.block = int(c.block) + dv
		if h.bpm > 0:
			Fx.number(main, h.position + Vector3(0, 1.4, 0), "Drop ! ♪ %d" % h.bpm, Color(0.95, 0.5, 0.8), true)
	_overload = false
	var ov_go: bool = c.has("overload") and energy >= int(c.overload) - cost and int(c.overload) > cost
	if ov_go and not main._testing():
		# un choix, pas une taxe : on surcharge si on le veut
		var k: int = await main.ui.choose("SURCHARGE", "%s : dépenser %d mana de plus pour toucher chaque ennemi ?" % [c.name, int(c.overload) - cost], [
			{"title": "Surcharger · +%d mana" % (int(c.overload) - cost), "glyph": "⚡", "text": "La carte touche chaque ennemi.", "color": Color(0.5, 0.8, 1.0)},
			{"title": "Jouer normalement", "glyph": "•", "text": "Une seule cible, rien de plus à payer.", "color": UI.GOLD}])
		ov_go = k == 0
	if ov_go:
		energy -= int(c.overload) - cost
		_overload = true
		Fx.number(main, h.position + Vector3(0, 1.2, 0), "Surcharge !", Color(0.5, 0.8, 1.0), true)
	if not c.cls.has(h.key):
		masque_used = true
	if has("plume") and not plume_used and c.cls != [h.key]:
		plume_used = true
		draw(1)
	if not played_ids.has(h):
		played_ids[h] = []
	played_ids[h].append(ci.id)
	if not played_lvl.has(h):
		played_lvl[h] = {}
	played_lvl[h][ci.id] = maxi(int(played_lvl[h].get(ci.id, 1)), int(ci.get("lvl", 1)))
	hand.remove_at(i)
	card_sel = -1
	busy = true
	board.highlight({})
	log_add("%s joue %s" % [h.nm, c.name])
	main.ui.announce(c)
	changed.emit()
	var pre := _trig_ok(c, h, t)
	_killed = false
	_struck = null
	if c.get("selfdmg", 0) > 0:
		# le prix en PV ne tue jamais
		var cost_hp := mini(int(c.selfdmg), h.hp - 1)
		h.hp -= cost_hp
		if cost_hp > 0:
			hurt_turn = true
			_berserk(h)
			if h.has_p("trait_sang"):
				h.bpm = mini(12, h.bpm + 2)  # Trait de sang
		Fx.number(main, h.position + Vector3(0, 0.3, 0), "-%d PV" % cost_hp, Color(0.8, 0.45, 1.0))
		h.hurt()
	_pre = pre
	_resolving = true
	await resolve(c, h, t)
	if c.has("gives"):
		_gives(c.gives, h)
	if c.kind == "atk" and c.get("draw", 0) > 0:
		draw(c.draw)
	for vk in ["voix", "voix2"]:
		if c.has(vk) and not voices.has(c[vk]):
			voices.append(c[vk])
	if voices.size() >= 3 and h.has_p("nuancier") and h.get_meta("nuancier_round", -1) != turn:
		h.set_meta("nuancier_round", turn)  # Nuancier : les trois voix dans le tour
		energy += 1
		h.bpm = mini(12, h.bpm + 2)
		Fx.number(main, h.position + Vector3(0, 1.5, 0), "Crescendo · +1 énergie", GOLD_FX)
	var refund := false
	if c.has("trig") and (pre or (c.trig.on == "grace" and _killed) or (c.trig.on == "butin" and stolen_turn > 0)) and h.alive:
		refund = _trig_apply(c, h, t)
		if c.trig.on == "immobile":
			h.moved = true  # Ancré : le héros reste planté
	played += 1
	tambour += 1
	if has("tambour") and tambour % 4 == 0 and h.alive:
		energy += 1
		Fx.number(main, h.position + Vector3(0, 1.4, 0), "174 BPM · +1 énergie", GOLD_FX)
	if has("galet") and played == 3 and h.alive:
		gain_block(h, 4)
	if has("echo_caverne") and not _echo_cav and c.kind == "atk":
		_echo_cav = true  # Écho de caverne : la première attaque du combat est jouée deux fois
		echo = true
	if echo and not c.get("echo", false) and c.kind != "power" and h.alive and not over:
		echo = false
		if c.get("target", "foe") in ["self", "tile", "line", "ally"] or card_targets(c, h).has(t):
			Fx.number(main, h.position + Vector3(0, 0.9, 0), "Écho", Color(0.85, 0.7, 1.0))
			await wait(0.2)
			await resolve(c, h, t)
	_resolving = false
	# concile du 29/09 : le ×3 d'Iaï et l'armure dépensée valent pour toute attaque (zone, dispersion), écho compris
	if h.triple and c.kind == "atk":
		h.triple = false
	if c.get("spend_block", 0.0) > 0.0 and h.block > 0:
		h.block -= int(h.block * float(c.spend_block))
	h.bpm = 0 if c.has("drop") else mini(12, h.bpm + 1 + int(c.get("bpm", 0)))
	if h.bpm >= 3 and _bpm_hero(h):
		Fx.number(main, h.position + Vector3(0.4, 1.6, 0), "♪ %d" % h.bpm, Color(0.95, 0.5, 0.8))
	if powers.has("kaede") and power_owner.get("kaede") == h and played == 3 and h.alive and not over:
		await _kaede(h)
	if powers.has("coupures") and not over:
		var live := alive_foes()
		if live.size() > 0:
			var v: Unit = live[randi() % live.size()]
			Fx.burst(main, v.position + Vector3(0, 0.7, 0), Data.CLASS_COLOR.lame, 14, 2.5)
			damage(v, 1 + int(power_val.get("coupures", 0)))
	ci.erase("free")
	ci.erase("cut")
	ci.erase("chg")
	played_turn.append(ci.duplicate())
	if refund:
		hand.append(ci)
	elif c.get("eph", false):
		pass
	elif c.has("tool"):
		if _spend_obj(ci, true) and has("goupille") and h.alive:  # charges : une de moins ; à zéro, la carte quittera le paquet en fin de combat
			_gain_energy(h, 1)
			Fx.number(main, h.position + Vector3(0, 1.4, 0), "Goupille · +1 énergie", GOLD_FX)
	elif c.get("exhaust", false) or c.kind == "power":
		exhausted.append(ci)
		if c.kind != "power" and not c.get("flashback", false):
			last_exhausted[h] = {"id": ci.id, "lvl": Data.level(ci)}
		if c.kind != "power":
			exhaust_n[h] = int(exhaust_n.get(h, 0)) + 1
			if h.has_p("decrue"):
				heal(h, 2, true)  # Décrue : chaque carte Épuisée soigne 2, le trop déborde
	else:
		discard.append(ci)
	busy = false
	changed.emit()
	coach.emit("done", ci.id)
	_after_action()


func resolve(c: Dictionary, h: Unit, t: Vector2i) -> void:
	if c.has("tool"):
		# objet : l'effet de l'outil, monté au niveau de la carte
		c = _tour_de_main(c, h)
		if powers.has("oriel") and not oriel_turn and DOUBLABLE.has(c.tool):
			oriel_turn = true
			item_echo = h
			if int(power_val.get("oriel", 0)) > 0:
				draw(int(power_val.oriel))  # La Double Dose niveau 3
		_sim("objet_niv%d" % c.lvl)
		await _apply_tool(c.tool, h, t, c)
		if c.get("draw", 0) > 0 and c.tool != "carnet":
			draw(int(c.draw))
		if c.get("energy", 0) > 0:
			energy += int(c.energy)
		_item_consumed(h)
		return
	var tgt: String = c.get("target", "foe")
	var col: Color = Data.CLASS_COLOR[c.owner]
	if c.kind == "power":
		await h.cast()
		powers.append(c.power)
		power_owner[c.power] = h
		power_val[c.power] = maxi(int(power_val.get(c.power, 0)), int(c.get("val", 0)))
		power_val[c.power + "2"] = maxi(int(power_val.get(c.power + "2", 0)), int(c.get("val2", 0)))
		if c.get("block", 0) > 0:
			for a in alive_heroes():
				gain_block(a, c.block)
		Fx.burst(main, h.position + Vector3(0, 0.8, 0), col.lightened(0.3), 50, 2.5, 5.0)
		Fx.number(main, h.position + Vector3(0, 0.6, 0), c.name, col.lightened(0.4))
		return
	if c.get("scatter", 0) > 0:
		await h.cast()
		var near: Array = []
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			if o and o.side == "foe":
				near.append(o)
		var seen := {}  # cible -> frappée de dos au moins une fois
		for k in int(c.scatter):
			near = near.filter(func(o): return o.alive)
			if near.is_empty():
				break
			var o: Unit = near[k % near.size()]
			await h.lunge(o.position)
			var back := _is_back(h, o)
			damage(o, hit_dmg(h, o, c, _base(c, h, o.cell), 1 if seen.has(o) else 0).dmg, h)
			seen[o] = back or seen.get(o, false)
			_on_hit(h, o, back)
			await wait(0.08)
		h.ambush = false
		for o in seen:
			if seen[o] and o.alive and not o.data.get("structure", false):
				o.face(h.cell - o.cell)
		_count_hit(h)
		return
	if c.get("around", false):
		await h.cast()
		main.shake(0.3)
		var tele: bool = c.get("back_if_tele", false) and h.tele
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			Fx.burst(main, board.world(h.cell + d) + Vector3(0, 0.4, 0), col.lightened(0.3), 16, 3.0)
			if o and o.side == "foe":
				if tele:
					h.ambush = true
				var back := _is_back(h, o)
				damage(o, hit_dmg(h, o, c, _base(c, h, o.cell)).dmg, h)
				_on_hit(h, o, back)
				if back and o.alive and not o.data.get("structure", false):
					o.face(h.cell - o.cell)
				if o.alive and c.get("push", 0) > 0:
					crash_bonus = int(c.get("crash", 0))
					await push(o, d, c.push)
					crash_bonus = 0
			elif board.props.get(h.cell + d, "") in BOOM + ["pilier"]:
				await trigger_prop(h.cell + d, d)
		h.ambush = false
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
		_count_hit(h)
		await wait(0.3)
		return
	if c.has("place"):
		if c.get("consume", false) and (await _consume(h)) == "":
			return
		await _place(c, t, h)
		if c.has("ground"):
			_ground_cells([t] + (Board.DIRS.map(func(d): return t + d) if c.get("aoe", false) else []), c.ground)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
		if c.get("recharge", 0) > 0:
			await _recharge(h, int(c.recharge))
		if c.get("energy", 0) > 0:
			energy += c.energy
		if c.has("rune") and not tiles.has(t):
			tiles[t] = c.rune
			_make_tile(t, c.rune)
		if c.get("lure", 0) > 0:
			await _lure(t, c.lure)
		if c.get("ambush", false):
			h.ambush = true
		return
	if tgt == "tile" and not c.get("aoe", false) and not c.get("blink", false) and c.id != "ombre":
		h.face(t - h.cell)
		await h.cast()
		if c.get("smoke", 0) > 0:
			for cc in [t] + Board.DIRS.map(func(d): return t + d):
				if board._in(cc) and board.kind[cc] != "tower":
					_smoke(cc, c.smoke)
		# la rune d'abord : l'ennemi attiré marche dessus au lieu de l'empêcher
		if c.has("rune") and board.walkable(t) and unit_at(t) == null and not tiles.has(t):
			tiles[t] = c.rune
			_make_tile(t, c.rune)
		if c.get("lure", 0) > 0:
			await _lure(t, c.lure)
		if c.get("omen", 0) > 0:
			_omen(t, int(c.omen), h)
		if c.has("ground"):
			_ground_cells([t], c.ground)
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		return
	if tgt == "self":
		h.cast()
		if c.get("per_missing_block", 0) > 0 and c.has("block"):
			c = c.duplicate()
			c.block = int(c.block) + int(c.per_missing_block) * ((h.max_hp - h.hp) / 5)
		await _self_fx(c, h)
		if c.has("ground"):
			_ground_cells(Board.DIRS.map(func(d): return h.cell + d), c.ground)
		if c.get("heal", 0) > 0:
			heal(h, c.heal, c.get("spill", false))
		if c.get("energy", 0) > 0:
			energy += c.energy
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "+%d énergie" % c.energy, GOLD_FX)
		if c.get("ambush", false):
			h.ambush = true
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "Embuscade", col.lightened(0.4))
		if c.get("echo", false):
			echo = true
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "Écho", col.lightened(0.4))
		if c.has("block"):
			for a in (alive_heroes() if c.get("all", false) else [h]):
				gain_block(a, c.block)
			if c.get("adj", false):
				for a in alive_heroes():
					if a != h and dist(a.cell, h.cell) == 1:
						gain_block(a, c.block)
		if c.get("craft", 0) > 0:
			_craft(c.craft, h, int(c.get("craft_min", 1)))
		if c.get("taunt", false):
			h.taunt = true
			Fx.number(main, h.position + Vector3(0, 0.4, 0), "Défi !", Color(1, 0.8, 0.4))
		if c.has("heal_all"):
			for a in alive_heroes():
				heal(a, c.heal_all)
				_onguent(h, a)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await wait(0.3)
		return
	if tgt == "ally":
		h.face(t - h.cell)
		await h.cast()
		var a := unit_at(t)
		if a and c.get("swap", false) and a != h:
			var hc := h.cell
			var ac := a.cell
			h.cell = Vector2i(-99, -99)
			await a.teleport(hc, board)
			await h.teleport(ac, board)
			_teleported(a)
			_teleported(h)
		if a:
			if c.get("heal_from_block", false) and a != h:
				c = c.duplicate()
				c.heal = int(c.get("heal", 0)) + h.block
				if h.block > 0:
					Fx.number(main, h.position + Vector3(0, 0.8, 0), "Armure transférée", Color(0.7, 0.85, 0.95))
				h.block = 0
			if c.get("heal", 0) > 0:
				var amt := int(c.heal * (1.5 if a.trait_id == "beni" else 1.0))
				var extra := maxi(0, amt - (a.max_hp - a.hp))
				heal(a, c.heal, c.get("spill", false) and not c.get("overheal", false))
				if c.get("overheal", false) and extra > 0:
					gain_block(a, extra * 2)
				_onguent(h, a)
			if c.get("block", 0) > 0:
				gain_block(a, c.block)
		if c.get("ambush", false):
			h.ambush = true
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await wait(0.2)
		return
	if c.id == "ombre" or c.get("blink", false):
		Fx.burst(main, h.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 30, 2.0)
		await h.teleport(t, board)
		_teleported(h)
		Fx.burst(main, h.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 30, 2.0)
		if loot.has(h.cell):
			_pick_loot(h, h.cell)
		if c.get("ambush", false):
			h.ambush = true
			Fx.number(main, h.position + Vector3(0, 0.8, 0), "Embuscade", col.lightened(0.4))
		if c.get("iblock", 0) > 0 and stock() > 0:
			gain_block(h, int(c.iblock) * stock())
		if c.get("block", 0) > 0:
			gain_block(h, c.block)
			if c.get("near_ally", false):
				for a in alive_heroes():
					if a != h and dist(a.cell, h.cell) == 1:
						gain_block(a, c.block)
		if c.get("craft", 0) > 0:
			_craft(c.craft, h, int(c.get("craft_min", 1)))
		if c.get("energy", 0) > 0:
			energy += c.energy
		if c.get("hitcount", false):
			h.hits += 1
			_count_hit(h)
		if c.get("dmg", 0) > 0:
			# Bond de grue niveau 3 : l'atterrissage frappe les voisins
			main.shake(0.3)
			for d in Board.DIRS:
				var o := unit_at(h.cell + d)
				if o and o.side == "foe":
					damage(o, calc(h, o, c.dmg, c).dmg, h)
		if c.get("draw", 0) > 0:
			draw(c.draw)
		await _landed(h)
		_check_portal(h)
		return
	if tgt == "line":
		await charge(h, t, c)
		return
	if c.get("aoe", false):
		if c.get("need_item", false) and (await _consume(h)) == "":
			c = c.duplicate()
			c.dmg = 0
		h.face(t - h.cell)
		await h.cast()
		await Fx.bolt(main, h.position, board.world(t), col)
		main.shake(0.25)
		var cells := [t]
		for d in Board.DIRS:
			cells.append(t + d)
		if _overload:
			cells = alive_foes().map(func(f): return f.cell)
		for cell in cells:
			if board._in(cell):
				Fx.burst(main, board.world(cell) + Vector3(0, 0.2, 0), col, 16, 3.5, 3.0)
			var u := unit_at(cell)
			if u and u.side == "foe":
				_blast = c.owner in ["artificier", "oracle"]  # grenades, mortier, cendre : du feu
				damage(u, hit_dmg(h, u, c, _base(c, h, t)).dmg, h, true, true)
				_blast = false
				if u.alive and int(c.get("root", 0)) > 0:
					u.root = maxi(u.root, int(c.root))  # Pluie de flèches niveau 3
			elif oaks.has(cell):
				_hit_tree(cell, _base(c, h, t) + h.gear_dmg() + h.dmg_bonus, c.owner in ["artificier", "oracle"])
			elif board.props.get(cell, "") in BOOM:
				await trigger_prop(cell, _dir(h.cell, cell))
		if c.has("ground"):
			_ground_cells(cells, c.ground)
		if c.get("aoe_baril", false) and board.walkable(t) and unit_at(t) == null and not board.props.has(t) and not traps.has(t):
			board.props[t] = "baril"
			_make_prop(t)
		await wait(0.3)
		return
	var f := unit_at(t)
	if f and _overload and f.side == "foe":
		for o in alive_foes():
			if not over:
				await attack(h, o, c)
	elif f:
		await attack(h, f, c)
	elif oaks.has(t):
		h.face(t - h.cell)
		if card_range(c, h).y > 1:
			await h.cast()
			await Fx.bolt(main, h.position, board.world(t), col.lightened(0.3))
		else:
			await h.lunge(board.world(t))
		_hit_tree(t, _base(c, h, t) + h.gear_dmg() + h.dmg_bonus)
	elif board.props.has(t):
		h.face(t - h.cell)
		if card_range(c, h).y > 1:
			await h.cast()
			await Fx.bolt(main, h.position, board.world(t), col.lightened(0.3))
		else:
			await h.lunge(board.world(t))
		if board.props.get(t, "") == "coffre":
			await _open_chest(h, t)  # un coup suffit à faire sauter le couvercle
		else:
			await trigger_prop(t, _dir(h.cell, t))
			if c.get("craft_id", "") != "":
				_craft_id(c.craft_id, 1, h)


func attack(h: Unit, f: Unit, c: Dictionary) -> void:
	_struck = f
	var col: Color = Data.CLASS_COLOR[c.owner]
	var origin := h.cell
	if c.get("rechute", false) and h.hp * 10 < h.max_hp * 3:
		await h.cast()
		heal(h, 12)
		return
	if c.get("shadow_ally", false):
		var ally: Unit = h
		for a in alive_heroes():
			if a != h and (ally == h or dist(a.cell, f.cell) < dist(ally.cell, f.cell)):
				ally = a
		await _go_behind(ally, f)
		ally.ambush = true
		Fx.number(main, ally.position + Vector3(0, 0.8, 0), "Dans son dos", col.lightened(0.4))
		if f.alive and c.get("mark", 0) > 0:
			f.mark = maxi(f.mark, c.mark)
		return
	if c.get("behind", false):
		await _go_behind(h, f)
		h.ambush = true
	elif c.get("dash", false) and dist(h.cell, f.cell) > 1:
		var best := h.cell
		for d in Board.DIRS:
			var n: Vector2i = f.cell + d
			if board.walkable(n) and unit_at(n) == null and (best == h.cell or dist(n, h.cell) < dist(best, h.cell)):
				best = n
		if best != h.cell:
			await h.teleport(best, board)
			_teleported(h)
	elif c.get("vault", false):
		var land: Vector2i = f.cell + (f.cell - h.cell)
		if board.walkable(land) and unit_at(land) == null:
			await h.teleport(land, board)
			_teleported(h)
	h.face(f.cell - h.cell)
	main.punch((h.position + f.position) * 0.5)
	f.set_xray(true)
	var ranged: bool = card_range(c, h).y > 1 and not c.get("behind", false) and not c.get("dash", false)
	if c.get("steal", false) and not _steal(h, f) and c.get("craft_else", false):
		_craft(1, h)
	if c.get("throw", false):
		await _throw_item(h, f.cell)
		if not f.alive:
			return
	var no_item: bool = c.get("need_item", false) and (await _consume(h)) == ""
	var base := _base(c, h, f.cell)
	if no_item:
		base = 0
	if c.get("pierce", false) and f.block > 0:
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "Perce", col.lightened(0.4))
		f.block = 0
	if c.get("delve", false):
		base = (2 + int(c.get("val", 0))) * discard.size()
		exhausted.append_array(discard)
		discard.clear()
	var had_poison := f.poison > 0
	if c.get("bph", 0) > 0:
		h.bph = int(c.bph)
	var dealt := 0
	var pivot := false  # frappé de dos, l'ennemi se retourne vers son agresseur après la carte
	var n_hits: int = (1 + played) if c.get("hits_flow", false) else int(c.get("hits", 1))
	for k in n_hits:
		if not f.alive:
			break
		if ranged:
			await h.cast()
			await Fx.bolt(main, h.position, f.position, col.lightened(0.3))
		else:
			await h.lunge(f.position)
		var back := _is_back(h, f)
		pivot = pivot or back
		var dm: int = hit_dmg(h, f, c, base, k).dmg
		dealt += dm
		damage(f, dm, h, true, ranged)
		f.exposed = false
		h.struck = true
		if base > 0 or c.get("dmg", 0) > 0:
			_on_hit(h, f, back)
		await wait(0.12)
	if f.alive and dealt > 0 and (c.get("exec", false) or h.has_p("execution")):
		_execute(h, f)
	h.ambush = false
	if pivot and f.alive and not f.data.get("structure", false):
		f.face(h.cell - f.cell)
		Fx.number(main, f.position + Vector3(0, 1.3, 0), "Se retourne", Color(1.0, 0.75, 0.45))
	if h.triple and c.kind == "atk":
		h.triple = false
	if c.get("heal_adj", false) and dealt > 0:
		var w: Unit = null
		for a in alive_heroes():
			if a != h and dist(a.cell, h.cell) <= 2 and a.hp < a.max_hp and (w == null or a.hp * w.max_hp < w.hp * a.max_hp):
				w = a
		if w:
			heal(w, dealt, c.get("spill", false))
			_onguent(h, w)
	if c.get("craft_id", "") != "":
		_craft_id(c.craft_id, 1, h)
	if c.get("det_near", false) or c.get("volt", false):
		for pc in board.props.keys():
			if board.props.get(pc, "") in BOOM and (dist(pc, f.cell) <= (3 if c.get("volt", false) else 1)):
				await trigger_prop(pc, _dir(f.cell, pc))
				if not c.get("volt", false):
					break
	if f.alive and c.get("stick", 0) > 0:
		f.stick = int(c.stick)
		Fx.number(main, f.position + Vector3(0, 0.9, 0), "Charge collée", EMBER)
	if f.alive and c.get("bounty", false):
		f.bounty = true
	if f.alive and c.get("delay", 0) > 0:
		_delay(f, int(c.delay))
	if c.get("rechute", false):
		var lose := mini(4, h.hp - 1)
		h.hp -= lose
		Fx.number(main, h.position + Vector3(0, 0.3, 0), "-%d PV" % lose, Color(0.8, 0.45, 1.0))
	if c.get("decoupe", false) and not f.alive and (elite_fight or f.affix != "" or f.key == "gardien"):
		pending_relics += 1
		Fx.number(main, f.position + Vector3(0, 1.2, 0), "Découpe : une relique !", GOLD_FX, true)
	if c.get("iblock", 0) > 0:
		gain_block(h, int(c.iblock) * stock())
	if c.get("recharge", 0) > 0:
		await _recharge(h, int(c.recharge))
	if c.get("leech", 0) > 0:
		heal(h, c.leech)
	if c.kind == "atk" and c.get("block", 0) > 0:
		gain_block(h, c.block)
	if f.alive and c.get("mark", 0) > 0:
		f.mark = maxi(f.mark, c.mark)
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "◎ Marqué", Color(1.0, 0.85, 0.4))
	if f.alive and c.get("root", 0) > 0:
		f.root = maxi(f.root, c.root)
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
	if f.alive and c.get("pull", 0) > 0:
		if has("hamecon"):
			f.mark = maxi(f.mark, 1)
		var n := mini(c.pull + (1 if has("hamecon") else 0), dist(h.cell, f.cell) - 1)
		if n > 0:
			_pulling = true
			await push(f, _dir(f.cell, h.cell), n)
			_pulling = false
	if c.get("chain", 0) > 1:
		var hit: Array = [f]
		var last := f
		for k in c.chain - 1:
			var nxt: Unit = null
			for o in alive_foes():
				if not hit.has(o) and dist(o.cell, last.cell) <= 3 and (nxt == null or dist(o.cell, last.cell) < dist(nxt.cell, last.cell)):
					nxt = o
			if nxt == null:
				break
			await Fx.bolt(main, last.position, nxt.position, col.lightened(0.3))
			damage(nxt, hit_dmg(h, nxt, c, base).dmg, h, true, true)
			hit.append(nxt)
			last = nxt
	_count_hit(h)
	if f.alive and c.get("poison", 0) > 0:
		var pz: int = int(c.poison) * (2 if c.get("x2_marked", false) and f.mark > 0 else 1) + (1 if has("vessie") else 0)
		f.poison += pz
		if c.get("poison_x2", false) and had_poison:
			f.poison *= 2
		Fx.number(main, f.position + Vector3(0, 0.4, 0), "☠ %d" % f.poison, Color(0.6, 0.9, 0.3))
	if c.get("consume_root", 0) > 0 and f.alive and f.root > 0:
		f.root = 0
		Fx.number(main, f.position + Vector3(0, 0.9, 0), "Libéré", Color(0.8, 0.9, 1.0))
	if c.get("taunt", false):
		h.taunt = true
		Fx.number(main, h.position + Vector3(0, 0.4, 0), "Défi !", Color(1, 0.8, 0.4))
	if c.get("expose", false) and f.alive:
		f.exposed = true
		Fx.number(main, f.position + Vector3(0, 1.0, 0), "Exposé", Color(1.0, 0.75, 0.45))
	if c.get("trap_behind", false) and f.alive:
		var tb: Vector2i = f.cell + _dir(h.cell, f.cell)
		if board._in(tb) and board.walkable(tb) and unit_at(tb) == null and not traps.has(tb):
			_make_trap(tb, "piege", int(c.get("tdmg", 8)))
	if c.has("ground_behind") and f.alive:
		var gb: Vector2i = f.cell + _dir(h.cell, f.cell)
		if unit_at(gb) == null:
			_ground_cells([gb], c.ground_behind)
	if f.alive and c.get("push", 0) > 0:
		double_trap = c.get("trap2", false)
		crash_bonus = int(c.get("crash", 0))
		await push(f, _dir(h.cell, f.cell), c.push)
		crash_bonus = 0
		double_trap = false
	if c.get("recoil", 0) > 0 and h.alive:
		await push(h, _dir(f.cell, h.cell), int(c.recoil))
	if c.get("ret", false) and h.alive and h.cell != origin and unit_at(origin) == null:
		await h.teleport(origin, board)
		_teleported(h)
	if c.get("bounce", false):
		for d in Board.DIRS:
			var o := unit_at(f.cell + d)
			if o and o.side == "foe":
				await Fx.bolt(main, f.position, o.position, col.lightened(0.3))
				damage(o, hit_dmg(h, o, c, base).dmg, h, true, true)
				break
	if c.get("omen", 0) > 0 and f.alive:
		_omen(f.cell, int(c.omen), h)
	f.set_xray(false)
	await wait(0.15)


func _dash_reach(h: Unit, n: int) -> Dictionary:
	## Cases libres qu'une ruée atteint en n pas au plus (cellule -> [pas, précédente]) : ni unité, ni objet, ni arbre, marches de 2 au plus.
	var R := {h.cell: [0, h.cell]}
	var q: Array = [h.cell]
	var i := 0
	while i < q.size():
		var p: Vector2i = q[i]
		i += 1
		if R[p][0] >= n:
			continue
		for d in Board.DIRS:
			var nx: Vector2i = p + d
			if R.has(nx) or not board.walkable(nx) or absi(board.h[nx] - board.h[p]) > 2 or unit_at(nx) or board.props.has(nx) or oaks.has(nx):
				continue
			R[nx] = [R[p][0] + 1, p]
			q.append(nx)
	return R


func _dash_path(h: Unit, t: Vector2i, n: int, R := {}):
	## Le chemin d'une ruée vers t : jusqu'à t s'il est libre, sinon jusqu'à la case voisine la plus proche (en n-1 pas), d'où frapper.
	## null : hors d'atteinte.
	if R.is_empty():
		R = _dash_reach(h, n)
	var end = null
	if R.has(t):
		end = t
	else:
		for d in Board.DIRS:
			var e: Vector2i = t - d
			if R.has(e) and R[e][0] <= n - 1 and absi(board.h[e] - board.h[t]) <= 2 and (end == null or R[e][0] < R[end][0] or (R[e][0] == R[end][0] and _dir(h.cell, t) == d)):
				end = e
	if end == null:
		return null
	var path: Array = []
	var p: Vector2i = end
	while p != h.cell:
		path.push_front(p)
		p = R[p][1]
	return path


func charge(h: Unit, t: Vector2i, c: Dictionary) -> void:
	var path = _dash_path(h, t, card_range(c, h).y)
	if path == null:
		return
	if path.size() > 0:
		await h.walk(path, board)
		for pc in path:
			if loot.has(pc):
				_pick_loot(h, pc)
	if h.cell == t:
		face_nearest(h)
		return
	var d := _dir(h.cell, t)  # le sens de l'arrivée : c'est là que part la poussée
	h.face(d)
	var nx := t
	var f := unit_at(nx)
	if f and f.side == "foe":
		await h.lunge(f.position)
		damage(f, hit_dmg(h, f, c, _base(c, h, nx)).dmg, h)
		if f.alive and c.get("push", 0) > 0:
			crash_bonus = int(c.get("crash", 0))
			await push(f, d, c.push)
			crash_bonus = 0
	elif board.props.get(nx, "") in BOOM + ["pilier"]:
		await h.lunge(board.world(nx))
		await trigger_prop(nx, d)
	elif oaks.has(nx):
		await h.lunge(board.world(nx))
		_hit_tree(nx, _base(c, h, nx) + h.gear_dmg() + h.dmg_bonus)


func _dir(a: Vector2i, b: Vector2i) -> Vector2i:
	var d := b - a
	if absi(d.x) >= absi(d.y):
		return Vector2i(signi(d.x), 0)
	return Vector2i(0, signi(d.y))


# ------------------------------------------------------------------ dégâts

var _gone: Array = []  # fuyards échappés, cachés jusqu'au combat suivant
var _cause := ""  # comment l'unité qui tombe a été achevée : "eau", "piege" (défis des porteurs de carte)


func _card_mark(f: Unit) -> void:
	## Au-dessus du porteur : une carte dorée qui tourne doucement.
	var l3 := Label3D.new()
	l3.name = "CardMark"
	l3.text = "🃏"
	l3.font = Fx.goth("pirataone")
	l3.font_size = 90
	l3.pixel_size = 0.005
	l3.modulate = Color(1.0, 0.82, 0.35)
	l3.outline_size = 14
	l3.outline_modulate = Color(0.1, 0.05, 0.02, 0.9)
	l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l3.position.y = 2.1
	f.add_child(l3)
	var tw := l3.create_tween().set_loops()
	tw.tween_property(l3, "position:y", 2.3, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l3, "position:y", 2.1, 0.8).set_trans(Tween.TRANS_SINE)


const CHALLENGE_SHORT := {"vite": "abattre %s avant la fin du round 2", "eau": "faire tomber %s à l'eau",
	"piege": "achever %s avec un piège", "marque": "achever %s pendant qu'il est Marqué"}


func _challenge_hud() -> void:
	## Le défi en cours reste écrit sous le titre : l'annonce d'entrée ne suffit pas à s'en souvenir.
	var t := ""
	for f in alive_foes():
		if f.card_id == "" or (f.card_cond == "vite" and turn > 2):
			continue
		var nm: String = Data.def(f.card_id).name
		if f.card_cond == "fuite":
			t = "✦ Fuyard : %s s'enfuit avec « %s » dans %d tour(s)" % [f.nm, nm, 3 - f.flee_n]
		else:
			t = "✦ %s · %s · « %s » enchantée" % [Data.CARD_CONDS[f.card_cond].name, CHALLENGE_SHORT[f.card_cond] % f.nm, nm]
		break
	main.ui.set_challenge(t)


func _card_won(f: Unit, how: String) -> void:
	if f.card_id == "":
		return
	# un défi relevé (pas un simple fuyard abattu) : la carte arrive avec un enchantement cohérent
	var en := Data.ench_roll({"id": f.card_id, "lvl": 1}, rng) if f.card_cond != "fuite" else ""
	main.pending_cards.append(f.card_id + ("|" + en if en != "" else ""))
	Fx.number(main, f.position + Vector3(0, 1.8, 0), "%s : %s" % [how, Data.def(f.card_id).name], GOLD_FX, true)
	log_add("🃏 %s — %s" % [how, Data.def(f.card_id).name])
	var shown := {"id": f.card_id, "lvl": 1, "h": alive_heroes()[0].key if alive_heroes().size() > 0 else "garde"}
	if en != "":
		shown["ench"] = en
	main.ui.reward_flash(shown, "Défi relevé" if f.card_cond != "fuite" else how)
	f.card_id = ""
	if f.has_node("CardMark"):
		f.get_node("CardMark").queue_free()
	_challenge_hud()


func _flee(f: Unit) -> void:
	## Le fuyard s'éloigne des héros ; au 3e tour il disparaît avec sa carte.
	f.flee_n += 1
	if f.flee_n >= 3 and f.card_id != "":
		Fx.number(main, f.position + Vector3(0, 1.3, 0), "S'enfuit !", Color(0.8, 0.8, 0.9), true)
		log_add("%s s'enfuit avec sa carte" % f.nm)
		main.ui.toast("%s s'est échappé avec %s." % [f.nm, Data.def(f.card_id).name])
		f.card_id = ""
		foes.erase(f)
		f.alive = false
		var tw := f.create_tween()
		tw.tween_property(f, "scale", Vector3.ONE * 0.01, 0.4)
		tw.tween_callback(func(): f.visible = false)
		_gone.append(f)  # libéré au prochain combat : son tour est encore en cours
		await wait(0.5)
		check_end()
		return
	var R := reach(f) if f.root <= 0 else {"prev": {f.cell: f.cell}, "cells": {f.cell: true}, "dist": {f.cell: 0}}
	var hs := alive_heroes()
	var best: Vector2i = f.cell
	var best_d := -1
	for c in R.cells:
		if unit_at(c) != null and c != f.cell:
			continue
		var dmin := 99
		for h in hs:
			dmin = mini(dmin, dist(c, h.cell))
		if dmin > best_d:
			best_d = dmin
			best = c
	if best != f.cell:
		await _foe_walk(f, path_to(R.prev, best))
	Fx.number(main, f.position + Vector3(0, 1.3, 0), "Fuit · %d" % (3 - f.flee_n), Color(1.0, 0.85, 0.5))


func _equip_foe(f: Unit) -> void:
	## Une pièce (jamais une arme de classe), rareté selon l'étage ; elle se voit sur la fiche et se vole.
	var rar := 1 + int(rng.randf() < 0.15 * main.floor_i) + int(main.floor_i >= 3 and rng.randf() < 0.2)
	var ids: Array = Data.ITEMS.keys().filter(func(id): return Data.ITEMS[id].get("foe", false) and Data.ITEMS[id].rarity <= rar)
	if ids.is_empty():
		return
	var id: String = ids[rng.randi_range(0, ids.size() - 1)]
	f.equip[Data.ITEMS[id].slot] = id
	var it: Dictionary = Data.ITEMS[id]
	f.max_hp += int(it.get("hp", 0))
	f.hp = f.max_hp
	f.move = maxi(1, f.move + int(it.get("move", 0)) + int(it.passive == "deplacement"))
	f.jump += int(it.get("jump", 0)) + 2 * int(it.passive == "saut")


func hit_dmg(h: Unit, f: Unit, c: Dictionary, base: int, k := 0) -> Dictionary:
	## Le k-ième coup d'une carte. Concile du 29/09 : les bonus plats (arme, Fragile, soutien...) ne comptent qu'au
	## premier coup ; les dégâts de Proie et de Revers s'ajoutent après les multiplicateurs (la Marque ou le dos
	## qui remplit la condition ne multiplie plus son propre bonus).
	var tb: int = mini(base, _trig_dmg(c, h, f.cell)) if c.has("trig") and c.trig.on in ["proie", "dos"] else 0
	var r := calc(h, f, base - tb, c, k > 0)
	r.dmg += tb
	return r


func card_total(h: Unit, f: Unit, c: Dictionary) -> Dictionary:
	## Ce que la carte inflige à f, tous ses coups compris : la prévision et l'infobulle disent la même chose que l'attaque.
	var base := _base(c, h, f.cell)
	var r := hit_dmg(h, f, c, base, 0)
	var n: int = (1 + played) if c.get("hits_flow", false) else int(c.get("hits", 1))
	if n > 1:
		r.dmg += hit_dmg(h, f, c, base, 1).dmg * (n - 1)
	return r


func calc(att: Unit, tgt: Unit, base: int, c := {}, no_flat := false) -> Dictionary:
	var mult := 1.0
	var flat := att.gear_dmg()
	if att.side == "hero" and att.rage > 0:
		flat += att.rage
	var notes: Array = []
	var ranged: bool = c.has("range") and card_range(c, att).y > 1 if att.side == "hero" else att.data.get("range", [1, 1])[1] > 1
	var dh: int = board.h[att.cell] - board.h[tgt.cell]
	if dh != 0:
		var hb := 0.1 * clampi(dh, -3, 3)
		mult += hb
		notes.append("hauteur %+d %%" % int(round(hb * 100)))
	var to_att := att.cell - tgt.cell
	var dot := tgt.facing.x * signi(to_att.x) + tgt.facing.y * signi(to_att.y)
	if dot < 0 and tgt.has_p("vigilance"):
		dot = 0
	if att.side == "hero" and att.ambush:
		dot = -1
	if tgt.exposed:
		dot = -1
	if smoke.has(tgt.cell) and dist(att.cell, tgt.cell) == 1:
		dot = -1  # dans la fumée, on ne voit pas venir le coup
	# Fanal : dans sa lumière, pas de coup de dos (ni d'Exposé) ; à l'acte 3, pas de flanc non plus
	var lit: bool = tgt.side == "foe" and _in_aura(tgt, "fanal", 3)
	if lit and dot < 0:
		dot = 0
		notes.append("fanal : pas de dos")
	if tgt.has_p("pavois_face") and dot > 0 and att.data.get("arme", "") != "magie":
		mult *= 0.5
		notes.append("pavois ×0.5")
	if lit and dot == 0 and main.floor_i >= 3:
		dot = 1
	# couvert : un héros collé à un allié, ou au premier round, ne se fait pas prendre de dos (flanc au pire)
	if dot < 0 and _covered(tgt):
		dot = 0
		notes.append("couvert : pas de dos")
	if dot < 0:
		var bs: float = c.get("backstab", 1.5)
		mult *= bs
		notes.append("dos ×%s" % str(bs))
		if att.side == "hero":
			flat += (3 if has("feuille") else 0) + (2 if att.trait_id == "gaucher" else 0)
	elif dot == 0:
		mult *= 1.2
		notes.append("flanc ×1.2")
	if tiles.get(att.cell, "") == "force" or att.get_meta("marelle", -1) == turn:
		flat += 3
		notes.append("rune de force +3")
	if att.side == "hero" and has("pierre") and int(c.get("hits", 1)) >= 2:
		flat += 2  # ne compte plus qu'au premier coup
	if att.companion and has("collier"):
		flat += 3
	if att.side == "hero" and att.key == "tidiane" and powers.has("hyperfocus"):
		flat += 3 + int(power_val.get("hyperfocus", 0))
	if att.trait_id == "rancune" and att.hp * 2 < att.max_hp:
		flat += 3
	if att.trait_id == "myope" and ranged:
		flat += 2
	if att.trait_id == "bagarreur" and not ranged:
		flat += 2
	if ranged and att.has_p("affut") and not att.walked:
		flat += 2
		notes.append("embusqué +2")
	if att.trait_id == "fragile":
		flat += 3
	if not ranged and att.has_p("arme_plus"):
		flat += 2
	if att.has_p("deux_mains") and not att.struck:
		mult *= 1.5
		notes.append("deux mains ×1.5")
	# Marque, Botte et Meute ne se cumulent pas sur un héros : on garde la plus forte
	var m_mark := 1.5 if tgt.mark > 0 else 1.0
	var m_botte := 1.5 if att.data.get("botte", false) and tgt.side == "hero" and tgt.get_meta("hit_round", -1) == turn else 1.0
	var meute := 0
	if att.key == "harpie" and tgt.has_meta("meute") and tgt.get_meta("meute")[0] == turn:
		meute = 2 * tgt.get_meta("meute")[1].filter(func(o): return o != att).size()
	if tgt.side == "hero" and maxf(m_mark, m_botte) > 1.0:
		meute = 0
	var m_top := maxf(m_mark, m_botte) if tgt.side == "hero" else m_mark
	if m_top > 1.0:
		mult *= m_top
		notes.append("botte ×1.5" if m_botte > m_mark else "marqué ×1.5")
	if meute > 0:
		flat += meute
		notes.append("meute +%d" % meute)
	if att.data.get("perche", false) and board.h[att.cell] > board.h[tgt.cell]:
		flat += 3
		notes.append("perché +3")
	if att.data.get("ancre_si_eau", false) and board.kind[att.cell] == "water":
		flat += 3
		notes.append("dans l'eau +3")
	if tgt.has_meta("echouee"):
		mult *= 1.5
		notes.append("échouée ×1.5")
	if att.side == "hero" and att.triple and c.get("kind", "") == "atk":
		mult *= 3.0
		notes.append("just frame ×3")
	if att.side == "hero" and powers.has("tetsu") and tgt.root > 0 and not ranged:
		flat += int(power_val.get("tetsu", 4))
	if att.side == "hero" and tgt.side == "foe" and tgt.root > 0 and has("chaine_amarre"):
		flat += 3
	if att.side == "hero" and has("lentille") and dist(att.cell, tgt.cell) >= 3:
		flat += 2
	if c.get("execute", false) and tgt.hp * 2 < tgt.max_hp:
		mult *= 2.0
		notes.append("exécution ×2")
	if ranged and tgt.fly:
		mult *= 1.5
		notes.append("tir sur volant ×1.5")
	if tiles.get(tgt.cell, "") == "fourre":
		mult *= 0.7
		notes.append("fourré ×0.7")
	if mult > 2.5:  # concile du 29/09 : au-delà, un cumul dispense de réfléchir (dos + Marque ×2,25 reste entier)
		mult = 2.5
		notes.append("plafond ×2.5")
	# soutien : un allié au contact
	if att.side == "hero" and alive_heroes().any(func(a): return a != att and dist(a.cell, att.cell) == 1):
		flat += 2
		notes.append("soutien +2")
	if tgt.side == "hero" and alive_heroes().any(func(a): return a != tgt and dist(a.cell, tgt.cell) == 1):
		flat -= 2
		notes.append("soutien −2")
	if att.side == "foe" and att.data.get("aura", "") != "ordre" and _in_aura(att, "ordre", 2):
		flat += 2
		notes.append("ordre du capitaine +2")
	return {"dmg": maxi(0, int(round(base * mult)) + (0 if no_flat else flat)), "notes": notes}



func damage(u: Unit, amount: int, src: Unit = null, show := true, ranged := false) -> void:
	if not u.alive:
		return
	# Tenant (et Hale pour Brasse) : intercepte le premier coup du round porté à un voisin, tel quel
	if u.side == "foe" and src and src.side == "hero" and not _blast and not _dot and _cause == "":
		for t in alive_foes():
			if t != u and int(t.data.get("guard", 0)) > 0 and dist(t.cell, u.cell) == 1 and t.get_meta("intercept_round", -1) != turn \
					and (not t.data.has("guard_only") or t.data.guard_only == u.key):
				t.set_meta("intercept_round", turn)
				Fx.bolt(main, u.position + Vector3(0, 0.8, 0), t.position + Vector3(0, 0.8, 0), Color(1.0, 0.75, 0.35))
				_first("intercept", t.position, "Intercepté !", Color(1.0, 0.75, 0.35), "le Tenant prend pour son voisin le premier coup du round.")
				u = t
				break
	# réactions d'esquive
	if src and ((not ranged and u.has_p("reflexe") and randf() < 0.25) or (ranged and u.has_p("parade") and randf() < 0.5) or (u.trait_id == "chanceux" and randf() < 0.2)):
		Fx.number(main, u.position, "Esquive", Color(0.8, 0.95, 1.0))
		u.dodge()
		return
	if _terrain and u.side == "foe" and src == null:
		# concile du 29/09 : le terrain suit les PV ennemis (étage) et paie la Marque
		var marked: bool = (u.mark > 0) if _terrain_mark < 0 else _terrain_mark == 1
		amount = int(round(amount * Data.TERRAIN[clampi(main.floor_i, 1, 3) - 1] * (1.5 if marked else 1.0)))
	var melee_hit: bool = src != null and not ranged and dist(src.cell, u.cell) == 1
	if melee_hit and amount > 0 and src.side != u.side and src.has_p("venin"):
		u.poison += 1
	if u.blastproof and _blast and amount > 0:
		Fx.number(main, u.position + Vector3(0, 0.6, 0), "Absorbé", Color(0.7, 0.85, 0.95))
		gain_block(u, amount)
		return
	if u.aegis and amount > 0:
		u.aegis = false
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Égide", Color(1.0, 0.95, 0.7), true)
		return
	if u.dodge_next and src:
		u.dodge_next = false
		Fx.number(main, u.position, "Iframe", Color(0.8, 0.95, 1.0), true)
		u.dodge()
		return
	if u.parry and melee_hit and src.alive:
		u.parry = false
		Fx.number(main, u.position + Vector3(0, 0.6, 0), "Parry !", GOLD_FX, true)
		main.hitstop(0.12)
		damage(src, amount)
		return
	if src and src.side == "hero":
		u.exposed = false  # le coup a porté : l'ouverture est prise
		if u.data.get("ai", "") == "commander":
			u.set_meta("hit", true)  # le Capitaine charge dès qu'on le touche
		if src.companion and u.side == "foe" and has("grelot"):
			u.exposed = true  # Grelot de dressage : le prochain coup compte de dos
	# Bitte d'amarrage : 40 % du coup porté à un amarré passe dans la bitte (ni poison ni noyade)
	if u.has_meta("amarre") and not _dot and _cause == "" and amount > 1:
		var bt = u.get_meta("amarre")
		if is_instance_valid(bt) and bt.alive:
			var part := int(amount * 0.4)
			amount -= part
			bt.hp -= part
			bt.hurt()
			Fx.number(main, bt.position, str(part), Color(0.55, 0.6, 1.0), true)
			_first("amarre", bt.position, "Amarré", Color(0.55, 0.6, 1.0), "la Bitte encaisse 40 % des coups portés à ses deux amarrés.")
			if bt.hp <= 0:
				kill(bt, src)
	if u.side == "hero" and src and src.side == "foe":
		if melee_hit and powers.has("vindicte") and power_owner.get("vindicte") == u and src.alive:
			src.exposed = true
			Fx.number(main, src.position + Vector3(0, 1.0, 0), "Vindicte", Color(1.0, 0.75, 0.45))
			if int(power_val.get("vindicte", 0)) > 0:
				damage(src, int(power_val.get("vindicte", 0)))
		if u.bait:
			src.exposed = true
		if u.boomguard > 0 and melee_hit:
			var bg := u.boomguard
			u.boomguard = 0
			_boom_foes(src.cell, bg)
		if melee_hit and powers.has("octroi") and power_owner.get("octroi") == u and src.alive:
			if src.tool != "":
				_steal(u, src)
			else:
				Fx.number(main, src.position + Vector3(0, 0.7, 0), "Octroi", GOLD_FX)
				damage(src, int(power_val.get("octroi", 5)))
		if melee_hit and powers.has("enclume"):
			_enclume_q.append([src, u])
	var had_block := u.block > 0
	var absorbed := mini(u.block, amount)
	u.block -= absorbed
	var rest := amount - absorbed
	u.hp -= rest
	# paliers verrouillés des boss : un coup ne franchit jamais un palier, la phase se déclenche
	if u.side == "foe" and u.data.has("paliers"):
		var ph: int = u.get_meta("phase", 0)
		var pal: Array = u.data.paliers
		if ph < pal.size() and u.hp < ceili(u.max_hp * float(pal[ph])):
			rest -= ceili(u.max_hp * float(pal[ph])) - u.hp
			u.hp = ceili(u.max_hp * float(pal[ph]))
			u.set_meta("phase", ph + 1)
			_phase.call_deferred(u, ph + 1)
	if u.side == "hero" and src and src.side == "foe":
		u.set_meta("hit_round", turn)  # la Botte vise qui a déjà été touché ce round
		if u.taunt and u.hp > 0 and has("etendard"):
			gain_block(u, 3)  # Étendard délavé
		if src.key == "harpie":
			var mt: Array = u.get_meta("meute") if u.has_meta("meute") and u.get_meta("meute")[0] == turn else [turn, []]
			if not mt[1].has(src):
				mt[1].append(src)
			u.set_meta("meute", mt)
	if u.side == "hero" and rest > 0:
		hurt_turn = true
		_berserk(u)
	if u.side == "hero" and u.hp <= 0 and powers.has("quarante") and not u.q40:
		u.q40 = true
		u.hp = 1
		if not has("machoire_ogre"):
			u.block += int(power_val.get("quarante", 15))
		bonus[u] = bonus.get(u, 0) + 2
		Fx.number(main, u.position + Vector3(0, 1.0, 0), "La règle des 40 % !", GOLD_FX, true)
	if u.side == "hero" and not u.companion and u.hp <= 0 and has("ecusson") and not _ecusson:
		_ecusson = true  # Écusson de la Compagnie : une fois par combat
		u.hp = 1
		u.aegis = not has("machoire_ogre")
		Fx.number(main, u.position + Vector3(0, 1.0, 0), "Écusson de la Compagnie !", GOLD_FX, true)
	if rest > 0 or absorbed > 0:
		log_add("%s%s : −%d PV%s" % [(src.nm + " → ") if src and src != u else "", u.nm, rest, (" (armure %d)" % absorbed) if absorbed > 0 else ""])
	if show:
		if rest > 0:
			Fx.number(main, u.position, str(rest), DMG_COL if u.side == "foe" else Color(1.0, 0.4, 0.35), rest >= 10)
		if absorbed > 0:
			Fx.number(main, u.position + Vector3(0.3, 0.3, 0), "🛡 %d" % absorbed, Color(0.7, 0.85, 0.95))
	u.hurt()
	if src:
		main.hitstop(0.05 + mini(rest, 15) * 0.005)
		if u.side == "foe":
			Fx.burst(main, u.position + Vector3(0, 0.8, 0), Color(0.42, 0.4, 0.44), 12 + rest, 3.5)
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), EMBER if u.side == "foe" else Color(1, 0.3, 0.25), 14 + rest, 2.5)
	main.shake(0.06 + rest * 0.012)
	if src and src.affix == "vampire" and rest > 1 and src.alive:
		heal(src, rest / 2)
	if _lifesteal and player_turn and src and src == active and rest > 1 and src.alive:
		heal(src, rest / 2)
	if _blast and u.tool == "bombe":
		# la bombe qu'il portait lui saute entre les mains
		u.tool = ""
		Fx.number(main, u.position + Vector3(0, 1.0, 0), "Sa bombe saute !", EMBER, true)
		_explode.call_deferred(u.cell, 6, true)
	if u.hp <= 0:
		_last_ranged = ranged
		kill(u, src)
	else:
		if u.side == "hero" and u.has_p("elan") and u.hp * 4 < u.max_hp and not _elan_used.has(u):
			_elan_used[u] = true
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "Dernier élan", GOLD_FX)
			_gain_energy(u, 2)
		if src and src.alive and src != u:
			if ranged and u.has_p("retour"):
				Fx.number(main, u.position + Vector3(0, 0.6, 0), "Retour", Color(1, 0.8, 0.5))
				damage(src, maxi(1, rest / 2))
			elif not ranged and dist(src.cell, u.cell) == 1:
				if had_block and u.has_p("brisant") and src.alive:
					push.call_deferred(src, _dir(u.cell, src.cell), 1)  # Brisant : l'armure renvoie l'attaquant
				if u.side == "hero" and u.has_p("contre_vague"):
					u.set_meta("vague", mini(2, int(u.get_meta("vague", 0)) + 1))
				var riposte := 0
				if u.has_p("casseur") and u.hp * 2 < u.max_hp:
					riposte = 8
				elif u.has_p("contre"):
					riposte = 8 if u.get_meta("piques", false) else (6 if u.key == "gardien" else 4)
				if riposte > 0:
					Fx.number(main, u.position + Vector3(0, 0.6, 0), "Contre", Color(1, 0.75, 0.4))
					damage(src, riposte)
	changed.emit()

const GOLD_FX := Color(1.0, 0.82, 0.4)


func kill(u: Unit, src: Unit = null) -> void:
	log_add("✝ %s tombe%s" % [u.nm, (" (%s)" % src.nm) if src and src != u else ""])
	if u.side == "foe":
		_killed = true
	u.hp = 0
	u.die()
	Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 40, 3.5)
	if u.side == "foe" and u.card_id != "":
		var ok: bool = {"fuite": true, "vite": turn <= 2, "eau": _cause == "eau", "piege": _cause == "piege", "marque": u.mark > 0}.get(u.card_cond, false)
		if ok:
			_card_won(u, "Carte gagnée")
			if has("registre_prevot"):
				_gold(20, u.position)
		else:
			Fx.number(main, u.position + Vector3(0, 1.8, 0), "Carte perdue", Color(0.7, 0.7, 0.75))
		_challenge_hud()
	if u.side == "foe" and src and src.side != "foe" and src.has_p("charogne"):
		gain_block(src, 4)
	if u.side == "foe":
		for sl in u.equip:
			if u.equip[sl] != "" and (randf() < 0.1 or (src and src.has_p("main_leste"))):
				main.bag.append(u.equip[sl])
				main.fight_loot.append({"item": u.equip[sl]})
				Fx.number(main, u.position + Vector3(0, 1.6, 0), "Butin : " + Data.ITEMS[u.equip[sl]].name, GOLD_FX, true)
				main.ui.toast("%s rejoint le sac." % Data.ITEMS[u.equip[sl]].name)
				u.equip[sl] = ""
		if u.mark > 0 and (u.bounty or trophy):
			main.gold += (25 if u.bounty else 0) + (10 if trophy else 0)
			main.ui.set_gold(main.gold)
			Fx.number(main, u.position + Vector3(0, 1.3, 0), "Prime !", GOLD_FX, true)
			if u.bounty and player_turn:
				draw(2)
		if u.mark > 0 and powers.has("vesk"):
			var vh: Unit = power_owner.get("vesk")
			if vh and vh.alive:
				_gain_energy(vh, 1)
			var nx: Unit = null
			for o in alive_foes():
				if o != u and (nx == null or dist(o.cell, u.cell) < dist(nx.cell, u.cell)):
					nx = o
			if nx:
				nx.mark = maxi(nx.mark, 2)
		_drop(u)
		if powers.has("seve_noire") and u.poison > 0:
			var nx2: Unit = null
			for o in alive_foes():
				if o != u and (nx2 == null or dist(o.cell, u.cell) < dist(nx2.cell, u.cell)):
					nx2 = o
			if nx2:
				nx2.poison += u.poison + int(power_val.get("seve_noire", 0))
				Fx.number(main, nx2.position + Vector3(0, 0.8, 0), "Sève noire ☠ %d" % nx2.poison, Color(0.6, 0.9, 0.3), true)
		if powers.has("curee") and (u.root > 0 or (int(power_val.get("curee2", 0)) > 0 and u.mark > 0)):
			if board.walkable(u.cell) and not traps.has(u.cell):
				_make_trap(u.cell, "piege", maxi(1, int(power_val.get("curee", 6))))
			if player_turn and curee_turn < 3:
				curee_turn += 1
				draw(1)
		if src and src.side == "hero" and src.has_p("absorbe"):
			_gain_energy(src, 1)
			Fx.number(main, src.position + Vector3(0, 0.5, 0), "+1 énergie", GOLD_FX)
		if has("cendre"):
			for d in Board.DIRS:
				var o := unit_at(u.cell + d)
				if o and o.side == "foe":
					damage(o, _boom_dmg(4))
		if has("machoire_ogre") and src and src.side == "hero" and src.alive:
			src.rage += 2
			Fx.number(main, src.position + Vector3(0, 1.2, 0), "Rage +2", Color(1.0, 0.3, 0.25))
		if has("denier_fossoyeur") and (_choc or _blast or _cause == "eau"):
			_gold(4, u.position)
		_foe_death(u, src)
	check_end()


func _foe_death(u: Unit, src: Unit) -> void:
	## Chaque structure a un effet visible à sa mort ; certains ennemis laissent quelque chose derrière eux.
	var gone := func(pred: Callable):
		for om in foe_omens.duplicate():
			if pred.call(om):
				_drop_omen(om)
	match u.data.get("on_death", ""):
		"fanal":
			for o in alive_foes():
				if dist(o.cell, u.cell) <= 3:
					o.exposed = true
					Fx.number(main, o.position + Vector3(0, 1.0, 0), "Exposé", Color(1.0, 0.75, 0.45))
			_first("fanal", u.position, "Le Fanal s'éteint", Color(1.0, 0.7, 0.36), "ceux qu'il éclairait sont exposés : leur prochain coup reçu compte de dos.")
		"treuil":
			for g in alive_foes().filter(func(o): return o.key == "grelin"):
				g.exposed = true
				_first("treuil", g.position, "Exposé", Color(1.0, 0.75, 0.45), "un treuil cassé laisse Grelin exposé.")
		"bitte":
			for o in alive_foes():
				if _meta(o, "amarre") == u:
					o.remove_meta("amarre")
					_delay(o, 1)
					_first("largues", o.position, "Largués !", Color(0.55, 0.6, 1.0), "la Bitte brisée, ses amarrés jouent en dernier au round suivant.")
		"vanne_dame":
			if not alive_foes().any(func(o): return o.key == "vanne_dame"):
				for d in alive_foes().filter(func(o): return o.key == "dame"):
					d.set_meta("sec", true)
					gone.call(func(om): return om.owner == d and om.kind == "suinte")
					main.ui.banner("La crue retombe", "Plus de vanne : l'eau cesse de monter")
		"vanne":
			gone.call(func(om): return om.owner == u and om.kind == "suinte")
			_first("reflux", u.position, "Reflux", Color(0.6, 0.9, 1.0), "la vanne cassée, l'eau annoncée ne monte pas.")
		"pilori":
			for h in heroes:
				if _meta(h, "chained") == u:
					h.remove_meta("chained")
					h.root = 0
					if h == active:
						h.moved = false
					Fx.number(main, h.position + Vector3(0, 0.8, 0), "Libéré", Color(0.8, 0.9, 1.0), true)
	match u.key:
		"husk":
			# Moussu lesté tué en mêlée : il colle aux pieds des héros voisins
			if src and src.side == "hero" and not src.companion and not _last_ranged and _cause == "" and not _blast and dist(src.cell, u.cell) == 1 and not main.tuto:
				for h in heroes:
					if h.alive and dist(h.cell, u.cell) == 1:
						h.set_meta("englue", true)
						_first("englue", h.position, "Englué", Color(0.6, 0.8, 0.5), "−1 déplacement à son prochain tour.")
		"eclusier_fou":
			if board.walkable(u.cell) and not traps.has(u.cell):
				board.props[u.cell] = "baril"
				_make_prop(u.cell)
				_foe_omen("baril", [u.cell] + Board.DIRS.map(func(d): return u.cell + d), u, {"cell": u.cell})
				Fx.number(main, u.position + Vector3(0, 1.0, 0), "Mèche allumée !", EMBER, true)
		"porte_etendard":
			_first("banniere", u.position, "La bannière tombe", Color(0.7, 0.6, 1.0), "les poussées reprennent autour de lui.")
		"obelisque":
			for o in alive_foes():
				if _meta(o, "summoner") == u:
					_delay(o, 1)
		"wisp":
			if u.has_meta("couvant") and heroes.any(func(h): return h.alive and dist(h.cell, u.cell) == 1):
				_explode.call_deferred(u.cell, u.atk(), true)
		"grelin", "gardien":
			gone.call(func(om): return om.owner == u)
	if u.data.has("bond"):
		for s in alive_foes().filter(func(o): return o.key == u.data.bond):
			s.data = s.data.duplicate(true)
			s.dmg_bonus += 4
			s.move += 2
			s.speed += 3
			s.data.ai = "assassin"
			s.data.erase("guard")
			main.ui.banner("Deuil !", "%s perd son double : +4 dégâts, +2 déplacement, +3 vitesse" % s.nm)
			Fx.burst(main, s.position + Vector3(0, 0.8, 0), Color(1.0, 0.3, 0.3), 60, 4.0)


func heal(u: Unit, amt: int, spill := false) -> void:
	var a := int(amt * (1.5 if u.trait_id == "beni" else 1.0))
	var surplus := a - (u.max_hp - u.hp)
	if u.side == "hero" and u.hp < u.max_hp and a > 0:
		heal_turn = true
	u.hp = mini(u.max_hp, u.hp + a)
	if u.side == "hero" and surplus > 0 and (spill or powers.has("maree_haute") or u.has_p("trop_plein")) and u.alive:
		# Débordement : le soin en trop frappe l'ennemi le plus proche
		var nx: Unit = null
		for o in alive_foes():
			if nx == null or dist(o.cell, u.cell) < dist(nx.cell, u.cell):
				nx = o
		if nx:
			var dv := surplus + (int(power_val.get("maree_haute", 0)) if powers.has("maree_haute") else 0)
			await_spill.call_deferred(u, nx, int(dv * (1.5 if nx.mark > 0 else 1.0)))
	Fx.number(main, u.position, "+%d" % a, Color(0.6, 1.0, 0.55))
	Fx.burst(main, u.position + Vector3(0, 0.5, 0), Color(0.8, 1.0, 0.5), 20, 1.5, 7.0)
	changed.emit()


func _onguent(h: Unit, a: Unit) -> void:
	## Onguent de résine : un héros soigne un allié, l'allié gagne 3 armure.
	if has("onguent") and a != h and a.alive and h.side == "hero":
		gain_block(a, 3)


func await_spill(u: Unit, nx: Unit, dv: int) -> void:
	if not nx.alive or over:
		return
	Fx.bolt(main, u.position, nx.position, Color(0.5, 0.9, 1.0))
	Fx.number(main, nx.position + Vector3(0, 0.9, 0), "Débordement", Color(0.5, 0.9, 1.0))
	damage(nx, dv)
	# Marée haute niveau 3 : le débordement repousse l'ennemi touché
	if int(power_val.get("maree_haute2", 0)) > 0 and nx.alive:
		await push(nx, _dir(u.cell, nx.cell), 1)


func gain_block(u: Unit, v: int) -> void:
	if u.side == "hero" and has("machoire_ogre"):
		return  # Mâchoire de l'ogre : plus d'armure pour les héros
	u.block += v
	Fx.number(main, u.position + Vector3(0, 0.2, 0), "🛡 +%d" % v, Color(0.7, 0.85, 0.95))
	changed.emit()


func push(u: Unit, d: Vector2i, n: int) -> void:
	if mods.has("glissant"):
		n += 1
	if has("crochet") and u.side == "foe":
		n += 1
	var from := u.cell
	if u.side == "foe" and active and active.side == "hero" and has("ecorce_saule"):
		gain_block(active, 2)  # Écorce de saule : même si l'ennemi ne bouge pas
	if u.side == "foe" and powers.has("hallali"):
		u.mark = maxi(u.mark, 2)
	var was_wet: bool = board.kind.get(from, "") == "water"
	await _push_steps(u, d, n)
	if u.cell != from:
		u.pushed = true
		if u.alive and u.data.get("water_only", false) and board.kind[u.cell] != "water":
			u.set_meta("echouee", 2)
			u.root = maxi(u.root, 2)
			_first("echouee", u.position, "Échouée !", Color(0.6, 0.85, 1.0), "hors de l'eau, l'Anguille est entravée et prend ×1,5.")
		if u.alive and u.data.get("ancre_si_eau", false) and was_wet and board.kind[u.cell] != "water":
			u.set_meta("asseche", true)
			u.block = 0
			_first("asseche", u.position, "Asséché !", Color(0.9, 0.8, 0.6), "tiré à terre, le Noyé ancien perd son armure.")
	if u.alive and u.cell != from:
		if u.side == "foe" and traps.has(u.cell):
			await _spring(u)
		await _landed(u)


func anchored(u: Unit) -> bool:
	## Ancre permanente, ou conditionnelle : armure (Crabe, Carapace dès l'acte 2), eau (Noyé ancien), bannière.
	if u.has_p("ancre"):
		return true
	if u.side != "foe":
		return false
	if u.data.get("ancre_armure", false) and u.block > 0 and main.floor_i >= 2:
		return true
	if u.data.get("ancre_si_eau", false) and board.kind[u.cell] == "water" and not _pulling:
		return true
	return _in_aura(u, "etendard", 2)


func _push_steps(u: Unit, d: Vector2i, n: int) -> void:
	if anchored(u) and n > 0:
		Fx.number(main, u.position, "Ancré", Color(0.7, 0.85, 0.95))
		_terrain = true
		damage(u, 3 + crash_bonus)
		_terrain = false
		return
	var i := 0
	var slid := 0
	while i < n:
		i += 1
		if not u.alive:
			return
		var nx := u.cell + d
		var o := unit_at(nx)
		if o:
			_crash(u, o)
			if has("quille") and player_turn and u.side == "foe" and o.side == "foe" and o.alive:
				await push(o, d, 1)  # Quille de plomb : la chaîne s'arrête d'elle-même
			return
		if board.props.get(nx, "") in BOOM + ["pilier"]:
			_crash(u)
			await trigger_prop(nx, d)
			return
		if oaks.has(nx):
			_crash(u)
			_hit_tree(nx, 3 + crash_bonus + (3 if has("clou_halage") else 0))  # l'arbre encaisse le même choc
			return
		if not board._in(nx) or board.kind[nx] == "tower" or board.blocked.has(nx) or board.props.has(nx) or (board.kind[nx] != "water" and board.h[nx] > board.h[u.cell] + 1):
			_crash(u)
			return
		if board.kind[nx] == "water" and not u.has_p("eau") and not u.fly:
			await _slide(u, Vector3(nx.x, Board.WATER_Y - 0.3, nx.y))
			u.cell = nx
			await _fall_water(u)
			return
		var drop: int = board.h[u.cell] - board.h[nx]
		u.cell = nx
		await _slide(u, board.world(nx))
		if u.side == "foe" and traps.has(nx):
			return  # concile du 29/09 : le piège traversé mord et arrête la poussée
		if drop >= 3:
			Fx.number(main, u.position, "Chute", Color(1, 0.8, 0.5))
			damage(u, drop)
		if i == n and ground.get(nx, "") == "glace" and not u.fly and slid < 6:
			slid += 1
			n += 1  # sur la glace, la poussée ne s'arrête qu'au prochain obstacle
			if slid == 1:
				Fx.number(main, u.position + Vector3(0, 0.6, 0), "Glisse !", Color(0.75, 0.95, 1.0))
				if u.side == "foe" and has("givre_etrave"):
					u.exposed = true
					Fx.number(main, u.position + Vector3(0, 1.0, 0), "Exposé", Color(1.0, 0.75, 0.45))
		elif i == n and ground.get(nx, "") == "vase" and not u.fly and not (u.side == "hero" and has("semelles_jonc")):
			u.root = maxi(u.root, 1)
			Fx.number(main, u.position + Vector3(0, 0.6, 0), "Enlisé", Color(0.6, 0.45, 0.3))


func _crash(u: Unit, o: Unit = null) -> void:
	## Choc : la poussée bute sur une unité (o), un mur ou un obstacle. Reliques du Choc.
	Fx.number(main, u.position, "Choc", Color(1, 0.8, 0.5))
	var n := 3 + crash_bonus + (3 if has("clou_halage") else 0)
	_choc = true
	_terrain = true
	damage(u, n)
	if o:
		damage(o, n)
	_choc = false
	_terrain = false
	if o == null and u.side == "foe" and u.alive and has("clou_quai"):
		u.root = maxi(u.root, 1)
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
	var f: Unit = u if u.side == "foe" else o
	if f and f.side == "foe" and f.alive and has("tuile") and not _tuile:
		_tuile = true  # Tuile Brisée : le premier Choc du combat
		f.set_meta("sonne", true)
		Fx.number(main, f.position + Vector3(0, 1.0, 0), "Sonné", Color(1.0, 0.8, 0.4), true)


func _slide(u: Unit, to: Vector3) -> void:
	var tw := u.create_tween()
	tw.tween_property(u, "position", to, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func _nearest_free(from: Vector2i) -> Vector2i:
	var best := from
	var bd := 1 << 30
	for c in board.walkable_cells():
		if unit_at(c) == null:
			var dd := dist(c, from)
			if dd < bd:
				bd = dd
				best = c
	return best


func debug_win() -> void:
	## Menu « Passer la salle » : tous les ennemis tombent, le combat se termine en victoire (pour tester vite).
	for f in alive_foes():
		kill(f)
	check_end()


func check_end() -> void:
	if over:
		return
	if alive_foes().is_empty():
		over = true
		player_turn = false
		_finish(true)
	elif not heroes.any(func(u): return u.alive):  # un compagnon seul ne tient pas la salle
		over = true
		player_turn = false
		_finish(false)


func _finish(v: bool) -> void:
	for ci in spent:
		main.deck.erase(ci)
	spent.clear()
	await wait(1.1)
	ended.emit(v)


# ------------------------------------------------------------------ IA

func can_hit(f: Unit, from: Vector2i, h: Unit) -> bool:
	var r: Array = f.data.range
	var hi: int = r[1] - (1 if r[1] > 2 and mods.has("brume") else 0) + (1 if r[1] > 1 and _in_aura(f, "fanal", 3) else 0)
	var dd := dist(from, h.cell)
	if dd < r[0] or dd > hi:
		return false
	if dd > 1 and smoke.has(h.cell):
		return false
	return r[1] > 1 or absi(board.h[from] - board.h[h.cell]) <= 3


func _wounded_ally(f: Unit) -> Unit:
	var best: Unit = null
	for o in alive_foes():
		if o != f and o.hp < o.max_hp * 0.6 and not o.data.get("structure", false) and (best == null or o.hp * best.max_hp < best.hp * o.max_hp):
			best = o
	return best


func intent(f: Unit) -> String:
	var s := _intent(f)
	if f.tool != "":
		s += "  ⟨%s⟩" % Data.TOOLS[f.tool].glyph
	return ("♛ " + s) if f.affix != "" else s


func _intent(f: Unit) -> String:
	var dmg: int = f.atk()
	var nx: int = f.turns + 1  # son prochain tour
	if f.has_meta("ligne"):
		return "⚠ Digue !" if f.get_meta("ligne").kind == "digue" else "≋ Chasse d'eau !"
	match f.data.ai:
		"bomb":
			return "✹ %d" % dmg
		"ranged":
			if f.key == "guetteur" and nx % 2 == 0 and not main.tuto:
				return "◎ Repère"
			return ("➶ %d perché" % (dmg + 3)) if f.data.get("perche", false) and board.h[f.cell] >= 2 else "➶ %d" % dmg
		"healer":
			return "✚ %d" % maxi(int(f.data.heal), roundi(_wounded_ally(f).max_hp * 0.25)) if _wounded_ally(f) else "➶ %d" % dmg
		"assassin":
			return "† %d" % dmg
		"boss":
			if f.get_meta("phase", 0) >= 2:
				return "⚠ Digue" if nx % 2 == 0 else "⚔ %d" % dmg
			return "☖ Appel" if (turn + 1) % 3 == 0 else "⚔ %d" % dmg
		"reflux":
			return "⚔ %d ↩" % dmg
		"dancer":
			return "♪ Danse"
		"spawner":
			return "✺ Appel"
		"puller":
			return "⤶ %d" % dmg
		"commander":
			return "⚑ %d" % dmg
		"anguille":
			return "≈ %d" % dmg
		"totem":
			return "☀ Veille" if f.key == "fanal" else ("≋ Crue" if f.key == "vanne_dame" else "⚙ +3 armure à Grelin")
		"tether":
			return "⛓ Amarre ×2"
		"flood":
			return "≋ Suinte" if f.get_meta("flooded", 0) < int(f.data.get("flood_cap", 8)) else "À sec"
		"pilori":
			var ch := chain_target(f)
			var who: String = ch.nm if ch else "personne"
			return ("⛓ → %s" % who) if nx % 2 == 0 else ("⛓ dans 1 tour → %s" % who)
		"chevrier":
			return "✂ Pont · ⚔ %d" % dmg
		"dame":
			return ("≋ Crue · ➶ %d" % dmg) if not f.has_meta("sec") else "➶ %d" % dmg
		"brule":
			return ("♨ Haie · ➶ %d" % dmg) if oaks.size() > 0 else "➶ %d" % dmg
		"eclusier":
			return "≋ Chasse d'eau" if nx % (2 if f.get_meta("phase", 0) >= 1 else 3) == 1 else "⚔ %d" % dmg
		"guard":
			var p := guard_target(f)
			return ("⛨ Garde %s · ⚔ %d" % [p.nm.split(",")[0], dmg]) if p else "⚔ %d" % dmg
		"cleanser":
			for o in alive_foes():
				if o != f and o.mark > 0:
					var h := _nearest_hero(f)
					return "✚ Absolution → %s" % (h.nm if h else "?")
			return "➶ %d" % dmg
		"sapper":
			return "▣ Baril" if nx % 2 == 1 and _kegs(f) < 2 else "⚔ %d" % dmg
		"burrow":
			return "⚒ %d" % dmg
	if f.key == "vouivre" and nx % 2 == 0:
		return "⤓ Plongée"
	return "⚔ %d" % dmg


func foe_act(f: Unit) -> void:
	var ai: String = f.data.ai
	f.turns += 1
	# structures : ni objet, ni fuite, ni attaque
	match ai:
		"totem", "tether":
			Fx.burst(main, f.position + Vector3(0, 1.4, 0), Color(1.0, 0.7, 0.36) if ai == "totem" else Color(0.45, 0.5, 1.0), 16, 1.5)
			return
		"spawner":
			return  # l'Appel se fait au début du round
		"flood":
			await _flood_mark(f)
			return
		"pilori":
			await _pilori(f)
			return
	if f.card_cond == "fuite" and f.card_id != "":
		await _flee(f)
		return
	if f.tool != "":
		await _foe_tool(f)  # l'objet ne coûte pas son action
		if not f.alive or over:
			return
	# ligne annoncée au tour précédent (Chasse d'eau, Coup de digue) : elle part avant tout le reste
	if f.has_meta("ligne"):
		await _flush(f)
		if not f.alive or over:
			return
	elif ai == "eclusier" and f.turns % (2 if f.get_meta("phase", 0) >= 1 else 3) == 1:
		await _set_line(f, "chasse")
		return
	if ai == "chevrier":
		await _cut_bridge(f)
	elif ai == "dame" and not f.has_meta("sec") and f.turns >= 2:  # un tour de grâce pour se placer
		await _crue(f)
	elif ai == "brule":
		await _kindle(f)
	if not f.alive or over:
		return
	elif ai == "boss" and f.get_meta("phase", 0) >= 2 and f.turns % 2 == 0:
		await _set_line(f, "digue")
		return
	var rooted := f.root > 0
	if rooted:
		f.root -= 1
		Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓", Color(0.8, 0.9, 1.0))
	var R := reach(f) if not rooted else {"prev": {f.cell: f.cell}, "cells": {f.cell: true}, "dist": {f.cell: 0}}
	if await _foe_prop(f, R):
		return
	if ai == "anguille":
		# elle ne quitte pas l'eau
		var wet := {}
		for c in R.cells:
			if board.kind[c] == "water" or c == f.cell:
				wet[c] = true
		R = {"prev": R.prev, "cells": wet, "dist": R.dist}
	# le dernier debout vient se battre au lieu de danser au loin (plus de combats de 11 manches)
	var last: bool = alive_foes().filter(func(o): return not o.data.get("structure", false)).size() == 1
	if ai == "dancer" and not last:
		await _dance(f, R)
		return
	if ai == "commander" and not f.has_meta("hit") and alive_foes().filter(func(o): return o != f and not o.data.get("structure", false)).size() >= 2 \
			and not alive_heroes().any(func(h): return dist(h.cell, f.cell) <= 4):
		Fx.number(main, f.position + Vector3(0, 1.1, 0), "Tient la position", Color(0.6, 0.95, 0.9))
		return  # il garde sa position : il attend qu'on vienne, ou qu'on le touche
	if ai == "healer":
		var w := _wounded_ally(f)
		if w:
			# se placer à portée du blessé, le plus loin possible des héros
			var go := f.cell
			var gs := -INF
			for cell in R.cells:
				var dd := dist(cell, w.cell)
				if dd < 1 or dd > 4:
					continue
				var s := 0.0
				for h in alive_heroes():
					s += minf(dist(cell, h.cell), 6)
				if s > gs:
					gs = s
					go = cell
			if gs > -INF:
				if go != f.cell:
					await _foe_walk(f, path_to(R.prev, go))
				if not f.alive or dist(f.cell, w.cell) > 4:
					return
				f.face(w.cell - f.cell)
				await f.cast()
				await Fx.bolt(main, f.position, w.position, Color(1.0, 0.7, 0.3))
				heal(w, maxi(int(f.data.heal), roundi(w.max_hp * 0.25)))  # un quart de vie, et il blinde
				gain_block(w, 3)
				return
	var done := false
	if ai == "cleanser":
		done = await _cleanse(f, R)
	elif ai == "guard":
		done = await _guard(f, R)
	elif ai == "sapper" and f.turns % 2 == 1 and _kegs(f) < 2 and not rooted:
		done = await _sap(f, R)
	elif f.key == "vouivre" and f.turns % 2 == 0 and not rooted:
		done = await _dive(f, R)
	if done or not f.alive or over:
		return
	var live := alive_heroes()
	if live.is_empty():
		return
	var taunter: Unit = null
	for h in live:
		if h.taunt and not h.has_meta("chained"):  # le Pilori suspend la Provocation
			taunter = h
	var best_cell = null
	var best_t: Unit = null
	var best_s := -INF
	var saved := f.cell
	var far_ai: bool = ai in ["ranged", "healer", "cleanser"] and not last  # le dernier debout ne recule plus
	for cell in R.cells:
		f.cell = cell
		var near_allies := 0
		if f.data.get("aura", "") == "etendard":
			near_allies = alive_foes().filter(func(o): return o != f and not o.data.get("structure", false) and dist(o.cell, cell) <= 2).size()
		for h in live:
			if taunter and h != taunter and dist(cell, taunter.cell) <= 6:
				continue
			if not can_hit(f, cell, h):
				continue
			var dmg: int = calc(f, h, f.atk()).dmg
			var s: float = dmg * 10.0 - R.dist[cell] * 0.5
			if tiles.get(cell, "") in ["lave", "ronces", "glyphe"]:
				s -= 40  # il évite les pièges du terrain
			elif tiles.get(cell, "") in ["fourre", "fort"]:
				s += 12
			if omen_cells().has(cell):
				s -= 15  # il n'aime pas plus que vous la ligne rouge
			if dmg >= h.hp + h.block:
				s += 60
			if far_ai:
				s += board.h[cell] * (6 if f.data.get("perche", false) else 3) + dist(cell, h.cell) * 2
			if ai == "assassin":
				s += (40 - h.hp) + (30 if _isolated(h) else 0)
			if h.mark > 0:
				s += 20  # la cible repérée
			if f.data.get("botte", false) and h.get_meta("hit_round", -1) == turn:
				s += 25
			if f.key == "harpie" and h.has_meta("meute") and h.get_meta("meute")[0] == turn:
				s += 25
			if f.data.get("shove", 0) > 0 and board.kind.get(h.cell + _dir(cell, h.cell), "") == "water":
				s += 25  # la bourrade du crabe l'envoie à l'eau
			if ai == "puller":
				if not live.any(func(o): return o != h and dist(o.cell, h.cell) == 1):
					s += 20
				var pd := _dir(h.cell, cell)
				for k in range(1, dist(cell, h.cell)):
					if board.kind.get(h.cell + pd * k, "") == "water":
						s += 30
						break
			if f.data.get("ancre_si_eau", false) and board.kind[cell] == "water":
				s += 15
			s += near_allies * 8
			if s > best_s:
				best_s = s
				best_cell = cell
				best_t = h
	f.cell = saved
	if best_cell != null:
		if best_cell != f.cell:
			await _foe_walk(f, path_to(R.prev, best_cell))
		if not f.alive or over:
			return
		if f.key == "guetteur" and f.turns % 2 == 0 and not main.tuto and best_t.alive:
			# Repérage : il marque la cible pour les autres au lieu de tirer
			f.face(best_t.cell - f.cell)
			await f.cast()
			await Fx.bolt(main, f.position, best_t.position, Color(1.0, 0.85, 0.4))
			best_t.mark = maxi(best_t.mark, 1)
			_first("repere", best_t.position, "◎ Repéré", Color(1.0, 0.85, 0.4), "le Guetteur marque une cible : ×1,5 aux coups reçus jusqu'à la fin de son prochain tour.")
			return
		if can_hit(f, f.cell, best_t):
			await foe_strike(f, best_t)
		if ai == "reflux" and f.alive and not over:
			await _reflux(f)
		return
	# approche : la case la plus proche d'un héros (le plus isolé, puis le plus faible, pour l'assassin)
	if ai == "anguille":
		var bc := Vector2.ZERO
		for h in live:
			bc += Vector2(h.cell)
		bc /= live.size()
		var ga := f.cell
		for cell in R.cells:
			if Vector2(cell).distance_to(bc) < Vector2(ga).distance_to(bc):
				ga = cell
		if ga != f.cell:
			await _foe_walk(f, path_to(R.prev, ga))
		return
	var targets: Array = [taunter] if taunter else live
	if ai == "assassin" and not taunter:
		targets = [live.reduce(func(a, b): return a if (40 - a.hp + (30 if _isolated(a) else 0)) >= (40 - b.hp + (30 if _isolated(b) else 0)) else b)]
	var dm := board.bfs_dist(targets.map(func(u): return u.cell), f.jump, f.fly)
	if not f.fly and not R.cells.keys().any(func(cl): return dm.has(cl)) and oaks.size() > 0:
		# enfermé par des arbres : il va frapper celui qui le sépare le mieux des héros
		var dt := board.bfs_dist(targets.map(func(u): return u.cell), f.jump, false, true)
		var pick := [null, null, 999]
		for cl in R.cells:
			for d in Board.DIRS:
				if oaks.has(cl + d) and dt.get(cl + d, 999) < pick[2]:
					pick = [cl, cl + d, dt[cl + d]]
		if pick[0] != null:
			if pick[0] != f.cell:
				await _foe_walk(f, path_to(R.prev, pick[0]))
			if f.alive and not over and oaks.has(pick[1]):
				_sim("percee_ia")
				f.face(pick[1] - f.cell)
				await f.lunge(board.world(pick[1]))
				_hit_tree(pick[1], f.atk())
			return
	var go := f.cell
	var gd: int = dm.get(f.cell, 999)
	for cell in R.cells:
		var v: int = dm.get(cell, 999)
		if v < gd or (v == gd and board.h[cell] > board.h[go]):
			gd = v
			go = cell
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))
	if not f.alive:
		return
	for h in live:
		if h.alive and can_hit(f, f.cell, h):
			await foe_strike(f, h)
			return


func _isolated(h: Unit) -> bool:
	## Aucun allié (héros ou compagnon) à 2 cases.
	return not alive_heroes().any(func(o): return o != h and dist(o.cell, h.cell) <= 2)


func _nearest_hero(u: Unit) -> Unit:
	var best: Unit = null
	for h in alive_heroes():
		if best == null or dist(h.cell, u.cell) < dist(best.cell, u.cell):
			best = h
	return best


func _cleanse(f: Unit, R: Dictionary) -> bool:
	## Pénitente : purifie un allié (Marque, poison, Entrave) et renvoie la Marque au héros le plus proche.
	var a: Unit = null
	for o in alive_foes():
		if o != f and not o.data.get("structure", false) and (o.mark > 0 or o.poison > 0 or o.root > 0) \
				and (a == null or dist(o.cell, f.cell) < dist(a.cell, f.cell)):
			a = o
	if a == null:
		return false
	var go := f.cell
	var gs := -INF
	for cell in R.cells:
		if dist(cell, a.cell) > 4:
			continue
		var s := 0.0
		for h in alive_heroes():
			s += minf(dist(cell, h.cell), 6)
		if s > gs:
			gs = s
			go = cell
	if gs == -INF:
		return false
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))
	if not f.alive or not a.alive or dist(f.cell, a.cell) > 4:
		return true
	f.face(a.cell - f.cell)
	await f.cast()
	await Fx.bolt(main, f.position, a.position, Color(0.7, 0.55, 1.0))
	var had := a.mark > 0
	a.mark = 0
	a.poison = 0
	a.root = 0
	Fx.number(main, a.position + Vector3(0, 1.0, 0), "Absolution", Color(0.7, 0.55, 1.0))
	if had:
		var h := _nearest_hero(f)
		if h:
			h.mark = maxi(h.mark, 1)
			_first("renvoi", h.position, "Marque renvoyée", Color(0.7, 0.55, 1.0), "la Pénitente purifie un allié et renvoie sa Marque au héros le plus proche.")
	return true


func guard_target(f: Unit) -> Unit:
	## Le protégé du Tenant : l'allié qui frappe le plus fort et le plus loin ; pour Hale, Brasse.
	if f.data.has("guard_only"):
		for o in alive_foes():
			if o.key == f.data.guard_only:
				return o
		return null
	var p: Unit = null
	var bv := -1.0
	for o in alive_foes():
		if o == f or o.data.get("structure", false) or int(o.data.get("guard", 0)) > 0:
			continue
		var v := float(o.atk() * int(o.data.range[1]))
		if v > bv:
			bv = v
			p = o
	return p


func _guard(f: Unit, R: Dictionary) -> bool:
	## Se colle à son protégé, du côté des héros, puis frappe s'il le peut.
	var p := guard_target(f)
	var hs := alive_heroes()
	if p == null or hs.is_empty():
		return false
	var go := f.cell
	var gs := INF
	for cell in R.cells:
		if dist(cell, p.cell) != 1:
			continue
		var dh := 99
		for h in hs:
			dh = mini(dh, dist(cell, h.cell))
		var s: float = dh + R.dist[cell] * 0.1
		if s < gs:
			gs = s
			go = cell
	if gs == INF:
		return false
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))
	if not f.alive:
		return true
	var tgt: Unit = null
	for h in hs:
		if h.alive and can_hit(f, f.cell, h) and (tgt == null or h.hp < tgt.hp):
			tgt = h
	if tgt:
		await foe_strike(f, tgt)
	return true


func _kegs(f: Unit) -> int:
	return foe_omens.filter(func(om): return om.kind == "baril" and om.owner == f).size()


func _sap(f: Unit, R: Dictionary) -> bool:
	## Éclusier fou : au contact du groupe le plus serré, il pose un baril qui saute au prochain round.
	var hs := alive_heroes()
	var tgt: Unit = null
	var bn := -1
	for h in hs:
		var n := hs.filter(func(o): return o != h and dist(o.cell, h.cell) <= 1).size()
		if n > bn or (n == bn and tgt and dist(h.cell, f.cell) < dist(tgt.cell, f.cell)):
			bn = n
			tgt = h
	if tgt == null:
		return false
	var go := f.cell
	var gd := dist(f.cell, tgt.cell)
	for cell in R.cells:
		var d := dist(cell, tgt.cell)
		if d >= 1 and d < gd:
			gd = d
			go = cell
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))
	if not f.alive or over:
		return true
	var spot = null
	var sd := 99
	for d in Board.DIRS:
		var c: Vector2i = tgt.cell + d
		if board.walkable(c) and unit_at(c) == null and not traps.has(c) and dist(c, f.cell) <= 2 and dist(c, f.cell) < sd:
			sd = dist(c, f.cell)
			spot = c
	if spot == null:
		if can_hit(f, f.cell, tgt):
			await foe_strike(f, tgt)
		return true
	f.face(spot - f.cell)
	await f.cast()
	board.props[spot] = "baril"
	_make_prop(spot)
	_foe_omen("baril", [spot] + Board.DIRS.map(func(d): return spot + d), f, {"cell": spot})
	_first("baril", board.world(spot), "Baril allumé", EMBER, "il saute au début du prochain round, sur 5 cases, ses alliés compris. Le frapper le fait sauter plus tôt.")
	return true


func _dive(f: Unit, R: Dictionary) -> bool:
	## Vouivre : un tour sur deux, elle saisit un héros voisin et l'emporte de 2 cases, vers l'eau si elle peut.
	var best = null
	var bh: Unit = null
	var bs := -INF
	for cell in R.cells:
		for h in alive_heroes():
			if dist(cell, h.cell) != 1:
				continue
			var d := _dir(cell, h.cell)
			var s: float = -R.dist[cell] * 0.5
			for k in [1, 2]:
				if board.kind.get(h.cell + d * k, "") == "water":
					s += 50
					break
			if s > bs:
				bs = s
				best = cell
				bh = h
	if best == null:
		return false
	if best != f.cell:
		await _foe_walk(f, path_to(R.prev, best))
	if not f.alive or not bh.alive or dist(f.cell, bh.cell) != 1:
		return true
	f.face(bh.cell - f.cell)
	await f.lunge(bh.position)
	if anchored(bh):
		f.exposed = true
		Fx.number(main, f.position + Vector3(0, 1.0, 0), "Plongée ratée : exposée", Color(1.0, 0.75, 0.45), true)
		return true
	_first("plongee", bh.position, "Plongée !", Color(0.6, 0.85, 1.0), "la Vouivre emporte un héros de 2 cases, vers l'eau si elle peut.")
	damage(bh, maxi(1, f.atk() / 2), f)
	if bh.alive:
		await push(bh, _dir(f.cell, bh.cell), 2)
	return true


func _set_line(f: Unit, kind: String) -> void:
	## Grelin (Chasse d'eau) et le Gardien (Coup de digue) : une ligne de 4 cases, annoncée un tour à l'avance.
	var nh := _nearest_hero(f)
	var toward: Vector2i = _dir(f.cell, nh.cell) if nh else f.facing
	var bd := toward
	var bn := -1
	if kind == "chasse":
		for d in Board.DIRS:
			var n := 0
			for i in range(1, 5):
				var u := unit_at(f.cell + d * i)
				if u and u.side == "hero":
					n += 1
			if n > bn or (n == bn and d == toward):
				bn = n
				bd = d
	var cells: Array = []
	for i in range(1, 5):
		if board._in(f.cell + bd * i):
			cells.append(f.cell + bd * i)
	f.face(bd)
	await f.cast()
	var om := _foe_omen(kind, cells, f, {"dir": bd})
	f.set_meta("ligne", om)
	if kind == "chasse":
		_first("chasse", f.position, "≋ Chasse d'eau", Color(0.6, 0.85, 1.0), "à son prochain tour, tout ce qui est sur la ligne rouge est poussé de 2 cases, ses alliés compris.")
	else:
		_first("digue", f.position, "⚠ Coup de digue", EMBER, "à son prochain tour : 22 dégâts et une poussée de 2 sur la ligne rouge, ses alliés compris.")


func _flush(f: Unit) -> void:
	## La ligne part : chaque unité dessus est poussée de 2 (et prend 22 au Coup de digue), ennemis compris.
	var om: Dictionary = f.get_meta("ligne")
	f.remove_meta("ligne")
	var d: Vector2i = om.dir
	var cells: Array = om.cells.duplicate()
	_drop_omen(om)
	f.face(d)
	await f.cast()
	main.shake(0.6)
	var digue: bool = om.kind == "digue"
	Fx.number(main, f.position + Vector3(0, 1.3, 0), "Coup de digue !" if digue else "Chasse d'eau !", EMBER if digue else Color(0.6, 0.85, 1.0), true)
	cells.reverse()  # le plus loin d'abord
	for c in cells:
		Fx.burst(main, board.world(c) + Vector3(0, 0.4, 0), Color(0.7, 0.9, 1.0), 30, 3.5, 3.0)
		var u := unit_at(c)
		if u == null or u == f:
			continue
		if digue:
			damage(u, int(round(22 * foe_mult)) + foe_bonus, f)
		if u.alive:
			await push(u, d, 2)
	if not digue and f.get_meta("phase", 0) >= 1 and alive_foes().size() < 8:
		var end: Vector2i = om.cells[om.cells.size() - 1]
		var spot := end if board.walkable(end) and unit_at(end) == null else _nearest_free(end)
		var m := spawn_foe("husk", spot)
		m.face(f.cell - m.cell)
		Fx.burst(main, m.position + Vector3(0, 0.5, 0), Color(0.6, 0.85, 1.0), 30, 2.0, 6.0)
	await wait(0.2)


func _cut_bridge(f: Unit) -> void:
	## Le Chevrier : le pont le plus proche d'un héros tombe à l'eau au prochain round (deux en phase 2).
	var pending := omen_cells()
	for k in (2 if f.get_meta("phase", 0) >= 1 else 1):
		var br: Array = board.h.keys().filter(func(c): return board._in(c) and board.kind[c] == "bridge" and not pending.has(c))
		if br.is_empty():
			if alive_foes().filter(func(o): return o.key == "chevre").size() < 3 and f.turns % 2 == 0:
				await _summon(f, "chevre")  # plus de pont : il siffle une chèvre
			return
		br.sort_custom(func(a, b): return _hero_dist(a) < _hero_dist(b))
		var cells: Array = [br[0]]
		for c in br:
			if c != br[0] and dist(c, br[0]) == 1 and cells.size() < 2:
				cells.append(c)
		for c in cells:
			pending[c] = true
		f.face(_dir(f.cell, br[0]))
		await f.cast()
		_foe_omen("coupe", cells, f)
		_first("coupe", board.world(br[0]), "✂ Pont coupé", Color(1.0, 0.7, 0.4), "au prochain round, ce pont tombe à l'eau avec ce qui s'y tient. Abattre un arbre au bord de l'eau jette un tronc en travers.")


func _crue(f: Unit) -> void:
	## La Dame : la crue gagne un rang (deux en phase 2) depuis le bord de l'arène le plus proche de l'escouade.
	if not f.has_meta("crue_dir"):
		var hc := Vector2.ZERO
		for h in heroes:
			hc += Vector2(h.cell)
		hc /= maxi(1, heroes.size())
		var sides := {Vector2i(1, 0): hc.x, Vector2i(-1, 0): board.dim - 1 - hc.x, Vector2i(0, 1): hc.y, Vector2i(0, -1): board.dim - 1 - hc.y}
		var best := Vector2i(1, 0)
		for d in sides:
			if sides[d] < sides[best]:
				best = d
		f.set_meta("crue_dir", best)  # sens de la montée : du bord vers l'intérieur
		f.set_meta("crue_row", 0)
	var d: Vector2i = f.get_meta("crue_dir")
	var row: int = f.get_meta("crue_row")
	var took: Array = []
	for k in (2 if f.get_meta("phase", 0) >= 1 else 1):
		if row >= board.dim - 3:
			break
		var r := row if (d.x > 0 or d.y > 0) else board.dim - 1 - row
		for j in board.dim:
			var c := Vector2i(r, j) if d.x != 0 else Vector2i(j, r)
			if board._in(c) and board.kind[c] in ["land", "bridge"]:
				took.append(c)
		row += 1
	f.set_meta("crue_row", row)
	if took.is_empty():
		return
	await f.cast()
	_foe_omen("suinte", took, f)
	_first("crue", board.world(took[0]), "≋ La crue monte", Color(0.6, 0.85, 1.0), "ce rang sera sous l'eau au prochain round, pour tout le monde. Cassez ses vannes, ou poussez-la dedans.")


func _kindle(f: Unit) -> void:
	## Brûle-Haie : l'arbre le plus proche de l'escouade se met à couver ; il flambe au round suivant.
	var cand: Array = oaks.keys().filter(func(c): return not smolder.has(c) and not oak_fp.has(c))
	if cand.is_empty():
		return
	cand.sort_custom(func(a, b): return _hero_dist(a) < _hero_dist(b))
	await f.cast()
	for c in cand.slice(0, 2 if f.get_meta("phase", 0) >= 1 else 1):
		Fx.bolt(main, f.position + Vector3(0, 0.8, 0), board.world(c) + Vector3(0, 0.8, 0), EMBER)
		smolder[c] = _ember_mark(c)
	_first("couve", board.world(cand[0]), "♨ La haie couve", EMBER, "cet arbre flambe au round suivant (6 dégâts autour) et gagne les arbres collés. Abattez la haie avant la flamme.")
	changed.emit()


func _flood_mark(f: Unit) -> void:
	## Vanne : marque 2 cases de berge (h ≤ 1, au bord de l'eau) près des héros ; elles seront sous l'eau au prochain round.
	var cap: int = int(f.data.get("flood_cap", 8))
	var n0: int = f.get_meta("flooded", 0)
	if n0 >= cap:
		Fx.number(main, f.position + Vector3(0, 1.2, 0), "À sec", Color(0.7, 0.8, 0.85))
		return
	var pending := omen_cells()
	var starts := {}
	if turn == 1:
		for h in heroes:
			starts[h.cell] = true
	var cand: Array = []
	for c in board.walkable_cells():
		if board.h[c] > 1 or pending.has(c) or starts.has(c):
			continue
		if Board.DIRS.any(func(d): return board.kind.get(c + d, "") == "water"):
			cand.append(c)
	cand.sort_custom(func(a, b): return _hero_dist(a) < _hero_dist(b))
	var take: Array = cand.slice(0, mini(2, cap - n0))
	if take.is_empty():
		return
	f.set_meta("flooded", n0 + take.size())
	await f.cast()
	_foe_omen("suinte", take, f)
	_first("suinte", board.world(take[0]), "≋ Suinte", Color(0.6, 0.85, 1.0), "ces cases seront sous l'eau au prochain round, pour tout le monde. Casser la vanne annule l'eau annoncée.")


func chain_target(f: Unit) -> Unit:
	## Pilori : le provocateur, sinon le héros le plus blindé, sinon le plus proche (6 cases).
	var best: Unit = null
	var bs := -INF
	for h in heroes:
		if not h.alive or dist(h.cell, f.cell) > int(f.data.range[1]):
			continue
		var s: float = (1000.0 if h.taunt else 0.0) + h.block * 10.0 - dist(h.cell, f.cell)
		if s > bs:
			bs = s
			best = h
	return best


func _pilori(f: Unit) -> void:
	var h := chain_target(f)
	if f.turns % 2 != 0 or h == null:
		Fx.number(main, f.position + Vector3(0, 1.3, 0), "⛓ …", Color(0.8, 0.5, 0.55))
		return
	await f.cast()
	await Fx.bolt(main, f.position + Vector3(0, 1.0, 0), h.position + Vector3(0, 0.6, 0), Color(0.75, 0.3, 0.35))
	h.set_meta("chained", f)
	root_hero(h, 1)
	_first("chaine", h.position, "Enchaîné !", Color(0.75, 0.3, 0.35), "le Pilori entrave ce héros et suspend sa Provocation. Le briser le libère.")


func _summon(f: Unit, id: String) -> void:
	## L'obélisque appelle une créature à côté de lui.
	var free: Array = Board.DIRS.map(func(d): return f.cell + d).filter(func(c): return board.walkable(c) and unit_at(c) == null and not board.props.has(c))
	if free.is_empty():
		return
	await f.cast()
	var u := spawn_foe(id, free[randi() % free.size()])
	u.set_meta("summoner", f)
	u.face(u.cell - f.cell)
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.glyphe.col, 40, 3.0, 5.0)
	Fx.number(main, f.position + Vector3(0, 2.2, 0), "Appel : %s" % u.nm, Data.TILES.glyphe.col, true)
	await wait(0.4)


func floor_bonus() -> int:
	return champions  # 0 au premier étage, 1 au deuxième...


func _reflux(f: Unit) -> void:
	## Reflux : le cavalier (et la harpie) frappe puis reflue loin des héros.
	var R2 := reach(f)
	var go := f.cell
	var gs := -INF
	for cell in R2.cells:
		if R2.dist.get(cell, 99) > 3 or tiles.get(cell, "") in ["lave", "ronces"]:
			continue
		var s := 0.0
		for h in alive_heroes():
			s += minf(dist(cell, h.cell), 5)
		if s > gs:
			gs = s
			go = cell
	if go != f.cell:
		_first("reflux_cav", f.position + Vector3(0, 0.5, 0), "Reflux", Color(0.6, 0.95, 0.9), "il frappe puis reflue au loin. Le coincer contre l'eau.")
		await _foe_walk(f, path_to(R2.prev, go))


func _dance(f: Unit, R: Dictionary) -> void:
	## La Danseuse fait rejouer un allié qui a déjà agi ce round ; sinon elle se tient à l'abri.
	## Jamais une structure ni un boss.
	var done: Array = order.slice(0, qi).filter(func(o): return is_instance_valid(o) and o.alive and o.side == "foe" and o.data.ai != "dancer" \
		and not o.data.get("structure", false) and not o.data.get("no_champion", false))
	done.sort_custom(func(a, b): return a.atk() > b.atk())
	for ally in done:
		var spot = null
		var sd := 999
		for cell in R.cells:
			if dist(cell, ally.cell) == 1 and R.dist[cell] < sd and not tiles.get(cell, "") in ["lave", "ronces"]:
				sd = R.dist[cell]
				spot = cell
		if spot == null:
			continue
		if spot != f.cell:
			await _foe_walk(f, path_to(R.prev, spot))
		if not f.alive:
			return
		f.face(ally.cell - f.cell)
		await f.cast()
		Fx.burst(main, ally.position + Vector3(0, 0.8, 0), Color(0.4, 1.0, 0.9), 40, 3.0)
		Fx.number(main, ally.position + Vector3(0, 1.3, 0), "Danse : rejoue !", Color(0.5, 1.0, 0.9), true)
		await wait(0.3)
		await foe_act(ally)
		return
	# personne à faire danser : rester loin des héros, près des siens
	var go := f.cell
	var gs := -INF
	for cell in R.cells:
		var s := 0.0
		for h in alive_heroes():
			s += minf(dist(cell, h.cell), 6)
		for o in alive_foes():
			if o != f and dist(o.cell, cell) <= 2:
				s += 2
		if s > gs:
			gs = s
			go = cell
	if go != f.cell:
		await _foe_walk(f, path_to(R.prev, go))


func foe_strike(f: Unit, h: Unit) -> void:
	f.face(h.cell - f.cell)
	var ai: String = f.data.ai
	if ai == "bomb":
		await f.lunge(h.position)
		Fx.burst(main, f.position + Vector3(0, 0.6, 0), EMBER, 70, 5.0)
		main.shake(0.45)
		for d in Board.DIRS:
			var o := unit_at(f.cell + d)
			if o:
				damage(o, f.atk(), f)
		if f.has_meta("couvant"):
			f.remove_meta("couvant")
		kill(f)
		return
	var ranged: bool = f.data.range[1] > 1
	if ranged:
		await f.cast()
		await Fx.bolt(main, f.position, h.position, EMBER)
	else:
		await f.lunge(h.position)
	if ai == "puller" and dist(f.cell, h.cell) > 1:
		# la langue du crapaud (la gaffe de Brasse) ramène sa proie au contact
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Happé !", Color(0.9, 0.4, 0.5), true)
		await push(h, _dir(h.cell, f.cell), dist(f.cell, h.cell) - 1)
		if not h.alive:
			return
	f.struck_hero = true
	if f.has_meta("maree"):
		# Mage de la marée (acte 3) : une vague sur 3 cases, qui repousse le dernier touché
		var d := _dir(f.cell, h.cell)
		var last: Unit = null
		for k in 3:
			var o := unit_at(h.cell + d * k)
			if o and o.side == "hero":
				var keep := o.block
				o.block = 0
				damage(o, calc(f, o, f.atk()).dmg, f, true, true)
				o.block = keep
				if o.alive:
					last = o
		if last:
			await push(last, d, 1)
		return
	var bk := _is_back(f, h)
	var dmg: int = calc(f, h, f.atk()).dmg
	if f.data.get("arme", "") == "magie" and f.data.ai != "healer":
		var keep := h.block  # la magie passe sous l'armure
		h.block = 0
		damage(h, dmg, f, true, ranged)
		h.block = keep
	else:
		damage(h, dmg, f, true, ranged)
	if bk and h.alive:  # frappé de dos, il fait face : le suivant du même côté frappe de face
		h.face(f.cell - h.cell)
	if ai == "boss":
		main.shake(0.5)
		for d in Board.DIRS:
			var o := unit_at(h.cell + d)
			if o and o.side == "hero":
				damage(o, 4, f)
	if ai == "anguille" and h.alive and f.alive:
		# la morsure tire le héros d'une case vers elle : dans l'eau s'il y en a
		for d in Board.DIRS:
			var c: Vector2i = h.cell + d
			if board.kind.get(c, "") == "water" and unit_at(c) == null and dist(c, f.cell) <= 1:
				await push(h, d, 1)
				break
	if ai == "burrow" and board._in(h.cell) and board.kind[h.cell] != "water":
		_foe_omen("fissure", [h.cell], f)
		_first("fissure", h.position, "Le sol se fend", Color(0.9, 0.7, 0.4), "cette case s'effondre au prochain round, sous n'importe qui.")
	if f.data.get("shove", 0) > 0 and h.alive and f.alive:
		await push(h, _dir(f.cell, h.cell), int(f.data.shove))


# ------------------------------------------------------------------ surbrillance

var _plan_mark: Label3D
func _mark3d(t: String, size: int, col: Color) -> Label3D:
	## Étiquette 3D lisible à travers le décor (flèche d'orientation, déplacement prévu).
	var l := Label3D.new()
	l.text = t
	l.font = Fx.title_font()
	l.font_size = size
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = col
	l.outline_size = 16
	l.outline_modulate = Color(0.1, 0.05, 0.02, 0.9)
	l.render_priority = 10
	l.outline_render_priority = 9
	units_root.add_child(l)
	return l


func refresh_highlight(hover) -> void:
	## Pas de grille permanente : contours pour la portée, cases pleines pour les choix.
	var cells := {}
	# où regarde le héros actif : une petite flèche dorée sur la case devant lui (clic droit ailleurs pour le tourner)
	var show_face: bool = player_turn and active != null and active.alive and not busy
	if show_face and _orient_mark == null:
		_orient_mark = _mark3d("⇩", 80, Color(1.0, 0.82, 0.35))
	if _orient_mark:
		_orient_mark.visible = show_face
		if show_face:
			var fp := board.world(active.cell + active.facing) if board._in(active.cell + active.facing) else active.position + Vector3(active.facing.x, 0, active.facing.y)
			_orient_mark.position = Vector3(fp.x, maxf(fp.y, active.position.y) + 0.55, fp.z)
	# déplacement en deux clics : l'étiquette du second clic
	var plan_ok: bool = _move_plan != null and player_turn and not busy and selected != null and card_sel < 0
	if plan_ok and _plan_mark == null:
		_plan_mark = _mark3d("", 44, Color(1.0, 0.9, 0.6))
	if _plan_mark:
		_plan_mark.visible = plan_ok
		if plan_ok:
			_plan_mark.text = "Course · 3 mana
recliquer pour courir" if selected.moved else "Recliquer : y aller"
			_plan_mark.modulate = Color(1.0, 0.7, 0.3) if selected.moved else Color(1.0, 0.92, 0.65)
			_plan_mark.position = board.world(_move_plan) + Vector3(0, 1.1, 0)
	if player_turn and not busy:
		if card_sel >= 0 and card_sel < hand.size():
			var c := Data.card(hand[card_sel])
			var h := owner_of(c)
			var col := Color(1.0, 0.3, 0.22)
			if c.has("heal") or c.has("heal_all") or c.has("block"):
				col = Color(0.45, 1.0, 0.5)
			elif c.kind == "move" or c.has("place"):
				col = Color(0.15, 0.9, 1.0)
			for t in range_cells(c, h):
				cells[t] = Color(col.r, col.g, col.b, 0.35)
			var tg := card_targets(c, h)
			var tele: bool = c.kind == "move" or c.get("blink", false) or c.id == "ombre"
			for t in tg:
				cells[t] = Color(col.r, col.g, col.b, 0.95)
				if tele and alive_foes().any(func(o): return int(o.data.get("guet", 0)) > 0 and dist(o.cell, t) <= int(o.data.guet)):
					cells[t] = Color(1.0, 0.35, 0.3, 0.95)  # sous l'œil de la Pisteuse
			if hover != null and tg.has(hover) and c.get("target", "foe") == "line":
				var dp = _dash_path(h, hover, card_range(c, h).y)
				if dp != null:
					for pc in dp:
						cells[pc] = Color(1.0, 0.86, 0.4, 0.9)  # le chemin de la ruée
			if hover != null and tg.has(hover) and c.get("aoe", false):
				for d in Board.DIRS:
					if board._in(hover + d):
						cells[hover + d] = Color(1.0, 0.6, 0.2, 0.9)
		elif selected and selected.alive and (not selected.moved or can_sprint(selected)):
			var sp := selected.moved
			var R := reach(selected)
			for t in R.cells:
				if t != selected.cell:
					cells[t] = SPRINT_COL if sp else Color(0.4, 0.68, 1.0, 0.75)  # la course (3 mana) en orange
			if _move_plan != null and R.cells.has(_move_plan):
				for pc in path_to(R.prev, _move_plan):
					cells[pc] = Color(1.0, 0.86, 0.4, 0.95)
			for pc in board.props:
				if board.props[pc] == "coffre" and dist(pc, selected.cell) == 1:
					cells[pc] = Color(1.0, 0.85, 0.35, 0.95)
		# zone de déplacement de l'ennemi épinglé ou survolé
		var look: Unit = inspect if inspect and inspect.alive else null
		if look == null and hover != null:
			look = unit_at(hover)
		if card_sel < 0 and look and look.side == "foe":
			for t in reach(look).cells:
				cells[t] = Color(1.0, 0.45, 0.2, 0.6)
			var ar: int = {"fanal": 3, "etendard": 2, "ordre": 2}.get(look.data.get("aura", ""), 0)
			if int(look.data.get("guet", 0)) > 0:
				ar = int(look.data.guet)
			for x in range(-ar, ar + 1):
				for z in range(-ar, ar + 1):
					var t: Vector2i = look.cell + Vector2i(x, z)
					if ar > 0 and absi(x) + absi(z) <= ar and board._in(t) and not cells.has(t):
						cells[t] = Color(1.0, 0.72, 0.36, 0.3)  # l'anneau de son aura
	for t in omen_cells():
		if not cells.has(t) or cells[t].a < 0.5:
			cells[t] = OMEN_COL
	if danger:
		for t in threat_cells():
			if not cells.has(t):
				cells[t] = Color(1.0, 0.25, 0.2, 0.34)
	if hover != null:
		cells[hover] = Color(1, 1, 1, 0.45) if not cells.has(hover) else Color(cells[hover].lightened(0.45), maxf(cells[hover].a, 0.6))
	for f in foes:
		if f.alive:
			f.set_xray(hover != null and f.cell == hover)
	var alt := Input.is_key_pressed(KEY_ALT)
	for pc in prop_nodes:
		var nd: Node3D = prop_nodes[pc]
		if nd.has_meta("mark"):
			nd.get_meta("mark").visible = alt or pc == hover or cells.has(pc)
	board.highlight(cells)


func threat_cells() -> Dictionary:
	## Toutes les cases qu'un ennemi peut frapper ce tour (déplacement + portée).
	var out := {}
	for f in alive_foes():
		if f.data.ai in IDLE_AI or f.data.get("structure", false):
			continue
		var r: Array = f.data.range
		var from: Dictionary = reach(f).cells if f.root <= 0 else {f.cell: true}
		for c in from:
			for dx in range(-r[1], r[1] + 1):
				var w: int = r[1] - absi(dx)
				for dz in range(-w, w + 1):
					var t: Vector2i = c + Vector2i(dx, dz)
					if absi(dx) + absi(dz) >= r[0] and board._in(t) and board.kind[t] != "tower":
						out[t] = true
	return out


func predict(u: Unit, hover) -> Dictionary:
	## Dégâts prévus sur u par la carte en main, si u est la cible survolée.
	if card_sel < 0 or card_sel >= hand.size() or hover == null or u.cell != hover:
		return {}
	var c := Data.card(hand[card_sel])
	var h := owner_of(c)
	if c.get("dmg", 0) <= 0 or not card_targets(c, h).has(hover):
		return {}
	var r := card_total(h, u, c)
	if _trig_dmg(c, h, u.cell) > 0:
		r.notes.append(Data.TRIGGERS[c.trig.on].name)
	return r


func incoming(h: Unit) -> int:
	## Concile du 29/09 : ce que les ennemis peuvent infliger à h d'ici son prochain tour, chacun son meilleur coup
	## sur lui (même procédé que l'IA). Orientation, Marque et soutien comptent : tourner ou grouper le héros se lit ici.
	var total := 0
	for f: Unit in alive_foes():
		if f.data.ai in IDLE_AI or f.data.get("structure", false) or int(f.data.get("dmg", 0)) <= 0:
			continue
		var saved: Vector2i = f.cell
		var rc = reach(f).cells
		var cells: Array = [f.cell] if f.root > 0 else (rc.keys() if rc is Dictionary else rc)
		var best := 0
		for cell in cells:
			f.cell = cell
			if can_hit(f, cell, h):
				best = maxi(best, calc(f, h, f.atk()).dmg)
		f.cell = saved
		total += best
	return total


func preview(hover) -> String:
	if hover == null:
		return ""
	var u := unit_at(hover)
	if card_sel >= 0 and card_sel < hand.size() and u and u.side == "foe":
		var c := Data.card(hand[card_sel])
		var h := owner_of(c)
		if card_targets(c, h).has(hover) and c.get("dmg", 0) > 0:
			var r := card_total(h, u, c)
			var t := "%s — %d dégâts" % [u.nm, r.dmg]
			if r.notes.size() > 0:
				t += "  (" + " · ".join(r.notes) + ")"
			return t
	if u:
		var t := "%s  %d/%d PV" % [u.nm, u.hp, u.max_hp]
		if u.block > 0:
			t += "  🛡%d" % u.block
		if u.poison > 0:
			t += "  ☠%d" % u.poison
		if u.side == "hero" and not over:
			var m := incoming(u)
			if m > 0:
				t += "  ·  Menace %d%s" % [m, " — mortel !" if m >= u.hp + u.block else ""]
		if u.side == "foe":
			t += "  —  %s" % Data.FOE_TIPS.get(u.key, "")
			if u.affix != "":
				t += "  ♛ " + Data.AFFIXES[u.affix].text
			if u.tool != "":
				t += "  ·  porte %s %s" % [Data.TOOLS[u.tool].glyph, Data.TOOLS[u.tool].name]
		if tiles.has(hover):
			t += "  ·  sur %s" % Data.TILES[tiles[hover]].name
		var ps: Array = u.passives()
		if ps.size() > 0:
			t += "  ·  " + ", ".join(ps.map(func(p): return Data.PASSIVES[p].name))
		return t
	if loot.has(hover):
		return "Butin : %s — un héros qui y passe en prend la carte" % Data.def(Data.obj_of(loot[hover][0])).name
	if tiles.has(hover):
		var tl: Dictionary = Data.TILES[tiles[hover]]
		return "%s — %s" % [tl.name, tl.text]
	if ground.has(hover):
		return "%s — %s" % [Data.GROUND[ground[hover]].name, Data.GROUND[ground[hover]].text]
	if oaks.has(hover):
		var th: String = " — %d/%d PV" % [tree_hp.get(hover, 0), oak_max.get(hover, 10)]
		if smolder.has(hover):
			return "Ce chêne couve : il prendra feu à la prochaine manche" + th
		if int(oak_aura.get(hover, 0)) > 0:
			return "Chêne%s · +%d armure aux héros voisins%s. Frappe-le pour l'abattre." % [th, oak_aura[hover], " · le feu ne le consume pas" if oak_fp.has(hover) else ""]
		return "Arbre%s. Frappe-le pour l'abattre. Le feu le consume et gagne les arbres voisins." % th
	if smoke.has(hover):
		return "Fumée (%d tour(s)) — on n'y vise pas de loin ; au contact, coups de dos" % smoke[hover]
	if traps.has(hover):
		return "Picots — l'ennemi qui y marche s'arrête et subit 5" if trap_kind.get(hover, "") == "picots" else "Piège à mâchoires — 8 dégâts et entrave"
	if board.props.has(hover):
		var pk: String = board.props[hover]
		if pk == "bombe_retard" and bombs.has(hover):
			return "%s — %s" % [Data.PROPS[pk].name, Data.PROPS[pk].text % [int(bombs[hover].n), int(bombs[hover].dmg)]]
		if Data.PROPS.has(pk):
			return "%s — %s" % [Data.PROPS[pk].name, Data.PROPS[pk].text]
		return "Levier actionné"
	if objective == "portal" and hover == board.portal:
		return "Portail — un héros qui s'y arrête termine le combat"
	if board._in(hover):
		var k: String = board.kind[hover]
		if k == "water":
			return "Eau profonde — y pousser un ennemi le noie"
		if board.blocked.has(hover):
			return "Arbre"
		if k == "tower":
			return "Tour"
		return "Hauteur %d" % board.h[hover]
	return ""


# ------------------------------------------------------------------ fiche d'unité

func sheet(u: Unit) -> String:
	var L: Array = []
	L.append("PV %d / %d%s%s" % [u.hp, u.max_hp, "   🛡 %d" % u.block if u.block > 0 else "", "   ☠ %d" % u.poison if u.poison > 0 else ""])
	L.append("Déplacement %d · Saut %d%s" % [u.move, u.jump, " · vole" if u.fly else ""])
	if u.mark > 0:
		L.append("◎ Marqué %d tour(s) : +50 %% de dégâts reçus" % u.mark)
	if u.root > 0:
		L.append("⛓ Entravé %d tour(s) : ne bouge plus" % u.root)
	for st in [["echouee", "Échouée : ×1,5 aux coups reçus"], ["amarre", "Amarré : la Bitte encaisse 40 % de ses coups"], ["chained", "Enchaîné au Pilori : Provocation suspendue"],
			["englue", "Englué : −1 déplacement à son prochain tour"], ["asseche", "Asséché : pas d'armure à son prochain tour"]]:
		if u.has_meta(st[0]):
			L.append(st[1])
	if u.side == "foe" and _in_aura(u, "fanal", 3) and u.key != "fanal":
		L.append("☀ Dans la lumière du Fanal : pas de coup de dos")
	if u.side == "foe" and anchored(u) and not u.has_p("ancre"):
		L.append("Ancré pour l'instant : ni poussé ni attiré")
	if u.companion:
		L.append("Compagnon — joue seul, du côté des héros. " + Data.COMPANIONS[u.key].text)
		return "\n".join(L)
	if u.side == "hero":
		L.append("Trait — %s : %s" % [Data.TRAITS[u.trait_id].name, Data.TRAITS[u.trait_id].text])
		L.append(main.voc_line(u))
		var worn: Array = Data.SLOTS.filter(func(sl): return u.equip.get(sl, "") != "").map(func(sl): return Data.ITEMS[u.equip[sl]].name)
		L.append("Équipement — %s" % (", ".join(worn) if worn.size() > 0 else "rien") + " · clic sur son portrait : la fiche")
		if u.key == "receleur":
			L.append("Double fond : ses objets ne comptent pas dans sa main · Tour de main : ses objets +2 (sinon pioche 1) · Stock %d" % stock())
		if tiles.has(u.cell):
			L.append("Sur %s : %s" % [Data.TILES[tiles[u.cell]].name, Data.TILES[tiles[u.cell]].text])
		var n := hand.filter(func(ci): return Data.card(ci).owner == u.key).size()
		L.append("Cartes en main : %d%s" % [n, " · a déjà bougé" if u.moved else ""])
		return "\n".join(L)
	# fiche ennemie en sections (« ## » = titre de section, « ~ » = note discrète) : ui.set_sheet les met en forme
	L.append("## Prochaine action")
	L.append("%s — %s" % [intent(u), _intent_text(u)])
	var cap: Array = []
	var arm := int(u.data.get("armor", 0)) + u.extra_armor
	if arm > 0:
		cap.append("Armure : +%d à chaque tour" % arm)
	if u.data.get("arme", "") == "magie":
		cap.append("Magie : ses coups passent sous l'armure.")
	if u.affix != "":
		cap.append("♛ %s : %s" % [Data.AFFIXES[u.affix].name, Data.AFFIXES[u.affix].text])
	for q in u.passives():
		cap.append("%s : %s" % [Data.PASSIVES[q].name, Data.PASSIVES[q].text])
	if cap.size() > 0:
		L.append("## Capacités")
		L.append_array(cap)
	var gear: Array = []
	if u.card_id != "":
		var left := (" Encore %d tour(s)." % (3 - u.flee_n)) if u.card_cond == "fuite" else ""
		gear.append("🃏 %s : garde %s. %s%s" % [Data.CARD_CONDS[u.card_cond].name, Data.def(u.card_id).name, Data.CARD_CONDS[u.card_cond].text, left])
	for sl in u.equip:
		if u.equip[sl] != "":
			gear.append("⚙ %s : %s" % [Data.ITEMS[u.equip[sl]].name, Data.item_text(u.equip[sl]).split("\n")[1]])
	if u.tool != "":
		var td: Dictionary = Data.TOOLS[u.tool]
		gear.append("%s %s : il %s. Vole-le, sa carte arrive dans ta main." % [td.glyph, td.name, td.get("foe_ai", "s'en servira")])
	if gear.size() > 0:
		L.append("## Il porte")
		L.append_array(gear)
	if Data.FOE_TIPS.get(u.key, "") != "":
		L.append("## Conseil")
		L.append(Data.FOE_TIPS[u.key])
	L.append("~ Zone orange : où il peut aller ce tour.")
	return "\n".join(L)


func _intent_text(f: Unit) -> String:
	var dmg: int = f.atk()
	var rg: Array = f.data.range
	match f.key:
		"guetteur":
			return "Tire entre %d et %d cases : %d dégâts. Un tour sur deux, il repère une cible au lieu de tirer : ×1,5 pour ses alliés." % [rg[0], rg[1], dmg]
		"frondeur":
			return "Tire entre %d et %d cases : %d dégâts, +3 s'il est plus haut que sa cible." % [rg[0], rg[1], dmg]
		"pisteuse":
			return "Tire entre %d et %d cases : %d dégâts. Tire aussitôt sur qui se téléporte à 5 cases d'elle, et l'expose." % [rg[0], rg[1], dmg]
		"pavoiseur":
			return "Avance et frappe au contact : %d dégâts. De face, les coups qu'il reçoit sont divisés par deux." % dmg
		"noye_ancien":
			return "Frappe au contact : %d dégâts, +3 depuis l'eau, où il est ancré." % dmg
		"porte_etendard":
			return "Frappe au contact : %d dégâts. Rien ne se pousse à 2 cases de lui." % dmg
		"vouivre":
			return "Frappe %d au contact ; un tour sur deux, emporte un héros voisin de 2 cases, vers l'eau." % dmg
		"wisp":
			return "Fonce et explose au contact : %d dégâts sur les 4 cases autour, alliés compris." % dmg
		"lancier":
			return "Frappe à 1 ou 2 cases : %d dégâts. Côte à côte avec un autre lancier : +3 armure, riposte 8." % dmg
		"harpie":
			return "Frappe %d puis reflue ; +2 par sœur qui a déjà frappé la même cible ce round." % dmg
		"bretteur":
			return "Fond sur un héros : %d dégâts, ×1,5 si la cible a déjà été touchée ce round." % dmg
		"brasse":
			return "Attire un héros à 2 cases et frappe %d ; ×1,5 s'il a déjà été touché ce round." % dmg
		"hale":
			return "Garde Brasse : prend pour elle le premier coup du round. Frappe %d et riposte au contact." % dmg
		"sentinelle":
			return "Frappe %d au contact. Ancrée ; quitter son contact coûte un coup de %d." % [dmg, maxi(1, roundi(dmg * 0.5))]
		"mage":
			if f.has_meta("maree"):
				return "Vague sur 3 cases : %d dégâts sous l'armure à chaque héros, repousse le dernier." % dmg
		"fanal":
			return "Éclaire 3 cases : pas de coup de dos sur ses alliés, +1 portée à leurs tireurs. Éteint, il les laisse exposés."
		"treuil":
			return "Donne +3 d'armure à Grelin à chacun de ses tours. Cassé, il expose Grelin."
		"vanne_dame":
			return "Nourrit la crue de la Dame. Toutes les vannes cassées, l'eau cesse de monter."
	match f.data.ai:
		"melee":
			return "Avance et frappe au contact : %d dégâts." % dmg
		"ranged":
			return "Tire entre %d et %d cases : %d dégâts." % [rg[0], rg[1], dmg]
		"bomb":
			return "Fonce et explose au contact : %d dégâts autour de lui." % dmg
		"healer":
			return "Soigne un quart de vie et +3 armure à un allié sous 60 %%, sinon tire : %d dégâts." % dmg
		"assassin":
			return "Fond sur le héros isolé, puis le plus faible : %d dégâts." % dmg
		"boss":
			match f.get_meta("phase", 0):
				0:
					return "Frappe %d au contact, 4 aux voisins de sa cible, riposte 6. Appelle 2 Moussus tous les 3 rounds." % dmg
				1:
					return "Frappe %d au contact, riposte 6. Deux vannes inondent la berge ; l'Appel fait venir un Éclusier fou." % dmg
			return "Un tour sur deux, annonce le Coup de digue : 22 dégâts et une poussée de 2 sur la ligne rouge. Sinon frappe %d." % dmg
		"reflux":
			return "Frappe %d au contact, puis reflue jusqu'à 3 cases." % dmg
		"dancer":
			return "Fait rejouer un allié qui a déjà agi ce round."
		"spawner":
			return "Appelle une créature à côté de lui au début du round. Abattu, il étourdit ce qu'il a appelé."
		"puller":
			return "Attire un héros jusqu'à lui depuis %d cases, puis mord : %d dégâts." % [rg[1], dmg]
		"commander":
			return "Tient sa position jusqu'à ce qu'un héros approche à 4 cases ou le touche, puis charge (+2 déplacement) : %d. Ses soldats à 2 cases frappent +2 et courent +1." % dmg
		"anguille":
			return "Mord depuis l'eau un héros sur la berge : %d, et le tire d'une case vers elle, dans l'eau si elle peut." % dmg
		"tether":
			return "S'amarre à ses deux alliés les plus solides : 40 % des coups qu'ils reçoivent passent dans la bitte."
		"flood":
			return "Inonde 2 cases de berge près de vous au prochain round, pour tout le monde (8 cases au plus)."
		"pilori":
			return "Un tour sur deux, enchaîne un héros à 6 cases (le provocateur d'abord) : entravé, Provocation suspendue."
		"chevrier":
			return "Chaque tour, coupe le pont le plus proche de vous (il tombe à l'eau au round suivant), puis frappe %d. À mi-vie, sonne la corne : deux chèvres." % dmg
		"dame":
			return "Chaque tour, la crue avance d'un rang depuis un bord de l'arène (deux à mi-vie) tant qu'une vanne tient. Magie : %d. Poussée dans l'eau, elle s'y noie." % dmg
		"brule":
			return "Chaque tour, fait couver l'arbre le plus proche de vous : il flambe au round suivant (6 autour) et gagne ses voisins. Magie : %d." % dmg
		"eclusier":
			return "Frappe %d à 1-2 cases. Tous les 3 tours (2 en phase 2), annonce une Chasse d'eau : la ligne rouge est poussée de 2 cases, ses alliés compris." % dmg
		"guard":
			return "Se colle à son protégé et prend pour lui le premier coup du round. Frappe %d." % dmg
		"cleanser":
			return "Purifie un allié (Marque, poison, Entrave) et renvoie sa Marque au héros le plus proche. Sinon, magie : %d." % dmg
		"sapper":
			return "Un tour sur deux, pose un baril près de votre groupe : 10 sur 5 cases au prochain round. Sinon frappe %d." % dmg
		"burrow":
			return "Frappe %d ; la case touchée s'effondre au prochain round." % dmg
	return ""


# ------------------------------------------------------------------ pièges, tourelles, pouvoirs

func _count_hit(h: Unit) -> void:
	## Enchaînement du Moine ; la Voie du poing récompense chaque 3e coup. Corde à nœuds : le 4e coup du tour, toutes classes.
	if h == active:
		_hits_turn += 1
		if _hits_turn == 4 and has("corde_noeuds"):
			draw(1)
			Fx.number(main, h.position + Vector3(0, 1.3, 0), "Corde à nœuds · pioche 1", GOLD_FX)
	if h.key != "moine" and h.voc != "moine" and h.voc2 != "moine":
		return
	h.combo += 1
	if h.combo >= 2:
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Enchaînement ×%d" % h.combo, Data.CLASS_COLOR.moine.lightened(0.3))
	if powers.has("voie") and h.combo % (3 - int(power_val.get("voie", 0))) == 0:
		energy += 1
		draw(1)
		Fx.number(main, h.position + Vector3(0, 1.3, 0), "+1 énergie", GOLD_FX)


func _place(c: Dictionary, t: Vector2i, h: Unit) -> void:
	var k: String = c.place
	h.face(t - h.cell)
	await h.cast()
	if unit_at(t) or board.props.has(t) or traps.has(t) or not board.walkable(t):
		return
	if k in TRAP_KINDS:
		var spots: Array = [t]
		if c.get("twin", false):
			for d in Board.DIRS:
				var n: Vector2i = t + d
				if board.walkable(n) and unit_at(n) == null and not traps.has(n) and not board.props.has(n):
					spots.append(n)
					break
		for sp: Vector2i in spots:
			_make_trap(sp, k, int(c.get("tdmg", 8)))
		if c.get("plus_baril", false):
			for d in Board.DIRS:
				var n: Vector2i = t + d
				if board.walkable(n) and unit_at(n) == null and not traps.has(n) and not board.props.has(n):
					board.props[n] = "baril"
					_make_prop(n)
					break
	else:
		board.props[t] = k
		_make_prop(t)
		if k == "bombe_retard":
			bombs[t] = {"n": int(c.get("delay", 2)), "dmg": int(c.get("tdmg", 6))}  # delay : rounds avant l'explosion
		if k == "tourelle":
			var tt := int(c.get("turns", 3))
			if c.get("turns_items", false):
				tt = maxi(tt, stock())
			turrets[t] = {"turns": tt, "dmg": int(c.get("tdmg", 4)) + (2 if h.has_p("bordee") else 0), "push": int(c.get("tpush", 0)), "mark": c.get("tmark", false),
				"pierce": c.get("tpierce", false), "far": c.get("tfar", false), "range": int(c.get("trange", 5)),
				"grow": int(c.get("tgrow", 0)), "base": int(c.get("tdmg", 4))}
	Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Data.CLASS_COLOR[h.key].lightened(0.2), 26, 2.5, 5.0)
	await wait(0.2)


func _make_trap(sp: Vector2i, k: String, td: int) -> void:
	var node := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = Board.mesh_of("prop_picots" if k == "epieu" else "prop_piege").mesh
	mi.material_override = Board.material("prop")
	node.add_child(mi)
	node.position = board.world(sp)
	if k in ["mine", "ombre", "collet"]:
		var l3 := Label3D.new()
		l3.text = {"mine": "✹", "ombre": "◎", "collet": "◆"}[k]
		l3.font = Fx.title_font()
		l3.font_size = 64
		l3.pixel_size = 0.004
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.modulate = {"mine": EMBER, "ombre": Color(0.85, 0.6, 1.0), "collet": GOLD_FX}[k]
		l3.outline_size = 14
		l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
		l3.position.y = 0.45
		node.add_child(l3)
	units_root.add_child(node)
	traps[sp] = node
	trap_kind[sp] = k
	trap_dmg[sp] = td


func _foe_walk(f: Unit, path: Array) -> void:
	## Un piège sur le chemin arrête l'ennemi net.
	var cut := path.size()
	for i in path.size():
		if traps.has(path[i]) and (unit_at(path[i]) == null or unit_at(path[i]) == f):
			cut = i + 1
			break
	path = path.slice(0, cut)
	if path.is_empty():
		return
	await f.walk(path, board)
	if traps.has(f.cell):
		await _spring(f)
	if f.alive:
		await _landed(f)


func _spring(f: Unit) -> void:
	## Piège à mâchoires (8, entrave) ou picots (5) : l'ennemi s'arrête dessus.
	var node: Node3D = traps[f.cell]
	_terrain_mark = 1 if f.mark > 0 else 0  # Détente, Collet de crin, Instinct marquent au déclic : pas pour ce piège-ci
	_terrain = true
	var k: String = trap_kind.get(f.cell, "piege")
	var td: int = trap_dmg.get(f.cell, 8)
	traps.erase(f.cell)
	trap_kind.erase(f.cell)
	trap_dmg.erase(f.cell)
	picot_root.erase(f.cell)
	node.queue_free()
	main.shake(0.35 if k == "piege" else 0.2)
	Fx.number(main, f.position + Vector3(0, 0.6, 0), "Piège !" if k == "piege" else "Picots !", Color(1.0, 0.8, 0.4), true)
	Fx.burst(main, f.position + Vector3(0, 0.3, 0), Color(0.75, 0.7, 0.6), 30, 3.0)
	traps_fired += 1
	for a in alive_heroes():
		if a.has_p("detente") and a.get_meta("detente_round", -1) != turn:
			a.set_meta("detente_round", turn)  # Détente : une fois par round
			_gain_energy(a, 1)
			f.mark = maxi(f.mark, 2)
	if has("collet_crin"):
		f.mark = maxi(f.mark, 2)
	var plus := (int(power_val.get("hallali", 4)) if powers.has("hallali") else 0) + (int(power_val.get("crane", 3)) if powers.has("crane") else 0) 		+ (4 if has("piquet_frene") else 0)
	var cell := f.cell
	for rep_i in (2 if double_trap else 1):
		if not f.alive:
			break
		match k:
			"piege":
				f.root = maxi(f.root, 1 + (int(power_val.get("instinct2", 0)) if powers.has("instinct") else 0))  # Instinct niveau 3 : un tour de plus
				if powers.has("instinct"):
					f.mark = maxi(f.mark, 2)
				_cause = "piege"
				damage(f, td + plus + (6 + int(power_val.get("instinct", 0)) if powers.has("instinct") else 0))
				_cause = ""
			"mine":
				f.mark = maxi(f.mark, 2)
				_explode(cell, td + plus)
			"epieu":
				f.root = maxi(f.root, 2)
				damage(f, td + plus)
			"ombre":
				f.root = maxi(f.root, 2)
				f.mark = maxi(f.mark, 2)
				damage(f, td + plus)
			"collet":
				f.root = maxi(f.root, 1)
				_steal(active if active else heroes[0], f)
				damage(f, td + plus)
			_:
				if int(picot_root.get(cell, 0)) > 0:
					f.root = maxi(f.root, int(picot_root[cell]))
				damage(f, td + plus)  # les picots portent leurs dégâts (trap_dmg)
		if rep_i == 0 and k != "mine" and powers.has("piquets"):
			var po: Unit = power_owner.get("piquets")
			if po and po.alive:
				gain_block(po, maxi(1, int(power_val.get("piquets", 4))))
			if f.alive:
				f.exposed = true
				Fx.number(main, f.position + Vector3(0, 1.0, 0), "Exposé", Color(1.0, 0.75, 0.45))
				if int(power_val.get("piquets2", 0)) > 0:
					f.mark = maxi(f.mark, int(power_val.piquets2))  # Piquets niveau 3
		if double_trap and rep_i == 0:
			Fx.number(main, f.position + Vector3(0, 0.9, 0), "Deux fois !", Color(1.0, 0.8, 0.4), true)
			await wait(0.2)
	_terrain = false
	_terrain_mark = -1
	if powers.has("crane"):
		_craft(1)
	await wait(0.3)


func _turrets_fire() -> void:
	for c in turrets.keys():
		var tr: Dictionary = turrets[c]
		var rg: int = int(tr.get("range", 5))
		var best: Unit = null
		var cands: Array = alive_foes().filter(func(f): return dist(f.cell, c) <= rg)
		if tr.get("far", false) and cands.any(func(f): return f.mark > 0):
			cands = cands.filter(func(f): return f.mark > 0)
		for f in cands:
			if best == null or (dist(f.cell, c) > dist(best.cell, c) if tr.get("far", false) else dist(f.cell, c) < dist(best.cell, c)):
				best = f
		if best:
			await Fx.bolt(main, board.world(c) + Vector3(0, 0.7, 0), best.position, Data.CLASS_COLOR.artificier.lightened(0.3))
			if tr.get("pierce", false):
				best.block = 0
			damage(best, int(tr.dmg))
			if int(tr.get("grow", 0)) > 0:
				tr.dmg = mini(int(tr.dmg) + int(tr.grow), 3 * int(tr.get("base", 4)) + 6)
			if best.alive and tr.get("mark", false):
				best.mark = maxi(best.mark, 2)
			if best.alive and int(tr.get("push", 0)) > 0:
				await push(best, _dir(c, best.cell), int(tr.push))
			await wait(0.15)
		turrets[c].turns -= 1
		if turrets[c].turns <= 0:
			turrets.erase(c)
			_remove_prop(c)
		if over:
			return


func _power_ticks(h: Unit) -> void:
	## Au début du tour de leur héros : cendres de l'Oracle, barils de l'Artificier, bricolage du Receleur.
	if h.key == "oracle" and powers.has("cendres"):
		var near: Array = alive_foes()
		near.sort_custom(func(a, b): return dist(a.cell, h.cell) < dist(b.cell, h.cell))
		for f in near.slice(0, 1 + int(power_val.get("cendres2", 0))):
			Fx.burst(main, f.position + Vector3(0, 1.2, 0), EMBER, 40, 4.0)
			damage(f, 4 + int(power_val.get("cendres", 0)))
	if h.key == "artificier" and powers.has("atelier"):
		for n in 1 + int(power_val.get("atelier", 0)):
			var live := alive_foes()
			if live.is_empty():
				break
			var f: Unit = live[randi() % live.size()]
			for d in Board.DIRS:
				var t: Vector2i = f.cell + d
				if board.walkable(t) and unit_at(t) == null and not traps.has(t):
					board.props[t] = "baril"
					_make_prop(t)
					Fx.burst(main, board.world(t) + Vector3(0, 0.3, 0), Data.CLASS_COLOR.artificier, 20, 2.0)
					break
	if h.key == "receleur" and powers.has("poches"):
		_craft(1 + int(power_val.get("poches", 0)), h)


# ------------------------------------------------------------------ déclencheurs

func _trig_ok(c: Dictionary, h: Unit, t) -> bool:
	## Condition du déclencheur avant de jouer (Coup de grâce se vérifie après).
	if not c.has("trig") or h == null:
		return false
	match c.trig.on:
		"mur":
			return h.hp * 10 < h.max_hp * 3
		"enchaine":
			return played >= 1
		"premier":
			return played == 0
		"surplomb":
			return t != null and board._in(t) and board.h[h.cell] > board.h[t]
		"precision":
			return t != null and absi(dist(h.cell, t) - card_range(c, h).y) <= (1 if powers.has("aelis") else 0)
		"tenaille":
			var f: Unit = unit_at(t) if t != null else null
			if f == null or f.side != "foe":
				return false
			var o := unit_at(t + _dir(h.cell, t))
			return o != null and o.side == "hero" and o != h
		"proie":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and (f.mark > 0 or f.root > 0)
		"attaque":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and f.struck_hero
		"chasse":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and f.pushed
		"poudre":
			return booms > 0
		"blesse":
			return hurt_turn
		"immobile":
			return not h.walked
		"regain":
			return heal_turn
		"declic":
			return traps_fired > h.trap_seen
		"dos":
			var f: Unit = unit_at(t) if t != null else null
			if f == null or f.side != "foe":
				return false
			if c.get("behind", false) or c.get("vault", false) or h.ambush or f.exposed or (smoke.has(f.cell) and dist(h.cell, f.cell) == 1):
				return true
			var dot := f.facing.x * signi(h.cell.x - f.cell.x) + f.facing.y * signi(h.cell.y - f.cell.y)
			return dot < 0 and not f.has_p("vigilance")
		"empoisonne":
			var f: Unit = unit_at(t) if t != null else null
			return f != null and f.side == "foe" and f.poison > 0
		"sol":
			return t != null and tiles.has(t)
		"bondi":
			return h.teles > 0
		"butin":
			return stolen_turn > 0
		"grixis":
			var v: Array = voices.duplicate()
			for vk in ["voix", "voix2"]:
				if c.has(vk) and not v.has(c[vk]):
					v.append(c[vk])
			return v.has("B") and v.has("R") and v.has("N")
	return false


func trig_live(c: Dictionary) -> bool:
	## Pour faire briller la carte en main : conditions qui ne dépendent pas de la cible.
	var h := owner_of(c)
	return c.has("trig") and h != null and h.alive and c.trig.on in ["mur", "enchaine", "premier", "grixis", "poudre", "blesse", "immobile", "bondi", "butin", "regain", "declic"] and _trig_ok(c, h, null)


func _trig_dmg(c: Dictionary, h: Unit, t) -> int:
	if not c.has("trig") or c.trig.on == "grace":
		return 0
	if _resolving:
		return int(c.trig.get("dmg", 0)) if _pre else 0  # la condition d'avant le coup (un bond ne la change plus)
	return int(c.trig.get("dmg", 0)) if _trig_ok(c, h, t) else 0


func _trig_apply(c: Dictionary, h: Unit, t) -> bool:
	## Effets hors dégâts ; renvoie vrai si la carte revient en main.
	var tr: Dictionary = c.trig
	Fx.number(main, h.position + Vector3(0, 1.1, 0), Data.TRIGGERS[tr.on].name + " !", Color(1.0, 0.85, 0.4))
	if tr.has("block"):
		gain_block(h, tr.block)
	if tr.has("heal"):
		heal(h, tr.heal)
	if tr.has("draw"):
		draw(tr.draw)
	if tr.has("energy"):
		energy += tr.energy
	if tr.has("poison") and t != null:
		var f := unit_at(t)
		if f and f.alive and f.side == "foe":
			f.poison += tr.poison
	if tr.get("keep", false):
		h.keep_block = true
	if tr.has("craft"):
		_craft(int(tr.craft), h)
	if (tr.has("mark") or tr.has("boom")) and t != null:
		var f: Unit = _struck if _struck != null and _struck.alive else unit_at(t)
		if f and f.alive and f.side == "foe":
			if tr.has("mark"):
				f.mark = maxi(f.mark, int(tr.mark))
			if tr.has("boom"):
				_boom_foes(f.cell, int(tr.boom))
	changed.emit()
	return tr.get("refund", false)


func _reinforce() -> void:
	## Modificateur Renforts : deux Moussus au plus loin des héros.
	var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and not board.props.has(c))
	free.sort_custom(func(a, b): return _hero_dist(a) > _hero_dist(b))
	for i in mini(2, free.size()):
		var u := spawn_foe("husk", free[i])
		Fx.burst(main, u.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
	main.ui.toast("Renforts ennemis !")


func _hero_dist(c: Vector2i) -> int:
	var best := 999
	for h in alive_heroes():
		best = mini(best, dist(c, h.cell))
	return best


# ------------------------------------------------------------------ objets

func _sim(k: String, n := 1) -> void:
	sim[k] = int(sim.get(k, 0)) + n


func stock() -> int:
	## Stock : objets de l'escouade encore en jeu (Éphémères exclues), 4 au plus.
	var is_obj := func(ci): return Data.def(ci.id).has("tool") and not ci.get("eph", false)
	var n := hand.filter(is_obj).size()
	for u in alive_heroes():
		if piles.has(u):
			for k in ["draw", "discard", "keep"]:
				n += piles[u][k].filter(is_obj).size()
	return mini(n, 4)


func objs_in_hand(filter := Callable()) -> Array:
	## Indices des objets de la main (le filtre reçoit l'instance).
	return range(hand.size()).filter(func(i): return Data.def(hand[i].id).has("tool") and (not filter.is_valid() or filter.call(hand[i])))


func _pick_obj(title: String, idx: Array) -> int:
	## Quel objet de la main : d'office s'il n'y en a qu'une ; sinon au choix (auto-jeu : la plus basse).
	if idx.is_empty():
		return -1
	if idx.size() == 1 or main._testing():
		idx.sort_custom(func(a, b): return Data.level(hand[a]) + (5 if Data.card(hand[a]).get("legend", false) else 0) < Data.level(hand[b]) + (5 if Data.card(hand[b]).get("legend", false) else 0))
		return idx[0]
	var j: int = await main.ui.choose(title, "Quel objet ?", idx.map(func(i): return {"card": hand[i]}))
	return idx[maxi(0, j)]


func _spend_obj(ci: Dictionary, played := false) -> bool:
	## Comptabilité d'un objet qui quitte la main (joué, démonté ou lancé). Vrai si sa dernière charge part.
	var c := Data.card(ci)
	if c.get("eph", false):
		return false
	if c.get("legend", false):
		exhausted.append(ci)
		return false
	ci["uses"] = int(ci.get("uses", Data.level(ci))) - 1
	if int(ci.uses) <= 0:
		spent.append(ci)
		exhausted.append(ci)
		return true
	if played and has("ecrin"):
		discard.append(ci)  # Écrin sans fond : elle revient par la défausse
	else:
		exhausted.append(ci)
	return false


func _item_consumed(h: Unit) -> void:
	## Chaque objet joué, démonté ou lancé : compteurs et pouvoirs qui s'en nourrissent.
	used_turn += 1
	if h.has_p("prestesse") and h == active and h.get_meta("prestesse_round", -1) != turn and hand.size() < 10:
		h.set_meta("prestesse_round", turn)  # Prestesse : le premier objet du tour fait piocher
		draw(1)
	if powers.has("linfei") and power_owner.get("linfei") == h:
		h.hits += 1
		_count_hit(h)
		if h.hits >= 3 - int(power_val.get("linfei", 0)) and not h.get_meta("linfei_fait", false):
			h.set_meta("linfei_fait", true)
			_craft(1, h)  # pas de cible à voler : Fabrique 1
	if powers.has("marchenoir") and not over:
		var near: Unit = null
		for f in alive_foes():
			if near == null or dist(f.cell, h.cell) < dist(near.cell, h.cell):
				near = f
		if near:
			Fx.bolt(main, h.position, near.position, Data.CLASS_COLOR.receleur.lightened(0.3))
			damage(near, 4 + int(power_val.get("marchenoir", 0)))
			if int(power_val.get("marchenoir2", 0)) > 0 and near.alive:
				near.mark = maxi(near.mark, 1)  # Marché noir niveau 3


const TOOL_MAIN := {"bombe": "bomb", "picots": "picots", "gland": "oak_hp", "sels": "block"}


func _tour_de_main(c: Dictionary, h: Unit) -> Dictionary:
	## Tour de main : les objets du Receleur gagnent +2 sur leur valeur principale, sinon piochent 1.
	if h.key != "receleur":
		return c
	c = c.duplicate()
	if TOOL_MAIN.has(c.tool):
		c[TOOL_MAIN[c.tool]] = int(c.get(TOOL_MAIN[c.tool], 0)) + 2
	elif c.tool != "fiole":
		c["draw"] = int(c.get("draw", 0)) + 1
	return c


func _consume(h: Unit) -> String:
	## Démonte : un objet quitte la main sans son effet (elle perd une charge). "" si la main n'en a pas.
	var i: int = await _pick_obj("DÉMONTE", objs_in_hand())
	if i < 0:
		main.ui.toast("Aucun objet en main.")
		return ""
	var ci: Dictionary = hand[i]
	hand.remove_at(i)
	_spend_obj(ci)
	_item_consumed(h)
	var nm: String = Data.card(ci).name
	Fx.number(main, h.position + Vector3(0, 1.0, 0), "Démonté : " + nm, GOLD_FX)
	changed.emit()
	return Data.def(ci.id).tool


func _recharge_ci(ci: Dictionary, n: int, rule := true) -> bool:
	var c := Data.card(ci)
	if c.tool == "fiole" or c.get("eph", false) or c.get("legend", false) or (rule and ci.get("rch", false)):
		return false
	ci["uses"] = mini(3, int(ci.get("uses", Data.level(ci))) + n)
	if rule:
		ci["rch"] = true
	return true


func _recharge(h: Unit, n: int) -> void:
	## Recharge : +n charges à un objet de la main, sinon à la première de la pioche du héros.
	var ok := func(ci): return _recharge_ci(ci.duplicate(), 0)
	var idx := objs_in_hand(ok)
	var ci = null
	if idx.size() > 0:
		ci = hand[await _pick_obj("RECHARGE", idx)]
	else:
		for x in draw_pile:
			if Data.def(x.id).has("tool") and _recharge_ci(x.duplicate(), 0):
				ci = x
				break
	if ci == null:
		main.ui.toast("Rien à recharger.")
		return
	_recharge_ci(ci, n)
	Fx.number(main, h.position + Vector3(0, 1.2, 0), "Recharge : %s (%d)" % [Data.card(ci).name, int(ci.uses)], GOLD_FX)
	changed.emit()


func _craft(n: int, h: Unit = null, min_rar := 1, tool := "") -> void:
	## Fabrique : des objets Éphémères dans la main (commune 75 %, peu commune 20 %, rare 5 %) ; jamais de légendaire.
	if h == null:
		h = active
	if h == null:
		return
	for k in n:
		var id := Data.obj_of(tool) if tool != "" else ""
		var lvl := 1
		if id == "":
			var roll := rng.randf()
			var rar := 3 if roll < 0.05 else (2 if roll < 0.25 else 1)
			rar = maxi(rar, min_rar)
			var ids: Array = Data.CARDS.keys().filter(func(x): return Data.CARDS[x].has("tool") and Data.CARDS[x].rar == rar)
			id = ids[rng.randi_range(0, ids.size() - 1)]
		if hand.size() >= 10:
			break
		hand.append({"id": id, "lvl": lvl, "h": h.key, "eph": true})
		Fx.number(main, h.position + Vector3(0, 1.0 + k * 0.35, 0), "+ " + Data.card({"id": id, "lvl": lvl, "h": h.key}).name, GOLD_FX)
	changed.emit()


func _craft_id(id: String, n: int, h: Unit) -> void:
	_craft(n, h, 1, id)


func give_obj(h: Unit, id: String, lvl := 1) -> Dictionary:
	## Un objet gagnée en combat : dans la main si c'est le tour du héros, sinon en réserve pour son tour.
	var ci: Dictionary = main.gain_obj(id, h.key, lvl)
	if ci.is_empty():
		return ci
	if not (hand.has(ci) or (piles.has(h) and (piles[h].draw.has(ci) or piles[h].discard.has(ci) or piles[h].keep.has(ci) or piles[h].exhausted.has(ci)))):
		if active == h:
			hand.append(ci)
		elif piles.has(h):
			piles[h].keep.append(ci)
	won_objs.append(ci)
	changed.emit()
	return ci


func _copy_item(h: Unit) -> bool:
	## Contrefaçon : une copie niveau 1, Éphémère, d'un objet de la main.
	var i: int = await _pick_obj("COPIE", objs_in_hand())
	if i < 0 or hand.size() >= 10:
		main.ui.toast("Rien à copier.")
		return false
	hand.append({"id": hand[i].id, "lvl": 1, "h": h.key, "eph": true})
	Fx.number(main, h.position + Vector3(0, 0.6, 0), "Copie : " + Data.def(hand[i].id).name, GOLD_FX)
	changed.emit()
	return true


func _throw_item(h: Unit, t: Vector2i) -> void:
	## Lance : un objet de la main joue son effet sur la cible (jamais un outil de soin d'allié).
	var i: int = await _pick_obj("LANCE", objs_in_hand(func(ci): return Data.TOOLS[Data.def(ci.id).tool].target != "ally"))
	if i < 0:
		return
	var ci: Dictionary = hand[i]
	hand.remove_at(i)
	var c := _tour_de_main(Data.card(ci), h)
	var tt: String = Data.TOOLS[c.tool].target
	var at := h.cell if tt == "self" else t
	if tt == "free" and not (board.walkable(t) and unit_at(t) == null):
		at = _nearest_free(t)
	await Fx.bolt(main, h.position, board.world(t), GOLD_FX)
	await _apply_tool(c.tool, h, at, c)
	_spend_obj(ci)
	_item_consumed(h)


func tool_targets(id: String, h: Unit, r: Array = []) -> Array:
	var t: Dictionary = Data.TOOLS[id]
	if r.is_empty():
		r = t.get("range", [0, 0])
	var out: Array = []
	match t.target:
		"self":
			out.append(h.cell)
		"ally":
			for a in alive_heroes():
				if dist(h.cell, a.cell) >= r[0] and dist(h.cell, a.cell) <= r[1]:
					out.append(a.cell)
		"foe":
			for f in alive_foes():
				if dist(h.cell, f.cell) >= r[0] and dist(h.cell, f.cell) <= r[1]:
					out.append(f.cell)
		"free":
			for c in board.walkable_cells():
				if dist(h.cell, c) >= r[0] and dist(h.cell, c) <= r[1] and unit_at(c) == null and not traps.has(c):
					out.append(c)
		"tile":
			for x in board.dim:
				for z in board.dim:
					var c := Vector2i(x, z)
					if dist(h.cell, c) >= r[0] and dist(h.cell, c) <= r[1] and board.kind[c] != "tower":
						out.append(c)
	return out


func _area(t: Vector2i, kind: String) -> Array:
	## Croix (5 cases), anneau 3×3 ou losange de rayon 2.
	var out: Array = [t]
	match kind:
		"ring":
			for d in RING8:
				out.append(t + d)
		"diamond":
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					if absi(dx) + absi(dz) <= 2 and (dx != 0 or dz != 0):
						out.append(t + Vector2i(dx, dz))
		_:
			for d in Board.DIRS:
				out.append(t + d)
	return out


func _apply_tool(id: String, u: Unit, t: Vector2i, c := {}) -> void:
	## Effet d'un outil, qu'un héros le joue en carte (c : la carte montée au niveau) ou qu'un ennemi s'en serve.
	if t != u.cell:
		u.face(t - u.cell)
	await u.cast()
	var tgt := unit_at(t)
	var hero: bool = u.side == "hero"
	if item_poison > 0 and hero and tgt and tgt.side == "foe":
		tgt.poison += item_poison
	var times := 1
	if hero and item_echo == u and DOUBLABLE.has(id):
		item_echo = null
		times = 2
		Fx.number(main, u.position + Vector3(0, 1.3, 0), "Écho : " + Data.TOOLS[id].name, GOLD_FX)
	for rep_i in times:
		match id:
			"fiole":
				if tgt:
					var amt: int = int(c.get("heal", 10)) * (2 if fiole2 and hero else 1)
					var extra := maxi(0, amt - (tgt.max_hp - tgt.hp))
					heal(tgt, amt)
					if c.get("cleanse", "") != "":
						tgt.poison = 0
						if c.cleanse == "all":
							tgt.root = 0
					if c.get("overheal", false) and extra > 0:
						gain_block(tgt, extra)
			"sels":
				for a in (alive_heroes() if c.get("all", false) and hero else ([tgt] if tgt else [])):
					a.poison = 0
					a.root = 0
					gain_block(a, int(c.get("block", 6)))
			"elixir":
				Fx.number(main, u.position + Vector3(0, 0.6, 0), "+%d énergie" % int(c.get("energy", 2)), GOLD_FX)
				if c.is_empty():
					energy += 2
			"ballot":
				if hero:
					await _embauche(u, int(c.get("heist", 1)), 2 if c.get("heist_free", false) else (0 if c.get("heist_plain", true) else 1))
				else:
					var spots: Array = Board.DIRS.map(func(d): return u.cell + d).filter(func(q): return board.walkable(q) and unit_at(q) == null and not board.props.has(q))
					if spots.size() > 0:
						var pool: Array = Data.EXTRAS[clampi(main.floor_i, 1, 3)]
						var cp := spawn_foe(pool[rng.randi_range(0, pool.size() - 1)], spots[rng.randi_range(0, spots.size() - 1)])
						Fx.burst(main, cp.position + Vector3(0, 0.5, 0), EMBER, 30, 2.0, 6.0)
						Fx.number(main, cp.position + Vector3(0, 1.6, 0), "Un complice !", EMBER, true)
			"carnet":
				var before := hand.size()
				draw(int(c.get("draw", 3)))
				if int(c.get("cut_drawn", 0)) > 0:
					for k in range(before, hand.size()):
						hand[k]["cut"] = int(c.cut_drawn)
			"de":
				var n := hand.size()
				discard.append_array(hand)
				hand.clear()
				draw(n + int(c.get("reroll", 0)))
			"sablier":
				for f in alive_foes():
					f.root = maxi(f.root, int(c.get("root_all", 1)))
					if c.get("expose_all", false):
						f.exposed = true
					Fx.number(main, f.position + Vector3(0, 0.5, 0), "⛓", Color(0.8, 0.9, 1.0))
				if int(c.get("block", 0)) > 0:
					for a in (alive_heroes() if c.get("all", false) else [u]):
						gain_block(a, int(c.block))
			"filet":
				if tgt:
					await Fx.bolt(main, u.position, tgt.position, Color(0.9, 0.85, 0.7))
					var hit: Array = [tgt]
					if c.get("splash", false):
						for o in alive_foes():
							if o != tgt and dist(o.cell, tgt.cell) == 1:
								hit.append(o)
					for o in hit:
						if root_hero(o, int(c.get("root", 2))):
							Fx.number(main, o.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
						if c.get("expose", false) or c.get("splash", false):
							o.exposed = true
			"fumigene":
				await Fx.bolt(main, u.position, board.world(t), Color(0.85, 0.85, 0.85))
				for cc in _area(t, c.get("area", "cross")):
					if board._in(cc) and board.kind[cc] != "tower":
						_smoke(cc, int(c.get("smoke", 2)))
						var a := unit_at(cc)
						if a and a.side == "hero" and int(c.get("smoke_block", 0)) > 0:
							gain_block(a, int(c.smoke_block))
				if int(c.get("block", 0)) > 0:
					gain_block(u, int(c.block))
			"bombe":
				await Fx.bolt(main, u.position, board.world(t), EMBER)
				var area: String = c.get("area", "cross")
				_explode(t, int(c.get("bomb", 8 if hero else 6)), area != "ring")
				if int(c.get("push", 0)) > 0:
					for cc in _area(t, area):
						var o := unit_at(cc)
						if o and o.alive and cc != t and o.side == "foe":
							await push(o, _dir(t, cc), int(c.push))
			"tonnelet":
				var dirv := _dir(u.cell, t) if t != u.cell else Vector2i(1, 0)
				var at := t
				for k in int(c.get("barils", 1)):
					if not (board.walkable(at) and unit_at(at) == null and not traps.has(at)):
						break
					board.props[at] = "baril"
					_make_prop(at)
					at += dirv
			"brasero":
				if board.walkable(t) and unit_at(t) == null:
					board.props[t] = "brasero"
					_make_prop(t)
					brasero_aura[t] = int(c.get("aura", 3))
			"picots":
				for cc in _area(t, c.get("area", "cross")):
					if board.walkable(cc) and unit_at(cc) == null and not traps.has(cc):
						var node := Node3D.new()
						var mi := MeshInstance3D.new()
						mi.mesh = Board.mesh_of("prop_picots").mesh
						mi.material_override = Board.material("prop")
						node.add_child(mi)
						node.position = board.world(cc)
						node.rotation.y = randf() * TAU
						units_root.add_child(node)
						traps[cc] = node
						trap_kind[cc] = "picots"
						trap_dmg[cc] = int(c.get("picots", 5))
						if int(c.get("trap_root", 0)) > 0:
							picot_root[cc] = int(c.trap_root)
			"grappin":
				await Fx.bolt(main, u.position + Vector3(0, 0.8, 0), board.world(t) + Vector3(0, 0.3, 0), Color(0.85, 0.85, 0.8))
				await u.teleport(t, board)
				if loot.has(u.cell):
					_pick_loot(u, u.cell)
				if int(c.get("land_dmg", 0)) > 0:
					for d in Board.DIRS:
						var o := unit_at(u.cell + d)
						if o and o.side == "foe":
							damage(o, int(c.land_dmg), u)
				await _landed(u)
				_check_portal(u)
			"gland":
				var cells: Array = [t]
				for d in Board.DIRS:
					if cells.size() < int(c.get("oaks_n", 1)) and board.walkable(t + d) and unit_at(t + d) == null and not traps.has(t + d):
						cells.append(t + d)
				for cc in cells:
					_plant(cc, int(c.get("oak_hp", 10)), int(c.get("oak_arm", 0)), int(c.get("oak_aura", 3)), c.get("fireproof", false))
		if rep_i + 1 < times:
			await wait(0.25)
	await wait(0.2)


func _base(c: Dictionary, h: Unit, t) -> int:
	## Dégâts de base d'une carte avant hauteur, dos, marque...
	return int(c.get("dmg", 0)) + int(c.get("combo", 0)) * mini(h.combo, 4) + _trig_dmg(c, h, t) + int(c.get("flow", 0)) * played + int(c.get("junk", 0)) * stock() \
		+ int(mini(h.block, 12) * float(c.get("per_block", 0.0))) + int(c.get("per_boom", 0)) * booms \
		+ int(c.get("per_missing", 0)) * ((h.max_hp - h.hp) / 5) + int(c.get("per_tele", 0)) * h.teles \
		+ int(c.get("per_used", 0)) * used_turn + int(c.get("_dropv", 0)) + int(c.get("_chg", 0)) \
		+ int(c.get("per_drawn", 0)) * drawn_turn + int(c.get("per_exhaust", 0)) * int(exhaust_n.get(h, 0)) \
		+ int(c.get("per_eph", 0)) * played_turn.filter(func(p): return p.get("eph", false)).size() 		+ int(c.get("per_marked", 0)) * alive_foes().filter(func(o): return o.mark > 0).size() \
		+ (int(c.get("consume_root", 0)) * (unit_at(t).root if t is Vector2i and unit_at(t) else 0))


func _gives(g: Dictionary, h: Unit) -> void:
	## Carte qui en crée une autre : {id, to: "self" | "allies", free, n}. Copies Éphémères ; celles des alliés
	## arrivent dans leur main à leur tour (piles.keep), le survol de la carte d'origine montre la carte créée.
	var to: Array = [h] if g.get("to", "self") == "self" else alive_heroes().filter(func(a): return a != h)
	for u in to:
		for i in int(g.get("n", 1)):
			var ci := {"id": g.id, "lvl": 1, "h": u.key, "eph": true}
			if g.get("free", false):
				ci["free"] = true
			if u == h:
				if hand.size() < 10:
					hand.append(ci)
			elif piles.has(u):
				piles[u].keep.append(ci)
		Fx.number(main, u.position + Vector3(0, 1.3, 0), "+ %s" % Data.def(g.id).name, Color(1.0, 0.85, 0.5))


func _berserk(u: Unit) -> void:
	## Berserk : chaque perte de PV de son porteur ajoute +val à ses coups jusqu'à la fin du combat.
	if powers.has("berserk") and power_owner.get("berserk") == u:
		u.rage = mini(u.rage + int(power_val.get("berserk", 2)), 3 * int(power_val.get("berserk", 2)))  # plafond : trois gains
		Fx.number(main, u.position + Vector3(0, 1.2, 0), "Rage +%d" % int(power_val.get("berserk", 2)), Color(1.0, 0.3, 0.25))


func _execute(h: Unit, f: Unit) -> void:
	## Exécution : une cible restée sous le seuil est achevée (20 %, élites 10 %, gardiens seulement en dernière phase).
	if f.data.has("paliers") and int(f.get_meta("phase", 0)) < f.data.paliers.size():
		return
	var thr := (0.15 if has("hachoir") else 0.1) if (f.affix != "" or elite_fight or f.data.has("paliers")) else (0.3 if has("hachoir") else 0.2)
	if f.hp > f.max_hp * thr:
		return
	Fx.number(main, f.position + Vector3(0, 1.1, 0), "Exécution !", Color(0.95, 0.3, 0.3), true)
	main.hitstop(0.14)
	_sim("execution")
	f.hp = 0
	kill(f, h)
	if has("pique"):
		for o in alive_foes():
			if dist(o.cell, f.cell) <= 3:
				o.mark = maxi(o.mark, 2)
				Fx.number(main, o.position + Vector3(0, 0.5, 0), "◎ Marqué", Color(1.0, 0.85, 0.4))


func _fourgue(h: Unit, stolen: bool) -> void:
	## Le Fourgue : un vol soigne l'escouade, une fois par tour.
	if not powers.has("fourgue") or not stolen or fourgue_turn:
		return
	fourgue_turn = true
	for a in alive_heroes():
		if a.hp < a.max_hp or powers.has("maree_haute"):
			heal(a, maxi(1, int(power_val.get("fourgue", 1))))


func _steal(h: Unit, f: Unit) -> bool:
	## Voler rapporte toujours : la carte de l'objet porté arrive en main ; sinon ce qui traîne dans ses poches (Éphémère).
	if int(power_val.get("fourgue2", 0)) > 0 and powers.has("fourgue"):
		f.exposed = true  # Le Fourgue niveau 3 : le vol ouvre le dos
	if f.card_id != "":
		_card_won(f, "Carte volée")
		stolen_turn += 1
		_fourgue(h, true)
		changed.emit()
		return true
	for sl in f.equip:
		if f.tool == "" and f.equip[sl] != "":
			var gid: String = f.equip[sl]
			f.equip[sl] = ""
			main.bag.append(gid)
			main.fight_loot.append({"item": gid})
			stolen_turn += 1
			_fourgue(h, true)
			Fx.number(main, f.position + Vector3(0, 1.2, 0), "Volé : %s (au sac)" % Data.ITEMS[gid].name, GOLD_FX, true)
			changed.emit()
			return true
	stolen_turn += 1
	_fourgue(h, true)
	if f.tool == "":
		# Poches fouillées : un objet commune, Éphémère, dans la main du voleur
		var common: Array = Data.CARDS.keys().filter(func(k): return Data.CARDS[k].has("tool") and Data.CARDS[k].rar == 1)
		var id: String = common[randi() % common.size()]
		if active == h and hand.size() < 10:
			hand.append({"id": id, "lvl": 1, "h": h.key, "eph": true})
		Fx.number(main, f.position + Vector3(0, 1.5, 0), "Poches fouillées : " + Data.def(id).name, GOLD_FX, true)
		changed.emit()
		return true
	var ci := give_obj(h, Data.obj_of(f.tool))
	if powers.has("fourgue") and not ci.is_empty():
		_recharge_ci(ci, 1, false)
	if has("doublure") and not ci.is_empty():
		_recharge_ci(ci, 1, false)  # Doublure de manteau : 1 charge de plus, 3 au plus
	Fx.number(main, f.position + Vector3(0, 1.2, 0), "Volé : " + Data.def(Data.obj_of(f.tool)).name, GOLD_FX, true)
	f.tool = ""
	changed.emit()
	return true


func _drop(u: Unit) -> void:
	## L'ennemi qui portait un objet le lâche en tombant : un héros qui passe dessus en prend la carte.
	if u.tool == "":
		return
	var c := u.cell if board.walkable(u.cell) else _nearest_free(u.cell)
	if loot.has(c):
		return
	var node := Node3D.new()
	var md := Board.mesh_of("prop_sac")
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material("glow" if part == "glow" else "prop")
		node.add_child(mi)
	# bien visible : une colonne de lumière dorée, un disque au sol, et l'icône de l'objet qui flotte au-dessus
	var gold := Color(1.0, 0.78, 0.3)
	if _beam_tex == null:
		var bg := Gradient.new()
		bg.offsets = PackedFloat32Array([0.0, 1.0])
		bg.colors = PackedColorArray([Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		_beam_tex = GradientTexture2D.new()
		_beam_tex.gradient = bg
		_beam_tex.fill_from = Vector2(0, 1)
		_beam_tex.fill_to = Vector2(0, 0)
	var beam := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.2
	cy.bottom_radius = 0.34
	cy.height = 3.6
	cy.cap_top = false
	cy.cap_bottom = false
	beam.mesh = cy
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_texture = _beam_tex
	bm.albedo_color = Color(gold.r * 3.0, gold.g * 3.0, gold.b * 3.0, 1.0)  # additif : il faut de la marge pour briller sur une dalle claire
	beam.material_override = bm
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position.y = 1.6
	node.add_child(beam)
	var btw := beam.create_tween().set_loops()
	btw.tween_property(bm, "albedo_color:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	btw.tween_property(bm, "albedo_color:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	var disc := MeshInstance3D.new()
	var dq := QuadMesh.new()
	dq.size = Vector2(1.3, 1.3)
	dq.orientation = PlaneMesh.FACE_Y
	disc.mesh = dq
	disc.material_override = Fx.soft_mat(gold, 2.2, true, BaseMaterial3D.BILLBOARD_DISABLED)
	disc.position.y = 0.03
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(disc)
	var icon_path := "res://assets/ui/tool_%s.png" % u.tool
	var fl: Node3D
	if ResourceLoader.exists(icon_path):
		var sp := Sprite3D.new()
		sp.texture = load(icon_path)
		sp.pixel_size = 0.75 / maxf(1.0, float(sp.texture.get_width()))
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.render_priority = 8
		fl = sp
	else:
		var l3 := Label3D.new()
		l3.text = Data.TOOLS[u.tool].glyph
		l3.font = Fx.title_font()
		l3.font_size = 96
		l3.pixel_size = 0.0055
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.no_depth_test = true
		l3.modulate = gold
		l3.outline_size = 18
		l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.85)
		fl = l3
	fl.position.y = 1.25
	node.add_child(fl)
	var tw := fl.create_tween().set_loops()
	tw.tween_property(fl, "position:y", 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(fl, "position:y", 1.25, 0.8).set_trans(Tween.TRANS_SINE)
	node.position = board.world(c)
	units_root.add_child(node)
	loot[c] = [u.tool, node]
	u.tool = ""


func _pick_loot(h: Unit, c: Vector2i) -> void:
	var e: Array = loot[c]
	loot.erase(c)
	e[1].queue_free()
	give_obj(h, Data.obj_of(e[0]))
	Fx.number(main, h.position + Vector3(0, 1.1, 0), "+ " + Data.def(Data.obj_of(e[0])).name, GOLD_FX)
	changed.emit()


func _foe_tool(f: Unit) -> void:
	## Un ennemi se sert parfois de ce qu'il porte ; l'objet est alors perdu.
	var id := f.tool
	var t = null
	match id:
		"fiole":
			if f.hp * 2 < f.max_hp:
				t = f.cell
		"sels":
			if f.hp * 10 < f.max_hp * 6 or f.poison > 0 or f.root > 0:
				t = f.cell
		"fumigene":
			if f.hp * 2 < f.max_hp and rng.randf() < 0.6:
				t = f.cell
		"ballot":
			# loin des héros, il sort son contrat : un complice est embauché
			if not alive_heroes().any(func(hh): return dist(hh.cell, f.cell) <= 2) and rng.randf() < 0.5:
				t = f.cell
		"filet":
			for h in alive_heroes():
				if dist(f.cell, h.cell) <= 4 and rng.randf() < 0.4:
					t = h.cell
					break
		"bombe":
			var best := 0
			for h in alive_heroes():
				var dd := dist(f.cell, h.cell)
				if dd < 2 or dd > 4:
					continue
				var sc := 0
				for c in [h.cell, h.cell + Vector2i(1, 0), h.cell + Vector2i(-1, 0), h.cell + Vector2i(0, 1), h.cell + Vector2i(0, -1)]:
					var o := unit_at(c)
					if o:
						sc += 1 if o.side == "hero" else -2
				if sc > best:
					best = sc
					t = h.cell
			if best < 2 and rng.randf() < 0.6:
				t = null
	if t == null:
		return
	f.tool = ""
	Fx.number(main, f.position + Vector3(0, 1.4, 0), Data.TOOLS[id].name + " !", Color(1.0, 0.75, 0.4), true)
	await _apply_tool(id, f, t)


func _explode(c: Vector2i, dmg: int, cross := false) -> void:
	## Explosion : dégâts autour, barils en chaîne, chênes qui flambent, bombes portées qui sautent.
	if over:
		return
	if player_turn and active and active.has_p("meche"):
		dmg += 2
	Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), EMBER, 80, 5.0)
	Fx.number(main, board.world(c), "Boum", EMBER, true)
	_sim("explosion")
	main.shake(0.5)
	var cells: Array = [c]
	for d in (Board.DIRS if cross else RING8):
		cells.append(c + d)
	for t in cells:
		var o := unit_at(t)
		if o:
			_blast = true
			damage(o, _boom_dmg(dmg))
			_blast = false
	for t in cells:
		if oaks.has(t):
			_hit_tree(t, 0, true)
		elif board.props.get(t, "") in BOOM:
			trigger_prop(t, Vector2i.ZERO)
	_after_boom(c)
	changed.emit()


func _plant(c: Vector2i, hp := 10, arm := 0, aura := 3, fireproof := false, grow := true) -> void:
	## Un arbre à PV : du décor (aura 0, sans pousse) ou un chêne planté par un objet.
	board.blocked[c] = "oak" if aura > 0 else "tree"
	tree_hp[c] = hp
	oak_max[c] = hp
	oak_arm[c] = arm
	oak_aura[c] = aura
	if fireproof:
		oak_fp[c] = true
	var ess: String = board.biome.get("tree", "green")
	var key := "pine_0" if ess == "pine" else "tree_%s_small" % ("green" if ess == "" else ess)
	var node := Node3D.new()
	var md := Board.mesh_of(key)
	for part in ["mesh", "glow"]:
		if md[part] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = md[part]
		mi.material_override = Board.material_for("tree", part == "glow")
		node.add_child(mi)
	node.position = board.world(c)
	node.rotation.y = randf() * TAU
	units_root.add_child(node)
	oaks[c] = node
	var sc := (0.7 if ess == "pine" else 1.0) * (1.0 + 0.08 * arm)
	if grow:
		node.scale = Vector3.ONE * 0.1
		node.create_tween().tween_property(node, "scale", Vector3.ONE * sc, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.burst(main, board.world(c) + Vector3(0, 0.4, 0), Color(0.5, 0.9, 0.4), 30, 2.5, 5.0)
	else:
		node.scale = Vector3.ONE * sc


func _hit_tree(c: Vector2i, n: int, fire := false) -> void:
	## Un coup sur un arbre : il perd des PV et tombe à zéro (la case se libère). Le feu le consume, sauf s'il est ignifugé.
	if not oaks.has(c):
		return
	if fire and not oak_fp.has(c):
		_burn(c)
		return
	n = 8 if fire else maxi(0, n - int(oak_arm.get(c, 0)))
	tree_hp[c] = tree_hp.get(c, 10) - n
	Fx.number(main, board.world(c) + Vector3(0, 1.1, 0), "−%d" % n, Color(0.75, 0.95, 0.55))
	var node: Node3D = oaks[c]
	var tw := node.create_tween()
	tw.tween_property(node, "rotation:z", 0.12, 0.06)
	tw.tween_property(node, "rotation:z", 0.0, 0.18)
	if tree_hp[c] <= 0:
		_sim("arbre_abattu")
		_fell(c, "L'arbre tombe")
	changed.emit()


func _fell(c: Vector2i, why: String, fire := false) -> void:
	var node: Node3D = oaks[c]
	oaks.erase(c)
	for dd in [tree_hp, oak_arm, oak_aura, oak_fp, oak_max]:
		dd.erase(c)
	board.blocked.erase(c)
	if smolder.has(c):
		if is_instance_valid(smolder[c]):
			smolder[c].queue_free()
		smolder.erase(c)
	Fx.burst(main, board.world(c) + Vector3(0, 0.8, 0), EMBER if fire else Color(0.55, 0.8, 0.35), 60, 3.5)
	Fx.number(main, board.world(c) + Vector3(0, 1.0, 0), why, EMBER if fire else Color(0.75, 0.95, 0.55), true)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector3(1.2, 0.05, 1.2), 0.4)
	tw.tween_callback(node.queue_free)
	if not fire:
		_log_bridge(c)


func _log_bridge(c: Vector2i) -> void:
	## L'arbre abattu tombe dans l'eau voisine : une case de pont, de préférence celle qui rejoint une autre rive.
	var best := Vector2i.ZERO
	for d in Board.DIRS:
		var w := c + d
		if not board._in(w) or board.kind.get(w, "") != "water":
			continue
		if best == Vector2i.ZERO or board.kind.get(w + d, "water") != "water":
			best = d
	if best == Vector2i.ZERO:
		return
	var w := c + best
	board.kind[w] = "bridge"
	board.h[w] = maxi(1, board.h[c])
	board.along_x[w] = best.x != 0
	board.build_visuals()
	_sim("tronc")
	_first("tronc", board.world(w), "Tronc en travers", Color(0.75, 0.95, 0.55), "un arbre abattu au bord de l'eau y tombe : un passage de fortune.")


func _burn(c: Vector2i) -> void:
	## Le feu : l'arbre flambe (6 autour, braseros et barils voisins sautent), les arbres collés couvent.
	if not oaks.has(c):
		return
	_sim("arbre_brule")
	_fell(c, "L'arbre flambe", true)
	if has("amadou") and board.walkable(c):
		_lava(c)  # Amadou : l'arbre laisse une Braise
	for d in RING8:
		var o := unit_at(c + d)
		if o:
			_blast = true
			damage(o, _boom_dmg(6 + (3 if has("amadou") else 0)))
			_blast = false
		if board.props.get(c + d, "") in BOOM:
			trigger_prop(c + d, Vector2i.ZERO)
	for d in Board.DIRS:
		var nb := c + d
		if oaks.has(nb) and not smolder.has(nb) and not oak_fp.has(nb):
			smolder[nb] = _ember_mark(nb)


func _ember_mark(c: Vector2i) -> Node3D:
	## La flamme qui couve : on la voit venir un round à l'avance.
	var l := Label3D.new()
	l.text = "♨"
	l.font_size = 64
	l.outline_size = 12
	l.modulate = EMBER
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = board.world(c) + Vector3(0, 1.6, 0)
	units_root.add_child(l)
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "modulate:a", 0.45, 0.5)
	tw.tween_property(l, "modulate:a", 1.0, 0.5)
	return l


func _smolder_tick() -> void:
	## Début de round : les arbres qui couvaient s'embrasent, 3 au plus par manche (les autres attendent).
	var n := 0
	for c in smolder.keys():
		if n >= 3:
			break
		n += 1
		if is_instance_valid(smolder[c]):
			smolder[c].queue_free()
		smolder.erase(c)
		if oaks.has(c):
			_burn(c)


func _smoke(c: Vector2i, turns: int) -> void:
	smoke[c] = maxi(smoke.get(c, 0), turns)
	if smoke_nodes.has(c):
		return
	smoke_nodes[c] = Fx.smoke_cloud(units_root, board.world(c) + Vector3(0, 0.35, 0))


func _brasero_tick() -> void:
	## Fin de manche : un brasero posé par une carte brûle les ennemis à son contact.
	for c in brasero_aura.keys():
		if board.props.get(c, "") != "brasero":
			brasero_aura.erase(c)
			continue
		for d in RING8:
			var o := unit_at(c + d)
			if o and o.side == "foe" and o.alive:
				_blast = true
				damage(o, int(brasero_aura[c]))
				_blast = false


func _smoke_tick() -> void:
	for c in smoke.keys():
		smoke[c] -= 1
		if smoke[c] <= 0:
			smoke.erase(c)
			var n: Node3D = smoke_nodes[c]
			smoke_nodes.erase(c)
			var tw := n.create_tween()
			tw.tween_property(n, "scale", Vector3.ONE * 0.05, 0.4)
			tw.tween_callback(n.queue_free)


# ------------------------------------------------------------------ runes au sol (Dofus Arena)

func _place_ground() -> void:
	## Matière du sol, selon le biome : glace (hauts plateaux, cristal, grotte), vase (marais, écluse, bassins, bosquet). 2 à 3 plaques de 3 à 5 cases.
	for n in ground_nodes.values():
		if is_instance_valid(n):
			n.queue_free()
	ground_nodes.clear()
	ground.clear()
	var bi: int = main._biome() if main.has_method("_biome") else 0
	var k: String = Data.ground_of(bi)
	if main.args.has("ground"):
		k = main.args.ground
	if k == "" or main.tuto:
		return
	var free: Array = board.walkable_cells().filter(func(c): return board.kind.get(c, "") == "land" and unit_at(c) == null and not board.props.has(c) and _hero_dist(c) >= 2)
	for p in rng.randi_range(2, 3):
		if free.is_empty():
			break
		var seed_c: Vector2i = free[rng.randi_range(0, free.size() - 1)]
		var patch: Array = [seed_c]
		var want := rng.randi_range(3, 5)
		var tries := 0
		while patch.size() < want and tries < 30:
			tries += 1
			var nx: Vector2i = patch[rng.randi_range(0, patch.size() - 1)] + Board.DIRS[rng.randi_range(0, 3)]
			if free.has(nx) and not patch.has(nx):
				patch.append(nx)
		for c in patch:
			_set_ground(c, k)
			free.erase(c)


func _set_ground(c: Vector2i, k: String) -> void:
	## Pose (ou change) la matière du sol d'une case : une seule plaque par case.
	if ground_nodes.has(c) and is_instance_valid(ground_nodes[c]):
		ground_nodes[c].queue_free()
	ground[c] = k
	var mi := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(1.0, 0.07, 1.0)
	mi.mesh = bx
	if _ground_mat.get(k) == null:
		var nt := NoiseTexture2D.new()
		nt.width = 64
		nt.height = 64
		nt.noise = FastNoiseLite.new()
		nt.noise.frequency = 0.09
		nt.color_ramp = Gradient.new()
		nt.color_ramp.colors = PackedColorArray([Color(0.72, 0.72, 0.72), Color(1, 1, 1)])
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Data.GROUND[k].col
		m.albedo_texture = nt
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # grain de voxel
		m.roughness = 0.1 if k == "glace" else 1.0
		m.metallic_specular = 1.0 if k == "glace" else 0.05
		if k == "glace":
			m.emission_enabled = true
			m.emission = Color(0.25, 0.4, 0.5)
		_ground_mat[k] = m
	mi.material_override = _ground_mat[k]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = board.world(c) + Vector3(0, 0.035, 0)
	units_root.add_child(mi)
	ground_nodes[c] = mi


func _ground_cells(cells: Array, k: String) -> void:
	## Cartes qui posent un sol : terre ferme sans objet seulement.
	for cc in cells:
		if board.walkable(cc) and board.kind[cc] == "land":
			_set_ground(cc, k)


func _place_tiles() -> void:
	for n in tile_nodes:
		if is_instance_valid(n):
			n.queue_free()
	tile_nodes.clear()
	tiles.clear()
	twins.clear()
	if main.tuto:
		return  # initiation : les runes du chapitre, posées par main._tuto_setup
	var free: Array = board.walkable_cells().filter(func(c): return unit_at(c) == null and _hero_dist(c) >= 2)
	for i in range(free.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = free[i]
		free[i] = free[j]
		free[j] = tmp
	var kinds: Array = Data.TILES.keys()
	glyph_t.clear()
	glyph_lbl.clear()
	var want := 4 + board.dim / 8
	for c: Vector2i in free:
		if want <= 0:
			break
		if tiles.keys().any(func(o): return dist(o, c) < 3):
			continue
		var k: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		if k == "portail":
			if twins.size() > 0:
				continue
			var twin = null
			for o: Vector2i in free:
				if dist(o, c) >= 6 and not tiles.keys().any(func(q): return dist(q, o) < 3):
					twin = o
					break
			if twin == null:
				continue
			tiles[twin] = k
			twins[c] = twin
			twins[twin] = c
			_make_tile(twin, k)
		tiles[c] = k
		_make_tile(c, k)
		want -= 1


static var _rune_tex: GradientTexture2D
static var _beam_tex: GradientTexture2D


func _make_tile(c: Vector2i, k: String) -> void:
	var td: Dictionary = Data.TILES[k]
	var col: Color = td.col
	if _rune_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.6, 0.68, 0.8, 0.86, 1.0])
		g.colors = PackedColorArray([Color(0.75, 0.75, 0.75, 0.8), Color(0.85, 0.85, 0.85, 0.85), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
		_rune_tex = GradientTexture2D.new()
		_rune_tex.gradient = g
		_rune_tex.fill = GradientTexture2D.FILL_RADIAL
		_rune_tex.fill_from = Vector2(0.5, 0.5)
		_rune_tex.fill_to = Vector2(1.0, 0.5)
		_rune_tex.width = 128
		_rune_tex.height = 128
	var node := Node3D.new()
	node.position = board.world(c) + Vector3(0, 0.03, 0)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.96, 0.96)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _rune_tex
	m.albedo_color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, 1.0)  # au-delà de 1 : la case brille malgré le plein soleil
	mi.material_override = m
	mi.position.y = 0.012
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	# bien lisible de loin : un fond sombre qui détache la couleur, un cadre lumineux en relief et un halo qui monte
	var under := MeshInstance3D.new()
	var uq := QuadMesh.new()
	uq.size = Vector2(1.0, 1.0)
	uq.orientation = PlaneMesh.FACE_Y
	under.mesh = uq
	var um := StandardMaterial3D.new()
	um.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	um.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	um.albedo_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.8)
	under.material_override = um
	under.position.y = -0.01
	node.add_child(under)
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color(col.r * 2.2, col.g * 2.2, col.b * 2.2)
	for side in 4:
		var bar := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.98, 0.1, 0.1)
		bar.mesh = bx
		bar.material_override = em
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := side * PI * 0.5
		bar.rotation.y = ang
		bar.position = Vector3(sin(ang), 0.02, cos(ang)) * 0.45
		node.add_child(bar)
	if _beam_tex == null:
		var bg := Gradient.new()
		bg.offsets = PackedFloat32Array([0.0, 1.0])
		bg.colors = PackedColorArray([Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		_beam_tex = GradientTexture2D.new()
		_beam_tex.gradient = bg
		_beam_tex.fill_from = Vector2(0, 1)
		_beam_tex.fill_to = Vector2(0, 0)
	var beam := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.4
	cy.bottom_radius = 0.47
	cy.height = 1.3
	cy.cap_top = false
	cy.cap_bottom = false
	beam.mesh = cy
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_texture = _beam_tex
	bm.albedo_color = col
	beam.material_override = bm
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position.y = 0.65
	node.add_child(beam)
	var btw := beam.create_tween().set_loops()
	btw.tween_property(bm, "albedo_color:a", 0.35, 1.3).set_trans(Tween.TRANS_SINE)
	btw.tween_property(bm, "albedo_color:a", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	var l3 := Label3D.new()
	l3.text = td.glyph
	l3.font = Fx.title_font()
	l3.font_size = 96
	l3.pixel_size = 0.0058
	l3.modulate = col.lightened(0.55)
	l3.outline_size = 20
	l3.outline_modulate = Color(0.05, 0.03, 0.02, 0.9)
	l3.rotation.x = -PI * 0.5
	l3.position.y = 0.02
	node.add_child(l3)
	# un peu de volume pour les terrains : buisson, murets, braises, compte à rebours
	var deco: String = {"fourre": "bush_green_0", "fort": "rubble", "autel": "crystal_0"}.get(k, "")
	if deco != "":
		var md := Board.mesh_of(deco)
		for part in ["mesh", "glow"]:
			if md[part] == null:
				continue
			var dm := MeshInstance3D.new()
			dm.mesh = md[part]
			dm.material_override = Board.material_for(deco, part == "glow")
			dm.scale = Vector3.ONE * (0.8 if k == "fourre" else 0.6)
			node.add_child(dm)
	if k == "glyphe":
		glyph_t[c] = 3
		var cd := Label3D.new()
		cd.text = "3"
		cd.font = Fx.title_font()
		cd.font_size = 110
		cd.pixel_size = 0.006
		cd.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cd.no_depth_test = true
		cd.render_priority = 10
		cd.modulate = col.lightened(0.4)
		cd.outline_size = 18
		cd.outline_modulate = Color(0.05, 0.02, 0.08, 0.9)
		cd.position.y = 1.1
		node.add_child(cd)
		glyph_lbl[c] = cd
	var tw := l3.create_tween().set_loops()
	tw.tween_property(l3, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l3, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	var gl := OmniLight3D.new()
	gl.light_color = col
	gl.light_energy = 1.4
	gl.omni_range = 1.8
	gl.position.y = 0.4
	node.add_child(gl)
	if k == "lave":
		gl.light_energy = 2.2  # la faille rougeoie
		gl.omni_range = 2.2
	units_root.add_child(node)
	tile_nodes.append(node)


func _glyphs() -> void:
	## Les glyphes instables comptent à rebours et explosent en croix.
	for c in glyph_t.keys():
		glyph_t[c] -= 1
		if glyph_t[c] <= 0:
			glyph_t[c] = 3
			Fx.number(main, board.world(c) + Vector3(0, 1.0, 0), "Glyphe !", Data.TILES.glyphe.col, true)
			Fx.burst(main, board.world(c) + Vector3(0, 0.5, 0), Data.TILES.glyphe.col, 60, 4.0)
			main.shake(0.35)
			for d in [Vector2i.ZERO] + Board.DIRS:
				var u := unit_at(c + d)
				if u:
					damage(u, 6)
			await wait(0.3)
		if glyph_lbl.has(c) and is_instance_valid(glyph_lbl[c]):
			glyph_lbl[c].text = str(glyph_t[c])
	if over:
		return


func _bombs() -> void:
	## Bombes à retardement : un round de moins à chaque début de round ; à zéro, une croix de tdmg
	## aux ennemis seulement. Ni les coups ni les explosions ne la déclenchent (hors de BOOM).
	for c in bombs.keys():
		if board.props.get(c, "") != "bombe_retard":
			bombs.erase(c)  # noyée, emportée
			continue
		bombs[c].n -= 1
		if bombs[c].n > 0:
			var node: Node3D = prop_nodes.get(c)
			if node and node.has_meta("count"):
				(node.get_meta("count") as Label3D).text = str(bombs[c].n)
			continue
		var dmg: int = bombs[c].dmg
		bombs.erase(c)
		_remove_prop(c)
		Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), EMBER, 90, 6.0)
		Fx.number(main, board.world(c) + Vector3(0, 1.0, 0), "Boum", EMBER, true)
		main.shake(0.5)
		for d in [Vector2i.ZERO] + Board.DIRS:
			var u := unit_at(c + d)
			if u and u.side == "foe" and u.alive:
				_blast = true
				damage(u, dmg)
				_blast = false
		await wait(0.3)
		if over:
			return


func _tile_turn(u: Unit) -> void:
	## Début du tour de l'unité : ce que lui donne sa rune.
	if not u.alive:
		return
	var k: String = tiles.get(u.cell, "")
	_rune(u, k)
	if has("marelle") and u.side == "hero" and k in ["force", "source", "garde"]:
		# Craie de marelle : l'allié le plus proche en profite aussi (ordre du round en cas d'égalité)
		var best: Unit = null
		for a in order:
			if is_instance_valid(a) and a.alive and a.side == "hero" and not a.companion and a != u and (best == null or dist(a.cell, u.cell) < dist(best.cell, u.cell)):
				best = a
		if best:
			Fx.number(main, best.position + Vector3(0, 1.1, 0), "Marelle : " + Data.TILES[k].name, Data.TILES[k].col)
			if k == "force":
				best.set_meta("marelle", turn)  # +3 à ses attaques pendant ce round
			else:
				_rune(best, k)


func _rune(u: Unit, k: String) -> void:
	## Ce que donne une rune au début du tour de qui s'y tient.
	match k:
		"fort":
			if u.hp < u.max_hp:
				heal(u, 3)
			gain_block(u, 3)
		"lave":
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "Braise", Color(1.0, 0.5, 0.2))
			damage(u, 5 + (int(power_val.get("fonderie", 0)) if u.side == "foe" and powers.has("fonderie") else 0))
		"source":
			if u.hp < u.max_hp:
				heal(u, 4)
		"garde":
			gain_block(u, 5)
		"elan":
			if u.side == "hero":
				energy += 1
				Fx.number(main, u.position + Vector3(0, 0.7, 0), "+1 énergie", GOLD_FX)


func _landed(u: Unit) -> void:
	## Fin d'un déplacement : ronces, portail jumeau.
	if not u.alive:
		return
	var k: String = tiles.get(u.cell, "")
	if k == "ronces":
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Ronces", Color(0.85, 0.6, 0.35))
		damage(u, 4)
	elif k == "lave":
		Fx.number(main, u.position + Vector3(0, 0.5, 0), "Braise", Color(1.0, 0.5, 0.2))
		Fx.burst(main, u.position + Vector3(0, 0.3, 0), EMBER, 30, 2.5)
		damage(u, 5 + (int(power_val.get("fonderie", 0)) if u.side == "foe" and powers.has("fonderie") else 0))
	elif k == "portail" and twins.has(u.cell) and unit_at(twins[u.cell]) == null:
		var to: Vector2i = twins[u.cell]
		Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.portail.col, 30, 2.5)
		await u.teleport(to, board)
		if u.side == "hero":
			_teleported(u)
		elif has("cle_jumeaux"):
			u.root = maxi(u.root, 1)
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "⛓ Entravé", Color(0.8, 0.9, 1.0))
		Fx.burst(main, u.position + Vector3(0, 0.6, 0), Data.TILES.portail.col, 30, 2.5)
		if u.side == "hero" and loot.has(u.cell):
			_pick_loot(u, u.cell)
	if has("tenaille"):
		# Tenaille : un ennemi entre deux héros, de part et d'autre (les compagnons ne comptent pas)
		var hero_at := func(c: Vector2i) -> bool:
			var o := unit_at(c)
			return o != null and o.side == "hero" and not o.companion
		for f in alive_foes():
			if f.mark < 1 and (hero_at.call(f.cell + Vector2i(1, 0)) and hero_at.call(f.cell - Vector2i(1, 0)) or hero_at.call(f.cell + Vector2i(0, 1)) and hero_at.call(f.cell - Vector2i(0, 1))):
				f.mark = 1
				Fx.number(main, f.position + Vector3(0, 0.5, 0), "◎ Tenaille", Color(1.0, 0.85, 0.4))


# ------------------------------------------------------------------ multiclasse : cartes de guilde

func _covered(tgt: Unit) -> bool:
	## Concile du 29/09 : un héros au contact d'un allié, ou au premier round, ne se fait pas prendre de dos.
	## Exposé passe outre. Même règle dans calc et _is_back.
	return tgt.side == "hero" and not tgt.exposed and (turn <= 1 or alive_heroes().any(func(a): return a != tgt and dist(a.cell, tgt.cell) == 1))


func _is_back(att: Unit, tgt: Unit) -> bool:
	## Le coup vient-il de dos ? (même règle que calc)
	if tgt.exposed:
		return true
	if (att.ambush or (smoke.has(tgt.cell) and dist(att.cell, tgt.cell) == 1)) and not _covered(tgt):
		return true
	var to_att := att.cell - tgt.cell
	var dot := tgt.facing.x * signi(to_att.x) + tgt.facing.y * signi(to_att.y)
	return dot < 0 and not tgt.has_p("vigilance") and not _covered(tgt)


func _on_hit(h: Unit, f: Unit, back: bool) -> void:
	## Après chaque coup d'un héros : pouvoirs de guilde qui comptent les coups.
	if h.side != "hero":
		return
	h.hits += 1
	# Nyxa : un coup de dos souffle un Murmure dans la main de celui qui l'a porté (4 par tour)
	if back and powers.has("nyxa") and nyxa_turn < 2 and hand.size() < 10:
		nyxa_turn += 1
		hand.append({"id": "murmure", "lvl": 2 if int(power_val.get("nyxa", 0)) >= 2 else 1, "h": h.key, "eph": true})
		Fx.number(main, h.position + Vector3(0, 1.3, 0), "+ Murmure", Color(0.75, 0.55, 1.0))
	if h.bph > 0:
		gain_block(h, h.bph)
	if h.inner > 0 and dist(h.cell, f.cell) == 1:
		var nx: Unit = null
		for o in alive_foes():
			if o != f and (nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell)):
				nx = o
		if nx:
			Fx.burst(main, nx.position + Vector3(0, 0.8, 0), EMBER, 18, 2.5)
			damage(nx, h.inner)
	var own := func(p: String) -> bool: return powers.has(p) and power_owner.get(p) == h
	if powers.has("suien") and power_owner.get("suien") == h:
		for a in alive_heroes():
			if a.hp < a.max_hp:
				a.hp = mini(a.max_hp, a.hp + int(power_val.get("suien", 1)))
		suien_hits += 1
		if suien_hits == 10:
			for a in heroes:
				if not a.alive:
					_revive(a, 0.3)
					break
	if back and own.call("cador"):
		if not (f.alive and _steal(h, f)):
			_craft(1, h)
	if powers.has("tetsu") and f.root > 0:
		h.moved = false
	if h.hits == 3:
		if own.call("korin") and f.alive and h.block > 0:
			Fx.number(main, f.position + Vector3(0, 1.0, 0), "Kōrin", Data.CLASS_COLOR.garde.lightened(0.4))
			damage(f, h.block, h)
	# >= et drapeau : un coup compté ailleurs (hitcount, objet) ne fait plus sauter le déclenchement
	if own.call("hazan") and h.hits >= 3 and not h.get_meta("hazan_fait", false):
		h.set_meta("hazan_fait", true)
		_boom_foes(f.cell, int(power_val.get("hazan", 7)))
	if own.call("linfei") and h.hits >= 3 - int(power_val.get("linfei", 0)) and not h.get_meta("linfei_fait", false):
		h.set_meta("linfei_fait", true)
		if not (f.alive and _steal(h, f)):
			_craft(1, h)


func _boom_foes(c: Vector2i, dmg: int) -> void:
	## Explosion qui épargne les héros : la cible et les ennemis autour.
	Fx.burst(main, board.world(c) + Vector3(0, 0.6, 0), EMBER, 60, 4.5)
	Fx.number(main, board.world(c) + Vector3(0, 0.4, 0), "Boum", EMBER, true)
	main.shake(0.4)
	for d in [Vector2i.ZERO] + RING8:
		var o := unit_at(c + d)
		if o and o.side == "foe":
			_blast = true
			damage(o, dmg)
			_blast = false


func _behind_cell(f: Unit) -> Vector2i:
	## Case dans le dos de l'unité, sinon une case libre à côté (-99 si rien).
	var back: Vector2i = f.cell - f.facing
	if board._in(back) and board.walkable(back) and unit_at(back) == null:
		return back
	for d in RING8:
		var n: Vector2i = f.cell + d
		if Board.DIRS.has(d) and board._in(n) and board.walkable(n) and unit_at(n) == null:
			return n
	return Vector2i(-99, -99)


func _go_behind(u: Unit, f: Unit) -> void:
	var b := _behind_cell(f)
	if b.x < -50 or b == u.cell:
		return
	Fx.burst(main, u.position + Vector3(0, 0.6, 0), Color(0.5, 0.2, 0.25), 24, 2.0)
	await u.teleport(b, board)
	_teleported(u)
	u.face(f.cell - u.cell)
	if loot.has(u.cell):
		_pick_loot(u, u.cell)


func _revive(a: Unit, frac: float) -> void:
	var c := a.cell if board.walkable(a.cell) and unit_at(a.cell) == null else _nearest_free(a.cell)
	a.revive()
	a.hp = maxi(1, int(a.max_hp * frac))
	a.place(c, board)
	Fx.burst(main, a.position + Vector3(0, 0.6, 0), Color(1.0, 0.95, 0.7), 60, 3.0, 7.0)
	Fx.number(main, a.position + Vector3(0, 1.0, 0), "Relevé !", GOLD_FX, true)


func root_hero(u: Unit, n: int) -> bool:
	## Entrave ; un héros entravé au round précédent y échappe (actes 1 et 2).
	if u.side == "hero" and main.floor_i < 3:
		if int(u.get_meta("root_round", -9)) >= turn - 1:
			Fx.number(main, u.position + Vector3(0, 0.5, 0), "Se dégage", Color(0.8, 0.9, 1.0))
			return false
		u.set_meta("root_round", turn)
	u.root = maxi(u.root, n)
	return true


func _delay(f: Unit, n: int) -> void:
	## Recule dans l'initiative : maintenant s'il n'a pas encore joué ce round, sinon au prochain.
	var i := order.find(f)
	if i > qi:
		order.remove_at(i)
		order.insert(mini(i + n, order.size()), f)
	else:
		f.set_meta("delay", n)
	Fx.number(main, f.position + Vector3(0, 0.9, 0), "Recule de %d" % n, Color(0.7, 0.85, 1.0))


func _lure(t: Vector2i, n: int) -> void:
	## Les ennemis à 4 cases avancent vers la case ; un piège sur la route les prend.
	var near: Array = alive_foes().filter(func(f): return dist(f.cell, t) <= 4 and f.cell != t)
	near.sort_custom(func(a, b): return dist(a.cell, t) < dist(b.cell, t))
	for f in near:
		for i in n:
			if not f.alive or f.cell == t or f.root > 0:
				break
			var nx: Vector2i = f.cell + _dir(f.cell, t)
			if not board.walkable(nx) or unit_at(nx) or board.props.has(nx) or absi(board.h[nx] - board.h[f.cell]) > f.jump:
				break
			f.cell = nx
			await _slide(f, board.world(nx))
			if traps.has(nx):
				await _spring(f)
				break


func _kaede(h: Unit) -> void:
	var nx: Unit = null
	for o in alive_foes():
		if nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell):
			nx = o
	if nx == null:
		return
	await _go_behind(h, nx)
	h.ambush = true
	await h.lunge(nx.position)
	Fx.number(main, h.position + Vector3(0, 1.0, 0), "Kaede", Data.CLASS_COLOR.lame.lightened(0.4))
	damage(nx, calc(h, nx, int(power_val.get("kaede", 5))).dmg, h)
	_on_hit(h, nx, true)
	h.ambush = false


func _enclume(src: Unit, hit: Unit) -> void:
	## Serment de l'Enclume : l'allié le plus proche prend l'ennemi à revers.
	if not src.alive or over:
		return
	var ally: Unit = null
	for a in alive_heroes():
		if a != hit and (ally == null or dist(a.cell, src.cell) < dist(ally.cell, src.cell)):
			ally = a
	if ally == null:
		return
	await _go_behind(ally, src)
	ally.ambush = true
	await ally.lunge(src.position)
	Fx.number(main, ally.position + Vector3(0, 1.0, 0), "Enclume", Data.CLASS_COLOR.garde.lightened(0.4))
	damage(src, calc(ally, src, int(power_val.get("enclume", 6))).dmg, ally)
	ally.ambush = false
	# niveau 3 : Marque 2, car la fin du tour ennemi en retire 1 juste après
	if int(power_val.get("enclume2", 0)) > 0 and src.alive:
		src.mark = maxi(src.mark, 2)


func _embauche(h: Unit, n: int, disc := 0) -> void:
	## Embauche : trois cartes d'une classe absente de l'escouade, on en garde une (cadre de sa classe d'origine).
	## disc : 0 prix plein (tout le monde), 1 coûte 1 de moins, 2 gratuite ce tour (les Cambrioleurs font mieux).
	var absent: Array = Data.HEROES.keys().filter(func(k): return not heroes.any(func(u): return u.key == k))
	for i in n:
		var pool: Array = Data.CARDS.keys().filter(func(id): return absent.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id))
		await _discover(h, pool, "EMBAUCHE", "Trois cartes d'une classe absente de l'escouade%s" % ((" (%d / %d)" % [i + 1, n]) if n > 1 else ""), disc == 2, disc == 0, true)


func _discover(h: Unit, ids: Array, title: String, sub: String, free := true, plain := false, cb := false, lvls := {}) -> void:
	## Découvre : trois cartes au choix, la choisie arrive en main (coût 0, ou 1 de moins ; plain : prix plein).
	ids = ids.duplicate()
	ids.shuffle()
	var picks: Array = ids.slice(0, 3)
	if picks.is_empty() or hand.size() >= 10:
		return
	var opts: Array = picks.map(func(id): return {"card": {"id": id, "lvl": int(lvls.get(id, 1)), "h": h.key, "cb": cb}})
	for o in opts:
		main.library_see(o.card.id)
	var j: int = await main.ui.choose(title, sub, opts, true)
	if j < 0:
		return
	var ci: Dictionary = {"id": picks[j], "lvl": int(lvls.get(picks[j], 1)), "h": h.key}
	if cb:
		ci["cb"] = true  # embauchée : la carte le dit sur son bandeau
	if not plain:
		ci["free" if free else "cut"] = true if free else 1
	hand.append(ci)
	changed.emit()


func _self_fx(c: Dictionary, h: Unit) -> void:
	## Effets des compétences de guilde sur soi.
	if c.get("revive", false):
		for a in heroes:
			if not a.alive:
				_revive(a, 0.25)
	if c.get("aegis_all", false) and not has("machoire_ogre"):
		for a in alive_heroes():
			a.aegis = true
			Fx.number(main, a.position + Vector3(0, 0.9, 0), "Égide", Color(1.0, 0.95, 0.7))
	if c.has("rune") and not tiles.has(h.cell):
		tiles[h.cell] = c.rune
		_make_tile(h.cell, c.rune)
	if c.get("bait", false):
		h.bait = true
	if c.get("parry", false):
		h.parry = true
		Fx.number(main, h.position + Vector3(0, 0.8, 0), "En garde", GOLD_FX)
	if c.get("iframe", false):
		h.dodge_next = true
		Fx.number(main, h.position + Vector3(0, 0.8, 0), "Iframe", Color(0.8, 0.95, 1.0))
	if c.get("boom", 0) > 0:
		h.boomguard = int(c.boom)
	if c.get("bph", 0) > 0:
		h.bph = int(c.bph)
	if c.get("inner", 0) > 0:
		h.inner = int(c.inner)
	if c.get("lvl_next", false):
		h.lvl_next = true
	if c.get("fuse", 0) > 0:
		h.fuse = int(c.fuse)
	if c.get("justframe", false):
		if played == 0:
			h.triple = true
			Fx.number(main, h.position + Vector3(0, 1.0, 0), "Just frame !", GOLD_FX, true)
		else:
			draw(1)
	if c.get("item_poison", 0) > 0:
		item_poison = maxi(item_poison, int(c.item_poison))
	if c.get("fiole2", false):
		fiole2 = true
	if c.get("trophy", false):
		trophy = true
	if c.get("traps_around", 0) > 0:
		var n := int(c.traps_around)
		for d in Board.DIRS + RING8:
			var sp: Vector2i = h.cell + d
			if n > 0 and board.walkable(sp) and unit_at(sp) == null and not traps.has(sp) and not board.props.has(sp):
				_make_trap(sp, "piege", 8)
				n -= 1
	if c.get("copy_item", false):
		await _copy_item(h)
	var dem := ""
	if c.get("consume", false) or c.get("sell", 0) > 0:
		dem = await _consume(h)
	if dem != "":
		if c.get("c_block", 0) > 0:
			gain_block(h, c.c_block)
		if c.get("c_energy", 0) > 0:
			energy += c.c_energy
			Fx.number(main, h.position + Vector3(0, 0.6, 0), "+%d énergie" % c.c_energy, GOLD_FX)
		if c.get("sell", 0) > 0:
			var got := mini(int(c.sell), 30 - sold_gold)
			sold_gold += got
			main.gold += got
			main.ui.set_gold(main.gold)
			Fx.number(main, h.position + Vector3(0, 1.3, 0), ("+%d or" % got) if got > 0 else "Le fourgue n'en veut plus", GOLD_FX, true)
	if c.get("craft_id", "") != "":
		_craft_id(c.craft_id, int(c.get("craft_n", 1)), h)
	if c.get("iblock", 0) > 0 and stock() > 0:
		gain_block(h, int(c.iblock) * stock())
	if c.get("idraw", 0) > 0:
		draw(mini(int(c.idraw), objs_in_hand().size()))
	if c.get("filiere", false):
		var n := mini(2, stolen_turn)
		if n > 0:
			draw(n)
			energy += n
	if c.get("recharge", 0) > 0:
		await _recharge(h, int(c.recharge))
	if c.get("rpoison", 0) > 0:
		var live := alive_foes()
		if live.size() > 0:
			var v: Unit = live[randi() % live.size()]
			v.poison += int(c.rpoison)
			Fx.number(main, v.position + Vector3(0, 0.4, 0), "☠ +%d" % c.rpoison, Color(0.6, 0.9, 0.3))
	if c.get("mark_near", 0) > 0:
		var nx: Unit = null
		for o in alive_foes():
			if nx == null or dist(o.cell, h.cell) < dist(nx.cell, h.cell):
				nx = o
		if nx:
			nx.mark = maxi(nx.mark, int(c.mark_near))
			Fx.number(main, nx.position + Vector3(0, 0.5, 0), "◎ Marqué", Color(1.0, 0.85, 0.4))
	if c.get("mark_all", 0) > 0:
		for o in alive_foes():
			o.mark = maxi(o.mark, int(c.mark_all))
			Fx.number(main, o.position + Vector3(0, 0.5, 0), "◎", Color(1.0, 0.85, 0.4))
	if c.get("mark_contact", 0) > 0:
		# Présage de mort : seuls les ennemis au contact d'un héros
		for o in alive_foes():
			if alive_heroes().any(func(a): return dist(a.cell, o.cell) == 1):
				o.mark = maxi(o.mark, int(c.mark_contact))
				Fx.number(main, o.position + Vector3(0, 0.5, 0), "◎", Color(1.0, 0.85, 0.4))
	if c.get("heal_ally", 0) > 0:
		var w: Unit = null
		for a in alive_heroes():
			if a != h and a.hp < a.max_hp and (w == null or a.hp * w.max_hp < w.hp * a.max_hp):
				w = a
		if w:
			heal(w, int(c.heal_ally))
	if c.get("barrels_behind", false):
		var n := 0
		for f in alive_foes():
			var b: Vector2i = f.cell - f.facing
			if board._in(b) and board.walkable(b) and unit_at(b) == null and not board.props.has(b) and not traps.has(b):
				board.props[b] = "baril"
				_make_prop(b)
				n += 1
		draw(n)
	if c.get("hitcount", false):
		h.hits += 1
		_count_hit(h)
	if c.get("recall", 0) > 0:
		discard.shuffle()
		for k in int(c.recall):
			if discard.is_empty() or hand.size() >= 10:
				break
			var ci: Dictionary = discard.pop_back()
			ci["cut"] = 1
			hand.append(ci)
	if c.get("copy_hand", false) and hand.size() > 0:
		var j: int = await main.ui.choose("FAUX INVENTAIRE", "Quelle carte copier ? La copie est Éphémère.", hand.map(func(ci): return {"card": ci}), true)
		if j >= 0 and hand.size() < 10:
			var cp: Dictionary = hand[j].duplicate()
			cp["eph"] = true
			hand.append(cp)
	if c.get("discover", "") == "guild":
		var pool: Array = Data.CARDS.keys().filter(func(id): return c.cls.has(Data.CARDS[id].owner) and not Data.STARTER[Data.CARDS[id].owner].has(id))
		await _discover(h, pool, "DÉCOUVRE", "Une carte de %s ; elle coûte 0 ce tour" % " ou ".join(c.cls.map(func(k): return Data.HEROES[k].name)))
	if c.get("heist", 0) > 0:
		await _embauche(h, int(c.heist), 2 if c.get("heist_free", false) else (0 if c.get("heist_plain", false) else 1))
	if c.get("echo_item", false):
		item_echo = h
		Fx.number(main, h.position + Vector3(0, 1.0, 0), "Le prochain objet agit deux fois", GOLD_FX)
	if c.get("blastproof", false):
		h.blastproof = true
	if c.get("hone", 0) > 0:
		for tc in turrets:
			turrets[tc].dmg = int(turrets[tc].dmg) + int(c.hone)
			turrets[tc]["base"] = int(turrets[tc].get("base", 4)) + int(c.hone)
			Fx.number(main, board.world(tc) + Vector3(0, 1.0, 0), "Affûtée +%d" % int(c.hone), GOLD_FX)
	if c.get("add_card", "") != "" and c.get("add_per_item", false) and stock() == 0:
		main.ui.toast("Stock vide.")
	elif c.get("add_card", "") != "":
		for k in (mini(stock(), 2) if c.get("add_per_item", false) else int(c.get("add_n", 1))):
			if hand.size() < 10:
				hand.append({"id": c.add_card, "lvl": 1, "eph": true, "h": h.key})
	if c.get("flashback", false):
		if last_exhausted.has(h) and hand.size() < 10:
			var fb: Dictionary = last_exhausted[h]
			hand.append({"id": fb.id, "lvl": fb.lvl, "eph": true, "cut": 1, "h": h.key})
			Fx.number(main, h.position + Vector3(0, 1.1, 0), "Flashback : " + Data.def(fb.id).name, Color(0.85, 0.7, 1.0))
		else:
			draw(1)
	if c.get("oeuvre", false):
		var idx: Array = range(deck.size()).filter(func(q): return Data.level(deck[q]) < Data.lvl_cap(deck[q]))
		if idx.size() > 0:
			var j: int = await main.ui.choose("L'ŒUVRE", "Quelle carte passe au niveau 3 pour toute la run ?", idx.map(func(q): return {"card": deck[q]}), true)
			if j >= 0:
				deck[idx[j]]["lvl"] = Data.lvl_cap(deck[idx[j]])
				main.ui.banner("L'Œuvre", "%s passe au niveau 3" % Data.def(deck[idx[j]].id).name)
