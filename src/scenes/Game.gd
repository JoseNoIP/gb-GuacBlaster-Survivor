extends Node2D
## Game scene controller. Starts the session on load.

func _ready() -> void:
	GameManager.start_game()
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.menu_requested.connect(_on_menu_requested)

func _on_restart_requested() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/Game.tscn")

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/MainMenu.tscn")
