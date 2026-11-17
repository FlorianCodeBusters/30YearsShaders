class_name ComputeJob
extends RefCounted
## Fait tourner un compute shader du type « état avant → état après ».
##
## Le shader lit un tableau (binding 0), écrit le suivant (binding 1) et reçoit
## un petit bloc de paramètres (binding 2). À chaque appel de `run()`, les deux
## tableaux échangent leurs rôles, et le résultat est relu par le processeur.
##
## Le shader est compilé à l'exécution depuis son texte : on peut donc le
## modifier en direct et récupérer ses erreurs de compilation.
##
## Deux façons de tourner :
##  - sur un périphérique de rendu à part (par défaut) : `run()` attend la fin
##    du calcul et renvoie son résultat. Simple, et la durée mesurée est exacte.
##    C'est le mode du Lab (`lab/boids.gd`), où rien d'autre n'est dessiné.
##  - dans le rendu de la scène (`in_scene = true`) : le calcul part avec le
##    reste de l'image et son résultat revient une ou deux images plus tard,
##    sans jamais bloquer. C'est le mode de la nuée de drones
##    (`features/2006/boids.gd`) : attendre une carte graphique déjà occupée à
##    dessiner l'atrium coûtait une image entière.

## Vrai : le calcul passe par le rendu de la scène, sans attente (voir plus haut).
## À régler avant le premier `compile()`.
var in_scene := false
## Durée lissée du dernier calcul (envoi + attente du GPU), en millisecondes.
## N'a de sens que hors scène.
var ms := 0.0

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _buffers: Array[RID] = []
var _params: RID
var _sets: Array[RID] = []
## 0 : on lit le tableau 0 et on écrit le 1. 1 : l'inverse.
var _flip := 0
## Dernier résultat revenu de la carte graphique (mode scène).
var _latest := PackedFloat32Array()


## Compile le shader. Renvoie "" si tout va bien, sinon le message d'erreur.
## En cas d'erreur, l'ancien shader reste en place.
func compile(code: String) -> String:
	if _rd == null:
		_rd = RenderingServer.get_rendering_device() if in_scene else RenderingServer.create_local_rendering_device()
		if _rd == null:
			return "Compute shaders indisponibles avec ce moteur de rendu."
	var source := RDShaderSource.new()
	# « #[compute] » est un marqueur pour l'importeur de Godot, pas du GLSL.
	source.source_compute = code.replace("#[compute]", "")
	var spirv := _rd.shader_compile_spirv_from_source(source, false)
	if spirv.compile_error_compute != "":
		return spirv.compile_error_compute
	var shader := _rd.shader_create_from_spirv(spirv)
	if not shader.is_valid():
		return "Le shader compile, mais ses tableaux ne correspondent pas à ceux attendus."
	# Libérer l'ancien shader libère aussi son pipeline et ses jeux d'uniformes.
	if _shader.is_valid():
		_rd.free_rid(_shader)
	_shader = shader
	_pipeline = _rd.compute_pipeline_create(_shader)
	_sets.clear()
	return ""


## Fournit l'état de départ : il est copié dans les deux tableaux, en mémoire vidéo.
func set_data(data: PackedFloat32Array) -> void:
	if _rd == null:
		return
	for buffer in _buffers:
		_rd.free_rid(buffer)
	var bytes := data.to_byte_array()
	_buffers = [_rd.storage_buffer_create(bytes.size(), bytes), _rd.storage_buffer_create(bytes.size(), bytes)]
	_sets.clear()
	_flip = 0


func has_data() -> bool:
	return not _buffers.is_empty()


## Lance une passe : `groups` paquets de fils d'exécution (voir `local_size_x`
## dans le shader). Renvoie le nouvel état (hors scène), le dernier état connu
## (en scène), ou un tableau vide si rien n'est encore prêt.
func run(params: PackedByteArray, groups: int) -> PackedFloat32Array:
	if not _pipeline.is_valid() or _buffers.is_empty():
		return PackedFloat32Array()
	if not _params.is_valid():
		_params = _rd.uniform_buffer_create(params.size(), params)
		_sets.clear()
	else:
		_rd.buffer_update(_params, 0, params.size(), params)
	if _sets.is_empty():
		_sets = [_make_set(0, 1), _make_set(1, 0)]

	var start := Time.get_ticks_usec()
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, _sets[_flip], 0)
	_rd.compute_list_dispatch(list, groups, 1, 1)
	_rd.compute_list_end()
	var written := _buffers[1 - _flip]
	_flip = 1 - _flip

	if in_scene:
		# Le calcul partira avec l'image. On demande à être rappelé quand son résultat sera lisible.
		_rd.buffer_get_data_async(written, _on_data)
		return _latest
	_rd.submit()
	_rd.sync()      # on attend que le GPU ait fini
	ms = lerpf(ms, (Time.get_ticks_usec() - start) / 1000.0, 0.1)
	return _rd.buffer_get_data(written).to_float32_array()


## Libère tout ce qui a été créé sur la carte graphique.
func dispose() -> void:
	if _rd == null:
		return
	if _shader.is_valid():
		_rd.free_rid(_shader)
	for buffer in _buffers:
		_rd.free_rid(buffer)
	if _params.is_valid():
		_rd.free_rid(_params)
	if not in_scene:
		_rd.free()      # le périphérique à part nous appartient, pas celui de la scène
	_rd = null
	_buffers.clear()
	_shader = RID()
	_pipeline = RID()
	_params = RID()


func _on_data(bytes: PackedByteArray) -> void:
	_latest = bytes.to_float32_array()


func _make_set(from: int, to: int) -> RID:
	return _rd.uniform_set_create([
		_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 0, _buffers[from]),
		_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, _buffers[to]),
		_uniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER, 2, _params),
	], _shader, 0)


func _uniform(type: RenderingDevice.UniformType, binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform
