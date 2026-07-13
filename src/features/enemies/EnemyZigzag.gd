class_name EnemyZigzag
extends "res://src/features/enemies/EnemyBase.gd"
## Nacho fly. Fast diagonal zigzag movement.

var _time: float = 0.0

func _initialize() -> void:
	_health = Constants.ENEMY_ZIGZAG_HP
	_xp_value = Constants.ENEMY_ZIGZAG_XP

func _move(delta: float) -> void:
	_time += delta
	var h_vel: float = (
		cos(_time * Constants.ENEMY_ZIGZAG_FREQUENCY * TAU)
		* Constants.ENEMY_ZIGZAG_AMPLITUDE
	)
	velocity = Vector2(h_vel, Constants.ENEMY_ZIGZAG_SPEED)
