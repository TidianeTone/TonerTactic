# Marqueurs de la carte d'étage, version « hologramme voxel » : chaque icône pixel art (assets/ui/mapico_px_<salle>.png)
# devient un bas-relief de voxels lumineux, dressé au-dessus d'un petit projecteur posé au sol (anneau et cône de lumière).
# "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P blender/render_mapico.py -> assets/ui/mapico_vox_<salle>.png
import bpy, bmesh, math, os
from mathutils import Vector

UI = r"G:\Mes APP\Delve\assets\ui"
TINT = {"combat": (1.0, 0.86, 0.62), "elite": (1.0, 0.35, 0.22), "boss": (1.0, 0.25, 0.18), "sanctuaire": (0.45, 1.0, 0.6),
        "reliquaire": (0.8, 0.5, 1.0), "marchand": (1.0, 0.82, 0.4), "mystere": (0.45, 1.0, 0.9)}  # les couleurs des anciennes pastilles
VOX = 1.0 / 64
DEPTH = 3


def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            s.render.engine = eng
            break
        except TypeError:
            continue
    s.render.film_transparent = True
    s.render.resolution_x, s.render.resolution_y = 176, 208
    s.view_settings.view_transform = "Standard"
    w = bpy.data.worlds.new("w")
    s.world = w
    next(n for n in w.node_tree.nodes if n.type == "BACKGROUND").inputs["Strength"].default_value = 0.0
    # vue de la carte : trois quarts, en plongée, comme l'île peinte
    bpy.ops.object.camera_add(location=(0.0, -2.87, 2.56))  # visée sur le milieu de l'hologramme (z 0,55), 35° de plongée
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 1.62
    cam.rotation_euler = (math.radians(55), 0, 0)
    s.camera = cam


def holo_mat(tint):
    ## Voxel d'hologramme : la couleur du pixel teintée, lumineuse, un peu transparente, barrée de lignes de balayage.
    m = bpy.data.materials.new("holo")
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Col"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["Factor"].default_value = 0.22
    mix.inputs["B"].default_value = (*tint, 1)
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Strength"].default_value = 1.05
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = 90.0  # lignes de balayage horizontales
    sn = nt.nodes.new("ShaderNodeMath")
    sn.operation = "SINE"
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = -1.0
    mr.inputs["To Min"].default_value = 0.7
    mr.inputs["To Max"].default_value = 0.95
    ms = nt.nodes.new("ShaderNodeMixShader")
    L = nt.links
    L.new(ca.outputs["Color"], mix.inputs["A"])
    L.new(mix.outputs["Result"], em.inputs["Color"])
    L.new(tc.outputs["Object"], sep.inputs["Vector"])
    L.new(sep.outputs["Z"], mul.inputs[0])
    L.new(mul.outputs["Value"], sn.inputs[0])
    L.new(sn.outputs["Value"], mr.inputs["Value"])
    L.new(mr.outputs["Result"], ms.inputs["Fac"])
    L.new(tr.outputs["BSDF"], ms.inputs[1])
    L.new(em.outputs["Emission"], ms.inputs[2])
    L.new(ms.outputs["Shader"], out.inputs["Surface"])
    return m


def glow_mat(tint, strength, alpha):
    m = bpy.data.materials.new("lueur")
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*tint, 1)
    em.inputs["Strength"].default_value = strength
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    ms = nt.nodes.new("ShaderNodeMixShader")
    ms.inputs["Fac"].default_value = alpha
    nt.links.new(tr.outputs["BSDF"], ms.inputs[1])
    nt.links.new(em.outputs["Emission"], ms.inputs[2])
    nt.links.new(ms.outputs["Shader"], out.inputs["Surface"])
    return m


def voxels(png):
    ## Un voxel par pixel opaque (l'image est agrandie ×2 : un pixel d'art sur deux), épaisseur DEPTH, faces cachées ôtées.
    img = bpy.data.images.load(png)
    W, H = img.size
    px = list(img.pixels)
    step = 2
    grid = {}
    for y in range(0, H, step):
        for x in range(0, W, step):
            i = (y * W + x) * 4
            if px[i + 3] > 0.5:
                grid[(x // step, y // step)] = (px[i], px[i + 1], px[i + 2])
    bm = bmesh.new()
    cols = []
    occ = {(gx, gz, d) for (gx, gz) in grid for d in range(DEPTH)}
    dirs = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]), ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
            ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]), ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
            ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]), ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]
    ox = W // step / 2
    for (gx, gz, d) in occ:
        c = grid[(gx, gz)]
        for (dx, dd, dz), quad in dirs:
            if (gx + dx, gz + dz, d + dd) in occ:
                continue
            vs = [bm.verts.new(((gx + a - ox) * VOX, (d + b) * VOX, (gz + cc) * VOX)) for a, b, cc in quad]
            bm.faces.new(vs)
            shade = {(0, -1, 0): 1.0, (0, 0, 1): 0.95, (1, 0, 0): 0.7, (-1, 0, 0): 0.7, (0, 1, 0): 0.5, (0, 0, -1): 0.45}[(dx, dd, dz)]
            cols.append(tuple(v * shade for v in c) + (1.0,))
    me = bpy.data.meshes.new("vox")
    bm.to_mesh(me)
    bm.free()
    at = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    at.data.foreach_set("color", [k for c in cols for _ in range(4) for k in c])
    ob = bpy.data.objects.new("vox", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def render(k):
    scene()
    tint = TINT[k]
    ob = voxels(os.path.join(UI, "mapico_px_%s.png" % k))
    ob.data.materials.append(holo_mat(tint))
    ob.location = (0, 0, 0.14)  # l'hologramme flotte au-dessus du projecteur
    ob.rotation_euler = (0, 0, math.radians(-18))
    # le projecteur : un disque sombre cerclé de lumière, et un cône de lumière qui monte, de plus en plus pâle
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.34, depth=0.05, location=(0, 0, 0.025))
    base = bpy.context.active_object
    base.data.materials.append(glow_mat((0.08, 0.07, 0.09), 1.0, 1.0))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.34, minor_radius=0.018, location=(0, 0, 0.05))
    bpy.context.active_object.data.materials.append(glow_mat(tint, 3.0, 1.0))
    bpy.ops.mesh.primitive_cone_add(vertices=40, radius1=0.33, radius2=0.5, depth=0.9, location=(0, 0, 0.5), end_fill_type="NOTHING")
    bpy.context.active_object.data.materials.append(glow_mat(tint, 1.0, 0.07))
    bpy.context.scene.render.filepath = os.path.join(UI, "mapico_vox_%s.png" % k)
    bpy.ops.render.render(write_still=True)
    halo(bpy.context.scene.render.filepath)


def halo(path):
    ## Le halo du projecteur : la lumière bave autour des voxels (flou des zones claires, ajouté par-dessus).
    try:
        from PIL import Image, ImageFilter, ImageChops
    except ImportError:
        return
    im = Image.open(path).convert("RGBA")
    glow = im.filter(ImageFilter.GaussianBlur(6))
    out = Image.alpha_composite(glow, im)
    out.save(path)


for k in TINT:
    render(k)
print("mapico ok")
