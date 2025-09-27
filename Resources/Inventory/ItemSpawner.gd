# ItemSpawner.gd - Utility class for spawning items
class_name ItemSpawner

static func spawn_item(item_name: String, spawn_position: Vector2, parent_node: Node):
	var pickup_scene = preload("res://Resources/Inventory/ItemPickup.tscn")  # Adjust path
	var pickup = pickup_scene.instantiate()
	
	pickup.item_name = item_name
	pickup.global_position = spawn_position
	
	parent_node.add_child(pickup)
	
	# Add some random spread when spawning
	var random_offset = Vector2(
		randf_range(-20, 20),
		randf_range(-20, 20)
	)
	pickup.global_position += random_offset
