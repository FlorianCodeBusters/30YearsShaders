class_name DemoContext
extends RefCounted
## Tout ce dont une fonctionnalité a besoin pour agir sur la scène, plus les
## arbitrages entre fonctionnalités qui partagent un même réglage.

const BAKE_1996 := "res://bakes/lm_1996.lmbake"
const BAKE_NOISY := "res://bakes/lm_2026_bruite.lmbake"
const BAKE_CLEAN := "res://bakes/lm_2026_debruite.lmbake"

## Énergie des néons tant que l'image n'est pas en HDR : au-delà de 1, ils saturent en blanc.
const NEON_LDR := 1.0
## Part de l'énergie Blender gardée en HDR (le glow fait le reste).
const NEON_HDR := 0.5

var main: Node3D
## La scène de l'atrium (`scenes/atrium.tscn`).
var world: Node3D
var viewport: Viewport
var env: Environment
var moon: DirectionalLight3D
var probe: ReflectionProbe
var lightmap: LightmapGI
var camera: CameraRig
var materials: MaterialLibrary
var neon_lights: NeonLights
var manager: EraManager
var quality: DemoQuality

var _bakes := {}
var _probe_request := 0


## Un objet de la scène par son nom Blender (`Puddle`, `Neon_01`, `Prop_Hologram`…).
func node(node_name: String) -> MeshInstance3D:
	return world.get_node_or_null(node_name) as MeshInstance3D


func state_of(id: String) -> int:
	return manager.state_of(id)


func is_on(id: String) -> bool:
	return manager.state_of(id) > 0


## Taille de la fenêtre en pixels réels (le rendu 3D en dépend, pas l'interface).
func pixel_size() -> Vector2i:
	return main.get_window().size


## Un bake `LightmapGI` préparé à l'avance, ou `null` s'il n'a pas encore été fait.
func bake(path: String) -> LightmapGIData:
	if not _bakes.has(path):
		_bakes[path] = load(path) as LightmapGIData if ResourceLoader.exists(path) else null
	return _bakes[path]


# --- Arbitrages -------------------------------------------------------------

## Résolution du rendu 3D : 1996 (480 lignes, gros pixels) > FSR 2 > native.
func update_scaling() -> void:
	if is_on("low_res"):
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
		viewport.scaling_3d_scale = clampf(480.0 / pixel_size().y, 0.1, 1.0)
	elif is_on("fsr2"):
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		viewport.scaling_3d_scale = 0.67
	else:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = quality.native_scale


## Lightmap affichée : le bake ray tracé (bruité, débruité) > celui de 1996 > aucune.
func update_lightmap() -> void:
	var data: LightmapGIData = null
	match state_of("rt_bake"):
		1: data = bake(BAKE_NOISY)
		2: data = bake(BAKE_CLEAN)
	var retro := false
	if data == null and is_on("lowres_lightmaps"):
		data = bake(BAKE_1996)
		retro = data != null
	lightmap.light_data = data
	# En 1996, pas de filtrage bicubique : on veut voir les gros texels.
	RenderingServer.lightmaps_set_bicubic_filter(not retro)
	update_neon_lights()
	manager.refresh("sdfgi")


func has_lightmap() -> bool:
	return lightmap.light_data != null


## Fausses lumières des néons.
##  - Avec une lightmap, la lumière des néons est déjà dans le bake : on les éteint toutes.
##  - Avec l'illumination globale, les néons éclairent pour de vrai : on ne garde
##    que les lumières clés, pour leurs reflets.
func update_neon_lights() -> void:
	var realtime := not has_lightmap()
	neon_lights.set_visible_groups(realtime, realtime and is_on("many_lights") and not env.sdfgi_enabled)


## Énergie d'émission des néons, selon qu'on est en HDR ou non.
func neon_energy(blender_energy: float) -> float:
	if is_on("hdr_glow"):
		return maxf(blender_energy * NEON_HDR, 1.0)
	return minf(blender_energy, NEON_LDR)


func update_neons() -> void:
	for material in materials.neons:
		material.emission_energy_multiplier = neon_energy(materials.original(material, &"emission_energy_multiplier"))
	manager.refresh("perlin")
	manager.refresh("hologram")
	manager.refresh("mobile_light")


## Lumière ambiante : une couleur fixe tant qu'on n'a pas d'illumination globale.
func update_ambient() -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.55)
	env.ambient_light_energy = 0.12 if env.sdfgi_enabled else 0.35


## Le cubemap du `ReflectionProbe` est capturé une seule fois : on redemande une
## capture quand l'éclairage change (tout de suite, puis une fois l'éclairage stabilisé).
func refresh_probe() -> void:
	if probe == null or not probe.visible:
		return
	_nudge_probe()
	_probe_request += 1
	var request := _probe_request
	main.get_tree().create_timer(0.8).timeout.connect(func() -> void:
		if request == _probe_request:
			_nudge_probe())


## Modifier un réglage de la sonde, même d'un rien, relance sa capture.
func _nudge_probe() -> void:
	probe.max_distance = 300.0 if probe.max_distance > 300.0 else 300.01
