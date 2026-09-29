# Perso riggé Mixamo -> modèle voxel animé pour TonerTactic (PC ultra, assets/hd/).
# Une coque de voxels (couleur prise dans la texture, poids d'os du point de surface le plus proche),
# les objets *_glow deviennent des voxels lumineux, les FBX d'animation (sans skin) deviennent des actions.
# blender -b -P blender/voxeliser_rig.py -- rig.fbx dossier_anims sortie.glb [voxels_de_haut=96] [hauteur_jeu=2.3] [couleur_glow=#ffc93a]
import bpy, sys, os, math
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc

a = sys.argv[sys.argv.index("--") + 1:]
RIG, ANIMS, OUT = a[0], a[1], a[2]
N = int(a[3]) if len(a) > 3 else 96
TARGET_H = float(a[4]) if len(a) > 4 else 2.3
GLOW_HEX = a[5] if len(a) > 5 else "#ffc93a"
GLOW_DZ = float(os.environ.get("DELVE_GLOW_DZ", "0"))   # décale les parties lumineuses (m, taille Mixamo) : yeux sous un bord de chapeau
BRIGHT = float(os.environ.get("DELVE_BRIGHT", "1.0"))    # éclaircit la texture (le jeu la rend plus sombre que Blender)


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


GLOW = tuple(lin(int(GLOW_HEX[i:i + 2], 16) / 255) for i in (1, 3, 5))
FACES = {
    (1, 0, 0): [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)],
    (-1, 0, 0): [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)],
    (0, 1, 0): [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)],
    (0, -1, 0): [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)],
    (0, 0, 1): [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)],
    (0, 0, -1): [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)],
}
AO = [0.5, 0.68, 0.85, 1.0]

bpy.ops.wm.read_factory_settings(use_empty=True)
STATIC = RIG.lower().endswith(".glb")  # modèle TRELLIS brut, sans squelette : aperçu voxel immobile
if STATIC:
    bpy.ops.import_scene.gltf(filepath=RIG)
    arm = None
else:
    bpy.ops.import_scene.fbx(filepath=RIG)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    arm.data.pose_position = "REST"
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
body = max((o for o in meshes if "glow" not in o.name), key=lambda o: len(o.data.vertices))
glows = [o for o in meshes if "glow" in o.name]
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()

# --- surface du corps en coordonnées monde, triangles, UV, poids
ev = body.evaluated_get(dg)
me = ev.to_mesh()
me.calc_loop_triangles()
from mathutils import Matrix
FLIP = os.environ.get("DELVE_FLIP") == "1"  # TRELLIS sort parfois le modèle de dos
M = (Matrix.Rotation(0 if FLIP else math.pi, 4, "Z") @ body.matrix_world) if STATIC else body.matrix_world  # TRELLIS regarde vers +Y
verts = [M @ v.co for v in me.vertices]
tris = [tuple(t.vertices) for t in me.loop_triangles]
tri_loops = [tuple(t.loops) for t in me.loop_triangles]
uv = me.uv_layers.active.data
bvh = BVHTree.FromPolygons(verts, tris)
gname = {g.index: g.name for g in body.vertex_groups}
vw = [{gname[g.group]: g.weight for g in v.groups if g.weight > 0.001} for v in body.data.vertices]
img = next(n.image for m in body.data.materials for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image)
W, H = img.size
tex = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[:, :, :3]
tex = np.where(tex <= 0.04045, tex / 12.92, ((tex + 0.055) / 1.055) ** 2.4)  # texture sRGB -> linéaire

# --- vocation : la forme et les couleurs viennent d'un autre modèle TRELLIS (DELVE_SKIN), calé sur le corps riggé ;
# les poids restent ceux du héros de base (point le plus proche de sa surface) : pas de Mixamo par vocation.
SKIN = os.environ.get("DELVE_SKIN")
if SKIN:
    wverts, wtris, wvw, wbvh = verts, tris, vw, bvh
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=SKIN)
    sk = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    sme = sk[0].evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    sme.calc_loop_triangles()
    R = Matrix.Rotation(0 if os.environ.get("DELVE_SKIN_FLIP") == "1" else math.pi, 4, "Z") @ sk[0].matrix_world
    sv = [R @ v.co for v in sme.vertices]
    blo = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
    bhi = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
    slo = Vector((min(v.x for v in sv), min(v.y for v in sv), min(v.z for v in sv)))
    shi = Vector((max(v.x for v in sv), max(v.y for v in sv), max(v.z for v in sv)))
    k = (bhi.z - blo.z) / (shi.z - slo.z)
    sc, bc = (slo + shi) / 2, (blo + bhi) / 2
    verts = [Vector(((v.x - sc.x) * k + bc.x, (v.y - sc.y) * k + bc.y, (v.z - slo.z) * k + blo.z)) for v in sv]
    tris = [tuple(t.vertices) for t in sme.loop_triangles]
    tri_loops = [tuple(t.loops) for t in sme.loop_triangles]
    uv = sme.uv_layers.active.data
    bvh = BVHTree.FromPolygons(verts, tris)
    img = next(n.image for m in sk[0].data.materials for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image)
    W, H = img.size
    tex = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[:, :, :3]
    tex = np.where(tex <= 0.04045, tex / 12.92, ((tex + 0.055) / 1.055) ** 2.4)
    meshes += sk
    print("peau", os.path.basename(SKIN), "échelle", round(k, 3))

lo = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
hi = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
vs = (hi.z - lo.z) / N
dims = [int(math.ceil((hi[i] - lo[i]) / vs)) + 2 for i in range(3)]
org = lo - Vector((vs, vs, vs))
print("grille", dims, "voxel", round(vs, 4))


def sample(loc, ti):
    t = tris[ti]
    w = poly_3d_calc([verts[t[0]], verts[t[1]], verts[t[2]]], loc)
    u = sum(uv[tri_loops[ti][k]].uv[0] * w[k] for k in range(3))
    v = sum(uv[tri_loops[ti][k]].uv[1] * w[k] for k in range(3))
    x, y = int(u % 1.0 * (W - 1)), int(v % 1.0 * (H - 1))
    col = tex[max(y - 1, 0):y + 2, max(x - 1, 0):x + 2].reshape(-1, 3).mean(axis=0)
    wt = {}
    if SKIN:  # poids pris sur le corps du héros de base
        wl, _, wti, _ = wbvh.find_nearest(loc)
        t = wtris[wti]
        w = poly_3d_calc([wverts[t[0]], wverts[t[1]], wverts[t[2]]], wl)
        src_w = wvw
    else:
        src_w = vw
    for k in range(3):
        for b, g in src_w[t[k]].items():
            wt[b] = wt.get(b, 0.0) + g * w[k]
    top = sorted(wt.items(), key=lambda kv: -kv[1])[:4]
    s = sum(g for _, g in top) or 1.0
    return tuple(min(c * BRIGHT, 1.0) for c in col), [(b, g / s) for b, g in top]


vox = {}
thr = vs * 0.62
for ix in range(dims[0]):
    for iy in range(dims[1]):
        for iz in range(dims[2]):
            c = org + Vector(((ix + 0.5) * vs, (iy + 0.5) * vs, (iz + 0.5) * vs))
            loc, nrm, ti, d = bvh.find_nearest(c, thr)
            if loc is not None:
                vox[(ix, iy, iz)] = sample(loc, ti)
print("voxels corps", len(vox))

# --- vocation Receleur : le barda du Receleur de base (DELVE_BAG = son rig), recopié au dos et fixé au haut du dos
BAG = os.environ.get("DELVE_BAG")
if BAG and arm:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=BAG)
    new = [o for o in bpy.context.scene.objects if o not in before]
    barm = next(o for o in new if o.type == "ARMATURE")
    barm.data.pose_position = "REST"
    bbody = max((o for o in new if o.type == "MESH" and "glow" not in o.name), key=lambda o: len(o.data.vertices))
    bpy.context.view_layer.update()
    bme = bbody.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    bme.calc_loop_triangles()
    bv = [bbody.matrix_world @ v.co for v in bme.vertices]
    btr = [tuple(t.vertices) for t in bme.loop_triangles]
    blp = [tuple(t.loops) for t in bme.loop_triangles]
    buv = bme.uv_layers.active.data
    bbvh = BVHTree.FromPolygons(bv, btr)
    bimg = next(n.image for m in bbody.data.materials for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image)
    BW, BH = bimg.size
    btex = np.array(bimg.pixels[:], dtype=np.float32).reshape(BH, BW, 4)[:, :, :3]
    btex = np.where(btex <= 0.04045, btex / 12.92, ((btex + 0.055) / 1.055) ** 2.4)
    s_sp = barm.matrix_world @ barm.data.bones["mixamorig:Spine2"].head_local
    s_hip = (barm.matrix_world @ barm.data.bones["mixamorig:Hips"].head_local).z
    t_sp = arm.matrix_world @ arm.data.bones["mixamorig:Spine2"].head_local
    off = t_sp - s_sp
    back = max(v.y for v in verts if abs(v.x - t_sp.x) < 0.12 and abs(v.z - t_sp.z) < 0.12)  # dos du héros au niveau du torse
    push = max(0.0, back - (max(v.y for v in bv if abs(v.x - s_sp.x) < 0.12 and abs(v.z - s_sp.z) < 0.12) + off.y))
    n = 0
    reg = [v for v in bv if v.y >= s_sp.y + 0.14 and v.z >= s_hip]
    rlo = Vector((min(v.x for v in reg), min(v.y for v in reg), min(v.z for v in reg))) + off + Vector((0, push, 0))
    rhi = Vector((max(v.x for v in reg), max(v.y for v in reg), max(v.z for v in reg))) + off + Vector((0, push, 0))
    rng = [range(int((rlo[i] - org[i]) / vs) - 1, int((rhi[i] - org[i]) / vs) + 2) for i in range(3)]
    for (ix, iy, iz) in [(x, y, z) for x in rng[0] for y in rng[1] for z in rng[2]]:  # le sac peut dépasser la grille du héros
        c = org + Vector(((ix + 0.5) * vs, (iy + 0.5) * vs, (iz + 0.5) * vs))
        p = c - off - Vector((0, push, 0))
        if p.y < s_sp.y + 0.14 or p.z < s_hip:  # seulement ce qui dépasse derrière le dos, au-dessus du bassin
            continue
        loc, nrm, ti, d = bbvh.find_nearest(p, thr)
        if loc is None:
            continue
        t = btr[ti]
        w = poly_3d_calc([bv[t[0]], bv[t[1]], bv[t[2]]], loc)
        u = sum(buv[blp[ti][k]].uv[0] * w[k] for k in range(3)); vv = sum(buv[blp[ti][k]].uv[1] * w[k] for k in range(3))
        x, y = int(u % 1.0 * (BW - 1)), int(vv % 1.0 * (BH - 1))
        col = btex[max(y - 1, 0):y + 2, max(x - 1, 0):x + 2].reshape(-1, 3).mean(axis=0)
        vox[(ix, iy, iz)] = (tuple(min(q * BRIGHT, 1.0) for q in col), [("mixamorig:Spine2", 1.0)])
        n += 1
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    print("sac", n, "voxels")

# --- yeux et autres parties lumineuses : cellules sous leur boîte, au moins une, devant la coque
glow = {}
for g in glows:
    bb = [g.matrix_world @ Vector(c) for c in g.bound_box]
    gl = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    gh = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    ctr = (gl + gh) / 2
    cells = set()
    for ix in range(int((gl.x - org.x) / vs), int((gh.x - org.x) / vs) + 1):
        for iz in range(int((gl.z - org.z) / vs), int((gh.z - org.z) / vs) + 1):
            cells.add((ix, int((ctr.y - org.y) / vs), iz + int(round(GLOW_DZ / vs))))
    for cl in cells:
        loc, nrm, ti, d = bvh.find_nearest(org + Vector(((cl[0] + 0.5) * vs, (cl[1] + 0.5) * vs, (cl[2] + 0.5) * vs)))
        glow[cl] = (GLOW, sample(loc, ti)[1])
        # la coque du visage devant l'œil ne doit pas le cacher
        for dy in range(1, 4):
            vox.pop((cl[0], cl[1] - dy, cl[2]), None)
        vox.pop(cl, None)
print("voxels lumineux", len(glow))


# --- poids : une robe suit le bassin, pas les cuisses ; puis lissage de voisin à voisin (sinon le tissu se déchire en lamelles)
def zof(bone):
    b = arm.data.bones.get(bone) if arm else None
    return (arm.matrix_world @ b.head_local).z if b else None


hip_z = zof("mixamorig:Hips")
knee_z = zof("mixamorig:LeftLeg")
ankle_z = zof("mixamorig:LeftFoot")
LEGS = ("mixamorig:LeftUpLeg", "mixamorig:RightUpLeg", "mixamorig:LeftLeg", "mixamorig:RightLeg")


def skirt(cell, wt):
    z = org.z + (cell[2] + 0.5) * vs
    if hip_z is None or z > hip_z or z < (knee_z or 0):
        return dict(wt)  # au-dessus du bassin, ou sous le genou (tibias, bottes) : inchangé
    k = 0.85  # une robe suit le bassin ; sous le genou, les jambes gardent la main (sinon les pieds glissent)
    out = {}
    for b, g in wt:
        if b in LEGS:
            out[b] = out.get(b, 0.0) + g * (1 - k)
            out["mixamorig:Hips"] = out.get("mixamorig:Hips", 0.0) + g * k
        else:
            out[b] = out.get(b, 0.0) + g
    return out


def smooth(cells, iters=4):
    cur = {c: skirt(c, wt) for c, (col, wt) in cells.items()}
    for _ in range(iters):
        nxt = {}
        for (x, y, z), w in cur.items():
            acc = dict(w)
            n = 1
            for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
                nw = cur.get((x + d[0], y + d[1], z + d[2]))
                if nw:
                    n += 1
                    for b, g in nw.items():
                        acc[b] = acc.get(b, 0.0) + g
            nxt[(x, y, z)] = {b: g / n for b, g in acc.items()}
        cur = nxt
    for c, w in cur.items():
        if ankle_z is not None and org.z + (c[2] + 0.5) * vs < ankle_z + vs * 2:
            w = dict(cells[c][1])  # pieds : poids d'origine, jamais lissés (un pied lissé s'étire vers l'autre jambe)
        top = sorted(w.items(), key=lambda kv: -kv[1])[:4]
        s = sum(g for _, g in top) or 1.0
        cells[c] = (cells[c][0], [(b, g / s) for b, g in top])


# --- découpes (DELVE_CUT) et zone rigide (DELVE_RIGID), mesurées en unités du jeu (modèle de TARGET_H de haut, pieds à 0)
#   DELVE_CUT="x0,x1,y0,y1,z0,z1[,v];..." : voxels retirés (l'arc dans le dos du Trappeur) ; v : seulement ceux plus clairs
#   que v (le bois de l'arc, pas le manteau sombre qu'il longe)
#   DELVE_RIGID="y_rigide,y_coupe" : dans le dos (+Y), au-dessus du genou, au-delà de y_rigide -> 100 % Spine2 (un bouclier ne
#   ondule pas comme une cape) ; sous le genou, au-delà de y_coupe -> retiré (sinon la jambe arrière le traverse en marchant)
KG = TARGET_H / (hi.z - lo.z)


def cell_game(c):
    return (org + Vector(((c[0] + 0.5) * vs, (c[1] + 0.5) * vs, (c[2] + 0.5) * vs))) * KG


CUTS = [tuple(map(float, b.split(","))) for b in os.environ.get("DELVE_CUT", "").split(";") if b.strip()]
if CUTS:
    n0 = len(vox)
    for c in list(vox):
        p = cell_game(c)
        v = max(x * 12.92 if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055 for x in vox[c][0])  # luminosité sRGB
        if any(b[0] <= p.x <= b[1] and b[2] <= p.y <= b[3] and b[4] <= p.z <= b[5] and v >= (b[6] if len(b) > 6 else 0) for b in CUTS):
            del vox[c]
    print("découpe", n0 - len(vox), "voxels")
RIGID = os.environ.get("DELVE_RIGID")
rigid = set()
if RIGID and arm:
    y_r, y_c = map(float, RIGID.split(","))
    kz = (knee_z or 0) * KG
    for c in list(vox):
        p = cell_game(c)
        if p.z >= kz and p.y >= y_r:
            rigid.add(c)
        elif p.z < kz and p.y >= y_c:
            del vox[c]
    print("rigide", len(rigid), "voxels")

if arm:
    smooth(vox, 12)
    for c in rigid:
        if c in vox:
            vox[c] = (vox[c][0], [("mixamorig:Spine2", 1.0)])


# --- poids aux coins : un sommet partagé par des cubes voisins prend la moyenne de leurs poids ; les cubes restent soudés
# quand les os tournent (sinon chacun suit son os, ils s'écartent, et l'on voit à travers la coque creuse)
_corner = {}


def corner_w(x, y, z):
    key = (x, y, z)
    if key in _corner:
        return _corner[key]
    acc, n = {}, 0
    for dx in (-1, 0):
        for dy in (-1, 0):
            for dz in (-1, 0):
                c = (x + dx, y + dy, z + dz)
                cw = vox.get(c) or glow.get(c)
                if cw:
                    n += 1
                    for b, g in cw[1]:
                        acc[b] = acc.get(b, 0.0) + g
    top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
    s = sum(g for _, g in top) or 1.0
    _corner[key] = [(b, g / s) for b, g in top]
    return _corner[key]


def build(name, cells, ao, emissive):
    vs_, fs, cols, wts = [], [], [], []
    occ = set(vox) | set(glow)
    for (x, y, z), (c, wt) in cells.items():
        for n, corners in FACES.items():
            if (x + n[0], y + n[1], z + n[2]) in occ:
                continue
            a_ = 0 if n[0] else (1 if n[1] else 2)
            a1, a2 = [i for i in range(3) if i != a_]
            p = (x + n[0], y + n[1], z + n[2])
            base = len(vs_)
            for cr in corners:
                vs_.append(org + Vector(((x + cr[0]) * vs, (y + cr[1]) * vs, (z + cr[2]) * vs)))
                f = 1.0
                if ao:
                    s1 = 1 if cr[a1] else -1
                    s2 = 1 if cr[a2] else -1
                    q1 = list(p); q1[a1] += s1
                    q2 = list(p); q2[a2] += s2
                    q3 = list(q1); q3[a2] += s2
                    o1, o2, o3 = tuple(q1) in occ, tuple(q2) in occ, tuple(q3) in occ
                    f = AO[0 if (o1 and o2) else 3 - (o1 + o2 + o3)]
                cols.append((c[0] * f, c[1] * f, c[2] * f, 1.0))
                wts.append(corner_w(x + cr[0], y + cr[1], z + cr[2]) if arm else wt)
            fs.append((base, base + 1, base + 2, base + 3))
    m = bpy.data.meshes.new(name)
    m.from_pydata([tuple(v) for v in vs_], [], fs)
    at = m.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    at.data.foreach_set("color", [k for c in cols for k in c])
    mat = bpy.data.materials.new(name)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Col"
    nt.links.new(ca.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    if emissive:
        nt.links.new(ca.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 4.0
    m.materials.append(mat)
    ob = bpy.data.objects.new(name, m)
    bpy.context.scene.collection.objects.link(ob)
    groups = {}
    for i, wt in enumerate(wts):
        for b, g in wt:
            if b not in groups:
                groups[b] = ob.vertex_groups.new(name=b)
            groups[b].add([i], g, "REPLACE")
    if arm:
        ob.parent = arm
        ob.matrix_parent_inverse = arm.matrix_world.inverted()
        mod = ob.modifiers.new("Armature", "ARMATURE")
        mod.object = arm
    print(name, len(fs), "faces")
    return ob


stem = os.path.basename(OUT).removesuffix(".glb").removeprefix("u_")
built = [build(stem + "_body", vox, True, False)]
if glow:
    built.append(build(stem + "_glow", glow, False, True))
for o in meshes:
    bpy.data.objects.remove(o, do_unlink=True)
if STATIC:
    k = TARGET_H / (hi.z - lo.z)
    for o in built:
        o.location = (-(lo.x + hi.x) / 2 * k, -(lo.y + hi.y) / 2 * k, -lo.z * k)
        o.scale = (k, k, k)
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True)
    print("ok", OUT)
    sys.exit(0)
arm.data.pose_position = "POSE"

# --- animations : une action par FBX, au nom du fichier (idle, walk, cast, hit, death)
for ac in list(bpy.data.actions):
    bpy.data.actions.remove(ac)
from mathutils import Matrix


def retarget(src, dst, name):
    """Les animations Mixamo sont liées au squelette qui les a téléchargées : on rejoue le mouvement
    en espace armature (rotation monde de chaque os par rapport à son repos), recalculé pour le repos de dst."""
    sb, db = src.data.bones, dst.data.bones
    order = [b.name for b in db if b.name in sb]  # data.bones : parents avant enfants
    hs = (sb["mixamorig:Hips"].head_local.length / max(db["mixamorig:Hips"].head_local.length, 1e-6)) if "mixamorig:Hips" in sb else 1.0  # axe haut de l armature Mixamo : Y
    ac = bpy.data.actions.new(name)
    dst.animation_data_create()
    dst.animation_data.action = ac
    f0, f1 = [int(x) for x in src.animation_data.action.frame_range]
    for fr in range(f0, f1 + 1):
        bpy.context.scene.frame_set(fr)
        world = {}
        for n in order:
            spb, b = src.pose.bones[n], db[n]
            rot = (spb.matrix.to_3x3() @ sb[n].matrix_local.to_3x3().inverted()) @ b.matrix_local.to_3x3()
            if b.parent and b.parent.name in world:
                rel = b.parent.matrix_local.inverted() @ b.matrix_local
                head = (world[b.parent.name] @ rel).translation
            else:  # racine : la translation Mixamo, remise à l'échelle du héros
                head = b.matrix_local.translation + (spb.matrix.translation - sb[n].matrix_local.translation) / hs
            m = Matrix.Translation(head) @ rot.to_4x4()
            world[n] = m
            parent_rest = (world[b.parent.name] @ (b.parent.matrix_local.inverted() @ b.matrix_local)) if (b.parent and b.parent.name in world) else b.matrix_local
            pb = dst.pose.bones[n]
            pb.matrix_basis = parent_rest.inverted() @ m
            pb.keyframe_insert("rotation_quaternion", frame=fr) if pb.rotation_mode == "QUATERNION" else pb.keyframe_insert("rotation_euler", frame=fr)
            if not b.parent:
                pb.keyframe_insert("location", frame=fr)
    ac.use_fake_user = True
    return ac


for f in sorted(os.listdir(ANIMS)):
    if not f.lower().endswith(".fbx"):
        continue
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(ANIMS, f))
    new = [o for o in bpy.context.scene.objects if o not in before]
    src = next(o for o in new if o.type == "ARMATURE")
    ac = retarget(src, arm, f[:-4])
    old = src.animation_data.action
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.actions.remove(old)
    print("action", ac.name, ac.frame_range[:])

arm.animation_data_create()
first = bpy.data.actions.get("idle") or bpy.data.actions[0]
arm.animation_data.action = first
k = TARGET_H / (hi.z - lo.z)
arm.scale = arm.scale * k
arm.name = stem
for o in bpy.context.scene.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True,
                          export_animation_mode="ACTIONS", export_force_sampling=True)
print("ok", OUT)
