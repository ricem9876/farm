# ============================================
# STORAGE UI (StorageUI.gd)
# ============================================
# PURPOSE: Transfer interface between player inventory and storage chest
#
# FEATURES:
# - Shows player's 8-slot inventory on the left
# - Shows storage chest's larger inventory on the right  
# - Click item to select it (highlights golden)
# - Click destination to transfer the item
# - Displays resources and instructions
# - Follows camera position
#
# KEY FUNCTIONS:
# - setup_storage(): Initialize with player and storage inventories
# - _on_player_slot_clicked(): Handle clicking player inventory
# - _on_storage_slot_clicked(): Handle clicking storage inventory
# - _transfer_item_from_player_to_storage(): Move item from player to chest
# - _transfer_item_from_storage_to_player(): Move item from chest to player
# ============================================

extends Control
class_name StorageUI

@onready var background_panel = $Background
@onready var player_inventory_panel = $Background/HBoxContainer/PlayerInventoryPanel
@onready var storage_inventory_panel = $Background/HBoxContainer/StorageInventoryPanel
@onready var player_title = $Background/HBoxContainer/PlayerInventoryPanel/VBoxContainer/PlayerTitle
@onready var storage_title = $Background/HBoxContainer/StorageInventoryPanel/VBoxContainer/StorageTitle
@onready var player_grid = $Background/HBoxContainer/PlayerInventoryPanel/VBoxContainer/PlayerGrid
@onready var storage_grid = $Background/HBoxContainer/StorageInventoryPanel/VBoxContainer/StorageGrid
@onready var close_button = $Background/CloseButton
@onready var transfer_info = $Background/TransferInfo

var player_inventory: InventoryManager  # Player's inventory (8 slots)
var storage_inventory: InventoryManager  # Storage chest inventory (larger)
var slot_scene = preload("res://Resources/Inventory/InventorySlot.tscn")

var player_slots: Array[InventorySlot] = []  # UI slots for player inventory
var storage_slots: Array[InventorySlot] = []  # UI slots for storage inventory

var selected_slot: InventorySlot = null  # Currently selected slot (if any)
var selected_from_player: bool = false  # Was selection from player inventory?

# Camera following variables
var follow_camera: Camera2D
var camera_zoom_factor: float = 1.0

signal storage_closed  # Emitted when storage UI is closed

func _ready():
	visible = false  # Start hidden
	_setup_styling()
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Hide transfer info initially
	if transfer_info:
		transfer_info.visible = false

func _setup_styling():
	"""Set up the visual appearance of the storage UI"""
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
	# Main background panel with cream color
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
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Style both inventory panels with dark brown background
	for panel in [player_inventory_panel, storage_inventory_panel]:
		if panel:
			var panel_style = StyleBoxFlat.new()
			panel_style.bg_color = Color(0.45, 0.32, 0.18)
			panel_style.border_width_left = 1
			panel_style.border_width_right = 1
			panel_style.border_width_top = 1
			panel_style.border_width_bottom = 1
			panel_style.border_color = Color(0.35, 0.25, 0.15)
			panel_style.corner_radius_top_left = 6
			panel_style.corner_radius_top_right = 6
			panel_style.corner_radius_bottom_left = 6
			panel_style.corner_radius_bottom_right = 6
			panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style titles
	if player_title:
		player_title.text = "YOUR INVENTORY"
		player_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		player_title.add_theme_font_override("font", pixel_font)
		player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if storage_title:
		storage_title.text = "STORAGE CHEST"
		storage_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		storage_title.add_theme_font_override("font", pixel_font)
		storage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style transfer instructions
	if transfer_info:
		transfer_info.text = "Click an item to select, then click destination to transfer"
		transfer_info.add_theme_color_override("font_color", Color(1.0, 0.87, 0.42))
		transfer_info.add_theme_font_override("font", pixel_font)
		transfer_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func setup_storage(player_inv: InventoryManager, storage_inv: InventoryManager, camera: Camera2D = null):
	"""
	Initialize the storage UI with player and storage inventories
	Parameters:
	- player_inv: The player's inventory manager
	- storage_inv: The storage chest's inventory manager
	- camera: Optional camera to follow
	"""
	player_inventory = player_inv
	storage_inventory = storage_inv
	follow_camera = camera
	
	# Calculate camera zoom factor for positioning
	if follow_camera:
		camera_zoom_factor = follow_camera.zoom.x
	
	# Connect to inventory changed signals
	player_inventory.inventory_changed.connect(_update_player_display)
	storage_inventory.inventory_changed.connect(_update_storage_display)
	
	_create_slots()
	_update_displays()

func _process(delta):
	"""Update position to follow camera every frame"""
	if visible and follow_camera:
		# Get the camera's position in world coordinates
		var camera_pos = follow_camera.global_position
		
		# Get viewport size
		var viewport = get_viewport()
		var screen_size = viewport.get_visible_rect().size
		
		# Account for zoom - with 3.0 zoom, the effective screen size is smaller
		var effective_screen_size = screen_size / camera_zoom_factor
		
		# Position UI at screen center
		global_position = camera_pos - (size * 0.5)

func _create_slots():
	"""Create all slot UI elements for both inventories"""
	# Clear existing slots
	for child in player_grid.get_children():
		child.queue_free()
	for child in storage_grid.get_children():
		child.queue_free()
	player_slots.clear()
	storage_slots.clear()
	
	# Set up grids
	player_grid.columns = 4  # Player inventory: 4 columns
	storage_grid.columns = 8  # Storage: 8 columns (more space)
	
	# Add spacing between slots for better visibility
	player_grid.add_theme_constant_override("h_separation", 4)  # Horizontal spacing
	player_grid.add_theme_constant_override("v_separation", 4)  # Vertical spacing
	storage_grid.add_theme_constant_override("h_separation", 4)
	storage_grid.add_theme_constant_override("v_separation", 4)
	
	# Create player inventory slots (8 slots total)
	for i in range(player_inventory.max_slots):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(48, 48)  # Increased from 32x32 to match inventory UI
		slot.size = Vector2(48, 48)
		slot.item_clicked.connect(_on_player_slot_clicked)
		player_grid.add_child(slot)
		player_slots.append(slot)
	
	# Create storage inventory slots (larger capacity)
	for i in range(storage_inventory.max_slots):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.custom_minimum_size = Vector2(48, 48)  # Increased from 32x32 for better visibility
		slot.size = Vector2(48, 48)
		slot.item_clicked.connect(_on_storage_slot_clicked)
		storage_grid.add_child(slot)
		storage_slots.append(slot)

func _update_displays():
	"""Update both inventory displays"""
	_update_player_display()
	_update_storage_display()

func _update_player_display():
	"""Update player inventory slots to match current state"""
	for i in range(player_slots.size()):
		if i < player_inventory.items.size():
			player_slots[i].set_item(player_inventory.items[i], player_inventory.quantities[i])
		else:
			player_slots[i].set_item(null, 0)
	_clear_selection()

func _update_storage_display():
	"""Update storage inventory slots to match current state"""
	for i in range(storage_slots.size()):
		if i < storage_inventory.items.size():
			storage_slots[i].set_item(storage_inventory.items[i], storage_inventory.quantities[i])
		else:
			storage_slots[i].set_item(null, 0)
	_clear_selection()

func _on_player_slot_clicked(slot_index: int):
	"""
	Handle clicking on player inventory slot
	- If no selection: Select this slot (if it has an item)
	- If selection from storage: Transfer from storage to this slot
	"""
	if selected_slot != null:
		# Transfer from storage to player
		if not selected_from_player:
			_transfer_item_from_storage_to_player(selected_slot.slot_index, slot_index)
		_clear_selection()
	else:
		# Select player slot if it has an item
		if slot_index < player_inventory.items.size() and player_inventory.items[slot_index] != null:
			_select_slot(player_slots[slot_index], true)

func _on_storage_slot_clicked(slot_index: int):
	"""
	Handle clicking on storage inventory slot
	- If no selection: Select this slot (if it has an item)
	- If selection from player: Transfer from player to this slot
	"""
	if selected_slot != null:
		# Transfer from player to storage
		if selected_from_player:
			_transfer_item_from_player_to_storage(selected_slot.slot_index, slot_index)
		_clear_selection()
	else:
		# Select storage slot if it has an item
		if slot_index < storage_inventory.items.size() and storage_inventory.items[slot_index] != null:
			_select_slot(storage_slots[slot_index], false)

func _select_slot(slot: InventorySlot, from_player: bool):
	"""
	Visually select a slot (highlight it golden)
	Parameters:
	- slot: The slot to select
	- from_player: Whether this is from player inventory
	"""
	_clear_selection()
	selected_slot = slot
	selected_from_player = from_player
	
	# Highlight selected slot with golden color
	if slot.slot_background:
		var highlight_style = StyleBoxFlat.new()
		highlight_style.bg_color = Color(1.0, 0.87, 0.42, 0.8)  # Golden highlight
		highlight_style.border_width_left = 3
		highlight_style.border_width_right = 3
		highlight_style.border_width_top = 3
		highlight_style.border_width_bottom = 3
		highlight_style.border_color = Color(1.0, 0.7, 0.0)  # Golden border
		highlight_style.corner_radius_top_left = 6
		highlight_style.corner_radius_top_right = 6
		highlight_style.corner_radius_bottom_left = 6
		highlight_style.corner_radius_bottom_right = 6
		slot.slot_background.add_theme_stylebox_override("panel", highlight_style)
	
	# Show transfer instructions
	if transfer_info:
		transfer_info.visible = true
		var source = "player inventory" if from_player else "storage"
		var destination = "storage" if from_player else "player inventory"
		transfer_info.text = "Selected item from " + source + ". Click " + destination + " to transfer."

func _clear_selection():
	"""Clear the current selection and hide transfer info"""
	if selected_slot:
		# Reset slot appearance
		selected_slot._update_slot_appearance(selected_slot.current_item != null)
	
	selected_slot = null
	selected_from_player = false
	
	if transfer_info:
		transfer_info.visible = false

func _transfer_item_from_player_to_storage(player_slot_index: int, storage_slot_index: int):
	"""
	Transfer an item from player inventory to storage
	Parameters:
	- player_slot_index: Which player slot to take from
	- storage_slot_index: Which storage slot to place in (unused, auto-finds space)
	"""
	if player_slot_index >= player_inventory.items.size():
		return
		
	var item = player_inventory.items[player_slot_index]
	if item == null:
		return
	
	var quantity = player_inventory.quantities[player_slot_index]
	
	# Try to add to storage
	if storage_inventory.add_item(item, quantity):
		# Successfully added to storage, remove from player
		player_inventory.remove_item(item, quantity)

func _transfer_item_from_storage_to_player(storage_slot_index: int, player_slot_index: int):
	"""
	Transfer an item from storage to player inventory
	Parameters:
	- storage_slot_index: Which storage slot to take from
	- player_slot_index: Which player slot to place in (unused, auto-finds space)
	"""
	if storage_slot_index >= storage_inventory.items.size():
		return
		
	var item = storage_inventory.items[storage_slot_index]
	if item == null:
		return
	
	var quantity = storage_inventory.quantities[storage_slot_index]

	# Try to add to player inventory
	if player_inventory.add_item(item, quantity):
		# Successfully added to player, remove from storage
		storage_inventory.remove_item(item, quantity)
	
	_update_player_display()
	_update_storage_display()

func _on_close_button_pressed():
	"""Called when close button is pressed"""
	storage_closed.emit()

func _input(event):
	"""Handle ESC key to close storage UI"""
	if visible and event.is_action_pressed("ui_cancel"):  # ESC key
		storage_closed.emit()
