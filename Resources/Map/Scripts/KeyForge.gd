extends Area2D
class_name KeyForge

## KeyForge - Converts vegetables into Harvest Keys
## Player interacts with this station to craft keys from 25 of each vegetable

@export var forge_name: String = "Key Forge"

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var interaction_prompt = $InteractionPrompt if has_node("InteractionPrompt") else null

var player_in_area: bool = false
var player_ref: Node2D
var forge_ui  # KeyForgeUI - using untyped to avoid dependency

signal key_crafted(key: Item)

# Recipe for Harvest Key: 25 of each vegetable
const HARVEST_KEY_RECIPE = {
	"Mushroom": 25,
	"Corn": 25,
	"Pumpkin": 25,
	"Tomato": 25
}

func _ready():
	add_to_group("key_forges")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up interaction prompt
	if interaction_prompt:
		interaction_prompt.text = "Press E to use " + forge_name
		interaction_prompt.visible = false
	
	print("Key Forge initialized - Harvest Key Recipe: 25 of each vegetable")

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
	"""Opens the Key Forge UI"""
	if not player_ref:
		return
	
	if not forge_ui:
		# Create UI if it doesn't exist
		var ui_scene = preload("res://Resources/UI/KeyForgeUI.tscn")
		forge_ui = ui_scene.instantiate()
		
		# Add to root so it appears over everything
		get_tree().root.add_child(forge_ui)
		print("✓ Created KeyForgeUI")
	
	# Setup and open the UI
	if forge_ui:
		forge_ui.setup(self, player_ref)
		forge_ui.open()
		print("Key Forge UI opened")

func can_craft_harvest_key(inventory: InventoryManager) -> bool:
	"""Check if player has enough vegetables to craft a Harvest Key"""
	if not inventory:
		return false
	
	for ingredient in HARVEST_KEY_RECIPE:
		var required = HARVEST_KEY_RECIPE[ingredient]
		if inventory.count_item_by_name(ingredient) < required:
			return false
	
	return true

func get_missing_ingredients(inventory: InventoryManager) -> Dictionary:
	"""Returns dictionary of what ingredients are still needed"""
	var missing = {}
	
	if not inventory:
		return HARVEST_KEY_RECIPE.duplicate()
	
	for ingredient in HARVEST_KEY_RECIPE:
		var required = HARVEST_KEY_RECIPE[ingredient]
		var current = inventory.count_item_by_name(ingredient)
		if current < required:
			missing[ingredient] = required - current
	
	return missing

func craft_harvest_key(inventory: InventoryManager) -> bool:
	"""Attempt to craft a Harvest Key, consuming the required vegetables"""
	if not can_craft_harvest_key(inventory):
		show_message("Not enough vegetables! Need 25 of each: Mushroom, Corn, Pumpkin, Tomato")
		return false
	
	# Consume ingredients
	for ingredient in HARVEST_KEY_RECIPE:
		var required = HARVEST_KEY_RECIPE[ingredient]
		if not inventory.remove_item_by_name(ingredient, required):
			show_message("Error: Failed to consume " + ingredient)
			return false
	
	# Create and give the Harvest Key
	var harvest_key = KeyItem.new()
	if inventory.add_item(harvest_key, 1):
		show_message("Crafted a Harvest Key!")
		key_crafted.emit(harvest_key)
		
		# Notify beam manager if it exists
		if has_node("/root/ChestBeamManager"):
			var beam_manager = get_node("/root/ChestBeamManager")
			beam_manager.notify_key_acquired("harvest")
		
		return true
	else:
		show_message("Inventory full! Could not add Harvest Key")
		# Refund ingredients since crafting failed
		for ingredient in HARVEST_KEY_RECIPE:
			var refund_item = _create_food_item(ingredient)
			if refund_item:
				inventory.add_item(refund_item, HARVEST_KEY_RECIPE[ingredient])
		return false

func _create_food_item(item_name: String) -> Item:
	"""Helper to recreate food items for refund"""
	var item = Item.new()
	match item_name:
		"Mushroom":
			item.name = "Mushroom"
			item.description = "A tasty mushroom that can be cooked or sold"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_mushroom.png")
		"Corn":
			item.name = "Corn"
			item.description = "Fresh corn harvested from the field"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_corn.png")
		"Pumpkin":
			item.name = "Pumpkin"
			item.description = "A large pumpkin ready for cooking or selling"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_pumpkin.png")
		"Tomato":
			item.name = "Tomato"
			item.description = "A ripe tomato full of nutrients"
			item.stack_size = 99
			item.item_type = "food"
			item.icon = preload("res://Resources/Inventory/Sprites/item_tomato.png")
		_:
			return null
	return item

func show_message(text: String):
	"""Display a message to the player"""
	print("KeyForge: ", text)
	# TODO: Implement proper UI notification
