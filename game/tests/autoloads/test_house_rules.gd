## Tests gdUnit4 — moteur de règles HouseDirector (S-3) et séquenceur/fins (S-7/S-8).
## Tourne avec tools/run_tests.sh dès que gdUnit4 est installé (Q-1).
extends GdUnitTestSuite

var _events: Array[StringName] = []
var _moves: Array[Dictionary] = []
var _acts: Array[int] = []
var _endings: Array[StringName] = []


func before() -> void:
	_reset_all()
	EventBus.house_event_triggered.connect(_on_event)
	EventBus.item_moved.connect(_on_moved)
	EventBus.act_changed.connect(_on_act)
	EventBus.ending_reached.connect(_on_ending)


func after() -> void:
	EventBus.house_event_triggered.disconnect(_on_event)
	EventBus.item_moved.disconnect(_on_moved)
	EventBus.act_changed.disconnect(_on_act)
	EventBus.ending_reached.disconnect(_on_ending)


func _on_event(id: StringName) -> void:
	_events.append(id)


func _on_moved(id: StringName, from_room: StringName, to_room: StringName, anchor: StringName) -> void:
	_moves.append({"id": id, "from": from_room, "to": to_room, "anchor": anchor})


func _on_act(act: int) -> void:
	_acts.append(act)


func _on_ending(id: StringName) -> void:
	_endings.append(id)


func _reset_all() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_events.clear()
	_moves.clear()
	_acts.clear()
	_endings.clear()
	for i: int in range(1, 61):
		var item := ItemData.new()
		item.id = StringName("t%02d" % i)
		item.list_index = i
		item.room_id = &"hall"
		InventoryManager._register_item(item)


func _make_rule(id: StringName, trigger: String, param: String, condition: String, actions: Array[String]) -> HouseRule:
	var rule := HouseRule.new()
	rule.id = id
	rule.trigger = trigger
	rule.trigger_param = param
	rule.condition = condition
	rule.actions = actions
	rule.once = true
	return rule


func test_progress_rule_fires_once() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "progress", "3", "checked>=3 && !item_checked:t99", ["event:beat"]))
	for i: int in range(1, 4):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	assert_int(_events.count(&"beat")).is_equal(1)
	for i: int in range(4, 8):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	assert_int(_events.count(&"beat")).is_equal(1)


func test_rule_with_false_condition_is_silent() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "room_left", "hall", "checked>=999", ["event:nope"]))
	EventBus.player_left_room.emit(&"hall")
	assert_bool(&"nope" in _events).is_false()


func test_move_item_action() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "room_left", "hall", "", ["move_item:t01:kitchen:anchor_x"]))
	EventBus.player_left_room.emit(&"hall")
	assert_int(_moves.size()).is_equal(1)
	if _moves.size() == 1:
		assert_that(_moves[0]["id"]).is_equal(&"t01")
		assert_that(_moves[0]["to"]).is_equal(&"kitchen")
		assert_that(_moves[0]["anchor"]).is_equal(&"anchor_x")


func test_attention_and_presence_actions() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "doc_read", "doc", "", ["attention:+5", "presence:offscreen"]))
	DocumentLibrary.mark_read(&"doc")
	assert_float(GameState.attention).is_equal(5.0)
	assert_that(HouseDirector.to_save_dict().get("presence", "")).is_equal("offscreen")


func test_sequencer_thresholds_and_closed_ending() -> void:
	for i: int in range(1, 60):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	assert_array(_acts).is_equal([2, 3])
	assert_array(_endings).is_empty()
	InventoryManager.check_item(&"t60", PhotoData.new())
	assert_array(_endings).is_equal([&"closed"])
	assert_bool(&"act1_drawer_opens" in _events).is_true()
	assert_bool(&"phone_rings" in _events).is_true()
	assert_bool(&"cellar_door_opens" in _events).is_true()


func test_ashes_ending_wins() -> void:
	for i: int in range(1, 46):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	assert_array(_endings).is_equal([&"ashes"])
	for i: int in range(46, 61):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	assert_array(_endings).is_equal([&"ashes"])


func test_sequencer_event_dedup_with_rules() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "progress", "20", "", ["event:act1_drawer_opens"]))
	for i: int in range(1, 21):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	assert_int(_events.count(&"act1_drawer_opens")).is_equal(1)


func test_move_replayed_on_load() -> void:
	HouseDirector.register_rule(_make_rule(&"r", "room_left", "hall", "", ["move_item:t01:living:anchor_replay"]))
	EventBus.player_left_room.emit(&"hall")
	assert_int(_moves.size()).is_equal(1)
	var saved := HouseDirector.to_save_dict()
	HouseDirector.from_save_dict({})
	_moves.clear()
	HouseDirector.from_save_dict(saved)
	# from_save_dict ne réémet pas : le rejeu est porté par game_loaded (SaveManager).
	EventBus.game_loaded.emit()
	assert_int(_moves.size()).is_equal(1)
	if _moves.size() == 1:
		assert_that(_moves[0]["anchor"]).is_equal(&"anchor_replay")
