extends DemoFeature
## 2001 — Le shader au bruit de Perlin, écrit à la main. La clé du titre.
##
## État 1 : le bruit seul, affiché sur la flaque (« du hasard doux »).
## État 2 : le bruit branché : la flaque ondule, l'enseigne PERLIN grésille.
##
## Les shaders sont faits pour être montrés et modifiés en live :
## `perlin.gdshaderinc` (le bruit), `perlin_flaque.gdshader`, `perlin_neon.gdshader`.
## La scène `scenes/labo_perlin.tscn` les affiche seuls dans l'éditeur.

const PUDDLE_SHADER := preload("res://features/2001/perlin_flaque.gdshader")
const NEON_SHADER := preload("res://features/2001/perlin_neon.gdshader")

var _puddle: MeshInstance3D
var _neon: MeshInstance3D
var _puddle_material := ShaderMaterial.new()
var _neon_material := ShaderMaterial.new()
var _neon_energy := 8.0


func _init() -> void:
	id = "perlin"
	label = "Shader au bruit de Perlin"
	states = [
		"Le bruit de Perlin, seul : du hasard doux",
		"Perlin branché : la flaque ondule, le néon grésille",
	]
	year = 2001
	key = KEY_P
	author = "Sébastien"


func _setup() -> void:
	_puddle = ctx.node("Puddle")
	_neon = ctx.node("Neon_01")
	_puddle_material.shader = PUDDLE_SHADER
	_neon_material.shader = NEON_SHADER
	var puddle_original := _puddle.mesh.surface_get_material(0) as StandardMaterial3D
	_puddle_material.set_shader_parameter("couleur", puddle_original.albedo_color)
	var neon_original := _neon.mesh.surface_get_material(0) as StandardMaterial3D
	_neon_material.set_shader_parameter("couleur", neon_original.emission)
	_neon_energy = ctx.materials.original(neon_original, &"emission_energy_multiplier")


func _apply() -> void:
	_puddle.material_override = _puddle_material if state > 0 else null
	_puddle_material.set_shader_parameter("bruit_seul", state == 1)
	_neon.material_override = _neon_material if state == 2 else null
	_neon_material.set_shader_parameter("intensite", ctx.neon_energy(_neon_energy))
