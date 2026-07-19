class_name EnemySpawner
extends Node2D
## Spawns enemies on a timer with increasing difficulty.
## Activates on game_started, pauses on level_up, stops on game_over.
## Also handles EnemyTank split by instantiating basic enemies.
##
## Assign the three enemy scenes in the inspector.

@export var basic_scene: PackedScene
@export var tank_scene: PackedScene
@export var zigzag_scene: PackedScene
@export var boss_scene: PackedScene
@export var elite_scene: PackedScene

var _active: bool = false
var _spawn_timer: float = 0.0
var _spawn_interval: float = Constants.SPAWNER_INITIAL_INTERVAL
var _wave_size: int = 1
var _elapsed: float = 0.0
var _boss_timer: float = Constants.BOSS_SPAWN_INTERVAL
var _boss_alive: bool = false
var _boss_generation: int = 0
var _boss_warning_emitted: bool = false
var _challenge_spawn_mult: float = 1.0
var _challenge_elite_mult: float = 1.0
var _biome_spawn_mult: float = 1.0
var _biome_elite_mult: float = 1.0
var _biome_speed_mult: float = 1.0
var _player_level: int = 0

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(func(_s: int, _d: float): _active = false)
	EventBus.game_won.connect(func(_s: int, _d: float): _active = false)
	EventBus.enemy_split_requested.connect(_on_enemy_split_requested)
	EventBus.boss_defeated.connect(func(_id: int): _boss_alive = false)
	EventBus.player_level_up.connect(func(lvl: int): _player_level = lvl)

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_wave()
		_update_difficulty()
	_boss_timer -= delta
	if not _boss_alive and not _boss_warning_emitted and _boss_timer <= 5.0:
		_boss_warning_emitted = true
		EventBus.boss_incoming.emit()
	if _boss_timer <= 0.0 and not _boss_alive:
		_boss_timer = Constants.BOSS_SPAWN_INTERVAL
		_boss_warning_emitted = false
		_spawn_boss()

func _on_game_started() -> void:
	_active = true
	_elapsed = 0.0
	_spawn_timer = 0.0
	_spawn_interval = Constants.SPAWNER_INITIAL_INTERVAL
	_wave_size = 1
	_boss_timer = Constants.BOSS_SPAWN_INTERVAL
	_boss_alive = false
	_boss_warning_emitted = false
	_player_level = 0
	_challenge_spawn_mult = WeeklyChallengeManager.get_spawn_rate_mult()
	_challenge_elite_mult = WeeklyChallengeManager.get_elite_chance_mult()
	var biome: int = GameManager.get_current_biome()
	_biome_spawn_mult = Constants.BIOME_SPAWN_MULT[biome]
	_biome_elite_mult = Constants.BIOME_ELITE_MULT[biome]
	_biome_speed_mult = Constants.BIOME_SPEED_MULT[biome]

func _spawn_wave() -> void:
	for _i: int in _wave_size:
		_instantiate_at_random_x(_pick_scene())

func _pick_scene() -> PackedScene:
	var elite_ready: bool = (
		elite_scene != null
		and _elapsed >= Constants.SPAWNER_ELITE_UNLOCK_TIME
		and _player_level >= 2
	)
	var elite_chance: float = (
		Constants.SPAWNER_ELITE_CHANCE * _challenge_elite_mult * _biome_elite_mult
	)
	if elite_ready and randf() < minf(1.0, elite_chance):
		return elite_scene
	if (
		_elapsed >= Constants.SPAWNER_TANK_UNLOCK_TIME
		and _player_level >= 2
		and randf() < Constants.SPAWNER_TANK_CHANCE
	):
		return tank_scene
	if (
		_elapsed >= Constants.SPAWNER_ZIGZAG_UNLOCK_TIME
		and _player_level >= 1
		and randf() < Constants.SPAWNER_ZIGZAG_CHANCE
	):
		return zigzag_scene
	return basic_scene

func _instantiate_at_random_x(scene: PackedScene) -> void:
	if scene == null:
		push_error("EnemySpawner: scene not assigned")
		return
	var enemy: Node2D = scene.instantiate()
	var vp_width: float = get_viewport_rect().size.x
	enemy.position = Vector2(randf_range(30.0, vp_width - 30.0), -30.0)
	enemy.set(&"_speed_mult", _biome_speed_mult)
	var minutes: float = _elapsed / 60.0
	var hp_mult: float = 1.0 + minutes * Constants.ENEMY_HP_SCALE_PER_MIN
	enemy.set(&"_hp_time_mult", hp_mult)
	get_parent().add_child(enemy)

func _update_difficulty() -> void:
	var minutes: float = _elapsed / 60.0
	_spawn_interval = maxf(
		Constants.SPAWNER_MIN_INTERVAL,
		Constants.SPAWNER_INITIAL_INTERVAL - minutes * Constants.SPAWNER_INTERVAL_DECREASE_PER_MIN
	) * _challenge_spawn_mult * _biome_spawn_mult
	_wave_size = mini(1 + int(_elapsed / Constants.SPAWNER_WAVE_RAMP_INTERVAL), 3)

func _spawn_boss() -> void:
	if boss_scene == null:
		return
	var boss: Node2D = boss_scene.instantiate()
	boss.set(&"_generation", SaveManager.get_victories())
	var vp: Vector2 = get_viewport_rect().size
	boss.position = Vector2(vp.x * 0.5, vp.y * Constants.BOSS_Y_RATIO)
	get_parent().add_child(boss)
	_spawn_boss_guards(vp)
	_boss_alive = true
	_boss_generation += 1
	EventBus.boss_spawned.emit(boss.get_instance_id())

func _spawn_boss_guards(vp: Vector2) -> void:
	var count: int = mini(
		Constants.BOSS_GUARD_BASE + _boss_generation * Constants.BOSS_GUARD_PER_GEN,
		Constants.BOSS_GUARD_MAX
	)
	var guard_y: float = vp.y * Constants.BOSS_Y_RATIO + 40.0
	for i: int in count:
		var guard: Node2D = basic_scene.instantiate()
		var t: float = (float(i) + 0.5) / float(count)
		guard.position = Vector2(t * vp.x, guard_y)
		guard.set(&"_speed_mult", _biome_speed_mult)
		get_parent().add_child(guard)

func _on_enemy_split_requested(spawn_position: Vector2, count: int) -> void:
	for i: int in count:
		var angle: float = (float(i) / float(count)) * TAU
		var offset := Vector2(cos(angle), sin(angle)) * 25.0
		var basic: Node2D = basic_scene.instantiate()
		basic.position = spawn_position + offset
		get_parent().call_deferred(&"add_child", basic)
