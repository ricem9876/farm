# ============================================
# INVENTORY UI (InventoryUI.gd)
# ============================================
# PURPOSE: Main inventory display showing player's collected items
# 
# FEATURES:
# - Shows 8 inventory slots in a horizontal row
# - Each slot displays item icon and quantity
# - Hover over item to see details (name, description, quantity)
# - Click close button or toggle to hide
# - Follows camera position
#
# KEY FUNCTIONS:
# - setup_inventory(): Connect to inventory manager and camera
# - _create_slots(): Create the 8 visible inventory slots
# - _update_display(): Refresh all slots when inventory changes
# - toggle_visibility(): Show/hide the inventory UI
# ============================================

extends Control
class_name InventoryUI

@onready var background_panel = $Background
@onready var item_grid = $Background/VBoxContainer/ItemGrid
@onready var title_bar = $Background/VBoxContainer/TitleBar if has_node("Background/VBoxContainer/TitleBar") else null
@onready var title_label = $Background/VBoxContainer/TitleBar/TitleLabel if has_node("Background/VBoxContainer/TitleBar/TitleLabel") else null
@onready var close_button = $Background/CloseButton if has_node("Background/CloseButton") else null
@onready var item_info_panel = $Background/VBoxContainer/ItemInfoPanel if has_node("Background/VBoxContainer/ItemInfoPanel") else null
@onready var item_name_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel") else null
@onready var item_description_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel") else null
@onready var item_quantity_label = $Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemQuantityLabel if has_node("Background/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemQuantityLabel") else null

var inventory_manager: InventoryManager
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")
var offset_from_camera: Vector2 = Vector2(0, -50)  # Position slightly above camera center
var follow_camera: Camera2D
var slots: Array[InventorySlot] = []  # Array holding all 8 inventory slot references

func _ready():
	visible = false  # Start hidden
	_setup_styling()
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Hide item info panel initially
	if item_info_panel:
		item_info_panel.visible = false

func _setup_styling():
	"""Set up the visual appearance of the inventory UI with pixel-art styling"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Style the main background panel with cream color and brown border
	if background_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.98, 0.94, 0.86)
		style_box.border_width_left = 1
		style_box.border_width_right = 1
		style_box.border_width_top = 1
		style_box.border_width_bottom = 1
		style_box.border_color = Color(0.45, 0.32, 0.18)
		style_box.corner_radius_top_left = 12
		style_box.corner_radius_top_right = 12
		style_box.corner_radius_bottom_left = 12
		style_box.corner_radius_bottom_right = 12
		style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
		style_box.shadow_size = 4
		style_box.shadow_offset = Vector2(2, 2)
		style_box.content_margin_left = 8
		style_box.content_margin_right = 8
		style_box.content_margin_top = 8
		style_box.content_margin_bottom = 8
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Style the title bar with dark brown background
	if title_bar:
		var title_style = StyleBoxFlat.new()
		title_style.bg_color = Color(0.45, 0.32, 0.18)
		title_style.border_width_left = 1
		title_style.border_width_right = 1
		title_style.border_width_top = 1
		title_style.border_width_bottom = 1
		title_style.border_color = Color(0.35, 0.25, 0.15)
		title_style.corner_radius_top_left = 6
		title_style.corner_radius_top_right = 6
		title_style.corner_radius_bottom_left = 6
		title_style.corner_radius_bottom_right = 6
		title_bar.add_theme_stylebox_override("panel", title_style)
	
	# Style the title text
	if title_label:
		title_label.text = "INVENTORY"
		title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", pixel_font)
	
	# Style the item info panel (shows when hovering over items)
	if item_info_panel:
		var info_style = StyleBoxFlat.new()
		info_style.bg_color = Color(0.45, 0.32, 0.18)
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
		
		# Style the info panel labels
		if item_name_label:
			item_name_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.42))
			item_name_label.add_theme_font_override("font", pixel_font)
		if item_description_label:
			item_description_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
			item_description_label.add_theme_font_override("font", pixel_font)
		if item_quantity_label:
			item_quantity_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
			item_quantity_label.add_theme_font_override("font", pixel_font)
	
	# Style the close button with red circular appearance
	if close_button:
		var close_normal = StyleBoxFlat.new()
		close_normal.bg_color = Color(0.8, 0.2, 0.2)
		close_normal.border_width_left = 2
		close_normal.border_width_right = 2
		close_normal.border_width_top = 2
		close_normal.border_width_bottom = 2
		close_normal.border_color = Color(0.6, 0.1, 0.1)
		close_normal.corner_radius_top_left = 50
		close_normal.corner_radius_top_right = 50
		close_normal.corner_radius_bottom_left = 50
		close_normal.corner_radius_bottom_right = 50
		close_button.add_theme_stylebox_override("normal", close_normal)
		
		var close_hover = StyleBoxFlat.new()
		close_hover.bg_color = Color(0.9, 0.3, 0.3)
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
		
		close_button.text = "×"
		close_button.add_theme_color_override("font_color", Color.WHITE)
		close_button.add_theme_font_override("font", pixel_font)

func setup_inventory(inv_manager: InventoryManager, camera: Camera2D = null, player_node: Node = null):
	"""
	SETUP FUNCTION - Call this to initialize the inventory UI
	Parameters:
	- inv_manager: The InventoryManager to display items from
	- camera: Camera2D to follow (optional)
	- player_node: Player node to connect toggle signal (optional)
	"""
	print("\n=== INVENTORY UI SETUP DEBUG ===")
	print("inv_manager: ", inv_manager)
	print("inv_manager type: ", inv_manager.get_class() if inv_manager else "NULL")
	print("inv_manager script: ", inv_manager.get_script() if inv_manager else "NULL")
	
	inventory_manager = inv_manager
	follow_camera = camera
	
	# Connect to inventory_changed signal so UI updates when items change
	if inventory_manager:
		print("Checking for signals on inventory_manager...")
		var signal_list = inventory_manager.get_signal_list()
		print("Available signals:")
		for sig in signal_list:
			print("  - ", sig.name)
		
		if inventory_manager.has_signal("inventory_changed"):
			print("✓ Signal 'inventory_changed' found! Connecting...")
			inventory_manager.inventory_changed.connect(_on_inventory_changed)
			print("✓ Signal connected successfully!")
		else:
			print("✗ ERROR: Signal 'inventory_changed' NOT found!")
			print("  Make sure InventoryManager.gd has 'signal inventory_changed' at the top")
	else:
		print("✗ ERROR: inventory_manager is NULL!")
	
	# Connect to player's inventory toggle signal if available
	if player_node and player_node.has_signal("inventory_toggle_requested"):
		player_node.inventory_toggle_requested.connect(toggle_visibility)
		print("✓ Connected to player's inventory_toggle_requested signal")
	
	print("=== END DEBUG ===\n")
	
	if not is_node_ready():
		await ready
		
	_create_slots()
	_update_display()
	
func _process(delta):
	"""Update position to follow camera every frame"""
	if visible and follow_camera:
		var viewport = get_viewport()
		var screen_size = viewport.get_visible_rect().size
		var camera_pos = follow_camera.global_position
		var screen_center_world = camera_pos + offset_from_camera
		global_position = screen_center_world - size * 0.5
		
func _create_slots():
	"""Create the 8 inventory slot UI elements"""
	if not item_grid:
		print("ERROR: item_grid is null!")
		return
		
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()
	slots.clear()
	
	# Set up grid as single row with 8 slots
	item_grid.columns = 8
	item_grid.add_theme_constant_override("h_separation", 4)  # Spacing between slots
	item_grid.add_theme_constant_override("v_separation", 0)
	
	if not inventory_manager:
		print("ERROR: inventory_manager is null!")
		return
	
	var slot_count = inventory_manager.max_slots
	print("Creating ", slot_count, " inventory slots...")
	
	# Create each slot
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_item_clicked)
		
		# Set slot size (48x48 pixels)
		slot.custom_minimum_size = Vector2(48, 48)
		slot.size = Vector2(48, 48)
		
		# Connect hover signals for item info display
		slot.mouse_entered.connect(_on_slot_hovered.bind(i))
		slot.mouse_exited.connect(_on_slot_unhovered)
			
		item_grid.add_child(slot)
		slots.append(slot)
		
	print("✓ Created ", slots.size(), " inventory slots successfully!")
		
func _update_display():
	"""Update all slots to match current inventory state"""
	for i in range(slots.size()):
		if i < inventory_manager.items.size():
			slots[i].set_item(inventory_manager.items[i], inventory_manager.quantities[i])
		else:
			slots[i].set_item(null, 0)
			
func _on_inventory_changed():
	"""Called when inventory manager signals a change - refresh display"""
	_update_display()
	
func _on_item_clicked(slot_index: int):
	"""Called when user clicks an inventory slot"""
	if slot_index < inventory_manager.items.size():
		var item = inventory_manager.items[slot_index]
		if item:
			print("Clicked item: ", item.name)
			_show_item_info(item, inventory_manager.quantities[slot_index])

func _on_slot_hovered(slot_index: int):
	"""Called when mouse hovers over a slot - show item details"""
	if slot_index < inventory_manager.items.size():
		var item = inventory_manager.items[slot_index]
		if item:
			_show_item_info(item, inventory_manager.quantities[slot_index])

func _on_slot_unhovered():
	"""Called when mouse leaves a slot - hide item details"""
	_hide_item_info()

func _show_item_info(item: Item, quantity: int):
	"""Display item information panel with name, description, and quantity"""
	if item_info_panel:
		item_info_panel.visible = true
		
		if item_name_label:
			item_name_label.text = item.name
		if item_description_label:
			item_description_label.text = item.description
		if item_quantity_label:
			item_quantity_label.text = "Quantity: " + str(quantity)

func _hide_item_info():
	"""Hide the item information panel"""
	if item_info_panel:
		item_info_panel.visible = false

func _on_close_button_pressed():
	"""Called when X button is clicked"""
	toggle_visibility()
		
func toggle_visibility():
	"""Show/hide the inventory UI"""
	visible = !visible
	if not visible:
		_hide_item_info()
