extends Node2D
## Game scene controller. Starts the session on load and handles screen shake.

const SHAKE_DURATION: float = 0.3
const SHAKE_STRENGTH: float = 5.0

const BG_PULSE_SPEED: float = 0.35
# Matches Constants.PERSPECTIVE_VP_Y_RATIO — kept local to avoid autoload const in const expr
const VP_Y_RATIO: float = 0.25
# Background zooms in slowly toward VP: 8% total over BG_ZOOM_DURATION seconds
const BG_ZOOM_MAX: float = 0.08
const BG_ZOOM_DURATION: float = 180.0

var _shake_timer: float = 0.0
var _tutorial_root: Control = null
var _tutorial_dismissed: bool = false
var _bg_time: float = 0.0
var _bg_base_color: Color = Color(0.08, 0.1, 0.08, 1.0)
var _bg_sprite: Sprite2D = null
var _bg_initial_scale: Vector2 = Vector2.ONE
var _vp_center: Vector2 = Vector2.ZERO

@onready var _camera: Camera2D = $Camera2D
@onready var _background: ColorRect = $Background

func _ready() -> void:
	var wins: int = SaveManager.get_victories()
	var world_count: int = Constants.BACKGROUND_PALETTE.size()
	var biome: int = wins % world_count
	var variant: int = (wins / world_count) % 3
	var gen: int = wins / (world_count * 3)
	_vp_center = get_viewport_rect().size * 0.5
	_bg_base_color = Constants.BACKGROUND_PALETTE[biome]
	_background.color = _bg_base_color
	_load_bg_texture(biome, variant, gen)
	_build_bg_particles(biome)
	GameManager.start_game()
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.menu_requested.connect(_on_menu_requested)
	EventBus.player_damaged.connect(_on_player_damaged)
	_maybe_show_tutorial()

func _process(delta: float) -> void:
	_bg_time += delta
	var pulse: float = (1.0 + sin(_bg_time * BG_PULSE_SPEED)) * 0.5
	_background.color = _bg_base_color.lerp(_bg_base_color.lightened(0.10), pulse)
	if _bg_sprite != null:
		# Zoom slowly toward vanishing point (VP_Y_RATIO from top, centered horizontally).
		# Math: for VP at (Cx, Cy - H*VP_Y_RATIO), keeping VP stationary while scaling:
		#   position.y = Cy * (1 + 2 * VP_Y_RATIO * z)  where z = zoom progress 0→BG_ZOOM_MAX
		var z: float = minf(_bg_time / BG_ZOOM_DURATION, 1.0) * BG_ZOOM_MAX
		_bg_sprite.scale = _bg_initial_scale * (1.0 + z)
		_bg_sprite.position.x = _vp_center.x
		_bg_sprite.position.y = _vp_center.y * (1.0 + 2.0 * VP_Y_RATIO * z)
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
	var tex_size: Vector2 = tex.get_size()
	var vp: Vector2 = get_viewport_rect().size
	var base_scale: Vector2 = Vector2(vp.x / tex_size.x, vp.y / tex_size.y)
	# Extra margin so VP zoom never reveals black edges (shift + scale growth)
	var extra: float = BG_ZOOM_MAX * VP_Y_RATIO + 0.06
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.position = _vp_center
	sprite.scale = base_scale * (1.0 + extra)
	sprite.modulate = _get_gen_tint(gen)
	_bg_sprite = sprite
	_bg_initial_scale = sprite.scale
	add_child(sprite)
	move_child(sprite, _background.get_index() + 1)

func _build_bg_particles(biome: int) -> void:
	var vp: Vector2 = get_viewport_rect().size
	var pcol: Color = _get_biome_particle_color(biome)
	var pcol_fade: Color = Color(pcol.r, pcol.g, pcol.b, 0.0)
	var p: CPUParticles2D = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = false
	p.amount = 20
	p.lifetime = 9.0
	p.explosiveness = 0.0
	p.randomness = 0.8
	p.direction = Vector2(0.0, -1.0)
	p.spread = 15.0
	p.gravity = Vector2(0.0, 0.0)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.5, 4.0)
	p.position = Vector2(vp.x * 0.5, vp.y + 8.0)
	var grad: Gradient = Gradient.new()
	grad.set_color(0, pcol)
	grad.set_color(1, pcol_fade)
	p.color_ramp = grad
	add_child(p)
	var particle_idx: int = _background.get_index() + (2 if _bg_sprite != null else 1)
	move_child(p, particle_idx)

func _get_biome_particle_color(biome: int) -> Color:
	var colors: Array = [
		Color(0.7, 1.0, 0.5, 0.25),
		Color(0.4, 0.8, 1.0, 0.22),
		Color(0.6, 0.4, 1.0, 0.25),
		Color(1.0, 0.55, 0.2, 0.28),
		Color(0.3, 0.75, 1.0, 0.25),
		Color(0.9, 0.3, 0.4, 0.28),
	]
	return colors[clampi(biome, 0, colors.size() - 1)]

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
	hint.text = tr(&"TUTORIAL_HINT")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 22)
	hint.add_theme_color_override(&"font_color", Color(0.88, 1.0, 0.84))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint)

	var sub: Label = Label.new()
	sub.text = tr(&"TUTORIAL_TAP")
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
