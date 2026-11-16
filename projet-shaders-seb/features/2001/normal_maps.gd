extends DemoFeature
## 2004 — Normal maps : une texture indique, pixel par pixel, dans quelle
## direction la surface « regarde ». Du relief sans un seul triangle de plus.


func _init() -> void:
	id = "normal_maps"
	label = "Normal maps"
	states = ["Normal maps : du relief sans triangles"]
	year = 2004
	key = KEY_N
	author = "Sébastien"


func _apply() -> void:
	for material in ctx.materials.all:
		material.normal_enabled = is_on() and ctx.materials.original(material, &"normal_enabled")
