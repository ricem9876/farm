extends Node2D

@onready var inventory_ui = $InventoryUI
@onready var player = $player
@onready var camera = $player/Camera2D
@onready var house_entrance = $HouseEntrance
var pause_menu_scene = preload("res://Resources/UI/PauseMenu.tscn")

func _ready():
	print("\n=== FARM SCENE _READY CALLED ===")
	AudioManager.play_music(AudioManager.farm_music)
	# Try to find EnemySpawner
	var spawner = get_node_or_null("EnemySpawner")
	print("EnemySpawner node: ", spawner)
	if spawner:
		print("EnemySpawner script: ", spawner.get_script())
	print("\n=== FARM SCENE SETUP START ===")

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
	
	# Setup house entrance interaction
	if house_entrance:
		print("✓ HouseEntrance found at position: ", house_entrance.global_position)
		
		var collision_shape = house_entrance.get_node_or_null("CollisionShape2D")
		if collision_shape:
			print("  ✓ CollisionShape2D found")
			print("    - Shape: ", collision_shape.shape)
			print("    - Position: ", collision_shape.position)
		else:
			print("  ✗ ERROR: CollisionShape2D not found!")
		
		if not house_entrance.is_in_group("interaction_areas"):
			house_entrance.add_to_group("interaction_areas")
		
		if house_entrance is InteractionArea:
			house_entrance.interaction_type = "house"
			house_entrance.show_prompt = true
			print("  ✓ Set interaction type to: ", house_entrance.interaction_type)
			print("  ✓ HouseEntrance is InteractionArea type")
		else:
			print("  ✗ ERROR: HouseEntrance is not InteractionArea type!")
			print("    Current script: ", house_entrance.get_script())
	else:
		print("ERROR: HouseEntrance not found!")
	
	# Setup inventory UI
	if inventory_ui:
		print("✓ InventoryUI found")
		
		if player.has_signal("inventory_toggle_requested"):
			print("  - Connecting inventory_toggle_requested signal...")
			player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
			print("  - Signal connected!")
		else:
			print("  ✗ Player doesn't have inventory_toggle_requested signal")
		
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			print("  - Setting up inventory UI...")
			inventory_ui.setup_inventory(inv_mgr, camera, player)
			print("  - Inventory UI setup complete")
			print("  - Initial visibility: ", inventory_ui.visible)
		else:
			print("  ✗ No inventory manager found")
	else:
		print("ERROR: InventoryUI not found!")
	
	# Setup weapon HUD

	
	# Restore player state from GameManager
	await get_tree().process_frame
	_restore_player_state()
	
	# Wait another frame for weapons to be restored and instantiated
	await get_tree().process_frame
	
	# NOW enable the gun
	_enable_gun_on_farm()
	
	
		
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	print("✓ Pause menu added")
	
	print("=== FARM SCENE SETUP COMPLETE ===\n")

func _restore_player_state():
	"""Restore player state when entering farm"""
	print("Checking for saved player state...")
	
	if not GameManager.pending_load_data.is_empty():
		print("Loading from save file...")
		SaveSystem.apply_player_data(player, GameManager.pending_load_data.get("player", {}))
		GameManager.pending_load_data = {}
		player.refresh_hud()
		player.refresh_weapon_hud()
		return
	
	# Scene transition - data already current
	print("Scene transition - player data already current")
	player.refresh_hud()
	player.refresh_weapon_hud()


func _enable_gun_on_farm():
	print("\n=== DETAILED GUN ENABLE DEBUG ===")
	print("Setting location state to Farm...")
	
	if not player:
		print("ERROR: No player!")
		return
	
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		print("ERROR: No WeaponManager!")
		return
	
	print("WeaponManager found")
	print("  Primary slot: ", weapon_manager.primary_slot)
	print("  Secondary slot: ", weapon_manager.secondary_slot)
	print("  Active slot: ", weapon_manager.active_slot)
	print("  Primary gun node: ", weapon_manager.primary_gun)
	print("  Secondary gun node: ", weapon_manager.secondary_gun)
	
	if weapon_manager.primary_gun:
		print("  Primary gun exists:")
		print("    - Name: ", weapon_manager.primary_gun.name)
		print("    - Visible: ", weapon_manager.primary_gun.visible)
		print("    - Can fire: ", weapon_manager.primary_gun.can_fire)
		print("    - Parent: ", weapon_manager.primary_gun.get_parent())
		print("    - Is inside tree: ", weapon_manager.primary_gun.is_inside_tree())
	
	if weapon_manager.secondary_gun:
		print("  Secondary gun exists:")
		print("    - Name: ", weapon_manager.secondary_gun.name)
		print("    - Visible: ", weapon_manager.secondary_gun.visible)
		print("    - Can fire: ", weapon_manager.secondary_gun.can_fire)
		print("    - Parent: ", weapon_manager.secondary_gun.get_parent())
	
	if player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		print("LocationStateMachine found")
		print("  Current state: ", loc_state.current_state.name if loc_state.current_state else "None")
		
		loc_state.change_state("FarmState")
		
		# Check gun status AFTER state change
		await get_tree().process_frame
		print("\nAfter FarmState enter:")
		if weapon_manager.primary_gun:
			print("  Primary gun:")
			print("    - Visible: ", weapon_manager.primary_gun.visible)
			print("    - Can fire: ", weapon_manager.primary_gun.can_fire)
			print("    - Is queued for deletion: ", weapon_manager.primary_gun.is_queued_for_deletion())
	else:
		print("ERROR: No LocationStateMachine!")
	
	print("=================================\n")

func _on_inventory_toggle_requested():
	print("=== INVENTORY TOGGLE REQUESTED ===")
	print("Current inventory_ui: ", inventory_ui)
	print("Is inventory_ui valid: ", is_instance_valid(inventory_ui))
	if inventory_ui:
		print("Current visibility: ", inventory_ui.visible)
		inventory_ui.toggle_visibility()
		print("New visibility: ", inventory_ui.visible)
	else:
		print("ERROR: inventory_ui is null!")
	print("==================================")

func _input(event):
	# Debug input
	if event.is_action_pressed("toggle_inventory"):
		print(">>> TAB/SHIFT PRESSED IN FARM SCENE <<<")
		_on_inventory_toggle_requested()
		
func _exit_tree():
	# Auto-save when leaving farm
	if GameManager.current_save_slot >= 0 and player:
		print("Auto-saving when leaving farm...")
		var player_data = SaveSystem.collect_player_data(player)
		SaveSystem.save_game(GameManager.current_save_slot, player_data)
