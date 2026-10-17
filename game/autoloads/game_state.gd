## GameState — état global de la partie. Propriétaire : Systèmes.
## API publique fixée dans docs/ARCHITECTURE.md §5.
extends Node

var current_act: int = 1
var attention: float = 0.0  # 0..100, modifié uniquement par HouseDirector

var _flags: Dictionary = {}     # StringName -> bool
var _counters: Dictionary = {}  # StringName -> int
var _current_room: StringName = &"exterior"


func _ready() -> void:
	EventBus.player_entered_room.connect(_on_player_entered_room)


func get_flag(key: StringName) -> bool:
	return _flags.get(key, false)


func set_flag(key: StringName, value: bool = true) -> void:
	_flags[key] = value


func get_counter(key: StringName) -> int:
	return _counters.get(key, 0)


func add_counter(key: StringName, delta: int = 1) -> void:
	_counters[key] = get_counter(key) + delta


func current_room() -> StringName:
	return _current_room


func to_save_dict() -> Dictionary:
	return {
		"act": current_act,
		"attention": attention,
		"flags": _flags.duplicate(),
		"counters": _counters.duplicate(),
		"room": String(_current_room),
	}


func from_save_dict(d: Dictionary) -> void:
	current_act = int(d.get("act", 1))
	attention = float(d.get("attention", 0.0))
	_flags = d.get("flags", {}).duplicate()
	_counters = d.get("counters", {}).duplicate()
	_current_room = StringName(d.get("room", "exterior"))


func _on_player_entered_room(room_id: StringName) -> void:
	_current_room = room_id
