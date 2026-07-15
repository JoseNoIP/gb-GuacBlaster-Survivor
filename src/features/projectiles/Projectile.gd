class_name Projectile
extends Area2D
## Single projectile fired by the player.
## Moves in _direction at _speed px/s. Handles pierce (super_guac) and bounce (spicy_bounce).
##
## Required child nodes:
##   CollisionShape2D (CollisionShape2D)
##   VisibleOnScreenNotifier2D — connected to _on_screen_exited
##
## Collision layer: 3 (player projectiles). Mask: 2 (enemies).

var _speed: float = 400.0
var _direction: Vector2 = Vector2.UP
var _damage: float = Constants.PLAYER_BASE_DAMAGE
var _pierce_remaining: int = 0
var _bouncy: bool = false

func _physics_process(delta: float) -> void:
	position += _direction.normalized() * _speed * delta
	if _bouncy:
		_check_bounce()

func setup(damage: float, direction: Vector2, pierce_count: int = 0, bouncy: bool = false) -> void:
	_damage = damage
	_direction = direction
	_pierce_remaining = pierce_count
	_bouncy = bouncy

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"enemies"):
		return
	EventBus.projectile_hit_enemy.emit(body.get_instance_id(), _damage)
	EventBus.enemy_hit.emit(global_position)
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

func _check_bounce() -> void:
	_bounce_at_width(get_viewport_rect().size.x)

func _bounce_at_width(vp_width: float) -> void:
	if position.x <= 0.0:
		_direction.x = absf(_direction.x)
		position.x = 0.0
	elif position.x >= vp_width:
		_direction.x = -absf(_direction.x)
		position.x = vp_width

func setup_visuals(tint: Color, scale_mult: float) -> void:
	scale = Vector2(scale_mult, scale_mult)
	var spr := get_node_or_null(^"Sprite2D") as Node2D
	if spr != null:
		spr.modulate = tint

func get_damage() -> float:
	return _damage

func get_pierce_remaining() -> int:
	return _pierce_remaining
