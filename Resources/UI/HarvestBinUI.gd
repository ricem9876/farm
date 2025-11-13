# HarvestBinUI.gd
# UI for selling crops at the harvest bin
extends CanvasLayer

@onready var crop_list_container = %CropListContainer
@onready var total_value_label = %TotalValueLabel
@onready var sell_button = %SellButton
@onready var close_button = %CloseButton

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

func _enter_tree():
	# Add to group as early as possible
	add_to_group("harvest_bin_ui")
	print("✓ HarvestBinUI added to group 'harvest_bin_ui'")

func _ready():
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
	
	# Connect buttons
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
		print("  ✓ Sell button connected")
	else:
		print("  ✗ Sell button NOT FOUND")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		print("  ✓ Close button connected")
	else:
		print("  ✗ Close button NOT FOUND")
	
	print("=== HarvestBinUI ready complete ===")

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
	# Clear existing entries
	for child in crop_list_container.get_children():
		child.queue_free()
	
	crop_entries.clear()
	
	# Scan inventory for sellable crops
	for i in range(inventory_manager.max_slots):
		var item = inventory_manager.items[i]
		if item and item.name in CROP_PRICES:
			var quantity = inventory_manager.quantities[i]
			if quantity > 0:
				_create_crop_entry(item, quantity)
	
	# Update total value
	_update_total_value()
	
	# If no crops, show a message
	if crop_entries.size() == 0:
		var no_crops_label = Label.new()
		no_crops_label.text = "No crops to sell!"
		no_crops_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_crops_label.add_theme_font_size_override("font_size", 24)
		no_crops_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		crop_list_container.add_child(no_crops_label)
		
		# Disable sell button
		if sell_button:
			sell_button.disabled = true

func _create_crop_entry(item: Item, max_quantity: int):
	"""Create a UI entry for a single crop type"""
	var entry_container = HBoxContainer.new()
	entry_container.custom_minimum_size = Vector2(0, 60)
	entry_container.add_theme_constant_override("separation", 10)
	
	# Crop icon
	var icon_texture = TextureRect.new()
	icon_texture.texture = item.icon
	icon_texture.custom_minimum_size = Vector2(48, 48)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	entry_container.add_child(icon_texture)
	
	# Crop info (name + price)
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 20)
	info_container.add_child(name_label)
	
	var price_label = Label.new()
	var unit_price = CROP_PRICES[item.name]
	price_label.text = str(unit_price) + " coins each"
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_container.add_child(price_label)
	
	entry_container.add_child(info_container)
	
	# Quantity controls
	var quantity_container = HBoxContainer.new()
	quantity_container.add_theme_constant_override("separation", 5)
	
	# Minus button
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(40, 40)
	quantity_container.add_child(minus_button)
	
	# Quantity spinbox/label
	var quantity_spinbox = SpinBox.new()
	quantity_spinbox.min_value = 0
	quantity_spinbox.max_value = max_quantity
	quantity_spinbox.value = 0
	quantity_spinbox.step = 1
	quantity_spinbox.custom_minimum_size = Vector2(100, 40)
	quantity_spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_container.add_child(quantity_spinbox)
	
	# Plus button
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(40, 40)
	quantity_container.add_child(plus_button)
	
	# Max/All button
	var all_button = Button.new()
	all_button.text = "All"
	all_button.custom_minimum_size = Vector2(60, 40)
	quantity_container.add_child(all_button)
	
	entry_container.add_child(quantity_container)
	
	# Value label (shows total for this crop)
	var value_label = Label.new()
	value_label.text = "0 coins"
	value_label.custom_minimum_size = Vector2(100, 40)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	entry_container.add_child(value_label)
	
	# Connect signals
	minus_button.pressed.connect(func(): 
		quantity_spinbox.value = max(0, quantity_spinbox.value - 1)
	)
	
	plus_button.pressed.connect(func(): 
		quantity_spinbox.value = min(max_quantity, quantity_spinbox.value + 1)
	)
	
	all_button.pressed.connect(func(): 
		quantity_spinbox.value = max_quantity
	)
	
	quantity_spinbox.value_changed.connect(func(new_value): 
		_update_entry_value(value_label, item.name, int(new_value))
		_update_total_value()
	)
	
	# Store entry data
	crop_entries.append({
		"item_name": item.name,
		"max_quantity": max_quantity,
		"spinbox": quantity_spinbox,
		"value_label": value_label
	})
	
	# Add to container
	crop_list_container.add_child(entry_container)
	
	# Add separator
	var separator = HSeparator.new()
	crop_list_container.add_child(separator)

func _update_entry_value(label: Label, crop_name: String, quantity: int):
	"""Update the value label for a single crop entry"""
	var unit_price = CROP_PRICES[crop_name]
	var total = unit_price * quantity
	label.text = str(total) + " coins"

func _update_total_value():
	"""Update the total value label"""
	var total = 0
	
	for entry in crop_entries:
		var quantity = int(entry.spinbox.value)
		var unit_price = CROP_PRICES[entry.item_name]
		total += unit_price * quantity
	
	if total_value_label:
		total_value_label.text = "Total: " + str(total) + " coins"
	
	# Enable/disable sell button based on total
	if sell_button:
		sell_button.disabled = (total == 0)

func _on_sell_pressed():
	"""Sell all selected crops"""
	var total_coins = 0
	var items_sold: Dictionary = {}
	
	# Calculate totals and remove items
	for entry in crop_entries:
		var quantity = int(entry.spinbox.value)
		if quantity > 0:
			var crop_name = entry.item_name
			var unit_price = CROP_PRICES[crop_name]
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
		
		print("\n=== CROPS SOLD ===")
		for crop_name in items_sold:
			print("  ", crop_name, " x", items_sold[crop_name])
		print("Total earned: ", total_coins, " coins")
		print("==================\n")
		
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
