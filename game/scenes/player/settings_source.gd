## settings_source.gd — relecture de secours des réglages persistés (module Gameplay).
##
## L'UI (menu Options) écrit `user://settings.cfg` (ConfigFile, ARCHITECTURE §7)
## et émet `EventBus.settings_changed` à chaque changement. Mais le joueur est
## instancié APRÈS le menu : les émissions du démarrage seraient perdues.
## Ce lecteur relit donc le fichier au `_ready()` du joueur, en silence :
## fichier absent, section inattendue ou valeur invalide = réglages par défaut.
##
## Aucune écriture ici : le fichier appartient à l'UI.
class_name SettingsSource
extends RefCounted

const DEFAULT_PATH: String = "user://settings.cfg"

## Clés consommées par le joueur (les autres sont ignorées).
const KEYS: Array[StringName] = [&"mouse_sensitivity", &"fov", &"flashlight_strong"]


## Lit les réglages utiles au joueur. Dictionnaire vide si rien d'exploitable.
## La section du fichier n'est pas imposée : on cherche la clé dans toutes les
## sections (racine comprise), ce qui tolère `[settings]`, `[options]` ou aucun
## en-tête.
static func read(path: String = DEFAULT_PATH) -> Dictionary:
	var out: Dictionary = {}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return out
	for key: StringName in KEYS:
		var value: Variant = _find_value(config, String(key))
		if value != null:
			out[key] = value
	return out


static func _find_value(config: ConfigFile, key: String) -> Variant:
	if config.has_section_key("", key):
		return config.get_value("", key)
	for section: String in config.get_sections():
		if config.has_section_key(section, key):
			return config.get_value(section, key)
	return null
