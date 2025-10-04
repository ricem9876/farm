extends CanvasLayer
class_name PlayerHUD

# Stats elements
@onready var level_label = $TopContainer/HBoxContainer/CenterStatsPanel/LevelLabel
@onready var health_bar = $TopContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthBar
@onready var health_label = $TopContainer/HBoxContainer/CenterStatsPanel/HealthBarContainer/HealthLabel
@onready var xp_bar = $TopContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPBar
@onready var xp_label = $TopContainer/HBoxContainer/CenterStatsPanel/XPBarContainer/XPLabel

# Weapon elements
@onready var primary_container = $TopContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer
@onready var primary_label = $TopContainer/HBoxContainer/LeftWeaponPanel/PrimaryContainer/PrimaryLabel
@onready var secondary_container = $TopContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer
@onready var secondary_label = $TopContainer/HBoxContainer/RightWeaponPanel/SecondaryContainer/SecondaryLabel

var level_system: PlayerLevelSystem
var weapon_manager: WeaponManager
var player: Node2D

func _ready():
	print("\n=== PlayerHUD _ready ===")
	
	var top_container = $TopContainer
	if top_container:
		# Position at top center
		top_container.anchor_left = 0
		top_container.anchor_right = 1
		top_container.anchor_top = 0
		top_container.anchor_bottom = 0
		
		top_container.add_theme_constant_override("margin_left", 100)
		top_container.add_theme_constant_override("margin_right", 100)
		top_container.add_theme_constant_override("margin_top", 10)
	
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
	
	# Primary weapon (left)
	if primary_container:
		primary_container.custom_minimum_size = Vector2(150, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.6, 1.0)  # Blue
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		primary_container.add_theme_stylebox_override("panel", style)
	
	if primary_label:
		primary_label.text = "Empty"
		primary_label.add_theme_font_override("font", pixel_font)
		primary_label.add_theme_font_size_override("font_size", 16)
		primary_label.add_theme_color_override("font_color", Color.WHITE)
		primary_label.add_theme_color_override("font_outline_color", Color.BLACK)
		primary_label.add_theme_constant_override("outline_size", 2)
		primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		primary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Secondary weapon (right)
	if secondary_container:
		secondary_container.custom_minimum_size = Vector2(150, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.6, 0.4, 1.0)  # Purple
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		secondary_container.add_theme_stylebox_override("panel", style)
	
	if secondary_label:
		secondary_label.text = "Empty"
		secondary_label.add_theme_font_override("font", pixel_font)
		secondary_label.add_theme_font_size_override("font_size", 16)
		secondary_label.add_theme_color_override("font_color", Color.WHITE)
		secondary_label.add_theme_color_override("font_outline_color", Color.BLACK)
		secondary_label.add_theme_constant_override("outline_size", 2)
		secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		secondary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func setup(player_node: Node2D, player_level_system: PlayerLevelSystem, player_weapon_manager: WeaponManager = null):
	player = player_node
	level_system = player_level_system
	weapon_manager = player_weapon_manager
	
	# Connect level system signals
	if level_system:
		level_system.level_up.connect(_on_level_up)
		level_system.experience_gained.connect(_on_experience_gained)
	
	# Connect weapon manager signals
	if weapon_manager:
		weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
		weapon_manager.weapon_unequipped.connect(_on_weapon_unequipped)
		weapon_manager.weapon_switched.connect(_on_weapon_switched)
		print("Connected to weapon manager signals")
	
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
		if weapon_manager.active_slot == 0:
			primary_container.modulate = Color(1.2, 1.2, 1.2)
		else:
			primary_container.modulate = Color(1, 1, 1)
	else:
		primary_label.text = "Empty"
		primary_container.modulate = Color(0.6, 0.6, 0.6)
	
	# Update secondary weapon
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	if secondary_weapon:
		secondary_label.text = secondary_weapon.name
		if weapon_manager.active_slot == 1:
			secondary_container.modulate = Color(1.2, 1.2, 1.2)
		else:
			secondary_container.modulate = Color(1, 1, 1)
	else:
		secondary_label.text = "Empty"
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
