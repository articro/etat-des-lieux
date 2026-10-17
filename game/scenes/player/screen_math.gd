## screen_math.gd — estimations géométriques partagées par le module Gameplay.
##
## Sert au contrat Item.is_in_frustum(cam) -> float (ARCHITECTURE §7) et à la
## détection des objets cadrés. Code pur : aucune dépendance de scène, testable.
##
## La couverture est calculée en espace caméra (AABB projetée) et non via
## unproject_position : le résultat ne dépend ni de la résolution réelle du
## viewport, ni du serveur d'affichage (headless compris).
class_name ScreenMath
extends RefCounted

const DEFAULT_ASPECT: float = 16.0 / 9.0


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
## Estimation par le rectangle de la boîte exprimée en espace caméra ; le
## rectangle est borné à l'écran. Retourne 0 si l'objet est derrière la caméra.
static func aabb_coverage(camera: Camera3D, world_aabb: AABB, screen_size: Vector2) -> float:
	if camera == null:
		return 0.0
	var aspect := DEFAULT_ASPECT
	if screen_size.y > 0.0:
		aspect = screen_size.x / screen_size.y
	var to_camera := camera.global_transform.affine_inverse()
	var min_v := Vector3(INF, INF, INF)
	var max_v := Vector3(-INF, -INF, -INF)
	for i: int in 8:
		var local := to_camera * world_aabb.get_endpoint(i)
		min_v = min_v.min(local)
		max_v = max_v.max(local)
	var depth := -(min_v.z + max_v.z) * 0.5
	if depth <= camera.near:
		return 0.0
	var half_h := depth * tan(deg_to_rad(camera.fov) * 0.5)
	var half_w := half_h * aspect
	if half_h <= 0.0 or half_w <= 0.0:
		return 0.0
	# Coordonnées écran normalisées (0..1), y vers le bas.
	var x0 := 0.5 + min_v.x / (2.0 * half_w)
	var x1 := 0.5 + max_v.x / (2.0 * half_w)
	var y0 := 0.5 - max_v.y / (2.0 * half_h)
	var y1 := 0.5 - min_v.y / (2.0 * half_h)
	var left := clampf(minf(x0, x1), 0.0, 1.0)
	var right := clampf(maxf(x0, x1), 0.0, 1.0)
	var top := clampf(minf(y0, y1), 0.0, 1.0)
	var bottom := clampf(maxf(y0, y1), 0.0, 1.0)
	return clampf((right - left) * (bottom - top), 0.0, 1.0)


## Couverture estimée d'un nœud à partir de sa boîte visuelle.
static func node_coverage(camera: Camera3D, node: Node3D, screen_size: Vector2) -> float:
	return aabb_coverage(camera, merged_world_aabb(node), screen_size)
