extends GutTest
## Tests AchievementManager autoload directly to avoid double-signal handling.

func before_each() -> void:
	SaveManager._data["achievements"] = {}
	SaveManager._data["total_powerups_collected"] = 0
	AchievementManager._session_kills = 0
	AchievementManager._session_level = 0
	AchievementManager._session_time = 0.0
	AchievementManager._session_active = false
	AchievementManager._survivor_unlocked = false

func test_achievement_manager_is_node() -> void:
	assert_true(AchievementManager is Node)

func test_game_started_activates_session() -> void:
	EventBus.game_started.emit()
	assert_true(AchievementManager._session_active)

func test_session_counters_reset_on_game_started() -> void:
	AchievementManager._session_kills = 42
	AchievementManager._session_level = 7
	EventBus.game_started.emit()
	assert_eq(AchievementManager._session_kills, 0)
	assert_eq(AchievementManager._session_level, 0)

func test_boss_slayer_unlocked_on_boss_defeated() -> void:
	EventBus.boss_defeated.emit(0)
	assert_true(SaveManager.has_achievement(&"boss_slayer"))

func test_massacre_unlocked_at_100_session_kills() -> void:
	EventBus.game_started.emit()
	for i: int in 99:
		EventBus.enemy_destroyed.emit(i, Vector2.ZERO, 1)
	assert_false(SaveManager.has_achievement(&"massacre"), "not yet at 99 kills")
	EventBus.enemy_destroyed.emit(99, Vector2.ZERO, 1)
	assert_true(SaveManager.has_achievement(&"massacre"))

func test_level_10_unlocked_on_level_up() -> void:
	EventBus.game_started.emit()
	EventBus.player_level_up.emit(10)
	assert_true(SaveManager.has_achievement(&"level_10"))

func test_level_10_not_unlocked_below_10() -> void:
	EventBus.game_started.emit()
	EventBus.player_level_up.emit(9)
	assert_false(SaveManager.has_achievement(&"level_10"))

func test_power_hoarder_at_50_lifetime_powerups() -> void:
	EventBus.game_started.emit()
	for i: int in 49:
		EventBus.powerup_selected.emit(&"triple_shot")
	EventBus.game_over.emit(0, 0.0)
	assert_false(SaveManager.has_achievement(&"power_hoarder"), "not yet at 49")
	EventBus.game_started.emit()
	EventBus.powerup_selected.emit(&"triple_shot")
	EventBus.game_over.emit(0, 0.0)
	assert_true(SaveManager.has_achievement(&"power_hoarder"))

func test_max_upgrade_unlocked_on_max_level() -> void:
	EventBus.upgrade_purchased.emit(&"damage", Constants.META_MAX_UPGRADE_LEVEL)
	assert_true(SaveManager.has_achievement(&"max_upgrade"))

func test_max_upgrade_not_unlocked_below_max() -> void:
	EventBus.upgrade_purchased.emit(&"damage", Constants.META_MAX_UPGRADE_LEVEL - 1)
	assert_false(SaveManager.has_achievement(&"max_upgrade"))

func test_achievement_unlock_emits_signal() -> void:
	watch_signals(EventBus)
	EventBus.boss_defeated.emit(0)
	assert_signal_emitted_with_parameters(
		EventBus, "achievement_unlocked", [&"boss_slayer"]
	)

func test_duplicate_unlock_not_emitted_twice() -> void:
	EventBus.boss_defeated.emit(0)
	watch_signals(EventBus)
	EventBus.boss_defeated.emit(0)
	assert_signal_not_emitted(EventBus, "achievement_unlocked")
