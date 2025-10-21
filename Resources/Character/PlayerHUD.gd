# ============================================
# PLAYER HUD (PlayerHUD.gd)
# ============================================
# PURPOSE: Display player stats and info at top of screen during gameplay
#
# FEATURES:
# - Level display (center top)
# - Health bar with current/max HP (center)
# - XP bar with progress to next level (center)
# - Primary weapon display [1] (left side)
# - Secondary weapon display [2] (right side)
# - Active weapon highlighted (brighter)
# - Updates in real-time
#
# DISPLAYED INFO:
# - Current level
# - HP: Current / Max
# - XP: Current / Required for next level
# - Equipped weapons with icons
# - Which weapon is currently active
#
# KEY FUNCTIONS:
# - setup() - Initialize HUD with player references
# - _update_display() - Refresh all HUD elements
# - _update_health() - Update health bar
# - _update_weapons() - Update weapon displays
# ============================================

extends CanvasLayer
class_name PlayerHUD

# ==========================================
# UI ELEMENT REFERENCES
# ==========================================

# Stats elements (center panel)
@onready var level_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/LevelLabel  # "Level X"
@onready var health_bar = $TopCenterContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthBar  # Red HP bar
@onready var health_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthLabel  # "X / Y"
@onready var xp_bar = $TopCenterContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPBar  # Blue XP bar
@onready var xp_label = $TopCenterContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPLabel  # "X / Y XP"

# Weapon elements (left panel - Primary weapon [1])
@onready var primary_container = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer
@onready var primary_label = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryLabel  # Weapon name
@onready var primary_icon = $TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryIcon if has_node("TopCenterContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryIcon") else null  # Weapon icon

# Weapon elements (right panel - Secondary weapon [2])
@onready var secondary_container = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer
@onready var secondary_label = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryLabel  # Weapon name
@onready var secondary_icon = $TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryIcon if has_node("TopCenterContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryIcon") else null  # Weapon icon

# ==========================================
# REFERENCES TO GAME SYSTEMS
# ==========================================
var level_system: PlayerLevelSystem  # Player's level/XP system
var weapon_manager: WeaponManager  # Player's weapon manager
var player: Node2D  # The player node itself (for health)

func _ready():
	"""Initialize the HUD when it's added to the scene"""
	print("\n=== PlayerHUD _ready ===")
	
	# Get player reference from parent (HUD is child of player)
	if not player:
		player = get_parent()
		print("Got player from parent: ", player)
	
	# Position and configure the top container
	var top_container = $TopCenterContainer
	if top_container:
		# Anchor to BOTTOM center of screen
		top_container.anchor_left = 0.5
		top_container.anchor_right = 0.5
		top_container.anchor_top = 1.0  # Changed from 0 to 1.0 (bottom)
		top_container.anchor_bottom = 1.0  # Changed from 0 to 1.0 (bottom)
		
		# Allow container to grow in both directions from center
		top_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		top_container.grow_vertical = Control.GROW_DIRECTION_BEGIN  # Grow upward from bottom
		top_container.pivot_offset = Vector2(0, 0)
		
		# Set margins (spacing from screen edges)
		top_container.add_theme_constant_override("margin_top", 0)
		top_container.add_theme_constant_override("margin_bottom", 50)  # Space from bottom
		top_container.add_theme_constant_override("margin_left", 0)
		top_container.add_theme_constant_override("margin_right", 0)
	
	# Configure horizontal spacing between HUD elements
	var hbox = $TopCenterContainer/HBoxContainer
	if hbox:
		hbox.add_theme_constant_override("separation", 15)  # 15 pixels between elements
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER  # Center all elements
	
	# Apply visual styling to all HUD elements
	_style_ui()

func _style_ui():
	"""
	Set up the visual appearance of all HUD elements
	
	CUSTOMIZATION GUIDE:
	- To change colors: Modify Color(r, g, b) values (0.0 to 1.0)
	- To change sizes: Modify Vector2(width, height) in custom_minimum_size
	- To change fonts: Change font_size values
	- To change bar appearance: Modify StyleBoxFlat properties
	"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# ==========================================
	# CENTER STATS PANEL STYLING
	# ==========================================
	
	# LEVEL LABEL - Big gold text showing "Level X"
	if level_label:
		level_label.text = "Level 1"
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_override("font", pixel_font)
		level_label.add_theme_font_size_override("font_size", 24)  # Size of level text
		level_label.add_theme_color_override("font_color", Color(0.87, 0.72, 0.53))  # Gold/tan color
		level_label.add_theme_color_override("font_outline_color", Color.BLACK)  # Black outline
		level_label.add_theme_constant_override("outline_size", 3)  # Outline thickness
	
	# HEALTH BAR - Red bar showing HP
	if health_bar:
		health_bar.custom_minimum_size = Vector2(250, 25)  # Bar size: 250px wide, 25px tall
		health_bar.show_percentage = false  # Don't show percentage, we use custom label
		
		# Background (empty part of bar) - dark gray
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray, 80% opacity
		bg_style.border_width_left = 3
		bg_style.border_width_right = 3
		bg_style.border_width_top = 3
		bg_style.border_width_bottom = 3
		bg_style.border_color = Color(0.0, 0.0, 0.0)  # Black border
		health_bar.add_theme_stylebox_override("background", bg_style)
		# ADD SHADOW HERE ⬇️
		bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)  # Black shadow, 50% opacity
		bg_style.shadow_size = 4  # Shadow blur radius (bigger = more blurred)
		bg_style.shadow_offset = Vector2(2, 2)  # Shadow position (X, Y offset from bar)
	# ⬆️ END SHADOW
		# Fill (full part of bar) - red
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.8, 0.2, 0.2)  # Red color
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	# HEALTH LABEL - Shows "X / Y" HP text on top of health bar
	if health_label:
		health_label.add_theme_font_override("font", pixel_font)
		health_label.add_theme_font_size_override("font_size", 14)  # Text size
		health_label.add_theme_color_override("font_color", Color.WHITE)  # White text
		health_label.add_theme_color_override("font_outline_color", Color.BLACK)  # Black outline
		health_label.add_theme_constant_override("outline_size", 2)  # Outline thickness
		health_label.custom_minimum_size = Vector2(80, 0)  # Minimum width
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# XP BAR - Blue bar showing experience progress
	if xp_bar:
		xp_bar.custom_minimum_size = Vector2(250, 20)  # Bar size: 250px wide, 20px tall
		xp_bar.show_percentage = false  # Don't show percentage, we use custom label
		
		# Background (empty part of bar) - dark gray
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_width_top = 2
		bg_style.border_width_bottom = 2
		bg_style.border_color = Color(0.5, 0.5, 0.5)  # Gray border
		xp_bar.add_theme_stylebox_override("background", bg_style)
		
		#Shadow
		bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)  # Black shadow, 50% opacity
		bg_style.shadow_size = 4  # Shadow blur radius (bigger = more blurred)
		bg_style.shadow_offset = Vector2(2, 2)  # Shadow position (X, Y offset from bar)
		# Fill (full part of bar) - blue
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.3, 0.7, 1.0)  # Cyan/blue color
		xp_bar.add_theme_stylebox_override("fill", fill_style)
	
	# XP LABEL - Shows "X / Y" XP text on top of XP bar
	if xp_label:
		xp_label.add_theme_font_override("font", pixel_font)
		xp_label.add_theme_font_size_override("font_size", 12)  # Smaller than health text
		xp_label.add_theme_color_override("font_color", Color.WHITE)
		xp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		xp_label.add_theme_constant_override("outline_size", 2)
		xp_label.custom_minimum_size = Vector2(80, 0)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# ==========================================
	# WEAPON PANEL STYLING
	# ==========================================
	
	# PRIMARY WEAPON (Left side - Slot [1])
	if primary_container:
		primary_container.custom_minimum_size = Vector2(150, 80)  # Size of weapon panel
		primary_container.add_theme_constant_override("separation", 5)  # Space between icon and label

	if primary_icon:
		primary_icon.custom_minimum_size = Vector2(50, 50)  # Size of weapon icon
		primary_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		primary_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep icon centered

	if primary_label:
		primary_label.text = "Empty"  # Default text when no weapon
		primary_label.add_theme_font_override("font", pixel_font)
		primary_label.add_theme_font_size_override("font_size", 14)  # Weapon name text size
		primary_label.add_theme_color_override("font_color", Color.WHITE)
		primary_label.add_theme_color_override("font_outline_color", Color.BLACK)
		primary_label.add_theme_constant_override("outline_size", 2)
		primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# SECONDARY WEAPON (Right side - Slot [2])
	# Same styling as primary weapon
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
	"""
	Initialize the HUD with references to player systems
	
	MUST BE CALLED from player script after HUD is created!
	
	Parameters:
	- player_node: The player Node2D (for health)
	- player_level_system: Player's level/XP system
	- player_weapon_manager: Player's weapon manager (optional)
	"""
	print("\n=== PlayerHUD setup called ===")
	print("Player: ", player_node)
	print("Level System: ", player_level_system)
	print("Weapon Manager: ", player_weapon_manager)
	
	# Store references
	player = player_node
	level_system = player_level_system
	weapon_manager = player_weapon_manager
	
	# Connect to level system signals to update when level/XP changes
	if level_system:
		if not level_system.level_up.is_connected(_on_level_up):
			level_system.level_up.connect(_on_level_up)
		if not level_system.experience_gained.is_connected(_on_experience_gained):
			level_system.experience_gained.connect(_on_experience_gained)
		print("✓ Connected to level system signals")
	
	# Connect to weapon manager signals to update when weapons change
	if weapon_manager:
		print("Weapon manager found, connecting signals...")
		if not weapon_manager.weapon_equipped.is_connected(_on_weapon_equipped):
			weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
		if not weapon_manager.weapon_unequipped.is_connected(_on_weapon_unequipped):
			weapon_manager.weapon_unequipped.connect(_on_weapon_unequipped)
		if not weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
			weapon_manager.weapon_switched.connect(_on_weapon_switched)
		print("✓ Connected to weapon manager signals")
		
		# Debug: Log current weapon state
		print("  Active slot: ", weapon_manager.active_slot)
		print("  Primary weapon: ", weapon_manager.get_weapon_in_slot(0))
		print("  Secondary weapon: ", weapon_manager.get_weapon_in_slot(1))
	else:
		print("⚠ WARNING: No weapon manager provided to HUD!")
	
	# Initial display update
	_update_display()
	print("✓ Player HUD setup complete\n")

func _process(_delta):
	"""Called every frame - continuously update health display"""
	# Health can change frequently (damage, healing), so update every frame
	_update_health()

func _update_display():
	"""
	Update all HUD elements (called when significant changes occur)
	- Level changes
	- XP gain
	- Weapon changes
	"""
	print("HUD _update_display called")
	
	# Update level and XP display
	if level_system:
		# Update level label ("Level X")
		if level_label:
			level_label.text = "Level " + str(level_system.current_level)
		
		# Update XP bar (shows progress to next level)
		if xp_bar:
			xp_bar.max_value = level_system.experience_to_next_level  # How much XP needed
			xp_bar.value = level_system.current_experience  # How much XP we have
		
		# Update XP text ("X / Y")
		if xp_label:
			xp_label.text = str(level_system.current_experience) + " / " + str(level_system.experience_to_next_level)
	else:
		print("⚠ No level system in _update_display")
	
	# Update weapon displays
	_update_weapons()
	
	# Update health display
	_update_health()

func _update_health():
	"""
	Update the health bar and label
	Called every frame in _process() to show real-time health changes
	"""
	# Try to get player reference if we don't have it
	if not player:
		player = get_parent()
	
	if not player:
		return  # Can't update without player reference
	
	# Update health bar fill amount
	if health_bar:
		health_bar.max_value = player.max_health  # Maximum HP
		health_bar.value = player.current_health  # Current HP
	
	# Update health text ("X / Y")
	if health_label:
		health_label.text = str(int(player.current_health)) + " / " + str(int(player.max_health))

func _update_weapons():
	"""
	Update weapon displays (icons, names, highlighting)
	Shows which weapons are equipped and which one is active
	"""
	if not weapon_manager:
		return  # Can't update without weapon manager
	
	# ==========================================
	# UPDATE PRIMARY WEAPON (Slot [1])
	# ==========================================
	var primary_weapon = weapon_manager.get_weapon_in_slot(0)
	if primary_weapon:
		# Weapon is equipped in primary slot
		primary_label.text = primary_weapon.name  # Show weapon name
		
		# Show weapon icon if available
		if primary_icon and primary_weapon.icon:
			primary_icon.texture = primary_weapon.icon
			primary_icon.visible = true
		
		# Highlight if this is the currently active weapon
		if weapon_manager.active_slot == 0:
			primary_container.modulate = Color(1.2, 1.2, 1.2)  # Brighter (20% brighter)
		else:
			primary_container.modulate = Color(1, 1, 1)  # Normal brightness
	else:
		# No weapon equipped in primary slot
		primary_label.text = "Empty"
		if primary_icon:
			primary_icon.visible = false  # Hide icon
		primary_container.modulate = Color(0.6, 0.6, 0.6)  # Dim (40% darker)
	
	# ==========================================
	# UPDATE SECONDARY WEAPON (Slot [2])
	# ==========================================
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	if secondary_weapon:
		# Weapon is equipped in secondary slot
		secondary_label.text = secondary_weapon.name
		
		# Show weapon icon if available
		if secondary_icon and secondary_weapon.icon:
			secondary_icon.texture = secondary_weapon.icon
			secondary_icon.visible = true
		
		# Highlight if this is the currently active weapon
		if weapon_manager.active_slot == 1:
			secondary_container.modulate = Color(1.2, 1.2, 1.2)  # Brighter
		else:
			secondary_container.modulate = Color(1, 1, 1)  # Normal
	else:
		# No weapon equipped in secondary slot
		secondary_label.text = "Empty"
		if secondary_icon:
			secondary_icon.visible = false
		secondary_container.modulate = Color(0.6, 0.6, 0.6)  # Dim

# ==========================================
# SIGNAL HANDLERS
# ==========================================
# These functions are called automatically when events occur

func _on_level_up(new_level: int, _skill_points_gained: int):
	"""Called when player levels up - refresh display"""
	_update_display()

func _on_experience_gained(_amount: int, _total: int):
	"""Called when player gains XP - refresh display"""
	_update_display()

func _on_weapon_equipped(_slot: int, _weapon: WeaponItem):
	"""Called when a weapon is equipped - refresh weapon displays"""
	_update_weapons()

func _on_weapon_unequipped(_slot: int):
	"""Called when a weapon is unequipped - refresh weapon displays"""
	_update_weapons()

func _on_weapon_switched(_new_slot: int, _weapon: Gun):
	"""Called when player switches active weapon (press 1 or 2) - refresh weapon displays"""
	_update_weapons()


# ============================================
# CUSTOMIZATION GUIDE
# ============================================
#
# HOW TO CHANGE COLORS:
# ----------------------
# Find the _style_ui() function above
#
# Health Bar Color:
#   fill_style.bg_color = Color(0.8, 0.2, 0.2)  # Current: Red
#   Change to: Color(0.2, 0.8, 0.2) for green
#              Color(1.0, 0.5, 0.0) for orange
#
# XP Bar Color:
#   fill_style.bg_color = Color(0.3, 0.7, 1.0)  # Current: Blue
#   Change to: Color(1.0, 0.8, 0.0) for gold
#              Color(0.5, 0.0, 1.0) for purple
#
# Level Text Color:
#   Color(0.87, 0.72, 0.53)  # Current: Gold/tan
#   Change to: Color(1, 1, 1) for white
#              Color(1, 0.9, 0.4) for brighter gold
#
# HOW TO CHANGE SIZES:
# ---------------------
#
# Health Bar Size:
#   health_bar.custom_minimum_size = Vector2(250, 25)
#   Change first number for width (250 = 250 pixels)
#   Change second number for height (25 = 25 pixels)
#
# XP Bar Size:
#   xp_bar.custom_minimum_size = Vector2(250, 20)
#
# Weapon Panel Size:
#   primary_container.custom_minimum_size = Vector2(150, 80)
#
# Weapon Icon Size:
#   primary_icon.custom_minimum_size = Vector2(50, 50)
#
# HOW TO CHANGE FONT SIZES:
# --------------------------
#
# Level Text:
#   .add_theme_font_size_override("font_size", 24)
#   Change 24 to desired size (bigger = larger text)
#
# Health Text:
#   .add_theme_font_size_override("font_size", 14)
#
# XP Text:
#   .add_theme_font_size_override("font_size", 12)
#
# Weapon Name Text:
#   .add_theme_font_size_override("font_size", 14)
#
# HOW TO REPOSITION HUD:
# -----------------------
#
# Top Margin (distance from top of screen):
#   top_container.add_theme_constant_override("margin_top", 10)
#   Change 10 to desired pixels from top
#
# Spacing Between Elements:
#   hbox.add_theme_constant_override("separation", 15)
#   Change 15 to desired spacing in pixels
#
# HOW TO ADD OUTLINE/SHADOW TO TEXT:
# ------------------------------------
#
# Outline Color:
#   .add_theme_color_override("font_outline_color", Color.BLACK)
#   Change Color.BLACK to desired outline color
#
# Outline Thickness:
#   .add_theme_constant_override("outline_size", 3)
#   Change 3 to desired thickness (0 = no outline)
#
# HOW TO HIDE/SHOW ELEMENTS:
# ----------------------------
#
# To hide weapon icons completely:
#   In _style_ui(), add:
#   primary_icon.visible = false
#   secondary_icon.visible = false
#
# To hide XP bar:
#   In _style_ui(), add:
#   xp_bar.visible = false
#   xp_label.visible = false
#
# ============================================
