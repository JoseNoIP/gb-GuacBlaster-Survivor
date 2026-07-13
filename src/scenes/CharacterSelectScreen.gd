class_name CharacterSelectScreen
extends Node2D
## Character selection screen. Unlockable characters with gold.

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.06, 0.08, 0.06)
const SELECTED_BORDER: Color = Color(0.3, 0.85, 0.2)
const UNLOCKED_BORDER: Color = Color(0.35, 0.55, 0.3)
const LOCKED_BORDER: Color = Color(0.3, 0.3, 0.3)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.2)

var _cards: Dictionary = {}
var _toast_layer: CanvasLayer
var _toast_label: Label
var _toast_tween: Tween

func _ready() -> void:
	_build_toast_layer()
	_build_ui()

func _build_toast_layer() -> void:
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 20
	add_child(_toast_layer)
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.anchor_top = 0.0
	_toast_label.anchor_bottom = 0.0
	_toast_label.offset_left = -140.0
	_toast_label.offset_right = 140.0
	_toast_label.offset_top = 60.0
	_toast_label.offset_bottom = 90.0
	_toast_label.add_theme_font_size_override(&"font_size", 15)
	_toast_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_toast_layer.add_child(_toast_label)

func _show_toast(text: String, color: Color) -> void:
	_toast_label.text = text
	_toast_label.add_theme_color_override(&"font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.35)

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
	title.text = "ELIGE PERSONAJE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", Color(0.3, 0.85, 0.2))
	root.add_child(title)

	var gold_lbl: Label = Label.new()
	gold_lbl.text = "Oro: %d" % SaveManager.get_gold()
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override(&"font_size", 18)
	gold_lbl.add_theme_color_override(&"font_color", GOLD_COLOR)
	root.add_child(gold_lbl)

	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, 16.0)
	root.add_child(gap)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 14)
	margin.add_theme_constant_override(&"margin_right", 14)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for def in Constants.CHARACTERS:
		_build_card(list, def as Dictionary, gold_lbl)

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

func _build_card(
	parent: Control, def: Dictionary, gold_lbl: Label
) -> void:
	var char_id: StringName = def.get("id", &"") as StringName
	var unlocked: bool = SaveManager.is_character_unlocked(char_id)
	var selected: bool = SaveManager.get_selected_character() == char_id
	var cost: int = def.get("cost", 0) as int

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.12)
	if selected:
		style.border_color = SELECTED_BORDER
	elif unlocked:
		style.border_color = UNLOCKED_BORDER
	else:
		style.border_color = LOCKED_BORDER
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

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override(&"separation", 12)
	card.add_child(hbox)

	var sprite_path: String = "res://assets/sprites/characters/player_" + str(char_id) + ".png"
	if ResourceLoader.exists(sprite_path):
		var preview: TextureRect = TextureRect.new()
		preview.custom_minimum_size = Vector2(56.0, 56.0)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = load(sprite_path) as Texture2D
		if not unlocked:
			preview.modulate = Color(0.4, 0.4, 0.4, 0.7)
		hbox.add_child(preview)
	else:
		var swatch: ColorRect = ColorRect.new()
		swatch.custom_minimum_size = Vector2(6.0, 0.0)
		swatch.size_flags_vertical = Control.SIZE_EXPAND_FILL
		swatch.color = def.get("sprite_tint", Color.WHITE) as Color
		hbox.add_child(swatch)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl: Label = Label.new()
	name_lbl.text = def.get("name", "") as String
	var name_color: Color = SELECTED_BORDER if selected else Color(0.9, 0.9, 0.9)
	name_lbl.add_theme_color_override(&"font_color", name_color)
	name_lbl.add_theme_font_size_override(&"font_size", 18)
	info.add_child(name_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = def.get("desc", "") as String
	desc_lbl.add_theme_font_size_override(&"font_size", 12)
	desc_lbl.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(100.0, 40.0)
	btn.add_theme_font_size_override(&"font_size", 14)
	if selected:
		btn.text = "ACTIVO"
		btn.disabled = true
	elif unlocked:
		btn.text = "ELEGIR"
		btn.pressed.connect(_on_select_pressed.bind(char_id))
	else:
		btn.text = "%d ORO" % cost
		btn.pressed.connect(_on_unlock_pressed.bind(char_id, cost, gold_lbl))
	hbox.add_child(btn)

func _on_select_pressed(char_id: StringName) -> void:
	SaveManager.set_selected_character(char_id)
	var char_name: String = _get_char_name(char_id)
	_rebuild()
	_show_toast("✓ %s seleccionado" % char_name, SELECTED_BORDER)

func _on_unlock_pressed(char_id: StringName, cost: int, _gold_lbl: Label) -> void:
	if SaveManager.unlock_character(char_id, cost):
		SaveManager.set_selected_character(char_id)
		var char_name: String = _get_char_name(char_id)
		_rebuild()
		_show_toast("✓ %s desbloqueado" % char_name, GOLD_COLOR)

func _get_char_name(char_id: StringName) -> String:
	for def in Constants.CHARACTERS:
		if (def as Dictionary).get("id", &"") as StringName == char_id:
			return (def as Dictionary).get("name", "") as String
	return str(char_id)

func _rebuild() -> void:
	for child in get_children():
		if child == _toast_layer:
			continue
		child.queue_free()
	await get_tree().process_frame
	_build_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)
