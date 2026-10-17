## AudioManager — Propriétaire : Audio. STUB M0 (tâche D-1). API fixée ARCHITECTURE §5.
extends Node


func play_sfx(sfx_id: StringName, _position: Vector3 = Vector3.INF, _volume_db: float = 0.0) -> void:
	push_warning("AudioManager.play_sfx non implémenté : %s" % sfx_id)


func play_ui(sfx_id: StringName) -> void:
	push_warning("AudioManager.play_ui non implémenté : %s" % sfx_id)


func set_layer(layer_id: StringName, _intensity: float, _fade: float = 2.0) -> void:
	push_warning("AudioManager.set_layer non implémenté : %s" % layer_id)


func play_music(track_id: StringName, _fade_in: float = 3.0) -> void:
	push_warning("AudioManager.play_music non implémenté : %s" % track_id)


func stop_music(_fade_out: float = 3.0) -> void:
	pass
