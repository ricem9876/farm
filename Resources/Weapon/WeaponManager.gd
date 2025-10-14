# WeaponManager.gd - UPDATED WITH UPGRADE SUPPORT
extends Node
class_name WeaponManager

signal weapon_switched(slot: int, weapon: Gun)
signal weapon_equipped(slot: int, weapon_item: WeaponItem)
signal weapon_unequipped(slot: int)

@export var primary_slot: WeaponItem
@export var secondary_slot: WeaponItem

var primary_gun: Gun
var secondary_gun: Gun
var active_slot: int = 0
var player: Node2D

func _ready():
	player = get_parent()

func equip_weapon(weapon_item: WeaponItem, slot: int = 0) -> bool:
	if not weapon_item or weapon_item.item_type != "weapon":
		print("Cannot equip non-weapon item")
		return false
	
	unequip_weapon(slot)
	
	if slot == 0:
		primary_slot = weapon_item
	else:
		secondary_slot = weapon_item
	
	var gun = weapon_item.weapon_scene.instantiate() as Gun
	if not gun:
		print("Failed to instantiate weapon")
		return false
	
	player.add_child(gun)
	gun.setup_with_player(player)
	
	# Set gun stats from weapon item
	gun.base_damage = weapon_item.base_damage
	gun.base_fire_rate = weapon_item.base_fire_rate
	gun.base_bullet_speed = weapon_item.base_bullet_speed
	gun.base_accuracy = weapon_item.base_accuracy
	gun.base_bullet_count = weapon_item.base_bullet_count
	
	# NEW: Set screen shake and knockback based on weapon type
	_configure_weapon_effects(gun, weapon_item.weapon_type)
	
	# Set the gun sprite
	if gun.gun_sprite and weapon_item.weapon_sprite:
		gun.gun_sprite.texture = weapon_item.weapon_sprite
	
	gun._initialize_stats()
	gun._setup_gun_appearance()
	
	# ✨ APPLY WEAPON UPGRADES ✨
	if WeaponUpgradeManager:
		WeaponUpgradeManager.apply_upgrade_to_gun(gun, weapon_item.weapon_type)
		print("✓ Applied upgrades for ", weapon_item.weapon_type)
		
		# Check if any upgrades were applied and make gun gold
		var has_upgrades = false
		for upgrade in WeaponUpgradeManager.get_upgrades_for_weapon(weapon_item.weapon_type):
			if upgrade.is_purchased:
				has_upgrades = true
				break
		
		if has_upgrades and gun.gun_sprite:
			gun.gun_sprite.modulate = Color(1.0, 0.84, 0.0)  # Gold color
			print("✨ Weapon is upgraded - made GOLD")
	
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
	
	# CRITICAL: Force HUD update after equipping
	if player and player.has_node("PlayerHUD"):
		var hud = player.get_node("PlayerHUD")
		if hud.has_method("_update_weapons"):
			hud._update_weapons()
			print("✓ HUD weapons display updated")
	
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
	
	if gun:
		gun.queue_free()
	
	if weapon_item:
		weapon_unequipped.emit(slot)
	
	return weapon_item

func switch_weapon():
	var new_slot = 1 - active_slot
	
	var new_weapon = get_weapon_in_slot(new_slot)
	if not new_weapon:
		print("No weapon in slot ", new_slot)
		return
	
	var current_gun = get_active_gun()
	if current_gun:
		current_gun.visible = false
		current_gun.process_mode = Node.PROCESS_MODE_DISABLED
		current_gun.stop_firing()
		current_gun.set_can_fire(false)
	
	active_slot = new_slot
	var new_gun = get_active_gun()
	
	if new_gun:
		var location_state = player.get_node_or_null("LocationStateMachine")
		
		if location_state:
			var current_state = location_state.get_current_state()
			
			if current_state and current_state.name == "FarmState":
				new_gun.set_can_fire(true)
				new_gun.visible = true
				new_gun.process_mode = Node.PROCESS_MODE_INHERIT
				print("Switched to ", "primary" if active_slot == 0 else "secondary", " weapon: ", new_weapon.name, " (ENABLED)")
			else:
				new_gun.set_can_fire(false)
				new_gun.visible = false
				new_gun.process_mode = Node.PROCESS_MODE_DISABLED
				print("Switched to ", "primary" if active_slot == 0 else "secondary", " weapon: ", new_weapon.name, " (DISABLED)")
		else:
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
	return primary_slot == null or secondary_slot == null

func instantiate_weapons_from_save():
	"""Recreate Gun nodes from saved WeaponItem data after loading from save"""
	print("\n=== RESTORING WEAPONS FROM SAVE ===")
	print("Primary slot: ", primary_slot)
	print("Primary gun: ", primary_gun)
	print("Secondary slot: ", secondary_slot)
	print("Secondary gun: ", secondary_gun)
	
	# CRITICAL: Clear any existing guns first (from scene defaults)
	if primary_gun:
		print("Removing existing primary gun from scene")
		primary_gun.queue_free()
		primary_gun = null
	
	if secondary_gun:
		print("Removing existing secondary gun from scene")
		secondary_gun.queue_free()
		secondary_gun = null
	
	# Now create guns from the saved weapon slots
	if primary_slot:
		print("Restoring primary weapon: ", primary_slot.name)
		primary_gun = _create_gun_from_weapon_item(primary_slot)
		if primary_gun:
			# CRITICAL: Add to tree FIRST so @onready variables get assigned
			player.add_child(primary_gun)
			primary_gun.setup_with_player(player)
			
			# NOW the gun_sprite should exist, so set the texture
			if primary_gun.gun_sprite and primary_slot.weapon_sprite:
				primary_gun.gun_sprite.texture = primary_slot.weapon_sprite
				print("✓ Set primary weapon sprite texture")
			
			# Apply upgrades
			if WeaponUpgradeManager:
				WeaponUpgradeManager.apply_upgrade_to_gun(primary_gun, primary_slot.weapon_type)
				
				# Check if any upgrades were applied and make gun gold
				var has_upgrades = false
				for upgrade in WeaponUpgradeManager.get_upgrades_for_weapon(primary_slot.weapon_type):
					if upgrade.is_purchased:
						has_upgrades = true
						break
				
				if has_upgrades and primary_gun.gun_sprite:
					primary_gun.gun_sprite.modulate = Color(1.0, 0.84, 0.0)  # Gold color
					print("✨ Primary weapon is upgraded - made GOLD")
			
			print("✓ Primary weapon instantiated")
	else:
		print("  No primary weapon to restore")
	
	if secondary_slot:
		print("Restoring secondary weapon: ", secondary_slot.name)
		secondary_gun = _create_gun_from_weapon_item(secondary_slot)
		if secondary_gun:
			# CRITICAL: Add to tree FIRST so @onready variables get assigned
			player.add_child(secondary_gun)
			secondary_gun.setup_with_player(player)
			
			# NOW the gun_sprite should exist, so set the texture
			if secondary_gun.gun_sprite and secondary_slot.weapon_sprite:
				secondary_gun.gun_sprite.texture = secondary_slot.weapon_sprite
				print("✓ Set secondary weapon sprite texture")
			
			# Apply upgrades
			if WeaponUpgradeManager:
				WeaponUpgradeManager.apply_upgrade_to_gun(secondary_gun, secondary_slot.weapon_type)
				
				# Check if any upgrades were applied and make gun gold
				var has_upgrades = false
				for upgrade in WeaponUpgradeManager.get_upgrades_for_weapon(secondary_slot.weapon_type):
					if upgrade.is_purchased:
						has_upgrades = true
						break
				
				if has_upgrades and secondary_gun.gun_sprite:
					secondary_gun.gun_sprite.modulate = Color(1.0, 0.84, 0.0)  # Gold color
					print("✨ Secondary weapon is upgraded - made GOLD")
			
			print("✓ Secondary weapon instantiated")
	else:
		print("  No secondary weapon to restore")
	
	# DON'T update visibility here - let the location state system handle it
	# The farm state will be set right after this function returns
	
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
	
	# Set base stats from weapon item
	gun.base_damage = weapon_item.base_damage
	gun.base_fire_rate = weapon_item.base_fire_rate
	gun.base_bullet_speed = weapon_item.base_bullet_speed
	gun.base_accuracy = weapon_item.base_accuracy
	gun.base_bullet_count = weapon_item.base_bullet_count
	
	# NEW: Set screen shake and knockback based on weapon type
	_configure_weapon_effects(gun, weapon_item.weapon_type)
	
	return gun

func _configure_weapon_effects(gun: Gun, weapon_type: String):
	"""Configure screen shake intensity and knockback force by weapon type"""
	# UPDATED: Reduced screen shake - Sniper (heaviest) = old Pistol intensity
	# Order: Pistol (lightest) -> Machine Gun -> Assault Rifle -> Burst Rifle -> Shotgun -> Sniper (heaviest)
	match weapon_type:
		"Pistol":
			gun.screen_shake_intensity = 0.3  # Very light
			gun.bullet_knockback_force = 80.0  # Increased for visibility
		"MachineGun":
			gun.screen_shake_intensity = 0.5  # Light
			gun.bullet_knockback_force = 100.0
		"Rifle":
			gun.screen_shake_intensity = 0.8  # Medium-light
			gun.bullet_knockback_force = 150.0
		"BurstRifle":
			gun.screen_shake_intensity = 1.0  # Medium
			gun.bullet_knockback_force = 180.0
		"Shotgun":
			gun.screen_shake_intensity = 1.3  # Medium-heavy
			gun.bullet_knockback_force = 250.0
		"Sniper":
			gun.screen_shake_intensity = 2.0  # Heavy (old pistol level)
			gun.bullet_knockback_force = 400.0  # Massive knockback
		_:
			# Default fallback
			gun.screen_shake_intensity = 0.8
			gun.bullet_knockback_force = 150.0

func _update_weapon_visibility_after_load():
	"""Update weapon visibility based on active slot and location state"""
	var location_state = player.get_node_or_null("LocationStateMachine")
	var is_farm = false
	
	if location_state:
		var current_state = location_state.get_current_state()
		is_farm = current_state and current_state.name == "FarmState"
	
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
