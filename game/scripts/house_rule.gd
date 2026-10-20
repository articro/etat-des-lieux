## HouseRule — une règle du système « la maison se souvient ». Voir docs/ARCHITECTURE.md §6.
class_name HouseRule
extends Resource

@export var id: StringName
@export_enum("room_left", "room_entered", "progress", "attention_above", "doc_read", "flash_count", "idle", "item_checked", "noise", "item_moved", "ending") var trigger: String = "room_left"
@export var trigger_param: String = ""
@export_multiline var condition: String = ""
@export var actions: Array[String] = []
@export var once: bool = true
@export var cooldown: float = 0.0
