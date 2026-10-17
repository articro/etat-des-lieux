## presence.gd — la Présence, version simplifiée V1 (G-8). Module Gameplay.
##
## PLAN_HALLOWEEN §1 : photo_only → offscreen → une apparition physique finale.
## Pas de NavMesh, pas de poursuite : quand HouseDirector passe l'état à
## "physical", la Présence apparaît et avance en ligne droite vers le joueur
## (0,45 m/s). Photographiée, elle est figée 4 s. Au contact : player_caught.
##
## La position du joueur est obtenue via le groupe "player" (convention de
## scène, pas d'accès de nœud inter-module). L'état vient uniquement de
## EventBus.presence_state_changed, émis par HouseDirector.
class_name Presence
extends CharacterBody3D

const MOVE_SPEED: float = 0.45
const CATCH_DISTANCE: float = 1.1
const PHOTO_HALF_ANGLE_DEG: float = 32.0
const PHOTO_MAX_DISTANCE: float = 25.0
const GRAVITY: float = 9.8
const PLAYER_GROUP: StringName = &"player"

## Durée du figeage quand la Présence est photographiée (4 s, GDD §4.1).
@export var freeze_time: float = 4.0

var _state: StringName = &"dormant"
var _freeze_left: float = 0.0
var _caught: bool = false
var _standalone: bool = false
var _standalone_target: Vector3 = Vector3.ZERO
var _player: Node3D = null

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $Collision
@onready var _stand_camera: Camera3D = $StandaloneCamera
@onready var _stand_floor: MeshInstance3D = $StandaloneFloor
@onready var _stand_body: StaticBody3D = $StandaloneFloor/Body
@onready var _stand_lamp: OmniLight3D = $StandaloneLamp


func _ready() -> void:
	add_to_group(&"presence")
	EventBus.presence_state_changed.connect(_on_presence_state_changed)
	EventBus.photo_taken.connect(_on_photo_taken)
	_apply_state(&"dormant")
	_standalone = get_tree().current_scene == self
	if _standalone:
		_enable_standalone()


func _physics_process(delta: float) -> void:
	if _state != &"physical":
		return
	if _freeze_left > 0.0:
		_freeze_left = maxf(0.0, _freeze_left - delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var target: Variant = _target_position()
	if target == null:
		return
	var target_point: Vector3 = target
	var to_target := target_point - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= CATCH_DISTANCE:
		_try_catch()
		return
	if distance > 0.01:
		var direction := to_target / distance
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


# --- API de test / intégration -----------------------------------------------

func set_state(state: StringName) -> void:
	_apply_state(state)


func is_active() -> bool:
	return _state == &"physical"


func is_frozen() -> bool:
	return _freeze_left > 0.0


# --- Interne ------------------------------------------------------------------

func _apply_state(state: StringName) -> void:
	_state = state
	var active := state == &"physical"
	_mesh.visible = active
	_collision.disabled = not active
	if not active:
		velocity = Vector3.ZERO
		_freeze_left = 0.0


func _target_position() -> Variant:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if _player != null:
		return _player.global_position
	if _standalone:
		return _standalone_target
	return null


func _try_catch() -> void:
	if _caught:
		return
	_caught = true
	EventBus.player_caught.emit()


func _on_presence_state_changed(state: StringName) -> void:
	_apply_state(state)


## Figée 4 s si elle apparaît sur la photo (test angulaire + distance).
func _on_photo_taken(photo: PhotoData) -> void:
	if _state != &"physical" or _freeze_left > 0.0:
		return
	if _was_in_photo(photo):
		_freeze_left = freeze_time


func _was_in_photo(photo: PhotoData) -> bool:
	if photo == null:
		return false
	var camera_transform := photo.camera_transform
	var target := global_position + Vector3(0.0, 1.0, 0.0)
	var to_target := target - camera_transform.origin
	var distance := to_target.length()
	if distance < 0.01 or distance > PHOTO_MAX_DISTANCE:
		return false
	var forward := -camera_transform.basis.z
	var cosine := forward.dot(to_target / distance)
	return cosine >= cos(deg_to_rad(PHOTO_HALF_ANGLE_DEG))


func _enable_standalone() -> void:
	_stand_camera.current = true
	_stand_floor.visible = true
	_stand_body.collision_layer = 1
	_stand_lamp.visible = true
	_standalone_target = _stand_camera.global_position
	_apply_state(&"physical")
