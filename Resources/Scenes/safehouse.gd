extends Node2D

@onready var weapon_storage_ui = %WeaponStorageUI  # % finds it anywhere!
@onready var weapon_chest = %WeaponChest
var player: Node2D
var weapon_storage: WeaponStorageManager

func _ready():
	print("=== SAFEHOUSE SETUP START ===")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("player")
	
	if not player:
		print("ERROR: Player not found!")
		return
	
	print("✓ Player found")
	
	# Check if nodes were found
	if not weapon_storage_ui:
		print("ERROR: WeaponStorageUI not found! Did you mark it as unique name?")
		return
	print("✓ WeaponStorageUI found")
	
	if not weapon_chest:
		print("ERROR: WeaponChest not found! Did you mark it as unique name?")
		return
	print("✓ WeaponChest found")
	
	# Create weapon storage
	weapon_storage = WeaponStorageManager.new()
	add_child(weapon_storage)
	print("✓ WeaponStorageManager created")
	
	# Setup UI
	weapon_storage_ui.setup_storage(
		weapon_storage,
		player.get_weapon_manager(),
		player
	)
	print("✓ WeaponStorageUI setup complete")
	
	# Connect chest
	weapon_chest.set_storage_ui(weapon_storage_ui)
	print("✓ WeaponChest connected")
	
	# Add test weapons
	_add_starter_weapons()
	
	print("=== SAFEHOUSE SETUP COMPLETE ===")

func _add_starter_weapons():
	if not weapon_storage:
		return
	
	# Pistol
	var pistol = WeaponItem.new()
	pistol.name = "Spare Pistol"
	pistol.weapon_type = "Pistol"
	pistol.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	pistol.weapon_sprite = preload("res://Resources/Weapon/assaultrifle.png")
	pistol.icon = preload("res://Resources/Weapon/assaultrifle.png")
	pistol.base_damage = 15.0
	pistol.base_fire_rate = 3.0
	pistol.base_bullet_count = 1
	weapon_storage.add_weapon(pistol)
	
	# Shotgun
	var shotgun = WeaponItem.new()
	shotgun.name = "Combat Shotgun"
	shotgun.weapon_type = "Shotgun"
	shotgun.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	shotgun.weapon_sprite = preload("res://Resources/Weapon/assaultrifle.png")
	shotgun.icon = preload("res://Resources/Weapon/assaultrifle.png")
	shotgun.base_damage = 8.0
	shotgun.base_fire_rate = 1.0
	shotgun.base_bullet_count = 6
	weapon_storage.add_weapon(shotgun)
	
	print("✓ Added starter weapons")
