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
	slot_deleted.emit(slot_index)
