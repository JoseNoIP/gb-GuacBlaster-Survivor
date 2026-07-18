extends Node
## Entry point. Routes to language selector on first run, otherwise MainMenu.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"
const LANG_SELECT_SCENE: String = "res://src/scenes/LanguageSelectScreen.tscn"

func _ready() -> void:
	var target: String = (
		LANG_SELECT_SCENE if SaveManager.get_language().is_empty() else MAIN_MENU_SCENE
	)
	get_tree().change_scene_to_file.call_deferred(target)
