## Outil de capture : rend house.tscn depuis des points de vue et écrit des PNG.
## Usage (via tools/shots.sh) :
##   godot --path game --rendering-driver vulkan --resolution 1280x720 --script res://tools/shot.gd -- out_dir [spot,...]
## Spots définis dans tools/shots.json : { "nom": {"pos":[x,y,z], "look":[x,y,z]} }
extends SceneTree

const HOUSE := "res://scenes/house/house.tscn"
const SPOTS_FILE := "res://tools/shots.json"
const WAIT_FRAMES := 12

var _out_dir := "/tmp/shots"
var _spots: Dictionary = {}
var _only: PackedStringArray = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out_dir = args[0]
	if args.size() >= 2 and args[1].strip_edges() != "":
		_only = args[1].split(",")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var f := FileAccess.open(SPOTS_FILE, FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_spots = parsed
	call_deferred("_run")


func _run() -> void:
	var house: Node = (load(HOUSE) as PackedScene).instantiate()
	root.add_child(house)
	var cam := Camera3D.new()
	cam.fov = 75.0
	cam.near = 0.05
	root.add_child(cam)
	cam.current = true
	# Lampe de poche simulée (le joueur en a une) pour que les captures soient lisibles.
	var torch := SpotLight3D.new()
	torch.spot_angle = 24.0
	torch.spot_range = 9.0
	torch.light_energy = 2.4
	torch.light_color = Color(1.0, 0.93, 0.8)
	cam.add_child(torch)
	for i in WAIT_FRAMES:
		await process_frame
	var names := _spots.keys()
	if _only.size() > 0:
		names = Array(_only)
	for name: String in names:
		if not _spots.has(name):
			push_warning("shot : spot inconnu %s" % name)
			continue
		var spot: Dictionary = _spots[name]
		var pos := _v3(spot.get("pos", [0, 1.6, 0]))
		var look := _v3(spot.get("look", [0, 1.4, 1]))
		cam.global_position = pos
		cam.look_at(look, Vector3.UP)
		for i in WAIT_FRAMES:
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [_out_dir, name]
		img.save_png(path)
		print("shot : %s" % path)
	quit(0)


func _v3(a: Variant) -> Vector3:
	var arr: Array = a
	return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
