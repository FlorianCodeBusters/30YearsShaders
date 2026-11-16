extends DemoFeature
## 2004 — Lumière mobile et ombres dynamiques (façon Doom 3) : une lanterne
## décrit un huit au ras du sol, juste derrière la grande flaque. Sa tache
## de lumière balaie le bitume, tout ce qu'elle croise (hologramme, gargote,
## caisses, poteaux) projette une ombre recalculée à chaque image, et son
## reflet glisse dans la flaque.
##
## Elle ne vole pas AU-DESSUS de la flaque : une flaque noire ne renvoie aucune
## lumière diffuse, la tache y serait invisible.

## Centre du huit : sur le bitume derrière la flaque, dans le champ des caméras Hero et Flaque.
const CENTER := Vector3(0.3, 0.75, -9.6)
## Demi-largeur du huit en x, demi-profondeur en z, et amplitude verticale.
const SIZE := Vector3(2.3, 0.12, 1.6)
## Secondes pour un huit complet.
const LOOP_TIME := 10.0
const COLOR := Color(1.0, 0.8, 0.5)

var _lantern: Node3D
var _light: OmniLight3D
var _time := 0.0


func _init() -> void:
	id = "mobile_light"
	label = "Lumière mobile + ombres"
	states = ["Lumière mobile et ombres dynamiques"]
	year = 2004
	key = KEY_M
	author = "Florian"


func _setup() -> void:
	_lantern = Node3D.new()
	_lantern.name = "MobileLight"

	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.light_energy = 7.0
	_light.omni_range = 7.0
	# Atténuation en 1/d² : très lumineux au sol sous la lanterne, sans brûler les murs.
	_light.omni_attenuation = 2.0
	# Une source un peu large : ombres adoucies et reflet visible dans la flaque.
	_light.light_size = 0.25
	_light.light_specular = 0.45
	_light.shadow_enabled = true
	_light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE
	_light.shadow_blur = 1.2
	_light.light_bake_mode = Light3D.BAKE_DISABLED
	_light.light_volumetric_fog_energy = 1.5
	_lantern.add_child(_light)

	# Le corps de la lanterne : une boule lumineuse, pour voir d'où vient la lumière.
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color.BLACK
	glow.emission_enabled = true
	glow.emission = COLOR
	glow.emission_energy_multiplier = 1.0
	sphere.material = glow
	body.mesh = sphere
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_lantern.add_child(body)
	_body_material = glow

	_lantern.visible = false
	ctx.world.add_child(_lantern)
	_move()


var _body_material: StandardMaterial3D


func _apply() -> void:
	_lantern.visible = is_on()
	# Les ombres de la lune deviennent dynamiques en même temps.
	ctx.moon.shadow_enabled = is_on()
	# En HDR, la lanterne elle-même devient éblouissante (et bave avec le glow).
	_body_material.emission_energy_multiplier = ctx.neon_energy(8.0)


func _process(delta: float) -> void:
	_time += delta
	_move()


## Un huit couché (courbe de Lissajous) : large en x, deux boucles en z.
func _move() -> void:
	var angle := TAU * _time / LOOP_TIME
	_lantern.position = CENTER + Vector3(
		SIZE.x * sin(angle),
		SIZE.y * sin(angle * 3.0),
		SIZE.z * sin(angle * 2.0))
