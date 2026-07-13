class_name AchievementsScreen
extends Node2D
## Displays all achievements with lock/unlock state.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.06, 0.08, 0.06)
const LOCKED_COLOR: Color = Color(0.35, 0.35, 0.35)
const UNLOCKED_COLOR: Color = Color(0.3, 0.85, 0.2)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)

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
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 0)
	canvas.add_child(root)

	var top_pad: Control = Control.new()
	top_pad.custom_minimum_size = Vector2(0.0, 24.0)
	root.add_child(top_pad)

	var title: Label = Label.new()
	title.text = "LOGROS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 28)
	title.add_theme_color_override(&"font_color", GOLD_COLOR)
	root.add_child(title)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 10.0)
	root.add_child(spacer)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(list)
	scroll.add_child(margin)

	for def in Constants.ACHIEVEMENTS:
		_build_row(list, def as Dictionary)

	var bottom_pad: Control = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0.0, 8.0)
	root.add_child(bottom_pad)

	var back_btn: Button = Button.new()
	back_btn.custom_minimum_size = Vector2(160.0, 44.0)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	var back_hbox: HBoxContainer = HBoxContainer.new()
	back_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	back_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	back_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(back_hbox)
	var back_icon: IconPainter = IconPainter.new()
	back_icon.icon_id = &"back"
	back_icon.icon_color = Color(1.0, 1.0, 1.0, 0.9)
	back_icon.custom_minimum_size = Vector2(20.0, 20.0)
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_hbox.add_child(back_icon)
	var back_lbl: Label = Label.new()
	back_lbl.text = " VOLVER"
	back_lbl.add_theme_font_size_override(&"font_size", 17)
	back_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_hbox.add_child(back_lbl)
	root.add_child(back_btn)

	var final_pad: Control = Control.new()
	final_pad.custom_minimum_size = Vector2(0.0, 14.0)
	root.add_child(final_pad)

func _build_row(parent: Control, def: Dictionary) -> void:
	var id: StringName = def.get("id", &"") as StringName
	var unlocked: bool = SaveManager.has_achievement(id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var icon: Label = Label.new()
	icon.text = "★" if unlocked else "☆"
	icon.add_theme_font_size_override(&"font_size", 24)
	var icon_color: Color = GOLD_COLOR if unlocked else LOCKED_COLOR
	icon.add_theme_color_override(&"font_color", icon_color)
	icon.custom_minimum_size = Vector2(32.0, 0.0)
	row.add_child(icon)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = def.get("name", "") as String
	name_lbl.add_theme_font_size_override(&"font_size", 16)
	var name_color: Color = UNLOCKED_COLOR if unlocked else LOCKED_COLOR
	name_lbl.add_theme_color_override(&"font_color", name_color)
	vbox.add_child(name_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = def.get("desc", "") as String
	desc_lbl.add_theme_font_size_override(&"font_size", 12)
	desc_lbl.add_theme_color_override(&"font_color", Color(0.6, 0.6, 0.6))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
