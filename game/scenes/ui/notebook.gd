## notebook.gd — le carnet, seul menu du jeu (U-1, U-2, U-3).
##
## V1 : deux onglets. **Liste** = les 60 lignes de l'inventaire 1973 groupées par
## pièce (`InventoryManager`), coche animée sur `item_checked`, ligne qui s'écrit
## seule sur `inventory_line_added` (« 61. Camille »). **Photos** = vignettes des
## photos développées (`photo_developed`) + zoom.
##
## Le carnet est une surcouche 2D : la version « objet 3D dans la main » du GDD §4.2
## demanderait d'attacher un nœud au joueur (hors périmètre UI) — note dans TASKS.md.
## Aucune dépendance au joueur ni à la maison : EventBus + API publiques en lecture.
class_name NotebookUi
extends CanvasLayer

## Repli seulement : dossier des objets, utilisé tant que `InventoryManager.all_items()`
## (contrat ARCHITECTURE §5, décision Architecte du 17/10) n'est pas implémentée.
const ITEMS_DIR := "res://data/items/"
const TAB_LIST := 0
const TAB_PHOTOS := 1
const SCROLL_STEP := 150.0
const TYPE_TIME_PER_CHAR := 0.03
const FADE_TIME := 0.14
const THUMB_SIZE := Vector2(240, 180)
const GRID_COLUMNS := 4

## Émis pour les tests et le HUD (aucun autre module ne l'écoute).
signal tab_changed(tab: int)

var _open := false
var _tab := TAB_LIST
var _items: Array[ItemData] = []
var _marks: Dictionary = {}          # StringName -> CheckMark
var _labels: Dictionary = {}         # StringName -> Label
var _room_labels: Dictionary = {}    # StringName -> Label
var _pending_marks: Dictionary = {}  # StringName -> true (à animer à l'ouverture)
var _added_rows: Array[Control] = []
var _photos: Array[PhotoData] = []
var _thumbs: Array[Control] = []
var _selected := -1
var _fade_tween: Tween

## L'API `all_items()` est au contrat mais pas encore implémentée : on le dit une
## fois (print, pas warning — la console doit rester propre), puis on se tait.
static var _source_notice_shown := false

var _dim: ColorRect
var _sheet: Panel
var _title: Label
var _progress: Label
var _tab_buttons: Array[Button] = []
var _list_scroll: ScrollContainer
var _list_column: VBoxContainer
var _photos_scroll: ScrollContainer
var _photo_column: VBoxContainer
var _hint: Label
var _zoom: Control
var _zoom_texture: TextureRect
var _zoom_placeholder: Label
var _zoom_caption: Label


func _ready() -> void:
	UiText.ensure()
	visible = false
	_cache_nodes()
	if _list_column == null:
		push_warning("Carnet : structure incomplète — carnet désactivé.")
		set_process_unhandled_input(false)
		return
	_sheet.theme = UiTheme.typewriter_theme()
	_sheet.add_theme_stylebox_override("panel", UiTheme.paper_style())
	_apply_look()
	_build_list()
	_apply_tab()
	EventBus.item_checked.connect(_on_item_checked)
	EventBus.item_revealed.connect(_on_item_revealed)
	EventBus.inventory_line_added.connect(_on_inventory_line_added)
	EventBus.photo_developed.connect(_on_photo_developed)
	EventBus.ending_reached.connect(_on_ending_reached)
	EventBus.game_loaded.connect(_on_game_loaded)


# --- Ouverture / fermeture ---

func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	_open = true
	UiState.notebook_open = true
	visible = true
	_apply_tab()
	_refresh_progress()
	_play_pending_marks()
	_fade(0.4, 1.0)
	EventBus.notebook_opened.emit()


func close() -> void:
	if not _open:
		return
	_close_zoom()
	_open = false
	UiState.notebook_open = false
	_fade(1.0, 0.0)
	EventBus.notebook_closed.emit()


func is_open() -> bool:
	return _open


func _fade(from: float, to: float) -> void:
	_kill_fade()
	_set_fade(from)
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_fade, from, to, FADE_TIME)
	if to <= 0.0:
		_fade_tween.tween_callback(func() -> void: visible = false)


## Un CanvasLayer n'est pas un CanvasItem : le fondu passe par ses enfants.
func _set_fade(value: float) -> void:
	if _dim != null:
		_dim.modulate.a = value
	if _sheet != null:
		_sheet.modulate.a = value


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


# --- Entrées clavier (la souris reste capturée par le joueur) ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"notebook"):
		if not UiState.document_open:
			toggle()
			get_viewport().set_input_as_handled()
		return
	if not _open:
		return
	if event.is_action_pressed(&"pause"):
		if UiState.photo_zoom_open:
			_close_zoom()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if UiState.photo_zoom_open:
		if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"photo_review"):
			_close_zoom()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_left"):
		_set_tab(TAB_LIST)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		_set_tab(TAB_PHOTOS)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept") and _tab == TAB_PHOTOS:
		_open_zoom(_selected)
		get_viewport().set_input_as_handled()


func _navigate(step: int) -> void:
	if _tab == TAB_LIST:
		if _list_scroll != null:
			_list_scroll.scroll_vertical = maxi(0, _list_scroll.scroll_vertical + step * SCROLL_STEP)
		return
	if _thumbs.is_empty():
		return
	_select(clampi(_selected + step, 0, _thumbs.size() - 1))


# --- Construction de la liste (U-2) ---

func _build_list() -> void:
	for child: Node in _list_column.get_children():
		_list_column.remove_child(child)
		child.queue_free()
	_marks.clear()
	_labels.clear()
	_room_labels.clear()
	_items = _collect_items()
	var current_room := StringName()
	for item: ItemData in _items:
		if item.room_id != current_room:
			current_room = item.room_id
			_list_column.add_child(_make_room_header(current_room))
		_list_column.add_child(_make_item_line(item))
	_refresh_progress()
	if _items.is_empty():
		push_warning("Carnet : aucune ligne d'inventaire (data/items/ vide ?).")


## Énumère les objets dans l'ordre de la liste 1973. Passe par
## `InventoryManager.all_items()` dès qu'elle existe ; sinon lit `data/items/`.
## Dans les deux cas, seul ce qu'InventoryManager connaît est affiché (source de
## vérité du cochage) — une ressource orpheline est ignorée avec un warning.
func _collect_items() -> Array[ItemData]:
	var found: Array[ItemData] = []
	if InventoryManager.has_method("all_items"):
		var from_api: Variant = InventoryManager.call("all_items")
		if from_api is Array:
			_append_known(found, from_api)
		else:
			push_warning("Carnet : all_items() n'a pas renvoyé d'Array — repli sur %s." % ITEMS_DIR)
	elif not _source_notice_shown:
		_source_notice_shown = true
		print("Carnet : InventoryManager.all_items() absente — repli sur %s (API au contrat §5, en attente de Systèmes)." % ITEMS_DIR)
	if found.is_empty():
		_append_known(found, _load_item_resources())
	found.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.list_index < b.list_index)
	return found


## Les ItemData du dossier de données (repli). `ResourceLoader` rend les instances
## déjà en cache : ce sont exactement celles d'InventoryManager, pas des copies.
func _load_item_resources() -> Array:
	var out: Array = []
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("Carnet : dossier %s inaccessible — liste vide." % ITEMS_DIR)
		return out
	var files := dir.get_files()
	files.sort()
	for file: String in files:
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var path := ITEMS_DIR + file
		if not ResourceLoader.exists(path):
			push_warning("Carnet : ressource invalide %s." % path)
			continue
		var resource := ResourceLoader.load(path)
		if resource is ItemData:
			out.append(resource)
	return out


func _append_known(target: Array[ItemData], source: Array) -> void:
	for element: Variant in source:
		if not (element is ItemData):
			continue
		var item := element as ItemData
		if InventoryManager.get_item(item.id) == null:
			push_warning("Carnet : %s inconnu d'InventoryManager — ligne ignorée." % item.id)
			continue
		target.append(item)


func _make_room_header(room_id: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = _room_name(room_id).to_upper()
	UiTheme.apply_font(title, UiTheme.FONT_TYPEWRITER_BOLD, 18)
	title.add_theme_color_override("font_color", UiTheme.INK_FADED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var progress := Label.new()
	progress.add_theme_color_override("font_color", UiTheme.INK_FADED)
	progress.add_theme_font_size_override("font_size", 16)
	row.add_child(progress)
	_room_labels[room_id] = progress
	return row


func _make_item_line(item: ItemData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var mark := CheckMark.new()
	row.add_child(mark)
	var label := Label.new()
	label.text = _line_text(item.list_index, tr(item.label_key))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	_marks[item.id] = mark
	_labels[item.id] = label
	if InventoryManager.is_checked(item.id):
		mark.set_checked(true, false)
	return row


## « 23. Pendule arrêtée, 3 h 10 » — format fourni par Narration (INV_LINE_FORMAT).
func _line_text(index: int, item_name: String) -> String:
	return UiText.inventory_line(index, item_name)


func _room_name(room_id: StringName) -> String:
	var key := StringName("ROOM_" + String(room_id).to_upper())
	if UiText.has_key(key):
		return tr(key)
	push_warning("Carnet : pièce sans libellé %s." % room_id)
	return tr(&"ROOM_UNKNOWN")


# --- Réactions aux signaux ---

func _on_item_checked(item_id: StringName, _photo: PhotoData) -> void:
	var mark := _marks.get(item_id) as CheckMark
	if mark == null:
		return
	if _open:
		mark.set_checked(true, true)
	else:
		mark.set_checked(true, false)
		_pending_marks[item_id] = true
	_refresh_progress()


## Un objet fantôme apparaît : sa ligne « fraîchement écrite » clignote à l'encre.
func _on_item_revealed(item_id: StringName) -> void:
	var label := _labels.get(item_id) as Label
	if label == null:
		return
	label.add_theme_color_override("font_color", UiTheme.BIRO_BLUE)
	var tween := create_tween()
	tween.tween_method(
		func(mix: float) -> void:
			label.add_theme_color_override("font_color", UiTheme.BIRO_BLUE.lerp(UiTheme.INK, mix)),
		0.0, 1.0, 1.6
	)


## Une ligne s'écrit seule dans le carnet (fin « Inventaire clos »).
func _on_inventory_line_added(line_index: int, text_key: StringName) -> void:
	if _list_column == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(26, 30)
	row.add_child(spacer)
	var label := Label.new()
	label.text = _line_text(line_index, tr(text_key))
	UiTheme.apply_font(label, UiTheme.FONT_HAND, 28)
	label.add_theme_color_override("font_color", UiTheme.BIRO_BLUE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.visible_characters = 0
	row.add_child(label)
	_list_column.add_child(row)
	_added_rows.append(row)
	var length := label.text.length()
	var tween := create_tween()
	tween.tween_property(label, "visible_characters", length, maxf(0.4, length * TYPE_TIME_PER_CHAR))


## Fin « Cendres » : le carnet brûle, la ligne qui s'était écrite disparaît avec lui.
func _on_ending_reached(ending_id: StringName) -> void:
	if ending_id != &"ashes":
		return
	for row: Control in _added_rows:
		if is_instance_valid(row):
			row.queue_free()
	_added_rows.clear()


func _on_game_loaded() -> void:
	_clear_photos()
	_build_list()


# --- Photos (U-3) ---

func _on_photo_developed(photo: PhotoData) -> void:
	if photo == null:
		push_warning("Carnet : photo_developed sans photo.")
		return
	if _photo_column == null:
		return
	_photos.append(photo)
	_thumbs.append(_make_thumb(photo, _photos.size() - 1))
	_refresh_progress()
	if _selected < 0:
		_select(0)


func _make_thumb(photo: PhotoData, index: int) -> Control:
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 4)
	if photo.texture != null:
		var picture := TextureRect.new()
		picture.texture = photo.texture
		picture.custom_minimum_size = THUMB_SIZE
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(picture)
	else:
		# Capture indisponible (headless, SubViewport absent) : on dégrade, jamais de crash.
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.42, 0.41, 0.38)
		placeholder.custom_minimum_size = THUMB_SIZE
		frame.add_child(placeholder)
		var note := Label.new()
		note.text = tr(&"UI_NOTEBOOK_PHOTO_UNDEVELOPED")
		note.add_theme_font_size_override("font_size", 14)
		frame.add_child(note)
	var caption := Label.new()
	caption.text = "%s — %s" % [_photo_index_text(index), _room_name(photo.room_id)]
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", UiTheme.INK_FADED)
	frame.add_child(caption)
	_photo_column.add_child(frame)
	return frame


func _photo_index_text(index: int) -> String:
	return UiText.format(&"UI_PHOTO_INDEX", {"index": index + 1})


func _select(index: int) -> void:
	if index < 0 or index >= _thumbs.size():
		return
	_selected = index
	for i: int in _thumbs.size():
		_thumbs[i].modulate = Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.55)
	if _photos_scroll != null:
		_photos_scroll.ensure_control_visible(_thumbs[index])


func _open_zoom(index: int) -> void:
	if index < 0 or index >= _photos.size() or _zoom == null:
		return
	var photo := _photos[index]
	_zoom_texture.texture = photo.texture
	_zoom_texture.visible = photo.texture != null
	_zoom_placeholder.visible = photo.texture == null
	_zoom_placeholder.text = tr(&"UI_NOTEBOOK_PHOTO_UNDEVELOPED")
	_zoom_caption.text = "%s — %s" % [_photo_index_text(index), _room_name(photo.room_id)]
	_zoom.visible = true
	UiState.photo_zoom_open = true


func _close_zoom() -> void:
	if _zoom == null or not _zoom.visible:
		return
	_zoom.visible = false
	UiState.photo_zoom_open = false


func _clear_photos() -> void:
	for thumb: Control in _thumbs:
		if is_instance_valid(thumb):
			thumb.queue_free()
	_thumbs.clear()
	_photos.clear()
	_selected = -1


# --- Onglets, habillage, progression ---

func _set_tab(tab: int) -> void:
	var wanted := clampi(tab, TAB_LIST, TAB_PHOTOS)
	if wanted == _tab:
		return
	_tab = wanted
	_apply_tab()
	tab_changed.emit(_tab)


func _apply_tab() -> void:
	if _list_scroll != null:
		_list_scroll.visible = _tab == TAB_LIST
	if _photos_scroll != null:
		_photos_scroll.visible = _tab == TAB_PHOTOS
	for i: int in _tab_buttons.size():
		var active := i == _tab
		UiTheme.apply_font(_tab_buttons[i], UiTheme.FONT_TYPEWRITER_BOLD if active else UiTheme.FONT_TYPEWRITER, 20)
		_tab_buttons[i].add_theme_color_override("font_color", UiTheme.INK if active else UiTheme.INK_FADED)
	if _hint != null:
		_hint.text = tr(&"UI_NOTEBOOK_PHOTOS_HINT") if _tab == TAB_PHOTOS else tr(&"UI_NOTEBOOK_HINT")
	_refresh_progress()


func _apply_look() -> void:
	_tab_buttons = []
	var tab_list := get_node_or_null("Sheet/Margin/Column/Tabs/TabList") as Button
	var tab_photos := get_node_or_null("Sheet/Margin/Column/Tabs/TabPhotos") as Button
	if tab_list != null:
		tab_list.text = tr(&"UI_NOTEBOOK_TAB_LIST")
		_tab_buttons.append(tab_list)
	if tab_photos != null:
		tab_photos.text = tr(&"UI_NOTEBOOK_TAB_PHOTOS")
		_tab_buttons.append(tab_photos)
	if _title != null:
		_title.text = tr(&"UI_NOTEBOOK_TITLE")
		UiTheme.apply_font(_title, UiTheme.FONT_HAND, 36)
	if _hint != null:
		UiTheme.apply_font(_hint, UiTheme.FONT_UI, 15)
		_hint.add_theme_color_override("font_color", UiTheme.INK_FADED)
	if _progress != null:
		_progress.add_theme_font_size_override("font_size", 18)
	if _zoom_caption != null:
		UiTheme.apply_font(_zoom_caption, UiTheme.FONT_TYPEWRITER, 18)
		_zoom_caption.add_theme_color_override("font_color", UiTheme.UI_TEXT)
	if _zoom_placeholder != null:
		_zoom_placeholder.text = tr(&"UI_NOTEBOOK_PHOTO_UNDEVELOPED")
		UiTheme.apply_font(_zoom_placeholder, UiTheme.FONT_TYPEWRITER, 20)
		_zoom_placeholder.add_theme_color_override("font_color", UiTheme.UI_DIM)
	var zoom_hint := _zoom.get_node_or_null("ZoomHint") as Label if _zoom != null else null
	if zoom_hint != null:
		zoom_hint.text = tr(&"UI_NOTEBOOK_PHOTO_ZOOM_HINT")
		UiTheme.apply_font(zoom_hint, UiTheme.FONT_UI, 15)
		zoom_hint.add_theme_color_override("font_color", UiTheme.UI_DIM)


func _refresh_progress() -> void:
	if _progress == null:
		return
	if _tab == TAB_PHOTOS:
		_progress.text = UiText.format(&"UI_PHOTOS_COUNT", {"count": _photos.size()})
	else:
		var progress := InventoryManager.progress()
		_progress.text = UiText.format(&"UI_NOTEBOOK_PROGRESS", {"checked": progress.x, "total": progress.y})
	for room_id: StringName in _room_labels.keys():
		(_room_labels[room_id] as Label).text = _room_progress_text(room_id)


func _room_progress_text(room_id: StringName) -> String:
	var total := 0
	var checked := 0
	for item: ItemData in _items:
		if item.room_id != room_id:
			continue
		total += 1
		if InventoryManager.is_checked(item.id):
			checked += 1
	return UiText.format(&"UI_ROOM_PROGRESS", {"checked": checked, "count": total})


## Les coches survenues carnet fermé s'animent à l'ouverture (le joueur les découvre).
func _play_pending_marks() -> void:
	for item_id: StringName in _pending_marks.keys():
		var mark := _marks.get(item_id) as CheckMark
		if mark != null:
			mark.set_checked(true, true)
	_pending_marks.clear()


## Onglet courant (TAB_LIST / TAB_PHOTOS).
func current_tab() -> int:
	return _tab


## Changement d'onglet depuis le code (tests, futur pad).
func select_tab(tab: int) -> void:
	_set_tab(tab)


## Nombre d'objets listés (doit valoir `InventoryManager.progress().y`).
func item_count() -> int:
	return _items.size()


## Nombre de lignes affichées (objets + en-têtes de pièce + lignes ajoutées).
func line_count() -> int:
	return _list_column.get_child_count() if _list_column != null else 0


func photo_count() -> int:
	return _photos.size()


func added_line_count() -> int:
	return _added_rows.size()


## Texte de la dernière ligne qui s'est écrite seule (« 61. Camille »).
func added_line_text() -> String:
	if _added_rows.is_empty():
		return ""
	var row := _added_rows[-1]
	var label := row.get_child(row.get_child_count() - 1) as Label
	return label.text if label != null else ""


func is_line_checked(item_id: StringName) -> bool:
	var mark := _marks.get(item_id) as CheckMark
	return mark != null and mark.is_checked()


func line_text(item_id: StringName) -> String:
	var label := _labels.get(item_id) as Label
	return label.text if label != null else ""


func _cache_nodes() -> void:
	_dim = get_node_or_null("Dim") as ColorRect
	_sheet = get_node_or_null("Sheet") as Panel
	_title = get_node_or_null("Sheet/Margin/Column/Head/Title") as Label
	_progress = get_node_or_null("Sheet/Margin/Column/Head/Progress") as Label
	_list_scroll = get_node_or_null("Sheet/Margin/Column/Pages/ListScroll") as ScrollContainer
	_list_column = get_node_or_null("Sheet/Margin/Column/Pages/ListScroll/ListColumn") as VBoxContainer
	_photos_scroll = get_node_or_null("Sheet/Margin/Column/Pages/PhotosScroll") as ScrollContainer
	_photo_column = get_node_or_null("Sheet/Margin/Column/Pages/PhotosScroll/PhotoColumn") as VBoxContainer
	_hint = get_node_or_null("Sheet/Margin/Column/Hint") as Label
	_zoom = get_node_or_null("Zoom") as Control
	_zoom_texture = get_node_or_null("Zoom/ZoomTexture") as TextureRect
	_zoom_placeholder = get_node_or_null("Zoom/ZoomPlaceholder") as Label
	_zoom_caption = get_node_or_null("Zoom/ZoomCaption") as Label
