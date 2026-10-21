## Chargement des modèles CC0 et compositions CSG lisibles des objets de la maison.
extends RefCounted

const DEFAULT_SIZE: Vector3 = Vector3(0.45, 0.45, 0.45)
const MODEL_PATHS: Dictionary[StringName, String] = {
	&"hall_console_table": "res://assets/models/polyhaven/ClassicConsole_01/ClassicConsole_01_1k.gltf",
	&"hall_coat_rack": "res://assets/models/kenney/furniture-kit/coatRackStanding.glb",
	&"hall_mirror": "res://assets/models/polyhaven/ornate_mirror_01/ornate_mirror_01_1k.gltf",
	&"hall_umbrella_stand": "res://assets/models/kenney/furniture-kit/trashcan.glb",
	&"hall_answering_machine": "res://assets/models/polyhaven/cassette_player/cassette_player_1k.gltf",
}
const CSG_ITEM_IDS: Array[StringName] = [
	&"hall_barometer",
	&"hall_key_board",
	&"hall_doorbell",
	&"hall_hand_railing",
	&"hall_ring_1951",
	&"kitchen_calendar",
]


static func create_visual(item: Node3D, item_id: StringName) -> StringName:
	var visual := item.get_node_or_null("Visual") as MeshInstance3D
	if visual == null:
		push_warning("Item '%s' : nœud Visual absent, prefab de secours conservé." % String(item_id))
		return &"placeholder"

	var model_path: String = ""
	if MODEL_PATHS.has(item_id):
		model_path = MODEL_PATHS[item_id]
	if not model_path.is_empty():
		if not ResourceLoader.exists(model_path):
			push_warning("Item '%s' : modèle CC0 absent (%s), essai CSG." % [String(item_id), model_path])
		else:
			var packed := ResourceLoader.load(model_path) as PackedScene
			if packed == null:
				push_warning("Item '%s' : modèle CC0 illisible (%s), essai CSG." % [String(item_id), model_path])
			else:
				var model_instance := packed.instantiate() as Node3D
				if model_instance == null:
					push_warning("Item '%s' : la ressource modèle n'a pas de racine 3D, essai CSG." % String(item_id))
				else:
					var asset_root := Node3D.new()
					asset_root.name = "AssetVisual"
					visual.add_child(asset_root)
					model_instance.name = "Model"
					asset_root.add_child(model_instance)
					_fit_model_to_default_size(asset_root, item_id)
					visual.mesh = null
					_set_item_orientation(item, item_id)
					if item_id == &"hall_umbrella_stand":
						_add_umbrella_stand_accessories(visual)
					return &"model"

	if _build_csg(item_id, visual):
		visual.mesh = null
		return &"csg"
	return &"placeholder"


static func _fit_model_to_default_size(asset_root: Node3D, item_id: StringName) -> void:
	var mesh_nodes: Array[Node] = asset_root.find_children("*", "MeshInstance3D", true, false)
	var merged_bounds := AABB()
	var has_bounds: bool = false
	var root_inverse: Transform3D = asset_root.global_transform.affine_inverse()
	for node: Node in mesh_nodes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local_transform: Transform3D = root_inverse * mesh_instance.global_transform
		var mesh_bounds: AABB = _transform_aabb(mesh_instance.get_aabb(), local_transform)
		if mesh_bounds.size.x <= 0.0001 or mesh_bounds.size.y <= 0.0001 or mesh_bounds.size.z <= 0.0001:
			continue
		if has_bounds:
			merged_bounds = merged_bounds.merge(mesh_bounds)
		else:
			merged_bounds = mesh_bounds
			has_bounds = true

	if not has_bounds:
		push_warning("Item '%s' : boîte englobante du modèle vide, taille importée inchangée." % String(item_id))
		return

	var bounds_size: Vector3 = merged_bounds.size
	var normalization: Vector3 = Vector3(
		DEFAULT_SIZE.x / bounds_size.x,
		DEFAULT_SIZE.y / bounds_size.y,
		DEFAULT_SIZE.z / bounds_size.z
	)
	asset_root.scale = normalization
	asset_root.position = -merged_bounds.get_center() * normalization


static func _transform_aabb(bounds: AABB, transform: Transform3D) -> AABB:
	var transformed_bounds := AABB()
	var initialized: bool = false
	for x_index: int in range(2):
		for y_index: int in range(2):
			for z_index: int in range(2):
				var corner := bounds.position + Vector3(
					bounds.size.x * float(x_index),
					bounds.size.y * float(y_index),
					bounds.size.z * float(z_index)
				)
				var transformed_corner: Vector3 = transform * corner
				if initialized:
					transformed_bounds = transformed_bounds.expand(transformed_corner)
				else:
					transformed_bounds = AABB(transformed_corner, Vector3.ZERO)
					initialized = true
	return transformed_bounds


static func _set_item_orientation(item: Node3D, item_id: StringName) -> void:
	match item_id:
		&"hall_barometer", &"hall_mirror", &"hall_coat_rack":
			item.rotation_degrees.y = -90.0
		&"hall_key_board":
			item.rotation_degrees.y = 90.0


static func _add_umbrella_stand_accessories(visual: MeshInstance3D) -> void:
	var details := Node3D.new()
	details.name = "CSGDetails"
	visual.add_child(details)
	var metal := _standard_material(Color(0.12, 0.15, 0.16), 0.55, 0.55)
	var canopy := _standard_material(Color(0.42, 0.18, 0.14), 0.78)
	_add_box(details, "UmbrellaShaftLeft", Vector3(0.012, 0.34, 0.012), Vector3(-0.055, 0.03, 0.03), metal)
	_add_box(details, "UmbrellaShaftRight", Vector3(0.012, 0.30, 0.012), Vector3(0.055, 0.01, -0.025), metal)
	_add_sphere(details, "UmbrellaCanopyLeft", 0.075, Vector3(-0.055, 0.17, 0.03), canopy, Vector3(1.0, 0.52, 1.0))
	_add_sphere(details, "UmbrellaCanopyRight", 0.068, Vector3(0.055, 0.15, -0.025), metal, Vector3(1.0, 0.52, 1.0))
	_add_torus(details, "UmbrellaHandleLeft", 0.025, 0.045, Vector3(-0.055, -0.16, 0.03), Vector3(90.0, 0.0, 0.0), metal)
	_add_torus(details, "UmbrellaHandleRight", 0.022, 0.040, Vector3(0.055, -0.14, -0.025), Vector3(90.0, 0.0, 0.0), canopy)


static func _build_csg(item_id: StringName, visual: MeshInstance3D) -> bool:
	if not CSG_ITEM_IDS.has(item_id):
		return false
	var details := Node3D.new()
	details.name = "CSGVisual"
	visual.add_child(details)
	var wood := _standard_material(Color(0.27, 0.14, 0.075), 0.72)
	var dark_wood := _standard_material(Color(0.12, 0.075, 0.045), 0.84)
	var brass := _standard_material(Color(0.62, 0.39, 0.12), 0.28, 0.76)
	var ivory := _standard_material(Color(0.78, 0.69, 0.50), 0.68)
	var black := _standard_material(Color(0.045, 0.042, 0.036), 0.36, 0.18)

	match item_id:
		&"hall_barometer":
			_set_item_orientation(visual.get_parent() as Node3D, item_id)
			_add_box(details, "WalnutBackplate", Vector3(0.34, 0.42, 0.035), Vector3.ZERO, wood)
			_add_cylinder(details, "BrassBezel", 0.18, 0.026, Vector3(0.0, 0.0, 0.027), Vector3(90.0, 0.0, 0.0), brass)
			_add_cylinder(details, "IvoryDial", 0.15, 0.014, Vector3(0.0, 0.0, 0.047), Vector3(90.0, 0.0, 0.0), ivory)
			_add_torus(details, "DialRim", 0.142, 0.157, Vector3(0.0, 0.0, 0.060), Vector3(90.0, 0.0, 0.0), brass)
			for tick: int in range(8):
				var angle: float = TAU * float(tick) / 8.0
				var tick_position := Vector3(sin(angle) * 0.116, cos(angle) * 0.116, 0.066)
				_add_box(details, "DialTick_%02d" % tick, Vector3(0.009, 0.026, 0.006), tick_position, dark_wood, Vector3(0.0, 0.0, -rad_to_deg(angle)))
			_add_box(details, "Needle", Vector3(0.012, 0.105, 0.008), Vector3(0.012, 0.022, 0.068), _color_material(Color(0.55, 0.13, 0.08), 0.55), Vector3(0.0, 0.0, 18.0))
			_add_sphere(details, "NeedleHub", 0.022, Vector3(0.0, 0.0, 0.073), brass)
			return true

		&"hall_key_board":
			_set_item_orientation(visual.get_parent() as Node3D, item_id)
			_add_box(details, "KeyBoardPanel", Vector3(0.37, 0.43, 0.035), Vector3.ZERO, dark_wood)
			_add_box(details, "TopInlay", Vector3(0.27, 0.045, 0.012), Vector3(0.0, 0.16, 0.026), brass)
			_add_box(details, "LowerInlay", Vector3(0.27, 0.018, 0.012), Vector3(0.0, -0.17, 0.026), wood)
			for hook_index: int in range(5):
				var x: float = -0.12 + float(hook_index) * 0.06
				_add_cylinder(details, "HookStem_%02d" % hook_index, 0.012, 0.072, Vector3(x, 0.045, 0.048), Vector3(90.0, 0.0, 0.0), brass)
				_add_sphere(details, "HookTip_%02d" % hook_index, 0.018, Vector3(x, 0.045, 0.084), brass)
			for key_index: int in range(3):
				var x: float = -0.075 + float(key_index) * 0.075
				_add_torus(details, "KeyRing_%02d" % key_index, 0.022, 0.033, Vector3(x, -0.045, 0.055), Vector3(90.0, 0.0, 0.0), brass)
				_add_box(details, "KeyStem_%02d" % key_index, Vector3(0.012, 0.095, 0.012), Vector3(x, -0.115, 0.055), brass, Vector3(0.0, 0.0, float((key_index - 1) * 8)))
				_add_box(details, "KeyBit_%02d" % key_index, Vector3(0.035, 0.014, 0.012), Vector3(x + 0.012, -0.16, 0.055), brass)
			return true

		&"hall_doorbell":
			_set_item_orientation(visual.get_parent() as Node3D, item_id)
			_add_box(details, "DarkBellPlate", Vector3(0.18, 0.27, 0.035), Vector3.ZERO, black)
			_add_box(details, "BrassPlate", Vector3(0.14, 0.23, 0.012), Vector3(0.0, 0.0, 0.025), brass)
			_add_box(details, "BellLabel", Vector3(0.085, 0.048, 0.012), Vector3(0.0, 0.075, 0.036), ivory)
			_add_cylinder(details, "ButtonRim", 0.037, 0.016, Vector3(0.0, -0.045, 0.043), Vector3(90.0, 0.0, 0.0), dark_wood)
			_add_cylinder(details, "Button", 0.026, 0.018, Vector3(0.0, -0.045, 0.058), Vector3(90.0, 0.0, 0.0), ivory)
			_add_sphere(details, "ScrewUpper", 0.009, Vector3(0.0, 0.105, 0.035), black)
			_add_sphere(details, "ScrewLower", 0.009, Vector3(0.0, -0.105, 0.035), black)
			return true

		&"hall_hand_railing":
			var ghost := _standard_material(Color(0.69, 0.84, 0.82, 0.64), 0.42)
			ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ghost.emission_enabled = true
			ghost.emission = Color(0.22, 0.42, 0.39, 1.0)
			ghost.emission_energy_multiplier = 0.32
			_add_box(details, "GhostPalm", Vector3(0.18, 0.115, 0.08), Vector3(0.0, -0.045, 0.0), ghost)
			_add_box(details, "GhostFingerIndex", Vector3(0.034, 0.14, 0.072), Vector3(-0.066, 0.075, 0.0), ghost)
			_add_box(details, "GhostFingerMiddle", Vector3(0.034, 0.16, 0.072), Vector3(-0.022, 0.085, 0.0), ghost)
			_add_box(details, "GhostFingerRing", Vector3(0.034, 0.15, 0.072), Vector3(0.022, 0.08, 0.0), ghost)
			_add_box(details, "GhostFingerLittle", Vector3(0.034, 0.12, 0.072), Vector3(0.066, 0.065, 0.0), ghost)
			_add_box(details, "GhostThumb", Vector3(0.105, 0.042, 0.072), Vector3(-0.118, -0.04, 0.0), ghost, Vector3(0.0, 0.0, -36.0))
			_add_sphere(details, "GhostKnuckleIndex", 0.026, Vector3(-0.066, 0.01, 0.0), ghost)
			_add_sphere(details, "GhostKnuckleMiddle", 0.026, Vector3(-0.022, 0.015, 0.0), ghost)
			_add_sphere(details, "GhostKnuckleRing", 0.026, Vector3(0.022, 0.012, 0.0), ghost)
			return true

		&"hall_ring_1951":
			var gold := _standard_material(Color(0.62, 0.43, 0.16), 0.22, 0.82)
			var ruby := _standard_material(Color(0.48, 0.07, 0.08), 0.18, 0.18)
			_add_torus(details, "GoldWeddingBand", 0.15, 0.215, Vector3.ZERO, Vector3.ZERO, gold)
			_add_sphere(details, "RubySetting", 0.054, Vector3(0.0, 0.205, 0.0), gold)
			_add_sphere(details, "Ruby", 0.038, Vector3(0.0, 0.236, 0.0), ruby)
			return true

		&"kitchen_calendar":
			var calendar_header := _color_material(Color(0.53, 0.13, 0.10), 0.76)
			var calendar_grid := _color_material(Color(0.18, 0.15, 0.13), 0.82)
			_add_box(details, "CalendarBacking", Vector3(0.42, 0.46, 0.16), Vector3.ZERO, wood)
			_add_box(details, "CalendarPage", Vector3(0.38, 0.40, 0.018), Vector3(0.0, -0.02, 0.092), ivory)
			_add_box(details, "CalendarHeader", Vector3(0.37, 0.07, 0.012), Vector3(0.0, 0.145, 0.105), calendar_header)
			for ring_index: int in range(7):
				var ring_x: float = -0.15 + float(ring_index) * 0.05
				_add_torus(details, "CalendarBinding_%02d" % ring_index, 0.006, 0.012, Vector3(ring_x, 0.205, 0.115), Vector3.ZERO, brass)
			for line_index: int in range(6):
				var line_y: float = 0.08 - float(line_index) * 0.05
				_add_box(details, "CalendarGridH_%02d" % line_index, Vector3(0.32, 0.006, 0.008), Vector3(0.0, line_y, 0.114), calendar_grid)
			for line_index: int in range(8):
				var line_x: float = -0.15 + float(line_index) * 0.043
				_add_box(details, "CalendarGridV_%02d" % line_index, Vector3(0.006, 0.26, 0.008), Vector3(line_x, -0.045, 0.114), calendar_grid)
			return true

		_:
			details.queue_free()
			return false


static func _standard_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


static func _color_material(color: Color, roughness: float) -> StandardMaterial3D:
	return _standard_material(color, roughness)


static func _add_box(
	parent: Node3D,
	shape_name: String,
	size: Vector3,
	position: Vector3,
	material: Material,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> CSGBox3D:
	var shape := CSGBox3D.new()
	shape.name = shape_name
	shape.size = size
	shape.position = position
	shape.rotation_degrees = rotation_degrees
	shape.material = material
	shape.use_collision = false
	parent.add_child(shape)
	return shape


static func _add_cylinder(
	parent: Node3D,
	shape_name: String,
	radius: float,
	height: float,
	position: Vector3,
	rotation_degrees: Vector3,
	material: Material
) -> CSGCylinder3D:
	var shape := CSGCylinder3D.new()
	shape.name = shape_name
	shape.radius = radius
	shape.height = height
	shape.position = position
	shape.rotation_degrees = rotation_degrees
	shape.material = material
	shape.use_collision = false
	parent.add_child(shape)
	return shape


static func _add_sphere(
	parent: Node3D,
	shape_name: String,
	radius: float,
	position: Vector3,
	material: Material,
	stretch: Vector3 = Vector3.ONE
) -> CSGSphere3D:
	var shape := CSGSphere3D.new()
	shape.name = shape_name
	shape.radius = radius
	shape.position = position
	shape.scale = stretch
	shape.material = material
	shape.use_collision = false
	parent.add_child(shape)
	return shape


static func _add_torus(
	parent: Node3D,
	shape_name: String,
	inner_radius: float,
	outer_radius: float,
	position: Vector3,
	rotation_degrees: Vector3,
	material: Material
) -> CSGTorus3D:
	var shape := CSGTorus3D.new()
	shape.name = shape_name
	shape.inner_radius = inner_radius
	shape.outer_radius = outer_radius
	shape.sides = 24
	shape.ring_sides = 8
	shape.position = position
	shape.rotation_degrees = rotation_degrees
	shape.material = material
	shape.use_collision = false
	parent.add_child(shape)
	return shape
