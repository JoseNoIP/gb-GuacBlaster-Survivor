extends GutTest
## Unit tests for SaveManager persistence logic.
## These tests verify in-memory state; file I/O is integration-level.

func before_each() -> void:
	SaveManager._data = {
		"gold": 0,
		"upgrades": {"damage": 0, "speed": 0, "health": 0, "luck": 0},
		"best_score": 0,
		"total_sessions": 0,
	}

func test_get_gold_returns_zero_initially() -> void:
	assert_eq(SaveManager.get_gold(), 0)

func test_gold_earned_increases_gold() -> void:
	SaveManager._on_gold_earned(50)
	assert_eq(SaveManager.get_gold(), 50)

func test_gold_earned_accumulates() -> void:
	SaveManager._on_gold_earned(30)
	SaveManager._on_gold_earned(20)
	assert_eq(SaveManager.get_gold(), 50)

func test_upgrade_level_defaults_to_zero() -> void:
	assert_eq(SaveManager.get_upgrade_level(&"damage"), 0)

func test_upgrade_purchased_stores_level() -> void:
	SaveManager._on_upgrade_purchased(&"damage", 3)
	assert_eq(SaveManager.get_upgrade_level(&"damage"), 3)

func test_game_over_updates_best_score() -> void:
	SaveManager._on_game_over(500, 90.0)
	assert_eq(SaveManager.get_best_score(), 500)

func test_game_over_does_not_lower_best_score() -> void:
	SaveManager._on_game_over(500, 90.0)
	SaveManager._on_game_over(200, 60.0)
	assert_eq(SaveManager.get_best_score(), 500)
