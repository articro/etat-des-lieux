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
## Le réticule garde la forme de la dernière action un court instant.
const CONTEXT_TIME := 1.4

var _film: Label
var _reticle: Reticle
var _context_tween: Tween


func _ready() -> void:
	UiText.ensure()
	UiSettings.apply_all()
	_film = get_node_or_null("FilmCounter") as Label
	_reticle = get_node_or_null("Reticle") as Reticle
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


func _on_player_interacted(_target_id: StringName, kind: StringName) -> void:
	if _reticle == null:
		return
	_reticle.pulse()
	_reticle.set_context(kind)
	if _context_tween != null and _context_tween.is_valid():
		_context_tween.kill()
	_context_tween = create_tween()
	_context_tween.tween_interval(CONTEXT_TIME)
	_context_tween.tween_callback(func() -> void: _reticle.set_context(StringName()))


func _on_notebook_opened() -> void:
	if _reticle != null:
		_reticle.visible = false


func _on_notebook_closed() -> void:
	if _reticle != null:
		_reticle.visible = true
