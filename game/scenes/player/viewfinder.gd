## viewfinder.gd — viseur de l'appareil photo (G-3).
##
## Quatre équerres + point central, dessinés sans texte. Apparaît quand
## l'appareil est levé (clic droit maintenu), disparaît sinon.
class_name Viewfinder
extends Control

const COLOR: Color = Color(0.92, 0.9, 0.86, 0.55)
const INSET: float = 56.0
const ARM: float = 26.0
const THICKNESS: float = 2.0
const SHOW_TIME: float = 0.14

var _amount: float = 0.0
var _tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_raised(raised: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_amount, _amount, 1.0 if raised else 0.0, SHOW_TIME)


func _set_amount(value: float) -> void:
	_amount = value
	modulate.a = value
	visible = value > 0.01
	queue_redraw()


func _draw() -> void:
	if _amount <= 0.01:
		return
	var rect := Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0)
	if rect.size.x <= ARM * 2.0 or rect.size.y <= ARM * 2.0:
		return
	var color := COLOR
	color.a = COLOR.a * _amount
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	var bottom_right := rect.end
	# Équerres
	draw_line(top_left, top_left + Vector2(ARM, 0.0), color, THICKNESS)
	draw_line(top_left, top_left + Vector2(0.0, ARM), color, THICKNESS)
	draw_line(top_right, top_right + Vector2(-ARM, 0.0), color, THICKNESS)
	draw_line(top_right, top_right + Vector2(0.0, ARM), color, THICKNESS)
	draw_line(bottom_left, bottom_left + Vector2(ARM, 0.0), color, THICKNESS)
	draw_line(bottom_left, bottom_left + Vector2(0.0, -ARM), color, THICKNESS)
	draw_line(bottom_right, bottom_right + Vector2(-ARM, 0.0), color, THICKNESS)
	draw_line(bottom_right, bottom_right + Vector2(0.0, -ARM), color, THICKNESS)
	# Point de visée
	draw_circle(size * 0.5, 1.6, color)
