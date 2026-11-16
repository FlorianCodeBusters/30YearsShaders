extends SceneTree
# Outil de contrôle : ouvre une scène, attend quelques images, enregistre une capture.
#   godot --path . -s tools/dev/shot_scene.gd -- res://scenes/labo_perlin.tscn export/labo.png
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	root.add_child((load(args[0]) as PackedScene).instantiate())
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[1])
	quit()
