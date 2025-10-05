extends CanvasLayer
class_name PlayerHUD

# Stats elements
@onready var level_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/LevelLabel
@onready var health_bar = $TopCenterContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthBar
@onready var health_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthLabel
@onready var xp_bar = $TopCenterContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPBar
@onready var xp_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPLabel

# Weapon elements
@onready var primary_container = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer
@onready var primary_label = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryLabel
@onready var primary_icon = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryIcon if has_node("TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryIcon") else null

@onready var secondary_container = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer
@onready var secondary_label = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryLabel
@onready var secondary_icon = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryIcon if has_node("TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryIcon") else null

var level_system: PlayerLevelSystem
var weapon_manager: WeaponManager
var player: Node2D

func _ready():
	print("\n=== PlayerHUD _ready ===")
	
	var top_container = $TopCenterContainer
	if top_container:
		# Position at top center with proper anchoring
		top_container.anchor_left = 0.5
		top_container.anchor_right = 0.5
		top_container.anchor_top = 0
		top_container.anchor_bottom = 0
		
		# Center the container by offsetting from the center anchor
		top_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		top_container.pivot_offset = Vector2(0, 0)
		
		# Set margins
		top_container.add_theme_constant_override("margin_top", 10)
		top_container.add_theme_constant_override("margin_bottom", 0)
		top_container.add_theme_constant_override("margin_left", 0)
		top_container.add_theme_constant_override("margin_right", 0)
	
	# Add spacing to the HBoxContainer
	var hbox = $TopCenterContainer/HBoxContainer
	if hbox:
		hbox.add_theme_constant_override("separation", 15)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	_style_ui()

func _style_ui():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# === CENTER STATS STYLING ===
	
	# Level label
	if level_label:
		level_label.text = "Level 1"
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_override("font", pixel_font)
		level_label.add_theme_font_size_override("font_size", 24)
		level_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		level_label.add_theme_color_override("font_outline_color", Color.BLACK)
		level_label.add_theme_constant_override("outline_size", 3)
	
	# Health Bar
	if health_bar:
		health_bar.custom_minimum_size = Vector2(250, 25)
		health_bar.show_percentage = false
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_width_top = 2
		bg_style.border_width_bottom = 2
		bg_style.border_color = Color(0.5, 0.5, 0.5)
		health_bar.add_theme_stylebox_override("background", bg_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.8, 0.2, 0.2)
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Health Label
	if health_label:
		health_label.add_theme_font_override("font", pixel_font)
		health_label.add_theme_font_size_override("font_size", 14)
		health_label.add_theme_color_override("font_color", Color.WHITE)
		health_label.add_theme_color_override("font_outline_color", Color.BLACK)
		health_label.add_theme_constant_override("outline_size", 2)
		health_label.custom_minimum_size = Vector2(80, 0)
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# XP Bar
	if xp_bar:
		xp_bar.custom_minimum_size = Vector2(250, 20)
		xp_bar.show_percentage = false
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_width_top = 2
		bg_style.border_width_bottom = 2
		bg_style.border_color = Color(0.5, 0.5, 0.5)
		xp_bar.add_theme_stylebox_override("background", bg_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.3, 0.7, 1.0)
		xp_bar.add_theme_stylebox_override("fill", fill_style)
	
	# XP Label
	if xp_label:
		xp_label.add_theme_font_override("font", pixel_font)
		xp_label.add_theme_font_size_override("font_size", 12)
		xp_label.add_theme_color_override("font_color", Color.WHITE)
		xp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		xp_label.add_theme_constant_override("outline_size", 2)
		xp_label.custom_minimum_size = Vector2(80, 0)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# === WEAPON STYLING ===
	
	# === WEAPON STYLING ===

# Primary weapon (left)
	# Primary weapon (left)
	if primary_container:
		primary_container.custom_minimum_size = Vector2(150, 80)
		primary_container.add_theme_constant_override("separation", 5)  # Space between icon and label

	if primary_icon:
		primary_icon.custom_minimum_size = Vector2(50, 50)
		primary_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		primary_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if primary_label:
		primary_label.text = "Empty"
		primary_label.add_theme_font_override("font", pixel_font)
		primary_label.add_theme_font_size_override("font_size", 14)
		primary_label.add_theme_color_override("font_color", Color.WHITE)
		primary_label.add_theme_color_override("font_outline_color", Color.BLACK)
		primary_label.add_theme_constant_override("outline_size", 2)
		primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Same for secondary
	if secondary_container:
		secondary_container.custom_minimum_size = Vector2(150, 80)
		secondary_container.add_theme_constant_override("separation", 5)

	if secondary_icon:
		secondary_icon.custom_minimum_size = Vector2(50, 50)
		secondary_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		secondary_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if secondary_label:
		secondary_label.text = "Empty"
		secondary_label.add_theme_font_override("font", pixel_font)
		secondary_label.add_theme_font_size_override("font_size", 14)
		secondary_label.add_theme_color_override("font_color", Color.WHITE)
		secondary_label.add_theme_color_override("font_outline_color", Color.BLACK)
		secondary_label.add_theme_constant_override("outline_size", 2)
		secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
func setup(player_node: Node2D, player_level_system: PlayerLevelSystem, player_weapon_manager: WeaponManager = null):
	print("\n=== PlayerHUD setup called ===")
	print("Player: ", player_node)
	print("Level System: ", player_level_system)
	print("Weapon Manager: ", player_weapon_manager)
	
	player = player_node
	level_system = player_level_system
	weapon_manager = player_weapon_manager
	
	# Connect level system signals
	if level_system:
		level_system.level_up.connect(_on_level_up)
		level_system.experience_gained.connect(_on_experience_gained)
		print("Connected to level system signals")
	
	# Connect weapon manager signals
	if weapon_manager:
		print("Weapon manager found, connecting signals...")
		weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
		weapon_manager.weapon_unequipped.connect(_on_weapon_unequipped)
		weapon_manager.weapon_switched.connect(_on_weapon_switched)
		print("Connected to weapon manager signals")
		
		# Debug current weapons
		print("Active slot: ", weapon_manager.active_slot)
		print("Primary weapon: ", weapon_manager.get_weapon_in_slot(0))
		print("Secondary weapon: ", weapon_manager.get_weapon_in_slot(1))
	else:
		print("WARNING: No weapon manager provided to HUD!")
	
	_update_display()

func _process(_delta):
	_update_health()

func _update_display():
	# Update stats
	if level_system:
		if level_label:
			level_label.text = "Level " + str(level_system.current_level)
		
		if xp_bar:
			xp_bar.max_value = level_system.experience_to_next_level
			xp_bar.value = level_system.current_experience
		
		if xp_label:
			xp_label.text = str(level_system.current_experience) + " / " + str(level_system.experience_to_next_level)
	
	# Update weapons
	_update_weapons()
	_update_health()

func _update_health():
	if not player:
		return
	
	if health_bar:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
	
	if health_label:
		health_label.text = str(int(player.current_health)) + " / " + str(int(player.max_health))

func _update_weapons():
	if not weapon_manager:
		return
	
	# Update primary weapon
	var primary_weapon = weapon_manager.get_weapon_in_slot(0)
	if primary_weapon:
		primary_label.text = primary_weapon.name
		if primary_icon and primary_weapon.icon:
			primary_icon.texture = primary_weapon.icon
			primary_icon.visible = true
		
		if weapon_manager.active_slot == 0:
			primary_container.modulate = Color(1.2, 1.2, 1.2)
		else:
			primary_container.modulate = Color(1, 1, 1)
	else:
		primary_label.text = "Empty"
		if primary_icon:
			primary_icon.visible = false
		primary_container.modulate = Color(0.6, 0.6, 0.6)
	
	# Update secondary weapon
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	if secondary_weapon:
		secondary_label.text = secondary_weapon.name
		if secondary_icon and secondary_weapon.icon:
			secondary_icon.texture = secondary_weapon.icon
			secondary_icon.visible = true
		
		if weapon_manager.active_slot == 1:
			secondary_container.modulate = Color(1.2, 1.2, 1.2)
		else:
			secondary_container.modulate = Color(1, 1, 1)
	else:
		secondary_label.text = "Empty"
		if secondary_icon:
			secondary_icon.visible = false
		secondary_container.modulate = Color(0.6, 0.6, 0.6)
		
# Signal handlers
func _on_level_up(new_level: int, skill_points_gained: int):
	_update_display()

func _on_experience_gained(amount: int, total: int):
	_update_display()

func _on_weapon_equipped(slot: int, weapon: WeaponItem):
	_update_weapons()

func _on_weapon_unequipped(slot: int):
	_update_weapons()

func _on_weapon_switched(new_slot: int):
	_update_weapons()
