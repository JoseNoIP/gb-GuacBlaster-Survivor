extends Node
## Periodically spawns a HeartDrop during active gameplay.
## Spawn interval: Constants.HEART_DROP_INTERVAL seconds (counted only while PLAYING).

const HeartDropGd := preload("res://src/features/player/HeartDrop.tscn")

var _timer: float = 0.0
var _active: bool = false

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_session_ended)
	EventBus.game_won.connect(_on_session_ended)

func _process(delta: float) -> void:
	if not _active:
		return
	if GameManager.get_state() != GameManager.GameState.PLAYING:
		return
	_timer -= delta
	if _timer <= 0.0:
		_spawn_heart()
		_timer = Constants.HEART_DROP_INTERVAL

func _spawn_heart() -> void:
	var drop: Area2D = HeartDropGd.instantiate() as Area2D
	var vp_width: float = get_viewport().get_visible_rect().size.x
	drop.position = Vector2(randf_range(20.0, vp_width - 20.0), -20.0)
	get_parent().add_child(drop)

func _on_game_started() -> void:
	_active = true
	_timer = Constants.HEART_DROP_INTERVAL

func _on_session_ended(_score: int, _duration: float) -> void:
	_active = false
	_timer = Constants.HEART_DROP_INTERVAL
