class_name BossProjectile
extends Area2D
## Slow downward projectile fired by the boss. Damages the player on contact.

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	var dot: ColorRect = ColorRect.new()
	dot.size = Vector2(16.0, 16.0)
	dot.position = Vector2(-8.0, -8.0)
	dot.color = Color(0.9, 0.1, 0.5)
	add_child(dot)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.y += Constants.BOSS_PROJECTILE_SPEED * delta
	if position.y > get_viewport_rect().size.y + 20.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and body.has_method(&"take_damage"):
		body.call(&"take_damage", Constants.BOSS_PROJECTILE_DAMAGE)
	queue_free()
