## Scène principale (S-6) : menu → jeu (house.tscn + player.tscn + UI) → fin.
## Les scènes des autres modules sont chargées par chemin (composition du niveau racine,
## autorisée par ARCHITECTURE §2) et dégradées proprement si elles n'existent pas encore.
extends Node

const HOUSE_SCENE := "res://scenes/house/house.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const UI_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const UI_HUD_SCENE := "res://scenes/ui/hud.tscn"
const UI_ENDING_SCENE := "res://scenes/ui/ending_screen.tscn"

## Signaux attendus sur la racine de main_menu.tscn (UI) — voir demande inter-modules.
const MENU_SIGNALS: Array[String] = [
	"new_game_requested", "continue_requested", "options_requested", "quit_requested",
]

@onready var _game_root: Node = $GameRoot
@onready var _menu_layer: CanvasLayer = $MenuLayer
@onready var _ending_layer: CanvasLayer = $EndingLayer

var _playing: bool = false
var _ending_shown: bool = false


func _ready() -> void:
	EventBus.ending_reached.connect(_on_ending_reached)
	_show_menu()
	var p := InventoryManager.progress()
	print("État des lieux — démarrage. Objets chargés : %d, films : %d" % [p.y, InventoryManager.film_count()])


# --- Menu ---

func _show_menu() -> void:
	_clear_children(_menu_layer)
	var menu := _instance_optional(UI_MENU_SCENE, _menu_layer)
	if menu != null and _connect_menu_signals(menu):
		return
	if menu != null:
		push_warning("Main : main_menu.tscn sans signaux new_game_requested/… — menu placeholder utilisé.")
	_clear_children(_menu_layer)
	_menu_layer.add_child(_build_placeholder_menu())


func _connect_menu_signals(menu: Node) -> bool:
	var connected := false
	if menu.has_signal("new_game_requested"):
		menu.connect("new_game_requested", _on_new_game)
		connected = true
	if menu.has_signal("continue_requested"):
		menu.connect("continue_requested", _on_continue)
		connected = true
	if menu.has_signal("options_requested"):
		menu.connect("options_requested", _on_options)
		connected = true
	if menu.has_signal("quit_requested"):
		menu.connect("quit_requested", _on_quit)
		connected = true
	return connected


func _build_placeholder_menu() -> Control:
	var center := CenterContainer.new()
	center.name = "PlaceholderMenu"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_make_button("UI_NEW_GAME", _on_new_game))
	var continue_btn := _make_button("UI_CONTINUE", _on_continue)
	continue_btn.disabled = not SaveManager.has_save()
	box.add_child(continue_btn)
	box.add_child(_make_button("UI_OPTIONS", _on_options))
	box.add_child(_make_button("UI_QUIT", _on_quit))
	center.add_child(box)
	return center


func _make_button(text_key: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = tr(text_key)
	btn.pressed.connect(handler)
	return btn


# --- Actions du menu ---

func _on_new_game() -> void:
	GameState.from_save_dict({})
	InventoryManager.from_save_dict({})
	HouseDirector.from_save_dict({})
	DocumentLibrary.from_save_dict({})
	_start_game(false)


func _on_continue() -> void:
	if not SaveManager.has_save():
		push_warning("Main : aucune sauvegarde à charger.")
		return
	_start_game(true)


func _on_options() -> void:
	push_warning("Main : options à venir (UI, U-6).")


func _on_quit() -> void:
	get_tree().quit()


# --- Jeu ---

func _start_game(from_save: bool) -> void:
	_clear_children(_menu_layer)
	_clear_children(_ending_layer)
	_ending_shown = false
	# La maison et le joueur d'abord : ils doivent être dans l'arbre avant le
	# rattrapage post-chargement (game_loaded) pour appliquer les événements.
	_instance_optional(HOUSE_SCENE, _game_root)
	_instance_optional(PLAYER_SCENE, _game_root)
	_instance_optional(UI_HUD_SCENE, _game_root)
	_playing = true
	if from_save:
		var err := SaveManager.load_game()
		if err != OK:
			push_warning("Main : échec du chargement de la sauvegarde (%s)." % error_string(err))
	else:
		EventBus.save_requested.emit()


# --- Fin ---

func _on_ending_reached(ending_id: StringName) -> void:
	if _ending_shown:
		return
	_ending_shown = true
	_playing = false
	_clear_children(_game_root)
	var ending := _instance_optional(UI_ENDING_SCENE, _ending_layer)
	if ending != null:
		if ending.has_method("set_ending_id"):
			ending.call("set_ending_id", ending_id)
		return
	push_warning("Main : ending_screen.tscn absente — écran de fin dégradé.")
	_ending_layer.add_child(_build_placeholder_ending(ending_id))


func _build_placeholder_ending(ending_id: StringName) -> Control:
	var center := CenterContainer.new()
	center.name = "PlaceholderEnding"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = tr("ENDING_%s_TITLE" % String(ending_id).to_upper())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_make_button("UI_QUIT", _on_quit))
	center.add_child(box)
	return center


# --- Utilitaires ---

func _instance_optional(path: String, parent: Node) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("Main : scène absente %s (module non livré ?)." % path)
		return null
	var res := load(path)
	if not (res is PackedScene):
		push_warning("Main : %s n'est pas une PackedScene." % path)
		return null
	var node := (res as PackedScene).instantiate()
	parent.add_child(node)
	return node


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
