# LevelSelectUI.gd
extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var level_container = $Panel/VBoxContainer/LevelContainer
@onready var back_button = $Panel/VBoxContainer/BackButton

# Level definitions
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
		"spawn_interval": 1.0,
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
		
		# Style based on difficulty
		var color = Color(0.3, 0.7, 0.3)
		match level_data.difficulty:
			"1": color = Color(0.3, 0.7, 0.3)
			"2": color = Color(0.7, 0.7, 0.3)
			"3": color = Color(0.7, 0.3, 0.3)
		
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
	print("Selected level: ", level_data.name)
	
	# Save level settings to GameManager
	GameManager.current_level_settings = level_data
	
	# IMPORTANT: Save player state before changing scenes
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Save inventory
		if player.has_method("get_inventory_manager"):
			var inv_mgr = player.get_inventory_manager()
			if inv_mgr:
				GameManager.save_player_inventory(inv_mgr)
		
		# Save weapons
		if player.has_method("get_weapon_manager"):
			var wep_mgr = player.get_weapon_manager()
			if wep_mgr:
				GameManager.save_player_weapons(wep_mgr)
		
		# Save level system
		if player.level_system:
			GameManager.save_player_level_system(player.level_system)
	
	# Save all storage containers in safehouse
	var storage_containers = get_tree().get_nodes_in_group("storage_containers")
	for container in storage_containers:
		if container.has_method("get_storage_id") and container.has_method("get_storage_manager"):
			GameManager.save_storage_data(container.get_storage_id(), container.get_storage_manager())
	
	# Close UI and load level
	close()
	get_tree().change_scene_to_file(level_data.scene)

func _on_back_pressed():
	close()
