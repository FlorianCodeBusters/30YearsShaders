extends DemoFeature
## 2020 — Illumination globale en temps réel (SDFGI + SSIL) : la lumière
## rebondit. Le clair de lune qui tombe dans l'atrium éclaire les murs en face,
## et les néons éclairent enfin pour de vrai, sans fausses lumières.


func _init() -> void:
	id = "sdfgi"
	label = "Illumination globale (SDFGI + SSIL)"
	states = ["Illumination globale : la lumière rebondit, en temps réel"]
	year = 2020
	key = KEY_S
	author = "Florian"


func _apply() -> void:
	var env := ctx.env
	# Avec une lightmap, la lumière indirecte vient du bake : inutile de la calculer deux fois.
	var active := is_on() and not ctx.has_lightmap()
	env.sdfgi_enabled = active
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.2
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = true
	env.sdfgi_bounce_feedback = 0.3
	env.sdfgi_energy = 0.3
	env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
	env.ssil_enabled = active
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.8
	ctx.update_ambient()
	# Les néons éclairent maintenant pour de vrai : plus besoin des lumières d'appoint.
	ctx.update_neon_lights()
