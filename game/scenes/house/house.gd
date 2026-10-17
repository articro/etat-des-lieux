## Composition de la maison V1 et placement des objets sur leurs ancres.
extends Node3D

const FALLBACK_ITEM_SCENE: String = "res://scenes/items/item.tscn"

@onready var _rooms_root: Node3D = get_node_or_null("Rooms") as Node3D
@onready var _standalone_camera: Camera3D = get_node_or_null("StandaloneCamera") as Camera3D
@onready var _standalone_lights: Node3D = get_node_or_null("StandaloneLights") as Node3D

var _rooms_by_id: Dictionary[StringName, Node3D] = {}
var _items_by_id: Dictionary[StringName, Item] = {}
var _item_rooms: Dictionary[StringName, StringName] = {}


func _ready() -> void:
	_configure_standalone_preview()
	_connect_event_bus()
	_index_rooms()
	_populate_rooms()


func _configure_standalone_preview() -> void:
	var standalone := get_tree().current_scene == self
	if _standalone_camera != null:
		_standalone_camera.current = standalone
	elif standalone:
		push_warning("House : caméra de prévisualisation absente.")
	if _standalone_lights != null:
		_standalone_lights.visible = standalone


func _connect_event_bus() -> void:
	if not EventBus.item_moved.is_connected(_on_item_moved):
		EventBus.item_moved.connect(_on_item_moved)
	if not EventBus.item_revealed.is_connected(_on_item_revealed):
		EventBus.item_revealed.connect(_on_item_revealed)


func _index_rooms() -> void:
	if _rooms_root == null:
		push_warning("House : nœud Rooms absent, aucun objet ne sera instancié.")
		return
	for child: Node in _rooms_root.get_children():
		var room := child as Node3D
		if room == null:
			push_warning("House : enfant non-3D ignoré sous Rooms.")
			continue
		var room_id := StringName(str(room.get_meta(&"room_id", "")))
		if room_id == &"":
			var zone := room.get_node_or_null("Zone") as Area3D
			if zone != null:
				room_id = StringName(str(zone.get_meta(&"room_id", "")))
		if room_id == &"":
			push_warning("House : room_id absent sur '%s', salle ignorée." % room.name)
			continue
		if _rooms_by_id.has(room_id):
			push_warning("House : room_id dupliqué '%s', salle ignorée." % room_id)
			continue
		_rooms_by_id[room_id] = room


func _populate_rooms() -> void:
	if _rooms_root == null:
		return
	for room_id: StringName in _rooms_by_id.keys():
		var room := _rooms_by_id.get(room_id) as Node3D
		if room == null:
			continue
		var items_root := room.get_node_or_null("Items") as Node3D
		if items_root == null:
			push_warning("House : nœud Items absent dans '%s'." % room_id)
			continue
		for item_data: ItemData in InventoryManager.get_items_in_room(room_id):
			_spawn_item(room, items_root, item_data)


func _spawn_item(room: Node3D, items_root: Node3D, item_data: ItemData) -> void:
	if item_data == null or item_data.id == &"":
		push_warning("House : ItemData invalide ignorée dans '%s'." % room.name)
		return
	var anchor_name: StringName = &""
	if not item_data.anchors.is_empty():
		anchor_name = item_data.anchors[0]
	if anchor_name == &"":
		push_error("House : ancre initiale absente pour '%s'." % item_data.id)
		return
	var anchor := _find_anchor(room, anchor_name)
	if anchor == null:
		push_error("House : ancre '%s' absente dans '%s' pour '%s'." % [anchor_name, room.name, item_data.id])
		return

	var packed_scene := item_data.scene
	if packed_scene == null:
		if not ResourceLoader.exists(FALLBACK_ITEM_SCENE):
			push_warning("House : scène Item absente; '%s' laissé de côté." % item_data.id)
			return
		packed_scene = load(FALLBACK_ITEM_SCENE) as PackedScene
	if packed_scene == null:
		push_warning("House : scène Item invalide pour '%s'." % item_data.id)
		return
	var instance := packed_scene.instantiate()
	var item := instance as Item
	if item == null:
		push_warning("House : la scène de '%s' n'a pas de racine Item." % item_data.id)
		instance.queue_free()
		return
	item.data = item_data
	items_root.add_child(item)
	item.global_position = anchor.global_position
	item.global_rotation = anchor.global_rotation
	item.set_present(InventoryManager.is_present(item_data.id))
	_items_by_id[item_data.id] = item
	_item_rooms[item_data.id] = item_data.room_id


func _find_anchor(room: Node3D, anchor_name: StringName) -> Marker3D:
	var anchors_root := room.get_node_or_null("Anchors") as Node3D
	if anchors_root == null:
		push_error("House : nœud Anchors absent dans '%s'." % room.name)
		return null
	var anchor := anchors_root.get_node_or_null(NodePath(String(anchor_name))) as Marker3D
	if anchor == null:
		push_error("House : '%s' n'est pas un Marker3D dans '%s'." % [anchor_name, room.name])
	return anchor


func _on_item_moved(item_id: StringName, from_room: StringName, to_room: StringName, new_anchor: StringName) -> void:
	var item := _items_by_id.get(item_id) as Item
	if item == null:
		push_warning("House : item déplacé '%s' absent des salles chargées." % item_id)
		return
	var recorded_room := StringName(str(_item_rooms.get(item_id, "")))
	if recorded_room != &"" and recorded_room != from_room:
		push_warning("House : '%s' annoncé dans '%s' mais enregistré dans '%s'." % [item_id, from_room, recorded_room])

	var target_room := _rooms_by_id.get(to_room) as Node3D
	if target_room == null:
		push_error("House : salle cible '%s' absente pour le déplacement de '%s'." % [to_room, item_id])
		return
	var target_anchor := _find_anchor(target_room, new_anchor)
	if target_anchor == null:
		push_error("House : déplacement de '%s' annulé, ancre '%s' absente." % [item_id, new_anchor])
		return
	var target_items := target_room.get_node_or_null("Items") as Node3D
	if target_items == null:
		push_error("House : nœud Items absent dans la salle cible '%s'." % to_room)
		return
	item.reparent(target_items, true)
	item.global_position = target_anchor.global_position
	item.global_rotation = target_anchor.global_rotation
	_item_rooms[item_id] = to_room


func _on_item_revealed(item_id: StringName) -> void:
	var item := _items_by_id.get(item_id) as Item
	if item == null:
		push_warning("House : objet révélé '%s' absent des salles chargées." % item_id)
		return
	item.set_present(true)
