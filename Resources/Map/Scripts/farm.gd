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
	
	# Setup house entrance interaction
	if house_entrance:
		print("✓ HouseEntrance found")
		if not house_entrance.is_in_group("interaction_areas"):
			house_entrance.add_to_group("interaction_areas")
		house_entrance.interaction_type = "house"
		print("  - Interaction type set to: ", house_entrance.interaction_type)
	else:
		print("ERROR: HouseEntrance not found!")
	
	# Setup inventory UI
	if inventory_ui:
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		inventory_ui.setup_inventory(player.get_inventory_manager(), camera, player)
		print("✓ Inventory UI setup complete")
	else:
		print("ERROR: InventoryUI not found!")
	
	# Restore player state from GameManager
	await get_tree().process_frame
	_restore_player_state()
	
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

func _on_inventory_toggle_requested():
	if inventory_ui:
		inventory_ui.toggle_visibility()
