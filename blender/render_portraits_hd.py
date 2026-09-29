# Portraits des héros HD (PC ultra) : chaque assets/hd/u_<héros>[__<vocation>].glb, en pose de repos,
# cadré sur la tête et les épaules devant le fond de sa classe -> assets/hd/portrait_<clé>.png
# "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P blender/render_portraits_hd.py [-- --only=oracle,garde__lame]
import bpy, os, sys, math, glob
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_art as ra

HD = os.path.join(ra.ASSETS, "hd")


def load(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before]
    for o in objs:
        if o.type == "ARMATURE" and o.animation_data:
            idle = bpy.data.actions.get("idle")
            if idle:
                o.animation_data.action = idle
    bpy.context.scene.frame_set(1)
    root = bpy.data.objects.new("hero_root", None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        if o.type == "MESH" and o.name.startswith("Icosphere"):
            o.hide_render = True  # une Icosphere oubliée traîne dans certains .glb
    return root, [o for o in objs if not o.hide_render]


def bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        if o.type != "MESH" or "glow" in o.name:
            continue
        ev = o.evaluated_get(dg)
        for v in ev.to_mesh().vertices:
            p = ev.matrix_world @ v.co
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
        ev.to_mesh_clear()
    return lo, hi


def run():
    ra.setup()
    only = next((a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--only=")), None)
    foes = "--foes" in sys.argv  # ennemis (bestiaire) : en pied, fond rouge de faction -> assets/hd/foe_<modèle>.png
    for path in sorted(glob.glob(os.path.join(HD, "u_*.glb"))):
        key = os.path.basename(path)[2:-4]
        cls = key.split("__")[0]
        if (cls in ra.CLASS) == foes or (only and key not in only):
            continue
        for a in list(bpy.data.actions):
            bpy.data.actions.remove(a)
        ra.clear()
        col = (0.62, 0.16, 0.12) if foes else ra.CLASS[cls]
        ra.backdrop(col)
        root, objs = load(path)
        root.rotation_euler = (0, 0, math.radians(-20))
        bpy.context.view_layer.update()
        lo, hi = bounds(objs)
        h = hi.z - lo.z
        root.location = (-(lo.x + hi.x) * 0.5, -(lo.y + hi.y) * 0.5, -lo.z)
        ra.light_rig(col)
        # la peau voxel HD est sombre : une douce lumière de face, depuis l'appareil
        bpy.ops.object.light_add(type="AREA", location=(0.6, -2.4 * h, 1.1 * h))
        fill = bpy.context.active_object
        fill.data.energy = 260 * h * h
        fill.data.size = 1.5
        fill.rotation_euler = (math.radians(80), 0, math.radians(14))
        if foes:
            # en pied : une bête large ou une structure trapue tient dans le cadre
            sz = max(h, hi.x - lo.x, hi.y - lo.y)
            ra.camera((0.3 * sz, -2.15 * sz, 0.6 * h + 0.2 * sz), (0.0, 0, 0.48 * h), lens=60)
            ra.render(os.path.join(HD, "foe_%s.png" % key), 256, 256)
            continue
        # téléobjectif à hauteur du visage : tête et épaules, sans plongée
        ra.camera((0.3 * h, -2.6 * h, 0.86 * h), (0.0, 0, 0.8 * h), lens=105)
        ra.render(os.path.join(HD, "portrait_%s.png" % key), 256, 256)
    print("portraits hd ok")


if __name__ == "__main__":
    run()
