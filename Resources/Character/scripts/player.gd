extends CharacterBody2D
class_name player

signal inventory_toggle_requested
@export var max_health: float = 100.0
var current_health: float
var inventory_manager: InventoryManager
var gun

func _ready():
	print("Player ready - setting up inventory manager...")
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	print("Inventory manager created and added as child")
	
	gun = preload("res://Resources/Weapon/Gun.tscn").instantiate()
	add_child(gun)
	gun.setup_with_player(self)
	
	gun.gun_evolved.connect(_on_gun_evolved)
	gun.stat_changed.connect(_on_gun_stat_changed)
	
	current_health = max_health
	print("Player setup complete")
	
func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		inventory_toggle_requested.emit()
		
	if event.is_action_pressed("fire"):
		gun.start_firing()
	elif event.is_action_released("fire"):
		gun.stop_firing()

func take_damage(damage: float):
	current_health -= damage
	print("Player took ", damage, "damage. Health: ", current_health, "/", max_health)
	
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
	print("get_inventory_manager called, returning: ", inventory_manager)
	return inventory_manager
	
func collect_item(item_name: String):
	print("=== COLLECT_ITEM CALLED ===")
	print("Item name: ", item_name)
	print("Inventory manager exists: ", inventory_manager != null)
	
	if not inventory_manager:
		print("ERROR: No inventory manager!")
		return
	
	# Handle different item types
	match item_name:
		"mushroom":
			print("Processing mushroom...")
			# Add to inventory
			if inventory_manager:
				var mushroom_item = Item.new()
				mushroom_item.name = "Mushroom"
				mushroom_item.description = "A tasty mushroom"
				mushroom_item.stack_size = 99
				mushroom_item.item_type = "consumable"
				# Add a default icon - you should replace this with an actual texture
				mushroom_item.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")  # Replace with actual mushroom icon
				
				print("Created mushroom item: ", mushroom_item.name)
				print("Attempting to add to inventory...")
				
				var success = inventory_manager.add_item(mushroom_item, 1)
				if success:
					print("SUCCESS: Mushroom added to inventory!")
				else:
					print("FAILED: Could not add mushroom to inventory - inventory might be full")
					
				# Debug: Check inventory state
				print("Current inventory size: ", inventory_manager.items.size())
				for i in range(inventory_manager.items.size()):
					if inventory_manager.items[i] != null:
						print("Slot ", i, ": ", inventory_manager.items[i].name, " x", inventory_manager.quantities[i])
			else:
				print("ERROR: inventory_manager is null in mushroom case")
		
		"health_potion":
			print("Processing health potion...")
			if current_health < max_health:
				current_health = min(max_health, current_health + 25)
				print("Health restored! Current health: ", current_health)
		
		"coin":
			print("Processing coin...")
			print("Gained coin!")
		
		_:
			print("Unknown item type: ", item_name)
	
	print("=== COLLECT_ITEM FINISHED ===")
	
	# Play pickup sound effect here
	# AudioManager.play_sound("pickup")
