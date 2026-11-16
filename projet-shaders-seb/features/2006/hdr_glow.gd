extends DemoFeature
## 2006 — HDR + tonemapping + glow. L'image est calculée avec des intensités
## bien supérieures à ce que l'écran sait afficher (un néon vaut 4, pas 1),
## puis ramenée dans la plage de l'écran. Ce qui dépasse « bave » : c'est le glow.


func _init() -> void:
	id = "hdr_glow"
	label = "HDR + tonemapping + glow"
	states = ["HDR, tonemapping et glow : les néons brûlent"]
	year = 2006
	key = KEY_G
	author = "Florian"


func _apply() -> void:
	var env := ctx.env
	if is_on():
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_white = 6.0
		env.tonemap_exposure = 1.0
	else:
		# Avant le HDR : pas de courbe, tout ce qui dépasse 1 est écrêté.
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_white = 1.0
		env.tonemap_exposure = 1.0
	env.glow_enabled = is_on()
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	# Les néons passent de « blanc saturé » à de vraies intensités HDR.
	ctx.update_neons()
