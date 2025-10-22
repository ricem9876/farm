func _debug_topup_resources():
	"""Debug cheat: Grant 25 of each resource material, 500 coins, and 100 tech points"""
	if not inventory_manager:
		print("DEBUG: Cannot add resources - no inventory manager")
		return
	
	var resources = [
		{"name": "Wood", "quantity": 25},
		{"name": "Plant Fiber", "quantity": 25},
		{"name": "Wolf Fur", "quantity": 25},
		{"name": "Mushroom", "quantity": 25}
	]
	
	print("\n=== DEBUG: TOPPING UP RESOURCES ===")
	
	# Add materials
	for resource in resources:
		var item = _create_item_from_name(resource.name)
		if item:
			if inventory_manager.add_item(item, resource.quantity):
				print("✓ Added ", resource.quantity, "x ", resource.name)
			else:
				print("✗ Failed to add ", resource.name, " (inventory full?)")
		else:
			print("✗ Failed to create item: ", resource.name)
	
	# Add coins
	if has_method("add_coins"):
		add_coins(500)
		print("✓ Added 500 Coins")
	else:
		print("⚠ add_coins method not found")
	
	# Add tech points
	if has_method("add_tech_points"):
		add_tech_points(100)
		print("✓ Added 100 Tech Points")
	else:
		print("⚠ add_tech_points method not found")
	
	print("=== TOPUP COMPLETE ===")
