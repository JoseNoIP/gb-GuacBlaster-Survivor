extends GutTest
## Unit tests for EnemyTank split-on-death mechanic.

# Preload forces EnemyBase → EnemyTank load chain, registering class_names.
const EnemyTankGd := preload("res://src/features/enemies/EnemyTank.gd")

var _tank: EnemyTank

func before_each() -> void:
	_tank = EnemyTank.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var shape_res := CircleShape2D.new()
	shape_res.radius = 24.0
	shape.shape = shape_res
	_tank.add_child(shape)
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.name = "VisibleOnScreenNotifier2D"
	_tank.add_child(notifier)
	add_child_autofree(_tank)

# --- Stats ---

func test_tank_health_higher_than_basic() -> void:
	assert_gt(_tank.get_health(), Constants.ENEMY_BASIC_HP)

func test_tank_health_equals_constant() -> void:
	assert_eq(_tank.get_health(), Constants.ENEMY_TANK_HP)

func test_tank_xp_equals_constant() -> void:
	assert_eq(_tank._xp_value, Constants.ENEMY_TANK_XP)

func test_tank_xp_higher_than_basic() -> void:
	assert_gt(_tank._xp_value, Constants.ENEMY_BASIC_XP)

# --- Split ---

func test_death_emits_enemy_split_requested() -> void:
	watch_signals(EventBus)
	_tank.take_damage(Constants.ENEMY_TANK_HP)
	assert_signal_emitted(EventBus, "enemy_split_requested")

func test_split_carries_correct_count() -> void:
	watch_signals(EventBus)
	_tank.take_damage(Constants.ENEMY_TANK_HP)
	assert_signal_emitted_with_parameters(
		EventBus,
		"enemy_split_requested",
		[Vector2.ZERO, Constants.ENEMY_TANK_SPLIT_COUNT]
	)

func test_death_also_emits_enemy_destroyed() -> void:
	watch_signals(EventBus)
	_tank.take_damage(Constants.ENEMY_TANK_HP)
	assert_signal_emitted(EventBus, "enemy_destroyed")

# --- Partial damage (tank survives) ---

func test_partial_damage_does_not_split() -> void:
	watch_signals(EventBus)
	_tank.take_damage(1)
	assert_signal_not_emitted(EventBus, "enemy_split_requested")

func test_partial_damage_reduces_health() -> void:
	_tank.take_damage(2)
	assert_eq(_tank.get_health(), Constants.ENEMY_TANK_HP - 2)
