extends Area2D
class_name StorageChest

@export var storage_id: String = "safehouse_chest"  # Unique ID for this storage
@export var max_slots: int = 40  # Larger storage than player inventory
@export var chest_name: String = "Storage Chest"

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var interaction_prompt = $InteractionPrompt

var storage_manager: InventoryManager
var storage_ui: StorageUI  # Changed from InventoryUI to StorageUI
var player_in_area: bool = false
var player_ref: Node2D

signal storage_opened
signal storage_closed

func _ready():
	# Add to storage containers group for automatic saving
	add_to_group("storage_containers")
	
	# Create storage manager
	storage_manager = InventoryManager.new()
	storage_manager.max_slots = max_slots
	add_child(storage_manager)
	
	# Load storage data from GameManager
	GameManager.restore_storage_data(storage_id, storage_manager)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up interaction prompt
	if interaction_prompt:
		interaction_prompt.text = "Press F to open " + chest_name
		interaction_prompt.visible = false
	
	print("Storage chest '", storage_id, "' initialized with ", max_slots, " slots")

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		toggle_storage()

func _on_body_entered(body):
	print("Body entered storage area: ", body.name)
	if body.has_method("get_inventory_manager"):
		player_ref = body
		player_in_area = true
		if interaction_prompt:
			interaction_prompt.visible = true
		print("Player can now interact with storage chest")

func _on_body_exited(body):
	print("Body exited storage area: ", body.name)
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
		
		# Save storage data
		GameManager.save_storage_data(storage_id, storage_manager)
		print("Storage data saved for: ", storage_id)

func create_storage_ui():
	# Create a CanvasLayer to ignore camera transformations
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # High layer to appear on top
	get_tree().current_scene.add_child(canvas_layer)
	
	# Load the storage UI scene
	var ui_scene = preload("res://Resources/Inventory/StorageUI.tscn")
	storage_ui = ui_scene.instantiate()
	
	# Add to canvas layer instead of scene directly
	canvas_layer.add_child(storage_ui)
	
	# Set anchors to center the UI on screen
	storage_ui.anchor_left = 0.5
	storage_ui.anchor_right = 0.5
	storage_ui.anchor_top = 0.5
	storage_ui.anchor_bottom = 0.5
	storage_ui.offset_left = -400  # Half of UI width
	storage_ui.offset_right = 400   # Half of UI width
	storage_ui.offset_top = -300    # Half of UI height
	storage_ui.offset_bottom = 300  # Half of UI height
	
	# Set up the UI for storage with both inventories (no camera parameter)
	var player_inventory = player_ref.get_inventory_manager()
	storage_ui.setup_storage(player_inventory, storage_manager)
	
	# Connect close signal
	storage_ui.storage_closed.connect(close_storage)
	
	storage_ui.visible = false

# Method to add items to storage (useful for quest rewards, etc.)
func add_item_to_storage(item: Item, quantity: int = 1) -> bool:
	return storage_manager.add_item(item, quantity)

# Method to remove items from storage
func remove_item_from_storage(item: Item, quantity: int = 1) -> int:
	return storage_manager.remove_item(item, quantity)

# Method to check what's in storage
func get_storage_contents() -> Array:
	var contents = []
	for i in range(storage_manager.max_slots):
		if storage_manager.items[i] != null:
			contents.append({
				"item": storage_manager.items[i],
				"quantity": storage_manager.quantities[i]
			})
	return contents

# Methods for GameManager integration
func get_storage_id() -> String:
	return storage_id

func get_storage_manager() -> InventoryManager:
	return storage_manager

func _on_tree_exiting():
	# Save data when scene is changing
	GameManager.save_storage_data(storage_id, storage_manager)
