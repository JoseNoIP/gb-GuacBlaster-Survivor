extends GutTest
## Tests for GameOverScreen: visibility, score display, best score, restart signal.

const GameOverScreenGd := preload("res://src/features/ui/GameOverScreen.gd")

var _screen: GameOverScreen

func before_each() -> void:
	_screen = GameOverScreenGd.new()
	add_child_autofree(_screen)

func test_panel_hidden_initially() -> void:
	assert_false(_screen.get_panel().visible)

func test_panel_visible_after_game_over() -> void:
	EventBus.game_over.emit(100, 30.0)
	assert_true(_screen.get_panel().visible)

func test_score_label_shows_correct_value() -> void:
	EventBus.game_over.emit(250, 60.0)
	assert_eq(_screen.get_score_label().text, "Score: 0")

func test_restart_button_emits_restart_requested() -> void:
	EventBus.game_over.emit(0, 0.0)
	watch_signals(EventBus)
	_screen.get_restart_button().pressed.emit()
	assert_signal_emitted(EventBus, "restart_requested")

func test_best_label_shows_best_score() -> void:
	EventBus.game_over.emit(0, 0.0)
	assert_eq(_screen.get_best_label().text, "Mejor: %d" % SaveManager.get_best_score())

func test_menu_button_emits_menu_requested() -> void:
	EventBus.game_over.emit(0, 0.0)
	watch_signals(EventBus)
	_screen.get_menu_button().pressed.emit()
	assert_signal_emitted(EventBus, "menu_requested")

func test_gold_label_shows_zero_when_no_gold_earned() -> void:
	EventBus.game_over.emit(0, 0.0)
	assert_eq(_screen.get_gold_label().text, "+0 oro")

func test_gold_label_accumulates_gold_earned() -> void:
	EventBus.gold_earned.emit(40)
	EventBus.gold_earned.emit(20)
	EventBus.game_over.emit(0, 0.0)
	assert_eq(_screen.get_gold_label().text, "+60 oro")

func test_gold_resets_on_game_started() -> void:
	EventBus.gold_earned.emit(100)
	EventBus.game_started.emit()
	EventBus.game_over.emit(0, 0.0)
	assert_eq(_screen.get_gold_label().text, "+0 oro")
