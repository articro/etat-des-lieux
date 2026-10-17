## Variante du prefab Item pour l'interaction longue de la fin Cendres.
extends Item


func get_interact_kind() -> StringName:
	return &"burn"


func get_interact_duration() -> float:
	return 8.0
