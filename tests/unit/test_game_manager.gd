extends GutTest
## Unit tests for GameManager state machine.

func before_each() -> void:
	GameManager.start_game()

func test_start_game_sets_playing_state() -> void:
	assert_eq(GameManager.get_state(), GameManager.GameState.PLAYING)

func test_start_game_resets_score() -> void:
	assert_eq(GameManager.get_score(), 0)

func test_start_game_resets_level() -> void:
	assert_eq(GameManager.get_current_level(), 0)

func test_gem_collected_increases_score() -> void:
	GameManager._on_gem_collected(10)
	assert_eq(GameManager.get_score(), 10)

func test_player_died_transitions_to_game_over() -> void:
	GameManager._on_player_died()
	assert_eq(GameManager.get_state(), GameManager.GameState.GAME_OVER)

func test_xp_below_threshold_does_not_level_up() -> void:
	GameManager._on_xp_collected(50, 50, 100)
	assert_eq(GameManager.get_current_level(), 0)
	assert_eq(GameManager.get_state(), GameManager.GameState.PLAYING)

func test_xp_at_threshold_triggers_level_up() -> void:
	GameManager._on_xp_collected(100, 100, 100)
	assert_eq(GameManager.get_current_level(), 1)
	assert_eq(GameManager.get_state(), GameManager.GameState.LEVEL_UP)

func test_powerup_selected_resumes_playing() -> void:
	GameManager._on_xp_collected(100, 100, 100)
	GameManager._on_powerup_selected(&"rapid_fire")
	assert_eq(GameManager.get_state(), GameManager.GameState.PLAYING)

func test_pick_powerup_options_returns_correct_count() -> void:
	var options: Array = GameManager._pick_powerup_options()
	assert_eq(options.size(), Constants.POWERUP_CARDS_PER_LEVEL)

func test_pick_powerup_options_returns_valid_ids() -> void:
	var options: Array = GameManager._pick_powerup_options()
	for opt: Variant in options:
		assert_true(Constants.POWERUP_POOL.has(opt),
			"Option '%s' not in POWERUP_POOL" % opt)
