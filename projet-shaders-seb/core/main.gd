extends Node3D
## Scène principale : assemble la scène de l'atrium, le gestionnaire d'époques,
## la caméra et l'overlay. Elle ne contient aucune logique de rendu : tout est
## dans `features/`.
##
## Arguments en ligne de commande (après `--`) :
##   --quality=portable|haute   force le niveau de qualité
##   --capture=<dossier>        mode capture : enregistre une image et le débit de chaque preset, puis quitte
##   --shots=presets|steps      (capture) les 5 presets, ou toutes les étapes de la frise
##   --cams=0,1,2,3             (capture) cadrages à capturer (0 = Cam_Hero)
##   --size=1280x720            (capture) taille de la fenêtre
##   --frames=45                (capture) images d'attente avant chaque capture
##   --aide                     (capture) affiche le panneau d'aide et le compteur d'images
##   --lab-capture=<dossier>    enregistre une image de chaque démo du Lab, puis quitte
##   --only=12                  (lab-capture) une seule démo, par son numéro
##   --autotest                 simule toutes les touches, vérifie qu'elles répondent, puis quitte

var ctx := DemoContext.new()
var overlay: DemoOverlay
var lab: ShaderLab

var _args := {}


func _ready() -> void:
	_args = _parse_args()
	var world: Node3D = $Atrium

	ctx.main = self
	ctx.world = world
	ctx.viewport = get_viewport()
	ctx.env = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	ctx.moon = world.get_node("Moon")
	ctx.probe = world.get_node("ReflectionProbe")
	ctx.lightmap = world.get_node("LightmapGI")

	ctx.materials = MaterialLibrary.new()
	ctx.materials.scan(world)

	ctx.neon_lights = NeonLights.new()
	world.add_child(ctx.neon_lights)
	ctx.neon_lights.build(world)

	ctx.quality = DemoQuality.new()
	ctx.quality.setup(get_viewport(), _args.get("quality", ""))

	ctx.camera = CameraRig.new()
	add_child(ctx.camera)
	ctx.camera.setup(world)

	ctx.manager = EraManager.new()
	ctx.manager.name = "EraManager"
	add_child(ctx.manager)
	ctx.manager.setup(ctx)

	overlay = DemoOverlay.new()
	add_child(overlay)
	overlay.setup(ctx)

	lab = ShaderLab.new()
	add_child(lab)
	lab.setup(ctx)
	lab.closed.connect(_on_lab_closed)

	get_viewport().size_changed.connect(ctx.update_scaling)

	if _args.has("capture"):
		await _capture()
		get_tree().quit()
	elif _args.has("lab-capture"):
		await _capture_lab()
		get_tree().quit()
	elif _args.has("autotest"):
		get_tree().quit(0 if await _autotest() else 1)
	else:
		await _warm_up()
		overlay.show_title(Timeline.START_YEAR, Timeline.START_TITLE)


func _exit_tree() -> void:
	# Fonctionnalités et contexte se référencent mutuellement : on défait le nœud à la sortie.
	for feature in ctx.manager.features:
		feature.ctx = null
	ctx.manager.features.clear()
	ctx.manager = null


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_TAB:
			_open_lab()
		KEY_ESCAPE:
			overlay.toggle_help()
		KEY_F9:
			overlay.toggle_fps()
		KEY_F7:
			ctx.quality.toggle()
			ctx.update_scaling()
			ctx.manager.refresh("ssao_debug")
			overlay.toast("Qualité " + ctx.quality.level_name())
		KEY_F11:
			var window := get_window()
			var fullscreen := window.mode == Window.MODE_FULLSCREEN
			window.mode = Window.MODE_WINDOWED if fullscreen else Window.MODE_FULLSCREEN


# --- Le Lab -------------------------------------------------------------------

## Tab : passe de la scène au Lab, ouvert sur la décennie où en est la démo.
func _open_lab() -> void:
	var era := ctx.manager.current_era()
	# La scène est mise en pause et n'est plus dessinée : toute la carte graphique est pour le Lab.
	get_viewport().disable_3d = true
	ctx.manager.process_mode = Node.PROCESS_MODE_DISABLED
	ctx.camera.process_mode = Node.PROCESS_MODE_DISABLED
	overlay.visible = false
	lab.open(2016 if era >= 2016 else era)


func _on_lab_closed() -> void:
	get_viewport().disable_3d = false
	ctx.manager.process_mode = Node.PROCESS_MODE_INHERIT
	ctx.camera.process_mode = Node.PROCESS_MODE_INHERIT
	overlay.visible = true


## Passe une fois par les grandes étapes derrière un écran noir, pour que les
## shaders soient compilés avant la démo et pas au premier appui sur une touche.
func _warm_up() -> void:
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = "Préparation des shaders…"
	label.add_theme_font_size_override("font_size", 36)
	label.set_anchors_preset(Control.PRESET_CENTER)
	cover.add_child(label)
	overlay.add_child(cover)
	var manager := ctx.manager
	for target: int in [manager.steps.size(), manager.presets[2026], manager.presets[2016], manager.presets[2006], manager.presets[2001], 0]:
		manager.go_to(target, false)
		for i in 4:
			await get_tree().process_frame
	cover.queue_free()


# --- Mode capture -----------------------------------------------------------

func _capture() -> void:
	var folder := ProjectSettings.globalize_path(_args["capture"])
	DirAccess.make_dir_recursive_absolute(folder)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if _args.has("size"):
		var parts: PackedStringArray = _args["size"].split("x")
		get_window().size = Vector2i(parts[0].to_int(), parts[1].to_int())
	if _args.has("aide"):
		overlay.toggle_help()
		overlay.toggle_fps()
	var frames: int = _args.get("frames", "45").to_int()
	var cams: Array = Array(_args.get("cams", "0").split(",")).map(func(c: String) -> int: return c.to_int())
	var manager := ctx.manager

	var positions: Array[int] = []
	if _args.get("shots", "presets") == "steps":
		positions.assign(range(manager.steps.size() + 1))
	elif _args.get("shots", "presets") == "presets":
		for year: int in [1996, 2001, 2006, 2016, 2026]:
			positions.append(manager.presets[year])
		positions.append(manager.steps.size())
	else:
		positions.assign(Array(_args["shots"].split(",")).map(func(p: String) -> int: return p.to_int()))

	var report: PackedStringArray = ["GPU : %s — qualité %s — fenêtre %s" % [
		RenderingServer.get_video_adapter_name(), ctx.quality.level_name(), get_window().size]]
	for at in positions:
		manager.go_to(at)
		for cam: int in cams:
			ctx.camera.go(cam, true)
			for i in frames:
				await get_tree().process_frame
			# Mesure du débit sur une trentaine d'images, synchro verticale coupée.
			var start := Time.get_ticks_usec()
			for i in 30:
				await get_tree().process_frame
			var fps := 30.0 / ((Time.get_ticks_usec() - start) / 1e6)
			await RenderingServer.frame_post_draw
			var file := "%02d_%d_%s.png" % [at, manager.year_at(at), CameraRig.SHOTS[cam]]
			get_viewport().get_texture().get_image().save_png(folder.path_join(file))
			var line := "%s  %5.1f img/s  %s" % [file, fps, manager.title_at(at)]
			report.append(line)
			print(line)
	var out := FileAccess.open(folder.path_join("rapport.txt"), FileAccess.WRITE)
	out.store_string("\n".join(report) + "\n")
	out.close()


## Enregistre une image de chaque démo du Lab (`--lab-capture=<dossier>`).
func _capture_lab() -> void:
	var folder := ProjectSettings.globalize_path(_args["lab-capture"])
	DirAccess.make_dir_recursive_absolute(folder)
	if _args.has("size"):
		var parts: PackedStringArray = _args["size"].split("x")
		get_window().size = Vector2i(parts[0].to_int(), parts[1].to_int())
	_open_lab()
	for i in LabDemos.LIST.size():
		if _args.has("only") and _args["only"].to_int() != i:
			continue
		lab.show_demo(i)
		for frame in _args.get("frames", "60").to_int():
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var file := "%02d_%s.png" % [i, String(LabDemos.LIST[i].source).get_file().get_basename()]
		get_viewport().get_texture().get_image().save_png(folder.path_join(file))
		print("Lab : ", file)


# --- Test automatique des touches --------------------------------------------

func _autotest() -> bool:
	var manager := ctx.manager
	var failures: PackedStringArray = []
	# Chaque fonctionnalité : sa touche la fait passer par tous ses états, puis la coupe.
	manager.go_to(manager.presets[2026], false)
	for feature in manager.features:
		if not feature.available():
			failures.append("%s : indisponible (%s)" % [feature.id, feature.unavailable_reason()])
			continue
		var before := feature.state
		for i in feature.state_count() + 1:
			await _press(feature.key)
			var expected := (before + i + 1) % (feature.state_count() + 1)
			if feature.state != expected:
				failures.append("%s : état %d au lieu de %d" % [feature.id, feature.state, expected])
	# Presets (touches physiques 1 à 5) et frise (flèches, espace).
	var digits: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	var years: Array[int] = [1996, 2001, 2006, 2016, 2026]
	for i in digits.size():
		await _press(digits[i], true)
		if manager.position != manager.presets[years[i]]:
			failures.append("preset %d : position %d" % [years[i], manager.position])
	await _press(KEY_1, true)
	for key: Key in [KEY_RIGHT, KEY_SPACE, KEY_PAGEDOWN, KEY_LEFT]:
		await _press(key)
	if manager.position != 2:
		failures.append("frise : position %d au lieu de 2 après → Espace PageSuiv ←" % manager.position)
	# Caméras et aide.
	for key: Key in [KEY_F2, KEY_F3, KEY_F4, KEY_F1, KEY_ESCAPE, KEY_F9, KEY_ESCAPE]:
		await _press(key)
	# Le Lab : Tab l'ouvre, Page suiv. fait défiler toutes les démos, Tab revient à la scène.
	await _press(KEY_TAB)
	if not lab.is_open():
		failures.append("lab : Tab ne l'ouvre pas")
	var first_demo := lab.index
	for i in LabDemos.LIST.size():
		lab.apply_code()
		lab.reset_code()
		await _press(KEY_PAGEDOWN)
		for frame in 3:
			await get_tree().process_frame
	if lab.index != first_demo:
		failures.append("lab : démo %d au lieu de %d après un tour complet" % [lab.index, first_demo])
	await _press(KEY_TAB)
	if lab.is_open() or get_viewport().disable_3d:
		failures.append("lab : Tab ne revient pas à la scène")
	# Toute la frise, dans les deux sens.
	for at in manager.steps.size() + 1:
		manager.go_to(at)
		await get_tree().process_frame
	for at in range(manager.steps.size(), -1, -1):
		manager.go_to(at)
		await get_tree().process_frame
	print("AUTOTEST : %d fonctionnalités, %d étapes — %s" % [
		manager.features.size(), manager.steps.size(),
		"OK" if failures.is_empty() else "ÉCHECS : " + " ; ".join(failures)])
	return failures.is_empty()


func _press(key: Key, physical := false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.pressed = pressed
		if physical:
			event.physical_keycode = key
		else:
			event.keycode = key
		Input.parse_input_event(event)
		await get_tree().process_frame


func _parse_args() -> Dictionary:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var pair := arg.substr(2).split("=", true, 1)
			args[pair[0]] = pair[1] if pair.size() > 1 else ""
	return args
