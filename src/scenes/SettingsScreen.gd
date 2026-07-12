class_name SettingsScreen
extends Node2D
## Settings screen. Currently exposes swipe sensitivity configuration.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.08, 0.1, 0.08)
const TITLE_COLOR: Color = Color(0.3, 0.85, 0.2)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9)
const VALUE_COLOR: Color = Color(0.3, 0.85, 0.2)
const HINT_COLOR: Color = Color(0.55, 0.55, 0.55)

var _sensitivity_pct: int = 100
var _sensitivity_label: Label

func _ready() -> void:
	var raw: int = roundi(SaveManager.get_swipe_sensitivity() * 100.0)
	_sensitivity_pct = clampi((raw / 20) * 20, 100, 200)
	_build_ui()

func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.size = vp
	add_child(bg)

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var root: VBoxContainer = VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 20)
	canvas.add_child(root)

	var spacer_top: Control = Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_top)

	var title: Label = Label.new()
	title.text = "CONFIGURACIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 32)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	root.add_child(title)

	var sep: Control = Control.new()
	sep.custom_minimum_size = Vector2(0.0, 16.0)
	root.add_child(sep)

	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override(&"separation", 10)
	root.add_child(section)

	var section_title: Label = Label.new()
	section_title.text = "SENSIBILIDAD DE CONTROL"
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_font_size_override(&"font_size", 18)
	section_title.add_theme_color_override(&"font_color", LABEL_COLOR)
	section.add_child(section_title)

	_sensitivity_label = Label.new()
	_sensitivity_label.text = "%d%%" % _sensitivity_pct
	_sensitivity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sensitivity_label.add_theme_font_size_override(&"font_size", 32)
	_sensitivity_label.add_theme_color_override(&"font_color", VALUE_COLOR)
	section.add_child(_sensitivity_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 100.0
	slider.max_value = 200.0
	slider.step = 20.0
	slider.value = float(_sensitivity_pct)
	slider.custom_minimum_size = Vector2(280.0, 44.0)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_slider_changed)
	section.add_child(slider)

	var hint: Label = Label.new()
	hint.text = "100% = base  ·  200% = doble velocidad"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 13)
	hint.add_theme_color_override(&"font_color", HINT_COLOR)
	section.add_child(hint)

	var spacer_bottom: Control = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_bottom)

	var back_btn: Button = Button.new()
	back_btn.text = "← ATRÁS"
	back_btn.custom_minimum_size = Vector2(160.0, 50.0)
	back_btn.add_theme_font_size_override(&"font_size", 20)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)

	var spacer_final: Control = Control.new()
	spacer_final.custom_minimum_size = Vector2(0.0, 32.0)
	root.add_child(spacer_final)

func _on_slider_changed(value: float) -> void:
	_sensitivity_pct = int(value)
	_sensitivity_label.text = "%d%%" % _sensitivity_pct
	SaveManager.set_swipe_sensitivity(float(_sensitivity_pct) / 100.0)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)

func get_sensitivity_label() -> Label:
	return _sensitivity_label
