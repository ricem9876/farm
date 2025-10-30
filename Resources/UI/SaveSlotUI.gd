# SaveSlotUI.gd
extends PanelContainer
class_name SaveSlotUI

signal slot_selected(slot: int)
signal slot_deleted(slot: int)

@onready var slot_label = $MarginContainer/VBoxContainer/SlotLabel
@onready var info_label = $MarginContainer/VBoxContainer/InfoLabel
@onready var timestamp_label = $MarginContainer/VBoxContainer/TimestampLabel
@onready var button_container = $MarginContainer/VBoxContainer/ButtonContainer
@onready var select_button = $MarginContainer/VBoxContainer/ButtonContainer/SelectButton
@onready var delete_button = $MarginContainer/VBoxContainer/ButtonContainer/DeleteButton

var slot_index: int = 0
var save_data: Dictionary = {}
var is_empty: bool = true

func _ready():
	select_button.pressed.connect(_on_select_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

func setup(slot: int, data: Dictionary):
	slot_index = slot
	save_data = data
	is_empty = data.is_empty()
	
	_update_display()

func refresh():
	"""Refresh the slot display with current save data"""
	save_data = SaveSystem.get_save_data(slot_index)
	is_empty = save_data.is_empty()
	_update_display()

func _update_display():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Slot number
	slot_label.text = "SAVE SLOT " + str(slot_index + 1)
	slot_label.add_theme_font_override("font", pixel_font)
	slot_label.add_theme_font_size_override("font_size", 24)
	
	if is_empty:
		# Empty slot
		info_label.text = "Empty Slot"
		timestamp_label.text = ""
		select_button.text = "NEW GAME"
		delete_button.visible = false
		
		# Gray out style with shadow
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		# Add shadow
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 2)
		add_theme_stylebox_override("panel", style)
	else:
		# Existing save
		var player_data = save_data.get("player", {})
		var level = player_data.get("level", 1)
		var health = player_data.get("health", 100)
		var max_health = player_data.get("max_health", 100)
		# Convert to proper types with validation
		var health_int = int(float(health)) if health != null else 100
		var max_health_int = int(float(max_health)) if max_health != null else 100
		info_label.text = "Level " + str(level) + " | HP: " + str(health_int) + "/" + str(max_health_int)
		timestamp_label.text = save_data.get("timestamp", "Unknown")
		select_button.text = "CONTINUE"
		delete_button.visible = true
		
		# Active style with shadow
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.4, 0.3)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.7, 0.4)
		# Add shadow
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 2)
		add_theme_stylebox_override("panel", style)
	
	# Style labels
	info_label.add_theme_font_override("font", pixel_font)
	info_label.add_theme_font_size_override("font_size", 16)
	timestamp_label.add_theme_font_override("font", pixel_font)
	timestamp_label.add_theme_font_size_override("font_size", 12)
	timestamp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Style buttons
	select_button.add_theme_font_override("font", pixel_font)
	delete_button.add_theme_font_override("font", pixel_font)

func _on_select_pressed():
	slot_selected.emit(slot_index)

func _on_delete_pressed():
	# Create a confirmation dialog
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to delete this save?\nThis action cannot be undone!"
	confirm_dialog.title = "Delete Save"
	
	# Style the dialog with pixel font
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	confirm_dialog.add_theme_font_override("font", pixel_font)
	
	# Connect the confirmed signal
	confirm_dialog.confirmed.connect(func():
		# Actually delete the save
		if SaveSystem.delete_save(slot_index):
			# CRITICAL: Reset all global systems
			SaveSystem.reset_global_systems_for_deleted_save()
			
			# Refresh this slot's display to show as empty
			refresh()
			
			# Emit the signal to notify parent (if needed)
			slot_deleted.emit(slot_index)
			
			print("Save slot ", slot_index, " deleted and systems reset")
	)
	
	# Add dialog to scene tree and show
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()
	
	# Clean up dialog after it's closed
	confirm_dialog.visibility_changed.connect(func():
		if not confirm_dialog.visible:
			confirm_dialog.queue_free()
	)
