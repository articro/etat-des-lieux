## menu_fog.gd — le brouillard du menu principal (U-6).
##
## Aucun asset externe : des dégradés radiaux **générés** (`GradientTexture2D`)
## qui dérivent lentement, plus deux halos chauds en bas de l'écran = les phares
## de la 205 garée dans la cour (GDD §10). Déplacements déterministes : le menu
## est identique d'un lancement à l'autre.
class_name MenuFog
extends Control

const BLOB_SIZE := 900.0
const DRIFT := 70.0
const FOG_COLOR := Color(0.60, 0.65, 0.72)
const FOG_ALPHA := 0.085
const LIGHT_COLOR := Color(0.96, 0.87, 0.66)
const LIGHT_ALPHA := 0.17
const LIGHT_SIZE := 520.0
const TEXTURE_SIZE := 256

## Positions relatives fixes (pas d'aléatoire).
const OFFSETS: Array[Vector2] = [
	Vector2(0.10, 0.66), Vector2(0.36, 0.40), Vector2(0.64, 0.72),
	Vector2(0.88, 0.36), Vector2(0.22, 0.20), Vector2(0.56, 0.10),
]
const SPEEDS: Array[float] = [0.051, -0.037, 0.043, -0.029, 0.033, -0.046]

var _blobs: Array[TextureRect] = []
var _lights: Array[TextureRect] = []
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fog := _radial(FOG_COLOR, FOG_ALPHA)
	var light := _radial(LIGHT_COLOR, LIGHT_ALPHA)
	for i: int in OFFSETS.size():
		_blobs.append(_make_sprite(fog, BLOB_SIZE))
	_lights.append(_make_sprite(light, LIGHT_SIZE))
	_lights.append(_make_sprite(light, LIGHT_SIZE))


func _process(delta: float) -> void:
	_time += delta
	var area := size
	if area.x <= 1.0:
		return
	for i: int in _blobs.size():
		var blob := _blobs[i]
		var base := Vector2(OFFSETS[i].x * area.x, OFFSETS[i].y * area.y)
		var phase := _time * SPEEDS[i] + float(i)
		blob.position = base + Vector2(sin(phase), cos(phase * 0.7)) * DRIFT - blob.size * 0.5
	if _lights.size() >= 2:
		_lights[0].position = Vector2(area.x * 0.30, area.y * 0.94) - _lights[0].size * 0.5
		_lights[1].position = Vector2(area.x * 0.44, area.y * 0.95) - _lights[1].size * 0.5
		var flicker := 0.9 + sin(_time * 1.7) * 0.05
		_lights[0].modulate.a = flicker
		_lights[1].modulate.a = flicker


func _make_sprite(texture: GradientTexture2D, blob_size: float) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.custom_minimum_size = Vector2(blob_size, blob_size)
	sprite.size = Vector2(blob_size, blob_size)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprite)
	return sprite


func _radial(color: Color, alpha: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	var inner := color
	inner.a = alpha
	var outer := color
	outer.a = 0.0
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([inner, inner * Color(1, 1, 1, 0.45), outer])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	return texture
