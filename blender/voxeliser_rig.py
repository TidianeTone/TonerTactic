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
M = body.matrix_world
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
    for k in range(3):
        for b, g in vw[t[k]].items():
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
    b = arm.data.bones.get(bone)
    return (arm.matrix_world @ b.head_local).z if b else None


hip_z = zof("mixamorig:Hips")
knee_z = zof("mixamorig:LeftLeg")
LEGS = ("mixamorig:LeftUpLeg", "mixamorig:RightUpLeg", "mixamorig:LeftLeg", "mixamorig:RightLeg")


def skirt(cell, wt):
    z = org.z + (cell[2] + 0.5) * vs
    if hip_z is None or z > hip_z or z < (knee_z or 0) - vs * 6:
        return dict(wt)  # au-dessus du bassin, ou les bottes : inchangé
    k = 0.92 if z > (knee_z or 0) else 0.75  # plus on descend vers les bottes, plus les jambes reprennent la main
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
        top = sorted(w.items(), key=lambda kv: -kv[1])[:4]
        s = sum(g for _, g in top) or 1.0
        cells[c] = (cells[c][0], [(b, g / s) for b, g in top])


smooth(vox, 12)


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
                wts.append(wt)
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
arm.data.pose_position = "POSE"

# --- animations : une action par FBX, au nom du fichier (idle, walk, cast, hit, death)
for ac in list(bpy.data.actions):
    bpy.data.actions.remove(ac)
for f in sorted(os.listdir(ANIMS)):
    if not f.lower().endswith(".fbx"):
        continue
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(ANIMS, f))
    new = [o for o in bpy.context.scene.objects if o not in before]
    src = next(o for o in new if o.type == "ARMATURE")
    ac = src.animation_data.action
    ac.name = f[:-4]
    ac.use_fake_user = True
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
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
