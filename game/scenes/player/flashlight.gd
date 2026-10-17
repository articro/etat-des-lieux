## flashlight.gd — lampe de poche faible (G-6).
##
## GDD §4.5 : éclairage de secours, faisceau étroit, piles infinies.
## Le flash reste la vraie lumière. Aucun texte affiché.
class_name Flashlight
extends SpotLight3D

# Mode normal (GDD §4.5) et mode « lampe plus forte » (option d'accessibilité,
# GDD §10, clé de réglage `flashlight_strong`).
const ENERGY_WEAK: float = 2.4
const ENERGY_STRONG: float = 4.6
const RANGE_WEAK: float = 9.0
const RANGE_STRONG: float = 13.0
const ANGLE_WEAK: float = 24.0
const ANGLE_STRONG: float = 30.0

var _strong: bool = false


func _ready() -> void:
	visible = false
	spot_angle_attenuation = 1.1
	light_color = Color(1.0, 0.93, 0.78)
	shadow_enabled = true
	_apply_profile()


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed(&"flashlight"):
		toggle()


## Bascule la lampe. Publique pour les tests.
func toggle() -> void:
	visible = not visible
	AudioManager.play_ui(&"flashlight_click")


func is_on() -> bool:
	return visible


## Mode « lampe plus forte » (option d'accessibilité). Ne change pas l'état
## allumé/éteint : seulement l'énergie, la portée et l'ouverture du faisceau.
func set_strong(strong: bool) -> void:
	if _strong == strong:
		return
	_strong = strong
	_apply_profile()


func is_strong() -> bool:
	return _strong


func _apply_profile() -> void:
	light_energy = ENERGY_STRONG if _strong else ENERGY_WEAK
	spot_range = RANGE_STRONG if _strong else RANGE_WEAK
	spot_angle = ANGLE_STRONG if _strong else ANGLE_WEAK
