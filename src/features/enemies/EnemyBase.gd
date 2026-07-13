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
var _hit_tween: Tween = null

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
	else:
		_play_hit_flash()

func _play_hit_flash() -> void:
	var sprite := get_node_or_null(^"Sprite2D") as Node2D
	if sprite == null:
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
		sprite.position = Vector2.ZERO
		sprite.modulate = Color.WHITE
	sprite.modulate = Color(2.0, 0.5, 0.5)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "position", Vector2(5.0, 0.0), 0.04)
	_hit_tween.tween_property(sprite, "position", Vector2(-4.0, 0.0), 0.04)
	_hit_tween.tween_property(sprite, "position", Vector2.ZERO, 0.04)
	_hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.06)

func get_health() -> int:
	return _health

func _die() -> void:
	EventBus.enemy_destroyed.emit(get_instance_id(), global_position, _xp_value)
	queue_free()

func _on_screen_exited() -> void:
	queue_free()
