extends Node2D  # or Control, or whatever your main scene extends

@onready var inventory_ui = $InventoryUI  # Adjust path to match your scene structure
@onready var player = $player  # Adjust path to match your scene structure
@onready var camera = $player/Camera2D

func _ready():
	if player:
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		
		if inventory_ui:
			inventory_ui.setup_inventory(player.get_inventory_manager(), camera)
	# Connect player's inventory signal
	#player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
	#
	## Setup inventory UI with player's inventory manager
	#inventory_ui.setup_inventory(player.get_inventory_manager())

func _on_inventory_toggle_requested():
	inventory_ui.toggle_visibility()
