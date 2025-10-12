# safehouse.gd
# Clean version - loads from save file when needed, no scattered save/restore calls
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
	
	# CRITICAL FIX: Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Find player - try multiple methods
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Fallback: look for player by name
		player = get_node_or_null("player")
	
	if not player:
		# Last resort: search all nodes
		for node in get_tree().get_nodes_in_group("player"):
			if node is CharacterBody2D:
				player = node
				break
	
	if not player:
		print("ERROR: Player not found!")
		print("DEBUG: Available groups: ", get_tree().get_nodes_in_group("player"))
		return
	
	print("✓ Player found: ", player.name)
	
	# Wait for player's _ready() to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Ensure player is in correct group
	if not player.is_in_group("player"):
		player.add_to_group("player")
	
	# CRITICAL: For new games, ensure no weapons are equipped
	if GameManager.pending_load_data.is_empty():
		print("New game - clearing any default weapons")
		var weapon_mgr = player.get_weapon_manager()
		if weapon_mgr:
			# Clear any WeaponItems in the slots (from scene exports)
			weapon_mgr.primary_slot = null
			weapon_mgr.secondary_slot = null
			
			# Remove any instantiated guns
			if weapon_mgr.primary_gun:
				weapon_mgr.primary_gun.queue_free()
				weapon_mgr.primary_gun = null
			if weapon_mgr.secondary_gun:
				weapon_mgr.secondary_gun.queue_free()
				weapon_mgr.secondary_gun = null
			
			print("✓ Cleared default weapons for new game")
	
	# Setup level select UI
	var level_select = level_select_scene.instantiate()
	add_child(level_select)
	
	# Setup farm exit interaction
	if farm_exit:
		if not farm_exit.is_in_group("interaction_areas"):
			farm_exit.add_to_group("interaction_areas")
		farm_exit.interaction_type = "farm_exit"
		print("✓ Farm exit configured")
	
	# Setup weapon storage system
	weapon_storage = WeaponStorageManager.new()
	weapon_storage.name = "WeaponStoragManager"
	add_child(weapon_storage)
	weapon_storage.add_to_group("weapon_storage")  # For SaveSystem to find it
	print("✓ Weapon storage created")
	
	# Connect weapon chest
	if weapon_chest:
		weapon_chest.set_storage_ui(weapon_storage_ui)
		print("✓ Weapon chest connected")
	
	# Connect to weapon equip events to disable guns in safehouse
	var player_weapon_manager = player.get_weapon_manager()
	if player_weapon_manager and player_weapon_manager.has_signal("weapon_equipped"):
		player_weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
	
	# CRITICAL: Load player data FIRST (this populates pending_load_data with unlocked_weapons)
	if not GameManager.pending_load_data.is_empty():
		print("Loading player from save file...")
		SaveSystem.apply_player_data(player, GameManager.pending_load_data.get("player", {}))
		
		# Force refresh inventory UI
		await get_tree().process_frame
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			inv_mgr.inventory_changed.emit()
			print("✓ Inventory restored and refreshed")
		
		player.refresh_hud()
	
	# NOW restore unlocked weapons (AFTER apply_player_data put them in pending_load_data)
	# Note: SaveSystem.apply_player_data already set them in GlobalWeaponStorage
	if GameManager.pending_load_data.has("unlocked_weapons"):
		# Just for logging - they're already in GlobalWeaponStorage
		var unlocked = GlobalWeaponStorage.get_unlocked_weapons() if GlobalWeaponStorage else []
		print("  ✓ Unlocked weapons already in GlobalWeaponStorage: ", unlocked)
		GameManager.pending_load_data.erase("unlocked_weapons")
	
	# Setup weapon storage UI (AFTER unlocked_weapons are restored)
	if weapon_storage_ui and player_weapon_manager:
		# CRITICAL: Wait for weapon_storage to be fully ready
		await get_tree().process_frame
		weapon_storage_ui.setup_storage(weapon_storage, player_weapon_manager, player)
		weapon_storage_ui.add_to_group("weapon_ui")  # For save system
		print("✓ Weapon storage UI configured")
	else:
		print("ERROR: Missing weapon_storage_ui or player_weapon_manager")
		print("  weapon_storage_ui: ", weapon_storage_ui)
		print("  player_weapon_manager: ", player_weapon_manager)
	
	
	# CRITICAL: Now restore chests AFTER apply_player_data (which populates the storage_chests data)
	if GameManager.pending_load_data.has("storage_chests"):
		_restore_storage_chests()
	
	# Restore weapon storage from save file if loading
	if GameManager.pending_load_data.has("weapon_storage"):
		_restore_weapon_storage_from_save(GameManager.pending_load_data.weapon_storage)
		GameManager.pending_load_data.erase("weapon_storage")
	
	# Clear pending load data
	GameManager.pending_load_data = {}
	
	# Wait a frame for weapons to instantiate
	await get_tree().process_frame
	await get_tree().process_frame  # Wait TWO frames to be sure
	
	# Set location state to disable guns
	_set_safehouse_state()
	
	# CRITICAL: Force disable guns after state change
	await get_tree().process_frame
	_disable_all_guns()
	print("Force-disabled guns after instantiation")
	
	# Add pause menu
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	
	print("=== SAFEHOUSE SETUP COMPLETE ===\n")

func _restore_weapon_storage_from_save(weapon_data: Array):
	"""Restore weapon chest contents from save data"""
	print("Restoring weapon storage from save...")
	
	for i in range(weapon_data.size()):
		var data = weapon_data[i]
		if data.is_empty():
			continue
		
		var weapon: WeaponItem = null
		match data.name:
			"Pistol":
				weapon = WeaponFactory.create_pistol()
			"Shotgun":
				weapon = WeaponFactory.create_shotgun()
			"Assault Rifle":
				weapon = WeaponFactory.create_rifle()
			"Sniper Rifle":
				weapon = WeaponFactory.create_sniper()
			"Machine Gun":
				weapon = WeaponFactory.create_machine_gun()
			"Burst Rifle":
				weapon = WeaponFactory.create_burst_rifle()
		
		if weapon and i < weapon_storage.weapons.size():
			weapon_storage.weapons[i] = weapon
	
	weapon_storage.storage_changed.emit()
	print("  ✓ Weapon storage restored")

func _restore_storage_chests():
	"""Restore item storage chests from save data"""
	if not GameManager.pending_load_data.has("storage_chests"):
		return
	
	var chests_data = GameManager.pending_load_data.storage_chests
	
	# Find StorageChest node and restore it
	var storage_chest = get_node_or_null("StorageChest")
	if storage_chest and storage_chest.has_method("load_from_save_data"):
		if chests_data.has("safehouse_chest"):
			storage_chest.load_from_save_data(chests_data.safehouse_chest)
			print("  ✓ Item storage restored")
	
	GameManager.pending_load_data.erase("storage_chests")

func _on_weapon_equipped(slot: int, weapon_item: WeaponItem):
	"""Disable any weapon equipped in safehouse"""
	await get_tree().process_frame
	_disable_all_guns()

func _set_safehouse_state():
	"""Set player location state to safehouse (disables guns)"""
	if player and player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		loc_state.change_state("SafehouseState")
		print("✓ Location state: Safehouse")

func _disable_all_guns():
	"""Disable all equipped guns"""
	print("\n=== DISABLING GUNS ===")
	
	if not player:
		print("ERROR: No player reference")
		return
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("ERROR: No weapon manager found")
		return
	
	print("Weapon manager found")
	print("Primary gun: ", weapon_manager.primary_gun)
	print("Secondary gun: ", weapon_manager.secondary_gun)
	
	# Disable primary
	if weapon_manager.primary_gun:
		weapon_manager.primary_gun.set_can_fire(false)
		weapon_manager.primary_gun.visible = false
		weapon_manager.primary_gun.process_mode = Node.PROCESS_MODE_DISABLED
		print("✓ Primary gun disabled")
	
	# Disable secondary
	if weapon_manager.secondary_gun:
		weapon_manager.secondary_gun.set_can_fire(false)
		weapon_manager.secondary_gun.visible = false
		weapon_manager.secondary_gun.process_mode = Node.PROCESS_MODE_DISABLED
		print("✓ Secondary gun disabled")
	
	print("=== GUNS DISABLED ===")
