## subtitle_box.gd — sous-titres du monologue intérieur de Camille (U-7).
##
## Écoute `EventBus.subtitle_requested(text_key, duration)` (durées : data/strings/subtitles.md),
## affiche `tr(text_key)` en bas de l'écran puis l'estompe. Respecte le réglage
## « sous-titres » (UiSettings / signal `settings_changed`). Une clé inconnue est
## ignorée avec un warning : jamais de clé brute à l'écran.
class_name SubtitleBox
extends Control

const DEFAULT_DURATION := 3.0
const MIN_DURATION := 0.8
const FADE_IN := 0.16
const FADE_OUT := 0.5
const FONT_SIZE := 26

var _label: Label
var _timer: Timer
var _tween: Tween


func _ready() -> void:
	UiText.ensure()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = get_node_or_null("Label") as Label
	if _label == null:
		push_warning("SubtitleBox : nœud Label absent — sous-titres désactivés.")
		set_process(false)
		return
	UiTheme.apply_font(_label, UiTheme.FONT_UI, FONT_SIZE)
	_label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.90))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 8)
	_label.modulate.a = 0.0
	visible = false
	_timer = Timer.new()
	_timer.name = "Hold"
	_timer.one_shot = true
	_timer.timeout.connect(_fade_out)
	add_child(_timer)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)
	EventBus.settings_changed.connect(_on_settings_changed)


## Affiche une ligne. `duration <= 0` → durée par défaut.
func show_line(text_key: StringName, duration: float = DEFAULT_DURATION) -> void:
	if _label == null:
		return
	if not UiSettings.get_bool(&"subtitles"):
		hide_line()
		return
	if not UiText.has_key(text_key):
		push_warning("SubtitleBox : clé de sous-titre inconnue %s — ignorée." % text_key)
		return
	_label.text = tr(text_key)
	visible = true
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, FADE_IN)
	_timer.start(maxf(duration, MIN_DURATION))


## Texte affiché (tests) ; vide si rien n'est à l'écran.
func current_text() -> String:
	if _label == null or not visible or _label.modulate.a < 0.5:
		return ""
	return _label.text


func hide_line() -> void:
	if _label == null:
		return
	_timer.stop()
	_fade_out()


func _on_subtitle_requested(text_key: StringName, duration: float) -> void:
	show_line(text_key, duration)


func _on_settings_changed(key: StringName, value: Variant) -> void:
	if key != &"subtitles":
		return
	if not bool(value):
		hide_line()


func _fade_out() -> void:
	if _label == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(func() -> void: visible = false)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
