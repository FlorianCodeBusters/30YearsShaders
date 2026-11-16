extends DemoFeature
## 1996 — Éclairage par sommet (Gouraud) : la lumière est calculée aux sommets
## des triangles, puis interpolée. Pas de reflets spéculaires, pas de détail.
## La couper = passer à l'éclairage par pixel de 2001.


func _init() -> void:
	id = "vertex_lighting"
	label = "Éclairage par sommet"
	label_off = "Éclairage par pixel"
	year = 1996
	key = KEY_V
	author = "Sébastien"
	baseline = 1


func _apply() -> void:
	for material in ctx.materials.all:
		if is_on():
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		else:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
