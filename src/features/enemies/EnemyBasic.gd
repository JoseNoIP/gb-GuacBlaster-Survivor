class_name EnemyBasic
extends "res://src/features/enemies/EnemyBase.gd"
## Basic bubble enemy. Descends in a straight line. 1 HP.

func _initialize() -> void:
	_health = Constants.ENEMY_BASIC_HP
	_xp_value = Constants.ENEMY_BASIC_XP

func _move(_delta: float) -> void:
	velocity = Vector2(0.0, Constants.ENEMY_BASIC_SPEED)
