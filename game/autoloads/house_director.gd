## HouseDirector — « la maison se souvient ». Propriétaire : Systèmes.
## Moteur de règles HouseRule (S-3), parser du mini-langage (ARCHITECTURE §6),
## attention (montée flashs/bruits, descente à l'immobilité), révélation des fantômes.
## API publique fixée (ARCHITECTURE §5). Le reste est privé.
extends Node

const RULES_DIR := "res://data/rules/"
const ATTENTION_MAX := 100.0

## Comportement de base de l'attention (hors règles) — calable au playtest.
const FLASH_ATTENTION := 3.0
const NOISE_ATTENTION_SCALE := 6.0
const IDLE_DECAY_DELAY := 20.0       # s d'immobilité avant que la maison « oublie »
const IDLE_DECAY_PER_SECOND := 1.5
const IDLE_POLL_INTERVAL := 0.5      # s entre deux évaluations des règles idle / attention_above

const KNOWN_TRIGGERS: Array[String] = [
	"room_left", "room_entered", "progress", "attention_above",
	"doc_read", "flash_count", "idle", "item_checked", "noise",
]
const KNOWN_ACTIONS: Array[String] = ["move_item", "event", "attention", "presence", "sfx", "subtitle", "reveal"]
## Durée par défaut d'un sous-titre si `subtitle:<clé>` n'en précise pas (S-9).
const SUBTITLE_DEFAULT_DURATION := 3.0

## Séquenceur V1 (PLAN_HALLOWEEN §1) : calme 0-20, inquiétude 20-45, cave 45-60.
const THRESHOLD_ACT2 := 20
const THRESHOLD_ACT3 := 45
const THRESHOLD_ENDING_CLOSED := 60
## Événements de secours du séquenceur : émis seulement si aucune règle ne les a déjà émis
## (les règles V1 r01/r03 portent ces événements — voir data/rules/README.md).
const EVENT_ACT2 := &"act1_drawer_opens"
const EVENT_ACT3_PHONE := &"phone_rings"
const EVENT_ACT3_CELLAR := &"cellar_door_opens"
const ROOM_IDS: Array[StringName] = [
	&"exterior", &"hall", &"kitchen", &"dining", &"living", &"study", &"stairs",
	&"bedroom_m", &"bedroom_child", &"bathroom", &"laundry", &"attic", &"cellar",
]


class _RuleState:
	var fired: bool = false
	var last_fire_ms: int = -1000000000


var _rules: Array[HouseRule] = []
var _rule_states: Dictionary = {}      # HouseRule -> _RuleState
var _presence_state: StringName = &"dormant"
var _emitted_events: Dictionary = {}   # StringName -> true (déjà émis cette partie)
var _moved_items: Dictionary = {}      # StringName -> {to_room, anchor} — état « la maison se souvient »
var _idle_time: float = 0.0
var _idle_poll: float = 0.0
var _ending_reached: bool = false
var _ending_id: StringName = &""

# --- État du parser (non réentrant, usage interne) ---
var _cond_src: String = ""
var _cond_idx: int = 0
var _cond_err: String = ""
var _last_eval_had_error: bool = false
var _invalid_reveal: Dictionary = {}   # StringName -> true (reveal_condition invalide)


func _ready() -> void:
	_load_rules()
	EventBus.player_entered_room.connect(_on_player_entered_room)
	EventBus.player_left_room.connect(_on_player_left_room)
	EventBus.document_read.connect(_on_document_read)
	EventBus.item_checked.connect(_on_item_checked)
	EventBus.inventory_progress.connect(_on_inventory_progress)
	EventBus.flash_fired.connect(_on_flash_fired)
	EventBus.player_noise.connect(_on_player_noise)
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.game_loaded.connect(_on_game_loaded)


func _process(delta: float) -> void:
	_idle_time += delta
	if _idle_time >= IDLE_DECAY_DELAY:
		add_attention(-IDLE_DECAY_PER_SECOND * delta, &"idle")
	_idle_poll += delta
	if _idle_poll >= IDLE_POLL_INTERVAL:
		_idle_poll = 0.0
		_evaluate_trigger_rules("idle", "")
		_evaluate_trigger_rules("attention_above", "")


# --- API publique (ARCHITECTURE §5) ---

func register_rule(rule: HouseRule) -> void:
	if rule == null:
		push_warning("HouseDirector.register_rule : règle nulle ignorée.")
		return
	if rule.id != StringName():
		for existing: HouseRule in _rules:
			if existing.id == rule.id:
				push_warning("HouseDirector : id de règle dupliqué %s, ignorée." % rule.id)
				return
	if not KNOWN_TRIGGERS.has(rule.trigger):
		push_warning("HouseDirector : trigger inconnu '%s' (règle %s)." % [rule.trigger, rule.id])
	if not _trigger_param_is_valid(rule):
		push_warning("HouseDirector : trigger_param invalide '%s' (règle %s)." % [rule.trigger_param, rule.id])
	for action: String in rule.actions:
		if not _action_is_valid(action):
			push_warning("HouseDirector : action invalide '%s' (règle %s)." % [action, rule.id])
	if not rule.condition.strip_edges().is_empty():
		_cond_evaluate(rule.condition, false)
		if _last_eval_had_error:
			push_warning("HouseDirector : condition invalide (règle %s), règle ignorée." % rule.id)
			return
	_rules.append(rule)
	_state_for(rule)


func request_event(event_id: StringName) -> void:
	_emit_event(event_id, false)


func set_presence_state(state: StringName) -> void:
	if state == _presence_state:
		return
	_presence_state = state
	EventBus.presence_state_changed.emit(state)


func add_attention(delta: float, _reason: StringName) -> void:
	var new_value := clampf(GameState.attention + delta, 0.0, ATTENTION_MAX)
	if is_equal_approx(new_value, GameState.attention):
		return
	GameState.attention = new_value
	EventBus.house_attention_changed.emit(new_value)


## Évalue une condition du mini-langage (ARCHITECTURE §6).
## Syntaxe invalide → push_error + false, jamais de crash.
func evaluate_condition(expression: String) -> bool:
	return _cond_evaluate(expression, true)


func to_save_dict() -> Dictionary:
	var fired: Array[String] = []
	for rule: HouseRule in _rules:
		if _state_for(rule).fired and rule.id != StringName():
			fired.append(String(rule.id))
	var events: Array[String] = []
	for id: StringName in _emitted_events.keys():
		events.append(String(id))
	var moves: Array[Dictionary] = []
	for id: StringName in _moved_items.keys():
		var move: Dictionary = _moved_items[id]
		moves.append({
			"item": String(id),
			"to": String(move.get("to_room", &"")),
			"anchor": String(move.get("anchor", &"")),
		})
	return {
		"presence": String(_presence_state),
		"rules_fired": fired,
		"events": events,
		"moves": moves,
		"ending": String(_ending_id),
	}


func from_save_dict(d: Dictionary) -> void:
	_presence_state = StringName(d.get("presence", "dormant"))
	var fired := {}
	for k: String in d.get("rules_fired", []):
		fired[StringName(k)] = true
	for rule: HouseRule in _rules:
		_state_for(rule).fired = fired.has(rule.id)
	_emitted_events.clear()
	for k: String in d.get("events", []):
		_emitted_events[StringName(k)] = true
	_moved_items.clear()
	for m: Dictionary in d.get("moves", []):
		_moved_items[StringName(m.get("item", ""))] = {
			"to_room": StringName(m.get("to", "")),
			"anchor": StringName(m.get("anchor", "")),
		}
	_ending_id = StringName(d.get("ending", ""))
	_ending_reached = _ending_id != StringName()


## Remise à zéro complète pour la scène de test Systèmes (usage interne uniquement).
func _reset_for_tests() -> void:
	_rules.clear()
	_rule_states.clear()
	_emitted_events.clear()
	_moved_items.clear()
	_invalid_reveal.clear()
	_presence_state = &"dormant"
	_idle_time = 0.0
	_ending_reached = false
	_ending_id = &""
	GameState.attention = 0.0


# --- Chargement des règles ---

func _load_rules() -> void:
	var dir := DirAccess.open(RULES_DIR)
	if dir == null:
		push_warning("HouseDirector : dossier %s introuvable (normal en M0)." % RULES_DIR)
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var path := RULES_DIR + file
		if not ResourceLoader.exists(path):
			push_warning("HouseDirector : ressource invalide %s." % path)
			continue
		var res := load(path)
		if res is HouseRule:
			register_rule(res as HouseRule)
		else:
			push_warning("HouseDirector : %s n'est pas une HouseRule." % path)


# --- Moteur de règles ---

func _state_for(rule: HouseRule) -> _RuleState:
	var st := _rule_states.get(rule) as _RuleState
	if st == null:
		st = _RuleState.new()
		_rule_states[rule] = st
	return st


## Un déclencheur « état » est satisfait quand sa valeur courante franchit le seuil.
## Les déclencheurs « événement » comparent `param` au paramètre de la règle.
func _rule_wants(rule: HouseRule, param: String) -> bool:
	match rule.trigger:
		"progress":
			return float(InventoryManager.progress().x) >= rule.trigger_param.to_float()
		"attention_above":
			return GameState.attention > rule.trigger_param.to_float()
		"idle":
			return _idle_time >= rule.trigger_param.to_float()
		"flash_count":
			return float(GameState.get_counter(&"flash_count")) >= rule.trigger_param.to_float()
		"noise":
			return param.to_float() >= rule.trigger_param.to_float()
		"room_left", "room_entered", "doc_read", "item_checked":
			return rule.trigger_param.is_empty() or rule.trigger_param == param
	return false


func _evaluate_trigger_rules(trigger: String, param: String) -> void:
	var now := Time.get_ticks_msec()
	for rule: HouseRule in _rules:
		if rule.trigger != trigger:
			continue
		var st := _state_for(rule)
		if rule.once and st.fired:
			continue
		if now - st.last_fire_ms < int(rule.cooldown * 1000.0):
			continue
		if not _rule_wants(rule, param):
			continue
		if not rule.condition.strip_edges().is_empty() and not evaluate_condition(rule.condition):
			continue
		_fire_rule(rule)


func _fire_rule(rule: HouseRule) -> void:
	var st := _state_for(rule)
	st.fired = true
	st.last_fire_ms = Time.get_ticks_msec()
	for action: String in rule.actions:
		_execute_action(rule, action)


func _execute_action(rule: HouseRule, action: String) -> void:
	var parts := action.split(":")
	if parts.size() < 2:
		push_error("HouseDirector : action invalide '%s' (règle %s)." % [action, rule.id])
		return
	match parts[0]:
		"move_item":
			if parts.size() != 4:
				push_error("HouseDirector : move_item attend 4 parties '%s' (règle %s)." % [action, rule.id])
				return
			var item_id := StringName(parts[1])
			var to_room := StringName(parts[2])
			var anchor := StringName(parts[3])
			var item := InventoryManager.get_item(item_id)
			if item == null:
				push_warning("HouseDirector : move_item, objet inconnu %s (règle %s)." % [item_id, rule.id])
			var from_room: StringName = item.room_id if item != null else &""
			_moved_items[item_id] = {"to_room": to_room, "anchor": anchor}
			EventBus.item_moved.emit(item_id, from_room, to_room, anchor)
		"event":
			if parts.size() != 2:
				push_error("HouseDirector : event attend 2 parties '%s' (règle %s)." % [action, rule.id])
				return
			_emit_event(StringName(parts[1]), false)
		"attention":
			if parts.size() != 2:
				push_error("HouseDirector : attention attend 2 parties '%s' (règle %s)." % [action, rule.id])
				return
			add_attention(_parse_delta(parts[1]), rule.id)
		"presence":
			if parts.size() != 2:
				push_error("HouseDirector : presence attend 2 parties '%s' (règle %s)." % [action, rule.id])
				return
			set_presence_state(StringName(parts[1]))
		"sfx":
			if parts.size() != 2:
				push_error("HouseDirector : sfx attend 2 parties '%s' (règle %s)." % [action, rule.id])
				return
			_play_sfx(StringName(parts[1]))
		"subtitle":
			if parts.size() < 2 or parts.size() > 3 or parts[1].is_empty():
				push_error("HouseDirector : subtitle attend '<clé>[:<durée>]' '%s' (règle %s)." % [action, rule.id])
				return
			var duration := SUBTITLE_DEFAULT_DURATION
			if parts.size() == 3:
				if not parts[2].strip_edges().is_valid_float():
					push_error("HouseDirector : durée de sous-titre invalide '%s' (règle %s)." % [action, rule.id])
					return
				duration = parts[2].to_float()
			EventBus.subtitle_requested.emit(StringName(parts[1]), duration)
		"reveal":
			if parts.size() != 2:
				push_error("HouseDirector : reveal attend 2 parties '%s' (règle %s)." % [action, rule.id])
				return
			InventoryManager.reveal_item(StringName(parts[1]))
		_:
			push_error("HouseDirector : action inconnue '%s' (règle %s)." % [action, rule.id])


func _parse_delta(text: String) -> float:
	var t := text.strip_edges()
	if t.begins_with("+"):
		t = t.substr(1)
	return t.to_float()


func _play_sfx(sfx_id: StringName) -> void:
	if not AudioManager.has_method("play_sfx"):
		push_warning("HouseDirector : AudioManager indisponible pour %s." % sfx_id)
		return
	AudioManager.play_sfx(sfx_id)


func _emit_event(event_id: StringName, only_if_new: bool) -> void:
	if event_id == StringName():
		push_warning("HouseDirector : event_id vide ignoré.")
		return
	if only_if_new and _emitted_events.has(event_id):
		return
	_emitted_events[event_id] = true
	EventBus.house_event_triggered.emit(event_id)


# --- Validation des données (dégradation propre, jamais de crash) ---

func _trigger_param_is_valid(rule: HouseRule) -> bool:
	match rule.trigger:
		"progress", "attention_above", "idle", "flash_count", "noise":
			return rule.trigger_param.strip_edges().is_valid_float()
	return true


func _action_is_valid(action: String) -> bool:
	var parts := action.split(":")
	if parts.size() < 2 or not KNOWN_ACTIONS.has(parts[0]):
		return false
	match parts[0]:
		"move_item":
			return parts.size() == 4
		"subtitle":
			if parts.size() < 2 or parts.size() > 3 or parts[1].is_empty():
				return false
			return parts.size() == 2 or parts[2].strip_edges().is_valid_float()
		_:
			return parts.size() == 2


# --- Révélation des objets fantômes (ARCHITECTURE §6) ---

func _update_phantom_reveals() -> void:
	for room_id: StringName in ROOM_IDS:
		for item: ItemData in InventoryManager.get_items_in_room(room_id):
			if not item.is_phantom or item.reveal_condition.strip_edges().is_empty():
				continue
			if _invalid_reveal.has(item.id):
				continue
			if evaluate_condition(item.reveal_condition):
				InventoryManager.reveal_item(item.id)
			elif _last_eval_had_error:
				_invalid_reveal[item.id] = true
				push_warning("HouseDirector : reveal_condition invalide pour %s, ignorée." % item.id)


# --- Triggers EventBus ---

func _on_player_entered_room(room_id: StringName) -> void:
	_idle_time = 0.0
	_update_phantom_reveals()
	_evaluate_trigger_rules("room_entered", String(room_id))


func _on_player_left_room(room_id: StringName) -> void:
	_idle_time = 0.0
	_evaluate_trigger_rules("room_left", String(room_id))


func _on_document_read(doc_id: StringName) -> void:
	_idle_time = 0.0
	_update_phantom_reveals()
	_evaluate_trigger_rules("doc_read", String(doc_id))


func _on_item_checked(item_id: StringName, _photo: PhotoData) -> void:
	_idle_time = 0.0
	_update_phantom_reveals()
	_evaluate_trigger_rules("item_checked", String(item_id))


func _on_inventory_progress(checked: int, _total: int) -> void:
	_update_phantom_reveals()
	_evaluate_trigger_rules("progress", str(checked))
	_update_progression(checked)


# --- Séquenceur de progression V1 (S-7) et fins (S-8) ---

func _update_progression(checked: int) -> void:
	var target := 1
	if checked >= THRESHOLD_ACT3:
		target = 3
	elif checked >= THRESHOLD_ACT2:
		target = 2
	if target > GameState.current_act:
		if target >= 2:
			_emit_event(EVENT_ACT2, true)
		if target >= 3:
			_emit_event(EVENT_ACT3_PHONE, true)
			_emit_event(EVENT_ACT3_CELLAR, true)
		GameState.current_act = target
		EventBus.act_changed.emit(target)
	if checked >= THRESHOLD_ENDING_CLOSED:
		_trigger_ending(&"closed")


## Première fin atteinte gagne : `closed` au 60e objet coché, `ashes` sur le poêle.
func _trigger_ending(ending_id: StringName) -> void:
	if _ending_reached:
		return
	_ending_reached = true
	_ending_id = ending_id
	EventBus.ending_reached.emit(ending_id)


func _on_game_loaded() -> void:
	_idle_time = 0.0
	_invalid_reveal.clear()
	# 1) Rejouer les déplacements déjà consommés par la maison (elle se souvient).
	_replay_item_moves()
	# 2) Rattrapage des seuils de progression manqués depuis la sauvegarde.
	var checked := InventoryManager.progress().x
	_update_progression(checked)
	_update_phantom_reveals()
	_evaluate_trigger_rules("progress", str(checked))


## Réémet `item_moved` pour chaque objet déjà déplacé (l'état maison n'est pas sauvegardé
## par Niveau : c'est HouseDirector qui porte la mémoire des déplacements).
func _replay_item_moves() -> void:
	for id: StringName in _moved_items.keys():
		var move: Dictionary = _moved_items[id]
		var item := InventoryManager.get_item(id)
		var from_room: StringName = item.room_id if item != null else &""
		EventBus.item_moved.emit(
			id,
			from_room,
			StringName(move.get("to_room", &"")),
			StringName(move.get("anchor", &"")),
		)


func _on_flash_fired(_world_position: Vector3, _room_id: StringName) -> void:
	_idle_time = 0.0
	GameState.add_counter(&"flash_count")
	add_attention(FLASH_ATTENTION, &"flash")
	_evaluate_trigger_rules("flash_count", str(GameState.get_counter(&"flash_count")))


func _on_player_noise(level: float, _world_position: Vector3) -> void:
	_idle_time = 0.0
	add_attention(clampf(level, 0.0, 1.0) * NOISE_ATTENTION_SCALE, &"noise")
	_evaluate_trigger_rules("noise", str(clampf(level, 0.0, 1.0)))


func _on_player_interacted(target_id: StringName, kind: StringName) -> void:
	_idle_time = 0.0
	# Fin « Cendres » : brûler le carnet dans le poêle de la cave (S-8).
	if target_id == &"cellar_stove" and kind == &"burn":
		_trigger_ending(&"ashes")


# --- Parser du mini-langage (ARCHITECTURE §6) ---
# Prédicats : checked/act/attention (comparaison), flag:, doc_read:, item_checked:,
# item_present:, room:, presence:. Négation `!` devant tout prédicat. `&&`, `||`, parenthèses.

func _cond_evaluate(expression: String, report: bool) -> bool:
	_last_eval_had_error = false
	var expr := expression.strip_edges()
	if expr.is_empty():
		return true
	_cond_src = expr
	_cond_idx = 0
	_cond_err = ""
	var value := _cond_or()
	_cond_skip_ws()
	if _cond_err.is_empty() and _cond_idx < _cond_src.length():
		_cond_err = "texte inattendu à la position %d" % _cond_idx
	if not _cond_err.is_empty():
		_last_eval_had_error = true
		if report:
			push_error("HouseDirector : condition invalide '%s' : %s" % [expr, _cond_err])
		return false
	return value


func _cond_or() -> bool:
	var value := _cond_and()
	while _cond_err.is_empty() and _cond_match("||"):
		var right := _cond_and()
		value = value or right
	return value


func _cond_and() -> bool:
	var value := _cond_unary()
	while _cond_err.is_empty() and _cond_match("&&"):
		var right := _cond_unary()
		value = value and right
	return value


func _cond_unary() -> bool:
	if _cond_match("!"):
		return not _cond_unary()
	return _cond_primary()


func _cond_primary() -> bool:
	if _cond_match("("):
		var value := _cond_or()
		if not _cond_match(")"):
			_cond_err = "parenthèse fermante manquante"
		return value
	return _cond_predicate()


func _cond_predicate() -> bool:
	var start := _cond_idx
	var name := _cond_read_ident()
	if name.is_empty():
		_cond_err = "prédicat attendu à la position %d" % start
		return false
	if _cond_peek_char() == ":":
		_cond_idx += 1
		var arg := _cond_read_ident()
		if arg.is_empty():
			_cond_err = "identifiant attendu après '%s:'" % name
			return false
		return _cond_eval_named(name, arg)
	var op := _cond_read_cmp()
	if op.is_empty():
		_cond_err = "opérateur de comparaison attendu après '%s'" % name
		return false
	var num := _cond_read_number()
	if not _cond_err.is_empty():
		return false
	match name:
		"checked":
			return _cond_compare(float(InventoryManager.progress().x), op, num)
		"act":
			return _cond_compare(float(GameState.current_act), op, num)
		"attention":
			return _cond_compare(GameState.attention, op, num)
		_:
			_cond_err = "prédicat inconnu '%s'" % name
			return false


func _cond_eval_named(name: String, arg: String) -> bool:
	match name:
		"flag":
			return GameState.get_flag(StringName(arg))
		"doc_read":
			return DocumentLibrary.is_read(StringName(arg))
		"item_checked":
			return InventoryManager.is_checked(StringName(arg))
		"item_present":
			return InventoryManager.is_present(StringName(arg))
		"room":
			return GameState.current_room() == StringName(arg)
		"presence":
			return _presence_state == StringName(arg)
		_:
			_cond_err = "prédicat inconnu '%s:'" % name
			return false


func _cond_compare(left: float, op: String, right: float) -> bool:
	match op:
		">=":
			return left >= right
		">":
			return left > right
		"<=":
			return left <= right
		"<":
			return left < right
		"==":
			return is_equal_approx(left, right)
		"!=":
			return not is_equal_approx(left, right)
		_:
			_cond_err = "opérateur inconnu '%s'" % op
			return false


func _cond_skip_ws() -> void:
	while _cond_idx < _cond_src.length():
		var c := _cond_src[_cond_idx]
		if c == " " or c == "\t" or c == "\n" or c == "\r":
			_cond_idx += 1
		else:
			return


func _cond_match(op: String) -> bool:
	_cond_skip_ws()
	if _cond_src.substr(_cond_idx, op.length()) != op:
		return false
	# Ne pas confondre la négation `!` avec l'opérateur `!=`.
	if op == "!" and _cond_src.substr(_cond_idx, 2) == "!=":
		return false
	_cond_idx += op.length()
	return true


func _cond_peek_char() -> String:
	_cond_skip_ws()
	if _cond_idx >= _cond_src.length():
		return ""
	return _cond_src[_cond_idx]


func _cond_read_ident() -> String:
	_cond_skip_ws()
	var start := _cond_idx
	while _cond_idx < _cond_src.length():
		var c := _cond_src[_cond_idx]
		var is_ident := (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
			or (c >= "0" and c <= "9") or c == "_"
		if not is_ident:
			break
		_cond_idx += 1
	var text := _cond_src.substr(start, _cond_idx - start)
	# Un identifiant ne commence pas par un chiffre.
	if not text.is_empty() and text[0] >= "0" and text[0] <= "9":
		_cond_idx = start
		return ""
	return text


func _cond_read_cmp() -> String:
	_cond_skip_ws()
	for op: String in [">=", "<=", "==", "!=", ">", "<"]:
		if _cond_src.substr(_cond_idx, op.length()) == op:
			_cond_idx += op.length()
			return op
	return ""


func _cond_read_number() -> float:
	_cond_skip_ws()
	var start := _cond_idx
	if _cond_idx < _cond_src.length() and _cond_src[_cond_idx] == "-":
		_cond_idx += 1
	var digits := 0
	while _cond_idx < _cond_src.length() and _cond_src[_cond_idx] >= "0" and _cond_src[_cond_idx] <= "9":
		_cond_idx += 1
		digits += 1
	if _cond_idx < _cond_src.length() and _cond_src[_cond_idx] == ".":
		_cond_idx += 1
		while _cond_idx < _cond_src.length() and _cond_src[_cond_idx] >= "0" and _cond_src[_cond_idx] <= "9":
			_cond_idx += 1
			digits += 1
	if digits == 0:
		_cond_err = "nombre attendu à la position %d" % start
		return 0.0
	return _cond_src.substr(start, _cond_idx - start).to_float()
