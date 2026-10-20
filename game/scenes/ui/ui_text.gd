## ui_text.gd — accès aux chaînes de l'UI (U-9).
##
## Les chaînes du module UI vivent dans `scenes/ui/ui_strings.csv` (périmètre UI)
## et non dans `data/strings/fr.csv` (périmètre Narration) : ce fichier est donc
## chargé puis **enregistré dans le TranslationServer** au premier appel. Après
## `UiText.ensure()`, `tr("UI_...")` fonctionne normalement partout dans l'UI.
## Une demande de fusion dans `data/strings/fr.csv` est déposée dans TASKS.md.
##
## Usage :
##   UiText.ensure()                        # 1re ligne de _ready() de chaque scène UI
##   label.text = tr("UI_PAUSE_TITLE")      # chaîne simple
##   label.text = UiText.format(&"UI_FILM_COUNT", {"count": 7})   # chaîne à paramètres
class_name UiText
extends RefCounted

const CSV_PATH := "res://scenes/ui/ui_strings.csv"
const TRANSLATION_PATH := "res://scenes/ui/ui_strings.fr.translation"
const LOCALE := "fr"

static var _installed: bool = false
static var _missing: bool = false


## Installe la traduction UI dans le TranslationServer (idempotent, sans crash).
static func ensure() -> void:
	if _installed or _missing:
		return
	var translation: Translation = _load_translation()
	if translation == null:
		_missing = true
		push_warning(
			"UiText : aucune traduction UI chargée (%s absent) — les clés s'afficheront telles quelles."
			% CSV_PATH
		)
		return
	TranslationServer.add_translation(translation)
	_installed = true


## Chaîne traduite, hors contexte d'objet (fonctions statiques, tests).
static func t(key: StringName) -> String:
	ensure()
	return String(TranslationServer.translate(key))


## Chaîne traduite dont on remplace les `{param}` par les valeurs fournies.
## Une clé absente renvoie la clé elle-même : jamais de crash, jamais de vide.
static func format(key: StringName, values: Dictionary) -> String:
	var text := t(key)
	for param: String in values.keys():
		text = text.replace("{%s}" % param, str(values[param]))
	return text


## « 23. Pendule arrêtée, 3 h 10 » — une ligne de l'inventaire 1973.
## Le format vient de Narration (`INV_LINE_FORMAT` dans fr.csv) ; repli si absent.
static func inventory_line(index: int, item_name: String) -> String:
	var text := format(&"INV_LINE_FORMAT", {"index": index, "name": item_name})
	if text == String(&"INV_LINE_FORMAT"):
		return "%d. %s" % [index, item_name]
	return text


## Vrai si la clé possède une traduction connue (utile aux tests et aux replis).
static func has_key(key: StringName) -> bool:
	ensure()
	return String(TranslationServer.translate(key)) != String(key)


## Priorité au .translation généré par l'import Godot ; repli sur une lecture
## directe du CSV (projet jamais importé, export partiel…) pour rester lisible.
static func _load_translation() -> Translation:
	if ResourceLoader.exists(TRANSLATION_PATH):
		var resource: Resource = ResourceLoader.load(TRANSLATION_PATH)
		if resource is Translation:
			return resource as Translation
		push_warning("UiText : %s n'est pas une Translation, lecture du CSV." % TRANSLATION_PATH)
	return _translation_from_csv()


static func _translation_from_csv() -> Translation:
	if not FileAccess.file_exists(CSV_PATH):
		return null
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_warning("UiText : ouverture impossible de %s." % CSV_PATH)
		return null
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2:
		file.close()
		return null
	var translation := Translation.new()
	translation.locale = header[1].strip_edges()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2:
			continue
		var key := row[0].strip_edges()
		if key.is_empty() or key == "keys":
			continue
		translation.add_message(StringName(key), row[1])
	file.close()
	return translation
