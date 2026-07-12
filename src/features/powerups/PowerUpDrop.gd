class_name PowerUpDrop
extends Area2D
## Falling power-up collectible. Player walks into it to pick it up.
## Set powerup_id before adding to tree so _ready() can build the visual.

const FALL_SPEED: float = 80.0

const DROP_COLORS: Dictionary = {
	&"triple_shot":    Color(0.2, 0.55, 1.0),
	&"super_guac":     Color(0.2, 0.8, 0.3),
	&"rapid_fire":     Color(1.0, 0.7, 0.1),
	&"mole_grenade":   Color(0.65, 0.4, 0.2),
	&"jalapeno_laser": Color(1.0, 0.3, 0.1),
	&"spicy_bounce":   Color(0.8, 0.2, 0.85),
	&"nacho_wall":     Color(1.0, 0.9, 0.3),
	&"salsa_magnet":   Color(0.3, 0.9, 0.8),
	&"guac_storm":     Color(0.45, 0.9, 0.2),
}
const POWERUP_ABBREV: Dictionary = {
	&"triple_shot":    "TS",
	&"super_guac":     "SG",
	&"rapid_fire":     "RF",
	&"mole_grenade":   "MG",
	&"jalapeno_laser": "JL",
	&"spicy_bounce":   "SB",
	&"nacho_wall":     "NW",
	&"salsa_magnet":   "SM",
	&"guac_storm":     "GS",
}

var powerup_id: StringName = &""

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rs: RectangleShape2D = RectangleShape2D.new()
	rs.size = Vector2(32.0, 32.0)
	shape.shape = rs
	add_child(shape)
	_build_visual()
	body_entered.connect(_on_body_entered)
	EventBus.game_over.connect(func(_s: int, _d: float): queue_free())
	EventBus.game_won.connect(func(_s: int, _d: float): queue_free())

func _build_visual() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(32.0, 32.0)
	bg.position = Vector2(-16.0, -16.0)
	bg.color = DROP_COLORS.get(powerup_id, Color(0.5, 0.5, 0.5))
	add_child(bg)

	var lbl: Label = Label.new()
	lbl.text = POWERUP_ABBREV.get(powerup_id, str(powerup_id).left(2).to_upper())
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.size = Vector2(32.0, 32.0)
	lbl.position = Vector2(-16.0, -16.0)
	add_child(lbl)

func _process(delta: float) -> void:
	position.y += FALL_SPEED * delta
	if position.y > get_viewport_rect().size.y + 50.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		EventBus.powerup_selected.emit(powerup_id)
		queue_free()
