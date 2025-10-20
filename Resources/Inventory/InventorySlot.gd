# ============================================
# INVENTORY SLOT (InventorySlot.gd)
# ============================================
# PURPOSE: Individual slot UI element for displaying a single item
#
# FEATURES:
# - Shows item icon
# - Displays quantity badge if item count > 1
# - Highlights when hovered
# - Emits signal when clicked
# - Changes appearance based on whether slot has item
#
# KEY FUNCTIONS:
# - set_item(): Update the slot to display a specific item
# - _update_slot_appearance(): Change visual style based on hover/filled state
# ============================================

extends Control
class_name InventorySlot

signal item_clicked(slot_index: int)  # Emitted when this slot is clicked

@onready var button = $TextureButton  # The clickable button showing item icon
@onready var quantity_label = $TextureButton/QuantityLabel  # Red badge showing quantity
@onready var slot_background = $SlotBackground  # Visual frame/border of slot

var slot_index: int  # Which slot number this is (0-7)
var current_item: Item  # The item currently displayed in this slot
var is_hovered: bool = false  # Whether mouse is currently over this slot

func _ready():
	# Connect button press signal
	button.pressed.connect(_on_button_pressed)
	
	# Connect mouse hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Setup initial appearance
	_setup_slot_styling()
	_setup_button_size()
	_setup_quantity_label()

func _setup_button_size():
	"""Make the button fill the entire slot control"""
	if button:
		button.anchor_right = 1.0
		button.anchor_bottom = 1.0
		button.offset_left = 0
		button.offset_top = 0
		button.offset_right = 0
		button.offset_bottom = 0
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.ignore_texture_size = true

func _setup_quantity_label():
	"""Position quantity badge in bottom-right corner"""
	if quantity_label:
		quantity_label.anchor_left = 1.0
		quantity_label.anchor_right = 1.0
		quantity_label.anchor_top = 1.0
		quantity_label.anchor_bottom = 1.0
		quantity_label.offset_left = -28  # Width of badge
		quantity_label.offset_right = -4
		quantity_label.offset_top = -24   # Height of badge
		quantity_label.offset_bottom = -4
		quantity_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		quantity_label.size_flags_vertical = Control.SIZE_SHRINK_END

func _setup_slot_styling():
	"""Setup the visual appearance of the slot background"""
	# Make slot background fill the entire control
	if slot_background:
		slot_background.anchor_right = 1.0
		slot_background.anchor_bottom = 1.0
		slot_background.offset_left = 0
		slot_background.offset_top = 0
		slot_background.offset_right = 0
		slot_background.offset_bottom = 0
		
		# Create cream-colored background with brown border
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.96, 0.90, 0.78)  # Warm cream
		normal_style.border_width_left = 4
		normal_style.border_width_right = 4
		normal_style.border_width_top = 4
		normal_style.border_width_bottom = 4
		normal_style.border_color = Color(0.55, 0.42, 0.28)  # Brown border
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		slot_background.add_theme_stylebox_override("panel", normal_style)
	
	# Style the quantity label - red badge style
	if quantity_label:
		quantity_label.add_theme_color_override("font_color", Color.WHITE)
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Create red badge background
		var qty_style = StyleBoxFlat.new()
		qty_style.bg_color = Color(0.8, 0.2, 0.2)  # Red
		qty_style.border_width_left = 2
		qty_style.border_width_right = 2
		qty_style.border_width_top = 2
		qty_style.border_width_bottom = 2
		qty_style.border_color = Color(0.6, 0.1, 0.1)  # Dark red border
		qty_style.corner_radius_top_left = 8
		qty_style.corner_radius_top_right = 8
		qty_style.corner_radius_bottom_left = 8
		qty_style.corner_radius_bottom_right = 8
		
		qty_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
		qty_style.shadow_size = 2
		qty_style.shadow_offset = Vector2(1, 1)
		
		quantity_label.add_theme_stylebox_override("normal", qty_style)
		quantity_label.add_theme_font_size_override("font_size", 14)
		quantity_label.z_index = 10  # Ensure it appears above icon

func set_item(item: Item, quantity: int):
	"""
	Update this slot to display a specific item
	Parameters:
	- item: The Item to display (or null for empty slot)
	- quantity: How many of this item
	"""
	current_item = item
	
	if item:
		# Show the item's icon
		button.texture_normal = item.icon
		
		# Show quantity badge if more than 1
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
		
		_update_slot_appearance(true)
	else:
		# Empty slot
		button.texture_normal = null
		quantity_label.visible = false
		_update_slot_appearance(false)

func _update_slot_appearance(has_item: bool):
	"""
	Update the visual appearance of the slot based on its state
	Parameters:
	- has_item: Whether this slot contains an item
	"""
	if not slot_background:
		return
		
	var style = StyleBoxFlat.new()
	
	if is_hovered:
		# Hovered state - brighter and warmer glow
		style.bg_color = Color(0.98, 0.94, 0.82)
		style.border_color = Color(0.65, 0.52, 0.38)
		style.shadow_color = Color(1.0, 0.84, 0.0, 0.3)
		style.shadow_size = 4
	elif has_item:
		# Has item state - slightly highlighted
		style.bg_color = Color(0.98, 0.92, 0.80)
		style.border_color = Color(0.55, 0.42, 0.28)
	else:
		# Empty state - duller appearance
		style.bg_color = Color(0.94, 0.88, 0.76)
		style.border_color = Color(0.50, 0.37, 0.23)
	
	# Apply consistent border and corners
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Add subtle shadow for depth (except when hovered)
	if has_item or is_hovered:
		if not is_hovered:
			style.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
			style.shadow_size = 3
			style.shadow_offset = Vector2(1, 1)
	
	slot_background.add_theme_stylebox_override("panel", style)

func _on_button_pressed():
	"""Emit signal when slot is clicked"""
	item_clicked.emit(slot_index)

func _on_mouse_entered():
	"""Called when mouse enters this slot - update appearance"""
	is_hovered = true
	_update_slot_appearance(current_item != null)

func _on_mouse_exited():
	"""Called when mouse leaves this slot - update appearance"""
	is_hovered = false
	_update_slot_appearance(current_item != null)
