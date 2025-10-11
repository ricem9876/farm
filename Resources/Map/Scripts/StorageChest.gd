extends Area2D
class_name StorageChest

@export var storage_id: String = "safehouse_chest"
@export var max_slots: int = 40
@export var chest_name: String = "Storage Chest"

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var interaction_prompt = $InteractionPrompt

var storage_manager: InventoryManager
var storage_ui: StorageUI
var player_in_area: bool = false
var player_ref: Node2D

signal storage_opened
signal storage_closed

func _ready():
	# Add to storage containers group
	add_to_group("storage_containers")
	
	# Create storage manager
	storage_manager = InventoryManager.new()
	storage_manager.max_slots = max_slots
	add_child(storage_manager)
	
	# Storage data will be loaded from save file when player enters safehouse
	# Don't load from GameManager here - wait for explicit load
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up interaction prompt
	if interaction_prompt:
		interaction_prompt.text = "Press E to open " + chest_name
		interaction_prompt.visible = false
	
	print("Storage chest '", storage_id, "' initialized with ", max_slots, " slots")

func load_from_save_data(storage_data: Dictionary):
	"""Load storage contents from save file data"""
	if storage_data.is_empty():
		print("No storage data to load for: ", storage_id)
		return
	
	print("Loading storage from save data for: ", storage_id)
	print("DEBUG: Storage data items: ", storage_data.items)
	
	# Clear current contents
	for i in range(storage_manager.max_slots):
		storage_manager.items[i] = null
		storage_manager.quantities[i] = 0
	
	# Restore items from save data
	if storage_data.has("items"):
		var items_data = storage_data.items
		print("DEBUG: Items array size: ", items_data.size())
		for i in range(min(items_data.size(), storage_manager.max_slots)):
			var item_data = items_data[i]
			if item_data != null and item_data is Dictionary:
				print("DEBUG: Restoring item at slot ", i, ": ", item_data)
				# Get player to use its item creation method
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("_create_item_from_name"):
					var item = player._create_item_from_name(item_data.name)
					if item:
						storage_manager.items[i] = item
						storage_manager.quantities[i] = int(item_data.quantity)
						print("DEBUG: Set slot ", i, " to ", item.name, " x", storage_manager.quantities[i])
					else:
						print("DEBUG: Failed to create item: ", item_data.name)
	
	storage_manager.inventory_changed.emit()
	print("  ✓ Storage loaded: ", storage_id)

func get_save_data() -> Dictionary:
	"""Get storage data for saving to file"""
	var data = {
		"storage_id": storage_id,
		"items": [],
		"max_slots": max_slots
	}
	
	# Save each item
	for i in range(storage_manager.max_slots):
		if storage_manager.items[i] != null:
			data.items.append({
				"name": storage_manager.items[i].name,
				"quantity": storage_manager.quantities[i]
			})
		else:
			data.items.append(null)
	
	return data

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		toggle_storage()

func _on_body_entered(body):
	if body.has_method("get_inventory_manager"):
		player_ref = body
		player_in_area = true
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body == player_ref:
		player_ref = null
		player_in_area = false
		if interaction_prompt:
			interaction_prompt.visible = false
		close_storage()

func toggle_storage():
	if storage_ui and storage_ui.visible:
		close_storage()
	else:
		open_storage()

func open_storage():
	if not player_ref:
		return
		
	print("Opening storage chest: ", chest_name)
	
	# Create storage UI if it doesn't exist
	if not storage_ui:
		create_storage_ui()
	
	# Show storage UI
	storage_ui.visible = true
	storage_opened.emit()

func close_storage():
	if storage_ui and storage_ui.visible:
		storage_ui.visible = false
		storage_closed.emit()
		
		# Auto-save when closing chest
		if GameManager.current_save_slot >= 0:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				print("Auto-saving after closing chest...")
				var player_data = SaveSystem.collect_player_data(player)
				SaveSystem.save_game(GameManager.current_save_slot, player_data)

func create_storage_ui():
	# Create a CanvasLayer to ignore camera transformations
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	get_tree().current_scene.add_child(canvas_layer)
	
	# Load the storage UI scene
	var ui_scene = preload("res://Resources/Inventory/StorageUI.tscn")
	storage_ui = ui_scene.instantiate()
	
	# Add to canvas layer
	canvas_layer.add_child(storage_ui)
	
	# Set anchors to center the UI on screen
	storage_ui.anchor_left = 0.5
	storage_ui.anchor_right = 0.5
	storage_ui.anchor_top = 0.5
	storage_ui.anchor_bottom = 0.5
	storage_ui.offset_left = -400
	storage_ui.offset_right = 400
	storage_ui.offset_top = -300
	storage_ui.offset_bottom = 300
	
	# Set up the UI for storage with both inventories
	var player_inventory = player_ref.get_inventory_manager()
	storage_ui.setup_storage(player_inventory, storage_manager)
	
	# Connect close signal
	storage_ui.storage_closed.connect(close_storage)
	
	storage_ui.visible = false

# Helper methods
func add_item_to_storage(item: Item, quantity: int = 1) -> bool:
	return storage_manager.add_item(item, quantity)

func remove_item_from_storage(item: Item, quantity: int = 1) -> int:
	return storage_manager.remove_item(item, quantity)

func get_storage_contents() -> Array:
	var contents = []
	for i in range(storage_manager.max_slots):
		if storage_manager.items[i] != null:
			contents.append({
				"item": storage_manager.items[i],
				"quantity": storage_manager.quantities[i]
			})
	return contents

# Methods for SaveSystem integration
func get_storage_id() -> String:
	return storage_id

func get_storage_manager() -> InventoryManager:
	return storage_manager
