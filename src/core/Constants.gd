extends Node
## Typed game constants. All magic numbers live here.
## Autoloaded first so all other scripts resolve Constants.VALUE at parse time.
## Never hardcode values in feature scripts.

# --- Player ---
const PLAYER_BASE_HEALTH: int = 3
const PLAYER_BASE_SPEED: float = 200.0
const PLAYER_BASE_DAMAGE: float = 10.0
const PLAYER_AUTOFIRE_INTERVAL: float = 0.4

# --- Enemies ---
const ENEMY_BASIC_HP: int = 1
const ENEMY_BASIC_SPEED: float = 80.0
const ENEMY_BASIC_XP: int = 5

const ENEMY_TANK_HP: int = 5
const ENEMY_TANK_SPEED: float = 50.0
const ENEMY_TANK_XP: int = 20
const ENEMY_TANK_SPLIT_COUNT: int = 4

const ENEMY_ZIGZAG_HP: int = 1
const ENEMY_ZIGZAG_SPEED: float = 130.0
const ENEMY_ZIGZAG_XP: int = 10
const ENEMY_ZIGZAG_AMPLITUDE: float = 100.0
const ENEMY_ZIGZAG_FREQUENCY: float = 1.5

const BOSS_SPAWN_INTERVAL: float = 180.0
const BACKGROUND_PALETTE: Array = [
	Color(0.08, 0.10, 0.08),  # jungla oscura (default)
	Color(0.08, 0.06, 0.13),  # crepúsculo / índigo
	Color(0.13, 0.06, 0.04),  # volcánico / brasa
	Color(0.04, 0.08, 0.13),  # abismo / océano profundo
	Color(0.10, 0.04, 0.07),  # luna sangre / desierto nocturno
]
const BOSS_TIMER_SHOW_REMAINING: float = 90.0
const BOSS_HP_BASE: int = 100
const BOSS_HP_PER_GENERATION: int = 50
const BOSS_SPEED: float = 60.0
const BOSS_XP: int = 100
const BOSS_FIRE_INTERVAL: float = 2.0
const BOSS_FIRE_INTERVAL_DECREASE: float = 0.2
const BOSS_FIRE_INTERVAL_MIN: float = 0.8
const BOSS_PROJECTILE_SPEED: float = 120.0
const BOSS_PROJECTILE_DAMAGE: int = 1

# --- Spawner ---
const SPAWNER_INITIAL_INTERVAL: float = 0.8
const SPAWNER_MIN_INTERVAL: float = 0.2
const SPAWNER_INTERVAL_DECREASE_PER_MIN: float = 0.1
const SPAWNER_TANK_UNLOCK_TIME: float = 60.0
const SPAWNER_ZIGZAG_UNLOCK_TIME: float = 30.0
const SPAWNER_TANK_CHANCE: float = 0.15
const SPAWNER_ZIGZAG_CHANCE: float = 0.25

# --- Power-ups ---
const POWERUP_POOL: Array = [
	&"triple_shot",
	&"super_guac",
	&"rapid_fire",
	&"mole_grenade",
	&"jalapeno_laser",
	&"spicy_bounce",
	&"nacho_wall",
	&"salsa_magnet",
	&"guac_storm",
]
const POWERUP_CARDS_PER_LEVEL: int = 3
const POWERUP_DURATION: float = 30.0
const RAPID_FIRE_MULTIPLIER: float = 2.0
const PLAYER_AUTOFIRE_MIN: float = 0.05
const MOLE_GRENADE_COOLDOWN: float = 5.0
const JALAPENO_LASER_DURATION: float = 2.0
const NACHO_WALL_HITS: int = 3
const SUPER_GUAC_PENETRATION: int = 3
const MULTI_STREAM_SPACING: float = 40.0

# --- Meta Upgrades ---
const META_DAMAGE_PER_LEVEL: float = 0.05
const META_SPEED_PER_LEVEL: float = 0.03
const META_HEALTH_PER_LEVEL: int = 1
const META_LUCK_PER_LEVEL: float = 0.05
const META_GOLD_BONUS_PER_LEVEL: float = 0.15
const META_STARTER_SHIELD_PER_LEVEL: int = 1
const META_MAX_UPGRADE_LEVEL: int = 5
const META_UPGRADE_COST_BASE: int = 50
const META_UPGRADE_COST_GROWTH: float = 1.8
const GOLD_PER_SCORE_POINT: float = 0.1
const GOLD_PER_HEART_KEPT: int = 25
const PLAYER_SWIPE_SENSITIVITY: float = 1.0
const GEM_FALL_SPEED: float = 90.0
const GEM_MAGNET_SPEED: float = 300.0

# --- XP ---
const XP_BASE_REQUIRED: int = 60
const XP_SCALE_FACTOR: float = 1.3

# --- Combat ---
const PLAYER_CONTACT_INVINCIBILITY: float = 1.0
const GRENADE_RADIUS: float = 80.0
const GRENADE_DAMAGE: int = 30
const LASER_DAMAGE_PER_TICK: int = 5
const LASER_TICK_INTERVAL: float = 0.3
