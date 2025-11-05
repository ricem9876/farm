# VegetableEnemy.gd - Template for vegetable enemies
# Attach this script to your Tomato, Pumpkin, and Corn enemy scenes
extends CharacterBody2D

signal died(experience_points: int)

## CUSTOMIZE THESE FOR EACH ENEMY TYPE
@export var enemy_type: String = "tomato"  # "tomato", "pumpkin", "corn", "mushroom"
@export var max_health: float = 100.0
@export var experience_value: int = 10
@export var move_speed: float = 50.0
@export var damage: float = 10.0

## Loot drops
@export var drop_item_name: String = "tomato"  # Should match enemy_type
@export var drop_chance: float = 1.0  # 100% chance to drop

var current_health: float
var player: Node2D
var item_pickup_scene = preload("res://Resources/Inventory/Items/ItemPickup.gd")

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready():
	add_to_group("enemies")
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	print(enemy_type.capitalize(), " enemy spawned with ", max_health, " HP")

func _physics_process(delta):
	if not player:
		return
	
	# Simple chase AI - move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# Flip sprite based on direction
	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0
	elif animated_sprite and direction.x != 0:
		animated_sprite.flip_h = direction.x < 0

func take_damage(amount: float):
	current_health -= amount
	print(enemy_type.capitalize(), " took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	# Flash effect when hit
	_flash_damage()
	
	if current_health <= 0:
		_die()

func _flash_damage():
	"""Visual feedback when taking damage"""
	var target = sprite if sprite else animated_sprite
	if not target:
		return
	
	var original_modulate = target.modulate
	target.modulate = Color(1.5, 0.5, 0.5)  # Red flash
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(target):
		target.modulate = original_modulate

func _die():
	print(enemy_type.capitalize(), " died! Awarded ", experience_value, " XP")
	
	# Drop vegetable item
	_drop_loot()
	
	# Emit death signal with XP
	died.emit(experience_value)
	
	# Optional: Death animation/effect
	_play_death_effect()
	
	# Remove enemy
	queue_free()

func _drop_loot():
	"""Drop a vegetable item when killed"""
	# Check drop chance
	if randf() > drop_chance:
		print("  No drop (chance failed)")
		return
	
	# Create the item pickup
	var item_pickup = item_pickup_scene.instantiate()
	item_pickup.item_name = drop_item_name
	
	# Spawn at enemy's position with slight random offset
	var spawn_pos = global_position
	spawn_pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# Add to scene tree (add to parent's parent to avoid being child of dying enemy)
	get_parent().add_child(item_pickup)
	item_pickup.global_position = spawn_pos
	
	print("  ✓ Dropped ", drop_item_name, " at ", spawn_pos)

func _play_death_effect():
	"""Optional: Play death animation/particles"""
	# TODO: Add death particles, sound, animation, etc.
	pass

## Damage detection (if using Area2D for hurtbox)
func _on_hurtbox_area_entered(area):
	"""Called when something hits the enemy"""
	if area.is_in_group("player_projectiles"):
		if area.has_method("get_damage"):
			take_damage(area.get_damage())
		else:
			take_damage(10.0)  # Default damage
		
		# Destroy the projectile
		if area.has_method("on_hit"):
			area.on_hit()
		else:
			area.queue_free()

## Collision detection with player
func _on_body_entered(body):
	"""Called when enemy touches player"""
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print(enemy_type.capitalize(), " hit player for ", damage, " damage!")
