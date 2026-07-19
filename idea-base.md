# Pendientes y Configuración

---

## CI/CD — GitHub Actions

Workflow: `.github/workflows/build-android.yml`

**Estado actual:** ✅ Compilación + subida a Dropbox funcionando.

### Lógica de ramas
| Rama | APK generado | Destino Dropbox |
|---|---|---|
| `staging` | `GuacBlaster-stg-{BUILD}.apk` | `/Guacamole Bit/GuacBlaster/stg/` |
| `main` | `GuacBlaster-prod-{BUILD}.apk` | `/Guacamole Bit/GuacBlaster/prod/` |

El número de build (`github.run_number`) evita sobrescribir versiones anteriores.
El APK también queda como artefacto descargable en GitHub por 14 días.

### Variables del workflow
- `GODOT_VERSION = "4.7"` — coincide con la versión instalada
- `DROPBOX_ROOT = "/Guacamole Bit/GuacBlaster"` — raíz en Dropbox

### Secrets requeridos en GitHub
Ir a: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Descripción |
|---|---|
| `DROPBOX_APP_KEY` | App Key de tu Dropbox App |
| `DROPBOX_APP_SECRET` | App Secret de tu Dropbox App |
| `DROPBOX_REFRESH_TOKEN` | Refresh token OAuth2 |

### Cómo crear la Dropbox App y obtener el refresh token

1. Ir a https://www.dropbox.com/developers/apps → **Create app**
2. Elegir **Scoped access** → **Full Dropbox**
3. En la pestaña **Permissions** activar: `files.content.write`, `files.content.read`
4. Anotar **App key** y **App secret** de la pestaña Settings

Para generar el refresh token (una sola vez desde tu máquina):
```bash
# Paso 1: abre este URL en el navegador (reemplaza APP_KEY)
# https://www.dropbox.com/oauth2/authorize?client_id=APP_KEY&response_type=code&token_access_type=offline

# Paso 2: después de autorizar recibes un code. Intercámbialo:
curl -X POST https://api.dropbox.com/oauth2/token \
  -d code=EL_CODE_QUE_RECIBISTE \
  -d grant_type=authorization_code \
  -u "APP_KEY:APP_SECRET"

# El campo "refresh_token" de la respuesta es el que va al secret de GitHub.
```

### Keystore de firma (evita el "no se puede actualizar" en Android)

Android rechaza actualizaciones si la firma cambia entre builds. Solución: keystore fijo en todos los entornos.

**Generar keystore (una sola vez):**
```bash
keytool -genkey -v \
  -keystore guacblaster.keystore \
  -alias guacblasterkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass guacblaster2024 -keypass guacblaster2024 \
  -dname "CN=GuacamoleBit, OU=GuacBlaster, O=GuacamoleBit, L=MX, ST=MX, C=MX"

# Codificar para GitHub Secret:
base64 -i guacblaster.keystore | pbcopy
```

**Secrets requeridos (además de los de Dropbox):**

| Secret | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | base64 del archivo .keystore |
| `ANDROID_KEYSTORE_ALIAS` | `guacblasterkey` |
| `ANDROID_KEYSTORE_PASS` | `guacblaster2024` |

**En el editor de Godot (local):**
Project → Export → Android → Options → Keystore → Debug:
- Keystore: apunta al archivo `guacblaster.keystore` local
- User: `guacblasterkey`
- Password: `guacblaster2024`

El workflow parchea automáticamente el path en CI con `sed`.

### Notas
- `export_presets.cfg` está en el repo (debug build).
- **No commitear el archivo `.keystore`** — solo vive como GitHub Secret y en tu máquina local.
- Para release build en Play Store se necesitará un keystore separado con firma de producción.

---

# Mejoras Implementadas

## Settings Screen — Sensibilidad, Sonido y Vibración ✅
- Escena `SettingsScreen.tscn` / `.gd` en `src/scenes/`, accesible desde el menú principal.
- **Sensibilidad de control:** slider 100%–200%, paso 20%. Guardado en `SaveManager._data["swipe_sensitivity"]`.
- **Sonido on/off:** `CheckButton` que guarda en `SaveManager._data["sound_enabled"]`. `AudioManager.play_sfx()` comprueba la flag antes de reproducir.
- **Vibración on/off:** `CheckButton` que guarda en `SaveManager._data["vibration_enabled"]`. `AudioManager.trigger_haptic_*()` comprueba la flag antes de vibrar.
- Los tres valores persisten entre sesiones vía `user://save.json`.

## Sistema de Power-ups temporal y stackable ✅
- Cada pick-up agrega un stack con timer de **15 segundos** independiente.
- Al expirar un stack, los efectos se reducen automáticamente (o desaparecen si era el último).
- Se pueden acumular múltiples stacks del mismo power-up.
- Al subir de nivel caen **3 items físicos** desde arriba de la pantalla (PowerUpDrop).
  El jugador toca el que quiere recoger; al tocarlo, los otros 2 desaparecen.
- El juego **no se pausa** durante la selección de power-ups.

### Salvo Guac (GS) — distribución simétrica ✅
- Los streams se distribuyen simétricamente respecto al centro del jugador.
- 1 stack = X2 = ±20 px, 2 stacks = X3 = −40/0/+40 px, hasta X6 = 5 extras.
- Cada stream dispara también los proyectiles de Triple Shot si está activo.
- Triple Shot ahora se aplica a TODOS los streams, no solo al central.

### Power-ups activos (9 en total)
| Iniciales | Nombre | Efecto | Duración |
|---|---|---|---|
| **TS** | Disparo Triple | +2 disparos diagonales | 45s por stack |
| **SG** | Súper-Guac | Proyectiles penetran 3 enemigos | 45s por stack |
| **RF** | Fuego Rápido | Cadencia ×2 por stack | 45s por stack |
| **MG** | Granada Mole | AoE automático cada 5s | 45s por stack |
| **JL** | Láser Jalapeño | Rayo de columna que sigue al jugador | 2s por stack |
| **SB** | Rebote Picante | Proyectiles rebotan en bordes | 45s por stack |
| **NW** | Muro Nachos | Escudo: absorbe 3 impactos por stack | 45s por stack |
| **SM** | Imán Salsa | Gemas vuelan hacia el jugador | 45s por stack |
| **GS** | Salvo Guac | +1 columna de disparos por stack (a ±40×N px del centro) | 45s por stack |

### Tira de power-ups activos en HUD ✅
- `VBoxContainer` anclado a la derecha de la pantalla, debajo del botón de pausa.
- Cada power-up activo aparece como `RF×2`, `TS×1`, `GS×3`, etc. con color propio por tipo.
- Colores: RF=naranja, TS=azul claro, SG=verde, MG=rojo, JL=amarillo, SB=morado, NW=dorado, SM=cian, GS=verde lima.
- Fuente de 16px para legibilidad en móvil.
- Al llegar a count=0 la pastilla desaparece; al reiniciar la sesión se limpian todas.

## Controles — Drag con ancla ✅
- El jugador NO salta al tocar la pantalla.
- `InputEventScreenTouch` (pressed) registra `_drag_anchor_x` (posición X del dedo) y `_drag_anchor_player_x` (posición X del jugador en ese momento).
- `InputEventScreenDrag` aplica: `_target_x = _drag_anchor_player_x + (drag.position.x - _drag_anchor_x) × PLAYER_SWIPE_SENSITIVITY`.
- El jugador se mueve proporcionalmente a cuánto se desplaza el dedo desde donde aterrizó, sin ningún salto inicial.
- Valor por defecto: `PLAYER_SWIPE_SENSITIVITY = 1.0` en `Constants.gd`.
- El mouse (editor) sigue siendo absoluto para no romper el flujo de pruebas en desktop.

## Láser Jalapeño — sigue al jugador ✅
- En versiones anteriores el láser se fijaba en la columna donde se activó.
- Ahora la posición X del láser se actualiza en cada frame siguiendo al jugador.

## Escudo Nacho Wall — indicador visual ✅
- Cuando el jugador tiene escudo activo, aparece un **anillo amarillo** (Line2D) alrededor del personaje.
- Desaparece automáticamente cuando `_shield_hits` llega a 0.

## Granada Mole — explosión más visible ✅
- Antes: solo un `ColorRect` semitransparente.
- Ahora: **anillo Line2D naranja** + flash interior con fade animado (tween).

## Barra de HP del jefe ✅
- `EnemyBoss.gd` guarda `_max_health` en `_initialize()` y emite `EventBus.boss_health_changed(current, maximum)` en cada `take_damage()`.
- `HUD.gd` tiene `_boss_hp_bar: ProgressBar` (ProgressBar roja, top-center, offset_left=-90/right=90, top=52/bottom=68).
- La barra es visible solo mientras el jefe está vivo: muestra en `boss_health_changed`, oculta en `boss_defeated` y `game_started`.

## Auto-pausa al perder el foco ✅
- `Game.gd` implementa `_notification(what: int)`: si `NOTIFICATION_APPLICATION_FOCUS_OUT` y estado es PLAYING → `GameManager.pause_game()`.
- Al volver al foco el usuario debe reanudar manualmente con CONTINUAR (intencional).

## Botón REINICIAR en PauseScreen ✅
- Botón entre CONTINUAR y MENU PRINCIPAL en la pantalla de pausa.
- `_on_restart_pressed()`: `GameManager.resume_game()` + `EventBus.restart_requested.emit()`.
- Panel expandido de 220px → 260px de alto para acomodar el tercer botón.

## Oro por corazones conservados ✅
- Al ganar, se recibe **25 oro adicional por cada corazón restante**.
- Constante: `GOLD_PER_HEART_KEPT = 25` en `Constants.gd`.

## Contador de victorias separado ✅
- `SaveManager` guarda `victories` independientemente de `total_sessions`.
- `total_sessions` sigue contando todas las partidas (victorias + derrotas).
- La **paleta de fondo** rota por victorias (`victories % 6`, seis biomas), no por sesiones totales.
- Al perder se mantiene el mismo bioma; al ganar avanza al siguiente.

## Corazones que caen durante la partida ✅
- Cada 45 segundos cae un corazón (♥ rojo) desde arriba en posición X aleatoria.
- El jugador lo recoge tocándolo; suma +1 HP hasta el máximo. Si está lleno de vida, el corazón se ignora sin efecto.
- Independiente del sistema de gemas y power-ups.
- Constantes: `HEART_DROP_INTERVAL = 45.0`, `HEART_DROP_SPEED = 80.0` en `Constants.gd`.
- Señal: `EventBus.heart_collected()`. Escuchada por `Player._on_heart_collected()`.
- Archivos: `HeartDrop.gd`, `HeartDrop.tscn`, `HeartDropper.gd` en `src/features/player/`.

## Láser Jalapeño — daña al moverse ✅
- Antes usaba `Area2D.get_overlapping_bodies()` que no actualizaba en movimiento.
- Ahora: en cada tick, itera los enemigos del grupo y compara `absf(enemy.x - laser.x) <= 7px`.
- El láser sigue dañando correctamente a todo enemigo que esté dentro de la columna mientras se mueve.

## XP y costo de triadas de power-ups ✅
- `XP_BASE_REQUIRED`: 60 → 40 → 120 → **150** (ajustes sucesivos para balancear dificultad)
- `XP_SCALE_FACTOR`: 1.3 → **1.2**
- `ENEMY_BASIC_XP`: 5 → **8**, `ENEMY_ZIGZAG_XP`: 10 → **15**, `ENEMY_TANK_XP`: 20 → **35**
- Primera triada requiere matar ~19 enemigos básicos (150/8 ≈ 18.75).
- Combinaciones de hasta 5 power-ups simultáneos son alcanzables con 45s de duración.

## Duración de power-ups: 30s → 45s ✅
- `POWERUP_DURATION` en `Constants.gd` = `45.0` (valor actual; fue 30s originalmente).

## Paleta de biomas — colores claramente distintos ✅
- Los colores anteriores eran todos prácticamente negros (0.04–0.13), visualmente indistinguibles.
- Colores actualizados a valores más saturados y visibles: verde, índigo, rojo volcánico, azul océano, rojo sangre.
- HUD agrega un `Label` "BIOMA X" centrado en pantalla al inicio de cada partida que hace fade-out en 2.6s.
- El índice del bioma es `SaveManager.get_victories() % 5` (0-based internamente, se muestra 1-based).

## Rapid Fire — multiplicador subido a ×2 ✅
- Antes: ×1.25 de cadencia por stack.
- Ahora: ×2.0 por stack (apilable: 2 stacks = ×4, 3 stacks = ×8, mínimo 0.05s).

## Backgrounds generados — 6 biomas × 3 variantes ✅
- **18 imágenes** `bg_{bioma}_{variante}.png` (390×844 px) AI-generadas con Pollinations.ai (Flux, gratis).
- Selector en `Game.gd`: `biome = victories % palette.size()`, `variant = (victories / palette.size()) % 3`, `gen = victories / (palette.size() * 3)`.
- **Tint por generación** (`_get_gen_tint()`): gen 0 neutro, gen 1 frío/azulado, gen 2 cálido/rojizo, gen 3+ violáceo.
- Efecto: el jugador ve 18 fondos distintos antes de repetir, con variación de tono indefinida por generación.
- Biomas (de más amigable a más oscuro): 0=Pradera Guacamole (tierra soleada), 1=Jungla Nocturna, 2=Crepúsculo Índigo, 3=Caldera Volcánica, 4=Abismo Oceánico, 5=Desierto de Luna Sangre.
- Diseño intencional: primer mundo brillante/feliz para onboarding; oscuridad crece con dificultad.
- La textura se carga como `Sprite2D` (Node2D) centrado en viewport; posición world-space float → sin pixel-snapping. Fallback al color de `BACKGROUND_PALETTE` si no existe PNG.
- Pipeline de regeneración: `tools/fetch_ai_assets.py` (secuencial, 1 req a la vez, venv Pillow).

## Escalado 2× de todos los elementos de gameplay ✅
- Sprites generados nativamente al doble de resolución en `gen_assets.py` (sin escalar en Godot — `scale = Vector2(1,1)` en todos los Sprite2D).
- Formas de colisión duplicadas para mantener la proporción hitbox/visual.
- **Elementos escalados:**
  | Elemento | PNG actual | Colisión |
  |---|---|---|
  | Player | 64×64 | Cápsula r=30, h=60 |
  | EnemyBasic | 56×56 | Círculo r=24 |
  | EnemyTank | 84×84 | Círculo r=48 |
  | EnemyZigzag | 52×52 | Cápsula r=16, h=40 |
  | EnemyBoss | 144×144 | Círculo r=80 |
  | Projectile | 28×28 | Círculo r=12 |
  | XPGem | 36×36 | Círculo r=20 |
  | HeartDrop | 52×52 | Círculo r=28 |
  | PowerUpDrop | 64×64 | Rect 64×64 |
  | PowerUpIcons | 64×64 | — |
- `Player.HALF_WIDTH = 35` previene salida de pantalla.
- Shield ring (Nacho Wall): radio 56. ProjectileSpawnPoint: y=-56.

## PowerUpDropper — batches independientes ✅
- Cada triada de power-ups es un **batch independiente** con `batch_id: int` único.
- Al recoger un drop, solo se eliminan los otros dos de **su misma triada** (vía señal `powerup_batch_cleared(batch_id)`).
- Múltiples triadas pueden coexistir en pantalla: cada una se resuelve por separado.
- Drops de élite tienen `batch_id = -1` → se recogen individualmente sin limpiar nada más.
- `PowerUpDropper._batches: Dictionary` mapea `batch_id → Array[Area2D]`.
- Señal nueva en EventBus: `powerup_batch_cleared(batch_id: int)`.

## Boss HP escalado por victorias ✅
- **Bug corregido:** `_boss_generation` en EnemySpawner se reseteaba a 0 en cada sesión → el jefe siempre tenía HP base (100).
- **Fix:** `boss.set(&"_generation", SaveManager.get_victories())` — el HP del jefe escala con el progreso real del jugador.
- Fórmula: `HP = BOSS_HP_BASE + victories × BOSS_HP_PER_GENERATION` = 100 + victorias×50.
- Victoria 0: 100 HP | Victoria 3: 250 HP | Victoria 10: 600 HP.

## Enemigo Élite ✅
- Variante dorada del EnemyBasic. Aparece a partir de los 45s con 8% de probabilidad.
- **HP:** 3× básico (3 HP). **XP:** 5× básico (40 XP).
- **Visual:** modulate = Color(1.0, 0.85, 0.15) — tinte dorado. Sprite propio: `enemy_elite.png` (56×56).
- **Al morir:** emite `elite_powerup_dropped(position, powerup_id)` con un ID aleatorio de `Constants.POWERUP_POOL`.
- `PowerUpDropper` escucha la señal y spawnea un `PowerUpDrop` en la posición de muerte → el jugador lo recoge tocándolo.
- Archivos: `EnemyElite.gd`, `EnemyElite.tscn`. Wired en `Game.tscn → EnemySpawner.elite_scene`.
- Constantes: `ENEMY_ELITE_HP_MULTIPLIER=3`, `ENEMY_ELITE_XP_MULTIPLIER=5`, `SPAWNER_ELITE_UNLOCK_TIME=45s`, `SPAWNER_ELITE_CHANCE=0.08`.

## Boss Fase 2 ✅
- Al llegar al 50% de HP, el jefe entra en **Fase 2**:
  - `modulate = Color(1.0, 0.3, 0.3)` — tinte rojo.
  - Velocidad ×1.8 (`BOSS_PHASE2_SPEED_MULT`).
  - Intervalo de disparo ×0.5 (el doble de rápido).
  - Disparo en abanico: 3 proyectiles a ±20° apuntando al jugador (`BOSS_PHASE2_SPREAD_COUNT=3`, `BOSS_PHASE2_SPREAD_ANGLE=20°`).
- Emite `boss_phase_changed(2)` en EventBus al transicionar.
- `BossProjectile` actualizado: `_velocity: Vector2` reemplaza el movimiento hardcodeado; soporte de off-screen en los 4 bordes.
- La fase 2 NO se activa si el golpe letal lleva al boss directo a 0 HP.

## Boss Fase 2 HUD Feedback ✅
- `HUD.gd` conecta `boss_phase_changed` y muestra label "¡FASE 2!" centrado en pantalla.
- Label aparece en rojo (38px) con tween de 1.2s pausa + 0.6s fade-out.
- Se construye en `_build_phase2_label()` durante `_build_ui()`.

## HapticManager — Hápticos orientados a eventos ✅
- Nuevo autoload: `src/features/audio/HapticManager.gd`.
- Conecta eventos faltantes: `player_damaged` (80ms), `powerup_selected` (20ms), `boss_phase_changed` (120ms), `heart_collected` (20ms).
- `AudioManager` mantiene hápticos de disparo (`trigger_haptic_light`) y jefe derrotado (`trigger_haptic_heavy`).
- Toda vibración respeta `SaveManager.get_vibration_enabled()`.

## Logros Persistentes ✅
- Nuevo autoload: `src/features/meta/AchievementManager.gd`.
- 10 logros definidos en `Constants.ACHIEVEMENTS` (Array de Dicts con id, name, desc).
- Persistencia en `SaveManager._data["achievements"]` — dict `{id: true}`.
- Métodos: `SaveManager.has_achievement(id)`, `unlock_achievement(id)`.
- Señal: `EventBus.achievement_unlocked(achievement_id)`.
- Nueva pantalla: `src/scenes/AchievementsScreen.gd/.tscn` — muestra ★/☆ con estado.
- Accesible desde MainMenu → botón LOGROS.
- Tests: `tests/unit/test_achievement_manager.gd` (12 pruebas).

| ID | Condición |
|---|---|
| first_victory | 1 victoria |
| five_victories | 5 victorias |
| boss_slayer | Derrota al jefe |
| level_10 | Nivel 10 en partida |
| gold_500 | 500 oro disponible |
| power_hoarder | 50 power-ups lifetime |
| veteran | 25 sesiones |
| massacre | 100 kills en partida |
| survivor_90 | 90s sobrevivido |
| max_upgrade | Mejora permanente al máximo |

## Misiones Diarias ✅
- Nuevo autoload: `src/features/meta/DailyMissionsManager.gd`.
- 3 misiones diarias generadas deterministamente desde la fecha local (hash del string "YYYY-MM-DD").
- Pool de 9 tipos de misión en `Constants.DAILY_MISSION_POOL`; sin repetidos en el mismo día.
- Progreso acumulativo durante el día; resetea automáticamente al cambiar de fecha.
- Persistencia en `SaveManager._data["daily_missions"]`.
- Señales: `EventBus.mission_completed(id, reward)`, `mission_progress(id, current, target)`.
- Recompensa: oro emitido vía `EventBus.gold_earned(reward)` al completar.
- Nueva pantalla: `src/scenes/DailyMissionsScreen.gd/.tscn` — cards con barra de progreso.
- Accesible desde MainMenu → botón MISIONES DIARIAS.
- Tests: `tests/unit/test_daily_missions.gd` (11 pruebas).

## Sistema de Personajes ✅
- **8 personajes** definidos en `Constants.CHARACTERS` (Array de Dicts con id, name, desc, hp_bonus, fire_rate_mult, damage_mult, cost, fire_mode, sprite_tint, bullet_tint, bullet_scale).
- Campo `fire_mode` determina el patrón de disparo: `&"normal"`, `&"double"`, `&"fan3"`, `&"fan5"`, `&"heavy"`.
- Cada personaje tiene sprite propio en `assets/sprites/characters/player_{id}.png`.
- Selección persistida en `SaveManager._data["selected_character"]` (default: "guac").
- Desbloqueo en `SaveManager._data["unlocked_characters"]` (guac siempre disponible).
- Player aplica modificadores en `_on_game_started()` después de los upgrades de meta.
- `CharacterSelectScreen.gd/.tscn` — cards con stats, fire_mode, tinte y botones ELEGIR/COMPRAR.
- Accesible desde MainMenu → botón PERSONAJE.

| ID | Nombre | Costo | Efecto |
|---|---|---|---|
| guac | Guacamole | Gratis | Base (normal) |
| habanero | Habanero | 200 | Fire rate ×1.25, -1 corazón (normal) |
| serrano | Serrano | 300 | Daño ×1.15, +1 corazón, fire rate ×0.8 (normal) |
| doble_guac | Doble Guac | 450 | 2 balas simultáneas (double) |
| veloz | Jalapeño Veloz | 600 | Fire rate ×1.7, daño -25%, balas pequeñas (normal) |
| tornado | Tornado Verde | 750 | 3 balas en abanico ±25°, fire rate ×0.75 (fan3) |
| aplastador | Mole Aplastador | 1000 | Daño ×2, balas grandes, +1 corazón, fire rate ×0.6 (heavy) |
| gran_abanico | Gran Abanico | 1400 | 5 balas en abanico ±40°, fire rate ×0.5 (fan5) |

## Mapa de Biomas ✅
- Nueva pantalla: `src/scenes/BiomeMapScreen.gd/.tscn`.
- Muestra los 6 biomas con swatch de color, nombre, estado lock/unlock.
- Bioma desbloqueado si `victories > idx` (bioma 0 siempre disponible).
- Indica bioma actual (`victories % Constants.BACKGROUND_PALETTE.size()`).
- Accesible desde MainMenu → botón MAPA.

## Toast de Personaje Seleccionado ✅
- `CharacterSelectScreen`: capa `_toast_layer: CanvasLayer` (layer=20) persiste a través de `_rebuild()`.
- Muestra "✓ [Name] seleccionado" (verde) o "✓ [Name] desbloqueado" (dorado) al interactuar.
- `HUD._on_game_started()` llama `_show_character_toast()` que encola "Jugando como: [name]" en el sistema de toasts del HUD.

## Desafío Semanal ✅
- **`WeeklyChallengeManager.gd`** — nuevo autoload que expone getters de multiplicadores:
  - `get_spawn_rate_mult()`, `get_elite_chance_mult()`, `get_boss_hp_mult()`, `get_gold_mult()`, `is_heart_drops_disabled()`
  - Retorna valores neutros (1.0 / false) cuando no hay desafío activo → los sistemas de juego multiplican sin if/else.
  - `activate_challenge()` lee el desafío de la semana actual (`week_number % 3`).
  - Al ganar con desafío activo: emite `weekly_challenge_completed`, marca la semana en SaveManager, resetea estado.
  - `game_over` y `menu_requested` también resetean `_is_active`.
- **`WeeklyChallengeScreen.gd/.tscn`** — pantalla con nombre, descripción, multiplicador de oro y estado "✓ COMPLETADO ESTA SEMANA".
- **Integración de juego**: `GameManager._calc_gold()` multiplica por `get_gold_mult()`; `EnemySpawner._update_difficulty()` aplica `spawn_rate_mult`; `_pick_scene()` aplica `elite_chance_mult`; `EnemyBoss._initialize()` aplica `boss_hp_mult`; `HeartDropper._on_game_started()` respeta `is_heart_drops_disabled()`.
- **`EnemySpawner._on_game_started()`** — convertido de lambda a método; ahora también resetea `_elapsed`, timers y carga multiplicadores de desafío.
- Pool de 3 desafíos en `Constants.WEEKLY_CHALLENGE_POOL`: Horda Masiva (×2 oro), Lluvia Élite (×2.5 oro), Supervivencia Pura (×1.5 oro).
- **HUD** conectado a `weekly_challenge_completed` → toast morado "★ DESAFÍO SEMANAL COMPLETADO".
- 17 tests en `test_weekly_challenge.gd`.

---

# Pendientes — Solo Código

## Settings Screen ✅ (completado)

## Misiones Diarias ✅ (completado)

## Logros ✅ (completado)

## Sistema de Personajes ✅ (completado)

## Mapa de Biomas ✅ (completado)

## HapticManager ✅ (completado)

## Cuentas de usuario
- Login con Facebook / Google / cuenta propia de Guacamole Bit.
- Requiere SDK externo: GodotFacebook, GodotGameServices, o backend REST propio.
- No implementable sin integración de plataforma externa.
- Impacto esperado: sync de progreso entre dispositivos, rankings, misiones sociales.

## Export Release (Android y iOS)
- Build actual es **debug**. Para publicar en tiendas se necesita:
  - **Android**: keystore firmado → agregarlo como secret en GitHub Actions.
  - **iOS**: Apple Developer account, provisioning profile, xcodeproj export.
- La lógica del workflow ya está lista; solo falta la configuración de firma.

---

## Sprites y SFX placeholder ✅
- **`tools/gen_assets.py`** — script Python stdlib que genera todos los assets sin dependencias externas.
- **8 sprites PNG**: player (64×64), enemy_basic (56×56), enemy_tank (84×84), enemy_zigzag (52×52), enemy_boss (144×144), projectile (28×28), gem (36×36), heart (52×52).
- **9 íconos de power-up** (64×64) en `assets/sprites/powerup_icons/` — uno por ID, con diseño único por tipo.
- **7 archivos WAV** en `assets/audio/`: shoot, enemy_die, player_hit, gem_collect, levelup, boss_die, music_loop.
- Escenas .tscn actualizadas: Sprite2D reemplaza Polygon2D en Player, EnemyBasic, EnemyTank, EnemyZigzag, EnemyBoss, Projectile.
- XPGem.gd, HeartDrop.gd y PowerUpDrop.gd cargan sprite si existe, con fallback a forma geométrica.
- AudioManager carga los WAVs automáticamente, conecta todos los eventos del juego, reproduce música en loop.
- Para sustituir por arte final: reemplazar los PNG/WAV en las mismas rutas y volver a importar con `godot --headless -e --quit`.

# Assets con IA ✅

## Fondos de bioma — AI-generated (Pollinations.ai Flux)
- 18 imágenes 390×844 px: `bg_{0-5}_{0-2}.png` (6 biomas × 3 variantes)
- Diseño progresivo: bioma 0 tierra soleada/amigable → bioma 5 desierto luna de sangre/final
- Biomas: 0=Pradera (seeds 500-502), 1=Jungla oscura (7-81), 2=Índigo (107-181), 3=Volcánico (207-281), 4=Oceánico (307-381), 5=Luna Sangre (407-481)
- Herramienta: `tools/fetch_ai_assets.py` (requiere venv con Pillow)

## Sprites principales — AI-generated (Pollinations.ai Flux)
- player.png (64×64), enemy_basic.png (56×56), enemy_tank.png (84×84), enemy_zigzag.png (112×112)
- enemy_elite.png (56×56), enemy_boss.png (144×144), projectile.png (28×28), gem.png (36×36), heart.png (52×52)
- Descargados con prompts de "pixel art ... white background isolated", chroma key para transparencia
- enemy_elite.tscn corregida para usar enemy_elite.png (antes usaba enemy_basic.png por error)

## Íconos de power-up — mejorados (procedural)
- 9 íconos 64×64 en `assets/sprites/powerup_icons/`
- Rediseñados en gen_assets.py con más detalle: flechas propias, relámpago, bomba con fusible, láser con corona, etc.

## Pipeline
```bash
# Regenerar assets AI (backgrounds + sprites, ~25 min, Pollinations.ai free)
/tmp/gb_venv/bin/python3 tools/fetch_ai_assets.py
# Solo biomas 0-1 si fueron sobrescritos
/tmp/gb_venv/bin/python3 tools/redownload_missing_bgs.py
# Regenerar procedurales (íconos, splash, audio)
python3 tools/gen_assets.py
```

## Audio (pendiente de mejora)
- 7 WAVs sintéticos en `assets/audio/` — funcional pero básico
- Para mejor calidad: reemplazar con OGG de banco libre (freesound.org, kenney.nl)

---

# Features — Sesión 4+ (2026-07-13)

## Modificadores de Bioma ✅
- 6 biomas (en lugar de 5) definidos en `Constants.BACKGROUND_PALETTE`.
- `GameManager` guarda `_current_biome = victories % 6` al inicio de partida y expone getters:
  - `get_biome_spawn_mult()`, `get_biome_speed_mult()`, `get_biome_elite_mult()`, `get_biome_boss_hp_mult()`, `get_biome_gold_mult()`
- Arrays en `Constants.gd` (índice = bioma):
  - `BIOME_SPAWN_MULT` — factor de intervalo de spawn (< 1.0 = más rápido)
  - `BIOME_ELITE_MULT` — multiplicador de probabilidad de élite
  - `BIOME_BOSS_HP_MULT` — multiplicador de HP del jefe
  - `BIOME_SPEED_MULT` — multiplicador de velocidad de enemigos
  - `BIOME_GOLD_MULT` — multiplicador de oro ganado
- `EnemySpawner` lee los multiplicadores de bioma en `_on_game_started()` junto con los del desafío semanal.
- `GameManager._calc_gold()` multiplica por `get_biome_gold_mult()`.

## Combo System ✅
- `GameManager` mantiene `_combo_kills: int` que se incrementa en cada `enemy_destroyed`.
- Al recibir daño, el combo se resetea a 0.
- `get_combo_multiplier() → float`: 5 kills=×1.5, 10=×2.0, 20=×3.0, 30=×5.0.
- Emite `EventBus.combo_changed(kills, multiplier)` al cambiar nivel o al resetear.
- HUD muestra el combo activo en pantalla cuando está activo.

## Modo Sin Fin (Endless Mode) ✅
- `GameManager.enable_endless_mode(true)` desactiva la condición de victoria por jefe.
- En modo endless, el jefe muere pero la partida continúa indefinidamente.
- Accesible desde MainMenu (opción separada o contexto específico).
- `get_endless_mode() → bool` permite que HUD/otros sistemas adapten su comportamiento.

## Pantalla de Mejores Puntuaciones ✅
- `src/scenes/HighScoresScreen.gd/.tscn` — tabla top-10 de puntuaciones.
- Muestra score, resultado (ganó/perdió), oro obtenido y fecha de cada entrada.
- Accesible desde MainMenu → botón PUNTUACIONES.
- Datos persistidos en `SaveManager` (array de entradas con score, won, gold, date).

## Animación del Menú Principal ✅
- `_build_animated_bg()`: fondo animado con CPUParticles2D y efectos de color en MainMenu.
- `_animate_title()`: título "GUACBLASTER" hace loop de escala 1.0 ↔ 1.04 (Tween 1.4s cada dirección).
- `_run_entrance_animation()`: botones del menú aparecen en secuencia con fade-in escalonado (0.25s por botón).

## Dificultad Escalable ✅
- `EnemySpawner._update_difficulty()` reduce el intervalo de spawn progresivamente:
  - Inicial: `SPAWNER_INITIAL_INTERVAL = 0.8s`
  - Mínimo: `SPAWNER_MIN_INTERVAL = 0.2s`
  - Reducción: `SPAWNER_INTERVAL_DECREASE_PER_MIN = 0.1s/min`
- Enemigo Tanque desbloquea a los 60s, Zigzag a los 30s.
- Élites aplican multiplicador combinado: `SPAWNER_ELITE_CHANCE × challenge_elite_mult × biome_elite_mult`.
- Los modificadores de bioma y desafío semanal se apilan con la dificultad base.

## Animación del Fondo en Partida ✅
- `Game.gd` implementa tres efectos simultáneos:
  1. **Parallax scroll**: `Sprite2D` (no TextureRect — evita pixel-snapping) se mueve con `sin(time × speed) × amplitude` en X e Y independientemente. Constantes: `BG_SCROLL_X=22px`, `BG_SCROLL_Y=18px`, `BG_SPEED_X=0.11`, `BG_SPEED_Y=0.08`.
  2. **Tinte pulsante**: `_background` (ColorRect) oscila entre color base y `lightened(0.10)` cada `BG_PULSE_SPEED=0.35` rad/s.
  3. **Partículas ambiente**: `CPUParticles2D` (20 partículas, lifetime 9s) ascienden lentamente desde el borde inferior. Color por bioma definido en `_get_biome_particle_color()` (array lookup, no match — evita `max-returns` gdlint).
- La escala del Sprite2D incluye margen de `BG_SCROLL_X*2/vp.x` para que nunca aparezcan bordes en el scroll.

## Botón VOLVER Homologado en 8 Pantallas ✅
- Todas las pantallas secundarias (AchievementsScreen, BiomeMapScreen, CharacterSelectScreen, DailyMissionsScreen, HighScoresScreen, SettingsScreen, UpgradeScreen, WeeklyChallengeScreen) usan el patrón idéntico:
  - `Button` 160×44 px, `SIZE_SHRINK_CENTER`.
  - `HBoxContainer` con `IconPainter(icon_id=&"back")` (20×20) + `Label(" VOLVER", 17px)`.
  - `_notification(NOTIFICATION_WM_GO_BACK_REQUEST)` → `_on_back_pressed()`.
- `IconPainter._draw_back()`: polígono de 7 puntos formando flecha izquierda con eje rectangular (procedural en `_draw()`).

## Manejo del Botón Sistema "Volver Atrás" ✅
- `project.godot`: `config/quit_on_go_back=false` → Godot no cierra la app automáticamente.
- Todos los nodos reciben `NOTIFICATION_WM_GO_BACK_REQUEST` vía `propagate_notification` independientemente de `process_mode`.
- **En pantallas secundarias**: `_notification` llama `_on_back_pressed()` → cambia a `MainMenu.tscn`.
- **Mientras se juega**: `Game.gd._notification` detecta `state == PLAYING` → `GameManager.pause_game()`. `PauseScreen._notification` detecta `visible` → cierra confirm panel si estaba abierto, o reanuda si no.
- **En MainMenu**: `_notification` muestra/oculta `_exit_confirm` (CanvasLayer layer=50 con overlay oscuro + card "¿Salir del juego?" + botones CANCELAR/SALIR).
- Guards de estado evitan doble-acción cuando múltiples nodos reciben la misma notificación.

## Curva de Dificultad Progresiva ✅
- **Problema:** jugadores nuevos encontraban zigzag (30s), élites (45s) y tanks (60s) antes de tener suficientes power-ups para manejarlos.
- **Solución:** `EnemySpawner` ahora escucha `EventBus.player_level_up` y usa `_player_level` como segunda compuerta:
  - Zigzag: tiempo ≥ 30s **AND** nivel ≥ 1 (primera tercia de power-ups)
  - Tank: tiempo ≥ 60s **AND** nivel ≥ 2 (segunda tercia de power-ups)
  - Élite: tiempo ≥ 45s **AND** nivel ≥ 2
- `_player_level` se reinicia a 0 en cada partida (en `_on_game_started`).
- La señal `player_level_up(new_level: int)` ya existía en EventBus — solo se añadió el listener en EnemySpawner.

## Fix: Contador de Corazones en Android ✅
- **Bug:** los corazones del HUD no actualizaban su color al perder o ganar vidas en Android (GL Compatibility renderer).
- **Causa:** `lbl.label_settings.font_color = color` modifica un `Resource`, cuya propagación de cambios no fuerza redibujado en el renderer GL de Android.
- **Fix:** eliminado `LabelSettings` de las etiquetas de corazón. Se usa `add_theme_font_size_override` + `add_theme_color_override("font_color", color)` para tamaño y color respectivamente. `add_theme_color_override` marca el nodo directamente como sucio, garantizando redibujado en todas las plataformas.
- **Archivos:** `HUD._make_heart_label()` y `HUD._on_player_health_changed()`.
