class_name ParticleSpawner
extends Node2D
## Spawns one-shot CPUParticles2D bursts on enemy death and on projectile hits.

func _ready() -> void:
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.enemy_hit.connect(_on_enemy_hit)

func _on_enemy_destroyed(
		_enemy_id: int, spawn_pos: Vector2, _xp_value: int) -> void:
	_spawn_death_burst(spawn_pos)

func _on_enemy_hit(hit_pos: Vector2) -> void:
	_spawn_hit_burst(hit_pos)

func _spawn_hit_burst(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 5
	p.lifetime = 0.2
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 120.0
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 0.4))
	grad.set_color(1, Color(1.0, 0.6, 0.1, 0.0))
	p.color_ramp = grad
	p.direction = Vector2(0.0, -1.0)
	p.position = pos
	p.finished.connect(func(): p.queue_free())
	get_parent().call_deferred(&"add_child", p)

func _spawn_death_burst(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12
	p.lifetime = 0.5
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 100.0
	p.spread = 180.0
	p.gravity = Vector2(0.0, 50.0)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 5.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.5, 0.1))
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	p.color_ramp = grad
	p.position = pos
	p.finished.connect(func(): p.queue_free())
	get_parent().call_deferred(&"add_child", p)
