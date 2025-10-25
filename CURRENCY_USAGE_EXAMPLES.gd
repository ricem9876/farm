# Currency Usage Examples
# How to use Coins and Tech Points in your game

extends Node

# Example 1: Shop System - Purchase a weapon with coins
func purchase_weapon(player: CharacterBody2D, weapon_cost: int) -> bool:
	var inventory = player.get_inventory_manager()
	
	# Check if player has enough coins
	if inventory.has_enough_items("Coin", weapon_cost):
		# Remove the coins
		if inventory.remove_item_by_name("Coin", weapon_cost):
			print("✓ Purchased weapon for ", weapon_cost, " coins!")
			# Add weapon to player here
			return true
		else:
			print("✗ Failed to remove coins (shouldn't happen)")
			return false
	else:
		var current_coins = inventory.count_item_by_name("Coin")
		print("✗ Not enough coins! Need ", weapon_cost, " but have ", current_coins)
		return false

# Example 2: Weapon Upgrade System - Use tech points to upgrade
func upgrade_weapon(player: CharacterBody2D, upgrade_cost: int) -> bool:
	var inventory = player.get_inventory_manager()
	
	# Check if player has enough tech points
	if inventory.has_enough_items("Tech Point", upgrade_cost):
		# Remove the tech points
		if inventory.remove_item_by_name("Tech Point", upgrade_cost):
			print("✓ Upgraded weapon for ", upgrade_cost, " tech points!")
			# Apply upgrade here
			return true
		else:
			print("✗ Failed to remove tech points")
			return false
	else:
		var current_tech = inventory.count_item_by_name("Tech Point")
		print("✗ Not enough tech points! Need ", upgrade_cost, " but have ", current_tech)
		return false

# Example 3: Display Currency UI
func update_currency_display(player: CharacterBody2D) -> Dictionary:
	var inventory = player.get_inventory_manager()
	
	var currency_data = {
		"coins": inventory.count_item_by_name("Coin"),
		"tech_points": inventory.count_item_by_name("Tech Point")
	}
	
	print("Player Currency:")
	print("  💰 Coins: ", currency_data.coins)
	print("  🔧 Tech Points: ", currency_data.tech_points)
	
	return currency_data

# Example 4: Award currency as quest reward
func give_quest_reward(player: CharacterBody2D, coins: int, tech_points: int):
	# Create coin item and add to inventory
	var coin_item = player._create_item_from_name("coin")
	player.add_item_to_inventory(coin_item, coins)
	
	# Create tech point item and add to inventory
	var tech_item = player._create_item_from_name("techpoint")
	player.add_item_to_inventory(tech_item, tech_points)
	
	print("Quest reward granted!")
	print("  + ", coins, " Coins")
	print("  + ", tech_points, " Tech Points")

# Example 5: Enemy Drop Currency
func on_enemy_death(enemy_position: Vector2, enemy_tier: int):
	# Calculate drops based on enemy tier
	var coin_drop = randi_range(5, 15) * enemy_tier
	var tech_drop = randi_range(1, 3) * enemy_tier
	
	# Spawn coin pickups
	_spawn_currency_pickup("coin", coin_drop, enemy_position)
	
	# Spawn tech point pickups (less frequent)
	if randf() < 0.5:  # 50% chance to drop tech points
		_spawn_currency_pickup("techpoint", tech_drop, enemy_position)

func _spawn_currency_pickup(currency_type: String, amount: int, position: Vector2):
	var pickup_scene = preload("res://Resources/Inventory/ItemPickup.tscn")
	
	for i in range(amount):
		var pickup = pickup_scene.instantiate()
		pickup.item_name = currency_type
		
		# Random spread around position
		var offset = Vector2(
			randf_range(-30, 30),
			randf_range(-30, 30)
		)
		pickup.global_position = position + offset
		
		get_tree().current_scene.add_child(pickup)

# Example 6: Chest Loot with Currency
func open_loot_chest(chest_position: Vector2, chest_tier: String):
	var coin_amount: int
	var tech_amount: int
	
	# Different amounts based on chest tier
	match chest_tier:
		"wood":
			coin_amount = randi_range(10, 25)
			tech_amount = randi_range(5, 10)
		"mushroom":
			coin_amount = randi_range(25, 50)
			tech_amount = randi_range(10, 20)
		"plant":
			coin_amount = randi_range(50, 100)
			tech_amount = randi_range(20, 30)
		"wool":
			coin_amount = randi_range(100, 200)
			tech_amount = randi_range(30, 50)
	
	# Spawn the currency
	_spawn_currency_pickup("coin", coin_amount, chest_position)
	_spawn_currency_pickup("techpoint", tech_amount, chest_position)
	
	print("Chest opened! Dropped ", coin_amount, " coins and ", tech_amount, " tech points")

# Example 7: Shop UI Button Handler
func on_purchase_button_pressed(player: CharacterBody2D, item_name: String, cost: int):
	if purchase_weapon(player, cost):
		# Update UI to show purchase success
		print("Purchase successful! Item: ", item_name)
		# Give player the item/weapon here
	else:
		# Show "not enough coins" message in UI
		print("Cannot afford this item!")

# Example 8: Upgrade UI Button Handler
func on_upgrade_button_pressed(player: CharacterBody2D, weapon_name: String, upgrade_level: int):
	# Calculate cost (increases with level)
	var upgrade_cost = 10 * upgrade_level
	
	if upgrade_weapon(player, upgrade_cost):
		print(weapon_name, " upgraded to level ", upgrade_level, "!")
		# Apply actual stat upgrade here
	else:
		print("Cannot afford upgrade!")

# Example 9: Currency Display Label Update (call this regularly)
func _on_inventory_changed(coin_label: Label, tech_label: Label, player: CharacterBody2D):
	var inventory = player.get_inventory_manager()
	
	coin_label.text = str(inventory.count_item_by_name("Coin"))
	tech_label.text = str(inventory.count_item_by_name("Tech Point"))

# Example 10: Save/Load (automatic with existing system)
# Currency saves automatically as part of inventory!
# No special code needed - just use SaveSystem as normal
