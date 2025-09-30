extends Control
class_name WeaponSlot

signal weapon_clicked(slot_index: int)

@onready var button = $TextureButton
@onready var slot_background = $SlotBackground

var slot_index: int
var current_weapon: WeaponItem
var is_hovered: bool = false

func _ready():
	button.pressed.connect(_on_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_slot_styling()
	_setup_button_size()

func _setup_button_size():
	# Make sure the button fills the entire control
	if button:
		button.anchor_right = 1.0
		button.anchor_bottom = 1.0
		button.offset_left = 0
		button.offset_top = 0
		button.offset_right = 0
		button.offset_bottom = 0
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.ignore_texture_size = true

func _setup_slot_styling():
	# Make slot background fill the entire control
	if slot_background:
		slot_background.anchor_right = 1.0
		slot_background.anchor_bottom = 1.0
		slot_background.offset_left = 0
		slot_background.offset_top = 0
		slot_background.offset_right = 0
		slot_background.offset_bottom = 0
		
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.2, 0.25)  # Dark gray-blue
		normal_style.border_width_left = 4
		normal_style.border_width_right = 4
		normal_style.border_width_top = 4
		normal_style.border_width_bottom = 4
		normal_style.border_color = Color(0.4, 0.4, 0.5)  # Steel blue border
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		slot_background.add_theme_stylebox_override("panel", normal_style)

func set_weapon(weapon: WeaponItem):
	current_weapon = weapon
	
	if weapon:
		button.texture_normal = weapon.icon
		_update_slot_appearance(true)
	else:
		button.texture_normal = null
		_update_slot_appearance(false)

func _update_slot_appearance(has_weapon: bool):
	if not slot_background:
		return
		
	var style = StyleBoxFlat.new()
	
	if is_hovered:
		# Hovered state - bright highlight
		style.bg_color = Color(0.3, 0.5, 0.7)  # Blue highlight
		style.border_color = Color(0.5, 0.7, 1.0)  # Bright blue
		style.shadow_color = Color(0.3, 0.6, 1.0, 0.5)
		style.shadow_size = 6
	elif has_weapon:
		# Has weapon state - slightly highlighted
		style.bg_color = Color(0.25, 0.25, 0.3)
		style.border_color = Color(0.5, 0.5, 0.6)
	else:
		# Empty state - darker
		style.bg_color = Color(0.15, 0.15, 0.2)
		style.border_color = Color(0.3, 0.3, 0.4)
	
	# Apply consistent styling
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	slot_background.add_theme_stylebox_override("panel", style)

func _on_button_pressed():
	weapon_clicked.emit(slot_index)

func _on_mouse_entered():
	is_hovered = true
	_update_slot_appearance(current_weapon != null)

func _on_mouse_exited():
	is_hovered = false
	_update_slot_appearance(current_weapon != null)
