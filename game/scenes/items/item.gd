## Objet générique de la maison : détection photo, interaction et surbrillance.
class_name Item
extends Node3D

const DEFAULT_SIZE: Vector3 = Vector3(0.45, 0.45, 0.45)
const ItemVisualFactory = preload("res://scenes/items/item_visuals.gd")
const PLACEHOLDER_SIZES: Dictionary[StringName, Vector3] = {
	&"hall_console_table": Vector3(0.90, 0.76, 0.42),
	&"hall_barometer": Vector3(0.36, 0.50, 0.10),
	&"hall_answering_machine": Vector3(0.42, 0.18, 0.30),
	&"hall_coat_rack": Vector3(0.55, 1.55, 0.35),
	&"hall_key_board": Vector3(0.52, 0.68, 0.12),
	&"hall_mirror": Vector3(0.82, 1.45, 0.10),
	&"hall_umbrella_stand": Vector3(0.35, 0.65, 0.35),
	&"hall_doorbell": Vector3(0.16, 0.24, 0.08),
	&"hall_hand_railing": Vector3(0.42, 0.22, 0.10),
	&"hall_ring_1951": Vector3(0.05, 0.05, 0.05),
	&"study_desk": Vector3(1.55, 0.75, 0.82),
	&"study_chair": Vector3(0.62, 1.00, 0.62),
	&"study_shelves": Vector3(0.85, 1.90, 0.36),
	&"study_typewriter": Vector3(0.45, 0.24, 0.35),
	&"study_lamp": Vector3(0.35, 0.75, 0.35),
	&"study_safe": Vector3(0.80, 1.05, 0.70),
	&"study_registers": Vector3(0.48, 0.54, 0.38),
	&"kitchen_table": Vector3(1.35, 0.75, 0.90),
	&"kitchen_calendar": Vector3(0.38, 0.50, 0.06),
	&"living_fireplace": Vector3(1.15, 1.00, 0.42),
	&"cellar_stove": Vector3(0.65, 0.85, 0.65),
	&"cellar_shelves": Vector3(1.20, 1.80, 0.42),
}

@export var data: ItemData

@onready var _collision_shape: CollisionShape3D = get_node_or_null("Collision/Shape") as CollisionShape3D
@onready var _highlight: MeshInstance3D = get_node_or_null("Highlight") as MeshInstance3D

var _highlighted: bool = false
var _present: bool = true
var _visual_kind: StringName = &"placeholder"


func _ready() -> void:
	add_to_group(&"items")
	if data == null:
		push_warning("Item '%s' : ItemData absente, cube de secours conservé." % name)
	else:
		name = String(data.id)
		_apply_placeholder_size()
		_visual_kind = ItemVisualFactory.create_visual(self, data.id)
	set_present(_present)
	if get_tree().current_scene == self:
		_setup_standalone_preview()


## Renvoie une fraction d'écran estimée pour le détecteur photo.
func is_in_frustum(camera: Camera3D) -> float:
	if camera == null or not _present or not is_visible_in_tree():
		return 0.0
	var screen_size := Vector2(1920.0, 1080.0)
	var viewport := camera.get_viewport()
	if viewport != null:
		screen_size = viewport.get_visible_rect().size
	return ScreenMath.node_coverage(camera, self, screen_size)


## Id et type consommés par l'interacteur Gameplay via le contrat Item.
func get_interact_id() -> StringName:
	if data == null:
		return &""
	return data.id


func get_interact_kind() -> StringName:
	return &"pickup"


func get_interact_duration() -> float:
	return 0.0


## Contenu d'inspection destiné à l'UI, sans dépendance directe sur son module.
func get_inspection_data() -> Dictionary:
	if data == null:
		return {}
	return {
		&"id": data.id,
		&"label_key": data.label_key,
		&"lore_key": data.lore_key,
		&"label": tr(data.label_key),
		&"lore": tr(data.lore_key),
		&"movable": data.movable,
	}


## Surbrillance discrète lors du survol par le rayon d'interaction.
func set_highlight(enabled: bool) -> void:
	_highlighted = enabled
	if _highlight != null:
		_highlight.visible = enabled and _present


## Cache aussi le collider des fantômes pas encore révélés.
func set_present(present: bool) -> void:
	_present = present
	visible = present
	if _collision_shape != null:
		_collision_shape.disabled = not present
	if _highlight != null:
		_highlight.visible = present and _highlighted


func is_present() -> bool:
	return _present


## Type de rendu construit par ItemVisualFactory, consommé par les tests Niveau.
func visual_kind() -> StringName:
	return _visual_kind


func _apply_placeholder_size() -> void:
	var size: Vector3 = DEFAULT_SIZE
	var stored_size: Variant = PLACEHOLDER_SIZES.get(data.id, DEFAULT_SIZE)
	if stored_size is Vector3:
		size = stored_size
	scale = Vector3(size.x / DEFAULT_SIZE.x, size.y / DEFAULT_SIZE.y, size.z / DEFAULT_SIZE.z)


func _setup_standalone_preview() -> void:
	var camera := Camera3D.new()
	camera.name = "StandalonePreviewCamera"
	camera.position = Vector3(1.5, 1.3, 2.2)
	camera.fov = 55.0
	add_child(camera)
	camera.look_at(global_position, Vector3.UP)
	camera.current = true

	var light := OmniLight3D.new()
	light.name = "StandalonePreviewLight"
	light.position = Vector3(1.4, 2.0, 1.8)
	light.light_energy = 1.2
	light.omni_range = 6.0
	light.shadow_enabled = false
	add_child(light)
