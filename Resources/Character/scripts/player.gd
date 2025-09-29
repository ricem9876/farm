extends CharacterBody2D
class_name player

signal inventory_toggle_requested
@export var max_health: float = 100.0
var current_health: float
var inventory_manager: InventoryManager
var gun

# Get reference to state machine
@onready var state_machine = $StateMachine

# Create item resources once and reuse them
var mushroom_item_resource: Item

func _ready():
	#print("Player ready - setting up inventory manager...")
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	#print("Inventory manager created and added as child")
	
	add_to_group("player")
	
	# Setup based on current scene type
	setup_for_scene_type(GameManager.get_current_scene_type())
	
	GameManager.restore_player_inventory(inventory_manager)
	
	# Create the mushroom item resource once
	_create_item_resources()
	
	gun = preload("res://Resources/Weapon/Gun.tscn").instantiate()
	add_child(gun)
	gun.setup_with_player(self)
	
	gun.gun_evolved.connect(_on_gun_evolved)
	gun.stat_changed.connect(_on_gun_stat_changed)
	
	current_health = max_health
	#print("Player setup complete")

func _create_item_resources():
	# Create mushroom item resource once - this will be reused for all mushrooms
	mushroom_item_resource = Item.new()
	mushroom_item_resource.name = "Mushroom"
	mushroom_item_resource.description = "A tasty mushroom"
	mushroom_item_resource.stack_size = 99
	mushroom_item_resource.item_type = "consumable"
	mushroom_item_resource.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")
	#print("Created reusable mushroom item resource")
	
func _input(event):
	# Only handle inventory toggle here - let state machine handle other inputs
	if event.is_action_pressed("toggle_inventory"):
		inventory_toggle_requested.emit()
		
	# Only handle gun input if not in safehouse
	if not state_machine.is_in_safehouse():
		if event.is_action_pressed("fire"):
			gun.start_firing()
		elif event.is_action_released("fire"):
			gun.stop_firing()

func take_damage(damage: float):
	current_health -= damage
	#print("Player took ", damage, "damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_player_died()

func _player_died():
	print ("Player died!")
	#GAME OVER

func _on_gun_evolved(new_tier: int):
	print ("Gun evolved to tier: ", new_tier)
	#add in effects

func _on_gun_stat_changed(stat_name: String, old_value: float, new_value: float):
	print(stat_name, " changed from ", old_value, " to ", new_value)
	
func gain_experience(points: int):
	gun.add_evolution_points(points)
	print("Gained ", points, " experience")
	
func _on_enemy_died():
	gain_experience(10) #adjust on enemy death

func get_inventory_manager() -> InventoryManager:
	#print("get_inventory_manager called, returning: ", inventory_manager)
	return inventory_manager
	
func collect_item(item_name: String):
	#print("=== COLLECT_ITEM CALLED ===")
	#print("Item name: ", item_name)
	#print("Inventory manager exists: ", inventory_manager != null)
	
	if not inventory_manager:
		#print("ERROR: No inventory manager!")
		return
	
	# Handle different item types
	match item_name:
		"mushroom":
			#print("Processing mushroom...")
			# Use the pre-created mushroom resource instead of creating a new one
			if mushroom_item_resource:
				#print("Using existing mushroom item resource: ", mushroom_item_resource.name)
				#print("Resource ID: ", mushroom_item_resource.get_instance_id())
				
				var success = inventory_manager.add_item(mushroom_item_resource, 1)
				#if success:
					#print("SUCCESS: Mushroom added to inventory!")
				#else:
					#print("FAILED: Could not add mushroom to inventory - inventory might be full")
					
				# Debug: Check inventory state
				#print("Current inventory contents:")
				#for i in range(inventory_manager.items.size()):
					#if inventory_manager.items[i] != null:
						#print("  Slot ", i, ": ", inventory_manager.items[i].name, " x", inventory_manager.quantities[i], " (ID: ", inventory_manager.items[i].get_instance_id(), ")")
			#else:
				#print("ERROR: mushroom_item_resource is null!")
		
		"health_potion":
			#print("Processing health potion...")
			if current_health < max_health:
				current_health = min(max_health, current_health + 25)
				#print("Health restored! Current health: ", current_health)
		
		"coin":
			print("Processing coin...")
			print("Gained coin!")
		
		_:
			print("Unknown item type: ", item_name)
	
	#print("=== COLLECT_ITEM FINISHED ===")
	
	# Play pickup sound effect here
	# AudioManager.play_sound("pickup")
	
func setup_for_scene_type(scene_type: String):
	"""Configure player capabilities based on current scene"""
	match scene_type:
		"farm":
			enable_combat_mode()
		"safehouse":
			enable_safehouse_mode()

func enable_combat_mode():
	"""Enable combat-related functionality"""
	#print("Enabling combat mode")
	if state_machine:
		state_machine.enter_combat_mode()

func enable_safehouse_mode():
	"""Enable safehouse-related functionality"""
	#print("Enabling safehouse mode")
	if state_machine:
		state_machine.enter_safehouse_mode()

# Add interaction system for entering/exiting buildings
func interact_with_building(building_type: String):
	match building_type:
		"house":
			GameManager.change_to_safehouse()
		"farm_exit":
			GameManager.change_to_farm()

# Method to check if player is in safehouse (useful for other systems)
func is_in_safehouse() -> bool:
	return state_machine.is_in_safehouse() if state_machine else false
