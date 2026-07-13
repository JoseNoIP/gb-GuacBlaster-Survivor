class_name MainMenu
extends Node2D
## Main menu scene. Animated background, icon-button grid, stats display.

const GAME_SCENE: String = "res://src/scenes/Game.tscn"
const SETTINGS_SCENE: String = "res://src/scenes/SettingsScreen.tscn"
const ACHIEVEMENTS_SCENE: String = "res://src/scenes/AchievementsScreen.tscn"
const DAILY_MISSIONS_SCENE: String = "res://src/scenes/DailyMissionsScreen.tscn"
const CHARACTER_SELECT_SCENE: String = "res://src/scenes/CharacterSelectScreen.tscn"
const BIOME_MAP_SCENE: String = "res://src/scenes/BiomeMapScreen.tscn"
const WEEKLY_CHALLENGE_SCENE: String = "res://src/scenes/WeeklyChallengeScreen.tscn"

const BG_COLOR: Color = Color(0.05, 0.08, 0.05)
const TITLE_COLOR: Color = Color(0.3, 0.85, 0.2)
const SUBTITLE_COLOR: Color = Color(0.55, 0.78, 0.35)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)
const STAT_COLOR: Color = Color(0.55, 0.75, 0.55)
const BTN_PLAY_COLOR: Color = Color(0.12, 0.62, 0.18)
const BTN_PLAY_HOVER: Color = Color(0.18, 0.78, 0.25)
const BTN_GRID_COLOR: Color = Color(0.10, 0.18, 0.10)
const BTN_GRID_BORDER: Color = Color(0.22, 0.50, 0.22)
const BTN_GRID_HOVER: Color = Color(0.14, 0.26, 0.14)
const BTN_CFG_COLOR: Color = Color(0.12, 0.14, 0.12)
const MUTED_COLOR: Color = Color(0.45, 0.45, 0.45)

var _title_label: Label
var _best_label: Label
var _play_btn: Button

func _ready() -> void:
	_build_animated_bg()
	_build_ui()

func _build_animated_bg() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.size = vp
	add_child(bg)

	var p: CPUParticles2D = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = false
	p.explosiveness = 0.0
	p.amount = 28
	p.lifetime = 7.0
	p.direction = Vector2(0.0, -1.0)
	p.spread = 38.0
	p.gravity = Vector2(0.0, 0.0)
	p.initial_velocity_min = 28.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.5, 4.0)
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(0.3, 0.85, 0.2, 0.0))
	grad.add_point(0.25, Color(0.35, 0.9, 0.25, 0.35))
	grad.add_point(0.75, Color(0.25, 0.7, 0.15, 0.2))
	grad.set_color(1, Color(0.3, 0.85, 0.2, 0.0))
	p.color_ramp = grad
	p.position = Vector2(vp.x * 0.5, vp.y + 10.0)
	add_child(p)

func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 0)
	canvas.add_child(root)

	# --- Top spacer ---
	var top_pad: Control = Control.new()
	top_pad.custom_minimum_size = Vector2(0.0, 36.0)
	root.add_child(top_pad)

	# --- Title ---
	_title_label = Label.new()
	_title_label.text = "GUACBLASTER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override(&"font_size", 50)
	_title_label.add_theme_color_override(&"font_color", TITLE_COLOR)
	_title_label.pivot_offset = Vector2(vp.x * 0.5, 30.0)
	root.add_child(_title_label)

	var subtitle: Label = Label.new()
	subtitle.text = "S U R V I V O R"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override(&"font_size", 20)
	subtitle.add_theme_color_override(&"font_color", SUBTITLE_COLOR)
	root.add_child(subtitle)

	_animate_title()

	# --- Stats row ---
	var stats_pad: Control = Control.new()
	stats_pad.custom_minimum_size = Vector2(0.0, 18.0)
	root.add_child(stats_pad)

	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override(&"separation", 28)
	root.add_child(stats_row)

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "★  %d oro" % SaveManager.get_gold()
	gold_lbl.add_theme_color_override(&"font_color", GOLD_COLOR)
	gold_lbl.add_theme_font_size_override(&"font_size", 16)
	stats_row.add_child(gold_lbl)

	var div: Label = Label.new()
	div.text = "·"
	div.add_theme_color_override(&"font_color", MUTED_COLOR)
	div.add_theme_font_size_override(&"font_size", 16)
	stats_row.add_child(div)

	var vic_lbl: Label = Label.new()
	vic_lbl.text = "▲  %d victorias" % SaveManager.get_victories()
	vic_lbl.add_theme_color_override(&"font_color", STAT_COLOR)
	vic_lbl.add_theme_font_size_override(&"font_size", 16)
	stats_row.add_child(vic_lbl)

	# --- Play button ---
	var play_pad: Control = Control.new()
	play_pad.custom_minimum_size = Vector2(0.0, 22.0)
	root.add_child(play_pad)

	var play_margin: MarginContainer = MarginContainer.new()
	play_margin.add_theme_constant_override(&"margin_left", 32)
	play_margin.add_theme_constant_override(&"margin_right", 32)
	root.add_child(play_margin)

	_play_btn = Button.new()
	_play_btn.text = ""
	_play_btn.custom_minimum_size = Vector2(0.0, 72.0)
	_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_btn.add_theme_stylebox_override(&"normal", _make_sb(BTN_PLAY_COLOR, Color.TRANSPARENT, 14))
	_play_btn.add_theme_stylebox_override(&"hover", _make_sb(BTN_PLAY_HOVER, Color.TRANSPARENT, 14))
	_play_btn.add_theme_stylebox_override(&"pressed", _make_sb(BTN_PLAY_HOVER, Color.TRANSPARENT, 14))
	_play_btn.pressed.connect(_on_play_pressed)
	play_margin.add_child(_play_btn)

	var play_inner: HBoxContainer = HBoxContainer.new()
	play_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	play_inner.add_theme_constant_override(&"separation", 14)
	play_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_btn.add_child(play_inner)

	var play_icon: IconPainter = IconPainter.new()
	play_icon.icon_id = &"play"
	play_icon.custom_minimum_size = Vector2(44.0, 44.0)
	play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_inner.add_child(play_icon)

	var play_lbl: Label = Label.new()
	play_lbl.text = "JUGAR"
	play_lbl.add_theme_font_size_override(&"font_size", 28)
	play_lbl.add_theme_color_override(&"font_color", Color(0.9, 1.0, 0.88))
	play_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_inner.add_child(play_lbl)

	# --- Secondary button grid ---
	var grid_pad: Control = Control.new()
	grid_pad.custom_minimum_size = Vector2(0.0, 16.0)
	root.add_child(grid_pad)

	var grid_margin: MarginContainer = MarginContainer.new()
	grid_margin.add_theme_constant_override(&"margin_left", 20)
	grid_margin.add_theme_constant_override(&"margin_right", 20)
	root.add_child(grid_margin)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_margin.add_child(grid)

	_add_grid_btn(grid, &"character", "PERSONAJE", _on_characters_pressed)
	_add_grid_btn(grid, &"upgrades", "MEJORAS", _on_upgrades_pressed)
	_add_grid_btn(grid, &"missions", "MISIONES", _on_missions_pressed)
	_add_grid_btn(grid, &"achievements", "LOGROS", _on_achievements_pressed)
	_add_grid_btn(grid, &"map", "MAPA", _on_biome_map_pressed)
	_add_grid_btn(grid, &"challenge", "DESAFÍO", _on_weekly_challenge_pressed)

	# --- Settings (bottom, subtle) ---
	var cfg_pad: Control = Control.new()
	cfg_pad.custom_minimum_size = Vector2(0.0, 12.0)
	root.add_child(cfg_pad)

	var cfg_btn: Button = Button.new()
	cfg_btn.text = "⚙  CONFIGURACIÓN"
	cfg_btn.custom_minimum_size = Vector2(180.0, 38.0)
	cfg_btn.add_theme_font_size_override(&"font_size", 14)
	cfg_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cfg_hover_color: Color = Color(0.16, 0.18, 0.16)
	cfg_btn.add_theme_stylebox_override(&"normal", _make_sb(BTN_CFG_COLOR, MUTED_COLOR, 8, 1))
	cfg_btn.add_theme_stylebox_override(&"hover", _make_sb(cfg_hover_color, MUTED_COLOR, 8, 1))
	cfg_btn.add_theme_stylebox_override(&"pressed", _make_sb(cfg_hover_color, MUTED_COLOR, 8, 1))
	cfg_btn.add_theme_color_override(&"font_color", MUTED_COLOR)
	cfg_btn.pressed.connect(_on_settings_pressed)
	root.add_child(cfg_btn)

	# --- Best score ---
	var score_pad: Control = Control.new()
	score_pad.custom_minimum_size = Vector2(0.0, 10.0)
	root.add_child(score_pad)

	_best_label = Label.new()
	_best_label.text = "Mejor puntuación: %d" % SaveManager.get_best_score()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override(&"font_size", 14)
	_best_label.add_theme_color_override(&"font_color", MUTED_COLOR)
	root.add_child(_best_label)

	var bottom_pad: Control = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0.0, 18.0)
	root.add_child(bottom_pad)

func _animate_title() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_title_label, "scale", Vector2(1.04, 1.04), 1.4)
	tween.tween_property(_title_label, "scale", Vector2(1.0, 1.0), 1.4)

func _add_grid_btn(
		parent: Control, icon_id: StringName, label: String, cb: Callable
) -> void:
	var btn: Button = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(0.0, 88.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_stylebox_override(&"normal", _make_sb(BTN_GRID_COLOR, BTN_GRID_BORDER, 12, 1))
	btn.add_theme_stylebox_override(&"hover", _make_sb(BTN_GRID_HOVER, BTN_GRID_BORDER, 12, 1))
	btn.add_theme_stylebox_override(&"pressed", _make_sb(BTN_GRID_HOVER, BTN_GRID_BORDER, 12, 1))
	btn.pressed.connect(cb)
	parent.add_child(btn)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override(&"separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon: IconPainter = IconPainter.new()
	icon.icon_id = icon_id
	icon.custom_minimum_size = Vector2(52.0, 52.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	var lbl: Label = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override(&"font_size", 11)
	lbl.add_theme_color_override(&"font_color", Color(0.75, 0.85, 0.75))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

func _make_sb(
	bg: Color,
	border: Color,
	radius: int,
	border_w: int = 0
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	return sb

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/UpgradeScreen.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(SETTINGS_SCENE)

func _on_missions_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(DAILY_MISSIONS_SCENE)

func _on_achievements_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(ACHIEVEMENTS_SCENE)

func _on_characters_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CHARACTER_SELECT_SCENE)

func _on_biome_map_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(BIOME_MAP_SCENE)

func _on_weekly_challenge_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(WEEKLY_CHALLENGE_SCENE)

func get_title_label() -> Label:
	return _title_label

func get_best_label() -> Label:
	return _best_label

func get_play_button() -> Button:
	return _play_btn
