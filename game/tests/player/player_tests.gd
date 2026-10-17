## player_tests.gd — vérifications headless du module Gameplay (sans gdUnit4).
##
## Lancement : godot --headless --path game res://tests/player/player_tests.tscn
## Code de sortie 0 si tout passe, 1 sinon. gdUnit4 n'est pas encore installé
## (tâche Q-1) : ce runner manuel tient le rôle en attendant, et ne dépend que
## de l'API publique (EventBus, scène de test du module).
extends Node

const ROOM_SCENE: PackedScene = preload("res://scenes/player/test_room.tscn")
const EXPECTED_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"sprint", &"crouch", &"interact", &"flashlight",
	&"camera_raise", &"camera_shoot", &"photo_review", &"notebook", &"pause",
]
const PHYSICS_STEP: float = 1.0 / 60.0

var _failures: int = 0
var _checks: int = 0
var _entered_room: StringName = &""
var _left_room: StringName = &""
var _room: Node3D
var _player: PlayerController
var _taken: Array[PhotoData] = []
var _developed: Array[PhotoData] = []


func _ready() -> void:
	EventBus.player_entered_room.connect(_on_entered_room)
	EventBus.player_left_room.connect(_on_left_room)
	EventBus.photo_taken.connect(_on_photo_taken)
	EventBus.photo_developed.connect(_on_photo_developed)
	await get_tree().process_frame

	_test_input_map()
	await _spawn_room()
	await _test_detection()
	await _test_photo_shot()
	await _test_room_sensor()
	await _test_walk()
	await _test_crouch()

	_report()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _wait_physics(frames: int) -> void:
	for i: int in frames:
		await get_tree().physics_frame


func _test_input_map() -> void:
	print("[InputMap]")
	for action: StringName in EXPECTED_ACTIONS:
		_check(InputMap.has_action(action), "action %s définie" % action)
		if InputMap.has_action(action):
			_check(InputMap.action_get_events(action).size() > 0, "action %s a au moins un événement" % action)
	var forward_events := InputMap.action_get_events(&"move_forward")
	var has_physical_w := false
	for event: InputEvent in forward_events:
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_W:
			has_physical_w = true
	_check(has_physical_w, "move_forward est lié à la touche physique W (Z sur AZERTY)")


func _spawn_room() -> void:
	print("[Scène de test]")
	_room = ROOM_SCENE.instantiate() as Node3D
	add_child(_room)
	await _wait_physics(3)
	_player = _room.get_node_or_null("Player") as PlayerController
	_check(_player != null, "le joueur est instancié dans test_room")
	_check(_player.is_on_floor(), "le joueur repose sur le sol")
	_check(_player.get_eye_camera() != null, "la caméra du joueur existe")


func _test_detection() -> void:
	print("[Détection des objets cadrés]")
	var camera := _player.get_eye_camera()
	var ids := PhotoDetector.collect_visible_items(camera)
	_check(ids.size() == 1, "un seul objet détecté (obtenu %d)" % ids.size())
	if ids.size() == 1:
		_check(ids[0] == &"test_item_a", "l'objet détecté est test_item_a (cadré et net)")
	_check(not ids.has(&"test_item_b"), "test_item_b occulté par le panneau : non détecté")
	_check(not ids.has(&"test_item_c"), "test_item_c trop petit à l'écran : non détecté")


func _test_photo_shot() -> void:
	print("[Appareil photo]")
	var device := _player.get_node_or_null("Head/Camera/PhotoDevice") as PhotoDevice
	_check(device != null, "PhotoDevice présent dans le joueur")
	if device == null:
		return
	device.develop_time = 0.1
	var films_before := InventoryManager.film_count()
	device.aim(true)
	await _wait_physics(2)
	_check(device.is_raised(), "l'appareil se lève (clic droit)")
	device.fire()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_taken.size() == 1, "photo_taken émis")
	_check(InventoryManager.film_count() == films_before - 1, "un film consommé")
	if _taken.size() == 1:
		var photo := _taken[0]
		_check(photo.visible_item_ids.size() == 1 and photo.visible_item_ids[0] == &"test_item_a",
			"PhotoData.visible_item_ids = [test_item_a] (obtenu %s)" % str(photo.visible_item_ids))
		_check(photo.room_id == &"test_room", "PhotoData.room_id = test_room")
		_check(not photo.developed, "photo non développée au déclenchement")
		_check(device.last_photo() == photo, "la photo est tenue en main")
	await get_tree().create_timer(0.35).timeout
	_check(_developed.size() == 1, "photo_developed émis après le délai de développement")
	if _developed.size() == 1:
		_check(_developed[0].developed, "PhotoData.developed = true")
	device.aim(false)
	await _wait_physics(2)


func _test_room_sensor() -> void:
	print("[Capteur de pièce]")
	await _wait_physics(3)
	_check(_entered_room == &"test_room", "player_entered_room émis avec room_id=test_room")
	var sensor := _player.get_node_or_null("RoomSensor") as RoomSensor
	_check(sensor != null and sensor.current_room() == &"test_room", "RoomSensor.current_room = test_room")
	_player.global_position = Vector3(0.0, 0.0, 20.0)
	await _wait_physics(6)
	_check(_left_room == &"test_room", "player_left_room émis en quittant la zone")
	_player.global_position = Vector3(0.0, 0.0, 6.0)
	await _wait_physics(6)


func _test_walk() -> void:
	print("[Marche]")
	_player.global_position = Vector3(0.0, 0.0, 6.0)
	_player.velocity = Vector3.ZERO
	var start := _player.global_position
	Input.action_press(&"move_forward")
	await _wait_physics(30)
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	Input.action_release(&"move_forward")
	await _wait_physics(6)
	var travelled := _player.global_position.distance_to(start)
	_check(travelled > 0.5, "le joueur avance (%.2f m en 0,5 s)" % travelled)
	_check(speed <= PlayerController.WALK_SPEED + 0.15, "vitesse de marche bornée à 2,5 m/s (%.2f)" % speed)


func _test_crouch() -> void:
	print("[Accroupi]")
	Input.action_press(&"crouch")
	await _wait_physics(20)
	_check(_player.is_crouching(), "l'accroupissement est actif")
	var capsule := (_player.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	_check(capsule.height < 1.3, "la capsule se réduit (%.2f m)" % capsule.height)
	Input.action_release(&"crouch")
	await _wait_physics(20)
	_check(not _player.is_crouching(), "l'accroupissement se relâche")


func _on_photo_taken(photo: PhotoData) -> void:
	_taken.append(photo)


func _on_photo_developed(photo: PhotoData) -> void:
	_developed.append(photo)


func _on_entered_room(room_id: StringName) -> void:
	_entered_room = room_id


func _on_left_room(room_id: StringName) -> void:
	_left_room = room_id


func _report() -> void:
	print("Tests Gameplay : %d vérifications, %d échec(s)." % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
