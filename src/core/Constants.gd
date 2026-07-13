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
const ENEMY_BASIC_HP: int = 10
const ENEMY_BASIC_SPEED: float = 80.0
const ENEMY_BASIC_XP: int = 8

const ENEMY_TANK_HP: int = 80
const ENEMY_TANK_SPEED: float = 50.0
const ENEMY_TANK_XP: int = 35
const ENEMY_TANK_SPLIT_COUNT: int = 4

const ENEMY_ZIGZAG_HP: int = 50
const ENEMY_ZIGZAG_SPEED: float = 130.0
const ENEMY_ZIGZAG_XP: int = 15
const ENEMY_ZIGZAG_AMPLITUDE: float = 100.0
const ENEMY_ZIGZAG_FREQUENCY: float = 1.5

const ENEMY_ELITE_HP_MULTIPLIER: int = 20
const ENEMY_ELITE_XP_MULTIPLIER: int = 5
const SPAWNER_ELITE_UNLOCK_TIME: float = 45.0
const SPAWNER_ELITE_CHANCE: float = 0.08

const BOSS_SPAWN_INTERVAL: float = 180.0
const BACKGROUND_PALETTE: Array = [
	Color(0.18, 0.55, 0.08),  # pradera terrestre (mundo 1 — amigable)
	Color(0.02, 0.18, 0.03),  # jungla nocturna (mundo 2)
	Color(0.05, 0.02, 0.28),  # crepúsculo índigo (mundo 3)
	Color(0.26, 0.04, 0.01),  # volcánico / brasa (mundo 4)
	Color(0.01, 0.07, 0.26),  # abismo oceánico (mundo 5)
	Color(0.22, 0.02, 0.08),  # luna sangre / desierto final (mundo 6)
]
const BOSS_TIMER_SHOW_REMAINING: float = 90.0
const BOSS_HP_BASE: int = 400
const BOSS_HP_PER_GENERATION: int = 80
const BOSS_SPEED: float = 60.0
const BOSS_XP: int = 100
const BOSS_FIRE_INTERVAL: float = 2.0
const BOSS_FIRE_INTERVAL_DECREASE: float = 0.2
const BOSS_FIRE_INTERVAL_MIN: float = 0.8
const BOSS_PROJECTILE_SPEED: float = 120.0
const BOSS_PROJECTILE_DAMAGE: int = 1
const BOSS_PHASE2_THRESHOLD: float = 0.5
const BOSS_PHASE2_SPEED_MULT: float = 1.8
const BOSS_PHASE2_FIRE_MULT: float = 0.5
const BOSS_PHASE2_SPREAD_COUNT: int = 3
const BOSS_PHASE2_SPREAD_ANGLE: float = 20.0

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
const POWERUP_DURATION: float = 45.0
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

# --- Heart Drops ---
const HEART_DROP_INTERVAL: float = 45.0
const HEART_DROP_SPEED: float = 80.0

# --- XP ---
const XP_BASE_REQUIRED: int = 80
const XP_SCALE_FACTOR: float = 1.2

# --- Combat ---
const PLAYER_CONTACT_INVINCIBILITY: float = 1.0
const GRENADE_RADIUS: float = 80.0
const GRENADE_DAMAGE: int = 30
const LASER_DAMAGE_PER_TICK: int = 5
const LASER_TICK_INTERVAL: float = 0.3

# --- Characters ---
const CHARACTERS: Array = [
	{
		"id": &"guac",
		"name": "Guacamole",
		"desc": "Equilibrado. Estadísticas base.",
		"hp_bonus": 0,
		"fire_rate_mult": 1.0,
		"damage_mult": 1.0,
		"cost": 0,
	},
	{
		"id": &"habanero",
		"name": "Habanero",
		"desc": "Disparo +25% más rápido. -1 corazón.",
		"hp_bonus": -1,
		"fire_rate_mult": 1.25,
		"damage_mult": 1.0,
		"cost": 200,
	},
	{
		"id": &"serrano",
		"name": "Serrano",
		"desc": "Daño +15%. +1 corazón. Disparo -20%.",
		"hp_bonus": 1,
		"fire_rate_mult": 0.8,
		"damage_mult": 1.15,
		"cost": 300,
	},
]

# --- Achievements ---
const ACHIEVEMENTS: Array = [
	{"id": &"first_victory",  "name": "Primera Victoria",   "desc": "Gana tu primera partida"},
	{"id": &"five_victories", "name": "Campeón",            "desc": "Gana 5 partidas"},
	{"id": &"boss_slayer",    "name": "Cazajefes",          "desc": "Derrota a un jefe"},
	{"id": &"level_10",       "name": "Experto",            "desc": "Alcanza nivel 10 en una partida"},
	{"id": &"gold_500",       "name": "Rico Rico",          "desc": "Acumula 500 oro disponible"},
	{"id": &"power_hoarder",  "name": "Coleccionista",      "desc": "Recoge 50 power-ups en total"},
	{"id": &"veteran",        "name": "Veterano",           "desc": "Completa 25 sesiones"},
	{"id": &"massacre",      "name": "Masacre",        "desc": "Elimina 100 enemigos en partida"},
	{"id": &"survivor_90",  "name": "Superviviente",  "desc": "Sobrevive 90 segundos"},
	{"id": &"max_upgrade",  "name": "Perfeccionista", "desc": "Maximiza cualquier mejora"},
]

# --- Daily Missions ---
const DAILY_MISSION_POOL: Array = [
	{"id": &"kill_20",     "desc": "Elimina 20 enemigos",          "target": 20,  "reward": 30},
	{"id": &"kill_50",     "desc": "Elimina 50 enemigos",          "target": 50,  "reward": 60},
	{"id": &"powerups_5",  "desc": "Recoge 5 power-ups",           "target": 5,   "reward": 40},
	{"id": &"powerups_10", "desc": "Recoge 10 power-ups",          "target": 10,  "reward": 80},
	{"id": &"win_game",    "desc": "Gana una partida",             "target": 1,   "reward": 100},
	{"id": &"play_3",      "desc": "Juega 3 partidas",             "target": 3,   "reward": 50},
	{"id": &"boss_kill",   "desc": "Derrota al jefe",              "target": 1,   "reward": 120},
	{"id": &"level_5",     "desc": "Alcanza nivel 5 en partida",   "target": 5,   "reward": 35},
	{"id": &"kill_100",    "desc": "Elimina 100 enemigos en total","target": 100, "reward": 75},
]
const DAILY_MISSIONS_COUNT: int = 3

# --- Weekly Challenge ---
const WEEKLY_CHALLENGE_POOL: Array = [
	{
		"id": &"horda_masiva",
		"name": "Horda Masiva",
		"desc": "Los enemigos aparecen 40% más rápido. Sin corazones caídos.",
		"spawn_rate_mult": 0.6,
		"elite_chance_mult": 1.0,
		"boss_hp_mult": 1.0,
		"gold_mult": 2.0,
		"no_heart_drops": true,
	},
	{
		"id": &"lluvia_elite",
		"name": "Lluvia Élite",
		"desc": "Élites ×4 de frecuencia. El jefe tiene +50% HP.",
		"spawn_rate_mult": 1.0,
		"elite_chance_mult": 4.0,
		"boss_hp_mult": 1.5,
		"gold_mult": 2.5,
		"no_heart_drops": false,
	},
	{
		"id": &"supervivencia_pura",
		"name": "Supervivencia Pura",
		"desc": "Sin corazones caídos. Spawn 25% más rápido.",
		"spawn_rate_mult": 0.75,
		"elite_chance_mult": 1.0,
		"boss_hp_mult": 1.0,
		"gold_mult": 1.5,
		"no_heart_drops": true,
	},
]
