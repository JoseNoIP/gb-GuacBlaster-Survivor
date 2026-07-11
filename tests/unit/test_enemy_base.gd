extends GutTest
## Unit tests for EnemyBasic (concrete implementation of EnemyBase).

# Preloads force EnemyBase.gd to load first, registering its class_name.
const EnemyBasicGd := preload("res://src/features/enemies/EnemyBasic.gd")

var _enemy: EnemyBasic

func before_each() -> void:
	_enemy = EnemyBasic.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var shape_res := CircleShape2D.new()
	shape_res.radius = 12.0
	shape.shape = shape_res
	_enemy.add_child(shape)
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.name = "VisibleOnScreenNotifier2D"
	_enemy.add_child(notifier)
	add_child_autofree(_enemy)

# --- Group ---

func test_enemy_is_in_enemies_group() -> void:
	assert_true(_enemy.is_in_group(&"enemies"))

# --- Health ---

func test_initial_health_equals_basic_hp_constant() -> void:
	assert_eq(_enemy.get_health(), Constants.ENEMY_BASIC_HP)

func test_take_damage_reduces_health() -> void:
	_enemy._health = 3
	_enemy.take_damage(1)
	assert_eq(_enemy.get_health(), 2)

func test_take_damage_clamps_to_zero() -> void:
	_enemy.take_damage(999)
	assert_eq(_enemy.get_health(), 0)

func test_take_damage_zero_has_no_effect() -> void:
	_enemy.take_damage(0)
	assert_eq(_enemy.get_health(), Constants.ENEMY_BASIC_HP)

# --- Death ---

func test_lethal_damage_emits_enemy_destroyed() -> void:
	watch_signals(EventBus)
	_enemy.take_damage(Constants.ENEMY_BASIC_HP)
	assert_signal_emitted(EventBus, "enemy_destroyed")

func test_non_lethal_damage_does_not_emit_enemy_destroyed() -> void:
	_enemy._health = 3
	watch_signals(EventBus)
	_enemy.take_damage(1)
	assert_signal_not_emitted(EventBus, "enemy_destroyed")

func test_enemy_destroyed_carries_correct_xp() -> void:
	watch_signals(EventBus)
	_enemy.take_damage(Constants.ENEMY_BASIC_HP)
	assert_signal_emitted_with_parameters(
		EventBus,
		"enemy_destroyed",
		[_enemy.get_instance_id(), Vector2.ZERO, Constants.ENEMY_BASIC_XP]
	)

# --- Screen exit ---

func test_on_screen_exited_marks_for_deletion() -> void:
	_enemy._on_screen_exited()
	assert_true(_enemy.is_queued_for_deletion())
