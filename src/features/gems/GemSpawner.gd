class_name GemSpawner
extends Node2D
## Listens to enemy_destroyed and spawns XP gems at the death position.
## Tougher enemies burst into multiple gems so effort visibly equals reward.

func _ready() -> void:
	XPGem.magnet_active = false
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.game_started.connect(func() -> void: XPGem.magnet_active = false)

func _on_enemy_destroyed(_enemy_id: int, spawn_pos: Vector2, xp_value: int) -> void:
	if xp_value <= 0:
		return
	var count: int = _gem_count(xp_value)
	var per_gem: int = maxi(1, xp_value / count)
	for i: int in count:
		var gem: XPGem = XPGem.new()
		gem.xp_value = per_gem
		var offset: Vector2 = Vector2.ZERO
		if count > 1:
			var angle: float = (float(i) / float(count)) * TAU + randf() * 0.5
			offset = Vector2(cos(angle), sin(angle)) * randf_range(8.0, 22.0)
		gem.position = spawn_pos + offset
		get_parent().call_deferred(&"add_child", gem)

func _gem_count(xp_value: int) -> int:
	if xp_value >= 80:
		return 8
	if xp_value >= 30:
		return 5
	if xp_value >= 12:
		return 3
	return 1
