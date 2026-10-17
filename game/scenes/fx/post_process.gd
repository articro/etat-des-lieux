## post_process.gd — réglages du post-process d'écran (G-7). Module Gameplay.
##
## Grain de pellicule, vignette, aberration chromatique légère (GDD §8).
## Instancié une seule fois, par le joueur ; l'Architecte/Niveau ne doit pas en
## ajouter un second (deux instances = deux fois le grain). Voir TASKS.md.
class_name PostProcess
extends CanvasLayer

@export_range(0.0, 1.0) var vignette_strength: float = 0.65
@export_range(0.0, 0.2) var grain_strength: float = 0.05
@export_range(0.0, 0.01) var aberration: float = 0.0016
@export_range(0.0, 1.0) var darkness: float = 0.97

@onready var _screen: ColorRect = $Screen


func _ready() -> void:
	apply_settings()


## Applique les réglages exportés au matériau (appelable depuis les options UI).
func apply_settings() -> void:
	if _screen == null:
		return
	var material := _screen.material as ShaderMaterial
	if material == null:
		push_warning("PostProcess : matériau de shader absent — effet désactivé.")
		return
	material.set_shader_parameter(&"vignette_strength", vignette_strength)
	material.set_shader_parameter(&"grain_strength", grain_strength)
	material.set_shader_parameter(&"aberration", aberration)
	material.set_shader_parameter(&"darkness", darkness)
