## DocumentData — un document lisible (inventaire, lettre, carnet...). Voir docs/ARCHITECTURE.md §6.
class_name DocumentData
extends Resource

@export var id: StringName
@export_enum("inventory", "letter", "journal", "form", "note", "postit", "tape", "drawing") var kind: String = "note"
@export var year: int = 1998
@export var author: String = ""
@export var title_key: StringName
@export var body_key: StringName
@export var pages: int = 1
@export var reveals_items: Array[StringName] = []
@export var sets_flags: Array[StringName] = []
@export var visual_scene: PackedScene
