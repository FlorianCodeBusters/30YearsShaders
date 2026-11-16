extends DemoFeature
## 2016 — Anti-aliasing temporel (TAA) : la caméra tremble d'une fraction de
## pixel à chaque image, et on accumule les images précédentes. Les escaliers
## disparaissent… et c'est déjà une façon d'effacer du bruit avec le temps.


func _init() -> void:
	id = "taa"
	label = "Anti-aliasing temporel (TAA)"
	states = ["TAA : on accumule les images pour lisser les contours"]
	year = 2016
	key = KEY_J
	author = "Florian"


func _apply() -> void:
	# FSR 2 fait son propre anti-aliasing temporel : les deux ne se cumulent pas.
	ctx.viewport.use_taa = is_on() and not ctx.is_on("fsr2")
