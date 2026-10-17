## main_menu.gd — menu principal (U-6).
##
## Fond noir + brouillard (MenuFog), titre manuscrit, quatre boutons. Les signaux
## sont ceux attendus par `main.tscn` (Systèmes, S-6) : `new_game_requested`,
## `continue_requested`, `options_requested`, `quit_requested`. Le panneau Options
## est ouvert **ici** (main.gd ne fait que journaliser `options_requested`).
class_name MainMenu
extends Control

signal new_game_requested()
signal continue_requested()
signal options_requested()
signal quit_requested()

var _title: Label
var _subtitle: Label
var _tagline: Label
var _version: Label
var _continue: Button
var _options: OptionsPanel


func _ready() -> void:
	UiText.ensure()
	UiSettings.apply_all()
	theme = UiTheme.ui_theme()
	# Le menu a besoin de la souris (le joueur n'est pas encore instancié, ou il a
	# été libéré par un écran de fin qui l'avait capturée).
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_cache_nodes()
	_apply_look()
	_bind("NewGame", _on_new_game)
	_bind("Continue", _on_continue)
	_bind("Options", _on_options)
	_bind("Quit", _on_quit)
	_refresh_continue()
	EventBus.save_requested.connect(_refresh_continue)
	EventBus.game_loaded.connect(_refresh_continue)


# --- Signaux attendus par main.tscn ---

func _on_new_game() -> void:
	new_game_requested.emit()


func _on_continue() -> void:
	continue_requested.emit()


func _on_options() -> void:
	options_requested.emit()
	if _options != null:
		_options.open()


func _on_quit() -> void:
	quit_requested.emit()


# --- Habillage ---

func _apply_look() -> void:
	if _title != null:
		_title.text = tr(&"UI_TITLE")
		UiTheme.apply_font(_title, UiTheme.FONT_HAND, 92)
		_title.add_theme_color_override("font_color", UiTheme.UI_TEXT)
	if _subtitle != null:
		_subtitle.text = tr(&"UI_SUBTITLE")
		UiTheme.apply_font(_subtitle, UiTheme.FONT_TYPEWRITER, 24)
		_subtitle.add_theme_color_override("font_color", UiTheme.UI_DIM)
	if _tagline != null:
		_tagline.text = tr(&"UI_TAGLINE")
		_tagline.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_tagline.add_theme_font_size_override("font_size", 17)
	if _version != null:
		_version.text = UiText.format(
			&"UI_VERSION", {"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0"))}
		)
		_version.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_version.add_theme_font_size_override("font_size", 13)
	_label_button("NewGame", &"UI_NEW_GAME")
	_label_button("Continue", &"UI_CONTINUE")
	_label_button("Options", &"UI_OPTIONS")
	_label_button("Quit", &"UI_QUIT")


func _refresh_continue() -> void:
	if _continue != null:
		_continue.disabled = not SaveManager.has_save()


func _bind(node_name: String, handler: Callable) -> void:
	var button := get_node_or_null("Column/Buttons/%s" % node_name) as Button
	if button == null:
		push_warning("Menu : bouton %s absent." % node_name)
		return
	button.pressed.connect(handler)


func _label_button(node_name: String, text_key: StringName) -> void:
	var button := get_node_or_null("Column/Buttons/%s" % node_name) as Button
	if button != null:
		button.text = tr(text_key)


func _cache_nodes() -> void:
	_title = get_node_or_null("Column/Title") as Label
	_subtitle = get_node_or_null("Column/Subtitle") as Label
	_tagline = get_node_or_null("Column/Tagline") as Label
	_version = get_node_or_null("Version") as Label
	_continue = get_node_or_null("Column/Buttons/Continue") as Button
	_options = get_node_or_null("OptionsLayer") as OptionsPanel
	var frame := get_node_or_null("Column") as Control
	if frame != null:
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
