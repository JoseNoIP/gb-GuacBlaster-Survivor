extends GutTest
## Unit tests for PowerUpManager — grenade activation lifecycle.

const PowerUpManagerGd := preload("res://src/features/powerups/PowerUpManager.gd")

var _manager: Node

func before_each() -> void:
	_manager = PowerUpManagerGd.new()
	add_child_autofree(_manager)

# --- Mole grenade activation ---

func test_manager_instantiates() -> void:
	assert_not_null(_manager)

func test_grenade_not_active_initially() -> void:
	assert_false(_manager.get("_grenade_active"))

func test_mole_grenade_activates_grenade() -> void:
	EventBus.powerup_selected.emit(&"mole_grenade")
	assert_true(_manager.get("_grenade_active"))

func test_mole_grenade_only_activates_once() -> void:
	EventBus.powerup_selected.emit(&"mole_grenade")
	EventBus.powerup_selected.emit(&"mole_grenade")
	assert_true(_manager.get("_grenade_active"))

func test_game_over_deactivates_grenade() -> void:
	EventBus.powerup_selected.emit(&"mole_grenade")
	EventBus.game_over.emit(0, 0.0)
	assert_false(_manager.get("_grenade_active"))

func test_rapid_fire_does_not_activate_grenade() -> void:
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_false(_manager.get("_grenade_active"))

func test_salsa_magnet_does_not_activate_grenade() -> void:
	EventBus.powerup_selected.emit(&"salsa_magnet")
	assert_false(_manager.get("_grenade_active"))
