# LevelSelectUI.gd
# Handles level selection and triggers auto-save BEFORE scene transition
extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var level_container = $Panel/VBoxContainer/LevelContainer
@onready var back_button = $Panel/VBoxContainer/BackButton

var levels = [
	{
		"name": "Farm - 1",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "easy",
		"max_enemies": 10,
		"spawn_interval": 6.0,
		"description": "A peaceful farm with few enemies"
	},
	{
		"name": "Farm - 2", 
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "normal",
		"max_enemies": 15,
		"spawn_interval": 5.0,
		"description": "Standard difficulty"
	},
	{
		"name": "Farm - 3",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "hard",
		"max_enemies": 25,
		"spawn_interval": 3.0,
		"description": "Intense combat with many enemies"
	},
	{
		"name": "Farm - 4",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "extremely hard",
		"max_enemies": 99999,
		"spawn_interval": 0.2,
		"description": "They don't stop!!!"
	}
]

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_ui()
	_create_level_buttons()
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	if title_label:
		title_label.text = "SELECT MISSION"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	if back_button:
		back_button.text = "BACK TO SAFEHOUSE"
		back_button.add_theme_font_override("font", pixel_font)

func _create_level_buttons():
	for level_data in levels:
		var button = Button.new()
		button.text = level_data.name
		button.custom_minimum_size = Vector2(300, 60)
		
		var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 20)
		
		var color = Color(0.3, 0.7, 0.3)
		match level_data.difficulty:
			"normal": color = Color(0.7, 0.7, 0.3)
			"hard": color = Color(0.7, 0.3, 0.3)
		
		_style_button(button, color)
		button.pressed.connect(_on_level_selected.bind(level_data))
		level_container.add_child(button)

func _style_button(button: Button, color: Color):
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
	
	var hover = normal_style.duplicate()
	hover.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover)

func open():
	visible = true
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false

func _on_level_selected(level_data: Dictionary):
	print("Level selected: ", level_data.name)
	
	# Store level settings
	GameManager.current_level_settings = level_data
	
	# CRITICAL: Auto-save RIGHT HERE, before any scene changes
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		print("Auto-saving before farm transition...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("Auto-save complete - all data captured")
		
		# CRITICAL FIX: Load the save back into pending_load_data
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty():
			GameManager.pending_load_data = save_data
			print("Save data loaded into pending_load_data for farm")
	
	# Now it's safe to transition
	close()
	get_tree().change_scene_to_file(level_data.scene)

func _on_back_pressed():
	close()
