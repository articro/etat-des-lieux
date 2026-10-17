## HouseDirector — « la maison se souvient ». Propriétaire : Systèmes.
## STUB M0 : signatures fixées (docs/ARCHITECTURE.md §5), moteur de règles à faire (tâche S-3).
extends Node

const ATTENTION_MAX := 100.0

var _rules: Array[HouseRule] = []
var _presence_state: StringName = &"dormant"


func register_rule(rule: HouseRule) -> void:
	if rule == null:
		return
	_rules.append(rule)


func request_event(event_id: StringName) -> void:
	EventBus.house_event_triggered.emit(event_id)


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
## À IMPLÉMENTER (S-3). Doit retourner false et push_error sur syntaxe invalide, jamais crasher.
func evaluate_condition(expression: String) -> bool:
	if expression.strip_edges().is_empty():
		return true
	push_warning("HouseDirector.evaluate_condition : non implémenté (S-3). Expression : %s" % expression)
	return false


func to_save_dict() -> Dictionary:
	return {"presence": String(_presence_state)}


func from_save_dict(d: Dictionary) -> void:
	_presence_state = StringName(d.get("presence", "dormant"))
