extends DemoFeature
## 1996 — Image en 16 bits (65 536 couleurs) avec tramage, comme une 3dfx Voodoo.
## Un shader 2D plein écran, posé par-dessus l'image finale.

const SHADER := preload("res://features/1996/color_16bit.gdshader")

var _layer: CanvasLayer
var _material: ShaderMaterial


func _init() -> void:
	id = "color_16bit"
	label = "Couleurs 16 bits + tramage"
	label_off = "Couleurs 32 bits"
	year = 1996
	key = KEY_T
	author = "Florian"
	baseline = 1


func _setup() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var rect := ColorRect.new()
	rect.material = _material
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer = CanvasLayer.new()
	_layer.layer = 1          # sous l'overlay (10), au-dessus de la 3D
	_layer.visible = false
	_layer.add_child(rect)
	ctx.main.add_child(_layer)


func _apply() -> void:
	_layer.visible = is_on()


func _process(_delta: float) -> void:
	# Le tramage se cale sur les « gros pixels » du rendu basse résolution.
	_material.set_shader_parameter("taille_pixel", 1.0 / ctx.viewport.scaling_3d_scale)
