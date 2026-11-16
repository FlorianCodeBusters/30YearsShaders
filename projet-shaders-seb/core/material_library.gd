class_name MaterialLibrary
extends RefCounted
## Recense les matériaux de la scène importée et garde leurs réglages d'origine.
##
## Les fonctionnalités modifient les matériaux **en mémoire** (jamais le fichier
## importé) : couper les normal maps, repasser en éclairage par sommet, etc.
## `original()` permet de revenir à ce que Blender a exporté.

const TRACKED: Array[StringName] = [
	&"normal_enabled", &"roughness", &"roughness_texture", &"metallic",
	&"metallic_texture", &"metallic_specular", &"emission_energy_multiplier",
]

## Tous les matériaux de la scène.
var all: Array[StandardMaterial3D] = []
## Les matériaux émissifs : `M_Neon_*`, `M_Sign`, `M_Hologram`.
var neons: Array[StandardMaterial3D] = []

var _original := {}


func scan(root: Node) -> void:
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_instance.mesh
		for i in mesh.get_surface_count():
			var material := mesh.surface_get_material(i) as StandardMaterial3D
			if material == null or _original.has(material):
				continue
			var values := {}
			for property in TRACKED:
				values[property] = material.get(property)
			_original[material] = values
			all.append(material)
			if material.emission_enabled:
				neons.append(material)


## Valeur d'origine (celle de l'export Blender) d'une propriété suivie.
func original(material: StandardMaterial3D, property: StringName) -> Variant:
	return _original[material][property]


func by_name(material_name: String) -> StandardMaterial3D:
	for material in all:
		if material.resource_name == material_name:
			return material
	return null
