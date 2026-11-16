extends DemoFeature
## 1996 — Brouillard linéaire en fonction de la distance. À l'époque, il sert
## surtout à cacher le fond de la scène, qu'on n'a pas la puissance d'afficher.


func _init() -> void:
	id = "linear_fog"
	label = "Brouillard linéaire"
	year = 1996
	key = KEY_B
	author = "Florian"
	baseline = 1


func _apply() -> void:
	var env := ctx.env
	env.fog_enabled = is_on()
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 6.0
	env.fog_depth_end = 34.0
	env.fog_density = 1.0
	env.fog_light_color = Color(0.11, 0.12, 0.2)
	env.fog_sky_affect = 1.0
