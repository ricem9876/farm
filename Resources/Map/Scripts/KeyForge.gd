extends Area2D
class_name KeyForge

## KeyForge - Converts base materials into keys
## Player interacts with this station to craft keys from materials

@export var forge_name: String = "Key Forge"

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var interaction_prompt = $InteractionPrompt

var player_in_area: bool = false
var player_ref: Node2D

# Crafting recipes: material_name -> number_required
var recipes: Dictionary = {
	"wood": 1,
	"mushroom": 1,
	"fiber": 1,  # For plant key
	"fur": 1     # For wool key
}

signal key_crafted(key: KeyItem)

func _ready():
	add_to_group("key_forges")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up interaction prompt
	if interaction_prompt:
		interaction_prompt.text = "Press E to use " + forge_name
		interaction_prompt.visible = false
	
	print("Key Forge initialized")

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		open_crafting_menu()

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

func open_crafting_menu():
	"""Opens a menu showing available keys to craft"""
	if not player_ref or not player_ref.has_method("get_inventory_manager"):
		return
	
	var inventory = player_ref.get_inventory_manager()
	
	# Check what materials the player has
	var available_materials = get_available_materials(inventory)
	
	if available_materials.is_empty():
		show_message("You don't have any materials to craft keys!")
		return
	
	# For now, let's create a simple auto-craft system
	# Later you can create a proper UI
	print("\n=== KEY FORGE ===")
	print("Available materials to convert into keys:")
	for material in available_materials:
		print("  - ", material.capitalize())
	
	# Craft first available key automatically
	# In a real implementation, you'd show a menu to choose
	craft_key(available_materials[0], inventory)

func get_available_materials(inventory: InventoryManager) -> Array:
	"""Returns list of craftable materials player has"""
	var available = []
	
	for material_name in recipes.keys():
		if has_material(inventory, material_name):
			available.append(material_name)
	
	return available

func has_material(inventory: InventoryManager, material_name: String) -> bool:
	"""Check if player has the required material"""
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item.name.to_lower() == material_name.to_lower():
			var quantity = inventory.quantities[i]
			if quantity >= recipes[material_name]:
				return true
	return false

func craft_key(material_name: String, inventory: InventoryManager):
	"""Craft a key from the given material"""
	
	# Find and remove the material
	var material_removed = false
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item.name.to_lower() == material_name.to_lower():
			var removed = inventory.remove_item(item, recipes[material_name])
			if removed > 0:
				material_removed = true
				break
	
	if not material_removed:
		show_message("Failed to remove material!")
		return
	
	# Create the key
	var key = LootChest.create_key_from_material(material_name)
	if not key:
		show_message("Failed to create key!")
		return
	
	# Add key to inventory
	if inventory.add_item(key, 1):
		show_message("Crafted: " + key.name + "!")
		key_crafted.emit(key)
		print("Successfully crafted ", key.name)
	else:
		show_message("Inventory full! Key was lost.")

func show_message(text: String):
	"""Display a message to the player"""
	print(text)
	# TODO: Implement proper UI notification
