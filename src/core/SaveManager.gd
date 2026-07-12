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
}

func _ready() -> void:
	_load()
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_won.connect(_on_game_over)
	EventBus.gold_earned.connect(_on_gold_earned)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_game_over(score: int, _duration: float) -> void:
	if score > _data.get("best_score", 0):
		_data["best_score"] = score
	_data["total_sessions"] = _data.get("total_sessions", 0) + 1
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
