extends DemoFeature
## 2004 — Reflets par cubemap : on photographie la scène une fois, depuis un
## point, et les surfaces brillantes reflètent cette photo. C'est faux (le
## reflet ne dépend pas vraiment de l'endroit où l'on se trouve), mais ça suffit
## pour une flaque.


func _init() -> void:
	id = "reflection_probe"
	label = "Reflets par cubemap"
	states = ["Reflets par cubemap (ReflectionProbe) : les premières fausses flaques"]
	year = 2004
	key = KEY_C
	author = "Florian"


func _apply() -> void:
	ctx.probe.visible = is_on()
	# Sans sonde, aucune réflexion d'environnement : ni cubemap, ni ciel.
	ctx.env.reflected_light_source = (Environment.REFLECTION_SOURCE_BG if is_on()
		else Environment.REFLECTION_SOURCE_DISABLED)
