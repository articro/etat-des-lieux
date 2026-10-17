## ui_settings.gd — réglages de l'UI (U-6), contrat ARCHITECTURE §7 « Options ».
##
## L'UI est propriétaire des réglages : elle les persiste dans `user://settings.cfg`
## et émet `EventBus.settings_changed(key, value)` à chaque modification **et une
## fois pour chaque clé au démarrage** (`UiSettings.apply_all()`). Aucun appel
## direct vers le joueur ou l'audio : ils écoutent le signal.
## `apply_all()` est appelé par le menu principal et le HUD ; il est idempotent.
class_name UiSettings
extends RefCounted

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "settings"

## Clés du contrat (ARCHITECTURE §4, signal settings_changed) + valeurs par défaut.
const DEFAULTS := {
	&"mouse_sensitivity": 1.0,
	&"fov": 75.0,
	&"volume_master": 0.8,
	&"volume_sfx": 0.8,
	&"volume_music": 0.8,
	&"subtitles": true,
	&"fullscreen": false,
	&"flashlight_strong": false,
}

## Bornes [min, max] des réglages numériques exposés dans le panneau Options.
const RANGES := {
	&"mouse_sensitivity": Vector2(0.2, 3.0),
	&"fov": Vector2(60.0, 100.0),
	&"volume_master": Vector2(0.0, 1.0),
	&"volume_sfx": Vector2(0.0, 1.0),
	&"volume_music": Vector2(0.0, 1.0),
}

const STEPS := {
	&"mouse_sensitivity": 0.05,
	&"fov": 1.0,
	&"volume_master": 0.05,
	&"volume_sfx": 0.05,
	&"volume_music": 0.05,
}

static var _values: Dictionary = {}
static var _loaded: bool = false
static var _applied: bool = false


## Charge le fichier (ou les défauts), applique ce qui dépend de l'UI, puis émet
## `settings_changed` une fois par clé. Idempotent : sans effet au second appel.
static func apply_all() -> void:
	ensure_loaded()
	if _applied:
		return
	_applied = true
	for key: StringName in DEFAULTS.keys():
		EventBus.settings_changed.emit(key, _values[key])
	_apply_window_mode()


## Charge sans émettre (utile aux tests et à la première ouverture du menu).
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_values = DEFAULTS.duplicate()
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error != OK:
		push_warning("UiSettings : %s illisible (%s) — valeurs par défaut." % [CONFIG_PATH, error_string(error)])
		return
	for key: StringName in DEFAULTS.keys():
		if not config.has_section_key(SECTION, String(key)):
			continue
		var stored: Variant = config.get_value(SECTION, String(key))
		_values[key] = _coerce(key, stored)


## Bornes et pas d'un réglage numérique (panneau Options). Clé inconnue → 0..1.
static func range_of(key: StringName) -> Vector2:
	if RANGES.has(key):
		return RANGES[key]
	return Vector2(0.0, 1.0)


static func step_of(key: StringName) -> float:
	if STEPS.has(key):
		return float(STEPS[key])
	return 0.01


## Lecture typée. Une clé inconnue renvoie la valeur par défaut (jamais de crash).
static func get_value(key: StringName) -> Variant:
	ensure_loaded()
	return _values.get(key, DEFAULTS.get(key))


static func get_float(key: StringName) -> float:
	return float(get_value(key))


static func get_bool(key: StringName) -> bool:
	return bool(get_value(key))


## Écrit, persiste et notifie les autres modules.
static func set_value(key: StringName, value: Variant) -> void:
	ensure_loaded()
	if not DEFAULTS.has(key):
		push_warning("UiSettings : clé inconnue %s ignorée." % key)
		return
	var coerced: Variant = _coerce(key, value)
	if _values.get(key) == coerced:
		return
	_values[key] = coerced
	_persist()
	EventBus.settings_changed.emit(key, coerced)
	if key == &"fullscreen":
		_apply_window_mode()


## Retour aux valeurs d'usine (panneau Options, V2 ; utilisé par les tests).
static func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate()
	_loaded = true
	_persist()
	for key: StringName in DEFAULTS.keys():
		EventBus.settings_changed.emit(key, _values[key])
	_apply_window_mode()


## Réinitialise l'état statique sans toucher au disque (tests headless).
static func _reset_state_for_tests() -> void:
	_values = {}
	_loaded = false
	_applied = false


static func _coerce(key: StringName, value: Variant) -> Variant:
	var fallback: Variant = DEFAULTS.get(key)
	if fallback is bool:
		return bool(value)
	if fallback is float:
		var number := float(value)
		var bounds := range_of(key)
		return clampf(number, bounds.x, bounds.y)
	return value


static func _persist() -> void:
	var config := ConfigFile.new()
	for key: StringName in _values.keys():
		config.set_value(SECTION, String(key), _values[key])
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("UiSettings : écriture impossible de %s (%s)." % [CONFIG_PATH, error_string(error)])


static func _apply_window_mode() -> void:
	var wanted := DisplayServer.WINDOW_MODE_FULLSCREEN if get_bool(&"fullscreen") else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() == wanted:
		return
	DisplayServer.window_set_mode(wanted)
