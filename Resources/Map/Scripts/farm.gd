extends Node2D

@onready var inventory_ui = $InventoryUI
@onready var weapon_storage_ui = $WeaponStorageUI
@onready var player = $player
@onready var camera = $player/Camera2D
@onready var weapon_chest = $WeaponChest

var weapon_storage: WeaponStorageManager

func _ready():
	print("=== FARM SETUP START ===")
	
	if player:
		# Setup inventory
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		if inventory_ui:
			inventory_ui.setup_inventory(player.get_inventory_manager(), camera, player)
		
		# Setup weapon storage
		weapon_storage = WeaponStorageManager.new()
		add_child(weapon_storage)
		
		if weapon_storage_ui:
			weapon_storage_ui.setup_storage(
				weapon_storage,
				player.get_weapon_manager(),
				player
			)
		
		# Connect weapon chest to UI
		if weapon_chest:
			weapon_chest.set_storage_ui(weapon_storage_ui)
		
		# Add test weapons
		_add_test_weapons()
	
	print("=== FARM SETUP COMPLETE ===")

func _add_test_weapons():
	if not weapon_storage:
		return
	
	var pistol = WeaponItem.new()
	pistol.name = "Test Pistol"
	pistol.description = "Backup weapon"
	pistol.weapon_type = "Pistol"
	pistol.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	pistol.weapon_sprite = preload("res://Resources/Weapon/assaultrifle.png")
	pistol.icon = preload("res://Resources/Weapon/assaultrifle.png")
	pistol.base_damage = 15.0
	pistol.base_fire_rate = 3.0
	pistol.base_bullet_count = 1
	pistol.base_accuracy = 0.95
	pistol.base_bullet_speed = 500.0
	weapon_storage.add_weapon(pistol)
	
	var shotgun = WeaponItem.new()
	shotgun.name = "Test Shotgun"
	shotgun.description = "Close range power"
	shotgun.weapon_type = "Shotgun"
	shotgun.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	shotgun.weapon_sprite = preload("res://Resources/Weapon/assaultrifle.png")
	shotgun.icon = preload("res://Resources/Weapon/assaultrifle.png")
	shotgun.base_damage = 8.0
	shotgun.base_fire_rate = 1.0
	shotgun.base_bullet_count = 6
	shotgun.base_accuracy = 0.6
	shotgun.base_bullet_speed = 350.0
	weapon_storage.add_weapon(shotgun)
	
	print("Added test weapons to storage")

func _on_inventory_toggle_requested():
	inventory_ui.toggle_visibility()
