## pause_menu.gd — pause + accès aux options pendant le jeu (U-6).
##
## Échap met le jeu en pause (`get_tree().paused`) **et** émet `pause_toggled`
## pour que le joueur relâche la souris (convention Gameplay, TASKS.md).
## Priorité des entrées : si une surcouche est ouverte (carnet, document, zoom),
## Échap lui revient — ce menu ne fait rien (voir `UiState`).
class_name PauseMenu
extends CanvasLayer

var _paused := false
var _frame: Panel
var _title: Label
var _hint: Label
var _options: OptionsPanel


func _ready() -> void:
	UiText.ensure()
	visible = false
	_frame = get_node_or_null("Frame") as Panel
	_title = get_node_or_null("Frame/Margin/Column/Title") as Label
	_hint = get_node_or_null("Frame/Margin/Column/Hint") as Label
	_options = get_node_or_null("OptionsLayer") as OptionsPanel
	if _frame == null:
		push_warning("Pause : structure incomplète — menu pause désactivé.")
		set_process_unhandled_input(false)
		return
	_frame.theme = UiTheme.ui_theme()
	_frame.add_theme_stylebox_override("panel", UiTheme.panel_style())
	if _title != null:
		_title.text = tr(&"UI_PAUSE_TITLE")
		UiTheme.apply_font(_title, UiTheme.FONT_HAND, 48)
	if _hint != null:
		_hint.text = tr(&"UI_PAUSE_HINT")
		_hint.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_hint.add_theme_font_size_override("font_size", 15)
	_bind("Resume", _on_resume)
	_bind("Options", _on_options)
	_bind("ToMenu", _on_to_menu)
	_bind("Quit", _on_quit)
	_apply_button_labels()


func is_paused() -> bool:
	return _paused


func set_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	get_tree().paused = paused
	visible = paused
	if not paused and _options != null:
		_options.visible = false
	EventBus.pause_toggled.emit(paused)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _options != null and _options.is_open():
		_options.close()
		get_viewport().set_input_as_handled()
		return
	if UiState.any_overlay_open():
		return
	set_paused(not _paused)
	get_viewport().set_input_as_handled()


func _on_resume() -> void:
	set_paused(false)


func _on_options() -> void:
	if _options != null:
		_options.open()


func _on_to_menu() -> void:
	set_paused(false)
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()


func _bind(node_name: String, handler: Callable) -> void:
	var button := get_node_or_null("Frame/Margin/Column/%s" % node_name) as Button
	if button == null:
		push_warning("Pause : bouton %s absent." % node_name)
		return
	button.pressed.connect(handler)


func _apply_button_labels() -> void:
	_label_button("Resume", &"UI_RESUME")
	_label_button("Options", &"UI_OPTIONS")
	_label_button("ToMenu", &"UI_BACK_TO_MENU")
	_label_button("Quit", &"UI_QUIT_TO_DESKTOP")


func _label_button(node_name: String, text_key: StringName) -> void:
	var button := get_node_or_null("Frame/Margin/Column/%s" % node_name) as Button
	if button != null:
		button.text = tr(text_key)
