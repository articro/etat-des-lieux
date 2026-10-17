## photo_detector.gd — objets réellement cadrés sur une photo (G-4).
##
## Contrat ARCHITECTURE §7 : nœuds du groupe "items" portant `data: ItemData` et
## `is_in_frustum(cam) -> float`. Trois filtres : couverture écran ≥
## data.min_photo_coverage, présence dans le frustum (via le contrat), occlusion
## par un raycast caméra → centre de l'objet.
##
## Occlusion : si l'Item n'a aucun CollisionObject3D enfant, le test est ignoré
## (dégradation documentée dans TASKS.md). Un objet touché par le rayon est
## « vu » ; un autre corps touché avant lui l'occulte.
class_name PhotoDetector
extends RefCounted

const ITEM_GROUP: StringName = &"items"
const DEFAULT_MAX_DISTANCE: float = 40.0


## Ids des objets cadrés et nets, dans l'ordre de l'arbre.
static func collect_visible_items(camera: Camera3D, exclude_rids: Array[RID] = []) -> Array[StringName]:
	var visible_ids: Array[StringName] = []
	if camera == null:
		return visible_ids
	var viewport := camera.get_viewport()
	var screen := Vector2(1920.0, 1080.0)
	if viewport != null:
		screen = viewport.get_visible_rect().size
	for node: Node in camera.get_tree().get_nodes_in_group(ITEM_GROUP):
		var item := node as Node3D
		if item == null or not item.is_visible_in_tree():
			continue
		var data := _item_data(item)
		if data == null or data.id == &"":
			continue
		if camera.global_position.distance_to(item.global_position) > DEFAULT_MAX_DISTANCE:
			continue
		if _coverage(item, camera, screen, data) < data.min_photo_coverage:
			continue
		if _is_occluded(item, camera, exclude_rids):
			continue
		visible_ids.append(data.id)
	return visible_ids


## Couverture écran de l'objet : contrat Item d'abord, estimation locale sinon.
static func _coverage(item: Node3D, camera: Camera3D, screen: Vector2, data: ItemData) -> float:
	if item.has_method(&"is_in_frustum"):
		var value: Variant = item.call(&"is_in_frustum", camera)
		if value is float or value is int:
			return clampf(float(value), 0.0, 1.0)
	push_warning("PhotoDetector : '%s' n'implémente pas is_in_frustum(), estimation locale (%.1f)." % [item.name, data.id])
	return ScreenMath.node_coverage(camera, item, screen)


static func _item_data(item: Node3D) -> ItemData:
	var value: Variant = item.get(&"data")
	return value as ItemData


static func _is_occluded(item: Node3D, camera: Camera3D, exclude_rids: Array[RID]) -> bool:
	var colliders: Array[CollisionObject3D] = []
	for child: Node in item.find_children("*", "CollisionObject3D", true, false):
		var collision := child as CollisionObject3D
		if collision != null:
			colliders.append(collision)
	if colliders.is_empty():
		return false
	var world := item.get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false
	var from := camera.global_position
	var to := ScreenMath.merged_world_aabb(item).get_center()
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# On n'exclut pas les colliders de l'objet : c'est le premier corps touché
	# qui décide (lui = vu, autre = occulté).
	query.exclude = exclude_rids
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false
	var hit := result.get("collider") as Node
	if hit == null:
		return false
	return not _is_descendant_of(hit, item)


## RIDs des colliders du joueur, à exclure des raycasts (le rayon part de
## l'intérieur de la capsule).
static func player_exclude_rids(body: CollisionObject3D) -> Array[RID]:
	var rids: Array[RID] = []
	if body == null:
		return rids
	rids.append(body.get_rid())
	for child: Node in body.find_children("*", "CollisionObject3D", true, false):
		var collision := child as CollisionObject3D
		if collision != null:
			rids.append(collision.get_rid())
	return rids


static func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var current: Node = node
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false
