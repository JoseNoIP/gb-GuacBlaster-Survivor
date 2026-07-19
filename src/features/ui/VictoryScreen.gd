class_name VictoryScreen
extends CanvasLayer
## Victory overlay shown when the boss is defeated.

var _panel: Control
var _run_label: Label
var _score_label: Label
var _time_label: Label
var _best_label: Label
var _record_label: Label
var _gold_label: Label
var _replay_btn: Button
var _menu_btn: Button
var _scores_box: VBoxContainer
var _gold_this_run: int = 0
var _prev_best: int = 0
var _particles: CPUParticles2D

func _ready() -> void:
	layer = 20
	_build_ui()
	_panel.hide()
	hide()
	EventBus.game_won.connect(_on_game_won)
	EventBus.gold_earned.connect(_on_gold_earned)
	EventBus.game_started.connect(_on_game_started_reset)

func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
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
	_panel.offset_top = -170.0
	_panel.offset_bottom = 170.0
	add_child(_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 12)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "¡VICTORIA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 38)
	title.add_theme_color_override(&"font_color", Color(0.3, 0.9, 0.2))
	vbox.add_child(title)

	_run_label = Label.new()
	_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_label.add_theme_font_size_override(&"font_size", 15)
	_run_label.add_theme_color_override(&"font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(_run_label)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override(&"font_size", 22)
	_score_label.add_theme_color_override(&"font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(_score_label)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override(&"font_size", 15)
	_time_label.add_theme_color_override(&"font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_time_label)

	_best_label = Label.new()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override(&"font_size", 14)
	_best_label.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(_best_label)

	_record_label = Label.new()
	_record_label.text = "¡NUEVO RÉCORD!"
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override(&"font_size", 18)
	_record_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.1))
	_record_label.visible = false
	vbox.add_child(_record_label)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override(&"font_size", 18)
	_gold_label.add_theme_color_override(&"font_color", Color(1.0, 0.75, 0.0))
	vbox.add_child(_gold_label)

	var sep: Label = Label.new()
	sep.text = "── Mejores ──"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override(&"font_size", 11)
	sep.add_theme_color_override(&"font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(sep)

	_scores_box = VBoxContainer.new()
	_scores_box.add_theme_constant_override(&"separation", 2)
	vbox.add_child(_scores_box)

	_replay_btn = Button.new()
	_replay_btn.text = "JUGAR DE NUEVO"
	_replay_btn.custom_minimum_size = Vector2(200.0, 48.0)
	_replay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_replay_btn.add_theme_font_size_override(&"font_size", 17)
	_replay_btn.pressed.connect(_on_replay_pressed)
	vbox.add_child(_replay_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "VER MEJORAS"
	_menu_btn.custom_minimum_size = Vector2(200.0, 44.0)
	_menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_btn.add_theme_font_size_override(&"font_size", 15)
	_menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(_menu_btn)

	_particles = CPUParticles2D.new()
	_particles.one_shot = true
	_particles.explosiveness = 0.85
	_particles.amount = 70
	_particles.lifetime = 2.2
	_particles.direction = Vector2(0.0, -1.0)
	_particles.spread = 75.0
	_particles.gravity = Vector2(0.0, 320.0)
	_particles.initial_velocity_min = 100.0
	_particles.initial_velocity_max = 280.0
	_particles.scale_amount_min = 4.0
	_particles.scale_amount_max = 10.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 24.0
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(0.3, 0.95, 0.2, 1.0))
	grad.add_point(0.35, Color(1.0, 0.85, 0.1, 1.0))
	grad.add_point(0.7, Color(0.3, 0.85, 1.0, 0.7))
	grad.set_color(1, Color(0.3, 0.9, 0.2, 0.0))
	_particles.color_ramp = grad
	_particles.emitting = false
	add_child(_particles)

func _on_game_won(score: int, duration: float) -> void:
	var is_new_record: bool = score > _prev_best
	_run_label.text = tr(&"VICTORY_RUN") % SaveManager.get_victories()
	_score_label.text = tr(&"LABEL_SCORE") % 0
	var mins: int = int(duration) / 60
	var secs: int = int(duration) % 60
	_time_label.text = tr(&"LABEL_TIME") % ("%02d:%02d" % [mins, secs])
	_best_label.text = tr(&"LABEL_BEST") % SaveManager.get_best_score()
	_gold_label.text = tr(&"LABEL_GOLD_EARNED") % _gold_this_run
	_record_label.visible = is_new_record
	_refresh_leaderboard(score)
	get_tree().create_timer(3.0).timeout.connect(
		func() -> void: _reveal(score, is_new_record)
	)

func _reveal(score: int, is_new_record: bool) -> void:
	_panel.modulate.a = 0.0
	_panel.show()
	show()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_particles.position = Vector2(vp.x * 0.5, vp.y * 0.38)
	_particles.emitting = true
	var tween: Tween = create_tween()
	tween.tween_property(_panel, ^"modulate:a", 1.0, 0.3)
	tween.tween_method(
		func(v: float) -> void: _score_label.text = tr(&"LABEL_SCORE") % int(v),
		0.0, float(score), 1.2
	)
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

func _flash_record() -> void:
	var t: Tween = create_tween().set_loops(3)
	t.tween_property(_record_label, ^"modulate:a", 0.1, 0.17)
	t.tween_property(_record_label, ^"modulate:a", 1.0, 0.17)

func _on_gold_earned(amount: int) -> void:
	_gold_this_run += amount

func _on_game_started_reset() -> void:
	_gold_this_run = 0
	_prev_best = SaveManager.get_best_score()

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
