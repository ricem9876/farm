# SaveSelectScreen.gd - SAFE VERSION (checks for methods before calling)
extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var slots_container = $VBoxContainer/SlotsContainer
@onready var back_button = $VBoxContainer/BackButton

var save_slot_scene = preload("res://Resources/UI/SaveSlotUI.tscn")
var selected_slot: int = -1
var permadeath_dialog = null
var pending_new_game_slot: int = -1

const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)  # Cream background
const TEXT_COLOR = Color(0.05, 0.05, 0.05)  # Very dark text
const TITLE_COLOR = Color(0.5, 0.7, 0.4)  # Sage green
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border

func _ready():
	_setup_ui()
	
	# CRITICAL FIX: Reset all global state when entering save select screen
	# This prevents save slot data from bleeding across slots
	_reset_global_state()
	
	_load_save_slots()
	
	back_button.pressed.connect(_on_back_pressed)
	
	# Create permadeath dialog - deferred to ensure it's fully ready
	call_deferred("_setup_permadeath_dialog")
	
func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Title - farm themed with shadow
	if title_label:
		title_label.text = "SELECT SAVE FILE"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", TITLE_COLOR)  # Sage green
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 4)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Back button - farm themed
	if back_button:
		back_button.text = "BACK TO MENU"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)
		back_button.add_theme_color_override("font_color", TEXT_COLOR)
		back_button.custom_minimum_size = Vector2(300, 60)
		
		# Rustic brown button
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
		back_button.add_theme_stylebox_override("normal", btn_style)
		
		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.85, 0.6, 0.45)
		back_button.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.65, 0.4, 0.25)
		back_button.add_theme_stylebox_override("pressed", pressed_style)
		
func _setup_permadeath_dialog():
	"""Setup permadeath dialog after scene is ready"""
	print("🔵 Starting dialog setup...")
	
	var dialog_scene = preload("uid://3w8sysbgqpel")
	permadeath_dialog = dialog_scene.instantiate()
	
	add_child(permadeath_dialog)
	print("🔵 Dialog added to tree")
	
	# Connect immediately without waiting
	if permadeath_dialog.has_signal("mode_selected"):
		permadeath_dialog.mode_selected.connect(_on_permadeath_mode_selected)
		print("✓ Permadeath dialog signal connected")
	else:
		print("⚠ Permadeath dialog missing mode_selected signal!")
	
	# Hide it after adding to tree
	permadeath_dialog.hide()
	print("✓ Permadeath dialog setup complete and hidden")
	
func _reset_global_state():
	"""Reset all autoload singletons to prevent save slot bleeding"""
	print("\n=== RESETTING GLOBAL STATE ===")
	
	# Reset weapon unlocks to default (Pistol only)
	if GlobalWeaponStorage:
		if GlobalWeaponStorage.has_method("set_unlocked_weapons"):
			GlobalWeaponStorage.set_unlocked_weapons(["Pistol"])
			print("✓ GlobalWeaponStorage reset to default")
		else:
			print("⚠ GlobalWeaponStorage doesn't have set_unlocked_weapons method")
	
	# Reset weapon upgrades
	if WeaponUpgradeManager:
		if WeaponUpgradeManager.has_method("reset_all_upgrades"):
			WeaponUpgradeManager.reset_all_upgrades()
			print("✓ WeaponUpgradeManager reset")
		else:
			print("⚠ WeaponUpgradeManager doesn't have reset_all_upgrades method")
	
	# Reset tutorial progress - CHECK if method exists first
	if TutorialManager:
		if TutorialManager.has_method("reset_all_tutorials"):
			TutorialManager.reset_all_tutorials()
			print("✓ TutorialManager reset")
		else:
			# If no reset method, manually clear tutorial data if possible
			if "completed_tutorials" in TutorialManager:
				TutorialManager.completed_tutorials.clear()
				print("✓ TutorialManager.completed_tutorials cleared manually")
			else:
				print("⚠ TutorialManager doesn't have reset method - skipping")
	
	# Reset stats
	if StatsTracker:
		if StatsTracker.has_method("reset_stats"):
			StatsTracker.reset_stats()
			print("✓ StatsTracker reset")
		else:
			print("⚠ StatsTracker doesn't have reset_stats method")
	
	# Clear GameManager state
	GameManager.current_save_slot = -1
	GameManager.pending_load_data = {}
	GameManager.returning_from_farm = false
	GameManager.is_starting_permadeath = false
	if "selected_character_id" in GameManager:
		GameManager.selected_character_id = "hero"
	print("✓ GameManager state cleared")
	
	print("=== GLOBAL STATE RESET COMPLETE ===\n")

func _load_save_slots():
	# Clear existing slots IMMEDIATELY to prevent duplicates
	for child in slots_container.get_children():
		slots_container.remove_child(child)  # Remove from tree immediately
		child.queue_free()  # Then mark for deletion
	
	# Get all saves
	var saves = SaveSystem.get_all_saves()
	
	# Create UI for each slot
	for i in range(saves.size()):
		var slot_ui = save_slot_scene.instantiate()
		slots_container.add_child(slot_ui)
		slot_ui.setup(i, saves[i])
		
		# Connect signals
		slot_ui.slot_selected.connect(_on_slot_selected)
		slot_ui.slot_deleted.connect(_on_slot_deleted)

func _on_slot_selected(slot: int):
	selected_slot = slot
	print("Selected slot: ", slot)
	
	# Check if slot is empty (new game) or has save (continue)
	if SaveSystem.save_exists(slot):
		# Load existing save
		_load_game(slot)
	else:
		# Ask about permadeath mode for new game
		pending_new_game_slot = slot
		
		# Make sure dialog is ready before showing
		if permadeath_dialog:
			permadeath_dialog.show()
		else:
			print("⚠ Permadeath dialog not ready yet, starting normal mode")
			GameManager.is_starting_permadeath = false
			_show_character_selection(slot)

func _on_permadeath_mode_selected(is_permadeath: bool):
	"""Called when player chooses normal or permadeath mode"""
	if pending_new_game_slot < 0:
		return
	
	# Store permadeath choice in GameManager
	GameManager.is_starting_permadeath = is_permadeath
	GameManager.current_save_slot = pending_new_game_slot
	GameManager.selected_character_id = "hero"  # Default character
	
	print("Starting new game - Slot: ", pending_new_game_slot, ", Permadeath: ", is_permadeath)
	
	# Go straight to safehouse
	_start_new_game(pending_new_game_slot, "hero")
	
	pending_new_game_slot = -1

func _show_character_selection(slot: int):
	"""Start new game directly (no character selection)"""
	print("Starting new game for slot ", slot)
	
	# Store the slot for later
	GameManager.current_save_slot = slot
	GameManager.selected_character_id = "hero"  # Default character
	
	# CRITICAL FIX: Ensure global systems are reset for new game
	if GlobalWeaponStorage and GlobalWeaponStorage.has_method("set_unlocked_weapons"):
		GlobalWeaponStorage.set_unlocked_weapons(["Pistol"])
		print("✓ Confirmed GlobalWeaponStorage reset for new game")
	
	# Go straight to safehouse
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

func _start_new_game(slot: int, character_id: String = "hero"):
	print("Starting new game in slot ", slot, " with character: ", character_id)
	
	# Store the current save slot and selected character
	GameManager.current_save_slot = slot
	GameManager.selected_character_id = character_id
	
	# Change to safehouse scene
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

func _load_game(slot: int):
	print("Loading game from slot ", slot)
	
	var save_data = SaveSystem.load_game(slot)
	
	if save_data.is_empty():
		print("Failed to load save!")
		return
	
	GameManager.current_save_slot = slot
	GameManager.pending_load_data = save_data
	
	# Always load into safehouse when loading a save
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)
	
func _on_slot_deleted(slot: int):
	print("Delete requested for slot ", slot)
	
	# Create our custom styled dialog
	var ConfirmDeleteDialog = load("res://Resources/UI/ConfirmDeleteDialog.gd")
	var dialog = ConfirmDeleteDialog.new()
	add_child(dialog)
	
	dialog.confirmed.connect(func(): _confirm_delete(slot))
	dialog.show_dialog("Delete save file " + str(slot + 1) + "?\nThis cannot be undone.")
	
func _confirm_delete(slot: int):
	if SaveSystem.delete_save(slot):
		print("Deleted save slot ", slot)
		
		# CRITICAL FIX: Reset global state after deletion
		# If we just deleted the currently "active" data in memory, clear it
		_reset_global_state()
		
		# Refresh the display
		_load_save_slots()
	else:
		print("Failed to delete save slot ", slot)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")
