## interactor.gd — interaction V1 (G-2) et interactions longues (G-9).
##
## Raycast 2,5 m depuis la caméra, touche E. Résolution de la cible, par ordre :
##   1. méthode `get_interact_id()` (+ `get_interact_kind()`, `get_interact_duration()`)
##   2. metadata `interact_id` (+ `interact_kind`, `interact_duration`)
##   3. metadata `document_id`  -> kind "read"
##   4. groupe "items" + `data: ItemData` -> kind "pickup"
## Émet EventBus.player_interacted(target_id, kind). Pour une lecture, appelle
## aussi DocumentLibrary.mark_read(id) (les documents sont gérés par Systèmes).
## Interaction longue : metadata `interact_duration` > 0 => maintenir E pendant
## la durée, annulée au relâchement ou au changement de cible.
class_name Interactor
extends RayCast3D

const RANGE: float = 2.5
const INTERACT_ACTION: StringName = &"interact"
const LIGHT_NAME: String = "HUD/LongAction"

var _target: Node = null
var _target_id: StringName = &""
var _kind: StringName = &"use"
var _duration: float = 0.0
var _held_time: float = 0.0
var _holding: bool = false
var _progress_bar: ProgressBar = null
var _player: PlayerController = null
# Dernière cible diffusée sur EventBus.interact_target_changed.
var _emitted_id: StringName = &""
var _emitted_kind: StringName = &""
var _emitted_once: bool = false


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -RANGE)
	collide_with_areas = true
	collide_with_bodies = true
	_player = _find_player()
	if _player != null:
		_progress_bar = _player.get_node_or_null(LIGHT_NAME) as ProgressBar
	EventBus.pause_toggled.connect(_on_pause_toggled)


func _find_player() -> PlayerController:
	var node: Node = self
	while node != null:
		if node is PlayerController:
			return node as PlayerController
		node = node.get_parent()
	return null


func _physics_process(_delta: float) -> void:
	var collider: Object = get_collider()
	var node: Node = collider as Node
	if node != null and not is_instance_valid(node):
		node = null
	_set_target(node)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed(INTERACT_ACTION) and _target != null and _duration <= 0.0:
		interact()


func _process(delta: float) -> void:
	if _duration <= 0.0 or _target == null:
		if _holding:
			_cancel_hold()
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if _holding:
			_cancel_hold()
		return
	if Input.is_action_pressed(INTERACT_ACTION):
		_holding = true
		advance_hold(delta)
	elif _holding:
		_cancel_hold()


## Interaction immédiate (E sur une cible courte). Publique pour les tests.
func interact() -> void:
	if _target == null or _target_id == &"" or _duration > 0.0:
		return
	_emit_interaction(_target_id, _kind)


## Avance la jauge d'une interaction longue. Publique pour les tests.
func advance_hold(delta: float) -> void:
	if _target == null or _duration <= 0.0:
		return
	_held_time += delta
	_update_bar(clampf(_held_time / _duration, 0.0, 1.0))
	if _held_time >= _duration:
		var completed_id := _target_id
		var completed_kind := _kind
		_cancel_hold()
		_emit_interaction(completed_id, completed_kind)


## Force la cible (tests uniquement). `node` peut être le collider ou un enfant.
func force_target(node: Node) -> void:
	_set_target(node)


func current_target_id() -> StringName:
	return _target_id


func current_kind() -> StringName:
	return _kind


func current_duration() -> float:
	return _duration


## Cible actuellement diffusée sur interact_target_changed (tests, debug).
func emitted_target_id() -> StringName:
	return _emitted_id


# --- Résolution de la cible ---------------------------------------------------

## Décrit une cible d'interaction ; dictionnaire vide si aucune cible.
## Une instance libérée (objet déplacé, scène changée) est traitée comme vide.
static func describe(node: Node) -> Dictionary:
	var current: Node = node
	while current != null:
		if not is_instance_valid(current):
			break
		var found := _describe_one(current)
		if not found.is_empty():
			return found
		current = current.get_parent()
	return {}


static func _describe_one(node: Node) -> Dictionary:
	if node.has_method(&"get_interact_id"):
		return _make(node, node.call(&"get_interact_id"), &"use")
	if node.has_meta(&"interact_id"):
		return _make(node, node.get_meta(&"interact_id"), &"use")
	if node.has_meta(&"document_id"):
		return _make(node, node.get_meta(&"document_id"), &"read")
	if node.is_in_group(&"items"):
		var data := node.get(&"data") as ItemData
		if data != null:
			return _make(node, data.id, &"pickup")
	return {}


static func _make(node: Node, raw_id: Variant, default_kind: StringName) -> Dictionary:
	var id := StringName(str(raw_id))
	if id == &"":
		return {}
	var kind := default_kind
	var duration := 0.0
	if node.has_meta(&"interact_kind"):
		kind = StringName(str(node.get_meta(&"interact_kind")))
	if node.has_method(&"get_interact_kind"):
		kind = StringName(str(node.call(&"get_interact_kind")))
	if node.has_meta(&"interact_duration"):
		duration = float(node.get_meta(&"interact_duration"))
	if node.has_method(&"get_interact_duration"):
		duration = float(node.call(&"get_interact_duration"))
	return {"node": node, "id": id, "kind": kind, "duration": duration}


# --- Interne ------------------------------------------------------------------

func _set_target(node: Node) -> void:
	if node != null and not is_instance_valid(node):
		node = null
	var described := describe(node)
	var described_node: Node = described.get("node", null) as Node
	var target_alive := _target != null and is_instance_valid(_target)
	# Même cible encore vivante : rien à refaire.
	if described_node != null and target_alive and described_node == _target:
		return
	# Rien à viser, et on ne visait déjà rien : pas de réémission.
	if described_node == null and not target_alive and _target_id == &"":
		return
	# Attention : une référence libérée se compare comme `null` en GDScript, et
	# la passer en argument typé `Node` déclenche une erreur de type. On vérifie
	# donc la validité AVANT l'appel, d'où `target_alive`.
	if target_alive:
		_clear_highlight(_target)
	_cancel_hold()
	_target = described_node
	if described_node == null:
		# Le contrat veut (&"", &"") quand plus rien n'est visé.
		_target_id = &""
		_kind = &""
		_duration = 0.0
	else:
		_target_id = described.get("id", &"") as StringName
		_kind = described.get("kind", &"use") as StringName
		_duration = float(described.get("duration", 0.0))
		if _target.has_method(&"set_highlight"):
			_target.call(&"set_highlight", true)
	_emit_target_changed()


## Diffuse la cible survolée (réticule contextuel, UI). (&"", &"") = rien.
## On ne l'émet que si le couple (id, kind) change réellement.
func _emit_target_changed() -> void:
	if _emitted_once and _emitted_id == _target_id and _emitted_kind == _kind:
		return
	_emitted_once = true
	_emitted_id = _target_id
	_emitted_kind = _kind
	EventBus.interact_target_changed.emit(_target_id, _kind)


func _emit_interaction(id: StringName, kind: StringName) -> void:
	EventBus.player_interacted.emit(id, kind)
	if kind == &"read" and DocumentLibrary.get_document(id) != null:
		DocumentLibrary.mark_read(id)


func _cancel_hold() -> void:
	if not _holding and _held_time <= 0.0:
		return
	_holding = false
	_held_time = 0.0
	_update_bar(0.0)


func _update_bar(ratio: float) -> void:
	if _progress_bar == null:
		return
	_progress_bar.visible = ratio > 0.0
	_progress_bar.value = ratio * 100.0


func _clear_highlight(node: Object) -> void:
	if node != null and is_instance_valid(node) and node.has_method(&"set_highlight"):
		node.call(&"set_highlight", false)


## En pause, le raycast s'arrête mais le liseré resterait allumé derrière le
## menu : on vide la cible (émis comme (&"", &"") pour le réticule).
func _on_pause_toggled(paused: bool) -> void:
	if paused:
		_set_target(null)
