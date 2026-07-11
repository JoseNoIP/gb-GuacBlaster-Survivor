extends GutTest
## Unit tests for HUD — hearts, XP bar, score, level label, and power-up panel.

const HUDGd := preload("res://src/features/ui/HUD.gd")

var _hud: HUD

func before_each() -> void:
	_hud = HUD.new()
	add_child_autofree(_hud)

# --- Power-up panel ---

func test_powerup_panel_hidden_initially() -> void:
	assert_false(_hud._powerup_panel.visible)

func test_powerup_panel_shows_on_selection_requested() -> void:
	EventBus.powerup_selection_requested.emit([&"triple_shot"])
	assert_true(_hud._powerup_panel.visible)

func test_card_text_matches_powerup_name() -> void:
	EventBus.powerup_selection_requested.emit([&"rapid_fire", &"triple_shot"])
	assert_eq(_hud._card_buttons[0].text, "Fuego Rapido")
	assert_eq(_hud._card_buttons[1].text, "Disparo Triple")

func test_card_press_hides_panel() -> void:
	EventBus.powerup_selection_requested.emit([&"triple_shot"])
	_hud._card_buttons[0].pressed.emit()
	assert_false(_hud._powerup_panel.visible)

func test_card_press_emits_powerup_selected() -> void:
	watch_signals(EventBus)
	EventBus.powerup_selection_requested.emit([&"triple_shot", &"rapid_fire"])
	_hud._card_buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(EventBus, "powerup_selected", [&"triple_shot"])

func test_second_card_emits_second_option() -> void:
	watch_signals(EventBus)
	EventBus.powerup_selection_requested.emit([&"triple_shot", &"rapid_fire"])
	_hud._card_buttons[1].pressed.emit()
	assert_signal_emitted_with_parameters(EventBus, "powerup_selected", [&"rapid_fire"])

func test_game_over_hides_powerup_panel() -> void:
	EventBus.powerup_selection_requested.emit([&"triple_shot"])
	EventBus.game_over.emit(0, 0.0)
	assert_false(_hud._powerup_panel.visible)

# --- XP bar ---

func test_xp_bar_value_updates_on_xp_collected() -> void:
	EventBus.xp_collected.emit(5, 30, 100)
	assert_eq(_hud._xp_bar.value, 30.0)

func test_xp_bar_max_updates_on_xp_collected() -> void:
	EventBus.xp_collected.emit(5, 30, 150)
	assert_eq(_hud._xp_bar.max_value, 150.0)

func test_xp_bar_resets_on_level_up() -> void:
	EventBus.xp_collected.emit(5, 50, 100)
	EventBus.player_level_up.emit(1)
	assert_eq(_hud._xp_bar.value, 0.0)

# --- Score ---

func test_score_accumulates_xp_amounts() -> void:
	EventBus.xp_collected.emit(5, 5, 100)
	EventBus.xp_collected.emit(20, 25, 100)
	assert_eq(_hud._score_label.text, "25")

func test_score_resets_on_game_started() -> void:
	EventBus.xp_collected.emit(50, 50, 100)
	EventBus.game_started.emit()
	assert_eq(_hud._score_label.text, "0")

# --- Level label ---

func test_level_label_updates_on_level_up() -> void:
	EventBus.player_level_up.emit(3)
	assert_eq(_hud._level_label.text, "Lvl 3")
