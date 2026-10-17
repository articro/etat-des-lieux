## ending_screen.gd — les deux écrans de fin de la V1 (U-8).
##
## `main.tscn` instancie cette scène dans son `EndingLayer` puis appelle
## `set_ending_id(&"closed")` ou `set_ending_id(&"ashes")` (contrat Systèmes S-6/S-8).
## Les paragraphes `ENDING_<ID>_P1..P5` s'écrivent un par un, puis la dernière ligne
## se compose comme une ligne d'inventaire (`INV_LINE_FORMAT` + `..._LINE_NAME`,
## numéro sérialisé : 61 pour « Inventaire clos », 1 pour « Cendres »), puis
## l'épilogue. Entrée accélère, Échap révèle tout.
class_name EndingScreen
extends Control

const STYLE_PARAGRAPH := 0
const STYLE_LINE := 1
const STYLE_EPILOGUE := 2
const MAX_PARAGRAPHS := 5
const TYPE_SPEED := 0.014
const STEP_PAUSE := 0.85
const SIZE_PARAGRAPH := 23
const SIZE_LINE := 28
const SIZE_EPILOGUE := 16
const LINE_COLOR := Color(0.62, 0.69, 0.88)

## Émis quand tout est affiché (tests).
signal finished()

var _ending_id := StringName()
var _steps: Array[String] = []
var _styles: Array[int] = []
var _cursor := -1
var _typing := false
var _tween: Tween
var _current: Label

var _title: Label
var _column: VBoxContainer
var _buttons: HBoxContainer


func _ready() -> void:
	UiText.ensure()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title = get_node_or_null("Center/Column/Title") as Label
	_column = get_node_or_null("Center/Column/Steps") as VBoxContainer
	_buttons = get_node_or_null("Center/Column/Buttons") as HBoxContainer
	if _column == null:
		push_warning("Fin : structure incomplète — écran de fin dégradé.")
		return
	theme = UiTheme.ui_theme()
	if _title != null:
		UiTheme.apply_font(_title, UiTheme.FONT_HAND, 76)
	if _buttons != null:
		_buttons.visible = false
		_bind("ToMenu", &"UI_ENDING_BACK", _on_to_menu)
		_bind("Quit", &"UI_ENDING_QUIT", _on_quit)


## Contrat Systèmes : appelée juste après l'instanciation.
func set_ending_id(ending_id: StringName) -> void:
	if _column == null:
		return
	_ending_id = ending_id
	if _title != null:
		_title.text = _ending_title(ending_id)
	_build_steps(ending_id)
	_cursor = -1
	_next_step()


func ending_id() -> StringName:
	return _ending_id


## Textes affichés, dans l'ordre (tests).
func step_texts() -> Array[String]:
	var out: Array[String] = []
	if _column == null:
		return out
	for child: Node in _column.get_children():
		var label := child as Label
		if label != null:
			out.append(label.text)
	return out


func is_finished() -> bool:
	return _cursor >= _steps.size()


# --- Séquence ---

func _build_steps(ending_id: StringName) -> void:
	_steps.clear()
	_styles.clear()
	var upper := String(ending_id).to_upper()
	for index: int in range(1, MAX_PARAGRAPHS + 1):
		var key := StringName("ENDING_%s_P%d" % [upper, index])
		if UiText.has_key(key):
			_steps.append(tr(key))
			_styles.append(STYLE_PARAGRAPH)
	var line_key := StringName("ENDING_%s_LINE_NAME" % upper)
	if UiText.has_key(line_key):
		_steps.append(_final_line(ending_id, line_key))
		_styles.append(STYLE_LINE)
	if UiText.has_key(&"ENDING_GENERIC_EPILOGUE"):
		_steps.append(tr(&"ENDING_GENERIC_EPILOGUE"))
		_styles.append(STYLE_EPILOGUE)
	if _steps.is_empty():
		push_warning("Fin : aucun texte pour %s (clés ENDING_%s_*)." % [ending_id, upper])


## « 61. Camille » (fin close) / « 1. Volant, cuir, usé » (cendres) : le numéro est
## sérialisé, jamais figé (convention Narration, TASKS.md).
func _final_line(ending_id: StringName, name_key: StringName) -> String:
	var index := 1
	if ending_id == &"closed":
		index = InventoryManager.progress().y + 1
	var text := UiText.format(&"INV_LINE_FORMAT", {"index": index, "name": tr(name_key)})
	if text == String(&"INV_LINE_FORMAT"):
		return "%d. %s" % [index, tr(name_key)]
	return text


func _ending_title(ending_id: StringName) -> String:
	var key := StringName("ENDING_%s_TITLE" % String(ending_id).to_upper())
	if UiText.has_key(key):
		return tr(key)
	push_warning("Fin : titre absent pour %s." % ending_id)
	return ""


func _next_step() -> void:
	_cursor += 1
	_typing = false
	_current = null
	if _cursor >= _steps.size():
		_show_buttons()
		return
	var label := _make_step_label(_styles[_cursor])
	label.text = _steps[_cursor]
	label.visible_characters = 0
	_current = label
	_typing = true
	var length := _steps[_cursor].length()
	_tween = create_tween()
	_tween.tween_property(label, "visible_characters", length, maxf(0.35, float(length) * TYPE_SPEED))
	_tween.tween_interval(STEP_PAUSE)
	_tween.tween_callback(_next_step)


func _make_step_label(style: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(940, 0)
	match style:
		STYLE_LINE:
			UiTheme.apply_font(label, UiTheme.FONT_TYPEWRITER_BOLD, SIZE_LINE)
			label.add_theme_color_override("font_color", LINE_COLOR)
		STYLE_EPILOGUE:
			UiTheme.apply_font(label, UiTheme.FONT_UI, SIZE_EPILOGUE)
			label.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_:
			UiTheme.apply_font(label, UiTheme.FONT_TYPEWRITER, SIZE_PARAGRAPH)
			label.add_theme_color_override("font_color", UiTheme.UI_TEXT)
	_column.add_child(label)
	return label


func _show_buttons() -> void:
	_typing = false
	if _buttons != null:
		_buttons.visible = true
	finished.emit()


# --- Entrées ---

func _unhandled_input(event: InputEvent) -> void:
	if _column == null:
		return
	if event.is_action_pressed(&"pause"):
		reveal_all()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_skip_step()
	elif _cursor + 1 < _steps.size():
		_next_step()


## Termine l'écriture en cours et enchaîne immédiatement.
func _skip_step() -> void:
	_kill_tween()
	if _current != null:
		_current.visible_characters = -1
	_next_step()


## Affiche tout d'un coup (Échap, ou tests) puis les boutons.
func reveal_all() -> void:
	_kill_tween()
	while _cursor + 1 < _steps.size():
		_cursor += 1
		var pending := _make_step_label(_styles[_cursor])
		pending.text = _steps[_cursor]
	for child: Node in _column.get_children():
		var label := child as Label
		if label != null:
			label.visible_characters = -1
	_cursor = _steps.size()
	_show_buttons()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_typing = false
	_current = null


# --- Boutons ---

func _on_to_menu() -> void:
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()


func _bind(node_name: String, text_key: StringName, handler: Callable) -> void:
	var button := _buttons.get_node_or_null(node_name) as Button
	if button == null:
		push_warning("Fin : bouton %s absent." % node_name)
		return
	button.text = tr(text_key)
	button.pressed.connect(handler)
