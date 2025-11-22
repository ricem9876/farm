# ============================================
# CHARACTER SELECT UI (CharacterSelectUI.gd)
# ============================================
# PURPOSE: Character selection screen before starting a new game
#
# FEATURES:
# - Browse through available characters with < > buttons
# - Shows character portrait, name, and description
# - Displays all character stats
# - Confirm button to select character
# - Back button to return to save selection
#
# HOW TO ADD A NEW CHARACTER:
# Edit CharacterRegistry.gd and add a new character in _register_default_characters()
#
# HOW TO CHANGE CHARACTER STATS:
# Edit the character data in CharacterRegistry.gd
#
# HOW TO CHANGE CHARACTER PORTRAITS:
# Set the portrait property in CharacterData (in CharacterRegistry.gd)
# ============================================

extends Control

signal character_selected(character_data: CharacterData)

# UI Element References
@onready var character_name_label = $VBoxContainer/CharacterName  # Big character name at top
@onready var character_description = $VBoxContainer/Description  # Description text below name
@onready var character_portrait = $VBoxContainer/Portrait  # Character image
@onready var stats_container = $VBoxContainer/StatsContainer  # Container showing all stats
@onready var prev_button = $VBoxContainer/NavigationButtons/PrevButton  # < button
@onready var next_button = $VBoxContainer/NavigationButtons/NextButton  # > button
@onready var confirm_button = $VBoxContainer/ConfirmButton  # "SELECT CHARACTER" button
@onready var back_button = $VBoxContainer/BackButton  # "BACK" button


# Available characters loaded from CharacterRegistry
var available_characters: Array[CharacterData] = []
var current_index: int = 0  # Which character is currently displayed (0 = first)

func _ready():
	_load_characters()
	_setup_ui()
	_update_display()
	
	# Connect button signals
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui():
	"""Setup fonts and colors for UI elements"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Character name label - big gold text
	if character_name_label:
		character_name_label.add_theme_font_override("font", pixel_font)
		character_name_label.add_theme_font_size_override("font_size", 48)
		character_name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Description text - smaller white text
	if character_description:
		character_description.add_theme_font_override("font", pixel_font)
		character_description.add_theme_font_size_override("font_size", 20)
	
	# All buttons use the same font
	for button in [prev_button, next_button, confirm_button, back_button]:
		if button:
			button.add_theme_font_override("font", pixel_font)
			button.add_theme_font_size_override("font_size", 24)

func _load_characters():
	"""Load all available characters from CharacterRegistry"""
	# CharacterRegistry is an autoload singleton that contains all character definitions
	available_characters = CharacterRegistry.get_all_characters()
	
	if available_characters.is_empty():
		print("⚠ Warning: No characters found in CharacterRegistry!")
		# Create default character as fallback
		var default_char = CharacterData.new()
		default_char.character_id = "hero"
		default_char.character_name = "Hero"
		default_char.description = "Balanced stats, great for beginners"
		default_char.starting_health = 100.0
		default_char.starting_speed = 100.0
		default_char.starting_weapon = "Pistol"
		available_characters.append(default_char)
	else:
		print("✓ Loaded ", available_characters.size(), " characters from registry")

func _update_display():
	"""Update UI to show the currently selected character"""
	if available_characters.is_empty():
		return
	
	var character = available_characters[current_index]
	
	# Update character name
	if character_name_label:
		character_name_label.text = character.character_name
	
	# Update description
	if character_description:
		character_description.text = character.description
	
	# Update portrait image
	if character_portrait and character.portrait:
		character_portrait.texture = character.portrait
	
	# Update stats display
	_update_stats_display(character)
	
	# Update navigation buttons (disable if at first/last character)
	prev_button.disabled = (current_index == 0)
	next_button.disabled = (current_index == available_characters.size() - 1)

func _update_stats_display(character: CharacterData):
	"""
	Display all character stats in the stats container
	
	CUSTOMIZATION NOTE:
	To change how stats are displayed, modify the 'stats' array below.
	Format: [["Label", "Value"], ["Label", "Value"], ...]
	"""
	# Clear existing stat labels
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create array of stats to display
	# Format: [Label, Value]
	var stats = [
		["Health", str(character.starting_health)],
		["Speed", str(character.starting_speed)],
		["Damage", "x" + str(character.starting_damage_multiplier)],
		["Fire Rate", "x" + str(character.starting_fire_rate_multiplier)],
	]
	
	# Add bonus stats if they're greater than 0
	if character.bonus_crit_chance > 0:
		stats.append(["Crit Chance", "+" + str(character.bonus_crit_chance * 100) + "%"])
	if character.bonus_crit_damage > 0:
		stats.append(["Crit Damage", "+" + str(character.bonus_crit_damage * 100) + "%"])
	if character.bonus_luck > 0:
		stats.append(["Luck", "+" + str(character.bonus_luck * 100) + "%"])
	if character.bonus_xp_gain > 0:
		stats.append(["XP Gain", "+" + str(character.bonus_xp_gain * 100) + "%"])
	
	# Create a label for each stat
	for stat in stats:
		var label = Label.new()
		label.text = stat[0] + ": " + stat[1]
		label.add_theme_font_override("font", preload("res://Resources/Fonts/yoster.ttf"))
		label.add_theme_font_size_override("font_size", 18)
		stats_container.add_child(label)

func _on_prev_pressed():
	"""Go to previous character (< button)"""
	current_index = max(0, current_index - 1)
	_update_display()

func _on_next_pressed():
	"""Go to next character (> button)"""
	current_index = min(available_characters.size() - 1, current_index + 1)
	_update_display()

func _on_confirm_pressed():
	"""Confirm character selection and start game"""
	if available_characters.is_empty():
		return
	
	var selected_character = available_characters[current_index]
	print("Character selected: ", selected_character.character_name)
	
	# Store the selected character ID in GameManager
	GameManager.selected_character_id = selected_character.character_id
	
	# Emit signal (other systems can listen to this)
	character_selected.emit(selected_character)
	
	# Start the game - permadeath will be applied in safehouse after first save
	_start_game()
		
func _on_back_pressed():
	"""Return to save slot selection screen"""
	get_tree().change_scene_to_file("res://Resources/UI/SaveSelectScene.tscn")

func _start_game():
	"""Start the game with the selected character - loads safehouse scene"""
	const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

# Public method to add characters dynamically (if needed)
func add_character(character: CharacterData):
	"""Add a character to the selection screen at runtime"""
	available_characters.append(character)
	if available_characters.size() == 1:
		_update_display()


# ============================================
# HOW TO CUSTOMIZE THE CHARACTER SELECT SCREEN
# ============================================
#
# 1. ADD A NEW CHARACTER:
#    - Open: Resources/Scripts/CharacterRegistry.gd
#    - In _register_default_characters(), copy one of the existing character blocks
#    - Change the stats, name, description, etc.
#    - Example:
#      var my_character = CharacterData.new()
#      my_character.character_id = "ninja"
#      my_character.character_name = "Ninja"
#      my_character.description = "Fast and deadly"
#      my_character.starting_health = 70.0
#      my_character.starting_speed = 150.0
#      my_character.starting_damage_multiplier = 1.2
#      my_character.starting_fire_rate_multiplier = 1.4
#      my_character.starting_weapon = "Pistol"
#      my_character.bonus_crit_chance = 0.15  # +15% crit chance
#      register_character(my_character)
#
# 2. CHANGE CHARACTER STATS:
#    - Open: Resources/Scripts/CharacterRegistry.gd
#    - Find the character you want to edit
#    - Change the stat values:
#      - starting_health: Base HP (100 is default)
#      - starting_speed: Movement speed (100 is default)
#      - starting_damage_multiplier: Damage multiplier (1.0 = normal, 1.5 = +50%)
#      - starting_fire_rate_multiplier: Fire rate (1.0 = normal, 1.2 = +20% faster)
#      - bonus_crit_chance: Critical hit chance (0.1 = +10%)
#      - bonus_crit_damage: Critical damage bonus (0.3 = +30%)
#      - bonus_luck: Luck bonus (0.05 = +5%)
#      - bonus_xp_gain: XP gain bonus (0.2 = +20% more XP)
#
# 3. ADD CHARACTER PORTRAIT:
#    - Add your portrait image to the project (e.g., "portraits/ninja.png")
#    - In CharacterRegistry.gd, after creating the character:
#      my_character.portrait = preload("res://path/to/ninja.png")
#
# 4. CHANGE STARTING WEAPON:
#    - In CharacterRegistry.gd, set:
#      my_character.starting_weapon = "Pistol"  # or "Shotgun", "Assault Rifle", etc.
#
# 5. GIVE STARTING ITEMS:
#    - In CharacterRegistry.gd, after creating character:
#      var items: Array[Dictionary] = []
#      items.append({"name": "Wood", "quantity": 10})
#      items.append({"name": "Wolf Fur", "quantity": 5})
#      my_character.starting_items = items
#
# 6. CHANGE UI COLORS:
#    - In _setup_ui() function above, change:
#      Color(1, 0.9, 0.4) = Current gold color for name
#      Change to Color(R, G, B) where R, G, B are 0.0 to 1.0
#      Example: Color(1, 0, 0) = red, Color(0, 1, 0) = green
#
# 7. CHANGE FONT SIZE:
#    - In _setup_ui() function above, change:
#      .add_theme_font_size_override("font_size", 48)
#      Change 48 to your desired size (bigger number = bigger text)
#
# 8. CHANGE STAT DISPLAY FORMAT:
#    - In _update_stats_display() function above
#    - Modify the 'stats' array to change what's shown
#    - Example to add starting weapon:
#      stats.append(["Weapon", character.starting_weapon])
#
# ============================================
