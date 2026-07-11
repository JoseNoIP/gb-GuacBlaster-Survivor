extends Node
## Global signal bus. All cross-feature communication goes through here.
## Features never reference each other directly — they emit and listen here.

# --- Player ---
signal player_health_changed(current: int, maximum: int)
signal player_died()
signal player_level_up(new_level: int)

# --- Enemies ---
signal enemy_destroyed(enemy_id: int, position: Vector2, xp_value: int)
signal enemy_split_requested(spawn_position: Vector2, count: int)
signal boss_spawned(boss_id: int)
signal boss_defeated(boss_id: int)

# --- Projectiles ---
signal player_fired(spawn_position: Vector2, direction: Vector2, damage: float)
signal projectile_hit_enemy(enemy_id: int, damage: float)

# --- Experience / Level ---
signal xp_collected(amount: int, total: int, required: int)

# --- Power-ups ---
signal powerup_selection_requested(options: Array)
signal powerup_selected(powerup_id: StringName)

# --- Game State ---
signal game_started()
signal game_paused(is_paused: bool)
signal game_over(score: int, duration: float)
signal wave_started(wave_number: int)

# --- Meta ---
signal gold_earned(amount: int)
signal upgrade_purchased(upgrade_id: StringName, new_level: int)
