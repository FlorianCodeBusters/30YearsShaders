extends DemoFeature
## 2009 — Compute shader : une nuée de drones lumineux vole dans le vide central
## de l'atrium. Leur mouvement est calculé sur la carte graphique par
## `boids.glsl` : chaque drone compare sa position à celle de tous les autres,
## soit un million de comparaisons par image.
##
## Le GPU ne dessine rien ici, il calcule : c'est ce qui en a fait une machine
## à tout faire (physique, vidéo, puis réseaux de neurones).
## Le processeur ne fait que recopier positions et vitesses dans un `MultiMesh`,
## et `boids_drone.gdshader` oriente chaque drone dans le sens de son vol.
## La même simulation, en 2D et modifiable en direct, est dans le Lab (Tab).

const COMPUTE_SHADER := "res://features/2006/boids.glsl"
const DRONE_SHADER := preload("res://features/2006/boids_drone.gdshader")
const COUNT := 1024
const GROUP := 64                              # local_size_x du compute shader
## Le volume où vole la nuée : le vide central, au-dessus des têtes et sous la passerelle.
## Assez loin des caméras pour qu'aucun drone ne leur passe sous le nez.
const CENTER := Vector3(0.0, 6.4, -14.0)
const HALF_SIZE := Vector3(2.8, 2.6, 6.5)
const COLORS: Array[Color] = [Color(0.1, 0.8, 1.0), Color(1.0, 0.15, 0.55), Color(1.0, 0.75, 0.1)]
## Floats par instance du MultiMesh : transformation (12), couleur (4), donnée libre (4).
const STRIDE := 20

var _job := ComputeJob.new()
var _error := ""
var _instance: MultiMeshInstance3D
var _multimesh := MultiMesh.new()
var _material := ShaderMaterial.new()
var _light: OmniLight3D
var _buffer := PackedFloat32Array()
var _time := 0.0


func _init() -> void:
	id = "boids"
	label = "Compute shader (nuée de drones)"
	states = ["Compute shader : 1 024 drones, un million de comparaisons par image"]
	year = 2009
	key = KEY_X
	author = "Sébastien"


func available() -> bool:
	return _error == ""


func unavailable_reason() -> String:
	return "Compute shader indisponible : " + _error.left(80)


func _setup() -> void:
	# Le calcul part avec le rendu de la scène ; son résultat revient une image ou deux plus tard.
	_job.in_scene = true
	_error = _job.compile(FileAccess.get_file_as_string(COMPUTE_SHADER))
	if _error != "":
		push_warning("Nuée de drones : " + _error)
		return
	_job.set_data(_random_drones())

	# Un petit cône, pointe vers +Y.
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.03
	cone.height = 0.17
	cone.radial_segments = 4
	cone.rings = 0
	_material.shader = DRONE_SHADER
	cone.material = _material
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	_multimesh.mesh = cone
	_multimesh.instance_count = COUNT
	# La partie fixe de chaque instance : pas de rotation (le vertex shader s'en charge), une couleur.
	_buffer.resize(COUNT * STRIDE)
	for i in COUNT:
		var o := i * STRIDE
		_buffer[o] = 1.0
		_buffer[o + 5] = 1.0
		_buffer[o + 10] = 1.0
		var color := COLORS[i % COLORS.size()]
		_buffer[o + 12] = color.r
		_buffer[o + 13] = color.g
		_buffer[o + 14] = color.b
		_buffer[o + 15] = 1.0

	_instance = MultiMeshInstance3D.new()
	_instance.name = "Boids"
	_instance.multimesh = _multimesh
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_instance.custom_aabb = AABB(CENTER - HALF_SIZE * 1.5, HALF_SIZE * 3.0)
	_instance.visible = false
	ctx.world.add_child(_instance)

	# Une lueur qui suit le cœur de la nuée : on voit passer les drones sur les murs.
	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.85, 1.0)
	_light.light_energy = 0.9
	_light.omni_range = 7.0
	_light.shadow_enabled = false
	_light.light_bake_mode = Light3D.BAKE_DISABLED
	_instance.add_child(_light)


func _exit() -> void:
	_job.dispose()


func _apply() -> void:
	if _instance == null:
		return
	_instance.visible = is_on()
	# En HDR, les drones dépassent un peu le blanc : le glow les fait briller.
	_material.set_shader_parameter("intensite", 1.7 if ctx.is_on("hdr_glow") else 1.0)


func _process(delta: float) -> void:
	_time += delta
	# Le point que la nuée suit : il fait le tour du volume en une quarantaine de secondes.
	var target := CENTER + HALF_SIZE * Vector3(sin(_time * 0.31), sin(_time * 0.47), sin(_time * 0.16)) * 0.8
	var params := PackedFloat32Array([
		CENTER.x, CENTER.y, CENTER.z, 0.0,
		HALF_SIZE.x, HALF_SIZE.y, HALF_SIZE.z, 0.0,
		target.x, target.y, target.z, 0.0,
		minf(delta, 0.05),
	]).to_byte_array()
	params.append_array(PackedInt32Array([COUNT, 0, 0]).to_byte_array())   # + de quoi arrondir à 64 octets
	var drones := _job.run(params, ceili(COUNT / float(GROUP)))
	if drones.is_empty():
		return

	# On recopie la position et la vitesse de chaque drone dans son instance.
	var center := Vector3.ZERO
	for i in COUNT:
		var from := i * 8
		var to := i * STRIDE
		_buffer[to + 3] = drones[from]
		_buffer[to + 7] = drones[from + 1]
		_buffer[to + 11] = drones[from + 2]
		_buffer[to + 16] = drones[from + 4]
		_buffer[to + 17] = drones[from + 5]
		_buffer[to + 18] = drones[from + 6]
		if i < 64:      # un échantillon suffit pour situer le cœur de la nuée
			center += Vector3(drones[from], drones[from + 1], drones[from + 2])
	_multimesh.buffer = _buffer
	_light.position = center / 64.0


## L'état de départ : position et vitesse de chaque drone, au hasard dans le volume.
func _random_drones() -> PackedFloat32Array:
	var start := PackedFloat32Array()
	start.resize(COUNT * 8)
	for i in COUNT:
		var position := CENTER + HALF_SIZE * Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		var velocity := Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)).normalized() * 3.5
		var o := i * 8
		start[o] = position.x
		start[o + 1] = position.y
		start[o + 2] = position.z
		start[o + 3] = 1.0
		start[o + 4] = velocity.x
		start[o + 5] = velocity.y
		start[o + 6] = velocity.z
	return start
