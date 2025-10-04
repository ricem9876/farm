# ItemSpawner.gd - Utility class for spawning items
class_name ItemSpawner

# Preload the pickup scene at class level for better performance
static var pickup_scene = preload("res://Resources/Inventory/ItemPickup.tscn")

static func spawn_item(item_name: String, spawn_position: Vector2, parent_node: Node):
	if not pickup_scene:
		push_error("ItemSpawner: ItemPickup.tscn not found at res://Resources/Inventory/ItemPickup.tscn")
		return
	
	if not parent_node:
		push_error("ItemSpawner: parent_node is null")
		return
	
	var pickup = pickup_scene.instantiate()
	
	if not pickup:
		push_error("ItemSpawner: Failed to instantiate ItemPickup scene")
		return
	
	pickup.item_name = item_name
	
	# Add some random spread when spawning
	var random_offset = Vector2(
		randf_range(-20, 20),
		randf_range(-20, 20)
	)
	
	pickup.global_position = spawn_position + random_offset
	
	# Use call_deferred to avoid state change conflicts during physics processing
	parent_node.call_deferred("add_child", pickup)
	
	print("ItemSpawner: Spawned ", item_name, " at ", pickup.global_position)
