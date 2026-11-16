class_name DemoQuality
extends RefCounted
## Niveau de qualité des effets coûteux, selon la machine.
##
## `PORTABLE` vise un GPU intégré (Intel Iris Xe), `HAUTE` une carte dédiée.
## Choisi automatiquement d'après le nom du GPU ; forçable en ligne de commande
## (`-- --quality=haute` ou `--quality=portable`) et basculable avec F7.

enum Level { PORTABLE, HAUTE }

var level := Level.HAUTE
## Échelle du rendu 3D quand ni le 640×480 ni FSR 2 ne sont actifs.
var native_scale := 1.0

var _viewport: Viewport
var _ssao_blur := 2


func setup(viewport: Viewport, forced := "") -> void:
	_viewport = viewport
	var gpu := RenderingServer.get_video_adapter_name()
	var integrated := gpu.containsn("intel") and not gpu.containsn("arc")
	level = Level.PORTABLE if integrated else Level.HAUTE
	if forced == "haute":
		level = Level.HAUTE
	elif forced == "portable":
		level = Level.PORTABLE
	print("GPU : %s → qualité %s" % [gpu, level_name()])
	apply()


func level_name() -> String:
	return "portable" if level == Level.PORTABLE else "haute"


func toggle() -> void:
	level = Level.HAUTE if level == Level.PORTABLE else Level.PORTABLE
	apply()


func apply() -> void:
	var low := level == Level.PORTABLE
	native_scale = 1.0
	# Illumination globale (SDFGI) : demi-résolution et peu de rayons sur un portable.
	RenderingServer.gi_set_use_half_resolution(low)
	RenderingServer.environment_set_sdfgi_ray_count(
		RenderingServer.ENV_SDFGI_RAY_COUNT_8 if low else RenderingServer.ENV_SDFGI_RAY_COUNT_32)
	RenderingServer.environment_set_sdfgi_frames_to_converge(RenderingServer.ENV_SDFGI_CONVERGE_IN_15_FRAMES)
	# SSIL et SSR.
	RenderingServer.environment_set_ssil_quality(
		RenderingServer.ENV_SSIL_QUALITY_LOW if low else RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
		true, 0.5, 4, 50.0, 300.0)
	RenderingServer.environment_set_ssr_half_size(low)
	# Brouillard volumétrique : taille de la grille de voxels.
	RenderingServer.environment_set_volumetric_fog_volume_size(64 if low else 96, 64 if low else 96)
	# Ombres.
	RenderingServer.directional_shadow_atlas_set_size(2048 if low else 4096, true)
	_viewport.positional_shadow_atlas_size = 2048 if low else 4096
	var shadow_filter := RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW if low else RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM
	RenderingServer.directional_soft_shadow_filter_set_quality(shadow_filter)
	RenderingServer.positional_soft_shadow_filter_set_quality(shadow_filter)
	set_ssao_blur(_ssao_blur)


## Nombre de passes de flou du SSAO. 0 = le tampon brut, pour le « pivot du bruit ».
func set_ssao_blur(passes: int) -> void:
	_ssao_blur = passes
	var low := level == Level.PORTABLE
	RenderingServer.environment_set_ssao_quality(
		RenderingServer.ENV_SSAO_QUALITY_LOW if low else RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		low, 0.5, passes, 50.0, 300.0)
