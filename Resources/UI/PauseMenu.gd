# PauseMenu.gd
extends CanvasLayer

@onready var menu_panel = $MenuPanel
@onready var title_label = $MenuPanel/VBoxContainer/TitleLabel
@onready var resume_button = $MenuPanel/VBoxContainer/ButtonContainer/ResumeButton
@onready var exit_button = $MenuPanel/VBoxContainer/ButtonContainer/ExitButton

const TITLE_SCREEN = "res://Resources/Scenes/TitleScreen.tscn"

func _ready():
	# Start hidden
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works even when paused
	
	_setup_ui()
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	print("PauseMenu initialized")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Title
	if title_label:
		title_label.text = "PAUSED"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Panel styling
	if menu_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.3, 0.6, 0.8)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		menu_panel.add_theme_stylebox_override("panel", style)
	
	# Style buttons
	_style_button(resume_button, "RESUME", Color(0.2, 0.7, 0.3), pixel_font)
	_style_button(exit_button, "EXIT TO TITLE", Color(0.7, 0.2, 0.2), pixel_font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	if not button:
		return
	
	button.text = text
	button.custom_minimum_size = Vector2(250, 50)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 24)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _input(event):
	if event.is_action_pressed("menu"):
		if visible:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func open_menu():
	print("Opening pause menu")
	visible = true
	get_tree().paused = true

func close_menu():
	print("Closing pause menu")
	visible = false
	get_tree().paused = false

func _on_resume_pressed():
	close_menu()

func _on_exit_pressed():
	print("Exiting to title screen...")
	
	# Save before exiting
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		var player_data = SaveSystem.collect_player_data(player)
		
		# Detect current scene
		var current_scene_path = get_tree().current_scene.scene_file_path
		if "safehouse" in current_scene_path.to_lower():
			player_data.current_scene = "safehouse"
		else:
			player_data.current_scene = "farm"
		
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("Game saved before exiting")
	
	# Unpause and return to title
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCREEN)
