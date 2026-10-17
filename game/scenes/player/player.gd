## player.gd — contrôleur première personne (G-1). Module Gameplay.
##
## GDD §4.5 : marche 2,5 m/s, course 4 m/s limitée par l'essoufflement,
## accroupi (maintenu), pas de saut. ZQSD et QWERTY via physical_keycode.
## Aucune interaction avec un autre module hors EventBus et API des autoloads.
## Aucun texte affiché ici : le module n'a pas de chaîne à traduire.
class_name PlayerController
extends CharacterBody3D

const WALK_SPEED: float = 2.5
const RUN_SPEED: float = 4.0
const CROUCH_SPEED: float = 1.3
const GROUND_ACCEL: float = 14.0
const GROUND_BRAKE: float = 18.0
const AIR_ACCEL: float = 2.0
const GRAVITY: float = 9.8

const STAMINA_MAX: float = 100.0
const STAMINA_DRAIN: float = 18.0
const STAMINA_REGEN: float = 12.0
const EXHAUST_RECOVER: float = 30.0

const STAND_HEIGHT: float = 1.75
const CROUCH_HEIGHT: float = 1.10
const EYE_OFFSET: float = 0.15
const CROUCH_LERP: float = 9.0

const PITCH_LIMIT: float = 1.45
const BOB_FREQUENCY: float = 8.0
const BOB_AMPLITUDE: float = 0.018
const STEP_LENGTH_WALK: float = 0.72
const STEP_LENGTH_RUN: float = 1.05
const NOISE_WALK: float = 0.25
const NOISE_RUN: float = 0.85

const FALL_RESET_Y: float = -25.0

# --- Réglages (EventBus.settings_changed, ARCHITECTURE §4 et §7) ---
const SETTING_SENSITIVITY: StringName = &"mouse_sensitivity"
const SETTING_FOV: StringName = &"fov"
const SETTING_FLASHLIGHT_STRONG: StringName = &"flashlight_strong"

## La sensibilité arrive normalisée 0..1 (curseur UI) et devient des rad/px.
## Une valeur < 0.02 est prise comme des rad/px bruts (compatibilité).
const SENSITIVITY_NORMALIZED_MIN: float = 0.0006
const SENSITIVITY_NORMALIZED_MAX: float = 0.0080
const SENSITIVITY_RAW_THRESHOLD: float = 0.02
const SENSITIVITY_RAW_MIN: float = 0.0004
const SENSITIVITY_RAW_MAX: float = 0.0120
const FOV_MIN: float = 55.0
const FOV_MAX: float = 110.0

## Sensibilité souris (rad/px). Pilotée par l'option UI (settings_changed).
@export var mouse_sensitivity: float = 0.0022
@export var base_fov: float = 75.0

var _pitch: float = 0.0
var _stamina: float = STAMINA_MAX
var _exhausted: bool = false
var _crouching: bool = false
var _bob_phase: float = 0.0
var _step_accum: float = 0.0
var _input_enabled: bool = true
var _spawn: Transform3D
var _standalone: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _collision: CollisionShape3D = $Collision
@onready var _capsule: CapsuleShape3D = _collision.shape as CapsuleShape3D
@onready var _standalone_floor: MeshInstance3D = $StandaloneFloor
@onready var _standalone_body: StaticBody3D = $StandaloneFloor/Body


func _ready() -> void:
	add_to_group(&"player")
	InputActions.ensure_defaults()
	_spawn = global_transform
	_apply_height(STAND_HEIGHT)
	_camera.fov = base_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.settings_changed.connect(_on_settings_changed)
	# Lancée seule (F6) : un sol de secours évite une chute infinie.
	_standalone = get_tree().current_scene == self
	_standalone_floor.visible = _standalone
	_standalone_body.collision_layer = 1 if _standalone else 0


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -PITCH_LIMIT, PITCH_LIMIT)
		_head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector2.ZERO
	if _input_enabled:
		input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var wish := global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	wish.y = 0.0
	var moving := wish.length() > 0.05
	if moving:
		wish = wish.normalized()

	var want_run := _input_enabled and Input.is_action_pressed(&"sprint") and not _crouching and moving
	_update_stamina(delta, want_run)
	var speed := WALK_SPEED
	if _crouching:
		speed = CROUCH_SPEED
	elif want_run and not _exhausted:
		speed = RUN_SPEED

	var target := wish * speed
	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if not moving:
		accel = GROUND_BRAKE
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)

	move_and_slide()
	_update_crouch(delta)
	_update_head_bob(delta)
	_reset_if_fallen()


## Accroupissement maintenu (Ctrl ou C), interpolé sur la capsule et la tête.
func _update_crouch(delta: float) -> void:
	_crouching = _input_enabled and is_on_floor() and Input.is_action_pressed(&"crouch")
	var target_height := CROUCH_HEIGHT if _crouching else STAND_HEIGHT
	var height := lerpf(_capsule.height, target_height, clampf(CROUCH_LERP * delta, 0.0, 1.0))
	_apply_height(height)


func _apply_height(height: float) -> void:
	_capsule.height = height
	_collision.position.y = height * 0.5
	_head.position.y = height - EYE_OFFSET


## Head-bob discret + bruit de pas émis sur player_noise (Audio : D-3).
func _update_head_bob(delta: float) -> void:
	var planar := Vector2(velocity.x, velocity.z).length()
	var walking := is_on_floor() and planar > 0.2
	if walking:
		_bob_phase += delta * BOB_FREQUENCY * (planar / WALK_SPEED)
		_step_accum += planar * delta
		var stride := STEP_LENGTH_RUN if planar > WALK_SPEED + 0.2 else STEP_LENGTH_WALK
		if _step_accum >= stride:
			_step_accum = 0.0
			var level := NOISE_RUN if planar > WALK_SPEED + 0.2 else NOISE_WALK
			EventBus.player_noise.emit(level, global_position)
	else:
		_bob_phase = lerpf(_bob_phase, 0.0, clampf(delta * 4.0, 0.0, 1.0))
	var amplitude := BOB_AMPLITUDE * (0.4 if _crouching else 1.0)
	_camera.position.y = sin(_bob_phase * 2.0) * amplitude
	_camera.rotation.z = sin(_bob_phase) * 0.006


func _update_stamina(delta: float, running: bool) -> void:
	if running:
		_stamina = maxf(0.0, _stamina - STAMINA_DRAIN * delta)
		if _stamina <= 0.0:
			_exhausted = true
	else:
		_stamina = minf(STAMINA_MAX, _stamina + STAMINA_REGEN * delta)
		if _exhausted and _stamina >= EXHAUST_RECOVER:
			_exhausted = false


func _reset_if_fallen() -> void:
	if global_position.y < FALL_RESET_Y:
		global_transform = _spawn
		velocity = Vector3.ZERO
		push_warning("PlayerController : chute hors carte, retour au point d'apparition.")


## Réglages émis par l'UI (menu Options) — on ignore en silence les clés qui ne
## concernent pas le joueur (volumes, sous-titres, plein écran…).
func _on_settings_changed(key: StringName, value: Variant) -> void:
	match key:
		SETTING_SENSITIVITY:
			_apply_sensitivity(value)
		SETTING_FOV:
			_apply_fov(value)
		SETTING_FLASHLIGHT_STRONG:
			var lamp := get_node_or_null("Head/Camera/Flashlight")
			if lamp != null and lamp.has_method(&"set_strong"):
				lamp.call(&"set_strong", bool(value))


func _apply_sensitivity(value: Variant) -> void:
	if not (value is float or value is int):
		push_warning("PlayerController : sensibilité ignorée (valeur non numérique).")
		return
	var raw := float(value)
	if raw <= 0.0:
		return
	if raw < SENSITIVITY_RAW_THRESHOLD:
		mouse_sensitivity = clampf(raw, SENSITIVITY_RAW_MIN, SENSITIVITY_RAW_MAX)
	else:
		mouse_sensitivity = lerpf(
			SENSITIVITY_NORMALIZED_MIN, SENSITIVITY_NORMALIZED_MAX, clampf(raw, 0.0, 1.0))


func _apply_fov(value: Variant) -> void:
	if not (value is float or value is int):
		push_warning("PlayerController : FOV ignoré (valeur non numérique).")
		return
	base_fov = clampf(float(value), FOV_MIN, FOV_MAX)
	_camera.fov = base_fov


func _on_pause_toggled(paused: bool) -> void:
	_input_enabled = not paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


# --- API interne au module ---------------------------------------------------

func get_eye_camera() -> Camera3D:
	return _camera


func is_crouching() -> bool:
	return _crouching


func is_exhausted() -> bool:
	return _exhausted


func stamina_ratio() -> float:
	return _stamina / STAMINA_MAX


func is_standalone() -> bool:
	return _standalone


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


## Réglages appliqués (lecture seule, pour les tests et l'UI).
func get_base_fov() -> float:
	return base_fov


func get_sensitivity() -> float:
	return mouse_sensitivity
