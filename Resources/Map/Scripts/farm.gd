extends Node2D

@onready var inventory_ui = $InventoryUI
@onready var weapon_hud = $CanvasLayer/WeaponHUD
@onready var player = $player
@onready var camera = $player/Camera2D
@onready var house_entrance = $HouseEntrance

func _ready():
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
	if weapon_hud:
		print("✓ WeaponHUD found")
		var weapon_mgr = player.get_weapon_manager()
		
		if weapon_mgr:
			weapon_hud.setup_hud(weapon_mgr, player)
			print("  - Weapon HUD setup complete")
		else:
			print("  ⚠ No weapon manager - hiding WeaponHUD")
			weapon_hud.visible = false
	else:
		print("ERROR: WeaponHUD not found!")
	
	# Restore player state from GameManager
	await get_tree().process_frame
	_restore_player_state()
	
	# Wait another frame for weapons to be restored and instantiated
	await get_tree().process_frame
	
	# NOW enable the gun
	_enable_gun_on_farm()
	
	print("=== FARM SCENE SETUP COMPLETE ===\n")

func _restore_player_state():
	"""Restore player state when entering farm"""
	print("Checking for saved player state...")
	
	# Restore inventory
	if player.has_method("get_inventory_manager"):
		var inv_mgr = player.get_inventory_manager()
		if inv_mgr:
			GameManager.restore_player_inventory(inv_mgr)
		else:
			print("  ⚠ No inventory manager to restore")
	
	# Restore weapons
	if player.has_method("get_weapon_manager"):
		var wep_mgr = player.get_weapon_manager()
		if wep_mgr:
			GameManager.restore_player_weapons(wep_mgr)
		else:
			print("  ⚠ No weapon manager to restore")
	
	# Restore level system
	if player.level_system:
		GameManager.restore_player_level_system(player.level_system)
		print("✓ Level system restored: Level ", player.level_system.current_level)
	else:
		print("  ⚠ No level system to restore")

func _enable_gun_on_farm():
	print("Setting location state to Farm...")
	
	if player and player.has_node("LocationStateMachine"):
		var loc_state = player.get_node("LocationStateMachine")
		loc_state.change_state("FarmState")
	else:
		print("✗ No LocationStateMachine found on player")

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
