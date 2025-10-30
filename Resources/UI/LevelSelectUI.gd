# LevelSelectUI.gd - FIXED: Deferred scene transition for exports + Unlock Dialogues
# Handles level selection with mushroom-based unlocking system (shop style)
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
		"total_enemies": 5,
		"description": "A peaceful farm with few enemies",
		"mushrooms_required": 0,  # Always unlocked
		"spawn_mode": "gradual",
		"boss_enabled": false  # No boss in level 1
	},
	{
		"name": "Farm - 2", 
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "normal",
		"max_enemies": 15,
		"spawn_interval": 2.0,
		"total_enemies": 25,
		"description": "Standard difficulty with BOSS at halfway!",
		"mushrooms_required": 10,
		"spawn_mode": "gradual",
		"boss_enabled": true,  # Boss spawns at halfway point
		"boss_spawn_at_halfway": true
	},
	{
		"name": "Farm - 3",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "hard",
		"max_enemies": 25,
		"spawn_interval": 1.0,
		"total_enemies": 50,
		"description": "Intense combat with BOSS at halfway!",
		"mushrooms_required": 15,
		"spawn_mode": "all_at_once",
		"boss_enabled": true,  # Boss spawns at halfway point
		"boss_spawn_at_halfway": true
	},
	{
		"name": "Farm - 4",
		"scene": "res://Resources/Scenes/farm.tscn",
		"difficulty": "extremely hard",
		"max_enemies": 40,
		"spawn_interval": 1.0,
		"total_enemies": 150,
		"description": "Wave after wave with BOSS at halfway!",
		"mushrooms_required": 25,
		"spawn_mode": "all_at_once",
		"boss_enabled": true,  # Boss spawns at halfway point
		"boss_spawn_at_halfway": true
	}
]

# Track which levels have been permanently unlocked
var unlocked_levels: Array = [true, false, false, false]  # Level 1 is always unlocked

# Track which levels have shown their unlock dialogue (per session/save)
var unlock_dialogues_shown: Array = [true, false, false, false]  # Level 1 doesn't need dialogue

# Preload the lock texture
var lock_texture: Texture2D = preload("res://Resources/Inventory/Sprites/lock.png")

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_unlocked_levels()
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
		# Tan/beige color
		title_label.add_theme_color_override("font_color", Color(0.87058824, 0.72156864, 0.5294118))
		# Add shadow with 0.5 opacity, offset (2,2), size 4
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 4)
		# Center the title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Center the level container
	if level_container:
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.custom_minimum_size = Vector2(500, 0)  # Minimum width for proper spacing
	
	if back_button:
		back_button.text = "BACK TO SAFEHOUSE"
		back_button.add_theme_font_override("font", pixel_font)

func _get_mushroom_count() -> int:
	"""Get the current mushroom count from the player's inventory"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_inventory_manager"):
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			return inv_mgr.get_item_quantity_by_name("Mushroom")
	return 0

func _load_unlocked_levels():
	"""Load unlocked levels from save data or pending load data"""
	# First check if there's data in pending_load_data (from returning to safehouse)
	if GameManager.pending_load_data.has("unlocked_levels"):
		var loaded_data = GameManager.pending_load_data.unlocked_levels
		if loaded_data is Array and loaded_data.size() == levels.size():
			unlocked_levels = loaded_data.duplicate()
			print("✓ Loaded unlocked levels from pending_load_data: ", unlocked_levels)
			return
	
	# Otherwise load from save file
	if GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
		if save_data.has("player") and save_data.player.has("unlocked_levels"):
			var loaded_data = save_data.player.unlocked_levels
			# Ensure we have the right number of levels
			if loaded_data is Array and loaded_data.size() == levels.size():
				unlocked_levels = loaded_data.duplicate()
				print("✓ Loaded unlocked levels from save file: ", unlocked_levels)
			else:
				print("⚠ Saved unlocked levels invalid, using defaults: ", unlocked_levels)
		else:
			print("ℹ No saved unlocked levels found, using defaults: ", unlocked_levels)
	else:
		print("⚠ No save slot selected, using default unlocked levels: ", unlocked_levels)

func _load_unlock_dialogues_shown():
	"""Load which unlock dialogues have been shown from save data"""
	if GameManager.current_save_slot >= 0:
		var save_data = SaveSystem.get_save_data(GameManager.current_save_slot)
		if save_data.has("player") and save_data.player.has("unlock_dialogues_shown"):
			var loaded_data = save_data.player.unlock_dialogues_shown
			if loaded_data is Array and loaded_data.size() == levels.size():
				unlock_dialogues_shown = loaded_data.duplicate()
				print("✓ Loaded unlock dialogues shown from save file: ", unlock_dialogues_shown)
			else:
				print("⚠ Saved unlock dialogues invalid, using defaults: ", unlock_dialogues_shown)
		else:
			print("ℹ No saved unlock dialogues found, using defaults: ", unlock_dialogues_shown)
	else:
		print("⚠ No save slot selected, using default unlock dialogues: ", unlock_dialogues_shown)

func _save_unlocked_levels():
	"""Save unlocked levels to save data immediately after purchase"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("✗ Cannot save unlocked levels - no player found")
		return
		
	if GameManager.current_save_slot < 0:
		print("✗ Cannot save unlocked levels - no save slot selected")
		return
	
	print("\n=== SAVING UNLOCKED LEVELS ===")
	print("Current unlocked_levels state: ", unlocked_levels)
	print("Current unlock_dialogues_shown state: ", unlock_dialogues_shown)
	
	# Collect all player data
	var player_data = SaveSystem.collect_player_data(player)
	
	# Add unlocked levels and dialogue tracking to the save data
	player_data["unlocked_levels"] = unlocked_levels.duplicate()
	player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
	
	print("Player data unlocked_levels field: ", player_data["unlocked_levels"])
	print("Player data unlock_dialogues_shown field: ", player_data["unlock_dialogues_shown"])
	
	# Save to file
	var success = SaveSystem.save_game(GameManager.current_save_slot, player_data)
	
	if success:
		print("✓ Successfully saved unlocked levels to slot ", GameManager.current_save_slot)
		
		# Verify the save by reading it back
		var verify_data = SaveSystem.get_save_data(GameManager.current_save_slot)
		if verify_data.has("player") and verify_data.player.has("unlocked_levels"):
			print("✓ Verification: Save file contains unlocked_levels: ", verify_data.player.unlocked_levels)
		else:
			print("✗ Verification FAILED: unlocked_levels not found in save file!")
	else:
		print("✗ Failed to save unlocked levels!")
	
	print("=== SAVE COMPLETE ===\n")

func _get_unlock_dialogue(level_index: int) -> Array:
	"""Get the unlock dialogue for a specific level"""
	match level_index:
		1:  # Farm - 2
			return [
				{
					"speaker": "Mysterious Voice",
					"text": "Feel proud of yourself?."
				},
			
			]
		2:  # Farm - 3
			return [
				{
					"speaker": "Mysterious Voice",
					"text": "Impressive work, nerd."
				}
			]
		3:  # Farm - 4
			return [
				{
					"speaker": "Mysterious Voice",
					"text": "Most people beat this level blindfolded with their monitor off. I bet you aren't one of them."
				},
			
			]
		_:
			return []

func _show_unlock_dialogue(level_index: int):
	"""Show the unlock dialogue for a newly unlocked level"""
	var dialogue_data = _get_unlock_dialogue(level_index)
	
	if dialogue_data.is_empty():
		print("No dialogue for level ", level_index)
		return
	
	print("Showing unlock dialogue for level ", level_index + 1)
	
	# Connect to dialogue ended signal
	if not TutorialManager.dialogue_ended.is_connected(_on_unlock_dialogue_ended.bind(level_index)):
		TutorialManager.dialogue_ended.connect(_on_unlock_dialogue_ended.bind(level_index))
	
	# Hide the level select UI while dialogue is showing
	panel.visible = false
	
	# CRITICAL FIX: Unpause the game so dialogue can receive input
	get_tree().paused = false
	
	# Start the dialogue
	TutorialManager.start_dialogue(dialogue_data)

func _on_unlock_dialogue_ended(level_index: int):
	"""Called when unlock dialogue ends"""
	print("Unlock dialogue ended for level ", level_index + 1)
	
	# Disconnect the signal
	if TutorialManager.dialogue_ended.is_connected(_on_unlock_dialogue_ended):
		TutorialManager.dialogue_ended.disconnect(_on_unlock_dialogue_ended)
	
	# Mark this dialogue as shown
	unlock_dialogues_shown[level_index] = true
	
	# Save the state
	_save_unlocked_levels()
	
	# CRITICAL FIX: Re-pause the game since level select should still be open
	get_tree().paused = true
	
	# Show the level select UI again
	panel.visible = true
	
	# Refresh buttons to show the newly unlocked level
	_refresh_buttons()

func _spend_mushrooms_to_unlock(level_index: int) -> bool:
	"""Attempt to spend mushrooms to unlock a level"""
	var level_data = levels[level_index]
	var mushroom_count = _get_mushroom_count()
	
	print("\n=== ATTEMPTING TO UNLOCK LEVEL ", level_index + 1, " ===")
	print("Required mushrooms: ", level_data.mushrooms_required)
	print("Available mushrooms: ", mushroom_count)
	
	if mushroom_count >= level_data.mushrooms_required:
		# Remove mushrooms from inventory
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("get_inventory_manager"):
			var inv_mgr = player.get_inventory_manager()
			if inv_mgr:
				# Find and create a mushroom item to remove
				var mushroom_item = _find_mushroom_item_in_inventory(inv_mgr)
				if mushroom_item:
					inv_mgr.remove_item(mushroom_item, level_data.mushrooms_required)
					print("✓ Removed ", level_data.mushrooms_required, " mushrooms from inventory")
					
					# Mark level as unlocked
					unlocked_levels[level_index] = true
					print("✓ Level ", level_index + 1, " marked as unlocked")
					
					# Check if we should show the unlock dialogue
					var should_show_dialogue = not unlock_dialogues_shown[level_index]
					
					# Save immediately (before showing dialogue)
					_save_unlocked_levels()
					
					print("✓ Level ", level_index + 1, " unlocked! Spent ", level_data.mushrooms_required, " mushrooms")
					
					# Show unlock dialogue if this is the first time
					if should_show_dialogue:
						_show_unlock_dialogue(level_index)
					else:
						# Just refresh buttons if dialogue already shown
						_refresh_buttons()
					
					return true
				else:
					print("✗ Could not find mushroom item in inventory")
			else:
				print("✗ No inventory manager found")
		else:
			print("✗ Player not found or doesn't have get_inventory_manager method")
	else:
		print("✗ Not enough mushrooms")
	
	return false

func _find_mushroom_item_in_inventory(inv_mgr) -> Item:
	"""Find the mushroom item in the inventory"""
	for i in range(inv_mgr.max_slots):
		if inv_mgr.items[i] != null and inv_mgr.items[i].name == "Mushroom":
			return inv_mgr.items[i]
	return null

func _create_level_buttons():
	var mushroom_count = _get_mushroom_count()
	
	for i in range(levels.size()):
		var level_data = levels[i]
		var is_unlocked = unlocked_levels[i]
		var can_afford = mushroom_count >= level_data.mushrooms_required
		
		# Create a container for the button and lock overlay
		var button_container = CenterContainer.new()
		button_container.custom_minimum_size = Vector2(300, 60)
		
		# Create the button
		var button = Button.new()
		button.custom_minimum_size = Vector2(300, 60)
		button.size = Vector2(300, 60)
		button.position = Vector2(0, 0)
		
		# Set button text - add boss indicator for levels with bosses
		var boss_indicator = " 👹" if level_data.get("boss_enabled", false) else ""
		if is_unlocked:
			button.text = level_data.name + boss_indicator
		else:
			var can_afford_text = " ✓" if can_afford else " ✗"
			button.text = level_data.name + boss_indicator + "\n[" + str(level_data.mushrooms_required) + " Mushrooms" + can_afford_text + "]"
		
		var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", 18)
		
		# Color based on difficulty
		var color = Color(0.3, 0.7, 0.3)
		match level_data.difficulty:
			"normal": color = Color(0.7, 0.7, 0.3)
			"hard": color = Color(0.7, 0.3, 0.3)
			"extremely hard": color = Color(0.5, 0.1, 0.1)
		
		# If locked and can't afford, darken the button
		if not is_unlocked and not can_afford:
			color = color.darkened(0.5)
		
		_style_button(button, color)
		
		# Connect button press
		if is_unlocked:
			button.pressed.connect(_on_level_selected.bind(level_data))
		else:
			# This is the "purchase" button
			button.pressed.connect(_on_purchase_level.bind(i))
		
		button_container.add_child(button)
		
		# Add lock icon overlay if level is locked
		if not is_unlocked:
			var lock_icon = TextureRect.new()
			lock_icon.texture = lock_texture
			lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_icon.custom_minimum_size = Vector2(50, 50)
			# Anchor to the right side of the button
			lock_icon.position = Vector2(240, 5)  # 300 - 50 - 10 = 240
			lock_icon.size = Vector2(50, 50)
			lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through
			button_container.add_child(lock_icon)
		
		level_container.add_child(button_container)

func _on_purchase_level(level_index: int):
	"""Called when player clicks a locked level to purchase it"""
	var level_data = levels[level_index]
	var mushroom_count = _get_mushroom_count()
	
	if mushroom_count >= level_data.mushrooms_required:
		if _spend_mushrooms_to_unlock(level_index):
			print("✓ Successfully unlocked ", level_data.name)
			# Don't refresh here if dialogue is being shown
			# _refresh_buttons() is called after dialogue ends
		else:
			print("✗ Failed to unlock level")
	else:
		print("✗ Not enough mushrooms! Need ", level_data.mushrooms_required, " but only have ", mushroom_count)

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
	
	# Reload unlocked levels when opening to get latest state
	_load_unlocked_levels()
	_load_unlock_dialogues_shown()
	
	# Refresh the buttons when opening to show current unlock status
	_refresh_buttons()

func _refresh_buttons():
	"""Refresh button states based on current mushroom count and unlocked status"""
	# Clear existing buttons
	for child in level_container.get_children():
		child.queue_free()
	
	# Recreate buttons with updated unlock status
	_create_level_buttons()

func close():
	visible = false
	get_tree().paused = false

func _on_level_selected(level_data: Dictionary):
	print("\n🎮 === LEVEL SELECTED ===")
	print("Level name: ", level_data.name)
	print("Level data: ", level_data)
	
	# CRITICAL FIX: Store level settings FIRST, before anything else
	GameManager.current_level_settings = level_data.duplicate()
	print("✓ GameManager.current_level_settings set: ", GameManager.current_level_settings)
	
	# Extract level number from name ("Farm - 1" -> 1)
	var level_name = level_data.name
	var parts = level_name.split(" - ")
	if parts.size() >= 2:
		GameManager.current_level = int(parts[1])
	else:
		GameManager.current_level = 1
	
	print("✓ Level number: ", GameManager.current_level)
	print("✓ Boss enabled: ", level_data.get("boss_enabled", false))
	
	# Notify tutorial if it exists
	var intro_tutorial = get_tree().root.get_node_or_null("Safehouse/IntroTutorial")
	if intro_tutorial and intro_tutorial.has_method("on_level_started"):
		intro_tutorial.on_level_started(GameManager.current_level)
	
	# Auto-save before transition
	var player = get_tree().get_first_node_in_group("player")
	if player and GameManager.current_save_slot >= 0:
		print("💾 Auto-saving before farm transition...")
		var player_data = SaveSystem.collect_player_data(player)
		player_data["unlocked_levels"] = unlocked_levels.duplicate()
		player_data["unlock_dialogues_shown"] = unlock_dialogues_shown.duplicate()
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("✓ Auto-save complete")
		
		# Load the save back into pending_load_data
		var save_data = SaveSystem.load_game(GameManager.current_save_slot)
		if not save_data.is_empty():
			GameManager.pending_load_data = save_data
			print("✓ Save data loaded into pending_load_data")
	
	close()
	
	# CRITICAL FIX: Wait a frame before scene transition
	# This ensures GameManager.current_level_settings is fully propagated
	print("⏳ Waiting one frame before scene transition...")
	await get_tree().process_frame
	
	print("🚀 Transitioning to farm scene...")
	print("Final check - GameManager.current_level_settings: ", GameManager.current_level_settings)
	
	get_tree().change_scene_to_file(level_data.scene)
	
	print("=== LEVEL TRANSITION INITIATED ===\n")

func _on_back_pressed():
	close()
