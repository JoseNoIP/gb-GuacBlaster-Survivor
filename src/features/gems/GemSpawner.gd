class_name GemSpawner
extends Node2D
## Listens to enemy_destroyed and spawns an XPGem at the death position.
## Also resets XPGem.magnet_active at the start of each session.

func _ready() -> void:
	XPGem.magnet_active = false
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)

func _on_enemy_destroyed(_enemy_id: int, spawn_pos: Vector2, xp_value: int) -> void:
	var gem: XPGem = XPGem.new()
	gem.xp_value = xp_value
	gem.position = spawn_pos
	get_parent().call_deferred(&"add_child", gem)
