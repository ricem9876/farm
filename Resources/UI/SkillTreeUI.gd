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

# Skill definitions with icons and descriptions
var skill_data = {
	"health": {
		"display_name": "Max Health",
		"description": "+10 HP per point",
		"icon": "❤️",
		"color": Color(1, 0.3, 0.3)
	},
	"speed": {
		"display_name": "Movement Speed",
		"description": "+5% speed per point",
		"icon": "⚡",
		"color": Color(0.3, 1, 1)
	},
	"damage": {
		"display_name": "Weapon Damage",
		"description": "+5% damage per point",
		"icon": "⚔️",
		"color": Color(1, 0.5, 0.2)
	},
	"fire_rate": {
		"display_name": "Fire Rate",
		"description": "+4% fire rate per point",
		"icon": "🔥",
		"color": Color(1, 0.8, 0.2)
	},
	"reload": {
		"display_name": "Reload Speed",
		"description": "+6% reload speed per point",
		"icon": "🔄",
		"color": Color(0.5, 0.5, 1)
	},
	"crit_chance": {
		"display_name": "Critical Chance",
		"description": "+2% crit chance per point (Max 25)",
		"icon": "💥",
		"color": Color(1, 1, 0.3)
	},
	"crit_damage": {
		"display_name": "Critical Damage",
		"description": "+10% crit damage per point",
		"icon": "💢",
		"color": Color(1, 0.3, 1)
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
		level_system.level_up.connect(_on_level_up)
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
	var data = skill_data[stat_name]
	
	# Main panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = data.color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	# Main HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)
	
	# Left side - Info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Title with icon
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = data.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	title_hbox.add_child(icon_label)
	
	var title_label = Label.new()
	title_label.text = data.display_name
	title_label.add_theme_color_override("font_color", data.color)
	title_label.add_theme_font_size_override("font_size", 18)
	title_hbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = data.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc_label)
	
	# Current value
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "Current: 0"
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	vbox.add_child(value_label)
	
	# Right side - Points and Button
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(right_vbox)
	
	# Points invested
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Points: 0/50"
	points_label.add_theme_font_size_override("font_size", 14)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(points_label)
	
	# Upgrade button
	var button = Button.new()
	button.name = "UpgradeButton"
	button.text = "Upgrade"
	button.custom_minimum_size = Vector2(100, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_on_upgrade_button_pressed.bind(stat_name))
	right_vbox.add_child(button)
	
	return panel

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
			"damage", "fire_rate", "reload":
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
		
		if can_upgrade:
			button.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
		else:
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

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

func _on_level_up(new_level: int, skill_points_gained: int):
	# Auto-open when leveling up
	print("Level up detected! Opening skill tree...")
	open()
	_update_ui()

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
