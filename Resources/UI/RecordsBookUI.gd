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
	
	# COMBAT STATISTICS
	_create_section_header("COMBAT STATISTICS")
	
	if StatsTracker:
		_create_record_entry("Total Enemies Killed", str(StatsTracker.get_total_kills()))
		_create_record_entry("Damage Dealt", "%.0f" % StatsTracker.total_damage_dealt)
		_create_record_entry("Damage Taken", "%.0f" % StatsTracker.total_damage_taken)
		_create_record_entry("Shots Fired", str(StatsTracker.shots_fired))
		_create_record_entry("Critical Hits", str(StatsTracker.critical_hits))
		
		var crit_rate = StatsTracker.get_critical_hit_rate()
		_create_record_entry("Critical Hit Rate", "%.1f%%" % crit_rate)
	
	# VEGETABLES DEFEATED
	_create_section_header("VEGETABLES DEFEATED")
	
	if StatsTracker:
		var veggie_names = {
			"mushroom": "Mushrooms",
			"corn": "Corn",
			"pumpkin": "Pumpkins",
			"tomato": "Tomatoes",
			"pea": "Peas"
		}
		
		for veggie_key in ["mushroom", "corn", "pumpkin", "tomato", "pea"]:
			var kill_count = StatsTracker.get_kills_for_type(veggie_key)
			var display_name = veggie_names.get(veggie_key, veggie_key.capitalize())
			_create_record_entry(display_name, str(kill_count))
	
	# EXPLORATION
	_create_section_header("EXPLORATION")
	
	if StatsTracker:
		_create_record_entry("Deaths", str(StatsTracker.times_died))
		_create_record_entry("Play Time", StatsTracker.get_playtime_formatted())
		_create_record_entry("Experience Gained", str(StatsTracker.total_experience_gained))
	
	# COLLECTION
	_create_section_header("COLLECTION")
	
	if StatsTracker:
		_create_record_entry("Items Collected", str(StatsTracker.items_collected))
	
	if player and player.has_node("InventoryManager"):
		var inv = player.get_node("InventoryManager")
		# Update these item names to match what your vegetables actually drop
		_create_record_entry("Mushrooms", str(inv.get_item_quantity_by_name("Mushroom")))
		_create_record_entry("Corn", str(inv.get_item_quantity_by_name("Corn")))
		_create_record_entry("Pumpkins", str(inv.get_item_quantity_by_name("Pumpkin")))
		_create_record_entry("Tomatoes", str(inv.get_item_quantity_by_name("Tomato")))
		_create_record_entry("Peas", str(inv.get_item_quantity_by_name("Pea")))

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
