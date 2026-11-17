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


## Casse la répétition d'une texture : une variation de teinte à grande échelle,
## plaquée dans l'espace monde (donc indépendante des UV de la texture, et qui ne
## se répète que tous les `tile` mètres).
## C'est la couche « détail » du matériau standard, branchée sur une projection
## triplanaire du second jeu d'UV. Elle affaiblit la normal map d'autant
## (`strength`) : on compense sur son intensité.
func add_macro_variation(material_name: String, tile := 11.0, strength := 0.4) -> void:
	var material := by_name(material_name)
	if material == null:
		return
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.011
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	noise.seed = 7
	# Du brun sombre (zones encrassées) au blanc (texture inchangée).
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.25, 0.8])
	ramp.colors = PackedColorArray([Color(0.2, 0.14, 0.12, strength), Color(1.0, 1.0, 1.0, strength)])
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	texture.color_ramp = ramp

	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	material.detail_albedo = texture
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.uv2_scale = Vector3.ONE / tile
	material.normal_scale /= 1.0 - strength
	# La couche détail assombrit en moyenne : on rattrape sur la couleur de base.
	material.albedo_color = material.albedo_color * (1.0 + 0.35 * strength)


func by_name(material_name: String) -> StandardMaterial3D:
	for material in all:
		if material.resource_name == material_name:
			return material
	return null
