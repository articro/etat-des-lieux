## Tests gdUnit4 — InventoryManager (S-2).
## Tourne avec tools/run_tests.sh dès que gdUnit4 est installé (Q-1).
extends GdUnitTestSuite

var _lines: Array[Array] = []


func before() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	_lines.clear()
	EventBus.inventory_line_added.connect(_on_line_added)
	for i: int in range(1, 4):
		var item := ItemData.new()
		item.id = StringName("t%02d" % i)
		item.list_index = i
		item.room_id = &"hall" if i < 3 else &"kitchen"
		InventoryManager._register_item(item)


func after() -> void:
	EventBus.inventory_line_added.disconnect(_on_line_added)


func _on_line_added(index: int, key: StringName) -> void:
	_lines.append([index, key])


func test_check_item_and_progress() -> void:
	assert_that(InventoryManager.progress()).is_equal(Vector2i(0, 3))
	assert_bool(InventoryManager.check_item(&"t01", PhotoData.new())).is_true()
	assert_bool(InventoryManager.check_item(&"t01", PhotoData.new())).is_false()
	assert_that(InventoryManager.progress()).is_equal(Vector2i(1, 3))


func test_check_unknown_or_missing_item() -> void:
	assert_bool(InventoryManager.check_item(&"nope", PhotoData.new())).is_false()
	assert_bool(InventoryManager.is_present(&"nope")).is_false()
	assert_that(InventoryManager.get_item(&"nope")).is_null()


func test_phantom_reveal_and_presence() -> void:
	var phantom := ItemData.new()
	phantom.id = &"t_phantom"
	phantom.list_index = 9
	phantom.room_id = &"hall"
	phantom.is_phantom = true
	InventoryManager._register_item(phantom)
	assert_bool(InventoryManager.is_present(&"t_phantom")).is_false()
	assert_bool(InventoryManager.check_item(&"t_phantom", PhotoData.new())).is_false()
	InventoryManager.reveal_item(&"t_phantom")
	assert_bool(InventoryManager.is_present(&"t_phantom")).is_true()
	assert_bool(InventoryManager.check_item(&"t_phantom", PhotoData.new())).is_true()


func test_get_items_in_room_sorted() -> void:
	var hall := InventoryManager.get_items_in_room(&"hall")
	assert_int(hall.size()).is_equal(2)
	if hall.size() == 2:
		assert_that(hall[0].id).is_equal(&"t01")
		assert_that(hall[1].id).is_equal(&"t02")


func test_films() -> void:
	assert_int(InventoryManager.film_count()).is_equal(InventoryManager.STARTING_FILM)
	InventoryManager.add_film(-20)
	assert_int(InventoryManager.film_count()).is_equal(0)
	InventoryManager.add_film(2)
	assert_bool(InventoryManager.consume_film()).is_true()
	assert_bool(InventoryManager.consume_film()).is_true()
	assert_bool(InventoryManager.consume_film()).is_false()


func test_final_line_on_all_checked() -> void:
	InventoryManager.check_item(&"t01", PhotoData.new())
	InventoryManager.check_item(&"t02", PhotoData.new())
	assert_array(_lines).is_empty()
	InventoryManager.check_item(&"t03", PhotoData.new())
	assert_int(_lines.size()).is_equal(1)
	if _lines.size() == 1:
		assert_that(_lines[0][0]).is_equal(4)
		assert_that(_lines[0][1]).is_equal(&"INV_LINE_ADDED_CAMILLE")


func test_save_roundtrip() -> void:
	InventoryManager.check_item(&"t01", PhotoData.new())
	var d := InventoryManager.to_save_dict()
	InventoryManager._reset_for_tests()
	for i: int in range(1, 4):
		var item := ItemData.new()
		item.id = StringName("t%02d" % i)
		item.list_index = i
		InventoryManager._register_item(item)
	InventoryManager.from_save_dict(d)
	assert_bool(InventoryManager.is_checked(&"t01")).is_true()
	assert_that(InventoryManager.progress()).is_equal(Vector2i(1, 3))


func test_check_random_unchecked() -> void:
	assert_bool(InventoryManager.check_item(&"t01", PhotoData.new())).is_true()
	assert_bool(InventoryManager._check_random_unchecked()).is_true()
	assert_that(InventoryManager.progress()).is_equal(Vector2i(2, 3))
	assert_bool(InventoryManager._check_random_unchecked()).is_true()
	assert_that(InventoryManager.progress()).is_equal(Vector2i(3, 3))
	assert_bool(InventoryManager._check_random_unchecked()).is_false()


func test_all_items_sorted() -> void:
	var all := InventoryManager.all_items()
	assert_int(all.size()).is_equal(3)
	assert_that(all[0].id).is_equal(&"t01")
	assert_that(all[1].id).is_equal(&"t02")
	assert_that(all[2].id).is_equal(&"t03")
