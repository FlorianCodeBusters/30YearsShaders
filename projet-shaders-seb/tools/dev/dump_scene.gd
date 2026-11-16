extends SceneTree
# Outil de contrôle : affiche l'arborescence importée et ses matériaux.
#   godot --headless --path . -s tools/dev/dump_scene.gd
func _init() -> void:
	var scene: Node = load("res://assets/scene/atrium_kit.glb").instantiate()
	var mats := {}
	_walk(scene, 0, mats)
	print("=== MATERIAUX")
	for n in mats:
		var m: BaseMaterial3D = mats[n]
		print("%s | %s | normal=%s rough=%.2f rtex=%s metal=%.2f mtex=%s emis=%s e=%.2f etex=%s transp=%d" % [n, m.get_class(), m.normal_enabled, m.roughness, m.roughness_texture != null, m.metallic, m.metallic_texture != null, m.emission_enabled, m.emission_energy_multiplier, m.emission_texture != null, m.transparency])
	quit()

func _walk(n: Node, depth: int, mats: Dictionary) -> void:
	var extra := ""
	if n is MeshInstance3D:
		var mesh: Mesh = n.mesh
		var aabb: AABB = n.global_transform * mesh.get_aabb() if n.is_inside_tree() else n.transform * mesh.get_aabb()
		extra = " surfaces=%d uv2=%s gi=%d pos=%s aabb=%s..%s" % [mesh.get_surface_count(), (mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_TEX_UV2) != 0, n.gi_mode, n.position, aabb.position.snappedf(0.1), aabb.end.snappedf(0.1)]
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			if m: mats[m.resource_name] = m
	elif n is Camera3D:
		extra = " fov=%.1f keep=%d near=%.2f far=%.0f pos=%s rot=%s" % [n.fov, n.keep_aspect, n.near, n.far, n.position, n.rotation_degrees]
	elif n is Node3D:
		extra = " pos=%s rot=%s" % [n.position, n.rotation_degrees]
	print("  ".repeat(depth), n.name, " [", n.get_class(), "]", extra)
	for c in n.get_children():
		_walk(c, depth + 1, mats)
