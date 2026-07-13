extends Node2D
## Game scene controller. Starts the session on load and handles screen shake.

const SHAKE_DURATION: float = 0.3
const SHAKE_STRENGTH: float = 5.0

var _shake_timer: float = 0.0
var _tutorial_root: Control = null
var _tutorial_dismissed: bool = false

@onready var _camera: Camera2D = $Camera2D
@onready var _background: ColorRect = $Background

func _ready() -> void:
	var wins: int = SaveManager.get_victories()
	var world_count: int = Constants.BACKGROUND_PALETTE.size()
	var biome: int = wins % world_count
	var variant: int = (wins / world_count) % 3
	var gen: int = wins / (world_count * 3)
	_background.color = Constants.BACKGROUND_PALETTE[biome]
	_load_bg_texture(biome, variant, gen)
	GameManager.start_game()
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.menu_requested.connect(_on_menu_requested)
	EventBus.player_damaged.connect(_on_player_damaged)
	_maybe_show_tutorial()

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
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
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

func _maybe_show_tutorial() -> void:
	if SaveManager.get_tutorial_shown():
		return
	SaveManager.set_tutorial_shown(true)
	_build_tutorial_overlay()

func _build_tutorial_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_tutorial_root = Control.new()
	_tutorial_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_root.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			_dismiss_tutorial()
	)
	layer.add_child(_tutorial_root)

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_root.add_child(dim)

	var vp: Vector2 = get_viewport_rect().size
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 10)
	vbox.position = Vector2(vp.x * 0.5 - 140.0, vp.y * 0.5 - 48.0)
	vbox.custom_minimum_size = Vector2(280.0, 0.0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_root.add_child(vbox)

	var hint: Label = Label.new()
	hint.text = "Arrastra con el dedo\npara moverte"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 22)
	hint.add_theme_color_override(&"font_color", Color(0.88, 1.0, 0.84))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint)

	var sub: Label = Label.new()
	sub.text = "Toca para continuar"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override(&"font_size", 13)
	sub.add_theme_color_override(&"font_color", Color(0.55, 0.65, 0.55))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)

	var timer: Timer = Timer.new()
	timer.wait_time = 3.5
	timer.one_shot = true
	timer.timeout.connect(_dismiss_tutorial)
	add_child(timer)
	timer.start()

func _dismiss_tutorial() -> void:
	if _tutorial_dismissed or _tutorial_root == null:
		return
	_tutorial_dismissed = true
	var layer: Node = _tutorial_root.get_parent()
	var tween: Tween = create_tween()
	tween.tween_property(_tutorial_root, "modulate:a", 0.0, 0.35)
	tween.tween_callback(layer.queue_free)
