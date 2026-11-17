extends DemoFeature
## 1996 — Lightmaps basse résolution, façon Quake : tout l'éclairage est
## précalculé dans une texture grossière, plaquée sur les murs.
## Le bake est préparé à l'avance (voir README, « Bakes ») ; l'arbitrage avec le
## bake ray tracé de 2026 est dans `DemoContext.update_lightmap()`.


func _init() -> void:
	id = "lowres_lightmaps"
	label = "Lightmaps basse résolution"
	label_off = "Lightmaps coupées : tout l'éclairage est dynamique"
	year = 1996
	key = KEY_L
	author = "Sébastien"
	baseline = 1


func available() -> bool:
	return ctx.bake(DemoContext.BAKE_1996) != null


func unavailable_reason() -> String:
	return "Lightmap 1996 à préparer : bakes/lm_1996.lmbake (voir README)"


func _apply() -> void:
	ctx.update_lightmap()
