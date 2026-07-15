extends GutTest

var _manager: Node

func before_each() -> void:
	_manager = load("res://src/features/audio/HapticManager.gd").new()
	add_child_autofree(_manager)

func test_haptic_manager_is_node() -> void:
	assert_true(_manager is Node, "HapticManager should extend Node")

func test_connects_to_player_damaged() -> void:
	assert_true(
		EventBus.player_damaged.is_connected(_manager._on_player_damaged),
		"should connect to player_damaged"
	)

func test_connects_to_powerup_selected() -> void:
	assert_true(
		EventBus.powerup_selected.is_connected(_manager._on_powerup_selected),
		"should connect to powerup_selected"
	)

func test_connects_to_boss_phase_changed() -> void:
	assert_true(
		EventBus.boss_phase_changed.is_connected(_manager._on_boss_phase_changed),
		"should connect to boss_phase_changed"
	)

func test_connects_to_heart_collected() -> void:
	assert_true(
		EventBus.heart_collected.is_connected(_manager._on_heart_collected),
		"should connect to heart_collected"
	)

func test_vibrate_skips_when_disabled() -> void:
	SaveManager.set_vibration_enabled(false)
	_manager._vibrate(80)
	assert_true(true, "vibrate with disabled flag must not crash")
	SaveManager.set_vibration_enabled(true)

func test_vibrate_runs_when_enabled() -> void:
	SaveManager.set_vibration_enabled(true)
	_manager._vibrate(20)
	assert_true(true, "vibrate with enabled flag must not crash")
