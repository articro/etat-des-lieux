## document_viewer.gd — lecture d'un document en plein écran (U-5).
##
## `EventBus.document_found` → `DocumentLibrary.get_document(doc_id)` → texte BBCode
## dans un RichTextLabel, typo **machine à écrire** (inventaires, actes, formulaires)
## ou **manuscrite** (lettres, journaux, post-it) selon `DocumentData.kind`, paginé.
## L'ouverture appelle `DocumentLibrary.mark_read()` (API publique) : c'est ce qui
## déclenche `document_read` et donc les révélations d'objets fantômes.
class_name DocumentViewer
extends CanvasLayer

const TAG_PATTERN := "\\[[^\\]]{1,12}\\]"
## Surface de texte de repli tant que la mise en page n'est pas calculée (headless).
const FALLBACK_AREA := Vector2(1052, 560)
const SIZE_TYPEWRITER := 21
const SIZE_HAND := 30
const FADE_TIME := 0.18

var _open := false
var _current_id := StringName()
var _pages: Array[String] = []
var _page := 0
var _tag_regex := RegEx.create_from_string(TAG_PATTERN)

var _dim: ColorRect
var _paper: Panel
var _title: Label
var _author: Label
var _body: RichTextLabel
var _page_label: Label
var _hint: Label


func _ready() -> void:
	UiText.ensure()
	visible = false
	_cache_nodes()
	if _body == null:
		push_warning("Visionneuse : structure incomplète — lecture de documents désactivée.")
		set_process_unhandled_input(false)
		return
	_paper.theme = UiTheme.typewriter_theme()
	_paper.add_theme_stylebox_override("panel", UiTheme.paper_style())
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_apply_look()
	EventBus.document_found.connect(_on_document_found)
	EventBus.game_loaded.connect(_on_game_loaded)


## Ouvre un document par son id (API publique, utilisée par les tests).
func open_document_id(doc_id: StringName) -> void:
	if _open and _current_id == doc_id:
		return
	var doc := DocumentLibrary.get_document(doc_id)
	if doc == null:
		push_warning("Visionneuse : document %s introuvable dans DocumentLibrary." % doc_id)
		return
	open_document(doc)


func open_document(doc: DocumentData) -> void:
	if doc == null or _body == null:
		return
	# L'état est posé avant mark_read : mark_read réémet document_found, la garde
	# ci-dessus empêche la réentrée.
	_current_id = doc.id
	_open = true
	UiState.document_open = true
	_apply_document(doc)
	visible = true
	_fade(0.0, 1.0)
	if not DocumentLibrary.is_read(doc.id):
		DocumentLibrary.mark_read(doc.id)


func close() -> void:
	if not _open:
		return
	_open = false
	_current_id = StringName()
	UiState.document_open = false
	_fade(1.0, 0.0)


func is_open() -> bool:
	return _open


func page_count() -> int:
	return _pages.size()


func current_page() -> int:
	return _page


# --- Contenu ---

func _on_document_found(doc_id: StringName) -> void:
	open_document_id(doc_id)


func _on_game_loaded() -> void:
	close()


func _apply_document(doc: DocumentData) -> void:
	var font := UiTheme.font_for_document_kind(doc.kind)
	var size := SIZE_HAND if font == UiTheme.FONT_HAND else SIZE_TYPEWRITER
	UiTheme.apply_font(_body, font, size)
	UiTheme.apply_font(_title, font, size + 8)
	UiTheme.apply_font(_author, UiTheme.FONT_TYPEWRITER, 16)
	_author.add_theme_color_override("font_color", UiTheme.INK_FADED)
	_title.text = tr(doc.title_key)
	_author.text = _author_line(doc)
	_pages = _paginate(String(tr(doc.body_key)), size)
	_show_page(0)


func _author_line(doc: DocumentData) -> String:
	if doc.author.strip_edges().is_empty() and doc.year <= 0:
		return ""
	if doc.year <= 0:
		return doc.author
	return UiText.format(&"UI_DOC_AUTHOR", {"author": doc.author, "year": doc.year})


func _show_page(index: int) -> void:
	if _pages.is_empty():
		return
	_page = clampi(index, 0, _pages.size() - 1)
	_body.text = _pages[_page]
	if _page_label != null:
		_page_label.text = UiText.format(&"UI_DOC_PAGE", {"page": _page + 1, "pages": _pages.size()})


# --- Pagination (sans mesure de texte : budget de caractères, cf. TASKS.md) ---

func _paginate(text: String, font_size: int) -> Array[String]:
	var budget := _page_budget(font_size)
	var units: Array[String] = []
	for paragraph: String in text.split("\n\n"):
		var trimmed := paragraph.strip_edges()
		if trimmed.is_empty():
			continue
		if _visible_length(trimmed) <= budget:
			units.append(trimmed)
		else:
			for line: String in trimmed.split("\n"):
				if not line.strip_edges().is_empty():
					units.append(line)
	var pages: Array[String] = []
	var current := ""
	for unit: String in units:
		var candidate := unit if current.is_empty() else current + "\n\n" + unit
		if _visible_length(candidate) > budget and not current.is_empty():
			pages.append(current)
			current = unit
		else:
			current = candidate
	if not current.strip_edges().is_empty():
		pages.append(current)
	if pages.is_empty():
		pages.append("")
	return pages


func _page_budget(font_size: int) -> int:
	var area := _body.size if _body != null and _body.size.x > 100.0 else FALLBACK_AREA
	var chars_per_line := maxi(24, int(area.x / (font_size * 0.52)))
	var lines := maxi(6, int(area.y / (font_size * 1.5)))
	return chars_per_line * lines


## Longueur affichée : les balises BBCode ne comptent pas.
func _visible_length(text: String) -> int:
	if _tag_regex == null:
		return text.length()
	return _tag_regex.sub(text, "", true).length()


# --- Entrées ---

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_right"):
		_show_page(_page + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_left"):
		_show_page(_page - 1)
		get_viewport().set_input_as_handled()


# --- Habillage ---

func _apply_look() -> void:
	if _hint != null:
		_hint.text = tr(&"UI_DOC_CLOSE_HINT")
		UiTheme.apply_font(_hint, UiTheme.FONT_UI, 15)
		_hint.add_theme_color_override("font_color", UiTheme.INK_FADED)
	if _page_label != null:
		_page_label.add_theme_font_size_override("font_size", 16)
		_page_label.add_theme_color_override("font_color", UiTheme.INK_FADED)


func _fade(from: float, to: float) -> void:
	if _dim != null:
		_dim.modulate.a = from
	if _paper != null:
		_paper.modulate.a = from
	var tween := create_tween()
	tween.set_parallel(true)
	if _dim != null:
		tween.tween_property(_dim, "modulate:a", to, FADE_TIME)
	if _paper != null:
		tween.tween_property(_paper, "modulate:a", to, FADE_TIME)
	if to <= 0.0:
		tween.chain().tween_callback(func() -> void: visible = false)


func _cache_nodes() -> void:
	_dim = get_node_or_null("Dim") as ColorRect
	_paper = get_node_or_null("Paper") as Panel
	_title = get_node_or_null("Paper/Margin/Column/Title") as Label
	_author = get_node_or_null("Paper/Margin/Column/Author") as Label
	_body = get_node_or_null("Paper/Margin/Column/BodyScroll/Body") as RichTextLabel
	_page_label = get_node_or_null("Paper/Margin/Column/Footer/Page") as Label
	_hint = get_node_or_null("Paper/Margin/Column/Footer/Hint") as Label
