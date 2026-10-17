## reticle.gd — réticule contextuel discret (U-4).
##
## Un point unique, très discret, qui pulse à chaque interaction. Il est prévu pour
## devenir « contextuel » (forme selon l'action : ouvrir / prendre / lire / brûler)
## dès qu'un signal de cible survolée existera — demande déposée dans TASKS.md :
## en attendant, `set_context()` est appelée par le HUD avec ce qu'EventBus fournit.
class_name Reticle
extends Control

const DOT_RADIUS := 1.7
const RING_RADIUS := 9.0
const TICK := 4.0
const COLOR_IDLE := Color(0.88, 0.86, 0.80, 0.34)
const COLOR_ACTIVE := Color(0.92, 0.88, 0.78, 0.72)
const PULSE_TIME := 0.26

var _kind: StringName = &""
var _pulse: float = 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Forme du réticule selon l'action disponible ("" = rien de ciblé).
func set_context(kind: StringName) -> void:
	if _kind == kind:
		return
	_kind = kind
	queue_redraw()


## Forme courante ("" = aucune cible) — utilisée par les tests.
func context() -> StringName:
	return _kind


## Retour visuel d'une interaction (`EventBus.player_interacted`).
func pulse() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_pulse = 1.0
	queue_redraw()
	_tween = create_tween()
	_tween.tween_method(_set_pulse, 1.0, 0.0, PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_pulse(value: float) -> void:
	_pulse = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var center := size * 0.5
	var color := COLOR_ACTIVE if _kind != StringName() else COLOR_IDLE
	color.a = lerpf(color.a, 0.95, _pulse)
	var radius := lerpf(DOT_RADIUS, DOT_RADIUS * 2.2, _pulse)
	draw_circle(center, radius, color)
	if _kind == StringName():
		return
	var reach := RING_RADIUS + TICK * (1.0 + _pulse * 0.5)
	var faint := color
	faint.a *= 0.55
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(center + direction * RING_RADIUS, center + direction * reach, faint, 1.2)
