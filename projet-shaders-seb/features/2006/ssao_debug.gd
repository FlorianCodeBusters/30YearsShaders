extends DemoFeature
## 2007 — Le pivot du bruit. On affiche le tampon du SSAO seul :
##   état 1 : brut, sans son flou → une image granuleuse, faite d'échantillons
##            tirés au hasard ;
##   état 2 : flouté, tel qu'il est utilisé dans l'image finale.
## « Première fois que le bruit change de camp. »
## Hors presets : c'est une parenthèse dans la frise (et la touche D).


func _init() -> void:
	id = "ssao_debug"
	label = "Tampon SSAO (brut / flouté)"
	states = [
		"Le SSAO sans son flou : du bruit",
		"Le même tampon, flouté",
	]
	label_off = "SSAO : retour à l'image complète"
	year = 2007
	key = KEY_D
	author = "Sébastien"


func _apply() -> void:
	ctx.viewport.debug_draw = Viewport.DEBUG_DRAW_SSAO if is_on() else Viewport.DEBUG_DRAW_DISABLED
	ctx.quality.set_ssao_blur(0 if state == 1 else 2)
	ctx.manager.refresh("ssao")
