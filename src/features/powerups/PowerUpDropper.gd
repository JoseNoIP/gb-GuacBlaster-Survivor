class_name PowerUpDropper
extends Node
## Spawns falling PowerUpDrop items whenever the player levels up.
## Each triad is an independent batch. Picking one drop clears only its two siblings.
## Multiple batches can be on-screen simultaneously — each is resolved independently.
## Elite drops have batch_id -1 and are collected individually with no sibling cleanup.

const PowerUpDropGd := preload("res://src/features/powerups/PowerUpDrop.tscn")

var _batches: Dictionary = {}
var _next_batch_id: int = 0

func _ready() -> void:
	EventBus.powerup_selection_requested.connect(_on_powerup_selection_requested)
	EventBus.powerup_batch_cleared.connect(_on_powerup_batch_cleared)
	EventBus.elite_powerup_dropped.connect(_on_elite_powerup_dropped)
	EventBus.game_over.connect(func(_s: int, _d: float): _batches.clear())
	EventBus.game_won.connect(func(_s: int, _d: float): _batches.clear())

func _on_powerup_selection_requested(options: Array) -> void:
	var bid: int = _next_batch_id
	_next_batch_id += 1
	var batch: Array[Area2D] = []
	var vp: Rect2 = get_viewport().get_visible_rect()
	var count: int = options.size()
	for i: int in count:
		var drop: Area2D = PowerUpDropGd.instantiate() as Area2D
		drop.set(&"powerup_id", options[i] as StringName)
		drop.set(&"batch_id", bid)
		var section_w: float = vp.size.x / float(count)
		var drop_x: float = section_w * float(i) + section_w * 0.5
		drop_x = clampf(drop_x, 24.0, vp.size.x - 24.0)
		drop.position = Vector2(drop_x, -20.0)
		batch.append(drop)
		get_parent().call_deferred(&"add_child", drop)
	_batches[bid] = batch

func _on_powerup_batch_cleared(bid: int) -> void:
	if not _batches.has(bid):
		return
	var batch: Array = _batches[bid] as Array
	for drop in batch:
		if is_instance_valid(drop):
			drop.queue_free()
	_batches.erase(bid)

func _on_elite_powerup_dropped(pos: Vector2, powerup_id: StringName) -> void:
	var drop: Area2D = PowerUpDropGd.instantiate() as Area2D
	drop.set(&"powerup_id", powerup_id)
	drop.position = pos
	get_parent().call_deferred(&"add_child", drop)
