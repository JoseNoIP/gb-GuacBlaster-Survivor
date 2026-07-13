class_name EnemyBoss
extends "res://src/features/enemies/EnemyBase.gd"
## Boss enemy. Moves horizontally at the top of the screen and fires projectiles.
## Phase 2 activates at 50% HP: faster movement + 3-way spread shot aimed at player.

const BossProjectileGd := preload("res://src/features/enemies/BossProjectile.gd")

var _generation: int = 0
var _direction: float = 1.0
var _fire_timer: float = 0.0
var _max_health: int = 0
var _phase: int = 1

func _initialize() -> void:
	_health = Constants.BOSS_HP_BASE + _generation * Constants.BOSS_HP_PER_GENERATION
	_max_health = _health
	_xp_value = Constants.BOSS_XP
	_phase = 1
	_fire_timer = maxf(
		Constants.BOSS_FIRE_INTERVAL_MIN,
		Constants.BOSS_FIRE_INTERVAL - _generation * Constants.BOSS_FIRE_INTERVAL_DECREASE
	)

func _move(delta: float) -> void:
	var speed: float = Constants.BOSS_SPEED
	if _phase == 2:
		speed *= Constants.BOSS_PHASE2_SPEED_MULT
	var vp_width: float = get_viewport_rect().size.x
	velocity = Vector2(_direction * speed, 0.0)
	move_and_slide()
	if position.x <= 40.0:
		_direction = 1.0
	elif position.x >= vp_width - 40.0:
		_direction = -1.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		var interval: float = Constants.BOSS_FIRE_INTERVAL
		if _phase == 2:
			interval *= Constants.BOSS_PHASE2_FIRE_MULT
		_fire_timer = maxf(Constants.BOSS_FIRE_INTERVAL_MIN, interval)
		_fire()

func _fire() -> void:
	if _phase == 1:
		_spawn_projectile(Vector2(0.0, Constants.BOSS_PROJECTILE_SPEED))
		return
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	var base_dir: Vector2 = Vector2.DOWN
	if not players.is_empty():
		base_dir = ((players[0] as Node2D).global_position - global_position).normalized()
	for i: int in Constants.BOSS_PHASE2_SPREAD_COUNT:
		var offset: float = float(i) - float(Constants.BOSS_PHASE2_SPREAD_COUNT - 1) * 0.5
		_spawn_projectile(base_dir.rotated(deg_to_rad(offset * Constants.BOSS_PHASE2_SPREAD_ANGLE))
				* Constants.BOSS_PROJECTILE_SPEED)

func _spawn_projectile(vel: Vector2) -> void:
	var proj: Area2D = BossProjectileGd.new()
	proj.position = global_position
	proj.set(&"_velocity", vel)
	get_parent().call_deferred(&"add_child", proj)

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	EventBus.boss_health_changed.emit(_health, _max_health)
	if _phase == 1 and _health > 0 and _health <= _max_health / 2:
		_phase = 2
		modulate = Color(1.0, 0.3, 0.3)
		EventBus.boss_phase_changed.emit(2)

func _die() -> void:
	EventBus.boss_defeated.emit(get_instance_id())
	super._die()
