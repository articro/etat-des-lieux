## photo_in_hand.gd — la photo qui sort de l'appareil et se développe (G-5).
##
## Quad child de PhotoHold (sous la caméra). Le shader `photo_develop.gdshader`
## révèle l'image en `develop_time` secondes (10 s par défaut, cf. GDD §4.1).
## Le signal photo_developed est émis par PhotoDevice, pas ici.
class_name PhotoInHand
extends MeshInstance3D

const RAISE_DISTANCE: float = 0.12
const RAISE_TIME: float = 0.25

var _photo: PhotoData = null
var _duration: float = 1.0
var _elapsed: float = 0.0
var _rest_position: Vector3 = Vector3.ZERO
var _material: ShaderMaterial = null


func _ready() -> void:
	_material = material_override as ShaderMaterial
	_rest_position = position
	visible = false
	set_process(false)


## Affiche une nouvelle photo et lance son développement visuel.
func show_photo(photo: PhotoData, duration: float) -> void:
	if photo == null:
		return
	_photo = photo
	_duration = maxf(duration, 0.001)
	_elapsed = 0.0
	visible = true
	set_process(not photo.developed)
	_apply_material(0.0 if not photo.developed else 1.0)
	position = _rest_position - Vector3(0.0, RAISE_DISTANCE, 0.0)
	var tween := create_tween()
	tween.tween_property(self, "position", _rest_position, RAISE_TIME).set_ease(Tween.EASE_OUT)


## Masque la photo quand l'appareil est levé (on ne tient pas les deux).
func set_suppressed(suppressed: bool) -> void:
	visible = not suppressed and _photo != null


func has_photo() -> bool:
	return _photo != null


func _process(delta: float) -> void:
	if _photo == null:
		set_process(false)
		return
	if _photo.developed:
		_apply_material(1.0)
		set_process(false)
		return
	_elapsed += delta
	_apply_material(clampf(_elapsed / _duration, 0.0, 1.0))


func _apply_material(value: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter(&"development", value)
	if _photo != null:
		_material.set_shader_parameter(&"photo_tex", _photo.texture)
		_material.set_shader_parameter(&"has_texture", _photo.texture != null)
