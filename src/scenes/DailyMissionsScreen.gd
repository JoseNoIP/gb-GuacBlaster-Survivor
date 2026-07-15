class_name DailyMissionsScreen
extends Node2D
## Shows today's 3 daily missions with progress and completion state.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.06, 0.08, 0.06)
const DONE_COLOR: Color = Color(0.3, 0.85, 0.2)
const PENDING_COLOR: Color = Color(0.85, 0.75, 0.25)
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
	title.text = "MISIONES DIARIAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", GOLD_COLOR)
	root.add_child(title)

	var date_lbl: Label = Label.new()
	var d: Dictionary = Time.get_date_dict_from_system()
	date_lbl.text = "%d/%02d/%d" % [d.get("day", 0), d.get("month", 0), d.get("year", 0)]
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_lbl.add_theme_font_size_override(&"font_size", 14)
	date_lbl.add_theme_color_override(&"font_color", Color(0.55, 0.55, 0.55))
	root.add_child(date_lbl)

	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, 24.0)
	root.add_child(gap)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_right", 18)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 20)
	margin.add_child(list)

	var missions: Array = DailyMissionsManager.get_missions()
	for mission in missions:
		_build_card(list, mission as Dictionary)

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

func _build_card(parent: Control, mission: Dictionary) -> void:
	var completed: bool = mission.get("completed", false) as bool
	var current: int = mission.get("current", 0) as int
	var target: int = mission.get("target", 1) as int
	var reward: int = mission.get("reward", 0) as int

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.12)
	var border_color: Color = DONE_COLOR if completed else PENDING_COLOR
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override(&"panel", style)
	parent.add_child(card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	card.add_child(vbox)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = mission.get("desc", "") as String
	desc_lbl.add_theme_font_size_override(&"font_size", 17)
	var text_color: Color = DONE_COLOR if completed else Color(0.9, 0.9, 0.9)
	desc_lbl.add_theme_color_override(&"font_color", text_color)
	vbox.add_child(desc_lbl)

	var progress_row: HBoxContainer = HBoxContainer.new()
	progress_row.add_theme_constant_override(&"separation", 10)
	vbox.add_child(progress_row)

	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(target)
	bar.value = float(mini(current, target))
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 16.0)
	progress_row.add_child(bar)

	var count_lbl: Label = Label.new()
	count_lbl.text = "%d/%d" % [mini(current, target), target]
	count_lbl.add_theme_font_size_override(&"font_size", 13)
	count_lbl.add_theme_color_override(&"font_color", Color(0.75, 0.75, 0.75))
	progress_row.add_child(count_lbl)

	var reward_lbl: Label = Label.new()
	var prefix: String = "✓ " if completed else ""
	reward_lbl.text = "%s+%d oro" % [prefix, reward]
	reward_lbl.add_theme_font_size_override(&"font_size", 14)
	reward_lbl.add_theme_color_override(&"font_color", GOLD_COLOR)
	vbox.add_child(reward_lbl)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
