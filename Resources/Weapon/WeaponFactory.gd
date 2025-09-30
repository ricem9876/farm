# WeaponFactory.gd
class_name WeaponFactory

const DEFAULT_SPRITE = preload("res://Resources/Weapon/assaultrifle.png")
const DEFAULT_ICON = preload("res://Resources/Weapon/assaultrifle.png")

# Helper to create a unique WeaponItem instance
static func _create_base_weapon() -> WeaponItem:
	var weapon = WeaponItem.new()
	weapon.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	weapon.item_type = "weapon"
	weapon.stack_size = 1
	return weapon

# Create a pistol
static func create_pistol(tier: int = 1) -> WeaponItem:
	var pistol = _create_base_weapon()
	pistol.name = "Pistol Tier " + str(tier)
	pistol.description = "Reliable sidearm with balanced stats"
	pistol.weapon_type = "Pistol"
	pistol.weapon_sprite = preload("res://Resources/Weapon/Sprites/pistol.png")
	pistol.icon = preload("res://Resources/Weapon/Sprites/pistol.png")
	pistol.weapon_tier = tier
	pistol.base_damage = 15.0 * tier
	pistol.base_fire_rate = 3.0
	pistol.base_bullet_count = 1
	pistol.base_accuracy = 0.95
	pistol.base_bullet_speed = 500.0
	return pistol

# Create a shotgun
static func create_shotgun(tier: int = 1) -> WeaponItem:
	var shotgun = _create_base_weapon()
	shotgun.name = "Shotgun Tier " + str(tier)
	shotgun.description = "Devastating at close range"
	shotgun.weapon_type = "Shotgun"
	shotgun.weapon_sprite = preload("res://Resources/Weapon/Sprites/shotgun.png")
	shotgun.icon = preload("res://Resources/Weapon/Sprites/shotgun.png")
	shotgun.weapon_tier = tier
	shotgun.base_damage = 8.0 * tier
	shotgun.base_fire_rate = 1.0
	shotgun.base_bullet_count = 6
	shotgun.base_accuracy = 0.6
	shotgun.base_bullet_speed = 350.0
	return shotgun

# Create a rifle
static func create_rifle(tier: int = 1) -> WeaponItem:
	var rifle = _create_base_weapon()
	rifle.name = "Assault Rifle Tier " + str(tier)
	rifle.description = "Balanced automatic weapon"
	rifle.weapon_type = "Rifle"
	rifle.weapon_sprite = DEFAULT_SPRITE
	rifle.icon = DEFAULT_ICON
	rifle.weapon_tier = tier
	rifle.base_damage = 12.0 * tier
	rifle.base_fire_rate = 5.0
	rifle.base_bullet_count = 1
	rifle.base_accuracy = 0.85
	rifle.base_bullet_speed = 600.0
	return rifle

# Create a sniper rifle
static func create_sniper(tier: int = 1) -> WeaponItem:
	var sniper = _create_base_weapon()
	sniper.name = "Sniper Rifle Tier " + str(tier)
	sniper.description = "High damage, precision weapon"
	sniper.weapon_type = "Sniper"
	sniper.weapon_sprite = preload("res://Resources/Weapon/Sprites/sniper.png")
	sniper.icon = preload("res://Resources/Weapon/Sprites/sniper.png")
	sniper.weapon_tier = tier
	sniper.base_damage = 60.0 * tier
	sniper.base_fire_rate = 0.7
	sniper.base_bullet_count = 1
	sniper.base_accuracy = 1.0
	sniper.base_bullet_speed = 1200.0
	return sniper

# Create a machine gun
static func create_machine_gun(tier: int = 1) -> WeaponItem:
	var mg = _create_base_weapon()
	mg.name = "Machine Gun Tier " + str(tier)
	mg.description = "Rapid fire suppression"
	mg.weapon_type = "MachineGun"
	mg.weapon_sprite = preload("res://Resources/Weapon/Sprites/machinegun.png")
	mg.icon = preload("res://Resources/Weapon/Sprites/machinegun.png")
	mg.weapon_tier = tier
	mg.base_damage = 6.0 * tier
	mg.base_fire_rate = 12.0
	mg.base_bullet_count = 1
	mg.base_accuracy = 0.75
	mg.base_bullet_speed = 450.0
	return mg

# Create a burst rifle
static func create_burst_rifle(tier: int = 1) -> WeaponItem:
	var burst = _create_base_weapon()
	burst.name = "Burst Rifle Tier " + str(tier)
	burst.description = "Fires 3-round bursts"
	burst.weapon_type = "Rifle"
	burst.weapon_sprite = preload("res://Resources/Weapon/Sprites/rifle.png")
	burst.icon = preload("res://Resources/Weapon/Sprites/rifle.png")
	burst.weapon_tier = tier
	burst.base_damage = 14.0 * tier
	burst.base_fire_rate = 3.0
	burst.base_bullet_count = 3
	burst.base_accuracy = 0.9
	burst.base_bullet_speed = 550.0
	return burst

# Create a laser weapon
static func create_laser(tier: int = 1) -> WeaponItem:
	var laser = _create_base_weapon()
	laser.name = "Laser Gun Tier " + str(tier)
	laser.description = "Energy weapon with continuous beam"
	laser.weapon_type = "Laser"
	laser.weapon_sprite = DEFAULT_SPRITE
	laser.icon = DEFAULT_ICON
	laser.weapon_tier = tier
	laser.base_damage = 10.0 * tier
	laser.base_fire_rate = 8.0
	laser.base_bullet_count = 1
	laser.base_accuracy = 0.98
	laser.base_bullet_speed = 800.0
	return laser

# Create a plasma weapon
static func create_plasma(tier: int = 1) -> WeaponItem:
	var plasma = _create_base_weapon()
	plasma.name = "Plasma Rifle Tier " + str(tier)
	plasma.description = "Experimental plasma technology"
	plasma.weapon_type = "Plasma"
	plasma.weapon_sprite = DEFAULT_SPRITE
	plasma.icon = DEFAULT_ICON
	plasma.weapon_tier = tier
	plasma.base_damage = 20.0 * tier
	plasma.base_fire_rate = 2.5
	plasma.base_bullet_count = 1
	plasma.base_accuracy = 0.88
	plasma.base_bullet_speed = 500.0
	return plasma
