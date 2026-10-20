## ui_tests.gd — vérifications headless du module UI (sans gdUnit4).
##
## Lancement : godot --headless --path game res://tests/ui/ui_tests.tscn
## Code de sortie 0 si tout passe, 1 sinon. Même runner manuel que les modules
## Gameplay (`tests/player/player_tests.tscn`) et Systèmes : gdUnit4 n'est pas
## encore installé (tâche Q-1). Ne dépend que de l'API publique (EventBus,
## autoloads, méthodes publiques des scènes UI).
extends Node

const NOTEBOOK_SCENE := "res://scenes/ui/notebook.tscn"
const DOC_SCENE := "res://scenes/ui/document_viewer.tscn"
const HUD_SCENE := "res://scenes/ui/hud.tscn"
const SUB_SCENE := "res://scenes/ui/subtitles.tscn"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const OPTIONS_SCENE := "res://scenes/ui/options_panel.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const ENDING_SCENE := "res://scenes/ui/ending_screen.tscn"
const ROOM_COUNT := 6

var _failures: int = 0
var _checks: int = 0
var _pause_log: Array[bool] = []
var _settings_log: Array[StringName] = []
var _notebook_opened: int = 0
var _menu_requests: Array[StringName] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.notebook_opened.connect(_on_notebook_opened)
	await get_tree().process_frame

	_test_strings()
	_test_theme()
	_test_settings()
	await _test_notebook()
	await _test_documents()
	await _test_hud()
	await _test_subtitles()
	await _test_pause()
	await _test_options()
	await _test_menu()
	await _test_endings()
	await _test_input_priority()
	await _test_save_reload()
	await _test_readability()

	_report()


# --- Chaînes, thème, réglages ---

func _test_strings() -> void:
	print("[Chaînes]")
	UiText.ensure()
	_check(tr(&"UI_PAUSE_TITLE") == "Pause", "ui_strings.csv enregistré dans le TranslationServer")
	_check(UiText.has_key(&"ROOM_KITCHEN"), "libellé de pièce disponible (ROOM_KITCHEN)")
	_check(UiText.has_key(&"INV_LINE_FORMAT"), "INV_LINE_FORMAT visible (fr.csv de Narration)")
	var film := UiText.format(&"UI_FILM_COUNT", {"count": 7})
	_check(film == "Films : 7", "formatage {count} (%s)" % film)
	_check(UiText.t(&"CLE_INCONNUE") == "CLE_INCONNUE", "clé absente renvoyée telle quelle, sans crash")


func _test_theme() -> void:
	print("[Thème / polices]")
	var theme := UiTheme.ui_theme()
	_check(theme != null and theme.default_font != null, "thème UI avec police par défaut")
	_check(UiTheme.FONT_TYPEWRITER != null, "police machine à écrire chargée (Courier Prime)")
	_check(UiTheme.FONT_HAND != null, "police manuscrite chargée (Caveat)")
	_check(UiTheme.FONT_UI != null, "police sans-serif chargée (Lato)")
	_check(UiTheme.font_for_document_kind(&"letter") == UiTheme.FONT_HAND, "lettre → manuscrite")
	_check(UiTheme.font_for_document_kind(&"inventory") == UiTheme.FONT_TYPEWRITER, "inventaire → machine à écrire")
	_check(UiTheme.font_for_document_kind(&"postit") == UiTheme.FONT_HAND, "post-it → manuscrite")


func _test_settings() -> void:
	print("[Réglages]")
	_settings_log.clear()
	UiSettings.apply_all()
	_check(_settings_log.size() >= 8, "apply_all émet settings_changed pour chaque clé (%d)" % _settings_log.size())
	_check(_settings_log.has(&"fov") and _settings_log.has(&"subtitles"), "clés du contrat présentes")
	UiSettings.set_value(&"fov", 90.0)
	_check(is_equal_approx(UiSettings.get_float(&"fov"), 90.0), "FOV enregistré (90)")
	UiSettings.set_value(&"fov", 500.0)
	_check(is_equal_approx(UiSettings.get_float(&"fov"), 100.0), "FOV borné à 100 (%.0f)" % UiSettings.get_float(&"fov"))
	UiSettings.set_value(&"cle_inconnue", 1)
	_check(true, "clé de réglage inconnue ignorée sans crash")
	UiSettings.set_value(&"fov", 75.0)


# --- Carnet ---

func _test_notebook() -> void:
	print("[Carnet]")
	var notebook := await _instance(NOTEBOOK_SCENE) as NotebookUi
	if notebook == null:
		return
	var total := InventoryManager.progress()
	_check(total.y == 60, "60 objets chargés par InventoryManager (%d)" % total.y)
	_check(not notebook.is_open(), "le carnet démarre fermé")
	_check(
		notebook.line_count() == total.y + ROOM_COUNT,
		"une ligne par objet + %d en-têtes de pièce (%d)" % [ROOM_COUNT, notebook.line_count()]
	)
	var before := _notebook_opened
	notebook.open()
	_check(notebook.is_open(), "le carnet s'ouvre (Tab)")
	_check(_notebook_opened == before + 1, "notebook_opened émis")
	_check(UiState.notebook_open, "UiState.notebook_open à vrai")
	var line := notebook.line_text(&"kitchen_clock_stopped")
	_check(line.begins_with("23."), "numéro de ligne via INV_LINE_FORMAT (%s)" % line)
	_check(line.contains("Pendule"), "libellé traduit depuis ITEM_*_LABEL (%s)" % line)

	InventoryManager.check_item(&"kitchen_clock_stopped", _fake_photo(&"kitchen"))
	await _wait(0.45)
	_check(notebook.is_line_checked(&"kitchen_clock_stopped"), "coche animée après item_checked")

	var lines_before := notebook.line_count()
	EventBus.inventory_line_added.emit(61, &"INV_LINE_ADDED_CAMILLE")
	await _wait(0.6)
	_check(notebook.added_line_count() == 1, "une ligne s'est écrite (inventory_line_added)")
	_check(notebook.added_line_text() == "61. Camille", "ligne composée : %s" % notebook.added_line_text())
	_check(notebook.line_count() == lines_before + 1, "la liste compte une ligne de plus")

	EventBus.photo_developed.emit(_fake_photo(&"study"))
	await get_tree().process_frame
	_check(notebook.photo_count() == 1, "photo ajoutée à l'onglet Photos (photo_developed)")
	notebook.select_tab(NotebookUi.TAB_PHOTOS)
	_check(notebook.current_tab() == NotebookUi.TAB_PHOTOS, "onglet Photos sélectionné")
	notebook.select_tab(NotebookUi.TAB_LIST)
	_check(notebook.current_tab() == NotebookUi.TAB_LIST, "retour à l'onglet Liste")
	print(
		"  info - source des objets : %s"
		% ("InventoryManager.all_items()" if InventoryManager.has_method("all_items") else "repli data/items/")
	)
	_check(notebook.item_count() == total.y, "le carnet liste exactement les objets d'InventoryManager (%d)" % notebook.item_count())
	var column := notebook.get_node("Sheet/Margin/Column/Pages/ListScroll/ListColumn") as VBoxContainer
	await get_tree().process_frame
	_check(column != null and column.size.y > 200.0, "liste mise en page (%.0f px de haut)" % (column.size.y if column != null else 0.0))
	notebook.close()
	_check(not notebook.is_open() and not UiState.notebook_open, "le carnet se referme")
	notebook.queue_free()
	await get_tree().process_frame


# --- Documents ---

func _test_documents() -> void:
	print("[Documents]")
	var viewer := await _instance(DOC_SCENE) as DocumentViewer
	if viewer == null:
		return
	viewer.open_document_id(&"hall_postit_besnard")
	_check(viewer.is_open(), "la visionneuse s'ouvre sur document_found")
	_check(UiState.document_open, "UiState.document_open à vrai")
	_check(DocumentLibrary.is_read(&"hall_postit_besnard"), "mark_read appelé (document_read émis)")
	_check(viewer.page_count() >= 1, "document paginé (%d page(s))" % viewer.page_count())
	viewer.open_document_id(&"study_inventory_1973")
	_check(viewer.page_count() > 1, "l'inventaire 1973 tient sur plusieurs pages (%d)" % viewer.page_count())
	viewer.close()
	_check(not viewer.is_open() and not UiState.document_open, "la visionneuse se ferme (Échap)")
	viewer.open_document_id(&"document_inexistant")
	_check(not viewer.is_open(), "document inconnu : warning et rien ne s'ouvre")
	viewer.queue_free()
	await get_tree().process_frame


# --- HUD ---

func _test_hud() -> void:
	print("[HUD]")
	var hud := await _instance(HUD_SCENE) as HudUi
	if hud == null:
		return
	_check(hud is CanvasLayer, "racine CanvasLayer (main.tscn l'ajoute à un Node simple)")
	var before := hud.film_text()
	_check(
		before == UiText.format(&"UI_FILM_COUNT", {"count": InventoryManager.film_count()}),
		"compteur de films initial (%s)" % before
	)
	InventoryManager.consume_film()
	EventBus.photo_taken.emit(_fake_photo(&"hall"))
	await get_tree().process_frame
	_check(hud.film_text() != before, "le compteur suit photo_taken (%s)" % hud.film_text())
	var reticle := hud.get_node_or_null("Reticle") as Reticle
	_check(reticle != null, "réticule présent")
	if reticle != null:
		EventBus.notebook_opened.emit()
		_check(not reticle.visible, "réticule masqué carnet ouvert")
		EventBus.notebook_closed.emit()
		_check(reticle.visible, "réticule rendu carnet fermé")
		EventBus.player_interacted.emit(&"study_desk", &"read")
		await get_tree().process_frame
		_check(reticle.context() == &"read", "repli : la forme suit player_interacted tant qu'aucun survol n'est émis")
		EventBus.interact_target_changed.emit(&"study_desk", &"read")
		await get_tree().process_frame
		_check(hud.is_hover_driven(), "interact_target_changed reçu (contrat du 17/10)")
		_check(reticle.context() == &"read", "réticule contextuel : forme « lire »")
		EventBus.interact_target_changed.emit(&"cellar_stove", &"burn")
		await get_tree().process_frame
		_check(reticle.context() == &"burn", "la forme suit la cible survolée (brûler)")
		EventBus.interact_target_changed.emit(StringName(), StringName())
		await get_tree().process_frame
		_check(reticle.context() == StringName(), "plus de cible → réticule nu")
	hud.queue_free()
	await get_tree().process_frame


# --- Sous-titres ---

func _test_subtitles() -> void:
	print("[Sous-titres]")
	var box := await _instance(SUB_SCENE) as SubtitleBox
	if box == null:
		return
	UiSettings.set_value(&"subtitles", true)
	EventBus.subtitle_requested.emit(&"SUB_TAPE", 2.0)
	await _wait(0.35)
	_check(box.current_text() == String(TranslationServer.translate(&"SUB_TAPE")), "sous-titre affiché (SUB_TAPE)")
	UiSettings.set_value(&"subtitles", false)
	EventBus.subtitle_requested.emit(&"SUB_HALL_KEYS", 2.0)
	await _wait(0.35)
	_check(box.current_text().is_empty(), "réglage sous-titres à faux → rien ne s'affiche")
	UiSettings.set_value(&"subtitles", true)
	EventBus.subtitle_requested.emit(&"SUB_CLE_INCONNUE", 2.0)
	await _wait(0.35)
	_check(box.current_text() != "SUB_CLE_INCONNUE", "clé de sous-titre inconnue ignorée")
	box.queue_free()
	await get_tree().process_frame


# --- Pause, options, menu, fins ---

func _test_pause() -> void:
	print("[Pause]")
	var menu := await _instance(PAUSE_SCENE) as PauseMenu
	if menu == null:
		return
	_pause_log.clear()
	menu.set_paused(true)
	_check(get_tree().paused, "get_tree().paused à vrai")
	_check(_pause_log.has(true), "pause_toggled(true) émis (le joueur relâche la souris)")
	_check(UiState.any_overlay_open() == false, "aucune surcouche ouverte")
	menu.set_paused(false)
	_check(not get_tree().paused, "la pause se lève")
	_check(_pause_log.has(false), "pause_toggled(false) émis")
	menu.queue_free()
	await get_tree().process_frame


func _test_options() -> void:
	var panel := await _instance(OPTIONS_SCENE) as OptionsPanel
	if panel == null:
		return
	print("[Options]")
	_check(panel.row_count() == 6, "6 réglages V1 (sensibilité, FOV, volume, sous-titres, plein écran, lampe) : %d" % panel.row_count())
	var closed: Array[bool] = [false]
	panel.closed.connect(func() -> void: closed[0] = true)
	panel.open()
	_check(panel.is_open(), "le panneau s'ouvre")
	panel.close()
	_check(closed[0] and not panel.is_open(), "le panneau se ferme et émet closed")
	panel.queue_free()
	await get_tree().process_frame


func _test_menu() -> void:
	print("[Menu principal]")
	var menu := await _instance(MENU_SCENE) as MainMenu
	if menu == null:
		return
	for expected: String in ["new_game_requested", "continue_requested", "options_requested", "quit_requested"]:
		_check(menu.has_signal(expected), "signal %s (contrat main.tscn)" % expected)
	menu.new_game_requested.connect(func() -> void: _menu_requests.append(&"new_game_requested"))
	menu.quit_requested.connect(func() -> void: _menu_requests.append(&"quit_requested"))
	_press(menu, "Column/Buttons/NewGame")
	_press(menu, "Column/Buttons/Quit")
	_check(_menu_requests.size() == 2, "les boutons émettent les signaux attendus")
	var continue_button := menu.get_node_or_null("Column/Buttons/Continue") as Button
	_check(continue_button != null, "bouton Continuer présent")
	if continue_button != null:
		_check(continue_button.disabled == (not SaveManager.has_save()), "Continuer grisé sans sauvegarde")
	menu.queue_free()
	await get_tree().process_frame


func _test_endings() -> void:
	print("[Écrans de fin]")
	var ending := await _instance(ENDING_SCENE) as EndingScreen
	if ending == null:
		return
	ending.set_ending_id(&"closed")
	var title := ending.get_node_or_null("Center/Column/Title") as Label
	_check(title != null and title.text == String(TranslationServer.translate(&"ENDING_CLOSED_TITLE")), "titre de la fin close")
	ending.reveal_all()
	_check(ending.is_finished(), "tout le texte est affiché")
	var texts := ending.step_texts()
	_check(texts.size() >= 6, "paragraphes + ligne finale + épilogue (%d)" % texts.size())
	if texts.size() >= 2:
		var expected_index := InventoryManager.progress().y + 1
		_check(
			texts[texts.size() - 2] == "%d. Camille" % expected_index,
			"dernière ligne sérialisée : %s" % texts[texts.size() - 2]
		)
	var buttons := ending.get_node_or_null("Center/Column/Buttons") as HBoxContainer
	_check(buttons != null and buttons.visible, "les boutons apparaissent à la fin")
	ending.queue_free()
	await get_tree().process_frame

	var ashes := await _instance(ENDING_SCENE) as EndingScreen
	if ashes != null:
		ashes.set_ending_id(&"ashes")
		ashes.reveal_all()
		var ashes_texts := ashes.step_texts()
		_check(ashes_texts.size() >= 6, "fin Cendres complète (%d blocs)" % ashes_texts.size())
		if ashes_texts.size() >= 2:
			_check(ashes_texts[ashes_texts.size() - 2].begins_with("1."), "la fin Cendres repart à la ligne 1 (%s)" % ashes_texts[ashes_texts.size() - 2])
		ashes.queue_free()
		await get_tree().process_frame


# --- Rattrapage après chargement d'une sauvegarde ---

func _test_save_reload() -> void:
	print("[Sauvegarde → carnet]")
	var notebook := await _instance(NOTEBOOK_SCENE) as NotebookUi
	if notebook == null:
		return
	var first := InventoryManager.check_item(&"hall_mirror", _fake_photo(&"hall"))
	var second := InventoryManager.check_item(&"study_desk", _fake_photo(&"study"))
	_check(first and second, "deux objets cochés via l'API publique")
	await _wait(0.4)
	_check(
		notebook.is_line_checked(&"hall_mirror") and notebook.is_line_checked(&"study_desk"),
		"les deux coches sont dans le carnet"
	)
	_check(SaveManager.save_game() == OK, "sauvegarde écrite (SaveManager)")
	EventBus.photo_developed.emit(_fake_photo(&"hall"))
	await get_tree().process_frame
	_check(notebook.photo_count() == 1, "une photographie dans l'onglet Photos")
	InventoryManager.from_save_dict({})
	_check(not InventoryManager.is_checked(&"hall_mirror"), "état remis à zéro avant rechargement")
	_check(SaveManager.load_game() == OK, "sauvegarde relue (game_loaded émis)")
	await _wait(0.3)
	_check(notebook.is_line_checked(&"hall_mirror"), "le carnet retrouve ses coches après game_loaded")
	_check(notebook.line_count() == 66, "la liste est reconstruite sans doublon (%d lignes)" % notebook.line_count())
	_check(notebook.photo_count() == 0, "les photos (non persistées) sont vidées")
	notebook.queue_free()
	await get_tree().process_frame


# --- U-10 : lisibilité et retour joueur (ARCHITECTURE §7) ---

func _test_readability() -> void:
	print("[Lisibilité U-10]")
	var hud := await _instance(HUD_SCENE) as HudUi
	if hud == null:
		return
	var hints := hud.hints()
	var subs := hud.get_node_or_null("Subtitles") as SubtitleBox
	_check(hints != null, "retours de lisibilité présents dans le HUD")
	if hints == null:
		hud.queue_free()
		return
	UiSettings.set_value(&"subtitles", true)

	# 1. Libellé 1973 sous le réticule
	var item := InventoryManager.get_item(&"hall_barometer")
	_check(item != null and not InventoryManager.is_checked(item.id), "objet de test non coché au départ")
	EventBus.interact_target_changed.emit(&"hall_barometer", &"pickup")
	await get_tree().process_frame
	_check(hints.target_visible(), "le libellé apparaît sous le réticule")
	_check(
		hints.target_text() == UiText.inventory_line(item.list_index, String(tr(item.label_key))),
		"libellé 1973 + numéro de ligne (%s)" % hints.target_text()
	)
	_check(not hints.target_state_visible(), "pas d'indicateur « déjà inventorié » tant qu'il n'est pas coché")

	# Plus de cible → plus de libellé
	EventBus.interact_target_changed.emit(StringName(), StringName())
	await get_tree().process_frame
	_check(not hints.target_visible(), "plus de cible → libellé effacé")

	# 3. E sur un objet → aide « photographier pour inventorier »
	EventBus.interact_target_changed.emit(&"hall_barometer", &"pickup")
	EventBus.player_interacted.emit(&"hall_barometer", &"pickup")
	await get_tree().process_frame
	_check(hints.hint_visible(), "aide « photographier » affichée sur E (pickup)")
	_check(tr(&"UI_HINT_PHOTOGRAPH") != "UI_HINT_PHOTOGRAPH", "clé UI_HINT_PHOTOGRAPH résolue (%s)" % tr(&"UI_HINT_PHOTOGRAPH"))
	await _wait(3.4)
	_check(not hints.hint_visible(), "l'aide s'efface seule après 3 s")

	# 2. Bandeau ✓ puis lore — par le vrai chemin (check_item émet item_checked)
	_check(InventoryManager.check_item(&"hall_barometer", _fake_photo(&"hall")), "check_item accepte l'objet")
	await _wait(0.4)
	var expected := UiText.format(
		&"UI_CHECK_BANNER", {"index": item.list_index, "label": String(tr(item.label_key))}
	)
	_check(hints.banner_text() == expected, "bandeau ✓ (%s)" % hints.banner_text())
	await _wait(2.6)
	_check(hints.banner_text().is_empty(), "le bandeau disparaît après 2,5 s")
	await _wait(1.6)
	_check(
		subs != null and subs.current_text() == String(tr(item.lore_key)),
		"la ligne de lore part en sous-titre 4 s après le coche"
	)

	# Indicateur « déjà inventorié »
	EventBus.interact_target_changed.emit(&"hall_barometer", &"pickup")
	await get_tree().process_frame
	_check(hints.target_state_visible(), "« déjà inventorié » une fois coché")

	# File d'attente : une photo peut cocher plusieurs objets, jamais deux bandeaux
	await _wait(5.0)
	_check(hints.queued_entries() == 0, "la file se vide (%d)" % hints.queued_entries())
	var second := InventoryManager.get_item(&"hall_doorbell")
	InventoryManager.check_item(&"hall_doorbell", null)
	InventoryManager.check_item(&"hall_coat_rack", null)
	await get_tree().process_frame
	_check(hints.queued_entries() == 2, "deux bandeaux en file, jamais simultanés (%d)" % hints.queued_entries())
	_check(
		hints.banner_text() == UiText.format(
			&"UI_CHECK_BANNER", {"index": second.list_index, "label": String(tr(second.label_key))}
		),
		"le premier bandeau de la file s'affiche (%s)" % hints.banner_text()
	)
	await _wait(2.9)
	_check(hints.queued_entries() == 1, "le second bandeau prend la suite (%d)" % hints.queued_entries())
	_check(hints.banner_text() != "", "second bandeau affiché (%s)" % hints.banner_text())
	await _wait(8.5)
	_check(hints.queued_entries() == 0, "file terminée (%d)" % hints.queued_entries())

	# 4. Rappel « Tab : carnet » après 2 photos, une seule fois
	_check(hints.notice_text().is_empty(), "aucun rappel avant 2 photographies")
	EventBus.photo_taken.emit(_fake_photo(&"hall"))
	await get_tree().process_frame
	_check(hints.notice_text().is_empty(), "toujours rien après 1 photographie")
	EventBus.photo_taken.emit(_fake_photo(&"hall"))
	await get_tree().process_frame
	_check(hints.notice_text() == tr(&"UI_HINT_NOTEBOOK"), "rappel « %s » après 2 photographies" % hints.notice_text())
	EventBus.notebook_opened.emit()
	EventBus.game_loaded.emit()
	await _wait(5.0)
	EventBus.photo_taken.emit(_fake_photo(&"hall"))
	EventBus.photo_taken.emit(_fake_photo(&"hall"))
	await get_tree().process_frame
	_check(hints.notice_text().is_empty(), "carnet déjà ouvert → plus de rappel")
	hud.queue_free()
	await get_tree().process_frame


# --- Priorité des entrées clavier ---

func _test_input_priority() -> void:
	print("[Entrées clavier]")
	var hud := await _instance(HUD_SCENE) as HudUi
	if hud == null:
		return
	var notebook := hud.get_node_or_null("Notebook") as NotebookUi
	_check(notebook != null, "le carnet est dans le HUD")
	if notebook == null:
		hud.queue_free()
		return
	_send_key(KEY_TAB)
	await get_tree().process_frame
	_check(notebook.is_open(), "Tab ouvre le carnet")
	_send_key(KEY_TAB)
	await get_tree().process_frame
	_check(not notebook.is_open(), "Tab referme le carnet")
	_send_key(KEY_TAB)
	await get_tree().process_frame
	_send_key(KEY_ESCAPE)
	await get_tree().process_frame
	_check(not notebook.is_open(), "Échap ferme d'abord le carnet…")
	_check(not get_tree().paused, "…et ne met pas le jeu en pause")
	_send_key(KEY_ESCAPE)
	await get_tree().process_frame
	_check(get_tree().paused, "Échap met en pause quand rien d'autre n'est ouvert")
	_send_key(KEY_ESCAPE)
	await get_tree().process_frame
	_check(not get_tree().paused, "Échap sort de la pause")
	EventBus.document_found.emit(&"hall_postit_besnard")
	await get_tree().process_frame
	var viewer := hud.get_node_or_null("DocumentViewer") as DocumentViewer
	_check(viewer != null and viewer.is_open(), "document_found ouvre la visionneuse")
	_send_key(KEY_ESCAPE)
	await get_tree().process_frame
	_check(not viewer.is_open(), "Échap ferme la visionneuse")
	_check(not get_tree().paused, "toujours pas de pause derrière un document")
	hud.queue_free()
	await get_tree().process_frame


## Envoie une vraie touche dans le pipeline d'entrée (comme le ferait le joueur).
func _send_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)


# --- Utilitaires ---

## Appuie sur un bouton du menu (vérifie le câblage bouton → signal).
func _press(root: Node, path: String) -> void:
	var button := root.get_node_or_null(path) as Button
	if button == null:
		_check(false, "bouton présent : %s" % path)
		return
	button.pressed.emit()


func _instance(path: String) -> Node:
	if not ResourceLoader.exists(path):
		_check(false, "scène présente : %s" % path)
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		_check(false, "scène chargeable : %s" % path)
		return null
	var node := scene.instantiate()
	add_child(node)
	await get_tree().process_frame
	return node


func _fake_photo(room_id: StringName) -> PhotoData:
	var photo := PhotoData.new()
	photo.id = 1
	photo.room_id = room_id
	photo.developed = true
	var image := Image.create_empty(64, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.42, 0.41, 0.38))
	photo.texture = ImageTexture.create_from_image(image)
	return photo


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _on_settings_changed(key: StringName, _value: Variant) -> void:
	_settings_log.append(key)


func _on_pause_toggled(paused: bool) -> void:
	_pause_log.append(paused)


func _on_notebook_opened() -> void:
	_notebook_opened += 1


func _report() -> void:
	print("Tests UI : %d vérifications, %d échec(s)." % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
