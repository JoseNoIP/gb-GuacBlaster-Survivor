# GDD Template — Juego Móvil Godot (GuacamoleBit)

Completa este template y pásalo a `/new-game ruta/a/este-archivo.md`.
Los campos con `[REQUERIDO]` bloquean la construcción si no se especifican.
Los campos con `[OPCIONAL]` tienen defaults razonables para hyper-casual.

---

## Identidad del juego

**Nombre:** [REQUERIDO]
**Género:** [REQUERIDO] (ej: survivor, runner, puzzle, tower-defense)
**Tagline:** [OPCIONAL] una línea que describe la fantasía del jugador
**Orientación:** vertical (default) | horizontal
**Sesión típica:** [REQUERIDO] (ej: 2–5 minutos)

---

## Core Loop [REQUERIDO]

Describe qué hace el jugador cada frame / cada segundo:

1. [qué controla el jugador]
2. [qué pasa automáticamente]
3. [cómo el jugador progresa en la sesión]

**Control:** drag relativo 1 dedo (default) | tap | swipe | [otro]

---

## Condición de Victoria [REQUERIDO]

- [ej: matar al jefe final]
- [ej: sobrevivir X minutos]
- [ej: llegar a nivel 10]

---

## Condición de Derrota [REQUERIDO]

- [ej: perder todos los corazones]
- [ej: que un enemigo llegue al borde inferior]

---

## Jugador

| Stat | Valor base | Upgrades |
|---|---|---|
| HP | [REQUERIDO] | [OPCIONAL] |
| Velocidad | [REQUERIDO] px/s | [OPCIONAL] |
| Daño base | [REQUERIDO] | [OPCIONAL] |
| Autofire interval | [OPCIONAL: 0.4s] | [OPCIONAL] |
| Sensibilidad swipe | [OPCIONAL: 1.0] | configurable 1.0×–2.0× |

---

## Enemigos [REQUERIDO — mínimo 2]

| Nombre | HP | Velocidad | Comportamiento | XP al morir | Gold al morir |
|---|---|---|---|---|---|
| [nombre] | | | [descripción] | | |

**Jefe:** [REQUERIDO si hay]
- HP: base + incremento × generación
- Aparece cada: [ej: 3 minutos]
- Comportamiento especial: [descripción]

---

## Power-ups [REQUERIDO — mínimo 3]

| ID | Abrev HUD | Nombre | Efecto por stack | Duración |
|---|---|---|---|---|
| `triple_shot` | TS | [nombre] | [descripción] | [ej: 30s] |

**Stackable:** sí (default) | no
**Método de obtención:** nivel-up drops físicos (default) | tarjetas pausadas | [otro]

---

## Progresión en sesión

**XP para nivel 1:** [OPCIONAL: 40]
**Escala por nivel:** [OPCIONAL: ×1.2]
**XP por enemigo básico:** [OPCIONAL: 8]

Al subir de nivel: [OPCIONAL: caen 3 power-up drops físicos, juego no se pausa]

---

## Metagame (entre sesiones) [OPCIONAL]

**Moneda:** [nombre] — se gana: [descripción]
**Upgrades permanentes:** [lista de upgrades]
**Costo de upgrade:** [OPCIONAL: 50 × 1.8^nivel, cap nivel 5]

---

## Pantallas y UI

**Pantallas requeridas:** MainMenu, Game, GameOver, Victory [REQUERIDO]
**Pantallas opcionales:** UpgradeScreen, SettingsScreen, DailyMissions, Leaderboard

**HUD elementos:**
- [ ] HP (corazones)
- [ ] Score / puntuación
- [ ] Nivel actual
- [ ] XP bar
- [ ] Timer (si aplica)
- [ ] Tira de power-ups activos
- [ ] Barra HP de jefe (si aplica)
- [ ] [otros]

---

## Estética / Feel

**Paleta de colores:** [ej: pixel art vibrante, neon, pastel]
**Biomas o fondos:** [número de biomas] — descripción de cada uno
**VFX requeridos:** [ej: explosiones, partículas de muerte, screen shake]
**Audio:** [ej: 8-bit chiptune, tropical, silencio/minimal]

---

## Assets disponibles al inicio

Marcar los que YA existen (no marcar = Claude usará ColorRect/placeholder):

- [ ] Sprite del jugador (`assets/sprites/player.png`, 32×32)
- [ ] Sprites de enemigos
- [ ] Sprites de proyectiles
- [ ] Íconos de power-ups (`assets/sprites/powerup_icons/`)
- [ ] Fondos por bioma (`assets/sprites/backgrounds/`)
- [ ] SFX (`.ogg` en `assets/audio/`)
- [ ] Música de fondo (`assets/audio/music_loop.ogg`)

---

## Señales clave del EventBus [OPCIONAL — Claude derivará del diseño]

Si quieres especificar señales exactas, lista aquí. Si no, Claude las derivará del GDD.

---

## Notas adicionales / Restricciones técnicas

[cualquier constraint que Claude deba respetar que no encaje en los campos anteriores]
