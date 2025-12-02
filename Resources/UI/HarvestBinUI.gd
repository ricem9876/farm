# HarvestBinUI.gd
# UI for selling crops at the harvest bin - SIMPLE VERSION WITH GUARANTEED BORDER
extends Control

@onready var crop_list_container = %CropListContainer
@onready var total_value_label = %TotalValueLabel
@onready var sell_button = %SellButton
@onready var close_button = %CloseButton
@onready var panel = %Panel  # Main panel for border
@onready var background = %Background  # ColorRect for background color

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
const BG_COLOR = Color(0.82, 0.71, 0.55)  # Tan/beige background
const BORDER_COLOR = Color(0.25, 0.15, 0.05)  # Very dark brown border
const TEXT_COLOR = Color(0.2, 0.2, 0.2)  # Dark text
const BUTTON_BG = Color(0.95, 0.88, 0.7)  # Light tan for buttons
const BUTTON_BORDER = Color(0.3, 0.2, 0.1)  # Dark brown border

# MEMORY LEAK FIX: Cache StyleBox objects
var _button_style_normal: StyleBoxFlat = null
var _button_style_hover: StyleBoxFlat = null
var _button_style_pressed: StyleBoxFlat = null
var _button_style_disabled: StyleBoxFlat = null
var _panel_style: StyleBoxFlat = null
var _display_style: StyleBoxFlat = null
var _separator_style: StyleBoxFlat = null
var _styles_created: bool = false

func _enter_tree():
	add_to_group("harvest_bin_ui")
	print("✓ HarvestBinUI added to group 'harvest_bin_ui'")

func _ready():
	if Engine.is_editor_hint():
		return
	
	if not is_in_group("harvest_bin_ui"):
		add_to_group("harvest_bin_ui")
	
	# CRITICAL: Allow processing while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make this Control fill the entire screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	visible = false
	
	print("=== HarvestBinUI _ready() called ===")
	
	# Create all StyleBox objects ONCE
	_create_cached_styles()
	
	# Apply styles - ColorRect for background, Panel for border
	_setup_panel_and_background()
	
	# Apply styles to buttons
	_setup_button_styles()
	
	# Connect buttons
	if sell_button:
		if sell_button.pressed.is_connected(_on_sell_pressed):
			sell_button.pressed.disconnect(_on_sell_pressed)
		sell_button.pressed.connect(_on_sell_pressed)
		print("  ✓ Sell button connected")
	
	if close_button:
		if close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.disconnect(_on_close_pressed)
		close_button.pressed.connect(_on_close_pressed)
		print("  ✓ Close button connected")

	if panel:
		var viewport_size = get_viewport_rect().size
		var panel_size = Vector2(750, 650)  # Your panel size
		panel.position = (viewport_size - panel_size) / 2.0
	
	print("=== HarvestBinUI ready complete ===")

func _create_cached_styles():
	"""Create all StyleBox objects ONCE and cache them to prevent memory leaks"""
	if _styles_created:
		return
	
	print("Creating cached StyleBox objects...")
	
	# Button styles
	_button_style_normal = StyleBoxFlat.new()
	_button_style_normal.bg_color = BUTTON_BG
	_button_style_normal.border_color = BUTTON_BORDER
	_button_style_normal.set_border_width_all(2)
	_button_style_normal.set_corner_radius_all(4)
	
	_button_style_hover = StyleBoxFlat.new()
	_button_style_hover.bg_color = Color(1.0, 0.95, 0.8)
	_button_style_hover.border_color = BUTTON_BORDER
	_button_style_hover.set_border_width_all(2)
	_button_style_hover.set_corner_radius_all(4)
	
	_button_style_pressed = StyleBoxFlat.new()
	_button_style_pressed.bg_color = Color(0.85, 0.78, 0.6)
	_button_style_pressed.border_color = BUTTON_BORDER
	_button_style_pressed.set_border_width_all(2)
	_button_style_pressed.set_corner_radius_all(4)
	
	_button_style_disabled = StyleBoxFlat.new()
	_button_style_disabled.bg_color = Color(0.7, 0.65, 0.55)
	_button_style_disabled.border_color = Color(0.5, 0.4, 0.3)
	_button_style_disabled.set_border_width_all(2)
	_button_style_disabled.set_corner_radius_all(4)
	
	# Panel style - ONLY BORDER, transparent background
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0, 0, 0, 0)  # Transparent - ColorRect handles background
	_panel_style.border_color = BORDER_COLOR
	_panel_style.set_border_width_all(8)  # THICK 8px border
	_panel_style.set_corner_radius_all(8)
	_panel_style.draw_center = true  # Must be true to show border
	
	# Quantity display background style
	_display_style = StyleBoxFlat.new()
	_display_style.bg_color = Color(0.95, 0.95, 0.95)
	_display_style.border_color = BUTTON_BORDER
	_display_style.set_border_width_all(2)
	_display_style.set_corner_radius_all(4)
	_display_style.content_margin_left = 4
	_display_style.content_margin_right = 4
	_display_style.content_margin_top = 4
	_display_style.content_margin_bottom = 4
	
	# Separator style
	_separator_style = StyleBoxFlat.new()
	_separator_style.bg_color = Color(0.6, 0.5, 0.3, 0.3)
	
	_styles_created = true
	print("✓ Cached StyleBox objects created")

func _setup_panel_and_background():
	"""Setup panel border and background color"""
	# Panel gets the border style
	if panel and _panel_style:
		panel.add_theme_stylebox_override("panel", _panel_style)
		print("✓ Panel border applied (8px dark brown)")
	else:
		print("⚠ Panel not found!")
	
	# ColorRect gets the background color
	if background:
		background.color = BG_COLOR
		print("✓ Background color applied (tan)")
	else:
		print("⚠ Background ColorRect not found!")

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
	if max_slots <= 0 or max_slots > 100:
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
	quantity_display.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	
	# Use anchors to center the label in the panel
	quantity_display.anchor_left = 0
	quantity_display.anchor_right = 1
	quantity_display.anchor_top = 0
	quantity_display.anchor_bottom = 1
	
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
	
	# Track current quantity
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
	
	# Add separator
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
		total_value_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	
	if sell_button:
		sell_button.disabled = (total == 0)

func _on_sell_pressed():
	"""Sell all selected crops"""
	var total_coins = 0
	var items_sold: Dictionary = {}
	
	for entry in crop_entries:
		var quantity = entry.get_quantity.call()
		
		if quantity > 0:
			var crop_name = entry.item_name
			var unit_price = CROP_PRICES.get(crop_name, 0)
			var value = unit_price * quantity
			
			if inventory_manager.remove_item_by_name(crop_name, quantity):
				total_coins += value
				items_sold[crop_name] = quantity
			else:
				print("⚠ Warning: Failed to remove ", crop_name, " x", quantity)
	
	if total_coins > 0:
		var coin_item = _create_coin_item()
		inventory_manager.add_item(coin_item, total_coins)
		
		if AudioManager:
			AudioManager.play_crop_sell()
		
		print("✓ Sold crops for ", total_coins, " coins")
		_auto_save_after_sale()
	
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
