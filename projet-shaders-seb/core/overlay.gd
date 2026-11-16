class_name DemoOverlay
extends CanvasLayer
## L'overlay : « année — fonctionnalité » en bas à gauche, la frise des époques
## en haut, le panneau d'aide (Échap) et le compteur d'images (F9).

const ACCENT := Color(1.0, 0.25, 0.6)        # rose néon « PERLIN »
const DIM := Color(1, 1, 1, 0.45)
const ON := "#5dffa0"
const OFF := "#ffffff66"
const TITLE_HOLD := 6.0                      # secondes avant que le titre s'efface

var _manager: EraManager
var _ctx: DemoContext

var _year: Label
var _title: Label
var _note: Label
var _eras: HBoxContainer
var _step: Label
var _help: PanelContainer
var _help_text: RichTextLabel
var _fps: Label
var _toast: Label
var _title_tween: Tween
var _toast_tween: Tween


func setup(ctx: DemoContext) -> void:
	_ctx = ctx
	_manager = ctx.manager
	layer = 10
	_build()
	_manager.announced.connect(_on_announced)
	_manager.changed.connect(_refresh)
	ctx.camera.shot_changed.connect(toast)
	_refresh()


func toggle_help() -> void:
	_help.visible = not _help.visible


func toggle_fps() -> void:
	_fps.visible = not _fps.visible


func toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func show_title(year: int, title: String, note := "") -> void:
	_on_announced(year, title, note)


func _process(_delta: float) -> void:
	if _fps.visible:
		var size := _ctx.pixel_size()
		var ratio := _ctx.viewport.scaling_3d_scale
		_fps.text = "%d img/s · %d×%d · qualité %s" % [
			Engine.get_frames_per_second(), roundi(size.x * ratio), roundi(size.y * ratio), _ctx.quality.level_name()]


func _on_announced(year: int, title: String, note: String) -> void:
	_year.text = str(year)
	_title.text = title
	_note.text = note
	_note.visible = note != ""
	_title.modulate.a = 1.0
	if _title_tween != null:
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.tween_interval(TITLE_HOLD)
	_title_tween.tween_property(_title, "modulate:a", 0.0, 1.0)


func _refresh() -> void:
	# Frise des époques : l'époque courante en rose, les autres en gris.
	var era := _manager.current_era()
	for label: Label in _eras.get_children():
		var current := label.text == str(era)
		label.add_theme_color_override("font_color", ACCENT if current else DIM)
	_step.text = "étape %d / %d" % [_manager.position, _manager.steps.size()]
	# Panneau d'aide : chaque fonctionnalité avec sa touche et son état.
	var lines: PackedStringArray = []
	var last_year := 0
	for feature in _manager.features:
		var decade := _decade_of(feature)
		if decade != last_year:
			last_year = decade
			lines.append("\n[color=#ff409a][b]%s[/b][/color]" % _decade_title(decade))
		var state := ""
		if feature.is_on() and feature.state_count() > 1:
			state = "  %d/%d" % [feature.state, feature.state_count()]
		if not feature.available():
			state = "  [color=#ffb040](à préparer)[/color]"
		lines.append("[color=%s]%s[/color]  [b]%s[/b]  %s%s" % [
			ON if feature.is_on() else OFF, "●" if feature.is_on() else "○",
			OS.get_keycode_string(feature.key), feature.label, state])
	lines.append("\n[color=#ff409a][b]Pilotage[/b][/color]")
	lines.append("[b]→ ←[/b] ou [b]Espace[/b]  étape suivante / précédente")
	lines.append("[b]1 2 3 4 5[/b]  presets 1996 · 2001 · 2006 · 2016 · 2026")
	lines.append("[b]F1…F4[/b]  caméras    [b]clic droit[/b]  vue libre (ZQSD)")
	lines.append("[b]Tab[/b]  le Lab : le code des shaders, en direct")
	lines.append("[b]Échap[/b]  cette aide    [b]F9[/b]  img/s    [b]F7[/b]  qualité    [b]F11[/b]  plein écran")
	_help_text.text = "\n".join(lines).strip_edges()


func _decade_of(feature: DemoFeature) -> int:
	var path: String = (feature.get_script() as Script).resource_path
	return path.get_base_dir().get_file().to_int()


func _decade_title(decade: int) -> String:
	match decade:
		1996: return "1996 · avant les shaders"
		2001: return "2001-2006 · du câblé au programmable"
		2006: return "2006-2016 · la course au réalisme"
		_: return "2016-2026 · la lumière simulée"


# --- Construction de l'interface --------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# En bas à gauche : l'année en grand, le titre de l'étape dessous.
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.position = Vector2(64, -56)
	box.add_theme_constant_override("separation", -6)
	root.add_child(box)
	_year = _label(132, ACCENT, 10)
	_title = _label(40, Color.WHITE, 8)
	_title.custom_minimum_size.x = 1500
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note = _label(26, Color(1.0, 0.7, 0.25), 6)
	box.add_child(_year)
	box.add_child(_title)
	box.add_child(_note)

	# En haut à gauche : la frise des cinq époques.
	var top := HBoxContainer.new()
	top.position = Vector2(64, 40)
	top.add_theme_constant_override("separation", 28)
	root.add_child(top)
	_eras = HBoxContainer.new()
	_eras.add_theme_constant_override("separation", 28)
	top.add_child(_eras)
	for year: int in [1996, 2001, 2006, 2016, 2026]:
		var label := _label(30, DIM, 6)
		label.text = str(year)
		_eras.add_child(label)
	_step = _label(20, DIM, 4)
	_step.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_step)

	# À la suite : le compteur d'images (F9).
	_fps = _label(20, Color(1, 1, 1, 0.8), 4)
	_fps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_fps.visible = false
	top.add_child(_fps)

	# En bas à droite : nom de la caméra, messages brefs.
	_toast = _label(28, Color.WHITE, 6)
	_toast.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.position = Vector2(-64, -64)
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	# À droite : le panneau d'aide.
	_help = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.88)
	style.border_color = ACCENT
	style.border_width_left = 3
	style.set_content_margin_all(22)
	_help.add_theme_stylebox_override("panel", style)
	_help.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_help.custom_minimum_size.x = 620
	_help.visible = false
	root.add_child(_help)
	_help_text = RichTextLabel.new()
	_help_text.bbcode_enabled = true
	_help_text.scroll_active = false
	_help_text.add_theme_font_size_override("normal_font_size", 19)
	_help_text.add_theme_font_size_override("bold_font_size", 19)
	_help.add_child(_help_text)


func _label(font_size: int, color: Color, outline: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", outline)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
