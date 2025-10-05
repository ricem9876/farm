extends Node2D

@onready var weapon_storage_ui = %WeaponStorageUI
@onready var weapon_chest = %WeaponChest
@onready var farm_exit = $FarmExit

var pause_menu_scene = preload("res://Resources/UI/PauseMenu.tscn")
var player: Node2D
var weapon_storage: WeaponStorageManager
var level_select_scene = preload("res://Resources/UI/LevelSelectUI.tscn")

func _ready():
	print("\n=== SAFEHOUSE SETUP START ===")
	AudioManager.play_music(AudioManager.safehouse_music)
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("player")
	
	if not player:
		print("ERROR: Player not found!")
		return
	
	print("✓ Player found at position: ", player.global_position)
	
	# Wait for player's _ready() to complete
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
	weapon_storage.storage_changed.connect(_on_weapon_storage_changed)
	
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
	
	# Connect to weapon manager signals to auto-disable guns when equipped
	if player_weapon_manager:
		if player_weapon_manager.has_signal("weapon_equipped"):
			player_weapon_manager.weapon_equipped.connect(_on_weapon_equipped_in_safehouse)
			print("✓ Connected to weapon_equipped signal")
		else:
			print("⚠ Warning: weapon_manager doesn't have weapon_equipped signal")
	else:
		print("⚠ Warning: No weapon manager found")
	
	# Restore player state from save file (if loading from save)
	await get_tree().process_frame
	_restore_player_state()
	
	# Wait another frame for weapons to be restored and instantiated
	await get_tree().process_frame
	
	# NOW disable the gun
	_disable_gun_in_safehouse()
	
	# Restore weapon storage after creating it
	if weapon_storage:
		GameManager.restore_weapon_storage(weapon_storage)
	
	# Restore item storage chest from save file
	var storage_chest = get_node_or_null("StorageChest")
	if storage_chest and storage_chest.has_method("load_from_save_data"):
		if GameManager.pending_storage_data.has("safehouse_chest"):
			var chest_data = GameManager.pending_storage_data["safehouse_chest"]
			storage_chest.load_from_save_data(chest_data)
			GameManager.pending_storage_data.erase("safehouse_chest")
			print("✓ Item storage chest restored from save file")
		
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	print("✓ Pause menu added")
	print("=== SAFEHOUSE SETUP COMPLETE ===\n")

func _restore_player_state():
	"""Restore player state when entering safehouse"""
	print("Checking for saved player state...")
	
	# Check if we're loading from a save file
	if not GameManager.pending_load_data.is_empty():
		print("Loading from save file...")
		SaveSystem.apply_player_data(player, GameManager.pending_load_data.get("player", {}))
		GameManager.pending_load_data = {}
		player.refresh_hud()
		return
	
	# Otherwise this is just a scene transition - data already loaded via auto-save
	print("Scene transition - player data already current")
	player.refresh_hud()

func _on_weapon_equipped_in_safehouse(slot: int, weapon_item: WeaponItem):
	"""Called whenever a weapon is equipped - disable it immediately if in safehouse"""
	print("Weapon equipped in safehouse - disabling it!")
	await get_tree().process_frame
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
		
func _on_weapon_storage_changed():
	"""Update GameManager whenever weapon storage changes"""
	if weapon_storage:
		GameManager.save_weapon_storage(weapon_storage)
		
func _exit_tree():
	pass
	# Auto-save when leaving safehouse
