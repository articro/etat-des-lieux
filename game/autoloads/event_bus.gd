## EventBus — contrat central de communication entre modules.
## Voir docs/ARCHITECTURE.md §4. NE PAS MODIFIER sans demande à l'Architecte.
extends Node

# --- Joueur / Caméra (émis par Gameplay) ---
signal photo_taken(photo: PhotoData)
signal photo_developed(photo: PhotoData)
signal flash_fired(world_position: Vector3, room_id: StringName)
signal player_entered_room(room_id: StringName)
signal player_left_room(room_id: StringName)
signal player_interacted(target_id: StringName, kind: StringName)
signal player_caught()
signal player_noise(level: float, world_position: Vector3)
signal interact_target_changed(target_id: StringName, kind: StringName)   # cible sous le réticule (vide = aucune)

# --- Inventaire (émis par InventoryManager) ---
signal item_checked(item_id: StringName, photo: PhotoData)
signal item_revealed(item_id: StringName)
signal inventory_progress(checked: int, total: int)
signal inventory_line_added(line_index: int, text_key: StringName)

# --- Maison (émis par HouseDirector) ---
signal house_attention_changed(value: float)
signal item_moved(item_id: StringName, from_room: StringName, to_room: StringName, new_anchor: StringName)
signal house_event_triggered(event_id: StringName)
signal presence_state_changed(state: StringName)
signal act_changed(act: int)

# --- Narration / Documents ---
signal document_found(doc_id: StringName)
signal document_read(doc_id: StringName)
signal ending_reached(ending_id: StringName)

# --- UI ---
signal notebook_opened()
signal notebook_closed()
signal pause_toggled(paused: bool)
signal subtitle_requested(text_key: StringName, duration: float)
signal settings_changed(key: StringName, value: Variant)   # émis par UI (options) ; écouté par Player, AudioManager…

# --- Sauvegarde ---
signal save_requested()
signal game_loaded()
