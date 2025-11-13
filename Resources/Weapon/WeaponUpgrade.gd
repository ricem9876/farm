# WeaponUpgrade.gd - Defines a single weapon upgrade
extends Resource
class_name WeaponUpgrade

@export var upgrade_id: String  # Unique identifier
@export var weapon_type: String  # "Pistol", "MachineGun", etc.
@export var upgrade_name: String  # Display name
@export var description: String  # What it does
@export var harvest_token_cost: int  # ← CHANGED: Cost in Harvest Tokens (was wood_cost)
@export var is_purchased: bool = false  # Track if player owns it

# Special behavior flags
@export var dual_wield: bool = false
@export var burst_mode: bool = false
@export var burst_count: int = 1  # How many bursts to fire (for Double Up)
@export var burst_delay: float = 0.0  # Delay between bursts in seconds
@export var penetrating_shots: bool = false
@export var headshot_chance: float = 0.0
@export var special_timer: float = 0.0  # For timed special attacks
@export var special_bullet_count: int = 0  # For special multi-shots

# Stat multipliers (1.0 = no change)
@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var bullet_count_multiplier: int = 1  # Additive
@export var bullet_speed_multiplier: float = 1.0
@export var accuracy_multiplier: float = 1.0

func _init():
	pass

# Helper to create an upgrade quickly
static func create(
	id: String,
	weapon: String,
	name: String,
	desc: String,
	cost: int
) -> WeaponUpgrade:
	var upgrade = WeaponUpgrade.new()
	upgrade.upgrade_id = id
	upgrade.weapon_type = weapon
	upgrade.upgrade_name = name
	upgrade.description = desc
	upgrade.harvest_token_cost = cost  # ← CHANGED: Set harvest_token_cost (was wood_cost)
	return upgrade
