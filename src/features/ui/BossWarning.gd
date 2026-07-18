class_name BossWarning
extends CanvasLayer
## Flash banner shown 5 s before the boss spawns.
## Fades out over the last 0.5 s of its display duration.

const DISPLAY_DURATION: float = 3.0

var _container: Control
var _label: Label
var _timer: float = 0.0

func _ready() -> void:
	layer = 15
	_build_ui()
	hide()
	EventBus.boss_incoming.connect(_on_boss_incoming)

func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.0, 0.0, 0.5)
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.26
	bg.anchor_bottom = 0.42
	_container.add_child(bg)

	_label = Label.new()
	_label.text = tr(&"BOSS_WARNING")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.0
	_label.anchor_right = 1.0
	_label.anchor_top = 0.26
	_label.anchor_bottom = 0.42
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	_container.add_child(_label)

func _process(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer -= delta
	var alpha: float = 1.0
	if _timer < 0.5:
		alpha = _timer / 0.5
	_container.modulate.a = alpha
	if _timer <= 0.0:
		hide()

func _on_boss_incoming() -> void:
	show()
	_timer = DISPLAY_DURATION
	_container.modulate.a = 1.0

func get_label() -> Label:
	return _label
