# WeaponFactory.gd
# Static class for creating different weapon types easily
# Place this in: res://Resources/Weapon/WeaponFactory.gd

class_name WeaponFactory

# Default sprite if you don't have custom ones yet
const DEFAULT_SPRITE = preload("res://Resources/Weapon/assaultrifle.png")
const DEFAULT_ICON = preload("res://Resources/Weapon/assaultrifle.png")

# Create a pistol
static func create_pistol(tier: int = 1) -> WeaponItem:
	var pistol = WeaponItem.new()
	pistol.name = "Pistol"
	pistol.description = "Reliable sidearm with balanced stats"
	pistol.weapon_type = "Pistol"
	
	# Use custom sprite if you have it, otherwise use default
	# pistol.weapon_sprite = preload("res://Resources/Weapon/Sprites/pistol.png")
	pistol.weapon_sprite = DEFAULT_SPRITE
	pistol.icon = DEFAULT_ICON
	
	pistol.weapon_tier = tier
	pistol.base_damage = 15.0
	pistol.base_fire_rate = 3.0
	pistol.base_bullet_count = 1
	pistol.base_accuracy = 0.95
	pistol.base_bullet_speed = 500.0
	
	return pistol

# Create a shotgun
static func create_shotgun(tier: int = 1) -> WeaponItem:
	var shotgun = WeaponItem.new()
	shotgun.name = "Shotgun"
	shotgun.description = "Devastating at close range"
	shotgun.weapon_type = "Shotgun"
	
	shotgun.weapon_sprite = DEFAULT_SPRITE
	shotgun.icon = DEFAULT_ICON
	
	shotgun.weapon_tier = tier
	shotgun.base_damage = 8.0
	shotgun.base_fire_rate = 1.0
	shotgun.base_bullet_count = 6  # Shoots 6 pellets in a spread
	shotgun.base_accuracy = 0.6  # Lower accuracy = wider spread
	shotgun.base_bullet_speed = 350.0
	
	return shotgun

# Create a rifle
static func create_rifle(tier: int = 1) -> WeaponItem:
	var rifle = WeaponItem.new()
	rifle.name = "Assault Rifle"
	rifle.description = "Balanced automatic weapon"
	rifle.weapon_type = "Rifle"
	
	rifle.weapon_sprite = DEFAULT_SPRITE
	rifle.icon = DEFAULT_ICON
	
	rifle.weapon_tier = tier
	rifle.base_damage = 12.0
	rifle.base_fire_rate = 5.0  # Fast fire rate
	rifle.base_bullet_count = 1
	rifle.base_accuracy = 0.85
	rifle.base_bullet_speed = 600.0
	
	return rifle

# Create a sniper rifle
static func create_sniper(tier: int = 1) -> WeaponItem:
	var sniper = WeaponItem.new()
	sniper.name = "Sniper Rifle"
	sniper.description = "High damage, precision weapon"
	sniper.weapon_type = "Sniper"
	
	sniper.weapon_sprite = DEFAULT_SPRITE
	sniper.icon = DEFAULT_ICON
	
	sniper.weapon_tier = tier
	sniper.base_damage = 60.0
	sniper.base_fire_rate = 0.7  # Slow fire rate
	sniper.base_bullet_count = 1
	sniper.base_accuracy = 1.0  # Perfect accuracy
	sniper.base_bullet_speed = 1200.0  # Very fast bullets
	
	return sniper

# Create a machine gun
static func create_machine_gun(tier: int = 1) -> WeaponItem:
	var mg = WeaponItem.new()
	mg.name = "Machine Gun"
	mg.description = "Rapid fire suppression"
	mg.weapon_type = "MachineGun"
	
	mg.weapon_sprite = DEFAULT_SPRITE
	mg.icon = DEFAULT_ICON
	
	mg.weapon_tier = tier
	mg.base_damage = 6.0
	mg.base_fire_rate = 12.0  # Very fast!
	mg.base_bullet_count = 1
	mg.base_accuracy = 0.75
	mg.base_bullet_speed = 450.0
	
	return mg

# Create a burst rifle
static func create_burst_rifle(tier: int = 1) -> WeaponItem:
	var burst = WeaponItem.new()
	burst.name = "Burst Rifle"
	burst.description = "Fires 3-round bursts"
	burst.weapon_type = "Rifle"
	
	burst.weapon_sprite = DEFAULT_SPRITE
	burst.icon = DEFAULT_ICON
	
	burst.weapon_tier = tier
	burst.base_damage = 14.0
	burst.base_fire_rate = 3.0
	burst.base_bullet_count = 3  # Fires 3 bullets in quick succession
	burst.base_accuracy = 0.9
	burst.base_bullet_speed = 550.0
	
	return burst

# Create a laser weapon
static func create_laser(tier: int = 1) -> WeaponItem:
	var laser = WeaponItem.new()
	laser.name = "Laser Gun"
	laser.description = "Energy weapon with continuous beam"
	laser.weapon_type = "Laser"
	
	laser.weapon_sprite = DEFAULT_SPRITE
	laser.icon = DEFAULT_ICON
	
	laser.weapon_tier = tier
	laser.base_damage = 10.0
	laser.base_fire_rate = 8.0  # Rapid continuous fire
	laser.base_bullet_count = 1
	laser.base_accuracy = 0.98  # Very accurate
	laser.base_bullet_speed = 800.0  # Fast projectiles
	
	return laser

# Create a plasma weapon
static func create_plasma(tier: int = 1) -> WeaponItem:
	var plasma = WeaponItem.new()
	plasma.name = "Plasma Rifle"
	plasma.description = "Experimental plasma technology"
	plasma.weapon_type = "Plasma"
	
	plasma.weapon_sprite = DEFAULT_SPRITE
	plasma.icon = DEFAULT_ICON
	
	plasma.weapon_tier = tier
	plasma.base_damage = 20.0
	plasma.base_fire_rate = 2.5
	plasma.base_bullet_count = 1
	plasma.base_accuracy = 0.88
	plasma.base_bullet_speed = 500.0
	
	return plasma

# Create a random weapon
static func create_random_weapon(min_tier: int = 1, max_tier: int = 3) -> WeaponItem:
	var weapon_types = ["Pistol", "Shotgun", "Rifle", "Sniper", "MachineGun", "Laser", "Plasma"]
	var random_type = weapon_types[randi() % weapon_types.size()]
	var random_tier = randi_range(min_tier, max_tier)
	
	match random_type:
		"Pistol":
			return create_pistol(random_tier)
		"Shotgun":
			return create_shotgun(random_tier)
		"Rifle":
			return create_rifle(random_tier)
		"Sniper":
			return create_sniper(random_tier)
		"MachineGun":
			return create_machine_gun(random_tier)
		"Laser":
			return create_laser(random_tier)
		"Plasma":
			return create_plasma(random_tier)
		_:
			return create_pistol(random_tier)

# Create a weapon by type name
static func create_weapon_by_type(weapon_type: String, tier: int = 1) -> WeaponItem:
	match weapon_type:
		"Pistol":
			return create_pistol(tier)
		"Shotgun":
			return create_shotgun(tier)
		"Rifle":
			return create_rifle(tier)
		"Sniper":
			return create_sniper(tier)
		"MachineGun":
			return create_machine_gun(tier)
		"Laser":
			return create_laser(tier)
		"Plasma":
			return create_plasma(tier)
		_:
			print("Unknown weapon type: ", weapon_type, " - defaulting to Pistol")
			return create_pistol(tier)

# Create a starter weapon pack (for new players)
static func create_starter_pack() -> Array[WeaponItem]:
	var weapons: Array[WeaponItem] = []
	weapons.append(create_pistol(1))
	weapons.append(create_shotgun(1))
	return weapons

# Create a weapon with custom stats
static func create_custom_weapon(
	weapon_name: String,
	weapon_type: String,
	tier: int,
	damage: float,
	fire_rate: float,
	bullet_count: int,
	accuracy: float = 1.0,
	bullet_speed: float = 400.0
) -> WeaponItem:
	var weapon = WeaponItem.new()
	weapon.name = weapon_name
	weapon.description = "Custom configured weapon"
	weapon.weapon_type = weapon_type
	weapon.weapon_sprite = DEFAULT_SPRITE
	weapon.icon = DEFAULT_ICON
	weapon.weapon_tier = tier
	weapon.base_damage = damage
	weapon.base_fire_rate = fire_rate
	weapon.base_bullet_count = bullet_count
	weapon.base_accuracy = accuracy
	weapon.base_bullet_speed = bullet_speed
	return weapon

# Get weapon stats preview (useful for tooltips)
static func get_weapon_stats_text(weapon: WeaponItem) -> String:
	return """
	Name: %s
	Type: %s
	Tier: %d
	-----------------
	Damage: %.1f
	Fire Rate: %.1f/sec
	Bullet Count: %d
	Accuracy: %.0f%%
	Bullet Speed: %.0f
	""" % [
		weapon.name,
		weapon.weapon_type,
		weapon.weapon_tier,
		weapon.base_damage,
		weapon.base_fire_rate,
		weapon.base_bullet_count,
		weapon.base_accuracy * 100,
		weapon.base_bullet_speed
	]

# Helper function to populate a storage with test weapons
static func fill_storage_with_test_weapons(storage: WeaponStorageManager):
	"""Fills a weapon storage with one of each weapon type for testing"""
	storage.add_weapon(create_pistol(1))
	storage.add_weapon(create_shotgun(1))
	storage.add_weapon(create_rifle(1))
	storage.add_weapon(create_sniper(1))
	storage.add_weapon(create_machine_gun(1))
	storage.add_weapon(create_burst_rifle(1))
	storage.add_weapon(create_laser(2))
	storage.add_weapon(create_plasma(2))
	print("Added 8 test weapons to storage")

# Helper function to create a balanced weapon loadout
static func create_balanced_loadout() -> Array[WeaponItem]:
	"""Returns a primary and secondary weapon that work well together"""
	var loadouts = [
		[create_rifle(1), create_pistol(1)],      # Assault + Backup
		[create_sniper(1), create_shotgun(1)],    # Long + Close range
		[create_machine_gun(1), create_sniper(1)], # Suppression + Precision
		[create_shotgun(1), create_pistol(1)],    # Close + Medium
		[create_laser(2), create_plasma(2)]       # Energy combo
	]
	
	return loadouts[randi() % loadouts.size()]
