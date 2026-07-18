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
const ELITE_CHARGE_DURATION: float = 1.5
const SPAWNER_ELITE_UNLOCK_TIME: float = 45.0
const SPAWNER_ELITE_CHANCE: float = 0.08

const BOSS_SPAWN_INTERVAL: float = 180.0
const BOSS_Y_RATIO: float = 0.33  # boss Y position: 33% from top (near VP, still visible)

# --- Character fire-mode geometry ---
const CHAR_DOUBLE_OFFSET: float = 18.0
const CHAR_FAN3_ANGLE: float = 25.0
const CHAR_FAN5_ANGLE: float = 20.0

# --- Biome Modifiers (6 biomes, index matches BACKGROUND_PALETTE) ---
# spawn_mult < 1.0 = faster spawns; speed_mult > 1.0 = enemies faster
const BIOME_SPAWN_MULT: Array = [1.0, 0.85, 1.0, 1.2, 0.75, 1.3]
const BIOME_ELITE_MULT: Array = [1.0, 1.0, 2.5, 1.0, 1.5, 3.0]
const BIOME_BOSS_HP_MULT: Array = [1.0, 1.0, 1.0, 1.5, 1.0, 2.0]
const BIOME_SPEED_MULT: Array = [1.0, 1.2, 1.0, 1.0, 1.3, 1.5]
const BIOME_GOLD_MULT: Array = [1.0, 1.0, 1.5, 1.0, 2.0, 2.5]

const BACKGROUND_PALETTE: Array = [
	Color(0.18, 0.55, 0.08),  # pradera terrestre (mundo 1 — amigable)
	Color(0.02, 0.18, 0.03),  # jungla nocturna (mundo 2)
	Color(0.05, 0.02, 0.28),  # crepúsculo índigo (mundo 3)
	Color(0.26, 0.04, 0.01),  # volcánico / brasa (mundo 4)
	Color(0.01, 0.07, 0.26),  # abismo oceánico (mundo 5)
	Color(0.22, 0.02, 0.08),  # luna sangre / desierto final (mundo 6)
]
const BOSS_TIMER_SHOW_REMAINING: float = 90.0
const BOSS_HP_BASE: int = 300
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

# --- Enemy HP time scaling ---
const ENEMY_HP_SCALE_PER_MIN: float = 0.25

# --- Spawner ---
const SPAWNER_INITIAL_INTERVAL: float = 0.8
const SPAWNER_MIN_INTERVAL: float = 0.2
const SPAWNER_INTERVAL_DECREASE_PER_MIN: float = 0.1
const SPAWNER_WAVE_RAMP_INTERVAL: float = 90.0
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
const POWERUP_MAX_STACKS: int = 3
const POWERUP_DURATION: float = 45.0
const RAPID_FIRE_MULTIPLIER: float = 2.0
const RAPID_FIRE_LINEAR_FACTOR: float = 0.9
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
const META_UPGRADE_COST_BASE: int = 200
const META_UPGRADE_COST_GROWTH: float = 2.0
const GOLD_PER_SCORE_POINT: float = 0.1
const GOLD_PER_HEART_KEPT: int = 25
const PLAYER_SWIPE_SENSITIVITY: float = 1.0
const GEM_FALL_SPEED: float = 90.0
const GEM_MAGNET_SPEED: float = 300.0

# --- Heart Drops ---
const HEART_DROP_INTERVAL: float = 45.0
const HEART_DROP_SPEED: float = 80.0

# --- XP ---
const XP_BASE_REQUIRED: int = 150
const XP_SCALE_FACTOR: float = 1.25

# --- Combat ---
const PLAYER_CONTACT_INVINCIBILITY: float = 1.0
const GRENADE_RADIUS: float = 80.0

# --- Perspective / Depth illusion ---
const PERSPECTIVE_VP_Y_RATIO: float = 0.25       # vanishing point at 25% from top
const PERSPECTIVE_FULL_SIZE_Y_RATIO: float = 0.45 # enemies reach full size by 45% from top
const PERSPECTIVE_SCALE_MIN: float = 0.35         # enemy size at vanishing point
const PERSPECTIVE_SCALE_MAX: float = 1.0          # enemy size at full-size threshold
const GRENADE_DAMAGE: int = 30
const LASER_DAMAGE_PER_TICK: int = 5
const LASER_TICK_INTERVAL: float = 0.3

# --- Characters ---
# Fields: id, name, desc, hp_bonus, fire_rate_mult, damage_mult, cost,
#         fire_mode (&"normal"|&"double"|&"fan3"|&"fan5"|&"heavy"),
#         sprite_tint, bullet_tint, bullet_scale
const CHARACTERS: Array = [
	{
		"id": &"guac",
		"name": "Guacamole",
		"desc": "Equilibrado. Estadísticas base.",
		"hp_bonus": 0, "fire_rate_mult": 1.0, "damage_mult": 1.0, "cost": 0,
		"fire_mode": &"normal",
		"sprite_tint": Color(1.0, 1.0, 1.0),
		"bullet_tint": Color(0.55, 1.0, 0.25),
		"bullet_scale": 1.0,
	},
	{
		"id": &"habanero",
		"name": "Habanero",
		"desc": "Cadencia +25%. -1 corazón.",
		"hp_bonus": -1, "fire_rate_mult": 1.25, "damage_mult": 1.0, "cost": 600,
		"fire_mode": &"normal",
		"sprite_tint": Color(1.0, 0.55, 0.15),
		"bullet_tint": Color(1.0, 0.5, 0.1),
		"bullet_scale": 1.0,
	},
	{
		"id": &"serrano",
		"name": "Serrano",
		"desc": "Daño +15%. +1 corazón. Cadencia -20%.",
		"hp_bonus": 1, "fire_rate_mult": 0.8, "damage_mult": 1.15, "cost": 900,
		"fire_mode": &"normal",
		"sprite_tint": Color(0.65, 1.0, 0.15),
		"bullet_tint": Color(0.65, 1.0, 0.2),
		"bullet_scale": 1.1,
	},
	{
		"id": &"doble_guac",
		"name": "Doble Guac",
		"desc": "2 balas simultáneas en paralelo.",
		"hp_bonus": 0, "fire_rate_mult": 1.0, "damage_mult": 1.0, "cost": 1350,
		"fire_mode": &"double",
		"sprite_tint": Color(0.2, 0.85, 1.0),
		"bullet_tint": Color(0.25, 0.9, 1.0),
		"bullet_scale": 1.0,
	},
	{
		"id": &"veloz",
		"name": "Jalapeño Veloz",
		"desc": "Cadencia ×1.7. Daño -25%. Balas pequeñas.",
		"hp_bonus": 0, "fire_rate_mult": 1.7, "damage_mult": 0.75, "cost": 1800,
		"fire_mode": &"normal",
		"sprite_tint": Color(1.0, 1.0, 0.15),
		"bullet_tint": Color(1.0, 1.0, 0.2),
		"bullet_scale": 0.75,
	},
	{
		"id": &"tornado",
		"name": "Tornado Verde",
		"desc": "3 balas en abanico (±25°). Cadencia -25%.",
		"hp_bonus": 0, "fire_rate_mult": 0.75, "damage_mult": 1.0, "cost": 2250,
		"fire_mode": &"fan3",
		"sprite_tint": Color(0.55, 0.25, 1.0),
		"bullet_tint": Color(0.6, 0.35, 1.0),
		"bullet_scale": 1.0,
	},
	{
		"id": &"aplastador",
		"name": "Mole Aplastador",
		"desc": "Daño ×2, balas grandes. +1 corazón. Cadencia -40%.",
		"hp_bonus": 1, "fire_rate_mult": 0.6, "damage_mult": 2.0, "cost": 3000,
		"fire_mode": &"heavy",
		"sprite_tint": Color(0.65, 0.3, 0.08),
		"bullet_tint": Color(0.75, 0.25, 0.05),
		"bullet_scale": 1.7,
	},
	{
		"id": &"gran_abanico",
		"name": "Gran Abanico",
		"desc": "5 balas en abanico (±40°). Cadencia -50%.",
		"hp_bonus": 0, "fire_rate_mult": 0.5, "damage_mult": 1.0, "cost": 4200,
		"fire_mode": &"fan5",
		"sprite_tint": Color(1.0, 0.2, 0.65),
		"bullet_tint": Color(1.0, 0.3, 0.7),
		"bullet_scale": 1.0,
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
