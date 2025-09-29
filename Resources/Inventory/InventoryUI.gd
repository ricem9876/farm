extends Control
class_name InventoryUI

@onready var background_panel = $Background
@onready var item_grid = $Background/VBoxContainer/ItemGrid
# Optional nodes - will be null if they don't exist in your scene
@onready var title_bar = $Background/VBoxContainer/TitleBar if has_node("Background/VBoxContainer/TitleBar") else null
@onready var title_label = $Background/VBoxContainer/TitleBar/TitleLabel if has_node("Background/VBoxContainer/TitleBar/TitleLabel") else null
@onready var close_button = $Background/CloseButton if has_node("Background/CloseButton") else null
@onready var item_info_panel = $Background/VBoxContainer/ItemInfoPanel if has_node("Background/VBoxContainer/ItemInfoPanel") else null
@onready var item_name_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel") else null
@onready var item_description_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel") else null
@onready var item_quantity_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemQuantityLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemQuantityLabel") else null

var inventory_manager: InventoryManager
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")
var offset_from_camera: Vector2 = Vector2(0, -50)  # Center on screen
var follow_camera: Camera2D
var slots: Array[InventorySlot] = []

func _ready():
	visible = false
	_setup_styling()
	
	# Debug: Check if all required nodes exist
	print("=== InventoryUI Node Check ===")
	print("background_panel: ", background_panel)
	print("title_bar: ", title_bar) 
	print("title_label: ", title_label)
	print("item_grid: ", item_grid)
	print("close_button: ", close_button)
	print("item_info_panel: ", item_info_panel)
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Hide item info panel initially
	if item_info_panel:
		item_info_panel.visible = false

func _setup_styling():
	# Load pixel font once at the beginning
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Set up the main background with pixel art style
	if background_panel:
		# Create a StyleBoxFlat for pixel art look - warm cream/beige
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.98, 0.94, 0.86)  # Very light warm cream (#FAF0DB)
		style_box.border_width_left = 1
		style_box.border_width_right = 1
		style_box.border_width_top = 1
		style_box.border_width_bottom = 1
		style_box.border_color = Color(0.45, 0.32, 0.18)  # Dark brown border (#73522E)
		style_box.corner_radius_top_left = 12
		style_box.corner_radius_top_right = 12
		style_box.corner_radius_bottom_left = 12
		style_box.corner_radius_bottom_right = 12
		
		# Add subtle inner shadow for depth
		style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
		style_box.shadow_size = 4
		style_box.shadow_offset = Vector2(2, 2)
		
		# Add padding to ensure content fits properly
		style_box.content_margin_left = 8
		style_box.content_margin_right = 8
		style_box.content_margin_top = 8
		style_box.content_margin_bottom = 8
		
		background_panel.add_theme_stylebox_override("panel", style_box)
		print("Applied styling to main panel")
	else:
		print("ERROR: background_panel (Panel) is null")
	
	# Style the title bar - dark wood color
	if title_bar:
		var title_style = StyleBoxFlat.new()
		title_style.bg_color = Color(0.45, 0.32, 0.18)  # Dark wood brown (#73522E)
		title_style.border_width_left = 1
		title_style.border_width_right = 1
		title_style.border_width_top = 1
		title_style.border_width_bottom = 1
		title_style.border_color = Color(0.35, 0.25, 0.15)  # Even darker brown
		title_style.corner_radius_top_left = 6
		title_style.corner_radius_top_right = 6
		title_style.corner_radius_bottom_left = 6
		title_style.corner_radius_bottom_right = 6
		title_bar.add_theme_stylebox_override("panel", title_style)
		print("Applied styling to title bar")
	else:
		print("ERROR: title_bar is null")
	
	# Style the title label
	if title_label:
		title_label.text = "INVENTORY"
		title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))  # Light cream text
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Add pixel font
		title_label.add_theme_font_override("font", pixel_font)
		print("Applied styling to title label")
	else:
		print("ERROR: title_label is null")
	
	# Style item info panel - same dark wood as title
	if item_info_panel:
		var info_style = StyleBoxFlat.new()
		info_style.bg_color = Color(0.45, 0.32, 0.18)  # Dark wood brown
		info_style.border_width_left = 1
		info_style.border_width_right = 1
		info_style.border_width_top = 1
		info_style.border_width_bottom = 1
		info_style.border_color = Color(0.35, 0.25, 0.15)
		info_style.corner_radius_top_left = 6
		info_style.corner_radius_top_right = 6
		info_style.corner_radius_bottom_left = 6
		info_style.corner_radius_bottom_right = 6
		item_info_panel.add_theme_stylebox_override("panel", info_style)
		print("Applied styling to item info panel")
		
		# Style info labels
		if item_name_label:
			item_name_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.42))  # Golden yellow (#FFDE6B)
			item_name_label.add_theme_font_override("font", pixel_font)
		if item_description_label:
			item_description_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))  # Light gray
			item_description_label.add_theme_font_override("font", pixel_font)
		if item_quantity_label:
			item_quantity_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))  # Light gray
			item_quantity_label.add_theme_font_override("font", pixel_font)
	else:
		print("ERROR: item_info_panel is null")
	
	# Style close button
	if close_button:
		# Normal state
		var close_normal = StyleBoxFlat.new()
		close_normal.bg_color = Color(0.8, 0.2, 0.2)  # Red
		close_normal.border_width_left = 2
		close_normal.border_width_right = 2
		close_normal.border_width_top = 2
		close_normal.border_width_bottom = 2
		close_normal.border_color = Color(0.6, 0.1, 0.1)  # Dark red
		close_normal.corner_radius_top_left = 50
		close_normal.corner_radius_top_right = 50
		close_normal.corner_radius_bottom_left = 50
		close_normal.corner_radius_bottom_right = 50
		close_button.add_theme_stylebox_override("normal", close_normal)
		
		# Hover state
		var close_hover = StyleBoxFlat.new()
		close_hover.bg_color = Color(0.9, 0.3, 0.3)  # Lighter red
		close_hover.border_width_left = 2
		close_hover.border_width_right = 2
		close_hover.border_width_top = 2
		close_hover.border_width_bottom = 2
		close_hover.border_color = Color(0.7, 0.2, 0.2)
		close_hover.corner_radius_top_left = 50
		close_hover.corner_radius_top_right = 50
		close_hover.corner_radius_bottom_left = 50
		close_hover.corner_radius_bottom_right = 50
		close_button.add_theme_stylebox_override("hover", close_hover)
		
		# Button text
		close_button.text = "×"
		close_button.add_theme_color_override("font_color", Color.WHITE)
		close_button.add_theme_font_override("font", pixel_font)
		print("Applied styling to close button")
	else:
		print("ERROR: close_button is null")

func setup_inventory(inv_manager: InventoryManager, camera: Camera2D = null, player_node: Node = null):
	inventory_manager = inv_manager
	follow_camera = camera
	inventory_manager.inventory_changed.connect(_on_inventory_changed)
	
	# Connect to player's inventory toggle signal
	if player_node and player_node.has_signal("inventory_toggle_requested"):
		player_node.inventory_toggle_requested.connect(toggle_visibility)
		print("Connected to player's inventory toggle signal")
	
	# Make sure we wait for the scene to be ready
	if not is_node_ready():
		await ready
		
	_create_slots()
	_update_display()
	
func _process(delta):
	if visible and follow_camera:
		# Get viewport size
		var viewport = get_viewport()
		var screen_size = viewport.get_visible_rect().size
		
		# Position inventory at screen center relative to camera
		# Since this is a Control node, we use the camera's global_position
		# and adjust for screen coordinates
		var camera_pos = follow_camera.global_position
		
		# Calculate center of screen in world coordinates
		var screen_center_world = camera_pos + offset_from_camera
		
		# Position inventory centered on screen
		global_position = screen_center_world - size * 0.5
		
func _create_slots():
	# Check if item_grid exists
	if not item_grid:
		print("ERROR: item_grid is null! Cannot create slots.")
		print("Check your scene structure or the node reference function.")
		return
		
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()
	slots.clear()
	
	# Set up grid as single row with 8 slots
	item_grid.columns = 8  # Single row with 8 slots
	item_grid.add_theme_constant_override("h_separation", 8)  # More spacing between slots
	item_grid.add_theme_constant_override("v_separation", 0)  # No vertical spacing
	
	if not inventory_manager:
		print("ERROR: inventory_manager is null!")
		return
	
	# Reduce inventory to 8 slots for single row
	var slot_count = 8
	print("Creating ", slot_count, " inventory slots in single row...")
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_item_clicked)
		
		# Very small slots - 16x16 pixels
		slot.custom_minimum_size = Vector2(16, 16)  # Tiny 16x16 slots
		slot.size = Vector2(16, 16)
		
		# Connect the built-in mouse hover signals for item info
		slot.mouse_entered.connect(_on_slot_hovered.bind(i))
		slot.mouse_exited.connect(_on_slot_unhovered)
			
		item_grid.add_child(slot)
		slots.append(slot)
		
	print("✓ Created ", slots.size(), " inventory slots successfully!")
	print("Final grid size: ", item_grid.size)
		
func _update_display():
	for i in range(slots.size()):
		if i < inventory_manager.items.size():
			slots[i].set_item(inventory_manager.items[i], inventory_manager.quantities[i])
		else:
			slots[i].set_item(null, 0)
			
func _on_inventory_changed():
	_update_display()
	
func _on_item_clicked(slot_index: int):
	if slot_index < inventory_manager.items.size():
		var item = inventory_manager.items[slot_index]
		if item:
			print("Clicked item: ", item.name)
			_show_item_info(item, inventory_manager.quantities[slot_index])

func _on_slot_hovered(slot_index: int):
	if slot_index < inventory_manager.items.size():
		var item = inventory_manager.items[slot_index]
		if item:
			_show_item_info(item, inventory_manager.quantities[slot_index])

func _on_slot_unhovered():
	_hide_item_info()

func _show_item_info(item: Item, quantity: int):
	if item_info_panel:
		item_info_panel.visible = true
		
		if item_name_label:
			item_name_label.text = item.name
		if item_description_label:
			item_description_label.text = item.description
		if item_quantity_label:
			item_quantity_label.text = "Quantity: " + str(quantity)

func _hide_item_info():
	if item_info_panel:
		item_info_panel.visible = false

func _on_close_button_pressed():
	toggle_visibility()
		
func toggle_visibility():
	visible = !visible
	if not visible:
		_hide_item_info()
