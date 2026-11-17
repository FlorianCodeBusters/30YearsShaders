extends DemoFeature
## 2001 — Le shader au bruit de Perlin, écrit à la main. La clé du titre.
##
## État 1 : le bruit seul, affiché sur tout le sol (« du hasard doux »).
## État 2 : le bruit branché : le sol se creuse de flaques qui ondulent, et
##          l'enseigne PERLIN grésille.
##
## Avant cette étape, la flaque est l'objet `Puddle` de la scène : un polygone
## sombre aux bords nets, comme en 1996. Ensuite, c'est le sol lui-même qui
## porte l'eau (`perlin_flaque.gdshader` remplace son matériau) : les bords sont
## fondus, sans raccord, et les reflets, les ombres et les lightmaps restent
## ceux du sol.
##
## Les shaders sont faits pour être montrés et modifiés en live :
## `perlin.gdshaderinc` (le bruit), `perlin_flaque.gdshader`, `perlin_neon.gdshader`.
## Tab (le Lab) ou la scène `scenes/labo_perlin.tscn` les affichent seuls.

const GROUND_SHADER := preload("res://features/2001/perlin_flaque.gdshader")
const NEON_SHADER := preload("res://features/2001/perlin_neon.gdshader")
## Niveau de l'eau par temps sec, et quand il pleut (les flaques s'étendent).
const WATER_DRY := 0.27
const WATER_RAIN := 0.32

var _ground: MeshInstance3D
var _puddle: MeshInstance3D
var _neon: MeshInstance3D
var _ground_original: StandardMaterial3D
var _ground_material := ShaderMaterial.new()
var _neon_material := ShaderMaterial.new()
var _neon_energy := 8.0
var _water := WATER_DRY


func _init() -> void:
	id = "perlin"
	label = "Shader au bruit de Perlin"
	states = [
		"Le bruit de Perlin, seul : du hasard doux",
		"Perlin branché : les flaques ondulent, le néon grésille",
	]
	year = 2001
	key = KEY_P
	author = "Sébastien"


func _setup() -> void:
	_ground = ctx.node("Ground")
	_puddle = ctx.node("Puddle")
	_neon = ctx.node("Neon_01")
	_ground_original = _ground.mesh.surface_get_material(0) as StandardMaterial3D
	_ground_material.shader = GROUND_SHADER
	set_ground_textures(_ground_material, ctx)
	_neon_material.shader = NEON_SHADER
	var neon_original := _neon.mesh.surface_get_material(0) as StandardMaterial3D
	_neon_material.set_shader_parameter("couleur", neon_original.emission)
	_neon_energy = ctx.materials.original(neon_original, &"emission_energy_multiplier")


## Donne au shader du sol mouillé les textures du bitume d'origine.
## (Celles de l'export Blender : d'autres étapes peuvent les avoir retirées du matériau.)
static func set_ground_textures(material: ShaderMaterial, context: DemoContext) -> void:
	var ground := context.node("Ground").mesh.surface_get_material(0) as StandardMaterial3D
	material.set_shader_parameter("sol_couleur", ground.albedo_texture)
	material.set_shader_parameter("sol_normales", ground.normal_texture)
	material.set_shader_parameter("sol_rugosite", context.materials.original(ground, &"roughness_texture"))


func _apply() -> void:
	# Le sol mouillé remplace le sol et l'ancienne flaque.
	_ground.material_override = _ground_material if is_on() else null
	_puddle.visible = not is_on()
	_ground_material.set_shader_parameter("bruit_seul", state == 1)
	_follow_ground()
	_neon.material_override = _neon_material if state == 2 else null
	_neon_material.set_shader_parameter("intensite", ctx.neon_energy(_neon_energy))


func _process(delta: float) -> void:
	_follow_ground()
	# Quand il pleut, l'eau monte doucement et les flaques s'étendent.
	var target := WATER_RAIN if ctx.is_on("rain") else WATER_DRY
	_water = move_toward(_water, target, delta * 0.02)
	_ground_material.set_shader_parameter("niveau_eau", _water)


## Le bitume du sol mouillé suit celui du sol d'origine, que d'autres étapes
## modifient : relief (normal maps, 2004) et rugosité texturée (PBR, 2014).
func _follow_ground() -> void:
	var relief := _ground_original.normal_scale if _ground_original.normal_enabled else 0.0
	var has_roughness_map := _ground_original.roughness_texture != null
	_ground_material.set_shader_parameter("sol_relief", relief)
	_ground_material.set_shader_parameter("sol_rugosite_fixe", 0.0 if has_roughness_map else _ground_original.roughness)
