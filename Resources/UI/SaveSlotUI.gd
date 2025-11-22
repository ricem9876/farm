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

# Farm theme colors
const TEXT_COLOR = Color(0.05, 0.05, 0.05)
const BORDER_COLOR = Color(0.3, 0.2, 0.1)

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
	slot_label.add_theme_font_size_override("font_size", 28)
	slot_label.add_theme_color_override("font_color", TEXT_COLOR)
	
	if is_empty:
		# Empty slot - light tan/cream
		info_label.text = "Empty Slot"
		info_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		timestamp_label.text = ""
		select_button.text = "NEW GAME"
		delete_button.visible = false
		if SaveSystem.is_permadeath_save(slot_index):
			info_label.text += " [PERMADEATH]"
			info_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # 
		# Light cream style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.92, 0.88, 0.78)  # Light cream
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = BORDER_COLOR
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 3
		style.shadow_offset = Vector2(2, 2)
		add_theme_stylebox_override("panel", style)
		
		# Style select button for new game - Sage green
		_style_button(select_button, Color(0.5, 0.7, 0.4))
	else:
		# Existing save - darker cream with sage green tint
		var player_data = save_data.get("player", {})
		var level = player_data.get("level", 1)
		var health = player_data.get("health", 100)
		var max_health = player_data.get("max_health", 100)
		var health_int = int(float(health)) if health != null else 100
		var max_health_int = int(float(max_health)) if max_health != null else 100
		
		info_label.text = "Level " + str(level) + " | HP: " + str(health_int) + "/" + str(max_health_int)
		info_label.add_theme_color_override("font_color", TEXT_COLOR)
		timestamp_label.text = save_data.get("timestamp", "Unknown")
		select_button.text = "CONTINUE"
		delete_button.visible = true
		
		# Sage green tinted style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.82, 0.88, 0.78)  # Light sage tint
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.4, 0.6, 0.4)  # Sage green border
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 3
		style.shadow_offset = Vector2(2, 2)
		add_theme_stylebox_override("panel", style)
		
		# Style buttons
		_style_button(select_button, Color(0.5, 0.7, 0.4))  # Sage green
		_style_button(delete_button, Color(0.75, 0.5, 0.35))  # Rustic brown
	
	# Style labels
	info_label.add_theme_font_override("font", pixel_font)
	info_label.add_theme_font_size_override("font_size", 20)
	
	timestamp_label.add_theme_font_override("font", pixel_font)
	timestamp_label.add_theme_font_size_override("font_size", 16)
	timestamp_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _style_button(button: Button, color: Color):
	"""Apply farm theme styling to a button"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.custom_minimum_size = Vector2(150, 50)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = color
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 3
	btn_style.border_color = BORDER_COLOR
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("normal", btn_style)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_select_pressed():
	slot_selected.emit(slot_index)

func _on_delete_pressed():
	# Create our custom styled dialog
	var ConfirmDeleteDialog = load("res://Resources/UI/ConfirmDeleteDialog.gd")
	var dialog = ConfirmDeleteDialog.new()
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		if SaveSystem.delete_save(slot_index):
			SaveSystem.reset_global_systems_for_deleted_save()
			refresh()
			slot_deleted.emit(slot_index)
			print("Save slot ", slot_index, " deleted and systems reset")
	)
	
	dialog.show_dialog("Are you sure you want to delete this save?\nThis action cannot be undone!")
