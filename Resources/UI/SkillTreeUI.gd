# SkillTreeUI.gd
extends CanvasLayer

signal skill_tree_closed

@onready var background = $Background
@onready var main_panel = $MainPanel
@onready var level_label = $MainPanel/MarginContainer/VBoxContainer/InfoPanel/LevelLabel
@onready var skill_points_label = $MainPanel/MarginContainer/VBoxContainer/InfoPanel/SkillPointsLabel
@onready var xp_bar = $MainPanel/MarginContainer/VBoxContainer/XPBar
@onready var xp_label = $MainPanel/MarginContainer/VBoxContainer/XPBar/XPLabel
@onready var skills_container = $MainPanel/MarginContainer/VBoxContainer/ScrollContainer/SkillsContainer
@onready var close_button = $MainPanel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var reset_button = $MainPanel/MarginContainer/VBoxContainer/BottomPanel/ResetButton
@onready var continue_button = $MainPanel/MarginContainer/VBoxContainer/BottomPanel/ContinueButton

var level_system: PlayerLevelSystem
var skill_buttons: Dictionary = {}

# Farm theme colors
const BG_COLOR = Color(0.96, 0.93, 0.82)  # Cream background
const TEXT_COLOR = Color(0.05, 0.05, 0.05)  # Very dark text
const TITLE_COLOR = Color(0.5, 0.7, 0.4)  # Sage green
const BORDER_COLOR = Color(0.3, 0.2, 0.1)  # Dark brown border
const CARD_BG = Color(0.92, 0.88, 0.78)  # Slightly darker cream for cards

# Skill definitions with descriptions (removed icons and colors)
var skill_data = {
	"health": {
		"display_name": "Max Health",
		"description": "+10 HP per point"
	},
	"speed": {
		"display_name": "Movement Speed",
		"description": "+5% speed per point"
	},
	"damage": {
		"display_name": "Weapon Damage",
		"description": "+5% damage per point"
	},
	"fire_rate": {
		"display_name": "Fire Rate",
		"description": "+4% fire rate per point"
	},
	"luck": {
		"display_name": "Luck",
		"description": "+1% dodge & double drops per point"
	},
	"crit_chance": {
		"display_name": "Critical Chance",
		"description": "+2% crit chance per point (Max 25)"
	},
	"crit_damage": {
		"display_name": "Critical Damage",
		"description": "+10% crit damage per point"
	}
}

func _ready():
	print("\n=== SKILLTREEUI INITIALIZATION ===")
	
	# CRITICAL: Allow this UI to process input even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Start hidden
	visible = false
	if background:
		background.visible = false
	
	# Apply farm theme styling
	_setup_ui_styling()
	
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("✓ Close button connected")
	else:
		print("✗ close_button is NULL")
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
		print("✓ Continue button connected")
	else:
		print("✗ continue_button is NULL")
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	_create_skill_buttons()
	print("=== INITIALIZATION COMPLETE ===\n")

func _setup_ui_styling():
	"""Apply farm theme to the UI"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style main panel
	if main_panel:
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
		main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# CHANGE 1: Add "SKILL TREE" title with shadow and warm gold color
	var title_container = main_panel.find_child("Header", true, false)
	if title_container:
		# Check if we already added the title
		var existing_title = title_container.find_child("SkillTreeTitle", false, false)
		if not existing_title:
			var title = Label.new()
			title.name = "SkillTreeTitle"
			title.text = "SKILL TREE"
			title.add_theme_font_override("font", pixel_font)
			title.add_theme_font_size_override("font_size", 48)
			title.add_theme_color_override("font_color", Color(0.8, 0.65, 0.4))  # Warm gold like Level
			# Add shadow
			title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))  # 50% transparent black
			title.add_theme_constant_override("shadow_offset_x", 1)
			title.add_theme_constant_override("shadow_offset_y", 2)
			title.add_theme_constant_override("shadow_outline_size", 4)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# Insert at the beginning of the header
			title_container.add_child(title)
			title_container.move_child(title, 0)
	
	# Style labels
	if level_label:
		level_label.add_theme_font_override("font", pixel_font)
		level_label.add_theme_font_size_override("font_size", 28)
		level_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.4))  # Warm gold
	
	if skill_points_label:
		skill_points_label.add_theme_font_override("font", pixel_font)
		skill_points_label.add_theme_font_size_override("font_size", 28)
		skill_points_label.add_theme_color_override("font_color", TITLE_COLOR)  # Sage green
	
	if xp_label:
		xp_label.add_theme_font_override("font", pixel_font)
		xp_label.add_theme_font_size_override("font_size", 20)
		xp_label.add_theme_color_override("font_color", TEXT_COLOR)
	
	# Style XP bar
	if xp_bar:
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.5, 0.7, 0.4)  # Sage green
		bar_style.corner_radius_top_left = 5
		bar_style.corner_radius_top_right = 5
		bar_style.corner_radius_bottom_left = 5
		bar_style.corner_radius_bottom_right = 5
		xp_bar.add_theme_stylebox_override("fill", bar_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.75, 0.68, 0.55)
		bg_style.corner_radius_top_left = 5
		bg_style.corner_radius_top_right = 5
		bg_style.corner_radius_bottom_left = 5
		bg_style.corner_radius_bottom_right = 5
		xp_bar.add_theme_stylebox_override("background", bg_style)
	
	# CHANGE 2: Remove scrollbars from ScrollContainer
	var scroll_container = main_panel.find_child("ScrollContainer", true, false)
	if scroll_container:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Style buttons
	_style_button(close_button, Color(0.75, 0.5, 0.35), "X")  # Rustic brown
	_style_button(reset_button, Color(0.75, 0.5, 0.35), "Reset All Skills")  # Rustic brown
	_style_button(continue_button, Color(0.5, 0.7, 0.4), "Continue")  # Sage green
	
	
func _style_button(button: Button, color: Color, text: String = ""):
	if not button:
		return
	
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	if text != "":
		button.text = text
	
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = color
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 3
	btn_style.border_color = BORDER_COLOR
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", btn_style)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
func _process(delta):
	if visible:
		# Check if mouse is over any button
		if close_button and close_button.is_hovered():
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				print("Mouse clicked while hovering close button!")
		
		if continue_button and continue_button.is_hovered():
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				print("Mouse clicked while hovering continue button!")

func setup(player_level_system: PlayerLevelSystem):
	print("SkillTreeUI.setup() called")
	level_system = player_level_system
	
	# Connect to level system signals
	if level_system:
		level_system.experience_gained.connect(_on_experience_gained)
		level_system.skill_point_spent.connect(_on_skill_point_spent)
		print("✓ Connected to level system signals")
	
	_update_ui()

func _create_skill_buttons():
	# Create a skill button for each stat
	for stat_name in skill_data.keys():
		var skill_panel = _create_skill_panel(stat_name)
		skills_container.add_child(skill_panel)
		skill_buttons[stat_name] = skill_panel
		
		
func _create_skill_panel(stat_name: String) -> PanelContainer:
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	var data = skill_data[stat_name]
	
	# Main panel with farm theme
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = BORDER_COLOR
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	# Main HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Left side - Info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(vbox)
	
	# CHANGE 3: Title only (no icon)
	var title_label = Label.new()
	title_label.text = data.display_name
	title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	
	# Description (removed gear icon here too)
	var desc_label = Label.new()
	desc_label.text = data.description
	desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	vbox.add_child(desc_label)
	
	# Current value
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "Current: 0"
	value_label.add_theme_font_override("font", pixel_font)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.4))  # Warm gold
	vbox.add_child(value_label)
	
	# Right side - Points and Button
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(right_vbox)
	
	# Points invested
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Points: 0/50"
	points_label.add_theme_font_override("font", pixel_font)
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.add_theme_color_override("font_color", TEXT_COLOR)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(points_label)
	
	# Upgrade button
	var button = Button.new()
	button.name = "UpgradeButton"
	button.text = "Upgrade"
	button.custom_minimum_size = Vector2(120, 50)
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(_on_upgrade_button_pressed.bind(stat_name))
	_style_upgrade_button(button)
	right_vbox.add_child(button)
	
	return panel
	
func _style_upgrade_button(button: Button):
	"""Style the upgrade button with sage green"""
	button.add_theme_color_override("font_color", TEXT_COLOR)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.5, 0.7, 0.4)  # Sage green
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
	hover_style.bg_color = Color(0.6, 0.8, 0.5)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.4, 0.6, 0.3)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled state
	var disabled_style = btn_style.duplicate()
	disabled_style.bg_color = Color(0.7, 0.65, 0.55)  # Gray/tan
	button.add_theme_stylebox_override("disabled", disabled_style)

func _on_upgrade_button_pressed(stat_name: String):
	if level_system and level_system.upgrade_stat(stat_name):
		_update_ui()
		print("Upgraded ", stat_name, "!")
	else:
		print("Cannot upgrade ", stat_name, " - no skill points or max reached")

func _update_ui():
	if not level_system:
		return
	
	# Update header info
	level_label.text = "Level: " + str(level_system.current_level)
	skill_points_label.text = "Skill Points: " + str(level_system.skill_points)
	
	# Update XP bar
	xp_bar.max_value = level_system.experience_to_next_level
	xp_bar.value = level_system.current_experience
	xp_label.text = str(level_system.current_experience) + " / " + str(level_system.experience_to_next_level) + " XP"
	
	# Update each skill button
	for stat_name in skill_buttons.keys():
		_update_skill_button(stat_name)

func _update_skill_button(stat_name: String):
	var panel = skill_buttons[stat_name]
	var points_invested = level_system.get_points_in_stat(stat_name)
	var current_value = level_system.get_stat_value(stat_name)
	var max_points = 50
	if stat_name == "crit_chance":
		max_points = 25
	
	# Update value label
	var value_label = panel.find_child("ValueLabel", true, false)
	if value_label:
		match stat_name:
			"health":
				value_label.text = "Current: %.0f HP" % current_value
			"speed":
				value_label.text = "Current: %.0f" % current_value
			"damage", "fire_rate", "luck":
				value_label.text = "Current: %.0f%% (x%.2f)" % [(current_value * 100), current_value]
			"crit_chance":
				value_label.text = "Current: %.1f%%" % (current_value * 100)
			"crit_damage":
				value_label.text = "Current: %.0f%% (x%.2f)" % [(current_value * 100), current_value]
	
	# Update points label
	var points_label = panel.find_child("PointsLabel", true, false)
	if points_label:
		points_label.text = "Points: %d/%d" % [points_invested, max_points]
	
	# Update button state
	var button = panel.find_child("UpgradeButton", true, false)
	if button:
		var can_upgrade = level_system.skill_points > 0 and points_invested < max_points
		button.disabled = not can_upgrade

func open():
	print("\n=== OPENING SKILL TREE ===")
	visible = true
	if background:
		background.visible = true
	get_tree().paused = true
	_update_ui()
	print("Skill tree is now VISIBLE and game is PAUSED")
	print("===========================\n")

func close():
	print("\n=== CLOSING SKILL TREE ===")
	visible = false
	if background:
		background.visible = false
	get_tree().paused = false
	skill_tree_closed.emit()
	print("Skill tree is now HIDDEN and game is UNPAUSED")
	print("===========================\n")

func _on_close_button_pressed():
	print(">>> CLOSE BUTTON (X) PRESSED <<<")
	close()

func _on_continue_button_pressed():
	print(">>> CONTINUE BUTTON PRESSED <<<")
	close()

func _on_reset_button_pressed():
	if not level_system:
		return
	
	print("Reset not implemented - add confirmation dialog")
	# You can add a confirmation dialog here

func _on_experience_gained(amount: int, total: int):
	# Update XP bar in real-time if UI is open
	if visible:
		_update_ui()

func _on_skill_point_spent(stat_name: String, new_value: float):
	_update_ui()

# Handle ESC key to close
func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		print(">>> ESC KEY PRESSED IN SKILL TREE <<<")
		close()
		get_viewport().set_input_as_handled()
