## Scène de test du module Audio (périmètre : tests/audio/).
##
## Deux usages :
##   • F6 (ou lecture de la scène) : une petite interface pour écouter chaque son,
##     tester les pas selon le matériau, la séquence complète de l'appareil photo
##     et les réactions de l'AudioManager aux signaux du jeu.
##   • Headless (`bash game/tests/audio/run_headless.sh`) : un test de fumée qui
##     joue tous les ids, émet tous les signaux consommés par l'AudioManager et
##     imprime un rapport. Aucune erreur ne doit apparaître.
##
## La scène fabrique son propre monde (5 sols avec metadata `surface`) : elle ne
## dépend d'aucun autre module.

extends Node3D

const FLOORS: Array[Dictionary] = [
	{"surface": &"wood", "x": -6.0, "color": Color(0.42, 0.28, 0.16)},
	{"surface": &"tile", "x": -3.0, "color": Color(0.55, 0.57, 0.58)},
	{"surface": &"carpet", "x": 0.0, "color": Color(0.36, 0.20, 0.22)},
	{"surface": &"gravel", "x": 3.0, "color": Color(0.33, 0.32, 0.30)},
	{"surface": &"stone", "x": 6.0, "color": Color(0.30, 0.31, 0.33)},
]

const CAMERA_IDS: Array[StringName] = [
	&"camera_raise", &"camera_shutter", &"camera_flash", &"photo_slide", &"camera_dry",
]

const UI_IDS: Array[StringName] = [
	&"flashlight_click", &"notebook_open", &"notebook_close", &"pencil_check", &"photo_ready",
]

const INTERACT_IDS: Array[StringName] = [
	&"drawer_open", &"door_open", &"door_close", &"interact_open", &"interact_pickup",
	&"interact_paper", &"interact_generic", &"fire_start",
]

const HOUSE_IDS: Array[StringName] = [
	&"house_creak_01", &"house_creak_02", &"house_creak_03", &"house_pipe_01", &"house_pipe_02",
	&"clock_chime_distant",
]

const PRESENCE_IDS: Array[StringName] = [
	&"chair_drag_upstairs", &"upstairs_chair", &"footsteps_above", &"door_close_upstairs",
	&"phone_ring", &"water_drip", &"paper_turn", &"breath_low", &"hall_light_out",
	&"cellar_light_flicker", &"caught_impact",
]

const PLAYER_IDS: Array[StringName] = [
	&"footstep_wood", &"footstep_tile", &"footstep_carpet", &"footstep_gravel",
	&"footstep_stone", &"bag_leather", &"breath_in", &"breath_out",
]

const MUSIC_IDS: Array[StringName] = [&"music_ending_closed", &"music_ending_ashes"]

const LAYER_IDS: Array[StringName] = [
	&"house_base", &"house_unease", &"house_dread", &"exterior", &"presence",
]

var _status: Label = null
var _surface_label: Label = null
var _listener_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	_build_world()
	if DisplayServer.get_name() in ["headless", "dummy"]:
		await get_tree().physics_frame
		await _smoke_test()
		get_tree().quit()
		return
	_build_ui()
	_status.text = "Prêt. Boutons = écouter. 1-5 = se placer sur un sol."


# ------------------------------------------------------------------- monde

func _build_world() -> void:
	var cam := Camera3D.new()
	cam.name = "Listener"
	cam.position = Vector3(0.0, 1.7, 6.0)
	cam.rotation = Vector3(-0.12, 0.0, 0.0)
	add_child(cam)
	cam.make_current()
	var light := DirectionalLight3D.new()
	light.name = "Light"
	light.rotation = Vector3(-0.9, 0.4, 0.0)
	add_child(light)
	for f in FLOORS:
		var body := StaticBody3D.new()
		body.name = "Floor_%s" % f["surface"]
		body.position = Vector3(f["x"], 0.0, 0.0)
		body.set_meta(&"surface", f["surface"])
		body.add_to_group(&"test_floors")
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.8, 0.2, 8.0)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = f["color"]
		mesh.material_override = mat
		body.add_child(mesh)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.8, 0.2, 8.0)
		col.shape = shape
		body.add_child(col)
		add_child(body)


func _floor_position(surface: StringName) -> Vector3:
	for f in FLOORS:
		if StringName(f["surface"]) == surface:
			return Vector3(f["x"], 0.1, 0.0)
	return Vector3.ZERO


# ---------------------------------------------------------------------- UI

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(12, 12)
	canvas.add_child(panel)
	var root := VBoxContainer.new()
	panel.add_child(root)
	_status = Label.new()
	root.add_child(_status)
	_surface_label = Label.new()
	root.add_child(_surface_label)
	root.add_child(_section("Appareil photo (priorité 1)", CAMERA_IDS, _play_ui_id))
	root.add_child(_button("Séquence complète : lever, déclencher, flash, éjection", _play_camera_sequence))
	root.add_child(_section("Interface / mains", UI_IDS, _play_ui_id))
	root.add_child(_section("Joueur : pas et souffle", PLAYER_IDS, _play_ui_id))
	root.add_child(_section("Interactions", INTERACT_IDS, _play_ui_id))
	root.add_child(_section("Maison", HOUSE_IDS, _play_ui_id))
	root.add_child(_section("Présence (sons domestiques)", PRESENCE_IDS, _play_ui_id))
	var surfaces := PackedStringArray()
	for f in FLOORS:
		surfaces.append(String(f["surface"]))
	root.add_child(_section("Se placer sur…", Array(surfaces), _place_on))
	root.add_child(_button("Un pas (marche)", func() -> void: _step(false)))
	root.add_child(_button("Un pas (course)", func() -> void: _step(true)))
	root.add_child(_button("Tester la Présence (physique)", func() -> void:
		EventBus.presence_state_changed.emit(&"physical")))
	root.add_child(_button("Tester player_caught", func() -> void:
		EventBus.player_caught.emit()))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(320, 0)
	slider.value_changed.connect(func(v: float) -> void:
		EventBus.house_attention_changed.emit(v))
	root.add_child(_label("Attention de la maison (0-100)"))
	root.add_child(slider)
	root.add_child(_button("Fin : Inventaire clos", func() -> void:
		EventBus.ending_reached.emit(&"closed")))
	root.add_child(_button("Fin : Cendres", func() -> void:
		EventBus.ending_reached.emit(&"ashes")))
	root.add_child(_button("Stop musique", func() -> void: AudioManager.stop_music(1.0)))


func _section(title: String, ids: Array, cb: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_label(title))
	var flow := HFlowContainer.new()
	box.add_child(flow)
	for id in ids:
		var b := Button.new()
		b.text = String(id)
		b.pressed.connect(cb.bind(StringName(id)))
		flow.add_child(b)
	return box


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _play_ui_id(sfx_id: StringName) -> void:
	AudioManager.play_ui(sfx_id)
	if _status != null:
		_status.text = "Joué : %s" % sfx_id


func _play_sfx_id(sfx_id: StringName) -> void:
	AudioManager.play_sfx(sfx_id)
	if _status != null:
		_status.text = "Joué : %s" % sfx_id


func _place_on(surface: StringName) -> void:
	_listener_pos = _floor_position(surface)
	var cam: Camera3D = get_node_or_null("Listener") as Camera3D
	if cam != null:
		cam.position = _listener_pos + Vector3(0.0, 1.6, 3.0)
	_step(false)


func _step(running: bool) -> void:
	EventBus.player_noise.emit(0.85 if running else 0.25, _listener_pos)
	await get_tree().process_frame
	if _surface_label != null:
		_surface_label.text = "Matériau détecté : %s" % AudioManager.current_surface()


func _play_camera_sequence() -> void:
	AudioManager.play_ui(&"camera_raise")
	await get_tree().create_timer(0.75).timeout
	AudioManager.play_ui(&"camera_shutter")
	await get_tree().create_timer(0.05).timeout
	AudioManager.play_ui(&"camera_flash")
	await get_tree().create_timer(0.10).timeout
	AudioManager.play_ui(&"photo_slide")


# ------------------------------------------------------- test headless (CI)

func _smoke_test() -> void:
	print("=== TEST AUDIO — registre ===")
	var missing: int = 0
	for id in AudioManager.sfx_ids():
		var ok: bool = AudioManager.sfx_is_available(id)
		if not ok:
			missing += 1
		print("  %-26s %-5s %.2f s" % [id, "OK" if ok else "MANQUE", AudioManager.sfx_duration(id)])
	print("  ids: %d, manquants: %d" % [AudioManager.sfx_ids().size(), missing])

	print("=== TEST AUDIO — lecture de chaque id ===")
	for id in AudioManager.sfx_ids():
		if id in LAYER_IDS or id in MUSIC_IDS:
			continue
		AudioManager.play_sfx(id)
		await get_tree().create_timer(0.02).timeout
	print("  %d ids joués" % (AudioManager.sfx_ids().size() - LAYER_IDS.size() - MUSIC_IDS.size()))

	print("=== TEST AUDIO — pas par matériau ===")
	for f in FLOORS:
		var surface: StringName = f["surface"]
		var pos: Vector3 = _floor_position(surface)
		EventBus.player_noise.emit(0.25, pos)
		await get_tree().create_timer(0.16).timeout
		var got: StringName = AudioManager.current_surface()
		print("  %-8s -> %-8s %s" % [surface, got, "OK" if got == surface else "ECHEC"])

	print("=== TEST AUDIO — signaux du jeu ===")
	EventBus.player_entered_room.emit(&"kitchen")
	EventBus.player_interacted.emit(&"study_desk", &"open")
	EventBus.player_interacted.emit(&"study_drawer_1", &"open")
	EventBus.player_interacted.emit(&"hall_door", &"open")
	EventBus.player_interacted.emit(&"living_book", &"read")
	EventBus.player_interacted.emit(&"kitchen_key_l", &"pickup")
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	EventBus.house_attention_changed.emit(35.0)
	print("  attention 35 -> inquiétude %.2f / angoisse %.2f" % [
		AudioManager.layer_intensity(&"house_unease"), AudioManager.layer_intensity(&"house_dread")])
	EventBus.house_attention_changed.emit(70.0)
	print("  attention 70 -> inquiétude %.2f / angoisse %.2f" % [
		AudioManager.layer_intensity(&"house_unease"), AudioManager.layer_intensity(&"house_dread")])
	EventBus.presence_state_changed.emit(&"physical")
	EventBus.presence_state_changed.emit(&"dormant")
	EventBus.flash_fired.emit(Vector3.ZERO, &"kitchen")
	EventBus.photo_taken.emit(PhotoData.new())
	EventBus.photo_developed.emit(PhotoData.new())
	EventBus.item_checked.emit(&"kitchen_clock_stopped", PhotoData.new())
	EventBus.notebook_opened.emit()
	EventBus.notebook_closed.emit()
	EventBus.settings_changed.emit(&"volume_sfx", 0.5)
	EventBus.settings_changed.emit(&"volume_music", 0.4)
	EventBus.settings_changed.emit(&"volume_master", 0.8)
	EventBus.pause_toggled.emit(true)
	EventBus.pause_toggled.emit(false)
	EventBus.player_caught.emit()
	await get_tree().create_timer(0.3).timeout
	print("  volumes bus : Master %.1f dB, SFX %.1f dB, Music %.1f dB" % [
		AudioManager.bus_volume_db(&"Master"), AudioManager.bus_volume_db(&"SFX"),
		AudioManager.bus_volume_db(&"Music")])

	print("=== TEST AUDIO — musiques et couches ===")
	AudioManager.play_music(&"music_ending_closed", 0.2)
	await get_tree().create_timer(0.3).timeout
	AudioManager.play_music(&"music_ending_ashes", 0.2)
	await get_tree().create_timer(0.3).timeout
	AudioManager.stop_music(0.2)
	AudioManager.set_layer(&"house_base", 0.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	EventBus.ending_reached.emit(&"closed")
	await get_tree().create_timer(0.3).timeout

	print("=== TEST AUDIO — ids inconnus (dégradation) ===")
	AudioManager.play_sfx(&"ce_son_n_existe_pas")
	AudioManager.play_ui(&"ce_son_n_existe_pas")
	AudioManager.set_layer(&"cette_couche_n_existe_pas", 1.0)
	AudioManager.play_music(&"cette_musique_n_existe_pas")
	print("=== TEST AUDIO — nettoyage avant fermeture ===")
	AudioManager.stop_music(0.05)
	for layer_id in LAYER_IDS:
		AudioManager.set_layer(layer_id, 0.0, 0.05)
	# Il faut quelques frames pour que l'AudioServer libère les playbacks :
	# sinon Godot signalera « resources still in use at exit ».
	await get_tree().create_timer(0.6).timeout
	print("=== TEST AUDIO — terminé ===")
