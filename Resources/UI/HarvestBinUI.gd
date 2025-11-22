# HarvestBinUI.gd
# UI for selling crops at the harvest bin - STYLED VERSION WITH MEMORY LEAK FIX
extends CanvasLayer

@onready var crop_list_container = %CropListContainer
@onready var total_value_label = %TotalValueLabel
@onready var sell_button = %SellButton
@onready var close_button = %CloseButton
@onready var panel = %Panel  # Main panel background
@onready var margin_container = %MarginContainer

var inventory_manager: InventoryManager = null
var player: Node2D = null
var crop_entries: Array[Dictionary] = []

# Crop prices (must match HarvestBin.gd)
const CROP_PRICES = {
	"Mushroom": 5,
	"Corn": 5,
	"Pumpkin": 5,
	"Tomato": 5
}

# Style colors
const BG_COLOR = Color(0.86, 0.72, 0.52)  # Tan/beige background
const HEADER_COLOR = Color(0.2, 0.7, 0.2)  # Green for "Harvest Bin" title
const TEXT_COLOR = Color(0.2, 0.2, 0.2)  # Dark text
const BUTTON_BG = Color(0.95, 0.88, 0.7)  # Light tan for buttons
const BUTTON_BORDER = Color(0.3, 0.2, 0.1)  # Dark brown border

# MEMORY LEAK FIX: Cache StyleBox objects instead of creating new ones every time
var _button_style_normal: StyleBoxFlat = null
var _button_style_hover: StyleBoxFlat = null
var _button_style_pressed: StyleBoxFlat = null
var _button_style_disabled: StyleBoxFlat = null
var _panel_style: StyleBoxFlat = null
var _display_style: StyleBoxFlat = null
var _separator_style: StyleBoxFlat = null
var _styles_created: bool = false

func _enter_tree():
	# Add to group as early as possible
	add_to_group("harvest_bin_ui")
	print("✓ HarvestBinUI added to group 'harvest_bin_ui'")

func _ready():
	# CRITICAL: Prevent running in editor to avoid memory leaks
	if Engine.is_editor_hint():
		return
	
	# Double-check we're in the group
	if not is_in_group("harvest_bin_ui"):
		add_to_group("harvest_bin_ui")
		print("⚠ Had to re-add HarvestBinUI to group in _ready()")
	
	# CRITICAL: Allow processing while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false
	
	print("=== HarvestBinUI _ready() called ===")
	print("  - In group: ", is_in_group("harvest_bin_ui"))
	print("  - Parent: ", get_parent().name if get_parent() else "NO PARENT")
	
	# Create all StyleBox objects ONCE
	_create_cached_styles()
	
	# Apply styles to panel AND ColorRect
	_setup_panel_style()
	_setup_colorrect()
	
	# Apply styles to buttons
	_setup_button_styles()
	
	# Connect buttons
	if sell_button:
		# Disconnect first if already connected (safety check)
		if sell_button.pressed.is_connected(_on_sell_pressed):
			sell_button.pressed.disconnect(_on_sell_pressed)
		sell_button.pressed.connect(_on_sell_pressed)
		print("  ✓ Sell button connected")
	else:
		print("  ✗ Sell button NOT FOUND")
	
	if close_button:
		# Disconnect first if already connected (safety check)
		if close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.disconnect(_on_close_pressed)
		close_button.pressed.connect(_on_close_pressed)
		print("  ✓ Close button connected")
	else:
		print("  ✗ Close button NOT FOUND")
	
	print("=== HarvestBinUI ready complete ===")

func _create_cached_styles():
	"""Create all StyleBox objects ONCE and cache them to prevent memory leaks"""
	if _styles_created:
		return  # Already created
	
	print("Creating cached StyleBox objects...")
	
	# Button styles
	_button_style_normal = StyleBoxFlat.new()
	_button_style_normal.bg_color = BUTTON_BG
	_button_style_normal.border_color = BUTTON_BORDER
	_button_style_normal.border_width_left = 2
	_button_style_normal.border_width_right = 2
	_button_style_normal.border_width_top = 2
	_button_style_normal.border_width_bottom = 2
	_button_style_normal.corner_radius_top_left = 4
	_button_style_normal.corner_radius_top_right = 4
	_button_style_normal.corner_radius_bottom_left = 4
	_button_style_normal.corner_radius_bottom_right = 4
	
	_button_style_hover = StyleBoxFlat.new()
	_button_style_hover.bg_color = Color(1.0, 0.95, 0.8)  # Lighter on hover
	_button_style_hover.border_color = BUTTON_BORDER
	_button_style_hover.border_width_left = 2
	_button_style_hover.border_width_right = 2
	_button_style_hover.border_width_top = 2
	_button_style_hover.border_width_bottom = 2
	_button_style_hover.corner_radius_top_left = 4
	_button_style_hover.corner_radius_top_right = 4
	_button_style_hover.corner_radius_bottom_left = 4
	_button_style_hover.corner_radius_bottom_right = 4
	
	_button_style_pressed = StyleBoxFlat.new()
	_button_style_pressed.bg_color = Color(0.85, 0.78, 0.6)  # Darker when pressed
	_button_style_pressed.border_color = BUTTON_BORDER
	_button_style_pressed.border_width_left = 2
	_button_style_pressed.border_width_right = 2
	_button_style_pressed.border_width_top = 2
	_button_style_pressed.border_width_bottom = 2
	_button_style_pressed.corner_radius_top_left = 4
	_button_style_pressed.corner_radius_top_right = 4
	_button_style_pressed.corner_radius_bottom_left = 4
	_button_style_pressed.corner_radius_bottom_right = 4
	
	_button_style_disabled = StyleBoxFlat.new()
	_button_style_disabled.bg_color = Color(0.7, 0.65, 0.55)
	_button_style_disabled.border_color = Color(0.5, 0.4, 0.3)
	_button_style_disabled.border_width_left = 2
	_button_style_disabled.border_width_right = 2
	_button_style_disabled.border_width_top = 2
	_button_style_disabled.border_width_bottom = 2
	_button_style_disabled.corner_radius_top_left = 4
	_button_style_disabled.corner_radius_top_right = 4
	_button_style_disabled.corner_radius_bottom_left = 4
	_button_style_disabled.corner_radius_bottom_right = 4
	
	# Panel style
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = BG_COLOR
	_panel_style.border_color = BUTTON_BORDER
	_panel_style.border_width_left = 3
	_panel_style.border_width_right = 3
	_panel_style.border_width_top = 3
	_panel_style.border_width_bottom = 3
	_panel_style.corner_radius_top_left = 8
	_panel_style.corner_radius_top_right = 8
	_panel_style.corner_radius_bottom_left = 8
	_panel_style.corner_radius_bottom_right = 8
	
	# Quantity display background style
	_display_style = StyleBoxFlat.new()
	_display_style.bg_color = Color(0.95, 0.95, 0.95)  # Almost white background
	_display_style.border_color = BUTTON_BORDER
	_display_style.border_width_left = 2
	_display_style.border_width_right = 2
	_display_style.border_width_top = 2
	_display_style.border_width_bottom = 2
	_display_style.corner_radius_top_left = 4
	_display_style.corner_radius_top_right = 4
	_display_style.corner_radius_bottom_left = 4
	_display_style.corner_radius_bottom_right = 4
	_display_style.content_margin_left = 4
	_display_style.content_margin_right = 4
	_display_style.content_margin_top = 4
	_display_style.content_margin_bottom = 4
	
	# Separator style
	_separator_style = StyleBoxFlat.new()
	_separator_style.bg_color = Color(0.6, 0.5, 0.3, 0.3)
	
	_styles_created = true
	print("✓ Cached StyleBox objects created")

func _setup_panel_style():
	"""Apply tan/beige background to the main panel"""
	if panel and _panel_style:
		panel.add_theme_stylebox_override("panel", _panel_style)
		panel.self_modulate = Color.WHITE
	
	# Also check if there's a ColorRect we need to update
	var color_rect = get_node_or_null("%ColorRect")
	if color_rect == null:
		color_rect = panel.get_node_or_null("../ColorRect")
	
	if color_rect:
		color_rect.color = BG_COLOR
		print("✓ ColorRect updated to tan color")

func _setup_colorrect():
	"""Find and update any ColorRect to tan background"""
	# Try to find ColorRect in various locations
	var paths_to_try = [
		"Control/ColorRect",
		"../ColorRect",
		"../../ColorRect"
	]
	
	for path in paths_to_try:
		var color_rect = get_node_or_null(path)
		if color_rect and color_rect is ColorRect:
			color_rect.color = BG_COLOR
			print("✓ Found and updated ColorRect at: ", path)
			return
	
	print("  No ColorRect found (this is okay if Panel handles the background)")

func _setup_button_styles():
	"""Apply consistent button styling using CACHED styles"""
	for button in [sell_button, close_button]:
		if button:
			button.add_theme_stylebox_override("normal", _button_style_normal)
			button.add_theme_stylebox_override("hover", _button_style_hover)
			button.add_theme_stylebox_override("pressed", _button_style_pressed)
			button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
			button.add_theme_font_size_override("font_size", 20)

func open(inv_manager: InventoryManager, player_ref: Node2D):
	"""Open the harvest bin UI with player's inventory"""
	inventory_manager = inv_manager
	player = player_ref
	
	# Pause the game
	get_tree().paused = true
	
	# Build the crop list
	_build_crop_list()
	
	# Show the UI
	visible = true
	
	print("✓ HarvestBinUI opened")

func close():
	"""Close the harvest bin UI"""
	visible = false
	get_tree().paused = false
	
	# Clear entries
	crop_entries.clear()
	print("✓ HarvestBinUI closed")

func _build_crop_list():
	"""Build the list of sellable crops from inventory"""
	# CRITICAL: Check for null inventory_manager
	if not inventory_manager:
		print("⚠ ERROR: inventory_manager is null!")
		return
	
	# Clear existing entries
	for child in crop_list_container.get_children():
		child.queue_free()
	
	crop_entries.clear()
	
	# Get all crops in a specific order
	var crop_order = ["Tomato", "Mushroom", "Pumpkin", "Corn"]
	
	# Validate max_slots
	var max_slots = inventory_manager.max_slots if inventory_manager else 0
	if max_slots <= 0 or max_slots > 100:  # Sanity check
		print("⚠ WARNING: Invalid max_slots: ", max_slots)
		return
	
	# Scan inventory for sellable crops in order
	for crop_name in crop_order:
		var found = false
		for i in range(max_slots):
			var item = inventory_manager.items[i]
			if item and item.name == crop_name:
				var quantity = inventory_manager.quantities[i]
				if quantity > 0:
					_create_crop_entry(item, quantity)
					found = true
					break
		
		# If crop not found in inventory, still show it with 0 quantity
		if not found:
			_create_crop_entry_placeholder(crop_name)
	
	# Update total value
	_update_total_value()
	
	# If no crops available, disable sell button
	var has_crops = false
	for entry in crop_entries:
		if entry.max_quantity > 0:
			has_crops = true
			break
	
	if sell_button:
		sell_button.disabled = not has_crops

func _create_crop_entry_placeholder(crop_name: String):
	"""Create a placeholder entry for crops not in inventory"""
	# Create a dummy item for display
	var dummy_item = Item.new()
	dummy_item.name = crop_name
	
	# Set the icon based on crop name
	match crop_name:
		"Tomato":
			dummy_item.icon = preload("uid://x5ouhlv5ewvl")
		"Mushroom":
			dummy_item.icon = preload("uid://bru1lxe77y5qo")
		"Pumpkin":
			dummy_item.icon = preload("uid://ch0tlq2sg0anc")
		"Corn":
			dummy_item.icon = preload("uid://cbjgaskk6flxt")
	
	_create_crop_entry(dummy_item, 0)

func _create_crop_entry(item: Item, max_quantity: int):
	"""Create a UI entry for a single crop type"""
	var entry_container = HBoxContainer.new()
	entry_container.custom_minimum_size = Vector2(0, 80)
	entry_container.add_theme_constant_override("separation", 15)
	
	# Crop icon
	var icon_texture = TextureRect.new()
	icon_texture.texture = item.icon
	icon_texture.custom_minimum_size = Vector2(64, 64)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	entry_container.add_child(icon_texture)
	
	# Crop info (name + price)
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 2)
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	info_container.add_child(name_label)
	
	var price_label = Label.new()
	var unit_price = CROP_PRICES.get(item.name, 0)
	price_label.text = str(unit_price) + " coins each"
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_container.add_child(price_label)
	
	var available_label = Label.new()
	available_label.text = "Available: " + str(max_quantity)
	available_label.add_theme_font_size_override("font_size", 16)
	available_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
	info_container.add_child(available_label)
	
	entry_container.add_child(info_container)
	
	# Quantity controls
	var quantity_container = HBoxContainer.new()
	quantity_container.add_theme_constant_override("separation", 8)
	
	# Minus button
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(50, 50)
	_apply_small_button_style(minus_button)
	quantity_container.add_child(minus_button)
	
	# Quantity display with background panel
	var quantity_panel = Panel.new()
	quantity_panel.custom_minimum_size = Vector2(80, 50)
	quantity_panel.add_theme_stylebox_override("panel", _display_style)
	
	# Create label for quantity number
	var quantity_display = Label.new()
	quantity_display.text = "0"
	quantity_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quantity_display.add_theme_font_size_override("font_size", 32)
	quantity_display.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))  # Very dark text
	
	# Use anchors to center the label in the panel
	quantity_display.anchor_left = 0
	quantity_display.anchor_right = 1
	quantity_display.anchor_top = 0
	quantity_display.anchor_bottom = 1
	quantity_display.offset_left = 0
	quantity_display.offset_right = 0
	quantity_display.offset_top = 0
	quantity_display.offset_bottom = 0
	
	# Add label to panel
	quantity_panel.add_child(quantity_display)
	quantity_container.add_child(quantity_panel)
	
	# Plus button
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(50, 50)
	_apply_small_button_style(plus_button)
	quantity_container.add_child(plus_button)
	
	# ALL button
	var all_button = Button.new()
	all_button.text = "ALL"
	all_button.custom_minimum_size = Vector2(70, 50)
	_apply_small_button_style(all_button)
	quantity_container.add_child(all_button)
	
	entry_container.add_child(quantity_container)
	
	# Track current quantity - USE DICTIONARY so lambdas can modify it
	var quantity_ref = {"value": 0}
	
	# Connect signals
	minus_button.pressed.connect(func(): 
		quantity_ref.value = max(0, quantity_ref.value - 1)
		quantity_display.text = str(quantity_ref.value)
		_update_total_value()
	)
	
	plus_button.pressed.connect(func(): 
		quantity_ref.value = min(max_quantity, quantity_ref.value + 1)
		quantity_display.text = str(quantity_ref.value)
		_update_total_value()
	)
	
	all_button.pressed.connect(func(): 
		quantity_ref.value = max_quantity
		quantity_display.text = str(quantity_ref.value)
		_update_total_value()
	)
	
	# Disable buttons if no quantity available
	if max_quantity == 0:
		minus_button.disabled = true
		plus_button.disabled = true
		all_button.disabled = true
		quantity_display.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	# Store entry data
	crop_entries.append({
		"item_name": item.name,
		"max_quantity": max_quantity,
		"quantity_label": quantity_display,
		"get_quantity": func(): return quantity_ref.value
	})
	
	# Add to container
	crop_list_container.add_child(entry_container)
	
	# Add separator (subtle)
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", _separator_style)
	crop_list_container.add_child(separator)

func _apply_small_button_style(button: Button):
	"""Apply consistent styling to small buttons using CACHED styles"""
	button.add_theme_stylebox_override("normal", _button_style_normal)
	button.add_theme_stylebox_override("hover", _button_style_hover)
	button.add_theme_stylebox_override("pressed", _button_style_pressed)
	button.add_theme_stylebox_override("disabled", _button_style_disabled)
	button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	button.add_theme_font_size_override("font_size", 20)

func _update_total_value():
	"""Update the total value label"""
	var total = 0
	
	for entry in crop_entries:
		var quantity = entry.get_quantity.call()
		var unit_price = CROP_PRICES.get(entry.item_name, 0)
		total += unit_price * quantity
	
	if total_value_label:
		total_value_label.text = "Total: " + str(total) + " Coins"
		total_value_label.add_theme_font_size_override("font_size", 26)
		total_value_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))  # Very dark
	
	# Enable/disable sell button based on total
	if sell_button:
		sell_button.disabled = (total == 0)

func _on_sell_pressed():
	"""Sell all selected crops"""
	var total_coins = 0
	var items_sold: Dictionary = {}
	
	# Calculate totals and remove items
	for entry in crop_entries:
		var quantity = entry.get_quantity.call()
		
		if quantity > 0:
			var crop_name = entry.item_name
			var unit_price = CROP_PRICES.get(crop_name, 0)
			var value = unit_price * quantity
			
			# Remove items from inventory
			if inventory_manager.remove_item_by_name(crop_name, quantity):
				total_coins += value
				items_sold[crop_name] = quantity
			else:
				print("⚠ Warning: Failed to remove ", crop_name, " x", quantity)
	
	# Add coins to inventory
	if total_coins > 0:
		var coin_item = _create_coin_item()
		inventory_manager.add_item(coin_item, total_coins)
		
		# Play sell sound effect
		if AudioManager:
			AudioManager.play_crop_sell()
		
		print("✓ Sold crops for ", total_coins, " coins")
		
		# Auto-save after selling
		_auto_save_after_sale()
	
	# Close the UI
	close()

func _auto_save_after_sale():
	"""Auto-save after selling crops"""
	if player and GameManager.current_save_slot >= 0:
		print("Auto-saving after crop sale...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
		print("✓ Auto-save complete")

func _create_coin_item() -> Item:
	"""Create a coin item for adding to inventory"""
	var coin = Item.new()
	coin.name = "Coin"
	coin.description = "Currency used to purchase new weapons"
	coin.stack_size = 9999
	coin.item_type = "currency"
	coin.icon = preload("res://Resources/Map/Objects/Coin.png")
	return coin

func _on_close_pressed():
	"""Close button pressed"""
	close()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
