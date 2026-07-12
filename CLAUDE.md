# CLAUDE.md — GuacBlaster Survivor

Guía autoritativa de desarrollo para Claude Code. **Lee este archivo completo antes de cualquier tarea.**

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Motor | Godot 4.7 (GDScript con tipado estático) |
| Testing | GUT (Godot Unit Testing) v9.7.1 — 185 tests |
| Lint/Format | gdtoolkit (`gdlint` / `gdformat`) vía pipx |
| Plataforma | iOS 14+ / Android API 24+ |
| CI/CD | GitHub Actions → APK en Dropbox (`/prod/` o `/stg/`) |
| Arte | Pixel art / Vector toony |
| Control | Touch drag relativo (1 dedo) |

---

## Comandos Esenciales

```bash
# Instalar herramientas de linting (una sola vez, requiere brew)
brew install pipx && pipx install gdtoolkit

# Lint — debe pasar a 0 errores antes de cualquier commit
gdlint src/

# Format check (sin modificar)
gdformat --check src/

# Format apply
gdformat src/

# Tests (requiere Godot instalado y GUT en addons/)
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gexit -glog=2

# Export Debug — Android
godot --headless --export-debug "Android" builds/debug/GuacBlaster.apk

# Export Debug — iOS
godot --headless --export-debug "iOS" builds/debug/GuacBlaster.xcodeproj

# Export Release — Android
godot --headless --export-release "Android" builds/release/GuacBlaster.apk
```

---

## Estructura de Carpetas (Feature-First)

```
src/
├── core/                   # Singletons / Autoloads globales
│   ├── Constants.gd        # Constantes tipadas (cargado PRIMERO)
│   ├── EventBus.gd         # Bus de señales (TODA comunicación cross-feature)
│   ├── GameManager.gd      # Máquina de estados de partida
│   └── SaveManager.gd      # Persistencia JSON (user://)
├── features/
│   ├── player/             # Input, movimiento, vida del jugador
│   ├── projectiles/        # Proyectiles y sus variantes
│   ├── enemies/            # EnemyBase + cada subtipo + Spawner
│   ├── powerups/           # PowerUpManager, PowerUpDrop, PowerUpDropper
│   ├── gems/               # XPGem, GemSpawner
│   ├── meta/               # ProgressionManager, árbol de mejoras
│   ├── audio/              # AudioManager + HapticManager
│   ├── vfx/                # ParticleSpawner
│   └── ui/                 # HUD, pantallas, menús
├── scenes/                 # Escenas raíz (.tscn)
└── shared/                 # Recursos compartidos (.tres, temas UI)
assets/
├── sprites/
├── audio/
└── fonts/
tests/
└── unit/                   # Tests GUT por feature (test_*.gd)
addons/
└── gut/                    # GUT framework (no modificar)
builds/
├── debug/
└── release/
```

---

## Estándares de Código GDScript

### Nomenclatura
| Elemento | Convención | Ejemplo |
|---|---|---|
| Clases | PascalCase, **antes de extends** | `class_name EnemyTank` |
| Variables / funciones | snake_case | `var max_health: int` |
| Constantes | SCREAMING_SNAKE_CASE | `const BASE_DAMAGE: float = 10.0` |
| Señales | snake_case (pasado) | `signal enemy_destroyed(id: int)` |
| Archivos | snake_case | `enemy_tank.gd`, `enemy_tank.tscn` |
| Parámetros privados | prefijo `_` | `var _state: GameState` |

### Tipado estático obligatorio
```gdscript
# CORRECTO
var speed: float = 200.0
func take_damage(amount: int) -> void:
    pass

# PROHIBIDO — causa errores en producción y falla gdlint
var speed = 200.0
func take_damage(amount):
    pass
```

### Principios SOLID aplicados
- **S** — Un `.gd` = una responsabilidad. `Player.gd` no toca lógica de cámara ni audio.
- **O** — Extender enemigos vía herencia: `EnemyBase → EnemyTank`, nunca modificar la base.
- **L** — Subclases sustituyen al padre sin romper el sistema de spawning.
- **I** — Usar señales específicas, no callbacks monolíticos.
- **D** — Features se comunican vía `EventBus`, nunca con `get_parent()` o rutas hardcodeadas.

### Event-Driven Architecture (regla absoluta)
**TODA comunicación entre features NO relacionadas va por `EventBus.gd`.**  
Los nodos hermanos nunca se llaman directamente.

```gdscript
# Emitir (desde cualquier nodo)
EventBus.enemy_destroyed.emit(enemy_id, position, gem_value)

# Suscribir (en _ready, siempre tipado)
EventBus.enemy_destroyed.connect(_on_enemy_destroyed)

# Desuscribir al salir del árbol (nodos dinámicos)
func _exit_tree() -> void:
    EventBus.enemy_destroyed.disconnect(_on_enemy_destroyed)
```

---

## Reglas Anti-Alucinación (CRÍTICO — NO NEGOCIABLE)

1. **PROHIBIDO** inventar nombres de métodos de la API de Godot. Si hay duda → verificar en `docs.godotengine.org` con WebSearch antes de escribir.
2. **PROHIBIDO** agregar addons o plugins no presentes en `addons/`. Verificar con `ls addons/` antes de importar.
3. **PROHIBIDO** usar `get_node()` con rutas largas hardcodeadas. Usar `@onready var` o señales.
4. **PROHIBIDO** crear archivos `.tscn` referenciando scripts que no existen aún.
5. **SIEMPRE** leer un archivo con `Read` tool antes de editarlo. Nunca asumir el contenido.
6. **SIEMPRE** verificar existencia de archivos con `ls` o `find` antes de importarlos o referenciarlos.
7. Si una función de Godot parece existir pero no hay certeza → declarar la duda, no inventar.
8. Los valores del GDD son la única fuente de verdad para mecánicas. No inventar comportamientos.
9. **`const ARRAY: Array[T]`** — arrays tipados inválidos como `const` en GDScript 4. Usar `const POOL: Array = [...]`.
10. **`class_name X` + autoload `X`** → conflicto fatal en Godot 4.7. Los singletons de constantes deben ser autoload `*` SIN `class_name`.
11. **Autoload de constantes PRIMERO** en `[autoload]` de project.godot — los autoloads se registran en orden.
12. **`change_scene_to_file()` en `_ready()`** → usar `.call_deferred()` siempre.
13. **Herencia por class_name** → si `B extends A` y `A` no es autoload, usar `extends "res://ruta/A.gd"` (path-based) para forzar la carga. `extends NombreDeClase` falla en headless si A no estaba cargado previamente.
14. **Preload-consts** → deben ser PascalCase (`const EnemyBasicGd := preload(...)`) — gdlint regla `load-constant-name`.
15. **`class_name` como tipo en otro script** → falla en parse si la clase no estaba previamente cargada. Usar la clase base (`Area2D`, `Node2D`, etc.) como tipo y `set(&"prop", val)` para asignar propiedades. Ver `PowerUpDropper.gd`.
16. **`for id: Variant in dict.keys()`** → tipo `Variant` no válido en for-loop en GDScript 4. Usar índice entero: `for i: int in arr.size()` + `arr[i]`, o dejar sin tipo.
17. **`add_child()` desde callback de física** → usar `call_deferred(&"add_child", node)` siempre que la llamada se origine en `_on_body_entered`, `_on_area_entered` o similares.

---

## Roles Internos por Iteración

### 🏗️ Architect Agent
**Cuándo activa:** Diseño de features, refactoring, nuevas escenas.  
**Checklist:**
- [ ] ¿Usa EventBus o acoplamiento directo?
- [ ] ¿El nodo tiene UNA responsabilidad?
- [ ] ¿Puede testearse de forma aislada (sin depender de escena completa)?
- [ ] ¿El grafo de dependencias es un DAG (sin ciclos)?
- [ ] ¿Las constantes están en `Constants.gd`, no hardcodeadas?

### 🛡️ QA & Security Agent
**Cuándo activa:** Toda implementación antes de marcarla "done".  
**Checklist:**
- [ ] ¿Inputs de usuario están acotados? (`clamp()` en posición del jugador)
- [ ] ¿Hay fugas de señales? (nodos dinámicos desuscriben en `_exit_tree`)
- [ ] ¿Los tests cubren: caso normal, borde mínimo, borde máximo, entrada inválida?
- [ ] `gdlint src/` pasa a 0 errores
- [ ] El build headless compila sin warnings

### 🎮 Game Designer / Polish Agent
**Cuándo activa:** Features de gameplay, power-ups, enemigos, feedback.  
**Checklist:**
- [ ] ¿Los valores vienen de `Constants.gd`?
- [ ] ¿El comportamiento respeta exactamente el GDD §3 (power-ups) y §4 (enemigos)?
- [ ] ¿Hay feedback visual (partículas/tween) Y auditivo (SFX) en cada interacción?
- [ ] ¿El feedback háptico está implementado para disparo y eventos críticos?
- [ ] ¿La sesión puede completarse en 2–5 minutos?

---

## Protocolo Obligatorio por Cambio

Cada feature o fix sigue EXACTAMENTE este flujo:

```
a) PLAN      — Listar: qué archivos se modifican, qué tests se agregan
b) IMPL      — Código mínimo y tipado (sin over-engineering)
c) VALIDATE  — Ejecutar: gdlint src/ && tests GUT headless → BUILD GREEN
d) SANITY    — Verificar que features existentes no se rompieron
e) DOC       — Actualizar idea-base.md, CLAUDE.md y memoria (project_guacblaster.md)
```

**Una tarea NO está terminada hasta que los pasos (c) y (e) estén completos.**  
**El paso (e) es OBLIGATORIO y debe ejecutarse SIN que el usuario lo pida.**

---

## Estado Actual del Juego

### Mecánicas implementadas
- **Victoria:** matar al jefe (NO timer). Timer en HUD aparece solo en los últimos 90s.
- **Derrota:** jugador pierde todos los corazones.
- **Controles:** drag con ancla — `InputEventScreenTouch` registra `_drag_anchor_x` y `_drag_anchor_player_x`; `InputEventScreenDrag` aplica `_target_x = anchor_player + (finger_x - anchor_x) × sensitivity`. El jugador NO salta al primer toque.
- **Level-up:** el juego NO se pausa. Caen 3 power-up drops; al tocar uno, los otros desaparecen.
- **Power-ups:** temporales (**30s**), stackables, con timers independientes por stack.
- **Oro:** `score × 0.1 × gold_mult + hearts_left × 25` al ganar.
- **Paleta de fondo:** rota por victorias (`victories % 5`), no por sesiones totales.

### Señales clave en EventBus
| Señal | Emisor | Receptores principales |
|---|---|---|
| `powerup_selected(id)` | PowerUpDrop | PowerUpManager, PowerUpDropper |
| `powerup_stack_changed(id, count)` | PowerUpManager | Player, ProjectileSpawner, XPGem, HUD |
| `powerup_expired(id)` | PowerUpManager | (informativa) |
| `player_shield_changed(hits)` | Player | HUD |
| `powerup_selection_requested(opts)` | GameManager | PowerUpDropper |
| `boss_health_changed(current, maximum)` | EnemyBoss | HUD |
| `heart_collected` | HeartDrop | Player |

---

## Referencia Rápida del GDD

### Valores base del jugador
| Stat | Valor base | Upgrade meta |
|---|---|---|
| HP | 3 corazones | +1 corazón/nivel |
| Velocidad | 200 px/s | +3%/nivel |
| Daño base | 10 | +5%/nivel |
| Autofire interval | 0.4s | ÷2 por stack de Fuego Rápido (mín 0.05s) |
| Sensibilidad swipe | 1.0 (base) | Configurable en Settings (100%–200%). Guardado en SaveManager. |

### Enemigos
| Tipo | HP | Comportamiento especial |
|---|---|---|
| Burbuja Básica | 1 | Línea recta descendente |
| Burbuja Tanque | 5 | Split en 4 básicas al morir |
| Mosca Nacho | 1 | Zigzag diagonal, rápida |
| Jefe | 100+50×gen | Dispara proyectiles, aparece cada 3 min |

### Power-ups (IDs en Constants.POWERUP_POOL) — todos temporales **30s**, stackables
**guac_storm**: streams distribuidos simétricamente. 1 stack=X2 (±20px), 2=X3 (-40/0/+40), …, 5=X6. Triple Shot aplica a todos los streams.


| ID | Abrev | Nombre | Efecto por stack |
|---|---|---|---|
| `triple_shot` | TS | Disparo Triple | +2 disparos diagonales |
| `super_guac` | SG | Súper-Guac | Proyectiles penetran 3 enemigos |
| `rapid_fire` | RF | Fuego Rápido | Cadencia ×2 (apilable) |
| `mole_grenade` | MG | Granada de Mole | AoE cada 5s automático |
| `jalapeno_laser` | JL | Láser Jalapeño | Rayo 2s que sigue al jugador |
| `spicy_bounce` | SB | Rebote Picante | Proyectiles rebotan en bordes |
| `nacho_wall` | NW | Muro de Nachos | Escudo: absorbe 3 impactos |
| `salsa_magnet` | SM | Imán de Salsa | Gemas vuelan hacia el jugador |
| `guac_storm` | GS | Salvo Guac | +1 columna de disparos a ±40×N px |

### Metagame
- **Moneda:** Oro — score × 0.1 + corazones × 25 (al ganar) / score × 0.1 (al perder)
- **Upgrades permanentes (6):** Daño, Velocidad, Vida, Suerte, Bono de Oro, Escudo Inicial
- **Costo:** `50 × 1.8^nivel` — cap nivel 5

---

## Autoloads registrados en project.godot

**Orden crítico — Constants debe ir primero:**

| Nombre | Archivo | Rol |
|---|---|---|
| `Constants` | `src/core/Constants.gd` | Constantes del juego (cargado primero) |
| `EventBus` | `src/core/EventBus.gd` | Bus de señales global |
| `GameManager` | `src/core/GameManager.gd` | Estado de partida |
| `SaveManager` | `src/core/SaveManager.gd` | Persistencia |
| `AudioManager` | `src/features/audio/AudioManager.gd` | SFX + Hápticos |

---

## Skills y Agentes Disponibles

### Skills (slash commands)

| Comando | Cuándo usar |
|---|---|
| `/validate` | Antes de cualquier commit — corre gdlint + GUT y reporta GREEN/BLOQUEADO |
| `/feature [nombre]` | Al implementar cualquier feature nueva — guía completa PLAN→IMPL→VALIDATE→SANITY→DOC |
| `/doc` | Al cerrar cualquier tarea — sincroniza idea-base.md, CLAUDE.md y memorias |
| `/new-game [gdd.md]` | Para construir un juego nuevo desde cero — autónomo hasta build funcional |

Los skills viven en `.claude/skills/<nombre>/SKILL.md`.

### Agentes sub-agent

| Agente | Cuándo delegar |
|---|---|
| `godot-architect` | Code review de arquitectura — detecta violaciones SOLID, acoplamiento directo, anti-patrones |
| `godot-qa` | Auditoría de tests — identifica cobertura faltante, escribe tests GUT |
| `game-designer` | Balance review — verifica que los valores numéricos den una buena experiencia |

Los agentes viven en `.claude/agents/<nombre>.md`.

### Hook automático

`.claude/hooks/lint-on-edit.sh` corre `gdlint` en cada archivo `.gd` que se edita o escribe.
El resultado aparece como `additionalContext` — informativo, no bloquea.

---

## Pendientes Documentados

### Solo código (sin assets externos)
| Feature | Archivo(s) a crear/modificar | Notas |
|---|---|---|
| ~~Settings screen~~ | ✅ Completado | Sensibilidad + sonido on/off + vibración on/off |
| Cuentas de usuario | SDK externo requerido | Facebook/Google/propio |
| Misiones diarias | Sistema de tracking + UI | Oro extra por objetivos |
| Export release Android | `export_presets.cfg`, keystore secret | Keystore firmado en GitHub Secrets |
| Export release iOS | Provisioning profile, Apple Dev account | |

### Assets externos requeridos
| Asset | Ruta esperada | Notas |
|---|---|---|
| 5 fondos de bioma | `assets/sprites/backgrounds/bg_0…4.png` | 390×844 px, pixel art |
| 7 SFX | `assets/audio/*.ogg` | shoot, enemy_die, boss_die, player_hit, levelup, gem_collect, music_loop |
| Sprites de personajes | `assets/sprites/` | player, 4 enemigos, proyectil, gema |
| 9 íconos de power-up | `assets/sprites/powerup_icons/` | ts, sg, rf, mg, jl, sb, nw, sm, gs — 32×32 px |
