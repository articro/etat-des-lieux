## Tests gdUnit4 — parser du mini-langage de conditions (HouseDirector, ARCHITECTURE §6).
## Les cas de syntaxe invalide (push_error attendu) sont couverts par
## res://scenes/main/test_systems.tscn ; ici les cas valides + moteur.
## Tourne avec tools/run_tests.sh dès que gdUnit4 est installé (Q-1).
extends GdUnitTestSuite


func before() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	var item := ItemData.new()
	item.id = &"t01"
	item.room_id = &"hall"
	item.list_index = 1
	InventoryManager._register_item(item)
	var phantom := ItemData.new()
	phantom.id = &"t_phantom"
	phantom.room_id = &"hall"
	phantom.list_index = 2
	phantom.is_phantom = true
	InventoryManager._register_item(phantom)


func test_empty_condition() -> void:
	assert_bool(HouseDirector.evaluate_condition("")).is_true()
	assert_bool(HouseDirector.evaluate_condition("   ")).is_true()


func test_checked_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("checked>=0")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked>=999")).is_false()
	assert_bool(HouseDirector.evaluate_condition("checked<=1")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked<0")).is_false()
	assert_bool(HouseDirector.evaluate_condition("checked==0")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked!=0")).is_false()


func test_act_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("act==1")).is_true()
	assert_bool(HouseDirector.evaluate_condition("act!=1")).is_false()
	assert_bool(HouseDirector.evaluate_condition("act>=1")).is_true()


func test_attention_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("attention>=0")).is_true()
	assert_bool(HouseDirector.evaluate_condition("attention>0")).is_false()
	GameState.attention = 42.0
	assert_bool(HouseDirector.evaluate_condition("attention>30")).is_true()
	assert_bool(HouseDirector.evaluate_condition("attention<=42")).is_true()
	GameState.attention = 0.0


func test_flag_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("flag:my_flag")).is_false()
	assert_bool(HouseDirector.evaluate_condition("!flag:my_flag")).is_true()
	GameState.set_flag(&"my_flag")
	assert_bool(HouseDirector.evaluate_condition("flag:my_flag")).is_true()
	assert_bool(HouseDirector.evaluate_condition("!flag:my_flag")).is_false()


func test_doc_read_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("doc_read:some_doc")).is_false()
	DocumentLibrary.mark_read(&"some_doc")
	assert_bool(HouseDirector.evaluate_condition("doc_read:some_doc")).is_true()
	assert_bool(HouseDirector.evaluate_condition("!doc_read:some_doc")).is_false()


func test_item_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("item_checked:t01")).is_false()
	assert_bool(HouseDirector.evaluate_condition("item_present:t01")).is_true()
	assert_bool(HouseDirector.evaluate_condition("item_present:t_phantom")).is_false()
	InventoryManager.check_item(&"t01", PhotoData.new())
	assert_bool(HouseDirector.evaluate_condition("item_checked:t01")).is_true()


func test_room_and_presence_predicates() -> void:
	assert_bool(HouseDirector.evaluate_condition("room:hall")).is_false()
	EventBus.player_entered_room.emit(&"hall")
	assert_bool(HouseDirector.evaluate_condition("room:hall")).is_true()
	assert_bool(HouseDirector.evaluate_condition("presence:dormant")).is_true()
	HouseDirector.set_presence_state(&"offscreen")
	assert_bool(HouseDirector.evaluate_condition("presence:offscreen")).is_true()
	assert_bool(HouseDirector.evaluate_condition("presence:dormant")).is_false()


func test_negation_universal() -> void:
	assert_bool(HouseDirector.evaluate_condition("!item_checked:t99")).is_true()
	assert_bool(HouseDirector.evaluate_condition("!doc_read:nope")).is_true()
	assert_bool(HouseDirector.evaluate_condition("!(checked>=999)")).is_true()
	assert_bool(HouseDirector.evaluate_condition("!!item_checked:t01")).is_false()


func test_combinators() -> void:
	assert_bool(HouseDirector.evaluate_condition("checked>=0 && act==1")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked>=999 && act==1")).is_false()
	assert_bool(HouseDirector.evaluate_condition("checked>=999 || act==1")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked>=999 || act==9")).is_false()
	assert_bool(HouseDirector.evaluate_condition("(checked>=999 || act==1) && !flag:nope")).is_true()
	assert_bool(HouseDirector.evaluate_condition("checked>=0 && (act==9 || !flag:nope)")).is_true()


func test_whitespace_tolerance() -> void:
	assert_bool(HouseDirector.evaluate_condition("  checked  >=  0  &&  act  ==  1  ")).is_true()
