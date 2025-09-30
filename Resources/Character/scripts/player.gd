extends CharacterBody2D
class_name player

signal inventory_toggle_requested

@export var max_health: float = 100.0
var current_health: float
var inventory_manager: InventoryManager
var weapon_manager: WeaponManager

func _ready():
	# Setup inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Setup weapon manager
	weapon_manager = WeaponManager.new()
	add_child(weapon_manager)
	
	# Connect weapon signals
	weapon_manager.weapon_switched.connect(_on_weapon_switched)
	weapon_manager.weapon_equipped.connect(_on_weapon_equipped)
	
	current_health = max_health
	
	# Give player a starting weapon
	_give_starting_weapon()
	
	add_to_group("player")
	
	print("Player ready - setting up managers...")

func _give_starting_weapon():
	# Create a basic weapon item
	var starter_weapon = WeaponItem.new()
	starter_weapon.name = "Starter Pistol"
	starter_weapon.description = "A basic pistol for beginners"
	starter_weapon.weapon_scene = preload("res://Resources/Weapon/Gun.tscn")
	starter_weapon.icon = preload("res://Resources/Weapon/assaultrifle.png")
	starter_weapon.weapon_tier = 1
	starter_weapon.base_damage = 10.0
	starter_weapon.base_fire_rate = 2.0
	starter_weapon.base_bullet_speed = 400.0
	starter_weapon.base_accuracy = 1.0
	starter_weapon.base_bullet_count = 1
	
	# Equip to primary slot
	weapon_manager.equip_weapon(starter_weapon, 0)
	
func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		print(">>> PLAYER DETECTED TAB/SHIFT PRESS <<<")
		print("Emitting inventory_toggle_requested signal...")
		inventory_toggle_requested.emit()
		print("Signal emitted!")
	
	# Direct weapon slot selection with 1 and 2
	if event.is_action_pressed("weapon_slot_1"):
		if weapon_manager.has_weapon_in_slot(0):
			weapon_manager.active_slot = 0
			weapon_manager.switch_weapon()
			print("Switched to weapon slot 1 (Primary)")
	
	if event.is_action_pressed("weapon_slot_2"):
		if weapon_manager.has_weapon_in_slot(1):
			weapon_manager.active_slot = 1
			weapon_manager.switch_weapon()
			print("Switched to weapon slot 2 (Secondary)")
	
	# Weapon switching with Q
	if event.is_action_pressed("switch_weapon"):
		weapon_manager.switch_weapon()
	
	# FIXED: Check if gun can fire before handling fire input
	if event.is_action_pressed("fire"):
		var active_gun = weapon_manager.get_active_gun()
		
		if active_gun and active_gun.can_fire:
			active_gun.start_firing()
		
	elif event.is_action_released("fire"):
		var active_gun = weapon_manager.get_active_gun()
		if active_gun:
			active_gun.stop_firing()

func take_damage(damage: float):
	current_health -= damage
	
	if current_health <= 0:
		_player_died()

func _player_died():
	# TODO: Game over logic
	pass

func _on_weapon_switched(slot: int, weapon: Gun):
	pass

func _on_weapon_equipped(slot: int, weapon_item: WeaponItem):
	pass

func gain_experience(points: int):
	# Give experience to active gun
	var active_gun = weapon_manager.get_active_gun()
	if active_gun:
		active_gun.add_evolution_points(points)
	
func _on_enemy_died():
	gain_experience(10)

func get_inventory_manager() -> InventoryManager:
	return inventory_manager

func get_weapon_manager() -> WeaponManager:
	return weapon_manager
	
func collect_item(item_name: String):
	if not inventory_manager:
		return
	
	# Handle different item types
	match item_name:
		"mushroom":
			var mushroom_item = Item.new()
			mushroom_item.name = "Mushroom"
			mushroom_item.description = "A tasty mushroom"
			mushroom_item.stack_size = 99
			mushroom_item.item_type = "consumable"
			mushroom_item.icon = preload("res://Resources/Inventory/Sprites/mushroom.png")
			
			inventory_manager.add_item(mushroom_item, 1)
		
		"health_potion":
			if current_health < max_health:
				current_health = min(max_health, current_health + 25)
		
		"coin":
			pass
		
		_:
			pass
