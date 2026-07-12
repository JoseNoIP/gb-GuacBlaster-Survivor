class_name MainMenu
extends Node2D
## Main menu scene. Shows title, best score, and play button.

const GAME_SCENE: String = "res://src/scenes/Game.tscn"
const SETTINGS_SCENE: String = "res://src/scenes/SettingsScreen.tscn"

const BG_COLOR: Color = Color(0.08, 0.1, 0.08)
const TITLE_COLOR: Color = Color(0.3, 0.85, 0.2)
const SUBTITLE_COLOR: Color = Color(0.7, 0.9, 0.4)
const BEST_COLOR: Color = Color(0.75, 0.75, 0.75)
const BTN_COLOR: Color = Color(0.15, 0.6, 0.2)
const BTN_HOVER_COLOR: Color = Color(0.2, 0.75, 0.28)

var _title_label: Label
var _best_label: Label
var _play_btn: Button

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.size = vp
	add_child(bg)

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var root: VBoxContainer = VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var top_spacer: Control = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(top_spacer)

	_title_label = Label.new()
	_title_label.text = "GUACBLASTER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override(&"font_size", 52)
	_title_label.add_theme_color_override(&"font_color", TITLE_COLOR)
	root.add_child(_title_label)

	var subtitle: Label = Label.new()
	subtitle.text = "SURVIVOR"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override(&"font_size", 24)
	subtitle.add_theme_color_override(&"font_color", SUBTITLE_COLOR)
	root.add_child(subtitle)

	var mid_spacer: Control = Control.new()
	mid_spacer.custom_minimum_size = Vector2(0.0, 48.0)
	root.add_child(mid_spacer)

	_play_btn = Button.new()
	_play_btn.text = "JUGAR"
	_play_btn.custom_minimum_size = Vector2(200.0, 60.0)
	_play_btn.add_theme_font_size_override(&"font_size", 26)
	var normal_sb: StyleBoxFlat = StyleBoxFlat.new()
	normal_sb.bg_color = BTN_COLOR
	normal_sb.corner_radius_top_left = 12
	normal_sb.corner_radius_top_right = 12
	normal_sb.corner_radius_bottom_left = 12
	normal_sb.corner_radius_bottom_right = 12
	_play_btn.add_theme_stylebox_override(&"normal", normal_sb)
	var hover_sb: StyleBoxFlat = normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = BTN_HOVER_COLOR
	_play_btn.add_theme_stylebox_override(&"hover", hover_sb)
	_play_btn.pressed.connect(_on_play_pressed)
	root.add_child(_play_btn)

	var upgrades_spacer: Control = Control.new()
	upgrades_spacer.custom_minimum_size = Vector2(0.0, 12.0)
	root.add_child(upgrades_spacer)

	var upgrades_btn: Button = Button.new()
	upgrades_btn.text = "MEJORAS"
	upgrades_btn.custom_minimum_size = Vector2(160.0, 44.0)
	upgrades_btn.add_theme_font_size_override(&"font_size", 18)
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	root.add_child(upgrades_btn)

	var settings_spacer: Control = Control.new()
	settings_spacer.custom_minimum_size = Vector2(0.0, 8.0)
	root.add_child(settings_spacer)

	var settings_btn: Button = Button.new()
	settings_btn.text = "CONFIGURACIÓN"
	settings_btn.custom_minimum_size = Vector2(160.0, 44.0)
	settings_btn.add_theme_font_size_override(&"font_size", 18)
	settings_btn.pressed.connect(_on_settings_pressed)
	root.add_child(settings_btn)

	var btn_spacer: Control = Control.new()
	btn_spacer.custom_minimum_size = Vector2(0.0, 24.0)
	root.add_child(btn_spacer)

	_best_label = Label.new()
	_best_label.text = "Mejor: %d" % SaveManager.get_best_score()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override(&"font_size", 18)
	_best_label.add_theme_color_override(&"font_color", BEST_COLOR)
	root.add_child(_best_label)

	var bottom_spacer: Control = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom_spacer)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/UpgradeScreen.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(SETTINGS_SCENE)

func get_title_label() -> Label:
	return _title_label

func get_best_label() -> Label:
	return _best_label

func get_play_button() -> Button:
	return _play_btn
