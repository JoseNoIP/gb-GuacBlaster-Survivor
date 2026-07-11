class_name Player
extends CharacterBody2D
## Controls player movement, health, and autofire.
##
## Required child nodes:
##   AutofireTimer  (Timer)       — autostart=true, one_shot=false
##   ProjectileSpawnPoint (Marker2D) — position Vector2(0, -20)
##   CollisionShape2D (CollisionShape2D) — capsule or circle shape
##
## Collision layers: Layer 1 (player). Masks: Layer 4 (enemy projectiles).

const HALF_WIDTH: float = 20.0

var _health: int = 0
var _max_health: int = 0
var _target_x: float = 0.0
var _current_damage: float = 0.0
var _current_autofire_interval: float = 0.0

@onready var _autofire_timer: Timer = $AutofireTimer
@onready var _spawn_point: Marker2D = $ProjectileSpawnPoint

func _ready() -> void:
	_max_health = Constants.PLAYER_BASE_HEALTH
	_health = _max_health
	_current_damage = Constants.PLAYER_BASE_DAMAGE
	_current_autofire_interval = Constants.PLAYER_AUTOFIRE_INTERVAL
	_target_x = global_position.x

	_autofire_timer.wait_time = _current_autofire_interval
	_autofire_timer.timeout.connect(_on_autofire_timeout)
	_autofire_timer.start()

	EventBus.player_health_changed.emit(_health, _max_health)

func _process(_delta: float) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	position.x = clampf(_target_x, HALF_WIDTH, viewport_width - HALF_WIDTH)

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
	_health = maxi(_health - amount, 0)
	EventBus.player_health_changed.emit(_health, _max_health)
	if _health == 0:
		_die()

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
