extends Area2D
class_name LootChest

## LootChest - A chest that requires a specific key to unlock
## Contains randomized loot (technology points, coins)
## NOW WITH: Automatic beam guide that appears after 30 seconds if player has the key

@export var required_key_type: String  # "wood", "mushroom", "plant", "wool"
@export var chest_name: String = "Locked Chest"
@export var is_locked: bool = true

## Loot configuration
@export_group("Loot Tables")
@export var tech_points_min: int = 10
@export var tech_points_max: int = 50
@export var coins_min: int = 100
@export var coins_max: int = 500

## Visual configuration
@export_group("Visual")
@export var locked_texture: Texture2D
@export var unlocked_texture: Texture2D

## Beam Guide configuration
@export_group("Beam Guide")
@export var enable_beam_guide: bool = true  # Toggle beam feature
@export var beam_activation_delay: float = 30.0  # Seconds before beam appears
@onready var open_particles = $GPUParticles2D if has_node("GPUParticles2D") else null

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var interaction_prompt = $InteractionPrompt if has_node("InteractionPrompt") else null

var player_in_area: bool = false
var player_ref: Node2D
var loot_generated: bool = false
var chest_contents: Dictionary = {}
var beam_guide: Node2D  # Reference to the beam guide node

signal chest_opened(loot: Dictionary)
signal chest_unlocked

func _ready():
	add_to_group("loot_chests")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set initial sprite
	if sprite:
		sprite.texture = locked_texture if is_locked else unlocked_texture
	
	# Set up interaction prompt
	if interaction_prompt:
		update_prompt()
		interaction_prompt.visible = false
	
	# Setup beam guide
	if enable_beam_guide and is_locked:
		setup_beam_guide()
	
	print("Loot chest '", chest_name, "' initialized - Requires ", required_key_type, " key")

func setup_beam_guide():
	"""Create and add the beam guide component"""
	# Load the ChestBeamGuide script
	var beam_script = load("res://Resources/UI/chestbeamguide.gd")
	if not beam_script:
		push_error("Could not load ChestBeamGuide.gd - beam guide disabled")
		return
	
	# Create the beam guide node
	beam_guide = Node2D.new()
	beam_guide.set_script(beam_script)
	beam_guide.name = "BeamGuide"
	
	# Set custom activation delay if different from default
	beam_guide.set("activation_delay", beam_activation_delay)
	
	add_child(beam_guide)
	print("  ✓ Beam guide added to ", chest_name)

func update_prompt():
	if not interaction_prompt:
		return
	
	if is_locked:
		interaction_prompt.text = "Locked - Need " + required_key_type.capitalize() + " Key"
	else:
		interaction_prompt.text = "Press E to open " + chest_name

func _input(event):
	if player_in_area and event.is_action_pressed("interact"):
		attempt_interaction()

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

func attempt_interaction():
	if is_locked:
		attempt_unlock()
	else:
		open_chest()

func attempt_unlock():
	if not player_ref or not player_ref.has_method("get_inventory_manager"):
		print("No player reference!")
		return
	
	var inventory = player_ref.get_inventory_manager()
	
	# Search for the correct key in player's inventory
	for i in range(inventory.max_slots):
		var item = inventory.items[i]
		if item and item is KeyItem:
			var key = item as KeyItem
			if key.chest_type == required_key_type:
				# Found the right key! Use it
				inventory.remove_item(key, 1)
				unlock_chest()
				return
	
	# No matching key found
	print("Player doesn't have the ", required_key_type, " key!")
	show_message("You need a " + required_key_type.capitalize() + " Key to unlock this chest!")

func unlock_chest():
	is_locked = false
	if sprite:
		sprite.texture = unlocked_texture
	update_prompt()
	chest_unlocked.emit()
	
	show_message("Chest Unlocked!")
	print("Chest unlocked: ", chest_name)
	
	# Auto-open after unlocking
	await get_tree().create_timer(0.5).timeout
	open_chest()

func open_chest():
	
	if open_particles:
		open_particles.emitting = true
		
	if not loot_generated:
		generate_loot()
	
	# Give loot to player
	if player_ref:
		award_loot_to_player()
	
	chest_opened.emit(chest_contents)
	print("Chest opened: ", chest_name)
	
	if open_particles:
		await get_tree().create_timer(open_particles.lifetime).timeout
	# Optionally: Make chest disappear or change appearance
	queue_free()  # Remove chest after opening

func generate_loot():
	"""Generate random loot based on configuration"""
	loot_generated = true
	chest_contents = {}
	
	# Generate tech points
	var tech_points = randi_range(tech_points_min, tech_points_max)
	chest_contents["tech_points"] = tech_points
	
	# Generate coins
	var coins = randi_range(coins_min, coins_max)
	chest_contents["coins"] = coins
	
	print("Generated loot for ", chest_name, ": ", chest_contents)

func award_loot_to_player():
	"""Give the generated loot to the player through inventory system"""
	if not player_ref:
		return
	
	var message = "Chest Contents:\n"
	
	# Award tech points - add to inventory as items
	if chest_contents.has("tech_points"):
		var points = chest_contents["tech_points"]
		if player_ref.has_method("add_item_to_inventory"):
			var tech_item = _create_tech_point_item()
			if tech_item and player_ref.add_item_to_inventory(tech_item, points):
				message += "+ " + str(points) + " Technology Points\n"
				print("✓ Awarded ", points, " Tech Points")
			else:
				print("✗ Failed to add Tech Points to inventory")
		else:
			print("Player doesn't have add_item_to_inventory method")
	
	# Award coins - add to inventory as items
	if chest_contents.has("coins"):
		var coins = chest_contents["coins"]
		if player_ref.has_method("add_item_to_inventory"):
			var coin_item = _create_coin_item()
			if coin_item and player_ref.add_item_to_inventory(coin_item, coins):
				message += "+ " + str(coins) + " Coins\n"
				print("✓ Awarded ", coins, " Coins")
			else:
				print("✗ Failed to add Coins to inventory")
		else:
			print("Player doesn't have add_item_to_inventory method")
	
	show_message(message)

func _create_tech_point_item() -> Item:
	"""Create a Tech Point item for inventory"""
	var item = Item.new()
	item.name = "Tech Point"
	item.description = "Technology points used to upgrade weapons"
	item.stack_size = 9999
	item.item_type = "currency"
	item.icon = load("res://Resources/Map/Objects/TechPoints.png")
	return item

func _create_coin_item() -> Item:
	"""Create a Coin item for inventory"""
	var item = Item.new()
	item.name = "Coin"
	item.description = "Currency used to purchase new weapons"
	item.stack_size = 9999
	item.item_type = "currency"
	item.icon = load("res://Resources/Map/Objects/Coin.png")
	return item

func show_message(text: String):
	"""Display a message to the player - customize based on your UI system"""
	print(text)
	# TODO: Implement proper UI notification
	# You might want to call a global notification system here

## Helper function to create a key from base materials
static func create_key_from_material(material_name: String) -> KeyItem:
	"""Convert a base material into a key"""
	var key = KeyItem.new()
	
	match material_name.to_lower():
		"wood":
			key.name = "Wood Key"
			key.description = "A key crafted from wood"
			key.chest_type = "wood"
			# Load wood key icon
			key.icon = load("res://Resources/Map/Objects/WoodKey.png")
		"mushroom":
			key.name = "Mushroom Key"
			key.description = "A key crafted from mushrooms"
			key.chest_type = "mushroom"
			key.icon = load("res://Resources/Map/Objects/MushroomKey.png")
		"plant", "fiber":
			key.name = "Plant Key"
			key.description = "A key crafted from plants"
			key.chest_type = "plant"
			key.icon = load("res://Resources/Map/Objects/PlantKey.png")
		"wool", "fur":
			key.name = "Wool Key"
			key.description = "A key crafted from wool"
			key.chest_type = "wool"
			key.icon = load("res://Resources/Map/Objects/WoolKey.png")
		_:
			push_error("Unknown material type: " + material_name)
			return null
	
	return key
