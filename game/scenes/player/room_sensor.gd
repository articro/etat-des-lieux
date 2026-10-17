## room_sensor.gd — détecte la pièce du joueur (G-10). Module Gameplay.
##
## Convention inter-modules (voir docs/TASKS.md, Demandes inter-modules) :
## une zone de pièce fournie par le Niveau est une Area3D *monitorable* portant
## la metadata `room_id` (StringName). Ce capteur, enfant du joueur, la détecte
## et émet player_entered_room / player_left_room — c'est le module Gameplay qui
## émet ces signaux, jamais le Niveau. Zone sans metadata => ignorée en silence.
class_name RoomSensor
extends Area3D

var _rooms: Dictionary = {}       # instance_id (int) -> StringName
var _current: StringName = &""


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


## Pièce courante selon le capteur (GameState reste la source de vérité).
func current_room() -> StringName:
	return _current


func _on_area_entered(area: Area3D) -> void:
	var room := _room_id_of(area)
	if room == &"":
		return
	_rooms[area.get_instance_id()] = room
	if room == _current:
		return
	var previous := _current
	_current = room
	if previous != &"":
		EventBus.player_left_room.emit(previous)
	EventBus.player_entered_room.emit(room)


func _on_area_exited(area: Area3D) -> void:
	var key := area.get_instance_id()
	if not _rooms.has(key):
		return
	var room: StringName = _rooms[key]
	_rooms.erase(key)
	if room != _current:
		return
	# On quitte la pièce courante : bascule sur une zone encore chevauchée
	# (seuil de porte), sinon on est dehors jusqu'à la prochaine zone.
	var fallback: StringName = &""
	for other: StringName in _rooms.values():
		fallback = other
		break
	_current = fallback
	EventBus.player_left_room.emit(room)
	if fallback != &"":
		EventBus.player_entered_room.emit(fallback)


func _room_id_of(area: Area3D) -> StringName:
	if not area.has_meta(&"room_id"):
		return &""
	var value: Variant = area.get_meta(&"room_id")
	if value is StringName:
		return value as StringName
	if value is String:
		return StringName(value)
	return &""
