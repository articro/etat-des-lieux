## InventoryManager — la liste des 212 objets. Propriétaire : Systèmes.
## STUB M0 : signatures fixées (docs/ARCHITECTURE.md §5), implémentation à faire (tâche S-2).
extends Node

const ITEMS_DIR := "res://data/items/"
const STARTING_FILM := 10

var _items: Dictionary = {}      # StringName -> ItemData
var _checked: Dictionary = {}    # StringName -> true
var _revealed: Dictionary = {}   # StringName -> true
var _film: int = STARTING_FILM


func _ready() -> void:
	_load_items()
	EventBus.photo_developed.connect(_on_photo_developed)


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id)


func get_items_in_room(room_id: StringName) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for item: ItemData in _items.values():
		if item.room_id == room_id:
			out.append(item)
	return out


func is_checked(item_id: StringName) -> bool:
	return _checked.has(item_id)


func is_present(item_id: StringName) -> bool:
	var item := get_item(item_id)
	if item == null:
		return false
	return not item.is_phantom or _revealed.has(item_id)


func check_item(item_id: StringName, photo: PhotoData) -> bool:
	if is_checked(item_id) or not is_present(item_id):
		return false
	_checked[item_id] = true
	EventBus.item_checked.emit(item_id, photo)
	var p := progress()
	EventBus.inventory_progress.emit(p.x, p.y)
	return true


func reveal_item(item_id: StringName) -> void:
	if _revealed.has(item_id) or not _items.has(item_id):
		return
	_revealed[item_id] = true
	EventBus.item_revealed.emit(item_id)


func progress() -> Vector2i:
	return Vector2i(_checked.size(), _items.size())


func film_count() -> int:
	return _film


func add_film(count: int) -> void:
	_film = maxi(0, _film + count)


func consume_film() -> bool:
	if _film <= 0:
		return false
	_film -= 1
	return true


func to_save_dict() -> Dictionary:
	return {
		"checked": _checked.keys().map(func(k: StringName) -> String: return String(k)),
		"revealed": _revealed.keys().map(func(k: StringName) -> String: return String(k)),
		"film": _film,
	}


func from_save_dict(d: Dictionary) -> void:
	_checked.clear()
	_revealed.clear()
	for k: String in d.get("checked", []):
		_checked[StringName(k)] = true
	for k: String in d.get("revealed", []):
		_revealed[StringName(k)] = true
	_film = int(d.get("film", STARTING_FILM))


func _load_items() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("InventoryManager : dossier %s introuvable (normal en M0)." % ITEMS_DIR)
		return
	for file in dir.get_files():
		if file.ends_with(".tres") or file.ends_with(".res"):
			var res := load(ITEMS_DIR + file)
			if res is ItemData:
				var item := res as ItemData
				if _items.has(item.id):
					push_error("InventoryManager : id dupliqué %s" % item.id)
				_items[item.id] = item


func _on_photo_developed(photo: PhotoData) -> void:
	for id in photo.visible_item_ids:
		check_item(id, photo)
	for id in photo.revealed_item_ids:
		reveal_item(id)
		check_item(id, photo)
