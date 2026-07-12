# Pendientes — Requieren Assets Externos

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
