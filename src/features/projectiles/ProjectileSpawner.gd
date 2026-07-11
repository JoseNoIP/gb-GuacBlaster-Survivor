class_name ProjectileSpawner
extends Node2D
## Listens to EventBus.player_fired and instantiates Projectile scenes.
## Power-ups that add shots (Triple Shot, Bounce) modify this node, not Player.
##
## Required: assign projectile_scene in the inspector.

@export var projectile_scene: PackedScene

var _triple_shot: bool = false

func _ready() -> void:
	EventBus.player_fired.connect(_on_player_fired)
	EventBus.powerup_selected.connect(_on_powerup_selected)

func _on_player_fired(
		spawn_position: Vector2,
		direction: Vector2,
		damage: float
) -> void:
	_spawn(spawn_position, direction, damage)
	if _triple_shot:
		_spawn(spawn_position, direction.rotated(deg_to_rad(20.0)), damage)
		_spawn(spawn_position, direction.rotated(deg_to_rad(-20.0)), damage)

func _spawn(spawn_position: Vector2, direction: Vector2, damage: float) -> void:
	if projectile_scene == null:
		push_error("ProjectileSpawner: projectile_scene not assigned")
		return
	var proj: Node2D = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = spawn_position
	proj.call(&"setup", damage, direction)

func _on_powerup_selected(powerup_id: StringName) -> void:
	match powerup_id:
		&"triple_shot":
			_triple_shot = true
