class_name HUD
extends CanvasLayer
## Heads-up display: hearts, XP bar, score, level, boss timer, and active power-up strip.
## Listens to EventBus signals — never references player or enemies directly.

const POWERUP_ABBREV: Dictionary = {
	&"triple_shot": "TS",
	&"super_guac": "SG",
	&"rapid_fire": "RF",
	&"mole_grenade": "MG",
	&"jalapeno_laser": "JL",
	&"spicy_bounce": "SB",
	&"nacho_wall": "NW",
	&"salsa_magnet": "SM",
	&"guac_storm": "GS",
}
const POWERUP_COLORS: Dictionary = {
	&"triple_shot": Color(0.4, 0.8, 1.0),
	&"super_guac": Color(0.3, 0.95, 0.3),
	&"rapid_fire": Color(1.0, 0.5, 0.1),
	&"mole_grenade": Color(1.0, 0.3, 0.3),
	&"jalapeno_laser": Color(1.0, 0.95, 0.1),
	&"spicy_bounce": Color(0.85, 0.3, 0.95),
	&"nacho_wall": Color(0.95, 0.85, 0.2),
	&"salsa_magnet": Color(0.3, 0.95, 0.95),
	&"guac_storm": Color(0.5, 1.0, 0.3),
}
const HEART_FULL_COLOR: Color = Color(0.9, 0.15, 0.15)
const HEART_EMPTY_COLOR: Color = Color(0.35, 0.35, 0.35)
const SCORE_COLOR: Color = Color(1.0, 1.0, 1.0)
const LEVEL_COLOR: Color = Color(1.0, 0.85, 0.2)
const TITLE_COLOR: Color = Color(1.0, 0.85, 0.2)
const XP_BAR_HEIGHT: float = 14.0

var _heart_labels: Array[Label] = []
var _xp_bar: ProgressBar
var _boss_hp_bar: ProgressBar
var _score_label: Label
var _level_label: Label
var _timer_label: Label
var _world_label: Label
var _world_tween: Tween
var _pause_btn: Button
var _powerup_strip: VBoxContainer
var _strip_pills: Dictionary = {}
var _displayed_score: int = 0
var _boss_spawned: bool = false
var _phase2_label: Label
var _phase2_tween: Tween
var _toast_label: Label
var _toast_tween: Tween
var _toast_queue: Array = []
var _toast_busy: bool = false

func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.powerup_stack_changed.connect(_on_powerup_stack_changed)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	EventBus.boss_spawned.connect(func(_id: int): _boss_spawned = true)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(func(_id: int): _boss_hp_bar.hide())
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.mission_completed.connect(_on_mission_completed)
	EventBus.weekly_challenge_completed.connect(_on_weekly_challenge_completed)

func _build_ui() -> void:
	_build_hearts()
	_build_score_and_level()
	_build_timer()
	_build_xp_bar()
	_build_boss_hp_bar()
	_build_powerup_strip()
	_build_pause_button()
	_build_world_label()
	_build_phase2_label()
	_build_toast()

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

func _build_boss_hp_bar() -> void:
	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.min_value = 0.0
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.anchor_left = 0.5
	_boss_hp_bar.anchor_right = 0.5
	_boss_hp_bar.anchor_top = 0.0
	_boss_hp_bar.anchor_bottom = 0.0
	_boss_hp_bar.offset_left = -90.0
	_boss_hp_bar.offset_right = 90.0
	_boss_hp_bar.offset_top = 52.0
	_boss_hp_bar.offset_bottom = 68.0
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.15, 0.1)
	_boss_hp_bar.add_theme_stylebox_override(&"fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.25, 0.05, 0.05)
	_boss_hp_bar.add_theme_stylebox_override(&"background", bg_style)
	_boss_hp_bar.hide()
	add_child(_boss_hp_bar)

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

func _build_world_label() -> void:
	_world_label = Label.new()
	_world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_label.anchor_left = 0.5
	_world_label.anchor_right = 0.5
	_world_label.anchor_top = 0.5
	_world_label.anchor_bottom = 0.5
	_world_label.offset_left = -80.0
	_world_label.offset_right = 80.0
	_world_label.offset_top = -40.0
	_world_label.offset_bottom = 10.0
	_world_label.add_theme_font_size_override(&"font_size", 32)
	_world_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	_world_label.hide()
	add_child(_world_label)

func _build_phase2_label() -> void:
	_phase2_label = Label.new()
	_phase2_label.text = "¡FASE 2!"
	_phase2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase2_label.anchor_left = 0.5
	_phase2_label.anchor_right = 0.5
	_phase2_label.anchor_top = 0.5
	_phase2_label.anchor_bottom = 0.5
	_phase2_label.offset_left = -80.0
	_phase2_label.offset_right = 80.0
	_phase2_label.offset_top = -60.0
	_phase2_label.offset_bottom = -10.0
	_phase2_label.add_theme_font_size_override(&"font_size", 38)
	_phase2_label.add_theme_color_override(&"font_color", Color(1.0, 0.2, 0.1))
	_phase2_label.hide()
	add_child(_phase2_label)

func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.anchor_top = 0.0
	_toast_label.anchor_bottom = 0.0
	_toast_label.offset_left = -140.0
	_toast_label.offset_right = 140.0
	_toast_label.offset_top = 80.0
	_toast_label.offset_bottom = 120.0
	_toast_label.add_theme_font_size_override(&"font_size", 14)
	_toast_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0))
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_toast_label)

func _build_powerup_strip() -> void:
	_powerup_strip = VBoxContainer.new()
	_powerup_strip.add_theme_constant_override("separation", 6)
	_powerup_strip.anchor_left = 1.0
	_powerup_strip.anchor_right = 1.0
	_powerup_strip.anchor_top = 0.0
	_powerup_strip.anchor_bottom = 0.0
	_powerup_strip.offset_left = -68.0
	_powerup_strip.offset_right = -4.0
	_powerup_strip.offset_top = 52.0
	_powerup_strip.offset_bottom = 420.0
	add_child(_powerup_strip)

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

func _process(_delta: float) -> void:
	if GameManager.get_state() != GameManager.GameState.PLAYING:
		return
	if _boss_spawned:
		_timer_label.text = "¡JEFE!"
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
		_timer_label.show()
		return
	var remaining: float = maxf(
		0.0, Constants.BOSS_SPAWN_INTERVAL - GameManager.get_session_time()
	)
	if remaining > Constants.BOSS_TIMER_SHOW_REMAINING:
		_timer_label.hide()
		return
	var mins: int = int(remaining) / 60
	var secs: int = int(remaining) % 60
	_timer_label.text = "JEFE EN: %02d:%02d" % [mins, secs]
	if remaining <= 30.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	else:
		_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_timer_label.show()

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

func _on_powerup_stack_changed(powerup_id: StringName, count: int) -> void:
	if count > 0:
		if not _strip_pills.has(powerup_id):
			var pill := Label.new()
			pill.add_theme_font_size_override("font_size", 16)
			var pill_color: Color = POWERUP_COLORS.get(powerup_id, Color(1.0, 1.0, 1.0)) as Color
			pill.add_theme_color_override("font_color", pill_color)
			pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_powerup_strip.add_child(pill)
			_strip_pills[powerup_id] = pill
		var abbrev: String = POWERUP_ABBREV.get(powerup_id, str(powerup_id).left(2).to_upper())
		(_strip_pills[powerup_id] as Label).text = "%s×%d" % [abbrev, count]
	else:
		if _strip_pills.has(powerup_id):
			(_strip_pills[powerup_id] as Label).queue_free()
			_strip_pills.erase(powerup_id)

func _on_boss_phase_changed(phase: int) -> void:
	if phase != 2:
		return
	_phase2_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_phase2_label.show()
	if _phase2_tween:
		_phase2_tween.kill()
	_phase2_tween = create_tween()
	_phase2_tween.tween_interval(1.2)
	_phase2_tween.tween_property(_phase2_label, "modulate:a", 0.0, 0.6)

func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_hp_bar.max_value = float(maximum)
	_boss_hp_bar.value = float(current)
	_boss_hp_bar.show()

func _show_world_banner() -> void:
	var world_idx: int = SaveManager.get_victories() % Constants.BACKGROUND_PALETTE.size()
	_world_label.text = "BIOMA %d" % (world_idx + 1)
	_world_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_world_label.show()
	if _world_tween:
		_world_tween.kill()
	_world_tween = create_tween()
	_world_tween.tween_interval(1.8)
	_world_tween.tween_property(_world_label, "modulate:a", 0.0, 0.8)

func _on_game_started() -> void:
	_displayed_score = 0
	_score_label.text = "0"
	_level_label.text = "Lvl 0"
	_xp_bar.value = 0.0
	_pause_btn.disabled = false
	_boss_spawned = false
	_boss_hp_bar.hide()
	_timer_label.hide()
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	for lbl: Label in _heart_labels:
		lbl.add_theme_color_override("font_color", HEART_FULL_COLOR)
	for pill: Label in _strip_pills.values():
		pill.queue_free()
	_strip_pills.clear()
	_show_world_banner()
	_show_character_toast()

func _show_character_toast() -> void:
	var selected_id: StringName = SaveManager.get_selected_character()
	var char_name: String = ""
	for def in Constants.CHARACTERS:
		if (def as Dictionary).get("id", &"") as StringName == selected_id:
			char_name = (def as Dictionary).get("name", "") as String
			break
	if not char_name.is_empty():
		_queue_toast("Jugando como: %s" % char_name, Color(0.3, 0.85, 0.2))

func _on_game_over(_score: int, _duration: float) -> void:
	_pause_btn.disabled = true
	_boss_hp_bar.hide()

func _on_achievement_unlocked(achievement_id: StringName) -> void:
	var name_str: String = ""
	for def in Constants.ACHIEVEMENTS:
		if (def as Dictionary).get("id", &"") as StringName == achievement_id:
			name_str = (def as Dictionary).get("name", "") as String
			break
	_queue_toast("★ %s" % name_str, Color(1.0, 0.85, 0.2))

func _on_weekly_challenge_completed(_challenge_id: StringName) -> void:
	_queue_toast("★ DESAFÍO SEMANAL COMPLETADO", Color(0.8, 0.5, 1.0))

func _on_mission_completed(mission_id: StringName, reward: int) -> void:
	var desc_str: String = str(mission_id)
	for def in Constants.DAILY_MISSION_POOL:
		if (def as Dictionary).get("id", &"") as StringName == mission_id:
			desc_str = (def as Dictionary).get("desc", str(mission_id)) as String
			break
	_queue_toast("✓ %s  +%d oro" % [desc_str, reward], Color(0.3, 0.95, 0.3))

func _queue_toast(text: String, color: Color) -> void:
	_toast_queue.append({"text": text, "color": color})
	if not _toast_busy:
		_show_next_toast()

func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_busy = false
		return
	_toast_busy = true
	var entry: Dictionary = _toast_queue.pop_front() as Dictionary
	_toast_label.text = entry.get("text", "") as String
	_toast_label.add_theme_color_override(&"font_color", entry.get("color", Color.WHITE) as Color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_show_next_toast)
