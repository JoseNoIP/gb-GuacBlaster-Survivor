extends GutTest
## Tests for meta-progression: gold earning, upgrade screen structure.

const UpgradeScreenGd := preload("res://src/scenes/UpgradeScreen.gd")

var _screen: UpgradeScreen

func before_each() -> void:
	SaveManager._data = {
		"gold": 0,
		"upgrades": {
			"damage": 0, "speed": 0, "health": 0, "luck": 0,
			"gold_bonus": 0, "starter_shield": 0,
		},
		"best_score": 0,
		"total_sessions": 0,
	}
	GameManager.start_game()
	_screen = UpgradeScreenGd.new()
	add_child_autofree(_screen)

# --- Gold earning ---

func test_gold_earned_emitted_when_score_positive() -> void:
	EventBus.gem_collected.emit(1000)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	assert_signal_emitted(EventBus, "gold_earned")

func test_no_gold_earned_when_score_is_zero() -> void:
	watch_signals(EventBus)
	EventBus.player_died.emit()
	assert_signal_not_emitted(EventBus, "gold_earned")

func test_gold_amount_proportional_to_score() -> void:
	EventBus.gem_collected.emit(1000)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	var expected: int = int(1000.0 * Constants.GOLD_PER_SCORE_POINT)
	assert_signal_emitted_with_parameters(EventBus, "gold_earned", [expected])

# --- UpgradeScreen structure ---

func test_upgrade_screen_has_damage_buy_button() -> void:
	assert_not_null(_screen.get_buy_button(&"damage"))

func test_upgrade_screen_has_speed_buy_button() -> void:
	assert_not_null(_screen.get_buy_button(&"speed"))

func test_upgrade_screen_has_health_buy_button() -> void:
	assert_not_null(_screen.get_buy_button(&"health"))

func test_upgrade_screen_has_luck_buy_button() -> void:
	assert_not_null(_screen.get_buy_button(&"luck"))

func test_upgrade_screen_gold_label_matches_save() -> void:
	assert_eq(_screen.get_gold_label().text, "Oro: %d" % SaveManager.get_gold())

func test_buy_with_gold_emits_upgrade_purchased() -> void:
	EventBus.gold_earned.emit(10000)
	watch_signals(EventBus)
	_screen.get_buy_button(&"damage").pressed.emit()
	assert_signal_emitted(EventBus, "upgrade_purchased")

func test_upgrade_screen_has_gold_bonus_button() -> void:
	assert_not_null(_screen.get_buy_button(&"gold_bonus"))

func test_upgrade_screen_has_starter_shield_button() -> void:
	assert_not_null(_screen.get_buy_button(&"starter_shield"))

func test_buy_button_disabled_at_max_level() -> void:
	SaveManager._data["gold"] = 100000
	SaveManager._data["upgrades"]["damage"] = Constants.META_MAX_UPGRADE_LEVEL
	var new_screen: UpgradeScreenGd = UpgradeScreenGd.new()
	add_child_autofree(new_screen)
	assert_true(new_screen.get_buy_button(&"damage").disabled)
