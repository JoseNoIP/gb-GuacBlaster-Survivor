class_name Player
extends CharacterBody2D
## Controls player movement, health, autofire, and power-up effects.
##
## Required child nodes:
##   AutofireTimer  (Timer)          — autostart=false, one_shot=false
##   ProjectileSpawnPoint (Marker2D) — position Vector2(0, -28)
##   CollisionShape2D                — capsule or circle shape
##
## Collision layers: Layer 1 (player). Masks: Layer 8 (enemy projectiles).
## Enemy contact is detected via a programmatic Area2D (mask layer 2).

const HALF_WIDTH: float = 35.0

var _health: int = 0
var _max_health: int = 0
var _target_x: float = 0.0
var _drag_anchor_x: float = 0.0
var _drag_anchor_player_x: float = 0.0
var _current_damage: float = 0.0
var _current_autofire_interval: float = 0.0
var _base_autofire_interval: float = 0.0
var _rapid_fire_stacks: int = 0
var _shield_hits: int = 0
var _nacho_wall_stacks: int = 0
var _invincibility_timer: float = 0.0
var _shield_visual: Line2D

@onready var _autofire_timer: Timer = $AutofireTimer
@onready var _spawn_point: Marker2D = $ProjectileSpawnPoint

func _ready() -> void:
	add_to_group(&"player")
	_max_health = Constants.PLAYER_BASE_HEALTH
	_health = _max_health
	_current_damage = Constants.PLAYER_BASE_DAMAGE
	_current_autofire_interval = Constants.PLAYER_AUTOFIRE_INTERVAL
	_base_autofire_interval = _current_autofire_interval
	_target_x = global_position.x

	_autofire_timer.wait_time = _current_autofire_interval
	_autofire_timer.timeout.connect(_on_autofire_timeout)
	_autofire_timer.start()

	_build_shield_visual()
	_setup_contact_area()
	EventBus.player_health_changed.emit(_health, _max_health)
	EventBus.powerup_stack_changed.connect(_on_powerup_stack_changed)
	EventBus.heart_collected.connect(_on_heart_collected)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_won.connect(_on_game_won_fired)

func _build_shield_visual() -> void:
	_shield_visual = Line2D.new()
	_shield_visual.width = 3.0
	_shield_visual.default_color = Color(0.9, 0.85, 0.2, 0.85)
	_shield_visual.closed = true
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 20:
		var angle: float = float(i) / 20.0 * TAU
		pts.append(Vector2(cos(angle), sin(angle)) * 56.0)
	_shield_visual.points = pts
	_shield_visual.hide()
	add_child(_shield_visual)

func _setup_contact_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_enemy_contact)
	add_child(area)

func _process(delta: float) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	position.x = clampf(_target_x, HALF_WIDTH, viewport_width - HALF_WIDTH)
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_drag_anchor_x = (event as InputEventScreenTouch).position.x
		_drag_anchor_player_x = _target_x
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var delta_x: float = (drag.position.x - _drag_anchor_x) * SaveManager.get_swipe_sensitivity()
		_target_x = _drag_anchor_player_x + delta_x
	elif event is InputEventMouseMotion:
		_target_x = (event as InputEventMouseMotion).position.x

func _on_autofire_timeout() -> void:
	_fire()

func _fire() -> void:
	EventBus.player_fired.emit(_spawn_point.global_position, Vector2.UP, _current_damage)
	AudioManager.play_sfx(&"shoot")
	AudioManager.trigger_haptic_light()

func take_damage(amount: int) -> void:
	if _shield_hits > 0:
		_update_shield(_shield_hits - 1)
		return
	_health = maxi(_health - amount, 0)
	EventBus.player_health_changed.emit(_health, _max_health)
	EventBus.player_damaged.emit()
	if _health == 0:
		_die()

func _update_shield(value: int) -> void:
	_shield_hits = value
	_shield_visual.visible = _shield_hits > 0
	EventBus.player_shield_changed.emit(_shield_hits)

func _on_enemy_contact(body: Node2D) -> void:
	if GameManager.get_state() != GameManager.GameState.PLAYING:
		return
	if _invincibility_timer > 0.0:
		return
	if not body.is_in_group(&"enemies"):
		return
	take_damage(1)
	_invincibility_timer = Constants.PLAYER_CONTACT_INVINCIBILITY

func _on_game_started() -> void:
	var health_bonus: int = SaveManager.get_upgrade_level(&"health") * Constants.META_HEALTH_PER_LEVEL
	_max_health = Constants.PLAYER_BASE_HEALTH + health_bonus
	_health = _max_health
	var dmg_level: int = SaveManager.get_upgrade_level(&"damage")
	var damage_mult: float = 1.0 + float(dmg_level) * Constants.META_DAMAGE_PER_LEVEL
	_current_damage = Constants.PLAYER_BASE_DAMAGE * damage_mult
	var spd_level: int = SaveManager.get_upgrade_level(&"speed")
	var speed_mult: float = 1.0 + float(spd_level) * Constants.META_SPEED_PER_LEVEL
	_base_autofire_interval = Constants.PLAYER_AUTOFIRE_INTERVAL / speed_mult
	_current_autofire_interval = _base_autofire_interval
	_rapid_fire_stacks = 0
	_autofire_timer.wait_time = _current_autofire_interval
	_autofire_timer.start()
	var char_data: Dictionary = _get_character_data()
	_max_health = maxi(1, _max_health + (char_data.get("hp_bonus", 0) as int))
	_health = _max_health
	_current_damage *= (char_data.get("damage_mult", 1.0) as float)
	var fire_mult: float = char_data.get("fire_rate_mult", 1.0) as float
	if fire_mult > 0.0:
		_base_autofire_interval /= fire_mult
	_current_autofire_interval = _base_autofire_interval
	_autofire_timer.wait_time = _current_autofire_interval
	var shield_level: int = SaveManager.get_upgrade_level(&"starter_shield")
	_update_shield(shield_level * Constants.META_STARTER_SHIELD_PER_LEVEL)
	_nacho_wall_stacks = 0
	var sprite_tint: Color = char_data.get("sprite_tint", Color.WHITE) as Color
	var char_id: StringName = char_data.get("id", &"") as StringName
	var char_sprite: String = "res://assets/sprites/characters/player_" + str(char_id) + ".png"
	var spr := get_node_or_null(^"Sprite2D") as Sprite2D
	if spr != null:
		if ResourceLoader.exists(char_sprite):
			spr.texture = load(char_sprite) as Texture2D
			spr.modulate = Color.WHITE
		else:
			spr.modulate = sprite_tint
	EventBus.player_health_changed.emit(_health, _max_health)

func _on_powerup_stack_changed(powerup_id: StringName, count: int) -> void:
	match powerup_id:
		&"rapid_fire":
			_rapid_fire_stacks = count
			var interval: float = (
				_base_autofire_interval / pow(Constants.RAPID_FIRE_MULTIPLIER, float(count))
			)
			_current_autofire_interval = maxf(Constants.PLAYER_AUTOFIRE_MIN, interval)
			_autofire_timer.wait_time = _current_autofire_interval
		&"nacho_wall":
			if count > _nacho_wall_stacks:
				_update_shield(_shield_hits + Constants.NACHO_WALL_HITS)
			elif count < _nacho_wall_stacks:
				var removed: int = (_nacho_wall_stacks - count) * Constants.NACHO_WALL_HITS
				_update_shield(maxi(0, _shield_hits - removed))
			_nacho_wall_stacks = count

func _on_heart_collected() -> void:
	if _health >= _max_health:
		return
	_health = mini(_health + 1, _max_health)
	EventBus.player_health_changed.emit(_health, _max_health)

func get_health() -> int:
	return _health

func get_max_health() -> int:
	return _max_health

func set_damage(new_damage: float) -> void:
	_current_damage = new_damage

func _get_character_data() -> Dictionary:
	var selected: StringName = SaveManager.get_selected_character()
	for char_def in Constants.CHARACTERS:
		if (char_def as Dictionary).get("id", &"") as StringName == selected:
			return char_def as Dictionary
	return {}

func _on_game_won_fired(_score: int, _duration: float) -> void:
	set_process(false)
	set_process_input(false)
	_autofire_timer.stop()

func _die() -> void:
	EventBus.player_died.emit()
	set_process(false)
	set_process_input(false)
	_autofire_timer.stop()
	queue_free()
