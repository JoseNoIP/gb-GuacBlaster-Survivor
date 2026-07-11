extends Node2D
## Game scene controller. Starts the session on load.

func _ready() -> void:
	GameManager.start_game()
