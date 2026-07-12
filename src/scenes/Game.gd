extends Node2D
## Game scene controller. Starts the session on load and handles screen shake.

const SHAKE_DURATION: float = 0.3
const SHAKE_STRENGTH: float = 5.0

var _shake_timer: float = 0.0

@onready var _camera: Camera2D = $Camera2D
@onready var _background: ColorRect = $Background

func _ready() -> void:
	var palette_index: int = SaveManager.get_victories() % Constants.BACKGROUND_PALETTE.size()
	_background.color = Constants.BACKGROUND_PALETTE[palette_index]
	GameManager.start_game()
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.menu_requested.connect(_on_menu_requested)
	EventBus.player_damaged.connect(_on_player_damaged)

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_camera.offset = Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH * 0.5, SHAKE_STRENGTH * 0.5)
		)
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if GameManager.get_state() == GameManager.GameState.PLAYING:
			GameManager.pause_game()

func _on_player_damaged() -> void:
	_shake_timer = SHAKE_DURATION

func _on_restart_requested() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/Game.tscn")

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/MainMenu.tscn")
