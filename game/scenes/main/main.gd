## Scène principale — STUB M0. Propriétaire : Systèmes (tâche S-6).
extends Node

@onready var _label: Label = $Label


func _ready() -> void:
	var p := InventoryManager.progress()
	_label.text = "ÉTAT DES LIEUX — M0\nAutoloads OK — objets chargés : %d / films : %d" % [p.y, InventoryManager.film_count()]
	print("État des lieux — projet initialisé. Objets : %d" % p.y)
