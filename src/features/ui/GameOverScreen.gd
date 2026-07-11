class_name GameOverScreen
extends CanvasLayer
## Overlay shown when game_over fires. Displays final score, best score,
## and buttons: restart (EventBus.restart_requested) and menu (EventBus.menu_requested).

const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.72)
const TITLE_COLOR: Color = Color(1.0, 0.25, 0.1)
const SCORE_COLOR: Color = Color(1.0, 0.85, 0.3)
const BEST_COLOR: Color = Color(0.7, 0.7, 0.7)
const BTN_NORMAL: Color = Color(0.15, 0.6, 0.2)
const BTN_HOVER: Color = Color(0.2, 0.75, 0.28)

var _bg: ColorRect
var _panel: Control
var _score_label: Label
var _best_label: Label
var _restart_btn: Button
var _menu_btn: Button

func _ready() -> void:
	layer = 20
	_build_ui()
	_bg.visible = false
	_panel.visible = false
	EventBus.game_over.connect(_on_game_over)

func _build_ui() -> void:
	_bg = ColorRect.new()
	var bg: ColorRect = _bg
	bg.color = OVERLAY_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = VBoxContainer.new()
	_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(280.0, 320.0)
	_panel.offset_left = -140.0
	_panel.offset_top = -160.0
	_panel.offset_right = 140.0
	_panel.offset_bottom = 160.0
	add_child(_panel)

	var title: Label = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 42)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	_panel.add_child(title)

	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0.0, 24.0)
	_panel.add_child(spacer1)

	_score_label = Label.new()
	_score_label.text = "Score: 0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override(&"font_size", 28)
	_score_label.add_theme_color_override(&"font_color", SCORE_COLOR)
	_panel.add_child(_score_label)

	_best_label = Label.new()
	_best_label.text = "Mejor: 0"
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override(&"font_size", 18)
	_best_label.add_theme_color_override(&"font_color", BEST_COLOR)
	_panel.add_child(_best_label)

	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0.0, 32.0)
	_panel.add_child(spacer2)

	_restart_btn = Button.new()
	_restart_btn.text = "JUGAR DE NUEVO"
	_restart_btn.custom_minimum_size = Vector2(220.0, 54.0)
	_restart_btn.add_theme_font_size_override(&"font_size", 20)
	var normal_sb: StyleBoxFlat = StyleBoxFlat.new()
	normal_sb.bg_color = BTN_NORMAL
	normal_sb.corner_radius_top_left = 10
	normal_sb.corner_radius_top_right = 10
	normal_sb.corner_radius_bottom_left = 10
	normal_sb.corner_radius_bottom_right = 10
	_restart_btn.add_theme_stylebox_override(&"normal", normal_sb)
	var hover_sb: StyleBoxFlat = normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = BTN_HOVER
	_restart_btn.add_theme_stylebox_override(&"hover", hover_sb)
	_restart_btn.pressed.connect(_on_restart_pressed)
	_panel.add_child(_restart_btn)

	var spacer3: Control = Control.new()
	spacer3.custom_minimum_size = Vector2(0.0, 12.0)
	_panel.add_child(spacer3)

	_menu_btn = Button.new()
	_menu_btn.text = "MENÚ PRINCIPAL"
	_menu_btn.custom_minimum_size = Vector2(220.0, 44.0)
	_menu_btn.add_theme_font_size_override(&"font_size", 16)
	var menu_sb: StyleBoxFlat = StyleBoxFlat.new()
	menu_sb.bg_color = Color(0.25, 0.25, 0.25)
	menu_sb.corner_radius_top_left = 10
	menu_sb.corner_radius_top_right = 10
	menu_sb.corner_radius_bottom_left = 10
	menu_sb.corner_radius_bottom_right = 10
	_menu_btn.add_theme_stylebox_override(&"normal", menu_sb)
	var menu_hover_sb: StyleBoxFlat = menu_sb.duplicate() as StyleBoxFlat
	menu_hover_sb.bg_color = Color(0.35, 0.35, 0.35)
	_menu_btn.add_theme_stylebox_override(&"hover", menu_hover_sb)
	_menu_btn.pressed.connect(_on_menu_pressed)
	_panel.add_child(_menu_btn)

func _on_game_over(score: int, _duration: float) -> void:
	_score_label.text = "Score: %d" % score
	_best_label.text = "Mejor: %d" % SaveManager.get_best_score()
	_bg.visible = true
	_panel.visible = true

func _on_restart_pressed() -> void:
	EventBus.restart_requested.emit()

func _on_menu_pressed() -> void:
	EventBus.menu_requested.emit()

func get_panel() -> Control:
	return _panel

func get_score_label() -> Label:
	return _score_label

func get_best_label() -> Label:
	return _best_label

func get_restart_button() -> Button:
	return _restart_btn

func get_menu_button() -> Button:
	return _menu_btn
