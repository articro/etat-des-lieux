## Scène de test Systèmes (S-3/S-7/S-8) — simule les signaux EventBus.
## Se lance seule (F6) sans Niveau/Gameplay/UI : les dépendances manquantes sont dégradées.
## Usage : godot --headless --path game res://scenes/main/test_systems.tscn
extends Node

var _failures: int = 0
var _checks: int = 0
var _events: Array[StringName] = []
var _moves: Array[Dictionary] = []
var _acts: Array[int] = []
var _endings: Array[StringName] = []
var _lines: Array[Array] = []
var _revealed: Array[StringName] = []
var _attention_log: Array[float] = []
var _presence_log: Array[StringName] = []
var _subtitles: Array[Array] = []

@onready var _label: Label = $Label


func _ready() -> void:
	EventBus.house_event_triggered.connect(func(id: StringName) -> void: _events.append(id))
	EventBus.item_moved.connect(func(id: StringName, from_room: StringName, to_room: StringName, anchor: StringName) -> void:
		_moves.append({"id": id, "from": from_room, "to": to_room, "anchor": anchor}))
	EventBus.act_changed.connect(func(act: int) -> void: _acts.append(act))
	EventBus.ending_reached.connect(func(id: StringName) -> void: _endings.append(id))
	EventBus.inventory_line_added.connect(func(index: int, key: StringName) -> void: _lines.append([index, key]))
	EventBus.item_revealed.connect(func(id: StringName) -> void: _revealed.append(id))
	EventBus.house_attention_changed.connect(func(value: float) -> void: _attention_log.append(value))
	EventBus.presence_state_changed.connect(func(state: StringName) -> void: _presence_log.append(state))
	EventBus.subtitle_requested.connect(func(key: StringName, duration: float) -> void: _subtitles.append([key, duration]))

	_test_parser()
	_test_rules_and_reveals()
	_test_sequencer_closed()
	await _test_sequencer_ashes()
	_test_move_and_ending_triggers()
	await _test_burning_delay()
	_test_save_roundtrip()
	_test_move_replay()
	_test_subtitle_and_reveal()
	_test_player_caught()
	_report()


# --- Mini-langage (ARCHITECTURE §6) ---

func _test_parser() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_register_items(60)

	# Conditions valides.
	_expect(HouseDirector.evaluate_condition(""), "condition vide = true")
	_expect(HouseDirector.evaluate_condition("   "), "condition espaces = true")
	_expect(HouseDirector.evaluate_condition("checked>=0"), "checked>=0")
	_expect(not HouseDirector.evaluate_condition("checked>=999"), "checked>=999 = false")
	_expect(HouseDirector.evaluate_condition("checked<=60"), "checked<=60")
	_expect(HouseDirector.evaluate_condition("act==1"), "act==1")
	_expect(HouseDirector.evaluate_condition("act!=3"), "act!=3")
	_expect(HouseDirector.evaluate_condition("attention>=0"), "attention>=0")
	_expect(not HouseDirector.evaluate_condition("attention>100"), "attention>100 = false")
	_expect(not HouseDirector.evaluate_condition("flag:test_flag"), "flag:test_flag = false")
	_expect(HouseDirector.evaluate_condition("!flag:test_flag"), "!flag:test_flag")
	_expect(not HouseDirector.evaluate_condition("doc_read:nope"), "doc_read:nope = false")
	_expect(HouseDirector.evaluate_condition("!doc_read:nope"), "!doc_read:nope")
	_expect(not HouseDirector.evaluate_condition("item_checked:t01"), "item_checked:t01 avant coche")
	_expect(HouseDirector.evaluate_condition("item_present:t01"), "item_present:t01")
	_expect(not HouseDirector.evaluate_condition("item_present:t_phantom"), "item_present fantôme non révélé = false")
	_expect(not HouseDirector.evaluate_condition("room:hall"), "room:hall avant entrée")
	_expect(not HouseDirector.evaluate_condition("presence:offscreen"), "presence:offscreen = false")

	GameState.set_flag(&"test_flag")
	InventoryManager.check_item(&"t01", PhotoData.new())
	EventBus.player_entered_room.emit(&"hall")
	HouseDirector.set_presence_state(&"offscreen")

	_expect(HouseDirector.evaluate_condition("flag:test_flag"), "flag:test_flag après set")
	_expect(HouseDirector.evaluate_condition("item_checked:t01"), "item_checked:t01 après coche")
	_expect(HouseDirector.evaluate_condition("room:hall"), "room:hall après entrée")
	_expect(HouseDirector.evaluate_condition("presence:offscreen"), "presence:offscreen après set")

	# Combinaisons.
	_expect(HouseDirector.evaluate_condition("checked>=1 && act==1"), "et")
	_expect(HouseDirector.evaluate_condition("checked>=999 || act==1"), "ou")
	_expect(not HouseDirector.evaluate_condition("checked>=999 && act==1"), "et faux")
	_expect(HouseDirector.evaluate_condition("(checked>=999 || act==1) && !flag:nope"), "parenthèses")
	_expect(HouseDirector.evaluate_condition("!item_checked:t99 && checked>=0"), "négation prédicat composé")
	_expect(HouseDirector.evaluate_condition("!!item_checked:t01"), "double négation")
	_expect(HouseDirector.evaluate_condition("!(checked>=999)"), "négation parenthèse")
	_expect(HouseDirector.evaluate_condition("checked!=0"), "checked!=0")
	_expect(HouseDirector.evaluate_condition("  checked  >=  1  &&  act  ==  1  "), "espaces libres")

	# Syntaxe invalide = false (push_error attendu dans la console).
	_expect(not HouseDirector.evaluate_condition("checked"), "sans opérateur = false")
	_expect(not HouseDirector.evaluate_condition("checked="), "'=' seul = false")
	_expect(not HouseDirector.evaluate_condition("checked>=abc"), "nombre invalide = false")
	_expect(not HouseDirector.evaluate_condition("foo:bar"), "prédicat inconnu = false")
	_expect(not HouseDirector.evaluate_condition("checkedx>=1"), "nom inconnu = false")
	_expect(not HouseDirector.evaluate_condition("flag:"), "argument vide = false")
	_expect(not HouseDirector.evaluate_condition("(checked>=1"), "parenthèse ouverte = false")
	_expect(not HouseDirector.evaluate_condition("checked>=1)"), "parenthèse en trop = false")
	_expect(not HouseDirector.evaluate_condition("checked>=1 &&& act==1"), "opérateur tronqué = false")
	_expect(not HouseDirector.evaluate_condition("checked>=1 2"), "texte en trop = false")
	_expect(not HouseDirector.evaluate_condition("&& act==1"), "début invalide = false")
	_expect(not HouseDirector.evaluate_condition("checked>>1"), "double comparateur = false")


# --- Moteur de règles, actions, révélation des fantômes ---

func _test_rules_and_reveals() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_events.clear()
	_moves.clear()
	_acts.clear()
	_endings.clear()
	_lines.clear()
	_revealed.clear()
	_attention_log.clear()
	_presence_log.clear()
	_register_items(60)

	# Règle A : progress 3 + condition → event + attention.
	var rule_a := HouseRule.new()
	rule_a.id = &"test_rule_a"
	rule_a.trigger = "progress"
	rule_a.trigger_param = "3"
	rule_a.condition = "checked>=3 && !item_checked:t99"
	rule_a.actions = ["event:test_progress", "attention:+5"]
	rule_a.once = true
	HouseDirector.register_rule(rule_a)

	# Règle B : room_left hall → move_item.
	var rule_b := HouseRule.new()
	rule_b.id = &"test_rule_b"
	rule_b.trigger = "room_left"
	rule_b.trigger_param = "hall"
	rule_b.actions = ["move_item:t01:kitchen:test_anchor"]
	rule_b.once = true
	HouseDirector.register_rule(rule_b)

	# Règle B2 : condition impossible → ne doit jamais partir.
	var rule_b2 := HouseRule.new()
	rule_b2.id = &"test_rule_b2"
	rule_b2.trigger = "room_left"
	rule_b2.trigger_param = "hall"
	rule_b2.condition = "checked>=999"
	rule_b2.actions = ["event:should_not_fire"]
	rule_b2.once = true
	HouseDirector.register_rule(rule_b2)

	# Règle C : room_entered kitchen → presence.
	var rule_c := HouseRule.new()
	rule_c.id = &"test_rule_c"
	rule_c.trigger = "room_entered"
	rule_c.trigger_param = "kitchen"
	rule_c.actions = ["presence:offscreen"]
	rule_c.once = true
	HouseDirector.register_rule(rule_c)

	# Règle D : doc_read → event.
	var rule_d := HouseRule.new()
	rule_d.id = &"test_rule_d"
	rule_d.trigger = "doc_read"
	rule_d.trigger_param = "test_doc"
	rule_d.actions = ["event:test_doc_event"]
	rule_d.once = true
	HouseDirector.register_rule(rule_d)

	# Fantômes pilotés par reveal_condition.
	var phantom := ItemData.new()
	phantom.id = &"t_phantom"
	phantom.list_index = 61
	phantom.room_id = &"hall"
	phantom.is_phantom = true
	phantom.reveal_condition = "checked>=4"
	InventoryManager._register_item(phantom)
	var phantom2 := ItemData.new()
	phantom2.id = &"t_phantom2"
	phantom2.list_index = 62
	phantom2.room_id = &"hall"
	phantom2.is_phantom = true
	phantom2.reveal_condition = "doc_read:test_doc"
	InventoryManager._register_item(phantom2)

	# all_items() : contrat §5, trié par list_index.
	var all := InventoryManager.all_items()
	_expect(all.size() == 62, "all_items : tous les objets")
	if all.size() == 62:
		_expect(all[0].list_index == 1 and all[61].list_index == 62, "all_items : trié par list_index")

	# Déclenchement progressif.
	InventoryManager.check_item(&"t01", PhotoData.new())
	InventoryManager.check_item(&"t02", PhotoData.new())
	_expect(not (&"test_progress" in _events), "règle A pas encore déclenchée à 2")
	InventoryManager.check_item(&"t03", PhotoData.new())
	_expect(&"test_progress" in _events, "règle A déclenchée à 3")
	_expect(_events.count(&"test_progress") == 1, "règle A once = une seule fois")
	_expect(_attention_log.back() == 5.0, "action attention:+5")

	InventoryManager.check_item(&"t04", PhotoData.new())
	_expect(&"t_phantom" in _revealed, "fantôme révélé à checked>=4")
	_expect(InventoryManager.is_present(&"t_phantom"), "fantôme présent après révélation")
	_expect(not InventoryManager.is_checked(&"t_phantom"), "fantôme pas encore coché")
	_expect(InventoryManager.check_item(&"t_phantom", PhotoData.new()), "coche du fantôme possible après révélation")

	# room_left hall → move_item (règle B) ; règle B2 ne part pas.
	EventBus.player_left_room.emit(&"hall")
	_expect(_moves.size() == 1, "move_item émis une fois")
	if _moves.size() == 1:
		_expect(_moves[0]["id"] == &"t01", "move_item: bon objet")
		_expect(_moves[0]["from"] == &"hall", "move_item: from_room")
		_expect(_moves[0]["to"] == &"kitchen", "move_item: to_room")
		_expect(_moves[0]["anchor"] == &"test_anchor", "move_item: ancre")
	_expect(not (&"should_not_fire" in _events), "condition impossible = règle muette")

	# room_entered kitchen → presence:offscreen.
	EventBus.player_entered_room.emit(&"kitchen")
	_expect(&"offscreen" in _presence_log, "action presence:offscreen")

	# doc_read → event + révélation par doc_read.
	DocumentLibrary.mark_read(&"test_doc")
	_expect(&"test_doc_event" in _events, "règle D déclenchée au doc_read")
	_expect(&"t_phantom2" in _revealed, "fantôme révélé par doc_read")

	# SFX dégradé (AudioManager stub) : ne doit pas crasher.
	var rule_e := HouseRule.new()
	rule_e.id = &"test_rule_e"
	rule_e.trigger = "doc_read"
	rule_e.trigger_param = "test_doc2"
	rule_e.actions = ["sfx:test_sound"]
	rule_e.once = true
	HouseDirector.register_rule(rule_e)
	DocumentLibrary.mark_read(&"test_doc2")
	_expect(true, "action sfx dégradée sans crash")

	# État de présence sauvegardé.
	_expect(HouseDirector.to_save_dict().get("presence", "") == "offscreen", "to_save_dict presence")


# --- Séquenceur V1 (S-7) + fin « Inventaire clos » (S-8) ---

func _test_sequencer_closed() -> void:
	_reset_scenario()
	_register_items(60)

	for i: int in range(1, 60):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	_expect(_acts == [2, 3], "act_changed 2 puis 3 aux seuils 20/45 (avant le 60e)")
	_expect(_endings.is_empty(), "pas de fin avant le 60e objet")
	_expect(&"act1_drawer_opens" in _events, "secours séquenceur : event seuil 20")
	_expect(&"phone_rings" in _events, "secours séquenceur : event seuil 45")
	_expect(&"cellar_door_opens" in _events, "secours séquenceur : trappe seuil 45")

	InventoryManager.check_item(&"t60", PhotoData.new())
	_expect(_endings == [&"closed"], "fin closed au 60e objet coché")
	_expect(_acts == [2, 3], "act_changed sans doublon")
	_expect(_events.count(&"act1_drawer_opens") == 1, "event de seuil émis une seule fois")
	_expect(_lines.size() == 1, "une ligne ajoutée à la fin")
	if _lines.size() == 1:
		_expect(_lines[0][0] == 61, "ligne index 61 (numéro sérialisé)")
		_expect(_lines[0][1] == &"INV_LINE_ADDED_CAMILLE", "ligne clé INV_LINE_ADDED_CAMILLE")


# --- Fin « Cendres » (S-8) + garde première fin + dédoublonnage règle/séquenceur ---

func _test_sequencer_ashes() -> void:
	_reset_scenario()
	_register_items(60)

	# Une règle porte déjà l'événement du seuil 20 : le séquenceur ne doit pas le réémettre.
	var rule := HouseRule.new()
	rule.id = &"test_rule_drawer"
	rule.trigger = "progress"
	rule.trigger_param = "20"
	rule.actions = ["event:act1_drawer_opens"]
	rule.once = true
	HouseDirector.register_rule(rule)

	for i: int in range(1, 46):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	_expect(_acts == [2, 3], "actes 2 et 3 atteints")
	_expect(_events.count(&"act1_drawer_opens") == 1, "event règle/séquenceur dédoublonné")

	# Interactions qui ne déclenchent pas la fin.
	EventBus.player_interacted.emit(&"cellar_stove", &"open")
	EventBus.player_interacted.emit(&"other", &"burn")
	_expect(_endings.is_empty(), "pas de fin sur interaction inattendue")

	# Fin différée (S-10) : le sous-titre part tout de suite, la fin 4 s plus tard.
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	_expect(_subtitles.size() == 1, "SUB_BURNING émis immédiatement")
	if _subtitles.size() == 1:
		_expect(_subtitles[0][0] == &"SUB_BURNING", "sous-titre SUB_BURNING")
		_expect(is_equal_approx(float(_subtitles[0][1]), 4.0), "SUB_BURNING sur 4,0 s")
	_expect(_endings.is_empty(), "fin ashes différée (pas dans la même frame)")
	await _wait_for_endings(1)
	_expect(_endings == [&"ashes"], "fin ashes sur player_interacted(cellar_stove, burn)")

	for i: int in range(46, 61):
		InventoryManager.check_item(StringName("t%02d" % i), PhotoData.new())
	_expect(_endings == [&"ashes"], "closed supprimée après ashes (première fin gagne)")
	_expect(_lines.is_empty(), "ligne « 61. Camille » supprimée après ashes")


func _reset_scenario() -> void:
	InventoryManager._reset_for_tests()
	HouseDirector._reset_for_tests()
	GameState.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_events.clear()
	_moves.clear()
	_acts.clear()
	_endings.clear()
	_lines.clear()
	_revealed.clear()
	_attention_log.clear()
	_presence_log.clear()
	_subtitles.clear()


# --- Sauvegarde / chargement (S-5) ---

func _test_save_roundtrip() -> void:
	_reset_scenario()
	_register_items(60)
	InventoryManager.check_item(&"t01", PhotoData.new())
	InventoryManager.check_item(&"t02", PhotoData.new())
	GameState.set_flag(&"save_flag")
	HouseDirector.set_presence_state(&"photo_only")
	DocumentLibrary.mark_read(&"test_doc")

	var err := SaveManager.save_game(0)
	_expect(err == OK, "save_game retourne OK")

	GameState.from_save_dict({})
	InventoryManager.from_save_dict({})
	HouseDirector.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_expect(InventoryManager.progress().x == 0, "état effacé avant rechargement")

	err = SaveManager.load_game(0)
	_expect(err == OK, "load_game retourne OK")
	_expect(InventoryManager.progress().x == 2, "objets cochés restaurés")
	_expect(InventoryManager.film_count() == InventoryManager.STARTING_FILM, "films restaurés")
	_expect(GameState.get_flag(&"save_flag"), "flag restauré")
	_expect(String(HouseDirector.to_save_dict().get("presence", "")) == "photo_only", "présence restaurée")
	_expect(DocumentLibrary.is_read(&"test_doc"), "document lu restauré")

	# Auto-sauvegarde à l'entrée en pièce.
	InventoryManager.check_item(&"t03", PhotoData.new())
	EventBus.player_entered_room.emit(&"hall")
	InventoryManager.from_save_dict({})
	var err2 := SaveManager.load_game(0)
	_expect(err2 == OK and InventoryManager.progress().x == 3, "auto-sauvegarde à player_entered_room")
	_expect(SaveManager.load_game(9) == ERR_FILE_NOT_FOUND, "slot absent = ERR_FILE_NOT_FOUND")


# --- Rejeu des déplacements d'objets au chargement (V1, ex-V2) ---

func _test_move_replay() -> void:
	_reset_scenario()
	_register_items(6)
	var rule := HouseRule.new()
	rule.id = &"test_rule_move"
	rule.trigger = "room_left"
	rule.trigger_param = "hall"
	rule.actions = ["move_item:t02:living:anchor_replay"]
	rule.once = true
	HouseDirector.register_rule(rule)

	EventBus.player_left_room.emit(&"hall")
	_expect(_moves.size() == 1, "déplacement initial émis")
	_expect(HouseDirector.to_save_dict().get("moves", []).size() == 1, "déplacement mémorisé dans la sauvegarde")
	_expect(SaveManager.save_game(0) == OK, "sauvegarde avec déplacement")

	_reset_scenario()
	_register_items(6)
	_moves.clear()
	_expect(SaveManager.load_game(0) == OK, "rechargement OK")
	_expect(_moves.size() == 1, "déplacement rejoué au chargement")
	if _moves.size() == 1:
		_expect(_moves[0]["id"] == &"t02", "rejeu : bon objet")
		_expect(_moves[0]["to"] == &"living", "rejeu : bonne pièce")
		_expect(_moves[0]["anchor"] == &"anchor_replay", "rejeu : bonne ancre")


# --- Actions subtitle: / reveal: (S-9, playtest J4) ---

func _test_subtitle_and_reveal() -> void:
	_reset_scenario()
	_register_items(6)
	var phantom := ItemData.new()
	phantom.id = &"t_sub_phantom"
	phantom.list_index = 7
	phantom.room_id = &"hall"
	phantom.is_phantom = true
	InventoryManager._register_item(phantom)

	var rule := HouseRule.new()
	rule.id = &"test_rule_sub"
	rule.trigger = "doc_read"
	rule.trigger_param = "sub_doc"
	rule.actions = ["subtitle:SUB_TEST_A:2.5", "subtitle:SUB_TEST_B", "reveal:t_sub_phantom"]
	rule.once = true
	HouseDirector.register_rule(rule)

	DocumentLibrary.mark_read(&"sub_doc")
	_expect(_subtitles.size() == 2, "actions subtitle émises")
	if _subtitles.size() == 2:
		_expect(_subtitles[0][0] == &"SUB_TEST_A" and is_equal_approx(float(_subtitles[0][1]), 2.5), "subtitle:clé:durée")
		_expect(_subtitles[1][0] == &"SUB_TEST_B" and is_equal_approx(float(_subtitles[1][1]), HouseDirector.SUBTITLE_DEFAULT_DURATION), "subtitle:clé = durée par défaut")
	_expect(&"t_sub_phantom" in _revealed, "action reveal: révèle le fantôme")
	_expect(InventoryManager.is_present(&"t_sub_phantom"), "fantôme présent après reveal:")

	# Actions mal formées : warning à l'enregistrement, aucun crash, rien d'émis.
	_subtitles.clear()
	var bad_rule := HouseRule.new()
	bad_rule.id = &"test_rule_bad_sub"
	bad_rule.trigger = "doc_read"
	bad_rule.trigger_param = "bad_doc"
	bad_rule.actions = ["subtitle:", "subtitle:SUB_C:pas_un_nombre"]
	bad_rule.once = true
	HouseDirector.register_rule(bad_rule)
	DocumentLibrary.mark_read(&"bad_doc")
	_expect(_subtitles.is_empty(), "actions subtitle invalides ignorées sans crash")


# --- Nouveaux déclencheurs item_moved / ending (S-10) ---

func _test_move_and_ending_triggers() -> void:
	_reset_scenario()
	_register_items(6)

	var any_move := HouseRule.new()
	any_move.id = &"test_rule_any_move"
	any_move.trigger = "item_moved"
	any_move.trigger_param = ""
	any_move.actions = ["event:any_item_moved"]
	any_move.once = true
	HouseDirector.register_rule(any_move)

	var knife_move := HouseRule.new()
	knife_move.id = &"test_rule_knife_move"
	knife_move.trigger = "item_moved"
	knife_move.trigger_param = "t03"
	knife_move.actions = ["event:knife_moved"]
	knife_move.once = true
	HouseDirector.register_rule(knife_move)

	EventBus.item_moved.emit(&"t02", &"hall", &"kitchen", &"anchor_a")
	_expect(&"any_item_moved" in _events, "trigger item_moved sans paramètre : n'importe quel objet")
	_expect(not (&"knife_moved" in _events), "trigger item_moved paramétré : autre objet ignoré")
	EventBus.item_moved.emit(&"t03", &"hall", &"living", &"anchor_b")
	_expect(&"knife_moved" in _events, "trigger item_moved paramétré : bon objet")

	# Une action move_item de règle émet item_moved → déclenche les règles item_moved.
	_events.clear()
	_moves.clear()
	var mover := HouseRule.new()
	mover.id = &"test_rule_move_t04"
	mover.trigger = "room_left"
	mover.trigger_param = "study"
	mover.actions = ["move_item:t04:dining:anchor_c"]
	mover.once = true
	HouseDirector.register_rule(mover)
	EventBus.player_left_room.emit(&"study")
	_expect(_moves.size() == 1 and _moves[0]["id"] == &"t04", "action move_item émet item_moved")
	_expect(_events.is_empty(), "règles item_moved once déjà parties : pas de réémission")

	# Trigger `ending` : param = ending_id, vide = n'importe quelle fin.
	_events.clear()
	var ashes_rule := HouseRule.new()
	ashes_rule.id = &"test_rule_ending_ashes"
	ashes_rule.trigger = "ending"
	ashes_rule.trigger_param = "ashes"
	ashes_rule.actions = ["event:ashes_epilogue"]
	ashes_rule.once = true
	HouseDirector.register_rule(ashes_rule)

	var closed_rule := HouseRule.new()
	closed_rule.id = &"test_rule_ending_closed"
	closed_rule.trigger = "ending"
	closed_rule.trigger_param = "closed"
	closed_rule.actions = ["event:closed_epilogue"]
	closed_rule.once = true
	HouseDirector.register_rule(closed_rule)

	var any_ending := HouseRule.new()
	any_ending.id = &"test_rule_ending_any"
	any_ending.trigger = "ending"
	any_ending.trigger_param = ""
	any_ending.actions = ["event:any_epilogue"]
	any_ending.once = true
	HouseDirector.register_rule(any_ending)

	HouseDirector._trigger_ending(&"ashes")   # appel interne : pas d'attente de 4 s ici
	_expect(&"ashes_epilogue" in _events, "trigger ending:ashes déclenche sa règle")
	_expect(&"any_epilogue" in _events, "trigger ending sans paramètre : n'importe quelle fin")
	_expect(not (&"closed_epilogue" in _events), "trigger ending paramétré : autre fin ignorée")
	_expect(String(HouseDirector.to_save_dict().get("ending", "")) == "ashes", "fin ashes enregistrée en sauvegarde")


# --- Fin « Cendres » différée de 4 s (S-10) ---

func _test_burning_delay() -> void:
	_reset_scenario()
	_register_items(60)

	var started := Time.get_ticks_msec()
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	_expect(_subtitles.size() == 1, "brûlage : un sous-titre immédiat")
	_expect(_endings.is_empty(), "brûlage : pas de fin immédiate")
	# Un second brûlage pendant l'attente ne programme rien de plus.
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	_expect(_subtitles.size() == 1, "brûlage double : un seul sous-titre")

	await _wait_for_endings(1)
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	_expect(_endings == [&"ashes"], "fin ashes reçue")
	_expect(elapsed >= HouseDirector.BURN_ENDING_DELAY - 0.2, "fin ashes après ~4 s (%.2f s mesurées)" % elapsed)

	# Après la fin, un brûlage ne redéclenche rien.
	var subs_before := _subtitles.size()
	EventBus.player_interacted.emit(&"cellar_stove", &"burn")
	_expect(_subtitles.size() == subs_before, "brûlage après la fin : ignoré")
	_expect(_endings == [&"ashes"], "une seule fin ashes")


# --- Player caught (GDD §4.4) : téléportation à l'entrée + une coche au hasard ---

func _test_player_caught() -> void:
	_reset_scenario()
	_register_items(60)
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(main_scene != null, "main.tscn chargeable")
	if main_scene == null:
		return
	var main_node := main_scene.instantiate()
	add_child(main_node)
	main_node._on_new_game()
	_expect(InventoryManager.progress().x == 0, "nouvelle partie : liste vierge")

	var player: Node3D = main_node._player
	_expect(player != null, "joueur instancié par main")
	if player != null:
		var start: Transform3D = main_node._player_start
		player.global_position = Vector3(7.0, 0.0, 7.0)
		EventBus.player_caught.emit()
		_expect(player.global_position.distance_to(start.origin) < 0.01, "player_caught : téléportation à l'entrée")
		_expect(InventoryManager.progress().x == 1, "player_caught : une coche aléatoire")
		EventBus.player_caught.emit()
		_expect(InventoryManager.progress().x == 2, "player_caught : une coche par capture")
	main_node.queue_free()


# --- Divers ---

## Attend l'arrivée de `count` fins (les fins différées dépendent du temps réel), au plus 8 s.
func _wait_for_endings(count: int) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while _endings.size() < count and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.05).timeout


func _register_items(count: int) -> void:
	for i: int in range(1, count + 1):
		var item := ItemData.new()
		item.id = StringName("t%02d" % i)
		item.list_index = i
		item.room_id = &"hall" if i % 2 == 1 else &"kitchen"
		InventoryManager._register_item(item)


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("  OK  %s" % what)
	else:
		_failures += 1
		print("FAIL  %s" % what)


func _report() -> void:
	var summary := "TESTS SYSTÈMES — %d vérifications, %d échecs" % [_checks, _failures]
	if _failures == 0:
		summary += "\n✅ TOUS LES TESTS PASSENT"
		print("✅ %s" % summary)
	else:
		summary += "\n❌ ÉCHECS CI-DESSUS"
		print("❌ %s" % summary)
	_label.text = summary
	# Sortie avec code d'échec pour les scripts CI.
	get_tree().quit(1 if _failures > 0 else 0)
