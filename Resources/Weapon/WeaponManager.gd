extends Node
class_name WeaponManager

signal weapon_switched(slot: int, weapon: Gun)
signal weapon_equipped(slot: int, weapon_item: WeaponItem)
signal weapon_unequipped(slot: int)

@export var primary_slot: WeaponItem
@export var secondary_slot: WeaponItem

var primary_gun: Gun
var secondary_gun: Gun
var active_slot: int = 0  # 0 = primary, 1 = secondary
var player: Node2D

func _ready():
	player = get_parent()

func equip_weapon(weapon_item: WeaponItem, slot: int = 0) -> bool:
	if not weapon_item or weapon_item.item_type != "weapon":
		print("Cannot equip non-weapon item")
		return false
	
	# Remove old weapon from slot
	unequip_weapon(slot)
	
	# Set the weapon item
	if slot == 0:
		primary_slot = weapon_item
	else:
		secondary_slot = weapon_item
	
	# Create the gun instance
	var gun = weapon_item.weapon_scene.instantiate() as Gun
	if not gun:
		print("Failed to instantiate weapon")
		return false
	
	# Add gun to player
	player.add_child(gun)
	gun.setup_with_player(player)
	
	# Set gun stats from weapon item
	gun.base_damage = weapon_item.base_damage
	gun.base_fire_rate = weapon_item.base_fire_rate
	gun.base_bullet_speed = weapon_item.base_bullet_speed
	gun.base_accuracy = weapon_item.base_accuracy
	gun.base_bullet_count = weapon_item.base_bullet_count
	
	
	# IMPORTANT: Set the gun sprite from the weapon item!
	if gun.gun_sprite and weapon_item.weapon_sprite:
		gun.gun_sprite.texture = weapon_item.weapon_sprite
		print("✓ Set gun sprite to: ", weapon_item.weapon_sprite.resource_path)
	else:
		print("✗ Warning: Could not set gun sprite!")
		if not gun.gun_sprite:
			print("  - gun_sprite is null")
		if not weapon_item.weapon_sprite:
			print("  - weapon_item.weapon_sprite is null")
	
	gun._initialize_stats()
	gun._setup_gun_appearance()
	
	# Store reference
	if slot == 0:
		primary_gun = gun
	else:
		secondary_gun = gun
	
	# Hide if not active slot
	if slot != active_slot:
		gun.visible = false
		gun.process_mode = Node.PROCESS_MODE_DISABLED
	
	weapon_equipped.emit(slot, weapon_item)
	print("Equipped weapon in slot ", slot, ": ", weapon_item.name)
	return true

func unequip_weapon(slot: int) -> WeaponItem:
	var weapon_item: WeaponItem
	var gun: Gun
	
	if slot == 0:
		weapon_item = primary_slot
		gun = primary_gun
		primary_slot = null
		primary_gun = null
	else:
		weapon_item = secondary_slot
		gun = secondary_gun
		secondary_slot = null
		secondary_gun = null
	
	# Remove the gun node
	if gun:
		gun.queue_free()
	
	if weapon_item:
		weapon_unequipped.emit(slot)
	
	return weapon_item

func switch_weapon():
	# Toggle between primary (0) and secondary (1)
	var new_slot = 1 - active_slot
	
	# Check if new slot has a weapon
	var new_weapon = get_weapon_in_slot(new_slot)
	if not new_weapon:
		print("No weapon in slot ", new_slot)
		return
	
	# Hide and disable current weapon
	var current_gun = get_active_gun()
	if current_gun:
		current_gun.visible = false
		current_gun.process_mode = Node.PROCESS_MODE_DISABLED
		current_gun.stop_firing()
		current_gun.set_can_fire(false)
	
	# Switch active slot
	active_slot = new_slot
	var new_gun = get_active_gun()
	
	if new_gun:
		# Let the location state decide if the gun should be enabled
		var location_state = player.get_node_or_null("LocationStateMachine")
		
		if location_state:
			var current_state = location_state.get_current_state()
			
			# Check if we're in a state that allows weapons
			if current_state and current_state.name == "FarmState":
				new_gun.set_can_fire(true)
				new_gun.visible = true
				new_gun.process_mode = Node.PROCESS_MODE_INHERIT
				print("Switched to ", "primary" if active_slot == 0 else "secondary", " weapon: ", new_weapon.name, " (ENABLED)")
			else:
				# In safehouse or other no-combat zone
				new_gun.set_can_fire(false)
				new_gun.visible = false
				new_gun.process_mode = Node.PROCESS_MODE_DISABLED
				print("Switched to ", "primary" if active_slot == 0 else "secondary", " weapon: ", new_weapon.name, " (DISABLED)")
		else:
			# No location state machine - default to enabled
			new_gun.set_can_fire(true)
			new_gun.visible = true
			new_gun.process_mode = Node.PROCESS_MODE_INHERIT
		
		weapon_switched.emit(active_slot, new_gun)

func get_active_gun() -> Gun:
	return primary_gun if active_slot == 0 else secondary_gun

func get_weapon_in_slot(slot: int) -> WeaponItem:
	return primary_slot if slot == 0 else secondary_slot

func has_weapon_in_slot(slot: int) -> bool:
	return get_weapon_in_slot(slot) != null

func get_active_slot() -> int:
	return active_slot

func can_equip_weapon() -> bool:
	# Check if either slot is empty
	return primary_slot == null or secondary_slot == null

# NEW: Restore weapons from save data
func instantiate_weapons_from_save():
	"""Recreate Gun nodes from saved WeaponItem data after loading from save"""
	print("\n=== RESTORING WEAPONS FROM SAVE ===")
	
	# Instantiate primary weapon if we have one
	if primary_slot and not primary_gun:
		print("Restoring primary weapon: ", primary_slot.name)
		primary_gun = _create_gun_from_weapon_item(primary_slot)
		if primary_gun:
			player.add_child(primary_gun)
			primary_gun.setup_with_player(player)
			print("✓ Primary weapon instantiated")
	
	# Instantiate secondary weapon if we have one
	if secondary_slot and not secondary_gun:
		print("Restoring secondary weapon: ", secondary_slot.name)
		secondary_gun = _create_gun_from_weapon_item(secondary_slot)
		if secondary_gun:
			player.add_child(secondary_gun)
			secondary_gun.setup_with_player(player)
			print("✓ Secondary weapon instantiated")
	
	# Update visibility based on active slot and location
	_update_weapon_visibility_after_load()
	
	print("=== WEAPON RESTORATION COMPLETE ===\n")

func _create_gun_from_weapon_item(weapon_item: WeaponItem) -> Gun:
	"""Create a Gun node from a saved WeaponItem"""
	if not weapon_item or not weapon_item.weapon_scene:
		print("ERROR: Invalid weapon item or missing weapon scene")
		return null
	
	var gun = weapon_item.weapon_scene.instantiate() as Gun
	if not gun:
		print("ERROR: Failed to instantiate gun from weapon scene")
		return null
	
	# Apply saved stats to the gun
	gun.base_damage = weapon_item.base_damage
	gun.base_fire_rate = weapon_item.base_fire_rate
	gun.base_bullet_speed = weapon_item.base_bullet_speed
	gun.base_accuracy = weapon_item.base_accuracy
	gun.base_bullet_count = weapon_item.base_bullet_count
	
	# Set the gun sprite
	if gun.gun_sprite and weapon_item.weapon_sprite:
		gun.gun_sprite.texture = weapon_item.weapon_sprite
		print("  ✓ Set gun sprite")
	
	# Initialize gun stats
	gun._initialize_stats()
	gun._setup_gun_appearance()
	
	return gun

func _update_weapon_visibility_after_load():
	"""Update weapon visibility based on active slot and location state"""
	var location_state = player.get_node_or_null("LocationStateMachine")
	var is_farm = false
	
	if location_state:
		var current_state = location_state.get_current_state()
		is_farm = current_state and current_state.name == "FarmState"
	
	# Handle primary weapon
	if primary_gun:
		if active_slot == 0 and is_farm:
			primary_gun.set_can_fire(true)
			primary_gun.visible = true
			primary_gun.process_mode = Node.PROCESS_MODE_INHERIT
			print("  ✓ Primary weapon enabled (active in farm)")
		else:
			primary_gun.set_can_fire(false)
			primary_gun.visible = false
			primary_gun.process_mode = Node.PROCESS_MODE_DISABLED
			print("  ✓ Primary weapon disabled")
	
	# Handle secondary weapon
	if secondary_gun:
		if active_slot == 1 and is_farm:
			secondary_gun.set_can_fire(true)
			secondary_gun.visible = true
			secondary_gun.process_mode = Node.PROCESS_MODE_INHERIT
			print("  ✓ Secondary weapon enabled (active in farm)")
		else:
			secondary_gun.set_can_fire(false)
			secondary_gun.visible = false
			secondary_gun.process_mode = Node.PROCESS_MODE_DISABLED
			print("  ✓ Secondary weapon disabled")
