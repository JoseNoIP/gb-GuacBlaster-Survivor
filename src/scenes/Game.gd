extends Node2D
## Game scene controller. Starts the session on load and handles screen shake.

const SHAKE_DURATION: float = 0.3
const SHAKE_STRENGTH: float = 5.0

var _shake_timer: float = 0.0

@onready var _camera: Camera2D = $Camera2D
@onready var _background: ColorRect = $Background

func _ready() -> void:
	var wins: int = SaveManager.get_victories()
	var biome: int = wins % 5
	var variant: int = (wins / 5) % 3
	var gen: int = wins / 15
	_background.color = Constants.BACKGROUND_PALETTE[biome]
	_load_bg_texture(biome, variant, gen)
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

func _load_bg_texture(biome: int, variant: int, gen: int) -> void:
	var path := "res://assets/sprites/backgrounds/bg_%d_%d.png" % [biome, variant]
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.size = _background.size
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.modulate = _get_gen_tint(gen)
	_background.add_child(tr)


func _get_gen_tint(gen: int) -> Color:
	match min(gen, 3):
		1: return Color(0.82, 0.88, 1.0)
		2: return Color(1.0, 0.82, 0.82)
		3: return Color(0.85, 0.78, 1.0)
		_: return Color(1.0, 1.0, 1.0)


func _on_menu_requested() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/MainMenu.tscn")
