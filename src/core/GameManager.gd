extends Node
## Master game state machine. Controls the high-level game loop.
## Listens to EventBus signals and drives state transitions.

enum GameState { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER, GAME_WON }

var _state: GameState = GameState.MENU
var _score: int = 0
var _session_time: float = 0.0
var _current_level: int = 0
var _xp_current: int = 0
var _xp_required: int = Constants.XP_BASE_REQUIRED

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.gem_collected.connect(_on_gem_collected)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _process(delta: float) -> void:
	if _state == GameState.PLAYING:
		_session_time += delta

func start_game() -> void:
	_state = GameState.PLAYING
	_score = 0
	_session_time = 0.0
	_current_level = 0
	_xp_current = 0
	_xp_required = Constants.XP_BASE_REQUIRED
	EventBus.game_started.emit()

func get_state() -> GameState:
	return _state

func pause_game() -> void:
	if _state != GameState.PLAYING:
		return
	_state = GameState.PAUSED
	get_tree().paused = true
	EventBus.game_paused.emit(true)

func resume_game() -> void:
	if _state != GameState.PAUSED:
		return
	_state = GameState.PLAYING
	get_tree().paused = false
	EventBus.game_paused.emit(false)

func get_score() -> int:
	return _score

func get_session_time() -> float:
	return _session_time

func get_current_level() -> int:
	return _current_level

func _calc_gold() -> int:
	var gold_level: int = SaveManager.get_upgrade_level(&"gold_bonus")
	var gold_mult: float = 1.0 + float(gold_level) * Constants.META_GOLD_BONUS_PER_LEVEL
	return int(float(_score) * Constants.GOLD_PER_SCORE_POINT * gold_mult)

func _on_player_died() -> void:
	_state = GameState.GAME_OVER
	var gold: int = _calc_gold()
	if gold > 0:
		EventBus.gold_earned.emit(gold)
	EventBus.game_over.emit(_score, _session_time)

func _trigger_victory() -> void:
	_state = GameState.GAME_WON
	var gold: int = _calc_gold()
	if gold > 0:
		EventBus.gold_earned.emit(gold)
	EventBus.game_won.emit(_score, _session_time)

func _on_boss_defeated(_boss_id: int) -> void:
	if _state == GameState.PLAYING:
		_trigger_victory()

func _on_gem_collected(xp_value: int) -> void:
	if _state != GameState.PLAYING and _state != GameState.LEVEL_UP:
		return
	var luck_level: int = SaveManager.get_upgrade_level(&"luck")
	var luck_mult: float = 1.0 + float(luck_level) * Constants.META_LUCK_PER_LEVEL
	var effective_xp: int = int(float(xp_value) * luck_mult)
	_score += effective_xp
	EventBus.xp_collected.emit(effective_xp, _xp_current + effective_xp, _xp_required)

func _on_xp_collected(amount: int, _total: int, _required: int) -> void:
	_xp_current += amount
	if _xp_current >= _xp_required:
		_trigger_level_up()

func _trigger_level_up() -> void:
	_xp_current -= _xp_required
	_xp_required = int(_xp_required * Constants.XP_SCALE_FACTOR)
	_current_level += 1
	_state = GameState.LEVEL_UP
	EventBus.player_level_up.emit(_current_level)
	EventBus.powerup_selection_requested.emit(_pick_powerup_options())

func _pick_powerup_options() -> Array:
	var pool: Array = Constants.POWERUP_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, Constants.POWERUP_CARDS_PER_LEVEL)

func _on_powerup_selected(_powerup_id: StringName) -> void:
	_state = GameState.PLAYING
