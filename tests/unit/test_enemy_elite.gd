extends GutTest
## Tests for EnemyElite: HP multiplier, XP multiplier, power-up drop on death.

const EnemyEliteGd := preload("res://src/features/enemies/EnemyElite.gd")

var _elite: Node

func before_each() -> void:
	_elite = EnemyEliteGd.new()
	add_child_autofree(_elite)

func test_elite_in_enemies_group() -> void:
	assert_true(_elite.is_in_group(&"enemies"))

func test_elite_hp_is_triple_basic() -> void:
	assert_eq(_elite.get_health(), Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER)

func test_elite_hp_is_three() -> void:
	assert_eq(_elite.get_health(), 3)

func test_elite_take_one_damage_survives() -> void:
	_elite.take_damage(1)
	assert_eq(_elite.get_health(), 2)

func test_elite_take_damage_reduces_health() -> void:
	_elite.take_damage(2)
	assert_eq(_elite.get_health(), 1)

func test_elite_death_emits_elite_powerup_dropped() -> void:
	watch_signals(EventBus)
	_elite.take_damage(Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER)
	assert_signal_emitted(EventBus, "elite_powerup_dropped")

func test_elite_death_emits_enemy_destroyed() -> void:
	watch_signals(EventBus)
	_elite.take_damage(Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER)
	assert_signal_emitted(EventBus, "enemy_destroyed")

func test_elite_powerup_dropped_has_valid_pool_id() -> void:
	watch_signals(EventBus)
	_elite.take_damage(Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER)
	var params: Array = get_signal_parameters(EventBus, "elite_powerup_dropped")
	assert_true(Constants.POWERUP_POOL.has(params[1]))

func test_non_lethal_damage_no_drop() -> void:
	watch_signals(EventBus)
	_elite.take_damage(1)
	assert_signal_not_emitted(EventBus, "elite_powerup_dropped")

func test_elite_health_clamps_to_zero() -> void:
	_elite.take_damage(999)
	assert_eq(_elite.get_health(), 0)
