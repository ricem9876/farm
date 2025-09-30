# GameManager.gd - Improved version with better state management
extends Node

# Persistent inventory data
var saved_inventory_items: Array[Item] = []
var saved_inventory_quantities: Array[int] = []
var current_scene_type: String = "farm"

# Persistent storage data
var saved_storage_data: Dictionary = {}

# Weapon data persistence
var saved_primary_weapon: WeaponItem = null
var saved_secondary_weapon: WeaponItem = null
var saved_active_slot: int = 0

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	print("GameManager initialized")

func save_player_inventory(inventory_manager: InventoryManager):
	"""Save the current inventory state"""
	print("Saving inventory state...")
	
	saved_inventory_items.clear()
	saved_inventory_quantities.clear()
	
	saved_inventory_items = inventory_manager.items.duplicate()
	saved_inventory_quantities = inventory_manager.quantities.duplicate()
	
	print("Inventory saved: ", saved_inventory_items.size(), " slots")

func restore_player_inventory(inventory_manager: InventoryManager):
	"""Restore the saved inventory state"""
	print("Restoring inventory state...")
	
	if saved_inventory_items.is_empty():
		print("No saved inventory to restore")
		return
	
	inventory_manager.items.clear()
	inventory_manager.quantities.clear()
	
	inventory_manager.items = saved_inventory_items.duplicate()
	inventory_manager.quantities = saved_inventory_quantities.duplicate()
	
	inventory_manager.items.resize(inventory_manager.max_slots)
	inventory_manager.quantities.resize(inventory_manager.max_slots)
	
	inventory_manager.inventory_changed.emit()
	
	print("Inventory restored successfully")

func save_player_weapons(weapon_manager: WeaponManager):
	"""Save the current weapon loadout"""
	print("Saving weapon loadout...")
	
	saved_primary_weapon = weapon_manager.primary_slot
	saved_secondary_weapon = weapon_manager.secondary_slot
	saved_active_slot = weapon_manager.active_slot
	
	if saved_primary_weapon:
		print("  Primary: ", saved_primary_weapon.name)
	if saved_secondary_weapon:
		print("  Secondary: ", saved_secondary_weapon.name)
	print("  Active slot: ", saved_active_slot)

func restore_player_weapons(weapon_manager: WeaponManager):
	"""Restore the saved weapon loadout"""
	print("Restoring weapon loadout...")
	
	# Unequip current weapons first
	weapon_manager.unequip_weapon(0)
	weapon_manager.unequip_weapon(1)
	
	# Restore saved weapons
	if saved_primary_weapon:
		weapon_manager.equip_weapon(saved_primary_weapon, 0)
		print("  Restored primary: ", saved_primary_weapon.name)
	
	if saved_secondary_weapon:
		weapon_manager.equip_weapon(saved_secondary_weapon, 1)
		print("  Restored secondary: ", saved_secondary_weapon.name)
	
	# Restore active slot
	if saved_active_slot != weapon_manager.active_slot:
		weapon_manager.switch_weapon()
	
	print("Weapons restored successfully")

func save_storage_data(storage_id: String, storage_manager: InventoryManager):
	"""Save storage data for a specific storage container"""
	print("Saving storage data for: ", storage_id)
	
	var storage_data = {
		"items": storage_manager.items.duplicate(),
		"quantities": storage_manager.quantities.duplicate(),
		"max_slots": storage_manager.max_slots
	}
	
	saved_storage_data[storage_id] = storage_data
	print("Storage data saved for: ", storage_id)

func restore_storage_data(storage_id: String, storage_manager: InventoryManager):
	"""Restore storage data for a specific storage container"""
	print("Restoring storage data for: ", storage_id)
	
	if not saved_storage_data.has(storage_id):
		print("No saved storage data found for: ", storage_id)
		return
	
	var storage_data = saved_storage_data[storage_id]
	
	storage_manager.items.clear()
	storage_manager.quantities.clear()
	
	storage_manager.items = storage_data["items"].duplicate()
	storage_manager.quantities = storage_data["quantities"].duplicate()
	
	storage_manager.items.resize(storage_manager.max_slots)
	storage_manager.quantities.resize(storage_manager.max_slots)
	
	storage_manager.inventory_changed.emit()
	
	print("Storage data restored for: ", storage_id)

func change_to_safehouse():
	"""Change to safehouse scene with full state persistence"""
	print("\n=== CHANGING TO SAFEHOUSE ===")
	
	# Save current player state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("get_inventory_manager"):
			save_player_inventory(player.get_inventory_manager())
		if player.has_method("get_weapon_manager"):
			save_player_weapons(player.get_weapon_manager())
	
	# Save all storage containers
	_save_all_storage_in_scene()
	
	current_scene_type = "safehouse"
	
	# Change scene
	print("Loading safehouse scene...")
	var error = get_tree().change_scene_to_file(SAFEHOUSE_SCENE)
	if error != OK:
		print("ERROR: Failed to change scene! Error code: ", error)
	else:
		print("Scene change initiated successfully")

func change_to_farm():
	"""Change to farm scene with full state persistence"""
	print("\n=== CHANGING TO FARM ===")
	
	# Save current player state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("get_inventory_manager"):
			save_player_inventory(player.get_inventory_manager())
		if player.has_method("get_weapon_manager"):
			save_player_weapons(player.get_weapon_manager())
	
	# Save all storage containers
	_save_all_storage_in_scene()
	
	current_scene_type = "farm"
	
	# Change scene
	print("Loading farm scene...")
	var error = get_tree().change_scene_to_file(FARM_SCENE)
	if error != OK:
		print("ERROR: Failed to change scene! Error code: ", error)
	else:
		print("Scene change initiated successfully")

func _save_all_storage_in_scene():
	"""Save all storage containers in the current scene"""
	var storage_containers = get_tree().get_nodes_in_group("storage_containers")
	print("Saving ", storage_containers.size(), " storage containers...")
	for container in storage_containers:
		if container.has_method("get_storage_id") and container.has_method("get_storage_manager"):
			save_storage_data(container.get_storage_id(), container.get_storage_manager())

func get_current_scene_type() -> String:
	return current_scene_type
