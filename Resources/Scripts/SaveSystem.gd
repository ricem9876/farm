# SaveSystem.gd - UPDATED WITH WEAPON UNLOCKS & UPGRADES
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
		"unlocked_weapons": ["Pistol"],  # NEW: Save unlocked weapons
		"weapon_upgrades": {},  # NEW: Save weapon upgrades
		"storage_chests": {},
		"current_scene": "farm",
		"player_stats": {},
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
						"quantity": int(inv_mgr.quantities[i])
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
	
	# NEW: Save unlocked weapons from GlobalWeaponStorage
	if GlobalWeaponStorage:
		data.unlocked_weapons = GlobalWeaponStorage.get_unlocked_weapons()
		print("  ✓ Saved ", data.unlocked_weapons.size(), " unlocked weapons")
	
	# NEW: Save weapon upgrades
	if WeaponUpgradeManager:
		data.weapon_upgrades = WeaponUpgradeManager.get_save_data()
		print("  ✓ Saved weapon upgrades")
	
	# Tutorial data
	if TutorialManager:
		data.tutorial = TutorialManager.get_save_data()
		print("  ✓ Saved tutorial data")
	
	# Storage chests (item storage)
	if player.is_inside_tree():
		var storage_containers = player.get_tree().get_nodes_in_group("storage_containers")
		
		if storage_containers.size() > 0:
			for container in storage_containers:
				if container.has_method("get_save_data"):
					var chest_data = container.get_save_data()
					data.storage_chests[chest_data.storage_id] = chest_data
		else:
			if GameManager.current_save_slot >= 0:
				var existing_save = get_save_data(GameManager.current_save_slot)
				if existing_save.has("player") and existing_save.player.has("storage_chests"):
					data.storage_chests = existing_save.player.storage_chests

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
			for i in range(inv_mgr.max_slots):
				inv_mgr.items[i] = null
				inv_mgr.quantities[i] = 0
			
			for i in range(min(data.inventory.size(), inv_mgr.max_slots)):
				var item_data = data.inventory[i]
				if item_data != null and item_data is Dictionary:
					var item = player._create_item_from_name(item_data.name)
					if item:
						inv_mgr.items[i] = item
						inv_mgr.quantities[i] = int(item_data.get("quantity", 1))
			
			inv_mgr.inventory_changed.emit()
	
	# Equipped weapons - ONLY restore WeaponItem slots, NOT Gun nodes
	# Gun nodes will be created later by instantiate_weapons_from_save()
	if data.has("weapons") and data.weapons != null:
		print("DEBUG: Looking for WeaponManager...")
		# Use the getter method instead of get_node_or_null
		var weapon_manager = player.get_weapon_manager() if player.has_method("get_weapon_manager") else player.get_node_or_null("WeaponManager")
		print("DEBUG: WeaponManager found: ", weapon_manager)
		if weapon_manager:
			print("DEBUG: WeaponManager current slots - Primary: ", weapon_manager.primary_slot, " Secondary: ", weapon_manager.secondary_slot)
			if data.weapons.has("primary") and data.weapons.primary != null:
				print("DEBUG: Creating primary weapon from name: ", data.weapons.primary)
				var primary_weapon = _create_weapon_from_name(data.weapons.primary)
				print("DEBUG: Created primary weapon: ", primary_weapon)
				if primary_weapon:
					weapon_manager.primary_slot = primary_weapon
					print("  ✓ Restored primary weapon slot: ", primary_weapon.name)
					print("DEBUG: Verified primary_slot after assignment: ", weapon_manager.primary_slot)
			
			if data.weapons.has("secondary") and data.weapons.secondary != null:
				var secondary_weapon = _create_weapon_from_name(data.weapons.secondary)
				if secondary_weapon:
					weapon_manager.secondary_slot = secondary_weapon
					print("  ✓ Restored secondary weapon slot: ", secondary_weapon.name)
			
			if data.weapons.has("active_slot"):
				weapon_manager.active_slot = data.weapons.active_slot
				print("  ✓ Restored active slot: ", data.weapons.active_slot)
				
			print("DEBUG: Final weapon_manager state - Primary: ", weapon_manager.primary_slot, " Secondary: ", weapon_manager.secondary_slot)
		else:
			print("ERROR: WeaponManager not found!")
	
	# Weapon storage
	if data.has("weapon_storage") and data.weapon_storage != null:
		GameManager.pending_load_data["weapon_storage"] = data.weapon_storage
	
	# NEW: Restore unlocked weapons to GlobalWeaponStorage
	if data.has("unlocked_weapons") and data.unlocked_weapons != null:
		if GlobalWeaponStorage:
			GlobalWeaponStorage.set_unlocked_weapons(data.unlocked_weapons)
			print("  ✓ Restored ", data.unlocked_weapons.size(), " unlocked weapons to GlobalWeaponStorage")
		GameManager.pending_load_data["unlocked_weapons"] = data.unlocked_weapons
		print("  ✓ Prepared ", data.unlocked_weapons.size(), " unlocked weapons for restoration")
	
	# NEW: Restore weapon upgrades
	if data.has("weapon_upgrades") and data.weapon_upgrades != null:
		if WeaponUpgradeManager:
			WeaponUpgradeManager.load_save_data(data.weapon_upgrades)
			print("  ✓ Weapon upgrades restored")
	
	# Storage chests
	if data.has("storage_chests") and data.storage_chests != null:
		GameManager.pending_load_data["storage_chests"] = data.storage_chests
	
	# Tutorial data
	if data.has("tutorial") and data.tutorial != null:
		if TutorialManager:
			TutorialManager.load_save_data(data.tutorial)
			print("  ✓ Tutorial data restored")
	
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
