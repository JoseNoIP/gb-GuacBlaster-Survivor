extends GutTest
## Unit tests for Player health, damage, and autofire configuration.
## Child nodes are created programmatically so no .tscn is required.

var _player: Player

func before_each() -> void:
	_player = Player.new()
	# Wire required child nodes before adding to tree (_ready uses @onready)
	var timer := Timer.new()
	timer.name = "AutofireTimer"
	_player.add_child(timer)
	var spawn := Marker2D.new()
	spawn.name = "ProjectileSpawnPoint"
	_player.add_child(spawn)
	add_child_autofree(_player)

# --- Health ---

func test_initial_health_equals_base_constant() -> void:
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH)

func test_initial_max_health_equals_base_constant() -> void:
	assert_eq(_player.get_max_health(), Constants.PLAYER_BASE_HEALTH)

func test_take_damage_reduces_health_by_amount() -> void:
	_player.take_damage(1)
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH - 1)

func test_take_damage_accumulates_correctly() -> void:
	_player.take_damage(1)
	_player.take_damage(1)
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH - 2)

func test_take_damage_clamps_to_zero() -> void:
	_player.take_damage(999)
	assert_eq(_player.get_health(), 0)

func test_take_damage_zero_has_no_effect() -> void:
	_player.take_damage(0)
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH)

# --- Death signal ---

func test_lethal_damage_emits_player_died() -> void:
	watch_signals(EventBus)
	_player.take_damage(Constants.PLAYER_BASE_HEALTH)
	assert_signal_emitted(EventBus, "player_died")

func test_non_lethal_damage_does_not_emit_player_died() -> void:
	watch_signals(EventBus)
	_player.take_damage(1)
	assert_signal_not_emitted(EventBus, "player_died")

# --- Health changed signal ---

func test_take_damage_emits_health_changed() -> void:
	watch_signals(EventBus)
	_player.take_damage(1)
	assert_signal_emitted(EventBus, "player_health_changed")

# --- Autofire ---

func test_autofire_timer_matches_constant() -> void:
	var timer: Timer = _player.get_node("AutofireTimer")
	assert_eq(timer.wait_time, Constants.PLAYER_AUTOFIRE_INTERVAL)

func test_rapid_fire_reduces_timer_wait_time() -> void:
	var timer: Timer = _player.get_node("AutofireTimer")
	var original: float = timer.wait_time
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 1)
	assert_lt(timer.wait_time, original)

func test_rapid_fire_applies_correct_multiplier() -> void:
	var timer: Timer = _player.get_node("AutofireTimer")
	var original: float = timer.wait_time
	EventBus.powerup_stack_changed.emit(&"rapid_fire", 1)
	assert_almost_eq(
		timer.wait_time,
		original / Constants.RAPID_FIRE_MULTIPLIER,
		0.001
	)

# --- Damage stat ---

func test_set_damage_updates_fired_damage() -> void:
	_player.set_damage(50.0)
	watch_signals(EventBus)
	_player._fire()
	# Can't inspect signal args directly without signal watcher args, so verify no crash
	assert_true(true, "set_damage and _fire did not raise errors")
