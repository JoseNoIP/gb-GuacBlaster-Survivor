extends GutTest
## Tests WeeklyChallengeManager autoload directly to avoid double-signal handling.

func before_each() -> void:
	WeeklyChallengeManager._is_active = false
	WeeklyChallengeManager._current_challenge = {}
	SaveManager._data["weekly_challenges"] = {}

func test_weekly_challenge_manager_is_node() -> void:
	assert_true(WeeklyChallengeManager is Node)

func test_get_current_week_returns_positive_int() -> void:
	var week: int = WeeklyChallengeManager.get_current_week()
	assert_true(week > 0)

func test_get_current_challenge_has_required_keys() -> void:
	var challenge: Dictionary = WeeklyChallengeManager.get_current_challenge()
	assert_true(challenge.has("id"))
	assert_true(challenge.has("name"))
	assert_true(challenge.has("desc"))
	assert_true(challenge.has("gold_mult"))

func test_inactive_spawn_rate_mult_is_one() -> void:
	assert_eq(WeeklyChallengeManager.get_spawn_rate_mult(), 1.0)

func test_inactive_elite_chance_mult_is_one() -> void:
	assert_eq(WeeklyChallengeManager.get_elite_chance_mult(), 1.0)

func test_inactive_boss_hp_mult_is_one() -> void:
	assert_eq(WeeklyChallengeManager.get_boss_hp_mult(), 1.0)

func test_inactive_gold_mult_is_one() -> void:
	assert_eq(WeeklyChallengeManager.get_gold_mult(), 1.0)

func test_inactive_heart_drops_not_disabled() -> void:
	assert_false(WeeklyChallengeManager.is_heart_drops_disabled())

func test_activate_sets_active_flag() -> void:
	WeeklyChallengeManager.activate_challenge()
	assert_true(WeeklyChallengeManager.is_active())

func test_activate_loads_challenge_data() -> void:
	WeeklyChallengeManager.activate_challenge()
	assert_false(WeeklyChallengeManager._current_challenge.is_empty())

func test_game_over_resets_active_flag() -> void:
	WeeklyChallengeManager.activate_challenge()
	EventBus.game_over.emit(0, 0.0)
	assert_false(WeeklyChallengeManager.is_active())

func test_game_over_clears_challenge() -> void:
	WeeklyChallengeManager.activate_challenge()
	EventBus.game_over.emit(0, 0.0)
	assert_true(WeeklyChallengeManager._current_challenge.is_empty())

func test_menu_requested_resets_active_flag() -> void:
	WeeklyChallengeManager.activate_challenge()
	EventBus.menu_requested.emit()
	assert_false(WeeklyChallengeManager.is_active())

func test_game_won_marks_week_completed() -> void:
	WeeklyChallengeManager.activate_challenge()
	EventBus.game_won.emit(100, 30.0)
	assert_true(WeeklyChallengeManager.is_current_week_completed())

func test_game_won_resets_active_flag() -> void:
	WeeklyChallengeManager.activate_challenge()
	EventBus.game_won.emit(100, 30.0)
	assert_false(WeeklyChallengeManager.is_active())

func test_game_won_without_challenge_does_not_mark_completed() -> void:
	EventBus.game_won.emit(100, 30.0)
	assert_false(WeeklyChallengeManager.is_current_week_completed())

func test_current_week_not_completed_initially() -> void:
	assert_false(WeeklyChallengeManager.is_current_week_completed())
