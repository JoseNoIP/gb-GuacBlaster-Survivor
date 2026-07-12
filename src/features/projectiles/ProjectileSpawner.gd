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
	var total: int = _extra_streams + 1
	for i: int in total:
		var offset_x: float = (
			(float(i) - float(total - 1) * 0.5) * Constants.MULTI_STREAM_SPACING
		)
		var pos: Vector2 = spawn_position + Vector2(offset_x, 0.0)
		_spawn(pos, direction, damage)
		if _triple_shot:
			_spawn(pos, direction.rotated(deg_to_rad(20.0)), damage)
			_spawn(pos, direction.rotated(deg_to_rad(-20.0)), damage)

func _spawn(spawn_position: Vector2, direction: Vector2, damage: float) -> void:
	if projectile_scene == null:
		push_error("ProjectileSpawner: projectile_scene not assigned")
		return
	var proj: Node2D = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = spawn_position
	proj.call(&"setup", damage, direction, _pierce_count, _bouncy)
	AudioManager.play_sfx(&"shoot")

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
