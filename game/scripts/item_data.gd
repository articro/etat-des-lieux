## ItemData — un des 212 objets de l'inventaire. Voir docs/ARCHITECTURE.md §6.
class_name ItemData
extends Resource

@export var id: StringName
@export var list_index: int = 0
@export var room_id: StringName
@export var label_key: StringName
@export var lore_key: StringName
@export var is_phantom: bool = false
@export_enum("none", "person", "moved", "message", "photo_only") var phantom_kind: String = "none"
@export_multiline var reveal_condition: String = ""
@export var movable: bool = true
@export var anchors: Array[StringName] = []
@export var scene: PackedScene
@export var photo_variant_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var min_photo_coverage: float = 0.15
