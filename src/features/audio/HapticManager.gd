extends Node
## Event-driven haptic feedback. Responds to game events with device vibration.
## AudioManager handles haptics triggered by Player (shoot, boss_defeated).
## This autoload handles remaining events: damage, powerup, phase change, heart.

func _ready() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.heart_collected.connect(_on_heart_collected)

func _vibrate(ms: int) -> void:
	if SaveManager.get_vibration_enabled():
		Input.vibrate_handheld(ms)

func _on_player_damaged() -> void:
	_vibrate(80)

func _on_powerup_selected(_id: StringName) -> void:
	_vibrate(20)

func _on_boss_phase_changed(_phase: int) -> void:
	_vibrate(120)

func _on_heart_collected() -> void:
	_vibrate(20)
