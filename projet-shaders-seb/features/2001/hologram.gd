extends DemoFeature
## 2001 — Vertex shader : le prisme `Prop_Hologram` tourne, respire et glitche.
## Les tout premiers shaders programmables (GeForce 3) étaient des vertex shaders.

const SHADER := preload("res://features/2001/hologram.gdshader")

var _prism: MeshInstance3D
var _material := ShaderMaterial.new()
var _energy := 1.5


func _init() -> void:
	id = "hologram"
	label = "Vertex shader (hologramme)"
	states = ["Vertex shader : un programme pour chaque sommet"]
	year = 2001
	key = KEY_H
	author = "Florian"


func _setup() -> void:
	_prism = ctx.node("Prop_Hologram")
	_material.shader = SHADER
	var original := _prism.mesh.surface_get_material(0) as StandardMaterial3D
	_material.set_shader_parameter("couleur", original.emission)
	_energy = ctx.materials.original(original, &"emission_energy_multiplier")


func _apply() -> void:
	_prism.material_override = _material if is_on() else null
	_prism.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if is_on()
		else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	_material.set_shader_parameter("intensite", ctx.neon_energy(_energy) * 1.6)
