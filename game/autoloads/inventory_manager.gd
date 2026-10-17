## InventoryManager — la liste des 60 objets (V1) / 212 (V2). Propriétaire : Systèmes.
## API publique fixée (docs/ARCHITECTURE.md §5). Tâche S-2.
extends Node

const ITEMS_DIR := "res://data/items/"
const STARTING_FILM := 10
## Clé de la ligne qui s'écrit seule quand toute la liste est cochée (« 61. Camille », clé = prénom ; le numéro se compose via INV_LINE_FORMAT côté UI).
const FINAL_LINE_KEY := &"INV_LINE_ADDED_CAMILLE"

var _items: Dictionary = {}      # StringName -> ItemData
var _checked: Dictionary = {}    # StringName -> true
var _revealed: Dictionary = {}   # StringName -> true
var _film: int = STARTING_FILM
var _final_line_added: bool = false


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
	out.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.list_index < b.list_index)
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
	_maybe_add_final_line()
	var p := progress()
	EventBus.inventory_progress.emit(p.x, p.y)
	return true


func reveal_item(item_id: StringName) -> void:
	if _revealed.has(item_id):
		return
	if not _items.has(item_id):
		push_warning("InventoryManager.reveal_item : objet inconnu %s." % item_id)
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
	_final_line_added = _checked.size() >= _items.size() and not _items.is_empty()


## Enregistre un ItemData (chargement disque + scène de test Systèmes).
func _register_item(item: ItemData) -> void:
	if item == null or item.id == StringName():
		push_error("InventoryManager : ItemData sans id ignoré.")
		return
	if _items.has(item.id):
		push_error("InventoryManager : id dupliqué %s." % item.id)
		return
	_items[item.id] = item


## Remise à zéro complète pour la scène de test Systèmes (usage interne uniquement).
func _reset_for_tests() -> void:
	_items.clear()
	_checked.clear()
	_revealed.clear()
	_film = STARTING_FILM
	_final_line_added = false


## Quand toute la liste est cochée, une ligne de plus s'écrit seule (fin « Inventaire clos »).
func _maybe_add_final_line() -> void:
	if _final_line_added or _items.is_empty() or _checked.size() < _items.size():
		return
	_final_line_added = true
	EventBus.inventory_line_added.emit(_items.size() + 1, FINAL_LINE_KEY)


func _load_items() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("InventoryManager : dossier %s introuvable (normal en M0)." % ITEMS_DIR)
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var path := ITEMS_DIR + file
		if not ResourceLoader.exists(path):
			push_warning("InventoryManager : ressource invalide %s." % path)
			continue
		var res := load(path)
		if res is ItemData:
			_register_item(res as ItemData)
		else:
			push_warning("InventoryManager : %s n'est pas une ItemData." % path)


func _on_photo_developed(photo: PhotoData) -> void:
	if photo == null:
		push_warning("InventoryManager : photo_developed avec photo nulle.")
		return
	for id: StringName in photo.visible_item_ids:
		check_item(id, photo)
	for id: StringName in photo.revealed_item_ids:
		reveal_item(id)
		check_item(id, photo)
