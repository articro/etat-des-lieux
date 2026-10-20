## Tests headless du placement, des déplacements et du prefab Item.
extends Node

var _assertions: int = 0
var _failures: int = 0
var _house: Node3D


func _ready() -> void:
	var packed := load("res://scenes/house/house.tscn") as PackedScene
	_expect(packed != null, "house.tscn se charge")
	if packed == null:
		_report_and_quit()
		return
	_house = packed.instantiate() as Node3D
	_expect(_house != null, "house.tscn a une racine 3D")
	if _house == null:
		_report_and_quit()
		return
	add_child(_house)
	await get_tree().process_frame

	_test_room_zones()
	_test_hall_blockout()
	_test_game_lighting()
	_test_added_room_blockouts()
	_test_cellar_integration()
	_test_item_population_and_reveal()
	await _test_hatch_event()
	_test_item_move()
	_test_item_prefab()
	_report_and_quit()


func _test_room_zones() -> void:
	var hall_zone := _house.get_node_or_null("Rooms/Hall/Zone") as Area3D
	var study_zone := _house.get_node_or_null("Rooms/Study/Zone") as Area3D
	var cellar_zone := _house.get_node_or_null("Rooms/Cellar/Zone") as Area3D
	var kitchen_zone := _house.get_node_or_null("Rooms/Kitchen/Zone") as Area3D
	var living_zone := _house.get_node_or_null("Rooms/Living/Zone") as Area3D
	var exterior_zone := _house.get_node_or_null("Rooms/Exterior/Zone") as Area3D
	_expect(hall_zone != null, "zone Area3D hall présente")
	_expect(study_zone != null, "zone Area3D study présente")
	_expect(cellar_zone != null, "zone Area3D cellar présente")
	_expect(kitchen_zone != null, "zone Area3D kitchen présente")
	_expect(living_zone != null, "zone Area3D living présente")
	_expect(exterior_zone != null, "zone Area3D exterior présente")
	if hall_zone != null:
		_expect(hall_zone.get_meta(&"room_id", &"") == &"hall", "metadata room_id hall")
		_expect(hall_zone.monitorable and hall_zone.collision_layer == 4, "zone hall monitorable / layer 4")
		var hall_collision := hall_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var hall_shape: BoxShape3D = null
		if hall_collision != null:
			hall_shape = hall_collision.shape as BoxShape3D
		_expect(hall_shape != null and hall_shape.size.is_equal_approx(Vector3(3, 2.6, 9)), "dimensions du hall 3 × 9 m, plafond 2,6 m")
	if study_zone != null:
		_expect(study_zone.get_meta(&"room_id", &"") == &"study", "metadata room_id study")
		_expect(study_zone.monitorable and study_zone.collision_layer == 4, "zone study monitorable / layer 4")
		var study_collision := study_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var study_shape: BoxShape3D = null
		if study_collision != null:
			study_shape = study_collision.shape as BoxShape3D
		_expect(study_shape != null and study_shape.size.is_equal_approx(Vector3(4.5, 2.6, 4)), "dimensions du bureau 4 × 4,5 m, plafond 2,6 m")
	if cellar_zone != null:
		_expect(cellar_zone.get_meta(&"room_id", &"") == &"cellar", "metadata room_id cellar")
		_expect(cellar_zone.monitorable and cellar_zone.collision_layer == 4, "zone cellar monitorable / layer 4")
		var cellar_collision := cellar_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var cellar_shape: BoxShape3D = null
		if cellar_collision != null:
			cellar_shape = cellar_collision.shape as BoxShape3D
		_expect(cellar_shape != null and cellar_shape.size.is_equal_approx(Vector3(6, 2.1, 4)), "dimensions de cave 6 × 4 m, hauteur 2,1 m")
	if kitchen_zone != null:
		_expect(kitchen_zone.get_meta(&"room_id", &"") == &"kitchen", "metadata room_id kitchen")
		_expect(kitchen_zone.monitorable and kitchen_zone.collision_layer == 4, "zone kitchen monitorable / layer 4")
		var kitchen_collision := kitchen_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var kitchen_shape: BoxShape3D = null
		if kitchen_collision != null:
			kitchen_shape = kitchen_collision.shape as BoxShape3D
		_expect(kitchen_shape != null and kitchen_shape.size.is_equal_approx(Vector3(4.5, 2.6, 4.5)), "dimensions cuisine 4,5 × 4,5 m, plafond 2,6 m")
	if living_zone != null:
		_expect(living_zone.get_meta(&"room_id", &"") == &"living", "metadata room_id living")
		_expect(living_zone.monitorable and living_zone.collision_layer == 4, "zone living monitorable / layer 4")
		var living_collision := living_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var living_shape: BoxShape3D = null
		if living_collision != null:
			living_shape = living_collision.shape as BoxShape3D
		_expect(living_shape != null and living_shape.size.is_equal_approx(Vector3(5, 2.6, 5)), "dimensions salon 5 × 5 m, plafond 2,6 m")
	if exterior_zone != null:
		_expect(exterior_zone.get_meta(&"room_id", &"") == &"exterior", "metadata room_id exterior")
		_expect(exterior_zone.monitorable and exterior_zone.collision_layer == 4, "zone exterior monitorable / layer 4")
		var exterior_collision := exterior_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var exterior_shape: BoxShape3D = null
		if exterior_collision != null:
			exterior_shape = exterior_collision.shape as BoxShape3D
		_expect(exterior_shape != null and exterior_shape.size.is_equal_approx(Vector3(14, 2.6, 9)), "dimensions de la cour 14 × 9 m")


func _test_hall_blockout() -> void:
	var hall := _house.get_node_or_null("Rooms/Hall") as Node3D
	_expect(hall != null, "blockout du hall instancié")
	if hall == null:
		return
	var note := hall.get_node_or_null("Blockout/BesnardNote") as CSGBox3D
	var phone := hall.get_node_or_null("Blockout/PhoneBase") as CSGBox3D
	var stairs := hall.get_node_or_null("Anchors/hall_anchor_stairs_top") as Marker3D
	var camera := hall.get_node_or_null("StandaloneCamera") as Camera3D
	_expect(note != null and note.get_meta(&"document_id", &"") == &"hall_postit_besnard", "mot interactif de Besnard dans le hall")
	_expect(phone != null and hall.get_node_or_null("Items/hall_answering_machine") != null, "téléphone + répondeur dans le hall")
	_expect(stairs != null and stairs.global_position.z > 4.5, "ancre d'apparition au sommet des marches condamnées")
	_expect(camera != null and camera.global_transform.basis.z.z < -0.99, "longue vue du hall orientée depuis l'entrée")


func _test_game_lighting() -> void:
	var world_environment := _house.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_expect(world_environment != null and world_environment.environment != null, "WorldEnvironment de la maison présent")
	if world_environment == null or world_environment.environment == null:
		return
	var environment := world_environment.environment
	_expect(environment.background_color.r < 0.03 and environment.ambient_light_energy < 0.3, "ambiance globale très sombre")
	_expect(environment.tonemap_mode == Environment.TONE_MAPPER_ACES, "tonemap ACES actif")
	_expect(environment.fog_enabled and environment.volumetric_fog_enabled, "fog de distance et volumétrique activés")

	var hall_light := _house.get_node_or_null("Rooms/Hall/PracticalLights/HallCeilingLight") as OmniLight3D
	var study_light := _house.get_node_or_null("Rooms/Study/PracticalLights/StudyDeskLamp") as OmniLight3D
	var cellar_light := _house.get_node_or_null("Rooms/Cellar/PracticalLights/CellarBareBulbLight") as OmniLight3D
	_expect(hall_light != null and hall_light.shadow_enabled and hall_light.light_energy < 1.0, "plafonnier bas du hall avec ombres")
	_expect(study_light != null and study_light.shadow_enabled and study_light.light_energy < 1.0, "lampe de bureau faible avec ombres")
	_expect(cellar_light != null and not cellar_light.shadow_enabled, "ampoule nue de cave sans ombres")
	var shadowed_omni_count: int = 0
	for light_node: Node in _house.find_children("*", "OmniLight3D", true, false):
		var omni := light_node as OmniLight3D
		if omni != null and omni.shadow_enabled:
			shadowed_omni_count += 1
	_expect(shadowed_omni_count <= 4, "budget des OmniLight avec ombres respecté")

	var preview_lights := _house.get_node_or_null("StandaloneLights") as Node3D
	var hall_preview_lights := _house.get_node_or_null("Rooms/Hall/StandaloneLights") as Node3D
	_expect(preview_lights != null and not preview_lights.visible, "lumières de preview house masquées en jeu")
	_expect(hall_preview_lights != null and not hall_preview_lights.visible, "lumières de preview hall masquées en jeu")
	for room_name: String in ["Study", "Cellar", "Kitchen", "Living", "Exterior"]:
		var room_preview := _house.get_node_or_null(NodePath("Rooms/" + room_name + "/StandaloneLights")) as Node3D
		_expect(room_preview != null and not room_preview.visible, "lumières de preview masquées : " + room_name)
	var spawn := _house.get_node_or_null("PlayerSpawn") as Marker3D
	_expect(spawn != null and _house.has_method("player_spawn_transform"), "contrat PlayerSpawn préservé")
	if spawn != null and _house.has_method("player_spawn_transform"):
		_expect(_house.call("player_spawn_transform") == spawn.global_transform, "transform de spawn fourni par house.gd")


func _test_added_room_blockouts() -> void:
	var rooms := _house.get_node_or_null("Rooms") as Node3D
	var kitchen := _house.get_node_or_null("Rooms/Kitchen") as Node3D
	var living := _house.get_node_or_null("Rooms/Living") as Node3D
	var exterior := _house.get_node_or_null("Rooms/Exterior") as Node3D
	_expect(rooms != null and rooms.get_child_count() == 6, "les six zones V1 sont composées")
	_expect(kitchen != null and living != null and exterior != null, "cuisine, salon et extérieur instanciés")
	_expect(_house.get_node_or_null("TempBlockers") == null, "TempBlockers retirés après livraison des pièces")
	if kitchen == null or living == null or exterior == null:
		return

	var kitchen_items := kitchen.get_node_or_null("Items") as Node3D
	var living_items := living.get_node_or_null("Items") as Node3D
	var exterior_items := exterior.get_node_or_null("Items") as Node3D
	_expect(kitchen_items != null and kitchen_items.get_child_count() == 16, "16 objets de cuisine instanciés")
	_expect(living_items != null and living_items.get_child_count() == 14, "14 objets du salon instanciés")
	_expect(exterior_items != null and exterior_items.get_child_count() == 4, "4 objets d'extérieur instanciés")
	_expect(kitchen.get_node_or_null("Anchors/kitchen_anchor_sink") is Marker3D, "ancre de règle près de l'évier présente")
	_expect(kitchen.get_node_or_null("Anchors/kitchen_anchor_sink_item") is Marker3D, "ancre de l'évier distincte de la cible de règle")
	_expect(kitchen.get_node_or_null("Anchors/kitchen_anchor_preserves") is Marker3D, "cible de règle des confitures présente")
	_expect(kitchen.get_node_or_null("Anchors/kitchen_anchor_preserves_item") is Marker3D, "ancre des confitures distincte de la cible")
	_expect(living.get_node_or_null("Anchors/living_anchor_fireplace") is Marker3D, "cible de règle près de la cheminée présente")
	_expect(living.get_node_or_null("Anchors/living_anchor_fireplace_item") is Marker3D, "ancre de cheminée distincte de la cible")

	var ground := exterior.get_node_or_null("Blockout/Ground") as CSGBox3D
	_expect(ground != null and ground.use_collision, "sol extérieur avec collision")
	for boundary_name: String in ["FenceWest", "FenceEast", "NorthFenceLeft", "NorthFenceRight", "SouthFenceLeft", "SouthFenceRight"]:
		var boundary := exterior.get_node_or_null(NodePath("Blockout/" + boundary_name)) as CSGBox3D
		_expect(boundary != null and boundary.use_collision, "clôture périmétrique avec collision : " + boundary_name)
	for gate_name: String in ["GatePanelLeft", "GatePanelRight"]:
		var gate_panel := exterior.get_node_or_null(NodePath("Blockout/" + gate_name)) as CSGBox3D
		_expect(gate_panel != null and gate_panel.use_collision, "portail fermé avec collision : " + gate_name)
	var hall_boards := _house.get_node_or_null("Rooms/Hall/Blockout") as Node3D
	var stair_board: CSGBox3D = null
	var stairwell_barrier: CSGBox3D = null
	if hall_boards != null:
		stair_board = hall_boards.get_node_or_null("BoardVertical") as CSGBox3D
		stairwell_barrier = hall_boards.get_node_or_null("StairwellBarrier") as CSGBox3D
	_expect(stair_board != null and stair_board.use_collision, "planches de l'escalier avec collision")
	_expect(stairwell_barrier != null and stairwell_barrier.use_collision, "fond de l'escalier condamné avec collision")


func _test_cellar_integration() -> void:
	var cellar := _house.get_node_or_null("Rooms/Cellar") as Node3D
	_expect(cellar != null, "blockout cave instancié sous la cuisine réservée")
	if cellar == null:
		return
	_expect(is_equal_approx(cellar.global_position.y, -2.1), "cave placée sous le plancher de la cuisine")
	var spawn := cellar.get_node_or_null("Anchors/cellar_anchor_presence_spawn") as Marker3D
	var presence := cellar.get_node_or_null("Presence") as Presence
	_expect(spawn != null and presence != null, "repère et scène de Présence présents dans la cave")
	if spawn != null and presence != null:
		_expect(presence.global_position.is_equal_approx(spawn.global_position), "Présence positionnée sur son ancre")
		_expect(not presence.is_active(), "Présence dormante au chargement")
		presence.set_state(&"physical")
		_expect(presence.is_active(), "Présence activable par l'API du module Gameplay")
		presence.set_state(&"offscreen")
	var hatch_hinge := _house.get_node_or_null("Rooms/Kitchen/Blockout/HatchHinge") as Node3D
	if hatch_hinge != null:
		var kitchen_hatch_center := hatch_hinge.global_position + Vector3(0, 0, -0.5)
		var cellar_hatch_center := cellar.global_position + Vector3(1, 2.16, -1)
		_expect(is_equal_approx(kitchen_hatch_center.x, cellar_hatch_center.x) and is_equal_approx(kitchen_hatch_center.z, cellar_hatch_center.z), "trappe cuisine alignée sur l'ouverture de cave")
	var register := cellar.get_node_or_null("Blockout/Register1847") as CSGBox3D
	_expect(register != null and register.get_meta(&"document_id", &"") == &"cellar_register_1847", "registre 1847 interactif placé près du poêle")
	var stove := _find_item(&"cellar_stove")
	_expect(stove != null, "poêle Item instancié depuis son prefab dédié")
	if stove != null:
		var interaction: Dictionary = Interactor.describe(stove)
		_expect(interaction.get("id", &"") == &"cellar_stove", "Interactor identifie le poêle")
		_expect(interaction.get("kind", &"") == &"burn", "poêle configuré en burn")
		_expect(is_equal_approx(float(interaction.get("duration", 0.0)), 8.0), "interaction du poêle dure 8 secondes")


func _test_item_population_and_reveal() -> void:
	var loaded_ids: Dictionary[StringName, bool] = {}
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"items"):
		if not _house.is_ancestor_of(node):
			continue
		var item := node as Item
		if item == null or item.data == null:
			continue
		loaded_ids[item.data.id] = true
		count += 1
	_expect(count == 60, "60 objets instanciés dans les six zones V1")
	var items_match_anchors: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"items"):
		if not _house.is_ancestor_of(node):
			continue
		var item := node as Item
		if item == null or item.data == null or item.data.anchors.is_empty():
			continue
		var room := item.get_parent().get_parent() as Node3D
		if room == null:
			continue
		var marker := room.get_node_or_null(NodePath("Anchors/" + String(item.data.anchors[0]))) as Marker3D
		if marker != null and item.global_position.is_equal_approx(marker.global_position):
			items_match_anchors += 1
	_expect(items_match_anchors == 60, "les 60 objets présents sont à leur ancre initiale")
	_expect(loaded_ids.has(&"hall_answering_machine"), "répondeur du hall instancié")
	_expect(loaded_ids.has(&"study_stamp"), "cachet du bureau instancié")
	var phantom := _find_item(&"hall_hand_railing")
	_expect(phantom != null, "fantôme du hall instancié en attente")
	if phantom != null:
		_expect(not phantom.visible, "fantôme masqué avant révélation")
		var shape := phantom.get_node_or_null("Collision/Shape") as CollisionShape3D
		_expect(shape != null and shape.disabled, "collider du fantôme désactivé")
		EventBus.item_revealed.emit(&"hall_hand_railing")
		_expect(phantom.visible, "fantôme visible après item_revealed")
		if shape != null:
			_expect(not shape.disabled, "collider réactivé après révélation")


func _test_hatch_event() -> void:
	var hinge := _house.get_node_or_null("Rooms/Kitchen/Blockout/HatchHinge") as Node3D
	var panel := _house.get_node_or_null("Rooms/Kitchen/Blockout/HatchHinge/HatchPanel") as CSGBox3D
	_expect(hinge != null and panel != null and panel.use_collision, "trappe de cave fermée et colmatée au démarrage")
	if hinge == null or panel == null:
		return
	_expect(hinge.rotation_degrees.is_zero_approx(), "charnière de trappe initialement fermée")
	EventBus.house_event_triggered.emit(&"cellar_door_opens")
	await get_tree().create_timer(1.0).timeout
	_expect(hinge.rotation_degrees.x > 85.0, "événement cellar_door_opens ouvre la trappe vers la cave")


func _test_item_move() -> void:
	var stamp := _find_item(&"study_stamp")
	var hall_items := _house.get_node_or_null("Rooms/Hall/Items") as Node3D
	var marker := _house.get_node_or_null("Rooms/Hall/Anchors/hall_anchor_console") as Marker3D
	_expect(stamp != null and hall_items != null and marker != null, "cible du déplacement hall disponible")
	if stamp == null or hall_items == null or marker == null:
		return
	EventBus.item_moved.emit(&"study_stamp", &"study", &"hall", &"hall_anchor_console")
	_expect(stamp.get_parent() == hall_items, "item_moved reparent vers la salle cible")
	_expect(stamp.global_position.is_equal_approx(marker.global_position), "item_moved place à l'ancre cible")


func _test_item_prefab() -> void:
	var packed := load("res://scenes/items/item.tscn") as PackedScene
	_expect(packed != null, "item.tscn se charge")
	if packed == null:
		return
	var item := packed.instantiate() as Item
	_expect(item != null, "prefab racine class_name Item")
	if item == null:
		return
	item.data = InventoryManager.get_item(&"hall_console_table")
	add_child(item)
	var inspection: Dictionary = item.get_inspection_data()
	_expect(inspection.get(&"id", &"") == &"hall_console_table", "inspection expose l'id de l'objet")
	_expect(inspection.has(&"label") and inspection.has(&"lore"), "inspection expose les textes traduits")
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 1.4)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	var coverage := item.is_in_frustum(camera)
	_expect(coverage > 0.0 and coverage <= 1.0, "is_in_frustum renvoie une couverture bornée")
	item.set_highlight(true)
	var highlight := item.get_node_or_null("Highlight") as MeshInstance3D
	_expect(highlight != null and highlight.visible, "surbrillance activable")
	item.queue_free()
	camera.queue_free()


func _find_item(item_id: StringName) -> Item:
	for node: Node in get_tree().get_nodes_in_group(&"items"):
		if not _house.is_ancestor_of(node):
			continue
		var item := node as Item
		if item != null and item.data != null and item.data.id == item_id:
			return item
	return null


func _expect(condition: bool, label: String) -> void:
	_assertions += 1
	if condition:
		return
	_failures += 1
	push_error("Test Niveau : %s." % label)


func _report_and_quit() -> void:
	print("Niveau — %d assertions, %d échec(s)." % [_assertions, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
