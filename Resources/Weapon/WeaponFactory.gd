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
	weapon.weapon_tier = 1  # Always tier 1
	return weapon

# Create a pistol
static func create_pistol() -> WeaponItem:
	var pistol = _create_base_weapon()
	pistol.name = "Pistol"
	pistol.description = "Reliable sidearm with balanced stats"
	pistol.weapon_type = "Pistol"
	pistol.weapon_sprite = preload("res://Resources/Weapon/Sprites/pistol.png")
	pistol.icon = preload("res://Resources/Weapon/Sprites/pistol.png")
	pistol.base_damage = 15.0
	pistol.base_fire_rate = 3.0
	pistol.base_bullet_count = 1
	pistol.base_accuracy = 0.95
	pistol.base_bullet_speed = 500.0
	return pistol

# Create a shotgun
static func create_shotgun() -> WeaponItem:
	var shotgun = _create_base_weapon()
	shotgun.name = "Shotgun"
	shotgun.description = "Devastating at close range"
	shotgun.weapon_type = "Shotgun"
	shotgun.weapon_sprite = preload("res://Resources/Weapon/Sprites/shotgun.png")
	shotgun.icon = preload("res://Resources/Weapon/Sprites/shotgun.png")
	shotgun.base_damage = 8.0
	shotgun.base_fire_rate = 1.0
	shotgun.base_bullet_count = 6
	shotgun.base_accuracy = 0.6
	shotgun.base_bullet_speed = 350.0
	return shotgun

# Create a rifle
static func create_rifle() -> WeaponItem:
	var rifle = _create_base_weapon()
	rifle.name = "Assault Rifle"
	rifle.description = "Balanced automatic weapon"
	rifle.weapon_type = "Rifle"
	rifle.weapon_sprite = DEFAULT_SPRITE
	rifle.icon = DEFAULT_ICON
	rifle.base_damage = 12.0
	rifle.base_fire_rate = 5.0
	rifle.base_bullet_count = 1
	rifle.base_accuracy = 0.85
	rifle.base_bullet_speed = 600.0
	return rifle

# Create a sniper rifle
static func create_sniper() -> WeaponItem:
	var sniper = _create_base_weapon()
	sniper.name = "Sniper Rifle"
	sniper.description = "High damage, precision weapon"
	sniper.weapon_type = "Sniper"
	sniper.weapon_sprite = preload("res://Resources/Weapon/Sprites/sniper.png")
	sniper.icon = preload("res://Resources/Weapon/Sprites/sniper.png")
	sniper.base_damage = 60.0
	sniper.base_fire_rate = 0.7
	sniper.base_bullet_count = 1
	sniper.base_accuracy = 1.0
	sniper.base_bullet_speed = 1200.0
	return sniper

# Create a machine gun
static func create_machine_gun() -> WeaponItem:
	var mg = _create_base_weapon()
	mg.name = "Machine Gun"
	mg.description = "Rapid fire suppression"
	mg.weapon_type = "MachineGun"
	mg.weapon_sprite = preload("res://Resources/Weapon/Sprites/machinegun.png")
	mg.icon = preload("res://Resources/Weapon/Sprites/machinegun.png")
	mg.base_damage = 6.0
	mg.base_fire_rate = 12.0
	mg.base_bullet_count = 1
	mg.base_accuracy = 0.75
	mg.base_bullet_speed = 450.0
	return mg

# Create a burst rifle
static func create_burst_rifle() -> WeaponItem:
	var burst = _create_base_weapon()
	burst.name = "Burst Rifle"
	burst.description = "Fires 3-round bursts"
	burst.weapon_type = "Rifle"
	burst.weapon_sprite = preload("res://Resources/Weapon/Sprites/rifle.png")
	burst.icon = preload("res://Resources/Weapon/Sprites/rifle.png")
	burst.base_damage = 14.0
	burst.base_fire_rate = 3.0
	burst.base_bullet_count = 3
	burst.base_accuracy = 0.9
	burst.base_bullet_speed = 550.0
	return burst
