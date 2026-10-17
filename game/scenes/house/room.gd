## Comportement commun aux salles du blockout.
extends Node3D


func _ready() -> void:
	var room_id := StringName(str(get_meta(&"room_id", "")))
	var zone := get_node_or_null("Zone") as Area3D
	if zone == null:
		push_warning("RoomBlockout '%s' : zone Area3D absente." % name)
	elif room_id != &"":
		zone.set_meta(&"room_id", room_id)
	else:
		push_warning("RoomBlockout '%s' : metadata room_id absent." % name)

	var standalone := get_tree().current_scene == self
	var camera := get_node_or_null("StandaloneCamera") as Camera3D
	if camera != null:
		camera.current = standalone
	elif standalone:
		push_warning("RoomBlockout '%s' : caméra de test absente." % name)

	var lights := get_node_or_null("StandaloneLights") as Node3D
	if lights != null:
		lights.visible = standalone

	# Le remplissage de la porte côté bureau disparaît dans la maison composée.
	var standalone_only := get_node_or_null("StandaloneOnly") as Node3D
	if standalone_only != null:
		standalone_only.visible = standalone
