class_name CameraRig
extends Camera3D
## La caméra de la démo : glisse d'un cadrage Blender (`Cam_*`) à l'autre,
## avec une vue libre pour aller montrer un détail.
##
## F1…F4 : cadrages Hero, Flaque, Atrium, Hologramme.
## Clic droit maintenu : vue libre (souris pour regarder, ZQSD pour avancer,
## A / E pour descendre / monter, Maj pour aller plus vite).

signal shot_changed(shot_name: String)

const SHOTS: Array[String] = ["Cam_Hero", "Cam_Puddle", "Cam_Atrium", "Cam_Hologram"]
const SHOT_LABELS: Array[String] = ["Plan principal", "La flaque", "L'atrium", "L'hologramme"]
const TRAVEL_TIME := 1.4
const FLY_SPEED := 3.0
const MOUSE_SENSITIVITY := 0.0025

## Vrai tant que le clic droit est maintenu : le clavier sert alors à se déplacer.
var flying := false

var _shots: Array[Camera3D] = []
var _tween: Tween
var _yaw := 0.0
var _pitch := 0.0


func setup(world: Node3D) -> void:
	name = "DemoCamera"
	for shot_name in SHOTS:
		var shot := world.get_node_or_null(shot_name) as Camera3D
		if shot != null:
			_shots.append(shot)
	near = 0.05
	far = 500.0
	go(0, true)
	make_current()


func go(index: int, instant := false) -> void:
	if index < 0 or index >= _shots.size():
		return
	var target := _shots[index]
	if _tween != null:
		_tween.kill()
	if instant:
		global_transform = target.global_transform
		fov = target.fov
	else:
		var from := global_transform
		var from_fov := fov
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_method(func(t: float) -> void:
			global_transform = from.interpolate_with(target.global_transform, t)
			fov = lerpf(from_fov, target.fov, t), 0.0, 1.0, TRAVEL_TIME)
	shot_changed.emit(SHOT_LABELS[SHOTS.find(String(target.name))])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1: go(0)
			KEY_F2: go(1)
			KEY_F3: go(2)
			KEY_F4: go(3)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		flying = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if flying else Input.MOUSE_MODE_VISIBLE
		if flying:
			if _tween != null:
				_tween.kill()
			_yaw = rotation.y
			_pitch = rotation.x
	elif event is InputEventMouseMotion and flying:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0.0)


func _process(delta: float) -> void:
	if not flying:
		return
	# Touches physiques : ZQSD sur un AZERTY, WASD sur un QWERTY.
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): move.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S): move.z += 1.0
	if Input.is_physical_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): move.x += 1.0
	if Input.is_physical_key_pressed(KEY_Q): move.y -= 1.0
	if Input.is_physical_key_pressed(KEY_E): move.y += 1.0
	var speed := FLY_SPEED * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	global_position += global_transform.basis * move.normalized() * speed * delta
