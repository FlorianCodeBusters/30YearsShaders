class_name ShaderLab
extends CanvasLayer
## Le Lab : à gauche ce que produit un shader, à droite son code, modifiable en direct.
##
## Tab                    ouvrir / fermer (la démo reprend où elle en était)
## Page suiv. / préc.     démo suivante / précédente
## Ctrl + ← / →           décennie précédente / suivante
## Ctrl + Entrée (ou S)   appliquer le code modifié
## Ctrl + R               revenir au code d'origine
##
## Deux sortes de fichiers : les shaders de Godot (.gdshader, .gdshaderinc), qui
## sont des ressources du moteur, et les compute shaders (.glsl), compilés ici
## depuis leur texte, ce qui permet d'afficher leurs erreurs de compilation.
##
## Les modifications restent en mémoire (rien n'est écrit sur le disque). Pour les
## shaders de la démo (Perlin, hologramme, tramage), elles se voient aussi dans
## la scène en revenant avec Tab.
## Les démos sont listées dans `lab/demos.gd`.

signal closed

const ACCENT := Color(1.0, 0.25, 0.6)
const PERLIN_FEATURE := preload("res://features/2001/perlin.gd")
const BRICK_COLOR := "res://assets/scene/atrium_kit_Bricks097_1K-JPG_Color.jpg"
const BRICK_NORMAL := "res://assets/scene/atrium_kit_Bricks097_1K-JPG_NormalGL.jpg"
const DECADE_TITLES := {
	1996: "1996 · avant les shaders",
	2001: "2001-2006 · du câblé au programmable",
	2006: "2006-2016 · la course au réalisme",
	2016: "2016-2026 · la lumière simulée",
}

var index := 0

var _ctx: DemoContext
var _viewport: SubViewport
var _camera: Camera3D
var _env: Environment
var _stage: Node3D
var _screen: CanvasLayer
var _decade: Label
var _title: Label
var _note: Label
var _file: Label
var _status: Label
var _editor: CodeEdit

## Le shader (ou l'include) affiché dans l'éditeur. `null` pour un compute shader.
var _resource: Resource
## Code d'origine de chaque fichier ouvert, pour Ctrl + R.
var _original := {}
## Texte courant des compute shaders (.glsl), par fichier.
var _glsl := {}
## La démo de compute shader en cours, s'il y en a une.
var _boids: LabBoids


func setup(ctx: DemoContext) -> void:
	_ctx = ctx
	layer = 20
	visible = false
	_build_view()
	_build_ui()


func is_open() -> bool:
	return visible


## Ouvre le Lab sur la décennie donnée (on reste sur la démo courante si elle en fait partie).
func open(decade: int) -> void:
	if LabDemos.LIST[index].decade != decade:
		for i in LabDemos.LIST.size():
			if LabDemos.LIST[i].decade == decade:
				index = i
				break
	visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	show_demo(index)


func close() -> void:
	visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_editor.release_focus()
	closed.emit()


func show_demo(target: int) -> void:
	index = posmod(target, LabDemos.LIST.size())
	var demo := LabDemos.LIST[index]

	_boids = null
	if String(demo.source).ends_with(".glsl"):
		_resource = null
		if not _glsl.has(demo.source):
			_original[demo.source] = FileAccess.get_file_as_string(demo.source)
			_glsl[demo.source] = _original[demo.source]
		_editor.text = _glsl[demo.source]
	else:
		_resource = load(demo.source)
		if not _original.has(demo.source):
			_original[demo.source] = _resource.get("code")
		_editor.text = _resource.get("code")
	_editor.clear_undo_history()
	_editor.set_caret_line(0)
	_editor.scroll_vertical = 0

	var position_in_decade := 0
	var count_in_decade := 0
	for i in LabDemos.LIST.size():
		if LabDemos.LIST[i].decade == demo.decade:
			count_in_decade += 1
			if i <= index:
				position_in_decade += 1
	_decade.text = "%s    %d / %d" % [DECADE_TITLES[demo.decade], position_in_decade, count_in_decade]
	_title.text = "%d — %s" % [demo.year, demo.title]
	_note.text = demo.note
	_note.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_file.text = String(demo.source).trim_prefix("res://")
	_set_status("")

	_reset_stage()
	call("_stage_" + String(demo.stage), demo)


func next_demo() -> void:
	show_demo(index + 1)


func previous_demo() -> void:
	show_demo(index - 1)


## Saute à la première démo de la décennie suivante (ou précédente).
func jump_decade(direction: int) -> void:
	var decades: Array = DECADE_TITLES.keys()
	var current: int = decades.find(LabDemos.LIST[index].decade)
	var wanted: int = decades[posmod(current + direction, decades.size())]
	for i in LabDemos.LIST.size():
		if LabDemos.LIST[i].decade == wanted:
			show_demo(i)
			return


func apply_code() -> void:
	if _resource != null:
		_resource.set("code", _editor.text)
		_set_status("Appliqué")
	else:
		_compile_glsl(_editor.text, "Appliqué")


func reset_code() -> void:
	var source: String = LabDemos.LIST[index].source
	_editor.text = _original[source]
	if _resource != null:
		_resource.set("code", _original[source])
		_set_status("Code d'origine rétabli")
	else:
		_compile_glsl(_original[source], "Code d'origine rétabli")


## Compile un compute shader. En cas d'erreur, l'ancien continue de tourner et le
## message du compilateur s'affiche sous le rendu.
func _compile_glsl(code: String, done: String) -> void:
	var demo := LabDemos.LIST[index]
	var error := _boids.set_code(code) if _boids != null else ""
	if error == "":
		_glsl[demo.source] = code
		_note.text = demo.note
		_note.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_set_status(done)
	else:
		_note.text = error.strip_edges().left(260)
		_note.add_theme_color_override("font_color", Color(1.0, 0.55, 0.3))
		_set_status("Erreur de compilation")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var handled := true
	if key.keycode == KEY_TAB and not key.echo:
		close()
	elif key.keycode == KEY_PAGEDOWN:
		next_demo()
	elif key.keycode == KEY_PAGEUP:
		previous_demo()
	elif key.ctrl_pressed and key.keycode == KEY_RIGHT:
		jump_decade(1)
	elif key.ctrl_pressed and key.keycode == KEY_LEFT:
		jump_decade(-1)
	elif key.ctrl_pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_S]:
		apply_code()
	elif key.ctrl_pressed and key.keycode == KEY_R:
		reset_code()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _set_status(text: String) -> void:
	_status.text = text


# --- Décors -----------------------------------------------------------------

func _reset_stage() -> void:
	for child in _stage.get_children():
		child.queue_free()
	for child in _screen.get_children():
		child.queue_free()
	for child in _camera.get_children():
		child.queue_free()
	_viewport.disable_3d = false
	_viewport.use_hdr_2d = false
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_env.glow_enabled = true
	_env.ssr_enabled = false
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.ambient_light_energy = 0.4
	_place_camera(Vector3(0.0, 1.6, 4.6), Vector3(0.0, 0.8, 0.0))


func _place_camera(from: Vector3, target: Vector3) -> void:
	_camera.look_at_from_position(from, target)


## Le matériau de la démo : son shader, plus les paramètres imposés.
func _material(demo: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(demo.get("shader", demo.source))
	var params: Dictionary = demo.get("params", {})
	for parameter: String in params:
		material.set_shader_parameter(parameter, params[parameter])
	return material


func _add_mesh(mesh: Mesh, at: Vector3, material: Material, parent: Node = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.lod_bias = 16.0   # toujours le maillage complet, même vu de loin
	(parent if parent != null else _stage).add_child(instance)
	return instance


func _plain(color: Color, roughness := 0.6, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _plain(Color.BLACK)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


## Une boule à facettes, une boule lisse et un sol de 4 sommets : pour comparer
## l'éclairage par sommet et par pixel.
func _stage_boules(demo: Dictionary) -> void:
	var material := _material(demo)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(9.0, 9.0)
	_add_mesh(floor_mesh, Vector3.ZERO, material)
	var rough := SphereMesh.new()
	rough.radius = 0.85
	rough.height = 1.7
	rough.radial_segments = 10
	rough.rings = 5
	_add_mesh(rough, Vector3(-1.15, 0.85, 0.0), material)
	var smooth := SphereMesh.new()
	smooth.radius = 0.85
	smooth.height = 1.7
	_add_mesh(smooth, Vector3(1.15, 0.85, 0.0), material)
	_place_camera(Vector3(0.0, 2.3, 5.0), Vector3(0.0, 0.6, 0.0))


## Un mur de briques : un simple rectangle, avec ses deux textures.
func _stage_mur(demo: Dictionary) -> void:
	var material := _material(demo)
	material.set_shader_parameter("texture_couleur", load(BRICK_COLOR))
	material.set_shader_parameter("texture_normales", load(BRICK_NORMAL))
	var wall := QuadMesh.new()
	wall.size = Vector2(5.2, 2.6)
	_add_mesh(wall, Vector3(0.0, 1.3, 0.0), material)
	_place_camera(Vector3(1.6, 1.3, 3.2), Vector3(0.0, 1.3, 0.0))


## Le prisme de la scène, avec son vertex shader.
func _stage_hologramme(demo: Dictionary) -> void:
	var prism := _add_mesh(_ctx.node("Prop_Hologram").mesh, Vector3(0.0, 1.25, 0.0), _material(demo))
	prism.scale = Vector3.ONE * 1.8
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(9.0, 9.0)
	_add_mesh(floor_mesh, Vector3.ZERO, _plain(Color(0.05, 0.06, 0.09), 0.3))
	_add_light(Vector3(1.5, 3.0, 2.0), Color(0.6, 0.8, 1.0), 2.0)
	_place_camera(Vector3(0.0, 1.5, 4.0), Vector3(0.0, 1.2, 0.0))


## Une surface d'eau devant trois panneaux lumineux : le bruit seul, ou la flaque.
func _stage_flaque(demo: Dictionary) -> void:
	var water := PlaneMesh.new()
	water.size = Vector2(7.0, 5.0)
	var material := _material(demo)
	# Le bitume de la scène, et un creux au milieu du décor.
	PERLIN_FEATURE.set_ground_textures(material, _ctx)
	material.set_shader_parameter("creux", Vector3(0.0, 0.4, 1.8))
	_add_mesh(water, Vector3.ZERO, material)
	_add_light(Vector3(-1.0, 2.6, 2.0), Color(0.8, 0.85, 1.0), 1.6)
	var panel := BoxMesh.new()
	panel.size = Vector3(0.9, 2.0, 0.12)
	_add_mesh(panel, Vector3(-1.5, 1.3, -2.7), _emissive(Color(1.0, 0.08, 0.5), 4.0))
	_add_mesh(panel, Vector3(0.0, 1.3, -2.7), _emissive(Color(0.05, 0.85, 1.0), 4.0))
	_add_mesh(panel, Vector3(1.5, 1.3, -2.7), _emissive(Color(1.0, 0.8, 0.05), 4.0))
	_env.ssr_enabled = true
	if demo.get("params", {}).get("bruit_seul", false):
		_place_camera(Vector3(0.0, 4.2, 3.4), Vector3(0.0, 0.0, -0.2))
	else:
		_place_camera(Vector3(0.0, 1.5, 4.6), Vector3(0.0, 0.5, 0.0))


## Une nuée de boids simulée par un compute shader (voir `lab/boids.gd`).
func _stage_boids(demo: Dictionary) -> void:
	_viewport.disable_3d = true
	_boids = LabBoids.new()
	_screen.add_child(_boids)
	_compile_glsl(_glsl[demo.source], "")


## L'enseigne PERLIN de la scène.
func _stage_neon(demo: Dictionary) -> void:
	var sign_mesh := _ctx.node("Neon_01").mesh
	var center := sign_mesh.get_aabb().get_center()
	_add_mesh(sign_mesh, Vector3(0.0, 1.45, 0.0) - center, _material(demo))
	var wall := QuadMesh.new()
	wall.size = Vector2(6.0, 4.0)
	_add_mesh(wall, Vector3(0.0, 1.45, -0.25), _plain(Color(0.03, 0.03, 0.05), 0.8))
	_place_camera(Vector3(0.0, 1.45, 3.6), Vector3(0.0, 1.45, 0.0))


## Une petite pièce éclairée par Godot, sur laquelle on pose un shader de post-processing.
func _stage_piece(demo: Dictionary) -> void:
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(9.0, 7.0)
	_add_mesh(floor_mesh, Vector3.ZERO, _plain(Color(0.32, 0.33, 0.36), 0.5))
	var wall := QuadMesh.new()
	wall.size = Vector2(9.0, 4.0)
	var bricks := _plain(Color.WHITE, 0.9)
	bricks.albedo_texture = load(BRICK_COLOR)
	bricks.uv1_scale = Vector3(3.0, 1.5, 1.0)
	_add_mesh(wall, Vector3(0.0, 2.0, -2.2), bricks)
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	_add_mesh(sphere, Vector3(-1.5, 0.6, -0.3), _plain(Color(0.85, 0.25, 0.2), 0.35))
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	_add_mesh(box, Vector3(0.1, 0.5, -1.0), _plain(Color(0.2, 0.4, 0.85), 0.5)).rotation.y = 0.5
	var torus := TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.6
	_add_mesh(torus, Vector3(1.6, 0.3, 0.1), _plain(Color(0.9, 0.7, 0.3), 0.3, 1.0))
	var strip := BoxMesh.new()
	strip.size = Vector3(2.4, 0.12, 0.08)
	_add_mesh(strip, Vector3(-1.6, 2.6, -2.1), _emissive(Color(1.0, 0.08, 0.5), 6.0))
	_add_mesh(strip, Vector3(1.6, 2.2, -2.1), _emissive(Color(0.05, 0.85, 1.0), 6.0))
	_add_light(Vector3(1.2, 3.2, 2.2), Color(1.0, 0.9, 0.75), 3.5)
	_place_camera(Vector3(0.0, 1.7, 4.4), Vector3(0.0, 0.9, -0.5))
	# Le post-processing fait à la main remplace celui de Godot.
	_env.glow_enabled = false
	_add_post_process(_material(demo))


## Deux rangées de boules : la rugosité varie de gauche à droite, le métal de haut en bas.
func _stage_pbr(demo: Dictionary) -> void:
	var material := _material(demo)
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	for row in 2:
		for column in 5:
			var ball := _add_mesh(sphere, Vector3((column - 2) * 0.92, 1.75 - row * 1.05, 0.0), material)
			ball.set_instance_shader_parameter("rugosite", lerpf(0.12, 0.9, column / 4.0))
			ball.set_instance_shader_parameter("metal", float(row))
	_place_camera(Vector3(0.0, 1.25, 4.9), Vector3(0.0, 1.22, 0.0))


## Un shader qui remplit tout l'écran, sans aucune géométrie (path tracing, champs de distances).
func _stage_ecran(demo: Dictionary) -> void:
	_viewport.disable_3d = true
	if demo.get("accumulate", false):
		# On n'efface plus l'image entre deux rendus : le shader se mélange à la précédente.
		_viewport.use_hdr_2d = true
		_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_add_post_process(_material(demo))


func _add_light(at: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 12.0
	light.shadow_enabled = true
	_stage.add_child(light)


## Pose un shader sur l'image : un rectangle 2D (canvas_item) ou un rectangle collé
## devant la caméra (spatial), selon le type du shader.
func _add_post_process(material: ShaderMaterial) -> void:
	if material.shader.get_mode() == Shader.MODE_CANVAS_ITEM:
		var rect := ColorRect.new()
		rect.material = material
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_screen.add_child(rect)
	else:
		var quad := QuadMesh.new()
		quad.size = Vector2(2.0, 2.0)
		var instance := _add_mesh(quad, Vector3.ZERO, material, _camera)
		instance.custom_aabb = AABB(Vector3.ONE * -1000.0, Vector3.ONE * 2000.0)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Construction -----------------------------------------------------------

func _build_view() -> void:
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.02, 0.02, 0.05)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.35, 0.4, 0.55)
	_env.glow_intensity = 0.6
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	_viewport.add_child(world_env)

	_camera = Camera3D.new()
	_camera.fov = 50.0
	_viewport.add_child(_camera)
	_stage = Node3D.new()
	_viewport.add_child(_stage)
	_screen = CanvasLayer.new()
	_viewport.add_child(_screen)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.025, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	margin.add_child(columns)

	# Colonne de gauche : titre, rendu, explication.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)
	_decade = _label(24, ACCENT)
	_title = _label(34, Color.WHITE)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_decade)
	left.add_child(_title)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_child(_viewport)
	left.add_child(view)
	_note = _label(24, Color(1, 1, 1, 0.85))
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size.y = 66
	left.add_child(_note)

	# Colonne de droite : le fichier, son code, les raccourcis.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)
	var header := HBoxContainer.new()
	right.add_child(header)
	_file = _label(20, Color(1, 1, 1, 0.6))
	_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_file)
	_status = _label(20, Color(0.36, 1.0, 0.63))
	header.add_child(_status)
	_editor = _build_editor()
	right.add_child(_editor)
	var help := _label(18, Color(1, 1, 1, 0.55))
	help.text = "Ctrl+Entrée appliquer · Ctrl+R code d'origine · Page suiv./préc. démo · Ctrl+←/→ décennie · Tab retour à la scène"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(help)


func _build_editor() -> CodeEdit:
	var editor := CodeEdit.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.gutters_draw_line_numbers = true
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.indent_automatic = true
	editor.auto_brace_completion_enabled = true
	editor.highlight_current_line = true
	editor.text_changed.connect(func() -> void: _set_status("Modifié — Ctrl+Entrée pour appliquer"))

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "Courier New", "monospace"])
	editor.add_theme_font_override("font", font)
	editor.add_theme_font_size_override("font_size", 19)
	editor.add_theme_color_override("background_color", Color(0.055, 0.05, 0.095))
	editor.add_theme_color_override("font_color", Color(0.88, 0.9, 0.95))
	editor.add_theme_color_override("current_line_color", Color(1, 1, 1, 0.05))
	editor.add_theme_color_override("line_number_color", Color(1, 1, 1, 0.3))

	# Coloration syntaxique minimale du langage de shaders.
	var colors := CodeHighlighter.new()
	colors.number_color = Color(1.0, 0.75, 0.4)
	colors.symbol_color = Color(0.75, 0.8, 0.9)
	colors.function_color = Color(0.45, 0.85, 1.0)
	colors.member_variable_color = Color(0.88, 0.9, 0.95)
	colors.add_color_region("//", "", Color(0.5, 0.62, 0.55), true)
	colors.add_color_region("\"", "\"", Color(1.0, 0.85, 0.5))
	for word: String in ["shader_type", "render_mode", "uniform", "varying", "const", "instance",
			"void", "return", "if", "else", "for", "while", "break", "in", "out", "inout",
			"true", "false", "#include", "#version", "layout", "struct", "buffer", "continue",
			"restrict", "readonly", "writeonly", "std430", "std140"]:
		colors.add_keyword_color(word, ACCENT)
	for word: String in ["float", "int", "bool", "vec2", "vec3", "vec4", "ivec2", "mat2", "mat3",
			"mat4", "sampler2D", "uint"]:
		colors.add_keyword_color(word, Color(0.6, 0.75, 1.0))
	for word: String in ["VERTEX", "NORMAL", "TANGENT", "BINORMAL", "UV", "ALBEDO", "EMISSION",
			"ROUGHNESS", "SPECULAR", "COLOR", "TIME", "PI", "TAU", "POSITION", "SCREEN_UV",
			"FRAGCOORD", "VIEW", "MODEL_MATRIX", "MODEL_NORMAL_MATRIX", "VIEW_MATRIX",
			"INV_VIEW_MATRIX", "PROJECTION_MATRIX", "INV_PROJECTION_MATRIX",
			"CAMERA_POSITION_WORLD", "SCREEN_PIXEL_SIZE", "METALLIC", "NORMAL_MAP",
			"NORMAL_MAP_DEPTH", "gl_GlobalInvocationID"]:
		colors.add_keyword_color(word, Color(1.0, 0.6, 0.35))
	editor.syntax_highlighter = colors
	return editor


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
