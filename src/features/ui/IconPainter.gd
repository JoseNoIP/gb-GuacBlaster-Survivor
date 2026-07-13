class_name IconPainter
extends Control
## Draws named menu icons procedurally via Godot's CanvasItem draw API.
## Set icon_id before adding to the scene tree; the Control auto-sizes to
## custom_minimum_size. Recognized ids: play, character, upgrades, missions,
## achievements, map, challenge, settings.

const _GOLD: Color = Color(1.0, 0.83, 0.12)
const _RED: Color = Color(0.9, 0.22, 0.18)
const _BLUE: Color = Color(0.38, 0.78, 1.0)
const _WHITE_DIM: Color = Color(1.0, 1.0, 1.0, 0.65)

@export var icon_id: StringName = &""
@export var icon_color: Color = Color(0.35, 0.85, 0.25)

func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.40
	match icon_id:
		&"play":          _draw_play(c, r)
		&"character":     _draw_character(c, r)
		&"upgrades":      _draw_upgrades(c, r)
		&"missions":      _draw_missions(c, r)
		&"achievements":  _draw_achievements(c, r)
		&"map":           _draw_map(c, r)
		&"challenge":     _draw_challenge(c, r)
		&"settings":      _draw_settings(c, r)

# ── helpers ────────────────────────────────────────────────────────────────

func _poly(pts: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(pts, color)

func _star(center: Vector2, outer: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var a: float = float(i) * PI / 5.0 - PI * 0.5
		var rad: float = outer if i % 2 == 0 else outer * 0.42
		pts.append(center + Vector2(cos(a), sin(a)) * rad)
	_poly(pts, color)

func _rotated_rect(
		center: Vector2, w: float, h: float, angle: float
) -> PackedVector2Array:
	var half_w: float = w * 0.5
	var half_h: float = h * 0.5
	var corners: Array = [
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	]
	var pts: PackedVector2Array = PackedVector2Array()
	for corner in corners:
		pts.append(center + (corner as Vector2).rotated(angle))
	return pts

# ── play — rocket ship ─────────────────────────────────────────────────────

func _draw_play(c: Vector2, r: float) -> void:
	var col: Color = icon_color
	# Main body
	_poly(PackedVector2Array([
		c + Vector2(0.0, -r),
		c + Vector2(-r * 0.56, r * 0.52),
		c + Vector2(r * 0.56, r * 0.52),
	]), col)
	# Left fin
	_poly(PackedVector2Array([
		c + Vector2(-r * 0.36, r * 0.3),
		c + Vector2(-r * 0.88, r * 0.88),
		c + Vector2(-r * 0.2, r * 0.88),
	]), col.darkened(0.2))
	# Right fin
	_poly(PackedVector2Array([
		c + Vector2(r * 0.36, r * 0.3),
		c + Vector2(r * 0.88, r * 0.88),
		c + Vector2(r * 0.2, r * 0.88),
	]), col.darkened(0.2))
	# Cockpit ring
	draw_circle(c + Vector2(0.0, -r * 0.2), r * 0.21, col.darkened(0.5))
	draw_circle(c + Vector2(0.0, -r * 0.2), r * 0.13, _BLUE)
	# Engine glow
	draw_circle(c + Vector2(0.0, r * 0.68), r * 0.15, Color(1.0, 0.6, 0.12, 0.9))
	draw_circle(c + Vector2(0.0, r * 0.68), r * 0.07, Color(1.0, 0.95, 0.55, 0.95))

# ── character — person silhouette ─────────────────────────────────────────

func _draw_character(c: Vector2, r: float) -> void:
	var col: Color = icon_color
	# Body (trapezoid, wider at hip)
	_poly(PackedVector2Array([
		c + Vector2(-r * 0.3, -r * 0.14),
		c + Vector2(r * 0.3, -r * 0.14),
		c + Vector2(r * 0.44, r * 0.88),
		c + Vector2(-r * 0.44, r * 0.88),
	]), col.darkened(0.18))
	# Head
	draw_circle(c + Vector2(0.0, -r * 0.54), r * 0.38, col)
	# Eyes
	draw_circle(c + Vector2(-r * 0.13, -r * 0.59), r * 0.08, Color(0.05, 0.05, 0.05))
	draw_circle(c + Vector2(r * 0.13, -r * 0.59), r * 0.08, Color(0.05, 0.05, 0.05))
	# Smile arc
	draw_arc(
		c + Vector2(0.0, -r * 0.42), r * 0.17,
		0.3, PI - 0.3, 10,
		Color(0.05, 0.05, 0.05), r * 0.07
	)

# ── upgrades — bar chart + star ────────────────────────────────────────────

func _draw_upgrades(c: Vector2, r: float) -> void:
	var bw: float = r * 0.3
	var base: float = c.y + r * 0.76
	draw_rect(Rect2(c.x - r * 0.72, base - r * 0.4, bw, r * 0.4), icon_color.darkened(0.35))
	draw_rect(Rect2(c.x - bw * 0.5, base - r * 0.7, bw, r * 0.7), icon_color)
	draw_rect(Rect2(c.x + r * 0.42, base - r, bw, r), icon_color.lightened(0.08))
	draw_line(
		c + Vector2(-r * 0.82, r * 0.76),
		c + Vector2(r * 0.82, r * 0.76),
		icon_color.darkened(0.2), r * 0.1
	)
	_star(c + Vector2(r * 0.57, -r * 0.45), r * 0.3, _GOLD)

# ── missions — clipboard with checklist ────────────────────────────────────

func _draw_missions(c: Vector2, r: float) -> void:
	var bg: Color = icon_color.darkened(0.28)
	var check: Color = Color(0.38, 1.0, 0.38)
	# Board
	draw_rect(Rect2(c.x - r * 0.72, c.y - r * 0.88, r * 1.44, r * 1.78), bg)
	# Clip (top center)
	draw_rect(Rect2(c.x - r * 0.26, c.y - r * 1.0, r * 0.52, r * 0.22), icon_color)
	# Three rows
	for row: int in 3:
		var ry: float = c.y - r * 0.48 + float(row) * r * 0.52
		draw_rect(Rect2(c.x - r * 0.58, ry - r * 0.09, r * 0.24, r * 0.24), _WHITE_DIM)
		draw_rect(
			Rect2(c.x - r * 0.24, ry - r * 0.04, r * 0.72, r * 0.12),
			check if row == 0 else _WHITE_DIM
		)
	# Checkmark on first row
	var ry0: float = c.y - r * 0.48
	draw_line(
		c + Vector2(-r * 0.56, ry0 + r * 0.02),
		c + Vector2(-r * 0.46, ry0 + r * 0.13),
		check, r * 0.11
	)
	draw_line(
		c + Vector2(-r * 0.46, ry0 + r * 0.13),
		c + Vector2(-r * 0.35, ry0 - r * 0.06),
		check, r * 0.11
	)

# ── achievements — 5-pointed gold star ─────────────────────────────────────

func _draw_achievements(c: Vector2, r: float) -> void:
	_star(c + Vector2(0.0, r * 0.04), r, _GOLD)
	_star(c + Vector2(0.0, r * 0.04), r * 0.44, Color(1.0, 0.96, 0.65, 0.55))

# ── map — folded map scroll with location pin ──────────────────────────────

func _draw_map(c: Vector2, r: float) -> void:
	var map_col: Color = icon_color.darkened(0.22)
	var line_col: Color = Color(1.0, 1.0, 1.0, 0.32)
	draw_rect(Rect2(c.x - r * 0.82, c.y - r * 0.78, r * 1.64, r * 1.56), map_col)
	# Top-right fold
	_poly(PackedVector2Array([
		c + Vector2(r * 0.82 - r * 0.38, -r * 0.78),
		c + Vector2(r * 0.82, -r * 0.78 + r * 0.38),
		c + Vector2(r * 0.82, -r * 0.78),
	]), map_col.darkened(0.38))
	# Terrain path lines
	draw_line(c + Vector2(-r * 0.55, -r * 0.32), c + Vector2(-r * 0.1, r * 0.18), line_col, r * 0.09)
	draw_line(c + Vector2(-r * 0.1, r * 0.18), c + Vector2(r * 0.42, -r * 0.22), line_col, r * 0.09)
	draw_line(c + Vector2(-r * 0.68, r * 0.22), c + Vector2(-r * 0.08, r * 0.52), line_col, r * 0.07)
	# Pin circle
	draw_circle(c + Vector2(r * 0.24, -r * 0.12), r * 0.23, _RED)
	draw_circle(c + Vector2(r * 0.24, -r * 0.12), r * 0.1, Color(1.0, 1.0, 1.0, 0.85))
	# Pin tail
	_poly(PackedVector2Array([
		c + Vector2(r * 0.11, r * 0.07),
		c + Vector2(r * 0.37, r * 0.07),
		c + Vector2(r * 0.24, r * 0.34),
	]), _RED)

# ── challenge — shield with lightning bolt ─────────────────────────────────

func _draw_challenge(c: Vector2, r: float) -> void:
	# Shield body
	_poly(PackedVector2Array([
		c + Vector2(0.0, -r),
		c + Vector2(r * 0.76, -r * 0.52),
		c + Vector2(r * 0.76, r * 0.18),
		c + Vector2(0.0, r),
		c + Vector2(-r * 0.76, r * 0.18),
		c + Vector2(-r * 0.76, -r * 0.52),
	]), icon_color.darkened(0.24))
	# Lightning bolt
	_poly(PackedVector2Array([
		c + Vector2(r * 0.18, -r * 0.64),
		c + Vector2(-r * 0.08, -r * 0.02),
		c + Vector2(r * 0.22, -r * 0.02),
		c + Vector2(-r * 0.18, r * 0.64),
		c + Vector2(r * 0.08, r * 0.02),
		c + Vector2(-r * 0.22, r * 0.02),
	]), _GOLD)

# ── settings — 6-tooth gear ────────────────────────────────────────────────

func _draw_settings(c: Vector2, r: float) -> void:
	var inner_r: float = r * 0.62
	var tooth_w: float = r * 0.3
	var tooth_h: float = r * 0.36
	var teeth: int = 6
	for i: int in teeth:
		var angle: float = float(i) / float(teeth) * TAU
		var tc: Vector2 = c + Vector2(0.0, -(inner_r + tooth_h * 0.5)).rotated(angle)
		_poly(_rotated_rect(tc, tooth_w, tooth_h, angle), icon_color)
	draw_circle(c, inner_r, icon_color)
	draw_circle(c, r * 0.28, Color(0.07, 0.09, 0.07))
