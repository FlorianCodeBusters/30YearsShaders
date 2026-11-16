extends DemoFeature
## 2009 — Beaucoup de lumières. Avec le rendu différé (puis le Forward+), le coût
## d'une lumière ne dépend plus du nombre d'objets : on peut en poser des dizaines.
## Ici : une lumière d'appoint devant chaque paquet de néons (voir `core/neon_lights.gd`).


func _init() -> void:
	id = "many_lights"
	label = "Beaucoup de lumières"
	states = ["Des dizaines de lumières : chaque néon éclaire"]
	year = 2009
	key = KEY_U
	author = "Florian"


func _apply() -> void:
	ctx.update_neon_lights()
