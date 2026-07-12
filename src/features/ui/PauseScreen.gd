class_name PauseScreen
extends CanvasLayer
## Pause overlay. process_mode=ALWAYS so buttons receive input while tree is paused.
## "Ir al menú" shows a confirmation panel before abandoning the session.

var _panel: Control
var _resume_btn: Button
var _menu_btn: Button
var _confirm_panel: Control
var _confirm_cancel_btn: Button
var _confirm_exit_btn: Button

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_build_confirm_panel()
	hide()
	EventBus.game_paused.connect(_on_game_paused)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = Control.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -120.0
	_panel.offset_right = 120.0
	_panel.offset_top = -110.0
	_panel.offset_bottom = 110.0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "JUEGO PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	_resume_btn = Button.new()
	_resume_btn.text = "CONTINUAR"
	_resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(_resume_btn)

	_menu_btn = Button.new()
	_menu_btn.text = "MENU PRINCIPAL"
	_menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(_menu_btn)

func _build_confirm_panel() -> void:
	_confirm_panel = Control.new()
	_confirm_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.hide()
	add_child(_confirm_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.add_child(dim)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -130.0
	box.offset_right = 130.0
	box.offset_top = -80.0
	box.offset_bottom = 80.0
	_confirm_panel.add_child(box)

	var warning := Label.new()
	warning.text = "Si sales ahora\nperderás el avance\nde la partida."
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	box.add_child(warning)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)

	_confirm_cancel_btn = Button.new()
	_confirm_cancel_btn.text = "CANCELAR"
	_confirm_cancel_btn.pressed.connect(_on_confirm_cancel_pressed)
	buttons.add_child(_confirm_cancel_btn)

	_confirm_exit_btn = Button.new()
	_confirm_exit_btn.text = "SALIR"
	_confirm_exit_btn.pressed.connect(_on_confirm_exit_pressed)
	buttons.add_child(_confirm_exit_btn)

func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		show()
	else:
		hide()
		_confirm_panel.hide()

func _on_resume_pressed() -> void:
	GameManager.resume_game()

func _on_menu_pressed() -> void:
	_confirm_panel.show()

func _on_confirm_cancel_pressed() -> void:
	_confirm_panel.hide()

func _on_confirm_exit_pressed() -> void:
	_confirm_panel.hide()
	GameManager.resume_game()
	EventBus.menu_requested.emit()

func get_panel() -> Control:
	return _panel

func get_resume_button() -> Button:
	return _resume_btn

func get_menu_button() -> Button:
	return _menu_btn

func get_confirm_panel() -> Control:
	return _confirm_panel

func get_confirm_cancel_button() -> Button:
	return _confirm_cancel_btn

func get_confirm_exit_button() -> Button:
	return _confirm_exit_btn
