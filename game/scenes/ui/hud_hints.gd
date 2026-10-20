## hud_hints.gd — lisibilité et retour joueur (U-10, ARCHITECTURE §7 « Lisibilité »,
## décisions du playtest J4 du 20/10).
##
## Le diagnostic J4 : « le joueur ne comprend pas que les objets sont sur la liste
## ni qu'une photo a coché quelque chose » — le seul retour était dans le carnet.
## Quatre retours discrets, en machine à écrire, jamais envahissants :
##
##   1. **Cible sous le réticule** — sur `interact_target_changed` visant un objet de
##      la liste : son libellé 1973 (`tr(label_key)`, format `INV_LINE_FORMAT`) sous le
##      réticule, + « déjà inventorié » s'il est coché. C'est l'outil principal pour
##      comprendre « ceci est sur la liste ».
##   2. **Objet coché** — sur `item_checked` : bandeau « ✓ n° X — libellé » 2,5 s, puis
##      la ligne de lore en sous-titre de Camille 4 s après le coche. Le son
##      `pencil_check` est joué par **AudioManager** (qui écoute `item_checked`) : rien
##      n'est joué ici, sinon il partirait deux fois.
##   3. **E sur un objet** — `player_interacted(id, &"pickup")` : libellé +
##      « photographier pour inventorier » (`UI_HINT_PHOTOGRAPH`, clé Narration R-10,
##      repli local jusque-là).
##   4. **Rappel carnet** — une seule fois par partie, si le carnet n'a jamais été
##      ouvert après 2 photographies.
##
## Le « ✓ » est **dessiné** (`check_mark.gd`) et non composé : U+2713 est absent de la
## table de caractères de Courier Prime (vérifié sur le cmap), il sortirait en tofu.
class_name HudHints
extends Control

const BANNER_TIME := 2.5
## La lore part 4 s après le coche, soit 1,5 s après la disparition du bandeau.
const LORE_DELAY := 4.0
const LORE_TIME := 4.0
const HINT_TIME := 3.0
const REMINDER_TIME := 4.5
const PHOTOS_BEFORE_REMINDER := 2
const FADE_TIME := 0.2

var _subtitle_box: SubtitleBox

var _target_label: Label
var _target_state: HBoxContainer
var _target_state_mark: CheckMark
var _target_state_label: Label
var _target_hint: Label
var _banner: HBoxContainer
var _banner_mark: CheckMark
var _banner_label: Label
var _notice: Label

var _queue: Array[Dictionary] = []
var _busy := false
var _tween: Tween
var _hint_tween: Tween
var _notice_tween: Tween
var _target_tween: Tween
var _lore_key := ""
var _photos := 0
## « Le joueur a trouvé le carnet » : durable, y compris après un chargement.
var _notebook_opened := false
var _reminder_shown := false
var _target_shown := false
var _banner_shown := false
var _notice_shown := false


func _ready() -> void:
	UiText.ensure()
	_cache_nodes()
	_apply_look()
	EventBus.interact_target_changed.connect(_on_interact_target_changed)
	EventBus.item_checked.connect(_on_item_checked)
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.photo_taken.connect(_on_photo_taken)
	EventBus.notebook_opened.connect(_on_notebook_opened)
	EventBus.game_loaded.connect(_reset_session)


## Le bandeau de lore passe par la boîte de sous-titres du HUD (même module) :
## elle respecte déjà le réglage « sous-titres ».
func set_subtitle_box(box: SubtitleBox) -> void:
	_subtitle_box = box


# --- 1 et 3. Cible sous le réticule ---

func _on_interact_target_changed(target_id: StringName, _kind: StringName) -> void:
	var item := InventoryManager.get_item(target_id)
	if item == null:
		_hide_target()
		return
	_show_target(item, false)


func _on_player_interacted(target_id: StringName, kind: StringName) -> void:
	if kind != &"pickup":
		return
	var item := InventoryManager.get_item(target_id)
	if item == null:
		return
	_show_target(item, true)


func _show_target(item: ItemData, with_hint: bool) -> void:
	if _target_label == null:
		return
	_target_shown = true
	_target_label.text = UiText.inventory_line(item.list_index, tr(item.label_key))
	var checked := InventoryManager.is_checked(item.id)
	if _target_state != null:
		_target_state.visible = checked
		if checked and _target_state_mark != null:
			_target_state_mark.set_checked(true, false)
	if _target_hint != null:
		_target_hint.visible = with_hint
		if with_hint:
			_target_hint.text = tr(&"UI_HINT_PHOTOGRAPH")
			_restart_hint_timer()
	_fade_in(_target_root())


## Le rappel « photographier » s'efface seul ; le libellé reste tant que la cible est là.
func _restart_hint_timer() -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(HINT_TIME)
	_hint_tween.tween_callback(_hide_hint)


func _hide_hint() -> void:
	if _target_hint != null:
		_target_hint.visible = false


func _hide_target() -> void:
	_target_shown = false
	if _target_label == null:
		return
	var root := _target_root()
	if root == null or root.modulate.a <= 0.01:
		return
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, FADE_TIME)


func _target_root() -> Control:
	return _target_label.get_parent() as Control if _target_label != null else null


# --- 2. Bandeau « ✓ n° X — libellé » puis lore ---

func _on_item_checked(item_id: StringName, _photo: PhotoData) -> void:
	var item := InventoryManager.get_item(item_id)
	if item == null:
		return
	_queue.append({"index": item.list_index, "label": tr(item.label_key)})
	# La lore jouée est celle du dernier objet du lot (une seule ligne, pas de mur de texte).
	_lore_key = String(item.lore_key)
	_pump_queue()


## Une photo peut cocher plusieurs objets d'un coup : les bandeaux passent en file,
## jamais deux à la fois (sobriété). La lore part après le dernier bandeau, soit 4 s
## après le coche pour le cas courant (un seul objet).
func _pump_queue() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	var entry: Dictionary = _queue.pop_front()
	_show_banner(int(entry.get("index", 0)), String(entry.get("label", "")))
	_kill_tween()
	_tween = create_tween()
	_tween.tween_interval(BANNER_TIME)
	_tween.tween_callback(_hide_banner)
	_tween.tween_callback(_end_of_entry)


## Fin d'un bandeau : on enchaîne le suivant tant que le lot n'est pas épuisé, puis on
## joue la lore du dernier objet coché (une seule ligne par lot, 4 s après son coche).
func _end_of_entry() -> void:
	_busy = false
	if not _queue.is_empty():
		_pump_queue()
		return
	var lore := _lore_key
	_lore_key = ""
	if lore == "" or not UiText.has_key(StringName(lore)):
		return
	_busy = true   # la lore occupe la file jusqu'à sa fin
	_kill_tween()
	_tween = create_tween()
	_tween.tween_interval(LORE_DELAY - BANNER_TIME)
	_tween.tween_callback(_show_lore.bind(lore))
	_tween.tween_interval(LORE_TIME)
	_tween.tween_callback(_finish_lore)


func _finish_lore() -> void:
	_busy = false
	_pump_queue()


func _show_banner(index: int, label: String) -> void:
	_banner_shown = true
	if _banner_label == null:
		return
	_banner_label.text = UiText.format(&"UI_CHECK_BANNER", {"index": index, "label": label})
	if _banner_mark != null:
		_banner_mark.set_checked(true, true)
	_fade_in(_banner)


func _hide_banner() -> void:
	_banner_shown = false
	if _banner == null:
		return
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 0.0, FADE_TIME)


func _show_lore(lore_key: String) -> void:
	if _subtitle_box == null:
		return
	_subtitle_box.show_line(StringName(lore_key), LORE_TIME)


# --- 4. Rappel « Tab : carnet » ---

func _on_photo_taken(_photo: PhotoData) -> void:
	_photos += 1
	_maybe_remind()


func _on_notebook_opened() -> void:
	_notebook_opened = true


func _maybe_remind() -> void:
	if _reminder_shown or _notebook_opened or _photos < PHOTOS_BEFORE_REMINDER:
		return
	_reminder_shown = true
	_notice_shown = true
	if _notice == null:
		return
	_notice.text = tr(&"UI_HINT_NOTEBOOK")
	_fade_in(_notice)
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(REMINDER_TIME)
	_notice_tween.tween_callback(_hide_notice)


func _hide_notice() -> void:
	_notice_shown = false
	if _notice == null:
		return
	var tween := create_tween()
	tween.tween_property(_notice, "modulate:a", 0.0, FADE_TIME)


## Nouvelle partie / chargement : les compteurs d'onboarding repartent de zéro.
func _reset_session() -> void:
	_photos = 0
	_reminder_shown = false
	_busy = false
	_queue.clear()
	_lore_key = ""
	_kill_tween()
	_hide_banner()
	_hide_notice()
	_hide_target()


# --- Habillage ---

func _apply_look() -> void:
	if _target_label != null:
		UiTheme.apply_font(_target_label, UiTheme.FONT_TYPEWRITER, 21)
		_outline(_target_label)
	if _target_state_label != null:
		UiTheme.apply_font(_target_state_label, UiTheme.FONT_UI, 14)
		_target_state_label.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_outline(_target_state_label)
	if _target_hint != null:
		UiTheme.apply_font(_target_hint, UiTheme.FONT_TYPEWRITER, 17)
		_target_hint.add_theme_color_override("font_color", UiTheme.UI_ACCENT)
		_outline(_target_hint)
	if _banner_label != null:
		UiTheme.apply_font(_banner_label, UiTheme.FONT_TYPEWRITER_BOLD, 24)
		_outline(_banner_label)
	if _notice != null:
		UiTheme.apply_font(_notice, UiTheme.FONT_TYPEWRITER, 19)
		_notice.add_theme_color_override("font_color", UiTheme.UI_DIM)
		_outline(_notice)
	for node: Control in [_target_root(), _banner, _notice]:
		if node != null:
			node.modulate.a = 0.0


func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)


func _fade_in(node: Control) -> void:
	if node == null:
		return
	node.modulate.a = 1.0


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


# --- Accès de test ---

func target_text() -> String:
	return _target_label.text if _target_label != null else ""


func target_visible() -> bool:
	return _target_shown and _target_root() != null


func target_state_visible() -> bool:
	return _target_shown and _target_state != null and _target_state.visible


func hint_visible() -> bool:
	return _target_hint != null and _target_hint.visible


func banner_text() -> String:
	if not _banner_shown or _banner_label == null:
		return ""
	return _banner_label.text


func notice_text() -> String:
	if not _notice_shown or _notice == null:
		return ""
	return _notice.text


func queued_entries() -> int:
	return _queue.size() + (1 if _busy else 0)


func photo_count() -> int:
	return _photos


func _cache_nodes() -> void:
	_target_label = get_node_or_null("Target/TargetLabel") as Label
	_target_state = get_node_or_null("Target/TargetState") as HBoxContainer
	_target_state_mark = get_node_or_null("Target/TargetState/TargetStateMark") as CheckMark
	_target_state_label = get_node_or_null("Target/TargetState/TargetStateLabel") as Label
	_target_hint = get_node_or_null("Target/TargetHint") as Label
	_banner = get_node_or_null("Banner") as HBoxContainer
	_banner_mark = get_node_or_null("Banner/BannerMark") as CheckMark
	_banner_label = get_node_or_null("Banner/BannerLabel") as Label
	_notice = get_node_or_null("Notice") as Label
	if _target_label == null or _banner_label == null:
		push_warning("HudHints : structure incomplète — retours de lisibilité désactivés.")
	if _target_state_label != null:
		_target_state_label.text = tr(&"UI_ALREADY_CHECKED")
