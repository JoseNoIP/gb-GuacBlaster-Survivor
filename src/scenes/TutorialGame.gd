extends Node2D
## Interactive FTUE tutorial. Teaches movement, shooting, gem collection,
## and power-up selection using real game systems.
## On completion sets tutorial_shown = true and transitions to Game.tscn.

enum Step { WELCOME, MOVE, SHOOT, COLLECT, LEVEL_UP, COMPLETE }

const TUTORIAL_SCENE: String = "res://src/scenes/TutorialGame.tscn"
const GAME_SCENE: String = "res://src/scenes/Game.tscn"
const MOVE_THRESHOLD: float = 80.0
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)
const GREEN_COLOR: Color = Color(0.3, 0.85, 0.2)
const MUTED_COLOR: Color = Color(0.45, 0.45, 0.45)

const PlayerScene := preload("res://src/features/player/Player.tscn")
const EnemyBasicScene := preload("res://src/features/enemies/EnemyBasic.tscn")
const ProjectileScene := preload("res://src/features/projectiles/Projectile.tscn")
const ProjectileSpawnerGd := preload(
		"res://src/features/projectiles/ProjectileSpawner.gd"
)
const GemSpawnerGd := preload("res://src/features/gems/GemSpawner.gd")
const PowerUpDropperGd := preload("res://src/features/powerups/PowerUpDropper.gd")

var _step: Step = Step.WELCOME
var _player: Node2D = null
var _arrow_label: Label = null
var _title_lbl: Label = null
var _hint_lbl: Label = null
var _next_btn: Button = null
var _dots: Array = []
var _drag_origin_x: float = 0.0
var _drag_started: bool = false
var _move_satisfied: bool = false
var _bounce_time: float = 0.0

func _ready() -> void:
	_build_scene()
	GameManager.start_game()
	EventBus.game_over.connect(_on_game_over)
	_advance_to(Step.WELCOME)

func _build_scene() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.05)
	bg.size = vp
	add_child(bg)

	_player = PlayerScene.instantiate()
	_player.position = Vector2(vp.x * 0.5, vp.y * 0.78)
	add_child(_player)

	var ps: Node2D = ProjectileSpawnerGd.new()
	ps.set(&"projectile_scene", ProjectileScene)
	add_child(ps)

	var gs: Node2D = GemSpawnerGd.new()
	add_child(gs)

	var pd: Node = PowerUpDropperGd.new()
	add_child(pd)

	_build_overlay()

func _build_overlay() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_arrow_label = Label.new()
	_arrow_label.text = "▼"
	_arrow_label.add_theme_font_size_override(&"font_size", 32)
	_arrow_label.add_theme_color_override(&"font_color", GOLD_COLOR)
	_arrow_label.position = Vector2(vp.x * 0.5 - 12.0, vp.y * 0.6)
	_arrow_label.hide()
	layer.add_child(_arrow_label)

	var panel_h: float = 160.0
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(0.0, vp.y - panel_h)
	panel.set_size(Vector2(vp.x, panel_h))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var dots_row: HBoxContainer = HBoxContainer.new()
	dots_row.add_theme_constant_override(&"separation", 10)
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(dots_row)

	for i: int in 5:
		var dot: Label = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override(&"font_size", 12)
		dot.add_theme_color_override(&"font_color", MUTED_COLOR)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots_row.add_child(dot)
		_dots.append(dot)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override(&"font_size", 22)
	_title_lbl.add_theme_color_override(&"font_color", Color(0.9, 1.0, 0.88))
	_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_title_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override(&"font_size", 13)
	_hint_lbl.add_theme_color_override(&"font_color", MUTED_COLOR)
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hint_lbl)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(180.0, 44.0)
	_next_btn.add_theme_font_size_override(&"font_size", 18)
	_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next_btn.pressed.connect(_on_next_pressed)
	_next_btn.hide()
	vbox.add_child(_next_btn)

func _process(delta: float) -> void:
	_bounce_time += delta
	if _step == Step.MOVE and _player != null and _arrow_label != null:
		if _arrow_label.visible:
			_arrow_label.position.x = _player.position.x - 12.0
			_arrow_label.position.y = (
				_player.position.y - 80.0 + sin(_bounce_time * TAU) * 6.0
			)

func _advance_to(next: Step) -> void:
	_step = next
	_update_dots()
	_update_panel()
	if next == Step.SHOOT:
		_spawn_tutorial_enemy()
	elif next == Step.LEVEL_UP:
		var opts: Array = [
			Constants.POWERUP_POOL[0],
			Constants.POWERUP_POOL[1],
			Constants.POWERUP_POOL[2],
		]
		EventBus.powerup_selected.connect(_on_powerup_selected_tutorial, CONNECT_ONE_SHOT)
		EventBus.powerup_selection_requested.emit(opts)

func _update_dots() -> void:
	var current_dot: int = int(_step) - 1
	for i: int in _dots.size():
		var dot: Label = _dots[i] as Label
		if i < current_dot:
			dot.add_theme_color_override(&"font_color", GREEN_COLOR)
		elif i == current_dot:
			dot.add_theme_color_override(&"font_color", GOLD_COLOR)
		else:
			dot.add_theme_color_override(&"font_color", MUTED_COLOR)

func _update_panel() -> void:
	_arrow_label.hide()
	_next_btn.hide()
	match _step:
		Step.WELCOME:
			_title_lbl.text = tr(&"TUTORIAL_WELCOME_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_WELCOME_HINT")
			_next_btn.text = tr(&"TUTORIAL_BTN_START")
			_next_btn.show()
		Step.MOVE:
			_title_lbl.text = tr(&"TUTORIAL_MOVE_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_MOVE_HINT")
			_arrow_label.show()
		Step.SHOOT:
			_title_lbl.text = tr(&"TUTORIAL_SHOOT_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_SHOOT_HINT")
		Step.COLLECT:
			_title_lbl.text = tr(&"TUTORIAL_COLLECT_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_COLLECT_HINT")
		Step.LEVEL_UP:
			_title_lbl.text = tr(&"TUTORIAL_LEVELUP_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_LEVELUP_HINT")
		Step.COMPLETE:
			_title_lbl.text = tr(&"TUTORIAL_DONE_TITLE")
			_hint_lbl.text = tr(&"TUTORIAL_DONE_HINT")
			_next_btn.text = tr(&"BTN_PLAY")
			_next_btn.show()

func _spawn_tutorial_enemy() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var enemy: Node2D = EnemyBasicScene.instantiate()
	enemy.position = Vector2(vp.x * 0.5, vp.y * 0.25)
	add_child(enemy)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed_tutorial, CONNECT_ONE_SHOT)

func _on_enemy_destroyed_tutorial(_id: int, _pos: Vector2, _xp: int) -> void:
	_advance_to(Step.COLLECT)
	EventBus.gem_collected.connect(_on_gem_collected_tutorial, CONNECT_ONE_SHOT)

func _on_gem_collected_tutorial(_xp: int) -> void:
	_advance_to(Step.LEVEL_UP)

func _on_powerup_selected_tutorial(_id: StringName) -> void:
	_advance_to(Step.COMPLETE)

func _on_next_pressed() -> void:
	if _step == Step.WELCOME:
		_advance_to(Step.MOVE)
	elif _step == Step.COMPLETE:
		SaveManager.set_tutorial_shown(true)
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)

func _input(event: InputEvent) -> void:
	if _step != Step.MOVE or _move_satisfied:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_drag_origin_x = touch.position.x
			_drag_started = true
		else:
			_drag_started = false
	elif event is InputEventScreenDrag and _drag_started:
		var drag := event as InputEventScreenDrag
		if absf(drag.position.x - _drag_origin_x) >= MOVE_THRESHOLD:
			_move_satisfied = true
			_arrow_label.hide()
			_advance_to(Step.SHOOT)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_drag_origin_x = mb.position.x
			_drag_started = true
		else:
			_drag_started = false
	elif event is InputEventMouseMotion and _drag_started:
		var mm := event as InputEventMouseMotion
		if absf(mm.position.x - _drag_origin_x) >= MOVE_THRESHOLD:
			_move_satisfied = true
			_arrow_label.hide()
			_advance_to(Step.SHOOT)

func _on_game_over() -> void:
	get_tree().change_scene_to_file.call_deferred(TUTORIAL_SCENE)
