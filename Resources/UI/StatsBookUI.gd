# StatsBookUI.gd - Displays player statistics in a book-style UI
extends Control

signal book_opened
signal book_closed

@onready var background_panel = $BackgroundPanel
@onready var title_label = $BackgroundPanel/VBoxContainer/TitleLabel
@onready var stats_scroll = $BackgroundPanel/VBoxContainer/StatsScroll
@onready var stats_content = $BackgroundPanel/VBoxContainer/StatsScroll/StatsContent
@onready var close_button = $BackgroundPanel/CloseButton

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	_setup_ui()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _setup_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Background panel styling
	if background_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.96, 0.93, 0.82, 0.98)  # Cream color
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.45, 0.32, 0.18)  # Brown border
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
		style.shadow_size = 8
		style.shadow_offset = Vector2(4, 4)
		background_panel.add_theme_stylebox_override("panel", style)
		
		# Center the panel
		background_panel.anchor_left = 0.5
		background_panel.anchor_right = 0.5
		background_panel.anchor_top = 0.5
		background_panel.anchor_bottom = 0.5
		background_panel.offset_left = -300
		background_panel.offset_right = 300
		background_panel.offset_top = -250
		background_panel.offset_bottom = 250
	
	# Title styling
	if title_label:
		title_label.text = "ADVENTURER'S RECORDS"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Close button styling
	if close_button:
		_style_button(close_button, "CLOSE", Color(0.7, 0.2, 0.2), pixel_font)

func _style_button(button: Button, text: String, color: Color, font: Font):
	button.text = text
	button.custom_minimum_size = Vector2(150, 40)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 20)
	
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
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

func open():
	print("[STATSBOOK] Opening records book...")
	visible = true
	get_tree().paused = true
	_update_stats()
	book_opened.emit()
	print("[STATSBOOK] ✓ Book opened, signal emitted")

func close():
	print("[STATSBOOK] Closing records book...")
	visible = false
	get_tree().paused = false
	book_closed.emit()

func _on_close_pressed():
	close()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _update_stats():
	# Clear existing stats
	for child in stats_content.get_children():
		child.queue_free()
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# === VEGETABLES DEFEATED SECTION ===
	_add_section_header("VEGETABLES Harvested", pixel_font)
	
	var total_kills = StatsTracker.get_total_kills()
	_add_stat_line("Total Kills:", str(total_kills), pixel_font, Color(0.2, 0.6, 0.2))
	
	_add_spacer(10)
	
	# Individual vegetable kills
	_add_stat_line("  Mushrooms:", str(StatsTracker.get_kills_for_type("mushroom")), pixel_font)
	_add_stat_line("  Corn:", str(StatsTracker.get_kills_for_type("corn")), pixel_font)
	_add_stat_line("  Pumpkins:", str(StatsTracker.get_kills_for_type("pumpkin")), pixel_font)
	_add_stat_line("  Tomatoes:", str(StatsTracker.get_kills_for_type("tomato")), pixel_font)
	_add_stat_line("  Peas:", str(StatsTracker.get_kills_for_type("pea")), pixel_font)
	
	_add_spacer(20)
	
	# === COMBAT SECTION ===
	_add_section_header("COMBAT STATISTICS", pixel_font)
	
	_add_stat_line("Damage Dealt:", "%.0f" % StatsTracker.total_damage_dealt, pixel_font)
	_add_stat_line("Damage Taken:", "%.0f" % StatsTracker.total_damage_taken, pixel_font)
	_add_stat_line("Shots Fired:", str(StatsTracker.shots_fired), pixel_font)
	_add_stat_line("Critical Hits:", str(StatsTracker.critical_hits), pixel_font)
	
	var crit_rate = StatsTracker.get_critical_hit_rate()
	_add_stat_line("Crit Rate:", "%.1f%%" % crit_rate, pixel_font, Color(1.0, 0.6, 0.0))
	
	_add_spacer(20)
	
	# === PROGRESSION SECTION ===
	_add_section_header("PROGRESSION", pixel_font)
	
	_add_stat_line("Total XP Gained:", str(StatsTracker.total_experience_gained), pixel_font)
	_add_stat_line("Items Collected:", str(StatsTracker.items_collected), pixel_font)
	_add_stat_line("Times Died:", str(StatsTracker.times_died), pixel_font, Color(0.8, 0.2, 0.2))
	
	_add_spacer(20)
	
	# === TIME SECTION ===
	_add_section_header("TIME PLAYED", pixel_font)
	
	var playtime = StatsTracker.get_playtime_formatted()
	_add_stat_line("Total Playtime:", playtime, pixel_font, Color(0.3, 0.5, 0.8))

func _add_section_header(text: String, font: Font):
	var header = Label.new()
	header.text = text
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add underline effect with separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 5)
	
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.45, 0.32, 0.18)
	separator.add_theme_stylebox_override("separator", sep_style)
	
	stats_content.add_child(header)
	stats_content.add_child(separator)

func _add_stat_line(label: String, value: String, font: Font, highlight_color: Color = Color(0.2, 0.2, 0.2)):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	var label_node = Label.new()
	label_node.text = label
	label_node.add_theme_font_override("font", font)
	label_node.add_theme_font_size_override("font_size", 18)
	label_node.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_node = Label.new()
	value_node.text = value
	value_node.add_theme_font_override("font", font)
	value_node.add_theme_font_size_override("font_size", 18)
	value_node.add_theme_color_override("font_color", highlight_color)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox.add_child(label_node)
	hbox.add_child(value_node)
	stats_content.add_child(hbox)

func _add_spacer(height: int):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	stats_content.add_child(spacer)
