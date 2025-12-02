# GlobalWeaponStorage.gd
extends Node

var weapon_storage: WeaponStorageManager
var unlocked_weapons: Array[String] = []  # CRITICAL: Store unlocked weapons globally
var _initialized: bool = false

func _ready():
	_initialize()

func _initialize():
	if _initialized:
		return
		
	weapon_storage = WeaponStorageManager.new()
	add_child(weapon_storage)
	
	# Initialize with default pistol if array is empty
	if unlocked_weapons.is_empty():
		unlocked_weapons.append("Handheld Harvester")
		print("Initialized with default weapon: Handheld Harvester")
	
	_initialized = true
	print("Global weapon storage initialized - Unlocked weapons: ", unlocked_weapons)

func get_storage() -> WeaponStorageManager:
	return weapon_storage

# CRITICAL: Persist unlocked weapons across scenes
func get_unlocked_weapons() -> Array[String]:
	return unlocked_weapons

func set_unlocked_weapons(weapons: Array):
	unlocked_weapons.clear()
	for weapon_name in weapons:
		if weapon_name is String:
			unlocked_weapons.append(weapon_name)
	print("GlobalWeaponStorage: Set unlocked weapons to: ", unlocked_weapons)

func unlock_weapon(weapon_name: String):
	if weapon_name not in unlocked_weapons:
		unlocked_weapons.append(weapon_name)
		print("GlobalWeaponStorage: Unlocked ", weapon_name)
