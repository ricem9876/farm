# SafeHouse.gd - Script for your safehouse scene
extends Node2D

@onready var inventory_ui = $InventoryUI  # Adjust path as needed
@onready var player = $player  # Adjust path as needed
@onready var camera = $player/Camera2D
@onready var farm_exit = $FarmExit  # InteractionArea to go back to farm

func _ready():
	# Set the current scene type
	GameManager.current_scene_type = "safehouse"
	print("Safehouse scene loaded")
	
	if player:
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		
		if inventory_ui:
			inventory_ui.setup_inventory(player.get_inventory_manager(), camera)
	
	# Setup farm exit interaction
	if farm_exit:
		farm_exit.body_entered.connect(_on_farm_exit_entered)

func _on_inventory_toggle_requested():
	inventory_ui.toggle_visibility()

func _on_farm_exit_entered(body):
	if body.has_method("get_inventory_manager"):  # Check if it's the player
		#print("Player leaving safehouse...")
		GameManager.change_to_farm()

# Add safehouse-specific functionality here
func setup_crafting_stations():
	# Connect to crafting station interactions
	pass

func setup_storage_chests():
	# Connect to storage chest interactions
	pass
