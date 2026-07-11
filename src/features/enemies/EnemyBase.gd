class_name EnemyBase
extends CharacterBody2D
## Base class for all enemies. Subclasses override _initialize() and _move().
##
## Required child nodes (set in each .tscn):
##   CollisionShape2D
##   VisibleOnScreenNotifier2D  — connects screen_exited → _on_screen_exited
##
## Collision layer: 2 (enemies). Mask: 1 (player, for contact damage — future).

var _health: int = 1
var _xp_value: int = 5

func _ready() -> void:
	add_to_group(&"enemies")
	_initialize()

func _initialize() -> void:
	pass

func _physics_process(delta: float) -> void:
	_move(delta)

func _move(_delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	_health = maxi(_health - amount, 0)
	if _health == 0:
		_die()

func get_health() -> int:
	return _health

func _die() -> void:
	EventBus.enemy_destroyed.emit(get_instance_id(), global_position, _xp_value)
	queue_free()

func _on_screen_exited() -> void:
	queue_free()
