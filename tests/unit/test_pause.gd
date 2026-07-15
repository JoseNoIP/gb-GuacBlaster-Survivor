extends GutTest
## Tests for pause system: GameManager state, PauseScreen visibility, signals.

const PauseScreenGd := preload("res://src/features/ui/PauseScreen.gd")

var _screen: PauseScreenGd

func before_each() -> void:
	GameManager.start_game()
	_screen = PauseScreenGd.new()
	add_child_autofree(_screen)

func after_each() -> void:
	if get_tree().paused:
		get_tree().paused = false

# --- PauseScreen UI ---

func test_pause_screen_hidden_by_default() -> void:
	assert_false(_screen.visible)

func test_pause_screen_has_panel() -> void:
	assert_not_null(_screen.get_panel())

func test_pause_screen_has_resume_button() -> void:
	assert_not_null(_screen.get_resume_button())

func test_pause_screen_has_menu_button() -> void:
	assert_not_null(_screen.get_menu_button())

func test_pause_screen_shows_on_game_paused_true() -> void:
	EventBus.game_paused.emit(true)
	assert_true(_screen.visible)

func test_pause_screen_hides_on_game_paused_false() -> void:
	EventBus.game_paused.emit(true)
	EventBus.game_paused.emit(false)
	assert_false(_screen.visible)

# --- GameManager pause/resume ---

func test_pause_game_changes_state_to_paused() -> void:
	GameManager.pause_game()
	assert_eq(GameManager.get_state(), GameManager.GameState.PAUSED)

func test_resume_game_changes_state_to_playing() -> void:
	GameManager.pause_game()
	GameManager.resume_game()
	assert_eq(GameManager.get_state(), GameManager.GameState.PLAYING)

func test_pause_game_emits_signal() -> void:
	watch_signals(EventBus)
	GameManager.pause_game()
	assert_signal_emitted_with_parameters(EventBus, "game_paused", [true])

func test_resume_game_emits_signal() -> void:
	GameManager.pause_game()
	watch_signals(EventBus)
	GameManager.resume_game()
	assert_signal_emitted_with_parameters(EventBus, "game_paused", [false])

func test_pause_ignored_when_not_playing() -> void:
	GameManager.pause_game()
	GameManager.pause_game()
	assert_eq(GameManager.get_state(), GameManager.GameState.PAUSED)

# --- Confirm-exit flow ---

func test_confirm_panel_hidden_initially() -> void:
	assert_false(_screen.get_confirm_panel().visible)

func test_menu_button_shows_confirm_panel() -> void:
	EventBus.game_paused.emit(true)
	_screen.get_menu_button().pressed.emit()
	assert_true(_screen.get_confirm_panel().visible)

func test_confirm_cancel_hides_confirm_panel() -> void:
	EventBus.game_paused.emit(true)
	_screen.get_menu_button().pressed.emit()
	_screen.get_confirm_cancel_button().pressed.emit()
	assert_false(_screen.get_confirm_panel().visible)

func test_confirm_exit_emits_menu_requested() -> void:
	EventBus.game_paused.emit(true)
	_screen.get_menu_button().pressed.emit()
	GameManager.pause_game()
	watch_signals(EventBus)
	_screen.get_confirm_exit_button().pressed.emit()
	assert_signal_emitted(EventBus, "menu_requested")

func test_resume_hides_confirm_panel() -> void:
	EventBus.game_paused.emit(true)
	_screen.get_menu_button().pressed.emit()
	EventBus.game_paused.emit(false)
	assert_false(_screen.get_confirm_panel().visible)

# --- Restart button ---

func test_pause_screen_has_restart_button() -> void:
	assert_not_null(_screen.get_restart_button())

func test_restart_button_emits_restart_requested() -> void:
	EventBus.game_paused.emit(true)
	GameManager.pause_game()
	watch_signals(EventBus)
	_screen.get_restart_button().pressed.emit()
	assert_signal_emitted(EventBus, "restart_requested")

func test_restart_button_resumes_game_before_restarting() -> void:
	GameManager.pause_game()
	_screen.get_restart_button().pressed.emit()
	assert_eq(GameManager.get_state(), GameManager.GameState.PLAYING)
