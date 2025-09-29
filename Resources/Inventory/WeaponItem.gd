extends Item
class_name WeaponItem

# Weapon-specific properties
@export var weapon_scene: PackedScene  # The actual Gun scene to instantiate
@export var weapon_tier: int = 1
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 2.0
@export var base_bullet_speed: float = 400.0
@export var base_accuracy: float = 1.0
@export var base_bullet_count: int = 1

func _init():
	item_type = "weapon"
	stack_size = 1  # Weapons don't stack
