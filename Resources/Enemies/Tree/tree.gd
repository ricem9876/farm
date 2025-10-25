# Tree.gd - Treant version with chase and attack behavior
extends CharacterBody2D
class_name TreeEnemy

signal died(experience_points: int)

@export var max_health: float = 80.0
@export var experience_value: int = 50
@export var move_speed: float = 80.0  # Slower than wolf/mushroom
@export var chase_speed: float = 100.0  # Treants are slower but relentless
@export var damage: float = 15.0  # Higher damage than wolf
@export var attack_range: float = 40.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 2.0  # Slower attacks

var current_health: float
var player: Node2D
var is_chasing: bool = false
var can_attack: bool = true
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_dead: bool = false
var health_bar: EnemyHealthBar
var health_bar_scene = preload("res://Resources/UI/EnemyHealthBar.tscn")
var damage_number_scene = preload("res://Resources/UI/DamageNumber.tscn")

# Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Setup detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		# Set detection radius
		var circle = CircleShape2D.new()
		circle.radius = detection_range
		var collision = detection_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = circle
	
	# Setup attack area
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
		
		# Set attack radius
		var circle = CircleShape2D.new()
		circle.radius = attack_range
		var collision = attack_area.get_child(0) as CollisionShape2D
		if collision:
			collision.shape = circle
	
	# Start with walk animation (idle state)
	if animated_sprite:
		animated_sprite.play("walk")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	# Create health bar
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)
	health_bar.z_index = 10
	print("Treant spawned with ", max_health, " HP")

func _physics_process(delta):
	if is_dead:
		return
	
	# Handle attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Apply knockback friction
	if knockback_velocity.length() > 1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# Don't move during attack animation or if being knocked back
	if is_attacking:
		velocity = Vector2.ZERO
	elif knockback_velocity.length() > 1:
		# Apply knockback instead of normal movement
		velocity = knockback_velocity
	# Chase player if detected
	elif is_chasing and player:
		_chase_player(delta)
	else:
		_patrol(delta)
	
	move_and_slide()
	_update_animation()

func _chase_player(delta):
	if not player:
		is_chasing = false
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	# Flip sprite based on direction
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0

func _patrol(delta):
	# Simple idle behavior - treants stand still when not chasing
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)

func _update_animation():
	if is_dead or is_attacking:
		return
	
	if not animated_sprite:
		return
	
	# Play walk animation when moving, otherwise keep playing walk (looks like idle swaying)
	if animated_sprite.animation != "walk" and animated_sprite.animation != "death":
		animated_sprite.play("walk")

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_dead:
		player = body
		is_chasing = true
		print("Treant detected player - chasing!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false
		print("Treant lost player")

func _on_attack_area_entered(body):
	if body.is_in_group("player") and can_attack and not is_attacking and not is_dead:
		_attack_player(body)

func _attack_player(target):
	if not can_attack or is_attacking or is_dead:
		return
	
	is_attacking = true
	
	# Keep playing walk animation during attack (looks like smashing motion)
	if animated_sprite:
		animated_sprite.play("walk")
	
	# Deal damage mid-animation
	await get_tree().create_timer(0.4).timeout
	
	if target and target.has_method("take_damage") and not is_dead:
		target.take_damage(damage)
		print("Treant attacked for ", damage, " damage")
	
	can_attack = false
	attack_timer = attack_cooldown
	is_attacking = false

func _on_animation_finished():
	if is_dead:
		if animated_sprite.animation == "death":
			died.emit(experience_value)
			queue_free()
		return

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:
		return
	
	current_health -= amount
	print("Treant took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	
	if current_health <= 0:
		_die()
		return
	
	# Brief visual feedback when hit (could flash sprite or play faster animation)
	# Since we only have walk and death, we just continue walking
	
	# Enrage - chase player when damaged
	if player:
		is_chasing = true
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _die():
	if is_dead:
		return
	
	is_dead = true
	print("Treant died!")
	
	# Stop movement immediately
	velocity = Vector2.ZERO
	is_chasing = false
	is_attacking = false
	
	# Disable all collision areas
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
	if attack_area:
		attack_area.monitoring = false
	
	# Play death animation
	if animated_sprite:
		animated_sprite.play("death")
	
	# Drop loot immediately
	_drop_loot()

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

func apply_knockback(force: Vector2):
	"""Apply knockback force to push enemy away"""
	if is_dead:
		return
	
	knockback_velocity = force
