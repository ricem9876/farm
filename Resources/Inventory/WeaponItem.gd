extends Item
class_name WeaponItem

# Weapon type identification
@export_enum("Pistol", "Shotgun", "Rifle", "Sniper", "MachineGun", "Laser", "Plasma") var weapon_type: String = "Pistol"

# Visual properties
@export var weapon_sprite: Texture2D  # The sprite shown when equipped
@export var muzzle_flash_color: Color = Color.YELLOW
@export var bullet_trail_color: Color = Color.WHITE

# Audio (optional - for future enhancement)
@export var fire_sound: AudioStream

# The Gun scene to instantiate (usually always the same)
@export var weapon_scene: PackedScene = preload("res://Resources/Weapon/Gun.tscn")

# Weapon stats
@export var weapon_tier: int = 1
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 2.0
@export var base_bullet_speed: float = 400.0
@export var base_accuracy: float = 1.0
@export var base_bullet_count: int = 1

# Evolution tracking (optional - if you want to save evolution progress)
var current_evolution_points: int = 0
var current_tier: int = 1

func _init():
	item_type = "weapon"
	stack_size = 1  # Weapons don't stack

# Helper function to create a weapon with specific stats
static func create_weapon(
	weapon_name: String,
	weapon_desc: String,
	type: String,
	sprite: Texture2D,
	icon_texture: Texture2D,
	damage: float,
	fire_rate: float,
	bullet_count: int,
	accuracy: float = 1.0,
	bullet_speed: float = 400.0,
	tier: int = 1
) -> WeaponItem:
	var weapon = WeaponItem.new()
	weapon.name = weapon_name
	weapon.description = weapon_desc
	weapon.weapon_type = type
	weapon.weapon_sprite = sprite
	weapon.icon = icon_texture
	weapon.base_damage = damage
	weapon.base_fire_rate = fire_rate
	weapon.base_bullet_count = bullet_count
	weapon.base_accuracy = accuracy
	weapon.base_bullet_speed = bullet_speed
	weapon.weapon_tier = tier
	return weapon
