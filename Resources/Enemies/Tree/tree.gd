# Tree.gd
extends CharacterBody2D
class_name TreeEnemy

signal died(experience_points: int)

@export var max_health: float = 80.0
@export var experience_value: int = 50
@export var falling_damage: float = 999.0  # One-hit kill damage

var current_health: float
var player: Node2D
var is_dead: bool = false
var is_falling: bool = false
var fall_direction: String = ""  # "left" or "right"
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var damage_area_left = $DamageAreaLeft
@onready var damage_area_right = $DamageAreaRight

func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Setup damage areas (only active when falling)
	if damage_area_left:
		damage_area_left.body_entered.connect(_on_left_damage_area_entered)
		damage_area_left.monitoring = false  # Start disabled
	
	if damage_area_right:
		damage_area_right.body_entered.connect(_on_right_damage_area_entered)
		damage_area_right.monitoring = false  # Start disabled
	
	# Start with idle animation
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	# Create health bar
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)  # Centered above enemy
	health_bar.z_index = 10  # Draw on top
	print("Tree spawned with ", max_health, " HP")

func _physics_process(delta):
	# Trees don't move
	pass

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("Tree took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	# Determine hit direction based on damage source
	var hit_from_left = false
	if player:
		hit_from_left = player.global_position.x < global_position.x
	
	# Play hit animation
	if animated_sprite and not is_dead:
		if hit_from_left:
			animated_sprite.play("hit_right")  # Hit from left, show right hit
		else:
			animated_sprite.play("hit_left")  # Hit from right, show left hit
		
		await get_tree().create_timer(0.3).timeout
		
		# Return to idle if still alive
		if not is_dead and animated_sprite:
			animated_sprite.play("idle")
		# Update health bar
	if health_bar:
		health_bar.update_health(current_health)
	_spawn_damage_number(amount, is_crit)	
	if current_health <= 0:
		_die()
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _die():
	if is_dead:
		return
	
	is_dead = true
	is_falling = true
	print("Tree is falling!")
	died.emit(experience_value)
	
	# Determine fall direction based on player position
	if player:
		if player.global_position.x < global_position.x:
			fall_direction = "left"
			print("Tree falling LEFT")
		else:
			fall_direction = "right"
			print("Tree falling RIGHT")
	else:
		# Default to random if no player
		fall_direction = "left" if randf() < 0.5 else "right"
	
	# Play fall animation
	if animated_sprite:
		animated_sprite.play("die_" + fall_direction)
	
	# Disable the tree's main collision so it doesn't block movement
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Enable the appropriate damage area
	await get_tree().create_timer(0.3).timeout  # Slight delay before damage starts
	
	if fall_direction == "left" and damage_area_left:
		damage_area_left.monitoring = true
		print("LEFT damage area ACTIVE")
	elif fall_direction == "right" and damage_area_right:
		damage_area_right.monitoring = true
		print("RIGHT damage area ACTIVE")
	
	# Drop loot after a moment
	await get_tree().create_timer(0.5).timeout
	_drop_loot()

func _on_left_damage_area_entered(body):
	if body.is_in_group("player") and is_falling:
		print("TREE CRUSHED PLAYER (fell left)!")
		if body.has_method("take_damage"):
			body.take_damage(falling_damage)
		
		# Disable damage area after hitting once
		if damage_area_left:
			damage_area_left.monitoring = false

func _on_right_damage_area_entered(body):
	if body.is_in_group("player") and is_falling:
		print("TREE CRUSHED PLAYER (fell right)!")
		if body.has_method("take_damage"):
			body.take_damage(falling_damage)
		
		# Disable damage area after hitting once
		if damage_area_right:
			damage_area_right.monitoring = false

func _on_animation_finished():
	if animated_sprite.animation.begins_with("die"):
		# Tree stays fallen on the ground
		# You could either:
		# 1. Leave it as a prop: do nothing
		# 2. Remove it after some time: await timer then queue_free()
		# 3. Fade it out
		
		# Option 2: Remove after 3 seconds
		await get_tree().create_timer(3.0).timeout
		queue_free()

func _drop_loot():
	var drop_count = 1
	
	# Check for double drops from player luck
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x wood!")
	
	# Spawn wood drops
	for i in range(drop_count):
		ItemSpawner.spawn_item("wood", global_position, get_parent())
