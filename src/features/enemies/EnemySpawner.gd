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

var _active: bool = false
var _spawn_timer: float = 0.0
var _spawn_interval: float = Constants.SPAWNER_INITIAL_INTERVAL
var _elapsed: float = 0.0
var _boss_timer: float = Constants.BOSS_SPAWN_INTERVAL
var _boss_alive: bool = false
var _boss_generation: int = 0
var _boss_warning_emitted: bool = false

func _ready() -> void:
	EventBus.game_started.connect(func(): _active = true)
	EventBus.game_over.connect(func(_s: int, _d: float): _active = false)
	EventBus.game_won.connect(func(_s: int, _d: float): _active = false)
	EventBus.enemy_split_requested.connect(_on_enemy_split_requested)
	EventBus.boss_defeated.connect(func(_id: int): _boss_alive = false)

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

func _spawn_wave() -> void:
	_instantiate_at_random_x(_pick_scene())

func _pick_scene() -> PackedScene:
	if _elapsed >= Constants.SPAWNER_TANK_UNLOCK_TIME and randf() < Constants.SPAWNER_TANK_CHANCE:
		return tank_scene
	if _elapsed >= Constants.SPAWNER_ZIGZAG_UNLOCK_TIME and randf() < Constants.SPAWNER_ZIGZAG_CHANCE:
		return zigzag_scene
	return basic_scene

func _instantiate_at_random_x(scene: PackedScene) -> void:
	if scene == null:
		push_error("EnemySpawner: scene not assigned")
		return
	var enemy: Node2D = scene.instantiate()
	var vp_width: float = get_viewport_rect().size.x
	enemy.position = Vector2(randf_range(30.0, vp_width - 30.0), -30.0)
	get_parent().add_child(enemy)

func _update_difficulty() -> void:
	var minutes: float = _elapsed / 60.0
	_spawn_interval = maxf(
		Constants.SPAWNER_MIN_INTERVAL,
		Constants.SPAWNER_INITIAL_INTERVAL - minutes * Constants.SPAWNER_INTERVAL_DECREASE_PER_MIN
	)

func _spawn_boss() -> void:
	if boss_scene == null:
		return
	var boss: Node2D = boss_scene.instantiate()
	boss.set(&"_generation", _boss_generation)
	var vp_width: float = get_viewport_rect().size.x
	boss.position = Vector2(vp_width * 0.5, 60.0)
	get_parent().add_child(boss)
	_boss_alive = true
	_boss_generation += 1
	EventBus.boss_spawned.emit(boss.get_instance_id())

func _on_enemy_split_requested(spawn_position: Vector2, count: int) -> void:
	for i: int in count:
		var angle: float = (float(i) / float(count)) * TAU
		var offset := Vector2(cos(angle), sin(angle)) * 25.0
		var basic: Node2D = basic_scene.instantiate()
		basic.position = spawn_position + offset
		get_parent().call_deferred(&"add_child", basic)
