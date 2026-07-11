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
const ENEMY_TANK_SPLIT_COUNT: int = 4
const BOSS_SPAWN_INTERVAL: float = 180.0

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
]
const POWERUP_CARDS_PER_LEVEL: int = 3
const RAPID_FIRE_MULTIPLIER: float = 1.25
const MOLE_GRENADE_COOLDOWN: float = 5.0
const JALAPENO_LASER_DURATION: float = 2.0
const NACHO_WALL_HITS: int = 3
const SUPER_GUAC_PENETRATION: int = 3

# --- Meta Upgrades ---
const META_DAMAGE_PER_LEVEL: float = 0.05
const META_SPEED_PER_LEVEL: float = 0.03
const META_HEALTH_PER_LEVEL: int = 1

# --- Sessions ---
const SESSION_TARGET_MIN: float = 120.0
const SESSION_TARGET_MAX: float = 300.0

# --- XP ---
const XP_BASE_REQUIRED: int = 100
const XP_SCALE_FACTOR: float = 1.5
