class_name HeartDrop
extends Area2D
## Falling heart pickup. Heals the player by 1 HP on contact.
## Spawned by HeartDropper. Falls at HEART_DROP_SPEED and auto-frees at screen bottom.

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	_build_collision()
	_build_visual()
	body_entered.connect(_on_body_entered)

func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)

func _build_visual() -> void:
	const HEART_TEX := "res://assets/sprites/heart.png"
	if ResourceLoader.exists(HEART_TEX):
		var sprite := Sprite2D.new()
		sprite.texture = load(HEART_TEX) as Texture2D
		add_child(sprite)
	else:
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
		lbl.position = Vector2(-11.0, -16.0)
		add_child(lbl)

func _process(delta: float) -> void:
	position.y += Constants.HEART_DROP_SPEED * delta
	if position.y > get_viewport().get_visible_rect().size.y + 40.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	EventBus.heart_collected.emit()
	AudioManager.trigger_haptic_light()
	queue_free()
