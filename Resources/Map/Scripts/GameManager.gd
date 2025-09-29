# GameManager.gd - Add this as an Autoload in Project Settings
extends Node

# Persistent inventory data
var saved_inventory_items: Array[Item] = []
var saved_inventory_quantities: Array[int] = []
var current_scene_type: String = "farm"  # "farm" or "safehouse"

# Persistent storage data - Dictionary with storage_id as key
var saved_storage_data: Dictionary = {}

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"  # Adjust path as needed
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"  # You'll create this

func _ready():
	print("GameManager initialized")

func save_player_inventory(inventory_manager: InventoryManager):
	"""Save the current inventory state"""
	#print("Saving inventory state...")
	
	# Clear previous data
	saved_inventory_items.clear()
	saved_inventory_quantities.clear()
	
	# Copy current inventory data
	saved_inventory_items = inventory_manager.items.duplicate()
	saved_inventory_quantities = inventory_manager.quantities.duplicate()
	
	#print("Inventory saved: ", saved_inventory_items.size(), " slots")

func restore_player_inventory(inventory_manager: InventoryManager):
	"""Restore the saved inventory state"""
	#print("Restoring inventory state...")
	
	if saved_inventory_items.is_empty():
		#print("No saved inventory to restore")
		return
	
	# Clear current inventory
	inventory_manager.items.clear()
	inventory_manager.quantities.clear()
	
	# Restore saved data
	inventory_manager.items = saved_inventory_items.duplicate()
	inventory_manager.quantities = saved_inventory_quantities.duplicate()
	
	# Ensure proper array sizes
	inventory_manager.items.resize(inventory_manager.max_slots)
	inventory_manager.quantities.resize(inventory_manager.max_slots)
	
	# Emit signal to update UI
	inventory_manager.inventory_changed.emit()
	
	#print("Inventory restored successfully")

func save_storage_data(storage_id: String, storage_manager: InventoryManager):
	"""Save storage data for a specific storage container"""
	#print("Saving storage data for: ", storage_id)
	
	var storage_data = {
		"items": storage_manager.items.duplicate(),
		"quantities": storage_manager.quantities.duplicate(),
		"max_slots": storage_manager.max_slots
	}
	
	saved_storage_data[storage_id] = storage_data
	#print("Storage data saved for: ", storage_id, " with ", storage_manager.items.size(), " slots")

func restore_storage_data(storage_id: String, storage_manager: InventoryManager):
	#"""Restore storage data for a specific storage container"""
	#print("Restoring storage data for: ", storage_id)
	
	if not saved_storage_data.has(storage_id):
		#print("No saved storage data found for: ", storage_id)
		return
	
	var storage_data = saved_storage_data[storage_id]
	
	# Clear current storage
	storage_manager.items.clear()
	storage_manager.quantities.clear()
	
	# Restore saved data
	storage_manager.items = storage_data["items"].duplicate()
	storage_manager.quantities = storage_data["quantities"].duplicate()
	
	# Ensure proper array sizes
	storage_manager.items.resize(storage_manager.max_slots)
	storage_manager.quantities.resize(storage_manager.max_slots)
	
	# Emit signal to update UI
	storage_manager.inventory_changed.emit()
	
	#print("Storage data restored for: ", storage_id)

func get_storage_data(storage_id: String) -> Dictionary:
	"""Get storage data for a specific storage container"""
	if saved_storage_data.has(storage_id):
		return saved_storage_data[storage_id]
	return {}

func has_storage_data(storage_id: String) -> bool:
	"""Check if storage data exists for a specific container"""
	return saved_storage_data.has(storage_id)

func clear_storage_data(storage_id: String):
	"""Clear storage data for a specific container"""
	if saved_storage_data.has(storage_id):
		saved_storage_data.erase(storage_id)
		#print("Storage data cleared for: ", storage_id)

func change_to_safehouse():
	#"""Change to safehouse scene with inventory persistence"""
	#print("Changing to safehouse...")
	
	# Save current player inventory
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_inventory_manager"):
		save_player_inventory(player.get_inventory_manager())
	
	# Save all storage containers in current scene
	_save_all_storage_in_scene()
	
	current_scene_type = "safehouse"
	get_tree().change_scene_to_file(SAFEHOUSE_SCENE)

func change_to_farm():
	#"""Change to farm scene with inventory persistence"""
	#print("Changing to farm...")
	
	# Save current player inventory
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_inventory_manager"):
		save_player_inventory(player.get_inventory_manager())
	
	# Save all storage containers in current scene
	_save_all_storage_in_scene()
	
	current_scene_type = "farm"
	get_tree().change_scene_to_file(FARM_SCENE)

func _save_all_storage_in_scene():
	"""Save all storage containers in the current scene"""
	var storage_containers = get_tree().get_nodes_in_group("storage_containers")
	for container in storage_containers:
		if container.has_method("get_storage_id") and container.has_method("get_storage_manager"):
			save_storage_data(container.get_storage_id(), container.get_storage_manager())

func get_current_scene_type() -> String:
	return current_scene_type

# Debug function to print all saved storage
#func debug_print_storage():
	##print("=== SAVED STORAGE DATA ===")
	#for storage_id in saved_storage_data.keys():
		#var data = saved_storage_data[storage_id]
		##print("Storage ID: ", storage_id)
		##print("  Max slots: ", data.get("max_slots", 0))
		#var item_count = 0
		#for item in data.get("items", []):
			#if item != null:
				#item_count += 1
		##print("  Items stored: ", item_count)
	##print("===========================")
