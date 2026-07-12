class_name PowerUpDropper
extends Node
## Spawns falling PowerUpDrop items whenever the player levels up.
## When one drop is collected, the remaining drops in the batch disappear.

const PowerUpDropGd := preload("res://src/features/powerups/PowerUpDrop.tscn")

var _current_batch: Array[Area2D] = []

func _ready() -> void:
	EventBus.powerup_selection_requested.connect(_on_powerup_selection_requested)
	EventBus.powerup_selected.connect(_on_powerup_selected)

func _on_powerup_selection_requested(options: Array) -> void:
	_current_batch.clear()
	var vp: Rect2 = get_viewport().get_visible_rect()
	var count: int = options.size()
	for i: int in count:
		var drop: Area2D = PowerUpDropGd.instantiate() as Area2D
		drop.set(&"powerup_id", options[i] as StringName)
		var section_w: float = vp.size.x / float(count)
		var drop_x: float = section_w * float(i) + section_w * 0.5
		drop_x = clampf(drop_x, 24.0, vp.size.x - 24.0)
		drop.position = Vector2(drop_x, -20.0)
		_current_batch.append(drop)
		get_parent().call_deferred(&"add_child", drop)

func _on_powerup_selected(_powerup_id: StringName) -> void:
	for drop: Area2D in _current_batch:
		if is_instance_valid(drop):
			drop.queue_free()
	_current_batch.clear()
