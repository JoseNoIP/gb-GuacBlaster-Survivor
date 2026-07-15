---
name: new-game
description: Construye un juego móvil Godot 4 completo y funcional a partir de un GDD en markdown. 100% autónomo hasta tener build verde.
context: fork
effort: max
agent: general-purpose
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
---

## /new-game [ruta/al/gdd.md] — Construcción autónoma de juego móvil

GDD a implementar:

```
!`cat $ARGUMENTS`
```

---

## Contexto del stack

Este proyecto usa:
- **Godot 4.7** / GDScript con tipado estático obligatorio
- **GUT v9.7.1** en `addons/gut/` para tests
- **gdtoolkit** (`gdlint` / `gdformat`) para lint
- **Plataforma:** iOS 14+ / Android API 24+ (pantalla vertical, 1 dedo)
- **CI/CD:** GitHub Actions → APK en Dropbox

Lee `CLAUDE.md` completo antes de empezar — contiene todas las reglas anti-alucinación, convenciones de código, y estructura de carpetas.

---

## Protocolo de construcción autónoma

Sigue estas fases en orden. Cada fase termina con su gate de validación antes de continuar.

---

### FASE 1 — Parsear GDD

Extraer y confirmar:
- [ ] Nombre del juego, plataforma, orientación
- [ ] Mecánica core (qué hace el jugador cada frame)
- [ ] Condición de victoria y derrota
- [ ] Entidades: jugador, enemigos, items, proyectiles
- [ ] Power-ups / habilidades con sus IDs y efectos
- [ ] Progresión: XP, niveles, metagame (upgrades, moneda)
- [ ] UI requerida: menús, HUD, pantallas de resultado
- [ ] Señales principales (derivar del diseño si no están explícitas)
- [ ] Valores numéricos: HP, velocidad, daño, intervalos, duraciones

Si el GDD no especifica un valor → usar valor razonable para hyper-casual móvil y documentarlo.

---

### FASE 2 — Scaffold del proyecto

```bash
# Verificar que Godot esté disponible
godot --version

# Estructura de carpetas (feature-first)
mkdir -p src/core src/features/player src/features/projectiles
mkdir -p src/features/enemies src/features/powerups src/features/gems
mkdir -p src/features/meta src/features/audio src/features/vfx src/features/ui
mkdir -p src/scenes src/shared
mkdir -p assets/sprites assets/audio assets/fonts
mkdir -p tests/unit builds/debug builds/release
```

Crear `project.godot` con:
- Autoloads en orden: Constants → EventBus → GameManager → SaveManager → AudioManager
- Display/window: 390×844 (portrait), stretch mode: canvas_items, aspect: expand
- Physics layers nombradas: player(1), enemy(2), projectile(3), item(4), powerup(5)

---

### FASE 3 — Core systems

Crear en este orden (dependencias primero):

#### 3.1 Constants.gd
Todas las constantes del GDD. Incluir:
- Valores del jugador (HP, speed, damage, fire_rate)
- Valores de enemigos (HP, speed, XP, gold)
- Valores de power-ups (duración, pool)
- Valores de UI (colores, fuentes)
- Paletas de background (mínimo 3)
- Constantes de metagame (costos de upgrade)

#### 3.2 EventBus.gd
Todas las señales derivadas del GDD, agrupadas por sección:
```
# --- Player ---
# --- Enemies ---
# --- PowerUps ---
# --- Progression ---
# --- Game State ---
# --- UI ---
```

#### 3.3 GameManager.gd
- Enum de estados: `{ MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER, GAME_WON }`
- Timers: session_time, boss_spawn_interval
- Transiciones: start_game, pause_game, resume_game, game_over, game_won
- Métodos: get_state(), get_session_time()

#### 3.4 SaveManager.gd
- Persistencia en `user://save.json`
- Guarda: gold, upgrades (array), best_score, total_sessions, victories
- Métodos: get_gold(), add_gold(), get_upgrade_level(), upgrade(), get_victories()
- Auto-carga en `_ready()`, auto-guarda en cada cambio

#### 3.5 AudioManager.gd
- Stub funcional: métodos `play_sfx(name)`, `play_music()`, `stop_music()`
- No crashea si el archivo .ogg no existe (verifica antes de cargar)

**Gate 3:** `gdlint src/core/` — debe pasar a 0 errores.

---

### FASE 4 — Player y controles

#### 4.1 Player.gd (CharacterBody2D)
- Drag con ancla (NO salto al primer toque):
  ```gdscript
  # InputEventScreenTouch: registra _drag_anchor_x y _drag_anchor_player_x
  # InputEventScreenDrag: _target_x = _drag_anchor_player_x + (drag.x - _drag_anchor_x) * sensitivity
  ```
- Autofire: Timer con intervalo desde Constants
- HP, shield, invulnerabilidad temporal post-daño
- Emitir señales: player_health_changed, player_died

#### 4.2 ProjectileSpawner.gd
- Instancia proyectiles en posición del jugador
- Responde a powerup_stack_changed para modificar patrones

#### 4.3 Projectile.gd (Area2D)
- Velocidad, daño, pierce, bounce según power-ups activos
- `_exit_tree()` desconecta señales

**Gate 4:** `gdlint src/features/player/` — 0 errores.

---

### FASE 5 — Enemigos

#### 5.1 EnemyBase.gd (CharacterBody2D)
- take_damage(amount), _die(), _initialize()
- Emite enemy_destroyed(id, position, gem_value)
- NO implementar comportamiento aquí — solo interfaz

#### 5.2 Un subtipo por enemigo del GDD
- Herencia: `extends "res://src/features/enemies/EnemyBase.gd"`
- Cada uno en su propio archivo (enemy_basic.gd, enemy_tank.gd, etc.)
- Comportamiento único en `_physics_process()`

#### 5.3 EnemySpawner.gd
- Dificultad creciente por tiempo
- Unlock de tipos por tiempo/generación
- NO se pausa durante level-up (continuar spawneando)

#### 5.4 EnemyBoss.gd
- Hereda de EnemyBase
- HP = base + increment × generación
- Emite boss_health_changed(current, maximum) en take_damage()
- Emite boss_defeated al morir

**Gate 5:** `gdlint src/features/enemies/` — 0 errores.

---

### FASE 6 — Power-ups y progresión

#### 6.1 PowerUpManager.gd
- `_stacks: Dictionary` (id → count)
- `_timers: Dictionary` (id → Array[float])
- `add_stack(id)`: agrega 1 stack con timer independiente
- `_process(delta)`: decrementa timers, emite powerup_stack_changed al expirar
- `get_stack_count(id) -> int`

#### 6.2 PowerUpDrop.gd + PowerUpDrop.tscn
- Area2D que cae desde arriba
- Al contacto con player: emite powerup_selected(id)
- Los demás drops desaparecen vía powerup_selected signal

#### 6.3 PowerUpDropper.gd
- Escucha powerup_selection_requested(options)
- Instancia 3 PowerUpDrop con IDs random del pool
- Posiciones: distribuidas horizontalmente

#### 6.4 XPGem.gd
- Cae al morir enemigos
- Atracción magnética si salsa_magnet activo
- Emite xp_collected(amount, total, required)

#### 6.5 GemSpawner.gd
- Instancia XPGem en posición del enemigo muerto

**Gate 6:** `gdlint src/features/powerups/ src/features/gems/` — 0 errores.

---

### FASE 7 — Metagame y meta-progresión

#### 7.1 ProgressionManager.gd (o integrado en GameManager)
- XP_BASE_REQUIRED, XP_SCALE_FACTOR
- level_up: emite player_level_up(level), powerup_selection_requested(options)
- Selección de 3 power-ups random ponderada por "suerte"

#### 7.2 UpgradeScreen.gd
- 6 upgrades (derivar del GDD o usar estándar: damage, speed, health, luck, gold_bonus, starter_shield)
- Costo: `50 × 1.8^nivel`, cap nivel 5
- Guarda en SaveManager

---

### FASE 8 — UI completa

Pantallas mínimas requeridas:
- **MainMenu.tscn** — botones: JUGAR, MEJORAS, CONFIGURACIÓN
- **Game.tscn** — escena principal con HUD
- **HUD.gd** — corazones, XP bar, score, nivel, timer de boss, tira de power-ups activos, barra HP boss
- **PauseScreen.tscn** — CONTINUAR, REINICIAR, MENU PRINCIPAL
- **GameOverScreen.tscn** — score, oro ganado, botón REINTENTAR
- **VictoryScreen.tscn** — score, oro, bioma siguiente, botón CONTINUAR
- **UpgradeScreen.tscn** — grid de upgrades con costos
- **SettingsScreen.tscn** — sensibilidad swipe (slider), sound on/off, vibración on/off

Reglas UI:
- Todo texto de gameplay: mínimo 18px (legibilidad en móvil)
- Colores de HUD: sacar de Constants para poder cambiarlos globalmente
- Pantallas de overlay: CanvasLayer con `process_mode = PROCESS_MODE_ALWAYS`
- `_panel.hide()` en `_ready()` para todos los overlays

---

### FASE 9 — Game.tscn (escena raíz)

Conectar todo:
- Instanciar: Player, EnemySpawner, PowerUpManager, PowerUpDropper, GemSpawner, HeartDropper
- Instanciar HUD, PauseScreen, GameOverScreen, VictoryScreen, BossWarning
- Background: ColorRect (o TextureRect si hay assets)
- `Game.gd`: conectar restart_requested, game_over, game_won con cambios de escena
- Auto-pausa: `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)`

---

### FASE 10 — Tests GUT

Mínimo un archivo de test por feature principal:
- `tests/unit/test_player.gd` — movimiento, daño, shield
- `tests/unit/test_powerup_manager.gd` — stacks, timers, expiración
- `tests/unit/test_game_manager.gd` — transiciones de estado
- `tests/unit/test_save_manager.gd` — persistencia, upgrades, gold
- `tests/unit/test_enemy_base.gd` — take_damage, die, signals
- `tests/unit/test_hud.gd` — actualización de HP, XP, score, boss bar
- `tests/unit/test_progression.gd` — XP threshold, level-up signal

Cada test: caso normal + borde mínimo + borde máximo + entrada inválida.

---

### FASE 11 — VALIDATE FINAL

```bash
# Gate lint
gdlint src/ tests/

# Gate tests
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gexit -glog=2 2>&1

# Gate build
godot --headless --export-debug "Android" builds/debug/game.apk 2>&1
```

Los tres gates deben estar en verde. Si alguno falla → corregir antes de reportar terminado.

---

### FASE 12 — Documentación

1. Crear `idea-base.md` con:
   - Resumen del juego (del GDD)
   - Features implementadas (todas)
   - Assets externos requeridos (sprites, audio)
   - Pendientes de código
   - Setup de CI/CD

2. `CLAUDE.md` ya existe en el template — actualizar con:
   - Señales reales del EventBus
   - Valores reales del jugador
   - Lista real de power-ups
   - Estado actual del juego

3. Confirmar al usuario:
   ```
   BUILD COMPLETO — [nombre del juego]

   Features: [lista]
   Tests: N passing
   Lint: 0 errores
   Build: APK generado en builds/debug/

   Assets pendientes (sin código): [lista]
   ```

---

## GDD mínimo requerido

Si el GDD proporcionado no tiene alguno de estos campos, preguntar antes de asumir:
- Nombre del juego
- Mecánica core (cómo se mueve/ataca el jugador)
- Condición de victoria
- Condición de derrota
- Al menos 2 tipos de enemigos
- Al menos 3 power-ups
- Loop de progresión (¿hay metagame?)
