## check_mark.gd — la coche du carnet (U-2).
##
## Deux traits de stylo-bille dessinés à la main, tracés en ~0,34 s quand un objet
## est photographié (`EventBus.item_checked`). Sans animation au rebuild de la liste.
class_name CheckMark
extends Control

const STROKE_WIDTH := 2.6
const DRAW_TIME := 0.34
## Part du tracé consacrée au premier trait (le plus court).
const SPLIT := 0.40
const TILT := -9.0

var _amount: float = 0.0
var _jitter := Vector2.ZERO
var _tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(26, 26)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	_jitter = Vector2(randf_range(-1.2, 1.2), randf_range(-1.2, 1.2))


## Coche immédiate (rebuild de liste) ou animée (l'objet vient d'être fixé).
func set_checked(checked: bool, animate: bool = false) -> void:
	_kill_tween()
	rotation_degrees = 0.0
	if not checked:
		_set_amount(0.0)
		return
	if not animate:
		_set_amount(1.0)
		return
	_set_amount(0.0)
	rotation_degrees = TILT
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_method(_set_amount, 0.0, 1.0, DRAW_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation_degrees", 0.0, DRAW_TIME * 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_checked() -> bool:
	return _amount > 0.99


func _set_amount(value: float) -> void:
	_amount = clampf(value, 0.0, 1.0)
	queue_redraw()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _draw() -> void:
	if _amount <= 0.001:
		return
	var box := size if size.x > 1.0 else custom_minimum_size
	var start := Vector2(box.x * 0.10, box.y * 0.54) + _jitter
	var elbow := Vector2(box.x * 0.38, box.y * 0.85) + _jitter
	var end := Vector2(box.x * 0.94, box.y * 0.13) - _jitter
	var ink := UiTheme.BIRO_BLUE
	ink.a = 0.92
	if _amount <= SPLIT:
		var first := _amount / SPLIT
		draw_polyline(PackedVector2Array([start, start.lerp(elbow, first)]), ink, STROKE_WIDTH)
		return
	var second := (_amount - SPLIT) / (1.0 - SPLIT)
	draw_polyline(PackedVector2Array([start, elbow, elbow.lerp(end, second)]), ink, STROKE_WIDTH)
