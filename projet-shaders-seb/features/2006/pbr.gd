extends DemoFeature
## 2014 — Matériaux PBR : on décrit une matière physique (est-ce du métal ? à
## quel point est-elle rugueuse ?) au lieu de bidouiller une couleur et une
## brillance jusqu'à ce que « ça rende bien ».
##
## Coupée, on revient aux matériaux d'avant : la même brillance plastique
## partout, pas de vrai métal.

const OLD_ROUGHNESS := 0.5


func _init() -> void:
	id = "pbr"
	label = "Matériaux PBR"
	states = ["Matériaux PBR : métal, rugosité, des matières physiques"]
	year = 2014
	key = KEY_A
	author = "Sébastien"


func _apply() -> void:
	var library := ctx.materials
	for material in library.all:
		if material.emission_enabled:
			continue
		if is_on():
			material.roughness = library.original(material, &"roughness")
			material.roughness_texture = library.original(material, &"roughness_texture")
			material.metallic = library.original(material, &"metallic")
			material.metallic_texture = library.original(material, &"metallic_texture")
		else:
			# La flaque garde son poli : c'était déjà un miroir avant le PBR.
			material.roughness = minf(OLD_ROUGHNESS, library.original(material, &"roughness"))
			material.roughness_texture = null
			material.metallic = 0.0
			material.metallic_texture = null
