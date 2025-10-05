# SaveSystem.gd
extends Node

const SAVE_DIR = "user://saves/"
const MAX_SAVES = 3

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_deleted(slot: int)

func _ready():
	# Create save directory if it doesn't exist
	_ensure_save_directory()

func _ensure_save_directory():
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			var error = dir.make_dir("saves")
			if error == OK:
				print("Created saves directory")
			else:
				print("Failed to create saves directory: ", error)
	else:
		print("Failed to open user:// directory")

func get_save_file_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + ".json"

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_file_path(slot))

func get_save_data(slot: int) -> Dictionary:
	"""Get metadata about a save file without fully loading it"""
	if not save_exists(slot):
		return {}
	
	var file = FileAccess.open(get_save_file_path(slot), FileAccess.READ)
	if not file:
		print("Failed to open save file for reading")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		return json.data
	else:
		print("Error parsing save file: ", json.get_error_message())
		return {}

func save_game(slot: int, player_data: Dictionary) -> bool:
	print("\n=== SAVING GAME TO SLOT ", slot, " ===")
	
	_ensure_save_directory()
	
	var save_data = {
		"slot": slot,
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": 0,
		"player": player_data
	}
	
	var file = FileAccess.open(get_save_file_path(slot), FileAccess.WRITE)
	if not file:
		print("Failed to open save file for writing!")
		print("Error: ", FileAccess.get_open_error())
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("Game saved successfully to slot ", slot)
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	print("\n=== LOADING GAME FROM SLOT ", slot, " ===")
	
	if not save_exists(slot):
		print("Save file does not exist!")
		return {}
	
	var save_data = get_save_data(slot)
	
	if save_data.is_empty():
		print("Failed to load save data!")
		return {}
	
	print("Game loaded successfully from slot ", slot)
	load_completed.emit(slot)
	return save_data

func delete_save(slot: int) -> bool:
	if not save_exists(slot):
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		print("Failed to open save directory")
		return false
	
	var filename = "save_" + str(slot) + ".json"
	var error = dir.remove(filename)
	
	if error == OK:
		print("Deleted save slot ", slot)
		save_deleted.emit(slot)
		return true
	else:
		print("Failed to delete save slot ", slot, " error: ", error)
		return false

func get_all_saves() -> Array:
	"""Returns array of save metadata for all slots"""
	var saves = []
	
	for i in range(MAX_SAVES):
		if save_exists(i):
			saves.append(get_save_data(i))
		else:
			saves.append({})
	
	return saves

func collect_player_data(player: Node2D) -> Dictionary:
	"""Collect all player data to save"""
	var data = {
		"level": 1,
		"experience": 0,
		"skill_points": 0,
		"stats": {},
		"position": {"x": player.global_position.x, "y": player.global_position.y},
		"health": 100,
		"max_health": 100,
		"inventory": [],
		"weapons": {},
		"current_scene": "farm",
		"player_stats": {}  # NEW: Add stats tracking
	}
	
	# Detect current scene - SAFE version
	var scene_name = "farm"
	if player.is_inside_tree():
		var tree = player.get_tree()
		if tree and tree.current_scene:
			var scene_path = tree.current_scene.scene_file_path
			if "safehouse" in scene_path.to_lower():
				scene_name = "safehouse"
			elif "farm" in scene_path.to_lower():
				scene_name = "farm"
	
	data.current_scene = scene_name
	data.player_stats = StatsTracker.get_stats_data()
	

	
	# Level system
	if player.level_system:
		data.level = player.level_system.current_level
		data.experience = player.level_system.current_experience
		data.skill_points = player.level_system.skill_points
		data.stats = {
			"health": player.level_system.points_in_health,
			"speed": player.level_system.points_in_speed,
			"damage": player.level_system.points_in_damage,
			"fire_rate": player.level_system.points_in_fire_rate,
			"luck": player.level_system.points_in_luck,
			"crit_chance": player.level_system.points_in_crit_chance,
			"crit_damage": player.level_system.points_in_crit_damage
		}
		data.max_health = player.level_system.max_health
	
	# Health
	data.health = player.current_health
	
	# Inventory
	if player.has_method("get_inventory_manager"):
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			var inv_data = []
			for i in range(inv_mgr.items.size()):  # FIXED: use inv_mgr
				var item = inv_mgr.items[i]  # FIXED
				if item:
					inv_data.append({
						"name": item.name,
						"quantity": inv_mgr.quantities[i]  # FIXED
					})
				else:
					inv_data.append(null)
			data.inventory = inv_data
			print("DEBUG: Saved inventory with ", inv_data.size(), " slots")  # Debug
	
	# Weapons
	if player.has_method("get_weapon_manager"):
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr:
			data.weapons = {
				"primary": weapon_mgr.primary_slot.name if weapon_mgr.primary_slot else null,
				"secondary": weapon_mgr.secondary_slot.name if weapon_mgr.secondary_slot else null,
				"active_slot": weapon_mgr.active_slot
			}
		print("DEBUG collect_player_data - Weapon data collected: ", data.weapons)
	# Weapon Storage (from GameManager)
	data.weapon_storage = []
	for weapon_data in GameManager.saved_weapon_storage:
		data.weapon_storage.append(weapon_data)
	
	data.storage_chests = {}
	if player.is_inside_tree():
		var storage_containers = player.get_tree().get_nodes_in_group("storage_containers")
		for container in storage_containers:
			if container.has_method("get_save_data"):
				var chest_data = container.get_save_data()
				data.storage_chests[chest_data.storage_id] = chest_data
	

	
	return data

func apply_player_data(player: Node2D, data: Dictionary):
	"""Apply saved data to player"""
	print("Applying saved player data...")
	
	# Validate data is not empty
	if data.is_empty():
		print("Warning: No data to apply")
		return
	
	# Position
	if data.has("position") and data.position != null:
		if data.position.has("x") and data.position.has("y"):
			player.global_position = Vector2(data.position.x, data.position.y)
	
	# Health
	if data.has("health") and data.has("max_health"):
		player.current_health = data.get("health", 100)
		player.max_health = data.get("max_health", 100)
	
	# Level system
	if player.level_system and data.has("level"):
		player.level_system.current_level = data.get("level", 1)
		player.level_system.current_experience = data.get("experience", 0)
		player.level_system.skill_points = data.get("skill_points", 0)
		
		# Restore stat points - with proper null checking
		if data.has("stats") and data.stats != null and typeof(data.stats) == TYPE_DICTIONARY:
			var stats = data.stats
			player.level_system.points_in_health = stats.get("health", 0)
			player.level_system.points_in_speed = stats.get("speed", 0)
			player.level_system.points_in_damage = stats.get("damage", 0)
			player.level_system.points_in_fire_rate = stats.get("fire_rate", 0)
			player.level_system.points_in_luck = stats.get("luck", 0)
			player.level_system.points_in_crit_chance = stats.get("crit_chance", 0)
			player.level_system.points_in_crit_damage = stats.get("crit_damage", 0)
			
			# Recalculate stats
			player.level_system._initialize_stats()
			player.level_system.max_health = player.level_system.base_max_health + (player.level_system.points_in_health * 10)
			player.level_system.move_speed = player.level_system.base_move_speed + (player.level_system.points_in_speed * 5)
			player.level_system.damage_multiplier = 1.0 + (player.level_system.points_in_damage * 0.05)
			player.level_system.fire_rate_multiplier = 1.0 + (player.level_system.points_in_fire_rate * 0.04)
			player.level_system.luck = 1.0 + (player.level_system.points_in_luck * 0.01)
			player.level_system.critical_chance = player.level_system.points_in_crit_chance * 0.02
			player.level_system.critical_damage = 1.5 + (player.level_system.points_in_crit_damage * 0.1)
			
			# Add this section after level system restoration:
# Restore inventory
	if data.has("inventory") and data.inventory != null:
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			print("Restoring inventory from save...")
			# Clear current inventory
			for i in range(inv_mgr.max_slots):
				inv_mgr.items[i] = null
				inv_mgr.quantities[i] = 0
			
			# Restore saved items
			for i in range(min(data.inventory.size(), inv_mgr.max_slots)):
				var item_data = data.inventory[i]
				if item_data != null and item_data is Dictionary:
					var item = player._create_item_from_name(item_data.name)
					if item:
						inv_mgr.items[i] = item
						inv_mgr.quantities[i] = item_data.quantity
			
			inv_mgr.inventory_changed.emit()
			print("  ✓ Restored inventory")
			
	if data.has("weapons") and data.weapons != null:
		var weapon_manager = player.get_node_or_null("WeaponManager")
		if weapon_manager:
			print("Restoring weapons from save data...")
			print("DEBUG: Weapon data: ", data.weapons)  # ADD THIS
			
			# Restore primary weapon
			if data.weapons.has("primary") and data.weapons.primary != null:
				print("DEBUG: Attempting to create primary weapon: ", data.weapons.primary)  # ADD THIS
				var primary_weapon = _create_weapon_from_name(data.weapons.primary)
				print("DEBUG: Created weapon result: ", primary_weapon)  # ADD THIS
				if primary_weapon:
					weapon_manager.equip_weapon(primary_weapon, 0)
					print("  ✓ Restored primary: ", primary_weapon.name)
				else:
					print("  ✗ Failed to create primary weapon!")  # ADD THIS
	# Restore weapon storage from saved data
	if data.has("weapon_storage") and data.weapon_storage != null:
		GameManager.saved_weapon_storage = data.weapon_storage.duplicate()
		print("Weapon storage data loaded")
		
	if data.has("player_stats") and data.player_stats != null:
		StatsTracker.load_stats_data(data.player_stats)
		print("Player statistics restored")
	
	if data.has("storage_chests") and data.storage_chests != null:
	# Storage will be restored when safehouse scene loads
	# Store it temporarily so safehouse can access it
		GameManager.pending_storage_data = data.storage_chests
	print("Storage chest data queued for restoration")
	
	print("Player data applied successfully")
	
	#helper code for restoring weapons
func _create_weapon_from_name(weapon_name: String) -> WeaponItem:
	"""Create a weapon item from its name"""
	match weapon_name:
		"Pistol":
			return WeaponFactory.create_pistol()
			print("DEBUG: Creating pistol...") 
		"Shotgun":
			return WeaponFactory.create_shotgun()
		"Assault Rifle":
			return WeaponFactory.create_rifle()
		"Sniper Rifle":
			return WeaponFactory.create_sniper()
		"Machine Gun":
			return WeaponFactory.create_machine_gun()
		"Burst Rifle":
			return WeaponFactory.create_burst_rifle()
		_:
			print("Unknown weapon name: ", weapon_name)
			return null
