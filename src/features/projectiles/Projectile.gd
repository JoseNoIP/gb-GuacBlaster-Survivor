class_name Projectile
extends Area2D
## Single projectile fired by the player.
## Moves in _direction at _speed px/s. Handles pierce (Súper-Guac power-up).
##
## Required child nodes:
##   CollisionShape2D (CollisionShape2D)
##   VisibleOnScreenNotifier2D — call _on_screen_exited on screen_exited signal
##
## Collision layer: 3 (player projectiles). Mask: 2 (enemies).

var _speed: float = 400.0
var _direction: Vector2 = Vector2.UP
var _damage: float = Constants.PLAYER_BASE_DAMAGE
var _pierce_remaining: int = 0

func _physics_process(delta: float) -> void:
	position += _direction.normalized() * _speed * delta

func setup(damage: float, direction: Vector2, pierce_count: int = 0) -> void:
	_damage = damage
	_direction = direction
	_pierce_remaining = pierce_count

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"enemies"):
		return
	EventBus.projectile_hit_enemy.emit(body.get_instance_id(), _damage)
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", int(_damage))
	_consume_pierce()

func _on_screen_exited() -> void:
	queue_free()

func _consume_pierce() -> void:
	if _pierce_remaining <= 0:
		queue_free()
	else:
		_pierce_remaining -= 1

func get_damage() -> float:
	return _damage

func get_pierce_remaining() -> int:
	return _pierce_remaining
