# Pierre de rareté au milieu de la carte : l'ovale serti en cristal taillé (retenu), 4 couleurs ; les autres dessins restent pour comparer.
# "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P blender/render_gemmes.py -- [--design=eclat] [--out=DIR]
#   -> DIR/gemme_<1..4>.png (défaut assets/ui) ; --all : chaque dessin dans DIR/<dessin>_<1..4>.png (planche de choix)
import bpy, math, os, sys, random, bmesh
from mathutils import Vector

ARGS = dict((a[2:].split("=", 1) + ["1"])[:2] for a in sys.argv[sys.argv.index("--") + 1:] if a.startswith("--")) if "--" in sys.argv else {}
OUT = ARGS.get("out", r"G:\Mes APP\Delve\assets\ui")
COLS = {1: (0.46, 0.47, 0.5), 2: (0.2, 0.4, 0.85), 3: (0.46, 0.22, 0.8), 4: (0.9, 0.42, 0.12)}  # commune, peu commune, rare, légendaire


def gem_mat(col):
    ## Cristal sobre : peu de lueur, des fractures claires (la lumière prise dans les cassures) tirées d'un Voronoi.
    m = bpy.data.materials.new("cristal")
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Roughness"].default_value = 0.28
    b.inputs["Transmission Weight"].default_value = 0.15
    b.inputs["IOR"].default_value = 1.7
    b.inputs["Coat Weight"].default_value = 0.15
    b.inputs["Emission Color"].default_value = (*(c * c for c in col), 1)
    b.inputs["Emission Strength"].default_value = 0.35
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.3, 1.3, 0.55)  # quelques grandes cassures, plutôt verticales, comme les éclats
    no = nt.nodes.new("ShaderNodeTexNoise")  # cassures tordues, pas un pavage
    no.inputs["Scale"].default_value = 2.5
    add = nt.nodes.new("ShaderNodeVectorMath")
    add.operation = "MULTIPLY_ADD"
    add.inputs[1].default_value = (0.45, 0.45, 0.45)
    vo = nt.nodes.new("ShaderNodeTexVoronoi")
    vo.feature = "DISTANCE_TO_EDGE"
    vo.inputs["Scale"].default_value = 1.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (*(min(1.0, c * 0.4 + 0.45) for c in col), 1)
    ramp.color_ramp.elements[1].position = 0.025
    ramp.color_ramp.elements[1].color = (*(c * c * 0.5 for c in col), 1)
    # du pied sombre à la pointe claire : la lumière monte dans le cristal
    grad = nt.nodes.new("ShaderNodeSeparateXYZ")
    mixh = nt.nodes.new("ShaderNodeMix")
    mixh.data_type = "RGBA"
    mixh.blend_type = "MULTIPLY"
    mrange = nt.nodes.new("ShaderNodeMapRange")
    mrange.inputs["From Min"].default_value = -1.0
    mrange.inputs["From Max"].default_value = 1.2
    mrange.inputs["To Min"].default_value = 0.35
    mrange.inputs["To Max"].default_value = 1.25
    nt.links.new(tc.outputs["Object"], grad.inputs["Vector"])
    nt.links.new(grad.outputs["Z"], mrange.inputs["Value"])
    mixh.inputs["Factor"].default_value = 1.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.35
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], no.inputs["Vector"])
    nt.links.new(no.outputs["Color"], add.inputs[0])
    nt.links.new(mp.outputs["Vector"], add.inputs[2])
    nt.links.new(add.outputs["Vector"], vo.inputs["Vector"])
    nt.links.new(vo.outputs["Distance"], ramp.inputs["Fac"])
    mixh.inputs["B"].default_value = (1, 1, 1, 1)
    nt.links.new(ramp.outputs["Color"], mixh.inputs["A"])
    nt.links.new(mrange.outputs["Result"], mixh.inputs["B"])
    nt.links.new(mixh.outputs["Result"], b.inputs["Base Color"])
    nt.links.new(vo.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


# teinte d'absorption : l'épaisseur assombrit et sature, on part donc plus clair (le gris restait noir, l'orange virait au rouge)
CRISTAL = {COLS[1]: (0.78, 0.8, 0.84), COLS[4]: (1.0, 0.62, 0.22)}


def crystal_mat(col):
    ## Du vrai cristal : verre teinté dans la masse, réfracté ; les facettes du pavillon se voient à travers la table.
    m = bpy.data.materials.new("cristal_taille")
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*(min(1.0, c * 0.6 + 0.4) for c in col), 1)
    b.inputs["Transmission Weight"].default_value = 1.0
    b.inputs["Roughness"].default_value = 0.0
    b.inputs["IOR"].default_value = 1.75
    ab = nt.nodes.new("ShaderNodeVolumeAbsorption")  # la couleur vient de l'épaisseur traversée : cœur profond, arêtes claires
    ab.inputs["Color"].default_value = (*CRISTAL.get(tuple(col), col), 1)
    ab.inputs["Density"].default_value = 1.1
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    nt.links.new(ab.outputs["Volume"], out.inputs["Volume"])
    return m


def ovale(sides=12):
    ## Ovale taillé en brillant, table face à l'appareil, serti d'un anneau d'argent.
    rx, ry = 0.7, 1.1
    rings = [(0.58, 0.34, 0.5), (0.86, 0.2, 0.0), (1.0, 0.0, 0.5), (1.0, -0.06, 0.5)]  # (rayon, profondeur, décalage d'un demi-pan)
    bm = bmesh.new()
    loops = []
    for r, z, off in rings:
        loops.append([bm.verts.new((r * rx * math.cos((k + off) * 2 * math.pi / sides), r * ry * math.sin((k + off) * 2 * math.pi / sides), z)) for k in range(sides)])
    culet = bm.verts.new((0, 0, -0.95))
    bm.faces.new(loops[0])  # la table
    for a, c in zip(loops, loops[1:]):
        for k in range(sides):
            bm.faces.new((a[k], a[(k + 1) % sides], c[(k + 1) % sides], c[k]))
    for k in range(sides):
        bm.faces.new((loops[-1][(k + 1) % sides], loops[-1][k], culet))  # le pavillon
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new("ovale")
    bm.to_mesh(me)
    bm.free()
    g = bpy.data.objects.new("ovale", me)
    for pl in me.polygons:
        pl.use_smooth = False
    bpy.context.scene.collection.objects.link(g)
    g.rotation_euler = (math.pi / 2, 0, 0)  # la table regarde l'appareil
    g.location = (0, 0.05, 1.12)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.085, major_segments=64, minor_segments=16)  # serti fin : la pierre d'abord
    t = bpy.context.active_object
    t.rotation_euler = (math.pi / 2, 0, 0)
    t.scale = (0.8, 1.0, 1.26)
    t.location = (0, 0, 1.12)
    return [g], [t]


def toon_mat(tones, name="peint", outline=False):
    ## Peint à la main façon Warcraft : chaque facette prend un aplat (ombre, ton, lumière, éclat), pas de dégradé réaliste.
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    if outline:
        # coque retournée : un trait de contour sombre autour de la pierre et du serti
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = (0.035, 0.025, 0.02, 1)
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
        m.use_backface_culling = True
        return m
    dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    bw = nt.nodes.new("ShaderNodeRGBToBW")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    els[0].position = 0.0
    els[0].color = (*tones[0], 1)
    els[1].position = 0.18
    els[1].color = (*tones[1], 1)
    for pos, c in zip((0.42, 0.72), tones[2:]):
        e = els.new(pos)
        e.color = (*c, 1)
    em = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(dif.outputs["BSDF"], s2r.inputs["Shader"])
    nt.links.new(s2r.outputs["Color"], bw.inputs["Color"])
    nt.links.new(bw.outputs["Val"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return m


def tones_of(col):
    ## Quatre tons peints d'une couleur : ombre profonde, ton propre, lumière, éclat presque blanc.
    return [tuple(c * 0.22 for c in col), tuple(c * 0.55 for c in col), tuple(c for c in col), tuple(min(1.0, c * 0.45 + 0.6) for c in col)]


def peint():
    ## L'ovale serti, repeint : moins de facettes (on doit pouvoir les compter), contour, reflet peint.
    gems, metal = ovale(sides=8)
    for o in metal:  # le contour sur le serti seul : sur la pierre, il transparaissait en traits parasites
        md = o.modifiers.new("contour", "SOLIDIFY")
        md.thickness = 0.045
        md.offset = 1.0
        md.use_flip_normals = True
        md.material_offset = 1
    # les traits de facettes peints : une copie en fil de fer, claire, posée sur les arêtes de la couronne
    tr = gems[0].copy()
    tr.data = gems[0].data.copy()
    bpy.context.scene.collection.objects.link(tr)
    wf = tr.modifiers.new("traits", "WIREFRAME")
    wf.thickness = 0.022
    wf.use_replace = True
    tr.location.y -= 0.004
    tr["traits"] = True
    metal.append(tr)
    # le reflet : une virgule blanche en haut à gauche, posée devant la pierre comme un coup de pinceau
    bpy.ops.mesh.primitive_circle_add(vertices=24, radius=1.0, fill_type="NGON", location=(-0.26, -0.5, 1.55))
    hl = bpy.context.active_object
    hl.rotation_euler = (math.pi / 2, 0, 0)
    hl.scale = (0.1, 0.24, 1)
    hl.rotation_euler = (math.pi / 2, math.radians(28), 0)
    mh = bpy.data.materials.new("reflet")
    e = next(n for n in mh.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    e.inputs["Emission Color"].default_value = (1, 0.98, 0.94, 1)
    e.inputs["Emission Strength"].default_value = 1.0
    e.inputs["Base Color"].default_value = (1, 1, 1, 1)
    hl.data.materials.append(mh)
    return gems, metal


def metal_mat(col=(0.42, 0.4, 0.38)):
    m = bpy.data.materials.new("fer")
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*col, 1)
    b.inputs["Metallic"].default_value = 1.0
    b.inputs["Roughness"].default_value = 0.45
    return m


def shard(h=2.0, r=0.4, sides=6, twist=60.0, tip=0.45, seed=0, loc=(0, 0, 0), tilt=(0, 0), foot=0.0):
    ## Un éclat : prisme à n pans, pointe taillée (foot > 0 : le bas aussi), tordu sur sa hauteur, pans irréguliers.
    rnd = random.Random(seed)
    bm = bmesh.new()
    rings = 12
    prev = None
    bot = None
    for i in range(rings + 1):
        t = i / rings
        k = 1.0 if t < 1 - tip else max(0.02, (1 - t) / tip)
        if foot > 0 and t < foot:
            k = min(k, max(0.02, t / foot))
        a0 = math.radians(twist) * t
        ring = []
        for j in range(sides):
            jr = r * k * (1 + rnd.uniform(-0.1, 0.1))
            ring.append(bm.verts.new((jr * math.cos(a0 + j * 2 * math.pi / sides), jr * math.sin(a0 + j * 2 * math.pi / sides), t * h)))
        if prev:
            for j in range(sides):
                bm.faces.new((prev[j], prev[(j + 1) % sides], ring[(j + 1) % sides], ring[j]))
        else:
            bot = ring
        prev = ring
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(prev)
    me = bpy.data.meshes.new("eclat")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("eclat", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (math.radians(tilt[0]), math.radians(tilt[1]), math.radians(25))
    return ob


def helix(radius=0.55, h=2.0, turns=2.2, thick=0.05, z0=0.0, sx=1.0):
    ## Un fil de fer tordu autour de la pierre (les ronces de la référence, en métal).
    cu = bpy.data.curves.new("fil", "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = thick
    cu.bevel_resolution = 3
    sp = cu.splines.new("POLY")
    n = 80
    sp.points.add(n - 1)
    for i in range(n):
        t = i / (n - 1)
        a = t * turns * 2 * math.pi
        sp.points[i].co = (radius * sx * math.cos(a), radius * math.sin(a), z0 + t * h, 1)
    ob = bpy.data.objects.new("fil", cu)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def lozolith():
    ## Le cube de la référence vu par la pointe (contour hexagonal), tordu, fendu : la moitié haute a glissé ; un fil tordu autour.
    bpy.ops.mesh.primitive_cube_add(size=1.05)
    c = bpy.context.active_object
    c.rotation_mode = "ZXY"  # d'abord 45° autour de Z, puis 35,26° : le cube tient sur une pointe, contour hexagonal
    c.rotation_euler = (math.radians(54.74), 0, math.radians(45))
    bpy.ops.object.transform_apply(rotation=True)
    me = c.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=6, use_grid_fill=True)
    n = Vector((0.35, 0.2, 1.0)).normalized()
    for v in bm.verts:
        a = math.radians(26) * (v.co.z + 1.1) / 2.2  # torsion sur la hauteur
        x, y = v.co.x, v.co.y
        v.co.x, v.co.y = x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
        if v.co.dot(n) > 0.1:
            v.co += Vector((0.08, 0.0, 0.06))  # la fêlure : le haut a glissé
    bm.to_mesh(me)
    bm.free()
    c.location = (0, 0, 1.12)
    w = helix(radius=0.8, h=1.3, turns=1.25, thick=0.045, z0=0.47, sx=1.05)
    return [c], [w]


DESIGNS = {
    # retenu : l'ovale serti, peint façon Warcraft (aplats par facette, contour, reflet)
    "peint": peint,
    # l'ovale serti en cristal réaliste (refusé : trop réaliste)
    "ovale": ovale,
    # A. un seul éclat long, tordu d'un cinquième de tour, pointe taillée
    "eclat": lambda: ([shard(2.2, 0.36, 5, 130, 0.4, 1, (0, 0, 0.05))], []),
    # B. trois éclats en gerbe, comme la main de glace : le grand au centre, deux petits penchés
    "gerbe": lambda: ([shard(2.15, 0.27, 5, 120, 0.45, 2, (0, 0, 0.1)),
                       shard(1.3, 0.19, 5, -110, 0.5, 3, (-0.2, 0.12, 0.08), (0, -20)),
                       shard(1.1, 0.18, 5, 100, 0.5, 4, (0.21, 0.12, 0.08), (0, 22))], []),
    # C. un losange à quatre pans, deux pointes, tordu, serré par un fil de fer
    "losange": lambda: ([shard(2.2, 0.5, 4, 80, 0.5, 5, (0, 0, 0.05), foot=0.5)], [helix(0.42, 0.34, 1.6, 0.04, 0.95)]),
    # D. le cube de la référence (« lozolith »), fendu, un fil tordu autour
    "lozolith": lozolith,
}


def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.samples = 96
    s.render.film_transparent = True
    s.render.resolution_x, s.render.resolution_y = 96, 112
    s.view_settings.view_transform = "Standard"
    s.view_settings.look = "Medium High Contrast"
    w = bpy.data.worlds.new("w")
    s.world = w
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.3, 0.27, 0.32, 1)
    bg.inputs["Strength"].default_value = 0.35
    bpy.ops.object.light_add(type="AREA", location=(-1.8, -3.5, 3.4))
    k = bpy.context.active_object
    k.data.energy = 110
    k.data.size = 3.0  # grande et douce : pas de reflet cramé sur un pan plat
    k.rotation_euler = (math.radians(50), 0, math.radians(-25))
    bpy.ops.object.light_add(type="AREA", location=(2.6, 1.2, 2.2))  # contre-jour : une arête claire sur les pans de droite
    rim = bpy.context.active_object
    rim.data.energy = 90
    rim.data.size = 0.6
    rim.data.color = (0.8, 0.88, 1.0)
    rim.rotation_euler = (math.radians(60), 0, math.radians(115))
    bpy.ops.object.camera_add(location=(0, -12, 1.12), rotation=(math.pi / 2, 0, 0))
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 2.6
    s.camera = cam


def crystal_world():
    ## Un ciel contrasté (haut clair et chaud, bas noir) : c'est lui que les facettes réfractent, d'où les pans clairs et sombres.
    s = bpy.context.scene
    s.cycles.samples = 256
    s.cycles.transmission_bounces = 16
    s.cycles.max_bounces = 24
    nt = s.world.node_tree
    bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.03, 0.028, 0.035, 1)
    ramp.color_ramp.elements[1].position = 0.62
    ramp.color_ramp.elements[1].color = (2.2, 2.0, 1.75, 1)
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = -1.0
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Z"], mr.inputs["Value"])
    nt.links.new(mr.outputs["Result"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 1.0


# couleurs peintes, franches mais pas néon
PEINT = {1: (0.62, 0.64, 0.68), 2: (0.2, 0.52, 1.0), 3: (0.62, 0.3, 1.0), 4: (1.0, 0.33, 0.02)}  # légendaire bien orange (il le voyait jaune)


def eevee():
    s = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            s.render.engine = eng
            break
        except TypeError:
            continue
    s.view_settings.view_transform = "Standard"
    s.view_settings.look = "None"
    s.render.resolution_x, s.render.resolution_y = 192, 224  # rendu ×2 puis réduit : trait net
    # une seule lumière franche en haut à gauche : les facettes se rangent en ombre / ton / lumière
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o)
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(35), math.radians(-35), math.radians(-30)))
    bpy.context.active_object.data.energy = 3.0
    bpy.context.active_object.data.use_shadow = False  # l'ombre douce laissait une tache au centre de la table


def render(name, prefix):
    scene()
    gems, metal = DESIGNS[name]()
    line = toon_mat(None, "contour", outline=True)
    for m in metal:
        if m.get("traits"):
            continue  # teinté plus bas, avec la pierre
        if name == "peint":
            m.data.materials.append(toon_mat([(0.1, 0.05, 0.02), (0.4, 0.22, 0.07), (0.78, 0.52, 0.2), (1.0, 0.86, 0.5)], "bronze_peint"))  # serti bronze doré, plus Warcraft
            m.data.materials.append(line)
        else:
            m.data.materials.append(metal_mat((0.55, 0.55, 0.57) if name == "ovale" else (0.42, 0.4, 0.38)))
    if name == "ovale":
        crystal_world()
    if name == "peint":
        eevee()
    for r, col in COLS.items():
        mt = toon_mat(tones_of(PEINT.get(r, col))) if name == "peint" else (crystal_mat(col) if name == "ovale" else gem_mat(col))
        for g in gems:
            g.data.materials.clear()
            g.data.materials.append(mt)
        for m in metal:
            if m.get("traits"):
                tn = tones_of(PEINT.get(r, col))
                m.data.materials.clear()
                m.data.materials.append(toon_mat([tn[2], tn[3], tn[3], (1, 1, 1)], "traits"))

        bpy.context.scene.render.filepath = os.path.join(OUT, "%s%d.png" % (prefix, r))
        bpy.ops.render.render(write_still=True)


if "all" in ARGS:
    for d in DESIGNS:
        render(d, d + "_")
else:
    render(ARGS.get("design", "peint"), "gemme_")
print("gemmes ok")
