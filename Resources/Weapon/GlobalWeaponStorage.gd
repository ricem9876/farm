# GlobalWeaponStorage.gd
extends Node

var weapon_storage: WeaponStorageManager

func _ready():
	weapon_storage = WeaponStorageManager.new()
	add_child(weapon_storage)
	print("Global weapon storage initialized")

func get_storage() -> WeaponStorageManager:
	return weapon_storage
