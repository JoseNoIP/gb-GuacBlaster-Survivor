extends Node
## Entry point. Boots into Game scene on the next frame (deferred to avoid
## modifying the scene tree during _ready).

const GAME_SCENE: String = "res://src/scenes/Game.tscn"

func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
