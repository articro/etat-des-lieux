## PhotoData — une photo instantanée prise par le joueur. Voir docs/ARCHITECTURE.md §6.
class_name PhotoData
extends RefCounted

var id: int = 0
var timestamp: float = 0.0
var room_id: StringName
var camera_transform: Transform3D
var visible_item_ids: Array[StringName] = []
var revealed_item_ids: Array[StringName] = []
var presence_visible: bool = false
var texture: Texture2D
var developed: bool = false
