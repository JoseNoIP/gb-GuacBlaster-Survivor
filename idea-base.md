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
| **TS** | Disparo Triple | +2 disparos diagonales | 30s por stack |
| **SG** | Súper-Guac | Proyectiles penetran 3 enemigos | 30s por stack |
| **RF** | Fuego Rápido | Cadencia ×2 por stack | 30s por stack |
| **MG** | Granada Mole | AoE automático cada 5s | 30s por stack |
| **JL** | Láser Jalapeño | Rayo de columna que sigue al jugador | 2s por stack |
| **SB** | Rebote Picante | Proyectiles rebotan en bordes | 30s por stack |
| **NW** | Muro Nachos | Escudo: absorbe 3 impactos por stack | 30s por stack |
| **SM** | Imán Salsa | Gemas vuelan hacia el jugador | 30s por stack |
| **GS** | Salvo Guac | +1 columna de disparos por stack (a ±40×N px del centro) | 30s por stack |

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
- `SaveManager` ahora guarda `victories` independientemente de `total_sessions`.
- `total_sessions` sigue contando todas las partidas (victorias + derrotas).
- La **paleta de fondo** rota por victorias (`victories % 5`), no por sesiones totales.
- Al perder se siente el mismo fondo; al ganar avanza al siguiente bioma.

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

## XP más rápido para combinaciones ✅
- `XP_BASE_REQUIRED`: 60 → **40**
- `XP_SCALE_FACTOR`: 1.3 → **1.2**
- `ENEMY_BASIC_XP`: 5 → **8**, `ENEMY_ZIGZAG_XP`: 10 → **15**, `ENEMY_TANK_XP`: 20 → **35**
- Combinaciones de hasta 5 power-ups simultáneos son alcanzables (~23s para 5 level-ups, 7s de ventana antes de que expire el primero).

## Duración de power-ups: 30s → 45s ✅
- `POWERUP_DURATION` en `Constants.gd` cambiado de `30.0` a `45.0`.

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
- La textura se carga como `TextureRect` hijo del `$Background` ColorRect; si no existe PNG usa el color de `BACKGROUND_PALETTE` como fallback.
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
- 3 personajes definidos en `Constants.CHARACTERS` (Array de Dicts con id, name, desc, hp_bonus, fire_rate_mult, damage_mult, cost).
- Selección persistida en `SaveManager._data["selected_character"]` (default: "guac").
- Desbloqueo en `SaveManager._data["unlocked_characters"]` (guac siempre disponible).
- Métodos: `SaveManager.get_selected_character()`, `set_selected_character(id)`, `is_character_unlocked(id)`, `unlock_character(id, cost)`.
- Player aplica modificadores en `_on_game_started()` después de los upgrades de meta.
- Nueva pantalla: `src/scenes/CharacterSelectScreen.gd/.tscn` — cards con stats y botones ELEGIR/desbloquear.
- Accesible desde MainMenu → botón PERSONAJE.

| ID | Nombre | Costo | Efecto |
|---|---|---|---|
| guac | Guacamole | Gratis | Base (sin modificadores) |
| habanero | Habanero | 200 oro | Fire rate ×1.25, -1 corazón |
| serrano | Serrano | 300 oro | Daño ×1.15, +1 corazón, fire rate ×0.8 |

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
