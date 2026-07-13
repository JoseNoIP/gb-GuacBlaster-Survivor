extends Node
## Daily missions reset at midnight (device local date).
## Tracks progress across sessions within the same day.

var _missions: Array = []
var _daily: Dictionary = {}
var _session_kills: int = 0
var _session_powerups: int = 0
var _session_max_level: int = 0
var _session_boss_killed: bool = false
var _session_active: bool = false

func _ready() -> void:
	_refresh_if_new_day()
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_over.connect(_on_game_ended)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_level_up.connect(_on_player_level_up)

func _get_today() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%d-%02d-%02d" % [d.get("year", 0), d.get("month", 0), d.get("day", 0)]

func _refresh_if_new_day() -> void:
	var today: String = _get_today()
	var saved: Dictionary = SaveManager.get_daily_missions()
	if saved.get("date", "") == today:
		_daily = saved
		_missions = _daily.get("missions", []) as Array
		return
	_generate_missions(today)

func _generate_missions(date: String) -> void:
	var hash_val: int = date.hash()
	var pool: Array = Constants.DAILY_MISSION_POOL.duplicate()
	_missions = []
	for i: int in Constants.DAILY_MISSIONS_COUNT:
		var idx: int = abs(hash_val + i * 31337) % pool.size()
		var mission: Dictionary = (pool[idx] as Dictionary).duplicate()
		mission["current"] = 0
		mission["completed"] = false
		_missions.append(mission)
		pool.remove_at(idx)
	_daily = {
		"date": date,
		"kills": 0,
		"powerups": 0,
		"sessions": 0,
		"wins": 0,
		"boss_kills": 0,
		"max_level": 0,
		"missions": _missions,
	}
	SaveManager.save_daily_missions(_daily)

func get_missions() -> Array:
	return _missions

func _on_game_started() -> void:
	_session_kills = 0
	_session_powerups = 0
	_session_max_level = 0
	_session_boss_killed = false
	_session_active = true
	_refresh_if_new_day()

func _on_game_won(_score: int, _duration: float) -> void:
	_daily["wins"] = (_daily.get("wins", 0) as int) + 1
	_flush_session(true)

func _on_game_ended(_score: int, _duration: float) -> void:
	_flush_session(false)

func _flush_session(_won: bool) -> void:
	if not _session_active:
		return
	_session_active = false
	_daily["sessions"] = (_daily.get("sessions", 0) as int) + 1
	_daily["kills"] = (_daily.get("kills", 0) as int) + _session_kills
	_daily["powerups"] = (_daily.get("powerups", 0) as int) + _session_powerups
	var stored_level: int = _daily.get("max_level", 0) as int
	_daily["max_level"] = maxi(stored_level, _session_max_level)
	if _session_boss_killed:
		_daily["boss_kills"] = (_daily.get("boss_kills", 0) as int) + 1
	_evaluate_missions()
	_daily["missions"] = _missions
	SaveManager.save_daily_missions(_daily)

func _evaluate_missions() -> void:
	for mission in _missions:
		if mission.get("completed", false) as bool:
			continue
		var id: StringName = mission.get("id", &"") as StringName
		var target: int = mission.get("target", 1) as int
		var current: int = 0
		match id:
			&"kill_20", &"kill_50", &"kill_100":
				current = _daily.get("kills", 0) as int
			&"powerups_5", &"powerups_10":
				current = _daily.get("powerups", 0) as int
			&"win_game":
				current = _daily.get("wins", 0) as int
			&"play_3":
				current = _daily.get("sessions", 0) as int
			&"boss_kill":
				current = _daily.get("boss_kills", 0) as int
			&"level_5":
				current = _daily.get("max_level", 0) as int
		mission["current"] = current
		EventBus.mission_progress.emit(id, current, target)
		if current >= target:
			mission["completed"] = true
			var reward: int = mission.get("reward", 0) as int
			EventBus.gold_earned.emit(reward)
			EventBus.mission_completed.emit(id, reward)

func _on_enemy_destroyed(_id: int, _pos: Vector2, _xp: int) -> void:
	if _session_active:
		_session_kills += 1

func _on_powerup_selected(_id: StringName) -> void:
	if _session_active:
		_session_powerups += 1

func _on_boss_defeated(_id: int) -> void:
	if _session_active:
		_session_boss_killed = true

func _on_player_level_up(new_level: int) -> void:
	if _session_active:
		_session_max_level = maxi(_session_max_level, new_level)
