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

### Notas
- `export_presets.cfg` está en el repo (debug build, sin claves de producción).
- Para release build necesitarás un keystore firmado y agregarlo como secret.

---

# Mejoras Implementadas

## Sistema de Power-ups temporal y stackable ✅
- Cada pick-up agrega un stack con timer de **15 segundos** independiente.
- Al expirar un stack, los efectos se reducen automáticamente (o desaparecen si era el último).
- Se pueden acumular múltiples stacks del mismo power-up.
- Al subir de nivel caen **3 items físicos** desde arriba de la pantalla (PowerUpDrop).
  El jugador toca el que quiere recoger; al tocarlo, los otros 2 desaparecen.
- El juego **no se pausa** durante la selección de power-ups.

### Power-ups activos (9 en total)
| Iniciales | Nombre | Efecto | Duración |
|---|---|---|---|
| **TS** | Disparo Triple | +2 disparos diagonales | 15s por stack |
| **SG** | Súper-Guac | Proyectiles penetran 3 enemigos | 15s por stack |
| **RF** | Fuego Rápido | Cadencia ×2 por stack | 15s por stack |
| **MG** | Granada Mole | AoE automático cada 5s | 15s por stack |
| **JL** | Láser Jalapeño | Rayo de columna que sigue al jugador | 2s por stack |
| **SB** | Rebote Picante | Proyectiles rebotan en bordes | 15s por stack |
| **NW** | Muro Nachos | Escudo: absorbe 3 impactos por stack | 15s por stack |
| **SM** | Imán Salsa | Gemas vuelan hacia el jugador | 15s por stack |
| **GS** | Salvo Guac | +1 columna de disparos por stack (a ±40×N px del centro) | 15s por stack |

### Tira de power-ups activos en HUD
Aparece en la parte inferior izquierda mientras hay efectos activos, ejemplo: `RF×2  TS×1  GS×3`

## Controles — Drag relativo ✅
- El jugador ya no salta al punto exacto del dedo.
- Se mueve proporcionalmente al desplazamiento del dedo (`event.relative.x × PLAYER_SWIPE_SENSITIVITY`).
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

## Oro por corazones conservados ✅
- Al ganar, se recibe **25 oro adicional por cada corazón restante**.
- Constante: `GOLD_PER_HEART_KEPT = 25` en `Constants.gd`.

## Contador de victorias separado ✅
- `SaveManager` ahora guarda `victories` independientemente de `total_sessions`.
- `total_sessions` sigue contando todas las partidas (victorias + derrotas).
- La **paleta de fondo** rota por victorias (`victories % 5`), no por sesiones totales.
- Al perder se siente el mismo fondo; al ganar avanza al siguiente bioma.

## Rapid Fire — multiplicador subido a ×2 ✅
- Antes: ×1.25 de cadencia por stack.
- Ahora: ×2.0 por stack (apilable: 2 stacks = ×4, 3 stacks = ×8, mínimo 0.05s).

---

# Pendientes — Solo Código

## Settings Screen
- Pantalla accesible desde el menú principal con:
  - Sonido on/off
  - Vibración on/off
  - Sensibilidad del swipe (slider que modifica `PLAYER_SWIPE_SENSITIVITY`)
- Requiere nueva escena `SettingsScreen.tscn` y persistencia en `SaveManager`.
- `PLAYER_SWIPE_SENSITIVITY = 1.0` actualmente en `Constants.gd`; para que sea configurable en runtime necesita vivir en `SaveManager._data`.

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
