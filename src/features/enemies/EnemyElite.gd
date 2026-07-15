class_name EnemyElite
extends "res://src/features/enemies/EnemyBasic.gd"
## Elite variant of the basic enemy. 3× HP, 5× XP, drops a random power-up on death.
## On player contact: flashes red for ELITE_CHARGE_DURATION, then deals 2 damage and explodes.
## Visually distinguished by a gold modulate applied in _ready().

var _charging: bool = false

func _initialize() -> void:
	_health = Constants.ENEMY_BASIC_HP * Constants.ENEMY_ELITE_HP_MULTIPLIER
	_xp_value = Constants.ENEMY_BASIC_XP * Constants.ENEMY_ELITE_XP_MULTIPLIER

func _ready() -> void:
	super._ready()
	modulate = Color(1.0, 0.85, 0.15)

func _die() -> void:
	var idx: int = randi() % Constants.POWERUP_POOL.size()
	EventBus.elite_powerup_dropped.emit(global_position, Constants.POWERUP_POOL[idx] as StringName)
	super._die()

func on_player_contact(player: Node2D) -> void:
	if _charging:
		return
	_charging = true
	_start_charge(player)

func _start_charge(player: Node2D) -> void:
	var step: float = Constants.ELITE_CHARGE_DURATION / 10.0
	var tween := create_tween()
	for _i: int in 5:
		tween.tween_property(self, "modulate", Color(1.5, 0.1, 0.1), step)
		tween.tween_property(self, "modulate", Color(1.0, 0.85, 0.15), step)
	tween.tween_callback(_explode_on_player.bind(player))

func _explode_on_player(player: Node2D) -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(player) and player.has_method(&"take_damage"):
		player.call(&"take_damage", 2)
	_contact_die()
