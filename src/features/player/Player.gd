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

const HALF_WIDTH: float = 20.0

var _health: int = 0
var _max_health: int = 0
var _target_x: float = 0.0
var _current_damage: float = 0.0
var _current_autofire_interval: float = 0.0
var _shield_hits: int = 0
var _invincibility_timer: float = 0.0

@onready var _autofire_timer: Timer = $AutofireTimer
@onready var _spawn_point: Marker2D = $ProjectileSpawnPoint

func _ready() -> void:
	add_to_group(&"player")
	_max_health = Constants.PLAYER_BASE_HEALTH
	_health = _max_health
	_current_damage = Constants.PLAYER_BASE_DAMAGE
	_current_autofire_interval = Constants.PLAYER_AUTOFIRE_INTERVAL
	_target_x = global_position.x

	_autofire_timer.wait_time = _current_autofire_interval
	_autofire_timer.timeout.connect(_on_autofire_timeout)
	_autofire_timer.start()

	_setup_contact_area()
	EventBus.player_health_changed.emit(_health, _max_health)
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.game_started.connect(_on_game_started)

func _setup_contact_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
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
	if event is InputEventScreenDrag:
		_target_x = (event as InputEventScreenDrag).position.x
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_target_x = touch.position.x
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
		_shield_hits -= 1
		return
	_health = maxi(_health - amount, 0)
	EventBus.player_health_changed.emit(_health, _max_health)
	if _health == 0:
		_die()

func _on_enemy_contact(body: Node2D) -> void:
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
	_current_autofire_interval = Constants.PLAYER_AUTOFIRE_INTERVAL / speed_mult
	_autofire_timer.wait_time = _current_autofire_interval
	_autofire_timer.start()
	EventBus.player_health_changed.emit(_health, _max_health)

func _on_powerup_selected(powerup_id: StringName) -> void:
	match powerup_id:
		&"rapid_fire":
			apply_rapid_fire()
		&"nacho_wall":
			_shield_hits += Constants.NACHO_WALL_HITS

func get_health() -> int:
	return _health

func get_max_health() -> int:
	return _max_health

func apply_rapid_fire() -> void:
	_current_autofire_interval /= Constants.RAPID_FIRE_MULTIPLIER
	_autofire_timer.wait_time = _current_autofire_interval

func set_damage(new_damage: float) -> void:
	_current_damage = new_damage

func _die() -> void:
	AudioManager.play_sfx(&"player_die")
	EventBus.player_died.emit()
	set_process(false)
	set_process_input(false)
	_autofire_timer.stop()
	queue_free()
