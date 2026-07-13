class_name WeeklyChallengeScreen
extends Node2D
## Weekly challenge screen. Shows the current challenge modifiers and lets the player opt in.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"
const GAME_SCENE: String = "res://src/scenes/Game.tscn"

const BG_COLOR: Color = Color(0.06, 0.04, 0.10)
const TITLE_COLOR: Color = Color(0.8, 0.5, 1.0)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)
const DONE_COLOR: Color = Color(0.3, 0.95, 0.3)

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var challenge: Dictionary = WeeklyChallengeManager.get_current_challenge()
	var completed: bool = WeeklyChallengeManager.is_current_week_completed()

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
	top_pad.custom_minimum_size = Vector2(0.0, 28.0)
	root.add_child(top_pad)

	var title: Label = Label.new()
	title.text = "DESAFÍO SEMANAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	root.add_child(title)

	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, 18.0)
	root.add_child(gap)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 20)
	margin.add_theme_constant_override(&"margin_right", 20)
	root.add_child(margin)

	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.20)
	style.border_color = TITLE_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override(&"panel", style)
	margin.add_child(card)

	var inner_margin: MarginContainer = MarginContainer.new()
	inner_margin.add_theme_constant_override(&"margin_left", 16)
	inner_margin.add_theme_constant_override(&"margin_right", 16)
	inner_margin.add_theme_constant_override(&"margin_top", 14)
	inner_margin.add_theme_constant_override(&"margin_bottom", 14)
	card.add_child(inner_margin)

	var card_vbox: VBoxContainer = VBoxContainer.new()
	card_vbox.add_theme_constant_override(&"separation", 10)
	inner_margin.add_child(card_vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = challenge.get("name", "") as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override(&"font_size", 22)
	name_lbl.add_theme_color_override(&"font_color", TITLE_COLOR)
	card_vbox.add_child(name_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = challenge.get("desc", "") as String
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override(&"font_size", 14)
	desc_lbl.add_theme_color_override(&"font_color", Color(0.75, 0.75, 0.75))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(desc_lbl)

	var divider: HSeparator = HSeparator.new()
	card_vbox.add_child(divider)

	var gold_mult: float = challenge.get("gold_mult", 1.0) as float
	var reward_lbl: Label = Label.new()
	reward_lbl.text = "Recompensa de oro: ×%.1f" % gold_mult
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override(&"font_size", 16)
	reward_lbl.add_theme_color_override(&"font_color", GOLD_COLOR)
	card_vbox.add_child(reward_lbl)

	if completed:
		var done_lbl: Label = Label.new()
		done_lbl.text = "✓ COMPLETADO ESTA SEMANA"
		done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done_lbl.add_theme_font_size_override(&"font_size", 14)
		done_lbl.add_theme_color_override(&"font_color", DONE_COLOR)
		card_vbox.add_child(done_lbl)

	var gap2: Control = Control.new()
	gap2.custom_minimum_size = Vector2(0.0, 20.0)
	root.add_child(gap2)

	var play_btn: Button = Button.new()
	play_btn.text = "JUGAR DESAFÍO"
	play_btn.custom_minimum_size = Vector2(200.0, 54.0)
	play_btn.add_theme_font_size_override(&"font_size", 20)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.pressed.connect(_on_play_pressed)
	root.add_child(play_btn)

	var bottom_fill: Control = Control.new()
	bottom_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom_fill)

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

	var bottom_pad: Control = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0.0, 14.0)
	root.add_child(bottom_pad)

func _on_play_pressed() -> void:
	WeeklyChallengeManager.activate_challenge()
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
