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
var _record_label: Label
var _gold_label: Label
var _restart_btn: Button
var _menu_btn: Button
var _scores_box: VBoxContainer
var _gold_this_run: int = 0
var _prev_best: int = 0

func _ready() -> void:
	layer = 20
	_build_ui()
	_bg.visible = false
	_panel.visible = false
	EventBus.game_over.connect(_on_game_over)
	EventBus.gold_earned.connect(_on_gold_earned)
	EventBus.game_started.connect(_on_game_started_reset)

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

	_record_label = Label.new()
	_record_label.text = "¡NUEVO RÉCORD!"
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override(&"font_size", 19)
	_record_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.1))
	_record_label.visible = false
	_panel.add_child(_record_label)

	_gold_label = Label.new()
	_gold_label.text = "+0 oro"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override(&"font_size", 20)
	_gold_label.add_theme_color_override(&"font_color", Color(1.0, 0.8, 0.1))
	_panel.add_child(_gold_label)

	var sep: Label = Label.new()
	sep.text = "── Mejores ──"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override(&"font_size", 11)
	sep.add_theme_color_override(&"font_color", Color(0.4, 0.4, 0.4))
	_panel.add_child(sep)

	_scores_box = VBoxContainer.new()
	_scores_box.add_theme_constant_override(&"separation", 2)
	_panel.add_child(_scores_box)

	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0.0, 20.0)
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
	var is_new_record: bool = score > _prev_best
	_score_label.text = "Score: 0"
	_best_label.text = "Mejor: %d" % SaveManager.get_best_score()
	_gold_label.text = "+%d oro" % _gold_this_run
	if GameManager.get_endless_mode() and GameManager.get_waves_cleared() > 0:
		_gold_label.text += "  ·  %d olas" % GameManager.get_waves_cleared()
	_record_label.visible = is_new_record
	_bg.visible = true
	_panel.modulate.a = 0.0
	_panel.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_panel, ^"modulate:a", 1.0, 0.28)
	tween.tween_method(
		func(v: float) -> void: _score_label.text = "Score: %d" % int(v),
		0.0, float(score), 1.1
	)
	_refresh_leaderboard(score)
	if is_new_record:
		tween.tween_callback(_flash_record)

func _refresh_leaderboard(current_score: int) -> void:
	for child in _scores_box.get_children():
		child.queue_free()
	var scores: Array = SaveManager.get_high_scores()
	var show_count: int = mini(3, scores.size())
	for i: int in show_count:
		var entry: Dictionary = scores[i] as Dictionary
		var entry_score: int = entry.get("score", 0) as int
		var char_name: String = entry.get("char", "") as String
		var won: bool = entry.get("won", false) as bool
		var is_current: bool = entry_score == current_score and i == 0
		var won_mark: String = " V" if won else ""
		var row: Label = Label.new()
		row.text = "%d.  %d  %s%s" % [i + 1, entry_score, char_name, won_mark]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override(&"font_size", 12)
		var row_color: Color = Color(1.0, 0.85, 0.1) if is_current else Color(0.5, 0.55, 0.5)
		row.add_theme_color_override(&"font_color", row_color)
		_scores_box.add_child(row)

func _on_gold_earned(amount: int) -> void:
	_gold_this_run += amount

func _flash_record() -> void:
	var t: Tween = create_tween().set_loops(3)
	t.tween_property(_record_label, ^"modulate:a", 0.1, 0.17)
	t.tween_property(_record_label, ^"modulate:a", 1.0, 0.17)

func _on_game_started_reset() -> void:
	_gold_this_run = 0
	_prev_best = SaveManager.get_best_score()

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

func get_gold_label() -> Label:
	return _gold_label

func get_restart_button() -> Button:
	return _restart_btn

func get_menu_button() -> Button:
	return _menu_btn
