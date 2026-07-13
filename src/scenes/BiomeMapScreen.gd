class_name BiomeMapScreen
extends Node2D
## Biome progression map. Each biome unlocks after one victory.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BIOME_NAMES: Array = [
	"Jungla Guacamole",
	"Crepúsculo Índigo",
	"Caldera Volcánica",
	"Abismo Oceánico",
	"Desierto de Luna Sangre",
]

const BG_COLOR: Color = Color(0.05, 0.07, 0.05)
const LOCKED_COLOR: Color = Color(0.25, 0.25, 0.25)
const UNLOCKED_COLOR: Color = Color(0.3, 0.85, 0.2)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var victories: int = SaveManager.get_victories()

	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.size = vp
	add_child(bg)

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 0)
	canvas.add_child(root)

	var top_pad: Control = Control.new()
	top_pad.custom_minimum_size = Vector2(0.0, 24.0)
	root.add_child(top_pad)

	var title: Label = Label.new()
	title.text = "MAPA DE BIOMAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", GOLD_COLOR)
	root.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Victorias: %d" % victories
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override(&"font_size", 15)
	subtitle.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.65))
	root.add_child(subtitle)

	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, 20.0)
	root.add_child(gap)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_right", 20)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 12)
	margin.add_child(list)

	var palette: Array = Constants.BACKGROUND_PALETTE
	for i: int in palette.size():
		_build_biome_row(list, i, victories, palette)

	var bottom_pad: Control = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0.0, 8.0)
	root.add_child(bottom_pad)

	var back_btn: Button = Button.new()
	back_btn.text = "VOLVER"
	back_btn.custom_minimum_size = Vector2(160.0, 44.0)
	back_btn.add_theme_font_size_override(&"font_size", 17)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)

	var final_pad: Control = Control.new()
	final_pad.custom_minimum_size = Vector2(0.0, 14.0)
	root.add_child(final_pad)

func _build_biome_row(
	parent: Control, idx: int, victories: int, palette: Array
) -> void:
	var unlocked: bool = victories > idx or idx == 0
	var current: bool = (victories % palette.size()) == idx

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var swatch: ColorRect = ColorRect.new()
	swatch.size = Vector2(32.0, 32.0)
	swatch.custom_minimum_size = Vector2(32.0, 32.0)
	swatch.color = palette[idx] as Color if unlocked else LOCKED_COLOR
	row.add_child(swatch)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vbox)

	var biome_name: String = BIOME_NAMES[idx] if idx < BIOME_NAMES.size() else "Bioma %d" % (idx + 1)
	var name_row_text: String = biome_name
	if current and unlocked:
		name_row_text += "  ◄ actual"

	var name_lbl: Label = Label.new()
	name_lbl.text = name_row_text
	var text_color: Color = UNLOCKED_COLOR if unlocked else LOCKED_COLOR
	name_lbl.add_theme_color_override(&"font_color", text_color)
	name_lbl.add_theme_font_size_override(&"font_size", 16)
	vbox.add_child(name_lbl)

	var status_lbl: Label = Label.new()
	if idx == 0:
		status_lbl.text = "Siempre disponible"
	elif unlocked:
		status_lbl.text = "Desbloqueado tras %d victoria(s)" % idx
	else:
		status_lbl.text = "Requiere %d victoria(s)" % idx
	status_lbl.add_theme_font_size_override(&"font_size", 12)
	status_lbl.add_theme_color_override(&"font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(status_lbl)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
