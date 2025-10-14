# Wolf.gd
extends CharacterBody2D
class_name Wolf

signal died(experience_points: int)

@export var max_health: float = 50.0
@export var experience_value: int = 40
@export var move_speed: float = 120.0
@export var chase_speed: float = 150.0
@export var damage: float = 10.0
@export var attack_range: float = 30.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 1.5

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

# NEW: Knockback system
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 400.0  # Reduced from 800 so knockback is more visible

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
	
	# Start with idle animation
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	# Create health bar
	health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	health_bar.position = Vector2(0, -35)  # Centered above enemy
	health_bar.z_index = 10  # Draw on top

func _physics_process(delta):
	if is_dead:  # Stop all physics when dead
		return
	
	# Handle attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# NEW: Apply knockback friction
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
	# Simple idle or wander behavior
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)

func _update_animation():
	if is_dead or is_attacking:  # Don't update animations when dead
		return
	
	if not animated_sprite:
		return
	
	# Determine which animation to play based on state
	if velocity.length() > 10:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_dead:  # Don't detect when dead
		player = body
		is_chasing = true
		print("Wolf detected player - chasing!")

func _on_detection_area_exited(body):
	if body == player:
		is_chasing = false
		print("Wolf lost player")

func _on_attack_area_entered(body):
	if body.is_in_group("player") and can_attack and not is_attacking and not is_dead:  # Check is_dead
		_attack_player(body)

func _attack_player(target):
	if not can_attack or is_attacking or is_dead:  # Check is_dead
		return
	
	is_attacking = true
	
	# Play attack animation
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Deal damage mid-animation (you can adjust timing)
	await get_tree().create_timer(0.3).timeout
	
	if target and target.has_method("take_damage") and not is_dead:  # Check is_dead before dealing damage
		target.take_damage(damage)
		print("Wolf attacked for ", damage, " damage")
	
	can_attack = false
	attack_timer = attack_cooldown

func _on_animation_finished():
	if is_dead:  # NEW: Only handle death cleanup when dead
		if animated_sprite.animation == "dead":
			died.emit(experience_value)  # Emit signal here instead
			queue_free()
		return
	
	# Handle other animations
	if animated_sprite.animation == "attack":
		is_attacking = false

func take_damage(amount: float, is_crit: bool = false):
	if is_dead:  # Prevent damage after death
		return
	
	current_health -= amount
	print("Wolf took ", amount, " damage. HP: ", current_health, "/", max_health)
	if health_bar:
		health_bar.update_health(current_health)
		
	_spawn_damage_number(amount, is_crit)
	if current_health <= 0:
		_die()
		return  # Don't play hurt animation if dying
	
	# Play hurt animation
	if animated_sprite:
		animated_sprite.play("hurt")
		await get_tree().create_timer(0.2).timeout
	
	# Enrage - chase player when damaged
	if player:
		is_chasing = true
		
func _spawn_damage_number(damage: float, is_crit: bool = false):
	var damage_num = damage_number_scene.instantiate()
	get_parent().add_child(damage_num)
	damage_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_num.setup(damage, is_crit)
	
func _die():
	if is_dead:  # Prevent multiple death calls
		return
	
	is_dead = true
	print("Wolf died!")
	
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
		animated_sprite.play("dead")
	
	# Drop loot immediately
	_drop_loot()
	
	# queue_free() will be called by _on_animation_finished() when death animation completes

func _drop_loot():
	var drop_count = 1
	
	# Check for double drops from player luck
	if player and player.level_system:
		if randf() < player.level_system.luck:
			drop_count = 2
			print("DOUBLE DROPS! 2x fur!")
	
	# Spawn fur drops
	for i in range(drop_count):
		ItemSpawner.spawn_item("fur", global_position, get_parent())

func apply_knockback(force: Vector2):
	"""Apply knockback force to push enemy away"""
	if is_dead:
		return
	
	knockback_velocity = force
