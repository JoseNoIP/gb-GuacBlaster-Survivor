extends GutTest
## Tests for power-up effects: Player (rapid_fire, nacho_wall),
## ProjectileSpawner (super_guac, spicy_bounce), Projectile (bounce logic).

const ProjectileGd := preload("res://src/features/projectiles/Projectile.gd")
const ProjectileSpawnerGd := preload("res://src/features/projectiles/ProjectileSpawner.gd")
const PlayerGd := preload("res://src/features/player/Player.gd")

var _player: Player
var _spawner: ProjectileSpawner
var _proj: Projectile

func before_each() -> void:
	_player = _make_player()
	_spawner = ProjectileSpawner.new()
	add_child_autofree(_spawner)
	_proj = Projectile.new()
	add_child_autofree(_proj)

func _make_player() -> Player:
	var p := Player.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15.0
	capsule.height = 30.0
	shape.shape = capsule
	p.add_child(shape)
	var timer := Timer.new()
	timer.name = "AutofireTimer"
	p.add_child(timer)
	var marker := Marker2D.new()
	marker.name = "ProjectileSpawnPoint"
	p.add_child(marker)
	add_child_autofree(p)
	return p

# --- Player: rapid_fire ---

func test_rapid_fire_reduces_autofire_interval() -> void:
	var initial: float = _player._current_autofire_interval
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_lt(_player._current_autofire_interval, initial)

func test_rapid_fire_applies_correct_multiplier() -> void:
	var initial: float = _player._current_autofire_interval
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_almost_eq(
		_player._current_autofire_interval,
		initial / Constants.RAPID_FIRE_MULTIPLIER,
		0.0001
	)

# --- Player: nacho_wall ---

func test_nacho_wall_absorbs_first_hit() -> void:
	EventBus.powerup_selected.emit(&"nacho_wall")
	var hp: int = _player.get_health()
	_player.take_damage(1)
	assert_eq(_player.get_health(), hp)

func test_nacho_wall_does_not_absorb_without_shield() -> void:
	var hp: int = _player.get_health()
	_player.take_damage(1)
	assert_eq(_player.get_health(), hp - 1)

func test_nacho_wall_absorbs_all_shield_hits() -> void:
	EventBus.powerup_selected.emit(&"nacho_wall")
	var hp: int = _player.get_health()
	for _i: int in Constants.NACHO_WALL_HITS:
		_player.take_damage(1)
	assert_eq(_player.get_health(), hp)

func test_nacho_wall_hp_lost_after_shield_depleted() -> void:
	EventBus.powerup_selected.emit(&"nacho_wall")
	for _i: int in Constants.NACHO_WALL_HITS:
		_player.take_damage(1)
	_player.take_damage(1)
	assert_eq(_player.get_health(), Constants.PLAYER_BASE_HEALTH - 1)

# --- ProjectileSpawner: power-up flags ---

func test_super_guac_sets_pierce_count() -> void:
	EventBus.powerup_selected.emit(&"super_guac")
	assert_eq(_spawner._pierce_count, Constants.SUPER_GUAC_PENETRATION)

func test_spicy_bounce_sets_bouncy_flag() -> void:
	EventBus.powerup_selected.emit(&"spicy_bounce")
	assert_true(_spawner._bouncy)

func test_triple_shot_sets_flag() -> void:
	EventBus.powerup_selected.emit(&"triple_shot")
	assert_true(_spawner._triple_shot)

func test_unrelated_powerup_does_not_set_pierce() -> void:
	EventBus.powerup_selected.emit(&"rapid_fire")
	assert_eq(_spawner._pierce_count, 0)

# --- Projectile: setup ---

func test_setup_sets_bouncy_true() -> void:
	_proj.setup(10.0, Vector2.UP, 0, true)
	assert_true(_proj._bouncy)

func test_setup_sets_bouncy_false_by_default() -> void:
	_proj.setup(10.0, Vector2.UP)
	assert_false(_proj._bouncy)

func test_setup_sets_pierce_count() -> void:
	_proj.setup(10.0, Vector2.UP, 3)
	assert_eq(_proj.get_pierce_remaining(), 3)

# --- Projectile: bounce logic ---

func test_bounce_at_left_wall_reverses_x_direction() -> void:
	_proj.setup(10.0, Vector2(-0.7, -0.7).normalized(), 0, true)
	_proj.position = Vector2(-5.0, 200.0)
	_proj._bounce_at_width(390.0)
	assert_gt(_proj._direction.x, 0.0)

func test_bounce_at_left_wall_clamps_position() -> void:
	_proj.setup(10.0, Vector2(-1.0, 0.0), 0, true)
	_proj.position = Vector2(-5.0, 200.0)
	_proj._bounce_at_width(390.0)
	assert_eq(_proj.position.x, 0.0)

func test_bounce_at_right_wall_reverses_x_direction() -> void:
	_proj.setup(10.0, Vector2(0.7, -0.7).normalized(), 0, true)
	_proj.position = Vector2(400.0, 200.0)
	_proj._bounce_at_width(390.0)
	assert_lt(_proj._direction.x, 0.0)

func test_bounce_at_right_wall_clamps_position() -> void:
	_proj.setup(10.0, Vector2(1.0, 0.0), 0, true)
	_proj.position = Vector2(400.0, 200.0)
	_proj._bounce_at_width(390.0)
	assert_eq(_proj.position.x, 390.0)

func test_no_bounce_within_bounds() -> void:
	_proj.setup(10.0, Vector2(0.5, -0.5).normalized(), 0, true)
	_proj.position = Vector2(200.0, 200.0)
	var dir_before: Vector2 = _proj._direction
	_proj._bounce_at_width(390.0)
	assert_eq(_proj._direction, dir_before)
