# GlobalWeaponStorage.gd
extends Node

var weapon_storage: WeaponStorageManager
var unlocked_weapons: Array[String] = ["Pistol"]  # CRITICAL: Store unlocked weapons globally

func _ready():
	weapon_storage = WeaponStorageManager.new()
	add_child(weapon_storage)
	print("Global weapon storage initialized")

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
