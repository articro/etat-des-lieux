## input_actions.gd — filet de sécurité de l'InputMap du module Gameplay.
##
## Les actions sont définies dans project.godot (section [input], exception
## autorisée du périmètre Gameplay). Ce module les recrée à l'exécution si la
## section a disparu (mauvaise fusion, scène lancée dans un projet tiers).
## Les actions déjà présentes ne sont jamais écrasées.
##
## Touches (physical_keycode => ZQSD sur AZERTY, WASD sur QWERTY) :
##   move_forward/back/left/right : W/S/A/D physiques
##   sprint : Maj   crouch : Ctrl ou C   interact : E   flashlight : F
##   camera_raise : clic droit   camera_shoot : clic gauche
##   photo_review : P   notebook : Tab   pause : Échap
class_name InputActions
extends RefCounted

const MOUSE_RAISE: int = MOUSE_BUTTON_RIGHT
const MOUSE_SHOOT: int = MOUSE_BUTTON_LEFT

## Actions clavier et touches physiques associées.
const KEY_EVENTS: Dictionary = {
	&"move_forward": [KEY_W],
	&"move_back": [KEY_S],
	&"move_left": [KEY_A],
	&"move_right": [KEY_D],
	&"sprint": [KEY_SHIFT],
	&"crouch": [KEY_CTRL, KEY_C],
	&"interact": [KEY_E],
	&"flashlight": [KEY_F],
	&"photo_review": [KEY_P],
	&"notebook": [KEY_TAB],
	&"pause": [KEY_ESCAPE],
}

## Actions souris et bouton associé.
const MOUSE_EVENTS: Dictionary = {
	&"camera_raise": MOUSE_RAISE,
	&"camera_shoot": MOUSE_SHOOT,
}


## Ajoute les actions manquantes (sans toucher à celles qui existent déjà).
static func ensure_defaults() -> void:
	for action: StringName in KEY_EVENTS:
		if InputMap.has_action(action):
			continue
		var deadzone: float = 0.2 if String(action).begins_with("move_") else 0.5
		InputMap.add_action(action, deadzone)
		for key: int in KEY_EVENTS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key as Key
			InputMap.action_add_event(action, event)
	for action: StringName in MOUSE_EVENTS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = int(MOUSE_EVENTS[action])
		InputMap.action_add_event(action, event)
