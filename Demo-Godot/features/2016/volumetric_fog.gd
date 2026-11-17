extends DemoFeature
## 2016 — Brouillard volumétrique : l'air lui-même est éclairé. Les néons et le
## projecteur dessinent des halos et des faisceaux dans la brume.


func _init() -> void:
	id = "volumetric_fog"
	label = "Brouillard volumétrique"
	states = ["Brouillard volumétrique : la lumière traverse l'air"]
	year = 2016
	key = KEY_F
	author = "Florian"


func _apply() -> void:
	var env := ctx.env
	env.volumetric_fog_enabled = is_on()
	env.volumetric_fog_density = 0.014
	env.volumetric_fog_albedo = Color(0.8, 0.85, 1.0)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_ambient_inject = 0.15
	env.volumetric_fog_gi_inject = 0.4
	env.volumetric_fog_sky_affect = 0.3
