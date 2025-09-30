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
		normal_style.bg_color = Color(0.96, 0.90, 0.78)
		normal_style.border_width_left = 4
		normal_style.border_width_right = 4
		normal_style.border_width_top = 4
		normal_style.border_width_bottom = 4
		normal_style.border_color = Color(0.55, 0.42, 0.28)
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
		qty_style.bg_color = Color(0.8, 0.2, 0.2)
		qty_style.border_width_left = 2
		qty_style.border_width_right = 2
		qty_style.border_width_top = 2
		qty_style.border_width_bottom = 2
		qty_style.border_color = Color(0.6, 0.1, 0.1)
		qty_style.corner_radius_top_left = 8
		qty_style.corner_radius_top_right = 8
		qty_style.corner_radius_bottom_left = 8
		qty_style.corner_radius_bottom_right = 8
		
		qty_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
		qty_style.shadow_size = 2
		qty_style.shadow_offset = Vector2(1, 1)
		
		quantity_label.add_theme_stylebox_override("normal", qty_style)
		quantity_label.add_theme_font_size_override("font_size", 24)

func set_item(item: Item, quantity: int):
	current_item = item
	
	if item:
		button.texture_normal = item.icon
		
		# The button is already configured in _setup_button_size() to scale properly
		
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
		
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
	
	# Apply consistent styling
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Add subtle inner gradient for depth
	if has_item or is_hovered:
		if not is_hovered:  # Only add shadow if not already hovered
			style.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
			style.shadow_size = 3
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
