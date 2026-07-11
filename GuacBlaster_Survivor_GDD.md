# Documento de Diseño de Juego (GDD - Quick Concept)
**Proyecto:** GuacBlaster Survivor  
**Estudio:** GuacamoleBit  
**Plataforma:** iOS / Android (Mobile)  
**Género:** Arcade / Hyper-Casual Survivor / Shooter Frontal  

---

## 1. Visión General del Juego

**GuacBlaster Survivor** es un juego hipercasual de supervivencia frontal con controles de un solo dedo. El jugador controla a una pequeña verdura/personaje heróico que combate hordas descendentes de comida basura mientras evoluciona su arsenal en tiempo real mediante un sistema de potenciadores aleatorios.

### Pilares de Diseño
* **Accesibilidad Extrema:** Control con un solo dedo (arrastrar horizontalmente).
* **Satisfacción Visual y Auditiva (Juice):** Explotar enemigos genera cadenas de sonido ASMR (*pop!/crunch!*) y salpicaduras de colores.
* **Progresión Rápida:** Partidas cortas (2 a 5 minutos) donde pasas de un disparo básico a una lluvia de proyectiles en segundos.

---

## 2. Mecánicas Core (Gameplay)

```
[ Controles ] ──► Mover a la izquierda / derecha (Disparo automático)
                      │
                      ▼
[ Loop Core ] ──► Destruir enemigos ──► Recoger Guac-Gemas ──► Subir de Nivel
                      │
                      ▼
[ Recompensa] ──► Elegir 1 de 3 Potenciadores ──► Crear sinergias absurdas
```

### Controles
* **Touch & Drag Horizontal:** El personaje sigue la posición del dedo en el eje X de la pantalla.
* **Autofire:** El personaje dispara de manera continua hacia arriba.

---

## 3. Sistema de Potenciadores (Power-Ups)

Cada vez que la barra de experiencia se llena, la partida se pausa brevemente y se presentan 3 tarjetas de mejora elegidas al azar:

| Nombre | Tipo | Descripción |
| :--- | :--- | :--- |
| **Disparo Triple** | Proyectil | Añade dos disparos diagonales adicionales en abanico. |
| **Súper-Guac** | Penetración | Proyectiles más grandes que atraviesan hasta 3 enemigos. |
| **Fuego Rápido** | Cadencia | Aumenta la velocidad de ataque un 25%. |
| **Granada de Mole** | Cooldown | Lanza una bomba cada 5s que genera daño de área (AoE). |
| **Láser de Jalapeño** | Haz continuo | Un rayo que quema una columna entera durante 2 segundos. |
| **Rebote Picante** | Física | Los proyectiles rebotan en los bordes laterales del escenario. |
| **Muro de Nachos** | Defensivo | Escudo frontal temporal que absorbe 3 impactos directos. |
| **Imán de Salsa** | Utilidad | Atrae automáticamente las gemas de experiencia en pantalla. |

---

## 4. Tipos de Enemigos

* **Burbuja Básica:** Desciende en línea recta. Requiere 1 impacto.
* **Burbuja Tanque (Gigante):** Absorbe múltiples disparos. Al destruirse, se divide en 4 burbujas básicas.
* **Abeja/Mosca de Nacho:** Se mueve rápidamente en zigzag diagonal.
* **Jefe (Cada 3 Minutos):** Enemigo masivo que dispara proyectiles lentos que el jugador debe esquivar mientras mantiene el ataque.

---

## 5. Estética, Sonido e Identidad (GuacamoleBit)

* **Arte:** Pixel art vibrante o *vector art toony*. Paleta de colores verde fresco en contraste con amarillos/naranjas fritos.
* **Feedback Háptico:**
  * Vibración ligera y rítmica con el disparo continuo.
  * Vibración fuerte al derrotar un Jefe o activar un súper potenciador.
* **Efectos de Sonido (SFX):**
  * Disparos con sonido suave (*plok-plok*).
  * Impactos y explosiones estilo burbuja reventando o crujido crujiente (*crunch!/pop!*).

---

## 6. Progresión Fuera de Partida (Meta-Game)

* **Monedas de Oro:** Se recolectan al finalizar las partidas o cumplir misiones diarias.
* **Árbol de Mejoras Permanentes:**
  1. *Daño Base (+5% por nivel)*
  2. *Velocidad de Movimiento (+3% por nivel)*
  3. *Vida Máxima (+1 corazón extra)*
  4. *Suerte (Mayor probabilidad de potenciadores raros)*