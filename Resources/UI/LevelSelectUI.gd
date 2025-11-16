# LevelSelectUI.gd - INFINITE LEVELS VERSION
# Procedurally generates level configurations for unlimited progression
extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var scroll_container = $Panel/VBoxContainer/ScrollContainer
@onready var level_container = $Panel/VBoxContainer/ScrollContainer/LevelContainer
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var progress_label = $Panel/VBoxContainer/ProgressLabel

# How many levels to display at once (can scroll for more)
const LEVELS_TO_DISPLAY = 20

# Track which levels have been completed
var completed_levels: Array = []

# Track which levels have shown their unlock dialogue
var unlock_dialogues_shown: Array = []

# Preload the lock texture
var lock_texture: Texture2D = preload("res://Resources/Inventory/Sprites/lock.png")

# Track highest level reached
var highest_level_reached: int = 1

func _ready():
	# Add to group so farm.gd can find it
	add_to_group("level_select_ui")
	
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_progress_from_save()
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
	
	# Style progress label
	if progress_label:
		progress_label.add_theme_font_override("font", pixel_font)
		progress_label.add_theme_font_size_override("font_size", 20)
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_update_progress_label()
	
	# Setup scroll container
	if scroll_container:
		scroll_container.custom_minimum_size = Vector2(500, 400)
	
	# Center the level container
	if level_container:
		level_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		level_container.custom_minimum_size = Vector2(480, 0)
	
	if back_button:
		back_button.text = "BACK"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)
		back_button.custom_minimum_size = Vector2(200, 50)

func _update_progress_label():
	"""Update the progress label showing highest level reached"""
	if progress_label:
		progress_label.text = "Highest Level: %d" % highest_level_reached

func _create_level_buttons():
	"""Create buttons for levels dynamically"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Calculate how many levels to show (up to highest + 1, minimum LEVELS_TO_DISPLAY)
	var levels_to_show = max(highest_level_reached + 1, LEVELS_TO_DISPLAY)
	
	for i in range(1, levels_to_show + 1):
		var level_data = _generate_level_config(i)
		var is_unlocked = _is_level_unlocked(i)
		
		# Container for button + lock icon
		var button_container = Control.new()
		button_container.custom_minimum_size = Vector2(460, 70)
		
		# Create the level button
		var button = Button.new()
		button.text = level_data.name
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 18)
		button.custom_minimum_size = Vector2(460, 60)
		button.disabled = not is_unlocked
		
		# Color based on difficulty
		var color = _get_level_color(level_data.difficulty, i)
		
		_style_button(button, color)
		
		if is_unlocked:
			button.pressed.connect(_on_level_selected.bind(level_data, i))
		
		button_container.add_child(button)
		
		# Add lock icon if locked
		if not is_unlocked:
			var lock_icon = TextureRect.new()
			lock_icon.texture = lock_texture
			lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_icon.custom_minimum_size = Vector2(50, 50)
			lock_icon.position = Vector2(400, 5)
			lock_icon.size = Vector2(50, 50)
			lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button_container.add_child(lock_icon)
		
		level_container.add_child(button_container)

func _generate_level_config(level_num: int) -> Dictionary:
	"""Generate level configuration based on level number
	
	Scaling formulas:
	- Enemies per type: 2 + (level - 1) * 3
	- Total enemies: (enemies per type) * 4 types
	- Max concurrent: 10 + (level - 1) * 2
	- Spawn interval: max(0.5, 2.0 - (level - 1) * 0.1)
	"""
	
	# Calculate enemy counts
	var enemies_per_type = 2 + (level_num - 1) * 3
	var total_enemies = enemies_per_type * 4  # 4 enemy types
	
	# Calculate concurrent enemy limit
	var max_enemies = 10 + (level_num - 1) * 2
	max_enemies = min(max_enemies, 50)  # Cap at 50 concurrent
	
	# Calculate spawn interval (faster over time)
	var spawn_interval = max(0.5, 2.0 - (level_num - 1) * 0.1)
	
	# Determine difficulty label
	var difficulty = _get_difficulty_name(level_num)
	
	# Check if this is a boss level
	var is_boss_level = (level_num % 5) == 0
	var boss_count = 1
	if (level_num % 10) == 0:
		boss_count = 2  # Every 10th level gets 2 bosses!
	
	# Build level name
	var level_name = "Farm - %d" % level_num
	if is_boss_level:
		if boss_count == 2:
			level_name += " (2 BOSSES!)"
		else:
			level_name += " (BOSS)"
	
	# Build description
	var description = "%d enemies per type" % enemies_per_type
	if is_boss_level:
		if boss_count == 2:
			description = "Epic battle with TWO bosses!"
		else:
			description = "Face the Pea Boss!"
	
	return {
		"name": level_name,
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": difficulty,
		"max_enemies": max_enemies,
		"spawn_interval": spawn_interval,
		"total_enemies": total_enemies,
		"description": description,
		"spawn_mode": "gradual",
		"boss_enabled": is_boss_level,
		"boss_count": boss_count if is_boss_level else 0,
		"boss_spawn_at_halfway": true,
		"level_number": level_num,
		# NEW: Batch spawning settings for MUCH faster gameplay
		"batch_spawn_enabled": true,
		"batch_size": 40,  # Increased from 20 to 30
		"batch_interval": 3.0  # Reduced from 5.0 to 3.0 seconds
	}

func _get_difficulty_name(level_num: int) -> String:
	"""Get difficulty name based on level number"""
	if level_num == 1:
		return "easy"
	elif level_num <= 3:
		return "normal"
	elif level_num <= 5:
		return "hard"
	elif level_num <= 10:
		return "very hard"
	elif level_num <= 20:
		return "extreme"
	elif level_num <= 30:
		return "insane"
	elif level_num <= 50:
		return "nightmare"
	else:
		return "impossible"

func _get_level_color(difficulty: String, level_num: int) -> Color:
	"""Get color based on difficulty and special levels"""
	# Special coloring for boss levels
	if (level_num % 10) == 0:
		return Color(0.8, 0.0, 0.8)  # Purple for double boss
	elif (level_num % 5) == 0:
		return Color(0.6, 0.0, 0.6)  # Dark purple for single boss
	
	# Standard difficulty colors
	match difficulty:
		"easy": return Color(0.4, 0.8, 0.4)
		"normal": return Color(0.4, 0.6, 0.8)
		"hard": return Color(0.8, 0.5, 0.2)
		"very hard": return Color(0.8, 0.2, 0.2)
		"extreme": return Color(0.9, 0.1, 0.1)
		"insane": return Color(0.7, 0.0, 0.0)
		"nightmare": return Color(0.5, 0.0, 0.2)
		"impossible": return Color(0.3, 0.0, 0.1)
		_: return Color(0.5, 0.5, 0.5)

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
	
	# Reload from save when opening
	_load_progress_from_save()
	
	_refresh_buttons()
	
	print("DEBUG: Level Select opened - highest level: ", highest_level_reached)

func _refresh_buttons():
	"""Refresh button states based on current completion status"""
	for child in level_container.get_children():
		child.queue_free()
	_create_level_buttons()
	_update_progress_label()

func close():
	visible = false
	get_tree().paused = false

func _on_level_selected(level_data: Dictionary, level_num: int):
	print("\n🎮 === LEVEL SELECTED ===")
	print("Level number: ", level_num)
	
	# Store level settings
	GameManager.current_level_settings = level_data.duplicate()
	GameManager.current_level = level_num
	
	print("✓ Level number: ", GameManager.current_level)
	print("✓ Boss enabled: ", level_data.get("boss_enabled", false))
	print("✓ Boss count: ", level_data.get("boss_count", 0))
	
	# Notify tutorial if it exists (for Level 1 tracking)
	var intro_tutorial = get_tree().root.get_node_or_null("Safehouse/IntroTutorial")
	if intro_tutorial and intro_tutorial.has_method("on_level_started"):
		intro_tutorial.on_level_started(GameManager.current_level)
	
	# Auto-save before transition
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		print("💾 Auto-saving before farm transition...")
		var player_data = SaveSystem.collect_player_data(player)
		player_data["highest_level_reached"] = highest_level_reached
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

func _load_progress_from_save():
	"""Load progress from save file - handles infinite levels"""
	# Reset to defaults first
	highest_level_reached = 1
	completed_levels = []
	unlock_dialogues_shown = []
	
	# First try pending_load_data
	if GameManager.pending_load_data.has("highest_level_reached"):
		highest_level_reached = GameManager.pending_load_data.highest_level_reached
		print("✓ Restored highest level from pending_load_data: ", highest_level_reached)
	
	if GameManager.pending_load_data.has("completed_levels"):
		completed_levels = GameManager.pending_load_data.completed_levels.duplicate()
		print("✓ Restored completed levels from pending_load_data")
	
	if GameManager.pending_load_data.has("unlock_dialogues_shown"):
		unlock_dialogues_shown = GameManager.pending_load_data.unlock_dialogues_shown.duplicate()
		print("✓ Restored unlock dialogues from pending_load_data")
	
	# If no pending data, try loading directly from save file
	if highest_level_reached == 1 and GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty() and save_data.has("player"):
			if save_data.player.has("highest_level_reached"):
				highest_level_reached = save_data.player.highest_level_reached
				print("✓ Restored highest level from save file: ", highest_level_reached)
			
			if save_data.player.has("completed_levels"):
				completed_levels = save_data.player.completed_levels.duplicate()
				print("✓ Restored completed levels from save file")
			
			if save_data.player.has("unlock_dialogues_shown"):
				unlock_dialogues_shown = save_data.player.unlock_dialogues_shown.duplicate()
				print("✓ Restored unlock dialogues from save file")
	
	print("ℹ Current highest level: ", highest_level_reached)
	print("ℹ Total completed levels: ", completed_levels.size())

func _save_level_progress():
	"""Save level completion progress"""
	if GameManager.current_save_slot >= 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var player_data = SaveSystem.collect_player_data(player)
			player_data["highest_level_reached"] = highest_level_reached
			player_data["completed_levels"] = completed_levels.duplicate()
			player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
			SaveSystem.save_game(GameManager.current_save_slot, player_data)
			print("✓ Level progress saved - highest: ", highest_level_reached)

func _is_level_unlocked(level_num: int) -> bool:
	"""Check if a level is unlocked - sequential unlocking"""
	if level_num == 1:
		return true  # Level 1 always unlocked
	
	# Level is unlocked if previous level is completed
	return level_num <= highest_level_reached

func mark_level_complete(level_number: int):
	"""Mark a level as completed - called from farm.gd"""
	print("✓ Level ", level_number, " marked as complete!")
	
	# Expand arrays if needed
	while completed_levels.size() < level_number:
		completed_levels.append(false)
	while unlock_dialogues_shown.size() < level_number:
		unlock_dialogues_shown.append(false)
	
	# Mark this level complete
	if level_number > 0 and level_number <= completed_levels.size():
		completed_levels[level_number - 1] = true
	
	# Update highest level reached
	if level_number >= highest_level_reached:
		highest_level_reached = level_number + 1
		print("🎉 NEW HIGHEST LEVEL REACHED: ", highest_level_reached)
	
	# Save progress
	_save_level_progress()
	
	# Check if next level should show dialogue
	var next_level = level_number + 1
	if next_level <= unlock_dialogues_shown.size():
		if not unlock_dialogues_shown[next_level - 1]:
			print("🎬 Level ", next_level, " unlocked!")
			unlock_dialogues_shown[next_level - 1] = true
			_save_level_progress()
