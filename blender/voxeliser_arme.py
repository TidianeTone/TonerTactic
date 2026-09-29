# Arme TRELLIS -> arme voxel des héros HD (assets/hd/arme_<classe>.glb).
# Même grain que les héros (1,75 m sur 96 voxels), couleurs prises dans la texture, origine sur la poignée,
# grand axe vertical (+Y dans Godot). La zone colorable devient l'enfant <classe>_weapon_glow : le jeu la teinte
# à la couleur de l'autre classe quand le héros est multiclasse.
# blender -b -P blender/voxeliser_arme.py -- entree.glb sortie.glb classe
import bpy, sys, math, colorsys
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc

a = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT, CLS = a[0], a[1], a[2]
VS = 1.75 / 96
# classe : (longueur en jeu, poignée en fraction du grand axe depuis le bas, zone colorable[, grand axe])
#   grand axe : "z" (debout, défaut) ou "-y" (arbalète couchée : la crosse vers +Y, l'arc devant vers -Y ; poignée comptée depuis la crosse)
#   ("teinte", "#rrggbb", tolérance de teinte, saturation min, valeur min) | ("clair", valeur min, saturation max) | ("haut", fraction)
ARMES = {
    "garde": (0.95, 0.10, ("teinte", "#3d63e0", 0.07, 0.45, 0.35)),
    "lame": (0.60, 0.12, ("teinte", "#e0344f", 0.05, 0.55, 0.45)),
    "oracle": (1.70, 0.45, ("teinte", "#ff7a1a", 0.06, 0.55, 0.55)),
    "artificier": (0.95, 0.22, ("teinte", "#d0409a", 0.07, 0.45, 0.45)),
    "moine": (0.28, 0.30, ("teinte", "#6cc24a", 0.08, 0.40, 0.40)),
    "trappeur": (0.75, 0.22, ("teinte", "#f0a13c", 0.05, 0.70, 0.75), "-y"),
    "receleur": (0.60, 0.93, ("clair", 0.78, 0.30)),
    "tidiane": (1.10, 0.35, ("haut", 0.70)),
}
LONG, GRIP, ZONE = ARMES[CLS][:3]
AXE = ARMES[CLS][3] if len(ARMES[CLS]) > 3 else "z"
AI = 2 if AXE == "z" else 1
AO = [0.5, 0.68, 0.85, 1.0]
FACES = {
    (1, 0, 0): [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)],
    (-1, 0, 0): [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)],
    (0, 1, 0): [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)],
    (0, -1, 0): [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)],
    (0, 0, 1): [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)],
    (0, 0, -1): [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)],
}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
body = max((o for o in bpy.context.scene.objects if o.type == "MESH"), key=lambda o: len(o.data.vertices))
me = body.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
me.calc_loop_triangles()
verts = [body.matrix_world @ v.co for v in me.vertices]
lo = Vector([min(v[i] for v in verts) for i in range(3)])
hi = Vector([max(v[i] for v in verts) for i in range(3)])
k = LONG / (hi[AI] - lo[AI])  # à sa taille en jeu, mesurée sur son grand axe
verts = [(v - lo) * k for v in verts]
lo, hi = Vector((0, 0, 0)), (hi - lo) * k
tris = [tuple(t.vertices) for t in me.loop_triangles]
tri_loops = [tuple(t.loops) for t in me.loop_triangles]
uv = me.uv_layers.active.data
bvh = BVHTree.FromPolygons(verts, tris)
img = next(n.image for m in body.data.materials for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image)
W, H = img.size
tex = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[:, :, :3]
tex = np.where(tex <= 0.04045, tex / 12.92, ((tex + 0.055) / 1.055) ** 2.4)


def sample(loc, ti):
    t = tris[ti]
    w = poly_3d_calc([verts[t[0]], verts[t[1]], verts[t[2]]], loc)
    u = sum(uv[tri_loops[ti][j]].uv[0] * w[j] for j in range(3))
    v = sum(uv[tri_loops[ti][j]].uv[1] * w[j] for j in range(3))
    x, y = int(u % 1.0 * (W - 1)), int(v % 1.0 * (H - 1))
    return tuple(tex[max(y - 1, 0):y + 2, max(x - 1, 0):x + 2].reshape(-1, 3).mean(axis=0))


def srgb(c):
    return tuple(x * 12.92 if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055 for x in c)


def colorable(c, z):
    if ZONE[0] == "haut":
        return z >= hi.z * ZONE[1]
    h, s, v = colorsys.rgb_to_hsv(*srgb(c))
    if ZONE[0] == "clair":
        return v >= ZONE[1] and s <= ZONE[2]
    th = colorsys.rgb_to_hsv(*(int(ZONE[1][i:i + 2], 16) / 255 for i in (1, 3, 5)))[0]
    dh = min(abs(h - th), 1 - abs(h - th))
    return dh <= ZONE[2] and s >= ZONE[3] and v >= ZONE[4]


dims = [int(math.ceil(hi[i] / VS)) + 2 for i in range(3)]
org = -Vector((VS, VS, VS))
vox, glow = {}, {}
for ix in range(dims[0]):
    for iy in range(dims[1]):
        for iz in range(dims[2]):
            c = org + Vector(((ix + 0.5) * VS, (iy + 0.5) * VS, (iz + 0.5) * VS))
            loc, nrm, ti, d = bvh.find_nearest(c, VS * 0.62)
            if loc is not None:
                col = sample(loc, ti)
                (glow if colorable(col, c.z) else vox)[(ix, iy, iz)] = col
print(CLS, "grille", dims, "voxels", len(vox), "colorables", len(glow))


def build(name, cells, ao):
    vs_, fs, cols = [], [], []
    occ = set(vox) | set(glow)
    for (x, y, z), c in cells.items():
        for n, corners in FACES.items():
            if (x + n[0], y + n[1], z + n[2]) in occ:
                continue
            a_ = 0 if n[0] else (1 if n[1] else 2)
            a1, a2 = [i for i in range(3) if i != a_]
            p = (x + n[0], y + n[1], z + n[2])
            base = len(vs_)
            for cr in corners:
                vs_.append(org + Vector(((x + cr[0]) * VS, (y + cr[1]) * VS, (z + cr[2]) * VS)))
                f = 1.0
                if ao:
                    q1 = list(p); q1[a1] += 1 if cr[a1] else -1
                    q2 = list(p); q2[a2] += 1 if cr[a2] else -1
                    q3 = list(q1); q3[a2] = q2[a2]
                    o1, o2, o3 = tuple(q1) in occ, tuple(q2) in occ, tuple(q3) in occ
                    f = AO[0 if (o1 and o2) else 3 - (o1 + o2 + o3)]
                cols.append((c[0] * f, c[1] * f, c[2] * f, 1.0))
            fs.append((base, base + 1, base + 2, base + 3))
    m = bpy.data.meshes.new(name)
    m.from_pydata([tuple(v) for v in vs_], [], fs)
    at = m.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    at.data.foreach_set("color", [q for c in cols for q in c])
    mat = bpy.data.materials.new(name)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Col"
    nt.links.new(ca.outputs["Color"], bsdf.inputs["Base Color"])
    m.materials.append(mat)
    ob = bpy.data.objects.new(name, m)
    bpy.context.scene.collection.objects.link(ob)
    return ob


arme = build(CLS + "_weapon", vox, True)
parts = [arme]
if glow:
    g = build(CLS + "_weapon_glow", glow, False)
    g.parent = arme
    parts.append(g)
bpy.data.objects.remove(body, do_unlink=True)
for o in list(bpy.context.scene.objects):
    if o not in parts:
        bpy.data.objects.remove(o, do_unlink=True)
# origine sur la poignée : le centre de la section de l'arme à la hauteur de la poignée
if AXE == "z":
    gz = hi.z * GRIP
    sec = [v for v in verts if abs(v.z - gz) < VS * 2] or verts
    gp = Vector(((min(v.x for v in sec) + max(v.x for v in sec)) / 2, (min(v.y for v in sec) + max(v.y for v in sec)) / 2, gz))
else:  # couchée : section prise depuis la crosse (+Y), la poignée sous le fût
    gy = hi.y * (1 - GRIP)
    sec = [v for v in verts if abs(v.y - gy) < VS * 2] or verts
    gp = Vector(((min(v.x for v in sec) + max(v.x for v in sec)) / 2, gy, min(v.z for v in sec)))
for v in arme.data.vertices:
    v.co -= gp
if len(parts) > 1:
    for v in parts[1].data.vertices:
        v.co -= gp
for o in parts:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True)
print("ok", OUT, "poignée", tuple(round(x, 3) for x in gp))
