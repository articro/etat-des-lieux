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
	await _test_interaction()
	await _test_flashlight()
	await _test_presence()
	await _test_room_sensor()
	await _test_walk()
	await _test_crouch()
	await _test_settings()
	await _test_pause()
	await _test_persisted_settings()

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


func _test_interaction() -> void:
	print("[Interaction]")
	var interactor := _player.get_node_or_null("Head/Camera/InteractRay") as Interactor
	_check(interactor != null, "InteractRay (raycast 2,5 m) présent")
	if interactor == null:
		return
	_player.global_position = Vector3(0.0, 0.0, 6.0)
	_player.rotation = Vector3.ZERO
	_player.get_node("Head").rotation = Vector3.ZERO
	await _wait_physics(4)
	_check(interactor.current_target_id() == &"hall_postit_besnard", "cible lue = hall_postit_besnard")
	_check(interactor.current_kind() == &"read", "kind = read pour un document")
	var interacted: Array = []
	var interacted_cb := func(id: StringName, kind: StringName) -> void:
		interacted.append([id, kind])
	var read_ids: Array[StringName] = []
	var read_cb := func(id: StringName) -> void:
		read_ids.append(id)
	EventBus.player_interacted.connect(interacted_cb)
	EventBus.document_read.connect(read_cb)
	var before := interacted.size()
	interactor.interact()
	await get_tree().process_frame
	_check(interacted.size() == before + 1, "player_interacted émis à l'appui sur E")
	if interacted.size() > before:
		var entry: Array = interacted[before]
		_check(entry[0] == &"hall_postit_besnard" and entry[1] == &"read", "player_interacted(hall_postit_besnard, read)")
	_check(read_ids.has(&"hall_postit_besnard"), "la lecture appelle DocumentLibrary.mark_read")
	var stove := _room.get_node_or_null("TestStove")
	interactor.force_target(stove)
	_check(interactor.current_duration() > 0.0, "interaction longue : durée détectée")
	var count_before := interacted.size()
	interactor.interact()
	await get_tree().process_frame
	_check(interacted.size() == count_before, "un appui court n'achève pas une action longue")
	interactor.advance_hold(0.1)
	interactor.advance_hold(0.15)
	await get_tree().process_frame
	_check(interacted.size() == count_before + 1, "maintenir E achève l'action longue")
	if interacted.size() > count_before:
		var done: Array = interacted[count_before]
		_check(done[0] == &"cellar_stove" and done[1] == &"burn", "player_interacted(cellar_stove, burn)")
	EventBus.player_interacted.disconnect(interacted_cb)
	EventBus.document_read.disconnect(read_cb)
	_player.rotation = Vector3.ZERO
	_player.get_node("Head").rotation = Vector3.ZERO


func _test_flashlight() -> void:
	print("[Lampe]")
	var lamp := _player.get_node_or_null("Head/Camera/Flashlight") as Flashlight
	_check(lamp != null, "lampe présente")
	if lamp == null:
		return
	_check(not lamp.is_on(), "lampe éteinte au départ")
	lamp.toggle()
	await get_tree().process_frame
	_check(lamp.is_on(), "la lampe s'allume (F)")
	lamp.toggle()
	await get_tree().process_frame
	_check(not lamp.is_on(), "la lampe s'éteint (F)")


func _test_presence() -> void:
	print("[Présence]")
	var presence_scene := load("res://scenes/player/presence.tscn") as PackedScene
	_check(presence_scene != null, "presence.tscn se charge")
	if presence_scene == null:
		return
	var presence := presence_scene.instantiate() as Presence
	_room.add_child(presence)
	presence.global_position = Vector3(1.2, 0.0, 3.6)
	_player.global_position = Vector3(0.0, 0.0, 6.0)
	await _wait_physics(3)
	_check(not presence.is_active(), "la Présence est dormante par défaut")
	if presence.is_active():
		return
	var caught := [0]
	var catch_cb := func() -> void:
		caught[0] += 1
	EventBus.player_caught.connect(catch_cb)
	EventBus.presence_state_changed.emit(&"physical")
	await _wait_physics(2)
	_check(presence.is_active(), "l'état physical la fait apparaître")
	var start_distance := presence.global_position.distance_to(_player.global_position)
	await _wait_physics(30)
	var moved_distance := presence.global_position.distance_to(_player.global_position)
	_check(moved_distance < start_distance - 0.1, "elle avance vers le joueur (%.2f -> %.2f m)" % [start_distance, moved_distance])
	presence.freeze_time = 0.2
	var photo := PhotoData.new()
	photo.camera_transform = _player.get_eye_camera().global_transform
	EventBus.photo_taken.emit(photo)
	await get_tree().process_frame
	_check(presence.is_frozen(), "photographiée : figée")
	var frozen_position := presence.global_position
	await _wait_physics(6)
	_check(presence.global_position.distance_to(frozen_position) < 0.01, "elle ne bouge plus pendant le figeage")
	await get_tree().create_timer(0.35).timeout
	presence.global_position = Vector3(0.0, 0.0, 4.95)
	await _wait_physics(12)
	_check(caught[0] == 1, "au contact : player_caught émis")
	EventBus.player_caught.disconnect(catch_cb)
	presence.queue_free()
	await get_tree().process_frame


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


func _test_settings() -> void:
	print("[Réglages (settings_changed)]")
	var camera := _player.get_eye_camera()
	var lamp := _player.get_node_or_null("Head/Camera/Flashlight") as Flashlight
	EventBus.settings_changed.emit(&"mouse_sensitivity", 0.5)
	_check(is_equal_approx(_player.get_sensitivity(), 0.0043),
		"sensibilité normalisée 0,5 → 0,0043 rad/px (%.4f)" % _player.get_sensitivity())
	EventBus.settings_changed.emit(&"mouse_sensitivity", 0.003)
	_check(is_equal_approx(_player.get_sensitivity(), 0.003), "sensibilité brute (rad/px) conservée")
	EventBus.settings_changed.emit(&"fov", 95.0)
	_check(is_equal_approx(_player.get_base_fov(), 95.0), "FOV 95 pris en compte")
	await _wait_physics(40)
	_check(absf(camera.fov - 95.0) < 1.0, "la caméra converge vers le FOV réglé (%.1f)" % camera.fov)
	EventBus.settings_changed.emit(&"fov", 140.0)
	_check(is_equal_approx(_player.get_base_fov(), 110.0), "FOV borné à 110°")
	EventBus.settings_changed.emit(&"fov", 75.0)
	await _wait_physics(30)
	_check(lamp != null, "lampe présente pour le réglage d'accessibilité")
	if lamp != null:
		var energy_before := lamp.light_energy
		EventBus.settings_changed.emit(&"flashlight_strong", true)
		_check(lamp.is_strong() and lamp.light_energy > energy_before,
			"lampe plus forte : énergie %.1f → %.1f" % [energy_before, lamp.light_energy])
		_check(not lamp.is_on(), "le réglage ne change pas l'état allumé/éteint")
		EventBus.settings_changed.emit(&"flashlight_strong", false)
		_check(not lamp.is_strong() and is_equal_approx(lamp.light_energy, energy_before),
			"retour au profil normal")
	EventBus.settings_changed.emit(&"volume_master", 0.4)
	EventBus.settings_changed.emit(&"inconnue", Vector3.ZERO)
	_check(true, "clés inconnues ignorées sans erreur")


func _test_pause() -> void:
	print("[Pause (Échap)]")
	var events: Array[bool] = []
	var cb := func(paused: bool) -> void:
		events.append(paused)
	EventBus.pause_toggled.connect(cb)
	_check(not _player.is_paused(), "non pausé au départ")
	_check(_player.get_intended_mouse_mode() == Input.MOUSE_MODE_CAPTURED, "souris capturée au départ")
	_check_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_send_escape()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_player.is_paused(), "Échap met en pause")
	_check(_player.get_intended_mouse_mode() == Input.MOUSE_MODE_VISIBLE, "Échap libère la souris (VISIBLE)")
	_check_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_check(events.size() == 1 and events[0] == true, "pause_toggled(true) émis une fois")
	_send_escape()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not _player.is_paused(), "second Échap : reprise")
	_check(_player.get_intended_mouse_mode() == Input.MOUSE_MODE_CAPTURED, "second Échap : souris recapturée")
	_check_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_check(events.size() == 2 and events[1] == false, "pause_toggled(false) émis")
	# Un pause_toggled venu d'ailleurs (UI) aligne le joueur sans réémettre.
	var before := events.size()
	EventBus.pause_toggled.emit(true)
	await get_tree().process_frame
	_check(_player.is_paused(), "pause pilotée par l'UI : le joueur s'aligne")
	_check(events.size() == before + 1, "aucune réémission en boucle depuis le joueur")
	EventBus.pause_toggled.emit(false)
	await get_tree().process_frame
	_check(not _player.is_paused()
		and _player.get_intended_mouse_mode() == Input.MOUSE_MODE_CAPTURED,
		"reprise pilotée par l'UI : souris recapturée")
	_check_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventBus.pause_toggled.disconnect(cb)


## Le serveur headless ignore la capture de souris : on ne vérifie l'état réel
## du curseur que sur un vrai serveur d'affichage.
func _check_mouse_mode(expected: Input.MouseMode) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_check(Input.mouse_mode == expected, "Input.mouse_mode réel = %d" % expected)


func _send_escape() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)


func _test_persisted_settings() -> void:
	print("[Réglages persistés]")
	var path := "user://settings.cfg"
	var had_file := FileAccess.file_exists(path)
	var backup: PackedByteArray = PackedByteArray()
	if had_file:
		backup = FileAccess.get_file_as_bytes(path)
	var missing := SettingsSource.read("user://__absent__.cfg")
	_check(missing.is_empty(), "fichier absent : aucune valeur, pas d'erreur")
	var config := ConfigFile.new()
	config.set_value("options", "fov", 88.0)
	config.set_value("options", "mouse_sensitivity", 0.25)
	config.set_value("options", "flashlight_strong", true)
	config.set_value("options", "volume_master", 0.5)
	_check(config.save(path) == OK, "fichier de réglages écrit")
	var stored := SettingsSource.read(path)
	_check(stored.has(&"fov") and is_equal_approx(float(stored[&"fov"]), 88.0), "fov relu (88)")
	_check(stored.has(&"flashlight_strong") and bool(stored[&"flashlight_strong"]), "flashlight_strong relu")
	_check(not stored.has(&"volume_master"), "clé hors périmètre ignorée")
	_player.apply_persisted_settings()
	await get_tree().process_frame
	_check(is_equal_approx(_player.get_base_fov(), 88.0), "réglages appliqués au démarrage du joueur")
	var lamp := _player.get_node_or_null("Head/Camera/Flashlight") as Flashlight
	_check(lamp != null and lamp.is_strong(), "lampe forte restaurée")
	# Nettoyage : on rend le fichier à son état d'origine.
	var restore := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if restore != OK:
		push_warning("Test : impossible de supprimer %s (%s)" % [path, error_string(restore)])
	if had_file:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(backup)
			f.close()
	EventBus.settings_changed.emit(&"fov", 75.0)
	await get_tree().process_frame


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
