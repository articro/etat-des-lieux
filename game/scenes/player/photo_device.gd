## photo_device.gd — l'appareil photo (G-3, G-4, G-5). Module Gameplay.
##
## GDD §4.1 : lever l'appareil (clic droit maintenu), viseur, déclencheur (clic
## gauche) qui consomme un film, flash 0,3 s + aveuglement 1,5 s, capture d'un
## SubViewport, PhotoData, flash_fired puis photo_taken, puis photo_developed
## 10 s plus tard. Aucune chaîne affichée, aucun accès direct à un autre module :
## InventoryManager / GameState / AudioManager / EventBus uniquement.
class_name PhotoDevice
extends Node3D

const FLASH_DURATION: float = 0.3
const BLIND_DURATION: float = 1.5
const BLIND_PEAK: float = 0.92
const BLIND_RISE: float = 0.06
const AIM_FOV_DELTA: float = 20.0
const AIM_FOV_MIN: float = 45.0
const AIM_LERP: float = 9.0
const REVIEW_LERP: float = 10.0
const CAPTURE_SIZE: Vector2i = Vector2i(1280, 720)
const DEFAULT_DEVELOP_TIME: float = 10.0

## Temps de développement de la photo (10 s, GDD §4.1 ; réduit dans les tests).
@export var develop_time: float = DEFAULT_DEVELOP_TIME

var _raised: bool = false
var _reviewing: bool = false
var _busy: bool = false
var _photo_count: int = 0
var _last_photo: PhotoData = null
var _blind_tween: Tween = null
var _hold_rest: Transform3D
var _hold_center: Transform3D = Transform3D(Basis(), Vector3(0.0, -0.02, -0.34))

@onready var _camera: Camera3D = get_parent() as Camera3D

var _player: PlayerController = null
var _viewport: SubViewport = null
var _photo_camera: Camera3D = null
var _flash: OmniLight3D = null
var _blind: ColorRect = null
var _viewfinder: Control = null
var _photo_in_hand: PhotoInHand = null
var _photo_hold: Node3D = null
var _camera_body: MeshInstance3D = null


func _ready() -> void:
	_player = _find_player()
	if _player == null or _camera == null:
		push_warning("PhotoDevice : joueur ou caméra introuvable — appareil inactif.")
		set_process(false)
		set_process_unhandled_input(false)
		return
	_viewport = _player.get_node_or_null("PhotoViewport") as SubViewport
	_flash = _camera.get_node_or_null("FlashBulb") as OmniLight3D
	_blind = _player.get_node_or_null("HUD/Blind") as ColorRect
	_viewfinder = _player.get_node_or_null("HUD/Viewfinder") as Control
	_photo_hold = _camera.get_node_or_null("PhotoHold") as Node3D
	_photo_in_hand = _camera.get_node_or_null("PhotoHold/PhotoInHand") as PhotoInHand
	_camera_body = _camera.get_node_or_null("CameraBody") as MeshInstance3D
	if _photo_hold != null:
		_hold_rest = _photo_hold.transform
	if _camera_body != null:
		_camera_body.visible = false
	if _viewport != null:
		_photo_camera = _viewport.get_node_or_null("PhotoCamera3D") as Camera3D
		if _viewport.own_world_3d:
			_viewport.world_3d = _player.get_world_3d()
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if _photo_camera != null:
			_photo_camera.current = true
	if _photo_camera == null:
		push_warning("PhotoDevice : SubViewport de capture absent — photos sans texture.")
	if _flash == null:
		push_warning("PhotoDevice : FlashBulb absent — pas de lumière de flash.")


func _find_player() -> PlayerController:
	var node: Node = self
	while node != null:
		if node is PlayerController:
			return node as PlayerController
		node = node.get_parent()
	return null


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed(&"camera_raise"):
		aim(true)
	elif event.is_action_released(&"camera_raise"):
		aim(false)
	elif event.is_action_pressed(&"camera_shoot") and _raised:
		fire()
	elif event.is_action_pressed(&"photo_review"):
		toggle_review()


func _process(delta: float) -> void:
	if _player == null:
		return
	var target_fov: float = _player.base_fov
	if _raised:
		target_fov = maxf(_player.base_fov - AIM_FOV_DELTA, AIM_FOV_MIN)
	_camera.fov = lerpf(_camera.fov, target_fov, clampf(delta * AIM_LERP, 0.0, 1.0))
	if _photo_hold != null:
		var target: Transform3D = _hold_center if _reviewing else _hold_rest
		_photo_hold.transform = _photo_hold.transform.interpolate_with(
			target, clampf(delta * REVIEW_LERP, 0.0, 1.0))


## Lève ou baisse l'appareil (clic droit maintenu). Public pour les tests.
func aim(raised: bool) -> void:
	if _raised == raised:
		return
	_raised = raised
	if not raised:
		_reviewing = false
	if _viewfinder != null and _viewfinder.has_method(&"set_raised"):
		_viewfinder.call(&"set_raised", raised)
	if _camera_body != null:
		_camera_body.visible = raised
	if _photo_in_hand != null:
		_photo_in_hand.set_suppressed(raised)
	AudioManager.play_ui(&"camera_raise")


## Déclenche (clic gauche). Ignoré si l'appareil est déjà en train de tirer.
func fire() -> void:
	if _busy:
		return
	_busy = true
	if InventoryManager.film_count() <= 0:
		AudioManager.play_ui(&"camera_dry")
		_busy = false
		return
	if not InventoryManager.consume_film():
		_busy = false
		return

	AudioManager.play_ui(&"camera_shutter")
	var shot_transform := _camera.global_transform
	var room_id: StringName = GameState.current_room()
	var visible_ids := PhotoDetector.collect_visible_items(_camera, _exclude_rids())

	_flash_on()
	await get_tree().process_frame
	await get_tree().process_frame
	var texture: Texture2D = await _capture(shot_transform)

	_photo_count += 1
	var photo := PhotoData.new()
	photo.id = _photo_count
	photo.timestamp = Time.get_ticks_msec() / 1000.0
	photo.room_id = room_id
	photo.camera_transform = shot_transform
	photo.visible_item_ids = visible_ids
	photo.texture = texture
	photo.developed = false
	_last_photo = photo

	_apply_blind()
	EventBus.flash_fired.emit(_camera.global_position, room_id)
	EventBus.photo_taken.emit(photo)
	if _photo_in_hand != null:
		_photo_in_hand.show_photo(photo, develop_time)
	AudioManager.play_ui(&"photo_slide")
	_schedule_development(photo)
	_busy = false


func toggle_review() -> void:
	if _last_photo == null or _raised:
		return
	_reviewing = not _reviewing
	if _photo_in_hand != null:
		_photo_in_hand.visible = true


func last_photo() -> PhotoData:
	return _last_photo


func is_raised() -> bool:
	return _raised


func photo_count() -> int:
	return _photo_count


# --- Flash / capture / développement -----------------------------------------

func _flash_on() -> void:
	if _flash != null:
		_flash.visible = true
	AudioManager.play_ui(&"camera_flash")
	var timer := get_tree().create_timer(FLASH_DURATION)
	timer.timeout.connect(_flash_off)


func _flash_off() -> void:
	if _flash != null:
		_flash.visible = false


func _apply_blind() -> void:
	if _blind == null:
		return
	if _blind_tween != null and _blind_tween.is_valid():
		_blind_tween.kill()
	_blind.visible = true
	_blind.modulate.a = 0.0
	_blind_tween = create_tween()
	_blind_tween.tween_property(_blind, "modulate:a", BLIND_PEAK, BLIND_RISE)
	_blind_tween.tween_property(_blind, "modulate:a", 0.0, BLIND_DURATION - BLIND_RISE) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_blind_tween.tween_callback(_hide_blind)


func _hide_blind() -> void:
	if _blind != null:
		_blind.visible = false


func _capture(shot_transform: Transform3D) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	if _viewport == null or _photo_camera == null:
		return null
	_photo_camera.global_transform = shot_transform
	_photo_camera.fov = _camera.fov
	_photo_camera.current = true
	_viewport.size = CAPTURE_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var viewport_texture := _viewport.get_texture()
	if viewport_texture == null:
		return null
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _schedule_development(photo: PhotoData) -> void:
	var delay := maxf(develop_time, 0.0)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if photo.developed:
		return
	photo.developed = true
	EventBus.photo_developed.emit(photo)


func _exclude_rids() -> Array[RID]:
	var body := _player as CollisionObject3D
	return PhotoDetector.player_exclude_rids(body)
