extends DemoFeature
## 2022 — FSR 2 : on calcule l'image en plus petit (67 %), puis on la reconstruit
## en pleine définition à partir des images précédentes. C'est la même idée que
## DLSS : acheter de la puissance avec de l'accumulation temporelle.
## L'arbitrage avec le 640×480 est dans `DemoContext.update_scaling()`.


func _init() -> void:
	id = "fsr2"
	label = "FSR 2 (upscaling temporel)"
	states = ["FSR 2 : image calculée à 67 %, reconstruite avec le temps"]
	year = 2022
	key = KEY_Z
	author = "Florian"


func _apply() -> void:
	# FSR 2 et TAA ne se cumulent pas : on coupe l'un avant d'allumer l'autre.
	if is_on():
		ctx.manager.refresh("taa")
		ctx.update_scaling()
	else:
		ctx.update_scaling()
		ctx.manager.refresh("taa")
