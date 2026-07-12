extends Node
## Centralized audio playback and haptic feedback.
## Loads WAV files from assets/audio/ if they exist; silently skips missing ones.
## Haptic uses Input.vibrate_handheld() — only active on mobile exports.

const AUDIO_DIR := "res://assets/audio/"

var _sfx_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _missing_warned: Dictionary[StringName, bool] = {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_load_all_sfx()
	_setup_music()
	_connect_events()

func _load_all_sfx() -> void:
	var sfx_map: Dictionary = {
		&"shoot":        "shoot.wav",
		&"enemy_die":    "enemy_die.wav",
		&"player_hit":   "player_hit.wav",
		&"gem_collect":  "gem_collect.wav",
		&"levelup":      "levelup.wav",
		&"boss_die":     "boss_die.wav",
	}
	for id: StringName in sfx_map.keys():
		var path: String = AUDIO_DIR + sfx_map[id]
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		if ResourceLoader.exists(path):
			player.stream = load(path) as AudioStream
		add_child(player)
		_sfx_players[id] = player

func _setup_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.volume_db = -6.0
	var music_path := AUDIO_DIR + "music_loop.wav"
	if ResourceLoader.exists(music_path):
		var stream := load(music_path) as AudioStreamWAV
		if stream != null:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music_player.stream = stream
	add_child(_music_player)

func _connect_events() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(func(_s: int, _d: float): _stop_music())
	EventBus.game_won.connect(func(_s: int, _d: float): _stop_music())
	EventBus.player_died.connect(func(): play_sfx(&"player_hit"))
	EventBus.boss_defeated.connect(func(_id: int): _on_boss_defeated())
	EventBus.enemy_destroyed.connect(func(_id: int, _pos: Vector2, _xp: int): play_sfx(&"enemy_die"))
	EventBus.gem_collected.connect(func(_xp: int): play_sfx(&"gem_collect"))
	EventBus.player_level_up.connect(func(_lvl: int): play_sfx(&"levelup"))

func _on_game_started() -> void:
	_play_music()

func _on_boss_defeated() -> void:
	play_sfx(&"boss_die")
	trigger_haptic_heavy()

func _play_music() -> void:
	if not SaveManager.get_sound_enabled():
		return
	if _music_player.stream != null and not _music_player.playing:
		_music_player.play()

func _stop_music() -> void:
	_music_player.stop()

func register_sfx(sound_id: StringName, player: AudioStreamPlayer) -> void:
	_sfx_players[sound_id] = player
	_missing_warned.erase(sound_id)

func play_sfx(sound_id: StringName) -> void:
	if not SaveManager.get_sound_enabled():
		return
	if not _sfx_players.has(sound_id):
		if not _missing_warned.get(sound_id, false):
			push_warning("AudioManager: SFX '%s' not registered" % sound_id)
			_missing_warned[sound_id] = true
		return
	var player: AudioStreamPlayer = _sfx_players[sound_id]
	if player.stream != null:
		player.play()

func trigger_haptic_light() -> void:
	if not SaveManager.get_vibration_enabled():
		return
	Input.vibrate_handheld(10)

func trigger_haptic_heavy() -> void:
	if not SaveManager.get_vibration_enabled():
		return
	Input.vibrate_handheld(50)
