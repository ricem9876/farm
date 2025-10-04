# SaveSelectScreen.gd
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
	_load_save_slots()
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Title
	if title_label:
		title_label.text = "SELECT SAVE FILE"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	
	# Back button
	if back_button:
		back_button.text = "BACK TO MENU"
		back_button.add_theme_font_override("font", pixel_font)
		back_button.add_theme_font_size_override("font_size", 24)

func _load_save_slots():
	# Clear existing slots
	for child in slots_container.get_children():
		child.queue_free()
	
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
		# Start new game
		_start_new_game(slot)

func _start_new_game(slot: int):
	print("Starting new game in slot ", slot)
	
	# Store the current save slot in GameManager or autoload
	GameManager.current_save_slot = slot
	
	# Change to farm scene
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
		# Refresh the display
		_load_save_slots()
	else:
		print("Failed to delete save slot ", slot)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Resources/Scenes/TitleScreen.tscn")
