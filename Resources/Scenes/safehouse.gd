extends Node2D

@onready var weapon_storage_ui = %WeaponStorageUI
@onready var weapon_chest = %WeaponChest
@onready var weapon_hud = $CanvasLayer/WeaponHUD
@onready var farm_exit = $FarmExit

var pause_menu_scene = preload("res://Resources/UI/PauseMenu.tscn")
var player: Node2D
var weapon_storage: WeaponStorageManager
var level_select_scene = preload("res://Resources/UI/LevelSelectUI.tscn")


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
	
		# IMPORTANT: Wait for player's _ready() to complete
	await get_tree().process_frame
	await get_tree().process_frame
	# Make sure player is in the player group
	if not player.is_in_group("player"):
		player.add_to_group("player")
		print("✓ Added player to 'player' group")
	else:
		print("✓ Player already in 'player' group")
	
	# Setup farm exit interaction
	var level_select = level_select_scene.instantiate()
	add_child(level_select)

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
	
	# Get player's weapon manager
	var player_weapon_manager = player.get_weapon_manager()
	
	# Setup UI - this will auto-populate with weapons
	if player_weapon_manager:
		weapon_storage_ui.setup_storage(
			weapon_storage,
			player_weapon_manager,
			player
		)
		print("✓ WeaponStorageUI setup complete (auto-populated with weapons)")
	else:
		print("⚠ Warning: Player has no weapon manager, storage UI may not work correctly")
	
	# Connect chest
	weapon_chest.set_storage_ui(weapon_storage_ui)
	print("✓ WeaponChest connected")
	
	# Setup weapon HUD
	if weapon_hud:
		print("✓ WeaponHUD found")
		if player_weapon_manager:
			weapon_hud.setup_hud(player_weapon_manager, player)
			print("  - Weapon HUD setup complete")
		else:
			print("  ⚠ No weapon manager - hiding WeaponHUD")
			weapon_hud.visible = false
	else:
		print("ERROR: WeaponHUD not found!")
	
	# Connect to weapon manager signals to auto-disable guns when equipped
	if player_weapon_manager:
		if player_weapon_manager.has_signal("weapon_equipped"):
			player_weapon_manager.weapon_equipped.connect(_on_weapon_equipped_in_safehouse)
			print("✓ Connected to weapon_equipped signal")
		else:
			print("⚠ Warning: weapon_manager doesn't have weapon_equipped signal")
	else:
		print("⚠ Warning: No weapon manager found")
	
	# Restore player state from GameManager
	await get_tree().process_frame
	_restore_player_state()
	
	# Wait another frame for weapons to be restored and instantiated
	await get_tree().process_frame
	
	# NOW disable the gun
	_disable_gun_in_safehouse()
	
	# Restore weapon storage after creating it
	if weapon_storage:
		GameManager.restore_weapon_storage(weapon_storage)
		
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	


	print("✓ Pause menu added")
	print("=== SAFEHOUSE SETUP COMPLETE ===")
	print("Storage has ", weapon_storage.get_weapon_count(), " weapons\n")

func _restore_player_state():
	"""Restore player state when entering safehouse"""
	print("Checking for saved player state...")
	
	# Restore inventory
	if player.has_method("get_inventory_manager"):
		var inv_manager = player.get_inventory_manager()
		if inv_manager:
			GameManager.restore_player_inventory(inv_manager)
		else:
			print("  ⚠ No inventory manager to restore")
	
	# Restore weapons
	if player.has_method("get_weapon_manager"):
		var weap_manager = player.get_weapon_manager()
		if weap_manager:
			GameManager.restore_player_weapons(weap_manager)
		else:
			print("  ⚠ No weapon manager to restore")
	
	# Restore level system
	if player.level_system:
		GameManager.restore_player_level_system(player.level_system)
		print("✓ Level system restored: Level ", player.level_system.current_level)
	else:
		print("  ⚠ No level system to restore")
		
	player.refresh_hud()
func _on_weapon_equipped_in_safehouse(slot: int, weapon_item: WeaponItem):
	"""Called whenever a weapon is equipped - disable it immediately if in safehouse"""
	print("Weapon equipped in safehouse - disabling it!")
	await get_tree().process_frame  # Wait for gun to be instantiated
	_disable_all_guns()

func _disable_gun_in_safehouse():
	print("Setting location state to Safehouse...")
	
	if player and player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		loc_state.change_state("SafehouseState")
	else:
		print("✗ No LocationStateMachine found on player")

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

func _exit_tree():
	if weapon_storage:
		GameManager.save_weapon_storage(weapon_storage)
	
	# Save player data
	if GameManager.current_save_slot >= 0 and player:
		print("Auto-saving to slot ", GameManager.current_save_slot)
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
