## subtitle_box.gd — sous-titres du monologue intérieur de Camille (U-7, file U-11).
##
## Écoute `EventBus.subtitle_requested(text_key, duration)` (durées : data/strings/subtitles.md)
## et affiche `tr(text_key)` en bas de l'écran. Respecte le réglage « sous-titres »
## (UiSettings / signal `settings_changed`). Une clé inconnue est ignorée avec un
## warning : jamais de clé brute à l'écran.
##
## **U-11 (ARCHITECTURE §7)** : les demandes sont **empilées**, jamais écrasées.
## Une règle `subtitle:` qui en déclenche trois dans la même frame (onboarding du hall,
## téléphone puis trappe) les joue l'une après l'autre :
##   - **FIFO**, `MAX_QUEUED` lignes en attente au maximum (au-delà : ignorée + warning) ;
##   - **durées cumulées** : chaque ligne garde sa propre durée, `remaining_time()`
##     donne le total restant de la file ;
##   - **`GAP` = 0,3 s d'écart** entre deux lignes (respiration, pas de collage) ;
##   - la ligne de lore d'un objet coché (`item_checked`, posée par `hud_hints`)
##     arrive par la même porte et passe donc **après toute ligne déjà en file**.
class_name SubtitleBox
extends Control

const DEFAULT_DURATION := 3.0
const MIN_DURATION := 0.8
const FADE_IN := 0.16
const FADE_OUT := 0.5
## Écart entre deux lignes de la file (U-11).
const GAP := 0.3
## Lignes en attente, hors ligne affichée (U-11).
const MAX_QUEUED := 4
const FONT_SIZE := 26

var _label: Label
var _tween: Tween
var _queue: Array[Dictionary] = []
var _busy := false
var _current_key := StringName()
var _line_started_msec := 0
var _line_total := 0.0


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
	EventBus.subtitle_requested.connect(_on_subtitle_requested)
	EventBus.settings_changed.connect(_on_settings_changed)


## Demande une ligne. Elle part immédiatement si rien n'est à l'écran, sinon elle
## prend sa place dans la file (FIFO) : la ligne en cours n'est jamais écrasée (U-11).
## `duration <= 0` → durée par défaut.
func show_line(text_key: StringName, duration: float = DEFAULT_DURATION) -> void:
	if _label == null:
		return
	if not UiSettings.get_bool(&"subtitles"):
		hide_line()
		return
	if not UiText.has_key(text_key):
		push_warning("SubtitleBox : clé de sous-titre inconnue %s — ignorée." % text_key)
		return
	if _queue.size() >= MAX_QUEUED:
		push_warning(
			"SubtitleBox : file pleine (%d lignes en attente) — %s ignorée." % [MAX_QUEUED, text_key]
		)
		return
	_queue.append({"key": text_key, "duration": maxf(duration, MIN_DURATION)})
	_pump()


## Coupe tout : la ligne affichée s'estompe et la file est vidée (réglage « sous-titres »
## désactivé, retour au menu).
func hide_line() -> void:
	_queue.clear()
	_busy = false
	_current_key = StringName()
	if _label == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(func() -> void: visible = false)


## Texte affiché (tests) ; vide si rien n'est lisible à l'écran.
func current_text() -> String:
	if _label == null or not visible or _label.modulate.a < 0.5:
		return ""
	return _label.text


# --- Accès de test ---

## Clé de la ligne en cours (&"" si aucune).
func current_key() -> StringName:
	return _current_key


## Vrai si une ligne occupe l'écran (fondu compris).
func is_showing() -> bool:
	return _busy


## Nombre de lignes en attente, hors ligne affichée.
func queued_count() -> int:
	return _queue.size()


## Clés en attente, dans l'ordre de passage.
func queue_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for entry: Dictionary in _queue:
		keys.append(StringName(entry.get("key", &"")))
	return keys


## Temps restant avant la fin de la file : durées **cumulées** + fondus + écarts (U-11).
func remaining_time() -> float:
	var total := 0.0
	if _busy:
		var elapsed := float(Time.get_ticks_msec() - _line_started_msec) / 1000.0
		total += maxf(0.0, _line_total - elapsed)
	for entry: Dictionary in _queue:
		total += FADE_IN + float(entry.get("duration", DEFAULT_DURATION)) + FADE_OUT + GAP
	return total


# --- Interne ---

func _on_subtitle_requested(text_key: StringName, duration: float) -> void:
	show_line(text_key, duration)


func _on_settings_changed(key: StringName, value: Variant) -> void:
	if key != &"subtitles":
		return
	if not bool(value):
		hide_line()


## Lance la tête de file si l'écran est libre.
func _pump() -> void:
	if _busy or _queue.is_empty() or _label == null:
		return
	_busy = true
	var entry: Dictionary = _queue.pop_front()
	_current_key = StringName(entry.get("key", &""))
	var hold := float(entry.get("duration", DEFAULT_DURATION))
	_label.text = tr(_current_key)
	visible = true
	_line_total = FADE_IN + hold + FADE_OUT + GAP
	_line_started_msec = Time.get_ticks_msec()
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(hold)
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_interval(GAP)
	_tween.tween_callback(_end_of_line)


func _end_of_line() -> void:
	_busy = false
	_current_key = StringName()
	visible = false
	_pump()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
