# WeaponUpgradeManager.gd - Manages all weapon upgrades
extends Node

signal upgrade_purchased(upgrade: WeaponUpgrade)
signal upgrade_applied(weapon_type: String, upgrade_id: String)

# Store all available upgrades
var available_upgrades: Dictionary = {}  # weapon_type -> Array[WeaponUpgrade]
var purchased_upgrades: Dictionary = {}  # upgrade_id -> WeaponUpgrade

func _ready():
	_initialize_upgrades()
	print("WeaponUpgradeManager initialized with ", available_upgrades.size(), " weapon types")

func _initialize_upgrades():
	"""Create all weapon upgrades based on your design"""
	
	# === PISTOL UPGRADES ===
	var pistol_dual = WeaponUpgrade.create(
		"pistol_dual_wield",
		"Pistol",
		"Dual Wield",
		"Equips 2 pistols - doubles fire rate",
		10
	)
	pistol_dual.dual_wield = true
	pistol_dual.fire_rate_multiplier = 2.0
	_add_upgrade(pistol_dual)
	
	# === MACHINE GUN UPGRADES ===
	var mg_lil_friend = WeaponUpgrade.create(
		"machinegun_lil_friend",
		"MachineGun",
		"Say hello to my lil' friend",
		"Shoots 10 bullets every 5 seconds",
		15
	)
	mg_lil_friend.special_timer = 5.0
	mg_lil_friend.special_bullet_count = 10
	_add_upgrade(mg_lil_friend)
	
	# === RIFLE UPGRADES ===
	var rifle_headshot = WeaponUpgrade.create(
		"rifle_headshot",
		"Rifle",
		"Boom Headshot",
		"10% chance to one-shot any enemy",
		25
	)
	rifle_headshot.headshot_chance = 0.1
	_add_upgrade(rifle_headshot)
	
	# === BURST RIFLE UPGRADES ===
	var burst_double = WeaponUpgrade.create(
		"burst_double",
		"BurstRifle",  # FIXED: Use separate type for Burst Rifle
		"Double Up",
		"Fires 2 bursts instead of 1 (6 bullets total)",
		20
	)
	burst_double.burst_mode = true
	burst_double.burst_count = 2  # Fire 2 bursts
	burst_double.burst_delay = 0.05  # 0.05 seconds between bursts
	_add_upgrade(burst_double)
	
	# === SNIPER UPGRADES ===
	var sniper_pierce = WeaponUpgrade.create(
		"sniper_penetrating",
		"Sniper",
		"Penetrating Rounds",
		"Every 4th shot pierces enemies and grows in size",
		15
	)
	sniper_pierce.penetrating_shots = true
	_add_upgrade(sniper_pierce)
	
	# === SHOTGUN UPGRADES ===
	var shotgun_360 = WeaponUpgrade.create(
		"shotgun_360",
		"Shotgun",
		"360 Degree Blast",
		"Shoots all around the player every 3 seconds",
		15
	)
	shotgun_360.special_timer = 3.0
	shotgun_360.special_bullet_count = 12  # Shoot in all directions
	_add_upgrade(shotgun_360)

func _add_upgrade(upgrade: WeaponUpgrade):
	"""Add an upgrade to the available upgrades dictionary"""
	if not available_upgrades.has(upgrade.weapon_type):
		available_upgrades[upgrade.weapon_type] = []
	available_upgrades[upgrade.weapon_type].append(upgrade)

func get_upgrades_for_weapon(weapon_type: String) -> Array[WeaponUpgrade]:
	"""Get all upgrades available for a specific weapon type"""
	var upgrades: Array[WeaponUpgrade] = []
	if available_upgrades.has(weapon_type):
		upgrades.assign(available_upgrades[weapon_type])
	return upgrades

func can_purchase_upgrade(upgrade: WeaponUpgrade, player: Node2D) -> bool:
	"""Check if player can afford and hasn't already purchased this upgrade"""
	if upgrade.is_purchased:
		return false
	
	if not player or not player.has_method("get_inventory_manager"):
		return false
	
	var inv = player.get_inventory_manager()
	if not inv:
		return false
	
	# Check if player has enough wood
	var wood_amount = inv.get_item_quantity_by_name("Wood")
	return wood_amount >= upgrade.wood_cost

func purchase_upgrade(upgrade: WeaponUpgrade, player: Node2D) -> bool:
	"""Purchase an upgrade if possible"""
	if not can_purchase_upgrade(upgrade, player):
		print("Cannot purchase upgrade: ", upgrade.upgrade_name)
		return false
	
	var inv = player.get_inventory_manager()
	
	# Create a wood item to remove
	var wood_item = Item.new()
	wood_item.name = "Wood"
	
	# Remove wood from inventory
	var removed = inv.remove_item(wood_item, upgrade.wood_cost)
	if removed < upgrade.wood_cost:
		print("Failed to remove wood from inventory")
		return false
	
	# Mark as purchased
	upgrade.is_purchased = true
	purchased_upgrades[upgrade.upgrade_id] = upgrade
	
	print("✓ Purchased upgrade: ", upgrade.upgrade_name, " for ", upgrade.wood_cost, " wood")
	upgrade_purchased.emit(upgrade)
	
	return true

func apply_upgrade_to_gun(gun: Gun, weapon_type: String) -> void:
	"""Apply all purchased upgrades for this weapon type to the gun"""
	if not available_upgrades.has(weapon_type):
		return
	
	for upgrade in available_upgrades[weapon_type]:
		if upgrade.is_purchased:
			_apply_single_upgrade(gun, upgrade)

func _apply_single_upgrade(gun: Gun, upgrade: WeaponUpgrade):
	"""Apply a single upgrade's effects to a gun"""
	print("Applying upgrade: ", upgrade.upgrade_name)
	
	# Apply stat multipliers
	if upgrade.damage_multiplier != 1.0:
		gun.base_damage *= upgrade.damage_multiplier
	
	if upgrade.fire_rate_multiplier != 1.0:
		gun.base_fire_rate *= upgrade.fire_rate_multiplier
	
	if upgrade.bullet_count_multiplier > 1:
		gun.base_bullet_count *= upgrade.bullet_count_multiplier
	
	if upgrade.bullet_speed_multiplier != 1.0:
		gun.base_bullet_speed *= upgrade.bullet_speed_multiplier
	
	if upgrade.accuracy_multiplier != 1.0:
		gun.base_accuracy *= upgrade.accuracy_multiplier
	
	# ✨ MAKE THE GUN GOLD WHEN UPGRADED ✨
	if gun.gun_sprite:
		gun.gun_sprite.modulate = Color(1.0, 0.84, 0.0)  # Gold color
		print("✨ Gun sprite modulated to GOLD")
	
	# Store special upgrade flags on the gun for runtime behavior
	if upgrade.dual_wield:
		print("🔫 DUAL WIELD UPGRADE DETECTED!")
		gun.set_meta("dual_wield", true)
		print("  Gun player reference: ", gun.player)
		print("  Calling create_second_gun() immediately...")
		# Create the second gun for dual wield
		gun.create_second_gun()
		print("  create_second_gun() call complete")
	
	if upgrade.burst_mode:
		gun.set_meta("burst_mode", true)
		gun.set_meta("burst_count", upgrade.burst_count)
		gun.set_meta("burst_delay", upgrade.burst_delay)
	
	if upgrade.headshot_chance > 0:
		gun.set_meta("headshot_chance", upgrade.headshot_chance)
	
	if upgrade.penetrating_shots:
		gun.set_meta("penetrating_shots", true)
		gun.set_meta("penetrating_counter", 0)  # Track shot count
	
	if upgrade.special_timer > 0:
		gun.set_meta("special_timer", upgrade.special_timer)
		gun.set_meta("special_bullet_count", upgrade.special_bullet_count)
		gun.set_meta("special_timer_current", 0.0)
		
		# Set specific upgrade type flags for special attacks
		if upgrade.weapon_type == "Shotgun":
			gun.set_meta("shotgun_360", true)
		elif upgrade.weapon_type == "MachineGun":
			gun.set_meta("machinegun_burst", true)
	
	# Re-initialize gun stats
	gun._initialize_stats()
	gun._setup_gun_appearance()
	
	upgrade_applied.emit(upgrade.weapon_type, upgrade.upgrade_id)

func is_upgrade_purchased(upgrade_id: String) -> bool:
	"""Check if an upgrade has been purchased"""
	return purchased_upgrades.has(upgrade_id)

func get_purchased_upgrades() -> Array[WeaponUpgrade]:
	"""Get all purchased upgrades"""
	var upgrades: Array[WeaponUpgrade] = []
	upgrades.assign(purchased_upgrades.values())
	return upgrades

func reset_all_upgrades():
	"""Reset all upgrades (for new game)"""
	for weapon_upgrades in available_upgrades.values():
		for upgrade in weapon_upgrades:
			upgrade.is_purchased = false
	purchased_upgrades.clear()
	print("All upgrades reset")

# === SAVE/LOAD ===

func get_save_data() -> Dictionary:
	"""Get upgrade data for saving"""
	var purchased_ids: Array = []
	for id in purchased_upgrades.keys():
		purchased_ids.append(id)
	
	return {
		"purchased_upgrade_ids": purchased_ids
	}

func load_save_data(data: Dictionary):
	"""Load upgrade data from save"""
	if not data.has("purchased_upgrade_ids"):
		return
	
	# Reset first
	reset_all_upgrades()
	
	# Mark upgrades as purchased
	for upgrade_id in data.purchased_upgrade_ids:
		# Find the upgrade
		for weapon_upgrades in available_upgrades.values():
			for upgrade in weapon_upgrades:
				if upgrade.upgrade_id == upgrade_id:
					upgrade.is_purchased = true
					purchased_upgrades[upgrade_id] = upgrade
					print("Restored upgrade: ", upgrade.upgrade_name)
					break
	
	print("✓ Loaded ", purchased_upgrades.size(), " purchased upgrades")
