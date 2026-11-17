extends DemoFeature
## 2007 — SSAO (Crysis) : on assombrit les creux et les recoins en ne regardant
## que l'image déjà calculée (la profondeur de chaque pixel), pas la scène.


func _init() -> void:
	id = "ssao"
	label = "SSAO"
	states = ["SSAO : l'occlusion ambiante, calculée dans l'image"]
	year = 2007
	key = KEY_O
	author = "Sébastien"


func _apply() -> void:
	var env := ctx.env
	# Le « pivot du bruit » (ssao_debug) a besoin du SSAO même s'il est coupé ici.
	env.ssao_enabled = is_on() or ctx.is_on("ssao_debug")
	env.ssao_radius = 1.4
	env.ssao_intensity = 3.0
	env.ssao_power = 1.6
	env.ssao_light_affect = 0.25
