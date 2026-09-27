# Kit voxel de Delve, v2 : voxels de 1/16 m, murs par face exposée, joints en creux,
# monuments, colonnades, végétation plus fine, personnages à silhouette forte.
# Exécuté dans Blender via blender/mcp.py. Chaque asset -> assets/<nom>.glb
import bpy, random, math, os

OUT = r"G:\Mes APP\Delve\assets"
os.makedirs(OUT, exist_ok=True)
V = 1 / 16    # architecture : une case = 16 voxels, un niveau = 8
VT = 1 / 12   # arbres et buissons
VC = 1 / 16   # personnages (agrandis x1.35 dans Godot)


def lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def tone(c, f):
    return (c[0] * f, c[1] * f, c[2] * f)


def pal(hexes):
    return [lin(h) for h in hexes]


STONE = pal(["#bdb5a3", "#aea694", "#c6bea9", "#a39c8b", "#b6ae9a", "#c0b8a2"])
MORTAR = lin("#5d584e")
QUOIN = pal(["#cbc3ae", "#bcb4a0"])
GRIME = lin("#6e6858")
MOSS = pal(["#6f8a45", "#5b7a3b", "#88a052", "#4d6b35"])
ALGAE = pal(["#3f5a3a", "#4a6a40", "#35503a"])
SAND = pal(["#d8cfb0", "#cbbf9b", "#e0d8bd", "#bfb28c"])
AUTUMN = pal(["#b4501c", "#c8662a", "#8c3616", "#d98434", "#a4401a", "#e39a3e"])
GREEN = pal(["#4f7a2f", "#3d6427", "#6a8f3a", "#2f4f22", "#7da44a"])
TEAL = pal(["#2f8a7e", "#3aa396", "#237064", "#4fb8a8", "#1f5e56"])
ROOF = pal(["#6e4b3b", "#5b3c2f", "#7d5646", "#4a3027", "#86604c"])
WOOD = pal(["#5a4030", "#4a3426", "#654838"])
FLOWER = pal(["#c8301c", "#e04a2a", "#a82418", "#ee6a3a"])
EMBER = pal(["#ffb347", "#ff9a2e", "#ffd07a"])
NICHE = lin("#262b29")

FACES = {
    (1, 0, 0): [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)],
    (-1, 0, 0): [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)],
    (0, 1, 0): [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)],
    (0, -1, 0): [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)],
    (0, 0, 1): [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)],
    (0, 0, -1): [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)],
}
AO = [0.42, 0.62, 0.82, 1.0]


def material(name="DelveVC", glow=False):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Col"
    nt.links.new(ca.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    if glow:
        nt.links.new(ca.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 6.0
    return m


def coll(name="Delve_kit"):
    c = bpy.data.collections.get(name)
    if not c:
        c = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(c)
    return c


def mesh(name, vox, v, origin=(0, 0, 0), ao=True, skip=(), glow=False):
    """vox: {(x,y,z): rgb lin}. Faces exposées seulement ; skip = normales jamais vues."""
    verts, faces, cols = [], [], []
    for (x, y, z), c in vox.items():
        for n, corners in FACES.items():
            if n in skip or (x + n[0], y + n[1], z + n[2]) in vox:
                continue
            base = len(verts)
            a1, a2 = [i for i in range(3) if n[i] == 0]
            p = (x + n[0], y + n[1], z + n[2])
            for cr in corners:
                verts.append(((x + cr[0] - origin[0]) * v, (y + cr[1] - origin[1]) * v, (z + cr[2] - origin[2]) * v))
                f = 1.0
                if ao:
                    s1 = 1 if cr[a1] else -1
                    s2 = 1 if cr[a2] else -1
                    q1 = list(p); q1[a1] += s1
                    q2 = list(p); q2[a2] += s2
                    q3 = list(q1); q3[a2] += s2
                    o1, o2, o3 = tuple(q1) in vox, tuple(q2) in vox, tuple(q3) in vox
                    f = AO[0 if (o1 and o2) else 3 - (o1 + o2 + o3)]
                    if n[2] == -1:
                        f *= 0.78
                cols.append((c[0] * f, c[1] * f, c[2] * f, 1.0))
            faces.append((base, base + 1, base + 2, base + 3))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    attr.data.foreach_set("color", [k for c in cols for k in c])
    me.materials.append(material("DelveGlow", True) if glow else material())
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    ob = bpy.data.objects.new(name, me)
    coll().objects.link(ob)
    return ob


def mesh_merged(name, vox, v, ao=True, skip=(), glow=False):
    """Comme mesh(), mais les faces planes (quatre coins de même couleur) d'un même plan et d'une même couleur
    sont fusionnées en rectangles (greedy meshing). Même rendu, bien moins de sommets : indispensable au voxel fin."""
    verts, faces, cols = [], [], []
    planes = {}
    for (x, y, z), c in vox.items():
        for n, corners in FACES.items():
            if n in skip or (x + n[0], y + n[1], z + n[2]) in vox:
                continue
            a = 0 if n[0] else (1 if n[1] else 2)
            a1, a2 = [i for i in range(3) if i != a]
            p = (x + n[0], y + n[1], z + n[2])
            fs = []
            for cr in corners:
                f = 1.0
                if ao:
                    s1 = 1 if cr[a1] else -1
                    s2 = 1 if cr[a2] else -1
                    q1 = list(p); q1[a1] += s1
                    q2 = list(p); q2[a2] += s2
                    q3 = list(q1); q3[a2] += s2
                    o1, o2, o3 = tuple(q1) in vox, tuple(q2) in vox, tuple(q3) in vox
                    f = AO[0 if (o1 and o2) else 3 - (o1 + o2 + o3)]
                    if n[2] == -1:
                        f *= 0.78
                fs.append(f)
            xyz = (x, y, z)
            if fs[0] == fs[1] == fs[2] == fs[3]:
                key = (round(c[0] * fs[0], 4), round(c[1] * fs[0], 4), round(c[2] * fs[0], 4))
                planes.setdefault((n, xyz[a]), {})[(xyz[a1], xyz[a2])] = key
                continue
            base = len(verts)
            for cr, f in zip(corners, fs):
                verts.append(((x + cr[0]) * v, (y + cr[1]) * v, (z + cr[2]) * v))
                cols.append((c[0] * f, c[1] * f, c[2] * f, 1.0))
            faces.append((base, base + 1, base + 2, base + 3))
    for (n, k), cells in planes.items():
        a = 0 if n[0] else (1 if n[1] else 2)
        a1, a2 = [i for i in range(3) if i != a]
        corners = FACES[n]
        seen = set()
        for (u, w0) in sorted(cells, key=lambda t: (t[1], t[0])):
            if (u, w0) in seen:
                continue
            col = cells[(u, w0)]
            wu = 1
            while (u + wu, w0) in cells and (u + wu, w0) not in seen and cells[(u + wu, w0)] == col:
                wu += 1
            hv = 1
            while all((u + i, w0 + hv) in cells and (u + i, w0 + hv) not in seen and cells[(u + i, w0 + hv)] == col for i in range(wu)):
                hv += 1
            for i in range(wu):
                for j in range(hv):
                    seen.add((u + i, w0 + j))
            base = len(verts)
            for cr in corners:
                q = [0, 0, 0]
                q[a] = k + cr[a]
                q[a1] = u + cr[a1] * wu
                q[a2] = w0 + cr[a2] * hv
                verts.append((q[0] * v, q[1] * v, q[2] * v))
                cols.append((col[0], col[1], col[2], 1.0))
            faces.append((base, base + 1, base + 2, base + 3))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    attr.data.foreach_set("color", [q for c in cols for q in c])
    me.materials.append(material("DelveGlow", True) if glow else material())
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    ob = bpy.data.objects.new(name, me)
    coll().objects.link(ob)
    return ob


_slot = [0]
_slot = [0]


SUB = [""]


def export(name, objs):
    folder = os.path.join(OUT, "hd" if HD else "", SUB[0])
    os.makedirs(folder, exist_ok=True)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=os.path.join(folder, name + ".glb"), export_format="GLB",
                              use_selection=True, export_yup=True, export_apply=False)
    i = _slot[0]
    _slot[0] += 1
    off = ((i % 12) * 4.0, (i // 12) * 4.0 + 8.0, 0)
    for o in objs:
        if o.parent is None:
            o["delve_home"] = tuple(o.location)
            o.location = (o.location[0] + off[0], o.location[1] + off[1], o.location[2])


def pick(R, p, lo=0.9, hi=1.08):
    return tone(R.choice(p), R.uniform(lo, hi))


# ---------------------------------------------------------------- maçonnerie

def masonry(R, W, H, course=4, brick=8, streaks=0.16, moss_joints=0.12):
    """Motif de briques pour une face W x H : renvoie (couleur, joint?, brique) par (u, z).
    Longueurs de briques variées par rangée, coulures verticales, crasse vers le bas."""
    tones = {}
    streak = {u: R.uniform(0.78, 0.9) for u in range(W) if R.random() < streaks}
    out = {}
    for row in range(0, (H + course - 1) // course):
        cuts = set()
        u = -R.randint(0, brick - 1)
        while u < W:
            cuts.add(u)
            u += R.randint(max(3, brick // 2), brick)
        start = 0
        for u in range(W):
            if u in cuts:
                start = u
            bid = (row, start)
            if bid not in tones:
                tones[bid] = pick(R, STONE, 0.84, 1.06)
            for z in range(row * course, min(H, (row + 1) * course)):
                c = tones[bid]
                if u in streak:
                    c = tone(c, streak[u] + (1 - streak[u]) * (z / max(H - 1, 1)))
                joint = z % course == 0 or u in cuts
                out[(u, z)] = (c, joint, bid)
    return out


def quoin(z):
    return QUOIN[(z // 4) % 2]


def wall(seed, kind="plain"):
    """Face de mur 16 x 2 x 8, face extérieure en y=0, intérieur vers +y (jamais vu)."""
    R = random.Random(seed)
    vox, glow = {}, {}
    W, H = 16, 8
    m = masonry(R, W, H)
    relief = {bid for (c, j, bid) in m.values() if R.random() < 0.06}
    for (u, z), (c, joint, bid) in m.items():
        corner = u < 2 or u > W - 3
        if corner:
            vox[(u, 0, z)] = vox[(u, 1, z)] = quoin(z)
            continue
        if joint:
            vox[(u, 1, z)] = pick(R, MOSS) if (z % 4 == 0 and R.random() < 0.12) else MORTAR
        else:
            edge = (u - 1, z) in m and m[(u - 1, z)][1] or (u + 1, z) in m and m[(u + 1, z)][1]
            if R.random() > (0.28 if edge else 0.03):
                vox[(u, 0, z)] = c
            vox[(u, 1, z)] = c
            if bid in relief:
                vox[(u, -1, z)] = tone(c, 1.03)
    if kind == "base":
        for u in range(W):
            for z in range(3):
                for y in (-1, 0):
                    if (u, y, z) in vox or y == -1:
                        vox[(u, y, z)] = pick(R, ALGAE, 0.8, 1.1) if R.random() < 0.55 else pick(R, STONE, 0.7, 0.85)
    if kind in ("cornice", "broken"):
        for u in range(W):
            vox[(u, -1, 7)] = pick(R, STONE, 1.04, 1.1)
            vox[(u, -2, 7)] = pick(R, STONE, 1.0, 1.06)
            vox[(u, -1, 6)] = pick(R, STONE, 0.95, 1.0)
            if R.random() < 0.25:
                vox[(u, -1, 8)] = pick(R, MOSS)
    if kind == "broken":
        cut = R.randint(4, 12)
        for u in range(cut, W):
            top = R.randint(2, 6)
            for z in range(top, 9):
                for y in (-2, -1, 0, 1):
                    vox.pop((u, y, z), None)
    if kind in ("window", "windowglow"):
        for u in range(6, 10):
            for z in range(1, 8):
                if z == 7 and u in (6, 9):
                    continue
                vox.pop((u, 0, z), None)
                vox.pop((u, 1, z), None)
                back = (u, 3, z)
                if kind == "windowglow":
                    glow[back] = R.choice(EMBER)
                else:
                    vox[back] = NICHE
                vox[(u, 2, z)] = NICHE if kind == "window" else tone(R.choice(EMBER), 0.5)
        for z in range(0, 8):
            vox[(5, -1, z)] = vox[(10, -1, z)] = pick(R, STONE, 1.03, 1.1)
        for u in range(5, 11):
            vox[(u, -1, 0)] = pick(R, STONE, 1.0, 1.08)
    if kind == "pilaster":
        for z in range(8):
            for u in (2, 3, 12, 13):
                vox[(u, -1, z)] = pick(R, STONE, 1.02, 1.1)
    return vox, glow


def arcade(seed):
    """Face de mur sur deux niveaux (16 x 2 x 16) percée d'une arche aveugle profonde."""
    R = random.Random(seed)
    vox = {}
    m = masonry(R, 16, 16)
    for (u, z), (c, joint, bid) in m.items():
        du = u - 7.5
        inside = abs(du) < 5 and (z < 9 or (z - 9) ** 2 + du * du < 25)
        ring = not inside and abs(du) < 7 and (z >= 9 and (z - 9) ** 2 + du * du < 49)
        if inside:
            for y in (2, 3, 4):
                vox[(u, y, z)] = tone(NICHE, 0.8 + 0.1 * (4 - y))
            continue
        if u < 2 or u > 13:
            vox[(u, 0, z)] = vox[(u, 1, z)] = quoin(z)
            continue
        if ring:
            vox[(u, -1, z)] = pick(R, STONE, 1.05, 1.14) if int(math.atan2(z - 9, du) * 4) % 2 else pick(R, STONE, 0.92, 1.0)
        if joint and not ring:
            vox[(u, 1, z)] = MORTAR
        else:
            vox[(u, 0, z)] = c
            vox[(u, 1, z)] = c
    for u in range(16):
        for z in range(3):
            if (u, 0, z) in vox and R.random() < 0.5:
                vox[(u, 0, z)] = pick(R, ALGAE)
    for u in range(3, 13):
        vox[(u, 5, 0)] = pick(R, ALGAE, 0.6, 0.8)
    return vox


def ashlar(seed, kind="plain"):
    """Face 16 x 2 x 8 en gros blocs (0,5 x 0,5 m) chanfreinés, fissurés, patinés vers le bas."""
    R = random.Random(seed)
    vox = {}
    split = R.choice((8, 6, 10))
    for (u0, u1) in ((0, split), (split, 16)):
        c = pick(R, STONE, 0.8, 1.1)
        crack = R.random() < 0.45
        cu = R.randint(u0 + 2, u1 - 3)
        for u in range(u0, u1):
            for z in range(8):
                edge_u = u in (u0, u1 - 1)
                edge_z = z in (0, 7)
                grime = 1.0 - 0.18 * (1 - z / 7)
                col = tone(c, grime * R.uniform(0.95, 1.05))
                if edge_u and edge_z:
                    vox[(u, 1, z)] = tone(col, 0.8)
                    continue
                if (edge_u or edge_z) and R.random() < 0.5:
                    vox[(u, 1, z)] = tone(col, 0.85)
                    continue
                if crack and abs(u - cu - (z % 3 == 0)) < 1 and 1 <= z <= 6:
                    vox[(u, 1, z)] = tone(col, 0.5)
                    continue
                if z == 7 and R.random() < 0.18:
                    vox[(u, 0, z)] = pick(R, MOSS)
                else:
                    vox[(u, 0, z)] = col
                vox[(u, 1, z)] = col
    if kind == "base":
        for u in range(16):
            for z in range(3):
                vox[(u, 0, z)] = pick(R, ALGAE, 0.75, 1.05) if R.random() < 0.6 else tone(vox.get((u, 1, z), STONE[0]), 0.7)
    if kind == "cornice":
        for u in range(16):
            vox[(u, -1, 7)] = pick(R, STONE, 1.04, 1.12)
            vox[(u, -2, 7)] = pick(R, STONE, 1.0, 1.06)
            vox[(u, -1, 6)] = pick(R, STONE, 0.9, 0.98)
            if R.random() < 0.3:
                vox[(u, -1, 8)] = pick(R, MOSS)
    return vox, {}


def lintel(seed):
    """Architrave de 2 m posée sur deux colonnes, bord parfois cassé."""
    R = random.Random(seed)
    vox = {}
    cut = R.choice((0, 0, R.randint(20, 30)))
    for x in range(32):
        if cut and x > cut:
            continue
        for y in range(5, 11):
            for z in range(5):
                c = pick(R, STONE, 0.95, 1.1)
                if z == 4 and R.random() < 0.2:
                    c = pick(R, MOSS)
                if z == 0 and x % 8 == 0:
                    c = tone(c, 0.75)
                vox[(x, y, z)] = c
    return vox


def chest(seed):
    R = random.Random(seed)
    vox = {}
    WOODC, GOLDC = pal(["#6b4a30", "#5a3d27", "#7a5638"]), lin("#e2b24e")
    for x in range(2, 14):
        for y in range(4, 12):
            for z in range(0, 9):
                if z >= 6 and (y - 8) ** 2 / 16 + (z - 5) ** 2 / 16 > 1.0:
                    continue
                band = x in (3, 12) or z == 5
                vox[(x, y, z)] = GOLDC if band else pick(R, WOODC)
    vox[(8, 3, 5)] = vox[(7, 3, 5)] = GOLDC
    vox[(8, 3, 4)] = vox[(7, 3, 4)] = lin("#2a1c10")
    return vox


def brazier(seed):
    R = random.Random(seed)
    vox, glow = {}, {}
    IRON = pal(["#3a3836", "#2e2c2a", "#46423d"])
    for s in ((4, 4), (11, 4), (4, 11), (11, 11)):
        for z in range(0, 6):
            vox[(s[0], s[1], z)] = pick(R, IRON)
    for x in range(2, 14):
        for y in range(2, 14):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 6.2:
                vox[(x, y, 6)] = pick(R, IRON)
                if d > 5.0:
                    vox[(x, y, 7)] = vox[(x, y, 8)] = pick(R, IRON)
                else:
                    glow[(x, y, 7)] = R.choice(EMBER)
                    if d < 3.5 and R.random() < 0.6:
                        glow[(x, y, 8)] = R.choice(EMBER)
    return vox, glow


def rack(seed):
    """Râtelier-forge : socle de pierre rond, puits de braise au centre, épées plantées de biais et chaînes qui pendent."""
    R = random.Random(seed)
    vox, glow = {}, {}
    STEEL, RUST, GRIP = pal(["#b9c2c7", "#a3adb3", "#cfd6da"]), pal(["#7a5a44", "#6a4a36"]), pal(["#5a3d27", "#4a3220"])
    CHAIN = pal(["#4a4a50", "#5a5a60", "#3c3c42"])
    for x in range(0, 16):
        for y in range(0, 16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 7.4:
                for z in range(0, 3 if d < 6.6 else 2):
                    vox[(x, y, z)] = pick(R, STONE, 0.8, 1.05)
                if d < 2.2:
                    glow[(x, y, 2)] = R.choice(EMBER)
                elif d < 3.0:
                    vox[(x, y, 3)] = pick(R, STONE, 0.9, 1.1)
    def blade(x0, y0, dx, dy, n):
        # lame plantée : pointe dans le socle, garde et poignée en haut, penchée de (dx, dy) par étage
        for z in range(2, 2 + n):
            k = z - 2
            x, y = int(round(x0 + dx * k)), int(round(y0 + dy * k))
            top = n - 5
            if k < top:
                for w in (0, 1):
                    vox[(x + w, y, z)] = pick(R, STEEL)
                    vox[(x + w, y + 1, z)] = pick(R, STEEL, 0.8, 0.95)
            elif k == top:
                for w in range(-2, 4):
                    vox[(x + w, y, z)] = pick(R, RUST)
            else:
                vox[(x, y, z)] = pick(R, GRIP)
        x, y = int(round(x0 + dx * (n - 1))), int(round(y0 + dy * (n - 1)))
        vox[(x, y, 2 + n)] = pick(R, RUST)
    for (px, py, ph) in ((6, 10, 4), (10, 6, 5), (9, 10, 3)):  # blocs de braise, comme sortis de la forge
        for z in range(3, 3 + ph):
            glow[(px, py, z)] = glow[(px + 1, py, z)] = R.choice(EMBER)
    blade(3, 4, 0.0, 0.0, 17)
    blade(11, 3, 0.12, -0.05, 14)
    blade(12, 11, 0.1, 0.1, 12)
    blade(4, 12, -0.1, 0.08, 10)
    for i in range(9):  # chaîne qui pend d'une garde jusqu'au sol
        x, y, z = 5 + i // 2, 5 + i // 3, 14 - int(i * 1.4)
        if z > 2:
            vox[(x, y, z)] = pick(R, CHAIN)
            if i % 2 == 0:
                vox[(x, y + 1, z)] = pick(R, CHAIN)
    return vox, glow


def vasque(seed):
    """Vasque : pied de pierre, large coupe, eau vive qui luit."""
    R = random.Random(seed)
    vox, glow = {}, {}
    WATER = pal(["#5fe0cf", "#4ad0c0", "#7af0de"])
    for x in range(0, 16):
        for y in range(0, 16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 3.2:
                for z in range(0, 6):
                    vox[(x, y, z)] = pick(R, STONE, 0.85, 1.05)
            if d < 6.8:
                vox[(x, y, 6)] = pick(R, STONE, 0.85, 1.05)
                if d > 5.6:
                    vox[(x, y, 7)] = vox[(x, y, 8)] = pick(R, STONE, 0.9, 1.1)
                else:
                    glow[(x, y, 7)] = R.choice(WATER)
            if 3.0 < d < 4.2:
                vox[(x, y, 0)] = pick(R, STONE, 0.8, 1.0)
    return vox, glow


def bell(seed):
    """Cloche d'alarme : portique de bois, cloche de bronze, marteau posé."""
    R = random.Random(seed)
    vox = {}
    BRONZE, WOODC = pal(["#c9913e", "#b07a2e", "#dca552"]), pal(["#6b4a30", "#5a3d27", "#7a5638"])
    for x in (2, 13):
        for y in (7, 8):
            for z in range(0, 17):
                vox[(x, y, z)] = pick(R, WOODC)
        for y in range(4, 12):
            vox[(x, y, 0)] = pick(R, WOODC)
    for x in range(1, 15):
        for y in (7, 8):
            vox[(x, y, 17)] = pick(R, WOODC)
    PROF = {15: 2.2, 14: 2.9, 13: 3.1, 12: 3.1, 11: 3.2, 10: 3.3, 9: 3.5, 8: 3.9, 7: 4.6, 6: 4.9}  # cloche : dôme, taille, lèvre évasée
    for z, r in PROF.items():
        for x in range(0, 16):
            for y in range(0, 16):
                d = math.hypot(x - 7.5, y - 7.5)
                if d < r and (d > r - 1.2 or z >= 14):
                    vox[(x, y, z)] = lin("#e6b865") if z in (6, 11) else pick(R, BRONZE)
    vox[(7, 7, 16)] = vox[(8, 8, 16)] = pick(R, BRONZE)
    for z in range(4, 7):
        vox[(7, 8, z)] = lin("#3a2a1c")
    return vox


def lever(seed):
    R = random.Random(seed)
    vox = {}
    for x in range(4, 12):
        for y in range(5, 11):
            for z in range(0, 4):
                vox[(x, y, z)] = pick(R, STONE, 0.85, 1.0)
    for i in range(12):
        vox[(8 + i // 3, 8, 4 + i)] = pick(R, WOOD)
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            vox[(12 + dx, 8, 16 + dz)] = lin("#e2b24e")
    return vox


def cracked_pillar(seed):
    R = random.Random(seed)
    vox = {}
    H = 32
    for z in range(H):
        for x in range(4, 12):
            for y in range(4, 12):
                if z < 3 or 5 <= x <= 10 and 5 <= y <= 10:
                    top_cut = H - (x + y) % 5
                    if z > top_cut:
                        continue
                    c = pick(R, STONE, 0.9, 1.05)
                    if abs(x - 7 - (z // 5) % 3) < 1 and y == 4 + 1:
                        c = tone(c, 0.4)
                    vox[(x, y, z)] = c
    for z in range(4, H - 4):
        vox[(7 + (z // 4) % 2, 5, z)] = tone(STONE[0], 0.35)
    return vox


PALETTES = {
    "pierre": (None, None, None),
    "brique": (["#a4523b", "#b5603f", "#94462f", "#c06a48", "#8a3f2c", "#ad5a40"], "#4e3228", ["#c98a66", "#b87a58"]),
    "blanc": (["#ebe6d9", "#dfd9c9", "#f2eee3", "#d6cfbd", "#e5dfcf", "#faf6ec"], "#9d968a", ["#f6f3ea", "#e9e4d6"]),
    "lilas": (["#a89cc0", "#9a8db4", "#b6abcc", "#8d80a8", "#a293bb", "#bfb4d4"], "#5a4f72", ["#e3c46a", "#cfae52"]),
    "terre": (["#7a5a4a", "#6b4d40", "#86665a", "#5e4238", "#73574a", "#8f6f5e"], "#3a2922", ["#8d6f60", "#7d6153"]),
    "crypte": (["#8e4a58", "#a0566a", "#7a3e4e", "#b0667a", "#6e3646", "#9a5264"], "#2e1c2a", ["#4f8c88", "#5d9c96"]),
    "jade": (["#5d8c6c", "#6c9c7a", "#4c7a5c", "#7aac88", "#548463", "#86b894"], "#223a2e", ["#c9b86a", "#b8a458"]),
    "quartz": (["#b48c9c", "#a27a8c", "#c49eac", "#8f6a7e", "#bb95a4", "#d0b0bc"], "#4a3040", ["#e8d8e8", "#d8c4dc"]),
}
GRASS = pal(["#b9b24a", "#a7a23e", "#c9c35a", "#8f9a3a", "#d6cc6a"])
PINK = pal(["#e0418c", "#f06aa8", "#c93278", "#f59ac4"])
CRYSTAL = pal(["#5fd6c8", "#7ae0e8", "#4a9fd8", "#9ff0d8"])


def grass_top(seed):
    R = random.Random(seed)
    vox = {}
    for x in range(16):
        for y in range(16):
            vox[(x, y, 0)] = pick(R, pal(["#6b5a3a", "#5e4f33"]))
            vox[(x, y, 1)] = pick(R, GRASS, 0.85, 1.1)
            if R.random() < 0.18:
                for z in range(2, 2 + R.randint(1, 3)):
                    vox[(x, y, z)] = pick(R, GRASS, 0.9, 1.25)
    return vox


def fireweed(seed):
    R = random.Random(seed)
    vox = {}
    for _ in range(26):
        x, y = R.randint(0, 15), R.randint(0, 15)
        hh = R.randint(4, 10)
        for z in range(hh):
            vox[(x, y, z)] = pick(R, GREEN) if z < hh - 3 else pick(R, PINK)
    return vox


def tufts(seed):
    R = random.Random(seed)
    vox = {}
    for _ in range(14):
        cx, cy = R.randint(1, 14), R.randint(1, 14)
        for _ in range(5):
            x, y = cx + R.randint(-1, 1), cy + R.randint(-1, 1)
            for z in range(R.randint(1, 4)):
                vox[(x, y, z)] = pick(R, GRASS, 0.9, 1.2)
    return vox


def statue(seed, big=False):
    """Figure drapée à auréole dorée sur socle (sanctuaire lilas)."""
    R = random.Random(seed)
    vox, glow = {}, {}
    k = 2 if big else 1
    GOLDS = pal(["#e8c664", "#f4d880", "#d4ad4c"])
    for x in range(2 * k, 14 * k):
        for y in range(2 * k, 14 * k):
            for z in range(0, 6 * k):
                vox[(x, y, z)] = pick(R, STONE, 0.9, 1.05) if z < 5 * k else pick(R, GOLDS)
    cx, cy = 8 * k, 8 * k
    for z in range(6 * k, 40 * k):
        t = (z - 6 * k) / (34 * k)
        r = (5.5 - 2.5 * t) * k if t < 0.8 else 2.2 * k
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            for y in range(int(cy - r * 0.7) - 1, int(cy + r * 0.7) + 2):
                if ((x - cx) / r) ** 2 + ((y - cy) / (r * 0.7)) ** 2 <= 1:
                    fold = (x + z // (2 * k)) % 3 == 0
                    vox[(x, y, z)] = pick(R, GOLDS) if (t > 0.8 and R.random() < 0.3) else pick(R, STONE, 0.85 if fold else 1.0, 1.08)
    for a in range(60 * k):
        t = a / (60 * k) * math.tau
        glow[(int(cx + math.cos(t) * 5 * k), cy + 3 * k, int(44 * k + math.sin(t) * 5 * k))] = R.choice(GOLDS)
    return vox, glow


def crystal(seed, big=False):
    """Amas de prismes hexagonaux sur un socle de roche : facettes claires / sombres, veine et pointe lumineuses."""
    R = random.Random(seed)
    vox, glow = {}, {}
    k = 3 if big else 1
    ROCK = pal(["#5a5560", "#4a4650", "#66616c"])
    for x in range(-5 * k, 5 * k + 1):
        for y in range(-5 * k, 5 * k + 1):
            d = math.hypot(x, y)
            for z in range(int(max(0, 3 * k - d * 0.5))):
                if d < 5 * k:
                    vox[(x + 8, y + 8, z)] = pick(R, ROCK)
    for i in range(3 if big else R.randint(2, 3)):
        ang, ang2 = R.uniform(-0.35, 0.35), R.uniform(-0.35, 0.35)
        L = (R.randint(26, 38) if i == 0 else R.randint(14, 24)) * k
        w = (3.2 if i == 0 else 2.2) * k
        bx, by = R.randint(-2, 2) * k, R.randint(-2, 2) * k
        for z in range(L):
            tip = max(0.0, (z - (L - w * 1.8)) / (w * 1.8))
            r = w * (1 - tip)
            if r < 0.5:
                continue
            px, py = bx + ang * z, by + ang2 * z
            for x in range(int(px - r) - 1, int(px + r) + 2):
                for y in range(int(py - r) - 1, int(py + r) + 2):
                    dx, dy = x - px, y - py
                    hexd = max(abs(dx), abs(dx) * 0.5 + abs(dy) * 0.866)
                    if hexd > r:
                        continue
                    edge = hexd > r - 1.0
                    if edge and abs(dx) < 0.7:
                        glow[(x + 8, y + 8, z)] = R.choice(CRYSTAL)
                    elif tip > 0.75:
                        glow[(x + 8, y + 8, z)] = R.choice(CRYSTAL)
                    else:
                        f = 0.8 if dx > r * 0.3 else (0.34 if dx < -r * 0.3 else 0.55)
                        vox[(x + 8, y + 8, z)] = tone(R.choice(CRYSTAL), f * R.uniform(0.95, 1.05))
    for q in glow:
        vox.pop(q, None)
    return vox, glow


def basin(seed):
    """Sommet de tour en bassin : margelle ronde et eau (tours de Yerka)."""
    R = random.Random(seed)
    vox = {}
    WATERC = pal(["#6fb7c0", "#7cc4c9", "#5da9b3"])
    for x in range(-2, 18):
        for y in range(-2, 18):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 9.8:
                if d > 8.4:
                    for z in range(0, 5):
                        vox[(x, y, z)] = pick(R, STONE, 0.9, 1.08)
                    if R.random() < 0.3:
                        vox[(x, y, 5)] = pick(R, GREEN)
                else:
                    vox[(x, y, 0)] = pick(R, STONE, 0.7, 0.8)
                    vox[(x, y, 3)] = pick(R, WATERC, 0.95, 1.05)
    return vox


def fallen_column(seed):
    R = random.Random(seed)
    vox = {}
    L = R.randint(24, 34)
    for x in range(L):
        for y in range(-3, 4):
            for z in range(0, 7):
                if (y) ** 2 + (z - 3) ** 2 <= 11:
                    c = pick(R, STONE, 0.92, 1.06)
                    if z >= 5 and R.random() < 0.35:
                        c = pick(R, MOSS)
                    if x % 9 == 0:
                        c = tone(c, 0.8)
                    vox[(x - L // 2 + 8, y + 8, z)] = c
    return vox


def pine(seed):
    R = random.Random(seed)
    vox = {}
    T = R.randint(30, 40)
    for z in range(T):
        vox[(0, 0, z)] = pick(R, WOOD)
        vox[(1, 0, z)] = pick(R, WOOD)
    for z in range(8, T + 3):
        r = (T + 3 - z) * 0.28 + 1
        for x in range(-int(r) - 1, int(r) + 2):
            for y in range(-int(r) - 1, int(r) + 2):
                if x * x + y * y <= r * r and R.random() > 0.15 and (z % 4 != 0 or x * x + y * y < (r * 0.5) ** 2):
                    vox[(x, y, z)] = tone(R.choice(GREEN), R.uniform(0.6, 0.95))
    return vox


def portal(seed):
    R = random.Random(seed)
    vox, glow = {}, {}
    for x in range(16):
        for y in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 7.8:
                vox[(x, y, 0)] = pick(R, STONE, 0.9, 1.05)
                if 5.2 < d < 6.6:
                    glow[(x, y, 1)] = (0.55, 0.9, 1.0)
    for a in range(48):
        t = a / 48 * math.pi
        glow[(int(7.5 + math.cos(t) * 6.5), 8, int(1 + math.sin(t) * 12))] = (0.6, 0.95, 1.0)
    for p in glow:
        vox.pop(p, None)
    return vox, glow


def top(seed, leaves=None):
    """Dalle 16 x 16 x 2 : pavés de 8, joints en creux moussus, fissures, éclats."""
    R = random.Random(seed)
    vox = {}
    stones = {}
    for x in range(16):
        for y in range(16):
            k = (x // 8, y // 8)
            if k not in stones:
                stones[k] = pick(R, STONE, 0.95, 1.14)
            c = stones[k]
            joint = x % 8 == 0 or y % 8 == 0
            vox[(x, y, 0)] = tone(c, 0.8)
            if joint:
                if R.random() < 0.3:
                    vox[(x, y, 1)] = pick(R, MOSS, 0.85, 1.05)
                continue
            vox[(x, y, 1)] = c
    for _ in range(2):
        x, y = R.randint(1, 14), R.randint(1, 14)
        for i in range(R.randint(4, 9)):
            if (x, y, 1) in vox:
                vox[(x, y, 1)] = tone(vox[(x, y, 1)], 0.72)
            x += R.choice((-1, 0, 1))
            y += R.choice((0, 1))
            x, y = max(0, min(15, x)), max(0, min(15, y))
    if leaves:
        for _ in range(8):
            vox[(R.randint(0, 15), R.randint(0, 15), 2)] = pick(R, leaves)
    return vox


def arch(seed):
    """Pile de pont 16 x 16 x 24 : tunnel le long de X, voussoirs, briques en creux."""
    R = random.Random(seed)
    vox = {}
    fm = {s: masonry(R, 16, 24) for s in (0, 15)}
    for x in range(16):
        for y in range(16):
            for z in range(24):
                dy = y - 7.5
                if 2 <= y <= 13 and (z < 10 or (z - 10) ** 2 + dy * dy < 36):
                    continue
                c = STONE[0]
                if x in (0, 15):
                    c, joint, _ = fm[x][(y, z)]
                    d = math.sqrt(dy * dy + (z - 10) ** 2)
                    if z >= 10 and 6 <= d < 8.6:
                        c = pick(R, STONE, 1.05, 1.12) if int(math.atan2(z - 10, dy) * 5) % 2 else pick(R, STONE, 0.92, 0.98)
                        joint = False
                    if joint:
                        vox[(1 if x == 0 else 14, y, z)] = MORTAR
                        continue
                if z < 3 and R.random() < 0.6:
                    c = pick(R, ALGAE)
                vox[(x, y, z)] = c
    for y in range(16):
        for x in (0, 15):
            vox[(x - 1 if x == 0 else x + 1, y, 16)] = pick(R, STONE, 1.03, 1.1)
    return vox


def rail(seed):
    R = random.Random(seed)
    vox = {}
    for u in range(16):
        for y in (0, 1):
            vox[(u, y, 0)] = pick(R, STONE, 0.95, 1.05)
            vox[(u, y, 7)] = pick(R, STONE, 1.03, 1.1)
        vox[(u, 0, 6)] = pick(R, STONE, 0.98, 1.05)
        if u % 3 == 1:
            for z in range(1, 6):
                vox[(u, 0, z)] = pick(R, STONE, 0.95, 1.05)
            vox[(u, 1, 3)] = vox[(u, -1, 3)] = pick(R, STONE, 0.95, 1.02)
    for z in range(8):
        for u in (0, 15):
            vox[(u, 0, z)] = vox[(u, 1, z)] = pick(R, STONE, 1.02, 1.08)
    return vox


def stairs(seed):
    """Marches vers l'eau : le haut (1 m) côté +y, descente vers y=0."""
    R = random.Random(seed)
    vox = {}
    for y in range(16):
        h = 2 + (y // 2) * 2
        for x in range(1, 15):
            for z in range(h):
                c = pick(R, STONE, 0.95, 1.08) if z == h - 1 else pick(R, STONE, 0.78, 0.92)
                if z < 5 and R.random() < 0.45:
                    c = pick(R, ALGAE)
                vox[(x, y, z)] = c
        for x in (0, 15):
            for z in range(min(16, h + 2)):
                vox[(x, y, z)] = pick(R, STONE, 0.9, 1.02)
    return vox


def seabed(seed):
    R = random.Random(seed)
    vox = {}
    for x in range(16):
        for y in range(16):
            c = pick(R, SAND, 0.85, 1.05)
            if R.random() < 0.08:
                c = pick(R, STONE, 0.7, 0.85)
            vox[(x, y, 0)] = c
            if R.random() < 0.05:
                vox[(x, y, 1)] = pick(R, ALGAE, 0.9, 1.2)
    return vox


def monument(seed):
    """Porte monumentale 3 cases x 1 case x 7 m, arc central, niches, sommet brisé."""
    R = random.Random(seed)
    W, D, H = 48, 16, 112
    vox = {}
    front = masonry(R, W, H, course=6, brick=10)
    side = masonry(R, D, H, course=6, brick=10)
    tops = [H - R.randint(0, 14) if 8 < x < 40 else H - R.randint(8, 30) for x in range(W)]
    for x in range(W):
        for y in range(D):
            for z in range(tops[x]):
                dx = x - 23.5
                if 12 <= x <= 35 and (z < 64 or (z - 64) ** 2 + dx * dx < 144):
                    continue
                if 4 <= y <= 11 and 3 <= x <= 8 and 30 <= z <= 52 and not (z > 49 and x in (3, 8)):
                    continue
                if 4 <= y <= 11 and 39 <= x <= 44 and 30 <= z <= 52 and not (z > 49 and x in (39, 44)):
                    continue
                outer = y in (0, D - 1) or x in (0, W - 1)
                c = STONE[0]
                if outer:
                    if y in (0, D - 1):
                        c, joint, _ = front[(x, z)]
                    else:
                        c, joint, _ = side[(y, z)]
                    d = math.sqrt(dx * dx + (z - 64) ** 2)
                    if z >= 64 and 12 <= d < 16 and 10 < x < 38:
                        c = pick(R, STONE, 1.05, 1.13) if int(math.atan2(z - 64, dx) * 7) % 2 else pick(R, STONE, 0.9, 0.97)
                        joint = False
                    if joint:
                        c = MORTAR
                    if z < 6 and R.random() < 0.6:
                        c = pick(R, ALGAE)
                    elif R.random() < 0.02:
                        c = pick(R, MOSS)
                vox[(x, y, z)] = c
    for x in range(W):
        for y in (-1, D):
            for z in (86, 87, 88):
                if z < tops[x]:
                    vox[(x, y, z)] = pick(R, STONE, 1.04, 1.12)
            if tops[x] > 20:
                vox[(x, y, 20)] = pick(R, STONE, 1.0, 1.08)
    return vox


def pillar(seed, broken=False):
    R = random.Random(seed)
    vox = {}
    H = 48 if not broken else R.randint(18, 36)
    for z in range(H):
        for x in range(4, 12):
            for y in range(4, 12):
                if z < 4 or (z > H - 5 and not broken):
                    vox[(x, y, z)] = pick(R, STONE, 1.0, 1.1)
                elif 5 <= x <= 10 and 5 <= y <= 10 and not ((x in (5, 10)) and (y in (5, 10))):
                    flute = (x + y) % 2 == 0 and (x in (5, 10) or y in (5, 10))
                    c = pick(R, STONE, 0.86, 0.94) if flute else pick(R, STONE, 0.96, 1.06)
                    if z < 8 and R.random() < 0.3:
                        c = pick(R, MOSS)
                    vox[(x, y, z)] = c
    for x in range(3, 13):
        for y in range(3, 13):
            vox[(x, y, 0)] = pick(R, STONE, 0.92, 1.0)
            if not broken:
                vox[(x, y, H)] = pick(R, STONE, 1.02, 1.1)
    if broken:
        for x in range(5, 11):
            for y in range(5, 11):
                for z in range(H, H + R.randint(0, 4)):
                    vox[(x, y, z)] = pick(R, STONE, 0.9, 1.05)
    return vox


def crown(seed):
    """Parapet brisé au sommet des tours."""
    R = random.Random(seed)
    vox = {}
    for x in range(16):
        for y in range(16):
            ring = x < 2 or x > 13 or y < 2 or y > 13
            if not ring:
                continue
            u = x + y
            hgt = int(6 * (0.5 + 0.5 * math.sin(u * 0.45 + seed))) + R.randint(0, 3)
            if R.random() < 0.25:
                hgt = R.randint(0, 1)
            for z in range(hgt):
                vox[(x, y, z)] = pick(R, STONE, 0.92, 1.08) if R.random() > 0.08 else pick(R, MOSS)
    return vox


def blob(R, vox, cx, cy, cz, r, palette, hole=0.12, flat=1.0):
    ri = int(r) + 1
    for x in range(-ri, ri + 1):
        for y in range(-ri, ri + 1):
            for z in range(-ri, ri + 1):
                d = math.sqrt(x * x + y * y + (z / flat) ** 2)
                if d < r * R.uniform(0.8, 1.06) and R.random() > hole:
                    lift = 1.0 + 0.14 * (z / max(r, 1))
                    vox[(cx + x, cy + y, cz + z)] = tone(R.choice(palette), R.uniform(0.82, 1.1) * lift)


def tree(seed, leaves, size=1.0):
    R = random.Random(seed)
    vox = {}
    T = int(R.randint(26, 32) * size)
    x = y = 0.0
    lean = (R.uniform(-0.2, 0.2), R.uniform(-0.2, 0.2))
    for z in range(T):
        th = 3 if z < T * 0.3 else (2 if z < T * 0.7 else 1)
        for dx in range(th):
            for dy in range(th):
                vox[(int(x) + dx, int(y) + dy, z)] = pick(R, WOOD)
        x += lean[0]
        y += lean[1]
    ends = [(int(x), int(y), T)]
    for b in range(R.randint(3, 5)):
        z0 = R.randint(int(T * 0.45), T - 3)
        a = R.uniform(0, math.tau)
        L = int(R.randint(6, 11) * size)
        bx, by = x * 0.5, y * 0.5
        for i in range(L):
            bx += math.cos(a)
            by += math.sin(a)
            vox[(int(bx), int(by), z0 + i // 2)] = pick(R, WOOD)
        ends.append((int(bx), int(by), z0 + L // 2))
    for (ex, ey, ez) in ends:
        blob(R, vox, ex, ey, ez + 1, R.uniform(5.5, 8.0) * size, leaves, hole=0.22, flat=0.62)
        for _ in range(3):
            blob(R, vox, ex + R.randint(-6, 6), ey + R.randint(-6, 6), ez - R.randint(0, 4),
                 R.uniform(3.0, 5.0) * size, leaves, hole=0.3, flat=0.55)
    return vox


def bush(seed, leaves):
    R = random.Random(seed)
    vox = {}
    blob(R, vox, 0, 0, 1, R.uniform(3.6, 4.6), leaves, hole=0.1, flat=0.7)
    return {k: c for k, c in vox.items() if k[2] >= 0}


def ivy(seed, leaves):
    R = random.Random(seed)
    vox = {}
    for u in range(16):
        L = R.randint(4, 40) if R.random() < 0.8 else 0
        for z in range(L):
            if R.random() < 0.8:
                pal_ = leaves if (z > L - 5 or R.random() < 0.25) else GREEN
                vox[(u, -1, -z)] = tone(R.choice(pal_), R.uniform(0.7, 1.05) * (1 - z / 70))
            if R.random() < 0.25:
                vox[(u, -2, -z)] = tone(R.choice(leaves), R.uniform(0.8, 1.1))
    return vox


def lily(seed):
    R = random.Random(seed)
    vox = {}
    for _ in range(R.randint(4, 7)):
        cx, cy, r = R.randint(1, 14), R.randint(1, 14), R.uniform(2.2, 4.5)
        c = pick(R, GREEN, 0.95, 1.25)
        for x in range(-5, 6):
            for y in range(-5, 6):
                if x * x + y * y < r * r and not (x > 0 and abs(y) < 1):
                    vox[(cx + x, cy + y, 0)] = tone(c, R.uniform(0.9, 1.05))
        if R.random() < 0.45:
            pc = lin("#f4dcd6") if R.random() < 0.6 else lin("#ee9ab4")
            for d in ((0, 0, 1), (1, 0, 1), (0, 1, 1), (-1, 0, 1), (0, -1, 1), (0, 0, 2)):
                vox[(cx + d[0], cy + d[1], d[2])] = pc
            vox[(cx, cy, 2)] = lin("#f2d060")
    return vox


def scatter(seed, palette, n, h=0, edges=False):
    R = random.Random(seed)
    out = {}
    for _ in range(n):
        x, y = R.randint(0, 15), R.randint(0, 15)
        if edges:
            side = R.randint(0, 3)
            d = int(abs(R.gauss(0, 1.3)))
            x, y = [(d, y), (15 - d, y), (x, d), (x, 15 - d)][side]
            x, y = max(0, min(15, x)), max(0, min(15, y))
        out[(x, y, h)] = pick(R, palette)
    return out


def pile(seed, leaves):
    """Amas de feuilles poussé dans un coin de la case."""
    R = random.Random(seed)
    vox = {}
    for x in range(8):
        for y in range(8):
            d = math.hypot(x, y)
            if d < 6.5 * R.uniform(0.7, 1.1):
                vox[(x, y, 0)] = pick(R, leaves)
                if d < 3.2 and R.random() < 0.7:
                    vox[(x, y, 1)] = pick(R, leaves, 1.0, 1.15)
    return vox


def flowers(seed):
    R = random.Random(seed)
    vox = {}
    for _ in range(40):
        x, y = R.randint(0, 15), R.randint(0, 15)
        hh = R.randint(1, 4)
        for z in range(hh):
            vox[(x, y, z)] = pick(R, GREEN)
        vox[(x, y, hh)] = pick(R, FLOWER)
    return vox


def rubble(seed):
    R = random.Random(seed)
    vox = {}
    for _ in range(5):
        cx, cy = R.randint(2, 12), R.randint(2, 12)
        sx, sy, sz = R.randint(2, 4), R.randint(2, 3), R.randint(1, 3)
        for x in range(sx):
            for y in range(sy):
                for z in range(sz):
                    vox[(cx + x, cy + y, z)] = pick(R, STONE, 0.82, 1.02)
    return vox


def lantern(seed):
    R = random.Random(seed)
    vox, glow = {}, {}
    for z in range(10):
        for x in (7, 8):
            for y in (7, 8):
                vox[(x, y, z)] = pick(R, STONE, 0.85, 1.0)
    for x in range(5, 11):
        for y in range(5, 11):
            vox[(x, y, 10)] = pick(R, STONE)
            vox[(x, y, 16)] = pick(R, STONE, 1.0, 1.1)
            if x in (5, 10) and y in (5, 10):
                for z in range(11, 16):
                    vox[(x, y, z)] = pick(R, STONE)
    for x in range(6, 10):
        for y in range(6, 10):
            vox[(x, y, 17)] = pick(R, STONE)
    for x in range(6, 10):
        for y in range(6, 10):
            for z in range(11, 15):
                glow[(x, y, z)] = R.choice(EMBER)
    return vox, glow


# ---------------------------------------------------------------- run

def stone_kit(kit, WALL, FLAT):
    for kind, n in (("plain", 2), ("base", 1), ("cornice", 1), ("window", 1), ("windowglow", 1), ("pilaster", 1), ("broken", 2)):
        for i in range(n):
            vox, g = wall(1000 + sum(map(ord, kind)) + i * 13, kind)
            kit.append(("wall_%s_%d" % (kind, i), vox, g, WALL))
    for kind, n in (("plain", 5), ("base", 3), ("cornice", 3)):
        for i in range(n):
            vox, g = ashlar(2000 + sum(map(ord, kind)) + i * 17, kind)
            kit.append(("ashlar_%s_%d" % (kind, i), vox, g, WALL))
    for i in range(2):
        kit.append(("wall_arcade_%d" % i, arcade(1500 + i), None, WALL))
    for i in range(3):
        kit.append(("top_%d" % i, top(300 + i), None, FLAT))
    for i in range(2):
        kit.append(("arch_%d" % i, arch(200 + i), None, dict(origin=(8, 8, 0), skip=((0, 0, -1),))))
    kit.append(("rail", rail(400), None, dict(origin=(8, 8, 0), skip=((0, 0, -1),))))
    kit.append(("stairs", stairs(410), None, FLAT))
    kit.append(("monument", monument(600), None, dict(origin=(24, 8, 0), skip=((0, 0, -1),))))
    kit.append(("pillar_0", pillar(610), None, FLAT))
    kit.append(("pillar_1", pillar(611, True), None, FLAT))
    kit.append(("crown_0", crown(620), None, FLAT))
    kit.append(("crown_1", crown(621), None, FLAT))
    kit.append(("lintel", lintel(630), None, dict(origin=(16, 8, 0), skip=((0, 0, -1),))))
    kit.append(("basin", basin(640), None, FLAT))
    kit.append(("column_fallen", fallen_column(650), None, FLAT))
    vox, g = statue(660)
    kit.append(("statue", vox, g, FLAT))
    vox, g = statue(661, True)
    kit.append(("statue_giant", vox, g, dict(origin=(16, 16, 0), skip=((0, 0, -1),))))



def barrel(seed):
    """Baril de poudre de l'Artificier : douves, cerclages de fer, mèche et braise au couvercle."""
    R = random.Random(seed)
    vox, glow = {}, {}
    STAVE = pal(["#7a4e2c", "#6a4226", "#83573a"])
    IRON = pal(["#3a3836", "#2e2c2a"])
    for z in range(0, 12):
        r = 4.6 + 0.5 * math.sin(z / 11 * math.pi)
        for x in range(16):
            for y in range(16):
                d = math.hypot(x - 7.5, y - 7.5)
                if d < r:
                    band = z in (2, 9)
                    vox[(x, y, z)] = pick(R, IRON) if band else (pick(R, STAVE) if (x + y) % 3 else tone(pick(R, STAVE), 0.85))
    for x in range(5, 11):
        for y in range(5, 11):
            if math.hypot(x - 7.5, y - 7.5) < 2.2:
                glow[(x, y, 12)] = R.choice(EMBER)
    for i in range(4):
        vox[(8, 8 + i // 2, 12 + i)] = lin("#2a1c10")
    glow[(8, 10, 16)] = EMBER[2]
    return vox, glow


def turret(seed):
    """Tourelle : socle de pierre, fût de cuivre, arbalète à cœur sarcelle."""
    R = random.Random(seed)
    vox, glow = {}, {}
    COP = pal(["#b87333", "#9a5f2a", "#c98a4a"])
    for x in range(3, 13):
        for y in range(3, 13):
            for z in range(0, 3):
                vox[(x, y, z)] = pick(R, STONE, 0.85, 1.0)
    for z in range(3, 11):
        for x in range(6, 10):
            for y in range(6, 10):
                vox[(x, y, z)] = pick(R, COP)
    for x in range(4, 12):
        for y in range(5, 11):
            for z in range(11, 14):
                vox[(x, y, z)] = pick(R, COP)
    for x in range(1, 15):
        vox[(x, 4, 13)] = lin("#5a4030")
        vox[(x, 4, 12)] = lin("#5a4030") if x in (1, 14) else vox.get((x, 4, 12), lin("#5a4030"))
    for y in range(-2, 5):
        vox[(8, y, 12)] = lin("#e8e2cc")
    for x in range(7, 10):
        for z in range(11, 14):
            glow[(x, 11, z)] = lin("#5ff0dc")
    return vox, glow


def jaw_trap(seed):
    """Piège à mâchoires : anneau de fer à dents, plaque de détente."""
    R = random.Random(seed)
    vox = {}
    IRON = pal(["#4a4642", "#3a3734", "#5a554f"])
    for x in range(16):
        for y in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if 4.2 < d < 6.2:
                vox[(x, y, 0)] = pick(R, IRON)
                if d > 5.2 and (x + y) % 2 == 0:
                    vox[(x, y, 1)] = lin("#c9c2b4")
            elif d < 1.8:
                vox[(x, y, 0)] = lin("#7a5a2a")
    for x in range(2, 14):
        vox[(x, 7, 0)] = pick(R, IRON)
    return vox

HD = int(os.environ.get("DELVE_HD", "0"))  # 3 : chaque voxel devient 3x3x3 grains -> assets/hd/ (PC ultra seulement)


def hd(vox, seed, F, chip=True):
    """Voxel fin : subdivise, écaille les arêtes vives, piquette les faces, varie la teinte grain par grain."""
    R = random.Random(seed)
    out = {}
    for (x, y, z), c in vox.items():
        ex = [n for n in FACES if (x + n[0], y + n[1], z + n[2]) not in vox]
        for i in range(F):
            for j in range(F):
                for k in range(F):
                    loc = (i, j, k)
                    on = sum(1 for n in ex if any(n[a] and loc[a] == (F - 1 if n[a] > 0 else 0) for a in range(3)))
                    if chip and on >= 2 and R.random() < 0.5:
                        continue
                    if chip and on == 1 and R.random() < 0.06:
                        continue
                    out[(x * F + i, y * F + j, z * F + k)] = tone(c, R.uniform(0.9, 1.07)) if chip else c
    return out


def emit(kit):
    for name, vox, glow, opt in kit:
        v = opt.get("v", V)
        origin = opt.get("origin", (0, 0, 0))
        skip = opt.get("skip", ())
        if HD:
            vox = hd(vox, len(name), HD)
            glow = glow and hd(glow, 0, HD, chip=False)
            v, origin = v / HD, tuple(o * HD for o in origin)
        objs = [mesh(name, vox, v, origin=origin, skip=skip)]
        if glow:
            objs.append(mesh(name + "_glow", glow, v, origin=origin, ao=False, glow=True))
        export(name, objs)


def foliage_kit(kit, biome, leaves):
    FLAT = dict(origin=(8, 8, 0), skip=((0, 0, -1),))
    for i in range(3):
        kit.append(("tree_%s_%d" % (biome, i), tree(700 + i, leaves, 1.25 if i == 2 else 1.0), None, dict(v=VT)))
    kit.append(("tree_%s_small" % biome, tree(710, leaves, 0.6), None, dict(v=VT)))
    for i in range(2):
        kit.append(("bush_%s_%d" % (biome, i), bush(800 + i, leaves), None, dict(v=VT, skip=((0, 0, -1),))))
        kit.append(("ivy_%s_%d" % (biome, i), ivy(900 + i, leaves), None, dict(origin=(8, 8, 0))))
    kit.append(("litter_" + biome, pile(950, leaves), None, FLAT))
    kit.append(("float_" + biome, scatter(960, leaves, 12), None, FLAT))


def build():
    global STONE, MORTAR, QUOIN
    for o in list(coll().objects):
        bpy.data.objects.remove(o, do_unlink=True)
    WALL = dict(origin=(8, 8, 0), skip=((0, 1, 0), (0, 0, -1)))
    FLAT = dict(origin=(8, 8, 0), skip=((0, 0, -1),))
    base = (STONE, MORTAR, QUOIN)
    only = os.environ.get("DELVE_ONLY", "")  # ex. "crypte,jade,teal" : ne régénère que ça
    for name, (st, mo, qu) in PALETTES.items():
        if only and name not in only.split(","):
            continue
        STONE, MORTAR, QUOIN = base if st is None else (pal(st), lin(mo), pal(qu))
        SUB[0] = "" if name == "pierre" else name
        kit = []
        stone_kit(kit, WALL, FLAT)
        emit(kit)
    STONE, MORTAR, QUOIN = base
    SUB[0] = ""
    kit = []
    if only:
        for biome, leaves in (("autumn", AUTUMN), ("green", GREEN), ("pink", PINK), ("teal", TEAL)):
            if biome in only.split(","):
                foliage_kit(kit, biome, leaves)
        emit(kit)
        print("ok (partiel)")
        return
    kit.append(("seabed", seabed(530), None, FLAT))
    kit.append(("lily_0", lily(500), None, FLAT)); kit.append(("lily_1", lily(501), None, FLAT))
    kit.append(("flowers", flowers(510), None, FLAT))
    kit.append(("rubble", rubble(520), None, FLAT))
    vox, g = lantern(540)
    kit.append(("lantern", vox, g, FLAT))
    kit.append(("prop_coffre", chest(560), None, FLAT))
    vox, g = brazier(561)
    kit.append(("prop_brasero", vox, g, FLAT))
    kit.append(("prop_levier", lever(562), None, FLAT))
    kit.append(("prop_pilier", cracked_pillar(563), None, FLAT))
    vox, g = rack(567)
    kit.append(("prop_ratelier", vox, g, FLAT))
    vox, g = vasque(568)
    kit.append(("prop_vasque", vox, g, FLAT))
    kit.append(("prop_cloche", bell(569), None, FLAT))
    vox, g = barrel(564)
    kit.append(("prop_baril", vox, g, FLAT))
    vox, g = turret(565)
    kit.append(("prop_tourelle", vox, g, FLAT))
    kit.append(("prop_piege", jaw_trap(566), None, FLAT))
    vox, g = portal(570)
    kit.append(("portal", vox, g, FLAT))
    for i in range(3):
        kit.append(("top_grass_%d" % i, grass_top(580 + i), None, FLAT))
    kit.append(("fireweed", fireweed(590), None, FLAT))
    kit.append(("tufts", tufts(591), None, FLAT))
    for i in range(2):
        vox, g = crystal(700 + i)
        kit.append(("crystal_%d" % i, vox, g, dict(origin=(8, 8, 0))))
        kit.append(("pine_%d" % i, pine(720 + i), None, dict(v=VT)))
    vox, g = crystal(710, True)
    kit.append(("crystal_giant", vox, g, dict(origin=(8, 8, 0))))
    for biome, leaves in (("autumn", AUTUMN), ("green", GREEN), ("pink", PINK), ("teal", TEAL)):
        foliage_kit(kit, biome, leaves)
    emit(kit)
    print("ok", sum(len(f) for _, _, f in os.walk(OUT)), "fichiers")


if __name__ == "__main__":
    build()
