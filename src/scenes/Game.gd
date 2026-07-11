extends Node2D
## Game scene controller. Starts the session on load.
## TODO: remove _auto_select_powerup once PowerUpSelectionUI is implemented (HUD feature).

func _ready() -> void:
	GameManager.start_game()
	EventBus.powerup_selection_requested.connect(_auto_select_powerup)

func _auto_select_powerup(options: Array) -> void:
	if options.is_empty():
		return
	EventBus.powerup_selected.emit(options[0] as StringName)
