extends Node2D
class_name ChestSpawner

## ChestSpawner - Randomly spawns 1-4 loot chests on the farm
## Place this node in your farm scene with spawn point markers

@export_group("Spawn Configuration")
@export var min_chests: int = 1
@export var max_chests: int = 4
@export var spawn_markers: Array[Marker2D] = []  # Drag Marker2D nodes here

@export_group("Chest Types")
@export var chest_scene: PackedScene  # Drag LootChest.tscn here
@export var chest_textures: Dictionary = {
	"wood": preload("res://Resources/Map/Objects/WoodChest.png"),
	"mushroom": preload("res://Resources/Map/Objects/MushroomChest.png"),
	"plant": preload("res://Resources/Map/Objects/PlantChest.png"),
	"wool": preload("res://Resources/Map/Objects/WoolChest.png")
}

var chest_types: Array[String] = ["wood", "mushroom", "plant", "wool"]
var spawned_chests: Array[Node] = []

signal chests_spawned(count: int)

func _ready():
	# Wait a frame to ensure scene is fully loaded
	await get_tree().process_frame
	spawn_random_chests()

func spawn_random_chests():
	"""Spawn random number of chests at random locations"""
	
	if spawn_markers.is_empty():
		push_error("ChestSpawner: No spawn markers assigned!")
		return
	
	if not chest_scene:
		push_error("ChestSpawner: No chest scene assigned!")
		return
	
	# Determine how many chests to spawn
	var num_chests = randi_range(min_chests, max_chests)
	print("\n=== SPAWNING CHESTS ===")
	print("Spawning ", num_chests, " chests on the farm")
	
	# Get shuffled list of spawn positions
	var available_positions = spawn_markers.duplicate()
	available_positions.shuffle()
	
	# Spawn chests
	for i in range(min(num_chests, available_positions.size())):
		var marker = available_positions[i]
		spawn_chest_at(marker.global_position)
	
	print("✓ Spawned ", spawned_chests.size(), " chests")
	chests_spawned.emit(spawned_chests.size())

func spawn_chest_at(position: Vector2):
	"""Spawn a single chest at the given position"""
	
	# Create chest instance
	var chest = chest_scene.instantiate() as LootChest
	if not chest:
		push_error("Failed to instantiate chest!")
		return
	
	# Choose random chest type
	var chest_type = chest_types[randi() % chest_types.size()]
	
	# Configure chest
	chest.global_position = position
	chest.required_key_type = chest_type
	chest.chest_name = chest_type.capitalize() + " Chest"
	chest.is_locked = true
	
	# Set textures
	if chest_textures.has(chest_type):
		chest.locked_texture = chest_textures[chest_type]
		chest.unlocked_texture = chest_textures[chest_type]
	
	# Set loot based on chest type
	match chest_type:
		"wood":
			chest.tech_points_min = 10
			chest.tech_points_max = 30
			chest.coins_min = 50
			chest.coins_max = 150
		"mushroom":
			chest.tech_points_min = 20
			chest.tech_points_max = 50
			chest.coins_min = 100
			chest.coins_max = 300
		"plant":
			chest.tech_points_min = 15
			chest.tech_points_max = 40
			chest.coins_min = 75
			chest.coins_max = 200
		"wool":
			chest.tech_points_min = 25
			chest.tech_points_max = 60
			chest.coins_min = 150
			chest.coins_max = 400
	
	# Add to scene
	get_parent().add_child(chest)
	spawned_chests.append(chest)
	
	print("  ✓ Spawned ", chest_type.capitalize(), " Chest at ", position)

func clear_chests():
	"""Remove all spawned chests"""
	for chest in spawned_chests:
		if is_instance_valid(chest):
			chest.queue_free()
	spawned_chests.clear()
	print("Cleared all spawned chests")

func respawn_chests():
	"""Clear existing chests and spawn new ones"""
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
