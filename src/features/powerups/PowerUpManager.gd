class_name PowerUpManager
extends Node
## Manages timed power-up stacks. Each pick-up adds one timed stack.
## Grenade fires continuously while any mole_grenade stack is active.
## Laser spawns a 2s beam that follows the player while active.
## Emits powerup_stack_changed on every add/expire.

var _stacks: Dictionary = {}
var _timers: Dictionary = {}
var _grenade_cooldown: float = 0.0
var _active_lasers: Array[Dictionary] = []

func _ready() -> void:
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.game_over.connect(_on_session_ended)
	EventBus.game_won.connect(_on_session_ended)

func _process(delta: float) -> void:
	_tick_timers(delta)
	_tick_grenade(delta)
	_update_laser_positions()

func _on_powerup_selected(powerup_id: StringName) -> void:
	if not _timers.has(powerup_id):
		_timers[powerup_id] = []
	var duration: float = Constants.POWERUP_DURATION
	if powerup_id == &"jalapeno_laser":
		duration = Constants.JALAPENO_LASER_DURATION
	(_timers[powerup_id] as Array).append(duration)
	_stacks[powerup_id] = (_timers[powerup_id] as Array).size()
	EventBus.powerup_stack_changed.emit(powerup_id, int(_stacks[powerup_id]))

	if powerup_id == &"jalapeno_laser":
		_spawn_laser()
	elif powerup_id == &"mole_grenade" and _grenade_cooldown <= 0.0:
		_grenade_cooldown = Constants.MOLE_GRENADE_COOLDOWN

func _tick_timers(delta: float) -> void:
	var ids: Array = _timers.keys()
	for idx: int in ids.size():
		var pid: StringName = ids[idx] as StringName
		var arr: Array = _timers[pid] as Array
		var i: int = arr.size() - 1
		while i >= 0:
			arr[i] = float(arr[i]) - delta
			if float(arr[i]) <= 0.0:
				arr.remove_at(i)
				_stacks[pid] = arr.size()
				EventBus.powerup_stack_changed.emit(pid, int(_stacks[pid]))
				EventBus.powerup_expired.emit(pid)
			i -= 1

func _tick_grenade(delta: float) -> void:
	if int(_stacks.get(&"mole_grenade", 0)) <= 0:
		return
	_grenade_cooldown -= delta
	if _grenade_cooldown <= 0.0:
		_grenade_cooldown = Constants.MOLE_GRENADE_COOLDOWN
		_throw_grenade()

func _throw_grenade() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var target: Vector2
	if enemies.is_empty():
		var vp: Rect2 = get_viewport().get_visible_rect()
		target = Vector2(vp.size.x * 0.5, vp.size.y * 0.4)
	else:
		target = (enemies.pick_random() as Node2D).global_position
	_deal_grenade_damage(target)
	_show_explosion(target)

func _deal_grenade_damage(at: Vector2) -> void:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		var en: Node2D = enemy as Node2D
		if en == null:
			continue
		if en.global_position.distance_to(at) <= Constants.GRENADE_RADIUS:
			if en.has_method(&"take_damage"):
				en.call(&"take_damage", Constants.GRENADE_DAMAGE)

func _show_explosion(at: Vector2) -> void:
	var radius: float = Constants.GRENADE_RADIUS
	var ring: Line2D = Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.6, 0.0, 0.9)
	ring.closed = true
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		var angle: float = float(i) / 24.0 * TAU
		pts.append(at + Vector2(cos(angle), sin(angle)) * radius)
	ring.points = pts
	get_parent().add_child(ring)

	var inner: ColorRect = ColorRect.new()
	inner.size = Vector2(radius * 2.0, radius * 2.0)
	inner.position = at - Vector2(radius, radius)
	inner.color = Color(1.0, 0.7, 0.1, 0.55)
	get_parent().add_child(inner)

	var tween: Tween = create_tween()
	tween.tween_property(inner, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	tween.tween_callback(inner.queue_free)
	tween.tween_callback(ring.queue_free)

func _spawn_laser() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	var vp: Rect2 = get_viewport().get_visible_rect()
	var lx: float = vp.size.x * 0.5
	if not players.is_empty():
		lx = (players[0] as Node2D).global_position.x

	var laser_rect: ColorRect = ColorRect.new()
	laser_rect.size = Vector2(12.0, vp.size.y)
	laser_rect.position = Vector2(lx - 6.0, 0.0)
	laser_rect.color = Color(1.0, 0.3, 0.0, 0.75)
	get_parent().add_child(laser_rect)

	var area: Area2D = Area2D.new()
	area.position = Vector2(lx, vp.size.y * 0.5)
	area.collision_layer = 0
	area.collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rs: RectangleShape2D = RectangleShape2D.new()
	rs.size = Vector2(12.0, vp.size.y)
	shape.shape = rs
	area.add_child(shape)
	get_parent().add_child(area)

	var laser_data: Dictionary = {"rect": laser_rect, "area": area}
	_active_lasers.append(laser_data)

	var tick: Timer = Timer.new()
	tick.wait_time = Constants.LASER_TICK_INTERVAL
	tick.timeout.connect(Callable(self, "_on_laser_tick").bind(area))
	area.add_child(tick)
	tick.start()

	var dur: Timer = Timer.new()
	dur.wait_time = Constants.JALAPENO_LASER_DURATION
	dur.one_shot = true
	dur.timeout.connect(
		Callable(self, "_cleanup_laser").bind(tick, laser_rect, area, laser_data)
	)
	area.add_child(dur)
	dur.start()

func _update_laser_positions() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var px: float = (players[0] as Node2D).global_position.x
	for i: int in _active_lasers.size():
		var d: Dictionary = _active_lasers[i]
		var rect: ColorRect = d.get("rect") as ColorRect
		var area: Area2D = d.get("area") as Area2D
		if is_instance_valid(rect):
			rect.position.x = px - 6.0
		if is_instance_valid(area):
			area.position.x = px

func _on_laser_tick(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	for body: Node2D in area.get_overlapping_bodies():
		if body.is_in_group(&"enemies") and body.has_method(&"take_damage"):
			body.call(&"take_damage", Constants.LASER_DAMAGE_PER_TICK)

func _cleanup_laser(
		tick: Timer, laser_rect: ColorRect, area: Area2D, laser_data: Dictionary
) -> void:
	_active_lasers.erase(laser_data)
	tick.stop()
	if is_instance_valid(laser_rect):
		laser_rect.queue_free()
	if is_instance_valid(area):
		area.queue_free()

func get_stack_count(powerup_id: StringName) -> int:
	return int(_stacks.get(powerup_id, 0))

func _on_session_ended(_s: int, _d: float) -> void:
	var ids: Array = _stacks.keys()
	for i: int in ids.size():
		var pid: StringName = ids[i] as StringName
		if int(_stacks.get(pid, 0)) > 0:
			EventBus.powerup_stack_changed.emit(pid, 0)
	_stacks.clear()
	_timers.clear()
	_grenade_cooldown = 0.0
	for i: int in _active_lasers.size():
		var d: Dictionary = _active_lasers[i]
		var rect: ColorRect = d.get("rect") as ColorRect
		var area: Area2D = d.get("area") as Area2D
		if is_instance_valid(rect):
			rect.queue_free()
		if is_instance_valid(area):
			area.queue_free()
	_active_lasers.clear()
