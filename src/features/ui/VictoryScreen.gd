class_name VictoryScreen
extends CanvasLayer
## Victory overlay shown when the player survives SESSION_TARGET_MIN seconds.

var _panel: Control
var _run_label: Label
var _score_label: Label
var _time_label: Label
var _best_label: Label
var _gold_label: Label
var _replay_btn: Button
var _menu_btn: Button
var _gold_this_run: int = 0

func _ready() -> void:
	layer = 20
	_build_ui()
	_panel.hide()
	hide()
	EventBus.game_won.connect(_on_game_won)
	EventBus.gold_earned.connect(_on_gold_earned)
	EventBus.game_started.connect(_on_game_started_reset)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = Control.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -145.0
	_panel.offset_right = 145.0
	_panel.offset_top = -150.0
	_panel.offset_bottom = 150.0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "¡SOBREVIVISTE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.2))
	vbox.add_child(title)

	_run_label = Label.new()
	_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_label.add_theme_font_size_override("font_size", 16)
	_run_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(_run_label)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_score_label)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 16)
	_time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_time_label)

	_best_label = Label.new()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override("font_size", 15)
	_best_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
	vbox.add_child(_best_label)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.0))
	vbox.add_child(_gold_label)

	_replay_btn = Button.new()
	_replay_btn.text = "JUGAR DE NUEVO"
	_replay_btn.custom_minimum_size = Vector2(180.0, 46.0)
	_replay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_replay_btn.pressed.connect(_on_replay_pressed)
	vbox.add_child(_replay_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "VER MEJORAS"
	_menu_btn.custom_minimum_size = Vector2(180.0, 46.0)
	_menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(_menu_btn)

func _on_game_won(score: int, duration: float) -> void:
	_run_label.text = "— Ronda %d —" % SaveManager.get_total_sessions()
	_score_label.text = "Score: %d" % score
	var mins: int = int(duration) / 60
	var secs: int = int(duration) % 60
	_time_label.text = "Tiempo: %02d:%02d" % [mins, secs]
	_best_label.text = "Mejor: %d" % SaveManager.get_best_score()
	_gold_label.text = "+%d oro" % _gold_this_run
	_panel.show()
	show()

func _on_gold_earned(amount: int) -> void:
	_gold_this_run += amount

func _on_game_started_reset() -> void:
	_gold_this_run = 0

func _on_replay_pressed() -> void:
	EventBus.restart_requested.emit()

func _on_menu_pressed() -> void:
	EventBus.menu_requested.emit()

func get_panel() -> Control:
	return _panel

func get_run_label() -> Label:
	return _run_label

func get_score_label() -> Label:
	return _score_label

func get_time_label() -> Label:
	return _time_label

func get_best_label() -> Label:
	return _best_label

func get_gold_label() -> Label:
	return _gold_label

func get_replay_button() -> Button:
	return _replay_btn

func get_menu_button() -> Button:
	return _menu_btn
