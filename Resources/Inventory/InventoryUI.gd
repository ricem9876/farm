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
var offset_from_camera: Vector2 = Vector2(0, -50)
var follow_camera: Camera2D
var slots: Array[InventorySlot] = []

func _ready():
	visible = false
	_setup_styling()
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	if item_info_panel:
		item_info_panel.visible = false

func _setup_styling():
	var pixel_font = preload("res://Resources/Fonts/yoster.ttf")
	
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
	
	if title_label:
		title_label.text = "INVENTORY"
		title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", pixel_font)
	
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
		
		if item_name_label:
			item_name_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.42))
			item_name_label.add_theme_font_override("font", pixel_font)
		if item_description_label:
			item_description_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
			item_description_label.add_theme_font_override("font", pixel_font)
		if item_quantity_label:
			item_quantity_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
			item_quantity_label.add_theme_font_override("font", pixel_font)
	
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
	inventory_manager = inv_manager
	follow_camera = camera
	inventory_manager.inventory_changed.connect(_on_inventory_changed)
	
	if player_node and player_node.has_signal("inventory_toggle_requested"):
		player_node.inventory_toggle_requested.connect(toggle_visibility)
	
	if not is_node_ready():
		await ready
		
	_create_slots()
	_update_display()
	
func _process(delta):
	if visible and follow_camera:
		var viewport = get_viewport()
		var screen_size = viewport.get_visible_rect().size
		var camera_pos = follow_camera.global_position
		var screen_center_world = camera_pos + offset_from_camera
		global_position = screen_center_world - size * 0.5
		
func _create_slots():
	if not item_grid:
		print("ERROR: item_grid is null!")
		return
		
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()
	slots.clear()
	
	# Set up grid as single row with 8 slots - BETTER SIZE
	item_grid.columns = 8
	item_grid.add_theme_constant_override("h_separation", 4)  # Reduced spacing
	item_grid.add_theme_constant_override("v_separation", 0)
	
	if not inventory_manager:
		print("ERROR: inventory_manager is null!")
		return
	
	var slot_count = 8
	print("Creating ", slot_count, " inventory slots...")
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.item_clicked.connect(_on_item_clicked)
		
		# MUCH BETTER SIZE - 48x48 pixels instead of 16x16
		slot.custom_minimum_size = Vector2(48, 48)
		slot.size = Vector2(48, 48)
		
		slot.mouse_entered.connect(_on_slot_hovered.bind(i))
		slot.mouse_exited.connect(_on_slot_unhovered)
			
		item_grid.add_child(slot)
		slots.append(slot)
		
	print("✓ Created ", slots.size(), " inventory slots successfully!")
		
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
