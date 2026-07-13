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
var _player_health: int = Constants.PLAYER_BASE_HEALTH
var _current_biome: int = 0
var _combo_kills: int = 0
var _endless_mode: bool = false
var _waves_cleared: int = 0

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.gem_collected.connect(_on_gem_collected)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.player_damaged.connect(_on_player_damaged_combo)

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
	_combo_kills = 0
	_waves_cleared = 0
	var health_bonus: int = SaveManager.get_upgrade_level(&"health") * Constants.META_HEALTH_PER_LEVEL
	_player_health = Constants.PLAYER_BASE_HEALTH + health_bonus
	_current_biome = SaveManager.get_victories() % Constants.BACKGROUND_PALETTE.size()
	EventBus.game_started.emit()

func get_current_biome() -> int:
	return _current_biome

func get_biome_spawn_mult() -> float:
	return Constants.BIOME_SPAWN_MULT[_current_biome] as float

func get_biome_speed_mult() -> float:
	return Constants.BIOME_SPEED_MULT[_current_biome] as float

func get_biome_elite_mult() -> float:
	return Constants.BIOME_ELITE_MULT[_current_biome] as float

func get_biome_boss_hp_mult() -> float:
	return Constants.BIOME_BOSS_HP_MULT[_current_biome] as float

func get_biome_gold_mult() -> float:
	return Constants.BIOME_GOLD_MULT[_current_biome] as float

func get_combo_kills() -> int:
	return _combo_kills

func get_combo_multiplier() -> float:
	if _combo_kills >= 30:
		return 4.0
	if _combo_kills >= 20:
		return 3.0
	if _combo_kills >= 10:
		return 2.0
	if _combo_kills >= 5:
		return 1.5
	return 1.0

func enable_endless_mode(v: bool) -> void:
	_endless_mode = v

func get_endless_mode() -> bool:
	return _endless_mode

func get_waves_cleared() -> int:
	return _waves_cleared

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
	gold_mult *= WeeklyChallengeManager.get_gold_mult()
	gold_mult *= get_biome_gold_mult()
	return int(float(_score) * Constants.GOLD_PER_SCORE_POINT * gold_mult)

func _on_player_died() -> void:
	_state = GameState.GAME_OVER
	var gold: int = _calc_gold()
	if gold > 0:
		EventBus.gold_earned.emit(gold)
	EventBus.game_over.emit(_score, _session_time)

func _on_player_health_changed(current: int, _maximum: int) -> void:
	_player_health = current

func _trigger_victory() -> void:
	_state = GameState.GAME_WON
	var gold: int = _calc_gold()
	gold += _player_health * Constants.GOLD_PER_HEART_KEPT
	if gold > 0:
		EventBus.gold_earned.emit(gold)
	EventBus.game_won.emit(_score, _session_time)

func _on_boss_defeated(_boss_id: int) -> void:
	if _state != GameState.PLAYING:
		return
	if _endless_mode:
		_waves_cleared += 1
		EventBus.wave_started.emit(_waves_cleared)
	else:
		_trigger_victory()

func _on_enemy_destroyed(_enemy_id: int, _pos: Vector2, _xp: int) -> void:
	if _state != GameState.PLAYING:
		return
	var prev_mult: float = get_combo_multiplier()
	_combo_kills += 1
	var new_mult: float = get_combo_multiplier()
	if new_mult != prev_mult or _combo_kills == 1:
		EventBus.combo_changed.emit(_combo_kills, new_mult)

func _on_player_damaged_combo() -> void:
	if _combo_kills > 0:
		_combo_kills = 0
		EventBus.combo_changed.emit(0, 1.0)

func _on_gem_collected(xp_value: int) -> void:
	if _state != GameState.PLAYING:
		return
	var luck_level: int = SaveManager.get_upgrade_level(&"luck")
	var luck_mult: float = 1.0 + float(luck_level) * Constants.META_LUCK_PER_LEVEL
	var effective_xp: int = int(float(xp_value) * luck_mult * get_combo_multiplier())
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
	EventBus.player_level_up.emit(_current_level)
	EventBus.powerup_selection_requested.emit(_pick_powerup_options())

func _pick_powerup_options() -> Array:
	var pool: Array = Constants.POWERUP_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, Constants.POWERUP_CARDS_PER_LEVEL)
