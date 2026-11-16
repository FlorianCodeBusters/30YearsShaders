extends DemoFeature
## 2011 — SSR, les reflets en espace écran : pour chaque pixel brillant, on lance
## un rayon… dans l'image déjà calculée. Les flaques reflètent enfin la vraie scène.
## Sa limite (à montrer avec la caméra Flaque, F2, ou en vue libre) : ce qui n'est
## pas à l'écran ne peut pas être reflété.


func _init() -> void:
	id = "ssr"
	label = "SSR (reflets écran)"
	states = ["SSR : les flaques reflètent vraiment la scène"]
	year = 2011
	key = KEY_E
	author = "Florian"


func _apply() -> void:
	var env := ctx.env
	env.ssr_enabled = is_on()
	env.ssr_max_steps = 96
	env.ssr_fade_in = 0.1
	env.ssr_fade_out = 3.0
	env.ssr_depth_tolerance = 0.4
