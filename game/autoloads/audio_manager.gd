## AudioManager — Propriétaire : module Audio. API fixée par ARCHITECTURE.md §5.
##
## Responsabilités (tâches D-1 à D-8) :
##   - création des bus Master / SFX / Ambiance / Music / UI **par code** (pas de
##     default_bus_layout.tres : ce fichier appartiendrait à l'Architecte) ;
##   - one-shots 2D (play_ui) et 2D/3D (play_sfx) depuis un registre d'ids ;
##   - soundscape en couches (set_layer) piloté par house_attention_changed ;
##   - musique avec fondu enchaîné (play_music / stop_music) ;
##   - écoute passive de l'EventBus : pas, appareil photo, Présence, fins, options.
##
## Dégradation : un id inconnu, un fichier absent ou un bus manquant ne doit
## JAMAIS faire planter le jeu -> push_warning (une seule fois par id) + silence.
##
## Voir docs/audio_conventions.md : liste des ids, convention metadata `surface`,
## placement 3D des sons « venus d'ailleurs », courbes d'intensité.

extends Node

# -------------------------------------------------------------------- bus
const BUS_MASTER: StringName = &"Master"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIANCE: StringName = &"Ambiance"
const BUS_MUSIC: StringName = &"Music"
const BUS_UI: StringName = &"UI"

const AUDIO_DIR: String = "res://assets/audio/"

# -------------------------------------------------------------- réglages
const POOL_2D_SIZE: int = 16
const POOL_3D_SIZE: int = 12
const SILENCE_DB: float = -80.0            # volume considéré comme inaudible
const MUSIC_FLOOR_DB: float = -70.0
const CUTOFF_OPEN: float = 20500.0         # low-pass Master « ouvert »
const CUTOFF_PAUSED: float = 900.0
const CUTOFF_CAUGHT: float = 420.0
const DUCK_PAUSE_DB: float = -8.0
const DUCK_CAUGHT_DB: float = -14.0

# Pas : seuils de EventBus.player_noise (convention documentée par Gameplay :
# 0,25 = marche, 0,85 = course).
const STEP_RUN_LEVEL: float = 0.6
const STEP_MIN_INTERVAL: float = 0.11      # anti-mitraille
const BAG_EVERY_MIN: int = 5               # bruit de sac toutes les N pas
const BAG_EVERY_MAX: int = 8

# Souffle : intervalle entre deux respirations selon l'attention (0..100).
const BREATH_CALM_INTERVAL: float = 5.4
const BREATH_DREAD_INTERVAL: float = 2.7

# Ticks de maison : intervalle aléatoire selon l'attention (0..100).
const TICK_CALM_MIN: float = 14.0
const TICK_CALM_MAX: float = 26.0
const TICK_DREAD_MIN: float = 5.0
const TICK_DREAD_MAX: float = 11.0

## Ids joués aléatoirement pour les craquements de la maison.
const HOUSE_TICK_IDS: Array[StringName] = [
	&"house_creak_01", &"house_creak_02", &"house_creak_03",
	&"house_pipe_01", &"house_pipe_02",
]

## Matériau par défaut quand le rayon ne trouve pas de metadata `surface`.
const SURFACE_FALLBACK_BY_ROOM: Dictionary = {
	&"exterior": &"gravel",
	&"cellar": &"stone",
	&"hall": &"tile",
	&"kitchen": &"tile",
	&"living": &"carpet",
	&"study": &"wood",
}

# ------------------------------------------------------------------- état
## id -> Dictionary { paths: Array[String], bus, db, pitch, rand, gain_rand,
##                    spatial, unit_size, max_distance }
var _register: Dictionary = {}
## couches -> Dictionary { path, bus, db } (boucles, pilotées par set_layer)
var _layer_register: Dictionary = {}
## Sons « venus d'ailleurs » : décalage 3D appliqué à la position du joueur.
var _spatial_hints: Dictionary = {}

var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _cursor_2d: int = 0
var _cursor_3d: int = 0
var _streams: Dictionary = {}               # path -> AudioStream (cache)
var _missing: Dictionary = {}               # id -> true (warning déjà émis)
var _tweens: Dictionary = {}                # Object -> Tween
var _last_played_at: Dictionary = {}        # StringName -> temps (s)

var _layers: Dictionary = {}                # StringName -> AudioStreamPlayer
var _layer_target: Dictionary = {}          # StringName -> float (0..1)
var _layer_tweens: Dictionary = {}          # StringName -> Tween

var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _music_id: StringName = &""
var _charge_player: AudioStreamPlayer = null  # sifflement de charge du flash

var _master_lp: AudioEffectLowPassFilter = null
var _duck_db: float = 0.0

var _vol_master: float = 1.0
var _vol_sfx: float = 1.0
var _vol_music: float = 1.0

var _attention: float = 0.0                 # 0..100 (reflet house_attention_changed)
var _last_player_pos: Vector3 = Vector3.INF
var _last_step_time: float = -1.0
var _step_count: int = 0
var _next_bag_in: int = 6
var _step_side: bool = false                # pied gauche / droite
var _surface: StringName = &"wood"
var _current_room: StringName = &""
var _camera_up: bool = false
var _shots_pending: int = 0
var _breath_in: bool = true
var _breath_timer: float = 0.0
var _tick_timer: float = 0.0
var _started: bool = false


# --------------------------------------------------------------- autoload

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # le son continue en pause
	_build_registers()
	_setup_buses()
	_setup_effects()
	_setup_players()
	_connect_event_bus()
	_apply_volumes()


## En quittant, on rend tous les flux : sinon Godot signalera « resources
## still in use at exit » et `tools/check.sh` échouera pour tout le monde.
func _exit_tree() -> void:
	for p in _pool_2d:
		p.stop()
		p.stream = null
	for p in _pool_3d:
		p.stop()
		p.stream = null
	for layer_id in _layers:
		var layer: AudioStreamPlayer = _layers[layer_id]
		if layer != null:
			layer.stop()
			layer.stream = null
	for p in [_music_a, _music_b, _charge_player]:
		var player: AudioStreamPlayer = p
		if player != null:
			player.stop()
			player.stream = null
	_streams.clear()


func _connect_event_bus() -> void:
	if EventBus == null:
		push_warning("AudioManager : EventBus absent, aucun son piloté par le jeu.")
		return
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.player_noise.connect(_on_player_noise)
	EventBus.player_entered_room.connect(_on_player_entered_room)
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.player_caught.connect(_on_player_caught)
	EventBus.house_attention_changed.connect(_on_house_attention_changed)
	EventBus.presence_state_changed.connect(_on_presence_state_changed)
	EventBus.flash_fired.connect(_on_flash_fired)
	EventBus.photo_taken.connect(_on_photo_taken)
	EventBus.photo_developed.connect(_on_photo_developed)
	EventBus.item_checked.connect(_on_item_checked)
	EventBus.notebook_opened.connect(_on_notebook_opened)
	EventBus.notebook_closed.connect(_on_notebook_closed)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.ending_reached.connect(_on_ending_reached)


# =============================================================================
# API PUBLIQUE (ARCHITECTURE §5 — signatures figées)
# =============================================================================

## Joue un one-shot. `position = Vector3.INF` (défaut) -> 2D, sinon 3D.
func play_sfx(sfx_id: StringName, position: Vector3 = Vector3.INF, volume_db: float = 0.0) -> void:
	var entry: Dictionary = _register.get(sfx_id, {})
	if entry.is_empty():
		_warn_missing(sfx_id)
		return
	var stream: AudioStream = _pick_stream(entry)
	if stream == null:
		return
	var at: Vector3 = position
	if at == Vector3.INF and _spatial_hints.has(sfx_id) and _last_player_pos != Vector3.INF:
		at = _last_player_pos + _spatial_hints[sfx_id]
	var db: float = entry.get("db", 0.0) + volume_db + _rand_gain(entry)
	var pitch: float = _rand_pitch(entry)
	if entry.get("spatial", true) and at != Vector3.INF:
		_play_3d(entry, stream, at, db, pitch)
	else:
		_play_2d(entry, stream, db, pitch)


## Joue un one-shot d'interface — ou un son « dans les mains » (appareil photo).
func play_ui(sfx_id: StringName) -> void:
	if sfx_id == &"camera_raise":
		_toggle_camera()          # un seul id pour lever et baisser
		return
	var entry: Dictionary = _register.get(sfx_id, {})
	if entry.is_empty():
		_warn_missing(sfx_id)
		return
	var stream: AudioStream = _pick_stream(entry)
	if stream == null:
		return
	_mark_played(sfx_id)
	_play_2d(entry, stream, entry.get("db", 0.0) + _rand_gain(entry), _rand_pitch(entry))


## Règle l'intensité (0..1) d'une couche de soundscape, avec fondu.
func set_layer(layer_id: StringName, intensity: float, fade: float = 2.0) -> void:
	if not _layer_register.has(layer_id):
		_warn_missing(layer_id)
		return
	var target: float = clampf(intensity, 0.0, 1.0)
	_layer_target[layer_id] = target
	var player: AudioStreamPlayer = _ensure_layer(layer_id)
	if player == null:
		return
	var entry: Dictionary = _layer_register[layer_id]
	var target_db: float = SILENCE_DB
	if target > 0.001:
		target_db = float(entry.get("db", 0.0)) + linear_to_db(maxf(target, 0.0001))
		if not player.playing:
			player.volume_db = SILENCE_DB
			player.play()
	var old: Tween = _layer_tweens.get(layer_id)
	if old != null and old.is_valid():
		old.kill()
	if fade <= 0.0:
		player.volume_db = target_db
		if target <= 0.001:
			player.stop()
		return
	var tw := create_tween()
	_layer_tweens[layer_id] = tw
	tw.tween_property(player, "volume_db", target_db, fade).set_trans(Tween.TRANS_SINE)
	if target <= 0.001:
		tw.tween_callback(player.stop)


## Lance une musique (fondu enchaîné si une autre est déjà en cours).
func play_music(track_id: StringName, fade_in: float = 3.0) -> void:
	var entry: Dictionary = _register.get(track_id, {})
	var paths: Array = entry.get("paths", [])
	var stream: AudioStream = null
	if paths.is_empty():
		# id non déclaré : on tente le chemin standard music/<id>.ogg.
		var guess: String = "music/%s.ogg" % track_id
		if not ResourceLoader.exists(AUDIO_DIR + guess):
			_warn_missing(track_id)
			return
		stream = _get_stream(guess)
	else:
		stream = _pick_stream(entry)
	if stream == null:
		_warn_missing(track_id)
		return
	if _music_id == track_id and (_music_a.playing or _music_b.playing):
		return
	var incoming: AudioStreamPlayer = _music_b if _music_a.playing else _music_a
	var outgoing: AudioStreamPlayer = _music_a if incoming == _music_b else _music_b
	incoming.stream = stream
	incoming.volume_db = MUSIC_FLOOR_DB
	incoming.play()
	_tween_player_volume(incoming, float(entry.get("db", 0.0)), maxf(fade_in, 0.05))
	if outgoing.playing:
		var tw := create_tween()
		tw.tween_property(outgoing, "volume_db", MUSIC_FLOOR_DB, maxf(fade_in, 0.05))
		tw.tween_callback(outgoing.stop)
	_music_id = track_id


## Arrête la musique avec fondu.
func stop_music(fade_out: float = 3.0) -> void:
	_music_id = &""
	for player in [_music_a, _music_b]:
		var p: AudioStreamPlayer = player
		if p == null or not p.playing:
			continue
		var tw := create_tween()
		tw.tween_property(p, "volume_db", MUSIC_FLOOR_DB, maxf(fade_out, 0.05))
		tw.tween_callback(p.stop)


# =============================================================================
# API COMPLÉMENTAIRE (lecture seule — utile aux tests et au debug)
# =============================================================================

## Dernier matériau détecté sous le joueur (convention metadata `surface`).
func current_surface() -> StringName:
	return _surface


## Dernière position connue du joueur (Vector3.INF si aucune).
func last_player_position() -> Vector3:
	return _last_player_pos


## Intensité courante d'une couche (0..1).
func layer_intensity(layer_id: StringName) -> float:
	return float(_layer_target.get(layer_id, 0.0))


## Volume d'un bus en dB (Master, SFX, Music…). -80 si le bus n'existe pas.
func bus_volume_db(bus_name: StringName) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return SILENCE_DB
	return AudioServer.get_bus_volume_db(idx)


## Tous les ids connus de l'AudioManager (sfx, musiques puis couches).
## Sert aux tests et à tools/validate_data.gd (tâche Q-2).
func sfx_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key in _register.keys():
		out.append(StringName(key))
	for key in _layer_register.keys():
		out.append(StringName(key))
	return out


## Vrai si l'id est connu ET qu'au moins un de ses fichiers existe.
func sfx_is_available(sfx_id: StringName) -> bool:
	if _layer_register.has(sfx_id):
		return ResourceLoader.exists(AUDIO_DIR + str(_layer_register[sfx_id].get("path", "")))
	var entry: Dictionary = _register.get(sfx_id, {})
	if entry.is_empty():
		return false
	for path in entry.get("paths", []):
		if ResourceLoader.exists(AUDIO_DIR + str(path)):
			return true
	return false


## Durée en secondes du premier fichier de l'id (0 si introuvable).
func sfx_duration(sfx_id: StringName) -> float:
	var path: String = ""
	if _layer_register.has(sfx_id):
		path = str(_layer_register[sfx_id].get("path", ""))
	else:
		var entry: Dictionary = _register.get(sfx_id, {})
		var paths: Array = entry.get("paths", [])
		if not paths.is_empty():
			path = str(paths[0])
	if path == "":
		return 0.0
	if not ResourceLoader.exists(AUDIO_DIR + path):
		return 0.0
	var stream: AudioStream = _get_stream(path)
	if stream == null:
		return 0.0
	return stream.get_length()


# ---------------------------------------------------------- sauvegarde (§9)
func to_save_dict() -> Dictionary:
	return {
		"vol_master": _vol_master,
		"vol_sfx": _vol_sfx,
		"vol_music": _vol_music,
	}


func from_save_dict(d: Dictionary) -> void:
	_vol_master = float(d.get("vol_master", _vol_master))
	_vol_sfx = float(d.get("vol_sfx", _vol_sfx))
	_vol_music = float(d.get("vol_music", _vol_music))
	_apply_volumes()


# =============================================================================
# GRAPHE AUDIO
# =============================================================================

func _setup_buses() -> void:
	# Un bus ne peut envoyer que vers un bus déjà créé : ordre important.
	_ensure_bus(BUS_SFX, BUS_MASTER)
	_ensure_bus(BUS_MUSIC, BUS_MASTER)
	_ensure_bus(BUS_AMBIANCE, BUS_SFX)      # le curseur SFX couvre l'ambiance
	_ensure_bus(BUS_UI, BUS_SFX)            # et les sons de l'appareil photo


func _ensure_bus(name_id: StringName, send_to: StringName) -> int:
	var idx: int = AudioServer.get_bus_index(name_id)
	if idx >= 0:
		return idx
	var at: int = AudioServer.bus_count
	AudioServer.add_bus(at)
	AudioServer.set_bus_name(at, name_id)
	AudioServer.set_bus_send(at, send_to)
	return AudioServer.get_bus_index(name_id)


func _setup_effects() -> void:
	# Low-pass sur le Master : ouvert par défaut, refermé en pause et au contact
	# de la Présence (ouïe étouffée). Jamais de saut de volume brutal.
	if _master_lp != null:
		return
	_master_lp = AudioEffectLowPassFilter.new()
	_master_lp.cutoff_hz = CUTOFF_OPEN
	_master_lp.resonance = 0.7
	AudioServer.add_bus_effect(0, _master_lp, 0)


func _setup_players() -> void:
	for i in POOL_2D_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx2D_%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_pool_2d.append(p)
	for i in POOL_3D_SIZE:
		var q := AudioStreamPlayer3D.new()
		q.name = "Sfx3D_%d" % i
		q.bus = BUS_SFX
		q.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		q.unit_size = 10.0
		q.max_distance = 32.0
		add_child(q)
		_pool_3d.append(q)
	_charge_player = AudioStreamPlayer.new()
	_charge_player.name = "CameraCharge"
	_charge_player.bus = BUS_UI
	add_child(_charge_player)
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.bus = BUS_MUSIC
	_music_a.volume_db = MUSIC_FLOOR_DB
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.bus = BUS_MUSIC
	_music_b.volume_db = MUSIC_FLOOR_DB
	add_child(_music_b)


func _apply_volumes() -> void:
	_set_bus_db(BUS_MASTER, linear_to_db(maxf(_vol_master, 0.0001)))
	_set_bus_db(BUS_SFX, linear_to_db(maxf(_vol_sfx, 0.0001)) + _duck_db)
	_set_bus_db(BUS_MUSIC, linear_to_db(maxf(_vol_music, 0.0001)) + _duck_db)


func _set_bus_db(bus_name: StringName, db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, db)


func _set_cutoff(hz: float, time: float) -> void:
	if _master_lp == null:
		return
	if time <= 0.0:
		_master_lp.cutoff_hz = hz
		return
	var tw := create_tween()
	tw.tween_property(_master_lp, "cutoff_hz", hz, time).set_trans(Tween.TRANS_SINE)


# =============================================================================
# LECTURE
# =============================================================================

func _pick_stream(entry: Dictionary) -> AudioStream:
	var paths: Array = entry.get("paths", [])
	if paths.is_empty():
		return null
	var path: String = paths[randi() % paths.size()]
	return _get_stream(path)


func _get_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var full: String = AUDIO_DIR + path
	if not ResourceLoader.exists(full):
		_streams[path] = null
		push_warning("AudioManager : asset audio absent res://assets/audio/%s" % path)
		return null
	var stream: AudioStream = load(full)
	_streams[path] = stream
	return stream


func _mark_played(sfx_id: StringName) -> void:
	_last_played_at[sfx_id] = Time.get_ticks_msec() / 1000.0


func _recently_played(sfx_id: StringName, window: float) -> bool:
	if not _last_played_at.has(sfx_id):
		return false
	return (Time.get_ticks_msec() / 1000.0) - float(_last_played_at[sfx_id]) < window


func _take_2d() -> AudioStreamPlayer:
	for i in _pool_2d.size():
		var idx: int = (_cursor_2d + i) % _pool_2d.size()
		var p: AudioStreamPlayer = _pool_2d[idx]
		if not p.playing:
			_cursor_2d = (idx + 1) % _pool_2d.size()
			return p
	var forced: AudioStreamPlayer = _pool_2d[_cursor_2d]
	_cursor_2d = (_cursor_2d + 1) % _pool_2d.size()
	return forced


func _take_3d() -> AudioStreamPlayer3D:
	for i in _pool_3d.size():
		var idx: int = (_cursor_3d + i) % _pool_3d.size()
		var p: AudioStreamPlayer3D = _pool_3d[idx]
		if not p.playing:
			_cursor_3d = (idx + 1) % _pool_3d.size()
			return p
	var forced: AudioStreamPlayer3D = _pool_3d[_cursor_3d]
	_cursor_3d = (_cursor_3d + 1) % _pool_3d.size()
	return forced


func _play_2d(entry: Dictionary, stream: AudioStream, db: float, pitch: float) -> void:
	var p: AudioStreamPlayer = _take_2d()
	p.bus = entry.get("bus", BUS_SFX)
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


func _play_3d(entry: Dictionary, stream: AudioStream, position: Vector3, db: float, pitch: float) -> void:
	var p: AudioStreamPlayer3D = _take_3d()
	p.bus = entry.get("bus", BUS_SFX)
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = db
	p.unit_size = entry.get("unit_size", 10.0)
	p.max_distance = entry.get("max_distance", 32.0)
	p.global_position = position
	p.play()


func _rand_pitch(entry: Dictionary) -> float:
	var base: float = entry.get("pitch", 1.0)
	var rand: float = entry.get("rand", 0.0)
	if rand <= 0.0:
		return base
	return clampf(base * (1.0 + randf_range(-rand, rand)), 0.2, 4.0)


func _rand_gain(entry: Dictionary) -> float:
	var rand: float = entry.get("gain_rand", 0.0)
	if rand <= 0.0:
		return 0.0
	return randf_range(-rand, rand)


func _tween_player_volume(player: AudioStreamPlayer, target_db: float, fade: float) -> void:
	var old: Tween = _tweens.get(player)
	if old != null and old.is_valid():
		old.kill()
	if fade <= 0.0:
		player.volume_db = target_db
		return
	var tw := create_tween()
	_tweens[player] = tw
	tw.tween_property(player, "volume_db", target_db, fade).set_trans(Tween.TRANS_SINE)


func _warn_missing(sfx_id: StringName) -> void:
	if _missing.has(sfx_id):
		return
	_missing[sfx_id] = true
	push_warning("AudioManager : id audio inconnu ou sans asset '%s' (silence)." % sfx_id)


# =============================================================================
# COUCHES (soundscape)
# =============================================================================

func _ensure_layer(layer_id: StringName) -> AudioStreamPlayer:
	if _layers.has(layer_id):
		return _layers[layer_id]
	var entry: Dictionary = _layer_register[layer_id]
	var stream: AudioStream = _get_stream(entry.get("path", ""))
	if stream == null:
		_warn_missing(layer_id)
		return null
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var player := AudioStreamPlayer.new()
	player.name = "Layer_%s" % layer_id
	player.bus = entry.get("bus", BUS_AMBIANCE)
	player.stream = stream
	player.volume_db = SILENCE_DB
	add_child(player)
	_layers[layer_id] = player
	return player


func _start_ambience() -> void:
	_started = true
	set_layer(&"house_base", 1.0, 4.0)
	set_layer(&"house_unease", 0.0, 0.0)
	set_layer(&"house_dread", 0.0, 0.0)
	set_layer(&"exterior", 0.0, 0.0)
	set_layer(&"presence", 0.0, 0.0)
	_breath_timer = BREATH_CALM_INTERVAL * randf()
	_tick_timer = randf_range(TICK_CALM_MIN, TICK_CALM_MAX)


# =============================================================================
# ÉVÉNEMENTS DU JEU
# =============================================================================

func _on_settings_changed(key: StringName, value: Variant) -> void:
	match key:
		&"volume_master":
			_vol_master = clampf(float(value), 0.0, 1.0)
		&"volume_sfx":
			_vol_sfx = clampf(float(value), 0.0, 1.0)
		&"volume_music":
			_vol_music = clampf(float(value), 0.0, 1.0)
		&"volume_ambiance":
			pass      # l'ambiance suit le curseur SFX (voir conventions)
		_:
			return
	_apply_volumes()


func _on_pause_toggled(paused: bool) -> void:
	_duck_db = DUCK_PAUSE_DB if paused else 0.0
	_apply_volumes()
	_set_cutoff(CUTOFF_PAUSED if paused else CUTOFF_OPEN, 0.25)


## Pas : Gameplay émet player_noise(level, world_position) — 0,25 marche,
## 0,85 course. Le matériau vient d'un rayon vers le bas + metadata `surface`.
func _on_player_noise(level: float, world_position: Vector3) -> void:
	if world_position != Vector3.INF:
		_last_player_pos = world_position
	var now: float = Time.get_ticks_msec() / 1000.0
	if _last_step_time > 0.0 and now - _last_step_time < STEP_MIN_INTERVAL:
		return
	_last_step_time = now
	_surface = _surface_at(_last_player_pos)
	var running: bool = level >= STEP_RUN_LEVEL
	var id: StringName = StringName("footstep_%s" % _surface)
	if not _register.has(id):
		id = &"footstep_wood"
	_step_side = not _step_side
	var db: float = (-4.0 if running else -9.0) + randf_range(-1.5, 1.5)
	if _step_side:
		db -= 0.8
	play_sfx(id, Vector3.INF, db)
	_step_count += 1
	if _step_count >= _next_bag_in:
		_step_count = 0
		_next_bag_in = randi_range(BAG_EVERY_MIN, BAG_EVERY_MAX)
		play_sfx(&"bag_leather", Vector3.INF, -18.0)


func _on_player_entered_room(room_id: StringName) -> void:
	_current_room = room_id
	if not _started:
		_start_ambience()          # le soundscape commence avec la partie
	var outside: bool = room_id == &"exterior"
	set_layer(&"exterior", 1.0 if outside else 0.0, 3.0)
	if outside:
		set_layer(&"house_base", 0.0, 3.0)
	elif room_id == &"cellar":
		set_layer(&"house_base", 0.55, 3.0)   # cave : la maison s'entend moins
	else:
		set_layer(&"house_base", 1.0, 3.0)


func _on_player_interacted(target_id: StringName, kind: StringName) -> void:
	var low: String = target_id.to_lower()
	match kind:
		&"open":
			if low.contains("drawer") or low.contains("tiroir"):
				play_sfx(&"drawer_open")
			elif low.contains("door") or low.contains("porte") or low.contains("gate") or low.contains("trappe"):
				play_sfx(&"door_open")
			else:
				play_sfx(&"interact_open")
		&"pickup":
			play_sfx(&"interact_pickup")
		&"read":
			play_sfx(&"interact_paper")
		&"burn":
			play_sfx(&"fire_start")
		_:
			play_sfx(&"interact_generic")


func _on_item_checked(_item_id: StringName, _photo: PhotoData) -> void:
	play_ui(&"pencil_check")


func _on_notebook_opened() -> void:
	play_ui(&"notebook_open")


func _on_notebook_closed() -> void:
	play_ui(&"notebook_close")


## Le flash : Gameplay joue déjà `camera_flash`. Ce relais ne sert que si
## personne ne l'a joué dans les 0,4 s (mon test, une cinématique, un autre
## déclencheur). Idem pour la photo qui sort, via photo_taken.
func _on_flash_fired(_world_position: Vector3, _room_id: StringName) -> void:
	if _recently_played(&"camera_flash", 0.4):
		return
	play_ui(&"camera_flash")
	_schedule_charge(1.15)


func _on_photo_taken(_photo: PhotoData) -> void:
	_shots_pending += 1
	if _recently_played(&"photo_slide", 0.6):
		return
	play_ui(&"photo_slide")


func _on_photo_developed(_photo: PhotoData) -> void:
	if _shots_pending > 0:
		_shots_pending -= 1
	play_ui(&"photo_ready")


## Attention 0..100 -> trois temps : calme (0-20), inquiétude (20-45), cave
## (45+). Aucune variation brutale : les fondus durent 4 à 6 s.
func _on_house_attention_changed(value: float) -> void:
	_attention = clampf(value, 0.0, 100.0)
	var unease: float = clampf((_attention - 20.0) / 25.0, 0.0, 1.0)
	var dread: float = clampf((_attention - 45.0) / 25.0, 0.0, 1.0)
	set_layer(&"house_unease", unease, 4.0)
	set_layer(&"house_dread", dread, 6.0)


func _on_presence_state_changed(state: StringName) -> void:
	match state:
		&"physical":
			set_layer(&"presence", 1.0, 5.0)
		&"frozen", &"dormant":
			set_layer(&"presence", 0.0, 3.0)
		_:
			set_layer(&"presence", 0.35, 4.0)


func _on_player_caught() -> void:
	# Pas de cri : un choc sourd, l'ouïe qui se bouche, puis la récupération.
	play_ui(&"caught_impact")
	_duck_db = DUCK_CAUGHT_DB
	_apply_volumes()
	_set_cutoff(CUTOFF_CAUGHT, 0.12)
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_callback(_recover_from_caught)


func _recover_from_caught() -> void:
	_duck_db = 0.0
	_apply_volumes()
	_set_cutoff(CUTOFF_OPEN, 2.5)


func _on_ending_reached(ending_id: StringName) -> void:
	set_layer(&"house_base", 0.0, 4.0)
	set_layer(&"house_unease", 0.0, 4.0)
	set_layer(&"house_dread", 0.0, 4.0)
	set_layer(&"exterior", 0.0, 4.0)
	set_layer(&"presence", 0.0, 3.0)
	var track: StringName = StringName("music_ending_%s" % ending_id)
	if not _register.has(track):
		track = &"music_ending_closed"
	play_music(track, 6.0)


# =============================================================================
# APPAREIL PHOTO (priorité 1 du jeu)
# =============================================================================

## `camera_raise` sert à lever ET à baisser (photo_device.gd n'émet qu'un id).
func _toggle_camera() -> void:
	if _camera_up:
		_camera_up = false
		_play_camera(&"camera_lower")
		return
	_camera_up = true
	_play_camera(&"camera_raise")
	_schedule_charge(0.35)


func _play_camera(sfx_id: StringName) -> void:
	var entry: Dictionary = _register.get(sfx_id, {})
	if entry.is_empty():
		_warn_missing(sfx_id)
		return
	var stream: AudioStream = _pick_stream(entry)
	if stream == null:
		return
	_mark_played(&"camera_raise")
	_play_2d(entry, stream, entry.get("db", 0.0) + _rand_gain(entry), _rand_pitch(entry))


## Sifflement de charge du condensateur : il monte, puis un clic discret « prêt ».
func _schedule_charge(delay: float) -> void:
	if _charge_player == null:
		return
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(_play_charge)


func _play_charge() -> void:
	var entry: Dictionary = _register.get(&"flash_charge", {})
	if entry.is_empty():
		_warn_missing(&"flash_charge")
		return
	var stream: AudioStream = _pick_stream(entry)
	if stream == null:
		return
	_charge_player.stream = stream
	_charge_player.bus = entry.get("bus", BUS_UI)
	_charge_player.volume_db = entry.get("db", 0.0)
	_charge_player.pitch_scale = _rand_pitch(entry)
	_charge_player.play()


# =============================================================================
# MATÉRIAU SOUS LES PIEDS (convention metadata `surface`)
# =============================================================================

func _surface_at(world_position: Vector3) -> StringName:
	if world_position == Vector3.INF:
		return SURFACE_FALLBACK_BY_ROOM.get(_current_room, &"wood")
	var space: PhysicsDirectSpaceState3D = _physics_space()
	if space == null:
		return SURFACE_FALLBACK_BY_ROOM.get(_current_room, &"wood")
	var from: Vector3 = world_position + Vector3.UP * 0.45
	var to: Vector3 = world_position - Vector3.UP * 1.30
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return SURFACE_FALLBACK_BY_ROOM.get(_current_room, &"wood")
	var node: Node = hit.get("collider") as Node
	var depth: int = 0
	while node != null and depth < 4:
		# HOTFIX Architecte 21/10 : get_meta(key, null) déclenche une erreur par pas en 4.7 → has_meta d'abord.
		if node.has_meta(&"surface"):
			var raw: Variant = node.get_meta(&"surface")
			if String(raw) != "":
				return StringName(String(raw))
		node = node.get_parent()
		depth += 1
	return SURFACE_FALLBACK_BY_ROOM.get(_current_room, &"wood")


func _physics_space() -> PhysicsDirectSpaceState3D:
	if get_tree() == null or get_tree().root == null:
		return null
	var world: World3D = get_tree().root.get_world_3d()
	if world == null:
		return null
	return world.direct_space_state


# =============================================================================
# BOUCLE : souffle et craquements de maison
# =============================================================================

func _process(delta: float) -> void:
	if not _started or _current_room == &"":
		return
	_tick_breath(delta)
	_tick_house(delta)


func _tick_breath(delta: float) -> void:
	_breath_timer -= delta
	if _breath_timer > 0.0:
		return
	var t: float = clampf(_attention / 70.0, 0.0, 1.0)
	_breath_timer = lerpf(BREATH_CALM_INTERVAL, BREATH_DREAD_INTERVAL, t) * randf_range(0.85, 1.15)
	play_sfx(&"breath_in" if _breath_in else &"breath_out", Vector3.INF, lerpf(-22.0, -13.0, t))
	_breath_in = not _breath_in


func _tick_house(delta: float) -> void:
	if _current_room == &"exterior":
		return
	_tick_timer -= delta
	if _tick_timer > 0.0:
		return
	var t: float = clampf(_attention / 70.0, 0.0, 1.0)
	_tick_timer = randf_range(
		lerpf(TICK_CALM_MIN, TICK_DREAD_MIN, t),
		lerpf(TICK_CALM_MAX, TICK_DREAD_MAX, t))
	var id: StringName = HOUSE_TICK_IDS[randi() % HOUSE_TICK_IDS.size()]
	# Les craquements viennent d'ailleurs : 4 à 11 m du joueur, au hasard.
	var pos: Vector3 = Vector3.INF
	if _last_player_pos != Vector3.INF:
		var angle: float = randf() * TAU
		var dist: float = randf_range(4.0, 11.0)
		pos = _last_player_pos + Vector3(cos(angle) * dist, randf_range(-1.0, 1.5), sin(angle) * dist)
	play_sfx(id, pos, lerpf(-24.0, -16.0, t))


# =============================================================================
# REGISTRES
# =============================================================================

func _build_registers() -> void:
	_register = {
		# --- Appareil photo (bus UI : sons « dans les mains ») ----------------
		&"camera_raise": {"paths": ["camera/camera_raise.ogg"], "bus": BUS_UI, "db": -2.0, "rand": 0.02},
		&"camera_lower": {"paths": ["camera/camera_lower.ogg"], "bus": BUS_UI, "db": -4.0, "rand": 0.02},
		&"camera_shutter": {"paths": ["camera/camera_shutter.ogg"], "bus": BUS_UI, "db": -1.0, "rand": 0.03},
		&"camera_flash": {"paths": ["camera/camera_flash.ogg"], "bus": BUS_UI, "db": 0.0, "rand": 0.01},
		&"flash_charge": {"paths": ["camera/flash_charge.ogg"], "bus": BUS_UI, "db": -13.0, "rand": 0.03},
		&"photo_slide": {"paths": ["camera/photo_slide.ogg"], "bus": BUS_UI, "db": -1.0, "rand": 0.02},
		&"camera_dry": {"paths": ["camera/camera_dry.ogg"], "bus": BUS_UI, "db": -3.0, "rand": 0.04},
		&"photo_ready": {"paths": ["camera/photo_ready.ogg"], "bus": BUS_UI, "db": -14.0, "rand": 0.06},
		# --- Joueur : pas et souffle -------------------------------------------
		&"footstep_wood": {"paths": ["player/footstep_wood_01.ogg", "player/footstep_wood_02.ogg", "player/footstep_wood_03.ogg", "player/footstep_wood_04.ogg"], "rand": 0.09, "gain_rand": 1.2},
		&"footstep_tile": {"paths": ["player/footstep_tile_01.ogg", "player/footstep_tile_02.ogg", "player/footstep_tile_03.ogg", "player/footstep_tile_04.ogg"], "rand": 0.09, "gain_rand": 1.2},
		&"footstep_carpet": {"paths": ["player/footstep_carpet_01.ogg", "player/footstep_carpet_02.ogg", "player/footstep_carpet_03.ogg", "player/footstep_carpet_04.ogg"], "rand": 0.09, "gain_rand": 1.2},
		&"footstep_gravel": {"paths": ["player/footstep_gravel_01.ogg", "player/footstep_gravel_02.ogg", "player/footstep_gravel_03.ogg", "player/footstep_gravel_04.ogg"], "rand": 0.09, "gain_rand": 1.2},
		&"footstep_stone": {"paths": ["player/footstep_stone_01.ogg", "player/footstep_stone_02.ogg", "player/footstep_stone_03.ogg", "player/footstep_stone_04.ogg"], "rand": 0.09, "gain_rand": 1.2},
		&"bag_leather": {"paths": ["player/bag_leather.ogg"], "rand": 0.08},
		&"breath_in": {"paths": ["player/breath_in.ogg"], "rand": 0.05},
		&"breath_out": {"paths": ["player/breath_out.ogg"], "rand": 0.05},
		# --- Interactions -------------------------------------------------------
		&"interact_open": {"paths": ["interact/interact_open.ogg"], "db": -6.0, "rand": 0.06},
		&"drawer_open": {"paths": ["interact/drawer_open.ogg"], "db": -4.0, "rand": 0.05},
		&"door_open": {"paths": ["interact/door_open.ogg"], "db": -3.0, "rand": 0.05},
		&"door_close": {"paths": ["interact/door_close.ogg"], "db": -2.0, "rand": 0.05},
		&"interact_pickup": {"paths": ["interact/interact_pickup.ogg"], "db": -8.0, "rand": 0.08},
		&"interact_paper": {"paths": ["interact/interact_paper.ogg"], "db": -10.0, "rand": 0.08},
		&"interact_generic": {"paths": ["interact/interact_generic.ogg"], "db": -10.0, "rand": 0.08},
		&"fire_start": {"paths": ["interact/fire_start.ogg"], "db": -6.0, "rand": 0.05},
		&"flashlight_click": {"paths": ["interact/flashlight_click.ogg"], "bus": BUS_UI, "db": -6.0, "rand": 0.04},
		&"notebook_open": {"paths": ["interact/notebook_open.ogg"], "bus": BUS_UI, "db": -8.0, "rand": 0.05},
		&"notebook_close": {"paths": ["interact/notebook_close.ogg"], "bus": BUS_UI, "db": -8.0, "rand": 0.05},
		&"pencil_check": {"paths": ["interact/pencil_check.ogg"], "bus": BUS_UI, "db": -9.0, "rand": 0.07},
		# --- Maison : craquements et tuyaux (ticks aléatoires) -------------------
		&"house_creak_01": {"paths": ["house/house_creak_01.ogg"], "rand": 0.06, "unit_size": 8.0, "max_distance": 28.0},
		&"house_creak_02": {"paths": ["house/house_creak_02.ogg"], "rand": 0.06, "unit_size": 8.0, "max_distance": 28.0},
		&"house_creak_03": {"paths": ["house/house_creak_03.ogg"], "rand": 0.06, "unit_size": 8.0, "max_distance": 28.0},
		&"house_pipe_01": {"paths": ["house/house_pipe_01.ogg"], "rand": 0.06, "unit_size": 8.0, "max_distance": 28.0},
		&"house_pipe_02": {"paths": ["house/house_pipe_02.ogg"], "rand": 0.06, "unit_size": 8.0, "max_distance": 28.0},
		&"clock_chime_distant": {"paths": ["house/clock_chime_distant.ogg"], "db": -8.0, "rand": 0.02, "unit_size": 12.0, "max_distance": 40.0},
		# --- Présence : sons domestiques au mauvais endroit -----------------------
		&"chair_drag_upstairs": {"paths": ["presence/chair_drag_upstairs.ogg"], "db": -6.0, "rand": 0.04, "unit_size": 12.0, "max_distance": 40.0},
		&"upstairs_chair": {"paths": ["presence/upstairs_chair.ogg"], "db": -7.0, "rand": 0.04, "unit_size": 12.0, "max_distance": 40.0},
		&"footsteps_above": {"paths": ["presence/footsteps_above.ogg"], "db": -5.0, "rand": 0.05, "unit_size": 12.0, "max_distance": 40.0},
		&"door_close_upstairs": {"paths": ["presence/door_close_upstairs.ogg"], "db": -4.0, "rand": 0.03, "unit_size": 12.0, "max_distance": 40.0},
		&"phone_ring": {"paths": ["presence/phone_ring.ogg"], "db": -6.0, "rand": 0.01, "unit_size": 10.0, "max_distance": 36.0},
		&"water_drip": {"paths": ["presence/water_drip.ogg"], "db": -12.0, "rand": 0.12, "unit_size": 6.0, "max_distance": 20.0},
		&"paper_turn": {"paths": ["presence/paper_turn.ogg"], "db": -9.0, "rand": 0.08, "unit_size": 6.0, "max_distance": 20.0},
		&"breath_low": {"paths": ["presence/breath_low.ogg"], "db": -10.0, "rand": 0.05, "unit_size": 6.0, "max_distance": 18.0},
		&"hall_light_out": {"paths": ["presence/hall_light_out.ogg"], "db": -5.0, "rand": 0.02, "unit_size": 10.0, "max_distance": 30.0},
		&"cellar_light_flicker": {"paths": ["presence/cellar_light_flicker.ogg"], "db": -6.0, "rand": 0.03, "unit_size": 8.0, "max_distance": 24.0},
		&"caught_impact": {"paths": ["presence/caught_impact.ogg"], "bus": BUS_UI, "db": -2.0},
		# --- Musiques -------------------------------------------------------------
		&"music_ending_closed": {"paths": ["music/music_ending_closed.ogg"], "bus": BUS_MUSIC, "db": -3.0},
		&"music_ending_ashes": {"paths": ["music/music_ending_ashes.ogg"], "bus": BUS_MUSIC, "db": -3.0},
	}
	# Sons « venus d'ailleurs » : joués en 3D par rapport au joueur même si
	# l'appelant (règle HouseDirector) ne donne pas de position.
	_spatial_hints = {
		&"chair_drag_upstairs": Vector3(0.0, 3.1, 0.0),
		&"upstairs_chair": Vector3(0.0, 3.1, 0.0),
		&"footsteps_above": Vector3(0.0, 3.1, 0.0),
		&"door_close_upstairs": Vector3(0.0, 3.1, 0.0),
		&"clock_chime_distant": Vector3(0.0, 1.0, -6.0),
	}
	_layer_register = {
		&"house_base": {"path": "house/amb_house_base.ogg", "bus": BUS_AMBIANCE, "db": -10.0},
		&"house_unease": {"path": "house/amb_house_unease.ogg", "bus": BUS_AMBIANCE, "db": -14.0},
		&"house_dread": {"path": "house/amb_house_dread.ogg", "bus": BUS_AMBIANCE, "db": -12.0},
		&"exterior": {"path": "house/amb_exterior.ogg", "bus": BUS_AMBIANCE, "db": -9.0},
		&"presence": {"path": "presence/amb_presence.ogg", "bus": BUS_AMBIANCE, "db": -18.0},
	}
