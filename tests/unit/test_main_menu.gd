extends GutTest
## Tests for MainMenu: title label, best score display, play button.

const MainMenuGd := preload("res://src/scenes/MainMenu.gd")

var _menu: MainMenu

func before_each() -> void:
	_menu = MainMenuGd.new()
	add_child_autofree(_menu)

func test_title_label_shows_game_name() -> void:
	assert_eq(_menu.get_title_label().text, "GUACBLASTER")

func test_play_button_exists() -> void:
	assert_not_null(_menu.get_play_button())

func test_best_label_shows_saved_value() -> void:
	assert_eq(_menu.get_best_label().text, "Mejor: %d" % SaveManager.get_best_score())
