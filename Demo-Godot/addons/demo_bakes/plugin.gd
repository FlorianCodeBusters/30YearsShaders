@tool
extends EditorPlugin
## Prépare les trois bakes `LightmapGI` de la démo, en une seule action.
##
## Dans l'éditeur : menu Projet → Outils → « Démo : recalculer les 3 lightmaps ».
## En ligne de commande (l'éditeur s'ouvre, calcule, puis se ferme) :
##
##     godot -e --path . -- --demo-bake
##
## Godot n'expose pas le bake des lightmaps aux scripts : ce plugin règle le
## nœud `LightmapGI` de `scenes/atrium.tscn`, puis « appuie » sur le bouton
## *Bake Lightmaps* de l'éditeur, une fois par bake. La scène n'est pas
## enregistrée : seuls les fichiers de `bakes/` sont écrits.

const SCENE := "res://scenes/atrium.tscn"
const MENU := "Démo : recalculer les 3 lightmaps"
## Pendant le bake, l'émission des néons est multipliée : ce sont les seules
## vraies sources de lumière de l'atrium, et des tubes aussi fins éclairent peu.
const NEON_BOOST := 6.0
## Réglage du débruiteur (JNLM, intégré à Godot). Les néons sont de petites
## sources très lumineuses, donc beaucoup de bruit : il faut débruiter fort.
const DENOISER_STRENGTH := 0.6
const DENOISER_RANGE := 20

## Les trois bakes. `texel_scale` multiplie la densité de la lightmap
## (1 = un texel tous les 20 cm, réglé à l'import du .glb).
const BAKES: Array[Dictionary] = [
	{   # 1996 : gros texels, façon Quake
		path = "res://bakes/lm_1996.lmbake",
		texel_scale = 0.25, quality = LightmapGI.BAKE_QUALITY_MEDIUM, denoiser = true, bounces = 3,
	},
	{   # 2026 : le path tracer brut, peu de rayons
		path = "res://bakes/lm_2026_bruite.lmbake",
		texel_scale = 2.0, quality = LightmapGI.BAKE_QUALITY_LOW, denoiser = false, bounces = 3,
	},
	{   # 2026 : exactement le même, avec le débruiteur
		path = "res://bakes/lm_2026_debruite.lmbake",
		texel_scale = 2.0, quality = LightmapGI.BAKE_QUALITY_LOW, denoiser = true, bounces = 3,
	},
]


func _enter_tree() -> void:
	add_tool_menu_item(MENU, bake_all)
	if "--demo-bake" in OS.get_cmdline_user_args():
		_run_unattended()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU)


func _run_unattended() -> void:
	# Laisser l'éditeur finir de démarrer et d'importer.
	await get_tree().create_timer(5.0).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	var ok := await bake_all()
	get_tree().quit(0 if ok else 1)


func bake_all() -> bool:
	EditorInterface.open_scene_from_path(SCENE)
	await _frames(10)
	var root := EditorInterface.get_edited_scene_root()
	var lightmap := root.get_node_or_null("LightmapGI") as LightmapGI if root != null else null
	if lightmap == null:
		push_error("Bakes : nœud LightmapGI introuvable dans " + SCENE)
		return false

	# Sélectionner le nœud fait apparaître le bouton de bake dans la barre de la vue 3D.
	EditorInterface.set_main_screen_editor("3D")
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(lightmap)
	EditorInterface.edit_node(lightmap)
	await _frames(10)
	var button := _find_bake_button()
	if button == null:
		push_error("Bakes : bouton de bake introuvable (version de Godot différente ?)")
		return false

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://bakes"))
	var before := {}
	for property: StringName in [&"texel_scale", &"quality", &"use_denoiser", &"bounces", &"denoiser_strength", &"denoiser_range"]:
		before[property] = lightmap.get(property)
	lightmap.denoiser_strength = DENOISER_STRENGTH
	lightmap.denoiser_range = DENOISER_RANGE
	var neons := _emissive_materials(root)
	for material: BaseMaterial3D in neons:
		material.emission_energy_multiplier = neons[material] * NEON_BOOST
	var ok := true
	for bake in BAKES:
		var path: String = bake.path
		lightmap.texel_scale = bake.texel_scale
		lightmap.quality = bake.quality
		lightmap.use_denoiser = bake.denoiser
		lightmap.bounces = bake.bounces
		# Un LightmapGIData déjà enregistré : l'éditeur bake alors directement
		# dans ce fichier, sans ouvrir de fenêtre de choix.
		ResourceSaver.save(LightmapGIData.new(), path)
		lightmap.light_data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		await _frames(3)
		print("Bakes : calcul de %s…" % path)
		var start := Time.get_ticks_msec()
		button.pressed.emit()
		await _frames(3)
		var data := lightmap.light_data
		var done := data != null and data.get_user_count() > 0
		print("Bakes : %s %s en %.0f s (%d objets)" % [
			path, "terminé" if done else "ÉCHEC", (Time.get_ticks_msec() - start) / 1000.0,
			data.get_user_count() if data != null else 0])
		ok = ok and done

	# On remet le nœud comme il était : la démo choisit sa lightmap à l'exécution.
	lightmap.light_data = null
	for property: StringName in before:
		lightmap.set(property, before[property])
	for material: BaseMaterial3D in neons:
		material.emission_energy_multiplier = neons[material]
	return ok


## Les matériaux émissifs de la scène, avec leur énergie d'origine.
func _emissive_materials(root: Node) -> Dictionary:
	var found := {}
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.gi_mode != GeometryInstance3D.GI_MODE_STATIC:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(i) as BaseMaterial3D
			if material != null and material.emission_enabled:
				found[material] = material.emission_energy_multiplier
	return found


## Le bouton « Bake Lightmaps » : celui dont le clic est branché sur l'outil de bake de l'éditeur.
func _find_bake_button() -> Button:
	for node in EditorInterface.get_base_control().find_children("*", "Button", true, false):
		var button := node as Button
		for connection in button.pressed.get_connections():
			var target: Object = (connection.callable as Callable).get_object()
			if target != null and target.get_class() == "LightmapGIEditorPlugin":
				return button
	return null


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
