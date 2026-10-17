## SaveManager — sauvegarde JSON. Propriétaire : Systèmes. STUB M0 (tâche S-5).
extends Node

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves/"


func _ready() -> void:
	EventBus.save_requested.connect(func() -> void: save_game())


func _path(slot: int) -> String:
	return "%sslot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_path(slot))


func save_game(slot: int = 0) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": SAVE_VERSION,
		"game_state": GameState.to_save_dict(),
		"inventory": InventoryManager.to_save_dict(),
		"house": HouseDirector.to_save_dict(),
		"documents": DocumentLibrary.to_save_dict(),
	}
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "\t"))
	return OK


func load_game(slot: int = 0) -> Error:
	if not has_save(slot):
		return ERR_FILE_NOT_FOUND
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	var data := parsed as Dictionary
	if int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveManager : version de sauvegarde %s, migration nécessaire." % data.get("version"))
	GameState.from_save_dict(data.get("game_state", {}))
	InventoryManager.from_save_dict(data.get("inventory", {}))
	HouseDirector.from_save_dict(data.get("house", {}))
	DocumentLibrary.from_save_dict(data.get("documents", {}))
	EventBus.game_loaded.emit()
	return OK
