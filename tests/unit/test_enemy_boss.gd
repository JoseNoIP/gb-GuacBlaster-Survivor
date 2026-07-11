extends GutTest
## Tests for EnemyBoss: group membership, HP scaling, damage, death signals.

const EnemyBossGd := preload("res://src/features/enemies/EnemyBoss.gd")

var _boss: Node

func before_each() -> void:
	_boss = EnemyBossGd.new()
	add_child_autofree(_boss)

func test_boss_in_enemies_group() -> void:
	assert_true(_boss.is_in_group(&"enemies"))

func test_boss_generation_zero_starts_with_base_hp() -> void:
	assert_eq(_boss.get_health(), Constants.BOSS_HP_BASE)

func test_boss_take_damage_reduces_health() -> void:
	_boss.take_damage(5)
	assert_eq(_boss.get_health(), Constants.BOSS_HP_BASE - 5)

func test_boss_health_clamps_to_zero() -> void:
	_boss.take_damage(Constants.BOSS_HP_BASE + 99)
	assert_eq(_boss.get_health(), 0)

func test_boss_death_emits_boss_defeated() -> void:
	watch_signals(EventBus)
	_boss.take_damage(Constants.BOSS_HP_BASE)
	assert_signal_emitted(EventBus, "boss_defeated")

func test_boss_death_emits_enemy_destroyed() -> void:
	watch_signals(EventBus)
	_boss.take_damage(Constants.BOSS_HP_BASE)
	assert_signal_emitted(EventBus, "enemy_destroyed")

func test_non_lethal_damage_does_not_emit_boss_defeated() -> void:
	watch_signals(EventBus)
	_boss.take_damage(1)
	assert_signal_not_emitted(EventBus, "boss_defeated")

func test_generation_one_has_more_hp() -> void:
	var boss_gen1: Node = EnemyBossGd.new()
	boss_gen1.set(&"_generation", 1)
	add_child_autofree(boss_gen1)
	var expected_hp: int = Constants.BOSS_HP_BASE + Constants.BOSS_HP_PER_GENERATION
	assert_eq(boss_gen1.get_health(), expected_hp)

func test_generation_scales_hp_correctly() -> void:
	var boss_gen3: Node = EnemyBossGd.new()
	boss_gen3.set(&"_generation", 3)
	add_child_autofree(boss_gen3)
	var expected_hp: int = Constants.BOSS_HP_BASE + 3 * Constants.BOSS_HP_PER_GENERATION
	assert_eq(boss_gen3.get_health(), expected_hp)
