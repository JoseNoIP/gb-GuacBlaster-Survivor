class_name PowerUpManager
extends Node
## Manages active power-up effects: mole_grenade, jalapeno_laser, salsa_magnet.
## Grenade fires every MOLE_GRENADE_COOLDOWN seconds once selected.
## Laser spawns a column beam for JALAPENO_LASER_DURATION seconds.

var _grenade_active: bool = false
var _grenade_cooldown: float = 0.0

func _ready() -> void:
	EventBus.powerup_selected.connect(_on_powerup_selected)
	EventBus.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	if not _grenade_active:
		return
	_grenade_cooldown -= delta
	if _grenade_cooldown <= 0.0:
		_grenade_cooldown = Constants.MOLE_GRENADE_COOLDOWN
		_throw_grenade()

func _on_powerup_selected(powerup_id: StringName) -> void:
	match powerup_id:
		&"mole_grenade":
			if not _grenade_active:
				_grenade_active = true
				_grenade_cooldown = Constants.MOLE_GRENADE_COOLDOWN
		&"jalapeno_laser":
			_spawn_laser()
		&"salsa_magnet":
			pass

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
	var d: float = Constants.GRENADE_RADIUS * 2.0
	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(d, d)
	rect.position = at - Vector2(Constants.GRENADE_RADIUS, Constants.GRENADE_RADIUS)
	rect.color = Color(1.0, 0.5, 0.0, 0.6)
	get_parent().add_child(rect)
	var tween: Tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(rect, "queue_free"))

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

	var tick: Timer = Timer.new()
	tick.wait_time = Constants.LASER_TICK_INTERVAL
	tick.timeout.connect(Callable(self, "_on_laser_tick").bind(area))
	area.add_child(tick)
	tick.start()

	var dur: Timer = Timer.new()
	dur.wait_time = Constants.JALAPENO_LASER_DURATION
	dur.one_shot = true
	dur.timeout.connect(Callable(self, "_cleanup_laser").bind(tick, laser_rect, area))
	area.add_child(dur)
	dur.start()

func _on_laser_tick(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	for body: Node2D in area.get_overlapping_bodies():
		if body.is_in_group(&"enemies") and body.has_method(&"take_damage"):
			body.call(&"take_damage", Constants.LASER_DAMAGE_PER_TICK)

func _cleanup_laser(tick: Timer, laser_rect: ColorRect, area: Area2D) -> void:
	tick.stop()
	laser_rect.queue_free()
	area.queue_free()

func _on_game_over(_score: int, _duration: float) -> void:
	_grenade_active = false
