extends Node2D

@onready var inventory_ui = $InventoryUI
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
		print("  - Connecting inventory_toggle_requested signal...")
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		print("  - Signal connected!")
		
		print("  - Setting up inventory UI...")
		inventory_ui.setup_inventory(player.get_inventory_manager(), camera, player)
		print("  - Inventory UI setup complete")
		print("  - Initial visibility: ", inventory_ui.visible)
	else:
		print("ERROR: InventoryUI not found!")
	
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
		GameManager.restore_player_inventory(player.get_inventory_manager())
	
	# Restore weapons
	if player.has_method("get_weapon_manager"):
		GameManager.restore_player_weapons(player.get_weapon_manager())

func _enable_gun_on_farm():
	print("Attempting to enable gun on farm...")
	
	if not player:
		print("✗ No player reference")
		return
	
	var weapon_manager = player.get_weapon_manager()
	if not weapon_manager:
		print("✗ No weapon manager")
		return
	
	var gun = weapon_manager.get_active_gun()
	if gun:
		gun.set_can_fire(true)
		gun.visible = true
		gun.process_mode = Node.PROCESS_MODE_INHERIT
		print("✓ Gun enabled, visible, and processing resumed on farm")
	else:
		print("✗ No active gun found (this is OK if player has no weapon)")

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
