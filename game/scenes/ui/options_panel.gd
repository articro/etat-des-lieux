## options_panel.gd — options « mini » de la V1 (U-6).
##
## Sensibilité, FOV, volume, sous-titres, plein écran (+ « lampe plus forte »,
## accessibilité). Aucune API directe vers le joueur ou l'audio : chaque changement
## passe par `UiSettings.set_value()` qui persiste et émet `EventBus.settings_changed`.
## Le même panneau sert au menu principal et au menu pause.
class_name OptionsPanel
extends Control

signal closed

const SLIDER_WIDTH := 300.0
const VALUE_WIDTH := 120.0

var _rows: VBoxContainer
var _title: Label
var _hint: Label
var _back: Button


func _ready() -> void:
	UiText.ensure()
	var frame := get_node_or_null("Frame") as Panel
	if frame != null:
		frame.add_theme_stylebox_override("panel", UiTheme.panel_style())
	_rows = get_node_or_null("Frame/Margin/Column/Rows") as VBoxContainer
	_title = get_node_or_null("Frame/Margin/Column/Title") as Label
	_hint = get_node_or_null("Frame/Margin/Column/Hint") as Label
	_back = get_node_or_null("Frame/Margin/Column/Back") as Button
	if _rows == null:
		push_warning("Options : structure incomplète — panneau désactivé.")
		return
	theme = UiTheme.ui_theme()
	if _title != null:
		_title.text = tr(&"UI_OPTIONS_TITLE")
		UiTheme.apply_font(_title, UiTheme.FONT_HAND, 44)
	if _hint != null:
		_hint.text = tr(&"UI_OPTIONS_HINT")
		_hint.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_hint.add_theme_font_size_override("font_size", 15)
	if _back != null:
		_back.text = tr(&"UI_BACK")
		_back.pressed.connect(close)
	_add_slider(&"mouse_sensitivity", &"UI_OPTION_SENSITIVITY", 2, 1.0)
	_add_slider(&"fov", &"UI_OPTION_FOV", 0, 1.0)
	_add_slider(&"volume_master", &"UI_OPTION_VOLUME", 0, 100.0)
	_add_toggle(&"subtitles", &"UI_OPTION_SUBTITLES")
	_add_toggle(&"fullscreen", &"UI_OPTION_FULLSCREEN")
	_add_toggle(&"flashlight_strong", &"UI_OPTION_FLASHLIGHT")
	visible = false


func open() -> void:
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func row_count() -> int:
	return _rows.get_child_count() if _rows != null else 0


func _add_slider(key: StringName, label_key: StringName, decimals: int, scale: float) -> void:
	var bounds := UiSettings.range_of(key)
	var step := UiSettings.step_of(key)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 18)
	var label := Label.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	var value := Label.new()
	value.custom_minimum_size = Vector2(VALUE_WIDTH, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.text = _format_number(UiSettings.get_float(key), decimals, scale)
	line.add_child(value)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(SLIDER_WIDTH, 0)
	slider.min_value = bounds.x
	slider.max_value = bounds.y
	slider.step = step
	slider.value = UiSettings.get_float(key)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(next: float) -> void: value.text = _format_number(next, decimals, scale))
	# Écriture disque au relâchement seulement : pas de sauvegarde par pixel de glissement.
	slider.drag_ended.connect(func(_changed: bool) -> void: UiSettings.set_value(key, slider.value))
	line.add_child(slider)
	_rows.add_child(line)


func _add_toggle(key: StringName, label_key: StringName) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 18)
	var label := Label.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	var box := CheckBox.new()
	box.button_pressed = UiSettings.get_bool(key)
	box.text = tr(&"UI_OPTION_YES") if box.button_pressed else tr(&"UI_OPTION_NO")
	box.toggled.connect(
		func(on: bool) -> void:
			box.text = tr(&"UI_OPTION_YES") if on else tr(&"UI_OPTION_NO")
			UiSettings.set_value(key, on)
	)
	line.add_child(box)
	_rows.add_child(line)


func _format_number(value: float, decimals: int, scale: float) -> String:
	if scale >= 100.0:
		return str(int(round(value * scale)))
	if decimals <= 0:
		return str(int(round(value)))
	return ("%.2f" % value).replace(".", ",")
