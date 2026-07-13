class_name UpgradeScreen
extends Node2D
## Permanent upgrade shop. Accessible from the Main Menu.
## Purchases are handled via SaveManager.purchase_upgrade().

const MAIN_MENU_SCENE: String = "res://src/scenes/MainMenu.tscn"

const BG_COLOR: Color = Color(0.06, 0.08, 0.06)
const CARD_BG_COLOR: Color = Color(0.12, 0.16, 0.12)
const CARD_BORDER_COLOR: Color = Color(0.25, 0.55, 0.2)
const BTN_BUY_COLOR: Color = Color(0.15, 0.6, 0.2)
const BTN_DISABLED_COLOR: Color = Color(0.3, 0.3, 0.3)
const GOLD_COLOR: Color = Color(1.0, 0.8, 0.1)

const UPGRADE_DEFS: Array = [
	{id = &"damage",         label = "DAÑO",      desc = "+5% daño por nivel"},
	{id = &"speed",          label = "CADENCIA",  desc = "+3% vel. disparo/nivel"},
	{id = &"health",         label = "VIDA",       desc = "+1 corazón por nivel"},
	{id = &"luck",           label = "SUERTE",    desc = "+5% XP por nivel"},
	{id = &"gold_bonus",     label = "BONUS ORO", desc = "+15% oro por partida/nivel"},
	{id = &"starter_shield", label = "ESCUDO",    desc = "+1 escudo inicial por nivel"},
]

var _gold_label: Label
var _buy_buttons: Dictionary = {}
var _level_labels: Dictionary = {}
var _cost_labels: Dictionary = {}

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
	top_pad.custom_minimum_size = Vector2(0.0, 28.0)
	root.add_child(top_pad)

	var title: Label = Label.new()
	title.text = "MEJORAS PERMANENTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", Color(0.3, 0.85, 0.2))
	root.add_child(title)

	var gold_row: HBoxContainer = HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_row.custom_minimum_size = Vector2(0.0, 36.0)
	root.add_child(gold_row)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override(&"font_size", 22)
	_gold_label.add_theme_color_override(&"font_color", GOLD_COLOR)
	gold_row.add_child(_gold_label)
	_refresh_gold_label()

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid_margin: MarginContainer = MarginContainer.new()
	grid_margin.add_theme_constant_override(&"margin_left", 14)
	grid_margin.add_theme_constant_override(&"margin_right", 14)
	grid_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_margin.add_child(grid)
	root.add_child(grid_margin)

	for def: Dictionary in UPGRADE_DEFS:
		_build_card(grid, def)

	var bottom_pad: Control = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0.0, 12.0)
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
	final_pad.custom_minimum_size = Vector2(0.0, 16.0)
	root.add_child(final_pad)

func _build_card(parent: Control, def: Dictionary) -> void:
	var upgrade_id: StringName = def.id as StringName
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = CARD_BG_COLOR
	card_style.border_color = CARD_BORDER_COLOR
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override(&"panel", card_style)
	parent.add_child(card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override(&"separation", 4)
	card.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = def.label as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override(&"font_size", 18)
	name_lbl.add_theme_color_override(&"font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(name_lbl)

	var level_lbl: Label = Label.new()
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_font_size_override(&"font_size", 14)
	level_lbl.add_theme_color_override(&"font_color", Color(0.6, 0.9, 0.6))
	_level_labels[upgrade_id] = level_lbl
	vbox.add_child(level_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = def.desc as String
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override(&"font_size", 11)
	desc_lbl.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var cost_lbl: Label = Label.new()
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override(&"font_size", 13)
	cost_lbl.add_theme_color_override(&"font_color", GOLD_COLOR)
	_cost_labels[upgrade_id] = cost_lbl
	vbox.add_child(cost_lbl)

	var btn: Button = Button.new()
	btn.text = "COMPRAR"
	btn.custom_minimum_size = Vector2(100.0, 36.0)
	btn.add_theme_font_size_override(&"font_size", 14)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	_buy_buttons[upgrade_id] = btn
	vbox.add_child(btn)

	_refresh_card(upgrade_id)

func _refresh_card(upgrade_id: StringName) -> void:
	var current_level: int = SaveManager.get_upgrade_level(upgrade_id)
	var is_maxed: bool = current_level >= Constants.META_MAX_UPGRADE_LEVEL
	var btn: Button = _buy_buttons[upgrade_id] as Button
	if is_maxed:
		(_level_labels[upgrade_id] as Label).text = "Nivel %d — MAX" % current_level
		(_cost_labels[upgrade_id] as Label).text = ""
		btn.text = "MAX"
		btn.disabled = true
		return
	var base: float = float(Constants.META_UPGRADE_COST_BASE)
	var growth: float = pow(Constants.META_UPGRADE_COST_GROWTH, float(current_level))
	var cost: int = int(base * growth)
	var can_afford: bool = SaveManager.get_gold() >= cost
	(_level_labels[upgrade_id] as Label).text = "Nivel %d" % current_level
	(_cost_labels[upgrade_id] as Label).text = "Costo: %d oro" % cost
	btn.text = "COMPRAR"
	btn.disabled = not can_afford
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = BTN_BUY_COLOR if can_afford else BTN_DISABLED_COLOR
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override(&"normal", sb)

func _refresh_gold_label() -> void:
	_gold_label.text = "Oro: %d" % SaveManager.get_gold()

func _on_buy_pressed(upgrade_id: StringName) -> void:
	if SaveManager.purchase_upgrade(upgrade_id):
		_refresh_gold_label()
		for def: Dictionary in UPGRADE_DEFS:
			_refresh_card(def.id as StringName)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_SCENE)

func get_gold_label() -> Label:
	return _gold_label

func get_buy_button(upgrade_id: StringName) -> Button:
	return _buy_buttons.get(upgrade_id) as Button
