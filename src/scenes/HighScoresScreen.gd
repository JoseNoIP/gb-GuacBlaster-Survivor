class_name HighScoresScreen
extends Node2D
## Full top-10 leaderboard screen.

const BG_COLOR: Color = Color(0.04, 0.06, 0.04)
const TITLE_COLOR: Color = Color(1.0, 0.85, 0.2)
const WON_COLOR: Color = Color(0.3, 0.95, 0.2)
const LOST_COLOR: Color = Color(0.75, 0.35, 0.35)
const MUTED_COLOR: Color = Color(0.45, 0.45, 0.45)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)
const HEADER_COLOR: Color = Color(0.55, 0.75, 0.55)

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
	top_pad.custom_minimum_size = Vector2(0.0, 32.0)
	root.add_child(top_pad)

	var title: Label = Label.new()
	title.text = tr(&"TITLE_HISCORES")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 28)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	root.add_child(title)

	var sep_pad: Control = Control.new()
	sep_pad.custom_minimum_size = Vector2(0.0, 16.0)
	root.add_child(sep_pad)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 24)
	margin.add_theme_constant_override(&"margin_right", 24)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var scores: Array = SaveManager.get_high_scores()
	if scores.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = tr(&"HISCORE_EMPTY")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override(&"font_size", 16)
		empty_lbl.add_theme_color_override(&"font_color", MUTED_COLOR)
		list.add_child(empty_lbl)
	else:
		var header: HBoxContainer = _make_row(
			"#", "PUNTOS", "PJ", "RESULTADO", "FECHA", HEADER_COLOR
		)
		list.add_child(header)
		var line: ColorRect = ColorRect.new()
		line.color = Color(0.25, 0.35, 0.25)
		line.custom_minimum_size = Vector2(0.0, 1.0)
		list.add_child(line)
		var show_count: int = mini(10, scores.size())
		for i: int in show_count:
			var entry: Dictionary = scores[i] as Dictionary
			var score_val: int = entry.get("score", 0) as int
			var char_name: String = entry.get("char", "?") as String
			var won: bool = entry.get("won", false) as bool
			var date_str: String = entry.get("date", "") as String
			var result_str: String = "VICTORIA" if won else "DERROTA"
			var row_color: Color = WON_COLOR if (i == 0) else (Color(0.9, 0.9, 0.9) if won else LOST_COLOR)
			if i > 0:
				row_color = WON_COLOR if won else LOST_COLOR
				row_color.s *= 0.7
			var row: HBoxContainer = _make_row(
				str(i + 1), str(score_val), char_name, result_str, date_str, row_color
			)
			if i == 0:
				var gold_bg: StyleBoxFlat = StyleBoxFlat.new()
				gold_bg.bg_color = Color(0.2, 0.18, 0.04)
				gold_bg.set_corner_radius_all(6)
				var panel: PanelContainer = PanelContainer.new()
				panel.add_theme_stylebox_override(&"panel", gold_bg)
				panel.add_child(row)
				list.add_child(panel)
			else:
				list.add_child(row)
			var divider: ColorRect = ColorRect.new()
			divider.color = Color(0.15, 0.2, 0.15)
			divider.custom_minimum_size = Vector2(0.0, 1.0)
			list.add_child(divider)

	var back_pad: Control = Control.new()
	back_pad.custom_minimum_size = Vector2(0.0, 20.0)
	root.add_child(back_pad)

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
	back_lbl.text = " " + tr(&"BTN_BACK")
	back_lbl.add_theme_font_size_override(&"font_size", 17)
	back_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_hbox.add_child(back_lbl)
	root.add_child(back_btn)

	var bot_pad: Control = Control.new()
	bot_pad.custom_minimum_size = Vector2(0.0, 20.0)
	root.add_child(bot_pad)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/MainMenu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _make_row(
		rank: String, score: String, char_name: String,
		result: String, date: String, color: Color
) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 0)
	row.custom_minimum_size = Vector2(0.0, 38.0)

	var cols: Array[String] = [rank, score, char_name, result, date]
	var widths: Array[float] = [30.0, 80.0, 80.0, 90.0, 0.0]
	for j: int in cols.size():
		var lbl: Label = Label.new()
		lbl.text = cols[j]
		lbl.add_theme_font_size_override(&"font_size", 14)
		lbl.add_theme_color_override(&"font_color", color)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if j == cols.size() - 1:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			lbl.custom_minimum_size = Vector2(widths[j], 0.0)
		row.add_child(lbl)
	return row
