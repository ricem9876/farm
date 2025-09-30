extends Node2D

@onready var weapon_storage_ui = %WeaponStorageUI
@onready var weapon_chest = %WeaponChest
@onready var farm_exit = $FarmExit
var player: Node2D
var weapon_storage: WeaponStorageManager

func _ready():
	print("\n=== SAFEHOUSE SETUP START ===")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("player")
	
	if not player:
		print("ERROR: Player not found!")
		return
	
	print("✓ Player found at position: ", player.global_position)
	
	# Make sure player is in the player group
	if not player.is_in_group("player"):
		player.add_to_group("player")
		print("✓ Added player to 'player' group")
	else:
		print("✓ Player already in 'player' group")
	
	# Setup farm exit interaction
	if farm_exit:
		print("✓ FarmExit found")
		if not farm_exit.is_in_group("interaction_areas"):
			farm_exit.add_to_group("interaction_areas")
		farm_exit.interaction_type = "farm_exit"
		print("  - Interaction type set to: ", farm_exit.interaction_type)
	else:
		print("ERROR: FarmExit not found!")
	
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
	
	# Setup UI - this will auto-populate with weapons
	weapon_storage_ui.setup_storage(
		weapon_storage,
		player.get_weapon_manager(),
		player
	)
	print("✓ WeaponStorageUI setup complete (auto-populated with weapons)")
	
	# Connect chest
	weapon_chest.set_storage_ui(weapon_storage_ui)
	print("✓ WeaponChest connected")
	
	# Restore player state from GameManager
	await get_tree().process_frame
	_restore_player_state()
	
	# Wait another frame for weapons to be restored and instantiated
	await get_tree().process_frame
	
	# NOW disable the gun
	_disable_gun_in_safehouse()
	
	print("=== SAFEHOUSE SETUP COMPLETE ===")
	print("Storage has ", weapon_storage.get_weapon_count(), " weapons\n")

func _restore_player_state():
	"""Restore player state when entering safehouse"""
	print("Checking for saved player state...")
	
	# Restore inventory
	if player.has_method("get_inventory_manager"):
		GameManager.restore_player_inventory(player.get_inventory_manager())
	
	# Restore weapons
	if player.has_method("get_weapon_manager"):
		GameManager.restore_player_weapons(player.get_weapon_manager())

func _disable_gun_in_safehouse():
	print("\n=== DISABLING GUN IN SAFEHOUSE ===")
	print("Attempting to disable gun in safehouse...")
	
	if not player:
		print("✗ No player reference")
		return
	
	print("✓ Player exists")
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("✗ No weapon manager")
		return
	
	print("✓ Weapon manager exists")
	
	var gun = weapon_manager.get_active_gun()
	print("Active gun: ", gun)
	
	if gun:
		print("BEFORE - can_fire: ", gun.can_fire, " visible: ", gun.visible, " process_mode: ", gun.process_mode)
		
		gun.set_can_fire(false)
		gun.visible = false
		gun.process_mode = Node.PROCESS_MODE_DISABLED  # Completely disable processing
		
		print("AFTER - can_fire: ", gun.can_fire, " visible: ", gun.visible, " process_mode: ", gun.process_mode)
		print("✓ Gun disabled, hidden, and processing stopped in safehouse")
	else:
		print("✗ No active gun found (this is OK if player has no weapon)")
	
	print("===================================\n")
