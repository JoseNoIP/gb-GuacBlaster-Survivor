class_name ProjectileSpawner
extends Node2D
## Listens to EventBus.player_fired and instantiates Projectile scenes.
## Power-ups that modify shots are driven by powerup_stack_changed.
##
## Required: assign projectile_scene in the inspector.

@export var projectile_scene: PackedScene

var _triple_shot: bool = false
var _pierce_count: int = 0
var _bouncy: bool = false
var _extra_streams: int = 0

func _ready() -> void:
	EventBus.player_fired.connect(_on_player_fired)
	EventBus.powerup_stack_changed.connect(_on_powerup_stack_changed)

func _on_player_fired(
		spawn_position: Vector2,
		direction: Vector2,
		damage: float
) -> void:
	_spawn(spawn_position, direction, damage)
	if _triple_shot:
		_spawn(spawn_position, direction.rotated(deg_to_rad(20.0)), damage)
		_spawn(spawn_position, direction.rotated(deg_to_rad(-20.0)), damage)
	for i: int in _extra_streams:
		var mult: float = float(i / 2 + 1) * Constants.MULTI_STREAM_SPACING
		var sign_val: float = 1.0 if i % 2 == 0 else -1.0
		var offset: Vector2 = Vector2(mult * sign_val, 0.0)
		_spawn(spawn_position + offset, direction, damage)

func _spawn(spawn_position: Vector2, direction: Vector2, damage: float) -> void:
	if projectile_scene == null:
		push_error("ProjectileSpawner: projectile_scene not assigned")
		return
	var proj: Node2D = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = spawn_position
	proj.call(&"setup", damage, direction, _pierce_count, _bouncy)

func _on_powerup_stack_changed(powerup_id: StringName, count: int) -> void:
	match powerup_id:
		&"triple_shot":
			_triple_shot = count > 0
		&"super_guac":
			_pierce_count = Constants.SUPER_GUAC_PENETRATION if count > 0 else 0
		&"spicy_bounce":
			_bouncy = count > 0
		&"guac_storm":
			_extra_streams = count
