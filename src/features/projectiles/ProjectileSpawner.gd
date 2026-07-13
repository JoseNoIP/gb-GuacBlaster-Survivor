class_name ProjectileSpawner
extends Node2D
## Listens to EventBus.player_fired and instantiates Projectile scenes.
## Power-ups that modify shots are driven by powerup_stack_changed.
## Character fire_mode (normal/double/fan3/fan5/heavy) is read on game_started.
##
## Required: assign projectile_scene in the inspector.

@export var projectile_scene: PackedScene

var _triple_shot: bool = false
var _pierce_count: int = 0
var _bouncy: bool = false
var _extra_streams: int = 0
var _fire_mode: StringName = &"normal"
var _bullet_tint: Color = Color.WHITE
var _bullet_scale: float = 1.0

func _ready() -> void:
	EventBus.player_fired.connect(_on_player_fired)
	EventBus.powerup_stack_changed.connect(_on_powerup_stack_changed)
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	var selected: StringName = SaveManager.get_selected_character()
	for def in Constants.CHARACTERS:
		var d := def as Dictionary
		if d.get("id", &"") as StringName == selected:
			_fire_mode = d.get("fire_mode", &"normal") as StringName
			_bullet_tint = d.get("bullet_tint", Color.WHITE) as Color
			_bullet_scale = d.get("bullet_scale", 1.0) as float
			return
	_fire_mode = &"normal"
	_bullet_tint = Color.WHITE
	_bullet_scale = 1.0

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
		_fire_mode_burst(pos, direction, damage)

func _fire_mode_burst(pos: Vector2, dir: Vector2, damage: float) -> void:
	match _fire_mode:
		&"double":
			_spawn(pos + Vector2(-Constants.CHAR_DOUBLE_OFFSET, 0.0), dir, damage)
			_spawn(pos + Vector2(Constants.CHAR_DOUBLE_OFFSET, 0.0), dir, damage)
		&"fan3":
			_spawn(pos, dir, damage)
			_spawn(pos, dir.rotated(deg_to_rad(Constants.CHAR_FAN3_ANGLE)), damage)
			_spawn(pos, dir.rotated(deg_to_rad(-Constants.CHAR_FAN3_ANGLE)), damage)
		&"fan5":
			for step: int in 5:
				var angle: float = (float(step) - 2.0) * Constants.CHAR_FAN5_ANGLE
				_spawn(pos, dir.rotated(deg_to_rad(angle)), damage)
		_:
			_spawn(pos, dir, damage)
	if _triple_shot:
		_spawn(pos, dir.rotated(deg_to_rad(20.0)), damage)
		_spawn(pos, dir.rotated(deg_to_rad(-20.0)), damage)

func _spawn(spawn_position: Vector2, direction: Vector2, damage: float) -> void:
	if projectile_scene == null:
		push_error("ProjectileSpawner: projectile_scene not assigned")
		return
	var proj: Node2D = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = spawn_position
	proj.call(&"setup", damage, direction, _pierce_count, _bouncy)
	proj.call(&"setup_visuals", _bullet_tint, _bullet_scale)
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
