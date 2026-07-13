extends GutTest
## Tests DailyMissionsManager autoload directly to avoid double-signal handling.

func before_each() -> void:
	SaveManager._data["daily_missions"] = {}
	DailyMissionsManager._session_kills = 0
	DailyMissionsManager._session_powerups = 0
	DailyMissionsManager._session_max_level = 0
	DailyMissionsManager._session_boss_killed = false
	DailyMissionsManager._session_active = false
	var today: String = DailyMissionsManager._get_today()
	DailyMissionsManager._generate_missions(today)

func test_daily_missions_manager_is_node() -> void:
	assert_true(DailyMissionsManager is Node)

func test_generates_correct_mission_count() -> void:
	var missions: Array = DailyMissionsManager.get_missions()
	assert_eq(missions.size(), Constants.DAILY_MISSIONS_COUNT)

func test_missions_have_required_keys() -> void:
	for mission in DailyMissionsManager.get_missions():
		var m: Dictionary = mission as Dictionary
		assert_true(m.has("id"), "mission should have id")
		assert_true(m.has("desc"), "mission should have desc")
		assert_true(m.has("target"), "mission should have target")
		assert_true(m.has("reward"), "mission should have reward")
		assert_true(m.has("current"), "mission should have current")
		assert_true(m.has("completed"), "mission should have completed")

func test_missions_start_not_completed() -> void:
	for mission in DailyMissionsManager.get_missions():
		assert_false(
			(mission as Dictionary).get("completed", true) as bool,
			"fresh missions should not be completed"
		)

func test_missions_start_at_zero_progress() -> void:
	for mission in DailyMissionsManager.get_missions():
		assert_eq(
			(mission as Dictionary).get("current", -1) as int, 0
		)

func test_kill_progress_accumulated_in_daily() -> void:
	EventBus.game_started.emit()
	EventBus.enemy_destroyed.emit(0, Vector2.ZERO, 1)
	EventBus.enemy_destroyed.emit(1, Vector2.ZERO, 1)
	EventBus.game_over.emit(0, 5.0)
	var kills: int = DailyMissionsManager._daily.get("kills", 0) as int
	assert_eq(kills, 2)

func test_boss_defeat_tracked_in_daily() -> void:
	EventBus.game_started.emit()
	EventBus.boss_defeated.emit(0)
	EventBus.game_won.emit(100, 60.0)
	var boss_kills: int = DailyMissionsManager._daily.get("boss_kills", 0) as int
	assert_eq(boss_kills, 1)

func test_win_increments_daily_wins() -> void:
	EventBus.game_started.emit()
	EventBus.game_won.emit(50, 30.0)
	var wins: int = DailyMissionsManager._daily.get("wins", 0) as int
	assert_eq(wins, 1)

func test_completed_mission_emits_signal() -> void:
	DailyMissionsManager._missions = [
		{"id": &"win_game", "desc": "Test", "target": 1, "reward": 10,
		"current": 0, "completed": false}
	]
	DailyMissionsManager._daily["missions"] = DailyMissionsManager._missions
	DailyMissionsManager._daily["wins"] = 0
	watch_signals(EventBus)
	EventBus.game_started.emit()
	EventBus.game_won.emit(0, 10.0)
	assert_signal_emitted(EventBus, "mission_completed")

func test_unique_missions_per_day() -> void:
	var missions: Array = DailyMissionsManager.get_missions()
	var ids: Array = []
	for mission in missions:
		var id: StringName = (mission as Dictionary).get("id", &"") as StringName
		assert_false(ids.has(id), "no duplicate mission IDs per day")
		ids.append(id)

func test_missions_persisted_to_save_manager() -> void:
	var saved: Dictionary = SaveManager.get_daily_missions()
	assert_true(saved.has("date"), "persisted data should have date")
	assert_true(saved.has("missions"), "persisted data should have missions")
