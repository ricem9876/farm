# RecordsBookUI.gd
# UI for viewing player records and achievements - Press B to open
extends CanvasLayer

signal records_opened
signal records_closed

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var records_container = $Panel/VBoxContainer/ScrollContainer/RecordsContainer
@onready var close_button = $Panel/CloseButton

var player: Node2D

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_setup_ui()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	if title_label:
		title_label.text = "RECORDS BOOK"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	
	if close_button:
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)

func _input(event):
	if event.is_action_pressed("open_records"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	
	if visible:
		records_opened.emit()
		_update_records_display()
		
		# Notify tutorial
		if IntroTutorial and IntroTutorial.has_method("on_records_book_opened"):
			IntroTutorial.on_records_book_opened()
	else:
		records_closed.emit()

func _update_records_display():
	"""Update the display of player records"""
	# Clear existing records
	for child in records_container.get_children():
		child.queue_free()
	
	# Create section headers and records
	_create_section_header("COMBAT STATISTICS")
	
	if StatsTracker:
		_create_record_entry("Enemies Killed", str(StatsTracker.enemies_killed))
		_create_record_entry("Damage Dealt", "%.0f" % StatsTracker.total_damage_dealt)
		_create_record_entry("Shots Fired", str(StatsTracker.shots_fired))
		_create_record_entry("Shots Hit", str(StatsTracker.shots_hit))
		
		var accuracy = 0.0
		if StatsTracker.shots_fired > 0:
			accuracy = (float(StatsTracker.shots_hit) / float(StatsTracker.shots_fired)) * 100.0
		_create_record_entry("Accuracy", "%.1f%%" % accuracy)
	
	_create_section_header("EXPLORATION")
	
	if StatsTracker:
		_create_record_entry("Levels Completed", str(StatsTracker.levels_completed))
		_create_record_entry("Deaths", str(StatsTracker.deaths))
		_create_record_entry("Play Time", _format_time(StatsTracker.play_time))
	
	_create_section_header("COLLECTION")
	
	if player and player.has_node("InventoryManager"):
		var inv = player.get_node("InventoryManager")
		_create_record_entry("Items Collected", str(inv.get_total_items()))
		_create_record_entry("Wolf Fur", str(inv.get_item_quantity_by_name("Wolf Fur")))
		_create_record_entry("Plant Fiber", str(inv.get_item_quantity_by_name("Plant Fiber")))
		_create_record_entry("Wood", str(inv.get_item_quantity_by_name("Wood")))

func _create_section_header(text: String):
	var label = Label.new()
	label.text = "━━━ " + text + " ━━━"
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	records_container.add_child(label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	records_container.add_child(spacer)

func _create_record_entry(label_text: String, value_text: String):
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	for lbl in [label, value]:
		lbl.add_theme_font_override("font", pixel_font)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	hbox.add_child(label)
	hbox.add_child(value)
	records_container.add_child(hbox)

func _format_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs

func _on_close_pressed():
	toggle_visibility()
