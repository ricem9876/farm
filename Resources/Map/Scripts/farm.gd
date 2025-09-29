# Try this approach in your farm.gd instead:

extends Node2D

@onready var inventory_ui = $InventoryUI
@onready var player = $player
@onready var camera = $player/Camera2D
@onready var house_entrance = $HouseEntrance  # Make sure path matches your scene

func _ready():
	GameManager.current_scene_type = "farm"
	
	if player:
		player.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
		
		if inventory_ui:
			inventory_ui.setup_inventory(player.get_inventory_manager(), camera)
	
	# Direct connection approach
	if house_entrance:
		#print("Connecting house entrance signals...")
		# Try both signals
		if house_entrance.has_signal("body_entered"):
			house_entrance.body_entered.connect(_on_house_entrance_entered)
			#print("Connected body_entered signal")
		#else:
			#print("ERROR: house_entrance does not have body_entered signal!")
		
		# Also try area_entered in case that's the issue
		
	#else:
		#print("ERROR: house_entrance not found!")

func _on_inventory_toggle_requested():
	inventory_ui.toggle_visibility()

func _on_house_entrance_entered(body):
	#print("=== FARM HOUSE ENTRANCE ===")
	#print("Body entered: ", body.name)
	#print("Is player: ", body.has_method("get_inventory_manager"))
	
	if body.has_method("get_inventory_manager"):
		#print("Player entering house...")
		GameManager.change_to_safehouse()
	#print("==========================")
