## screen_math.gd — estimations géométriques partagées par le module Gameplay.
##
## Sert au contrat Item.is_in_frustum(cam) -> float (ARCHITECTURE §7) et à la
## détection des objets cadrés. Code pur : aucune dépendance de scène, testable.
class_name ScreenMath
extends RefCounted


## Boîte englobante monde de tous les VisualInstance3D descendants de node.
## Repli : une petite boîte autour de l'origine du nœud (placeholder sans mesh).
static func merged_world_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for child: Node in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		if visual == null:
			continue
		var box: AABB = visual.global_transform * visual.get_aabb()
		out = box if first else out.merge(box)
		first = false
	if first:
		out = AABB(node.global_position - Vector3(0.1, 0.1, 0.1), Vector3(0.2, 0.2, 0.2))
	return out


## Fraction d'écran (0..1) occupée par la projection d'une boîte monde.
## Estimation par rectangle englobant des 8 sommets projetés, borné à l'écran.
## Retourne 0 si le centre est derrière la caméra ou si l'écran est dégénéré.
static func aabb_coverage(camera: Camera3D, world_aabb: AABB, screen_size: Vector2) -> float:
	if camera == null or screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return 0.0
	if camera.is_position_behind(world_aabb.get_center()):
		return 0.0
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	var used := 0
	for i: int in 8:
		var corner := world_aabb.get_endpoint(i)
		if camera.is_position_behind(corner):
			continue
		var p := camera.unproject_position(corner)
		min_p = min_p.min(p)
		max_p = max_p.max(p)
		used += 1
	if used == 0:
		return 0.0
	var rect := (max_p - min_p).max(Vector2.ZERO)
	return clampf((rect.x * rect.y) / (screen_size.x * screen_size.y), 0.0, 1.0)


## Couverture estimée d'un nœud à partir de sa boîte visuelle.
static func node_coverage(camera: Camera3D, node: Node3D, screen_size: Vector2) -> float:
	return aabb_coverage(camera, merged_world_aabb(node), screen_size)
