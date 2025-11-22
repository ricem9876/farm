# ConfirmDeleteDialog.gd
extends Control

signal confirmed
signal cancelled

var message_label: Label
var confirm_button: Button
var cancel_button: Button

const BG_COLOR = Color(0.96, 0.93, 0.82)
const TEXT_COLOR = Color(0.05, 0.05, 0.05)
const BORDER_COLOR = Color(0.3, 0.2, 0.1)

func _init():
	# Build the UI in _init so it exists immediately
	_build_ui()

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	_setup_styling()

func _build_ui():
	"""Build the entire UI structure"""
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks on root
	z_index = 100
	
	# Background - blocks clicks behind dialog
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	# Make background close the dialog when clicked
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_cancel_pressed()
	)
	add_child(bg)
	
	# Panel
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -150)
	panel.custom_minimum_size = Vector2(500, 250)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	
	# VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Message label
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = "Confirm action?"
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(message_label)
	
	# Button container
	var button_hbox = HBoxContainer.new()
	button_hbox.name = "ButtonContainer"
	button_hbox.add_theme_constant_override("separation", 20)
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(button_hbox)
	
	# Confirm button
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "Delete"
	confirm_button.focus_mode = Control.FOCUS_ALL  # Enable focus
	button_hbox.add_child(confirm_button)
	
	# Cancel button
	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "Cancel"
	cancel_button.focus_mode = Control.FOCUS_ALL  # Enable focus
	button_hbox.add_child(cancel_button)

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	var panel = get_node("Panel")
	
	# Panel styling
	if panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR
		panel_style.border_width_left = 6
		panel_style.border_width_right = 6
		panel_style.border_width_top = 6
		panel_style.border_width_bottom = 6
		panel_style.border_color = BORDER_COLOR
		panel_style.corner_radius_top_left = 12
		panel_style.corner_radius_top_right = 12
		panel_style.corner_radius_bottom_left = 12
		panel_style.corner_radius_bottom_right = 12
		panel.add_theme_stylebox_override("panel", panel_style)
	
	# Message label
	if message_label:
		message_label.add_theme_font_override("font", pixel_font)
		message_label.add_theme_font_size_override("font_size", 28)
		message_label.add_theme_color_override("font_color", TEXT_COLOR)
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Confirm button (Delete - rustic brown)
	if confirm_button:
		confirm_button.add_theme_font_override("font", pixel_font)
		confirm_button.add_theme_font_size_override("font_size", 24)
		confirm_button.add_theme_color_override("font_color", TEXT_COLOR)
		confirm_button.custom_minimum_size = Vector2(150, 60)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.75, 0.5, 0.35)
		btn_style.border_width_left = 4
		btn_style.border_width_right = 4
		btn_style.border_width_top = 4
		btn_style.border_width_bottom = 4
		btn_style.border_color = BORDER_COLOR
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		confirm_button.add_theme_stylebox_override("normal", btn_style)
		
		var hover = btn_style.duplicate()
		hover.bg_color = Color(0.85, 0.6, 0.45)
		confirm_button.add_theme_stylebox_override("hover", hover)
		
		var pressed = btn_style.duplicate()
		pressed.bg_color = Color(0.65, 0.4, 0.25)
		confirm_button.add_theme_stylebox_override("pressed", pressed)
	
	# Cancel button (sage green)
	if cancel_button:
		cancel_button.add_theme_font_override("font", pixel_font)
		cancel_button.add_theme_font_size_override("font_size", 24)
		cancel_button.add_theme_color_override("font_color", TEXT_COLOR)
		cancel_button.custom_minimum_size = Vector2(150, 60)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.5, 0.7, 0.4)
		btn_style.border_width_left = 4
		btn_style.border_width_right = 4
		btn_style.border_width_top = 4
		btn_style.border_width_bottom = 4
		btn_style.border_color = BORDER_COLOR
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		cancel_button.add_theme_stylebox_override("normal", btn_style)
		
		var hover = btn_style.duplicate()
		hover.bg_color = Color(0.6, 0.8, 0.5)
		cancel_button.add_theme_stylebox_override("hover", hover)
		
		var pressed = btn_style.duplicate()
		pressed.bg_color = Color(0.4, 0.6, 0.3)
		cancel_button.add_theme_stylebox_override("pressed", pressed)

func show_dialog(message: String):
	"""Show the dialog with a custom message"""
	if message_label:
		message_label.text = message
	visible = true
	get_tree().paused = true

func _on_confirm_pressed():
	confirmed.emit()
	_close()

func _on_cancel_pressed():
	cancelled.emit()
	_close()

func _close():
	visible = false
	get_tree().paused = false
	queue_free()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
