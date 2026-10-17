## ui_state.gd — état interne du module UI (aucune donnée de jeu).
##
## Sert uniquement à arbitrer les entrées clavier entre les surcouches de l'UI
## (Échap ferme d'abord la surcouche la plus haute avant de mettre en pause).
## Aucun autre module ne lit cette classe : le jeu passe par EventBus.
class_name UiState
extends RefCounted

static var notebook_open: bool = false
static var document_open: bool = false
static var photo_zoom_open: bool = false


## Vrai si une surcouche de l'UI capte le clavier (le menu pause doit s'effacer).
static func any_overlay_open() -> bool:
	return notebook_open or document_open or photo_zoom_open
