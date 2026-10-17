## test_ui.gd — banc d'essai **manuel** du module UI (lancer cette scène seule, F6).
##
## Émet des signaux factices (`EventBus`) et appelle les API publiques des autoloads
## pour exercer carnet, coches, photos, documents, sous-titres, HUD, pause et les
## deux fins — sans joueur ni maison. Touches 1 à 7 (actions `ui_test_*` créées ici
## à l'exécution, comme le filet de sécurité `input_actions.gd` du Gameplay).
extends Node

const ITEMS_DIR := "res://data/items/"
const ROOMS: Array[StringName] = [&"exterior", &"hall", &"kitchen", &"living", &"study", &"cellar"]
const DOC_IDS: Array[StringName] = [
	&"hall_postit_besnard", &"study_inventory_1973", &"kitchen_letter_lucienne_1",
	&"living_photo_family", &"cellar_register_1847", &"study_deed_1912",
]
const SUB_KEYS: Array[StringName] = [&"SUB_TAPE", &"SUB_DRAWER_OPENS", &"SUB_PRESENCE_SEEN", &"SUB_DAWN"]
const TEST_ACTIONS: Array[StringName] = [
	&"ui_test_check", &"ui_test_line", &"ui_test_photo", &"ui_test_document",
	&"ui_test_subtitle", &"ui_test_ending_closed", &"ui_test_ending_ashes",
]

var _ending: EndingScreen
var _doc_index := 0
var _sub_index := 0
var _photo_index := 0
var _items: Array[ItemData] = []


func _ready() -> void:
	UiText.ensure()
	_ensure_actions()
	_items = _collect_items()
	_ending = get_node_or_null("EndingLayer/Ending") as EndingScreen
	if _ending != null:
		_ending.visible = false
	else:
		push_warning("Banc d'essai : écran de fin absent.")
	print("── %s ──" % tr(&"UI_TEST_TITLE"))
	print(tr(&"UI_TEST_HELP"))
	print("objets chargés : %d · films : %d" % [InventoryManager.progress().y, InventoryManager.film_count()])


func _unhandled_input(event: InputEvent) -> void:
	if _ending != null and _ending.visible and event.is_action_pressed(&"pause"):
		_ending.visible = false
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_test_check"):
		_check_next()
	elif event.is_action_pressed(&"ui_test_line"):
		EventBus.inventory_line_added.emit(InventoryManager.progress().y + 1, &"INV_LINE_ADDED_CAMILLE")
	elif event.is_action_pressed(&"ui_test_photo"):
		_emit_photo()
	elif event.is_action_pressed(&"ui_test_document"):
		_open_next_document()
	elif event.is_action_pressed(&"ui_test_subtitle"):
		_emit_subtitle()
	elif event.is_action_pressed(&"ui_test_ending_closed"):
		_show_ending(&"closed")
	elif event.is_action_pressed(&"ui_test_ending_ashes"):
		_show_ending(&"ashes")
	else:
		return
	get_viewport().set_input_as_handled()


# --- Émissions factices ---

func _check_next() -> void:
	for item: ItemData in _items:
		if InventoryManager.is_checked(item.id) or not InventoryManager.is_present(item.id):
			continue
		var ok := InventoryManager.check_item(item.id, _fake_photo(item.room_id))
		print("coché : %s (%s)" % [item.id, "ok" if ok else "refusé"])
		return
	print("plus aucun objet à cocher")


func _emit_photo() -> void:
	var room := ROOMS[_photo_index % ROOMS.size()]
	_photo_index += 1
	EventBus.photo_taken.emit(_fake_photo(room))
	EventBus.photo_developed.emit(_fake_photo(room))
	print("photographie développée (%s)" % room)


func _open_next_document() -> void:
	var doc_id := DOC_IDS[_doc_index % DOC_IDS.size()]
	_doc_index += 1
	DocumentLibrary.mark_found(doc_id)
	print("document : %s" % doc_id)


func _emit_subtitle() -> void:
	var key := SUB_KEYS[_sub_index % SUB_KEYS.size()]
	_sub_index += 1
	EventBus.subtitle_requested.emit(key, 3.0)


func _show_ending(ending_id: StringName) -> void:
	if _ending == null:
		return
	_ending.visible = true
	_ending.set_ending_id(ending_id)
	print("fin : %s" % ending_id)


# --- Données de test ---

func _fake_photo(room_id: StringName) -> PhotoData:
	var photo := PhotoData.new()
	photo.id = _photo_index
	photo.room_id = room_id
	photo.developed = true
	var image := Image.create_empty(480, 360, false, Image.FORMAT_RGBA8)
	var shade := 0.18 + float(_photo_index % 5) * 0.06
	image.fill(Color(shade, shade * 0.98, shade * 0.92))
	image.fill_rect(Rect2i(40, 30, 400, 300), Color(shade * 1.8, shade * 1.7, shade * 1.5))
	photo.texture = ImageTexture.create_from_image(image)
	return photo


## Même énumération que le carnet : `all_items()` si elle existe, sinon le dossier.
func _collect_items() -> Array[ItemData]:
	var found: Array[ItemData] = []
	if InventoryManager.has_method("all_items"):
		var from_api: Variant = InventoryManager.call("all_items")
		if from_api is Array:
			for element: Variant in from_api:
				if element is ItemData:
					found.append(element as ItemData)
	if found.is_empty():
		var dir := DirAccess.open(ITEMS_DIR)
		if dir == null:
			push_warning("Banc d'essai : %s inaccessible." % ITEMS_DIR)
			return found
		var files := dir.get_files()
		files.sort()
		for file: String in files:
			if not file.ends_with(".tres"):
				continue
			var resource := ResourceLoader.load(ITEMS_DIR + file)
			if resource is ItemData and InventoryManager.get_item((resource as ItemData).id) != null:
				found.append(resource as ItemData)
	found.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.list_index < b.list_index)
	return found


## Crée les actions de test si elles n'existent pas (project.godot = périmètre Architecte).
func _ensure_actions() -> void:
	for index: int in TEST_ACTIONS.size():
		var action := TEST_ACTIONS[index]
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1 + index
		InputMap.action_add_event(action, key)
