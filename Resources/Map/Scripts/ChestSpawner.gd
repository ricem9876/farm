extends Node2D
class_name ChestSpawner

## ChestSpawner - Randomly spawns 1-4 Harvest Baskets on the farm
## Place this node in your farm scene with spawn point markers

@export_group("Spawn Configuration")
@export var min_chests: int = 1
@export var max_chests: int = 4
@export var spawn_markers: Array[Marker2D] = []  # Drag Marker2D nodes here

@export_group("Harvest Basket")
@export var chest_scene: PackedScene  # Drag LootChest.tscn here
@export var basket_texture: Texture2D = preload("res://Resources/Inventory/Sprites/harvestbasket.png")

var spawned_chests: Array[Node] = []

signal chests_spawned(count: int)

func _ready():
	# Wait a frame to ensure scene is fully loaded
	await get_tree().process_frame
	spawn_random_chests()

func spawn_random_chests():
	"""Spawn random number of Harvest Baskets at random locations"""
	
	if spawn_markers.is_empty():
		push_error("ChestSpawner: No spawn markers assigned!")
		return
	
	if not chest_scene:
		push_error("ChestSpawner: No chest scene assigned!")
		return
	
	# Determine how many baskets to spawn
	var num_chests = randi_range(min_chests, max_chests)
	print("\n=== SPAWNING HARVEST BASKETS ===")
	print("Spawning ", num_chests, " harvest baskets on the farm")
	
	# Get shuffled list of spawn positions
	var available_positions = spawn_markers.duplicate()
	available_positions.shuffle()
	
	# Spawn baskets
	for i in range(min(num_chests, available_positions.size())):
		var marker = available_positions[i]
		spawn_chest_at(marker.global_position)
	
	print("✓ Spawned ", spawned_chests.size(), " harvest baskets")
	chests_spawned.emit(spawned_chests.size())

func spawn_chest_at(position: Vector2):
	"""Spawn a single Harvest Basket at the given position"""
	
	# Create chest instance
	var chest = chest_scene.instantiate() as LootChest
	if not chest:
		push_error("Failed to instantiate harvest basket!")
		return
	
	# Configure harvest basket
	chest.global_position = position
	chest.required_key_type = "harvest"
	chest.chest_name = "Harvest Basket"
	chest.is_locked = true
	
	# Set texture
	chest.locked_texture = basket_texture
	chest.unlocked_texture = basket_texture
	
	# Set loot - generous rewards for collecting all vegetables
	chest.tech_points_min = 50
	chest.tech_points_max = 100
	chest.coins_min = 200
	chest.coins_max = 500
	
	# Add to scene
	get_parent().add_child(chest)
	spawned_chests.append(chest)
	
	print("  ✓ Spawned Harvest Basket at ", position)

func clear_chests():
	"""Remove all spawned harvest baskets"""
	for chest in spawned_chests:
		if is_instance_valid(chest):
			chest.queue_free()
	spawned_chests.clear()
	print("Cleared all spawned harvest baskets")

func respawn_chests():
	"""Clear existing baskets and spawn new ones"""
	clear_chests()
	await get_tree().process_frame
	spawn_random_chests()

## Utility function to create spawn markers programmatically
func create_spawn_markers_in_area(center: Vector2, radius: float, count: int):
	"""Helper function to create spawn markers in a circular area"""
	spawn_markers.clear()
	
	for i in range(count):
		var marker = Marker2D.new()
		
		# Random position in circle
		var angle = randf() * TAU
		var distance = randf() * radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		marker.global_position = center + offset
		add_child(marker)
		spawn_markers.append(marker)
	
	print("Created ", count, " spawn markers around ", center)
