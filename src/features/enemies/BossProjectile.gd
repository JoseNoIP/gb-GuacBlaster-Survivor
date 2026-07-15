class_name BossProjectile
extends Area2D
## Slow projectile fired by the boss. Phase 1: straight down. Phase 2: directional spread.
## Set _velocity before adding to tree to override the default downward direction.

var _velocity: Vector2 = Vector2(0.0, Constants.BOSS_PROJECTILE_SPEED)

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
	position += _velocity * delta
	var vp: Rect2 = get_viewport_rect()
	if (position.y > vp.size.y + 40.0 or position.y < -40.0
			or position.x < -40.0 or position.x > vp.size.x + 40.0):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and body.has_method(&"take_damage"):
		body.call(&"take_damage", Constants.BOSS_PROJECTILE_DAMAGE)
	queue_free()
