extends GutTest
## Unit tests for PowerUpManager — stack lifecycle and grenade/laser activation.

const PowerUpManagerGd := preload("res://src/features/powerups/PowerUpManager.gd")

var _manager: Node

func before_each() -> void:
	_manager = PowerUpManagerGd.new()
	add_child_autofree(_manager)

# --- Stack lifecycle ---

func test_manager_instantiates() -> void:
	assert_not_null(_manager)

func test_no_stacks_initially() -> void:
	assert_eq(_manager.get_stack_count(&"mole_grenade"), 0)

func test_powerup_selected_adds_stack() -> void:
	EventBus.powerup_selected.emit(&"mole_grenade")
	assert_eq(_manager.get_stack_count(&"mole_grenade"), 1)

func test_multiple_selects_stack() -> void:
	EventBus.powerup_selected.emit(&"rapid_fire")
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_eq(_manager.get_stack_count(&"rapid_fire"), 2)

func test_different_powerups_stack_independently() -> void:
	EventBus.powerup_selected.emit(&"triple_shot")
	EventBus.powerup_selected.emit(&"mole_grenade")
	assert_eq(_manager.get_stack_count(&"triple_shot"), 1)
	assert_eq(_manager.get_stack_count(&"mole_grenade"), 1)

func test_session_ended_clears_stacks() -> void:
	EventBus.powerup_selected.emit(&"rapid_fire")
	EventBus.game_over.emit(0, 0.0)
	assert_eq(_manager.get_stack_count(&"rapid_fire"), 0)

func test_session_ended_emits_stack_changed_zero() -> void:
	EventBus.powerup_selected.emit(&"triple_shot")
	watch_signals(EventBus)
	EventBus.game_over.emit(0, 0.0)
	assert_signal_emitted_with_parameters(EventBus, "powerup_stack_changed", [&"triple_shot", 0])

func test_salsa_magnet_does_not_affect_grenade_stack() -> void:
	EventBus.powerup_selected.emit(&"salsa_magnet")
	assert_eq(_manager.get_stack_count(&"mole_grenade"), 0)
