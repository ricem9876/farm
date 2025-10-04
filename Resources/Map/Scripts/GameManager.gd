# GameManager.gd - Improved version with better state management
extends Node

var current_level_settings: Dictionary = {}

# Persistent inventory data
var saved_inventory_items: Array[Item] = []
var saved_inventory_quantities: Array[int] = []
var current_scene_type: String = "farm"


# Persistent storage data
var saved_storage_data: Dictionary = {}
var current_save_slot: int = -1
var pending_load_data: Dictionary = {}

# Weapon data persistence
var saved_primary_weapon: WeaponItem = null
var saved_secondary_weapon: WeaponItem = null
var saved_active_slot: int = 0

var saved_weapon_storage: Array = []

# Player level system persistence
var saved_player_level: int = 1
var saved_player_xp: int = 0
var saved_skill_points: int = 0
var saved_stat_points: Dictionary = {}

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	print("GameManager initialized")

# ========== INVENTORY PERSISTENCE ==========

func save_player_inventory(inventory_manager: InventoryManager):
	"""Save the current inventory state"""
	print("Saving inventory state...")
	
	if not inventory_manager:
		print("  ⚠ Warning: inventory_manager is null, cannot save inventory")
		return
	
	saved_inventory_items.clear()
	saved_inventory_quantities.clear()
	
	saved_inventory_items = inventory_manager.items.duplicate()
	saved_inventory_quantities = inventory_manager.quantities.duplicate()
	
	print("  ✓ Inventory saved: ", saved_inventory_items.size(), " slots")

func restore_player_inventory(inventory_manager: InventoryManager):
	"""Restore the saved inventory state"""
	print("Restoring inventory state...")
	
	if not inventory_manager:
		print("  ⚠ Warning: inventory_manager is null, cannot restore inventory")
		return
	
	if saved_inventory_items.is_empty():
		print("  ℹ No saved inventory to restore")
		return
	
	inventory_manager.items.clear()
	inventory_manager.quantities.clear()
	
	inventory_manager.items = saved_inventory_items.duplicate()
	inventory_manager.quantities = saved_inventory_quantities.duplicate()
	
	inventory_manager.items.resize(inventory_manager.max_slots)
	inventory_manager.quantities.resize(inventory_manager.max_slots)
	
	inventory_manager.inventory_changed.emit()
	
	print("  ✓ Inventory restored successfully")

# ========== WEAPON PERSISTENCE ==========

func save_player_weapons(weapon_manager: WeaponManager):
	"""Save the current weapon loadout"""
	print("Saving weapon loadout...")
	
	if not weapon_manager:
		print("  ⚠ Warning: weapon_manager is null, cannot save weapons")
		return
	
	saved_primary_weapon = weapon_manager.primary_slot
	saved_secondary_weapon = weapon_manager.secondary_slot
	saved_active_slot = weapon_manager.active_slot
	
	if saved_primary_weapon:
		print("  Primary: ", saved_primary_weapon.name)
	else:
		print("  Primary: (empty)")
	
	if saved_secondary_weapon:
		print("  Secondary: ", saved_secondary_weapon.name)
	else:
		print("  Secondary: (empty)")
	
	print("  Active slot: ", saved_active_slot)

func save_weapon_storage(weapon_storage: WeaponStorageManager):
	"""Save weapon storage contents"""
	print("Saving weapon storage...")
	saved_weapon_storage.clear()
	
	for weapon in weapon_storage.weapons:
		if weapon:
			saved_weapon_storage.append({
				"name": weapon.name,
				"type": weapon.weapon_type
			})
		else:
			saved_weapon_storage.append({})
	
	print("Saved ", saved_weapon_storage.size(), " weapon storage slots")

func restore_weapon_storage(weapon_storage: WeaponStorageManager):
	"""Restore weapon storage contents"""
	print("Restoring weapon storage...")
	
	if saved_weapon_storage.is_empty():
		print("No saved storage data")
		return
	
	# Clear current storage
	for i in range(weapon_storage.max_slots):
		weapon_storage.weapons[i] = null
	
	# Restore weapons by recreating them from saved data
	for i in range(saved_weapon_storage.size()):
		var weapon_data = saved_weapon_storage[i]
		if weapon_data.is_empty():
			continue
		
		# Recreate weapon based on name
		var weapon: WeaponItem = null
		match weapon_data.name:
			"Pistol":
				weapon = WeaponFactory.create_pistol()
			"Shotgun":
				weapon = WeaponFactory.create_shotgun()
			"Assault Rifle":
				weapon = WeaponFactory.create_rifle()
			"Sniper Rifle":
				weapon = WeaponFactory.create_sniper()
			"Machine Gun":
				weapon = WeaponFactory.create_machine_gun()
			"Burst Rifle":
				weapon = WeaponFactory.create_burst_rifle()
		
		if weapon and i < weapon_storage.weapons.size():
			weapon_storage.weapons[i] = weapon
	
	weapon_storage.storage_changed.emit()
	print("Weapon storage restored")
func restore_player_weapons(weapon_manager: WeaponManager):
	"""Restore the saved weapon loadout"""
	print("Restoring weapon loadout...")
	
	if not weapon_manager:
		print("  ⚠ Warning: weapon_manager is null, cannot restore weapons")
		return
	
	# Unequip current weapons first (if any)
	if weapon_manager.has_weapon_in_slot(0):
		weapon_manager.unequip_weapon(0)
		print("  Unequipped current primary weapon")
	
	if weapon_manager.has_weapon_in_slot(1):
		weapon_manager.unequip_weapon(1)
		print("  Unequipped current secondary weapon")
	
	# Restore saved weapons
	if saved_primary_weapon:
		var success = weapon_manager.equip_weapon(saved_primary_weapon, 0)
		if success:
			print("  ✓ Restored primary: ", saved_primary_weapon.name)
		else:
			print("  ✗ Failed to restore primary weapon")
	else:
		print("  ℹ No primary weapon to restore")
	
	if saved_secondary_weapon:
		var success = weapon_manager.equip_weapon(saved_secondary_weapon, 1)
		if success:
			print("  ✓ Restored secondary: ", saved_secondary_weapon.name)
		else:
			print("  ✗ Failed to restore secondary weapon")
	else:
		print("  ℹ No secondary weapon to restore")
	
	# Restore active slot (only if we have a weapon in that slot)
	if saved_active_slot != weapon_manager.active_slot:
		if weapon_manager.has_weapon_in_slot(saved_active_slot):
			weapon_manager.switch_weapon()
			print("  ✓ Switched to slot: ", saved_active_slot)
		else:
			print("  ⚠ Cannot switch to slot ", saved_active_slot, " - no weapon equipped")
	
	print("  ✓ Weapons restored successfully")


# ========== LEVEL SYSTEM PERSISTENCE ==========

func save_player_level_system(level_system: PlayerLevelSystem):
	"""Save the player's level and skill progression"""
	print("Saving player level system...")
	
	if not level_system:
		print("  ⚠ Warning: level_system is null, cannot save")
		return
	
	saved_player_level = level_system.current_level
	saved_player_xp = level_system.current_experience
	saved_skill_points = level_system.skill_points
	
	# Save all stat points
	saved_stat_points = {
		"health": level_system.points_in_health,
		"speed": level_system.points_in_speed,
		"damage": level_system.points_in_damage,
		"fire_rate": level_system.points_in_fire_rate,
		"luck": level_system.points_in_luck,
		"crit_chance": level_system.points_in_crit_chance,
		"crit_damage": level_system.points_in_crit_damage
	}
	
	print("  ✓ Level: ", saved_player_level)
	print("  ✓ XP: ", saved_player_xp)
	print("  ✓ Skill Points: ", saved_skill_points)
	print("  ✓ Stat points saved")

func restore_player_level_system(level_system: PlayerLevelSystem):
	"""Restore the player's level and skill progression"""
	print("Restoring player level system...")
	
	if not level_system:
		print("  ⚠ Warning: level_system is null, cannot restore")
		return
	
	if saved_player_level <= 0:
		print("  ℹ No saved level data to restore")
		return
	
	# Restore level and XP
	level_system.current_level = saved_player_level
	level_system.current_experience = saved_player_xp
	level_system.skill_points = saved_skill_points
	
	# Restore stat points
	if not saved_stat_points.is_empty():
		level_system.points_in_health = saved_stat_points.get("health", 0)
		level_system.points_in_speed = saved_stat_points.get("speed", 0)
		level_system.points_in_damage = saved_stat_points.get("damage", 0)
		level_system.points_in_fire_rate = saved_stat_points.get("fire_rate", 0)
		level_system.luck = saved_stat_points.get("luck", 0)
		level_system.points_in_crit_chance = saved_stat_points.get("crit_chance", 0)
		level_system.points_in_crit_damage = saved_stat_points.get("crit_damage", 0)
		
		# Recalculate all stats based on points invested
		level_system._initialize_stats()
		
		# Apply stat upgrades
		level_system.max_health = level_system.base_max_health + (level_system.points_in_health * 10)
		level_system.move_speed = level_system.base_move_speed + (level_system.points_in_speed * 5)
		level_system.damage_multiplier = 1.0 + (level_system.points_in_damage * 0.05)
		level_system.fire_rate_multiplier = 1.0 + (level_system.points_in_fire_rate * 0.04)
		level_system.luck = 1.0 + (level_system.points_in_luck * 0.01)
		level_system.critical_chance = level_system.points_in_crit_chance * 0.02
		level_system.critical_damage = 1.5 + (level_system.points_in_crit_damage * 0.1)
	
	print("  ✓ Level system restored")
	print("  ✓ Level: ", level_system.current_level)
	print("  ✓ XP: ", level_system.current_experience)
	print("  ✓ Skill Points: ", level_system.skill_points)

# ========== STORAGE PERSISTENCE ==========

func save_storage_data(storage_id: String, storage_manager: InventoryManager):
	"""Save storage data for a specific storage container"""
	print("Saving storage data for: ", storage_id)
	
	if not storage_manager:
		print("  ⚠ Warning: storage_manager is null")
		return
	
	var storage_data = {
		"items": storage_manager.items.duplicate(),
		"quantities": storage_manager.quantities.duplicate(),
		"max_slots": storage_manager.max_slots
	}
	
	saved_storage_data[storage_id] = storage_data
	print("  ✓ Storage data saved for: ", storage_id)

func restore_storage_data(storage_id: String, storage_manager: InventoryManager):
	"""Restore storage data for a specific storage container"""
	print("Restoring storage data for: ", storage_id)
	
	if not storage_manager:
		print("  ⚠ Warning: storage_manager is null")
		return
	
	if not saved_storage_data.has(storage_id):
		print("  ℹ No saved storage data found for: ", storage_id)
		return
	
	var storage_data = saved_storage_data[storage_id]
	
	storage_manager.items.clear()
	storage_manager.quantities.clear()
	
	storage_manager.items = storage_data["items"].duplicate()
	storage_manager.quantities = storage_data["quantities"].duplicate()
	
	storage_manager.items.resize(storage_manager.max_slots)
	storage_manager.quantities.resize(storage_manager.max_slots)
	
	storage_manager.inventory_changed.emit()
	
	print("  ✓ Storage data restored for: ", storage_id)

# ========== SCENE TRANSITIONS ==========

func change_to_safehouse():
	"""Change to safehouse scene with full state persistence"""
	print("\n=== CHANGING TO SAFEHOUSE ===")
	
	# Save current player state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Save inventory
		if player.has_method("get_inventory_manager"):
			var inv_mgr = player.get_inventory_manager()
			if inv_mgr:
				save_player_inventory(inv_mgr)
		
		# Save weapons
		if player.has_method("get_weapon_manager"):
			var wep_mgr = player.get_weapon_manager()
			if wep_mgr:
				save_player_weapons(wep_mgr)
		
		# Save level system
		if player.level_system:
			save_player_level_system(player.level_system)
	
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
		# Save inventory
		if player.has_method("get_inventory_manager"):
			var inv_mgr = player.get_inventory_manager()
			if inv_mgr:
				save_player_inventory(inv_mgr)
		
		# Save weapons
		if player.has_method("get_weapon_manager"):
			var wep_mgr = player.get_weapon_manager()
			if wep_mgr:
				save_player_weapons(wep_mgr)
		
		# Save level system
		if player.level_system:
			save_player_level_system(player.level_system)
	
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
