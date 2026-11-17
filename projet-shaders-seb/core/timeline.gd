class_name Timeline
extends RefCounted
## La frise de la démo : la liste des fonctionnalités et l'ordre des étapes.
##
## C'est LE fichier à modifier pour changer le déroulé : l'ordre des étapes,
## les années affichées, les titres. Les presets (touches 1 à 5) sont des
## positions dans cette frise.

## Les fonctionnalités, dans l'ordre du panneau d'aide.
const FEATURES: Array[Script] = [
	# 1996 : avant les shaders
	preload("res://features/1996/low_res.gd"),
	preload("res://features/1996/color_16bit.gd"),
	preload("res://features/1996/linear_fog.gd"),
	preload("res://features/1996/lowres_lightmaps.gd"),
	preload("res://features/1996/vertex_lighting.gd"),
	# 2001-2006 : du câblé au programmable
	preload("res://features/2001/hologram.gd"),
	preload("res://features/2001/perlin.gd"),
	preload("res://features/2001/normal_maps.gd"),
	preload("res://features/2001/mobile_light.gd"),
	preload("res://features/2001/reflection_probe.gd"),
	# 2006-2016 : la course au réalisme
	preload("res://features/2006/hdr_glow.gd"),
	preload("res://features/2006/ssao.gd"),
	preload("res://features/2006/ssao_debug.gd"),
	preload("res://features/2006/many_lights.gd"),
	preload("res://features/2006/boids.gd"),
	preload("res://features/2006/rain.gd"),
	preload("res://features/2006/ssr.gd"),
	preload("res://features/2006/pbr.gd"),
	# 2016-2026 : la lumière simulée
	preload("res://features/2016/taa.gd"),
	preload("res://features/2016/volumetric_fog.gd"),
	preload("res://features/2016/sdfgi.gd"),
	preload("res://features/2016/fsr2.gd"),
	preload("res://features/2016/rt_bake.gd"),
]

## Titre de la position 0 : le preset 1996, où seules les fonctionnalités
## « baseline » (celles du dossier 1996) sont actives.
const START_YEAR := 1996
const START_TITLE := "Pipeline fixe : la carte graphique se configure, elle ne se programme pas"

## Les étapes, dans l'ordre où → les déroule.
##   year   : année affichée dans l'overlay
##   states : { id de fonctionnalité : état } (0 = coupée, 1…n = active)
##   title  : titre affiché ; vide = celui de la fonctionnalité
##   preset : la touche de ce preset amène juste APRÈS cette étape
## Années indicatives : à vérifier avant de les reprendre sur une slide.
const STEPS: Array[Dictionary] = [
	# --- Partie 1 : 1996-2006 ---
	{year = 2001, states = {low_res = 0, color_16bit = 0, linear_fog = 0},
		title = "Plus de pixels, plus de couleurs, plus de brouillard cache-misère"},
	{year = 2001, states = {vertex_lighting = 0, lowres_lightmaps = 0},
		title = "Shaders programmables : l'éclairage se calcule pour chaque pixel"},
	{year = 2001, states = {hologram = 1}},
	{year = 2001, states = {perlin = 1}},
	{year = 2001, states = {perlin = 2}, preset = 2001},
	{year = 2004, states = {normal_maps = 1}},
	{year = 2004, states = {mobile_light = 1}},
	{year = 2004, states = {reflection_probe = 1}, preset = 2006},
	# --- Partie 2 : 2006-2016 ---
	{year = 2006, states = {hdr_glow = 1}},
	{year = 2007, states = {ssao = 1}},
	{year = 2007, states = {ssao_debug = 1}},
	{year = 2007, states = {ssao_debug = 2}},
	{year = 2007, states = {ssao_debug = 0}, title = "SSAO : retour à l'image complète"},
	{year = 2009, states = {many_lights = 1}},
	{year = 2009, states = {boids = 1}},
	{year = 2010, states = {rain = 1}},
	{year = 2011, states = {ssr = 1}},
	{year = 2014, states = {pbr = 1}, preset = 2016},
	# --- Partie 3 : 2016-2026 ---
	{year = 2016, states = {taa = 1}},
	{year = 2016, states = {volumetric_fog = 1}},
	{year = 2020, states = {sdfgi = 1}},
	{year = 2022, states = {fsr2 = 1}, preset = 2026},
	# --- Final : un vrai lancer de rayons (bakes préparés à l'avance) ---
	{year = 2026, states = {rt_bake = 1}},
	{year = 2026, states = {rt_bake = 2}},
]
