extends Node
## Centralized audio playback and haptic feedback.
## SFX keys map to AudioStreamPlayer nodes registered via register_sfx().
## Haptic uses Input.vibrate_handheld() — only active on mobile exports.
## Missing SFX warn once per ID so the terminal doesn't spam during development.

var _sfx_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _missing_warned: Dictionary[StringName, bool] = {}

func _ready() -> void:
	EventBus.player_died.connect(func(): play_sfx(&"player_die"))
	EventBus.boss_defeated.connect(func(_id: int): trigger_haptic_heavy())

func register_sfx(sound_id: StringName, player: AudioStreamPlayer) -> void:
	_sfx_players[sound_id] = player
	_missing_warned.erase(sound_id)

func play_sfx(sound_id: StringName) -> void:
	if not _sfx_players.has(sound_id):
		if not _missing_warned.get(sound_id, false):
			push_warning("AudioManager: SFX '%s' not registered — add an AudioStreamPlayer" % sound_id)
			_missing_warned[sound_id] = true
		return
	_sfx_players[sound_id].play()

func trigger_haptic_light() -> void:
	Input.vibrate_handheld(10)

func trigger_haptic_heavy() -> void:
	Input.vibrate_handheld(50)
