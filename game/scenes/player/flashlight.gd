## flashlight.gd — lampe de poche faible (G-6).
##
## GDD §4.5 : éclairage de secours, faisceau étroit, piles infinies.
## Le flash reste la vraie lumière. Aucun texte affiché.
class_name Flashlight
extends SpotLight3D


func _ready() -> void:
	visible = false
	light_energy = 2.4
	spot_range = 9.0
	spot_angle = 24.0
	spot_angle_attenuation = 1.1
	light_color = Color(1.0, 0.93, 0.78)
	shadow_enabled = true


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
