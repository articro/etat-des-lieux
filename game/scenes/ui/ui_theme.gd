## ui_theme.gd — direction artistique de l'UI (GDD §8 et §10), polices U-9.
##
## Trois familles OFL (voir assets/CREDITS.md) :
##   • Courier Prime  → machine à écrire : inventaires, documents officiels, compteur de films.
##   • Caveat         → manuscrite : annotations de Camille/Lucienne, lettres, titres du carnet.
##   • Lato           → sans-serif : menus, options, sous-titres (lisibilité d'abord).
## Palette : papier vieilli, encre brune, stylo-bille bleu pour les coches, écran quasi noir.
class_name UiTheme
extends RefCounted

const FONT_UI: FontFile = preload("res://assets/fonts/lato_regular.ttf")
const FONT_UI_BOLD: FontFile = preload("res://assets/fonts/lato_bold.ttf")
const FONT_TYPEWRITER: FontFile = preload("res://assets/fonts/courier_prime_regular.ttf")
const FONT_TYPEWRITER_BOLD: FontFile = preload("res://assets/fonts/courier_prime_bold.ttf")
const FONT_TYPEWRITER_ITALIC: FontFile = preload("res://assets/fonts/courier_prime_italic.ttf")
const FONT_HAND: FontFile = preload("res://assets/fonts/caveat_regular.ttf")

# --- Palette (réalisme sale, 1998) ---
const INK := Color(0.13, 0.11, 0.10)
const INK_FADED := Color(0.28, 0.25, 0.22)
const BIRO_BLUE := Color(0.16, 0.22, 0.42)
const PAPER := Color(0.855, 0.826, 0.745)
const PAPER_EDGE := Color(0.70, 0.66, 0.57)
const PAPER_DARK := Color(0.74, 0.70, 0.61)
const SCREEN_BG := Color(0.015, 0.015, 0.02, 0.88)
const SCREEN_SOLID := Color(0.02, 0.02, 0.025)
const UI_TEXT := Color(0.83, 0.82, 0.78)
const UI_DIM := Color(0.5, 0.49, 0.46)
const UI_ACCENT := Color(0.72, 0.66, 0.52)

const SIZE_UI := 20
const SIZE_TYPEWRITER := 20
const SIZE_HAND := 30

static var _ui_theme: Theme
static var _typewriter_theme: Theme
static var _hand_theme: Theme


## Thème par défaut de l'UI (menus, options, sous-titres).
static func ui_theme() -> Theme:
	if _ui_theme != null:
		return _ui_theme
	var theme := Theme.new()
	theme.default_font = FONT_UI
	theme.default_font_size = SIZE_UI
	theme.set_font("bold", "Button", FONT_UI_BOLD)
	theme.set_color("font_color", "Button", UI_TEXT)
	theme.set_color("font_hover_color", "Button", UI_ACCENT)
	theme.set_color("font_pressed_color", "Button", UI_ACCENT)
	theme.set_color("font_disabled_color", "Button", UI_DIM * 0.6)
	theme.set_color("font_focus_color", "Button", UI_ACCENT)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "Button", _button_style(state))
	theme.set_color("font_color", "Label", UI_TEXT)
	theme.set_color("font_color", "CheckBox", UI_TEXT)
	theme.set_font_size("font_size", "Label", SIZE_UI)
	_ui_theme = theme
	return theme


## Thème « machine à écrire » : listes d'inventaire, documents officiels, HUD.
static func typewriter_theme() -> Theme:
	if _typewriter_theme != null:
		return _typewriter_theme
	var theme := _paper_base_theme()
	theme.default_font = FONT_TYPEWRITER
	theme.default_font_size = SIZE_TYPEWRITER
	theme.set_font("bold_font", "RichTextLabel", FONT_TYPEWRITER_BOLD)
	theme.set_font("italics_font", "RichTextLabel", FONT_TYPEWRITER_ITALIC)
	theme.set_font("bold_italics_font", "RichTextLabel", FONT_TYPEWRITER_BOLD)
	_typewriter_theme = theme
	return theme


## Thème « manuscrit » : annotations, lettres, journaux, titres du carnet.
static func hand_theme() -> Theme:
	if _hand_theme != null:
		return _hand_theme
	var theme := _paper_base_theme()
	theme.default_font = FONT_HAND
	theme.default_font_size = SIZE_HAND
	theme.set_font("bold_font", "RichTextLabel", FONT_HAND)
	theme.set_font("italics_font", "RichTextLabel", FONT_HAND)
	theme.set_font("bold_italics_font", "RichTextLabel", FONT_HAND)
	_hand_theme = theme
	return theme


## Police d'un document selon son `DocumentData.kind` (contrat ARCHITECTURE §6).
## Officiel/dactylographié → machine à écrire ; écrit à la main → manuscrit.
static func font_for_document_kind(kind: StringName) -> FontFile:
	match String(kind):
		"letter", "journal", "postit":
			return FONT_HAND
		_:
			return FONT_TYPEWRITER


## Applique une police (et une taille optionnelle) à un contrôle, sans thème complet.
static func apply_font(control: Control, font: Font, size: int = -1) -> void:
	if control == null or font == null:
		return
	control.add_theme_font_override("font", font)
	if size > 0:
		control.add_theme_font_size_override("font_size", size)


## Feuille de papier du carnet / d'un document.
static func paper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = PAPER_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(1)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 26
	style.shadow_offset = Vector2(0, 10)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 26.0
	style.content_margin_bottom = 26.0
	return style


## Fond d'écran (menus, pause, fin) : noir de pellicule, jamais tout à fait opaque.
static func screen_style(alpha: float = 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var color := SCREEN_SOLID
	color.a = alpha
	style.bg_color = color
	return style


## Panneau sombre (menus, pause, options) : liseré discret, jamais de cadre brillant.
static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.045, 0.05, 0.96)
	style.border_color = Color(0.4, 0.38, 0.34, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 40.0
	style.content_margin_right = 40.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 30.0
	return style


static func _paper_base_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "RichTextLabel", INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	return theme


static func _button_style(state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(0)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	if state == "disabled":
		style.border_color = Color(0, 0, 0, 0)
	else:
		style.border_color = UI_ACCENT
		style.border_width_bottom = 1
		if state != "normal":
			style.bg_color = Color(1, 1, 1, 0.03)
	return style
