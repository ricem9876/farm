# SaveSystem.gd
# The ONLY source of truth for all persistent player data
extends Node

const SAVE_DIR = "user://saves/"
const MAX_SAVES = 3

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_deleted(slot: int)

func _ready():
	_ensure_save_directory()

func _ensure_save_directory():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

func get_save_file_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + ".json"

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_file_path(slot))

func get_save_data(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}
	
	var file = FileAccess.open(get_save_file_path(slot), FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return json.data
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
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("Game saved successfully to slot ", slot)
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	print("\n=== LOADING GAME FROM SLOT ", slot, " ===")
	
	var save_data = get_save_data(slot)
	if not save_data.is_empty():
		load_completed.emit(slot)
		print("Game loaded successfully from slot ", slot)
	
	return save_data

func delete_save(slot: int) -> bool:
	if not save_exists(slot):
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		return false
	
	var error = dir.remove("save_" + str(slot) + ".json")
	if error == OK:
		save_deleted.emit(slot)
		return true
	return false

func get_all_saves() -> Array:
	var saves = []
	for i in range(MAX_SAVES):
		saves.append(get_save_data(i) if save_exists(i) else {})
	return saves

# ========== COLLECT ALL PLAYER DATA FOR SAVING ==========
func collect_player_data(player: Node2D) -> Dictionary:
	"""Collect ALL player data - this is called right before scene transitions"""
	
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
		"weapon_storage": [],
		"storage_chests": {},
		"current_scene": "farm",
		"player_stats": {}
	}
	
	# Detect current scene
	if player.is_inside_tree():
		var scene_path = player.get_tree().current_scene.scene_file_path
		if "safehouse" in scene_path.to_lower():
			data.current_scene = "safehouse"
		elif "farm" in scene_path.to_lower():
			data.current_scene = "farm"
	
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
			for i in range(inv_mgr.items.size()):
				var item = inv_mgr.items[i]
				if item:
					inv_data.append({
						"name": item.name,
						"quantity": int(inv_mgr.quantities[i])  # FIX: Force int
					})
				else:
					inv_data.append(null)
			data.inventory = inv_data

	
	# Equipped weapons
	if player.has_method("get_weapon_manager"):
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr:
			data.weapons = {
				"primary": weapon_mgr.primary_slot.name if weapon_mgr.primary_slot else null,
				"secondary": weapon_mgr.secondary_slot.name if weapon_mgr.secondary_slot else null,
				"active_slot": weapon_mgr.active_slot
			}
	
	# Weapon storage (the chest in safehouse)
	var weapon_storage = player.get_tree().get_first_node_in_group("weapon_storage")
	if weapon_storage and weapon_storage.has_method("get_weapons"):
		for weapon in weapon_storage.get_weapons():
			if weapon:
				data.weapon_storage.append({
					"name": weapon.name,
					"type": weapon.weapon_type
				})
			else:
				data.weapon_storage.append({})
	
	# Storage chests (item storage)
	if player.is_inside_tree():
		var storage_containers = player.get_tree().get_nodes_in_group("storage_containers")
		print("DEBUG: Found ", storage_containers.size(), " storage containers")
		
		# CRITICAL FIX: Only update storage_chests if we found containers
		# Otherwise, preserve existing data from previous saves
		if storage_containers.size() > 0:
			# We're in a scene with storage - save current state
			for container in storage_containers:
				print("DEBUG: Container: ", container.name)
				if container.has_method("get_save_data"):
					var chest_data = container.get_save_data()
					print("DEBUG: Chest data: ", chest_data)
					data.storage_chests[chest_data.storage_id] = chest_data
				else:
					print("DEBUG: Container missing get_save_data method")
		else:
			# We're in a scene without storage (e.g., farm)
			# Load existing storage data from the current save file to preserve it
			if GameManager.current_save_slot >= 0:
				var existing_save = get_save_data(GameManager.current_save_slot)
				if existing_save.has("player") and existing_save.player.has("storage_chests"):
					data.storage_chests = existing_save.player.storage_chests
					print("DEBUG: Preserved existing storage data from save file")
	# Stats tracking
	data.player_stats = StatsTracker.get_stats_data()
	
	return data

# ========== RESTORE ALL PLAYER DATA FROM SAVE ==========
func apply_player_data(player: Node2D, data: Dictionary):
	"""Apply saved data to player - called when loading a save file"""
	
	if data.is_empty():
		print("Warning: No data to apply")
		return
	
	print("Restoring player from save file...")
	
	# Position
	if data.has("position") and data.position != null:
		player.global_position = Vector2(data.position.x, data.position.y)
	
	# Health
	if data.has("health"):
		player.current_health = data.get("health", 100)
		player.max_health = data.get("max_health", 100)
	
	# Level system
	if player.level_system and data.has("level"):
		player.level_system.current_level = data.get("level", 1)
		player.level_system.current_experience = data.get("experience", 0)
		player.level_system.skill_points = data.get("skill_points", 0)
		
		if data.has("stats") and data.stats != null:
			var stats = data.stats
			player.level_system.points_in_health = stats.get("health", 0)
			player.level_system.points_in_speed = stats.get("speed", 0)
			player.level_system.points_in_damage = stats.get("damage", 0)
			player.level_system.points_in_fire_rate = stats.get("fire_rate", 0)
			player.level_system.points_in_luck = stats.get("luck", 0)
			player.level_system.points_in_crit_chance = stats.get("crit_chance", 0)
			player.level_system.points_in_crit_damage = stats.get("crit_damage", 0)
			
			# Recalculate all stats
			player.level_system._initialize_stats()
			player.level_system.max_health = player.level_system.base_max_health + (player.level_system.points_in_health * 10)
			player.level_system.move_speed = player.level_system.base_move_speed + (player.level_system.points_in_speed * 5)
			player.level_system.damage_multiplier = 1.0 + (player.level_system.points_in_damage * 0.05)
			player.level_system.fire_rate_multiplier = 1.0 + (player.level_system.points_in_fire_rate * 0.04)
			player.level_system.luck = 1.0 + (player.level_system.points_in_luck * 0.01)
			player.level_system.critical_chance = player.level_system.points_in_crit_chance * 0.02
			player.level_system.critical_damage = 1.5 + (player.level_system.points_in_crit_damage * 0.1)
	
	# Inventory
	if data.has("inventory") and data.inventory != null:
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
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
						# CRITICAL FIX: Ensure quantity is an integer
						inv_mgr.quantities[i] = int(item_data.get("quantity", 1))
			
			inv_mgr.inventory_changed.emit()
	
	# Equipped weapons
	if data.has("weapons") and data.weapons != null:
		var weapon_manager = player.get_node_or_null("WeaponManager")
		if weapon_manager:
			# Restore primary weapon
			if data.weapons.has("primary") and data.weapons.primary != null:
				var primary_weapon = _create_weapon_from_name(data.weapons.primary)
				if primary_weapon:
					weapon_manager.equip_weapon(primary_weapon, 0)
					print("  ✓ Restored primary weapon: ", primary_weapon.name)
			
			# Restore secondary weapon
			if data.weapons.has("secondary") and data.weapons.secondary != null:
				var secondary_weapon = _create_weapon_from_name(data.weapons.secondary)
				if secondary_weapon:
					weapon_manager.equip_weapon(secondary_weapon, 1)
					print("  ✓ Restored secondary weapon: ", secondary_weapon.name)
			
			# Restore active slot
			if data.weapons.has("active_slot"):
				weapon_manager.active_slot = data.weapons.active_slot
	
	# Weapon storage (store in temporary holder for safehouse to restore)
	if data.has("weapon_storage") and data.weapon_storage != null:
		# Store temporarily so safehouse can restore the weapon chest
		GameManager.pending_load_data["weapon_storage"] = data.weapon_storage
	
	# Storage chests
	if data.has("storage_chests") and data.storage_chests != null:
		# Store temporarily so scenes can restore their chests
		GameManager.pending_load_data["storage_chests"] = data.storage_chests
	
	# Stats tracking
	if data.has("player_stats") and data.player_stats != null:
		StatsTracker.load_stats_data(data.player_stats)
		print("  ✓ Statistics restored")
	
	print("Player data fully restored from save file")

# Helper to create weapon from name
func _create_weapon_from_name(weapon_name: String) -> WeaponItem:
	match weapon_name:
		"Pistol":
			return WeaponFactory.create_pistol()
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
			print("Unknown weapon: ", weapon_name)
			return null
