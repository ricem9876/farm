# LevelSelectUI.gd - ORIGINAL VERSION (before scene transition complexity)
# Simple level selection with completion-based progression
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
		"spawn_interval": 2.0,
		"total_enemies": 8,  # 2 of each x 4 types
		"description": "A peaceful farm with few enemies",
		"spawn_mode": "gradual",
		"boss_enabled": false
	},
	{
		"name": "Farm - 2", 
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "normal",
		"max_enemies": 15,
		"spawn_interval": 2.0,
		"total_enemies": 20,  # 5 of each x 4 types
		"description": "Standard difficulty",
		"spawn_mode": "gradual",
		"boss_enabled": false
	},
	{
		"name": "Farm - 3",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "hard",
		"max_enemies": 25,
		"spawn_interval": 1.5,
		"total_enemies": 32,  # 8 of each x 4 types
		"description": "Intense combat",
		"spawn_mode": "gradual",
		"boss_enabled": false
	},
	{
		"name": "Farm - 4",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "very hard",
		"max_enemies": 30,
		"spawn_interval": 1.0,
		"total_enemies": 44,  # 11 of each x 4 types
		"description": "Challenging waves",
		"spawn_mode": "gradual",
		"boss_enabled": false
	},
	{
		"name": "Farm - 5 (BOSS)",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "boss",
		"max_enemies": 35,
		"spawn_interval": 0.8,
		"total_enemies": 56,  # 14 of each x 4 types
		"description": "Face the Pea Boss!",
		"spawn_mode": "all_at_once",
		"boss_enabled": true,
		"boss_spawn_at_halfway": true
	}
]

# Track which levels have been completed
var completed_levels: Array = [false, false, false, false, false]

# Track which levels have shown their unlock dialogue
var unlock_dialogues_shown: Array = [true, false, false, false, false]  # Level 1 doesn't need dialogue

# Preload the lock texture
var lock_texture: Texture2D = preload("res://Resources/Inventory/Sprites/lock.png")

func _ready():
	# Add to group so farm.gd can find it
	add_to_group("level_select_ui")
	
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_completed_levels()
	_load_unlock_dialogues_shown()
	_setup_ui()
	_create_level_buttons()
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style the title label
	if title_label:
		title_label.text = "SELECT MISSION"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color(0.87, 0.72, 0.53))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 4)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Center the level container
	if level_container:
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.custom_minimum_size = Vector2(500, 0)
	
	if back_button:
		back_button.text = "BACK"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)
		back_button.custom_minimum_size = Vector2(200, 50)

func _create_level_buttons():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	for i in range(levels.size()):
		var level = levels[i]
		var is_unlocked = _is_level_unlocked(i)
		
		# Container for button + lock icon
		var button_container = Control.new()
		button_container.custom_minimum_size = Vector2(300, 70)
		
		# Create the level button
		var button = Button.new()
		button.text = level.name
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 20)
		button.custom_minimum_size = Vector2(300, 60)
		button.disabled = not is_unlocked
		
		# Color based on difficulty
		var color = Color.GREEN
		match level.difficulty:
			"easy": color = Color(0.4, 0.8, 0.4)
			"normal": color = Color(0.4, 0.6, 0.8)
			"hard": color = Color(0.8, 0.5, 0.2)
			"very hard": color = Color(0.8, 0.2, 0.2)
			"boss": color = Color(0.6, 0.0, 0.6)
		
		_style_button(button, color)
		
		if is_unlocked:
			button.pressed.connect(_on_level_selected.bind(level))
		
		button_container.add_child(button)
		
		# Add lock icon if locked
		if not is_unlocked:
			var lock_icon = TextureRect.new()
			lock_icon.texture = lock_texture
			lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_icon.custom_minimum_size = Vector2(50, 50)
			lock_icon.position = Vector2(240, 5)
			lock_icon.size = Vector2(50, 50)
			lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button_container.add_child(lock_icon)
		
		level_container.add_child(button_container)

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
	
	var disabled = normal_style.duplicate()
	disabled.bg_color = color.darkened(0.5)
	button.add_theme_stylebox_override("disabled", disabled)

func open():
	visible = true
	get_tree().paused = true
	
	# CRITICAL: Reload from pending_load_data or save file when opening
	_load_completed_levels()
	_load_unlock_dialogues_shown()
	
	_refresh_buttons()
	
	print("DEBUG: Level Select opened with completed_levels: ", completed_levels)

func _refresh_buttons():
	"""Refresh button states based on current completion status"""
	for child in level_container.get_children():
		child.queue_free()
	_create_level_buttons()

func close():
	visible = false
	get_tree().paused = false

func _on_level_selected(level_data: Dictionary):
	print("\n🎮 === LEVEL SELECTED ===")
	print("Level name: ", level_data.name)
	
	# Store level settings
	GameManager.current_level_settings = level_data.duplicate()
	
	# Extract level number
	var level_name = level_data.name
	var parts = level_name.split(" - ")
	if parts.size() >= 2:
		GameManager.current_level = int(parts[1].split(" ")[0])  # Handle "5 (BOSS)"
	else:
		GameManager.current_level = 1
	
	print("✓ Level number: ", GameManager.current_level)
	print("✓ Boss enabled: ", level_data.get("boss_enabled", false))
	
	# Notify tutorial if it exists (for Level 1 tracking)
	var intro_tutorial = get_tree().root.get_node_or_null("Safehouse/IntroTutorial")
	if intro_tutorial and intro_tutorial.has_method("on_level_started"):
		intro_tutorial.on_level_started(GameManager.current_level)
	
	# Auto-save before transition
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		print("💾 Auto-saving before farm transition...")
		var player_data = SaveSystem.collect_player_data(player)
		player_data["completed_levels"] = completed_levels.duplicate()
		player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("✓ Auto-save complete")
		
		# Load the save back
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty():
			GameManager.pending_load_data = save_data
			print("✓ Save data loaded into pending_load_data")
	
	close()
	
	# Simple scene transition
	get_tree().change_scene_to_file(level_data.scene)

func _on_back_pressed():
	close()

func _load_completed_levels():
	"""Load completed levels from save file"""
	# First try pending_load_data
	if GameManager.pending_load_data.has("completed_levels"):
		completed_levels = GameManager.pending_load_data.completed_levels.duplicate()
		print("✓ Restored completed levels from pending_load_data: ", completed_levels)
		return
	
	# If no pending data, try loading directly from save file
	if GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty() and save_data.has("player"):
			if save_data.player.has("completed_levels"):
				completed_levels = save_data.player.completed_levels.duplicate()
				print("✓ Restored completed levels from save file: ", completed_levels)
				return
	
	# Default fallback
	print("ℹ No saved completed levels found, using defaults: ", completed_levels)

func _load_unlock_dialogues_shown():
	"""Load unlock dialogue shown status from save file"""
	# First try pending_load_data
	if GameManager.pending_load_data.has("unlock_dialogues_shown"):
		unlock_dialogues_shown = GameManager.pending_load_data.unlock_dialogues_shown.duplicate()
		print("✓ Restored unlock dialogues shown from pending_load_data: ", unlock_dialogues_shown)
		return
	
	# If no pending data, try loading directly from save file
	if GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty() and save_data.has("player"):
			if save_data.player.has("unlock_dialogues_shown"):
				unlock_dialogues_shown = save_data.player.unlock_dialogues_shown.duplicate()
				print("✓ Restored unlock dialogues shown from save file: ", unlock_dialogues_shown)
				return
	
	# Default fallback
	print("ℹ No saved unlock dialogues found, using defaults: ", unlock_dialogues_shown)

func _save_level_progress():
	"""Save level completion progress"""
	if GameManager.current_save_slot >= 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var player_data = SaveSystem.collect_player_data(player)
			player_data["completed_levels"] = completed_levels.duplicate()
			player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
			SaveSystem.save_game(GameManager.current_save_slot, player_data)
			print("✓ Level progress saved")

func _is_level_unlocked(level_index: int) -> bool:
	"""Check if a level is unlocked"""
	if level_index == 0:
		return true  # Level 1 always unlocked
	return completed_levels[level_index - 1]

func mark_level_complete(level_number: int):
	"""Mark a level as completed (called from farm.gd)"""
	var level_index = level_number - 1
	if level_index >= 0 and level_index < completed_levels.size():
		if not completed_levels[level_index]:
			completed_levels[level_index] = true
			print("✓ Level ", level_number, " marked as complete!")
			
			# Save progress
			_save_level_progress()
			
			# Check if next level should show dialogue
			if level_index + 1 < levels.size():
				if not unlock_dialogues_shown[level_index + 1]:
					print("🎬 Next level unlocked, would show dialogue here")
					unlock_dialogues_shown[level_index + 1] = true
					_save_level_progress()
