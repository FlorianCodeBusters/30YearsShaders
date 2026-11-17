extends DemoFeature
## 1996 — Rendu en 480 lignes, gros pixels (le 640×480 d'une 3dfx Voodoo).
## L'arbitrage avec FSR 2 est dans `DemoContext.update_scaling()`.


func _init() -> void:
	id = "low_res"
	label = "Rendu 640×480"
	label_off = "Haute résolution"
	year = 1996
	key = KEY_R
	author = "Florian"
	baseline = 1


func _apply() -> void:
	ctx.update_scaling()
