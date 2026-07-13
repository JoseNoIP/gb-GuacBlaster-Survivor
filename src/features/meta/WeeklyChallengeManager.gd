extends Node
## Tracks the active weekly challenge and exposes multiplier getters to game systems.
## Returns neutral values (1.0 / false) when no challenge is active so callers
## don't need to branch on challenge state.

var _is_active: bool = false
var _current_challenge: Dictionary = {}

func _ready() -> void:
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_over.connect(_on_game_ended)
	EventBus.menu_requested.connect(_on_menu_requested)

func get_current_week() -> int:
	return int(Time.get_unix_time_from_system() / (7.0 * 24.0 * 3600.0))

func get_current_challenge() -> Dictionary:
	var pool: Array = Constants.WEEKLY_CHALLENGE_POOL
	return pool[get_current_week() % pool.size()] as Dictionary

func activate_challenge() -> void:
	_is_active = true
	_current_challenge = get_current_challenge()

func is_active() -> bool:
	return _is_active

func is_current_week_completed() -> bool:
	return SaveManager.is_weekly_challenge_completed(get_current_week())

func get_spawn_rate_mult() -> float:
	if not _is_active:
		return 1.0
	return _current_challenge.get("spawn_rate_mult", 1.0) as float

func get_elite_chance_mult() -> float:
	if not _is_active:
		return 1.0
	return _current_challenge.get("elite_chance_mult", 1.0) as float

func get_boss_hp_mult() -> float:
	if not _is_active:
		return 1.0
	return _current_challenge.get("boss_hp_mult", 1.0) as float

func is_heart_drops_disabled() -> bool:
	if not _is_active:
		return false
	return _current_challenge.get("no_heart_drops", false) as bool

func get_gold_mult() -> float:
	if not _is_active:
		return 1.0
	return _current_challenge.get("gold_mult", 1.0) as float

func _on_game_won(_score: int, _duration: float) -> void:
	if not _is_active:
		return
	var challenge_id: StringName = _current_challenge.get("id", &"") as StringName
	SaveManager.mark_weekly_challenge_completed(get_current_week())
	EventBus.weekly_challenge_completed.emit(challenge_id)
	_is_active = false
	_current_challenge = {}

func _on_game_ended(_score: int, _duration: float) -> void:
	_is_active = false
	_current_challenge = {}

func _on_menu_requested() -> void:
	_is_active = false
	_current_challenge = {}
