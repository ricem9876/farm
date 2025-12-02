extends Node
class_name WeaponStorageManager

signal storage_changed
signal weapon_added(weapon: WeaponItem)
signal weapon_removed(weapon: WeaponItem)

var max_slots: int = 12  # Fixed at 12 slots for export compatibility
var weapons: Array[WeaponItem] = []

func _ready():
	if weapons.is_empty():
		weapons.resize(max_slots)
		print("WeaponStorageManager initialized with ", max_slots, " slots")

func add_weapon(weapon: WeaponItem) -> bool:
	if not weapon or weapon.item_type != "weapon":
		print("Can only store weapons in weapon storage")
		return false
	
	# Find first empty slot
	for i in range(max_slots):
		if weapons[i] == null:
			weapons[i] = weapon
			weapon_added.emit(weapon)
			storage_changed.emit()
			print("Added weapon to storage: ", weapon.name)
			return true
	
	print("Weapon storage is full!")
	return false

func remove_weapon(slot_index: int) -> WeaponItem:
	if slot_index < 0 or slot_index >= max_slots:
		return null
	
	var weapon = weapons[slot_index]
	if weapon:
		weapons[slot_index] = null
		weapon_removed.emit(weapon)
		storage_changed.emit()
		print("Removed weapon from storage: ", weapon.name)
	
	return weapon

func get_weapon(slot_index: int) -> WeaponItem:
	if slot_index < 0 or slot_index >= max_slots:
		return null
	return weapons[slot_index]

func is_storage_full() -> bool:
	for i in range(max_slots):
		if weapons[i] == null:
			return false
	return true

func get_weapon_count() -> int:
	var count = 0
	for weapon in weapons:
		if weapon:
			count += 1
	return count
