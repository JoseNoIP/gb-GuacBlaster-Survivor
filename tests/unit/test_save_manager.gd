extends GutTest
## Unit tests for SaveManager persistence logic.
## These tests verify in-memory state; file I/O is integration-level.

func before_each() -> void:
	SaveManager._data = {
		"gold": 0,
		"upgrades": {
			"damage": 0, "speed": 0, "health": 0, "luck": 0,
			"gold_bonus": 0, "starter_shield": 0,
		},
		"best_score": 0,
		"total_sessions": 0,
		"victories": 0,
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

func test_game_won_increments_victories() -> void:
	SaveManager._on_game_won(100, 60.0)
	assert_eq(SaveManager.get_victories(), 1)

func test_game_over_does_not_increment_victories() -> void:
	SaveManager._on_game_over(100, 60.0)
	assert_eq(SaveManager.get_victories(), 0)

func test_game_won_also_increments_total_sessions() -> void:
	SaveManager._on_game_won(100, 60.0)
	assert_eq(SaveManager.get_total_sessions(), 1)

func test_purchase_upgrade_increments_level() -> void:
	SaveManager._data["gold"] = 1000
	var before: int = SaveManager.get_upgrade_level(&"damage")
	SaveManager.purchase_upgrade(&"damage")
	assert_eq(SaveManager.get_upgrade_level(&"damage"), before + 1)

func test_purchase_upgrade_deducts_gold() -> void:
	SaveManager._data["gold"] = 1000
	var level: int = SaveManager.get_upgrade_level(&"damage")
	var base: float = float(Constants.META_UPGRADE_COST_BASE)
	var growth: float = pow(Constants.META_UPGRADE_COST_GROWTH, float(level))
	var cost: int = int(base * growth)
	SaveManager.purchase_upgrade(&"damage")
	assert_eq(SaveManager.get_gold(), 1000 - cost)

func test_purchase_upgrade_returns_false_when_no_gold() -> void:
	SaveManager._data["gold"] = 0
	assert_false(SaveManager.purchase_upgrade(&"damage"))

func test_purchase_upgrade_emits_upgrade_purchased() -> void:
	SaveManager._data["gold"] = 1000
	watch_signals(EventBus)
	SaveManager.purchase_upgrade(&"damage")
	assert_signal_emitted(EventBus, "upgrade_purchased")

func test_purchase_upgrade_at_max_level_returns_false() -> void:
	SaveManager._data["gold"] = 100000
	SaveManager._data["upgrades"]["damage"] = Constants.META_MAX_UPGRADE_LEVEL
	assert_false(SaveManager.purchase_upgrade(&"damage"))

func test_purchase_upgrade_at_max_level_does_not_deduct_gold() -> void:
	SaveManager._data["gold"] = 100000
	SaveManager._data["upgrades"]["damage"] = Constants.META_MAX_UPGRADE_LEVEL
	SaveManager.purchase_upgrade(&"damage")
	assert_eq(SaveManager.get_gold(), 100000)

func test_cost_grows_exponentially() -> void:
	SaveManager._data["gold"] = 100000
	SaveManager.purchase_upgrade(&"damage")
	var cost_lvl1: int = SaveManager._data["gold"]
	SaveManager._data["gold"] = 100000
	SaveManager._data["upgrades"]["damage"] = 1
	SaveManager.purchase_upgrade(&"damage")
	var cost_lvl2: int = SaveManager._data["gold"]
	assert_gt(100000 - cost_lvl2, 100000 - cost_lvl1)

# --- Swipe sensitivity ---

func test_swipe_sensitivity_defaults_to_one() -> void:
	assert_almost_eq(SaveManager.get_swipe_sensitivity(), 1.0, 0.001)

func test_set_swipe_sensitivity_stores_value() -> void:
	SaveManager.set_swipe_sensitivity(1.4)
	assert_almost_eq(SaveManager.get_swipe_sensitivity(), 1.4, 0.001)

func test_set_swipe_sensitivity_clamps_below_one() -> void:
	SaveManager.set_swipe_sensitivity(0.5)
	assert_almost_eq(SaveManager.get_swipe_sensitivity(), 1.0, 0.001)

func test_set_swipe_sensitivity_clamps_above_two() -> void:
	SaveManager.set_swipe_sensitivity(5.0)
	assert_almost_eq(SaveManager.get_swipe_sensitivity(), 2.0, 0.001)
