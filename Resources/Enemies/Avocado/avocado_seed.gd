# AvocadoSeed.gd - Projectile fired by Avocado enemies
extends Area2D

@export var speed: float = 200.0
@export var lifetime: float = 3.0  # How long before seed despawns

var direction: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var shooter: Node2D = null  # Reference to the avocado that shot this
var lifetime_timer: float = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# CRITICAL: Enable monitoring so we can detect collisions
	monitoring = true
	monitorable = true
	
	# Connect to body_entered signal for collision with player
	body_entered.connect(_on_body_entered)
	
	# Also connect area_entered in case player is an Area2D
	area_entered.connect(_on_area_entered)
	
	# Play the seed animation
	if animated_sprite:
		animated_sprite.play("default")
	
	# Set collision layers - seeds should hit player
	# Layer 3 = enemy projectiles, Mask 2 = player
	collision_layer = 4  # 2^2 = layer 3
	collision_mask = 2   # 2^1 = layer 2 (player)
	
	lifetime_timer = lifetime
	
	print("🌱 Seed spawned - Layer: ", collision_layer, " Mask: ", collision_mask, " Monitoring: ", monitoring)

func initialize(shoot_direction: Vector2, shoot_damage: float, from_shooter: Node2D):
	"""Initialize the seed with direction, damage, and shooter reference"""
	direction = shoot_direction.normalized()
	damage = shoot_damage
	shooter = from_shooter
	
	# Rotate sprite to match direction
	if animated_sprite:
		animated_sprite.rotation = direction.angle()
	
	print("🌱 Seed initialized - Direction: ", direction, " Damage: ", damage)

func _physics_process(delta):
	# Move the seed
	position += direction * speed * delta
	
	# Update lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()

func _on_body_entered(body):
	"""Handle collision with player"""
	print("🌱 Seed hit something: ", body.name, " Groups: ", body.get_groups())
	
	if body.is_in_group("player"):
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("🌱 Seed hit player for ", damage, " damage!")
		else:
			print("⚠ Player has no take_damage method!")
		
		# Destroy the seed
		queue_free()
	else:
		print("⚠ Hit non-player body: ", body.name)

func _on_area_entered(area):
	"""Handle collision with player if player is an Area2D"""
	print("🌱 Seed hit area: ", area.name, " Groups: ", area.get_groups())
	
	# Check if this area belongs to the player
	if area.is_in_group("player") or area.get_parent().is_in_group("player"):
		var player = area if area.is_in_group("player") else area.get_parent()
		
		if player.has_method("take_damage"):
			player.take_damage(damage)
			print("🌱 Seed hit player (area) for ", damage, " damage!")
		
		# Destroy the seed
		queue_free()
