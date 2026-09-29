extends SkeletonModifier3D
## Après l'animation (toutes empruntées à l'Oracle, mains jointes devant le ventre), pose le bras qui tient l'arme
## « arme au côté » : bras le long du corps mais écarté, avant-bras vers l'avant. La main sort ainsi du volume
## du corps et l'arme ne le traverse plus. Le Moine lève les deux poings en garde.

var ref: Node3D            # le nœud « model » de l'unité : ses axes (Y haut, Z devant, -X à droite du perso)
var sides: Array = ["Right"]
var ecart := 0.45          # écartement du bras (rad)
var leve := 0.0            # bras porté vers l'avant (le Receleur tend sa lanterne)
var avant_bras := Vector3(0.18, -0.3, 1.0)  # direction de l'avant-bras (x vers l'extérieur, y haut, z devant)
var garde := false         # Moine : avant-bras relevés
var _b := {}


func _ready() -> void:
	var sk := get_skeleton()
	for s in ["Right", "Left"]:
		for part in ["Arm", "ForeArm", "Hand"]:
			for pre in ["mixamorig:", "mixamorig_"]:
				var i := sk.find_bone(pre + s + part)
				if i >= 0:
					_b[s + part] = i


func _aim(b: Basis, d: Vector3) -> Basis:
	## Tourne l'os (axe Y, de sa tête vers sa queue) vers d, par le plus court chemin : la torsion de l'animation reste.
	var y := b.y.normalized()
	if y.dot(d) > 0.9999:
		return b
	return Basis(Quaternion(y, d)) * b


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or ref == null:
		return
	var to_sk := (sk.global_transform.basis.inverse() * ref.global_basis.orthonormalized())
	for s in sides:
		if not (_b.has(s + "Arm") and _b.has(s + "ForeArm") and _b.has(s + "Hand")):
			continue
		var x := -1.0 if s == "Right" else 1.0  # le côté du perso, en axes du modèle
		var d1 := Vector3(x * sin(ecart), -cos(ecart), 0.12 + leve)
		var d2 := Vector3(x * 0.12, 0.45, 1.0) if garde else Vector3(x * avant_bras.x, avant_bras.y, avant_bras.z)
		d1 = (to_sk * d1).normalized()
		d2 = (to_sk * d2).normalized()
		var ia: int = _b[s + "Arm"]
		var iff: int = _b[s + "ForeArm"]
		var ih: int = _b[s + "Hand"]
		var ta := sk.get_bone_global_pose(ia)
		var tf := sk.get_bone_global_pose(iff)
		var th := sk.get_bone_global_pose(ih)
		var l1 := ta.origin.distance_to(tf.origin)
		var l2 := tf.origin.distance_to(th.origin)
		ta.basis = _aim(ta.basis, d1)
		sk.set_bone_global_pose(ia, ta)
		tf.origin = ta.origin + d1 * l1
		tf.basis = _aim(tf.basis, d2)
		sk.set_bone_global_pose(iff, tf)
		th.origin = tf.origin + d2 * l2
		th.basis = _aim(th.basis, d2)
		sk.set_bone_global_pose(ih, th)
