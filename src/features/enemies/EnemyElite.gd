class_name EnemyElite
extends "res://src/features/enemies/EnemyBasic.gd"
## Elite variant of the basic enemy. 3× HP, 5× XP, drops a random power-up on death.
## Visually distinguished by a gold modulate applied in _ready().

func _initialize() -> void:
	_health = Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER
	_xp_value = Constants.ENEMY_BASIC_XP * Constants.ENEMY_ELITE_XP_MULTIPLIER

func _ready() -> void:
	super._ready()
	modulate = Color(1.0, 0.85, 0.15)

func _die() -> void:
	var idx: int = randi() % Constants.POWERUP_POOL.size()
	EventBus.elite_powerup_dropped.emit(global_position, Constants.POWERUP_POOL[idx] as StringName)
	super._die()
