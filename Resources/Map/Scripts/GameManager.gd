# GameManager.gd - Minimal version, SaveSystem is the source of truth
extends Node

var current_level_settings: Dictionary = {}
var current_scene_type: String = "farm"

# ONLY for temporary data during scene transitions
var pending_load_data: Dictionary = {}
var pending_storage_data: Dictionary = {}
var current_save_slot: int = -1

# Weapon storage (the chest in safehouse, NOT equipped weapons)
var saved_weapon_storage: Array = []

# Scene paths
const FARM_SCENE = "res://Resources/Scenes/farm.tscn"
const SAFEHOUSE_SCENE = "res://Resources/Scenes/safehouse.tscn"

func _ready():
	print("GameManager initialized")

# ========== WEAPON STORAGE (CHEST ONLY) ==========

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

# ========== SCENE TRANSITIONS ==========

func change_to_safehouse():
	"""Change to safehouse scene"""
	print("\n=== CHANGING TO SAFEHOUSE ===")
	current_scene_type = "safehouse"
	
	# Auto-save before transition
	var player = get_tree().get_first_node_in_group("player")
	if player and current_save_slot >= 0:
		print("Auto-saving before scene change...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(current_save_slot, player_data)
	
	print("Loading safehouse scene...")
	var error = get_tree().change_scene_to_file(SAFEHOUSE_SCENE)
	if error != OK:
		print("ERROR: Failed to change scene! Error code: ", error)

func change_to_farm():
	"""Change to farm scene"""
	print("\n=== CHANGING TO FARM ===")
	current_scene_type = "farm"
	
	# Auto-save before transition
	var player = get_tree().get_first_node_in_group("player")
	if player and current_save_slot >= 0:
		print("Auto-saving before scene change...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(current_save_slot, player_data)
	
	print("Loading farm scene...")
	var error = get_tree().change_scene_to_file(FARM_SCENE)
	if error != OK:
		print("ERROR: Failed to change scene! Error code: ", error)

func get_current_scene_type() -> String:
	return current_scene_type
