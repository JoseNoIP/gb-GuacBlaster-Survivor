extends Node2D
## First-run language selection screen. Shows once; saves choice and routes to MainMenu.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.08, 0.1, 0.08)
const TITLE_COLOR: Color = Color(0.3, 0.85, 0.2)

const LANGUAGES: Array = [
	{"id": "es", "label": "Español"},
	{"id": "en", "label": "English"},
	{"id": "pt_BR", "label": "Português (BR)"},
	{"id": "fr", "label": "Français"},
]

func _ready() -> void:
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
	root.add_theme_constant_override(&"separation", 24)
	canvas.add_child(root)

	var spacer_top: Control = Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_top)

	var title: Label = Label.new()
	title.text = "Language / Idioma"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 28)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	root.add_child(title)

	var sep: Control = Control.new()
	sep.custom_minimum_size = Vector2(0.0, 8.0)
	root.add_child(sep)

	for lang: Dictionary in LANGUAGES:
		var btn: Button = Button.new()
		btn.text = lang.get("label", "") as String
		btn.custom_minimum_size = Vector2(240.0, 60.0)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override(&"font_size", 22)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.4, 0.15)
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_left = 12
		sb.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override(&"normal", sb)
		var sb_h: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color(0.2, 0.6, 0.2)
		btn.add_theme_stylebox_override(&"hover", sb_h)
		var lang_id: String = lang.get("id", "es") as String
		btn.pressed.connect(func() -> void: _on_language_selected(lang_id))
		root.add_child(btn)

	var spacer_bottom: Control = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_bottom)

func _on_language_selected(lang_id: String) -> void:
	LocalizationManager.set_language(lang_id)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
