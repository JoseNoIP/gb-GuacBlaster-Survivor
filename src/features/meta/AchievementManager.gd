extends Node
## Tracks and unlocks persistent achievements via EventBus signals.
## Per-session counters reset on game_started; lifetime stats via SaveManager.

var _session_kills: int = 0
var _session_level: int = 0
var _session_time: float = 0.0
var _session_active: bool = false
var _survivor_unlocked: bool = false

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_won.connect(_on_game_ended)
	EventBus.game_over.connect(_on_game_ended)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.gold_earned.connect(_on_gold_earned)

func _process(delta: float) -> void:
	if not _session_active or _survivor_unlocked:
		return
	_session_time += delta
	if _session_time >= 90.0:
		_survivor_unlocked = true
		_try_unlock(&"survivor_90")

func _on_game_started() -> void:
	_session_kills = 0
	_session_level = 0
	_session_time = 0.0
	_session_active = true
	_survivor_unlocked = false

func _on_game_ended(_score: int, _duration: float) -> void:
	_session_active = false
	if SaveManager.get_total_sessions() >= 25:
		_try_unlock(&"veteran")
	if SaveManager.get_victories() >= 1:
		_try_unlock(&"first_victory")
	if SaveManager.get_victories() >= 5:
		_try_unlock(&"five_victories")
	if SaveManager.get_gold() >= 500:
		_try_unlock(&"gold_500")
	if SaveManager.get_lifetime_stat(&"total_powerups_collected") >= 50:
		_try_unlock(&"power_hoarder")

func _on_enemy_destroyed(_id: int, _pos: Vector2, _xp: int) -> void:
	if not _session_active:
		return
	_session_kills += 1
	if _session_kills >= 100:
		_try_unlock(&"massacre")

func _on_powerup_selected(_id: StringName) -> void:
	SaveManager.add_lifetime_stat(&"total_powerups_collected", 1)

func _on_player_level_up(new_level: int) -> void:
	if not _session_active:
		return
	_session_level = maxi(_session_level, new_level)
	if _session_level >= 10:
		_try_unlock(&"level_10")

func _on_boss_defeated(_id: int) -> void:
	_try_unlock(&"boss_slayer")

func _on_upgrade_purchased(_id: StringName, new_level: int) -> void:
	if new_level >= Constants.META_MAX_UPGRADE_LEVEL:
		_try_unlock(&"max_upgrade")

func _on_gold_earned(_amount: int) -> void:
	if SaveManager.get_gold() >= 500:
		_try_unlock(&"gold_500")

func _try_unlock(achievement_id: StringName) -> void:
	if SaveManager.has_achievement(achievement_id):
		return
	SaveManager.unlock_achievement(achievement_id)
	EventBus.achievement_unlocked.emit(achievement_id)
