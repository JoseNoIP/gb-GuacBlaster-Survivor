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
| CI/CD | GitHub Actions → AAB firmado en Google Play Store (Internal/Production) |
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

### Reglas Android CI/CD (Godot 4.7 → Google Play)
18. **Godot 4.7 no exporta `.aab` directamente** — rechaza la extensión. Exportar siempre a `.apk` (paso 1: popula `android/build/`), luego producir AAB con `./gradlew bundleRelease` (paso 2).
19. **`--install-android-build-template`** — este flag extrae `android_source.zip` y escribe `.build_version` con el string exacto que Godot espera. **Nunca** escribir `.build_version` a mano ni usar `godot --version` (no produce output en headless).
20. **`shouldSign()` en `config.gradle` es `false` por defecto** — pasar **siempre** `-Pperform_signing=true -Prelease_keystore_file=RUTA -Prelease_keystore_password=PASS -Prelease_keystore_alias=ALIAS` a `bundleRelease`. Las props `android.injected.signing.*` no aplican al template de Godot.
20b. **`export_version_code` default=1 en `config.gradle`** — el `sed` sobre `export_presets.cfg` solo afecta la exportación del APK (Godot). Para el AAB que genera Gradle se debe pasar `-Pexport_version_code=N` explícitamente a `bundleRelease`. Sin esto el version code siempre es 1 y Play Store rechaza cada subida posterior. Usar `$(( ($(date +%s) - 1704067200) / 60 ))` como value (minutos desde 2024-01-01, ~815k hoy, crece ~525k/año).
21. **Package name default de Godot es `com.godot.game`** — pasar **siempre** `-Pexport_package_name=com.tuempresa.tujuego` a `bundleRelease`. Sin esto, Play Store rechaza el AAB por fileprovider incorrecto.
22. **`assetPackInstallTime/src/main/assets` debe existir** — `mkdir -p android/build/assetPackInstallTime/src/main/assets` antes de correr Gradle (el módulo de Play Asset Delivery lo requiere).
23. **Primera subida a Play Store debe ser manual** — la API de Google Play retorna error genérico hasta que exista al menos una versión subida manualmente desde Play Console. Descargar el AAB del artefacto CI y subirlo una vez desde la web.
24. **Pre-heat obligatorio** — `godot --headless --editor --quit || true` antes del export. Sin este paso, el file-system scanner de Godot puede crashear en headless al exportar.
### Reglas de Multi-idioma / i18n (Godot 4.7)
26. **`LocalizationManager` NO lleva `class_name`** — es autoload. Añadirle `class_name` provoca conflicto fatal (regla #10).
27. **No usar archivos `.translation` binarios en CI/CD** — requieren import del editor Godot. Usar CSV parseado en runtime con `FileAccess.get_csv_line()` y objetos `Translation` creados programáticamente.
28. **Saltos de línea en CSV** — el separador de CSV rompe si se incluyen `\n` literales. Usar `[BR]` como placeholder y reemplazarlo por `"\n"` en `_load_csv()`.
29. **`LocalizationManager` debe cargarse DESPUÉS de `SaveManager`** en `project.godot` — necesita `SaveManager.get_language()` en `_ready()`.
30. **El CSV de traducciones no se exporta automáticamente a Android** — `FileAccess.open("res://...")` en runtime no hace que Godot incluya el archivo en el PCK. Añadir `*.csv` al `include_filter` en `export_presets.cfg`. Sin esto, `tr("KEY")` devuelve la clave cruda en Android pero funciona en el editor (que lee del disco directamente).
31. **Chino y japonés requieren fuente especial** — el tema default de Godot no incluye esos glifos. No añadirlos sin fuente compatible.

25. **`bundleRelease` no firma aunque se pasen `-Pperform_signing=true`** — en Godot 4.7, `config.gradle` puede ignorar estos flags. Solución: firmar el AAB explícitamente con `jarsigner` después de construirlo, antes de subir a Play Store. JAR Signature (v1) es suficiente — Google Play reemplaza la firma al distribuir si se usa Google Play App Signing. Ejemplo: `jarsigner -sigalg SHA256withRSA -digestalg SHA-256 -keystore KEY.keystore -storepass PASS builds/GuacBlaster.aab ALIAS`.

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
- [ ] **Referencia competitiva**: ¿Se buscó cómo resuelven esta mecánica los juegos top del género actual? (WebSearch con género + mecánica antes de decidir valores o diseño — no asumir genre, leer CLAUDE.md primero)
- [ ] ¿Los valores vienen de `Constants.gd`?
- [ ] ¿El comportamiento respeta exactamente el GDD §3 (power-ups) y §4 (enemigos)?
- [ ] ¿Hay feedback visual (partículas/tween) Y auditivo (SFX) en cada interacción?
- [ ] ¿El feedback háptico está implementado para disparo y eventos críticos?
- [ ] ¿La sesión puede completarse en 2–5 minutos?
- [ ] ¿La feature se alinea con patrones probados del género o introduce diferenciación justificada?

### ⚡ Feel / Combat Agent
**Cuándo activa:** Implementación o revisión de contacto jugador-enemigo, curva de dificultad, cualquier sensación de impacto.  
**Principios aprendidos (GuacBlaster, 2026-07):**
- **Contacto enemigo-jugador tiene que tener consecuencia y lógica por tipo:**
  - Enemigos desechables (básicos): mueren al tocar → `on_player_contact()` → daño + `_contact_die()` (no emite XP).
  - Enemigos de peso (zigzag, tank): sobreviven al contacto → daño pero sin morir; el jugador los esquiva.
  - Enemigos élite: cargan antes de explotar → tween rojo/dorado, 1.5s de telegrafía, 2 de daño → más impacto sin death-loop.
- **`_invincibility_timer` es crítico** — sin él, un enemigo que hace overlap genera múltiples hits por frame = muerte instantánea injusta.
- **Curva de dificultad: preferir rampas suaves y largas:**
  - `BOSS_HP_BASE: 300` (no 400) — el primer jefe tiene que ser vencible con build modesta.
  - `ENEMY_HP_SCALE_PER_MIN: 0.25` (no 0.4) — si escala muy rápido los últimos 30s del jefe se vuelven imposibles.
  - `SPAWNER_WAVE_RAMP_INTERVAL: 90s` — olas cada 90s, no cada 30s; dar tiempo al jugador de nivel-up entre olas.
- **Telegrafía = respeto al jugador:** cualquier ataque que haga más de 1 de daño debe tener al menos 0.75s de anticipación visual (tween de color, partícula, sonido).
- **Checklist:**
  - [ ] ¿Cada tipo de enemigo tiene un comportamiento de contacto con lógica propia (`on_player_contact`)?
  - [ ] ¿El `_invincibility_timer` es > 0 después de cualquier hit de contacto?
  - [ ] ¿El jefe gen-0 puede vencerse en una sesión con 1–2 power-ups? (target: 40 disparos de daño base)
  - [ ] ¿Los enemigos élite telegrafían su ataque especial visualmente antes de dañar?
  - [ ] ¿La tasa de spawn en minuto 1 deja al jugador aprender sin abrumarlo?

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
| `boss_phase_changed(phase)` | EnemyBoss | HUD (flash "¡FASE 2!"), HapticManager |
| `elite_powerup_dropped(position, powerup_id)` | EnemyElite | PowerUpDropper |
| `heart_collected` | HeartDrop | Player, HapticManager |
| `achievement_unlocked(id)` | AchievementManager | (informativa — UI puede escuchar) |
| `mission_completed(id, reward)` | DailyMissionsManager | (informativa — UI puede escuchar) |
| `mission_progress(id, current, target)` | DailyMissionsManager | (informativa) |
| `weekly_challenge_completed(id)` | WeeklyChallengeManager | HUD (toast morado) |

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
| Tipo | HP | Disparos para matar (daño base=10) | Comportamiento especial |
|---|---|---|---|
| Burbuja Básica | 10 | 1 | Línea recta descendente |
| Burbuja Tanque | 80 | 8 | Split en 4 básicas al morir |
| Mosca Nacho | 50 | 5 | Zigzag diagonal, doble tamaño de básica |
| Élite Dorada | 200 (10×20) | 20 | Drop power-up al morir |
| Jefe | 400+80×gen | 40+ | Dispara proyectiles, aparece cada 3 min |

### Power-ups (IDs en Constants.POWERUP_POOL) — todos temporales **45s**, stackables
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
- **Personajes (3):** guac (base/gratis), habanero (200 oro), serrano (300 oro). Modificadores de HP, fire_rate_mult y damage_mult aplicados en `Player._on_game_started()`.
- **Logros (10):** persistidos en SaveManager. Pantalla en AchievementsScreen.tscn.
- **Misiones diarias (3/día):** generadas por hash de fecha. Progreso persiste en SaveManager. Recompensa en oro.

---

## Autoloads registrados en project.godot

**Orden crítico — Constants debe ir primero:**

| Nombre | Archivo | Rol |
|---|---|---|
| `Constants` | `src/core/Constants.gd` | Constantes del juego (cargado primero) |
| `EventBus` | `src/core/EventBus.gd` | Bus de señales global |
| `GameManager` | `src/core/GameManager.gd` | Estado de partida |
| `SaveManager` | `src/core/SaveManager.gd` | Persistencia |
| `AudioManager` | `src/features/audio/AudioManager.gd` | SFX + Hápticos (disparo, boss) |
| `HapticManager` | `src/features/audio/HapticManager.gd` | Hápticos orientados a eventos |
| `AchievementManager` | `src/features/meta/AchievementManager.gd` | Logros persistentes |
| `DailyMissionsManager` | `src/features/meta/DailyMissionsManager.gd` | Misiones diarias |
| `WeeklyChallengeManager` | `src/features/meta/WeeklyChallengeManager.gd` | Desafío semanal |

---

## Skills y Agentes Disponibles

### Skills (slash commands)

| Comando | Cuándo usar |
|---|---|
| `/validate` | Antes de cualquier commit — corre gdlint + GUT y reporta GREEN/BLOQUEADO |
| `/feature [nombre]` | Al implementar cualquier feature nueva — guía completa PLAN→IMPL→VALIDATE→SANITY→DOC |
| `/doc` | Al cerrar cualquier tarea — sincroniza idea-base.md, CLAUDE.md y memorias |
| `/new-game [gdd.md]` | Para construir un juego nuevo desde cero — autónomo hasta build funcional. Incluye FASE 0 de preguntas de alcance (i18n, perspectiva, CI/CD) |
| `/gen-ai-art` | Generar arte final de un juego con Pollinations.ai (Flux, gratis) — backgrounds, sprites con transparencia, íconos procedurales |
| `/android-deploy` | Configurar o depurar el pipeline CI/CD de GitHub Actions para publicar en Google Play Store como AAB firmado — incluye mapa completo de errores conocidos (Godot 4.7) y workflow probado y funcional |
| `/mobile-i18n` | Agregar soporte multi-idioma a un juego Godot móvil — CSV runtime, LocalizationManager autoload, selector de idioma, SettingsScreen |

Los skills viven en `.claude/skills/<nombre>/SKILL.md`.

### Agentes sub-agent

| Agente | Cuándo delegar |
|---|---|
| `godot-architect` | Code review de arquitectura — detecta violaciones SOLID, acoplamiento directo, anti-patrones |
| `godot-qa` | Auditoría de tests — identifica cobertura faltante, escribe tests GUT |
| `game-designer` | Balance review — verifica que los valores numéricos den una buena experiencia |
| `game-feel` | Revisión de combat feel, contacto jugador-enemigo, curva de dificultad, telegrafía de ataques |

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
| ~~HapticManager~~ | ✅ Completado | Eventos: damaged, powerup, boss_phase, heart |
| ~~Logros persistentes~~ | ✅ Completado | 10 logros, AchievementManager autoload + AchievementsScreen |
| ~~Misiones diarias~~ | ✅ Completado | DailyMissionsManager autoload + DailyMissionsScreen |
| ~~Personajes alternativos~~ | ✅ Completado | 8 personajes con fire_mode, CharacterSelectScreen, Player carga sprite único por personaje |
| ~~Mapa de biomas~~ | ✅ Completado | BiomeMapScreen, lock/unlock por victorias |
| ~~Desafío semanal~~ | ✅ Completado | WeeklyChallengeManager autoload + WeeklyChallengeScreen + 3 desafíos |
| ~~Toast personaje~~ | ✅ Completado | CharacterSelectScreen + HUD muestran nombre al seleccionar/iniciar |
| Cuentas de usuario | SDK externo requerido | Facebook/Google/propio |
| ~~Export release Android~~ | ✅ Completado | `.github/workflows/deploy-playstore.yml` — AAB firmado → Google Play. Skill: `/android-deploy` |
| Export release iOS | Provisioning profile, Apple Dev account | |

### Assets completados con IA
| Asset | Ruta | Estado | Herramienta |
|---|---|---|---|
| 18 fondos de bioma (6 biomas × 3 variantes) | `assets/sprites/backgrounds/bg_N_V.png` | ✅ AI-generated | Pollinations.ai (Flux) 390×844 |
| Player | `assets/sprites/player.png` | ✅ AI-generated | Pollinations.ai (Flux) 64×64 |
| 5 enemigos + boss | `assets/sprites/enemy_*.png` | ✅ AI-generated | Pollinations.ai (Flux) |
| Proyectil, gema, corazón | `assets/sprites/{projectile,gem,heart}.png` | ✅ AI-generated | Pollinations.ai (Flux) |
| 9 íconos de power-up | `assets/sprites/powerup_icons/*.png` | ✅ Mejorados (procedural) | gen_assets.py rediseñado |
| 8 íconos de menú principal | `src/features/ui/IconPainter.gd` | ✅ Procedural en _draw() | IconPainter Control |
| 8 sprites de personaje | `assets/sprites/characters/player_*.png` | ✅ AI-generated | Pollinations.ai (Flux) 64×64 |
| Boot splash + App icon | `assets/splash.png`, `assets/icon.png` | ✅ Procedural (GuacamoleBit logo) | gen_assets.py |
| 7 SFX | `assets/audio/*.wav` | ✅ Sintéticos | gen_assets.py |

**Pipeline de regeneración de assets:**
```bash
# Regenerar sprites + íconos procedurales (fallback si AI falla)
python3 tools/gen_assets.py

# Re-generar assets AI (backgrounds + sprites principales)
/tmp/gb_venv/bin/python3 tools/fetch_ai_assets.py
# (requiere: python3 -m venv /tmp/gb_venv && /tmp/gb_venv/bin/pip install Pillow)

# Re-descargar sprites de personaje únicamente
/tmp/gb_venv/bin/python3 tools/fetch_character_sprites.py
# Después: godot --headless -e --quit  (regenerar .import)

# Re-descargar solo biomas 0 y 1 (si fueron sobrescritos)
/tmp/gb_venv/bin/python3 tools/redownload_missing_bgs.py
```

### Assets aún pendientes
| Asset | Notas |
|---|---|
| 7 SFX en formato OGG | Actualmente WAV sintéticos; Godot puede importar WAV, no bloquea |
| Audio de mejor calidad | Música loop y SFX mejorados requieren compositor o banco de sonidos libre |
