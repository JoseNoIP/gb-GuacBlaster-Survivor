extends GutTest
## Tests for HeartDrop pickup behavior and Player healing.

# ── HeartDrop ──

var _drop: Area2D
var _player: Player

func before_each() -> void:
	var scene := load("res://src/features/player/HeartDrop.tscn") as PackedScene
	_drop = scene.instantiate() as Area2D
	add_child_autofree(_drop)

func test_heart_drop_instantiates() -> void:
	assert_not_null(_drop)

func test_heart_drop_collision_layer_is_8() -> void:
	assert_eq(_drop.collision_layer, 8)

func test_heart_drop_collision_mask_is_1() -> void:
	assert_eq(_drop.collision_mask, 1)

func test_body_entered_by_player_emits_heart_collected() -> void:
	watch_signals(EventBus)
	var fake_player := CharacterBody2D.new()
	fake_player.add_to_group(&"player")
	add_child_autofree(fake_player)
	_drop._on_body_entered(fake_player)
	assert_signal_emitted(EventBus, "heart_collected")

func test_body_entered_by_non_player_does_not_emit() -> void:
	watch_signals(EventBus)
	var enemy := CharacterBody2D.new()
	enemy.add_to_group(&"enemies")
	add_child_autofree(enemy)
	_drop._on_body_entered(enemy)
	assert_signal_not_emitted(EventBus, "heart_collected")

# ── Player healing ──

func _make_player() -> Player:
	var p := Player.new()
	var timer := Timer.new()
	timer.name = "AutofireTimer"
	p.add_child(timer)
	var spawn := Marker2D.new()
	spawn.name = "ProjectileSpawnPoint"
	p.add_child(spawn)
	add_child_autofree(p)
	return p

func test_heart_collected_heals_damaged_player() -> void:
	_player = _make_player()
	_player.take_damage(1)
	var hp_before: int = _player.get_health()
	EventBus.heart_collected.emit()
	assert_eq(_player.get_health(), hp_before + 1)

func test_heart_collected_does_not_overheal() -> void:
	_player = _make_player()
	EventBus.heart_collected.emit()
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH)

func test_heart_collected_emits_health_changed_when_damaged() -> void:
	_player = _make_player()
	_player.take_damage(1)
	watch_signals(EventBus)
	EventBus.heart_collected.emit()
	assert_signal_emitted(EventBus, "player_health_changed")

func test_heart_collected_does_not_emit_health_changed_at_full_hp() -> void:
	_player = _make_player()
	watch_signals(EventBus)
	EventBus.heart_collected.emit()
	assert_signal_not_emitted(EventBus, "player_health_changed")
