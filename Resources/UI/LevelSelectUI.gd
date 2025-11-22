# LevelSelectUI.gd - INFINITE LEVELS VERSION - COZY FARM STYLED - MEMORY LEAK FIXED
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

# Cozy farm color palette
const BG_COLOR = Color(0.86, 0.72, 0.52)  # Tan/beige background
const SAGE_GREEN = Color(0.4, 0.6, 0.4)  # Sage green for title
const TEXT_COLOR = Color(0.2, 0.2, 0.2)  # Dark text
const BUTTON_BG = Color(0.95, 0.88, 0.7)  # Light tan for buttons
const BUTTON_BORDER = Color(0.3, 0.2, 0.1)  # Dark brown border

# MEMORY LEAK FIX: Cache all StyleBox objects
var _button_style_normal: StyleBoxFlat = null
var _button_style_hover: StyleBoxFlat = null
var _button_style_pressed: StyleBoxFlat = null
var _panel_style: StyleBoxFlat = null
var _styles_created: bool = false

func _ready():
	# CRITICAL: Prevent running in editor
	if Engine.is_editor_hint():
		return
	
	# Add to group so farm.gd can find it
	add_to_group("level_select_ui")
	
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create all StyleBox objects ONCE
	_create_cached_styles()
	
	_load_progress_from_save()
	_setup_ui()
	_create_level_buttons()
	
	# Disconnect first if already connected
	if back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.disconnect(_on_back_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _create_cached_styles():
	"""Create all StyleBox objects ONCE to prevent memory leaks"""
	if _styles_created:
		return
	
	print("Creating cached StyleBox objects for LevelSelectUI...")
	
	# Button styles (for back button and general buttons)
	_button_style_normal = StyleBoxFlat.new()
	_button_style_normal.bg_color = BUTTON_BG
	_button_style_normal.border_color = BUTTON_BORDER
	_button_style_normal.border_width_left = 2
	_button_style_normal.border_width_right = 2
	_button_style_normal.border_width_top = 2
	_button_style_normal.border_width_bottom = 2
	_button_style_normal.corner_radius_top_left = 4
	_button_style_normal.corner_radius_top_right = 4
	_button_style_normal.corner_radius_bottom_left = 4
	_button_style_normal.corner_radius_bottom_right = 4
	
	_button_style_hover = StyleBoxFlat.new()
	_button_style_hover.bg_color = Color(1.0, 0.95, 0.8)
	_button_style_hover.border_color = BUTTON_BORDER
	_button_style_hover.border_width_left = 2
	_button_style_hover.border_width_right = 2
	_button_style_hover.border_width_top = 2
	_button_style_hover.border_width_bottom = 2
	_button_style_hover.corner_radius_top_left = 4
	_button_style_hover.corner_radius_top_right = 4
	_button_style_hover.corner_radius_bottom_left = 4
	_button_style_hover.corner_radius_bottom_right = 4
	
	_button_style_pressed = StyleBoxFlat.new()
	_button_style_pressed.bg_color = Color(0.85, 0.78, 0.6)
	_button_style_pressed.border_color = BUTTON_BORDER
	_button_style_pressed.border_width_left = 2
	_button_style_pressed.border_width_right = 2
	_button_style_pressed.border_width_top = 2
	_button_style_pressed.border_width_bottom = 2
	_button_style_pressed.corner_radius_top_left = 4
	_button_style_pressed.corner_radius_top_right = 4
	_button_style_pressed.corner_radius_bottom_left = 4
	_button_style_pressed.corner_radius_bottom_right = 4
	
	# Panel style
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = BG_COLOR
	_panel_style.border_color = BUTTON_BORDER
	_panel_style.border_width_left = 3
	_panel_style.border_width_right = 3
	_panel_style.border_width_top = 3
	_panel_style.border_width_bottom = 3
	_panel_style.corner_radius_top_left = 8
	_panel_style.corner_radius_top_right = 8
	_panel_style.corner_radius_bottom_left = 8
	_panel_style.corner_radius_bottom_right = 8
	
	_styles_created = true
	print("✓ Cached StyleBox objects created for LevelSelectUI")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style the main panel with CACHED style
	if panel and _panel_style:
		panel.add_theme_stylebox_override("panel", _panel_style)
	
	# Style the title label
	if title_label:
		title_label.text = "SELECT MISSION"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", SAGE_GREEN)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 4)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style progress label
	if progress_label:
		progress_label.add_theme_font_override("font", pixel_font)
		progress_label.add_theme_font_size_override("font_size", 20)
		progress_label.add_theme_color_override("font_color", TEXT_COLOR)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_update_progress_label()
	
	# Setup scroll container
	if scroll_container:
		scroll_container.custom_minimum_size = Vector2(500, 400)
	
	# Center the level container
	if level_container:
		level_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		level_container.custom_minimum_size = Vector2(480, 0)
	
	# Style back button with CACHED styles
	if back_button:
		back_button.text = "BACK"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)
		back_button.add_theme_color_override("font_color", TEXT_COLOR)
		back_button.custom_minimum_size = Vector2(200, 50)
		_apply_cached_button_style(back_button)

func _apply_cached_button_style(button: Button):
	"""Apply CACHED button styling - NO memory leak!"""
	button.add_theme_stylebox_override("normal", _button_style_normal)
	button.add_theme_stylebox_override("hover", _button_style_hover)
	button.add_theme_stylebox_override("pressed", _button_style_pressed)

func _update_progress_label():
	"""Update the progress label showing highest level reached"""
	if progress_label:
		progress_label.text = "Highest Level: %d" % highest_level_reached

func _create_level_buttons():
	"""Create buttons for levels dynamically - MEMORY LEAK FIXED"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Calculate how many levels to show
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
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.custom_minimum_size = Vector2(460, 60)
		button.disabled = not is_unlocked
		
		# Get color for this level
		var color = _get_level_color(level_data.difficulty, i)
		
		# Apply styled button - creates NEW StyleBox for each button but only when creating buttons
		# This is unavoidable since each level needs a different color
		_style_level_button(button, color, is_unlocked)
		
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
	"""Generate level configuration based on level number"""
	var enemies_per_type = 2 + (level_num - 1) * 3
	var total_enemies = enemies_per_type * 4
	var max_enemies = 10 + (level_num - 1) * 2
	max_enemies = min(max_enemies, 50)
	var spawn_interval = max(0.5, 2.0 - (level_num - 1) * 0.1)
	var difficulty = _get_difficulty_name(level_num)
	var is_boss_level = (level_num % 5) == 0
	var boss_count = 1
	if (level_num % 10) == 0:
		boss_count = 2
	
	var level_name = "Farm - %d" % level_num
	if is_boss_level:
		if boss_count == 2:
			level_name += " (2 BOSSES!)"
		else:
			level_name += " (BOSS)"
	
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
		"batch_spawn_enabled": true,
		"batch_size": 40,
		"batch_interval": 3.0
	}

func _get_difficulty_name(level_num: int) -> String:
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
	if (level_num % 10) == 0:
		return Color(0.3, 0.55, 0.35)
	elif (level_num % 5) == 0:
		return Color(0.4, 0.6, 0.4)
	
	match difficulty:
		"easy": return Color(0.6, 0.7, 0.5)
		"normal": return Color(0.7, 0.6, 0.4)
		"hard": return Color(0.75, 0.55, 0.35)
		"very hard": return Color(0.7, 0.45, 0.3)
		"extreme": return Color(0.65, 0.4, 0.25)
		"insane": return Color(0.6, 0.35, 0.2)
		"nightmare": return Color(0.55, 0.3, 0.2)
		"impossible": return Color(0.45, 0.25, 0.15)
		_: return Color(0.5, 0.5, 0.4)

func _style_level_button(button: Button, color: Color, is_unlocked: bool):
	"""Style level buttons - NOTE: Must create new StyleBox per button for different colors"""
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = BUTTON_BORDER
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover = normal_style.duplicate()
	hover.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover)
	
	var disabled = normal_style.duplicate()
	disabled.bg_color = color.darkened(0.4)
	disabled.border_color = BUTTON_BORDER.darkened(0.2)
	button.add_theme_stylebox_override("disabled", disabled)

func open():
	visible = true
	get_tree().paused = true
	_load_progress_from_save()
	_refresh_buttons()
	print("DEBUG: Level Select opened - highest level: ", highest_level_reached)

func _refresh_buttons():
	"""Refresh button states - WARNING: This recreates all buttons and their StyleBoxes"""
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
	
	GameManager.current_level_settings = level_data.duplicate()
	GameManager.current_level = level_num
	
	print("✓ Level number: ", GameManager.current_level)
	print("✓ Boss enabled: ", level_data.get("boss_enabled", false))
	print("✓ Boss count: ", level_data.get("boss_count", 0))
	
	var intro_tutorial = get_tree().root.get_node_or_null("Safehouse/IntroTutorial")
	if intro_tutorial and intro_tutorial.has_method("on_level_started"):
		intro_tutorial.on_level_started(GameManager.current_level)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		print("💾 Auto-saving before farm transition...")
		var player_data = SaveSystem.collect_player_data(player)
		player_data["highest_level_reached"] = highest_level_reached
		player_data["completed_levels"] = completed_levels.duplicate()
		player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("✓ Auto-save complete")
		
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty():
			GameManager.pending_load_data = save_data
			print("✓ Save data loaded into pending_load_data")
	
	close()
	get_tree().change_scene_to_file(level_data.scene)

func _on_back_pressed():
	close()

func _load_progress_from_save():
	highest_level_reached = 1
	completed_levels = []
	unlock_dialogues_shown = []
	
	if GameManager.pending_load_data.has("highest_level_reached"):
		highest_level_reached = GameManager.pending_load_data.highest_level_reached
		print("✓ Restored highest level from pending_load_data: ", highest_level_reached)
	
	if GameManager.pending_load_data.has("completed_levels"):
		completed_levels = GameManager.pending_load_data.completed_levels.duplicate()
		print("✓ Restored completed levels from pending_load_data")
	
	if GameManager.pending_load_data.has("unlock_dialogues_shown"):
		unlock_dialogues_shown = GameManager.pending_load_data.unlock_dialogues_shown.duplicate()
		print("✓ Restored unlock dialogues from pending_load_data")
	
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
	if level_num == 1:
		return true
	return level_num <= highest_level_reached

func mark_level_complete(level_number: int):
	print("✓ Level ", level_number, " marked as complete!")
	
	while completed_levels.size() < level_number:
		completed_levels.append(false)
	while unlock_dialogues_shown.size() < level_number:
		unlock_dialogues_shown.append(false)
	
	if level_number > 0 and level_number <= completed_levels.size():
		completed_levels[level_number - 1] = true
	
	if level_number >= highest_level_reached:
		highest_level_reached = level_number + 1
		print("🎉 NEW HIGHEST LEVEL REACHED: ", highest_level_reached)
	
	_save_level_progress()
	
	var next_level = level_number + 1
	if next_level <= unlock_dialogues_shown.size():
		if not unlock_dialogues_shown[next_level - 1]:
			print("🎬 Level ", next_level, " unlocked!")
			unlock_dialogues_shown[next_level - 1] = true
			_save_level_progress()

func debug_unlock_next_level():
	var next_level = highest_level_reached
	
	print("\n=== DEBUG: UNLOCKING NEXT LEVEL ===")
	print("Current highest level: ", highest_level_reached)
	print("Unlocking level: ", next_level)
	
	while completed_levels.size() < next_level:
		completed_levels.append(false)
	while unlock_dialogues_shown.size() < next_level:
		unlock_dialogues_shown.append(false)
	
	if next_level > 1:
		completed_levels[next_level - 2] = true
	
	highest_level_reached = next_level + 1
	
	print("✓ Level ", next_level, " is now unlocked!")
	print("New highest level: ", highest_level_reached)
	
	_save_level_progress()
	
	if visible:
		_refresh_buttons()
	
	print("=== LEVEL UNLOCK COMPLETE ===")
