class_name HUD
extends CanvasLayer
## Heads-up display: hearts, XP bar, score, level, and power-up selection overlay.
## Listens to EventBus signals — never references player or enemies directly.

const POWERUP_NAMES: Dictionary = {
	&"triple_shot": "Disparo Triple",
	&"super_guac": "Super-Guac",
	&"rapid_fire": "Fuego Rapido",
	&"mole_grenade": "Granada Mole",
	&"jalapeno_laser": "Laser Jalapeno",
	&"spicy_bounce": "Rebote Picante",
	&"nacho_wall": "Muro Nachos",
	&"salsa_magnet": "Iman Salsa",
}
const HEART_FULL_COLOR: Color = Color(0.9, 0.15, 0.15)
const HEART_EMPTY_COLOR: Color = Color(0.35, 0.35, 0.35)
const SCORE_COLOR: Color = Color(1.0, 1.0, 1.0)
const LEVEL_COLOR: Color = Color(1.0, 0.85, 0.2)
const TITLE_COLOR: Color = Color(1.0, 0.85, 0.2)
const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.65)
const CARD_MIN_SIZE: Vector2 = Vector2(100.0, 140.0)
const XP_BAR_HEIGHT: float = 14.0

var _heart_labels: Array[Label] = []
var _xp_bar: ProgressBar
var _score_label: Label
var _level_label: Label
var _timer_label: Label
var _pause_btn: Button
var _powerup_panel: Control
var _card_buttons: Array[Button] = []
var _current_options: Array = []
var _displayed_score: int = 0

func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.powerup_selection_requested.connect(_on_powerup_selection_requested)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)

func _build_ui() -> void:
	_build_hearts()
	_build_score_and_level()
	_build_timer()
	_build_xp_bar()
	_build_powerup_panel()
	_build_pause_button()

func _build_hearts() -> void:
	var container := HBoxContainer.new()
	container.position = Vector2(10.0, 16.0)
	container.add_theme_constant_override("separation", 4)
	add_child(container)
	for _i: int in Constants.PLAYER_BASE_HEALTH:
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", HEART_FULL_COLOR)
		container.add_child(lbl)
		_heart_labels.append(lbl)

func _build_score_and_level() -> void:
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", SCORE_COLOR)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.anchor_left = 0.5
	_score_label.anchor_right = 0.5
	_score_label.offset_left = -60.0
	_score_label.offset_right = 60.0
	_score_label.offset_top = 16.0
	_score_label.offset_bottom = 48.0
	add_child(_score_label)

	_level_label = Label.new()
	_level_label.text = "Lvl 0"
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", LEVEL_COLOR)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.anchor_left = 1.0
	_level_label.anchor_right = 1.0
	_level_label.offset_left = -140.0
	_level_label.offset_right = -50.0
	_level_label.offset_top = 16.0
	_level_label.offset_bottom = 44.0
	add_child(_level_label)

func _build_xp_bar() -> void:
	_xp_bar = ProgressBar.new()
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = float(Constants.XP_BASE_REQUIRED)
	_xp_bar.value = 0.0
	_xp_bar.show_percentage = false
	_xp_bar.anchor_left = 0.0
	_xp_bar.anchor_right = 1.0
	_xp_bar.anchor_top = 1.0
	_xp_bar.anchor_bottom = 1.0
	_xp_bar.offset_top = -XP_BAR_HEIGHT
	_xp_bar.offset_bottom = 0.0
	add_child(_xp_bar)

func _build_timer() -> void:
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.anchor_left = 0.5
	_timer_label.anchor_right = 0.5
	_timer_label.offset_left = -35.0
	_timer_label.offset_right = 35.0
	_timer_label.offset_top = 50.0
	_timer_label.offset_bottom = 70.0
	_timer_label.add_theme_font_size_override("font_size", 16)
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(_timer_label)

func _process(_delta: float) -> void:
	if GameManager.get_state() != GameManager.GameState.PLAYING:
		return
	var remaining: float = maxf(
		0.0, Constants.SESSION_TARGET_MIN - GameManager.get_session_time()
	)
	var mins: int = int(remaining) / 60
	var secs: int = int(remaining) % 60
	_timer_label.text = "%02d:%02d" % [mins, secs]
	if remaining <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	else:
		_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _build_pause_button() -> void:
	_pause_btn = Button.new()
	_pause_btn.text = "||"
	_pause_btn.anchor_left = 1.0
	_pause_btn.anchor_right = 1.0
	_pause_btn.offset_left = -44.0
	_pause_btn.offset_right = -4.0
	_pause_btn.offset_top = 4.0
	_pause_btn.offset_bottom = 40.0
	_pause_btn.pressed.connect(func(): GameManager.pause_game())
	add_child(_pause_btn)

func get_pause_button() -> Button:
	return _pause_btn

func _build_powerup_panel() -> void:
	_powerup_panel = Control.new()
	_powerup_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_powerup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_powerup_panel.hide()
	add_child(_powerup_panel)

	var dim := ColorRect.new()
	dim.color = OVERLAY_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_powerup_panel.add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -165.0
	vbox.offset_right = 165.0
	vbox.offset_top = -110.0
	vbox.offset_bottom = 110.0
	_powerup_panel.add_child(vbox)

	var title := Label.new()
	title.text = "¡Sube de nivel!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 10)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_row)

	for i: int in Constants.POWERUP_CARDS_PER_LEVEL:
		var btn := Button.new()
		btn.text = "???"
		btn.custom_minimum_size = CARD_MIN_SIZE
		btn.pressed.connect(_on_card_pressed.bind(i))
		cards_row.add_child(btn)
		_card_buttons.append(btn)

func _on_player_health_changed(current: int, maximum: int) -> void:
	while _heart_labels.size() < maximum:
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", HEART_FULL_COLOR)
		_heart_labels[0].get_parent().add_child(lbl)
		_heart_labels.append(lbl)
	for i: int in _heart_labels.size():
		if i < current:
			_heart_labels[i].add_theme_color_override("font_color", HEART_FULL_COLOR)
		else:
			_heart_labels[i].add_theme_color_override("font_color", HEART_EMPTY_COLOR)

func _on_xp_collected(amount: int, total: int, required: int) -> void:
	_displayed_score += amount
	_xp_bar.max_value = float(required)
	_xp_bar.value = float(total)
	_score_label.text = str(_displayed_score)

func _on_player_level_up(new_level: int) -> void:
	_level_label.text = "Lvl %d" % new_level
	_xp_bar.value = 0.0

func _on_powerup_selection_requested(options: Array) -> void:
	_current_options = options
	for i: int in _card_buttons.size():
		var btn: Button = _card_buttons[i]
		if i < options.size():
			var id: StringName = options[i] as StringName
			btn.text = POWERUP_NAMES.get(id, str(id))
			btn.show()
		else:
			btn.hide()
	_powerup_panel.show()

func _on_card_pressed(index: int) -> void:
	if index >= _current_options.size():
		return
	var id: StringName = _current_options[index] as StringName
	_powerup_panel.hide()
	EventBus.powerup_selected.emit(id)

func _on_game_started() -> void:
	_displayed_score = 0
	_score_label.text = "0"
	_level_label.text = "Lvl 0"
	_xp_bar.value = 0.0
	_powerup_panel.hide()
	_pause_btn.disabled = false
	var total_secs: int = int(Constants.SESSION_TARGET_MIN)
	_timer_label.text = "%02d:%02d" % [total_secs / 60, total_secs % 60]
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	for lbl: Label in _heart_labels:
		lbl.add_theme_color_override("font_color", HEART_FULL_COLOR)

func _on_game_over(_score: int, _duration: float) -> void:
	_powerup_panel.hide()
	_pause_btn.disabled = true
