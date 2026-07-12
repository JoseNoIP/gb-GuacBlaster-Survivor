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

---

# Pendientes — Solo Código

## Settings Screen ✅ (completado)

## Cuentas de usuario
- Login con Facebook / Google / cuenta propia de Guacamole Bit.
- Requiere SDK externo: GodotFacebook, GodotGameServices, o backend REST propio.
- No implementable sin integración de plataforma externa.
- Impacto esperado: sync de progreso entre dispositivos, rankings, misiones sociales.

## Misiones diarias
- Objetivos por sesión que otorgan oro extra (ej. "Mata 20 básicas", "Sobrevive 60 segundos").
- Requiere: sistema de tracking de eventos, persistencia de estado de misiones en `SaveManager`, UI de misiones.

## Export Release (Android y iOS)
- Build actual es **debug**. Para publicar en tiendas se necesita:
  - **Android**: keystore firmado → agregarlo como secret en GitHub Actions.
  - **iOS**: Apple Developer account, provisioning profile, xcodeproj export.
- La lógica del workflow ya está lista; solo falta la configuración de firma.

---

# Assets Externos Pendientes

## Backgrounds por ronda
La lógica ya está implementada: cada victoria avanza `SaveManager.get_victories() % 5`
y aplica un color de `Constants.BACKGROUND_PALETTE`. Para reemplazar colores por imágenes:

- Crear 5 imágenes de fondo (390×844 px, pixel art) para los biomas:
  1. Jungla oscura (default) — `bg_0.png`
  2. Crepúsculo / índigo — `bg_1.png`
  3. Volcánico / brasa — `bg_2.png`
  4. Abismo / océano profundo — `bg_3.png`
  5. Luna de sangre / desierto nocturno — `bg_4.png`
- Colocar en `assets/sprites/backgrounds/`
- En `Game.gd._ready()`, reemplazar `_background.color = ...` por:
  ```gdscript
  var tex := load("res://assets/sprites/backgrounds/bg_%d.png" % palette_index) as Texture2D
  _background.texture = tex  # cambiar ColorRect → TextureRect en Game.tscn
  ```

## SFX / Música
`AudioManager` autoload existe en `src/features/audio/AudioManager.gd`.
Archivos necesarios en `assets/audio/`:
- `shoot.ogg` — disparo del jugador
- `enemy_die.ogg` — muerte de enemigo básico
- `boss_die.ogg` — derrota del jefe
- `player_hit.ogg` — daño al jugador
- `levelup.ogg` — subida de nivel
- `gem_collect.ogg` — recolección de gema
- `music_loop.ogg` — loop de música de fondo

## Sprites
Placeholders actuales son `ColorRect` y `CharacterBody2D` sin textura.
Archivos necesarios en `assets/sprites/`:
- `player.png` (32×32 px)
- `enemy_basic.png`, `enemy_tank.png`, `enemy_zigzag.png`, `enemy_boss.png`
- `projectile.png`, `gem.png`
- `powerup_icons/` — 9 íconos (32×32 px), uno por power-up:
  `ts.png`, `sg.png`, `rf.png`, `mg.png`, `jl.png`, `sb.png`, `nw.png`, `sm.png`, `gs.png`
