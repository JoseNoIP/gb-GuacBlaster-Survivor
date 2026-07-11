extends Node
## Centralized audio playback and haptic feedback.
## SFX keys map to AudioStreamPlayer nodes added as children in the scene.
## Haptic uses Input.vibrate_handheld() — only active on mobile exports.

var _sfx_players: Dictionary[StringName, AudioStreamPlayer] = {}

func _ready() -> void:
	EventBus.player_died.connect(func(): play_sfx(&"player_die"))
	EventBus.boss_defeated.connect(func(_id): trigger_haptic_heavy())

func register_sfx(sound_id: StringName, player: AudioStreamPlayer) -> void:
	_sfx_players[sound_id] = player

func play_sfx(sound_id: StringName) -> void:
	if not _sfx_players.has(sound_id):
		push_warning("AudioManager: unknown SFX '%s'" % sound_id)
		return
	_sfx_players[sound_id].play()

func trigger_haptic_light() -> void:
	Input.vibrate_handheld(10)

func trigger_haptic_heavy() -> void:
	Input.vibrate_handheld(50)
