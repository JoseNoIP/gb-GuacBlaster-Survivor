class_name EnemyBoss
extends "res://src/features/enemies/EnemyBase.gd"
## Boss enemy. Moves horizontally at the top of the screen and fires slow
## projectiles toward the player. Emits boss_defeated on death.

const BossProjectileGd := preload("res://src/features/enemies/BossProjectile.gd")

var _generation: int = 0
var _direction: float = 1.0
var _fire_timer: float = 0.0
var _max_health: int = 0

func _initialize() -> void:
	_health = Constants.BOSS_HP_BASE + _generation * Constants.BOSS_HP_PER_GENERATION
	_max_health = _health
	_xp_value = Constants.BOSS_XP
	_fire_timer = maxf(
		Constants.BOSS_FIRE_INTERVAL_MIN,
		Constants.BOSS_FIRE_INTERVAL - _generation * Constants.BOSS_FIRE_INTERVAL_DECREASE
	)

func _move(delta: float) -> void:
	var vp_width: float = get_viewport_rect().size.x
	velocity = Vector2(_direction * Constants.BOSS_SPEED, 0.0)
	move_and_slide()
	if position.x <= 40.0:
		_direction = 1.0
	elif position.x >= vp_width - 40.0:
		_direction = -1.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = Constants.BOSS_FIRE_INTERVAL
		_fire()

func _fire() -> void:
	var proj: Area2D = BossProjectileGd.new()
	proj.position = global_position
	get_parent().call_deferred(&"add_child", proj)

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	EventBus.boss_health_changed.emit(_health, _max_health)

func _die() -> void:
	EventBus.boss_defeated.emit(get_instance_id())
	super._die()
