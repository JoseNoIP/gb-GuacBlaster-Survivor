# Pendientes y Configuración

## CI/CD — GitHub Actions

Workflow creado en `.github/workflows/build-android.yml`.

**Estado actual:** solo compilación (paso 1).
**Paso 2 pendiente:** subir APK a Dropbox (ver instrucciones abajo).

### Lógica de ramas
| Rama | APK generado | Destino Dropbox (pendiente) |
|---|---|---|
| `staging` | `GuacBlaster-staging.apk` | `/stg/` |
| `main` | `GuacBlaster-prod.apk` | `/prod/` |

El APK queda como artefacto descargable en GitHub Actions por 14 días.

### Variables a ajustar en el workflow
- `GODOT_VERSION` — debe coincidir exactamente con tu versión instalada (actualmente `"4.4.2"`).
  Verifica tags disponibles en: https://github.com/godotengine/godot/releases
- `DROPBOX_DEST_PATH` — ruta dentro de tu Dropbox donde se deposita el APK.

### Secrets requeridos en GitHub
Ir a: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Descripción |
|---|---|
| `DROPBOX_APP_KEY` | App Key de tu Dropbox App |
| `DROPBOX_APP_SECRET` | App Secret de tu Dropbox App |
| `DROPBOX_REFRESH_TOKEN` | Refresh token OAuth2 (ver instrucciones abajo) |

### Cómo crear la Dropbox App y obtener el refresh token

1. Ir a https://www.dropbox.com/developers/apps → **Create app**
2. Elegir **Scoped access** → **Full Dropbox** (o App folder si prefieres)
3. Darle un nombre (ej. `guacblaster-ci`)
4. En la pestaña **Permissions** activar: `files.content.write`, `files.content.read`
5. Anotar **App key** y **App secret** de la pestaña Settings

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

### Notas importantes
- `export_presets.cfg` está en el repo (debug build, sin claves de producción).
- Para release build necesitarás un keystore firmado y agregarlo como secret.
- El APK también queda disponible como artefacto descargable en GitHub Actions por 14 días.

---

# Assets Externos

## Backgrounds por ronda
La lógica ya está implementada: cada run lee `SaveManager.get_total_sessions() % palette.size()`
y aplica un color de `Constants.BACKGROUND_PALETTE`. Para reemplazar colores por imágenes:

- Crear 5 imágenes de fondo (390×844 px, pixel art) para los biomas:
  1. Jungla oscura (default)
  2. Crepúsculo / índigo
  3. Volcánico / brasa
  4. Abismo / océano profundo
  5. Luna de sangre / desierto nocturno
- Colocar en `assets/sprites/backgrounds/bg_0.png` … `bg_4.png`
- En `Game.gd._ready()`, reemplazar `_background.color = ...` por:
  ```gdscript
  var tex := load("res://assets/sprites/backgrounds/bg_%d.png" % palette_index) as Texture2D
  _background.texture = tex  # cambiar ColorRect → TextureRect en Game.tscn
  ```

## Settings Screen (pendiente)
- Sonido on/off, vibración on/off
- Sensibilidad del swipe (actualmente usa `Constants.PLAYER_SWIPE_SENSITIVITY = 1.0`)
- Requiere pantalla de configuración nueva y persistencia en SaveManager

## Cuentas de usuario (pendiente)
- Login con Facebook / Google / cuenta propia de Guacamole Bit
- Requiere SDK externo (GodotFacebook / GodotGameServices / backend propio)
- No implementable sin integración de plataforma

---

## SFX / Música
AudioManager autoload existe en `src/features/audio/AudioManager.gd`.
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
- `powerup_icons/` — 8 íconos (32×32 px) para las cartas de power-up
