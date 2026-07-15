class_name EnemyTank
extends "res://src/features/enemies/EnemyBase.gd"
## Tank bubble. High HP, slow. Splits into N basics on death.

func _initialize() -> void:
	_health = Constants.ENEMY_TANK_HP
	_xp_value = Constants.ENEMY_TANK_XP

func _move(_delta: float) -> void:
	velocity = Vector2(0.0, Constants.ENEMY_TANK_SPEED)

func _die() -> void:
	EventBus.enemy_split_requested.emit(global_position, Constants.ENEMY_TANK_SPLIT_COUNT)
	super._die()

func on_player_contact(player: Node2D) -> void:
	EventBus.enemy_split_requested.emit(global_position, Constants.ENEMY_TANK_SPLIT_COUNT)
	if player.has_method(&"take_damage"):
		player.call(&"take_damage", 1)
	_contact_die()
