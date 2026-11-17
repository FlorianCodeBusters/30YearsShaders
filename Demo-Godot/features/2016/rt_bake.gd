extends DemoFeature
## 2026 — Un vrai lancer de rayons. Godot n'a pas de ray tracing matériel en
## temps réel, mais son `LightmapGI` est un authentique path tracer : il lance
## des rayons depuis chaque point des murs pour savoir quelle lumière y arrive.
##
##   état 1 : le résultat brut, avec peu de rayons → bruité ;
##   état 2 : le même, passé dans le débruiteur.
##
## Les deux bakes sont préparés à l'avance (voir README, « Bakes ») et échangés
## en live. Dans ces bakes, ce sont les néons eux-mêmes qui éclairent : les
## fausses lumières sont éteintes (`DemoContext.update_lightmap()`).


func _init() -> void:
	id = "rt_bake"
	label = "Lancer de rayons (bake LightmapGI)"
	states = [
		"Lancer de rayons : peu de rayons, une image bruitée",
		"Le même lancer de rayons, débruité",
	]
	label_off = "Retour au temps réel"
	year = 2026
	key = KEY_K
	author = "Sébastien"


func available() -> bool:
	return ctx.bake(DemoContext.BAKE_NOISY) != null and ctx.bake(DemoContext.BAKE_CLEAN) != null


func unavailable_reason() -> String:
	return "Bakes ray tracés à préparer : bakes/lm_2026_*.lmbake (voir README)"


func _apply() -> void:
	ctx.update_lightmap()
