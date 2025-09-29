extends Control
class_name InventorySlot

signal item_clicked(slot_index: int)

@onready var button = $TextureButton
@onready var quantity_label = $TextureButton/QuantityLabel
@onready var slot_background = $SlotBackground

var slot_index: int
var current_item: Item
var is_hovered: bool = false

func _ready():
	button.pressed.connect(_on_button_pressed)
	# Use the built-in mouse signals from Control
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_slot_styling()

func _setup_slot_styling():
	# Set up the slot background with pixel art style
	if slot_background:
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.96, 0.90, 0.78)  # Light cream (#F5E6C8)
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.55, 0.42, 0.28)  # Medium brown border (#8C6B47)
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_left = 6
		normal_style.corner_radius_bottom_right = 6
		slot_background.add_theme_stylebox_override("panel", normal_style)
	
	# Style the quantity label - red badge style
	if quantity_label:
		quantity_label.add_theme_color_override("font_color", Color.WHITE)
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Create red badge background
		var qty_style = StyleBoxFlat.new()
		qty_style.bg_color = Color(0.8, 0.2, 0.2)  # Red background (#CC3333)
		qty_style.border_width_left = 2
		qty_style.border_width_right = 2
		qty_style.border_width_top = 2
		qty_style.border_width_bottom = 2
		qty_style.border_color = Color(0.6, 0.1, 0.1)  # Darker red border (#991A1A)
		qty_style.corner_radius_top_left = 8
		qty_style.corner_radius_top_right = 8
		qty_style.corner_radius_bottom_left = 8
		qty_style.corner_radius_bottom_right = 8
		
		# Add small shadow for depth
		qty_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
		qty_style.shadow_size = 2
		qty_style.shadow_offset = Vector2(1, 1)
		
		quantity_label.add_theme_stylebox_override("normal", qty_style)
		
		# Skip custom font for now - just use default with smaller size
		quantity_label.add_theme_font_size_override("font_size", 12)

func set_item(item: Item, quantity: int):
	current_item = item
	
	if item:
		button.texture_normal = item.icon
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
		
		# Add slight highlight when item is present
		_update_slot_appearance(true)
	else:
		button.texture_normal = null
		quantity_label.visible = false
		_update_slot_appearance(false)

func _update_slot_appearance(has_item: bool):
	if not slot_background:
		return
		
	var style = StyleBoxFlat.new()
	
	if is_hovered:
		# Hovered state - brighter and warmer
		style.bg_color = Color(0.98, 0.94, 0.82)  # Brighter cream with golden tint
		style.border_color = Color(0.65, 0.52, 0.38)  # Lighter brown border
		# Add subtle glow effect
		style.shadow_color = Color(1.0, 0.84, 0.0, 0.3)  # Golden glow
		style.shadow_size = 3
	elif has_item:
		# Has item state - slightly highlighted
		style.bg_color = Color(0.98, 0.92, 0.80)  # Warm cream
		style.border_color = Color(0.55, 0.42, 0.28)  # Normal brown border
	else:
		# Empty state - duller appearance
		style.bg_color = Color(0.94, 0.88, 0.76)  # Duller cream
		style.border_color = Color(0.50, 0.37, 0.23)  # Darker brown border
		
		# Add slot number for empty slots
		# Note: You might want to add a label child to show slot numbers
	
	# Apply consistent styling
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	# Add subtle inner gradient for depth
	if has_item or is_hovered:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
		style.shadow_size = 2
		style.shadow_offset = Vector2(1, 1)
	
	slot_background.add_theme_stylebox_override("panel", style)

func _on_button_pressed():
	item_clicked.emit(slot_index)

func _on_mouse_entered():
	is_hovered = true
	_update_slot_appearance(current_item != null)

func _on_mouse_exited():
	is_hovered = false
	_update_slot_appearance(current_item != null)
