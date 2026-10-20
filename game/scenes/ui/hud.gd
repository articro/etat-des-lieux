## hud.gd — HUD minimal (U-4) : compteur de films + réticule, et rien d'autre (GDD §10).
##
## Racine = CanvasLayer (main.tscn l'instancie dans un `Node` simple). Le HUD est
## volontairement **sous** le post-process du joueur (CanvasLayer 3) et sous son
## voile de flash (CanvasLayer 5) : le grain s'applique au compteur et le flash
## l'aveugle aussi. Le joueur possède déjà le viseur photo, le voile blanc et la
## jauge d'interaction longue (`player.tscn`) : rien n'est doublé ici.
class_name HudUi
extends CanvasLayer

const FILM_SIZE := 21
const FILM_EMPTY := Color(0.74, 0.31, 0.25)
## Repli uniquement : tant que Gameplay n'émet pas `interact_target_changed`, le
## réticule garde la forme de la dernière action un court instant.
const CONTEXT_TIME := 1.4
const HOVER_SIGNAL := &"interact_target_changed"

var _film: Label
var _reticle: Reticle
var _hints: HudHints
var _context_tween: Tween
## Vrai dès qu'un `interact_target_changed` a été reçu : la cible survolée devient
## alors la seule source de la forme du réticule (décision Architecte, 17/10).
var _hover_driven := false


func _ready() -> void:
	UiText.ensure()
	UiSettings.apply_all()
	_film = get_node_or_null("FilmCounter") as Label
	_reticle = get_node_or_null("Reticle") as Reticle
	_hints = get_node_or_null("Hints") as HudHints
	if _hints != null:
		# Les lignes de lore passent par la boîte de sous-titres du HUD (U-10).
		_hints.set_subtitle_box(get_node_or_null("Subtitles") as SubtitleBox)
	else:
		push_warning("HUD : retours de lisibilité (U-10) absents.")
	if _film == null:
		push_warning("HUD : compteur de films absent — dégradé.")
	else:
		UiTheme.apply_font(_film, UiTheme.FONT_TYPEWRITER, FILM_SIZE)
		_film.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
		_film.add_theme_constant_override("outline_size", 6)
	if _reticle == null:
		push_warning("HUD : réticule absent — dégradé.")
	_refresh_film()
	EventBus.photo_taken.connect(_on_photo_taken)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.notebook_opened.connect(_on_notebook_opened)
	EventBus.notebook_closed.connect(_on_notebook_closed)
	if EventBus.has_signal(HOVER_SIGNAL):
		EventBus.connect(HOVER_SIGNAL, _on_interact_target_changed)
	else:
		push_warning("HUD : EventBus.interact_target_changed absent — réticule non contextuel.")


## Retours de lisibilité U-10 (tests).
func hints() -> HudHints:
	return _hints


func film_text() -> String:
	if _film == null:
		return ""
	return _film.text


## Le compteur suit `InventoryManager.film_count()` : le film est consommé par
## l'appareil AVANT l'émission de `photo_taken` (photo_device.gd).
func _refresh_film() -> void:
	if _film == null:
		return
	var count := InventoryManager.film_count()
	_film.text = UiText.format(&"UI_FILM_COUNT", {"count": count})
	_film.add_theme_color_override("font_color", FILM_EMPTY if count <= 0 else UiTheme.UI_TEXT)


func _on_photo_taken(_photo: PhotoData) -> void:
	_refresh_film()


func _on_game_loaded() -> void:
	_refresh_film()


## Cible sous le réticule (émis par l'Interactor) : `(&"", &"")` quand plus rien.
func _on_interact_target_changed(_target_id: StringName, kind: StringName) -> void:
	_hover_driven = true
	if _context_tween != null and _context_tween.is_valid():
		_context_tween.kill()
	if _reticle != null:
		_reticle.set_context(kind)


func _on_player_interacted(_target_id: StringName, kind: StringName) -> void:
	if _reticle == null:
		return
	_reticle.pulse()
	if _hover_driven:
		return
	# Repli : pas encore de signal de survol, on affiche l'action qui vient d'avoir lieu.
	_reticle.set_context(kind)
	if _context_tween != null and _context_tween.is_valid():
		_context_tween.kill()
	_context_tween = create_tween()
	_context_tween.tween_interval(CONTEXT_TIME)
	_context_tween.tween_callback(func() -> void: _reticle.set_context(StringName()))


## Vrai si la forme du réticule vient du signal de survol (tests).
func is_hover_driven() -> bool:
	return _hover_driven


func _on_notebook_opened() -> void:
	if _reticle != null:
		_reticle.visible = false


func _on_notebook_closed() -> void:
	if _reticle != null:
		_reticle.visible = true
