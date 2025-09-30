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
	
	# Connect to weapon manager signals to auto-disable guns when equipped
	if player.has_method("get_weapon_manager"):
		var weapon_mgr = player.get_weapon_manager()
		weapon_mgr.weapon_equipped.connect(_on_weapon_equipped_in_safehouse)
	
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

func _on_weapon_equipped_in_safehouse(slot: int, weapon_item: WeaponItem):
	"""Called whenever a weapon is equipped - disable it immediately if in safehouse"""
	print("Weapon equipped in safehouse - disabling it!")
	await get_tree().process_frame  # Wait for gun to be instantiated
	_disable_all_guns()

func _disable_gun_in_safehouse():
	print("\n=== DISABLING GUN IN SAFEHOUSE ===")
	_disable_all_guns()
	print("===================================\n")

func _disable_all_guns():
	"""Disable ALL guns (both primary and secondary)"""
	if not player:
		print("✗ No player reference")
		return
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("✗ No weapon manager")
		return
	
	# Disable primary gun
	var primary_gun = weapon_manager.primary_gun
	if primary_gun:
		print("Disabling PRIMARY gun")
		primary_gun.set_can_fire(false)
		primary_gun.visible = false
		primary_gun.process_mode = Node.PROCESS_MODE_DISABLED
		print("✓ Primary gun disabled")
	
	# Disable secondary gun
	var secondary_gun = weapon_manager.secondary_gun
	if secondary_gun:
		print("Disabling SECONDARY gun")
		secondary_gun.set_can_fire(false)
		secondary_gun.visible = false
		secondary_gun.process_mode = Node.PROCESS_MODE_DISABLED
		print("✓ Secondary gun disabled")
	
	if not primary_gun and not secondary_gun:
		print("✗ No guns found (this is OK if player has no weapons)")
