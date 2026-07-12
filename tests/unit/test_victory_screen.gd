extends GutTest
## Tests for VictoryScreen: visibility, labels, button signals.

const VictoryScreenGd := preload("res://src/features/ui/VictoryScreen.gd")
const BossWarningGd := preload("res://src/features/ui/BossWarning.gd")

var _screen: VictoryScreenGd
var _warning: BossWarningGd

func before_each() -> void:
	SaveManager._data = {
		"gold": 0,
		"upgrades": {
			"damage": 0, "speed": 0, "health": 0, "luck": 0,
			"gold_bonus": 0, "starter_shield": 0,
		},
		"best_score": 0,
		"total_sessions": 0,
	}
	GameManager.start_game()
	_screen = VictoryScreenGd.new()
	add_child_autofree(_screen)
	_warning = BossWarningGd.new()
	add_child_autofree(_warning)

# --- VictoryScreen ---

func test_panel_hidden_initially() -> void:
	assert_false(_screen.get_panel().visible)

func test_screen_hidden_initially() -> void:
	assert_false(_screen.visible)

func test_screen_shows_on_game_won() -> void:
	EventBus.game_won.emit(500, 125.0)
	assert_true(_screen.visible)

func test_score_label_shows_correct_value() -> void:
	EventBus.game_won.emit(500, 120.0)
	assert_eq(_screen.get_score_label().text, "Score: 500")

func test_time_label_shows_formatted_duration() -> void:
	EventBus.game_won.emit(0, 125.0)
	assert_eq(_screen.get_time_label().text, "Tiempo: 02:05")

func test_best_label_shows_saved_best() -> void:
	SaveManager._data["best_score"] = 999
	EventBus.game_won.emit(0, 120.0)
	assert_eq(_screen.get_best_label().text, "Mejor: 999")

func test_gold_label_shows_zero_when_no_gold_earned() -> void:
	EventBus.game_won.emit(0, 120.0)
	assert_eq(_screen.get_gold_label().text, "+0 oro")

func test_gold_label_accumulates_gold_earned() -> void:
	EventBus.gold_earned.emit(50)
	EventBus.gold_earned.emit(30)
	EventBus.game_won.emit(0, 120.0)
	assert_eq(_screen.get_gold_label().text, "+80 oro")

func test_gold_resets_on_game_started() -> void:
	EventBus.gold_earned.emit(100)
	EventBus.game_started.emit()
	EventBus.game_won.emit(0, 120.0)
	assert_eq(_screen.get_gold_label().text, "+0 oro")

func test_menu_button_text_is_ver_mejoras() -> void:
	assert_eq(_screen.get_menu_button().text, "VER MEJORAS")

func test_replay_button_emits_restart_requested() -> void:
	EventBus.game_won.emit(0, 120.0)
	watch_signals(EventBus)
	_screen.get_replay_button().pressed.emit()
	assert_signal_emitted(EventBus, "restart_requested")

func test_menu_button_emits_menu_requested() -> void:
	EventBus.game_won.emit(0, 120.0)
	watch_signals(EventBus)
	_screen.get_menu_button().pressed.emit()
	assert_signal_emitted(EventBus, "menu_requested")

# --- BossWarning ---

func test_warning_hidden_initially() -> void:
	assert_false(_warning.visible)

func test_warning_shows_on_boss_incoming() -> void:
	EventBus.boss_incoming.emit()
	assert_true(_warning.visible)

func test_warning_has_label() -> void:
	assert_not_null(_warning.get_label())

func test_warning_label_text() -> void:
	assert_eq(_warning.get_label().text, "¡JEFE EN CAMINO!")

# --- GameManager victory ---

func test_victory_triggers_on_boss_defeated() -> void:
	EventBus.boss_defeated.emit(1)
	assert_eq(GameManager.get_state(), GameManager.GameState.GAME_WON)

func test_victory_emits_game_won_signal() -> void:
	watch_signals(EventBus)
	EventBus.boss_defeated.emit(1)
	assert_signal_emitted(EventBus, "game_won")

func test_victory_does_not_trigger_when_not_playing() -> void:
	GameManager._on_player_died()
	EventBus.boss_defeated.emit(1)
	assert_eq(GameManager.get_state(), GameManager.GameState.GAME_OVER)
