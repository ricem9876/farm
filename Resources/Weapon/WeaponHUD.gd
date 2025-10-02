extends Control
class_name WeaponHUD

@onready var primary_panel = $HBoxContainer/PrimaryWeaponPanel
@onready var secondary_panel = $HBoxContainer/SecondaryWeaponPanel
@onready var primary_icon = $HBoxContainer/PrimaryWeaponPanel/VBoxContainer/PrimaryIcon
@onready var secondary_icon = $HBoxContainer/SecondaryWeaponPanel/VBoxContainer/SecondaryIcon
@onready var primary_label = $HBoxContainer/PrimaryWeaponPanel/VBoxContainer/PrimaryLabel
@onready var secondary_label = $HBoxContainer/SecondaryWeaponPanel/VBoxContainer/SecondaryLabel
@onready var primary_key_label = $HBoxContainer/PrimaryWeaponPanel/KeyLabel
@onready var secondary_key_label = $HBoxContainer/SecondaryWeaponPanel/KeyLabel

var weapon_manager: WeaponManager
var player: Node2D

# Positioning
var offset_from_player_bottom: float = -130.0  # Distance below player

func _ready():
	scale = Vector2(2, 2)
	anchors_preset = Control.PRESET_CENTER_BOTTOM
	offset_top = -175
	offset_bottom = -100
	_setup_styling()

func setup_hud(manager: WeaponManager, player_node: Node2D):
	print("\n=== WEAPON HUD SETUP DEBUG ===")
	print("manager: ", manager)
	print("player_node: ", player_node)
	
	# Check if manager is null before proceeding
	if not manager:
		print("✗ ERROR: WeaponManager is NULL! Cannot setup HUD")
		print("  The WeaponHUD will be hidden")
		visible = false
		print("=== END DEBUG ===\n")
		return
	
	weapon_manager = manager
	player = player_node
	
	# Safe signal connections - check if signals exist
	if weapon_manager.has_signal("weapon_equipped"):
		weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
		print("✓ Connected to weapon_equipped signal")
	else:
		print("⚠ Warning: WeaponManager missing 'weapon_equipped' signal")
	
	if weapon_manager.has_signal("weapon_unequipped"):
		weapon_manager.weapon_unequipped.connect(_on_weapon_unequipped)
		print("✓ Connected to weapon_unequipped signal")
	else:
		print("⚠ Warning: WeaponManager missing 'weapon_unequipped' signal")
	
	if weapon_manager.has_signal("weapon_switched"):
		weapon_manager.weapon_switched.connect(_on_weapon_switched)
		print("✓ Connected to weapon_switched signal")
	else:
		print("⚠ Warning: WeaponManager missing 'weapon_switched' signal")
	
	print("=== END DEBUG ===\n")
	
	# Initial update
	_update_display()


	
func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style primary panel
	if primary_panel:
		_style_weapon_panel(primary_panel, Color(0.2, 0.3, 0.4), true)
	
	# Style secondary panel
	if secondary_panel:
		_style_weapon_panel(secondary_panel, Color(0.25, 0.25, 0.3), false)
	
	# Style labels
	for label in [primary_label, secondary_label]:
		if label:
			label.add_theme_font_override("font", pixel_font)
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", Color.WHITE)
	
	# Style key labels
	for key_label in [primary_key_label, secondary_key_label]:
		if key_label:
			key_label.add_theme_font_override("font", pixel_font)
			key_label.add_theme_font_size_override("font_size", 10)
			key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _style_weapon_panel(panel: Panel, base_color: Color, is_active: bool):
	if not panel:
		return
	
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	
	if is_active:
		style.border_color = Color(1.0, 0.8, 0.2)  # Gold border for active
		style.shadow_color = Color(1.0, 0.8, 0.2, 0.4)
		style.shadow_size = 6
	else:
		style.border_color = Color(0.4, 0.4, 0.5)  # Gray border for inactive
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	panel.add_theme_stylebox_override("panel", style)

func _update_display():
	if not weapon_manager:
		return
	
	# Update primary weapon
	var primary_weapon = weapon_manager.get_weapon_in_slot(0)
	if primary_weapon:
		primary_icon.texture = primary_weapon.icon
		primary_label.text = primary_weapon.name
	else:
		primary_icon.texture = null
		primary_label.text = "Empty"
	
	# Update secondary weapon
	var secondary_weapon = weapon_manager.get_weapon_in_slot(1)
	if secondary_weapon:
		secondary_icon.texture = secondary_weapon.icon
		secondary_label.text = secondary_weapon.name
	else:
		secondary_icon.texture = null
		secondary_label.text = "Empty"
	
	# Update active state highlighting
	_update_active_state()

func _update_active_state():
	var active_slot = weapon_manager.get_active_slot()
	
	# Highlight active weapon panel
	_style_weapon_panel(primary_panel, Color(0.2, 0.3, 0.4), active_slot == 0)
	_style_weapon_panel(secondary_panel, Color(0.25, 0.25, 0.3), active_slot == 1)

func _on_weapon_equipped(slot: int, weapon_item: WeaponItem):
	_update_display()

func _on_weapon_unequipped(slot: int):
	_update_display()

func _on_weapon_switched(slot: int, weapon: Gun):
	_update_active_state()
