class_name Projectile
extends Area2D
## Single projectile fired by the player.
## Moves in _direction at _speed px/s. Handles burst (chipotle_burst) and bounce (spicy_bounce).
##
## Required child nodes:
##   CollisionShape2D (CollisionShape2D)
##   VisibleOnScreenNotifier2D — connected to _on_screen_exited
##
## Collision layer: 3 (player projectiles). Mask: 2 (enemies).

var _speed: float = 400.0
var _direction: Vector2 = Vector2.UP
var _damage: float = Constants.PLAYER_BASE_DAMAGE
var _burst: bool = false
var _bouncy: bool = false

func _physics_process(delta: float) -> void:
	position += _direction.normalized() * _speed * delta
	if _bouncy:
		_check_bounce()

func setup(damage: float, direction: Vector2, burst: bool = false, bouncy: bool = false) -> void:
	_damage = damage
	_direction = direction
	_burst = burst
	_bouncy = bouncy

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"enemies"):
		return
	EventBus.projectile_hit_enemy.emit(body.get_instance_id(), _damage)
	EventBus.enemy_hit.emit(global_position)
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", int(_damage))
	if _burst:
		_explode()
	else:
		queue_free()

func _explode() -> void:
	var burst_damage: float = _damage * Constants.CHIPOTLE_BURST_DAMAGE_MULT
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = Constants.CHIPOTLE_BURST_RADIUS
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 2
	var hits: Array[Dictionary] = space.intersect_shape(params)
	for hit: Dictionary in hits:
		var body: Variant = hit.get(&"collider")
		if body is Node2D:
			var node: Node2D = body as Node2D
			if node.is_in_group(&"enemies") and node.has_method(&"take_damage"):
				node.call(&"take_damage", int(burst_damage))
	_spawn_burst_vfx()
	queue_free()

func _spawn_burst_vfx() -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.35
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 180.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.direction = Vector2.ZERO
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1.0, 0.55, 0.1, 1.0))
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	p.color_ramp = grad
	var timer: Timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(p.queue_free)
	p.add_child(timer)
	get_parent().call_deferred(&"add_child", p)

func _on_screen_exited() -> void:
	queue_free()

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

func get_burst() -> bool:
	return _burst
