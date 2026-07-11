# CLAUDE.md — GuacBlaster Survivor

Guía autoritativa de desarrollo para Claude Code. **Lee este archivo completo antes de cualquier tarea.**

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Motor | Godot 4.x (GDScript con tipado estático) |
| Testing | GUT (Godot Unit Testing) v7.x |
| Lint/Format | gdtoolkit (`gdlint` / `gdformat`) vía pip |
| Plataforma | iOS 14+ / Android API 24+ |
| Arte | Pixel art / Vector toony |
| Control | Touch & Drag horizontal (1 dedo) |

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
  -gdir=res://tests -gexit -glog=2

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
│   ├── EventBus.gd         # Bus de señales (TODA comunicación cross-feature)
│   ├── GameManager.gd      # Máquina de estados de partida
│   ├── Constants.gd        # Constantes tipadas (sin magic numbers)
│   └── SaveManager.gd      # Persistencia JSON (user://)
├── features/
│   ├── player/             # Input, movimiento, vida del jugador
│   ├── projectiles/        # Proyectiles y sus variantes
│   ├── enemies/            # EnemyBase + cada subtipo + Spawner
│   ├── powerups/           # Sistema de power-ups y UI de selección
│   ├── meta/               # ProgressionManager, árbol de mejoras
│   ├── audio/              # AudioManager + HapticManager
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
```

**Una tarea NO está terminada hasta que el paso (c) pase en verde.**

---

## Referencia Rápida del GDD

### Valores base del jugador
| Stat | Valor base | Upgrade meta |
|---|---|---|
| HP | 3 corazones | +1 corazón/nivel |
| Velocidad | 200 px/s | +3%/nivel |
| Daño base | 10 | +5%/nivel |
| Autofire interval | 0.4s | reducible con Fuego Rápido |

### Enemigos
| Tipo | HP | Comportamiento especial |
|---|---|---|
| Burbuja Básica | 1 | Línea recta descendente |
| Burbuja Tanque | N | Split en 4 básicas al morir |
| Mosca Nacho | 1 | Zigzag diagonal, rápida |
| Jefe | Alto | Dispara proyectiles lentos, cada 3 min |

### Power-ups (IDs en Constants.POWERUP_POOL)
| ID | Nombre | Efecto |
|---|---|---|
| `triple_shot` | Disparo Triple | +2 disparos diagonales |
| `super_guac` | Súper-Guac | Proyectiles grandes que penetran 3 enemigos |
| `rapid_fire` | Fuego Rápido | +25% cadencia |
| `mole_grenade` | Granada de Mole | AoE cada 5s |
| `jalapeno_laser` | Láser de Jalapeño | Haz 2s columna entera |
| `spicy_bounce` | Rebote Picante | Proyectiles rebotan en bordes |
| `nacho_wall` | Muro de Nachos | Escudo: absorbe 3 impactos |
| `salsa_magnet` | Imán de Salsa | Atrae gemas de XP automáticamente |

### Metagame
- Moneda: Oro (drop al final de partida + misiones diarias)
- Árbol de mejoras permanentes: Daño, Velocidad, Vida, Suerte

---

## Autoloads registrados en project.godot

| Nombre | Archivo | Rol |
|---|---|---|
| `EventBus` | `src/core/EventBus.gd` | Bus de señales global |
| `GameManager` | `src/core/GameManager.gd` | Estado de partida |
| `Constants` | `src/core/Constants.gd` | Constantes del juego |
| `SaveManager` | `src/core/SaveManager.gd` | Persistencia |
| `AudioManager` | `src/features/audio/AudioManager.gd` | SFX + Hápticos |
