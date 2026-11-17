class_name LabBoids
extends Node2D
## La démo de compute shader du Lab : une nuée de boids en 2D.
##
## Le calcul se fait entièrement sur la carte graphique (`ComputeJob`). Le
## processeur ne fait que relire les positions pour les dessiner : un triangle
## par boid, dans un `MultiMesh`.

const COUNT := 4096
const GROUP := 64               # doit correspondre à local_size_x dans le shader

var _job := ComputeJob.new()
var _size := Vector2.ZERO
var _multimesh := MultiMesh.new()
var _palette: Array[Color] = []
var _background := ColorRect.new()
var _counter := Label.new()


func _ready() -> void:
	_background.color = Color(0.02, 0.02, 0.05)
	add_child(_background)
	for i in 64:
		_palette.append(Color.from_hsv(i / 64.0, 0.55, 1.0))
	var triangle := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(5, 0), Vector2(-3, 2.6), Vector2(-3, -2.6)])
	triangle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.mesh = triangle
	_multimesh.instance_count = COUNT
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = _multimesh
	add_child(instance)
	_counter.position = Vector2(14, 10)
	_counter.add_theme_font_size_override("font_size", 20)
	_counter.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_counter.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_counter.add_theme_constant_override("outline_size", 6)
	add_child(_counter)


## Compile le shader. Renvoie "" si tout va bien, sinon le message d'erreur du compilateur.
func set_code(code: String) -> String:
	return _job.compile(code)


func _process(delta: float) -> void:
	_size = get_viewport_rect().size
	# On attend que la vue ait sa taille définitive pour répartir les boids.
	if _size.x < 64.0:
		return
	_background.size = _size
	if not _job.has_data():
		_job.set_data(_random_boids())

	# Le bloc de paramètres du shader : taille de l'écran, durée de l'image, nombre de boids.
	var params := PackedFloat32Array([_size.x, _size.y, minf(delta, 0.05)]).to_byte_array()
	params.append_array(PackedInt32Array([COUNT]).to_byte_array())
	var boids := _job.run(params, ceili(COUNT / float(GROUP)))
	if boids.is_empty():
		return
	_draw_boids(boids)
	_counter.text = ("%s boids · %.1f millions de comparaisons · %.1f ms sur le GPU" % [
		_thousands(COUNT), COUNT * (COUNT - 1.0) / 1e6, _job.ms]).replace(".", ",")


## Un triangle par boid, orienté dans le sens du vol, coloré selon sa direction.
func _draw_boids(boids: PackedFloat32Array) -> void:
	var buffer := PackedFloat32Array()
	buffer.resize(COUNT * 12)
	for i in COUNT:
		var x := boids[i * 4]
		var y := boids[i * 4 + 1]
		var heading := Vector2(boids[i * 4 + 2], boids[i * 4 + 3]).normalized()
		var color := _palette[int((heading.angle() / TAU + 0.5) * 63.99)]
		var o := i * 12
		buffer[o] = heading.x
		buffer[o + 1] = -heading.y
		buffer[o + 3] = x
		buffer[o + 4] = heading.y
		buffer[o + 5] = heading.x
		buffer[o + 7] = y
		buffer[o + 8] = color.r
		buffer[o + 9] = color.g
		buffer[o + 10] = color.b
		buffer[o + 11] = 1.0
	_multimesh.buffer = buffer


## L'état de départ : position (x, y) et vitesse (x, y) de chaque boid, au hasard.
func _random_boids() -> PackedFloat32Array:
	var start := PackedFloat32Array()
	start.resize(COUNT * 4)
	for i in COUNT:
		var velocity := Vector2.from_angle(randf() * TAU) * randf_range(80.0, 200.0)
		start[i * 4] = randf() * _size.x
		start[i * 4 + 1] = randf() * _size.y
		start[i * 4 + 2] = velocity.x
		start[i * 4 + 3] = velocity.y
	return start


func _thousands(value: int) -> String:
	return "%d %03d" % [value / 1000, value % 1000] if value >= 1000 else str(value)


func _exit_tree() -> void:
	_job.dispose()
