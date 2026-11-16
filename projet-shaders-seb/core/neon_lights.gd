class_name NeonLights
extends Node3D
## Les « fausses » lumières des néons.
##
## En rastérisation, une surface émissive n'éclaire rien : pendant 20 ans, on a
## triché en posant une lumière ponctuelle devant chaque néon. Ce nœud les
## génère à partir de la géométrie des objets `Neon_*` :
##  - les lumières **clés** : une par grande enseigne (PERLIN, GPU, HOTEL…) ;
##  - les lumières **d'appoint** : une par paquet de néons (réglettes des
##    coursives, vitrines, écrans, lampes), pour l'étape « beaucoup de lumières ».
## Si la scène est régénérée, les lumières suivent : rien n'est placé à la main.

## Grandes enseignes : une seule lumière, plus forte.
const KEY_NEONS: Array[String] = ["Neon_01", "Neon_02", "Neon_03", "Neon_04", "Neon_05", "Neon_07"]
## Au-delà de cette distance (la skyline), pas de lumière.
const MAX_DISTANCE := 60.0
## Taille des paquets pour les lumières d'appoint, en mètres.
const CELL := 5.0
## Couleur moyenne de l'atlas d'enseignes (`M_Sign`), qui n'a pas de couleur unie.
const SIGN_COLOR := Color(1.0, 0.45, 0.75)

var key_lights: Array[OmniLight3D] = []
var extra_lights: Array[OmniLight3D] = []


func build(world: Node3D) -> void:
	name = "NeonLights"
	# Les néons d'appoint sont regroupés tous ensemble, par cases de `CELL` mètres.
	var sums := {}
	var colors := {}
	var counts := {}
	for neon: MeshInstance3D in world.find_children("Neon_*", "MeshInstance3D", true, false):
		var aabb := neon.global_transform * neon.mesh.get_aabb()
		if aabb.get_center().length() > MAX_DISTANCE:
			continue
		var color := _color_of(neon)
		if String(neon.name) in KEY_NEONS:
			key_lights.append(_add_light(aabb.get_center(), color, 2.2, 9.0))
			continue
		for surface in neon.mesh.get_surface_count():
			var vertices: PackedVector3Array = neon.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				var point := neon.global_transform * vertex
				var cell := Vector3i((point / CELL).floor())
				sums[cell] = sums.get(cell, Vector3.ZERO) + point
				colors[cell] = colors.get(cell, Color.BLACK) + color
				counts[cell] = counts.get(cell, 0) + 1
	for cell: Vector3i in sums:
		var count: int = counts[cell]
		var mixed: Color = colors[cell] / float(count)
		extra_lights.append(_add_light(sums[cell] / float(count), mixed, 1.1, 7.5))
	print("NeonLights : %d lumières clés, %d lumières d'appoint" % [key_lights.size(), extra_lights.size()])


func set_visible_groups(keys: bool, extras: bool) -> void:
	for light in key_lights:
		light.visible = keys
	for light in extra_lights:
		light.visible = extras


func _add_light(at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	# Décalée vers l'axe de l'atrium, pour ne pas rester collée au mur.
	light.position = at + Vector3(-signf(at.x) * 0.5 if absf(at.x) > 1.0 else 0.0, 0.0, 0.0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.2
	light.light_specular = 0.6
	light.shadow_enabled = false
	light.light_bake_mode = Light3D.BAKE_DISABLED
	add_child(light)
	return light


func _color_of(neon: MeshInstance3D) -> Color:
	var material := neon.mesh.surface_get_material(0) as StandardMaterial3D
	if material == null or material.emission_texture != null:
		return SIGN_COLOR
	return material.emission
