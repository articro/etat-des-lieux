## test_item.gd — Item placeholder du module Gameplay (scène de test uniquement).
##
## Respecte le contrat ARCHITECTURE §7 : `@export data: ItemData`, groupe
## "items", `is_in_frustum(cam) -> float` (couverture écran estimée 0..1).
## Sera remplacé par `scenes/items/item.gd` livré par le Niveau ; le code de
## détection ne dépend que de ce contrat, pas de ce fichier.
class_name TestItem
extends Node3D

@export var data: ItemData


func _ready() -> void:
	add_to_group(&"items")
	if data == null:
		push_warning("TestItem '%s' : ItemData manquante (placeholder de test)." % name)


## Couverture écran estimée de l'objet (0 = hors champ).
func is_in_frustum(camera: Camera3D) -> float:
	if camera == null:
		return 0.0
	var viewport := camera.get_viewport()
	var screen := Vector2(1920.0, 1080.0)
	if viewport != null:
		screen = viewport.get_visible_rect().size
	return ScreenMath.node_coverage(camera, self, screen)


## Id exposé à l'interaction (G-2) tant que le Niveau n'a pas livré item.gd.
func get_interact_id() -> StringName:
	if data == null:
		return &""
	return data.id
