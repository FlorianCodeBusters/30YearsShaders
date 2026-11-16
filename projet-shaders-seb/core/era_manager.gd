class_name EraManager
extends Node
## Gestionnaire d'époques : instancie les fonctionnalités, déroule la frise,
## gère les presets et les touches.
##
## Trois façons de piloter la démo :
##  - → / ← (ou Espace, ou une télécommande de présentation) : étape suivante / précédente ;
##  - 1 à 5 : sauter au preset 1996, 2001, 2006, 2016, 2026 ;
##  - la touche d'une fonctionnalité : la basculer seule, pour un avant / après.
## Revenir sur la frise (→, ← ou un preset) remet tout dans l'état de l'étape.

## Émis à chaque changement visible : année, titre, et une note éventuelle (bake manquant…).
signal announced(year: int, title: String, note: String)
## Émis quand l'état d'au moins une fonctionnalité a changé.
signal changed

const PRESET_KEYS := {KEY_1: 1996, KEY_2: 2001, KEY_3: 2006, KEY_4: 2016, KEY_5: 2026}

var features: Array[DemoFeature] = []
var steps: Array[Dictionary] = Timeline.STEPS
## Position dans la frise : 0 = preset 1996, n = après la n-ième étape.
var position := 0
## Année du preset → position dans la frise.
var presets := {1996: 0}

var _by_id := {}
var _by_key := {}
var _ctx: DemoContext


func setup(ctx: DemoContext) -> void:
	_ctx = ctx
	for script in Timeline.FEATURES:
		var feature: DemoFeature = script.new()
		feature.ctx = ctx
		features.append(feature)
		_by_id[feature.id] = feature
		if feature.key != KEY_NONE:
			assert(not _by_key.has(feature.key), "Touche en double : " + feature.id)
			_by_key[feature.key] = feature
	for i in steps.size():
		for id: String in steps[i].states:
			assert(_by_id.has(id), "Frise : fonctionnalité inconnue « %s »" % id)
		if steps[i].has("preset"):
			presets[steps[i].preset] = i + 1
	for feature in features:
		feature._setup()
	go_to(0, false)


func feature(id: String) -> DemoFeature:
	return _by_id.get(id)


func state_of(id: String) -> int:
	var found: DemoFeature = _by_id.get(id)
	return found.state if found != null else 0


## Réapplique une fonctionnalité sans changer son état (quand un réglage dont elle dépend a bougé).
func refresh(id: String) -> void:
	var found: DemoFeature = _by_id.get(id)
	if found != null:
		found._apply()


# --- Frise ------------------------------------------------------------------

## État de toutes les fonctionnalités à une position de la frise.
func states_at(target: int) -> Dictionary:
	var result := {}
	for found in features:
		result[found.id] = found.baseline
	for i in target:
		result.merge(steps[i].states, true)
	return result


func go_to(target: int, announce := true) -> void:
	position = clampi(target, 0, steps.size())
	var wanted := states_at(position)
	var note := ""
	for found in features:
		var blocked := _set_state(found, wanted[found.id])
		if blocked != "" and position > 0 and steps[position - 1].states.has(found.id):
			note = blocked
	_after_change()
	if announce:
		announced.emit(year_at(position), title_at(position), note)


func next() -> void:
	go_to(position + 1)


func previous() -> void:
	go_to(position - 1)


func goto_preset(year: int) -> void:
	if presets.has(year):
		go_to(presets[year])


func year_at(at: int) -> int:
	return Timeline.START_YEAR if at <= 0 else steps[at - 1].year


func title_at(at: int) -> String:
	if at <= 0:
		return Timeline.START_TITLE
	var step := steps[at - 1]
	if step.get("title", "") != "":
		return step.title
	var id: String = step.states.keys()[0]
	return feature(id).title(step.states[id])


## L'époque dans laquelle on se trouve : la dernière borne (1996, 2001, 2006,
## 2016, 2026) atteinte, soit par l'année de l'étape courante, soit parce qu'on
## est arrivé au preset de cette borne.
func current_era() -> int:
	var era := 1996
	for year: int in presets:
		if (year <= year_at(position) or presets[year] <= position) and year > era:
			era = year
	return era


# --- Bascule à la main ------------------------------------------------------

## Passe une fonctionnalité à l'état suivant (coupée → 1 → 2 → … → coupée).
func toggle(found: DemoFeature) -> void:
	var blocked := _set_state(found, (found.state + 1) % (found.state_count() + 1))
	_after_change()
	announced.emit(found.year, found.title(), blocked)


func _set_state(found: DemoFeature, wanted: int) -> String:
	var blocked := ""
	if wanted > 0 and not found.available():
		blocked = found.unavailable_reason()
		wanted = 0
	if wanted != found.state or not found.has_meta(&"applied"):
		found.state = wanted
		found.set_meta(&"applied", true)
		found._apply()
	return blocked


func _after_change() -> void:
	_ctx.refresh_probe()
	changed.emit()


# --- Entrées ----------------------------------------------------------------

func _process(delta: float) -> void:
	for found in features:
		if found.state > 0:
			found._process(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if _ctx.camera.flying or key_event.ctrl_pressed or key_event.alt_pressed:
		return
	# Chiffres : touche physique, pour que la rangée du haut marche en AZERTY sans Maj.
	if PRESET_KEYS.has(key_event.physical_keycode):
		goto_preset(PRESET_KEYS[key_event.physical_keycode])
	elif key_event.keycode in [KEY_RIGHT, KEY_SPACE, KEY_PAGEDOWN]:
		next()
	elif key_event.keycode in [KEY_LEFT, KEY_PAGEUP]:
		previous()
	elif _by_key.has(key_event.keycode):
		toggle(_by_key[key_event.keycode])
	else:
		return
	get_viewport().set_input_as_handled()
