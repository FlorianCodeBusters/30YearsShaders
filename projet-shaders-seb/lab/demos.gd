class_name LabDemos
extends RefCounted
## Les démos du Lab : pour chaque décennie, des shaders écrits à la main, avec
## leur code affiché à côté de ce qu'ils produisent.
##
##   decade : 1996, 2001, 2006 ou 2016 (les quatre parties du talk)
##   year   : année affichée
##   title  : titre de la démo
##   note   : une phrase d'explication, sous le rendu
##   source : le fichier affiché et modifiable (.gdshader ou .gdshaderinc)
##   stage  : le décor (une méthode `_stage_<nom>` de `lab.gd`)
##   shader : le shader appliqué au décor, s'il diffère de `source`
##   params : paramètres imposés au matériau
##
## Pour ajouter une démo : écrire le shader, ajouter une ligne ici. C'est tout.

const S := "res://lab/shaders/"
const F := "res://features/"

const LIST: Array[Dictionary] = [
	# --- 1996 : avant les shaders ---
	{decade = 1996, year = 1996, title = "Le pipeline fixe : tout se calcule par sommet",
		note = "Boule à facettes et sol à 4 sommets : la lumière est interpolée, le reflet disparaît.",
		source = S + "1996_pipeline_fixe.gdshader", stage = "boules"},
	{decade = 1996, year = 1996, title = "16 bits et tramage",
		note = "65 536 couleurs seulement : un motif régulier cache les bandes dans les dégradés.",
		source = F + "1996/color_16bit.gdshader", stage = "piece"},

	# --- 2001-2006 : du câblé au programmable ---
	{decade = 2001, year = 2001, title = "Vertex shader : un programme par sommet",
		note = "La géométrie ne change pas : c'est le shader qui déplace les sommets à chaque image.",
		source = F + "2001/hologram.gdshader", stage = "hologramme"},
	{decade = 2001, year = 2001, title = "Fragment shader : l'éclairage par pixel",
		note = "Le même calcul qu'en 1996, déplacé du sommet vers le pixel.",
		source = S + "2001_eclairage_par_pixel.gdshader", stage = "boules"},
	{decade = 2001, year = 1983, title = "Le bruit de Perlin",
		note = "Du hasard doux. Changez la courbe en S (ligne « vec2 s ») par « f » pour voir la grille.",
		source = F + "2001/perlin.gdshaderinc", stage = "flaque",
		shader = F + "2001/perlin_flaque.gdshader", params = {bruit_seul = true}},
	{decade = 2001, year = 2001, title = "Perlin branché sur l'eau",
		note = "Le bruit sert de hauteur à l'eau ; sa pente dévie les reflets.",
		source = F + "2001/perlin_flaque.gdshader", stage = "flaque", params = {bruit_seul = false}},
	{decade = 2001, year = 2001, title = "Perlin branché sur un néon",
		note = "Le même bruit, lu dans le temps : l'enseigne grésille.",
		source = F + "2001/perlin_neon.gdshader", stage = "neon", params = {intensite = 4.0}},
	{decade = 2001, year = 2004, title = "Normal map : du relief sans triangles",
		note = "Le mur est un rectangle plat. Passez « relief » à false pour le vérifier.",
		source = S + "2004_normal_map.gdshader", stage = "mur"},

	# --- 2006-2016 : la course au réalisme ---
	{decade = 2006, year = 2006, title = "HDR, glow et tonemapping : un shader sur l'image",
		note = "Post-processing : le shader ne dessine pas d'objet, il retouche l'image entière.",
		source = S + "2006_hdr_glow.gdshader", stage = "piece"},
	{decade = 2006, year = 2007, title = "SSAO : des échantillons tirés au hasard",
		note = "8 échantillons par pixel : l'image est bruitée. C'est ce bruit que Godot floute ensuite.",
		source = S + "2007_ssao.gdshader", stage = "piece"},
	{decade = 2006, year = 2011, title = "SSR : un rayon lancé dans l'image",
		note = "Le sol reflète ce qui est à l'écran, et seulement ce qui est à l'écran.",
		source = S + "2011_ssr.gdshader", stage = "piece"},
	{decade = 2006, year = 2014, title = "PBR : rugosité et métal",
		note = "En haut : pas du métal. En bas : du métal. De gauche à droite : de lisse à rugueux.",
		source = S + "2014_pbr.gdshader", stage = "pbr"},

	# --- 2016-2026 : la lumière simulée ---
	{decade = 2016, year = 2018, title = "Path tracing : la lumière simulée… et bruitée",
		note = "Montez « rayons_par_pixel », ou passez « accumulation » à 0.05 : le bruit s'efface avec le temps.",
		source = S + "2018_path_tracing.gdshader", stage = "ecran", accumulate = true},
	{decade = 2016, year = 2020, title = "Champs de distances : l'idée derrière SDFGI",
		note = "La scène est une fonction. Passez « montrer_les_pas » à true pour voir le coût de chaque rayon.",
		source = S + "2020_champ_de_distances.gdshader", stage = "ecran"},
]
