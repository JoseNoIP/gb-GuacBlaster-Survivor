class_name XPGem
extends Area2D
## Collectible XP gem. Spawned at enemy death position.
## Emits gem_collected when touched by the player.
## Moves toward the player when salsa_magnet is active.

static var magnet_active: bool = false

var xp_value: int = 5
var _collected: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	var diamond: Polygon2D = Polygon2D.new()
	diamond.color = Color(0.9, 0.85, 0.1)
	diamond.polygon = PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-7.0, 0.0),
	])
	add_child(diamond)
	body_entered.connect(_on_body_entered)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.game_over.connect(func(_s: int, _d: float): queue_free())

func _process(delta: float) -> void:
	if XPGem.magnet_active:
		_move_toward_player(delta)
	else:
		position.y += Constants.GEM_FALL_SPEED * delta
		if position.y > get_viewport_rect().size.y + 20.0:
			queue_free()

func _move_toward_player(delta: float) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var player_pos: Vector2 = (players[0] as Node2D).global_position
	var dir: Vector2 = (player_pos - global_position).normalized()
	position += dir * Constants.GEM_MAGNET_SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		collect()

func collect() -> void:
	if _collected:
		return
	_collected = true
	EventBus.gem_collected.emit(xp_value)
	queue_free()

func _on_powerup_selected(powerup_id: StringName) -> void:
	if powerup_id == &"salsa_magnet":
		XPGem.magnet_active = true
