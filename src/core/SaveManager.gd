extends Node
## Handles game persistence. Saves meta-progression to user://save.json.
## All file I/O goes through this node — never open files directly in features.

const SAVE_PATH: String = "user://save.json"

var _data: Dictionary = {
	"gold": 0,
	"upgrades": {
		"damage": 0,
		"speed": 0,
		"health": 0,
		"luck": 0,
		"gold_bonus": 0,
		"starter_shield": 0,
	},
	"best_score": 0,
	"total_sessions": 0,
	"victories": 0,
	"swipe_sensitivity": 1.0,
	"sound_enabled": true,
	"vibration_enabled": true,
	"achievements": {},
	"total_powerups_collected": 0,
	"selected_character": "guac",
	"unlocked_characters": {},
	"daily_missions": {},
}

func _ready() -> void:
	_load()
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_won.connect(_on_game_won)
	EventBus.gold_earned.connect(_on_gold_earned)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_game_over(score: int, _duration: float) -> void:
	if score > _data.get("best_score", 0):
		_data["best_score"] = score
	_data["total_sessions"] = _data.get("total_sessions", 0) + 1
	_save()

func _on_game_won(score: int, _duration: float) -> void:
	if score > _data.get("best_score", 0):
		_data["best_score"] = score
	_data["total_sessions"] = _data.get("total_sessions", 0) + 1
	_data["victories"] = _data.get("victories", 0) + 1
	_save()

func _on_gold_earned(amount: int) -> void:
	_data["gold"] = get_gold() + amount
	_save()

func _on_upgrade_purchased(upgrade_id: StringName, new_level: int) -> void:
	_data["upgrades"][str(upgrade_id)] = new_level
	_save()

func get_gold() -> int:
	return _data.get("gold", 0)

func get_upgrade_level(upgrade_id: StringName) -> int:
	return _data.get("upgrades", {}).get(str(upgrade_id), 0)

func get_best_score() -> int:
	return _data.get("best_score", 0)

func get_total_sessions() -> int:
	return _data.get("total_sessions", 0)

func get_victories() -> int:
	return _data.get("victories", 0)

func get_swipe_sensitivity() -> float:
	return float(_data.get("swipe_sensitivity", 1.0))

func set_swipe_sensitivity(value: float) -> void:
	_data["swipe_sensitivity"] = clampf(value, 1.0, 2.0)
	_save()

func get_sound_enabled() -> bool:
	return bool(_data.get("sound_enabled", true))

func set_sound_enabled(value: bool) -> void:
	_data["sound_enabled"] = value
	_save()

func get_vibration_enabled() -> bool:
	return bool(_data.get("vibration_enabled", true))

func set_vibration_enabled(value: bool) -> void:
	_data["vibration_enabled"] = value
	_save()

func get_achievements() -> Dictionary:
	return _data.get("achievements", {}) as Dictionary

func has_achievement(achievement_id: StringName) -> bool:
	return get_achievements().get(str(achievement_id), false) as bool

func unlock_achievement(achievement_id: StringName) -> void:
	if not _data.has("achievements"):
		_data["achievements"] = {}
	(_data["achievements"] as Dictionary)[str(achievement_id)] = true
	_save()

func get_selected_character() -> StringName:
	return _data.get("selected_character", "guac") as StringName

func set_selected_character(char_id: StringName) -> void:
	_data["selected_character"] = str(char_id)
	_save()

func is_character_unlocked(char_id: StringName) -> bool:
	if char_id == &"guac":
		return true
	var unlocked: Dictionary = _data.get("unlocked_characters", {}) as Dictionary
	return unlocked.get(str(char_id), false) as bool

func unlock_character(char_id: StringName, cost: int) -> bool:
	if char_id == &"guac":
		return true
	if is_character_unlocked(char_id):
		return true
	if get_gold() < cost:
		return false
	_data["gold"] = get_gold() - cost
	if not _data.has("unlocked_characters"):
		_data["unlocked_characters"] = {}
	(_data["unlocked_characters"] as Dictionary)[str(char_id)] = true
	_save()
	return true

func get_daily_missions() -> Dictionary:
	return _data.get("daily_missions", {}) as Dictionary

func save_daily_missions(data: Dictionary) -> void:
	_data["daily_missions"] = data
	_save()

func add_lifetime_stat(key: StringName, amount: int) -> void:
	var current: int = _data.get(str(key), 0) as int
	_data[str(key)] = current + amount
	_save()

func get_lifetime_stat(key: StringName) -> int:
	return _data.get(str(key), 0) as int

func purchase_upgrade(upgrade_id: StringName) -> bool:
	var current_level: int = get_upgrade_level(upgrade_id)
	if current_level >= Constants.META_MAX_UPGRADE_LEVEL:
		return false
	var base: float = float(Constants.META_UPGRADE_COST_BASE)
	var growth: float = pow(Constants.META_UPGRADE_COST_GROWTH, float(current_level))
	var cost: int = int(base * growth)
	if get_gold() < cost:
		return false
	_data["gold"] = get_gold() - cost
	_data["upgrades"][str(upgrade_id)] = current_level + 1
	_save()
	EventBus.upgrade_purchased.emit(upgrade_id, current_level + 1)
	return true

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (err %s)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open %s for reading" % SAVE_PATH)
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		_data.merge(parsed, true)
	else:
		push_error("SaveManager: corrupt save file, using defaults")
