# UpgradeStatsUI.gd
# UI for upgrading player stats - Press K to open
extends CanvasLayer

signal stats_ui_opened
signal stats_ui_closed

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var stats_container = $Panel/VBoxContainer/StatsContainer
@onready var close_button = $Panel/CloseButton

var player: Node2D

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)  # Cream background
const TEXT_COLOR = Color(0.05, 0.05, 0.05)  # Very dark text
const TITLE_COLOR = Color(0.5, 0.7, 0.4)  # Sage green
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border
const STAT_COLOR = Color(0.8, 0.65, 0.4)  # Warm gold for stat values

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
	
	# Style main panel
	if panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = BG_COLOR
		panel_style.border_width_left = 6
		panel_style.border_width_right = 6
		panel_style.border_width_top = 6
		panel_style.border_width_bottom = 6
		panel_style.border_color = BORDER_COLOR
		panel_style.corner_radius_top_left = 12
		panel_style.corner_radius_top_right = 12
		panel_style.corner_radius_bottom_left = 12
		panel_style.corner_radius_bottom_right = 12
		panel.add_theme_stylebox_override("panel", panel_style)
	
	# Title
	if title_label:
		title_label.text = "PLAYER STATS"
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", 42)
		title_label.add_theme_color_override("font_color", TITLE_COLOR)
		title_label.add_theme_constant_override("outline_size", 2)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Close button
	if close_button:
		close_button.text = "X"
		close_button.add_theme_font_override("font", pixel_font)
		close_button.add_theme_font_size_override("font_size", 32)
		close_button.add_theme_color_override("font_color", TEXT_COLOR)
		close_button.custom_minimum_size = Vector2(50, 50)
		
		# Style close button
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.75, 0.5, 0.35)  # Rustic brown
		btn_style.border_width_left = 3
		btn_style.border_width_right = 3
		btn_style.border_width_top = 3
		btn_style.border_width_bottom = 3
		btn_style.border_color = BORDER_COLOR
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		close_button.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.85, 0.6, 0.45)
		close_button.add_theme_stylebox_override("hover", btn_hover)
		
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.65, 0.4, 0.25)
		close_button.add_theme_stylebox_override("pressed", btn_pressed)

func _input(event):
	if event.is_action_pressed("upgrade_stats"):
		toggle_visibility()

func toggle_visibility():
	visible = !visible
	
	if visible:
		get_tree().paused = true
		stats_ui_opened.emit()
		_update_stats_display()
		
		# Notify tutorial
		if IntroTutorial and IntroTutorial.has_method("on_upgrade_menu_opened"):
			IntroTutorial.on_upgrade_menu_opened()
	else:
		get_tree().paused = false
		stats_ui_closed.emit()

func _update_stats_display():
	"""Update the display of player stats"""
	if not player or not player.has_node("LevelSystem"):
		return
	
	var level_system = player.get_node("LevelSystem")
	
	# Clear existing stat displays
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create uniform stat rows
	_create_stat_row("Level", str(level_system.level))
	_create_stat_row("Experience", "%d / %d" % [level_system.experience, level_system.experience_to_next_level])
	_create_stat_row("Health", "%.0f" % level_system.max_health)
	_create_stat_row("Damage", "%.0f%%" % (level_system.damage * 100))
	_create_stat_row("Speed", "%.0f%%" % (level_system.speed * 100))
	_create_stat_row("Luck", "%.0f%%" % (level_system.luck * 100))

func _create_stat_row(stat_name: String, stat_value: String):
	"""Create a uniform stat row with name and value"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Container for the stat
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 50)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.92, 0.88, 0.78)  # Slightly darker cream
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = BORDER_COLOR
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	
	# Horizontal layout
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Stat name (left-aligned)
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Stat value (right-aligned)
	var value_label = Label.new()
	value_label.text = stat_value
	value_label.add_theme_font_override("font", pixel_font)
	value_label.add_theme_font_size_override("font_size", 28)
	value_label.add_theme_color_override("font_color", STAT_COLOR)  # Warm gold
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)
	
	stats_container.add_child(card)

func _on_close_pressed():
	toggle_visibility()
