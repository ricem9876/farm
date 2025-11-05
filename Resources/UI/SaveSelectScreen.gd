# SaveSelectScreen.gd - SAFE VERSION (checks for methods before calling)
extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var slots_container = $VBoxContainer/SlotsContainer
@onready var back_button = $VBoxContainer/BackButton

var save_slot_scene = preload("res://Resources/UI/SaveSlotUI.tscn")
var selected_slot: int = -1

const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	_setup_ui()
	
	# CRITICAL FIX: Reset all global state when entering save select screen
	# This prevents save slot data from bleeding across slots
	_reset_global_state()
	
	_load_save_slots()
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Title - same styling as LevelSelectUI
	if title_label:
		title_label.text = "SELECT SAVE FILE"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		# Tan/beige color
		#title_label.add_theme_color_override("font_color", Color(0.87058824, 0.72156864, 0.5294118))
		# Add shadow with 0.5 opacity, offset (2,2), size 4
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 4)
		# Center the title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Back button
	if back_button:
		back_button.text = "BACK TO MENU"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)

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
		# Start new game - go to character selection
		_show_character_selection(slot)

func _show_character_selection(slot: int):
	"""Show character selection screen for new game"""
	print("Opening character selection for slot ", slot)
	
	# Store the slot for later
	GameManager.current_save_slot = slot
	
	# CRITICAL FIX: Ensure global systems are reset for new game
	# (Defense in depth - this should already be done in _reset_global_state, 
	# but we double-check here to be safe)
	if GlobalWeaponStorage and GlobalWeaponStorage.has_method("set_unlocked_weapons"):
		GlobalWeaponStorage.set_unlocked_weapons(["Pistol"])
		print("✓ Confirmed GlobalWeaponStorage reset for new game")
	
	# Load character selection scene
	get_tree().change_scene_to_file("res://Resources/UI/CharacterSelectScene.tscn")

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
	
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete save file " + str(slot + 1) + "?\nThis cannot be undone."
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	
	dialog.confirmed.connect(func(): _confirm_delete(slot))
	
	add_child(dialog)
	dialog.popup_centered()

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
