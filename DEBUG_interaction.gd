# Add this to player.gd temporarily for debugging

func _check_interaction_areas():
	print("\n=== CHECKING INTERACTIONS ===")
	
	# Find nearby interaction areas
	var areas = get_tree().get_nodes_in_group("interaction_areas")
	print("Total interaction areas found: ", areas.size())
	
	for area in areas:
		print("  Area: ", area.name, " at ", area.global_position)
		print("  Distance: ", global_position.distance_to(area.global_position))
		print("  Has meta: ", area.has_meta("interaction_type"))
		if area.has_meta("interaction_type"):
			print("  Type: ", area.get_meta("interaction_type"))
		
		if global_position.distance_to(area.global_position) < 50:
			var interaction_type = area.get_meta("interaction_type", "")
			print("  ✓ WITHIN RANGE!")
			
			match interaction_type:
				"upgrade_shop":
					print("  ✓ Matched upgrade_shop")
					_open_upgrade_shop()
					break
				_:
					print("  Unknown interaction type: ", interaction_type)
	
	print("=== END CHECK ===\n")

func _open_upgrade_shop():
	print("\n=== OPENING UPGRADE SHOP ===")
	
	# Find the upgrade UI (it's in safehouse scene)
	var safehouse = get_tree().current_scene
	print("Current scene: ", safehouse.name if safehouse else "NULL")
	
	var upgrade_ui = safehouse.get_node_or_null("%WeaponUpgradeUI")
	print("Upgrade UI found: ", upgrade_ui != null)
	
	if upgrade_ui:
		print("Upgrade UI name: ", upgrade_ui.name)
		print("Has 'open' method: ", upgrade_ui.has_method("open"))
		
		if upgrade_ui.has_method("open"):
			print("Calling open()...")
			upgrade_ui.open()
			print("✓ Opened upgrade shop!")
		else:
			print("✗ ERROR: No 'open' method")
	else:
		print("✗ ERROR: WeaponUpgradeUI not found in scene!")
		print("Available nodes:")
		for child in safehouse.get_children():
			print("  - ", child.name)
	
	print("=== END OPEN ===\n")
