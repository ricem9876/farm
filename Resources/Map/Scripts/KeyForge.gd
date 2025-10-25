extends Area2D
class_name KeyForge

## KeyForge - Converts base materials into keys
## Player interacts with this station to craft keys from materials

@export var forge_name: String = "Key Forge"

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var interaction_prompt = $InteractionPrompt if has_node("InteractionPrompt") else null

var player_in_area: bool = false
var player_ref: Node2D
var forge_ui  # KeyForgeUI - using untyped to avoid dependency

signal key_crafted(key: Item)

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

func get_available_materials(inventory: InventoryManager) -> Array:
	"""Returns list of craftable materials player has"""
	var available = []
	var required_amount = 25
	
	var materials = ["Mushroom", "Wood", "Plant Fiber", "Wolf Fur"]
	for material_name in materials:
		if inventory.count_item_by_name(material_name) >= required_amount:
			available.append(material_name)
	
	return available

func show_message(text: String):
	"""Display a message to the player"""
	print(text)
	# TODO: Implement proper UI notification
